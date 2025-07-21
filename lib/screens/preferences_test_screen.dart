import 'package:flutter/material.dart';
import '../services/preferences_service.dart';

/// 用于测试和调试偏好设置的页面
class PreferencesTestScreen extends StatefulWidget {
  const PreferencesTestScreen({super.key});

  @override
  State<PreferencesTestScreen> createState() => _PreferencesTestScreenState();
}

class _PreferencesTestScreenState extends State<PreferencesTestScreen> {
  final PreferencesService _preferencesService = PreferencesService();
  Map<String, dynamic> _preferences = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadPreferences();
  }

  Future<void> _loadPreferences() async {
    setState(() => _isLoading = true);
    try {
      final prefs = await _preferencesService.getAllPreferences();
      setState(() {
        _preferences = prefs;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('加载偏好设置失败: $e')),
        );
      }
    }
  }

  Future<void> _resetPreferences() async {
    try {
      await _preferencesService.clearAll();
      await _loadPreferences();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('偏好设置已重置')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('重置失败: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('偏好设置调试'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadPreferences,
          ),
          IconButton(
            icon: const Icon(Icons.clear),
            onPressed: _resetPreferences,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '当前偏好设置:',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Expanded(
                    child: _preferences.isEmpty
                        ? const Center(
                            child: Text('没有找到偏好设置'))
                        : ListView.builder(
                            itemCount: _preferences.length,
                            itemBuilder: (context, index) {
                              final key = _preferences.keys.elementAt(index);
                              final value = _preferences[key];
                              return Card(
                                child: ListTile(
                                  title: Text(key),
                                  subtitle: Text('$value'),
                                  trailing: Text(value.runtimeType.toString()),
                                ),
                              );
                            },
                          ),
                  ),
                ],
              ),
            ),
    );
  }
}
