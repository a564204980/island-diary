import 'package:flutter/material.dart';
import '../pages/decoration_page_constants.dart';
import './isometric_coordinate_utils.dart';

/// 墙面花纹与装饰渲染器
class WallPatternPainter {
  static void paint({
    required Canvas canvas,
    required IsometricCoordinateConverter converter,
    required WallPattern pattern,
    required bool isLeft,
    required int rows,
    required int cols,
    required Color baseColor,
  }) {
    switch (pattern) {
      case WallPattern.none:
        break;
      case WallPattern.stripes:
        _drawWallStripes(
          canvas: canvas,
          converter: converter,
          isLeft: isLeft,
          rows: rows,
          cols: cols,
          baseColor: baseColor,
        );
        // 为普通条纹增加一个简约的白木踢脚线
        _drawSkirtingBoard(
          canvas: canvas,
          converter: converter,
          isLeft: isLeft,
          rows: rows,
          cols: cols,
          bottomColor: const Color(0xFFF3E9CA),
          shadowColor: const Color(0xFFCDBAAA),
        );
        break;
      case WallPattern.dualColor:
        // 红调双色：红色主体 + 深胡桃木色底边
        _drawSolidColor(
          canvas: canvas,
          converter: converter,
          isLeft: isLeft,
          rows: rows,
          cols: cols,
          color: const Color(0xFFBC5860),
        );
        _drawSkirtingBoard(
          canvas: canvas,
          converter: converter,
          isLeft: isLeft,
          rows: rows,
          cols: cols,
          bottomColor: const Color(0xFF5D4037),
        );
        break;
      case WallPattern.lavenderStripes:
        // 薰衣草条纹：紫色/米色条纹 + 暖灰色底边
        _drawWallStripes(
          canvas: canvas,
          converter: converter,
          isLeft: isLeft,
          rows: rows,
          cols: cols,
          baseColor: const Color(0xFFD5CEDD),
          stripeColor: const Color(0xFFFFF6E7),
        );
        _drawSkirtingBoard(
          canvas: canvas,
          converter: converter,
          isLeft: isLeft,
          rows: rows,
          cols: cols,
          bottomColor: const Color(0xFFF3E9CA),
          shadowColor: const Color(0xFFCDBAAA),
        );
        break;
    }
  }

  /// 绘制纯色覆盖（用于特殊模式下覆盖基础墙色）
  static void _drawSolidColor({
    required Canvas canvas,
    required IsometricCoordinateConverter converter,
    required bool isLeft,
    required int rows,
    required int cols,
    required Color color,
  }) {
    final path = isLeft
        ? (Path()
          ..addPolygon([
            converter.getScreenPoint(0, 0, 0),
            converter.getScreenPoint(rows.toDouble(), 0, 0),
            converter.getScreenPoint(rows.toDouble(), 0, kWallGridHeight.toDouble()),
            converter.getScreenPoint(0, 0, kWallGridHeight.toDouble()),
          ], true))
        : (Path()
          ..addPolygon([
            converter.getScreenPoint(0, 0, 0),
            converter.getScreenPoint(0, cols.toDouble(), 0),
            converter.getScreenPoint(0, cols.toDouble(), kWallGridHeight.toDouble()),
            converter.getScreenPoint(0, 0, kWallGridHeight.toDouble()),
          ], true));
    canvas.drawPath(path, Paint()..color = color..style = PaintingStyle.fill);
  }

  /// 绘制条纹
  static void _drawWallStripes({
    required Canvas canvas,
    required IsometricCoordinateConverter converter,
    required bool isLeft,
    required int rows,
    required int cols,
    required Color baseColor,
    Color? stripeColor,
  }) {
    final Color finalStripeColor;
    if (stripeColor != null) {
      finalStripeColor = stripeColor;
    } else {
      final hsl = HSLColor.fromColor(baseColor);
      finalStripeColor = hsl
          .withLightness((hsl.lightness - 0.1).clamp(0.0, 1.0))
          .toColor();
    }

    final count = isLeft ? rows : cols;

    for (int i = 0; i < count; i++) {
      if (i % 2 == 1) {
        final path = Path();
        if (isLeft) {
          path.addPolygon([
            converter.getScreenPoint(i.toDouble(), 0, 0),
            converter.getScreenPoint(i + 1.0, 0, 0),
            converter.getScreenPoint(i + 1.0, 0, kWallGridHeight.toDouble()),
            converter.getScreenPoint(i.toDouble(), 0, kWallGridHeight.toDouble()),
          ], true);
        } else {
          path.addPolygon([
            converter.getScreenPoint(0, i.toDouble(), 0),
            converter.getScreenPoint(0, i + 1.0, 0),
            converter.getScreenPoint(0, i + 1.0, kWallGridHeight.toDouble()),
            converter.getScreenPoint(0, i.toDouble(), kWallGridHeight.toDouble()),
          ], true);
        }
        canvas.drawPath(
          path,
          Paint()
            ..color = finalStripeColor
            ..style = PaintingStyle.fill,
        );
      }
    }
  }

  /// 绘制踢脚线/底部装饰边
  static void _drawSkirtingBoard({
    required Canvas canvas,
    required IsometricCoordinateConverter converter,
    required bool isLeft,
    required int rows,
    required int cols,
    required Color bottomColor,
    Color? shadowColor,
    double height = 1.2, // 稍微加高一点，更有墙面装饰感
  }) {
    // 动态计算线条颜色，或者使用传入的颜色
    final Color finalShadowColor;
    if (shadowColor != null) {
      finalShadowColor = shadowColor;
    } else {
      final hsl = HSLColor.fromColor(bottomColor);
      finalShadowColor = hsl.withLightness((hsl.lightness - 0.15).clamp(0, 1)).toColor();
    }
    
    final hsl = HSLColor.fromColor(bottomColor);
    final highlightColor = hsl.withLightness((hsl.lightness + 0.05).clamp(0, 1)).toColor();

    final bottomPath = Path();
    if (isLeft) {
      bottomPath.addPolygon([
        converter.getScreenPoint(0, 0, 0),
        converter.getScreenPoint(rows.toDouble(), 0, 0),
        converter.getScreenPoint(rows.toDouble(), 0, height),
        converter.getScreenPoint(0, 0, height),
      ], true);
    } else {
      bottomPath.addPolygon([
        converter.getScreenPoint(0, 0, 0),
        converter.getScreenPoint(0, cols.toDouble(), 0),
        converter.getScreenPoint(0, cols.toDouble(), height),
        converter.getScreenPoint(0, 0, height),
      ], true);
    }
    canvas.drawPath(
      bottomPath,
      Paint()
        ..color = bottomColor
        ..style = PaintingStyle.fill,
    );

    // 绘制顶部的阴影线（分界线）
    final shadowPaint = Paint()
      ..color = finalShadowColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.8;

    // 绘制一个极细的高光线，增加立体感
    final highlightPaint = Paint()
      ..color = highlightColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.5;

    if (isLeft) {
      final start = converter.getScreenPoint(0, 0, height);
      final end = converter.getScreenPoint(rows.toDouble(), 0, height);
      canvas.drawLine(start, end, shadowPaint);
      canvas.drawLine(
        Offset(start.dx, start.dy + 0.5), 
        Offset(end.dx, end.dy + 0.5), 
        highlightPaint
      );
    } else {
      final start = converter.getScreenPoint(0, 0, height);
      final end = converter.getScreenPoint(0, cols.toDouble(), height);
      canvas.drawLine(start, end, shadowPaint);
      canvas.drawLine(
        Offset(start.dx, start.dy + 0.5), 
        Offset(end.dx, end.dy + 0.5), 
        highlightPaint
      );
    }
  }
}
