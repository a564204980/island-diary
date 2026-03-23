import 'package:flutter/material.dart';
import '../domain/models/furniture_item.dart';

final List<FurnitureItem> defaultFurnitureItems = [
  FurnitureItem(
    id: 'fridge_1',
    name: '复古冰箱',
    imagePath: 'assets/images/decoration/furniture/fridges2.png',
    spriteRect: const Rect.fromLTWH(0, 0, 0.5, 1.0), // 第1个面
    gridW: 3,
    gridH: 3,
    intrinsicWidth: 605,
    intrinsicHeight: 1072,
    quantity: 3,
  ),
];
