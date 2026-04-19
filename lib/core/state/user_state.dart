import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:island_diary/features/record/domain/models/diary_entry.dart';
import 'package:island_diary/features/record/domain/models/placed_furniture.dart';
import 'package:island_diary/core/models/mascot_decoration.dart';
import 'package:island_diary/core/models/mascot_achievement.dart';
import 'package:island_diary/features/record/domain/models/diary_draft.dart';
import 'dart:typed_data';

/// 存贮键常量池
class _K {
  static const userName = 'user_name';
  static const onboarding = 'has_finished_onboarding';
  static const lastVisit = 'last_visit_time';
  static const draftContent = 'diary_draft_content';
  static const draftBlocks = 'diary_draft_blocks';
  static const draftMood = 'diary_draft_mood';
  static const draftIntensity = 'diary_draft_intensity';
  static const draftTag = 'diary_draft_tag';
  static const draftWeather = 'diary_draft_weather';
  static const draftTemp = 'diary_draft_temp';
  static const draftLocation = 'diary_draft_location';
  static const draftCustomDate = 'diary_draft_custom_date';
  static const draftCustomTime = 'diary_draft_custom_time';
  static const draftDateTime = 'diary_draft_date_time';
  static const draftPaperStyle = 'diary_draft_paper_style';
  static const draftIsImageGrid = 'diary_draft_is_image_grid';
  static const draftIsMixedLayout = 'diary_draft_is_mixed_layout';
  static const savedDiaries = 'saved_diaries';
  static const themeMode = 'theme_mode';
  static const recordGuidance = 'has_seen_record_guidance';
  static const decorationSnapshot = 'decoration_snapshot_bytes';
  static const placedFurniture = 'placed_furniture';
  static const momentsCover = 'moments_cover_path';
  static const diaryLayoutMode = 'diary_layout_mode';
  static const wallColorLeft = 'wall_color_left';
  static const wallColorRight = 'wall_color_right';
  static const moodTagHistory = 'mood_tag_history';
  static const statsOrderWeek = 'stats_order_week';
  static const statsOrderMonth = 'stats_order_month';
  static const statsOrderAll = 'stats_order_all';
  static const vipLevel = 'vip_level_v2';
  static const isVip = 'is_vip'; // Keep for migration
  static const isAppLockEnabled = 'is_app_lock_enabled';
  static const appLockPin = 'app_lock_pin';
  static const isBiometricEnabled = 'is_biometric_enabled';
  static const isMistModeEnabled = 'is_mist_mode_enabled';
  static const destructionCode = 'destruction_code';
  static const isScreenshotProtected = 'is_screenshot_protected';
  static const isIntruderCaptureEnabled = 'is_intruder_capture_enabled';
  static const autoLockDuration = 'auto_lock_duration';
  static const appIconType = 'app_icon_type';
  static const intruderLogs = 'intruder_logs';
  static const preferredPaperStyle = 'preferred_paper_style';
  static const preferredFontSize = 'preferred_font_size';
  static const preferredFontFamily = 'preferred_font_family';
  static const mascotDecoration = 'selected_mascot_decoration';
  static const ownedDecorations = 'owned_decoration_ids';
  static const achievementPoints = 'achievement_points';
  static const unlockedAchievementsMap = 'unlocked_achievements_v2';
  static const unlockedAchievements = 'unlocked_achievement_ids';
  static const vipExpireTime = 'vip_expire_time';
  static const customAvatar = 'custom_avatar_path';
  static const userBio = 'user_bio_v1';
  static const userBirthday = 'user_birthday';
  static const userGender = 'user_gender';
  static const lastBirthdayGiftYear = 'last_birthday_gift_year';
  static const selectedTitles = 'selected_user_titles_v2';
  static const mascotType = 'selected_mascot_type_v1';
  static const unlockedMascots = 'unlocked_mascot_paths_v1';
  static const isGlassesOverlayEnabled = 'is_glasses_overlay_enabled_v1';
  static const isGlassesAboveHat = 'is_glasses_above_hat_v1';
  static const selectedGlassesDecoration = 'selected_glasses_decoration_v1';
}

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
  DateTime? lastVisitTime;

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
    if (level == 0 && oldVip) level = 1;
    
    vipLevel.value = level;
    isVip.value = level > 0;
    
    themeMode.value = prefs.getString(_K.themeMode) ?? 'auto';
    final lastVisit = prefs.getString(_K.lastVisit);
    if (lastVisit != null) {
      lastVisitTime = DateTime.parse(lastVisit);
    }

    final expireStr = prefs.getString(_K.vipExpireTime);
    if (expireStr != null) {
      vipExpireTime.value = DateTime.tryParse(expireStr);
    }
    
    customAvatarPath.value = prefs.getString(_K.customAvatar);
    
    // 启动时执行一次过期检测
    checkVipExpiry(prefs);
  }

  /// 检查会员是否已过期
  void checkVipExpiry(SharedPreferences prefs) {
    if (vipLevel.value == 0 || vipLevel.value == 3) return; // 非会员或终身会员无需检查
    
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
}

/// 2. 日记与草稿管理模块
mixin DiaryMixin on ProfileMixin {
  final ValueNotifier<DiaryDraft?> diaryDraft = ValueNotifier<DiaryDraft?>(null);
  final ValueNotifier<List<DiaryEntry>> savedDiaries = ValueNotifier<List<DiaryEntry>>([]);
  final ValueNotifier<bool> isDiarySheetOpen = ValueNotifier<bool>(false);

  Future<void> loadDiaries(SharedPreferences prefs) async {
    final draftContent = prefs.getString(_K.draftContent);
    if (draftContent != null) {
      final blocksJson = prefs.getString(_K.draftBlocks);
      List<Map<String, dynamic>>? blocks;
      if (blocksJson != null) {
        try {
          final List<dynamic> decoded = jsonDecode(blocksJson);
          blocks = decoded.map((e) => Map<String, dynamic>.from(e)).toList();
        } catch (e) { debugPrint('Error decoding draft blocks: $e'); }
      }
      diaryDraft.value = DiaryDraft(
        content: draftContent,
        moodIndex: (prefs.getInt(_K.draftMood) ?? -1) == -1 ? null : prefs.getInt(_K.draftMood),
        intensity: prefs.getDouble(_K.draftIntensity) ?? 5.0,
        tag: prefs.getString(_K.draftTag),
        weather: prefs.getString(_K.draftWeather),
        temp: prefs.getString(_K.draftTemp),
        location: prefs.getString(_K.draftLocation),
        customDate: prefs.getString(_K.draftCustomDate),
        customTime: prefs.getString(_K.draftCustomTime),
        dateTime: prefs.getString(_K.draftDateTime) != null ? DateTime.parse(prefs.getString(_K.draftDateTime)!) : null,
        blocks: blocks,
        paperStyle: prefs.getString(_K.draftPaperStyle) ?? 'note1',
        isImageGrid: prefs.getBool(_K.draftIsImageGrid) ?? false,
        isMixedLayout: prefs.getBool(_K.draftIsMixedLayout) ?? (isVip.value && !(prefs.getBool(_K.draftIsImageGrid) ?? false)),
      );
    }

    final savedJson = prefs.getString(_K.savedDiaries);
    if (savedJson != null) {
      try {
        final List<dynamic> decoded = jsonDecode(savedJson);
        final allEntries = decoded.map((e) => DiaryEntry.fromMap(Map<String, dynamic>.from(e))).toList();
        for (var entry in allEntries) {
          entry.blocks.removeWhere((block) => block['type'] == 'image' && (block['path'] as String).contains('assets/images/residents/'));
        }
        savedDiaries.value = allEntries;
      } catch (e) { debugPrint('Error decoding saved diaries: $e'); }
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
    if (blocks != null) await sp.setString(_K.draftBlocks, jsonEncode(blocks));
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
    for (var key in [_K.draftContent, _K.draftBlocks, _K.draftMood, _K.draftIntensity, _K.draftTag, _K.draftWeather, _K.draftTemp, _K.draftLocation, _K.draftCustomDate, _K.draftCustomTime, _K.draftDateTime, _K.draftPaperStyle, _K.draftIsImageGrid, _K.draftIsMixedLayout]) { await sp.remove(key); }
  }

  static bool _debugForceClearOnce = false;

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

    // 检查是否有新成就达成
    if (this is AchievementMixin) {
      return await (this as AchievementMixin).checkAchievements();
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
    if (this is dynamic) {
      try {
        (this as dynamic).checkAchievements();
      } catch (_) {}
    }
  }
}

/// 3. 装修与场景装饰模块
mixin DecorationMixin {
  final ValueNotifier<List<PlacedFurniture>> placedFurniture = ValueNotifier<List<PlacedFurniture>>([]);
  final ValueNotifier<Color> wallColorLeft = ValueNotifier<Color>(const Color(0xFFDEDCCE));
  final ValueNotifier<Color> wallColorRight = ValueNotifier<Color>(const Color(0xFFDEDCCE));
  final ValueNotifier<Uint8List?> decorationSnapshot = ValueNotifier<Uint8List?>(null);

  Future<void> loadDecoration(SharedPreferences prefs) async {
    final snapshotBase64 = prefs.getString(_K.decorationSnapshot);
    if (snapshotBase64 != null) { try { decorationSnapshot.value = base64Decode(snapshotBase64); } catch (_) {} }
    final l = prefs.getInt(_K.wallColorLeft);
    if (l != null) {
      wallColorLeft.value = Color(l);
    }
    final r = prefs.getInt(_K.wallColorRight);
    if (r != null) {
      wallColorRight.value = Color(r);
    }
    final f = prefs.getString(_K.placedFurniture);
    if (f != null) {
      try {
        final decoded = jsonDecode(f) as List;
        placedFurniture.value = decoded.map((e) => PlacedFurniture.fromMap(Map<String, dynamic>.from(e))).where((pf) => !pf.item.imagePath.contains('assets/images/residents/')).toList();
      } catch (_) {}
    }
  }

  Future<void> setDecorationSnapshot(Uint8List? bytes) async {
    decorationSnapshot.value = bytes;
    final prefs = await SharedPreferences.getInstance();
    bytes != null ? await prefs.setString(_K.decorationSnapshot, base64Encode(bytes)) : await prefs.remove(_K.decorationSnapshot);
  }

  Future<void> savePlacedFurniture(List<PlacedFurniture> list) async {
    placedFurniture.value = list;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_K.placedFurniture, jsonEncode(list.map((e) => e.toMap()).toList()));
  }

  Future<void> saveWallColors(Color left, Color right) async {
    wallColorLeft.value = left; wallColorRight.value = right;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_K.wallColorLeft, left.toARGB32());
    await prefs.setInt(_K.wallColorRight, right.toARGB32());
  }
}

/// 4. 安全保障模块
mixin SecurityMixin {
  final ValueNotifier<bool> isAppLockEnabled = ValueNotifier<bool>(false);
  final ValueNotifier<String> appLockPin = ValueNotifier<String>('');
  final ValueNotifier<bool> isBiometricEnabled = ValueNotifier<bool>(false);
  final ValueNotifier<bool> isMistModeEnabled = ValueNotifier<bool>(false);
  final ValueNotifier<String> destructionCode = ValueNotifier<String>('');
  final ValueNotifier<bool> isScreenshotProtected = ValueNotifier<bool>(false);
  final ValueNotifier<bool> isIntruderCaptureEnabled = ValueNotifier<bool>(false);
  final ValueNotifier<int> autoLockDuration = ValueNotifier<int>(0);
  final ValueNotifier<String> appIconType = ValueNotifier<String>('default');
  final ValueNotifier<List<Map<String, dynamic>>> intruderLogs = ValueNotifier<List<Map<String, dynamic>>>([]);

  void loadSecurity(SharedPreferences prefs) {
    isAppLockEnabled.value = prefs.getBool(_K.isAppLockEnabled) ?? false;
    appLockPin.value = prefs.getString(_K.appLockPin) ?? '';
    isBiometricEnabled.value = prefs.getBool(_K.isBiometricEnabled) ?? false;
    isMistModeEnabled.value = prefs.getBool(_K.isMistModeEnabled) ?? false;
    destructionCode.value = prefs.getString(_K.destructionCode) ?? '';
    isScreenshotProtected.value = prefs.getBool(_K.isScreenshotProtected) ?? false;
    isIntruderCaptureEnabled.value = prefs.getBool(_K.isIntruderCaptureEnabled) ?? false;
    autoLockDuration.value = prefs.getInt(_K.autoLockDuration) ?? 0;
    appIconType.value = prefs.getString(_K.appIconType) ?? 'default';
    final l = prefs.getString(_K.intruderLogs);
    if (l != null) { try { intruderLogs.value = (jsonDecode(l) as List).map((e) => Map<String, dynamic>.from(e)).toList(); } catch (_) {} }
  }

  Future<void> updateSecuritySettings({bool? appLock, String? pin, bool? biometric, bool? mistMode, String? destCode}) async {
    final prefs = await SharedPreferences.getInstance();
    if (appLock != null) { isAppLockEnabled.value = appLock; await prefs.setBool(_K.isAppLockEnabled, appLock); }
    if (pin != null) { appLockPin.value = pin; await prefs.setString(_K.appLockPin, pin); }
    if (biometric != null) { isBiometricEnabled.value = biometric; await prefs.setBool(_K.isBiometricEnabled, biometric); }
    if (mistMode != null) { isMistModeEnabled.value = mistMode; await prefs.setBool(_K.isMistModeEnabled, mistMode); }
    if (destCode != null) { destructionCode.value = destCode; await prefs.setString(_K.destructionCode, destCode); }
  }

  Future<void> updateAdvancedSecurity({bool? screenshot, bool? intruder, int? lockDuration, String? iconType, Map<String, dynamic>? newIntruderLog}) async {
    final prefs = await SharedPreferences.getInstance();
    if (screenshot != null) { isScreenshotProtected.value = screenshot; await prefs.setBool(_K.isScreenshotProtected, screenshot); }
    if (intruder != null) { isIntruderCaptureEnabled.value = intruder; await prefs.setBool(_K.isIntruderCaptureEnabled, intruder); }
    if (lockDuration != null) { autoLockDuration.value = lockDuration; await prefs.setInt(_K.autoLockDuration, lockDuration); }
    if (iconType != null) { appIconType.value = iconType; await prefs.setString(_K.appIconType, iconType); }
    if (newIntruderLog != null) {
      final logs = [newIntruderLog, ...intruderLogs.value];
      if (logs.length > 50) {
        logs.removeLast();
      }
      intruderLogs.value = logs;
      await prefs.setString(_K.intruderLogs, jsonEncode(logs));
    }
  }
}

/// 5. 成就与统计模块
mixin AchievementMixin on DiaryMixin {
  final ValueNotifier<List<String>> ownedDecorationIds = ValueNotifier<List<String>>([]);
  final ValueNotifier<List<String>> unlockedMascotPaths = ValueNotifier<List<String>>([]);
  final ValueNotifier<int> achievementPoints = ValueNotifier<int>(0);
  final ValueNotifier<Map<String, String>> unlockedAchievements = ValueNotifier<Map<String, String>>({});

  Future<void> loadAchievement(SharedPreferences prefs) async {
    achievementPoints.value = prefs.getInt(_K.achievementPoints) ?? 0;
    final mapJson = prefs.getString(_K.unlockedAchievementsMap);
    if (mapJson != null) { try { unlockedAchievements.value = Map<String, String>.from(jsonDecode(mapJson)); } catch (_) {} }
    else {
      final old = prefs.getStringList(_K.unlockedAchievements);
      if (old != null) {
        final m = {for (var id in old) id: DateTime.now().toIso8601String()};
        unlockedAchievements.value = m; await prefs.setString(_K.unlockedAchievementsMap, jsonEncode(m));
      }
    }
    ownedDecorationIds.value = prefs.getStringList(_K.ownedDecorations) ?? _defaultOwnedIds;
    // 强制同步新增的眼镜：满足“全部解锁”需求
    final current = List<String>.from(ownedDecorationIds.value);
    bool added = false;
    for (var d in MascotDecoration.allDecorations) {
      if (d.category == MascotDecorationCategory.glasses && !current.contains(d.id)) {
        current.add(d.id);
        added = true;
      }
    }
    if (added) {
      ownedDecorationIds.value = current;
      prefs.setStringList(_K.ownedDecorations, current);
    }
    unlockedMascotPaths.value = prefs.getStringList(_K.unlockedMascots) ?? ['assets/images/emoji/marshmallow2.png'];
  }

  /// 同步奖励逻辑：确保所有已达成成就的对应奖励饰品都已加入拥有列表
  /// 常用于数据模型变更后的补偿（例如给老成就补发新奖励）
  Future<void> syncAchievementRewards() async {
    bool needsSync = false;
    final currentOwned = List<String>.from(ownedDecorationIds.value);
    final unlockedMap = unlockedAchievements.value;
    final currentMascots = List<String>.from(unlockedMascotPaths.value);
    
    // 强制解锁所有眼镜（满足用户特殊要求）
    for (var d in MascotDecoration.allDecorations) {
      if (d.category == MascotDecorationCategory.glasses && !currentOwned.contains(d.id)) {
        currentOwned.add(d.id);
        needsSync = true;
      }
    }

    for (var a in MascotAchievement.allAchievements) {
      if (unlockedMap.containsKey(a.id)) {
        if (a.rewardDecorationId != null && !currentOwned.contains(a.rewardDecorationId!)) {
          currentOwned.add(a.rewardDecorationId!);
          needsSync = true;
        }
        if (a.rewardMascotPath != null && !currentMascots.contains(a.rewardMascotPath!)) {
          currentMascots.add(a.rewardMascotPath!);
          needsSync = true;
        }
      }
    }

    if (needsSync) {
      ownedDecorationIds.value = currentOwned;
      unlockedMascotPaths.value = currentMascots;
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList(_K.ownedDecorations, currentOwned);
      await prefs.setStringList(_K.unlockedMascots, currentMascots);
      debugPrint('Decoration Rewards Synced: Unlocked glasses and rewards.');
    }
  }

  List<String> get _defaultOwnedIds {
    final rewards = MascotAchievement.allAchievements.map((a) => a.rewardDecorationId).whereType<String>().toSet();
    return MascotDecoration.allDecorations.map((d) => d.id).where((id) {
      final deco = MascotDecoration.allDecorations.where((de) => de.id == id).firstOrNull;
      if (deco == null) return false;
      // 眼镜全解锁，或者非成就奖励物品
      return deco.category == MascotDecorationCategory.glasses || !rewards.contains(id);
    }).toList();
  }

  Future<List<MascotAchievement>> checkAchievements() async {
    final stats = getAchievementStats();
    final m = Map<String, String>.from(unlockedAchievements.value);
    final o = List<String>.from(ownedDecorationIds.value);
    final mf = List<String>.from(unlockedMascotPaths.value);
    int p = 0;
    bool changed = false;
    List<MascotAchievement> newlyUnlocked = [];

    for (var a in MascotAchievement.allAchievements) {
      if (!m.containsKey(a.id) && a.isMet(stats)) {
        m[a.id] = DateTime.now().toIso8601String();
        p += a.rewardPoints;
        if (a.rewardDecorationId != null && !o.contains(a.rewardDecorationId!)) {
          o.add(a.rewardDecorationId!);
        }
        if (a.rewardMascotPath != null && !mf.contains(a.rewardMascotPath!)) {
          mf.add(a.rewardMascotPath!);
        }
        newlyUnlocked.add(a);
        changed = true;
      }
    }
    if (changed) {
      unlockedAchievements.value = m;
      ownedDecorationIds.value = o;
      unlockedMascotPaths.value = mf;
      achievementPoints.value += p;
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_K.unlockedAchievementsMap, jsonEncode(m));
      await prefs.setStringList(_K.ownedDecorations, o);
      await prefs.setStringList(_K.unlockedMascots, mf);
      await prefs.setInt(_K.achievementPoints, achievementPoints.value);
    }
    return newlyUnlocked;
  }

  /// [DEBUG] 一键解锁所有饰品、成就与会员权限 (仅供测试使用)
  Future<void> unlockAllForTesting() async {
    final prefs = await SharedPreferences.getInstance();
    final now = DateTime.now().toIso8601String();

    // 1. 解锁所有饰品 (动态覆盖分片库)
    final allDecoIds = MascotDecoration.allDecorations.map((d) => d.id).toList();
    ownedDecorationIds.value = allDecoIds;
    await prefs.setStringList(_K.ownedDecorations, allDecoIds);
    debugPrint('DEBUG: [Mascot] Total ${allDecoIds.length} decorations unlocked.');

    // 2. 解锁所有皮肤 (云织系列)
    final allMascots = [
      'assets/images/emoji/marshmallow.png',
      'assets/images/emoji/marshmallow2.png',
      'assets/images/emoji/marshmallow3.png',
      'assets/images/emoji/marshmallow4.png',
    ];
    unlockedMascotPaths.value = allMascots;
    await prefs.setStringList(_K.unlockedMascots, allMascots);

    // 3. 解锁所有成就并累计点数
    final allAchievementsMap = <String, String>{};
    int totalPoints = 0;
    for (var a in MascotAchievement.allAchievements) {
      allAchievementsMap[a.id] = now;
      totalPoints += a.rewardPoints;
    }
    unlockedAchievements.value = allAchievementsMap;
    achievementPoints.value = totalPoints;
    await prefs.setString(_K.unlockedAchievementsMap, jsonEncode(allAchievementsMap));
    await prefs.setInt(_K.achievementPoints, totalPoints);

    // 4. 解锁终身会员
    await setIsVipLevel(3);

    debugPrint('Debug: All items, achievements and VIP unlocked for testing.');
  }

  Map<String, int> getAchievementStats() {
    final diaries = savedDiaries.value; final stats = <String, int>{};
    stats[AchievementCondition.totalDiaries.name] = diaries.length;
    final dates = diaries.map((e) => DateTime(e.dateTime.year, e.dateTime.month, e.dateTime.day)).toSet().toList()..sort((a, b) => b.compareTo(a));
    int streak = 0, maxS = 0;
    if (dates.isNotEmpty) {
      streak = maxS = 1;
      for (int i = 0; i < dates.length - 1; i++) {
        if (dates[i].difference(dates[i + 1]).inDays == 1) {
          streak++;
          if (streak > maxS) {
            maxS = streak;
          }
        } else {
          streak = 1;
        }
      }
    }
    stats[AchievementCondition.maxStreak.name] = maxS;
    int tw = 0, mw = 0, mor = 0, nit = 0;
    for (var e in diaries) {
      int l = e.content.length;
      tw += l;
      if (l > mw) {
        mw = l;
      }
      int h = e.dateTime.hour;
      if (h >= 5 && h <= 10) {
        mor++;
      }
      if (h >= 0 && h <= 4) {
        nit++;
      }
    }
    stats[AchievementCondition.totalWords.name] = tw;
    stats[AchievementCondition.maxSingleWords.name] = mw;
    stats[AchievementCondition.morningDiaries.name] = mor;
    stats[AchievementCondition.nightDiaries.name] = nit;
    stats[AchievementCondition.photoDiaries.name] = diaries.where((e) => e.blocks.any((b) => b['type'] == 'image')).length;
    stats[AchievementCondition.uniqueTags.name] = diaries.where((e) => e.tag != null).map((e) => e.tag!).toSet().length;
    stats[AchievementCondition.activeDays.name] = dates.length;
    stats[AchievementCondition.totalMoods.name] = diaries.length;
    stats[AchievementCondition.uniqueMoods.name] = diaries.map((e) => e.moodIndex).whereType<int>().toSet().length;
    stats[AchievementCondition.totalDecorationsOwned.name] = ownedDecorationIds.value.length;
    stats[AchievementCondition.vipLevel.name] = vipLevel.value;
    stats[AchievementCondition.isResident.name] = 1; // 只要进入 app 即为入驻
    return stats;
  }
}

/// 6. 用户偏好与个性化模块
mixin PreferenceMixin {
  final ValueNotifier<String?> momentsCoverPath = ValueNotifier<String?>(null);
  final ValueNotifier<int> diaryLayoutMode = ValueNotifier<int>(0);
  final ValueNotifier<bool> isSlimeInBottomMenu = ValueNotifier<bool>(true);
  final ValueNotifier<List<String>> moodTagHistory = ValueNotifier<List<String>>([]);
  final ValueNotifier<List<String>> statsOrderWeek = ValueNotifier<List<String>>([]);
  final ValueNotifier<List<String>> statsOrderMonth = ValueNotifier<List<String>>([]);
  final ValueNotifier<List<String>> statsOrderAll = ValueNotifier<List<String>>([]);
  final ValueNotifier<String> preferredPaperStyle = ValueNotifier<String>('note1');
  final ValueNotifier<double> preferredFontSize = ValueNotifier<double>(20.0);
  final ValueNotifier<String> preferredFontFamily = ValueNotifier<String>('LXGWWenKai');
  final ValueNotifier<String?> selectedMascotDecoration = ValueNotifier<String?>(null);
  final ValueNotifier<String?> selectedGlassesDecoration = ValueNotifier<String?>(null);
  final ValueNotifier<bool> isGlassesOverlayEnabled = ValueNotifier<bool>(false);
  final ValueNotifier<bool> isGlassesAboveHat = ValueNotifier<bool>(true);
  // 新增：记录最后一次交互是否为眼镜类饰品
  bool _lastInteractedIsGlasses = false;
  final ValueNotifier<String> selectedMascotType = ValueNotifier<String>('assets/images/emoji/marshmallow2.png');

  void loadPreference(SharedPreferences prefs) {
    momentsCoverPath.value = prefs.getString(_K.momentsCover);
    diaryLayoutMode.value = prefs.getInt(_K.diaryLayoutMode) ?? 0;
    moodTagHistory.value = prefs.getStringList(_K.moodTagHistory) ?? [];
    statsOrderWeek.value = prefs.getStringList(_K.statsOrderWeek) ?? [];
    statsOrderMonth.value = prefs.getStringList(_K.statsOrderMonth) ?? [];
    statsOrderAll.value = prefs.getStringList(_K.statsOrderAll) ?? [];
    preferredPaperStyle.value = prefs.getString(_K.preferredPaperStyle) ?? 'note1';
    preferredFontSize.value = prefs.getDouble(_K.preferredFontSize) ?? 20.0;
    preferredFontFamily.value = prefs.getString(_K.preferredFontFamily) ?? 'LXGWWenKai';
    selectedMascotDecoration.value = prefs.getString(_K.mascotDecoration);
    selectedGlassesDecoration.value = prefs.getString(_K.selectedGlassesDecoration);
    isGlassesOverlayEnabled.value = prefs.getBool(_K.isGlassesOverlayEnabled) ?? false;
    isGlassesAboveHat.value = prefs.getBool(_K.isGlassesAboveHat) ?? true;
    selectedMascotType.value = prefs.getString(_K.mascotType) ?? 'assets/images/emoji/marshmallow2.png';
  }

  Future<void> setMomentsCoverPath(String? path) async { momentsCoverPath.value = path; final p = await SharedPreferences.getInstance(); path != null ? await p.setString(_K.momentsCover, path) : await p.remove(_K.momentsCover); }
  Future<void> setDiaryLayoutMode(int mode) async { diaryLayoutMode.value = mode; final p = await SharedPreferences.getInstance(); await p.setInt(_K.diaryLayoutMode, mode); }
  Future<void> addMoodTag(String tag) async {
    final t = tag.trim();
    if (t.isEmpty) {
      return;
    }
    final l = List<String>.from(moodTagHistory.value)..remove(t)..insert(0, t);
    if (l.length > 20) {
      l.removeLast();
    }
    moodTagHistory.value = l;
    final p = await SharedPreferences.getInstance();
    await p.setStringList(_K.moodTagHistory, l);
  }
  Future<void> saveStatsOrder(String range, List<String> order) async {
    if (range == 'week') {
      statsOrderWeek.value = order;
    } else if (range == 'month') {
      statsOrderMonth.value = order;
    } else {
      statsOrderAll.value = order;
    }
    final p = await SharedPreferences.getInstance();
    final k = range == 'week'
        ? _K.statsOrderWeek
        : (range == 'month' ? _K.statsOrderMonth : _K.statsOrderAll);
    await p.setStringList(k, order);
  }
  Future<void> resetStatsOrder(String range) async {
    final p = await SharedPreferences.getInstance();
    final k = range == 'week'
        ? _K.statsOrderWeek
        : (range == 'month' ? _K.statsOrderMonth : _K.statsOrderAll);
    if (range == 'week') {
      statsOrderWeek.value = [];
    } else if (range == 'month') {
      statsOrderMonth.value = [];
    } else {
      statsOrderAll.value = [];
    }
    await p.remove(k);
  }
  Future<void> setPreferredPaperStyle(String s) async { preferredPaperStyle.value = s; final p = await SharedPreferences.getInstance(); await p.setString(_K.preferredPaperStyle, s); }
  Future<void> setPreferredFontSize(double s) async { preferredFontSize.value = s; final p = await SharedPreferences.getInstance(); await p.setDouble(_K.preferredFontSize, s); }
  Future<void> setPreferredFontFamily(String f) async { preferredFontFamily.value = f; final p = await SharedPreferences.getInstance(); await p.setString(_K.preferredFontFamily, f); }
  Future<void> setMascotDecoration(String? a) async { 
    selectedMascotDecoration.value = a; 
    _lastInteractedIsGlasses = false; 
    final p = await SharedPreferences.getInstance(); 
    a == null ? await p.remove(_K.mascotDecoration) : await p.setString(_K.mascotDecoration, a); 
  }
  Future<void> setSelectedGlassesDecoration(String? a) async { 
    selectedGlassesDecoration.value = a; 
    _lastInteractedIsGlasses = true; 
    final p = await SharedPreferences.getInstance(); 
    a == null ? await p.remove(_K.selectedGlassesDecoration) : await p.setString(_K.selectedGlassesDecoration, a); 
  }
  Future<void> setGlassesOverlayEnabled(bool enabled) async { 
    if (isGlassesOverlayEnabled.value && !enabled) {
      // 正在关闭叠戴模式：解决可能的“二合一”冲突
      if (selectedGlassesDecoration.value != null) {
        if (_lastInteractedIsGlasses) {
          // 最后操作的是眼镜 -> 将其路径赋给主槽位（互斥逻辑）
          final path = selectedGlassesDecoration.value;
          await setSelectedGlassesDecoration(null); // 先清空眼镜槽位
          await setMascotDecoration(path); // 填入主槽位
        } else {
          // 最后操作的是主饰品 -> 仅清空物理眼镜层
          await setSelectedGlassesDecoration(null);
        }
      }
    }
    isGlassesOverlayEnabled.value = enabled; 
    final p = await SharedPreferences.getInstance(); 
    await p.setBool(_K.isGlassesOverlayEnabled, enabled); 
  }
  Future<void> setGlassesAboveHat(bool enabled) async { 
    isGlassesAboveHat.value = enabled; 
    final p = await SharedPreferences.getInstance(); 
    await p.setBool(_K.isGlassesAboveHat, enabled); 
  }
  Future<void> setMascotType(String path) async { selectedMascotType.value = path; final p = await SharedPreferences.getInstance(); await p.setString(_K.mascotType, path); }
}

/// 聚合状态管理类
class UserState with ProfileMixin, DiaryMixin, DecorationMixin, SecurityMixin, AchievementMixin, PreferenceMixin {
  static final UserState _instance = UserState._internal();
  factory UserState() => _instance;
  UserState._internal();

  Future<void> loadFromStorage() async {
    final prefs = await SharedPreferences.getInstance();
    
    loadProfile(prefs);
    await loadDiaries(prefs);
    await loadDecoration(prefs);
    loadSecurity(prefs);
    loadPreference(prefs);
    await loadAchievement(prefs);
    await syncAchievementRewards(); // 启动时强制同步一次
  }

  Future<void> factoryReset() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    userName.value = ''; isVip.value = false; isAppLockEnabled.value = false; appLockPin.value = '';
    isBiometricEnabled.value = false; isMistModeEnabled.value = false; destructionCode.value = '';
    customAvatarPath.value = null;
    savedDiaries.value = []; placedFurniture.value = []; diaryDraft.value = null;
    ownedDecorationIds.value = _defaultOwnedIds;
    unlockedMascotPaths.value = ['assets/images/emoji/marshmallow2.png'];
  }

  void dispose() {
    userName.dispose(); hasFinishedOnboarding.dispose(); hasSeenRecordGuidance.dispose();
    diaryDraft.dispose(); isSlimeInBottomMenu.dispose(); selectedMascotDecoration.dispose();
    ownedDecorationIds.dispose(); unlockedMascotPaths.dispose(); unlockedAchievements.dispose(); achievementPoints.dispose();
  }
}
