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
}
