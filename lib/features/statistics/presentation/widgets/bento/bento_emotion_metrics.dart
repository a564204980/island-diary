part of '../../pages/statistics_page.dart';

extension _BentoEmotionMetrics on _StatisticsPageState {
  Widget _buildStatsBentoList(bool isNight, List<DiaryEntry> allEntries, Color themeColor) {
    final bool isCottonCandy = UserState().selectedIslandThemeId.value == 'cotton_candy';
    int streak = 0;
    int totalWords = 0;

    if (allEntries.isNotEmpty) {
      for (var d in allEntries) {
        totalWords += d.content.length;
      }
      
      final sortedDates = allEntries.map((e) => DateTime(e.dateTime.year, e.dateTime.month, e.dateTime.day)).toSet().toList();
      sortedDates.sort((a, b) => b.compareTo(a));
      
      final today = DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day);
      DateTime current = sortedDates.first == today ? today : sortedDates.first;
      
      for (int i = 0; i < sortedDates.length; i++) {
        if (sortedDates[i] == current) {
          streak++;
          current = current.subtract(const Duration(days: 1));
        } else {
          break;
        }
      }
    }

    return Row(
      children: [
        Expanded(
          child: _buildSmallBentoCore(
            isNight,
            isCottonCandy,
            '连记',
            '$streak',
            '天',
            CupertinoIcons.flame_fill,
            '连续记录',
            themeColor,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildSmallBentoCore(
            isNight,
            isCottonCandy,
            '字数',
            '${totalWords > 999 ? '${(totalWords / 1000).toStringAsFixed(1)}k' : totalWords}',
            '字',
            CupertinoIcons.doc_text_fill,
            '累计写下',
            themeColor,
          ),
        ),
      ],
    );
  }

  Widget _buildSmallBentoCore(
    bool isNight,
    bool isCottonCandy,
    String title,
    String value,
    String unit,
    IconData icon,
    String hint,
    Color themeColor,
  ) {
    return _buildGlassCard(
      isNight: isNight,
      backgroundColor: isCottonCandy ? const Color(0xFFFFF4EF) : null,
      padding: const EdgeInsets.all(10),
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 72),
        child: SizedBox(
          width: double.infinity,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: _bentoTitleStyle(isNight).copyWith(
                      fontFamily: 'LXGWWenKai',
                    ),
                  ),
                  Icon(
                    icon,
                    size: 13,
                    color: isNight
                        ? Colors.white38
                        : (isCottonCandy ? const Color(0xFFF2B9BF) : themeColor.withValues(alpha: 0.28)),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Row(
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Text(
                    value,
                    style: TextStyle(
                      fontSize: isCottonCandy ? 19 : 21,
                      fontWeight: FontWeight.w900,
                      color: isNight
                          ? Colors.white
                          : (isCottonCandy ? const Color(0xFF7A5C4E) : const Color(0xFF5A3E28)),
                      fontFamily: 'LXGWWenKai',
                    ),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    unit,
                    style: TextStyle(
                      fontSize: 10,
                      color: isNight ? Colors.white54 : const Color(0xFF8E7768),
                      fontFamily: 'LXGWWenKai',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 3),
              Text(
                hint,
                style: TextStyle(
                  fontSize: 12,
                  color: isNight
                      ? Colors.white54
                      : (isCottonCandy ? const Color(0xFF9E8474) : const Color(0xFF6D5A4B)),
                  fontFamily: 'LXGWWenKai',
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMoodProgressBarBento(bool isNight, List<DiaryEntry> filtered, Color themeColor) {
    final bool isCottonCandy = UserState().selectedIslandThemeId.value == 'cotton_candy';

    if (filtered.isEmpty) {
       return _buildGlassCard(
        isNight: isNight,
        backgroundColor: isCottonCandy ? const Color(0xFFFFF4EF) : null,
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildBentoHeader(
              context: context,
              title: '情绪成分',
              helpContent: '量化展示这段时间里，各种情绪分别出现了多少。你可以直接看到哪种情绪更常见。',
              isNight: isNight,
            ),
            const SizedBox(height: 16),
            Container(
              height: 20,
              decoration: BoxDecoration(
                color: themeColor.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: themeColor.withValues(alpha: 0.04)),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              '暂无数据',
              style: TextStyle(
                color: isNight ? Colors.white38 : Colors.black38,
                fontSize: 12,
                fontFamily: 'LXGWWenKai',
              ),
            ),
          ],
        )
      );
    }

    final unifiedData = _getUnifiedEmotionData(filtered);
    final int total = filtered.length;
    final visibleData = unifiedData.where((data) => data.count > 0).toList();
    final topItem = visibleData.isEmpty
        ? null
        : visibleData.reduce((a, b) => a.count >= b.count ? a : b);
    final summaryText = topItem == null
        ? '最近的情绪分布还比较平均。'
        : '最近出现最多的是 ${topItem.label}，占 ${((topItem.count / total) * 100).toStringAsFixed(0)}%。';

    List<Widget> barSegments = [];
    List<Widget> legendChips = [];

    for (int i = 0; i < visibleData.length; i++) {
        final data = visibleData[i];
        final flex = (data.count / total * 100).toInt().clamp(1, 100);

        barSegments.add(Expanded(
          flex: flex,
          child: GestureDetector(
            onTap: () {
              if (data.originalMoodIndex != null) {
                _showMoodDetailSheet(context, data.originalMoodIndex!, filtered, isNight);
              }
            },
            child: Container(
              height: 20,
              decoration: BoxDecoration(
                color: data.color,
                borderRadius: BorderRadius.horizontal(
                  left: i == 0 ? const Radius.circular(12) : Radius.zero,
                  right: i == visibleData.length - 1 ? const Radius.circular(12) : Radius.zero,
                ),
              ),
            ),
          ),
        ));
        
        legendChips.add(
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: isNight
                  ? data.color.withValues(alpha: 0.16)
                  : data.color.withValues(alpha: isCottonCandy ? 0.12 : 0.14),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: data.color.withValues(alpha: isNight ? 0.22 : 0.2),
                width: 0.7,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 7,
                  height: 7,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: data.color,
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  data.label,
                  style: TextStyle(
                    fontSize: 11.5,
                    color: isNight
                        ? Colors.white70
                        : (isCottonCandy ? const Color(0xFF6F574A) : Colors.black87),
                    fontFamily: 'LXGWWenKai',
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  '${((data.count / total) * 100).toStringAsFixed(0)}%',
                  style: TextStyle(
                    fontSize: 10.5,
                    color: isNight
                        ? Colors.white54
                        : (isCottonCandy ? const Color(0xFF8F7464) : Colors.black45),
                    fontFamily: 'LXGWWenKai',
                  ),
                ),
              ],
            ),
          ),
        );
    }

    return _buildGlassCard(
      isNight: isNight,
      backgroundColor: isCottonCandy ? const Color(0xFFFFF4EF) : null,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildBentoHeader(
            context: context,
            title: '情绪成分',
            helpContent: '量化展示这段时间里，各种情绪分别出现了多少。你可以直接看到哪种情绪更常见。',
            isNight: isNight,
          ),
          const SizedBox(height: 8),
          Text(
            summaryText,
            style: TextStyle(
              fontSize: 12,
              height: 1.3,
              color: isNight
                  ? Colors.white60
                  : (isCottonCandy ? const Color(0xFF8F7464) : const Color(0xFF6D5A4B)),
              fontFamily: 'LXGWWenKai',
            ),
          ),
          const SizedBox(height: 14),
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Row(children: barSegments),
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: legendChips,
          ),
        ],
      )
    );
  }
}
