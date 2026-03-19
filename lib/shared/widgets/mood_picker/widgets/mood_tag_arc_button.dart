import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

/// 弧形标签按钮
class MoodTagArcButton extends StatelessWidget {
  final String tag;
  final bool isEditing;
  final VoidCallback onTap;
  final double radius;

  const MoodTagArcButton({
    super.key,
    required this.tag,
    required this.isEditing,
    required this.onTap,
    this.radius = 130,
  });

  @override
  Widget build(BuildContext context) {
    const double startAngle = 32 * math.pi / 180;
    const double swepAngle = 30 * math.pi / 180;
    final double size = radius * 2 + 100;

    return Center(
      child: _MoodTagArcButtonHitTestWrapper(
        radius: radius,
        startAngle: startAngle,
        swepAngle: swepAngle,
        child: GestureDetector(
          onTap: onTap,
          behavior: HitTestBehavior.opaque,
          child: CustomPaint(
            size: Size(size, size),
            painter: TagArcPainter(
              tag: tag.isEmpty ? "添加标签" : tag,
              isEditing: isEditing,
              radius: radius,
              startAngle: startAngle,
              swepAngle: swepAngle,
            ),
          ),
        ),
      ),
    );
  }
}

/// 自定义 HitTest 包装器
class _MoodTagArcButtonHitTestWrapper extends SingleChildRenderObjectWidget {
  final double radius;
  final double startAngle;
  final double swepAngle;

  const _MoodTagArcButtonHitTestWrapper({
    required Widget child,
    required this.radius,
    required this.startAngle,
    required this.swepAngle,
  }) : super(child: child);

  @override
  RenderObject createRenderObject(BuildContext context) {
    return _RenderMoodTagArcButtonHitTest(radius, startAngle, swepAngle);
  }

  @override
  void updateRenderObject(
    BuildContext context,
    covariant _RenderMoodTagArcButtonHitTest renderObject,
  ) {
    renderObject
      ..radius = radius
      ..startAngle = startAngle
      ..swepAngle = swepAngle;
  }
}

class _RenderMoodTagArcButtonHitTest extends RenderProxyBox {
  double radius;
  double startAngle;
  double swepAngle;

  _RenderMoodTagArcButtonHitTest(this.radius, this.startAngle, this.swepAngle);

  @override
  bool hitTest(BoxHitTestResult result, {required Offset position}) {
    final center = size.center(Offset.zero);
    final dx = position.dx - center.dx;
    final dy = position.dy - center.dy;
    final distance = math.sqrt(dx * dx + dy * dy);

    if (distance < radius - 5 || distance > radius + 25) {
      return false;
    }

    double angle = math.atan2(dy, dx);
    if (angle < startAngle - 0.1 || angle > (startAngle + swepAngle + 0.1)) {
      return false;
    }

    return super.hitTest(result, position: position);
  }
}

class TagArcPainter extends CustomPainter {
  final String tag;
  final bool isEditing;
  final double radius;
  final double startAngle;
  final double swepAngle;

  TagArcPainter({
    required this.tag,
    required this.isEditing,
    required this.radius,
    required this.startAngle,
    required this.swepAngle,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final String displayTag = tag.isEmpty ? "+ 添加标签" : tag;

    final backgroundPaint = Paint()
      ..color = const Color(0xFFFFFDE7).withValues(alpha: 0.6)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 18
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius + 9),
      startAngle - 0.05,
      swepAngle + 0.1,
      false,
      backgroundPaint,
    );

    final chars = displayTag.split('');
    if (chars.isEmpty) {
      return;
    }

    final double effectiveSwep = swepAngle * 0.85;
    final double startArcOffset = startAngle + (swepAngle - effectiveSwep) / 2;
    final double charStep =
        effectiveSwep / (chars.length > 1 ? chars.length - 1 : 1);

    for (int i = 0; i < chars.length; i++) {
      final double charAngle = startArcOffset + i * charStep;
      final double currentR = radius + 9;

      final charOffset = Offset(
        center.dx + currentR * math.cos(charAngle),
        center.dy + currentR * math.sin(charAngle),
      );

      final textPainter = TextPainter(
        text: TextSpan(
          text: chars[i],
          style: TextStyle(
            color: isEditing
                ? const Color(0xFFFF8C00)
                : const Color(0xFF8C7359),
            fontSize: displayTag.length > 6 ? 9 : 11,
            fontWeight: FontWeight.bold,
            fontFamily: 'LXGWWenKai',
          ),
        ),
        textDirection: TextDirection.ltr,
      );
      textPainter.layout();

      canvas.save();
      canvas.translate(charOffset.dx, charOffset.dy);
      textPainter.paint(
        canvas,
        Offset(-textPainter.width / 2, -textPainter.height / 2),
      );
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant TagArcPainter oldDelegate) {
    return oldDelegate.tag != tag || oldDelegate.isEditing != isEditing;
  }
}
