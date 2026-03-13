class DiaryUtils {
  /// 获取格式化的当前日期 (yyyy年MM月dd日)
  static String getFormattedDate() {
    final now = DateTime.now();
    return '${now.year}年${now.month}月${now.day}日';
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
