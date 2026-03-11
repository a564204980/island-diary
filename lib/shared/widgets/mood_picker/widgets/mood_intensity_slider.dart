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
  final double startAngle = -math.pi / 6; // -30度 (约 11 点钟方向)
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

    // 碰撞检测：只有在弧线附近（半径 ± 40）点击才有效
    if ((distance - widget.radius).abs() > 45) return;

    double angle = math.atan2(dy, dx);

    // 限制在右侧弧形区域内 (atan2 范围为 -pi 到 pi)
    // 对于 -45 到 45 度，无需特殊处理跳变

    // 过滤掉不在弧形范围内的角度 (允许缓冲区)
    if (angle < startAngle - 0.2 || angle > (startAngle + swepAngle + 0.2)) {
      return;
    }

    double normalized = (angle - startAngle) / swepAngle;
    normalized = normalized.clamp(0.0, 1.0);

    double newIntensity = 1 + normalized * 9;

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

    // 1. 判断半径范围 (弧形宽度约为 45px，包含数字)
    if ((distance - radius).abs() > 45) {
      return false; // 不在弧线范围内，允许穿透
    }

    // 2. 判断角度范围 (允许 0.2 弧度的缓冲)
    double angle = math.atan2(dy, dx);
    if (angle < startAngle - 0.2 || angle > (startAngle + swepAngle + 0.2)) {
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

    final paintBase = Paint()
      ..color = Colors.black
          .withValues(alpha: 0.1) // 背景弧线改淡
      ..style = PaintingStyle.stroke
      ..strokeWidth = 10
      ..strokeCap = StrokeCap.round;

    final paintProgress = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 10
      ..strokeCap = StrokeCap.round
      ..shader = uiGradient(rect);

    // 1. 绘制底色圆弧
    canvas.drawArc(rect, startAngle, swepAngle, false, paintBase);

    // 2. 绘制进度圆弧
    double progressPercent = (intensity - 1) / 9;
    canvas.drawArc(
      rect,
      startAngle,
      swepAngle * progressPercent,
      false,
      paintProgress,
    );

    // 3. 绘制指示器小圆点
    final indicatorAngle = startAngle + swepAngle * progressPercent;
    final indicatorOffset = Offset(
      center.dx + radius * math.cos(indicatorAngle),
      center.dy + radius * math.sin(indicatorAngle),
    );

    canvas.drawCircle(
      indicatorOffset,
      7,
      Paint()
        ..color = Colors.black12
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2),
    );
    canvas.drawCircle(indicatorOffset, 6, Paint()..color = Colors.white);
    canvas.drawCircle(
      indicatorOffset,
      3.5,
      Paint()..color = const Color(0xFFFF8C00),
    );

    // 4. 绘制数字刻度 (1-10)
    for (int i = 1; i <= 10; i++) {
      double iPercent = (i - 1) / 9;
      double iAngle = startAngle + swepAngle * iPercent;

      // 数字在弧线外侧，落在右侧突起圆区域内显示
      final textOffset = Offset(
        center.dx + (radius + 18) * math.cos(iAngle),
        center.dy + (radius + 18) * math.sin(iAngle),
      );

      _drawText(canvas, i.toString(), textOffset);
    }
  }

  void _drawText(Canvas canvas, String text, Offset offset) {
    final textPainter = TextPainter(
      text: TextSpan(
        text: text,
        style: const TextStyle(
          color: Colors.black87, // 数字黑色
          fontSize: 12,
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
