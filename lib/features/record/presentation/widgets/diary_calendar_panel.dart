import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:lunar/lunar.dart';
import 'package:island_diary/core/state/user_state.dart';
import 'package:island_diary/features/record/domain/models/diary_entry.dart';
import 'package:island_diary/shared/widgets/mood_picker/config/mood_config.dart';
import 'package:island_diary/shared/widgets/diary_entry/utils/diary_utils.dart';
import 'package:island_diary/shared/widgets/diary_entry/utils/emoji_mapping.dart';
import 'package:island_diary/features/record/presentation/pages/diary_detail_page.dart';

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

        // 当前选中的日记列表（直接从所有日记中过滤，支持跨月选择）
        final selectedDayDiaries = _selectedDay != null
            ? allDiaries.where((d) {
                final local = d.dateTime.toLocal();
                return local.year == _selectedDay!.year &&
                    local.month == _selectedDay!.month &&
                    local.day == _selectedDay!.day;
              }).toList()
            : <DiaryEntry>[];

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
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('开发中：根据标签或分类筛选日历显示的功能'),
                                  duration: Duration(seconds: 2),
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
                                                : _CalendarDayCell(
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
                                                    : _CalendarDayCell(
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

                    // 5. 选中日期的详细日记记录
                    if (_selectedDay != null)
                      Column(
                        key: ValueKey(_selectedDay),
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                "${_selectedDay!.day} ${_getWeekdayChinese(_selectedDay!.weekday)}",
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
                                  "这一天没有记录日记哦~",
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
                      ).animate(key: ValueKey(_selectedDay)).fadeIn(duration: 220.ms).slideY(begin: 0.08, end: 0, curve: Curves.easeOutCubic),
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

  Widget _buildDiaryDetailCard(DiaryEntry entry, bool isNight, String fontFamily, {required bool isFirst, required bool isLast}) {
    final themeId = UserState().selectedIslandThemeId.value;
    final bool isCottonCandy = themeId == 'cotton_candy';

    final Color mainTextColor = isNight
        ? Colors.white.withValues(alpha: 0.9)
        : (isCottonCandy ? const Color(0xFF4E3A46) : const Color(0xFF3B2E25));

    final Color subTextColor = isNight
        ? Colors.white38
        : (isCottonCandy ? const Color(0xFF8D7A84) : const Color(0xFF7E7570));

    final moodIdx = entry.moodIndex.clamp(0, kMoods.length - 1);
    final mood = kMoods[moodIdx];
    final images = entry.blocks.where((b) => b['type'] == 'image').toList();

    // 日记内容提取逻辑
    final String plainContent = DiaryUtils.getFilteredContent(entry.content).trim();

    final timeStr = "${entry.dateTime.toLocal().hour.toString().padLeft(2, '0')}:${entry.dateTime.toLocal().minute.toString().padLeft(2, '0')}";

    // 心情表情图与文本解析
    final parsed = ParsedTags.parse(entry.tag, entry.moodIndex);
    final String moodLabel = parsed.customMood ?? mood.label;
    final String iconPath = (entry.moodIndex >= 0 && entry.moodIndex <= 23)
        ? 'assets/icons/custom${entry.moodIndex + 1}.png'
        : (mood.iconPath ?? 'assets/icons/happy.png');
    final bool hasCustomIcon = parsed.customMoodIconPath != null && parsed.customMoodIconPath!.isNotEmpty;

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
                    top: 10,
                    child: Container(
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        color: isNight ? const Color(0xFF2C323A) : Colors.white,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: isNight ? Colors.white12 : Colors.black.withValues(alpha: 0.06),
                          width: 1.5,
                        ),
                      ),
                      child: Center(
                        child: hasCustomIcon
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
                      ),
                    ),
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
                        const SizedBox(width: 8),
                        Text(
                          moodLabel,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: subTextColor,
                            fontFamily: fontFamily,
                          ),
                        ),
                        const Spacer(),
                        Icon(
                          Icons.more_horiz_rounded,
                          size: 16,
                          color: subTextColor.withValues(alpha: 0.7),
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
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Wrap(
                          spacing: 6,
                          runSpacing: 6,
                          children: images.take(3).map((img) {
                            return DiaryUtils.buildImage(
                              img['path'],
                              width: 64,
                              height: 64,
                              fit: BoxFit.cover,
                            );
                          }).toList(),
                        ),
                      ),
                    ],
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

class _LunarCacheData {
  final String lunarStr;
  final bool isImportantFest;

  _LunarCacheData(this.lunarStr, this.isImportantFest);
}

class _CalendarDayCell extends StatelessWidget {
  final DateTime date;
  final List<DiaryEntry>? entries;
  final bool isToday;
  final bool isSelected;
  final bool isNight;
  final VoidCallback onTap;

  static final Map<String, _LunarCacheData> _lunarCache = {};

  const _CalendarDayCell({
    required this.date,
    this.entries,
    required this.isToday,
    required this.isSelected,
    required this.isNight,
    required this.onTap,
  });

  static const Set<String> _importantFests = {
    '元旦', '除夕', '春节', '元宵节', '清明', '劳动节', '端午节', '中秋节', '国庆节',
    '情人节', '妇女节', '儿童节', '教师节', '圣诞节', '冬至', '七夕', '重阳', '腊八',
  };

  _LunarCacheData _getLunarData(DateTime date) {
    final key = "${date.year}-${date.month}-${date.day}";
    if (_lunarCache.containsKey(key)) {
      return _lunarCache[key]!;
    }

    final lunar = Lunar.fromDate(date);
    final solar = Solar.fromDate(date);

    final solarFests = solar.getFestivals();
    final lunarFests = lunar.getFestivals();
    final jieQi = lunar.getJieQi();

    String? importantFest;
    for (final f in [
      ...solarFests,
      ...lunarFests,
      if (jieQi.isNotEmpty) jieQi,
    ]) {
      if (_importantFests.any((important) => f.contains(important))) {
        importantFest = _importantFests.firstWhere((important) => f.contains(important));
        break;
      }
    }

    String lunarStr;
    if (importantFest != null) {
      lunarStr = importantFest;
    } else {
      if (lunar.getDay() == 1) {
        lunarStr = '${lunar.getMonthInChinese()}月';
      } else {
        lunarStr = lunar.getDayInChinese();
      }
    }

    final data = _LunarCacheData(lunarStr, importantFest != null);
    _lunarCache[key] = data;
    return data;
  }

  @override
  Widget build(BuildContext context) {
    final bool hasEntry = entries?.isNotEmpty ?? false;
    
    // 收集当天所有日记里的所有图片
    final List<String> allImages = [];
    int? moodIdx;
    String? customMoodIconPath;
    String? customMoodIconAsset;
    
    if (hasEntry) {
      for (var entry in entries!) {
        for (var block in entry.blocks) {
          if (block['type'] == 'image' && block['path'] != null) {
            allImages.add(block['path'] as String);
          }
        }
      }
      // 如果没有图片，则取最后一条日记的心情图标
      if (allImages.isEmpty) {
        final lastEntry = entries!.last;
        moodIdx = lastEntry.moodIndex;
        final parsed = ParsedTags.parse(lastEntry.tag, lastEntry.moodIndex);
        if (parsed.customMoodIconPath != null && parsed.customMoodIconPath!.isNotEmpty) {
          customMoodIconPath = parsed.customMoodIconPath;
        }
        if (lastEntry.moodIndex >= 0 && lastEntry.moodIndex <= 23) {
          customMoodIconAsset = 'assets/icons/custom${lastEntry.moodIndex + 1}.png';
        }
      }
    }

    final lunarData = _getLunarData(date);
    final lunarStr = lunarData.lunarStr;
    final bool isImportantFest = lunarData.isImportantFest;

    final bool hasPhotos = allImages.isNotEmpty;

    final TextStyle dayStyle = TextStyle(
      fontSize: 16,
      fontWeight: FontWeight.bold,
      fontFamily: 'LXGWWenKai',
      color: hasPhotos
          ? Colors.white
          : (isNight
                ? Colors.white.withValues(alpha: 0.65)
                : const Color(0xFF2C2E30).withValues(alpha: 0.48)),
      shadows: hasPhotos
          ? [
              const Shadow(
                blurRadius: 4,
                color: Colors.black87,
                offset: Offset(0, 1.5),
              ),
            ]
          : null,
    );

    final Color lunarColor = isImportantFest
        ? (hasEntry ? Colors.white : const Color(0xFFE1AF78))
        : (isNight ? Colors.white.withValues(alpha: 0.55) : Colors.black.withValues(alpha: 0.55));

    final TextStyle lunarStyle = TextStyle(
      fontSize: 9.5,
      fontWeight: FontWeight.w600,
      fontFamily: 'LXGWWenKai',
      color: hasEntry ? Colors.white70 : lunarColor,
      shadows: hasEntry
          ? [
              const Shadow(
                blurRadius: 3,
                color: Colors.black54,
                offset: Offset(0, 1),
              ),
            ]
          : null,
      height: 1.1,
    );

    final BorderSide borderSide = isSelected
        ? const BorderSide(color: Color(0xFFE1AF78), width: 2.2)
        : (isToday
            ? BorderSide(color: const Color(0xFFE1AF78).withValues(alpha: 0.6), width: 1.5)
            : (hasEntry
                ? BorderSide(color: isNight ? Colors.white12 : Colors.black.withValues(alpha: 0.12), width: 1.0)
                : BorderSide(color: isNight ? Colors.white.withValues(alpha: 0.1) : Colors.black.withValues(alpha: 0.06), width: 0.8)));

    final themeId = UserState().selectedIslandThemeId.value;
    final bool isLego = themeId == 'lego';

    final Widget cellContent = AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      decoration: BoxDecoration(
        color: isSelected
            ? const Color(0xFFD4A373).withValues(alpha: isNight ? 0.35 : 0.2)
            : (isToday
                  ? const Color(0xFFD4A373).withValues(alpha: isNight ? 0.2 : 0.1)
                  : (hasEntry
                        ? (isNight ? const Color(0xFF3B3E42) : Colors.white)
                        : (isNight
                              ? Colors.white.withValues(alpha: 0.06)
                              : Colors.white.withValues(alpha: 0.5)))),
        borderRadius: BorderRadius.circular(10),
      ),
      clipBehavior: hasPhotos ? Clip.antiAlias : Clip.none,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // 图片背景或拼图组件
          if (allImages.isNotEmpty)
            Positioned.fill(
              child: _buildGridImages(allImages),
            ),

          // 日期数字 + 心情图标（整合为同一列，避免图标被文字遮挡）
          Center(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 3),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text("${date.day}", style: dayStyle),
                  if (!hasEntry) ...[
                    const SizedBox(height: 1),
                    Text(lunarStr, style: lunarStyle),
                  ] else if (allImages.isEmpty && (moodIdx != null || customMoodIconPath != null)) ...[
                    const SizedBox(height: 1),
                    _buildMoodIcon(
                      moodIdx: moodIdx,
                      customMoodIconPath: customMoodIconPath,
                      customMoodIconAsset: customMoodIconAsset,
                      isNight: isNight,
                    ),
                  ],
                ],
              ),
            ),
          ),

          // 顶层覆盖的完美圆角/乐高凹陷边框，确保图片和凹陷边缘完全贴合
          Positioned.fill(
            child: IgnorePointer(
              child: CustomPaint(
                painter: LegoBorderPainter(
                  hasSockets: false,
                  progress: 0.0,
                  borderColor: borderSide.color,
                  borderWidth: borderSide.width,
                ),
              ),
            ),
          ),
        ],
      ),
    );

    if (isLego) {
      return TweenAnimationBuilder<double>(
        duration: const Duration(milliseconds: 120),
        curve: Curves.easeOutCubic,
        tween: Tween<double>(begin: 0.0, end: isSelected ? 1.0 : 0.0),
        builder: (context, progress, child) {
          final bool active = progress > 0.0;
          return GestureDetector(
            onTap: onTap,
            child: Transform.translate(
              offset: Offset(0, 1.5 * progress),
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  ClipPath(
                    clipper: LegoCellClipper(
                      hasSockets: active,
                      progress: progress,
                    ),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? const Color(0xFFD4A373).withValues(alpha: isNight ? 0.35 : 0.2)
                            : (isToday
                                  ? const Color(0xFFD4A373).withValues(alpha: isNight ? 0.2 : 0.1)
                                  : (hasEntry
                                        ? (isNight ? const Color(0xFF3B3E42) : Colors.white)
                                        : (isNight
                                              ? Colors.white.withValues(alpha: 0.06)
                                              : Colors.white.withValues(alpha: 0.5)))),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      clipBehavior: hasPhotos ? Clip.antiAlias : Clip.none,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          if (allImages.isNotEmpty)
                            Positioned.fill(
                              child: _buildGridImages(allImages),
                            ),
                          Center(
                            child: Padding(
                              padding: const EdgeInsets.only(bottom: 3),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text("${date.day}", style: dayStyle),
                                  if (!hasEntry) ...[
                                    const SizedBox(height: 1),
                                    Text(lunarStr, style: lunarStyle),
                                  ] else if (allImages.isEmpty && (moodIdx != null || customMoodIconPath != null)) ...[
                                    const SizedBox(height: 1),
                                    _buildMoodIcon(
                                      moodIdx: moodIdx,
                                      customMoodIconPath: customMoodIconPath,
                                      customMoodIconAsset: customMoodIconAsset,
                                      isNight: isNight,
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ),
                          Positioned.fill(
                            child: IgnorePointer(
                              child: CustomPaint(
                                painter: LegoBorderPainter(
                                  hasSockets: active,
                                  progress: progress,
                                  borderColor: borderSide.color,
                                  borderWidth: borderSide.width,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  if (active)
                    Positioned(
                      top: -3,
                      left: 0,
                      right: 0,
                      child: Opacity(
                        opacity: progress.clamp(0.0, 1.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            _buildLegoStud(progress),
                            const SizedBox(width: 6),
                            _buildLegoStud(progress),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),
          );
        },
      );
    }

    return GestureDetector(
      onTap: onTap,
      child: cellContent,
    );
  }

  Widget _buildLegoStud(double progress) {
    return Container(
      width: 7,
      height: 4,
      decoration: const BoxDecoration(
        color: Color(0xFFE1AF78),
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(1.5),
          topRight: Radius.circular(1.5),
        ),
      ),
    );
  }

  Widget _buildMoodIcon({
    required int? moodIdx,
    required String? customMoodIconPath,
    required String? customMoodIconAsset,
    required bool isNight,
  }) {
    const double size = 18;
    final fallbackIcon = Icon(Icons.mood, size: size, color: isNight ? Colors.white54 : const Color(0xFF5C5C5C));

    Widget img;
    if (customMoodIconPath != null) {
      img = Image.file(
        File(customMoodIconPath),
        width: size, height: size,
        errorBuilder: (c, e, s) => customMoodIconAsset != null
            ? Image.asset(customMoodIconAsset, width: size, height: size,
                errorBuilder: (c2, e2, s2) => fallbackIcon)
            : fallbackIcon,
      );
    } else if (customMoodIconAsset != null) {
      img = Image.asset(
        customMoodIconAsset,
        width: size, height: size,
        errorBuilder: (c, e, s) => fallbackIcon,
      );
    } else if (moodIdx != null) {
      final iconPath = kMoods[moodIdx.clamp(0, kMoods.length - 1)].iconPath;
      if (iconPath != null) {
        img = Image.asset(iconPath, width: size, height: size);
      } else {
        return fallbackIcon;
      }
    } else {
      return fallbackIcon;
    }

    return Opacity(opacity: 0.9, child: img);
  }


  // 构建拼图宫格逻辑

  Widget _buildGridImages(List<String> images) {
    // 用 SizedBox.expand 确保图片在 Expanded 内始终铺满
    Widget tile(String path) => SizedBox.expand(
      child: ClipRect(
        child: DiaryUtils.buildImage(path, fit: BoxFit.cover),
      ),
    );

    final int count = images.length;
    if (count == 1) {
      return tile(images[0]);
    } else if (count == 2) {
      // 2张图：左右平分
      return Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(child: tile(images[0])),
          const SizedBox(width: 1),
          Expanded(child: tile(images[1])),
        ],
      );
    } else if (count == 3) {
      // 3张图：左侧单张，右侧上下两张
      return Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(child: tile(images[0])),
          const SizedBox(width: 1),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(child: tile(images[1])),
                const SizedBox(height: 1),
                Expanded(child: tile(images[2])),
              ],
            ),
          ),
        ],
      );
    } else {
      // 4张及以上：2x2 田字格拼图，右下角覆盖 +N
      final int remaining = count - 4;
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(child: tile(images[0])),
                const SizedBox(width: 1),
                Expanded(child: tile(images[1])),
              ],
            ),
          ),
          const SizedBox(height: 1),
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(child: tile(images[2])),
                const SizedBox(width: 1),
                Expanded(
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      tile(images[3]),
                      if (remaining > 0)
                        DecoratedBox(
                          decoration: BoxDecoration(
                            gradient: RadialGradient(
                              center: Alignment.center,
                              radius: 0.9,
                              colors: [
                                Colors.black.withValues(alpha: 0.72),
                                Colors.black.withValues(alpha: 0.45),
                              ],
                            ),
                          ),
                          child: Center(
                            child: Text(
                              "+$remaining",
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 13,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 0.5,
                                shadows: [
                                  Shadow(
                                    blurRadius: 6,
                                    color: Colors.black,
                                    offset: Offset(0, 1.5),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      );
    }
  }
}

class LegoCellClipper extends CustomClipper<Path> {
  final bool hasSockets;
  final double progress;
  LegoCellClipper({required this.hasSockets, this.progress = 1.0});

  @override
  Path getClip(Size size) {
    final path = Path();
    final w = size.width;
    final h = size.height;
    final r = 10.0;

    if (!hasSockets) {
      path.addRRect(RRect.fromRectAndRadius(
        Rect.fromLTWH(0, 0, w, h),
        Radius.circular(r),
      ));
      return path;
    }

    // Top-left corner to top-right corner
    path.moveTo(r, 0);
    path.lineTo(w - r, 0);
    path.arcToPoint(Offset(w, r), radius: Radius.circular(r));
    
    // Right edge to bottom-right corner
    path.lineTo(w, h - r);
    path.arcToPoint(Offset(w - r, h), radius: Radius.circular(r));
    
    // Bottom edge with two sockets (aligned with top studs)
    final socketW = 7.0;
    final socketH = 3.5 * progress;
    final centerX = w / 2;
    final studLeftCenter = centerX - 6.5;
    final studRightCenter = centerX + 6.5;
    
    final socketLeft1 = studLeftCenter - socketW / 2;
    final socketLeft2 = studRightCenter - socketW / 2;

    path.lineTo(socketLeft2 + socketW, h);
    path.lineTo(socketLeft2 + socketW, h - socketH);
    path.lineTo(socketLeft2, h - socketH);
    path.lineTo(socketLeft2, h);

    path.lineTo(socketLeft1 + socketW, h);
    path.lineTo(socketLeft1 + socketW, h - socketH);
    path.lineTo(socketLeft1, h - socketH);
    path.lineTo(socketLeft1, h);
    
    // Bottom-left corner to top-left corner
    path.lineTo(r, h);
    path.arcToPoint(Offset(0, h - r), radius: Radius.circular(r));
    path.lineTo(0, r);
    path.arcToPoint(Offset(r, 0), radius: Radius.circular(r));
    
    path.close();
    return path;
  }

  @override
  bool shouldReclip(covariant LegoCellClipper oldClipper) =>
      oldClipper.hasSockets != hasSockets || oldClipper.progress != progress;
}

class LegoBorderPainter extends CustomPainter {
  final bool hasSockets;
  final double progress;
  final Color borderColor;
  final double borderWidth;

  LegoBorderPainter({
    required this.hasSockets,
    this.progress = 1.0,
    required this.borderColor,
    required this.borderWidth,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = borderColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = borderWidth
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final w = size.width;
    final h = size.height;
    final r = 10.0;

    final path = Path();

    if (!hasSockets) {
      final rrect = RRect.fromRectAndRadius(
        Rect.fromLTWH(borderWidth / 2, borderWidth / 2, w - borderWidth, h - borderWidth),
        Radius.circular(r - borderWidth / 2),
      );
      path.addRRect(rrect);
      canvas.drawPath(path, paint);
      return;
    }

    path.moveTo(r, 0);
    path.lineTo(w - r, 0);
    path.arcToPoint(Offset(w, r), radius: Radius.circular(r));
    
    path.lineTo(w, h - r);
    path.arcToPoint(Offset(w - r, h), radius: Radius.circular(r));
    
    // Bottom edge with sockets
    final socketW = 7.0;
    final socketH = 3.5 * progress;
    final centerX = w / 2;
    final studLeftCenter = centerX - 6.5;
    final studRightCenter = centerX + 6.5;
    
    final socketLeft1 = studLeftCenter - socketW / 2;
    final socketLeft2 = studRightCenter - socketW / 2;

    path.lineTo(socketLeft2 + socketW, h);
    path.lineTo(socketLeft2 + socketW, h - socketH);
    path.lineTo(socketLeft2, h - socketH);
    path.lineTo(socketLeft2, h);

    path.lineTo(socketLeft1 + socketW, h);
    path.lineTo(socketLeft1 + socketW, h - socketH);
    path.lineTo(socketLeft1, h - socketH);
    path.lineTo(socketLeft1, h);
    
    path.lineTo(r, h);
    path.arcToPoint(Offset(0, h - r), radius: Radius.circular(r));
    path.lineTo(0, r);
    path.arcToPoint(Offset(r, 0), radius: Radius.circular(r));
    
    path.close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant LegoBorderPainter oldDelegate) {
    return oldDelegate.hasSockets != hasSockets ||
        oldDelegate.progress != progress ||
        oldDelegate.borderColor != borderColor ||
        oldDelegate.borderWidth != borderWidth;
  }
}
