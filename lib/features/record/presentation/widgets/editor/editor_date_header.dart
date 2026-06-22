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
    final String dayStr = dateTime.day.toString();
    final String yearMonthStr = "${dateTime.year}年${dateTime.month}月";
    final String weekTimeStr = "${_getChineseWeekDay(dateTime.weekday)}  ${DateFormat('HH:mm').format(dateTime)}";

    return GestureDetector(
      onTap: onDateTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        margin: const EdgeInsets.only(top: 2, bottom: 8),
        padding: const EdgeInsets.only(top: 4, bottom: 0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // 大日历天数数字
            Text(
              dayStr,
              style: TextStyle(
                fontSize: 68,
                fontWeight: FontWeight.w500,
                color: DiaryUtils.getInkColor(paperStyle, isNight),
                fontFamily: 'Georgia',
                height: 1.0,
              ),
            ),
            const SizedBox(width: 14),
            // 右侧两行小字日期时间
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  yearMonthStr,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: DiaryUtils.getInkColor(paperStyle, isNight).withValues(alpha: 0.6),
                    fontFamily: 'LXGWWenKai',
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text(
                      weekTimeStr,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: DiaryUtils.getInkColor(paperStyle, isNight).withValues(alpha: 0.8),
                        fontFamily: 'LXGWWenKai',
                      ),
                    ),
                    const SizedBox(width: 4),
                    Icon(
                      Icons.keyboard_arrow_down_rounded,
                      size: 18,
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
