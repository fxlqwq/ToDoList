import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' hide Category;
import 'package:provider/provider.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:intl/intl.dart';
import '../models/todo.dart' show Todo, Priority, Category;
import '../models/view_mode.dart';
import '../services/todo_provider.dart';
import '../services/preferences_service.dart';
import '../services/notification_helper.dart';
import '../utils/app_theme.dart';
import '../widgets/todo_card.dart';
import '../widgets/todo_card_view.dart';
import '../widgets/todo_compact_view.dart';
import '../widgets/todo_grid_view.dart';
import '../widgets/stats_card.dart';
import '../widgets/category_filter_chip.dart';
import '../widgets/priority_filter_chip.dart';
import '../widgets/usage_guide_dialog.dart';
import 'add_edit_todo_screen.dart';
import 'notification_settings_screen.dart';
import 'preferences_test_screen.dart';
import 'statistics_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  final TextEditingController _searchController = TextEditingController();
  late AnimationController _fabAnimationController;
  late Animation<double> _fabAnimation;
  bool _showFilters = false;
  TodoViewMode _currentViewMode = TodoViewMode.list;

  @override
  void initState() {
    super.initState();
    _fabAnimationController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _fabAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _fabAnimationController, curve: Curves.easeInOut),
    );
    _fabAnimationController.forward();

    // Load todos when screen initializes
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<TodoProvider>().loadTodos();
      _handleFirstLaunchSetup();
      _loadViewMode(); // 加载保存的视图模式
    });
  }

  void _handleFirstLaunchSetup() async {
    try {
      final preferencesService = PreferencesService();

      // 检查是否是首次启动
      final isFirstLaunch = await preferencesService.isFirstLaunch();

      if (isFirstLaunch && mounted) {
        // 显示使用说明
        await Future.delayed(const Duration(milliseconds: 1500));
        if (mounted) {
          final guideResult = await UsageGuideDialog.show(context);
          if (guideResult == true) {
            await preferencesService.setUsageGuideShown(true);
          }
        }

        // 设置首次启动完成
        await preferencesService.setFirstLaunch(false);
      }

      // 检查通知权限是否已请求过
      final permissionAsked =
          await preferencesService.isNotificationPermissionAsked();

      if (!permissionAsked && mounted) {
        await Future.delayed(const Duration(milliseconds: 1000));
        if (mounted) {
          // 使用新的权限请求系统
          final notificationHelper = NotificationHelper();
          final results =
              await notificationHelper.requestAllPermissions(context);

          await preferencesService.setNotificationPermissionAsked(true);

          // 检查所有权限的结果
          final notificationGranted = results['notification'] ?? false;
          final batteryOptGranted = results['batteryOptimization'] ?? false;
          final alarmGranted = results['scheduleExactAlarm'] ?? false;

          if (notificationGranted) {
            await preferencesService.setNotificationEnabled(true);

            String message = '通知权限已启用！';
            if (batteryOptGranted) {
              message += ' 后台运行已优化，通知将更可靠。';
            }
            if (alarmGranted) {
              message += ' 精确提醒已启用。';
            }

            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(message),
                  backgroundColor: const Color(0xFF10B981),
                  duration: const Duration(seconds: 4),
                ),
              );
            }
          } else {
            await preferencesService.setNotificationEnabled(false);
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('未启用通知权限，您将无法收到任务提醒。'),
                  backgroundColor: Colors.orange,
                ),
              );
            }
          }
        }
      }

      // 更新最后使用日期
      await preferencesService.updateLastUsedDate();
    } catch (e) {
      debugPrint('首次启动设置失败: $e');
    }
  }

  /// 加载保存的视图模式
  void _loadViewMode() async {
    try {
      final preferencesService = PreferencesService();
      final savedViewMode = await preferencesService.getViewMode();

      if (savedViewMode != null && mounted) {
        final viewMode = TodoViewMode.values.firstWhere(
          (mode) => mode.name == savedViewMode,
          orElse: () => TodoViewMode.list,
        );
        setState(() {
          _currentViewMode = viewMode;
        });
      }
    } catch (e) {
      debugPrint('加载视图模式失败: $e');
    }
  }

  /// 保存视图模式
  void _saveViewMode(TodoViewMode mode) async {
    try {
      final preferencesService = PreferencesService();
      await preferencesService.setViewMode(mode.name);
    } catch (e) {
      debugPrint('保存视图模式失败: $e');
    }
  }

  void _randomSelectTask() {
    final todoProvider = Provider.of<TodoProvider>(context, listen: false);
    final incompleteTodos = todoProvider.allTodos
        .where((todo) => !todo.isCompleted)
        .toList();

    if (incompleteTodos.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('没有未完成的任务可供选择'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    // 随机选择一个未完成的任务
    final random = DateTime.now().millisecondsSinceEpoch;
    final selectedTask = incompleteTodos[random % incompleteTodos.length];

    // 显示选中的任务
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: const Row(
          children: [
            Icon(
              FontAwesomeIcons.dice,
              color: AppTheme.primaryColor,
              size: 20,
            ),
            SizedBox(width: 8),
            Text('随机选择的任务'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.primaryColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppTheme.primaryColor.withValues(alpha: 0.3),
                  width: 1,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    selectedTask.title,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (selectedTask.description.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text(
                      selectedTask.description,
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 14,
                      ),
                    ),
                  ],
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      _buildPriorityChip(selectedTask.priority),
                      const SizedBox(width: 8),
                      _buildCategoryChip(selectedTask.category),
                    ],
                  ),
                  if (selectedTask.dueDate != null) ...[
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(
                          FontAwesomeIcons.clock,
                          size: 14,
                          color: selectedTask.isOverdue ? Colors.red : Colors.grey[600],
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '截止: ${DateFormat('MM/dd HH:mm').format(selectedTask.dueDate!)}',
                          style: TextStyle(
                            fontSize: 12,
                            color: selectedTask.isOverdue ? Colors.red : Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('关闭'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              // 可以选择跳转到编辑任务页面
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => AddEditTodoScreen(todo: selectedTask),
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryColor,
              foregroundColor: Colors.white,
            ),
            child: const Text('查看详情'),
          ),
        ],
      ),
    );
  }

  Widget _buildPriorityChip(Priority priority) {
    Color color;
    String text;
    switch (priority) {
      case Priority.high:
        color = Colors.red;
        text = '高';
        break;
      case Priority.medium:
        color = Colors.orange;
        text = '中';
        break;
      case Priority.low:
        color = Colors.green;
        text = '低';
        break;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildCategoryChip(Category category) {
    String text;
    switch (category) {
      case Category.personal:
        text = '个人';
        break;
      case Category.work:
        text = '工作';
        break;
      case Category.health:
        text = '健康';
        break;
      case Category.shopping:
        text = '购物';
        break;
      case Category.education:
        text = '学习';
        break;
      case Category.other:
        text = '其他';
        break;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppTheme.secondaryColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.secondaryColor.withValues(alpha: 0.3)),
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: AppTheme.secondaryColor,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  void _handleMenuSelection(String value) async {
    switch (value) {
      case 'usage_guide':
        await UsageGuideDialog.show(context);
        break;
      case 'statistics':
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const StatisticsScreen(),
          ),
        );
        break;
      case 'about':
        _showAboutDialog();
        break;
      case 'debug_preferences':
        if (kDebugMode && mounted) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const PreferencesTestScreen(),
            ),
          );
        }
        break;
      case 'reset_splash':
        if (kDebugMode) {
          await _resetSplashScreen();
        }
        break;
    }
  }

  Future<void> _resetSplashScreen() async {
    final preferencesService = PreferencesService();
    await preferencesService.setFirstLaunch(true);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('首次启动状态已重置，重启应用将再次显示启动画面'),
          backgroundColor: AppTheme.secondaryColor,
        ),
      );
    }
  }

  void _showAboutDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppTheme.primaryColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                FontAwesomeIcons.listCheck,
                color: AppTheme.primaryColor,
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            const Text('关于应用'),
          ],
        ),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'TodoList - 智能待办事项管理',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 8),
            Text('版本 1.8.4'),
            SizedBox(height: 12),
            Text(
              '1.8.4版本说明：',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            SizedBox(height: 4),
            Text('• 统计页面优化：修复统计卡片高度过窄问题'),
            Text('• 显示体验改进：统计数据文字完整显示'),
            Text('• 随机任务功能：新增主界面随机选择任务功能'),
            Text('• 代码质量提升：修复所有lint警告，提升性能'),
            Text('• 工具完善：添加代码行数统计脚本'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('确定'),
          ),
        ],
      ),
    );
  }

  void _showViewModeDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('选择视图模式'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: TodoViewMode.values.map((mode) {
            return RadioListTile<TodoViewMode>(
              title: Text(_getViewModeName(mode)),
              subtitle: Text(_getViewModeDescription(mode)),
              value: mode,
              groupValue: _currentViewMode,
              onChanged: (value) {
                if (value != null) {
                  setState(() {
                    _currentViewMode = value;
                  });
                  _saveViewMode(value); // 保存选择的视图模式
                  Navigator.pop(context);
                }
              },
            );
          }).toList(),
        ),
      ),
    );
  }

  IconData _getViewModeIcon() {
    switch (_currentViewMode) {
      case TodoViewMode.list:
        return FontAwesomeIcons.list;
      case TodoViewMode.card:
        return FontAwesomeIcons.idCard;
      case TodoViewMode.grid:
        return FontAwesomeIcons.tableCells;
      case TodoViewMode.compact:
        return FontAwesomeIcons.bars;
    }
  }

  String _getViewModeName(TodoViewMode mode) {
    switch (mode) {
      case TodoViewMode.list:
        return '列表视图';
      case TodoViewMode.card:
        return '卡片视图';
      case TodoViewMode.grid:
        return '网格视图';
      case TodoViewMode.compact:
        return '紧凑视图';
    }
  }

  String _getViewModeDescription(TodoViewMode mode) {
    switch (mode) {
      case TodoViewMode.list:
        return '经典列表，功能完整';
      case TodoViewMode.card:
        return '卡片式，信息丰富';
      case TodoViewMode.grid:
        return '网格布局，紧凑展示';
      case TodoViewMode.compact:
        return '最简模式，节省空间';
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _fabAnimationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          _buildAppBar(),
          _buildStatsSection(),
          _buildFiltersSection(),
          _buildTodoList(),
        ],
      ),
      floatingActionButton: _buildFloatingActionButton(),
    );
  }

  Widget _buildAppBar() {
    return SliverAppBar(
      expandedHeight: 120,
      floating: true,
      pinned: true,
      backgroundColor: Colors.transparent,
      elevation: 0,
      actions: [
        // 随机选择任务按钮
        IconButton(
          onPressed: _randomSelectTask,
          icon: const Icon(
            FontAwesomeIcons.dice,
            color: Colors.white,
            size: 20,
          ),
          tooltip: '随机选择任务',
        ),
        // 视图切换按钮
        IconButton(
          onPressed: _showViewModeDialog,
          icon: Icon(
            _getViewModeIcon(),
            color: Colors.white,
            size: 20,
          ),
        ),
        IconButton(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const NotificationSettingsScreen(),
              ),
            );
          },
          icon: const Icon(
            FontAwesomeIcons.bell,
            color: Colors.white,
            size: 20,
          ),
        ),
        PopupMenuButton<String>(
          icon: const Icon(
            FontAwesomeIcons.ellipsisVertical,
            color: Colors.white,
            size: 20,
          ),
          onSelected: _handleMenuSelection,
          itemBuilder: (BuildContext context) => [
            const PopupMenuItem<String>(
              value: 'statistics',
              child: Row(
                children: [
                  Icon(FontAwesomeIcons.chartPie, size: 16),
                  SizedBox(width: 8),
                  Text('统计数据'),
                ],
              ),
            ),
            const PopupMenuItem<String>(
              value: 'usage_guide',
              child: Row(
                children: [
                  Icon(FontAwesomeIcons.lightbulb, size: 16),
                  SizedBox(width: 8),
                  Text('使用指南'),
                ],
              ),
            ),
            const PopupMenuItem<String>(
              value: 'about',
              child: Row(
                children: [
                  Icon(FontAwesomeIcons.info, size: 16),
                  SizedBox(width: 8),
                  Text('关于应用'),
                ],
              ),
            ),
            // Debug menu item - only in debug mode
            if (kDebugMode)
              const PopupMenuItem<String>(
                value: 'debug_preferences',
                child: Row(
                  children: [
                    Icon(Icons.settings, size: 16),
                    SizedBox(width: 8),
                    Text('偏好设置调试'),
                  ],
                ),
              ),
            if (kDebugMode)
              const PopupMenuItem<String>(
                value: 'reset_splash',
                child: Row(
                  children: [
                    Icon(Icons.refresh, size: 16),
                    SizedBox(width: 8),
                    Text('重置启动画面'),
                  ],
                ),
              ),
          ],
        ),
      ],
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFF6366F1),
                Color(0xFF8B5CF6),
              ],
            ),
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '我的任务',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Consumer<TodoProvider>(
                    builder: (context, todoProvider, child) {
                      return Text(
                        '${todoProvider.pendingTodos} 个待办，${todoProvider.completedTodos} 个已完成',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.9),
                          fontSize: 14,
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(60), // 减少高度
        child: Container(
          color: Colors.white,
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 12), // 优化padding
              child: _buildSearchBar(),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Row(
      children: [
        Expanded(
          child: SizedBox(
            height: 40, // 固定高度
            child: TextField(
              controller: _searchController,
              onChanged: (value) {
                context.read<TodoProvider>().searchTodos(value);
              },
              decoration: InputDecoration(
                hintText: '搜索任务...',
                prefixIcon: const Icon(Icons.search, size: 20),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, size: 20),
                        onPressed: () {
                          _searchController.clear();
                          context.read<TodoProvider>().searchTodos('');
                        },
                      )
                    : null,
                filled: true,
                fillColor: Colors.grey.shade100,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(
                  vertical: 8,
                  horizontal: 12,
                ),
                isDense: true,
              ),
              style: const TextStyle(fontSize: 14),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: Colors.grey.shade100,
            borderRadius: BorderRadius.circular(12),
          ),
          child: IconButton(
            iconSize: 20,
            icon: Icon(
              _showFilters ? Icons.filter_list : Icons.filter_list_outlined,
              color:
                  _showFilters ? const Color(0xFF6366F1) : Colors.grey.shade600,
            ),
            onPressed: () {
              setState(() {
                _showFilters = !_showFilters;
              });
            },
          ),
        ),
      ],
    );
  }

  Widget _buildStatsSection() {
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 400;

    return SliverToBoxAdapter(
      child: Container(
        constraints: BoxConstraints(
          maxHeight: isSmallScreen ? 65 : 75, // 进一步减少高度
        ),
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: isSmallScreen ? 12 : 16,
            vertical: isSmallScreen ? 4 : 6,
          ),
          child: Consumer<TodoProvider>(
            builder: (context, todoProvider, child) {
              return Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(
                    child: StatsCard(
                      title: '总数',
                      value: todoProvider.totalTodos.toString(),
                      icon: FontAwesomeIcons.listCheck,
                      gradient: const LinearGradient(
                        colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
                      ),
                    ),
                  ),
                  SizedBox(width: isSmallScreen ? 4 : 6),
                  Expanded(
                    child: StatsCard(
                      title: '待办',
                      value: todoProvider.pendingTodos.toString(),
                      icon: FontAwesomeIcons.clock,
                      gradient: const LinearGradient(
                        colors: [Color(0xFFF59E0B), Color(0xFFD97706)],
                      ),
                    ),
                  ),
                  SizedBox(width: isSmallScreen ? 4 : 6),
                  Expanded(
                    child: StatsCard(
                      title: '已完成',
                      value: todoProvider.completedTodos.toString(),
                      icon: FontAwesomeIcons.circleCheck,
                      gradient: const LinearGradient(
                        colors: [Color(0xFF10B981), Color(0xFF059669)],
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildFiltersSection() {
    if (!_showFilters) {
      return const SliverToBoxAdapter(child: SizedBox.shrink());
    }

    return SliverToBoxAdapter(
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                '分类',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: Category.values.map((category) {
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: CategoryFilterChip(category: category),
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                '优先级',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: Priority.values.map((priority) {
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: PriorityFilterChip(priority: priority),
                  );
                }).toList(),
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Consumer<TodoProvider>(
                    builder: (context, todoProvider, child) {
                      return Row(
                        children: [
                          Checkbox(
                            value: todoProvider.showCompleted,
                            onChanged: (value) {
                              todoProvider.toggleShowCompleted();
                            },
                          ),
                          const Text('显示已完成'),
                        ],
                      );
                    },
                  ),
                  TextButton(
                    onPressed: () {
                      context.read<TodoProvider>().clearFilters();
                      _searchController.clear();
                    },
                    child: const Text('清除筛选'),
                  ),
                ],
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTodoList() {
    return Consumer<TodoProvider>(
      builder: (context, todoProvider, child) {
        if (todoProvider.todos.isEmpty) {
          return SliverFillRemaining(
            child: _buildEmptyState(),
          );
        }

        // 根据视图模式选择不同的布局
        switch (_currentViewMode) {
          case TodoViewMode.grid:
            return _buildGridView(todoProvider);
          case TodoViewMode.card:
            return _buildCardView(todoProvider);
          case TodoViewMode.compact:
            return _buildCompactView(todoProvider);
          case TodoViewMode.list:
            return _buildListView(todoProvider);
        }
      },
    );
  }

  Widget _buildListView(TodoProvider todoProvider) {
    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate(
          (context, index) {
            return AnimationConfiguration.staggeredList(
              position: index,
              duration: const Duration(milliseconds: 375),
              child: SlideAnimation(
                verticalOffset: 50.0,
                child: FadeInAnimation(
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: TodoCard(
                      todo: todoProvider.todos[index],
                      onToggle: () {
                        todoProvider.toggleTodoCompletion(
                          todoProvider.todos[index],
                        );
                      },
                      onEdit: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => AddEditTodoScreen(
                              todo: todoProvider.todos[index],
                            ),
                          ),
                        );
                      },
                      onSubtaskToggle: (subtaskIndex) {
                        todoProvider.toggleSubtaskCompletion(
                          todoProvider.todos[index].id!,
                          subtaskIndex,
                        );
                      },
                      onSubtaskReorder: (oldIndex, newIndex) {
                        todoProvider.reorderSubtasks(
                          todoProvider.todos[index].id!,
                          oldIndex,
                          newIndex,
                        );
                      },
                      onSubtaskEdit: (subtaskIndex, newTitle) {
                        todoProvider.editSubtask(
                          todoProvider.todos[index].id!,
                          subtaskIndex,
                          newTitle,
                        );
                      },
                      onSubtaskDelete: (subtaskIndex) {
                        todoProvider.deleteSubtask(
                          todoProvider.todos[index].id!,
                          subtaskIndex,
                        );
                      },
                      onDelete: () async {
                        final confirmed = await _showDeleteConfirmation(
                            todoProvider.todos[index]);
                        if (confirmed == true && context.mounted) {
                          final success = await todoProvider
                              .deleteTodo(todoProvider.todos[index].id!);
                          if (success && context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('任务已删除'),
                                backgroundColor: Colors.green,
                              ),
                            );
                          } else if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('删除失败，请重试'),
                                backgroundColor: Colors.red,
                              ),
                            );
                          }
                        }
                      },
                      onCopy: () async {
                        final copiedTodo = await todoProvider
                            .copyTodo(todoProvider.todos[index]);
                        if (copiedTodo != null && context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('任务已复制: ${copiedTodo.title}'),
                              backgroundColor: Colors.blue,
                              duration: const Duration(seconds: 2),
                            ),
                          );
                        } else if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('复制失败，请重试'),
                              backgroundColor: Colors.red,
                            ),
                          );
                        }
                      },
                    ),
                  ),
                ),
              ),
            );
          },
          childCount: todoProvider.todos.length,
        ),
      ),
    );
  }

  Widget _buildCardView(TodoProvider todoProvider) {
    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate(
          (context, index) {
            return AnimationConfiguration.staggeredList(
              position: index,
              duration: const Duration(milliseconds: 375),
              child: SlideAnimation(
                verticalOffset: 50.0,
                child: FadeInAnimation(
                  child: TodoCardView(
                    todo: todoProvider.todos[index],
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => AddEditTodoScreen(
                            todo: todoProvider.todos[index],
                          ),
                        ),
                      );
                    },
                    onLongPress: () async {
                      final confirmed = await _showDeleteConfirmation(
                          todoProvider.todos[index]);
                      if (confirmed == true && context.mounted) {
                        final success = await todoProvider
                            .deleteTodo(todoProvider.todos[index].id!);
                        if (success && context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('任务已删除'),
                              backgroundColor: Colors.green,
                            ),
                          );
                        }
                      }
                    },
                    onSubtaskToggle: (subtaskIndex) {
                      todoProvider.toggleSubtaskCompletion(
                        todoProvider.todos[index].id!,
                        subtaskIndex,
                      );
                    },
                    onMainTaskToggle: () {
                      todoProvider.toggleTodoCompletion(
                        todoProvider.todos[index],
                      );
                    },
                  ),
                ),
              ),
            );
          },
          childCount: todoProvider.todos.length,
        ),
      ),
    );
  }

  Widget _buildCompactView(TodoProvider todoProvider) {
    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate(
          (context, index) {
            return AnimationConfiguration.staggeredList(
              position: index,
              duration: const Duration(milliseconds: 200),
              child: SlideAnimation(
                verticalOffset: 30.0,
                child: FadeInAnimation(
                  child: TodoCompactView(
                    todo: todoProvider.todos[index],
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => AddEditTodoScreen(
                            todo: todoProvider.todos[index],
                          ),
                        ),
                      );
                    },
                    onLongPress: () async {
                      final confirmed = await _showDeleteConfirmation(
                          todoProvider.todos[index]);
                      if (confirmed == true && context.mounted) {
                        final success = await todoProvider
                            .deleteTodo(todoProvider.todos[index].id!);
                        if (success && context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('任务已删除'),
                              backgroundColor: Colors.green,
                            ),
                          );
                        }
                      }
                    },
                    onSubtaskToggle: (subtaskIndex) {
                      todoProvider.toggleSubtaskCompletion(
                        todoProvider.todos[index].id!,
                        subtaskIndex,
                      );
                    },
                    onMainTaskToggle: () {
                      todoProvider.toggleTodoCompletion(
                        todoProvider.todos[index],
                      );
                    },
                  ),
                ),
              ),
            );
          },
          childCount: todoProvider.todos.length,
        ),
      ),
    );
  }

  Widget _buildGridView(TodoProvider todoProvider) {
    final screenWidth = MediaQuery.of(context).size.width;
    final padding = screenWidth < 400 ? 12.0 : 16.0;
    final spacing = screenWidth < 400 ? 8.0 : 12.0;

    // 动态计算列数，考虑平板和大屏设备
    int crossAxisCount;
    if (screenWidth < 600) {
      crossAxisCount = screenWidth < 360 ? 1 : 2; // 手机模式
    } else {
      crossAxisCount = (screenWidth / 300).floor().clamp(2, 4); // 平板模式，最多4列
    }

    return SliverPadding(
      padding: EdgeInsets.symmetric(horizontal: padding),
      sliver: SliverGrid(
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: crossAxisCount,
          crossAxisSpacing: spacing,
          mainAxisSpacing: spacing,
          childAspectRatio:
              _calculateAspectRatio(screenWidth, todoProvider.todos),
        ),
        delegate: SliverChildBuilderDelegate(
          (context, index) {
            return AnimationConfiguration.staggeredGrid(
              position: index,
              duration: const Duration(milliseconds: 375),
              columnCount: crossAxisCount,
              child: ScaleAnimation(
                child: FadeInAnimation(
                  child: TodoGridView(
                    todo: todoProvider.todos[index],
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => AddEditTodoScreen(
                            todo: todoProvider.todos[index],
                          ),
                        ),
                      );
                    },
                    onLongPress: () async {
                      final confirmed = await _showDeleteConfirmation(
                          todoProvider.todos[index]);
                      if (confirmed == true && context.mounted) {
                        final success = await todoProvider
                            .deleteTodo(todoProvider.todos[index].id!);
                        if (success && context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('任务已删除'),
                              backgroundColor: Colors.green,
                            ),
                          );
                        }
                      }
                    },
                    onSubtaskToggle: (subtaskIndex) {
                      todoProvider.toggleSubtaskCompletion(
                        todoProvider.todos[index].id!,
                        subtaskIndex,
                      );
                    },
                    onMainTaskToggle: () {
                      todoProvider.toggleTodoCompletion(
                        todoProvider.todos[index],
                      );
                    },
                  ),
                ),
              ),
            );
          },
          childCount: todoProvider.todos.length,
        ),
      ),
    );
  }

  // 根据屏幕尺寸和任务内容动态计算高宽比
  double _calculateAspectRatio(double screenWidth, List<Todo> todos) {
    // 基础高宽比 - 降低比例以增加卡片高度
    double baseRatio;

    if (screenWidth < 400) {
      baseRatio = 1.2; // 小屏设备增加高度
    } else if (screenWidth < 600) {
      baseRatio = 1.3; // 手机竖屏模式
    } else if (screenWidth < 800) {
      baseRatio = 1.4; // 大手机或小平板
    } else {
      baseRatio = 1.4; // 平板设备
    }

    // 计算平均子任务数量来调整高宽比
    if (todos.isNotEmpty) {
      final avgSubtasks =
          todos.fold<double>(0, (sum, todo) => sum + todo.subtasks.length) /
              todos.length;

      // 根据子任务数量动态调整 - 精细化调整
      if (avgSubtasks > 4) {
        baseRatio *= 0.7; // 子任务很多时，显著增加高度
      } else if (avgSubtasks > 2) {
        baseRatio *= 0.8; // 子任务较多时，适当增高
      } else if (avgSubtasks > 0) {
        baseRatio *= 0.9; // 有子任务时，轻微增高
      } else {
        baseRatio *= 1.0; // 无子任务时，保持基础高度
      }

      // 检查是否有任务包含描述，有描述的任务需要更多高度
      final hasDescriptions = todos.any((todo) => todo.description.isNotEmpty);
      if (hasDescriptions) {
        baseRatio *= 0.85; // 有描述时增加更多高度
      }
    }

    return baseRatio.clamp(0.7, 1.5); // 调整范围，允许更高的卡片
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            FontAwesomeIcons.listCheck,
            size: 80,
            color: Colors.grey.shade300,
          ),
          const SizedBox(height: 16),
          Text(
            '暂无任务',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '点击 + 按钮添加您的第一个任务',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey.shade500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFloatingActionButton() {
    return AnimatedBuilder(
      animation: _fabAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _fabAnimation.value,
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(28),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Theme.of(context).primaryColor.withValues(alpha: 0.9),
                  Theme.of(context).primaryColor,
                ],
              ),
              boxShadow: [
                BoxShadow(
                  color: Theme.of(context).primaryColor.withValues(alpha: 0.3),
                  blurRadius: 12,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(28),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const AddEditTodoScreen(),
                    ),
                  );
                },
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(2),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(
                          Icons.add_rounded,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        '添加任务',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Future<bool?> _showDeleteConfirmation(Todo todo) async {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('确认删除'),
        content: Text('确定要删除"${todo.title}"吗？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('删除', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}
