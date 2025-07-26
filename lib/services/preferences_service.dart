import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 偏好设置服务，用于管理用户的偏好设置
class PreferencesService {
  static final PreferencesService _instance = PreferencesService._internal();
  factory PreferencesService() => _instance;
  PreferencesService._internal();

  late SharedPreferences _prefs;
  bool _isInitialized = false;

  /// 初始化偏好设置服务
  Future<void> init() async {
    if (_isInitialized) return;

    try {
      _prefs = await SharedPreferences.getInstance();
      _isInitialized = true;
    } catch (e) {
      debugPrint('偏好设置服务初始化失败: $e');
      rethrow;
    }
  }

  /// 确保服务已初始化
  Future<void> _ensureInitialized() async {
    if (!_isInitialized) {
      await init();
    }
  }

  // 键名常量
  static const String _keyFirstLaunch = 'first_launch';
  static const String _keyNotificationPermissionAsked =
      'notification_permission_asked';
  static const String _keyUsageGuideShown = 'usage_guide_shown';
  static const String _keyNotificationEnabled = 'notification_enabled';
  static const String _keyLastUsedDate = 'last_used_date';
  static const String _keyViewMode = 'view_mode'; // 新增：视图模式键

  /// 是否首次启动
  Future<bool> isFirstLaunch() async {
    await _ensureInitialized();
    return !(_prefs.getBool(_keyFirstLaunch) ?? false);
  }

  /// 设置首次启动状态
  Future<void> setFirstLaunch(bool isFirst) async {
    await _ensureInitialized();
    await _prefs.setBool(_keyFirstLaunch, !isFirst);
  }

  /// 是否已经询问过通知权限
  Future<bool> isNotificationPermissionAsked() async {
    await _ensureInitialized();
    return _prefs.getBool(_keyNotificationPermissionAsked) ?? false;
  }

  /// 设置通知权限询问状态
  Future<void> setNotificationPermissionAsked(bool asked) async {
    await _ensureInitialized();
    await _prefs.setBool(_keyNotificationPermissionAsked, asked);
  }

  /// 是否已经显示过使用说明
  Future<bool> isUsageGuideShown() async {
    await _ensureInitialized();
    return _prefs.getBool(_keyUsageGuideShown) ?? false;
  }

  /// 设置使用说明显示状态
  Future<void> setUsageGuideShown(bool shown) async {
    await _ensureInitialized();
    await _prefs.setBool(_keyUsageGuideShown, shown);
  }

  /// 通知是否已启用
  Future<bool> isNotificationEnabled() async {
    await _ensureInitialized();
    return _prefs.getBool(_keyNotificationEnabled) ?? false;
  }

  /// 设置通知启用状态
  Future<void> setNotificationEnabled(bool enabled) async {
    await _ensureInitialized();
    await _prefs.setBool(_keyNotificationEnabled, enabled);
  }

  /// 获取最后使用日期
  Future<String?> getLastUsedDate() async {
    await _ensureInitialized();
    return _prefs.getString(_keyLastUsedDate);
  }

  /// 设置最后使用日期
  Future<void> setLastUsedDate(String date) async {
    await _ensureInitialized();
    await _prefs.setString(_keyLastUsedDate, date);
  }

  /// 更新最后使用日期为今天
  Future<void> updateLastUsedDate() async {
    final today = DateTime.now().toIso8601String().split('T')[0];
    await setLastUsedDate(today);
  }

  /// 获取保存的视图模式
  Future<String?> getViewMode() async {
    await _ensureInitialized();
    return _prefs.getString(_keyViewMode);
  }

  /// 保存视图模式
  Future<void> setViewMode(String viewMode) async {
    await _ensureInitialized();
    await _prefs.setString(_keyViewMode, viewMode);
  }

  /// 清除所有偏好设置（用于调试或重置）
  Future<void> clearAll() async {
    await _ensureInitialized();
    await _prefs.clear();
  }

  /// 获取所有偏好设置（用于调试）
  Future<Map<String, dynamic>> getAllPreferences() async {
    await _ensureInitialized();
    final keys = _prefs.getKeys();
    final Map<String, dynamic> allPrefs = {};

    for (String key in keys) {
      final value = _prefs.get(key);
      allPrefs[key] = value;
    }

    return allPrefs;
  }
}
