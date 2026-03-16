import 'dart:math';
import 'dart:ui';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart'; // 核心：导入基础类型支持
import 'package:flutter_animate/flutter_animate.dart';
import 'package:island_diary/core/state/user_state.dart';
import 'package:island_diary/shared/widgets/slime_onboarding.dart';
import 'package:island_diary/shared/widgets/slime_button.dart';
import 'package:island_diary/shared/widgets/sprite_dialogue.dart';
import 'package:island_diary/shared/widgets/mood_picker/mood_picker_sheet.dart';
import 'package:island_diary/core/services/slime_dialogue_service.dart';
import 'package:island_diary/shared/widgets/mood_picker/config/mood_config.dart';
import 'package:island_diary/shared/widgets/diary_entry/diary_entry_sheet.dart';

class BottomNavBar extends StatefulWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;
  final bool isNight;
  final VoidCallback? onSaveSuccess;
  final bool forceHideDialogue; // [NEW] 是否强制隐藏精灵对话框

  const BottomNavBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
    this.isNight = false,
    this.onSaveSuccess,
    this.forceHideDialogue = false,
  });

  @override
  State<BottomNavBar> createState() => _BottomNavBarState();
}

const double centerButtonRadius = 32.0; // 遵循相切圆方案比例：下调至 32.0，更精致紧凑

class _BottomNavBarState extends State<BottomNavBar> {
  bool _justFinishedOnboarding = false; // 是否刚完成新手引导
  late final ValueNotifier<bool> _showDialogueNotifier;
  late final ValueNotifier<String> _dialogueTextNotifier;
  late final ValueNotifier<bool> _isIdleNotifier;
  late final ValueNotifier<bool> _isMoodPickerOpenNotifier;

  Timer? _dialogueTimer;
  Timer? _idleTimer;
  final GlobalKey _slimeKey =
      GlobalKey(); // 核心：使用 GlobalKey 强力锁定精灵状态，确保呼吸动效跨 Stack 变化不断

  @override
  void initState() {
    super.initState();
    _showDialogueNotifier = ValueNotifier<bool>(true);
    _dialogueTextNotifier = ValueNotifier<String>('');
    _isIdleNotifier = ValueNotifier<bool>(false);
    _isMoodPickerOpenNotifier = ValueNotifier<bool>(false);

    _refreshDialogue();
    _startDialogueTimer();
    _startIdleTimer();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // 【核心性能优化】提前预解码精灵表情资源，彻底消除初次切换时的“主线程解码卡顿”
    precacheImage(const AssetImage('assets/images/emoji/weixiao.png'), context);
    precacheImage(const AssetImage('assets/images/emoji/pedding.png'), context);
    precacheImage(const AssetImage('assets/images/paper.png'), context);

    // 【绝杀卡顿】心情面板在被直接创建时会引发 16 次独立的高清图层 I/O 解码。
    // 在这里一次性地毯式预解码，确保点击精灵的一瞬间路由动画能保持绝对满帧。
    for (var mood in kMoods) {
      if (mood.imagePath != null) {
        precacheImage(AssetImage(mood.imagePath!), context);
      }
      if (mood.iconPath != null) {
        precacheImage(AssetImage(mood.iconPath!), context);
      }
    }
  }

  void _startDialogueTimer() {
    _dialogueTimer?.cancel();
    _dialogueTimer = Timer(const Duration(seconds: 10), () {
      if (mounted) {
        _showDialogueNotifier.value = false;
      }
    });
  }

  void _startIdleTimer() {
    _idleTimer?.cancel();
    _idleTimer = Timer(const Duration(seconds: 30), () {
      if (mounted) {
        _isIdleNotifier.value = true;
      }
    });
  }

  void _refreshDialogue() {
    // 修正：该服务内部已自动处理 UserState()
    _dialogueTextNotifier.value = SlimeDialogueService().getDynamicDialogue();
  }

  @override
  void dispose() {
    _dialogueTimer?.cancel();
    _idleTimer?.cancel();
    _showDialogueNotifier.dispose();
    _dialogueTextNotifier.dispose();
    _isIdleNotifier.dispose();
    _isMoodPickerOpenNotifier.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const double barHeight = 76;
    const double notchRadius = 52.0; // 怀抱式设计：凹口半径 (52) 大于按钮半径 (36)，形成包裹感
    final bool isNight = widget.isNight;

    final double screenWidth = MediaQuery.of(context).size.width;
    // 彻底锁定：在任何设备上都保持 500 左右的最佳宽度，确保视觉一致性
    final double barMaxWidth = screenWidth <= 600 ? screenWidth * 0.9 : 500.0;
    final double contentWidth = barMaxWidth * 0.88;

    return SizedBox(
      height: SlimeButton.containerHeight, // 统一使用扩容后的高度，确保气泡 hits 测试有效
      child: Stack(
        alignment: Alignment.bottomCenter,
        clipBehavior: Clip.none,
        children: [
          // ── 底栏主体：阴影 + 裁剪 + 磨砂 + 渐变边框 ──
          Positioned(
            bottom: -6,
            left: 0,
            right: 0,
            child: Center(
              child: Container(
                constraints: BoxConstraints(
                  maxWidth: barMaxWidth,
                ), // iPad/大屏：响应式动态宽度
                margin: const EdgeInsets.symmetric(horizontal: 24),
                decoration: BoxDecoration(
                  boxShadow: [
                    BoxShadow(
                      color: isNight
                          ? Colors.black.withOpacity(0.18)
                          : const Color(0xFF1B3B5F).withOpacity(0.2), // 软化复合阴影
                      blurRadius: isNight ? 20 : 40,
                      spreadRadius: isNight ? 1 : 1,
                      offset: Offset(0, isNight ? 8 : 12),
                    ),
                    if (!isNight)
                      BoxShadow(
                        color: const Color(0xFF80D8FF).withOpacity(0.12),
                        blurRadius: 20,
                        spreadRadius: -2,
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
                        width: double.infinity,
                        child: Stack(
                          children: [
                            Positioned.fill(
                              child: BackdropFilter(
                                filter: ImageFilter.blur(
                                  sigmaX: isNight ? 15 : 20, // 夜间还原为 15
                                  sigmaY: isNight ? 15 : 20,
                                ),
                                child: Container(
                                  decoration: BoxDecoration(
                                    gradient: isNight
                                        ? null
                                        : LinearGradient(
                                            begin: Alignment.topCenter,
                                            end: Alignment.bottomCenter,
                                            colors: [
                                              const Color(0xFFB3E5FC).withOpacity(0.5), // 深湖蓝顶部
                                              const Color(0xFFE1F5FE).withOpacity(0.3), // 浅水蓝底部
                                            ],
                                          ),
                                    color: isNight
                                        ? const Color(0xFF736675).withOpacity(0.2)
                                        : null,
                                  ),
                                ),
                              ),
                            ),
                            // 仅在日间增加金色顶部细描边
                            if (!isNight)
                              Positioned(
                                top: 0,
                                left: 0,
                                right: 0,
                                child: Container(
                                  height: 0.8,
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: [
                                        const Color(0xFFFFF176).withOpacity(0.0),
                                        const Color(0xFFFFF176).withOpacity(0.6),
                                        const Color(0xFFFFF176).withOpacity(0.0),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            // 限制内容的宽度，防止图标在 500px 内仍然太散
                            Center(
                              child: Container(
                                width: contentWidth, // 动态内容区宽度
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceAround,
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
                                    const SizedBox(width: 80),
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
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    // 2. 渐变描边 (由于白天也要惊艳，我们为白天也加上微弱的流金边框)
                    Positioned.fill(
                      child: IgnorePointer(
                        child: CustomPaint(
                          painter: _NavBarGradientPainter(
                            clipper: const _NavBarClipper(
                              notchRadius: notchRadius,
                              barRadius: 38,
                            ),
                            strokeWidth: isNight ? 2.5 : 1.2, // 白天细一点，更精致
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: isNight 
                                ? const [
                                    Color(0xFFEEBB3C), // 描边顶部换成金色
                                    Color(0xFF1B2735), // 深海蓝
                                  ]
                                : [
                                    const Color(0xFFFFF9C4).withOpacity(0.8), // 白天淡金色顶部
                                    const Color(0xFFB3E5FC).withOpacity(0.2), // 融入水色的底部
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
          ),

          Positioned.fill(
            child: Center(
              child: Container(
                constraints: BoxConstraints(maxWidth: barMaxWidth), // 与底栏宽度保持一致
                child: ValueListenableBuilder<bool>(
                  valueListenable: UserState().hasFinishedOnboarding,
                  builder: (context, hasFinished, child) {
                    if (!hasFinished) {
                      return SlimeOnboarding(
                        key: const ValueKey('slime_onboarding'),
                        isNight: isNight,
                        onSlimeAction: () => _openMoodPicker(),
                        onComplete: () {
                          setState(() => _justFinishedOnboarding = true);
                          UserState().completeOnboarding();
                        },
                      );
                    }

                    return MultiValueListenableBuilder(
                      listenables: [
                        _isIdleNotifier,
                        _showDialogueNotifier,
                        _isMoodPickerOpenNotifier,
                        _dialogueTextNotifier,
                      ],
                      builder: (context, values, child) {
                        final isIdle = values[0] as bool;
                        final showDialogue = values[1] as bool;
                        final isMoodPickerOpen = values[2] as bool;
                        final slimeDialogue = values[3] as String;

                        return Stack(
                          alignment: Alignment.bottomCenter,
                          clipBehavior: Clip.none,
                          children: [
                            Positioned(
                              bottom: SlimeButton.bottomOffset,
                              child: ValueListenableBuilder<bool>(
                                valueListenable: UserState().isSlimeInBottomMenu,
                                builder: (context, isInMenu, _) {
                                  return SlimeButton(
                                    key: _slimeKey,
                                    isNight: isNight,
                                    isGlowing: true,
                                    showSlime: isInMenu, // 关键：背景常驻，只改变角色可见度
                                    assetPath: isIdle
                                        ? 'assets/images/emoji/pedding.png'
                                        : 'assets/images/emoji/weixiao.png',
                                    frameCount: isIdle ? 1 : 9,
                                    isPlaying: showDialogue && !isIdle,
                                    onTap: () => _openMoodPicker(),
                                  );
                                },
                              ),
                            ),
                            if (!_justFinishedOnboarding)
                              Positioned(
                                bottom: 124.0, // 气泡距离底部的距离
                                child: IgnorePointer(
                                  ignoring: !showDialogue || isMoodPickerOpen || widget.forceHideDialogue,
                                  child:
                                      SpriteDialogue(
                                            text: slimeDialogue,
                                            useTypewriter: false,
                                            onNext: () {
                                              _dialogueTimer?.cancel();
                                              _showDialogueNotifier.value =
                                                  false;
                                            },
                                          )
                                          .animate(
                                            target:
                                                (showDialogue &&
                                                        !isMoodPickerOpen &&
                                                        !widget.forceHideDialogue)
                                                ? 1
                                                : 0,
                                          )
                                          .fade(duration: 400.ms)
                                          .scale(
                                            begin: const Offset(0.9, 0.9),
                                            duration: 400.ms,
                                            curve: Curves.easeOutBack,
                                          ),
                                ),
                              ),
                          ],
                        );
                      },
                    );
                  },
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // 统一打开心情选择器的逻辑
  Future<void> _openMoodPicker() async {
    // 0. 优先检查是否有草稿，如果有则直接进入编辑
    final draft = UserState().diaryDraft.value;
    if (draft != null) {
      _openDiaryEntry(draft.moodIndex, draft.intensity);
      return;
    }

    // 记录进入时是否还在引导状态（await 之后无法再读取准确值）
    final wasOnboarding = !UserState().hasFinishedOnboarding.value;

    // 记录弹窗状态，对话框顺便消失，闲置状态重置
    _isMoodPickerOpenNotifier.value = true;
    _showDialogueNotifier.value = false; // 退场动画由上面 target 控制
    _isIdleNotifier.value = false;
    _dialogueTimer?.cancel();
    _idleTimer?.cancel();

    // 【核心修复】使用 addPostFrameCallback 确保当前帧的渲染流水线正常完成后再启动弹窗。
    final completer = Completer<Map<String, dynamic>?>();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) {
        completer.complete(null);
        return;
      }
      final result = await showGeneralDialog<Map<String, dynamic>>(
        context: context,
        barrierDismissible: true,
        barrierLabel: 'MoodPicker',
        barrierColor: Colors.black.withOpacity(0.6),
        transitionDuration: const Duration(milliseconds: 500),
        transitionBuilder: (context, animation, secondaryAnimation, child) {
          final curvedAnimation = CurvedAnimation(
            parent: animation,
            curve: Curves.easeOutBack,
          );
          return Transform.scale(
            scale: curvedAnimation.value,
            alignment: const Alignment(0.0, 0.8),
            child: FadeTransition(opacity: animation, child: child),
          );
        },
        pageBuilder: (context, anim1, anim2) => const MoodPickerSheet(),
      );
      completer.complete(result);
    });

    final result = await completer.future;

    // 【核心修复】弹窗关闭后才标记引导完成，避免在弹窗打开动画期间切换底层 widget 造成闪烁
    if (mounted) {
      _isMoodPickerOpenNotifier.value = false;
      _isIdleNotifier.value = false; // 操作完肯定不是闲置了

      if (wasOnboarding) {
        setState(() {
          _justFinishedOnboarding = true;
        });
        _refreshDialogue(); // 引导结束后重新刷一次充满温度的对话
      }
      _startIdleTimer(); // 重新开始挂机计时

      if (wasOnboarding) {
        UserState().completeOnboarding();
      }

      // 如果用户选择了心情，则自动打开日记输入框
      if (result != null) {
        _openDiaryEntry(result['index'], result['intensity']);
      }
    }
  }

  // 打开像 uniapp popup 一样的日记输入组件
  void _openDiaryEntry(int moodIndex, double intensity) {
    UserState().isDiarySheetOpen.value = true;
    showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      isDismissible: false,
      enableDrag: false,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withOpacity(0.6),
      constraints: const BoxConstraints(maxWidth: double.infinity),
      builder: (context) =>
          MoodDiaryEntrySheet(moodIndex: moodIndex, intensity: intensity),
    ).then((success) {
      UserState().isDiarySheetOpen.value = false;
      if (success == true && widget.onSaveSuccess != null) {
        widget.onSaveSuccess!();
      }
    });
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

/// 辅助组件：同时监听多个 ValueListenable
class MultiValueListenableBuilder extends StatelessWidget {
  final List<ValueListenable> listenables;
  final Widget Function(
    BuildContext context,
    List<dynamic> values,
    Widget? child,
  )
  builder;
  final Widget? child;

  const MultiValueListenableBuilder({
    super.key,
    required this.listenables,
    required this.builder,
    this.child,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge(listenables),
      builder: (context, child) {
        // 精确映射每一个监听器的最新值
        final values = listenables.map((l) => l.value).toList();
        return builder(context, values, child);
      },
      child: child,
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
            Stack(
              alignment: Alignment.center,
              children: [
                // 选中的辉光背景 (仅限日间)
                if (isSelected && !widget.isNight)
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFFFFE082).withOpacity(0.4),
                          blurRadius: 15,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                  ).animate().fade(duration: 400.ms),
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
              ],
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
