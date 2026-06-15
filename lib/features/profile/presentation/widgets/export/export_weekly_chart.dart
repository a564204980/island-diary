import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:island_diary/features/record/domain/models/diary_entry.dart';
import 'package:island_diary/core/state/user_state.dart';
import 'package:island_diary/features/profile/presentation/widgets/export/export_bento_wrapper.dart';

class ExportWeeklyChart extends StatelessWidget {
  final List<DiaryEntry> diaries;

  const ExportWeeklyChart({
    super.key,
    required this.diaries,
  });

  @override
  Widget build(BuildContext context) {
    final bool isNight = UserState().isNight;
    final String themeId = UserState().selectedIslandThemeId.value;
    final bool isCottonCandy = themeId == 'cotton_candy';

    if (diaries.isEmpty) {
      return const ExportBentoWrapper(
        title: '周活动规律',
        rightAction: Icon(CupertinoIcons.calendar_today, size: 16, color: Colors.grey),
        child: SizedBox(
          height: 140,
          child: Center(
            child: Text('暂无周度数据 📊', style: TextStyle(fontSize: 12, color: Colors.grey)),
          ),
        ),
      );
    }

    final Color themeColor = isCottonCandy ? const Color(0xFFFF8E9B) : const Color(0xFFD4A373);

    List<double> dayIntensities = List.filled(7, 0.0);
    List<int> dayCounts = List.filled(7, 0);
    for (var entry in diaries) {
      int w = entry.dateTime.weekday - 1; // 0=Mon, 6=Sun
      if (w >= 0 && w < 7) {
        dayIntensities[w] += entry.intensity;
        dayCounts[w]++;
      }
    }

    List<double> averages = List.generate(7, (i) => dayCounts[i] > 0 ? (dayIntensities[i] / dayCounts[i]) : 0);
    double maxAvg = averages.reduce(max);

    return ExportBentoWrapper(
      title: '周活动规律',
      rightAction: Icon(
        CupertinoIcons.calendar_today,
        size: 16,
        color: isCottonCandy ? const Color(0xFFAE9584) : themeColor,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final double height = constraints.maxHeight;

                return Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: List.generate(7, (index) {
                    final days = ['一', '二', '三', '四', '五', '六', '日'];
                    double h = maxAvg > 0 ? (averages[index] / maxAvg) * (height - 35).clamp(10, 500) : 0;
                    bool hasData = dayCounts[index] > 0;

                    return Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        if (hasData)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 4.0),
                            child: Text(
                              averages[index].toStringAsFixed(1),
                              style: TextStyle(
                                fontSize: 8,
                                fontWeight: FontWeight.bold,
                                color: isNight ? Colors.white38 : const Color(0xFF6C7A89),
                              ),
                            ),
                          )
                        else
                          const SizedBox(height: 12),
                        Container(
                          width: 14,
                          height: hasData ? 8 + h : 5,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(6),
                            gradient: hasData
                                ? LinearGradient(
                                    begin: Alignment.bottomCenter,
                                    end: Alignment.topCenter,
                                    colors: isCottonCandy
                                        ? const [Color(0xFFFF8E9B), Color(0xFFFFB2A6)]
                                        : [themeColor, themeColor.withOpacity(0.5)],
                                  )
                                : null,
                            color: hasData ? null : (isNight ? Colors.white12 : Colors.black.withOpacity(0.04)),
                            boxShadow: hasData
                                ? [
                                    BoxShadow(
                                      color: themeColor.withOpacity(0.3),
                                      blurRadius: 4,
                                      offset: const Offset(0, 2),
                                    )
                                  ]
                                : null,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          days[index],
                          style: TextStyle(
                            fontSize: 10,
                            color: isNight ? Colors.white54 : Colors.black45,
                            fontFamily: 'LXGWWenKai',
                          ),
                        ),
                      ],
                    );
                  }),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
