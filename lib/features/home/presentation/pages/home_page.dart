import 'dart:async';
import 'dart:math';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:island_diary/shared/widgets/bottom_nav_bar.dart';
import 'package:island_diary/features/home/presentation/widgets/floating_clouds.dart';
import 'package:island_diary/features/home/presentation/widgets/rising_lanterns.dart';
import 'package:island_diary/features/home/presentation/widgets/twinkling_stars.dart';
import 'package:island_diary/core/state/user_state.dart';
import 'package:island_diary/shared/widgets/diary_entry/components/diary_success_overlay.dart';
import 'package:island_diary/core/models/mascot_achievement.dart';
import 'package:island_diary/core/models/mascot_persona.dart';
import 'package:island_diary/features/record/presentation/pages/record_page.dart';
import 'package:island_diary/features/profile/presentation/pages/profile_page.dart';
import 'package:island_diary/shared/widgets/barrage/mood_barrage_wall.dart';
import 'package:island_diary/shared/widgets/sprite_dialogue.dart';
import 'package:island_diary/features/record/domain/models/diary_entry.dart';
import 'package:island_diary/features/statistics/presentation/pages/statistics_page.dart';
import 'package:island_diary/shared/widgets/frosted_rainbow.dart';
import 'package:island_diary/shared/widgets/multi_value_listenable_builder.dart';
import 'package:island_diary/features/record/presentation/widgets/scrolling_sun_background.dart';
import 'package:island_diary/features/record/presentation/pages/decoration_page.dart';
import 'package:island_diary/features/record/presentation/widgets/diary_history_overlay.dart';
import 'package:island_diary/features/home/presentation/widgets/island_theme_picker.dart';

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
  bool _isLandscape = false; // 是否全屏横屏模式
  bool _showGlobalDialogue = false;
  String _globalDialogueText = "";
  Timer? _thoughtTimer;

  // 弹幕相关
  List<Map<DateTime, List<DiaryEntry>>> _groupedEntries = [];
  int _barrageCurrentIndex = 0;
  late PageController _barragePageController;

  bool get _isNight {
    final themeId = UserState().selectedIslandThemeId.value;
    if (themeId == 'cotton_candy') {
      return UserState().themeMode.value == 'dark' ||
          (UserState().themeMode.value == 'system' &&
              (DateTime.now().hour < 10 || DateTime.now().hour >= 18));
    }
    if (themeId != 'default' && themeId != 'starry_night') {
      return false;
    }
    return UserState().isNight;
  }

  @override
  void initState() {
    super.initState();
    // 强制初始化为竖屏，防止热重启后残留横屏设置
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);

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

    // 监听 AI 想法
    UserState().mascotThought.addListener(_onThoughtChanged);

    // 首次进入首页时检测成就与启动事件
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (mounted) {
        UserState().checkAchievements();

        // 我们给 AI 一点时间处理 (2秒内如果 AI 没响，再出保底)
        UserState().checkAppStartEvents();

        await Future.delayed(const Duration(seconds: 3));
        if (mounted && !_showGlobalDialogue) {
          _showLocalFallbackDialogue();
        }
      }
    });
  }

  void _onThoughtChanged() {
    final thought = UserState().mascotThought.value;
    if (thought != null && thought.isNotEmpty) {
      if (mounted) {
        setState(() {
          // AI 响应回来，直接覆盖并显示
          _globalDialogueText = thought;
          _showGlobalDialogue = true;
        });

        _thoughtTimer?.cancel();
        _thoughtTimer = Timer(const Duration(seconds: 10), () {
          if (mounted) {
            setState(() => _showGlobalDialogue = false);
            UserState().mascotThought.value = null;
          }
        });
      }
    }
  }

  void _showLocalFallbackDialogue() {
    // 只有在没显示 AI 对话且没有待处理对话时，才显示本地兜底
    if (_showGlobalDialogue || UserState().mascotThought.value != null) return;

    final persona = MascotPersona.getByMascotPath(
      UserState().selectedMascotType.value,
    );
    final fallback =
        persona.fallbackQuotes[Random().nextInt(persona.fallbackQuotes.length)];

    setState(() {
      _globalDialogueText = fallback;
      _showGlobalDialogue = true;
    });

    _thoughtTimer?.cancel();
    _thoughtTimer = Timer(const Duration(seconds: 8), () {
      if (mounted) setState(() => _showGlobalDialogue = false);
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
      final dateStr =
          "${entry.dateTime.year}-${entry.dateTime.month}-${entry.dateTime.day}";
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

  String _getIslandImageForCurrentTime() {
    final themeId = UserState().selectedIslandThemeId.value;
    // 如果是星夜灯塔岛主题，强制使用晚上图片
    if (themeId == 'starry_night') {
      return 'assets/images/home_small_demo2.png';
    } else if (themeId == 'cotton_candy') {
      return _isNight
          ? 'assets/images/theme/miamhuadao/mianhuadao_xiaodao_night.png'
          : 'assets/images/theme/miamhuadao/mianhuadao_xiaodao.png';
    } else if (themeId == 'lantern_festival') {
      return 'assets/images/home5.png';
    }

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
    final themeId = UserState().selectedIslandThemeId.value;
    if (themeId == 'lantern_festival') {
      return const Color(0xFFFFD180).withValues(alpha: 0.7); // 温暖金橙光
    }
    if (themeId == 'cotton_candy') {
      return const Color(0xFFFFE8F5).withValues(alpha: 0.8); // 粉紫色柔光
    }

    if (_isNight) {
      return const Color(0xFFFFEFA1).withValues(alpha: 0.65);
    } else {
      return Colors.white.withValues(alpha: 0.9);
    }
  }

  Color _getIslandBottomLightColorForCurrentTime() {
    final themeId = UserState().selectedIslandThemeId.value;
    if (themeId == 'lantern_festival') {
      return const Color(0xFFFF8A65).withValues(alpha: 0.95); // 暖红橙火光
    }
    if (themeId == 'cotton_candy') {
      return _isNight
          ? const Color(0xFFD1C4E9).withValues(alpha: 0.85) // 粉紫色柔光
          : Colors.transparent;
    }

    if (_isNight) {
      return const Color(0xFFFFB347).withValues(alpha: 0.95);
    } else {
      return Colors.transparent;
    }
  }

  Color _getIslandBottomRockLightColorForCurrentTime() {
    final themeId = UserState().selectedIslandThemeId.value;
    if (themeId == 'lantern_festival') {
      return const Color(0xFFFF8A65).withValues(alpha: 0.7); // 底部岩石映照色
    }
    if (themeId == 'cotton_candy') {
      return _isNight
          ? const Color(0xFFD1C4E9).withValues(alpha: 0.6) // 底部岩石映照粉紫光
          : Colors.transparent;
    }

    if (_isNight) {
      return const Color(0xFFFFB347).withValues(alpha: 0.65);
    } else {
      return Colors.transparent;
    }
  }

  @override
  void dispose() {
    UserState().savedDiaries.removeListener(_groupEntriesByDate);
    UserState().mascotThought.removeListener(_onThoughtChanged);
    _timeChecker?.cancel();
    _thoughtTimer?.cancel();
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

  void _toggleZoom(BuildContext context, bool isWide) {
    if (_zoomAnimationController.isAnimating) return;
    if (_zoomAnimationController.status == AnimationStatus.completed) {
      _zoomAnimationController.reverse();
    } else {
      _zoomAnimationController.forward();
    }
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
    return MultiValueListenableBuilder(
      listenables: [UserState().themeMode, UserState().selectedIslandThemeId],
      builder: (context, values, child) {
        final String themeId = values[1] as String;
        final bool isNight = _isNight;
        final bool isLantern = themeId == 'lantern_festival';
        final bool isCottonCandy = themeId == 'cotton_candy';
        final isWide = MediaQuery.of(context).size.width > 600;

        return Scaffold(
          backgroundColor: isNight
              ? const Color(0xFF0D1B2A)
              : const Color(0xFFE6F3F5),
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
                    StatisticsPage(
                      key: const ValueKey('StatisticsPage'),
                      isActive: _currentNavIndex == 3,
                    ),
                    const ProfilePage(key: ValueKey('ProfilePage')),
                  ],
                ),
              ),
              // 统一顶部操作栏：仅在首页(0)和记录页(1)显示
              if (_currentNavIndex == 0 || _currentNavIndex == 1)
                Positioned.fill(
                  child: SafeArea(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24.0,
                        vertical: 24.0,
                      ),
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
                                          _isLandscape
                                              ? '心情漫游'
                                              : '${UserState().userName.value}的小岛',
                                          style: TextStyle(
                                            color:
                                                (isNight ||
                                                    UserState()
                                                            .selectedIslandThemeId
                                                            .value ==
                                                        'lantern_festival')
                                                ? Colors.white
                                                : const Color(0xFF5A3E28),
                                            fontSize: 22,
                                            fontWeight: FontWeight.bold,
                                            shadows: isNight
                                                ? [
                                                    Shadow(
                                                      color: Colors.black
                                                          .withValues(
                                                            alpha: 0.3,
                                                          ),
                                                      offset: const Offset(
                                                        0,
                                                        2,
                                                      ),
                                                      blurRadius: 4,
                                                    ),
                                                  ]
                                                : null,
                                          ),
                                        )
                                        .animate(target: isOpen ? 0 : 1)
                                        .fade(duration: 400.ms);
                                  },
                                )
                              : (_currentNavIndex == 1
                                    ? Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Text(
                                            "我的岛屿日记",
                                            style: TextStyle(
                                              color: isLantern
                                                  ? const Color(0xFFF6DFA5)
                                                  : (isCottonCandy
                                                        ? (isNight ? Colors.white : const Color(0xFF4E3A46))
                                                        : (isNight
                                                              ? Colors.white
                                                              : const Color(
                                                                  0xFF060606,
                                                                ))),
                                              fontSize: 22,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          Text(
                                            "${UserState().userName.value} 的小岛·第 ${UserState().savedDiaries.value.length} 天",
                                            style: TextStyle(
                                              color: isLantern
                                                  ? const Color(0xFFE6C78F)
                                                  : (isCottonCandy
                                                        ? (isNight ? Colors.white54 : const Color(0xFF8D7A84))
                                                        : (isNight
                                                              ? Colors.white54
                                                              : Colors.black54)),
                                              fontSize: 12,
                                              fontFamily: 'LXGWWenKai',
                                            ),
                                          ),
                                        ],
                                      )
                                    : const SizedBox.shrink()),

                          Row(
                            children: [
                              if (_currentNavIndex == 0) ...[
                                _buildTopIconButton(
                                  icon: _isLandscape
                                      ? Icons.fullscreen_exit_rounded
                                      : Icons.fullscreen_rounded,
                                  isNight: isNight,
                                  onTap: _toggleOrientation,
                                ),
                                const SizedBox(width: 16),
                                ValueListenableBuilder<String>(
                                  valueListenable: UserState().homeDisplayMode,
                                  builder: (context, mode, _) {
                                    return Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        _buildTopIconButton(
                                          icon: Icons.auto_fix_high_rounded,
                                          isNight: isNight,
                                          onTap: () {
                                            if (mode == 'island') {
                                              // 室外场景：弹出主题切换底栏
                                              showModalBottomSheet(
                                                context: context,
                                                backgroundColor:
                                                    Colors.transparent,
                                                isScrollControlled: true,
                                                showDragHandle: false,
                                                builder: (context) =>
                                                    const IslandThemePicker(),
                                              );
                                            } else {
                                              // 室内场景：跳转到家具装修页
                                              Navigator.push(
                                                context,
                                                MaterialPageRoute(
                                                  builder: (context) =>
                                                      const DecorationPage(),
                                                ),
                                              );
                                            }
                                          },
                                        ),
                                        const SizedBox(width: 16),
                                        _buildTopIconButton(
                                          icon: mode == 'island'
                                              ? Icons.cottage_outlined
                                              : Icons.landscape_outlined,
                                          isNight: isNight,
                                          onTap: () {
                                            final nextMode = mode == 'island'
                                                ? 'house'
                                                : 'island';
                                            UserState().setHomeDisplayMode(
                                              nextMode,
                                            );
                                          },
                                        ),
                                      ],
                                    );
                                  },
                                ),
                              ],
                              if (_currentNavIndex == 1) ...[
                                ValueListenableBuilder<int>(
                                  valueListenable: UserState().diaryLayoutMode,
                                  builder: (context, modeIndex, _) {
                                    final mode =
                                        DiaryLayoutMode.values[modeIndex];
                                    IconData icon;
                                    if (mode == DiaryLayoutMode.calendar) {
                                      icon = Icons.format_list_bulleted_rounded;
                                    } else if (mode ==
                                        DiaryLayoutMode.moments) {
                                      icon = Icons.calendar_month_rounded;
                                    } else {
                                      icon = Icons
                                          .camera_rounded; // 朋友圈图标 (Moments)
                                    }

                                    return _buildTopIconButton(
                                      icon: icon,
                                      isNight: isNight,
                                      onTap: () {
                                        // 循环切换: 时间轴 -> 朋友圈 -> 日历
                                        DiaryLayoutMode nextMode;
                                        if (mode == DiaryLayoutMode.timeline) {
                                          nextMode = DiaryLayoutMode.moments;
                                        } else if (mode ==
                                            DiaryLayoutMode.moments) {
                                          nextMode = DiaryLayoutMode.calendar;
                                        } else {
                                          nextMode = DiaryLayoutMode.timeline;
                                        }
                                        UserState().setDiaryLayoutMode(
                                          nextMode.index,
                                        );
                                      },
                                    );
                                  },
                                ),
                              ],
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

              // 全局气泡：位于导航栏上方
              if (_showGlobalDialogue)
                Positioned(
                  left: 20,
                  right: 20,
                  bottom: _isLandscape
                      ? 60
                      : (MediaQuery.of(context).size.width > 600 ? 170 : 150),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 400),
                      child:
                          SpriteDialogue(
                                text: _globalDialogueText,
                                useTypewriter: true,
                                onNext: () {
                                  setState(() => _showGlobalDialogue = false);
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
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildHomeContent(bool isNight, bool isWide) {
    return MultiValueListenableBuilder(
      listenables: [
        UserState().currentBackgroundPath,
        UserState().homeDisplayMode,
        UserState().selectedIslandThemeId,
      ],
      builder: (context, values, _) {
        final currentBgPath = values[0] as String;
        final displayMode = values[1] as String;
        final themeId = values[2] as String;
        final islandPath = _getIslandImageForCurrentTime();

        // --- 背景及小岛单独调整配置区 ---
        double bgScale = 1.1; // 默认背景缩放
        double bgOffsetY = 0.0; // 默认背景垂直偏移

        double islandScale = 1.0; // 默认小岛缩放
        double islandOffsetY = 0.0; // 默认小岛垂直偏移

        if (themeId == 'cotton_candy') {
          bgScale = 1; // 棉花糖岛背景放大
          bgOffsetY = 0; // 棉花糖背景偏移

          islandScale = 1.1; // 棉花糖小岛放大
          islandOffsetY = 20.0; // 棉花糖小岛向下偏移
        } else if (themeId == 'lantern_festival') {
          bgScale = 1.4; // 元宵节背景放大
          bgOffsetY = -30.0; // 元宵节背景偏移

          islandScale = 1.1; // 元宵节小岛缩放
          islandOffsetY = 0.0; // 元宵节小岛垂直偏移
        } else if (themeId == 'starry_night') {
          bgScale = 1.1;
          bgOffsetY = 0.0;
        }
        // ---------------------------

        return IndexedStack(
          index: displayMode == 'house' ? 1 : 0,
          children: [
            _buildIslandContent(
              isNight,
              isWide,
              currentBgPath,
              islandPath,
              bgScale,
              bgOffsetY,
              islandScale,
              islandOffsetY,
              themeId,
            ),
            _buildHouseContent(isNight, isWide, themeId),
          ],
        );
      },
    );
  }

  Widget _buildIslandContent(
    bool isNight,
    bool isWide,
    String currentBgPath,
    String islandPath,
    double bgScale,
    double bgOffsetY,
    double islandScale,
    double islandOffsetY,
    String themeId,
  ) {
    return Stack(
      key: const ValueKey('island'),
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
            child: Transform.translate(
              offset: Offset(0, bgOffsetY),
              child: Transform.scale(
                scale: bgScale,
                child: Image.asset(
                  currentBgPath,
                  key: ValueKey(currentBgPath),
                  fit: BoxFit.cover,
                ),
              ),
            ),
          ),
        ),
        // 闪烁繁星层 (元宵节主题专属)
        if (!_isLandscape && themeId == 'lantern_festival')
          const Positioned.fill(child: TwinklingStars(count: 35)),
        if (!_isLandscape && themeId != 'lantern_festival')
          Positioned.fill(
            child: FloatingClouds(
              isNight: isNight,
              themeId: themeId,
              shouldAnimate:
                  _currentNavIndex == 0 &&
                  UserState().homeDisplayMode.value == 'island',
            ),
          ),
        if (!_isLandscape && themeId == 'lantern_festival')
          Positioned.fill(
            child: RisingLanterns(
              count: 6,
              isForeground: false, // 背景层灯笼
              shouldAnimate:
                  _currentNavIndex == 0 &&
                  UserState().homeDisplayMode.value == 'island',
            ),
          ),

        // 装饰层：磨砂彩虹 (位于背景云朵之上，前景云朵和岛屿之下)
        if (!isNight)
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: IgnorePointer(
              child: FrostedRainbow(
                width: double.infinity,
                height: MediaQuery.of(context).size.height * 0.55,
                opacity: 0.8,
              ),
            ),
          ),
        // ... rest of the interactive content
        Positioned.fill(
          child: InteractiveViewer(
            transformationController: _transformationController,
            panEnabled: false,
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
                        offset: Offset(
                          0,
                          _floatAnimation.value + islandOffsetY,
                        ),
                        child: Transform.scale(
                          scale: islandScale,
                          child: child,
                        ),
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
                                _getIslandBottomLightColorForCurrentTime()
                                    .withValues(alpha: 0.0),
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
                          width:
                              (currentScreenWidth <= 600
                                  ? currentScreenWidth * 0.9
                                  : 540.0) *
                              1.05,
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
                        child: GestureDetector(
                          onTap: () {
                            _toggleZoom(context, isWide);
                          },
                          child: Image.asset(
                            islandPath,
                            width: currentScreenWidth <= 600
                                ? currentScreenWidth * 0.9
                                : 540.0,
                            fit: BoxFit.contain,
                          ),
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
          Positioned.fill(child: _buildBarrageLayer()),

        if (!_isLandscape && themeId != 'lantern_festival')
          Positioned.fill(
            child: FloatingClouds(
              isNight: isNight,
              isForeground: true,
              themeId: themeId,
              shouldAnimate:
                  _currentNavIndex == 0 &&
                  UserState().homeDisplayMode.value == 'island',
            ),
          ),
        if (!_isLandscape && themeId == 'lantern_festival')
          Positioned.fill(
            child: RisingLanterns(
              count: 4,
              isForeground: true, // 前景层灯笼
              shouldAnimate:
                  _currentNavIndex == 0 &&
                  UserState().homeDisplayMode.value == 'island',
            ),
          ),
        // 移除了内部的顶部操作栏，已提升至上层 Stack
      ],
    );
  }

  Widget _buildHouseContent(bool isNight, bool isWide, String themeId) {
    return ValueListenableBuilder<Uint8List?>(
      valueListenable: UserState().decorationSnapshot,
      builder: (context, snapshot, _) {
        return Stack(
          key: const ValueKey('house'),
          children: [
            // 1. 背景层
            Positioned.fill(child: ScrollingSunBackground(isNight: isNight, themeId: themeId)),
            // 2. 气氛滤镜
            Positioned.fill(
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 1000),
                decoration: BoxDecoration(
                  gradient: isNight
                      ? LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            const Color(0xFF2D1B10).withValues(alpha: 0.35),
                            const Color(0xFF1A0F0A).withValues(alpha: 0.55),
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
            // 3. 房屋快照
            Positioned.fill(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  if (snapshot == null) {
                    return Center(
                      child: Text(
                        "小屋还在装修中...",
                        style: TextStyle(
                          color: isNight ? Colors.white30 : Colors.black26,
                          fontFamily: 'LXGWWenKai',
                        ),
                      ),
                    );
                  }

                  // 复用类似 RecordPage 的比例计算，但为了首页美感稍作调整
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 60),
                      child: AspectRatio(
                        aspectRatio: 1.0, // 强制 1:1 容器
                        child: Container(
                          decoration: isNight
                              ? BoxDecoration(
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: const Color(
                                        0xFF818CF8,
                                      ).withValues(alpha: 0.15),
                                      blurRadius: 100,
                                      spreadRadius: 20,
                                    ),
                                  ],
                                )
                              : null,
                          child: Center(
                            child: Image.memory(snapshot, fit: BoxFit.contain)
                                .animate()
                                .fadeIn(duration: 800.ms)
                                .scale(begin: const Offset(0.95, 0.95)),
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        );
      },
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
                _formatBarrageDate(
                  _groupedEntries[_barrageCurrentIndex].keys.first,
                ),
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
                        ? const Color(0xFFD4A373).withValues(alpha: 0.25)
                        : Colors.black.withValues(alpha: 0.05),
                    width: 0.8,
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
