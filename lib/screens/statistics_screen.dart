import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../services/todo_provider.dart';
import '../models/todo.dart';
import '../utils/app_theme.dart';
import 'project_statistics_with_subtasks_screen.dart';

class StatisticsScreen extends StatelessWidget {
  const StatisticsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 400;

    return Scaffold(
      appBar: AppBar(
        title: const Text('任务统计'),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Consumer<TodoProvider>(
        builder: (context, todoProvider, child) {
          return SingleChildScrollView(
            padding: EdgeInsets.all(isSmallScreen ? 12 : 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 总体统计标题
                Row(
                  children: [
                    Icon(
                      FontAwesomeIcons.chartPie,
                      color: AppTheme.primaryColor,
                      size: isSmallScreen ? 20 : 24,
                    ),
                    SizedBox(width: 8),
                    Text(
                      '总体统计',
                      style: TextStyle(
                        fontSize: isSmallScreen ? 18 : 20,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.primaryColor,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: isSmallScreen ? 12 : 16),
                _buildOverviewCards(todoProvider, isSmallScreen),
                SizedBox(height: isSmallScreen ? 16 : 24),
                _buildCompletionChart(todoProvider, isSmallScreen),
                SizedBox(height: isSmallScreen ? 16 : 24),
                _buildCategoryStats(todoProvider, isSmallScreen),
                SizedBox(height: isSmallScreen ? 16 : 24),
                _buildPriorityStats(todoProvider, isSmallScreen),
                SizedBox(height: isSmallScreen ? 16 : 24),
                _buildTimeStats(todoProvider, isSmallScreen),
                SizedBox(height: isSmallScreen ? 24 : 32),
                
                // 项目组统计选择器
                _buildProjectGroupSelector(context, todoProvider, isSmallScreen),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildProjectGroupSelector(BuildContext context, TodoProvider todoProvider, bool isSmallScreen) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              FontAwesomeIcons.folderOpen,
              color: AppTheme.secondaryColor,
              size: isSmallScreen ? 20 : 24,
            ),
            SizedBox(width: 8),
            Text(
              '项目组统计',
              style: TextStyle(
                fontSize: isSmallScreen ? 18 : 20,
                fontWeight: FontWeight.bold,
                color: AppTheme.secondaryColor,
              ),
            ),
          ],
        ),
        SizedBox(height: isSmallScreen ? 12 : 16),
        Text(
          '选择一个项目组查看详细统计数据',
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey[600],
          ),
        ),
        SizedBox(height: 12),
        if (todoProvider.projectGroups.isEmpty)
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey[300]!),
            ),
            child: Center(
              child: Column(
                children: [
                  Icon(
                    FontAwesomeIcons.folderPlus,
                    color: Colors.grey[400],
                    size: 32,
                  ),
                  SizedBox(height: 8),
                  Text(
                    '暂无项目组',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    '请先创建项目组来查看分组统计',
                    style: TextStyle(
                      color: Colors.grey[500],
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
          )
        else
          ...todoProvider.projectGroups.map((group) {
            final groupTodos = todoProvider.allTodos
                .where((todo) => todo.projectGroupId == group.id)
                .toList();
            final completedCount = groupTodos.where((todo) => todo.isCompleted).length;
            final totalCount = groupTodos.length;
            final completionRate = totalCount > 0 ? (completedCount / totalCount) : 0.0;

            return Container(
              margin: EdgeInsets.only(bottom: isSmallScreen ? 8 : 12),
              child: Card(
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ProjectStatisticsWithSubtasksScreen(
                          projectGroup: group,
                          todos: groupTodos,
                        ),
                      ),
                    );
                  },
                  child: Padding(
                    padding: EdgeInsets.all(isSmallScreen ? 12 : 16),
                    child: Row(
                      children: [
                        // 项目组颜色标识
                        Container(
                          width: isSmallScreen ? 32 : 36,
                          height: isSmallScreen ? 32 : 36,
                          decoration: BoxDecoration(
                            color: Color(group.colorCode),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            FontAwesomeIcons.folderOpen,
                            color: Colors.white,
                            size: isSmallScreen ? 14 : 16,
                          ),
                        ),
                        SizedBox(width: isSmallScreen ? 12 : 16),
                        
                        // 项目组信息
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      group.name,
                                      style: TextStyle(
                                        fontSize: isSmallScreen ? 16 : 18,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                  Text(
                                    '$completedCount/$totalCount',
                                    style: TextStyle(
                                      fontSize: isSmallScreen ? 14 : 16,
                                      fontWeight: FontWeight.w600,
                                      color: AppTheme.primaryColor,
                                    ),
                                  ),
                                ],
                              ),
                              if (group.description.isNotEmpty) ...[
                                SizedBox(height: 4),
                                Text(
                                  group.description,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey[600],
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                              SizedBox(height: 8),
                              
                              // 进度条
                              LinearProgressIndicator(
                                value: completionRate,
                                backgroundColor: Colors.grey[300],
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  Color(group.colorCode),
                                ),
                                minHeight: isSmallScreen ? 4 : 6,
                              ),
                              SizedBox(height: 4),
                              Text(
                                '完成率: ${(completionRate * 100).toStringAsFixed(1)}%',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                        ),
                        
                        // 箭头图标
                        Icon(
                          Icons.chevron_right,
                          color: Colors.grey[400],
                          size: isSmallScreen ? 20 : 24,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
      ],
    );
  }

  Widget _buildOverviewCards(TodoProvider todoProvider, bool isSmallScreen) {
    final totalTasks = todoProvider.totalTodos;
    final completedTasks = todoProvider.completedTodos;
    final pendingTasks = todoProvider.pendingTodos;
    final overdueTasks = todoProvider.overdueTodos;

    // 计算子任务统计
    int totalSubtasks = 0;
    int completedSubtasks = 0;
    for (final todo in todoProvider.allTodos) {
      totalSubtasks += todo.subtasks.length;
      completedSubtasks += todo.subtasks.where((s) => s.isCompleted).length;
    }

    final completionRate =
        totalTasks > 0 ? (completedTasks / totalTasks * 100) : 0.0;
    final subtaskCompletionRate =
        totalSubtasks > 0 ? (completedSubtasks / totalSubtasks * 100) : 0.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '总体概览',
          style: TextStyle(
            fontSize: isSmallScreen ? 18 : 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(height: isSmallScreen ? 12 : 16),
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: isSmallScreen ? 2 : 3, // 调整为3列以适应更多卡片
          crossAxisSpacing: isSmallScreen ? 8 : 12,
          mainAxisSpacing: isSmallScreen ? 8 : 12,
          childAspectRatio: isSmallScreen ? 1.0 : 1.1,
          children: [
            _buildStatCard(
              '总任务数',
              totalTasks.toString(),
              FontAwesomeIcons.listCheck,
              Colors.blue,
              isSmallScreen,
            ),
            _buildStatCard(
              '已完成',
              completedTasks.toString(),
              FontAwesomeIcons.circleCheck,
              Colors.green,
              isSmallScreen,
            ),
            _buildStatCard(
              '待办中',
              pendingTasks.toString(),
              FontAwesomeIcons.clock,
              Colors.orange,
              isSmallScreen,
            ),
            _buildStatCard(
              '已逾期',
              overdueTasks.toString(),
              FontAwesomeIcons.triangleExclamation,
              Colors.red,
              isSmallScreen,
            ),
            _buildStatCard(
              '完成率',
              '${completionRate.toStringAsFixed(1)}%',
              FontAwesomeIcons.chartPie,
              Colors.purple,
              isSmallScreen,
            ),
            _buildStatCard(
              '总子任务',
              totalSubtasks.toString(),
              FontAwesomeIcons.listCheck,
              Colors.indigo,
              isSmallScreen,
            ),
            _buildStatCard(
              '子任务已完成',
              completedSubtasks.toString(),
              FontAwesomeIcons.checkDouble,
              Colors.teal,
              isSmallScreen,
            ),
            _buildStatCard(
              '子任务完成率',
              '${subtaskCompletionRate.toStringAsFixed(1)}%',
              FontAwesomeIcons.percent,
              Colors.cyan,
              isSmallScreen,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color,
      bool isSmallScreen) {
    return Container(
      height: isSmallScreen ? 130 : 150, // 进一步增加高度确保文字完整显示
      padding: EdgeInsets.all(isSmallScreen ? 12 : 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.1),
            spreadRadius: 1,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: EdgeInsets.all(isSmallScreen ? 8 : 12),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              color: color,
              size: isSmallScreen ? 20 : 24,
            ),
          ),
          SizedBox(height: isSmallScreen ? 8 : 12),
          Text(
            value,
            style: TextStyle(
              fontSize: isSmallScreen ? 18 : 20,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 6), // 增加间距
          Flexible( // 使用Flexible包装文本
            child: Text(
              title,
              style: TextStyle(
                fontSize: isSmallScreen ? 10 : 12,
                color: Colors.grey.shade600,
              ),
              textAlign: TextAlign.center,
              maxLines: 2, // 允许两行显示
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCompletionChart(TodoProvider todoProvider, bool isSmallScreen) {
    final completedTasks = todoProvider.completedTodos;
    final pendingTasks = todoProvider.pendingTodos;
    final totalTasks = completedTasks + pendingTasks;

    if (totalTasks == 0) {
      return const SizedBox.shrink();
    }

    final completionRate = completedTasks / totalTasks;

    return Container(
      padding: EdgeInsets.all(isSmallScreen ? 16 : 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.1),
            spreadRadius: 1,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '任务完成分布',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              // 自定义圆形进度指示器
              SizedBox(
                width: 120,
                height: 120,
                child: Stack(
                  children: [
                    Center(
                      child: SizedBox(
                        width: 100,
                        height: 100,
                        child: CircularProgressIndicator(
                          value: completionRate,
                          strokeWidth: 8,
                          backgroundColor: Colors.grey.shade200,
                          valueColor:
                              const AlwaysStoppedAnimation<Color>(Colors.green),
                        ),
                      ),
                    ),
                    Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            '${(completionRate * 100).toStringAsFixed(0)}%',
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.green,
                            ),
                          ),
                          const Text(
                            '完成率',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 32),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildLegendItem('已完成', completedTasks, Colors.green),
                    const SizedBox(height: 8),
                    _buildLegendItem('待办中', pendingTasks, Colors.orange),
                    const SizedBox(height: 8),
                    _buildLegendItem('总计', totalTasks, Colors.grey),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLegendItem(String label, int value, Color color) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 8),
        Text(
          '$label: $value',
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildCategoryStats(TodoProvider todoProvider, bool isSmallScreen) {
    final categoryStats = <Category, Map<String, int>>{};

    for (final category in Category.values) {
      final categoryTodos = todoProvider.allTodos
          .where((todo) => todo.category == category)
          .toList();
      categoryStats[category] = {
        'total': categoryTodos.length,
        'completed': categoryTodos.where((todo) => todo.isCompleted).length,
        'pending': categoryTodos.where((todo) => !todo.isCompleted).length,
      };
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.1),
            spreadRadius: 1,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '分类统计',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          ...categoryStats.entries.map((entry) {
            final category = entry.key;
            final stats = entry.value;
            final total = stats['total']!;
            final completed = stats['completed']!;

            if (total == 0) return const SizedBox.shrink();

            final completionRate = completed / total;

            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        _getCategoryName(category),
                        style: const TextStyle(fontWeight: FontWeight.w500),
                      ),
                      Text(
                        '$completed/$total',
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  LinearProgressIndicator(
                    value: completionRate,
                    backgroundColor: Colors.grey.shade200,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      _getCategoryColor(category),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildPriorityStats(TodoProvider todoProvider, bool isSmallScreen) {
    final priorityStats = <Priority, Map<String, int>>{};

    for (final priority in Priority.values) {
      final priorityTodos = todoProvider.allTodos
          .where((todo) => todo.priority == priority)
          .toList();
      priorityStats[priority] = {
        'total': priorityTodos.length,
        'completed': priorityTodos.where((todo) => todo.isCompleted).length,
        'pending': priorityTodos.where((todo) => !todo.isCompleted).length,
      };
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.1),
            spreadRadius: 1,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '优先级统计',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          ...priorityStats.entries.map((entry) {
            final priority = entry.key;
            final stats = entry.value;
            final total = stats['total']!;
            final completed = stats['completed']!;

            if (total == 0) return const SizedBox.shrink();

            final completionRate = completed / total;

            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        _getPriorityName(priority),
                        style: const TextStyle(fontWeight: FontWeight.w500),
                      ),
                      Text(
                        '$completed/$total',
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  LinearProgressIndicator(
                    value: completionRate,
                    backgroundColor: Colors.grey.shade200,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      _getPriorityColor(priority),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildTimeStats(TodoProvider todoProvider, bool isSmallScreen) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final tomorrow = today.add(const Duration(days: 1));
    final nextWeek = today.add(const Duration(days: 7));

    int todayTasks = 0;
    int tomorrowTasks = 0;
    int thisWeekTasks = 0;
    int overdueTasks = 0;

    for (final todo in todoProvider.allTodos) {
      if (todo.isCompleted) continue;

      if (todo.dueDate != null) {
        final dueDate = DateTime(
            todo.dueDate!.year, todo.dueDate!.month, todo.dueDate!.day);

        if (dueDate.isBefore(today)) {
          overdueTasks++;
        } else if (dueDate == today) {
          todayTasks++;
        } else if (dueDate == tomorrow) {
          tomorrowTasks++;
        } else if (dueDate.isBefore(nextWeek)) {
          thisWeekTasks++;
        }
      }
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.1),
            spreadRadius: 1,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '时间统计',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          _buildTimeStatRow('今天到期', todayTasks, Colors.blue),
          _buildTimeStatRow('明天到期', tomorrowTasks, Colors.green),
          _buildTimeStatRow('本周到期', thisWeekTasks, Colors.orange),
          _buildTimeStatRow('已逾期', overdueTasks, Colors.red),
        ],
      ),
    );
  }

  Widget _buildTimeStatRow(String label, int count, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(fontWeight: FontWeight.w500),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              count.toString(),
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _getCategoryName(Category category) {
    switch (category) {
      case Category.work:
        return '工作';
      case Category.personal:
        return '个人';
      case Category.shopping:
        return '购物';
      case Category.health:
        return '健康';
      case Category.education:
        return '教育';
      case Category.other:
        return '其他';
    }
  }

  Color _getCategoryColor(Category category) {
    switch (category) {
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

  String _getPriorityName(Priority priority) {
    switch (priority) {
      case Priority.low:
        return '低优先级';
      case Priority.medium:
        return '中优先级';
      case Priority.high:
        return '高优先级';
    }
  }

  Color _getPriorityColor(Priority priority) {
    switch (priority) {
      case Priority.low:
        return Colors.green;
      case Priority.medium:
        return Colors.orange;
      case Priority.high:
        return Colors.red;
    }
  }
}
