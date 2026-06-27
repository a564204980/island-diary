import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:island_diary/features/record/domain/models/diary_entry.dart';
import 'package:island_diary/shared/widgets/mood_picker/config/mood_config.dart';
import 'package:island_diary/core/state/user_state.dart';
import 'package:island_diary/features/profile/presentation/widgets/export/export_bento_wrapper.dart';

class ExportTrendChart extends StatelessWidget {
  final List<DiaryEntry> diaries;

  const ExportTrendChart({
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
        title: '情绪起伏',
        rightAction: Icon(CupertinoIcons.waveform_path, size: 18, color: Colors.grey),
        child: SizedBox(
          height: 140,
          child: Center(
            child: Text('暂无心情起伏 📈', style: TextStyle(fontSize: 12, color: Colors.grey)),
          ),
        ),
      );
    }

    final Color themeColor = isCottonCandy ? const Color(0xFFFF8E9B) : const Color(0xFFD4A373);
    final Color accentColor = isCottonCandy ? const Color(0xFFF7AAB6) : themeColor;

    int getMoodWeight(int index) {
      switch (index % kMoods.length) {
        case 0:
        case 5:
        case 10:
          return 1;
        case 2:
        case 3:
        case 4:
        case 7:
        case 8:
        case 9:
          return -1;
        default:
          return 0;
      }
    }

    final sortedDiaries = List<DiaryEntry>.from(diaries)
      ..sort((a, b) => a.dateTime.compareTo(b.dateTime));

    final displayDiaries = sortedDiaries.length > 8
        ? sortedDiaries.sublist(sortedDiaries.length - 8)
        : sortedDiaries;

    final List<FlSpot> spots = [];
    final List<Map<String, dynamic>> aggregatedPoints = [];
    for (int i = 0; i < displayDiaries.length; i++) {
      final e = displayDiaries[i];
      final double score = getMoodWeight(e.moodIndex) * e.intensity.toDouble();
      spots.add(FlSpot(i.toDouble(), score));
      
      final List<String> radarIcons = [
        'assets/icons/happy.png',
        'assets/icons/calm.png',
        'assets/icons/down.png',
        'assets/icons/irritated.png',
        'assets/icons/tired.png',
        'assets/icons/surprise.png',
        'assets/icons/shy.png',
        'assets/icons/anxious.png',
        'assets/icons/wronged.png',
        'assets/icons/bored.png',
        'assets/icons/expect.png',
      ];
      final icon = radarIcons[e.moodIndex % kMoods.length];

      aggregatedPoints.add({
        'score': score,
        'label': '${e.dateTime.month}/${e.dateTime.day}',
        'hasData': true,
        'moodIcon': icon,
      });
    }

    int maxIdx = -1, minIdx = -1;
    double maxVal = -double.infinity, minVal = double.infinity;
    for (int i = 0; i < spots.length; i++) {
      if (spots[i].y > maxVal) {
        maxVal = spots[i].y;
        maxIdx = i;
      }
      if (spots[i].y < minVal) {
        minVal = spots[i].y;
        minIdx = i;
      }
    }
    double absMax = [maxVal.abs(), minVal.abs(), 5.0].reduce((a, b) => a > b ? a : b);
    double yLimit = (absMax * 1.3).ceilToDouble();

    // 本地趋势总结
    String summary = '情绪整体偏柔和，后段略有波动。';
    if (spots.length >= 2) {
      final realScores = spots.map((s) => s.y).toList();
      final avg = realScores.reduce((a, b) => a + b) / realScores.length;
      summary = avg > 1.2
          ? '情绪整体偏明亮'
          : (avg < -1.2 ? '情绪整体偏低缓' : '情绪整体偏柔和');
    }

    final barData = LineChartBarData(
      spots: spots,
      isCurved: true,
      curveSmoothness: 0.35,
      gradient: LinearGradient(
        colors: isCottonCandy
            ? const [Color(0xFFFF6E8D), Color(0xFFC69DF3), Color(0xFF8DAEFF)]
            : [themeColor, themeColor.withValues(alpha: 0.5)],
      ),
      barWidth: 3,
      isStrokeCapRound: true,
      dotData: FlDotData(
        show: true,
        getDotPainter: (spot, percent, barData, index) {
          bool isExtreme = (index == maxIdx || index == minIdx) && spots[index].y != 0;
          if (isExtreme) {
            return FlDotCirclePainter(
              radius: 4,
              color: index == maxIdx ? const Color(0xFFFF5252) : const Color(0xFF448AFF),
              strokeWidth: 2.0,
              strokeColor: Colors.white,
            );
          }
          final double t = index / (displayDiaries.length - 1).clamp(1, 999);
          final Color dotColor = Color.lerp(
            const Color(0xFFFF6E8D),
            const Color(0xFF8DAEFF),
            t,
          )!;
          return FlDotCirclePainter(
            radius: 2,
            color: dotColor,
            strokeWidth: 1.0,
            strokeColor: Colors.white,
          );
        },
      ),
      belowBarData: BarAreaData(
        show: true,
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            (isCottonCandy ? const Color(0xFFFFD5DB) : themeColor).withValues(alpha: 0.35),
            (isCottonCandy ? const Color(0xFFFFD5DB) : themeColor).withValues(alpha: 0.0),
          ],
        ),
      ),
    );

    return ExportBentoWrapper(
      title: '情绪起伏',
      rightAction: Icon(
        CupertinoIcons.waveform_path,
        size: 18,
        color: accentColor.withValues(alpha: isNight ? 0.72 : 0.8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            summary,
            style: TextStyle(
              fontSize: 12,
              color: isNight ? Colors.white60 : const Color(0xFF8A7462),
              fontFamily: 'LXGWWenKai',
            ),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: Row(
              children: [
                SizedBox(
                  width: 32,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildExportTrendYLabel(yLimit.toInt().toString(), '愉悦', const Color(0xFFF3A5B6), isNight),
                      _buildExportTrendYLabel('0', '平和', const Color(0xFFD79A64), isNight),
                      _buildExportTrendYLabel((-yLimit).toInt().toString(), '低落', const Color(0xFF78AEEB), isNight),
                      const SizedBox(height: 14),
                    ],
                  ),
                ),
                Expanded(
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final double width = constraints.maxWidth;
                      final double height = constraints.maxHeight;

                      return Stack(
                        children: [
                          Positioned(
                            right: width * 0.15,
                            top: height * 0.05,
                            child: Icon(
                              CupertinoIcons.cloud_fill,
                              size: 26,
                              color: (isCottonCandy ? const Color(0xFFFFD5DB) : themeColor).withValues(alpha: 0.3),
                            ),
                          ),
                          LineChart(
                            LineChartData(
                              minX: -0.3,
                              maxX: displayDiaries.length - 0.7,
                              minY: -yLimit,
                              maxY: yLimit,
                              gridData: FlGridData(
                                show: true,
                                drawVerticalLine: false,
                                getDrawingHorizontalLine: (value) {
                                  if (value == 0) {
                                    return FlLine(
                                      color: isNight ? Colors.white24 : Colors.black.withValues(alpha: 0.08),
                                      strokeWidth: 1.2,
                                    );
                                  }
                                  return FlLine(
                                    color: isNight ? Colors.white10 : Colors.black.withValues(alpha: 0.02),
                                    strokeWidth: 0.8,
                                  );
                                },
                              ),
                              titlesData: FlTitlesData(
                                show: true,
                                topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                                rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                                leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                                bottomTitles: AxisTitles(
                                  sideTitles: SideTitles(
                                    showTitles: true,
                                    reservedSize: 22,
                                    interval: 1,
                                    getTitlesWidget: (value, meta) {
                                      int idx = value.round();
                                      if (idx < 0 || idx >= displayDiaries.length) {
                                        return const SizedBox.shrink();
                                      }
                                      return Padding(
                                        padding: const EdgeInsets.only(top: 6.0),
                                        child: Text(
                                          aggregatedPoints[idx]['label'],
                                          style: TextStyle(
                                            fontSize: 8,
                                            color: isNight ? Colors.white38 : Colors.black54,
                                            fontFamily: 'LXGWWenKai',
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                ),
                              ),
                              borderData: FlBorderData(show: false),
                              lineBarsData: [barData],
                            ),
                            duration: Duration.zero,
                          ),
                          // 极值表情贴纸
                          if (maxIdx != -1 && maxIdx < displayDiaries.length) ...[
                            () {
                              final spot = spots[maxIdx];
                              final iconPath = aggregatedPoints[maxIdx]['moodIcon'] as String;
                              final double spotX = (maxIdx + 0.3) / displayDiaries.length * width;
                              final double spotY = (yLimit - spot.y) / (yLimit * 2) * (height - 20);
                              return Positioned(
                                left: spotX - 10.0,
                                top: spotY.clamp(4.0, height - 25),
                                child: _buildMoodTrendIconStick(iconPath: iconPath, isMax: true),
                              );
                            }(),
                          ],
                          if (minIdx != -1 && minIdx < displayDiaries.length && maxIdx != minIdx) ...[
                            () {
                              final spot = spots[minIdx];
                              final iconPath = aggregatedPoints[minIdx]['moodIcon'] as String;
                              final double spotX = (minIdx + 0.3) / displayDiaries.length * width;
                              final double spotY = (yLimit - spot.y) / (yLimit * 2) * (height - 20);
                              return Positioned(
                                left: spotX - 10.0,
                                top: spotY.clamp(4.0, height - 25),
                                child: _buildMoodTrendIconStick(iconPath: iconPath, isMax: false),
                              );
                            }(),
                          ],
                        ],
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExportTrendYLabel(String val, String text, Color col, bool isNight) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          val,
          style: TextStyle(fontSize: 8, fontWeight: FontWeight.bold, color: isNight ? Colors.white24 : Colors.black38),
        ),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 4,
              height: 4,
              decoration: BoxDecoration(shape: BoxShape.circle, color: col),
            ),
            const SizedBox(width: 2),
            Text(
              text,
              style: TextStyle(fontSize: 7, color: col, fontWeight: FontWeight.bold, fontFamily: 'LXGWWenKai'),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildMoodTrendIconStick({required String iconPath, required bool isMax}) {
    return Container(
      padding: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 3,
            offset: const Offset(0, 1),
          ),
        ],
        border: Border.all(
          color: isMax ? const Color(0xFFFF8E9B) : const Color(0xFF8DAEFF),
          width: 1.0,
        ),
      ),
      child: Image.asset(
        iconPath,
        width: 12,
        height: 12,
        errorBuilder: (_, __, ___) => const SizedBox.shrink(),
      ),
    );
  }
}
