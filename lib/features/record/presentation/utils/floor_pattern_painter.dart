import 'dart:math' as math;
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
      case FloorPattern.tripleHerringbone:
        _drawTripleHerringbone(
          canvas: canvas,
          converter: converter,
          rows: rows,
          cols: cols,
          baseColor: baseColor,
        );
        break;
      case FloorPattern.plaid:
        _drawPlaid(
          canvas: canvas,
          converter: converter,
          rows: rows,
          cols: cols,
          baseColor: baseColor,
        );
        break;
      case FloorPattern.randomWood:
        _drawRandomWood(
          canvas: canvas,
          converter: converter,
          rows: rows,
          cols: cols,
          baseColor: baseColor,
        );
        break;
      case FloorPattern.harlequin:
        _drawHarlequin(canvas, converter, rows, cols);
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

  /// 绘制三重人字拼（Triple Herringbone）
  static void _drawTripleHerringbone({
    required Canvas canvas,
    required IsometricCoordinateConverter converter,
    required int rows,
    required int cols,
    required Color baseColor,
  }) {
    final hsl = HSLColor.fromColor(baseColor);
    // 增加线条对比度，模仿图像中的深色勾线
    final lineColor = hsl
        .withLightness((hsl.lightness - 0.2).clamp(0.0, 1.0))
        .toColor();

    final paint = Paint()
      ..color = lineColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.6
      ..strokeCap = StrokeCap.round;

    // 单块木板长度 L=6，宽度 W=1
    // 一组 3 块，总宽度为 3
    const int L = 6;
    const int W = 3;

    for (int j = -cols - L * 2; j < cols + L * 2; j += W) {
      final bool isHorizontal = (j ~/ W) % 2 == 0;
      final int shift = -((j ~/ W) ~/ 2) * W;

      for (int i = -rows - L * 4; i < rows + L * 4; i += L) {
        if (isHorizontal) {
          // 绘制横向三连板
          _drawPlankInternal(canvas, converter, (i + shift).toDouble(), j.toDouble(), L.toDouble(), 1.0, baseColor, lineColor, paint);
          _drawPlankInternal(canvas, converter, (i + shift).toDouble(), (j + 1).toDouble(), L.toDouble(), 1.0, baseColor, lineColor, paint);
          _drawPlankInternal(canvas, converter, (i + shift).toDouble(), (j + 2).toDouble(), L.toDouble(), 1.0, baseColor, lineColor, paint);
        } else {
          // 绘制纵向三连板
          final double baseR = (i + shift + L - W).toDouble();
          _drawPlankInternal(canvas, converter, baseR, j.toDouble(), 1.0, L.toDouble(), baseColor, lineColor, paint);
          _drawPlankInternal(canvas, converter, baseR + 1, j.toDouble(), 1.0, L.toDouble(), baseColor, lineColor, paint);
          _drawPlankInternal(canvas, converter, baseR + 2, j.toDouble(), 1.0, L.toDouble(), baseColor, lineColor, paint);
        }
      }
    }
  }

  /// 绘制格纹地板 (Plaid / Gingham)
  static void _drawPlaid({
    required Canvas canvas,
    required IsometricCoordinateConverter converter,
    required int rows,
    required int cols,
    required Color baseColor,
  }) {
    final paint = Paint()..style = PaintingStyle.fill;
    
    // 用户指定的精确颜色
    final lightBlue = const Color(0xFFC0E0F0);
    // 交叉点深蓝色块颜色 (基于用户蓝色进行加深，增加层次感)
    final darkBlue = const Color(0xFFA8C8D8).withValues(alpha: 0.6);

    const int step = 2; // 适度增大方格尺寸，每 2x2 为一个色块

    // 1. 绘制基础棋盘格 (Step x Step 网格)
    for (int i = 0; i < rows; i += step) {
      for (int j = 0; j < cols; j += step) {
        final p1 = converter.getScreenPoint(i.toDouble(), j.toDouble());
        final p2 = converter.getScreenPoint((i + step).toDouble(), j.toDouble());
        final p3 = converter.getScreenPoint((i + step).toDouble(), (j + step).toDouble());
        final p4 = converter.getScreenPoint(i.toDouble(), (j + step).toDouble());
        
        final path = Path()..addPolygon([p1, p2, p3, p4], true);
        
        // 间隔着色 (强制使用白色和浅蓝色，不依赖 baseColor)
        if (((i / step).floor() + (j / step).floor()) % 2 == 0) {
          paint.color = Colors.white; // 强制白色
        } else {
          paint.color = lightBlue; // 浅蓝色
        }
        canvas.drawPath(path, paint);
      }
    }

    // 2. 绘制四个色块交汇处的深色小方块
    for (int i = 0; i <= rows; i += step) {
      for (int j = 0; j <= cols; j += step) {
        // 小方块半径 (适度增大到 0.4 原始网格单位)
        const double r = 0.4;
        final cp1 = converter.getScreenPoint(i - r, j - r);
        final cp2 = converter.getScreenPoint(i + r, j - r);
        final cp3 = converter.getScreenPoint(i + r, j + r);
        final cp4 = converter.getScreenPoint(i - r, j + r);

        final cPath = Path()..addPolygon([cp1, cp2, cp3, cp4], true);
        paint.color = darkBlue;
        canvas.drawPath(cPath, paint);
      }
    }
  }

  /// 绘制随机木质地板（Random Wood Plank）
  static void _drawRandomWood({
    required Canvas canvas,
    required IsometricCoordinateConverter converter,
    required int rows,
    required int cols,
    required Color baseColor,
  }) {
    // 1. 定义颜色池（提取自用户提供的图片）
    final woodColors = [
      const Color(0xFFA39074), // 灰褐色
      const Color(0xFFB6A68A), // 浅木色
      const Color(0xFF8E8B75), // 灰绿色调
      const Color(0xFFD2C4AE), // 米黄色
      const Color(0xFFC0B199), // 浅褐色
    ];

    final hsl = HSLColor.fromColor(baseColor);
    final lineColor = hsl.withLightness((hsl.lightness - 0.15).clamp(0.0, 1.0)).toColor();

    final paint = Paint()
      ..color = lineColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.5
      ..strokeCap = StrokeCap.round;

    // 使用固定种子，确保渲染结果稳定
    final random = math.Random(42);

    const double minL = 3.0; // 木板最小长度
    const double maxL = 7.0; // 木板最大长度
    const int step = 1;      // 每行宽度

    // 遍历每一行 (j 轴)
    for (int j = -cols; j < cols + 2; j += step) {
      double r = -rows.toDouble() - 10; // 从画面外开始
      
      // 每一行的起始偏移随机化，形成错缝效果
      r += random.nextDouble() * -5;

      while (r < rows + 10) {
        final double plankL = minL + random.nextDouble() * (maxL - minL);
        final Color plankColor = woodColors[random.nextInt(woodColors.length)];

        // 绘制木板（在 r-j 平面上）
        _drawPlankInternal(
          canvas,
          converter,
          r,
          j.toDouble(),
          plankL,
          step.toDouble(),
          plankColor,
          lineColor,
          paint,
        );

        r += plankL;
      }
    }
  }

  /// 绘制马卡龙菱格地板 (Harlequin/Diamond Pattern)
  static void _drawHarlequin(
    Canvas canvas,
    IsometricCoordinateConverter converter,
    int rows,
    int cols,
  ) {
    final palette = [
      const Color(0xFFF4EBEB), // 极淡粉
      const Color(0xFFE8D7D7), //  dusty rose
      const Color(0xFFF2F0E6), // 奶油白
      const Color(0xFFE2DCE6), // 淡紫灰
    ];

    for (int i = 0; i < rows; i++) {
      for (int j = 0; j < cols; j++) {
        // 使用 (i + j) 逻辑来交错颜色
        final colorIndex = (i + j) % palette.length;
        final color = palette[colorIndex];

        final path = Path();
        path.addPolygon([
          converter.getScreenPoint(i.toDouble(), j.toDouble(), 0),
          converter.getScreenPoint((i + 1).toDouble(), j.toDouble(), 0),
          converter.getScreenPoint((i + 1).toDouble(), (j + 1).toDouble(), 0),
          converter.getScreenPoint(i.toDouble(), (j + 1).toDouble(), 0),
        ], true);

        canvas.drawPath(path, Paint()..color = color..style = PaintingStyle.fill);
        
        // 绘制极细的分割线，增加精致感
        canvas.drawPath(
          path, 
          Paint()
            ..color = Colors.white.withOpacity(0.3)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 0.5
        );
      }
    }
  }
}
