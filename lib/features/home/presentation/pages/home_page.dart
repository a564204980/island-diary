import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:island_diary/shared/widgets/bottom_nav_bar.dart';
import 'package:island_diary/features/home/presentation/widgets/floating_clouds.dart';
import 'package:island_diary/core/state/user_state.dart';
import 'package:island_diary/shared/widgets/diary_entry/components/diary_success_overlay.dart';
import 'package:island_diary/core/models/mascot_achievement.dart';
import 'package:island_diary/features/record/presentation/pages/record_page.dart';
import 'package:island_diary/features/profile/presentation/pages/profile_page.dart';
import 'package:island_diary/shared/widgets/barrage/mood_barrage_wall.dart';
import 'package:island_diary/features/record/domain/models/diary_entry.dart';
import 'package:island_diary/features/record/presentation/pages/decoration_page.dart';
import 'package:island_diary/features/statistics/presentation/pages/statistics_page.dart';


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

  // 弹幕相关
  List<Map<DateTime, List<DiaryEntry>>> _groupedEntries = [];
  int _barrageCurrentIndex = 0;
  late PageController _barragePageController;

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

    _barragePageController = PageController();
    _groupEntriesByDate();
    
    // 监听日记变化，实时更新分组
    UserState().savedDiaries.addListener(_groupEntriesByDate);
    
    // 首次进入首页时检测成就（用于解锁“星河初航”等入驻成就）
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        UserState().checkAchievements();
      }
    });
  }

  void _groupEntriesByDate() {
    final diaries = UserState().savedDiaries.value;
    if (diaries.isEmpty) {
      if (mounted) setState(() => _groupedEntries = []);
      return;
    }

    final Map<String, List<DiaryEntry>> groups = {};
    for (var entry in diaries) {
      final dateStr = "${entry.dateTime.year}-${entry.dateTime.month}-${entry.dateTime.day}";
      if (!groups.containsKey(dateStr)) {
        groups[dateStr] = [];
      }
      groups[dateStr]!.add(entry);
    }
    
    // 按日期倒序排列
    final sortedKeys = groups.keys.toList()..sort((a, b) => b.compareTo(a));
    final newGrouped = sortedKeys.map((k) {
      final date = groups[k]![0].dateTime;
      return {DateTime(date.year, date.month, date.day): groups[k]!};
    }).toList();

    if (mounted) {
      setState(() {
        _groupedEntries = newGrouped;
      });
    }
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
    if (currentHour >= 10 && currentHour < 18) {
      return 'assets/images/home_small_demo.png';
    }
    return 'assets/images/home_small_demo2.png';
  }

  Color _getIslandGlowColorForCurrentTime() {
    if (UserState().isNight) {
      return const Color(0xFFFFEFA1).withValues(alpha: 0.65);
    } else {
      return Colors.white.withValues(alpha: 0.9);
    }
  }

  Color _getIslandBottomLightColorForCurrentTime() {
    if (UserState().isNight) {
      return const Color(0xFFFFB347).withValues(alpha: 0.95);
    } else {
      return Colors.transparent;
    }
  }

  Color _getIslandBottomRockLightColorForCurrentTime() {
    if (UserState().isNight) {
      return const Color(0xFFFFB347).withValues(alpha: 0.65);
    } else {
      return Colors.transparent;
    }
  }

  @override
  void dispose() {
    UserState().savedDiaries.removeListener(_groupEntriesByDate);
    _timeChecker?.cancel();
    _floatController.dispose();
    _zoomAnimationController.dispose();
    _transformationController.dispose();
    _barragePageController.dispose();
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    super.dispose();
  }

  Matrix4 _getLandscapeMatrix(Size size) {
    const double scale = 2.0;
    final double centerX = size.width / 2;
    final double centerY = size.height / 2;

    return Matrix4.identity()
      ..translateByDouble(centerX, centerY, 0.0, 1.0)
      ..scaleByDouble(scale, scale, 1.0, 1.0)
      ..translateByDouble(-centerX, -centerY + (size.height * 0.02), 0.0, 1.0);
  }

  Future<void> _toggleOrientation() async {
    final bool becomingLandscape = !_isLandscape;
    final currentSize = MediaQuery.of(context).size;

    final targetSizeForMatrix = becomingLandscape
        ? Size(currentSize.height, currentSize.width)
        : currentSize;

    setState(() {
      _isLandscape = becomingLandscape;
    });

    final Matrix4 endMatrix = becomingLandscape
        ? _getLandscapeMatrix(targetSizeForMatrix)
        : Matrix4.identity();

    _zoomAnimation = Matrix4Tween(
      begin: _transformationController.value,
      end: endMatrix,
    ).animate(
      CurvedAnimation(
        parent: _zoomAnimationController,
        curve: Curves.easeInOutCubic,
      ),
    );

    _zoomAnimationController.forward(from: 0);

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

  void _openDecorationPage() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const DecorationPage()),
    );
  }


  Future<void> _showSuccessEffect(List<MascotAchievement> achievements) async {
    if (achievements.isEmpty || !mounted) return;
    
    // 目前一次保存通常触发一个或几个成就，我们展示最重要的那个或者第一个
    final achievement = achievements.first;

    // 使用 WidgetsBinding 确保在渲染周期外安全操作 Overlay
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      
      OverlayEntry? overlayEntry;
      overlayEntry = OverlayEntry(
        builder: (context) => DiarySuccessOverlay(
          achievement: achievement,
          onFinished: () {
            overlayEntry?.remove();
          },
        ),
      );
      
      Overlay.of(context).insert(overlayEntry);
    });
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<String>(
      valueListenable: UserState().themeMode,
      builder: (context, themeMode, child) {
        final bool isNight = UserState().isNight;
        final isWide = MediaQuery.of(context).size.width > 600;

        return Scaffold(
          backgroundColor: isNight ? const Color(0xFF0D1B2A) : const Color(0xFFE6F3F5),
          resizeToAvoidBottomInset: false,
          body: Stack(
            children: [
              Positioned.fill(
                child: IndexedStack(
                  index: _currentNavIndex == 4 
                      ? 3 
                      : (_currentNavIndex == 3 
                          ? 2 
                          : (_currentNavIndex == 1 ? 1 : 0)),
                  children: [
                    _buildHomeContent(isNight, isWide),
                    const RecordPage(key: ValueKey('RecordPage')),
                    StatisticsPage(key: const ValueKey('StatisticsPage'), isActive: _currentNavIndex == 3),
                    const ProfilePage(key: ValueKey('ProfilePage')),
                  ],
                ),
              ),
              // 统一顶部操作栏：仅在首页(0)和记录页(1)显示
              if (_currentNavIndex == 0 || _currentNavIndex == 1)
                Positioned.fill(
                  child: SafeArea(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 24.0),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          // 标题逻辑：仅在首页(0)显示岛屿名称
                          _currentNavIndex == 0 
                            ? ValueListenableBuilder<bool>(
                                valueListenable: UserState().isDiarySheetOpen,
                                builder: (context, isOpen, child) {
                                  return Text(
                                    _isLandscape ? '心情漫游' : '${UserState().userName.value}的小岛',
                                    style: TextStyle(
                                      color: isNight ? Colors.white : const Color(0xFF5A3E28),
                                      fontSize: 22,
                                      fontWeight: FontWeight.bold,
                                      shadows: isNight
                                          ? [
                                              Shadow(color: Colors.black.withValues(alpha: 0.3), offset: const Offset(0, 2), blurRadius: 4),
                                            ]
                                          : null,
                                    ),
                                  ).animate(target: isOpen ? 0 : 1).fade(duration: 400.ms);
                                },
                              )
                            : const SizedBox.shrink(),
                          
                          Row(
                            children: [
                              _buildTopIconButton(
                                icon: _isLandscape ? Icons.fullscreen_exit_rounded : Icons.fullscreen_rounded,
                                isNight: isNight,
                                onTap: _toggleOrientation,
                              ),
                              const SizedBox(width: 16),
                                _buildTopIconButton(
                                 icon: _currentNavIndex == 1 ? Icons.chair_outlined : Icons.palette_outlined,
                                 isNight: isNight,
                                 onTap: _currentNavIndex == 1 ? _openDecorationPage : _toggleOrientation,
                               ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

              AnimatedPositioned(
                duration: 800.ms,
                curve: Curves.easeOutQuart,
                left: 0,
                right: 0,
                bottom: _isLandscape ? -120 : (isWide ? 60 : 40),
                child: BottomNavBar(
                  currentIndex: _currentNavIndex,
                  isNight: isNight,
                  forceHideDialogue: _isLandscape,
                  onSaveSuccess: _showSuccessEffect,
                  onTap: (index) {
                    if (index == 0 || index == 1 || index == 3 || index == 4) {
                      setState(() {
                        _currentNavIndex = index;
                      });
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

  Widget _buildHomeContent(bool isNight, bool isWide) {
    final responsiveBgPath = _getBackgroundImageForCurrentTime(
      isWide: MediaQuery.of(context).size.width > 600,
    );
    final islandPath = _getIslandImageForCurrentTime();

    return Stack(
      key: const ValueKey('HomeContent'),
      children: [
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
        if (!_isLandscape)
          Positioned.fill(
            child: FloatingClouds(
              isNight: isNight,
              shouldAnimate: _currentNavIndex == 0,
            ),
          ),
        Positioned.fill(
          child: InteractiveViewer(
            transformationController: _transformationController,
            panEnabled: false,
            boundaryMargin: EdgeInsets.zero,
            minScale: 1.0,
            maxScale: 5.0,
            child: Builder(
              builder: (context) {
                final double currentScreenWidth = MediaQuery.of(context).size.width;
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
                      Positioned(
                        bottom: currentScreenWidth * 0.04,
                        child: Container(
                          width: isWide ? 480 : currentScreenWidth * 0.8,
                          height: isWide ? 200 : currentScreenWidth * 0.4,
                          decoration: BoxDecoration(
                            gradient: RadialGradient(
                              colors: [
                                _getIslandBottomLightColorForCurrentTime(),
                                _getIslandBottomLightColorForCurrentTime().withValues(alpha: 0.0),
                              ],
                              stops: const [0.15, 1.0],
                            ),
                          ),
                        ),
                      ),
                      ImageFiltered(
                        imageFilter: ImageFilter.blur(sigmaX: 5.0, sigmaY: 5.4),
                        child: Image.asset(
                          islandPath,
                          width: (currentScreenWidth <= 600 ? currentScreenWidth * 0.9 : 540.0) * 1.05,
                          fit: BoxFit.contain,
                          color: _getIslandGlowColorForCurrentTime(),
                        ),
                      ),
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
                          width: currentScreenWidth <= 600 ? currentScreenWidth * 0.9 : 540.0,
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

        if (_isLandscape && _groupedEntries.isNotEmpty)
          Positioned.fill(
            child: _buildBarrageLayer(),
          ),

        if (!_isLandscape)
          Positioned.fill(
            child: FloatingClouds(
              isNight: isNight,
              isForeground: true,
              shouldAnimate: _currentNavIndex == 0,
            ),
          ),
        // 移除了内部的顶部操作栏，已提升至上层 Stack
      ],
    );
  }

  Widget _buildBarrageLayer() {
    return Stack(
      children: [
        PageView.builder(
          controller: _barragePageController,
          itemCount: _groupedEntries.length,
          onPageChanged: (index) {
            setState(() {
              _barrageCurrentIndex = index;
            });
          },
          itemBuilder: (context, index) {
            final dateGroup = _groupedEntries[index];
            final dayEntries = dateGroup.values.first;

            return BarrageDayScene(
              entries: dayEntries,
              date: dateGroup.keys.first,
              onFinished: () {
                if (index == _barrageCurrentIndex) {
                  _autoNextDay();
                }
              },
            );
          },
        ),
        
        Positioned(
          bottom: 40,
          left: 0,
          right: 0,
          child: Center(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                _formatBarrageDate(_groupedEntries[_barrageCurrentIndex].keys.first),
                style: const TextStyle(
                  color: Colors.white,
                  fontFamily: 'LXGWWenKai',
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ),
      ],
    ).animate().fadeIn(duration: 800.ms);
  }

  void _autoNextDay() {
    if (_barrageCurrentIndex < _groupedEntries.length - 1) {
      _barragePageController.nextPage(
        duration: const Duration(seconds: 2),
        curve: Curves.easeInOutCubic,
      );
    }
  }

  String _formatBarrageDate(DateTime dt) {
    return "${dt.year}年${dt.month}月${dt.day}日";
  }

  Widget _buildTopIconButton({
    required IconData icon,
    required bool isNight,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: ClipOval(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: isNight 
                ? Colors.white.withValues(alpha: 0.15) 
                : Colors.black.withValues(alpha: 0.25),
              shape: BoxShape.circle,
              border: Border.all(
                color: isNight 
                  ? Colors.white.withValues(alpha: 0.1) 
                  : Colors.black.withValues(alpha: 0.05),
                width: 0.5,
              ),
            ),
            child: Icon(
              icon,
              size: 24,
              color: Colors.white.withValues(alpha: 0.95),
            ),
          ),
        ),
      ),
    ).animate(onPlay: (controller) => controller.repeat(reverse: true)).scale(
          begin: const Offset(1, 1),
          end: const Offset(1.05, 1.05),
          duration: 3.seconds,
          curve: Curves.easeInOut,
        );
  }
}
