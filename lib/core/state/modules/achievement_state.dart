part of '../user_state.dart';

/// 5. 成就与统计模块
mixin AchievementMixin on ProfileMixin, DiaryMixin {
  final ValueNotifier<List<String>> ownedDecorationIds = ValueNotifier<List<String>>([]);
  final ValueNotifier<List<String>> unlockedMascotPaths = ValueNotifier<List<String>>([]);
  final ValueNotifier<int> achievementPoints = ValueNotifier<int>(0);
  final ValueNotifier<Map<String, String>> unlockedAchievements = ValueNotifier<Map<String, String>>({});

  Future<void> loadAchievement(SharedPreferences prefs) async {
    achievementPoints.value = prefs.getInt(_K.achievementPoints) ?? 0;
    final mapJson = prefs.getString(_K.unlockedAchievementsMap);
    if (mapJson != null) {
      try {
        unlockedAchievements.value = Map<String, String>.from(jsonDecode(mapJson));
      } catch (_) {}
    } else {
      final old = prefs.getStringList(_K.unlockedAchievements);
      if (old != null) {
        final m = {for (var id in old) id: DateTime.now().toIso8601String()};
        unlockedAchievements.value = m;
        await prefs.setString(_K.unlockedAchievementsMap, jsonEncode(m));
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
      if (deco == null) {
        return false;
      }
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
        p += a.rewardPoints.toInt();
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
      achievementPoints.value += p.toInt();
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
      totalPoints += a.rewardPoints.toInt();
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
    final diaries = savedDiaries.value;
    final stats = <String, int>{};
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
