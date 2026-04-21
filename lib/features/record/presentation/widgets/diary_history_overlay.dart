import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:island_diary/core/state/user_state.dart';
import 'package:island_diary/features/record/domain/models/diary_entry.dart';
import 'package:island_diary/features/record/presentation/widgets/diary_search_panel.dart';
import 'package:island_diary/features/record/presentation/widgets/diary_calendar_panel.dart';
import 'package:island_diary/features/record/presentation/widgets/diary_history_card.dart';
import 'package:island_diary/features/record/presentation/widgets/diary_moments_card.dart';
import 'package:island_diary/features/record/presentation/widgets/diary_moments_header.dart';
import 'package:island_diary/features/record/presentation/widgets/diary_share_card_builder.dart';
import 'package:island_diary/features/record/presentation/widgets/export_config_dialog.dart';
import 'package:island_diary/shared/widgets/diary_entry/utils/diary_utils.dart';
import 'package:island_diary/features/record/presentation/pages/diary_editor_page.dart';
import 'package:island_diary/shared/widgets/diary_entry/components/diary_painters.dart';
import 'package:share_plus/share_plus.dart';

enum DiaryLayoutMode {
  timeline, // 拟物纸张时间轴
  moments, // 朋友圈风格记忆流
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

  @override
  void initState() {
    super.initState();
    _dragPosition = ValueNotifier<Offset?>(null);
    _selectedDate = null;
    // 从持久化状态加载
    _layoutMode = DiaryLayoutMode.values[UserState().diaryLayoutMode.value];
  }

  @override
  void dispose() {
    _dragPosition.dispose();
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
    final bool isMoments = _layoutMode == DiaryLayoutMode.moments;
    final bool isCalendar = _layoutMode == DiaryLayoutMode.calendar;
    final bool isNight = UserState().isNight;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          ValueListenableBuilder<String?>(
            valueListenable: UserState().momentsCoverPath,
            builder: (context, coverPath, _) {
              return Positioned.fill(
                child: Container(
                  color: isNight ? const Color(0xFF1A1C1E) : Colors.white,
                  child: isMoments
                      ? (isNight
                            ? const SizedBox.shrink()
                            : Stack(
                                children: [
                                  Positioned.fill(
                                    child: coverPath != null
                                        ? DiaryUtils.buildImage(
                                            coverPath,
                                            fit: BoxFit.cover,
                                          )
                                        : Image.asset(
                                            'assets/images/note/note_bg1.png',
                                            fit: BoxFit.cover,
                                          ),
                                  ),
                                  Positioned.fill(
                                    child: BackdropFilter(
                                      filter: ImageFilter.blur(
                                        sigmaX: 60,
                                        sigmaY: 60,
                                      ),
                                      child: Container(
                                        color: Colors.white.withValues(
                                          alpha: 0.6,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ))
                      : (isNight
                            ? null
                            : Container(color: const Color(0xFFFDF9F0))),
                ),
              );
            },
          ),
          if (!isMoments && !isCalendar)
            Positioned.fill(
              child: CustomPaint(
                painter: PaperBackgroundPainter(
                  style: 'classic', // 历史记录列表默认使用经典风格线稿
                  isNight: isNight,
                  accentColor: isNight
                      ? const Color(0xFFE0C097)
                      : const Color(0xFFD4A373),
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
                  // 统一的 800px 宽度约束容器
                  Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 800),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // 方案 B：在朋友圈模式下隐藏周历，否则显示周历及其右侧的朋友圈入口
                          if (!isMoments && !isCalendar)
                            HorizontalWeekCalendar(
                              selectedDate: _selectedDate,
                              isNight: isNight,
                              onDateSelected: (date) =>
                                  setState(() => _selectedDate = date),
                              onMomentsToggle: () =>
                                  _setLayoutMode(DiaryLayoutMode.moments),
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
                              child: (filtered.isEmpty && !isMoments)
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
                                          fontFamily: 'LXGWWenKai',
                                        ),
                                      ),
                                    )
                                  : ListView.builder(
                                      key: ValueKey('list_$_layoutMode'),
                                      padding: const EdgeInsets.only(
                                        top: 0,
                                        bottom: 100,
                                      ),
                                      itemCount: isMoments
                                          ? filtered.length + 1
                                          : filtered.length,
                                      itemBuilder: (context, index) {
                                        if (isMoments) {
                                          if (index == 0) {
                                            return DiaryMomentsHeader(
                                              isNight: isNight,
                                              onBack: () => _setLayoutMode(
                                                DiaryLayoutMode.timeline,
                                              ),
                                            );
                                          }
                                          return Center(
                                            child: ConstrainedBox(
                                              constraints: const BoxConstraints(
                                                maxWidth: contentMaxWidth,
                                              ),
                                              child: DiaryMomentsCard(
                                                entry: filtered[index - 1],
                                                isNight: isNight,
                                                userName:
                                                    UserState().userName.value,
                                              ),
                                            ),
                                          );
                                        }
                                        return Center(
                                          child: ConstrainedBox(
                                            constraints: const BoxConstraints(
                                              maxWidth: contentMaxWidth,
                                            ),
                                            child: DiaryHistoryCard(
                                              entry: filtered[index],
                                              index: index,
                                              isFilteredMode: true,
                                              isNight: isNight,
                                              showDate: _selectedDate == null,
                                              isFirst: index == 0,
                                              isLast:
                                                  index == filtered.length - 1,
                                              onShare: () => _shareCurrentDay(
                                                filtered[index].dateTime,
                                              ),
                                            ),
                                          ),
                                        );
                                      },
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
                              ? const Color(0xFF2C2E30).withValues(alpha: 0.9)
                              : Colors.white.withValues(alpha: 0.9),
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.15),
                              blurRadius: 12,
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
                              color: Color(0xFFD4A373),
                            ),
                            const Text(
                              "导出",
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w900,
                                color: Color(0xFFD4A373),
                                fontFamily: 'LXGWWenKai',
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
                          fontFamily: 'LXGWWenKai',
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

  Future<void> _shareCurrentDay([DateTime? date]) async {
    final now = date ?? _selectedDate ?? DateTime.now();
    final dayEntries = UserState().savedDiaries.value
        .where(
          (d) =>
              d.dateTime.year == now.year &&
              d.dateTime.month == now.month &&
              d.dateTime.day == now.day,
        )
        .toList();
    if (dayEntries.isEmpty) {
      return;
    }
    setState(() {
      _shareEntries = dayEntries;
      _shareTitle = "${now.year}年${now.month}月${now.day}日";
      _isMonthShare = false;
      _isBookShare = false;
      _isCapturing = true;
    });
    await _executeCaptureAndShare(
      "diary_day_${now.millisecondsSinceEpoch}.png",
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

class HorizontalWeekCalendar extends StatefulWidget {
  final DateTime? selectedDate;
  final Function(DateTime?) onDateSelected;
  final VoidCallback onMomentsToggle;
  final bool isNight;
  const HorizontalWeekCalendar({
    super.key,
    required this.selectedDate,
    required this.onDateSelected,
    required this.onMomentsToggle,
    required this.isNight,
  });
  @override
  State<HorizontalWeekCalendar> createState() => _HorizontalWeekCalendarState();
}

class _HorizontalWeekCalendarState extends State<HorizontalWeekCalendar> {
  late ScrollController _scrollController;
  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController(initialScrollOffset: 5000.0);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final firstDayOfMonth = DateTime(now.year, now.month, 1);
    final weekDates = List.generate(
      now.day,
      (i) => firstDayOfMonth.add(Duration(days: i)),
    );
    final weekDays = ["日", "一", "二", "三", "四", "五", "六"];
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Row(
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 20, right: 12),
            child: GestureDetector(
              onTap: () => widget.onDateSelected(null),
              child: Column(
                children: [
                  Text(
                    "全部",
                    style: TextStyle(
                      fontSize: 12,
                      color: widget.isNight
                          ? Colors.white30
                          : Colors.black.withValues(alpha: 0.25),
                      fontFamily: 'LXGWWenKai',
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: widget.selectedDate == null
                          ? const Color(0xFFD4A373)
                          : Colors.transparent,
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Icon(
                        Icons.all_inclusive,
                        size: 20,
                        color: widget.selectedDate == null
                            ? Colors.white
                            : (widget.isNight
                                  ? Colors.white30
                                  : Colors.black38),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              controller: _scrollController,
              child: Row(
                children: [
                  ...weekDates.map((date) {
                    final isSelected =
                        widget.selectedDate != null &&
                        date.day == widget.selectedDate!.day &&
                        date.month == widget.selectedDate!.month &&
                        date.year == widget.selectedDate!.year;
                    return GestureDetector(
                      onTap: () => widget.onDateSelected(date),
                      child: Container(
                        width: 45,
                        margin: const EdgeInsets.symmetric(horizontal: 2),
                        child: Column(
                          children: [
                            Text(
                              weekDays[date.weekday % 7],
                              style: TextStyle(
                                fontSize: 12,
                                color: isSelected
                                    ? const Color(0xFFD4A373)
                                    : (widget.isNight
                                          ? Colors.white30
                                          : Colors.black26),
                                fontFamily: 'LXGWWenKai',
                              ),
                            ),
                            const SizedBox(height: 8),
                            Container(
                              width: 38,
                              height: 38,
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? const Color(0xFFD4A373)
                                    : Colors.transparent,
                                shape: BoxShape.circle,
                              ),
                              child: Center(
                                child: Text(
                                  "${date.day}",
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: isSelected
                                        ? FontWeight.bold
                                        : FontWeight.normal,
                                    color: isSelected
                                        ? Colors.white
                                        : (widget.isNight
                                              ? Colors.white54
                                              : Colors.black87),
                                    fontFamily: 'LXGWWenKai',
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                  const SizedBox(width: 44), // 为右侧固定按钮预留安全空隙
                ],
              ),
            ),
          ),
          // 右侧朋友圈入口 - 固定在右侧，不随日期滚动
          Padding(
            padding: const EdgeInsets.only(left: 6, right: 16),
            child: GestureDetector(
              onTap: widget.onMomentsToggle,
              child: Column(
                children: [
                  Text(
                    "朋友圈",
                    style: TextStyle(
                      fontSize: 12,
                      color: widget.isNight
                          ? Colors.white30
                          : Colors.black.withValues(alpha: 0.25),
                      fontFamily: 'LXGWWenKai',
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: (widget.isNight
                          ? Colors.white10
                          : Colors.black.withValues(alpha: 0.04)),
                      shape: BoxShape.circle,
                    ),
                    child: const Center(
                      child: Icon(
                        Icons.camera_rounded,
                        size: 20,
                        color: Color(0xFFD4A373),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
