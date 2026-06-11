import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Models
import 'package:island_diary/core/models/daily_task.dart';
import 'package:island_diary/core/models/mascot_achievement.dart';
import 'package:island_diary/core/models/mascot_decoration.dart';
import 'package:island_diary/core/models/mascot_event.dart';
import 'package:island_diary/core/models/mascot_persona.dart';
import 'package:island_diary/core/models/life_line_profile.dart';
import 'package:island_diary/features/record/domain/models/diary_entry.dart';
import 'package:island_diary/features/record/domain/models/diary_draft.dart';
import 'package:island_diary/features/record/domain/models/placed_furniture.dart';

// Services
import 'package:island_diary/core/services/ai_service.dart';

part 'modules/profile_state.dart';
part 'modules/diary_state.dart';
part 'modules/decoration_state.dart';
part 'modules/security_state.dart';
part 'modules/preference_state.dart';
part 'modules/life_line_state.dart';
part 'modules/achievement_state.dart';

class _K {
  static const userName = 'user_name';
  static const userBio = 'user_bio';
  static const userBirthday = 'user_birthday';
  static const userGender = 'user_gender';
  static const onboarding = 'has_finished_onboarding';
  static const recordGuidance = 'has_seen_record_guidance';
  static const selectedTitles = 'selected_user_titles';
  static const vipLevel = 'vip_level';
  static const isVip = 'is_vip';
  static const vipExpireTime = 'vip_expire_time';
  static const customAvatar = 'custom_avatar_path';
  static const themeMode = 'theme_mode';
  static const lastVisit = 'last_visit_time';
  static const deepseekApiKey = 'deepseek_api_key';
  static const lastSoulInsight = 'last_soul_insight';
  static const lastSoulInsightDate = 'last_soul_insight_date';
  static const currentDailyTask = 'current_daily_task';
  static const lastBirthdayGiftYear = 'last_birthday_gift_year';

  static const savedDiaries = 'saved_diaries_v1';
  static const draftContent = 'diary_draft_content';
  static const draftMood = 'diary_draft_mood';
  static const draftIntensity = 'diary_draft_intensity';
  static const draftTag = 'diary_draft_tag';
  static const draftWeather = 'diary_draft_weather';
  static const draftTemp = 'diary_draft_temp';
  static const draftLocation = 'diary_draft_location';
  static const draftCustomDate = 'diary_draft_custom_date';
  static const draftCustomTime = 'diary_draft_custom_time';
  static const draftDateTime = 'diary_draft_date_time';
  static const draftBlocks = 'diary_draft_blocks';
  static const draftPaperStyle = 'diary_draft_paper_style';
  static const draftIsImageGrid = 'diary_draft_is_image_grid';
  static const draftIsMixedLayout = 'diary_draft_is_mixed_layout';

  static const wallColorLeft = 'wall_color_left';
  static const wallColorRight = 'wall_color_right';
  static const wallPattern = 'wall_pattern';
  static const floorColor = 'floor_color';
  static const floorPattern = 'floor_pattern';
  static const placedFurniture = 'placed_furniture_v1';
  static const decorationSnapshot = 'decoration_snapshot_v1';

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

  static const achievementPoints = 'achievement_points';
  static const unlockedAchievementsMap = 'unlocked_achievements_v2';
  static const ownedDecorations = 'owned_decoration_ids';
  static const unlockedMascots = 'unlocked_mascot_paths';


  static const diaryLayoutMode = 'diary_layout_mode';
  static const moodTagHistory = 'mood_tag_history';
  static const statsOrderWeek = 'stats_order_week';
  static const statsOrderMonth = 'stats_order_month';
  static const statsOrderAll = 'stats_order_all';
  static const preferredPaperStyle = 'preferred_paper_style';
  static const preferredFontSize = 'preferred_font_size';
  static const preferredFontFamily = 'preferred_font_family';
  static const mascotDecoration = 'selected_mascot_decoration';
  static const selectedGlassesDecoration = 'selected_glasses_decoration';
  static const selectedEarringDecoration = 'selected_earring_decoration';
  static const selectedBackgroundDecoration = 'selected_background_decoration';
  static const isGlassesOverlayEnabled = 'is_glasses_overlay_enabled';
  static const isGlassesAboveHat = 'is_glasses_above_hat';
  static const mascotType = 'selected_mascot_type';
  static const homeDisplayMode = 'home_display_mode';
  static const selectedIslandThemeId = 'selected_island_theme_id';
}

/// 聚合状态管理类
class UserState
    with
        LifeLineMixin,
        ProfileMixin,
        DiaryMixin,
        DecorationMixin,
        SecurityMixin,
        AchievementMixin,
        PreferenceMixin {
  static final UserState _instance = UserState._internal();
  factory UserState() => _instance;
  UserState._internal();
  final ValueNotifier<int> refreshNavbarBgTrigger = ValueNotifier<int>(0);

  /// 是否已加载最小必需数据（userName/安全设置），可以开始路由
  final ValueNotifier<bool> isMinimalDataLoaded = ValueNotifier<bool>(false);

  Future<void> loadFromStorage() async {
    final prefs = await SharedPreferences.getInstance();

    // 同步执行必须先做的命名空间与基础配置加载（极快，仅读取已缓存的 prefs 对象）
    loadLifeLines(prefs);
    loadProfile(prefs);
    loadSecurity(prefs);
    loadPreference(prefs);

    // 通知 UI：路由所需的最小数据已就绪，可以立即渲染主页
    isMinimalDataLoaded.value = true;

    // 并行执行耗时的数据加载，加载完成后 UI 通过 ValueNotifier 自动刷新
    await Future.wait([
      loadDiaries(prefs),
      loadDecoration(prefs),
      loadAchievements(prefs),
    ]);
  }

  Future<void> factoryReset() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();

    // 重置内存状态
    userName.value = '';
    userBio.value = '';
    lifeLines.value = [];
    currentLifeLineId.value = 'default';
    savedDiaries.value = [];
    placedFurniture.value = [];

    // 重新从空白状态初始化
    loadLifeLines(prefs);
    loadProfile(prefs);
    await loadDiaries(prefs);
    await loadDecoration(prefs);
  }

  void dispose() {
    _backgroundTimer?.cancel();
    userName.dispose();
    hasFinishedOnboarding.dispose();
    hasSeenRecordGuidance.dispose();
    diaryDraft.dispose();
    isSlimeInBottomMenu.dispose();
    selectedMascotDecoration.dispose();
    selectedGlassesDecoration.dispose();
    selectedEarringDecoration.dispose();
    selectedBackgroundDecoration.dispose();
    ownedDecorationIds.dispose();
    unlockedAchievements.dispose();
    achievementPoints.dispose();
    unlockedMascotPaths.dispose();
    refreshNavbarBgTrigger.dispose();
  }
}
