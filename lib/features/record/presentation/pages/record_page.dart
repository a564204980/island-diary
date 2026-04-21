import 'dart:async';
import 'dart:ui';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:island_diary/core/state/user_state.dart';
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
  bool _showBookHint = true; // 始终显示书籍互动的提示
  Timer? _bookHintTimer; 
  Timer? _thoughtTimer; 

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _scrollOffsetNotifier = ValueNotifier<double>(0.0);
    _resolveImageSize();
    UserState().decorationSnapshot.addListener(_onSnapshotChanged);

    // 默认显示互动提示
    _showBookHint = true;
  }

  void _onSnapshotChanged() {
    if (mounted) {
      _resolveImageSize();
    }
  }

  void _resolveImageSize() {
    final snapshot = UserState().decorationSnapshot.value;
    if (snapshot != null) {
      final image = Image.memory(snapshot).image;
      image
          .resolve(ImageConfiguration.empty)
          .addListener(
            ImageStreamListener((ImageInfo info, bool _) {
              if (mounted) {
                setState(() {
                  _aspectRatio = info.image.width / info.image.height;
                });
                _centerBackground();
              }
            }),
          );
    } else {
      _aspectRatio = 16 / 9; // 默认比例
      _centerBackground();
    }
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
    _bookHintTimer?.cancel();
    _thoughtTimer?.cancel();
    _scrollController.dispose();
    _scrollOffsetNotifier.dispose();
    UserState().decorationSnapshot.removeListener(_onSnapshotChanged);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<String>(
      valueListenable: UserState().themeMode,
      builder: (context, themeMode, _) {
        return ValueListenableBuilder<Color>(
          valueListenable: UserState().currentThemeColor,
          builder: (context, themeColor, _) {
            return Scaffold(
              backgroundColor: themeColor,
              body: Stack(
                children: [
                  // 1. 高质感材质底层 (Paper Texture)
                  Positioned.fill(
                    child: Image.asset(
                      'assets/images/paper_bg.png',
                      fit: BoxFit.cover,
                    ),
                  ),
                  // 2. 气氛滤镜层 (支持昼夜动态过渡)
                  Positioned.fill(
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 1000),
                      decoration: BoxDecoration(
                        gradient: UserState().isNight
                            ? LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [
                                  const Color(0xFF1E1026).withValues(alpha: 0.88), // 暖紫
                                  const Color(0xFF0F0B1E).withValues(alpha: 0.96), // 极暗
                                ],
                              )
                            : LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [
                                  const Color(0xFFFFFFFF).withValues(alpha: 0.1),
                                  const Color(0xFFE5DED4).withValues(alpha: 0.35),
                                ],
                              ),
                      ),
                    ),
                  ),
                  Positioned.fill(
                    child: ValueListenableBuilder<Uint8List?>(
                      valueListenable: UserState().decorationSnapshot,
                      builder: (context, snapshot, _) {
                        return LayoutBuilder(
                          builder: (context, constraints) {
                            if (constraints.maxHeight <= 0 ||
                                constraints.maxWidth <= 0) {
                              return const SizedBox.shrink();
                            }

                            final isLandscape =
                                constraints.maxWidth > constraints.maxHeight;
                            double scale = isLandscape ? 1.4 : 1.0;

                            if (snapshot != null) {
                              double targetH = constraints.maxHeight * 0.68; // 提升显示比例
                              double targetW = targetH * _aspectRatio;

                              if (targetW > constraints.maxWidth * 0.95) {
                                targetW = constraints.maxWidth * 0.95;
                                targetH = targetW / _aspectRatio;
                              }
                              scale = targetH / constraints.maxHeight;
                            }

                            final h = constraints.maxHeight * scale;
                            final fullWidth = h * _aspectRatio;

                            // 坐标系数 (0.50 为中心)
                            final deskRelX = fullWidth * 0.40; // 书桌位置
                            final deskY = h * 0.58;

                            return NotificationListener<ScrollNotification>(
                              onNotification: (notification) {
                                if (notification is ScrollUpdateNotification) {
                                  _scrollOffsetNotifier.value =
                                      notification.metrics.pixels;
                                }
                                return false;
                              },
                              child: Center(
                                child: SizedBox(
                                  width: fullWidth,
                                  height: h,
                                  child: Stack(
                                    clipBehavior: Clip.none,
                                    children: [
                                      _buildBackground(
                                        null,
                                        snapshot,
                                        h,
                                        fullWidth,
                                        Colors.transparent,
                                      ),
                                      if (_showBookHint)
                                        _buildBookHint(deskRelX, deskY),
                                    ],
                                  ),
                                ),
                              ),
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
      },
    );
  }

  Widget _buildBackground(
    String? bgPath,
    Uint8List? snapshot,
    double h,
    double w,
    Color bgColor,
  ) {
    return Positioned.fill(
      child: _ParallaxBackground(
        bgPath: bgPath,
        snapshot: snapshot,
        h: h,
        w: w,
        bgColor: bgColor,
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
                          _showBookHint = false;
                        });
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
                color: Colors.white.withValues(alpha: 0.4),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.2),
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

  Future<void> _openHistoryTimeline() async {
    await showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'HistoryTimeline',
      barrierColor: Colors.black.withValues(alpha: 0.4),
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
  final String? bgPath;
  final Uint8List? snapshot;
  final double h;
  final double w;
  final Color bgColor;

  const _ParallaxBackground({
    this.bgPath,
    this.snapshot,
    required this.h,
    required this.w,
    required this.bgColor,
  });

  @override
  Widget build(BuildContext context) {
    if (snapshot != null) {
      return Image.memory(snapshot!, height: h, width: w, fit: BoxFit.cover);
    }
    return Container(color: bgColor, width: w, height: h);
  }
}
