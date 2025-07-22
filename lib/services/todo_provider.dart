import 'package:flutter/material.dart';
import '../models/todo.dart';
import '../models/subtask.dart';
import '../services/database_service.dart';
import '../services/notification_service.dart';

class TodoProvider with ChangeNotifier {
  final DatabaseService _databaseService = DatabaseService();
  final NotificationService _notificationService = NotificationService();

  List<Todo> _todos = [];
  List<Todo> _filteredTodos = [];
  String _searchQuery = '';
  Category? _selectedCategory;
  Priority? _selectedPriority;
  bool _showCompleted = true;
  String _sortBy = 'createdAt'; // 'createdAt', 'dueDate', 'priority', 'title'
  bool _sortAscending = false;

  // Getters
  List<Todo> get todos => _filteredTodos;
  List<Todo> get allTodos => _todos;
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
    await loadTodos();
    await _scheduleNotifications();
  }

  // Load todos from database
  Future<void> loadTodos() async {
    try {
      _todos = await _databaseService.getAllTodosWithDetails();
      _applyFilters();
      notifyListeners();
    } catch (e) {
      debugPrint('加载任务失败: $e');
      // 回退到基本加载
      try {
        _todos = await _databaseService.getAllTodos();
        _applyFilters();
        notifyListeners();
      } catch (e2) {
        debugPrint('基本加载也失败: $e2');
      }
    }
  }

  // Add new todo
  Future<bool> addTodo(Todo todo) async {
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

      return true;
    } catch (e) {
      debugPrint('添加任务失败: $e');
      return false;
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
        return;
      }

      final todo = _todos[todoIndex];
      final updatedSubtasks = List<Subtask>.from(todo.subtasks);
      updatedSubtasks[subtaskIndex] = updatedSubtasks[subtaskIndex].copyWith(
        isCompleted: !updatedSubtasks[subtaskIndex].isCompleted,
      );

      final updatedTodo = todo.copyWith(subtasks: updatedSubtasks);
      await updateTodo(updatedTodo);
    } catch (e, stackTrace) {
      debugPrint('切换子任务完成状态失败: $e');
      debugPrint('子任务切换错误堆栈跟踪: $stackTrace');
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
}
