import 'package:flutter/material.dart';

class FurnitureColorVariant {
  final String id;
  final String name;
  final String imagePath;
  final int colorValue;
  final int dyeCost;
  final int goldCost;

  Color get color => Color(colorValue);

  FurnitureColorVariant({
    required this.id,
    required this.name,
    required this.imagePath,
    int? colorValue,
    Color? color,
    this.dyeCost = 1,
    this.goldCost = 100,
  }) : colorValue = colorValue ?? (color?.toARGB32() ?? 0);

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'imagePath': imagePath,
      'colorValue': colorValue,
      'dyeCost': dyeCost,
      'goldCost': goldCost,
    };
  }

  factory FurnitureColorVariant.fromMap(Map<String, dynamic> map) {
    return FurnitureColorVariant(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      imagePath: map['imagePath'] ?? '',
      colorValue: map['colorValue'] as int?,
      dyeCost: map['dyeCost'] as int? ?? 1,
      goldCost: map['goldCost'] as int? ?? 100,
    );
  }
}

class FurnitureItem {
  static void Function(FurnitureItem item)? itemMigrator;

  String id;
  String name;
  String imagePath;

  double rectLeft;
  double rectTop;
  double rectWidth;
  double rectHeight;

  int gridW;
  int gridH;
  double intrinsicWidth;
  double intrinsicHeight;
  String category;
  String subCategory;
  double visualScale;
  String description;
  String style;
  double? surfaceHeight; // 家具表面的高度
  bool canStack; // 是否可以堆叠在其他家具上

  double vOffsetX;
  double vOffsetY;

  double visualRotationX;
  double visualRotationY;
  double visualRotationZ;

  double vPivotX;
  double vPivotY;

  double tbOffsetX;
  double tbOffsetY;

  bool canBeDyed;
  List<FurnitureColorVariant> colorVariants;

  double? flippedVisualScale;
  double? fvOffsetX;
  double? fvOffsetY;
  double? flippedVisualRotationX;
  double? flippedVisualRotationY;
  double? flippedVisualRotationZ;
  double? fvPivotX;
  double? fvPivotY;

  int quantity;

  FurnitureItem({
    this.id = '',
    this.name = '',
    this.imagePath = '',
    Rect? spriteRect,
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
    Offset? visualOffset,
    this.vOffsetX = 0,
    this.vOffsetY = 0,
    this.visualRotationX = 0,
    this.visualRotationY = 0,
    this.visualRotationZ = 0,
    Offset? visualPivot,
    this.vPivotX = 0,
    this.vPivotY = 0,
    this.flippedVisualScale,
    Offset? flippedVisualOffset,
    this.fvOffsetX,
    this.fvOffsetY,
    this.flippedVisualRotationX,
    this.flippedVisualRotationY,
    this.flippedVisualRotationZ,
    Offset? flippedVisualPivot,
    this.fvPivotX,
    this.fvPivotY,
    Offset? toolbarOffset,
    this.tbOffsetX = 0,
    this.tbOffsetY = 0,
    this.canBeDyed = false,
    this.colorVariants = const [],
    this.description = '',
    this.style = '常规',
    this.surfaceHeight,
    this.canStack = false,
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

  Rect get spriteRect =>
      Rect.fromLTWH(rectLeft, rectTop, rectWidth, rectHeight);

  Offset get visualOffset => Offset(vOffsetX, vOffsetY);

  Offset get visualPivot => Offset(vPivotX, vPivotY);

  Offset get toolbarOffset => Offset(tbOffsetX, tbOffsetY);

  Offset? get flippedVisualOffset => (fvOffsetX != null && fvOffsetY != null)
      ? Offset(fvOffsetX!, fvOffsetY!)
      : null;

  Offset? get flippedVisualPivot => (fvPivotX != null && fvPivotY != null)
      ? Offset(fvPivotX!, fvPivotY!)
      : null;

  bool get isFloor =>
      category.contains('地板') || id.toLowerCase().startsWith('floor');

  bool get isWall =>
      category.contains('墙') ||
      id.toLowerCase().contains('wall') ||
      name.contains('挂') ||
      subCategory.contains('挂');

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'imagePath': imagePath,
      'category': category,
      'subCategory': subCategory,
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
      'quantity': quantity,
      'visualScale': visualScale,
      'surfaceHeight': surfaceHeight,
      'canStack': canStack,
      'description': description,
      'style': style,
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
      'colorVariants': colorVariants.map((v) => v.toMap()).toList(),
    };
  }

  FurnitureItem copyWith({
    String? imagePath,
    String? category,
    String? subCategory,
    double? surfaceHeight,
    bool? canStack,
    String? description,
    String? style,
  }) {
    return FurnitureItem(
      id: id,
      name: name,
      imagePath: imagePath ?? this.imagePath,
      spriteRect: spriteRect,
      category: category ?? this.category,
      subCategory: subCategory ?? this.subCategory,
      gridW: gridW,
      gridH: gridH,
      intrinsicWidth: intrinsicWidth,
      intrinsicHeight: intrinsicHeight,
      quantity: quantity,
      visualScale: visualScale,
      visualOffset: visualOffset,
      surfaceHeight: surfaceHeight ?? this.surfaceHeight,
      canStack: canStack ?? this.canStack,
      description: description ?? this.description,
      style: style ?? this.style,
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
    final item = FurnitureItem(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      imagePath: map['imagePath'] ?? '',
      category: map['category'] ?? '',
      subCategory: map['subCategory'] ?? '',
      spriteRect: Rect.fromLTWH(
        (rect['l'] as num).toDouble(),
        (rect['t'] as num).toDouble(),
        (rect['w'] as num).toDouble(),
        (rect['h'] as num).toDouble(),
      ),
      gridW: map['gridW'] ?? 1,
      gridH: map['gridH'] ?? 1,
      intrinsicWidth: (map['intrinsicWidth'] as num).toDouble(),
      intrinsicHeight: (map['intrinsicHeight'] as num?)?.toDouble() ?? 1.0,
      quantity: map['quantity'] ?? 3,
      visualScale: (map['visualScale'] as num?)?.toDouble() ?? 1.0,
      surfaceHeight: (map['surfaceHeight'] as num?)?.toDouble(),
      canStack: map['canStack'] ?? false,
      description: map['description'] ?? '',
      style: map['style'] ?? '常规',
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
      colorVariants: (map['colorVariants'] as List?)
              ?.map((v) => FurnitureColorVariant.fromMap(v))
              .toList() ??
          const [],
    );
    itemMigrator?.call(item);
    return item;
  }
}

bool isCellExcluded(int i, int j) {
  return false;
}
