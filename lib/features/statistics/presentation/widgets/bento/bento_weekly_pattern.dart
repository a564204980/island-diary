part of '../../pages/statistics_page.dart';

extension BentoWeeklyPattern on _StatisticsPageState {
  Widget _buildWeeklyPatternBento(bool isNight, List<DiaryEntry> filtered, Color themeColor) {
    if (filtered.isEmpty) return const SizedBox.shrink();

    // 统计每一天的大数据
    List<double> dayIntensities = List.filled(7, 0.0);
    List<int> dayCounts = List.filled(7, 0);

    for (var entry in filtered) {
      int w = entry.dateTime.weekday - 1; // 0=Mon, 6=Sun
      dayIntensities[w] += entry.intensity;
      dayCounts[w]++;
    }

    List<double> averages = List.generate(7, (i) => dayCounts[i] > 0 ? (dayIntensities[i] / dayCounts[i]) : 0);
    double maxAvg = averages.reduce(max);

    return _buildGlassCard(
      isNight: isNight,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildBentoHeader(
            context: context,
            title: '岛屿脉动',
            helpContent: '分析您在一周内的[[时间分配]]与[[心情走势]]，揭秘工作日与休息日之间的[[切换规律]]。',
            isNight: isNight,
            rightAction: Text('揭示一周心情', style: TextStyle(fontSize: 10, color: isNight ? Colors.white38 : Colors.black38)),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 120, // 固定高度容器支撑动画和排版
            child: LayoutBuilder(
              builder: (context, constraints) {
                return Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: List.generate(7, (index) {
                        final days = ['一', '二', '三', '四', '五', '六', '日'];
                        double h = maxAvg > 0 ? (averages[index] / maxAvg) * 46 : 0;
                        bool isToday = (DateTime.now().weekday - 1) == index;

                        return GestureDetector(
                          onTap: () => updateWeeklyPatternIndex(index),
                          behavior: HitTestBehavior.opaque,
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              // 数值悬浮展示 (延迟淡入)
                              if (dayCounts[index] > 0)
                                Padding(
                                  padding: const EdgeInsets.only(bottom: 4.0),
                                  child: Text(
                                    averages[index].toStringAsFixed(1),
                                    style: TextStyle(
                                      fontSize: 9,
                                      fontWeight: FontWeight.w900,
                                      color: isNight ? Colors.white70 : const Color(0xFF6C7A89),
                                    ),
                                  ).animate().fadeIn(delay: (300 + index * 50).ms),
                                ),
                              if (dayCounts[index] == 0) 
                                const SizedBox(height: 16), // 占位保持对齐

                              // 主柱形
                              Container(
                                width: 18,
                                height: dayCounts[index] > 0 ? 12 + h : 6, // 空数据展示小矮柱
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(9),
                                  gradient: dayCounts[index] > 0 
                                    ? LinearGradient(
                                        begin: Alignment.bottomCenter,
                                        end: Alignment.topCenter,
                                        colors: [
                                          themeColor.withOpacity(0.6),
                                          themeColor,
                                        ]
                                      )
                                    : null,
                                  color: dayCounts[index] == 0 
                                    ? (isNight ? Colors.white10 : Colors.black.withOpacity(0.04))
                                    : null,
                                  boxShadow: dayCounts[index] > 0 
                                    ? [
                                        BoxShadow(
                                          color: themeColor.withOpacity(0.4),
                                          blurRadius: 8,
                                          spreadRadius: -2,
                                          offset: const Offset(0, 4)
                                        )
                                      ] 
                                    : null
                                ),
                              ).animate().scaleY(
                                begin: 0, end: 1, 
                                duration: 700.ms, 
                                curve: Curves.easeOutBack, 
                                alignment: Alignment.bottomCenter,
                                delay: (index * 80).ms
                              ),
                              
                              const SizedBox(height: 10),
                              
                              // 底部星期标识
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: isToday ? (isNight ? Colors.white24 : Colors.black12) : Colors.transparent,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  days[index], 
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: isToday ? FontWeight.bold : FontWeight.normal,
                                    color: isToday 
                                      ? (isNight ? Colors.white : Colors.black87)
                                      : (isNight ? Colors.white38 : Colors.black38)
                                  )
                                ),
                              ),
                            ],
                          ),
                        );
                      }),
                    ),
                    if (_selectedWeeklyPatternIndex != null)
                      _buildBentoTooltip(
                        title: '星期${['一', '二', '三', '四', '五', '六', '日'][_selectedWeeklyPatternIndex!]} · 统计',
                        items: [
                          _BentoTooltipItem(
                            label: '平均强度',
                            value: dayCounts[_selectedWeeklyPatternIndex!] > 0 ? averages[_selectedWeeklyPatternIndex!].toStringAsFixed(1) : '无记录',
                            color: dayCounts[_selectedWeeklyPatternIndex!] > 0 ? themeColor : null,
                          ),
                          _BentoTooltipItem(
                            label: '记录篇数',
                            value: '${dayCounts[_selectedWeeklyPatternIndex!]}篇',
                          ),
                        ],
                        relativeX: (_selectedWeeklyPatternIndex! + 0.5) / 7,
                        chartWidth: constraints.maxWidth,
                        isNight: isNight,
                        top: -20, // 稍微上移一点，避免挡住柱子
                      ),
                  ],
                );
              }
            ),
          ),
        ],
      ),
    );
  }
}
