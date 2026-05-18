part of '../../pages/statistics_page.dart';

extension _BentoMoodFlow on _StatisticsPageState {
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
      // 筛选：如果选中了某个标签，只处理该标签的数据
      if (_selectedMoodFlowLabel != null && _selectedMoodFlowLabel != label) continue;

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
          color: color.withValues(alpha: 0.8),
          barWidth: 2.5,
          isStrokeCapRound: true,
          dotData: const FlDotData(show: false),
          belowBarData: BarAreaData(
            show: true,
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                color.withValues(alpha: (0.25 - (i * 0.03).clamp(0.0, 0.2)).toDouble()),
                color.withValues(alpha: 0.0),
              ],
            ),
          ),
        ),
      );
    }

    final bool isCottonCandy = UserState().selectedIslandThemeId.value == 'cotton_candy';

    return _buildGlassCard(
      isNight: isNight,
      backgroundColor: isCottonCandy ? const Color(0xFFFFF4EF) : null,
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildBentoHeader(
            context: context,
            title: '情绪分布趋势',
            helpContent: '这里会把不同情绪分开画成多条线。哪条线越高，说明那种情绪在那天越明显。用它可以看出这段时间[[哪种情绪更多]]，以及它们分别在什么时候变强或变弱。',
            isNight: isNight,
            rightAction: Icon(
              CupertinoIcons.graph_circle,
              size: 18,
              color: isCottonCandy
                  ? const Color(0xFFF7AAB6)
                  : themeColor.withValues(alpha: isNight ? 0.6 : 0.4),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: _buildMoodFlowSubtitle(
              targetLabels.first,
              labelToMoodIndex[targetLabels.first]!,
              isNight,
            ),
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
                      width: 24,
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
                          child: Stack(
                            children: [
                              LineChart(
                                LineChartData(
                                  minX: -0.18,
                                  maxX: daysCount.toDouble() - 0.5,
                                  minY: 0,
                                  maxY: displayMaxY,
                                  clipData: const FlClipData.none(),
                                  gridData: FlGridData(
                                    show: true,
                                    drawVerticalLine: false,
                                    getDrawingHorizontalLine: (value) {
                                      return FlLine(
                                        color: isNight ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.03),
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
                                    handleBuiltInTouches: true,
                                    touchCallback: (FlTouchEvent event, LineTouchResponse? response) {
                                      if (event is FlTapUpEvent) {
                                        if (response == null || response.lineBarSpots == null || response.lineBarSpots!.isEmpty) {
                                          updateMoodFlowX(null);
                                        } else {
                                          final spot = response.lineBarSpots!.first;
                                          updateMoodFlowX(spot.x.toInt());
                                        }
                                      }
                                    },
                                    touchTooltipData: LineTouchTooltipData(
                                      getTooltipColor: (_) => Colors.transparent,
                                      getTooltipItems: (touchedSpots) => touchedSpots.map((_) {
                                        return const LineTooltipItem('', TextStyle(fontSize: 0));
                                      }).toList(),
                                    ),
                                  ),
                                ),
                              ),
                              // 自定义提示框叠加层
                              if (_selectedMoodFlowX != null)
                                ...[
                                  // 辅助垂线
                                  Positioned(
                                    left: (_selectedMoodFlowX! + 0.5) / daysCount * finalWidth,
                                    top: 0,
                                    bottom: 32,
                                    child: Container(
                                      width: 1,
                                      color: isNight ? Colors.white.withValues(alpha: 0.15) : Colors.black.withValues(alpha: 0.1),
                                    ),
                                  ),
                                  _buildBentoTooltip(
                                    title: '${startDate.add(Duration(days: _selectedMoodFlowX!)).month}月${startDate.add(Duration(days: _selectedMoodFlowX!)).day}日',
                                    items: [
                                      for (var label in targetLabels)
                                        if (_selectedMoodFlowLabel == null || _selectedMoodFlowLabel == label)
                                          if (dataMap[label]![_selectedMoodFlowX!] > 0)
                                            _BentoTooltipItem(
                                              label: label,
                                              value: dataMap[label]![_selectedMoodFlowX!].toStringAsFixed(1),
                                              color: label == kMoods[labelToMoodIndex[label]!].label
                                                ? kMoods[labelToMoodIndex[label]!].glowColor ?? (isNight ? Colors.white : Colors.black87)
                                                : HSLColor.fromAHSL(1.0, (label.hashCode % 360).toDouble(), 0.5, 0.6).toColor()
                                            )
                                    ]..sort((a, b) => double.parse(b.value).compareTo(double.parse(a.value))),
                                    relativeX: (_selectedMoodFlowX! + 0.5) / daysCount,
                                    chartWidth: finalWidth,
                                    isNight: isNight,
                                    width: isCottonCandy ? 138 : 150,
                                    useCottonCandyStyle: isCottonCandy,
                                  ),
                                ]
                            ],
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
    final bool isSelected = _selectedMoodFlowLabel == label;

    Color color;
    if (label == kMoods[baseMoodIndex].label) {
      color = kMoods[baseMoodIndex].glowColor ?? Colors.blueAccent;
    } else {
      final h = (label.hashCode % 360).toDouble();
      color = HSLColor.fromAHSL(1.0, h, 0.6, 0.7).toColor();
    }
    final readableColor = _getReadableMoodFlowChipColor(color, isNight);

    return GestureDetector(
      onTap: () => updateMoodFlowLabel(isSelected ? null : label),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? color.withValues(alpha: 0.22) : color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected ? readableColor.withValues(alpha: 0.35) : Colors.transparent,
            width: 1.5,
          ),
          boxShadow: isSelected ? [
            BoxShadow(
              color: readableColor.withValues(alpha: 0.16),
              blurRadius: 8,
              spreadRadius: 1,
            )
          ] : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 6,
              height: 6,
              decoration: BoxDecoration(
                color: readableColor,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                color: readableColor.withValues(alpha: isSelected ? 1.0 : 0.88),
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                fontFamily: 'LXGWWenKai',
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMoodFlowSubtitle(String label, int baseMoodIndex, bool isNight) {
    final color = _getMoodFlowColor(label, baseMoodIndex);
    final readableColor = _getReadableMoodFlowChipColor(color, isNight);

    return RichText(
      text: TextSpan(
        style: TextStyle(
          color: isNight ? Colors.white54 : const Color(0xFF9A7A69),
          fontSize: 12,
          height: 1.35,
          letterSpacing: 0,
          fontFamily: 'LXGWWenKai',
          fontWeight: FontWeight.w500,
        ),
        children: [
          TextSpan(text: '${_moodFlowRangeLabel()}高频情绪：'),
          TextSpan(
            text: label,
            style: TextStyle(
              color: readableColor,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Color _getMoodFlowColor(String label, int baseMoodIndex) {
    if (label == kMoods[baseMoodIndex].label) {
      return kMoods[baseMoodIndex].glowColor ?? Colors.blueAccent;
    }
    final h = (label.hashCode % 360).toDouble();
    return HSLColor.fromAHSL(1.0, h, 0.6, 0.7).toColor();
  }

  String _moodFlowRangeLabel() {
    switch (_currentRange) {
      case StatTimeRange.week:
        return '本周';
      case StatTimeRange.month:
        return '本月';
      case StatTimeRange.all:
        return '整体';
    }
  }

  Color _getReadableMoodFlowChipColor(Color color, bool isNight) {
    if (isNight) {
      return color.computeLuminance() < 0.35
          ? HSLColor.fromColor(color).withLightness(0.72).toColor()
          : color;
    }

    final hsl = HSLColor.fromColor(color);
    if (color.computeLuminance() > 0.56) {
      final saturation = (hsl.saturation + 0.12).clamp(0.0, 1.0).toDouble();
      return hsl
          .withSaturation(saturation)
          .withLightness(0.46)
          .toColor();
    }
    final lightness = hsl.lightness.clamp(0.34, 0.52).toDouble();
    return hsl.withLightness(lightness).toColor();
  }
}
