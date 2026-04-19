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

  static DailyTask? getHolidayTask(DateTime date) {
    final mmdd = "${date.month.toString().padLeft(2, '0')}${date.day.toString().padLeft(2, '0')}";
    
    if (mmdd == "0501" || mmdd == "0312") {
      return DailyTask(
        id: 'holiday_arbor_day',
        title: '森林守护者',
        description: '小岛的春天需要你的一份绿意。去小红书分享你的岛屿记录，集赞领取森林限定礼吧！',
        type: DailyTaskType.writeDiary,
        rewardPoints: 51,
        isHoliday: true,
        icon: 'assets/images/icons/leaf.png',
      );
    }
    
    // 其他节日逻辑可在此扩展...
    return null;
  }
}
