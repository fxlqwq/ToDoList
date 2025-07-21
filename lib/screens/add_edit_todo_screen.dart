import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:intl/intl.dart';
import '../models/todo.dart';
import '../services/todo_provider.dart';
import '../utils/app_theme.dart';

class AddEditTodoScreen extends StatefulWidget {
  final Todo? todo;

  const AddEditTodoScreen({
    super.key,
    this.todo,
  });

  @override
  State<AddEditTodoScreen> createState() => _AddEditTodoScreenState();
}

class _AddEditTodoScreenState extends State<AddEditTodoScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _tagsController = TextEditingController();

  Category _selectedCategory = Category.personal;
  Priority _selectedPriority = Priority.medium;
  DateTime? _selectedDueDate;
  TimeOfDay? _selectedDueTime;
  DateTime? _selectedReminderDate;
  TimeOfDay? _selectedReminderTime;
  bool _hasReminder = false;
  List<String> _tags = [];

  bool get _isEditing => widget.todo != null;

  @override
  void initState() {
    super.initState();
    if (_isEditing) {
      _populateFields();
    }
  }

  void _populateFields() {
    final todo = widget.todo!;
    _titleController.text = todo.title;
    _descriptionController.text = todo.description;
    _selectedCategory = todo.category;
    _selectedPriority = todo.priority;
    _selectedDueDate = todo.dueDate;
    if (todo.dueDate != null) {
      _selectedDueTime = TimeOfDay.fromDateTime(todo.dueDate!);
    }
    _hasReminder = todo.hasReminder;
    _selectedReminderDate = todo.reminderDate;
    if (todo.reminderDate != null) {
      _selectedReminderTime = TimeOfDay.fromDateTime(todo.reminderDate!);
    }
    _tags = List.from(todo.tags);
    _tagsController.text = _tags.join(', ');
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _tagsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _buildAppBar(),
      body: _buildBody(),
      bottomNavigationBar: SafeArea(
        child: _buildBottomBar(),
      ),
    );
  }

  AppBar _buildAppBar() {
    return AppBar(
      title: Text(_isEditing ? '编辑任务' : '添加新任务'),
      backgroundColor: Colors.transparent,
      elevation: 0,
      actions: [
        if (_isEditing)
          IconButton(
            onPressed: _showDeleteConfirmation,
            icon: const Icon(Icons.delete_outline),
            tooltip: '删除任务',
          ),
      ],
    );
  }

  Widget _buildBody() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildTitleField(),
            const SizedBox(height: 20),
            _buildDescriptionField(),
            const SizedBox(height: 20),
            _buildCategorySection(),
            const SizedBox(height: 20),
            _buildPrioritySection(),
            const SizedBox(height: 20),
            _buildDueDateSection(),
            const SizedBox(height: 20),
            _buildReminderSection(),
            const SizedBox(height: 20),
            _buildTagsSection(),
            const SizedBox(height: 100), // 增加底部间距防止溢出
          ],
        ),
      ),
    );
  }

  Widget _buildTitleField() {
    return TextFormField(
      controller: _titleController,
      decoration: const InputDecoration(
        labelText: '任务标题 *',
        hintText: '请输入任务标题',
        prefixIcon: Icon(Icons.title),
      ),
      validator: (value) {
        if (value == null || value.trim().isEmpty) {
          return '请输入任务标题';
        }
        return null;
      },
      textCapitalization: TextCapitalization.sentences,
      maxLines: 2, // 允许标题换行显示
      minLines: 1,
    );
  }

  Widget _buildDescriptionField() {
    return TextFormField(
      controller: _descriptionController,
      maxLines: 3,
      decoration: const InputDecoration(
        labelText: '任务描述',
        hintText: '请输入任务描述',
        prefixIcon: Icon(Icons.description),
        alignLabelWithHint: true,
      ),
      textCapitalization: TextCapitalization.sentences,
    );
  }

  Widget _buildCategorySection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '任务分类',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: Category.values.map((category) {
            final isSelected = _selectedCategory == category;
            final categoryText = _getCategoryText(category);
            final categoryColor = AppTheme.getCategoryColor(categoryText);

            return GestureDetector(
              onTap: () {
                setState(() {
                  _selectedCategory = category;
                });
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: isSelected
                      ? categoryColor.withOpacity(0.2)
                      : Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isSelected ? categoryColor : Colors.grey.shade300,
                    width: isSelected ? 2 : 1,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      _getCategoryIcon(category),
                      size: 16,
                      color: isSelected ? categoryColor : Colors.grey.shade600,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      categoryText,
                      style: TextStyle(
                        color: isSelected ? categoryColor : Colors.grey.shade700,
                        fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildPrioritySection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '优先级',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: Priority.values.map((priority) {
            final isSelected = _selectedPriority == priority;
            final priorityText = _getPriorityText(priority);
            final priorityColor = AppTheme.getPriorityColor(priorityText);

            return Expanded(
              child: GestureDetector(
                onTap: () {
                  setState(() {
                    _selectedPriority = priority;
                  });
                },
                child: Container(
                  margin: const EdgeInsets.only(right: 8),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? priorityColor.withOpacity(0.2)
                        : Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isSelected ? priorityColor : Colors.grey.shade300,
                      width: isSelected ? 2 : 1,
                    ),
                  ),
                  child: Column(
                    children: [
                      Icon(
                        _getPriorityIcon(priority),
                        color: isSelected ? priorityColor : Colors.grey.shade600,
                        size: 20,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        priorityText,
                        style: TextStyle(
                          color: isSelected ? priorityColor : Colors.grey.shade700,
                          fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildDueDateSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '截止日期',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _selectDueDate,
                icon: const Icon(Icons.calendar_today),
                label: Text(
                  _selectedDueDate != null
                      ? DateFormat('MM月dd日 yyyy年').format(_selectedDueDate!)
                      : '选择日期',
                ),
                style: OutlinedButton.styleFrom(
                  foregroundColor: _selectedDueDate != null
                      ? AppTheme.primaryColor
                      : Colors.grey.shade600,
                  side: BorderSide(
                    color: _selectedDueDate != null
                        ? AppTheme.primaryColor
                        : Colors.grey.shade300,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _selectedDueDate != null ? _selectDueTime : null,
                icon: const Icon(Icons.access_time),
                label: Text(
                  _selectedDueTime != null
                      ? _selectedDueTime!.format(context)
                      : '选择时间',
                ),
                style: OutlinedButton.styleFrom(
                  foregroundColor: _selectedDueTime != null
                      ? AppTheme.primaryColor
                      : Colors.grey.shade600,
                  side: BorderSide(
                    color: _selectedDueTime != null
                        ? AppTheme.primaryColor
                        : Colors.grey.shade300,
                  ),
                ),
              ),
            ),
          ],
        ),
        if (_selectedDueDate != null) ...[
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton.icon(
                onPressed: _clearDueDate,
                icon: const Icon(Icons.clear, size: 16),
                label: const Text('清除'),
                style: TextButton.styleFrom(
                  foregroundColor: Colors.grey.shade600,
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }

  Widget _buildReminderSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text(
              '提醒设置',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const Spacer(),
            Switch(
              value: _hasReminder,
              onChanged: (value) {
                setState(() {
                  _hasReminder = value;
                  if (!value) {
                    _selectedReminderDate = null;
                    _selectedReminderTime = null;
                  }
                });
              },
            ),
          ],
        ),
        if (_hasReminder) ...[
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _selectReminderDate,
                  icon: const Icon(Icons.notifications),
                  label: Text(
                    _selectedReminderDate != null
                        ? DateFormat('MM月dd日 yyyy年').format(_selectedReminderDate!)
                        : '选择提醒日期',
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: _selectedReminderDate != null
                        ? AppTheme.accentColor
                        : Colors.grey.shade600,
                    side: BorderSide(
                      color: _selectedReminderDate != null
                          ? AppTheme.accentColor
                          : Colors.grey.shade300,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _selectedReminderDate != null ? _selectReminderTime : null,
                  icon: const Icon(Icons.access_time),
                  label: Text(
                    _selectedReminderTime != null
                        ? _selectedReminderTime!.format(context)
                        : '选择提醒时间',
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: _selectedReminderTime != null
                        ? AppTheme.accentColor
                        : Colors.grey.shade600,
                    side: BorderSide(
                      color: _selectedReminderTime != null
                          ? AppTheme.accentColor
                          : Colors.grey.shade300,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }

  Widget _buildTagsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '标签',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: _tagsController,
          decoration: const InputDecoration(
            hintText: '输入标签，用逗号分隔',
            prefixIcon: Icon(Icons.tag),
          ),
          onChanged: (value) {
            setState(() {
              _tags = value
                  .split(',')
                  .map((tag) => tag.trim())
                  .where((tag) => tag.isNotEmpty)
                  .toList();
            });
          },
        ),
        if (_tags.isNotEmpty) ...[
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 4,
            children: _tags.map((tag) {
              return Chip(
                label: Text('#$tag'),
                backgroundColor: AppTheme.primaryColor.withOpacity(0.1),
                labelStyle: const TextStyle(
                  color: AppTheme.primaryColor,
                  fontSize: 12,
                ),
              );
            }).toList(),
          ),
        ],
      ],
    );
  }

  Widget _buildBottomBar() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('取消'),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            flex: 2,
            child: ElevatedButton(
              onPressed: _saveTodo,
              child: Text(_isEditing ? '更新任务' : '创建任务'),
            ),
          ),
        ],
      ),
    );
  }  // Helper methods
  String _getCategoryText(Category category) {
    switch (category) {
      case Category.personal:
        return '个人';
      case Category.work:
        return '工作';
      case Category.health:
        return '健康';
      case Category.shopping:
        return '购物';
      case Category.education:
        return '学习';
      case Category.other:
        return '其他';
    }
  }

  IconData _getCategoryIcon(Category category) {
    switch (category) {
      case Category.personal:
        return FontAwesomeIcons.user;
      case Category.work:
        return FontAwesomeIcons.briefcase;
      case Category.health:
        return FontAwesomeIcons.heartPulse;
      case Category.shopping:
        return FontAwesomeIcons.cartShopping;
      case Category.education:
        return FontAwesomeIcons.graduationCap;
      case Category.other:
        return FontAwesomeIcons.ellipsis;
    }
  }

  String _getPriorityText(Priority priority) {
    switch (priority) {
      case Priority.low:
        return '低';
      case Priority.medium:
        return '中';
      case Priority.high:
        return '高';
    }
  }

  IconData _getPriorityIcon(Priority priority) {
    switch (priority) {
      case Priority.low:
        return FontAwesomeIcons.arrowDown;
      case Priority.medium:
        return FontAwesomeIcons.minus;
      case Priority.high:
        return FontAwesomeIcons.arrowUp;
    }
  }

  // Date and time pickers
  void _selectDueDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _selectedDueDate ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (date != null) {
      setState(() {
        _selectedDueDate = date;
        if (_selectedDueTime == null) {
          _selectedDueTime = const TimeOfDay(hour: 9, minute: 0);
        }
      });
    }
  }

  void _selectDueTime() async {
    final time = await showTimePicker(
      context: context,
      initialTime: _selectedDueTime ?? const TimeOfDay(hour: 9, minute: 0),
    );
    if (time != null) {
      setState(() {
        _selectedDueTime = time;
      });
    }
  }

  void _selectReminderDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _selectedReminderDate ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (date != null) {
      setState(() {
        _selectedReminderDate = date;
        if (_selectedReminderTime == null) {
          _selectedReminderTime = const TimeOfDay(hour: 8, minute: 0);
        }
      });
    }
  }

  void _selectReminderTime() async {
    final time = await showTimePicker(
      context: context,
      initialTime: _selectedReminderTime ?? const TimeOfDay(hour: 8, minute: 0),
    );
    if (time != null) {
      setState(() {
        _selectedReminderTime = time;
      });
    }
  }

  void _clearDueDate() {
    setState(() {
      _selectedDueDate = null;
      _selectedDueTime = null;
    });
  }

  // Save todo
  void _saveTodo() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    DateTime? dueDateTime;
    if (_selectedDueDate != null) {
      final time = _selectedDueTime ?? const TimeOfDay(hour: 23, minute: 59);
      dueDateTime = DateTime(
        _selectedDueDate!.year,
        _selectedDueDate!.month,
        _selectedDueDate!.day,
        time.hour,
        time.minute,
      );
    }

    DateTime? reminderDateTime;
    if (_hasReminder && _selectedReminderDate != null) {
      final time = _selectedReminderTime ?? const TimeOfDay(hour: 8, minute: 0);
      reminderDateTime = DateTime(
        _selectedReminderDate!.year,
        _selectedReminderDate!.month,
        _selectedReminderDate!.day,
        time.hour,
        time.minute,
      );
    }

    final todo = Todo(
      id: _isEditing ? widget.todo!.id : null,
      title: _titleController.text.trim(),
      description: _descriptionController.text.trim(),
      category: _selectedCategory,
      priority: _selectedPriority,
      dueDate: dueDateTime,
      hasReminder: _hasReminder,
      reminderDate: reminderDateTime,
      tags: _tags,
      isCompleted: _isEditing ? widget.todo!.isCompleted : false,
      createdAt: _isEditing ? widget.todo!.createdAt : DateTime.now(),
    );

    final todoProvider = context.read<TodoProvider>();
    bool success;

    if (_isEditing) {
      success = await todoProvider.updateTodo(todo);
    } else {
      success = await todoProvider.addTodo(todo);
    }

    if (success && mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _isEditing ? '任务更新成功！' : '任务创建成功！',
          ),
          backgroundColor: AppTheme.secondaryColor,
        ),
      );
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('保存任务失败，请重试。'),
          backgroundColor: AppTheme.errorColor,
        ),
      );
    }
  }

  void _showDeleteConfirmation() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('删除任务'),
        content: Text('确定要删除 "${widget.todo!.title}" 吗？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () async {
              final success = await context.read<TodoProvider>().deleteTodo(widget.todo!.id!);
              if (mounted) {
                Navigator.pop(context); // Close dialog
                Navigator.pop(context); // Close screen
                if (success) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('任务删除成功！'),
                      backgroundColor: AppTheme.secondaryColor,
                    ),
                  );
                }
              }
            },
            child: const Text('删除'),
          ),
        ],
      ),
    );
  }
}
