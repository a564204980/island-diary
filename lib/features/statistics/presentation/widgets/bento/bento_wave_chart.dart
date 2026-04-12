part of '../../pages/statistics_page.dart';

extension BentoWaveChart on _StatisticsPageState {
  Widget _buildWaveChartBento(bool isNight, List<DiaryEntry> filtered, Color themeColor) {
    if (filtered.isEmpty) {
      return _buildGlassCard(
        isNight: isNight,
        padding: const EdgeInsets.all(16),
        child: const SizedBox(
          height: 160,
          child: Center(child: Text('开启日记旅程，看情感之河缓缓流淌 🌊', style: TextStyle(fontSize: 13, color: Colors.grey))),
        )
      );
    }

    // --- 1. 数据日聚合逻辑 ---
    final Map<String, List<DiaryEntry>> dailyGroups = {};
    for (var entry in filtered) {
      final key = DateFormat('yyyy-MM-dd').format(entry.dateTime);
      dailyGroups.putIfAbsent(key, () => []).add(entry);
    }

    final List<Map<String, dynamic>> aggregatedPoints = dailyGroups.entries.map((e) {
      final entries = e.value;
      final avgIntensity = entries.fold(0.0, (sum, item) => sum + item.intensity) / entries.length;
      final representative = entries.first; 
      return {
        'date': DateTime.parse(e.key),
        'intensity': avgIntensity,
        'entry': representative,
      };
    }).toList();

    aggregatedPoints.sort((a, b) => (a['date'] as DateTime).compareTo(b['date'] as DateTime));

    int maxPoints = _currentRange == StatTimeRange.week ? 7 : 12;
    final displayPoints = aggregatedPoints.length > maxPoints 
        ? aggregatedPoints.sublist(aggregatedPoints.length - maxPoints)
        : aggregatedPoints;

    if (displayPoints.length < 2 && _currentRange != StatTimeRange.week) {
        return _buildGlassCard(
          isNight: isNight,
          padding: const EdgeInsets.all(16),
          child: const SizedBox(
            height: 160,
            child: Center(child: Text('积累更多不同日期的记录解锁趋势 🌊', style: TextStyle(fontSize: 13, color: Colors.grey))),
          )
        );
    }

    final spots = displayPoints.asMap().entries.map((e) {
      return FlSpot(e.key.toDouble(), e.value['intensity'] as double);
    }).toList();

    // 提高主题色亮度以适应折线
    final barColor = themeColor.withOpacity(isNight ? 0.9 : 0.85);

    final barData = LineChartBarData(
      spots: spots,
      isCurved: true,
      curveSmoothness: 0.4,
      color: barColor,
      barWidth: 4,
      isStrokeCapRound: true,
      shadow: Shadow(
        color: barColor.withOpacity(0.4),
        blurRadius: 10,
        offset: const Offset(0, 4),
      ),
      dotData: FlDotData(
        show: true,
        getDotPainter: (spot, percent, barData, index) {
          if (index >= displayPoints.length) return FlDotCirclePainter(radius: 0, color: Colors.transparent);
          final entry = displayPoints[index]['entry'] as DiaryEntry;
          final mood = kMoods[entry.moodIndex % kMoods.length];
          final isSelected = _touchedWaveSpotIndex == index;
          return FlDotCirclePainter(
            radius: isSelected ? 8 : 4.5, 
            color: Colors.white, 
            strokeWidth: isSelected ? 4 : 2, 
            strokeColor: mood.glowColor ?? barColor,
          );
        }
      ),
      belowBarData: BarAreaData(
        show: true,
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            barColor.withOpacity(isNight ? 0.3 : 0.4),
            barColor.withOpacity(0.05),
            Colors.transparent,
          ],
        ),
      ),
    );

    return _buildGlassCard(
      isNight: isNight,
      padding: const EdgeInsets.only(top: 16, bottom: 4, left: 16, right: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildBentoHeader(
            context: context,
            title: '情感律动',
            helpContent: '波纹的起伏展现了当日情感的[[能量张力]]与[[平均心境]]。平稳或剧烈的涟漪，都是生命力的真实表达。',
            isNight: isNight,
            rightAction: Icon(CupertinoIcons.waveform_path, size: 18, color: barColor),
          ),
          const SizedBox(height: 24),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: SizedBox(
              height: 130,
              child: LayoutBuilder(
                builder: (context, constraints) {
                  return Stack(
                    children: [
                      LineChart(
                        LineChartData(
                          minY: 0,
                          maxY: 10,
                          lineTouchData: LineTouchData(
                            handleBuiltInTouches: true,
                            touchCallback: (event, response) {
                              if (event is FlTapUpEvent) {
                                if (response == null || response.lineBarSpots == null || response.lineBarSpots!.isEmpty) {
                                  updateWaveSpotIndex(null);
                                } else {
                                  final index = response.lineBarSpots!.first.spotIndex;
                                  updateWaveSpotIndex(index);
                                }
                              }
                            },
                            touchTooltipData: LineTouchTooltipData(
                              getTooltipColor: (_) => Colors.transparent,
                              getTooltipItems: (touchedSpots) => [],
                            ),
                          ),
                          gridData: const FlGridData(show: false),
                          titlesData: FlTitlesData(
                            leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                            bottomTitles: AxisTitles(
                              sideTitles: SideTitles(
                                showTitles: true,
                                reservedSize: 22,
                                interval: 1,
                                getTitlesWidget: (double value, TitleMeta meta) {
                                   final int index = value.toInt();
                                   if (index >= 0 && index < displayPoints.length) {
                                      final bool shouldShow = displayPoints.length <= 7 || index % 2 == 0;
                                      if (!shouldShow) return const SizedBox.shrink();

                                      final date = displayPoints[index]['date'] as DateTime;
                                      return Padding(
                                        padding: const EdgeInsets.only(top: 6.0),
                                        child: Text(
                                          DateFormat('MM/dd').format(date), 
                                          style: TextStyle(fontSize: 9, color: isNight ? Colors.white38 : Colors.black38)
                                        ),
                                      );
                                   }
                                   return const SizedBox.shrink();
                                }
                              )
                            )
                          ),
                          borderData: FlBorderData(show: false),
                          lineBarsData: [barData],
                        ),
                        duration: const Duration(milliseconds: 800),
                        curve: Curves.easeOutQuart,
                      ),
                      // 自定义提示框
                      if (_touchedWaveSpotIndex != null && _touchedWaveSpotIndex! < displayPoints.length) ...[
                        Positioned(
                          left: (spots.length > 1) ? _touchedWaveSpotIndex! / (spots.length - 1) * constraints.maxWidth : constraints.maxWidth / 2,
                          top: 0,
                          bottom: 22,
                          child: Container(
                            width: 1,
                            color: isNight ? Colors.white.withOpacity(0.15) : Colors.black.withOpacity(0.1),
                          ),
                        ),
                        _buildBentoTooltip(
                          title: DateFormat('MM月dd日').format(displayPoints[_touchedWaveSpotIndex!]['date']),
                          items: [
                            (){
                              final data = displayPoints[_touchedWaveSpotIndex!];
                              final entry = data['entry'] as DiaryEntry;
                              final mood = kMoods[entry.moodIndex % kMoods.length];
                              double y = spots[_touchedWaveSpotIndex!].y;
                              String desc = y >= 8 ? '内心能量澎湃' : (y >= 5 ? '情感起伏有力' : (y < 2 ? '万籁俱寂静谧' : '心境宁静平和'));
                              return _BentoTooltipItem(
                                label: mood.label,
                                value: desc,
                                color: mood.glowColor ?? barColor
                              );
                            }(),
                            _BentoTooltipItem(
                              label: '能量强度',
                              value: spots[_touchedWaveSpotIndex!].y.toStringAsFixed(1),
                            )
                          ],
                          relativeX: (spots.length > 1) ? _touchedWaveSpotIndex! / (spots.length - 1) : 0.5,
                          chartWidth: constraints.maxWidth,
                          isNight: isNight,
                        ),
                      ]
                    ],
                  );
                }
              ),
            ),
          ),
        ],
      ),
    );
  }
}
