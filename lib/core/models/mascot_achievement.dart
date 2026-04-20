import 'package:flutter/material.dart';

/// 称号等级枚举，依据 rewardPoints 自动推导
enum TitleTier {
  bronze('青铜', Color(0xFF9CA3AF)),
  silver('白银', Color(0xFFB87333)),
  gold('黄金', Color(0xFFFFB300)),
  platinum('铂金', Color(0xFF2DD4BF)),
  diamond('钻石', Color(0xFF818CF8));

  final String label;
  final Color color;
  const TitleTier(this.label, this.color);

  /// 卡片背景渐变（已解锁态）
  LinearGradient get unlockedGradient {
    switch (this) {
      case TitleTier.bronze:
        return const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFFFF8F0), Color(0xFFF5E6D3)],
        );
      case TitleTier.silver:
        return const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFF8FAFC), Color(0xFFE2E8F0)],
        );
      case TitleTier.gold:
        return const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFFFFBEB), Color(0xFFFEF3C7)],
        );
      case TitleTier.platinum:
        return const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFECFDF5), Color(0xFFCCFBF1)],
        );
      case TitleTier.diamond:
        return const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFEDE9FE), Color(0xFFDDD6FE)],
        );
    }
  }

  /// 边框颜色
  Color get borderColor => color.withValues(alpha: 0.45);

  /// 等级徽标图标
  IconData get badge {
    switch (this) {
      case TitleTier.bronze:
        return Icons.workspace_premium_rounded;
      case TitleTier.silver:
        return Icons.star_rounded;
      case TitleTier.gold:
        return Icons.emoji_events_rounded;
      case TitleTier.platinum:
        return Icons.diamond_rounded;
      case TitleTier.diamond:
        return Icons.auto_awesome_rounded;
    }
  }

  /// 饱和渐变（用于卡片背景、外部标签等）
  LinearGradient get cardGradient {
    switch (this) {
      case TitleTier.bronze:
        return const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF8EA0B2), Color(0xFF546778)],
        );
      case TitleTier.silver:
        return const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFD4924B), Color(0xFF8B5E35)],
        );
      case TitleTier.gold:
        return const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFFFCA28), Color(0xFFD46B00)],
        );
      case TitleTier.platinum:
        return const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF2DD4BF), Color(0xFF0D9488)],
        );
      case TitleTier.diamond:
        return const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF818CF8), Color(0xFFB845F5)],
        );
    }
  }
}

enum AchievementCondition {
  totalDiaries,
  maxStreak,
  uniqueMoods,
  totalWords,
  morningDiaries,
  nightDiaries,
  maxSingleWords,
  totalDecorationsOwned,
  photoDiaries,
  uniqueTags,
  activeDays,
  totalMoods,
  vipLevel,
  isResident,
}

class MascotAchievement {
  final String id;
  final String title;
  final String description;
  final AchievementCondition condition;
  final int targetValue;
  final String? rewardDecorationId;
  final String? rewardTitle;
  final String? rewardMascotPath;
  final int rewardPoints;
  final String? imagePath;
  final double medalScale;
  final Offset medalOffset;

  const MascotAchievement({
    required this.id,
    required this.title,
    required this.description,
    required this.condition,
    required this.targetValue,
    this.rewardDecorationId,
    this.rewardTitle,
    this.rewardMascotPath,
    this.rewardPoints = 10,
    this.imagePath,
    this.medalScale = 1.0,
    this.medalOffset = Offset.zero,
  });

  /// 检查是否满足成就条件
  bool isMet(Map<String, int> stats) {
    final value = stats[condition.name] ?? 0;
    return value >= targetValue;
  }

  /// 根据 rewardPoints 自动计算称号等级
  TitleTier get titleTier {
    if (rewardPoints >= 800) return TitleTier.diamond;
    if (rewardPoints >= 401) return TitleTier.platinum;
    if (rewardPoints >= 151) return TitleTier.gold;
    if (rewardPoints >= 51) return TitleTier.silver;
    return TitleTier.bronze;
  }

  /// 全局成就注册表
  static const List<MascotAchievement> allAchievements = [
    MascotAchievement(
      id: 'first_diary',
      title: '初遇小岛',
      description: '记录第 1 篇日记',
      condition: AchievementCondition.totalDiaries,
      targetValue: 1,
      rewardDecorationId: 'panda_hat',
      rewardTitle: '岛上新邻',
      rewardPoints: 20,
    ),
    MascotAchievement(
      id: 'seven_days_milestone',
      title: '旅岛序章',
      description: '累计记录 7 篇日记',
      condition: AchievementCondition.totalDiaries,
      targetValue: 7,
      rewardTitle: '旅岛信使',
      rewardPoints: 30,
    ),
    MascotAchievement(
      id: 'lingxi_unlock',
      title: '林间灵光',
      description: '累计记录 14 篇日记',
      condition: AchievementCondition.totalDiaries,
      targetValue: 14,
      rewardMascotPath: 'assets/images/emoji/marshmallow3.png',
      rewardTitle: '灵犀之友',
      rewardPoints: 50,
      imagePath: 'assets/images/emoji/medal/medal8.png',
      medalScale: 1.2,
    ),
    MascotAchievement(
      id: 'month_milestone',
      title: '旧梦采集',
      description: '累计记录 30 篇日记',
      condition: AchievementCondition.totalDiaries,
      targetValue: 30,
      rewardDecorationId: 'retro_heart_bow',
      rewardTitle: '旧梦拾遗',
      rewardPoints: 100,
    ),
    MascotAchievement(
      id: 'three_days_streak',
      title: '微光跃动',
      description: '连续 3 天记录日记',
      condition: AchievementCondition.maxStreak,
      targetValue: 3,
      rewardTitle: '点点微光',
      rewardPoints: 20,
      imagePath: 'assets/images/emoji/medal/medal3.png',
      medalScale: 1.7,
    ),
    MascotAchievement(
      id: 'fifteen_days_streak',
      title: '海岛回响',
      description: '连续 15 天记录日记',
      condition: AchievementCondition.maxStreak,
      targetValue: 15,
      rewardTitle: '海岛羁绊',
      rewardPoints: 80,
    ),
    MascotAchievement(
      id: 'streak_30_days',
      title: '孤岛守望',
      description: '连续 30 天记录日记',
      condition: AchievementCondition.maxStreak,
      targetValue: 30,
      rewardDecorationId: 'egret',
      rewardTitle: '孤岛守夜',
      rewardPoints: 200,
    ),
    MascotAchievement(
      id: 'mood_explorer',
      title: '情绪标本',
      description: '记录过 5 种不同的情绪',
      condition: AchievementCondition.uniqueMoods,
      targetValue: 5,
      rewardTitle: '情绪切片',
      rewardPoints: 40,
    ),
    MascotAchievement(
      id: 'all_moods_explorer',
      title: '百态品鉴',
      description: '记录过全部 12 种不同的情绪',
      condition: AchievementCondition.uniqueMoods,
      targetValue: 12,
      rewardDecorationId: 'funny_tails',
      rewardTitle: '浮生掠影',
      rewardPoints: 200,
    ),
    MascotAchievement(
      id: 'morning_ritual',
      title: '向阳前行',
      description: '在早上 5:00 - 10:00 记录 7 篇日记',
      condition: AchievementCondition.morningDiaries,
      targetValue: 7,
      rewardTitle: '向阳而栖',
      rewardPoints: 50,
      imagePath: 'assets/images/emoji/medal/medal7.png',
      medalScale: 1.2,
    ),
    MascotAchievement(
      id: 'night_soul',
      title: '星夜观察',
      description: '在凌晨 0:00 - 4:00 记录 5 篇日记',
      condition: AchievementCondition.nightDiaries,
      targetValue: 5,
      rewardTitle: '引星入梦',
      rewardPoints: 50,
      imagePath: 'assets/images/emoji/medal/medal6.png',
      medalScale: 1.2,
    ),
    MascotAchievement(
      id: 'long_diary_talker',
      title: '孤独独白',
      description: '单篇日记字数超过 500 字',
      condition: AchievementCondition.maxSingleWords,
      targetValue: 500,
      rewardTitle: '孤独乐章',
      rewardPoints: 60,
      imagePath: 'assets/images/emoji/medal/medal18.png',
      medalScale: 1.2,
    ),
    MascotAchievement(
      id: 'word_master',
      title: '文字织网',
      description: '累计字数达到 5000 字',
      condition: AchievementCondition.totalWords,
      targetValue: 5000,
      rewardTitle: '笔尖脉络',
      rewardPoints: 120,
      imagePath: 'assets/images/emoji/medal/medal15.png',
      medalScale: 1.2,
    ),
    MascotAchievement(
      id: 'word_scholar',
      title: '星际牧笔',
      description: '累计字数达到 20000 字',
      condition: AchievementCondition.totalWords,
      targetValue: 20000,
      rewardDecorationId: 'snake_rabbit',
      rewardTitle: '牧星图志',
      rewardPoints: 300,
    ),
    MascotAchievement(
      id: 'fashion_icon',
      title: '美学策展',
      description: '拥有 15 件以上的小软饰品',
      condition: AchievementCondition.totalDecorationsOwned,
      targetValue: 15,
      rewardTitle: '美学原点',
      rewardPoints: 150,
    ),
    MascotAchievement(
      id: 'half_year_journey',
      title: '时光咏叹',
      description: '记录总数达到 180 篇日记',
      condition: AchievementCondition.totalDiaries,
      targetValue: 180,
      rewardDecorationId: 'luo_yan',
      rewardTitle: '时光咏叹调',
      rewardPoints: 400,
    ),
    MascotAchievement(
      id: 'year_celebration',
      title: '恒常记录',
      description: '记录总数达到 365 篇日记',
      condition: AchievementCondition.totalDiaries,
      targetValue: 365,
      rewardTitle: '岁月恒常',
      rewardPoints: 1000,
    ),
    MascotAchievement(
      id: 'diaries_50',
      title: '海岛灵感',
      description: '累计记录 50 篇日记',
      condition: AchievementCondition.totalDiaries,
      targetValue: 50,
      rewardTitle: '灵感捕手',
      rewardPoints: 50,
      imagePath: 'assets/images/emoji/medal/medal5.png',
      medalScale: 1.2,
    ),
    MascotAchievement(
      id: 'yunzhi_unlock',
      title: '云端织梦',
      description: '累计记录 60 篇日记',
      condition: AchievementCondition.totalDiaries,
      targetValue: 60,
      rewardMascotPath: 'assets/images/emoji/marshmallow.png',
      rewardTitle: '织梦大师',
      rewardPoints: 120,
      imagePath: 'assets/images/emoji/medal/medal11.png',
      medalScale: 1.2,
    ),
    MascotAchievement(
      id: 'diaries_100',
      title: '深海速读',
      description: '累计记录 100 篇日记',
      condition: AchievementCondition.totalDiaries,
      targetValue: 100,
      rewardTitle: '文字潜行',
      rewardPoints: 100,
    ),
    MascotAchievement(
      id: 'diaries_200',
      title: '编年史记',
      description: '累计记录 200 篇日记',
      condition: AchievementCondition.totalDiaries,
      targetValue: 200,
      rewardTitle: '岛屿年鉴',
      rewardPoints: 200,
    ),
    MascotAchievement(
      id: 'diaries_500',
      title: '传世墨迹',
      description: '累计记录 500 篇日记',
      condition: AchievementCondition.totalDiaries,
      targetValue: 500,
      rewardDecorationId: 'lucky_tiger',
      rewardTitle: '墨色陈迹',
      rewardPoints: 500,
    ),
    MascotAchievement(
      id: 'diaries_1000',
      title: '文明火种',
      description: '累计记录 1000 篇日记',
      condition: AchievementCondition.totalDiaries,
      targetValue: 1000,
      rewardDecorationId: 'chen_yu',
      rewardTitle: '文明薪传',
      rewardPoints: 1000,
    ),
    MascotAchievement(
      id: 'streak_50',
      title: '岁月隙间',
      description: '连续 50 天记录日记',
      condition: AchievementCondition.maxStreak,
      targetValue: 50,
      rewardTitle: '漫步岁月的隙间',
      rewardPoints: 120,
    ),
    MascotAchievement(
      id: 'streak_100',
      title: '长情共生',
      description: '连续 100 天记录日记',
      condition: AchievementCondition.maxStreak,
      targetValue: 100,
      rewardTitle: '长情共生体',
      rewardPoints: 300,
    ),
    MascotAchievement(
      id: 'streak_200',
      title: '意志朝圣',
      description: '连续 200 天记录日记',
      condition: AchievementCondition.maxStreak,
      targetValue: 200,
      rewardTitle: '意志跋涉',
      rewardPoints: 500,
    ),
    MascotAchievement(
      id: 'streak_365',
      title: '最后信徒',
      description: '连续 365 天记录日记',
      condition: AchievementCondition.maxStreak,
      targetValue: 365,
      rewardDecorationId: 'yellow_duck_hat',
      rewardTitle: '时光残响',
      rewardPoints: 1000,
    ),
    MascotAchievement(
      id: 'single_word_1000',
      title: '思绪暴君',
      description: '单篇日记字数超过 1000 字',
      condition: AchievementCondition.maxSingleWords,
      targetValue: 1000,
      rewardTitle: '思绪暴君',
      rewardPoints: 150,
    ),
    MascotAchievement(
      id: 'total_word_50000',
      title: '岛屿叙事',
      description: '累计字数达到 50000 字',
      condition: AchievementCondition.totalWords,
      targetValue: 50000,
      rewardTitle: '岛屿物语',
      rewardPoints: 400,
    ),
    MascotAchievement(
      id: 'total_word_100000',
      title: '文字筑城',
      description: '累计字数达到 100000 字',
      condition: AchievementCondition.totalWords,
      targetValue: 100000,
      rewardDecorationId: 'red_long_tassel',
      rewardTitle: '文字围城',
      rewardPoints: 800,
    ),
    MascotAchievement(
      id: 'morning_30',
      title: '曦光漫步',
      description: '晨间日记达到 30 篇',
      condition: AchievementCondition.morningDiaries,
      targetValue: 30,
      rewardTitle: '曦光微行',
      rewardPoints: 80,
    ),
    MascotAchievement(
      id: 'morning_100',
      title: '逐日之旅',
      description: '晨间日记达到 100 篇',
      condition: AchievementCondition.morningDiaries,
      targetValue: 100,
      rewardTitle: '逐日流光',
      rewardPoints: 250,
      imagePath: 'assets/images/emoji/medal/medal10.png',
      medalScale: 1.2,
    ),
    MascotAchievement(
      id: 'night_30',
      title: '星火编织',
      description: '深夜日记达到 30 篇',
      condition: AchievementCondition.nightDiaries,
      targetValue: 30,
      rewardTitle: '星夜织火',
      rewardPoints: 80,
      imagePath: 'assets/images/emoji/medal/medal19.png',
      medalScale: 1.2,
    ),
    MascotAchievement(
      id: 'night_100',
      title: '银河拾荒',
      description: '深夜日记达到 100 篇',
      condition: AchievementCondition.nightDiaries,
      targetValue: 100,
      rewardTitle: '银河微尘',
      rewardPoints: 250,
    ),
    MascotAchievement(
      id: 'decorations_5',
      title: '审美拾荒',
      description: '拥有超过 5 件小软饰品',
      condition: AchievementCondition.totalDecorationsOwned,
      targetValue: 5,
      rewardTitle: '审美感知',
      rewardPoints: 20,
      imagePath: 'assets/images/emoji/medal/medal12.png',
      medalScale: 1.2,
    ),
    MascotAchievement(
      id: 'decorations_10',
      title: '繁花主理',
      description: '拥有超过 10 件小软饰品',
      condition: AchievementCondition.totalDecorationsOwned,
      targetValue: 10,
      rewardDecorationId: 'big_ear_fluffy_hat',
      rewardTitle: '繁花主理人',
      rewardPoints: 60,
    ),
    MascotAchievement(
      id: 'decorations_25',
      title: '霓虹收藏',
      description: '收集齐 25 件以上饰品',
      condition: AchievementCondition.totalDecorationsOwned,
      targetValue: 25,
      rewardTitle: '霓虹幻影',
      rewardPoints: 400,
    ),
    MascotAchievement(
      id: 'photo_1',
      title: '瞬间捕捉',
      description: '记录第 1 篇图文日记',
      condition: AchievementCondition.photoDiaries,
      targetValue: 1,
      rewardTitle: '瞬间留白',
      rewardPoints: 10,
      imagePath: 'assets/images/emoji/medal/medal2.png',
      medalScale: 1.12,
    ),
    MascotAchievement(
      id: 'photo_10',
      title: '光影巡游',
      description: '累计记录 10 篇图文日记',
      condition: AchievementCondition.photoDiaries,
      targetValue: 10,
      rewardTitle: '光影漫步',
      rewardPoints: 80,
      imagePath: 'assets/images/emoji/medal/medal20.png',
      medalScale: 1.2,
    ),
    MascotAchievement(
      id: 'photo_50',
      title: '光影叙事',
      description: '累计记录 50 篇图文日记',
      condition: AchievementCondition.photoDiaries,
      targetValue: 50,
      rewardDecorationId: 'lily_hat',
      rewardTitle: '光影志异',
      rewardPoints: 300,
    ),
    MascotAchievement(
      id: 'photo_100',
      title: '画卷缔造',
      description: '记录 100 篇精彩图文',
      condition: AchievementCondition.photoDiaries,
      targetValue: 100,
      rewardTitle: '画卷初成',
      rewardPoints: 600,
    ),
    MascotAchievement(
      id: 'tag_5',
      title: '秩序初探',
      description: '使用 5 个不同的标签',
      condition: AchievementCondition.uniqueTags,
      targetValue: 5,
      rewardTitle: '秩序原点',
      rewardPoints: 20,
      imagePath: 'assets/images/emoji/medal/medal16.png',
      medalScale: 1.2,
    ),
    MascotAchievement(
      id: 'tag_15',
      title: '记忆领航',
      description: '累计使用过 15 个不同标签',
      condition: AchievementCondition.uniqueTags,
      targetValue: 15,
      rewardTitle: '记忆灯塔',
      rewardPoints: 150,
    ),
    MascotAchievement(
      id: 'tag_30',
      title: '万象观测',
      description: '建立 30 个不同的记忆节点',
      condition: AchievementCondition.uniqueTags,
      targetValue: 30,
      rewardTitle: '万象森罗',
      rewardPoints: 300,
      imagePath: 'assets/images/emoji/medal/medal14.png',
      medalScale: 1.2,
    ),
    MascotAchievement(
      id: 'active_10',
      title: '海岛访客',
      description: '累计活跃 10 天',
      condition: AchievementCondition.activeDays,
      targetValue: 10,
      rewardTitle: '海岛寄旅',
      rewardPoints: 20,
      imagePath: 'assets/images/emoji/medal/medal4.png',
      medalScale: 1.6,
    ),
    MascotAchievement(
      id: 'active_50',
      title: '海岛知己',
      description: '累计活跃达到 50 天',
      condition: AchievementCondition.activeDays,
      targetValue: 50,
      rewardTitle: '岛屿知己',
      rewardPoints: 100,
      imagePath: 'assets/images/emoji/medal/medal9.png',
      medalScale: 1.2,
    ),
    MascotAchievement(
      id: 'active_100',
      title: '时光漫游',
      description: '累计活跃达到 100 天',
      condition: AchievementCondition.activeDays,
      targetValue: 100,
      rewardTitle: '时光印记',
      rewardPoints: 300,
      imagePath: 'assets/images/emoji/medal/medal13.png',
      medalScale: 1.2,
    ),
    MascotAchievement(
      id: 'active_365',
      title: '永恒居民',
      description: '累计记录生活 365 天',
      condition: AchievementCondition.activeDays,
      targetValue: 365,
      rewardDecorationId: 'pink_long_tassel',
      rewardTitle: '永恒原色',
      rewardPoints: 800,
    ),
    MascotAchievement(
      id: 'moods_100',
      title: '心灵捕手',
      description: '累计进行了 100 次心情记录',
      condition: AchievementCondition.totalMoods,
      targetValue: 100,
      rewardTitle: '心灵捕手',
      rewardPoints: 80,
    ),
    MascotAchievement(
      id: 'moods_500',
      title: '灵魂观察',
      description: '累计进行了 500 次心情记录',
      condition: AchievementCondition.totalMoods,
      targetValue: 500,
      rewardTitle: '灵魂共振',
      rewardPoints: 400,
    ),
    MascotAchievement(
      id: 'moods_1000',
      title: '回声探索',
      description: '累计完成 1000 次心情倾诉',
      condition: AchievementCondition.totalMoods,
      targetValue: 1000,
      rewardDecorationId: 'red_reindeer',
      rewardTitle: '回声探源',
      rewardPoints: 1000,
    ),
    MascotAchievement(
      id: 'vip_level_1',
      title: '星河初航',
      description: '入驻星空岛，开启月度拾光之旅',
      condition: AchievementCondition.isResident,
      targetValue: 1,
      rewardTitle: '星海指引',
      rewardPoints: 10,
      imagePath: 'assets/images/emoji/medal/medal1.png',
      medalScale: 1.0,
    ),
    MascotAchievement(
      id: 'vip_level_2',
      title: '星河巡航',
      description: '点亮年度星河，与海岛长久同行',
      condition: AchievementCondition.vipLevel,
      targetValue: 2,
      rewardDecorationId: 'phoenix_crown',
      rewardTitle: '星海漫索',
      rewardPoints: 50,
    ),
    MascotAchievement(
      id: 'vip_level_3',
      title: '永恒观测',
      description: '刻下永恒印记，成为岛屿的终身守护',
      condition: AchievementCondition.vipLevel,
      targetValue: 3,
      rewardDecorationId: 'mask',
      rewardTitle: '永恒注脚',
      rewardPoints: 100,
    ),
    // --- 新增：眼镜系列成就 ---
    MascotAchievement(
      id: 'glasses_kitty_collection',
      title: '萌系视界',
      description: '累计活跃达到 3 天，开启粉色视界',
      condition: AchievementCondition.activeDays,
      targetValue: 3,
      rewardDecorationId: 'glasses_kitty',
      rewardTitle: '猫耳观察员',
      rewardPoints: 30,
    ),
    MascotAchievement(
      id: 'glasses_reindeer_logic',
      title: '林间跃动',
      description: '累计记录 15 篇日记，捕捉野性直觉',
      condition: AchievementCondition.totalDiaries,
      targetValue: 15,
      rewardDecorationId: 'glasses_reindeer',
      rewardTitle: '通灵鹿语',
      rewardPoints: 50,
    ),
    MascotAchievement(
      id: 'glasses_heart_passion',
      title: '炽热节拍',
      description: '累计记录 20 篇图文日记，镌刻热烈心动',
      condition: AchievementCondition.photoDiaries,
      targetValue: 20,
      rewardDecorationId: 'glasses_heart',
      rewardTitle: '热恋观察家',
      rewardPoints: 80,
    ),
    MascotAchievement(
      id: 'glasses_cupcake_sweet',
      title: '甜点美学',
      description: '连续记录 5 天日记，品味生活甘美',
      condition: AchievementCondition.maxStreak,
      targetValue: 5,
      rewardDecorationId: 'glasses_cupcake',
      rewardTitle: '糖份侦探',
      rewardPoints: 40,
      imagePath: 'assets/images/emoji/medal/medal17.png',
      medalScale: 1.2,
    ),
    MascotAchievement(
      id: 'glasses_pixel_geek',
      title: '极客视界',
      description: '累计字数达到 10000 字，洞察数字脉络',
      condition: AchievementCondition.totalWords,
      targetValue: 10000,
      rewardDecorationId: 'glasses_pixel',
      rewardTitle: '比特筑梦人',
      rewardPoints: 200,
    ),
    MascotAchievement(
      id: 'glasses_star_gazer',
      title: '星愿观测',
      description: '在深夜 0:00 - 4:00 记录 10 篇日记',
      condition: AchievementCondition.nightDiaries,
      targetValue: 10,
      rewardDecorationId: 'glasses_star',
      rewardTitle: '追星信使',
      rewardPoints: 60,
    ),
    MascotAchievement(
      id: 'glasses_bear_polar',
      title: '极地冰心',
      description: '入驻小岛成为高级居民 (VIP 2 级奖励)',
      condition: AchievementCondition.vipLevel,
      targetValue: 2,
      rewardDecorationId: 'glasses_bear',
      rewardTitle: '冰原守望者',
      rewardPoints: 100,
    ),
  ];

  /// 根据饰品 ID 查找成就说明
  static MascotAchievement? getByRewardId(String decorationId) {
    try {
      return allAchievements.firstWhere(
        (a) => a.rewardDecorationId == decorationId,
      );
    } catch (_) {
      return null;
    }
  }
}

/// 成就条件的颜色与图标统一定义（单一事实来源）
extension AchievementConditionStyle on AchievementCondition {
  /// 该类别成就的主题色
  Color get themeColor {
    switch (this) {
      case AchievementCondition.totalDiaries:
      case AchievementCondition.activeDays:
        return const Color(0xFF29B6E0); // 清晨蓝
      case AchievementCondition.maxStreak:
        return const Color(0xFFFF7043); // 火焰橙红
      case AchievementCondition.uniqueMoods:
      case AchievementCondition.totalMoods:
        return const Color(0xFFEC4899); // 玫粉
      case AchievementCondition.totalWords:
      case AchievementCondition.maxSingleWords:
        return const Color(0xFF6366F1); // 靛蓝
      case AchievementCondition.morningDiaries:
        return const Color(0xFFF59E0B); // 晨光金
      case AchievementCondition.nightDiaries:
        return const Color(0xFF818CF8); // 星夜紫
      case AchievementCondition.photoDiaries:
        return const Color(0xFFF97316); // 相机橙
      case AchievementCondition.uniqueTags:
        return const Color(0xFF10B981); // 翠绿
      case AchievementCondition.vipLevel:
        return const Color(0xFFFFB300); // 荣耀金
      case AchievementCondition.isResident:
        return const Color(0xFF6366F1); // 入驻蓝紫 (Indigo)
      case AchievementCondition.totalDecorationsOwned:
        return const Color(0xFF14B8A6); // 青色（与详情页 amber fallback 统一换为此色）
    }
  }

  /// 该类别成就的渐变
  LinearGradient get gradient {
    switch (this) {
      case AchievementCondition.totalDiaries:
      case AchievementCondition.activeDays:
        return const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF38BDF8), Color(0xFF34D399)],
        );
      case AchievementCondition.maxStreak:
        return const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFFFBBF24), Color(0xFFEF4444)],
        );
      case AchievementCondition.uniqueMoods:
      case AchievementCondition.totalMoods:
        return const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFF472B6), Color(0xFFA855F7)],
        );
      case AchievementCondition.totalWords:
      case AchievementCondition.maxSingleWords:
        return const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF6366F1), Color(0xFF22D3EE)],
        );
      case AchievementCondition.morningDiaries:
        return const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFFDE68A), Color(0xFFF59E0B)],
        );
      case AchievementCondition.nightDiaries:
        return const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFA5B4FC), Color(0xFF6366F1)],
        );
      case AchievementCondition.photoDiaries:
        return const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFFDA4AF), Color(0xFFF97316)],
        );
      case AchievementCondition.uniqueTags:
        return const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF4ADE80), Color(0xFF14B8A6)],
        );
      case AchievementCondition.vipLevel:
        return const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFFFD54F), Color(0xFFFF8F00)],
        );
      case AchievementCondition.isResident:
        return const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF818CF8), Color(0xFF6366F1)],
        );
      case AchievementCondition.totalDecorationsOwned:
        return const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF2DD4BF), Color(0xFF14B8A6)],
        );
    }
  }

  /// 该类别成就的图标
  IconData get icon {
    switch (this) {
      case AchievementCondition.totalDiaries:
        return Icons.import_contacts_rounded;
      case AchievementCondition.activeDays:
        return Icons.calendar_month_rounded;
      case AchievementCondition.maxStreak:
        return Icons.local_fire_department_rounded;
      case AchievementCondition.uniqueMoods:
        return Icons.bubble_chart_rounded;
      case AchievementCondition.totalMoods:
        return Icons.favorite_rounded;
      case AchievementCondition.totalWords:
        return Icons.history_edu_rounded;
      case AchievementCondition.maxSingleWords:
        return Icons.article_rounded;
      case AchievementCondition.morningDiaries:
        return Icons.wb_sunny_rounded;
      case AchievementCondition.nightDiaries:
        return Icons.nightlight_round;
      case AchievementCondition.photoDiaries:
        return Icons.photo_camera_rounded;
      case AchievementCondition.uniqueTags:
        return Icons.sell_rounded;
      case AchievementCondition.vipLevel:
        return Icons.workspace_premium_rounded;
      case AchievementCondition.isResident:
        return Icons.rocket_launch_rounded;
      case AchievementCondition.totalDecorationsOwned:
        return Icons.diamond_rounded;
    }
  }
}
