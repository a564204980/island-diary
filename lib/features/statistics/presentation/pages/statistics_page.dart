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

import 'package:island_diary/features/statistics/presentation/widgets/custom_neon_radar_chart.dart';
import 'package:island_diary/features/statistics/domain/utils/soul_season_logic.dart';
import 'package:island_diary/features/record/presentation/pages/diary_editor_page.dart';
import 'package:island_diary/features/statistics/presentation/widgets/mood_poster_widget.dart';
import 'package:island_diary/features/statistics/presentation/widgets/glass_bento.dart';
part '../widgets/bento/bento_mood_calendar.dart';
part '../widgets/bento/bento_emotion_metrics.dart';
part '../widgets/bento/bento_wave_chart.dart';
part '../widgets/bento/bento_weekly_pattern.dart';
part '../widgets/bento/bento_behavioral_analysis.dart';
part '../widgets/bento/bento_utils.dart';
part '../widgets/statistics_advanced_bento_fragments.dart';

enum StatTimeRange { week, month, all }

class UnifiedEmotionData {
  final String label;
  final int count;
  final Color color;
  final String? iconPath;
  final int? originalMoodIndex;

  UnifiedEmotionData({
    required this.label,
    required this.count,
    required this.color,
    this.iconPath,
    this.originalMoodIndex,
  });
}

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

  // 新增：波浪图交互状态
  int? _touchedWaveSpotIndex;

  void updateWaveSpotIndex(int? index) {
    setState(() {
      _touchedWaveSpotIndex = index;
    });
  }

  List<UnifiedEmotionData> _getUnifiedEmotionData(List<DiaryEntry> entries) {
    if (entries.isEmpty) return [];

    Map<String, int> counts = {};
    Map<String, Color> colorMap = {};
    Map<String, String?> iconMap = {};
    Map<String, int?> moodIdxMap = {};

    for (var entry in entries) {
      // 1. 获取核心标签
      // 优先从 tag 获取（用户自定义心境），如果没有则取内置情绪 label
      String label = entry.tag != null && entry.tag!.isNotEmpty 
          ? entry.tag! 
          : kMoods[entry.moodIndex % kMoods.length].label;

      counts[label] = (counts[label] ?? 0) + 1;

      // 2. 确定视觉属性
      if (!colorMap.containsKey(label)) {
        // 如果是内置情绪，使用其专属色
        bool isStandard = false;
        for (var m in kMoods) {
          if (m.label == label) {
            colorMap[label] = m.glowColor ?? Colors.blue;
            iconMap[label] = m.iconPath;
            moodIdxMap[label] = kMoods.indexOf(m);
            isStandard = true;
            break;
          }
        }

        // 如果是纯自定义标签，分配一个生成的平衡色
        if (!isStandard) {
           // 基于 label 的哈希值生成一个色相，确保同一标签颜色一致
           final h = (label.hashCode % 360).toDouble();
           colorMap[label] = HSVColor.fromAHSV(1.0, h, 0.4, 0.9).toColor();
           iconMap[label] = 'assets/images/icons/custom.png'; // 备选图标
           moodIdxMap[label] = null;
        }
      }
    }

    // 转换为列表并按频次排序
    final sorted = counts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return sorted.map((e) => UnifiedEmotionData(
      label: e.key,
      count: e.value,
      color: colorMap[e.key] ?? Colors.blue,
      iconPath: iconMap[e.key],
      originalMoodIndex: moodIdxMap[e.key],
    )).toList();
  }

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

  // ============== SHARED UI HELPERS FOR BENTO ==============

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
                          if (_currentRange == StatTimeRange.week) ...[
                            _buildEmotionRadarBento(isNight, filteredDiaries),
                            const SizedBox(height: 16),
                            IntrinsicHeight(
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  Expanded(flex: 5, child: _buildStatsBentoList(isNight, filteredDiaries)),
                                  const SizedBox(width: 16),
                                  Expanded(flex: 6, child: _buildMoodProgressBarBento(isNight, filteredDiaries)),
                                ],
                              ),
                            ),
                            const SizedBox(height: 16),
                            _buildVolatilityIndexBento(isNight, filteredDiaries),
                            const SizedBox(height: 16),
                            _buildWaveChartBento(isNight, filteredDiaries),
                            const SizedBox(height: 16),
                            _buildWeeklyPatternBento(isNight, filteredDiaries),
                            const SizedBox(height: 16),
                            _buildTimePatternBento(isNight, filteredDiaries),
                          ]
                          else if (_currentRange == StatTimeRange.month) ...[
                            _buildMoodCalendarBento(isNight, filteredDiaries),
                            const SizedBox(height: 16),
                            IntrinsicHeight(
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  Expanded(flex: 5, child: _buildStatsBentoList(isNight, filteredDiaries)),
                                  const SizedBox(width: 16),
                                  Expanded(flex: 6, child: _buildMoodProgressBarBento(isNight, filteredDiaries)),
                                ],
                              ),
                            ),
                            const SizedBox(height: 16),
                            _buildMonthlyHighlightsBento(isNight, filteredDiaries),
                            const SizedBox(height: 16),
                            _buildTimePatternBento(isNight, filteredDiaries),
                          ]
                          else if (_currentRange == StatTimeRange.all) ...[
                            _buildSoulColorBento(isNight, _allDiaries),
                            const SizedBox(height: 16),

                            _buildSeasonalityTrendBento(isNight, _allDiaries),
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
                            _buildTimePatternBento(isNight, filteredDiaries),
                            const SizedBox(height: 16),
                            if (_hasWeatherData(filteredDiaries)) ...[
                              _buildWeatherMoodBento(isNight, filteredDiaries),
                              const SizedBox(height: 16),
                            ],

                          ]
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
    String seasonNote = "";
    Color seasonColor = isNight ? Colors.white : const Color(0xFF5A3E28);

    if (filtered.isNotEmpty) {
      final season = SoulSeasonLogic.getSeason(filtered);
      String rangeText = _currentRange == StatTimeRange.week 
          ? "本周" 
          : (_currentRange == StatTimeRange.month ? "本月" : "目前");
      greeting = "${rangeText}灵魂处于【${season.seasonName}】${season.icon}";
      seasonNote = season.description;
      seasonColor = season.accentColor;
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
                        color: seasonColor,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'LXGWWenKai',
                      ),
                    ),
                    if (seasonNote.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        seasonNote,
                        style: TextStyle(
                          color: isNight ? Colors.white70 : Colors.black54,
                          fontSize: 13,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ],
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
        setState(() {
          _currentRange = range;
          _touchedWaveSpotIndex = null; // 切换时间维度时重置选中点
        });
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

}
