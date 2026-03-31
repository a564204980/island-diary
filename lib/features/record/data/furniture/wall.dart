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

  FurnitureItem(
    id: 'wall_window_1',
    name: '窗户 1',
    imagePath: 'assets/images/decoration/furniture/window1.png',
    category: '墙壁',
    subCategory: '装饰',
    gridW: 5,
    gridH: 7,
    intrinsicWidth: 365,
    intrinsicHeight: 710,
    quantity: 5,
    visualScale: 1.0,
    visualOffset: Offset.zero,
    visualRotationX: 0,
    visualRotationY: 0,
    visualRotationZ: 0,
    visualPivot: Offset.zero,
  ),
];
