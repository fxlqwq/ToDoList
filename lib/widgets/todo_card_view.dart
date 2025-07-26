import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../models/todo.dart';

class TodoCardView extends StatelessWidget {
  final Todo todo;
  final VoidCallback onTap;
  final VoidCallback onLongPress;
  final Function(int subtaskIndex)? onSubtaskToggle;
  final VoidCallback? onMainTaskToggle; // 新增：主任务状态切换

  const TodoCardView({
    super.key,
    required this.todo,
    required this.onTap,
    required this.onLongPress,
    this.onSubtaskToggle,
    this.onMainTaskToggle, // 新增参数
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: onTap,
        onLongPress: onLongPress,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(),
              if (todo.description.isNotEmpty) ...[
                const SizedBox(height: 8),
                _buildDescription(),
              ],
              if (todo.hasSubtasks) ...[
                const SizedBox(height: 12),
                _buildSubtaskProgress(),
              ],
              const SizedBox(height: 12),
              _buildFooter(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 完成状态指示器 - 可点击切换
        GestureDetector(
          onTap: onMainTaskToggle,
          child: Container(
            width: 20,
            height: 20,
            margin: const EdgeInsets.only(right: 12, top: 2),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: todo.isCompleted ? Colors.green : _getPriorityColor(),
                width: 2,
              ),
              color: todo.isCompleted ? Colors.green : Colors.transparent,
            ),
            child: todo.isCompleted
                ? const Icon(
                    Icons.check,
                    size: 12,
                    color: Colors.white,
                  )
                : null,
          ),
        ),

        // 标题和优先级
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      todo.title,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        decoration: todo.isCompleted
                            ? TextDecoration.lineThrough
                            : null,
                        color: todo.isCompleted ? Colors.grey.shade500 : null,
                      ),
                    ),
                  ),
                  _buildPriorityChip(),
                ],
              ),
              if (todo.dueDate != null) ...[
                const SizedBox(height: 4),
                _buildDueDate(),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDescription() {
    return Text(
      todo.description,
      style: TextStyle(
        fontSize: 14,
        color: Colors.grey.shade600,
        decoration: todo.isCompleted ? TextDecoration.lineThrough : null,
      ),
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
    );
  }

  Widget _buildSubtaskProgress() {
    final completedSubtasks = todo.subtasks.where((s) => s.isCompleted).length;
    final totalSubtasks = todo.subtasks.length;
    final progress =
        totalSubtasks > 0 ? completedSubtasks / totalSubtasks : 0.0;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(
                    FontAwesomeIcons.listCheck,
                    size: 14,
                    color: Colors.grey.shade600,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    '子任务进度',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
              Text(
                '$completedSubtasks/$totalSubtasks',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: progress == 1.0 ? Colors.green : Colors.orange,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          LinearProgressIndicator(
            value: progress,
            backgroundColor: Colors.grey.shade200,
            valueColor: AlwaysStoppedAnimation<Color>(
              progress == 1.0 ? Colors.green : Colors.blue,
            ),
          ),
          if (totalSubtasks <= 3) ...[
            const SizedBox(height: 8),
            ...todo.subtasks.take(3).map((subtask) {
              final index = todo.subtasks.indexOf(subtask);
              return GestureDetector(
                onTap: () => onSubtaskToggle?.call(index),
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Row(
                    children: [
                      Container(
                        width: 12,
                        height: 12,
                        margin: const EdgeInsets.only(right: 8),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: subtask.isCompleted
                                ? Colors.green
                                : Colors.grey,
                            width: 1,
                          ),
                          color: subtask.isCompleted
                              ? Colors.green
                              : Colors.transparent,
                        ),
                        child: subtask.isCompleted
                            ? const Icon(
                                Icons.check,
                                size: 8,
                                color: Colors.white,
                              )
                            : null,
                      ),
                      Expanded(
                        child: Text(
                          subtask.title,
                          style: TextStyle(
                            fontSize: 11,
                            color: subtask.isCompleted
                                ? Colors.grey.shade500
                                : Colors.grey.shade700,
                            decoration: subtask.isCompleted
                                ? TextDecoration.lineThrough
                                : null,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
          ],
        ],
      ),
    );
  }

  Widget _buildFooter() {
    return Row(
      children: [
        _buildCategoryChip(),
        const Spacer(),
        if (todo.hasReminder) ...[
          Icon(
            FontAwesomeIcons.bell,
            size: 12,
            color: Colors.grey.shade500,
          ),
          const SizedBox(width: 8),
        ],
        if (todo.hasAttachments) ...[
          Icon(
            FontAwesomeIcons.paperclip,
            size: 12,
            color: Colors.grey.shade500,
          ),
          const SizedBox(width: 8),
        ],
        if (todo.tags.isNotEmpty) ...[
          Icon(
            FontAwesomeIcons.tag,
            size: 12,
            color: Colors.grey.shade500,
          ),
          const SizedBox(width: 4),
          Text(
            todo.tags.length.toString(),
            style: TextStyle(
              fontSize: 11,
              color: Colors.grey.shade500,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildPriorityChip() {
    if (todo.priority == Priority.medium) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: _getPriorityColor().withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        _getPriorityText(),
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w500,
          color: _getPriorityColor(),
        ),
      ),
    );
  }

  Widget _buildCategoryChip() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: _getCategoryColor().withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            _getCategoryIcon(),
            size: 12,
            color: _getCategoryColor(),
          ),
          const SizedBox(width: 4),
          Text(
            _getCategoryText(),
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: _getCategoryColor(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDueDate() {
    final now = DateTime.now();
    final isOverdue = todo.dueDate!.isBefore(now) && !todo.isCompleted;
    final isToday = todo.dueDate!.day == now.day &&
        todo.dueDate!.month == now.month &&
        todo.dueDate!.year == now.year;

    Color dateColor = Colors.grey.shade600;
    if (isOverdue) dateColor = Colors.red;
    if (isToday) dateColor = Colors.orange;

    return Row(
      children: [
        Icon(
          FontAwesomeIcons.calendar,
          size: 12,
          color: dateColor,
        ),
        const SizedBox(width: 4),
        Text(
          _formatDueDate(),
          style: TextStyle(
            fontSize: 12,
            color: dateColor,
            fontWeight:
                isOverdue || isToday ? FontWeight.w500 : FontWeight.normal,
          ),
        ),
      ],
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

  String _getPriorityText() {
    switch (todo.priority) {
      case Priority.low:
        return '低';
      case Priority.medium:
        return '中';
      case Priority.high:
        return '高';
    }
  }

  Color _getCategoryColor() {
    switch (todo.category) {
      case Category.work:
        return Colors.blue;
      case Category.personal:
        return Colors.green;
      case Category.shopping:
        return Colors.orange;
      case Category.health:
        return Colors.red;
      case Category.education:
        return Colors.purple;
      case Category.other:
        return Colors.grey;
    }
  }

  IconData _getCategoryIcon() {
    switch (todo.category) {
      case Category.work:
        return FontAwesomeIcons.briefcase;
      case Category.personal:
        return FontAwesomeIcons.user;
      case Category.shopping:
        return FontAwesomeIcons.cartShopping;
      case Category.health:
        return FontAwesomeIcons.heartPulse;
      case Category.education:
        return FontAwesomeIcons.graduationCap;
      case Category.other:
        return FontAwesomeIcons.folder;
    }
  }

  String _getCategoryText() {
    switch (todo.category) {
      case Category.work:
        return '工作';
      case Category.personal:
        return '个人';
      case Category.shopping:
        return '购物';
      case Category.health:
        return '健康';
      case Category.education:
        return '教育';
      case Category.other:
        return '其他';
    }
  }

  String _formatDueDate() {
    final now = DateTime.now();
    final difference = todo.dueDate!.difference(now).inDays;

    if (difference == 0) {
      return '今天';
    } else if (difference == 1) {
      return '明天';
    } else if (difference == -1) {
      return '昨天';
    } else if (difference < 0) {
      return '${-difference}天前';
    } else if (difference <= 7) {
      return '$difference天后';
    } else {
      return '${todo.dueDate!.month}/${todo.dueDate!.day}';
    }
  }
}
