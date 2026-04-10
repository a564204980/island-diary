part of '../../pages/statistics_page.dart';

extension BentoWaveChart on _StatisticsPageState {
  Widget _buildWaveChartBento(bool isNight, List<DiaryEntry> filtered) {
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

    // 提前构建 BarData 以便引用
    final mainLineColor = isNight ? const Color(0xFF00E5FF) : const Color(0xFF00B8D4);
    final barData = LineChartBarData(
      spots: spots,
      isCurved: true,
      curveSmoothness: 0.4,
      color: mainLineColor,
      barWidth: 4,
      isStrokeCapRound: true,
      shadow: Shadow(
        color: mainLineColor.withOpacity(0.5),
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
            strokeColor: mood.glowColor ?? mainLineColor,
          );
        }
      ),
      belowBarData: BarAreaData(
        show: true,
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            mainLineColor.withOpacity(isNight ? 0.3 : 0.4),
            mainLineColor.withOpacity(0.05),
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
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('情感之河', style: _bentoTitleStyle(isNight)),
                  Icon(CupertinoIcons.waveform_path, size: 18, color: isNight ? Colors.white54 : Colors.black38),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                '感知情感的涨落，看内心能量缓缓流淌',
                style: TextStyle(
                  fontSize: 10,
                  color: isNight ? Colors.white38 : Colors.black38,
                  fontFamily: 'LXGWWenKai',
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: SizedBox(
              height: 130,
              child: LineChart(
                LineChartData(
                  minY: 0,
                  maxY: 10,
                  showingTooltipIndicators: (_touchedWaveSpotIndex != null && _touchedWaveSpotIndex! < spots.length)
                    ? [ShowingTooltipIndicators([LineBarSpot(
                        barData, 
                        0, 
                        spots[_touchedWaveSpotIndex!]
                      )])]
                    : [],
                  lineTouchData: LineTouchData(
                    handleBuiltInTouches: true,
                    touchCallback: (event, response) {
                      if (response != null && response.lineBarSpots != null && response.lineBarSpots!.isNotEmpty) {
                        final index = response.lineBarSpots!.first.spotIndex;
                        updateWaveSpotIndex((_touchedWaveSpotIndex == index) ? null : index);
                      }
                    },
                    touchTooltipData: LineTouchTooltipData(
                      getTooltipColor: (_) => isNight ? const Color(0xFF3D3D3D) : const Color(0xFF5A3E28),
                      tooltipBorderRadius: BorderRadius.circular(12),
                      fitInsideHorizontally: true,
                      fitInsideVertically: true,
                      getTooltipItems: (touchedSpots) {
                        return touchedSpots.map((spot) {
                          if (spot.x.toInt() >= displayPoints.length) return null;
                          final data = displayPoints[spot.x.toInt()];
                          final entry = data['entry'] as DiaryEntry;
                          final mood = kMoods[entry.moodIndex % kMoods.length];
                          String intensityDesc = '心境宁静平和';
                          double y = spot.y;
                          if (y >= 8) {
                            intensityDesc = '内心能量澎湃';
                          } else if (y >= 5) {
                            intensityDesc = '情感起伏有力';
                          } else if (y < 2) {
                            intensityDesc = '万籁俱寂静谧';
                          }

                          return LineTooltipItem(
                            '${mood.label} · $intensityDesc\n',
                            const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12, fontFamily: 'LXGWWenKai'),
                            children: [
                              TextSpan(
                                text: '当日平均能量强度: ${spot.y.toStringAsFixed(1)} · ${DateFormat('MM/dd').format(data['date'])}', 
                                style: const TextStyle(fontWeight: FontWeight.normal, fontSize: 10, color: Colors.white70)
                              )
                            ],
                          );
                        }).toList();
                      },
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
            ),
          ),
        ],
      ),
    );
  }
}
