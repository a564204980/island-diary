import 'package:flutter/material.dart';

class DiaryMasonryHeader extends StatelessWidget {
  final bool isNight;
  final String userName;
  final int islandDays;
  final DateTime currentDate;
  final VoidCallback onCalendarTap;

  const DiaryMasonryHeader({
    super.key,
    this.isNight = false,
    required this.userName,
    required this.islandDays,
    required this.currentDate,
    required this.onCalendarTap,
  });

  @override
  Widget build(BuildContext context) {
    final textColor = isNight
        ? Colors.white.withValues(alpha: 0.9)
        : const Color(0xFF060606);
    final subTextColor = isNight
        ? Colors.white54
        : Colors.black.withValues(alpha: 0.8);

    return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
        child: Row(
          children: [
            // 日期胶囊
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: isNight 
                  ? Colors.white.withValues(alpha: 0.1) 
                  : Colors.black.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isNight 
                    ? Colors.white.withValues(alpha: 0.1) 
                    : Colors.transparent,
                  width: 1,
                ),
              ),
              child: Text.rich(
                key: ValueKey("${currentDate.year}-${currentDate.month}-${currentDate.day}"),
                TextSpan(
                  children: [
                    TextSpan(
                      text: "${currentDate.month}",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: textColor,
                      ),
                    ),
                    TextSpan(
                      text: "月",
                      style: TextStyle(fontSize: 12, color: textColor),
                    ),
                    TextSpan(
                      text: "${currentDate.day}",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: textColor,
                      ),
                    ),
                    TextSpan(
                      text: "日",
                      style: TextStyle(fontSize: 12, color: textColor),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 12),
            // 天气图标
            const Icon(
              Icons.wb_sunny_rounded,
              size: 20,
              color: Color(0xFFF9A826),
            ),
            const SizedBox(width: 8),
            // 寄语
            Expanded(
              child: Text(
                "海风晴朗，适合发呆和记录美好",
                style: TextStyle(
                  fontSize: 12, 
                  color: subTextColor,
                  fontFamily: 'LXGWWenKai',
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
      ),
    );
  }
}
