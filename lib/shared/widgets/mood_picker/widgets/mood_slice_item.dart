import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../models/mood_item.dart';

/// 渲染一个单独的心情切片部件，包含背景图片、外发光、内发光边缘、文字和小图标。
/// 处理自身的坐标偏移和复杂的动画层级叠加。 (方案 A+: 分层异步弹性反馈)
class MoodSliceItem extends StatelessWidget {
  final MoodItem item;
  final bool isSelected;
  final double baseWheelSize;

  const MoodSliceItem({
    super.key,
    required this.item,
    required this.isSelected,
    required this.baseWheelSize,
  });

  // 构建一个包含外围阴影发光的辅助图层组件，通过 8 个圆周方向偏移生成等厚度的外轮廓
  Widget _buildGlowLayer({
    required Widget child,
    required Color color,
    required double strokeWidth,
    double blurRadius = 0,
  }) {
    Widget coloredImage = ColorFiltered(
      colorFilter: ColorFilter.mode(color, BlendMode.srcIn),
      child: child,
    );

    if (blurRadius > 0) {
      coloredImage = ImageFiltered(
        imageFilter: ui.ImageFilter.blur(
          sigmaX: blurRadius,
          sigmaY: blurRadius,
        ),
        child: coloredImage,
      );
    }

    return Stack(
      alignment: Alignment.center,
      children: [
        for (double angle = 0; angle < 2 * math.pi; angle += math.pi / 4)
          Transform.translate(
            offset: Offset(
              math.cos(angle) * strokeWidth,
              math.sin(angle) * strokeWidth,
            ),
            child: coloredImage,
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    // 动画配置：向外移动的距离
    const double moveOutOffset = 12.0; // 减少位移量，避免太夸张

    // 计算中心外的移动向量 (无论是否选中都进行预计算)
    double angleRad;
    if (item.popAngle != null) {
      // 优先使用手动校准的弹出角度
      angleRad = item.popAngle! * math.pi / 180;
    } else if (item.iconOffset != null) {
      // 回退到基于图标位置的自动计算
      angleRad = (item.iconOffset!.dy == 0 && item.iconOffset!.dx == 0)
          ? 0
          : ui.Offset(item.iconOffset!.dx, item.iconOffset!.dy).direction;
    } else {
      angleRad = 0;
    }

    final Offset translationOffset = Offset(
      moveOutOffset * ui.Offset.fromDirection(angleRad).dx,
      moveOutOffset * ui.Offset.fromDirection(angleRad).dy,
    );

    return SizedBox(
      width: baseWheelSize,
      height: baseWheelSize,
      child:
          Stack(
                alignment: Alignment.center,
                clipBehavior: Clip.none,
                children: [
                  // ── A+ Max 方案：全局居中平移与轴向缩放保证 ──

                  // 1. 底层切片层图片 (实施挤压与伸展反馈)
                  if (item.imagePath != null)
                    Transform.rotate(
                      angle: item.angle * math.pi / 180,
                      child: Stack(
                        alignment: Alignment.center,
                        clipBehavior: Clip.none,
                        children: [
                          Positioned(
                            bottom: (baseWheelSize / 2) + (item.imageTop ?? 0),
                            left: item.imageLeft,
                            right: 0,
                            child: Transform.rotate(
                              angle: (item.imageRotation ?? 0) * math.pi / 180,
                              child: Transform.scale(
                                scale: item.scale ?? 1.0,
                                alignment: Alignment.bottomCenter,
                                child: Stack(
                                  alignment: Alignment.bottomCenter,
                                  children: [
                                    // 1. 发光层 (核心优化：仅在选中时渲染这些昂贵的滤镜图层)
                                    if (isSelected) ...[
                                      _buildGlowLayer(
                                            child: Image.asset(
                                              item.imagePath!,
                                              width: item.width,
                                              height: item.height,
                                              fit:
                                                  (item.width != null ||
                                                      item.height != null)
                                                  ? BoxFit.contain
                                                  : BoxFit.none,
                                              alignment: Alignment.bottomCenter,
                                            ),
                                            color: item.glowColor ?? Colors.white,
                                            strokeWidth: 6.0,
                                            blurRadius: 8.0,
                                          )
                                          .animate()
                                          .fade(
                                            duration: 300.ms,
                                            curve: Curves.easeOut,
                                          ),

                                      _buildGlowLayer(
                                            child: Image.asset(
                                              item.imagePath!,
                                              width: item.width,
                                              height: item.height,
                                              fit:
                                                  (item.width != null ||
                                                      item.height != null)
                                                  ? BoxFit.contain
                                                  : BoxFit.none,
                                              alignment: Alignment.bottomCenter,
                                            ),
                                            color: Colors.white,
                                            strokeWidth: 6.0,
                                          )
                                          .animate()
                                          .fade(
                                            duration: 300.ms,
                                            curve: Curves.easeOut,
                                          ),
                                    ],

                                    // 2. 原图
                                    Image.asset(
                                      item.imagePath!,
                                      width: item.width,
                                      height: item.height,
                                      fit:
                                          (item.width != null ||
                                              item.height != null)
                                          ? BoxFit.contain
                                          : BoxFit.none,
                                      alignment: Alignment.bottomCenter,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                  // 2. 中心图标层 (实施延时回弹弹出 + 悬浮 Idle)
                  if (item.iconPath != null)
                    Center(
                          child: Transform.translate(
                            offset: item.iconOffset ?? Offset.zero,
                            child: Transform.rotate(
                              angle: (item.iconRotation ?? 0) * math.pi / 180,
                              child: Image.asset(
                                item.iconPath!,
                                width: item.iconSize ?? 40,
                                height: item.iconSize ?? 40,
                                fit: BoxFit.contain,
                              ),
                            ),
                          ),
                        )
                        .animate(target: isSelected ? 1 : 0)
                        .scale(
                          delay: 0.ms, // 极致优化：移除延迟
                          duration: isSelected ? 300.ms : 200.ms, // 压缩时长
                          curve: isSelected
                              ? Curves.easeOutBack // 更直接的曲线，减少震荡时间
                              : Curves.easeOutCubic,
                          begin: const Offset(1, 1),
                          end: const Offset(1.15, 1.15),
                        )
                        .animate(
                          onPlay: (controller) =>
                              controller.repeat(reverse: true),
                        )
                        // 图标 Idle: 极小幅度的 Y 轴浮动 (仅在选中时生效)
                        .moveY(
                          begin: 0,
                          end: isSelected ? 2 : 0,
                          duration: 1200.ms,
                          curve: Curves.easeInOutSine,
                        ),

                  // 3. 标签文字层 (淡入 + 异步呼吸)
                  if (item.label.isNotEmpty)
                    Center(
                          child: Transform.translate(
                            offset: item.textOffset ?? Offset.zero,
                            child: Transform.rotate(
                              angle: (item.textRotation ?? 0) * math.pi / 180,
                              child: Text(
                                item.label,
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: const Color(0xFF4A3424),
                                  fontSize: item.fontSize ?? 16,
                                  fontWeight: FontWeight.w600,
                                  height: 1.0,
                                ),
                              ),
                            ),
                          ),
                        )
                        .animate(target: isSelected ? 1 : 0)
                        .scale(
                          delay: 0.ms, // 极致优化：移除延迟
                          duration: isSelected ? 250.ms : 200.ms, // 压缩时长
                          curve: isSelected
                              ? Curves.easeOutBack
                              : Curves.easeOut,
                          begin: const Offset(0.9, 0.9),
                          end: const Offset(1.05, 1.05),
                        )
                        .animate(
                          onPlay: (controller) =>
                              controller.repeat(reverse: true),
                        )
                        // 文字 Idle 呼吸感
                        .fade(
                          begin: 1.0,
                          end: isSelected ? 0.7 : 1.0,
                          duration: 1500.ms,
                          curve: Curves.easeInOutSine,
                        ),
                ],
              )
              .animate(target: isSelected ? 1 : 0)
              // 1. 全局平移：向外弹出
              .move(
                duration: isSelected ? 250.ms : 200.ms, // 极速弹出
                curve: isSelected ? Curves.easeOutBack : Curves.easeOutQuart,
                begin: Offset.zero,
                end: translationOffset,
              )
              // 2. 全局等分缩放
              .scale(
                duration: isSelected ? 300.ms : 200.ms, // 极速缩放
                curve: isSelected ? Curves.easeOutCubic : Curves.easeOut, // 弃用 elasticOut
                begin: const Offset(1, 1),
                end: const Offset(1.05, 1.05),
                alignment: Alignment.center,
              ),
    );
  }
}
