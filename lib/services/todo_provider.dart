import 'package:flutter/material.dart';
import '../models/todo.dart';
import '../models/subtask.dart';
import '../models/attachment.dart';
import '../models/project_group.dart';
import '../services/database_service.dart';
import '../services/notification_service.dart';

class TodoProvider with ChangeNotifier {
  final DatabaseService _databaseService = DatabaseService();
  final NotificationService _notificationService = NotificationService();

  List<Todo> _todos = [];
  List<Todo> _filteredTodos = [];
  List<ProjectGroup> _projectGroups = [];
  ProjectGroup? _selectedProjectGroup;
  String _searchQuery = '';
  Category? _selectedCategory;
  Priority? _selectedPriority;
  bool _showCompleted = true;
  String _sortBy = 'createdAt'; // 'createdAt', 'dueDate', 'priority', 'title'
  bool _sortAscending = false;

  // Getters
  List<Todo> get todos => _filteredTodos;
  List<Todo> get allTodos => _todos;
  List<ProjectGroup> get projectGroups => _projectGroups;
  ProjectGroup? get selectedProjectGroup => _selectedProjectGroup;
  String get searchQuery => _searchQuery;
  Category? get selectedCategory => _selectedCategory;
  Priority? get selectedPriority => _selectedPriority;
  bool get showCompleted => _showCompleted;
  String get sortBy => _sortBy;
  bool get sortAscending => _sortAscending;

  // Statistics
  int get totalTodos => _todos.length;
  int get completedTodos => _todos.where((todo) => todo.isCompleted).length;
  int get pendingTodos => _todos.where((todo) => !todo.isCompleted).length;
  int get overdueTodos => _todos.where((todo) => todo.isOverdue).length;
  int get todayTodos => _todos.where((todo) => todo.isDueToday).length;

  List<Todo> get highPriorityTodos => _todos
      .where((todo) => todo.priority == Priority.high && !todo.isCompleted)
      .toList();

  List<Todo> get recentTodos =>
      _todos.where((todo) => !todo.isCompleted).take(5).toList();

  // Initialize
  Future<void> initialize() async {
    await loadProjectGroups();
    await loadTodos();
    await _scheduleNotifications();
  }

  // Load todos from database
  Future<void> loadTodos() async {
    try {
      if (_selectedProjectGroup == null) {
        _todos = await _databaseService.getAllTodosWithDetails();
      } else {
        _todos = await _databaseService.getTodosByProjectGroup(_selectedProjectGroup!.id);
      }
      _applyFilters();
      notifyListeners();
    } catch (e) {
      debugPrint('加载任务失败: $e');
      // 回退到基本加载
      try {
        if (_selectedProjectGroup == null) {
          _todos = await _databaseService.getAllTodos();
        } else {
          // For fallback, just get all todos and filter in memory
          final allTodos = await _databaseService.getAllTodos();
          _todos = allTodos.where((todo) => 
            todo.projectGroupId == _selectedProjectGroup!.id ||
            (_selectedProjectGroup!.isDefault && todo.projectGroupId == null)
          ).toList();
        }
        _applyFilters();
        notifyListeners();
      } catch (e2) {
        debugPrint('基本加载也失败: $e2');
      }
    }
  }

  // Add new todo
  Future<Todo?> addTodo(Todo todo) async {
    try {
      final id = await _databaseService.insertTodo(todo);
      final newTodo = todo.copyWith(id: id);
      _todos.insert(0, newTodo);

      // Schedule notification if needed
      if (newTodo.hasValidReminder) {
        try {
          await _notificationService.scheduleNotification(newTodo);
        } catch (e) {
          debugPrint('为新任务安排通知失败: ${newTodo.title}, 错误: $e');
          // 不让通知失败阻止任务创建
        }
      }

      _applyFilters();
      notifyListeners();

      return newTodo;
    } catch (e) {
      debugPrint('添加任务失败: $e');
      return null;
    }
  }

  // Update todo
  Future<bool> updateTodo(Todo todo) async {
    try {
      await _databaseService.updateTodo(todo);
      final index = _todos.indexWhere((t) => t.id == todo.id);
      if (index != -1) {
        _todos[index] = todo;

        // Update notification
        try {
          await _notificationService.cancelNotification(todo.id!);
          if (todo.hasValidReminder) {
            await _notificationService.scheduleNotification(todo);
          }
        } catch (e) {
          debugPrint('更新任务通知失败: ${todo.title}, 错误: $e');
          // 不让通知失败阻止任务更新
        }

        _applyFilters();
        notifyListeners();
      }
      return true;
    } catch (e) {
      debugPrint('更新任务失败: $e');
      return false;
    }
  }

  // Delete todo
  Future<bool> deleteTodo(int id) async {
    try {
      await _databaseService.deleteTodoWithDetails(id);
      await _notificationService.cancelNotification(id);
      _todos.removeWhere((todo) => todo.id == id);
      _applyFilters();
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('删除任务失败: $e');
      return false;
    }
  }

  // Copy todo
  Future<Todo?> copyTodo(Todo originalTodo) async {
    try {
      // 创建任务副本，重置ID和创建时间，标题加上"副本"
      final copyTodo = Todo(
        // id为null，让数据库自动分配新ID
        title: '${originalTodo.title} (副本)',
        description: originalTodo.description,
        isCompleted: false, // 副本默认为未完成状态
        createdAt: DateTime.now(),
        dueDate: originalTodo.dueDate,
        priority: originalTodo.priority,
        category: originalTodo.category,
        colorCode: originalTodo.colorCode,
        tags: List<String>.from(originalTodo.tags),
        hasReminder: false, // 重置提醒设置
        reminderDate: null,
        useMarkdown: originalTodo.useMarkdown,
        subtasks: [], // 稍后添加
        attachments: [], // 稍后添加
      );

      // 保存副本到数据库
      final newId = await _databaseService.insertTodo(copyTodo);
      final newTodo = copyTodo.copyWith(id: newId);

      // 复制子任务
      List<Subtask> copiedSubtasks = [];
      for (final subtask in originalTodo.subtasks) {
        final copiedSubtask = Subtask(
          // id为null，让数据库自动分配新ID
          todoId: newId,
          title: subtask.title,
          isCompleted: false, // 子任务副本也默认为未完成
          createdAt: DateTime.now(),
          order: subtask.order,
        );
        await _databaseService.insertSubtask(copiedSubtask);
        copiedSubtasks.add(copiedSubtask);
      }

      // 复制附件
      List<Attachment> copiedAttachments = [];
      for (final attachment in originalTodo.attachments) {
        final copiedAttachment = Attachment(
          // id为null，让数据库自动分配新ID
          todoId: newId,
          fileName: attachment.fileName,
          filePath: attachment.filePath,
          type: attachment.type,
          createdAt: DateTime.now(),
          fileSize: attachment.fileSize,
          textContent: attachment.textContent,
        );
        await _databaseService.insertAttachment(copiedAttachment);
        copiedAttachments.add(copiedAttachment);
      }

      // 创建包含子任务和附件的完整副本
      final completeTodo = newTodo.copyWith(
        subtasks: copiedSubtasks,
        attachments: copiedAttachments,
      );

      // 添加到本地列表
      _todos.insert(0, completeTodo);
      _applyFilters();
      notifyListeners();

      return completeTodo;
    } catch (e) {
      debugPrint('复制任务失败: $e');
      return null;
    }
  }

  // Toggle todo completion
  Future<void> toggleTodoCompletion(Todo todo) async {
    try {
      final updatedTodo = todo.copyWith(isCompleted: !todo.isCompleted);

      if (updatedTodo.isCompleted) {
        // Cancel notification when completed
        try {
          await _notificationService.cancelNotification(todo.id!);
        } catch (e) {
          debugPrint('取消通知失败: ${todo.title}, 错误: $e');
        }

        // Show completion notification
        try {
          await _notificationService.showNotification(
            id: DateTime.now().millisecondsSinceEpoch,
            title: '任务完成！ 🎉',
            body: '${todo.title} 已完成。',
          );
        } catch (e) {
          debugPrint('显示完成通知失败: $e');
        }
      } else {
        // Reschedule notification if uncompleted
        if (updatedTodo.hasValidReminder) {
          try {
            await _notificationService.scheduleNotification(updatedTodo);
          } catch (e) {
            debugPrint('重新安排通知失败: ${todo.title}, 错误: $e');
          }
        }
      }

      await updateTodo(updatedTodo);
    } catch (e, stackTrace) {
      debugPrint('切换任务完成状态失败: $e');
      debugPrint('切换状态错误堆栈跟踪: $stackTrace');
    }
  }

  // Toggle subtask completion
  Future<void> toggleSubtaskCompletion(int todoId, int subtaskIndex) async {
    try {
      final todoIndex = _todos.indexWhere((todo) => todo.id == todoId);
      if (todoIndex == -1 ||
          subtaskIndex < 0 ||
          subtaskIndex >= _todos[todoIndex].subtasks.length) {
        debugPrint('子任务切换失败: todoIndex=$todoIndex, subtaskIndex=$subtaskIndex');
        return;
      }

      final todo = _todos[todoIndex];
      final subtask = todo.subtasks[subtaskIndex];

      debugPrint(
          '切换子任务: ${subtask.title}, ID: ${subtask.id}, 当前状态: ${subtask.isCompleted}');

      // 更新子任务状态
      final updatedSubtask = subtask.copyWith(
        isCompleted: !subtask.isCompleted,
      );

      // 直接更新子任务到数据库
      if (updatedSubtask.id != null) {
        await _databaseService.updateSubtask(updatedSubtask);

        // 更新本地状态
        final updatedSubtasks = List<Subtask>.from(todo.subtasks);
        updatedSubtasks[subtaskIndex] = updatedSubtask;

        _todos[todoIndex] = todo.copyWith(subtasks: updatedSubtasks);
        _applyFilters();
        notifyListeners();

        debugPrint(
            '子任务状态已更新: ${updatedSubtask.title} -> ${updatedSubtask.isCompleted}');
      } else {
        debugPrint('子任务没有ID，无法更新: ${subtask.title}');
      }
    } catch (e, stackTrace) {
      debugPrint('切换子任务完成状态失败: $e');
      debugPrint('子任务切换错误堆栈跟踪: $stackTrace');
    }
  }

  // 重新排序子任务
  Future<void> reorderSubtasks(int todoId, int oldIndex, int newIndex) async {
    try {
      final todoIndex = _todos.indexWhere((todo) => todo.id == todoId);
      if (todoIndex == -1) return;

      final todo = _todos[todoIndex];
      final updatedSubtasks = List<Subtask>.from(todo.subtasks);

      // 移动子任务到新位置
      final movedSubtask = updatedSubtasks.removeAt(oldIndex);
      updatedSubtasks.insert(newIndex, movedSubtask);

      // 更新所有子任务的order字段
      for (int i = 0; i < updatedSubtasks.length; i++) {
        updatedSubtasks[i] = updatedSubtasks[i].copyWith(order: i);

        // 更新数据库中的order
        if (updatedSubtasks[i].id != null) {
          await _databaseService.updateSubtask(updatedSubtasks[i]);
        }
      }

      // 更新本地状态
      _todos[todoIndex] = todo.copyWith(subtasks: updatedSubtasks);
      _applyFilters();
      notifyListeners();
    } catch (e, stackTrace) {
      debugPrint('重新排序子任务失败: $e');
      debugPrint('子任务排序错误堆栈跟踪: $stackTrace');
    }
  }

  // 编辑子任务
  Future<void> editSubtask(
      int todoId, int subtaskIndex, String newTitle) async {
    try {
      if (newTitle.trim().isEmpty) return;

      final todoIndex = _todos.indexWhere((todo) => todo.id == todoId);
      if (todoIndex == -1 ||
          subtaskIndex < 0 ||
          subtaskIndex >= _todos[todoIndex].subtasks.length) {
        return;
      }

      final todo = _todos[todoIndex];
      final subtask = todo.subtasks[subtaskIndex];

      // 更新子任务标题
      final updatedSubtask = subtask.copyWith(title: newTitle.trim());

      // 直接更新子任务到数据库
      if (updatedSubtask.id != null) {
        await _databaseService.updateSubtask(updatedSubtask);

        // 更新本地状态
        final updatedSubtasks = List<Subtask>.from(todo.subtasks);
        updatedSubtasks[subtaskIndex] = updatedSubtask;

        _todos[todoIndex] = todo.copyWith(subtasks: updatedSubtasks);
        _applyFilters();
        notifyListeners();
      }
    } catch (e, stackTrace) {
      debugPrint('编辑子任务失败: $e');
      debugPrint('子任务编辑错误堆栈跟踪: $stackTrace');
    }
  }

  // 删除子任务
  Future<void> deleteSubtask(int todoId, int subtaskIndex) async {
    try {
      final todoIndex = _todos.indexWhere((todo) => todo.id == todoId);
      if (todoIndex == -1 ||
          subtaskIndex < 0 ||
          subtaskIndex >= _todos[todoIndex].subtasks.length) {
        return;
      }

      final todo = _todos[todoIndex];
      final subtask = todo.subtasks[subtaskIndex];

      // 从数据库删除子任务
      if (subtask.id != null) {
        await _databaseService.deleteSubtask(subtask.id!);

        // 更新本地状态
        final updatedSubtasks = List<Subtask>.from(todo.subtasks);
        updatedSubtasks.removeAt(subtaskIndex);

        // 重新设置剩余子任务的order
        for (int i = 0; i < updatedSubtasks.length; i++) {
          updatedSubtasks[i] = updatedSubtasks[i].copyWith(order: i);
          if (updatedSubtasks[i].id != null) {
            await _databaseService.updateSubtask(updatedSubtasks[i]);
          }
        }

        _todos[todoIndex] = todo.copyWith(subtasks: updatedSubtasks);
        _applyFilters();
        notifyListeners();
      }
    } catch (e, stackTrace) {
      debugPrint('删除子任务失败: $e');
      debugPrint('子任务删除错误堆栈跟踪: $stackTrace');
    }
  }

  // Search todos
  void searchTodos(String query) {
    _searchQuery = query;
    _applyFilters();
    notifyListeners();
  }

  // Filter by category
  void filterByCategory(Category? category) {
    _selectedCategory = category;
    _applyFilters();
    notifyListeners();
  }

  // Filter by priority
  void filterByPriority(Priority? priority) {
    _selectedPriority = priority;
    _applyFilters();
    notifyListeners();
  }

  // Toggle show completed
  void toggleShowCompleted() {
    _showCompleted = !_showCompleted;
    _applyFilters();
    notifyListeners();
  }

  // Sort todos
  void sortTodos(String sortBy) {
    if (_sortBy == sortBy) {
      _sortAscending = !_sortAscending;
    } else {
      _sortBy = sortBy;
      _sortAscending = true;
    }
    _applyFilters();
    notifyListeners();
  }

  // Clear all filters
  void clearFilters() {
    _searchQuery = '';
    _selectedCategory = null;
    _selectedPriority = null;
    _showCompleted = true;
    _applyFilters();
    notifyListeners();
  }

  // Apply filters and sorting
  void _applyFilters() {
    _filteredTodos = List.from(_todos);

    // Apply search filter
    if (_searchQuery.isNotEmpty) {
      _filteredTodos = _filteredTodos.where((todo) {
        return todo.title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
            todo.description.toLowerCase().contains(_searchQuery.toLowerCase());
      }).toList();
    }

    // Apply category filter
    if (_selectedCategory != null) {
      _filteredTodos = _filteredTodos
          .where((todo) => todo.category == _selectedCategory)
          .toList();
    }

    // Apply priority filter
    if (_selectedPriority != null) {
      _filteredTodos = _filteredTodos
          .where((todo) => todo.priority == _selectedPriority)
          .toList();
    }

    // Apply completion filter
    if (!_showCompleted) {
      _filteredTodos =
          _filteredTodos.where((todo) => !todo.isCompleted).toList();
    }

    // Apply sorting
    _filteredTodos.sort((a, b) {
      switch (_sortBy) {
        case 'title':
          return _sortAscending
              ? a.title.compareTo(b.title)
              : b.title.compareTo(a.title);
        case 'dueDate':
          if (a.dueDate == null && b.dueDate == null) return 0;
          if (a.dueDate == null) return 1;
          if (b.dueDate == null) return -1;
          return _sortAscending
              ? a.dueDate!.compareTo(b.dueDate!)
              : b.dueDate!.compareTo(a.dueDate!);
        case 'priority':
          final priorityOrder = {
            Priority.high: 3,
            Priority.medium: 2,
            Priority.low: 1
          };
          final aValue = priorityOrder[a.priority]!;
          final bValue = priorityOrder[b.priority]!;
          return _sortAscending
              ? aValue.compareTo(bValue)
              : bValue.compareTo(aValue);
        case 'createdAt':
        default:
          return _sortAscending
              ? a.createdAt.compareTo(b.createdAt)
              : b.createdAt.compareTo(a.createdAt);
      }
    });
  }

  // Schedule notifications for todos with reminders
  Future<void> _scheduleNotifications() async {
    try {
      final todosWithValidReminders =
          _todos.where((todo) => todo.hasValidReminder).toList();

      debugPrint('找到 ${todosWithValidReminders.length} 个需要安排通知的任务');

      for (final todo in todosWithValidReminders) {
        try {
          await _notificationService.scheduleNotification(todo);
          // 添加小延迟以避免快速连续调用可能导致的问题
          await Future.delayed(const Duration(milliseconds: 100));
          debugPrint('已为任务安排通知: ${todo.title}');
        } catch (e, stackTrace) {
          debugPrint('为任务安排通知失败: ${todo.title}, 错误: $e');
          debugPrint('通知安排错误堆栈跟踪: $stackTrace');
          // 继续处理其他任务，不让单个失败影响所有任务
        }
      }
    } catch (e, stackTrace) {
      debugPrint('批量安排通知失败: $e');
      debugPrint('批量通知错误堆栈跟踪: $stackTrace');
    }
  }

  // Get todos by specific filters
  Future<List<Todo>> getTodosByCategory(Category category) async {
    return await _databaseService.getTodosByCategory(category);
  }

  Future<List<Todo>> getOverdueTodos() async {
    return await _databaseService.getOverdueTodos();
  }

  Future<List<Todo>> getTodayTodos() async {
    return await _databaseService.getTodayTodos();
  }

  Future<List<Todo>> getUpcomingTodos() async {
    return await _databaseService.getUpcomingTodos();
  }

  // Notification-related methods
  Future<void> scheduleDailySummary() async {
    await _notificationService.scheduleDailySummary(
      pendingTodos,
      _todos.where((todo) => todo.isOverdue).length,
    );
  }

  // Project Group methods
  Future<void> loadProjectGroups() async {
    try {
      _projectGroups = await _databaseService.getAllProjectGroups();
      
      // Set default project group if none selected
      if (_selectedProjectGroup == null && _projectGroups.isNotEmpty) {
        _selectedProjectGroup = _projectGroups.firstWhere(
          (group) => group.isDefault,
          orElse: () => _projectGroups.first,
        );
      }
      
      notifyListeners();
    } catch (e) {
      debugPrint('加载项目组失败: $e');
    }
  }

  void selectProjectGroup(ProjectGroup? group) {
    _selectedProjectGroup = group;
    loadTodos(); // Reload todos for the selected project group
    notifyListeners();
  }

  // Get statistics for current project group
  int get currentProjectTotalTodos => _todos.length;
  int get currentProjectCompletedTodos => _todos.where((todo) => todo.isCompleted).length;
  int get currentProjectPendingTodos => _todos.where((todo) => !todo.isCompleted).length;
  int get currentProjectOverdueTodos => _todos.where((todo) => todo.isOverdue).length;
}
