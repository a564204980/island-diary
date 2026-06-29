import 'package:flutter/material.dart';

class LegoCellClipper extends CustomClipper<Path> {
  final bool hasSockets;
  final double progress;
  LegoCellClipper({required this.hasSockets, this.progress = 1.0});

  @override
  Path getClip(Size size) {
    final path = Path();
    final w = size.width;
    final h = size.height;
    final r = 10.0;

    if (!hasSockets) {
      path.addRRect(RRect.fromRectAndRadius(
        Rect.fromLTWH(0, 0, w, h),
        Radius.circular(r),
      ));
      return path;
    }

    // Top-left corner to top-right corner
    path.moveTo(r, 0);
    path.lineTo(w - r, 0);
    path.arcToPoint(Offset(w, r), radius: Radius.circular(r));
    
    // Right edge to bottom-right corner
    path.lineTo(w, h - r);
    path.arcToPoint(Offset(w - r, h), radius: Radius.circular(r));
    
    // Bottom edge with two sockets (aligned with top studs)
    final socketW = 7.0;
    final socketH = 3.5 * progress;
    final centerX = w / 2;
    final studLeftCenter = centerX - 6.5;
    final studRightCenter = centerX + 6.5;
    
    final socketLeft1 = studLeftCenter - socketW / 2;
    final socketLeft2 = studRightCenter - socketW / 2;

    path.lineTo(socketLeft2 + socketW, h);
    path.lineTo(socketLeft2 + socketW, h - socketH);
    path.lineTo(socketLeft2, h - socketH);
    path.lineTo(socketLeft2, h);

    path.lineTo(socketLeft1 + socketW, h);
    path.lineTo(socketLeft1 + socketW, h - socketH);
    path.lineTo(socketLeft1, h - socketH);
    path.lineTo(socketLeft1, h);
    
    // Bottom-left corner to top-left corner
    path.lineTo(r, h);
    path.arcToPoint(Offset(0, h - r), radius: Radius.circular(r));
    path.lineTo(0, r);
    path.arcToPoint(Offset(r, 0), radius: Radius.circular(r));
    
    path.close();
    return path;
  }

  @override
  bool shouldReclip(covariant LegoCellClipper oldClipper) =>
      oldClipper.hasSockets != hasSockets || oldClipper.progress != progress;
}

class LegoBorderPainter extends CustomPainter {
  final bool hasSockets;
  final double progress;
  final Color borderColor;
  final double borderWidth;

  LegoBorderPainter({
    required this.hasSockets,
    this.progress = 1.0,
    required this.borderColor,
    required this.borderWidth,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = borderColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = borderWidth
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final w = size.width;
    final h = size.height;
    final r = 10.0;

    final path = Path();

    if (!hasSockets) {
      final rrect = RRect.fromRectAndRadius(
        Rect.fromLTWH(borderWidth / 2, borderWidth / 2, w - borderWidth, h - borderWidth),
        Radius.circular(r - borderWidth / 2),
      );
      path.addRRect(rrect);
      canvas.drawPath(path, paint);
      return;
    }

    path.moveTo(r, 0);
    path.lineTo(w - r, 0);
    path.arcToPoint(Offset(w, r), radius: Radius.circular(r));
    
    path.lineTo(w, h - r);
    path.arcToPoint(Offset(w - r, h), radius: Radius.circular(r));
    
    // Bottom edge with sockets
    final socketW = 7.0;
    final socketH = 3.5 * progress;
    final centerX = w / 2;
    final studLeftCenter = centerX - 6.5;
    final studRightCenter = centerX + 6.5;
    
    final socketLeft1 = studLeftCenter - socketW / 2;
    final socketLeft2 = studRightCenter - socketW / 2;

    path.lineTo(socketLeft2 + socketW, h);
    path.lineTo(socketLeft2 + socketW, h - socketH);
    path.lineTo(socketLeft2, h - socketH);
    path.lineTo(socketLeft2, h);

    path.lineTo(socketLeft1 + socketW, h);
    path.lineTo(socketLeft1 + socketW, h - socketH);
    path.lineTo(socketLeft1, h - socketH);
    path.lineTo(socketLeft1, h);
    
    path.lineTo(r, h);
    path.arcToPoint(Offset(0, h - r), radius: Radius.circular(r));
    path.lineTo(0, r);
    path.arcToPoint(Offset(r, 0), radius: Radius.circular(r));
    
    path.close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant LegoBorderPainter oldDelegate) {
    return oldDelegate.hasSockets != hasSockets ||
        oldDelegate.progress != progress ||
        oldDelegate.borderColor != borderColor ||
        oldDelegate.borderWidth != borderWidth;
  }
}
