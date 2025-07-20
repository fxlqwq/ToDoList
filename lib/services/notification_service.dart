import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart' hide Priority;
import 'package:flutter_local_notifications/flutter_local_notifications.dart' as fln;
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;
import '../models/todo.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  Future<void> init() async {
    try {
      // Initialize timezone with error handling
      try {
        tz.initializeTimeZones();
        print('时区初始化成功'); // 在Release版本中使用print替代debugPrint
      } catch (e) {
        print('时区初始化失败: $e');
        // Continue with system default timezone
      }
      
      const AndroidInitializationSettings initializationSettingsAndroid =
          AndroidInitializationSettings('@mipmap/ic_launcher');

      const InitializationSettings initializationSettings =
          InitializationSettings(
        android: initializationSettingsAndroid,
      );

      bool? initialized = await flutterLocalNotificationsPlugin.initialize(
        initializationSettings,
        onDidReceiveNotificationResponse: (NotificationResponse response) async {
          // 安全的通知响应处理，防止崩溃
          try {
            print('通知被点击: ${response.payload}');
            // 添加空检查
            if (response.payload != null && response.payload!.isNotEmpty) {
              // 可以在这里添加导航到特定任务的逻辑
              print('处理通知载荷: ${response.payload}');
            }
          } catch (e, stackTrace) {
            print('处理通知点击失败: $e');
            print('堆栈跟踪: $stackTrace');
            // 防止崩溃，静默处理错误
          }
        },
      );

      print('通知服务初始化结果: $initialized');

      // Request permissions for Android 13+ with error handling
      try {
        final permissionGranted = await requestPermissions();
        print('通知权限获取结果: $permissionGranted');
      } catch (e) {
        print('权限请求过程中出错: $e');
        // 继续执行，不让权限问题阻止应用运行
      }
      
    } catch (e, stackTrace) {
      print('通知服务初始化失败: $e');
      print('初始化错误堆栈跟踪: $stackTrace');
      // Continue without crashing the app
    }
  }

  Future<bool> requestPermissions() async {
    try {
      final AndroidFlutterLocalNotificationsPlugin? androidImplementation =
          flutterLocalNotificationsPlugin.resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>();

      if (androidImplementation != null) {
        final bool? exactAlarmGranted = await androidImplementation.requestExactAlarmsPermission();
        final bool? notificationGranted = await androidImplementation.requestNotificationsPermission();
        
        debugPrint('精确闹钟权限: $exactAlarmGranted');
        debugPrint('通知权限: $notificationGranted');
        
        return notificationGranted ?? false;
      }
      return false;
    } catch (e) {
      debugPrint('权限请求失败: $e');
      return false;
    }
  }

  // Schedule notification for a todo
  Future<void> scheduleNotification(Todo todo) async {
    try {
      // 使用新的安全检查方法
      if (!todo.hasValidReminder) {
        debugPrint('任务不需要提醒或提醒时间无效: ${todo.title}');
        return;
      }

      final safeReminderTime = todo.safeReminderDate;
      if (safeReminderTime == null) {
        debugPrint('无法获取安全的提醒时间: ${todo.title}');
        return;
      }

      // 先取消已存在的通知，确保不会重复
      try {
        await cancelNotification(todo.id ?? 0);
      } catch (e) {
        debugPrint('取消现有通知时出错: $e');
        // 继续执行
      }

      const AndroidNotificationDetails androidPlatformChannelSpecifics =
          AndroidNotificationDetails(
        'todo_reminders',
        '待办事项提醒',
        channelDescription: '待办事项的提醒通知',
        importance: Importance.high, // 改为high而不是max
        priority: fln.Priority.high,
        icon: '@mipmap/ic_launcher',
        enableLights: true,
        enableVibration: true,
        playSound: true,
        autoCancel: true, // 改为true
        ongoing: false,
        showWhen: true,
        channelShowBadge: true,
      );

      const NotificationDetails platformChannelSpecifics =
          NotificationDetails(android: androidPlatformChannelSpecifics);

      // 更安全的时区处理
      DateTime targetTime = safeReminderTime;
      tz.TZDateTime scheduledTime;
      
      try {
        scheduledTime = tz.TZDateTime.from(targetTime, tz.local);
      } catch (e) {
        debugPrint('时区转换失败，使用UTC时间: $e');
        try {
          scheduledTime = tz.TZDateTime.utc(
            targetTime.year,
            targetTime.month, 
            targetTime.day,
            targetTime.hour,
            targetTime.minute,
            targetTime.second,
          );
        } catch (e2) {
          debugPrint('UTC时间转换也失败: $e2');
          return; // 放弃这个通知
        }
      }
      
      debugPrint('正在安排通知: ${todo.title}');
      debugPrint('原始提醒时间: $safeReminderTime');
      debugPrint('转换后时区时间: $scheduledTime');
      debugPrint('当前时间: ${DateTime.now()}');

      // 确保时间在未来，添加额外的时间检查
      final nowTz = tz.TZDateTime.now(tz.local);
      if (scheduledTime.isAfter(nowTz)) {
        try {
          await flutterLocalNotificationsPlugin.zonedSchedule(
            todo.id ?? 0,
            '✅ 待办提醒',
            '${todo.title}${todo.description.isNotEmpty ? '\n${todo.description}' : ''}',
            scheduledTime,
            platformChannelSpecifics,
            payload: todo.id.toString(),
            uiLocalNotificationDateInterpretation:
                UILocalNotificationDateInterpretation.absoluteTime,
            matchDateTimeComponents: DateTimeComponents.dateAndTime,
            androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
          );
          
          debugPrint('通知已安排成功: ID ${todo.id}');
        } catch (schedulingError) {
          debugPrint('通知调度失败: $schedulingError');
          // 尝试备用调度方法
          try {
            await flutterLocalNotificationsPlugin.zonedSchedule(
              todo.id ?? 0,
              '✅ 待办提醒',
              todo.title,
              scheduledTime,
              platformChannelSpecifics,
              payload: todo.id.toString(),
              uiLocalNotificationDateInterpretation:
                  UILocalNotificationDateInterpretation.absoluteTime,
              androidScheduleMode: AndroidScheduleMode.alarmClock,
            );
            debugPrint('使用备用方法成功安排通知: ID ${todo.id}');
          } catch (backupError) {
            debugPrint('备用通知调度也失败: $backupError');
          }
        }
      } else {
        debugPrint('调度时间不在未来，跳过通知: ${todo.title}');
      }
    } catch (e, stackTrace) {
      debugPrint('安排通知时发生严重错误: $e');
      debugPrint('错误堆栈跟踪: $stackTrace');
      // 不要让通知失败导致应用崩溃
    }
  }

  // Schedule daily summary notification
  Future<void> scheduleDailySummary(int pendingCount, int overdueCount) async {
    try {
      if (pendingCount == 0 && overdueCount == 0) return;

      const AndroidNotificationDetails androidPlatformChannelSpecifics =
          AndroidNotificationDetails(
        'daily_summary',
        '每日总结',
        channelDescription: '每日待办事项总结通知',
        importance: Importance.defaultImportance,
        priority: fln.Priority.defaultPriority,
        icon: '@mipmap/ic_launcher',
        autoCancel: true,
        showWhen: true,
      );

      const NotificationDetails platformChannelSpecifics =
          NotificationDetails(android: androidPlatformChannelSpecifics);

      String message = '';
      if (pendingCount > 0 && overdueCount > 0) {
        message = '您有 $pendingCount 个待办任务和 $overdueCount 个逾期任务。';
      } else if (pendingCount > 0) {
        message = '您今天有 $pendingCount 个待办任务。';
      } else {
        message = '您有 $overdueCount 个逾期任务。';
      }

      // Schedule for 9 AM daily
      final now = DateTime.now();
      var scheduledDate = DateTime(now.year, now.month, now.day, 9, 0);
      
      if (scheduledDate.isBefore(now)) {
        scheduledDate = scheduledDate.add(const Duration(days: 1));
      }

      tz.TZDateTime scheduledTime;
      try {
        scheduledTime = tz.TZDateTime.from(scheduledDate, tz.local);
      } catch (e) {
        debugPrint('每日总结时区转换失败: $e');
        return; // 放弃调度
      }

      // 确保时间在未来
      if (scheduledTime.isAfter(tz.TZDateTime.now(tz.local))) {
        try {
          await flutterLocalNotificationsPlugin.zonedSchedule(
            9999, // Special ID for daily summary
            '📊 每日待办总结',
            message,
            scheduledTime,
            platformChannelSpecifics,
            uiLocalNotificationDateInterpretation:
                UILocalNotificationDateInterpretation.absoluteTime,
            matchDateTimeComponents: DateTimeComponents.time,
            androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
          );

          debugPrint('每日总结通知已安排');
        } catch (e) {
          debugPrint('安排每日总结通知调度失败: $e');
        }
      } else {
        debugPrint('每日总结时间不在未来，跳过安排');
      }
    } catch (e, stackTrace) {
      debugPrint('安排每日总结通知失败: $e');
      debugPrint('每日总结错误堆栈跟踪: $stackTrace');
      // 不让失败影响应用运行
    }
  }

  // Show immediate notification
  Future<void> showNotification({
    required int id,
    required String title,
    required String body,
    String? payload,
  }) async {
    try {
      const AndroidNotificationDetails androidPlatformChannelSpecifics =
          AndroidNotificationDetails(
        'immediate_notifications',
        '即时通知',
        channelDescription: '即时待办事项通知',
        importance: Importance.high,
        priority: fln.Priority.high,
        icon: '@mipmap/ic_launcher',
        enableVibration: true,
        playSound: true,
      );

      const NotificationDetails platformChannelSpecifics =
          NotificationDetails(android: androidPlatformChannelSpecifics);

      await flutterLocalNotificationsPlugin.show(
        id,
        title,
        body,
        platformChannelSpecifics,
        payload: payload,
      );

      debugPrint('即时通知已发送: $title');
    } catch (e) {
      debugPrint('发送即时通知失败: $e');
    }
  }

  // Cancel a specific notification
  Future<void> cancelNotification(int id) async {
    try {
      await flutterLocalNotificationsPlugin.cancel(id);
      debugPrint('已取消通知: ID $id');
    } catch (e) {
      debugPrint('取消通知失败: $e');
    }
  }

  // Cancel all notifications
  Future<void> cancelAllNotifications() async {
    try {
      await flutterLocalNotificationsPlugin.cancelAll();
      debugPrint('已取消所有通知');
    } catch (e) {
      debugPrint('取消所有通知失败: $e');
    }
  }

  // Get pending notifications
  Future<List<PendingNotificationRequest>> getPendingNotifications() async {
    try {
      final pendingNotifications = await flutterLocalNotificationsPlugin.pendingNotificationRequests();
      debugPrint('待处理通知数量: ${pendingNotifications.length}');
      return pendingNotifications;
    } catch (e) {
      debugPrint('获取待处理通知失败: $e');
      return [];
    }
  }

  // Test notification - for debugging
  Future<void> testNotification() async {
    await showNotification(
      id: 99999,
      title: '🔔 通知测试',
      body: '如果您看到这条通知，说明通知功能正常工作！',
      payload: 'test',
    );
  }
}