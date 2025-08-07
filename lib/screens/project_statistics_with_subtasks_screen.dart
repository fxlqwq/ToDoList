import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:fl_chart/fl_chart.dart';
import '../models/todo.dart';
import '../models/project_group.dart';
import '../models/subtask.dart';
import '../services/database_service.dart';

class ProjectStatisticsWithSubtasksScreen extends StatefulWidget {
  final ProjectGroup projectGroup;
  final List<Todo> todos;

  const ProjectStatisticsWithSubtasksScreen({
    super.key,
    required this.projectGroup,
    required this.todos,
  });

  @override
  State<ProjectStatisticsWithSubtasksScreen> createState() => _ProjectStatisticsWithSubtasksScreenState();
}

class _ProjectStatisticsWithSubtasksScreenState extends State<ProjectStatisticsWithSubtasksScreen> {
  List<Subtask> subtasks = [];
  bool isLoadingSubtasks = true;

  @override
  void initState() {
    super.initState();
    _loadSubtasks();
  }

  Future<void> _loadSubtasks() async {
    try {
      final dbService = DatabaseService();
      final loadedSubtasks = await dbService.getSubtasksForProjectGroup(widget.projectGroup.id!);
      setState(() {
        subtasks = loadedSubtasks;
        isLoadingSubtasks = false;
      });
    } catch (e) {
      setState(() {
        isLoadingSubtasks = false;
      });
    }
  }

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
              widget.projectGroup.name,
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
        backgroundColor: Color(widget.projectGroup.colorCode),
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
            _buildSubtaskStats(isSmallScreen),
            SizedBox(height: isSmallScreen ? 16 : 24),
            _buildCompletionChart(isSmallScreen),
            SizedBox(height: isSmallScreen ? 16 : 24),
            _buildCategoryStats(isSmallScreen),
            SizedBox(height: isSmallScreen ? 16 : 24),
            _buildPriorityStats(isSmallScreen),
            SizedBox(height: isSmallScreen ? 16 : 24),
            _buildTimeStats(isSmallScreen),
            if (widget.todos.isNotEmpty) ...[
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
            Color(widget.projectGroup.colorCode).withOpacity(0.1),
            Color(widget.projectGroup.colorCode).withOpacity(0.05),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Color(widget.projectGroup.colorCode).withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: isSmallScreen ? 48 : 56,
            height: isSmallScreen ? 48 : 56,
            decoration: BoxDecoration(
              color: Color(widget.projectGroup.colorCode),
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
                  widget.projectGroup.name,
                  style: TextStyle(
                    fontSize: isSmallScreen ? 20 : 24,
                    fontWeight: FontWeight.bold,
                    color: Color(widget.projectGroup.colorCode),
                  ),
                ),
                if (widget.projectGroup.description.isNotEmpty) ...[
                  SizedBox(height: 4),
                  Text(
                    widget.projectGroup.description,
                    style: TextStyle(
                      fontSize: isSmallScreen ? 14 : 16,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
                SizedBox(height: 8),
                Text(
                  '共 ${widget.todos.length} 个任务，${subtasks.length} 个子任务',
                  style: TextStyle(
                    fontSize: 14,
                    color: Color(widget.projectGroup.colorCode),
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
    final completedTasks = widget.todos.where((todo) => todo.isCompleted).length;
    final pendingTasks = widget.todos.length - completedTasks;
    final overdueTasks = widget.todos.where((todo) => todo.isOverdue && !todo.isCompleted).length;
    final completionRate = widget.todos.isNotEmpty ? (completedTasks / widget.todos.length) : 0.0;

    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                '总任务',
                widget.todos.length.toString(),
                FontAwesomeIcons.listCheck,
                Color(widget.projectGroup.colorCode),
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
            Color(widget.projectGroup.colorCode),
            isSmallScreen,
          ),
        ),
      ],
    );
  }

  Widget _buildSubtaskStats(bool isSmallScreen) {
    if (isLoadingSubtasks) {
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
            Row(
              children: [
                Icon(
                  FontAwesomeIcons.listUl,
                  color: Color(widget.projectGroup.colorCode),
                  size: isSmallScreen ? 18 : 20,
                ),
                SizedBox(width: 8),
                Text(
                  '子任务统计',
                  style: TextStyle(
                    fontSize: isSmallScreen ? 16 : 18,
                    fontWeight: FontWeight.bold,
                    color: Color(widget.projectGroup.colorCode),
                  ),
                ),
              ],
            ),
            SizedBox(height: 16),
            Center(
              child: CircularProgressIndicator(
                color: Color(widget.projectGroup.colorCode),
              ),
            ),
            SizedBox(height: 16),
          ],
        ),
      );
    }

    final totalSubtasks = subtasks.length;
    final completedSubtasks = subtasks.where((subtask) => subtask.isCompleted).length;
    final pendingSubtasks = totalSubtasks - completedSubtasks;
    final subtaskCompletionRate = totalSubtasks > 0 ? (completedSubtasks / totalSubtasks) : 0.0;

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
          Row(
            children: [
              Icon(
                FontAwesomeIcons.listUl,
                color: Color(widget.projectGroup.colorCode),
                size: isSmallScreen ? 18 : 20,
              ),
              SizedBox(width: 8),
              Text(
                '子任务统计',
                style: TextStyle(
                  fontSize: isSmallScreen ? 16 : 18,
                  fontWeight: FontWeight.bold,
                  color: Color(widget.projectGroup.colorCode),
                ),
              ),
            ],
          ),
          SizedBox(height: isSmallScreen ? 16 : 20),
          
          // 子任务概览卡片
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  '总子任务',
                  totalSubtasks.toString(),
                  FontAwesomeIcons.listCheck,
                  Color(widget.projectGroup.colorCode),
                  isSmallScreen,
                ),
              ),
              SizedBox(width: isSmallScreen ? 8 : 12),
              Expanded(
                child: _buildStatCard(
                  '已完成',
                  completedSubtasks.toString(),
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
                  pendingSubtasks.toString(),
                  FontAwesomeIcons.clock,
                  Colors.orange,
                  isSmallScreen,
                ),
              ),
              SizedBox(width: isSmallScreen ? 8 : 12),
              Expanded(
                child: _buildStatCard(
                  '完成率',
                  '${(subtaskCompletionRate * 100).toStringAsFixed(1)}%',
                  FontAwesomeIcons.chartPie,
                  Color(widget.projectGroup.colorCode),
                  isSmallScreen,
                ),
              ),
            ],
          ),

          if (totalSubtasks > 0) ...[
            SizedBox(height: isSmallScreen ? 16 : 20),
            
            // 子任务完成率进度条
            Container(
              padding: EdgeInsets.all(isSmallScreen ? 12 : 16),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Color(widget.projectGroup.colorCode).withOpacity(0.2),
                  width: 1,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '子任务进度',
                        style: TextStyle(
                          fontSize: isSmallScreen ? 14 : 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey[700],
                        ),
                      ),
                      Text(
                        '$completedSubtasks / $totalSubtasks',
                        style: TextStyle(
                          fontSize: isSmallScreen ? 12 : 14,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 8),
                  LinearProgressIndicator(
                    value: subtaskCompletionRate,
                    backgroundColor: Colors.grey[300],
                    valueColor: AlwaysStoppedAnimation<Color>(
                      Color(widget.projectGroup.colorCode),
                    ),
                    minHeight: 8,
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  // 以下方法从原始文件复制，并修改引用
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
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildCompletionChart(bool isSmallScreen) {
    final completedTasks = widget.todos.where((todo) => todo.isCompleted).length;
    final pendingTasks = widget.todos.length - completedTasks;

    if (widget.todos.isEmpty) {
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
            Row(
              children: [
                Icon(
                  FontAwesomeIcons.chartPie,
                  color: Color(widget.projectGroup.colorCode),
                  size: isSmallScreen ? 18 : 20,
                ),
                SizedBox(width: 8),
                Text(
                  '完成情况',
                  style: TextStyle(
                    fontSize: isSmallScreen ? 16 : 18,
                    fontWeight: FontWeight.bold,
                    color: Color(widget.projectGroup.colorCode),
                  ),
                ),
              ],
            ),
            SizedBox(height: isSmallScreen ? 16 : 20),
            Text(
              '暂无任务数据',
              style: TextStyle(
                color: Colors.grey[500],
                fontSize: isSmallScreen ? 14 : 16,
              ),
            ),
            SizedBox(height: isSmallScreen ? 16 : 20),
          ],
        ),
      );
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
          Row(
            children: [
              Icon(
                FontAwesomeIcons.chartPie,
                color: Color(widget.projectGroup.colorCode),
                size: isSmallScreen ? 18 : 20,
              ),
              SizedBox(width: 8),
              Text(
                '完成情况',
                style: TextStyle(
                  fontSize: isSmallScreen ? 16 : 18,
                  fontWeight: FontWeight.bold,
                  color: Color(widget.projectGroup.colorCode),
                ),
              ),
            ],
          ),
          SizedBox(height: isSmallScreen ? 16 : 20),
          SizedBox(
            height: isSmallScreen ? 180 : 200,
            child: PieChart(
              PieChartData(
                sectionsSpace: 2,
                centerSpaceRadius: isSmallScreen ? 30 : 40,
                sections: [
                  PieChartSectionData(
                    color: Colors.green,
                    value: completedTasks.toDouble(),
                    title: '已完成\n$completedTasks',
                    radius: isSmallScreen ? 50 : 60,
                    titleStyle: TextStyle(
                      fontSize: isSmallScreen ? 12 : 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  PieChartSectionData(
                    color: Colors.orange,
                    value: pendingTasks.toDouble(),
                    title: '进行中\n$pendingTasks',
                    radius: isSmallScreen ? 50 : 60,
                    titleStyle: TextStyle(
                      fontSize: isSmallScreen ? 12 : 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryStats(bool isSmallScreen) {
    final Map<Category, int> categoryStats = {};
    for (var category in Category.values) {
      categoryStats[category] = widget.todos.where((todo) => todo.category == category).length;
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
          Row(
            children: [
              Icon(
                FontAwesomeIcons.tags,
                color: Color(widget.projectGroup.colorCode),
                size: isSmallScreen ? 18 : 20,
              ),
              SizedBox(width: 8),
              Text(
                '分类统计',
                style: TextStyle(
                  fontSize: isSmallScreen ? 16 : 18,
                  fontWeight: FontWeight.bold,
                  color: Color(widget.projectGroup.colorCode),
                ),
              ),
            ],
          ),
          SizedBox(height: isSmallScreen ? 16 : 20),
          ...categoryStats.entries.map((entry) {
            final count = entry.value;
            final percentage = widget.todos.isNotEmpty ? (count / widget.todos.length) : 0.0;
            final color = _getCategoryColor(entry.key);
            
            return Container(
              margin: EdgeInsets.only(bottom: isSmallScreen ? 12 : 16),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 12,
                            height: 12,
                            decoration: BoxDecoration(
                              color: color,
                              shape: BoxShape.circle,
                            ),
                          ),
                          SizedBox(width: 8),
                          Text(
                            _getCategoryName(entry.key),
                            style: TextStyle(
                              fontSize: isSmallScreen ? 14 : 16,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                      Row(
                        children: [
                          Text(
                            '$count',
                            style: TextStyle(
                              fontSize: isSmallScreen ? 14 : 16,
                              fontWeight: FontWeight.bold,
                              color: Color(widget.projectGroup.colorCode),
                            ),
                          ),
                          SizedBox(width: 8),
                          Text(
                            '${(percentage * 100).toStringAsFixed(1)}%',
                            style: TextStyle(
                              fontSize: isSmallScreen ? 12 : 14,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  SizedBox(height: 8),
                  LinearProgressIndicator(
                    value: percentage,
                    backgroundColor: Colors.grey[200],
                    valueColor: AlwaysStoppedAnimation<Color>(color),
                    minHeight: 6,
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
    final Map<Priority, int> priorityStats = {};
    for (var priority in Priority.values) {
      priorityStats[priority] = widget.todos.where((todo) => todo.priority == priority).length;
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
          Row(
            children: [
              Icon(
                FontAwesomeIcons.exclamation,
                color: Color(widget.projectGroup.colorCode),
                size: isSmallScreen ? 18 : 20,
              ),
              SizedBox(width: 8),
              Text(
                '优先级统计',
                style: TextStyle(
                  fontSize: isSmallScreen ? 16 : 18,
                  fontWeight: FontWeight.bold,
                  color: Color(widget.projectGroup.colorCode),
                ),
              ),
            ],
          ),
          SizedBox(height: isSmallScreen ? 16 : 20),
          ...priorityStats.entries.map((entry) {
            final count = entry.value;
            final percentage = widget.todos.isNotEmpty ? (count / widget.todos.length) : 0.0;
            final color = _getPriorityColor(entry.key);
            final priorityName = _getPriorityName(entry.key);
            
            return Container(
              margin: EdgeInsets.only(bottom: isSmallScreen ? 12 : 16),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 12,
                            height: 12,
                            decoration: BoxDecoration(
                              color: color,
                              shape: BoxShape.circle,
                            ),
                          ),
                          SizedBox(width: 8),
                          Text(
                            priorityName,
                            style: TextStyle(
                              fontSize: isSmallScreen ? 14 : 16,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                      Row(
                        children: [
                          Text(
                            '$count',
                            style: TextStyle(
                              fontSize: isSmallScreen ? 14 : 16,
                              fontWeight: FontWeight.bold,
                              color: color,
                            ),
                          ),
                          SizedBox(width: 8),
                          Text(
                            '${(percentage * 100).toStringAsFixed(1)}%',
                            style: TextStyle(
                              fontSize: isSmallScreen ? 12 : 14,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  SizedBox(height: 8),
                  LinearProgressIndicator(
                    value: percentage,
                    backgroundColor: Colors.grey[200],
                    valueColor: AlwaysStoppedAnimation<Color>(color),
                    minHeight: 6,
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
    final today = DateTime(now.year, now.month, now.day);
    final thisWeekStart = today.subtract(Duration(days: now.weekday - 1));

    final todayTasks = widget.todos.where((todo) {
      if (todo.dueDate == null) return false;
      final dueDate = DateTime(todo.dueDate!.year, todo.dueDate!.month, todo.dueDate!.day);
      return dueDate == today;
    }).length;

    final thisWeekTasks = widget.todos.where((todo) {
      if (todo.dueDate == null) return false;
      final dueDate = DateTime(todo.dueDate!.year, todo.dueDate!.month, todo.dueDate!.day);
      return dueDate.isAfter(thisWeekStart.subtract(Duration(days: 1))) && 
             dueDate.isBefore(today.add(Duration(days: 7)));
    }).length;

    final overdueTasks = widget.todos.where((todo) => todo.isOverdue && !todo.isCompleted).length;

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
          Row(
            children: [
              Icon(
                FontAwesomeIcons.clock,
                color: Color(widget.projectGroup.colorCode),
                size: isSmallScreen ? 18 : 20,
              ),
              SizedBox(width: 8),
              Text(
                '时间统计',
                style: TextStyle(
                  fontSize: isSmallScreen ? 16 : 18,
                  fontWeight: FontWeight.bold,
                  color: Color(widget.projectGroup.colorCode),
                ),
              ),
            ],
          ),
          SizedBox(height: isSmallScreen ? 16 : 20),
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  '今日任务',
                  todayTasks.toString(),
                  FontAwesomeIcons.calendarDay,
                  Colors.blue,
                  isSmallScreen,
                ),
              ),
              SizedBox(width: isSmallScreen ? 8 : 12),
              Expanded(
                child: _buildStatCard(
                  '本周任务',
                  thisWeekTasks.toString(),
                  FontAwesomeIcons.calendarWeek,
                  Colors.purple,
                  isSmallScreen,
                ),
              ),
            ],
          ),
          SizedBox(height: isSmallScreen ? 8 : 12),
          Container(
            width: double.infinity,
            child: _buildStatCard(
              '逾期任务',
              overdueTasks.toString(),
              FontAwesomeIcons.triangleExclamation,
              Colors.red,
              isSmallScreen,
            ),
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
          Row(
            children: [
              Icon(
                FontAwesomeIcons.list,
                color: Color(widget.projectGroup.colorCode),
                size: isSmallScreen ? 18 : 20,
              ),
              SizedBox(width: 8),
              Text(
                '任务列表',
                style: TextStyle(
                  fontSize: isSmallScreen ? 16 : 18,
                  fontWeight: FontWeight.bold,
                  color: Color(widget.projectGroup.colorCode),
                ),
              ),
            ],
          ),
          SizedBox(height: isSmallScreen ? 16 : 20),
          ...widget.todos.take(10).map((todo) {
            return Container(
              margin: EdgeInsets.only(bottom: isSmallScreen ? 8 : 12),
              padding: EdgeInsets.all(isSmallScreen ? 12 : 16),
              decoration: BoxDecoration(
                color: todo.isCompleted ? Colors.green[50] : Colors.grey[50],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: todo.isCompleted ? Colors.green.withOpacity(0.3) : Colors.grey.withOpacity(0.3),
                  width: 1,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    todo.isCompleted ? FontAwesomeIcons.circleCheck : FontAwesomeIcons.circle,
                    color: todo.isCompleted ? Colors.green : Colors.grey,
                    size: isSmallScreen ? 16 : 18,
                  ),
                  SizedBox(width: 12),
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
                            color: todo.isCompleted ? Colors.grey[600] : Colors.black87,
                          ),
                        ),
                        if (todo.dueDate != null) ...[
                          SizedBox(height: 4),
                          Text(
                            '截止: ${todo.dueDate!.month}/${todo.dueDate!.day}',
                            style: TextStyle(
                              fontSize: isSmallScreen ? 12 : 14,
                              color: todo.isOverdue && !todo.isCompleted ? Colors.red : Colors.grey[600],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: _getPriorityColor(todo.priority).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      _getPriorityName(todo.priority),
                      style: TextStyle(
                        fontSize: isSmallScreen ? 10 : 12,
                        color: _getPriorityColor(todo.priority),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
          if (widget.todos.length > 10) ...[
            SizedBox(height: 8),
            Text(
              '... 还有 ${widget.todos.length - 10} 个任务',
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: isSmallScreen ? 12 : 14,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ],
      ),
    );
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
