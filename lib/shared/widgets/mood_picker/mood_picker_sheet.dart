import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import 'config/mood_config.dart';
import 'widgets/mood_slice_item.dart';

class MoodPickerSheet extends StatefulWidget {
  const MoodPickerSheet({super.key});

  @override
  State<MoodPickerSheet> createState() => _MoodPickerSheetState();
}

class _MoodPickerSheetState extends State<MoodPickerSheet> {
  int? _selectedIndex;

  void _handleTap(Offset localPosition, double baseWheelSize) {
    // 中心点就是宽度/高度的一半
    final double center = baseWheelSize / 2;
    final double dx = localPosition.dx - center;
    final double dy = localPosition.dy - center;
    final double distance = math.sqrt(dx * dx + dy * dy);

    // 如果点击实在太靠近中心（小白点区域）或者太靠外，忽略它
    if (distance < 20 || distance > baseWheelSize / 2) {
      if (_selectedIndex != null) {
        setState(() => _selectedIndex = null);
      }
      return;
    }

    // 以中心点为原点，计算手指触摸的角度 (-pi to pi)
    final double tapAngle = math.atan2(dy, dx);

    int? bestIndex;
    double minAngleDiff = double.infinity;

    for (int i = 0; i < kMoods.length; i++) {
      final item = kMoods[i];
      // 我们用对应图标的向量位置来代表该切片最准确的极座标分布方向
      final offset = item.iconOffset ?? Offset.zero;
      final itemAngle = math.atan2(offset.dy, offset.dx);

      double diff = (tapAngle - itemAngle).abs();
      // 将差值约束在 0 到 pi 之间，寻找最短几何夹角
      if (diff > math.pi) {
        diff = 2 * math.pi - diff;
      }

      if (diff < minAngleDiff) {
        minAngleDiff = diff;
        bestIndex = i;
      }
    }

    if (bestIndex != null) {
      setState(() {
        if (_selectedIndex == bestIndex) {
          _selectedIndex = null; // 再次点击取消高亮
        } else {
          _selectedIndex = bestIndex;
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // 获取当前屏幕的宽度，做响应式适配
    final screenWidth = MediaQuery.of(context).size.width;

    // 设定转盘占屏幕宽度的比例
    final displaySize = screenWidth * 1.0;

    // 微调各种偏移量的基准画布大小
    const double baseWheelSize = 400.0;

    return GestureDetector(
      onTap: () => Navigator.pop(context),
      behavior: HitTestBehavior.opaque,
      child: Material(
        color: Colors.transparent, // 背景由 barrierColor 控制，内部设为透明
        child: Center(
          child: GestureDetector(
            onTap: () {}, // 拦截点击事件，防止误触关闭
            // 外层的 SizedBox 决定最终在屏幕上显示的物理大小
            child: SizedBox(
              width: displaySize,
              height: displaySize,
              child: FittedBox(
                fit: BoxFit.cover,
                child: SizedBox(
                  width: baseWheelSize,
                  height: baseWheelSize,
                  child: Stack(
                    alignment: Alignment.center,
                    clipBehavior: Clip.none,
                    children: [
                      // 底层白色圆盘背景 (增加透明度，呈现磨砂质感)
                      Container(
                            width: 320,
                            height: 320,
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(
                                0.30,
                              ), // 稍微提亮一点核心白色底，显得通透
                              shape: BoxShape.circle,
                              boxShadow: [
                                // 第一层外围光：极大面积的暖色环境光晕
                                BoxShadow(
                                  color: const Color(
                                    0xFFFFE4B5,
                                  ).withOpacity(0.25), // 莫卡辛暖黄 (Moccasin) 环境光
                                  blurRadius: 60,
                                  spreadRadius: 15, // 增加扩散范围
                                ),
                                // 第二层内交界光：贴合白色底盘边缘的实体暖高光
                                BoxShadow(
                                  color: const Color(
                                    0xFFFFDAB9,
                                  ).withOpacity(0.45), // 桃色暖黄 (PeachPuff) 内圈发光
                                  blurRadius: 25,
                                  spreadRadius: 4, // 加强内侧金红色调
                                ),
                              ],
                            ),
                          )
                          .animate()
                          .fade(duration: 400.ms)
                          .scale(
                            duration: 500.ms,
                            curve: Curves.easeOutBack,
                          ), // 让白色底座带有呼吸感的淡出和轻微弹性缩放
                      // 全盘手势接管层区
                      GestureDetector(
                        onTapUp: (details) {
                          _handleTap(details.localPosition, baseWheelSize);
                        },
                        child: Container(
                          width: baseWheelSize,
                          height: baseWheelSize,
                          color: Colors.transparent, // 设置透明色拦截手指事件
                          child: Stack(
                            alignment: Alignment.center,
                            clipBehavior: Clip.none,
                            children: [
                              // 心情选项图标层 (因为原来的切片偏右下一点，所以全局往左上平移一点来纠正视觉居中)
                              Transform.translate(
                                offset: const Offset(-5, -4),
                                child: Stack(
                                  alignment: Alignment.center,
                                  clipBehavior: Clip.none,
                                  children: [
                                    // 渲染每个带动画的光效切片
                                    ...List.generate(kMoods.length, (index) {
                                      return MoodSliceItem(
                                            item: kMoods[index],
                                            isSelected: _selectedIndex == index,
                                            baseWheelSize: baseWheelSize,
                                          )
                                          .animate()
                                          .fade(
                                            delay: (index * 40).ms,
                                            duration: 300.ms,
                                          )
                                          .scale(
                                            delay: (index * 30).ms,
                                            duration: 500.ms,
                                            curve: Curves.easeOutBack,
                                            alignment: Alignment.center,
                                          );
                                    }),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      // 中心基准小白点
                      Container(
                        width: 10,
                        height: 10,
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(color: Colors.black26, blurRadius: 4),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
