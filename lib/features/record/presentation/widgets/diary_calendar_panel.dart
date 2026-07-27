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
import 'package:island_diary/core/theme/app_colors.dart';
import 'package:island_diary/core/plugins/plugin_manager.dart';
import 'package:island_diary/core/plugins/island_plugin.dart';

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
  bool _scrollStartedAtTop = false;
  int _slideDirection = 1;

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

        final themeColors = AppColorsExtension.current(themeId: themeId, isNight: widget.isNight);
        final Color mainTextColor = themeColors.textPrimary;
        final Color subTextColor = themeColors.textSecondary;

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

          // 预加载所有日记中的本地或网络照片，保证周视图左右滑动时秒开显示，零灰块零白屏
          for (var entry in allDiaries) {
            for (var block in entry.blocks) {
              if (block['type'] == 'image' && block['path'] != null) {
                final String path = block['path'];
                if (path.startsWith('http') || path.startsWith('blob:')) {
                  precacheImage(NetworkImage(path), context);
                } else if (path.startsWith('assets/')) {
                  precacheImage(AssetImage(path), context);
                } else {
                  final file = File(path);
                  if (file.existsSync()) {
                    precacheImage(FileImage(file), context);
                  }
                }
              }
            }
          }
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
              behavior: HitTestBehavior.opaque,
              onVerticalDragUpdate: (details) {
                final delta = details.primaryDelta;
                if (delta == null) return;
                if (delta > 8) {
                  // 向下拖拽：展开日历
                  if (_isCollapsed) {
                    setState(() {
                      _isCollapsed = false;
                    });
                  }
                } else if (delta < -8) {
                  // 向上拖拽：折叠日历为单周
                  if (!_isCollapsed && _selectedDay != null) {
                    setState(() {
                      _isCollapsed = true;
                      _collapsedWeekIndex = selectedWeekIndex;
                    });
                    if (_scrollController.hasClients && _scrollController.offset > 0) {
                      _scrollController.jumpTo(0);
                    }
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
                              Widget? cachedPanel;
                              showModalBottomSheet(
                                context: context,
                                isScrollControlled: true,
                                backgroundColor: Colors.transparent,
                                builder: (context) {
                                  cachedPanel ??= DiarySearchPanel(
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
                                  );
                                  return cachedPanel!;
                                },
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
                  // 3. 日历网格：始终用同一 Column 结构，折叠时仅靠高度动画隐藏非目标行
                  // 这样 CalendarDayCell 永远不会被销毁，图片不会重新加载
                  GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    // 折叠状态下支持左右滑动切换周行
                    onHorizontalDragEnd: _isCollapsed ? (details) {
                      if (details.primaryVelocity == null) return;
                      if (details.primaryVelocity! < -120) {
                        // 向左手势：下一周（从右向左划入，_slideDirection = 1）
                        final nextIndex = ((_collapsedWeekIndex ?? activeWeekIndex) + 1).clamp(0, weeks.length - 1);
                        if (nextIndex != (_collapsedWeekIndex ?? activeWeekIndex)) {
                          setState(() {
                            _slideDirection = 1;
                            _collapsedWeekIndex = nextIndex;
                          });
                        }
                      } else if (details.primaryVelocity! > 120) {
                        // 向右手势：上一周（从左向右划入，_slideDirection = -1）
                        final prevIndex = ((_collapsedWeekIndex ?? activeWeekIndex) - 1).clamp(0, weeks.length - 1);
                        if (prevIndex != (_collapsedWeekIndex ?? activeWeekIndex)) {
                          setState(() {
                            _slideDirection = -1;
                            _collapsedWeekIndex = prevIndex;
                          });
                        }
                      }
                    } : null,
                    child: ClipRect(
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 250),
                        curve: Curves.easeOutCubic,
                        height: _isCollapsed ? 62 : weeks.length * 62.0,
                        child: _isCollapsed
                            ? AnimatedSwitcher(
                                duration: const Duration(milliseconds: 220),
                                switchInCurve: Curves.fastOutSlowIn,
                                switchOutCurve: Curves.fastOutSlowIn,
                                transitionBuilder: (Widget child, Animation<double> animation) {
                                  final isIncoming = child.key == ValueKey(activeWeekIndex);
                                  final slideAnimation = Tween<Offset>(
                                    begin: isIncoming
                                        ? Offset(_slideDirection * 0.35, 0.0)
                                        : Offset(-_slideDirection * 0.35, 0.0),
                                    end: Offset.zero,
                                  ).animate(animation);
                                  final fadeAnimation = Tween<double>(
                                    begin: isIncoming ? 0.2 : 1.0,
                                    end: isIncoming ? 1.0 : 0.0,
                                  ).animate(animation);

                                  return SlideTransition(
                                    position: slideAnimation,
                                    child: FadeTransition(
                                      opacity: fadeAnimation,
                                      child: child,
                                    ),
                                  );
                                },
                                child: KeyedSubtree(
                                  key: ValueKey(activeWeekIndex),
                                  child: Padding(
                                    padding: const EdgeInsets.only(top: 4, bottom: 6),
                                    child: _buildWeekRow(
                                      wIndex: activeWeekIndex,
                                      week: weeks[activeWeekIndex],
                                      month: month,
                                      year: year,
                                      allDiaries: allDiaries,
                                    ),
                                  ),
                                ),
                              )
                            : OverflowBox(
                                alignment: Alignment.topCenter,
                                minHeight: 0,
                                maxHeight: double.infinity,
                                child: Column(
                                  key: const ValueKey('full_month'),
                                  mainAxisSize: MainAxisSize.min,
                                  children: List.generate(weeks.length, (wIndex) {
                                    return Padding(
                                      padding: const EdgeInsets.only(top: 4, bottom: 6),
                                      child: _buildWeekRow(
                                        wIndex: wIndex,
                                        week: weeks[wIndex],
                                        month: month,
                                        year: year,
                                        allDiaries: allDiaries,
                                      ),
                                    );
                                  }),
                                ),
                              ),
                      ),
                    ),
                  ),
              ],
              ),
            ),
          ),
          Expanded(
            child: NotificationListener<ScrollNotification>(
              onNotification: (notification) {
                if (notification is ScrollStartNotification) {
                  // 记录本次滑动开始时，列表是否已经在最顶部
                  _scrollStartedAtTop = notification.metrics.pixels <= 0;
                } else if (notification is UserScrollNotification) {
                  if (notification.direction == ScrollDirection.reverse) {
                    if (!_isCollapsed && _selectedDay != null) {
                      setState(() {
                        _isCollapsed = true;
                      });
                      // 使用 addPostFrameCallback 脱离当前 Notification 触发栈，彻底杜绝 StackOverflow 递归
                      WidgetsBinding.instance.addPostFrameCallback((_) {
                        if (_scrollController.hasClients && _scrollController.offset != 0) {
                          _scrollController.jumpTo(0);
                        }
                      });
                    }
                  }
                } else if (notification is ScrollUpdateNotification) {
                  if (_scrollStartedAtTop && notification.metrics.pixels < -12 && notification.scrollDelta != null && notification.scrollDelta! < 0) {
                    // 折叠态：只有当手势是从列表顶部发起的，才响应下拉展开日历
                    if (_isCollapsed) {
                      setState(() {
                        _isCollapsed = false;
                      });
                    }
                  }
                } else if (notification is OverscrollNotification) {
                  if (_scrollStartedAtTop && notification.overscroll < -6) {
                    if (_isCollapsed) {
                      setState(() {
                        _isCollapsed = false;
                      });
                    }
                  }
                } else if (notification is ScrollEndNotification) {
                  _scrollStartedAtTop = false;
                }
                return false;
              },
              child: SingleChildScrollView(
                controller: _scrollController,
                physics: const AlwaysScrollableScrollPhysics(
                  parent: BouncingScrollPhysics(),
                ),
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
    final themeColors = AppColorsExtension.current(themeId: themeId, isNight: isNight);
    final Color subTextColor = themeColors.textSecondary;

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
                    color: subTextColor,
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
    final String iconPath = mood.iconPath ?? 'assets/icons/happy.png';

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

    final images = entry.blocks.where((b) {
      if (b['type'] != 'image' || b['path'] == null) return false;
      final String path = b['path'] as String;
      if (path.startsWith('http') || path.startsWith('blob:') || path.startsWith('data:') || path.startsWith('assets/')) return true;
      return File(path).existsSync();
    }).toList();

    // 日记内容提取逻辑：将预览转换为单行文本（自然折行），彻底消除因回车或多余空行导致的垂直间距
    final String plainContent = DiaryUtils.getFilteredContent(entry.content)
        .replaceAll(RegExp(r'[\u200B-\u200F\u2028\u2029\uFEFF\uFFFC]'), '')
        .replaceAll('\n', ' ')
        .replaceAll('\r', ' ')
        .replaceAll(RegExp(r'\s+'), ' ') // 合并多个空格
        .trim();

    final timeStr = _selectedDay == null 
        ? "${entry.dateTime.toLocal().month}月${entry.dateTime.toLocal().day}日 ${entry.dateTime.toLocal().hour.toString().padLeft(2, '0')}:${entry.dateTime.toLocal().minute.toString().padLeft(2, '0')}"
        : "${entry.dateTime.toLocal().hour.toString().padLeft(2, '0')}:${entry.dateTime.toLocal().minute.toString().padLeft(2, '0')}";

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
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
                        if (entry.imageLayoutStyle == 'chunshan') ...[
                          const SizedBox(width: 6),
                          Icon(
                            Icons.eco_rounded, // 代表春天的图标
                            size: 14,
                            color: const Color(0xFF66BB6A), // 清新的春绿色
                          ),
                        ],
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
                        return const SizedBox.shrink();
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
                        textHeightBehavior: const TextHeightBehavior(
                          applyHeightToFirstAscent: false,
                          applyHeightToLastDescent: false,
                        ),
                        text: TextSpan(children: spans),
                      );
                    }),
                    // 如果有图片，展示图片预览
                    if (images.isNotEmpty) ...[
                      const SizedBox(height: 4),
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
                    // 插件注入的迷你组件（例如：旅程简易卡片）
                    Builder(builder: (context) {
                      final parsed = ParsedTags.parse(entry.tag, entry.moodIndex);
                      if (parsed.tags.isEmpty) return const SizedBox.shrink();

                      final expPlugin = PluginManager.instance.getActivePlugin<ExperiencePlugin>(PluginCategory.experience);
                      final String? activeTag = parsed.tags.cast<String?>().firstWhere(
                        (t) => expPlugin?.targetTags.contains(t) == true, 
                        orElse: () => null
                      );
                      final bool isPluginActive = expPlugin != null && activeTag != null;
                      
                      if (isPluginActive) {
                        final miniWidget = expPlugin.buildTimelineMiniWidget(
                          context,
                          tag: activeTag,
                          annotations: entry.annotations,
                        );
                        if (miniWidget != null) {
                          return Padding(
                            padding: const EdgeInsets.only(top: 10),
                            child: miniWidget,
                          );
                        }
                      }
                      return const SizedBox.shrink();
                    }),
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

  Widget _buildWeekRow({
    required int wIndex,
    required List<DateTime> week,
    required int month,
    required int year,
    required List<DiaryEntry> allDiaries,
  }) {
    return SizedBox(
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
