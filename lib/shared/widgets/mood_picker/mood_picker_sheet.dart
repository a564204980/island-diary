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
  int _shakeCount = 0; // 用于触发抖动动画的计数器
  bool _showBubble = false; // 是否显示提示气泡

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

    // 设定转盘占屏幕宽度的比例，大屏限制最大宽度
    final displaySize = screenWidth > 600 ? 500.0 : screenWidth;

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
                  behavior: HitTestBehavior.opaque, // 显式声明不透明，确保拦截生效
                  // 外层的 SizedBox 决定最终在屏幕上显示的物理大小
                  child: SizedBox(
                    width: displaySize,
                    height:
                        displaySize *
                        1.25, // 核心修复：将高度比例由 1 改为 1.25 (对应 400:500)，确保底部按钮落在感应区内
                    child: FittedBox(
                      fit: BoxFit.contain, // 改为 contain 确保内容完全显示在感应区内且不被裁剪
                      child: SizedBox(
                        width: baseWheelSize,
                        height: baseWheelSize + 100, // 500
                        child: Stack(
                          alignment: Alignment.topCenter,
                          clipBehavior: Clip.none,
                          children: [
                            // 盘面主容器 (400x400)
                            SizedBox(
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
                                              painter:
                                                  MoodPickerBackgroundPainter(),
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
                                                              item:
                                                                  kMoods[index],
                                                              isSelected:
                                                                  _selectedIndex ==
                                                                  index,
                                                              baseWheelSize:
                                                                  baseWheelSize,
                                                            ),
                                                          )
                                                          .animate()
                                                          .fade(
                                                            delay:
                                                                (index * 40).ms,
                                                            duration: 300.ms,
                                                          )
                                                          .scale(
                                                            delay:
                                                                (index * 30).ms,
                                                            duration: 500.ms,
                                                            curve: Curves
                                                                .easeOutBack,
                                                            alignment: Alignment
                                                                .center,
                                                          );
                                                    }),
                                                  ],
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),

                                      // 3. 右侧强度选择器
                                      Transform.translate(
                                        offset: const Offset(23, 0),
                                        child:
                                            RepaintBoundary(
                                                  child: MoodIntensitySlider(
                                                    intensity: _intensity,
                                                    onChanged: (val) =>
                                                        setState(
                                                          () =>
                                                              _intensity = val,
                                                        ),
                                                    radius: 130,
                                                  ),
                                                )
                                                .animate()
                                                .fade(
                                                  delay: 500.ms,
                                                  duration: 600.ms,
                                                )
                                                .scale(
                                                  begin: const Offset(0.8, 0.8),
                                                  duration: 600.ms,
                                                  curve: Curves.easeOutBack,
                                                ),
                                      ),

                                      // 4. 中心基准小白点
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
                                    ],
                                  ),
                                )
                                .animate(
                                  target: _shakeCount.toDouble(),
                                  onPlay: (controller) =>
                                      controller.forward(from: 0),
                                )
                                .shake(
                                  hz: 6,
                                  curve: Curves.easeInOutCubic,
                                  duration: 400.ms,
                                  offset: const Offset(6, 0),
                                ),

                            // 5. 自定义“清新风格”表情气泡提示
                            // 5. 提示气泡 (使用 AnimatedOpacity 保持索引稳定)
                            Positioned(
                              bottom: 100,
                              child: AnimatedOpacity(
                                opacity: _showBubble ? 1.0 : 0.0,
                                duration: 300.ms,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 18,
                                    vertical: 8,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: 0.95),
                                    borderRadius: BorderRadius.circular(30),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.05),
                                        blurRadius: 20,
                                        offset: const Offset(0, 4),
                                      ),
                                    ],
                                  ),
                                  child: const Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text('✨', style: TextStyle(fontSize: 18)),
                                      SizedBox(width: 8),
                                      Text(
                                        '先选个心情再出发吧~',
                                        style: TextStyle(
                                          color: Color(0xFF6D4C41),
                                          fontSize: 14,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),

                            // 6. 底部确认按钮 (现在位于 500 高度范围内)
                            Positioned(
                              bottom: 10, // 距离底部边缘留一点空隙
                              child:
                                  IslandButton(
                                        text: '确认',
                                        width: 120,
                                        backgroundColor: Colors.white
                                            .withValues(alpha: 0.6),
                                        useHandDrawn: false,
                                        onTap: () {
                                          if (_selectedIndex == null) {
                                            setState(() {
                                              _shakeCount++;
                                              _showBubble = true;
                                            });
                                            // 2秒后自动消失
                                            Future.delayed(
                                              const Duration(seconds: 2),
                                              () {
                                                if (mounted) {
                                                  setState(
                                                    () => _showBubble = false,
                                                  );
                                                }
                                              },
                                            );
                                            return;
                                          }
                                          Navigator.pop(context, {
                                            'index': _selectedIndex,
                                            'intensity': _intensity,
                                          });
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
      ..color = Colors.white.withValues(alpha: 0.6)
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

    // ======= 纯粹边缘外发光实现 (True Outer Glow) =======
    // 方案：使用 MaskFilter.blur(BlurStyle.outer) 确保发光仅作用于路径外部，不产生底部填充叠加感。

    // 1. 底层大范围柔和光晕 (环境光)
    final ambientGlowPaint = Paint()
      ..color = const Color.fromRGBO(213, 213, 213, 0.4)
      ..maskFilter = const MaskFilter.blur(BlurStyle.outer, 12.0);
    canvas.drawPath(path, ambientGlowPaint);

    // 2. 金色质感外发光 (核心光)
    final goldenGlowPaint = Paint()
      ..color = const Color.fromRGBO(244, 214, 115, 0.7)
      ..maskFilter = const MaskFilter.blur(BlurStyle.outer, 6.0);
    canvas.drawPath(path, goldenGlowPaint);

    // 3. 绘制实体背景 (中心区域)
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}
