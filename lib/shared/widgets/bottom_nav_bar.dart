import 'dart:math';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:island_diary/shared/widgets/sprite_animation.dart';
import 'package:island_diary/shared/widgets/mood_picker/mood_picker_sheet.dart';

class BottomNavBar extends StatefulWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;
  final bool isNight;

  const BottomNavBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
    this.isNight = false,
  });

  @override
  State<BottomNavBar> createState() => _BottomNavBarState();
}

const double centerButtonRadius = 32.0; // 遵循相切圆方案比例：下调至 32.0，更精致紧凑

class _BottomNavBarState extends State<BottomNavBar> {
  @override
  Widget build(BuildContext context) {
    const double barHeight = 76;
    const double notchRadius = 52.0; // 怀抱式设计：凹口半径 (52) 大于按钮半径 (36)，形成包裹感
    final bool isNight = widget.isNight;

    return SizedBox(
      height: barHeight + notchRadius + 16, // 扩容高度以支持更大的悬浮间隙
      child: Stack(
        alignment: Alignment.bottomCenter,
        clipBehavior: Clip.none,
        children: [
          // ── 底栏主体：阴影 + 裁剪 + 磨砂 + 渐变边框 ──
          Positioned(
            bottom: 0,
            left: 24,
            right: 24,
            child: Container(
              decoration: BoxDecoration(
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.18),
                    blurRadius: 20,
                    spreadRadius: 1,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Stack(
                children: [
                  // 1. 裁剪背板（含磨砂特效）
                  ClipPath(
                    clipper: const _NavBarClipper(
                      notchRadius: notchRadius,
                      barRadius: 38,
                    ),
                    child: Container(
                      height: barHeight,
                      child: Stack(
                        children: [
                          Positioned.fill(
                            child: BackdropFilter(
                              filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
                              child: Container(
                                decoration: BoxDecoration(
                                  color: isNight
                                      ? const Color(0xFF736675).withOpacity(
                                          0.2,
                                        ) // 回归灰紫色
                                      : Colors.white.withOpacity(0.4),
                                ),
                              ),
                            ),
                          ),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [
                              _buildNavItem(
                                0,
                                'assets/images/icons/ic_home.png',
                                '首页',
                              ),
                              _buildNavItem(
                                1,
                                'assets/images/icons/ic_write.png',
                                '记录',
                              ),
                              const SizedBox(width: 92),
                              _buildNavItem(
                                3,
                                'assets/images/icons/ic_journal.png',
                                '相册',
                              ),
                              _buildNavItem(
                                4,
                                'assets/images/icons/ic_stting.png',
                                '我',
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  // 2. 只有夜间模式才有的“夕阳到深海”渐变描边层
                  if (isNight)
                    Positioned.fill(
                      child: IgnorePointer(
                        // 核心修复：防止描边层拦截点击事件
                        child: CustomPaint(
                          painter: _NavBarGradientPainter(
                            clipper: const _NavBarClipper(
                              notchRadius: notchRadius,
                              barRadius: 38,
                            ),
                            strokeWidth: 2.5,
                            gradient: const LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                Color(0xFFEEBB3C), // 描边顶部换成金色
                                Color(0xFF1B2735), // 深海蓝
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),

          // ── 中心凸出精灵按钮 ──
          Positioned(
            top: 24, // 下移
            child: GestureDetector(
              onTap: () {
                showGeneralDialog(
                  context: context,
                  barrierDismissible: true,
                  barrierLabel: 'MoodPicker',
                  barrierColor: Colors.black.withOpacity(0.6),
                  transitionDuration: const Duration(milliseconds: 500),
                  transitionBuilder:
                      (context, animation, secondaryAnimation, child) {
                        final curvedAnimation = CurvedAnimation(
                          parent: animation,
                          curve: Curves.easeOutBack,
                        );
                        return Transform.scale(
                          scale: curvedAnimation.value,
                          alignment: const Alignment(0.0, 0.8),
                          child: FadeTransition(
                            opacity: animation,
                            child: child,
                          ),
                        );
                      },
                  pageBuilder: (context, anim1, anim2) =>
                      const MoodPickerSheet(),
                );
              },
              child: Stack(
                alignment: Alignment.center,
                clipBehavior: Clip.none,
                children: [
                  // 呼吸光晕
                  Container(
                        width: centerButtonRadius * 2 + 12,
                        height: centerButtonRadius * 2 + 12,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white.withOpacity(0.15),
                          border: Border.all(
                            color: Colors.white.withOpacity(0.8),
                            width: 1.5,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFFFFD97D).withOpacity(0.4),
                              blurRadius: 12,
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                      )
                      .animate(onPlay: (c) => c.repeat(reverse: true))
                      .scale(
                        begin: const Offset(1, 1),
                        end: const Offset(1.15, 1.15),
                        duration: 2500.ms,
                        curve: Curves.easeInOutSine,
                      )
                      .fade(
                        begin: 1,
                        end: 0.3,
                        duration: 2500.ms,
                        curve: Curves.easeInOutSine,
                      ),

                  // 精灵主体 (简洁设计)
                  Container(
                    width: centerButtonRadius * 2,
                    height: centerButtonRadius * 2,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isNight
                          ? const Color(0xFF2A2E50).withOpacity(
                              0.1,
                            ) // 透明度调为 0.1
                          : const Color(0xFFFFF0C0),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(
                            0xFFFFD97D,
                          ).withOpacity(0.8), // 恢复光感
                          blurRadius: 10,
                          spreadRadius: 2,
                        ),
                      ],
                      border: Border.all(
                        color: const Color(0xFFFFE4B5), // 恢复稳健边框
                        width: 2.5,
                      ),
                    ),
                    child: Center(
                      child: SpriteAnimation(
                        assetPath: 'assets/images/emoji/weixiao.png',
                        frameCount: 9,
                        duration: 800.ms,
                        size: 44.0, // 适配 32.0 半径：由 48 下调至 44
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavItem(int index, String assetPath, String label) {
    return Expanded(
      child: _NavItem(
        assetPath: assetPath,
        label: label,
        index: index,
        currentIndex: widget.currentIndex,
        onTap: widget.onTap,
        isNight: widget.isNight,
      ),
    );
  }
}

class _NavBarClipper extends CustomClipper<Path> {
  final double notchRadius;
  final double barRadius;

  const _NavBarClipper({required this.notchRadius, required this.barRadius});

  @override
  Path getClip(Size size) {
    final path = Path();
    final double w = size.width;
    final double h = size.height;
    final double cx = w / 2;

    path.moveTo(barRadius, 0);

    // ── 严格几何相切圆方案 (100% 数学无缝衔接) ──
    const double notchMargin = -8.0; // 凹口与悬浮按钮的间距
    final double r = notchRadius + notchMargin; // 凹口主圆半径
    const double rs = 16.0; // 裙边过渡圆角半径 (越大越平缓)

    // 几何相切计算
    final double d = r + rs; // 两圆心距离
    final double dx = sqrt(d * d - rs * rs); // 裙边圆心水平距离

    // 相切交点坐标偏移量
    final double tangentOffsetX = dx * (r / d);
    final double tangentY = rs * (r / d);

    // 裙边圆起点 X
    final double leftShoulderX = cx - dx;
    final double rightShoulderX = cx + dx;

    // 绘制路径
    path.lineTo(leftShoulderX, 0);

    // 🌟 第一段：左侧裙边 (顺时针，向内凹)
    path.arcToPoint(
      Offset(cx - tangentOffsetX, tangentY),
      radius: const Radius.circular(rs),
      clockwise: true,
    );

    // 🌟 第二段：主凹口 (逆时针，向上托盘)
    path.arcToPoint(
      Offset(cx + tangentOffsetX, tangentY),
      radius: Radius.circular(r),
      clockwise: false,
    );

    // 🌟 第三段：右侧裙边 (顺时针，回归直线)
    path.arcToPoint(
      Offset(rightShoulderX, 0),
      radius: const Radius.circular(rs),
      clockwise: true,
    );

    path.lineTo(w - barRadius, 0);
    path.quadraticBezierTo(w, 0, w, barRadius);
    path.lineTo(w, h - barRadius);
    path.quadraticBezierTo(w, h, w - barRadius, h);
    path.lineTo(barRadius, h);
    path.quadraticBezierTo(0, h, 0, h - barRadius);
    path.lineTo(0, barRadius);
    path.quadraticBezierTo(0, 0, barRadius, 0);

    return path;
  }

  @override
  bool shouldReclip(covariant _NavBarClipper oldClipper) =>
      oldClipper.notchRadius != notchRadius ||
      oldClipper.barRadius != barRadius;
}

class _NavBarGradientPainter extends CustomPainter {
  final CustomClipper<Path> clipper;
  final double strokeWidth;
  final Gradient gradient;

  _NavBarGradientPainter({
    required this.clipper,
    required this.strokeWidth,
    required this.gradient,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final path = clipper.getClip(size);
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..shader = gradient.createShader(Offset.zero & size);

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _NavBarGradientPainter oldDelegate) =>
      oldDelegate.strokeWidth != strokeWidth ||
      oldDelegate.gradient != gradient;
}

class _NavItem extends StatefulWidget {
  final String assetPath;
  final String label;
  final int index;
  final int currentIndex;
  final ValueChanged<int> onTap;
  final bool isNight;

  const _NavItem({
    required this.assetPath,
    required this.label,
    required this.index,
    required this.currentIndex,
    required this.onTap,
    this.isNight = false,
  });

  @override
  State<_NavItem> createState() => _NavItemState();
}

class _NavItemState extends State<_NavItem> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final isSelected = widget.currentIndex == widget.index;

    return GestureDetector(
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) {
        setState(() => _isPressed = false);
        widget.onTap(widget.index);
      },
      onTapCancel: () => setState(() => _isPressed = false),
      behavior: HitTestBehavior.opaque,
      child: AnimatedScale(
        scale: _isPressed ? 0.9 : 1.0,
        duration: const Duration(milliseconds: 100),
        curve: Curves.easeOutCubic,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(
                  widget.assetPath,
                  width: 40.0,
                  height: 40.0,
                  fit: BoxFit.contain,
                )
                .animate(target: isSelected ? 1 : 0)
                .scale(
                  begin: const Offset(0.8, 0.8),
                  end: const Offset(1.0, 1.0),
                  duration: 400.ms,
                  curve: Curves.easeOutBack,
                )
                .custom(
                  duration: 3000.ms,
                  builder: (context, value, child) {
                    if (!isSelected) return child;
                    final sineValue = sin(value * 2 * pi) * 0.015;
                    return Transform.scale(
                      scale: 1.0 + sineValue,
                      child: child,
                    );
                  },
                ),
            const SizedBox(height: 2),
            Text(
              widget.label,
              style: TextStyle(
                fontSize: 13.0,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                color: isSelected
                    ? (widget.isNight
                          ? const Color(0xFFFFEFA1)
                          : const Color(0xFF7B5C2E))
                    : (widget.isNight
                          ? const Color(0xFFB5B5C9)
                          : const Color(0xFF8B7763)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
