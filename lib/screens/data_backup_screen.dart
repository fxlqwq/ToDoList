import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';
import 'package:intl/intl.dart';
import 'package:path/path.dart' as path;
import '../models/project_group.dart';
import '../services/data_export_service.dart';
import '../services/database_service.dart';
import '../services/todo_provider.dart';

class DataBackupScreen extends StatefulWidget {
  const DataBackupScreen({super.key});

  @override
  State<DataBackupScreen> createState() => _DataBackupScreenState();
}

class _DataBackupScreenState extends State<DataBackupScreen> {
  final DataExportService _exportService = DataExportService();
  final DatabaseService _databaseService = DatabaseService();
  
  List<ProjectGroup> _projectGroups = [];
  List<FileSystemEntity> _backupFiles = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    
    try {
      final groups = await _databaseService.getAllProjectGroups();
      final files = await _exportService.getBackupFiles();
      
      setState(() {
        _projectGroups = groups;
        _backupFiles = files;
      });
    } catch (e) {
      _showSnackBar('加载数据失败: $e', isError: true);
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

  Future<void> _exportAllData() async {
    try {
      setState(() => _isLoading = true);
      final filePath = await _exportService.exportAllData();
      await _loadData(); // Refresh file list
      _showSnackBar('全部数据导出成功: $filePath');
    } catch (e) {
      _showSnackBar('导出失败: $e', isError: true);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _exportProjectGroup(ProjectGroup group) async {
    try {
      setState(() => _isLoading = true);
      final filePath = await _exportService.exportProjectGroupData(group.id!);
      await _loadData(); // Refresh file list
      _showSnackBar('项目组 "${group.name}" 导出成功: $filePath');
    } catch (e) {
      _showSnackBar('导出失败: $e', isError: true);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _restoreBackup(String backupPath) async {
    try {
      // 显示确认对话框
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('确认恢复'),
          content: const Text('恢复备份将覆盖当前所有数据，此操作不可撤销。您确定要继续吗？'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('取消'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              child: const Text('确认恢复'),
            ),
          ],
        ),
      );

      if (confirmed != true) return;

      setState(() => _isLoading = true);
      
      // 使用新的 ZIP 导入功能
      await _exportService.importAllData(backupPath);
      
      // 刷新数据
      if (mounted) {
        final todoProvider = context.read<TodoProvider>();
        await todoProvider.loadProjectGroups();
        await todoProvider.loadTodos();
        await _loadData();
      }
      
      _showSnackBar('备份恢复成功');
    } catch (e) {
      _showSnackBar('恢复失败: $e', isError: true);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _importData() async {
    try {
      print('🔥 BackupScreen: 开始导入数据流程');
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['zip', 'json'], // 支持新的 ZIP 格式和旧的 JSON 格式
      );

      if (result != null && result.files.single.path != null) {
        print('🔥 BackupScreen: 文件选择成功: ${result.files.single.path}');
        setState(() => _isLoading = true);
        
        final filePath = result.files.single.path!;
        print('🔥 BackupScreen: 开始调用导入服务');
        final success = await _exportService.importAllData(filePath);
        print('🔥 BackupScreen: 导入服务返回结果: $success');
        
        if (success) {
          print('🔥 BackupScreen: 导入成功，开始刷新数据');
          // Refresh the todo provider
          if (mounted) {
            final todoProvider = context.read<TodoProvider>();
            await todoProvider.loadProjectGroups();
            print('🔥 BackupScreen: 项目组加载完成');
            await todoProvider.loadTodos();
            print('🔥 BackupScreen: 任务加载完成');
            await _loadData(); // 刷新备份文件列表
            print('🔥 BackupScreen: 备份文件列表刷新完成');
          }
          
          _showSnackBar('数据导入成功');
        } else {
          print('🔥 BackupScreen: 导入失败');
          _showSnackBar('数据导入失败', isError: true);
        }
      } else {
        print('🔥 BackupScreen: 用户取消文件选择');
      }
    } catch (e, stackTrace) {
      print('🔥 BackupScreen: 导入异常: $e');
      print('🔥 BackupScreen: 堆栈跟踪: $stackTrace');
      _showSnackBar('导入失败: $e', isError: true);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _importProjectData() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['zip', 'json'], // 支持新的 ZIP 格式和旧的 JSON 格式
      );

      if (result != null && result.files.single.path != null) {
        setState(() => _isLoading = true);
        
        final filePath = result.files.single.path!;
        await _exportService.importProjectGroupData(filePath);
        
        // Refresh the todo provider and data
        if (mounted) {
          final todoProvider = context.read<TodoProvider>();
          await todoProvider.loadProjectGroups();
          await todoProvider.loadTodos();
          await _loadData(); // 刷新备份文件列表
        }
        
        _showSnackBar('项目数据导入成功');
      }
    } catch (e) {
      _showSnackBar('导入失败: $e', isError: true);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _deleteBackupFile(String filePath) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('确认删除'),
        content: const Text('确定要删除这个备份文件吗？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('删除'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await _exportService.deleteBackupFile(filePath);
        await _loadData(); // Refresh file list
        _showSnackBar('备份文件删除成功');
      } catch (e) {
        _showSnackBar('删除失败: $e', isError: true);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('数据备份管理'),
        elevation: 0,
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildExportSection(),
                  const SizedBox(height: 24),
                  _buildImportSection(),
                  const SizedBox(height: 24),
                  _buildBackupFilesSection(),
                ],
              ),
            ),
    );
  }

  Widget _buildExportSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.upload,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  '导出数据',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _exportAllData,
              icon: const Icon(Icons.backup),
              label: const Text('导出全部数据'),
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 48),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              '导出各项目组：',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            ..._projectGroups.map((group) => Padding(
                  padding: const EdgeInsets.only(bottom: 8.0),
                  child: OutlinedButton.icon(
                    onPressed: () => _exportProjectGroup(group),
                    icon: Icon(
                      Icons.folder,
                      color: Color(group.colorCode),
                    ),
                    label: Text(
                      group.name,
                      style: TextStyle(color: Color(group.colorCode)),
                    ),
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size(double.infinity, 40),
                      side: BorderSide(color: Color(group.colorCode)),
                    ),
                  ),
                )),
          ],
        ),
      ),
    );
  }

  Widget _buildImportSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.download,
                  color: Theme.of(context).colorScheme.secondary,
                ),
                const SizedBox(width: 8),
                Text(
                  '导入数据',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _importData,
              icon: const Icon(Icons.restore),
              label: const Text('导入全部数据'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.secondary,
                minimumSize: const Size(double.infinity, 48),
              ),
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: _importProjectData,
              icon: const Icon(Icons.folder_open),
              label: const Text('导入项目数据'),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size(double.infinity, 40),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBackupFilesSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.folder,
                  color: Theme.of(context).colorScheme.tertiary,
                ),
                const SizedBox(width: 8),
                Text(
                  '备份文件',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const Spacer(),
                IconButton(
                  onPressed: _loadData,
                  icon: const Icon(Icons.refresh),
                  tooltip: '刷新',
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (_backupFiles.isEmpty)
              Center(
                child: Column(
                  children: [
                    Icon(
                      Icons.folder_open,
                      size: 64,
                      color: Colors.grey[400],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '暂无备份文件',
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            color: Colors.grey[600],
                          ),
                    ),
                  ],
                ),
              )
            else
              ..._backupFiles.map((file) => _buildBackupFileItem(file)),
          ],
        ),
      ),
    );
  }

  Widget _buildBackupFileItem(FileSystemEntity file) {
    return FutureBuilder<Map<String, dynamic>>(
      future: _exportService.getBackupFileInfo(file.path),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return Card(
            margin: const EdgeInsets.only(bottom: 8.0),
            child: ListTile(
              leading: Icon(
                Icons.backup,
                color: Theme.of(context).colorScheme.secondary,
              ),
              title: Text(path.basename(file.path)),
              subtitle: const Text('正在加载...'),
            ),
          );
        }

        final fileInfo = snapshot.data!;
        final size = fileInfo['size'] as int;
        final modified = fileInfo['modified'] as DateTime;
        final isProjectSpecific = fileInfo['isProjectSpecific'] as bool;

        return Card(
          margin: const EdgeInsets.only(bottom: 8.0),
          child: ListTile(
            leading: Icon(
              isProjectSpecific ? Icons.folder : Icons.backup,
              color: isProjectSpecific 
                  ? Theme.of(context).colorScheme.primary
                  : Theme.of(context).colorScheme.secondary,
            ),
            title: Text(
              fileInfo['name'],
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
            subtitle: Text(
              '${_formatFileSize(size)} • ${DateFormat('yyyy-MM-dd HH:mm').format(modified)}',
            ),
            trailing: PopupMenuButton<String>(
              onSelected: (action) {
                switch (action) {
                  case 'delete':
                    _deleteBackupFile(fileInfo['path']);
                    break;
                }
              },
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'delete',
                  child: Row(
                    children: [
                      Icon(Icons.delete, color: Colors.red),
                      SizedBox(width: 8),
                      Text('删除'),
                    ],
                  ),
                ),
              ],
            ),
            onTap: () => _restoreBackup(fileInfo['path']),
          ),
        );
      },
    );
  }

  String _formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) {
      return '${(bytes / 1024).toStringAsFixed(1)} KB';
    }
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }
}
