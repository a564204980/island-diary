import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import '../utils/camera_image_processor.dart';

/// 绘制四个角的白色圆角转角框
class MattingFramePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.9)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0
      ..strokeCap = StrokeCap.round;

    const double lineLength = 24.0;
    const double radius = 12.0;

    // 左上角
    final pathLT = Path()
      ..moveTo(0, lineLength)
      ..lineTo(0, radius)
      ..quadraticBezierTo(0, 0, radius, 0)
      ..lineTo(lineLength, 0);
    canvas.drawPath(pathLT, paint);

    // 右上角
    final pathRT = Path()
      ..moveTo(size.width - lineLength, 0)
      ..lineTo(size.width - radius, 0)
      ..quadraticBezierTo(size.width, 0, size.width, radius)
      ..lineTo(size.width, lineLength);
    canvas.drawPath(pathRT, paint);

    // 左下角
    final pathLB = Path()
      ..moveTo(0, size.height - lineLength)
      ..lineTo(0, size.height - radius)
      ..quadraticBezierTo(0, size.height, radius, size.height)
      ..lineTo(lineLength, size.height);
    canvas.drawPath(pathLB, paint);

    // 右下角
    final pathRB = Path()
      ..moveTo(size.width - lineLength, size.height)
      ..lineTo(size.width - radius, size.height)
      ..quadraticBezierTo(size.width, size.height, size.width, size.height - radius)
      ..lineTo(size.width, size.height - lineLength);
    canvas.drawPath(pathRB, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// 描边渲染预览 CustomPainter，支持实线、发光、星光三种样式
class StrokePreviewPainter extends CustomPainter {
  final ui.Image image;
  final double strokeWidth;
  final Color strokeColor;
  final String strokeStyle;
  final double animationProgress;
  final List<ContourPoint> contourPoints;
  final double strokeDistance;
  final Rect normalizedCropRect;
  final Rect activeCropBoxRect;
  final bool isRatioMode;

  StrokePreviewPainter({
    required this.image,
    required this.strokeWidth,
    required this.strokeColor,
    required this.strokeStyle,
    required this.animationProgress,
    required this.contourPoints,
    required this.strokeDistance,
    this.normalizedCropRect = const Rect.fromLTWH(0, 0, 1, 1),
    this.activeCropBoxRect = const Rect.fromLTWH(0, 0, 1, 1),
    this.isRatioMode = false,
  });

  ui.ColorFilter _createThresholdFilter(Color color, {double threshold = 0.16}) {
    // 阈值说明：
    //   高斯模糊后，原图边缘外 1σ 处的 alpha ≈ Q(1) ≈ 0.16。
    //   因此当 sigma = 目标扩展距离 时，threshold = 0.16 对应恰好在 1σ（=扩展距离）处截断。
    //   threshold = 0.5 只会在原始边缘处截断，等于什么都没扩展，描边不可见。
    //   在 Flutter ColorFilter.matrix 中，最后一列的偏移量 (translation vector) 的范围 is 0..255，而非 0..1。
    final double r = color.red.toDouble();
    final double g = color.green.toDouble();
    final double b = color.blue.toDouble();
    const double s = 100.0;
    final double t = -100.0 * threshold * 255.0;
    return ui.ColorFilter.matrix([
      0, 0, 0, 0, r,
      0, 0, 0, 0, g,
      0, 0, 0, 0, b,
      0, 0, 0, s, t,
    ]);
  }

  @override
  void paint(Canvas canvas, Size size) {
    if (size.width <= 0 || size.height <= 0) return;
    final double srcW = image.width.toDouble();
    final double srcH = image.height.toDouble();
    if (srcW <= 0 || srcH <= 0) return;
    
    if (normalizedCropRect.width <= 0 || normalizedCropRect.height <= 0 ||
        normalizedCropRect.left.isNaN || normalizedCropRect.top.isNaN ||
        normalizedCropRect.width.isNaN || normalizedCropRect.height.isNaN) {
      return;
    }
    
    // 渲染区域
    final dstRect = Rect.fromLTWH(0, 0, size.width, size.height);
    
    final srcRect = isRatioMode 
      ? Rect.fromLTWH(0, 0, srcW, srcH)
      : Rect.fromLTWH(
          normalizedCropRect.left * srcW,
          normalizedCropRect.top * srcH,
          normalizedCropRect.width * srcW,
          normalizedCropRect.height * srcH,
        );

    Rect dstDrawRect;
    if (isRatioMode) {
      final double imgAspect = srcW / srcH;
      final double iw = (activeCropBoxRect.width * size.width) / normalizedCropRect.width;
      final double ih = iw / imgAspect;
      final double px = activeCropBoxRect.left * size.width;
      final double py = activeCropBoxRect.top * size.height;
      final double pw = activeCropBoxRect.width * size.width;
      final double ph = activeCropBoxRect.height * size.height;
      final double il = (px + pw / 2) - (normalizedCropRect.left + normalizedCropRect.width / 2) * iw;
      final double it = (py + ph / 2) - (normalizedCropRect.top + normalizedCropRect.height / 2) * ih;
      dstDrawRect = Rect.fromLTWH(il, it, iw, ih);
    } else {
      dstDrawRect = dstRect;
    }

    // 1. 先在最底层绘制清晰图
    canvas.drawImageRect(image, srcRect, dstDrawRect, Paint());

    // 2. 如果是裁剪模式，在上面覆盖一层高斯模糊大图，但剔除裁剪框内部
    if (isRatioMode) {
      canvas.save();
      final double px = activeCropBoxRect.left * size.width;
      final double py = activeCropBoxRect.top * size.height;
      final double pw = activeCropBoxRect.width * size.width;
      final double ph = activeCropBoxRect.height * size.height;
      final physicalRect = Rect.fromLTWH(px, py, pw, ph);

      // 仅在裁剪框外部区域绘制模糊
      canvas.clipRect(physicalRect, clipOp: ui.ClipOp.difference);

      final Rect overlayRect = dstRect.expandToInclude(dstDrawRect);
      canvas.drawRect(
        overlayRect,
        Paint()..color = Colors.black.withValues(alpha: 0.55),
      );
      canvas.restore();
    }

    if (strokeWidth > 0) {
      canvas.save();
      // 开启生成动画裁切
      if (animationProgress < 1.0) {
        final center = Offset(size.width / 2, size.height / 2);
        final double radius = math.sqrt(size.width * size.width + size.height * size.height);
        final Path clipPath = Path()
          ..moveTo(center.dx, center.dy)
          ..arcTo(
            Rect.fromCircle(center: center, radius: radius),
            -math.pi / 2,
            2 * math.pi * animationProgress,
            false,
          )
          ..close();
        canvas.clipPath(clipPath);
      }

      if (strokeStyle == 'solid') {
        canvas.saveLayer(dstRect, Paint());

        // 正确顺序：外层应用 colorFilter（阈值化），内层应用 imageFilter（模糊）
        // restore 的时候先执行内层模糊，再执行外层阈值化，即 先模糊 → 再锐化 的正确顺序
        final double outerSigma = math.max(0.5, strokeWidth + strokeDistance);
        canvas.saveLayer(dstRect, Paint()..colorFilter = _createThresholdFilter(strokeColor));
        canvas.saveLayer(dstRect, Paint()..imageFilter = ui.ImageFilter.blur(sigmaX: outerSigma, sigmaY: outerSigma));
        canvas.drawImageRect(image, srcRect, dstDrawRect, Paint());
        canvas.restore(); // 应用模糊
        canvas.restore(); // 应用阈值化，模糊边缘转为锐利描边

        // 如果有距离，挖空内部的距离区
        if (strokeDistance > 0) {
          final double innerSigma = math.max(0.5, strokeDistance);
          canvas.saveLayer(dstRect, Paint()
            ..colorFilter = _createThresholdFilter(Colors.white)
            ..blendMode = BlendMode.dstOut);
          canvas.saveLayer(dstRect, Paint()..imageFilter = ui.ImageFilter.blur(sigmaX: innerSigma, sigmaY: innerSigma));
          canvas.drawImageRect(image, srcRect, dstDrawRect, Paint());
          canvas.restore(); // 应用模糊
          canvas.restore(); // 阈值化后用 dstOut 挖空内圈
        }

        canvas.restore();
      } else if (strokeStyle == 'glow') {
        canvas.saveLayer(dstRect, Paint());

        final double totalSigma = math.max(0.5, strokeWidth + strokeDistance);
        canvas.saveLayer(dstRect, Paint()..colorFilter = ui.ColorFilter.mode(strokeColor, BlendMode.srcIn));
        canvas.saveLayer(dstRect, Paint()..imageFilter = ui.ImageFilter.blur(sigmaX: totalSigma, sigmaY: totalSigma));
        canvas.drawImageRect(image, srcRect, dstDrawRect, Paint());
        canvas.restore(); // 应用模糊
        canvas.restore(); // 应用颜色

        if (strokeDistance > 0) {
          final double innerSigma = math.max(0.5, strokeDistance);
          canvas.saveLayer(dstRect, Paint()
            ..colorFilter = _createThresholdFilter(Colors.white)
            ..blendMode = BlendMode.dstOut);
          canvas.saveLayer(dstRect, Paint()..imageFilter = ui.ImageFilter.blur(sigmaX: innerSigma, sigmaY: innerSigma));
          canvas.drawImageRect(image, srcRect, dstDrawRect, Paint());
          canvas.restore();
          canvas.restore();
        }

        canvas.restore();
      } else if (strokeStyle == 'stars') {
        // 1. 将原图提取出来的边缘轮廓点沿着法线外推并映射到当前的 dstDrawRect 空间中
        final List<Offset> mappedPoints = [];
        for (final p in contourPoints) {
          final double rx = (p.x - srcRect.left) / srcRect.width;
          final double ry = (p.y - srcRect.top) / srcRect.height;
          final double screenX = rx * dstDrawRect.width + dstDrawRect.left;
          final double screenY = ry * dstDrawRect.height + dstDrawRect.top;

          // 在屏幕/画布空间下沿着法线进行外推
          final double px = screenX + p.nx * strokeDistance;
          final double py = screenY + p.ny * strokeDistance;

          mappedPoints.add(Offset(px, py));
        }

        // 2. 计算间距与星星大小 (间距固定，加粗只变大星星，不增加数量)
        final double spacing = 11.0;
        final double starSize = 6.0 + strokeWidth * 0.8;

        // 3. 过滤出等距分布 of 星星点
        final List<Offset> starPoints = CameraImageProcessor.filterMappedPoints(mappedPoints, spacing);

        // 4. 绘制圆润的五角星
        final starPaint = Paint()..color = strokeColor;
        for (int i = 0; i < starPoints.length; i++) {
          final p = starPoints[i];
          canvas.save();
          final double hash = (math.sin(i * 12.9898) * 43758.5453).abs() % 1.0;
          canvas.translate(p.dx, p.dy);
          canvas.rotate(hash * 2.0 * math.pi);
          CameraImageProcessor.drawRoundedFivePointStar(canvas, Offset.zero, starSize / 2, starPaint);
          canvas.restore();
        }
      }
      canvas.restore();
    }

    // 4. 如果非裁剪模式，在上面覆盖最终的前景 (裁剪模式因为已经在最底层画了清晰大图且盖了模糊边缘，所以在此不需要重新绘制，避免覆盖高斯模糊)
    if (!isRatioMode) {
      canvas.drawImageRect(image, srcRect, dstDrawRect, Paint());
    }
  }

  @override
  bool shouldRepaint(covariant StrokePreviewPainter oldDelegate) {
    return oldDelegate.image != image ||
           oldDelegate.strokeWidth != strokeWidth ||
           oldDelegate.strokeColor != strokeColor ||
           oldDelegate.strokeStyle != strokeStyle ||
           oldDelegate.animationProgress != animationProgress ||
           oldDelegate.contourPoints != contourPoints ||
           oldDelegate.strokeDistance != strokeDistance ||
           oldDelegate.normalizedCropRect != normalizedCropRect ||
           oldDelegate.activeCropBoxRect != activeCropBoxRect ||
           oldDelegate.isRatioMode != isRatioMode;
  }
}

/// 描边样式预览 CustomPainter
class StrokeStylePreviewPainter extends CustomPainter {
  final String style;

  StrokeStylePreviewPainter({required this.style});

  @override
  void paint(Canvas canvas, Size size) {
    if (style == 'none') {
      // 原图：绘制一个可爱的相片框简笔画，中间加一条斜线代表“无描边”
      final paint = Paint()
        ..color = Colors.white38
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeWidth = 1.6;

      // 外框
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(size.width * 0.26, size.height * 0.15, size.width * 0.48, size.height * 0.52),
          const Radius.circular(4),
        ),
        paint,
      );
      // 中间的禁止斜线
      canvas.drawLine(
        Offset(size.width * 0.32, size.height * 0.20),
        Offset(size.width * 0.68, size.height * 0.62),
        paint,
      );
      return;
    }

    // 1. 创建类似手绘感曲线路径 Path
    final Path path = Path();
    // 以 size 为限做贝塞尔曲线，类似 S 线
    path.moveTo(size.width * 0.22, size.height * 0.72);
    path.cubicTo(
      size.width * 0.28, size.height * 0.15,
      size.width * 0.72, size.height * 0.85,
      size.width * 0.78, size.height * 0.28,
    );

    if (style == 'solid') {
      // 实线描边：先用较粗的白色 Paint 绘制底层描边，再用较细的深色 Paint 绘制线条
      final strokePaint = Paint()
        ..color = Colors.white
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..strokeWidth = 5.5;
      canvas.drawPath(path, strokePaint);

      final corePaint = Paint()
        ..color = const Color(0xFF262626)
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..strokeWidth = 2.0;
      canvas.drawPath(path, corePaint);
    } else if (style == 'glow') {
      // 发光描边：先用多层宽幅半透明白色绘制发光底图
      for (double w = 8.0; w >= 3.0; w -= 1.5) {
        final glowPaint = Paint()
          ..color = Colors.white.withValues(alpha: w == 8.0 ? 0.15 : 0.25)
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round
          ..strokeJoin = StrokeJoin.round
          ..strokeWidth = w;
        canvas.drawPath(path, glowPaint);
      }

      // 再绘制清晰的核心线
      final corePaint = Paint()
        ..color = Colors.white
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..strokeWidth = 1.8;
      canvas.drawPath(path, corePaint);
    } else if (style == 'stars') {
      // 星光描边：沿着手绘 Path 等距分布画小四角星
      final starPaint = Paint()
        ..color = Colors.white
        ..style = PaintingStyle.fill;

      // 提取 Path 的 Metrics 沿着路径等距采样
      final metrics = path.computeMetrics();
      for (final metric in metrics) {
        final double length = metric.length;
        const double step = 6.0; // 星星点距
        for (double d = 0.0; d <= length; d += step) {
          final tangent = metric.getTangentForOffset(d);
          if (tangent != null) {
            canvas.save();
            canvas.translate(tangent.position.dx, tangent.position.dy);
            
            // 四角星大小可以随 hash 微微抖动产生灵动感
            final double hash = (math.sin(d * 12.9898) * 43758.5453).abs() % 1.0;
            final double starSize = 3.5 + (hash * 1.5);
            canvas.rotate(hash * 2 * math.pi);
            
            _drawMiniStar(canvas, starSize, starPaint);
            canvas.restore();
          }
        }
      }
    }
  }

  // 绘制迷你四角星
  void _drawMiniStar(Canvas canvas, double size, Paint paint) {
    final Path path = Path();
    final double r = size / 2;
    path.moveTo(0, -r);
    path.quadraticBezierTo(0, 0, r, 0);
    path.quadraticBezierTo(0, 0, 0, r);
    path.quadraticBezierTo(0, 0, -r, 0);
    path.quadraticBezierTo(0, 0, 0, -r);
    path.close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant StrokeStylePreviewPainter oldDelegate) {
    return oldDelegate.style != style;
  }
}
