import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' hide Category;
import 'package:provider/provider.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../models/todo.dart' show Todo, Priority, Category;
import '../services/todo_provider.dart';
import '../services/preferences_service.dart';
import '../services/notification_helper.dart';
import '../utils/app_theme.dart';
import '../widgets/todo_card.dart';
import '../widgets/stats_card.dart';
import '../widgets/category_filter_chip.dart';
import '../widgets/priority_filter_chip.dart';
import '../widgets/usage_guide_dialog.dart';
import 'add_edit_todo_screen.dart';
import 'notification_settings_screen.dart';
import 'preferences_test_screen.dart';

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

  void _checkNotificationPermission() async {
    // 这个方法现在被 _handleFirstLaunchSetup 替代
    // 保留作为备用
  }

  void _handleMenuSelection(String value) async {
    switch (value) {
      case 'usage_guide':
        await UsageGuideDialog.show(context);
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
                color: AppTheme.primaryColor.withOpacity(0.1),
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
            Text('版本 1.6.0'),
            SizedBox(height: 12),
            Text(
              '功能特点：',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            SizedBox(height: 4),
            Text('• 智能提醒，后台通知'),
            Text('• 任务分类与优先级管理'),
            Text('• 数据本地存储'),
            Text('• 简洁美观的界面设计'),
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
                          color: Colors.white.withOpacity(0.9),
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
    return SliverToBoxAdapter(
      child: Container(
        constraints: const BoxConstraints(
          maxHeight: 85, // 进一步减少最大高度
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(
              horizontal: 16, vertical: 6), // 进一步减少垂直padding
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
                  const SizedBox(width: 6), // 进一步减少间距
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
                  const SizedBox(width: 6), // 进一步减少间距
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
      },
    );
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
                  Theme.of(context).primaryColor.withOpacity(0.9),
                  Theme.of(context).primaryColor,
                ],
              ),
              boxShadow: [
                BoxShadow(
                  color: Theme.of(context).primaryColor.withOpacity(0.3),
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
                          color: Colors.white.withOpacity(0.2),
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
