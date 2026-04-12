part of '../../pages/statistics_page.dart';

extension BentoHeatmap on _StatisticsPageState {
  Widget _buildHeatmapBento(bool isNight, List<DiaryEntry> filtered, StatTimeRange range, Color themeColor) {
    return _buildGlassCard(
      isNight: isNight,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildBentoHeader(
            context: context,
            title: range == StatTimeRange.week 
                ? '周间心境' 
                : (range == StatTimeRange.month ? '${DateTime.now().month}月 · 心境图谱' : '时光足迹'),
            helpContent: range == StatTimeRange.all
                ? '色块深度代表[[记录密度]]，见证您对生活的每一次回应。'
                : '方块颜色映射当下的[[心情色调]]。[[暖色调]]代表积极期待，[[冷色调]]代表忧郁平静。',
            isNight: isNight,
            rightAction: Icon(
              range == StatTimeRange.all ? CupertinoIcons.graph_square : CupertinoIcons.circle_grid_hex,
              size: 16,
              color: themeColor.withOpacity(isNight ? 0.6 : 0.4),
            ),
          ),
          const SizedBox(height: 16),
          _buildHeatmapContent(isNight, filtered, range, themeColor),
          if (range == StatTimeRange.all) ...[
            const SizedBox(height: 12),
            _buildHeatmapLegend(isNight, themeColor),
          ] else ...[
            const SizedBox(height: 16),
            _buildMoodLegend(isNight, filtered),
          ],
        ],
      ),
    );
  }

  Widget _buildHeatmapContent(bool isNight, List<DiaryEntry> entries, StatTimeRange range, Color themeColor) {
    switch (range) {
      case StatTimeRange.week:
        return _buildWeeklyHeatmap(isNight, entries, themeColor);
      case StatTimeRange.month:
        return _buildMonthlyHeatmap(isNight, entries, themeColor);
      case StatTimeRange.all:
        return _buildAllTimeHeatmap(isNight, _allDiaries, themeColor);
    }
  }

  // --- 周视图：7天 x 24小时 (心情色彩矩阵) ---
  Widget _buildWeeklyHeatmap(bool isNight, List<DiaryEntry> entries, Color themeColor) {
    final data = List.generate(7, (_) => List.filled(24, -1));
    final now = DateTime.now();
    
    final sundayOffset = now.weekday % 7;
    final weekStart = DateTime(now.year, now.month, now.day).subtract(Duration(days: sundayOffset));
    final weekEnd = weekStart.add(const Duration(days: 7));

    for (var e in entries) {
       if (e.dateTime.isAfter(weekStart.subtract(const Duration(seconds: 1))) && e.dateTime.isBefore(weekEnd)) {
         int weekdayIdx = e.dateTime.weekday % 7;
         int hour = e.dateTime.hour;
         data[weekdayIdx][hour] = e.moodIndex;
       }
    }

    final weekLabels = ['日', '一', '二', '三', '四', '五', '六'];

    return LayoutBuilder(
      builder: (context, constraints) {
        const double spacing = 2.0;
        const double labelWidth = 24.0;
        final double availableWidth = constraints.maxWidth - labelWidth - 10;
        
        final double cellSize = (availableWidth - (23 * spacing)) / 24;
        final double gridHeight = (cellSize * 7) + (6 * spacing);

        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: labelWidth,
                  height: gridHeight,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: weekLabels.map((l) => SizedBox(
                      height: cellSize,
                      child: Center(
                        child: Text(
                          l, 
                          style: TextStyle(
                            fontSize: 10, 
                            color: isNight ? Colors.white38 : Colors.black38, 
                            fontFamily: 'LXGWWenKai', 
                            fontWeight: FontWeight.bold
                          ),
                        ),
                      ),
                    )).toList(),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: SizedBox(
                    height: gridHeight,
                    child: Stack(
                      children: [
                        GestureDetector(
                          onTapUp: (details) {
                            final x = details.localPosition.dx;
                            final y = details.localPosition.dy;
                            final h = (x / (cellSize + spacing)).floor().clamp(0, 23);
                            final d = (y / (cellSize + spacing)).floor().clamp(0, 6);
                            updateHeatmapCoord(Offset(h.toDouble(), d.toDouble()));
                          },
                          child: CustomPaint(
                            size: Size(double.infinity, gridHeight),
                            painter: _HeatmapPainter(
                              data: data,
                              isNight: isNight,
                              mode: HeatmapMode.weekly,
                              isMoodMode: true,
                              themeColor: themeColor,
                            ),
                          ),
                        ),
                        if (_selectedHeatmapCoord != null && _currentRange == StatTimeRange.week) ...[
                           (){
                              final int h = _selectedHeatmapCoord!.dx.toInt();
                              final int d = _selectedHeatmapCoord!.dy.toInt();
                              final int moodIdx = data[d][h];
                              
                              return _buildBentoTooltip(
                                title: '${weekLabels[d]}曜 · ${h}时',
                                items: [
                                  if (moodIdx != -1)
                                    _BentoTooltipItem(
                                      label: kMoods[moodIdx % kMoods.length].label,
                                      value: '心情记录',
                                      color: kMoods[moodIdx % kMoods.length].glowColor,
                                    )
                                  else
                                    _BentoTooltipItem(label: '静谧时光', value: '暂无记录'),
                                ],
                                relativeX: (h * (cellSize + spacing) + cellSize / 2) / availableWidth,
                                chartWidth: availableWidth,
                                isNight: isNight,
                                top: d * (cellSize + spacing) > gridHeight / 2 ? d * (cellSize + spacing) - 80 : d * (cellSize + spacing) + 15,
                              );
                           }()
                        ]
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.only(left: 34),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                   Text('0h', style: _axisStyle(isNight)),
                   Text('6h', style: _axisStyle(isNight)),
                   Text('12h', style: _axisStyle(isNight)),
                   Text('18h', style: _axisStyle(isNight)),
                   Text('23h', style: _axisStyle(isNight)),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  TextStyle _axisStyle(bool isNight) => TextStyle(fontSize: 9, color: isNight ? Colors.white24 : Colors.black26);

  // --- 月视图：情感动态长卷 (每日 24 小时矩阵) ---
  Widget _buildMonthlyHeatmap(bool isNight, List<DiaryEntry> entries, Color themeColor) {
    final now = DateTime.now();
    final daysInMonth = DateUtils.getDaysInMonth(now.year, now.month);
    
    final data = List.generate(daysInMonth, (_) => List.filled(24, -1));
    for (var e in entries) {
      if (e.dateTime.year == now.year && e.dateTime.month == now.month) {
        data[e.dateTime.day - 1][e.dateTime.hour] = e.moodIndex;
      }
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        const double spacing = 1.8;
        const double labelWidth = 32.0;
        final double availableWidth = constraints.maxWidth - labelWidth - 10;
        final double cellSize = (availableWidth - (23 * spacing)) / 24;

        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.only(left: 42, bottom: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: ['0h', '12h', '23h'].map((t) => Text(t, style: _axisStyle(isNight))).toList(),
              ),
            ),
            SizedBox(
              height: 240,
              child: Scrollbar(
                thickness: 2,
                radius: const Radius.circular(1),
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  child: Column(
                    children: List.generate(daysInMonth, (index) {
                      final day = index + 1;
                      final date = DateTime(now.year, now.month, day);
                      final weekdayStr = ['日', '一', '二', '三', '四', '五', '六'][date.weekday % 7];
                      
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 2.0),
                        child: Row(
                          children: [
                            SizedBox(
                              width: labelWidth,
                              child: Text(
                                '${day.toString().padLeft(2, '0')} $weekdayStr',
                                style: TextStyle(
                                  fontSize: 8, 
                                  color: isNight ? Colors.white30 : Colors.black38,
                                  fontWeight: date.weekday >= 6 ? FontWeight.bold : FontWeight.normal,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: SizedBox(
                                height: cellSize,
                                child: Stack(
                                  clipBehavior: Clip.none,
                                  children: [
                                    GestureDetector(
                                      onTapUp: (details) {
                                        final x = details.localPosition.dx;
                                        final h = (x / (cellSize + spacing)).floor().clamp(0, 23);
                                        updateHeatmapCoord(Offset(h.toDouble(), day.toDouble()));
                                      },
                                      child: CustomPaint(
                                        size: Size(double.infinity, cellSize),
                                        painter: _HeatmapPainter(
                                          data: [data[index]],
                                          isNight: isNight,
                                          mode: HeatmapMode.weekly,
                                          isMoodMode: true,
                                          themeColor: themeColor,
                                        ),
                                      ),
                                    ),
                                    if (_selectedHeatmapCoord != null && _selectedHeatmapCoord!.dy == day && _currentRange == StatTimeRange.month) ...[
                                      (){
                                         final int h = _selectedHeatmapCoord!.dx.toInt();
                                         final int moodIdx = data[index][h];
                                         return _buildBentoTooltip(
                                           title: '${now.month}月${day}日 · ${h}时',
                                           items: [
                                              if (moodIdx != -1)
                                                _BentoTooltipItem(
                                                  label: kMoods[moodIdx % kMoods.length].label,
                                                  value: '心情记录',
                                                  color: kMoods[moodIdx % kMoods.length].glowColor,
                                                )
                                              else
                                                _BentoTooltipItem(label: '静谧时刻', value: '记录空白'),
                                           ],
                                           relativeX: (h * (cellSize + spacing) + cellSize / 2) / availableWidth,
                                           chartWidth: availableWidth,
                                           isNight: isNight,
                                           top: -60,
                                         );
                                      }()
                                    ]
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    }),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  // --- 全量视图：年度心境矩阵 (12x31 月-日矩阵) ---
  Widget _buildAllTimeHeatmap(bool isNight, List<DiaryEntry> allEntries, Color themeColor) {
    if (allEntries.isEmpty) {
      return _buildYearlyMatrixBlock(DateTime.now().year, {}, isNight, themeColor);
    }

    Map<int, Map<int, Map<int, int>>> yearToMonthToDayToCount = {};
    Set<int> years = {};
    
    for (var e in allEntries) {
      final y = e.dateTime.year;
      final m = e.dateTime.month;
      final d = e.dateTime.day;
      years.add(y);
      yearToMonthToDayToCount.putIfAbsent(y, () => {})
                             .putIfAbsent(m, () => {})[d] = 
                             (yearToMonthToDayToCount[y]![m]![d] ?? 0) + 1;
    }

    final sortedYears = years.toList()..sort();
    
    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          physics: const BouncingScrollPhysics(),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: sortedYears.map((y) {
              return Padding(
                padding: EdgeInsets.only(right: sortedYears.length > 1 ? 24.0 : 0),
                child: _buildYearlyMatrixBlock(y, yearToMonthToDayToCount[y]!, isNight, themeColor, constraints.maxWidth),
              );
            }).toList(),
          ),
        );
      },
    );
  }

  Widget _buildYearlyMatrixBlock(int year, Map<int, Map<int, int>> data, bool isNight, Color themeColor, [double? maxWidth]) {
    final List<List<int>> matrix = List.generate(12, (mIdx) {
      final daysInMonth = DateUtils.getDaysInMonth(year, mIdx + 1);
      return List.generate(31, (dIdx) {
        final day = dIdx + 1;
        if (day > daysInMonth) return -2;
        return data[mIdx + 1]?[day] ?? 0;
      });
    });

    return LayoutBuilder(
      builder: (context, constraints) {
        const double spacing = 1.8;
        const double labelWidth = 26.0;
        final double width = maxWidth ?? constraints.maxWidth;
        final double availableWidth = width - labelWidth - 8;
        final double cellSize = (availableWidth - (30 * spacing)) / 31;
        final double gridHeight = (12 * cellSize) + (11 * spacing);

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(left: 34, bottom: 8),
              child: Text('$year', style: TextStyle(
                fontSize: 12, 
                fontWeight: FontWeight.bold,
                color: isNight ? Colors.white30 : Colors.black26,
              )),
            ),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(top: 1),
                  child: Column(
                    children: List.generate(12, (i) => SizedBox(
                      height: cellSize + spacing,
                      width: labelWidth,
                      child: Text('${i + 1}月', 
                        textAlign: TextAlign.right,
                        style: TextStyle(fontSize: 8, color: isNight ? Colors.white24 : Colors.black26)
                      ),
                    )),
                  ),
                ),
                const SizedBox(width: 8),
                SizedBox(
                  width: availableWidth,
                  height: gridHeight,
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      GestureDetector(
                        onTapUp: (details) {
                          final x = details.localPosition.dx;
                          final y = details.localPosition.dy;
                          final d = (x / (cellSize + spacing)).floor().clamp(0, 30);
                          final m = (y / (cellSize + spacing)).floor().clamp(0, 11);
                          updateHeatmapCoord(Offset(d.toDouble(), (year * 100 + m + 1).toDouble())); // 编码年份和月份
                        },
                        child: CustomPaint(
                          size: Size(availableWidth, gridHeight),
                          painter: _HeatmapPainter(
                            data: matrix,
                            isNight: isNight,
                            mode: HeatmapMode.all,
                            isMoodMode: false,
                            cellSizeOverride: cellSize,
                            themeColor: themeColor,
                          ),
                        ),
                      ),
                      if (_selectedHeatmapCoord != null && _selectedHeatmapCoord!.dy >= (year * 100) && _selectedHeatmapCoord!.dy < ((year + 1) * 100) && _currentRange == StatTimeRange.all) ...[
                        (){
                          final int dIdx = _selectedHeatmapCoord!.dx.toInt();
                          final int mIdx = (_selectedHeatmapCoord!.dy % 100).toInt() - 1;
                          if (mIdx < 0 || mIdx >= 12 || dIdx >= matrix[mIdx].length) return const SizedBox.shrink();
                          final int count = matrix[mIdx][dIdx];
                          if (count == -2) return const SizedBox.shrink();

                          return _buildBentoTooltip(
                            title: '${year}年${mIdx + 1}月${dIdx + 1}日',
                            items: [
                              _BentoTooltipItem(
                                label: '记录篇数',
                                value: '$count篇',
                                color: count > 0 ? themeColor : null,
                              )
                            ],
                            relativeX: (dIdx * (cellSize + spacing) + cellSize / 2) / availableWidth,
                            chartWidth: availableWidth,
                            isNight: isNight,
                            top: mIdx * (cellSize + spacing) > gridHeight / 2 ? mIdx * (cellSize + spacing) - 70 : mIdx * (cellSize + spacing) + 15,
                          );
                        }()
                      ]
                    ],
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );
  }

  Widget _buildMoodLegend(bool isNight, List<DiaryEntry> filtered) {
     final unifiedData = _getUnifiedEmotionData(filtered);
     if (unifiedData.isEmpty) return const SizedBox.shrink();

     return ConstrainedBox(
       constraints: const BoxConstraints(maxHeight: 120),
       child: CupertinoScrollbar(
         child: SingleChildScrollView(
           physics: const BouncingScrollPhysics(),
           child: Wrap(
             spacing: 12,
             runSpacing: 8,
             children: unifiedData.map((data) {
               Color color = data.color;
               if (isNight) color = Color.lerp(color, Colors.black, 0.2)!;
               
               return Row(
                 mainAxisSize: MainAxisSize.min,
                 children: [
                   Container(
                     width: 10,
                     height: 10,
                     decoration: BoxDecoration(
                       color: color,
                       borderRadius: BorderRadius.circular(2),
                     ),
                   ),
                   const SizedBox(width: 4),
                   Text(
                     data.label,
                     style: TextStyle(
                       fontSize: 10,
                       color: isNight ? Colors.white30 : Colors.black38,
                       fontFamily: 'LXGWWenKai',
                     ),
                   ),
                 ],
               );
             }).toList(),
           ),
         ),
       ),
     );
  }

  Widget _buildHeatmapLegend(bool isNight, Color themeColor) {
     return Row(
       mainAxisAlignment: MainAxisAlignment.end,
       children: [
         Text('浅', style: TextStyle(fontSize: 10, color: isNight ? Colors.white24 : Colors.black26)),
         const SizedBox(width: 4),
         ...List.generate(5, (i) => Container(
           width: 10, height: 10,
           margin: const EdgeInsets.symmetric(horizontal: 1),
           decoration: BoxDecoration(
             color: _getSeasonalGlowColor(i + 1, isNight, themeColor),
             borderRadius: BorderRadius.circular(2),
           ),
         )),
         const SizedBox(width: 4),
         Text('深', style: TextStyle(fontSize: 10, color: isNight ? Colors.white24 : Colors.black26)),
       ],
     );
  }
}

enum HeatmapMode { weekly, monthly, all }

class _HeatmapPainter extends CustomPainter {
  final List<List<int>>? data;
  final bool isNight;
  final HeatmapMode mode;
  final bool isMoodMode;
  final double? cellSizeOverride;
  final Color themeColor;

  _HeatmapPainter({
    this.data,
    required this.isNight,
    required this.mode,
    this.isMoodMode = false,
    this.cellSizeOverride,
    required this.themeColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    const double spacing = 1.8;
    
    if (mode == HeatmapMode.weekly && data != null) {
      final double cellWidth = (size.width - (23 * spacing)) / 24;
      final double cellHeight = (size.height - (6 * spacing)) / 7;
      final double cellSize = min(cellWidth, cellHeight);
      
      final double xOffset = (size.width - (24 * cellSize + 23 * spacing)) / 2;

      for (int d = 0; d < 7; d++) {
        for (int h = 0; h < 24; h++) {
          final count = data![d][h];
          final rect = Rect.fromLTWH(
            xOffset + h * (cellSize + spacing),
            d * (cellSize + spacing),
            cellSize,
            cellSize,
          );
          _drawCell(canvas, rect, count);
        }
      }
    } else if (mode == HeatmapMode.monthly && data != null) {
      final double cellSize = (size.width - (23 * spacing)) / 24;
      for (int h = 0; h < 24; h++) {
        final count = data![0][h];
        final rect = Rect.fromLTWH(
          h * (cellSize + spacing),
          0,
          cellSize,
          cellSize,
        );
        _drawCell(canvas, rect, count);
      }
    } else if (mode == HeatmapMode.all && data != null) {
      final double cellSize = cellSizeOverride ?? 11.0;
      for (int m = 0; m < 12; m++) {
        for (int d = 0; d < 31; d++) {
          final count = data![m][d];
          if (count == -2) continue;

          final rect = Rect.fromLTWH(
            d * (cellSize + spacing),
            m * (cellSize + spacing),
            cellSize,
            cellSize,
          );
          _drawCell(canvas, rect, count);
        }
      }
    }
  }

  void _drawCell(Canvas canvas, Rect rect, int count, {bool isCircle = false}) {
    Color color;
    if (isMoodMode) {
      if (count == -1) {
        color = isNight ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.03);
      } else {
        final moodIdx = count % kMoods.length;
        color = kMoods[moodIdx].glowColor ?? const Color(0xFFD4A373);
        if (isNight) color = Color.lerp(color, Colors.black, 0.2)!;
      }
    } else {
      color = _getSeasonalGlowColor(count, isNight, themeColor);
    }

    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;
    
    if (isCircle) {
      canvas.drawCircle(rect.center, rect.width * 0.42, paint);
    } else {
      canvas.drawRRect(
        RRect.fromRectAndRadius(rect, const Radius.circular(2)),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _HeatmapPainter oldDelegate) => 
      oldDelegate.isNight != isNight || oldDelegate.mode != mode || oldDelegate.themeColor != themeColor;
}

Color _getSeasonalGlowColor(int count, bool isNight, Color themeColor) {
  if (count <= 0) return isNight ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.03);
  double opacity = (0.2 + (count * 0.15)).clamp(0.2, 0.9);
  return themeColor.withOpacity(opacity);
}
