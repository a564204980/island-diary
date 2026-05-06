import 'package:flutter/material.dart';
import '../utils/isometric_coordinate_utils.dart';
import '../pages/decoration_page_constants.dart';

/// 等轴测场景基础元素渲染器
class IsometricSceneRenderer {
  /// 绘制墙体外壳（基础形状 + 3D 深度效应）
  static void drawWallShell({
    required Canvas canvas,
    required IsometricCoordinateConverter converter,
    required int rows,
    required int cols,
    required Color wallColorLeft,
    required Color wallColorRight,
    required Paint outlinePaint,
  }) {
    // 1. 基础填充路径
    final leftPath = Path()
      ..addPolygon([
        converter.getScreenPoint(0, 0, 0),
        converter.getScreenPoint(rows.toDouble(), 0, 0),
        converter.getScreenPoint(
          rows.toDouble(),
          0,
          kWallGridHeight.toDouble(),
        ),
        converter.getScreenPoint(0, 0, kWallGridHeight.toDouble()),
      ], true);

    final rightPath = Path()
      ..addPolygon([
        converter.getScreenPoint(0, 0, 0),
        converter.getScreenPoint(0, cols.toDouble(), 0),
        converter.getScreenPoint(
          0,
          cols.toDouble(),
          kWallGridHeight.toDouble(),
        ),
        converter.getScreenPoint(0, 0, kWallGridHeight.toDouble()),
      ], true);

    canvas.drawPath(leftPath, Paint()..color = wallColorLeft);
    canvas.drawPath(rightPath, Paint()..color = wallColorRight);

    // 2. 3D 深度效果
    final hslLeft = HSLColor.fromColor(wallColorLeft);
    final hslRight = HSLColor.fromColor(wallColorRight);

    final topPaintLeft = Paint()
      ..color = hslLeft
          .withLightness((hslLeft.lightness + 0.12).clamp(0, 1))
          .toColor();
    final topPaintRight = Paint()
      ..color = hslRight
          .withLightness((hslRight.lightness + 0.12).clamp(0, 1))
          .toColor();

    final sidePaintLeft = Paint()
      ..color = hslLeft
          .withLightness((hslLeft.lightness - 0.08).clamp(0, 1))
          .toColor();
    final sidePaintRight = Paint()
      ..color = hslRight
          .withLightness((hslRight.lightness - 0.08).clamp(0, 1))
          .toColor();

    // 顶部厚度
    _drawPath(canvas, outlinePaint, topPaintLeft, [
      converter.getScreenPoint(0, 0, kWallGridHeight.toDouble()),
      converter.getScreenPoint(rows.toDouble(), 0, kWallGridHeight.toDouble()),
      converter.getScreenPoint(
        rows.toDouble(),
        -kWallThickness,
        kWallGridHeight.toDouble(),
      ),
      converter.getScreenPoint(0, -kWallThickness, kWallGridHeight.toDouble()),
    ]);
    _drawPath(canvas, outlinePaint, topPaintRight, [
      converter.getScreenPoint(0, 0, kWallGridHeight.toDouble()),
      converter.getScreenPoint(0, cols.toDouble(), kWallGridHeight.toDouble()),
      converter.getScreenPoint(
        -kWallThickness,
        cols.toDouble(),
        kWallGridHeight.toDouble(),
      ),
      converter.getScreenPoint(-kWallThickness, 0, kWallGridHeight.toDouble()),
    ]);

    // 远端侧面
    _drawPath(canvas, outlinePaint, sidePaintLeft, [
      converter.getScreenPoint(rows.toDouble(), 0, 0),
      converter.getScreenPoint(rows.toDouble(), -kWallThickness, 0),
      converter.getScreenPoint(
        rows.toDouble(),
        -kWallThickness,
        kWallGridHeight.toDouble(),
      ),
      converter.getScreenPoint(rows.toDouble(), 0, kWallGridHeight.toDouble()),
    ]);
    _drawPath(canvas, outlinePaint, sidePaintRight, [
      converter.getScreenPoint(0, cols.toDouble(), 0),
      converter.getScreenPoint(-kWallThickness, cols.toDouble(), 0),
      converter.getScreenPoint(
        -kWallThickness,
        cols.toDouble(),
        kWallGridHeight.toDouble(),
      ),
      converter.getScreenPoint(0, cols.toDouble(), kWallGridHeight.toDouble()),
    ]);

    // 墙角连接
    _drawPath(canvas, outlinePaint, topPaintLeft, [
      converter.getScreenPoint(0, 0, kWallGridHeight.toDouble()),
      converter.getScreenPoint(-kWallThickness, 0, kWallGridHeight.toDouble()),
      converter.getScreenPoint(
        -kWallThickness,
        -kWallThickness,
        kWallGridHeight.toDouble(),
      ),
      converter.getScreenPoint(0, -kWallThickness, kWallGridHeight.toDouble()),
    ]);
  }

  /// 绘制墙体轮廓（在花纹之后绘制，确保遮盖花纹边缘）
  static void drawWallOutline({
    required Canvas canvas,
    required IsometricCoordinateConverter converter,
    required int rows,
    required int cols,
    required Paint outlinePaint,
  }) {
    // 1. 左右墙体主轮廓
    final leftPath = Path()
      ..addPolygon([
        converter.getScreenPoint(0, 0, 0),
        converter.getScreenPoint(rows.toDouble(), 0, 0),
        converter.getScreenPoint(
          rows.toDouble(),
          0,
          kWallGridHeight.toDouble(),
        ),
        converter.getScreenPoint(0, 0, kWallGridHeight.toDouble()),
      ], true);

    final rightPath = Path()
      ..addPolygon([
        converter.getScreenPoint(0, 0, 0),
        converter.getScreenPoint(0, cols.toDouble(), 0),
        converter.getScreenPoint(
          0,
          cols.toDouble(),
          kWallGridHeight.toDouble(),
        ),
        converter.getScreenPoint(0, 0, kWallGridHeight.toDouble()),
      ], true);

    canvas.drawPath(leftPath, outlinePaint);
    canvas.drawPath(rightPath, outlinePaint);

    // 2. 顶部厚度轮廓
    canvas.drawPath(
      Path()..addPolygon([
        converter.getScreenPoint(0, 0, kWallGridHeight.toDouble()),
        converter.getScreenPoint(
          rows.toDouble(),
          0,
          kWallGridHeight.toDouble(),
        ),
        converter.getScreenPoint(
          rows.toDouble(),
          -kWallThickness,
          kWallGridHeight.toDouble(),
        ),
        converter.getScreenPoint(
          0,
          -kWallThickness,
          kWallGridHeight.toDouble(),
        ),
      ], true),
      outlinePaint,
    );
    canvas.drawPath(
      Path()..addPolygon([
        converter.getScreenPoint(0, 0, kWallGridHeight.toDouble()),
        converter.getScreenPoint(
          0,
          cols.toDouble(),
          kWallGridHeight.toDouble(),
        ),
        converter.getScreenPoint(
          -kWallThickness,
          cols.toDouble(),
          kWallGridHeight.toDouble(),
        ),
        converter.getScreenPoint(
          -kWallThickness,
          0,
          kWallGridHeight.toDouble(),
        ),
      ], true),
      outlinePaint,
    );

    // 3. 远端侧面轮廓
    canvas.drawPath(
      Path()..addPolygon([
        converter.getScreenPoint(rows.toDouble(), 0, 0),
        converter.getScreenPoint(rows.toDouble(), -kWallThickness, 0),
        converter.getScreenPoint(
          rows.toDouble(),
          -kWallThickness,
          kWallGridHeight.toDouble(),
        ),
        converter.getScreenPoint(
          rows.toDouble(),
          0,
          kWallGridHeight.toDouble(),
        ),
      ], true),
      outlinePaint,
    );
    canvas.drawPath(
      Path()..addPolygon([
        converter.getScreenPoint(0, cols.toDouble(), 0),
        converter.getScreenPoint(-kWallThickness, cols.toDouble(), 0),
        converter.getScreenPoint(
          -kWallThickness,
          cols.toDouble(),
          kWallGridHeight.toDouble(),
        ),
        converter.getScreenPoint(
          0,
          cols.toDouble(),
          kWallGridHeight.toDouble(),
        ),
      ], true),
      outlinePaint,
    );

    // 4. 墙角厚度轮廓
    canvas.drawPath(
      Path()..addPolygon([
        converter.getScreenPoint(0, 0, kWallGridHeight.toDouble()),
        converter.getScreenPoint(
          -kWallThickness,
          0,
          kWallGridHeight.toDouble(),
        ),
        converter.getScreenPoint(
          -kWallThickness,
          -kWallThickness,
          kWallGridHeight.toDouble(),
        ),
        converter.getScreenPoint(
          0,
          -kWallThickness,
          kWallGridHeight.toDouble(),
        ),
      ], true),
      outlinePaint,
    );
  }

  /// 绘制地面外壳
  static void drawFloorShell({
    required Canvas canvas,
    required IsometricCoordinateConverter converter,
    required int rows,
    required int cols,
    required Color floorColor,
    required Paint outlinePaint,
  }) {
    final floorPath = Path()
      ..addPolygon([
        converter.getScreenPoint(0, 0, 0),
        converter.getScreenPoint(rows.toDouble(), 0, 0),
        converter.getScreenPoint(rows.toDouble(), cols.toDouble(), 0),
        converter.getScreenPoint(0, cols.toDouble(), 0),
      ], true);

    canvas.drawPath(floorPath, Paint()..color = floorColor);

    final sideColor = const Color(0xFFD2D0C5);
    final sidePaintLeft = Paint()..color = sideColor;
    final sidePaintRight = Paint()
      ..color = HSLColor.fromColor(sideColor).withLightness(0.4).toColor();

    // 绘制 3D 基座侧边
    _drawPath(canvas, outlinePaint, sidePaintLeft, [
      converter.getScreenPoint(rows.toDouble(), -kWallThickness, 0),
      converter.getScreenPoint(rows.toDouble(), cols.toDouble(), 0),
      converter.getScreenPoint(
        rows.toDouble(),
        cols.toDouble(),
        -kWallThickness,
      ),
      converter.getScreenPoint(
        rows.toDouble(),
        -kWallThickness,
        -kWallThickness,
      ),
    ]);
    _drawPath(canvas, outlinePaint, sidePaintRight, [
      converter.getScreenPoint(-kWallThickness, cols.toDouble(), 0),
      converter.getScreenPoint(rows.toDouble(), cols.toDouble(), 0),
      converter.getScreenPoint(
        rows.toDouble(),
        cols.toDouble(),
        -kWallThickness,
      ),
      converter.getScreenPoint(
        -kWallThickness,
        cols.toDouble(),
        -kWallThickness,
      ),
    ]);
  }

  /// 绘制网格线与坐标标签
  static void drawGrid({
    required Canvas canvas,
    required IsometricCoordinateConverter converter,
    required int rows,
    required int cols,
    required bool showLabels,
  }) {
    final gridPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.15)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    // 地面网格
    for (int j = 0; j <= cols; j++) {
      canvas.drawLine(
        converter.getScreenPoint(0, j.toDouble()),
        converter.getScreenPoint(rows.toDouble(), j.toDouble()),
        gridPaint,
      );
    }
    for (int i = 0; i <= rows; i++) {
      canvas.drawLine(
        converter.getScreenPoint(i.toDouble(), 0),
        converter.getScreenPoint(i.toDouble(), cols.toDouble()),
        gridPaint,
      );
    }

    // 墙面网格
    for (int i = 0; i <= rows; i++) {
      canvas.drawLine(
        converter.getScreenPoint(i.toDouble(), 0, 0),
        converter.getScreenPoint(i.toDouble(), 0, kWallGridHeight.toDouble()),
        gridPaint,
      );
    }
    for (int z = 1; z <= kWallGridHeight; z++) {
      canvas.drawLine(
        converter.getScreenPoint(0, 0, z.toDouble()),
        converter.getScreenPoint(rows.toDouble(), 0, z.toDouble()),
        gridPaint,
      );
    }
    for (int j = 0; j <= cols; j++) {
      canvas.drawLine(
        converter.getScreenPoint(0, j.toDouble(), 0),
        converter.getScreenPoint(0, j.toDouble(), kWallGridHeight.toDouble()),
        gridPaint,
      );
    }
    for (int z = 1; z <= kWallGridHeight; z++) {
      canvas.drawLine(
        converter.getScreenPoint(0, 0, z.toDouble()),
        converter.getScreenPoint(0, cols.toDouble(), z.toDouble()),
        gridPaint,
      );
    }

    if (showLabels) {
      _drawLabels(canvas, converter, rows, cols);
    }
  }

  static void _drawLabels(
    Canvas canvas,
    IsometricCoordinateConverter converter,
    int rows,
    int cols,
  ) {
    final style = TextStyle(
      color: Colors.white.withValues(alpha: 0.3),
      fontSize: 6.0,
    );
    for (int i = 0; i < rows; i++) {
      for (int j = 0; j < cols; j++) {
        final pos = converter.getScreenPoint(i + 0.5, j + 0.5);
        _drawText(canvas, '$i,$j', pos, style);
      }
    }
  }

  static void _drawText(
    Canvas canvas,
    String text,
    Offset pos,
    TextStyle style,
  ) {
    final tp = TextPainter(
      text: TextSpan(text: text, style: style),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, pos - Offset(tp.width / 2, tp.height / 2));
  }

  static void _drawPath(
    Canvas canvas,
    Paint stroke,
    Paint fill,
    List<Offset> points,
  ) {
    final path = Path()..addPolygon(points, true);
    canvas.drawPath(path, fill);
    canvas.drawPath(path, stroke);
  }
}
