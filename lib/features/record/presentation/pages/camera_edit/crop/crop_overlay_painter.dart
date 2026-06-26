import 'package:flutter/material.dart';

class CropOverlayPainter extends CustomPainter {
  final Rect rect;
  final double edgePadding;
  final bool isDragging;

  CropOverlayPainter({
    required this.rect,
    required this.edgePadding,
    required this.isDragging,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // 移除背景遮罩绘制，避免与底图 StrokePreviewPainter 遮罩重复叠加导致颜色不一致

    final borderPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.85)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;
    canvas.drawRect(rect, borderPaint);

    // 绘制九宫格构图线
    if (isDragging) {
      final gridPaint = Paint()
        ..color = Colors.white.withValues(alpha: 0.35)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.0;

      // 垂直分割线
      final double thirdW = rect.width / 3;
      canvas.drawLine(
        Offset(rect.left + thirdW, rect.top),
        Offset(rect.left + thirdW, rect.bottom),
        gridPaint,
      );
      canvas.drawLine(
        Offset(rect.left + thirdW * 2, rect.top),
        Offset(rect.left + thirdW * 2, rect.bottom),
        gridPaint,
      );

      // 水平分割线
      final double thirdH = rect.height / 3;
      canvas.drawLine(
        Offset(rect.left, rect.top + thirdH),
        Offset(rect.right, rect.top + thirdH),
        gridPaint,
      );
      canvas.drawLine(
        Offset(rect.left, rect.top + thirdH * 2),
        Offset(rect.right, rect.top + thirdH * 2),
        gridPaint,
      );
    }

    final handlePaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0
      ..strokeCap = StrokeCap.round;

    const double len = 16.0;

    canvas.drawPath(
      Path()
        ..moveTo(rect.left, rect.top + len)
        ..lineTo(rect.left, rect.top)
        ..lineTo(rect.left + len, rect.top),
      handlePaint,
    );
    canvas.drawPath(
      Path()
        ..moveTo(rect.right - len, rect.top)
        ..lineTo(rect.right, rect.top)
        ..lineTo(rect.right, rect.top + len),
      handlePaint,
    );
    canvas.drawPath(
      Path()
        ..moveTo(rect.left, rect.bottom - len)
        ..lineTo(rect.left, rect.bottom)
        ..lineTo(rect.left + len, rect.bottom),
      handlePaint,
    );
    canvas.drawPath(
      Path()
        ..moveTo(rect.right - len, rect.bottom)
        ..lineTo(rect.right, rect.bottom)
        ..lineTo(rect.right, rect.bottom - len),
      handlePaint,
    );

    const double sideLen = 14.0;
    final topMid = Offset(rect.left + rect.width / 2, rect.top);
    canvas.drawLine(
      Offset(topMid.dx - sideLen / 2, topMid.dy),
      Offset(topMid.dx + sideLen / 2, topMid.dy),
      handlePaint,
    );
    final bottomMid = Offset(rect.left + rect.width / 2, rect.bottom);
    canvas.drawLine(
      Offset(bottomMid.dx - sideLen / 2, bottomMid.dy),
      Offset(bottomMid.dx + sideLen / 2, bottomMid.dy),
      handlePaint,
    );
    final leftMid = Offset(rect.left, rect.top + rect.height / 2);
    canvas.drawLine(
      Offset(leftMid.dx, leftMid.dy - sideLen / 2),
      Offset(leftMid.dx, leftMid.dy + sideLen / 2),
      handlePaint,
    );
    final rightMid = Offset(rect.right, rect.top + rect.height / 2);
    canvas.drawLine(
      Offset(rightMid.dx, rightMid.dy - sideLen / 2),
      Offset(rightMid.dx, rightMid.dy + sideLen / 2),
      handlePaint,
    );
  }

  @override
  bool shouldRepaint(covariant CropOverlayPainter oldDelegate) {
    return oldDelegate.rect != rect ||
        oldDelegate.edgePadding != edgePadding ||
        oldDelegate.isDragging != isDragging;
  }
}
