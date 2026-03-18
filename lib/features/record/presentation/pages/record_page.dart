import 'dart:async';
import 'dart:math';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:island_diary/core/state/user_state.dart';
import 'package:island_diary/shared/widgets/sprite_animation.dart';
import 'package:island_diary/shared/widgets/sprite_dialogue.dart';
import 'package:island_diary/shared/widgets/mood_picker/config/mood_config.dart';
import 'package:island_diary/features/record/domain/models/diary_entry.dart';
import 'package:island_diary/shared/widgets/diary_entry/utils/diary_utils.dart';

class RecordPage extends StatefulWidget {
  const RecordPage({super.key});

  @override
  State<RecordPage> createState() => _RecordPageState();
}

class _RecordPageState extends State<RecordPage>
    with SingleTickerProviderStateMixin {
  late ScrollController _scrollController;
  double _aspectRatio = 1.0;

  // 跳跃动画相关
  late AnimationController _jumpController;
  late Animation<double> _jumpAnimation;
  bool _isJumpStarted = false;
  bool _showDeskDialogue = false; // 【新增】控制桌面气泡显示
  bool _showBookHint = false; // 【新增】控制书籍互动提示显示
  Timer? _jumpTimer;
  Timer? _dialogueTimer; // 【新增】处理落地后的延迟
  Timer? _bookHintTimer; // 【新增】控制书籍提示出现的时机

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _resolveImageSize();

    _jumpController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 4000), // 总计 4 秒：1s 跳 + 2s 停 + 1s 跳
    );

    _jumpAnimation = CurvedAnimation(
      parent: _jumpController,
      curve: Curves.linear, // 手动在各个阶段做缓动处理，外层用线性
    );

    // 如果还没看过引导，则启动引导序列
    if (!UserState().hasSeenRecordGuidance.value) {
      // 落地监听：完成后等待 0.5s 弹出对话
      _jumpController.addStatusListener((status) {
        if (status == AnimationStatus.completed) {
          _dialogueTimer = Timer(const Duration(milliseconds: 500), () {
            if (mounted) {
              setState(() => _showDeskDialogue = true);
            }
          });
          // 对话框弹出 1.2 秒后，书籍提示淡入
          _bookHintTimer = Timer(const Duration(milliseconds: 1700), () {
            if (mounted) {
              setState(() => _showBookHint = true);
            }
          });
        }
      });

      // 延迟 1.5s 触发跳跃
      _jumpTimer = Timer(const Duration(milliseconds: 1500), () {
        if (mounted) {
          setState(() => _isJumpStarted = true);
          UserState().isSlimeInBottomMenu.value = false;
          _jumpController.forward();
          // 触发跳跃即视为开始引导
          UserState().completeRecordGuidance();
        }
      });
    } else {
      // 非初次进入，直接显示书籍提示，不触发小软引导
      _showBookHint = true;
    }
  }

  void _resolveImageSize() {
    const path = 'assets/images/indoor.png';
    final ImageStream stream = const AssetImage(
      path,
    ).resolve(ImageConfiguration.empty);
    stream.addListener(
      ImageStreamListener((ImageInfo info, bool _) {
        if (mounted) {
          setState(() {
            _aspectRatio = info.image.width / info.image.height;
          });
          _centerBackground();
        }
      }),
    );
  }

  void _centerBackground() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        final double maxScroll = _scrollController.position.maxScrollExtent;
        _scrollController.jumpTo(maxScroll / 2);
      }
    });
  }

  @override
  void dispose() {
    _jumpTimer?.cancel();
    _dialogueTimer?.cancel();
    _bookHintTimer?.cancel();
    _jumpController.dispose();
    _scrollController.dispose();
    // 恢复小软状态
    WidgetsBinding.instance.addPostFrameCallback((_) {
      UserState().isSlimeInBottomMenu.value = true;
    });
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<String>(
      valueListenable: UserState().themeMode,
      builder: (context, themeMode, _) {
        final bool isNight = UserState().isNight;
        final String bgPath = isNight
            ? 'assets/images/indoor3.png'
            : 'assets/images/indoor.png';

        const double bgScale = 1.0;
        const double leftBuffer = 175.0;
        const double rightBuffer = 325.0;

        final Color bgColor = isNight
            ? const Color(0xFF13131F)
            : const Color(0xFFD2B48C);

        return Scaffold(
          backgroundColor: bgColor,
          body: Stack(
            children: [
              // 1. 全景背景层
              Positioned.fill(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final double h = constraints.maxHeight * bgScale;
                    final double fullWidth = h * _aspectRatio;

                    // 计算静态位置参数
                    final deskRelX = fullWidth * 0.456 - leftBuffer;
                    final deskY = h * 0.546;
                    final bedRelX = fullWidth * 0.56 - leftBuffer;
                    final bedY = h * 0.58;

                    return SingleChildScrollView(
                      controller: _scrollController,
                      scrollDirection: Axis.horizontal,
                      physics: const BouncingScrollPhysics(),
                      child: Stack(
                        clipBehavior: Clip.none,
                        children: [
                          // 背景图：唯一需要高频重绘的部分
                          Positioned(
                            left: -leftBuffer,
                            top: 0,
                            bottom: 0,
                            child: ListenableBuilder(
                              listenable: _scrollController,
                              builder: (context, _) {
                                double currentScale = 1.05;
                                if (_scrollController.hasClients) {
                                  final double maxScroll = _scrollController
                                      .position.maxScrollExtent;
                                  final double currentScroll = _scrollController
                                      .offset
                                      .clamp(0, maxScroll);
                                  final double scrollRatio = maxScroll > 0
                                      ? currentScroll / maxScroll
                                      : 0.5;

                                  if (scrollRatio < 0.2) {
                                    currentScale =
                                        1.05 + (0.13 * (scrollRatio / 0.2));
                                  } else if (scrollRatio < 0.5) {
                                    currentScale = 1.18 +
                                        (0.07 * ((scrollRatio - 0.2) / 0.3));
                                  } else if (scrollRatio < 0.8) {
                                    currentScale = 1.25 -
                                        (0.07 * ((scrollRatio - 0.5) / 0.3));
                                  } else {
                                    currentScale = 1.18 -
                                        (0.13 * ((scrollRatio - 0.8) / 0.2));
                                  }
                                }
                                return Transform.scale(
                                  scale: currentScale,
                                  alignment: Alignment.center,
                                  child: Image.asset(
                                    bgPath,
                                    height: h,
                                    fit: BoxFit.fitHeight,
                                  ),
                                );
                              },
                            ),
                          ),

                          // --- 小软跳出的动画内容 ---
                          if (_isJumpStarted)
                            Positioned.fill(
                              child: AnimatedBuilder(
                                animation: _jumpAnimation,
                                builder: (context, child) {
                                  final rawT = _jumpAnimation.value;
                                  final isWide = constraints.maxWidth > 600;
                                  final menuBottomOffset = isWide ? 60.0 : 40.0;

                                  // 关键：起点坐标需要监听滚动，但这部分代码在 AnimatedBuilder 中本就会随 Ticker 重绘
                                  final startP = Offset(
                                    _scrollController.offset +
                                        constraints.maxWidth / 2,
                                    h - menuBottomOffset - 24.0,
                                  );
                                  final bedP = Offset(bedRelX, bedY);
                                  final deskP = Offset(deskRelX, deskY);

                                  late double curX,
                                      curY,
                                      shadowY,
                                      slimeScale;
                                  double jumpArc = 0;

                                  if (rawT < 0.25) {
                                    final t = Curves.easeInOut
                                        .transform(rawT / 0.25);
                                    curX = startP.dx + (bedP.dx - startP.dx) * t;
                                    shadowY =
                                        startP.dy + (bedP.dy - startP.dy) * t;
                                    jumpArc = sin(t * pi) * 140;
                                    curY = shadowY - jumpArc;
                                    slimeScale = 0.8 + (0.15 * t);
                                  } else if (rawT < 0.75) {
                                    curX = bedP.dx;
                                    curY = bedP.dy;
                                    shadowY = bedP.dy;
                                    jumpArc = 0;
                                    slimeScale = 0.95;
                                  } else {
                                    final t = Curves.easeInOut
                                        .transform((rawT - 0.75) / 0.25);
                                    curX = bedP.dx + (deskP.dx - bedP.dx) * t;
                                    shadowY = bedP.dy + (deskP.dy - bedP.dy) * t;
                                    jumpArc = sin(t * pi) * 80;
                                    curY = shadowY - jumpArc;
                                    slimeScale = 0.95 + (0.05 * t);
                                  }

                                  return Stack(
                                    clipBehavior: Clip.none,
                                    children: [
                                      Positioned(
                                        left: curX - 16,
                                        top: shadowY - 4,
                                        child: Opacity(
                                          opacity: (0.15 +
                                                  0.15 * (jumpArc / 140))
                                              .clamp(0, 0.3),
                                          child: Container(
                                            width: 32,
                                            height: 8,
                                            decoration: const BoxDecoration(
                                              color: Colors.black,
                                              borderRadius: BorderRadius.all(
                                                Radius.elliptical(16, 4),
                                              ),
                                              boxShadow: [
                                                BoxShadow(
                                                  color: Colors.black,
                                                  blurRadius: 8,
                                                  spreadRadius: 2,
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ),
                                      Positioned(
                                        left: curX - 21,
                                        top: curY - 42,
                                        child: Transform.scale(
                                          scale: slimeScale,
                                          child: const SpriteAnimation(
                                            assetPath:
                                                'assets/images/emoji/weixiao.png',
                                            frameCount: 9,
                                            duration: Duration(
                                              milliseconds: 800,
                                            ),
                                            size: 42.0,
                                            isPlaying: true,
                                          ),
                                        ),
                                      ),
                                    ],
                                  );
                                },
                              ),
                            ),

                          // 书籍提示与对话
                          if (_showBookHint)
                            Positioned(
                              left: deskRelX - 2,
                              top: deskY - 110,
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(14),
                                    child: BackdropFilter(
                                      filter: ImageFilter.blur(
                                        sigmaX: 10,
                                        sigmaY: 10,
                                      ),
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 16,
                                          vertical: 6,
                                        ),
                                        decoration: BoxDecoration(
                                          color: Colors.white.withOpacity(0.4),
                                          borderRadius:
                                              BorderRadius.circular(14),
                                          border: Border.all(
                                            color:
                                                Colors.white.withOpacity(0.2),
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
                                      .animate(
                                        onPlay: (controller) =>
                                            controller.repeat(reverse: true),
                                      )
                                      .moveY(
                                        begin: 0,
                                        end: -4,
                                        duration: 1.5.seconds,
                                        curve: Curves.easeInOut,
                                      ),
                                  const SizedBox(height: 4),
                                  _BookGlowHint(
                                    onTap: () {
                                      if (mounted) {
                                        setState(() {
                                          _showDeskDialogue = false;
                                          _showBookHint = false;
                                          _isJumpStarted = false;
                                        });
                                        UserState()
                                            .isSlimeInBottomMenu
                                            .value = true;
                                        _openHistoryTimeline().then((_) {
                                          if (mounted) {
                                            setState(() => _showBookHint = true);
                                          }
                                        });
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
                            ),
                          if (_showDeskDialogue)
                            Positioned(
                              left: deskRelX - 108,
                              top: deskY - 130,
                              child: SpriteDialogue(
                                text: "点点旁边的书，看看我为你准备了什么",
                                useTypewriter: true,
                                onNext: () {
                                  setState(() => _showDeskDialogue = false);
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

                          // 占位撑开滚动范围
                          SizedBox(
                            width: fullWidth - leftBuffer - rightBuffer,
                            height: h,
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _openHistoryTimeline() async {
    await showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'HistoryTimeline',
      barrierColor: Colors.black.withOpacity(0.4),
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

/// 书籍上的呼吸光晕组件
class _BookGlowHint extends StatefulWidget {
  final VoidCallback onTap;
  const _BookGlowHint({required this.onTap});

  @override
  State<_BookGlowHint> createState() => _BookGlowHintState();
}

class _BookGlowHintState extends State<_BookGlowHint>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _opacityAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat(reverse: true);

    _scaleAnimation = Tween<double>(
      begin: 0.8,
      end: 1.25,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));

    _opacityAnimation = Tween<double>(
      begin: 0.2,
      end: 0.7,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        // 通过扩充透明容器的尺寸，在不改变视觉的情况下增加点击判定范围
        width: 80,
        height: 80,
        alignment: Alignment.center,
        color: Colors.transparent,
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            return Stack(
              alignment: Alignment.center,
              children: [
                // 扩散的光晕
                Transform.scale(
                  scale: _scaleAnimation.value,
                  child: Container(
                    width: 20,
                    height: 20,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFFFFECB3).withOpacity(
                            _opacityAnimation.value,
                          ),
                          blurRadius: 10,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                  ),
                ),
                // 中心的引导圆点
                Container(
                  width: 16,
                  height: 16,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.white.withOpacity(0.5),
                        blurRadius: 4,
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

/// 时间轴历史记录全屏覆盖层
class DiaryHistoryOverlay extends StatefulWidget {
  final VoidCallback onClose;
  const DiaryHistoryOverlay({super.key, required this.onClose});

  @override
  State<DiaryHistoryOverlay> createState() => _DiaryHistoryOverlayState();
}

class _DiaryHistoryOverlayState extends State<DiaryHistoryOverlay> {
  DateTime? _selectedDate; // 改为可选，null 表示显示全部

  @override
  void initState() {
    super.initState();
    // 默认显示全部记录，或者选中今天
    _selectedDate = null; 
  }

  @override
  Widget build(BuildContext context) {
    final bool isNight = UserState().isNight;
    
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          // 1. 拟物化纸张底层 (动态昼夜色值)
          Positioned.fill(
            child: Container(
              color: isNight ? const Color(0xFF1A1C1E) : const Color(0xFFFDF9F0),
            ),
          ),
          // 2. 纸张纹理绘制 (横格线与书脊阴影)
          Positioned.fill(
            child: CustomPaint(
              painter: _PaperBackgroundPainter(isNight: isNight),
            ),
          ),
          // 3. 增强通透感的毛玻璃
          Positioned.fill(
            child: GestureDetector(
              onTap: widget.onClose,
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
                child: Container(
                  color: isNight 
                    ? Colors.black.withOpacity(0.2) 
                    : Colors.white.withOpacity(0.3),
                ),
              ),
            ),
          ),
          // 内容区域
          SafeArea(
            child: Column(
              children: [
                // 顶部周历选择器 (参考最新图)
                _HorizontalWeekCalendar(
                  selectedDate: _selectedDate,
                  isNight: isNight,
                  onDateSelected: (date) {
                    setState(() {
                      _selectedDate = date;
                    });
                  },
                ),
                
                // 历史列表
                Expanded(
                  child: ValueListenableBuilder<List<DiaryEntry>>(
                    valueListenable: UserState().savedDiaries,
                    builder: (context, allDiaries, _) {
                      // 过滤逻辑：如果没选日期，显示全部；选中了则按天过滤
                      final diaries = _selectedDate == null 
                        ? allDiaries 
                        : allDiaries.where((e) => 
                            e.dateTime.year == _selectedDate!.year &&
                            e.dateTime.month == _selectedDate!.month &&
                            e.dateTime.day == _selectedDate!.day
                          ).toList();

                      return Column(
                        children: [
                          // 今日记录摘要
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                            child: Row(
                              children: [
                                Text(
                                  _selectedDate == null ? "历史共有 " : "今日有 ",
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: isNight ? Colors.white54 : Colors.black.withOpacity(0.4),
                                    fontFamily: 'LXGWWenKai',
                                  ),
                                ),
                                Text(
                                  "${diaries.length}",
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: isNight ? Colors.white : Colors.black,
                                    fontFamily: 'LXGWWenKai',
                                  ),
                                ),
                                Text(
                                  " 条记录",
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: isNight ? Colors.white54 : Colors.black.withOpacity(0.4),
                                    fontFamily: 'LXGWWenKai',
                                  ),
                                ),
                              ],
                            ),
                          ),
                          
                          Expanded(
                            child: diaries.isEmpty 
                              ? Center(
                                  child: Text(
                                    "这一天还没有记录呢...",
                                    style: TextStyle(
                                      color: isNight ? Colors.white30 : Colors.black.withOpacity(0.3),
                                      fontFamily: 'LXGWWenKai',
                                    ),
                                  ),
                                )
                              : ListView.builder(
                                  padding: const EdgeInsets.symmetric(horizontal: 16),
                                  itemCount: diaries.length,
                                  itemBuilder: (context, index) {
                                    return _DiaryHistoryCard(
                                      entry: diaries[index],
                                      index: index,
                                      isFilteredMode: true,
                                      isNight: isNight,
                                    );
                                  },
                                ),
                          ),
                        ],
                      );
                    },
                  ),
                ),
                // 底部悬浮工具栏
                Padding(
                  padding: const EdgeInsets.only(bottom: 30, top: 10),
                  child: Container(
                    height: 54,
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    decoration: BoxDecoration(
                      color: isNight ? const Color(0xFF2C2E30) : Colors.white,
                      borderRadius: BorderRadius.circular(27),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(isNight ? 0.45 : 0.12),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _buildToolBtn(Icons.search_rounded, () {}, isNight: isNight),
                        const SizedBox(width: 40),
                        GestureDetector(
                          onTap: widget.onClose,
                          child: Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Icon(
                              Icons.close_rounded,
                              size: 28,
                              color: isNight ? Colors.white70 : Colors.black87,
                            ),
                          ),
                        ),
                        const SizedBox(width: 40),
                        _buildToolBtn(Icons.calendar_month_rounded, () {}, isNight: isNight),
                      ],
                    ),
                  ),
                ).animate().fadeIn(delay: 200.ms).scale(begin: const Offset(0.9, 0.9)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildToolBtn(IconData icon, VoidCallback onTap, {bool isNight = false}) {
    return GestureDetector(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Icon(
          icon,
          size: 24,
          color: isNight ? Colors.white54 : Colors.black.withOpacity(0.4),
        ),
      ),
    );
  }
}

/// 拟物化纸张画家：绘制横格线与书脊阴影
class _PaperBackgroundPainter extends CustomPainter {
  final bool isNight;
  _PaperBackgroundPainter({this.isNight = false});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = isNight 
        ? Colors.white.withOpacity(0.05) 
        : Colors.black.withOpacity(0.04)
      ..strokeWidth = 1.0;

    // 绘制水平横线 (模拟格线本)
    const double lineSpacing = 28.0;
    for (double y = 100; y < size.height; y += lineSpacing) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }

    // 绘制中心书脊阴影 (拟物感核心)
    final spinePaint = Paint()
      ..shader = LinearGradient(
        colors: [
          isNight ? Colors.black.withOpacity(0.4) : Colors.black.withOpacity(0.08),
          isNight ? Colors.black.withOpacity(0.1) : Colors.black.withOpacity(0.02),
          Colors.transparent,
          isNight ? Colors.black.withOpacity(0.1) : Colors.black.withOpacity(0.02),
          isNight ? Colors.black.withOpacity(0.4) : Colors.black.withOpacity(0.08),
        ],
        stops: const [0.0, 0.45, 0.5, 0.55, 1.0],
      ).createShader(Rect.fromLTWH(70, 0, 50, size.height));

    // 书脊区域 (大致位于时间轴正下方)
    canvas.drawRect(Rect.fromLTWH(75, 0, 40, size.height), spinePaint);

    // 绘制左侧红色垂直参考线 (怀旧感)
    final redLinePaint = Paint()
      ..color = isNight 
        ? const Color(0xFF4A2525).withOpacity(0.3) 
        : Colors.red.withOpacity(0.08)
      ..strokeWidth = 1.5;
    canvas.drawLine(const Offset(68, 0), Offset(68, size.height), redLinePaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

/// 水平周历组件 (参考最新图)
class _HorizontalWeekCalendar extends StatelessWidget {
  final DateTime? selectedDate;
  final Function(DateTime?) onDateSelected;
  final bool isNight;

  const _HorizontalWeekCalendar({
    required this.selectedDate,
    required this.onDateSelected,
    required this.isNight,
  });

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    // 动态生成本月 1 号到今天的日期列表
    final firstDayOfMonth = DateTime(now.year, now.month, 1);
    final daysInMonthSoFar = now.difference(firstDayOfMonth).inDays + 1;
    final weekDates = List.generate(
      daysInMonthSoFar, 
      (i) => firstDayOfMonth.add(Duration(days: i))
    );
    final weekDays = ["日", "一", "二", "三", "四", "五", "六"];

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Row(
        children: [
          // 1. 固定在左侧的“全部”按钮
          Padding(
            padding: const EdgeInsets.only(left: 20, right: 12),
            child: GestureDetector(
              onTap: () => onDateSelected(null),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    "全部",
                    style: TextStyle(
                      fontSize: 12,
                      color: isNight ? Colors.white30 : Colors.black.withOpacity(0.25),
                      fontFamily: 'LXGWWenKai',
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: selectedDate == null 
                          ? const Color(0xFFD4A373) 
                          : Colors.transparent,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: selectedDate == null 
                            ? Colors.transparent 
                            : (isNight ? Colors.white10 : Colors.black.withOpacity(0.05)),
                      ),
                    ),
                    child: Center(
                      child: Icon(
                        Icons.all_inclusive,
                        size: 20,
                        color: selectedDate == null ? Colors.white : (isNight ? Colors.white30 : Colors.black38),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          // 垂直分割线
          Container(
            width: 1,
            height: 30,
            color: isNight ? Colors.white10 : Colors.black.withOpacity(0.05),
          ),

          // 2. 可滚动的日期列表
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 12),
              // 自动滚动到最右侧（今天）
              controller: ScrollController(initialScrollOffset: 1000.0), 
              child: Row(
                children: weekDates.map((date) {
                  final isToday = date.day == now.day && date.month == now.month && date.year == now.year;
                  final isSelected = selectedDate != null && 
                                    date.day == selectedDate!.day && 
                                    date.month == selectedDate!.month && 
                                    date.year == selectedDate!.year;
                  final dayName = weekDays[date.weekday % 7];

                  return GestureDetector(
                    onTap: () => onDateSelected(date),
                    child: Container(
                      width: 45, // 固定宽度确保对齐
                      margin: const EdgeInsets.symmetric(horizontal: 2),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // 星期几提示
                          Text(
                            dayName,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: isToday ? FontWeight.bold : FontWeight.normal,
                              color: isToday 
                                ? const Color(0xFFD4A373).withOpacity(0.8)
                                : (isNight ? Colors.white30 : Colors.black.withOpacity(0.25)),
                              fontFamily: 'LXGWWenKai',
                            ),
                          ),
                          const SizedBox(height: 8),
                          // 日期圆圈
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 300),
                            width: 38,
                            height: 38,
                            decoration: BoxDecoration(
                              color: isSelected 
                                  ? const Color(0xFFD4A373) 
                                  : Colors.transparent,
                              shape: BoxShape.circle,
                            ),
                            child: Center(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    isToday ? "今" : date.day.toString(),
                                    style: TextStyle(
                                      fontSize: 15,
                                      fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                                      color: isSelected ? Colors.white : (isNight ? Colors.white70 : Colors.black87),
                                      fontFamily: 'LXGWWenKai',
                                    ),
                                  ),
                                  if (isToday && !isSelected)
                                    Container(
                                      margin: const EdgeInsets.only(top: 2),
                                      width: 3,
                                      height: 3,
                                      decoration: const BoxDecoration(
                                        color: Color(0xFFD4A373),
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// 每一份日记卡片
class _DiaryHistoryCard extends StatelessWidget {
  final DiaryEntry entry;
  final int index;
  final bool isFilteredMode;
  final bool isNight;

  const _DiaryHistoryCard({
    required this.entry,
    required this.index,
    this.isFilteredMode = false,
    this.isNight = false,
  });

  @override
  Widget build(BuildContext context) {
    final timeStr =
        "${entry.dateTime.hour.toString().padLeft(2, '0')}:${entry.dateTime.minute.toString().padLeft(2, '0')}";

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. 左侧：时刻 (字号加大)
            Container(
              width: 60,
              padding: const EdgeInsets.only(top: 14),
              alignment: Alignment.topRight,
              child: Text(
                timeStr,
                style: TextStyle(
                  fontSize: 15, // 增大时间文字
                  color: isNight ? Colors.white30 : Colors.black.withOpacity(0.35),
                  fontWeight: FontWeight.w600,
                  fontFamily: 'LXGWWenKai',
                ),
              ),
            ),
            const SizedBox(width: 16),
            // 2. 中间：书脊装订轴 (改为拟物化感)
            SizedBox(
              width: 24,
              child: Column(
                children: [
                  const SizedBox(height: 20),
                  // 实心装订点 (模拟缝线或小扣子)
                  Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      color: isNight ? const Color(0xFF2C2E30) : const Color(0xFFC4B69E), // 古典铜金色调
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(isNight ? 0.3 : 0.1),
                          blurRadius: 2,
                          offset: const Offset(1, 1),
                        ),
                      ],
                      border: isNight ? Border.all(color: Colors.white10, width: 0.5) : null,
                    ),
                  ),
                  Expanded(
                    child: Container(
                      width: 4,
                      margin: const EdgeInsets.symmetric(vertical: 4),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            isNight ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.05),
                            isNight ? Colors.white.withOpacity(0.01) : Colors.black.withOpacity(0.01),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            // 右侧内容卡片
            Expanded(
              child: Container(
                margin: const EdgeInsets.only(bottom: 24, right: 8),
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: isNight ? const Color(0xFF232527) : Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: isNight 
                      ? Colors.white.withOpacity(0.05) 
                      : Colors.black.withOpacity(0.03),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(isNight ? 0.45 : 0.12), // 更深更实的阴影
                      blurRadius: 10,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        _buildMoodBadge(entry.moodIndex, entry.intensity, isNight: isNight),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      entry.content,
                      style: TextStyle(
                        fontSize: 15.5,
                        color: isNight ? Colors.white70 : Colors.black.withOpacity(0.75),
                        height: 1.6,
                        fontFamily: 'LXGWWenKai',
                      ),
                    ),
                    if (entry.blocks.any((b) => b['type'] == 'image')) ...[
                      const SizedBox(height: 16),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: entry.blocks
                            .where((b) => b['type'] == 'image')
                            .take(3)
                            .map((b) => DiaryUtils.buildImage(
                                  b['path'],
                                  width: 110,
                                  height: 110,
                                  fit: BoxFit.cover,
                                  borderRadius: BorderRadius.circular(14),
                                ))
                            .toList(),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    ).animate().fadeIn(delay: (index * 60).ms, duration: 350.ms).moveX(begin: 12, end: 0);
  }

  Widget _buildMoodBadge(int moodIndex, double intensity, {bool isNight = false}) {
    final moodIdx = moodIndex.clamp(0, kMoods.length - 1);
    final mood = kMoods[moodIdx];
    final Color badgeColor = mood.glowColor ?? const Color(0xFFC4B69E);
    final String fullMoodDescription = DiaryUtils.getPersonifiedMoodDescription(mood.label, intensity);
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: badgeColor.withOpacity(isNight ? 0.15 : 0.1),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Image.asset(mood.iconPath ?? 'assets/images/icons/sun.png', width: 14, height: 14),
          const SizedBox(width: 4),
          Text(
            fullMoodDescription,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: badgeColor.withOpacity(isNight ? 0.8 : 1.0),
              fontFamily: 'LXGWWenKai',
            ),
          ),
        ],
      ),
    );
  }
}
