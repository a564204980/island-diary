import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'dart:math' as math;
import 'dart:typed_data';
import 'package:island_diary/features/record/domain/models/diary_entry.dart';
import 'package:island_diary/features/record/domain/models/placed_furniture.dart';
import 'package:island_diary/shared/widgets/diary_entry/utils/diary_utils.dart';

/// 全局单例用户状态管理
/// 采用轻量级的 ValueNotifier 实现，方便跨组件监听
class UserState {
  static final UserState _instance = UserState._internal();
  factory UserState() => _instance;
  UserState._internal();

  static const _keyUserName = 'user_name';
  static const _keyOnboarding = 'has_finished_onboarding';
  static const _keyLastVisit = 'last_visit_time';
  static const _keyDraftContent = 'diary_draft_content';
  static const _keyDraftBlocks = 'diary_draft_blocks'; // 新增分块数据键
  static const _keyDraftMood = 'diary_draft_mood';
  static const _keyDraftIntensity = 'diary_draft_intensity';
  static const _keyDraftTag = 'diary_draft_tag';
  static const _keyDraftWeather = 'diary_draft_weather';
  static const _keyDraftTemp = 'diary_draft_temp';
  static const _keyDraftLocation = 'diary_draft_location';
  static const _keyDraftCustomDate = 'diary_draft_custom_date';
  static const _keyDraftCustomTime = 'diary_draft_custom_time';
  static const _keyDraftDateTime = 'diary_draft_date_time'; // 新增：草稿特定的时间锚点
  static const _keySavedDiaries = 'saved_diaries';
  static const _keyThemeMode = 'theme_mode'; // 新增主题模式键
  static const _keyRecordGuidance = 'has_seen_record_guidance'; // 记录页引导
  static const _keyDecorationSnapshot = 'decoration_snapshot_bytes'; // 场景快照
  static const _keyPlacedFurniture = 'placed_furniture'; // 家具布局
  static const _keyMomentsCover = 'moments_cover_path'; // 朋友圈背景封面
  static const _keyDiaryLayoutMode = 'diary_layout_mode'; // 日记布局模式
  static const _keyWallColorLeft = 'wall_color_left'; // 左墙颜色
  static const _keyWallColorRight = 'wall_color_right'; // 右墙颜色
  static const _keyMoodTagHistory = 'mood_tag_history'; // 心情标签历史
  static const _keyStatsOrderWeek = 'stats_order_week'; // 统计模块顺序-周
  static const _keyStatsOrderMonth = 'stats_order_month'; // 统计模块顺序-月
  static const _keyStatsOrderAll = 'stats_order_all'; // 统计模块顺序-全
  static const _keyIsVip = 'is_vip'; // 新增：是否为 VIP
  static const _keyIsAppLockEnabled = 'is_app_lock_enabled'; // 应用锁
  static const _keyAppLockPin = 'app_lock_pin'; // PIN 码
  static const _keyIsBiometricEnabled = 'is_biometric_enabled'; // 生物识别
  static const _keyIsMistModeEnabled = 'is_mist_mode_enabled'; // 迷雾模式
  static const _keyDestructionCode = 'destruction_code'; // 自毁码



  /// 朋友圈背景封面 (本地图片路径或 null 使用默认)
  final ValueNotifier<String?> momentsCoverPath = ValueNotifier<String?>(null);

  /// 家具布局列表
  final ValueNotifier<List<PlacedFurniture>> placedFurniture = ValueNotifier<List<PlacedFurniture>>([]);

  /// 主题模式枚举
  /// auto: 跟随时间, light: 强制日间, dark: 强制夜间
  final ValueNotifier<String> themeMode = ValueNotifier<String>('auto');

  /// 日记布局模式 (由 DiaryHistoryOverlay 使用，需持久化)
  /// 0: timeline, 1: moments, 2: calendar
  final ValueNotifier<int> diaryLayoutMode = ValueNotifier<int>(0);

  /// 墙面颜色 (左、右)
  final ValueNotifier<Color> wallColorLeft = ValueNotifier<Color>(const Color(0xFFDEDCCE));
  final ValueNotifier<Color> wallColorRight = ValueNotifier<Color>(const Color(0xFFDEDCCE));

  /// 统一的日夜判断逻辑
  bool get isNight {
    if (themeMode.value == 'light') return false;
    if (themeMode.value == 'dark') return true;
    // auto 模式：遵循原有的时间逻辑
    final hour = DateTime.now().hour;
    return hour >= 17 || hour < 6;
  }

  /// 用户的姓名（游戏内称称呼）
  final ValueNotifier<String> userName = ValueNotifier<String>('');

  /// 是否已完成新手引导
  final ValueNotifier<bool> hasFinishedOnboarding = ValueNotifier<bool>(false);

  /// 是否已看过记录页引导
  final ValueNotifier<bool> hasSeenRecordGuidance = ValueNotifier<bool>(false);

  /// 日记草稿暂存
  final ValueNotifier<DiaryDraft?> diaryDraft = ValueNotifier<DiaryDraft?>(
    null,
  );

  /// 已保存的日记列表
  final ValueNotifier<List<DiaryEntry>> savedDiaries =
      ValueNotifier<List<DiaryEntry>>([]);

  /// 记录当前日记信纸是否处于打开状态（用于标题显隐等联动动效）
  final ValueNotifier<bool> isDiarySheetOpen = ValueNotifier<bool>(false);

  /// 记录小软是否在底部菜单中（记录页面小软跳出时设为 false）
  final ValueNotifier<bool> isSlimeInBottomMenu = ValueNotifier<bool>(true);

  /// 自定义心情标签历史
  final ValueNotifier<List<String>> moodTagHistory = ValueNotifier<List<String>>([]);

  /// 统计模块排序状态
  final ValueNotifier<List<String>> statsOrderWeek = ValueNotifier<List<String>>([]);
  final ValueNotifier<List<String>> statsOrderMonth = ValueNotifier<List<String>>([]);
  final ValueNotifier<List<String>> statsOrderAll = ValueNotifier<List<String>>([]);

  /// 是否为 VIP 永久居民
  final ValueNotifier<bool> isVip = ValueNotifier<bool>(false);

  // --- 安全设置 ---
  final ValueNotifier<bool> isAppLockEnabled = ValueNotifier<bool>(false);
  final ValueNotifier<String> appLockPin = ValueNotifier<String>('');
  final ValueNotifier<bool> isBiometricEnabled = ValueNotifier<bool>(false);
  final ValueNotifier<bool> isMistModeEnabled = ValueNotifier<bool>(false);
  final ValueNotifier<String> destructionCode = ValueNotifier<String>('');



  /// 装修场景快照数据 (Uint8List)
  final ValueNotifier<Uint8List?> decorationSnapshot = ValueNotifier<Uint8List?>(null);

  /// 上次访问时间
  DateTime? lastVisitTime;

  /// 计算距离上次访问的天数
  int get daysSinceLastVisit {
    if (lastVisitTime == null) return 0;
    return DateTime.now().difference(lastVisitTime!).inDays;
  }

  /// 保存草稿
  Future<void> saveDraft({
    int? moodIndex,
    required double intensity,
    required String content,
    String? tag,
    String? weather,
    String? temp,
    String? location,
    String? customDate,
    String? customTime,
    DateTime? dateTime,
    List<Map<String, dynamic>>? blocks,
  }) async {
    final draft = DiaryDraft(
      moodIndex: moodIndex,
      intensity: intensity,
      content: content,
      tag: tag,
      weather: weather,
      temp: temp,
      location: location,
      customDate: customDate,
      customTime: customTime,
      dateTime: dateTime,
      blocks: blocks,
    );
    diaryDraft.value = draft;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyDraftContent, content);
    await prefs.setInt(_keyDraftMood, moodIndex ?? -1);
    await prefs.setDouble(_keyDraftIntensity, intensity);
    if (tag != null) {
      await prefs.setString(_keyDraftTag, tag);
    } else {
      await prefs.remove(_keyDraftTag);
    }
    if (blocks != null) {
      await prefs.setString(_keyDraftBlocks, jsonEncode(blocks));
    }
    if (weather != null) await prefs.setString(_keyDraftWeather, weather);
    else await prefs.remove(_keyDraftWeather);
    if (temp != null) await prefs.setString(_keyDraftTemp, temp);
    else await prefs.remove(_keyDraftTemp);
    if (location != null) await prefs.setString(_keyDraftLocation, location);
    else await prefs.remove(_keyDraftLocation);
    if (customDate != null) await prefs.setString(_keyDraftCustomDate, customDate);
    else await prefs.remove(_keyDraftCustomDate);
    if (customTime != null) await prefs.setString(_keyDraftCustomTime, customTime);
    else await prefs.remove(_keyDraftCustomTime);
    if (dateTime != null) await prefs.setString(_keyDraftDateTime, dateTime.toIso8601String());
    else await prefs.remove(_keyDraftDateTime);
  }

  /// 清空草稿
  Future<void> clearDraft() async {
    diaryDraft.value = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyDraftContent);
    await prefs.remove(_keyDraftBlocks);
    await prefs.remove(_keyDraftMood);
    await prefs.remove(_keyDraftIntensity);
    await prefs.remove(_keyDraftTag);
    await prefs.remove(_keyDraftWeather);
    await prefs.remove(_keyDraftTemp);
    await prefs.remove(_keyDraftLocation);
    await prefs.remove(_keyDraftCustomDate);
    await prefs.remove(_keyDraftCustomTime);
    await prefs.remove(_keyDraftDateTime);
  }

  /// 将当前草稿保存为正式日记并持久化
  Future<void> saveDiary() async {
    final draft = diaryDraft.value;
    if (draft == null) return;

    final entryDate = draft.dateTime ?? DateTime.now();
    final List<Map<String, dynamic>> blocks = draft.blocks != null
        ? List<Map<String, dynamic>>.from(draft.blocks!)
        : [];

    // 检查今日是否已记录过（用于发放奖励）
    final bool isFirstToday = !savedDiaries.value.any(
      (e) =>
          e.dateTime.year == entryDate.year &&
          e.dateTime.month == entryDate.month &&
          e.dateTime.day == entryDate.day,
    );

    if (isFirstToday) {
      // 随机抽取一个奖励
      final rewardKeys = DiaryUtils.rewardConfigs.keys.toList();
      final String randomKey =
          rewardKeys[math.Random().nextInt(rewardKeys.length)];
      final config = DiaryUtils.rewardConfigs[randomKey]!;

      // 插入奖励块到首位
      blocks.insert(0, {
        'id': 'reward_${entryDate.millisecondsSinceEpoch}',
        'type': 'reward',
        'rewardId': randomKey,
        'path': config['path'],
        'name': config['name'],
      });
    }

    final newEntry = DiaryEntry(
      dateTime: entryDate,
      moodIndex: draft.moodIndex!,
      intensity: draft.intensity,
      content: draft.content,
      tag: draft.tag,
      weather: draft.weather,
      temp: draft.temp,
      location: draft.location,
      customDate: draft.customDate,
      customTime: draft.customTime,
      blocks: blocks,
    );

    // 更新内存列表
    final newList = List<DiaryEntry>.from(savedDiaries.value);
    newList.insert(0, newEntry); // 新日记放在最前面
    savedDiaries.value = newList;

    // 持久化整个列表
    await _saveDiariesToStorage();

    // 保存后清空草稿
    await clearDraft();
  }

  /// 为指定日记添加一条回复（感悟）
  Future<void> addReplyToDiary(String diaryId, String content) async {
    final index = savedDiaries.value.indexWhere((e) => e.id == diaryId);
    if (index == -1) return;

    final entry = savedDiaries.value[index];
    final newReply = DiaryReply(
      content: content,
      dateTime: DateTime.now(),
    );

    final updatedEntry = DiaryEntry(
      id: entry.id,
      dateTime: entry.dateTime,
      moodIndex: entry.moodIndex,
      intensity: entry.intensity,
      content: entry.content,
      tag: entry.tag,
      blocks: entry.blocks,
      weather: entry.weather,
      temp: entry.temp,
      location: entry.location,
      customDate: entry.customDate,
      customTime: entry.customTime,
      replies: [...entry.replies, newReply],
    );

    final newList = List<DiaryEntry>.from(savedDiaries.value);
    newList[index] = updatedEntry;
    savedDiaries.value = newList;

    await _saveDiariesToStorage();
  }

  /// 私有方法：同步日记列表到本地存储
  Future<void> _saveDiariesToStorage() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonList = savedDiaries.value.map((e) => e.toMap()).toList();
    await prefs.setString(_keySavedDiaries, jsonEncode(jsonList));
  }

  /// 更新已有的日记
  Future<void> updateDiary(DiaryEntry entry) async {
    final newList = List<DiaryEntry>.from(savedDiaries.value);
    final index = newList.indexWhere((e) => e.id == entry.id);
    if (index != -1) {
      newList[index] = entry;
      savedDiaries.value = newList;

      // 持久化整个列表
      await _saveDiariesToStorage();
    }
  }

  /// 删除日记
  Future<void> deleteDiary(DiaryEntry entry) async {
    final newList = List<DiaryEntry>.from(savedDiaries.value);
    newList.removeWhere((e) => e.id == entry.id);
    savedDiaries.value = newList;

    // 持久化整个列表
    final prefs = await SharedPreferences.getInstance();
    final jsonList = savedDiaries.value.map((e) => e.toMap()).toList();
    await prefs.setString(_keySavedDiaries, jsonEncode(jsonList));
  }

  /// 更新用户名称并持久化到本地
  Future<void> setUserName(String name) async {
    final trimmed = name.trim();
    if (trimmed.isNotEmpty) {
      userName.value = trimmed;
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_keyUserName, trimmed);
    }
  }

  /// 设置引导完成状态
  Future<void> completeOnboarding() async {
    hasFinishedOnboarding.value = true;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyOnboarding, true);
  }

  /// 设置记录页引导完成状态
  Future<void> completeRecordGuidance() async {
    hasSeenRecordGuidance.value = true;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyRecordGuidance, true);
  }

  /// 记录本次访问时间
  Future<void> recordVisit() async {
    final now = DateTime.now();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyLastVisit, now.toIso8601String());
  }

  /// 设置主题模式
  Future<void> setThemeMode(String mode) async {
    if (['auto', 'light', 'dark'].contains(mode)) {
      themeMode.value = mode;
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_keyThemeMode, mode);
    }
  }

  /// 设置并保存装修快照
  Future<void> setDecorationSnapshot(Uint8List? bytes) async {
    decorationSnapshot.value = bytes;
    final prefs = await SharedPreferences.getInstance();
    if (bytes != null) {
      await prefs.setString(_keyDecorationSnapshot, base64Encode(bytes));
    } else {
      await prefs.remove(_keyDecorationSnapshot);
    }
  }

  /// 保存家具布局
  Future<void> savePlacedFurniture(List<PlacedFurniture> list) async {
    placedFurniture.value = list;
    final prefs = await SharedPreferences.getInstance();
    final jsonList = list.map((e) => e.toMap()).toList();
    await prefs.setString(_keyPlacedFurniture, jsonEncode(jsonList));
  }

  /// 保存墙面颜色
  Future<void> saveWallColors(Color left, Color right) async {
    wallColorLeft.value = left;
    wallColorRight.value = right;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_keyWallColorLeft, left.value);
    await prefs.setInt(_keyWallColorRight, right.value);
  }

  /// 设置朋友圈背景封面
  Future<void> setMomentsCoverPath(String? path) async {
    momentsCoverPath.value = path;
    final prefs = await SharedPreferences.getInstance();
    if (path != null) {
      await prefs.setString(_keyMomentsCover, path);
    } else {
      await prefs.remove(_keyMomentsCover);
    }
  }

  /// 设置并保存日记布局模式
  Future<void> setDiaryLayoutMode(int mode) async {
    diaryLayoutMode.value = mode;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_keyDiaryLayoutMode, mode);
  }

  /// 添加并保存心情标签到历史
  Future<void> addMoodTag(String tag) async {
    final trimmed = tag.trim();
    if (trimmed.isEmpty) return;
    
    final currentList = List<String>.from(moodTagHistory.value);
    currentList.remove(trimmed); // 先移除旧的（如果是重复话），从而让它排到第一个
    currentList.insert(0, trimmed);
    
    // 最多保留 20 个
    if (currentList.length > 20) {
      currentList.removeLast();
    }
    
    moodTagHistory.value = currentList;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_keyMoodTagHistory, currentList);
  }

  /// 设置 VIP 状态并持久化
  Future<void> setIsVip(bool value) async {
    isVip.value = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyIsVip, value);
  }

  /// 批量更新安全设置
  Future<void> updateSecuritySettings({
    bool? appLock,
    String? pin,
    bool? biometric,
    bool? mistMode,
    String? destCode,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    if (appLock != null) {
      isAppLockEnabled.value = appLock;
      await prefs.setBool(_keyIsAppLockEnabled, appLock);
    }
    if (pin != null) {
      appLockPin.value = pin;
      await prefs.setString(_keyAppLockPin, pin);
    }
    if (biometric != null) {
      isBiometricEnabled.value = biometric;
      await prefs.setBool(_keyIsBiometricEnabled, biometric);
    }
    if (mistMode != null) {
      isMistModeEnabled.value = mistMode;
      await prefs.setBool(_keyIsMistModeEnabled, mistMode);
    }
    if (destCode != null) {
      destructionCode.value = destCode;
      await prefs.setString(_keyDestructionCode, destCode);
    }
  }

  /// 紧急自毁：清空所有本地数据
  Future<void> factoryReset() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    
    // 重置内存状态（除了 onboarding 以外可能需要根据逻辑调整）
    userName.value = '';
    isVip.value = false;
    isAppLockEnabled.value = false;
    appLockPin.value = '';
    isBiometricEnabled.value = false;
    isMistModeEnabled.value = false;
    destructionCode.value = '';
    savedDiaries.value = [];
    placedFurniture.value = [];
    diaryDraft.value = null;
    
    // 通常自毁后建议重启应用或引导回 Onboarding
  }



  /// 从本地存储中读取状态
  Future<void> loadFromStorage() async {
    final prefs = await SharedPreferences.getInstance();

    // 加载名称
    final savedName = prefs.getString(_keyUserName);
    if (savedName != null && savedName.isNotEmpty) {
      userName.value = savedName;
    }

    final finished = prefs.getBool(_keyOnboarding) ?? false;
    hasFinishedOnboarding.value = finished;

    final recordFinished = prefs.getBool(_keyRecordGuidance) ?? false;
    hasSeenRecordGuidance.value = recordFinished;

    // 加载朋友圈封面
    momentsCoverPath.value = prefs.getString(_keyMomentsCover);

    // 加载主题模式
    final savedTheme = prefs.getString(_keyThemeMode) ?? 'auto';
    themeMode.value = savedTheme;

    // 加载日记布局模式
    diaryLayoutMode.value = prefs.getInt(_keyDiaryLayoutMode) ?? 0;

    // 加载草稿
    final draftContent = prefs.getString(_keyDraftContent);
    if (draftContent != null) {
      final blocksJson = prefs.getString(_keyDraftBlocks);
      List<Map<String, dynamic>>? blocks;
      if (blocksJson != null) {
        try {
          final List<dynamic> decoded = jsonDecode(blocksJson);
          blocks = decoded.map((e) => Map<String, dynamic>.from(e)).toList();
        } catch (e) {
          debugPrint('Error decoding draft blocks: $e');
        }
      }

      diaryDraft.value = DiaryDraft(
        content: draftContent,
        moodIndex: (prefs.getInt(_keyDraftMood) ?? -1) == -1 ? null : prefs.getInt(_keyDraftMood),
        intensity: prefs.getDouble(_keyDraftIntensity) ?? 5.0,
        tag: prefs.getString(_keyDraftTag),
        weather: prefs.getString(_keyDraftWeather),
        temp: prefs.getString(_keyDraftTemp),
        location: prefs.getString(_keyDraftLocation),
        customDate: prefs.getString(_keyDraftCustomDate),
        customTime: prefs.getString(_keyDraftCustomTime),
        dateTime: prefs.getString(_keyDraftDateTime) != null ? DateTime.parse(prefs.getString(_keyDraftDateTime)!) : null,
        blocks: blocks,
      );
    }

    // 加载已保存的日记
    final savedJson = prefs.getString(_keySavedDiaries);
    if (savedJson != null) {
      try {
        final List<dynamic> decoded = jsonDecode(savedJson);
        savedDiaries.value = decoded
            .map((e) => DiaryEntry.fromMap(Map<String, dynamic>.from(e)))
            .toList();
      } catch (e) {
        debugPrint('Error decoding saved diaries: $e');
      }
    }

    // 加载家具布局
    final furnitureJson = prefs.getString(_keyPlacedFurniture);
    if (furnitureJson != null) {
      try {
        final List<dynamic> decoded = jsonDecode(furnitureJson);
        placedFurniture.value = decoded
            .map((e) => PlacedFurniture.fromMap(Map<String, dynamic>.from(e)))
            .toList();
      } catch (e) {
        debugPrint('Error decoding placed furniture: $e');
      }
    }

    // 加载快照
    final snapshotBase64 = prefs.getString(_keyDecorationSnapshot);
    if (snapshotBase64 != null) {
      try {
        decorationSnapshot.value = base64Decode(snapshotBase64);
      } catch (e) {
        debugPrint('Error decoding decoration snapshot: $e');
      }
    }

    // 加载墙面颜色
    final leftVal = prefs.getInt(_keyWallColorLeft);
    if (leftVal != null) wallColorLeft.value = Color(leftVal);
    final rightVal = prefs.getInt(_keyWallColorRight);
    if (rightVal != null) wallColorRight.value = Color(rightVal);

    // 加载心情标签历史
    moodTagHistory.value = prefs.getStringList(_keyMoodTagHistory) ?? [];

    // 加载统计页面模块排序
    statsOrderWeek.value = prefs.getStringList(_keyStatsOrderWeek) ?? [];
    statsOrderMonth.value = prefs.getStringList(_keyStatsOrderMonth) ?? [];
    statsOrderAll.value = prefs.getStringList(_keyStatsOrderAll) ?? [];

    // 加载 VIP 状态
    isVip.value = prefs.getBool(_keyIsVip) ?? false;

    // 加载安全设置
    isAppLockEnabled.value = prefs.getBool(_keyIsAppLockEnabled) ?? false;
    appLockPin.value = prefs.getString(_keyAppLockPin) ?? '';
    isBiometricEnabled.value = prefs.getBool(_keyIsBiometricEnabled) ?? false;
    isMistModeEnabled.value = prefs.getBool(_keyIsMistModeEnabled) ?? false;
    destructionCode.value = prefs.getString(_keyDestructionCode) ?? '';
  }



  /// 保存统计页面模块顺序
  Future<void> saveStatsOrder(String rangeType, List<String> newOrder) async {
    // 立即同步更新内存状态，防止 UI 渲染出现由于 await 导致的竞态回弹
    switch (rangeType) {
      case 'week':
        statsOrderWeek.value = newOrder;
        break;
      case 'month':
        statsOrderMonth.value = newOrder;
        break;
      case 'all':
        statsOrderAll.value = newOrder;
        break;
    }

    final prefs = await SharedPreferences.getInstance();
    switch (rangeType) {
      case 'week':
        await prefs.setStringList(_keyStatsOrderWeek, newOrder);
        break;
      case 'month':
        await prefs.setStringList(_keyStatsOrderMonth, newOrder);
        break;
      case 'all':
        await prefs.setStringList(_keyStatsOrderAll, newOrder);
        break;
    }
  }

  /// 重置统计页面排序
  Future<void> resetStatsOrder(String rangeType) async {
    final prefs = await SharedPreferences.getInstance();
    switch (rangeType) {
      case 'week':
        statsOrderWeek.value = [];
        await prefs.remove(_keyStatsOrderWeek);
        break;
      case 'month':
        statsOrderMonth.value = [];
        await prefs.remove(_keyStatsOrderMonth);
        break;
      case 'all':
        statsOrderAll.value = [];
        await prefs.remove(_keyStatsOrderAll);
        break;
    }
  }

  void dispose() {
    userName.dispose();
    hasFinishedOnboarding.dispose();
    hasSeenRecordGuidance.dispose();
    diaryDraft.dispose();
    isSlimeInBottomMenu.dispose();
  }
}

/// 日记草稿模型
class DiaryDraft {
  final int? moodIndex;
  final double intensity;
  final String content;
  final String? tag;
  final String? weather;
  final String? temp;
  final String? location;
  final String? customDate;
  final String? customTime;
  final DateTime? dateTime;
  final List<Map<String, dynamic>>? blocks; // 结构化分块数据

  DiaryDraft({
    required this.moodIndex,
    required this.intensity,
    required this.content,
    this.tag,
    this.weather,
    this.temp,
    this.location,
    this.customDate,
    this.customTime,
    this.dateTime,
    this.blocks,
  });
}
