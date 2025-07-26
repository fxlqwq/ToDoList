import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../utils/app_theme.dart';

/// 使用说明对话框
class UsageGuideDialog extends StatefulWidget {
  const UsageGuideDialog({super.key});

  static Future<bool?> show(BuildContext context) {
    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => const UsageGuideDialog(),
    );
  }

  @override
  State<UsageGuideDialog> createState() => _UsageGuideDialogState();
}

class _UsageGuideDialogState extends State<UsageGuideDialog> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final List<GuideStep> _steps = [
    const GuideStep(
      icon: FontAwesomeIcons.plus,
      title: '创建待办事项',
      description: '点击右下角的 + 按钮即可创建新的待办事项。你可以设置标题、描述、优先级和提醒时间。',
      color: AppTheme.primaryColor,
    ),
    const GuideStep(
      icon: FontAwesomeIcons.bell,
      title: '智能提醒功能',
      description: '设置提醒时间后，应用会在指定时间发送通知提醒你完成任务，即使应用处于后台也能正常提醒。',
      color: Color(0xFFE11D48),
    ),
    const GuideStep(
      icon: FontAwesomeIcons.checkDouble,
      title: '管理任务状态',
      description: '点击任务卡片左侧的圆圈标记任务完成，长按任务卡片可以进行编辑或删除操作。',
      color: Color(0xFF10B981),
    ),
    const GuideStep(
      icon: FontAwesomeIcons.filter,
      title: '筛选和分类',
      description: '使用顶部的筛选器按优先级、分类或完成状态查看任务，让你的工作更有条理。',
      color: Color(0xFF8B5CF6),
    ),
    const GuideStep(
      icon: FontAwesomeIcons.chartLine,
      title: '统计信息',
      description: '主页顶部显示你的任务统计，包括总任务数、已完成数和逾期任务数，帮助你掌握进度。',
      color: Color(0xFFF59E0B),
    ),
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _nextPage() {
    if (_currentPage < _steps.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      Navigator.of(context).pop(true);
    }
  }

  void _previousPage() {
    if (_currentPage > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      child: Container(
        constraints: const BoxConstraints(
          maxHeight: 600,
          maxWidth: 400,
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    FontAwesomeIcons.lightbulb,
                    color: AppTheme.primaryColor,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text(
                    '使用指南',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Text(
                  '${_currentPage + 1}/${_steps.length}',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            
            // Page Indicator
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                _steps.length,
                (index) => Container(
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  width: _currentPage == index ? 24 : 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: _currentPage == index
                        ? AppTheme.primaryColor
                        : Colors.grey[300],
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),
            
            // Content
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                onPageChanged: (index) {
                  setState(() {
                    _currentPage = index;
                  });
                },
                itemCount: _steps.length,
                itemBuilder: (context, index) {
                  final step = _steps[index];
                  return Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          color: step.color.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(40),
                        ),
                        child: Icon(
                          step.icon,
                          size: 36,
                          color: step.color,
                        ),
                      ),
                      const SizedBox(height: 24),
                      Text(
                        step.title,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        step.description,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                          height: 1.5,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  );
                },
              ),
            ),
            
            // Navigation Buttons
            Row(
              children: [
                if (_currentPage > 0)
                  TextButton(
                    onPressed: _previousPage,
                    child: const Text('上一步'),
                  ),
                const Spacer(),
                if (_currentPage < _steps.length - 1)
                  ElevatedButton(
                    onPressed: _nextPage,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryColor,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text('下一步'),
                  )
                else
                  ElevatedButton(
                    onPressed: _nextPage,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF10B981),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text('开始使用'),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class GuideStep {
  final IconData icon;
  final String title;
  final String description;
  final Color color;

  const GuideStep({
    required this.icon,
    required this.title,
    required this.description,
    required this.color,
  });
}
