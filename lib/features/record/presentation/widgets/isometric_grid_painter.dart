import 'package:flutter/material.dart';
import 'dart:math' as math;
import 'dart:ui' as ui;
import '../../domain/models/furniture_item.dart';
import '../../domain/models/placed_furniture.dart';
import '../pages/decoration_page_constants.dart';
import 'furniture_sprite.dart';

class IsometricGridPainter extends CustomPainter {
  final int rows;
  final int cols;
  final double fullWidth;
  final double fullHeight;
  final List<PlacedFurniture> placedItems;
  final (FurnitureItem, (int, int)?, int, bool)? ghostItem; // (item, cell, rotation, isValid)
  final (int, int)? selectedCell;
  final PlacedFurniture? selectedFurniture;
  final double centerYFactor;
  final bool isCapturing;
  final bool showGrid; // 新增：控制网格显示

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
    this.showGrid = true, // 默认显示
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFFFF0000)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0;

    final double centerX = fullWidth / 2;
    final double centerY = fullHeight * centerYFactor;

    // 旋转整体网格
    canvas.save();
    canvas.translate(centerX, centerY);
    canvas.rotate(kGridRotationDegree * math.pi / 180);
    canvas.translate(-centerX, -centerY);

    // 单个菱形格子的尺寸 (2:1 比例)
    final double tw = fullWidth / 22;
    final double th = tw / 2;

    // 如果正在截图或用户手动关闭网格，跳过网格线和序号的绘制
    if (showGrid && !isCapturing) {
      // 绘制网格线
      for (int j = 0; j <= cols; j++) {
        for (int i = 0; i < rows; i++) {
          if (isCellExcluded(i, j)) continue;
          final start = _getPoint(i.toDouble(), j.toDouble(), centerX, centerY, tw, th);
          final end = _getPoint((i + 1).toDouble(), j.toDouble(), centerX, centerY, tw, th);
          canvas.drawLine(start, end, paint);
        }
      }
      for (int i = 0; i <= rows; i++) {
        for (int j = 0; j < cols; j++) {
          if (isCellExcluded(i, j)) continue;
          final start = _getPoint(i.toDouble(), j.toDouble(), centerX, centerY, tw, th);
          final end = _getPoint(i.toDouble(), (j + 1).toDouble(), centerX, centerY, tw, th);
          canvas.drawLine(start, end, paint);
        }
      }

      // 绘制序号
      final textStyle = const TextStyle(
        color: Colors.white,
        fontSize: 8,
        fontWeight: FontWeight.bold,
      );
      for (int i = 0; i < rows; i++) {
        for (int j = 0; j < cols; j++) {
          if (isCellExcluded(i, j)) continue;
          final pt = _getPoint(i + 0.5, j + 0.5, centerX, centerY, tw, th);
          final tp = TextPainter(
            text: TextSpan(text: '$i-$j', style: textStyle),
            textDirection: TextDirection.ltr,
          )..layout();
          tp.paint(canvas, Offset(pt.dx - tp.width / 2, pt.dy - tp.height / 2));
        }
      }
    }

    // --- 分层渲染：将地板与其他物体分离 ---
    final floors = placedItems.where((pf) => pf.item.category == '地板').toList();
    final others = placedItems.where((pf) => pf.item.category != '地板').toList();

    // 1. 绘制地板层 (按坐标顺序绘制即可，地板通常不重叠)
    for (final pf in floors) {
      if (pf == selectedFurniture) {
        _drawSelectionFootprint(canvas, pf, centerX, centerY, tw, th);
      }
      _drawFurniture(canvas, pf.item, pf.r, pf.c, centerX, centerY, tw, th, 1.0, pf.rotation);
    }

    // 2. 绘制其他物体层 (家具、墙壁、装饰) - 需要深度排序
    final sortedOthers = List<PlacedFurniture>.from(others)
      ..sort((a, b) {
        int gwA = a.item.gridW;
        int ghA = a.item.gridH;
        if (a.rotation % 2 != 0) {
          gwA = a.item.gridH;
          ghA = a.item.gridW;
        }
        final depthA = a.r + gwA + a.c + ghA;

        int gwB = b.item.gridW;
        int ghB = b.item.gridH;
        if (b.rotation % 2 != 0) {
          gwB = b.item.gridH;
          ghB = b.item.gridW;
        }
        final depthB = b.r + gwB + b.c + ghB;

        return depthA.compareTo(depthB);
      });

    for (final pf in sortedOthers) {
      if (pf == selectedFurniture) {
        _drawSelectionFootprint(canvas, pf, centerX, centerY, tw, th);
      }
      _drawFurniture(canvas, pf.item, pf.r, pf.c, centerX, centerY, tw, th, 1.0, pf.rotation);
    }

    // --- 绘制拖拽预览 (Ghost) ---
    if (ghostItem != null && ghostItem!.$2 != null) {
      _drawFurniture(
        canvas,
        ghostItem!.$1,
        ghostItem!.$2!.$1,
        ghostItem!.$2!.$2,
        centerX,
        centerY,
        tw,
        th,
        0.5,
        ghostItem!.$3,
        ghostItem!.$4,
      );
    }

    canvas.restore();
  }

  void _drawSelectionFootprint(Canvas canvas, PlacedFurniture pf, double cx, double cy, double tw, double th) {
    int gw = pf.item.gridW;
    int gh = pf.item.gridH;
    if (pf.rotation % 2 != 0) {
      gw = pf.item.gridH;
      gh = pf.item.gridW;
    }

    final path = Path()
      ..moveTo(_getPoint(pf.r.toDouble(), pf.c.toDouble(), cx, cy, tw, th).dx, _getPoint(pf.r.toDouble(), pf.c.toDouble(), cx, cy, tw, th).dy)
      ..lineTo(_getPoint((pf.r + gw).toDouble(), pf.c.toDouble(), cx, cy, tw, th).dx, _getPoint((pf.r + gw).toDouble(), pf.c.toDouble(), cx, cy, tw, th).dy)
      ..lineTo(_getPoint((pf.r + gw).toDouble(), (pf.c + gh).toDouble(), cx, cy, tw, th).dx, _getPoint((pf.r + gw).toDouble(), (pf.c + gh).toDouble(), cx, cy, tw, th).dy)
      ..lineTo(_getPoint(pf.r.toDouble(), (pf.c + gh).toDouble(), cx, cy, tw, th).dx, _getPoint(pf.r.toDouble(), (pf.c + gh).toDouble(), cx, cy, tw, th).dy)
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

  Offset _getPoint(double i, double j, double cx, double cy, double tw, double th) {
    final double u = i / kGridRows;
    final double v = j / kGridCols;

    final double scale = 1.0 +
        (1 - u) * (1 - v) * kGridTopTaper +
        u * (1 - v) * kGridRightTaper +
        (1 - u) * v * kGridLeftTaper +
        u * v * kGridBottomTaper;

    final double x = (i - j) * (tw / 2) * scale;
    final double y = (i + j - (kGridRows + kGridCols) / 2) * (th / 2) * scale;

    return Offset(cx + x, cy + y);
  }

  void _drawFurniture(
    Canvas canvas,
    FurnitureItem item,
    int r,
    int c,
    double cx,
    double cy,
    double tw,
    double th,
    double opacity, [
    int rotation = 0,
    bool isValid = true,
  ]) {
    int gw = item.gridW;
    int gh = item.gridH;
    if (rotation % 2 != 0) {
      gw = item.gridH;
      gh = item.gridW;
    }

    final bool isBack = (rotation == 1 || rotation == 2);
    final double vScale = isBack ? (item.backVisualScale ?? item.visualScale) : item.visualScale;
    final Offset vOffset = isBack ? (item.backVisualOffset ?? item.visualOffset) : item.visualOffset;
    final double vRotX = isBack ? (item.backVisualRotationX ?? item.visualRotationX) : item.visualRotationX;
    final double vRotY = isBack ? (item.backVisualRotationY ?? item.visualRotationY) : item.visualRotationY;
    final double vRotZ = isBack ? (item.backVisualRotationZ ?? item.visualRotationZ) : item.visualRotationZ;
    final Offset vPivot = isBack ? (item.backVisualPivot ?? item.visualPivot) : item.visualPivot;

    int faceIndex = 0;
    bool isFlipped = false;
    final bool hasMultipleFaces = item.spriteRect.width < 0.9;
    if (hasMultipleFaces) {
      switch (rotation) {
        case 0: faceIndex = 0; isFlipped = false; break;
        case 1: faceIndex = 1; isFlipped = false; break;
        case 2: faceIndex = 1; isFlipped = true; break;
        case 3: faceIndex = 0; isFlipped = true; break;
      }
    } else {
      isFlipped = (rotation == 1 || rotation == 3);
    }

    final p0 = _getPoint(r.toDouble(), c.toDouble(), cx, cy, tw, th);
    final p1 = _getPoint((r + gw).toDouble(), c.toDouble(), cx, cy, tw, th);
    final p2 = _getPoint((r + gw).toDouble(), (c + gh).toDouble(), cx, cy, tw, th);
    final p3 = _getPoint(r.toDouble(), (c + gh).toDouble(), cx, cy, tw, th);

    final paint = Paint()
      ..color = (isValid ? Colors.black : Colors.red).withOpacity(0.6 * opacity)
      ..style = PaintingStyle.fill;

    final path = Path();
    path.moveTo(p0.dx, p0.dy);
    path.lineTo(p1.dx, p1.dy);
    path.lineTo(p2.dx, p2.dy);
    path.lineTo(p3.dx, p3.dy);
    path.close();
    canvas.drawPath(path, paint);

    final image = SpritePainter.getImage(item.imagePath);
    if (image != null) {
      if (item.category == '地板') {
        // --- 地板特化：使用顶点映射（透视形变）填满菱形区域 ---
        final src = Rect.fromLTWH(
          (item.spriteRect.left + faceIndex * item.spriteRect.width) * image.width,
          item.spriteRect.top * image.height,
          item.spriteRect.width * image.width,
          item.spriteRect.height * image.height,
        );

        final vertices = ui.Vertices(
          VertexMode.triangleFan,
          [p0, p1, p2, p3],
          textureCoordinates: [
            Offset(src.left, src.top),
            Offset(src.right, src.top),
            Offset(src.right, src.bottom),
            Offset(src.left, src.bottom),
          ],
        );

        canvas.drawVertices(
          vertices,
          BlendMode.srcOver,
          Paint()
            ..color = Colors.white.withOpacity(opacity)
            ..filterQuality = FilterQuality.medium,
        );
      } else {
        // --- 家具与墙壁：正常的垂直渲染 ---
        final double baseU = (r + gw / 2.0) / rows;
        final double baseV = (c + gh / 2.0) / cols;
        final double baseS = 1.0 +
            (1 - baseU) * (1 - baseV) * kGridTopTaper +
            baseU * (1 - baseV) * kGridRightTaper +
            (1 - baseU) * baseV * kGridLeftTaper +
            baseU * baseV * kGridBottomTaper;

        final double itemW = tw * (gw + gh) * baseS * 0.5 * vScale;
        final double itemH = itemW * (item.intrinsicHeight / item.intrinsicWidth);

        final basePoint = _getPoint(r + gw / 2.0, c + gh / 2.0, cx, cy, tw, th);
        final double verticalOffset = itemW / 4.0;
        
        canvas.save();
        canvas.translate(
          basePoint.dx + vOffset.dx,
          basePoint.dy + verticalOffset - (itemH / 2.0) + vOffset.dy,
        );
        
        if (isFlipped) {
          canvas.scale(-1, 1);
        }

        final dst = Rect.fromCenter(
          center: Offset.zero,
          width: itemW,
          height: itemH,
        );

        if (vRotX != 0 || vRotY != 0 || vRotZ != 0) {
          final matrix = Matrix4.identity()
            ..translate(vPivot.dx, vPivot.dy)
            ..rotateX(vRotX * math.pi / 180)
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

        canvas.drawImageRect(
          image, 
          src, 
          dst, 
          Paint()
            ..color = (isValid ? Colors.white : Colors.redAccent).withOpacity(opacity)
            ..filterQuality = FilterQuality.low
            ..colorFilter = isValid ? null : const ColorFilter.mode(Colors.red, BlendMode.modulate),
        );
        canvas.restore();
      }
    }
  }

  @override
  bool shouldRepaint(covariant IsometricGridPainter oldDelegate) => true;
}
