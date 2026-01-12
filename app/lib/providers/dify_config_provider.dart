import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:teacher_tools/models/dify_config.dart';

/// Dify配置状态管理
class DifyConfigProvider extends ChangeNotifier {
  static const String _configKey = 'dify_config';

  DifyConfig? _config;
  bool _isLoading = false;

  DifyConfig? get config => _config;
  bool get isLoading => _isLoading;
  bool get isConfigured => _config?.isValid ?? false;

  /// 加载配置
  Future<void> loadConfig() async {
    _isLoading = true;
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      final configJson = prefs.getString(_configKey);

      if (configJson != null) {
        final json = jsonDecode(configJson) as Map<String, dynamic>;
        _config = DifyConfig.fromJson(json);
      }
    } catch (e) {
      debugPrint('加载Dify配置失败: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// 保存配置
  Future<bool> saveConfig(DifyConfig config) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final configJson = jsonEncode(config.toJson());
      await prefs.setString(_configKey, configJson);

      _config = config;
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('保存Dify配置失败: $e');
      return false;
    }
  }

  /// 清除配置
  Future<bool> clearConfig() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_configKey);

      _config = null;
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('清除Dify配置失败: $e');
      return false;
    }
  }

  /// 更新配置
  Future<bool> updateConfig({
    String? host,
    String? token,
  }) async {
    if (_config == null) {
      debugPrint('未找到现有配置');
      return false;
    }

    final updatedConfig = _config!.copyWith(
      host: host,
      token: token,
    );

    return await saveConfig(updatedConfig);
  }
}
