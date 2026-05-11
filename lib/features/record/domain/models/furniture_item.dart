import 'package:flutter/material.dart';
import 'package:isar/isar.dart';

part 'furniture_item.g.dart';

@embedded
class FurnitureColorVariant {
  String id = '';
  String name = '';
  String imagePath = '';
  int colorValue = 0;
  int dyeCost = 1;
  int goldCost = 100;

  FurnitureColorVariant({
    this.id = '',
    this.name = '',
    this.imagePath = '',
    this.colorValue = 0,
    this.dyeCost = 1,
    this.goldCost = 100,
    @ignore Color? color,
  }) {
    if (color != null) {
      colorValue = color.value;
    }
  }

  @ignore
  Color get color => Color(colorValue);
}

@Collection()
class FurnitureItem {
  Id isarId = Isar.autoIncrement;

  @Index(unique: true, replace: true)
  String id = '';
  String name = '';
  String imagePath = '';
  
  double rectLeft = 0;
  double rectTop = 0;
  double rectWidth = 1;
  double rectHeight = 1;

  int gridW = 1;
  int gridH = 1;
  double intrinsicWidth = 1;
  double intrinsicHeight = 1;
  String category = '';
  String subCategory = '';
  double visualScale = 1.0;
  
  double vOffsetX = 0;
  double vOffsetY = 0;

  double visualRotationX = 0;
  double visualRotationY = 0;
  double visualRotationZ = 0;
  
  double vPivotX = 0;
  double vPivotY = 0;

  double tbOffsetX = 0;
  double tbOffsetY = 0;

  bool canBeDyed = false;
  List<FurnitureColorVariant> colorVariants = [];

  double? flippedVisualScale;
  double? fvOffsetX;
  double? fvOffsetY;
  double? flippedVisualRotationX;
  double? flippedVisualRotationY;
  double? flippedVisualRotationZ;
  double? fvPivotX;
  double? fvPivotY;

  int quantity = 3;

  FurnitureItem({
    this.id = '',
    this.name = '',
    this.imagePath = '',
    @ignore Rect? spriteRect,
    this.rectLeft = 0,
    this.rectTop = 0,
    this.rectWidth = 1,
    this.rectHeight = 1,
    this.category = '',
    this.subCategory = '',
    this.gridW = 1,
    this.gridH = 1,
    this.intrinsicWidth = 1,
    this.intrinsicHeight = 1,
    this.quantity = 3,
    this.visualScale = 1.0,
    @ignore Offset? visualOffset,
    this.vOffsetX = 0,
    this.vOffsetY = 0,
    this.visualRotationX = 0,
    this.visualRotationY = 0,
    this.visualRotationZ = 0,
    @ignore Offset? visualPivot,
    this.vPivotX = 0,
    this.vPivotY = 0,
    this.flippedVisualScale,
    @ignore Offset? flippedVisualOffset,
    this.fvOffsetX,
    this.fvOffsetY,
    this.flippedVisualRotationX,
    this.flippedVisualRotationY,
    this.flippedVisualRotationZ,
    @ignore Offset? flippedVisualPivot,
    this.fvPivotX,
    this.fvPivotY,
    @ignore Offset? toolbarOffset,
    this.tbOffsetX = 0,
    this.tbOffsetY = 0,
    this.canBeDyed = false,
    this.colorVariants = const [],
  }) {
    if (spriteRect != null) {
      rectLeft = spriteRect.left;
      rectTop = spriteRect.top;
      rectWidth = spriteRect.width;
      rectHeight = spriteRect.height;
    }
    if (visualOffset != null) {
      vOffsetX = visualOffset.dx;
      vOffsetY = visualOffset.dy;
    }
    if (visualPivot != null) {
      vPivotX = visualPivot.dx;
      vPivotY = visualPivot.dy;
    }
    if (flippedVisualOffset != null) {
      fvOffsetX = flippedVisualOffset.dx;
      fvOffsetY = flippedVisualOffset.dy;
    }
    if (flippedVisualPivot != null) {
      fvPivotX = flippedVisualPivot.dx;
      fvPivotY = flippedVisualPivot.dy;
    }
    if (toolbarOffset != null) {
      tbOffsetX = toolbarOffset.dx;
      tbOffsetY = toolbarOffset.dy;
    }
  }

  @ignore
  Rect get spriteRect => Rect.fromLTWH(rectLeft, rectTop, rectWidth, rectHeight);
  
  @ignore
  Offset get visualOffset => Offset(vOffsetX, vOffsetY);
  
  @ignore
  Offset get visualPivot => Offset(vPivotX, vPivotY);
  
  @ignore
  Offset get toolbarOffset => Offset(tbOffsetX, tbOffsetY);

  @ignore
  Offset? get flippedVisualOffset => (fvOffsetX != null && fvOffsetY != null) 
      ? Offset(fvOffsetX!, fvOffsetY!) 
      : null;
      
  @ignore
  Offset? get flippedVisualPivot => (fvPivotX != null && fvPivotY != null)
      ? Offset(fvPivotX!, fvPivotY!)
      : null;

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'imagePath': imagePath,
      'spriteRect': {
        'l': rectLeft,
        't': rectTop,
        'w': rectWidth,
        'h': rectHeight,
      },
      'gridW': gridW,
      'gridH': gridH,
      'intrinsicWidth': intrinsicWidth,
      'intrinsicHeight': intrinsicHeight,
      'category': category,
      'subCategory': subCategory,
      'quantity': quantity,
      'visualScale': visualScale,
      'visualOffset': {'x': vOffsetX, 'y': vOffsetY},
      'vRotationX': visualRotationX,
      'vRotationY': visualRotationY,
      'vRotationZ': visualRotationZ,
      'vPivot': {'x': vPivotX, 'y': vPivotY},
      'fvScale': flippedVisualScale,
      'fvOffset': fvOffsetX != null ? {'x': fvOffsetX, 'y': fvOffsetY} : null,
      'fvRotationX': flippedVisualRotationX,
      'fvRotationY': flippedVisualRotationY,
      'fvRotationZ': flippedVisualRotationZ,
      'fvPivot': fvPivotX != null ? {'x': fvPivotX, 'y': fvPivotY} : null,
      'toolbarOffset': {'x': tbOffsetX, 'y': tbOffsetY},
      'canBeDyed': canBeDyed,
    };
  }

  FurnitureItem copyWith({
    String? imagePath,
  }) {
    return FurnitureItem(
      id: id,
      name: name,
      imagePath: imagePath ?? this.imagePath,
      spriteRect: spriteRect,
      category: category,
      subCategory: subCategory,
      gridW: gridW,
      gridH: gridH,
      intrinsicWidth: intrinsicWidth,
      intrinsicHeight: intrinsicHeight,
      quantity: quantity,
      visualScale: visualScale,
      visualOffset: visualOffset,
      visualRotationX: visualRotationX,
      visualRotationY: visualRotationY,
      visualRotationZ: visualRotationZ,
      visualPivot: visualPivot,
      flippedVisualScale: flippedVisualScale,
      flippedVisualOffset: flippedVisualOffset,
      flippedVisualRotationX: flippedVisualRotationX,
      flippedVisualRotationY: flippedVisualRotationY,
      flippedVisualRotationZ: flippedVisualRotationZ,
      flippedVisualPivot: flippedVisualPivot,
      toolbarOffset: toolbarOffset,
      canBeDyed: canBeDyed,
      colorVariants: colorVariants,
    );
  }

  factory FurnitureItem.fromMap(Map<String, dynamic> map) {
    final rect = map['spriteRect'] as Map<String, dynamic>;
    return FurnitureItem(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      imagePath: map['imagePath'] ?? '',
      spriteRect: Rect.fromLTWH(
        (rect['l'] as num).toDouble(),
        (rect['t'] as num).toDouble(),
        (rect['w'] as num).toDouble(),
        (rect['h'] as num).toDouble(),
      ),
      gridW: map['gridW'] ?? 1,
      gridH: map['gridH'] ?? 1,
      intrinsicWidth: (map['intrinsicWidth'] as num).toDouble(),
      intrinsicHeight: (map['intrinsicHeight'] as num).toDouble(),
      category: map['category'] ?? '',
      subCategory: map['subCategory'] ?? '',
      quantity: map['quantity'] ?? 3,
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
      canBeDyed: map['canBeDyed'] ?? false,
    );
  }

  @ignore
  bool get isFloor =>
      category.contains('地板') || id.toLowerCase().startsWith('floor');
  
  @ignore
  bool get isWall =>
      category.contains('墙') ||
      id.toLowerCase().contains('wall') ||
      name.contains('挂') ||
      subCategory.contains('挂');
}

bool isCellExcluded(int i, int j) {
  // 不再屏蔽任何区域
  return false;
}
