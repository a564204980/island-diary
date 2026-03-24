import 'package:flutter/material.dart';
import 'dart:math' as math;
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

    // 如果正在截图，跳过网格线和序号的绘制
    if (!isCapturing) {
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

    // --- 绘制已摆放的家具 (按深度排序：r+c 越大越靠前) ---
    final sortedItems = List<PlacedFurniture>.from(placedItems)
      ..sort((a, b) => (a.r + a.c).compareTo(b.r + b.c));

    for (final pf in sortedItems) {
      _drawFurniture(canvas, pf.item, pf.r, pf.c, centerX, centerY, tw, th, 1.0, pf.rotation);
      
      // 如果是被选中的家具，绘制高亮边框
      if (pf == selectedFurniture) {
        _drawSelectionFootprint(canvas, pf, centerX, centerY, tw, th);
      }
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
        ghostItem!.$3, // 使用传入的旋转角度
        ghostItem!.$4, // 传入合法性
      );
    }

    // --- 绘制选中高亮 (由 _drawSelectionFootprint 在循环中处理) ---

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

    final paint = Paint()
      ..color = (isValid ? Colors.blue : Colors.red).withOpacity(0.1 * opacity)
      ..style = PaintingStyle.fill;

    final path = Path();
    final p0 = _getPoint(r.toDouble(), c.toDouble(), cx, cy, tw, th);
    final p1 = _getPoint((r + gw).toDouble(), c.toDouble(), cx, cy, tw, th);
    final p2 = _getPoint((r + gw).toDouble(), (c + gh).toDouble(), cx, cy, tw, th);
    final p3 = _getPoint(r.toDouble(), (c + gh).toDouble(), cx, cy, tw, th);
    path.moveTo(p0.dx, p0.dy);
    path.lineTo(p1.dx, p1.dy);
    path.lineTo(p2.dx, p2.dy);
    path.lineTo(p3.dx, p3.dy);
    path.close();
    canvas.drawPath(path, paint);

    final image = SpritePainter.getImage(item.imagePath);
    if (image != null) {
      final double u = (r + gw / 2.0) / rows;
      final double v = (c + gh / 2.0) / cols;
      final double s = 1.0 +
          (1 - u) * (1 - v) * kGridTopTaper +
          u * (1 - v) * kGridRightTaper +
          (1 - u) * v * kGridLeftTaper +
          u * v * kGridBottomTaper;

      // 核心修复：根据等距投影几何学，物体的总视觉宽度应与 (gw + gh) 成正比
      // 0.45 是针对 22 分格系统的视觉平衡系数
      final double itemW = tw * (gw + gh) * s * 0.45;
      final double itemH = itemW * (item.intrinsicHeight / item.intrinsicWidth);

      // 根据用户反馈调整的顺时针映射逻辑：
      // 0: 面1 (正面左下 +r)
      // 1: 面2 (背面左上 -c)
      // 2: 面2 翻转 (背面右上 -r)
      // 3: 面1 翻转 (正面右下 +c)
      int faceIndex = 0;
      bool isFlipped = false;
      
      final bool hasMultipleFaces = item.spriteRect.width < 0.9; // 简单判断是否有多个面
      
      if (hasMultipleFaces) {
        switch (rotation) {
          case 0: faceIndex = 0; isFlipped = false; break;
          case 1: faceIndex = 1; isFlipped = false; break;
          case 2: faceIndex = 1; isFlipped = true; break;
          case 3: faceIndex = 0; isFlipped = true; break;
        }
      } else {
        // 单面素材退化逻辑
        isFlipped = (rotation == 1 || rotation == 3);
      }

      final basePoint = _getPoint(r + gw / 2.0, c + gh / 2.0, cx, cy, tw, th);
      // 根据几何学，方块底角距离中心的垂直距离为 (gw + gh) * (th / 4)
      // 这里的 th = tw / 2，所以对应公式为 (gw + gh) * (tw / 8)
      final double verticalOffset = ((gw + gh) * tw / 8.0) * s;
      
      canvas.save();
      canvas.translate(basePoint.dx, basePoint.dy + verticalOffset - (itemH / 2.0));
      
      if (isFlipped) {
        canvas.scale(-1, 1);
      }

      final dst = Rect.fromCenter(
        center: Offset.zero,
        width: itemW,
        height: itemH,
      );

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
          ..colorFilter = isValid ? null : const ColorFilter.mode(Colors.red, BlendMode.modulate),
      );
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant IsometricGridPainter oldDelegate) => true;
}
