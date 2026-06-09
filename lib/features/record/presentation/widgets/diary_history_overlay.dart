import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:island_diary/core/state/user_state.dart';
import 'package:island_diary/features/record/domain/models/diary_entry.dart';
import 'package:island_diary/features/record/presentation/widgets/diary_search_panel.dart';
import 'package:island_diary/features/record/presentation/widgets/diary_calendar_panel.dart';
import 'package:island_diary/features/record/presentation/widgets/diary_share_card_builder.dart';
import 'package:island_diary/features/record/presentation/widgets/export_config_dialog.dart';
import 'package:island_diary/shared/widgets/diary_entry/utils/diary_utils.dart';
import 'package:island_diary/features/record/presentation/pages/diary_editor_page.dart';
import 'package:share_plus/share_plus.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:island_diary/features/record/presentation/widgets/diary_masonry_header.dart';
import 'package:island_diary/features/record/presentation/widgets/diary_masonry_card.dart';
import 'package:island_diary/features/record/presentation/widgets/diary_featured_card.dart';
import 'package:island_diary/features/record/presentation/pages/decoration_page.dart';

enum DiaryLayoutMode {
  timeline, // 时间轴模式
  masonry, // 小红书模式
  calendar, // 日历网格
}

class DiaryHistoryOverlay extends StatefulWidget {
  final VoidCallback onClose;
  const DiaryHistoryOverlay({super.key, required this.onClose});

  @override
  State<DiaryHistoryOverlay> createState() => _DiaryHistoryOverlayState();
}

class _DiaryHistoryOverlayState extends State<DiaryHistoryOverlay> {
  DateTime? _selectedDate;
  String _searchQuery = "";
  int? _filterMoodIndex;

  late DiaryLayoutMode _layoutMode;

  final GlobalKey _shareKey = GlobalKey();
  bool _isCapturing = false;
  List<DiaryEntry> _shareEntries = [];
  String _shareTitle = "";
  bool _isMonthShare = false;
  bool _isBookShare = false;
  late final ValueNotifier<Offset?> _dragPosition;
  late final ScrollController _scrollController;
  late final ValueNotifier<DateTime> _headerDate;

  @override
  void initState() {
    super.initState();
    _dragPosition = ValueNotifier<Offset?>(null);
    _scrollController = ScrollController();
    _headerDate = ValueNotifier<DateTime>(DateTime.now());
    _selectedDate = null;
    // 从持久化状态加载
    int savedIndex = UserState().diaryLayoutMode.value;
    // 防止旧数据保存的 index (如 1 为 moments) 超出新的范围或者定位错乱，这里做一个安全转换映射
    if (savedIndex == 1) {
      savedIndex = 0; // moments 回落至 timeline
    } else if (savedIndex > 1) {
      savedIndex -= 1; // 后续 index 均向前平移一位
    }
    _layoutMode = DiaryLayoutMode.values[savedIndex.clamp(0, DiaryLayoutMode.values.length - 1)];
  }

  @override
  void dispose() {
    _dragPosition.dispose();
    _scrollController.dispose();
    _headerDate.dispose();
    super.dispose();
  }

  void _setLayoutMode(DiaryLayoutMode mode) {
    setState(() {
      _layoutMode = mode;
      UserState().setDiaryLayoutMode(mode.index);
    });
  }

  void _cycleLayoutMode() {
    // 恢复为之前的双态切换：Timeline <-> Calendar
    setState(() {
      if (_layoutMode == DiaryLayoutMode.calendar) {
        _layoutMode = DiaryLayoutMode.timeline;
      } else {
        _layoutMode = DiaryLayoutMode.calendar;
      }
      UserState().setDiaryLayoutMode(_layoutMode.index);
    });
  }

  IconData _getLayoutIcon() {
    // 只在列表和日历间切换的图标提示
    return _layoutMode == DiaryLayoutMode.calendar
        ? Icons.format_list_bulleted_rounded
        : Icons.calendar_month_rounded;
  }

  @override
  Widget build(BuildContext context) {
    final bool isCalendar = _layoutMode == DiaryLayoutMode.calendar;
    final bool isNight = UserState().isNight;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          Positioned.fill(
            child: Container(
              color: isNight ? const Color(0xFF13131F) : const Color(0xFFF7F5F0),
              child: isNight
                  ? null
                  : Container(color: const Color(0xFFFDF9F0)),
            ),
          ),
          if (!isCalendar)
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: isNight 
                        ? [const Color(0xFF1A1A24), const Color(0xFF13131F)]
                        : [const Color(0xFFF7F2EC), const Color(0xFFF5F1EB)],
                  ),
                ),
              ),
            ),
          Positioned.fill(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
              child: Container(
                color: isNight
                    ? Colors.transparent
                    : Colors.white.withValues(alpha: 0.3),
              ),
            ),
          ),
          Positioned.fill(
            child: SafeArea(
              bottom: false,
              child: Column(
                children: [
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
                                  userName: UserState().userName.value.isEmpty ? "我" : UserState().userName.value,
                                  islandDays: 128, // mock
                                  currentDate: headerDate,
                                  onCalendarTap: () => _setLayoutMode(DiaryLayoutMode.calendar),
                                  onDecorateTap: () => Navigator.push(
                                    context,
                                    MaterialPageRoute(builder: (context) => const DecorationPage()),
                                  ),
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
                    child: Center(
                      child: Container(
                        constraints: const BoxConstraints(maxWidth: 800),
                        child: ValueListenableBuilder<List<DiaryEntry>>(
                          valueListenable: UserState().savedDiaries,
                          builder: (context, diaries, _) {
                            const double contentMaxWidth = 800.0;

                            if (isCalendar) {
                              return Center(
                                child: ConstrainedBox(
                                  constraints: const BoxConstraints(
                                    maxWidth: contentMaxWidth,
                                  ),
                                  child: DiaryCalendarPanel(
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
                                  ),
                                ),
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

                            return AnimatedSwitcher(
                              duration: const Duration(milliseconds: 300),
                              child: filtered.isEmpty
                                  ? Center(
                                      key: const ValueKey('empty'),
                                      child: Text(
                                        _searchQuery.isEmpty
                                            ? "还没有心情记录呢..."
                                            : "没找到相关记录哦~",
                                        style: TextStyle(
                                          color: isNight
                                              ? Colors.white30
                                              : Colors.black.withValues(
                                                  alpha: 0.3,
                                                ),
                                          fontFamily: 'ArphicKaiti',
                                        ),
                                      ),
                                    )
                                  : NotificationListener<ScrollNotification>(
                                      onNotification: (notification) {
                                        if (filtered.isEmpty) return false;
                                        
                                        final double offset = _scrollController.offset;
                                        final int crossAxisCount = MediaQuery.of(context).size.width > 800 ? 3 : 2;
                                        
                                        int index = 0;
                                        if (offset < 260) {
                                          index = 0;
                                        } else {
                                          double masonryOffset = offset - 260;
                                          int row = (masonryOffset / 220).floor(); // 估算行高
                                          index = 1 + row * crossAxisCount;
                                        }
                                        
                                        if (index >= filtered.length) index = filtered.length - 1;
                                        if (index < 0) index = 0;
                                        
                                        final targetDate = filtered[index].dateTime;
                                        if (_headerDate.value.year != targetDate.year || 
                                            _headerDate.value.month != targetDate.month || 
                                            _headerDate.value.day != targetDate.day) {
                                          _headerDate.value = targetDate;
                                        }
                                        return false;
                                      },
                                      child: CustomScrollView(
                                        key: const ValueKey('masonry'),
                                        controller: _scrollController,
                                        slivers: [
                                          if (filtered.isNotEmpty)
                                            SliverToBoxAdapter(
                                              child: DiaryFeaturedCard(
                                                entry: filtered.first,
                                                isNight: isNight,
                                              ),
                                            ),
                                          SliverPadding(
                                            padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
                                            sliver: SliverMasonryGrid.count(
                                              crossAxisCount: MediaQuery.of(context).size.width > 800 ? 3 : 2,
                                              crossAxisSpacing: 12,
                                              mainAxisSpacing: 12,
                                              childCount: filtered.length > 1 ? filtered.length - 1 : 0,
                                              itemBuilder: (context, index) {
                                                return DiaryMasonryCard(
                                                  entry: filtered[index + 1],
                                                  isNight: isNight,
                                                  index: index + 1,
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

          if (!isCalendar)
            ValueListenableBuilder<Offset?>(
              valueListenable: _dragPosition,
              builder: (context, dragOffset, _) {
                final size = MediaQuery.of(context).size;
                final bool isWide = size.width > 800;
                final double effectiveWidth = isWide ? 800 : size.width;
                final double leftOffset = isWide ? (size.width - 800) / 2 : 0;

                final defaultPos = Offset(
                  leftOffset + effectiveWidth - 66,
                  size.height / 2 - 23,
                );
                final currentPos = dragOffset ?? defaultPos;
                return Positioned(
                  left: currentPos.dx,
                  top: currentPos.dy,
                  child: RepaintBoundary(
                    child: GestureDetector(
                      onPanUpdate: (details) => _dragPosition.value =
                          (_dragPosition.value ?? defaultPos) + details.delta,
                      onTap: _exportAllAsBook,
                      child: Container(
                        width: 50,
                        height: 50,
                        decoration: BoxDecoration(
                          color: isNight
                              ? const Color(0xFF212831)
                              : Colors.white.withValues(alpha: 0.9),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: isNight
                                ? const Color(0xFFE1AF78).withValues(alpha: 0.25)
                                : const Color(0xFFD4A373).withValues(alpha: 0.2),
                            width: 1.5,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: isNight ? 0.35 : 0.15),
                              blurRadius: 15,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              Icons.auto_stories_rounded,
                              size: 20,
                              color: Color(0xFFE1AF78),
                            ),
                            const Text(
                              "导出",
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w900,
                                color: Color(0xFFE1AF78),
                                fontFamily: 'ArphicKaiti',
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),

          Positioned(
            left: 0,
            right: 0,
            bottom: 30,
            child: Builder(
              builder: (context) {
                final double screenWidth = MediaQuery.of(context).size.width;
                final bool isWide = screenWidth > 800;
                return Center(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      maxWidth: isWide ? 800 : double.infinity,
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          // 1. 居中的主工具栏
                          Container(
                                height: 54,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 20,
                                ),
                                decoration: BoxDecoration(
                                  color: isNight
                                      ? const Color(0xFF2C2E30)
                                      : Colors.white,
                                  borderRadius: BorderRadius.circular(27),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withValues(
                                        alpha: 0.12,
                                      ),
                                      blurRadius: 10,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    if (!isCalendar) ...[
                                      _buildToolBtn(Icons.search_rounded, () {
                                        showModalBottomSheet(
                                          context: context,
                                          backgroundColor: Colors.transparent,
                                          isScrollControlled: true,
                                          builder: (context) => DiarySearchPanel(
                                            isNight: isNight,
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
                                      }, isNight: isNight),
                                      const SizedBox(width: 40),
                                    ],
                                    GestureDetector(
                                      onTap: widget.onClose,
                                      child: Icon(
                                        Icons.close_rounded,
                                        size: 28,
                                        color: isNight
                                            ? Colors.white70
                                            : Colors.black87,
                                      ),
                                    ),
                                    const SizedBox(width: 40),
                                    _buildToolBtn(
                                      _getLayoutIcon(),
                                      _cycleLayoutMode,
                                      isNight: isNight,
                                      isActive:
                                          _layoutMode !=
                                          DiaryLayoutMode.timeline,
                                    ),
                                  ],
                                ),
                              )
                              .animate()
                              .fadeIn(delay: 200.ms)
                              .scale(begin: const Offset(0.9, 0.9)),
                          const SizedBox(width: 16),
                          // 2. 靠在一起的添加按钮
                          _buildAddButton(isNight),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),

          if (_isCapturing)
            Positioned.fill(
              child: Container(
                color: Colors.black.withValues(alpha: 0.3),
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const CircularProgressIndicator(color: Colors.white),
                      const SizedBox(height: 16),
                      Text(
                        _isBookShare ? "正在编撰岁月之书..." : "正在制作分享卡片...",
                        style: const TextStyle(
                          color: Colors.white,
                          fontFamily: 'ArphicKaiti',
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
  }


  Future<void> _shareCurrentMonth([DateTime? date]) async {
    final now = date ?? _selectedDate ?? DateTime.now();
    final monthEntries = UserState().savedDiaries.value
        .where(
          (d) => d.dateTime.year == now.year && d.dateTime.month == now.month,
        )
        .toList();
    if (monthEntries.isEmpty) {
      return;
    }
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

  void _exportAllAsBook() {
    final all = UserState().savedDiaries.value;
    if (all.isEmpty) {
      return;
    }
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'ExportConfig',
      barrierColor: Colors.black.withValues(alpha: 0.4),
      transitionDuration: const Duration(milliseconds: 300),
      pageBuilder: (context, anim1, anim2) =>
          ExportConfigDialog(allDiaries: all),
      transitionBuilder: (context, animation, second, child) =>
          FadeTransition(opacity: animation, child: child),
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

  Widget _buildToolBtn(
    IconData icon,
    VoidCallback onTap, {
    bool isNight = false,
    bool isActive = false,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Icon(
        icon,
        size: 24,
        color: isActive
            ? const Color(0xFFD4A373)
            : (isNight ? Colors.white54 : Colors.black.withValues(alpha: 0.4)),
      ),
    );
  }

  Widget _buildAddButton(bool isNight) {
    return GestureDetector(
      onTap: _openNewDiary,
      child: Container(
        width: 54,
        height: 54,
        decoration: BoxDecoration(
          color: const Color(0xFFD4A373),
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFD4A373).withValues(alpha: 0.4),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: const Icon(Icons.add_rounded, size: 32, color: Colors.white),
      ).animate().fadeIn(delay: 250.ms).scale(begin: const Offset(0.9, 0.9)),
    );
  }

  Future<void> _openNewDiary() async {
    final draft = UserState().diaryDraft.value;
    if (draft != null) {
      UserState().isDiarySheetOpen.value = true;
      await Navigator.push<bool>(
        context,
        MaterialPageRoute(
          builder: (context) => DiaryEditorPage(
            moodIndex: draft.moodIndex,
            intensity: draft.intensity,
            tag: draft.tag,
          ),
        ),
      );
      UserState().isDiarySheetOpen.value = false;
      return;
    }

    // 直接进入编辑器 (默认：平静心情)
    UserState().isDiarySheetOpen.value = true;
    await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (context) => const DiaryEditorPage(moodIndex: 4, intensity: 6),
      ),
    );
    UserState().isDiarySheetOpen.value = false;
  }
}

