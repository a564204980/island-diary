part of '../../pages/statistics_page.dart';

extension _BentoBehavioralAnalysis on _StatisticsPageState {
  bool _hasWeatherData(List<DiaryEntry> filtered) {
    return filtered.any((e) => e.weather != null && e.weather!.isNotEmpty && e.weather != '未设置');
  }

  Widget _buildWeatherMoodBento(bool isNight, List<DiaryEntry> filtered) {
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
              color: isNight ? Colors.white54 : Colors.black38,
            ),
          ),
          const SizedBox(height: 12),
          ...displayWeather.map((e) {
            final avg = e.value.fold<double>(0.0, (sum, d) => sum + d.intensity) / e.value.length;
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
                          color: isNight ? Colors.white : const Color(0xFFD4A373),
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
                          color: isNight ? Colors.white10 : Colors.black.withValues(alpha: 0.05),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      FractionallySizedBox(
                        widthFactor: avg / 10.0,
                        child: Container(
                          height: 4,
                          decoration: BoxDecoration(
                            color: const Color(0xFFD4A373).withValues(alpha: 0.8),
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
    final bool isCottonCandy = UserState().selectedIslandThemeId.value == 'cotton_candy';

    final timeLabels = [
      {'label': '凌晨', 'icon': CupertinoIcons.sparkles, 'color': const Color(0xFF8E9BFF)},
      {'label': '上午', 'icon': CupertinoIcons.sunrise_fill, 'color': const Color(0xFFFFA24A)},
      {'label': '下午', 'icon': CupertinoIcons.sun_max_fill, 'color': const Color(0xFFFFC36A)},
      {'label': '晚上', 'icon': CupertinoIcons.moon_stars_fill, 'color': const Color(0xFF9FA7B8)},
    ];

    final dominantLabel = maxCount > 0 ? timeLabels[maxIndex]['label'] as String : '暂无';
    final dominantCount = maxCount;
    final dominantRate = filtered.isNotEmpty ? dominantCount / filtered.length : 0.0;
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
              color: isNight ? Colors.white54 : Colors.black38,
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
              final double heightFactor = maxCount > 0 ? (counts[index] / maxCount) : 0;
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
                        padding: const EdgeInsets.only(top: 6, left: 6, right: 6, bottom: 6),
                        child: Align(
                          alignment: Alignment.topCenter,
                          child: Icon(
                            timeLabels[index]['icon'] as IconData,
                            size: 17,
                            color: Colors.white.withValues(alpha: 0.68),
                          ),
                        ),
                      ),
                    ).animate(onPlay: (c) => c.repeat(reverse: true)).shimmer(
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
                                DateFormat('MM/dd HH:mm').format(entry.dateTime),
                                style: TextStyle(
                                  fontSize: 12,
                                  color: isNight ? Colors.white54 : Colors.black45,
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
                            _truncateMemoryText(entry.content.replaceAll('\n', ' '), 80),
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
}
