import 'dart:io';
import 'dart:ui';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:island_diary/core/state/user_state.dart';
import 'package:island_diary/core/models/mascot_decoration.dart';
import 'package:island_diary/features/record/domain/models/diary_entry.dart';
import 'package:island_diary/shared/utils/toast_utils.dart';
import 'package:island_diary/shared/widgets/mood_picker/config/mood_config.dart';
import 'package:island_diary/shared/widgets/mood_picker/models/mood_item.dart';
import 'package:island_diary/shared/widgets/prop_obtained/prop_obtained_popup.dart';
import 'package:island_diary/features/record/presentation/pages/diary_detail_page.dart';

import 'package:island_diary/shared/widgets/diary_entry/utils/diary_utils.dart';

/// 随机回忆 · 轮播卡片弹出层
/// 参考：豆瓣 App 卡片轮播 / Apple TV Up Next 3D carousel
class RandomMemoryOverlay extends StatefulWidget {
  final bool isNight;

  const RandomMemoryOverlay({super.key, required this.isNight});

  static void show(BuildContext context, {required bool isNight}) {
    final diaries = UserState().savedDiaries.value;
    if (diaries.isEmpty) {
      showTopToast(
        context,
        '还没有日记哦，去记录第一篇吧 🌱',
        icon: Icons.info_outline_rounded,
      );
      return;
    }

    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'RandomMemory',
      barrierColor: Colors.transparent,
      transitionDuration: Duration.zero,
      pageBuilder: (ctx, a1, a2) =>
          RandomMemoryOverlay(isNight: isNight),
    );
  }

  @override
  State<RandomMemoryOverlay> createState() => _RandomMemoryOverlayState();
}

class _RandomMemoryOverlayState extends State<RandomMemoryOverlay>
    with TickerProviderStateMixin {
  late List<DiaryEntry> _entries;
  late PageController _pageCtrl;
  late AnimationController _enterCtrl;
  late Animation<double> _enterBlur;
  late Animation<double> _enterFade;
  late Animation<double> _enterScale;

  double _currentPage = 0;
  int _lastTriggeredPage = 0;
  bool _hasTriggeredGift = false;
  int _consecutiveFlips = 0;

  AnimationController? _confettiCtrl;
  List<_ConfettiPiece> _confettiPieces = [];
  bool _showConfetti = false;

  // 就地展开详情动画相关状态
  late AnimationController _expandCtrl;
  late Animation<double> _expandAni;
  Rect? _expandedStartRect;
  DiaryEntry? _expandedEntry;
  bool _isExpanding = false;
  final Map<int, GlobalKey> _cardKeys = {};
  final Map<int, _CardRenderConfig> _cardConfigs = {};

  @override
  void initState() {
    super.initState();

    // 随机打乱日记顺序，限制最多随机回忆 15 条
    final all = List<DiaryEntry>.from(UserState().savedDiaries.value);
    all.shuffle();
    _entries = all.take(15).toList();

    // 预先为这 15 条日记数据解析并缓存渲染所需的静态配置，消除滑屏高频重复计算带来的性能开销
    for (int i = 0; i < _entries.length; i++) {
      final entry = _entries[i];
      final mood = (entry.moodIndex >= 0 && entry.moodIndex < kMoods.length)
          ? kMoods[entry.moodIndex]
          : null;
      final moodColor = mood?.glowColor ?? const Color(0xFFD4A373);

      String? imageUrl;
      for (final block in entry.blocks) {
        if (block['type'] == 'image' && block['path'] != null) {
          imageUrl = block['path'].toString();
          break;
        }
      }

      final Widget bgWidget;
      if (imageUrl != null && imageUrl.isNotEmpty) {
        bgWidget = DiaryUtils.buildImage(imageUrl, fit: BoxFit.cover);
      } else {
        String bgAsset = DiaryUtils.getPaperBackgroundPath(entry.paperStyle, widget.isNight);
        if (bgAsset.isEmpty) {
          bgAsset = widget.isNight
              ? 'assets/images/note/note_night_bg1.png'
              : 'assets/images/note/note_bg1.png';
        }
        bgWidget = Image.asset(bgAsset, fit: BoxFit.cover);
      }

      final dt = entry.dateTime;
      final months = ['一月','二月','三月','四月','五月','六月',
                      '七月','八月','九月','十月','十一月','十二月'];
      final dateStr = '${dt.year}  ${months[dt.month - 1]}  ${dt.day}日';
      final rawContent = entry.content.trim();
      final preview = rawContent.isNotEmpty ? rawContent : '（这天只有画面，没有文字）';

      _cardConfigs[i] = _CardRenderConfig(
        entry: entry,
        mood: mood,
        moodColor: moodColor,
        imageUrl: imageUrl,
        bgWidget: bgWidget,
        dateStr: dateStr,
        preview: preview,
      );
    }

    // 从中间开始，让两侧都有卡片
    final startIndex = (_entries.length > 2) ? 1 : 0;
    _currentPage = startIndex.toDouble();
    _lastTriggeredPage = startIndex;
    _pageCtrl = PageController(viewportFraction: 0.78, initialPage: startIndex)
      ..addListener(() {
        final double page = _pageCtrl.page ?? _currentPage;
        setState(() => _currentPage = page);

        final int targetInt = page.round();
        if (targetInt != _lastTriggeredPage) {
          _lastTriggeredPage = targetInt;
          _consecutiveFlips++;
          _checkGiftEgg();
        }
      });

    // 入场动画
    _enterCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 480));
    _enterBlur = Tween<double>(begin: 0, end: 12).animate(
      CurvedAnimation(parent: _enterCtrl,
          curve: const Interval(0, 0.6, curve: Curves.easeOut)),
    );
    _enterFade = CurvedAnimation(parent: _enterCtrl,
        curve: const Interval(0, 0.5, curve: Curves.easeOut));
    _enterScale = Tween<double>(begin: 0.90, end: 1.0).animate(
      CurvedAnimation(parent: _enterCtrl, curve: Curves.easeOutBack),
    );
    _enterCtrl.forward();

    _expandCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 450),
    );
    _expandAni = CurvedAnimation(
      parent: _expandCtrl,
      curve: Curves.fastOutSlowIn,
    );
  }

  void _checkGiftEgg() {
    if (_hasTriggeredGift) return;

    final ownedIds = UserState().ownedDecorationIds.value;
    final lockedDecorations = MascotDecoration.allDecorations
        .where((d) => !ownedIds.contains(d.id))
        .toList();

    if (lockedDecorations.isEmpty) return;

    // 每次翻页有 20% 概率触发送礼物彩蛋，翻页达 4 次时强制 100% 触发兜底
    if (math.Random().nextDouble() < 0.20 || _consecutiveFlips >= 4) {
      _hasTriggeredGift = true;
      final randomDeco = lockedDecorations[math.Random().nextInt(lockedDecorations.length)];

      // 1. 初始化彩纸
      final screenWidth = MediaQuery.of(context).size.width;
      _confettiPieces = List.generate(40, (_) => _ConfettiPiece(screenWidth));

      // 2. 初始化并播放彩带下落动画
      _confettiCtrl = AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 8000),
      );

      setState(() {
        _showConfetti = true;
      });
      _confettiCtrl!.forward();

      // 3. 延迟 4000 毫秒展示（让彩纸漫天飘落4秒，尽情展示喜庆氛围），再弹出底部的弹窗和顶部轻提示
      Future.delayed(const Duration(milliseconds: 4000), () async {
        if (!mounted) return;
        await UserState().unlockDecoration(randomDeco.id);
        if (mounted) {
          // 获取当前形象类型并派发个性化彩蛋话术
          final mascotType = UserState().selectedMascotType.value;
          String toastMsg = '小岛守护者送了你一份神秘礼物 🎁';
          IconData toastIcon = Icons.card_giftcard_rounded;

          if (mascotType.contains('marshmallow.png')) {
            toastMsg = '云织悄悄把一份闪闪发光的礼物塞进了你的口袋 🧸';
            toastIcon = Icons.auto_awesome_rounded;
          } else if (mascotType.contains('marshmallow2.png')) {
            toastMsg = '笃守叼着一个新礼物朝你兴奋地摇尾巴！🐶';
            toastIcon = Icons.pets_rounded;
          } else if (mascotType.contains('marshmallow3.png')) {
            toastMsg = '灵犀发现了藏在林间的宝物，顺手丢给了你 🔮';
            toastIcon = Icons.visibility_rounded;
          } else if (mascotType.contains('marshmallow4.png')) {
            toastMsg = '霜见静静把一份月光编织的赠礼递到你手中 ❄️';
            toastIcon = Icons.brightness_2_rounded;
          }

          final toastEntry = showTopToast(
            context,
            toastMsg,
            icon: toastIcon,
            iconColor: const Color(0xFFFBBF24),
            duration: const Duration(days: 365), // 设定超长持续时间，不自动关闭
          );

          showPropObtainedPopup(context, randomDeco).then((_) {
            // 当用户手动关闭底部弹窗时，移除顶部的轻提示
            try {
              toastEntry.remove();
            } catch (_) {}
            // 弹窗关闭后，清除彩纸图层
            if (mounted) {
              setState(() {
                _showConfetti = false;
              });
            }
          });
        }
      });
    }
  }

  Future<void> _dismiss() async {
    // 如果处于展开详情态，先收回详情页，而不关闭整个 overlay
    if (_isExpanding) {
      _collapseCard();
      return;
    }
    await _enterCtrl.reverse();
    if (mounted) Navigator.of(context).pop();
  }

  void _expandCard(int index, DiaryEntry entry) {
    final key = _cardKeys[index];
    if (key == null || key.currentContext == null) return;

    final RenderBox renderBox = key.currentContext!.findRenderObject() as RenderBox;
    final size = renderBox.size;
    final position = renderBox.localToGlobal(Offset.zero);

    setState(() {
      _expandedStartRect = Rect.fromLTWH(position.dx, position.dy, size.width, size.height);
      _expandedEntry = entry;
      _isExpanding = true;
    });

    _expandCtrl.forward();
  }

  void _collapseCard() {
    _expandCtrl.reverse().then((_) {
      if (mounted) {
        setState(() {
          _isExpanding = false;
          _expandedEntry = null;
          _expandedStartRect = null;
        });
      }
    });
  }

  @override
  void dispose() {
    _pageCtrl.dispose();
    _enterCtrl.dispose();
    _expandCtrl.dispose();
    _confettiCtrl?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final cardH = size.height * 0.62;

    return Material(
      color: Colors.transparent,
      child: GestureDetector(
        onTap: _dismiss,
        child: AnimatedBuilder(
          animation: _enterCtrl,
          builder: (context, child) {
            return Stack(
              children: [
                // ── 磨砂遮罩
                Positioned.fill(
                  child: Opacity(
                    opacity: _enterFade.value,
                    child: ClipRect(
                      child: BackdropFilter(
                        filter: ImageFilter.blur(
                          sigmaX: _enterBlur.value,
                          sigmaY: _enterBlur.value,
                        ),
                        child: Container(
                          color: Colors.black.withValues(
                              alpha: widget.isNight ? 0.62 : 0.40),
                        ),
                      ),
                    ),
                  ),
                ),

                // ── 顶部标题
                Positioned(
                  top: size.height * 0.11,
                  left: 0,
                  right: 0,
                  child: Opacity(
                    opacity: _enterFade.value,
                    child: Column(
                      children: [
                        Text(
                          '时光回溯',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: Colors.white.withValues(alpha: 0.95),
                            fontFamily: 'LXGWWenKai',
                            letterSpacing: 3,
                            shadows: const [
                              Shadow(blurRadius: 12, color: Colors.black38)
                            ],
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          '从 ${_entries.length} 条回忆中，为你随机翻开一页',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.white.withValues(alpha: 0.55),
                            fontFamily: 'LXGWWenKai',
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // ── 轮播卡片区域
                Positioned(
                  top: 0,
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: Opacity(
                    opacity: _enterFade.value,
                    child: Transform.scale(
                      scale: _enterScale.value,
                      child: GestureDetector(
                        onTap: () {}, // 拦截，防止关闭
                        child: Center(
                          child: SizedBox(
                            height: cardH,
                            child: PageView.builder(
                              controller: _pageCtrl,
                              itemCount: _entries.length,
                              clipBehavior: Clip.none,
                              physics: _showConfetti
                                  ? const NeverScrollableScrollPhysics()
                                  : const BouncingScrollPhysics(),
                              itemBuilder: (context, index) {
                                return _buildCard(index, cardH);
                              },
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),

                // ── 底部提示
                Positioned(
                  bottom: size.height * 0.10,
                  left: 0,
                  right: 0,
                  child: Opacity(
                    opacity: _enterFade.value,
                    child: Column(
                      children: [
                        // 页码点
                        if (_entries.length > 1)
                          Builder(
                            builder: (context) {
                              final int activeIndex = _currentPage.round();
                              final int total = _entries.length;
                              final int showCount = total > 8 ? 8 : total;
                              int startIndex = 0;
                              if (total > 8) {
                                startIndex = activeIndex - 4;
                                if (startIndex < 0) startIndex = 0;
                                if (startIndex + 8 > total) {
                                  startIndex = total - 8;
                                }
                              }
                              return Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: List.generate(
                                  showCount,
                                  (i) {
                                    final int realIndex = startIndex + i;
                                    final active = realIndex == activeIndex;
                                    return AnimatedContainer(
                                      duration: 200.ms,
                                      margin: const EdgeInsets.symmetric(horizontal: 3),
                                      width: active ? 18 : 6,
                                      height: 6,
                                      decoration: BoxDecoration(
                                        color: active
                                            ? Colors.white.withValues(alpha: 0.9)
                                            : Colors.white.withValues(alpha: 0.30),
                                        borderRadius: BorderRadius.circular(3),
                                      ),
                                    );
                                  },
                                ),
                              );
                            },
                          ),
                      ],
                    ),
                  ),
                ),
                // ── 卡片就地放大展开为全屏详情图层
                if (_expandedEntry != null && _expandedStartRect != null)
                  Positioned.fill(
                    child: AnimatedBuilder(
                      animation: _expandAni,
                      builder: (context, child) {
                        final double val = _expandAni.value;
                        final double screenWidth = size.width;
                        final double screenHeight = size.height;

                        // 使用 Rect.lerp 计算当前卡片在动画过程中的绝对位置与大小
                        final currentRect = Rect.lerp(
                          _expandedStartRect!,
                          Rect.fromLTWH(0, 0, screenWidth, screenHeight),
                          val,
                        )!;

                        // 圆角插值：从 30.0 渐变到 0.0
                        final double currentRadius = lerpDouble(30.0, 0.0, val)!;

                        // 控制预览卡片与实际日记详情的淡入淡出过渡
                        final double cardOpacity = (1.0 - (val / 0.35)).clamp(0.0, 1.0);
                        final double detailOpacity = ((val - 0.25) / 0.75).clamp(0.0, 1.0);

                        final entry = _expandedEntry!;
                        final config = _cardConfigs.values.firstWhere(
                          (c) => c.entry.id == entry.id,
                          orElse: () => _CardRenderConfig(
                            entry: entry,
                            mood: null,
                            moodColor: const Color(0xFFD4A373),
                            imageUrl: null,
                            bgWidget: const SizedBox.shrink(),
                            dateStr: '',
                            preview: '',
                          ),
                        );

                        return Stack(
                          children: [
                            Positioned(
                              left: currentRect.left,
                              top: currentRect.top,
                              width: currentRect.width,
                              height: currentRect.height,
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(currentRadius),
                                child: Stack(
                                  fit: StackFit.expand,
                                  children: [
                                    // 1. 卡片预览层
                                    if (cardOpacity > 0)
                                      Opacity(
                                        opacity: cardOpacity,
                                        child: Center(
                                          child: OverflowBox(
                                            minWidth: _expandedStartRect!.width,
                                            maxWidth: _expandedStartRect!.width,
                                            minHeight: _expandedStartRect!.height,
                                            maxHeight: _expandedStartRect!.height,
                                            child: _buildCardStatic(config, cardH),
                                          ),
                                        ),
                                      ),

                                    // 2. 详情内容层
                                    if (detailOpacity > 0)
                                      Opacity(
                                        opacity: detailOpacity,
                                        child: DiaryDetailPage(
                                          entry: entry,
                                          isNight: widget.isNight,
                                          showFloatingActions: true,
                                          onBack: _collapseCard,
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  ),

                // ── 满天飘落的彩纸与彩带彩蛋
                if (_showConfetti && _confettiCtrl != null)
                  Positioned.fill(
                    child: IgnorePointer(
                      child: AnimatedBuilder(
                        animation: _confettiCtrl!,
                        builder: (context, child) {
                          return CustomPaint(
                            painter: _ConfettiPainter(
                              pieces: _confettiPieces,
                              animationValue: _confettiCtrl!.value,
                            ),
                          );
                        },
                      ),
                    ),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildCard(int index, double cardH) {
    final config = _cardConfigs[index];
    if (config == null) return const SizedBox.shrink();

    final entry = config.entry;
    final cardKey = _cardKeys.putIfAbsent(index, () => GlobalKey());
    final mood = config.mood;
    final moodColor = config.moodColor;
    final bgWidget = config.bgWidget;
    final dateStr = config.dateStr;

    // 当前卡与非当前卡的差值（用于缩放/透明度/倾斜/弧度定位）
    final diff = index - _currentPage;
    final dist = diff.abs();
    final scale = (1.0 - dist * 0.10).clamp(0.84, 1.0);
    final opacity = (1.0 - dist * 0.35).clamp(0.55, 1.0);

    // 1. Z 轴平面旋转：让左侧卡片向左微倒，右侧卡片向右微倒，形成放射扇形
    final rotateZ = (diff * 0.05).clamp(-0.08, 0.08);

    // 2. Y 轴垂直偏移：让两侧的卡片向下沉，形成拱形/圆弧排列感
    final translateY = dist * 14.0;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 16),
      child: Opacity(
        opacity: (_isExpanding && _expandedEntry?.id == entry.id) ? 0.0 : opacity,
        child: Transform.translate(
          offset: Offset(0.0, translateY),
          child: Transform.rotate(
            angle: rotateZ,
            alignment: Alignment.center,
            child: Transform.scale(
              scale: scale,
              alignment: Alignment.center,
              child: GestureDetector(
                onTap: () {
                  HapticFeedback.selectionClick();
                  _expandCard(index, entry);
                },
                child: Container(
                  key: cardKey,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(30),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.15),
                      width: 1.0,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: moodColor.withValues(alpha: 0.35 * opacity),
                        blurRadius: 30,
                        spreadRadius: -4,
                        offset: const Offset(0, 16),
                      ),
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.30 * opacity),
                        blurRadius: 20,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(29), // 稍微内缩圆角以贴合 border 描边
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        // ── 纸质纹理或图片背景
                        bgWidget,

                        // ── 心情色叠层（让每张卡有独特色调）
                        Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                moodColor.withValues(alpha: 0.25),
                                moodColor.withValues(alpha: 0.05),
                                Colors.transparent,
                              ],
                            ),
                          ),
                        ),

                        // ── 底部渐变遮罩（文字可读性，大幅调矮调淡）
                        Positioned(
                          bottom: 0, left: 0, right: 0,
                          child: Container(
                            height: cardH * 0.26,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.bottomCenter,
                                end: Alignment.topCenter,
                                colors: [
                                  Colors.black.withValues(alpha: 0.45),
                                  Colors.black.withValues(alpha: 0.18),
                                  Colors.transparent,
                                ],
                              ),
                            ),
                          ),
                        ),

                        // ── 顶部标签
                        Positioned(
                          top: 18, left: 18,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 5),
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.30),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: Colors.white.withValues(alpha: 0.25),
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.auto_awesome_rounded,
                                    size: 11,
                                    color: Colors.white.withValues(alpha: 0.85)),
                                const SizedBox(width: 5),
                                Text(
                                  '过去的今天',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: Colors.white.withValues(alpha: 0.85),
                                    fontFamily: 'LXGWWenKai',
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),

                        // ── 底部日期与标签同行排版
                        Positioned(
                          bottom: 0, left: 0, right: 0,
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(18, 0, 18, 20),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                // 日期
                                Text(
                                  dateStr,
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w500,
                                    color: Colors.white.withValues(alpha: 0.85),
                                    fontFamily: 'LXGWWenKai',
                                    letterSpacing: 0.5,
                                  ),
                                ),
                                const Spacer(),
                                // 地点 / 心情标签行
                                Flexible(
                                  child: Wrap(
                                    spacing: 6,
                                    runSpacing: 6,
                                    alignment: WrapAlignment.end,
                                    crossAxisAlignment: WrapCrossAlignment.center,
                                    children: [
                                      if (entry.location != null)
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4.5),
                                          decoration: BoxDecoration(
                                            color: Colors.white.withValues(alpha: 0.12),
                                            borderRadius: BorderRadius.circular(15),
                                            border: Border.all(
                                              color: Colors.white.withValues(alpha: 0.20),
                                              width: 0.8,
                                            ),
                                          ),
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            crossAxisAlignment: CrossAxisAlignment.center,
                                            children: [
                                              Icon(
                                                Icons.location_on_outlined,
                                                size: 13,
                                                color: Colors.white.withValues(alpha: 0.7),
                                              ),
                                              const SizedBox(width: 4),
                                              Flexible(
                                                child: Text(
                                                  entry.location!,
                                                  overflow: TextOverflow.ellipsis,
                                                  style: TextStyle(
                                                    fontSize: 12,
                                                    fontWeight: FontWeight.w500,
                                                    color: Colors.white.withValues(alpha: 0.85),
                                                    fontFamily: 'LXGWWenKai',
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      if (mood != null) (() {
                                        final parsed = ParsedTags.parse(entry.tag, entry.moodIndex);
                                        final String moodLabel = parsed.customMood ?? mood.label;
                                        final String iconPath = parsed.customMood != null
                                            ? (entry.moodIndex >= 0 && entry.moodIndex <= 23
                                                ? 'assets/icons/custom${entry.moodIndex + 1}.png'
                                                : 'assets/images/icons/custom.png')
                                            : (mood.iconPath ?? 'assets/icons/happy.png');
                                        final bool hasCustomIcon = parsed.customMoodIconPath != null && parsed.customMoodIconPath!.isNotEmpty;

                                        return Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4.5),
                                          decoration: BoxDecoration(
                                            color: Colors.white.withValues(alpha: 0.12),
                                            borderRadius: BorderRadius.circular(15),
                                            border: Border.all(
                                              color: Colors.white.withValues(alpha: 0.20),
                                              width: 0.8,
                                            ),
                                          ),
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            crossAxisAlignment: CrossAxisAlignment.center,
                                            children: [
                                              hasCustomIcon
                                                  ? Image.file(
                                                      File(parsed.customMoodIconPath!),
                                                      width: 14,
                                                      height: 14,
                                                    )
                                                  : Image.asset(
                                                      iconPath,
                                                      width: 14,
                                                      height: 14,
                                                    ),
                                              const SizedBox(width: 5),
                                              Text(
                                                moodLabel,
                                                style: TextStyle(
                                                  fontSize: 12,
                                                  fontWeight: FontWeight.w500,
                                                  color: Colors.white.withValues(alpha: 0.85),
                                                  fontFamily: 'LXGWWenKai',
                                                ),
                                              ),
                                            ],
                                          ),
                                        );
                                      })(),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCardStatic(_CardRenderConfig config, double cardH) {
    final entry = config.entry;
    final mood = config.mood;
    final moodColor = config.moodColor;
    final bgWidget = config.bgWidget;
    final dateStr = config.dateStr;

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(30),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.15),
          width: 1.0,
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(29), // 内缩圆角贴合 border
        child: Stack(
          fit: StackFit.expand,
          children: [
            bgWidget,
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    moodColor.withValues(alpha: 0.25),
                    moodColor.withValues(alpha: 0.05),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
            Positioned(
              bottom: 0, left: 0, right: 0,
              child: Container(
                height: cardH * 0.26,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    colors: [
                      Colors.black.withValues(alpha: 0.45),
                      Colors.black.withValues(alpha: 0.18),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
            Positioned(
              top: 18, left: 18,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.30),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.25),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.auto_awesome_rounded,
                        size: 11,
                        color: Colors.white.withValues(alpha: 0.85)),
                    const SizedBox(width: 5),
                    Text(
                      '过去的今天',
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.white.withValues(alpha: 0.85),
                        fontFamily: 'LXGWWenKai',
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Positioned(
              bottom: 0, left: 0, right: 0,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(18, 0, 18, 20),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text(
                      dateStr,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: Colors.white.withValues(alpha: 0.85),
                        fontFamily: 'LXGWWenKai',
                        letterSpacing: 0.5,
                      ),
                    ),
                    const Spacer(),
                    Flexible(
                      child: Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        alignment: WrapAlignment.end,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          if (entry.location != null)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4.5),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(15),
                                border: Border.all(
                                  color: Colors.white.withValues(alpha: 0.20),
                                  width: 0.8,
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.location_on_outlined,
                                    size: 13,
                                    color: Colors.white.withValues(alpha: 0.7),
                                  ),
                                  const SizedBox(width: 4),
                                  Flexible(
                                    child: Text(
                                      entry.location!,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w500,
                                        color: Colors.white.withValues(alpha: 0.85),
                                        fontFamily: 'LXGWWenKai',
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          if (mood != null) (() {
                            final parsed = ParsedTags.parse(entry.tag, entry.moodIndex);
                            final String moodLabel = parsed.customMood ?? mood.label;
                            final String iconPath = parsed.customMood != null
                                ? (entry.moodIndex >= 0 && entry.moodIndex <= 23
                                    ? 'assets/icons/custom${entry.moodIndex + 1}.png'
                                    : 'assets/images/icons/custom.png')
                                : (mood.iconPath ?? 'assets/icons/happy.png');
                            final bool hasCustomIcon = parsed.customMoodIconPath != null && parsed.customMoodIconPath!.isNotEmpty;

                            return Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4.5),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(15),
                                border: Border.all(
                                  color: Colors.white.withValues(alpha: 0.20),
                                  width: 0.8,
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  hasCustomIcon
                                      ? Image.file(
                                          File(parsed.customMoodIconPath!),
                                          width: 14,
                                          height: 14,
                                        )
                                      : Image.asset(
                                          iconPath,
                                          width: 14,
                                          height: 14,
                                        ),
                                  const SizedBox(width: 5),
                                  Text(
                                    moodLabel,
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500,
                                      color: Colors.white.withValues(alpha: 0.85),
                                      fontFamily: 'LXGWWenKai',
                                    ),
                                  ),
                                ],
                              ),
                            );
                          })(),
                        ],
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
  }
}

class _ConfettiPiece {
  late double x;
  late double y;
  late double size;
  late Color color;
  late double speedY;
  late double speedX;
  late double rotation;
  late double rotationSpeed;
  late double oscSpeed;
  late double oscRange;
  late bool isCircle;

  _ConfettiPiece(double screenWidth) {
    final random = math.Random();
    x = random.nextDouble() * screenWidth;
    y = -random.nextDouble() * 200 - 20;
    size = 8 + random.nextDouble() * 12;

    final colors = [
      const Color(0xFFFF6B6B),
      const Color(0xFF4DABF7),
      const Color(0xFFFFD43B),
      const Color(0xFF51CF66),
      const Color(0xFFFCC419),
      const Color(0xFFE599F7),
      const Color(0xFF20C997),
    ];
    color = colors[random.nextInt(colors.length)];
    speedY = 4.0 + random.nextDouble() * 6.0;
    speedX = -1.5 + random.nextDouble() * 3.0;
    rotation = random.nextDouble() * math.pi * 2;
    rotationSpeed = -0.08 + random.nextDouble() * 0.16;
    oscSpeed = 1.0 + random.nextDouble() * 3.0;
    oscRange = 10 + random.nextDouble() * 25;
    isCircle = random.nextBool();
  }
}

class _ConfettiPainter extends CustomPainter {
  final List<_ConfettiPiece> pieces;
  final double animationValue;

  _ConfettiPainter({required this.pieces, required this.animationValue});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;

    for (var piece in pieces) {
      double currentY = piece.y + animationValue * size.height * (piece.speedY / 6.0);
      double swing = math.sin(animationValue * math.pi * 2 * piece.oscSpeed) * piece.oscRange;
      double currentX = (piece.x + swing + animationValue * size.width * (piece.speedX / 10.0)) % size.width;

      if (currentY > size.height) continue;

      paint.color = piece.color;

      // 1. 快速通道：圆形在旋转状态下视觉完全一致，直接用绝对坐标绘制，消除 expensive 的 canvas.save/restore
      if (piece.isCircle) {
        canvas.drawCircle(Offset(currentX, currentY), piece.size / 2, paint);
        continue;
      }

      // 2. 只有矩形（彩带）需要偏转偏斜效果，使用状态栈进行偏转矩阵变换
      double currentRot = piece.rotation + animationValue * 30 * piece.rotationSpeed;
      canvas.save();
      canvas.translate(currentX, currentY);
      canvas.rotate(currentRot);
      canvas.drawRect(
        Rect.fromCenter(center: Offset.zero, width: piece.size, height: piece.size * 0.5),
        paint,
      );
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant _ConfettiPainter oldDelegate) => true;
}

class _CardRenderConfig {
  final DiaryEntry entry;
  final MoodItem? mood;
  final Color moodColor;
  final String? imageUrl;
  final Widget bgWidget;
  final String dateStr;
  final String preview;

  _CardRenderConfig({
    required this.entry,
    required this.mood,
    required this.moodColor,
    required this.imageUrl,
    required this.bgWidget,
    required this.dateStr,
    required this.preview,
  });
}
