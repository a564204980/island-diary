part of '../user_state.dart';

/// 顶层函数：供 compute() 在后台 Isolate 中解析日记 JSON，避免阻塞主线程
List<DiaryEntry> _parseDiaryEntries(String jsonStr) {
  final decoded = jsonDecode(jsonStr) as List;
  return decoded.map((e) => DiaryEntry.fromMap(Map<String, dynamic>.from(e))).toList();
}

List<DiaryBook> _parseDiaryBooks(String jsonStr) {
  final decoded = jsonDecode(jsonStr) as List;
  return decoded.map((e) => DiaryBook.fromMap(Map<String, dynamic>.from(e))).toList();
}

mixin DiaryMixin on ProfileMixin {
  final ValueNotifier<DiaryDraft?> diaryDraft = ValueNotifier<DiaryDraft?>(null);
  final ValueNotifier<List<DiaryEntry>> savedDiaries = ValueNotifier<List<DiaryEntry>>([]);
  final ValueNotifier<List<DiaryBook>> savedBooks = ValueNotifier<List<DiaryBook>>([]);
  final ValueNotifier<bool> isDiarySheetOpen = ValueNotifier<bool>(false);

  Future<void> loadDiaries(SharedPreferences prefs) async {
    final draftContent = prefs.getString(UserState().n(_K.draftContent));
    if (draftContent != null) {
      final blocksJson = prefs.getString(UserState().n(_K.draftBlocks));
      diaryDraft.value = DiaryDraft(
        content: draftContent,
        moodIndex: prefs.getInt(UserState().n(_K.draftMood)),
        intensity: prefs.getDouble(UserState().n(_K.draftIntensity)) ?? 5.0,
        tag: prefs.getString(UserState().n(_K.draftTag)),
        weather: prefs.getString(UserState().n(_K.draftWeather)),
        temp: prefs.getString(UserState().n(_K.draftTemp)),
        location: prefs.getString(UserState().n(_K.draftLocation)),
        customDate: prefs.getString(UserState().n(_K.draftCustomDate)),
        customTime: prefs.getString(UserState().n(_K.draftCustomTime)),
        dateTime: prefs.getString(UserState().n(_K.draftDateTime)) != null ? DateTime.tryParse(prefs.getString(UserState().n(_K.draftDateTime))!) : null,
        blocks: blocksJson != null ? (jsonDecode(blocksJson) as List).map((e) => Map<String, dynamic>.from(e)).toList() : null,
        paperStyle: prefs.getString(UserState().n(_K.draftPaperStyle)) ?? 'note1',
        isImageGrid: prefs.getBool(UserState().n(_K.draftIsImageGrid)) ?? false,
        isMixedLayout: prefs.getBool(UserState().n(_K.draftIsMixedLayout)) ?? (isVip.value && !(prefs.getBool(UserState().n(_K.draftIsImageGrid)) ?? false)),
        bookId: prefs.getString(UserState().n(_K.draftBookId)) ?? 'default',
      );
    }
    
    final b = prefs.getString(UserState().n(_K.savedBooks));
    if (b != null) {
      try {
        final allBooks = await compute(_parseDiaryBooks, b);
        savedBooks.value = allBooks;
      } catch (e) {
        debugPrint('Error decoding saved books: $e');
      }
    }
    if (savedBooks.value.isEmpty) {
      final defaultBook = DiaryBook(
        id: 'default',
        name: '岛屿随笔',
        description: '默认日记本，记录岛屿的点滴日常',
        coverColorValue: 0xFF64B5F6,
        coverStyle: 0,
      );
      savedBooks.value = [defaultBook];
      await _saveBooksToStorage();
    }
    
    final s = prefs.getString(UserState().n(_K.savedDiaries));
    if (s != null) {
      try {
        // 使用 compute 将大量 JSON 解析移入后台 Isolate，避免阻塞主线程
        final allEntries = await compute(_parseDiaryEntries, s);
        savedDiaries.value = allEntries;
      } catch (e) {
        debugPrint('Error decoding saved diaries: $e');
      }
    }
  }

  Future<void> saveDraft({
    int? moodIndex, required double intensity, required String content, String? tag, String? weather, String? temp,
    String? location, String? customDate, String? customTime, DateTime? dateTime, List<Map<String, dynamic>>? blocks,
    String? paperStyle, bool? isImageGrid, bool? isMixedLayout, String? bookId,
  }) async {
    diaryDraft.value = DiaryDraft(
      moodIndex: moodIndex, intensity: intensity, content: content, tag: tag, weather: weather, temp: temp,
      location: location, customDate: customDate, customTime: customTime, dateTime: dateTime, blocks: blocks,
      paperStyle: paperStyle ?? 'note1', isImageGrid: isImageGrid ?? false, isMixedLayout: isMixedLayout ?? (isVip.value && !(isImageGrid ?? false)),
      bookId: bookId ?? 'default',
    );
    final sp = await SharedPreferences.getInstance();
    await sp.setString(UserState().n(_K.draftContent), content);
    await sp.setInt(UserState().n(_K.draftMood), moodIndex ?? -1);
    await sp.setDouble(UserState().n(_K.draftIntensity), intensity);
    tag != null ? await sp.setString(UserState().n(_K.draftTag), tag) : await sp.remove(UserState().n(_K.draftTag));
    if (blocks != null) {
      await sp.setString(UserState().n(_K.draftBlocks), jsonEncode(blocks));
    }
    weather != null ? await sp.setString(UserState().n(_K.draftWeather), weather) : await sp.remove(UserState().n(_K.draftWeather));
    temp != null ? await sp.setString(UserState().n(_K.draftTemp), temp) : await sp.remove(UserState().n(_K.draftTemp));
    location != null ? await sp.setString(UserState().n(_K.draftLocation), location) : await sp.remove(UserState().n(_K.draftLocation));
    customDate != null ? await sp.setString(UserState().n(_K.draftCustomDate), customDate) : await sp.remove(UserState().n(_K.draftCustomDate));
    customTime != null ? await sp.setString(UserState().n(_K.draftCustomTime), customTime) : await sp.remove(UserState().n(_K.draftCustomTime));
    dateTime != null ? await sp.setString(UserState().n(_K.draftDateTime), dateTime.toIso8601String()) : await sp.remove(UserState().n(_K.draftDateTime));
    paperStyle != null ? await sp.setString(UserState().n(_K.draftPaperStyle), paperStyle) : await sp.remove(UserState().n(_K.draftPaperStyle));
    isImageGrid != null ? await sp.setBool(UserState().n(_K.draftIsImageGrid), isImageGrid) : await sp.remove(UserState().n(_K.draftIsImageGrid));
    isMixedLayout != null ? await sp.setBool(UserState().n(_K.draftIsMixedLayout), isMixedLayout) : await sp.remove(UserState().n(_K.draftIsMixedLayout));
    bookId != null ? await sp.setString(UserState().n(_K.draftBookId), bookId) : await sp.remove(UserState().n(_K.draftBookId));
  }

  Future<void> clearDraft() async {
    diaryDraft.value = null;
    final sp = await SharedPreferences.getInstance();
    for (var key in [_K.draftContent, _K.draftBlocks, _K.draftMood, _K.draftIntensity, _K.draftTag, _K.draftWeather, _K.draftTemp, _K.draftLocation, _K.draftCustomDate, _K.draftCustomTime, _K.draftDateTime, _K.draftPaperStyle, _K.draftIsImageGrid, _K.draftIsMixedLayout, _K.draftBookId]) {
      await sp.remove(UserState().n(key));
    }
  }

  Future<List<dynamic>> saveDiary() async {
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
      bookId: draft.bookId,
    );
    savedDiaries.value = [newEntry, ...savedDiaries.value];
    await _saveDiariesToStorage();
    await clearDraft();

    // 检查每日任务
    completeTaskIfType(DailyTaskType.writeDiary);

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
      annotations: entry.annotations,
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
      annotations: entry.annotations,
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
    await prefs.setString(UserState().n(_K.savedDiaries), jsonEncode(savedDiaries.value.map((e) => e.toMap()).toList()));
  }

  Future<void> clearAllDiaries() async {
    savedDiaries.value = [];
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(UserState().n(_K.savedDiaries));
  }

  Future<void> generateMockDiaries() async {
    final List<DiaryEntry> mockEntries = [];
    final now = DateTime.now();
    for (int i = 0; i < 100; i++) {
      // 随机生成过去 90 天内的数据
      final randomDays = (i * 0.9).toInt() + (DateTime.now().millisecond % 3);
      final randomDate = now.subtract(Duration(days: randomDays, hours: i % 24, minutes: i % 60));
      
      mockEntries.add(DiaryEntry(
        dateTime: randomDate,
        moodIndex: i % 8, // 假设有 8 种心情
        intensity: ((i % 10) + 1).toDouble(), // 1.0 - 10.0
        content: '这是一条自动生成的测试日记内容。$i\n包含了一些随机的情感数据，用于调试图表和统计功能。',
        tag: i % 3 == 0 ? '测试标签${i % 5}' : null,
        blocks: [],
      ));
    }
    
    // 合并并按时间降序排序
    final allEntries = [...savedDiaries.value, ...mockEntries];
    allEntries.sort((a, b) => b.dateTime.compareTo(a.dateTime));
    
    savedDiaries.value = allEntries;
    await _saveDiariesToStorage();
  }

  Future<void> _saveBooksToStorage() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(UserState().n(_K.savedBooks), jsonEncode(savedBooks.value.map((e) => e.toMap()).toList()));
  }

  Future<void> createBook(DiaryBook book) async {
    savedBooks.value = [...savedBooks.value, book];
    await _saveBooksToStorage();
  }

  Future<void> updateBook(DiaryBook book) async {
    final idx = savedBooks.value.indexWhere((b) => b.id == book.id);
    if (idx != -1) {
      savedBooks.value = List.from(savedBooks.value)..[idx] = book;
      await _saveBooksToStorage();
    }
  }

  Future<void> deleteBook(String bookId) async {
    if (bookId == 'default') return;
    savedBooks.value = savedBooks.value.where((b) => b.id != bookId).toList();
    await _saveBooksToStorage();

    final updatedDiaries = savedDiaries.value.map((entry) {
      if (entry.bookId == bookId) {
        return entry.copyWith(bookId: 'default');
      }
      return entry;
    }).toList();
    savedDiaries.value = updatedDiaries;
    await _saveDiariesToStorage();
  }

  Future<void> moveDiariesToBook(List<String> diaryIds, String targetBookId) async {
    final updatedDiaries = savedDiaries.value.map((entry) {
      if (diaryIds.contains(entry.id)) {
        return entry.copyWith(bookId: targetBookId);
      }
      return entry;
    }).toList();
    savedDiaries.value = updatedDiaries;
    await _saveDiariesToStorage();
  }
}
