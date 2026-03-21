import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class DiaryTimePickerSheet extends StatefulWidget {
  final TimeOfDay initialTime;
  final ValueChanged<TimeOfDay> onConfirm;

  const DiaryTimePickerSheet({
    super.key,
    required this.initialTime,
    required this.onConfirm,
  });

  @override
  State<DiaryTimePickerSheet> createState() => _DiaryTimePickerSheetState();
}

class _DiaryTimePickerSheetState extends State<DiaryTimePickerSheet> {
  late TimeOfDay _selectedTime;

  @override
  void initState() {
    super.initState();
    _selectedTime = widget.initialTime;
  }

  @override
  Widget build(BuildContext context) {
    // CupertinoDatePicker uses DateTime, so we convert TimeOfDay
    final now = DateTime.now();
    final initialDateTime = DateTime(
      now.year,
      now.month,
      now.day,
      widget.initialTime.hour,
      widget.initialTime.minute,
    );

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
            '选择时间',
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
                mode: CupertinoDatePickerMode.time,
                initialDateTime: initialDateTime,
                use24hFormat: true,
                onDateTimeChanged: (DateTime newDateTime) {
                  setState(() {
                    _selectedTime = TimeOfDay(
                      hour: newDateTime.hour,
                      minute: newDateTime.minute,
                    );
                  });
                },
              ),
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => widget.onConfirm(_selectedTime),
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
