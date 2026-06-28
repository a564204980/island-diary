part of '../user_state.dart';

/// 顶层函数：供 compute() 在后台 isolate 解码 base64 快照
Uint8List _decodeBase64(String base64Str) => base64Decode(base64Str);

/// 顶层函数：供 compute() 在后台 isolate 解析家具 JSON
List<PlacedFurniture> _parseFurniture(String jsonStr) {
  final decoded = jsonDecode(jsonStr) as List;
  return decoded
      .map((e) => PlacedFurniture.fromMap(Map<String, dynamic>.from(e)))
      .where((pf) => !pf.item.imagePath.contains('assets/images/residents/'))
      .toList();
}

/// 3. 装修与场景装饰模块
mixin DecorationMixin {
  final ValueNotifier<List<PlacedFurniture>> placedFurniture = ValueNotifier<List<PlacedFurniture>>([]);
  final ValueNotifier<Color> wallColorLeft = ValueNotifier<Color>(const Color(0xFFDEDCCE));
  final ValueNotifier<Color> wallColorRight = ValueNotifier<Color>(const Color(0xFFDEDCCE));
  final ValueNotifier<int> wallPattern = ValueNotifier<int>(0);
  final ValueNotifier<Color> floorColor = ValueNotifier<Color>(const Color(0xFFF1EBD1));
  final ValueNotifier<int> floorPattern = ValueNotifier<int>(0);
  final ValueNotifier<Uint8List?> decorationSnapshot = ValueNotifier<Uint8List?>(null);

  // 饰品拥有权与角色解锁属性
  final ValueNotifier<List<String>> ownedDecorationIds = ValueNotifier<List<String>>([]);
  final ValueNotifier<List<String>> unlockedMascotPaths = ValueNotifier<List<String>>([]);

  Future<void> loadDecoration(SharedPreferences prefs) async {
    final owned = prefs.getStringList(UserState().n(_K.ownedDecorations)) ?? [];
    ownedDecorationIds.value = owned;
    final mascots = prefs.getStringList(UserState().n(_K.unlockedMascots)) ?? ['assets/images/residents/soft.png'];
    unlockedMascotPaths.value = mascots;

    final snapshotBase64 = prefs.getString(UserState().n(_K.decorationSnapshot));
    if (snapshotBase64 != null) {
      try {
        // base64解码收到弹巳 — 用 compute 移入后台 isolate
        decorationSnapshot.value = await compute(_decodeBase64, snapshotBase64);
      } catch (_) {}
    }
    final l = prefs.getInt(UserState().n(_K.wallColorLeft));
    if (l != null) {
      wallColorLeft.value = Color(l);
    }
    final r = prefs.getInt(UserState().n(_K.wallColorRight));
    if (r != null) {
      wallColorRight.value = Color(r);
    }
    final pattern = prefs.getInt(UserState().n(_K.wallPattern));
    if (pattern != null) {
      wallPattern.value = pattern;
    }
    final floor = prefs.getInt(UserState().n(_K.floorColor));
    if (floor != null) {
      floorColor.value = Color(floor);
    }
    final fPattern = prefs.getInt(UserState().n(_K.floorPattern));
    if (fPattern != null) {
      floorPattern.value = fPattern;
    }
    final f = prefs.getString(UserState().n(_K.placedFurniture));
    if (f != null) {
      try {
        // 家具 JSON 解析移入后台 isolate
        placedFurniture.value = await compute(_parseFurniture, f);
      } catch (_) {}
    }
  }

  Future<void> unlockDecoration(String id) async {
    if (!ownedDecorationIds.value.contains(id)) {
      final updated = List<String>.from(ownedDecorationIds.value)..add(id);
      ownedDecorationIds.value = updated;
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList(UserState().n(_K.ownedDecorations), updated);
    }
  }

  Future<void> unlockMascot(String path) async {
    if (!unlockedMascotPaths.value.contains(path)) {
      final updated = List<String>.from(unlockedMascotPaths.value)..add(path);
      unlockedMascotPaths.value = updated;
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList(UserState().n(_K.unlockedMascots), updated);
    }
  }

  Future<void> setDecorationSnapshot(Uint8List? bytes) async {
    decorationSnapshot.value = bytes;
    final prefs = await SharedPreferences.getInstance();
    bytes != null ? await prefs.setString(UserState().n(_K.decorationSnapshot), base64Encode(bytes)) : await prefs.remove(UserState().n(_K.decorationSnapshot));
  }

  Future<void> savePlacedFurniture(List<PlacedFurniture> list) async {
    placedFurniture.value = list;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(UserState().n(_K.placedFurniture), jsonEncode(list.map((e) => e.toMap()).toList()));
  }

  Future<void> saveSceneColors(Color left, Color right, Color floor) async {
    wallColorLeft.value = left;
    wallColorRight.value = right;
    floorColor.value = floor;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(UserState().n(_K.wallColorLeft), left.toARGB32());
    await prefs.setInt(UserState().n(_K.wallColorRight), right.toARGB32());
    await prefs.setInt(UserState().n(_K.wallPattern), wallPattern.value);
    await prefs.setInt(UserState().n(_K.floorColor), floor.toARGB32());
    await prefs.setInt(UserState().n(_K.floorPattern), floorPattern.value);
  }

  Future<void> saveWallColors(Color left, Color right) async {
    await saveSceneColors(left, right, floorColor.value);
  }

  Future<void> saveWallPattern(int pattern) async {
    wallPattern.value = pattern;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(UserState().n(_K.wallPattern), pattern);
  }

  Future<void> saveFloorPattern(int pattern) async {
    floorPattern.value = pattern;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(UserState().n(_K.floorPattern), pattern);
  }
}
