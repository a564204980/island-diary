import 'furniture_item.dart';

class PlacedFurniture {
  final FurnitureItem item;
  int r;
  int c;
  double z; // 高度坐标（默认 0）
  int rotation; // 0, 1, 2, 3（0度、90度、180度、270度）

  PlacedFurniture({
    required this.item,
    required this.r,
    required this.c,
    this.z = 0.0,
    this.rotation = 0,
  });

  Map<String, dynamic> toMap() {
    return {'item': item.toMap(), 'r': r, 'c': c, 'z': z, 'rotation': rotation};
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

  PlacedFurniture copyWith({
    FurnitureItem? item,
    int? r,
    int? c,
    double? z,
    int? rotation,
  }) {
    return PlacedFurniture(
      item: item ?? this.item,
      r: r ?? this.r,
      c: c ?? this.c,
      z: z ?? this.z,
      rotation: rotation ?? this.rotation,
    );
  }
}
