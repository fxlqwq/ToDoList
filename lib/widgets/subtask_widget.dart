import 'package:flutter/material.dart';
import '../models/subtask.dart';

class SubtaskWidget extends StatefulWidget {
  final Subtask subtask;
  final VoidCallback? onToggle;
  final VoidCallback? onDelete;
  final Function(String)? onEdit;
  final bool isEditing;
  final VoidCallback? onStartEdit;
  final VoidCallback? onCancelEdit;

  const SubtaskWidget({
    super.key,
    required this.subtask,
    this.onToggle,
    this.onDelete,
    this.onEdit,
    this.isEditing = false,
    this.onStartEdit,
    this.onCancelEdit,
  });

  @override
  State<SubtaskWidget> createState() => _SubtaskWidgetState();
}

class _SubtaskWidgetState extends State<SubtaskWidget> {
  late TextEditingController _editController;

  @override
  void initState() {
    super.initState();
    _editController = TextEditingController(text: widget.subtask.title);
  }

  @override
  void didUpdateWidget(SubtaskWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isEditing && !oldWidget.isEditing) {
      _editController.text = widget.subtask.title;
      _editController.selection = TextSelection.fromPosition(
        TextPosition(offset: _editController.text.length),
      );
    }
  }

  @override
  void dispose() {
    _editController.dispose();
    super.dispose();
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
              onChanged: (_) => widget.onToggle?.call(),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ),
          const SizedBox(width: 12),

          // 子任务内容
          Expanded(
            child: widget.isEditing ? _buildEditField() : _buildDisplayText(),
          ),

          // 删除按钮
          if (widget.onDelete != null)
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
      onTap: widget.onStartEdit,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 2),
        child: Text(
          widget.subtask.title,
          style: TextStyle(
            fontSize: 14,
            decoration:
                widget.subtask.isCompleted ? TextDecoration.lineThrough : null,
            color: widget.subtask.isCompleted ? Colors.grey : null,
          ),
        ),
      ),
    );
  }

  Widget _buildEditField() {
    return Row(
      children: [
        Expanded(
          child: TextField(
            controller: _editController,
            onSubmitted: (value) => _handleSubmit(),
            decoration: const InputDecoration(
              isDense: true,
              border: UnderlineInputBorder(),
              contentPadding: EdgeInsets.symmetric(vertical: 4),
            ),
            style: const TextStyle(fontSize: 14),
            autofocus: true,
          ),
        ),
        // 确认按钮
        IconButton(
          onPressed: _handleSubmit,
          icon: const Icon(Icons.check, size: 18),
          constraints: const BoxConstraints(
            minWidth: 32,
            minHeight: 32,
          ),
          color: Colors.green.shade600,
          padding: EdgeInsets.zero,
        ),
        // 取消按钮
        IconButton(
          onPressed: () => widget.onCancelEdit?.call(),
          icon: const Icon(Icons.close, size: 18),
          constraints: const BoxConstraints(
            minWidth: 32,
            minHeight: 32,
          ),
          color: Colors.red.shade400,
          padding: EdgeInsets.zero,
        ),
      ],
    );
  }

  void _handleSubmit() {
    final text = _editController.text.trim();
    if (text.isNotEmpty) {
      widget.onEdit?.call(text);
    } else {
      widget.onCancelEdit?.call();
    }
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
                  onStartEdit: () {
                    setState(() {
                      editingIndex = index;
                    });
                  },
                  onEdit: (title) {
                    if (title.trim().isNotEmpty) {
                      widget.onEdit?.call(index, title.trim());
                    }
                    setState(() {
                      editingIndex = null;
                    });
                  },
                  onCancelEdit: () {
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
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      TextButton.icon(
                        onPressed: () {
                          setState(() {
                            _showAddField = true;
                          });
                        },
                        icon: const Icon(Icons.add, size: 18),
                        label: const Text('添加子任务'),
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: _showBatchAddDialog,
                      icon: const Icon(Icons.playlist_add, size: 18),
                      label: const Text('批量添加多个子任务'),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 8),
                        side: BorderSide(
                          color: Theme.of(context)
                              .primaryColor
                              .withValues(alpha: 0.5),
                          width: 1.5,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ),
                ],
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

  void _showBatchAddDialog() {
    final TextEditingController batchController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.playlist_add, size: 24),
            SizedBox(width: 8),
            Text('批量添加子任务'),
          ],
        ),
        content: SizedBox(
          width: double.maxFinite,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                '请输入子任务，每行一个：',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: batchController,
                decoration: const InputDecoration(
                  hintText: '例如：\n更新ubuntu\n重装windows\n备份数据\n清理系统缓存',
                  border: OutlineInputBorder(),
                  contentPadding: EdgeInsets.all(12),
                  helperText: '支持粘贴多行文本',
                  helperMaxLines: 2,
                ),
                maxLines: 8,
                minLines: 4,
                autofocus: true,
                textCapitalization: TextCapitalization.sentences,
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blue.shade200),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.info_outline, size: 16, color: Colors.blue),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '每行内容将成为一个子任务，空行将被忽略',
                        style: TextStyle(fontSize: 12, color: Colors.blue),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () {
              final text = batchController.text.trim();
              if (text.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('请输入至少一个子任务'),
                    backgroundColor: Colors.orange,
                    duration: Duration(seconds: 2),
                  ),
                );
                return;
              }

              final lines = text
                  .split('\n')
                  .map((line) => line.trim())
                  .where((line) => line.isNotEmpty)
                  .toList();

              if (lines.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('没有找到有效的子任务内容'),
                    backgroundColor: Colors.orange,
                    duration: Duration(seconds: 2),
                  ),
                );
                return;
              }

              // 添加所有子任务
              int addedCount = 0;
              for (String line in lines) {
                if (line.length <= 200) {
                  // 限制子任务标题长度
                  widget.onAdd?.call(line);
                  addedCount++;
                } else {
                  // 如果某行太长，截断并添加
                  final truncated = '${line.substring(0, 197)}...';
                  widget.onAdd?.call(truncated);
                  addedCount++;
                }
              }

              Navigator.of(context).pop();

              // 显示成功消息
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('✅ 已成功添加 $addedCount 个子任务'),
                  backgroundColor: Colors.green,
                  duration: const Duration(seconds: 3),
                  action: SnackBarAction(
                    label: '知道了',
                    textColor: Colors.white,
                    onPressed: () {
                      ScaffoldMessenger.of(context).hideCurrentSnackBar();
                    },
                  ),
                ),
              );
            },
            child: const Text('确定添加'),
          ),
        ],
      ),
    );
  }
}
