class DiaryUtils {
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
}
