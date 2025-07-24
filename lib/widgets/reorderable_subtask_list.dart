import 'package:flutter/material.dart';
import '../models/subtask.dart';

class ReorderableSubtaskList extends StatelessWidget {
  final List<Subtask> subtasks;
  final Function(int) onSubtaskToggle;
  final Function(int) onSubtaskDelete;
  final Function(int, String) onSubtaskEdit;
  final Function(int, int) onReorder;

  const ReorderableSubtaskList({
    super.key,
    required this.subtasks,
    required this.onSubtaskToggle,
    required this.onSubtaskDelete,
    required this.onSubtaskEdit,
    required this.onReorder,
  });

  @override
  Widget build(BuildContext context) {
    if (subtasks.isEmpty) {
      return const SizedBox.shrink();
    }

    return ReorderableListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      buildDefaultDragHandles: false,
      itemCount: subtasks.length,
      onReorder: onReorder,
      itemBuilder: (context, index) {
        final subtask = subtasks[index];
        return Container(
          key: ValueKey('subtask_${subtask.id}_$index'),
          child: Row(
            children: [
              // 拖拽手柄
              ReorderableDragStartListener(
                index: index,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
                  child: Icon(
                    Icons.drag_handle,
                    color: Colors.grey.shade400,
                    size: 18,
                  ),
                ),
              ),

              // 子任务内容
              Expanded(
                child: _SubtaskItemWithEdit(
                  subtask: subtask,
                  index: index,
                  onToggle: () => onSubtaskToggle(index),
                  onDelete: () => onSubtaskDelete(index),
                  onEdit: (newTitle) => onSubtaskEdit(index, newTitle),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _SubtaskItemWithEdit extends StatefulWidget {
  final Subtask subtask;
  final int index;
  final VoidCallback onToggle;
  final VoidCallback onDelete;
  final Function(String) onEdit;

  const _SubtaskItemWithEdit({
    required this.subtask,
    required this.index,
    required this.onToggle,
    required this.onDelete,
    required this.onEdit,
  });

  @override
  State<_SubtaskItemWithEdit> createState() => _SubtaskItemWithEditState();
}

class _SubtaskItemWithEditState extends State<_SubtaskItemWithEdit> {
  bool _isEditing = false;
  late TextEditingController _editController;

  @override
  void initState() {
    super.initState();
    _editController = TextEditingController(text: widget.subtask.title);
  }

  @override
  void dispose() {
    _editController.dispose();
    super.dispose();
  }

  void _startEdit() {
    setState(() {
      _isEditing = true;
      _editController.text = widget.subtask.title;
      _editController.selection = TextSelection.fromPosition(
        TextPosition(offset: _editController.text.length),
      );
    });
  }

  void _saveEdit() {
    if (_editController.text.trim().isNotEmpty) {
      widget.onEdit(_editController.text.trim());
    }
    setState(() {
      _isEditing = false;
    });
  }

  void _cancelEdit() {
    setState(() {
      _isEditing = false;
    });
  }

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
              value: widget.subtask.isCompleted,
              onChanged: (_) => widget.onToggle(),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ),
          const SizedBox(width: 12),

          // 子任务内容
          Expanded(
            child: _isEditing ? _buildEditField() : _buildDisplayText(),
          ),

          // 删除按钮
          IconButton(
            onPressed: widget.onDelete,
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
    return GestureDetector(
      onTap: _startEdit,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
        child: Text(
          widget.subtask.title,
          style: TextStyle(
            decoration: widget.subtask.isCompleted
                ? TextDecoration.lineThrough
                : TextDecoration.none,
            color: widget.subtask.isCompleted ? Colors.grey.shade500 : null,
            fontSize: 14,
          ),
        ),
      ),
    );
  }

  Widget _buildEditField() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _editController,
              autofocus: true,
              style: const TextStyle(fontSize: 14),
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 8,
                ),
                isDense: true,
                hintText: '输入子任务内容',
              ),
              onSubmitted: (_) => _saveEdit(),
              onEditingComplete: _saveEdit,
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            onPressed: _saveEdit,
            icon: const Icon(Icons.check, color: Colors.green),
            iconSize: 18,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(
              minWidth: 28,
              minHeight: 28,
            ),
          ),
          IconButton(
            onPressed: _cancelEdit,
            icon: const Icon(Icons.close, color: Colors.red),
            iconSize: 18,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(
              minWidth: 28,
              minHeight: 28,
            ),
          ),
        ],
      ),
    );
  }
}
