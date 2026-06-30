import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../utils/diary_utils.dart';
import 'diary_bottom_sheet.dart';
import 'package:island_diary/core/state/user_state.dart';

class DiaryDatePickerSheet extends StatefulWidget {
  final DateTime initialDate;
  final String paperStyle;
  final ValueChanged<DateTime> onConfirm;

  const DiaryDatePickerSheet({
    super.key,
    required this.initialDate,
    required this.onConfirm,
    this.paperStyle = 'standard',
  });

  @override
  State<DiaryDatePickerSheet> createState() => _DiaryDatePickerSheetState();
}

class _DiaryDatePickerSheetState extends State<DiaryDatePickerSheet> {
  late DateTime _selectedDate;
  late int _viewYear;
  late int _viewMonth;

  @override
  void initState() {
    super.initState();
    _selectedDate = widget.initialDate;
    _viewYear = _selectedDate.year;
    _viewMonth = _selectedDate.month;
  }

  // 切换上一个月
  void _prevMonth() {
    setState(() {
      if (_viewMonth == 1) {
        _viewMonth = 12;
        _viewYear--;
      } else {
        _viewMonth--;
      }
    });
  }

  // 切换下一个月
  void _nextMonth() {
    setState(() {
      if (_viewMonth == 12) {
        _viewMonth = 1;
        _viewYear++;
      } else {
        _viewMonth++;
      }
    });
  }

  // 获取该月的所有展示格 (包含上月尾巴和下月开头，固定 42 格保证高度不变)
  List<DateTime> _buildCalendarDays() {
    final List<DateTime> days = [];
    final firstDay = DateTime(_viewYear, _viewMonth, 1);
    
    // 补齐上个月的尾巴 (1=周一, 7=周日)
    final int prefixDaysCount = firstDay.weekday - 1;
    final prevMonthLimit = firstDay.subtract(Duration(days: prefixDaysCount));
    for (int i = 0; i < prefixDaysCount; i++) {
      days.add(prevMonthLimit.add(Duration(days: i)));
    }

    // 本月日期
    final int daysInMonth = DateUtils.getDaysInMonth(_viewYear, _viewMonth);
    for (int i = 1; i <= daysInMonth; i++) {
      days.add(DateTime(_viewYear, _viewMonth, i));
    }

    // 补齐下个月的开头 (填满 42 格)
    final int totalCells = 42;
    final int suffixDaysCount = totalCells - days.length;
    final lastDay = DateTime(_viewYear, _viewMonth, daysInMonth);
    for (int i = 1; i <= suffixDaysCount; i++) {
      days.add(lastDay.add(Duration(days: i)));
    }

    return days;
  }

  @override
  Widget build(BuildContext context) {
    final bool isNight = UserState().isNight;
    final Color accentColor = DiaryUtils.getAccentColor(widget.paperStyle, isNight);
    final Color inkColor = DiaryUtils.getInkColor(widget.paperStyle, isNight);
    final bool isLego = UserState().selectedIslandThemeId.value == 'lego';
    final String font = isLego ? 'SweiFistLeg' : 'LXGWWenKai';

    final calendarDays = _buildCalendarDays();
    final weekLabels = ['一', '二', '三', '四', '五', '六', '日'];

    return DiaryBottomSheet(
      paperStyle: widget.paperStyle,
      isDiary: false,
      showDragHandle: true,
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 8,
        bottom: 20 + MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 1. 月份切换头部
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                onPressed: _prevMonth,
                icon: Icon(CupertinoIcons.chevron_left, color: accentColor, size: 20),
              ),
              Text(
                '$_viewYear 年 $_viewMonth 月',
                style: TextStyle(
                  fontFamily: font,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: accentColor,
                ),
              ),
              IconButton(
                onPressed: _nextMonth,
                icon: Icon(CupertinoIcons.chevron_right, color: accentColor, size: 20),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // 2. 星期指示横条 (周末上色)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: List.generate(weekLabels.length, (idx) {
              final w = weekLabels[idx];
              final bool isWeekend = idx == 5 || idx == 6; // 六和日
              return SizedBox(
                width: 36,
                child: Text(
                  w,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: font,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: isWeekend 
                        ? (isNight ? const Color(0xFFFFB3A7).withValues(alpha: 0.7) : const Color(0xFFE76F51).withValues(alpha: 0.7))
                        : inkColor.withValues(alpha: 0.4),
                  ),
                ),
              );
            }),
          ),
          const SizedBox(height: 8),

          // 3. 日历网格
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 7,
              mainAxisSpacing: 4,
              crossAxisSpacing: 4,
              childAspectRatio: 1.45,
            ),
            itemCount: calendarDays.length,
            itemBuilder: (context, idx) {
              final date = calendarDays[idx];
              final bool isCurrentMonth = date.month == _viewMonth;
              final bool isToday = DateUtils.isSameDay(date, DateTime.now());
              final bool isSelected = DateUtils.isSameDay(date, _selectedDate);
              final bool isWeekend = date.weekday == 6 || date.weekday == 7;

              // 检查该天是否有写过日记，用于画小圆点
              final bool hasDiary = UserState().savedDiaries.value.any(
                (d) => DateUtils.isSameDay(d.dateTime, date)
              );

              Color textColor;
              if (isSelected) {
                textColor = Colors.white;
              } else if (isCurrentMonth) {
                if (isToday) {
                  textColor = accentColor;
                } else if (isWeekend) {
                  textColor = isNight ? const Color(0xFFFFB3A7) : const Color(0xFFE76F51); // 周末亮橙色
                } else {
                  textColor = inkColor.withValues(alpha: 0.85);
                }
              } else {
                textColor = inkColor.withValues(alpha: 0.25); // 非本月日期变暗
              }

              return GestureDetector(
                onTap: () {
                  setState(() {
                    _selectedDate = date;
                    if (date.month != _viewMonth) {
                      _viewYear = date.year;
                      _viewMonth = date.month; // 跨月点击自动切月
                    }
                  });
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: isSelected 
                        ? accentColor 
                        : (isToday ? accentColor.withValues(alpha: 0.1) : Colors.transparent),
                    shape: BoxShape.circle,
                  ),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Padding(
                        padding: EdgeInsets.only(bottom: (hasDiary && isCurrentMonth) ? 4.0 : 0.0),
                        child: Text(
                          '${date.day}',
                          style: TextStyle(
                            fontFamily: font,
                            fontSize: 13,
                            fontWeight: (isSelected || isToday) ? FontWeight.bold : FontWeight.w500,
                            color: textColor,
                          ),
                        ),
                      ),
                      if (hasDiary && isCurrentMonth)
                        Positioned(
                          bottom: 1.5,
                          child: Container(
                            width: 3.5,
                            height: 3.5,
                            decoration: BoxDecoration(
                              color: isSelected 
                                  ? Colors.white.withValues(alpha: 0.9) 
                                  : (isToday ? accentColor : accentColor.withValues(alpha: 0.55)),
                              shape: BoxShape.circle,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 20),

          // 4. 底部动作栏 (回到今天 + 确认选择)
          Row(
            children: [
              // 快速回到今天
              GestureDetector(
                onTap: () {
                  final now = DateTime.now();
                  setState(() {
                    _selectedDate = now;
                    _viewYear = now.year;
                    _viewMonth = now.month;
                  });
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  decoration: BoxDecoration(
                    color: isNight ? Colors.white10 : Colors.black.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    '回到今天',
                    style: TextStyle(
                      fontFamily: font,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: inkColor.withValues(alpha: 0.7),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              
              // 确认选择按钮
              Expanded(
                child: ElevatedButton(
                  onPressed: () => widget.onConfirm(_selectedDate),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: accentColor,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: Text(
                    '确认日期',
                    style: TextStyle(
                      fontFamily: font,
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    ).animate().fadeIn(duration: 350.ms).slideY(begin: 0.08, end: 0, curve: Curves.easeOutCubic);
  }
}
