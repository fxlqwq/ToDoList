import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import '../models/project_group.dart';
import '../services/database_service.dart';
import '../services/todo_provider.dart';

class ProjectGroupManagerScreen extends StatefulWidget {
  const ProjectGroupManagerScreen({super.key});

  @override
  State<ProjectGroupManagerScreen> createState() => _ProjectGroupManagerScreenState();
}

class _ProjectGroupManagerScreenState extends State<ProjectGroupManagerScreen> {
  final DatabaseService _databaseService = DatabaseService();
  List<ProjectGroup> _projectGroups = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadProjectGroups();
  }

  Future<void> _loadProjectGroups() async {
    setState(() => _isLoading = true);
    try {
      final groups = await _databaseService.getAllProjectGroups();
      setState(() => _projectGroups = groups);
    } catch (e) {
      _showSnackBar('加载项目组失败: $e', isError: true);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : Colors.green,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _showAddEditDialog({ProjectGroup? group}) async {
    final isEditing = group != null;
    final nameController = TextEditingController(text: group?.name ?? '');
    final descriptionController = TextEditingController(text: group?.description ?? '');
    Color selectedColor = Color(group?.colorCode ?? 0xFF2196F3);

    final result = await showDialog<ProjectGroup>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(isEditing ? '编辑项目组' : '新建项目组'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    labelText: '项目组名称',
                    hintText: '输入项目组名称',
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: descriptionController,
                  decoration: const InputDecoration(
                    labelText: '描述',
                    hintText: '输入项目组描述（可选）',
                  ),
                  maxLines: 3,
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    const Text('颜色: '),
                    const SizedBox(width: 8),
                    GestureDetector(
                      onTap: () {
                        showDialog(
                          context: context,
                          builder: (context) => AlertDialog(
                            title: const Text('选择颜色'),
                            content: SingleChildScrollView(
                              child: ColorPicker(
                                pickerColor: selectedColor,
                                onColorChanged: (color) {
                                  selectedColor = color;
                                },
                              ),
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.of(context).pop(),
                                child: const Text('取消'),
                              ),
                              TextButton(
                                onPressed: () {
                                  setDialogState(() {});
                                  Navigator.of(context).pop();
                                },
                                child: const Text('确定'),
                              ),
                            ],
                          ),
                        );
                      },
                      child: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: selectedColor,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.grey),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('取消'),
            ),
            TextButton(
              onPressed: () {
                if (nameController.text.trim().isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('项目组名称不能为空')),
                  );
                  return;
                }

                final newGroup = ProjectGroup(
                  id: group?.id,
                  name: nameController.text.trim(),
                  description: descriptionController.text.trim(),
                  colorCode: selectedColor.value,
                  isDefault: group?.isDefault ?? false,
                );

                Navigator.of(context).pop(newGroup);
              },
              child: Text(isEditing ? '保存' : '创建'),
            ),
          ],
        ),
      ),
    );

    if (result != null) {
      try {
        if (isEditing) {
          await _databaseService.updateProjectGroup(result);
          _showSnackBar('项目组更新成功');
        } else {
          await _databaseService.insertProjectGroup(result);
          _showSnackBar('项目组创建成功');
        }
        await _loadProjectGroups();
        
        // Refresh todo provider
        if (mounted) {
          context.read<TodoProvider>().loadTodos();
        }
      } catch (e) {
        _showSnackBar('操作失败: $e', isError: true);
      }
    }
  }

  Future<void> _deleteProjectGroup(ProjectGroup group) async {
    if (group.isDefault) {
      _showSnackBar('无法删除默认项目组', isError: true);
      return;
    }

    final stats = await _databaseService.getProjectGroupStats(group.id!);
    final todoCount = stats['total'] ?? 0;

    if (!mounted) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('确认删除'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('确定要删除项目组 "${group.name}" 吗？'),
            if (todoCount > 0) ...[
              const SizedBox(height: 8),
              Text(
                '该项目组中有 $todoCount 个任务，删除后这些任务将移动到默认项目组。',
                style: TextStyle(color: Colors.orange[700]),
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('删除'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await _databaseService.deleteProjectGroup(group.id!);
        await _loadProjectGroups();
        _showSnackBar('项目组删除成功');
        
        // Refresh todo provider
        if (mounted) {
          context.read<TodoProvider>().loadTodos();
        }
      } catch (e) {
        _showSnackBar('删除失败: $e', isError: true);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('项目组管理'),
        elevation: 0,
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            onPressed: () => _showAddEditDialog(),
            icon: const Icon(Icons.add),
            tooltip: '新建项目组',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _projectGroups.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.folder_open,
                        size: 64,
                        color: Colors.grey[400],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        '暂无项目组',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              color: Colors.grey[600],
                            ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '点击右上角的 + 号创建第一个项目组',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: Colors.grey[500],
                            ),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16.0),
                  itemCount: _projectGroups.length,
                  itemBuilder: (context, index) {
                    final group = _projectGroups[index];
                    return _buildProjectGroupCard(group);
                  },
                ),
    );
  }

  Widget _buildProjectGroupCard(ProjectGroup group) {
    return FutureBuilder<Map<String, int>>(
      future: _databaseService.getProjectGroupStats(group.id!),
      builder: (context, snapshot) {
        final stats = snapshot.data ?? {'total': 0, 'completed': 0, 'pending': 0};
        
        return Card(
          margin: const EdgeInsets.only(bottom: 12.0),
          child: InkWell(
            borderRadius: BorderRadius.circular(8.0),
            onTap: () => _showAddEditDialog(group: group),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 24,
                        height: 24,
                        decoration: BoxDecoration(
                          color: Color(group.colorCode),
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    group.name,
                                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                          fontWeight: FontWeight.bold,
                                        ),
                                  ),
                                ),
                                if (group.isDefault)
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.blue[100],
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Text(
                                      '默认',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.blue[700],
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                            if (group.description.isNotEmpty) ...[
                              const SizedBox(height: 4),
                              Text(
                                group.description,
                                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                      color: Colors.grey[600],
                                    ),
                              ),
                            ],
                          ],
                        ),
                      ),
                      if (!group.isDefault)
                        PopupMenuButton<String>(
                          onSelected: (action) {
                            switch (action) {
                              case 'edit':
                                _showAddEditDialog(group: group);
                                break;
                              case 'delete':
                                _deleteProjectGroup(group);
                                break;
                            }
                          },
                          itemBuilder: (context) => [
                            const PopupMenuItem(
                              value: 'edit',
                              child: Row(
                                children: [
                                  Icon(Icons.edit),
                                  SizedBox(width: 8),
                                  Text('编辑'),
                                ],
                              ),
                            ),
                            const PopupMenuItem(
                              value: 'delete',
                              child: Row(
                                children: [
                                  Icon(Icons.delete, color: Colors.red),
                                  SizedBox(width: 8),
                                  Text('删除', style: TextStyle(color: Colors.red)),
                                ],
                              ),
                            ),
                          ],
                        ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      _buildStatChip(
                        '总计',
                        stats['total'].toString(),
                        Colors.blue,
                      ),
                      const SizedBox(width: 8),
                      _buildStatChip(
                        '已完成',
                        stats['completed'].toString(),
                        Colors.green,
                      ),
                      const SizedBox(width: 8),
                      _buildStatChip(
                        '未完成',
                        stats['pending'].toString(),
                        Colors.orange,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildStatChip(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: color,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(width: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 12,
              color: color,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
