import 'package:flutter/material.dart';
 
class MoodItem {
  final String label;         // 心情名称 (如: '开心')
  final String? iconPath;     // 小图标路径 (如: 'assets/icons/happy.png')
  final Color? glowColor;     // 心情色调色彩

  const MoodItem({
    required this.label,
    this.iconPath,
    this.glowColor,
  });
}
