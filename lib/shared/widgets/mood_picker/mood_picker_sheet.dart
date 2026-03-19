import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'dart:ui';

import 'package:flutter/rendering.dart';
import 'config/mood_config.dart';
import 'widgets/mood_slice_item.dart';
import 'widgets/mood_intensity_slider.dart';
import '../island_button.dart';
import '../island_alert.dart';

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
  late TextEditingController _tagController;
  late FixedExtentScrollController _intensityScrollController;
  bool _isTagEditing = false; // 是否处于标签编辑状态

  @override
  void initState() {
    super.initState();
    // 【核心性能优化】延迟一帧渲染内部组件
    // 这解决了弹出瞬间外层 SlimeButton 呼吸光晕被打断感的问题。
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        setState(() => _isReady = true);
      }
    });
    _tagController = TextEditingController();
    _intensityScrollController = FixedExtentScrollController(
      initialItem: _intensity.toInt() - 1,
    );
  }

  @override
  void dispose() {
    _tagController.dispose();
    _intensityScrollController.dispose();
    super.dispose();
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
      HapticFeedback.lightImpact();
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
                                      // 1. 底层白色背景 (带突出部) - 编辑时完全隐藏
                                      AnimatedOpacity(
                                        opacity: _isTagEditing ? 0.0 : 1.0,
                                        duration: 300.ms,
                                        child:
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
                                      ),

                                      // 2. 心情选项层 (居中) - 编辑时完全隐藏
                                      AnimatedOpacity(
                                        opacity: _isTagEditing ? 0.0 : 1.0,
                                        duration: 300.ms,
                                        child: GestureDetector(
                                          onTapDown: (details) {
                                            if (!_isTagEditing) {
                                              _handleTap(
                                                details.localPosition,
                                                baseWheelSize,
                                              );
                                            }
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
                                                                  (index * 40)
                                                                      .ms,
                                                              duration: 300.ms,
                                                            )
                                                            .scale(
                                                              delay:
                                                                  (index * 30)
                                                                      .ms,
                                                              duration: 500.ms,
                                                              curve: Curves
                                                                  .easeOutBack,
                                                              alignment:
                                                                  Alignment
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
                                      ),

                                      // 3. 右侧强度选择器 - 编辑时完全隐藏 (由新滑块替代)
                                      Transform.translate(
                                        offset: const Offset(21, 0),
                                        child: AnimatedOpacity(
                                          opacity: _isTagEditing ? 0.0 : 1.0,
                                          duration: 300.ms,
                                          child:
                                              RepaintBoundary(
                                                    child: MoodIntensitySlider(
                                                      intensity: _intensity,
                                                      onChanged: (val) {
                                                        if (!_isTagEditing) {
                                                          setState(
                                                            () => _intensity =
                                                                val,
                                                          );
                                                        }
                                                      },
                                                      radius: 138,
                                                    ),
                                                  )
                                                  .animate()
                                                  .fade(
                                                    delay: 500.ms,
                                                    duration: 600.ms,
                                                  )
                                                  .scale(
                                                    duration: 600.ms,
                                                    curve: Curves.easeOutBack,
                                                  ),
                                        ),
                                      ),

                                      // 4. 下方标签按钮 - 编辑时完全隐藏
                                      Transform.translate(
                                            offset: const Offset(27, 0),
                                            child: AnimatedOpacity(
                                              opacity: _isTagEditing
                                                  ? 0.0
                                                  : 1.0,
                                              duration: 200.ms,
                                              child: Transform.rotate(
                                                angle: -5 * math.pi / 180,
                                                origin: const Offset(
                                                  87.3,
                                                  93.6,
                                                ),
                                                child: MoodTagArcButton(
                                                  tag: _tagController.text,
                                                  isEditing: _isTagEditing,
                                                  onTap: () {
                                                    HapticFeedback.lightImpact();
                                                    setState(() {
                                                      _isTagEditing = true;
                                                      // 确保滚轮起始位置正确同步
                                                      _intensityScrollController
                                                          .jumpToItem(
                                                            _intensity.toInt() -
                                                                1,
                                                          );
                                                    });
                                                  },
                                                  radius: 128,
                                                ),
                                              ),
                                            ),
                                          )
                                          .animate(
                                            onPlay: (controller) => controller
                                                .repeat(reverse: true),
                                          )
                                          .scale(
                                            begin: const Offset(1.0, 1.0),
                                            end: const Offset(1.02, 1.02),
                                            duration: 2.seconds,
                                            curve: Curves.easeInOut,
                                          )
                                          .animate()
                                          .fade(delay: 600.ms, duration: 600.ms)
                                          .scale(
                                            begin: const Offset(0.8, 0.8),
                                            duration: 600.ms,
                                            curve: Curves.easeOutBack,
                                          ),

                                      // 核心：发光珠光风格数字滚位器 + 标签输入 (仅在编辑标签时显示)
                                      if (_isTagEditing)
                                        TweenAnimationBuilder<double>(
                                          duration: 500.ms,
                                          curve: Curves.elasticOut,
                                          tween: Tween(begin: 0.0, end: 1.0),
                                          builder: (context, value, child) {
                                            final sleekGlowingDecoration =
                                                BoxDecoration(
                                                  color: Colors.white
                                                      .withValues(alpha: 0.8),
                                                  borderRadius:
                                                      BorderRadius.circular(16),
                                                  border: Border.all(
                                                    color: Colors.white
                                                        .withValues(alpha: 0.5),
                                                    width: 1.5,
                                                  ),
                                                  boxShadow: [
                                                    // 1. 环境柔和发光 (淡金色)
                                                    BoxShadow(
                                                      color: const Color(
                                                        0xFFF4D673,
                                                      ).withOpacity(0.55),
                                                      blurRadius: 25,
                                                      spreadRadius: 2,
                                                    ),
                                                    // 2. 基础接地阴影
                                                    BoxShadow(
                                                      color: Colors.black
                                                          .withOpacity(0.08),
                                                      blurRadius: 15,
                                                      offset: const Offset(
                                                        0,
                                                        5,
                                                      ),
                                                    ),
                                                  ],
                                                );

                                            return Transform.scale(
                                              scale: value,
                                              child: Row(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  // 1. 输入内容与底座 (发光珠光风格)
                                                  Container(
                                                    width: 200,
                                                    height: 52,
                                                    decoration:
                                                        sleekGlowingDecoration,
                                                    child: Center(
                                                      child: TextField(
                                                        controller:
                                                            _tagController,
                                                        textAlign:
                                                            TextAlign.center,
                                                        cursorColor:
                                                            const Color(
                                                              0xFF8D6E63,
                                                            ),
                                                        maxLength:
                                                            10, // 限制 10 个字符
                                                        style: const TextStyle(
                                                          fontSize: 16,
                                                          color: Color(
                                                            0xFF6D4C41,
                                                          ),
                                                          fontWeight:
                                                              FontWeight.bold,
                                                          fontFamily:
                                                              'LXGWWenKai',
                                                        ),
                                                        decoration: InputDecoration(
                                                          counterText:
                                                              '', // 隐藏默认文字计数器
                                                          hintText:
                                                              '描述此刻的心境...',
                                                          hintStyle: TextStyle(
                                                            color:
                                                                const Color(
                                                                  0xFF8D6E63,
                                                                ).withOpacity(
                                                                  0.6,
                                                                ), // 提高可见度
                                                            fontSize: 14,
                                                            fontWeight:
                                                                FontWeight.w500,
                                                          ),
                                                          border:
                                                              InputBorder.none,
                                                          isDense: true,
                                                          contentPadding:
                                                              const EdgeInsets.symmetric(
                                                                horizontal: 16,
                                                              ),
                                                        ),
                                                        onSubmitted: (_) {
                                                          // 提交时触发确认逻辑 (有内容即可提交)
                                                          if (_tagController.text.isNotEmpty ||
                                                              _selectedIndex != null) {
                                                            Navigator.pop(context, {
                                                              'index': _selectedIndex ?? 4, // 默认平静
                                                              'intensity': _intensity,
                                                              'tag': _tagController.text.isNotEmpty
                                                                  ? _tagController.text
                                                                  : null,
                                                            });
                                                          } else {
                                                            // 全空，仅执行抖动并显示警告，保持编辑界面
                                                            setState(() {
                                                              _shakeCount++;
                                                            });
                                                            IslandAlert.show(
                                                              context,
                                                              message: '先选个心情再出发吧~',
                                                              icon: '✨',
                                                              withAnimation: false,
                                                            );
                                                          }
                                                        },
                                                      ),
                                                    ),
                                                  ),
                                                  const SizedBox(width: 12),
                                                  // 2. 右侧数字滚动选择器 (发光珠光风格)
                                                  Container(
                                                    width: 52,
                                                    height: 52,
                                                    decoration:
                                                        sleekGlowingDecoration,
                                                    child: ListWheelScrollView.useDelegate(
                                                      controller:
                                                          _intensityScrollController,
                                                      itemExtent: 28,
                                                      physics:
                                                          const FixedExtentScrollPhysics(),
                                                      diameterRatio: 1.2,
                                                      perspective: 0.003,
                                                      onSelectedItemChanged: (index) {
                                                        HapticFeedback.selectionClick();
                                                        setState(
                                                          () => _intensity =
                                                              (index + 1)
                                                                  .toDouble(),
                                                        );
                                                      },
                                                      childDelegate: ListWheelChildListDelegate(
                                                        children: List.generate(
                                                          10,
                                                          (i) => Center(
                                                            child: Text(
                                                              '${i + 1}',
                                                              style: const TextStyle(
                                                                fontSize: 18,
                                                                color: Color(
                                                                  0xFF6D4C41,
                                                                ),
                                                                fontWeight:
                                                                    FontWeight
                                                                        .bold,
                                                                fontFamily:
                                                                    'LXGWWenKai',
                                                              ),
                                                            ),
                                                          ),
                                                        ),
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            );
                                          },
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

                            // 5. 底部确认按钮 - 始终可见
                            Positioned(
                              bottom: 10,
                              child:
                                  IslandButton(
                                        text: '确认',
                                        width: 120,
                                        backgroundColor: Colors.white
                                            .withValues(
                                              alpha: 0.7,
                                            ), // 显式提高不透明度，增强视觉反馈
                                        useHandDrawn: false,
                                        onTap: () {
                                          // 提交逻辑重构：不再强制要求选择心情切片
                                          if (_isTagEditing) {
                                            if (_tagController.text.isNotEmpty ||
                                                _selectedIndex != null) {
                                              // 情况 A: 有内容（标签或心情）即可直接提交
                                              Navigator.pop(context, {
                                                'index': _selectedIndex ?? 4, // 默认平静
                                                'intensity': _intensity,
                                                'tag': _tagController.text.isNotEmpty
                                                    ? _tagController.text
                                                    : null,
                                              });
                                              return;
                                            } else {
                                              // 情况 B: 全空，仅执行抖动并显示警告，保持编辑界面
                                              setState(() {
                                                _shakeCount++;
                                              });
                                              IslandAlert.show(
                                                context,
                                                message: '先选个心情再出发吧~',
                                                icon: '✨',
                                                withAnimation: false,
                                              );
                                              return;
                                            }
                                          }

                                          // 非编辑模式下点击确认
                                          if (_selectedIndex == null &&
                                              _tagController.text.isEmpty) {
                                            setState(() {
                                              _shakeCount++;
                                            });
                                            IslandAlert.show(
                                              context,
                                              message: '先选个心情再出发吧~',
                                              icon: '✨',
                                              withAnimation: false,
                                            );
                                            return;
                                          }

                                          // 正常模式提交
                                          Navigator.pop(context, {
                                            'index': _selectedIndex ?? 4,
                                            'intensity': _intensity,
                                            'tag': _tagController.text.isNotEmpty
                                                ? _tagController.text
                                                : null,
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

    // ======= 连续路径重塑：确保背景完整且无缝 =======
    final double r = radius;
    final double outerR = r + 14;

    final path = Path();

    // ======= 侧边统一大突起：整合强度条与标签按钮背景 =======
    final shiftedCenter = Offset(center.dx + 15, center.dy);
    const double startAngle = -60 * math.pi / 180;

    path.moveTo(
      center.dx + r * math.cos(startAngle),
      center.dy + r * math.sin(startAngle),
    );

    // 1. 爬坡
    path.cubicTo(
      center.dx + (r + 1) * math.cos(-57 * math.pi / 180),
      center.dy + (r + 1) * math.sin(-57 * math.pi / 180),
      shiftedCenter.dx + (outerR - 1) * math.cos(-53 * math.pi / 180),
      shiftedCenter.dy + (outerR - 1) * math.sin(-53 * math.pi / 180),
      shiftedCenter.dx + outerR * math.cos(-50 * math.pi / 180),
      shiftedCenter.dy + outerR * math.sin(-50 * math.pi / 180),
    );

    // 2. 突起顶部大圆弧
    path.arcTo(
      Rect.fromCircle(center: shiftedCenter, radius: outerR),
      -50 * math.pi / 180,
      (50 + 65) * math.pi / 180,
      false,
    );

    // 3. 下坡
    path.cubicTo(
      shiftedCenter.dx + (outerR - 1) * math.cos(67 * math.pi / 180),
      shiftedCenter.dy + (outerR - 1) * math.sin(67 * math.pi / 180),
      center.dx + (r + 1) * math.cos(69 * math.pi / 180),
      center.dy + (r + 1) * math.sin(69 * math.pi / 180),
      center.dx + r * math.cos(72 * math.pi / 180),
      center.dy + r * math.sin(72 * math.pi / 180),
    );

    // 4. 完成剩余的大圆弧
    path.arcTo(
      Rect.fromCircle(center: center, radius: r),
      72 * math.pi / 180,
      (360 - 72 - 60) * math.pi / 180,
      false,
    );

    path.close();
    final combinedPath = path;

    // ======= 纯粹边缘外发光实现 =======
    final ambientGlowPaint = Paint()
      ..color = const Color.fromRGBO(213, 213, 213, 0.4)
      ..maskFilter = const MaskFilter.blur(BlurStyle.outer, 12.0);
    canvas.drawPath(combinedPath, ambientGlowPaint);

    final goldenGlowPaint = Paint()
      ..color = const Color.fromRGBO(244, 214, 115, 0.7)
      ..maskFilter = const MaskFilter.blur(BlurStyle.outer, 6.0);
    canvas.drawPath(combinedPath, goldenGlowPaint);

    canvas.drawPath(combinedPath, paint);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}

/// 弧形标签按钮
class MoodTagArcButton extends StatelessWidget {
  final String tag;
  final bool isEditing;
  final VoidCallback onTap;
  final double radius;

  const MoodTagArcButton({
    super.key,
    required this.tag,
    required this.isEditing,
    required this.onTap,
    this.radius = 130,
  });

  @override
  Widget build(BuildContext context) {
    const double startAngle = 32 * math.pi / 180;
    const double swepAngle = 30 * math.pi / 180;
    final double size = radius * 2 + 100;

    return Center(
      child: _MoodTagArcButtonHitTestWrapper(
        radius: radius,
        startAngle: startAngle,
        swepAngle: swepAngle,
        child: GestureDetector(
          onTap: onTap,
          behavior: HitTestBehavior.translucent,
          child: CustomPaint(
            size: Size(size, size),
            painter: TagArcPainter(
              tag: tag.isEmpty ? "添加标签" : tag,
              isEditing: isEditing,
              radius: radius,
              startAngle: startAngle,
              swepAngle: swepAngle,
            ),
          ),
        ),
      ),
    );
  }
}

/// 自定义 HitTest 包装器
class _MoodTagArcButtonHitTestWrapper extends SingleChildRenderObjectWidget {
  final double radius;
  final double startAngle;
  final double swepAngle;

  const _MoodTagArcButtonHitTestWrapper({
    required Widget child,
    required this.radius,
    required this.startAngle,
    required this.swepAngle,
  }) : super(child: child);

  @override
  RenderObject createRenderObject(BuildContext context) {
    return _RenderMoodTagArcButtonHitTest(radius, startAngle, swepAngle);
  }

  @override
  void updateRenderObject(
    BuildContext context,
    covariant _RenderMoodTagArcButtonHitTest renderObject,
  ) {
    renderObject
      ..radius = radius
      ..startAngle = startAngle
      ..swepAngle = swepAngle;
  }
}

class _RenderMoodTagArcButtonHitTest extends RenderProxyBox {
  double radius;
  double startAngle;
  double swepAngle;

  _RenderMoodTagArcButtonHitTest(this.radius, this.startAngle, this.swepAngle);

  @override
  bool hitTest(BoxHitTestResult result, {required Offset position}) {
    final center = size.center(Offset.zero);
    final dx = position.dx - center.dx;
    final dy = position.dy - center.dy;
    final distance = math.sqrt(dx * dx + dy * dy);

    if (distance < radius - 5 || distance > radius + 25) {
      return false;
    }

    double angle = math.atan2(dy, dx);
    if (angle < startAngle - 0.1 || angle > (startAngle + swepAngle + 0.1)) {
      return false;
    }

    return super.hitTest(result, position: position);
  }
}

class TagArcPainter extends CustomPainter {
  final String tag;
  final bool isEditing;
  final double radius;
  final double startAngle;
  final double swepAngle;

  TagArcPainter({
    required this.tag,
    required this.isEditing,
    required this.radius,
    required this.startAngle,
    required this.swepAngle,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final String displayTag = tag.isEmpty ? "+ 添加标签" : tag;

    final backgroundPaint = Paint()
      ..color = const Color(0xFFFFFDE7).withValues(alpha: 0.6)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 18
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius + 9),
      startAngle - 0.05,
      swepAngle + 0.1,
      false,
      backgroundPaint,
    );

    final chars = displayTag.split('');
    if (chars.isEmpty) {
      return;
    }

    final double effectiveSwep = swepAngle * 0.85;
    final double startArcOffset = startAngle + (swepAngle - effectiveSwep) / 2;
    final double charStep =
        effectiveSwep / (chars.length > 1 ? chars.length - 1 : 1);

    for (int i = 0; i < chars.length; i++) {
      final double charAngle = startArcOffset + i * charStep;
      final double currentR = radius + 9;

      final charOffset = Offset(
        center.dx + currentR * math.cos(charAngle),
        center.dy + currentR * math.sin(charAngle),
      );

      final textPainter = TextPainter(
        text: TextSpan(
          text: chars[i],
          style: TextStyle(
            color: isEditing
                ? const Color(0xFFFF8C00)
                : const Color(0xFF8C7359),
            fontSize: displayTag.length > 6 ? 9 : 11,
            fontWeight: FontWeight.bold,
            fontFamily: 'LXGWWenKai',
          ),
        ),
        textDirection: TextDirection.ltr,
      );
      textPainter.layout();

      canvas.save();
      canvas.translate(charOffset.dx, charOffset.dy);
      textPainter.paint(
        canvas,
        Offset(-textPainter.width / 2, -textPainter.height / 2),
      );
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant TagArcPainter oldDelegate) {
    return oldDelegate.tag != tag || oldDelegate.isEditing != isEditing;
  }
}
