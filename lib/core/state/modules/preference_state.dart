part of '../user_state.dart';

/// 6. 用户偏好与个性化模块
mixin PreferenceMixin on ProfileMixin {
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
  final ValueNotifier<String?> selectedEarringDecoration = ValueNotifier<String?>(null);
  final ValueNotifier<String?> selectedBackgroundDecoration = ValueNotifier<String?>(null);
  final ValueNotifier<bool> isGlassesOverlayEnabled = ValueNotifier<bool>(false);
  final ValueNotifier<bool> isGlassesAboveHat = ValueNotifier<bool>(true);
  // 新增：记录最后一次交互是否为眼镜类饰品
  bool _lastInteractedIsGlasses = false;
  final ValueNotifier<String> selectedMascotType = ValueNotifier<String>('assets/images/emoji/marshmallow2.png');
  final ValueNotifier<String> homeDisplayMode = ValueNotifier<String>('island');
  
  // 新增：棉花岛主题长按屏幕时的云朵快速移动倍率
  final ValueNotifier<double> cloudSpeedMultiplier = ValueNotifier<double>(1.0);

  void loadPreference(SharedPreferences prefs) {
    momentsCoverPath.value = prefs.getString(UserState().n(_K.momentsCover));
    diaryLayoutMode.value = prefs.getInt(UserState().n(_K.diaryLayoutMode)) ?? 0;
    moodTagHistory.value = prefs.getStringList(UserState().n(_K.moodTagHistory)) ?? [];
    statsOrderWeek.value = prefs.getStringList(UserState().n(_K.statsOrderWeek)) ?? [];
    statsOrderMonth.value = prefs.getStringList(UserState().n(_K.statsOrderMonth)) ?? [];
    statsOrderAll.value = prefs.getStringList(UserState().n(_K.statsOrderAll)) ?? [];
    preferredPaperStyle.value = prefs.getString(UserState().n(_K.preferredPaperStyle)) ?? 'note1';
    preferredFontSize.value = prefs.getDouble(UserState().n(_K.preferredFontSize)) ?? 20.0;
    preferredFontFamily.value = prefs.getString(UserState().n(_K.preferredFontFamily)) ?? 'LXGWWenKai';
    selectedMascotDecoration.value = prefs.getString(UserState().n(_K.mascotDecoration));
    selectedGlassesDecoration.value = prefs.getString(UserState().n(_K.selectedGlassesDecoration));
    selectedEarringDecoration.value = prefs.getString(UserState().n(_K.selectedEarringDecoration));
    selectedBackgroundDecoration.value = prefs.getString(UserState().n(_K.selectedBackgroundDecoration));
    isGlassesOverlayEnabled.value = prefs.getBool(UserState().n(_K.isGlassesOverlayEnabled)) ?? false;
    isGlassesAboveHat.value = prefs.getBool(UserState().n(_K.isGlassesAboveHat)) ?? true;
    selectedMascotType.value = prefs.getString(UserState().n(_K.mascotType)) ?? 'assets/images/emoji/marshmallow2.png';
    homeDisplayMode.value = prefs.getString(UserState().n(_K.homeDisplayMode)) ?? 'island';
  }

  Future<void> setMomentsCoverPath(String? path) async {
    momentsCoverPath.value = path;
    final p = await SharedPreferences.getInstance();
    path != null ? await p.setString(UserState().n(_K.momentsCover), path) : await p.remove(UserState().n(_K.momentsCover));
  }

  Future<void> setDiaryLayoutMode(int mode) async {
    diaryLayoutMode.value = mode;
    final p = await SharedPreferences.getInstance();
    await p.setInt(UserState().n(_K.diaryLayoutMode), mode);
  }

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
    await p.setStringList(UserState().n(_K.moodTagHistory), l);
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
    await p.setStringList(UserState().n(k), order);
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
    await p.remove(UserState().n(k));
  }

  Future<void> setPreferredPaperStyle(String s) async {
    preferredPaperStyle.value = s;
    final p = await SharedPreferences.getInstance();
    await p.setString(UserState().n(_K.preferredPaperStyle), s);
  }

  Future<void> setPreferredFontSize(double s) async {
    preferredFontSize.value = s;
    final p = await SharedPreferences.getInstance();
    await p.setDouble(UserState().n(_K.preferredFontSize), s);
  }

  Future<void> setPreferredFontFamily(String f) async {
    preferredFontFamily.value = f;
    final p = await SharedPreferences.getInstance();
    await p.setString(UserState().n(_K.preferredFontFamily), f);
  }

  Future<void> setMascotDecoration(String? a) async {
    selectedMascotDecoration.value = a; 
    _lastInteractedIsGlasses = false; 
    final p = await SharedPreferences.getInstance(); 
    a == null ? await p.remove(UserState().n(_K.mascotDecoration)) : await p.setString(UserState().n(_K.mascotDecoration), a); 

    if (a != null) {
      // 检查每日任务
      completeTaskIfType(DailyTaskType.changeDecoration);
      
      final deco = MascotDecoration.getByPath(a);
      notifyMascotEvent(MascotEvent(
        type: MascotEventType.decorationChanged,
        description: "戴上了${deco?.name ?? '新饰品'}",
      ));
    }
  }

  Future<void> setSelectedEarringDecoration(String? a) async {
    selectedEarringDecoration.value = a;
    final p = await SharedPreferences.getInstance();
    a == null
        ? await p.remove(UserState().n(_K.selectedEarringDecoration))
        : await p.setString(UserState().n(_K.selectedEarringDecoration), a);

    if (a != null) {
      completeTaskIfType(DailyTaskType.changeDecoration);
      final deco = MascotDecoration.getByPath(a);
      notifyMascotEvent(MascotEvent(
        type: MascotEventType.decorationChanged,
        description: "戴上了${deco?.name ?? '新耳饰'}",
      ));
    }
  }

  Future<void> setSelectedBackgroundDecoration(String? a) async {
    selectedBackgroundDecoration.value = a;
    final p = await SharedPreferences.getInstance();
    a == null
        ? await p.remove(UserState().n(_K.selectedBackgroundDecoration))
        : await p.setString(UserState().n(_K.selectedBackgroundDecoration), a);

    if (a != null) {
      completeTaskIfType(DailyTaskType.changeDecoration);
      final deco = MascotDecoration.getByPath(a);
      notifyMascotEvent(MascotEvent(
        type: MascotEventType.decorationChanged,
        description: "戴上了${deco?.name ?? '新背景'}",
      ));
    }
  }

  Future<void> setSelectedGlassesDecoration(String? a) async {
    selectedGlassesDecoration.value = a; 
    _lastInteractedIsGlasses = true; 
    final p = await SharedPreferences.getInstance(); 
    a == null ? await p.remove(UserState().n(_K.selectedGlassesDecoration)) : await p.setString(UserState().n(_K.selectedGlassesDecoration), a); 

    if (a != null) {
      // 检查每日任务
      completeTaskIfType(DailyTaskType.changeDecoration);

      final deco = MascotDecoration.getByPath(a);
      notifyMascotEvent(MascotEvent(
        type: MascotEventType.decorationChanged,
        description: "戴上了${deco?.name ?? '新眼镜'}",
      ));
    }
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
    await p.setBool(UserState().n(_K.isGlassesOverlayEnabled), enabled); 
  }

  Future<void> setGlassesAboveHat(bool enabled) async { 
    isGlassesAboveHat.value = enabled; 
    final p = await SharedPreferences.getInstance(); 
    await p.setBool(UserState().n(_K.isGlassesAboveHat), enabled); 
  }

  Future<void> setMascotType(String path) async {
    selectedMascotType.value = path;
    final p = await SharedPreferences.getInstance();
    await p.setString(UserState().n(_K.mascotType), path);
  }

  Future<void> setHomeDisplayMode(String mode) async {
    homeDisplayMode.value = mode;
    final p = await SharedPreferences.getInstance();
    await p.setString(UserState().n(_K.homeDisplayMode), mode);
  }
}
