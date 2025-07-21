import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/todo.dart' as todo_models;
import '../models/subtask.dart';
import '../models/attachment.dart';

class DatabaseService {
  static final DatabaseService _instance = DatabaseService._internal();
  factory DatabaseService() => _instance;
  DatabaseService._internal();

  Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<void> init() async {
    try {
      _database = await _initDatabase();
      debugPrint('Database initialized successfully');
    } catch (e) {
      debugPrint('Database initialization failed: $e');
      // Try alternative initialization with in-memory database as fallback
      try {
        debugPrint('Trying in-memory database as fallback');
        _database = await openDatabase(
          ':memory:',
          version: 1,
          onCreate: _onCreate,
        );
        debugPrint('In-memory database initialized successfully');
      } catch (e2) {
        debugPrint('Even in-memory database failed: $e2');
        rethrow;
      }
    }
  }

  Future<Database> _initDatabase() async {
    try {
      String databasesPath;
      try {
        databasesPath = await getDatabasesPath();
      } catch (e) {
        debugPrint('Failed to get databases path, using fallback: $e');
        // Fallback to a simple path
        databasesPath = '/data/data/com.fxl.todo_list_app/databases';
      }
      
      String path = join(databasesPath, 'todos.db');
      debugPrint('Database path: $path');
      
      return await openDatabase(
        path,
        version: 2, // 升级版本号以支持新字段
        onCreate: _onCreate,
        onUpgrade: _onUpgrade,
      );
    } catch (e) {
      debugPrint('Database creation failed: $e');
      rethrow;
    }
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE todos(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        title TEXT NOT NULL,
        description TEXT,
        isCompleted INTEGER NOT NULL DEFAULT 0,
        createdAt INTEGER NOT NULL,
        dueDate INTEGER,
        priority INTEGER NOT NULL DEFAULT 1,
        category INTEGER NOT NULL DEFAULT 0,
        colorCode INTEGER,
        tags TEXT,
        hasReminder INTEGER NOT NULL DEFAULT 0,
        reminderDate INTEGER,
        useMarkdown INTEGER NOT NULL DEFAULT 0
      )
    ''');

    await db.execute('''
      CREATE TABLE subtasks(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        todoId INTEGER NOT NULL,
        title TEXT NOT NULL,
        isCompleted INTEGER NOT NULL DEFAULT 0,
        createdAt INTEGER NOT NULL,
        order_index INTEGER NOT NULL DEFAULT 0,
        FOREIGN KEY (todoId) REFERENCES todos (id) ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE TABLE attachments(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        todoId INTEGER NOT NULL,
        fileName TEXT NOT NULL,
        filePath TEXT NOT NULL,
        type INTEGER NOT NULL,
        createdAt INTEGER NOT NULL,
        fileSize INTEGER,
        textContent TEXT,
        FOREIGN KEY (todoId) REFERENCES todos (id) ON DELETE CASCADE
      )
    ''');
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      // 添加新字段到现有的todos表
      try {
        await db.execute('ALTER TABLE todos ADD COLUMN useMarkdown INTEGER NOT NULL DEFAULT 0');
      } catch (e) {
        debugPrint('Error adding useMarkdown column: $e');
      }

      // 创建新表
      await db.execute('''
        CREATE TABLE IF NOT EXISTS subtasks(
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          todoId INTEGER NOT NULL,
          title TEXT NOT NULL,
          isCompleted INTEGER NOT NULL DEFAULT 0,
          createdAt INTEGER NOT NULL,
          order_index INTEGER NOT NULL DEFAULT 0,
          FOREIGN KEY (todoId) REFERENCES todos (id) ON DELETE CASCADE
        )
      ''');

      await db.execute('''
        CREATE TABLE IF NOT EXISTS attachments(
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          todoId INTEGER NOT NULL,
          fileName TEXT NOT NULL,
          filePath TEXT NOT NULL,
          type INTEGER NOT NULL,
          createdAt INTEGER NOT NULL,
          fileSize INTEGER,
          textContent TEXT,
          FOREIGN KEY (todoId) REFERENCES todos (id) ON DELETE CASCADE
        )
      ''');
    }
  }

  // Insert a new todo
  Future<int> insertTodo(todo_models.Todo todo) async {
    try {
      final db = await database;
      debugPrint('Database instance obtained: $db');
      
      // Validate required fields
      if (todo.title.trim().isEmpty) {
        throw Exception('Todo title cannot be empty');
      }
      
      final todoMap = todo.toMap();
      debugPrint('Todo map: $todoMap');
      
      // Ensure no null values for required fields
      final sanitizedMap = {
        ...todoMap,
        'title': todoMap['title']?.toString().trim() ?? '',
        'description': todoMap['description']?.toString() ?? '',
        'isCompleted': todoMap['isCompleted'] ?? 0,
        'createdAt': todoMap['createdAt'] ?? DateTime.now().millisecondsSinceEpoch,
        'priority': todoMap['priority'] ?? 1,
        'category': todoMap['category'] ?? 0,
        'tags': todoMap['tags']?.toString() ?? '',
        'hasReminder': todoMap['hasReminder'] ?? 0,
      };
      
      debugPrint('Sanitized map: $sanitizedMap');
      
      final result = await db.insert('todos', sanitizedMap);
      debugPrint('Insert successful, ID: $result');
      return result;
    } catch (e) {
      debugPrint('Error in insertTodo: $e');
      debugPrint('Stack trace: ${StackTrace.current}');
      rethrow;
    }
  }

  // Get all todos
  Future<List<todo_models.Todo>> getAllTodos() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('todos');

    return List.generate(maps.length, (i) {
      return todo_models.Todo.fromMap(maps[i]);
    });
  }

  // Get todos by status (completed/pending)
  Future<List<todo_models.Todo>> getTodosByStatus(bool isCompleted) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'todos',
      where: 'isCompleted = ?',
      whereArgs: [isCompleted ? 1 : 0],
    );

    return List.generate(maps.length, (i) {
      return todo_models.Todo.fromMap(maps[i]);
    });
  }

  // Get todos by category
  Future<List<todo_models.Todo>> getTodosByCategory(todo_models.Category category) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'todos',
      where: 'category = ?',
      whereArgs: [category.index],
      orderBy: 'createdAt DESC',
    );

    return List.generate(maps.length, (i) {
      return todo_models.Todo.fromMap(maps[i]);
    });
  }

  // Get todos by priority
  Future<List<todo_models.Todo>> getTodosByPriority(todo_models.Priority priority) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'todos',
      where: 'priority = ?',
      whereArgs: [priority.index],
      orderBy: 'createdAt DESC',
    );

    return List.generate(maps.length, (i) {
      return todo_models.Todo.fromMap(maps[i]);
    });
  }

  // Get overdue todos
  Future<List<todo_models.Todo>> getOverdueTodos() async {
    final db = await database;
    final now = DateTime.now().millisecondsSinceEpoch;
    final List<Map<String, dynamic>> maps = await db.query(
      'todos',
      where: 'dueDate < ? AND isCompleted = 0 AND dueDate IS NOT NULL',
      whereArgs: [now],
      orderBy: 'dueDate ASC',
    );

    return List.generate(maps.length, (i) {
      return todo_models.Todo.fromMap(maps[i]);
    });
  }

  // Get today's todos
  Future<List<todo_models.Todo>> getTodayTodos() async {
    final db = await database;
    final today = DateTime.now();
    final startOfDay = DateTime(today.year, today.month, today.day).millisecondsSinceEpoch;
    final endOfDay = DateTime(today.year, today.month, today.day, 23, 59, 59).millisecondsSinceEpoch;

    final List<Map<String, dynamic>> maps = await db.query(
      'todos',
      where: 'dueDate >= ? AND dueDate <= ? AND dueDate IS NOT NULL',
      whereArgs: [startOfDay, endOfDay],
      orderBy: 'dueDate ASC',
    );

    return List.generate(maps.length, (i) {
      return todo_models.Todo.fromMap(maps[i]);
    });
  }

  // Update a todo
  Future<int> updateTodo(todo_models.Todo todo) async {
    final db = await database;
    return await db.update(
      'todos',
      todo.toMap(),
      where: 'id = ?',
      whereArgs: [todo.id],
    );
  }

  // Delete a todo
  Future<int> deleteTodo(int id) async {
    final db = await database;
    return await db.delete(
      'todos',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // Search todos by title or description
  Future<List<todo_models.Todo>> searchTodos(String query) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'todos',
      where: 'title LIKE ? OR description LIKE ?',
      whereArgs: ['%$query%', '%$query%'],
      orderBy: 'createdAt DESC',
    );

    return List.generate(maps.length, (i) {
      return todo_models.Todo.fromMap(maps[i]);
    });
  }

  // Get statistics
  Future<Map<String, int>> getStatistics() async {
    final db = await database;
    
    final totalResult = await db.rawQuery('SELECT COUNT(*) as count FROM todos');
    final completedResult = await db.rawQuery('SELECT COUNT(*) as count FROM todos WHERE isCompleted = 1');
    final overdueResult = await db.rawQuery(
      'SELECT COUNT(*) as count FROM todos WHERE dueDate < ? AND isCompleted = 0 AND dueDate IS NOT NULL',
      [DateTime.now().millisecondsSinceEpoch]
    );

    return {
      'total': totalResult.first['count'] as int,
      'completed': completedResult.first['count'] as int,
      'overdue': overdueResult.first['count'] as int,
      'pending': (totalResult.first['count'] as int) - (completedResult.first['count'] as int),
    };
  }

  // Get upcoming todos (next 7 days)
  Future<List<todo_models.Todo>> getUpcomingTodos() async {
    final db = await database;
    final now = DateTime.now();
    final weekFromNow = now.add(const Duration(days: 7));
    
    final List<Map<String, dynamic>> maps = await db.query(
      'todos',
      where: 'dueDate >= ? AND dueDate <= ? AND isCompleted = 0',
      whereArgs: [now.millisecondsSinceEpoch, weekFromNow.millisecondsSinceEpoch],
      orderBy: 'dueDate ASC',
    );

    return List.generate(maps.length, (i) => todo_models.Todo.fromMap(maps[i]));
  }

  // ============= SUBTASK METHODS =============
  
  // Insert a new subtask
  Future<int> insertSubtask(Subtask subtask) async {
    final db = await database;
    return await db.insert('subtasks', {
      ...subtask.toMap(),
      'order_index': subtask.order, // 映射到正确的列名
    }..remove('order'));
  }

  // Get subtasks for a todo
  Future<List<Subtask>> getSubtasks(int todoId) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'subtasks',
      where: 'todoId = ?',
      whereArgs: [todoId],
      orderBy: 'order_index ASC',
    );

    return List.generate(maps.length, (i) {
      return Subtask.fromMap({
        ...maps[i],
        'order': maps[i]['order_index'], // 映射回模型的字段名
      });
    });
  }

  // Update a subtask
  Future<int> updateSubtask(Subtask subtask) async {
    final db = await database;
    return await db.update(
      'subtasks',
      {
        ...subtask.toMap(),
        'order_index': subtask.order,
      }..remove('order'),
      where: 'id = ?',
      whereArgs: [subtask.id],
    );
  }

  // Delete a subtask
  Future<int> deleteSubtask(int id) async {
    final db = await database;
    return await db.delete(
      'subtasks',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // Delete all subtasks for a todo
  Future<int> deleteSubtasksForTodo(int todoId) async {
    final db = await database;
    return await db.delete(
      'subtasks',
      where: 'todoId = ?',
      whereArgs: [todoId],
    );
  }

  // ============= ATTACHMENT METHODS =============
  
  // Insert a new attachment
  Future<int> insertAttachment(Attachment attachment) async {
    final db = await database;
    return await db.insert('attachments', attachment.toMap());
  }

  // Get attachments for a todo
  Future<List<Attachment>> getAttachments(int todoId) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'attachments',
      where: 'todoId = ?',
      whereArgs: [todoId],
      orderBy: 'createdAt DESC',
    );

    return List.generate(maps.length, (i) {
      return Attachment.fromMap(maps[i]);
    });
  }

  // Update an attachment
  Future<int> updateAttachment(Attachment attachment) async {
    final db = await database;
    return await db.update(
      'attachments',
      attachment.toMap(),
      where: 'id = ?',
      whereArgs: [attachment.id],
    );
  }

  // Delete an attachment
  Future<int> deleteAttachment(int id) async {
    final db = await database;
    return await db.delete(
      'attachments',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // Delete all attachments for a todo
  Future<int> deleteAttachmentsForTodo(int todoId) async {
    final db = await database;
    return await db.delete(
      'attachments',
      where: 'todoId = ?',
      whereArgs: [todoId],
    );
  }

  // ============= ENHANCED TODO METHODS =============
  
  // Get a todo with its subtasks and attachments
  Future<todo_models.Todo?> getTodoWithDetails(int id) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'todos',
      where: 'id = ?',
      whereArgs: [id],
    );

    if (maps.isEmpty) return null;

    final todo = todo_models.Todo.fromMap(maps.first);
    final subtasks = await getSubtasks(id);
    final attachments = await getAttachments(id);

    return todo.copyWith(
      subtasks: subtasks,
      attachments: attachments,
    );
  }

  // Get all todos with their subtasks and attachments
  Future<List<todo_models.Todo>> getAllTodosWithDetails() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('todos', orderBy: 'createdAt DESC');

    List<todo_models.Todo> todos = [];
    
    for (var map in maps) {
      final todo = todo_models.Todo.fromMap(map);
      final subtasks = await getSubtasks(todo.id!);
      final attachments = await getAttachments(todo.id!);
      
      todos.add(todo.copyWith(
        subtasks: subtasks,
        attachments: attachments,
      ));
    }

    return todos;
  }

  // Delete todo with all related data
  Future<int> deleteTodoWithDetails(int id) async {
    final db = await database;
    
    // Delete related data first
    await deleteSubtasksForTodo(id);
    await deleteAttachmentsForTodo(id);
    
    // Then delete the todo
    return await db.delete(
      'todos',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // Close database
  Future<void> close() async {
    final db = await database;
    await db.close();
  }
}
