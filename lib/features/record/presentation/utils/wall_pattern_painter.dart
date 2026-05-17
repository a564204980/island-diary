import 'dart:math' as math;
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
    if (pattern == WallPattern.none) {
      return;
    }

    // --- 1. 建立墙面裁剪路径，防止花纹溢出到墙外 ---
    final wallPath = isLeft
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

    canvas.save();
    canvas.clipPath(wallPath);

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
      case WallPattern.wainscoting:
        _drawWainscoting(
          canvas: canvas,
          converter: converter,
          isLeft: isLeft,
          rows: rows,
          cols: cols,
          baseColor: baseColor,
        );
        break;
      case WallPattern.clouds:
        _drawClouds(
          canvas: canvas,
          converter: converter,
          isLeft: isLeft,
          rows: rows,
          cols: cols,
          baseColor: baseColor,
        );
        break;
      case WallPattern.gradient:
        _drawGradient(
          canvas: canvas,
          converter: converter,
          isLeft: isLeft,
          rows: rows,
          cols: cols,
          topColor: const Color(0xFFDBF3F4),
          bottomColor: const Color(0xFF77D9D9),
        );
        break;
      case WallPattern.sparkle:
        _drawSparkle(
          canvas: canvas,
          converter: converter,
          isLeft: isLeft,
          rows: rows,
          cols: cols,
          baseColor: const Color(0xFF9181C9),
          lightColor: const Color(0xFFDCCFF2),
        );
        break;
      case WallPattern.meltingDrips:
        _drawMeltingDrips(
          canvas: canvas,
          converter: converter,
          isLeft: isLeft,
          rows: rows,
          cols: cols,
        );
        break;
      case WallPattern.greenHills:
        _drawGreenHills(
          canvas: canvas,
          converter: converter,
          isLeft: isLeft,
          rows: rows,
          cols: cols,
        );
        break;
      case WallPattern.vintageFloral:
        _drawVintageFloral(
          canvas: canvas,
          converter: converter,
          isLeft: isLeft,
          rows: rows,
          cols: cols,
          baseColor: baseColor,
        );
        break;
      case WallPattern.ivySkirting:
        _drawIvySkirting(
          canvas: canvas,
          converter: converter,
          isLeft: isLeft,
          rows: rows,
          cols: cols,
          baseColor: baseColor,
        );
        break;
      case WallPattern.sakura:
        _drawSakura(
          canvas: canvas,
          converter: converter,
          isLeft: isLeft,
          rows: rows,
          cols: cols,
          baseColor: baseColor,
        );
        break;
      case WallPattern.greenWoodPanels:
        _drawGreenWoodPanels(
          canvas: canvas,
          converter: converter,
          isLeft: isLeft,
          rows: rows,
          cols: cols,
          baseColor: baseColor,
        );
        break;
    }

    canvas.restore();
  }

  /// 绘制云端拾光效果
  static void _drawClouds({
    required Canvas canvas,
    required IsometricCoordinateConverter converter,
    required bool isLeft,
    required int rows,
    required int cols,
    required Color baseColor,
  }) {
    final count = isLeft ? rows : cols;

    // 1. 绘制天空底色
    _drawSolidColor(
      canvas: canvas,
      converter: converter,
      isLeft: isLeft,
      rows: rows,
      cols: cols,
      color: baseColor,
    );

    // --- 关键：建立墙面投影矩阵 ---
    // 获取墙面的两个基向量（水平方向和垂直方向）
    final pOrigin = converter.getScreenPoint(0, 0, 0);
    final pHorizontal = isLeft ? converter.getScreenPoint(1, 0, 0) : converter.getScreenPoint(0, 1, 0);
    final pVertical = converter.getScreenPoint(0, 0, 1);

    final vx = Offset(pHorizontal.dx - pOrigin.dx, pHorizontal.dy - pOrigin.dy);
    final vy = Offset(pVertical.dx - pOrigin.dx, pVertical.dy - pOrigin.dy);

    // 2. 绘制装饰虚线 (在中部建立投影)
    final dashPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.7)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;
    
    const double dashH = 5.5;
    const double dashLen = 0.8;
    const double gapLen = 0.4;
    
    for (double i = 0; i < count; i += (dashLen + gapLen)) {
      final p1 = isLeft ? converter.getScreenPoint(i, 0, dashH) : converter.getScreenPoint(0, i, dashH);
      final p2 = isLeft ? converter.getScreenPoint(i + dashLen, 0, dashH) : converter.getScreenPoint(0, i + dashLen, dashH);
      canvas.drawLine(p1, p2, dashPaint);
    }

    // 3. 绘制投影云朵
    final cloudPaint = Paint()..color = Colors.white.withValues(alpha: 0.9)..style = PaintingStyle.fill;
    
    final List<(double, double, double)> cloudConfigs = [
      (2.0, 10.0, 1.2),
      (6.0, 7.5, 1.0),
      (12.0, 11.0, 1.5),
      (18.0, 8.5, 0.9),
      (22.0, 12.0, 1.1),
    ];

    for (var config in cloudConfigs) {
      if (config.$1 >= count) {
        continue;
      }
      
      // 这里的 x, y 是墙面坐标系下的坐标
      final double wallX = config.$1;
      final double wallZ = config.$2;
      final double scale = config.$3;

      _drawSingleCloudProjected(canvas, pOrigin, vx, vy, wallX, wallZ, scale, cloudPaint);
    }
  }

  /// 在墙面投影空间中绘制单个云朵 (横向蓬松排列)
  static void _drawSingleCloudProjected(
    Canvas canvas, 
    Offset origin, 
    Offset vx, 
    Offset vy, 
    double x, 
    double z, 
    double scale, 
    Paint paint
  ) {
    // 将墙面上的局部坐标 (dx, dz) 映射到屏幕投影坐标
    Offset project(double dx, double dz) {
      return Offset(
        origin.dx + (x + dx) * vx.dx + (z + dz) * vy.dx,
        origin.dy + (x + dx) * vx.dy + (z + dz) * vy.dy,
      );
    }

    // 在等轴测平面上绘制一个投影后的圆（即椭圆）
    void drawCircleInSpace(double dx, double dz, double radius) {
      final path = Path();
      for (int i = 0; i <= 32; i++) {
        final angle = i * (2 * math.pi / 32);
        // 修正：在空间内使用 1:1 比例，投影矩阵会自动处理 30 度透视变形
        final p = project(dx + radius * math.cos(angle), dz + radius * math.sin(angle));
        if (i == 0) {
          path.moveTo(p.dx, p.dy);
        } else {
          path.lineTo(p.dx, p.dy);
        }
      }
      canvas.drawPath(path, paint);
    }

    // 绘制云朵组合：通过 5 个圆的横向拉伸排列，营造蓬松感
    drawCircleInSpace(0, 0, 1.2 * scale); // 中心圆
    drawCircleInSpace(-1.1 * scale, -0.1 * scale, 0.8 * scale); // 左侧圆
    drawCircleInSpace(1.1 * scale, -0.1 * scale, 0.8 * scale); // 右侧圆
    drawCircleInSpace(-0.4 * scale, 0.5 * scale, 0.7 * scale); // 左上圆
    drawCircleInSpace(0.4 * scale, 0.5 * scale, 0.7 * scale); // 右上圆
  }


  /// 绘制法式护墙板与波点
  static void _drawWainscoting({
    required Canvas canvas,
    required IsometricCoordinateConverter converter,
    required bool isLeft,
    required int rows,
    required int cols,
    required Color baseColor,
  }) {
    const double wallH = kWallGridHeight + 0.0;
    const double panelH = 5.0; // 护墙板高度
    final count = isLeft ? rows : cols;

    // 1. 绘制上半部分的藕粉色（或传入的 baseColor）
    _drawSolidColor(
      canvas: canvas,
      converter: converter,
      isLeft: isLeft,
      rows: rows,
      cols: cols,
      color: baseColor,
    );

    // 2. 绘制下半部分的护墙板 (米白色)
    final bottomColor = const Color(0xFFFDF9EE);
    final bottomPath = Path();
    if (isLeft) {
      bottomPath.addPolygon([
        converter.getScreenPoint(0, 0, 0),
        converter.getScreenPoint(rows.toDouble(), 0, 0),
        converter.getScreenPoint(rows.toDouble(), 0, panelH),
        converter.getScreenPoint(0, 0, panelH),
      ], true);
    } else {
      bottomPath.addPolygon([
        converter.getScreenPoint(0, 0, 0),
        converter.getScreenPoint(0, cols.toDouble(), 0),
        converter.getScreenPoint(0, cols.toDouble(), panelH),
        converter.getScreenPoint(0, 0, panelH),
      ], true);
    }
    canvas.drawPath(bottomPath, Paint()..color = bottomColor..style = PaintingStyle.fill);

    // 3. 绘制护墙板的垂直线条 (细微的阴影线)
    final linePaint = Paint()
      ..color = const Color(0xFFE5DCC5)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.5;
    
    for (int i = 0; i <= count; i++) {
      final p1 = isLeft ? converter.getScreenPoint(i.toDouble(), 0, 0) : converter.getScreenPoint(0, i.toDouble(), 0);
      final p2 = isLeft ? converter.getScreenPoint(i.toDouble(), 0, panelH) : converter.getScreenPoint(0, i.toDouble(), panelH);
      canvas.drawLine(p1, p2, linePaint);
    }

    // 4. 绘制腰线 (两条细白线)
    final dividerPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.9)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.8;
    
    for (double h in [panelH, panelH + 0.3]) {
      final start = converter.getScreenPoint(0, 0, h);
      final end = isLeft ? converter.getScreenPoint(rows.toDouble(), 0, h) : converter.getScreenPoint(0, cols.toDouble(), h);
      canvas.drawLine(start, end, dividerPaint);
    }

    // 5. 绘制波点 (Polka Dots)
    final dotPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.6)
      ..style = PaintingStyle.fill;
    
    // 使用数学偏移实现交错排列
    const double stepH = 2.5;
    const double stepV = 2.0;
    
    for (double v = panelH + 1.5; v < wallH - 0.5; v += stepV) {
      final bool isShifted = (v ~/ stepV) % 2 == 0;
      for (double h = 0.5; h < count; h += stepH) {
        final double posH = h + (isShifted ? stepH / 2 : 0);
        if (posH >= count) {
          continue;
        }

        final center = isLeft ? converter.getScreenPoint(posH, 0, v) : converter.getScreenPoint(0, posH, v);
        
        // 绘制大小错落的圆点
        final double radius = (posH.toInt() % 3 == 0) ? 2.5 : 1.5;
        canvas.drawCircle(center, radius, dotPaint);
      }
    }
  }
  
  /// 绘制渐变墙面
  static void _drawGradient({
    required Canvas canvas,
    required IsometricCoordinateConverter converter,
    required bool isLeft,
    required int rows,
    required int cols,
    required Color topColor,
    required Color bottomColor,
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

    final Rect bounds = path.getBounds();
    final gradient = LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [topColor, bottomColor],
    ).createShader(bounds);

    canvas.drawPath(path, Paint()..shader = gradient..style = PaintingStyle.fill);
  }

  /// 绘制星光像素墙面
  static void _drawSparkle({
    required Canvas canvas,
    required IsometricCoordinateConverter converter,
    required bool isLeft,
    required int rows,
    required int cols,
    required Color baseColor,
    required Color lightColor,
  }) {
    // 1. 绘制背景基色
    _drawSolidColor(
      canvas: canvas,
      converter: converter,
      isLeft: isLeft,
      rows: rows,
      cols: cols,
      color: baseColor,
    );

    final random = math.Random(42); // 固定种子
    const double step = 0.6; // 像素块间距

    if (isLeft) {
      for (double r = 0; r < rows; r += step) {
        for (double z = 0; z < kWallGridHeight; z += step) {
          final double hRatio = (kWallGridHeight - z) / kWallGridHeight;
          // 底部密集，顶部稀疏
          if (random.nextDouble() < hRatio * 0.7) {
            final path = Path()
              ..addPolygon([
                converter.getScreenPoint(r, 0, z),
                converter.getScreenPoint(r + step, 0, z),
                converter.getScreenPoint(r + step, 0, z + step),
                converter.getScreenPoint(r, 0, z + step),
              ], true);
            canvas.drawPath(
              path,
              Paint()..color = lightColor.withValues(alpha: 0.2 + random.nextDouble() * 0.6),
            );
          }
        }
      }
    } else {
      for (double c = 0; c < cols; c += step) {
        for (double z = 0; z < kWallGridHeight; z += step) {
          final double hRatio = (kWallGridHeight - z) / kWallGridHeight;
          if (random.nextDouble() < hRatio * 0.7) {
            final path = Path()
              ..addPolygon([
                converter.getScreenPoint(0, c, z),
                converter.getScreenPoint(0, c + step, z),
                converter.getScreenPoint(0, c + step, z + step),
                converter.getScreenPoint(0, c, z + step),
              ], true);
            canvas.drawPath(
              path,
              Paint()..color = lightColor.withValues(alpha: 0.2 + random.nextDouble() * 0.6),
            );
          }
        }
      }
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

  /// 绘制青绿原木质感墙板
  static void _drawGreenWoodPanels({
    required Canvas canvas,
    required IsometricCoordinateConverter converter,
    required bool isLeft,
    required int rows,
    required int cols,
    required Color baseColor,
  }) {
    // 1. 画基础底色
    _drawSolidColor(
      canvas: canvas,
      converter: converter,
      isLeft: isLeft,
      rows: rows,
      cols: cols,
      color: baseColor,
    );

    final count = isLeft ? rows : cols;
    const double plankWidth = 0.5; // 每块木板的宽度（在网格单元中占比）
    
    // 木板之间的沟槽颜色（更深的绿）和高光颜色
    final hsl = HSLColor.fromColor(baseColor);
    final shadowColor = hsl.withLightness((hsl.lightness - 0.12).clamp(0, 1)).toColor();
    final highlightColor = hsl.withLightness((hsl.lightness + 0.08).clamp(0, 1)).toColor();

    final shadowPaint = Paint()
      ..color = shadowColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;
      
    final highlightPaint = Paint()
      ..color = highlightColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.8;

    // 绘制木板接缝沟槽
    for (double i = plankWidth; i < count; i += plankWidth) {
      final pBottom = isLeft
          ? converter.getScreenPoint(i, 0, 0)
          : converter.getScreenPoint(0, i, 0);
      final pTop = isLeft
          ? converter.getScreenPoint(i, 0, kWallGridHeight.toDouble())
          : converter.getScreenPoint(0, i, kWallGridHeight.toDouble());

      // 主深色沟槽
      canvas.drawLine(pBottom, pTop, shadowPaint);
      
      // 细微的高光增加立体感（根据墙面朝向决定高光位置）
      final highlightOffset = isLeft ? const Offset(-1, 0) : const Offset(1, 0);
      canvas.drawLine(
        pBottom + highlightOffset,
        pTop + highlightOffset,
        highlightPaint,
      );
    }
    
    // 增加底部木质踢脚线
    _drawSkirtingBoard(
      canvas: canvas,
      converter: converter,
      isLeft: isLeft,
      rows: rows,
      cols: cols,
      bottomColor: shadowColor,
      shadowColor: shadowColor.withAlpha(200),
      height: 1.0,
    );
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

  /// 绘制熔岩滴落/甜品风格墙面
  static void _drawMeltingDrips({
    required Canvas canvas,
    required IsometricCoordinateConverter converter,
    required bool isLeft,
    required int rows,
    required int cols,
  }) {
    final count = isLeft ? rows : cols;
    final random = math.Random(88); // 固定种子保证渲染一致性

    // 1. 绘制底色 (米黄色)
    _drawSolidColor(
      canvas: canvas,
      converter: converter,
      isLeft: isLeft,
      rows: rows,
      cols: cols,
      color: const Color(0xFFF3E9D2),
    );

    // 2. 绘制彩色垂直细条纹
    final List<Color> stripeColors = [
      const Color(0xFFE8D5B5),
      const Color(0xFFF0C9CF),
      const Color(0xFFC5E0D8),
      const Color(0xFFF5E6C8),
    ];

    final stripePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.8;

    for (double i = 0.5; i < count; i += 0.8) {
      final p1 = isLeft
          ? converter.getScreenPoint(i, 0, 0)
          : converter.getScreenPoint(0, i, 0);
      final p2 = isLeft
          ? converter.getScreenPoint(i, 0, kWallGridHeight.toDouble())
          : converter.getScreenPoint(0, i, kWallGridHeight.toDouble());

      stripePaint.color = stripeColors[random.nextInt(stripeColors.length)]
          .withValues(alpha: 0.6);
      canvas.drawLine(p1, p2, stripePaint);
    }

    // 3. 绘制彩豆 (Sprinkles)
    final sprinkleColors = [
      const Color(0xFFF08080), // 珊瑚红
      const Color(0xFF87CEEB), // 天空蓝
      const Color(0xFFFFD700), // 金色
      const Color(0xFF98FB98), // 浅绿
    ];

    for (int i = 0; i < 20; i++) {
      final double r = random.nextDouble() * count;
      final double z = random.nextDouble() * (kWallGridHeight - 4);
      final center = isLeft
          ? converter.getScreenPoint(r, 0, z)
          : converter.getScreenPoint(0, r, z);

      final paint = Paint()
        ..color = sprinkleColors[random.nextInt(sprinkleColors.length)]
            .withValues(alpha: 0.8)
        ..style = PaintingStyle.fill;

      // 绘制小椭圆豆子
      canvas.save();
      canvas.translate(center.dx, center.dy);
      canvas.rotate(random.nextDouble() * math.pi);
      canvas.drawOval(
        Rect.fromCenter(center: Offset.zero, width: 6, height: 10),
        paint,
      );
      canvas.restore();
    }

    // 4. 绘制顶部滴落效果 (薄荷绿)
    final dripPaint = Paint()
      ..color = const Color(0xFFAEEEEE) // 薄荷蓝绿
      ..style = PaintingStyle.fill;

    final dripPath = Path();
    // 顶部起始线
    final pStart = isLeft
        ? converter.getScreenPoint(0, 0, kWallGridHeight.toDouble())
        : converter.getScreenPoint(0, 0, kWallGridHeight.toDouble());
    dripPath.moveTo(pStart.dx, pStart.dy);

    // 沿着墙顶绘制波浪和滴落
    for (double i = 0; i <= count; i += 0.5) {
      // 随机波动高度 (0.5 - 1.5 之间)
      final double waveZ = kWallGridHeight - 1.0 - random.nextDouble() * 1.5;
      final p = isLeft
          ? converter.getScreenPoint(i, 0, waveZ)
          : converter.getScreenPoint(0, i, waveZ);
      dripPath.lineTo(p.dx, p.dy);

      // 每隔一段距离画一个长滴落
      if (i % 2.5 == 0 && i > 0) {
        final double dripLen = 3.0 + random.nextDouble() * 4.0;
        final double dripZ = kWallGridHeight - dripLen;
        final pBottom = isLeft
            ? converter.getScreenPoint(i, 0, dripZ)
            : converter.getScreenPoint(0, i, dripZ);

        // 绘制滴落圆头
        canvas.drawCircle(pBottom, 6, dripPaint);
        // 绘制连接的长柱 (简化处理：在 Path 中连线)
      }
    }

    // 封闭顶部路径
    final pEndTop = isLeft
        ? converter.getScreenPoint(count.toDouble(), 0, kWallGridHeight.toDouble())
        : converter.getScreenPoint(0, count.toDouble(), kWallGridHeight.toDouble());
    dripPath.lineTo(pEndTop.dx, pEndTop.dy);
    dripPath.close();

    canvas.drawPath(dripPath, dripPaint);

    // 5. 补全长滴落的连接柱体
    for (double i = 2.5; i < count; i += 2.5) {
      final double dripLen = 3.0 + random.nextDouble() * 4.0;
      final double dripZ = kWallGridHeight - dripLen;
      final pTop = isLeft
          ? converter.getScreenPoint(i, 0, kWallGridHeight.toDouble())
          : converter.getScreenPoint(0, i, kWallGridHeight.toDouble());
      final pBottom = isLeft
          ? converter.getScreenPoint(i, 0, dripZ)
          : converter.getScreenPoint(0, i, dripZ);

      canvas.drawRect(
        Rect.fromLTRB(pTop.dx - 4, pTop.dy, pTop.dx + 4, pBottom.dy),
        dripPaint,
      );
    }
  }

  /// 绘制青翠山峦效果
  static void _drawGreenHills({
    required Canvas canvas,
    required IsometricCoordinateConverter converter,
    required bool isLeft,
    required int rows,
    required int cols,
  }) {
    // 1. 绘制背景底色 (极淡的青色)
    _drawSolidColor(
      canvas: canvas,
      converter: converter,
      isLeft: isLeft,
      rows: rows,
      cols: cols,
      color: const Color(0xFFF2F9F5),
    );

    final paint = Paint()..style = PaintingStyle.fill;
    final count = isLeft ? rows : cols;

    // 定义三层山的颜色和参数
    final layers = [
      // 后层 (最高, 最淡)
      _HillLayer(
        color: const Color(0xFFDFEBE0),
        baseHeight: 5.0,
        amplitude: 1.5,
        frequency: 0.6,
        phase: 0.0,
      ),
      // 中层
      _HillLayer(
        color: const Color(0xFFCBE0C8),
        baseHeight: 3.5,
        amplitude: 1.2,
        frequency: 0.8,
        phase: 2.0,
      ),
      // 前层 (最低, 最深)
      _HillLayer(
        color: const Color(0xFFB6D6B0),
        baseHeight: 2.0,
        amplitude: 0.8,
        frequency: 1.2,
        phase: 4.5,
      ),
    ];

    for (var layer in layers) {
      paint.color = layer.color;
      final path = Path();
      
      // 起点 (左下角)
      final start = isLeft 
          ? converter.getScreenPoint(0, 0, 0)
          : converter.getScreenPoint(0, 0, 0);
      path.moveTo(start.dx, start.dy);

      // 沿墙面水平方向绘制波浪
      for (double i = 0; i <= count; i += 0.2) {
        // 计算当前高度 (z)
        final z = layer.baseHeight + math.sin(i * layer.frequency + layer.phase) * layer.amplitude;
        final p = isLeft
            ? converter.getScreenPoint(i, 0, z)
            : converter.getScreenPoint(0, i, z);
        path.lineTo(p.dx, p.dy);
      }

      // 闭合路径 (到右下角再回到起点)
      final endBase = isLeft
          ? converter.getScreenPoint(count.toDouble(), 0, 0)
          : converter.getScreenPoint(0, count.toDouble(), 0);
      path.lineTo(endBase.dx, endBase.dy);
      path.close();

      canvas.drawPath(path, paint);
    }
  }

  /// 绘制法式复古碎花墙纸 (Vintage Floral with Wainscoting)
  static void _drawVintageFloral({
    required Canvas canvas,
    required IsometricCoordinateConverter converter,
    required bool isLeft,
    required int rows,
    required int cols,
    required Color baseColor,
  }) {
    final double wallH = kWallGridHeight + 0.0;
    const double wainscotH = 4.5; // 护墙板高度
    final count = isLeft ? rows : cols;
    final random = math.Random(42);

    // 1. 绘制上半部分底色 (淡青绿)
    _drawSolidColor(
      canvas: canvas,
      converter: converter,
      isLeft: isLeft,
      rows: rows,
      cols: cols,
      color: baseColor,
    );

    // 2. 绘制下半部分护墙板 (随机色木条)
    final woodColors = [
      const Color(0xFFA39074), // 灰褐色
      const Color(0xFFB6A68A), // 浅木色
      const Color(0xFF8E8B75), // 灰绿色调
      const Color(0xFFD2C4AE), // 米黄色
      const Color(0xFFC0B199), // 浅褐色
    ];

    for (double i = 0; i < count; i += 0.8) {
      final Color plankColor = woodColors[random.nextInt(woodColors.length)];
      final path = Path();
      final double width = 0.8;
      if (isLeft) {
        path.addPolygon([
          converter.getScreenPoint(i, 0, 0),
          converter.getScreenPoint(i + width, 0, 0),
          converter.getScreenPoint(i + width, 0, wainscotH),
          converter.getScreenPoint(i, 0, wainscotH),
        ], true);
      } else {
        path.addPolygon([
          converter.getScreenPoint(0, i, 0),
          converter.getScreenPoint(0, i + width, 0),
          converter.getScreenPoint(0, i + width, wainscotH),
          converter.getScreenPoint(0, i, wainscotH),
        ], true);
      }
      canvas.drawPath(path, Paint()..color = plankColor..style = PaintingStyle.fill);
      
      // 绘制木纹细线
      final linePaint = Paint()..color = Colors.black.withValues(alpha: 0.05)..style = PaintingStyle.stroke..strokeWidth = 0.5;
      canvas.drawPath(path, linePaint);
    }

    // 3. 绘制护墙板顶边线 (Top Rail)
    final railPaint = Paint()..color = const Color(0xFF8B7355)..style = PaintingStyle.fill;
    final railPath = Path();
    const double railH = 0.4;
    if (isLeft) {
      railPath.addPolygon([
        converter.getScreenPoint(0, 0, wainscotH),
        converter.getScreenPoint(rows.toDouble(), 0, wainscotH),
        converter.getScreenPoint(rows.toDouble(), 0, wainscotH + railH),
        converter.getScreenPoint(0, 0, wainscotH + railH),
      ], true);
    } else {
      railPath.addPolygon([
        converter.getScreenPoint(0, 0, wainscotH),
        converter.getScreenPoint(0, cols.toDouble(), wainscotH),
        converter.getScreenPoint(0, cols.toDouble(), wainscotH + railH),
        converter.getScreenPoint(0, 0, wainscotH + railH),
      ], true);
    }
    canvas.drawPath(railPath, railPaint);

    // 4. 绘制藤蔓与花簇
    final dotPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.5)
      ..style = PaintingStyle.fill;
    
    final petalPaint = Paint()
      ..color = const Color(0xFFC4D5B4).withValues(alpha: 0.6)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    final flowerPaint = Paint()..style = PaintingStyle.fill;
    final flowerRandom = math.Random(isLeft ? 123 : 456);
    final double scaleFactor = converter.tw / 25; // 根据网格大小优化缩放因子

    // 每 5 个单位一列藤蔓
    for (double i = 2.0; i < count; i += 5.0) {
      // A. 绘制右侧的蕾丝边 (波浪形状)
      for (double z = wainscotH + railH; z < wallH; z += 1.2) {
        final center = isLeft ? converter.getScreenPoint(i + 1.2, 0, z) : converter.getScreenPoint(0, i + 1.2, z);
        canvas.drawCircle(center, 2.5 * scaleFactor, dotPaint);
      }

      // B. 绘制纵向藤蔓枝叶
      final leafPath = Path();
      bool first = true;
      for (double z = wainscotH + railH; z < wallH; z += 0.5) {
        final double xOffset = math.sin(z * 1.5) * 0.4;
        final p = isLeft ? converter.getScreenPoint(i + xOffset, 0, z) : converter.getScreenPoint(0, i + xOffset, z);
        if (first) {
          leafPath.moveTo(p.dx, p.dy);
          first = false;
        } else {
          leafPath.lineTo(p.dx, p.dy);
        }
        
        if (flowerRandom.nextDouble() < 0.3) {
          canvas.drawCircle(p, 1.5 * scaleFactor, petalPaint..style = PaintingStyle.fill);
        }
      }
      canvas.drawPath(leafPath, petalPaint..style = PaintingStyle.stroke);

      // C. 绘制花簇
      for (double z = wainscotH + railH + 1.5; z < wallH - 1.0; z += 3.5) {
        final double xOffset = math.sin(z * 1.5) * 0.8;
        final flowerCenter = isLeft ? converter.getScreenPoint(i + xOffset, 0, z) : converter.getScreenPoint(0, i + xOffset, z);

        final int clusterSize = 2 + flowerRandom.nextInt(2);
        for (int c = 0; c < clusterSize; c++) {
          final clusterOffset = Offset(
            (flowerRandom.nextDouble() - 0.5) * 6 * scaleFactor,
            (flowerRandom.nextDouble() - 0.5) * 6 * scaleFactor,
          );
          final double scale = (0.7 + flowerRandom.nextDouble() * 0.4) * scaleFactor;

          // 花瓣
          flowerPaint.color = const Color(0xFFE5989B);
          for (int k = 0; k < 5; k++) {
            final double angle = k * (2 * math.pi / 5);
            final petalOffset = Offset(math.cos(angle) * 3 * scale, math.sin(angle) * 3 * scale);
            canvas.drawCircle(flowerCenter + clusterOffset + petalOffset, 2.5 * scale, flowerPaint);
          }
          // 花蕊
          flowerPaint.color = const Color(0xFFFFD166);
          canvas.drawCircle(flowerCenter + clusterOffset, 1.5 * scale, flowerPaint);
        }
      }
    }
  }

  /// 绘制常春藤与条纹踢脚线 (Ivy with Skirting)
  static void _drawIvySkirting({
    required Canvas canvas,
    required IsometricCoordinateConverter converter,
    required bool isLeft,
    required int rows,
    required int cols,
    required Color baseColor,
  }) {
    final double wallH = kWallGridHeight + 0.0;
    final count = isLeft ? rows : cols;

    // 1. 绘制墙面底色 (淡米黄)
    _drawSolidColor(
      canvas: canvas,
      converter: converter,
      isLeft: isLeft,
      rows: rows,
      cols: cols,
      color: baseColor,
    );

    // 2. 绘制底部的宽大踢脚线 (白色)
    const double skirtingH = 2.2;
    final skirtingPath = Path();
    if (isLeft) {
      skirtingPath.addPolygon([
        converter.getScreenPoint(0, 0, 0),
        converter.getScreenPoint(rows.toDouble(), 0, 0),
        converter.getScreenPoint(rows.toDouble(), 0, skirtingH),
        converter.getScreenPoint(0, 0, skirtingH),
      ], true);
    } else {
      skirtingPath.addPolygon([
        converter.getScreenPoint(0, 0, 0),
        converter.getScreenPoint(0, cols.toDouble(), 0),
        converter.getScreenPoint(0, cols.toDouble(), skirtingH),
        converter.getScreenPoint(0, 0, skirtingH),
      ], true);
    }
    canvas.drawPath(skirtingPath, Paint()..color = const Color(0xFFF9FBFB)..style = PaintingStyle.fill);

    // 3. 绘制踢脚线上的平行细线 (浅蓝色)
    final linePaint = Paint()
      ..color = const Color(0xFFD8E5E8)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.8;
    
    for (double h = 0.4; h < skirtingH; h += 0.5) {
      final p1 = isLeft ? converter.getScreenPoint(0, 0, h) : converter.getScreenPoint(0, 0, h);
      final p2 = isLeft ? converter.getScreenPoint(rows.toDouble(), 0, h) : converter.getScreenPoint(0, cols.toDouble(), h);
      canvas.drawLine(p1, p2, linePaint);
    }

    // 4. 绘制顶部的常春藤藤蔓 (Ivy)
    final ivyPaint = Paint()
      ..color = const Color(0xFF8B5A2B).withValues(alpha: 0.4) // 浅褐色枝干藤蔓
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;
    
    final leafPaint = Paint()..style = PaintingStyle.fill;
    final random = math.Random(isLeft ? 777 : 888);

    // 绘制主藤蔓 (沿着墙顶波动)
    final ivyPath = Path();
    bool first = true;
    for (double i = 0; i <= count; i += 0.5) {
      // 在墙顶 1.5 单位范围内波动
      final double zOffset = wallH - 0.2 - random.nextDouble() * 0.8;
      final p = isLeft ? converter.getScreenPoint(i, 0, zOffset) : converter.getScreenPoint(0, i, zOffset);
      if (first) {
        ivyPath.moveTo(p.dx, p.dy);
        first = false;
      } else {
        ivyPath.lineTo(p.dx, p.dy);
      }

      // 绘制叶子
      if (random.nextDouble() < 0.6) {
        final leafColor = random.nextBool() 
          ? const Color(0xFFC4D5B4) // 浅绿
          : const Color(0xFFA5B88E); // 深一点的绿
        
        leafPaint.color = leafColor.withValues(alpha: 0.9);
        
        canvas.save();
        canvas.translate(p.dx, p.dy);
        canvas.rotate(random.nextDouble() * math.pi);
        
        // 绘制心形或椭圆形叶片 (由两个小圆/椭圆重叠组成)
        final double leafSize = 4.0 + random.nextDouble() * 4.0;
        canvas.drawOval(Rect.fromCenter(center: const Offset(-2, 0), width: leafSize, height: leafSize * 1.2), leafPaint);
        canvas.drawOval(Rect.fromCenter(center: const Offset(2, 0), width: leafSize, height: leafSize * 1.2), leafPaint);
        
        canvas.restore();
      }
    }
    canvas.drawPath(ivyPath, ivyPaint);
  }

  /// 绘制樱花墙面效果
  static void _drawSakura({
    required Canvas canvas,
    required IsometricCoordinateConverter converter,
    required bool isLeft,
    required int rows,
    required int cols,
    required Color baseColor,
  }) {
    final count = isLeft ? rows : cols;
    final random = math.Random(123); // 固定种子

    // 1. 绘制背景底色 (柔和粉色)
    _drawSolidColor(
      canvas: canvas,
      converter: converter,
      isLeft: isLeft,
      rows: rows,
      cols: cols,
      color: baseColor,
    );

    // 2. 绘制花瓣/花朵
    final flowerPaint = Paint()..color = Colors.white.withValues(alpha: 0.6)..style = PaintingStyle.fill;
    
    // 获取墙面投影参数
    final pOrigin = converter.getScreenPoint(0, 0, 0);
    final pHorizontal = isLeft ? converter.getScreenPoint(1, 0, 0) : converter.getScreenPoint(0, 1, 0);
    final pVertical = converter.getScreenPoint(0, 0, 1);
    final vx = Offset(pHorizontal.dx - pOrigin.dx, pHorizontal.dy - pOrigin.dy);
    final vy = Offset(pVertical.dx - pOrigin.dx, pVertical.dy - pOrigin.dy);

    for (int i = 0; i < 35; i++) {
      final double r = random.nextDouble() * count;
      final double z = random.nextDouble() * kWallGridHeight;
      final double scale = 0.4 + random.nextDouble() * 0.6;
      final double rotation = random.nextDouble() * 2 * math.pi;

      _drawSingleSakuraProjected(canvas, pOrigin, vx, vy, r, z, scale, rotation, flowerPaint);
    }
  }

  /// 在墙面投影空间绘制单个樱花
  static void _drawSingleSakuraProjected(
    Canvas canvas, 
    Offset origin, 
    Offset vx, 
    Offset vy, 
    double x, 
    double z, 
    double scale, 
    double rotation,
    Paint paint
  ) {
    Offset project(double dx, double dz) {
      // 这里的 dx, dz 是花朵局部坐标系下的偏移
      // 需要先进行旋转，再应用投影
      final cosR = math.cos(rotation);
      final sinR = math.sin(rotation);
      final rx = dx * cosR - dz * sinR;
      final rz = dx * sinR + dz * cosR;

      return Offset(
        origin.dx + (x + rx) * vx.dx + (z + rz) * vy.dx,
        origin.dy + (x + rx) * vx.dy + (z + rz) * vy.dy,
      );
    }

    // 简化版樱花：5个花瓣
    for (int i = 0; i < 5; i++) {
      final angle = i * (2 * math.pi / 5);
      final petalPath = Path();
      const int segments = 12;
      for (int j = 0; j <= segments; j++) {
        final t = j / segments;
        // 花瓣形状：水滴形简化
        final double r = (0.5 + 0.5 * math.sin(t * math.pi)) * scale;
        final double petalAngle = angle + (t - 0.5) * 0.8;
        final p = project(r * math.cos(petalAngle), r * math.sin(petalAngle));
        if (j == 0) {
          petalPath.moveTo(p.dx, p.dy);
        } else {
          petalPath.lineTo(p.dx, p.dy);
        }
      }
      petalPath.close();
      canvas.drawPath(petalPath, paint);
    }
    
    // 花蕊
    final center = project(0, 0);
    canvas.drawCircle(center, 0.2 * scale, paint..color = Colors.white.withValues(alpha: 0.8));
    paint.color = Colors.white.withValues(alpha: 0.6); // 恢复透明度
  }
}

class _HillLayer {
  final Color color;
  final double baseHeight;
  final double amplitude;
  final double frequency;
  final double phase;

  _HillLayer({
    required this.color,
    required this.baseHeight,
    required this.amplitude,
    required this.frequency,
    required this.phase,
  });
}
