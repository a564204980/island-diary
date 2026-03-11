import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:island_diary/shared/widgets/typewriter_text.dart';

/// 手绘风格对话气泡，集成打字机效果与点击交互
class SpriteDialogue extends StatefulWidget {
  final String text;
  final bool isNight;
  final bool useTypewriter;
  final VoidCallback? onNext; // 打字完成后的下一步回调

  const SpriteDialogue({
    super.key,
    required this.text,
    this.isNight = false,
    this.useTypewriter = true,
    this.onNext,
  });

  @override
  State<SpriteDialogue> createState() => SpriteDialogueState();
}

class SpriteDialogueState extends State<SpriteDialogue> {
  final GlobalKey<TypewriterTextState> _typewriterKey = GlobalKey();

  void handleTap() {
    if (widget.useTypewriter) {
      final state = _typewriterKey.currentState;
      if (state != null && !state.isFinished) {
        state.skip();
        return;
      }
    }
    widget.onNext?.call();
  }

  @override
  Widget build(BuildContext context) {
    final textColor = widget.isNight
        ? const Color(0xFFE0C097)
        : const Color(0xFF5A3E28);

    return GestureDetector(
      onTap: handleTap,
      behavior: HitTestBehavior.opaque,
      child: CustomPaint(
        painter: _HandDrawnBubblePainter(isNight: widget.isNight),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          constraints: const BoxConstraints(maxWidth: 220),
          color: Colors.transparent, // 显式给一个透明色辅助命中
          child: widget.useTypewriter
              ? TypewriterText(
                  key: _typewriterKey,
                  text: widget.text,
                  style: TextStyle(
                    color: textColor,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    fontFamily: 'Zhi Mang Xing',
                  ),
                )
              : Text(
                  widget.text,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: textColor,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    fontFamily: 'Zhi Mang Xing',
                  ),
                ),
        ),
      ),
    );
  }
}

class _HandDrawnBubblePainter extends CustomPainter {
  final bool isNight;

  _HandDrawnBubblePainter({required this.isNight});

  @override
  void paint(Canvas canvas, Size size) {
    final mainRandom = Random(42); // 每次绘制都从固定种子开始，确保静态
    final paint = Paint()
      ..style = PaintingStyle.fill
      ..color = isNight
          ? const Color(0xFF2A2A3A).withOpacity(0.85)
          : const Color(0xFFFFFDF5).withOpacity(0.92);

    final borderPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.3
      ..strokeCap = StrokeCap.round
      ..color = isNight
          ? const Color(0xFF8B7355).withOpacity(0.7)
          : const Color(0xFF9E896A); // 稍微加深一点对比

    final path = Path();
    final double w = size.width;
    final double h = size.height;
    final double r = 14.0;
    final double tailW = 14.0;
    final double tailH = 9.0;

    // 绘制主路径
    _drawBubblePath(path, w, h, r, tailW, tailH, random: mainRandom);

    // 绘制阴影 (仅日间)
    if (!isNight) {
      canvas.drawShadow(
        path.shift(const Offset(0, 1.5)),
        Colors.black.withOpacity(0.1),
        3,
        true,
      );
    }

    canvas.drawPath(path, paint);
    canvas.drawPath(path, borderPaint);

    // 绘制“复线”或“补笔”效果，模拟多次落笔的不重合感
    final secondPath = Path();
    final secondRandom = Random(43); // 使用不同种子
    _drawBubblePath(
      secondPath,
      w,
      h,
      r,
      tailW,
      tailH,
      jitterScale: 0.8,
      random: secondRandom,
    );

    canvas.drawPath(
      secondPath,
      borderPaint
        ..strokeWidth = 0.8
        ..color = borderPaint.color.withOpacity(0.25),
    );
  }

  void _drawBubblePath(
    Path path,
    double w,
    double h,
    double r,
    double tailW,
    double tailH, {
    double jitterScale = 1.0,
    required Random random,
  }) {
    final rnd = random;
    // 起点：左上角偏右
    path.moveTo(r, 0);

    // 顶边
    _addJitterLine(path, Offset(r, 0), Offset(w - r, 0), jitterScale, rnd);
    // 右上圆角
    _addJitterCorner(path, Offset(w, 0), Offset(w, r), jitterScale, rnd);
    // 右边
    _addJitterLine(path, Offset(w, r), Offset(w, h - r), jitterScale, rnd);
    // 右下圆角
    _addJitterCorner(path, Offset(w, h), Offset(w - r, h), jitterScale, rnd);

    // 底边右段
    _addJitterLine(
      path,
      Offset(w - r, h),
      Offset(w / 2 + tailW / 2, h),
      jitterScale,
      rnd,
    );
    // 对话框尖角
    _addJitterLine(
      path,
      Offset(w / 2 + tailW / 2, h),
      Offset(w / 2, h + tailH),
      jitterScale * 1.5,
      rnd,
    );
    _addJitterLine(
      path,
      Offset(w / 2, h + tailH),
      Offset(w / 2 - tailW / 2, h),
      jitterScale * 1.5,
      rnd,
    );
    // 底边左段
    _addJitterLine(
      path,
      Offset(w / 2 - tailW / 2, h),
      Offset(r, h),
      jitterScale,
      rnd,
    );

    // 左下圆角
    _addJitterCorner(path, Offset(0, h), Offset(0, h - r), jitterScale, rnd);
    // 左边
    _addJitterLine(path, Offset(0, h - r), Offset(0, r), jitterScale, rnd);
    // 左上圆角回到起点
    _addJitterCorner(path, Offset(0, 0), Offset(r, 0), jitterScale, rnd);
  }

  void _addJitterLine(
    Path path,
    Offset start,
    Offset end,
    double scale,
    Random rnd,
  ) {
    const int segments = 6; // 增加段数使线条更碎
    final double dx = (end.dx - start.dx) / segments;
    final double dy = (end.dy - start.dy) / segments;

    for (int i = 1; i <= segments; i++) {
      final double targetX = start.dx + dx * i;
      final double targetY = start.dy + dy * i;

      // 模拟笔尖跳动：中间控制点加入更大且更随机的偏移
      final double midX = start.dx + dx * (i - 0.5);
      final double midY = start.dy + dy * (i - 0.5);

      final double jitterX = (rnd.nextDouble() - 0.5) * 2.2 * scale;
      final double jitterY = (rnd.nextDouble() - 0.5) * 2.2 * scale;

      path.quadraticBezierTo(midX + jitterX, midY + jitterY, targetX, targetY);
    }
  }

  void _addJitterCorner(
    Path path,
    Offset control,
    Offset end,
    double scale,
    Random rnd,
  ) {
    // 这里简化处理：在控制点加入随机性
    final double jitterX = (rnd.nextDouble() - 0.5) * 1.8 * scale;
    final double jitterY = (rnd.nextDouble() - 0.5) * 1.8 * scale;

    path.quadraticBezierTo(
      control.dx + jitterX,
      control.dy + jitterY,
      end.dx,
      end.dy,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
