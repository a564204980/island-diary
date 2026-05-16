import 'package:flutter/material.dart';

/// 首页专属的棋盘格背景组件
class IslandCheckerboardBackground extends StatelessWidget {
  final Color color1;
  final Color color2;
  final double cellSize;

  const IslandCheckerboardBackground({
    super.key,
    required this.color1,
    required this.color2,
    this.cellSize = 80.0, // 初始设定一个较大的格子尺寸，匹配首页视觉
  });

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: CustomPaint(
        painter: _IslandCheckerboardPainter(
          color1: color1,
          color2: color2,
          cellSize: cellSize,
        ),
      ),
    );
  }
}

class _IslandCheckerboardPainter extends CustomPainter {
  final Color color1;
  final Color color2;
  final double cellSize;

  _IslandCheckerboardPainter({
    required this.color1,
    required this.color2,
    required this.cellSize,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;
    
    // 遍历绘制整个屏幕区域
    for (double x = 0; x < size.width; x += cellSize) {
      for (double y = 0; y < size.height; y += cellSize) {
        // 计算当前格子的索引
        final int ix = (x / cellSize).floor();
        final int iy = (y / cellSize).floor();
        
        // 交替颜色逻辑
        paint.color = (ix + iy) % 2 == 0 ? color1 : color2;
        
        // 绘制矩形
        canvas.drawRect(
          Rect.fromLTWH(x, y, cellSize, cellSize),
          paint,
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant _IslandCheckerboardPainter oldDelegate) {
    return oldDelegate.color1 != color1 || 
           oldDelegate.color2 != color2 || 
           oldDelegate.cellSize != cellSize;
  }
}
