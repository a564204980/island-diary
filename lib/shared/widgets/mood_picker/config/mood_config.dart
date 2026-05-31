import 'package:flutter/material.dart';
import '../models/mood_item.dart';

// 这里的顺序必须与 MoodSelectorHeader 中的 moods 列表完全一致
List<MoodItem> kMoods = [
  // 0: 开心 (原索引 7)
  const MoodItem(
    label: '开心',
    iconPath: 'assets/icons/happy.png',
    imagePath: 'assets/images/icons/select8.png',
    glowColor: Color(0xFFFFA000),
  ),
  // 1: 平静 (原索引 4)
  const MoodItem(
    label: '平静',
    iconPath: 'assets/icons/calm.png',
    imagePath: 'assets/images/icons/select5.png',
    glowColor: Color(0xFFA4D4E4),
  ),
  // 2: 低落 (原索引 6 - 悲伤)
  const MoodItem(
    label: '低落',
    iconPath: 'assets/icons/down.png',
    imagePath: 'assets/images/icons/select7.png',
    glowColor: Color(0xFF84A4E4),
  ),
  // 3: 烦躁 (原索引 5 - 愤怒)
  const MoodItem(
    label: '烦躁',
    iconPath: 'assets/icons/irritated.png',
    imagePath: 'assets/images/icons/select6.png',
    glowColor: Color(0xFFFF8484),
  ),
  // 4: 疲惫 (暂用 select2 - 厌恶的配置)
  const MoodItem(
    label: '疲惫',
    iconPath: 'assets/icons/tired.png',
    imagePath: 'assets/images/icons/select2.png',
    glowColor: Color(0xFFC4A4E4),
  ),
  // 5: 惊喜 (原索引 3)
  const MoodItem(
    label: '惊喜',
    iconPath: 'assets/icons/surprise.png',
    imagePath: 'assets/images/icons/select4.png',
    glowColor: Color(0xFFFFC484),
  ),
  // 6: 害羞 (暂用 select1 - 期待的配置)
  const MoodItem(
    label: '害羞',
    iconPath: 'assets/icons/shy.png',
    imagePath: 'assets/images/icons/select1.png',
    glowColor: Color(0xFFF06292),
  ),
  // 7: 焦虑 (原索引 2 - 恐惧)
  const MoodItem(
    label: '焦虑',
    iconPath: 'assets/icons/anxious.png',
    imagePath: 'assets/images/icons/select3.png',
    glowColor: Color(0xFF90A4AE),
  ),
  // 8: 委屈 (暂用 select7 - 悲伤的配置)
  const MoodItem(
    label: '委屈',
    iconPath: 'assets/icons/wronged.png',
    imagePath: 'assets/images/icons/select7.png',
    glowColor: Color(0xFF9575CD),
  ),
  // 9: 无聊 (暂用 select5 - 平静的配置)
  const MoodItem(
    label: '无聊',
    iconPath: 'assets/icons/bored.png',
    imagePath: 'assets/images/icons/select5.png',
    glowColor: Color(0xFFA1887F),
  ),
  // 10: 期待 (原索引 0)
  const MoodItem(
    label: '期待',
    iconPath: 'assets/icons/expect.png',
    imagePath: 'assets/images/icons/select1.png',
    glowColor: Color(0xFFFFB74D),
  ),
];
