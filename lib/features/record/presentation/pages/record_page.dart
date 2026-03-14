import 'dart:ui';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:island_diary/core/state/user_state.dart';
import 'package:island_diary/features/record/domain/models/diary_entry.dart';
import 'package:island_diary/features/record/presentation/widgets/month_calendar_card.dart';
import 'package:intl/intl.dart';
import 'package:island_diary/shared/widgets/mood_picker/config/mood_config.dart';

class RecordPage extends StatefulWidget {
  const RecordPage({super.key});

  @override
  State<RecordPage> createState() => _RecordPageState();
}

class _RecordPageState extends State<RecordPage> {
  int _selectedYear = DateTime.now().year;
  bool _isCalendarView = false; // 新增：是否为日历视图

  @override
  Widget build(BuildContext context) {
    // 根据时间决定背景
    final int hour = DateTime.now().hour;
    final bool isNight = hour >= 17 || hour < 6;
    final String bgPath = isNight
        ? 'assets/images/record_night.png'
        : 'assets/images/record_daytime2.png';
    // 强制全局居中，解决不同尺寸下的藤蔓对齐问题
    const Alignment bgAlignment = Alignment.center;

    return Scaffold(
      backgroundColor: Colors.transparent, // 确保无底色干扰
      body: Stack(
        children: [
          // 1. 底层清晰背景 - 锁定居中对齐
          Positioned.fill(
            child: Image.asset(
              bgPath,
              fit: BoxFit.cover,
              alignment: bgAlignment,
            ),
          ),

          // 1.5 氛围层：夜晚萤火虫 (仅在夜晚显示)
          if (isNight) const Positioned.fill(child: _FirefliesOverlay()),

          // 2. 主体展示区域 (优化过渡曲线)
          Positioned.fill(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 400),
              switchInCurve: Curves.easeOutQuart,
              switchOutCurve: Curves.easeInQuart,
              child: _isCalendarView
                  ? _buildCalendarView()
                  : _buildTimelineView(),
            ),
          ),

          // 3. 顶部导航/选择器 (明确位置在顶部)
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 40, 24, 0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment:
                      CrossAxisAlignment.start, // 关键修复：确保展开年份时图标不向下偏移
                  children: [
                    // 左侧占位实现绝对居中
                    Expanded(child: Container()),
                    _YearPicker(
                      selectedYear: _selectedYear,
                      onYearChanged: (year) {
                        setState(() {
                          _selectedYear = year;
                        });
                      },
                    ),
                    // 右侧切换按钮
                    Expanded(
                      child: Align(
                        alignment: Alignment.centerRight,
                        child: _buildViewToggleButton(),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// 构建视图切换按钮
  Widget _buildViewToggleButton() {
    return GestureDetector(
      onTap: () => setState(() => _isCalendarView = !_isCalendarView),
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.15),
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white.withOpacity(0.2), width: 0.5),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
            child: Icon(
              _isCalendarView ? Icons.alt_route : Icons.calendar_month,
              size: 22,
              color: Colors.white.withOpacity(0.9),
            ),
          ),
        ),
      ),
    );
  }

  /// 传统的藤蔓时间轴视图
  Widget _buildTimelineView() {
    return ValueListenableBuilder<List<DiaryEntry>>(
      valueListenable: UserState().savedDiaries,
      builder: (context, allDiaries, child) {
        final diaries = allDiaries
            .where((e) => e.dateTime.year == _selectedYear)
            .toList();

        if (diaries.isEmpty) {
          return const Center(
            child: Text(
              '这一年还没有留下足迹...',
              style: TextStyle(color: Colors.white54, fontSize: 16),
            ),
          );
        }

        return ListView.builder(
          key: const ValueKey('timeline'),
          padding: const EdgeInsets.fromLTRB(24, 120, 24, 120),
          itemCount: diaries.length,
          itemBuilder: (context, index) {
            final diary = diaries[index];
            return _TimelineEntryCard(diary: diary);
          },
        );
      },
    );
  }

  /// 新增的卡片式日历视图
  Widget _buildCalendarView() {
    return ValueListenableBuilder<List<DiaryEntry>>(
      valueListenable: UserState().savedDiaries,
      builder: (context, allDiaries, child) {
        // 获取当前选中年份的所有日记
        final yearDiaries = allDiaries
            .where((e) => e.dateTime.year == _selectedYear)
            .toList();

        // 为该年有记录的月份动态生成卡片
        final Set<int> months = yearDiaries
            .map((e) => e.dateTime.month)
            .toSet();
        final List<int> sortedMonths = months.toList()
          ..sort((a, b) => b.compareTo(a));

        if (sortedMonths.isEmpty) {
          // 如果没有记录，显示当前月份的空卡片
          final current = DateTime.now();
          if (current.year == _selectedYear) {
            sortedMonths.add(current.month);
          } else {
            return const Center(
              child: Text('暂无记录', style: TextStyle(color: Colors.white54)),
            );
          }
        }

        return ListView.builder(
          key: const ValueKey('calendar'),
          padding: const EdgeInsets.only(top: 100, bottom: 120),
          itemCount: sortedMonths.length,
          itemBuilder: (context, index) {
            final month = sortedMonths[index];
            final monthDiaries = yearDiaries
                .where((e) => e.dateTime.month == month)
                .toList();

            return MonthCalendarCard(
              year: _selectedYear,
              month: month,
              monthDiaries: monthDiaries,
            );
          },
        );
      },
    );
  }
}

/// 顶部玻璃拟态年份选择器
class _YearPicker extends StatefulWidget {
  final int selectedYear;
  final ValueChanged<int> onYearChanged;

  const _YearPicker({required this.selectedYear, required this.onYearChanged});

  @override
  State<_YearPicker> createState() => _YearPickerState();
}

class _YearPickerState extends State<_YearPicker> {
  bool _isExpanded = false;

  // 模拟可选年份列表，实际开发中可以从数据中提取
  final List<int> _years = [
    DateTime.now().year,
    DateTime.now().year - 1,
    DateTime.now().year - 2,
  ];

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => setState(() => _isExpanded = !_isExpanded),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.15),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: Colors.white.withOpacity(0.2), width: 0.5),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '${widget.selectedYear} 年',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white.withOpacity(0.9),
                          shadows: [
                            Shadow(
                              color: Colors.black.withOpacity(0.2),
                              blurRadius: 4,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 4),
                      AnimatedRotation(
                        turns: _isExpanded ? 0.5 : 0,
                        duration: const Duration(milliseconds: 300),
                        child: Icon(
                          Icons.keyboard_arrow_down,
                          size: 20,
                          color: Colors.white.withOpacity(0.9),
                        ),
                      ),
                    ],
                  ),
                  if (_isExpanded)
                    Padding(
                      padding: const EdgeInsets.only(top: 12),
                      child: Column(
                        children: _years
                            .where((y) => y != widget.selectedYear)
                            .map(
                              (year) => GestureDetector(
                                onTap: () {
                                  widget.onYearChanged(year);
                                  setState(() => _isExpanded = false);
                                },
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 6,
                                    horizontal: 8,
                                  ),
                                  child: Text(
                                    '$year 年',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Colors.white.withOpacity(0.7),
                                    ),
                                  ),
                                ),
                              ),
                            )
                            .toList(),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// 时间轴上的单条记录卡片
class _TimelineEntryCard extends StatelessWidget {
  final DiaryEntry diary;

  const _TimelineEntryCard({required this.diary});

  @override
  Widget build(BuildContext context) {
    final mood = kMoods[diary.moodIndex.clamp(0, kMoods.length - 1)];
    // 显式使用 DateFormat
    final String dateStr = DateFormat('MM月dd日').format(diary.dateTime);
    final String timeStr = DateFormat('HH:mm').format(diary.dateTime);

    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.15), width: 0.5),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 左侧时间/心情
                Column(
                  children: [
                    Image.asset(mood.iconPath!, width: 32, height: 32),
                    const SizedBox(height: 8),
                    Text(
                      timeStr,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.white.withOpacity(0.5),
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 16),
                // 右侧内容
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            dateStr,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.white.withOpacity(0.9),
                            ),
                          ),
                          Text(
                            mood.label,
                            style: TextStyle(
                              fontSize: 13,
                              color: (mood.glowColor ?? Colors.white)
                                  .withOpacity(0.8),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Text(
                        diary.content.replaceAll('\n', ' '),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 14,
                          height: 1.5,
                          color: Colors.white.withOpacity(0.7),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// 萤火虫氛围层
class _FirefliesOverlay extends StatefulWidget {
  const _FirefliesOverlay({super.key});

  @override
  State<_FirefliesOverlay> createState() => _FirefliesOverlayState();
}

class _FirefliesOverlayState extends State<_FirefliesOverlay>
    with SingleTickerProviderStateMixin {
  late Ticker _ticker;
  double _elapsedSeconds = 0;

  @override
  void initState() {
    super.initState();
    _ticker = createTicker((elapsed) {
      setState(() {
        _elapsedSeconds = elapsed.inMicroseconds / 1000000.0;
      });
    });
    _ticker.start();
  }

  @override
  void dispose() {
    _ticker.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final padding = MediaQuery.of(context).padding;
    final topBarY = padding.top + 25;
    // 底部工具栏大致位置
    final bottomBarY = MediaQuery.of(context).size.height - padding.bottom - 45;

    return CustomPaint(
      painter: _FirefliesPainter(_elapsedSeconds, topBarY, bottomBarY),
    );
  }
}

class _FirefliesPainter extends CustomPainter {
  final double animationValue;
  final double topBarY;
  final double bottomBarY;

  // 增加到 70 个粒子，前 6 个负责底部彩蛋 (sp=2)
  static final List<Map<String, double>> _particles = List.generate(70, (i) {
    int spStatus = 0;
    if (i < 6) spStatus = 2; // 全部设为底部彩蛋

    final bool isBottomEgg = spStatus == 2;
    double seed(double k) => (i * k + 0.123) % 1.0;

    return {
      'x': seed(0.713),
      // 底部彩蛋强制初始在屏幕底端 (0.85 - 0.98 区域)，确保不从天而降
      'y': isBottomEgg ? 0.85 + seed(0.421) * 0.13 : seed(0.237),
      's': 1.0 + seed(0.33) * 1.5,
      'ph': i * 1.5,
      'vx': -30.0 + seed(0.887) * 60.0,
      'vy': -25.0 + seed(0.662) * 50.0,
      'wf': 0.4 + seed(0.12) * 1.5,
      'wa': 10.0 + seed(0.95) * 30.0,
      'sp': spStatus.toDouble(),
      'to': seed(0.55) * 25.0, // 独特的时间偏移
    };
  });

  _FirefliesPainter(this.animationValue, this.topBarY, this.bottomBarY);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;

    for (var i = 0; i < _particles.length; i++) {
      final config = _particles[i];
      final double spStatus = config['sp']!;
      final bool isSpecial = spStatus == 2.0;

      // 1. 呼吸闪烁
      final double opacityValue = (animationValue * 2.5 + config['ph']!);
      double baseOpacity = (0.1 + 0.6 * (0.5 + 0.5 * math.sin(opacityValue)))
          .clamp(0.0, 1.0);

      // 2. 运动控制实现
      double x, y;
      double finalOpacity = baseOpacity;

      if (isSpecial) {
        // 彩蛋逻辑：每 25 秒一个轮回
        const double cycle = 25.0;
        final double t = (animationValue + config['to']!) % cycle;
        final double startX = config['x']! * size.width;
        final double startY = config['y']! * size.height;

        // 分散的目标点：跨越屏幕 10% - 90%
        final double targetX = size.width * (0.1 + ((i * 0.17) % 0.8));
        final double targetY = bottomBarY + (i % 2 == 0 ? 3 : -3);

        const double swimTime = 7.0; // 游走时长
        final double anchorX = (startX + config['vx']! * swimTime) % size.width;
        double anchorY = (startY + config['vy']! * swimTime) % size.height;
        if (anchorY < 0) anchorY += size.height;

        if (t < swimTime) {
          x = (startX + config['vx']! * t) % size.width;
          y = (startY + config['vy']! * t) % size.height;
          if (y < 0) y += size.height;
        } else if (t < 10.5) {
          // 阶段 B: 减速接近
          final double p = (t - swimTime) / 3.5;
          final double easing = 1.0 - math.pow(1.0 - p, 3.0).toDouble();
          final double searchingWave = 15.0 * (1.0 - p) * math.sin(p * 10.0);
          x = anchorX + (targetX - anchorX) * easing + searchingWave;
          y = anchorY + (targetY - anchorY) * easing;
        } else if (t < 17.5) {
          // 阶段 C: 停靠休息
          x = targetX + 1.5 * math.sin(animationValue * 2.0);
          y = targetY + 1.0 * math.cos(animationValue * 1.5);
          baseOpacity = 0.8 + 0.2 * math.sin(animationValue * 3.0);
        } else {
          // 阶段 D: 平滑向下飞离并渐隐
          final double p = (t - 17.5) / 7.5;
          final double easing = (p * p).toDouble();
          x = targetX + (size.width * 0.3) * (i % 2 == 0 ? 1 : -1) * easing;
          y = targetY + (size.height * 0.15) * easing;
          baseOpacity *= (1.0 - p);
        }
        finalOpacity = baseOpacity;
      } else {
        // 普通漫游
        final double xLinear =
            config['x']! * size.width + config['vx']! * animationValue;
        final double yLinear =
            config['y']! * size.height + config['vy']! * animationValue;
        final double xWave =
            config['wa']! *
            math.sin(animationValue * config['wf']! + config['ph']!);

        x = (xLinear + xWave) % size.width;
        y = yLinear % size.height;
        if (y < 0) y = size.height + (y % size.height);

        final double altitudeFactor = (y / size.height).clamp(0.0, 1.0);
        finalOpacity = baseOpacity * math.pow(altitudeFactor, 2.5).toDouble();
      }

      if (finalOpacity < 0.01) continue;

      final double radius = config['s']!;
      paint.color = const Color(0xFFFFF9C4).withOpacity(finalOpacity);
      canvas.drawCircle(Offset(x, y), radius, paint);

      paint.color = const Color(0xFFFFF176).withOpacity(finalOpacity * 0.3);
      canvas.drawCircle(Offset(x, y), radius * 2.5, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _FirefliesPainter oldDelegate) => true;
}
