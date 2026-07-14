import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'island_plugin.dart';

class PluginManager extends ChangeNotifier {
  // 单例模式
  PluginManager._privateConstructor();
  static final PluginManager _instance = PluginManager._privateConstructor();
  static PluginManager get instance => _instance;

  // 系统中所有已注册（代码中预埋）的可用插件实例
  final Map<String, IslandPlugin> _registeredPlugins = {};

  // 用户已“下载/安装”的插件 ID
  final Set<String> _installedPluginIds = {};

  // 当前针对特定 Category 激活的插件 ID
  final Map<PluginCategory, String> _activePluginIds = {};

  /// 初始化并从本地存储加载状态
  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    
    final installedList = prefs.getStringList('pm_installed_plugins') ?? [];
    _installedPluginIds.addAll(installedList);

    final activePluginsJson = prefs.getString('pm_active_plugins');
    if (activePluginsJson != null) {
      try {
        final Map<String, dynamic> decoded = jsonDecode(activePluginsJson);
        for (var entry in decoded.entries) {
          final categoryStr = entry.key;
          final pluginId = entry.value as String;
          // 查找对应的 Category enum
          final category = PluginCategory.values.firstWhere(
            (e) => e.toString() == categoryStr,
            orElse: () => PluginCategory.camera, // 默认 fallback
          );
          _activePluginIds[category] = pluginId;
        }
      } catch (e) {
        debugPrint('Failed to load active plugins: $e');
      }
    }
  }

  /// 保存状态到本地
  Future<void> _saveState() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('pm_installed_plugins', _installedPluginIds.toList());
    
    final Map<String, String> activePluginsToSave = {};
    _activePluginIds.forEach((category, pluginId) {
      activePluginsToSave[category.toString()] = pluginId;
    });
    await prefs.setString('pm_active_plugins', jsonEncode(activePluginsToSave));
  }

  /// 注册插件到系统 (App 启动时调用)
  void registerPlugin(IslandPlugin plugin) {
    _registeredPlugins[plugin.pluginId] = plugin;
  }

  /// 获取某分类下当前激活的插件
  T? getActivePlugin<T extends IslandPlugin>(PluginCategory category) {
    final activeId = _activePluginIds[category];
    if (activeId == null) return null;
    final plugin = _registeredPlugins[activeId];
    if (plugin is T) return plugin;
    return null;
  }

  /// 获取系统所有已知插件（模拟从云端获取的商店列表）
  List<IslandPlugin> getAllAvailablePlugins() {
    return _registeredPlugins.values.toList();
  }

  /// 检查插件是否已安装
  bool isPluginInstalled(String pluginId) {
    return _installedPluginIds.contains(pluginId);
  }

  /// 检查插件是否已激活
  bool isPluginActive(String pluginId) {
    final plugin = _registeredPlugins[pluginId];
    if (plugin == null) return false;
    return _activePluginIds[plugin.category] == pluginId;
  }

  /// 模拟下载/安装插件
  Future<void> installPlugin(String pluginId) async {
    final plugin = _registeredPlugins[pluginId];
    if (plugin == null) return;
    
    // 模拟云端下载素材耗时
    await Future.delayed(const Duration(seconds: 2));
    await plugin.onInstall();
    
    _installedPluginIds.add(pluginId);
    await _saveState();
    notifyListeners();
  }

  /// 激活插件
  Future<void> enablePlugin(String pluginId) async {
    if (!isPluginInstalled(pluginId)) return;
    final plugin = _registeredPlugins[pluginId];
    if (plugin == null) return;

    final currentActiveId = _activePluginIds[plugin.category];
    if (currentActiveId != null && currentActiveId != pluginId) {
      // 禁用之前的插件
      await _registeredPlugins[currentActiveId]?.onDisable();
    }

    await plugin.onEnable();
    _activePluginIds[plugin.category] = pluginId;
    await _saveState();
    notifyListeners();
  }

  /// 禁用插件（恢复到系统默认）
  Future<void> disablePlugin(String pluginId) async {
    final plugin = _registeredPlugins[pluginId];
    if (plugin == null) return;

    if (_activePluginIds[plugin.category] == pluginId) {
      await plugin.onDisable();
      _activePluginIds.remove(plugin.category);
      await _saveState();
      notifyListeners();
    }
  }
}
