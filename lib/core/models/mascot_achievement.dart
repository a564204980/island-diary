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
          begin: Alignment.topLeft, end: Alignment.bottomRight,
          colors: [Color(0xFFFFF8F0), Color(0xFFF5E6D3)],
        );
      case TitleTier.silver:
        return const LinearGradient(
          begin: Alignment.topLeft, end: Alignment.bottomRight,
          colors: [Color(0xFFF8FAFC), Color(0xFFE2E8F0)],
        );
      case TitleTier.gold:
        return const LinearGradient(
          begin: Alignment.topLeft, end: Alignment.bottomRight,
          colors: [Color(0xFFFFFBEB), Color(0xFFFEF3C7)],
        );
      case TitleTier.platinum:
        return const LinearGradient(
          begin: Alignment.topLeft, end: Alignment.bottomRight,
          colors: [Color(0xFFECFDF5), Color(0xFFCCFBF1)],
        );
      case TitleTier.diamond:
        return const LinearGradient(
          begin: Alignment.topLeft, end: Alignment.bottomRight,
          colors: [Color(0xFFEDE9FE), Color(0xFFDDD6FE)],
        );
    }
  }

  /// 边框颜色
  Color get borderColor => color.withValues(alpha: 0.45);

  /// 等级徽标图标
  IconData get badge {
    switch (this) {
      case TitleTier.bronze:  return Icons.shield_rounded;
      case TitleTier.silver:  return Icons.star_rounded;
      case TitleTier.gold:    return Icons.emoji_events_rounded;
      case TitleTier.platinum: return Icons.diamond_rounded;
      case TitleTier.diamond: return Icons.auto_awesome_rounded;
    }
  }

  /// 饱和渐变（用于卡片背景、外部标签等）
  LinearGradient get cardGradient {
    switch (this) {
      case TitleTier.bronze:
        return const LinearGradient(
          begin: Alignment.topLeft, end: Alignment.bottomRight,
          colors: [Color(0xFF8EA0B2), Color(0xFF546778)],
        );
      case TitleTier.silver:
        return const LinearGradient(
          begin: Alignment.topLeft, end: Alignment.bottomRight,
          colors: [Color(0xFFD4924B), Color(0xFF8B5E35)],
        );
      case TitleTier.gold:
        return const LinearGradient(
          begin: Alignment.topLeft, end: Alignment.bottomRight,
          colors: [Color(0xFFFFCA28), Color(0xFFD46B00)],
        );
      case TitleTier.platinum:
        return const LinearGradient(
          begin: Alignment.topLeft, end: Alignment.bottomRight,
          colors: [Color(0xFF2DD4BF), Color(0xFF0D9488)],
        );
      case TitleTier.diamond:
        return const LinearGradient(
          begin: Alignment.topLeft, end: Alignment.bottomRight,
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
}

class MascotAchievement {
  final String id;
  final String title;
  final String description;
  final AchievementCondition condition;
  final int targetValue;
  final String? rewardDecorationId;
  final String? rewardTitle;
  final int rewardPoints;

  const MascotAchievement({
    required this.id,
    required this.title,
    required this.description,
    required this.condition,
    required this.targetValue,
    this.rewardDecorationId,
    this.rewardTitle,
    this.rewardPoints = 10,
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
    if (rewardPoints >= 51)  return TitleTier.silver;
    return TitleTier.bronze;
  }

  /// 全局成就注册表
  static const List<MascotAchievement> allAchievements = [
    MascotAchievement(
      id: 'first_diary',
      title: '初见小岛',
      description: '记录第 1 篇日记',
      condition: AchievementCondition.totalDiaries,
      targetValue: 1,
      rewardDecorationId: 'panda_hat',
      rewardTitle: '初语者',
      rewardPoints: 20,
    ),
    MascotAchievement(
      id: 'seven_days_milestone',
      title: '岛屿常客',
      description: '累计记录 7 篇日记',
      condition: AchievementCondition.totalDiaries,
      targetValue: 7,
      rewardTitle: '岛间行者',
      rewardPoints: 30,
    ),
    MascotAchievement(
      id: 'month_milestone',
      title: '月之印记',
      description: '累计记录 30 篇日记',
      condition: AchievementCondition.totalDiaries,
      targetValue: 30,
      rewardTitle: '时光拾荒者',
      rewardPoints: 100,
    ),
    MascotAchievement(
      id: 'three_days_streak',
      title: '坚持是光',
      description: '连续 3 天记录日记',
      condition: AchievementCondition.maxStreak,
      targetValue: 3,
      rewardTitle: '坚持之光',
      rewardPoints: 20,
    ),
    MascotAchievement(
      id: 'fifteen_days_streak',
      title: '守望者',
      description: '连续 15 天记录日记',
      condition: AchievementCondition.maxStreak,
      targetValue: 15,
      rewardTitle: '守望人',
      rewardPoints: 80,
    ),
    MascotAchievement(
      id: 'streak_30_days',
      title: '意志如钢',
      description: '连续 30 天记录日记',
      condition: AchievementCondition.maxStreak,
      targetValue: 30,
      rewardDecorationId: 'egret',
      rewardTitle: '孤独的旗手',
      rewardPoints: 200,
    ),
    MascotAchievement(
      id: 'mood_explorer',
      title: '五味人生',
      description: '记录过 5 种不同的情绪',
      condition: AchievementCondition.uniqueMoods,
      targetValue: 5,
      rewardTitle: '情绪收藏家',
      rewardPoints: 40,
    ),
    MascotAchievement(
      id: 'all_moods_explorer',
      title: '全味人生',
      description: '记录过全部 12 种不同的情绪',
      condition: AchievementCondition.uniqueMoods,
      targetValue: 12,
      rewardDecorationId: 'funny_tails',
      rewardTitle: '五味品鉴官',
      rewardPoints: 200,
    ),
    MascotAchievement(
      id: 'morning_ritual',
      title: '晨间之光',
      description: '在早上 5:00 - 10:00 记录 7 篇日记',
      condition: AchievementCondition.morningDiaries,
      targetValue: 7,
      rewardTitle: '晨曦猎人',
      rewardPoints: 50,
    ),
    MascotAchievement(
      id: 'night_soul',
      title: '深夜灵魂',
      description: '在凌晨 0:00 - 4:00 记录 5 篇日记',
      condition: AchievementCondition.nightDiaries,
      targetValue: 5,
      rewardTitle: '暗夜哲学家',
      rewardPoints: 50,
    ),
    MascotAchievement(
      id: 'long_diary_talker',
      title: '倾诉者',
      description: '单篇日记字数超过 500 字',
      condition: AchievementCondition.maxSingleWords,
      targetValue: 500,
      rewardTitle: '深海倾诉者',
      rewardPoints: 60,
    ),
    MascotAchievement(
      id: 'word_master',
      title: '万词汇海',
      description: '累计字数达到 5000 字',
      condition: AchievementCondition.totalWords,
      targetValue: 5000,
      rewardTitle: '文字炼金师',
      rewardPoints: 120,
    ),
    MascotAchievement(
      id: 'word_scholar',
      title: '墨染千秋',
      description: '累计字数达到 20000 字',
      condition: AchievementCondition.totalWords,
      targetValue: 20000,
      rewardDecorationId: 'snake_rabbit',
      rewardTitle: '墨染乾坤',
      rewardPoints: 300,
    ),
    MascotAchievement(
      id: 'fashion_icon',
      title: '时尚达人',
      description: '拥有 15 件以上的小软饰品',
      condition: AchievementCondition.totalDecorationsOwned,
      targetValue: 15,
      rewardTitle: '时尚弄潮儿',
      rewardPoints: 150,
    ),
    MascotAchievement(
      id: 'half_year_journey',
      title: '时光半载',
      description: '记录总数达到 180 篇日记',
      condition: AchievementCondition.totalDiaries,
      targetValue: 180,
      rewardDecorationId: 'luo_yan',
      rewardTitle: '时光吟游诗人',
      rewardPoints: 400,
    ),
    MascotAchievement(
      id: 'year_celebration',
      title: '周年庆典',
      description: '记录总数达到 365 篇日记',
      condition: AchievementCondition.totalDiaries,
      targetValue: 365,
      rewardTitle: '时光的见证者',
      rewardPoints: 1000,
    ),
    // --- 扩充 34 项新成就 ---
    // 日记阶梯扩充
    MascotAchievement(
      id: 'diaries_50',
      title: '海岛速记员',
      description: '累计记录 50 篇日记',
      condition: AchievementCondition.totalDiaries,
      targetValue: 50,
      rewardTitle: '灵感捕手',
      rewardPoints: 50,
    ),
    MascotAchievement(
      id: 'diaries_100',
      title: '百日墨香',
      description: '累计记录 100 篇日记',
      condition: AchievementCondition.totalDiaries,
      targetValue: 100,
      rewardTitle: '百日墨客',
      rewardPoints: 100,
    ),
    MascotAchievement(
      id: 'diaries_200',
      title: '岛屿史官',
      description: '累计记录 200 篇日记',
      condition: AchievementCondition.totalDiaries,
      targetValue: 200,
      rewardTitle: '文明记录官',
      rewardPoints: 200,
    ),
    MascotAchievement(
      id: 'diaries_500',
      title: '传世笔录',
      description: '累计记录 500 篇日记',
      condition: AchievementCondition.totalDiaries,
      targetValue: 500,
      rewardDecorationId: 'lucky_tiger',
      rewardTitle: '传世笔录人',
      rewardPoints: 500,
    ),
    MascotAchievement(
      id: 'diaries_1000',
      title: '不朽的记忆',
      description: '累计记录 1000 篇日记',
      condition: AchievementCondition.totalDiaries,
      targetValue: 1000,
      rewardDecorationId: 'chen_yu',
      rewardTitle: '不朽的见证',
      rewardPoints: 1000,
    ),

    // 连续天数扩充
    MascotAchievement(
      id: 'streak_50',
      title: '半百之约',
      description: '连续 50 天记录日记',
      condition: AchievementCondition.maxStreak,
      targetValue: 50,
      rewardTitle: '岁月同行者',
      rewardPoints: 120,
    ),
    MascotAchievement(
      id: 'streak_100',
      title: '百日同行',
      description: '连续 100 天记录日记',
      condition: AchievementCondition.maxStreak,
      targetValue: 100,
      rewardTitle: '长情陪伴者',
      rewardPoints: 300,
    ),
    MascotAchievement(
      id: 'streak_200',
      title: '岛屿羁绊',
      description: '连续 200 天记录日记',
      condition: AchievementCondition.maxStreak,
      targetValue: 200,
      rewardTitle: '意志的行旅',
      rewardPoints: 500,
    ),
    MascotAchievement(
      id: 'streak_365',
      title: '岁月的见证者',
      description: '连续 365 天记录日记',
      condition: AchievementCondition.maxStreak,
      targetValue: 365,
      rewardDecorationId: 'yellow_duck_hat',
      rewardTitle: '时光的信徒',
      rewardPoints: 1000,
    ),

    // 字数阶梯扩充
    MascotAchievement(
      id: 'single_word_1000',
      title: '文思泉涌',
      description: '单篇日记字数超过 1000 字',
      condition: AchievementCondition.maxSingleWords,
      targetValue: 1000,
      rewardTitle: '笔尖的舞者',
      rewardPoints: 150,
    ),
    MascotAchievement(
      id: 'total_word_50000',
      title: '五万言书',
      description: '累计字数达到 50000 字',
      condition: AchievementCondition.totalWords,
      targetValue: 50000,
      rewardTitle: '长篇叙事家',
      rewardPoints: 400,
    ),
    MascotAchievement(
      id: 'total_word_100000',
      title: '著作等身',
      description: '累计字数达到 100000 字',
      condition: AchievementCondition.totalWords,
      targetValue: 100000,
      rewardDecorationId: 'red_long_tassel',
      rewardTitle: '著作等身者',
      rewardPoints: 800,
    ),

    // 时间统计扩充
    MascotAchievement(
      id: 'morning_30',
      title: '晨曦守望',
      description: '晨间日记达到 30 篇',
      condition: AchievementCondition.morningDiaries,
      targetValue: 30,
      rewardTitle: '晨光拾忆人',
      rewardPoints: 80,
    ),
    MascotAchievement(
      id: 'morning_100',
      title: '光之追随者',
      description: '晨间日记达到 100 篇',
      condition: AchievementCondition.morningDiaries,
      targetValue: 100,
      rewardTitle: '朝阳追逐者',
      rewardPoints: 250,
    ),
    MascotAchievement(
      id: 'night_30',
      title: '星夜清寂',
      description: '深夜日记达到 30 篇',
      condition: AchievementCondition.nightDiaries,
      targetValue: 30,
      rewardTitle: '深夜织梦者',
      rewardPoints: 80,
    ),
    MascotAchievement(
      id: 'night_100',
      title: '夜之哲学家',
      description: '深夜日记达到 100 篇',
      condition: AchievementCondition.nightDiaries,
      targetValue: 100,
      rewardTitle: '星夜漫步家',
      rewardPoints: 250,
    ),

    // 饰品收藏扩充
    MascotAchievement(
      id: 'decorations_5',
      title: '初品格调',
      description: '拥有超过 5 件小软饰品',
      condition: AchievementCondition.totalDecorationsOwned,
      targetValue: 5,
      rewardTitle: '美学爱好者',
      rewardPoints: 20,
    ),
    MascotAchievement(
      id: 'decorations_10',
      title: '饰品收藏家',
      description: '拥有超过 10 件小软饰品',
      condition: AchievementCondition.totalDecorationsOwned,
      targetValue: 10,
      rewardTitle: '格调收藏家',
      rewardPoints: 60,
    ),
    MascotAchievement(
      id: 'decorations_25',
      title: '弄潮儿',
      description: '收集齐 25 件以上饰品',
      condition: AchievementCondition.totalDecorationsOwned,
      targetValue: 25,
      rewardTitle: '潮流先锋',
      rewardPoints: 400,
    ),

    // 新维度：图文日记
    MascotAchievement(
      id: 'photo_1',
      title: '瞬间定格',
      description: '记录第 1 篇图文日记',
      condition: AchievementCondition.photoDiaries,
      targetValue: 1,
      rewardTitle: '瞬间定格',
      rewardPoints: 10,
    ),
    MascotAchievement(
      id: 'photo_10',
      title: '快门记录者',
      description: '累计记录 10 篇图文日记',
      condition: AchievementCondition.photoDiaries,
      targetValue: 10,
      rewardTitle: '光影捕手',
      rewardPoints: 80,
    ),
    MascotAchievement(
      id: 'photo_50',
      title: '光影叙事手',
      description: '累计记录 50 篇图文日记',
      condition: AchievementCondition.photoDiaries,
      targetValue: 50,
      rewardDecorationId: 'lily_hat',
      rewardTitle: '光影叙事家',
      rewardPoints: 300,
    ),
    MascotAchievement(
      id: 'photo_100',
      title: '画卷编织者',
      description: '记录 100 篇精彩图文',
      condition: AchievementCondition.photoDiaries,
      targetValue: 100,
      rewardTitle: '画卷缔造者',
      rewardPoints: 600,
    ),

    // 新维度：标签探索
    MascotAchievement(
      id: 'tag_5',
      title: '分类学学徒',
      description: '使用 5 个不同的标签',
      condition: AchievementCondition.uniqueTags,
      targetValue: 5,
      rewardTitle: '秩序探索者',
      rewardPoints: 20,
    ),
    MascotAchievement(
      id: 'tag_15',
      title: '记忆导航员',
      description: '累计使用过 15 个不同标签',
      condition: AchievementCondition.uniqueTags,
      targetValue: 15,
      rewardTitle: '记忆导航员',
      rewardPoints: 150,
    ),
    MascotAchievement(
      id: 'tag_30',
      title: '万象观察者',
      description: '建立 30 个不同的记忆节点',
      condition: AchievementCondition.uniqueTags,
      targetValue: 30,
      rewardTitle: '万象观察家',
      rewardPoints: 300,
    ),

    // 新维度：活跃天数（总天数）
    MascotAchievement(
      id: 'active_10',
      title: '暂住客',
      description: '累计活跃 10 天',
      condition: AchievementCondition.activeDays,
      targetValue: 10,
      rewardTitle: '岛屿旅人',
      rewardPoints: 20,
    ),
    MascotAchievement(
      id: 'active_50',
      title: '岛屿老友',
      description: '累计活跃达到 50 天',
      condition: AchievementCondition.activeDays,
      targetValue: 50,
      rewardTitle: '岛屿老友',
      rewardPoints: 100,
    ),
    MascotAchievement(
      id: 'active_100',
      title: '时光长廊',
      description: '累计活跃达到 100 天',
      condition: AchievementCondition.activeDays,
      targetValue: 100,
      rewardTitle: '时光漫游家',
      rewardPoints: 300,
    ),
    MascotAchievement(
      id: 'active_365',
      title: '终身岛民',
      description: '累计记录生活 365 天',
      condition: AchievementCondition.activeDays,
      targetValue: 365,
      rewardDecorationId: 'pink_long_tassel',
      rewardTitle: '永恒居民',
      rewardPoints: 800,
    ),

    // 新维度：累计心情记录
    MascotAchievement(
      id: 'moods_100',
      title: '情绪观察员',
      description: '累计进行了 100 次心情记录',
      condition: AchievementCondition.totalMoods,
      targetValue: 100,
      rewardTitle: '心灵捕手',
      rewardPoints: 80,
    ),
    MascotAchievement(
      id: 'moods_500',
      title: '内在之镜',
      description: '累计进行了 500 次心情记录',
      condition: AchievementCondition.totalMoods,
      targetValue: 500,
      rewardTitle: '心灵之眼',
      rewardPoints: 400,
    ),
    MascotAchievement(
      id: 'moods_1000',
      title: '灵魂的回响',
      description: '累计完成 1000 次心情倾诉',
      condition: AchievementCondition.totalMoods,
      targetValue: 1000,
      rewardDecorationId: 'red_reindeer',
      rewardTitle: '灵魂共鸣者',
      rewardPoints: 1000,
    ),

    // --- 会员身份系列成就 ---
    MascotAchievement(
      id: 'vip_level_1',
      title: '星光初航',
      description: '入驻星空岛，开启月度拾光之旅',
      condition: AchievementCondition.vipLevel,
      targetValue: 1, // 级别 >= 1
      rewardDecorationId: 'butterfly_wreath',
      rewardTitle: '星河引路人',
      rewardPoints: 10,
    ),
    MascotAchievement(
      id: 'vip_level_2',
      title: '星河伴侣',
      description: '点亮年度星河，与海岛长久同行',
      condition: AchievementCondition.vipLevel,
      targetValue: 2, // 级别 >= 2
      rewardDecorationId: 'phoenix_crown',
      rewardTitle: '星河守护者',
      rewardPoints: 50,
    ),
    MascotAchievement(
      id: 'vip_level_3',
      title: '永恒守望者',
      description: '刻下永恒印记，成为岛屿的终身守护',
      condition: AchievementCondition.vipLevel,
      targetValue: 3, // 级别 == 3
      rewardDecorationId: 'mask',
      rewardTitle: '岛屿守护神',
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
          begin: Alignment.topLeft, end: Alignment.bottomRight,
          colors: [Color(0xFF38BDF8), Color(0xFF34D399)],
        );
      case AchievementCondition.maxStreak:
        return const LinearGradient(
          begin: Alignment.topCenter, end: Alignment.bottomCenter,
          colors: [Color(0xFFFBBF24), Color(0xFFEF4444)],
        );
      case AchievementCondition.uniqueMoods:
      case AchievementCondition.totalMoods:
        return const LinearGradient(
          begin: Alignment.topLeft, end: Alignment.bottomRight,
          colors: [Color(0xFFF472B6), Color(0xFFA855F7)],
        );
      case AchievementCondition.totalWords:
      case AchievementCondition.maxSingleWords:
        return const LinearGradient(
          begin: Alignment.topLeft, end: Alignment.bottomRight,
          colors: [Color(0xFF6366F1), Color(0xFF22D3EE)],
        );
      case AchievementCondition.morningDiaries:
        return const LinearGradient(
          begin: Alignment.topLeft, end: Alignment.bottomRight,
          colors: [Color(0xFFFDE68A), Color(0xFFF59E0B)],
        );
      case AchievementCondition.nightDiaries:
        return const LinearGradient(
          begin: Alignment.topLeft, end: Alignment.bottomRight,
          colors: [Color(0xFFA5B4FC), Color(0xFF6366F1)],
        );
      case AchievementCondition.photoDiaries:
        return const LinearGradient(
          begin: Alignment.topLeft, end: Alignment.bottomRight,
          colors: [Color(0xFFFDA4AF), Color(0xFFF97316)],
        );
      case AchievementCondition.uniqueTags:
        return const LinearGradient(
          begin: Alignment.topLeft, end: Alignment.bottomRight,
          colors: [Color(0xFF4ADE80), Color(0xFF14B8A6)],
        );
      case AchievementCondition.vipLevel:
        return const LinearGradient(
          begin: Alignment.topLeft, end: Alignment.bottomRight,
          colors: [Color(0xFFFFD54F), Color(0xFFFF8F00)],
        );
      case AchievementCondition.totalDecorationsOwned:
        return const LinearGradient(
          begin: Alignment.topLeft, end: Alignment.bottomRight,
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
      case AchievementCondition.totalDecorationsOwned:
        return Icons.diamond_rounded;
    }
  }
}
