import 'furniture_item.dart';

class PlacedFurniture {
  final FurnitureItem item;
  final int r;
  final int c;
  double z; // 高度坐标 (默认 0)
  int rotation; // 0, 1, 2, 3 (0°, 90°, 180°, 270°)

  PlacedFurniture({
    required this.item,
    required this.r,
    required this.c,
    this.z = 0.0,
    this.rotation = 0,
  });

  Map<String, dynamic> toMap() {
    return {
      'item': item.toMap(),
      'r': r,
      'c': c,
      'z': z,
      'rotation': rotation,
    };
  }

  factory PlacedFurniture.fromMap(Map<String, dynamic> map) {
    return PlacedFurniture(
      item: FurnitureItem.fromMap(Map<String, dynamic>.from(map['item'])),
      r: map['r'],
      c: map['c'],
      z: (map['z'] as num?)?.toDouble() ?? 0.0,
      rotation: map['rotation'],
    );
  }
}
