import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../utils/diary_utils.dart';
import 'diary_bottom_sheet.dart';
import 'package:island_diary/core/state/user_state.dart';
import 'package:lunar/lunar.dart';

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
  late FixedExtentScrollController _yearController;
  late FixedExtentScrollController _monthController;
  late FixedExtentScrollController _dayController;

  late int _selectedYear;
  late int _selectedMonth;
  late int _selectedDay;

  final int _startYear = 1990;
  final int _endYear = 2050;

  @override
  void initState() {
    super.initState();
    _selectedYear = widget.initialDate.year;
    _selectedMonth = widget.initialDate.month;
    _selectedDay = widget.initialDate.day;

    _yearController = FixedExtentScrollController(
      initialItem: _selectedYear - _startYear,
    );
    _monthController = FixedExtentScrollController(
      initialItem: _selectedMonth - 1,
    );
    _dayController = FixedExtentScrollController(initialItem: _selectedDay - 1);
  }

  @override
  void dispose() {
    _yearController.dispose();
    _monthController.dispose();
    _dayController.dispose();
    super.dispose();
  }

  int _getDaysInMonth(int year, int month) {
    return DateTime(year, month + 1, 0).day;
  }

  void _updateDays() {
    final maxDays = _getDaysInMonth(_selectedYear, _selectedMonth);
    if (_selectedDay > maxDays) {
      setState(() {
        _selectedDay = maxDays;
        _dayController.jumpToItem(_selectedDay - 1);
      });
    }
  }

  String _getLunarAndWeekday() {
    try {
      final date = DateTime(_selectedYear, _selectedMonth, _selectedDay);
      final lunar = Lunar.fromDate(date);
      final month = lunar.getMonthInChinese();
      final day = lunar.getDayInChinese();

      // 替换星座为星期
      final weekdays = ['星期一', '星期二', '星期三', '星期四', '星期五', '星期六', '星期日'];
      final weekday = weekdays[date.weekday - 1];

      return "农历$month$day · $weekday";
    } catch (e) {
      return "次元导航中...";
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isNight = UserState().isNight;
    final themeId = UserState().selectedIslandThemeId.value;

    // 采用与通用弹窗一致的非信纸配色，不跟随信纸材质色
    final Color inkColor;
    final Color accentColor;
    if (isNight) {
      inkColor = Colors.white;
      accentColor = themeId == 'cotton_candy'
          ? const Color(0xFFC0A6FF)
          : const Color(0xFFE0C097);
    } else {
      inkColor = themeId == 'cotton_candy'
          ? const Color(0xFF7C3AED)
          : const Color(0xFF1F2937);
      accentColor = themeId == 'cotton_candy'
          ? const Color(0xFF7C3AED)
          : const Color(0xFFA68565);
    }

    // 针对参考图 1 优化的暖奶油背景色
    final Color bgColor = isNight
        ? (themeId == 'cotton_candy'
              ? const Color(0xFF1E1B2E).withValues(alpha: 0.95)
              : (themeId == 'lego'
                    ? const Color(0xFF18181B).withValues(alpha: 0.95)
                    : const Color(0xFF111827).withValues(alpha: 0.95)))
        : (themeId == 'cotton_candy'
              ? const Color(0xFFFAF5FF)
              : (themeId == 'lego'
                    ? const Color(0xFFF9FAFB)
                    : const Color(0xFFFAF9F6)));

    return DiaryBottomSheet(
      paperStyle: widget.paperStyle,
      isDiary: false,
      showDragHandle: true,
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 12,
        bottom: 24 + MediaQuery.of(context).padding.bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '选择日期',
            style: TextStyle(
              fontFamily: 'LXGWWenKai',
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: inkColor.withValues(alpha: 0.8),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '选择要记录的那一天',
            style: TextStyle(
              fontFamily: 'LXGWWenKai',
              fontSize: 12,
              color: inkColor.withValues(alpha: 0.35),
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 24),

          // 虚空晶石滚轮区
                  Stack(
                    alignment: Alignment.center,
                    children: [
                      // 选中光感区 (拟物化升级)
                      Container(
                        height: 48,
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        decoration: BoxDecoration(
                          color: isNight
                              ? Colors.white.withValues(alpha: 0.05)
                              : const Color(0xFFFDF7E9), // 奶油色底
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: accentColor.withValues(
                              alpha: isNight ? 0.1 : 0.08,
                            ),
                            width: 1,
                          ),
                          boxShadow: isNight
                              ? null
                              : [
                                  BoxShadow(
                                    color: const Color(
                                      0xFF8B5E3C,
                                    ).withValues(alpha: 0.04),
                                    blurRadius: 8,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                        ),
                      ),
                      SizedBox(
                        height: 180, // 稍微缩小高度防止溢出
                        child: ShaderMask(
                          shaderCallback: (rect) {
                            return const LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                Colors.black,
                                Colors.transparent,
                                Colors.transparent,
                                Colors.black,
                              ],
                              stops: [0.0, 0.25, 0.75, 1.0],
                            ).createShader(rect);
                          },
                          blendMode:
                              BlendMode.dstOut, // 改回 dstOut，黑色部分隐藏，透明部分显示
                          child: Row(
                            children: [
                              _buildWheel(
                                label: '年',
                                controller: _yearController,
                                itemCount: _endYear - _startYear + 1,
                                onChanged: (i) {
                                  setState(
                                    () => _selectedYear = _startYear + i,
                                  );
                                  _updateDays();
                                },
                                getItemText: (i) => '${_startYear + i}',
                                accentColor: inkColor,
                              ),
                              _buildWheel(
                                label: '月',
                                controller: _monthController,
                                itemCount: 12,
                                onChanged: (i) {
                                  setState(() => _selectedMonth = i + 1);
                                  _updateDays();
                                },
                                getItemText: (i) => '${i + 1}',
                                accentColor: inkColor,
                              ),
                              _buildWheel(
                                label: '日',
                                controller: _dayController,
                                itemCount: _getDaysInMonth(
                                  _selectedYear,
                                  _selectedMonth,
                                ),
                                onChanged: (i) {
                                  setState(() => _selectedDay = i + 1);
                                },
                                getItemText: (i) => '${i + 1}',
                                accentColor: inkColor,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),
                  // 农历标签
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: isNight
                          ? Colors.white.withValues(alpha: 0.03)
                          : accentColor.withValues(alpha: 0.04),
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: Text(
                      _getLunarAndWeekday(),
                      style: TextStyle(
                        fontFamily: 'LXGWWenKai',
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: inkColor.withValues(alpha: 0.45),
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),
                  // 确认按钮
                  GestureDetector(
                    onTap: () => widget.onConfirm(
                      DateTime(_selectedYear, _selectedMonth, _selectedDay),
                    ),
                    child: Container(
                      width: double.infinity,
                      height: 54,
                      decoration: BoxDecoration(
                        color: accentColor,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: accentColor.withValues(alpha: 0.25),
                            blurRadius: 8,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        '确定',
                        style: TextStyle(
                          fontFamily: 'LXGWWenKai',
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          letterSpacing: 2,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            )
            .animate()
            .fadeIn(duration: 400.ms)
            .slideY(begin: 0.1, end: 0, curve: Curves.easeOutCubic);
  }

  Widget _buildWheel({
    required String label,
    required FixedExtentScrollController controller,
    required int itemCount,
    required ValueChanged<int> onChanged,
    required String Function(int) getItemText,
    required Color accentColor,
  }) {
    return Expanded(
      child: ListWheelScrollView.useDelegate(
        controller: controller,
        itemExtent: 44,
        perspective: 0.005,
        diameterRatio: 1.2,
        physics: const FixedExtentScrollPhysics(),
        onSelectedItemChanged: onChanged,
        childDelegate: ListWheelChildBuilderDelegate(
          builder: (context, index) {
            if (index < 0 || index >= itemCount) return null;
            return Center(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Text(
                    getItemText(index),
                    style: TextStyle(
                      fontFamily: 'Douyin',
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: accentColor.withValues(alpha: 0.8),
                    ),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    label,
                    style: TextStyle(
                      fontFamily: 'LXGWWenKai',
                      fontSize: 12,
                      color: accentColor.withValues(alpha: 0.4),
                    ),
                  ),
                ],
              ),
            );
          },
          childCount: itemCount,
        ),
      ),
    );
  }
}
