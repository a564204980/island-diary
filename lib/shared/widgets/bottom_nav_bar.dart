import 'dart:ui';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:island_diary/core/state/user_state.dart';
import 'package:island_diary/shared/widgets/slime_onboarding.dart';
import 'package:island_diary/shared/widgets/slime_button.dart';
import 'package:island_diary/shared/widgets/sprite_dialogue.dart';
import 'package:island_diary/shared/widgets/mood_picker/mood_picker_sheet.dart';
import 'package:island_diary/core/services/slime_dialogue_service.dart';
import 'package:island_diary/shared/widgets/mood_picker/config/mood_config.dart';
import 'package:island_diary/features/record/presentation/pages/diary_editor_page.dart';

import 'nav_item.dart';
import 'nav_bar_clipper.dart';
import 'multi_value_listenable_builder.dart';

class BottomNavBar extends StatefulWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;
  final bool isNight;
  final VoidCallback? onSaveSuccess;
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
  bool _justFinishedOnboarding = false;
  late final ValueNotifier<bool> _showDialogueNotifier;
  late final ValueNotifier<String> _dialogueTextNotifier;
  late final ValueNotifier<bool> _isIdleNotifier;
  late final ValueNotifier<bool> _isMoodPickerOpenNotifier;

  Timer? _dialogueTimer;
  Timer? _idleTimer;
  final GlobalKey _slimeKey = GlobalKey();

  static const double barHeight = 76;
  static const double notchRadius = 52.0;
  static const double barRadius = 38.0;

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
    precacheImage(const AssetImage('assets/images/emoji/weixiao.png'), context);
    precacheImage(const AssetImage('assets/images/emoji/pedding.png'), context);
    precacheImage(const AssetImage('assets/images/paper.png'), context);
    precacheImage(const AssetImage('assets/images/paper2.png'), context);

    for (var mood in kMoods) {
      if (mood.imagePath != null) precacheImage(AssetImage(mood.imagePath!), context);
      if (mood.iconPath != null) precacheImage(AssetImage(mood.iconPath!), context);
    }
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

  void _startDialogueTimer() {
    _dialogueTimer?.cancel();
    _dialogueTimer = Timer(const Duration(seconds: 10), () {
      if (mounted) _showDialogueNotifier.value = false;
    });
  }

  void _startIdleTimer() {
    _idleTimer?.cancel();
    _idleTimer = Timer(const Duration(seconds: 30), () {
      if (mounted) _isIdleNotifier.value = true;
    });
  }

  void _refreshDialogue() {
    _dialogueTextNotifier.value = SlimeDialogueService().getDynamicDialogue();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final double barMaxWidth = screenWidth <= 600 ? screenWidth * 0.9 : 500.0;

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
    return Positioned(
      bottom: -6,
      left: 0,
      right: 0,
      child: Center(
        child: Container(
          constraints: BoxConstraints(maxWidth: barMaxWidth),
          margin: const EdgeInsets.symmetric(horizontal: 24),
          decoration: BoxDecoration(
            boxShadow: [
              BoxShadow(
                color: widget.isNight
                    ? Colors.black.withValues(alpha: 0.18)
                    : const Color(0xFF1B3B5F).withValues(alpha: 0.2),
                blurRadius: widget.isNight ? 20 : 40,
                offset: Offset(0, widget.isNight ? 8 : 12),
              ),
              if (!widget.isNight)
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
                clipper: const NavBarClipper(notchRadius: notchRadius, barRadius: barRadius),
                child: _buildBlurBody(
                  child: Center(
                    child: Container(
                      width: barMaxWidth * 0.88,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _buildNavItem(0, CupertinoIcons.house, CupertinoIcons.house_fill, '首页'),
                          _buildNavItem(1, CupertinoIcons.book, CupertinoIcons.book_fill, '记录'),
                          const SizedBox(width: 80),
                          _buildNavItem(3, CupertinoIcons.chart_bar, CupertinoIcons.chart_bar_fill, '数据'),
                          _buildNavItem(4, CupertinoIcons.person, CupertinoIcons.person_solid, '我'),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              _buildGradientBorder(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBlurBody({Widget? child}) {
    return Container(
      height: barHeight,
      width: double.infinity,
      child: Stack(
        children: [
          Positioned.fill(
            child: BackdropFilter(
              filter: ImageFilter.blur(
                sigmaX: widget.isNight ? 15 : 20,
                sigmaY: widget.isNight ? 15 : 20,
              ),
              child: Container(
                decoration: BoxDecoration(
                  gradient: widget.isNight
                      ? null
                      : LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: widget.currentIndex == 1
                              ? [
                                  const Color(0xFFF5E6CC).withValues(alpha: 0.6),
                                  const Color(0xFFFFF8E1).withValues(alpha: 0.4),
                                ]
                              : [
                                  const Color(0xFFB3E5FC).withValues(alpha: 0.5),
                                  const Color(0xFFE1F5FE).withValues(alpha: 0.3),
                                ],
                        ),
                  color: widget.isNight 
                      ? (widget.currentIndex == 1 
                          ? const Color(0xFF4A3C31).withValues(alpha: 0.3) 
                          : const Color(0xFF736675).withValues(alpha: 0.2))
                      : null,
                ),
              ),
            ),
          ),
          if (child != null) child,
          _buildTopHighlight(),
        ],
      ),
    );
  }

  Widget _buildTopHighlight() {
    if (widget.isNight) return const SizedBox.shrink();
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

  Widget _buildGradientBorder() {
    return Positioned.fill(
      child: IgnorePointer(
        child: CustomPaint(
          painter: NavBarGradientPainter(
            clipper: const NavBarClipper(notchRadius: notchRadius, barRadius: barRadius),
            strokeWidth: widget.isNight ? 2.5 : 1.2,
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: widget.isNight
                ? (widget.currentIndex == 1 
                    ? const [Color(0xFFEEBB3C), Color(0xFF3E2723)] 
                    : const [Color(0xFFEEBB3C), Color(0xFF1B2735)])
                : [
                    const Color(0xFFFFF9C4).withValues(alpha: 0.8),
                    widget.currentIndex == 1 
                        ? const Color(0xFFFFCC80).withValues(alpha: 0.3) 
                        : const Color(0xFFB3E5FC).withValues(alpha: 0.2),
                  ],
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
        setState(() => _justFinishedOnboarding = true);
        UserState().completeOnboarding();
      },
    );
  }

  Widget _buildSlimeAndNav(double barMaxWidth) {
    return _buildSlimeInteractiveLayer(barMaxWidth);
  }

  Widget _buildSlimeInteractiveLayer(double barMaxWidth) {
    return MultiValueListenableBuilder(
      listenables: [_isIdleNotifier, _showDialogueNotifier, _isMoodPickerOpenNotifier, _dialogueTextNotifier],
      builder: (context, values, _) {
        final isIdle = values[0] as bool;
        final showDialogue = values[1] as bool;
        final isMoodPickerOpen = values[2] as bool;
        final dialogue = values[3] as String;

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
                  assetPath: isIdle ? 'assets/images/emoji/pedding.png' : 'assets/images/emoji/weixiao.png',
                  frameCount: isIdle ? 1 : 9,
                  isPlaying: showDialogue && !isIdle,
                  onTap: _openMoodPicker,
                ),
              ),
            ),
            if (!_justFinishedOnboarding)
              _buildDialogue(showDialogue && !isMoodPickerOpen && !widget.forceHideDialogue, dialogue),
          ],
        );
      },
    );
  }

  Widget _buildDialogue(bool visible, String text) {
    return Positioned(
      bottom: 124.0,
      child: IgnorePointer(
        ignoring: !visible,
        child: SpriteDialogue(
          text: text,
          useTypewriter: false,
          onNext: () {
            _dialogueTimer?.cancel();
            _showDialogueNotifier.value = false;
          },
        ).animate(target: visible ? 1 : 0).fade(duration: 400.ms).scale(
              begin: const Offset(0.9, 0.9),
              duration: 400.ms,
              curve: Curves.easeOutBack,
            ),
      ),
    );
  }

  Widget _buildNavItem(int index, IconData unselectedIcon, IconData selectedIcon, String label) {
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
    // 如果有草稿，直接进入编辑器
    if (draft != null) {
      _openDiaryEntry(draft.moodIndex, draft.intensity, tag: draft.tag);
      return;
    }

    final wasOnboarding = !UserState().hasFinishedOnboarding.value;
    
    // 如果不是在进行新手引导，则直接进入编辑器（初始：不选心情）
    if (!wasOnboarding) {
      _openDiaryEntry(null, 6.0);
      return;
    }

    // 只有在新手引导时才强制先选心情（或者用户明确想选心情的情况，但目前主要需求是快）
    _isMoodPickerOpenNotifier.value = true;
    _showDialogueNotifier.value = false;
    _isIdleNotifier.value = false;
    _dialogueTimer?.cancel();
    _idleTimer?.cancel();

    final completer = Completer<Map<String, dynamic>?>();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return completer.complete(null);
      final result = await showGeneralDialog<Map<String, dynamic>>(
        context: context,
        barrierDismissible: true,
        barrierLabel: 'MoodPicker',
        barrierColor: Colors.black.withValues(alpha: 0.6),
        transitionDuration: const Duration(milliseconds: 500),
        transitionBuilder: (context, animation, secondaryAnimation, child) {
          final curvedAnimation =
              CurvedAnimation(parent: animation, curve: Curves.easeOutBack);
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

    if (mounted) {
      _isMoodPickerOpenNotifier.value = false;
      _isIdleNotifier.value = false;
      if (wasOnboarding) {
        setState(() => _justFinishedOnboarding = true);
        _refreshDialogue();
        UserState().completeOnboarding();
      }
      _startIdleTimer();
      if (result != null) {
        _openDiaryEntry(result['index'], result['intensity'], tag: result['tag']);
      }
    }
  }

  void _openDiaryEntry(int? moodIndex, double intensity, {String? tag}) {
    UserState().isDiarySheetOpen.value = true;
    Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (context) => DiaryEditorPage(
          moodIndex: moodIndex,
          intensity: intensity,
          tag: tag,
        ),
      ),
    ).then((success) {
      UserState().isDiarySheetOpen.value = false;
      if (success == true && widget.onSaveSuccess != null) widget.onSaveSuccess!();
    });
  }
}
