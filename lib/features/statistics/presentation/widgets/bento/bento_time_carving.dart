part of '../../pages/statistics_page.dart';

extension _BentoTimeCarving on _StatisticsPageState {
  Widget _buildTimeCarvingBento(bool isNight, List<DiaryEntry> filtered, Color themeColor) {
    final String themeId = UserState().selectedIslandThemeId.value;
    final bool isLego = themeId == 'lego';
    final bool isEmpty = filtered.isEmpty;

    // 二维数据矩阵：24小时 * 12格（5分钟一格）
    // grid[h][m] 保存该时段对应的日记（若有）
    final List<List<DiaryEntry?>> grid = List.generate(
      24,
      (_) => List.filled(12, null),
    );

    // 统计每种心情的频次
    final Map<int, int> moodCounts = {};

    // 24小时是否有记录的标记，用于计算最长无记录区间
    final List<bool> hourHasRecord = List.filled(24, false);

    for (var entry in filtered) {
      final hour = entry.dateTime.hour;
      final minute = entry.dateTime.minute;
      final mIndex = (minute / 5).floor().clamp(0, 11);

      // 同一5分钟区间若有多篇，取最新的
      if (grid[hour][mIndex] == null || entry.dateTime.isAfter(grid[hour][mIndex]!.dateTime)) {
        grid[hour][mIndex] = entry;
      }
      
      hourHasRecord[hour] = true;
      moodCounts[entry.moodIndex] = (moodCounts[entry.moodIndex] ?? 0) + 1;
    }

    // 1. 计算「最长无记录区间」
    String longestIdleRange = "00:00 - 24:00 · 24小时";
    if (!isEmpty) {
      int maxLen = 0;
      int bestStart = 0;
      
      final doubleHourHasRecord = [...hourHasRecord, ...hourHasRecord];
      int currentLen = 0;
      int currentStart = 0;
      
      for (int i = 0; i < doubleHourHasRecord.length; i++) {
        if (!doubleHourHasRecord[i]) {
          if (currentLen == 0) {
            currentStart = i;
          }
          currentLen++;
          if (currentLen > maxLen && currentLen <= 24) {
            maxLen = currentLen;
            bestStart = currentStart;
          }
        } else {
          currentLen = 0;
        }
      }
      
      if (maxLen > 0) {
        final startHour = bestStart % 24;
        final endHour = (bestStart + maxLen) % 24;
        longestIdleRange = "${startHour.toString().padLeft(2, '0')}:00 - ${endHour.toString().padLeft(2, '0')}:00 · $maxLen小时";
      } else {
        longestIdleRange = "全天均有记录";
      }
    }

    // 2. 计算「活跃小时」
    final int activeHours = hourHasRecord.where((has) => has).length;

    // 获取有记录的心情列表，并排序（按频次从高到低）
    final sortedMoods = moodCounts.keys.toList()
      ..sort((a, b) => moodCounts[b]!.compareTo(moodCounts[a]!));

    return _buildGlassCard(
      isNight: isNight,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildBentoHeader(
            context: context,
            title: '时光风铃',
            isNight: isNight,
            rightAction: Text(
              '全天记录分布',
              style: TextStyle(
                fontSize: 10,
                color: isNight ? Colors.white38 : Colors.black38,
                fontFamily: isLego ? 'SweiFistLeg' : 'LXGWWenKai',
              ),
            ),
          ),
          const SizedBox(height: 8),

          // 引导说明：帮助用户一眼理解图表含义
          Text(
            '风铃垂直线代表一天 24 小时，圆点颜色为当时心情。点击彩色露珠可查看日记。',
            style: TextStyle(
              fontSize: 11,
              color: isNight
                  ? Colors.white60
                  : (isLego ? const Color(0xFF6D5A4B) : Colors.black54),
              fontFamily: isLego ? 'SweiFistLeg' : 'LXGWWenKai',
              height: 1.4,
            ),
          ),
          const SizedBox(height: 10),

          // 时光风铃热力图主图表 (预留左侧 Y 轴提示空间)
          LayoutBuilder(
            builder: (context, constraints) {
              final containerWidth = constraints.maxWidth;
              const double containerHeight = 140.0;
              return GestureDetector(
                onTapDown: (details) {
                  const double leftLabelWidth = 28.0;
                  const double rightPadding = 8.0;
                  final double localX = details.localPosition.dx;
                  final double localY = details.localPosition.dy;

                  final double chartWidth = containerWidth - leftLabelWidth - rightPadding;
                  final double cellWidth = chartWidth / 24;
                  final double cellHeight = containerHeight / 12;

                  final int h = ((localX - leftLabelWidth) / cellWidth).floor();
                  final int m = ((containerHeight - localY) / cellHeight).floor();

                  if (h >= 0 && h < 24 && m >= 0 && m < 12) {
                    final tappedEntry = grid[h][m];
                    updateTimeCarvingEntry(tappedEntry);
                  }
                },
                child: Container(
                  height: containerHeight,
                  width: double.infinity,
                  padding: const EdgeInsets.only(right: 8),
                  child: AnimatedBuilder(
                    animation: _timeCarvingAnimController,
                    builder: (context, child) {
                      return CustomPaint(
                        painter: _TimeWindchimePainter(
                          grid: grid,
                          isNight: isNight,
                          isLego: isLego,
                          selectedEntry: _selectedTimeCarvingEntry,
                          animProgress: _timeCarvingAnimController.value,
                        ),
                      );
                    },
                  ),
                ),
              );
            },
          ),
          
          // 横轴时间刻度
          Padding(
            padding: const EdgeInsets.only(left: 28.0, right: 8.0, top: 4.0, bottom: 4.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildTimeLabel("0h", isNight),
                _buildTimeLabel("6h", isNight),
                _buildTimeLabel("12h", isNight),
                _buildTimeLabel("18h", isNight),
                _buildTimeLabel("24h", isNight),
              ],
            ),
          ),
          
          // 联动详情卡片展示
          if (_selectedTimeCarvingEntry != null) ...[
            const SizedBox(height: 12),
            GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => DiaryDetailPage(
                      entry: _selectedTimeCarvingEntry!,
                      isNight: isNight,
                    ),
                  ),
                );
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: isNight
                      ? Colors.white.withValues(alpha: 0.05)
                      : themeColor.withValues(alpha: 0.06),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isNight
                        ? Colors.white.withValues(alpha: 0.1)
                        : themeColor.withValues(alpha: 0.15),
                    width: 0.8,
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                        shape: isLego ? BoxShape.rectangle : BoxShape.circle,
                        borderRadius: isLego ? BorderRadius.circular(2.0) : null,
                        color: kMoods[_selectedTimeCarvingEntry!.moodIndex % kMoods.length].glowColor ?? Colors.amber,
                        boxShadow: [
                          BoxShadow(
                            color: (kMoods[_selectedTimeCarvingEntry!.moodIndex % kMoods.length].glowColor ?? Colors.amber).withValues(alpha: 0.4),
                            blurRadius: 4,
                          )
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '${_selectedTimeCarvingEntry!.dateTime.hour.toString().padLeft(2, '0')}:${_selectedTimeCarvingEntry!.dateTime.minute.toString().padLeft(2, '0')} · ${kMoods[_selectedTimeCarvingEntry!.moodIndex % kMoods.length].label}',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: isNight ? Colors.white : Colors.black87,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _selectedTimeCarvingEntry!.content.trim().isNotEmpty
                            ? _selectedTimeCarvingEntry!.content.trim()
                            : "写下了这一刻的心情",
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 12,
                          color: isNight ? Colors.white60 : Colors.black54,
                        ),
                      ),
                    ),
                    Icon(
                      Icons.chevron_right_rounded,
                      size: 16,
                      color: isNight ? Colors.white38 : Colors.black38,
                    ),
                  ],
                ),
              ),
            ).animate(
              key: ValueKey(_selectedTimeCarvingEntry!.dateTime),
            ).fadeIn(duration: 250.ms, curve: Curves.easeOut)
             .slideY(begin: 0.12, end: 0.0, duration: 250.ms, curve: Curves.easeOut),
          ],
          const SizedBox(height: 16),
          
          // 情绪图例展示
          if (sortedMoods.isNotEmpty) ...[
            Wrap(
              spacing: 12,
              runSpacing: 8,
              children: sortedMoods.map((moodIdx) {
                final moodItem = kMoods[moodIdx % kMoods.length];
                final count = moodCounts[moodIdx] ?? 0;
                return Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        shape: isLego ? BoxShape.rectangle : BoxShape.circle,
                        borderRadius: isLego ? BorderRadius.circular(1.6) : null,
                        color: moodItem.glowColor ?? Colors.amber,
                        boxShadow: [
                          BoxShadow(
                            color: (moodItem.glowColor ?? Colors.amber).withValues(alpha: 0.4),
                            blurRadius: 4,
                          )
                        ],
                      ),
                    ),
                    const SizedBox(width: 5),
                    Text(
                      '${moodItem.label} · $count次',
                      style: TextStyle(
                        fontSize: 11,
                        color: isNight ? Colors.white70 : Colors.black87,
                      ),
                    ),
                  ],
                );
              }).toList(),
            ),
            const SizedBox(height: 16),
          ],
          
          // 底部数据摘要
          Divider(
            height: 1,
            color: isNight ? Colors.white10 : Colors.black.withValues(alpha: 0.06),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '最长无记录区间',
                    style: TextStyle(
                      fontSize: 10,
                      color: isNight ? Colors.white38 : Colors.black45,
                      fontFamily: isLego ? 'SweiFistLeg' : 'LXGWWenKai',
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    isEmpty ? '暂无数据' : longestIdleRange,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: isNight ? Colors.white.withValues(alpha: 0.75) : Colors.black.withValues(alpha: 0.65),
                      fontFamily: isLego ? 'SweiFistLeg' : 'LXGWWenKai',
                    ),
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '活跃记录时段',
                    style: TextStyle(
                      fontSize: 10,
                      color: isNight ? Colors.white38 : Colors.black45,
                      fontFamily: isLego ? 'SweiFistLeg' : 'LXGWWenKai',
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    isEmpty ? '0 小时' : '$activeHours 小时',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: isNight ? Colors.white.withValues(alpha: 0.75) : Colors.black.withValues(alpha: 0.65),
                      fontFamily: isLego ? 'SweiFistLeg' : 'LXGWWenKai',
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTimeLabel(String text, bool isNight) {
    final String themeId = UserState().selectedIslandThemeId.value;
    final bool isLego = themeId == 'lego';
    return Text(
      text,
      style: TextStyle(
        fontSize: 9,
        fontWeight: FontWeight.w500,
        color: isNight ? Colors.white38 : Colors.black38,
        fontFamily: isLego ? 'SweiFistLeg' : 'LXGWWenKai',
      ),
    );
  }
}

/// 时光风铃 CustomPainter
class _TimeWindchimePainter extends CustomPainter {
  final List<List<DiaryEntry?>> grid;
  final bool isNight;
  final bool isLego;
  final DiaryEntry? selectedEntry;
  final double animProgress;

  _TimeWindchimePainter({
    required this.grid,
    required this.isNight,
    required this.isLego,
    this.selectedEntry,
    required this.animProgress,
  });

  @override
  void paint(Canvas canvas, Size size) {
    const double leftLabelWidth = 28.0; // 左侧预留给纵轴刻度的宽度
    final double chartWidth = size.width - leftLabelWidth;
    final double cellWidth = chartWidth / 24;
    final double cellHeight = size.height / 12;

    // 绘制左轴的分钟刻度说明 (60分、30分和00分)
    final textPainter = TextPainter(
      textDirection: TextDirection.ltr,
    );

    final labelStyle = TextStyle(
      fontSize: 8,
      fontWeight: FontWeight.w500,
      color: isNight ? Colors.white38 : Colors.black45,
    );

    // 绘制左侧刻度，并加上淡入效果
    final double scaleOpacity = animProgress.clamp(0.0, 1.0);
    final animatedLabelStyle = labelStyle.copyWith(
      color: labelStyle.color!.withValues(alpha: labelStyle.color!.a * scaleOpacity),
    );

    // 绘制 60分 刻度
    textPainter.text = TextSpan(text: "60分", style: animatedLabelStyle);
    textPainter.layout();
    textPainter.paint(canvas, Offset(2, 2));

    // 绘制 30分 刻度
    textPainter.text = TextSpan(text: "30分", style: animatedLabelStyle);
    textPainter.layout();
    textPainter.paint(canvas, Offset(2, size.height / 2 - textPainter.height / 2));

    // 绘制 00分 刻度
    textPainter.text = TextSpan(text: "00分", style: animatedLabelStyle);
    textPainter.layout();
    textPainter.paint(canvas, Offset(2, size.height - textPainter.height - 2));

    for (int h = 0; h < 24; h++) {
      // 每一列（包含风铃线和其上的气泡）采用错开（Staggered）延迟启动
      final double startOffset = h / 45.0; // 从左到右依次启动
      final double colProgress = ((animProgress - startOffset) * 2.2).clamp(0.0, 1.0);

      if (colProgress <= 0.0) continue;

      final double x = leftLabelWidth + (h + 0.5) * cellWidth;
      
      // 检查当前小时是否有记录，如果有，可以让风铃线微微亮一点
      bool hasRecordInHour = false;
      for (int m = 0; m < 12; m++) {
        if (grid[h][m] != null) {
          hasRecordInHour = true;
          break;
        }
      }

      // 绘制纵向风铃线（全长，随着列进度渐显）
      if (hasRecordInHour) {
        final activeLinePaint = Paint()
          ..color = isNight 
              ? Colors.white.withValues(alpha: 0.08 * colProgress) 
              : Colors.black.withValues(alpha: 0.06 * colProgress)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.2;
        canvas.drawLine(Offset(x, 0), Offset(x, size.height), activeLinePaint);
      } else {
        final linePaint = Paint()
          ..color = isNight 
              ? Colors.white.withValues(alpha: 0.04 * colProgress) 
              : Colors.black.withValues(alpha: 0.03 * colProgress)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.0;
        canvas.drawLine(Offset(x, 0), Offset(x, size.height), linePaint);
      }

      // 气泡飘浮与弹性弹出动画
      final double dotScale = Curves.easeOutBack.transform(colProgress);

      // 绘制气泡（露珠节点）
      for (int m = 0; m < 12; m++) {
        final entry = grid[h][m];
        final double targetY = size.height - (m + 0.5) * cellHeight;

        // 气泡从底部 (size.height) 飘浮上升到 targetY 并在途中缩放变大
        final double y = size.height - (size.height - targetY) * dotScale;

        if (entry == null) {
          // 无记录：绘制细小的灰色露珠节点
          final dotPaint = Paint()
            ..color = isNight 
                ? Colors.white.withValues(alpha: 0.12 * colProgress) 
                : Colors.black.withValues(alpha: 0.06 * colProgress)
            ..style = PaintingStyle.fill;
          _drawDot(canvas, Offset(x, y), 1.5 * dotScale, dotPaint, cornerRadius: 0.6);
        } else {
          // 有记录：绘制发光的彩色心情露珠
          final moodItem = kMoods[entry.moodIndex % kMoods.length];
          final moodColor = moodItem.glowColor ?? Colors.amber;
          final isSelected = selectedEntry == entry;

          // 1. 绘制虚影/光晕
          final glowPaint = Paint()
            ..color = moodColor.withValues(alpha: (isSelected ? 0.6 : 0.4) * colProgress)
            ..style = PaintingStyle.fill
            ..maskFilter = MaskFilter.blur(BlurStyle.normal, isSelected ? 6.0 : 4.0);
          _drawDot(canvas, Offset(x, y), (isSelected ? 8.0 : 5.5) * dotScale, glowPaint, cornerRadius: 2.2);

          // 2. 绘制彩色露珠本体
          final beadPaint = Paint()
            ..color = moodColor.withValues(alpha: 1.0 * colProgress)
            ..style = PaintingStyle.fill;
          _drawDot(canvas, Offset(x, y), (isSelected ? 5.0 : 3.8) * dotScale, beadPaint, cornerRadius: 1.5);

          // 如果被选中，加一个外圈描边或发光圈
          if (isSelected) {
            final borderPaint = Paint()
              ..color = (isNight ? Colors.white : Colors.black87).withValues(alpha: 1.0 * colProgress)
              ..style = PaintingStyle.stroke
              ..strokeWidth = 1.0;
            _drawDot(canvas, Offset(x, y), 6.5 * dotScale, borderPaint, cornerRadius: 1.8);
          }

          // 3. 绘制高光
          final highlightPaint = Paint()
            ..color = Colors.white.withValues(alpha: 0.65 * colProgress)
            ..style = PaintingStyle.fill;
          _drawDot(canvas, Offset(x - 1.0, y - 1.0), (isSelected ? 1.5 : 1.0) * dotScale, highlightPaint, cornerRadius: 0.5);
        }
      }
    }
  }

  void _drawDot(Canvas canvas, Offset center, double radius, Paint paint, {double cornerRadius = 1.0}) {
    if (isLego) {
      final rect = Rect.fromCircle(center: center, radius: radius);
      canvas.drawRRect(RRect.fromRectAndRadius(rect, Radius.circular(cornerRadius)), paint);
    } else {
      canvas.drawCircle(center, radius, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _TimeWindchimePainter oldDelegate) {
    return oldDelegate.grid != grid || 
           oldDelegate.isNight != isNight || 
           oldDelegate.isLego != isLego || 
           oldDelegate.selectedEntry != selectedEntry ||
           oldDelegate.animProgress != animProgress;
  }
}
