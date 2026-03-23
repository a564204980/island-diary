import 'package:flutter/material.dart';

class FurnitureItem {
  final String id;
  final String name;
  final String imagePath;
  final Rect spriteRect;
  final int gridW;
  final int gridH;
  final double intrinsicWidth;
  final double intrinsicHeight;
  int quantity;

  FurnitureItem({
    required this.id,
    required this.name,
    required this.imagePath,
    required this.spriteRect,
    this.gridW = 1,
    this.gridH = 1,
    this.intrinsicWidth = 1,
    this.intrinsicHeight = 1,
    this.quantity = 3,
  });
}

bool isCellExcluded(int i, int j) {
  // 屏蔽区域：(0, 4-8) 和 (1, 4-8)
  if ((i == 0 || i == 1) && (j >= 4 && j <= 8)) {
    return true;
  }
  return false;
}
