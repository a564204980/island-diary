import 'dart:math';
import 'package:flutter/material.dart';

/// 带中心圆弧凹口的底栏形状 Painter
class _NotchedBarPainter extends CustomPainter {
  final double notchRadius;
  final double barRadius;
  final Color color;

  _NotchedBarPainter({
    required this.notchRadius,
    required this.barRadius,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    const notchMargin = 6.0; // 凹口与按钮边缘留出的空隙
    final r = notchRadius + notchMargin;
    final cx = size.width / 2; // 凹口圆心 X
    const cy = 0.0; // 凹口圆心 Y（顶边）

    final path = Path();
    // 从左上角开始顺时针绘制
    final leftNotchStart = cx - sqrt(r * r - cy * cy);
    final rightNotchStart = cx + sqrt(r * r - cy * cy);

    path.moveTo(barRadius, 0);
    // 左半段顶边直线
    path.lineTo(leftNotchStart, 0);
    // 凹口弧线（顺时针绕过圆心，即 counterclockwise: false → 这里用负向弧）
    path.arcToPoint(
      Offset(rightNotchStart, 0),
      radius: Radius.circular(r),
      clockwise: false, // 向下凹
    );
    // 右半段顶边直线
    path.lineTo(size.width - barRadius, 0);
    // 右上角圆角
    path.arcToPoint(
      Offset(size.width, barRadius),
      radius: Radius.circular(barRadius),
    );
    // 右边竖线
    path.lineTo(size.width, size.height - barRadius);
    // 右下角圆角
    path.arcToPoint(
      Offset(size.width - barRadius, size.height),
      radius: Radius.circular(barRadius),
    );
    // 底边直线
    path.lineTo(barRadius, size.height);
    // 左下角圆角
    path.arcToPoint(
      Offset(0, size.height - barRadius),
      radius: Radius.circular(barRadius),
    );
    // 左边竖线
    path.lineTo(0, barRadius);
    // 左上角圆角
    path.arcToPoint(Offset(barRadius, 0), radius: Radius.circular(barRadius));

    path.close();

    // 绘制阴影
    canvas.drawShadow(path, Colors.black26, 8, false);
    // 绘制主体
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class BottomNavBar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;

  /// 中心精灵按钮的半径，与 HomePage 中凸出按钮保持一致
  static const double centerButtonRadius = 32.0;

  const BottomNavBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    const double barHeight = 70;
    const double notchRadius = centerButtonRadius;

    return SizedBox(
      // 整体高度 = 底栏高度 + 凸出的精灵按钮半身
      height: barHeight + notchRadius,
      child: Stack(
        alignment: Alignment.bottomCenter,
        clipBehavior: Clip.none,
        children: [
          // ── 胶囊底栏（带凹口）──
          Positioned(
            bottom: 0,
            left: 16,
            right: 16,
            child: CustomPaint(
              painter: _NotchedBarPainter(
                notchRadius: notchRadius,
                barRadius: 40,
                color: Colors.white.withOpacity(0.92),
              ),
              child: SizedBox(
                height: barHeight,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _NavItem(
                      icon: '🏔️',
                      label: '首页',
                      index: 0,
                      currentIndex: currentIndex,
                      onTap: onTap,
                    ),
                    _NavItem(
                      icon: '📓',
                      label: '记录',
                      index: 1,
                      currentIndex: currentIndex,
                      onTap: onTap,
                    ),
                    const SizedBox(width: 60), // 中心凹口占位
                    _NavItem(
                      icon: '📖',
                      label: '相册',
                      index: 3,
                      currentIndex: currentIndex,
                      onTap: onTap,
                    ),
                    _NavItem(
                      icon: '🌴',
                      label: '我',
                      index: 4,
                      currentIndex: currentIndex,
                      onTap: onTap,
                    ),
                  ],
                ),
              ),
            ),
          ),

          // ── 中心凸出精灵按钮 ──
          Positioned(
            top: 0,
            child: GestureDetector(
              onTap: () => onTap(2),
              child: Container(
                width: centerButtonRadius * 2,
                height: centerButtonRadius * 2,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFFFFF0C0),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFFFD97D).withOpacity(0.7),
                      blurRadius: 16,
                      spreadRadius: 4,
                    ),
                  ],
                  border: Border.all(color: Colors.white, width: 3),
                ),
                child: const Center(
                  child: Text('✨', style: TextStyle(fontSize: 26)),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final String icon;
  final String label;
  final int index;
  final int currentIndex;
  final ValueChanged<int> onTap;

  const _NavItem({
    required this.icon,
    required this.label,
    required this.index,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isSelected = currentIndex == index;
    return GestureDetector(
      onTap: () => onTap(index),
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: 60,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(icon, style: TextStyle(fontSize: isSelected ? 26 : 22)),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                color: isSelected
                    ? const Color(0xFF7B5C2E)
                    : Colors.grey.shade500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
