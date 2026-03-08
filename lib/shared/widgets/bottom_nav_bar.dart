import 'dart:math';
import 'package:flutter/material.dart';
import 'package:island_diary/shared/widgets/sprite_animation.dart';
import 'package:island_diary/shared/widgets/mood_picker.dart';

/// 将底栏裁剪为带圆角矩形 + 中心顶凹口的形状（使用严格几何相切圆，完美贴合）
class _NavBarClipper extends CustomClipper<Path> {
  final double notchRadius;
  final double barRadius;

  const _NavBarClipper({required this.notchRadius, required this.barRadius});

  @override
  Path getClip(Size size) {
    final path = Path();
    final width = size.width;
    final height = size.height;
    final cx = width / 2;

    // 1. 核心参数设置
    const notchMargin = 6.0; // 凹口与悬浮按钮的间距
    final r = notchRadius + notchMargin; // 凹口主圆的半径
    const rs = 16.0; // 裙边过渡圆角的半径（数值越大，过渡越平缓）

    // 2. 几何相切计算 (计算直线、裙边圆、凹口主圆的精确交点)
    final d = r + rs; // 两圆心的距离
    final dx = sqrt(d * d - rs * rs); // 裙边圆心距离中心 cx 的水平距离

    // 两个圆的相切交点坐标偏移量
    final tangentOffsetX = dx * (r / d);
    final tangentY = rs * (r / d);

    // 裙边圆的 X 坐标
    final leftShoulderX = cx - dx;
    final rightShoulderX = cx + dx;

    // ── 开始绘制路径 ──

    // 左上大圆角起点
    path.moveTo(barRadius, 0);

    // 画顶部的平直横线，直到左侧裙边圆的起点
    path.lineTo(leftShoulderX, 0);

    // 🌟 第一段：左侧裙边（向下向内凹的圆弧）
    path.arcToPoint(
      Offset(cx - tangentOffsetX, tangentY),
      radius: const Radius.circular(rs),
      clockwise: true, // 顺时针，向内挤压形成裙边
    );

    // 🌟 第二段：主凹口（完美的正圆弧，绝对贴合你的悬浮球）
    path.arcToPoint(
      Offset(cx + tangentOffsetX, tangentY),
      radius: Radius.circular(r),
      clockwise: false, // 逆时针，形成向上的托盘缺口
    );

    // 🌟 第三段：右侧裙边（向上向外的圆弧，回到平直线）
    path.arcToPoint(
      Offset(rightShoulderX, 0),
      radius: const Radius.circular(rs),
      clockwise: true, // 顺时针，回到顶部
    );

    // 画顶部的平直横线，直到右侧大圆角起点
    path.lineTo(width - barRadius, 0);

    // ── 绘制底栏外部的四个大圆角 ──

    // 右上大圆角
    path.arcToPoint(
      Offset(width, barRadius),
      radius: Radius.circular(barRadius),
    );

    // 右边界和右下大圆角
    path.lineTo(width, height - barRadius);
    path.arcToPoint(
      Offset(width - barRadius, height),
      radius: Radius.circular(barRadius),
    );

    // 底边界和左下大圆角
    path.lineTo(barRadius, height);
    path.arcToPoint(
      Offset(0, height - barRadius),
      radius: Radius.circular(barRadius),
    );

    // 左边界和左上大圆角
    path.lineTo(0, barRadius);
    path.arcToPoint(Offset(barRadius, 0), radius: Radius.circular(barRadius));

    path.close();
    return path;
  }

  @override
  bool shouldReclip(covariant _NavBarClipper oldClipper) =>
      oldClipper.notchRadius != notchRadius ||
      oldClipper.barRadius != barRadius;
}

class BottomNavBar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;

  static const double centerButtonRadius = 32.0;

  const BottomNavBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    const double barHeight = 54;
    const double notchRadius = centerButtonRadius;

    return SizedBox(
      height: barHeight + notchRadius,
      child: Stack(
        alignment: Alignment.bottomCenter,
        clipBehavior: Clip.none,
        children: [
          // ── 底栏主体：阴影 + 裁剪图片 ──
          Positioned(
            bottom: 0,
            left: 26,
            right: 26,
            child: Container(
              // 外层容器负责提供顺着 Clipper 形状的阴影
              decoration: BoxDecoration(
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.18),
                    blurRadius: 16,
                    spreadRadius: 0,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              // 内部用 ClipPath 精确裁切出完美相切的凹口和胶囊圆角
              child: ClipPath(
                clipper: const _NavBarClipper(
                  notchRadius: notchRadius,
                  barRadius: 27, // 👈 高度 54 的一半，确保两端是完美的半圆形
                ),
                child: Container(
                  height: barHeight,
                  decoration: BoxDecoration(
                    image: DecorationImage(
                      image: const AssetImage('assets/images/navbar.png'),
                      fit: BoxFit.cover,
                      alignment: Alignment.center,
                      opacity: 0.7, // 降低图片本身的透明度，融入背后的波光湖面
                      colorFilter: ColorFilter.mode(
                        Colors.white.withOpacity(0.25),
                        BlendMode.lighten,
                      ),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _NavItem(
                        assetPath: 'assets/images/icons/ic_home.png',
                        label: '首页',
                        index: 0,
                        currentIndex: currentIndex,
                        onTap: onTap,
                      ),
                      _NavItem(
                        assetPath: 'assets/images/icons/ic_write.png',
                        label: '记录',
                        index: 1,
                        currentIndex: currentIndex,
                        onTap: onTap,
                      ),
                      const SizedBox(width: 60), // 中心凹口占位
                      _NavItem(
                        assetPath: 'assets/images/icons/ic_journal.png',
                        label: '相册',
                        index: 3,
                        currentIndex: currentIndex,
                        onTap: onTap,
                      ),
                      _NavItem(
                        assetPath:
                            'assets/images/icons/ic_stting.png', // 以用户实际文件名拼写为准
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
          ),

          // ── 中心凸出精灵按钮 ──
          Positioned(
            top: 0,
            child: GestureDetector(
              onTap: () {
                showGeneralDialog(
                  context: context,
                  barrierDismissible: true,
                  barrierLabel: 'MoodPicker',
                  barrierColor: Colors.transparent,
                  transitionDuration: const Duration(milliseconds: 300),
                  pageBuilder: (context, anim1, anim2) {
                    return const MoodPickerSheet();
                  },
                );
              },
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
                  // 挂载动态精灵图：预设为 12 帧，如果实际序列图不是 12 帧或速度不对可以直接修改这两个参数！
                  child: SpriteAnimation(
                    assetPath: 'assets/images/emoji/weixiao.png',
                    frameCount: 9, // 通常微表情贴图可能有 8-15 帧
                    duration: Duration(milliseconds: 800), // 一个微笑动画周期 1.5 秒
                    size: 44.0, // 根据圆圈大小设定动图尺寸
                  ),
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
  final String assetPath;
  final String label;
  final int index;
  final int currentIndex;
  final ValueChanged<int> onTap;

  const _NavItem({
    required this.assetPath,
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
            // 完全保留图标原始的透明度与色彩，不再通过程序降低透明度
            Image.asset(
              assetPath,
              width: isSelected ? 28.0 : 24.0, // 稍微加大尺寸，弥补丢失的透明度区分
              height: isSelected ? 28.0 : 24.0,
              fit: BoxFit.contain,
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                color: isSelected
                    ? const Color(0xFF7B5C2E)
                    : const Color(0xFF8B7763), // 稍微加深未选中的文字颜色，提升阅读清晰度
              ),
            ),
          ],
        ),
      ),
    );
  }
}
