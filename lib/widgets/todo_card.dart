import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../models/todo.dart';
import '../utils/app_theme.dart';

class TodoCard extends StatefulWidget {
  final Todo todo;
  final VoidCallback onToggle;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const TodoCard({
    super.key,
    required this.todo,
    required this.onToggle,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  State<TodoCard> createState() => _TodoCardState();
}

class _TodoCardState extends State<TodoCard> with TickerProviderStateMixin {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    return Dismissible(
      key: Key('todo_${widget.todo.id}'),
      background: _buildLeftBackground(),
      secondaryBackground: _buildRightBackground(),
      onDismissed: (direction) {
        if (direction == DismissDirection.endToStart) {
          // 向左滑动 - 删除（只有删除会真正移除卡片）
          widget.onDelete();
        }
      },
      confirmDismiss: (direction) async {
        if (direction == DismissDirection.startToEnd) {
          // 向右滑动 - 编辑
          widget.onEdit();
          return false; // 不删除卡片，只是触发编辑
        } else if (direction == DismissDirection.endToStart) {
          // 向左滑动 - 删除需要确认
          return await _showDeleteConfirmation();
        }
        return false;
      },
      child: GestureDetector(
        onTap: () {
          setState(() {
            _isExpanded = !_isExpanded;
          });
        },
        child: _buildTodoCard(),
      ),
    );
  }

  Widget _buildLeftBackground() {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      decoration: BoxDecoration(
        color: Colors.blue.shade400,
        borderRadius: BorderRadius.circular(16),
      ),
      child: const Align(
        alignment: Alignment.centerLeft,
        child: Padding(
          padding: EdgeInsets.only(left: 20),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.edit, color: Colors.white, size: 24),
              SizedBox(width: 8),
              Text(
                '编辑',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRightBackground() {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      decoration: BoxDecoration(
        color: Colors.red.shade400,
        borderRadius: BorderRadius.circular(16),
      ),
      child: const Align(
        alignment: Alignment.centerRight,
        child: Padding(
          padding: EdgeInsets.only(right: 20),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '删除',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(width: 8),
              Icon(Icons.delete, color: Colors.white, size: 24),
            ],
          ),
        ),
      ),
    );
  }

  Future<bool?> _showDeleteConfirmation() async {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('确认删除'),
        content: Text('确定要删除"${widget.todo.title}"吗？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('删除', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  Widget _buildTodoCard() {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      margin: const EdgeInsets.symmetric(vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
        border: Border.all(
          color: widget.todo.isCompleted
              ? AppTheme.secondaryColor.withOpacity(0.3)
              : Colors.transparent,
          width: 2,
        ),
      ),
      child: Column(
        children: [
          _buildMainContent(),
          if (_isExpanded) _buildExpandedContent(),
        ],
      ),
    );
  }

  Widget _buildMainContent() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          // 完成状态勾选框
          GestureDetector(
            onTap: widget.onToggle,
            child: Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: widget.todo.isCompleted
                      ? AppTheme.primaryColor
                      : Colors.grey.shade400,
                  width: 2,
                ),
                color: widget.todo.isCompleted
                    ? AppTheme.primaryColor
                    : Colors.transparent,
              ),
              child: widget.todo.isCompleted
                  ? const Icon(
                      Icons.check,
                      size: 16,
                      color: Colors.white,
                    )
                  : null,
            ),
          ),
          const SizedBox(width: 12),
          // 任务内容
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.todo.title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: widget.todo.isCompleted
                        ? Colors.grey.shade500
                        : Colors.black87,
                    decoration: widget.todo.isCompleted
                        ? TextDecoration.lineThrough
                        : null,
                  ),
                  maxLines: _isExpanded ? null : 3, // 允许标题显示更多行
                  overflow: _isExpanded ? null : TextOverflow.ellipsis,
                ),
                if (widget.todo.description.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    widget.todo.description,
                    style: TextStyle(
                      fontSize: 14,
                      color: widget.todo.isCompleted
                          ? Colors.grey.shade400
                          : Colors.grey.shade600,
                      decoration: widget.todo.isCompleted
                          ? TextDecoration.lineThrough
                          : null,
                    ),
                    maxLines: _isExpanded ? null : 2,
                    overflow: _isExpanded ? null : TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),
          // 优先级和类别标识
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              _buildPriorityIndicator(),
              if (widget.todo.category != Category.other) ...[
                const SizedBox(height: 4),
                _buildCategoryChip(),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildExpandedContent() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Divider(height: 1),
          const SizedBox(height: 12),
          if (widget.todo.dueDate != null) ...[
            _buildInfoRow(
              Icons.schedule,
              '截止时间',
              _formatDueDate(widget.todo.dueDate!),
              _isOverdue() ? Colors.red.shade600 : Colors.grey.shade600,
            ),
            const SizedBox(height: 8),
          ],
          if (widget.todo.tags.isNotEmpty) ...[
            _buildInfoRow(
              Icons.local_offer,
              '标签',
              widget.todo.tags.join(', '),
              Colors.grey.shade600,
            ),
            const SizedBox(height: 8),
          ],
          _buildInfoRow(
            Icons.access_time,
            '创建时间',
            _formatCreatedDate(widget.todo.createdAt),
            Colors.grey.shade600,
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value, Color color) {
    return Row(
      children: [
        Icon(icon, size: 16, color: color),
        const SizedBox(width: 8),
        Text(
          '$label: ',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: color,
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: TextStyle(
              fontSize: 12,
              color: color,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPriorityIndicator() {
    Color priorityColor;
    IconData priorityIcon;
    String priorityText;

    switch (widget.todo.priority) {
      case Priority.high:
        priorityColor = Colors.red.shade400;
        priorityIcon = FontAwesomeIcons.arrowUp;
        priorityText = '高';
        break;
      case Priority.medium:
        priorityColor = Colors.orange.shade400;
        priorityIcon = FontAwesomeIcons.minus;
        priorityText = '中';
        break;
      case Priority.low:
      default:
        priorityColor = Colors.green.shade400;
        priorityIcon = FontAwesomeIcons.arrowDown;
        priorityText = '低';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: priorityColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: priorityColor.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          FaIcon(
            priorityIcon,
            size: 10,
            color: priorityColor,
          ),
          const SizedBox(width: 4),
          Text(
            priorityText,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: priorityColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryChip() {
    Color categoryColor = _getCategoryColor(widget.todo.category);
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: categoryColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: categoryColor.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Text(
        _getCategoryDisplayName(widget.todo.category),
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w600,
          color: categoryColor,
        ),
      ),
    );
  }

  Color _getCategoryColor(Category category) {
    switch (category) {
      case Category.work:
        return Colors.blue.shade600;
      case Category.personal:
        return Colors.green.shade600;
      case Category.shopping:
        return Colors.purple.shade600;
      case Category.health:
        return Colors.red.shade600;
      case Category.education:
        return Colors.orange.shade600;
      default:
        return Colors.grey.shade600;
    }
  }

  String _getCategoryDisplayName(Category category) {
    switch (category) {
      case Category.work:
        return '工作';
      case Category.personal:
        return '个人';
      case Category.shopping:
        return '购物';
      case Category.health:
        return '健康';
      case Category.education:
        return '学习';
      default:
        return '';
    }
  }

  bool _isOverdue() {
    if (widget.todo.dueDate == null) return false;
    return widget.todo.dueDate!.isBefore(DateTime.now()) && !widget.todo.isCompleted;
  }

  String _formatDueDate(DateTime dueDate) {
    final now = DateTime.now();
    final difference = dueDate.difference(now).inDays;
    
    if (difference == 0) {
      return '今天 ${_formatTime(dueDate)}';
    } else if (difference == 1) {
      return '明天 ${_formatTime(dueDate)}';
    } else if (difference == -1) {
      return '昨天 ${_formatTime(dueDate)}';
    } else if (difference > 1 && difference <= 7) {
      return '$difference天后 ${_formatTime(dueDate)}';
    } else if (difference < -1 && difference >= -7) {
      return '${difference.abs()}天前 ${_formatTime(dueDate)}';
    } else {
      return '${dueDate.month}月${dueDate.day}日 ${_formatTime(dueDate)}';
    }
  }

  String _formatCreatedDate(DateTime createdAt) {
    final now = DateTime.now();
    final difference = now.difference(createdAt).inDays;
    
    if (difference == 0) {
      return '今天 ${_formatTime(createdAt)}';
    } else if (difference == 1) {
      return '昨天 ${_formatTime(createdAt)}';
    } else if (difference <= 7) {
      return '$difference天前';
    } else {
      return '${createdAt.month}月${createdAt.day}日';
    }
  }

  String _formatTime(DateTime dateTime) {
    return '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }
}
