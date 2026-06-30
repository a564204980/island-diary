import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:island_diary/core/state/user_state.dart';
import 'package:island_diary/features/record/domain/models/diary_entry.dart';
import 'package:island_diary/features/record/presentation/widgets/diary_search_panel.dart';
import 'package:island_diary/features/record/presentation/widgets/diary_calendar_panel.dart';
import 'package:island_diary/features/record/presentation/widgets/diary_share_card_builder.dart';
import 'package:island_diary/shared/widgets/diary_entry/utils/diary_utils.dart';
import 'package:island_diary/features/record/presentation/pages/diary_editor_page.dart';
import 'package:share_plus/share_plus.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:island_diary/features/record/presentation/widgets/diary_masonry_header.dart';
import 'package:island_diary/features/record/presentation/widgets/diary_masonry_card.dart';
import 'package:island_diary/features/record/domain/models/diary_book.dart';
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
  bool _isSelectMode = false;
  final Set<String> _selectedIds = {};

  late DiaryLayoutMode _layoutMode;

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
                                          if (filtered.isNotEmpty && !_isSelectMode)
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
                                              childCount: _isSelectMode
                                                  ? filtered.length
                                                  : (filtered.length > 1 ? filtered.length - 1 : 0),
                                              itemBuilder: (context, index) {
                                                final entry = _isSelectMode
                                                    ? filtered[index]
                                                    : filtered[index + 1];
                                                final id = entry.id;
                                                final bool isSelected = _selectedIds.contains(id);
                                                return DiaryMasonryCard(
                                                  entry: entry,
                                                  isNight: isNight,
                                                  index: _isSelectMode ? index : index + 1,
                                                  isSelectMode: _isSelectMode,
                                                  isSelected: isSelected,
                                                  onTap: () {
                                                    setState(() {
                                                      if (isSelected) {
                                                        _selectedIds.remove(id);
                                                      } else {
                                                        _selectedIds.add(id);
                                                      }
                                                    });
                                                  },
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
                      child: _isSelectMode
                          ? Container(
                              height: 54,
                              padding: const EdgeInsets.symmetric(horizontal: 20),
                              decoration: BoxDecoration(
                                color: isNight ? const Color(0xFF2C2E30) : Colors.white,
                                borderRadius: BorderRadius.circular(27),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.12),
                                    blurRadius: 10,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    '已选择 ${_selectedIds.length} 篇记录',
                                    style: TextStyle(
                                      color: isNight ? Colors.white70 : Colors.black87,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 13,
                                      fontFamily: 'LXGWWenKai',
                                    ),
                                  ),
                                  Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      TextButton.icon(
                                        icon: const Icon(Icons.drive_file_move_rounded, size: 18, color: Color(0xFFD4A373)),
                                        label: const Text('归档至...', style: TextStyle(color: Color(0xFFD4A373), fontWeight: FontWeight.bold, fontSize: 13)),
                                        onPressed: _selectedIds.isEmpty
                                            ? null
                                            : () => _showBatchMoveDialog(context),
                                      ),
                                      const SizedBox(width: 8),
                                      IconButton(
                                        icon: Icon(Icons.close_rounded, size: 20, color: isNight ? Colors.white54 : Colors.black45),
                                        onPressed: () {
                                          setState(() {
                                            _isSelectMode = false;
                                            _selectedIds.clear();
                                          });
                                        },
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ).animate().slideY(begin: 0.2, end: 0)
                          : Row(
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
                                            _buildToolBtn(
                                              _isSelectMode
                                                  ? Icons.close_rounded
                                                  : Icons.checklist_rounded,
                                              () {
                                                setState(() {
                                                  _isSelectMode = !_isSelectMode;
                                                  _selectedIds.clear();
                                                });
                                              },
                                              isNight: isNight,
                                              isActive: _isSelectMode,
                                            ),
                                            const SizedBox(width: 40),
                                            _buildToolBtn(Icons.search_rounded, () {
                                              showModalBottomSheet(
                                                context: context,
                                                backgroundColor: Colors.transparent,
                                                isScrollControlled: true,
                                                builder: (context) => DiarySearchPanel(
                                                  isNight: isNight,
                                                  onSearch: (q, m) {
                                                    setState(() {
                                                      _searchQuery = q;
                                                      _filterMoodIndex = m;
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

  void _showBatchMoveDialog(BuildContext context) {
    final bool isNight = UserState().isNight;
    final String fontFamily = UserState().selectedIslandThemeId.value == 'lego'
        ? 'SweiFistLeg'
        : 'LXGWWenKai';
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 30),
          decoration: BoxDecoration(
            color: isNight ? const Color(0xFF1E1E2C) : Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                '归档至指定的岁月之书',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, fontFamily: fontFamily),
              ),
              const SizedBox(height: 16),
              ValueListenableBuilder<List<DiaryBook>>(
                valueListenable: UserState().savedBooks,
                builder: (context, books, _) {
                  return Column(
                    children: books.map((book) {
                      return ListTile(
                        leading: const Icon(Icons.book_rounded, color: Color(0xFFD4A373)),
                        title: Text(book.name, style: TextStyle(fontFamily: fontFamily)),
                        onTap: () async {
                          await UserState().moveDiariesToBook(_selectedIds.toList(), book.id);
                          if (!context.mounted) return;
                          setState(() {
                            _isSelectMode = false;
                            _selectedIds.clear();
                          });
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('已将日记成功归档至《${book.name}》', style: TextStyle(fontFamily: fontFamily))),
                          );
                        },
                      );
                    }).toList(),
                  );
                },
              ),
            ],
          ),
        );
      },
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
        ShareParams(
          files: [XFile(path)],
          text: '分享我在岛屿日记的点滴记录 ✨',
        ),
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

