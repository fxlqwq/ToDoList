import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:file_picker/file_picker.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_sound/flutter_sound.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:uuid/uuid.dart';
import '../models/attachment.dart';

class AttachmentService {
  static final AttachmentService _instance = AttachmentService._internal();
  factory AttachmentService() => _instance;
  AttachmentService._internal();

  final FlutterSoundRecorder _recorder = FlutterSoundRecorder();
  final FlutterSoundPlayer _player = FlutterSoundPlayer();
  final ImagePicker _imagePicker = ImagePicker();
  final Uuid _uuid = const Uuid();

  bool _isRecorderInitialized = false;
  bool _isPlayerInitialized = false;

  Future<void> init() async {
    try {
      await _recorder.openRecorder();
      await _player.openPlayer();
      _isRecorderInitialized = true;
      _isPlayerInitialized = true;
      debugPrint('AttachmentService initialized successfully');
    } catch (e) {
      debugPrint('Error initializing AttachmentService: $e');
    }
  }

  Future<void> dispose() async {
    try {
      if (_isRecorderInitialized) {
        await _recorder.closeRecorder();
      }
      if (_isPlayerInitialized) {
        await _player.closePlayer();
      }
    } catch (e) {
      debugPrint('Error disposing AttachmentService: $e');
    }
  }

  // 获取应用文档目录
  Future<String> get _documentsPath async {
    final directory = await getApplicationDocumentsDirectory();
    final attachmentsDir = Directory('${directory.path}/attachments');
    if (!await attachmentsDir.exists()) {
      await attachmentsDir.create(recursive: true);
    }
    return attachmentsDir.path;
  }

  // ============= IMAGE METHODS =============

  Future<Attachment?> pickImageFromGallery(int todoId) async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1920,
        maxHeight: 1920,
        imageQuality: 85,
      );

      if (image == null) return null;

      return await _createImageAttachment(todoId, image);
    } catch (e) {
      debugPrint('Error picking image from gallery: $e');
      return null;
    }
  }

  Future<Attachment?> takePhoto(int todoId) async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.camera,
        maxWidth: 1920,
        maxHeight: 1920,
        imageQuality: 85,
      );

      if (image == null) return null;

      return await _createImageAttachment(todoId, image);
    } catch (e) {
      debugPrint('Error taking photo: $e');
      return null;
    }
  }

  Future<Attachment> _createImageAttachment(int todoId, XFile image) async {
    final documentsPath = await _documentsPath;
    final fileName = '${_uuid.v4()}.${image.path.split('.').last}';
    final filePath = '$documentsPath/$fileName';

    // 复制文件到应用目录
    final File imageFile = File(image.path);
    await imageFile.copy(filePath);

    // 获取文件大小
    final fileStats = await File(filePath).stat();

    return Attachment(
      todoId: todoId,
      fileName: image.name,
      filePath: filePath,
      type: AttachmentType.image,
      fileSize: fileStats.size,
    );
  }

  // ============= AUDIO METHODS =============

  Future<bool> requestAudioPermissions() async {
    final status = await Permission.microphone.request();
    return status == PermissionStatus.granted;
  }

  Future<bool> startRecording() async {
    if (!_isRecorderInitialized) return false;
    
    try {
      if (!await requestAudioPermissions()) {
        return false;
      }

      final documentsPath = await _documentsPath;
      final fileName = '${_uuid.v4()}.aac';
      final filePath = '$documentsPath/$fileName';

      await _recorder.startRecorder(
        toFile: filePath,
        codec: Codec.aacADTS,
      );
      return true;
    } catch (e) {
      debugPrint('Error starting recording: $e');
      return false;
    }
  }

  Future<Attachment?> stopRecording(int todoId) async {
    if (!_isRecorderInitialized) return null;

    try {
      final recordingPath = await _recorder.stopRecorder();
      if (recordingPath == null) return null;

      final File audioFile = File(recordingPath);
      final fileStats = await audioFile.stat();
      
      return Attachment(
        todoId: todoId,
        fileName: 'Voice Recording ${DateTime.now().toString().substring(0, 19)}.aac',
        filePath: recordingPath,
        type: AttachmentType.audio,
        fileSize: fileStats.size,
      );
    } catch (e) {
      debugPrint('Error stopping recording: $e');
      return null;
    }
  }

  Future<bool> playAudio(String filePath) async {
    if (!_isPlayerInitialized) return false;

    try {
      if (_player.isPlaying) {
        await _player.stopPlayer();
      }

      await _player.startPlayer(
        fromURI: filePath,
        codec: Codec.aacADTS,
      );
      return true;
    } catch (e) {
      debugPrint('Error playing audio: $e');
      return false;
    }
  }

  Future<void> stopAudio() async {
    if (_isPlayerInitialized && _player.isPlaying) {
      await _player.stopPlayer();
    }
  }

  bool get isRecording => _recorder.isRecording;
  bool get isPlaying => _player.isPlaying;

  // ============= TEXT METHODS =============

  Future<Attachment> createTextAttachment(int todoId, String title, String content) async {
    final documentsPath = await _documentsPath;
    final fileName = '${_uuid.v4()}.txt';
    final filePath = '$documentsPath/$fileName';

    // 保存文本文件
    final File textFile = File(filePath);
    await textFile.writeAsString(content);

    final fileStats = await textFile.stat();

    return Attachment(
      todoId: todoId,
      fileName: title.isEmpty ? 'Text Note' : title,
      filePath: filePath,
      type: AttachmentType.text,
      fileSize: fileStats.size,
      textContent: content,
    );
  }

  // ============= FILE METHODS =============

  Future<Attachment?> pickFile(int todoId) async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['jpg', 'jpeg', 'png', 'gif', 'pdf', 'doc', 'docx', 'txt'],
        allowMultiple: false,
      );

      if (result == null || result.files.isEmpty) return null;

      final file = result.files.first;
      final documentsPath = await _documentsPath;
      final fileName = '${_uuid.v4()}.${file.extension}';
      final filePath = '$documentsPath/$fileName';

      // 复制文件
      if (file.path != null) {
        await File(file.path!).copy(filePath);
      } else if (file.bytes != null) {
        await File(filePath).writeAsBytes(file.bytes!);
      }

      // 根据文件类型创建附件
      AttachmentType type = AttachmentType.text;
      if (['jpg', 'jpeg', 'png', 'gif'].contains(file.extension?.toLowerCase())) {
        type = AttachmentType.image;
      }

      return Attachment(
        todoId: todoId,
        fileName: file.name,
        filePath: filePath,
        type: type,
        fileSize: file.size,
      );
    } catch (e) {
      debugPrint('Error picking file: $e');
      return null;
    }
  }

  // ============= UTILITY METHODS =============

  Future<bool> deleteAttachmentFile(Attachment attachment) async {
    try {
      final file = File(attachment.filePath);
      if (await file.exists()) {
        await file.delete();
      }
      return true;
    } catch (e) {
      debugPrint('Error deleting attachment file: $e');
      return false;
    }
  }

  Future<String?> readTextFile(String filePath) async {
    try {
      final file = File(filePath);
      if (await file.exists()) {
        return await file.readAsString();
      }
    } catch (e) {
      debugPrint('Error reading text file: $e');
    }
    return null;
  }

  Future<bool> fileExists(String filePath) async {
    return await File(filePath).exists();
  }
}
