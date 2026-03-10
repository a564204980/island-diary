import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import '../models/mood_item.dart';

/// 渲染一个单独的心情切片部件，包含背景图片、外发光、内发光边缘、文字和小图标。
/// 处理自身的坐标偏移和复杂的动画层级叠加。
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
    const double moveOutOffset = 15.0;

    // 计算中心外的移动向量
    Offset translationOffset = Offset.zero;
    if (isSelected && item.iconOffset != null) {
      final double angleRad =
          (item.iconOffset!.dy == 0 && item.iconOffset!.dx == 0)
          ? 0
          : ui.Offset(item.iconOffset!.dx, item.iconOffset!.dy).direction;
      translationOffset = Offset(
        moveOutOffset * ui.Offset.fromDirection(angleRad).dx,
        moveOutOffset * ui.Offset.fromDirection(angleRad).dy,
      );
    }

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOutBack,
      width: baseWheelSize,
      height: baseWheelSize,
      // 使用 Matrix4 来进行复杂的位移
      transform: Matrix4.translationValues(
        translationOffset.dx,
        translationOffset.dy,
        0,
      ),
      child: Stack(
        alignment: Alignment.center,
        clipBehavior: Clip.none,
        children: [
          // 渲染心情图片切片层及其发光效果
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
                            // 1. 最外层的柔和彩色发光
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
                            // 2. 内层的锐利白色描边
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
                            // 3. 原本的图片
                            Image.asset(
                              item.imagePath!,
                              width: item.width,
                              height: item.height,
                              fit: (item.width != null || item.height != null)
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

          // 独立渲染在切片上方的“图标”
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
            ),

          // 独立渲染在切片上方的“文字”
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
                      color: const Color(0xFF4A3424), // 深棕色字体
                      fontSize: item.fontSize ?? 16,
                      fontWeight: FontWeight.w600,
                      height: 1.0, // 去除默认行高间隙
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
