import 'package:flutter/material.dart';
import 'package:island_diary/features/record/domain/models/diary_entry.dart';

class SoulSeasonResult {
  final String seasonName;
  final String description;
  final String healingMessage; // 新增：更深层的治愈建议
  final String particleType; // 新增：对应的视角粒子类型 (flower, firefly, leaf, frost)
  final Color accentColor;
  final String icon;

  SoulSeasonResult({
    required this.seasonName,
    required this.description,
    required this.healingMessage,
    required this.particleType,
    required this.accentColor,
    required this.icon,
  });
}

class SoulSeasonLogic {
  static SoulSeasonResult getSeason(List<DiaryEntry> entries) {
    if (entries.isEmpty) {
      return SoulSeasonResult(
        seasonName: '沉寂之初',
        description: '岛屿还在等待你的第一笔记录，每一刻的感受都值得被铭记。',
        healingMessage: '哪怕只是一句简单的问候，也是与自己对话的开始。',
        particleType: 'none',
        accentColor: Colors.grey,
        icon: '🌬️',
      );
    }

    // 统计情绪分布
    Map<int, int> counts = {};
    double totalIntensity = 0;
    for (var e in entries) {
      counts[e.moodIndex] = (counts[e.moodIndex] ?? 0) + 1;
      totalIntensity += e.intensity;
    }

    final avgIntensity = totalIntensity / entries.length;

    // 找出占比最高的情绪类别（按 kMoods 定义的顺序映射）
    // 0: 期待, 1: 厌恶, 2: 恐惧, 3: 惊喜, 4: 平静, 5: 愤怒, 6: 悲伤, 7: 开心
    
    int getCount(int idx) => counts[idx] ?? 0;
    
    final positiveCount = getCount(0) + getCount(3) + getCount(7); // 期待、惊喜、开心
    final negativeCount = getCount(1) + getCount(2) + getCount(5) + getCount(6); // 厌恶、恐惧、愤怒、悲伤
    final neutralCount = getCount(4); // 平静

    if (positiveCount >= negativeCount && positiveCount >= neutralCount) {
      if (avgIntensity > 7.0) {
        return SoulSeasonResult(
          seasonName: '烈阳盛夏',
          description: '你的内心如仲夏般热烈，对生活充满了迸发的期待与喜悦。',
          healingMessage: '灿烂的阳光正照进心房，享受这份额外的生命热度吧。',
          particleType: 'firefly',
          accentColor: const Color(0xFFFFB347),
          icon: '☀️',
        );
      } else {
        return SoulSeasonResult(
          seasonName: '萌动初春',
          description: '万物正在你的灵魂中萌生，平和中带着对未知的温柔期待。',
          healingMessage: '在微风中伸个懒腰，那些小小的愿望正在静静破土。',
          particleType: 'flower',
          accentColor: const Color(0xFFA8E6CF),
          icon: '🌱',
        );
      }
    } else if (neutralCount >= positiveCount && neutralCount >= negativeCount) {
      return SoulSeasonResult(
        seasonName: '恬淡之秋',
        description: '灵魂正处于静谧的深秋，虽偶有风落，心境却已果实累累。',
        healingMessage: '听一听叶子落地的声音，这一刻的回响是给努力后的馈赠。',
        particleType: 'leaf',
        accentColor: const Color(0xFFD4A373),
        icon: '🍂',
      );
    } else {
      if (getCount(5) > getCount(6)) { // 愤怒多于悲伤
        return SoulSeasonResult(
          seasonName: '骤雨时节',
          description: '情绪中有着无法忽视的雷雨，去接纳那些不安，它们也是生命的一部分。',
          healingMessage: '雨后总有泥土的芬芳，不完美也是一种特别的生命张力。',
          particleType: 'rain',
          accentColor: const Color(0xFFFF6B6B),
          icon: '⛈️',
        );
      } else {
        return SoulSeasonResult(
          seasonName: '冷冽深冬',
          description: '灵魂在深冬蛰伏。偶尔的瑟缩是为了更好地积蓄力量，春天不远了。',
          healingMessage: '在寒冷中给自己一个拥抱，温暖其实一直都在手心里。',
          particleType: 'frost',
          accentColor: const Color(0xFF74EBD5),
          icon: '❄️',
        );
      }
    }
  }
}
