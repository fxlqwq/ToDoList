import 'package:intl/intl.dart';
import 'subtask.dart';
import 'attachment.dart';

enum Priority { low, medium, high }

enum Category { personal, work, health, shopping, education, other }

class Todo {
  int? id;
  String title;
  String description;
  bool isCompleted;
  DateTime createdAt;
  DateTime? dueDate;
  Priority priority;
  Category category;
  int? colorCode;
  List<String> tags;
  bool hasReminder;
  DateTime? reminderDate;
  bool useMarkdown; // 是否使用Markdown格式
  List<Subtask> subtasks; // 子任务列表
  List<Attachment> attachments; // 附件列表

  Todo({
    this.id,
    required this.title,
    this.description = '',
    this.isCompleted = false,
    DateTime? createdAt,
    this.dueDate,
    this.priority = Priority.medium,
    this.category = Category.personal,
    this.colorCode,
    List<String>? tags,
    this.hasReminder = false,
    this.reminderDate,
    this.useMarkdown = false,
    List<Subtask>? subtasks,
    List<Attachment>? attachments,
  })  : createdAt = createdAt ?? DateTime.now(),
        tags = tags ?? [],
        subtasks = subtasks ?? [],
        attachments = attachments ?? [];

  // Convert Todo to Map for database
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'isCompleted': isCompleted ? 1 : 0,
      'createdAt': createdAt.millisecondsSinceEpoch,
      'dueDate': dueDate?.millisecondsSinceEpoch,
      'priority': priority.index,
      'category': category.index,
      'colorCode': colorCode,
      'tags': tags.join(','),
      'hasReminder': hasReminder ? 1 : 0,
      'reminderDate': reminderDate?.millisecondsSinceEpoch,
      'useMarkdown': useMarkdown ? 1 : 0,
    };
  }

  // Create Todo from Map
  factory Todo.fromMap(Map<String, dynamic> map) {
    try {
      return Todo(
        id: map['id'],
        title: map['title'] ?? '',
        description: map['description'] ?? '',
        isCompleted: map['isCompleted'] == 1,
        createdAt: map['createdAt'] != null
            ? DateTime.fromMillisecondsSinceEpoch(map['createdAt'])
            : DateTime.now(),
        dueDate: map['dueDate'] != null
            ? DateTime.fromMillisecondsSinceEpoch(map['dueDate'])
            : null,
        priority:
            map['priority'] != null && map['priority'] < Priority.values.length
                ? Priority.values[map['priority']]
                : Priority.medium,
        category:
            map['category'] != null && map['category'] < Category.values.length
                ? Category.values[map['category']]
                : Category.personal,
        colorCode: map['colorCode'],
        tags: map['tags'] != null && map['tags'].toString().isNotEmpty
            ? map['tags'].toString().split(',')
            : [],
        hasReminder: map['hasReminder'] == 1,
        reminderDate: map['reminderDate'] != null
            ? DateTime.fromMillisecondsSinceEpoch(map['reminderDate'])
            : null,
        useMarkdown: map['useMarkdown'] == 1,
        // 子任务和附件将通过单独的查询获取
      );
    } catch (e) {
      // 如果解析失败，返回一个基本的todo对象
      return Todo(
        id: map['id'],
        title: map['title']?.toString() ?? 'Untitled Task',
        description: map['description']?.toString() ?? '',
        isCompleted: false,
        createdAt: DateTime.now(),
      );
    }
  }

  // Copy with method
  Todo copyWith({
    int? id,
    String? title,
    String? description,
    bool? isCompleted,
    DateTime? createdAt,
    DateTime? dueDate,
    Priority? priority,
    Category? category,
    int? colorCode,
    List<String>? tags,
    bool? hasReminder,
    DateTime? reminderDate,
    bool? useMarkdown,
    List<Subtask>? subtasks,
    List<Attachment>? attachments,
  }) {
    return Todo(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      isCompleted: isCompleted ?? this.isCompleted,
      createdAt: createdAt ?? this.createdAt,
      dueDate: dueDate ?? this.dueDate,
      priority: priority ?? this.priority,
      category: category ?? this.category,
      colorCode: colorCode ?? this.colorCode,
      tags: tags ?? this.tags,
      hasReminder: hasReminder ?? this.hasReminder,
      reminderDate: reminderDate ?? this.reminderDate,
      useMarkdown: useMarkdown ?? this.useMarkdown,
      subtasks: subtasks ?? this.subtasks,
      attachments: attachments ?? this.attachments,
    );
  }

  // Helper methods
  bool get isOverdue {
    if (dueDate == null || isCompleted) return false;
    return DateTime.now().isAfter(dueDate!);
  }

  bool get isDueToday {
    if (dueDate == null) return false;
    final today = DateTime.now();
    return dueDate!.year == today.year &&
        dueDate!.month == today.month &&
        dueDate!.day == today.day;
  }

  // 检查提醒时间是否有效
  bool get hasValidReminder {
    return hasReminder &&
        reminderDate != null &&
        reminderDate!.isAfter(DateTime.now()) &&
        !isCompleted;
  }

  // 检查提醒是否已过期
  bool get isReminderOverdue {
    return hasReminder &&
        reminderDate != null &&
        reminderDate!.isBefore(DateTime.now());
  }

  // 获取安全的提醒时间（如果无效则返回null）
  DateTime? get safeReminderDate {
    if (!hasReminder || reminderDate == null || isCompleted) {
      return null;
    }

    // 确保提醒时间在未来
    if (reminderDate!.isBefore(DateTime.now())) {
      return null;
    }

    return reminderDate;
  }

  String get formattedDueDate {
    if (dueDate == null) return '';
    try {
      return DateFormat('MMM dd, yyyy').format(dueDate!);
    } catch (e) {
      return '';
    }
  }

  String get formattedCreatedAt {
    try {
      return DateFormat('MMM dd, yyyy').format(createdAt);
    } catch (e) {
      return '';
    }
  }

  String get formattedReminderDate {
    if (reminderDate == null) return '';
    try {
      return DateFormat('MMM dd, yyyy HH:mm').format(reminderDate!);
    } catch (e) {
      return '';
    }
  }

  String get priorityText {
    switch (priority) {
      case Priority.low:
        return 'Low';
      case Priority.medium:
        return 'Medium';
      case Priority.high:
        return 'High';
    }
  }

  String get categoryText {
    switch (category) {
      case Category.personal:
        return 'Personal';
      case Category.work:
        return 'Work';
      case Category.health:
        return 'Health';
      case Category.shopping:
        return 'Shopping';
      case Category.education:
        return 'Education';
      case Category.other:
        return 'Other';
    }
  }

  // 新的辅助方法
  double get completionPercentage {
    if (subtasks.isEmpty) {
      return isCompleted ? 1.0 : 0.0;
    }

    final completedSubtasks = subtasks.where((s) => s.isCompleted).length;
    final totalSubtasks = subtasks.length;
    const mainTaskWeight = 0.3; // 主任务权重30%
    const subtasksWeight = 0.7; // 子任务权重70%

    double mainCompletion = isCompleted ? mainTaskWeight : 0.0;
    double subtaskCompletion =
        (completedSubtasks / totalSubtasks) * subtasksWeight;

    return mainCompletion + subtaskCompletion;
  }

  bool get hasSubtasks => subtasks.isNotEmpty;
  bool get hasAttachments => attachments.isNotEmpty;

  int get completedSubtasksCount => subtasks.where((s) => s.isCompleted).length;
  int get totalSubtasksCount => subtasks.length;

  List<Attachment> get imageAttachments =>
      attachments.where((a) => a.type == AttachmentType.image).toList();

  List<Attachment> get audioAttachments =>
      attachments.where((a) => a.type == AttachmentType.audio).toList();

  List<Attachment> get textAttachments =>
      attachments.where((a) => a.type == AttachmentType.text).toList();

  @override
  String toString() {
    return 'Todo{id: $id, title: $title, isCompleted: $isCompleted, priority: $priorityText}';
  }
}
