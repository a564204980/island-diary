import 'package:flutter/material.dart';

class MoodItem {
  final String label;
  final String? imagePath;
  final double angle; // 圆盘方位角
  final double? imageRotation; // 贴图自身旋转角(角度)
  final double? imageTop; // 径向偏移 (正数远离圆心，负数靠近圆心)
  final double? imageLeft; // 切向偏移 (左右微调)
  final double? width;
  final double? height;
  final double? scale;

  // 图文组配置 (不受切片旋转和偏移影响，基于圆心绝对定位)
  final String? iconPath; // 小图标路径
  final double? iconSize; // 图标大小 (由于主要为正方形，提供一个 size)
  final double? fontSize; // 文字大小
  final Offset? iconOffset; // 图标相对于圆盘中心的绝对偏移
  final Offset? textOffset; // 文字相对于圆盘中心的绝对偏移
  final double? iconRotation; // 图标自身的旋转
  final double? textRotation; // 文字自身的旋转
  final Color? glowColor; // 选中时的外圈发光色

  const MoodItem({
    required this.label,
    this.imagePath,
    required this.angle,
    this.imageRotation,
    this.imageTop,
    this.imageLeft,
    this.width,
    this.height,
    this.scale,
    this.iconPath,
    this.iconSize,
    this.fontSize,
    this.iconOffset,
    this.textOffset,
    this.iconRotation,
    this.textRotation,
    this.glowColor,
  });
}
