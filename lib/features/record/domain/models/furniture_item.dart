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
  final Offset toolbarOffset;

  // 镜像（旋转 index 为 1 时）的独立微调参数
  final double? flippedVisualScale;
  final Offset? flippedVisualOffset;
  final double? flippedVisualRotationX;
  final double? flippedVisualRotationY;
  final double? flippedVisualRotationZ;
  final Offset? flippedVisualPivot;

  int quantity;

  FurnitureItem({
    required this.id,
    required this.name,
    required this.imagePath,
    this.spriteRect = const Rect.fromLTWH(0, 0, 1, 1),
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
    this.flippedVisualScale,
    this.flippedVisualOffset,
    this.flippedVisualRotationX,
    this.flippedVisualRotationY,
    this.flippedVisualRotationZ,
    this.flippedVisualPivot,
    this.toolbarOffset = Offset.zero,
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
      'fvScale': flippedVisualScale,
      'fvOffset': flippedVisualOffset != null ? {'x': flippedVisualOffset!.dx, 'y': flippedVisualOffset!.dy} : null,
      'fvRotationX': flippedVisualRotationX,
      'fvRotationY': flippedVisualRotationY,
      'fvRotationZ': flippedVisualRotationZ,
      'fvPivot': flippedVisualPivot != null ? {'x': flippedVisualPivot!.dx, 'y': flippedVisualPivot!.dy} : null,
      'toolbarOffset': {'x': toolbarOffset.dx, 'y': toolbarOffset.dy},
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
      flippedVisualScale: (map['fvScale'] as num?)?.toDouble(),
      flippedVisualOffset: map['fvOffset'] != null
          ? Offset(
              (map['fvOffset']['x'] as num).toDouble(),
              (map['fvOffset']['y'] as num).toDouble(),
            )
          : null,
      flippedVisualRotationX: (map['fvRotationX'] as num?)?.toDouble(),
      flippedVisualRotationY: (map['fvRotationY'] as num?)?.toDouble(),
      flippedVisualRotationZ: (map['fvRotationZ'] as num?)?.toDouble(),
      flippedVisualPivot: map['fvPivot'] != null
          ? Offset(
              (map['fvPivot']['x'] as num).toDouble(),
              (map['fvPivot']['y'] as num).toDouble(),
            )
          : null,
      toolbarOffset: map['toolbarOffset'] != null
          ? Offset(
              (map['toolbarOffset']['x'] as num).toDouble(),
              (map['toolbarOffset']['y'] as num).toDouble(),
            )
          : Offset.zero,
    );
  }

  bool get isFloor => category.contains('地板') || id.toLowerCase().startsWith('floor');
  bool get isWall => category.contains('墙壁') || id.toLowerCase().startsWith('wall');
  
  // 判定是否为墙面挂件（装饰物）：属于墙壁类但不是结构性材质
  bool get isWallDecoration => isWall && 
      (subCategory.contains('挂饰') || 
       subCategory.contains('装饰') || 
       id.contains('item') || 
       id.contains('deco') ||
       name.contains('挂') ||
       name.contains('窗'));
}

bool isCellExcluded(int i, int j) {
  // 不再屏蔽任何区域
  return false;
}
