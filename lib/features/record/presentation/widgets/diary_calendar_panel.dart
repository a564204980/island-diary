import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:island_diary/core/state/user_state.dart';
import 'package:island_diary/features/record/domain/models/diary_entry.dart';
import 'package:island_diary/shared/widgets/mood_picker/config/mood_config.dart';
import 'package:island_diary/shared/widgets/diary_entry/utils/diary_utils.dart';
import 'package:island_diary/shared/widgets/diary_entry/utils/emoji_mapping.dart';
import 'package:island_diary/features/record/presentation/pages/diary_detail_page.dart';
import 'package:island_diary/features/record/presentation/widgets/calendar_day_cell.dart';
import 'package:island_diary/features/record/presentation/widgets/diary_search_panel.dart';

/// 日历网格面板：单月视图带记录列表版
class DiaryCalendarPanel extends StatefulWidget {
  final bool isNight;
  final Function(DateTime) onDateSelected;

  const DiaryCalendarPanel({
    super.key,
    required this.isNight,
    required this.onDateSelected,
    this.onShareMonth,
  });

  final Function(DateTime)? onShareMonth;

  @override
  State<DiaryCalendarPanel> createState() => _DiaryCalendarPanelState();
}

class _DiaryCalendarPanelState extends State<DiaryCalendarPanel> {
  final ScrollController _scrollController = ScrollController();
  late DateTime _focusedMonth;
  DateTime? _selectedDay;
  bool _isCollapsed = false;
  int? _collapsedWeekIndex;
  bool _isSortDescending = true;
  String _searchQuery = '';
  int? _searchMoodIndex;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _focusedMonth = DateTime(now.year, now.month, 1);
    _selectedDay = DateTime(now.year, now.month, now.day);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  // 获取中文星期
  String _getWeekdayChinese(int weekday) {
    const weekDays = ["周一", "周二", "周三", "周四", "周五", "周六", "周日"];
    if (weekday >= 1 && weekday <= 7) {
      return weekDays[weekday - 1];
    }
    return "";
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<String>(
      valueListenable: UserState().selectedIslandThemeId,
      builder: (context, themeId, _) {
        final isLego = themeId == 'lego';
        final fontFamily = isLego ? 'SweiFistLeg' : 'LXGWWenKai';

        return ValueListenableBuilder<List<DiaryEntry>>(
          valueListenable: UserState().savedDiaries,
          builder: (context, allDiaries, _) {
        final year = _focusedMonth.year;
        final month = _focusedMonth.month;

        final bool isCottonCandy = themeId == 'cotton_candy';
        final Color mainTextColor = widget.isNight
            ? Colors.white.withValues(alpha: 0.9)
            : (isCottonCandy ? const Color(0xFF4E3A46) : const Color(0xFF3B2E25));
        final Color subTextColor = widget.isNight
            ? Colors.white38
            : (isCottonCandy ? const Color(0xFF8D7A84) : const Color(0xFF7E7570));

        // 当前月份所有日记
        final monthDiaries = allDiaries.where((d) => d.dateTime.toLocal().year == year && d.dateTime.toLocal().month == month).toList();

        // 预加载当前月份所有日记的背景信纸图，防止卡片首次渲染时出现白屏闪烁
        for (var entry in monthDiaries) {
          String bgAsset = DiaryUtils.getPaperBackgroundPath(entry.paperStyle, widget.isNight);
          if (bgAsset.isEmpty) {
            bgAsset = widget.isNight
                ? 'assets/images/note/note_night_bg1.png'
                : 'assets/images/note/note_bg1.png';
          }
          precacheImage(AssetImage(bgAsset), context);
        }

        // 阴历/节假日数据计算
        final int daysInMonth = DateTime(year, month + 1, 0).day;
        final int firstDayWeekday = DateTime(year, month, 1).weekday;
        final int emptySlotsBefore = firstDayWeekday - 1;

        // 构造完整的 35 或 42 天网格日期，以便按周行折叠
        final List<DateTime> gridDays = [];
        final prevMonthEnd = DateTime(year, month, 0);
        for (int i = emptySlotsBefore - 1; i >= 0; i--) {
          gridDays.add(DateTime(year, month - 1, prevMonthEnd.day - i));
        }
        for (int day = 1; day <= daysInMonth; day++) {
          gridDays.add(DateTime(year, month, day));
        }
        int remaining = gridDays.length % 7;
        if (remaining > 0) {
          final int nextDaysCount = 7 - remaining;
          for (int i = 1; i <= nextDaysCount; i++) {
            gridDays.add(DateTime(year, month + 1, i));
          }
        }
        final List<List<DateTime>> weeks = [];
        for (int i = 0; i < gridDays.length; i += 7) {
          weeks.add(gridDays.sublist(i, i + 7));
        }

        int selectedWeekIndex = -1;
        if (_selectedDay != null) {
          for (int w = 0; w < weeks.length; w++) {
            if (weeks[w].any((d) => d.year == _selectedDay!.year && d.month == _selectedDay!.month && d.day == _selectedDay!.day)) {
              selectedWeekIndex = w;
              break;
            }
          }
        }
        if (selectedWeekIndex == -1) {
          final today = DateTime.now();
          for (int w = 0; w < weeks.length; w++) {
            if (weeks[w].any((d) => d.year == today.year && d.month == today.month && d.day == today.day)) {
              selectedWeekIndex = w;
              break;
            }
          }
        }
        if (selectedWeekIndex == -1) {
          selectedWeekIndex = 0;
        }

        final int activeWeekIndex = (_isCollapsed && _collapsedWeekIndex != null) ? _collapsedWeekIndex! : selectedWeekIndex;

        final bool isGlobalSearch = _selectedDay == null && (_searchQuery.isNotEmpty || _searchMoodIndex != null);

        // 当前选中的日记列表（支持选中具体某天，或进行全局搜索）
        final selectedDayDiaries = (isGlobalSearch || _selectedDay != null)
            ? allDiaries.where((d) {
                final local = d.dateTime.toLocal();
                
                if (!isGlobalSearch) {
                  bool matchDate = local.year == _selectedDay!.year &&
                      local.month == _selectedDay!.month &&
                      local.day == _selectedDay!.day;
                  if (!matchDate) return false;
                }

                if (_searchMoodIndex != null && d.moodIndex != _searchMoodIndex) {
                  return false;
                }

                if (_searchQuery.isNotEmpty) {
                  return d.content.contains(_searchQuery) ||
                         (d.title?.contains(_searchQuery) ?? false) ||
                         (d.tag?.contains(_searchQuery) ?? false);
                }

                return true;
              }).toList()
            : <DiaryEntry>[];

        // 将置顶的日记排在前面，未置顶的按时间排序
        selectedDayDiaries.sort((a, b) {
          if (a.isPinned && !b.isPinned) return -1;
          if (!a.isPinned && b.isPinned) return 1;
          return _isSortDescending 
              ? b.dateTime.compareTo(a.dateTime)
              : a.dateTime.compareTo(b.dateTime);
        });

        return Column(
          children: [
            // 固定在顶部的日记头部模块
            GestureDetector(
              onVerticalDragUpdate: (details) {
                if (details.primaryDelta != null && details.primaryDelta! > 8) {
                  if (_isCollapsed) {
                    setState(() {
                      _isCollapsed = false;
                    });
                  }
                } else if (details.primaryDelta != null && details.primaryDelta! < -8) {
                  if (!_isCollapsed && _selectedDay != null) {
                    setState(() {
                      _isCollapsed = true;
                      _collapsedWeekIndex = selectedWeekIndex;
                    });
                  }
                }
              },
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 8, 24, 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                  // 1. 月份切换与功能按钮栏
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          IconButton(
                            icon: Icon(
                              Icons.chevron_left_rounded,
                              size: 18,
                              color: mainTextColor.withValues(alpha: 0.8),
                            ),
                            style: IconButton.styleFrom(
                              backgroundColor: subTextColor.withValues(alpha: 0.1),
                              shape: const CircleBorder(),
                              padding: EdgeInsets.zero,
                              minimumSize: const Size(30, 30),
                              fixedSize: const Size(30, 30),
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            ),
                            onPressed: () {
                              setState(() {
                                _focusedMonth = DateTime(_focusedMonth.year, _focusedMonth.month - 1, 1);
                                _selectedDay = null;
                                _isCollapsed = false;
                                _collapsedWeekIndex = null;
                              });
                            },
                          ),
                          const SizedBox(width: 12),
                          Text(
                            "${_focusedMonth.year}.${_focusedMonth.month.toString().padLeft(2, '0')}",
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              fontFamily: fontFamily,
                              color: mainTextColor,
                            ),
                          ),
                          const SizedBox(width: 12),
                          IconButton(
                            icon: Icon(
                              Icons.chevron_right_rounded,
                              size: 18,
                              color: mainTextColor.withValues(alpha: 0.8),
                            ),
                            style: IconButton.styleFrom(
                              backgroundColor: subTextColor.withValues(alpha: 0.1),
                              shape: const CircleBorder(),
                              padding: EdgeInsets.zero,
                              minimumSize: const Size(30, 30),
                              fixedSize: const Size(30, 30),
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            ),
                            onPressed: () {
                              setState(() {
                                _focusedMonth = DateTime(_focusedMonth.year, _focusedMonth.month + 1, 1);
                                _selectedDay = null;
                                _isCollapsed = false;
                                _collapsedWeekIndex = null;
                              });
                            },
                          ),
                        ],
                      ),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: Icon(
                              Icons.search_rounded,
                              size: 19,
                              color: subTextColor,
                            ),
                            style: IconButton.styleFrom(
                              backgroundColor: subTextColor.withValues(alpha: 0.1),
                              shape: const CircleBorder(),
                              padding: EdgeInsets.zero,
                              minimumSize: const Size(32, 32),
                              fixedSize: const Size(32, 32),
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            ),
                            onPressed: () {
                              showModalBottomSheet(
                                context: context,
                                isScrollControlled: true,
                                backgroundColor: Colors.transparent,
                                builder: (context) => DiarySearchPanel(
                                  isNight: widget.isNight,
                                  onSearch: (query, moodIndex) {
                                    setState(() {
                                      _searchQuery = query;
                                      _searchMoodIndex = moodIndex;
                                      if (query.isNotEmpty || moodIndex != null) {
                                        try {
                                          final firstMatch = allDiaries.firstWhere((d) {
                                            if (moodIndex != null && d.moodIndex != moodIndex) return false;
                                            if (query.isNotEmpty) {
                                              return d.content.contains(query) ||
                                                     (d.title?.contains(query) ?? false) ||
                                                     (d.tag?.contains(query) ?? false);
                                            }
                                            return true;
                                          });
                                          _selectedDay = firstMatch.dateTime.toLocal();
                                          _focusedMonth = DateTime(_selectedDay!.year, _selectedDay!.month, 1);
                                        } catch (_) {
                                          _selectedDay = null;
                                        }
                                      } else {
                                        final now = DateTime.now();
                                        _selectedDay = DateTime(now.year, now.month, now.day);
                                        _focusedMonth = DateTime(now.year, now.month, 1);
                                      }
                                    });
                                  },
                                  onClear: () {
                                    setState(() {
                                      _searchQuery = '';
                                      _searchMoodIndex = null;
                                    });
                                  },
                                ),
                              );
                            },
                          ),
                          if (widget.onShareMonth != null && monthDiaries.isNotEmpty) ...[
                            const SizedBox(width: 8),
                            IconButton(
                              icon: Icon(
                                  Icons.ios_share_rounded,
                                  size: 18,
                                  color: subTextColor,
                                ),
                                style: IconButton.styleFrom(
                                  backgroundColor: subTextColor.withValues(alpha: 0.1),
                                  shape: const CircleBorder(),
                                  padding: EdgeInsets.zero,
                                  minimumSize: const Size(32, 32),
                                  fixedSize: const Size(32, 32),
                                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                ),
                                onPressed: () => widget.onShareMonth!(_focusedMonth),
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                  const SizedBox(height: 12),
                  // 2. 星期标头
                  _buildWeekHeader(widget.isNight, fontFamily),
                  const SizedBox(height: 12),
                  // 3. 日历网格
                  AnimatedSize(
                    duration: const Duration(milliseconds: 250),
                    curve: Curves.easeOutCubic,
                    child: _isCollapsed
                        ? SizedBox(
                            height: 62,
                            child: PageView.builder(
                              key: ValueKey('pageview_${_focusedMonth.year}_${_focusedMonth.month}'),
                              controller: PageController(initialPage: activeWeekIndex),
                              onPageChanged: (index) {
                                setState(() {
                                  _collapsedWeekIndex = index;
                                });
                              },
                              itemCount: weeks.length,
                              itemBuilder: (context, wIndex) {
                                final week = weeks[wIndex];
                                return Padding(
                                  padding: const EdgeInsets.only(top: 4, bottom: 6),
                                  child: SizedBox(
                                    height: 52,
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      crossAxisAlignment: CrossAxisAlignment.stretch,
                                      children: List.generate(7, (dIndex) {
                                        final cellDate = week[dIndex];
                                        final bool isCurrentMonth = cellDate.month == month && cellDate.year == year;

                                        final entries = allDiaries.where((d) {
                                          final local = d.dateTime.toLocal();
                                          return local.year == cellDate.year &&
                                              local.month == cellDate.month &&
                                              local.day == cellDate.day;
                                        }).toList();

                                        final bool isToday = DateTime.now().year == cellDate.year &&
                                            DateTime.now().month == cellDate.month &&
                                            DateTime.now().day == cellDate.day;
                                        final bool isSelected = _selectedDay != null &&
                                            _selectedDay!.year == cellDate.year &&
                                            _selectedDay!.month == cellDate.month &&
                                            _selectedDay!.day == cellDate.day;

                                        return Expanded(
                                          child: Padding(
                                            padding: const EdgeInsets.symmetric(horizontal: 5),
                                            child: !isCurrentMonth
                                                ? const SizedBox()
                                                : CalendarDayCell(
                                                    date: cellDate,
                                                    entries: entries,
                                                    isToday: isToday,
                                                    isSelected: isSelected,
                                                    isNight: widget.isNight,
                                                    onTap: () {
                                                      setState(() {
                                                        _selectedDay = cellDate;
                                                        _collapsedWeekIndex = wIndex;
                                                      });
                                                    },
                                                  ),
                                          ),
                                        );
                                      }),
                                    ),
                                  ),
                                );
                              },
                            ),
                          )
                        : Column(
                            mainAxisSize: MainAxisSize.min,
                            children: List.generate(weeks.length, (wIndex) {
                              final week = weeks[wIndex];
                              final bool isTargetWeek = wIndex == selectedWeekIndex;
                              final bool shouldShow = !_isCollapsed || isTargetWeek;

                              return ClipRect(
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 250),
                                  curve: Curves.easeOutCubic,
                                  height: shouldShow ? 62 : 0,
                                  child: SingleChildScrollView(
                                    physics: const NeverScrollableScrollPhysics(),
                                    clipBehavior: Clip.none,
                                    child: Padding(
                                      padding: const EdgeInsets.only(top: 4, bottom: 6),
                                      child: SizedBox(
                                        height: 52,
                                        child: Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          crossAxisAlignment: CrossAxisAlignment.stretch,
                                          children: List.generate(7, (dIndex) {
                                            final cellDate = week[dIndex];
                                            final bool isCurrentMonth = cellDate.month == month && cellDate.year == year;

                                            final entries = allDiaries.where((d) {
                                              final local = d.dateTime.toLocal();
                                              return local.year == cellDate.year &&
                                                  local.month == cellDate.month &&
                                                  local.day == cellDate.day;
                                            }).toList();

                                            final bool isToday = DateTime.now().year == cellDate.year &&
                                                DateTime.now().month == cellDate.month &&
                                                DateTime.now().day == cellDate.day;
                                            final bool isSelected = _selectedDay != null &&
                                                _selectedDay!.year == cellDate.year &&
                                                _selectedDay!.month == cellDate.month &&
                                                _selectedDay!.day == cellDate.day;

                                            return Expanded(
                                              child: Padding(
                                                padding: const EdgeInsets.symmetric(horizontal: 5),
                                                child: !isCurrentMonth
                                                    ? const SizedBox()
                                                    : CalendarDayCell(
                                                        date: cellDate,
                                                        entries: entries,
                                                        isToday: isToday,
                                                        isSelected: isSelected,
                                                        isNight: widget.isNight,
                                                        onTap: () {
                                                          setState(() {
                                                            _selectedDay = cellDate;
                                                            _collapsedWeekIndex = wIndex;
                                                          });
                                                        },
                                                      ),
                                              ),
                                            );
                                          }),
                                        ),
                                      ),
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
            Expanded(
              child: NotificationListener<UserScrollNotification>(
                onNotification: (notification) {
                  if (notification.direction == ScrollDirection.forward) {
                    if (_isCollapsed) {
                      setState(() {
                        _isCollapsed = false;
                      });
                    }
                  } else if (notification.direction == ScrollDirection.reverse) {
                    if (!_isCollapsed && _selectedDay != null) {
                      setState(() {
                        _isCollapsed = true;
                      });
                    }
                  }
                  return false;
                },
                child: SingleChildScrollView(
                  controller: _scrollController,
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(24, 16, 24, 120),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 4. 月份记录统计信息
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          "$month月记录",
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            fontFamily: fontFamily,
                            color: mainTextColor,
                          ),
                        ),
                        Text(
                          "${monthDiaries.length}条",
                          style: TextStyle(
                            fontSize: 14,
                            color: subTextColor,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 16),

                    // 5. 选中日期的详细日记记录，或搜索结果
                    if (_selectedDay != null || isGlobalSearch)
                      Column(
                        key: ValueKey(_selectedDay ?? 'search'),
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                isGlobalSearch
                                    ? "搜索结果"
                                    : "${_selectedDay!.day} ${_getWeekdayChinese(_selectedDay!.weekday)}",
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  fontFamily: fontFamily,
                                  color: mainTextColor,
                                ),
                              ),
                              Text(
                                "${selectedDayDiaries.length}条",
                                style: TextStyle(
                                  fontSize: 14,
                                  color: subTextColor,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          if (selectedDayDiaries.isEmpty)
                            Padding(
                              padding: const EdgeInsets.symmetric(vertical: 24),
                              child: Center(
                                child: Text(
                                  isGlobalSearch ? "没有找到符合条件的记录哦~" : "这一天没有记录日记哦~",
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: widget.isNight ? Colors.white24 : Colors.black26,
                                    fontFamily: fontFamily,
                                  ),
                                ),
                              ),
                            )
                          else
                            ...List.generate(selectedDayDiaries.length, (index) {
                              return _buildDiaryDetailCard(
                                selectedDayDiaries[index],
                                widget.isNight,
                                fontFamily,
                                isFirst: index == 0,
                                isLast: index == selectedDayDiaries.length - 1,
                              );
                            }),
                        ],
                      ).animate(key: ValueKey(_selectedDay ?? 'search')).fadeIn(duration: 220.ms).slideY(begin: 0.08, end: 0, curve: Curves.easeOutCubic),
                  ],
            ),
          ),
        ),
      ),
    ],
  );
    },
  );
},
);
}

  Widget _buildWeekHeader(bool isNight, String fontFamily) {
    final themeId = UserState().selectedIslandThemeId.value;
    final bool isCottonCandy = themeId == 'cotton_candy';
    final Color subTextColor = isNight
        ? Colors.white38
        : (isCottonCandy ? const Color(0xFF8D7A84) : const Color(0xFF7E7570));

    final List<String> weekDays = ["周一", "周二", "周三", "周四", "周五", "周六", "周日"];
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: weekDays
          .map(
            (d) => Expanded(
              child: Center(
                child: Text(
                  d,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: subTextColor.withValues(alpha: 0.7),
                    fontFamily: fontFamily,
                  ),
                ),
              ),
            ),
          )
          .toList(),
    );
  }

  Widget _buildTimelineNode(bool isNight, String themeId) {
    Color color;
    bool isSquare = false;

    if (themeId == 'lego') {
      // 乐高模式：使用代表积木的圆角小方块，颜色使用活力黄
      color = isNight ? const Color(0xFFFFD54F) : const Color(0xFFFFC107);
      isSquare = true;
    } else if (themeId == 'cotton_candy') {
      // 棉花糖：粉嫩圆点
      color = isNight ? const Color(0xFFCE93D8) : const Color(0xFFF48FB1);
    } else {
      // 默认：高级金棕
      color = isNight ? const Color(0xFFE1AF78).withValues(alpha: 0.8) : const Color(0xFFD4A373);
    }

    // 边框颜色与当前背景色一致，营造出“切断”时间轴线的现代视觉效果
    final borderColor = isNight ? const Color(0xFF2C323A) : Colors.white;

    return Container(
      width: 14,
      height: 14,
      decoration: BoxDecoration(
        color: color,
        shape: isSquare ? BoxShape.rectangle : BoxShape.circle,
        borderRadius: isSquare ? BorderRadius.circular(4) : null,
        border: Border.all(
          color: borderColor,
          width: 2.5,
        ),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.5),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
    );
  }

  Widget _buildMoodBadge(DiaryEntry entry, {bool isNight = false}) {
    final parsed = ParsedTags.parse(entry.tag, entry.moodIndex);
    final moodIdx = entry.moodIndex.clamp(0, kMoods.length - 1);
    final mood = kMoods[moodIdx];
    final String moodLabel = parsed.customMood ?? mood.label;
    final String iconPath = (entry.moodIndex >= 0 && entry.moodIndex <= 23)
        ? 'assets/icons/custom${entry.moodIndex + 1}.png'
        : (mood.iconPath ?? 'assets/icons/happy.png');

    final bool hasCustomIcon = parsed.customMoodIconPath != null && parsed.customMoodIconPath!.isNotEmpty;

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        // 1. 心情标签 (表情图片 + 心情文字)
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: isNight
                ? Colors.white.withValues(alpha: 0.08)
                : Colors.black.withValues(alpha: 0.04),
            borderRadius: BorderRadius.circular(100),
            border: Border.all(
              color: isNight
                  ? Colors.white.withValues(alpha: 0.15)
                  : Colors.black.withValues(alpha: 0.08),
              width: 0.8,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              hasCustomIcon
                  ? Image.file(
                      File(parsed.customMoodIconPath!),
                      width: 14,
                      height: 14,
                      errorBuilder: (c, e, s) => Icon(
                        Icons.mood,
                        size: 14,
                        color: isNight ? Colors.white54 : const Color(0xFF5C5C5C),
                      ),
                    )
                  : Image.asset(
                      iconPath,
                      width: 14,
                      height: 14,
                      errorBuilder: (c, e, s) => Icon(
                        Icons.mood,
                        size: 14,
                        color: isNight ? Colors.white54 : const Color(0xFF5C5C5C),
                      ),
                    ),
              const SizedBox(width: 4),
              Text(
                moodLabel,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: isNight ? Colors.white.withValues(alpha: 0.75) : const Color(0xFF5C5C5C),
                  fontFamily: 'LXGWWenKai',
                ),
              ),
            ],
          ),
        ),

        // 3. 天气标签 (如果有)
        if (entry.weather != null)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: isNight
                  ? Colors.white.withValues(alpha: 0.08)
                  : Colors.black.withValues(alpha: 0.04),
              borderRadius: BorderRadius.circular(100),
              border: Border.all(
                color: isNight
                    ? Colors.white.withValues(alpha: 0.15)
                    : Colors.black.withValues(alpha: 0.08),
                width: 0.8,
              ),
            ),
            child: Text(
              "${entry.weather} ${entry.temp ?? ''}",
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: isNight ? Colors.white.withValues(alpha: 0.75) : const Color(0xFF5C5C5C),
                fontFamily: 'LXGWWenKai',
              ),
            ),
          ),

        // 4. 地点标签 (如果有)
        if (entry.location != null)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: isNight
                  ? Colors.white.withValues(alpha: 0.08)
                  : Colors.black.withValues(alpha: 0.04),
              borderRadius: BorderRadius.circular(100),
              border: Border.all(
                color: isNight
                    ? Colors.white.withValues(alpha: 0.15)
                    : Colors.black.withValues(alpha: 0.08),
                width: 0.8,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.location_on_outlined,
                  size: 10,
                  color: isNight ? Colors.white54 : const Color(0xFF5C5C5C),
                ),
                const SizedBox(width: 2),
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 160),
                  child: Text(
                    entry.location!,
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: isNight ? Colors.white.withValues(alpha: 0.75) : const Color(0xFF5C5C5C),
                      fontFamily: 'LXGWWenKai',
                    ),
                  ),
                ),
              ],
            ),
          ),

        // 5. 话题标签 (如果有)
        ...parsed.tags.map((singleTag) => Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: isNight
                    ? Colors.white.withValues(alpha: 0.08)
                    : Colors.black.withValues(alpha: 0.04),
                borderRadius: BorderRadius.circular(100),
                border: Border.all(
                  color: isNight
                      ? Colors.white.withValues(alpha: 0.15)
                      : Colors.black.withValues(alpha: 0.08),
                  width: 0.8,
                ),
              ),
              child: Text(
                '#$singleTag',
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: isNight ? Colors.white.withValues(alpha: 0.75) : const Color(0xFF5C5C5C),
                  fontFamily: 'LXGWWenKai',
                ),
              ),
            )),
      ],
    );
  }

  Widget _buildDiaryDetailCard(DiaryEntry entry, bool isNight, String fontFamily, {required bool isFirst, required bool isLast}) {
    final themeId = UserState().selectedIslandThemeId.value;
    final bool isCottonCandy = themeId == 'cotton_candy';

    final Color mainTextColor = isNight
        ? Colors.white.withValues(alpha: 0.9)
        : (isCottonCandy ? const Color(0xFF4E3A46) : const Color(0xFF3B2E25));

    final Color subTextColor = isNight
        ? Colors.white38
        : (isCottonCandy ? const Color(0xFF8D7A84) : const Color(0xFF7E7570));

    final images = entry.blocks.where((b) => b['type'] == 'image').toList();

    // 日记内容提取逻辑
    final String plainContent = DiaryUtils.getFilteredContent(entry.content).trim();

    final timeStr = _selectedDay == null 
        ? "${entry.dateTime.toLocal().month}月${entry.dateTime.toLocal().day}日 ${entry.dateTime.toLocal().hour.toString().padLeft(2, '0')}:${entry.dateTime.toLocal().minute.toString().padLeft(2, '0')}"
        : "${entry.dateTime.toLocal().hour.toString().padLeft(2, '0')}:${entry.dateTime.toLocal().minute.toString().padLeft(2, '0')}";

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => DiaryDetailPage(
              entry: entry,
              isNight: isNight,
            ),
          ),
        );
      },
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 左侧时间轴
            SizedBox(
              width: 36,
              child: Stack(
                alignment: Alignment.topCenter,
                children: [
                  // 竖线
                  Align(
                    alignment: Alignment.center,
                    child: Container(
                      width: 1.5,
                      color: isNight ? Colors.white10 : Colors.black.withValues(alpha: 0.08),
                      margin: EdgeInsets.only(
                        top: isFirst ? 22 : 0,
                        bottom: isLast ? 22 : 0,
                      ),
                    ),
                  ),
                  // 时间轴节点（圆形背景 + 心情图标）
                  Positioned(
                    top: 14,
                    child: _buildTimelineNode(isNight, themeId),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            // 右侧内容区
            Expanded(
              child: Container(
                margin: const EdgeInsets.symmetric(vertical: 4),
                padding: const EdgeInsets.only(bottom: 16, right: 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 时间 + 心情标签
                    Row(
                      children: [
                        Text(
                          timeStr,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: mainTextColor,
                            fontFamily: fontFamily,
                          ),
                        ),
                        if (entry.isPinned) ...[
                          const SizedBox(width: 6),
                          Icon(
                            Icons.push_pin_rounded,
                            size: 14,
                            color: const Color(0xFFF9A826), // 暖橙色作为置顶强调色
                          ),
                        ],
                        const Spacer(),
                        PopupMenuButton<String>(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          color: isNight ? const Color(0xFF2C323A) : const Color(0xFFF6F7F9),
                          elevation: 6,
                          offset: const Offset(0, 24),
                          child: Container(
                            padding: const EdgeInsets.only(left: 12, right: 4, top: 4, bottom: 4),
                            color: Colors.transparent, // expand hit area slightly
                            child: Icon(
                              Icons.more_horiz_rounded,
                              size: 16,
                              color: subTextColor.withValues(alpha: 0.7),
                            ),
                          ),
                          itemBuilder: (context) => [
                            PopupMenuItem(
                              value: 'pin',
                              height: 44,
                              child: Text(
                                entry.isPinned ? '取消置顶' : '置顶',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: mainTextColor,
                                  fontFamily: fontFamily,
                                ),
                              ),
                            ),
                            _CustomMenuDivider(dividerColor: subTextColor.withValues(alpha: 0.2)),
                            PopupMenuItem(
                              value: 'sort',
                              height: 44,
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    '按时间的排序',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: mainTextColor,
                                      fontFamily: fontFamily,
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Icon(
                                    _isSortDescending ? Icons.arrow_downward_rounded : Icons.arrow_upward_rounded,
                                    size: 16,
                                    color: mainTextColor,
                                  ),
                                ],
                              ),
                            ),
                          ],
                          onSelected: (value) {
                            if (value == 'pin') {
                              UserState().toggleDiaryPin(entry.id);
                            } else if (value == 'sort') {
                              setState(() {
                                _isSortDescending = !_isSortDescending;
                              });
                            } else {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('开发中：$value 功能'),
                                  duration: const Duration(seconds: 1),
                                ),
                              );
                            }
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    // 日记内容文字
                    Builder(builder: (context) {
                      final textStyle = TextStyle(
                        fontSize: 14,
                        color: mainTextColor.withValues(alpha: 0.85),
                        fontFamily: fontFamily,
                        height: 1.4,
                      );
                      if (plainContent.isEmpty) {
                        return Text("无文字内容", style: textStyle);
                      }
                      final spans = EmojiMapping.parseText(plainContent).map((chunk) {
                        if (chunk.isEmoji) {
                          return WidgetSpan(
                            alignment: PlaceholderAlignment.middle,
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 1),
                              child: Image.asset(chunk.emojiPath!, width: 16, height: 16),
                            ),
                          );
                        }
                        return TextSpan(text: chunk.text, style: textStyle);
                      }).toList();
                      return RichText(
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                        text: TextSpan(children: spans),
                      );
                    }),
                    // 如果有图片，展示图片预览
                    if (images.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: List.generate(
                          images.length > 5 ? 5 : images.length,
                          (index) {
                            final img = images[index];
                            final bool isLast = index == 4;
                            final int extraCount = images.length - 5;
                            
                            Widget imageWidget = ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: DiaryUtils.buildImage(
                                img['path'],
                                width: 56,
                                height: 56,
                                fit: BoxFit.cover,
                              ),
                            );

                            if (isLast && extraCount > 0) {
                              return Stack(
                                children: [
                                  imageWidget,
                                  Positioned.fill(
                                    child: Container(
                                      decoration: BoxDecoration(
                                        color: Colors.black.withValues(alpha: 0.5),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      alignment: Alignment.center,
                                      child: Text(
                                        '+$extraCount',
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 18,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              );
                            }
                            return imageWidget;
                          },
                        ),
                      ),
                    ],
                    const SizedBox(height: 10),
                    // 底部：心情标签及其他标签（如天气、话题）
                    _buildMoodBadge(entry, isNight: isNight),
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

// 带有左右内边距的自定义分割线，还原精美的 iOS UI
class _CustomMenuDivider extends PopupMenuEntry<Never> {
  final Color dividerColor;
  const _CustomMenuDivider({required this.dividerColor});

  @override
  double get height => 1.0;

  @override
  bool represents(void value) => false;

  @override
  State<_CustomMenuDivider> createState() => _CustomMenuDividerState();
}

class _CustomMenuDividerState extends State<_CustomMenuDivider> {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Divider(
        height: 1.0,
        thickness: 0.5,
        color: widget.dividerColor,
      ),
    );
  }
}
