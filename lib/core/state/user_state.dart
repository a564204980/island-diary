import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Models
import 'package:island_diary/core/models/daily_task.dart';
import 'package:island_diary/core/models/mascot_achievement.dart';
import 'package:island_diary/core/models/mascot_decoration.dart';
import 'package:island_diary/core/models/mascot_event.dart';
import 'package:island_diary/features/record/domain/models/diary_entry.dart';
import 'package:island_diary/features/record/domain/models/diary_draft.dart';
import 'package:island_diary/features/record/domain/models/placed_furniture.dart';

// Services
import 'package:island_diary/core/services/ai_service.dart';

part 'modules/profile_state.dart';
part 'modules/diary_state.dart';
part 'modules/decoration_state.dart';
part 'modules/security_state.dart';
part 'modules/achievement_state.dart';
part 'modules/preference_state.dart';

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
  static const unlockedAchievements = 'unlocked_achievements';
  static const unlockedAchievementsMap = 'unlocked_achievements_map';
  static const ownedDecorations = 'owned_decoration_ids';
  static const unlockedMascots = 'unlocked_mascot_paths';

  static const momentsCover = 'moments_cover_path';
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
  static const isGlassesOverlayEnabled = 'is_glasses_overlay_enabled';
  static const isGlassesAboveHat = 'is_glasses_above_hat';
  static const mascotType = 'selected_mascot_type';
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
    userName.value = '';
    isVip.value = false;
    isAppLockEnabled.value = false;
    appLockPin.value = '';
    isBiometricEnabled.value = false;
    isMistModeEnabled.value = false;
    destructionCode.value = '';
    customAvatarPath.value = null;
    savedDiaries.value = [];
    placedFurniture.value = [];
    diaryDraft.value = null;
    ownedDecorationIds.value = _defaultOwnedIds;
    unlockedMascotPaths.value = ['assets/images/emoji/marshmallow2.png'];
  }

  void dispose() {
    _backgroundTimer?.cancel();
    userName.dispose();
    hasFinishedOnboarding.dispose();
    hasSeenRecordGuidance.dispose();
    diaryDraft.dispose();
    isSlimeInBottomMenu.dispose();
    selectedMascotDecoration.dispose();
    ownedDecorationIds.dispose();
    unlockedMascotPaths.dispose();
    unlockedAchievements.dispose();
    achievementPoints.dispose();
  }
}
