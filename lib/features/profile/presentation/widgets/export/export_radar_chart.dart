import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:island_diary/features/record/domain/models/diary_entry.dart';
import 'package:island_diary/shared/widgets/mood_picker/config/mood_config.dart';
import 'package:island_diary/core/state/user_state.dart';
import 'package:island_diary/features/profile/presentation/widgets/export/export_bento_wrapper.dart';

class _ExportRadarIntensityData {
  final int moodIndex;
  final String label;
  final double avgIntensity;
  final Color glowColor;
  final String? iconPath;
  final bool isNegative;

  _ExportRadarIntensityData({
    required this.moodIndex,
    required this.label,
    required this.avgIntensity,
    required this.glowColor,
    this.iconPath,
    required this.isNegative,
  });
}

class ExportRadarChart extends StatelessWidget {
  final List<DiaryEntry> diaries;

  const ExportRadarChart({
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
        title: '心境雷达',
        rightAction: Icon(CupertinoIcons.compass, size: 18, color: Colors.grey),
        child: SizedBox(
          height: 160,
          child: Center(
            child: Text('暂无日记数据 🎨', style: TextStyle(fontSize: 12, color: Colors.grey)),
          ),
        ),
      );
    }

    final Color themeColor = isCottonCandy ? const Color(0xFFFF8E9B) : const Color(0xFFD4A373);
    final Color accentColor = isCottonCandy ? const Color(0xFFF7AAB6) : themeColor;

    // 数据聚合
    final Map<int, List<double>> moodIndexToIntensities = {};
    for (int i = 0; i < kMoods.length; i++) {
      moodIndexToIntensities[i] = <double>[];
    }
    for (var e in diaries) {
      final int moodIndex = e.moodIndex % kMoods.length;
      moodIndexToIntensities[moodIndex]?.add(e.intensity.toDouble());
    }

    final Map<int, int> moodCounts = {};
    for (var e in diaries) {
      final int moodIndex = e.moodIndex % kMoods.length;
      moodCounts[moodIndex] = (moodCounts[moodIndex] ?? 0) + 1;
    }

    final List<_ExportRadarIntensityData> chartData = [];
    for (int moodIndex = 0; moodIndex < kMoods.length; moodIndex++) {
      final intensities = moodIndexToIntensities[moodIndex] ?? const <double>[];
      final avg = intensities.isEmpty
          ? 0.0
          : intensities.reduce((a, b) => a + b) / intensities.length;
      final mood = kMoods[moodIndex];
      final color = mood.glowColor ?? Colors.blueAccent;
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
      final icon = radarIcons[moodIndex % kMoods.length];
      final negative = [2, 3, 4, 7, 8, 9].contains(moodIndex % kMoods.length);

      chartData.add(
        _ExportRadarIntensityData(
          moodIndex: moodIndex,
          label: mood.label,
          avgIntensity: avg,
          glowColor: color,
          iconPath: icon,
          isNegative: negative,
        ),
      );
    }

    final _ExportRadarIntensityData? strongestMood = chartData
        .where((item) => item.avgIntensity > 0)
        .fold<_ExportRadarIntensityData?>(null, (best, item) {
      if (best == null) return item;
      if (item.avgIntensity > best.avgIntensity) return item;
      return best;
    });

    final int? mostCommonMoodIndex = moodCounts.entries.isEmpty
        ? null
        : moodCounts.entries.reduce((a, b) => a.value >= b.value ? a : b).key;
    final String summaryText = strongestMood == null
        ? '这段时间的心情分布还比较平均。'
        : '本期最强：${strongestMood.label}'
            '${mostCommonMoodIndex != null ? '，出现最多：${kMoods[mostCommonMoodIndex].label}' : ''}';

    // 常用标签统计
    final Map<String, int> tagCounts = {};
    for (var e in diaries) {
      if (e.tag != null && e.tag!.isNotEmpty) {
        tagCounts[e.tag!] = (tagCounts[e.tag!] ?? 0) + 1;
      }
    }
    final sortedTags = tagCounts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return ExportBentoWrapper(
      title: '心境雷达',
      rightAction: Icon(
        CupertinoIcons.compass,
        size: 18,
        color: accentColor.withValues(alpha: isNight ? 0.72 : 0.8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            summaryText,
            style: TextStyle(
              fontSize: 12,
              height: 1.3,
              fontWeight: FontWeight.w500,
              color: isNight
                  ? Colors.white60
                  : (isCottonCandy
                      ? const Color(0xFFB28D7B)
                      : const Color(0xFF6D5A4B)),
              fontFamily: 'LXGWWenKai',
            ),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final double size = min(constraints.maxWidth, constraints.maxHeight);
                final double radius = size / 4.8;
                final Offset center = Offset(constraints.maxWidth / 2, constraints.maxHeight / 2);
                final int n = chartData.length;

                return Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Positioned.fill(
                      child: CustomPaint(
                        painter: _ExportRadarPainter(
                          data: chartData,
                          isNight: isNight,
                          radius: radius,
                          themeColor: themeColor,
                          center: center,
                        ),
                      ),
                    ),
                    ...List.generate(n, (i) {
                      double angle = (2 * pi / n) * i - pi / 2;
                      double labelR = radius + 24;
                      double lx = center.dx + labelR * cos(angle);
                      double ly = center.dy + labelR * sin(angle);

                      final item = chartData[i];
                      const double fontSize = 9.0;
                      const double iconSize = 16.0;

                      return Positioned(
                        left: lx - 25,
                        top: ly - 20,
                        width: 50,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (item.iconPath != null && item.avgIntensity > 0)
                              Image.asset(
                                item.iconPath!,
                                width: iconSize,
                                height: iconSize,
                                errorBuilder: (_, _, _) => const SizedBox(),
                              ),
                            const SizedBox(height: 2),
                            Text(
                              item.label,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: fontSize,
                                fontWeight: FontWeight.bold,
                                color: isNight
                                    ? Colors.white70
                                    : (isCottonCandy
                                        ? const Color(0xFF9A7A69)
                                        : const Color(0xFF5A3E28)),
                                fontFamily: 'LXGWWenKai',
                              ),
                            ),
                          ],
                        ),
                      );
                    }),
                  ],
                );
              },
            ),
          ),
          if (sortedTags.isNotEmpty) ...[
            const SizedBox(height: 8),
            Container(
              height: 1,
              color: isNight
                  ? Colors.white.withValues(alpha: 0.06)
                  : Colors.black.withValues(alpha: 0.04),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: List.generate(sortedTags.take(4).length, (index) {
                final tag = sortedTags[index].key;
                final count = sortedTags[index].value;
                final colorScheme = _getTagColorScheme(index, isNight);

                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: colorScheme['bg'],
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: colorScheme['border']!, width: 0.7),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        tag,
                        style: TextStyle(
                          fontSize: 10,
                          color: colorScheme['text'],
                          fontFamily: 'LXGWWenKai',
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '$count',
                        style: TextStyle(
                          fontSize: 9,
                          color: colorScheme['text']!.withValues(alpha: 0.65),
                          fontFamily: 'LXGWWenKai',
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                );
              }),
            ),
          ],
        ],
      ),
    );
  }

  Map<String, Color> _getTagColorScheme(int index, bool isNight) {
    final List<Map<String, Color>> colors = isNight
        ? [
            {
              'bg': const Color(0xFF7B1FA2).withValues(alpha: 0.12),
              'text': const Color(0xFFE1BEE7),
              'border': const Color(0xFF9C27B0).withValues(alpha: 0.25),
            },
            {
              'bg': const Color(0xFF2E7D32).withValues(alpha: 0.12),
              'text': const Color(0xFFC8E6C9),
              'border': const Color(0xFF4CAF50).withValues(alpha: 0.25),
            },
            {
              'bg': const Color(0xFF1565C0).withValues(alpha: 0.12),
              'text': const Color(0xFFBBDEFB),
              'border': const Color(0xFF2196F3).withValues(alpha: 0.25),
            },
            {
              'bg': const Color(0xFFC62828).withValues(alpha: 0.12),
              'text': const Color(0xFFFFCDD2),
              'border': const Color(0xFFE57373).withValues(alpha: 0.25),
            },
          ]
        : [
            {
              'bg': const Color(0xFFF3E5F5),
              'text': const Color(0xFF7B1FA2),
              'border': const Color(0xFFE1BEE7),
            },
            {
              'bg': const Color(0xFFE8F5E9),
              'text': const Color(0xFF2E7D32),
              'border': const Color(0xFFC8E6C9),
            },
            {
              'bg': const Color(0xFFE3F2FD),
              'text': const Color(0xFF1565C0),
              'border': const Color(0xFFBBDEFB),
            },
            {
              'bg': const Color(0xFFFFEBEE),
              'text': const Color(0xFFC62828),
              'border': const Color(0xFFFFCDD2),
            },
          ];
    return colors[index % colors.length];
  }
}

class _ExportRadarPainter extends CustomPainter {
  final List<_ExportRadarIntensityData> data;
  final bool isNight;
  final double radius;
  final Color themeColor;
  final Offset center;

  _ExportRadarPainter({
    required this.data,
    required this.isNight,
    required this.radius,
    required this.themeColor,
    required this.center,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final int n = data.length;

    final gridPaint = Paint()
      ..color = isNight
          ? Colors.white.withValues(alpha: 0.2)
          : Colors.black.withValues(alpha: 0.12)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.8;

    for (int i = 1; i <= 5; i++) {
      _drawDashedCircle(canvas, center, radius * (i / 5), gridPaint);
    }

    for (int i = 0; i < n; i++) {
      double angle = (2 * pi / n) * i - pi / 2;
      double px = center.dx + radius * cos(angle);
      double py = center.dy + radius * sin(angle);
      canvas.drawLine(center, Offset(px, py), gridPaint);
    }

    final List<Offset> points = [];
    final Path polygonPath = Path();

    for (int i = 0; i < n; i++) {
      double angle = (2 * pi / n) * i - pi / 2;
      double val = (data[i].avgIntensity / 10.0).clamp(0.001, 1.0);
      double r = radius * val;
      double px = center.dx + r * cos(angle);
      double py = center.dy + r * sin(angle);

      points.add(Offset(px, py));
      if (i == 0) {
        polygonPath.moveTo(px, py);
      } else {
        polygonPath.lineTo(px, py);
      }
    }
    polygonPath.close();

    final fillPaint = Paint()
      ..color = themeColor.withValues(alpha: 0.35)
      ..style = PaintingStyle.fill;
    canvas.drawPath(polygonPath, fillPaint);

    final borderPaint = Paint()
      ..color = themeColor.withValues(alpha: 0.8)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;
    canvas.drawPath(polygonPath, borderPaint);

    for (int i = 0; i < n; i++) {
      if (data[i].avgIntensity <= 0) continue;
      final dotColor = data[i].glowColor;
      canvas.drawCircle(points[i], 3.0, Paint()..color = dotColor);
    }
  }

  void _drawDashedCircle(Canvas canvas, Offset center, double radius, Paint paint) {
    const double dashWidth = 2.0;
    const double dashSpace = 3.0;
    double currentAngle = 0;
    final double perimeter = 2 * pi * radius;
    final int dashCount = max(12, (perimeter / (dashWidth + dashSpace)).floor());
    final double step = (2 * pi) / dashCount;

    for (int i = 0; i < dashCount; i++) {
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        currentAngle,
        step * (dashWidth / (dashWidth + dashSpace)),
        false,
        paint,
      );
      currentAngle += step;
    }
  }

  @override
  bool shouldRepaint(covariant _ExportRadarPainter oldDelegate) => true;
}
