import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:island_diary/features/record/domain/models/diary_entry.dart';
import 'package:island_diary/shared/widgets/mood_picker/config/mood_config.dart';
import 'package:island_diary/core/state/user_state.dart';
import 'package:island_diary/features/profile/presentation/widgets/export/export_bento_wrapper.dart';

class ExportMoodFlowChart extends StatelessWidget {
  final List<DiaryEntry> diaries;

  const ExportMoodFlowChart({
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
        title: '情绪分布趋势',
        rightAction: Icon(CupertinoIcons.graph_circle, size: 18, color: Colors.grey),
        child: SizedBox(
          height: 140,
          child: Center(
            child: Text('暂无分布趋势 📈', style: TextStyle(fontSize: 12, color: Colors.grey)),
          ),
        ),
      );
    }

    final Color themeColor = isCottonCandy ? const Color(0xFFFF8E9B) : const Color(0xFFD4A373);
    final Color accentColor = isCottonCandy ? const Color(0xFFF7AAB6) : themeColor;

    final Map<int, int> moodCounts = {};
    for (var e in diaries) {
      final int moodIndex = e.moodIndex % kMoods.length;
      moodCounts[moodIndex] = (moodCounts[moodIndex] ?? 0) + 1;
    }

    final sortedMoods = moodCounts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    final topMoodIndices = sortedMoods.take(3).map((e) => e.key).toList();

    final sortedDiaries = List<DiaryEntry>.from(diaries)
      ..sort((a, b) => a.dateTime.compareTo(b.dateTime));

    final displayDiaries = sortedDiaries.length > 7
        ? sortedDiaries.sublist(sortedDiaries.length - 7)
        : sortedDiaries;

    final List<LineChartBarData> lineBarsData = [];
    double maxY = 5.0;

    for (int i = 0; i < topMoodIndices.length; i++) {
      final moodIdx = topMoodIndices[i];
      final Color color = kMoods[moodIdx].glowColor ?? Colors.teal;

      final List<FlSpot> spots = [];
      for (int day = 0; day < displayDiaries.length; day++) {
        final entry = displayDiaries[day];
        final double val = (entry.moodIndex % kMoods.length == moodIdx)
            ? entry.intensity.toDouble()
            : 0.0;
        if (val > maxY) maxY = val;
        spots.add(FlSpot(day.toDouble(), val));
      }

      lineBarsData.add(
        LineChartBarData(
          spots: spots,
          isCurved: true,
          color: color.withOpacity(0.8),
          barWidth: 2,
          dotData: FlDotData(
            show: true,
            getDotPainter: (spot, percent, barData, index) => FlDotCirclePainter(
              radius: 2,
              color: color,
              strokeWidth: 0.8,
              strokeColor: Colors.white,
            ),
          ),
          belowBarData: BarAreaData(
            show: true,
            color: color.withOpacity(0.04),
          ),
        ),
      );
    }

    final double displayMaxY = (maxY * 1.2).ceilToDouble();

    return ExportBentoWrapper(
      title: '情绪分布趋势',
      rightAction: Icon(
        CupertinoIcons.graph_circle,
        size: 18,
        color: accentColor.withOpacity(isNight ? 0.72 : 0.8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (topMoodIndices.isNotEmpty) ...[
            Text(
              '近期高频情绪：${kMoods[topMoodIndices.first].label}',
              style: TextStyle(
                fontSize: 10,
                color: isNight ? Colors.white60 : const Color(0xFF9A7A69),
                fontFamily: 'LXGWWenKai',
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 6,
              runSpacing: 4,
              children: topMoodIndices.map((idx) {
                final mood = kMoods[idx];
                final color = mood.glowColor ?? Colors.blueAccent;
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 5,
                        height: 5,
                        decoration: BoxDecoration(color: color, shape: BoxShape.circle),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        mood.label,
                        style: TextStyle(
                          fontSize: 9,
                          color: color,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'LXGWWenKai',
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ],
          const SizedBox(height: 12),
          Expanded(
            child: Row(
              children: [
                SizedBox(
                  width: 20,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(displayMaxY.toInt().toString(), style: TextStyle(fontSize: 8, color: isNight ? Colors.white24 : Colors.black38)),
                      Text((displayMaxY / 2).toInt().toString(), style: TextStyle(fontSize: 8, color: isNight ? Colors.white24 : Colors.black38)),
                      Text('0', style: TextStyle(fontSize: 8, color: isNight ? Colors.white24 : Colors.black38)),
                      const SizedBox(height: 14),
                    ],
                  ),
                ),
                Expanded(
                  child: LineChart(
                    LineChartData(
                      minX: -0.2,
                      maxX: displayDiaries.length.toDouble() - 0.8,
                      minY: 0,
                      maxY: displayMaxY,
                      gridData: FlGridData(
                        show: true,
                        drawVerticalLine: false,
                        getDrawingHorizontalLine: (value) => FlLine(
                          color: isNight ? Colors.white10 : Colors.black.withOpacity(0.03),
                          strokeWidth: 0.8,
                        ),
                      ),
                      titlesData: FlTitlesData(
                        show: true,
                        topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 18,
                            getTitlesWidget: (value, meta) {
                              int index = value.round();
                              if (index >= 0 && index < displayDiaries.length) {
                                final d = displayDiaries[index].dateTime;
                                return Text(
                                  '${d.month}/${d.day}',
                                  style: TextStyle(
                                    fontSize: 8, 
                                    color: isNight ? Colors.white30 : Colors.black54,
                                    fontFamily: 'LXGWWenKai',
                                  ),
                                );
                              }
                              return const SizedBox.shrink();
                            },
                          ),
                        ),
                      ),
                      borderData: FlBorderData(show: false),
                      lineBarsData: lineBarsData,
                    ),
                    duration: Duration.zero,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
