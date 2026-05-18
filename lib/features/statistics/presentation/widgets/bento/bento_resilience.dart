part of '../../pages/statistics_page.dart';

extension _BentoResilience on _StatisticsPageState {
  Widget _buildResilienceBento(bool isNight, List<DiaryEntry> entries, Color themeColor) {
    if (entries.isEmpty) return const SizedBox.shrink();

    // --- 1. 数据算法：统计从低落到平静/正向的回升 ---
    final sorted = List<DiaryEntry>.from(entries)..sort((a, b) => a.dateTime.compareTo(b.dateTime));
    
    int recoveryCount = 0;
    List<Duration> recoveryDurations = [];
    
    DateTime? negativeStart;
    
    // 负向情绪索引：1(厌恶), 2(恐惧), 5(愤怒), 6(悲伤)
    final negativeIndices = [1, 2, 5, 6];

    for (var entry in sorted) {
      final isNeg = negativeIndices.contains(entry.moodIndex % kMoods.length);
      
      if (isNeg) {
        negativeStart ??= entry.dateTime;
      } else {
        if (negativeStart != null) {
          // 成功从负向情绪回到平静或正向情绪
          final duration = entry.dateTime.difference(negativeStart);
          // 只有在合理范围内（如 7 天内）的恢复才算作一次有效回升，防止跨度太大的数据干扰
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

    final bool isCottonCandy = UserState().selectedIslandThemeId.value == 'cotton_candy';
    final Color accentColor = isCottonCandy ? const Color(0xFFF7AAB6) : themeColor;
    final Color primaryTextColor = isCottonCandy
        ? const Color(0xFFE98FA4)
        : (isNight ? Colors.white : Colors.black87);
    final Color metricTextColor = isCottonCandy
        ? const Color(0xFFD9859A)
        : (isNight ? accentColor.withValues(alpha: 0.9) : accentColor.withValues(alpha: 0.82));
    final Color secondaryTextColor = isCottonCandy
        ? const Color(0xFF9A7A69)
        : (isNight ? Colors.white60 : Colors.black54);

    // --- 2. UI 渲染 ---
    return _buildGlassCard(
      isNight: isNight,
      backgroundColor: isCottonCandy ? const Color(0xFFFFF4EF) : null,
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildBentoHeader(
            context: context,
            title: '情绪恢复',
            helpContent: '统计你从低落情绪回到平静或开心，大约用了多久。它不是评价好坏，只是帮你看见自己的[[恢复节奏]]。',
            isNight: isNight,
            rightAction: Icon(
              CupertinoIcons.heart_circle,
              size: 18,
              color: accentColor.withValues(alpha: isNight ? 0.72 : 0.8),
            ),
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
                  color: primaryTextColor,
                  fontFamily: 'LXGWWenKai',
                ),
              ),
              const SizedBox(width: 8),
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Text(
                  '次回升',
                  style: TextStyle(
                    fontSize: 14,
                    color: secondaryTextColor,
                    fontFamily: 'LXGWWenKai',
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
                      color: metricTextColor,
                      fontFamily: 'LXGWWenKai',
                    ),
                  ),
                  Text(
                    '平均恢复用时',
                    style: TextStyle(
                      fontSize: 12,
                      color: secondaryTextColor.withValues(alpha: 0.75),
                      fontFamily: 'LXGWWenKai',
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
              color: isCottonCandy
                  ? const Color(0xFFFFE8E2).withValues(alpha: 0.7)
                  : (isNight ? Colors.white : Colors.black).withValues(alpha: 0.03),
              borderRadius: BorderRadius.circular(12),
              border: isCottonCandy
                  ? Border.all(color: const Color(0xFFF6D8D0).withValues(alpha: 0.65))
                  : null,
            ),
            child: _buildHighlightedText(
              context,
              avgHours > 0
                  ? '从低落回到平静或开心，平均大约需要 [[${avgHours.toStringAsFixed(1)} 小时]]。'
                  : '继续记录后，这里会显示你从低落回到平静或开心的 [[平均用时]]。',
              isNight,
            ),
          ),
        ],
      ),
    );
  }
}
