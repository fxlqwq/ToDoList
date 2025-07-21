import 'package:flutter/material.dart';
import '../services/notification_helper.dart';

/// 通知测试页面，用于测试和验证通知功能
class NotificationTestScreen extends StatefulWidget {
  const NotificationTestScreen({super.key});

  @override
  State<NotificationTestScreen> createState() => _NotificationTestScreenState();
}

class _NotificationTestScreenState extends State<NotificationTestScreen> {
  final NotificationHelper _notificationHelper = NotificationHelper();
  String _status = '通知服务状态：未知';
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _checkNotificationStatus();
  }

  Future<void> _checkNotificationStatus() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final isAvailable = await _notificationHelper.isNotificationAvailable();
      setState(() {
        _status = '通知服务状态：${isAvailable ? '可用' : '不可用'}';
      });
    } catch (e) {
      setState(() {
        _status = '检查通知状态时出错: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _testNotification() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final success = await _notificationHelper.safeTestNotification();
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(success ? '测试通知发送成功！' : '测试通知发送失败'),
          backgroundColor: success ? Colors.green : Colors.red,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('测试通知时出错: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _requestPermissions() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final granted = await _notificationHelper.safeRequestPermissions();
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(granted ? '权限已授予！' : '权限授予失败'),
          backgroundColor: granted ? Colors.green : Colors.red,
        ),
      );
      
      await _checkNotificationStatus();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('请求权限时出错: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('通知功能测试'),
        backgroundColor: Colors.blue,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '通知状态',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(_status),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: _isLoading ? null : _checkNotificationStatus,
                      child: const Text('刷新状态'),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '测试功能',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: _isLoading ? null : _requestPermissions,
                      child: const Text('请求通知权限'),
                    ),
                    const SizedBox(height: 8),
                    ElevatedButton(
                      onPressed: _isLoading ? null : _testNotification,
                      child: const Text('发送测试通知'),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            if (_isLoading)
              const Center(
                child: CircularProgressIndicator(),
              ),
          ],
        ),
      ),
    );
  }
}
