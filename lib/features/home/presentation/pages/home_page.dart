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
import 'package:island_diary/features/home/presentation/widgets/rising_lanterns.dart';
import 'package:island_diary/features/home/presentation/widgets/twinkling_stars.dart';
import 'package:island_diary/core/state/user_state.dart';
import 'package:island_diary/core/models/mascot_persona.dart';
import 'package:island_diary/features/record/presentation/pages/record_page.dart';
import 'package:island_diary/features/profile/presentation/pages/profile_page.dart';
import 'package:island_diary/features/profile/presentation/pages/cloud_sync_page.dart';
import 'package:island_diary/shared/widgets/barrage/mood_barrage_wall.dart';
import 'package:island_diary/shared/widgets/sprite_dialogue.dart';
import 'package:island_diary/features/record/domain/models/diary_entry.dart';
import 'package:island_diary/features/statistics/presentation/pages/statistics_page.dart';
import 'package:island_diary/shared/widgets/frosted_rainbow.dart';
import 'package:island_diary/shared/widgets/multi_value_listenable_builder.dart';
import 'package:island_diary/features/record/presentation/widgets/diary_history_overlay.dart';
import 'package:island_diary/features/home/presentation/widgets/island_theme_picker.dart';
import 'package:island_diary/features/home/presentation/widgets/room_scene_overlay.dart';

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

    _barragePageController = PageController();
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

  Future<void> _showSuccessEffect(List<dynamic> achievements) async {
    // 彻底不渲染成就解锁动画，下线成就系统
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
                                                      : (isNight ? Colors.white54 : const Color(0xFF8B7E74)),
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
                                _buildLayoutQuickSwitcher(isNight),
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
              if (_isRestoring)
                _buildLoadingOverlay("正在还原备份数据，请稍候...", isNight, themeId == 'lego' ? 'SweiFistLeg' : 'LXGWWenKai'),
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
          Positioned.fill(child: _buildBarrageLayer()),

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

  Widget _buildLayoutQuickSwitcher(bool isNight) {
    final currentModeIndex = UserState().diaryLayoutMode.value;
    final themeId = UserState().selectedIslandThemeId.value;

    Color activeColor;
    Color selectedIconColor;
    Color unselectedIconColor;
    Color containerColor;
    Color borderColor;

    if (themeId == 'cotton_candy') {
      activeColor = const Color(0xFFFF94B8);
      selectedIconColor = Colors.white;
      unselectedIconColor = isNight
          ? Colors.white.withValues(alpha: 0.6)
          : const Color(0xFF6F5E63).withValues(alpha: 0.6);
      containerColor = isNight
          ? const Color(0xFF8676FF).withValues(alpha: 0.25)
          : const Color(0xFFFFCADB).withValues(alpha: 0.45);
      borderColor = isNight
          ? const Color(0xFFB19FFB).withValues(alpha: 0.3)
          : const Color(0xFFFFD1E1).withValues(alpha: 0.45);
    } else if (themeId == 'lego') {
      activeColor = const Color(0xFFFFD54F);
      selectedIconColor = const Color(0xFF3B2E25);
      unselectedIconColor = isNight
          ? Colors.white.withValues(alpha: 0.6)
          : Colors.black.withValues(alpha: 0.5);
      containerColor = isNight
          ? Colors.white.withValues(alpha: 0.12)
          : Colors.black.withValues(alpha: 0.15);
      borderColor = isNight
          ? Colors.white.withValues(alpha: 0.1)
          : Colors.black.withValues(alpha: 0.08);
    } else {
      // 默认水蓝色主题
      activeColor = isNight ? const Color(0xFF00ACC1) : const Color(0xFF83B7C5);
      selectedIconColor = Colors.white;
      unselectedIconColor = isNight
          ? Colors.white.withValues(alpha: 0.6)
          : const Color(0xFF83B7C5);
      containerColor = isNight
          ? const Color(0xFF1B2A4A).withValues(alpha: 0.4)
          : const Color(0xFFEDF5F7).withValues(alpha: 0.7);
      borderColor = isNight
          ? const Color(0xFF80D8FF).withValues(alpha: 0.25)
          : const Color(0xFF83B7C5).withValues(alpha: 0.65);
    }

    final List<DiaryLayoutMode> modes = [
      DiaryLayoutMode.masonry,
      DiaryLayoutMode.timeline,
      DiaryLayoutMode.calendar,
    ];

    final selectedIndex = modes.indexOf(
      DiaryLayoutMode.values[currentModeIndex.clamp(0, DiaryLayoutMode.values.length - 1)],
    ).clamp(0, 2);

    final List<IconData> icons = [
      Icons.view_quilt_rounded,
      Icons.format_list_bulleted_rounded,
      Icons.calendar_month_rounded,
    ];

    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          width: 120,
          height: 36,
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: containerColor,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: borderColor,
              width: 0.8,
            ),
          ),
          child: Stack(
            children: [
              AnimatedAlign(
                duration: const Duration(milliseconds: 280),
                curve: Curves.easeInOut,
                alignment: selectedIndex == 0
                    ? Alignment.centerLeft
                    : (selectedIndex == 1
                        ? Alignment.center
                        : Alignment.centerRight),
                child: FractionallySizedBox(
                  widthFactor: 0.33,
                  child: Container(
                    decoration: BoxDecoration(
                      color: activeColor,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
              ),
              Positioned.fill(
                child: Row(
                  children: List.generate(modes.length, (i) {
                    final isSelected = i == selectedIndex;
                    return Expanded(
                      child: GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: () {
                          UserState().setDiaryLayoutMode(modes[i].index);
                          setState(() {});
                        },
                        child: Center(
                          child: Icon(
                            icons[i],
                            size: 18,
                            color: isSelected
                                ? selectedIconColor
                                : unselectedIconColor,
                          ),
                        ),
                      ),
                    );
                  }),
                ),
              ),
            ],
          ),
        ),
      ),
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
        _showSuccessDialog(fontFamily);
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
      _showBackupReminderDialog(differenceSeconds);
    }
  }

  String _formatOverdueTime(int totalSeconds) {
    final days = totalSeconds ~/ 86400;
    final hours = (totalSeconds % 86400) ~/ 3600;
    final minutes = (totalSeconds % 3600) ~/ 60;
    final seconds = totalSeconds % 60;

    final parts = <String>[];
    if (days > 0) parts.add('$days天');
    if (hours > 0) parts.add('$hours小时');
    if (minutes > 0) parts.add('$minutes分钟');
    if (seconds > 0 || parts.isEmpty) parts.add('$seconds秒');

    return parts.join('');
  }

  void _showBackupReminderDialog(int overdueSeconds) {
    final themeId = UserState().selectedIslandThemeId.value;
    final fontFamily = themeId == 'lego' ? 'SweiFistLeg' : 'LXGWWenKai';
    final isNight = _isNight;
    final overdueStr = _formatOverdueTime(overdueSeconds);

    showDialog(
      context: context,
      barrierDismissible: true,
      barrierColor: Colors.black.withValues(alpha: 0.4),
      builder: (context) {
        return BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Dialog(
            backgroundColor: Colors.transparent,
            elevation: 0,
            child: Stack(
              clipBehavior: Clip.none,
              alignment: Alignment.topCenter,
              children: [
                // 1. 主体卡片
                Container(
                  width: 320,
                  decoration: BoxDecoration(
                    color: isNight ? const Color(0xFF1E293B) : const Color(0xFFFFFDF9),
                    borderRadius: BorderRadius.circular(32),
                    border: Border.all(
                      color: isNight
                          ? Colors.white.withValues(alpha: 0.15)
                          : const Color(0xFFEADCC9),
                      width: 2.0,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: isNight ? 0.4 : 0.12),
                        blurRadius: 36,
                        spreadRadius: 2,
                        offset: const Offset(0, 16),
                      ),
                    ],
                  ),
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      // 左侧虚线心形线条装饰
                      Positioned(
                        left: 12,
                        top: 60,
                        child: CustomPaint(
                          size: const Size(30, 60),
                          painter: _LeftCurvePainter(isNight: isNight),
                        ),
                      ),
                      // 右侧植物分支与星光装饰
                      Positioned(
                        right: 12,
                        top: 40,
                        child: Icon(
                          Icons.local_florist_rounded,
                          color: isNight ? Colors.white.withValues(alpha: 0.1) : const Color(0xFFD7CCC8).withValues(alpha: 0.5),
                          size: 28,
                        ),
                      ),
                      Positioned(
                        right: 20,
                        top: 80,
                        child: Icon(
                          Icons.star_rounded,
                          color: isNight ? Colors.white.withValues(alpha: 0.1) : const Color(0xFFFFE082).withValues(alpha: 0.5),
                          size: 14,
                        ),
                      ),
                      
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // 头部悬浮头像在主体卡片内部的占位高度，确保标题不与头像重叠
                            const SizedBox(height: 54),
                            
                            // 标题
                            Text(
                              '别忘了备份今天的回忆',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: isNight ? Colors.white.withValues(alpha: 0.9) : const Color(0xFF3E2723),
                                fontFamily: fontFamily,
                                letterSpacing: 0.5,
                              ),
                            ),
                            const SizedBox(height: 16),
                            
                            // 状态小药丸布局
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              decoration: BoxDecoration(
                                color: isNight
                                    ? Colors.white.withValues(alpha: 0.05)
                                    : const Color(0xFFEDF2F7),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(
                                    Icons.access_time_rounded,
                                    color: Color(0xFF00ACC1),
                                    size: 16,
                                  ),
                                  const SizedBox(width: 6),
                                  RichText(
                                    text: TextSpan(
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: isNight ? Colors.white70 : const Color(0xFF5D5450),
                                        fontFamily: fontFamily,
                                      ),
                                      children: [
                                        const TextSpan(text: '已 '),
                                        TextSpan(
                                          text: overdueStr,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            color: Color(0xFF00ACC1),
                                          ),
                                        ),
                                        const TextSpan(text: ' 未备份'),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 20),
                            
                            // 描述内容
                            Column(
                              children: [
                                Text(
                                  '你的日记和回忆还没有完成备份',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: isNight ? Colors.white60 : const Color(0xFF8D827A),
                                    fontFamily: fontFamily,
                                    height: 1.5,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '去给珍贵的数据加一份安心守护吧',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: isNight ? Colors.white60 : const Color(0xFF8D827A),
                                    fontFamily: fontFamily,
                                    height: 1.5,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 28),
                            
                            // 按钮栏
                            Row(
                              children: [
                                Expanded(
                                  child: _buildReminderOutlineButton(
                                    label: '稍后提醒',
                                    isNight: isNight,
                                    fontFamily: fontFamily,
                                    onPressed: () => Navigator.pop(context),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: _buildReminderGradientButton(
                                    label: '立即备份',
                                    isNight: isNight,
                                    fontFamily: fontFamily,
                                    onPressed: () {
                                      Navigator.pop(context);
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) => const CloudSyncPage(),
                                        ),
                                      );
                                    },
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 24),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                
                // 2. 头部悬浮的 Mascot 头像（半个圆在主体卡片上方）
                Positioned(
                  top: -42, // 直径 84，向上偏移 42
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isNight ? const Color(0xFF0F172A) : Colors.white,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isNight
                            ? const Color(0xFF00ACC1).withValues(alpha: 0.4)
                            : const Color(0xFFE0F7FA),
                        width: 4.0,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF00ACC1).withValues(alpha: isNight ? 0.3 : 0.15),
                          blurRadius: 18,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: Image.asset(
                      UserState().selectedMascotType.value,
                      width: 60,
                      height: 60,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildReminderOutlineButton({
    required String label,
    required bool isNight,
    required String fontFamily,
    required VoidCallback onPressed,
  }) {
    return SizedBox(
      height: 48,
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          side: BorderSide(
            color: isNight ? Colors.white24 : const Color(0xFFE2E8F0),
            width: 1.5,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          backgroundColor: isNight ? Colors.white.withValues(alpha: 0.03) : const Color(0xFFF8FAFC),
          elevation: 0,
          padding: EdgeInsets.zero,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.access_alarm_rounded,
              size: 18,
              color: isNight ? Colors.white70 : const Color(0xFF64748B),
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: isNight ? Colors.white70 : const Color(0xFF64748B),
                fontFamily: fontFamily,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReminderGradientButton({
    required String label,
    required bool isNight,
    required String fontFamily,
    required VoidCallback onPressed,
  }) {
    return Container(
      height: 48,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: const LinearGradient(
          colors: [Color(0xFF4DD0E1), Color(0xFF00ACC1)],
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF00ACC1).withValues(alpha: 0.35),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          elevation: 0,
          padding: EdgeInsets.zero,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.cloud_upload_rounded,
              size: 18,
              color: Colors.white,
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Colors.white,
                fontFamily: fontFamily,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showSuccessDialog(String fontFamily) {
    final isNight = _isNight;
    showDialog(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.5),
      builder: (context) {
        Future.delayed(const Duration(milliseconds: 1500), () {
          if (context.mounted) {
            Navigator.pop(context);
          }
        });

        return Dialog(
          backgroundColor: Colors.transparent,
          elevation: 0,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(28),
                decoration: BoxDecoration(
                  color: isNight ? const Color(0xFF1E293B) : Colors.white,
                  borderRadius: BorderRadius.circular(28),
                  border: Border.all(
                    color: isNight ? Colors.white.withValues(alpha: 0.1) : const Color(0xFF00ACC1).withValues(alpha: 0.2),
                    width: 1.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF00ACC1).withValues(alpha: isNight ? 0.3 : 0.15),
                      blurRadius: 30,
                      offset: const Offset(0, 12),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    // 渐变流光勾号
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: const BoxDecoration(
                        color: Color(0xFF00ACC1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.check_rounded,
                        color: Colors.white,
                        size: 32,
                      ),
                    ).animate().scale(curve: Curves.elasticOut, duration: 800.ms),
                    const SizedBox(height: 20),
                    Text(
                      '记忆复苏成功！',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: isNight ? Colors.white : const Color(0xFF1A1A1A),
                        fontFamily: fontFamily,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '我们的岛屿已安全重建 ✨',
                      style: TextStyle(
                        fontSize: 13,
                        color: isNight ? Colors.white60 : Colors.black54,
                        fontFamily: fontFamily,
                      ),
                    ),
                  ],
                ),
              ).animate().fadeIn(duration: 400.ms).scale(begin: const Offset(0.8, 0.8), end: const Offset(1.0, 1.0), curve: Curves.easeOutBack),
            ],
          ),
        );
      },
    );
  }

  Widget _buildLoadingOverlay(String text, bool isNight, String fontFamily) {
    return Positioned.fill(
      child: ClipRRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 15.0, sigmaY: 15.0),
          child: Container(
            color: Colors.black.withValues(alpha: isNight ? 0.5 : 0.35),
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // 旋转的流光光圈与跳动的小伙伴容器
                  Stack(
                    alignment: Alignment.center,
                    children: [
                      // 旋转流光圈
                      Container(
                        width: 110,
                        height: 110,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: Colors.transparent,
                          ),
                          gradient: const SweepGradient(
                            colors: [
                              Color(0xFF00ACC1),
                              Color(0xFF818CF8),
                              Color(0xFFCE93D8),
                              Color(0xFF00ACC1),
                            ],
                          ),
                        ),
                      )
                      .animate(onPlay: (controller) => controller.repeat())
                      .rotate(duration: 2.seconds),
                      
                      // 内层遮罩，制造环形感
                      Container(
                        width: 102,
                        height: 102,
                        decoration: BoxDecoration(
                          color: isNight ? const Color(0xFF161513) : const Color(0xFFFAF7F0),
                          shape: BoxShape.circle,
                        ),
                      ),
                      
                      // 永久弹性跳动的小胖形象 (Mascot)
                      Image.asset(
                        UserState().selectedMascotType.value,
                        width: 60,
                        height: 60,
                      )
                      .animate(onPlay: (controller) => controller.repeat(reverse: true))
                      .moveY(begin: -8, end: 8, duration: 800.ms, curve: Curves.easeInOutCubic)
                      .rotate(begin: -0.05, end: 0.05, duration: 800.ms, curve: Curves.easeInOutCubic),
                    ],
                  ),
                  const SizedBox(height: 28),
                  
                  // 呼吸灯文字
                  Text(
                    text,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: isNight ? Colors.white.withValues(alpha: 0.9) : const Color(0xFF374151),
                      fontFamily: fontFamily,
                      letterSpacing: 0.8,
                    ),
                  )
                  .animate(onPlay: (controller) => controller.repeat(reverse: true))
                  .fadeIn(duration: 1.seconds, curve: Curves.easeInOut),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _LeftCurvePainter extends CustomPainter {
  final bool isNight;
  _LeftCurvePainter({required this.isNight});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = isNight ? Colors.white.withValues(alpha: 0.12) : const Color(0xFFD7CCC8)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;

    // 绘制二次贝塞尔曲线点集，实现虚线效果
    for (var i = 0; i <= 20; i++) {
      final t = i / 20;
      // 曲线起始点 (0, 0)，控制点 (22, 18)，终点 (10, 52)
      final x = (1 - t) * (1 - t) * 0 + 2 * (1 - t) * t * 22 + t * t * 10;
      final y = (1 - t) * (1 - t) * 0 + 2 * (1 - t) * t * 18 + t * t * 52;
      
      if (i % 2 == 0) {
        canvas.drawCircle(Offset(x, y), 1.0, paint);
      }
    }
    
    // 在曲线终点绘制一个精美的小心形 (Color: Color(0xFF81D4FA))
    final heartPaint = Paint()
      ..color = const Color(0xFF81D4FA)
      ..style = PaintingStyle.fill;
      
    final heartPath = Path();
    const hx = 10.0;
    const hy = 52.0;
    
    // 心形绘制路径以 hx, hy 为顶端交汇点
    heartPath.moveTo(hx, hy);
    heartPath.cubicTo(hx - 3, hy - 3, hx - 6, hy, hx, hy + 5);
    heartPath.cubicTo(hx + 6, hy, hx + 3, hy - 3, hx, hy);
    canvas.drawPath(heartPath, heartPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
