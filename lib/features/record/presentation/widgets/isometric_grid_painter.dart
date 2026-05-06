import 'package:flutter/material.dart';
import 'dart:math' as math;
import '../../domain/models/furniture_item.dart';
import '../../domain/models/placed_furniture.dart';
import '../utils/isometric_coordinate_utils.dart';
import '../utils/wall_pattern_painter.dart';
import '../pages/decoration_page_constants.dart';
import './isometric_scene_renderer.dart';
import './furniture_renderer.dart';

class IsometricGridPainter extends CustomPainter {
  final int rows;
  final int cols;
  final double fullWidth;
  final double fullHeight;
  final List<PlacedFurniture> placedItems;
  final (FurnitureItem, (int, int)?, int, bool, double)? ghostItem;
  final bool isInteracting;
  final double currentScale;
  final bool showGrid;
  final (int, int)? selectedCell;
  final PlacedFurniture? selectedFurniture;
  final PlacedFurniture? draggingOriginalPF;
  final double centerYFactor;
  final bool isCapturing;
  final PlacedFurniture? bouncingItem;
  final double bounceScale;
  final Color wallColorLeft;
  final Color wallColorRight;
  final WallPattern wallPattern;
  final Color floorColor;

  IsometricGridPainter({
    required this.rows,
    required this.cols,
    required this.fullWidth,
    required this.fullHeight,
    this.selectedCell,
    this.placedItems = const [],
    this.ghostItem,
    this.selectedFurniture,
    required this.centerYFactor,
    this.isCapturing = false,
    this.showGrid = true,
    this.isInteracting = false,
    this.currentScale = 1.0,
    this.draggingOriginalPF,
    this.bouncingItem,
    this.bounceScale = 1.0,
    this.wallColorLeft = const Color(0xFFDEDCCE),
    this.wallColorRight = const Color(0xFFDEDCCE),
    this.wallPattern = WallPattern.none,
    this.floorColor = const Color(0xFFF1EBD1),
  });

  @override
  void paint(Canvas canvas, Size size) {
    final double centerX = fullWidth / 2;
    final double centerY = fullHeight * centerYFactor;
    final double tw = fullWidth / 50;
    final double th = tw * kGridAspectRatio;
    final converter = IsometricCoordinateConverter(centerX: centerX, centerY: centerY, tw: tw, th: th);

    // 旋转整体网格
    canvas.save();
    canvas.translate(centerX, centerY);
    canvas.rotate(kGridRotationDegree * math.pi / 180);
    canvas.translate(-centerX, -centerY);

    final outlinePaint = Paint()
      ..color = const Color(0xFF3B3B36)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2
      ..strokeJoin = StrokeJoin.round
      ..strokeCap = StrokeCap.round;

    // 1. 绘制场景基础外壳
    IsometricSceneRenderer.drawWallShell(
      canvas: canvas,
      converter: converter,
      rows: rows,
      cols: cols,
      wallColorLeft: wallColorLeft,
      wallColorRight: wallColorRight,
      outlinePaint: outlinePaint,
    );

    // 2. 绘制墙面花纹
    WallPatternPainter.paint(
      canvas: canvas,
      converter: converter,
      pattern: wallPattern,
      isLeft: true,
      rows: rows,
      cols: cols,
      baseColor: wallColorLeft,
    );
    WallPatternPainter.paint(
      canvas: canvas,
      converter: converter,
      pattern: wallPattern,
      isLeft: false,
      rows: rows,
      cols: cols,
      baseColor: wallColorRight,
    );

    // 3. 绘制墙体轮廓（在花纹之后，确保遮盖花纹边缘，解决层级问题）
    IsometricSceneRenderer.drawWallOutline(
      canvas: canvas,
      converter: converter,
      rows: rows,
      cols: cols,
      outlinePaint: outlinePaint,
    );

    // 4. 绘制地面外壳
    IsometricSceneRenderer.drawFloorShell(
      canvas: canvas,
      converter: converter,
      rows: rows,
      cols: cols,
      floorColor: floorColor,
      outlinePaint: outlinePaint,
    );

    // 4. 绘制网格线
    if (showGrid && !isCapturing) {
      IsometricSceneRenderer.drawGrid(
        canvas: canvas,
        converter: converter,
        rows: rows,
        cols: cols,
        showLabels: !isInteracting && currentScale >= 2.0,
      );
    }

    // 5. 分类并绘制家具
    _drawAllFurniture(canvas, converter, tw, th);

    // 6. 绘制拖拽预览 (Ghost)
    if (ghostItem != null && ghostItem!.$2 != null) {
      final cell = ghostItem!.$2!;
      FurnitureRenderer.draw(
        canvas: canvas,
        item: ghostItem!.$1,
        r: cell.$1,
        c: cell.$2,
        z: ghostItem!.$5,
        rotation: ghostItem!.$3,
        converter: converter,
        tw: tw,
        th: th,
        opacity: 0.6,
        isValid: ghostItem!.$4,
      );
    }

    canvas.restore();
  }

  void _drawAllFurniture(Canvas canvas, IsometricCoordinateConverter converter, double tw, double th) {
    // 基础分类排序 (这里简化了排序逻辑，保持原有逻辑)
    final List<PlacedFurniture> sortedItems = List<PlacedFurniture>.from(placedItems.where((pf) => pf != draggingOriginalPF))
      ..sort((a, b) {
        if (a.item.isFloor != b.item.isFloor) return a.item.isFloor ? -1 : 1;
        if (a.item.isWall != b.item.isWall) return a.item.isWall ? -1 : 1;
        
        bool aIsCarpet = a.item.subCategory == '地毯';
        bool bIsCarpet = b.item.subCategory == '地毯';
        if (aIsCarpet != bIsCarpet) return aIsCarpet ? -1 : 1;

        // 深度排序
        final depthA = a.r + a.c + a.z;
        final depthB = b.r + b.c + b.z;
        return depthA.compareTo(depthB);
      });

    for (final pf in sortedItems) {
      if (pf == selectedFurniture) {
        FurnitureRenderer.drawSelectionFootprint(canvas, pf, converter, tw, th);
      }
      FurnitureRenderer.draw(
        canvas: canvas,
        item: pf.item,
        r: pf.r,
        c: pf.c,
        z: pf.z,
        rotation: pf.rotation,
        converter: converter,
        tw: tw,
        th: th,
        bounceScale: (pf == bouncingItem) ? bounceScale : 1.0,
      );
    }
  }

  @override
  bool shouldRepaint(covariant IsometricGridPainter oldDelegate) {
    return oldDelegate.placedItems != placedItems ||
        oldDelegate.ghostItem != ghostItem ||
        oldDelegate.selectedFurniture != selectedFurniture ||
        oldDelegate.selectedCell != selectedCell ||
        oldDelegate.isInteracting != isInteracting ||
        oldDelegate.currentScale != currentScale ||
        oldDelegate.showGrid != showGrid ||
        oldDelegate.draggingOriginalPF != draggingOriginalPF ||
        oldDelegate.bouncingItem != bouncingItem ||
        oldDelegate.bounceScale != bounceScale ||
        oldDelegate.wallColorLeft != wallColorLeft ||
        oldDelegate.wallColorRight != wallColorRight ||
        oldDelegate.wallPattern != wallPattern ||
        oldDelegate.floorColor != floorColor;
  }
}
