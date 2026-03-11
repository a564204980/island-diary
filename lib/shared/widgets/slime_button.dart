import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:island_diary/shared/widgets/sprite_animation.dart';

/// 统一的精灵按钮组件，确保在任何地方（底栏、新手引导）都拥有绝对一致的几何尺寸和视觉表现。
class SlimeButton extends StatelessWidget {
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
    this.spriteSize = 44.0,
  });

  static const double centerButtonRadius = 32.0;

  @override
  Widget build(BuildContext context) {
    // 【核心设计】强制设定固定尺寸 76x76 (基准半径 32*2 + 呼吸边距 12)。
    // 无论内部的光晕(isGlowing)是否开启，该 Container 的占地面积永远不变。
    // 这解决了因“光晕改变容器大小”导致的 top 定位偏移问题。
    const double totalSize = centerButtonRadius * 2 + 12;

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: totalSize,
        height: totalSize,
        child: Stack(
          alignment: Alignment.center,
          clipBehavior: Clip.none,
          children: [
            // ── 1. 呼吸光晕 (动态效果) ──
            // 当 isGlowing 为 true 时，显示白色半透明呼吸层。
            if (isGlowing)
              Container(
                    width: totalSize,
                    height: totalSize,
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
                    begin: 1.0,
                    end: 0.3,
                    duration: 2500.ms,
                    curve: Curves.easeInOutSine,
                  ),

            // ── 2. 精灵球背景容器 (视觉基座) ──
            // 遵循图 2 的磨砂圆框设计，提供稳定的视觉焦点。
            Container(
              width: centerButtonRadius * 2,
              height: centerButtonRadius * 2,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isNight
                    ? const Color(0xFF2A2E50).withOpacity(0.1)
                    : const Color(0xFFFFF0C0),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFFFD97D).withOpacity(0.8),
                    blurRadius: 10,
                    spreadRadius: 2,
                  ),
                ],
                border: Border.all(color: const Color(0xFFFFE4B5), width: 2.5),
              ),
              child: Center(
                child: SpriteAnimation(
                  assetPath: assetPath,
                  frameCount: frameCount,
                  startFrame: startFrame,
                  endFrame: endFrame,
                  repeatCount: repeatCount,
                  duration: duration,
                  size: spriteSize,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
