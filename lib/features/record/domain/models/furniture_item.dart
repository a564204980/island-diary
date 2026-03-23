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
  final String category;
  final String subCategory;
  int quantity;

  FurnitureItem({
    required this.id,
    required this.name,
    required this.imagePath,
    required this.spriteRect,
    required this.category,
    required this.subCategory,
    this.gridW = 1,
    this.gridH = 1,
    this.intrinsicWidth = 1,
    this.intrinsicHeight = 1,
    this.quantity = 3,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'imagePath': imagePath,
      'spriteRect': {
        'l': spriteRect.left,
        't': spriteRect.top,
        'w': spriteRect.width,
        'h': spriteRect.height,
      },
      'gridW': gridW,
      'gridH': gridH,
      'intrinsicWidth': intrinsicWidth,
      'intrinsicHeight': intrinsicHeight,
      'category': category,
      'subCategory': subCategory,
      'quantity': quantity,
    };
  }

  factory FurnitureItem.fromMap(Map<String, dynamic> map) {
    final rect = map['spriteRect'] as Map<String, dynamic>;
    return FurnitureItem(
      id: map['id'],
      name: map['name'],
      imagePath: map['imagePath'],
      spriteRect: Rect.fromLTWH(
        (rect['l'] as num).toDouble(),
        (rect['t'] as num).toDouble(),
        (rect['w'] as num).toDouble(),
        (rect['h'] as num).toDouble(),
      ),
      gridW: map['gridW'],
      gridH: map['gridH'],
      intrinsicWidth: (map['intrinsicWidth'] as num).toDouble(),
      intrinsicHeight: (map['intrinsicHeight'] as num).toDouble(),
      category: map['category'],
      subCategory: map['subCategory'],
      quantity: map['quantity'],
    );
  }
}

bool isCellExcluded(int i, int j) {
  // 屏蔽区域：(0, 4-8) 和 (1, 4-8)
  if ((i == 0 || i == 1) && (j >= 4 && j <= 8)) {
    return true;
  }
  return false;
}
