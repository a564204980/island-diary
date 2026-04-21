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
import 'package:island_diary/core/models/daily_task.dart';

import 'package:island_diary/features/statistics/domain/utils/soul_season_logic.dart';
import 'package:island_diary/features/statistics/presentation/widgets/bento/recovery_dialog.dart';
import 'package:island_diary/features/statistics/presentation/widgets/mood_poster_widget.dart';
import 'package:island_diary/features/statistics/presentation/widgets/glass_bento.dart';
import 'package:island_diary/features/statistics/presentation/widgets/seasonal_atmosphere_painter.dart';
import 'package:island_diary/features/statistics/presentation/widgets/mental_island_card.dart';
import 'package:island_diary/core/services/ai_service.dart';
part '../widgets/bento/bento_radar_chart.dart';
part '../widgets/bento/bento_mood_calendar.dart';
part '../widgets/bento/bento_emotion_metrics.dart';
part '../widgets/bento/bento_wave_chart.dart';
part '../widgets/bento/bento_weekly_pattern.dart';
part '../widgets/bento/bento_behavioral_analysis.dart';
part '../widgets/bento/bento_heatmap.dart';
part '../widgets/bento/bento_utils.dart';
part '../widgets/statistics_advanced_bento_fragments.dart';
part '../widgets/bento/bento_mood_trend.dart';
part '../widgets/bento/bento_mood_flow.dart';
part '../widgets/bento/bento_resilience.dart';

enum StatTimeRange { week, month, all }

class UnifiedEmotionData {
  final String label;
  final int count;
  final Color color;
  final String? iconPath;
  final int? originalMoodIndex;
  final Color orbColor1 = const Color(0xFFBC8A5F).withValues(alpha: 0.05);

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

  // 新增：波浪图交互状态 (将在下方统一定义)


  // 新增：心境流转图交互状态
  int? _selectedMoodFlowX;

  void _clearAllBentoSelections() {
    _selectedMoodFlowX = null;
    _selectedMoodTrendX = null;
    _touchedWaveSpotIndex = null; // WaveChart mapping
    _selectedWeeklyPatternIndex = null;
    _selectedRadarPointIndex = null;
    _selectedHeatmapCoord = null;
  }

  void updateMoodFlowX(int? x) {
    setState(() {
      if (x != null) {
        final prev = _selectedMoodFlowX;
        _clearAllBentoSelections();
        _selectedMoodFlowX = (prev == x) ? null : x;
      } else {
        _selectedMoodFlowX = null;
      }
    });
  }

  // 新增：各子模块的选择状态
  int? _selectedMoodTrendX;
  int? _touchedWaveSpotIndex; // 新增这一行
  int? _selectedWeeklyPatternIndex;
  int? _selectedRadarPointIndex;

  void updateMoodTrendX(int? x) {
    setState(() {
       if (x != null) {
        final prev = _selectedMoodTrendX;
        _clearAllBentoSelections();
        _selectedMoodTrendX = (prev == x) ? null : x;
      } else {
        _selectedMoodTrendX = null;
      }
    });
  }

  void updateWaveSpotIndex(int? index) {
    setState(() {
      if (index != null) {
        final prev = _touchedWaveSpotIndex;
        _clearAllBentoSelections();
        _touchedWaveSpotIndex = (prev == index) ? null : index;
      } else {
        _touchedWaveSpotIndex = null;
      }
    });
  }

  void updateWeeklyPatternIndex(int? index) {
    setState(() {
      if (index != null) {
        final prev = _selectedWeeklyPatternIndex;
        _clearAllBentoSelections();
        _selectedWeeklyPatternIndex = (prev == index) ? null : index;
      } else {
        _selectedWeeklyPatternIndex = null;
      }
    });
  }

  void updateRadarPointIndex(int? index) {
    setState(() {
      if (index != null) {
        final prev = _selectedRadarPointIndex;
        _clearAllBentoSelections();
        _selectedRadarPointIndex = (prev == index) ? null : index;
      } else {
        _selectedRadarPointIndex = null;
      }
    });
  }

  // 新增：热力图交互状态 (x: hour/day, y: day/month)
  Offset? _selectedHeatmapCoord;

  void updateHeatmapCoord(Offset? coord) {
    setState(() {
      if (coord != null) {
        final prev = _selectedHeatmapCoord;
        _clearAllBentoSelections();
        _selectedHeatmapCoord = (prev == coord) ? null : coord;
      } else {
        _selectedHeatmapCoord = null;
      }
    });
  }

  // 新增：心境流转标签筛选状态
  String? _selectedMoodFlowLabel;

  void updateMoodFlowLabel(String? label) {
    setState(() {
      _selectedMoodFlowLabel = label;
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
    
    // 检查每日任务
    UserState().completeTaskIfType(DailyTaskType.viewStats);

    // 触发自动心灵分析 (静默异步)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _triggerAutoAnalysis();
    });
  }

  Future<void> _triggerAutoAnalysis() async {
    final state = UserState();
    final diaries = _getFilteredDiaries();
    if (diaries.isEmpty) return;

    // 1. 检查今日是否已分析过
    final now = DateTime.now();
    final todayStr = "${now.year}-${now.month}-${now.day}";
    if (state.lastSoulInsightDate == todayStr && state.lastSoulInsight.value != null) {
      debugPrint("SOUL_INSIGHT: 今日已分析，跳过。");
      return;
    }

    debugPrint("SOUL_INSIGHT: 开始执行自动心灵解析...");
    
    // 2. 汇总数据画像
    final moodData = _getUnifiedEmotionData(diaries);
    final String moodDesc = moodData.take(3).map((e) => "${e.label}(${e.count}次)").join('、');
    
    // 提取热门关键词
    final Map<String, int> tagCounts = {};
    for (var d in diaries) {
      if (d.tag != null && d.tag!.isNotEmpty) {
        tagCounts[d.tag!] = (tagCounts[d.tag!] ?? 0) + 1;
      }
    }
    final sortedTags = tagCounts.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
    final String topTags = sortedTags.take(5).map((e) => e.key).join('、');
    
    final currentSeason = SoulSeasonLogic.getSeason(diaries);

    // 3. 调用 AI 解析
    final insight = await AIService().analyzeSoulSeason(
      state.deepseekApiKey.value, 
      seasonName: currentSeason.seasonName, 
      moodDistribution: moodDesc, 
      topTags: topTags.isEmpty ? "暂无关键词" : topTags,
    );

    // 4. 持久化缓存
    if (insight != null && insight.isNotEmpty) {
      await state.saveSoulInsight(insight);
    }
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

  // ============== 模块化排序逻辑 ==============

  List<String> _getModuleOrder() {
    final state = UserState();
    List<String> saved;
    List<String> defaults;

    switch (_currentRange) {
      case StatTimeRange.week:
        saved = state.statsOrderWeek.value;
        defaults = ['island', 'mood_trend', 'mood_flow', 'resilience', 'intensity_radar', 'stats_row', 'volatility', 'wave', 'weekly_pattern', 'heatmap', 'time_pattern'];
        break;
      case StatTimeRange.month:
        saved = state.statsOrderMonth.value;
        defaults = ['island', 'mood_trend', 'mood_flow', 'resilience', 'calendar', 'intensity_radar', 'stats_row', 'highlights', 'time_pattern'];
        break;
      case StatTimeRange.all:
        saved = state.statsOrderAll.value;
        defaults = ['island', 'mood_trend', 'mood_flow', 'resilience', 'intensity_radar', 'seasonality', 'heatmap', 'stats_row', 'time_pattern', 'weather'];
        break;
    }
    
    // 如果保存的列表为空或长度不匹配（可能有新功能加入），使用默认
    if (saved.isEmpty) return defaults;
    
    // 确保保存的列表包含所有必需的模块（去重且补全）
    final Set<String> currentModules = Set.from(saved);
    final List<String> finalOrder = saved.where((m) => defaults.contains(m)).toList();
    for (var d in defaults) {
      if (!currentModules.contains(d)) finalOrder.add(d);
    }
    return finalOrder;
  }

  Widget _buildModuleById(String id, bool isNight, List<DiaryEntry> filtered) {
    // 统一计算当前时节主题色
    final currentSeason = SoulSeasonLogic.getSeason(filtered);
    final themeColor = currentSeason.accentColor;

    switch (id) {
      case 'island':
        if (filtered.isEmpty) return const SizedBox.shrink();
        return MentalIslandCard(
          season: currentSeason,
          isNight: isNight,
          totalEntries: _allDiaries.length,
          rangeText: _currentRange == StatTimeRange.week 
              ? "本周" 
              : (_currentRange == StatTimeRange.month ? "本月" : "目前"),
        );
      case 'intensity_radar':
        return _buildRadarBento(isNight, filtered, themeColor);
      case 'stats_row':
        return IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(flex: 5, child: _buildStatsBentoList(isNight, _currentRange == StatTimeRange.all ? _allDiaries : filtered, themeColor)),
              const SizedBox(width: 16),
              Expanded(flex: 6, child: _buildMoodProgressBarBento(isNight, filtered, themeColor)),
            ],
          ),
        );
      case 'volatility':
        return _buildVolatilityIndexBento(isNight, filtered, themeColor);
      case 'wave':
        return _buildWaveChartBento(isNight, filtered, themeColor);
      case 'weekly_pattern':
        return _buildWeeklyPatternBento(isNight, filtered, themeColor);
      case 'time_pattern':
        return _buildTimePatternBento(isNight, filtered); // 时间模式暂不强制换色，保持其中性
      case 'calendar':
        return _buildMoodCalendarBento(isNight, filtered); // 日历保持多色
      case 'highlights':
        return _buildMonthlyHighlightsBento(isNight, filtered, themeColor);
      case 'seasonality':
        return _buildSeasonalityTrendBento(isNight, _allDiaries, themeColor);
      case 'heatmap':
        return _buildHeatmapBento(isNight, filtered, _currentRange, themeColor);
      case 'weather':
        if (_hasWeatherData(filtered)) {
          return _buildWeatherMoodBento(isNight, filtered);
        }
        return const SizedBox.shrink();
      case 'mood_trend':
        return _buildMoodTrendBento(isNight, filtered, themeColor);
      case 'mood_flow':
        return _buildMoodFlowBento(isNight, filtered, themeColor);
      case 'resilience':
        return _buildResilienceBento(isNight, _currentRange == StatTimeRange.all ? _allDiaries : filtered, themeColor);
      default:
        return const SizedBox.shrink();
    }
  }

  void _onReorder(int oldIndex, int newIndex) {
    setState(() {
      if (newIndex > oldIndex) newIndex -= 1;
      final order = _getModuleOrder();
      final String item = order.removeAt(oldIndex);
      order.insert(newIndex, item);
      
      final rangeStr = _currentRange == StatTimeRange.week ? 'week' 
                     : (_currentRange == StatTimeRange.month ? 'month' : 'all');
      UserState().saveStatsOrder(rangeStr, order);
    });
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


  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<String>(
      valueListenable: UserState().themeMode,
      builder: (context, themeMode, _) {
        final bool isNight = UserState().isNight;
        final filteredDiaries = _getFilteredDiaries();
        
        return Scaffold(
          backgroundColor: Colors.transparent,
          body: Stack(
            children: [
              // 1. 动态治愈背景
              if (filteredDiaries.isNotEmpty)
                SeasonalAtmosphere(
                  particleType: SoulSeasonLogic.getSeason(filteredDiaries).particleType,
                  isNight: isNight,
                ),
              
              SafeArea(
                bottom: false,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildHeader(isNight, filteredDiaries),
                    Expanded(
                      child: filteredDiaries.isEmpty && _currentRange != StatTimeRange.month
                        ? _buildEmptyState(isNight)
                        : Center(
                            child: ConstrainedBox(
                              constraints: const BoxConstraints(maxWidth: 800),
                              child: ReorderableListView.builder(
                                key: ValueKey('$_currentRange'), // 切换维度时重置
                                padding: const EdgeInsets.fromLTRB(20, 10, 20, 120),
                                physics: const BouncingScrollPhysics(),
                                itemCount: _getModuleOrder().length,
                                onReorder: _onReorder,
                                proxyDecorator: (child, index, animation) {
                                  return AnimatedBuilder(
                                    animation: animation,
                                    builder: (context, child) {
                                      final double animValue = Curves.easeInOut.transform(animation.value);
                                      final double scale = lerpDouble(1, 1.02, animValue)!;
                                      return Transform.scale(
                                        scale: scale,
                                        child: Material(
                                          color: Colors.transparent,
                                          elevation: animValue * 8,
                                          shadowColor: Colors.black.withValues(alpha: 0.26),
                                          child: child,
                                        ),
                                      );
                                    },
                                    child: child,
                                  );
                                },
                                itemBuilder: (context, index) {
                                  final order = _getModuleOrder();
                                  final id = order[index];
                                  final module = _buildModuleById(id, isNight, filteredDiaries);
                                  
                                  if (module is SizedBox && module.child == null) {
                                     return SizedBox(key: ValueKey('empty_$id'));
                                  }

                                  return Padding(
                                    key: ValueKey(id),
                                    padding: const EdgeInsets.only(bottom: 16),
                                    child: module,
                                  );
                                },
                              ),
                            ),
                          ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildHeader(bool isNight, List<DiaryEntry> filtered) {
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
                      '心灵气象站',
                      style: TextStyle(
                        color: isNight ? Colors.white : const Color(0xFF5A3E28),
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.0,
                        fontFamily: 'LXGWWenKai',
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '记录情绪起伏，感知心灵季候',
                      style: TextStyle(
                        color: isNight ? Colors.white38 : Colors.black38,
                        fontSize: 12,
                        fontFamily: 'LXGWWenKai',
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
                  Row(
                    children: [
                      GestureDetector(
                        onTap: () async {
                           final rangeStr = _currentRange == StatTimeRange.week ? 'week' 
                                          : (_currentRange == StatTimeRange.month ? 'month' : 'all');
                           await UserState().resetStatsOrder(rangeStr);
                           setState(() {});
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: isNight ? Colors.white24 : Colors.black.withValues(alpha: 0.05),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Row(
                            children: [
                              Icon(CupertinoIcons.refresh, size: 14, color: isNight ? Colors.white70 : Colors.black54),
                              const SizedBox(width: 4),
                              Text('重置布局', style: TextStyle(fontSize: 11, color: isNight ? Colors.white70 : Colors.black54)),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      GestureDetector(
                        onTap: () => _showPosterPreview(context, isNight),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: isNight ? Colors.white24 : Colors.black.withValues(alpha: 0.05),
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
                      ),
                    ],
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
            BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 4, offset: const Offset(0,2))
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
