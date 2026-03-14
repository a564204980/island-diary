import 'package:flutter/material.dart';

class DiaryUtils {
  /// 预设文本颜色
  static const List<Color> presetTextColors = [
    Color(0xFF5D4037),
    Color(0xFF2C3E50),
    Color(0xFF34495E),
    Color(0xFF27AE60),
    Color(0xFF16A085),
    Color(0xFFC0392B),
    Color(0xFFE74C3C),
    Color(0xFF8E44AD),
    Color(0xFF9B59B6),
    Color(0xFFF39C12),
    Color(0xFFD35400),
    Color(0xFF2980B9),
    Color(0xFF7F8C8D),
    Color(0xFF1ABC9C),
    Color(0xFFD4AC0D),
  ];

  /// 预设背景高亮颜色
  static const List<Color> presetBgColors = [
    Color(0xFFFFF9EE),
    Color(0xFFF9EED8),
    Color(0xFFE8F5E9),
    Color(0xFFE3F2FD),
    Color(0xFFFFF3E0),
    Color(0xFFFFEBEE),
    Color(0xFFF3E5F5),
    Color(0xFFE0F2F1),
    Color(0xFFF1F8E9),
    Color(0xFFFFFDE7),
    Color(0xFFFFFF00),
    Color(0xFF00FF00),
    Color(0xFF00FFFF),
    Color(0xFFFF00FF),
    Color(0xFFC0C0C0),
  ];

  /// 获取格式化的当前日期 (yyyy年MM月dd日)
  static String getFormattedDate() {
    final now = DateTime.now();
    return '${now.year}年${now.month}月${now.day}日';
  }

  /// 获取格式化的当前时间 (HH:mm)
  static String getFormattedTime() {
    final now = DateTime.now();
    return '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';
  }

  /// 根据心情获取治愈系语录
  static String getMoodQuote(String label) {
    const Map<String, List<String>> quotes = {
      '期待': ['愿所有的美好，都如约而至。', '心之所向，便是阳光。', '未来可期，人间值得。'],
      '厌恶': ['在这个喧嚣的世界，守住内心的清凉。', '不必讨好世界，只需取悦自己。', '烦恼随风去，清风自归来。'],
      '恐惧': ['勇敢不是不害怕，而是带着畏惧继续前行。', '黑暗终会过去，黎明就在前方。', '你比想象中更强大。'],
      '惊喜': ['生活总会在不经意间，给你温柔的重击。', '好运不期而遇，惊喜如约而至。', '每一场不期而遇，都是最好的礼物。'],
      '平静': ['世界喧嚣，我自安然。', '心若不动，风又奈何。', '静坐听蝉鸣，淡然看烟云。'],
      '愤怒': ['别让别人的错误，惩罚了自己的心情。', '深呼吸，把不快交给风。', '平和是最高级的优雅。'],
      '悲伤': ['眼泪是灵魂的洗礼。', '万物皆有裂痕，那是光照进来的地方。', '难过的时候，就抱抱那个勇敢的自己。'],
      '开心': ['你笑起来的样子，藏着一整个夏天的风。', '今日心情：明亮且温柔。', '收集世间的每一份好心情。'],
    };

    final List<String> options = quotes[label] ?? ['记录下这一刻的触动。'];
    return options[DateTime.now().second % options.length];
  }

  /// 拟人化强度描述文案映射
  static String getPersonifiedMoodDescription(String label, double intensity) {
    const Map<String, List<String>> moodPrefixes = {
      '期待': ['略带憧憬', '满心向往', '迫不及待'],
      '厌恶': ['有些反感', '深感蹙眉', '嫌弃至极'],
      '恐惧': ['隐约不安', '忐忑紧锁', '灵魂颤栗'],
      '惊喜': ['意料之外', '万分激动', '喜从天降'],
      '平静': ['凡事从容', '岁月安好', '万籁寂静'],
      '愤怒': ['隐隐不快', '火冒三丈', '怒气冲天'],
      '悲伤': ['隐隐哀愁', '满怀感伤', '痛彻心扉'],
      '开心': ['眉开眼笑', '神采飞扬', '狂喜雀跃'],
    };

    final int level = (intensity * 10).toInt();
    final List<String>? options = moodPrefixes[label];
    if (options == null) return label;
    final int index = level <= 3 ? 0 : (level <= 7 ? 1 : 2);
    // 注意：intensity 需转为 int 且由于业务需求直接显示 intensity 原值转换后的整数
    return "${options[index]}的$label/${intensity.toInt()}";
  }

  /// 奖励配置映射表
  static const Map<String, Map<String, String>> rewardConfigs = {
    'fox': {'name': '灵动小狐狸', 'path': 'assets/images/reward_fox.png'},
    'flower': {'name': '治愈小花朵', 'path': 'assets/images/reward_flower.png'},
    'bird': {'name': '和平小白鸟', 'path': 'assets/images/reward_bird.png'},
  };
}
