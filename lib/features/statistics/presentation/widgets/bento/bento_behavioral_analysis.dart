part of '../../pages/statistics_page.dart';

extension BentoBehavioralAnalysis on _StatisticsPageState {
  Widget _buildTagsBento(bool isNight, List<DiaryEntry> filtered) {
    if (filtered.isEmpty) return const SizedBox.shrink();

    // 1. 数据聚合：按标签组织日记
    Map<String, List<DiaryEntry>> tagGroups = {};
    for (var entry in filtered) {
      if (entry.tag != null && entry.tag!.trim().isNotEmpty) {
        final tag = entry.tag!.trim();
        if (!tagGroups.containsKey(tag)) tagGroups[tag] = [];
        tagGroups[tag]!.add(entry);
      }
    }

    if (tagGroups.isEmpty) return const SizedBox.shrink();

    // 2. 多维洞察推演
    List<Widget> insights = [];

    // --- 维度 A: 表达欲/投入深度 (基于日记文本长度) ---
    String? deepEngagementTag;
    double maxAvgLength = 0;
    tagGroups.forEach((tag, entries) {
      double avgLen = entries.fold(0.0, (sum, e) => sum + e.content.length) / entries.length;
      if (avgLen > maxAvgLength && entries.length >= 2) {
        maxAvgLength = avgLen;
        deepEngagementTag = tag;
      }
    });
    if (deepEngagementTag != null) {
      insights.add(_buildInsightItem(
        isNight: isNight,
        title: '深度投入',
        subtitle: '该活动下您的日记平均字数远超其他，它是您的灵魂树洞。',
        label: deepEngagementTag!,
        icon: CupertinoIcons.doc_text_viewfinder,
        color: const Color(0xFF6A11CB),
      ));
    }

    // --- 维度 B: 时间共鸣 (深夜/清晨 偏好) ---
    String? lateNightTag;
    tagGroups.forEach((tag, entries) {
      int lateNightCount = entries.where((e) => e.dateTime.hour >= 22 || e.dateTime.hour <= 4).length;
      if (lateNightCount >= 2 && lateNightCount / entries.length > 0.6) {
        lateNightTag = tag;
      }
    });
    if (lateNightTag != null) {
      insights.add(_buildInsightItem(
        isNight: isNight,
        title: '深夜共鸣',
        subtitle: '这是一项高度绑定“静谧时光”的活动，常在您的深夜出现。',
        label: lateNightTag!,
        icon: CupertinoIcons.moon_stars_fill,
        color: const Color(0xFF2575FC),
      ));
    }

    // --- 维度 C: 环境耦合 (天气亲和度) ---
    String? rainAffinityTag;
    tagGroups.forEach((tag, entries) {
       int rainCount = entries.where((e) => e.weather?.contains('雨') ?? false).length;
       if (rainCount >= 1 && rainCount / entries.length > 0.5) {
         rainAffinityTag = tag;
       }
    });
    if (rainAffinityTag != null) {
      insights.add(_buildInsightItem(
        isNight: isNight,
        title: '雨天耦合',
        subtitle: '您倾向于在阴雨连绵时开启此项活动，它是您的雨中避难所。',
        label: rainAffinityTag!,
        icon: CupertinoIcons.cloud_rain_fill,
        color: const Color(0xFF4FACFE),
      ));
    }

    if (insights.isEmpty) {
       // 如果没有特殊联系，退回到之前的相关性逻辑
       return _buildFallbackImpactBento(isNight, tagGroups);
    }

    return _buildGlassCard(
      isNight: isNight,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('多维洞察', style: _bentoTitleStyle(isNight)),
              Icon(CupertinoIcons.sparkles, size: 18, color: isNight ? Colors.white54 : Colors.amber),
            ],
          ),
          const SizedBox(height: 16),
          ...insights,
        ],
      ),
    );
  }

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
              gradient: LinearGradient(colors: [color.withOpacity(0.8), color.withOpacity(0.4)]),
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
                      decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(4), border: Border.all(color: color.withOpacity(0.2))),
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
          Text('心理相关性', style: _bentoTitleStyle(isNight)),
          const SizedBox(height: 12),
          Text('目前数据量较少，仅为您呈现最强关联活动：', style: TextStyle(fontSize: 11, color: isNight?Colors.white38:Colors.black45)),
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
          decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(20)),
          child: Text(tag, style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: color)),
        )
      ],
    );
  }

  bool _hasWeatherData(List<DiaryEntry> filtered) {
    return filtered.any((e) => e.weather != null && e.weather!.isNotEmpty && e.weather != '未设置');
  }

  bool _hasTagData(List<DiaryEntry> filtered) {
    return filtered.any((e) => e.tag != null && e.tag!.isNotEmpty);
  }

  Widget _buildWeatherMoodBento(bool isNight, List<DiaryEntry> filtered) {
    Map<String, List<DiaryEntry>> weatherGroups = {};
    for (var e in filtered) {
      if (e.weather != null && e.weather!.isNotEmpty && e.weather != '未设置') {
        if (!weatherGroups.containsKey(e.weather!)) weatherGroups[e.weather!] = [];
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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('气候反差', style: _bentoTitleStyle(isNight)),
              Icon(CupertinoIcons.cloud_sun, size: 18, color: isNight ? Colors.white54 : Colors.black38),
            ],
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
                       Container(height: 4, width: double.infinity, decoration: BoxDecoration(color: isNight ? Colors.white10 : Colors.black.withOpacity(0.05), borderRadius: BorderRadius.circular(2))),
                       FractionallySizedBox(
                         widthFactor: avg / 10.0,
                         child: Container(height: 4, decoration: BoxDecoration(color: const Color(0xFFD4A373).withOpacity(0.8), borderRadius: BorderRadius.circular(2))),
                       )
                     ],
                   )
                 ],
               ),
             );
          }).toList()
        ],
      )
    );
  }

  Widget _buildTimePatternBento(bool isNight, List<DiaryEntry> filtered) {
    if (filtered.isEmpty) return const SizedBox.shrink();

    List<int> counts = List.filled(4, 0); // 凌晨, 上午, 下午, 晚上
    for (var e in filtered) {
      int h = e.dateTime.hour;
      if (h >= 0 && h < 6) counts[0]++;
      else if (h >= 6 && h < 12) counts[1]++;
      else if (h >= 12 && h < 18) counts[2]++;
      else if (h >= 18 && h < 24) counts[3]++;
    }

    int maxCount = counts.reduce(max);
    int maxIndex = counts.indexOf(maxCount);

    final timeLabels = [
      {'label': '凌晨', 'icon': CupertinoIcons.moon_stars_fill, 'color': Colors.indigo},
      {'label': '上午', 'icon': CupertinoIcons.sun_min_fill, 'color': Colors.orangeAccent},
      {'label': '下午', 'icon': CupertinoIcons.sun_max_fill, 'color': Colors.orange},
      {'label': '晚上', 'icon': CupertinoIcons.moon_fill, 'color': Colors.blueGrey},
    ];

    return _buildGlassCard(
      isNight: isNight,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('时段出没', style: _bentoTitleStyle(isNight)),
              Icon(CupertinoIcons.clock_fill, size: 18, color: isNight ? Colors.white54 : Colors.black38),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            maxIndex != -1 ? '原来您是一个偏向于在【${timeLabels[maxIndex]['label']}】有强烈情感共鸣的人。' : '',
            style: TextStyle(fontSize: 12, color: isNight ? Colors.white70 : Colors.black54),
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: List.generate(4, (index) {
               double heightFactor = maxCount > 0 ? (counts[index] / maxCount) : 0;
               bool isDominant = index == maxIndex;
               return Column(
                 mainAxisSize: MainAxisSize.min,
                 children: [
                   AnimatedContainer(
                     duration: const Duration(milliseconds: 600),
                     width: 30,
                     height: 30 + (heightFactor * 40),
                     decoration: BoxDecoration(
                       gradient: LinearGradient(
                         begin: Alignment.bottomCenter, end: Alignment.topCenter,
                         colors: [
                           (timeLabels[index]['color'] as Color).withOpacity(isDominant ? 1.0 : 0.4),
                           (timeLabels[index]['color'] as Color).withOpacity(isDominant ? 0.6 : 0.1),
                         ]
                       ),
                       borderRadius: BorderRadius.circular(15),
                     ),
                     child: Padding(
                       padding: const EdgeInsets.all(6.0),
                       child: Align(
                         alignment: Alignment.topCenter,
                         child: Icon(timeLabels[index]['icon'] as IconData, size: 18, color: Colors.white),
                       ),
                     ),
                   ),
                   const SizedBox(height: 8),
                   Text(timeLabels[index]['label'] as String, style: TextStyle(fontSize: 11, fontWeight: isDominant ? FontWeight.bold : FontWeight.normal, color: isNight ? Colors.white54 : Colors.black54)),
                   Text('${counts[index]}篇', style: TextStyle(fontSize: 9, color: isNight ? Colors.white38 : Colors.black38)),
                 ],
               );
            }),
          )
        ],
      )
    );
  }
}
