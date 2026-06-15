import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:island_diary/features/record/domain/models/diary_entry.dart';
import 'package:island_diary/core/state/user_state.dart';
import 'package:island_diary/features/profile/presentation/widgets/export/export_bento_wrapper.dart';

class ExportHeatmapChart extends StatelessWidget {
  final List<DiaryEntry> diaries;

  const ExportHeatmapChart({
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
        title: '心境图谱 / 时光足迹',
        rightAction: Icon(CupertinoIcons.graph_square, size: 16, color: Colors.grey),
        child: SizedBox(
          height: 160,
          child: Center(
            child: Text('暂无时光足迹 🎨', style: TextStyle(fontSize: 12, color: Colors.grey)),
          ),
        ),
      );
    }

    final int currentYear = DateTime.now().year;
    Map<int, Map<int, int>> data = {};
    for (var e in diaries) {
      if (e.dateTime.year == currentYear) {
        final m = e.dateTime.month;
        final d = e.dateTime.day;
        data.putIfAbsent(m, () => {})[d] = (data[m]?[d] ?? 0) + 1;
      }
    }

    final List<List<int>> matrix = List.generate(12, (mIdx) {
      final daysInMonth = _getDaysInMonth(currentYear, mIdx + 1);
      return List.generate(31, (dIdx) {
        final day = dIdx + 1;
        if (day > daysInMonth) return -2;
        return data[mIdx + 1]?[day] ?? 0;
      });
    });

    // 提取配色
    final Color themeColor = isCottonCandy ? const Color(0xFFFF8E9B) : const Color(0xFFD4A373);
    final Color labelColor = isNight
        ? Colors.white30
        : (isCottonCandy ? const Color(0xFF8A7462) : Colors.black38);
    final Color softLabelColor = isNight
        ? Colors.white24
        : (isCottonCandy ? const Color(0xFFAE9584) : Colors.black26);

    return ExportBentoWrapper(
      title: '心境图谱 / 时光足迹',
      rightAction: Icon(
        CupertinoIcons.graph_square,
        size: 16,
        color: isCottonCandy ? const Color(0xFFAE9584) : themeColor,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '色块深度代表记录密度，见证对生活的每一次回应。',
            style: TextStyle(
              fontSize: 10,
              color: isNight ? Colors.white54 : const Color(0xFF8A7462),
              fontFamily: 'LXGWWenKai',
            ),
          ),
          const SizedBox(height: 12),
          LayoutBuilder(
            builder: (context, constraints) {
              const double spacing = 1.8;
              const double labelWidth = 26.0;
              final double availableWidth = constraints.maxWidth - labelWidth - 8;
              final double cellSize = (availableWidth - (30 * spacing)) / 31;
              final double gridHeight = (12 * cellSize) + (11 * spacing);

              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: labelWidth,
                    height: gridHeight,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: List.generate(12, (i) => SizedBox(
                        height: cellSize,
                        child: Align(
                          alignment: Alignment.centerRight,
                          child: Text(
                            '${i + 1}月',
                            style: TextStyle(
                              fontSize: 9,
                              color: softLabelColor,
                            ),
                          ),
                        ),
                      )),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: SizedBox(
                      height: gridHeight,
                      child: CustomPaint(
                        painter: _ExportHeatmapPainter(
                          data: matrix,
                          themeColor: themeColor,
                          cellSize: cellSize,
                          spacing: spacing,
                          isNight: isNight,
                        ),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Text('少', style: TextStyle(fontSize: 10, color: labelColor, fontFamily: 'LXGWWenKai')),
              const SizedBox(width: 6),
              ...List.generate(5, (i) => Container(
                width: 11,
                height: 11,
                margin: const EdgeInsets.symmetric(horizontal: 1.5),
                decoration: BoxDecoration(
                  color: _getSeasonalGlowColor(i + 1, isNight, themeColor),
                  borderRadius: BorderRadius.circular(3),
                ),
              )),
              const SizedBox(width: 6),
              Text('深', style: TextStyle(fontSize: 10, color: labelColor, fontFamily: 'LXGWWenKai')),
            ],
          ),
        ],
      ),
    );
  }

  int _getDaysInMonth(int year, int month) {
    if (month == 2) {
      final bool isLeapYear = (year % 4 == 0 && year % 100 != 0) || (year % 400 == 0);
      return isLeapYear ? 29 : 28;
    }
    const List<int> days = [0, 31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31];
    return days[month];
  }

  Color _getSeasonalGlowColor(int count, bool isNight, Color themeColor) {
    if (count <= 0) return isNight ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.03);
    double opacity = (0.2 + (count * 0.15)).clamp(0.2, 0.9);
    return themeColor.withOpacity(opacity);
  }
}

class _ExportHeatmapPainter extends CustomPainter {
  final List<List<int>> data;
  final Color themeColor;
  final double cellSize;
  final double spacing;
  final bool isNight;

  _ExportHeatmapPainter({
    required this.data,
    required this.themeColor,
    required this.cellSize,
    required this.spacing,
    required this.isNight,
  });

  @override
  void paint(Canvas canvas, Size size) {
    for (int m = 0; m < 12; m++) {
      for (int d = 0; d < 31; d++) {
        final count = data[m][d];
        if (count == -2) continue;

        final rect = Rect.fromLTWH(
          d * (cellSize + spacing),
          m * (cellSize + spacing),
          cellSize,
          cellSize,
        );

        Color color;
        if (count <= 0) {
          color = isNight ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.03);
        } else {
          double opacity = (0.2 + (count * 0.15)).clamp(0.2, 0.9);
          color = themeColor.withOpacity(opacity);
        }

        final paint = Paint()
          ..color = color
          ..style = PaintingStyle.fill;

        canvas.drawRRect(
          RRect.fromRectAndRadius(rect, const Radius.circular(2)),
          paint,
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant _ExportHeatmapPainter oldDelegate) => true;
}
