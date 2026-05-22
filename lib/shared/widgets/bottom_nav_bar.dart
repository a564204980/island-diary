import 'dart:ui';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:island_diary/core/state/user_state.dart';
import 'package:island_diary/shared/widgets/slime_onboarding.dart';
import 'package:island_diary/shared/widgets/slime_button.dart';
import 'package:island_diary/shared/widgets/mood_picker/config/mood_config.dart';
import 'package:island_diary/features/record/presentation/pages/diary_editor_page.dart';
import 'package:island_diary/core/models/mascot_achievement.dart';

import 'nav_item.dart';
import 'nav_bar_clipper.dart';
import 'multi_value_listenable_builder.dart';

class BottomNavBar extends StatefulWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;
  final bool isNight;
  final Function(List<MascotAchievement>)? onSaveSuccess;
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
      final img = mood.imagePath;
      if (img != null) precacheImage(AssetImage(img), context);
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

    return SizedBox(
      height: SlimeButton.containerHeight,
      child: Stack(
        alignment: Alignment.bottomCenter,
        clipBehavior: Clip.none,
        children: [
          _buildBackground(barMaxWidth),
          _buildContentArea(barMaxWidth),
        ],
      ),
    );
  }

  Widget _buildBackground(double barMaxWidth) {
    final themeId = UserState().selectedIslandThemeId.value;
    final isLanternFestival = themeId == 'lantern_festival';
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
                color: isLanternFestival
                    ? const Color(0xFFFF8A65).withValues(alpha: 0.15)
                    : (isCottonCandy
                          ? const Color(0xFFFF94B8).withValues(alpha: 0.25)
                          : (widget.isNight
                                ? Colors.black.withValues(alpha: 0.18)
                                : const Color(
                                    0xFF1B3B5F,
                                  ).withValues(alpha: 0.2))),
                blurRadius:
                    (widget.isNight || isLanternFestival || isCottonCandy)
                    ? 20
                    : 40,
                offset: Offset(
                  0,
                  (widget.isNight || isLanternFestival || isCottonCandy)
                      ? 8
                      : 12,
                ),
              ),
              if (!widget.isNight && !isLanternFestival && !isCottonCandy)
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
                                      colors: widget.currentIndex == 1
                                          ? [
                                              const Color(
                                                0xFFF5E6CC,
                                              ).withValues(alpha: 0.6),
                                              const Color(
                                                0xFFFFF8E1,
                                              ).withValues(alpha: 0.4),
                                            ]
                                          : [
                                              const Color(
                                                0xFFB3E5FC,
                                              ).withValues(alpha: 0.5),
                                              const Color(
                                                0xFFE1F5FE,
                                              ).withValues(alpha: 0.3),
                                            ],
                                    ))),
                  color: (widget.isNight && !isLanternFestival && !isCottonCandy)
                      ? (widget.currentIndex == 1
                            ? const Color(0xFF4A3C31).withValues(alpha: 0.3)
                            : const Color(0xFF736675).withValues(alpha: 0.2))
                      : null,
                ),
              ),
            ),
          ),
          if (child != null) child,
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
    if (widget.isNight || isLanternFestival || isCottonCandy)
      return const SizedBox.shrink();
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
                      const Color(0xFFFFDFB4).withValues(alpha: 0.55),
                      const Color(0xFFE2C4FF).withValues(alpha: 0.45),
                      const Color(0xFFFFDFB4).withValues(alpha: 0.55),
                    ],
                  )
                : null,
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: isCottonCandy
                  ? (widget.isNight
                      ? [
                          const Color(0xFFFFDFB4).withValues(alpha: 0.9),
                          const Color(0xFFE2C4FF).withValues(alpha: 0.7),
                          const Color(0xFFFFDFB4).withValues(alpha: 0.9),
                        ]
                      : [
                          const Color(0xFFFFFFFF).withValues(alpha: 0.9),
                          const Color(0xFFFFD1E1).withValues(alpha: 0.6),
                          const Color(0xFFFFFFFF).withValues(alpha: 0.9),
                        ])
                  : ((isLanternFestival || widget.isNight)
                      ? (widget.currentIndex == 1
                            ? const [Color(0xFFEEBB3C), Color(0xFF3E2723)]
                            : const [
                                Color(0xFFEEBB3C),
                                Color(0xFFD4A373),
                                Color(0xFF5D2E2E),
                              ])
                      : [
                          const Color(0xFFFFF9C4).withValues(alpha: 0.8),
                          widget.currentIndex == 1
                              ? const Color(0xFFFFCC80).withValues(alpha: 0.3)
                              : const Color(
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
          child: ValueListenableBuilder<bool>(
            valueListenable: UserState().hasFinishedOnboarding,
            builder: (context, hasFinished, _) {
              if (!hasFinished) return _buildOnboarding();
              return _buildSlimeAndNav(barMaxWidth);
            },
          ),
        ),
      ),
    );
  }

  Widget _buildOnboarding() {
    return SlimeOnboarding(
      key: const ValueKey('slime_onboarding'),
      isNight: widget.isNight,
      onSlimeAction: _openMoodPicker,
      onComplete: () {
        UserState().completeOnboarding();
      },
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
        widget.onSaveSuccess?.call(List<MascotAchievement>.from(result));
      }
    });
  }
}
