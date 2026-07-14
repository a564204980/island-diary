import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:island_diary/core/theme/app_colors.dart';
import 'package:lunar/lunar.dart';
import 'package:island_diary/core/state/user_state.dart';
import 'package:island_diary/shared/widgets/diary_entry/components/diary_bottom_sheet.dart';
class IslandDateTimePicker extends StatefulWidget {
  final DateTime initialDate;

  const IslandDateTimePicker({super.key, required this.initialDate});

  static Future<DateTime?> show(BuildContext context, {required DateTime initialDate}) {
    return showModalBottomSheet<DateTime>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return DiaryBottomSheet(
          isDiary: false,
          paperStyle: '',
          padding: EdgeInsets.zero,
          child: IslandDateTimePicker(initialDate: initialDate),
        );
      },
    );
  }

  @override
  State<IslandDateTimePicker> createState() => _IslandDateTimePickerState();
}

class _IslandDateTimePickerState extends State<IslandDateTimePicker> {
  late DateTime _selectedDate;
  late DateTime _currentMonth;
  bool _isTimePickerVisible = false;

  final List<String> _weekdaysCn = ['周日', '周一', '周二', '周三', '周四', '周五', '周六'];

  @override
  void initState() {
    super.initState();
    _selectedDate = widget.initialDate;
    _currentMonth = DateTime(_selectedDate.year, _selectedDate.month);
  }

  void _previousMonth() {
    HapticFeedback.lightImpact();
    setState(() {
      _currentMonth = DateTime(_currentMonth.year, _currentMonth.month - 1);
    });
  }

  void _nextMonth() {
    HapticFeedback.lightImpact();
    setState(() {
      _currentMonth = DateTime(_currentMonth.year, _currentMonth.month + 1);
    });
  }

  void _goToToday() {
    HapticFeedback.lightImpact();
    final now = DateTime.now();
    setState(() {
      _currentMonth = DateTime(now.year, now.month);
      _selectedDate = DateTime(
        now.year, now.month, now.day,
        _selectedDate.hour, _selectedDate.minute,
      );
    });
  }

  void _selectDate(DateTime date) {
    HapticFeedback.selectionClick();
    setState(() {
      _selectedDate = DateTime(
        date.year, date.month, date.day,
        _selectedDate.hour, _selectedDate.minute,
      );
      if (_currentMonth.month != date.month || _currentMonth.year != date.year) {
        _currentMonth = DateTime(date.year, date.month);
      }
    });
  }

  List<DateTime> _buildCalendarDays() {
    final List<DateTime> days = [];
    final firstDayOfMonth = DateTime(_currentMonth.year, _currentMonth.month, 1);
    final lastDayOfMonth = DateTime(_currentMonth.year, _currentMonth.month + 1, 0);

    int leadingDays = firstDayOfMonth.weekday;
    if (leadingDays == 7) leadingDays = 0; 

    final prevMonth = DateTime(_currentMonth.year, _currentMonth.month - 1);
    final lastDayOfPrevMonth = DateTime(prevMonth.year, prevMonth.month + 1, 0).day;

    for (int i = leadingDays - 1; i >= 0; i--) {
      days.add(DateTime(prevMonth.year, prevMonth.month, lastDayOfPrevMonth - i));
    }

    for (int i = 1; i <= lastDayOfMonth.day; i++) {
      days.add(DateTime(_currentMonth.year, _currentMonth.month, i));
    }

    // 动态计算剩余天数，补齐到当前行的末尾（7的倍数），而不是固定 42 天（6行）
    int remainingDays = (7 - (days.length % 7)) % 7; 
    final nextMonth = DateTime(_currentMonth.year, _currentMonth.month + 1);
    for (int i = 1; i <= remainingDays; i++) {
      days.add(DateTime(nextMonth.year, nextMonth.month, i));
    }

    return days;
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  @override
  Widget build(BuildContext context) {
    final appColors = AppColorsExtension.of(context);
    
    final bool isNight = UserState().isNight;
    final themeId = UserState().selectedIslandThemeId.value;
    final Color themeAccentColor;
    if (isNight) {
      themeAccentColor = themeId == 'cotton_candy' ? const Color(0xFFC0A6FF) : const Color(0xFFE0C097);
    } else {
      themeAccentColor = themeId == 'cotton_candy' ? const Color(0xFF7C3AED) : const Color(0xFF9C785A);
    }
    
    // 从 AppColors 提取文字和背景
    final textColor = appColors.textPrimary;
    final subTextColor = appColors.textSecondary;
    final disabledColor = appColors.border;
    
    final now = DateTime.now();
    final days = _buildCalendarDays();

    return Padding(
      padding: EdgeInsets.only(
        left: 24.0,
        right: 24.0,
        top: 12.0, // Reduced slightly since DiaryBottomSheet has a top padding of 12.0
        bottom: 24.0 + MediaQuery.of(context).padding.bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                GestureDetector(
                  onTap: _goToToday,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
                    color: Colors.transparent,
                    child: Text(
                      '今天',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: subTextColor,
                      ),
                    ),
                  ),
                ),
                Text(
                  '${_currentMonth.year}年 ${_currentMonth.month}月',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: textColor,
                    fontFamily: 'LXGWWenKai',
                  ),
                ),
                Row(
                  children: [
                    GestureDetector(
                      onTap: _previousMonth,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        color: Colors.transparent,
                        child: Icon(Icons.arrow_back_ios_rounded, size: 18, color: subTextColor),
                      ),
                    ),
                    GestureDetector(
                      onTap: _nextMonth,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        color: Colors.transparent,
                        child: Icon(Icons.arrow_forward_ios_rounded, size: 18, color: subTextColor),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 24),
            
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: _weekdaysCn.map((day) => Expanded(
                child: Center(
                  child: Text(
                    day,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: textColor,
                    ),
                  ),
                ),
              )).toList(),
            ),
            const SizedBox(height: 16),
            
            GridView.builder(
              padding: EdgeInsets.zero,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: days.length,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 7,
                childAspectRatio: 1.0,
              ),
              itemBuilder: (context, index) {
                final day = days[index];
                final isCurrentMonth = day.month == _currentMonth.month;
                
                // 只能出现当月的日期
                if (!isCurrentMonth) {
                  return const SizedBox.shrink();
                }

                final isSelected = _isSameDay(day, _selectedDate);
                final isToday = _isSameDay(day, now);

                return GestureDetector(
                  onTap: () => _selectDate(day),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeOutCubic,
                      margin: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: isSelected ? themeAccentColor.withValues(alpha: 0.15) : Colors.transparent,
                        borderRadius: BorderRadius.circular(12),
                        border: isSelected
                            ? Border.all(color: themeAccentColor, width: 2.0)
                            : (isToday ? Border.all(color: themeAccentColor.withValues(alpha: 0.3), width: 1.0) : null),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          AnimatedDefaultTextStyle(
                            duration: const Duration(milliseconds: 300),
                            curve: Curves.easeOutCubic,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                              color: isSelected ? themeAccentColor : textColor,
                            ),
                            child: Text('${day.day}'),
                          ),
                          Builder(
                            builder: (context) {
                              final lunar = Lunar.fromDate(day);
                              String lunarText = lunar.getDayInChinese();
                              if (lunarText == '初一') {
                                lunarText = '${lunar.getMonthInChinese()}月';
                              }
                              return AnimatedDefaultTextStyle(
                                duration: const Duration(milliseconds: 300),
                                curve: Curves.easeOutCubic,
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.normal,
                                  color: isSelected ? themeAccentColor.withValues(alpha: 0.8) : subTextColor,
                                  fontFamily: 'LXGWWenKai',
                                ),
                                child: Text(lunarText),
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                );
              },
            ),
            
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Divider(height: 1, thickness: 1, color: disabledColor),
            ),
            
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '时间',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: textColor,
                    fontFamily: 'LXGWWenKai',
                  ),
                ),
                GestureDetector(
                  onTap: () {
                    HapticFeedback.selectionClick();
                    setState(() {
                      _isTimePickerVisible = !_isTimePickerVisible;
                    });
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      border: Border.all(color: disabledColor),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      children: [
                        Text(
                          '${_selectedDate.hour.toString().padLeft(2, '0')}:${_selectedDate.minute.toString().padLeft(2, '0')}',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                            color: textColor,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Icon(
                          _isTimePickerVisible ? Icons.keyboard_arrow_up_rounded : Icons.keyboard_arrow_down_rounded,
                          size: 20,
                          color: textColor,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            
            AnimatedCrossFade(
              firstChild: const SizedBox(height: 0, width: double.infinity),
              secondChild: SizedBox(
                height: 150,
                child: CupertinoDatePicker(
                  mode: CupertinoDatePickerMode.time,
                  initialDateTime: _selectedDate,
                  use24hFormat: true,
                  onDateTimeChanged: (newTime) {
                    setState(() {
                      _selectedDate = DateTime(
                        _selectedDate.year, _selectedDate.month, _selectedDate.day,
                        newTime.hour, newTime.minute,
                      );
                    });
                  },
                ),
              ),
              crossFadeState: _isTimePickerVisible ? CrossFadeState.showSecond : CrossFadeState.showFirst,
              duration: const Duration(milliseconds: 300),
            ),
            
            const SizedBox(height: 16),
            
            GestureDetector(
              onTap: () {
                HapticFeedback.mediumImpact();
                Navigator.pop(context, _selectedDate);
              },
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 16),
                decoration: BoxDecoration(
                  color: themeAccentColor,
                  borderRadius: BorderRadius.circular(30),
                  boxShadow: isNight ? [] : [
                    BoxShadow(
                      color: themeAccentColor.withValues(alpha: 0.3),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    )
                  ],
                ),
                alignment: Alignment.center,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
                      '确定',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
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
