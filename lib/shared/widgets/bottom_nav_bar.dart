import 'dart:ui';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:island_diary/core/state/user_state.dart';
import 'package:island_diary/shared/widgets/slime_button.dart';
import 'package:island_diary/shared/widgets/mood_picker/config/mood_config.dart';
import 'package:island_diary/features/record/presentation/pages/diary_editor_page.dart';

import 'nav_item.dart';
import 'nav_bar_clipper.dart';
import 'multi_value_listenable_builder.dart';

class BottomNavBar extends StatefulWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;
  final bool isNight;
  final Function(List<dynamic>)? onSaveSuccess;
  final bool forceHideDialogue;

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

class _BottomNavBarState extends State<BottomNavBar> {
  late final ValueNotifier<bool> _isIdleNotifier;
  late final ValueNotifier<bool> _isMoodPickerOpenNotifier;

  Timer? _idleTimer;
  final GlobalKey _slimeKey = GlobalKey();

  static const double barHeight = 76;
  static const double notchRadius = 52.0;
  static const double barRadius = 38.0;

  @override
  void initState() {
    super.initState();
    _isIdleNotifier = ValueNotifier<bool>(false);
    _isMoodPickerOpenNotifier = ValueNotifier<bool>(false);
    _startIdleTimer();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    precacheImage(const AssetImage('assets/images/paper.png'), context);

    for (var mood in kMoods) {
      final icon = mood.iconPath;
      if (icon != null) precacheImage(AssetImage(icon), context);
    }
  }

  @override
  void dispose() {
    _idleTimer?.cancel();
    _isIdleNotifier.dispose();
    _isMoodPickerOpenNotifier.dispose();
    super.dispose();
  }

  void _startIdleTimer() {
    _idleTimer?.cancel();
    _idleTimer = Timer(const Duration(seconds: 30), () {
      if (mounted) _isIdleNotifier.value = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final double barMaxWidth = screenWidth <= 600 ? screenWidth * 0.92 : 560.0;
    final userState = UserState();

    return SizedBox(
      height: SlimeButton.containerHeight,
      child: ListenableBuilder(
        listenable: Listenable.merge([
          userState.selectedBackgroundDecoration,
          userState.refreshNavbarBgTrigger,
        ]),
        builder: (context, _) {
          return Stack(
            alignment: Alignment.bottomCenter,
            clipBehavior: Clip.none,
            children: [
              _buildBackground(barMaxWidth),
              _buildContentArea(barMaxWidth),
            ],
          );
        },
      ),
    );
  }

  Widget _buildBackground(double barMaxWidth) {
    final themeId = UserState().selectedIslandThemeId.value;
    final isLanternFestival = false;
    final isCottonCandy = themeId == 'cotton_candy';

    return Positioned(
      bottom: -6,
      left: 0,
      right: 0,
      child: Center(
        child: Container(
          constraints: BoxConstraints(maxWidth: barMaxWidth),
          decoration: BoxDecoration(
            boxShadow: [
              BoxShadow(
                color: isCottonCandy
                    ? const Color(0xFFFF94B8).withValues(alpha: 0.25)
                    : (widget.isNight
                        ? Colors.black.withValues(alpha: 0.18)
                        : const Color(
                            0xFF1B3B5F,
                          ).withValues(alpha: 0.2)),
                blurRadius:
                    (widget.isNight || isCottonCandy)
                        ? 20
                        : 40,
                offset: Offset(
                  0,
                  (widget.isNight || isCottonCandy)
                      ? 8
                      : 12,
                ),
              ),
              if (!widget.isNight && !isCottonCandy)
                BoxShadow(
                  color: const Color(0xFF80D8FF).withValues(alpha: 0.12),
                  blurRadius: 20,
                  spreadRadius: -2,
                ),
            ],
          ),
          child: Stack(
            children: [
              ClipPath(
                clipper: const NavBarClipper(
                  notchRadius: notchRadius,
                  barRadius: barRadius,
                ),
                child: _buildBlurBody(
                  isLanternFestival: isLanternFestival,
                  isCottonCandy: isCottonCandy,
                  child: Center(
                    child: SizedBox(
                      width: barMaxWidth * 0.88,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _buildNavItem(
                            0,
                            CupertinoIcons.house,
                            CupertinoIcons.house_fill,
                            '首页',
                          ),
                          _buildNavItem(
                            1,
                            CupertinoIcons.book,
                            CupertinoIcons.book_fill,
                            '记录',
                          ),
                          const SizedBox(width: 80),
                          _buildNavItem(
                            3,
                            CupertinoIcons.chart_bar,
                            CupertinoIcons.chart_bar_fill,
                            '数据',
                          ),
                          _buildNavItem(
                            4,
                            CupertinoIcons.person,
                            CupertinoIcons.person_solid,
                            '我',
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              _buildGradientBorder(
                isLanternFestival: isLanternFestival,
                isCottonCandy: isCottonCandy,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBlurBody({
    required bool isLanternFestival,
    required bool isCottonCandy,
    Widget? child,
  }) {
    return SizedBox(
      height: barHeight,
      width: double.infinity,
      child: Stack(
        children: [
          Positioned.fill(
            child: RepaintBoundary(
              child: BackdropFilter(
                filter: ImageFilter.blur(
                  sigmaX: (widget.isNight || isLanternFestival || isCottonCandy)
                      ? 15
                      : 20,
                  sigmaY: (widget.isNight || isLanternFestival || isCottonCandy)
                      ? 15
                      : 20,
                ),
                child: Container(
                  decoration: BoxDecoration(
                    gradient: isLanternFestival
                        ? LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              const Color(0xFF5D2E2E).withValues(alpha: 0.3),
                              const Color(0xFF3E1A1A).withValues(alpha: 0.45),
                            ],
                          )
                        : (isCottonCandy
                            ? LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: widget.isNight
                                    ? [
                                        const Color(0xFF8676FF).withValues(alpha: 0.45),
                                        const Color(0xFFB19FFB).withValues(alpha: 0.55),
                                      ]
                                    : [
                                        const Color(
                                          0xFFFFE1E9,
                                        ).withValues(alpha: 0.5),
                                        const Color(
                                          0xFFFFCADB,
                                        ).withValues(alpha: 0.65),
                                      ],
                              )
                            : (widget.isNight
                                ? null
                                : LinearGradient(
                                    begin: Alignment.topCenter,
                                    end: Alignment.bottomCenter,
                                    colors: [
                                      const Color(
                                        0xFFB3E5FC,
                                      ).withValues(alpha: 0.5),
                                      const Color(
                                        0xFFE1F5FE,
                                      ).withValues(alpha: 0.3),
                                    ],
                                  ))),
                    color: (widget.isNight && !isLanternFestival && !isCottonCandy)
                        ? const Color(0xFF736675).withValues(alpha: 0.2)
                        : null,
                  ),
                ),
              ),
            ),
          ),
          ?child,
          _buildTopHighlight(
            isLanternFestival: isLanternFestival,
            isCottonCandy: isCottonCandy,
          ),
        ],
      ),
    );
  }

  Widget _buildTopHighlight({
    required bool isLanternFestival,
    required bool isCottonCandy,
  }) {
    if (widget.isNight || isLanternFestival || isCottonCandy) {
      return const SizedBox.shrink();
    }
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: Container(
        height: 0.8,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              const Color(0xFFFFF176).withValues(alpha: 0.0),
              const Color(0xFFFFF176).withValues(alpha: 0.6),
              const Color(0xFFFFF176).withValues(alpha: 0.0),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGradientBorder({
    required bool isLanternFestival,
    required bool isCottonCandy,
  }) {
    return Positioned.fill(
      child: IgnorePointer(
        child: CustomPaint(
          painter: NavBarGradientPainter(
            clipper: const NavBarClipper(
              notchRadius: notchRadius,
              barRadius: barRadius,
            ),
            strokeWidth: (widget.isNight || isLanternFestival || isCottonCandy)
                ? 2.5
                : 1.2,
            hasGlow: isCottonCandy && widget.isNight,
            glowGradient: isCottonCandy && widget.isNight
                ? LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      const Color(0xFFFFFFFF).withValues(alpha: 0.35),
                      const Color(0xFFE2C4FF).withValues(alpha: 0.25),
                      const Color(0xFFFFFFFF).withValues(alpha: 0.35),
                    ],
                  )
                : null,
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: isCottonCandy
                  ? (widget.isNight
                      ? [
                          const Color(0xFFFFFFFF).withValues(alpha: 0.7),
                          const Color(0xFFE2C4FF).withValues(alpha: 0.5),
                          const Color(0xFFFFFFFF).withValues(alpha: 0.7),
                        ]
                      : [
                          const Color(0xFFFFFFFF).withValues(alpha: 0.9),
                          const Color(0xFFFFD1E1).withValues(alpha: 0.6),
                          const Color(0xFFFFFFFF).withValues(alpha: 0.9),
                        ])
                  : ((isLanternFestival || widget.isNight)
                      ? const [
                          Color(0xFFEEBB3C),
                          Color(0xFFD4A373),
                          Color(0xFF5D2E2E),
                        ]
                      : [
                          const Color(0xFFFFF9C4).withValues(alpha: 0.8),
                          const Color(
                            0xFFB3E5FC,
                          ).withValues(alpha: 0.2),
                        ]),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildContentArea(double barMaxWidth) {
    return Positioned.fill(
      child: Center(
        child: Container(
          constraints: BoxConstraints(maxWidth: barMaxWidth),
          child: _buildSlimeAndNav(barMaxWidth),
        ),
      ),
    );
  }

  Widget _buildSlimeAndNav(double barMaxWidth) {
    return _buildSlimeInteractiveLayer(barMaxWidth);
  }

  Widget _buildSlimeInteractiveLayer(double barMaxWidth) {
    return MultiValueListenableBuilder(
      listenables: [_isIdleNotifier, _isMoodPickerOpenNotifier],
      builder: (context, values, _) {
        return Stack(
          alignment: Alignment.bottomCenter,
          clipBehavior: Clip.none,
          children: [
            Positioned(
              bottom: SlimeButton.bottomOffset,
              child: ValueListenableBuilder<bool>(
                valueListenable: UserState().isSlimeInBottomMenu,
                builder: (context, isInMenu, _) => SlimeButton(
                  key: _slimeKey,
                  isNight: widget.isNight,
                  isGlowing: true,
                  showSlime: isInMenu,
                  onTap: _openMoodPicker,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildNavItem(
    int index,
    IconData unselectedIcon,
    IconData selectedIcon,
    String label,
  ) {
    return Expanded(
      child: NavItem(
        defaultIcon: unselectedIcon,
        activeIcon: selectedIcon,
        label: label,
        index: index,
        currentIndex: widget.currentIndex,
        onTap: widget.onTap,
        isNight: widget.isNight,
      ),
    );
  }

  Future<void> _openMoodPicker() async {
    final draft = UserState().diaryDraft.value;
    if (draft != null) {
      _openDiaryEntry(draft.moodIndex, draft.intensity, tag: draft.tag);
      return;
    }
    final wasOnboarding = !UserState().hasFinishedOnboarding.value;
    if (wasOnboarding) {
      UserState().completeOnboarding();
    }
    _openDiaryEntry(null, 6.0);
  }

  void _openDiaryEntry(int? moodIndex, double intensity, {String? tag}) {
    UserState().isDiarySheetOpen.value = true;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => DiaryEditorPage(
          moodIndex: moodIndex,
          intensity: intensity,
          tag: tag,
        ),
      ),
    ).then((result) {
      UserState().isDiarySheetOpen.value = false;
      if (result is List && result.isNotEmpty) {
        widget.onSaveSuccess?.call(List<dynamic>.from(result));
      }
    });
  }
}

class _NavBarParticlesBg extends StatefulWidget {
  final String imagePath;
  final String decorationId;

  const _NavBarParticlesBg({
    required this.imagePath,
    required this.decorationId,
  });

  @override
  State<_NavBarParticlesBg> createState() => _NavBarParticlesBgState();
}

class _NavBarParticlesBgState extends State<_NavBarParticlesBg>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  Timer? _dismissTimer;
  bool _isFadingOut = false;
  bool _isGone = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
    _controller.forward();

    _dismissTimer = Timer(const Duration(seconds: 15), () {
      if (mounted) {
        setState(() {
          _isFadingOut = true;
        });
      }
    });
  }

  @override
  void didUpdateWidget(_NavBarParticlesBg oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.decorationId != widget.decorationId) {
      _controller.forward(from: 0.0);
      _dismissTimer?.cancel();
      _dismissTimer = Timer(const Duration(seconds: 15), () {
        if (mounted) {
          setState(() {
            _isFadingOut = true;
          });
        }
      });
      setState(() {
        _isFadingOut = false;
        _isGone = false;
      });
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _dismissTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isGone) return const SizedBox.shrink();

    return RepaintBoundary(
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 1000),
        opacity: _isFadingOut ? 0.0 : 1.0,
        onEnd: () {
          if (_isFadingOut) {
            setState(() {
              _isGone = true;
            });
          }
        },
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          final t = _controller.value;
          final bgOpacity = ((t - 0.3) / 0.7).clamp(0.0, 1.0);
          final double scaleProgress = ((t - 0.2) / 0.8).clamp(0.0, 1.0);
          final curve = widget.decorationId == 'bg_modules_animation_2'
              ? Curves.easeOutCubic
              : Curves.easeOutBack;
          final bgScale = 0.6 + 0.4 * curve.transform(scaleProgress);

          return RepaintBoundary(
            child: ShaderMask(
              shaderCallback: (rect) {
                return const LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.transparent, Colors.black],
                  stops: [0.0, 0.25],
                ).createShader(rect);
              },
              blendMode: BlendMode.dstIn,
              child: Stack(
                children: [
                  if (widget.decorationId == 'bg_modules_animation_1')
                    Positioned.fill(
                      child: Opacity(
                        opacity: bgOpacity,
                        child: Transform.scale(
                          scale: bgScale,
                          alignment: Alignment.bottomCenter,
                          child: Image.asset(
                            'assets/images/emoji/modules_animation/1_1.png',
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                    )
                    .animate(
                      onPlay: (controller) => controller.repeat(reverse: true),
                    )
                    .fadeIn(duration: 2500.ms, curve: Curves.easeInOut),
                  if (widget.decorationId == 'bg_modules_animation_2')
                    Positioned.fill(
                      child: Opacity(
                        opacity: bgOpacity,
                        child: Transform.scale(
                          scale: bgScale,
                          alignment: Alignment.bottomCenter,
                          child: Image.asset(
                            'assets/images/emoji/modules_animation/2-2.png',
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                    )
                    .animate()
                    .moveY(
                      begin: 40,
                      end: 0,
                      duration: 3500.ms,
                      curve: Curves.easeOutCubic,
                    ),
                  Positioned.fill(
                    child: Opacity(
                      opacity: bgOpacity,
                      child: Transform.scale(
                        scale: bgScale,
                        alignment: Alignment.bottomCenter,
                        child: Builder(
                          builder: (context) {
                            final img = Image.asset(widget.imagePath, fit: BoxFit.cover);
                            if (widget.decorationId == 'bg_modules_animation_2') {
                              return img
                                  .animate(onPlay: (controller) => controller.repeat(reverse: true))
                                  .fadeIn(duration: 2500.ms, curve: Curves.easeInOut);
                            }
                            return img;
                          },
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    ),
    );
  }
}
