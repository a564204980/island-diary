import 'package:flutter/material.dart';
import '../models/mood_item.dart';

// 这里的顺序必须与 MoodSelectorHeader 中的 moods 列表完全一致
List<MoodItem> kMoods = [
  // 0: 开心
  const MoodItem(
    label: '开心',
    iconPath: 'assets/icons/happy.png',
    glowColor: Color(0xFFFFEEA6),
  ),
  // 1: 平静
  const MoodItem(
    label: '平静',
    iconPath: 'assets/icons/calm.png',
    glowColor: Color(0xFFCFE8D6),
  ),
  // 2: 低落
  const MoodItem(
    label: '低落',
    iconPath: 'assets/icons/down.png',
    glowColor: Color(0xFFB7C6D9),
  ),
  // 3: 烦躁
  const MoodItem(
    label: '烦躁',
    iconPath: 'assets/icons/irritated.png',
    glowColor: Color(0xFFFFC2B5),
  ),
  // 4: 疲惫
  const MoodItem(
    label: '疲惫',
    iconPath: 'assets/icons/tired.png',
    glowColor: Color(0xFFB5C8C9),
  ),
  // 5: 惊喜
  const MoodItem(
    label: '惊喜',
    iconPath: 'assets/icons/surprise.png',
    glowColor: Color(0xFFFFE7A3), // 对应图中黄色款惊喜
  ),
  // 6: 害羞
  const MoodItem(
    label: '害羞',
    iconPath: 'assets/icons/shy.png',
    glowColor: Color(0xFFFFD6E0),
  ),
  // 7: 焦虑
  const MoodItem(
    label: '焦虑',
    iconPath: 'assets/icons/anxious.png',
    glowColor: Color(0xFFDCCCF0),
  ),
  // 8: 委屈
  const MoodItem(
    label: '委屈',
    iconPath: 'assets/icons/wronged.png',
    glowColor: Color(0xFFC7D9F1),
  ),
  // 9: 无聊
  const MoodItem(
    label: '无聊',
    iconPath: 'assets/icons/bored.png',
    glowColor: Color(0xFFDDE7D1),
  ),
  // 10: 期待
  const MoodItem(
    label: '期待',
    iconPath: 'assets/icons/expect.png',
    glowColor: Color(0xFFFFE0B5),
  ),
];
