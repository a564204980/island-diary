part of '../user_state.dart';

/// 顶层函数：供 compute() 在后台 isolate 解析成就 JSON
Map<String, String> _parseAchievements(String jsonStr) {
  return Map<String, String>.from(jsonDecode(jsonStr));
}

mixin AchievementMixin on ProfileMixin, DiaryMixin, DecorationMixin {
  final ValueNotifier<int> achievementPoints = ValueNotifier<int>(0);
  final ValueNotifier<Map<String, String>> unlockedAchievements =
      ValueNotifier<Map<String, String>>({});

  Future<void> loadAchievements(SharedPreferences prefs) async {
    achievementPoints.value = prefs.getInt(n(_K.achievementPoints)) ?? 0;
    final mapJson = prefs.getString(n(_K.unlockedAchievementsMap));
    if (mapJson != null) {
      try {
        unlockedAchievements.value = await compute(_parseAchievements, mapJson);
      } catch (_) {}
    }
  }

  Future<void> syncAchievementRewards() async {
    bool needsSync = false;
    final currentOwned = List<String>.from(ownedDecorationIds.value);
    final unlockedMap = unlockedAchievements.value;
    final currentMascots = List<String>.from(unlockedMascotPaths.value);
    final rewards = MascotAchievement.allAchievements
        .map((a) => a.rewardDecorationId)
        .whereType<String>()
        .toSet();
    for (var d in MascotDecoration.allDecorations) {
      if (d.category == MascotDecorationCategory.glasses &&
          !currentOwned.contains(d.id)) {
        currentOwned.add(d.id);
        needsSync = true;
      } else if (!rewards.contains(d.id) && !currentOwned.contains(d.id)) {
        currentOwned.add(d.id);
        needsSync = true;
      }
    }
    for (var a in MascotAchievement.allAchievements) {
      if (unlockedMap.containsKey(a.id)) {
        if (a.rewardDecorationId != null &&
            !currentOwned.contains(a.rewardDecorationId!)) {
          currentOwned.add(a.rewardDecorationId!);
          needsSync = true;
        }
      }
    }
    if (needsSync) {
      ownedDecorationIds.value = currentOwned;
      unlockedMascotPaths.value = currentMascots;
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList(n(_K.ownedDecorations), currentOwned);
      await prefs.setStringList(n(_K.unlockedMascots), currentMascots);
    }
  }

  Future<List<MascotAchievement>> checkAchievements() async {
    final stats = getAchievementStats();
    final m = Map<String, String>.from(unlockedAchievements.value);
    final o = List<String>.from(ownedDecorationIds.value);
    int p = 0;
    bool changed = false;
    List<MascotAchievement> newlyUnlocked = [];

    for (var a in MascotAchievement.allAchievements) {
      if (!m.containsKey(a.id) && a.isMet(stats)) {
        m[a.id] = DateTime.now().toIso8601String();
        p += a.rewardPoints.toInt();
        if (a.rewardDecorationId != null &&
            !o.contains(a.rewardDecorationId!)) {
          o.add(a.rewardDecorationId!);
        }
        newlyUnlocked.add(a);
        changed = true;
      }
    }
    if (changed) {
      unlockedAchievements.value = m;
      ownedDecorationIds.value = o;
      achievementPoints.value += p.toInt();
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(n(_K.unlockedAchievementsMap), jsonEncode(m));
      await prefs.setStringList(n(_K.ownedDecorations), o);
      await prefs.setInt(n(_K.achievementPoints), achievementPoints.value);
    }
    return newlyUnlocked;
  }

  Future<void> unlockAllForTesting() async {
    final prefs = await SharedPreferences.getInstance();
    final now = DateTime.now().toIso8601String();

    final allDecoIds = MascotDecoration.allDecorations
        .map((d) => d.id)
        .toList();
    ownedDecorationIds.value = allDecoIds;
    await prefs.setStringList(n(_K.ownedDecorations), allDecoIds);

    final allMascots = [
      'assets/images/emoji/marshmallow.png',
      'assets/images/emoji/marshmallow2.png',
      'assets/images/emoji/marshmallow3.png',
      'assets/images/emoji/marshmallow4.png',
    ];
    unlockedMascotPaths.value = allMascots;
    await prefs.setStringList(n(_K.unlockedMascots), allMascots);

    final allAchievementsMap = <String, String>{};
    int totalPoints = 0;
    for (var a in MascotAchievement.allAchievements) {
      allAchievementsMap[a.id] = now;
      totalPoints += a.rewardPoints.toInt();
    }
    unlockedAchievements.value = allAchievementsMap;
    achievementPoints.value = totalPoints;
    await prefs.setString(
      n(_K.unlockedAchievementsMap),
      jsonEncode(allAchievementsMap),
    );
    await prefs.setInt(n(_K.achievementPoints), totalPoints);

    await setIsVipLevel(3);
  }

  Map<String, int> getAchievementStats() {
    final diaries = savedDiaries.value;
    final stats = <String, int>{};
    stats[AchievementCondition.totalDiaries.name] = diaries.length;
    final dates =
        diaries
            .map(
              (e) =>
                  DateTime(e.dateTime.year, e.dateTime.month, e.dateTime.day),
            )
            .toSet()
            .toList()
          ..sort((a, b) => b.compareTo(a));
    int streak = 0, maxS = 0;
    if (dates.isNotEmpty) {
      streak = maxS = 1;
      for (int i = 0; i < dates.length - 1; i++) {
        if (dates[i].difference(dates[i + 1]).inDays == 1) {
          streak++;
          if (streak > maxS) maxS = streak;
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
      if (l > mw) mw = l;
      int h = e.dateTime.hour;
      if (h >= 5 && h <= 10) mor++;
      if (h >= 0 && h <= 4) nit++;
    }
    stats[AchievementCondition.totalWords.name] = tw;
    stats[AchievementCondition.maxSingleWords.name] = mw;
    stats[AchievementCondition.morningDiaries.name] = mor;
    stats[AchievementCondition.nightDiaries.name] = nit;
    stats[AchievementCondition.photoDiaries.name] = diaries
        .where((e) => e.blocks.any((b) => b['type'] == 'image'))
        .length;
    stats[AchievementCondition.uniqueTags.name] = diaries
        .where((e) => e.tag != null)
        .map((e) => e.tag!)
        .toSet()
        .length;
    stats[AchievementCondition.activeDays.name] = dates.length;
    stats[AchievementCondition.totalMoods.name] = diaries.length;
    stats[AchievementCondition.uniqueMoods.name] = diaries
        .map((e) => e.moodIndex)
        .whereType<int>()
        .toSet()
        .length;
    stats[AchievementCondition.totalDecorationsOwned.name] =
        ownedDecorationIds.value.length;
    stats[AchievementCondition.vipLevel.name] = vipLevel.value;
    return stats;
  }
}
