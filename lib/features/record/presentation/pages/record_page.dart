import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
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
import 'package:island_diary/features/record/presentation/widgets/diary_history_card.dart';
import 'package:island_diary/shared/widgets/multi_value_listenable_builder.dart';
import 'package:island_diary/shared/widgets/diary_entry/components/diary_date_picker_sheet.dart';
import 'package:island_diary/features/record/presentation/pages/diary_editor_page.dart';


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

        final bool isCalendar = layoutIndex == DiaryLayoutMode.calendar.index;
        final bool isTimeline = layoutIndex == DiaryLayoutMode.timeline.index;
        final bool isNight = _isNight;

        return Scaffold(
          backgroundColor: isNight
              ? const Color(0xFF0D1B2A)
              : const Color(0xFFE6F3F5),
          body: Stack(
            children: [
              // 背景层 (适配不同模式)
              Positioned.fill(
                child: Builder(
                  builder: (context) {
                    final themeId = UserState().selectedIslandThemeId.value;
                    if (themeId == 'cotton_candy') {
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
                                  const Color(0xFFE6F3F5),
                                  const Color(0xFFEDF8FA),
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
                  padding: const EdgeInsets.only(bottom: 30.0), // 整体底高度向上提缩 30，精致贴合，避免缝隙漏出或底部留白过大
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
                              if (!isCalendar)
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
                                      onCalendarTap: () {
                                        // 保存外层稳定的 context，避免 onConfirm 使用底部弹窗的 context（弹窗关闭后会失效）
                                        final pageContext = context;
                                        showModalBottomSheet(
                                          context: pageContext,
                                          backgroundColor: Colors.transparent,
                                          isScrollControlled: true,
                                          showDragHandle: false,
                                          builder: (sheetContext) => DiaryDatePickerSheet(
                                            initialDate: headerDate,
                                            onConfirm: (date) {
                                              // 立即关闭底部选择器，零延迟响应，启动收起动画
                                              Navigator.pop(sheetContext);
                                              
                                              // 1. 获取当前数据及最终 targetOffset (同步计算，耗时极低)
                                              final diaries = UserState().savedDiaries.value;
                                              final filteredForScroll = diaries.where((d) {
                                                final matchesSearch = _searchQuery.isEmpty || d.content.contains(_searchQuery);
                                                final matchesMood = _filterMoodIndex == null || d.moodIndex == _filterMoodIndex;
                                                return matchesSearch && matchesMood;
                                              }).toList();
                                              
                                              int targetIndex = -1;
                                              bool exactMatch = false;
                                              if (filteredForScroll.isNotEmpty) {
                                                int minDiff = -1;
                                                for (int i = 0; i < filteredForScroll.length; i++) {
                                                  final d = filteredForScroll[i];
                                                  final dDate = DateTime(d.dateTime.year, d.dateTime.month, d.dateTime.day);
                                                  final targetDate = DateTime(date.year, date.month, date.day);
                                                  final diffMs = dDate.difference(targetDate).inMilliseconds.abs();
                                                  if (minDiff == -1 || diffMs < minDiff) {
                                                    minDiff = diffMs;
                                                    targetIndex = i;
                                                  }
                                                }
                                                if (targetIndex != -1) {
                                                  final matchDate = filteredForScroll[targetIndex].dateTime;
                                                  if (matchDate.year == date.year && matchDate.month == date.month && matchDate.day == date.day) {
                                                    exactMatch = true;
                                                  }
                                                }
                                              }
                                              
                                              setState(() {
                                                _selectedDate = date;
                                                _headerDate.value = date;
                                              });
                                              
                                              if (exactMatch && targetIndex != -1 && _scrollController.hasClients) {
                                                double targetOffset = 0;
                                                if (isTimeline) {
                                                  targetOffset = targetIndex * 230.0;
                                                } else {
                                                  final bool showFeatured = filteredForScroll.isNotEmpty && filteredForScroll.first.blocks.any((b) => b['type'] == 'image');
                                                  final int crossAxisCount = MediaQuery.of(pageContext).size.width > 800 ? 3 : 2;
                                                  
                                                  if (showFeatured) {
                                                    if (targetIndex == 0) {
                                                      targetOffset = 0;
                                                    } else {
                                                      int row = ((targetIndex - 1) / crossAxisCount).floor();
                                                      targetOffset = 260.0 + row * 220.0;
                                                    }
                                                  } else {
                                                    int row = (targetIndex / crossAxisCount).floor();
                                                    targetOffset = row * 220.0;
                                                  }
                                                }
                                                
                                                final double currentOffset = _scrollController.offset;
                                                final double distance = (targetOffset - currentOffset).abs();
                                                
                                                if (distance < 1500.0) {
                                                  _scrollController.animateTo(
                                                    targetOffset,
                                                    duration: const Duration(milliseconds: 300),
                                                    curve: Curves.easeOutCubic,
                                                  );
                                                } else {
                                                  final double fakeTarget = targetOffset > currentOffset
                                                      ? currentOffset + 200.0
                                                      : (currentOffset - 200.0).clamp(0.0, _scrollController.position.maxScrollExtent);
                                                  
                                                  _scrollController.animateTo(
                                                    fakeTarget,
                                                    duration: const Duration(milliseconds: 250),
                                                    curve: Curves.decelerate,
                                                  );
                                                  
                                                  Future.delayed(const Duration(milliseconds: 250), () {
                                                    if (!mounted || !_scrollController.hasClients) return;
                                                    
                                                     final double maxScroll = _scrollController.position.maxScrollExtent;
                                                     final double intermediateOffset = (targetOffset > currentOffset
                                                         ? targetOffset - 1200.0
                                                         : targetOffset + 1200.0).clamp(0.0, maxScroll);
                                                     
                                                     _scrollController.jumpTo(intermediateOffset);
                                                    
                                                    WidgetsBinding.instance.addPostFrameCallback((_) {
                                                      if (!mounted || !_scrollController.hasClients) return;
                                                      _scrollController.animateTo(
                                                        targetOffset,
                                                        duration: const Duration(milliseconds: 400),
                                                        curve: Curves.easeOutCubic,
                                                      );
                                                    });
                                                  });
                                                }
                                              }
                                            },
                                          ),
                                        );
                                      },
                                      showDecorateIcon: false,
                                    );
                                  },
                                )
                              else if (isCalendar)
                                const SizedBox(height: 12.0),
                            ],
                          ),
                        ),
                      ),

                      Expanded(
                        child: Align(
                          alignment: Alignment.topCenter,
                          child: Container(
                            constraints: const BoxConstraints(maxWidth: 800),
                            child: ValueListenableBuilder<List<DiaryEntry>>(
                              valueListenable: UserState().savedDiaries,
                              builder: (context, diaries, _) {
                                Widget mainContent;

                                if (isCalendar) {
                                  mainContent = DiaryCalendarPanel(
                                    key: const ValueKey('calendar'),
                                    isNight: isNight,
                                    onDateSelected: (date) {
                                      final diariesList = UserState().savedDiaries.value;
                                      int targetIndex = -1;
                                      bool exactMatch = true;
                                      
                                      if (diariesList.isNotEmpty) {
                                        DiaryEntry nearest = diariesList.first;
                                        int minDiff = (nearest.dateTime.difference(date).inMilliseconds).abs();
                                        for (var d in diariesList) {
                                          int diff = (d.dateTime.difference(date).inMilliseconds).abs();
                                          if (diff < minDiff) {
                                             minDiff = diff;
                                             nearest = d;
                                          }
                                        }
                                        targetIndex = diariesList.indexOf(nearest);
                                        final matchDate = nearest.dateTime;
                                        if (matchDate.year != date.year || matchDate.month != date.month || matchDate.day != date.day) {
                                          exactMatch = false;
                                        }
                                      }

                                      setState(() {
                                        _selectedDate = date;
                                        _headerDate.value = date;
                                        _setLayoutMode(
                                          DiaryLayoutMode.timeline,
                                        );
                                      });
                                       if (exactMatch && targetIndex != -1) {
                                         WidgetsBinding.instance.addPostFrameCallback((_) {
                                           if (!mounted || !_scrollController.hasClients) return;
                                           double targetOffset = targetIndex * 230.0;
                                           _scrollController.jumpTo(targetOffset.clamp(0.0, _scrollController.position.maxScrollExtent));
                                         });
                                       }
                                    },
                                    onShareMonth: _shareCurrentMonth,
                                  );
                                } else {
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

                                  if (filtered.isEmpty) {
                                    mainContent = Center(
                                      key: const ValueKey('empty'),
                                      child: Column(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          Image.asset(
                                            'assets/images/sticker/bp_sweet_bunny3.png',
                                            width: 160,
                                            height: 160,
                                          )
                                          .animate(onPlay: (controller) => controller.repeat(reverse: true))
                                          .moveY(begin: 0, end: -5, duration: 2000.ms, curve: Curves.easeInOut)
                                          .animate()
                                          .fade(duration: 450.ms)
                                          .scale(
                                            begin: const Offset(0.75, 0.75),
                                            end: const Offset(1.0, 1.0),
                                            duration: 650.ms,
                                            curve: Curves.elasticOut,
                                          ),
                                          const SizedBox(height: 16),
                                          Text(
                                            _searchQuery.isEmpty
                                                ? "这一天还没有留下故事呢..."
                                                : "没找到相关记录哦~",
                                            style: TextStyle(
                                              fontSize: 16,
                                              color: isNight
                                                  ? Colors.white30
                                                  : Colors.black38,
                                              fontFamily: UserState().selectedIslandThemeId.value == 'lego' ? 'SweiFistLeg' : 'ArphicKaiti',
                                            ),
                                          ).animate().fade(delay: 150.ms, duration: 400.ms).slideY(begin: 0.08, end: 0, curve: Curves.easeOut),
                                          if (_searchQuery.isEmpty) ...[
                                            const SizedBox(height: 28),
                                            Row(
                                              mainAxisAlignment: MainAxisAlignment.center,
                                              children: [
                                                if (_selectedDate != null) ...[
                                                  _buildEmptyStateBtn(
                                                    text: "清除筛选",
                                                    isPrimary: false,
                                                    isNight: isNight,
                                                    onTap: () {
                                                      setState(() {
                                                        _selectedDate = null;
                                                        _headerDate.value = DateTime.now();
                                                      });
                                                    },
                                                  ),
                                                  const SizedBox(width: 16),
                                                ],
                                                _buildEmptyStateBtn(
                                                  text: "去写一篇",
                                                  isPrimary: true,
                                                  isNight: isNight,
                                                  onTap: () => _openDiaryEntry(null, 6.0, preselectedDate: _selectedDate),
                                                ),
                                              ],
                                            ).animate().fade(delay: 280.ms, duration: 450.ms).slideY(begin: 0.12, end: 0, curve: Curves.easeOutBack),
                                          ],
                                        ],
                                      ),
                                    );
                                  } else {
                                    final bool showFeatured =
                                        filtered.isNotEmpty &&
                                        filtered.first.blocks.any(
                                          (b) => b['type'] == 'image',
                                        );

                                    Widget listContent;
                                    if (isTimeline) {
                                      listContent = NotificationListener<ScrollNotification>(
                                        onNotification: (notification) {
                                          if (filtered.isEmpty) return false;
                                          final double offset = _scrollController.offset;
                                          int index = (offset / 230).floor();
                                          if (index >= filtered.length) {
                                            index = filtered.length - 1;
                                          }
                                          if (index < 0) {
                                            index = 0;
                                          }
                                          final targetDate = filtered[index].dateTime;
                                          if (_headerDate.value.year != targetDate.year ||
                                              _headerDate.value.month != targetDate.month ||
                                              _headerDate.value.day != targetDate.day) {
                                            _headerDate.value = targetDate;
                                          }
                                          return false;
                                        },
                                        child: ListView.builder(
                                          key: const ValueKey('timeline_list'),
                                          controller: _scrollController,
                                          padding: const EdgeInsets.only(top: 16, bottom: 120),
                                          itemCount: filtered.length,
                                          itemBuilder: (context, index) {
                                            return Center(
                                              child: ConstrainedBox(
                                                constraints: const BoxConstraints(maxWidth: 800),
                                                child: DiaryHistoryCard(
                                                  entry: filtered[index],
                                                  index: index,
                                                  isNight: isNight,
                                                  showDate: index == 0 ||
                                                      filtered[index].dateTime.day !=
                                                          filtered[index - 1].dateTime.day ||
                                                      filtered[index].dateTime.month !=
                                                          filtered[index - 1].dateTime.month,
                                                  isFirst: index == 0,
                                                  isLast: index == filtered.length - 1,
                                                ),
                                              ),
                                            );
                                          },
                                        ),
                                      );
                                    } else {
                                      listContent = NotificationListener<ScrollNotification>(
                                        key: const ValueKey('masonry_list'),
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
                                          if (index >= filtered.length) {
                                            index = filtered.length - 1;
                                          }
                                          if (index < 0) {
                                            index = 0;
                                          }
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
                                      );
                                    }

                                    mainContent = RepaintBoundary(
                                      key: ValueKey('list_shader_${layoutIndex}'),
                                      child: ShaderMask(
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
                                        child: listContent,
                                      ),
                                    );
                                  }
                                }
                                return mainContent;
                              },
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              if (!isCalendar)
                Positioned(
                  right: 20,
                  bottom: 200,
                  child: _buildFloatingToolBtn(
                    icon: CupertinoIcons.search,
                    onTap: _showSearch,
                    isNight: isNight,
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
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: ClipOval(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
          child: GestureDetector(
            onTap: onTap,
            child: Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: isNight 
                    ? const Color(0xFF1B232E).withValues(alpha: 0.72) 
                    : Colors.white.withValues(alpha: 0.8),
                shape: BoxShape.circle,
                border: Border.all(
                  color: isNight 
                      ? Colors.white.withValues(alpha: 0.12) 
                      : Colors.black.withValues(alpha: 0.06),
                  width: 1.0,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.06),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Center(
                child: Icon(
                  icon,
                  size: 20,
                  color: isNight ? const Color(0xFFE1AF78) : const Color(0xFFD4A373),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyStateBtn({
    required String text,
    required bool isPrimary,
    required bool isNight,
    required VoidCallback onTap,
  }) {
    final themeId = UserState().selectedIslandThemeId.value;
    final String fontFamily = themeId == 'lego' ? 'SweiFistLeg' : 'LXGWWenKai';
    
    final decoration = isPrimary
        ? BoxDecoration(
            color: isNight
                ? const Color(0xFFD4A373).withValues(alpha: 0.15)
                : const Color(0xFFFFF6ED),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isNight
                  ? const Color(0xFFE1AF78).withValues(alpha: 0.3)
                  : const Color(0xFFD4A373).withValues(alpha: 0.4),
              width: 1.0,
            ),
          )
        : BoxDecoration(
            color: isNight
                ? Colors.white.withValues(alpha: 0.05)
                : Colors.white.withValues(alpha: 0.6),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isNight
                  ? Colors.white.withValues(alpha: 0.1)
                  : Colors.black.withValues(alpha: 0.06),
              width: 1.0,
            ),
          );

    final textColor = isPrimary
        ? (isNight ? const Color(0xFFE1AF78) : const Color(0xFFD4A373))
        : (isNight ? Colors.white54 : Colors.black45);

    return BounceScaleWidget(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
        decoration: decoration,
        child: Text(
          text,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: textColor,
            fontFamily: fontFamily,
          ),
        ),
      ),
    );
  }

  void _openDiaryEntry(int? moodIndex, double intensity, {String? tag, DateTime? preselectedDate}) {
    UserState().isDiarySheetOpen.value = true;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => DiaryEditorPage(
          moodIndex: moodIndex,
          intensity: intensity,
          tag: tag,
          initialDate: preselectedDate,
        ),
      ),
    ).then((result) {
      UserState().isDiarySheetOpen.value = false;
    });
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
            _headerDate.value = DateTime.now();
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

class BounceScaleWidget extends StatefulWidget {
  final Widget child;
  final VoidCallback onTap;
  const BounceScaleWidget({super.key, required this.child, required this.onTap});

  @override
  State<BounceScaleWidget> createState() => _BounceScaleWidgetState();
}

class _BounceScaleWidgetState extends State<BounceScaleWidget> {
  double _scale = 1.0;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _scale = 0.94),
      onTapUp: (_) => setState(() => _scale = 1.0),
      onTapCancel: () => setState(() => _scale = 1.0),
      onTap: widget.onTap,
      child: AnimatedScale(
        scale: _scale,
        duration: const Duration(milliseconds: 100),
        curve: Curves.easeOutCubic,
        child: widget.child,
      ),
    );
  }
}

