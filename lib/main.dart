import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'services/todo_provider.dart';
import 'services/database_service.dart';
import 'services/notification_helper.dart';
import 'services/preferences_service.dart';
import 'screens/splash_screen.dart';
import 'utils/app_theme.dart';
import 'dart:ui';

void main() async {
  // 添加全局错误处理
  FlutterError.onError = (FlutterErrorDetails details) {
    debugPrint('Flutter Error: ${details.exception}');
    debugPrint('Stack trace: ${details.stack}');
    // 在生产环境中可以将错误发送到崩溃报告服务
  };
  
  // 捕获异步错误
  PlatformDispatcher.instance.onError = (error, stack) {
    debugPrint('Uncaught async error: $error');
    debugPrint('Stack trace: $stack');
    return true; // 表示错误已处理，防止崩溃
  };
  
  try {
    WidgetsFlutterBinding.ensureInitialized();
    
    // Initialize services with error handling
    bool databaseInitialized = false;
    bool notificationInitialized = false;
    bool preferencesInitialized = false;
    
    try {
      final databaseService = DatabaseService();
      await databaseService.init();
      databaseInitialized = true;
      debugPrint('Database initialized successfully');
    } catch (e, stackTrace) {
      debugPrint('Database initialization error: $e');
      debugPrint('Database error stack trace: $stackTrace');
      // Continue without database - app will work in read-only mode
      databaseInitialized = false;
    }

    try {
      // Initialize preferences service
      final preferencesService = PreferencesService();
      await preferencesService.init();
      preferencesInitialized = true;
      debugPrint('Preferences service initialized successfully');
    } catch (e, stackTrace) {
      debugPrint('Preferences service initialization error: $e');
      debugPrint('Preferences error stack trace: $stackTrace');
      preferencesInitialized = false;
    }

    try {
      // Initialize notification service
      final notificationHelper = NotificationHelper();
      notificationInitialized = await notificationHelper.safeInit();
      debugPrint('Notification service initialization result: $notificationInitialized');
      
    } catch (e, stackTrace) {
      debugPrint('Notification service initialization error: $e');
      debugPrint('Notification error stack trace: $stackTrace');
      notificationInitialized = false;
      // Continue without notifications for now
    }
    
    debugPrint('App initialization complete - Database: $databaseInitialized, Notifications: $notificationInitialized, Preferences: $preferencesInitialized');
    
    runApp(MyApp(
      databaseInitialized: databaseInitialized,
      notificationInitialized: notificationInitialized,
    ));
    
  } catch (e, stackTrace) {
    debugPrint('Critical app initialization error: $e');
    debugPrint('Stack trace: $stackTrace');
    // Run app anyway with basic functionality
    runApp(MaterialApp(
      home: Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error, size: 64, color: Colors.red),
              const SizedBox(height: 16),
              const Text('应用初始化失败', 
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text('错误信息: $e', 
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 14)),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  // Try to restart
                  main();
                },
                child: const Text('重试'),
              ),
            ],
          ),
        ),
      ),
    ));
  }
}

class MyApp extends StatelessWidget {
  final bool databaseInitialized;
  final bool notificationInitialized;
  
  const MyApp({
    super.key, 
    this.databaseInitialized = true,
    this.notificationInitialized = true,
  });

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) {
        try {
          final provider = TodoProvider();
          // Load todos safely only if database is initialized
          if (databaseInitialized) {
            provider.loadTodos().catchError((error) {
              debugPrint('Error loading todos in provider: $error');
              return null;
            });
          }
          return provider;
        } catch (e) {
          debugPrint('Error creating TodoProvider: $e');
          // Return a basic provider
          return TodoProvider();
        }
      },
      child: MaterialApp(
        title: 'Todo List',
        theme: AppTheme.lightTheme,
        home: const SafeArea(child: SplashScreen()),
        debugShowCheckedModeBanner: false,
        // Add error handling
        builder: (context, widget) {
          // 捕获和处理widget构建错误
          ErrorWidget.builder = (FlutterErrorDetails errorDetails) {
            debugPrint('Widget构建错误: ${errorDetails.exception}');
            debugPrint('错误堆栈: ${errorDetails.stack}');
            
            return Scaffold(
              body: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error_outline, color: Colors.red, size: 48),
                    const SizedBox(height: 16),
                    const Text('页面加载出现问题', 
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Text('${errorDetails.exception}', 
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontSize: 14)),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () {
                        // 尝试重新构建
                        Navigator.of(context).pushReplacement(
                          MaterialPageRoute(builder: (context) => const SafeArea(child: SplashScreen())),
                        );
                      },
                      child: const Text('重新加载'),
                    ),
                  ],
                ),
              ),
            );
          };
          return widget ?? const SizedBox.shrink();
        },
      ),
    );
  }
}

