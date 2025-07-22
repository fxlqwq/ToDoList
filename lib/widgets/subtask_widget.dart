import 'package:flutter/material.dart';
import '../models/subtask.dart';

class SubtaskWidget extends StatelessWidget {
  final Subtask subtask;
  final VoidCallback? onToggle;
  final VoidCallback? onDelete;
  final Function(String)? onEdit;
  final bool isEditing;

  const SubtaskWidget({
    super.key,
    required this.subtask,
    this.onToggle,
    this.onDelete,
    this.onEdit,
    this.isEditing = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        children: [
          // 完成状态复选框
          SizedBox(
            width: 24,
            height: 24,
            child: Checkbox(
              value: subtask.isCompleted,
              onChanged: (_) => onToggle?.call(),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ),
          const SizedBox(width: 12),

          // 子任务内容
          Expanded(
            child: isEditing ? _buildEditField() : _buildDisplayText(),
          ),

          // 删除按钮
          if (onDelete != null)
            IconButton(
              onPressed: onDelete,
              icon: const Icon(Icons.delete_outline),
              iconSize: 18,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(
                minWidth: 32,
                minHeight: 32,
              ),
              color: Colors.red.shade400,
            ),
        ],
      ),
    );
  }

  Widget _buildDisplayText() {
    return Text(
      subtask.title,
      style: TextStyle(
        fontSize: 14,
        decoration: subtask.isCompleted ? TextDecoration.lineThrough : null,
        color: subtask.isCompleted ? Colors.grey : null,
      ),
    );
  }

  Widget _buildEditField() {
    return TextField(
      controller: TextEditingController(text: subtask.title),
      onSubmitted: onEdit,
      decoration: const InputDecoration(
        isDense: true,
        border: UnderlineInputBorder(),
        contentPadding: EdgeInsets.symmetric(vertical: 4),
      ),
      style: const TextStyle(fontSize: 14),
      autofocus: true,
    );
  }
}

class SubtaskListWidget extends StatefulWidget {
  final List<Subtask> subtasks;
  final Function(int index)? onToggle;
  final Function(int index)? onDelete;
  final Function(int index, String title)? onEdit;
  final Function(String title)? onAdd;
  final bool showAddButton;

  const SubtaskListWidget({
    super.key,
    required this.subtasks,
    this.onToggle,
    this.onDelete,
    this.onEdit,
    this.onAdd,
    this.showAddButton = true,
  });

  @override
  State<SubtaskListWidget> createState() => _SubtaskListWidgetState();
}

class _SubtaskListWidgetState extends State<SubtaskListWidget> {
  int? editingIndex;
  final TextEditingController _newSubtaskController = TextEditingController();
  bool _showAddField = false;

  @override
  void dispose() {
    _newSubtaskController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.subtasks.isEmpty && !_showAddField && !widget.showAddButton) {
      return const SizedBox.shrink();
    }

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 标题
            Row(
              children: [
                const Icon(Icons.checklist, size: 20),
                const SizedBox(width: 8),
                Text(
                  '子任务 (${widget.subtasks.where((s) => s.isCompleted).length}/${widget.subtasks.length})',
                  style: Theme.of(context).textTheme.titleSmall,
                ),
              ],
            ),

            if (widget.subtasks.isNotEmpty || _showAddField) ...[
              const SizedBox(height: 12),

              // 子任务列表
              ...widget.subtasks.asMap().entries.map((entry) {
                final index = entry.key;
                final subtask = entry.value;

                return SubtaskWidget(
                  subtask: subtask,
                  isEditing: editingIndex == index,
                  onToggle: () => widget.onToggle?.call(index),
                  onDelete: () => widget.onDelete?.call(index),
                  onEdit: (title) {
                    if (title.trim().isNotEmpty) {
                      widget.onEdit?.call(index, title.trim());
                    }
                    setState(() {
                      editingIndex = null;
                    });
                  },
                );
              }),

              // 添加新子任务的输入框
              if (_showAddField) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    const SizedBox(width: 36), // 对齐复选框位置
                    Expanded(
                      child: TextField(
                        controller: _newSubtaskController,
                        decoration: const InputDecoration(
                          hintText: '输入子任务标题',
                          isDense: true,
                          border: UnderlineInputBorder(),
                          contentPadding: EdgeInsets.symmetric(vertical: 4),
                        ),
                        style: const TextStyle(fontSize: 14),
                        autofocus: true,
                        onSubmitted: _addSubtask,
                      ),
                    ),
                    IconButton(
                      onPressed: _addSubtask,
                      icon: const Icon(Icons.check, size: 18),
                      constraints: const BoxConstraints(
                        minWidth: 32,
                        minHeight: 32,
                      ),
                    ),
                    IconButton(
                      onPressed: () {
                        setState(() {
                          _showAddField = false;
                          _newSubtaskController.clear();
                        });
                      },
                      icon: const Icon(Icons.close, size: 18),
                      constraints: const BoxConstraints(
                        minWidth: 32,
                        minHeight: 32,
                      ),
                    ),
                  ],
                ),
              ],
            ],

            // 添加按钮
            if (widget.showAddButton && !_showAddField) ...[
              const SizedBox(height: 8),
              TextButton.icon(
                onPressed: () {
                  setState(() {
                    _showAddField = true;
                  });
                },
                icon: const Icon(Icons.add, size: 18),
                label: const Text('添加子任务'),
                style: TextButton.styleFrom(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _addSubtask([String? value]) {
    final title = value ?? _newSubtaskController.text.trim();
    if (title.isNotEmpty) {
      widget.onAdd?.call(title);
      _newSubtaskController.clear();
    }
    setState(() {
      _showAddField = false;
    });
  }
}
