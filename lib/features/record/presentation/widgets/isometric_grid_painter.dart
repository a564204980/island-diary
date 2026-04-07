import 'package:flutter/material.dart';
import 'dart:math' as math;
import 'package:vector_math/vector_math_64.dart' hide Colors;
import '../../domain/models/furniture_item.dart';
import '../../domain/models/placed_furniture.dart';
import '../utils/isometric_coordinate_utils.dart';
import '../pages/decoration_page_constants.dart';
import 'furniture_sprite.dart';

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
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.15)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    final double centerX = fullWidth / 2;
    final double centerY = fullHeight * centerYFactor;

    // 旋转整体网格
    canvas.save();
    canvas.translate(centerX, centerY);
    canvas.rotate(kGridRotationDegree * math.pi / 180);
    canvas.translate(-centerX, -centerY);

    // 单个菱形格子的尺寸
    final double tw = fullWidth / 28;
    final double th = tw * kGridAspectRatio;

    // 初始化统一的坐标转换工具
    final converter = IsometricCoordinateConverter(
      centerX: centerX,
      centerY: centerY,
      tw: tw,
      th: th,
    );

    // --- 0. 绘制墙面底层染色 ---
    // 左墙区域 (XZ 面)
    final leftWallPath = Path()
      ..moveTo(converter.getScreenPoint(0, 0, 0).dx, converter.getScreenPoint(0, 0, 0).dy)
      ..lineTo(converter.getScreenPoint(rows.toDouble(), 0, 0).dx, converter.getScreenPoint(rows.toDouble(), 0, 0).dy)
      ..lineTo(converter.getScreenPoint(rows.toDouble(), 0, kWallGridHeight.toDouble()).dx, converter.getScreenPoint(rows.toDouble(), 0, kWallGridHeight.toDouble()).dy)
      ..lineTo(converter.getScreenPoint(0, 0, kWallGridHeight.toDouble()).dx, converter.getScreenPoint(0, 0, kWallGridHeight.toDouble()).dy)
      ..close();
    
    // 右墙区域 (YZ 面)
    final rightWallPath = Path()
      ..moveTo(converter.getScreenPoint(0, 0, 0).dx, converter.getScreenPoint(0, 0, 0).dy)
      ..lineTo(converter.getScreenPoint(0, cols.toDouble(), 0).dx, converter.getScreenPoint(0, cols.toDouble(), 0).dy)
      ..lineTo(converter.getScreenPoint(0, cols.toDouble(), kWallGridHeight.toDouble()).dx, converter.getScreenPoint(0, cols.toDouble(), kWallGridHeight.toDouble()).dy)
      ..lineTo(converter.getScreenPoint(0, 0, kWallGridHeight.toDouble()).dx, converter.getScreenPoint(0, 0, kWallGridHeight.toDouble()).dy)
      ..close();

    // 结构轮廓线画笔 (深咖色，矢量手绘感)
    final outlinePaint = Paint()
      ..color = const Color(0xFF3B3B36)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2
      ..strokeJoin = StrokeJoin.round
      ..strokeCap = StrokeCap.round;

    canvas.drawPath(leftWallPath, Paint()..color = wallColorLeft..style = PaintingStyle.fill);
    canvas.drawPath(rightWallPath, Paint()..color = wallColorRight..style = PaintingStyle.fill);
    
    // 绘制墙面主轮廓线
    canvas.drawPath(leftWallPath, outlinePaint);
    canvas.drawPath(rightWallPath, outlinePaint);

    // --- 0.1 绘制墙体厚度效果 (3D 立体感) ---
    final hslLeft = HSLColor.fromColor(wallColorLeft);
    final hslRight = HSLColor.fromColor(wallColorRight);
    
    // 顶部厚度面 (略亮)
    final topPaintLeft = Paint()..color = hslLeft.withLightness((hslLeft.lightness + 0.12).clamp(0.0, 1.0)).toColor()..style = PaintingStyle.fill;
    final topPaintRight = Paint()..color = hslRight.withLightness((hslRight.lightness + 0.12).clamp(0.0, 1.0)).toColor()..style = PaintingStyle.fill;
    
    // 侧面截断面 (略暗)
    final sidePaintLeft = Paint()..color = hslLeft.withLightness((hslLeft.lightness - 0.08).clamp(0.0, 1.0)).toColor()..style = PaintingStyle.fill;
    final sidePaintRight = Paint()..color = hslRight.withLightness((hslRight.lightness - 0.08).clamp(0.0, 1.0)).toColor()..style = PaintingStyle.fill;

    // A. 左墙顶部面
    final leftTopPath = Path()
      ..moveTo(converter.getScreenPoint(0, 0, kWallGridHeight.toDouble()).dx, converter.getScreenPoint(0, 0, kWallGridHeight.toDouble()).dy)
      ..lineTo(converter.getScreenPoint(rows.toDouble(), 0, kWallGridHeight.toDouble()).dx, converter.getScreenPoint(rows.toDouble(), 0, kWallGridHeight.toDouble()).dy)
      ..lineTo(converter.getScreenPoint(rows.toDouble(), -kWallThickness, kWallGridHeight.toDouble()).dx, converter.getScreenPoint(rows.toDouble(), -kWallThickness, kWallGridHeight.toDouble()).dy)
      ..lineTo(converter.getScreenPoint(0, -kWallThickness, kWallGridHeight.toDouble()).dx, converter.getScreenPoint(0, -kWallThickness, kWallGridHeight.toDouble()).dy)
      ..close();
    canvas.drawPath(leftTopPath, topPaintLeft);
    canvas.drawPath(leftTopPath, outlinePaint);

    // B. 右墙顶部面
    final rightTopPath = Path()
      ..moveTo(converter.getScreenPoint(0, 0, kWallGridHeight.toDouble()).dx, converter.getScreenPoint(0, 0, kWallGridHeight.toDouble()).dy)
      ..lineTo(converter.getScreenPoint(0, cols.toDouble(), kWallGridHeight.toDouble()).dx, converter.getScreenPoint(0, cols.toDouble(), kWallGridHeight.toDouble()).dy)
      ..lineTo(converter.getScreenPoint(-kWallThickness, cols.toDouble(), kWallGridHeight.toDouble()).dx, converter.getScreenPoint(-kWallThickness, cols.toDouble(), kWallGridHeight.toDouble()).dy)
      ..lineTo(converter.getScreenPoint(-kWallThickness, 0, kWallGridHeight.toDouble()).dx, converter.getScreenPoint(-kWallThickness, 0, kWallGridHeight.toDouble()).dy)
      ..close();
    canvas.drawPath(rightTopPath, topPaintRight);
    canvas.drawPath(rightTopPath, outlinePaint);

    // C. 远端侧面截断 (仅当 rows/cols 较大时可见)
    final leftEndPath = Path()
      ..moveTo(converter.getScreenPoint(rows.toDouble(), 0, 0).dx, converter.getScreenPoint(rows.toDouble(), 0, 0).dy)
      ..lineTo(converter.getScreenPoint(rows.toDouble(), -kWallThickness, 0).dx, converter.getScreenPoint(rows.toDouble(), -kWallThickness, 0).dy)
      ..lineTo(converter.getScreenPoint(rows.toDouble(), -kWallThickness, kWallGridHeight.toDouble()).dx, converter.getScreenPoint(rows.toDouble(), -kWallThickness, kWallGridHeight.toDouble()).dy)
      ..lineTo(converter.getScreenPoint(rows.toDouble(), 0, kWallGridHeight.toDouble()).dx, converter.getScreenPoint(rows.toDouble(), 0, kWallGridHeight.toDouble()).dy)
      ..close();
    canvas.drawPath(leftEndPath, sidePaintLeft);
    canvas.drawPath(leftEndPath, outlinePaint);

    final rightEndPath = Path()
      ..moveTo(converter.getScreenPoint(0, cols.toDouble(), 0).dx, converter.getScreenPoint(0, cols.toDouble(), 0).dy)
      ..lineTo(converter.getScreenPoint(-kWallThickness, cols.toDouble(), 0).dx, converter.getScreenPoint(-kWallThickness, cols.toDouble(), 0).dy)
      ..lineTo(converter.getScreenPoint(-kWallThickness, cols.toDouble(), kWallGridHeight.toDouble()).dx, converter.getScreenPoint(-kWallThickness, cols.toDouble(), kWallGridHeight.toDouble()).dy)
      ..lineTo(converter.getScreenPoint(0, cols.toDouble(), kWallGridHeight.toDouble()).dx, converter.getScreenPoint(0, cols.toDouble(), kWallGridHeight.toDouble()).dy)
      ..close();
    canvas.drawPath(rightEndPath, sidePaintRight);
    canvas.drawPath(rightEndPath, outlinePaint);

    // D. 墙角连接处 (Corner Cap)
    final cornerPath = Path()
      ..moveTo(converter.getScreenPoint(0, 0, kWallGridHeight.toDouble()).dx, converter.getScreenPoint(0, 0, kWallGridHeight.toDouble()).dy)
      ..lineTo(converter.getScreenPoint(-kWallThickness, 0, kWallGridHeight.toDouble()).dx, converter.getScreenPoint(-kWallThickness, 0, kWallGridHeight.toDouble()).dy)
      ..lineTo(converter.getScreenPoint(-kWallThickness, -kWallThickness, kWallGridHeight.toDouble()).dx, converter.getScreenPoint(-kWallThickness, -kWallThickness, kWallGridHeight.toDouble()).dy)
      ..lineTo(converter.getScreenPoint(0, -kWallThickness, kWallGridHeight.toDouble()).dx, converter.getScreenPoint(0, -kWallThickness, kWallGridHeight.toDouble()).dy)
      ..close();
    canvas.drawPath(cornerPath, topPaintLeft); // 使用左侧明度即可，保持一致
    canvas.drawPath(cornerPath, outlinePaint);

    // --- 0.2 绘制地面厚度效果 (3D 基座) ---
    // 左前侧面 (考虑墙体厚度延伸，起始点设为 (rows, -kWallThickness))
    final floorLeftFacePath = Path()
      ..moveTo(converter.getScreenPoint(rows.toDouble(), -kWallThickness, 0).dx, converter.getScreenPoint(rows.toDouble(), -kWallThickness, 0).dy)
      ..lineTo(converter.getScreenPoint(rows.toDouble(), cols.toDouble(), 0).dx, converter.getScreenPoint(rows.toDouble(), cols.toDouble(), 0).dy)
      ..lineTo(converter.getScreenPoint(rows.toDouble(), cols.toDouble(), -kWallThickness).dx, converter.getScreenPoint(rows.toDouble(), cols.toDouble(), -kWallThickness).dy)
      ..lineTo(converter.getScreenPoint(rows.toDouble(), -kWallThickness, -kWallThickness).dx, converter.getScreenPoint(rows.toDouble(), -kWallThickness, -kWallThickness).dy)
      ..close();

    // 右前侧面 (考虑墙体厚度延伸，起始点设为 (-kWallThickness, cols))
    final floorRightFacePath = Path()
      ..moveTo(converter.getScreenPoint(-kWallThickness, cols.toDouble(), 0).dx, converter.getScreenPoint(-kWallThickness, cols.toDouble(), 0).dy)
      ..lineTo(converter.getScreenPoint(rows.toDouble(), cols.toDouble(), 0).dx, converter.getScreenPoint(rows.toDouble(), cols.toDouble(), 0).dy)
      ..lineTo(converter.getScreenPoint(rows.toDouble(), cols.toDouble(), -kWallThickness).dx, converter.getScreenPoint(rows.toDouble(), cols.toDouble(), -kWallThickness).dy)
      ..lineTo(converter.getScreenPoint(-kWallThickness, cols.toDouble(), -kWallThickness).dx, converter.getScreenPoint(-kWallThickness, cols.toDouble(), -kWallThickness).dy)
      ..close();

    // 地面侧面颜色 (使用中性的灰褐色 Foundation Color)
    final floorSideColor = const Color(0xFFD2D0C5);
    final hslFloorSide = HSLColor.fromColor(floorSideColor);
    final floorSidePaintLeft = Paint()..color = hslFloorSide.toColor()..style = PaintingStyle.fill;
    final floorSidePaintRight = Paint()..color = hslFloorSide.withLightness((hslFloorSide.lightness - 0.05).clamp(0.0, 1.0)).toColor()..style = PaintingStyle.fill;

    canvas.drawPath(floorLeftFacePath, floorSidePaintLeft);
    canvas.drawPath(floorRightFacePath, floorSidePaintRight);
    canvas.drawPath(floorLeftFacePath, outlinePaint);
    canvas.drawPath(floorRightFacePath, outlinePaint);

    // 如果正在截图或用户手动关闭网格，跳过网格线和序号的绘制
    if (showGrid && !isCapturing) {
      // --- 1. 绘制地面网格 (XY 平面) ---
      for (int j = 0; j <= cols; j++) {
        for (int i = 0; i < rows; i++) {
          final start = converter.getScreenPoint(i.toDouble(), j.toDouble());
          final end = converter.getScreenPoint(
            (i + 1).toDouble(),
            j.toDouble(),
          );
          canvas.drawLine(start, end, paint);
        }
      }
      for (int i = 0; i <= rows; i++) {
        for (int j = 0; j < cols; j++) {
          final start = converter.getScreenPoint(i.toDouble(), j.toDouble());
          final end = converter.getScreenPoint(
            i.toDouble(),
            (j + 1).toDouble(),
          );
          canvas.drawLine(start, end, paint);
        }
      }

      // --- 3. 绘制地面网格坐标序号 (性能关键：交互时或缩放过小时必须隐藏，避免 TextPainter.layout 阻塞主线程) ---
      final bool shouldShowLabels =
          showGrid && !isCapturing && !isInteracting && currentScale >= 2.0;

      if (shouldShowLabels) {
        final textStyle = TextStyle(
          color: Colors.white.withOpacity(0.35),
          fontSize: 6.0,
          fontWeight: FontWeight.w300,
        );

        for (int i = 0; i < rows; i++) {
          for (int j = 0; j < cols; j++) {
            final center = converter.getScreenPoint(i + 0.5, j + 0.5);

            final textPainter = TextPainter(
              text: TextSpan(text: '$i,$j', style: textStyle),
              textDirection: TextDirection.ltr,
            );
            textPainter.layout();

            textPainter.paint(
              canvas,
              center - Offset(textPainter.width / 2, textPainter.height / 2),
            );
          }
        }

        // --- 墙面网格坐标序号 ---
        final wallTextStyle = TextStyle(
          color: Colors.white.withOpacity(0.3),
          fontSize: 6.0,
          fontWeight: FontWeight.w300,
        );

        // 左墙 XZ 面 (i, z)
        for (int i = 0; i < rows; i += 1) {
          for (int z = 0; z < kWallGridHeight; z += 1) {
            final center = converter.getScreenPoint(i + 0.5, 0, z + 0.5);
            final tp = TextPainter(
              text: TextSpan(text: '$i,$z', style: wallTextStyle),
              textDirection: TextDirection.ltr,
            );
            tp.layout();
            tp.paint(canvas, center - Offset(tp.width / 2, tp.height / 2));
          }
        }

        // 右墙 YZ 面 (j, z)
        for (int j = 0; j < cols; j += 1) {
          for (int z = 0; z < kWallGridHeight; z += 1) {
            final center = converter.getScreenPoint(0, j + 0.5, z + 0.5);
            final tp = TextPainter(
              text: TextSpan(text: '$j,$z', style: wallTextStyle),
              textDirection: TextDirection.ltr,
            );
            tp.layout();
            tp.paint(canvas, center - Offset(tp.width / 2, tp.height / 2));
          }
        }
      }

      // --- 2. 绘制墙面网格 (XZ 和 YZ 平面) ---
      final wallPaint = Paint()
        ..color = Colors.white.withOpacity(0.15)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.0;

      // 左后墙 (XZ 面, 沿 j=0)
      for (int i = 0; i <= rows; i++) {
        final bottom = converter.getScreenPoint(i.toDouble(), 0);
        final top = converter.getScreenPoint(
          i.toDouble(),
          0,
          kWallGridHeight.toDouble(),
        );
        canvas.drawLine(bottom, top, wallPaint);
      }
      for (int z = 1; z <= kWallGridHeight; z++) {
        final start = converter.getScreenPoint(0, 0, z.toDouble());
        final end = converter.getScreenPoint(rows.toDouble(), 0, z.toDouble());
        canvas.drawLine(start, end, wallPaint);
      }

      // 右后墙 (YZ 面, 沿 i=0)
      for (int j = 0; j <= cols; j++) {
        final bottom = converter.getScreenPoint(0, j.toDouble());
        final top = converter.getScreenPoint(
          0,
          j.toDouble(),
          kWallGridHeight.toDouble(),
        );
        canvas.drawLine(bottom, top, wallPaint);
      }
      for (int z = 1; z <= kWallGridHeight; z++) {
        final start = converter.getScreenPoint(0, 0, z.toDouble());
        final end = converter.getScreenPoint(0, cols.toDouble(), z.toDouble());
        canvas.drawLine(start, end, wallPaint);
      }
    }

    // --- 性能优化：一次迭代完成所有分类，避免 4 次 .where().toList() 导致的 GC 压力 ---
    final List<PlacedFurniture> floors = [];
    final List<PlacedFurniture> carpets = [];
    final List<PlacedFurniture> wallItems = [];
    final List<PlacedFurniture> others = [];
    final List<PlacedFurniture> softDecorations = [];

    for (final pf in placedItems) {
      if (pf == draggingOriginalPF) continue;
      final sub = pf.item.subCategory;
      if (pf.item.isFloor) {
        floors.add(pf);
      } else if (pf.item.isWall) {
        wallItems.add(pf);
      } else if (sub == '地毯') {
        carpets.add(pf);
      } else if (sub == '软装') {
        softDecorations.add(pf);
      } else {
        others.add(pf);
      }
    }

    // 1. 绘制地板层
    for (final pf in floors) {
      final double bScale = (pf == bouncingItem) ? bounceScale : 1.0;
      _drawFurniture(
        canvas,
        pf.item,
        pf.r,
        pf.c,
        pf.z,
        converter,
        tw,
        th,
        1.0,
        pf.rotation,
        true,
        bScale,
      );
    }

    if (selectedFurniture != null && selectedFurniture!.item.isFloor) {
      _drawSelectionFootprint(canvas, selectedFurniture!, converter, tw, th);
    }

    // 2. 绘制墙面层 (此时墙面是背景，应早于地毯和家具绘制)
    final sortedWalls = List<PlacedFurniture>.from(wallItems)
      ..sort((a, b) {
        // 修正墙面足迹计算：沿墙长度为 gridW，厚度为 1
        int gwA = a.rotation % 2 == 0 ? a.item.gridW : 1;
        int ghA = a.rotation % 2 == 0 ? 1 : a.item.gridW;
        int gwB = b.rotation % 2 == 0 ? b.item.gridW : 1;
        int ghB = b.rotation % 2 == 0 ? 1 : b.item.gridW;
        
        if (a.r + gwA <= b.r || a.c + ghA <= b.c) return -1;
        if (b.r + gwB <= a.r || b.c + ghB <= a.c) return 1;
        final depthA = a.r + gwA / 2.0 + a.c + ghA / 2.0;
        final depthB = b.r + gwB / 2.0 + b.c + ghB / 2.0;
        return depthA.compareTo(depthB);
      });

    for (final pf in sortedWalls) {
      if (pf == selectedFurniture) {
        _drawSelectionFootprint(canvas, pf, converter, tw, th);
      }
      final double bScale = (pf == bouncingItem) ? bounceScale : 1.0;
      _drawFurniture(
        canvas,
        pf.item,
        pf.r,
        pf.c,
        pf.z,
        converter,
        tw,
        th,
        1.0,
        pf.rotation,
        true,
        bScale,
      );
    }

    // 3. 绘制地毯层
    for (final pf in carpets) {
      if (pf == selectedFurniture) {
        _drawSelectionFootprint(canvas, pf, converter, tw, th);
      }
      final double bScale = (pf == bouncingItem) ? bounceScale : 1.0;
      _drawFurniture(
        canvas,
        pf.item,
        pf.r,
        pf.c,
        pf.z,
        converter,
        tw,
        th,
        1.0,
        pf.rotation,
        true,
        bScale,
      );
    }

    // 4. 绘制主体家具层
    final sortedOthers = List<PlacedFurniture>.from(others)
      ..sort((a, b) {
        // 主体家具均为地面物品，gw/gh 直接根据旋转状态切换
        int gwA = a.rotation % 2 == 0 ? a.item.gridW : a.item.gridH;
        int ghA = a.rotation % 2 == 0 ? a.item.gridH : a.item.gridW;
        int gwB = b.rotation % 2 == 0 ? b.item.gridW : b.item.gridH;
        int ghB = b.rotation % 2 == 0 ? b.item.gridH : b.item.gridW;
        if (a.r + gwA <= b.r || a.c + ghA <= b.c) return -1;
        if (b.r + gwB <= a.r || b.c + ghB <= a.c) return 1;
        final depthA = a.r + gwA / 2.0 + a.c + ghA / 2.0;
        final depthB = b.r + gwB / 2.0 + b.c + ghB / 2.0;
        return depthA.compareTo(depthB);
      });

    for (final pf in sortedOthers) {
      if (pf == selectedFurniture) {
        _drawSelectionFootprint(canvas, pf, converter, tw, th);
      }
      final double bScale = (pf == bouncingItem) ? bounceScale : 1.0;
      _drawFurniture(
        canvas,
        pf.item,
        pf.r,
        pf.c,
        pf.z,
        converter,
        tw,
        th,
        1.0,
        pf.rotation,
        true,
        bScale,
      );
    }

    // 4. 绘制软装饰品层 (报枕、摆放物件)
    final sortedSoftDecorations = List<PlacedFurniture>.from(softDecorations)
      ..sort((a, b) {
        int gwA = a.rotation % 2 == 0 ? a.item.gridW : a.item.gridH;
        int ghA = a.rotation % 2 == 0 ? a.item.gridH : a.item.gridW;
        int gwB = b.rotation % 2 == 0 ? b.item.gridW : b.item.gridH;
        int ghB = b.rotation % 2 == 0 ? b.item.gridH : b.item.gridW;
        if (a.r + gwA <= b.r || a.c + ghA <= b.c) return -1;
        if (b.r + gwB <= a.r || b.c + ghB <= a.c) return 1;
        final depthA = a.r + gwA / 2.0 + a.c + ghA / 2.0;
        final depthB = b.r + gwB / 2.0 + b.c + ghB / 2.0;
        return depthA.compareTo(depthB);
      });

    for (final pf in sortedSoftDecorations) {
      if (pf == selectedFurniture) {
        _drawSelectionFootprint(canvas, pf, converter, tw, th);
      }
      final double bScale = (pf == bouncingItem) ? bounceScale : 1.0;
      _drawFurniture(
        canvas,
        pf.item,
        pf.r,
        pf.c,
        pf.z,
        converter,
        tw,
        th,
        1.0,
        pf.rotation,
        true,
        bScale,
      );
    }

    // --- 绘制拖拽预览 (Ghost) ---
    if (ghostItem != null && ghostItem!.$2 != null) {
      _drawFurniture(
        canvas,
        ghostItem!.$1,
        ghostItem!.$2!.$1,
        ghostItem!.$2!.$2,
        ghostItem!.$5,
        converter,
        tw,
        th,
        0.5,
        ghostItem!.$3,
        ghostItem!.$4,
      );
    }

    if (selectedCell != null && selectedFurniture == null) {
      _drawSelectionCell(canvas, selectedCell!, converter, tw, th);
    }
    canvas.restore();
  }

  void _drawSelectionFootprint(
    Canvas canvas,
    PlacedFurniture pf,
    IsometricCoordinateConverter converter,
    double tw,
    double th,
  ) {
    final Offset p0, p1, p2, p3;
    if (pf.item.isWall) {
      final double h = pf.item.gridH.toDouble();
      final double l = pf.item.gridW.toDouble();
      final double baseZ = pf.z;
      if (pf.rotation % 2 == 0) {
        p0 = converter.getScreenPoint(pf.r.toDouble(), pf.c.toDouble(), baseZ + h);
        p1 = converter.getScreenPoint(pf.r + l, pf.c.toDouble(), baseZ + h);
        p2 = converter.getScreenPoint(pf.r + l, pf.c.toDouble(), baseZ);
        p3 = converter.getScreenPoint(pf.r.toDouble(), pf.c.toDouble(), baseZ);
      } else {
        p0 = converter.getScreenPoint(pf.r.toDouble(), pf.c.toDouble(), baseZ + h);
        p1 = converter.getScreenPoint(pf.r.toDouble(), pf.c + l, baseZ + h);
        p2 = converter.getScreenPoint(pf.r.toDouble(), pf.c + l, baseZ);
        p3 = converter.getScreenPoint(pf.r.toDouble(), pf.c.toDouble(), baseZ);
      }
    } else {
      int gw = pf.item.gridW;
      int gh = pf.item.gridH;
      if (pf.rotation % 2 != 0) {
        gw = pf.item.gridH;
        gh = pf.item.gridW;
      }
      p0 = converter.getScreenPoint(pf.r.toDouble(), pf.c.toDouble(), pf.z);
      p1 = converter.getScreenPoint((pf.r + gw).toDouble(), pf.c.toDouble(), pf.z);
      p2 = converter.getScreenPoint((pf.r + gw).toDouble(), (pf.c + gh).toDouble(), pf.z);
      p3 = converter.getScreenPoint(pf.r.toDouble(), (pf.c + gh).toDouble(), pf.z);
    }
    final path = Path()
      ..moveTo(p0.dx, p0.dy)
      ..lineTo(p1.dx, p1.dy)
      ..lineTo(p2.dx, p2.dy)
      ..lineTo(p3.dx, p3.dy)
      ..close();
    canvas.drawPath(
      path,
      Paint()
        ..color = Colors.yellow.withOpacity(0.2)
        ..style = PaintingStyle.fill,
    );
    canvas.drawPath(
      path,
      Paint()
        ..color = Colors.yellow
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3.0,
    );
  }

  void _drawFurniture(
    Canvas canvas,
    FurnitureItem item,
    int r,
    int c,
    double z,
    IsometricCoordinateConverter converter,
    double tw,
    double th,
    double opacity, [
    int rotation = 0,
    bool isValid = true,
    double currentBounceScale = 1.0,
  ]) {
    int gw = item.gridW;
    int gh = item.gridH;
    if (rotation % 2 != 0) {
      gw = item.gridH;
      gh = item.gridW;
    }
    final bool isFlipped = rotation == 1;
    final double vScale = isFlipped ? (item.flippedVisualScale ?? item.visualScale) : item.visualScale;
    final Offset vOffset = isFlipped ? (item.flippedVisualOffset ?? item.visualOffset) : item.visualOffset;
    final double vRotX = isFlipped ? (item.flippedVisualRotationX ?? item.visualRotationX) : item.visualRotationX;
    final double vRotY = isFlipped ? (item.flippedVisualRotationY ?? item.visualRotationY) : item.visualRotationY;
    final double vRotZ = isFlipped ? (item.flippedVisualRotationZ ?? item.visualRotationZ) : item.visualRotationZ;
    final Offset vPivot = isFlipped ? (item.flippedVisualPivot ?? item.visualPivot) : item.visualPivot;
    
    const int faceIndex = 0;
    final image = SpritePainter.getImage(item.imagePath);
    if (image == null) return;

    final p0 = converter.getScreenPoint(r.toDouble(), c.toDouble());
    final p1 = converter.getScreenPoint((r + gw).toDouble(), c.toDouble());
    final p2 = converter.getScreenPoint((r + gw).toDouble(), (c + gh).toDouble());
    final p3 = converter.getScreenPoint(r.toDouble(), (c + gh).toDouble());

    if (item.isFloor) {
      final src = Rect.fromLTWH(
        (item.spriteRect.left + faceIndex * item.spriteRect.width) * image.width,
        item.spriteRect.top * image.height,
        item.spriteRect.width * image.width,
        item.spriteRect.height * image.height,
      );
      final clipPath = Path()
        ..moveTo(p0.dx, p0.dy)
        ..lineTo(p1.dx, p1.dy)
        ..lineTo(p2.dx, p2.dy)
        ..lineTo(p3.dx, p3.dy)
        ..close();
      final double minX = [p0.dx, p1.dx, p2.dx, p3.dx].reduce(math.min);
      final double maxX = [p0.dx, p1.dx, p2.dx, p3.dx].reduce(math.max);
      final double minY = [p0.dy, p1.dy, p2.dy, p3.dy].reduce(math.min);
      final double maxY = [p0.dy, p1.dy, p2.dy, p3.dy].reduce(math.max);
      final dst = Rect.fromLTRB(minX, minY, maxX, maxY);
      canvas.save();
      canvas.clipPath(clipPath);
      if (item.visualRotationZ != 0 || currentBounceScale != 1.0) {
        final center = dst.center;
        canvas.translate(center.dx, center.dy);
        if (item.visualRotationZ != 0) canvas.rotate(item.visualRotationZ * math.pi / 180);
        if (currentBounceScale != 1.0) canvas.scale(currentBounceScale, currentBounceScale);
        canvas.translate(-center.dx, -center.dy);
      }
      canvas.drawImageRect(image, src, dst, Paint()..color = Colors.white.withOpacity(opacity)..filterQuality = FilterQuality.medium);
      canvas.restore();
    } else if (item.isWall) {
      final double s = converter.getTaperScale(r.toDouble(), c.toDouble());
      final bool isLeftWall = rotation % 2 == 0;
      final double itemW = (item.gridW * tw / 2) * s * vScale;
      final double itemH = itemW * (item.intrinsicHeight / item.intrinsicWidth);
      final double midR = isLeftWall ? r + item.gridW / 2.0 : r.toDouble();
      final double midC = isLeftWall ? c.toDouble() : c + item.gridW / 2.0;
      final Offset basePoint = converter.getScreenPoint(midR, midC, z);

      canvas.save();
      const double wallBasePadding = 33.0;
      canvas.translate(basePoint.dx + vOffset.dx, basePoint.dy + wallBasePadding + vOffset.dy);
      if (isFlipped) canvas.scale(-1, 1);
      if (vRotZ != 0) canvas.rotate(vRotZ * math.pi / 180);
      if (currentBounceScale != 1.0) canvas.scale(currentBounceScale, currentBounceScale);

      final dst = Rect.fromLTRB(-itemW / 2, -itemH, itemW / 2, 0);
      final src = Rect.fromLTWH(
        (item.spriteRect.left + faceIndex * item.spriteRect.width) * image.width,
        item.spriteRect.top * image.height,
        item.spriteRect.width * image.width,
        item.spriteRect.height * image.height,
      );

      canvas.drawImageRect(image, src, dst, Paint()
          ..color = (isValid ? Colors.white : Colors.redAccent).withOpacity(opacity)
          ..filterQuality = FilterQuality.medium
          ..colorFilter = isValid ? null : const ColorFilter.mode(Colors.red, BlendMode.modulate));
      canvas.restore();
    } else {
      final double baseS = converter.getTaperScale(r + gw / 2.0, c + gh / 2.0);
      final double itemW = tw * (gw + gh) * baseS * 0.5 * vScale;
      final double itemH = itemW * (item.intrinsicHeight / item.intrinsicWidth);
      final basePoint = converter.getScreenPoint(r + gw / 2.0, c + gh / 2.0);
      canvas.save();
      
      double ty = basePoint.dy + (itemW / 4.0) - (itemH / 2.0);
      if (item.subCategory == '软装' || item.subCategory == '地毯') {
        ty = basePoint.dy;
      }
      
      canvas.translate(basePoint.dx + vOffset.dx, ty + vOffset.dy);
      if (isFlipped) canvas.scale(-1, 1);
      final dst = Rect.fromCenter(center: Offset.zero, width: itemW, height: itemH);
      if (vRotX != 0 || vRotY != 0 || vRotZ != 0 || currentBounceScale != 1.0) {
        final matrix = Matrix4.identity()..translate(vPivot.dx, vPivot.dy);
        if (currentBounceScale != 1.0) {
          matrix.translate(0.0, itemH / 2.0);
          matrix.scale(currentBounceScale, currentBounceScale, 1.0);
          matrix.translate(0.0, -itemH / 2.0);
        }
        matrix..rotateX(vRotX * math.pi / 180)
              ..rotateY(vRotY * math.pi / 180)
              ..rotateZ(vRotZ * math.pi / 180)
              ..translate(-vPivot.dx, -vPivot.dy);
        canvas.transform(matrix.storage);
      }
      final src = Rect.fromLTWH(
        (item.spriteRect.left + faceIndex * item.spriteRect.width) * image.width,
        item.spriteRect.top * image.height,
        item.spriteRect.width * image.width,
        item.spriteRect.height * image.height,
      );
      canvas.drawImageRect(image, src, dst, Paint()
          ..color = (isValid ? Colors.white : Colors.redAccent).withOpacity(opacity)
          ..filterQuality = FilterQuality.low
          ..colorFilter = isValid ? null : const ColorFilter.mode(Colors.red, BlendMode.modulate));
      canvas.restore();
    }
  }

  void _drawSelectionCell(Canvas canvas, (int, int) cell, IsometricCoordinateConverter converter, double tw, double th) {
    final p0 = converter.getScreenPoint(cell.$1.toDouble(), cell.$2.toDouble());
    final p1 = converter.getScreenPoint((cell.$1 + 1).toDouble(), cell.$2.toDouble());
    final p2 = converter.getScreenPoint((cell.$1 + 1).toDouble(), (cell.$2 + 1).toDouble());
    final p3 = converter.getScreenPoint(cell.$1.toDouble(), (cell.$2 + 1).toDouble());
    final path = Path()..moveTo(p0.dx, p0.dy)..lineTo(p1.dx, p1.dy)..lineTo(p2.dx, p2.dy)..lineTo(p3.dx, p3.dy)..close();
    canvas.drawPath(path, Paint()..color = Colors.blue.withOpacity(0.3)..style = PaintingStyle.fill);
    canvas.drawPath(path, Paint()..color = Colors.blueAccent..style = PaintingStyle.stroke..strokeWidth = 2.0);
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
        oldDelegate.bounceScale != bounceScale;
  }
}
