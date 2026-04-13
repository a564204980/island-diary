part of '../../pages/statistics_page.dart';

extension _BentoBehavioralAnalysis on _StatisticsPageState {

  Widget _buildInsightItem({
    required bool isNight, 
    required String title, 
    required String subtitle, 
    required String label, 
    required IconData icon, 
    required Color color
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: [color.withValues(alpha: 0.8), color.withValues(alpha: 0.4)]),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 18, color: Colors.white),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(title, style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: isNight ? Colors.white : Colors.black87)),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(4), border: Border.all(color: color.withValues(alpha: 0.2))),
                      child: Text(label, style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: color)),
                    )
                  ],
                ),
                const SizedBox(height: 4),
                Text(subtitle, style: TextStyle(fontSize: 11, color: isNight ? Colors.white38 : Colors.black45, height: 1.4)),
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _buildFallbackImpactBento(bool isNight, Map<String, List<DiaryEntry>> tagGroups) {
    // 降级显示最基础的情绪关联
    List<Map<String, dynamic>> tagStats = [];
    tagGroups.forEach((tag, entries) {
       double avg = entries.fold(0.0, (sum, e) => sum+e.intensity) / entries.length;
       tagStats.add({'tag': tag, 'avg': avg});
    });
    tagStats.sort((a,b) => (b['avg'] as double).compareTo(a['avg'] as double));
    final best = tagStats.first;

    return _buildGlassCard(
      isNight: isNight,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('共鸣频率', style: _bentoTitleStyle(isNight)),
          const SizedBox(height: 12),
          Text('揭示特定活动下的情绪共振：', style: TextStyle(fontSize: 11, color: isNight?Colors.white38:Colors.black45)),
          const SizedBox(height: 8),
          _buildImpactRow(isNight: isNight, title: '情绪上扬器', tag: best['tag'], score: best['avg'], isPositive: true),
        ],
      ),
    );
  }

  Widget _buildImpactRow({required bool isNight, required String title, required String tag, required double score, required bool isPositive}) {
    final color = isPositive ? const Color(0xFFFFB75E) : const Color(0xFF6dd5ed);
    final icon = isPositive ? CupertinoIcons.arrow_up_right_circle_fill : CupertinoIcons.arrow_down_right_circle_fill;
    
    return Row(
      children: [
        Icon(icon, size: 20, color: color),
        const SizedBox(width: 8),
        Text(title, style: TextStyle(fontSize: 12, color: isNight ? Colors.white70 : Colors.black87)),
        const Spacer(),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(20)),
          child: Text(tag, style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: color)),
        )
      ],
    );
  }

  bool _hasWeatherData(List<DiaryEntry> filtered) {
    return filtered.any((e) => e.weather != null && e.weather!.isNotEmpty && e.weather != '未设置');
  }

  Widget _buildWeatherMoodBento(bool isNight, List<DiaryEntry> filtered) {
    Map<String, List<DiaryEntry>> weatherGroups = {};
    for (var e in filtered) {
      if (e.weather != null && e.weather!.isNotEmpty && e.weather != '未设置') {
        if (!weatherGroups.containsKey(e.weather!)) {
          weatherGroups[e.weather!] = [];
        }
        weatherGroups[e.weather!]!.add(e);
      }
    }

    if (weatherGroups.isEmpty) return const SizedBox.shrink();

    // 选取记录最多的两个天气进行对比
    final sortedWeather = weatherGroups.entries.toList()..sort((a,b) => b.value.length.compareTo(a.value.length));
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
            helpContent: '分析不同天气对您心境的影响，看清[[自然律动]]如何拂过您的心房。',
            isNight: isNight,
            rightAction: Icon(CupertinoIcons.cloud_sun, size: 18, color: isNight ? Colors.white54 : Colors.black38),
          ),
          const SizedBox(height: 12),
          ...displayWeather.map((e) {
             double avg = e.value.fold(0.0, (sum, d) => sum + d.intensity) / e.value.length;
             return Padding(
               padding: const EdgeInsets.only(bottom: 8.0),
               child: Column(
                 crossAxisAlignment: CrossAxisAlignment.start,
                 children: [
                   Row(
                     mainAxisAlignment: MainAxisAlignment.spaceBetween,
                     children: [
                        Text('${e.key}天 (${e.value.length}次)', style: TextStyle(fontSize: 12, color: isNight ? Colors.white70 : Colors.black87)),
                        Text('${(avg*10).toStringAsFixed(0)}分', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: isNight ? Colors.white : const Color(0xFFD4A373))),
                     ],
                   ),
                   const SizedBox(height: 4),
                    Stack(
                      children: [
                        Container(height: 4, width: double.infinity, decoration: BoxDecoration(color: isNight ? Colors.white10 : Colors.black.withValues(alpha: 0.05), borderRadius: BorderRadius.circular(2))),
                        FractionallySizedBox(
                          widthFactor: avg / 10.0,
                          child: Container(height: 4, decoration: BoxDecoration(color: const Color(0xFFD4A373).withValues(alpha: 0.8), borderRadius: BorderRadius.circular(2))),
                        )
                      ],
                    )
                 ],
               ),
             );
          })
        ],
      )
    );
  }

  Widget _buildTimePatternBento(bool isNight, List<DiaryEntry> filtered) {
    if (filtered.isEmpty) {
      return const SizedBox.shrink();
    }

    List<int> counts = List.filled(4, 0); // 凌晨, 上午, 下午, 晚上
    for (var e in filtered) {
      int h = e.dateTime.hour;
      if (h >= 0 && h < 6) {
        counts[0]++;
      } else if (h >= 6 && h < 12) {
        counts[1]++;
      } else if (h >= 12 && h < 18) {
        counts[2]++;
      } else if (h >= 18 && h < 24) {
        counts[3]++;
      }
    }

    int maxCount = counts.reduce(max);
    int maxIndex = counts.indexOf(maxCount);

    final timeLabels = [
      {'label': '凌晨', 'icon': CupertinoIcons.sparkles, 'color': Colors.indigoAccent},
      {'label': '上午', 'icon': CupertinoIcons.sunrise_fill, 'color': Colors.orangeAccent},
      {'label': '下午', 'icon': CupertinoIcons.sun_max_fill, 'color': Colors.orange},
      {'label': '晚上', 'icon': CupertinoIcons.moon_stars_fill, 'color': Colors.blueGrey},
    ];

    return _buildGlassCard(
      isNight: isNight,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildBentoHeader(
            context: context,
            title: '独处时刻',
            helpContent: '分析并捕捉您最倾向于记录日记的时间段，那是您[[灵魂星图]]最为[[璀璨]]、思绪最为流淌的时刻。',
            isNight: isNight,
            rightAction: Icon(CupertinoIcons.star_lefthalf_fill, size: 18, color: isNight ? Colors.white54 : Colors.black38),
          ),
          const SizedBox(height: 12),
          Text(
            maxIndex != -1 ? '于【${timeLabels[maxIndex]['label']}】时分，您的灵魂星图最为璀璨。' : '',
            style: TextStyle(fontSize: 12, color: isNight ? Colors.white70 : Colors.black54, fontFamily: 'LXGWWenKai'),
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: List.generate(4, (index) {
               double heightFactor = maxCount > 0 ? (counts[index] / maxCount) : 0;
               bool isDominant = index == maxIndex;
               Color baseColor = timeLabels[index]['color'] as Color;
               return Column(
                 mainAxisSize: MainAxisSize.min,
                 children: [
                   AnimatedContainer(
                     duration: const Duration(milliseconds: 800),
                     width: 32,
                     height: 32 + (heightFactor * 50),
                     decoration: BoxDecoration(
                       gradient: LinearGradient(
                         begin: Alignment.bottomCenter, end: Alignment.topCenter,
                          colors: [
                            baseColor.withValues(alpha: isDominant ? 0.9 : 0.3),
                            baseColor.withValues(alpha: isDominant ? 0.3 : 0.05),
                          ]
                        ),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: isDominant ? [
                          BoxShadow(color: baseColor.withValues(alpha: 0.4), blurRadius: 12, spreadRadius: 2)
                        ] : null,
                     ),
                     child: Padding(
                       padding: const EdgeInsets.all(6.0),
                       child: Align(
                         alignment: Alignment.topCenter,
                         child: Icon(
                           timeLabels[index]['icon'] as IconData, 
                           size: 18, 
                           color: isDominant ? Colors.white : Colors.white24
                         ),
                       ),
                     ),
                   ).animate(onPlay: (c) => c.repeat(reverse: true)).shimmer(duration: (1500 + index * 200).ms, color: Colors.white12),
                   const SizedBox(height: 10),
                   Text(timeLabels[index]['label'] as String, style: TextStyle(fontSize: 11, fontWeight: isDominant ? FontWeight.bold : FontWeight.normal, color: isNight ? Colors.white54 : Colors.black54)),
                   Text('${counts[index]}次', style: TextStyle(fontSize: 9, color: isNight ? Colors.white38 : Colors.black38)),
                 ],
               );
            }),
          )
        ],
      )
    );
  }
}
