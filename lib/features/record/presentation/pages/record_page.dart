import 'dart:async';
import 'dart:ui';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:island_diary/core/state/user_state.dart';
import 'package:island_diary/features/record/presentation/widgets/diary_history_overlay.dart';
import 'package:island_diary/shared/widgets/decoration/firefly_atmosphere.dart';
import 'package:island_diary/features/record/presentation/pages/decoration_page.dart';
import 'package:island_diary/features/record/presentation/pages/diary_photo_wall_page.dart';

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
  Timer? _thoughtTimer; 

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _scrollOffsetNotifier = ValueNotifier<double>(0.0);
    _resolveImageSize();
    UserState().decorationSnapshot.addListener(_onSnapshotChanged);
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
                  // 1. 高质感材质底层 (Paper Texture / Night Image)
                  Positioned.fill(
                    child: Image.asset(
                      UserState().isNight 
                          ? 'assets/images/login_bg_1.png' 
                          : 'assets/images/paper_bg.png',
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
                                  const Color(0xFF1B1629).withValues(alpha: 0.4), // 显著降低透明度，透出背景图
                                  const Color(0xFF0A0814).withValues(alpha: 0.6),
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
                  // 深夜氛围装饰层 (星云、萤火虫)
                  if (UserState().isNight) ...[
                    _buildNightAtmosphere(),
                    const FireflyAtmosphere(),
                  ],
                  
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

                            return Center(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  // 1. 房屋快照容器
                                  Container(
                                    width: double.infinity,
                                    height: constraints.maxHeight * 0.65,
                                    decoration: UserState().isNight ? BoxDecoration(
                                      shape: BoxShape.circle,
                                      boxShadow: [
                                        BoxShadow(
                                          color: const Color(0xFF818CF8).withValues(alpha: 0.15),
                                          blurRadius: 100,
                                          spreadRadius: 20,
                                        ),
                                      ],
                                    ) : null,
                                    child: Center(
                                      child: SizedBox(
                                        width: fullWidth,
                                        height: h,
                                        child: _buildBackground(
                                          null,
                                          snapshot,
                                          h,
                                          fullWidth,
                                          Colors.transparent,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        );
                      },
                    ),
                  ),
                  
                  // 3. 侧边功能缎带 (方案 A)
                  _buildSideActionRibbon(),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildNightAtmosphere() {
    return Positioned.fill(
      child: IgnorePointer(
        child: Stack(
          children: [
            // 1. 背景星云光晕 - 紫色
            Positioned(
              top: -100,
              right: -50,
              child: Container(
                width: 300,
                height: 300,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFF6366F1).withValues(alpha: 0.08),
                ),
              ).animate(onPlay: (c) => c.repeat(reverse: true)).move(end: const Offset(40, 20), duration: 10.seconds),
            ),
            // 2. 背景星云光晕 - 蓝色
            Positioned(
              bottom: 150,
              left: -80,
              child: Container(
                width: 250,
                height: 250,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFF0EA5E9).withValues(alpha: 0.06),
                ),
              ).animate(onPlay: (c) => c.repeat(reverse: true)).move(end: const Offset(30, -30), duration: 12.seconds),
            ),
          ],
        ),
      ),
    );
  }


  Widget _buildSideActionRibbon() {
    return Positioned(
      right: 12,
      top: 0,
      bottom: 0,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildStampItem(
              icon: Icons.auto_stories_rounded,
              label: "回忆",
              onTap: () => _openHistoryTimeline(),
              delay: 300.ms,
            ),
            const SizedBox(height: 16),
            _buildStampItem(
              icon: Icons.collections_rounded,
              label: "照片墙",
              onTap: () => _openPhotoWall(),
              delay: 400.ms,
            ),
            const SizedBox(height: 16),
            _buildStampItem(
              icon: Icons.bar_chart_rounded,
              label: "统计",
              onTap: () {},
              delay: 500.ms,
              opacity: 0.5,
            ),
            const SizedBox(height: 16),
            _buildStampItem(
              icon: Icons.emoji_events_rounded,
              label: "成就",
              onTap: () {},
              delay: 600.ms,
              opacity: 0.5,
            ),
            const SizedBox(height: 16),
            _buildStampItem(
              icon: Icons.chair_outlined,
              label: "装修",
              onTap: () => _openDecorationPage(),
              delay: 750.ms,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStampItem({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    required Duration delay,
    double opacity = 1.0,
  }) {
    final isNight = UserState().isNight;
    final primaryColor = isNight ? Colors.white.withValues(alpha: 0.9) : const Color(0xFF5D4037);
    
    return Opacity(
      opacity: opacity,
      child: GestureDetector(
        onTap: onTap,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isNight 
                    ? Colors.white.withValues(alpha: 0.1) 
                    : Colors.white.withValues(alpha: 0.65),
                border: Border.all(
                  color: isNight 
                      ? Colors.white.withValues(alpha: 0.2) 
                      : const Color(0xFF5D4037).withValues(alpha: 0.15),
                  width: 1.0,
                ),
                boxShadow: [
                  BoxShadow(
                    color: isNight 
                        ? const Color(0xFF818CF8).withValues(alpha: 0.3) // 夜晚使用月光蓝发光
                        : Colors.black.withValues(alpha: 0.08),
                    blurRadius: 12,
                    offset: isNight ? Offset.zero : const Offset(0, 5),
                    spreadRadius: isNight ? 2 : 0,
                  ),
                ],
              ),
              child: ClipOval(
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                  child: Center(
                    child: Icon(
                      icon,
                      color: primaryColor,
                      size: 24,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 5),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: primaryColor.withValues(alpha: 0.8),
                fontFamily: 'LXGWWenKai',
                letterSpacing: 1.0,
              ),
            ),
          ],
        ),
      ).animate().fadeIn(duration: 600.ms, delay: delay).scale(begin: const Offset(0.8, 0.8)),
    );
  }

  Widget _buildBackground(
    String? bgPath,
    Uint8List? snapshot,
    double h,
    double w,
    Color bgColor,
  ) {
    return _ParallaxBackground(
      bgPath: bgPath,
      snapshot: snapshot,
      h: h,
      w: w,
      bgColor: bgColor,
    );
  }

  Future<void> _openDecorationPage() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const DecorationPage()),
    );
  }

  Future<void> _openPhotoWall() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const DiaryPhotoWallPage()),
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
    return Stack(
      children: [
        // 1. 背景材质/图片
        if (bgPath != null)
          Positioned.fill(
            child: Image.asset(bgPath!, fit: BoxFit.cover),
          )
        else
          Positioned.fill(child: Container(color: bgColor)),

        // 2. 房屋快照
        if (snapshot != null)
          Positioned.fill(
            child: Image.memory(snapshot!, fit: BoxFit.cover),
          ),
      ],
    );
  }
}
