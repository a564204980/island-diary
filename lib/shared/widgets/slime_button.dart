import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:island_diary/shared/widgets/sprite_animation.dart';

/// 统一的精灵按钮组件，确保在任何地方（底栏、新手引导）都拥有绝对一致的几何尺寸和视觉表现。
/// 改为 StatefulWidget，使动画 Controller 常驻不因 rebuild 而重建，消除卡顿感。
class SlimeButton extends StatefulWidget {
  final bool isNight;
  final bool isGlowing;
  final VoidCallback? onTap;

  // SpriteAnimation 相关属性
  final String assetPath;
  final int frameCount;
  final int startFrame;
  final int? endFrame;
  final int? repeatCount;
  final Duration duration;
  final double spriteSize;
  final bool isPlaying;

  const SlimeButton({
    super.key,
    this.isNight = false,
    this.isGlowing = false,
    this.onTap,
    this.assetPath = 'assets/images/emoji/weixiao.png',
    this.frameCount = 9,
    this.startFrame = 0,
    this.endFrame,
    this.repeatCount,
    this.duration = const Duration(milliseconds: 800),
    this.spriteSize = 42.0,
    this.isPlaying = true,
  });

  static const double centerButtonRadius = 32.0;
  static const double containerHeight =
      450.0; // 【高度扩容】大幅增加高度以容纳高处的气泡，并提供充足的点击判定区
  static const double bottomOffset = 24.0; // 【统一海拔】精灵按钮相对于容器底部的偏移量

  @override
  State<SlimeButton> createState() => _SlimeButtonState();
}

class _SlimeButtonState extends State<SlimeButton> {
  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const double totalSize = SlimeButton.centerButtonRadius * 2 + 12;

    return GestureDetector(
      onTap: widget.onTap,
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: totalSize,
        height: totalSize,
        child: Stack(
          alignment: Alignment.center,
          clipBehavior: Clip.none,
          children: [
            // ── 1. 呼吸光晕 (独立组件，局部重绘) ──
            Positioned.fill(child: _BreathGlow(isGlowing: widget.isGlowing)),

            // ── 2. 精灵球背景容器 (视觉基座) ──
            RepaintBoundary(
              // 【性能优化】隔离该层的阴影与重绘影响
              child: Container(
                width: SlimeButton.centerButtonRadius * 2,
                height: SlimeButton.centerButtonRadius * 2,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: widget.isNight
                      ? const Color(0xFF2A2E50).withOpacity(0.1)
                      : const Color(0xFFFFF0C0),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFFFD97D).withOpacity(0.8),
                      blurRadius: 10,
                      spreadRadius: 2,
                    ),
                  ],
                  border: Border.all(
                    color: const Color(0xFFFFE4B5),
                    width: 2.5,
                  ),
                ),
                child: Center(
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 500),
                    transitionBuilder:
                        (Widget child, Animation<double> animation) {
                          return FadeTransition(
                            opacity: animation,
                            child: child,
                          );
                        },
                    child: SpriteAnimation(
                      key: ValueKey(widget.assetPath), // 核心：资源路径变化触发动画
                      assetPath: widget.assetPath,
                      frameCount: widget.frameCount,
                      startFrame: widget.startFrame,
                      endFrame: widget.endFrame,
                      repeatCount: widget.repeatCount,
                      duration: widget.duration,
                      size: widget.spriteSize,
                      isPlaying: widget.isPlaying,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 独立的呼吸光晕组件，防止高频动画导致父组件（精灵按钮甚至底栏）全量重画
class _BreathGlow extends StatefulWidget {
  final bool isGlowing;
  const _BreathGlow({required this.isGlowing});

  @override
  State<_BreathGlow> createState() => _BreathGlowState();
}

class _BreathGlowState extends State<_BreathGlow>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnim;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2500),
    )..repeat(reverse: true);

    _scaleAnim = Tween<double>(begin: 1.0, end: 1.15).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOutSine),
    );
    _fadeAnim = Tween<double>(begin: 1.0, end: 0.3).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOutSine),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: AnimatedOpacity(
        opacity: widget.isGlowing ? 1.0 : 0.0,
        duration: 1500.ms,
        curve: Curves.easeInOutSine,
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            return Transform.scale(
              scale: _scaleAnim.value,
              // 使用 FadeTransition 代替 Opacity 以获得更好的性能
              child: FadeTransition(opacity: _fadeAnim, child: child),
            );
          },
          child: RepaintBoundary(
            child: Container(
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
            ),
          ),
        ),
      ),
    );
  }
}
