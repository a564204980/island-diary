part of '../user_state.dart';

/// 2. 日记记录与存储模块
mixin DiaryMixin on ProfileMixin {
  final ValueNotifier<DiaryDraft?> diaryDraft = ValueNotifier<DiaryDraft?>(null);
  final ValueNotifier<List<DiaryEntry>> savedDiaries = ValueNotifier<List<DiaryEntry>>([]);
  final ValueNotifier<bool> isDiarySheetOpen = ValueNotifier<bool>(false);

  Future<void> loadDiaries(SharedPreferences prefs) async {
    final draftContent = prefs.getString(_K.draftContent);
    if (draftContent != null) {
      final blocksJson = prefs.getString(_K.draftBlocks);
      diaryDraft.value = DiaryDraft(
        content: draftContent,
        moodIndex: prefs.getInt(_K.draftMood),
        intensity: prefs.getDouble(_K.draftIntensity) ?? 5.0,
        tag: prefs.getString(_K.draftTag),
        weather: prefs.getString(_K.draftWeather),
        temp: prefs.getString(_K.draftTemp),
        location: prefs.getString(_K.draftLocation),
        customDate: prefs.getString(_K.draftCustomDate),
        customTime: prefs.getString(_K.draftCustomTime),
        dateTime: prefs.getString(_K.draftDateTime) != null ? DateTime.tryParse(prefs.getString(_K.draftDateTime)!) : null,
        blocks: blocksJson != null ? (jsonDecode(blocksJson) as List).map((e) => Map<String, dynamic>.from(e)).toList() : null,
        paperStyle: prefs.getString(_K.draftPaperStyle) ?? 'note1',
        isImageGrid: prefs.getBool(_K.draftIsImageGrid) ?? false,
        isMixedLayout: prefs.getBool(_K.draftIsMixedLayout) ?? (isVip.value && !(prefs.getBool(_K.draftIsImageGrid) ?? false)),
      );
    }
    
    final s = prefs.getString(_K.savedDiaries);
    if (s != null) {
      try {
        final decoded = jsonDecode(s) as List;
        final allEntries = decoded.map((e) => DiaryEntry.fromMap(Map<String, dynamic>.from(e))).toList();
        // 自动添加索引（如果不存在）
        for (int i = 0; i < allEntries.length; i++) {
          allEntries[i] = allEntries[i].copyWith(id: allEntries[i].id); 
        }
        savedDiaries.value = allEntries;
      } catch (e) {
        debugPrint('Error decoding saved diaries: $e');
      }
    }
  }

  Future<void> saveDraft({
    int? moodIndex, required double intensity, required String content, String? tag, String? weather, String? temp,
    String? location, String? customDate, String? customTime, DateTime? dateTime, List<Map<String, dynamic>>? blocks,
    String? paperStyle, bool? isImageGrid, bool? isMixedLayout,
  }) async {
    diaryDraft.value = DiaryDraft(
      moodIndex: moodIndex, intensity: intensity, content: content, tag: tag, weather: weather, temp: temp,
      location: location, customDate: customDate, customTime: customTime, dateTime: dateTime, blocks: blocks,
      paperStyle: paperStyle ?? 'note1', isImageGrid: isImageGrid ?? false, isMixedLayout: isMixedLayout ?? (isVip.value && !(isImageGrid ?? false)),
    );
    final sp = await SharedPreferences.getInstance();
    await sp.setString(_K.draftContent, content);
    await sp.setInt(_K.draftMood, moodIndex ?? -1);
    await sp.setDouble(_K.draftIntensity, intensity);
    tag != null ? await sp.setString(_K.draftTag, tag) : await sp.remove(_K.draftTag);
    if (blocks != null) {
      await sp.setString(_K.draftBlocks, jsonEncode(blocks));
    }
    weather != null ? await sp.setString(_K.draftWeather, weather) : await sp.remove(_K.draftWeather);
    temp != null ? await sp.setString(_K.draftTemp, temp) : await sp.remove(_K.draftTemp);
    location != null ? await sp.setString(_K.draftLocation, location) : await sp.remove(_K.draftLocation);
    customDate != null ? await sp.setString(_K.draftCustomDate, customDate) : await sp.remove(_K.draftCustomDate);
    customTime != null ? await sp.setString(_K.draftCustomTime, customTime) : await sp.remove(_K.draftCustomTime);
    dateTime != null ? await sp.setString(_K.draftDateTime, dateTime.toIso8601String()) : await sp.remove(_K.draftDateTime);
    paperStyle != null ? await sp.setString(_K.draftPaperStyle, paperStyle) : await sp.remove(_K.draftPaperStyle);
    isImageGrid != null ? await sp.setBool(_K.draftIsImageGrid, isImageGrid) : await sp.remove(_K.draftIsImageGrid);
    isMixedLayout != null ? await sp.setBool(_K.draftIsMixedLayout, isMixedLayout) : await sp.remove(_K.draftIsMixedLayout);
  }

  Future<void> clearDraft() async {
    diaryDraft.value = null;
    final sp = await SharedPreferences.getInstance();
    for (var key in [_K.draftContent, _K.draftBlocks, _K.draftMood, _K.draftIntensity, _K.draftTag, _K.draftWeather, _K.draftTemp, _K.draftLocation, _K.draftCustomDate, _K.draftCustomTime, _K.draftDateTime, _K.draftPaperStyle, _K.draftIsImageGrid, _K.draftIsMixedLayout]) {
      await sp.remove(key);
    }
  }

  Future<List<MascotAchievement>> saveDiary() async {
    final draft = diaryDraft.value;
    if (draft == null) {
      return [];
    }
    final newEntry = DiaryEntry(
      dateTime: draft.dateTime ?? DateTime.now(),
      moodIndex: draft.moodIndex!,
      intensity: draft.intensity,
      content: draft.content,
      tag: draft.tag,
      weather: draft.weather,
      temp: draft.temp,
      location: draft.location,
      customDate: draft.customDate,
      customTime: draft.customTime,
      blocks: draft.blocks ?? [],
      paperStyle: draft.paperStyle,
      isImageGrid: draft.isImageGrid,
      isMixedLayout: draft.isMixedLayout,
    );
    savedDiaries.value = [newEntry, ...savedDiaries.value];
    await _saveDiariesToStorage();
    await clearDraft();

    // 检查每日任务
    completeTaskIfType(DailyTaskType.writeDiary);

    // 检查是否有新成就达成
    if (this is AchievementMixin) {
      final newAchievements = await (this as AchievementMixin).checkAchievements();
      if (newAchievements.isNotEmpty) {
        notifyMascotEvent(MascotEvent(
          type: MascotEventType.achievementUnlocked,
          description: newAchievements.map((MascotAchievement e) => e.title).join('、'),
        ));
      }
      return newAchievements;
    }
    return [];
  }

  Future<void> addReplyToDiary(String diaryId, String content) async {
    final index = savedDiaries.value.indexWhere((e) => e.id == diaryId);
    if (index == -1) {
      return;
    }
    final entry = savedDiaries.value[index];
    final updatedEntry = DiaryEntry(
      id: entry.id, dateTime: entry.dateTime, moodIndex: entry.moodIndex, intensity: entry.intensity, content: entry.content,
      tag: entry.tag, blocks: entry.blocks, weather: entry.weather, temp: entry.temp, location: entry.location,
      customDate: entry.customDate, customTime: entry.customTime, replies: [...entry.replies, DiaryReply(content: content, dateTime: DateTime.now())],
      paperStyle: entry.paperStyle, isImageGrid: entry.isImageGrid, isMixedLayout: entry.isMixedLayout, isLiked: entry.isLiked,
    );
    savedDiaries.value = List.from(savedDiaries.value)..[index] = updatedEntry;
    await _saveDiariesToStorage();
  }

  Future<void> toggleLike(String diaryId) async {
    final index = savedDiaries.value.indexWhere((e) => e.id == diaryId);
    if (index == -1) {
      return;
    }
    final entry = savedDiaries.value[index];
    savedDiaries.value = List.from(savedDiaries.value)..[index] = DiaryEntry(
      id: entry.id, dateTime: entry.dateTime, moodIndex: entry.moodIndex, intensity: entry.intensity, content: entry.content,
      tag: entry.tag, blocks: entry.blocks, weather: entry.weather, temp: entry.temp, location: entry.location,
      customDate: entry.customDate, customTime: entry.customTime, replies: entry.replies, paperStyle: entry.paperStyle,
      isImageGrid: entry.isImageGrid, isMixedLayout: entry.isMixedLayout, isLiked: !entry.isLiked,
    );
    await _saveDiariesToStorage();
  }

  Future<void> deleteDiary(String diaryId) async {
    savedDiaries.value = savedDiaries.value.where((e) => e.id != diaryId).toList();
    await _saveDiariesToStorage();
  }

  Future<void> updateDiary(DiaryEntry entry) async {
    final index = savedDiaries.value.indexWhere((e) => e.id == entry.id);
    if (index != -1) {
      savedDiaries.value = List.from(savedDiaries.value)..[index] = entry;
      await _saveDiariesToStorage();
    }
  }

  Future<void> _saveDiariesToStorage() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_K.savedDiaries, jsonEncode(savedDiaries.value.map((e) => e.toMap()).toList()));
  }

  Future<void> clearAllDiaries() async {
    savedDiaries.value = [];
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_K.savedDiaries);
    if (this is AchievementMixin) {
      (this as AchievementMixin).checkAchievements();
    }
  }
}
