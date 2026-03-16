import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:island_diary/core/state/user_state.dart';
import 'package:island_diary/shared/widgets/sprite_animation.dart';
import 'package:island_diary/shared/widgets/sprite_dialogue.dart';

class RecordPage extends StatefulWidget {
  const RecordPage({super.key});

  @override
  State<RecordPage> createState() => _RecordPageState();
}

class _RecordPageState extends State<RecordPage>
    with SingleTickerProviderStateMixin {
  late ScrollController _scrollController;
  double _aspectRatio = 1.0;

  // 跳跃动画相关
  late AnimationController _jumpController;
  late Animation<double> _jumpAnimation;
  bool _isJumpStarted = false;
  bool _showDeskDialogue = false; // 【新增】控制桌面气泡显示
  Timer? _jumpTimer;
  Timer? _dialogueTimer; // 【新增】处理落地后的延迟

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _resolveImageSize();

    _jumpController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 4000), // 总计 4 秒：1s 跳 + 2s 停 + 1s 跳
    );

    _jumpAnimation = CurvedAnimation(
      parent: _jumpController,
      curve: Curves.linear, // 手动在各个阶段做缓动处理，外层用线性
    );

    // 落地监听：完成后等待 0.5s 弹出对话
    _jumpController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        _dialogueTimer = Timer(const Duration(milliseconds: 500), () {
          if (mounted) {
            setState(() => _showDeskDialogue = true);
          }
        });
      }
    });

    // 延迟 1.5s 触发跳跃
    _jumpTimer = Timer(const Duration(milliseconds: 1500), () {
      if (mounted) {
        setState(() => _isJumpStarted = true);
        UserState().isSlimeInBottomMenu.value = false;
        _jumpController.forward();
      }
    });
  }

  void _resolveImageSize() {
    const path = 'assets/images/indoor.png';
    final ImageStream stream = const AssetImage(
      path,
    ).resolve(ImageConfiguration.empty);
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
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        final double maxScroll = _scrollController.position.maxScrollExtent;
        _scrollController.jumpTo(maxScroll / 2);
      }
    });
  }

  @override
  void dispose() {
    _jumpTimer?.cancel();
    _dialogueTimer?.cancel();
    _jumpController.dispose();
    _scrollController.dispose();
    // 恢复小软状态
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
        final String bgPath = isNight
            ? 'assets/images/indoor3.png'
            : 'assets/images/indoor.png';

        const double bgScale = 1.0;
        const double leftBuffer = 175.0;
        const double rightBuffer = 325.0;

        final Color bgColor = isNight
            ? const Color(0xFF13131F)
            : const Color(0xFFD2B48C);

        return Scaffold(
          backgroundColor: bgColor,
          body: Stack(
            children: [
              // 1. 全景背景层
              Positioned.fill(
                child: ListenableBuilder(
                  listenable: _scrollController,
                  builder: (context, child) {
                    return LayoutBuilder(
                      builder: (context, constraints) {
                        final double h = constraints.maxHeight * bgScale;
                        final double fullWidth = h * _aspectRatio;

                        double currentScale = 1.05;
                        if (_scrollController.hasClients) {
                          final double maxScroll =
                              _scrollController.position.maxScrollExtent;
                          final double currentScroll = _scrollController.offset
                              .clamp(0, maxScroll);
                          final double scrollRatio = maxScroll > 0
                              ? currentScroll / maxScroll
                              : 0.5;

                          if (scrollRatio < 0.2) {
                            currentScale = 1.05 + (0.13 * (scrollRatio / 0.2));
                          } else if (scrollRatio < 0.5) {
                            currentScale =
                                1.18 + (0.07 * ((scrollRatio - 0.2) / 0.3));
                          } else if (scrollRatio < 0.8) {
                            currentScale =
                                1.25 - (0.07 * ((scrollRatio - 0.5) / 0.3));
                          } else {
                            currentScale =
                                1.18 - (0.13 * ((scrollRatio - 0.8) / 0.2));
                          }
                        }

                        // 计算位置
                        final deskRelX = fullWidth * 0.456 - leftBuffer;
                        final deskY = h * 0.546;
                        final bedRelX =
                            fullWidth * 0.56 - leftBuffer; // 校准：向右平移至床铺中心
                        final bedY = h * 0.58; // 校准：高度调至与床面契合

                        return Stack(
                          children: [
                            SingleChildScrollView(
                              controller: _scrollController,
                              scrollDirection: Axis.horizontal,
                              physics: const BouncingScrollPhysics(),
                              child: Stack(
                                clipBehavior: Clip.none,
                                children: [
                                  Positioned(
                                    left: -leftBuffer,
                                    top: 0,
                                    bottom: 0,
                                    child: Transform.scale(
                                      scale: currentScale,
                                      alignment: Alignment.center,
                                      child: Image.asset(
                                        bgPath,
                                        height: h,
                                        fit: BoxFit.fitHeight,
                                      ),
                                    ),
                                  ),
                                  // --- 小软跳出的动画内容 ---
                                  if (_isJumpStarted)
                                    Positioned.fill(
                                      child: AnimatedBuilder(
                                        animation: _jumpAnimation,
                                        builder: (context, child) {
                                          final rawT = _jumpAnimation.value;

                                          // 定义三个关键点
                                          final isWide =
                                              constraints.maxWidth > 600;
                                          final menuBottomOffset = isWide
                                              ? 60.0
                                              : 40.0;

                                          final startP = Offset(
                                            _scrollController.offset +
                                                constraints.maxWidth / 2,
                                            h - menuBottomOffset - 24.0,
                                          );
                                          final bedP = Offset(bedRelX, bedY);
                                          final deskP = Offset(deskRelX, deskY);

                                          late double curX,
                                              curY,
                                              shadowY,
                                              currentScale;
                                          double jumpArc = 0;

                                          if (rawT < 0.25) {
                                            // 1. 第一跳：底栏 -> 床铺 (0% - 25%)
                                            final t = Curves.easeInOut
                                                .transform(rawT / 0.25);
                                            curX =
                                                startP.dx +
                                                (bedP.dx - startP.dx) * t;
                                            shadowY =
                                                startP.dy +
                                                (bedP.dy - startP.dy) * t;
                                            jumpArc = sin(t * pi) * 140;
                                            curY = shadowY - jumpArc;
                                            currentScale = 0.8 + (0.15 * t);
                                          } else if (rawT < 0.75) {
                                            // 2. 停留：在床上等待 (25% - 75%，持续 2s)
                                            curX = bedP.dx;
                                            curY = bedP.dy;
                                            shadowY = bedP.dy;
                                            jumpArc = 0;
                                            currentScale = 0.95;
                                          } else {
                                            // 3. 第二跳：床铺 -> 书桌 (75% - 100%)
                                            final t = Curves.easeInOut
                                                .transform(
                                                  (rawT - 0.75) / 0.25,
                                                );
                                            curX =
                                                bedP.dx +
                                                (deskP.dx - bedP.dx) * t;
                                            shadowY =
                                                bedP.dy +
                                                (deskP.dy - bedP.dy) * t;
                                            jumpArc = sin(t * pi) * 80;
                                            curY = shadowY - jumpArc;
                                            currentScale = 0.95 + (0.05 * t);
                                          }

                                          return Stack(
                                            clipBehavior: Clip.none,
                                            children: [
                                              // 阴影
                                              Positioned(
                                                left: curX - 16,
                                                top: shadowY - 4,
                                                child: Opacity(
                                                  opacity:
                                                      (0.15 +
                                                              0.15 *
                                                                  (jumpArc /
                                                                      140))
                                                          .clamp(0, 0.3),
                                                  child: Container(
                                                    width: 32,
                                                    height: 8,
                                                    decoration:
                                                        const BoxDecoration(
                                                          color: Colors.black,
                                                          borderRadius:
                                                              BorderRadius.all(
                                                                Radius.elliptical(
                                                                  16,
                                                                  4,
                                                                ),
                                                              ),
                                                          boxShadow: [
                                                            BoxShadow(
                                                              color:
                                                                  Colors.black,
                                                              blurRadius: 8,
                                                              spreadRadius: 2,
                                                            ),
                                                          ],
                                                        ),
                                                  ),
                                                ),
                                              ),
                                              // 小软本人
                                              Positioned(
                                                left: curX - 21,
                                                top: curY - 42,
                                                child: Transform.scale(
                                                  scale: currentScale,
                                                  child: const SpriteAnimation(
                                                    assetPath:
                                                        'assets/images/emoji/weixiao.png',
                                                    frameCount: 9,
                                                    duration: Duration(
                                                      milliseconds: 800,
                                                    ),
                                                    size: 42.0,
                                                    isPlaying: true,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          );
                                        },
                                      ),
                                    ),
                                  if (_showDeskDialogue)
                                    Positioned(
                                      left: deskRelX - 108, // 居中偏移调整
                                      top: deskY - 130, // 调近距离，之前是 180
                                      child:
                                          SpriteDialogue(
                                                text: "点点旁边的书，看看我为你准备了什么",
                                                useTypewriter: true,
                                                onNext: () {
                                                  setState(
                                                    () => _showDeskDialogue =
                                                        false,
                                                  );
                                                },
                                              )
                                              .animate()
                                              .fade(duration: 400.ms)
                                              .scale(
                                                begin: const Offset(0.8, 0.8),
                                                duration: 400.ms,
                                                curve: Curves.easeOutBack,
                                              ),
                                    ),
                                  SizedBox(
                                    width: fullWidth - leftBuffer - rightBuffer,
                                    height: h,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        );
                      },
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
}
