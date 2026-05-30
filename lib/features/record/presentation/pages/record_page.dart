import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:island_diary/core/state/user_state.dart';
import 'package:island_diary/features/record/domain/models/diary_entry.dart';
import 'package:island_diary/features/record/presentation/widgets/diary_search_panel.dart';
import 'package:island_diary/features/record/presentation/widgets/diary_calendar_panel.dart';
import 'package:island_diary/features/record/presentation/widgets/diary_share_card_builder.dart';
import 'package:island_diary/shared/widgets/diary_entry/utils/diary_utils.dart';
import 'package:share_plus/share_plus.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:island_diary/features/record/presentation/widgets/diary_masonry_header.dart';
import 'package:island_diary/features/record/presentation/widgets/diary_masonry_card.dart';
import 'package:island_diary/features/record/presentation/widgets/diary_featured_card.dart';
import 'package:island_diary/features/record/presentation/widgets/diary_history_overlay.dart';
import 'package:island_diary/shared/widgets/multi_value_listenable_builder.dart';

class RecordPage extends StatefulWidget {
  const RecordPage({super.key});

  @override
  State<RecordPage> createState() => _RecordPageState();
}

class _RecordPageState extends State<RecordPage> {
  DateTime? _selectedDate;
  String _searchQuery = "";
  int? _filterMoodIndex;

  final GlobalKey _shareKey = GlobalKey();
  bool _isCapturing = false;
  List<DiaryEntry> _shareEntries = [];
  String _shareTitle = "";
  bool _isMonthShare = false;
  bool _isBookShare = false;

  late final ScrollController _scrollController;
  late final ValueNotifier<DateTime> _headerDate;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _headerDate = ValueNotifier<DateTime>(DateTime.now());
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _headerDate.dispose();
    super.dispose();
  }

  void _setLayoutMode(DiaryLayoutMode mode) {
    setState(() {
      UserState().setDiaryLayoutMode(mode.index);
    });
  }

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
  Widget build(BuildContext context) {
    return MultiValueListenableBuilder(
      listenables: [
        UserState().themeMode,
        UserState().diaryLayoutMode,
        UserState().selectedIslandThemeId,
      ],
      builder: (context, values, _) {
        final int layoutIndex = values[1] as int;

        final bool isMoments = layoutIndex == DiaryLayoutMode.moments.index;
        final bool isCalendar = layoutIndex == DiaryLayoutMode.calendar.index;
        final bool isNight = _isNight;

        return Scaffold(
          backgroundColor: isNight
              ? const Color(0xFF0D1B2A)
              : const Color(0xFFF7F5F0),
          body: Stack(
            children: [
              // 背景层 (适配不同模式)
              Positioned.fill(
                child: Builder(
                  builder: (context) {
                    final themeId = UserState().selectedIslandThemeId.value;
                    if (themeId == 'lantern_festival') {
                      return Image.asset(
                        'assets/images/background/page_yuanxiaojie_bg.png',
                        fit: BoxFit.cover,
                      );
                    } else if (themeId == 'cotton_candy') {
                      return Image.asset(
                        isNight
                            ? 'assets/images/theme/miamhuadao/mianhuadao_page_night_bg.png'
                            : 'assets/images/theme/miamhuadao/mianhuadao_page_bg.png',
                        fit: BoxFit.cover,
                      );
                    } else if (themeId == 'lego') {
                      return Image.asset(
                        'assets/images/theme/legao/legao_page_bg.png',
                        fit: BoxFit.cover,
                      );
                    }
                    return AnimatedContainer(
                      duration: 500.ms,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: isNight
                              ? [
                                  const Color(0xFF0D1B2A),
                                  const Color(0xFF13131F),
                                ]
                              : [
                                  const Color(0xFFF7F2EC),
                                  const Color(0xFFF5F1EB),
                                ],
                        ),
                      ),
                    );
                  },
                ),
              ),

              // ... rest of the stack
              SafeArea(
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 16.0), // 高度整体向上提缩 76
                  child: Column(
                    children: [
                      // 留出空间给全局顶栏 (避免重叠)
                      const SizedBox(height: 80),
                      // 顶部标题与统计
                      Center(
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 800),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (!isMoments && !isCalendar)
                                ValueListenableBuilder<DateTime>(
                                  valueListenable: _headerDate,
                                  builder: (context, headerDate, _) {
                                    return DiaryMasonryHeader(
                                      isNight: isNight,
                                      userName:
                                          UserState().userName.value.isEmpty
                                          ? "我"
                                          : UserState().userName.value,
                                      islandDays: UserState()
                                          .savedDiaries
                                          .value
                                          .length, // 暂时用日记数量模拟
                                      currentDate: headerDate,
                                      onCalendarTap: () => _setLayoutMode(
                                        DiaryLayoutMode.calendar,
                                      ),
                                      showDecorateIcon: false,
                                    );
                                  },
                                )
                              else if (isCalendar)
                                const SizedBox(height: 16),
                            ],
                          ),
                        ),
                      ),

                      Expanded(
                        child: Center(
                          child: Container(
                            constraints: const BoxConstraints(maxWidth: 800),
                            child: ValueListenableBuilder<List<DiaryEntry>>(
                              valueListenable: UserState().savedDiaries,
                              builder: (context, diaries, _) {
                                if (isCalendar) {
                                  return DiaryCalendarPanel(
                                    isNight: isNight,
                                    onDateSelected: (date) {
                                      setState(() {
                                        _selectedDate = date;
                                        _headerDate.value = date;
                                        _setLayoutMode(
                                          DiaryLayoutMode.timeline,
                                        );
                                      });
                                    },
                                    onShareMonth: _shareCurrentMonth,
                                  );
                                }

                                final filtered = diaries.where((d) {
                                  final matchesDate =
                                      _selectedDate == null ||
                                      (d.dateTime.year == _selectedDate!.year &&
                                          d.dateTime.month ==
                                              _selectedDate!.month &&
                                          d.dateTime.day == _selectedDate!.day);
                                  final matchesSearch =
                                      _searchQuery.isEmpty ||
                                      d.content.contains(_searchQuery);
                                  final matchesMood =
                                      _filterMoodIndex == null ||
                                      d.moodIndex == _filterMoodIndex;
                                  return matchesDate &&
                                      matchesSearch &&
                                      matchesMood;
                                }).toList();

                                if (filtered.isEmpty && !isMoments) {
                                  return Center(
                                    child: Text(
                                      _searchQuery.isEmpty
                                          ? "还没有心情记录呢..."
                                          : "没找到相关记录哦~",
                                      style: TextStyle(
                                        color: isNight
                                            ? Colors.white30
                                            : Colors.black26,
                                        fontFamily: UserState().selectedIslandThemeId.value == 'lego' ? 'SweiFistLeg' : 'ArphicKaiti',
                                      ),
                                    ),
                                  );
                                }

                                final bool showFeatured =
                                    filtered.isNotEmpty &&
                                    filtered.first.blocks.any(
                                      (b) => b['type'] == 'image',
                                    );

                                return ShaderMask(
                                  shaderCallback: (Rect bounds) {
                                    return LinearGradient(
                                      begin: Alignment.topCenter,
                                      end: Alignment.bottomCenter,
                                      colors: const [
                                        Colors.white,       // 顶部完全不透明，不加任何遮罩或渐变
                                        Colors.white,       // 底部 110px 处仍不透明
                                        Colors.transparent, // 最底端透明过渡淡出
                                      ],
                                      stops: [
                                        0.0,
                                        (bounds.height - 110.0) / bounds.height,
                                        1.0,
                                      ],
                                    ).createShader(bounds);
                                  },
                                  blendMode: BlendMode.dstIn,
                                  child: NotificationListener<ScrollNotification>(
                                    onNotification: (notification) {
                                      if (filtered.isEmpty) return false;
                                      final double offset =
                                          _scrollController.offset;
                                      final int crossAxisCount =
                                          MediaQuery.of(context).size.width > 800
                                          ? 3
                                          : 2;
                                      int index = 0;
                                      if (offset < 260) {
                                        index = 0;
                                      } else {
                                        double masonryOffset = offset - 260;
                                        int row = (masonryOffset / 220).floor();
                                        index = 1 + row * crossAxisCount;
                                      }
                                      if (index >= filtered.length)
                                        index = filtered.length - 1;
                                      if (index < 0) index = 0;
                                      final targetDate = filtered[index].dateTime;
                                      if (_headerDate.value.day !=
                                          targetDate.day) {
                                        _headerDate.value = targetDate;
                                      }
                                      return false;
                                    },
                                    child: CustomScrollView(
                                      controller: _scrollController,
                                      slivers: [
                                        if (showFeatured)
                                          SliverToBoxAdapter(
                                            child: DiaryFeaturedCard(
                                              entry: filtered.first,
                                              isNight: isNight,
                                            ),
                                          ),
                                        SliverPadding(
                                          padding: const EdgeInsets.fromLTRB(
                                            16,
                                            0,
                                            16,
                                            120, // 增加底部 Padding，确保最后一张卡片可完全画过渐变淡出区域，清晰可见
                                          ),
                                          sliver: SliverMasonryGrid.count(
                                            crossAxisCount:
                                                MediaQuery.of(
                                                      context,
                                                    ).size.width >
                                                    800
                                                ? 3
                                                : 2,
                                            crossAxisSpacing: 12,
                                            mainAxisSpacing: 12,
                                            childCount: showFeatured
                                                ? (filtered.length > 1
                                                      ? filtered.length - 1
                                                      : 0)
                                                : filtered.length,
                                            itemBuilder: (context, index) {
                                              final actualIndex = showFeatured
                                                  ? index + 1
                                                  : index;
                                              return DiaryMasonryCard(
                                                entry: filtered[actualIndex],
                                                isNight: isNight,
                                                index: actualIndex,
                                              );
                                            },
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
                    ],
                  ),
                ),
              ),

              // 右下角工具栏
              Positioned(
                right: 20,
                bottom: 100,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildFloatingToolBtn(
                      icon: Icons.search_rounded,
                      onTap: _showSearch,
                      isNight: isNight,
                      label: "搜索",
                    ),
                  ],
                ),
              ),

              if (_isCapturing)
                Positioned.fill(
                  child: Container(
                    color: Colors.black54,
                    child: Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const CircularProgressIndicator(color: Colors.white),
                          const SizedBox(height: 16),
                          Text(
                            _isBookShare ? "正在编撰岁月之书..." : "正在制作分享卡片...",
                            style: TextStyle(
                              color: Colors.white,
                              fontFamily: UserState().selectedIslandThemeId.value == 'lego' ? 'SweiFistLeg' : 'ArphicKaiti',
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

              if (_isCapturing)
                Positioned(
                  left: -2000,
                  top: 0,
                  child: DiaryShareCardBuilder(
                    boundaryKey: _shareKey,
                    entries: _shareEntries,
                    title: _shareTitle,
                    isMonthMode: _isMonthShare,
                    isBookMode: _isBookShare,
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildFloatingToolBtn({
    required IconData icon,
    required VoidCallback onTap,
    required bool isNight,
    required String label,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: isNight ? const Color(0xFF2C2E30) : Colors.white,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Icon(
              icon,
              size: 24,
              color: isNight ? Colors.white70 : Colors.black87,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              color: isNight ? Colors.white54 : Colors.black45,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  void _showSearch() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      showDragHandle: false,
      builder: (context) => DiarySearchPanel(
        isNight: _isNight,
        initialDate: _selectedDate,
        onSearch: (q, m, d) {
          setState(() {
            _searchQuery = q;
            _filterMoodIndex = m;
            if (d != null) {
              _selectedDate = d;
              _headerDate.value = d;
            }
          });
        },
        onClear: () {
          setState(() {
            _searchQuery = "";
            _filterMoodIndex = null;
            _selectedDate = null;
          });
        },
      ),
    );
  }

  Future<void> _shareCurrentMonth([DateTime? date]) async {
    final now = date ?? _selectedDate ?? DateTime.now();
    final monthEntries = UserState().savedDiaries.value
        .where(
          (d) => d.dateTime.year == now.year && d.dateTime.month == now.month,
        )
        .toList();
    if (monthEntries.isEmpty) return;
    setState(() {
      _shareEntries = monthEntries;
      _shareTitle = "${now.year}年${now.month}月度总结";
      _isMonthShare = true;
      _isBookShare = false;
      _isCapturing = true;
    });
    await _executeCaptureAndShare(
      "diary_month_${now.millisecondsSinceEpoch}.png",
    );
  }

  Future<void> _executeCaptureAndShare(String fileName) async {
    await Future.delayed(const Duration(milliseconds: 300));
    final bytes = await DiaryUtils.captureWidgetToImage(_shareKey);
    if (bytes == null) {
      setState(() => _isCapturing = false);
      return;
    }
    final path = await DiaryUtils.saveImageToTempFile(
      bytes,
      fileName: fileName,
    );
    setState(() => _isCapturing = false);
    if (path != null) {
      await SharePlus.instance.share(
        ShareParams(files: [XFile(path)], text: '分享我在岛屿日记的点滴记录 ✨'),
      );
    }
  }
}
