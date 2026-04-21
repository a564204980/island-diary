import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../utils/diary_utils.dart';
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

    _yearController = FixedExtentScrollController(initialItem: _selectedYear - _startYear);
    _monthController = FixedExtentScrollController(initialItem: _selectedMonth - 1);
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
    final Color accentColor = DiaryUtils.getAccentColor(widget.paperStyle, isNight);
    final Color bgColor = DiaryUtils.getPopupBackgroundColor(widget.paperStyle, isNight);
    final Color inkColor = DiaryUtils.getInkColor(widget.paperStyle, isNight);

    return BackdropFilter(
      filter: ImageFilter.blur(
        sigmaX: isNight ? 15 : 0,
        sigmaY: isNight ? 15 : 0,
      ),
      child: Container(
        padding: EdgeInsets.only(
          left: 24,
          right: 24,
          top: 20,
          bottom: 24 + MediaQuery.of(context).viewInsets.bottom,
        ),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(32),
            topRight: Radius.circular(32),
          ),
          boxShadow: [
            BoxShadow(
              color: accentColor.withValues(alpha: 0.1),
              blurRadius: 30,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
          // 晶体拉杆
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [accentColor.withValues(alpha: 0.1), accentColor.withValues(alpha: 0.3)],
              ),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            '选择日期',
            style: TextStyle(
              fontFamily: 'LXGWWenKai',
              fontSize: 18,
              fontWeight: FontWeight.w900,
              color: accentColor,
              letterSpacing: 4,
            ),
          ),
          const SizedBox(height: 24),
          
          // 虚空晶石滚轮区
          Stack(
            alignment: Alignment.center,
            children: [
              // 选中光感区
              Container(
                height: 48,
                decoration: BoxDecoration(
                  color: accentColor.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: accentColor.withValues(alpha: 0.1)),
                ),
              ),
              SizedBox(
                height: 200,
                child: ShaderMask(
                  shaderCallback: (rect) {
                    return LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.black,
                        Colors.transparent,
                        Colors.transparent,
                        Colors.black
                      ],
                      stops: const [0.0, 0.15, 0.85, 1.0],
                    ).createShader(rect);
                  },
                  blendMode: BlendMode.dstOut,
                  child: Row(
                    children: [
                      _buildWheel(
                        label: '年',
                        controller: _yearController,
                        itemCount: _endYear - _startYear + 1,
                        onChanged: (i) {
                          setState(() => _selectedYear = _startYear + i);
                          _updateDays();
                        },
                        getItemText: (i) => '${_startYear + i}',
                        accentColor: accentColor,
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
                        accentColor: accentColor,
                      ),
                      _buildWheel(
                        label: '日',
                        controller: _dayController,
                        itemCount: _getDaysInMonth(_selectedYear, _selectedMonth),
                        onChanged: (i) {
                          setState(() => _selectedDay = i + 1);
                        },
                        getItemText: (i) => '${i + 1}',
                        accentColor: accentColor,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 16),
          // 时空反馈区
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: accentColor.withValues(alpha: 0.03),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              _getLunarAndWeekday(),
              style: TextStyle(
                fontFamily: 'LXGWWenKai',
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: inkColor.withValues(alpha: 0.6),
                letterSpacing: 1.2,
              ),
            ),
          ),
          
          const SizedBox(height: 24),
          // 确认按钮 (晶体风格)
          GestureDetector(
            onTap: () => widget.onConfirm(DateTime(_selectedYear, _selectedMonth, _selectedDay)),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [accentColor, Color.lerp(accentColor, Colors.white, 0.2)!],
                ),
                borderRadius: BorderRadius.circular(18),
                boxShadow: [
                  BoxShadow(
                    color: accentColor.withValues(alpha: 0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              alignment: Alignment.center,
              child: const Text(
                '确定',
                style: TextStyle(
                  fontFamily: 'LXGWWenKai',
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                  letterSpacing: 4,
                ),
              ),
            ),
          ),
        ],
      ),
    ),
    ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.1, end: 0, curve: Curves.easeOutCubic);
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
