part of '../../pages/statistics_page.dart';

extension _BentoBehavioralAnalysis on _StatisticsPageState {
  bool _hasWeatherData(List<DiaryEntry> filtered) {
    return filtered.any(
      (e) => e.weather != null && e.weather!.isNotEmpty && e.weather != '未设置',
    );
  }

  Widget _buildWeatherMoodBento(bool isNight, List<DiaryEntry> filtered) {
    final bool isCottonCandy =
        UserState().selectedIslandThemeId.value == 'cotton_candy';
    final Map<String, List<DiaryEntry>> weatherGroups = {};
    for (final e in filtered) {
      if (e.weather != null && e.weather!.isNotEmpty && e.weather != '未设置') {
        weatherGroups.putIfAbsent(e.weather!, () => []);
        weatherGroups[e.weather!]!.add(e);
      }
    }

    if (weatherGroups.isEmpty) return const SizedBox.shrink();

    final sortedWeather = weatherGroups.entries.toList()
      ..sort((a, b) => b.value.length.compareTo(a.value.length));
    final displayWeather = sortedWeather.take(2).toList();

    return _buildGlassCard(
      isNight: isNight,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildBentoHeader(
            context: context,
            title: '气象共鸣',
            helpContent: '分析不同天气与你情绪的关系，看清自然律动如何影响你的心情。',
            isNight: isNight,
            rightAction: Icon(
              CupertinoIcons.cloud_sun,
              size: 18,
              color: isCottonCandy
                  ? const Color(0xFFF7AAB6)
                  : (isNight ? Colors.white54 : Colors.black38),
            ),
          ),
          const SizedBox(height: 12),
          ...displayWeather.map((e) {
            final avg =
                e.value.fold<double>(0.0, (sum, d) => sum + d.intensity) /
                e.value.length;
            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '${e.key}天 (${e.value.length}次)',
                        style: TextStyle(
                          fontSize: 12,
                          color: isNight ? Colors.white70 : Colors.black87,
                        ),
                      ),
                      Text(
                        '${(avg * 10).toStringAsFixed(0)}分',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: isNight
                              ? Colors.white
                              : const Color(0xFFD4A373),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Stack(
                    children: [
                      Container(
                        height: 4,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: isNight
                              ? Colors.white10
                              : Colors.black.withValues(alpha: 0.05),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      FractionallySizedBox(
                        widthFactor: avg / 10.0,
                        child: Container(
                          height: 4,
                          decoration: BoxDecoration(
                            color: const Color(
                              0xFFD4A373,
                            ).withValues(alpha: 0.8),
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildTimePatternBento(bool isNight, List<DiaryEntry> filtered) {
    if (filtered.isEmpty) {
      return const SizedBox.shrink();
    }

    final List<List<DiaryEntry>> groups = List.generate(4, (_) => []);
    for (final e in filtered) {
      final h = e.dateTime.hour;
      if (h < 6) {
        groups[0].add(e);
      } else if (h < 12) {
        groups[1].add(e);
      } else if (h < 18) {
        groups[2].add(e);
      } else {
        groups[3].add(e);
      }
    }

    final counts = groups.map((e) => e.length).toList();
    final maxCount = counts.isEmpty ? 0 : counts.reduce(max);
    final maxIndex = counts.indexOf(maxCount);
    final bool isCottonCandy =
        UserState().selectedIslandThemeId.value == 'cotton_candy';

    final timeLabels = [
      {
        'label': '凌晨',
        'icon': CupertinoIcons.sparkles,
        'color': const Color(0xFF8E9BFF),
      },
      {
        'label': '上午',
        'icon': CupertinoIcons.sunrise_fill,
        'color': const Color(0xFFFFA24A),
      },
      {
        'label': '下午',
        'icon': CupertinoIcons.sun_max_fill,
        'color': const Color(0xFFFFC36A),
      },
      {
        'label': '晚上',
        'icon': CupertinoIcons.moon_stars_fill,
        'color': const Color(0xFF9FA7B8),
      },
    ];

    final dominantLabel = maxCount > 0
        ? timeLabels[maxIndex]['label'] as String
        : '暂无';
    final dominantCount = maxCount;
    final dominantRate = filtered.isNotEmpty
        ? dominantCount / filtered.length
        : 0.0;
    final dominantSentence = dominantCount > 0
        ? '于【$dominantLabel】时分，您的灵魂星图最为璀璨。'
        : '还没有足够的时间分布数据。';

    return _buildGlassCard(
      isNight: isNight,
      backgroundColor: isCottonCandy ? const Color(0xFFFFF4EF) : null,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildBentoHeader(
            context: context,
            title: '独处时刻',
            helpContent: '统计你最常记录日记的时间段，帮助你找到自己的写作节律。',
            isNight: isNight,
            rightAction: Icon(
              CupertinoIcons.star_lefthalf_fill,
              size: 18,
              color: isCottonCandy
                  ? const Color(0xFFF7AAB6)
                  : (isNight ? Colors.white54 : Colors.black38),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            dominantSentence,
            style: TextStyle(
              fontSize: 13,
              height: 1.45,
              color: isNight ? Colors.white70 : const Color(0xFF7E5D51),
              fontFamily: 'LXGWWenKai',
            ),
          ),
          if (dominantCount > 0) ...[
            const SizedBox(height: 8),
            Text(
              '占比 ${(dominantRate * 100).toStringAsFixed(0)}%，共 $dominantCount 篇记录。',
              style: TextStyle(
                fontSize: 11,
                color: isNight ? Colors.white38 : Colors.black38,
              ),
            ),
          ],
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: List.generate(4, (index) {
              final double heightFactor = maxCount > 0
                  ? (counts[index] / maxCount)
                  : 0;
              final Color baseColor = timeLabels[index]['color'] as Color;
              final int count = counts[index];

              return GestureDetector(
                onTap: () => _showTimePatternDetailSheet(
                  context: context,
                  isNight: isNight,
                  label: timeLabels[index]['label'] as String,
                  icon: timeLabels[index]['icon'] as IconData,
                  color: baseColor,
                  entries: groups[index],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    AnimatedContainer(
                          duration: const Duration(milliseconds: 600),
                          width: 34,
                          height: 26 + (heightFactor * 58),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.bottomCenter,
                              end: Alignment.topCenter,
                              colors: [
                                baseColor.withValues(alpha: 0.82),
                                baseColor.withValues(alpha: 0.36),
                              ],
                            ),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.22),
                              width: 0.8,
                            ),
                            borderRadius: BorderRadius.circular(18),
                            boxShadow: [
                              BoxShadow(
                                color: baseColor.withValues(alpha: 0.16),
                                blurRadius: 14,
                                offset: const Offset(0, 6),
                              ),
                            ],
                          ),
                          child: Padding(
                            padding: const EdgeInsets.only(
                              top: 6,
                              left: 6,
                              right: 6,
                              bottom: 6,
                            ),
                            child: Align(
                              alignment: Alignment.topCenter,
                              child: Icon(
                                timeLabels[index]['icon'] as IconData,
                                size: 17,
                                color: Colors.white.withValues(alpha: 0.68),
                              ),
                            ),
                          ),
                        )
                        .animate(onPlay: (c) => c.repeat(reverse: true))
                        .shimmer(
                          duration: (1600 + index * 180).ms,
                          color: Colors.white.withValues(alpha: 0.16),
                        ),
                    const SizedBox(height: 10),
                    Text(
                      timeLabels[index]['label'] as String,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.normal,
                        color: isNight ? Colors.white54 : Colors.black54,
                      ),
                    ),
                    Text(
                      '$count 次',
                      style: TextStyle(
                        fontSize: 9,
                        color: isNight ? Colors.white38 : Colors.black38,
                      ),
                    ),
                  ],
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  void _showTimePatternDetailSheet({
    required BuildContext context,
    required bool isNight,
    required String label,
    required IconData icon,
    required Color color,
    required List<DiaryEntry> entries,
  }) {
    final sortedEntries = List<DiaryEntry>.from(entries)
      ..sort((a, b) => b.dateTime.compareTo(a.dateTime));

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        return Container(
          height: MediaQuery.of(context).size.height * 0.7,
          decoration: BoxDecoration(
            color: isNight ? const Color(0xFF1E1E1E) : const Color(0xFFFDF7F0),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: Column(
            children: [
              const SizedBox(height: 8),
              Container(
                width: 42,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 16),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  children: [
                    Container(
                      width: 14,
                      height: 14,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: color,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '$label 时段记录',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: isNight ? Colors.white : Colors.black87,
                        ),
                      ),
                    ),
                    Icon(icon, color: color, size: 18),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    '这个时段共 ${sortedEntries.length} 条记录。',
                    style: TextStyle(
                      fontSize: 12,
                      color: isNight ? Colors.white54 : Colors.black45,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                  itemCount: sortedEntries.length,
                  itemBuilder: (context, index) {
                    final entry = sortedEntries[index];
                    final mood = kMoods[entry.moodIndex % kMoods.length];
                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: isNight ? Colors.white10 : Colors.white,
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(
                          color: color.withValues(alpha: isNight ? 0.14 : 0.12),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                DateFormat(
                                  'MM/dd HH:mm',
                                ).format(entry.dateTime),
                                style: TextStyle(
                                  fontSize: 12,
                                  color: isNight
                                      ? Colors.white54
                                      : Colors.black45,
                                ),
                              ),
                              const Spacer(),
                              Text(
                                mood.label,
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: color,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            _truncateMemoryText(
                              entry.content.replaceAll('\n', ' '),
                              80,
                            ),
                            maxLines: 3,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 13,
                              height: 1.5,
                              color: isNight ? Colors.white70 : Colors.black87,
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  String _truncateMemoryText(String text, int maxLength) {
    final normalized = text.trim();
    if (normalized.length <= maxLength) return normalized;
    return '${normalized.substring(0, maxLength)}...';
  }

  Widget _buildMonthlyMoodWeatherBento(
    bool isNight,
    List<DiaryEntry> filtered,
    Color themeColor,
  ) {
    final summary = _resolveMonthlyMoodWeather(filtered);
    final selectedId = _selectedMoodWeatherStateId ?? summary.stateId;
    final state = _monthlyMoodWeatherStates.firstWhere(
      (item) => item.id == selectedId,
      orElse: () => _monthlyMoodWeatherStates.first,
    );

    final bool isCottonCandy =
        UserState().selectedIslandThemeId.value == 'cotton_candy';
    final Color textColor = isNight ? Colors.white : const Color(0xFF5A3E28);
    final Color subTextColor = isNight
        ? Colors.white60
        : const Color(0xFF8A7462);

    // 仅在棉花糖主题下映射专属精美手绘插图，其他主题保持通用默认图
    String bgAsset = 'assets/images/background/data_3_tianqing.png';
    String weatherAsset = 'assets/images/background/data_3_tianqing2.png';

    if (isCottonCandy) {
      if (state.id == 'mistMorning' ||
          state.id == 'lightRain' ||
          state.id == 'continuousRain' ||
          state.id == 'thunder') {
        bgAsset = 'assets/images/background/data_3_xiayu.png';
        weatherAsset = 'assets/images/background/data_3_xiayu2.png';
      } else if (state.id == 'cloudDrift' || state.id == 'softBreeze') {
        bgAsset = 'assets/images/background/data_3_duoyun.png';
        weatherAsset = 'assets/images/background/data_3_duoyun2.png';
      } else {
        bgAsset = 'assets/images/background/data_3_qingtian.png';
        weatherAsset = 'assets/images/background/data_3_qingtian2.png';
      }
    }

    final Widget content = Stack(
      children: [
        // 右侧漂浮岛屿手绘插图
        Positioned(
          right: 0,
          top: 0,
          bottom: 44,
          width: 180,
          child: IgnorePointer(
            child: Image.asset(bgAsset, fit: BoxFit.contain),
          ),
        ),
        // 中间治愈晴云手绘插图
        Positioned(
          left: 90,
          top: 20,
          width: 60,
          height: 60,
          child: IgnorePointer(
            child: Image.asset(weatherAsset, fit: BoxFit.contain),
          ),
        ),
        // 主体内容
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildBentoHeader(
              context: context,
              title: '本月心情天气',
              helpContent:
                  '把本月的心情状态翻译成天气：晴空、云层、细雨和雷阵雨分别对应整体情绪、波动程度和回升趋势，让数据更像一段可以被感受的天气。',
              isNight: isNight,
            ),
            const SizedBox(height: 14),
            // 心情气象标签与文学叙事
            Padding(
              padding: const EdgeInsets.only(right: 180),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    state.label,
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: textColor,
                      fontFamily: 'LXGWWenKai',
                      letterSpacing: 1.0,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    state.description,
                    style: TextStyle(
                      color: subTextColor,
                      fontSize: 12.5,
                      height: 1.5,
                      fontFamily: 'LXGWWenKai',
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            // 底部横向四卡片 Bento 指标组
            Row(
              children: [
                Expanded(
                  child: _buildMoodWeatherMetricChip(
                    icon: '😊',
                    label: '开心日',
                    value: '${summary.sunnyDays}天',
                    isNight: isNight,
                  ),
                ),
                const SizedBox(width: 5),
                Expanded(
                  child: _buildMoodWeatherMetricChip(
                    icon: '☁️',
                    label: '低落日',
                    value: '${summary.rainyDays}天',
                    isNight: isNight,
                  ),
                ),
                const SizedBox(width: 5),
                Expanded(
                  child: _buildMoodWeatherMetricChip(
                    icon: '〽️',
                    label: '情绪波动',
                    value: summary.volatilityLabel == '高'
                        ? '高'
                        : (summary.volatilityLabel == '中' ? '中等' : '轻微'),
                    isNight: isNight,
                  ),
                ),
                const SizedBox(width: 5),
                Expanded(
                  child: _buildMoodWeatherMetricChip(
                    icon: '💗',
                    label: '记录天数',
                    value: '${summary.recordDays}天',
                    isNight: isNight,
                  ),
                ),
              ],
            ),
          ],
        ),
      ],
    );

    if (isNight) {
      return _buildGlassCard(
        isNight: isNight,
        padding: EdgeInsets.zero,
        child: Container(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            gradient: isCottonCandy
                ? null
                : const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFF23232F), Color(0xFF16161D)],
                  ),
            color: isCottonCandy ? Colors.transparent : null,
          ),
          child: content,
        ),
      );
    } else {
      return _buildGlassCard(
        isNight: isNight,
        backgroundColor: isCottonCandy
            ? const Color(0xFFFFF4EF).withValues(alpha: 1)
            : null,
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
        child: content,
      );
    }
  }

  Widget _buildMoodWeatherMetricChip({
    required String icon,
    required String label,
    required String value,
    required bool isNight,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 6),
      decoration: BoxDecoration(
        color: isNight
            ? Colors.white.withValues(alpha: 0.05)
            : Colors.white.withValues(alpha: 0.85),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isNight
              ? Colors.white.withValues(alpha: 0.08)
              : const Color(0xFFFFF0EC),
          width: 1,
        ),
        boxShadow: isNight
            ? null
            : [
                BoxShadow(
                  color: const Color(0xFF5A3E28).withValues(alpha: 0.03),
                  blurRadius: 6,
                  offset: const Offset(0, 3),
                ),
              ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(icon, style: const TextStyle(fontSize: 14)),
          const SizedBox(width: 3),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 9.5,
                    color: isNight ? Colors.white54 : const Color(0xFF8A7462),
                    fontFamily: 'LXGWWenKai',
                  ),
                ),
                const SizedBox(height: 1),
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: isNight ? Colors.white : const Color(0xFF4A3423),
                    fontFamily: 'LXGWWenKai',
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  _MonthlyMoodWeatherSummary _resolveMonthlyMoodWeather(
    List<DiaryEntry> filtered,
  ) {
    if (filtered.isEmpty) {
      return const _MonthlyMoodWeatherSummary(
        stateId: 'sunny',
        label: '晴空万里',
        subtitle: '等待更多记录',
        description: '这个月还没有足够的记录，先把心情留在晴空里，等更多日子被慢慢填满。',
        caption: '记录还在继续，晴空先留白。',
        score: 0,
        sunnyDays: 0,
        rainyDays: 0,
        recordDays: 0,
        volatilityLabel: '低',
        volatilityAccent: Color(0xFF8AB6FF),
        rainAccent: Color(0xFF7A98C9),
      );
    }

    final Map<String, double> dailyScore = {};
    final Map<String, int> dailyCount = {};

    for (final entry in filtered) {
      final key = DateFormat('yyyy-MM-dd').format(entry.dateTime);
      final score =
          _moodWeatherWeight(entry.moodIndex) *
          (0.35 + (entry.intensity.clamp(0.0, 10.0) / 10.0) * 0.65);
      dailyScore[key] = (dailyScore[key] ?? 0) + score;
      dailyCount[key] = (dailyCount[key] ?? 0) + 1;
    }

    final List<double> scores = [];
    final List<String> orderedKeys = dailyScore.keys.toList()..sort();
    for (final key in orderedKeys) {
      final count = dailyCount[key] ?? 1;
      scores.add(dailyScore[key]! / count);
    }

    final double score = scores.isEmpty
        ? 0
        : scores.reduce((a, b) => a + b) / scores.length;
    double volatility = 0;
    for (int i = 1; i < scores.length; i++) {
      volatility += (scores[i] - scores[i - 1]).abs();
    }
    volatility = scores.length > 1 ? volatility / (scores.length - 1) : 0;

    final int sunnyDays = scores.where((e) => e > 0.18).length;
    final int rainyDays = scores.where((e) => e < -0.18).length;
    final int neutralDays = scores.length - sunnyDays - rainyDays;
    final int recordDays = scores.length;

    double trend = 0.0;
    if (scores.length >= 4) {
      final half = (scores.length / 2).floor();
      final early = scores.take(half).toList();
      final late = scores.skip(half).toList();
      final earlyAvg = early.isEmpty
          ? 0.0
          : early.reduce((a, b) => a + b) / early.length;
      final lateAvg = late.isEmpty
          ? 0.0
          : late.reduce((a, b) => a + b) / late.length;
      trend = lateAvg - earlyAvg;
    }

    String stateId = 'cloudDrift';
    if (volatility >= 0.55) {
      stateId = 'thunder';
    } else if (trend >= 0.22 && score < 0.2) {
      stateId = 'afterRain';
    } else if (score >= 0.55) {
      stateId = 'sunny';
    } else if (score >= 0.32) {
      stateId = rainyDays > 0 ? 'partlyCloudy' : 'warmBreeze';
    } else if (score >= 0.12) {
      stateId = neutralDays > sunnyDays ? 'cloudDrift' : 'warmBreeze';
    } else if (score >= -0.08) {
      stateId = volatility >= 0.24 ? 'softBreeze' : 'cloudDrift';
    } else if (score >= -0.28) {
      stateId = volatility >= 0.3 ? 'lightRain' : 'mistMorning';
    } else if (trend > 0.05) {
      stateId = 'afterRain';
    } else {
      stateId = rainyDays >= (recordDays * 0.65).ceil()
          ? 'continuousRain'
          : 'lightRain';
    }

    final config = _monthlyMoodWeatherStates.firstWhere(
      (item) => item.id == stateId,
      orElse: () => _monthlyMoodWeatherStates.first,
    );

    return _MonthlyMoodWeatherSummary(
      stateId: config.id,
      label: config.label,
      subtitle: config.subtitle,
      description: config.description,
      caption: config.caption,
      score: score.clamp(-1.0, 1.0),
      sunnyDays: sunnyDays,
      rainyDays: rainyDays,
      recordDays: recordDays,
      volatilityLabel: _moodWeatherVolatilityLabel(volatility),
      volatilityAccent: config.accentColor,
      rainAccent: const Color(0xFF7EA8E8),
    );
  }

  double _moodWeatherWeight(int moodIndex) {
    switch (moodIndex % kMoods.length) {
      case 0:
      case 5:
      case 10:
        return 1.0;
      case 1:
      case 4:
      case 6:
      case 9:
        return 0.15;
      case 2:
      case 3:
      case 7:
      case 8:
        return -1.0;
      default:
        return 0.0;
    }
  }

  String _moodWeatherVolatilityLabel(double volatility) {
    if (volatility >= 0.55) return '高';
    if (volatility >= 0.28) return '中';
    return '低';
  }

  List<_MonthlyMoodWeatherStateConfig> get _monthlyMoodWeatherStates => const [
    _MonthlyMoodWeatherStateConfig(
      id: 'sunny',
      label: '晴空万里',
      subtitle: '晴朗而稳定',
      description: '整体情绪很亮，开心和轻松占了上风，几乎没有明显的阴影。',
      caption: '本月像一整片打开的晴空，心情通透、轻快、也很稳。',
      accentColor: Color(0xFFFFB84D),
      overlayStart: Color(0xFFFFD98B),
      overlayEnd: Color(0xFFF7A764),
      icon: CupertinoIcons.sun_max_fill,
      backgroundAsset: 'assets/images/background/data_3_tianqing.png',
    ),
    _MonthlyMoodWeatherStateConfig(
      id: 'partlyCloudy',
      label: '晴间多云',
      subtitle: '亮色为主，偶有云层',
      description: '整体情绪偏柔和，开心的日子居多\n中旬有些小低落，月底逐渐回暖 🌈',
      caption: '大部分时间都在晴朗区间，只是偶尔会有云朵经过。',
      accentColor: Color(0xFFFFB7A1),
      overlayStart: Color(0xFFFFE0C8),
      overlayEnd: Color(0xFFF4B7D1),
      icon: CupertinoIcons.cloud_sun_fill,
      backgroundAsset: 'assets/images/background/data_3_tianqing.png',
    ),
    _MonthlyMoodWeatherStateConfig(
      id: 'warmBreeze',
      label: '暖风轻拂',
      subtitle: '温和上升',
      description: '情绪比较柔软，恢复感在慢慢累积，整体轻松又不张扬。',
      caption: '像一阵刚刚好的风，吹过时不刺眼，也不急躁。',
      accentColor: Color(0xFFF1B57C),
      overlayStart: Color(0xFFFFE6CE),
      overlayEnd: Color(0xFFF3CDB3),
      icon: CupertinoIcons.wind,
      backgroundAsset: 'assets/images/background/data_3_tianqing.png',
    ),
    _MonthlyMoodWeatherStateConfig(
      id: 'cloudDrift',
      label: '云朵漫游',
      subtitle: '平稳漂浮',
      description: '情绪比较平和，没有特别强烈的上扬或下沉，更像轻轻飘着。',
      caption: '这是一种安静的中间地带，情绪有空间，步调也不急。',
      accentColor: Color(0xFFB6C8E6),
      overlayStart: Color(0xFFF0F6FF),
      overlayEnd: Color(0xFFDDE9FA),
      icon: CupertinoIcons.cloud_fill,
      backgroundAsset: 'assets/images/background/data_3_tianqing.png',
    ),
    _MonthlyMoodWeatherStateConfig(
      id: 'softBreeze',
      label: '微风多云',
      subtitle: '轻微波动',
      description: '不算特别明亮，但也没有压得很重，心情在平静和疲惫之间摆动。',
      caption: '像有一点风，也有一点云，整体还算克制而安稳。',
      accentColor: Color(0xFF97B7D8),
      overlayStart: Color(0xFFEAF1F9),
      overlayEnd: Color(0xFFCAD9EA),
      icon: CupertinoIcons.wind,
      backgroundAsset: 'assets/images/background/data_3_tianqing.png',
    ),
    _MonthlyMoodWeatherStateConfig(
      id: 'mistMorning',
      label: '雾气清晨',
      subtitle: '朦胧而缓慢',
      description: '情绪偏低，更多是疲惫、迟疑和看不清方向的感觉。',
      caption: '像清晨的薄雾，能见度不高，但并不意味着不会慢慢散开。',
      accentColor: Color(0xFF9EAAC1),
      overlayStart: Color(0xFFE9EEF4),
      overlayEnd: Color(0xFFCBD4E1),
      icon: CupertinoIcons.cloud_fog_fill,
      backgroundAsset: 'assets/images/background/data_3_tianqing.png',
    ),
    _MonthlyMoodWeatherStateConfig(
      id: 'lightRain',
      label: '阴天小雨',
      subtitle: '轻度低落',
      description: '低落感开始变得可见，但还没有沉到最深处，仍然保留一点恢复空间。',
      caption: '细雨落得不大，但足够让人感受到需要被轻轻安放。',
      accentColor: Color(0xFF83A6D8),
      overlayStart: Color(0xFFDCE7F7),
      overlayEnd: Color(0xFFB7CDEB),
      icon: CupertinoIcons.cloud_rain_fill,
      backgroundAsset: 'assets/images/background/data_3_tianqing.png',
    ),
    _MonthlyMoodWeatherStateConfig(
      id: 'continuousRain',
      label: '连绵细雨',
      subtitle: '持续阴湿',
      description: '低落持续得更久，情绪恢复得慢一些，需要更多耐心和照顾。',
      caption: '雨线并不大，但连着下的时间很长，天空始终没完全放晴。',
      accentColor: Color(0xFF6F90BE),
      overlayStart: Color(0xFFC9D9F2),
      overlayEnd: Color(0xFF9FB9DE),
      icon: CupertinoIcons.cloud_rain_fill,
      backgroundAsset: 'assets/images/background/data_3_tianqing.png',
    ),
    _MonthlyMoodWeatherStateConfig(
      id: 'thunder',
      label: '雷阵雨',
      subtitle: '起伏明显',
      description: '这个月的情绪波动很大，起落交替，像骤雨一样变化得比较快。',
      caption: '有亮起的时候，也有骤然落下的时候，情绪节奏不太稳定。',
      accentColor: Color(0xFF8C95FF),
      overlayStart: Color(0xFFC8D0FF),
      overlayEnd: Color(0xFF8EA0E6),
      icon: CupertinoIcons.cloud_bolt_rain_fill,
      backgroundAsset: 'assets/images/background/data_3_tianqing.png',
    ),
    _MonthlyMoodWeatherStateConfig(
      id: 'afterRain',
      label: '雨后放晴',
      subtitle: '逐渐回暖',
      description: '前面有过低落，但后半段明显回升，整个月的走向是在变好。',
      caption: '雨停之后，天空开始发亮，恢复感是这段时间最重要的线索。',
      accentColor: Color(0xFFFFB090),
      overlayStart: Color(0xFFFFE2CD),
      overlayEnd: Color(0xFFF1C9AE),
      icon: CupertinoIcons.cloud_sun_rain_fill,
      backgroundAsset: 'assets/images/background/data_3_tianqing.png',
    ),
  ];
}

class _MonthlyMoodWeatherStateConfig {
  final String id;
  final String label;
  final String subtitle;
  final String description;
  final String caption;
  final Color accentColor;
  final Color overlayStart;
  final Color overlayEnd;
  final IconData icon;
  final String backgroundAsset;

  const _MonthlyMoodWeatherStateConfig({
    required this.id,
    required this.label,
    required this.subtitle,
    required this.description,
    required this.caption,
    required this.accentColor,
    required this.overlayStart,
    required this.overlayEnd,
    required this.icon,
    required this.backgroundAsset,
  });
}

class _MonthlyMoodWeatherSummary {
  final String stateId;
  final String label;
  final String subtitle;
  final String description;
  final String caption;
  final double score;
  final int sunnyDays;
  final int rainyDays;
  final int recordDays;
  final String volatilityLabel;
  final Color volatilityAccent;
  final Color rainAccent;

  const _MonthlyMoodWeatherSummary({
    required this.stateId,
    required this.label,
    required this.subtitle,
    required this.description,
    required this.caption,
    required this.score,
    required this.sunnyDays,
    required this.rainyDays,
    required this.recordDays,
    required this.volatilityLabel,
    required this.volatilityAccent,
    required this.rainAccent,
  });
}
