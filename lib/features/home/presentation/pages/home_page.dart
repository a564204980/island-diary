import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:island_diary/shared/widgets/bottom_nav_bar.dart';
import 'package:island_diary/features/home/presentation/widgets/floating_clouds.dart';
import 'package:island_diary/core/state/user_state.dart';
import 'package:island_diary/shared/widgets/diary_entry/components/diary_success_overlay.dart';
import 'package:island_diary/features/record/presentation/pages/record_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage>
    with SingleTickerProviderStateMixin {
  int _currentNavIndex = 0;
  late AnimationController _floatController;
  late Animation<double> _floatAnimation;
  Timer? _timeChecker;
  late String _currentBgPath;

  @override
  void initState() {
    super.initState();
    _currentBgPath = _getBackgroundImageForCurrentTime();

    _timeChecker = Timer.periodic(const Duration(minutes: 1), (timer) {
      final newBgPath = _getBackgroundImageForCurrentTime();
      if (newBgPath != _currentBgPath) {
        setState(() {
          _currentBgPath = newBgPath;
        });
      }
    });

    _floatController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 8),
    )..repeat(reverse: true);

    _floatAnimation = Tween<double>(begin: -7.0, end: 7.0).animate(
      CurvedAnimation(parent: _floatController, curve: Curves.easeInOut),
    );
  }

  String _getBackgroundImageForCurrentTime({bool isWide = false}) {
    final int currentHour = DateTime.now().hour;
    if (currentHour >= 6 && currentHour < 11) {
      return 'assets/images/home_xiatian_big.png';
    } else if (currentHour >= 11 && currentHour < 17) {
      return 'assets/images/home_zhongwu_big.png';
    } else {
      return 'assets/images/home_wanshang_big.png';
    }
  }

  String _getIslandImageForCurrentTime() {
    final int currentHour = DateTime.now().hour;
    // 中午到下午 (10:00 - 18:00) 使用 home_small_demo
    if (currentHour >= 10 && currentHour < 18) {
      return 'assets/images/home_small_demo.png';
    }
    // 其余时间使用 home_small_demo2
    return 'assets/images/home_small_demo2.png';
  }

  Color _getIslandGlowColorForCurrentTime() {
    final int currentHour = DateTime.now().hour;
    if (currentHour >= 17 || currentHour < 6) {
      return const Color(0xFFFFEFA1).withOpacity(0.65);
    } else {
      return Colors.white.withOpacity(0.9);
    }
  }

  Color _getIslandBottomLightColorForCurrentTime() {
    final int currentHour = DateTime.now().hour;
    if (currentHour >= 17 || currentHour < 6) {
      return const Color(0xFFFFB347).withOpacity(0.95);
    } else {
      return Colors.transparent;
    }
  }

  Color _getIslandBottomRockLightColorForCurrentTime() {
    final int currentHour = DateTime.now().hour;
    if (currentHour >= 17 || currentHour < 6) {
      return const Color(0xFFFFB347).withOpacity(0.65);
    } else {
      return Colors.transparent;
    }
  }

  @override
  void dispose() {
    _timeChecker?.cancel();
    _floatController.dispose();
    super.dispose();
  }

  void _showSuccessEffect() {
    OverlayEntry? overlayEntry;
    overlayEntry = OverlayEntry(
      builder: (context) => DiarySuccessOverlay(
        onFinished: () {
          overlayEntry?.remove();
        },
      ),
    );
    Overlay.of(context).insert(overlayEntry);
  }

  @override
  Widget build(BuildContext context) {
    final Size screenSize = MediaQuery.of(context).size;
    final double screenWidth = screenSize.width;
    final double screenHeight = screenSize.height;
    final bool isWide = screenWidth > 600;
    final responsiveBgPath = _getBackgroundImageForCurrentTime(isWide: isWide);
    final bool isNight = DateTime.now().hour >= 17 || DateTime.now().hour < 6;
    final islandPath = _getIslandImageForCurrentTime();

    return Scaffold(
      backgroundColor: isNight
          ? const Color(0xFF0D1B2A)
          : const Color(0xFFE6F3F5),
      resizeToAvoidBottomInset: false,
      body: Stack(
        children: [
          // 1. 主内容区域 (带有物理裁剪，解决溢出警告)
          Positioned.fill(
            child: ClipRect(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 600),
                switchInCurve: Curves.easeInOut,
                switchOutCurve: Curves.easeInOut,
                layoutBuilder:
                    (Widget? currentChild, List<Widget> previousChildren) {
                      return Stack(
                        children: [
                          ...previousChildren.map(
                            (e) => Positioned.fill(child: e),
                          ),
                          if (currentChild != null)
                            Positioned.fill(child: currentChild),
                        ],
                      );
                    },
                transitionBuilder: (Widget child, Animation<double> animation) {
                  return FadeTransition(opacity: animation, child: child);
                },
                child: _currentNavIndex == 1
                    ? const RecordPage(key: ValueKey('RecordPage'))
                    : Stack(
                        key: const ValueKey('HomeContent'),
                        children: [
                          // 首页背景
                          Positioned.fill(
                            child: AnimatedSwitcher(
                              duration: const Duration(milliseconds: 1500),
                              layoutBuilder: (child, others) => Stack(
                                children: [
                                  ...others.map(
                                    (e) => Positioned.fill(child: e),
                                  ),
                                  if (child != null)
                                    Positioned.fill(child: child),
                                ],
                              ),
                              child: Image.asset(
                                responsiveBgPath,
                                key: ValueKey(responsiveBgPath),
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),
                          // 云朵层
                          Positioned.fill(
                            child: FloatingClouds(isNight: isNight),
                          ),
                          // 标题
                          SafeArea(
                            child: Align(
                              alignment: Alignment.topLeft,
                              child: Padding(
                                padding: const EdgeInsets.all(24.0),
                                child: ValueListenableBuilder<bool>(
                                  valueListenable: UserState().isDiarySheetOpen,
                                  builder: (context, isOpen, child) {
                                    return Text(
                                          '${UserState().userName.value}的小岛',
                                          style: TextStyle(
                                            color: isNight
                                                ? Colors.white
                                                : const Color(0xFF5A3E28),
                                            fontSize: 22,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        )
                                        .animate(target: isOpen ? 0 : 1)
                                        .fade(duration: 400.ms);
                                  },
                                ),
                              ),
                            ),
                          ),
                          // 岛屿主体
                          AnimatedBuilder(
                            animation: _floatAnimation,
                            builder: (context, child) {
                              final double aspectRatio =
                                  screenWidth / screenHeight;
                              final Alignment islandAlignment =
                                  aspectRatio > 0.6
                                  ? const Alignment(0, -0.16)
                                  : const Alignment(0, -0.4);
                              return Align(
                                alignment: islandAlignment,
                                child: Transform.translate(
                                  offset: Offset(0, _floatAnimation.value),
                                  child: child,
                                ),
                              );
                            },
                            child: Stack(
                              alignment: Alignment.center,
                              children: [
                                // 岛屿倒影光束
                                Positioned(
                                  bottom: isWide ? 100 : screenWidth * 0.08,
                                  child: Container(
                                    width: isWide ? 600 : screenWidth * 0.85,
                                    height: isWide ? 300 : screenWidth * 0.45,
                                    decoration: BoxDecoration(
                                      gradient: RadialGradient(
                                        colors: [
                                          _getIslandBottomLightColorForCurrentTime(),
                                          _getIslandBottomLightColorForCurrentTime()
                                              .withOpacity(0.0),
                                        ],
                                        stops: const [0.15, 1.0],
                                      ),
                                    ),
                                  ),
                                ),
                                // 岛屿光晕层
                                ImageFiltered(
                                  imageFilter: ImageFilter.blur(
                                    sigmaX: 5.0,
                                    sigmaY: 5.4,
                                  ),
                                  child: Image.asset(
                                    islandPath,
                                    width:
                                        (screenWidth <= 600
                                            ? screenWidth * 0.9
                                            : 540.0) *
                                        1.05,
                                    fit: BoxFit.contain,
                                    color: _getIslandGlowColorForCurrentTime(),
                                  ),
                                ),
                                // 岛屿主体层 (带岩石反光)
                                ShaderMask(
                                  blendMode: BlendMode.srcATop,
                                  shaderCallback: (bounds) {
                                    return RadialGradient(
                                      center: const Alignment(0, 0.85),
                                      radius: 0.6,
                                      colors: [
                                        _getIslandBottomRockLightColorForCurrentTime(),
                                        Colors.transparent,
                                      ],
                                      stops: const [0.0, 1.0],
                                    ).createShader(bounds);
                                  },
                                  child: Image.asset(
                                    islandPath,
                                    width: screenWidth <= 600
                                        ? screenWidth * 0.9
                                        : 540.0,
                                    fit: BoxFit.contain,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          // 前景云
                          Positioned.fill(
                            child: FloatingClouds(
                              isNight: isNight,
                              isForeground: true,
                            ),
                          ),
                        ],
                      ),
              ),
            ),
          ),

          // 2. 底部导航栏 (位于顶层)
          Positioned(
            left: 0,
            right: 0,
            bottom: isWide ? 60 : 40,
            child: BottomNavBar(
              currentIndex: _currentNavIndex,
              isNight: isNight,
              onSaveSuccess: _showSuccessEffect,
              onTap: (index) {
                if (index == 0 || index == 1) {
                  setState(() => _currentNavIndex = index);
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('功能开发中，敬请期待~'),
                      duration: Duration(seconds: 1),
                    ),
                  );
                }
              },
            ),
          ),
        ],
      ),
    );
  }
}
