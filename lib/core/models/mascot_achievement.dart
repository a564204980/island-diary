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
}

class MascotAchievement {
  final String id;
  final String title;
  final String description;
  final AchievementCondition condition;
  final int targetValue;
  final String? rewardDecorationId;
  final int rewardPoints;

  const MascotAchievement({
    required this.id,
    required this.title,
    required this.description,
    required this.condition,
    required this.targetValue,
    this.rewardDecorationId,
    this.rewardPoints = 10,
  });

  /// 检查是否满足成就条件
  bool isMet(Map<String, int> stats) {
    final value = stats[condition.name] ?? 0;
    return value >= targetValue;
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
      rewardPoints: 20,
    ),
    MascotAchievement(
      id: 'seven_days_milestone',
      title: '岛屿常客',
      description: '累计记录 7 篇日记',
      condition: AchievementCondition.totalDiaries,
      targetValue: 7,
      rewardPoints: 30,
    ),
    MascotAchievement(
      id: 'month_milestone',
      title: '月之印记',
      description: '累计记录 30 篇日记',
      condition: AchievementCondition.totalDiaries,
      targetValue: 30,
      rewardPoints: 100,
    ),
    MascotAchievement(
      id: 'three_days_streak',
      title: '坚持是光',
      description: '连续 3 天记录日记',
      condition: AchievementCondition.maxStreak,
      targetValue: 3,
      rewardPoints: 20,
    ),
    MascotAchievement(
      id: 'fifteen_days_streak',
      title: '守望者',
      description: '连续 15 天记录日记',
      condition: AchievementCondition.maxStreak,
      targetValue: 15,
      rewardPoints: 80,
    ),
    MascotAchievement(
      id: 'streak_30_days',
      title: '意志如钢',
      description: '连续 30 天记录日记',
      condition: AchievementCondition.maxStreak,
      targetValue: 30,
      rewardDecorationId: 'egret',
      rewardPoints: 200,
    ),
    MascotAchievement(
      id: 'mood_explorer',
      title: '五味人生',
      description: '记录过 5 种不同的情绪',
      condition: AchievementCondition.uniqueMoods,
      targetValue: 5,
      rewardPoints: 40,
    ),
    MascotAchievement(
      id: 'all_moods_explorer',
      title: '全味人生',
      description: '记录过全部 12 种不同的情绪',
      condition: AchievementCondition.uniqueMoods,
      targetValue: 12,
      rewardDecorationId: 'funny_tails',
      rewardPoints: 200,
    ),
    MascotAchievement(
      id: 'morning_ritual',
      title: '晨间之光',
      description: '在早上 5:00 - 10:00 记录 7 篇日记',
      condition: AchievementCondition.morningDiaries,
      targetValue: 7,
      rewardPoints: 50,
    ),
    MascotAchievement(
      id: 'night_soul',
      title: '深夜灵魂',
      description: '在凌晨 0:00 - 4:00 记录 5 篇日记',
      condition: AchievementCondition.nightDiaries,
      targetValue: 5,
      rewardPoints: 50,
    ),
    MascotAchievement(
      id: 'long_diary_talker',
      title: '倾诉者',
      description: '单篇日记字数超过 500 字',
      condition: AchievementCondition.maxSingleWords,
      targetValue: 500,
      rewardPoints: 60,
    ),
    MascotAchievement(
      id: 'word_master',
      title: '万词汇海',
      description: '累计字数达到 5000 字',
      condition: AchievementCondition.totalWords,
      targetValue: 5000,
      rewardPoints: 120,
    ),
    MascotAchievement(
      id: 'word_scholar',
      title: '墨染千秋',
      description: '累计字数达到 20000 字',
      condition: AchievementCondition.totalWords,
      targetValue: 20000,
      rewardDecorationId: 'snake_rabbit',
      rewardPoints: 300,
    ),
    MascotAchievement(
      id: 'fashion_icon',
      title: '时尚达人',
      description: '拥有 15 件以上的小软饰品',
      condition: AchievementCondition.totalDecorationsOwned,
      targetValue: 15,
      rewardPoints: 150,
    ),
    MascotAchievement(
      id: 'half_year_journey',
      title: '时光半载',
      description: '记录总数达到 180 篇日记',
      condition: AchievementCondition.totalDiaries,
      targetValue: 180,
      rewardDecorationId: 'luo_yan',
      rewardPoints: 400,
    ),
    MascotAchievement(
      id: 'year_celebration',
      title: '周年庆典',
      description: '记录总数达到 365 篇日记',
      condition: AchievementCondition.totalDiaries,
      targetValue: 365,
      rewardDecorationId: 'phoenix_crown',
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
      rewardPoints: 50,
    ),
    MascotAchievement(
      id: 'diaries_100',
      title: '百日墨香',
      description: '累计记录 100 篇日记',
      condition: AchievementCondition.totalDiaries,
      targetValue: 100,
      rewardPoints: 100,
    ),
    MascotAchievement(
      id: 'diaries_200',
      title: '岛屿史官',
      description: '累计记录 200 篇日记',
      condition: AchievementCondition.totalDiaries,
      targetValue: 200,
      rewardPoints: 200,
    ),
    MascotAchievement(
      id: 'diaries_500',
      title: '传世笔录',
      description: '累计记录 500 篇日记',
      condition: AchievementCondition.totalDiaries,
      targetValue: 500,
      rewardDecorationId: 'lucky_tiger',
      rewardPoints: 500,
    ),
    MascotAchievement(
      id: 'diaries_1000',
      title: '不朽的记忆',
      description: '累计记录 1000 篇日记',
      condition: AchievementCondition.totalDiaries,
      targetValue: 1000,
      rewardDecorationId: 'chen_yu',
      rewardPoints: 1000,
    ),

    // 连续天数扩充
    MascotAchievement(
      id: 'streak_50',
      title: '半百之约',
      description: '连续 50 天记录日记',
      condition: AchievementCondition.maxStreak,
      targetValue: 50,
      rewardPoints: 120,
    ),
    MascotAchievement(
      id: 'streak_100',
      title: '百日同行',
      description: '连续 100 天记录日记',
      condition: AchievementCondition.maxStreak,
      targetValue: 100,
      rewardDecorationId: 'butterfly_wreath',
      rewardPoints: 300,
    ),
    MascotAchievement(
      id: 'streak_200',
      title: '岛屿羁绊',
      description: '连续 200 天记录日记',
      condition: AchievementCondition.maxStreak,
      targetValue: 200,
      rewardPoints: 500,
    ),
    MascotAchievement(
      id: 'streak_365',
      title: '岁月的见证者',
      description: '连续 365 天记录日记',
      condition: AchievementCondition.maxStreak,
      targetValue: 365,
      rewardDecorationId: 'yellow_duck_hat',
      rewardPoints: 1000,
    ),

    // 字数阶梯扩充
    MascotAchievement(
      id: 'single_word_1000',
      title: '文思泉涌',
      description: '单篇日记字数超过 1000 字',
      condition: AchievementCondition.maxSingleWords,
      targetValue: 1000,
      rewardPoints: 150,
    ),
    MascotAchievement(
      id: 'total_word_50000',
      title: '五万言书',
      description: '累计字数达到 50000 字',
      condition: AchievementCondition.totalWords,
      targetValue: 50000,
      rewardPoints: 400,
    ),
    MascotAchievement(
      id: 'total_word_100000',
      title: '著作等身',
      description: '累计字数达到 100000 字',
      condition: AchievementCondition.totalWords,
      targetValue: 100000,
      rewardDecorationId: 'red_long_tassel',
      rewardPoints: 800,
    ),

    // 时间统计扩充
    MascotAchievement(
      id: 'morning_30',
      title: '晨曦守望',
      description: '晨间日记达到 30 篇',
      condition: AchievementCondition.morningDiaries,
      targetValue: 30,
      rewardPoints: 80,
    ),
    MascotAchievement(
      id: 'morning_100',
      title: '光之追随者',
      description: '晨间日记达到 100 篇',
      condition: AchievementCondition.morningDiaries,
      targetValue: 100,
      rewardPoints: 250,
    ),
    MascotAchievement(
      id: 'night_30',
      title: '星夜清寂',
      description: '深夜日记达到 30 篇',
      condition: AchievementCondition.nightDiaries,
      targetValue: 30,
      rewardPoints: 80,
    ),
    MascotAchievement(
      id: 'night_100',
      title: '夜之哲学家',
      description: '深夜日记达到 100 篇',
      condition: AchievementCondition.nightDiaries,
      targetValue: 100,
      rewardPoints: 250,
    ),

    // 饰品收藏扩充
    MascotAchievement(
      id: 'decorations_5',
      title: '初品格调',
      description: '拥有超过 5 件小软饰品',
      condition: AchievementCondition.totalDecorationsOwned,
      targetValue: 5,
      rewardPoints: 20,
    ),
    MascotAchievement(
      id: 'decorations_10',
      title: '饰品收藏家',
      description: '拥有超过 10 件小软饰品',
      condition: AchievementCondition.totalDecorationsOwned,
      targetValue: 10,
      rewardPoints: 60,
    ),
    MascotAchievement(
      id: 'decorations_25',
      title: '弄潮儿',
      description: '收集齐 25 件以上饰品',
      condition: AchievementCondition.totalDecorationsOwned,
      targetValue: 25,
      rewardDecorationId: 'mask',
      rewardPoints: 400,
    ),

    // 新维度：图文日记
    MascotAchievement(
      id: 'photo_1',
      title: '瞬间定格',
      description: '记录第 1 篇图文日记',
      condition: AchievementCondition.photoDiaries,
      targetValue: 1,
      rewardPoints: 10,
    ),
    MascotAchievement(
      id: 'photo_10',
      title: '快门记录者',
      description: '累计记录 10 篇图文日记',
      condition: AchievementCondition.photoDiaries,
      targetValue: 10,
      rewardPoints: 80,
    ),
    MascotAchievement(
      id: 'photo_50',
      title: '光影叙事手',
      description: '累计记录 50 篇图文日记',
      condition: AchievementCondition.photoDiaries,
      targetValue: 50,
      rewardDecorationId: 'lily_hat',
      rewardPoints: 300,
    ),
    MascotAchievement(
      id: 'photo_100',
      title: '画卷编织者',
      description: '记录 100 篇精彩图文',
      condition: AchievementCondition.photoDiaries,
      targetValue: 100,
      rewardPoints: 600,
    ),

    // 新维度：标签探索
    MascotAchievement(
      id: 'tag_5',
      title: '分类学学徒',
      description: '使用 5 个不同的标签',
      condition: AchievementCondition.uniqueTags,
      targetValue: 5,
      rewardPoints: 20,
    ),
    MascotAchievement(
      id: 'tag_15',
      title: '记忆导航员',
      description: '累计使用过 15 个不同标签',
      condition: AchievementCondition.uniqueTags,
      targetValue: 15,
      rewardPoints: 150,
    ),
    MascotAchievement(
      id: 'tag_30',
      title: '万象观察者',
      description: '建立 30 个不同的记忆节点',
      condition: AchievementCondition.uniqueTags,
      targetValue: 30,
      rewardPoints: 300,
    ),

    // 新维度：活跃天数（总天数）
    MascotAchievement(
      id: 'active_10',
      title: '暂住客',
      description: '累计活跃 10 天',
      condition: AchievementCondition.activeDays,
      targetValue: 10,
      rewardPoints: 20,
    ),
    MascotAchievement(
      id: 'active_50',
      title: '岛屿老友',
      description: '累计活跃达到 50 天',
      condition: AchievementCondition.activeDays,
      targetValue: 50,
      rewardPoints: 100,
    ),
    MascotAchievement(
      id: 'active_100',
      title: '时光长廊',
      description: '累计活跃达到 100 天',
      condition: AchievementCondition.activeDays,
      targetValue: 100,
      rewardPoints: 300,
    ),
    MascotAchievement(
      id: 'active_365',
      title: '终身岛民',
      description: '累计记录生活 365 天',
      condition: AchievementCondition.activeDays,
      targetValue: 365,
      rewardDecorationId: 'pink_long_tassel',
      rewardPoints: 800,
    ),

    // 新维度：累计心情记录
    MascotAchievement(
      id: 'moods_100',
      title: '情绪观察员',
      description: '累计进行了 100 次心情记录',
      condition: AchievementCondition.totalMoods,
      targetValue: 100,
      rewardPoints: 80,
    ),
    MascotAchievement(
      id: 'moods_500',
      title: '内在之镜',
      description: '累计进行了 500 次心情记录',
      condition: AchievementCondition.totalMoods,
      targetValue: 500,
      rewardPoints: 400,
    ),
    MascotAchievement(
      id: 'moods_1000',
      title: '灵魂的回响',
      description: '累计完成 1000 次心情倾诉',
      condition: AchievementCondition.totalMoods,
      targetValue: 1000,
      rewardDecorationId: 'red_reindeer',
      rewardPoints: 1000,
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
