enum AttachmentType { image, audio, text }

class Attachment {
  int? id;
  int todoId;
  String fileName;
  String filePath;
  AttachmentType type;
  DateTime createdAt;
  int? fileSize; // in bytes
  String? textContent; // for text attachments

  Attachment({
    this.id,
    required this.todoId,
    required this.fileName,
    required this.filePath,
    required this.type,
    DateTime? createdAt,
    this.fileSize,
    this.textContent,
  }) : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'todoId': todoId,
      'fileName': fileName,
      'filePath': filePath,
      'type': type.index,
      'createdAt': createdAt.millisecondsSinceEpoch,
      'fileSize': fileSize,
      'textContent': textContent,
    };
  }

  factory Attachment.fromMap(Map<String, dynamic> map) {
    return Attachment(
      id: map['id'],
      todoId: map['todoId'],
      fileName: map['fileName'] ?? '',
      filePath: map['filePath'] ?? '',
      type: map['type'] != null && map['type'] < AttachmentType.values.length
          ? AttachmentType.values[map['type']]
          : AttachmentType.text,
      createdAt: map['createdAt'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['createdAt'])
          : DateTime.now(),
      fileSize: map['fileSize'],
      textContent: map['textContent'],
    );
  }

  Attachment copyWith({
    int? id,
    int? todoId,
    String? fileName,
    String? filePath,
    AttachmentType? type,
    DateTime? createdAt,
    int? fileSize,
    String? textContent,
  }) {
    return Attachment(
      id: id ?? this.id,
      todoId: todoId ?? this.todoId,
      fileName: fileName ?? this.fileName,
      filePath: filePath ?? this.filePath,
      type: type ?? this.type,
      createdAt: createdAt ?? this.createdAt,
      fileSize: fileSize ?? this.fileSize,
      textContent: textContent ?? this.textContent,
    );
  }

  String get typeText {
    switch (type) {
      case AttachmentType.image:
        return '图片';
      case AttachmentType.audio:
        return '音频';
      case AttachmentType.text:
        return '文本';
    }
  }

  String get formattedFileSize {
    if (fileSize == null) return '';
    if (fileSize! < 1024) return '${fileSize!} B';
    if (fileSize! < 1024 * 1024) return '${(fileSize! / 1024).toStringAsFixed(1)} KB';
    return '${(fileSize! / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  @override
  String toString() {
    return 'Attachment{id: $id, todoId: $todoId, fileName: $fileName, type: $typeText}';
  }
}
