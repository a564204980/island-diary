import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:flutter/rendering.dart';

/// 心情强度选择器：右侧弧形滑动条
class MoodIntensitySlider extends StatefulWidget {
  final double intensity; // 1.0 - 10.0
  final ValueChanged<double> onChanged;
  final double radius;

  const MoodIntensitySlider({
    super.key,
    required this.intensity,
    required this.onChanged,
    this.radius = 180,
  });

  @override
  State<MoodIntensitySlider> createState() => _MoodIntensitySliderState();
}

class _MoodIntensitySliderState extends State<MoodIntensitySlider> {
  // 圆弧范围设定 (基于 0 度在右侧中点，顺时针为正)
  // 参考 UI，圆弧大致分布在 -60 度到 60 度之间
  // 调整为更短的弧度：从约 2 点钟方向到 4 点钟方向
  final double startAngle = -math.pi / 4; // -45度 (进一步上移)
  final double swepAngle = math.pi / 3; // 60度 (总弧长缩短一半)

  void _handlePanUpdate(DragUpdateDetails details, Size size) {
    _updateIntensity(details.localPosition, size);
  }

  void _handleTapDown(TapDownDetails details, Size size) {
    _updateIntensity(details.localPosition, size);
  }

  void _updateIntensity(Offset localPosition, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final dx = localPosition.dx - center.dx;
    final dy = localPosition.dy - center.dy;
    final distance = math.sqrt(dx * dx + dy * dy);

    // 碰撞检测：外侧宽容度保持 60 防断触，内侧收窄至 20 避免遮挡弹出的心情模块
    if (distance < widget.radius - 20 || distance > widget.radius + 60) return;

    double angle = math.atan2(dy, dx);

    // 放宽角度过滤区间的缓冲，防止快速拖动时因手指离开扇区而断触
    if (angle < startAngle - 0.4 || angle > (startAngle + swepAngle + 0.4)) {
      return;
    }

    double normalized = (angle - startAngle) / swepAngle;
    normalized = normalized.clamp(0.0, 1.0);

    // 连续、平滑地输出 double 强度值
    double newIntensity = 1 + normalized * 9;

    // 触觉反馈仅在整数位变化时触发一次，不干扰连续的 setState
    if (newIntensity.round() != widget.intensity.round()) {
      HapticFeedback.selectionClick();
    }

    widget.onChanged(newIntensity);
  }

  @override
  Widget build(BuildContext context) {
    final double size = widget.radius * 2 + 100;

    return Center(
      child: _MoodIntensitySliderHitTestWrapper(
        radius: widget.radius,
        startAngle: startAngle,
        swepAngle: swepAngle,
        child: GestureDetector(
          onPanUpdate: (details) => _handlePanUpdate(details, Size(size, size)),
          onTapDown: (details) => _handleTapDown(details, Size(size, size)),
          behavior: HitTestBehavior.translucent,
          child: CustomPaint(
            size: Size(size, size),
            painter: IntensityPainter(
              intensity: widget.intensity,
              radius: widget.radius,
              startAngle: startAngle,
              swepAngle: swepAngle,
            ),
          ),
        ),
      ),
    );
  }
}

/// 自定义 HitTest 包装器，仅允许点击在弧线区域
class _MoodIntensitySliderHitTestWrapper extends SingleChildRenderObjectWidget {
  final double radius;
  final double startAngle;
  final double swepAngle;

  const _MoodIntensitySliderHitTestWrapper({
    required Widget child,
    required this.radius,
    required this.startAngle,
    required this.swepAngle,
  }) : super(child: child);

  @override
  RenderObject createRenderObject(BuildContext context) {
    return _RenderMoodIntensitySliderHitTest(radius, startAngle, swepAngle);
  }

  @override
  void updateRenderObject(
    BuildContext context,
    covariant _RenderMoodIntensitySliderHitTest renderObject,
  ) {
    renderObject
      ..radius = radius
      ..startAngle = startAngle
      ..swepAngle = swepAngle;
  }
}

class _RenderMoodIntensitySliderHitTest extends RenderProxyBox {
  double radius;
  double startAngle;
  double swepAngle;

  _RenderMoodIntensitySliderHitTest(
    this.radius,
    this.startAngle,
    this.swepAngle,
  );

  @override
  bool hitTest(BoxHitTestResult result, {required Offset position}) {
    // 计算点击位置相对于组件中心的极坐标
    final center = size.center(Offset.zero);
    final dx = position.dx - center.dx;
    final dy = position.dy - center.dy;
    final distance = math.sqrt(dx * dx + dy * dy);

    // 1. 判断半径范围 (外侧放宽到 60 避免断触，内侧收窄到 20 避免遮挡拨盘)
    if (distance < radius - 20 || distance > radius + 60) {
      return false; // 不在弧线范围内，允许穿透
    }

    // 2. 判断角度范围 (允许 0.4 弧度的缓冲)
    double angle = math.atan2(dy, dx);
    if (angle < startAngle - 0.4 || angle > (startAngle + swepAngle + 0.4)) {
      return false; // 不在弧线扇区内，允许穿透
    }

    // 在响应区域内，执行正常的命中测试，并拦截事件
    return super.hitTest(result, position: position);
  }
}

class IntensityPainter extends CustomPainter {
  final double intensity;
  final double radius;
  final double startAngle;
  final double swepAngle;

  IntensityPainter({
    required this.intensity,
    required this.radius,
    required this.startAngle,
    required this.swepAngle,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final rect = Rect.fromCircle(center: center, radius: radius);
    const double strokeWidth = 12.0;
    final rnd = math.Random(42);
    final rndSketch = math.Random(43);

    // 1. 底色轨道 (原生圆角弧)
    canvas.drawArc(
      rect,
      startAngle,
      swepAngle,
      false,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.round
        ..color = Colors.black.withValues(alpha: 0.08),
    );

    // 2. 进度弧线 (原生圆角弧 + 渐变)
    double progressPercent = (intensity - 1) / 9;
    canvas.drawArc(
      rect,
      startAngle,
      swepAngle * progressPercent,
      false,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.round
        ..shader = uiGradient(rect),
    );

    // 3. 整体轨道手绘抖动描边 (对齐对话框 _HandDrawnBubblePainter)
    final outerR = radius + strokeWidth / 2;
    final innerR = radius - strokeWidth / 2;

    final mainBorderPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.3
      ..strokeCap = StrokeCap.round
      ..color = const Color(0xFF9E896A).withValues(alpha: 0.7);

    final sketchBorderPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.8
      ..strokeCap = StrokeCap.round
      ..color = const Color(0xFF9E896A).withValues(alpha: 0.25);

    // 外圆弧手绘描边 (主笔)
    canvas.drawPath(
      _buildJitterArcPath(center, outerR, startAngle, swepAngle, rnd),
      mainBorderPaint,
    );
    // 内圆弧手绘描边 (主笔)
    canvas.drawPath(
      _buildJitterArcPath(center, innerR, startAngle, swepAngle, rnd),
      mainBorderPaint,
    );

    // 外圆弧手绘补笔 (草图层)
    canvas.drawPath(
      _buildJitterArcPath(
        center,
        outerR,
        startAngle,
        swepAngle,
        rndSketch,
        jitter: 0.8,
      ),
      sketchBorderPaint,
    );
    // 内圆弧手绘补笔 (草图层)
    canvas.drawPath(
      _buildJitterArcPath(
        center,
        innerR,
        startAngle,
        swepAngle,
        rndSketch,
        jitter: 0.8,
      ),
      sketchBorderPaint,
    );

    // 4. 进度弧专属手绘描边 (仅绘制进度范围，StrokeCap.round 自然为两端生成圆头)
    final progressSweep = swepAngle * progressPercent;
    if (progressSweep.abs() > 0.01) {
      final rndP = math.Random(44);
      final rndPS = math.Random(45);

      // 外圆弧进度描边
      canvas.drawPath(
        _buildJitterArcPath(center, outerR, startAngle, progressSweep, rndP),
        mainBorderPaint,
      );
      // 内圆弧进度描边
      canvas.drawPath(
        _buildJitterArcPath(center, innerR, startAngle, progressSweep, rndP),
        mainBorderPaint,
      );
      // 补笔层
      canvas.drawPath(
        _buildJitterArcPath(
          center,
          outerR,
          startAngle,
          progressSweep,
          rndPS,
          jitter: 0.8,
        ),
        sketchBorderPaint,
      );
      canvas.drawPath(
        _buildJitterArcPath(
          center,
          innerR,
          startAngle,
          progressSweep,
          rndPS,
          jitter: 0.8,
        ),
        sketchBorderPaint,
      );

      // 进度弧端点盖帽 半圆描边
      _drawRoundCapBorder(
        canvas,
        center,
        radius,
        strokeWidth,
        startAngle,
        true,
        mainBorderPaint,
      );
      _drawRoundCapBorder(
        canvas,
        center,
        radius,
        strokeWidth,
        startAngle,
        true,
        sketchBorderPaint,
      );

      final progressEndA = startAngle + progressSweep;
      _drawRoundCapBorder(
        canvas,
        center,
        radius,
        strokeWidth,
        progressEndA,
        false,
        mainBorderPaint,
      );
      _drawRoundCapBorder(
        canvas,
        center,
        radius,
        strokeWidth,
        progressEndA,
        false,
        sketchBorderPaint,
      );
    }

    // 整个刻度弧的两端也需要盖帽
    _drawRoundCapBorder(
      canvas,
      center,
      radius,
      strokeWidth,
      startAngle,
      true,
      mainBorderPaint,
    );
    _drawRoundCapBorder(
      canvas,
      center,
      radius,
      strokeWidth,
      startAngle,
      true,
      sketchBorderPaint,
    );
    _drawRoundCapBorder(
      canvas,
      center,
      radius,
      strokeWidth,
      startAngle + swepAngle,
      false,
      mainBorderPaint,
    );
    _drawRoundCapBorder(
      canvas,
      center,
      radius,
      strokeWidth,
      startAngle + swepAngle,
      false,
      sketchBorderPaint,
    );

    // 5. 绘制指示器小圆点 (对齐 UI：白底 + 橙心)
    final indicatorAngle = startAngle + swepAngle * progressPercent;
    final indicatorOffset = Offset(
      center.dx + radius * math.cos(indicatorAngle),
      center.dy + radius * math.sin(indicatorAngle),
    );

    // 使用 drawShadow 替换 MaskFilter.blur 阴影，避免软件渲染阻塞
    canvas.drawShadow(
      Path()..addOval(Rect.fromCircle(center: indicatorOffset, radius: 7.5)),
      Colors.black54,
      2.5,
      true,
    );
    canvas.drawCircle(indicatorOffset, 6.5, Paint()..color = Colors.white);
    canvas.drawCircle(
      indicatorOffset,
      3.5,
      Paint()..color = const Color(0xFFFF8C00),
    );

    // 5. 绘制数字刻度 (对齐 UI)
    for (int i = 1; i <= 10; i++) {
      double iPercent = (i - 1) / 9;
      double iAngle = startAngle + swepAngle * iPercent;
      final textOffset = Offset(
        center.dx + (radius + 15) * math.cos(iAngle),
        center.dy + (radius + 15) * math.sin(iAngle),
      );
      _drawText(canvas, i.toString(), textOffset);
    }
  }

  Path _buildJitterArcPath(
    Offset center,
    double r,
    double startA,
    double sweepA,
    math.Random rnd, {
    double jitter = 1.0,
  }) {
    const int segments = 8;
    final path = Path();
    final double step = sweepA / segments;
    path.moveTo(
      center.dx + r * math.cos(startA),
      center.dy + r * math.sin(startA),
    );
    for (int i = 1; i <= segments; i++) {
      final double targetA = startA + i * step;
      final double midA = startA + (i - 0.5) * step;
      final double jitterR = r + (rnd.nextDouble() - 0.5) * 2.0 * jitter;
      path.quadraticBezierTo(
        center.dx + jitterR * math.cos(midA),
        center.dy + jitterR * math.sin(midA),
        center.dx + r * math.cos(targetA),
        center.dy + r * math.sin(targetA),
      );
    }
    return path;
  }

  /// 绘制半圆描边，用于封闭端帽（与主描边风格一致的微抖动）
  void _drawRoundCapBorder(
    Canvas canvas,
    Offset center,
    double radius,
    double strokeWidth,
    double capA,
    bool isStart,
    Paint paint,
  ) {
    final capCenter = Offset(
      center.dx + radius * math.cos(capA),
      center.dy + radius * math.sin(capA),
    );
    final capR = strokeWidth / 2;

    // 半圆的起始和清扫角度
    // 从外层边缘 (capA) 出发
    final double startArcA = capA;
    // 如果是起点封口，向轨道切线反向 (-pi) 画半圆；如果是终点封口则顺着画 (+pi)
    final double sweepArcA = isStart ? -math.pi : math.pi;

    // 为了保持手绘感，将半圆拆成 4 段并加上随机偏移
    const int capSegments = 4;
    final double step = sweepArcA / capSegments;
    final rnd = math.Random((capA * 100).toInt()); // 固定种子

    final path = Path();
    path.moveTo(
      capCenter.dx + capR * math.cos(startArcA),
      capCenter.dy + capR * math.sin(startArcA),
    );

    for (int i = 1; i <= capSegments; i++) {
      final double targetA = startArcA + i * step;
      final double midA = startArcA + (i - 0.5) * step;
      final double jitterR = capR + (rnd.nextDouble() - 0.5) * 1.5;

      path.quadraticBezierTo(
        capCenter.dx + jitterR * math.cos(midA),
        capCenter.dy + jitterR * math.sin(midA),
        capCenter.dx + capR * math.cos(targetA),
        capCenter.dy + capR * math.sin(targetA),
      );
    }
    canvas.drawPath(path, paint);
  }

  void _drawText(Canvas canvas, String text, Offset offset) {
    final textPainter = TextPainter(
      text: TextSpan(
        text: text,
        style: const TextStyle(
          color: Color(0xFF8C7359), // 加深灰褐色，提升对比度
          fontSize: 10, // 字号调小，更精致
          fontWeight: FontWeight.bold,
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();
    textPainter.paint(
      canvas,
      offset - Offset(textPainter.width / 2, textPainter.height / 2),
    );
  }

  Shader uiGradient(Rect rect) {
    return const LinearGradient(
      colors: [Color(0xFFFFE474), Color(0xFFFFB344), Color(0xFFFF4D4D)],
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
    ).createShader(rect);
  }

  @override
  bool shouldRepaint(covariant IntensityPainter oldDelegate) {
    return oldDelegate.intensity != intensity;
  }
}
