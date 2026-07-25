import 'package:flutter/material.dart';

/// 首页模块与卡片元数据配置项
class HomeModuleItem {
  final String id;
  final String title;
  final String subtitle;
  final IconData icon;
  final bool isFullWidth;
  bool enabled;
  int order;

  HomeModuleItem({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.isFullWidth,
    this.enabled = true,
    this.order = 0,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'enabled': enabled,
        'order': order,
        'isFullWidth': isFullWidth,
      };

  factory HomeModuleItem.fromJson(Map<String, dynamic> json, HomeModuleItem defaultTemplate) {
    return HomeModuleItem(
      id: defaultTemplate.id,
      title: defaultTemplate.title,
      subtitle: defaultTemplate.subtitle,
      icon: defaultTemplate.icon,
      isFullWidth: json['isFullWidth'] as bool? ?? defaultTemplate.isFullWidth,
      enabled: json['enabled'] as bool? ?? defaultTemplate.enabled,
      order: json['order'] as int? ?? defaultTemplate.order,
    );
  }

  HomeModuleItem copyWith({
    bool? isFullWidth,
    bool? enabled,
    int? order,
  }) {
    return HomeModuleItem(
      id: id,
      title: title,
      subtitle: subtitle,
      icon: icon,
      isFullWidth: isFullWidth ?? this.isFullWidth,
      enabled: enabled ?? this.enabled,
      order: order ?? this.order,
    );
  }

  /// 获取系统预设的全部首页卡片列表
  static List<HomeModuleItem> getDefaultModules() {
    return [
      HomeModuleItem(
        id: 'photo_throwback',
        title: '时光相框',
        subtitle: '拾起昔日闪光的碎片',
        icon: Icons.photo_library_rounded,
        isFullWidth: false,
        enabled: true,
        order: 0,
      ),
      HomeModuleItem(
        id: 'photo_wall',
        title: '情绪轨迹',
        subtitle: '记录相册照片的足迹',
        icon: Icons.auto_awesome_motion_rounded,
        isFullWidth: false,
        enabled: true,
        order: 1,
      ),
      HomeModuleItem(
        id: 'gravity_box',
        title: '重力宝藏盒',
        subtitle: '沉浸式正念重力感知盒',
        icon: Icons.all_inclusive_rounded,
        isFullWidth: false,
        enabled: true,
        order: 2,
      ),
      HomeModuleItem(
        id: 'camera_widget',
        title: '岛屿快照',
        subtitle: '一键定格当下瞬间',
        icon: Icons.camera_alt_rounded,
        isFullWidth: false,
        enabled: false, // 放在卡片仓库中做初始备选
        order: 3,
      ),
      HomeModuleItem(
        id: 'piano_mood',
        title: '近七日心情',
        subtitle: '琴键与音律联动弹奏',
        icon: Icons.music_note_rounded,
        isFullWidth: true,
        enabled: true,
        order: 4,
      ),
      HomeModuleItem(
        id: 'inspiration_quote',
        title: '每日灵感金句',
        subtitle: '温暖灵感诗句与岛屿问候',
        icon: Icons.format_quote_rounded,
        isFullWidth: true,
        enabled: false, // 放在卡片仓库中做初始备选
        order: 5,
      ),
    ];
  }
}
