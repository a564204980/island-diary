import 'package:flutter/material.dart';

/// 展板背景底纹枚举
enum WallTheme {
  dotGrid('🖊️ 手帐点阵', Color(0xFFE4DAD8), 'dot'),
  warmWood('🪵 温暖木纹', Color(0xFFF7F3E9), 'wood'),
  islandBlue('🌊 海岛水彩', Color(0xFFE0F2FE), 'blue'),
  darkPaper('🌙 暗夜深墨', Color(0xFF1E293B), 'dark');

  final String label;
  final Color bgColor;
  final String id;

  const WallTheme(this.label, this.bgColor, this.id);
}

enum WallLayoutMode {
  scatter('手帐散落'),
  treemap('无缝二叉树');

  final String label;
  const WallLayoutMode(this.label);
}

/// 手帐展板背景 Painter (绘制手帐点阵、木纹线等)
class WallBackgroundPainter extends CustomPainter {
  final WallTheme theme;

  WallBackgroundPainter({required this.theme});

  @override
  void paint(Canvas canvas, Size size) {
    if (theme == WallTheme.dotGrid) {
      final paint = Paint()
        ..color = const Color(0xFFB8AAA8) // 匹配 #E4DAD8 的高质感柔和点阵色
        ..strokeWidth = 1.2
        ..strokeCap = StrokeCap.round;

      const double step = 24.0;
      for (double x = 12; x < size.width; x += step) {
        for (double y = 12; y < size.height; y += step) {
          canvas.drawCircle(Offset(x, y), 0.85, paint);
        }
      }
    } else if (theme == WallTheme.warmWood) {
      final paint = Paint()
        ..color = const Color(0xFFE2D9C8).withValues(alpha: 0.4)
        ..strokeWidth = 1.0;

      for (double y = 0; y < size.height; y += 40.0) {
        canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant WallBackgroundPainter oldDelegate) {
    return oldDelegate.theme != theme;
  }
}
