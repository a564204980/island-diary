part of '../../pages/statistics_page.dart';

extension BentoResilience on _StatisticsPageState {
  Widget _buildResilienceBento(bool isNight, List<DiaryEntry> entries, Color themeColor) {
    if (entries.isEmpty) return const SizedBox.shrink();

    // --- 1. 数据算法：统计自愈跳变 ---
    final sorted = List<DiaryEntry>.from(entries)..sort((a, b) => a.dateTime.compareTo(b.dateTime));
    
    int recoveryCount = 0;
    List<Duration> recoveryDurations = [];
    
    DateTime? negativeStart;
    
    // 负向情绪索引：1(厌恶), 2(恐惧), 5(愤怒), 6(悲伤)
    final negativeIndices = [1, 2, 5, 6];

    for (var entry in sorted) {
      final isNeg = negativeIndices.contains(entry.moodIndex % kMoods.length);
      
      if (isNeg) {
        if (negativeStart == null) {
          negativeStart = entry.dateTime;
        }
      } else {
        if (negativeStart != null) {
          // 成功从负向转晴
          final duration = entry.dateTime.difference(negativeStart);
          // 只有在合理范围内（如 7 天内）的恢复才算作一次有效的“自愈回响”，防止跨度太大的数据干扰
          if (duration.inHours < 24 * 7) {
            recoveryCount++;
            recoveryDurations.add(duration);
          }
          negativeStart = null;
        }
      }
    }

    double avgHours = 0;
    if (recoveryDurations.isNotEmpty) {
      final totalMinutes = recoveryDurations.fold<int>(0, (prev, element) => prev + element.inMinutes);
      avgHours = totalMinutes / recoveryDurations.length / 60.0;
    }

    // --- 2. UI 渲染 ---
    return _buildGlassCard(
      isNight: isNight,
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 20),
      child: Stack(
        children: [
          // 背景装饰：渐变丝带
          Positioned.fill(
            child: Opacity(
              opacity: isNight ? 0.3 : 0.5,
              child: CustomPaint(
                painter: _ResilienceRibbonPainter(
                  isNight: isNight,
                  recoveryProgress: recoveryCount > 0 ? 1.0 : 0.0,
                ),
              ),
            ),
          ),
          
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildBentoHeader(
                context: context,
                title: '心灵回响',
                helpContent: '[[心灵回响]] 见证了您内在的修复力量。它统计了您从 [[低谷状态]] 重新找回 [[平静与喜悦]] 的过程。每一次的回响，都是您灵魂韧性的成就。',
                isNight: isNight,
              ),
              const SizedBox(height: 20),
              
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    recoveryCount.toString(),
                    style: TextStyle(
                      fontSize: 42,
                      fontWeight: FontWeight.bold,
                      color: isNight ? Colors.white : Colors.black87,
                      fontFamily: 'LXGWWenKai',
                    ),
                  ),
                  const SizedBox(width: 8),
                  Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Text(
                      '次自愈',
                      style: TextStyle(
                        fontSize: 14,
                        color: isNight ? Colors.white60 : Colors.black54,
                      ),
                    ),
                  ),
                  const Spacer(),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        avgHours > 0 ? avgHours.toStringAsFixed(1) : '--',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: themeColor.withOpacity(0.9),
                        ),
                      ),
                      Text(
                        '平均小时转晴',
                        style: TextStyle(
                          fontSize: 12,
                          color: isNight ? Colors.white38 : Colors.black38,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              
              const SizedBox(height: 24),
              
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: (isNight ? Colors.white : Colors.black).withOpacity(0.03),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: _buildHighlightedText(
                  context,
                  avgHours > 0 
                    ? '每次乌云过后，阳光平均会在 [[${avgHours.toStringAsFixed(1)} 小时]] 后重新回归您的岛屿。'
                    : '每一场雨季都是为了更好的放晴，继续记录您的 [[自愈时刻]]。',
                  isNight,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// 绘制一条象征自愈的渐变丝带
class _ResilienceRibbonPainter extends CustomPainter {
  final bool isNight;
  final double recoveryProgress;

  _ResilienceRibbonPainter({required this.isNight, required this.recoveryProgress});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 30
      ..strokeCap = StrokeCap.round;

    final path = Path();
    
    // 起点：左下角偏上（代表低谷开始）
    path.moveTo(size.width * 0.1, size.height * 0.8);
    
    // 贝塞尔曲线模拟向上的旋回感
    path.cubicTo(
      size.width * 0.4, size.height * 0.9,  // 控制点1
      size.width * 0.6, size.height * 0.2,  // 控制点2
      size.width * 0.9, size.height * 0.3   // 终点：右上角（代表阳光回归）
    );

    // 渐变色：从冷色到暖色
    final gradient = LinearGradient(
      colors: [
        isNight ? const Color(0xFF3949AB) : const Color(0xFF5C6BC0), // 靛蓝
        isNight ? const Color(0xFFBA68C8) : const Color(0xFFCE93D8), // 紫罗兰
        isNight ? const Color(0xFFFFF176) : const Color(0xFFFFEB3B), // 明黄
        isNight ? const Color(0xFFFFB74D) : const Color(0xFFFFCC80), // 橘橙
      ],
      stops: const [0.0, 0.4, 0.8, 1.0],
    );

    paint.shader = gradient.createShader(Offset.zero & size);
    
    // 使用模糊滤镜增加丝绸朦胧感
    paint.maskFilter = const MaskFilter.blur(BlurStyle.normal, 20);

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _ResilienceRibbonPainter oldDelegate) => isNight != oldDelegate.isNight;
}
