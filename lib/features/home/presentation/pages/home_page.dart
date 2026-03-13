import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:island_diary/shared/widgets/bottom_nav_bar.dart';
import 'package:island_diary/features/home/presentation/widgets/floating_clouds.dart';
import 'package:island_diary/core/state/user_state.dart';
import 'package:island_diary/shared/widgets/diary_entry/components/diary_success_overlay.dart';

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
  late String _currentIslandPath;

  @override
  void initState() {
    super.initState();
    _currentBgPath = _getBackgroundImageForCurrentTime();
    _currentIslandPath = _getIslandImageForCurrentTime();

    _timeChecker = Timer.periodic(const Duration(minutes: 1), (timer) {
      final newBgPath = _getBackgroundImageForCurrentTime();
      final newIslandPath = _getIslandImageForCurrentTime();
      if (newBgPath != _currentBgPath || newIslandPath != _currentIslandPath) {
        setState(() {
          _currentBgPath = newBgPath;
          _currentIslandPath = newIslandPath;
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

  /// 依据系统小时数和屏幕宽度获取背景素材
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
    if (currentHour >= 17 || currentHour < 6) {
      return 'assets/images/home_island_smal_wanshang.png';
    } else {
      return 'assets/images/home_island_small.png';
    }
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
    // 恢复为响应式尺寸获取：直接使用 MediaQuery 感知窗口变化
    final Size screenSize = MediaQuery.of(context).size;
    final double screenWidth = screenSize.width;
    final double screenHeight = screenSize.height;

    final bool isWide = screenWidth > 600;
    final responsiveBgPath = _getBackgroundImageForCurrentTime(isWide: isWide);
    final bool isNight = DateTime.now().hour >= 17 || DateTime.now().hour < 6;

    return Scaffold(
      resizeToAvoidBottomInset: false,
      body: Stack(
        children: [
          // 1. 响应式背景图
          Positioned.fill(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 1500),
              child: Image.asset(
                responsiveBgPath,
                key: ValueKey(responsiveBgPath),
                fit: BoxFit.cover,
                width: screenWidth,
                height: screenHeight,
              ),
            ),
          ),

          // 1.5 天气层：多云
          Positioned.fill(child: FloatingClouds(isNight: isNight)),

          // 2. 标题区
          SafeArea(
            child: Align(
              alignment: Alignment.topLeft,
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: ValueListenableBuilder<bool>(
                  valueListenable: UserState().isDiarySheetOpen,
                  builder: (context, isOpen, child) {
                    return Text(
                          '治愈岛',
                          style: TextStyle(
                            color: isNight
                                ? Colors.white
                                : const Color(0xFF5A3E28),
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            shadows: isNight
                                ? [
                                    Shadow(
                                      color: Colors.black.withOpacity(0.3),
                                      blurRadius: 4,
                                      offset: const Offset(0, 2),
                                    ),
                                  ]
                                : null,
                          ),
                        )
                        .animate(target: isOpen ? 0 : 1) // 打开时消失，关闭时出现
                        .fade(duration: 400.ms)
                        .moveY(
                          begin: -10,
                          end: 0,
                          duration: 400.ms,
                          curve: Curves.easeOutCubic,
                        );
                  },
                ),
              ),
            ),
          ),

          // 3. 岛屿浮动区
          AnimatedBuilder(
            animation: _floatAnimation,
            builder: (context, child) {
              // 关键适配：iPad 的屏幕宽高比 (通常在 0.7 - 0.75) 比手机 (通常 < 0.5) 要大
              // 使用更高的 Alignment 值来补偿 iPad 屏幕更“胖”导致的重心偏下感
              final double aspectRatio = screenWidth / screenHeight;
              final Alignment islandAlignment = aspectRatio > 0.6
                  ? const Alignment(0, -0.16) // iPad 向上提一点
                  : const Alignment(0, -0.4); // 手机保持原位

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
                // 底部倒影光束
                Positioned(
                  bottom: isWide ? 100 : screenWidth * 0.08,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 1500),
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
                // 岛屿背光层
                Transform.translate(
                  offset: const Offset(0, 5.0),
                  child: ImageFiltered(
                    imageFilter: ImageFilter.blur(sigmaX: 5.0, sigmaY: 5.4),
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 1500),
                      child: Builder(
                        builder: (context) {
                          final sw = MediaQuery.of(context).size.width;
                          // 固定逻辑：在 iPad 上也按比例缩小，最大宽度限制在 500 左右
                          final iw = sw <= 600 ? sw * 0.9 : 540.0;
                          return Image.asset(
                            _currentIslandPath,
                            key: ValueKey('glow_$_currentIslandPath'),
                            width: iw * 1.05,
                            fit: BoxFit.contain,
                            color: _getIslandGlowColorForCurrentTime(),
                          );
                        },
                      ),
                    ),
                  ),
                ),
                // 岛屿主体层
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 1500),
                  child: ShaderMask(
                    key: ValueKey('top_$_currentIslandPath'),
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
                    child: Builder(
                      builder: (context) {
                        final sw = MediaQuery.of(context).size.width;
                        final iw = sw <= 600 ? sw * 0.9 : 540.0;
                        return Image.asset(
                          _currentIslandPath,
                          width: iw,
                          fit: BoxFit.contain,
                        );
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),

          // 3.5 前景层：在岛屿前方飘过的云
          Positioned.fill(
            child: FloatingClouds(isNight: isNight, isForeground: true),
          ),

          // 4. 底部导航栏
          Positioned(
            left: 0,
            right: 0,
            bottom: isWide ? 60 : 40, // iPad 适当提升底部距离
            child: BottomNavBar(
              currentIndex: _currentNavIndex,
              isNight: DateTime.now().hour >= 17 || DateTime.now().hour < 6,
              onSaveSuccess: _showSuccessEffect,
              onTap: (index) {
                setState(() {
                  _currentNavIndex = index;
                });
              },
            ),
          ),
        ],
      ),
    );
  }
}
