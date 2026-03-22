import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:island_diary/core/state/user_state.dart';
import 'package:island_diary/features/record/domain/models/diary_entry.dart';
import 'package:island_diary/features/record/presentation/widgets/diary_search_panel.dart';
import 'package:island_diary/features/record/presentation/widgets/diary_calendar_panel.dart';
import 'package:island_diary/features/record/presentation/widgets/diary_history_card.dart';
import 'package:island_diary/features/record/presentation/widgets/diary_share_card_builder.dart';
import 'package:island_diary/features/record/presentation/widgets/export_config_dialog.dart';
import 'package:island_diary/shared/widgets/diary_entry/utils/diary_utils.dart';
import 'package:share_plus/share_plus.dart';
/// 时间轴历史记录全屏覆盖层
class DiaryHistoryOverlay extends StatefulWidget {
  final VoidCallback onClose;
  const DiaryHistoryOverlay({super.key, required this.onClose});

  @override
  State<DiaryHistoryOverlay> createState() => _DiaryHistoryOverlayState();
}

class _DiaryHistoryOverlayState extends State<DiaryHistoryOverlay> {
  DateTime? _selectedDate; // 改为可选，null 表示显示全部
  String _searchQuery = "";
  int? _filterMoodIndex;
  bool _isCalendarView = false; // 是否显示日历格网视图

  // 分享相关状态
  final GlobalKey _shareKey = GlobalKey();
  bool _isCapturing = false;
  List<DiaryEntry> _shareEntries = [];
  String _shareTitle = "";
  bool _isMonthShare = false;
  bool _isBookShare = false;
  late final ValueNotifier<Offset?> _dragPosition; // 使用 ValueNotifier 优化拖拽性能

  @override
  void initState() {
    super.initState();
    _dragPosition = ValueNotifier<Offset?>(null);
    // 默认显示全部记录，或者选中今天
    _selectedDate = null;
  }

  @override
  void dispose() {
    _dragPosition.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          // 1. 拟物化纸张底层
          Positioned.fill(
            child: Container(
              color: UserState().isNight ? const Color(0xFF141414) : const Color(0xFFFDF9F0),
            ),
          ),
          // 2. 纸张纹理绘制
          Positioned.fill(
            child: CustomPaint(
              painter: PaperBackgroundPainter(isNight: UserState().isNight),
            ),
          ),
          // 3. 增强通透感的毛玻璃
          Positioned.fill(
            child: GestureDetector(
              onTap: widget.onClose,
            child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
                child: Container(
                  color: UserState().isNight
                      ? Colors.transparent
                      : Colors.white.withOpacity(0.3),
                ),
              ),
            ),
          ),

          // 内容区域
          Positioned.fill(
            child: SafeArea(
              bottom: false,
              child: Column(
                children: [
                  // 顶部周历选择器 (仅在时间轴模式显示)
                  if (!_isCalendarView)
                    HorizontalWeekCalendar(
                      selectedDate: _selectedDate,
                      isNight: UserState().isNight,
                      onDateSelected: (date) {
                        setState(() {
                          _selectedDate = date;
                        });
                      },
                    )
                  else
                    const SizedBox(height: 16),

                  // 历史列表
                  Expanded(
                    child: ValueListenableBuilder<List<DiaryEntry>>(
                      valueListenable: UserState().savedDiaries,
                      builder: (context, diaries, _) {
                        // 如果是日历视图模式，直接返回日历面板
                        if (_isCalendarView) {
                          return DiaryCalendarPanel(
                            isNight: UserState().isNight,
                            onDateSelected: (date) {
                              setState(() {
                                _selectedDate = date;
                                _isCalendarView = false;
                              });
                            },
                            onShareMonth: _shareCurrentMonth,
                          );
                        }

                        // 按日期及搜索条件过滤
                        final filteredByDate = _selectedDate == null
                            ? diaries
                            : diaries
                                  .where(
                                    (d) =>
                                        d.dateTime.year ==
                                            _selectedDate!.year &&
                                        d.dateTime.month ==
                                            _selectedDate!.month &&
                                        d.dateTime.day == _selectedDate!.day,
                                  )
                                  .toList();

                        // 搜索过滤
                        final filtered = filteredByDate.where((d) {
                          final matchesSearch =
                              _searchQuery.isEmpty ||
                              d.content.contains(_searchQuery);
                          final matchesMood =
                              _filterMoodIndex == null ||
                              d.moodIndex == _filterMoodIndex;
                          return matchesSearch && matchesMood;
                        }).toList();

                        return AnimatedSwitcher(
                          duration: const Duration(milliseconds: 300),
                          child: (filtered.isEmpty)
                              ? Center(
                                  key: const ValueKey('empty'),
                                  child: Text(
                                    _searchQuery.isEmpty
                                        ? "还没有心情记录呢..."
                                        : "没找到相关记录哦~",
                                    style: TextStyle(
                                      color: UserState().isNight
                                          ? Colors.white30
                                          : Colors.black.withOpacity(0.3),
                                      fontFamily: 'LXGWWenKai',
                                    ),
                                  ),
                                )
                              : ListView.builder(
                                  key: const ValueKey('list'),
                                  padding: const EdgeInsets.only(
                                    left: 16,
                                    right: 16,
                                    top: 0,
                                    bottom: 100,
                                  ),
                                  itemCount: filtered.length,
                                  itemBuilder: (context, index) {
                                    return DiaryHistoryCard(
                                      entry: filtered[index],
                                      index: index,
                                      isFilteredMode: true,
                                      isNight: UserState().isNight,
                                      showDate: _selectedDate == null,
                                      isFirst: index == 0,
                                      isLast: index == filtered.length - 1,
                                      onShare: () => _shareCurrentDay(
                                        filtered[index].dateTime,
                                      ),
                                    );
                                  },
                                ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),

          // 3.5 悬浮：导出成书入口 (极致性能优化版)
          if (!_isCalendarView)
            ValueListenableBuilder<Offset?>(
              valueListenable: _dragPosition,
              builder: (context, dragOffset, _) {
                final size = MediaQuery.of(context).size;
                // 初始/默认位置：右侧中间
                final defaultPos = Offset(size.width - 66, size.height / 2 - 23);
                final currentPos = dragOffset ?? defaultPos;
 
                return Positioned(
                left: currentPos.dx,
                top: currentPos.dy,
                child: RepaintBoundary(
                  child: GestureDetector(
                    onPanUpdate: (details) {
                      // 关键：始终基于当前 ValueNotifier 的最新值进行叠加，消除视觉上的延迟
                      final val = _dragPosition.value ?? defaultPos;
                      _dragPosition.value = val + details.delta;
                    },
                    onTap: _exportAllAsBook,
                    child: Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        color: UserState().isNight
                            ? const Color(0xFF2C2E30).withOpacity(0.9)
                            : Colors.white.withOpacity(0.9),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: UserState().isNight
                              ? Colors.white10
                              : const Color(0xFFD4A373).withOpacity(0.3),
                          width: 1.5,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.15),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.auto_stories_rounded,
                          size: 20, // 稍微调小一点，腾出位置给文字
                          color: UserState().isNight
                              ? const Color(0xFFD4A373).withOpacity(0.9)
                              : const Color(0xFFD4A373),
                        ),
                        const SizedBox(height: 1),
                        Text(
                          "导出",
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w900,
                            fontFamily: 'LXGWWenKai',
                            color: UserState().isNight
                                ? const Color(0xFFD4A373).withOpacity(0.8)
                                : const Color(0xFFD4A373),
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

          // 4. 底部工具栏
          Positioned(
                left: 0,
                right: 0,
                bottom: 30,
                child: Center(
                  child: Container(
                    height: 54,
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    decoration: BoxDecoration(
                      color: UserState().isNight
                          ? const Color(0xFF2C2E30)
                          : Colors.white,
                      borderRadius: BorderRadius.circular(27),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.12),
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
                              isNight: UserState().isNight,
                              initialDate: _selectedDate,
                              onSearch: (query, moodIdx, date) {
                                setState(() {
                                  _searchQuery = query;
                                  _filterMoodIndex = moodIdx;
                                  if (date != null) {
                                    _selectedDate = date;
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
                        }, isNight: UserState().isNight),
                        const SizedBox(width: 40),
                        GestureDetector(
                          onTap: widget.onClose,
                          child: Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Icon(
                              Icons.close_rounded,
                              size: 28,
                              color: UserState().isNight
                                  ? Colors.white70
                                  : Colors.black87,
                            ),
                          ),
                        ),
                        const SizedBox(width: 40),
                        _buildToolBtn(
                          _isCalendarView
                              ? Icons.format_list_bulleted_rounded
                              : Icons.calendar_month_rounded,
                          () {
                            setState(() {
                              _isCalendarView = !_isCalendarView;
                            });
                          },
                          isNight: UserState().isNight,
                          isActive: _isCalendarView,
                        ),
                        // 移除了全局分享按钮，改为卡片内分享
                      ],
                    ),
                  ).animate().fadeIn(delay: 200.ms).scale(begin: const Offset(0.9, 0.9)),
                ),
              ),

          // 5. 隐藏的截图区域
          if (_isCapturing)
            Positioned(
              left: -2000, // 极远距离确保不被看见
              top: 0,
              child: DiaryShareCardBuilder(
                boundaryKey: _shareKey,
                entries: _shareEntries,
                title: _shareTitle,
                isMonthMode: _isMonthShare,
                isBookMode: _isBookShare,
              ),
            ),

          // 加载遮罩 (截图时)
          if (_isCapturing)
            Positioned.fill(
              child: Container(
                color: Colors.black.withOpacity(0.3),
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const CircularProgressIndicator(color: Colors.white),
                      const SizedBox(height: 16),
                      Text(
                        _isBookShare ? "正在编撰你的岁月之书..." : "正在制作分享卡片...",
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
        ],
      ),
    );
  }

  Future<void> _shareCurrentDay([DateTime? date]) async {
    final now = date ?? _selectedDate ?? DateTime.now();
    final dayLabel = "${now.year}年${now.month}月${now.day}日";

    // 获取当天的所有记录
    final allDiaries = UserState().savedDiaries.value;
    final dayEntries = allDiaries
        .where(
          (d) =>
              d.dateTime.year == now.year &&
              d.dateTime.month == now.month &&
              d.dateTime.day == now.day,
        )
        .toList();

    if (dayEntries.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            "这一天还没有记录哦~",
            style: TextStyle(fontFamily: 'LXGWWenKai'),
          ),
        ),
      );
      return;
    }

    setState(() {
      _shareEntries = dayEntries;
      _shareTitle = dayLabel;
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
    final monthLabel = "${now.year}年${now.month}月度总结";

    // 获取当月的所有记录
    final allDiaries = UserState().savedDiaries.value;
    final monthEntries = allDiaries
        .where(
          (d) => d.dateTime.year == now.year && d.dateTime.month == now.month,
        )
        .toList();

    if (monthEntries.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            "这个月还没有记录哦~",
            style: TextStyle(fontFamily: 'LXGWWenKai'),
          ),
        ),
      );
      return;
    }

    setState(() {
      _shareEntries = monthEntries;
      _shareTitle = monthLabel;
      _isMonthShare = true;
      _isBookShare = false;
      _isCapturing = true;
    });

    await _executeCaptureAndShare(
      "diary_month_${now.millisecondsSinceEpoch}.png",
    );
  }
 
  void _exportAllAsBook() {
    final allDiaries = UserState().savedDiaries.value;
 
    if (allDiaries.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            "岛上空荡荡的，还没有日记记录可以导出哦~",
            style: TextStyle(fontFamily: 'LXGWWenKai'),
          ),
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }
 
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'ExportConfig',
      barrierColor: Colors.black.withOpacity(0.4),
      transitionDuration: const Duration(milliseconds: 300),
      pageBuilder: (context, anim1, anim2) {
        return ExportConfigDialog(allDiaries: allDiaries);
      },
      transitionBuilder: (context, animation, secondaryAnimation, child) {
        return SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0, 0.2),
            end: Offset.zero,
          ).animate(CurvedAnimation(parent: animation, curve: Curves.easeOutCubic)),
          child: FadeTransition(opacity: animation, child: child),
        );
      },
    );
  }

  Future<void> _executeCaptureAndShare(String fileName) async {
    // 等待一帧确保 RepaintBoundary 渲染
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
      await Share.shareXFiles([XFile(path)], text: '分享我在岛屿日记的点滴记录 ✨');
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
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Icon(
          icon,
          size: 24,
          color: isActive
              ? const Color(0xFFD4A373)
              : (isNight ? Colors.white54 : Colors.black.withOpacity(0.4)),
        ),
      ),
    );
  }
}

/// 拟物化纸张画家：绘制横格线与书脊阴影
class PaperBackgroundPainter extends CustomPainter {
  final bool isNight;
  PaperBackgroundPainter({this.isNight = false});

  @override
  void paint(Canvas canvas, Size size) {
    if (isNight) return; // 深色模式下保持纯净背景

    final paint = Paint()
      ..color = isNight
          ? const Color(0xFFD4A373).withOpacity(0.04)
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
          isNight
              ? Colors.black.withOpacity(0.5)
              : Colors.black.withOpacity(0.08),
          isNight
              ? Colors.black.withOpacity(0.15)
              : Colors.black.withOpacity(0.02),
          Colors.transparent,
          isNight
              ? Colors.black.withOpacity(0.15)
              : Colors.black.withOpacity(0.02),
          isNight
              ? Colors.black.withOpacity(0.5)
              : Colors.black.withOpacity(0.08),
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

/// 水平周历组件
class HorizontalWeekCalendar extends StatefulWidget {
  final DateTime? selectedDate;
  final Function(DateTime?) onDateSelected;
  final bool isNight;

  const HorizontalWeekCalendar({
    super.key,
    required this.selectedDate,
    required this.onDateSelected,
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
    // 自动滚动到最右侧（今天）
    _scrollController = ScrollController(initialScrollOffset: 1000.0);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    // 动态生成本月 1 号到今天的日期列表
    final firstDayOfMonth = DateTime(now.year, now.month, 1);
    final daysInMonthSoFar = now.difference(firstDayOfMonth).inDays + 1;
    final weekDates = List.generate(
      daysInMonthSoFar,
      (i) => firstDayOfMonth.add(Duration(days: i)),
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
              onTap: () => widget.onDateSelected(null),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    "全部",
                    style: TextStyle(
                      fontSize: 12,
                      color: widget.isNight
                          ? Colors.white30
                          : Colors.black.withOpacity(0.25),
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
                      border: Border.all(
                        color: widget.selectedDate == null
                            ? Colors.transparent
                            : (widget.isNight
                                  ? Colors.white10
                                  : Colors.black.withOpacity(0.05)),
                      ),
                    ),
                    child: Center(
                      child: Icon(
                        Icons.all_inclusive,
                        size: 20,
                        color: widget.selectedDate == null
                            ? Colors.white
                            : (widget.isNight ? Colors.white30 : Colors.black38),
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
            color: widget.isNight ? Colors.white10 : Colors.black.withOpacity(0.05),
          ),

          // 2. 可滚动的日期列表
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 12),
              controller: _scrollController,
              child: Row(
                children: weekDates.map((date) {
                  final isToday =
                      date.day == now.day &&
                      date.month == now.month &&
                      date.year == now.year;
                  final isSelected =
                      widget.selectedDate != null &&
                      date.day == widget.selectedDate!.day &&
                      date.month == widget.selectedDate!.month &&
                      date.year == widget.selectedDate!.year;
                  final dayName = weekDays[date.weekday % 7];

                  return GestureDetector(
                    onTap: () => widget.onDateSelected(date),
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
                              fontWeight: isToday
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                              color: isToday
                                  ? const Color(0xFFD4A373).withOpacity(0.8)
                                  : (widget.isNight
                                        ? Colors.white30
                                        : Colors.black.withOpacity(0.25)),
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
                                      fontWeight: isSelected
                                          ? FontWeight.bold
                                          : FontWeight.w500,
                                      color: isSelected
                                          ? Colors.white
                                          : (widget.isNight
                                                ? Colors.white70
                                                : Colors.black87),
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
