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
  static const _keySavedDiaries = 'saved_diaries';

  /// 用户的姓名（游戏内称称呼）
  final ValueNotifier<String> userName = ValueNotifier<String>('');

  /// 是否已完成新手引导
  final ValueNotifier<bool> hasFinishedOnboarding = ValueNotifier<bool>(false);

  /// 日记草稿暂存
  final ValueNotifier<DiaryDraft?> diaryDraft = ValueNotifier<DiaryDraft?>(
    null,
  );

  /// 已保存的日记列表
  final ValueNotifier<List<DiaryEntry>> savedDiaries =
      ValueNotifier<List<DiaryEntry>>([]);

  /// 记录当前日记信纸是否处于打开状态（用于标题显隐等联动动效）
  final ValueNotifier<bool> isDiarySheetOpen = ValueNotifier<bool>(false);

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
    List<Map<String, dynamic>>? blocks,
  }) async {
    final draft = DiaryDraft(
      moodIndex: moodIndex,
      intensity: intensity,
      content: content,
      blocks: blocks,
    );
    diaryDraft.value = draft;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyDraftContent, content);
    await prefs.setInt(_keyDraftMood, moodIndex);
    await prefs.setDouble(_keyDraftIntensity, intensity);
    if (blocks != null) {
      await prefs.setString(_keyDraftBlocks, jsonEncode(blocks));
    }
  }

  /// 清空草稿
  Future<void> clearDraft() async {
    diaryDraft.value = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyDraftContent);
    await prefs.remove(_keyDraftBlocks);
    await prefs.remove(_keyDraftMood);
    await prefs.remove(_keyDraftIntensity);
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

  /// 记录本次访问时间
  Future<void> recordVisit() async {
    final now = DateTime.now();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyLastVisit, now.toIso8601String());
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
    diaryDraft.dispose();
  }
}

/// 日记草稿模型
class DiaryDraft {
  final int moodIndex;
  final double intensity;
  final String content;
  final List<Map<String, dynamic>>? blocks; // 结构化分块数据

  DiaryDraft({
    required this.moodIndex,
    required this.intensity,
    required this.content,
    this.blocks,
  });
}
