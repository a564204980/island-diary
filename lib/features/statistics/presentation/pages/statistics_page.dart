import 'dart:ui';
import 'dart:math';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';
import 'package:island_diary/core/state/user_state.dart';
import 'package:island_diary/features/record/domain/models/diary_entry.dart';
import 'package:island_diary/shared/widgets/mood_picker/config/mood_config.dart';

enum StatTimeRange { week, month, all }

class StatisticsPage extends StatefulWidget {
  final bool isActive;

  const StatisticsPage({super.key, this.isActive = true});

  @override
  State<StatisticsPage> createState() => _StatisticsPageState();
}

class _StatisticsPageState extends State<StatisticsPage> with TickerProviderStateMixin {
  List<DiaryEntry> _allDiaries = [];
  StatTimeRange _currentRange = StatTimeRange.month;
  late AnimationController _waveAnimController;
  Key _animKey = UniqueKey();

  @override
  void initState() {
    super.initState();
    _allDiaries = UserState().savedDiaries.value;
    UserState().savedDiaries.addListener(_updateDiaries);
    _waveAnimController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1500))..forward();
  }

  @override
  void dispose() {
    UserState().savedDiaries.removeListener(_updateDiaries);
    _waveAnimController.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant StatisticsPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!oldWidget.isActive && widget.isActive) {
      _waveAnimController.forward(from: 0);
      setState(() {
        _animKey = UniqueKey();
      });
    }
  }

  void _updateDiaries() {
    if (mounted) {
      setState(() {
        _allDiaries = UserState().savedDiaries.value;
      });
    }
  }

  List<DiaryEntry> _getFilteredDiaries() {
    final now = DateTime.now();
    switch (_currentRange) {
      case StatTimeRange.week:
        // 取最近7天内
        return _allDiaries.where((e) => now.difference(e.dateTime).inDays < 7 && e.dateTime.isBefore(now.add(const Duration(days: 1)))).toList();
      case StatTimeRange.month:
        // 当月
        return _allDiaries.where((e) => e.dateTime.year == now.year && e.dateTime.month == now.month).toList();
      case StatTimeRange.all:
        return _allDiaries;
    }
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<String>(
      valueListenable: UserState().themeMode,
      builder: (context, themeMode, _) {
        final bool isNight = UserState().isNight;
        final filteredDiaries = _getFilteredDiaries();
        
        return Scaffold(
          backgroundColor: Colors.transparent,
          body: SafeArea(
            bottom: false,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(isNight, filteredDiaries),
                Expanded(
                  child: filteredDiaries.isEmpty && _currentRange != StatTimeRange.month
                    ? _buildEmptyState(isNight)
                    : ListView(
                        key: _animKey,
                        padding: const EdgeInsets.fromLTRB(20, 10, 20, 120),
                        physics: const BouncingScrollPhysics(),
                        children: [
                          if (_currentRange == StatTimeRange.month)
                            _buildMoodCalendarBento(isNight, _allDiaries),
                          if (_currentRange == StatTimeRange.month)
                            const SizedBox(height: 16),
                          IntrinsicHeight(
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Expanded(flex: 5, child: _buildStatsBentoList(isNight, _allDiaries)),
                                const SizedBox(width: 16),
                                Expanded(flex: 6, child: _buildMoodProgressBarBento(isNight, filteredDiaries)),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),
                          _buildWeeklyPatternBento(isNight, filteredDiaries),
                          const SizedBox(height: 16),
                          _buildWaveChartBento(isNight, filteredDiaries),
                          const SizedBox(height: 16),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(flex: 1, child: _buildTagsBento(isNight, filteredDiaries)),
                            ],
                          ),
                          const SizedBox(height: 16),
                          _buildTimeOfDayBento(isNight, filteredDiaries),
                        ].animate(interval: 80.ms).fadeIn(duration: 500.ms, curve: Curves.easeOut).slideY(begin: 0.1, end: 0, curve: Curves.easeOutQuart),
                      ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeader(bool isNight, List<DiaryEntry> filtered) {
    String greeting = "静静地记录，也是一种力量";
    if (filtered.isNotEmpty) {
      // 找出最多的情绪
      Map<int, int> counts = {};
      for (var e in filtered) {
         counts[e.moodIndex] = (counts[e.moodIndex] ?? 0) + 1;
      }
      var sorted = counts.entries.toList()..sort((a,b)=>b.value.compareTo(a.value));
      var topMood = kMoods[sorted.first.key % kMoods.length];
      greeting = "主导情绪是[${topMood.label}]，继续感受每一天。";
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '数据洞察',
                      style: TextStyle(
                        color: isNight ? Colors.white : const Color(0xFF5A3E28),
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.0,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      greeting,
                      style: TextStyle(
                        color: isNight ? Colors.white70 : Colors.black54,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  _buildSegmentControl(isNight),
                  const SizedBox(height: 12),
                  GestureDetector(
                    onTap: () => _showPosterPreview(context, isNight),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: isNight ? Colors.white24 : Colors.black.withOpacity(0.05),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Row(
                        children: [
                          Icon(CupertinoIcons.camera_viewfinder, size: 14, color: isNight ? Colors.white70 : Colors.black54),
                          const SizedBox(width: 4),
                          Text('总结海报', style: TextStyle(fontSize: 11, color: isNight ? Colors.white70 : Colors.black54)),
                        ],
                      ),
                    ),
                  )
                ],
              )
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSegmentControl(bool isNight) {
    return Container(
      decoration: BoxDecoration(
        color: isNight ? Colors.black26 : Colors.white54,
        borderRadius: BorderRadius.circular(20),
      ),
      padding: const EdgeInsets.all(4),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildSegmentTab('周', StatTimeRange.week, isNight),
          _buildSegmentTab('月', StatTimeRange.month, isNight),
          _buildSegmentTab('全', StatTimeRange.all, isNight),
        ],
      ),
    );
  }

  Widget _buildSegmentTab(String title, StatTimeRange range, bool isNight) {
    final bool isSelected = _currentRange == range;
    return GestureDetector(
      onTap: () {
        setState(() => _currentRange = range);
        _waveAnimController.forward(from: 0);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected 
              ? (isNight ? Colors.white24 : Colors.white)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
          boxShadow: isSelected && !isNight ? [
            BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 4, offset: const Offset(0,2))
          ] : null,
        ),
        child: Text(
          title,
          style: TextStyle(
            fontSize: 13,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            color: isSelected 
              ? (isNight ? Colors.white : const Color(0xFF5A3E28))
              : (isNight ? Colors.white54 : Colors.black54),
          ),
        ),
      ),
    );
  }

  // ============== BENTO COMPONENTS ==============

  Widget _buildMoodCalendarBento(bool isNight, List<DiaryEntry> allEntries) {
    final now = DateTime.now();
    // 构建本月每一天的数据映射
    Map<int, DiaryEntry> daysMap = {};
    for (var e in allEntries) {
      if (e.dateTime.year == now.year && e.dateTime.month == now.month) {
        // 如果同一天有多篇，保留后写的那篇（也就是最新状态）
        if (!daysMap.containsKey(e.dateTime.day) || daysMap[e.dateTime.day]!.dateTime.isBefore(e.dateTime)) {
            daysMap[e.dateTime.day] = e;
        }
      }
    }

    final int daysInMonth = DateUtils.getDaysInMonth(now.year, now.month);
    final int firstWeekday = DateTime(now.year, now.month, 1).weekday; // 1=Mon, 7=Sun

    return _buildGlassCard(
      isNight: isNight,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('${now.month}月心情墙', style: _bentoTitleStyle(isNight)),
              Icon(CupertinoIcons.calendar, size: 18, color: isNight ? Colors.white54 : Colors.black38),
            ],
          ),
          const SizedBox(height: 12),
          // 星期表头
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: ['一', '二', '三', '四', '五', '六', '日'].map((day) {
              return Text(day, style: TextStyle(fontSize: 12, color: isNight ? Colors.white38 : Colors.black38, fontWeight: FontWeight.bold));
            }).toList(),
          ),
          const SizedBox(height: 8),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 7, 
              childAspectRatio: 1,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
            ),
            itemCount: daysInMonth + firstWeekday - 1,
            itemBuilder: (context, index) {
              if (index < firstWeekday - 1) return const SizedBox.shrink(); // 空白占位
              final day = index - (firstWeekday - 1) + 1;
              final entry = daysMap[day];

              return Container(
                decoration: BoxDecoration(
                  color: isNight ? Colors.white10 : Colors.black.withOpacity(0.04),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: entry != null && !isNight ? [
                     BoxShadow(color: (kMoods[entry.moodIndex % kMoods.length].glowColor ?? Colors.yellow).withOpacity(0.4), blurRadius: 4, offset: const Offset(0, 2))
                  ] : null,
                ),
                child: entry != null 
                    ? Image.asset(kMoods[entry.moodIndex % kMoods.length].iconPath!)
                    : Center(child: Text('$day', style: TextStyle(fontSize: 11, color: isNight ? Colors.white24 : Colors.black26))),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildStatsBentoList(bool isNight, List<DiaryEntry> allEntries) {
    int streak = 0;
    int totalWords = 0;

    if (allEntries.isNotEmpty) {
      for (var d in allEntries) {
        totalWords += d.content.length;
      }
      
      final sortedDates = allEntries.map((e) => DateTime(e.dateTime.year, e.dateTime.month, e.dateTime.day)).toSet().toList();
      sortedDates.sort((a, b) => b.compareTo(a));
      
      final today = DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day);
      DateTime current = sortedDates.first == today ? today : sortedDates.first;
      
      for (int i = 0; i < sortedDates.length; i++) {
        if (sortedDates[i] == current) {
          streak++;
          current = current.subtract(const Duration(days: 1));
        } else {
          break;
        }
      }
    }

    return Column(
      children: [
        Expanded(child: _buildSmallBentoCore(isNight, '🔥 连记', '$streak', '天')),
        const SizedBox(height: 16),
        Expanded(child: _buildSmallBentoCore(isNight, '📝 字数', '${totalWords > 999 ? '${(totalWords/1000).toStringAsFixed(1)}k' : totalWords}', '字')),
      ],
    );
  }

  Widget _buildSmallBentoCore(bool isNight, String title, String value, String unit) {
    return _buildGlassCard(
      isNight: isNight,
      padding: const EdgeInsets.all(16),
      child: SizedBox(
        width: double.infinity,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(title, style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: isNight ? Colors.white70 : Colors.black54)),
            const SizedBox(height: 12),
            Row(
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Text(value, style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: isNight ? Colors.white : const Color(0xFF5A3E28))),
                const SizedBox(width: 4),
                Text(unit, style: TextStyle(fontSize: 12, color: isNight ? Colors.white54 : Colors.black45)),
              ],
            )
          ],
        ),
      ),
    );
  }

  Widget _buildMoodProgressBarBento(bool isNight, List<DiaryEntry> filtered) {
    // 横向堆叠柱状图
    Map<int, int> counts = {};
    for (var entry in filtered) {
      counts[entry.moodIndex] = (counts[entry.moodIndex] ?? 0) + 1;
    }
    
    int total = filtered.length;
    List<Widget> barSegments = [];
    List<Widget> legendItems = [];

    if (total > 0) {
      var sortedCounts = counts.entries.toList()..sort((a,b) => b.value.compareTo(a.value));
      for (int i=0; i < sortedCounts.length; i++) {
        var e = sortedCounts[i];
        final config = kMoods[e.key % kMoods.length];
        final flex = (e.value / total * 100).toInt();
        
        barSegments.add(Expanded(
          flex: flex == 0 ? 1 : flex,
          child: GestureDetector(
            onTap: () => _showMoodDetailSheet(context, e.key, filtered, isNight),
            child: Container(
              height: 24,
              decoration: BoxDecoration(
                color: config.glowColor ?? Colors.yellow,
                borderRadius: BorderRadius.horizontal(
                  left: i == 0 ? const Radius.circular(12) : Radius.zero,
                  right: i == sortedCounts.length - 1 ? const Radius.circular(12) : Radius.zero,
                ),
                border: Border.all(color: isNight ? Colors.black12 : Colors.white54, width: 0.5),
              ),
            ),
          ),
        ));
        
        // Legend
        if (i < 4) { // 最多展示前四个图例
          legendItems.add(Padding(
            padding: const EdgeInsets.only(bottom: 6.0),
            child: Row(
              children: [
                Container(width: 8, height: 8, decoration: BoxDecoration(shape: BoxShape.circle, color: config.glowColor ?? Colors.yellow)),
                const SizedBox(width: 6),
                Text('${config.label} ${(e.value / total * 100).toStringAsFixed(0)}%', style: TextStyle(fontSize: 11, color: isNight ? Colors.white70 : Colors.black87)),
              ],
            ),
          ));
        }
      }
    } else {
      barSegments.add(Container(height: 24, decoration: BoxDecoration(color: isNight ? Colors.white10 : Colors.black12, borderRadius: BorderRadius.circular(12))));
    }

    return _buildGlassCard(
      isNight: isNight,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('情绪成分', style: _bentoTitleStyle(isNight)),
          const SizedBox(height: 16),
          ClipRRect(borderRadius: BorderRadius.circular(12), child: Row(children: barSegments)),
          const SizedBox(height: 16),
          if (legendItems.isNotEmpty)
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: legendItems)
          else 
            Text('暂无数据', style: TextStyle(color: isNight ? Colors.white38 : Colors.black38, fontSize: 12)),
        ],
      )
    );
  }

  Widget _buildWaveChartBento(bool isNight, List<DiaryEntry> filtered) {
    if (filtered.length < 2) {
      return _buildGlassCard(
        isNight: isNight,
        padding: const EdgeInsets.all(16),
        child: const SizedBox(
          height: 160,
          child: Center(child: Text('积累更多日记解锁趋势波浪 🌊', style: TextStyle(fontSize: 13, color: Colors.grey))),
        )
      );
    }

    // 截取适当数量点避免拥挤
    int takeCount = _currentRange == StatTimeRange.week ? 7 : (_currentRange == StatTimeRange.month ? 15 : 20);
    final List<DiaryEntry> subset = filtered.take(takeCount).toList().reversed.toList();
    
    final spots = subset.asMap().entries.map((e) {
      return FlSpot(e.key.toDouble(), e.value.intensity * 10);
    }).toList();

    return _buildGlassCard(
      isNight: isNight,
      padding: const EdgeInsets.only(top: 16, bottom: 2, left: 16, right: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('情绪波动', style: _bentoTitleStyle(isNight)),
              Icon(CupertinoIcons.waveform_path, size: 18, color: isNight ? Colors.white54 : Colors.black38),
            ],
          ),
          const SizedBox(height: 24),
          SizedBox(
            height: 130,
            child: LineChart(
              LineChartData(
                minY: 0,
                maxY: 10,
                lineTouchData: LineTouchData(
                  touchTooltipData: LineTouchTooltipData(
                    getTooltipItems: (touchedSpots) {
                      return touchedSpots.map((spot) {
                        final entry = subset[spot.x.toInt()];
                        final mood = kMoods[entry.moodIndex % kMoods.length];
                        return LineTooltipItem(
                          '${mood.label}\n',
                          const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                          children: [TextSpan(text: '${spot.y.toStringAsFixed(1)} 强度', style: const TextStyle(fontWeight: FontWeight.normal, fontSize: 10))],
                        );
                      }).toList();
                    },
                  ),
                ),
                gridData: FlGridData(show: false),
                titlesData: FlTitlesData(
                  leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 22,
                      getTitlesWidget: (value, meta) {
                         if (value.toInt() >= 0 && value.toInt() < subset.length && value.toInt() % max(1, subset.length ~/ 5) == 0) {
                            final date = subset[value.toInt()].dateTime;
                            return Padding(
                              padding: const EdgeInsets.only(top: 4.0),
                              child: Text(DateFormat('MM/dd').format(date), style: TextStyle(fontSize: 10, color: isNight ? Colors.white54 : Colors.black38)),
                            );
                         }
                         return const Text('');
                      }
                    )
                  )
                ),
                borderData: FlBorderData(show: false),
                lineBarsData: [
                  LineChartBarData(
                    spots: spots,
                    isCurved: true,
                    curveSmoothness: 0.4,
                    color: isNight ? const Color(0xFF80D8FF) : const Color(0xFF64B5F6),
                    barWidth: 3,
                    isStrokeCapRound: true,
                    dotData: FlDotData(
                      show: true,
                      getDotPainter: (spot, percent, barData, index) {
                        final mood = kMoods[subset[index].moodIndex % kMoods.length];
                        return FlDotCirclePainter(radius: 4, color: mood.glowColor ?? Colors.yellow, strokeWidth: 1.5, strokeColor: Colors.white);
                      }
                    ),
                    belowBarData: BarAreaData(
                      show: true,
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          (isNight ? const Color(0xFF80D8FF) : const Color(0xFF64B5F6)).withOpacity(0.4),
                          (isNight ? const Color(0xFF80D8FF) : const Color(0xFF64B5F6)).withOpacity(0.0),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              duration: const Duration(milliseconds: 800),
              curve: Curves.easeOutQuart,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTagsBento(bool isNight, List<DiaryEntry> filtered) {
    Map<String, int> tagCounts = {};
    for (var entry in filtered) {
      if (entry.tag != null && entry.tag!.isNotEmpty) {
        tagCounts[entry.tag!] = (tagCounts[entry.tag!] ?? 0) + 1;
      }
    }

    if (tagCounts.isEmpty) return const SizedBox.shrink();

    final sortedTags = tagCounts.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
    final topTags = sortedTags.take(8).toList();

    return _buildGlassCard(
      isNight: isNight,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('活动气泡', style: _bentoTitleStyle(isNight)),
              Icon(CupertinoIcons.tag, size: 18, color: isNight ? Colors.white54 : Colors.black38),
            ],
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: topTags.map((e) {
              // 随机调整大小模拟气泡，频率高的气泡大一点
              final double scale = 1.0 + min(0.3, e.value * 0.05);
              return Transform.scale(
                scale: scale,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: isNight ? Colors.white.withOpacity(0.12) : const Color(0xFFF0F4F8),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: isNight ? Colors.white24 : Colors.transparent),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(e.key, style: TextStyle(color: isNight ? Colors.white : const Color(0xFF2C3E50), fontSize: 13, fontWeight: FontWeight.bold)),
                      if (e.value > 1) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(shape: BoxShape.circle, color: isNight ? Colors.black38 : Colors.white),
                          child: Text('${e.value}', style: TextStyle(color: isNight ? Colors.white70 : Colors.black54, fontSize: 10, fontWeight: FontWeight.bold)),
                        )
                      ]
                    ],
                  ),
                ),
              );
            }).toList(),
          )
        ],
      ),
    );
  }

  void _showMoodDetailSheet(BuildContext context, int moodIndex, List<DiaryEntry> subset, bool isNight) {
    final config = kMoods[moodIndex % kMoods.length];
    final moodColor = config.glowColor ?? Colors.yellow;
    final entries = subset.where((e) => e.moodIndex == moodIndex).toList();
    entries.sort((a,b) => b.dateTime.compareTo(a.dateTime));

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        return Container(
          height: MediaQuery.of(context).size.height * 0.7,
          decoration: BoxDecoration(
            color: isNight ? const Color(0xFF1E1E1E) : Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            children: [
              const SizedBox(height: 8),
              Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey.withOpacity(0.3), borderRadius: BorderRadius.circular(2))),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(width: 12, height: 12, decoration: BoxDecoration(shape: BoxShape.circle, color: moodColor)),
                  const SizedBox(width: 8),
                  Text('${config.label} (${entries.length}篇)', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: isNight ? Colors.white : Colors.black87)),
                ]
              ),
              const Divider(height: 32),
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  itemCount: entries.length,
                  itemBuilder: (context, index) {
                    final e = entries[index];
                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(color: isNight ? Colors.white10 : Colors.black.withOpacity(0.04), borderRadius: BorderRadius.circular(16)),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(DateFormat('MM月dd日 HH:mm').format(e.dateTime), style: TextStyle(fontSize: 12, color: isNight ? Colors.white54 : Colors.black45)),
                          const SizedBox(height: 8),
                          Text(e.content, style: TextStyle(fontSize: 14, color: isNight ? Colors.white : Colors.black87), maxLines: 3, overflow: TextOverflow.ellipsis),
                        ],
                      )
                    );
                  }
                )
              )
            ]
          )
        );
      }
    );
  }

  Widget _buildTimeOfDayBento(bool isNight, List<DiaryEntry> filtered) {
    if (filtered.isEmpty) return const SizedBox.shrink();

    // 0~6: 深夜, 6~12: 晨间, 12~18: 下午, 18~24: 夜晚
    List<int> counts = [0,0,0,0];
    for (var e in filtered) {
      int h = e.dateTime.hour;
      if (h >= 0 && h < 6) counts[0]++;
      else if (h >= 6 && h < 12) counts[1]++;
      else if (h >= 12 && h < 18) counts[2]++;
      else counts[3]++;
    }

    int maxCount = 0;
    int maxIndex = -1;
    for(int i=0; i<4; i++){
      if(counts[i] > maxCount) {
        maxCount = counts[i];
        maxIndex = i;
      }
    }

    List<Map<String, dynamic>> timeLabels = [
      {'icon': CupertinoIcons.moon_stars_fill, 'label': '深夜', 'color': Color(0xFF9FA8DA)},
      {'icon': CupertinoIcons.sunrise_fill, 'label': '晨间', 'color': Color(0xFFFFCC80)},
      {'icon': CupertinoIcons.sun_max_fill, 'label': '初秋', 'color': Color(0xFFFFAB91)},
      {'icon': CupertinoIcons.moon_fill, 'label': '夜晚', 'color': Color(0xFF5C6BC0)},
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
                           timeLabels[index]['color'].withOpacity(isDominant ? 1.0 : 0.4),
                           timeLabels[index]['color'].withOpacity(isDominant ? 0.6 : 0.1),
                         ]
                       ),
                       borderRadius: BorderRadius.circular(15),
                     ),
                     child: Padding(
                       padding: const EdgeInsets.all(6.0),
                       child: Align(
                         alignment: Alignment.topCenter,
                         child: Icon(timeLabels[index]['icon'], size: 18, color: isNight ? Colors.white : Colors.white),
                       ),
                     ),
                   ),
                   const SizedBox(height: 8),
                   Text(timeLabels[index]['label'], style: TextStyle(fontSize: 11, fontWeight: isDominant ? FontWeight.bold : FontWeight.normal, color: isNight ? Colors.white54 : Colors.black54)),
                   Text('${counts[index]}篇', style: TextStyle(fontSize: 9, color: isNight ? Colors.white38 : Colors.black38)),
                 ],
               );
            }),
          )
        ],
      )
    );
  }

  void _showPosterPreview(BuildContext context, bool isNight) {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: isNight ? const Color(0xFF2C2C2C) : const Color(0xFFFDFBF7),
            borderRadius: BorderRadius.circular(24),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('📷 生成海报', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: isNight ? Colors.white : Colors.black87)),
              const SizedBox(height: 16),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                   border: Border.all(color: isNight ? Colors.white24 : Colors.black12),
                   borderRadius: BorderRadius.circular(16)
                ),
                child: Column(
                  children: [
                    Text(_currentRange == StatTimeRange.month ? '本月总结回忆' : '我的情感洞察', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: isNight ? Colors.white : Colors.black87)),
                    const SizedBox(height: 20),
                    Opacity(opacity: 0.5, child: Icon(CupertinoIcons.camera_viewfinder, size: 60, color: isNight ? Colors.white : Colors.black)),
                    const SizedBox(height: 20),
                    Text('未来，这儿会渲染出一张美美的\n长拼接图海报，可以保存去发朋友圈哦！', textAlign: TextAlign.center, style: TextStyle(fontSize: 12, color: isNight ? Colors.white54 : Colors.black54, height: 1.5)),
                  ]
                )
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFFB347),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                ),
                onPressed: () => Navigator.pop(ctx),
                child: const Text('我知道啦'),
              )
            ],
          )
        )
      )
    );
  }

  Widget _buildWeeklyPatternBento(bool isNight, List<DiaryEntry> filtered) {
    if (filtered.isEmpty) return const SizedBox.shrink();

    // 统计每一天的大数据
    List<double> dayIntensities = List.filled(7, 0.0);
    List<int> dayCounts = List.filled(7, 0);

    for (var entry in filtered) {
      int w = entry.dateTime.weekday - 1; // 0=Mon, 6=Sun
      dayIntensities[w] += entry.intensity;
      dayCounts[w] += 1;
    }

    List<BarChartGroupData> barGroups = [];
    double maxAvg = 0;
    int bestDay = 0;
    for (int i = 0; i < 7; i++) {
      double avg = dayCounts[i] > 0 ? dayIntensities[i] / dayCounts[i] : 0.0;
      if (avg > maxAvg) {
        maxAvg = avg;
        bestDay = i;
      }
      barGroups.add(
        BarChartGroupData(
          x: i,
          barRods: [
            BarChartRodData(
              toY: avg * 10,
              color: isNight ? Colors.white54 : Colors.black26,
              width: 12,
              borderRadius: BorderRadius.circular(4),
              backDrawRodData: BackgroundBarChartRodData(
                show: true,
                toY: 100,
                color: isNight ? Colors.white10 : Colors.black.withOpacity(0.04),
              ),
            ),
          ],
        ),
      );
    }
    
    // 给最高的心情柱子标亮
    if (maxAvg > 0) {
      barGroups[bestDay] = BarChartGroupData(
        x: bestDay,
        barRods: [
          BarChartRodData(
            toY: maxAvg * 10,
            color: isNight ? const Color(0xFFFFD54F) : const Color(0xFFFFCA28),
            width: 12,
            borderRadius: BorderRadius.circular(4),
            backDrawRodData: BackgroundBarChartRodData(
              show: true,
              toY: 100,
              color: isNight ? Colors.white10 : Colors.black.withOpacity(0.04),
            ),
          )
        ]
      );
    }

    final List<String> weekdaysStr = ['周一', '周二', '周三', '周四', '周五', '周六', '周日'];

    return _buildGlassCard(
      isNight: isNight,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('星期规律', style: _bentoTitleStyle(isNight)),
              Icon(CupertinoIcons.chart_bar_alt_fill, size: 18, color: isNight ? Colors.white54 : Colors.black38),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            maxAvg > 0 ? '看起来您在 ${weekdaysStr[bestDay]} 的心情最棒！' : '记录太少，还看不出规律哦',
            style: TextStyle(fontSize: 12, color: isNight ? Colors.white54 : Colors.black54),
          ),
          const SizedBox(height: 24),
          SizedBox(
            height: 100,
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceAround,
                maxY: 100,
                barTouchData: BarTouchData(enabled: false),
                titlesData: FlTitlesData(
                  show: true,
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        return Padding(
                          padding: const EdgeInsets.only(top: 8.0),
                          child: Text(weekdaysStr[value.toInt()].substring(1), style: TextStyle(color: isNight ? Colors.white38 : Colors.black38, fontSize: 10, fontWeight: FontWeight.bold)),
                        );
                      },
                    ),
                  ),
                  leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                ),
                gridData: FlGridData(show: false),
                borderData: FlBorderData(show: false),
                barGroups: barGroups,
              ),
              duration: const Duration(milliseconds: 800),
              curve: Curves.easeOutQuart,
            ),
          ),
        ],
      )
    );
  }

  TextStyle _bentoTitleStyle(bool isNight) {
    return TextStyle(
      fontSize: 14,
      fontWeight: FontWeight.bold,
      color: isNight ? Colors.white : const Color(0xFF5A3E28),
    );
  }

  Widget _buildEmptyState(bool isNight) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            CupertinoIcons.wind,
            size: 60,
            color: isNight ? Colors.white38 : Colors.black26,
          ),
          const SizedBox(height: 16),
          Text(
            '在这段时间里没有记录日记哦',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: isNight ? Colors.white54 : Colors.black54,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGlassCard({required bool isNight, required Widget child, EdgeInsetsGeometry? padding}) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
        child: Container(
          decoration: BoxDecoration(
            color: isNight
                ? Colors.white.withOpacity(0.08)
                : Colors.white.withOpacity(0.65),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: isNight
                  ? Colors.white.withOpacity(0.15)
                  : Colors.white.withOpacity(0.8),
              width: 1.2,
            ),
            boxShadow: [
              BoxShadow(
                color: isNight
                    ? Colors.black.withOpacity(0.2)
                    : const Color(0xFF1B3B5F).withOpacity(0.05),
                blurRadius: 24,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          padding: padding ?? const EdgeInsets.all(20),
          child: child,
        ),
      ),
    );
  }
}
