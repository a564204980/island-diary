import 'package:flutter/material.dart';
import '../../domain/models/furniture_item.dart';

final List<FurnitureItem> floorItems = [
  FurnitureItem(
    id: 'floor_wood_1',
    name: '原木地板',
    imagePath: 'assets/images/decoration/furniture/house.png',
    // 从 house.png 中取一小块地板
    spriteRect: const Rect.fromLTWH(0.44, 0.58, 0.05, 0.05),
    category: '地板',
    subCategory: '木质',
    gridW: 3,
    gridH: 3,
    intrinsicWidth: 300,
    intrinsicHeight: 150,
    quantity: 99,
    visualScale: 1.0,
  ),
  FurnitureItem(
    id: 'floor_wood_2',
    name: '深色木纹',
    imagePath: 'assets/images/decoration/furniture/house.png',
    spriteRect: const Rect.fromLTWH(0.5, 0.65, 0.05, 0.05),
    category: '地板',
    subCategory: '木质',
    gridW: 3,
    gridH: 3,
    intrinsicWidth: 300,
    intrinsicHeight: 150,
    quantity: 99,
  ),
];
