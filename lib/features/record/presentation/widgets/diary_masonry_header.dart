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

  String _getGreetingMessage(DateTime date, bool isNightMode) {
    final List<String> morningMessages = [
      "晨光微亮，小岛醒来，今天也是美好的一天。",
      "海浪带着清晨的微风，轻抚着沉睡的岛屿。",
      "第一缕阳光落在海面上，去写下新的一页吧。",
    ];

    final List<String> dayMessages = [
      "海风晴朗，适合发呆 and 记录美好。",
      "日光倾城，波光粼粼，小岛的午后慢悠悠的。",
      "翻开日记本，海鸥正在云端呢喃。",
      "云朵在蓝天里散步，风里有海盐汽水的味道。",
    ];

    final List<String> sunsetMessages = [
      "橘红色的落日，是小岛送给你的温柔晚安曲。",
      "晚霞跌落海面，波光中闪烁着今天的记忆。",
      "斜阳脉脉，海风渐凉，整理一下今日的心情吧。",
    ];

    final List<String> nightMessages = [
      "星河滚烫，小岛静谧，今夜的风很温柔。",
      "明月高悬，潮汐起落，悄悄把心事藏进日记里。",
      "夜静静的，海浪在轻吟，祝你今晚有个好梦。",
    ];

    final int seed = date.day + date.month + date.year;
    if (isNightMode) {
      final combined = [...sunsetMessages, ...nightMessages];
      return combined[seed % combined.length];
    } else {
      final combined = [...morningMessages, ...dayMessages, ...sunsetMessages];
      return combined[seed % combined.length];
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeId = UserState().selectedIslandThemeId.value;
    final bool isCottonCandy = themeId == 'cotton_candy';

    final Color themeGoldColor = isNight
        ? const Color(0xFFE1AF78)
        : const Color(0xFFD4A373);

    final Color capsuleTextColor = isNight
        ? const Color(0xFFE1AF78).withValues(alpha: 0.9)
        : const Color(0xFF332F2D); // 暖炭灰色

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
          JellyDateCapsule(
            date: currentDate,
            isNight: isNight,
            themeGoldColor: themeGoldColor,
            capsuleTextColor: capsuleTextColor,
            onTap: onCalendarTap,
          ),
          const SizedBox(width: 12),
          // 天气图标 (根据白天夜晚动态显示太阳与月亮)
          Icon(
            isNight ? Icons.nights_stay_rounded : Icons.wb_sunny_rounded,
            size: 20,
            color: isNight
                ? themeGoldColor
                : (isCottonCandy 
                    ? const Color(0xFFF3B547)
                    : const Color(0xFFF9A826)),
          ),
          const SizedBox(width: 8),
          // 寄语 (随日期哈希动态变化，彻底告别一成不变)
          Expanded(
            child: Text(
              _getGreetingMessage(currentDate, isNight),
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

class JellyDateCapsule extends StatelessWidget {
  final DateTime date;
  final bool isNight;
  final Color themeGoldColor;
  final Color capsuleTextColor;
  final VoidCallback onTap;

  const JellyDateCapsule({
    super.key,
    required this.date,
    required this.isNight,
    required this.themeGoldColor,
    required this.capsuleTextColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final Widget capsuleBody = Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
      decoration: BoxDecoration(
        color: isNight ? const Color(0xFF2C2E30) : Colors.white,
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
            TextSpan(
              children: [
                TextSpan(
                  text: "${date.month}",
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
                  text: "${date.day}",
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
    );

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: capsuleBody,
    );
  }
}
