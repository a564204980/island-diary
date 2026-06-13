import 'package:flutter/material.dart';
import 'package:island_diary/shared/widgets/diary_entry/utils/diary_utils.dart';
import 'package:intl/intl.dart';

class EditorDateHeader extends StatelessWidget {
  final DateTime dateTime;
  final String paperStyle;
  final bool isNight;
  final VoidCallback onDateTap;

  const EditorDateHeader({
    super.key,
    required this.dateTime,
    required this.paperStyle,
    required this.isNight,
    required this.onDateTap,
  });

  @override
  Widget build(BuildContext context) {
    final Color inkColor = DiaryUtils.getInkColor(paperStyle, isNight);
    final String dayStr = dateTime.day.toString().padLeft(2, '0');
    final String yearMonthStr = DateFormat('yyyy年M月').format(dateTime);
    final String weekTimeStr = "${_getChineseWeekDay(dateTime.weekday)}  ${DateFormat('HH:mm').format(dateTime)}";

    return GestureDetector(
      onTap: onDateTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        margin: const EdgeInsets.only(top: 8, bottom: 12),
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // 大日历天数数字
            Text(
              dayStr,
              style: TextStyle(
                fontSize: 38,
                fontWeight: FontWeight.bold,
                color: isNight ? Colors.white.withValues(alpha: 0.9) : inkColor.withValues(alpha: 0.95),
                fontFamily: 'LXGWWenKai',
                height: 1.0,
              ),
            ),
            const SizedBox(width: 12),
            // 右侧两行小字日期时间
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  yearMonthStr,
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.bold,
                    color: isNight ? Colors.white70 : inkColor.withValues(alpha: 0.75),
                    fontFamily: 'LXGWWenKai',
                  ),
                ),
                const SizedBox(height: 3),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text(
                      weekTimeStr,
                      style: TextStyle(
                        fontSize: 11,
                        color: isNight ? Colors.white60 : inkColor.withValues(alpha: 0.55),
                        fontFamily: 'LXGWWenKai',
                      ),
                    ),
                    const SizedBox(width: 3),
                    Icon(
                      Icons.keyboard_arrow_down_rounded,
                      size: 13,
                      color: isNight ? Colors.white30 : inkColor.withValues(alpha: 0.4),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _getChineseWeekDay(int weekday) {
    const weeks = ["星期一", "星期二", "星期三", "星期四", "星期五", "星期六", "星期日"];
    return weeks[weekday - 1];
  }
}
