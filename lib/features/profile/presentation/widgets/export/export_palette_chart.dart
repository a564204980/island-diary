import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:island_diary/features/record/domain/models/diary_entry.dart';
import 'package:island_diary/shared/widgets/mood_picker/config/mood_config.dart';
import 'package:island_diary/core/state/user_state.dart';
import 'package:island_diary/features/profile/presentation/widgets/export/export_bento_wrapper.dart';

class ExportPaletteChart extends StatelessWidget {
  final List<DiaryEntry> diaries;

  const ExportPaletteChart({
    super.key,
    required this.diaries,
  });

  @override
  Widget build(BuildContext context) {
    final bool isNight = UserState().isNight;
    final String themeId = UserState().selectedIslandThemeId.value;
    final bool isCottonCandy = themeId == 'cotton_candy';

    final sortedDiaries = List<DiaryEntry>.from(diaries)
      ..sort((a, b) => a.dateTime.compareTo(b.dateTime));
    
    final now = DateTime.now();
    final List<DiaryEntry> monthDiaries = sortedDiaries
        .where((e) => e.dateTime.year == now.year && e.dateTime.month == now.month)
        .toList();

    if (monthDiaries.isEmpty) {
      return const ExportBentoWrapper(
        title: '时光调色盘',
        rightAction: Icon(CupertinoIcons.color_filter, size: 16, color: Colors.grey),
        child: SizedBox(
          height: 140,
          child: Center(
            child: Text('暂无本月心情数据 🎨', style: TextStyle(fontSize: 12, color: Colors.grey)),
          ),
        ),
      );
    }

    final Color themeColor = isCottonCandy ? const Color(0xFFFF8E9B) : const Color(0xFFD4A373);
    final int recordDays = monthDiaries.map((e) => e.dateTime.day).toSet().length;
    final Set<int> uniqueMoods = monthDiaries.map((e) => e.moodIndex % kMoods.length).toSet();
    final int moodColorCount = uniqueMoods.length;

    return ExportBentoWrapper(
      title: '时光调色盘',
      rightAction: Icon(
        CupertinoIcons.color_filter,
        size: 16,
        color: isCottonCandy ? const Color(0xFFAE9584) : themeColor,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            height: 95,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: 38,
                  child: Text(
                    "把本月的心情，\n调成一款独一无二\n的\n灵魂画布。",
                    style: TextStyle(
                      fontSize: 11,
                      height: 1.4,
                      color: isNight ? Colors.white60 : const Color(0xFF8A6C5C),
                      fontFamily: 'LXGWWenKai',
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  flex: 62,
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final double width = constraints.maxWidth;
                      final double height = constraints.maxHeight;

                      const int rowCount = 7;
                      final double cellSize = (height / rowCount) - 1.5;
                      final int totalCols = (width / cellSize).floor().clamp(1, 20);

                      return Stack(
                        clipBehavior: Clip.none,
                        children: [
                          Positioned.fill(
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(10),
                              child: Align(
                                alignment: Alignment.centerRight,
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: List.generate(totalCols, (colIdx) {
                                    return Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: List.generate(rowCount, (rowIdx) {
                                        final int itemIdx = colIdx * rowCount + rowIdx;
                                        if (itemIdx >= monthDiaries.length) {
                                          return Container(
                                            width: cellSize,
                                            height: cellSize,
                                            decoration: BoxDecoration(
                                              color: isNight 
                                                  ? Colors.white.withValues(alpha: 0.04) 
                                                  : const Color(0xFFFFEDE7).withValues(alpha: 0.45),
                                              border: Border.all(
                                                color: isNight 
                                                    ? Colors.white.withValues(alpha: 0.05) 
                                                    : const Color(0xFFF8DDD5).withValues(alpha: 0.35),
                                                width: 0.4,
                                              ),
                                            ),
                                          );
                                        }

                                        final item = monthDiaries[itemIdx];
                                        final color = _getMoodColor(item.moodIndex % kMoods.length);

                                        return Container(
                                          width: cellSize,
                                          height: cellSize,
                                          decoration: BoxDecoration(
                                            gradient: LinearGradient(
                                              begin: Alignment.topLeft,
                                              end: Alignment.bottomRight,
                                              colors: [
                                                color,
                                                Color.lerp(color, Colors.black, 0.08) ?? color,
                                              ],
                                            ),
                                          ),
                                        );
                                      }),
                                    );
                                  }),
                                ),
                              ),
                            ),
                          ),
                          Positioned(
                            left: width * 0.28,
                            top: height * 0.1,
                            child: Icon(
                              Icons.cloud,
                              size: 14,
                              color: isNight ? Colors.white24 : const Color(0xFFC5CAE9).withValues(alpha: 0.9),
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '$recordDays 天记录 · $moodColorCount 种情绪色',
                style: TextStyle(
                  fontSize: 10.5,
                  fontWeight: FontWeight.bold,
                  color: isNight ? Colors.white38 : const Color(0xFFB09587),
                  fontFamily: 'LXGWWenKai',
                ),
              ),
              Wrap(
                spacing: 6,
                children: uniqueMoods.map((moodIdx) {
                  final color = _getMoodColor(moodIdx % kMoods.length);
                  return Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: color,
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Color _getMoodColor(int moodIndex) {
    switch (moodIndex % 11) {
      case 0: return const Color(0xFFFFB2A6);
      case 1: return const Color(0xFFC7E5C7);
      case 2: return const Color(0xFFA9D8EB);
      case 3: return const Color(0xFFFF8E9B);
      case 4: return const Color(0xFFD9B9E7);
      case 5: return const Color(0xFFFFE0A3);
      case 6: return const Color(0xFFF9B7FF);
      case 7: return const Color(0xFFB0BEC5);
      case 8: return const Color(0xFFB3E5FC);
      case 9: return const Color(0xFFD7CCC8);
      case 10: return const Color(0xFFFFF59D);
      default: return Colors.grey;
    }
  }
}
