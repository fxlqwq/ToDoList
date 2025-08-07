import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:fl_chart/fl_chart.dart';
import '../models/todo.dart';
import '../models/project_group.dart';
import '../models/subtask.dart';
import '../services/database_service.dart';

class ProjectStatisticsScreen extends StatelessWidget {
  final ProjectGroup projectGroup;
  final List<Todo> todos;

  const ProjectStatisticsScreen({
    super.key,
    required this.projectGroup,
    required this.todos,
  });

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 400;

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              projectGroup.name,
              style: const TextStyle(fontSize: 18),
            ),
            Text(
              '项目统计',
              style: TextStyle(
                fontSize: 14,
                color: Colors.white.withOpacity(0.8),
              ),
            ),
          ],
        ),
        backgroundColor: Color(projectGroup.colorCode),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(isSmallScreen ? 12 : 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildProjectHeader(isSmallScreen),
            SizedBox(height: isSmallScreen ? 16 : 24),
            _buildOverviewCards(isSmallScreen),
            SizedBox(height: isSmallScreen ? 16 : 24),
            _buildCompletionChart(isSmallScreen),
            SizedBox(height: isSmallScreen ? 16 : 24),
            _buildCategoryStats(isSmallScreen),
            SizedBox(height: isSmallScreen ? 16 : 24),
            _buildPriorityStats(isSmallScreen),
            SizedBox(height: isSmallScreen ? 16 : 24),
            _buildTimeStats(isSmallScreen),
            if (todos.isNotEmpty) ...[
              SizedBox(height: isSmallScreen ? 16 : 24),
              _buildTaskList(isSmallScreen),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildProjectHeader(bool isSmallScreen) {
    return Container(
      padding: EdgeInsets.all(isSmallScreen ? 16 : 20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Color(projectGroup.colorCode).withOpacity(0.1),
            Color(projectGroup.colorCode).withOpacity(0.05),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Color(projectGroup.colorCode).withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: isSmallScreen ? 48 : 56,
            height: isSmallScreen ? 48 : 56,
            decoration: BoxDecoration(
              color: Color(projectGroup.colorCode),
              shape: BoxShape.circle,
            ),
            child: Icon(
              FontAwesomeIcons.folderOpen,
              color: Colors.white,
              size: isSmallScreen ? 20 : 24,
            ),
          ),
          SizedBox(width: isSmallScreen ? 12 : 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  projectGroup.name,
                  style: TextStyle(
                    fontSize: isSmallScreen ? 20 : 24,
                    fontWeight: FontWeight.bold,
                    color: Color(projectGroup.colorCode),
                  ),
                ),
                if (projectGroup.description.isNotEmpty) ...[
                  SizedBox(height: 4),
                  Text(
                    projectGroup.description,
                    style: TextStyle(
                      fontSize: isSmallScreen ? 14 : 16,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
                SizedBox(height: 8),
                Text(
                  '共 ${todos.length} 个任务',
                  style: TextStyle(
                    fontSize: 14,
                    color: Color(projectGroup.colorCode),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOverviewCards(bool isSmallScreen) {
    final completedTasks = todos.where((todo) => todo.isCompleted).length;
    final pendingTasks = todos.length - completedTasks;
    final overdueTasks = todos.where((todo) => todo.isOverdue && !todo.isCompleted).length;
    final completionRate = todos.isNotEmpty ? (completedTasks / todos.length) : 0.0;

    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                '总任务',
                todos.length.toString(),
                FontAwesomeIcons.listCheck,
                Color(projectGroup.colorCode),
                isSmallScreen,
              ),
            ),
            SizedBox(width: isSmallScreen ? 8 : 12),
            Expanded(
              child: _buildStatCard(
                '已完成',
                completedTasks.toString(),
                FontAwesomeIcons.circleCheck,
                Colors.green,
                isSmallScreen,
              ),
            ),
          ],
        ),
        SizedBox(height: isSmallScreen ? 8 : 12),
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                '进行中',
                pendingTasks.toString(),
                FontAwesomeIcons.clock,
                Colors.orange,
                isSmallScreen,
              ),
            ),
            SizedBox(width: isSmallScreen ? 8 : 12),
            Expanded(
              child: _buildStatCard(
                '已逾期',
                overdueTasks.toString(),
                FontAwesomeIcons.triangleExclamation,
                Colors.red,
                isSmallScreen,
              ),
            ),
          ],
        ),
        SizedBox(height: isSmallScreen ? 8 : 12),
        Container(
          width: double.infinity,
          child: _buildStatCard(
            '完成率',
            '${(completionRate * 100).toStringAsFixed(1)}%',
            FontAwesomeIcons.chartPie,
            Color(projectGroup.colorCode),
            isSmallScreen,
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color, bool isSmallScreen) {
    return Container(
      padding: EdgeInsets.all(isSmallScreen ? 12 : 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
        border: Border.all(
          color: color.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Icon(
            icon,
            color: color,
            size: isSmallScreen ? 20 : 24,
          ),
          SizedBox(height: isSmallScreen ? 8 : 12),
          Text(
            value,
            style: TextStyle(
              fontSize: isSmallScreen ? 20 : 24,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          SizedBox(height: 4),
          Text(
            title,
            style: TextStyle(
              fontSize: isSmallScreen ? 12 : 14,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCompletionChart(bool isSmallScreen) {
    final completedTasks = todos.where((todo) => todo.isCompleted).length;
    final pendingTasks = todos.length - completedTasks;

    if (todos.isEmpty) {
      return _buildEmptyChart('完成进度', isSmallScreen);
    }

    return Container(
      padding: EdgeInsets.all(isSmallScreen ? 16 : 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '完成进度',
            style: TextStyle(
              fontSize: isSmallScreen ? 16 : 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: isSmallScreen ? 16 : 20),
          SizedBox(
            height: isSmallScreen ? 200 : 250,
            child: PieChart(
              PieChartData(
                sections: [
                  PieChartSectionData(
                    color: Colors.green,
                    value: completedTasks.toDouble(),
                    title: '已完成\n$completedTasks',
                    radius: isSmallScreen ? 80 : 100,
                    titleStyle: TextStyle(
                      fontSize: isSmallScreen ? 12 : 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  PieChartSectionData(
                    color: Colors.orange,
                    value: pendingTasks.toDouble(),
                    title: '待完成\n$pendingTasks',
                    radius: isSmallScreen ? 80 : 100,
                    titleStyle: TextStyle(
                      fontSize: isSmallScreen ? 12 : 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ],
                sectionsSpace: 2,
                centerSpaceRadius: isSmallScreen ? 30 : 40,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryStats(bool isSmallScreen) {
    final categoryStats = <Category, int>{};
    for (final category in Category.values) {
      categoryStats[category] = todos.where((todo) => todo.category == category).length;
    }

    return Container(
      padding: EdgeInsets.all(isSmallScreen ? 16 : 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '分类统计',
            style: TextStyle(
              fontSize: isSmallScreen ? 16 : 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: isSmallScreen ? 12 : 16),
          ...categoryStats.entries.map((entry) {
            final category = entry.key;
            final count = entry.value;
            final percentage = todos.isNotEmpty ? (count / todos.length) : 0.0;
            
            return Container(
              margin: EdgeInsets.only(bottom: isSmallScreen ? 8 : 12),
              child: Row(
                children: [
                  Container(
                    width: isSmallScreen ? 80 : 100,
                    child: Text(
                      _getCategoryName(category),
                      style: TextStyle(
                        fontSize: isSmallScreen ? 13 : 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  Expanded(
                    child: Container(
                      height: isSmallScreen ? 20 : 24,
                      decoration: BoxDecoration(
                        color: Colors.grey[200],
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: FractionallySizedBox(
                        alignment: Alignment.centerLeft,
                        widthFactor: percentage,
                        child: Container(
                          decoration: BoxDecoration(
                            color: Color(projectGroup.colorCode),
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: 8),
                  SizedBox(
                    width: isSmallScreen ? 40 : 50,
                    child: Text(
                      '$count',
                      style: TextStyle(
                        fontSize: isSmallScreen ? 13 : 14,
                        fontWeight: FontWeight.bold,
                        color: Color(projectGroup.colorCode),
                      ),
                      textAlign: TextAlign.end,
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        ],
      ),
    );
  }

  Widget _buildPriorityStats(bool isSmallScreen) {
    final priorityStats = <Priority, int>{};
    for (final priority in Priority.values) {
      priorityStats[priority] = todos.where((todo) => todo.priority == priority).length;
    }

    return Container(
      padding: EdgeInsets.all(isSmallScreen ? 16 : 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '优先级统计',
            style: TextStyle(
              fontSize: isSmallScreen ? 16 : 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: isSmallScreen ? 12 : 16),
          ...priorityStats.entries.map((entry) {
            final priority = entry.key;
            final count = entry.value;
            final percentage = todos.isNotEmpty ? (count / todos.length) : 0.0;
            final color = _getPriorityColor(priority);
            
            return Container(
              margin: EdgeInsets.only(bottom: isSmallScreen ? 8 : 12),
              child: Row(
                children: [
                  Container(
                    width: isSmallScreen ? 80 : 100,
                    child: Text(
                      _getPriorityName(priority),
                      style: TextStyle(
                        fontSize: isSmallScreen ? 13 : 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  Expanded(
                    child: Container(
                      height: isSmallScreen ? 20 : 24,
                      decoration: BoxDecoration(
                        color: Colors.grey[200],
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: FractionallySizedBox(
                        alignment: Alignment.centerLeft,
                        widthFactor: percentage,
                        child: Container(
                          decoration: BoxDecoration(
                            color: color,
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: 8),
                  SizedBox(
                    width: isSmallScreen ? 40 : 50,
                    child: Text(
                      '$count',
                      style: TextStyle(
                        fontSize: isSmallScreen ? 13 : 14,
                        fontWeight: FontWeight.bold,
                        color: color,
                      ),
                      textAlign: TextAlign.end,
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        ],
      ),
    );
  }

  Widget _buildTimeStats(bool isSmallScreen) {
    final now = DateTime.now();
    final todayTasks = todos.where((todo) {
      return todo.dueDate != null && 
             todo.dueDate!.year == now.year &&
             todo.dueDate!.month == now.month &&
             todo.dueDate!.day == now.day;
    }).length;

    final thisWeekTasks = todos.where((todo) {
      if (todo.dueDate == null) return false;
      final weekStart = now.subtract(Duration(days: now.weekday - 1));
      final weekEnd = weekStart.add(const Duration(days: 6));
      return todo.dueDate!.isAfter(weekStart) && todo.dueDate!.isBefore(weekEnd.add(const Duration(days: 1)));
    }).length;

    final overdueTasks = todos.where((todo) => todo.isOverdue && !todo.isCompleted).length;

    return Container(
      padding: EdgeInsets.all(isSmallScreen ? 16 : 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '时间统计',
            style: TextStyle(
              fontSize: isSmallScreen ? 16 : 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: isSmallScreen ? 12 : 16),
          Row(
            children: [
              Expanded(
                child: _buildTimeStatCard(
                  '今日到期',
                  todayTasks.toString(),
                  FontAwesomeIcons.calendar,
                  Colors.blue,
                  isSmallScreen,
                ),
              ),
              SizedBox(width: isSmallScreen ? 8 : 12),
              Expanded(
                child: _buildTimeStatCard(
                  '本周到期',
                  thisWeekTasks.toString(),
                  FontAwesomeIcons.calendarWeek,
                  Colors.green,
                  isSmallScreen,
                ),
              ),
              SizedBox(width: isSmallScreen ? 8 : 12),
              Expanded(
                child: _buildTimeStatCard(
                  '已逾期',
                  overdueTasks.toString(),
                  FontAwesomeIcons.triangleExclamation,
                  Colors.red,
                  isSmallScreen,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTimeStatCard(String title, String value, IconData icon, Color color, bool isSmallScreen) {
    return Container(
      padding: EdgeInsets.all(isSmallScreen ? 8 : 12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: color.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Icon(
            icon,
            color: color,
            size: isSmallScreen ? 16 : 20,
          ),
          SizedBox(height: isSmallScreen ? 4 : 8),
          Text(
            value,
            style: TextStyle(
              fontSize: isSmallScreen ? 16 : 18,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          SizedBox(height: 2),
          Text(
            title,
            style: TextStyle(
              fontSize: isSmallScreen ? 10 : 12,
              color: color,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildTaskList(bool isSmallScreen) {
    return Container(
      padding: EdgeInsets.all(isSmallScreen ? 16 : 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '任务列表',
            style: TextStyle(
              fontSize: isSmallScreen ? 16 : 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: isSmallScreen ? 12 : 16),
          ...todos.take(10).map((todo) {
            return Container(
              margin: EdgeInsets.only(bottom: isSmallScreen ? 8 : 12),
              padding: EdgeInsets.all(isSmallScreen ? 8 : 12),
              decoration: BoxDecoration(
                color: todo.isCompleted 
                    ? Colors.green.withOpacity(0.1)
                    : (todo.isOverdue ? Colors.red.withOpacity(0.1) : Colors.grey.withOpacity(0.1)),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: todo.isCompleted 
                      ? Colors.green.withOpacity(0.3)
                      : (todo.isOverdue ? Colors.red.withOpacity(0.3) : Colors.grey.withOpacity(0.3)),
                  width: 1,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    todo.isCompleted 
                        ? FontAwesomeIcons.circleCheck
                        : (todo.isOverdue ? FontAwesomeIcons.triangleExclamation : FontAwesomeIcons.circle),
                    color: todo.isCompleted 
                        ? Colors.green
                        : (todo.isOverdue ? Colors.red : Colors.grey),
                    size: isSmallScreen ? 16 : 18,
                  ),
                  SizedBox(width: isSmallScreen ? 8 : 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          todo.title,
                          style: TextStyle(
                            fontSize: isSmallScreen ? 14 : 16,
                            fontWeight: FontWeight.w500,
                            decoration: todo.isCompleted ? TextDecoration.lineThrough : null,
                          ),
                        ),
                        if (todo.dueDate != null) ...[
                          SizedBox(height: 2),
                          Text(
                            '到期: ${todo.dueDate!.month}/${todo.dueDate!.day} ${todo.dueDate!.hour}:${todo.dueDate!.minute.toString().padLeft(2, '0')}',
                            style: TextStyle(
                              fontSize: 12,
                              color: todo.isOverdue && !todo.isCompleted ? Colors.red : Colors.grey[600],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: _getPriorityColor(todo.priority).withOpacity(0.2),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      _getPriorityName(todo.priority),
                      style: TextStyle(
                        fontSize: 10,
                        color: _getPriorityColor(todo.priority),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
          if (todos.length > 10) ...[
            SizedBox(height: 8),
            Text(
              '... 还有 ${todos.length - 10} 个任务',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildEmptyChart(String title, bool isSmallScreen) {
    return Container(
      padding: EdgeInsets.all(isSmallScreen ? 16 : 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: isSmallScreen ? 16 : 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: isSmallScreen ? 20 : 30),
          Icon(
            FontAwesomeIcons.chartPie,
            color: Colors.grey[300],
            size: isSmallScreen ? 48 : 64,
          ),
          SizedBox(height: 12),
          Text(
            '暂无数据',
            style: TextStyle(
              color: Colors.grey[500],
              fontSize: isSmallScreen ? 14 : 16,
            ),
          ),
        ],
      ),
    );
  }

  String _getCategoryName(Category category) {
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

  String _getPriorityName(Priority priority) {
    switch (priority) {
      case Priority.high:
        return '高';
      case Priority.medium:
        return '中';
      case Priority.low:
        return '低';
    }
  }

  Color _getPriorityColor(Priority priority) {
    switch (priority) {
      case Priority.high:
        return Colors.red;
      case Priority.medium:
        return Colors.orange;
      case Priority.low:
        return Colors.green;
    }
  }
}
