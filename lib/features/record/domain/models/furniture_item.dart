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
  final double visualScale;
  final Offset visualOffset;
  final double visualRotationX;
  final double visualRotationY;
  final double visualRotationZ;
  final Offset visualPivot;

  // 背面（旋转 index 为 1, 2 时）的独立微调参数
  final double? backVisualScale;
  final Offset? backVisualOffset;
  final double? backVisualRotationX;
  final double? backVisualRotationY;
  final double? backVisualRotationZ;
  final Offset? backVisualPivot;

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
    this.visualScale = 1.0,
    this.visualOffset = Offset.zero,
    this.visualRotationX = 0,
    this.visualRotationY = 0,
    this.visualRotationZ = 0,
    this.visualPivot = Offset.zero,
    this.backVisualScale,
    this.backVisualOffset,
    this.backVisualRotationX,
    this.backVisualRotationY,
    this.backVisualRotationZ,
    this.backVisualPivot,
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
      'visualScale': visualScale,
      'visualOffset': {'x': visualOffset.dx, 'y': visualOffset.dy},
      'vRotationX': visualRotationX,
      'vRotationY': visualRotationY,
      'vRotationZ': visualRotationZ,
      'vPivot': {'x': visualPivot.dx, 'y': visualPivot.dy},
      'bvScale': backVisualScale,
      'bvOffset': backVisualOffset != null ? {'x': backVisualOffset!.dx, 'y': backVisualOffset!.dy} : null,
      'bvRotationX': backVisualRotationX,
      'bvRotationY': backVisualRotationY,
      'bvRotationZ': backVisualRotationZ,
      'bvPivot': backVisualPivot != null ? {'x': backVisualPivot!.dx, 'y': backVisualPivot!.dy} : null,
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
      visualScale: (map['visualScale'] as num?)?.toDouble() ?? 1.0,
      visualOffset: map['visualOffset'] != null
          ? Offset(
              (map['visualOffset']['x'] as num).toDouble(),
              (map['visualOffset']['y'] as num).toDouble(),
            )
          : Offset.zero,
      visualRotationX: (map['vRotationX'] as num?)?.toDouble() ?? 0,
      visualRotationY: (map['vRotationY'] as num?)?.toDouble() ?? 0,
      visualRotationZ: (map['vRotationZ'] as num?)?.toDouble() ?? 0,
      visualPivot: map['vPivot'] != null
          ? Offset(
              (map['vPivot']['x'] as num).toDouble(),
              (map['vPivot']['y'] as num).toDouble(),
            )
          : Offset.zero,
      backVisualScale: (map['bvScale'] as num?)?.toDouble(),
      backVisualOffset: map['bvOffset'] != null
          ? Offset(
              (map['bvOffset']['x'] as num).toDouble(),
              (map['bvOffset']['y'] as num).toDouble(),
            )
          : null,
      backVisualRotationX: (map['bvRotationX'] as num?)?.toDouble(),
      backVisualRotationY: (map['bvRotationY'] as num?)?.toDouble(),
      backVisualRotationZ: (map['bvRotationZ'] as num?)?.toDouble(),
      backVisualPivot: map['bvPivot'] != null
          ? Offset(
              (map['bvPivot']['x'] as num).toDouble(),
              (map['bvPivot']['y'] as num).toDouble(),
            )
          : null,
    );
  }

  bool get isFloor => category.contains('地板') || id.toLowerCase().startsWith('floor');
  bool get isWall => category.contains('墙壁') || id.toLowerCase().startsWith('wall');
}

bool isCellExcluded(int i, int j) {
  // 不再屏蔽任何区域
  return false;
}
