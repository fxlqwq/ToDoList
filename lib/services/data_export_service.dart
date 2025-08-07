import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:archive/archive.dart';
import 'package:path/path.dart' as path;
import '../models/todo.dart' as todo_models;
import '../models/project_group.dart';
import 'database_service.dart';

class DataExportService {
  static final DataExportService _instance = DataExportService._internal();
  factory DataExportService() => _instance;
  DataExportService._internal();

  final DatabaseService _databaseService = DatabaseService();

  // Get Downloads/ToDoList directory
  Future<Directory> _getExportDirectory() async {
    Directory? downloadsDir;
    
    if (Platform.isAndroid) {
      // Try to get external storage directory
      try {
        final externalDir = await getExternalStorageDirectory();
        if (externalDir != null) {
          // Navigate to Downloads directory
          downloadsDir = Directory('/storage/emulated/0/Download/ToDoList');
        }
      } catch (e) {
        debugPrint('Error accessing external storage: $e');
      }
    }
    
    // Fallback to app documents directory
    downloadsDir ??= Directory('${(await getApplicationDocumentsDirectory()).path}/ToDoList');
    
    if (!await downloadsDir.exists()) {
      await downloadsDir.create(recursive: true);
    }
    
    return downloadsDir;
  }

  // Request necessary permissions
  Future<bool> _requestPermissions() async {
    if (Platform.isAndroid) {
      final storagePermission = await Permission.manageExternalStorage.request();
      if (storagePermission.isDenied) {
        final storagePermissionLegacy = await Permission.storage.request();
        return storagePermissionLegacy.isGranted;
      }
      return storagePermission.isGranted;
    }
    return true; // iOS doesn't need explicit permission for app sandbox
  }

  // Get attachments directory
  Future<Directory> _getAttachmentsDirectory() async {
    final appDir = await getApplicationDocumentsDirectory();
    return Directory('${appDir.path}/attachments');
  }

  // Process todos for export, updating attachment paths
  Future<List<Map<String, dynamic>>> _processTodosForExport(List<todo_models.Todo> todos) async {
    final processedTodos = <Map<String, dynamic>>[];
    
    for (final todo in todos) {
      final todoJson = todo.toJson();
      
      // Update attachment file paths to relative paths
      if (todoJson['attachments'] != null) {
        final List<dynamic> attachments = todoJson['attachments'];
        for (int i = 0; i < attachments.length; i++) {
          if (attachments[i]['filePath'] != null) {
            final originalPath = attachments[i]['filePath'] as String;
            final fileName = path.basename(originalPath);
            attachments[i]['filePath'] = 'attachments/$fileName';
            attachments[i]['originalPath'] = originalPath; // Keep original for reference
          }
        }
      }
      
      processedTodos.add(todoJson);
    }
    
    return processedTodos;
  }

  // Add attachments to archive
  Future<void> _addAttachmentsToArchive(Archive archive, Directory attachmentsDir, List<todo_models.Todo> todos) async {
    final Set<String> attachmentPaths = {};
    
    // Collect all attachment file paths
    for (final todo in todos) {
      for (final attachment in todo.attachments) {
        if (attachment.filePath.isNotEmpty) {
          attachmentPaths.add(attachment.filePath);
        }
      }
    }
    
    // Add each attachment file to archive
    for (final filePath in attachmentPaths) {
      final file = File(filePath);
      if (await file.exists()) {
        try {
          final bytes = await file.readAsBytes();
          final fileName = path.basename(filePath);
          final archiveFile = ArchiveFile('attachments/$fileName', bytes.length, bytes);
          archive.addFile(archiveFile);
        } catch (e) {
          debugPrint('Error adding attachment $filePath to archive: $e');
        }
      }
    }
  }

  // Export all data as ZIP with attachments
  Future<String> exportAllData() async {
    try {
      if (!await _requestPermissions()) {
        throw Exception('Storage permission denied');
      }

      final directory = await _getExportDirectory();
      final timestamp = DateTime.now().toIso8601String().replaceAll(':', '-').split('.')[0];
      final zipFileName = 'todolist_backup_$timestamp.zip';
      final zipFile = File('${directory.path}/$zipFileName');

      // Get all data
      final projectGroups = await _databaseService.getAllProjectGroups();
      final allTodos = await _databaseService.getAllTodosWithDetails();

      // Create archive
      final archive = Archive();

      // Add main data file
      final exportData = {
        'version': '1.0',
        'exportDate': DateTime.now().toIso8601String(),
        'projectGroups': projectGroups.map((g) => g.toJson()).toList(),
        'todos': await _processTodosForExport(allTodos),
      };

      final dataJson = jsonEncode(exportData);
      // Use UTF-8 encoding instead of codeUnits to prevent encoding issues
      final dataBytes = utf8.encode(dataJson);
      final dataFile = ArchiveFile('data.json', dataBytes.length, dataBytes);
      archive.addFile(dataFile);

      // Add attachments
      final attachmentsDir = await _getAttachmentsDirectory();
      if (await attachmentsDir.exists()) {
        await _addAttachmentsToArchive(archive, attachmentsDir, allTodos);
      }

      // Write ZIP file
      final zipData = ZipEncoder().encode(archive);
      if (zipData != null) {
        await zipFile.writeAsBytes(zipData);
      }

      return zipFile.path;
    } catch (e) {
      debugPrint('Error exporting all data: $e');
      rethrow;
    }
  }

  // Export specific project group data as ZIP
  Future<String> exportProjectGroupData(int projectGroupId) async {
    try {
      if (!await _requestPermissions()) {
        throw Exception('Storage permission denied');
      }

      final directory = await _getExportDirectory();
      final projectGroup = await _databaseService.getProjectGroup(projectGroupId);
      final todos = await _databaseService.getTodosByProjectGroup(projectGroupId);
      
      final timestamp = DateTime.now().toIso8601String().replaceAll(':', '-').split('.')[0];
      final zipFileName = 'todolist_${projectGroup?.name ?? 'unknown'}_$timestamp.zip';
      final zipFile = File('${directory.path}/$zipFileName');

      // Create archive
      final archive = Archive();

      // Add main data file
      final exportData = {
        'version': '1.0',
        'exportDate': DateTime.now().toIso8601String(),
        'projectGroup': projectGroup?.toJson(),
        'todos': await _processTodosForExport(todos),
      };

      final dataJson = jsonEncode(exportData);
      // Use UTF-8 encoding instead of codeUnits to prevent encoding issues
      final dataBytes = utf8.encode(dataJson);
      final dataFile = ArchiveFile('data.json', dataBytes.length, dataBytes);
      archive.addFile(dataFile);

      // Add attachments for this project group
      final attachmentsDir = await _getAttachmentsDirectory();
      if (await attachmentsDir.exists()) {
        await _addAttachmentsToArchive(archive, attachmentsDir, todos);
      }

      // Write ZIP file
      final zipData = ZipEncoder().encode(archive);
      if (zipData != null) {
        await zipFile.writeAsBytes(zipData);
      }

      return zipFile.path;
    } catch (e) {
      debugPrint('Error exporting project group data: $e');
      rethrow;
    }
  }

  // Import from ZIP file
  Future<Map<String, dynamic>> _importFromZip(File zipFile) async {
    final bytes = await zipFile.readAsBytes();
    final archive = ZipDecoder().decodeBytes(bytes);
    
    Map<String, dynamic>? data;
    final attachmentsToRestore = <String, List<int>>{};
    
    // Extract files from archive
    for (final file in archive) {
      debugPrint('🔥 DataExportService: Processing file in ZIP: ${file.name}');
      if (file.name == 'data.json') {
        try {
          // Extract main data using UTF-8 decoding
          final contentBytes = file.content as List<int>;
          final content = utf8.decode(contentBytes, allowMalformed: true);
          debugPrint('🔥 DataExportService: Extracted data.json content length: ${content.length}');
          debugPrint('🔥 DataExportService: First 200 chars: ${content.substring(0, content.length > 200 ? 200 : content.length)}');
          data = jsonDecode(content);
          debugPrint('🔥 DataExportService: Successfully parsed JSON data');
        } catch (e) {
          debugPrint('🔥 DataExportService: Error parsing data.json: $e');
          rethrow;
        }
      } else if (file.name.startsWith('attachments/')) {
        // Store attachment for later restoration
        attachmentsToRestore[file.name] = file.content as List<int>;
        debugPrint('🔥 DataExportService: Found attachment: ${file.name}');
      }
    }
    
    if (data == null) {
      throw Exception('No data.json found in backup file');
    }
    
    // Restore attachments
    await _restoreAttachments(attachmentsToRestore);
    
    return data;
  }

  // Restore attachments from ZIP
  Future<void> _restoreAttachments(Map<String, List<int>> attachments) async {
    final attachmentsDir = await _getAttachmentsDirectory();
    if (!await attachmentsDir.exists()) {
      await attachmentsDir.create(recursive: true);
    }
    
    for (final entry in attachments.entries) {
      try {
        final fileName = path.basename(entry.key);
        final file = File('${attachmentsDir.path}/$fileName');
        await file.writeAsBytes(entry.value);
      } catch (e) {
        debugPrint('Error restoring attachment ${entry.key}: $e');
      }
    }
  }

  // Import todos with attachment path correction
  Future<void> _importTodosWithAttachments(List<dynamic> todosData) async {
    print('🔥 DataExportService: Starting to import ${todosData.length} todos');
    final attachmentsDir = await _getAttachmentsDirectory();
    print('🔥 DataExportService: Attachments directory: ${attachmentsDir.path}');
    
    for (var todoData in todosData) {
      try {
        print('🔥 DataExportService: Processing todo: ${todoData['title']}');
        
        // Update attachment paths to current device paths
        if (todoData['attachments'] != null) {
          final List<dynamic> attachments = todoData['attachments'];
          print('🔥 DataExportService: Todo has ${attachments.length} attachments');
          for (int i = 0; i < attachments.length; i++) {
            if (attachments[i]['filePath'] != null) {
              final relativePath = attachments[i]['filePath'] as String;
              if (relativePath.startsWith('attachments/')) {
                final fileName = path.basename(relativePath);
                attachments[i]['filePath'] = '${attachmentsDir.path}/$fileName';
                print('🔥 DataExportService: Updated attachment path: ${attachments[i]['filePath']}');
              }
            }
          }
        }
        
        final todo = todo_models.Todo.fromJson(todoData);
        final todoId = await _databaseService.insertTodo(todo);
        print('🔥 DataExportService: Inserted todo: ${todo.title} with ID: $todoId');
        
        // Import subtasks
        for (var subtask in todo.subtasks) {
          final newSubtask = subtask.copyWith(todoId: todoId);
          await _databaseService.insertSubtask(newSubtask);
        }
        
        // Import attachments
        for (var attachment in todo.attachments) {
          final newAttachment = attachment.copyWith(todoId: todoId);
          await _databaseService.insertAttachment(newAttachment);
        }
        
        debugPrint('Completed importing todo: ${todo.title}');
      } catch (e) {
        debugPrint('Error importing todo: $e');
      }
    }
    debugPrint('Finished importing all todos');
  }

  // Import all data from ZIP or JSON file
  Future<bool> importAllData(String filePath) async {
    try {
      print('🔥 DataExportService: Starting import from: $filePath');
      final file = File(filePath);
      if (!await file.exists()) {
        print('🔥 DataExportService: File does not exist: $filePath');
        throw Exception('File does not exist');
      }

      print('🔥 DataExportService: File exists, size: ${await file.length()} bytes');
      Map<String, dynamic> data;
      
      // Check if it's a ZIP file
      if (filePath.toLowerCase().endsWith('.zip')) {
        print('🔥 DataExportService: Importing from ZIP file');
        data = await _importFromZip(file);
        print('🔥 DataExportService: ZIP import returned data keys: ${data.keys.toList()}');
      } else {
        print('🔥 DataExportService: Importing from JSON file');
        // Legacy JSON import
        final content = await file.readAsString();
        data = jsonDecode(content);
        print('🔥 DataExportService: JSON import returned data keys: ${data.keys.toList()}');
      }

      // Validate data structure - support both full and project-specific backups
      if (data['version'] == null || data['todos'] == null) {
        print('🔥 DataExportService: Invalid backup file format. Keys: ${data.keys.toList()}');
        throw Exception('Invalid backup file format');
      }

      // Check if it's a full backup (has projectGroups) or project-specific backup (has projectGroup)
      final isFullBackup = data['projectGroups'] != null;
      final isProjectBackup = data['projectGroup'] != null;
      
      if (!isFullBackup && !isProjectBackup) {
        print('🔥 DataExportService: Neither projectGroups nor projectGroup found. Keys: ${data.keys.toList()}');
        throw Exception('Invalid backup file format - no project data found');
      }

      if (isFullBackup) {
        print('🔥 DataExportService: Full backup detected. Project groups: ${(data['projectGroups'] as List).length}, Todos: ${(data['todos'] as List).length}');
        
        // Import project groups for full backup
        final projectGroups = data['projectGroups'] as List;
        print('🔥 DataExportService: Starting to import ${projectGroups.length} project groups');
        for (var groupData in projectGroups) {
          try {
            final group = ProjectGroup.fromJson(groupData);
            await _databaseService.insertProjectGroup(group);
            print('🔥 DataExportService: Imported project group: ${group.name}');
          } catch (e) {
            print('🔥 DataExportService: Error importing project group: $e');
          }
        }
      } else {
        print('🔥 DataExportService: Project-specific backup detected. Project: ${data['projectGroup']['name']}, Todos: ${(data['todos'] as List).length}');
        
        // Import single project group for project-specific backup
        try {
          final group = ProjectGroup.fromJson(data['projectGroup']);
          await _databaseService.insertProjectGroup(group);
          print('🔥 DataExportService: Imported project group: ${group.name}');
        } catch (e) {
          print('🔥 DataExportService: Error importing project group: $e');
        }
      }

      // Import todos
      if (data['todos'] != null) {
        print('🔥 DataExportService: Starting to import todos');
        await _importTodosWithAttachments(data['todos']);
        print('🔥 DataExportService: Imported todos with attachments');
      }

      print('🔥 DataExportService: Import completed successfully');
      return true;
    } catch (e, stackTrace) {
      print('🔥 DataExportService: Error importing data: $e');
      print('🔥 DataExportService: Stack trace: $stackTrace');
      return false;
    }
  }

  // Import project group data
  Future<bool> importProjectGroupData(String filePath) async {
    try {
      final file = File(filePath);
      if (!await file.exists()) {
        throw Exception('File does not exist');
      }

      Map<String, dynamic> data;
      
      // Check if it's a ZIP file
      if (filePath.toLowerCase().endsWith('.zip')) {
        data = await _importFromZip(file);
      } else {
        // Legacy JSON import
        final content = await file.readAsString();
        data = jsonDecode(content);
      }

      // Validate data structure
      if (data['version'] == null) {
        throw Exception('Invalid backup file format');
      }

      int? projectGroupId;

      // Import project group
      if (data['projectGroup'] != null) {
        try {
          final group = ProjectGroup.fromJson(data['projectGroup']);
          projectGroupId = await _databaseService.insertProjectGroup(group);
        } catch (e) {
          debugPrint('Error importing project group: $e');
          // Use default project group if import fails
          final defaultGroup = await _databaseService.getDefaultProjectGroup();
          projectGroupId = defaultGroup?.id;
        }
      }

      // Import todos
      if (data['todos'] != null && projectGroupId != null) {
        for (var todoData in data['todos']) {
          try {
            // Update project group ID
            todoData['projectGroupId'] = projectGroupId;
            
            final todo = todo_models.Todo.fromJson(todoData);
            final todoId = await _databaseService.insertTodo(todo);
            
            // Import subtasks
            for (var subtask in todo.subtasks) {
              final newSubtask = subtask.copyWith(todoId: todoId);
              await _databaseService.insertSubtask(newSubtask);
            }
            
            // Import attachments
            for (var attachment in todo.attachments) {
              final newAttachment = attachment.copyWith(todoId: todoId);
              await _databaseService.insertAttachment(newAttachment);
            }
          } catch (e) {
            debugPrint('Error importing todo: $e');
          }
        }
      }

      return true;
    } catch (e) {
      debugPrint('Error importing project group data: $e');
      return false;
    }
  }


  // Get list of export files (alias for compatibility)
  Future<List<File>> getExportFiles() async {
    try {
      final directory = await _getExportDirectory();
      final files = directory.listSync()
          .whereType<File>()
          .where((file) => file.path.endsWith('.zip') || file.path.endsWith('.json'))
          .toList();
      
      // Sort by modification date (newest first)
      files.sort((a, b) => b.statSync().modified.compareTo(a.statSync().modified));
      
      return files;
    } catch (e) {
      debugPrint('Error getting export files: $e');
      return [];
    }
  }

  // Get backup files (alias for backward compatibility)
  Future<List<File>> getBackupFiles() async {
    return await getExportFiles();
  }

  // Delete backup file
  Future<bool> deleteBackupFile(String filePath) async {
    try {
      final file = File(filePath);
      if (await file.exists()) {
        await file.delete();
        return true;
      }
      return false;
    } catch (e) {
      debugPrint('Error deleting backup file: $e');
      return false;
    }
  }

  // Get backup file info
  Future<Map<String, dynamic>> getBackupFileInfo(String filePath) async {
    try {
      final file = File(filePath);
      if (!await file.exists()) {
        throw Exception('File does not exist');
      }

      final stat = await file.stat();
      final fileName = path.basename(filePath);
      
      Map<String, dynamic> info = {
        'name': fileName,
        'path': filePath,
        'size': stat.size,
        'modified': stat.modified,
        'type': filePath.toLowerCase().endsWith('.zip') ? 'ZIP Archive' : 'JSON File',
        'isProjectSpecific': false, // 默认为false，后面根据内容判断
      };

      // Try to read content preview for JSON files
      if (filePath.toLowerCase().endsWith('.json')) {
        try {
          final content = await file.readAsString();
          final data = jsonDecode(content);
          
          info['version'] = data['version'] ?? 'Unknown';
          info['exportDate'] = data['exportDate'] ?? 'Unknown';
          
          // Handle both full backup (projectGroups) and project-specific backup (projectGroup)
          if (data['projectGroups'] != null) {
            final projectGroups = data['projectGroups'] as List;
            info['projectGroupsCount'] = projectGroups.length;
            info['isProjectSpecific'] = false;
            info['projectGroupNames'] = projectGroups.map((pg) => pg['name'] ?? 'Unknown').join(', ');
          } else if (data['projectGroup'] != null) {
            info['projectGroupsCount'] = 1;
            info['isProjectSpecific'] = true;
            info['projectGroupNames'] = data['projectGroup']['name'] ?? 'Unknown';
          }
          
          if (data['todos'] != null) {
            info['todosCount'] = (data['todos'] as List).length;
          }
        } catch (e) {
          debugPrint('Error reading JSON preview: $e');
        }
      } else if (filePath.toLowerCase().endsWith('.zip')) {
        // For ZIP files, try to extract basic info
        try {
          final bytes = await file.readAsBytes();
          final archive = ZipDecoder().decodeBytes(bytes);
          
          info['filesInArchive'] = archive.length;
          
          // Try to read data.json from archive
          for (final archiveFile in archive) {
            if (archiveFile.name == 'data.json') {
              try {
                // Use UTF-8 decoding for consistency
                final contentBytes = archiveFile.content as List<int>;
                final content = utf8.decode(contentBytes, allowMalformed: true);
                final data = jsonDecode(content);
                
                info['version'] = data['version'] ?? 'Unknown';
                info['exportDate'] = data['exportDate'] ?? 'Unknown';
                
                // Handle both full backup (projectGroups) and project-specific backup (projectGroup)
                if (data['projectGroups'] != null) {
                  final projectGroups = data['projectGroups'] as List;
                  info['projectGroupsCount'] = projectGroups.length;
                  info['isProjectSpecific'] = false;
                  info['projectGroupNames'] = projectGroups.map((pg) => pg['name'] ?? 'Unknown').join(', ');
                } else if (data['projectGroup'] != null) {
                  info['projectGroupsCount'] = 1;
                  info['isProjectSpecific'] = true;
                  info['projectGroupNames'] = data['projectGroup']['name'] ?? 'Unknown';
                }
                
                if (data['todos'] != null) {
                  info['todosCount'] = (data['todos'] as List).length;
                }
              } catch (e) {
                debugPrint('Error parsing ZIP data.json: $e');
              }
              break;
            }
          }
        } catch (e) {
          debugPrint('Error reading ZIP preview: $e');
        }
      }

      return info;
    } catch (e) {
      debugPrint('Error getting backup file info: $e');
      rethrow;
    }
  }
}