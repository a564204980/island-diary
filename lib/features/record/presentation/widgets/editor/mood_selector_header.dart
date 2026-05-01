import 'package:flutter/material.dart';
import 'package:island_diary/shared/widgets/diary_entry/utils/diary_utils.dart';

class MoodSelectorHeader extends StatelessWidget {
  final int? currentMoodIndex;
  final Function(int) onMoodSelected;
  final String paperStyle;
  final bool isNight;

  const MoodSelectorHeader({
    super.key,
    required this.currentMoodIndex,
    required this.onMoodSelected,
    required this.paperStyle,
    required this.isNight,
  });

  static const List<Map<String, String>> moods = [
    {'label': '开心', 'icon': 'assets/icons/happy.png', 'color': '0xFFFFE484'},
    {'label': '平静', 'icon': 'assets/icons/calm.png', 'color': '0xFFA4D4E4'},
    {'label': '低落', 'icon': 'assets/icons/down.png', 'color': '0xFF84A4E4'},
    {'label': '烦躁', 'icon': 'assets/icons/irritated.png', 'color': '0xFFFF8484'},
    {'label': '疲惫', 'icon': 'assets/icons/tired.png', 'color': '0xFFC4A4E4'},
  ];

  @override
  Widget build(BuildContext context) {
    final Color inkColor = DiaryUtils.getInkColor(paperStyle, isNight);
    final bool isDark = isNight;

    return Container(
      margin: const EdgeInsets.fromLTRB(0, 8, 0, 24),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withValues(alpha: 0.05) : const Color(0xFFFEF9F0),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: inkColor.withValues(alpha: isDark ? 0.1 : 0.08),
          width: 1,
        ),
        boxShadow: [
          if (!isDark)
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 14.0, horizontal: 20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  "此刻心情",
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: inkColor.withValues(alpha: 0.8),
                    fontFamily: 'LXGWWenKai',
                  ),
                ),
                const SizedBox(width: 4),
                Icon(
                  Icons.auto_awesome_rounded,
                  size: 12,
                  color: inkColor.withValues(alpha: 0.4),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              "选一个最接近的心情吧",
              style: TextStyle(
                fontSize: 12,
                color: inkColor.withValues(alpha: 0.4),
                fontFamily: 'LXGWWenKai',
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: List.generate(moods.length, (index) {
                final mood = moods[index];
                final bool isSelected = currentMoodIndex == index;
                final Color moodColor = Color(int.parse(mood['color']!));

                return Expanded(
                  child: GestureDetector(
                    onTap: () => onMoodSelected(index),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeOutCubic,
                      margin: const EdgeInsets.symmetric(horizontal: 2),
                      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
                      decoration: BoxDecoration(
                        color: isDark 
                            ? Colors.white.withValues(alpha: isSelected ? 0.15 : 0.05) 
                            : Colors.white.withValues(alpha: isSelected ? 1.0 : 0.6),
                        borderRadius: BorderRadius.circular(32),
                        border: Border.all(
                          color: isSelected 
                              ? moodColor.withValues(alpha: 0.3) 
                              : inkColor.withValues(alpha: 0.05),
                          width: 1,
                        ),
                        boxShadow: [
                          if (isSelected && !isDark)
                            BoxShadow(
                              color: moodColor.withValues(alpha: 0.12),
                              blurRadius: 12,
                              offset: const Offset(0, 6),
                            ),
                        ],
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: RadialGradient(
                                colors: [
                                  moodColor.withValues(alpha: 0.4),
                                  moodColor.withValues(alpha: 0.1),
                                  Colors.transparent,
                                ],
                                stops: const [0.5, 0.9, 1.0],
                              ),
                            ),
                            child: Center(
                              child: Image.asset(
                                mood['icon']!,
                                width: 28,
                                height: 28,
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Text(
                              mood['label']!,
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                color: isSelected ? moodColor : inkColor.withValues(alpha: 0.5),
                                fontFamily: 'LXGWWenKai',
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }),
            ),
            const SizedBox(height: 20),
            // 底部提示
            Center(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _buildDashLine(inkColor, width: 20),
                    const SizedBox(width: 8),
                    Icon(
                      Icons.eco_rounded,
                      size: 14,
                      color: inkColor.withValues(alpha: 0.5),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      "先记录此刻的感受，再慢慢写下今天的故事",
                      style: TextStyle(
                        fontSize: 12,
                        color: inkColor.withValues(alpha: 0.5),
                        fontFamily: 'LXGWWenKai',
                      ),
                    ),
                    const SizedBox(width: 8),
                    _buildDashLine(inkColor, width: 20),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDashLine(Color color, {double width = 30}) {
    return Container(
      width: width,
      height: 1,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.transparent,
            color.withValues(alpha: 0.1),
            Colors.transparent,
          ],
        ),
      ),
    );
  }
}
