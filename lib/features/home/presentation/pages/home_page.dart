import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:island_diary/shared/widgets/bottom_nav_bar.dart';
import 'package:island_diary/features/home/presentation/widgets/floating_clouds.dart';

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
      return 'assets/images/home_xiatian.png';
    } else if (currentHour >= 11 && currentHour < 17) {
      return isWide
          ? 'assets/images/home_zhongwu_big.png'
          : 'assets/images/home_zhongwu.png';
    } else {
      return isWide
          ? 'assets/images/home_wanshang_big.png'
          : 'assets/images/home_wanshang.png';
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

  @override
  Widget build(BuildContext context) {
    // 响应式逻辑：检测屏幕宽度
    final double screenWidth = MediaQuery.of(context).size.width;
    final bool isWide = screenWidth > 600;
    final responsiveBgPath = _getBackgroundImageForCurrentTime(isWide: isWide);
    final bool isNight = DateTime.now().hour >= 17 || DateTime.now().hour < 6;

    return Scaffold(
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
                width: double.infinity,
                height: double.infinity,
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
                child: const Text(
                  '治愈岛',
                  style: TextStyle(
                    color: Color(0xFF5A3E28),
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),

          // 3. 岛屿浮动区
          AnimatedBuilder(
            animation: _floatAnimation,
            builder: (context, child) {
              // 响应式岛屿尺寸计算：确保在 600px 切换点平滑连接
              return Align(
                alignment: const Alignment(0, -0.4),
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
                  bottom: screenWidth * 0.08,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 1500),
                    width: screenWidth * 0.85,
                    height: screenWidth * 0.45,
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
                          final iw = sw <= 600
                              ? sw * 0.9
                              : 540 + (sw - 600) * 0.3;
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
                        final iw = sw <= 600
                            ? sw * 0.9
                            : 540 + (sw - 600) * 0.3;
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
            bottom: 40,
            child: BottomNavBar(
              currentIndex: _currentNavIndex,
              isNight: DateTime.now().hour >= 17 || DateTime.now().hour < 6,
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
