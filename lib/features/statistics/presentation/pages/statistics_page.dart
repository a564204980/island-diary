import 'dart:ui';
import 'dart:math';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart' hide TextDirection;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:island_diary/core/state/user_state.dart';
import 'package:island_diary/features/record/domain/models/diary_entry.dart';
import 'package:island_diary/shared/widgets/mood_picker/config/mood_config.dart';
import 'package:island_diary/core/models/daily_task.dart';
import 'package:island_diary/shared/widgets/diary_entry/utils/diary_utils.dart';

import 'package:island_diary/features/statistics/domain/utils/soul_season_logic.dart';
import 'package:island_diary/features/statistics/presentation/pages/memories_today_page.dart';
import 'package:island_diary/features/statistics/presentation/widgets/bento/recovery_dialog.dart';
import 'package:island_diary/features/statistics/presentation/widgets/mood_poster_widget.dart';
import 'package:island_diary/features/statistics/presentation/widgets/glass_bento.dart';

import 'package:island_diary/shared/widgets/multi_value_listenable_builder.dart';
import 'package:island_diary/core/services/ai_service.dart';
import 'package:island_diary/features/record/presentation/pages/diary_detail_page.dart';
import 'package:island_diary/shared/widgets/diary_entry/components/diary_bottom_sheet.dart';
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
part '../widgets/bento/bento_memories_today.dart';
part '../widgets/bento/bento_mood_palette.dart';
part '../widgets/bento/bento_time_carving.dart';

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
  bool _isScrolling = false;
  StatTimeRange _currentRange = StatTimeRange.month;
  late AnimationController _waveAnimController;
  late AnimationController _timeCarvingAnimController;
  final Map<String, String> _moodTrendSummaries = {};
  String? _selectedMoodWeatherStateId;

  // 新增：波浪图交互状态 (将在下方统一定义)


  // 新增：心境流转图交互状态
  int? _selectedMoodFlowX;
  int? _selectedPaletteDay; // 新增：时光调色盘选中日期
  DiaryEntry? _selectedTimeCarvingEntry; // 新增：时光风铃选中的日记记录
  String? _hoveredEmotionLabel; // 新增：当前被长按/悬浮的标签情绪名称
  int? _hoveredTimeIndex; // 新增：当前被长按/悬浮的独处时刻时间段索引

  void _clearAllBentoSelections() {
    _hoveredTimeIndex = null;
    _hoveredEmotionLabel = null;
    _selectedMoodFlowX = null;
    _selectedMoodTrendX = null;
    _touchedWaveSpotIndex = null; // WaveChart mapping
    _selectedWeeklyPatternIndex = null;
    _selectedRadarPointIndex = null;
    _selectedHeatmapCoord = null;
    _selectedMoodWeatherStateId = null;
    _selectedPaletteDay = null;
    _selectedTimeCarvingEntry = null;
  }

  void updateState(VoidCallback fn) {
    if (mounted) {
      setState(fn);
    }
  }

  void updateTimeCarvingEntry(DiaryEntry? entry) {
    setState(() {
      if (entry != null) {
        final prev = _selectedTimeCarvingEntry;
        _clearAllBentoSelections();
        _selectedTimeCarvingEntry = (prev == entry) ? null : entry;
      } else {
        _selectedTimeCarvingEntry = null;
      }
    });
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

  void updatePaletteDay(int? day) {
    setState(() {
      if (day != null) {
        final prev = _selectedPaletteDay;
        _clearAllBentoSelections();
        _selectedPaletteDay = (prev == day) ? null : day;
      } else {
        _selectedPaletteDay = null;
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
      final parsed = ParsedTags.parse(entry.tag, entry.moodIndex);
      final String label = parsed.customMood ?? kMoods[entry.moodIndex % kMoods.length].label;

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
           iconMap[label] = entry.moodIndex >= 0 && entry.moodIndex <= 23
               ? 'assets/icons/custom${entry.moodIndex + 1}.png'
               : 'assets/images/icons/custom.png'; // 备选图标
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
    _timeCarvingAnimController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1400))..forward();
    
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
    _timeCarvingAnimController.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant StatisticsPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!oldWidget.isActive && widget.isActive) {
      _waveAnimController.forward(from: 0);
      _timeCarvingAnimController.forward(from: 0);
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
      color: isNight ? Colors.white : const Color(0xFF332F2D),
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
        defaults = ['mood_trend', 'mood_flow', 'intensity_radar', 'stats_row', 'max_streaks', 'mood_progress', 'volatility', 'wave', 'weekly_pattern', 'heatmap', 'time_carving', 'time_pattern'];
        break;
      case StatTimeRange.month:
        saved = state.statsOrderMonth.value;
        defaults = ['mood_trend', 'mood_weather', 'mood_palette', 'mood_flow', 'calendar', 'intensity_radar', 'stats_row', 'max_streaks', 'mood_progress', 'highlights', 'time_carving', 'time_pattern'];
        break;
      case StatTimeRange.all:
        saved = state.statsOrderAll.value;
        defaults = ['mood_trend', 'mood_flow', 'intensity_radar', 'seasonality', 'memories_today', 'heatmap', 'stats_row', 'max_streaks', 'mood_progress', 'time_carving', 'time_pattern', 'weather'];
        break;
    }
    
    List<String> ordered;
    if (saved.isEmpty) {
      ordered = List<String>.from(defaults);
    } else {
      final Set<String> currentModules = Set.from(saved);
      final List<String> finalOrder = saved.where((m) => defaults.contains(m)).toList();
      for (var d in defaults) {
        if (!currentModules.contains(d)) finalOrder.add(d);
      }
      ordered = finalOrder;
    }

    final hidden = state.statsHiddenModules.value;
    return ordered.where((m) => !hidden.contains(m)).toList();
  }

  Widget _buildModuleById(String id, bool isNight, List<DiaryEntry> filtered) {
    // 统一计算当前时节主题色
    final currentSeason = SoulSeasonLogic.getSeason(filtered);
    final themeColor = currentSeason.accentColor;

    switch (id) {
      case 'intensity_radar':
        return _buildRadarBento(isNight, filtered, themeColor);
      case 'stats_row':
        return _buildStatsBentoList(
          isNight,
          _currentRange == StatTimeRange.all ? _allDiaries : filtered,
          themeColor,
        );
      case 'max_streaks':
        return _buildMaxStreaksBento(
          isNight,
          _allDiaries,
          themeColor,
        );
      case 'mood_progress':
        return _buildMoodProgressBarBento(isNight, filtered, themeColor);
      case 'volatility':
        return _buildVolatilityIndexBento(isNight, filtered, themeColor);
      case 'wave':
        return _buildWaveChartBento(isNight, filtered, themeColor);
      case 'weekly_pattern':
        return _buildWeeklyPatternBento(isNight, filtered, themeColor);
      case 'time_pattern':
        return _buildTimePatternBento(isNight, filtered, themeColor);
      case 'time_carving':
        return _buildTimeCarvingBento(isNight, filtered, themeColor);
      case 'calendar':
        return _buildMoodCalendarBento(isNight, filtered); // 日历保持多色
      case 'highlights':
        return _buildMonthlyHighlightsBento(isNight, filtered, themeColor);
      case 'seasonality':
        return _buildSeasonalityTrendBento(isNight, _allDiaries, themeColor);
      case 'memories_today':
        return _buildMemoriesTodayBento(isNight, _allDiaries, themeColor);
      case 'heatmap':
        return _buildHeatmapBento(isNight, filtered, _currentRange, themeColor);
      case 'weather':
        if (_hasWeatherData(filtered)) {
          return _buildWeatherMoodBento(isNight, filtered);
        }
        return const SizedBox.shrink();
      case 'mood_weather':
        return _buildMonthlyMoodWeatherBento(isNight, filtered, themeColor);
      case 'mood_trend':
        return _buildMoodTrendBento(isNight, filtered, themeColor);
      case 'mood_flow':
        return _buildMoodFlowBento(isNight, filtered, themeColor);
      case 'mood_palette':
        return _buildMoodPaletteBento(isNight, filtered);
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
    return MultiValueListenableBuilder(
      listenables: [
        UserState().themeMode,
        UserState().selectedIslandThemeId,
      ],
      builder: (context, values, _) {
        final bool isNight = UserState().isNight;
        final String themeId = values[1] as String;
        final filteredDiaries = _getFilteredDiaries();
        
        return Scaffold(
          backgroundColor: Colors.transparent,
          body: Stack(
            children: [
              // 0. 节日特定背景/主题特定背景
              if (themeId == 'cotton_candy' || themeId == 'lego')
                Positioned.fill(
                  child: Image.asset(
                    themeId == 'lego'
                        ? 'assets/images/theme/legao/legao_data_bg.png'
                        : (isNight
                            ? 'assets/images/theme/miamhuadao/mianhuadao_home_night_bg.png'
                            : 'assets/images/theme/miamhuadao/mianhaudao_home_bg.png'),
                    fit: BoxFit.cover,
                  ),
                ),

              SafeArea(
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 30.0), // 整体底高度向上提缩 30，精致贴合，避免缝隙漏出或底部留白过大
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
                                child: NotificationListener<ScrollNotification>(
                                  onNotification: (ScrollNotification notification) {
                                    if (notification is ScrollStartNotification) {
                                      if (!_isScrolling) {
                                        setState(() {
                                          _isScrolling = true;
                                        });
                                      }
                                    } else if (notification is ScrollEndNotification) {
                                      if (_isScrolling) {
                                        setState(() {
                                          _isScrolling = false;
                                        });
                                      }
                                    }
                                    return false;
                                  },
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
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildHeader(bool isNight, List<DiaryEntry> filtered) {
    final String themeId = UserState().selectedIslandThemeId.value;
    final bool isLego = themeId == 'lego';
    final String headerFont = isLego ? 'SweiFistLeg' : 'LXGWWenKai';

    return Padding(
      padding: const EdgeInsets.only(left: 24.0, right: 24.0, top: 24.0, bottom: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                '心灵气象站',
                style: TextStyle(
                  color: isNight ? Colors.white : const Color(0xFF332F2D),
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.0,
                  fontFamily: headerFont,
                ),
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildSegmentControl(isNight),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: () => _showManageBottomSheet(context, isNight),
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: themeId == 'cotton_candy'
                            ? Colors.white.withValues(alpha: 0.7)
                            : (isNight ? Colors.white24 : Colors.black.withValues(alpha: 0.05)),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        CupertinoIcons.ellipsis_circle,
                        size: 20,
                        color: isNight ? Colors.white70 : Colors.black54,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            '记录情绪起伏，感知心灵季候',
            style: TextStyle(
              color: isNight ? Colors.white38 : Colors.black38,
              fontSize: 12,
              fontFamily: headerFont,
            ),
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
    final bool isCottonCandy = UserState().selectedIslandThemeId.value == 'cotton_candy';

    Color getBackgroundColor() {
      if (!isSelected) return Colors.transparent;
      if (isCottonCandy) return const Color(0xFFFCAEAE);
      return isNight ? Colors.white24 : Colors.white;
    }

    Color getTextColor() {
      if (isSelected) {
        if (isCottonCandy) return Colors.white;
        return isNight ? Colors.white : const Color(0xFF332F2D);
      } else {
        if (isCottonCandy) return const Color(0xFF9E7777);
        return isNight ? Colors.white54 : Colors.black54;
      }
    }

    return GestureDetector(
      onTap: () {
        setState(() {
          _currentRange = range;
          _touchedWaveSpotIndex = null; // 切换时间维度时重置选中点
          _selectedMoodWeatherStateId = null;
        });
        _waveAnimController.forward(from: 0);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        decoration: BoxDecoration(
          color: getBackgroundColor(),
          borderRadius: BorderRadius.circular(16),
          boxShadow: (isSelected && !isNight && !isCottonCandy) ? [
            BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 4, offset: const Offset(0,2))
          ] : null,
        ),
        child: AnimatedDefaultTextStyle(
          duration: const Duration(milliseconds: 200),
          style: TextStyle(
            fontSize: 13,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            color: getTextColor(),
          ),
          child: Text(title),
        ),
      ),
    );
  }

  static const Map<String, String> _moduleNames = {
    'mood_trend': '心境起伏趋势',
    'mood_weather': '当月心情气象',
    'mood_palette': '时光调色盘',
    'mood_flow': '情绪流转分析',
    'calendar': '情绪日历',
    'intensity_radar': '情绪雷达图',
    'stats_row': '核心数值统计',
    'max_streaks': '记录坚持天数',
    'mood_progress': '心情分布比例',
    'volatility': '情感波动指数',
    'wave': '情绪起伏波浪图',
    'weekly_pattern': '周度记录规律',
    'time_pattern': '全天记录热力',
    'time_carving': '时光风铃',
    'highlights': '月度高光时刻',
    'seasonality': '灵魂季候分析',
    'memories_today': '那年今日回顾',
    'heatmap': '年度记录频率',
    'weather': '天气心情分布',
  };

  void _showCustomizeModulesSheet(BuildContext context, bool isNight) {
    final state = UserState();
    final themeId = state.selectedIslandThemeId.value;
    final paperStyle = state.preferredPaperStyle.value;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            List<String> defaults;
            switch (_currentRange) {
              case StatTimeRange.week:
                defaults = ['mood_trend', 'mood_flow', 'intensity_radar', 'stats_row', 'max_streaks', 'mood_progress', 'volatility', 'wave', 'weekly_pattern', 'heatmap', 'time_carving', 'time_pattern'];
                break;
              case StatTimeRange.month:
                defaults = ['mood_trend', 'mood_weather', 'mood_palette', 'mood_flow', 'calendar', 'intensity_radar', 'stats_row', 'max_streaks', 'mood_progress', 'highlights', 'time_carving', 'time_pattern'];
                break;
              case StatTimeRange.all:
                defaults = ['mood_trend', 'mood_flow', 'intensity_radar', 'seasonality', 'memories_today', 'heatmap', 'stats_row', 'max_streaks', 'mood_progress', 'time_carving', 'time_pattern', 'weather'];
                break;
            }

            final hidden = state.statsHiddenModules.value;

            return DiaryBottomSheet(
              isDiary: false,
              paperStyle: paperStyle,
              showDragHandle: true,
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(context).size.height * 0.7,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      '定制数据分析模块',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: isNight ? Colors.white : const Color(0xFF1F2937),
                        fontFamily: 'LXGWWenKai',
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '勾选展示您关注的模块，取消勾选隐藏，长按主页面模块可上下拖动排序',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 11,
                        color: isNight ? Colors.white38 : Colors.black45,
                        fontFamily: 'LXGWWenKai',
                      ),
                    ),
                    const SizedBox(height: 16),
                    Flexible(
                      child: ListView.builder(
                        shrinkWrap: true,
                        itemCount: defaults.length,
                        itemBuilder: (context, index) {
                          final id = defaults[index];
                          final name = _moduleNames[id] ?? id;
                          final isVisible = !hidden.contains(id);

                          return Container(
                            margin: const EdgeInsets.only(bottom: 8),
                            decoration: BoxDecoration(
                              color: isNight
                                  ? Colors.white.withValues(alpha: 0.03)
                                  : Colors.black.withValues(alpha: 0.02),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: CheckboxListTile(
                              title: Text(
                                name,
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                  color: isNight ? Colors.white.withValues(alpha: 0.9) : const Color(0xFF1F2937),
                                  fontFamily: 'LXGWWenKai',
                                ),
                              ),
                              value: isVisible,
                              activeColor: themeId == 'cotton_candy' 
                                  ? const Color(0xFF7C3AED) 
                                  : Theme.of(context).primaryColor,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(6),
                              ),
                              onChanged: (bool? val) async {
                                if (val != null) {
                                  final newHidden = List<String>.from(state.statsHiddenModules.value);
                                  if (val) {
                                    newHidden.remove(id);
                                  } else {
                                    if (!newHidden.contains(id)) {
                                      newHidden.add(id);
                                    }
                                  }
                                  await state.saveStatsHiddenModules(newHidden);
                                  setModalState(() {});
                                  setState(() {});
                                }
                              },
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _showManageBottomSheet(BuildContext context, bool isNight) {
    final state = UserState();
    final paperStyle = state.preferredPaperStyle.value;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return DiaryBottomSheet(
          isDiary: false,
          paperStyle: paperStyle,
          showDragHandle: true,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                '面板管理',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: isNight ? Colors.white : const Color(0xFF1F2937),
                  fontFamily: 'LXGWWenKai',
                ),
              ),
              const SizedBox(height: 16),
              
              _buildManageOption(
                icon: CupertinoIcons.slider_horizontal_3,
                title: '定制展示模块',
                subtitle: '开启/隐藏您关心的分析图表',
                isNight: isNight,
                onTap: () {
                  Navigator.pop(context);
                  _showCustomizeModulesSheet(context, isNight);
                },
              ),
              Divider(height: 1, color: isNight ? Colors.white10 : Colors.black12, indent: 56),
              
              _buildManageOption(
                icon: CupertinoIcons.refresh,
                title: '重置组件布局',
                subtitle: '恢复默认的卡片显示排序',
                isNight: isNight,
                onTap: () async {
                  Navigator.pop(context);
                  final rangeStr = _currentRange == StatTimeRange.week ? 'week' 
                                 : (_currentRange == StatTimeRange.month ? 'month' : 'all');
                  await UserState().resetStatsOrder(rangeStr);
                  setState(() {});
                },
              ),
              Divider(height: 1, color: isNight ? Colors.white10 : Colors.black12, indent: 56),
              
              _buildManageOption(
                icon: CupertinoIcons.camera_viewfinder,
                title: '生成总结海报',
                subtitle: '导出您的高清情绪统计卡片',
                isNight: isNight,
                onTap: () {
                  Navigator.pop(context);
                  _showPosterPreview(context, isNight);
                },
              ),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }

  Widget _buildManageOption({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool isNight,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: isNight ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.03),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: isNight ? Colors.white70 : Colors.black54, size: 18),
      ),
      title: Text(
        title,
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.bold,
          color: isNight ? Colors.white.withValues(alpha: 0.9) : const Color(0xFF1F2937),
          fontFamily: 'LXGWWenKai',
        ),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(
          fontSize: 11,
          color: isNight ? Colors.white38 : Colors.black45,
          fontFamily: 'LXGWWenKai',
        ),
      ),
      trailing: Icon(
        Icons.chevron_right_rounded,
        size: 18,
        color: isNight ? Colors.white24 : Colors.black26,
      ),
      onTap: onTap,
    );
  }

}
