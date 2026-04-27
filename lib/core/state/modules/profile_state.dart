part of '../user_state.dart';

/// 1. 用户资料与引导模块
mixin ProfileMixin {
  final ValueNotifier<String> userName = ValueNotifier<String>('');
  final ValueNotifier<String> userBio = ValueNotifier<String>('');
  final ValueNotifier<DateTime?> userBirthday = ValueNotifier<DateTime?>(null);
  final ValueNotifier<String> userGender = ValueNotifier<String>('secret');
  final ValueNotifier<bool> hasFinishedOnboarding = ValueNotifier<bool>(false);
  final ValueNotifier<bool> hasSeenRecordGuidance = ValueNotifier<bool>(false);
  final ValueNotifier<List<String>> selectedTitles = ValueNotifier<List<String>>([]);
  final ValueNotifier<int> vipLevel = ValueNotifier<int>(0);
  final ValueNotifier<bool> isVip = ValueNotifier<bool>(false); // Sync with vipLevel
  final ValueNotifier<DateTime?> vipExpireTime = ValueNotifier<DateTime?>(null);
  final ValueNotifier<String?> customAvatarPath = ValueNotifier<String?>(null);
  final ValueNotifier<String> themeMode = ValueNotifier<String>('auto');
  final ValueNotifier<String> deepseekApiKey = ValueNotifier<String>('sk-9860dceeff9240c4a497fb6fb7739d95');
  final ValueNotifier<String?> mascotThought = ValueNotifier<String?>(null);
  final ValueNotifier<String?> lastSoulInsight = ValueNotifier<String?>(null);
  final ValueNotifier<DailyTask?> dailyTask = ValueNotifier<DailyTask?>(null);
  final ValueNotifier<bool> isEventDrawerUnlocked = ValueNotifier<bool>(false);

  // 全局背景与主题色
  final ValueNotifier<String> currentBackgroundPath = ValueNotifier<String>('assets/images/home_xiatian_big.png');
  final ValueNotifier<Color> currentThemeColor = ValueNotifier<Color>(const Color(0xFFE6F3F5));
  Timer? _backgroundTimer;

  DateTime? lastVisitTime;
  String? lastSoulInsightDate;
  MascotEvent? _pendingDecorationEvent;

  bool get isNight {
    if (themeMode.value == 'light') {
      return false;
    }
    if (themeMode.value == 'dark') {
      return true;
    }
    final hour = DateTime.now().hour;
    return hour >= 17 || hour < 6;
  }

  int get daysSinceLastVisit {
    if (lastVisitTime == null) {
      return 0;
    }
    return DateTime.now().difference(lastVisitTime!).inDays;
  }

  void loadProfile(SharedPreferences prefs) {
    userName.value = prefs.getString(_K.userName) ?? '';
    userBio.value = prefs.getString(_K.userBio) ?? '';
    
    final birthdayStr = prefs.getString(_K.userBirthday);
    if (birthdayStr != null) {
      userBirthday.value = DateTime.tryParse(birthdayStr);
    }
    userGender.value = prefs.getString(_K.userGender) ?? 'secret';

    hasFinishedOnboarding.value = prefs.getBool(_K.onboarding) ?? false;
    hasSeenRecordGuidance.value = prefs.getBool(_K.recordGuidance) ?? false;
    final titles = prefs.getStringList(_K.selectedTitles);
    if (titles != null) {
      selectedTitles.value = titles;
    } else {
      final old = prefs.getString('selected_user_title_v1');
      if (old != null && old.isNotEmpty) {
        selectedTitles.value = [old];
      }
    }
    // Migration: if old isVip was true but vipLevel is 0, set to level 1
    int level = prefs.getInt(_K.vipLevel) ?? 0;
    bool oldVip = prefs.getBool(_K.isVip) ?? false;
    if (level == 0 && oldVip) {
      level = 1;
    }
    
    vipLevel.value = level;
    isVip.value = level > 0;
    
    themeMode.value = prefs.getString(_K.themeMode) ?? 'auto';
    deepseekApiKey.value = prefs.getString(_K.deepseekApiKey) ?? 'sk-9860dceeff9240c4a497fb6fb7739d95';
    final lastVisit = prefs.getString(_K.lastVisit);
    if (lastVisit != null) {
      lastVisitTime = DateTime.parse(lastVisit);
    }

    final expireStr = prefs.getString(_K.vipExpireTime);
    if (expireStr != null) {
      vipExpireTime.value = DateTime.tryParse(expireStr);
    }
    
    customAvatarPath.value = prefs.getString(_K.customAvatar);
    
    // 加载缓存的 AI 洞见
    lastSoulInsight.value = prefs.getString(_K.lastSoulInsight);
    lastSoulInsightDate = prefs.getString(_K.lastSoulInsightDate);
    
    // 加载每日任务
    final taskJson = prefs.getString(_K.currentDailyTask);
    if (taskJson != null) {
      try {
        dailyTask.value = DailyTask.fromMap(jsonDecode(taskJson));
      } catch (_) {}
    }
    _checkAndResetDailyTask(prefs);

    // 启动时执行一次过期检测
    checkVipExpiry(prefs);

    // 启动全局背景巡检
    updateDynamicBackground();
    _backgroundTimer?.cancel();
    _backgroundTimer = Timer.periodic(const Duration(minutes: 1), (_) {
      updateDynamicBackground();
    });
  }

  /// 根据时间自动切换背景与主题色
  void updateDynamicBackground() {
    if (themeMode.value == 'light') {
      currentBackgroundPath.value = 'assets/images/home_zhongwu_big.png';
      currentThemeColor.value = const Color(0xFFE6F3F5);
      return;
    }
    if (themeMode.value == 'dark') {
      currentBackgroundPath.value = 'assets/images/home_wanshang_big.png';
      currentThemeColor.value = const Color(0xFF0D1B2A);
      return;
    }

    final int hour = DateTime.now().hour;
    String newPath;
    Color newColor;

    if (hour >= 6 && hour < 11) {
      newPath = 'assets/images/home_xiatian_big.png';
      newColor = const Color(0xFFE6F3F5);
    } else if (hour >= 11 && hour < 17) {
      newPath = 'assets/images/home_zhongwu_big.png';
      newColor = const Color(0xFFE8F5E9); 
    } else {
      newPath = 'assets/images/home_wanshang_big.png';
      newColor = const Color(0xFF0D1B2A);
    }

    if (currentBackgroundPath.value != newPath) {
      currentBackgroundPath.value = newPath;
    }
    if (currentThemeColor.value != newColor) {
      currentThemeColor.value = newColor;
    }
  }

  void _checkAndResetDailyTask(SharedPreferences prefs) {
    // 【调试模式】极其强硬地强制开启劳动节任务，绕过所有判定
    final newTask = DailyTask.getHolidayTask(DateTime(2026, 5, 1))!;
    dailyTask.value = newTask;
    prefs.setString(_K.currentDailyTask, jsonEncode(newTask.toMap()));
    debugPrint("DAILY_TASK: 已执行极其强硬的强制重置 -> ${newTask.id}");
  }

  /// 允许外部手动触发任务完成（如查看统计页）
  void completeTaskIfType(DailyTaskType type) {
    final task = dailyTask.value;
    if (task != null && task.type == type && !task.isCompleted) {
      task.isCompleted = true;
      dailyTask.value = task;
      _saveDailyTask();
      debugPrint("DAILY_TASK: 任务状态更新 -> 已完成待领取");
    }
  }

  Future<void> claimTaskReward() async {
    final task = dailyTask.value;
    if (task != null && task.isCompleted && !task.isClaimed) {
      task.isClaimed = true;
      dailyTask.value = task;
      _saveDailyTask();
      
      // 增加成就点
      if (this is AchievementMixin) {
        (this as UserState).achievementPoints.value += task.rewardPoints;
        final prefs = await SharedPreferences.getInstance();
        await prefs.setInt(_K.achievementPoints, (this as UserState).achievementPoints.value);
      }
      
      debugPrint("DAILY_TASK: 奖励已领取 -> +${task.rewardPoints}点");
    }
  }

  void _saveDailyTask() async {
    if (dailyTask.value != null) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_K.currentDailyTask, jsonEncode(dailyTask.value!.toMap()));
      // 强制触发通知
      dailyTask.value = dailyTask.value;
    }
  }

  /// 检查会员是否已过期
  void checkVipExpiry(SharedPreferences prefs) {
    if (vipLevel.value == 0 || vipLevel.value == 3) {
      return; // 非会员或终身会员无需检查
    }
    
    final expireDate = vipExpireTime.value;
    if (expireDate != null && DateTime.now().isAfter(expireDate)) {
      // 已过期，重置状态
      vipLevel.value = 0;
      isVip.value = false;
      vipExpireTime.value = null;
      prefs.setInt(_K.vipLevel, 0);
      prefs.setBool(_K.isVip, false);
      prefs.remove(_K.vipExpireTime);
      debugPrint('Member status expired and reset.');
    }
  }

  Future<void> setUserName(String name) async {
    final trimmed = name.trim();
    userName.value = trimmed; // Allow empty
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_K.userName, trimmed);
  }

  Future<void> setUserBio(String bio) async {
    final trimmed = bio.trim();
    userBio.value = trimmed;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_K.userBio, trimmed);
  }

  Future<void> setUserBirthday(DateTime? birthday) async {
    userBirthday.value = birthday;
    final prefs = await SharedPreferences.getInstance();
    if (birthday != null) {
      await prefs.setString(_K.userBirthday, birthday.toIso8601String());
    } else {
      await prefs.remove(_K.userBirthday);
    }
  }

  Future<void> setUserGender(String gender) async {
    userGender.value = gender;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_K.userGender, gender);
  }

  Future<void> toggleTitle(String title) async {
    final list = List<String>.from(selectedTitles.value);
    if (list.contains(title)) {
      list.remove(title);
    } else {
      if (list.length >= 2) {
        list.removeAt(0); // 超过2个则踢掉最早的
      }
      list.add(title);
    }
    selectedTitles.value = list;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_K.selectedTitles, list);
  }

  /// 检查今天是否可以领取生日礼物
  Future<bool> checkAndClaimBirthdayGift() async {
    if (userBirthday.value == null) return false;
    
    final now = DateTime.now();
    final birthday = userBirthday.value!;
    
    // 检查月和日是否一致
    if (now.month == birthday.month && now.day == birthday.day) {
      final prefs = await SharedPreferences.getInstance();
      final lastYear = prefs.getInt(_K.lastBirthdayGiftYear) ?? 0;
      
      if (lastYear < now.year) {
        // 今年还没领过
        await prefs.setInt(_K.lastBirthdayGiftYear, now.year);
        return true;
      }
    }
    return false;
  }

  Future<void> setCustomAvatarPath(String? path) async {
    customAvatarPath.value = path;
    final prefs = await SharedPreferences.getInstance();
    if (path != null) {
      await prefs.setString(_K.customAvatar, path);
    } else {
      await prefs.remove(_K.customAvatar);
    }
  }

  Future<void> setIsVipLevel(int level) async {
    final now = DateTime.now();
    DateTime? newExpire;
    
    if (level == 1) { // 月度
      final currentExpire = (vipExpireTime.value != null && vipExpireTime.value!.isAfter(now)) 
          ? vipExpireTime.value! : now;
      newExpire = currentExpire.add(const Duration(days: 30));
    } else if (level == 2) { // 年度
      final currentExpire = (vipExpireTime.value != null && vipExpireTime.value!.isAfter(now)) 
          ? vipExpireTime.value! : now;
      newExpire = currentExpire.add(const Duration(days: 365));
    } else if (level == 3) { // 终身
      newExpire = null; // 终身会员没有过期时间
    }

    vipLevel.value = level;
    isVip.value = level > 0;
    vipExpireTime.value = newExpire;
    
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_K.vipLevel, level);
    await prefs.setBool(_K.isVip, level > 0);
    if (newExpire != null) {
      await prefs.setString(_K.vipExpireTime, newExpire.toIso8601String());
    } else {
      await prefs.remove(_K.vipExpireTime);
    }
  }

  // Deprecated: use setIsVipLevel instead
  Future<void> setIsVip(bool value) async {
    await setIsVipLevel(value ? 1 : 0);
  }

  Future<void> setThemeMode(String mode) async {
    if (['auto', 'light', 'dark'].contains(mode)) {
      themeMode.value = mode;
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_K.themeMode, mode);
    }
  }

  Future<void> completeOnboarding() async {
    hasFinishedOnboarding.value = true;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_K.onboarding, true);
  }

  Future<void> completeRecordGuidance() async {
    hasSeenRecordGuidance.value = true;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_K.recordGuidance, true);
  }

  Future<void> recordVisit() async {
    final now = DateTime.now();
    lastVisitTime = now;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_K.lastVisit, now.toIso8601String());
  }

  Future<void> setDeepseekApiKey(String key) async {
    deepseekApiKey.value = key;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_K.deepseekApiKey, key);
  }

  /// 保存 AI 生成的心灵深度分析结果
  Future<void> saveSoulInsight(String insight) async {
    final now = DateTime.now();
    final dateStr = "${now.year}-${now.month}-${now.day}";
    
    lastSoulInsight.value = insight;
    lastSoulInsightDate = dateStr;
    
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_K.lastSoulInsight, insight);
    await prefs.setString(_K.lastSoulInsightDate, dateStr);
    debugPrint("SOUL_INSIGHT: 分析结果已缓存 -> $dateStr");
  }

  /// 检查启动事件（时间、离别、节日）
  void checkAppStartEvents() {
    final now = DateTime.now();
    
    // 1. 时间段
    String timeLabel = "深夜";
    if (now.hour >= 5 && now.hour < 9) {
      timeLabel = "清晨";
    } else if (now.hour >= 9 && now.hour < 12) {
      timeLabel = "上午";
    } else if (now.hour >= 12 && now.hour < 14) {
      timeLabel = "正午";
    } else if (now.hour >= 14 && now.hour < 18) {
      timeLabel = "下午";
    } else if (now.hour >= 18 && now.hour < 23) {
      timeLabel = "晚上";
    }
    
    // 2. 离别天数
    final days = daysSinceLastVisit;
    
    // 3. 节日
    final holiday = _getHolidayInfo(now);
    
    // 构建上下文描述
    String ctx = "在$timeLabel打开了应用";
    if (days >= 3) {
      ctx += "，距离他上次已经过去了 $days 天，他好久没来了（如果你觉得很久的话）";
    }
    if (holiday != null) {
      ctx += "，而且今天还是 $holiday";
    }
    
    // 触发事件
    notifyMascotEvent(MascotEvent(
      type: MascotEventType.appStarted,
      description: ctx,
    ));
    
    // 刷新访问时间
    recordVisit();
  }

  String? _getHolidayInfo(DateTime now) {
    // 极简节日匹配
    final mmdd = "${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}";
    final Map<String, String> holidays = {
      "0101": "元旦",
      "0214": "情人节",
      "0501": "劳动节",
      "0601": "儿童节",
      "1001": "国庆节",
      "1225": "圣诞节",
    };
    
    // 检查用户生日
    if (userBirthday.value != null) {
      if (now.month == userBirthday.value!.month && now.day == userBirthday.value!.day) {
        return "他本人的生日";
      }
    }
    
    return holidays[mmdd];
  }

  /// 内部方法：触发小软的情感反应
  Future<void> notifyMascotEvent(MascotEvent event) async {
    // 换装相关的事件改为“挂起”模式，等到用户离开页面时再统一清算
    if (event.type == MascotEventType.decorationChanged) {
      debugPrint("AI_EVENT: 记录装扮变更事件 -> ${event.type}，等待退出时清算...");
      _pendingDecorationEvent = event;
      return;
    }

    // 其他即时类事件直接执行
    _executeMascotEvent(event);
  }

  /// 强制清算积压的装扮变更事件（通常在离开换装页时调用）
  void flushMascotEvent() {
    if (_pendingDecorationEvent != null) {
      debugPrint("AI_EVENT: 正在清算装扮变更事件...");
      _executeMascotEvent(_pendingDecorationEvent!);
      _pendingDecorationEvent = null;
    }
  }

  /// 真正的执行逻辑
  Future<void> _executeMascotEvent(MascotEvent event) async {
    debugPrint("AI_EVENT: 正在发送请求 -> ${event.type}");
    
    // 获取当前真实的形象路径
    String path = 'assets/images/emoji/marshmallow2.png';
    if (this is UserState) {
      path = (this as UserState).selectedMascotType.value;
    }

    // 异步获取不阻塞主线程
    try {
      final reply = await AIService().triggerEventReply(path, deepseekApiKey.value, event);
      debugPrint("AI_EVENT: AI 最终回复 -> $reply");
      if (reply.isNotEmpty) {
        mascotThought.value = reply;
      }
    } catch (e) {
      debugPrint("AI_EVENT: 请求执行失败 -> $e");
    }
  }
}
