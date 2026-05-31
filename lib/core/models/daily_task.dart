enum DailyTaskType {
  writeDiary,
  changeDecoration,
  viewStats,
  checkAchievements,
}

class DailyTask {
  final String id;
  final String title;
  final String description;
  final DailyTaskType type;
  final int rewardPoints;
  final bool isHoliday;
  final String? icon; // 节日特殊图标或挂件
  bool isCompleted;
  bool isClaimed;

  DailyTask({
    required this.id,
    required this.title,
    required this.description,
    required this.type,
    this.rewardPoints = 10,
    this.isHoliday = false,
    this.icon,
    this.isCompleted = false,
    this.isClaimed = false,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'type': type.index,
      'rewardPoints': rewardPoints,
      'isHoliday': isHoliday,
      'icon': icon,
      'isCompleted': isCompleted,
      'isClaimed': isClaimed,
    };
  }

  factory DailyTask.fromMap(Map<String, dynamic> map) {
    return DailyTask(
      id: map['id'],
      title: map['title'],
      description: map['description'],
      type: DailyTaskType.values[map['type']],
      rewardPoints: map['rewardPoints'],
      isHoliday: map['isHoliday'] ?? false,
      icon: map['icon'],
      isCompleted: map['isCompleted'] ?? false,
      isClaimed: map['isClaimed'] ?? false,
    );
  }

  static List<DailyTask> get pool => [
    DailyTask(
      id: 'task_diary',
      title: '笔耕不辍',
      description: '想听听你今天的故事，哪怕只有一小句...',
      type: DailyTaskType.writeDiary,
    ),
    DailyTask(
      id: 'task_deco',
      title: '焕然一新',
      description: '总觉得今天适合换个心情，要不要帮我挑件新衣服？',
      type: DailyTaskType.changeDecoration,
    ),
    DailyTask(
      id: 'task_stats',
      title: '回望足迹',
      description: '那些走过的日子里，其实藏着很多温暖的秘密呢。',
      type: DailyTaskType.viewStats,
    ),
    DailyTask(
      id: 'task_achieve',
      title: '荣誉殿堂',
      description: '看看你在这个小岛留下的每一个闪光点吧。',
      type: DailyTaskType.checkAchievements,
    ),
  ];

  static DailyTask getNormalTask(DateTime date) {
    final index = (date.year + date.month + date.day) % pool.length;
    return pool[index];
  }

  bool get isPreheating {
    if (!isHoliday) return false;
    final now = DateTime.now();
    if (id == 'holiday_arbor_day') {
      // 植树节：3月12日 - 3月14日，预热：3月9日 - 3月11日
      return now.month == 3 && now.day >= 9 && now.day <= 11;
    }
    if (id == 'holiday_labor_day') {
      // 劳动节：5月1日 - 5月5日，预热：4月28日 - 4月30日
      return now.month == 4 && now.day >= 28 && now.day <= 30;
    }
    return false;
  }

  static DailyTask? getHolidayTask(DateTime date) {
    final month = date.month;
    final day = date.day;

    // 植树节：3月12日 - 3月14日 (预热 3月9日 - 3月11日)
    if (month == 3 && day >= 9 && day <= 14) {
      return DailyTask(
        id: 'holiday_arbor_day',
        title: '森林守护者',
        description: '小岛的春天需要你的一份绿意。去小红书分享你的岛屿记录，集赞领取森林限定礼吧！',
        type: DailyTaskType.writeDiary,
        rewardPoints: 32,
        isHoliday: true,
        icon: 'assets/icons/calm.png',
      );
    }

    // 劳动节：5月1日 - 5月5日 (预热 4月28日 - 4月30日)
    final isLaborDayPeriod = (month == 4 && day >= 28 && day <= 30) || (month == 5 && day >= 1 && day <= 5);
    if (isLaborDayPeriod) {
      return DailyTask(
        id: 'holiday_labor_day',
        title: '致敬劳动者',
        description: '勤劳的手指能编织最美的岛屿梦。去小红书安利你的岛屿生活，集赞收获日出勋章！',
        type: DailyTaskType.writeDiary,
        rewardPoints: 51,
        isHoliday: true,
        icon: 'assets/icons/happy.png',
      );
    }
    return null;
  }

  /// 获取目前所有可用的节日活动任务
  static List<DailyTask> getAvailableEvents() {
    final now = DateTime.now();
    final List<DailyTask> activeEvents = [];

    // 检查植树节（包含预热期 3.9 - 3.14）
    if (now.month == 3 && now.day >= 9 && now.day <= 14) {
      activeEvents.add(DailyTask(
        id: 'holiday_arbor_day',
        title: '森林守护者',
        description: '小岛的春天需要你的一份绿意。去小红书分享你的岛屿记录，集赞领取森林限定礼吧！',
        type: DailyTaskType.writeDiary,
        rewardPoints: 32,
        isHoliday: true,
        icon: 'assets/icons/calm.png',
      ));
    }

    // 检查劳动节（包含预热期 4.28 - 5.5）
    final isLaborDayPeriod = (now.month == 4 && now.day >= 28 && now.day <= 30) || (now.month == 5 && now.day >= 1 && now.day <= 5);
    if (isLaborDayPeriod) {
      activeEvents.add(DailyTask(
        id: 'holiday_labor_day',
        title: '致敬劳动者',
        description: '勤劳的手指能编织最美的岛屿梦。去小红书安利你的岛屿生活，集赞收获日出勋章！',
        type: DailyTaskType.writeDiary,
        rewardPoints: 55,
        isHoliday: true,
        icon: 'assets/icons/happy.png',
      ));
    }

    return activeEvents;
  }
}
