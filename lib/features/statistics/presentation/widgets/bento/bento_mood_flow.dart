part of '../../pages/statistics_page.dart';

extension BentoMoodFlow on _StatisticsPageState {
  Widget _buildMoodFlowBento(bool isNight, List<DiaryEntry> filtered, Color themeColor) {
    if (filtered.isEmpty && _allDiaries.isEmpty) {
      return const SizedBox.shrink();
    }

    // --- 1. 确定时间轴范围 ---
    final now = DateTime.now();
    late DateTime startDate;
    late int daysCount;
    
    if (_currentRange == StatTimeRange.week) {
      startDate = DateTime(now.year, now.month, now.day).subtract(const Duration(days: 6));
      daysCount = 7;
    } else if (_currentRange == StatTimeRange.month) {
      startDate = DateTime(now.year, now.month, 1);
      daysCount = DateTime(now.year, now.month + 1, 0).day;
    } else {
      final firstDate = _allDiaries.isEmpty 
          ? DateTime(now.year, now.month, now.day) 
          : _allDiaries.map((e) => e.dateTime).reduce((a, b) => a.isBefore(b) ? a : b);
      startDate = DateTime(firstDate.year, firstDate.month, firstDate.day);
      daysCount = now.difference(startDate).inDays + 1;
    }

    // --- 2. 筛选活跃心情 (区分内置与自定义) ---
    final Map<String, double> labelTotalIntensity = {};
    final Map<String, int> labelToMoodIndex = {};

    for (var e in filtered) {
      final label = e.tag != null && e.tag!.isNotEmpty 
          ? e.tag! 
          : kMoods[e.moodIndex % kMoods.length].label;
      
      labelTotalIntensity[label] = (labelTotalIntensity[label] ?? 0) + e.intensity.toDouble();
      if (!labelToMoodIndex.containsKey(label)) {
        labelToMoodIndex[label] = e.moodIndex % kMoods.length;
      }
    }
    
    final sortedLabels = labelTotalIntensity.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    
    final List<String> targetLabels = sortedLabels.map((e) => e.key).toList();
    
    if (targetLabels.isEmpty) {
       return const SizedBox.shrink();
    }

    // --- 3. 聚合每日多维数据 ---
    final Map<String, List<double>> dataMap = {
      for (var label in targetLabels) label: List.filled(daysCount, 0.0)
    };

    for (var e in filtered) {
      final label = e.tag != null && e.tag!.isNotEmpty 
          ? e.tag! 
          : kMoods[e.moodIndex % kMoods.length].label;
          
      if (!targetLabels.contains(label)) continue;
      
      final dayDiff = e.dateTime.difference(startDate).inDays;
      if (dayDiff >= 0 && dayDiff < daysCount) {
        dataMap[label]![dayDiff] += e.intensity.toDouble();
      }
    }

    // --- 4. 构建图表数据 ---
    final List<LineChartBarData> lineBarsData = [];
    double maxY = 5.0;

    for (int i = 0; i < targetLabels.length; i++) {
      final label = targetLabels[i];
      final baseMoodIdx = labelToMoodIndex[label]!;
      
      Color color;
      if (label == kMoods[baseMoodIdx].label) {
        color = kMoods[baseMoodIdx].glowColor ?? Colors.blueAccent;
      } else {
        final h = (label.hashCode % 360).toDouble();
        color = HSLColor.fromAHSL(1.0, h, 0.6, 0.7).toColor();
      }
      
      final List<FlSpot> spots = [];
      for (int day = 0; day < daysCount; day++) {
        final val = dataMap[label]![day];
        if (val > maxY) maxY = val;
        spots.add(FlSpot(day.toDouble(), val));
      }

      lineBarsData.add(
        LineChartBarData(
          spots: spots,
          isCurved: true,
          curveSmoothness: 0.35,
          preventCurveOverShooting: true,
          color: color.withOpacity(0.8),
          barWidth: 2.5,
          isStrokeCapRound: true,
          dotData: const FlDotData(show: false),
          belowBarData: BarAreaData(
            show: true,
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                color.withOpacity(0.25 - (i * 0.03).clamp(0, 0.2)),
                color.withOpacity(0.0),
              ],
            ),
          ),
        ),
      );
    }

    return _buildGlassCard(
      isNight: isNight,
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildBentoHeader(
            context: context,
            title: '心境流转',
            helpContent: '[[心境流转]] 展现了不同情绪在时间轴上的 [[交织与消长]]。每一抹色彩都代表一份独特的心灵记忆，透过波形的起伏，您可以看清不同情感如何共同谱写您的生活乐章。',
            isNight: isNight,
          ),
          const SizedBox(height: 16),
          // 优化标签展示区：双行横向滚动
          if (targetLabels.isNotEmpty)
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 第一行
                  Row(
                    children: List.generate((targetLabels.length / 2).ceil(), (index) {
                      final label = targetLabels[index];
                      return Padding(
                        padding: const EdgeInsets.only(right: 8, bottom: 8),
                        child: _buildMoodTag(label, labelToMoodIndex[label]!, isNight),
                      );
                    }),
                  ),
                  // 第二行
                  Row(
                    children: List.generate(targetLabels.length - (targetLabels.length / 2).ceil(), (index) {
                      final label = targetLabels[index + (targetLabels.length / 2).ceil()];
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: _buildMoodTag(label, labelToMoodIndex[label]!, isNight),
                      );
                    }),
                  ),
                ],
              ),
            ),

          const SizedBox(height: 16),
          SizedBox(
            height: 180,
            child: Row(
              children: [
                // Y 轴
                LayoutBuilder(
                  builder: (context, _) {
                    final double displayMaxY = (maxY * 1.2).ceilToDouble();
                    return SizedBox(
                      width: 28,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _buildYLabel(displayMaxY.toInt().toString(), isNight),
                          _buildYLabel((displayMaxY / 2).toInt().toString(), isNight),
                          _buildYLabel('0', isNight),
                          const SizedBox(height: 32),
                        ],
                      ),
                    );
                  }
                ),
                const SizedBox(width: 4),
                // 绘图区
                Expanded(
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final double minWidth = constraints.maxWidth;
                      final double calculatedWidth = daysCount * 64.0;
                      final double finalWidth = calculatedWidth > minWidth ? calculatedWidth : minWidth;
                      final double displayMaxY = (maxY * 1.2).ceilToDouble();

                      return SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        physics: const BouncingScrollPhysics(),
                        child: SizedBox(
                          width: finalWidth,
                          child: LineChart(
                            LineChartData(
                              minX: -0.5,
                              maxX: daysCount.toDouble() - 0.5,
                              minY: 0,
                              maxY: displayMaxY,
                              clipData: const FlClipData.none(),
                              gridData: FlGridData(
                                show: true,
                                drawVerticalLine: false,
                                getDrawingHorizontalLine: (value) {
                                  return FlLine(
                                    color: isNight ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.03),
                                    strokeWidth: 1,
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
                                    reservedSize: 32,
                                    interval: 1,
                                    getTitlesWidget: (value, meta) {
                                      if (value % 1 != 0) return const SizedBox.shrink();
                                      final int index = value.round();
                                      if (index < 0 || index >= daysCount) return const SizedBox.shrink();
                                      
                                      final date = startDate.add(Duration(days: index));
                                      bool isEdge = index == 0 || index == daysCount - 1;
                                      
                                      String label;
                                      if (_currentRange == StatTimeRange.week) {
                                        label = _getChineseWeekDay(date.weekday);
                                      } else {
                                        label = (date.day == 1 || index == 0) 
                                            ? '${date.month}/${date.day}' 
                                            : '${date.day}';
                                      }

                                      return Padding(
                                        padding: const EdgeInsets.only(top: 8.0),
                                        child: Text(
                                          label,
                                          style: TextStyle(
                                            fontSize: 9,
                                            fontWeight: (date.day == 1 || isEdge) ? FontWeight.bold : FontWeight.normal,
                                            color: isNight ? Colors.white38 : Colors.black38,
                                            fontFamily: 'LXGWWenKai',
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                ),
                              ),
                              borderData: FlBorderData(show: false),
                              lineBarsData: lineBarsData,
                              lineTouchData: LineTouchData(
                                touchTooltipData: LineTouchTooltipData(
                                  getTooltipColor: (_) => isNight ? const Color(0xFF2C2C2C) : const Color(0xFFFBFBFB),
                                  fitInsideHorizontally: true,
                                  fitInsideVertically: true,
                                  getTooltipItems: (touchedSpots) {
                                    return touchedSpots.map((spot) {
                                      final label = targetLabels[spot.barIndex];
                                      final baseMoodIdx = labelToMoodIndex[label]!;
                                      Color color;
                                      if (label == kMoods[baseMoodIdx].label) {
                                        color = kMoods[baseMoodIdx].glowColor ?? (isNight ? Colors.white : Colors.black87);
                                      } else {
                                        final h = (label.hashCode % 360).toDouble();
                                        color = HSVColor.fromAHSV(1.0, h, 0.5, 0.8).toColor();
                                      }

                                      return LineTooltipItem(
                                        '$label: ${spot.y.toStringAsFixed(1)}',
                                        TextStyle(
                                          color: color,
                                          fontSize: 11,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      );
                                    }).toList();
                                  },
                                ),
                              ),
                            ),
                          ),
                        ),
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

  Widget _buildMoodTag(String label, int baseMoodIndex, bool isNight) {
    Color color;
    if (label == kMoods[baseMoodIndex].label) {
      color = kMoods[baseMoodIndex].glowColor ?? Colors.blueAccent;
    } else {
      final h = (label.hashCode % 360).toDouble();
      color = HSLColor.fromAHSL(1.0, h, 0.6, 0.7).toColor();
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: color.withOpacity(0.9),
              fontWeight: FontWeight.bold,
              fontFamily: 'LXGWWenKai',
            ),
          ),
        ],
      ),
    );
  }
}
