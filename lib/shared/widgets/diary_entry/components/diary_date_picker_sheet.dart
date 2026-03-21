import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class DiaryDatePickerSheet extends StatefulWidget {
  final DateTime initialDate;
  final ValueChanged<DateTime> onConfirm;

  const DiaryDatePickerSheet({
    super.key,
    required this.initialDate,
    required this.onConfirm,
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
    return Container(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 24,
        bottom: 24 + MediaQuery.of(context).viewInsets.bottom,
      ),
      decoration: const BoxDecoration(
        color: Color(0xFFFDF7E9),
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(28),
          topRight: Radius.circular(28),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            '选择日期',
            style: TextStyle(
              fontFamily: 'LXGWWenKai',
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Color(0xFF8B5E3C),
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 200,
            child: CupertinoTheme(
              data: const CupertinoThemeData(
                textTheme: CupertinoTextThemeData(
                  dateTimePickerTextStyle: TextStyle(
                    fontFamily: 'LXGWWenKai',
                    fontSize: 20,
                    color: Color(0xFF8B5E3C),
                  ),
                ),
              ),
              child: CupertinoDatePicker(
                mode: CupertinoDatePickerMode.date,
                initialDateTime: widget.initialDate,
                onDateTimeChanged: (DateTime newDate) {
                  setState(() => _selectedDate = newDate);
                },
              ),
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => widget.onConfirm(_selectedDate),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF8B5E3C),
                foregroundColor: Colors.white,
                elevation: 0,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: const Text(
                '确认',
                style: TextStyle(
                  fontFamily: 'LXGWWenKai',
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
