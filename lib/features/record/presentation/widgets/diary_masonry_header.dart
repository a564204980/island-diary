import 'package:flutter/material.dart';
import 'package:island_diary/core/state/user_state.dart';

class DiaryMasonryHeader extends StatelessWidget {
  final bool isNight;
  final String userName;
  final int islandDays;
  final DateTime currentDate;
  final VoidCallback onCalendarTap;
  final VoidCallback? onDecorateTap;
  final bool showDecorateIcon;

  const DiaryMasonryHeader({
    super.key,
    this.isNight = false,
    required this.userName,
    required this.islandDays,
    required this.currentDate,
    required this.onCalendarTap,
    this.onDecorateTap,
    this.showDecorateIcon = true,
  });

  @override
  Widget build(BuildContext context) {
    final themeId = UserState().selectedIslandThemeId.value;
    final bool isCottonCandy = themeId == 'cotton_candy';

    final Color themeGoldColor = isNight
        ? const Color(0xFFE1AF78)
        : const Color(0xFFD4A373);

    final Color capsuleTextColor = isNight
        ? const Color(0xFFE1AF78).withValues(alpha: 0.9)
        : const Color(0xFF5C4E43); // 暖深咖啡褐色，契合图1

    final subTextColor = isCottonCandy
        ? (isNight ? Colors.white54 : const Color(0xFF6F5E63))
        : (isNight
            ? Colors.white54
            : Colors.black.withValues(alpha: 0.8));

    return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
        child: Row(
          children: [
            // 日期胶囊
            GestureDetector(
              onTap: onCalendarTap,
              behavior: HitTestBehavior.opaque,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                decoration: BoxDecoration(
                  color: isNight 
                    ? const Color(0xFF2C2E30) 
                    : Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isNight 
                      ? Colors.white.withValues(alpha: 0.08) 
                      : const Color(0xFFD4A373).withValues(alpha: 0.22),
                    width: 1,
                  ),
                  boxShadow: isNight 
                    ? null 
                    : [
                        BoxShadow(
                          color: const Color(0xFFD4A373).withValues(alpha: 0.06),
                          blurRadius: 8,
                          offset: const Offset(0, 3),
                        ),
                      ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.calendar_today_rounded,
                      size: 14,
                      color: themeGoldColor,
                    ),
                    const SizedBox(width: 7),
                    Text.rich(
                      key: ValueKey("${currentDate.year}-${currentDate.month}-${currentDate.day}"),
                      TextSpan(
                        children: [
                          TextSpan(
                            text: "${currentDate.month}",
                            style: TextStyle(
                              fontSize: 14.5,
                              fontWeight: FontWeight.w900,
                              color: capsuleTextColor,
                              fontFamily: 'LXGWWenKai',
                            ),
                          ),
                          TextSpan(
                            text: "月",
                            style: TextStyle(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w900,
                              color: capsuleTextColor,
                              fontFamily: 'LXGWWenKai',
                            ),
                          ),
                          TextSpan(
                            text: "${currentDate.day}",
                            style: TextStyle(
                              fontSize: 14.5,
                              fontWeight: FontWeight.w900,
                              color: capsuleTextColor,
                              fontFamily: 'LXGWWenKai',
                            ),
                          ),
                          TextSpan(
                            text: "日",
                            style: TextStyle(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w900,
                              color: capsuleTextColor,
                              fontFamily: 'LXGWWenKai',
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 12),
            // 天气图标
            Icon(
              Icons.wb_sunny_rounded,
              size: 20,
              color: isCottonCandy 
                ? const Color(0xFFF3B547)
                : const Color(0xFFF9A826),
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
            const SizedBox(width: 12),
            // 装扮按钮
            if (showDecorateIcon)
              GestureDetector(
                onTap: onDecorateTap,
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: isNight 
                      ? Colors.white.withValues(alpha: 0.1) 
                      : Colors.black.withValues(alpha: 0.05),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.auto_fix_high_rounded,
                    size: 20,
                    color: isNight 
                      ? Colors.amber.withValues(alpha: 0.8) 
                      : const Color(0xFFD4A373),
                  ),
                ),
              ),
          ],
      ),
    );
  }
}
