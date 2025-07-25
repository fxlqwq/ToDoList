import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../models/todo.dart';

class TodoCompactView extends StatelessWidget {
  final Todo todo;
  final VoidCallback onTap;
  final VoidCallback onLongPress;
  final Function(int subtaskIndex)? onSubtaskToggle;
  final VoidCallback? onMainTaskToggle; // 新增：主任务状态切换

  const TodoCompactView({
    super.key,
    required this.todo,
    required this.onTap,
    required this.onLongPress,
    this.onSubtaskToggle,
    this.onMainTaskToggle, // 新增参数
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 4),
      child: InkWell(
        onTap: onTap,
        onLongPress: onLongPress,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: todo.isCompleted ? Colors.grey.shade50 : Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: Colors.grey.shade200,
              width: 1,
            ),
          ),
          child: Row(
            children: [
              // 完成状态
              GestureDetector(
                onTap: onMainTaskToggle,
                child: Container(
                  width: 16,
                  height: 16,
                  margin: const EdgeInsets.only(right: 12),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color:
                          todo.isCompleted ? Colors.green : _getPriorityColor(),
                      width: 1.5,
                    ),
                    color: todo.isCompleted ? Colors.green : Colors.transparent,
                  ),
                  child: todo.isCompleted
                      ? const Icon(
                          Icons.check,
                          size: 10,
                          color: Colors.white,
                        )
                      : null,
                ),
              ),

              // 标题
              Expanded(
                child: Text(
                  todo.title,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    decoration:
                        todo.isCompleted ? TextDecoration.lineThrough : null,
                    color: todo.isCompleted ? Colors.grey.shade500 : null,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),

              // 子任务进度
              if (todo.hasSubtasks) ...[
                const SizedBox(width: 8),
                _buildSubtaskIndicator(),
              ],

              // 图标指示器
              const SizedBox(width: 8),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (todo.hasReminder)
                    Icon(
                      FontAwesomeIcons.bell,
                      size: 10,
                      color: Colors.grey.shade500,
                    ),
                  if (todo.hasAttachments) ...[
                    if (todo.hasReminder) const SizedBox(width: 4),
                    Icon(
                      FontAwesomeIcons.paperclip,
                      size: 10,
                      color: Colors.grey.shade500,
                    ),
                  ],
                  if (todo.dueDate != null) ...[
                    if (todo.hasReminder || todo.hasAttachments)
                      const SizedBox(width: 4),
                    Icon(
                      FontAwesomeIcons.calendar,
                      size: 10,
                      color: _getDueDateColor(),
                    ),
                  ],
                ],
              ),

              // 优先级指示器
              if (todo.priority != Priority.medium) ...[
                const SizedBox(width: 8),
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: _getPriorityColor(),
                    shape: BoxShape.circle,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSubtaskIndicator() {
    final completedSubtasks = todo.subtasks.where((s) => s.isCompleted).length;
    final totalSubtasks = todo.subtasks.length;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: Colors.blue.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        '$completedSubtasks/$totalSubtasks',
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w500,
          color:
              completedSubtasks == totalSubtasks ? Colors.green : Colors.blue,
        ),
      ),
    );
  }

  Color _getPriorityColor() {
    switch (todo.priority) {
      case Priority.low:
        return Colors.green;
      case Priority.medium:
        return Colors.orange;
      case Priority.high:
        return Colors.red;
    }
  }

  Color _getDueDateColor() {
    if (todo.dueDate == null) return Colors.grey;

    final now = DateTime.now();
    if (todo.dueDate!.isBefore(now) && !todo.isCompleted) {
      return Colors.red;
    }

    final today = DateTime(now.year, now.month, now.day);
    final dueDay =
        DateTime(todo.dueDate!.year, todo.dueDate!.month, todo.dueDate!.day);

    if (dueDay == today) {
      return Colors.orange;
    }

    return Colors.grey.shade500;
  }
}
