import 'dart:ui';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:island_diary/core/state/user_state.dart';
import 'package:island_diary/features/record/domain/models/diary_entry.dart';
import 'package:island_diary/features/record/presentation/widgets/month_calendar_card.dart';
import 'package:intl/intl.dart';
import 'package:island_diary/shared/widgets/mood_picker/config/mood_config.dart';

/// 记录页面的查看模式
enum RecordViewMode {
  timeline, // 经典列表
  calendar, // 日历视图
  bubble, // 藤蔓泡泡（对话模式）
}

class RecordPage extends StatefulWidget {
  const RecordPage({super.key});

  @override
  State<RecordPage> createState() => _RecordPageState();
}

class _RecordPageState extends State<RecordPage> {
  int _selectedYear = DateTime.now().year;
  RecordViewMode _viewMode = RecordViewMode.bubble;

  @override
  Widget build(BuildContext context) {
    // 根据时间决定背景
    final int hour = DateTime.now().hour;
    final bool isNight = hour >= 18 || hour < 6;

    String bgPath;
    if (isNight) {
      bgPath = 'assets/images/record_night.png';
    } else if (hour >= 10 && hour < 18) {
      // 中午和下午：使用用户指定的 daytime2
      bgPath = 'assets/images/record_daytime2.png';
    } else {
      // 早晨/上午：使用较清新的 daytime
      bgPath = 'assets/images/record_daytime.png';
    }

    // 强制全局居中，解决不同尺寸下的藤蔓对齐问题
    const Alignment bgAlignment = Alignment.center;

    return Stack(
      children: [
        // 1. 底层清晰背景 - 锁定居中对齐
        Positioned.fill(
          child: Image.asset(bgPath, fit: BoxFit.cover, alignment: bgAlignment),
        ),

        // 1.5 氛围层：夜晚萤火虫 (仅在夜晚显示)
        if (isNight) const Positioned.fill(child: _FirefliesOverlay()),

        // 2. 主体展示区域 (优化过渡曲线)
        Positioned.fill(
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 400),
            switchInCurve: Curves.easeOutQuart,
            switchOutCurve: Curves.easeInQuart,
            child: _buildCurrentView(),
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
    );
  }

  /// 根据当前模式分发视图
  Widget _buildCurrentView() {
    switch (_viewMode) {
      case RecordViewMode.calendar:
        return _buildCalendarView();
      case RecordViewMode.timeline:
        return _buildTimelineView();
      case RecordViewMode.bubble:
        return _buildVineBubbleView(); // 待实现
    }
  }

  /// 构建视图切换按钮
  Widget _buildViewToggleButton() {
    IconData icon;
    switch (_viewMode) {
      case RecordViewMode.timeline:
        icon = Icons.calendar_month;
        break;
      case RecordViewMode.calendar:
        icon = Icons.bubble_chart;
        break;
      case RecordViewMode.bubble:
        icon = Icons.view_headline;
        break;
    }

    return GestureDetector(
      onTap: () {
        setState(() {
          // 循环切换逻辑
          if (_viewMode == RecordViewMode.timeline) {
            _viewMode = RecordViewMode.calendar;
          } else if (_viewMode == RecordViewMode.calendar) {
            _viewMode = RecordViewMode.bubble;
          } else {
            _viewMode = RecordViewMode.timeline;
          }
        });
      },
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
            child: Icon(icon, size: 22, color: Colors.white.withOpacity(0.9)),
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

  /// 藤蔓泡泡（对话模式）视图
  Widget _buildVineBubbleView() {
    return LayoutBuilder(
      builder: (context, constraints) {
        return ValueListenableBuilder<List<DiaryEntry>>(
          valueListenable: UserState().savedDiaries,
          builder: (context, allDiaries, child) {
            final diaries =
                allDiaries
                    .where((e) => e.dateTime.year == _selectedYear)
                    .toList()
                  ..sort((a, b) => a.dateTime.compareTo(b.dateTime));

            if (diaries.isEmpty) {
              return const Center(
                child: Text(
                  '等待新的回忆发芽...',
                  style: TextStyle(color: Colors.white54, fontSize: 16),
                ),
              );
            }

            const double stepHeight = 160.0;
            final double viewportHeight = constraints.hasBoundedHeight
                ? constraints.maxHeight
                : MediaQuery.of(context).size.height;
            // 计算记录内容的实际高度
            final double contentHeight = diaries.length * stepHeight + 480.0;
            // 确保滚动区域至少等于视口高度，但若内容不足则不产生强制溢出
            final double totalHeight = math.max(contentHeight, viewportHeight);

            return SizedBox(
              height: viewportHeight,
              width: constraints.maxWidth,
              child: SingleChildScrollView(
                key: const ValueKey('bubble_vine_scroll'),
                // 仅在内容超过视口时允许滚动
                child: SizedBox(
                  width: constraints.maxWidth,
                  height: totalHeight,
                  child: Stack(
                    alignment: Alignment.topCenter,
                    children: [
                      // 1. 背景层 (整体居中)
                      Positioned.fill(
                        child: Center(
                          child: SizedBox(
                            width: math.min(constraints.maxWidth, 400.0),
                            height: totalHeight,
                            child: Stack(
                              children: [
                                // 氛围发光层
                                Positioned.fill(
                                  child: ImageFiltered(
                                    imageFilter: ImageFilter.blur(
                                      sigmaX: 8,
                                      sigmaY: 8,
                                    ),
                                    child: ColorFiltered(
                                      colorFilter: ColorFilter.mode(
                                        const Color(
                                          0xFFFFF176,
                                        ).withOpacity(0.05),
                                        BlendMode.srcATop,
                                      ),
                                      child: _buildVineImages(
                                        context,
                                        totalHeight,
                                      ),
                                    ),
                                  ),
                                ),
                                // 藤蔓本体层
                                _buildVineImages(context, totalHeight),
                              ],
                            ),
                          ),
                        ),
                      ),

                      // 2. 气泡内容层
                      ...List.generate(diaries.length, (index) {
                        final diary = diaries[index];
                        final bool isLeft = index % 2 != 0;
                        final double topPos = index * stepHeight + 120;
                        // 核心：计算 Pod 中心的物理 Y 坐标 (基准下移 60px)，实现精准“吸附”
                        final double podCenterY = topPos + 60;
                        final double podX = _getVineXAt(podCenterY);

                        return Positioned(
                          top: topPos,
                          left: 0,
                          right: 0,
                          child: _VineBubbleItem(
                            diary: diary,
                            isLeft: isLeft,
                            podXOffset: podX,
                            yOffset: 0, // 已经在 topPos 中包含了基础偏移
                          ),
                        );
                      }),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  /// 恢复：卡片式日历视图
  Widget _buildCalendarView() {
    return ValueListenableBuilder<List<DiaryEntry>>(
      valueListenable: UserState().savedDiaries,
      builder: (context, allDiaries, child) {
        final yearDiaries = allDiaries
            .where((e) => e.dateTime.year == _selectedYear)
            .toList();

        final Set<int> months = yearDiaries
            .map((e) => e.dateTime.month)
            .toSet();
        final List<int> sortedMonths = months.toList()
          ..sort((a, b) => b.compareTo(a));

        if (sortedMonths.isEmpty) {
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

/// 藤蔓对话项：包含中心 Pod 和 侧向气泡
class _VineBubbleItem extends StatelessWidget {
  final DiaryEntry diary;
  final bool isLeft;
  final double podXOffset;
  final double yOffset;

  const _VineBubbleItem({
    required this.diary,
    required this.isLeft,
    this.podXOffset = 0,
    this.yOffset = 0,
  });

  @override
  Widget build(BuildContext context) {
    return Transform.translate(
      offset: Offset(0, yOffset),
      child: Container(
        constraints: const BoxConstraints(minHeight: 120),
        child: Stack(
          alignment: Alignment.center,
          children: [
            // 1. 中心发光点 Pod (应用水平偏移)
            Transform.translate(
              offset: Offset(podXOffset, 0),
              child: SizedBox(
                width: 40,
                height: 40,
                child: CustomPaint(painter: _VinePodPainter()),
              ),
            ),

            // 2. 有机连接线 (Tendril) (传递偏移量供绘图器使用)
            Positioned.fill(
              child: CustomPaint(
                painter: _TendrilPainter(
                  isLeft: isLeft,
                  podXOffset: podXOffset,
                ),
              ),
            ),

            // 3. 左右气泡实现 (紧凑型布局，使气泡紧贴藤蔓)
            Row(
              children: [
                // 左侧槽位
                Expanded(
                  child: isLeft
                      ? Align(
                          alignment: Alignment.centerRight, // 磁吸至中心藤蔓
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 460),
                            child: Padding(
                              padding: const EdgeInsets.only(
                                right: 35,
                              ), // 给 Pod 和卷须留出空间
                              child: _DialogueBubble(
                                diary: diary,
                                isLeft: isLeft,
                              ),
                            ),
                          ),
                        )
                      : const SizedBox.shrink(),
                ),

                // 中心避让区 (供藤蔓和 Pod 展示)
                const SizedBox(width: 50),

                // 右侧槽位
                Expanded(
                  child: !isLeft
                      ? Align(
                          alignment: Alignment.centerLeft, // 磁吸至中心藤蔓
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 460),
                            child: Padding(
                              padding: const EdgeInsets.only(
                                left: 35,
                              ), // 给 Pod 和卷须留出空间
                              child: _DialogueBubble(
                                diary: diary,
                                isLeft: isLeft,
                              ),
                            ),
                          ),
                        )
                      : const SizedBox.shrink(),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// 绘制连接 Pod 与气泡的有机卷须
class _TendrilPainter extends CustomPainter {
  final bool isLeft;
  final double podXOffset;
  _TendrilPainter({required this.isLeft, this.podXOffset = 0});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white70.withOpacity(0.6)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5;

    // 起点同步发光点的偏移
    final center = Offset(size.width / 2 + podXOffset, size.height / 2);
    // 精确计算气泡边缘位置：基于中轴线的固定偏移 (25px 避让区 + 35px 呼吸间距 = 60px)
    final targetX = isLeft ? (size.width / 2 - 60) : (size.width / 2 + 60);
    final target = Offset(targetX, size.height / 2);

    final path = Path();
    path.moveTo(center.dx, center.dy);

    // 使用贝塞尔曲线模拟“卷须”感
    final controlPoint = Offset(
      (center.dx + target.dx) / 2,
      center.dy + (isLeft ? -20 : 20),
    );

    path.quadraticBezierTo(
      controlPoint.dx,
      controlPoint.dy,
      target.dx,
      target.dy,
    );
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}

/// 藤蔓发光点绘制器 (Pod)
class _VinePodPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final paint = Paint()..style = PaintingStyle.fill;

    // 1. 最外层扩散云（极淡的黄色辉光）
    paint.color = const Color(0xFFFFF176).withOpacity(0.12);
    paint.maskFilter = const MaskFilter.blur(BlurStyle.normal, 12);
    canvas.drawCircle(center, 22, paint);

    // 2. 中层氛围光晕
    paint.color = const Color(0xFFFFF59D).withOpacity(0.25);
    paint.maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);
    canvas.drawCircle(center, 14, paint);

    // 3. 核心辉光圈
    paint.color = const Color(0xFFFFF176).withOpacity(0.6);
    paint.maskFilter = const MaskFilter.blur(BlurStyle.normal, 2);
    canvas.drawCircle(center, 8, paint);

    // 4. 最内层高亮白点
    paint.color = Colors.white.withOpacity(0.95);
    paint.maskFilter = null;
    canvas.drawCircle(center, 3.5, paint);

    // 增加一个小小的顶部高亮反光
    final highlightRect = Rect.fromCircle(
      center: center.translate(-1, -1),
      radius: 1.5,
    );
    canvas.drawOval(
      highlightRect,
      Paint()
        ..color = Colors.white
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 0.5),
    );
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}

/// 藤蔓素材衔接点专用发光点 (Junction Pod) - 体积更大、发光更散，用于掩盖接缝
class _VineJunctionPodPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final paint = Paint()..style = PaintingStyle.fill;

    // --- 灵感颜色：用戶指定的金棕色 ---
    final baseGold = const Color.fromRGBO(213, 188, 123, 1);

    // 1. 新增：更广域的氛围底光
    paint.color = baseGold.withOpacity(0.04);
    paint.maskFilter = const MaskFilter.blur(BlurStyle.normal, 50);
    canvas.drawCircle(center, 140, paint);

    // 2. 中层扩散辉光 (替代原来的生硬线条)
    paint.color = baseGold.withOpacity(0.08);
    paint.maskFilter = const MaskFilter.blur(BlurStyle.normal, 20);
    canvas.drawCircle(center, 80, paint);

    // 3. 核心氛围圈 (由 45 增大至 65)
    paint.color = baseGold.withOpacity(0.2);
    paint.maskFilter = const MaskFilter.blur(BlurStyle.normal, 10);
    canvas.drawCircle(center, 65, paint);

    // 4. 核心高亮圆 (由 22 增大至 38)
    paint.style = PaintingStyle.fill;
    paint.color = baseGold.withOpacity(0.65);
    paint.maskFilter = const MaskFilter.blur(BlurStyle.normal, 3);
    canvas.drawCircle(center, 38, paint);

    // 5. 极细微的最中心强光点 (由 6 增大至 12)
    paint.color = Colors.white.withOpacity(0.45);
    paint.maskFilter = const MaskFilter.blur(BlurStyle.normal, 2);
    canvas.drawCircle(center, 12, paint);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}

/// 气泡样式的对话框 (自带装饰尾巴)
class _DialogueBubble extends StatelessWidget {
  final DiaryEntry diary;
  final bool isLeft;

  const _DialogueBubble({required this.diary, required this.isLeft});

  @override
  Widget build(BuildContext context) {
    final mood = kMoods[diary.moodIndex.clamp(0, kMoods.length - 1)];
    final dateStr = DateFormat('MM.dd HH:mm').format(diary.dateTime);

    // 自动判定昼夜模式，对标 HomePage 逻辑
    final bool isNight = DateTime.now().hour >= 17 || DateTime.now().hour < 6;

    // 动态视觉配置
    final Color baseColor = isNight
        ? Colors.white.withOpacity(0.08)
        : Colors.white.withOpacity(0.65); // 提升白度：0.3 -> 0.65，作为文字的背景板

    final Color textColor = isNight
        ? Colors.white.withOpacity(0.9)
        : const Color(0xFF453224); // 回归中性深褐，提升高级感
    final Color dateColor = textColor.withOpacity(0.55);
    final Color borderColor = isNight
        ? Colors.white.withOpacity(0.12)
        : Colors.white.withOpacity(0.4); // 增强边界清晰度

    return CustomPaint(
      painter: _BubbleTailPainter(
        isLeft: isLeft,
        color: baseColor,
        isNight: isNight,
        borderColor: borderColor,
      ),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(22), // 稍微增大圆角
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              baseColor.withOpacity(isNight ? 0.15 : 0.8), // 顶部更亮，确保遮盖背景干扰
              baseColor.withOpacity(isNight ? 0.05 : 0.4), // 底部保留通透感
            ],
          ),
          border: Border.all(color: borderColor, width: 0.8),
          boxShadow: [
            BoxShadow(
              color: isNight
                  ? Colors.black.withOpacity(0.4)
                  : const Color(0xFF4A3423).withOpacity(0.15),
              blurRadius: 16,
              offset: const Offset(0, 6),
              spreadRadius: -2,
            ),
            BoxShadow(
              color: Colors.white.withOpacity(isNight ? 0.05 : 0.12),
              blurRadius: 2,
              offset: const Offset(1, 1),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(22),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16), // 增强模糊
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              child: Column(
                crossAxisAlignment: isLeft
                    ? CrossAxisAlignment.start
                    : CrossAxisAlignment.end,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (isLeft) ...[
                        Image.asset(mood.iconPath!, width: 20, height: 20),
                        const SizedBox(width: 8),
                      ],
                      Text(
                        dateStr,
                        style: TextStyle(
                          fontSize: 11,
                          color: dateColor,
                          letterSpacing: 0.5,
                        ),
                      ),
                      if (!isLeft) ...[
                        const SizedBox(width: 8),
                        Image.asset(mood.iconPath!, width: 20, height: 20),
                      ],
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(
                    diary.content,
                    textAlign: isLeft ? TextAlign.left : TextAlign.right,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 14,
                      height: 1.5,
                      color: textColor,
                      fontWeight: isNight
                          ? FontWeight.normal
                          : FontWeight.w500, // 恢复 w500，保持优雅轻盈
                      shadows: isNight
                          ? [
                              Shadow(
                                color: Colors.black.withOpacity(0.2),
                                offset: const Offset(0, 1),
                                blurRadius: 4,
                              ),
                            ]
                          : [], // 彻底移除日间模式下生硬的边缘阴影
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

/// 绘制对话气泡的小尾巴
class _BubbleTailPainter extends CustomPainter {
  final bool isLeft;
  final Color color;
  final bool isNight;
  final Color borderColor;

  _BubbleTailPainter({
    required this.isLeft,
    required this.color,
    required this.isNight,
    required this.borderColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    // 绘制一个小三角形尾巴
    final path = Path();
    if (isLeft) {
      path.moveTo(0, size.height / 2 - 8);
      path.lineTo(-10, size.height / 2);
      path.lineTo(0, size.height / 2 + 8);
    } else {
      path.moveTo(size.width, size.height / 2 - 8);
      path.lineTo(size.width + 10, size.height / 2);
      path.lineTo(size.width, size.height / 2 + 8);
    }
    path.close();

    // 增加更柔和的阴影感
    canvas.drawPath(
      path,
      Paint()
        ..color = isNight
            ? Colors.black.withOpacity(0.2)
            : const Color(0xFF5A3E28).withOpacity(0.05)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3),
    );

    canvas.drawPath(path, paint);

    // 补一圈描边
    final strokePaint = Paint()
      ..color = borderColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.8;
    canvas.drawPath(path, strokePaint);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
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
        color: Colors.white.withOpacity(0.08), // 降低：0.12 -> 0.08
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.15), width: 0.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3), // 加重
            blurRadius: 10, // 收紧
            offset: const Offset(0, 5), // 离近点
            spreadRadius: -2,
          ),
        ],
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

extension on _RecordPageState {
  // 素材 1 (vine.png) 规格
  static const double kVine1TileHeight = 1086.5;
  // 素材 2 (vine2.png) 规格
  static const double kVine2TileHeight = 911.6;

  // --- 集中调节区 ---
  static const double kVine1To2Overlap = 42.0; // 首段 vine 与第二段 vine2 的重叠
  static const double kVine2To2Overlap = 60.0; // vine2 与 vine2 之间的重叠
  static const double kVine1ShiftX = 0.0; // vine1 的左右微调
  static const double kVine2ShiftX = 22.0; // 配合 SkewX 调整基础偏移
  static const double kVine2SkewX = -0.025; // 减小斜切感，让扭曲更温和 (-0.05 -> -0.025)
  static const double kVine2SkewOffset = -4.0; // 相应减小补偿值 (-8.0 -> -4.0)
  // ----------------

  static const double kVine1EffectiveHeight =
      kVine1TileHeight - kVine1To2Overlap;
  static const double kVine2EffectiveHeight =
      kVine2TileHeight - kVine2To2Overlap;

  /// 提取藤蔓组件渲染逻辑，实现 vine + vine2 的无缝拼接，并增加接缝遮盖 Pod
  Widget _buildVineImages(BuildContext context, double totalHeight) {
    final List<Widget> vines = [];
    final List<Widget> junctionPods = [];
    double currentTop = 0;
    int index = 0;

    while (currentTop < totalHeight + 500) {
      final bool isFirst = index == 0;
      final double shiftX = isFirst ? kVine1ShiftX : kVine2ShiftX;

      // 1. 绘制藤蔓素材
      vines.add(
        Positioned(
          top: currentTop,
          left: shiftX,
          right: -shiftX,
          child: Transform(
            // 对非首段应用斜切变形，使其尾部向左扭曲
            transform: isFirst
                ? Matrix4.identity()
                : (Matrix4.skewX(kVine2SkewX)..translate(kVine2SkewOffset)),
            child: Image.asset(
              isFirst ? 'assets/images/vine.png' : 'assets/images/vine2.png',
              width: 400,
              fit: BoxFit.fitWidth,
            ),
          ),
        ),
      );

      // 2. 计算下一段起始位置
      final double nextTop =
          currentTop +
          (isFirst ? kVine1EffectiveHeight : kVine2EffectiveHeight);

      // 3. 收集衔接点发光点 (Junction Pod) 用于视觉遮盖接缝
      if (nextTop < totalHeight + 300) {
        final double podX = _getVineXAt(nextTop);
        junctionPods.add(
          Positioned(
            top: nextTop - 150, // 垂直居中覆盖接缝
            left: 200 + podX - 150, // 400px 宽度中轴对齐
            child: IgnorePointer(
              child: SizedBox(
                width: 300,
                height: 300,
                child: CustomPaint(painter: _VineJunctionPodPainter()),
              ),
            ),
          ),
        );
      }

      currentTop = nextTop;
      index++;
    }

    return Positioned.fill(
      child: Align(
        alignment: Alignment.topCenter,
        child: SizedBox(
          width: 400,
          height: totalHeight,
          child: Stack(
            children: [
              ...vines, // 先放藤蔓
              ...junctionPods, // 发光点强制在最顶层，确保遮盖所有藤蔓
            ],
          ),
        ),
      ),
    );
  }

  /// 核心算法：根据垂直坐标 Y，自动计算对应藤蔓主干的 X 偏移
  double _getVineXAt(double y) {
    final bool isFirstSegment = y < kVine1EffectiveHeight;
    double relativeY;
    List<Offset> lookupTable;
    double segmentShift;

    if (isFirstSegment) {
      relativeY = y;
      segmentShift = 0;
      lookupTable = [
        const Offset(0.0, 30.0),
        const Offset(36.2, 12.5),
        const Offset(72.4, -5.4),
        const Offset(108.7, -12.4),
        const Offset(144.9, -21.8),
        const Offset(181.1, -12.5),
        const Offset(217.3, 24.9),
        const Offset(253.5, 22.8),
        const Offset(289.7, 71.5),
        const Offset(326.0, 39.7),
        const Offset(362.2, 10.7),
        const Offset(398.4, -65.3),
        const Offset(434.6, -73.7),
        const Offset(470.8, -80.0),
        const Offset(507.1, -74.9),
        const Offset(543.3, -103.4),
        const Offset(579.5, -113.3),
        const Offset(615.7, -106.2),
        const Offset(651.9, -130.3),
        const Offset(688.1, -93.5),
        const Offset(724.4, -16.2),
        const Offset(760.6, 11.9),
        const Offset(796.8, 10.8),
        const Offset(833.0, 91.4),
        const Offset(869.2, 98.8),
        const Offset(905.4, 79.6),
        const Offset(941.7, 65.3),
        const Offset(977.9, 32.4),
        const Offset(1014.1, 21.8),
        const Offset(1050.3, 2.9),
        const Offset(1086.5, -16.0),
      ];
    } else {
      // 处于 vine2 循环区 (核心修复：准确计算循环周期内的相对 Y)
      relativeY = (y - kVine1EffectiveHeight) % kVine2EffectiveHeight;
      segmentShift = kVine2ShiftX;
      lookupTable = [
        const Offset(0.0, -20.0),
        const Offset(23.3, -17.2),
        const Offset(46.5, 21.6),
        const Offset(69.8, 23.3),
        const Offset(93.0, 16.3),
        const Offset(116.3, 39.8),
        const Offset(139.5, 64.8),
        const Offset(162.8, 42.4),
        const Offset(186.0, 11.7),
        const Offset(209.3, 11.0),
        const Offset(232.6, -46.9),
        const Offset(255.8, -65.2),
        const Offset(279.1, -40.6),
        const Offset(302.3, -78.1),
        const Offset(325.6, -65.6),
        const Offset(348.8, -100.3),
        const Offset(372.1, -99.9),
        const Offset(395.3, -126.6),
        const Offset(418.6, -86.4),
        const Offset(441.9, -100.3),
        const Offset(465.1, -121.2),
        const Offset(488.4, -119.2),
        const Offset(511.6, -84.1),
        const Offset(534.9, -16.4),
        const Offset(558.1, -6.7),
        const Offset(581.4, -15.2),
        const Offset(604.7, 30.5),
        const Offset(627.9, 50.9),
        const Offset(651.2, 97.8),
        const Offset(674.4, 95.8),
        const Offset(697.7, 89.1),
        const Offset(720.9, 42.4),
        const Offset(744.2, 62.8),
        const Offset(767.4, 19.5),
        const Offset(790.7, 40.8),
        const Offset(814.0, 24.0),
        const Offset(837.2, 5.4),
        const Offset(860.5, -11.9),
        const Offset(911.6, 5.0),
      ];
    }

    for (int i = 0; i < lookupTable.length - 1; i++) {
      final p1 = lookupTable[i];
      final p2 = lookupTable[i + 1];
      if (relativeY >= p1.dx && relativeY <= p2.dx) {
        final double t = (relativeY - p1.dx) / (p2.dx - p1.dx);
        double finalX = p1.dy + (p2.dy - p1.dy) * t + segmentShift;

        // 重要：针对 vine2 的变形进行 X 坐标补偿
        if (!isFirstSegment) {
          // 补偿计算：newX = oldX + relativeY * skewFactor + translation
          finalX += (relativeY * kVine2SkewX) + kVine2SkewOffset;
        }
        return finalX;
      }
    }
    return 6 + segmentShift;
  }
}
