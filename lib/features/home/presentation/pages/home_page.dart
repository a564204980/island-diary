import 'dart:async';
import 'dart:math';
import 'dart:ui';
import 'dart:io';
import 'dart:convert';
import 'package:archive/archive.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:island_diary/shared/widgets/bottom_nav_bar.dart';
import 'package:island_diary/features/home/presentation/widgets/floating_clouds.dart';
import 'package:island_diary/features/home/presentation/widgets/floating_bricks.dart';
import 'package:island_diary/core/state/user_state.dart';
import 'package:island_diary/core/models/mascot_persona.dart';
import 'package:island_diary/features/record/presentation/pages/record_page.dart';
import 'package:island_diary/features/profile/presentation/pages/profile_page.dart';
import 'package:island_diary/shared/widgets/sprite_dialogue.dart';
import 'package:island_diary/features/record/domain/models/diary_entry.dart';
import 'package:island_diary/features/statistics/presentation/pages/statistics_page.dart';
import 'package:island_diary/shared/widgets/frosted_rainbow.dart';
import 'package:island_diary/shared/widgets/multi_value_listenable_builder.dart';
import 'package:island_diary/features/home/presentation/widgets/island_theme_picker.dart';
import 'package:island_diary/features/home/presentation/widgets/room_scene_overlay.dart';
import 'package:island_diary/features/home/presentation/widgets/backup_reminder_dialog.dart';
import 'package:island_diary/features/home/presentation/widgets/restore_overlays.dart';
import 'package:island_diary/features/home/presentation/widgets/layout_quick_switcher.dart';
import 'package:island_diary/features/home/presentation/widgets/mood_barrage_layer.dart';
import 'package:island_diary/features/home/presentation/widgets/random_memory_overlay.dart';


class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with TickerProviderStateMixin {
  int _currentNavIndex = 0;
  bool _hasPromptedBackupThisSession = false;
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
  bool _isRestoring = false;

  Offset? _pointerDownPos;
  DateTime? _pointerDownTime;

  // 弹幕相关
  List<Map<DateTime, List<DiaryEntry>>> _groupedEntries = [];


  bool get _isNight {
    final themeId = UserState().selectedIslandThemeId.value;
    if (themeId == 'cotton_candy') {
      return UserState().themeMode.value == 'dark' ||
          (UserState().themeMode.value == 'system' &&
              (DateTime.now().hour < 10 || DateTime.now().hour >= 18));
    }
    if (themeId == 'lego') {
      return false;
    }
    if (themeId != 'default' && themeId != 'starry_night') {
      return false;
    }
    return UserState().isNight;
  }

  /// 判定当前是否应该浮现彩虹：限制 13:00 ~ 17:00 且每天仅有 25% 概率（以年月日为种子，同一天内稳定）
  bool get _shouldShowRainbow {
    if (_isNight) return false;
    final now = DateTime.now();
    if (now.hour < 13 || now.hour >= 17) return false;
    final seed = now.year * 10000 + now.month * 100 + now.day;
    return Random(seed).nextDouble() < 0.25;
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

    _groupEntriesByDate();

    // 监听日记变化，实时更新分组
    UserState().savedDiaries.addListener(_groupEntriesByDate);

    // 监听 AI 想法
    UserState().mascotThought.addListener(_onThoughtChanged);

    // 首次进入首页时检测启动事件
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (mounted) {
        // 注册外部文件打开监听通道
        const fileChannel = MethodChannel('com.example.island_diary/file_open');
        fileChannel.setMethodCallHandler((call) async {
          if (call.method == 'onFileReceived') {
            final String? path = call.arguments as String?;
            if (path != null) {
              _handleReceivedFile(path);
            }
          }
          return null;
        });

        // 检查是否有冷启动状态下待处理的外部文件
        try {
          final String? path = await fileChannel.invokeMethod<String>('getPendingFile');
          if (path != null) {
            _handleReceivedFile(path);
          }
        } catch (e) {
          debugPrint("获取外部冷启动文件失败: $e");
        }

        // 我们给 AI 一点时间处理 (2秒内如果 AI 没响，再出保底)
        UserState().checkAppStartEvents();

        await Future.delayed(const Duration(seconds: 3));
        if (mounted && !_showGlobalDialogue) {
          _showLocalFallbackDialogue();
        }
        _checkBackupReminder();
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
    } else if (themeId == 'lego') {
      return 'assets/images/theme/legao/legao_xiaodao.png';
    }

    if (UserState().themeMode.value == 'light') {
      return 'assets/images/home_small_demo.png';
    }
    if (UserState().themeMode.value == 'dark') {
      return 'assets/images/home_small_demo2.png';
    }

    if (_isNight) {
      return 'assets/images/home_small_demo2.png';
    }
    return 'assets/images/home_small_demo.png';
  }

  Color _getIslandGlowColorForCurrentTime() {
    final themeId = UserState().selectedIslandThemeId.value;
    if (themeId == 'cotton_candy') {
      return const Color(0xFFFFE8F5).withValues(alpha: 0.8); // 粉紫色柔光
    }
    if (themeId == 'lego') {
      return const Color(0xFFFFF9E0).withValues(alpha: 0.8); // 暖黄积木柔光
    }

    if (_isNight) {
      return const Color(0xFFFFEFA1).withValues(alpha: 0.65);
    } else {
      return Colors.white.withValues(alpha: 0.9);
    }
  }

  Color _getIslandBottomLightColorForCurrentTime() {
    final themeId = UserState().selectedIslandThemeId.value;
    if (themeId == 'cotton_candy') {
      return _isNight
          ? const Color(0xFFD1C4E9).withValues(alpha: 0.85) // 粉紫色柔光
          : Colors.transparent;
    }
    if (themeId == 'lego') {
      return _isNight
          ? const Color(0xFFFFE082).withValues(alpha: 0.8) // 暖黄底光
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
    if (themeId == 'cotton_candy') {
      return _isNight
          ? const Color(0xFFD1C4E9).withValues(alpha: 0.6) // 底部岩石映照粉紫光
          : Colors.transparent;
    }
    if (themeId == 'lego') {
      return _isNight
          ? const Color(0xFFFFE082).withValues(alpha: 0.6) // 底部岩石映照黄光
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

  Future<void> _showSuccessEffect(List<dynamic> achievements) async {
    // 彻底不渲染成就解锁动画，下线成就系统
  }

  /// 带淡入淡出动画的页面切换，保留页面状态
  Widget _buildAnimatedPage(int pageIndex, Widget child) {
    // 将导航 index 映射到 pageIndex
    final int mappedIndex = _currentNavIndex == 4
        ? 3
        : (_currentNavIndex == 3
              ? 2
              : (_currentNavIndex == 1 ? 1 : 0));
    final bool isVisible = mappedIndex == pageIndex;
    return IgnorePointer(
      ignoring: !isVisible,
      child: AnimatedOpacity(
        opacity: isVisible ? 1.0 : 0.0,
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeInOut,
        child: child,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return MultiValueListenableBuilder(
      listenables: [UserState().themeMode, UserState().selectedIslandThemeId],
      builder: (context, values, child) {
        final String themeId = values[1] as String;
        final bool isNight = _isNight;
        final bool isCottonCandy = themeId == 'cotton_candy';
        final isWide = MediaQuery.of(context).size.width > 600;

        // 动态设置状态栏与底部系统导航栏为全透明，并根据明暗主题自动切换图标颜色，消除安卓黑边与顶部遮罩，实现真正的沉浸式全面屏效果
        SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          systemNavigationBarColor: Colors.transparent,
          systemNavigationBarDividerColor: Colors.transparent,
          statusBarIconBrightness: isNight ? Brightness.light : Brightness.dark,
          systemNavigationBarIconBrightness: isNight ? Brightness.light : Brightness.dark,
          systemStatusBarContrastEnforced: false, // 禁用系统自动的状态栏对比度遮罩层
          systemNavigationBarContrastEnforced: false, // 禁用系统自动的导航栏对比度遮罩层
        ));

        return Scaffold(
          backgroundColor: isNight
              ? const Color(0xFF0D1B2A)
              : const Color(0xFFE6F3F5),
          resizeToAvoidBottomInset: false,
          body: Listener(
            onPointerDown: (event) {
              _pointerDownPos = event.position;
              _pointerDownTime = DateTime.now();
            },
            onPointerUp: (event) {
              if (_pointerDownPos != null && _pointerDownTime != null) {
                final diff = event.position - _pointerDownPos!;
                final duration = DateTime.now().difference(_pointerDownTime!);
                if (diff.distance < 15 && duration.inMilliseconds < 300) {
                  debugPrint('Tap detected at ${event.position}. Active clouds:');
                  for (final entry in CloudRegistry.activeClouds.entries) {
                    debugPrint('  Cloud ${entry.key}: ${entry.value}');
                  }
                  if (_currentNavIndex == 0 &&
                      UserState().homeDisplayMode.value == 'island') {
                    if (CloudRegistry.hitTestClouds(event.position)) {
                      debugPrint('Cloud HIT!');
                      RandomMemoryOverlay.show(context, isNight: _isNight);
                    } else {
                      debugPrint('Cloud MISS');
                    }
                  }
                }
              }
            },
            child: Stack(
              children: [
                Positioned.fill(
                  child: Stack(
                    children: [
                    _buildAnimatedPage(0, _buildHomeContent(isNight, isWide)),
                    _buildAnimatedPage(1, const RecordPage(key: ValueKey('RecordPage'))),
                    _buildAnimatedPage(
                      2,
                      StatisticsPage(
                        key: const ValueKey('StatisticsPage'),
                        isActive: _currentNavIndex == 3,
                      ),
                    ),
                    _buildAnimatedPage(3, const ProfilePage(key: ValueKey('ProfilePage'))),
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
                                        color: isNight
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
                                    ? Builder(
                                        builder: (context) {
                                          final isLego = UserState().selectedIslandThemeId.value == 'lego';
                                          final headerFont = isLego ? 'SweiFistLeg' : 'LXGWWenKai';
                                          return Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Row(
                                                mainAxisSize: MainAxisSize.min,
                                                crossAxisAlignment: CrossAxisAlignment.center,
                                                children: [
                                                  Text(
                                                    "我的岛屿日记",
                                                    style: TextStyle(
                                                      color: isCottonCandy
                                                          ? (isNight ? Colors.white : const Color(0xFF4E3A46))
                                                          : (isNight
                                                              ? Colors.white
                                                              : const Color(0xFF3B2E25)),
                                                      fontSize: 22,
                                                      fontWeight: FontWeight.bold,
                                                      fontFamily: headerFont,
                                                    ),
                                                  ),
                                                  const SizedBox(width: 6),
                                                  Icon(
                                                    Icons.star_rounded,
                                                    color: const Color(0xFFFFCC99).withValues(alpha: 0.9),
                                                    size: 18,
                                                  ),
                                                ],
                                              ),
                                              const SizedBox(height: 4),
                                              Text(
                                                "${UserState().userName.value} 的小岛 · 第 ${UserState().savedDiaries.value.length} 天",
                                                style: TextStyle(
                                                  color: isCottonCandy
                                                      ? (isNight ? Colors.white54 : const Color(0xFF8D7A84))
                                                      : (isNight ? Colors.white54 : const Color(0xFF7E7570)),
                                                  fontSize: 12,
                                                  fontFamily: headerFont,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ],
                                          );
                                        },
                                      )
                                    : const SizedBox.shrink()),

                          Row(
                            children: [
                              if (_currentNavIndex == 0) ...[
                                _buildTopIconButton(
                                  icon: Icons.auto_fix_high_rounded,
                                   isNight: isNight,
                                   onTap: () {
                                     showModalBottomSheet(
                                       context: context,
                                       backgroundColor:
                                           Colors.transparent,
                                       isScrollControlled: true,
                                       showDragHandle: false,
                                       builder: (context) =>
                                           const IslandThemePicker(),
                                     );
                                   },
                                 ),
                                  const SizedBox(width: 16),
                                  _buildTopIconButton(
                                    icon: Icons.home_work_rounded,
                                    isNight: isNight,
                                    onTap: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) => const RoomDecorationPage(),
                                        ),
                                      );
                                    },
                                  ),
                                 const SizedBox(width: 16),
                                _buildTopIconButton(
                                  icon: _isLandscape
                                      ? Icons.fullscreen_exit_rounded
                                      : Icons.fullscreen_rounded,
                                  isNight: isNight,
                                  onTap: _toggleOrientation,
                                ),
                              ],
                              if (_currentNavIndex == 1) ...[
                                LayoutQuickSwitcher(isNight: isNight),
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
                      _checkBackupReminder();
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
                                autoDismiss: true,
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
              // 侧边右侧沙漏按钮：仅在首页显示
              if (_currentNavIndex == 0 && !_isLandscape)
                Positioned(
                  right: 24,
                  top: MediaQuery.of(context).size.height * 0.45,
                  child: _buildTopIconButton(
                    icon: Icons.hourglass_empty_rounded,
                    isNight: isNight,
                    animate: false,
                    onTap: () => RandomMemoryOverlay.show(context, isNight: isNight),
                  ),
                ),

              if (_isRestoring)
                RestoreLoadingOverlay(
                  text: "正在还原备份数据，请稍候...",
                  isNight: isNight,
                  fontFamily: themeId == 'lego' ? 'SweiFistLeg' : 'LXGWWenKai',
                ),
            ],
          ),
        ),
      );
      },
    );
  }

  Widget _buildHomeContent(bool isNight, bool isWide) {
    return MultiValueListenableBuilder(
      listenables: [
        UserState().currentBackgroundPath,
        UserState().selectedIslandThemeId,
      ],
      builder: (context, values, _) {
        final currentBgPath = values[0] as String;
        final themeId = values[1] as String;
        final islandPath = _getIslandImageForCurrentTime();

        // --- 背景及小岛单独调整配置区 ---
        double bgScale = 1.1; // 默认背景缩放
        double bgOffsetY = 0.0; // 默认背景垂直偏移

        double islandScale = 1.0; // 默认小岛缩放
        double islandOffsetY = 0.0; // 默认小岛垂直偏移

        if (themeId == 'cotton_candy') {
          bgScale = 1; // 棉花糖岛背景放大
          bgOffsetY = 0; // 棉花糖背景偏移

          islandScale = 1.0; // 棉花糖小岛大小为1.0
          islandOffsetY = 15.0; // 对应偏移微调为15.0
        } else if (themeId == 'lego') {
          bgScale = 1.1;
          bgOffsetY = 0.0;
        }
        // ---------------------------

        return _buildIslandContent(
          isNight,
          isWide,
          currentBgPath,
          islandPath,
          bgScale,
          bgOffsetY,
          islandScale,
          islandOffsetY,
          themeId,
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
            child: GestureDetector(
              onLongPressStart: (_) {
                if (themeId == 'cotton_candy') {
                  UserState().cloudSpeedMultiplier.value = 25.0; // 快速移动
                }
              },
              onLongPressEnd: (_) {
                if (themeId == 'cotton_candy') {
                  UserState().cloudSpeedMultiplier.value = 1.0; // 恢复正常速度
                }
              },
              onLongPressCancel: () {
                if (themeId == 'cotton_candy') {
                  UserState().cloudSpeedMultiplier.value = 1.0;
                }
              },
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
        ),
        if (!_isLandscape && themeId != 'lego')
          Positioned.fill(
            child: FloatingClouds(
              isNight: isNight,
              themeId: themeId,
              shouldAnimate:
                  _currentNavIndex == 0 &&
                  UserState().homeDisplayMode.value == 'island',
            ),
          ),

        // 装饰层：磨砂彩虹 (位于背景云朵之上，前景云朵和岛屿之下)
        if (_shouldShowRainbow)
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
          child: GestureDetector(
            onLongPressStart: (_) {
              if (themeId == 'cotton_candy') {
                UserState().cloudSpeedMultiplier.value = 25.0;
              }
            },
            onLongPressEnd: (_) {
              if (themeId == 'cotton_candy') {
                UserState().cloudSpeedMultiplier.value = 1.0;
              }
            },
            onLongPressCancel: () {
              if (themeId == 'cotton_candy') {
                UserState().cloudSpeedMultiplier.value = 1.0;
              }
            },
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
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 600), // 黄金 600ms 过渡
                      switchInCurve: Curves.easeInOutCubic,
                      switchOutCurve: Curves.easeInOutCubic,
                      transitionBuilder: (Widget child, Animation<double> animation) {
                        // 判定是否是正在淡入的新小岛
                        final isNewChild = child.key == ValueKey(islandPath);
                        
                        // 精准驱动上下沉降平移：新小岛从下方升起，旧小岛向下方沉降隐去
                        final slideTween = isNewChild
                            ? Tween<Offset>(begin: const Offset(0.0, 0.06), end: Offset.zero)
                            : Tween<Offset>(begin: Offset.zero, end: const Offset(0.0, 0.06));

                        return FadeTransition(
                          opacity: animation,
                          child: ScaleTransition(
                            scale: Tween<double>(begin: 0.95, end: 1.0).animate(
                              CurvedAnimation(
                                parent: animation,
                                curve: Curves.easeInOutCubic,
                              ),
                            ),
                            child: SlideTransition(
                              position: slideTween.animate(
                                CurvedAnimation(
                                  parent: animation,
                                  curve: Curves.easeInOutCubic,
                                ),
                              ),
                              child: child,
                            ),
                          ),
                        );
                      },
                      child: Stack(
                        key: ValueKey(islandPath), // 以当前小岛资源路径为 key，触发丝滑转场
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
                          // 替换原高能耗的高斯模糊发光 ImageFiltered 为超高性能的椭圆 RadialGradient 渐变光晕
                          Container(
                            width: isWide ? 500 : currentScreenWidth * 0.85,
                            height: isWide ? 220 : currentScreenWidth * 0.42,
                            decoration: BoxDecoration(
                              gradient: RadialGradient(
                                colors: [
                                  _getIslandGlowColorForCurrentTime().withValues(alpha: 0.5),
                                  _getIslandGlowColorForCurrentTime().withValues(alpha: 0.0),
                                ],
                                stops: const [0.2, 1.0],
                              ),
                            ),
                          ),
                          RepaintBoundary(
                            child: ShaderMask(
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
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ),

        // 将 FloatingBricks 置于 InteractiveViewer 岛屿层的上方，防止被岛屿的 GestureDetector/全屏容器拦截手势
        if (!_isLandscape && themeId == 'lego')
          const Positioned.fill(
            child: FloatingBricks(),
          ),

        if (_isLandscape && _groupedEntries.isNotEmpty)
          Positioned.fill(
            child: MoodBarrageLayer(groupedEntries: _groupedEntries),
          ),

        if (!_isLandscape && themeId != 'lego')
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
        // 移除了内部的顶部操作栏，已提升至上层 Stack
      ],
    );
  }




  Widget _buildTopIconButton({
    required IconData icon,
    required bool isNight,
    required VoidCallback onTap,
    bool animate = true,
  }) {
    final button = GestureDetector(
          onTap: onTap,
          child: RepaintBoundary(
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
          ),
        );
    if (!animate) return button;
    return button
        .animate(onPlay: (controller) => controller.repeat(reverse: true))
        .scale(
          begin: const Offset(1, 1),
          end: const Offset(1.05, 1.05),
          duration: 3.seconds,
          curve: Curves.easeInOut,
        );
  }

  Future<void> _handleReceivedFile(String path) async {
    final file = File(path);
    if (!await file.exists()) return;

    final themeId = UserState().selectedIslandThemeId.value;
    final fontFamily = themeId == 'lego' ? 'SweiFistLeg' : 'LXGWWenKai';

    if (!mounted) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        final isNight = UserState().isNight;
        return AlertDialog(
          backgroundColor: isNight ? const Color(0xFF2C281F) : const Color(0xFFFFFDF6),
          title: Text('检测到外部日记备份包', style: TextStyle(fontFamily: fontFamily)),
          content: Text('确认从此备份还原所有数据？此操作将覆盖您当前的全部日记，且不可撤销。', style: TextStyle(fontFamily: fontFamily)),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                if (file.existsSync()) {
                  file.deleteSync();
                }
              },
              child: Text('取消', style: TextStyle(fontFamily: fontFamily, color: isNight ? Colors.white38 : Colors.black38)),
            ),
            TextButton(
              onPressed: () async {
                Navigator.pop(context);
                _performFileRestore(file);
              },
              child: const Text('确认还原', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
            ),
          ],
        );
      },
    );
  }

  Future<void> _performFileRestore(File file) async {
    if (!mounted) return;

    setState(() => _isRestoring = true);

    try {
      final zipBytes = await file.readAsBytes();
      final zipDecoder = ZipDecoder();
      final archive = zipDecoder.decodeBytes(zipBytes);
      final ArchiveFile? dataFile = archive.findFile("island_data.json");
      if (dataFile == null) throw Exception("无效的备份文件");

      final obfuscatedBytes = dataFile.content as List<int>;
      final secret = utf8.encode("IslandVault_Secure_2026_!@#");
      final rawBytes = Uint8List(obfuscatedBytes.length);
      for (var i = 0; i < obfuscatedBytes.length; i++) {
        rawBytes[i] = obfuscatedBytes[i] ^ secret[i % secret.length];
      }

      final jsonContent = utf8.decode(rawBytes);
      final Map<String, dynamic> backupMap = jsonDecode(jsonContent);

      if (backupMap['signature'] != "ISLAND_DIARY_CRYSTAL_VAULT_V1") {
        throw Exception("文件签名不正确");
      }

      final data = backupMap['data'] as Map<String, dynamic>;
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();

      for (var entry in data.entries) {
        final key = entry.key;
        final value = entry.value;
        if (value is String) {
          await prefs.setString(key, value);
        } else if (value is int) {
          await prefs.setInt(key, value);
        } else if (value is bool) {
          await prefs.setBool(key, value);
        } else if (value is double) {
          await prefs.setDouble(key, value);
        } else if (value is List) {
          await prefs.setStringList(key, List<String>.from(value));
        }
      }

      await UserState().loadFromStorage();

      // 提供 1.5 秒动画时间
      await Future.delayed(const Duration(milliseconds: 1500));

      if (mounted) {
        setState(() => _isRestoring = false);
        final themeId = UserState().selectedIslandThemeId.value;
        final fontFamily = themeId == 'lego' ? 'SweiFistLeg' : 'LXGWWenKai';
        RestoreSuccessDialog.show(context, fontFamily: fontFamily, isNight: _isNight);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isRestoring = false);
      }
    } finally {
      if (file.existsSync()) {
        try {
          file.deleteSync();
        } catch (_) {}
      }
    }
  }

  Future<void> _checkBackupReminder() async {
    if (_hasPromptedBackupThisSession) return;

    final prefs = await SharedPreferences.getInstance();
    int? intervalSeconds = prefs.getInt('backup_reminder_interval_seconds');
    if (intervalSeconds == null) {
      final oldDays = prefs.getInt('backup_reminder_interval_days');
      if (oldDays != null) {
        intervalSeconds = oldDays * 86400;
        await prefs.setInt('backup_reminder_interval_seconds', intervalSeconds);
      } else {
        intervalSeconds = 7 * 86400; // 默认 7 天
      }
    }

    if (intervalSeconds == 0) return; // 0 表示关闭提醒

    final lastBackupMs = prefs.getInt('last_backup_time');
    final now = DateTime.now();

    if (lastBackupMs == null) {
      // 首次使用，记录当前时间作为初始基准，避免直接弹窗打扰用户
      await prefs.setInt('last_backup_time', now.millisecondsSinceEpoch);
      return;
    }

    final lastBackupTime = DateTime.fromMillisecondsSinceEpoch(lastBackupMs);
    final differenceSeconds = now.difference(lastBackupTime).inSeconds;

    if (differenceSeconds >= intervalSeconds) {
      if (!mounted) return;
      _hasPromptedBackupThisSession = true;
      final themeId = UserState().selectedIslandThemeId.value;
      final fontFamily = themeId == 'lego' ? 'SweiFistLeg' : 'LXGWWenKai';
      BackupReminderDialog.show(
        context,
        overdueSeconds: differenceSeconds,
        isNight: _isNight,
        fontFamily: fontFamily,
      );
    }
  }

}
