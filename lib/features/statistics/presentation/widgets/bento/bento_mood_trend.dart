part of '../../pages/statistics_page.dart';

extension _BentoMoodTrend on _StatisticsPageState {
  Widget _buildMoodTrendBento(
    bool isNight,
    List<DiaryEntry> filtered,
    Color themeColor,
  ) {
    if (filtered.isEmpty && _allDiaries.isEmpty) {
      return _buildGlassCard(
        isNight: isNight,
        padding: const EdgeInsets.all(16),
        child: const SizedBox(
          height: 200,
          child: Center(
            child: Text(
              '记录心情，发现情绪波动的旋律 📈',
              style: TextStyle(fontSize: 13, color: Colors.grey),
            ),
          ),
        ),
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
        final d = DateTime(
          now.year,
          now.month,
          now.day,
        ).subtract(Duration(days: i));
        final dayKey = DateFormat('yyyy-MM-dd').format(d);
        final dayDiaries = _allDiaries
            .where((e) => DateFormat('yyyy-MM-dd').format(e.dateTime) == dayKey)
            .toList();

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
          'moodIcon': _resolvePeakMoodIconPath(dayDiaries),
        });
      }
    } else if (_currentRange == StatTimeRange.month) {
      // 【月模式】：当月全量天数
      final daysInMonth = DateTime(now.year, now.month + 1, 0).day;
      for (int i = 1; i <= daysInMonth; i++) {
        final d = DateTime(now.year, now.month, i);
        // 🌟 核心过滤：如果日期超前于今天，则无需摆出未来的空日期，直接截断！
        if (d.isAfter(DateTime(now.year, now.month, now.day))) {
          break;
        }
        final dayKey = DateFormat('yyyy-MM-dd').format(d);
        final dayDiaries = _allDiaries
            .where((e) => DateFormat('yyyy-MM-dd').format(e.dateTime) == dayKey)
            .toList();

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
          'moodIcon': _resolvePeakMoodIconPath(dayDiaries),
        });
      }
    } else {
      // 【全量模式】：月度均值聚合
      DateTime start = _allDiaries.isEmpty
          ? DateTime(now.year, now.month)
          : _allDiaries
                .map((e) => e.dateTime)
                .reduce((a, b) => a.isBefore(b) ? a : b);
      start = DateTime(start.year, start.month);

      final currentMonth = DateTime(now.year, now.month);
      DateTime temp = start;
      while (temp.isBefore(currentMonth.add(const Duration(days: 32)))) {
        final monthDiaries = _allDiaries
            .where(
              (e) =>
                  e.dateTime.year == temp.year &&
                  e.dateTime.month == temp.month,
            )
            .toList();
        double monthTotal = 0;
        for (var e in monthDiaries) {
          monthTotal += getMoodWeight(e.moodIndex) * e.intensity.toDouble();
        }

        aggregatedPoints.add({
          'date': temp,
          'score': monthDiaries.isEmpty
              ? 0.0
              : monthTotal / monthDiaries.length,
          'label': '${temp.month}月',
          'subLabel': temp.year.toString(),
          'hasData': monthDiaries.isNotEmpty,
          'moodIcon': _resolvePeakMoodIconPath(monthDiaries),
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
      if (spots[i].y > maxVal) {
        maxVal = spots[i].y;
        maxIdx = i;
      }
      if (spots[i].y < minVal) {
        minVal = spots[i].y;
        minIdx = i;
      }
    }
    double absMax = [
      maxVal.abs(),
      minVal.abs(),
      5.0,
    ].reduce((curr, next) => curr > next ? curr : next);
    double yLimit = (absMax * 1.3).ceilToDouble();

    final bool isCottonCandy =
        UserState().selectedIslandThemeId.value == 'cotton_candy';

    // 🔥 棉花糖岛白天模式下的折线颜色：一比一复刻图 2 的梦幻马卡龙桃粉色！
    final Color mainBarColor = (isCottonCandy && !isNight)
        ? const Color(0xFFFF8E9E)
        : themeColor.withValues(alpha: 0.8);

    final barData = LineChartBarData(
      spots: spots,
      isCurved: true,
      curveSmoothness: 0.35,
      // 避开 FL Chart 单色与渐变色的 API 互斥限制，进行优雅的主题动态分支切换
      color: (isCottonCandy && !isNight) ? null : mainBarColor,
      gradient: (isCottonCandy && !isNight)
          ? const LinearGradient(
              colors: [
                Color(0xFFFF6E8D), // 🌸 起点：梦幻马卡龙樱花粉
                Color(0xFFC69DF3), // 🔮 中段：梦幻马卡龙薰衣草紫
                Color(0xFF8DAEFF), // 💧 终点：梦幻马卡龙晴空蓝
              ],
            )
          : null,
      barWidth: 3,
      isStrokeCapRound: true,
      dotData: FlDotData(
        show: true,
        getDotPainter: (spot, percent, barData, index) {
          final bool hasRealData = aggregatedPoints[index]['hasData'] == true;
          bool isExtreme =
              (index == maxIdx || index == minIdx) && spots[index].y != 0;

          if (isExtreme) {
            return FlDotCirclePainter(
              radius: 5,
              color: index == maxIdx
                  ? const Color(0xFFFF5252)
                  : const Color(0xFF448AFF),
              strokeWidth: 2.5,
              strokeColor: Colors.white,
            );
          }

          if (hasRealData) {
            // 🌟 细节大师：依据点在横轴上的坐标位置 t，进行色彩线性插值自适应染色，达成完美的视觉一体化！
            final double t = index / (aggregatedPoints.length - 1).clamp(1, 999);
            final Color dotColor = (isCottonCandy && !isNight)
                ? Color.lerp(
                    const Color(0xFFFF6E8D), // 粉红
                    const Color(0xFF8DAEFF), // 浅蓝
                    t,
                  )!
                : mainBarColor.withValues(alpha: 0.8);

            return FlDotCirclePainter(
              radius: 2.5,
              color: dotColor,
              strokeWidth: 1.5,
              strokeColor: Colors.white,
            );
          }

          return FlDotCirclePainter(radius: 0, color: Colors.transparent);
        },
      ),
      belowBarData: BarAreaData(
        show: true,
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: (isCottonCandy && !isNight)
              ? [
                  const Color(0xFFFFD5DB).withValues(alpha: 0.45), // 🌸 梦幻粉色渐变顶端
                  const Color(0xFFFFD5DB).withValues(alpha: 0.0),  // 渐变到完全透明
                ]
              : [
                  mainBarColor.withValues(alpha: 0.25),
                  mainBarColor.withValues(alpha: 0.0),
                ],
        ),
      ),
    );

    final bool isMonth = _currentRange == StatTimeRange.month;

    final summaryFuture = _getMoodTrendSummaryFuture(aggregatedPoints);

    return _buildGlassCard(
      isNight: isNight,
      backgroundColor: isCottonCandy ? const Color(0xFFFFF4EF) : null,
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildBentoHeader(
            context: context,
            title: '情绪趋势',
            helpContent:
                '这条线把每天的心情合成一个[[情绪分数]]：开心、期待会往上，难过、烦躁会往下，平静接近 0。用它可以快速看出这段时间整体是在变好、变低，还是波动比较大。',
            isNight: isNight,
            rightAction: Icon(
              CupertinoIcons.waveform_path,
              size: 18,
              color: isCottonCandy
                  ? const Color(0xFFF7AAB6)
                  : themeColor.withValues(alpha: isNight ? 0.6 : 0.4),
            ),
          ),
          FutureBuilder<String>(
            future: summaryFuture,
            initialData: _buildLocalMoodTrendSummary(aggregatedPoints),
            builder: (context, snapshot) {
              final summary = (snapshot.data ?? '').trim();
              if (summary.isEmpty) return const SizedBox.shrink();

              return Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Text(
                  summary,
                  textAlign: TextAlign.start,
                  style: TextStyle(
                    color: isNight ? Colors.white60 : const Color(0xFF8A7462),
                    fontSize: 12,
                    height: 1.35,
                    letterSpacing: 0,
                    fontFamily: 'LXGWWenKai',
                    fontWeight: FontWeight.w500,
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 190,
            child: Row(
              children: [
                SizedBox(
                  width: 36,
                  child: Column(
                    children: [
                      SizedBox(
                        height: 150,
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            _buildMoodTrendYLabel(
                              yLimit.toInt().toString(),
                              '愉悦',
                              const Color(0xFFF3A5B6),
                              isNight,
                            ),
                            _buildMoodTrendYLabel(
                              '0',
                              '平和',
                              const Color(0xFFD79A64),
                              isNight,
                            ),
                            _buildMoodTrendYLabel(
                              (-yLimit).toInt().toString(),
                              '低落',
                              const Color(0xFF78AEEB),
                              isNight,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 40),
                    ],
                  ),
                ),
                Expanded(
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final double minWidth = constraints.maxWidth;
                      final double calculatedWidth =
                          aggregatedPoints.length * 48.0;
                      final double finalWidth = isMonth
                          ? (calculatedWidth > minWidth
                                ? calculatedWidth
                                : minWidth)
                          : minWidth;

                      return Stack(
                        children: [
                          if (isCottonCandy && !isNight) ...[
                            // ☁️ 固定右上方大粉云
                            Positioned(
                              right: 60,
                              top: 15,
                              child: Icon(
                                CupertinoIcons.cloud_fill,
                                size: 40,
                                color: const Color(0xFFFFD5DB).withValues(alpha: 0.45),
                              ),
                            ),
                            // ☁️ 固定右侧小蓝云
                            Positioned(
                              right: 15,
                              top: 32,
                              child: Icon(
                                CupertinoIcons.cloud_fill,
                                size: 28,
                                color: const Color(0xFFD0E1FD).withValues(alpha: 0.4),
                              ),
                            ),
                            // ❤️ 固定中右侧：粉色梦幻小爱心（俏皮旋转 0.2 弧度）
                            Positioned(
                              right: 100,
                              top: 48,
                              child: Transform.rotate(
                                angle: 0.2,
                                child: Icon(
                                  CupertinoIcons.heart_fill,
                                  size: 18,
                                  color: const Color(0xFFFFB3BA).withValues(alpha: 0.35),
                                ),
                              ),
                            ),
                            // ✨ 固定中右偏上：柠檬黄闪烁小星（俏皮反向旋转 -0.15 弧度）
                            Positioned(
                              right: 135,
                              top: 20,
                              child: Transform.rotate(
                                angle: -0.15,
                                child: Icon(
                                  CupertinoIcons.star_fill,
                                  size: 11,
                                  color: const Color(0xFFFFF1C5).withValues(alpha: 0.45),
                                ),
                              ),
                            ),
                          ],
                          SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            physics: isMonth
                                ? const BouncingScrollPhysics()
                                : const NeverScrollableScrollPhysics(),
                            child: SizedBox(
                              width: finalWidth,
                              child: Stack(
                                children: [
                                  if (UserState().selectedIslandThemeId.value == 'lego')
                                    Positioned(
                                      left: 0,
                                      right: 0,
                                      top: 0,
                                      bottom: 40,
                                      child: CustomPaint(
                                        painter: _LegoBaseplatePainter(isNight: isNight),
                                      ),
                                    ),
                                  LineChart(
                                LineChartData(
                                  minX: -0.4,
                                  maxX: aggregatedPoints.length - 0.6,
                                  minY: -yLimit,
                                  maxY: yLimit,
                                  gridData: FlGridData(
                                    show: true,
                                    drawVerticalLine: false,
                                    getDrawingHorizontalLine: (value) {
                                      if (value == 0) {
                                        return FlLine(
                                          color: isNight
                                              ? Colors.white12
                                              : Colors.black.withValues(
                                                  alpha: 0.05,
                                                ),
                                          strokeWidth: 1.5,
                                        );
                                      }
                                      return FlLine(
                                        color: isNight
                                            ? Colors.white.withValues(
                                                alpha: 0.03,
                                              )
                                            : Colors.black.withValues(
                                                alpha: 0.01,
                                              ),
                                        strokeWidth: 1,
                                      );
                                    },
                                  ),
                                  titlesData: FlTitlesData(
                                    show: true,
                                    topTitles: const AxisTitles(
                                      sideTitles: SideTitles(showTitles: false),
                                    ),
                                    rightTitles: const AxisTitles(
                                      sideTitles: SideTitles(showTitles: false),
                                    ),
                                    leftTitles: const AxisTitles(
                                      sideTitles: SideTitles(showTitles: false),
                                    ),
                                    bottomTitles: AxisTitles(
                                      sideTitles: SideTitles(
                                        showTitles: true,
                                        reservedSize: 40,
                                        interval: 1,
                                        getTitlesWidget: (value, meta) {
                                          // 确保只在整数点显示标签，避免 minX 偏移导致的重复渲染
                                          if (value % 1 != 0) {
                                            return const SizedBox.shrink();
                                          }
                                          int index = value.round();
                                          if (index < 0 ||
                                              index >= aggregatedPoints.length) {
                                            return const SizedBox.shrink();
                                          }
                                          final p = aggregatedPoints[index];
                                          return Padding(
                                            padding: const EdgeInsets.only(
                                              top: 10,
                                            ),
                                            child: Column(
                                              children: [
                                                Text(
                                                  p['label'],
                                                  style: TextStyle(
                                                    fontSize: 11,
                                                    color: isNight
                                                        ? Colors.white70
                                                        : Colors.black87,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                                Text(
                                                  p['subLabel'],
                                                  style: TextStyle(
                                                    fontSize: 9,
                                                    color: isNight
                                                        ? Colors.white38
                                                        : Colors.black38,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          );
                                        },
                                      ),
                                    ),
                                  ),
                                  borderData: FlBorderData(show: false),
                                  lineBarsData: [barData],
                                  lineTouchData: LineTouchData(
                                    touchCallback: (event, response) {
                                      if (event is FlTapUpEvent) {
                                        if (response == null ||
                                            response.lineBarSpots == null ||
                                            response.lineBarSpots!.isEmpty) {
                                          updateMoodTrendX(null);
                                        } else {
                                          final spot =
                                              response.lineBarSpots!.first;
                                          updateMoodTrendX(spot.x.toInt());
                                        }
                                      }
                                    },
                                    touchTooltipData: LineTouchTooltipData(
                                      getTooltipColor: (_) =>
                                          Colors.transparent,
                                      getTooltipItems: (touchedSpots) =>
                                          touchedSpots.map((_) {
                                            return const LineTooltipItem(
                                              '',
                                              TextStyle(fontSize: 0),
                                            );
                                          }).toList(),
                                    ),
                                  ),
                                ),
                              ),
                              // 自定义提示框
                              if (_selectedMoodTrendX != null) ...[
                                // 辅助垂线
                                Positioned(
                                  left:
                                      (_selectedMoodTrendX! + 0.4) /
                                      (aggregatedPoints.length - 0.2) *
                                      finalWidth,
                                  top: 0,
                                  bottom: 40,
                                  child: Container(
                                    width: 1,
                                    color: isNight
                                        ? Colors.white.withValues(alpha: 0.15)
                                        : Colors.black.withValues(alpha: 0.1),
                                  ),
                                ),
                                _buildBentoTooltip(
                                  title:
                                      '${aggregatedPoints[_selectedMoodTrendX!]['label']}日 ${aggregatedPoints[_selectedMoodTrendX!]['subLabel']}',
                                  items: [
                                    _BentoTooltipItem(
                                      label: '情绪指数',
                                      value: spots[_selectedMoodTrendX!].y
                                          .toStringAsFixed(1),
                                      color: spots[_selectedMoodTrendX!].y >= 0
                                          ? themeColor
                                          : (isNight
                                                ? const Color(0xFF448AFF)
                                                : const Color(0xFF2196F3)),
                                    ),
                                  ],
                                  relativeX:
                                      (_selectedMoodTrendX! + 0.4) /
                                      (aggregatedPoints.length - 0.2),
                                  chartWidth: finalWidth,
                                  isNight: isNight,
                                  useCottonCandyStyle: isCottonCandy,
                                ),
                              ],

                              // 🌸 波峰极值心情插画贴纸 (一比一复刻设计图样式)
                              if (maxIdx != -1 &&
                                  aggregatedPoints[maxIdx]['moodIcon'] !=
                                      null) ...[
                                () {
                                  final spot = spots[maxIdx];
                                  final iconPath =
                                      aggregatedPoints[maxIdx]['moodIcon']
                                          as String;
                                  // 水平 X 绝对坐标精算 (减去贴纸半径 14.0 以完美居中)
                                  final double spotX =
                                      (maxIdx + 0.4) /
                                      (aggregatedPoints.length - 0.2) *
                                      finalWidth;
                                  // 垂直 Y 绝对坐标像素精算 (基于卡片总高度 180px - 底部 X 轴 reservedSize 40px = 140px 净绘图高进行无偏差插值)
                                  final double spotY =
                                      (yLimit - spot.y) / (yLimit * 2) * 140.0;
                                  return Positioned(
                                    left: spotX - 14.0,
                                    top: (spotY - 14.0).clamp(4.0, 140.0),
                                    child: _buildMoodTrendIconStick(
                                      iconPath: iconPath,
                                      isMax: true,
                                      isNight: isNight,
                                    ),
                                  );
                                }(),
                              ],

                              // ❄️ 波谷极值心情插画贴纸 (一比一复刻设计图样式)
                              if (minIdx != -1 &&
                                  maxIdx != minIdx &&
                                  aggregatedPoints[minIdx]['moodIcon'] !=
                                      null) ...[
                                () {
                                  final spot = spots[minIdx];
                                  final iconPath =
                                      aggregatedPoints[minIdx]['moodIcon']
                                          as String;
                                  final double spotX =
                                      (minIdx + 0.4) /
                                      (aggregatedPoints.length - 0.2) *
                                      finalWidth;
                                  // 垂直 Y 绝对坐标像素精算 (同上，140.0px 净绘图高完美比例线性缩放)
                                  final double spotY =
                                      (yLimit - spot.y) / (yLimit * 2) * 140.0;
                                  return Positioned(
                                    left: spotX - 14.0,
                                    top: (spotY - 14.0 + 3).clamp(4.0, 140.0),
                                    child: _buildMoodTrendIconStick(
                                      iconPath: iconPath,
                                      isMax: false,
                                      isNight: isNight,
                                    ),
                                  );
                                }(),
                              ],
                            ],
                          ),
                        ),
                      ),
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

  Future<String> _getMoodTrendSummaryFuture(List<Map<String, dynamic>> points) {
    final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
    final key = '${today}_${_moodTrendRangeKey()}';
    return _moodTrendSummaryFutures.putIfAbsent(
      key,
      () => _loadMoodTrendSummary(points),
    );
  }

  Future<String> _loadMoodTrendSummary(
    List<Map<String, dynamic>> points,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    final state = UserState();
    final rangeKey = _moodTrendRangeKey();
    final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
    final textKey = state.n('mood_trend_summary_$rangeKey');
    final dateKey = state.n('mood_trend_summary_${rangeKey}_date');
    final cachedDate = prefs.getString(dateKey);
    final cachedText = prefs.getString(textKey);

    if (cachedDate == today &&
        cachedText != null &&
        cachedText.trim().isNotEmpty) {
      return cachedText.trim();
    }

    final fallback = _buildLocalMoodTrendSummary(points);
    final aiSummary = await AIService().summarizeMoodTrend(
      state.deepseekApiKey.value,
      rangeLabel: _moodTrendRangeLabel(),
      trendData: _formatMoodTrendData(points),
      fallbackSummary: fallback,
    );

    final summary = _normalizeMoodTrendSummary(aiSummary ?? fallback);
    if (state.deepseekApiKey.value.isNotEmpty &&
        state.deepseekApiKey.value != 'YOUR_API_KEY') {
      await prefs.setString(textKey, summary);
      await prefs.setString(dateKey, today);
    }
    return summary;
  }

  String _buildLocalMoodTrendSummary(List<Map<String, dynamic>> points) {
    final realScores = points
        .where((p) => p['hasData'] == true)
        .map((p) => p['score'] as double)
        .toList();

    if (realScores.length < 2) {
      return '记录还不多，但已能看见一点起伏';
    }

    final avg = realScores.reduce((a, b) => a + b) / realScores.length;
    final half = (realScores.length / 2).ceil();
    final early = realScores.take(half).reduce((a, b) => a + b) / half;
    final lateValues = realScores.skip(half).toList();
    final late = lateValues.isEmpty
        ? early
        : lateValues.reduce((a, b) => a + b) / lateValues.length;
    double movement = 0;
    for (int i = 1; i < realScores.length; i++) {
      movement += (realScores[i] - realScores[i - 1]).abs();
    }
    final wave = movement / (realScores.length - 1);

    final base = avg > 1.2
        ? '${_moodTrendRangeLabel()}情绪整体偏明亮'
        : (avg < -1.2
              ? '${_moodTrendRangeLabel()}情绪整体偏低缓'
              : '${_moodTrendRangeLabel()}情绪整体偏柔和');

    if ((late - early).abs() > 1.2) {
      return late > early ? '$base，后段慢慢回升' : '$base，后段略有下沉';
    }
    if (wave > 2.0) {
      return '$base，期间起伏较明显';
    }
    return '$base，后段略有波动';
  }

  String _formatMoodTrendData(List<Map<String, dynamic>> points) {
    return points
        .where((p) => p['hasData'] == true)
        .map(
          (p) => '${p['label']}:${(p['score'] as double).toStringAsFixed(1)}',
        )
        .join('，');
  }

  String _normalizeMoodTrendSummary(String text) {
    final cleaned = text
        .replaceAll('\n', '')
        .replaceAll(RegExp(r'^[「“"]|[」”"]$'), '')
        .trim();
    if (cleaned.length <= 34) return cleaned;
    return cleaned.substring(0, 34);
  }

  String _moodTrendRangeKey() {
    switch (_currentRange) {
      case StatTimeRange.week:
        return 'week';
      case StatTimeRange.month:
        return 'month';
      case StatTimeRange.all:
        return 'all';
    }
  }

  String _moodTrendRangeLabel() {
    switch (_currentRange) {
      case StatTimeRange.week:
        return '本周';
      case StatTimeRange.month:
        return '本月';
      case StatTimeRange.all:
        return '整体';
    }
  }

  /// 依据「峰值强度定律」从当天的全部日记中筛出情绪最强烈的一本，作为代言图标
  String? _resolvePeakMoodIconPath(List<DiaryEntry> diaries) {
    if (diaries.isEmpty) return null;

    // 寻找强度（intensity，数值越大越强烈）最高的那篇日记
    final peakEntry = diaries.reduce(
      (a, b) => a.intensity >= b.intensity ? a : b,
    );
    final int moodIdx = peakEntry.moodIndex % kMoods.length;

    // 映射日记内置的心情插画 assets/icons 文件名
    const icons = [
      'happy.png', // 0: 开心
      'calm.png', // 1: 平静
      'down.png', // 2: 低落
      'irritated.png', // 3: 易怒
      'tired.png', // 4: 疲惫
      'surprise.png', // 5: 惊喜
      'shy.png', // 6: 害羞
      'anxious.png', // 7: 焦虑
      'wronged.png', // 8: 委屈
      'bored.png', // 9: 无聊
      'expect.png', // 10: 期待
    ];

    final name = moodIdx >= 0 && moodIdx < icons.length
        ? icons[moodIdx]
        : 'happy.png';
    return 'assets/icons/$name';
  }

  /// 极致还原设计图样式的极值表情小贴纸 (圆形、温润半透明白边、高光投影)
  Widget _buildMoodTrendIconStick({
    required String iconPath,
    required bool isMax,
    required bool isNight,
  }) {
    return Container(
      width: 28,
      height: 28,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: isNight
            ? const Color(0xFF2C2C35)
            : Colors.white.withValues(alpha: 0.82),
        border: Border.all(
          color: isMax
              ? const Color(0xFFFF5252).withValues(
                  alpha: 0.8,
                ) // 🔥 最高峰：红色半透明高亮描边
              : const Color(
                  0xFF448AFF,
                ).withValues(alpha: 0.8), // ❄️ 最低谷：蓝色半透明高亮描边
          width: 2.0,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.12),
            blurRadius: 4,
            offset: const Offset(0, 1.5), // 浮空阴影
          ),
        ],
      ),
      padding: const EdgeInsets.all(3.5), // 边缘合理内缩以防贴边，营造呼吸感
      child: Image.asset(iconPath, fit: BoxFit.contain),
    );
  }
}

Widget _buildMoodTrendYLabel(
  String value,
  String label,
  Color labelColor,
  bool isNight,
) {
  return Column(
    mainAxisSize: MainAxisSize.min,
    children: [
      Text(
        value,
        style: TextStyle(
          color: isNight ? Colors.white38 : const Color(0xFF9C7E68),
          fontSize: 11,
          height: 1,
          letterSpacing: 0,
          fontFamily: 'LXGWWenKai',
        ),
      ),
      const SizedBox(height: 5),
      Text(
        label,
        style: TextStyle(
          color: isNight ? labelColor.withValues(alpha: 0.82) : labelColor,
          fontSize: 11,
          height: 1,
          letterSpacing: 0,
          fontFamily: 'LXGWWenKai',
          fontWeight: FontWeight.w500,
        ),
      ),
    ],
  );
}

Widget _buildYLabel(String text, bool isNight) {
  return Text(
    text,
    style: TextStyle(
      color: isNight ? Colors.white24 : Colors.black26,
      fontSize: 10,
    ),
  );
}

String _getChineseWeekDay(int weekday) {
  const list = ['一', '二', '三', '四', '五', '六', '日'];
  return list[weekday - 1];
}

class _LegoBaseplatePainter extends CustomPainter {
  final bool isNight;
  _LegoBaseplatePainter({required this.isNight});

  @override
  void paint(Canvas canvas, Size size) {
    const double step = 14.0;
    const double radius = 3.5;

    final Color studColor = isNight
        ? Colors.white.withValues(alpha: 0.007)
        : const Color(0xFFE5ECF6).withValues(alpha: 0.15); // 极其柔和淡淡的浅灰蓝

    final Color shadowColor = isNight
        ? Colors.black.withValues(alpha: 0.03)
        : const Color(0x04000000);

    final Color highlightColor = isNight
        ? Colors.white.withValues(alpha: 0.015)
        : Colors.white.withValues(alpha: 0.2);

    final Paint paintMain = Paint()..color = studColor..style = PaintingStyle.fill;
    final Paint paintShadow = Paint()..color = shadowColor..style = PaintingStyle.fill;
    final Paint paintHighlight = Paint()..color = highlightColor..style = PaintingStyle.fill;

    for (double x = step / 2; x < size.width; x += step) {
      for (double y = step / 2; y < size.height; y += step) {
        // 1. 绘制阴影（右下微偏）
        canvas.drawCircle(Offset(x + 0.6, y + 0.6), radius, paintShadow);
        // 2. 绘制高光（左上微偏）
        canvas.drawCircle(Offset(x - 0.6, y - 0.6), radius, paintHighlight);
        // 3. 绘制主体圆粒
        canvas.drawCircle(Offset(x, y), radius, paintMain);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
