part of '../../pages/statistics_page.dart';

/// 情感强度数据模型
class _RadarIntensityData {
  final String label;
  final double avgIntensity; // 0.0 - 1.0
  final Color glowColor;
  final String? iconPath;
  final bool isNegative;

  _RadarIntensityData({
    required this.label,
    required this.avgIntensity,
    required this.glowColor,
    this.iconPath,
    this.isNegative = false,
  });
}

extension _BentoRadarChart on _StatisticsPageState {
  Widget _buildRadarBento(bool isNight, List<DiaryEntry> entries, Color themeColor) {
    if (entries.isEmpty) return const SizedBox.shrink();

    // 1. 数据统计与聚合 - 预设 8 个内置心情作为“基础底座”
    final Map<String, List<double>> labelToIntensities = {};
    for (var m in kMoods) {
      labelToIntensities[m.label] = [];
    }
    
    final Map<String, int> labelToMoodIndex = {};
    for (int i = 0; i < kMoods.length; i++) {
        labelToMoodIndex[kMoods[i].label] = i;
    }
    
    for (var e in entries) {
      final label = e.tag != null && e.tag!.isNotEmpty 
          ? e.tag! 
          : kMoods[e.moodIndex % kMoods.length].label;
      
      labelToIntensities.putIfAbsent(label, () => []).add(e.intensity);
      if (e.tag == null || e.tag!.isEmpty) {
         labelToMoodIndex[label] = e.moodIndex;
      }
    }

    final List<_RadarIntensityData> chartData = [];
    // 按顺序处理：先排内置 8 心情，再排自定义标签
    labelToIntensities.forEach((label, intensities) {
      final avg = intensities.isEmpty ? 0.0 : intensities.reduce((a, b) => a + b) / intensities.length;
      final mIdx = labelToMoodIndex[label];
      
      Color color;
      String? icon;
      bool negative = false;

      if (mIdx != null) {
        final mood = kMoods[mIdx % kMoods.length];
        color = mood.glowColor ?? Colors.blueAccent;
        icon = mood.iconPath;
        if ([1, 2, 5, 6].contains(mIdx % kMoods.length)) {
          negative = true;
        }
      } else {
        // 自定义标签颜色生成
        final h = (label.hashCode % 360).toDouble();
        color = HSVColor.fromAHSV(1.0, h, 0.4, 0.9).toColor();
        icon = 'assets/images/icons/tag.png'; // 自定义标签默认图标
      }

      chartData.add(_RadarIntensityData(
        label: label,
        avgIntensity: avg,
        glowColor: color,
        iconPath: icon,
        isNegative: negative,
      ));
    });

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: _buildGlassCard(
        isNight: isNight,
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildBentoHeader(
              context: context,
              title: '心境雷达',
              helpContent: '基于日记记录，从[[多个维度]]呈现您的情感偏好，助您发现潜意识中的[[情绪主导力量]]。',
              isNight: isNight,
              rightAction: Icon(CupertinoIcons.waveform_circle_fill, size: 18, color: isNight ? Colors.white54 : Colors.black.withValues(alpha: 0.26)),
            ),
            const SizedBox(height: 24),
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
                      if (_selectedRadarPointIndex != null && _selectedRadarPointIndex! < chartData.length) ...[
                        (){
                           final item = chartData[_selectedRadarPointIndex!];
                           final double angle = (2 * pi / n) * _selectedRadarPointIndex! - pi / 2;
                           final double val = (item.avgIntensity / 10.0).clamp(0.001, 1.0);
                           final double r = radius * val;
                           final double px = chartCenter.dx + r * cos(angle);
                           final double py = chartCenter.dy + r * sin(angle);
                           
                           return _buildBentoTooltip(
                             title: '心境雷达 · ${item.label}',
                             items: [
                               _BentoTooltipItem(
                                 label: '强度',
                                 value: (item.isNegative ? '-' : '') + item.avgIntensity.toStringAsFixed(1),
                                 color: item.glowColor
                               ),
                               _BentoTooltipItem(
                                 label: '特质',
                                 value: item.isNegative ? '低能阴雨' : (item.avgIntensity > 8 ? '高频滋养' : '平稳过渡'),
                               )
                             ],
                             relativeX: px / size,
                             chartWidth: size,
                             isNight: isNight,
                             top: py > graphHeight / 2 ? py - 120 : py + 20, // 根据位置动态上下偏移
                           );
                        }()
                      ],
                      // 3. 悬浮标签与图标 (原有布局)
                      ...List.generate(n, (i) {
                        double angle = (2 * pi / n) * i - pi / 2;
                        double labelR = radius + 32;
                        double lx = chartCenter.dx + labelR * cos(angle);
                        double ly = chartCenter.dy + labelR * sin(angle);
                        
                        final item = chartData[i];
                        // 新增：超过 19 个轴时切换为“纯文字模式”
                        final bool hideIcons = n > 19;
                        double fontSize = hideIcons ? 7.0 : (n > 13 ? 7.5 : (n > 10 ? 8.5 : 9.5));
                        double iconSize = n > 13 ? 18 : (n > 10 ? 21 : 25);
                        
                        final scoreStr = (item.isNegative ? '-' : '') + item.avgIntensity.toStringAsFixed(1);

                        return Positioned(
                          left: lx - 30,
                          top: ly - (hideIcons ? 15 : 28), // 纯文字模式下上移一点以居中于轴端
                          width: 60,
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (item.iconPath != null && !hideIcons)
                                Container(
                                  padding: EdgeInsets.all(n > 13 ? 4 : 5),
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: item.avgIntensity > 0 
                                        ? item.glowColor.withValues(alpha: isNight ? 0.35 : 0.25)
                                        : (isNight ? Colors.white10 : Colors.black.withValues(alpha: 0.04)),
                                    boxShadow: [
                                      if (item.avgIntensity > 0)
                                        BoxShadow(
                                          color: item.glowColor.withValues(alpha: 0.2),
                                          blurRadius: 8,
                                          spreadRadius: -2,
                                        ),
                                      if (item.avgIntensity == 0)
                                        BoxShadow(
                                          color: item.glowColor.withValues(alpha: 0.05),
                                          blurRadius: 4,
                                        ),
                                    ],
                                  ),
                                  child: Image.asset(item.iconPath!, width: iconSize, height: iconSize, 
                                    errorBuilder: (context, error, stackTrace) => const SizedBox(),
                                  ),
                                ),
                              if (!hideIcons) const SizedBox(height: 3),
                              Text(item.label, 
                                textAlign: TextAlign.center,
                                maxLines: 1, // 恢复单行显示
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: fontSize, 
                                  fontWeight: FontWeight.bold, 
                                  color: isNight ? Colors.white70 : Colors.black87,
                                  fontFamily: 'LXGWWenKai',
                                  height: 1.2,
                                )
                              ),
                              Text(scoreStr, 
                                style: TextStyle(
                                  fontSize: fontSize - 1, 
                                  color: isNight ? Colors.white30 : Colors.black26,
                                  height: 1.1,
                                )
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
          ],
        ),
      ),
    );
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
      ..color = isNight ? Colors.white.withValues(alpha: 0.2) : Colors.black.withValues(alpha: 0.12)
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
      canvas.drawCircle(points[i], 8, Paint()
        ..color = dotColor.withValues(alpha: 0.3)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3)
      );
    }
  }

  void _drawDashedCircle(Canvas canvas, Offset center, double radius, Paint paint) {
    const double dashWidth = 2.0;
    const double dashSpace = 3.0;
    double currentAngle = 0;
    final double perimeter = 2 * pi * radius;
    // 动态计算虚线段数
    final int dashCount = max(12, (perimeter / (dashWidth + dashSpace)).floor());
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
      oldDelegate.data != data || oldDelegate.isNight != isNight || oldDelegate.themeColor != themeColor;
}
