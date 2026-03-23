import 'furniture_item.dart';

class PlacedFurniture {
  final FurnitureItem item;
  final int r;
  final int c;
  int rotation; // 0, 1, 2, 3 (0°, 90°, 180°, 270°)

  PlacedFurniture({
    required this.item,
    required this.r,
    required this.c,
    this.rotation = 0,
  });

  Map<String, dynamic> toMap() {
    return {
      'item': item.toMap(),
      'r': r,
      'c': c,
      'rotation': rotation,
    };
  }

  factory PlacedFurniture.fromMap(Map<String, dynamic> map) {
    return PlacedFurniture(
      item: FurnitureItem.fromMap(Map<String, dynamic>.from(map['item'])),
      r: map['r'],
      c: map['c'],
      rotation: map['rotation'],
    );
  }
}
