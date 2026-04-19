import 'package:flutter/material.dart';

part 'mascot_decoration_hats.dart';
part 'mascot_decoration_glasses.dart';
part 'mascot_decoration_other.dart';

/// 装饰品分类
enum MascotDecorationCategory {
  /// 帽子/头饰
  hat('帽子'),
  /// 眼镜
  glasses('眼镜'),
  /// 面饰 (如胡须、口红等)
  face('面饰'),
  /// 其他
  other('其他');

  final String label;
  const MascotDecorationCategory(this.label);
}

/// 稀有度定义
enum MascotRarity {
  common('普通', Color(0xFF94A3B8)),
  rare('稀有', Color(0xFF38BDF8)),
  epic('卓越', Color(0xFFA855F7)),
  legendary('传说', Color(0xFFF59E0B));

  final String label;
  final Color color;
  const MascotRarity(this.label, this.color);
}

/// 单个装扮针对不同形象的个性化配置
class MascotDecorationConfig {
  final Offset offset;
  final double scale;

  const MascotDecorationConfig({this.offset = Offset.zero, this.scale = 1.0});
}

/// 装饰品模型
class MascotDecoration {
  final String id;
  final String name;
  final String path;
  final String description;
  final MascotRarity rarity;
  final MascotDecorationCategory category;

  /// 默认的配置
  final MascotDecorationConfig defaultConfig;

  /// 针对不同形象的特定配置字典
  final Map<String, MascotDecorationConfig> characterConfigs;

  const MascotDecoration({
    required this.id,
    required this.name,
    required this.path,
    required this.description,
    this.rarity = MascotRarity.common,
    this.category = MascotDecorationCategory.hat,
    this.defaultConfig = const MascotDecorationConfig(),
    this.characterConfigs = const {},
  });

  /// 获取指定卡通形象对应的装扮配置
  MascotDecorationConfig getConfigForCharacter(String characterPath) {
    return characterConfigs[characterPath] ?? defaultConfig;
  }

  /// 全局饰品注册表 (维持向下兼容)
  static const List<MascotDecoration> allDecorations = [
    ..._hatDecorations,
    ..._glassesDecorations,
    ..._otherDecorations,
  ];

  /// 根据路径查找配置
  static MascotDecoration? getByPath(String? path) {
    if (path == null || path.isEmpty) return null;
    try {
      return allDecorations.firstWhere((d) => d.path == path);
    } catch (_) {
      return null;
    }
  }
}
