import 'package:flutter/material.dart';
import 'package:island_diary/core/state/user_state.dart';
import 'package:island_diary/features/record/domain/models/diary_entry.dart';
import 'package:island_diary/shared/widgets/mood_picker/config/mood_config.dart';
import 'package:island_diary/shared/widgets/diary_entry/utils/diary_utils.dart';

/// 日历格网面板：显示单月日记分布情况，支持滑动切换月份
class DiaryCalendarPanel extends StatefulWidget {
  final bool isNight;
  final Function(DateTime) onDateSelected;

  const DiaryCalendarPanel({
    super.key,
    required this.isNight,
    required this.onDateSelected,
  });

  @override
  State<DiaryCalendarPanel> createState() => _DiaryCalendarPanelState();
}

class _DiaryCalendarPanelState extends State<DiaryCalendarPanel> {
  late PageController _pageController;
  late DateTime _initialMonth;
  late int _currentPage;
  final int _basePage = 500; // 基准页

  final List<String> _weekDays = ["一", "二", "三", "四", "五", "六", "日"];

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _initialMonth = DateTime(now.year, now.month, 1);
    _currentPage = _basePage;
    _pageController = PageController(initialPage: _basePage);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  DateTime _getMonthForPage(int page) {
    return DateTime(_initialMonth.year, _initialMonth.month + (page - _basePage), 1);
  }

  void _nextMonth() {
    _pageController.nextPage(duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
  }

  void _prevMonth() {
    _pageController.previousPage(duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
  }

  @override
  Widget build(BuildContext context) {
    final currentViewMonth = _getMonthForPage(_currentPage);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          _buildHeader(currentViewMonth),
          const SizedBox(height: 12),
          _buildWeekRow(),
          const SizedBox(height: 4),
          Expanded(
            child: PageView.builder(
              controller: _pageController,
              onPageChanged: (page) {
                setState(() {
                  _currentPage = page;
                });
              },
              itemBuilder: (context, index) {
                return _buildCalendarGrid(_getMonthForPage(index));
              },
            ),
          ),
          _buildFooterSummary(currentViewMonth),
        ],
      ),
    );
  }

  Widget _buildHeader(DateTime month) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            onPressed: _prevMonth,
            iconSize: 22,
            icon: Icon(
              Icons.arrow_back_ios_new_rounded,
              color: widget.isNight ? Colors.white54 : Colors.black45,
            ),
          ),
          Text(
            "${month.year}年${month.month}月",
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w900,
              fontFamily: 'LXGWWenKai',
              color: widget.isNight ? Colors.white.withOpacity(0.9) : const Color(0xFF2C2E30),
            ),
          ),
          IconButton(
            onPressed: _nextMonth,
            iconSize: 22,
            icon: Icon(
              Icons.arrow_forward_ios_rounded,
              color: widget.isNight ? Colors.white54 : Colors.black45,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWeekRow() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: _weekDays.map((d) => SizedBox(
          width: 40,
          child: Center(
            child: Text(
              d,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w800,
                color: widget.isNight ? Colors.white38 : Colors.black.withOpacity(0.2), // 稍微拉开与数字的层次
                fontFamily: 'LXGWWenKai',
              ),
            ),
          ),
        )).toList(),
      ),
    );
  }

  Widget _buildCalendarGrid(DateTime month) {
    final int daysInMonth = DateTime(month.year, month.month + 1, 0).day;
    final int firstDayWeekday = month.weekday;
    final int emptySlotsBefore = firstDayWeekday - 1;

    return ValueListenableBuilder<List<DiaryEntry>>(
      valueListenable: UserState().savedDiaries,
      builder: (context, allDiaries, _) {
        final Map<String, List<DiaryEntry>> dayMap = {};
        for (var entry in allDiaries) {
          final key = "${entry.dateTime.year}-${entry.dateTime.month}-${entry.dateTime.day}";
          dayMap.putIfAbsent(key, () => []).add(entry);
        }

        return GridView.builder(
          padding: const EdgeInsets.only(top: 12),
          physics: const BouncingScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 7,
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 0.85,
          ),
          itemCount: daysInMonth + emptySlotsBefore,
          itemBuilder: (context, index) {
            if (index < emptySlotsBefore) return const SizedBox.shrink();

            final int day = index - emptySlotsBefore + 1;
            final dateKey = "${month.year}-${month.month}-$day";
            final entries = dayMap[dateKey];
            final bool isToday = DateTime.now().year == month.year &&
                DateTime.now().month == month.month &&
                DateTime.now().day == day;

            return _CalendarDayCell(
              day: day,
              entries: entries,
              isToday: isToday,
              isNight: widget.isNight,
              onTap: () => widget.onDateSelected(DateTime(month.year, month.month, day)),
            );
          },
        );
      },
    );
  }

  Widget _buildFooterSummary(DateTime month) {
    return ValueListenableBuilder<List<DiaryEntry>>(
      valueListenable: UserState().savedDiaries,
      builder: (context, allDiaries, _) {
        final monthDiaries = allDiaries.where((e) => 
          e.dateTime.year == month.year && e.dateTime.month == month.month
        ).toList();
        
        final activeDays = monthDiaries.map((e) => "${e.dateTime.year}-${e.dateTime.month}-${e.dateTime.day}").toSet().length;
        int totalWords = 0;
        for (var e in monthDiaries) {
          totalWords += e.content.length;
        }

        return Padding(
          padding: const EdgeInsets.only(bottom: 24, top: 12),
          child: Text(
            "$activeDays天 | ${monthDiaries.length}篇 | $totalWords字",
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: widget.isNight ? Colors.white24 : Colors.black12,
              fontFamily: 'LXGWWenKai',
            ),
          ),
        );
      },
    );
  }
}

class _CalendarDayCell extends StatelessWidget {
  final int day;
  final List<DiaryEntry>? entries;
  final bool isToday;
  final bool isNight;
  final VoidCallback onTap;

  const _CalendarDayCell({
    required this.day,
    this.entries,
    required this.isToday,
    required this.isNight,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final bool hasEntry = entries != null && entries!.isNotEmpty;
    String? thumbPath;
    int? moodIdx;

    if (hasEntry) {
      final latest = entries!.last;
      for (var block in latest.blocks) {
        if (block['type'] == 'image') {
          thumbPath = block['path'];
          break;
        }
      }
      if (thumbPath == null) {
        moodIdx = latest.moodIndex;
      }
    }

    // 文字样式：如果下面有图片/心情，则使用白色文字加阴影
    final TextStyle dayStyle = TextStyle(
      fontSize: 18,
      fontWeight: FontWeight.w900,
      fontFamily: 'LXGWWenKai',
      color: hasEntry 
          ? Colors.white 
          : (isNight ? Colors.white.withOpacity(0.9) : const Color(0xFF2C2E30)),
      shadows: hasEntry ? [
        const Shadow(
          blurRadius: 4,
          color: Colors.black54,
          offset: Offset(0, 1),
        )
      ] : null,
    );

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          color: isToday 
              ? const Color(0xFFD4A373).withOpacity(isNight ? 0.3 : 0.1)
              : (hasEntry 
                  ? (isNight ? const Color(0xFF383B3E) : Colors.white)
                  : (isNight ? Colors.white.withOpacity(0.02) : Colors.black.withOpacity(0.01))),
          borderRadius: BorderRadius.circular(10),
          border: isToday 
              ? Border.all(color: const Color(0xFFD4A373), width: 2.2)
              : (hasEntry 
                  ? Border.all(color: isNight ? Colors.white12 : Colors.black.withOpacity(0.1), width: 1.0)
                  : Border.all(color: isNight ? Colors.white.withOpacity(0.04) : Colors.black.withOpacity(0.03), width: 0.5)),
          boxShadow: hasEntry ? [
            BoxShadow(
              color: Colors.black.withOpacity(isNight ? 0.5 : 0.1),
              blurRadius: 6,
              offset: const Offset(0, 4),
            )
          ] : null,
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          alignment: Alignment.center,
          children: [
            // 底层：内容图片
            if (thumbPath != null)
              Positioned.fill(
                child: DiaryUtils.buildImage(
                  thumbPath,
                  borderRadius: BorderRadius.circular(0), // 内部填满
                ),
              ),
            
            // 底层：心情图标 (稍微大一点)
            if (thumbPath == null && moodIdx != null)
              Center(
                child: Padding(
                  padding: const EdgeInsets.all(4.0),
                  child: Image.asset(
                    kMoods[moodIdx.clamp(0, kMoods.length - 1)].iconPath!,
                    width: 32,
                    height: 32,
                    opacity: const AlwaysStoppedAnimation(0.8),
                  ),
                ),
              ),

            // 如果有图片或心情，加一层极淡的阴影层确保数字始终清晰
            if (hasEntry)
              Positioned.fill(
                child: Container(
                  color: Colors.black.withOpacity(0.15),
                ),
              ),

            // 顶层：日期数字
            Center(
              child: Text("$day", style: dayStyle),
            ),

            // 多条目标识 (移至右下角以免干扰视觉中心)
            if (hasEntry && entries!.length > 1)
              Positioned(
                right: 4,
                bottom: 4,
                child: Container(
                  width: 6,
                  height: 6,
                  decoration: const BoxDecoration(
                    color: Color(0xFFD4A373),
                    shape: BoxShape.circle,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
