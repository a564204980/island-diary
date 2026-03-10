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
    const double moveOutOffset = 20.0; // 增强位移感

    // 计算中心外的移动向量 (支持通过 popAngle 进行手动中轴校准)
    Offset translationOffset = Offset.zero;
    if (isSelected) {
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

      translationOffset = Offset(
        moveOutOffset * ui.Offset.fromDirection(angleRad).dx,
        moveOutOffset * ui.Offset.fromDirection(angleRad).dy,
      );
    }

    return SizedBox(
          width: baseWheelSize,
          height: baseWheelSize,
          child: Stack(
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
                                // 1. 发光层
                                if (isSelected)
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
                                  ),
                                if (isSelected)
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
                                  ),
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
                      delay: isSelected ? 80.ms : 0.ms, // 收缩时不设延迟
                      duration: isSelected ? 800.ms : 350.ms,
                      curve: isSelected
                          ? Curves.elasticOut
                          : Curves.easeOutCubic,
                      begin: const Offset(1, 1),
                      end: const Offset(1.2, 1.2), // 选中后图标变大一点
                    )
                    .animate(
                      onPlay: (controller) => isSelected
                          ? controller.repeat(reverse: true)
                          : controller.stop(),
                    )
                    // 图标 Idle: 极小幅度的 Y 轴浮动
                    .moveY(
                      begin: -2,
                      end: 2,
                      duration: 2000.ms,
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
                      delay: isSelected ? 150.ms : 0.ms,
                      duration: isSelected ? 400.ms : 300.ms,
                      curve: isSelected ? Curves.easeOutBack : Curves.easeOut,
                      begin: const Offset(0.9, 0.9),
                      end: const Offset(1.05, 1.05),
                    )
                    .animate(
                      onPlay: (controller) => isSelected
                          ? controller.repeat(reverse: true)
                          : controller.stop(),
                    )
                    // 文字 Idle: 呼吸感淡入淡出 (频率与图标错开，增加自然感)
                    .fade(
                      begin: 1.0,
                      end: 0.6,
                      duration: 1800.ms,
                      curve: Curves.easeInOutSine,
                    ),
            ],
          ),
        )
        .animate(target: isSelected ? 1 : 0)
        // 1. 全局平移：向外弹出
        .move(
          duration: isSelected ? 500.ms : 350.ms,
          curve: isSelected ? Curves.easeOutBack : Curves.easeOutCubic,
          begin: Offset.zero,
          end: translationOffset,
        )
        // 2. 全局等分缩放：中心永远对齐圆盘轴心
        .scale(
          duration: isSelected ? 700.ms : 350.ms,
          curve: isSelected ? Curves.elasticOut : Curves.easeOut,
          begin: const Offset(1, 1),
          end: const Offset(1.08, 1.08),
          alignment: Alignment.center,
        );
  }
}
