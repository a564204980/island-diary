import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 全局单例用户状态管理
/// 采用轻量级的 ValueNotifier 实现，方便跨组件监听
class UserState {
  static final UserState _instance = UserState._internal();
  factory UserState() => _instance;
  UserState._internal();

  static const _keyUserName = 'user_name';

  /// 用户的姓名（游戏内称呼）
  final ValueNotifier<String> userName = ValueNotifier<String>('');

  /// 更新用户名称并持久化到本地
  Future<void> setUserName(String name) async {
    final trimmed = name.trim();
    if (trimmed.isNotEmpty) {
      userName.value = trimmed;
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_keyUserName, trimmed);
    }
  }

  /// 从本地存储中读取用户名称，返回 null 表示第一次启动
  Future<String?> loadFromStorage() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString(_keyUserName);
    if (saved != null && saved.isNotEmpty) {
      userName.value = saved;
    }
    return saved?.isEmpty == false ? saved : null;
  }

  void dispose() {
    userName.dispose();
  }
}
