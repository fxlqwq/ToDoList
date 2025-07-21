class Subtask {
  int? id;
  int todoId;
  String title;
  bool isCompleted;
  DateTime createdAt;
  int order; // 用于排序

  Subtask({
    this.id,
    required this.todoId,
    required this.title,
    this.isCompleted = false,
    DateTime? createdAt,
    this.order = 0,
  }) : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'todoId': todoId,
      'title': title,
      'isCompleted': isCompleted ? 1 : 0,
      'createdAt': createdAt.millisecondsSinceEpoch,
      'order': order,
    };
  }

  factory Subtask.fromMap(Map<String, dynamic> map) {
    return Subtask(
      id: map['id'],
      todoId: map['todoId'],
      title: map['title'] ?? '',
      isCompleted: map['isCompleted'] == 1,
      createdAt: map['createdAt'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['createdAt'])
          : DateTime.now(),
      order: map['order'] ?? 0,
    );
  }

  Subtask copyWith({
    int? id,
    int? todoId,
    String? title,
    bool? isCompleted,
    DateTime? createdAt,
    int? order,
  }) {
    return Subtask(
      id: id ?? this.id,
      todoId: todoId ?? this.todoId,
      title: title ?? this.title,
      isCompleted: isCompleted ?? this.isCompleted,
      createdAt: createdAt ?? this.createdAt,
      order: order ?? this.order,
    );
  }

  @override
  String toString() {
    return 'Subtask{id: $id, todoId: $todoId, title: $title, isCompleted: $isCompleted}';
  }
}
