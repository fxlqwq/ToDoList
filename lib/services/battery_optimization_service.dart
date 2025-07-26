import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart';

/// 电池优化权限管理服务
class BatteryOptimizationService {
  static final BatteryOptimizationService _instance = BatteryOptimizationService._internal();
  factory BatteryOptimizationService() => _instance;
  BatteryOptimizationService._internal();

  static const MethodChannel _channel = MethodChannel('battery_optimization');

  /// 检查是否忽略电池优化
  Future<bool> isIgnoringBatteryOptimizations() async {
    try {
      final bool? result = await _channel.invokeMethod('isIgnoringBatteryOptimizations');
      return result ?? false;
    } catch (e) {
      debugPrint('检查电池优化状态失败: $e');
      return false;
    }
  }

  /// 请求忽略电池优化权限
  Future<bool> requestIgnoreBatteryOptimizations(BuildContext context) async {
    try {
      // 先检查是否已经忽略了电池优化
      final bool isIgnoring = await isIgnoringBatteryOptimizations();
      if (isIgnoring) {
        return true;
      }

      // 显示说明对话框
      if (!context.mounted) return false;
      final bool? userConfirmed = await _showBatteryOptimizationDialog(context);
      if (userConfirmed != true) {
        return false;
      }

      // 请求权限
      final bool? result = await _channel.invokeMethod('requestIgnoreBatteryOptimizations');
      return result ?? false;
    } catch (e) {
      debugPrint('请求电池优化权限失败: $e');
      return false;
    }
  }

  /// 显示电池优化权限说明对话框
  Future<bool?> _showBatteryOptimizationDialog(BuildContext context) {
    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.orange.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.battery_saver,
                  color: Colors.orange,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  '允许应用始终在后台运行？',
                  style: TextStyle(fontSize: 18),
                ),
              ),
            ],
          ),
          content: const Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '允许"待办事件-FXL"始终在后台运行可能会缩短电池的续航时间。',
                style: TextStyle(fontSize: 16),
              ),
              SizedBox(height: 12),
              Text(
                '您以后可以在"设置">"应用和通知"中更改此设置。',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey,
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('拒绝'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
              ),
              child: const Text('允许'),
            ),
          ],
        );
      },
    );
  }

  /// 检查通知权限
  Future<bool> checkNotificationPermission() async {
    try {
      final status = await Permission.notification.status;
      return status.isGranted;
    } catch (e) {
      debugPrint('检查通知权限失败: $e');
      return false;
    }
  }

  /// 请求通知权限
  Future<bool> requestNotificationPermission() async {
    try {
      final status = await Permission.notification.request();
      return status.isGranted;
    } catch (e) {
      debugPrint('请求通知权限失败: $e');
      return false;
    }
  }

  /// 检查精确闹钟权限（Android 12+）
  Future<bool> checkScheduleExactAlarmPermission() async {
    try {
      final status = await Permission.scheduleExactAlarm.status;
      return status.isGranted;
    } catch (e) {
      debugPrint('检查精确闹钟权限失败: $e');
      return false;
    }
  }

  /// 请求精确闹钟权限
  Future<bool> requestScheduleExactAlarmPermission() async {
    try {
      final status = await Permission.scheduleExactAlarm.request();
      return status.isGranted;
    } catch (e) {
      debugPrint('请求精确闹钟权限失败: $e');
      return false;
    }
  }

  /// 一次性请求所有必要权限
  Future<Map<String, bool>> requestAllPermissions(BuildContext context) async {
    final Map<String, bool> results = {};

    // 1. 请求通知权限
    results['notification'] = await requestNotificationPermission();

    // 2. 请求精确闹钟权限
    results['scheduleExactAlarm'] = await requestScheduleExactAlarmPermission();

    // 3. 请求电池优化豁免
    if (context.mounted) {
      results['batteryOptimization'] = await requestIgnoreBatteryOptimizations(context);
    } else {
      results['batteryOptimization'] = false;
    }

    return results;
  }
}
