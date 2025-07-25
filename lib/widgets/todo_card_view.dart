import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../models/todo.dart';

class TodoGridView extends StatelessWidget {
  final Todo todo;
  final VoidCallback onTap;
  final VoidCallback onLongPress;
  final Function(int subtaskIndex)? onSubtaskToggle;
  final VoidCallback? onMainTaskToggle; // 新增：主任务状态切换

  const TodoGridView({
    super.key,
    required this.todo,
    required this.onTap,
    required this.onLongPress,
    this.onSubtaskToggle,
    this.onMainTaskToggle, // 新增参数
  });

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 400;

    return Card(
      elevation: 2,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: onTap,
        onLongPress: onLongPress,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: EdgeInsets.all(isSmallScreen ? 4 : 6),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min, // 重要：只占用必要空间
            mainAxisAlignment: MainAxisAlignment.start, // 内容贴顶
            children: [
              // 头部：完成状态 + 优先级
              Row(
                children: [
                  GestureDetector(
                    onTap: onMainTaskToggle,
                    child: Container(
                      width: isSmallScreen ? 14 : 16,
                      height: isSmallScreen ? 14 : 16,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: todo.isCompleted
                              ? Colors.green
                              : _getPriorityColor(),
                          width: 2,
                        ),
                        color: todo.isCompleted
                            ? Colors.green
                            : Colors.transparent,
                      ),
                      child: todo.isCompleted
                          ? Icon(
                              Icons.check,
                              size: isSmallScreen ? 8 : 10,
                              color: Colors.white,
                            )
                          : null,
                    ),
                  ),
                  const Spacer(),
                  if (todo.priority != Priority.medium)
                    Container(
                      width: isSmallScreen ? 6 : 8,
                      height: isSmallScreen ? 6 : 8,
                      decoration: BoxDecoration(
                        color: _getPriorityColor(),
                        shape: BoxShape.circle,
                      ),
                    ),
                ],
              ),

              SizedBox(height: isSmallScreen ? 2 : 3),

              // 标题
              Text(
                todo.title,
                style: TextStyle(
                  fontSize: isSmallScreen ? 12 : 13,
                  fontWeight: FontWeight.w600,
                  decoration:
                      todo.isCompleted ? TextDecoration.lineThrough : null,
                  color: todo.isCompleted ? Colors.grey.shade500 : null,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),

              // 描述（如果有）
              if (todo.description.isNotEmpty) ...[
                SizedBox(height: isSmallScreen ? 1 : 2),
                Text(
                  todo.description,
                  style: TextStyle(
                    fontSize: isSmallScreen ? 9 : 10,
                    color: Colors.grey.shade600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],

              SizedBox(height: isSmallScreen ? 1 : 2),

              // 子任务详情 - 紧凑显示，不强制占用空间
              if (todo.hasSubtasks) ...[
                _buildCompactSubtasks(isSmallScreen),
              ],

              // 底部信息 - 紧贴子任务或标题，无额外间距
              Row(
                children: [
                  // 分类图标
                  Container(
                    padding: EdgeInsets.all(isSmallScreen ? 2 : 3),
                    decoration: BoxDecoration(
                      color: _getCategoryColor().withOpacity(0.1),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Icon(
                      _getCategoryIcon(),
                      size: isSmallScreen ? 8 : 10,
                      color: _getCategoryColor(),
                    ),
                  ),

                  // 使用Expanded而不是Spacer，让状态图标贴右边
                  Expanded(child: Container()),

                  // 状态图标
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (todo.hasReminder)
                        Icon(
                          FontAwesomeIcons.bell,
                          size: isSmallScreen ? 8 : 10,
                          color: Colors.grey.shade500,
                        ),
                      if (todo.hasAttachments) ...[
                        if (todo.hasReminder)
                          SizedBox(width: isSmallScreen ? 2 : 4),
                        Icon(
                          FontAwesomeIcons.paperclip,
                          size: isSmallScreen ? 8 : 10,
                          color: Colors.grey.shade500,
                        ),
                      ],
                      if (todo.dueDate != null) ...[
                        if (todo.hasReminder || todo.hasAttachments)
                          SizedBox(width: isSmallScreen ? 2 : 4),
                        Icon(
                          FontAwesomeIcons.calendar,
                          size: isSmallScreen ? 8 : 10,
                          color: _getDueDateColor(),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // 紧凑的子任务显示
  Widget _buildCompactSubtasks(bool isSmallScreen) {
    final completedSubtasks = todo.subtasks.where((s) => s.isCompleted).length;
    final totalSubtasks = todo.subtasks.length;
    final progress =
        totalSubtasks > 0 ? completedSubtasks / totalSubtasks : 0.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        // 子任务进度条和数量
        Row(
          children: [
            Expanded(
              child: Container(
                height: isSmallScreen ? 2 : 3,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(1.5),
                  color: Colors.grey.shade200,
                ),
                child: FractionallySizedBox(
                  widthFactor: progress,
                  alignment: Alignment.centerLeft,
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(1.5),
                      color: progress == 1.0 ? Colors.green : Colors.blue,
                    ),
                  ),
                ),
              ),
            ),
            SizedBox(width: isSmallScreen ? 3 : 4),
            Text(
              '$completedSubtasks/$totalSubtasks',
              style: TextStyle(
                fontSize: isSmallScreen ? 7 : 8,
                fontWeight: FontWeight.bold,
                color: progress == 1.0 ? Colors.green : Colors.orange,
              ),
            ),
          ],
        ),

        // 显示所有子任务，使用极致紧凑布局
        if (totalSubtasks > 0) ...[
          SizedBox(height: isSmallScreen ? 1 : 2),
          // 增大子任务显示的最大高度，以适应更大的字体和更多子任务
          ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: isSmallScreen ? 100 : 120, // 大幅增加高度限制以显示更多子任务
            ),
            child: SingleChildScrollView(
              // 如果子任务太多，允许滚动
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: todo.subtasks.map((subtask) {
                  final index = todo.subtasks.indexOf(subtask);
                  return GestureDetector(
                    onTap: () => onSubtaskToggle?.call(index),
                    child: Container(
                      margin: EdgeInsets.only(bottom: isSmallScreen ? 1.5 : 2),
                      padding: EdgeInsets.symmetric(
                          vertical: isSmallScreen ? 3 : 4,
                          horizontal: 3), // 增大点击区域
                      child: Row(
                        children: [
                          Container(
                            width: isSmallScreen ? 18 : 21, // 增大复选框
                            height: isSmallScreen ? 18 : 21,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: subtask.isCompleted
                                    ? Colors.green
                                    : Colors.grey.shade400,
                                width: 1,
                              ),
                              color: subtask.isCompleted
                                  ? Colors.green
                                  : Colors.transparent,
                            ),
                            child: subtask.isCompleted
                                ? Icon(
                                    Icons.check,
                                    size: isSmallScreen ? 10 : 12, // 增大对勾
                                    color: Colors.white,
                                  )
                                : null,
                          ),
                          SizedBox(width: isSmallScreen ? 3 : 4),
                          Expanded(
                            child: Text(
                              subtask.title,
                              style: TextStyle(
                                fontSize: isSmallScreen ? 8 : 9,
                                color: subtask.isCompleted
                                    ? Colors.grey.shade500
                                    : Colors.grey.shade700,
                                decoration: subtask.isCompleted
                                    ? TextDecoration.lineThrough
                                    : null,
                                height: 1.3, // 稍微增加行高便于阅读
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
        ],
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
        return FontAwesomeIcons.shoppingCart;
      case Category.health:
        return FontAwesomeIcons.heartPulse;
      case Category.education:
        return FontAwesomeIcons.graduationCap;
      case Category.other:
        return FontAwesomeIcons.folder;
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
