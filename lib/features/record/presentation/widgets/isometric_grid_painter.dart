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
  final (FurnitureItem, (int, int)?)? ghostItem;
  final (int, int)? selectedCell;
  final PlacedFurniture? selectedFurniture;

  IsometricGridPainter({
    required this.rows,
    required this.cols,
    required this.fullWidth,
    required this.fullHeight,
    this.selectedCell,
    this.placedItems = const [],
    this.ghostItem,
    this.selectedFurniture,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFFFF0000)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0;

    final double centerX = fullWidth / 2;
    final double centerY = fullHeight * kGridCenterYFactor;

    // 旋转整体网格
    canvas.save();
    canvas.translate(centerX, centerY);
    canvas.rotate(kGridRotationDegree * math.pi / 180);
    canvas.translate(-centerX, -centerY);

    // 单个菱形格子的尺寸 (2:1 比例)
    final double tw = fullWidth / 22;
    final double th = tw / 2;

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
  ]) {
    int gw = item.gridW;
    int gh = item.gridH;
    if (rotation % 2 != 0) {
      gw = item.gridH;
      gh = item.gridW;
    }

    final paint = Paint()
      ..color = Colors.blue.withOpacity(0.1 * opacity)
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
      final double u = r / rows;
      final double v = c / cols;
      final double s = 1.0 +
          (1 - u) * (1 - v) * kGridTopTaper +
          u * (1 - v) * kGridRightTaper +
          (1 - u) * v * kGridLeftTaper +
          u * v * kGridBottomTaper;

      final double itemW = tw * gw * s * 0.8;
      final double itemH = itemW * (1072 / 605);

      final basePoint = _getPoint(r + gw / 2.0, c + gh / 2.0, cx, cy, tw, th);
      final double verticalOffset = (gw * tw / 4.0) * s;
      
      canvas.save();
      canvas.translate(basePoint.dx, basePoint.dy + verticalOffset - (itemH / 2.0));
      // 这里的旋转是视觉上的，可能需要根据具体素材调整
      // 如果素材本身就是 2.5D 的，简单的旋转可能不对，但用户要求“旋转”
      // 在等距视图中，典型的旋转是镜像或 90度切换素材
      // 目前没有多向素材，我们先做简单的 scaleX 也可以作为翻转
      if (rotation == 1 || rotation == 3) {
        canvas.scale(-1, 1);
      }

      final dst = Rect.fromCenter(
        center: Offset.zero,
        width: itemW,
        height: itemH,
      );

      final src = Rect.fromLTWH(
        item.spriteRect.left * image.width,
        item.spriteRect.top * image.height,
        item.spriteRect.width * image.width,
        item.spriteRect.height * image.height,
      );

      canvas.drawImageRect(image, src, dst, Paint()..color = Colors.white.withOpacity(opacity));
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant IsometricGridPainter oldDelegate) =>
      oldDelegate.selectedCell != selectedCell ||
      oldDelegate.fullWidth != fullWidth ||
      oldDelegate.fullHeight != fullHeight ||
      oldDelegate.placedItems != placedItems ||
      oldDelegate.selectedFurniture != selectedFurniture ||
      oldDelegate.ghostItem != ghostItem;
}
