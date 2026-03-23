import 'dart:ui' as ui;

class FurnitureItem {
  final String id;
  final String name;
  final String imagePath;
  final int gridWidth;
  final int gridHeight;
  final double offsetX;
  final double widthStretch;
  final double heightStretch;
  ui.Image? image;

  FurnitureItem({
    required this.id,
    required this.name,
    required this.imagePath,
    required this.gridWidth,
    required this.gridHeight,
    this.offsetX = 0.0,
    this.widthStretch = 1.0,
    this.heightStretch = 1.0,
  });
}

class FurnitureInstance {
  final FurnitureItem item;
  int col;
  int row;

  FurnitureInstance({
    required this.item,
    required this.col,
    required this.row,
  });
}
