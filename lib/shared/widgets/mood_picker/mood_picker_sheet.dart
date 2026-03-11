import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import 'config/mood_config.dart';
import 'widgets/mood_slice_item.dart';
import 'widgets/mood_intensity_slider.dart';
import '../island_button.dart';

class MoodPickerSheet extends StatefulWidget {
  const MoodPickerSheet({super.key});

  @override
  State<MoodPickerSheet> createState() => _MoodPickerSheetState();
}

class _MoodPickerSheetState extends State<MoodPickerSheet> {
  int? _selectedIndex;
  double _intensity = 6.0; // 默认强度 6
  bool _isReady = false; // 延迟渲染标志

  @override
  void initState() {
    super.initState();
    // 【核心性能优化】延迟一帧渲染内部重度组件，彻底释放 showGeneralDialog 路由进场第一帧的 CPU 压力。
    // 这解决了弹出瞬间外层 SlimeButton 呼吸光晕被打断感的问题。
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) setState(() => _isReady = true);
    });
  }

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
        child: _isReady
            ? Center(
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
                            // 1. 底层白色背景 (带突出部)
                            RepaintBoundary(
                                  child: CustomPaint(
                                    size: const Size(320, 320),
                                    painter: MoodPickerBackgroundPainter(),
                                  ),
                                )
                                .animate()
                                .fade(duration: 400.ms)
                                .scale(
                                  duration: 500.ms,
                                  curve: Curves.easeOutBack,
                                ),

                            // 2. 心情选项层 (居中)
                            GestureDetector(
                              onTapUp: (details) {
                                _handleTap(
                                  details.localPosition,
                                  baseWheelSize,
                                );
                              },
                              child: Container(
                                width: baseWheelSize,
                                height: baseWheelSize,
                                color: Colors.transparent,
                                child: Stack(
                                  alignment: Alignment.center,
                                  clipBehavior: Clip.none,
                                  children: [
                                    Transform.translate(
                                      offset: const Offset(-5, -4),
                                      child: Stack(
                                        alignment: Alignment.center,
                                        clipBehavior: Clip.none,
                                        children: [
                                          ...List.generate(kMoods.length, (
                                            index,
                                          ) {
                                            return RepaintBoundary(
                                                  child: MoodSliceItem(
                                                    item: kMoods[index],
                                                    isSelected:
                                                        _selectedIndex == index,
                                                    baseWheelSize:
                                                        baseWheelSize,
                                                  ),
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

                            // 3. 右侧强度选择器 (叠加在中心并向右平移)
                            Transform.translate(
                              offset: const Offset(23, 0),
                              child:
                                  RepaintBoundary(
                                        child: MoodIntensitySlider(
                                          intensity: _intensity,
                                          onChanged: (val) =>
                                              setState(() => _intensity = val),
                                          radius: 130,
                                        ),
                                      )
                                      .animate()
                                      .fade(delay: 500.ms, duration: 600.ms)
                                      .scale(
                                        begin: const Offset(0.8, 0.8),
                                        duration: 600.ms,
                                        curve: Curves.easeOutBack,
                                      ),
                            ),

                            // 4. 中心基准小白点 (居中)
                            Container(
                              width: 10,
                              height: 10,
                              decoration: const BoxDecoration(
                                color: Colors.white,
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black26,
                                    blurRadius: 4,
                                  ),
                                ],
                              ),
                            ),

                            // 5. 底部确认按钮
                            Positioned(
                              bottom: -35, // 进一步向下偏移，视觉更平衡
                              child:
                                  IslandButton(
                                        text: '确认',
                                        width: 120,
                                        useHandDrawn:
                                            false, // 确认按钮保持简洁平滑，不使用手绘模式
                                        onTap: () {
                                          // TODO: 实现确认逻辑
                                          Navigator.pop(context);
                                        },
                                      )
                                      .animate()
                                      .fade(delay: 700.ms, duration: 500.ms)
                                      .scale(
                                        begin: const Offset(0.8, 0.8),
                                        duration: 550.ms,
                                        curve: Curves.easeOutBack,
                                      )
                                      .moveY(
                                        begin: 15,
                                        end: 0,
                                        duration: 600.ms,
                                      ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              )
            : const SizedBox.shrink(), // 第一帧用透明空壳占位
      ),
    );
  }
}

/// 自定义绘制带突起的背景
class MoodPickerBackgroundPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.38)
      ..style = PaintingStyle.fill;

    // ======= 发光重构：彻底抛弃软件计算的 MaskFilter.blur，改用硬件加速 API =======
    // (预留，由 drawShadow 接管)

    // ======= 终极重塑：圆角弧度版 (消除倾斜斜坡) =======
    final double r = radius;
    final double outerR = r + 20; // 突起高度 (保持 20)

    // 收窄过渡区间：从 36° 到 31° (仅 5 度差)，消除漫长斜度
    const double startA = 36 * math.pi / 180;
    const double endA = 31 * math.pi / 180;

    final path = Path();

    // 1. 主圆弧 (361度闭环，留出 36°x2 的开口)
    path.addArc(
      Rect.fromCircle(center: center, radius: r),
      startA,
      2 * math.pi - 2 * startA,
    );

    // 2. 顶部紧凑圆角 (Fillet)
    path.cubicTo(
      center.dx + (r + 4) * math.cos(-startA), // 极短控制点：引导切向
      center.dy + (r + 4) * math.sin(-startA),
      center.dx + outerR * math.cos(-startA), // 指向突起半径切向
      center.dy + outerR * math.sin(-startA),
      center.dx + outerR * math.cos(-endA), // 快速收回至突起外弧
      center.dy + outerR * math.sin(-endA),
    );

    // 3. 突起外边缘弧线 (与大圆绝对平行)
    path.arcTo(
      Rect.fromCircle(center: center, radius: outerR),
      -endA,
      2 * endA,
      false,
    );

    // 4. 底部紧凑圆角 (Fillet)
    path.cubicTo(
      center.dx + outerR * math.cos(startA), // 指向突起半径
      center.dy + outerR * math.sin(startA),
      center.dx + (r + 4) * math.cos(startA), // 极短控制点：对齐大圆
      center.dy + (r + 4) * math.sin(startA),
      center.dx + r * math.cos(startA), // 回到大圆
      center.dy + r * math.sin(startA),
    );

    path.close();

    // 填色与发光：通过底层引擎重度优化的 C++ 硬件阴影，瞬间解除主线程和 GPU 的百倍压力
    canvas.drawShadow(
      path,
      const Color.fromRGBO(213, 213, 213, 1),
      15.0, // 视觉高度 (物理映射模糊度)
      true,
    );
    canvas.drawShadow(path, const Color.fromRGBO(244, 214, 115, 1), 4.0, true);
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}
