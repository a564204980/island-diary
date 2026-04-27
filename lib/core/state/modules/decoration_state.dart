part of '../user_state.dart';

/// 3. 装修与场景装饰模块
mixin DecorationMixin {
  final ValueNotifier<List<PlacedFurniture>> placedFurniture = ValueNotifier<List<PlacedFurniture>>([]);
  final ValueNotifier<Color> wallColorLeft = ValueNotifier<Color>(const Color(0xFFDEDCCE));
  final ValueNotifier<Color> wallColorRight = ValueNotifier<Color>(const Color(0xFFDEDCCE));
  final ValueNotifier<Uint8List?> decorationSnapshot = ValueNotifier<Uint8List?>(null);

  Future<void> loadDecoration(SharedPreferences prefs) async {
    final snapshotBase64 = prefs.getString(_K.decorationSnapshot);
    if (snapshotBase64 != null) {
      try {
        decorationSnapshot.value = base64Decode(snapshotBase64);
      } catch (_) {}
    }
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
    wallColorLeft.value = left;
    wallColorRight.value = right;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_K.wallColorLeft, left.toARGB32());
    await prefs.setInt(_K.wallColorRight, right.toARGB32());
  }
}
