import 'package:flutter/material.dart';
import 'notification_service.dart';

/// 通知服务辅助类，用于安全地处理通知相关操作
class NotificationHelper {
  static final NotificationHelper _instance = NotificationHelper._internal();
  factory NotificationHelper() => _instance;
  NotificationHelper._internal();

  final NotificationService _notificationService = NotificationService();
  bool _isInitialized = false;
  bool get isInitialized => _isInitialized;

  /// 安全初始化通知服务
  Future<bool> safeInit() async {
    if (_isInitialized) {
      return true;
    }

    try {
      await _notificationService.init();
      _isInitialized = true;
      debugPrint('通知服务安全初始化成功');
      return true;
    } catch (e, stackTrace) {
      debugPrint('通知服务初始化失败: $e');
      debugPrint('初始化错误堆栈: $stackTrace');
      _isInitialized = false;
      return false;
    }
  }

  /// 安全请求权限
  Future<bool> safeRequestPermissions() async {
    try {
      if (!_isInitialized) {
        final initSuccess = await safeInit();
        if (!initSuccess) {
          return false;
        }
      }
      
      return await _notificationService.requestPermissions();
    } catch (e) {
      debugPrint('请求通知权限失败: $e');
      return false;
    }
  }

  /// 安全获取通知服务实例
  NotificationService? getService() {
    return _isInitialized ? _notificationService : null;
  }

  /// 检查通知功能是否可用
  Future<bool> isNotificationAvailable() async {
    try {
      if (!_isInitialized) {
        return await safeInit();
      }
      return true;
    } catch (e) {
      debugPrint('检查通知可用性失败: $e');
      return false;
    }
  }

  /// 安全测试通知
  Future<bool> safeTestNotification() async {
    try {
      if (!_isInitialized) {
        final initSuccess = await safeInit();
        if (!initSuccess) {
          return false;
        }
      }
      
      await _notificationService.testNotification();
      return true;
    } catch (e) {
      debugPrint('测试通知失败: $e');
      return false;
    }
  }

  /// 重置初始化状态（用于错误恢复）
  void reset() {
    _isInitialized = false;
    debugPrint('通知助手状态已重置');
  }
}
