import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:island_diary/core/state/user_state.dart';
import 'package:island_diary/shared/widgets/sprite_animation.dart';
import 'package:island_diary/shared/widgets/sprite_dialogue.dart';
import 'package:island_diary/features/record/presentation/widgets/book_glow_hint.dart';
import 'package:island_diary/features/record/presentation/widgets/diary_history_overlay.dart';

class RecordPage extends StatefulWidget {
  const RecordPage({super.key});

  @override
  State<RecordPage> createState() => _RecordPageState();
}

class _RecordPageState extends State<RecordPage>
    with SingleTickerProviderStateMixin {
  late ScrollController _scrollController;
  late final ValueNotifier<double> _scrollOffsetNotifier;
  double _aspectRatio = 1.0;

  // 跳跃动画相关
  late AnimationController _jumpController;
  late Animation<double> _jumpAnimation;
  bool _isJumpStarted = false;
  bool _showDeskDialogue = false; // 控制桌面气泡显示
  bool _showBookHint = false; // 控制书籍互动提示显示
  Timer? _jumpTimer;
  Timer? _dialogueTimer; // 处理落地后的延迟
  Timer? _bookHintTimer; // 控制书籍提示出现的时机

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _scrollOffsetNotifier = ValueNotifier<double>(0.0);
    _resolveImageSize();

    _jumpController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 4000), // 总计 4 秒：1s 跳 + 2s 停 + 1s 跳
    );

    _jumpAnimation = CurvedAnimation(
      parent: _jumpController,
      curve: Curves.linear,
    );

    if (!UserState().hasSeenRecordGuidance.value) {
      _jumpController.addStatusListener((status) {
        if (status == AnimationStatus.completed) {
          _dialogueTimer = Timer(const Duration(milliseconds: 500), () {
            if (mounted) {
              setState(() => _showDeskDialogue = true);
            }
          });
          _bookHintTimer = Timer(const Duration(milliseconds: 1700), () {
            if (mounted) {
              setState(() => _showBookHint = true);
            }
          });
        }
      });

      _jumpTimer = Timer(const Duration(milliseconds: 1500), () {
        if (mounted) {
          setState(() => _isJumpStarted = true);
          UserState().isSlimeInBottomMenu.value = false;
          _jumpController.forward();
          UserState().completeRecordGuidance();
        }
      });
    } else {
      _showBookHint = true;
    }
  }

  void _resolveImageSize() {
    const path = 'assets/images/decoration/furniture/house.png';
    final stream = const AssetImage(path).resolve(ImageConfiguration.empty);
    stream.addListener(
      ImageStreamListener((ImageInfo info, bool _) {
        if (mounted) {
          setState(() {
            _aspectRatio = info.image.width / info.image.height;
          });
          _centerBackground();
        }
      }),
    );
  }

  void _centerBackground() {
    if (!mounted) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (_scrollController.hasClients &&
          _scrollController.position.hasContentDimensions &&
          _scrollController.position.maxScrollExtent > 0) {
        final double maxScroll = _scrollController.position.maxScrollExtent;
        _scrollController.jumpTo(maxScroll / 2);
      }
    });
  }

  @override
  void dispose() {
    _jumpTimer?.cancel();
    _dialogueTimer?.cancel();
    _bookHintTimer?.cancel();
    _jumpController.dispose();
    _scrollController.dispose();
    _scrollOffsetNotifier.dispose();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      UserState().isSlimeInBottomMenu.value = true;
    });
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<String>(
      valueListenable: UserState().themeMode,
      builder: (context, themeMode, _) {
        final bool isNight = UserState().isNight;
        const String bgPath = 'assets/images/decoration/furniture/house.png';

        final Color bgColor = isNight
            ? const Color(0xFF13131F)
            : const Color(0xFFD2B48C);

        return Scaffold(
          backgroundColor: bgColor,
          body: Stack(
            children: [
              Positioned.fill(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final isLandscape =
                        constraints.maxWidth > constraints.maxHeight;
                    final double currentBgScale = isLandscape ? 1.4 : 1.0;

                    final double h = constraints.maxHeight * currentBgScale;
                    final double fullWidth = h * _aspectRatio;

                    // 重新对 3x 画面进行交互点微调
                    final deskRelX = fullWidth * 0.44;
                    final deskY = h * 0.62;
                    final bedRelX = fullWidth * 0.74;
                    final bedY = h * 0.64;

                    return NotificationListener<ScrollNotification>(
                      onNotification: (notification) {
                        if (notification is ScrollUpdateNotification) {
                          _scrollOffsetNotifier.value =
                              notification.metrics.pixels;
                        }
                        return false;
                      },
                      child: SingleChildScrollView(
                        controller: _scrollController,
                        scrollDirection: Axis.horizontal,
                        physics: const BouncingScrollPhysics(),
                        child: Stack(
                          clipBehavior: Clip.none,
                          children: [
                            _buildBackground(bgPath, h, fullWidth),
                            if (_isJumpStarted)
                              _buildSlimeJumpAnimation(
                                h,
                                bedRelX,
                                bedY,
                                deskRelX,
                                deskY,
                                constraints,
                              ),
                            if (_showBookHint) _buildBookHint(deskRelX, deskY),
                            if (_showDeskDialogue)
                              _buildDeskDialogue(deskRelX, deskY),
                            SizedBox(width: fullWidth, height: h),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildBackground(String bgPath, double h, double w) {
    return Positioned.fill(
      child: _ParallaxBackground(
        bgPath: bgPath,
        h: h,
        w: w,
        scrollOffsetNotifier: _scrollOffsetNotifier,
        scrollController: _scrollController,
      ),
    );
  }

  Widget _buildSlimeJumpAnimation(
    double h,
    double bedRelX,
    double bedY,
    double deskRelX,
    double deskY,
    BoxConstraints constraints,
  ) {
    return Positioned.fill(
      child: AnimatedBuilder(
        animation: _jumpAnimation,
        builder: (context, child) {
          final rawT = _jumpAnimation.value;
          final isWide = constraints.maxWidth > 600;
          final menuBottomOffset = isWide ? 60.0 : 40.0;

          double scrollOffset = 0;
          if (_scrollController.hasClients &&
              _scrollController.position.hasContentDimensions &&
              _scrollController.position.hasPixels) {
            scrollOffset = _scrollController.offset;
          }

          final startP = Offset(
            scrollOffset + constraints.maxWidth / 2,
            h - menuBottomOffset - 24.0,
          );
          final bedP = Offset(bedRelX, bedY);
          final deskP = Offset(deskRelX, deskY);

          late double curX, curY, shadowY, slimeScale;
          double jumpArc = 0;

          if (rawT < 0.25) {
            final t = Curves.easeInOut.transform(rawT / 0.25);
            curX = startP.dx + (bedP.dx - startP.dx) * t;
            shadowY = startP.dy + (bedP.dy - startP.dy) * t;
            jumpArc = (rawT < 0.25)
                ? (4 * (rawT / 0.25) * (1 - rawT / 0.25) * 140)
                : 0;
            curY = shadowY - jumpArc;
            slimeScale = 0.8 + (0.15 * t);
          } else if (rawT < 0.75) {
            curX = bedP.dx;
            curY = bedP.dy;
            shadowY = bedP.dy;
            jumpArc = 0;
            slimeScale = 0.95;
          } else {
            final t = Curves.easeInOut.transform((rawT - 0.75) / 0.25);
            curX = bedP.dx + (deskP.dx - bedP.dx) * t;
            shadowY = bedP.dy + (deskP.dy - bedP.dy) * t;
            jumpArc = (4 * t * (1 - t) * 80);
            curY = shadowY - jumpArc;
            slimeScale = 0.95 + (0.05 * t);
          }

          return Stack(
            clipBehavior: Clip.none,
            children: [
              Positioned(
                left: curX - 16,
                top: shadowY - 4,
                child: Opacity(
                  opacity: (0.15 + 0.15 * (jumpArc / 140)).clamp(0, 0.3),
                  child: Container(
                    width: 32,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: Colors.black,
                      borderRadius: BorderRadius.all(Radius.elliptical(16, 4)),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black,
                          blurRadius: 8,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              Positioned(
                left: curX - 21,
                top: curY - 42,
                child: Transform.scale(
                  scale: slimeScale,
                  child: const SpriteAnimation(
                    assetPath: 'assets/images/emoji/weixiao.png',
                    frameCount: 9,
                    duration: Duration(milliseconds: 800),
                    size: 42.0,
                    isPlaying: true,
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildBookHint(double deskRelX, double deskY) {
    return Positioned(
      left: deskRelX - 2,
      top: deskY - 110,
      child:
          Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildHintLabel(),
                  const SizedBox(height: 4),
                  BookGlowHint(
                    onTap: () async {
                      if (mounted) {
                        setState(() {
                          _showDeskDialogue = false;
                          _showBookHint = false;
                          _isJumpStarted = false;
                        });
                        UserState().isSlimeInBottomMenu.value = true;
                        await _openHistoryTimeline();
                        if (mounted) setState(() => _showBookHint = true);
                      }
                    },
                  ),
                ],
              )
              .animate()
              .fadeIn(duration: 800.ms)
              .scale(
                begin: const Offset(0.5, 0.5),
                duration: 600.ms,
                curve: Curves.easeOutBack,
              ),
    );
  }

  Widget _buildHintLabel() {
    return ClipRRect(
          borderRadius: BorderRadius.circular(14),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.4),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: Colors.white.withOpacity(0.2),
                  width: 0.5,
                ),
              ),
              child: const Text(
                "旧日回忆",
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF5D4037),
                  fontFamily: 'LXGWWenKai',
                ),
              ),
            ),
          ),
        )
        .animate(onPlay: (c) => c.repeat(reverse: true))
        .moveY(
          begin: 0,
          end: -4,
          duration: 1.5.seconds,
          curve: Curves.easeInOut,
        );
  }

  Widget _buildDeskDialogue(double deskRelX, double deskY) {
    return Positioned(
      left: deskRelX - 108,
      top: deskY - 130,
      child:
          SpriteDialogue(
                text: "点点旁边的书，看看我为你准备了什么",
                useTypewriter: true,
                onNext: () => setState(() => _showDeskDialogue = false),
              )
              .animate()
              .fade(duration: 400.ms)
              .scale(
                begin: const Offset(0.8, 0.8),
                duration: 400.ms,
                curve: Curves.easeOutBack,
              ),
    );
  }

  Future<void> _openHistoryTimeline() async {
    await showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'HistoryTimeline',
      barrierColor: Colors.black.withOpacity(0.4),
      transitionDuration: const Duration(milliseconds: 600),
      pageBuilder: (context, anim1, anim2) {
        return DiaryHistoryOverlay(onClose: () => Navigator.pop(context));
      },
      transitionBuilder: (context, animation, secondaryAnimation, child) {
        return FadeTransition(opacity: animation, child: child);
      },
    );
  }
}

class _ParallaxBackground extends StatelessWidget {
  final String bgPath;
  final double h;
  final double w;
  final ValueNotifier<double> scrollOffsetNotifier;
  final ScrollController scrollController;

  const _ParallaxBackground({
    required this.bgPath,
    required this.h,
    required this.w,
    required this.scrollOffsetNotifier,
    required this.scrollController,
  });

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<double>(
      valueListenable: scrollOffsetNotifier,
      builder: (context, currentScroll, _) {
        double currentScale = 1.05;

        if (scrollController.hasClients) {
          try {
            final double maxScroll = scrollController.position.maxScrollExtent;
            if (maxScroll > 0) {
              final double normalizedScroll = currentScroll.clamp(0, maxScroll);
              final double scrollRatio = normalizedScroll / maxScroll;

              if (scrollRatio < 0.2) {
                currentScale = 1.05 + (0.13 * (scrollRatio / 0.2));
              } else if (scrollRatio < 0.5) {
                currentScale = 1.18 + (0.07 * ((scrollRatio - 0.2) / 0.3));
              } else if (scrollRatio < 0.8) {
                currentScale = 1.25 - (0.07 * ((scrollRatio - 0.5) / 0.3));
              } else {
                currentScale = 1.18 - (0.13 * ((scrollRatio - 0.8) / 0.2));
              }
            }
          } catch (_) {}
        }

        return Transform.scale(
          scale: currentScale,
          alignment: Alignment.center,
          child: Image.asset(bgPath, height: h, width: w, fit: BoxFit.cover),
        );
      },
    );
  }
}
