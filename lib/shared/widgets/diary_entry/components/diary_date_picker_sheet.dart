import 'dart:ui';
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

  @override
  void initState() {
    super.initState();
    _selectedDate = widget.initialDate;
  }

  @override
  Widget build(BuildContext context) {
    final bool isNight = UserState().isNight;
    final Color accentColor = DiaryUtils.getAccentColor(widget.paperStyle, isNight);
    final Color inkColor = DiaryUtils.getInkColor(widget.paperStyle, isNight);

    return DiaryBottomSheet(
      paperStyle: widget.paperStyle,
      isDiary: false,
      showDragHandle: true,
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 12,
        bottom: 24 + MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '选择日期',
            style: TextStyle(
              fontFamily: 'LXGWWenKai',
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: accentColor,
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 200,
            child: CupertinoTheme(
              data: CupertinoThemeData(
                textTheme: CupertinoTextThemeData(
                  dateTimePickerTextStyle: TextStyle(
                    fontFamily: 'LXGWWenKai',
                    fontSize: 20,
                    color: inkColor.withValues(alpha: 0.9),
                  ),
                ),
              ),
              child: CupertinoDatePicker(
                mode: CupertinoDatePickerMode.date,
                initialDateTime: widget.initialDate,
                maximumDate: DateTime.now().add(const Duration(minutes: 5)),
                minimumDate: DateTime(2000),
                onDateTimeChanged: (DateTime newDateTime) {
                  setState(() {
                    _selectedDate = newDateTime;
                  });
                },
              ),
            ),
          ),
          const SizedBox(height: 32),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => widget.onConfirm(_selectedDate),
              style: ElevatedButton.styleFrom(
                backgroundColor: accentColor,
                foregroundColor: Colors.white,
                elevation: 4,
                shadowColor: accentColor.withValues(alpha: 0.3),
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                ),
              ),
              child: const Text(
                '确认日期',
                style: TextStyle(
                  fontFamily: 'LXGWWenKai',
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 2.0,
                ),
              ),
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.1, end: 0, curve: Curves.easeOutCubic);
  }
}
