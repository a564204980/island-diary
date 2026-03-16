import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:island_diary/shared/widgets/bottom_nav_bar.dart';
import 'package:island_diary/features/home/presentation/widgets/floating_clouds.dart';
import 'package:island_diary/core/state/user_state.dart';
import 'package:island_diary/shared/widgets/diary_entry/components/diary_success_overlay.dart';
import 'package:island_diary/features/record/presentation/pages/record_page.dart';
import 'package:island_diary/features/profile/presentation/pages/profile_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with TickerProviderStateMixin {
  int _currentNavIndex = 0;
  late AnimationController _floatController;
  late Animation<double> _floatAnimation;
  late TransformationController _transformationController;
  late AnimationController _zoomAnimationController;
  Animation<Matrix4>? _zoomAnimation;
  Timer? _timeChecker;
  late String _currentBgPath;
  bool _isLandscape = false; // 是否全屏横屏模式

  @override
  void initState() {
    super.initState();
    _currentBgPath = _getBackgroundImageForCurrentTime();

    // 强制初始化为竖屏，防止热重启后残留横屏设置
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);

    _timeChecker = Timer.periodic(const Duration(minutes: 1), (timer) {
      if (UserState().themeMode.value == 'auto') {
        final newBgPath = _getBackgroundImageForCurrentTime();
        if (newBgPath != _currentBgPath) {
          setState(() {
            _currentBgPath = newBgPath;
          });
        }
      }
    });

    _floatController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 8),
    )..repeat(reverse: true);

    _floatAnimation = Tween<double>(begin: -7.0, end: 7.0).animate(
      CurvedAnimation(parent: _floatController, curve: Curves.easeInOut),
    );

    _transformationController = TransformationController();
    _zoomAnimationController =
        AnimationController(vsync: this, duration: 800.ms)..addListener(() {
          if (_zoomAnimation != null) {
            _transformationController.value = _zoomAnimation!.value;
          }
        });
  }

  String _getBackgroundImageForCurrentTime({bool isWide = false}) {
    if (UserState().themeMode.value == 'light') {
      return 'assets/images/home_zhongwu_big.png';
    }
    if (UserState().themeMode.value == 'dark') {
      return 'assets/images/home_wanshang_big.png';
    }

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
    if (UserState().themeMode.value == 'light') {
      return 'assets/images/home_small_demo.png';
    }
    if (UserState().themeMode.value == 'dark') {
      return 'assets/images/home_small_demo2.png';
    }

    final int currentHour = DateTime.now().hour;
    // 中午到下午 (10:00 - 18:00) 使用 home_small_demo
    if (currentHour >= 10 && currentHour < 18) {
      return 'assets/images/home_small_demo.png';
    }
    // 其余时间使用 home_small_demo2
    return 'assets/images/home_small_demo2.png';
  }

  Color _getIslandGlowColorForCurrentTime() {
    if (UserState().isNight) {
      return const Color(0xFFFFEFA1).withOpacity(0.65);
    } else {
      return Colors.white.withOpacity(0.9);
    }
  }

  Color _getIslandBottomLightColorForCurrentTime() {
    if (UserState().isNight) {
      return const Color(0xFFFFB347).withOpacity(0.95);
    } else {
      return Colors.transparent;
    }
  }

  Color _getIslandBottomRockLightColorForCurrentTime() {
    if (UserState().isNight) {
      return const Color(0xFFFFB347).withOpacity(0.65);
    } else {
      return Colors.transparent;
    }
  }

  @override
  void dispose() {
    _timeChecker?.cancel();
    _floatController.dispose();
    _zoomAnimationController.dispose();
    _transformationController.dispose();
    // 强制复原系统 UI 和方向
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    super.dispose();
  }

  /// 计算全屏矩阵 (中心缩放版)
  Matrix4 _getLandscapeMatrix(Size size) {
    const double scale = 2.0;
    // 关键：以屏幕中心为缩放锚点，防止内容飞出屏幕
    final double centerX = size.width / 2;
    final double centerY = size.height / 2;

    // 组合矩阵：先平移到中心点，执行缩放，再平移回来的同时加上位置补偿
    return Matrix4.identity()
      ..translate(centerX, centerY)
      ..scale(scale)
      ..translate(-centerX, -centerY + (size.height * 0.02)); // 减小补偿值，将小岛往上抬一点
  }

  /// 切换横竖屏全屏模式 (矩阵动画版)
  Future<void> _toggleOrientation() async {
    final bool becomingLandscape = !_isLandscape;
    final currentSize = MediaQuery.of(context).size;

    // 关键修正：如果即将进入横屏，目标尺寸应该是宽高交换后的结果
    final targetSizeForMatrix = becomingLandscape
        ? Size(currentSize.height, currentSize.width)
        : currentSize;

    // 1. 更新 UI 状态
    setState(() {
      _isLandscape = becomingLandscape;
    });

    // 2. 准备矩阵动画
    final Matrix4 endMatrix = becomingLandscape
        ? _getLandscapeMatrix(targetSizeForMatrix)
        : Matrix4.identity();

    _zoomAnimation =
        Matrix4Tween(
          begin: _transformationController.value,
          end: endMatrix,
        ).animate(
          CurvedAnimation(
            parent: _zoomAnimationController,
            curve: Curves.easeInOutCubic,
          ),
        );

    _zoomAnimationController.forward(from: 0);

    // 3. 硬件旋转处理
    if (becomingLandscape) {
      await SystemChrome.setPreferredOrientations([
        DeviceOrientation.landscapeLeft,
        DeviceOrientation.landscapeRight,
      ]);
      await SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    } else {
      await SystemChrome.setPreferredOrientations([
        DeviceOrientation.portraitUp,
      ]);
      await SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    }
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
    return ValueListenableBuilder<String>(
      valueListenable: UserState().themeMode,
      builder: (context, themeMode, child) {
        final bool isNight = UserState().isNight;
        final isWide = MediaQuery.of(context).size.width > 600;

        return Scaffold(
          backgroundColor: isNight
              ? const Color(0xFF0D1B2A)
              : const Color(0xFFE6F3F5),
          resizeToAvoidBottomInset: false,
          body: Stack(
            children: [
              // 1. 主内容区域
              Positioned.fill(
                child: ClipRect(
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 500),
                    switchInCurve: Curves.easeInOut,
                    switchOutCurve: Curves.easeInOut,
                    transitionBuilder: (child, animation) {
                      return FadeTransition(opacity: animation, child: child);
                    },
                    child: _buildCurrentPage(),
                  ),
                ),
              ),

              // 2. 底部导航栏 (全屏模式下通过动画滑出隐藏)
              AnimatedPositioned(
                duration: 800.ms,
                curve: Curves.easeOutQuart,
                left: 0,
                right: 0,
                bottom: _isLandscape ? -120 : (isWide ? 60 : 40),
                child: BottomNavBar(
                  currentIndex: _currentNavIndex,
                  isNight: isNight,
                  forceHideDialogue: _isLandscape, // 全屏模式下强制隐藏精灵对话框
                  onSaveSuccess: _showSuccessEffect,
                  onTap: (index) {
                    if (index == 0 || index == 1 || index == 4) {
                      setState(() {
                        _currentNavIndex = index;
                      });
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
      },
    );
  }

  Widget _buildCurrentPage() {
    final bool isNight = UserState().isNight;
    final responsiveBgPath = _getBackgroundImageForCurrentTime(
      isWide: MediaQuery.of(context).size.width > 600,
    );
    final islandPath = _getIslandImageForCurrentTime();
    final screenWidth = MediaQuery.of(context).size.width;
    final isWide = screenWidth > 600;

    switch (_currentNavIndex) {
      case 1:
        return const RecordPage(key: ValueKey('RecordPage'));
      case 4:
        return const ProfilePage(key: ValueKey('ProfilePage'));
      default:
        return Stack(
          key: const ValueKey('HomeContent'),
          children: [
            // 首页背景
            Positioned.fill(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 1500),
                layoutBuilder: (child, others) => Stack(
                  children: [
                    ...others.map((e) => Positioned.fill(child: e)),
                    if (child != null) Positioned.fill(child: child),
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
              child: FloatingClouds(
                isNight: isNight,
                shouldAnimate: _currentNavIndex == 0,
              ),
            ),
            // 岛屿主体 (支持双指缩放与平移)
            Positioned.fill(
              child: InteractiveViewer(
                transformationController: _transformationController,
                panEnabled: false, // 禁用平移，防止随意拖动
                boundaryMargin: EdgeInsets.zero,
                minScale: 1.0,
                maxScale: 5.0,
                child: Builder(
                  builder: (context) {
                    final double currentScreenWidth = MediaQuery.of(
                      context,
                    ).size.width;

                    return AnimatedBuilder(
                      animation: _floatAnimation,
                      builder: (context, child) {
                        return Center(
                      child: Transform.translate(
                        offset: Offset(0, _floatAnimation.value),
                        child: child,
                      ),
                    );
                  },
                  child: Stack(
                        alignment: Alignment.center,
                        children: [
                          // 岛屿倒影光束 (水面反光)
                          Positioned(
                            bottom: currentScreenWidth * 0.04, // 进一步降低
                            child: Container(
                              width: isWide ? 480 : currentScreenWidth * 0.8,
                              height: isWide ? 200 : currentScreenWidth * 0.4,
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
                                  (currentScreenWidth <= 600
                                      ? currentScreenWidth * 0.9
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
                              width: currentScreenWidth <= 600
                                  ? currentScreenWidth * 0.9
                                  : 540.0,
                              fit: BoxFit.contain,
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ),
            // 前景云
            Positioned.fill(
              child: FloatingClouds(
                isNight: isNight,
                isForeground: true,
                shouldAnimate: _currentNavIndex == 0,
              ),
            ),
            // 标题与操作图标区 (移至顶层，防止被放大的岛屿遮挡点击)
            Positioned.fill(
              child: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24.0,
                    vertical: 24.0,
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start, // 确保在顶端
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // 左侧：标题
                      ValueListenableBuilder<bool>(
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
                                  shadows: isNight
                                      ? [
                                          Shadow(
                                            color: Colors.black.withOpacity(
                                              0.3,
                                            ),
                                            offset: const Offset(0, 2),
                                            blurRadius: 4,
                                          ),
                                        ]
                                      : null,
                                ),
                              )
                              .animate(target: isOpen ? 0 : 1)
                              .fade(duration: 400.ms);
                        },
                      ),
                      // 右侧：功能按钮组
                      Row(
                        children: [
                          _buildTopIconButton(
                            icon: _isLandscape
                                ? Icons.fullscreen_exit_rounded
                                : Icons.fullscreen_rounded,
                            isNight: isNight,
                            onTap: _toggleOrientation,
                          ),
                          const SizedBox(width: 16),
                          _buildTopIconButton(
                            icon: Icons.palette_outlined,
                            isNight: isNight,
                            onTap: () {
                              // TODO: 装扮功能实现
                            },
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        );
    }
  }

  Widget _buildTopIconButton({
    required IconData icon,
    required bool isNight,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: isNight
                  ? Colors.white.withOpacity(0.08)
                  : Colors.black.withOpacity(0.04),
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              size: 24,
              color: isNight
                  ? Colors.white.withOpacity(0.9)
                  : const Color(0xFF5A3E28),
            ),
          ),
        )
        .animate(onPlay: (controller) => controller.repeat(reverse: true))
        .scale(
          begin: const Offset(1, 1),
          end: const Offset(1.05, 1.05),
          duration: 3.seconds,
          curve: Curves.easeInOut,
        );
  }
}
