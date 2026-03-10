import 'package:flutter/material.dart';
import '../models/mood_item.dart';

List<MoodItem> kMoods = [
  const MoodItem(
    label: '期待',
    imagePath: 'assets/images/icons/select1.png',
    angle: 0,
    imageRotation: 0,
    imageTop: 8,
    imageLeft: -78,
    width: 205,
    height: 286,
    scale: 0.38,
    // 图文绝对坐标偏移 (x 为正向右，y 为正向下)
    iconPath: 'assets/images/icons/sprout.png',
    iconSize: 40,
    fontSize: 14,
    iconOffset: Offset(-28, -84),
    textOffset: Offset(-26, -60),
    glowColor: Color(0xFFFFA4A4), // 粉红色
  ),
  const MoodItem(
    label: '厌恶',
    imagePath: 'assets/images/icons/select2.png',
    angle: 315,
    imageRotation: 40,
    imageTop: 13,
    imageLeft: 60,
    width: 324,
    height: 237,
    scale: 0.34,
    // 图文绝对坐标偏移
    iconPath: 'assets/images/icons/upset.png',
    iconSize: 40,
    fontSize: 14,
    iconOffset: Offset(-74, -38),
    textOffset: Offset(-72, -14),
    glowColor: Color(0xFFA4E4A4), // 浅绿色
  ),
  const MoodItem(
    label: '恐惧',
    imagePath: 'assets/images/icons/select3.png',
    angle: 270,
    imageRotation: 90,
    imageTop: -60,
    imageLeft: 72,
    width: 324,
    height: 241,
    scale: 0.33,
    // 图文绝对坐标偏移
    iconPath: 'assets/images/icons/eyes.png',
    iconSize: 52,
    fontSize: 14,
    iconOffset: Offset(-76, 28),
    textOffset: Offset(-76, 50),
    glowColor: Color(0xFFC4A4E4), // 紫色
  ),
  const MoodItem(
    label: '惊喜',
    imagePath: 'assets/images/icons/select4.png',
    angle: 225,
    imageRotation: 135,
    imageTop: -178,
    imageLeft: 123,
    width: 230,
    height: 345,
    scale: 0.35,
    // 图文绝对坐标偏移
    iconPath: 'assets/images/icons/star.png',
    iconSize: 40,
    fontSize: 14,
    iconOffset: Offset(-28, 78),
    textOffset: Offset(-28, 102),
    glowColor: Color(0xFFFFC484), // 橘黄色
  ),
  const MoodItem(
    label: '平静',
    imagePath: 'assets/images/icons/select5.png',
    angle: 180,
    imageRotation: 180,
    imageTop: -294,
    imageLeft: -88,
    width: 306,
    height: 420,
    scale: 0.274,
    // 图文绝对坐标偏移
    iconPath: 'assets/images/icons/leaf.png',
    iconSize: 56,
    fontSize: 14,
    iconOffset: Offset(34, 78),
    textOffset: Offset(34, 102),
    glowColor: Color(0xFFA4D4E4), // 浅蓝色
  ),
  const MoodItem(
    label: '愤怒',
    imagePath: 'assets/images/icons/select6.png',
    angle: 225,
    imageRotation: 134,
    imageTop: -176,
    imageLeft: -58,
    width: 301,
    height: 221,
    scale: 0.38,
    // 图文绝对坐标偏移
    iconPath: 'assets/images/icons/angry.png',
    iconSize: 56,
    fontSize: 14,
    iconOffset: Offset(86, 28),
    textOffset: Offset(86, 52),
    glowColor: Color(0xFFFF8484), // 红色
  ),
  const MoodItem(
    label: '悲伤',
    imagePath: 'assets/images/icons/select7.png',
    angle: 270,
    imageRotation: 90,
    imageTop: -158,
    imageLeft: 180,
    width: 245,
    height: 181,
    scale: 0.52,
    // 图文绝对坐标偏移
    iconPath: 'assets/images/icons/raindrop.png',
    iconSize: 58,
    fontSize: 14,
    iconOffset: Offset(86, -42),
    textOffset: Offset(86, -14),
    glowColor: Color(0xFF84A4E4), // 深蓝色
  ),
  const MoodItem(
    label: '开心',
    imagePath: 'assets/images/icons/select8.png',
    angle: 4,
    imageRotation: 0,
    imageTop: 10,
    imageLeft: 72,
    width: 175,
    height: 230,
    scale: 0.48,
    // 图文绝对坐标偏移
    iconPath: 'assets/images/icons/sun.png',
    iconSize: 46,
    fontSize: 14,
    iconOffset: Offset(33, -88),
    textOffset: Offset(33, -60),
    glowColor: Color(0xFFFFE484), // 黄色
  ),
];
