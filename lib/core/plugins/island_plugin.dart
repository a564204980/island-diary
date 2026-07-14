import 'package:flutter/material.dart';

/// 插件分类
enum PluginCategory {
  camera,     // 相机相关（皮肤、取景器、专属滤镜）
  editor,     // 手账编辑器相关（新贴纸、新笔刷）
  widget,     // 桌面小组件
  tool,       // 效率工具（如数据导出）
}

/// 所有插件的基础契约
abstract class IslandPlugin {
  /// 插件唯一标识符
  String get pluginId;
  
  /// 插件名称
  String get name;
  
  /// 插件描述
  String get description;
  
  /// 插件版本号
  String get version;
  
  /// 插件类别
  PluginCategory get category;

  /// 插件预览图或图标的远程 URL
  String get previewImageUrl;
  
  /// 下载/安装插件时调用（这里做资源的拉取或数据库初始化操作）
  Future<void> onInstall() async {}
  
  /// 插件启用时调用
  Future<void> onEnable() async {}
  
  /// 插件禁用时调用
  Future<void> onDisable() async {}
  
  /// 卸载插件时清理资源
  Future<void> onUninstall() async {}
}

/// 专门针对相机扩展点的插件抽象类
abstract class CameraPlugin extends IslandPlugin {
  @override
  PluginCategory get category => PluginCategory.camera;

  /// 核心方法：向系统提供相机界面的构建方式
  /// [onReTake] 重新拍摄回调
  /// [onRetBack] 返回回调
  Widget buildCameraPage(BuildContext context, {
    String? initialImagePath,
    String? initialMattedPath,
  });
}
