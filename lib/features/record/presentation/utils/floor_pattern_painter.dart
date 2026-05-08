import 'package:flutter/material.dart';
import '../pages/decoration_page_constants.dart';
import './isometric_coordinate_utils.dart';

/// 地板花纹渲染器
class FloorPatternPainter {
  static void paint({
    required Canvas canvas,
    required IsometricCoordinateConverter converter,
    required FloorPattern pattern,
    required int rows,
    required int cols,
    required Color baseColor,
  }) {
    if (pattern == FloorPattern.none) return;

    // 1. 裁剪画布，确保纹理只在地板区域内绘制
    final floorPath = Path()
      ..addPolygon([
        converter.getScreenPoint(0, 0, 0),
        converter.getScreenPoint(rows.toDouble(), 0, 0),
        converter.getScreenPoint(rows.toDouble(), cols.toDouble(), 0),
        converter.getScreenPoint(0, cols.toDouble(), 0),
      ], true);
    
    canvas.save();
    canvas.clipPath(floorPath);

    switch (pattern) {
      case FloorPattern.herringbone:
        _drawHerringbone(
          canvas: canvas,
          converter: converter,
          rows: rows,
          cols: cols,
          baseColor: baseColor,
        );
        break;
      default:
        break;
    }

    canvas.restore();
  }

  /// 绘制人字纹（Herringbone / 鱼骨纹）
  /// 采用“填充遮盖法”：通过底色填充隐藏重叠的内部线段，只保留咬合轮廓
  static void _drawHerringbone({
    required Canvas canvas,
    required IsometricCoordinateConverter converter,
    required int rows,
    required int cols,
    required Color baseColor,
  }) {
    final hsl = HSLColor.fromColor(baseColor);
    final lineColor = hsl
        .withLightness((hsl.lightness - 0.1).clamp(0.0, 1.0))
        .toColor();

    final paint = Paint()
      ..color = lineColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.5
      ..strokeCap = StrokeCap.round;

    // 长度 L=4，对应图 2 的比例
    const int L = 4;
    
    // 算法逻辑：
    // 交替铺设横向和纵向木板。
    // 每一列根据 (j ~/ 2) 产生位移，形成斜向咬合。
    // 重要：必须按顺序绘制，并使用 _drawPlankInternal 进行填充，以遮盖重叠线段。
    
    for (int j = -cols - L * 2; j < cols + L * 2; j++) {
      final bool isHorizontal = j % 2 == 0;
      final int shift = -(j ~/ 2); 
      
      for (int i = -rows - L * 4; i < rows + L * 4; i += L) {
        if (isHorizontal) {
          _drawPlankInternal(canvas, converter, (i + shift).toDouble(), j.toDouble(), L.toDouble(), 1.0, baseColor, lineColor, paint);
        } else {
          // 纵向木板
          _drawPlankInternal(canvas, converter, (i + shift + L - 1).toDouble(), j.toDouble(), 1.0, L.toDouble(), baseColor, lineColor, paint);
        }
      }
    }
  }

  /// 内部绘制方法：包含底色填充以遮盖重叠线条
  static void _drawPlankInternal(
    Canvas canvas,
    IsometricCoordinateConverter converter,
    double r,
    double c,
    double wr,
    double wc,
    Color baseColor,
    Color lineColor,
    Paint strokePaint,
  ) {
    final p1 = converter.getScreenPoint(r, c, 0);
    final p2 = converter.getScreenPoint(r + wr, c, 0);
    final p3 = converter.getScreenPoint(r + wr, c + wc, 0);
    final p4 = converter.getScreenPoint(r, c + wc, 0);

    final path = Path()..addPolygon([p1, p2, p3, p4], true);
    
    // 1. 先用底色填充（遮掉被压在下面的线）
    canvas.drawPath(path, Paint()..color = baseColor..style = PaintingStyle.fill);
    
    // 2. 再绘制边框
    canvas.drawPath(path, strokePaint);
  }
}
