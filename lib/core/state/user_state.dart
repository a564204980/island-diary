import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'dart:math' as math;
import 'package:island_diary/features/record/domain/models/diary_entry.dart';
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
  static const _keySavedDiaries = 'saved_diaries';
  static const _keyThemeMode = 'theme_mode'; // 新增主题模式键
  static const _keyRecordGuidance = 'has_seen_record_guidance'; // 记录页引导

  /// 主题模式枚举
  /// auto: 跟随时间, light: 强制日间, dark: 强制夜间
  final ValueNotifier<String> themeMode = ValueNotifier<String>('auto');

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

  /// 上次访问时间
  DateTime? lastVisitTime;

  /// 计算距离上次访问的天数
  int get daysSinceLastVisit {
    if (lastVisitTime == null) return 0;
    return DateTime.now().difference(lastVisitTime!).inDays;
  }

  /// 保存草稿
  Future<void> saveDraft({
    required int moodIndex,
    required double intensity,
    required String content,
    String? tag,
    String? weather,
    String? temp,
    String? location,
    String? customDate,
    String? customTime,
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
      blocks: blocks,
    );
    diaryDraft.value = draft;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyDraftContent, content);
    await prefs.setInt(_keyDraftMood, moodIndex);
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
  }

  /// 将当前草稿保存为正式日记并持久化
  Future<void> saveDiary() async {
    final draft = diaryDraft.value;
    if (draft == null) return;

    final now = DateTime.now();
    final List<Map<String, dynamic>> blocks = draft.blocks != null
        ? List<Map<String, dynamic>>.from(draft.blocks!)
        : [];

    // 检查今日是否已记录过（用于发放奖励）
    final bool isFirstToday = !savedDiaries.value.any(
      (e) =>
          e.dateTime.year == now.year &&
          e.dateTime.month == now.month &&
          e.dateTime.day == now.day,
    );

    if (isFirstToday) {
      // 随机抽取一个奖励
      final rewardKeys = DiaryUtils.rewardConfigs.keys.toList();
      final String randomKey =
          rewardKeys[math.Random().nextInt(rewardKeys.length)];
      final config = DiaryUtils.rewardConfigs[randomKey]!;

      // 插入奖励块到首位
      blocks.insert(0, {
        'id': 'reward_${now.millisecondsSinceEpoch}',
        'type': 'reward',
        'rewardId': randomKey,
        'path': config['path'],
        'name': config['name'],
      });
    }

    final newEntry = DiaryEntry(
      dateTime: now,
      moodIndex: draft.moodIndex,
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
    final prefs = await SharedPreferences.getInstance();
    final jsonList = savedDiaries.value.map((e) => e.toMap()).toList();
    await prefs.setString(_keySavedDiaries, jsonEncode(jsonList));

    // 保存后清空草稿
    await clearDraft();
  }

  /// 更新已有的日记
  Future<void> updateDiary(DiaryEntry entry) async {
    final newList = List<DiaryEntry>.from(savedDiaries.value);
    final index = newList.indexWhere((e) => e.id == entry.id);
    if (index != -1) {
      newList[index] = entry;
      savedDiaries.value = newList;

      // 持久化整个列表
      final prefs = await SharedPreferences.getInstance();
      final jsonList = savedDiaries.value.map((e) => e.toMap()).toList();
      await prefs.setString(_keySavedDiaries, jsonEncode(jsonList));
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

    // 加载主题模式
    final savedTheme = prefs.getString(_keyThemeMode) ?? 'auto';
    themeMode.value = savedTheme;

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
        moodIndex: prefs.getInt(_keyDraftMood) ?? 0,
        intensity: prefs.getDouble(_keyDraftIntensity) ?? 5.0,
        tag: prefs.getString(_keyDraftTag),
        weather: prefs.getString(_keyDraftWeather),
        temp: prefs.getString(_keyDraftTemp),
        location: prefs.getString(_keyDraftLocation),
        customDate: prefs.getString(_keyDraftCustomDate),
        customTime: prefs.getString(_keyDraftCustomTime),
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
  }

  void dispose() {
    userName.dispose();
    hasFinishedOnboarding.dispose();
    hasSeenRecordGuidance.dispose();
    diaryDraft.dispose();
  }
}

/// 日记草稿模型
class DiaryDraft {
  final int moodIndex;
  final double intensity;
  final String content;
  final String? tag;
  final String? weather;
  final String? temp;
  final String? location;
  final String? customDate;
  final String? customTime;
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
    this.blocks,
  });
}
