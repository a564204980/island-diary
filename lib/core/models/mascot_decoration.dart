import 'package:flutter/material.dart';

class MascotDecoration {
  final String id;
  final String name;
  final String path;
  final Offset offset;
  final double scale;
  final String description;

  const MascotDecoration({
    required this.id,
    required this.name,
    required this.path,
    this.offset = Offset.zero,
    this.scale = 1.0,
    required this.description,
  });

  /// 全局饰品注册表
  static const List<MascotDecoration> allDecorations = [
    MascotDecoration(
      id: 'mask',
      name: '高达头盔',
      path: 'assets/images/emoji/decorate/decorate1.png',
      offset: Offset(0, -6), // 向上偏移以对齐眼睛
      scale: 1.1, // 略微放大覆盖侧边
      description: '在未知的丛林中穿梭',
    ),
    MascotDecoration(
      id: 'glasses',
      name: '博学眼镜',
      path: 'assets/images/emoji/decorate/decorate2.png',
      offset: Offset(0, -20), // 向下偏移对齐脸颊
      scale: 1.2, // 缩小避免溢出边缘
      description: '知识让视线更加清晰',
    ),
    MascotDecoration(
      id: 'flower',
      name: '蝴蝶盔（刀马旦）',
      path: 'assets/images/emoji/decorate/decorate3.png',
      offset: Offset(0, -28), // 向右上角偏移
      scale: 1.8, // 放大展现细节
      description: '采下一朵最娇艳的记忆',
    ),
    MascotDecoration(
      id: 'reindeer',
      name: '麋鹿头饰',
      path: 'assets/images/emoji/decorate/decorate4.png',
      offset: Offset(0, -20), // 向上偏移以对齐头顶
      scale: 1.5, // 略微放大展现鹿角细节
      description: '戴上鹿角，奔向冬日的旷野',
    ),
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
