part of '../../pages/statistics_page.dart';

extension BentoMoodTrend on _StatisticsPageState {
  Widget _buildMoodTrendBento(bool isNight, List<DiaryEntry> filtered, Color themeColor) {
    if (filtered.isEmpty && _allDiaries.isEmpty) {
      return _buildGlassCard(
        isNight: isNight,
        padding: const EdgeInsets.all(16),
        child: const SizedBox(
          height: 200,
          child: Center(child: Text('记录心情，发现情绪波动的旋律 📈', style: TextStyle(fontSize: 13, color: Colors.grey))),
        )
      );
    }

    // --- 1. 评分权重定义 ---
    int getMoodWeight(int index) {
      switch (index % kMoods.length) {
        case 0: // 期待
        case 3: // 惊喜
        case 7: // 开心
          return 1;
        case 1: // 厌恶
        case 2: // 恐惧
        case 5: // 愤怒
        case 6: // 悲伤
          return -1;
        default: // 平静 (4)
          return 0;
      }
    }

    // --- 2. 差异化数据聚合处理 ---
    final List<Map<String, dynamic>> aggregatedPoints = [];
    final now = DateTime.now();
    
    if (_currentRange == StatTimeRange.week) {
      // 【周模式】：精准最近 7 天
      for (int i = 6; i >= 0; i--) {
        final d = DateTime(now.year, now.month, now.day).subtract(Duration(days: i));
        final dayKey = DateFormat('yyyy-MM-dd').format(d);
        final dayDiaries = _allDiaries.where((e) => DateFormat('yyyy-MM-dd').format(e.dateTime) == dayKey).toList();
        
        double dayScore = 0;
        for (var e in dayDiaries) {
          dayScore += getMoodWeight(e.moodIndex) * e.intensity.toDouble();
        }
        aggregatedPoints.add({
          'date': d,
          'score': dayScore,
          'label': d.day.toString(),
          'subLabel': _getChineseWeekDay(d.weekday),
          'hasData': dayDiaries.isNotEmpty,
        });
      }
    } else if (_currentRange == StatTimeRange.month) {
      // 【月模式】：当月全量天数
      final daysInMonth = DateTime(now.year, now.month + 1, 0).day;
      for (int i = 1; i <= daysInMonth; i++) {
        final d = DateTime(now.year, now.month, i);
        final dayKey = DateFormat('yyyy-MM-dd').format(d);
        final dayDiaries = _allDiaries.where((e) => DateFormat('yyyy-MM-dd').format(e.dateTime) == dayKey).toList();
        
        double dayScore = 0;
        for (var e in dayDiaries) {
          dayScore += getMoodWeight(e.moodIndex) * e.intensity.toDouble();
        }
        aggregatedPoints.add({
          'date': d,
          'score': dayScore,
          'label': i.toString(),
          'subLabel': _getChineseWeekDay(d.weekday),
          'hasData': dayDiaries.isNotEmpty,
        });
      }
    } else {
      // 【全量模式】：月度均值聚合
      DateTime start = _allDiaries.isEmpty ? DateTime(now.year, now.month) : _allDiaries.map((e) => e.dateTime).reduce((a, b) => a.isBefore(b) ? a : b);
      start = DateTime(start.year, start.month);
      
      final currentMonth = DateTime(now.year, now.month);
      DateTime temp = start;
      while (temp.isBefore(currentMonth.add(const Duration(days: 32)))) {
        final monthDiaries = _allDiaries.where((e) => e.dateTime.year == temp.year && e.dateTime.month == temp.month).toList();
        double monthTotal = 0;
        for (var e in monthDiaries) {
          monthTotal += getMoodWeight(e.moodIndex) * e.intensity.toDouble();
        }
        
        aggregatedPoints.add({
          'date': temp,
          'score': monthDiaries.isEmpty ? 0.0 : monthTotal / monthDiaries.length,
          'label': '${temp.month}月',
          'subLabel': temp.year.toString(),
          'hasData': monthDiaries.isNotEmpty,
        });
        
        temp = DateTime(temp.year, temp.month + 1);
        if (temp.isAfter(currentMonth)) break;
      }
    }


    // --- 3. 图表点计算 ---
    final spots = aggregatedPoints.asMap().entries.map((e) {
      return FlSpot(e.key.toDouble(), e.value['score'] as double);
    }).toList();

    int maxIdx = -1, minIdx = -1;
    double maxVal = -double.infinity, minVal = double.infinity;
    for (int i = 0; i < spots.length; i++) {
        if (spots[i].y > maxVal) { maxVal = spots[i].y; maxIdx = i; }
        if (spots[i].y < minVal) { minVal = spots[i].y; minIdx = i; }
    }
    double absMax = [maxVal.abs(), minVal.abs(), 5.0].reduce((curr, next) => curr > next ? curr : next);
    double yLimit = (absMax * 1.3).ceilToDouble();

    final mainBarColor = themeColor.withOpacity(0.8);

    final barData = LineChartBarData(
      spots: spots,
      isCurved: true,
      curveSmoothness: 0.35,
      color: mainBarColor,
      barWidth: 3,
      isStrokeCapRound: true,
      dotData: FlDotData(
        show: true,
        getDotPainter: (spot, percent, barData, index) {
          final bool hasRealData = aggregatedPoints[index]['hasData'] == true;
          bool isExtreme = (index == maxIdx || index == minIdx) && spots[index].y != 0;
          
          if (isExtreme) {
            return FlDotCirclePainter(
              radius: 5,
              color: index == maxIdx ? const Color(0xFFFF5252) : const Color(0xFF448AFF),
              strokeWidth: 2.5,
              strokeColor: Colors.white,
            );
          }
          
          if (hasRealData) {
            return FlDotCirclePainter(
              radius: 2.5,
              color: mainBarColor.withOpacity(0.8),
              strokeWidth: 1.5,
              strokeColor: Colors.white,
            );
          }

          return FlDotCirclePainter(radius: 0, color: Colors.transparent);
        }
      ),
      belowBarData: BarAreaData(
        show: true,
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [mainBarColor.withOpacity(0.25), mainBarColor.withOpacity(0.0)],
        ),
      ),
    );

    final bool isMonth = _currentRange == StatTimeRange.month;

    return _buildGlassCard(
      isNight: isNight,
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildBentoHeader(
            context: context,
            title: '情绪趋势',
            helpContent: '情绪指数由心情种类与强度[[加权计算]]得出。曲线展现了[[心境的起伏流动]]，助您捕捉那些微妙的情感波峰与低谷。',
            isNight: isNight,
            rightAction: Icon(CupertinoIcons.waveform_path, size: 18, color: themeColor.withOpacity(isNight ? 0.6 : 0.4)),
          ),
          const SizedBox(height: 24),
          SizedBox(
            height: 190,
            child: Row(
              children: [
                SizedBox(
                  width: 28,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildYLabel(yLimit.toInt().toString(), isNight),
                      _buildYLabel('0', isNight),
                      _buildYLabel((-yLimit).toInt().toString(), isNight),
                      const SizedBox(height: 40),
                    ],
                  ),
                ),
                Expanded(
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final double minWidth = constraints.maxWidth;
                      final double calculatedWidth = aggregatedPoints.length * 48.0;
                      final double finalWidth = isMonth ? (calculatedWidth > minWidth ? calculatedWidth : minWidth) : minWidth;

                      return SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        physics: isMonth ? const BouncingScrollPhysics() : const NeverScrollableScrollPhysics(),
                        child: SizedBox(
                          width: finalWidth,
                          child: LineChart(
                            LineChartData(
                              minX: -0.15,
                              maxX: aggregatedPoints.length - 0.85,
                              minY: -yLimit,
                              maxY: yLimit,
                              gridData: FlGridData(
                                show: true,
                                drawVerticalLine: false,
                                getDrawingHorizontalLine: (value) {
                                  if (value == 0) return FlLine(color: isNight ? Colors.white12 : Colors.black.withOpacity(0.05), strokeWidth: 1.5);
                                  return FlLine(color: isNight ? Colors.white.withOpacity(0.03) : Colors.black.withOpacity(0.01), strokeWidth: 1);
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
                                    reservedSize: 40,
                                    interval: 1,
                                    getTitlesWidget: (value, meta) {
                                      // 确保只在整数点显示标签，避免 minX 偏移导致的重复渲染
                                      if (value % 1 != 0) return const SizedBox.shrink();
                                      int index = value.round();
                                      if (index < 0 || index >= aggregatedPoints.length) return const SizedBox.shrink();
                                      final p = aggregatedPoints[index];
                                      return Padding(
                                        padding: const EdgeInsets.only(top: 10),
                                        child: Column(
                                          children: [
                                            Text(p['label'], style: TextStyle(fontSize: 11, color: isNight ? Colors.white70 : Colors.black87, fontWeight: FontWeight.bold)),
                                            Text(p['subLabel'], style: TextStyle(fontSize: 9, color: isNight ? Colors.white38 : Colors.black38)),
                                          ],
                                        ),
                                      );
                                    }
                                  )
                                ),
                              ),
                              borderData: FlBorderData(show: false),
                              lineBarsData: [barData],
                              lineTouchData: LineTouchData(
                                  touchTooltipData: LineTouchTooltipData(
                                    getTooltipColor: (_) => isNight ? const Color(0xFF2C2C2C) : const Color(0xFFFBFBFB),
                                    fitInsideHorizontally: true,
                                    fitInsideVertically: true,
                                    getTooltipItems: (touchedSpots) {
                                    return touchedSpots.map((spot) {
                                      final p = aggregatedPoints[spot.x.toInt()];
                                      return LineTooltipItem(
                                        '${p['label']}号 指数: ${spot.y.toStringAsFixed(1)}',
                                        TextStyle(color: isNight ? Colors.white : Colors.black87, fontSize: 11, fontWeight: FontWeight.bold, fontFamily: 'LXGWWenKai'),
                                      );
                                    }).toList();
                                  }
                                )
                              ),
                            ),
                          ),
                        ),
                      );
                    }
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildYLabel(String text, bool isNight) {
    return Text(text, style: TextStyle(color: isNight ? Colors.white24 : Colors.black26, fontSize: 10));
  }


  String _getChineseWeekDay(int weekday) {
    const list = ['一', '二', '三', '四', '五', '六', '日'];
    return list[weekday - 1];
  }
}
