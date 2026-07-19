import 'package:flutter/material.dart';
import '../../features/record/domain/models/diary_entry.dart';

/// 插件分类
enum PluginCategory {
  camera,     // 相机相关（皮肤、取景器、专属滤镜）
  editor,     // 手账编辑器相关（新贴纸、新笔刷）
  widget,     // 桌面小组件
  tool,       // 效率工具（如数据导出）
  experience, // 场景体验（特殊标签交互）
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

/// 专门针对特定标签、场景增强体验的插件抽象类
abstract class ExperiencePlugin extends IslandPlugin {
  @override
  PluginCategory get category => PluginCategory.experience;

  /// 该体验插件响应的目标标签列表
  List<String> get targetTags;

  /// 构建编辑器顶部
  Widget? buildEditorHeader(BuildContext context, {required String tag}) => null;

  /// 构建编辑器底部
  Widget? buildEditorFooter(BuildContext context, {required String tag, required Map<String, String> annotations, bool isReadOnly = false}) => null;

  /// 构建时间轴上的迷你组件 (简化的行程条等)
  Widget? buildTimelineMiniWidget(BuildContext context, {required String tag, required Map<String, String> annotations}) => null;

  /// 构建编辑器背景
  Widget? buildEditorBackground(BuildContext context, {required String tag}) => null;

  /// 保存前拦截（可用于弹窗选择，如果返回 false 则阻断保存）
  Future<bool> onBeforeSave(BuildContext context, DiaryEntry entry) async => true;

  /// 保存后拦截（可用于弹窗展示结果）
  Future<void> onAfterSave(BuildContext context, DiaryEntry entry) async {}

  /// 当用户主动添加某个该插件关注的标签时触发
  Future<void> onTagAdded(BuildContext context, String tag, Map<String, String> annotations) async {}

  /// 构建自定义的标签视图（取代标准的 Timeline）
  Widget? buildCustomTimelineView(BuildContext context, List<DiaryEntry> entries) => null;
}
