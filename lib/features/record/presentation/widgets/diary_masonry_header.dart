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
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        "我的岛屿日记",
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: textColor,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Image.asset(
                        'assets/images/icons/leaf.png',
                        width: 20,
                        height: 20,
                        color: const Color(0xFF8B9E7B),
                      ),
                    ],
                  ),
                  Text.rich(
                    TextSpan(
                      text: "$userName 的小岛·第",
                      children: [
                        TextSpan(
                          text: "$islandDays",
                          style: const TextStyle(
                            color: Color(0xFFD4A373),
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                          ),
                        ),
                        const TextSpan(text: "天"),
                      ],
                    ),
                    style: TextStyle(fontSize: 13, color: subTextColor),
                  ),
                ],
              ),
              Row(
                children: [
                  GestureDetector(
                    onTap: onCalendarTap,
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: isNight
                            ? Colors.white.withValues(alpha: 0.1)
                            : Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.05),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Icon(
                        Icons.calendar_today_rounded,
                        size: 18,
                        color: textColor,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),

          const SizedBox(height: 14),

          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 400),
                        transitionBuilder: (Widget child, Animation<double> animation) {
                          final offsetAnimation = Tween<Offset>(
                            begin: const Offset(0.0, 0.4),
                            end: Offset.zero,
                          ).animate(CurvedAnimation(
                            parent: animation,
                            curve: Curves.easeOutBack,
                          ));
                          
                          return FadeTransition(
                            opacity: animation,
                            child: SlideTransition(
                              position: offsetAnimation,
                              child: child,
                            ),
                          );
                        },
                        child: Text.rich(
                          key: ValueKey("${currentDate.year}-${currentDate.month}-${currentDate.day}"),
                          TextSpan(
                            children: [
                              TextSpan(
                                text: "${currentDate.month}",
                                style: TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  color: textColor,
                                ),
                              ),
                              TextSpan(
                                text: "月",
                                style: TextStyle(fontSize: 16, color: textColor),
                              ),
                              TextSpan(
                                text: "${currentDate.day}",
                                style: TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  color: textColor,
                                ),
                              ),
                              TextSpan(
                                text: "日",
                                style: TextStyle(fontSize: 16, color: textColor),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      const Icon(
                        Icons.wb_sunny_rounded,
                        size: 20,
                        color: Color(0xFFF9A826),
                      ),
                    ],
                  ),
                  Text(
                    "海风晴朗，适合发呆和记录美好",
                    style: TextStyle(fontSize: 12, color: subTextColor),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}
