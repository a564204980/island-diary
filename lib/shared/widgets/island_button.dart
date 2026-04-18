import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// 通用手绘风格按钮
class IslandButton extends StatefulWidget {
  final String text;
  final VoidCallback onTap;
  final double? width;
  final double height;
  final Color? backgroundColor;
  final TextStyle? textStyle;
  final Widget? icon;
  final bool useHandDrawn;

  const IslandButton({
    super.key,
    required this.text,
    required this.onTap,
    this.width,
    this.height = 44,
    this.backgroundColor,
    this.textStyle,
    this.icon,
    this.useHandDrawn = true,
  });

  @override
  State<IslandButton> createState() => _IslandButtonState();
}

class _IslandButtonState extends State<IslandButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
    );
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.95,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleTapDown(TapDownDetails details) {
    _controller.forward();
    HapticFeedback.lightImpact();
  }

  void _handleTapUp(TapUpDetails details) {
    _controller.reverse();
  }

  void _handleTapCancel() {
    _controller.reverse();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: _handleTapDown,
      onTapUp: _handleTapUp,
      onTapCancel: _handleTapCancel,
      onTap: widget.onTap,
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: CustomPaint(
          painter: _HandDrawnCapsulePainter(
            backgroundColor:
                widget.backgroundColor ?? Colors.white.withValues(alpha: 0.38),
            useHandDrawn: widget.useHandDrawn,
          ),
          child: Container(
            width: widget.width,
            height: widget.height,
            padding: const EdgeInsets.symmetric(horizontal: 24),
            alignment: Alignment.center,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (widget.icon != null) ...[
                  widget.icon!,
                  const SizedBox(width: 8),
                ],
                Text(
                  widget.text,
                  style:
                      widget.textStyle ??
                      const TextStyle(
                        color: Color(0xFF5A3E28),
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _HandDrawnCapsulePainter extends CustomPainter {
  final Color backgroundColor;
  final bool useHandDrawn;

  _HandDrawnCapsulePainter({
    required this.backgroundColor,
    required this.useHandDrawn,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final rnd = Random(42);

    // ======= 发光效果 (抛弃 MaskFilter，改用 drawShadow) =======

    final paint = Paint()
      ..style = PaintingStyle.fill
      ..color = backgroundColor;

    final borderPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.3
      ..strokeCap = StrokeCap.round
      ..color = const Color(0xFF9E896A);

    final path = Path();

    if (useHandDrawn) {
      _drawCapsulePath(path, size, rnd: rnd);
    } else {
      // 平滑模式：标准胶囊路径
      path.addRRect(
        RRect.fromLTRBR(
          0,
          0,
          size.width,
          size.height,
          Radius.circular(size.height / 2),
        ),
      );
    }

    // ======= 纯粹边缘外发光实现 (True Outer Glow) =======
    // 1. 底层柔和光晕
    final ambientGlowPaint = Paint()
      ..color = const Color.fromRGBO(213, 213, 213, 0.4)
      ..maskFilter = const MaskFilter.blur(BlurStyle.outer, 12.0);
    canvas.drawPath(path, ambientGlowPaint);

    // 2. 金色核心光晕
    final goldenGlowPaint = Paint()
      ..color = const Color.fromRGBO(244, 214, 115, 0.7)
      ..maskFilter = const MaskFilter.blur(BlurStyle.outer, 5.0);
    canvas.drawPath(path, goldenGlowPaint);

    canvas.drawPath(path, paint);
    canvas.drawPath(path, borderPaint);

    if (useHandDrawn) {
      // 绘制补笔层
      final sketchPath = Path();
      final rndSketch = Random(43);
      _drawCapsulePath(sketchPath, size, jitterScale: 0.8, rnd: rndSketch);

      canvas.drawPath(
        sketchPath,
        borderPaint
          ..strokeWidth = 0.8
          ..color = borderPaint.color.withValues(alpha: 0.25),
      );
    }
  }

  void _drawCapsulePath(
    Path path,
    Size size, {
    double jitterScale = 1.0,
    required Random rnd,
  }) {
    final double w = size.width;
    final double h = size.height;
    final double r = h / 2; // 圆角半径为高度的一半，形成胶囊形

    // 起点：顶部左侧圆角后的直线起点
    path.moveTo(r, 0);

    // 顶边
    _addJitterLine(path, Offset(r, 0), Offset(w - r, 0), jitterScale, rnd);
    // 右侧半圆
    _addJitterArc(path, Offset(w - r, r), r, -pi / 2, pi, jitterScale, rnd);
    // 底边
    _addJitterLine(path, Offset(w - r, h), Offset(r, h), jitterScale, rnd);
    // 左侧半圆
    _addJitterArc(path, Offset(r, r), r, pi / 2, pi, jitterScale, rnd);

    path.close();
  }

  void _addJitterLine(
    Path path,
    Offset start,
    Offset end,
    double scale,
    Random rnd,
  ) {
    const int segments = 4;
    final double dx = (end.dx - start.dx) / segments;
    final double dy = (end.dy - start.dy) / segments;

    for (int i = 1; i <= segments; i++) {
      final double targetX = start.dx + dx * i;
      final double targetY = start.dy + dy * i;
      final double midX = start.dx + dx * (i - 0.5);
      final double midY = start.dy + dy * (i - 0.5);

      final double jitterX = (rnd.nextDouble() - 0.5) * 2.0 * scale;
      final double jitterY = (rnd.nextDouble() - 0.5) * 2.0 * scale;

      path.quadraticBezierTo(midX + jitterX, midY + jitterY, targetX, targetY);
    }
  }

  void _addJitterArc(
    Path path,
    Offset center,
    double radius,
    double startAngle,
    double sweepAngle,
    double scale,
    Random rnd,
  ) {
    const int segments = 4;
    final double step = sweepAngle / segments;

    for (int i = 1; i <= segments; i++) {
      final double targetAngle = startAngle + step * i;
      final double midAngle = startAngle + step * (i - 0.5);
      final double jitterR = radius + (rnd.nextDouble() - 0.5) * 1.8 * scale;

      final double targetX = center.dx + radius * cos(targetAngle);
      final double targetY = center.dy + radius * sin(targetAngle);
      final double midX = center.dx + jitterR * cos(midAngle);
      final double midY = center.dy + jitterR * sin(midAngle);

      path.quadraticBezierTo(midX, midY, targetX, targetY);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
