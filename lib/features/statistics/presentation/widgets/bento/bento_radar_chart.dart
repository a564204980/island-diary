part of '../../pages/statistics_page.dart';

/// 情感强度数据模型
class _RadarIntensityData {
  final int moodIndex;
  final String label;
  final double avgIntensity; // 0.0 - 10.0
  final Color glowColor;
  final String? iconPath;
  final bool isNegative;

  _RadarIntensityData({
    required this.moodIndex,
    required this.label,
    required this.avgIntensity,
    required this.glowColor,
    this.iconPath,
    this.isNegative = false,
  });
}

extension _BentoRadarChart on _StatisticsPageState {
  Widget _buildRadarBento(
    bool isNight,
    List<DiaryEntry> entries,
    Color themeColor,
  ) {
    if (entries.isEmpty) return const SizedBox.shrink();

    final bool isCottonCandy =
        UserState().selectedIslandThemeId.value == 'cotton_candy';
    final Color accentColor = isCottonCandy
        ? const Color(0xFFF7AAB6)
        : themeColor;

    // 1. 数据统计与聚合 - 预设 11 个内置心情作为“基础底座”
    final Map<int, List<double>> moodIndexToIntensities = {};
    for (int i = 0; i < kMoods.length; i++) {
      moodIndexToIntensities[i] = <double>[];
    }

    for (var e in entries) {
      final int moodIndex = e.moodIndex % kMoods.length;
      moodIndexToIntensities[moodIndex]?.add(e.intensity.toDouble());
    }

    final Map<int, int> moodCounts = {};
    for (var e in entries) {
      final int moodIndex = e.moodIndex % kMoods.length;
      moodCounts[moodIndex] = (moodCounts[moodIndex] ?? 0) + 1;
    }

    final List<_RadarIntensityData> chartData = [];
    // 按顺序处理内置 11 心情
    for (int moodIndex = 0; moodIndex < kMoods.length; moodIndex++) {
      final intensities = moodIndexToIntensities[moodIndex] ?? const <double>[];
      final avg = intensities.isEmpty
          ? 0.0
          : intensities.reduce((a, b) => a + b) / intensities.length;
      final mood = kMoods[moodIndex];
      final color = mood.glowColor ?? Colors.blueAccent;
      final List<String> radarIcons = [
        'assets/icons/happy.png',
        'assets/icons/calm.png',
        'assets/icons/down.png',
        'assets/icons/irritated.png',
        'assets/icons/tired.png',
        'assets/icons/surprise.png',
        'assets/icons/shy.png',
        'assets/icons/anxious.png',
        'assets/icons/wronged.png',
        'assets/icons/bored.png',
        'assets/icons/expect.png',
      ];
      final icon = radarIcons[moodIndex % kMoods.length];
      final negative = [2, 3, 4, 7, 8, 9].contains(moodIndex % kMoods.length);

      chartData.add(
        _RadarIntensityData(
          moodIndex: moodIndex,
          label: mood.label,
          avgIntensity: avg,
          glowColor: color,
          iconPath: icon,
          isNegative: negative,
        ),
      );
    }

    final _RadarIntensityData? strongestMood = chartData
        .where((item) => item.avgIntensity > 0)
        .fold<_RadarIntensityData?>(null, (best, item) {
      if (best == null) return item;
      if (item.avgIntensity > best.avgIntensity) return item;
      return best;
    });

    final int? mostCommonMoodIndex = moodCounts.entries.isEmpty
        ? null
        : moodCounts.entries.reduce((a, b) => a.value >= b.value ? a : b).key;
    final String summaryText = strongestMood == null
        ? '这段时间的心情分布还比较平均。'
        : '本期最强：${strongestMood.label}'
            '${mostCommonMoodIndex != null ? '，出现最多：${kMoods[mostCommonMoodIndex].label}' : ''}';

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: _buildGlassCard(
        isNight: isNight,
        backgroundColor: isCottonCandy ? const Color(0xFFFFF4EF) : null,
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildBentoHeader(
              context: context,
              title: '心境雷达',
              helpContent:
                  '这个图会把不同心情放到不同方向上。线越长，说明那种心情在这段时间里越强。',
              isNight: isNight,
              rightAction: Icon(
                CupertinoIcons.compass,
                size: 18,
                color: accentColor.withValues(alpha: isNight ? 0.72 : 0.8),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              summaryText,
              style: TextStyle(
                fontSize: 12,
                height: 1.3,
                fontWeight: FontWeight.w500,
                color: isNight
                    ? Colors.white60
                    : (isCottonCandy
                        ? const Color(0xFFB28D7B)
                        : const Color(0xFF6D5A4B)),
                fontFamily: 'LXGWWenKai',
              ),
            ),
            const SizedBox(height: 14),
            LayoutBuilder(
              builder: (context, constraints) {
                final double size = constraints.maxWidth;
                final double radius = size / 4.8;
                final int n = chartData.length;

                final double graphHeight = size * 0.75;
                final Offset chartCenter = Offset(size / 2, graphHeight / 2);

                return SizedBox(
                  height: graphHeight,
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      // 1. 雷达背景与多边形层
                      Positioned.fill(
                        child: CustomPaint(
                          size: Size(size, graphHeight),
                          painter: _IntensityRadarPainter(
                            data: chartData,
                            isNight: isNight,
                            radius: radius,
                            themeColor: themeColor,
                            center: chartCenter,
                          ),
                        ),
                      ),
                      // 2. 顶点点击热区 (新增交互)
                      ...List.generate(n, (i) {
                        double angle = (2 * pi / n) * i - pi / 2;
                        final item = chartData[i];
                        // 强度分值 (10分制)
                        final score = item.avgIntensity;
                        if (score <= 0) return const SizedBox.shrink();

                        double val = (score / 10.0).clamp(0.001, 1.0);
                        double r = radius * val;

                        double px = chartCenter.dx + r * cos(angle);
                        double py = chartCenter.dy + r * sin(angle);

                        return Positioned(
                          left: px - 18,
                          top: py - 18,
                          width: 36,
                          height: 36,
                          child: GestureDetector(
                            behavior: HitTestBehavior.opaque,
                            onTap: () => updateRadarPointIndex(i),
                            child: Container(color: Colors.transparent),
                          ),
                        );
                      }),
                      // 自定义提示框
                      if (_selectedRadarPointIndex != null &&
                          _selectedRadarPointIndex! < chartData.length) ...[
                        () {
                          final item = chartData[_selectedRadarPointIndex!];
                          final double angle =
                              (2 * pi / n) * _selectedRadarPointIndex! - pi / 2;
                          final double val = (item.avgIntensity / 10.0).clamp(
                            0.001,
                            1.0,
                          );
                          final double r = radius * val;
                          final double px = chartCenter.dx + r * cos(angle);
                          final double py = chartCenter.dy + r * sin(angle);

                          return _buildBentoTooltip(
                            title: '心情：${item.label}',
                            items: [
                              _BentoTooltipItem(
                                label: '情绪强度',
                                value: item.avgIntensity.toStringAsFixed(1),
                                color: item.glowColor,
                              ),
                              _BentoTooltipItem(
                                label: '情绪特质',
                                value: item.isNegative
                                    ? '低能阴雨'
                                    : (item.avgIntensity > 8 ? '高频滋养' : '平稳过渡'),
                              ),
                            ],
                            relativeX: px / size,
                            chartWidth: size,
                            isNight: isNight,
                            useCottonCandyStyle: isCottonCandy,
                            top: py > graphHeight / 2
                                ? py - 120
                                : py + 20, // 根据位置动态上下偏移
                          );
                        }(),
                      ],
                      // 3. 悬浮标签与图标 (原有布局)
                      ...List.generate(n, (i) {
                        double angle = (2 * pi / n) * i - pi / 2;
                        double labelR = radius + 32;
                        double lx = chartCenter.dx + labelR * cos(angle);
                        double ly = chartCenter.dy + labelR * sin(angle);

                        final item = chartData[i];
                        final bool hideIcons = n > 19;
                        final double fontSize = 10.5;
                        final double iconSize = 22.0;

                        return Positioned(
                          left: lx - 30,
                          top: ly - (hideIcons ? 15 : 28), // 纯文字模式下上移一点以居中于轴端
                          width: 60,
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (item.iconPath != null && !hideIcons)
                                Container(
                                  padding: EdgeInsets.all(n > 13 ? 3 : 4),
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: item.avgIntensity > 0
                                        ? item.glowColor.withValues(
                                            alpha: isNight ? 0.22 : 0.16,
                                          )
                                        : (isNight
                                              ? Colors.white10
                                              : Colors.black.withValues(
                                                  alpha: 0.04,
                                                )),
                                    boxShadow: [
                                      if (item.avgIntensity > 0)
                                        BoxShadow(
                                          color: item.glowColor.withValues(
                                            alpha: 0.12,
                                          ),
                                          blurRadius: 6,
                                          spreadRadius: -3,
                                        ),
                                      if (item.avgIntensity == 0)
                                        BoxShadow(
                                          color: item.glowColor.withValues(
                                            alpha: 0.05,
                                          ),
                                          blurRadius: 4,
                                        ),
                                    ],
                                  ),
                                  child: Image.asset(
                                    item.iconPath!,
                                    width: iconSize,
                                    height: iconSize,
                                    errorBuilder:
                                        (context, error, stackTrace) =>
                                            const SizedBox(),
                                  ),
                                ),
                              if (!hideIcons) const SizedBox(height: 3),
                              Text(
                                item.label,
                                textAlign: TextAlign.center,
                                maxLines: 1, // 恢复单行显示
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: fontSize,
                                  fontWeight: FontWeight.bold,
                                  color: isNight
                                      ? Colors.white70
                                      : (isCottonCandy
                                            ? const Color(0xFF9A7A69)
                                            : const Color(0xFF332F2D)),
                                  fontFamily: 'LXGWWenKai',
                                  height: 1.2,
                                ),
                              ),
                            ],
                          ),
                        );
                      }),
                    ],
                  ),
                );
              },
            ),
            _buildCustomTagsSection(isNight, entries, isCottonCandy),
          ],
        ),
      ),
    );
  }

  Widget _buildCustomTagsSection(
    bool isNight,
    List<DiaryEntry> entries,
    bool isCottonCandy,
  ) {
    final Map<String, int> tagCounts = {};
    for (var e in entries) {
      if (e.tag != null && e.tag!.isNotEmpty) {
        tagCounts[e.tag!] = (tagCounts[e.tag!] ?? 0) + 1;
      }
    }

    if (tagCounts.isEmpty) return const SizedBox.shrink();

    final sortedTags = tagCounts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    final colors = _getTagColors(isNight);

    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 16, 4, 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 1,
            margin: const EdgeInsets.only(bottom: 12),
            color: isNight
                ? Colors.white.withValues(alpha: 0.06)
                : Colors.black.withValues(alpha: 0.04),
          ),
          Text(
            '常用标签',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              fontFamily: 'LXGWWenKai',
              color: isNight
                  ? Colors.white60
                  : (isCottonCandy
                      ? const Color(0xFF9A7A69)
                      : const Color(0xFF332F2D)),
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: List.generate(sortedTags.length, (index) {
              final tag = sortedTags[index].key;
              final count = sortedTags[index].value;
              final colorScheme = colors[index % colors.length];

              return Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: colorScheme['bg'],
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: colorScheme['border']!, width: 0.7),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      tag,
                      style: TextStyle(
                        fontSize: 11.5,
                        color: colorScheme['text'],
                        fontFamily: 'LXGWWenKai',
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '$count',
                      style: TextStyle(
                        fontSize: 10.5,
                        color: colorScheme['text']!.withValues(alpha: 0.65),
                        fontFamily: 'LXGWWenKai',
                        fontWeight: FontWeight.bold,
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

  List<Map<String, Color>> _getTagColors(bool isNight) {
    if (isNight) {
      return [
        {
          'bg': const Color(0xFF7B1FA2).withValues(alpha: 0.12),
          'text': const Color(0xFFE1BEE7),
          'border': const Color(0xFF9C27B0).withValues(alpha: 0.25),
        },
        {
          'bg': const Color(0xFF2E7D32).withValues(alpha: 0.12),
          'text': const Color(0xFFC8E6C9),
          'border': const Color(0xFF4CAF50).withValues(alpha: 0.25),
        },
        {
          'bg': const Color(0xFF1565C0).withValues(alpha: 0.12),
          'text': const Color(0xFFBBDEFB),
          'border': const Color(0xFF2196F3).withValues(alpha: 0.25),
        },
        {
          'bg': const Color(0xFFC62828).withValues(alpha: 0.12),
          'text': const Color(0xFFFFCDD2),
          'border': const Color(0xFFE57373).withValues(alpha: 0.25),
        },
        {
          'bg': const Color(0xFFEF6C00).withValues(alpha: 0.12),
          'text': const Color(0xFFFFECB3),
          'border': const Color(0xFFFFB74D).withValues(alpha: 0.25),
        },
      ];
    } else {
      return [
        {
          'bg': const Color(0xFFF3E5F5),
          'text': const Color(0xFF7B1FA2),
          'border': const Color(0xFFE1BEE7),
        },
        {
          'bg': const Color(0xFFE8F5E9),
          'text': const Color(0xFF2E7D32),
          'border': const Color(0xFFC8E6C9),
        },
        {
          'bg': const Color(0xFFE3F2FD),
          'text': const Color(0xFF1565C0),
          'border': const Color(0xFFBBDEFB),
        },
        {
          'bg': const Color(0xFFFFEBEE),
          'text': const Color(0xFFC62828),
          'border': const Color(0xFFFFCDD2),
        },
        {
          'bg': const Color(0xFFFFF8E1),
          'text': const Color(0xFFEF6C00),
          'border': const Color(0xFFFFECB3),
        },
      ];
    }
  }
}

class _IntensityRadarPainter extends CustomPainter {
  final List<_RadarIntensityData> data;
  final bool isNight;
  final double radius;
  final Color themeColor;
  final Offset center;

  _IntensityRadarPainter({
    required this.data,
    required this.isNight,
    required this.radius,
    required this.themeColor,
    required this.center,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final int n = data.length;

    // 绘制背景虚线同心圆 - 提高对比度
    final gridPaint = Paint()
      ..color = isNight
          ? Colors.white.withValues(alpha: 0.2)
          : Colors.black.withValues(alpha: 0.12)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.8;

    for (int i = 1; i <= 5; i++) {
      _drawDashedCircle(canvas, center, radius * (i / 5), gridPaint);
    }

    // 绘制轴线
    for (int i = 0; i < n; i++) {
      double angle = (2 * pi / n) * i - pi / 2;
      double px = center.dx + radius * cos(angle);
      double py = center.dy + radius * sin(angle);
      canvas.drawLine(center, Offset(px, py), gridPaint);
    }

    // 计算多边形路径与端点
    final List<Offset> points = [];
    final Path polygonPath = Path();

    for (int i = 0; i < n; i++) {
      double angle = (2 * pi / n) * i - pi / 2;
      // 核心修正：强度是 10 分制，渲染时需要归一化到 0-1 之间
      double val = (data[i].avgIntensity / 10.0).clamp(0.001, 1.0);
      double r = radius * val;
      double px = center.dx + r * cos(angle);
      double py = center.dy + r * sin(angle);

      points.add(Offset(px, py));
      if (i == 0) {
        polygonPath.moveTo(px, py);
      } else {
        polygonPath.lineTo(px, py);
      }
    }
    polygonPath.close();

    // 填充蒙版
    final fillPaint = Paint()
      ..color = themeColor.withValues(alpha: 0.35)
      ..style = PaintingStyle.fill;
    canvas.drawPath(polygonPath, fillPaint);

    // 绘制加粗描边
    final borderPaint = Paint()
      ..color = themeColor.withValues(alpha: 0.8)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0
      ..strokeCap = StrokeCap.round;
    canvas.drawPath(polygonPath, borderPaint);

    // 绘制顶点
    for (int i = 0; i < n; i++) {
      // 只有有强度的心情才画顶点，增加清晰度
      if (data[i].avgIntensity <= 0) continue;

      final dotColor = data[i].glowColor;
      final dotPaint = Paint()..color = dotColor;
      canvas.drawCircle(points[i], 3.5, dotPaint);

      // 顶点光晕
      canvas.drawCircle(
        points[i],
        8,
        Paint()
          ..color = dotColor.withValues(alpha: 0.3)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3),
      );
    }
  }

  void _drawDashedCircle(
    Canvas canvas,
    Offset center,
    double radius,
    Paint paint,
  ) {
    const double dashWidth = 2.0;
    const double dashSpace = 3.0;
    double currentAngle = 0;
    final double perimeter = 2 * pi * radius;
    // 动态计算虚线段数
    final int dashCount = max(
      12,
      (perimeter / (dashWidth + dashSpace)).floor(),
    );
    final double step = (2 * pi) / dashCount;

    for (int i = 0; i < dashCount; i++) {
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        currentAngle,
        step * (dashWidth / (dashWidth + dashSpace)),
        false,
        paint,
      );
      currentAngle += step;
    }
  }

  @override
  bool shouldRepaint(covariant _IntensityRadarPainter oldDelegate) =>
      oldDelegate.data != data ||
      oldDelegate.isNight != isNight ||
      oldDelegate.themeColor != themeColor;
}
