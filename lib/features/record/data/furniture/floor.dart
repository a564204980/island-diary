import 'package:flutter/material.dart';
import '../../domain/models/furniture_item.dart';

final List<FurnitureItem> floorItems = [
  FurnitureItem(
    id: 'floor_herringbone_green',
    name: '清新鱼骨纹地板',
    imagePath: 'assets/images/decoration/floors/floor8.png',
    category: '地饰',
    subCategory: '地板',
    gridW: 3,
    gridH: 3,
    intrinsicWidth: 907,
    intrinsicHeight: 577,
    quantity: 99,
    canBeDyed: true,
    colorVariants: [
      FurnitureColorVariant(
        id: 'default',
        name: '清新森绿',
        imagePath: 'assets/images/decoration/floors/floor8.png',
        color: const Color(0xFFA0BA8F),
      ),
      FurnitureColorVariant(
        id: 'mint',
        name: '薄荷奶绿',
        imagePath: 'assets/images/decoration/floors/floor8.png',
        color: const Color(0xFFB9DCC8),
      ),
      FurnitureColorVariant(
        id: 'cream',
        name: '奶油鹅黄',
        imagePath: 'assets/images/decoration/floors/floor8.png',
        color: const Color(0xFFF1DC8A),
      ),
    ],
  ),
  FurnitureItem(
    id: 'floor_sand_beach_full',
    name: '沙滩',
    imagePath: 'assets/images/decoration/door/door1.png',
    category: '地饰',
    subCategory: '地板',
    gridW: 24,
    gridH: 24,
    intrinsicWidth: 1600,
    intrinsicHeight: 924,
    quantity: 1,
    visualScale: 1.05,
    visualOffset: const Offset(0, 0),
  ),
];
