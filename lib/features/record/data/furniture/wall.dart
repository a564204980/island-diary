import 'package:flutter/material.dart';
import '../../domain/models/furniture_item.dart';

final List<FurnitureItem> wallItems = [
  FurnitureItem(
    id: 'wall_wood_1',
    name: '木构墙壁',
    imagePath: 'assets/images/decoration/furniture/house.png',
    // 截取 house.png 里的墙壁部分
    spriteRect: const Rect.fromLTWH(0.66, 0.15, 0.1, 0.4),
    category: '墙壁',
    subCategory: '木质',
    gridW: 4,
    gridH: 4,
    intrinsicWidth: 200,
    intrinsicHeight: 400,
    quantity: 99,
    visualScale: 1.0,
  ),
];
