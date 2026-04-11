part of '../../pages/statistics_page.dart';

extension BentoEmotionMetrics on _StatisticsPageState {
  Widget _buildStatsBentoList(bool isNight, List<DiaryEntry> allEntries, Color themeColor) {
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

    return Column(
      children: [
        Expanded(child: _buildSmallBentoCore(isNight, '🔥 连记', '$streak', '天', themeColor)),
        const SizedBox(height: 16),
        Expanded(child: _buildSmallBentoCore(isNight, '📝 字数', '${totalWords > 999 ? '${(totalWords/1000).toStringAsFixed(1)}k' : totalWords}', '字', themeColor)),
      ],
    );
  }

  Widget _buildSmallBentoCore(bool isNight, String title, String value, String unit, Color themeColor) {
    return _buildGlassCard(
      isNight: isNight,
      padding: const EdgeInsets.all(16),
      child: SizedBox(
        width: double.infinity,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(title, style: TextStyle(
              fontSize: 12, 
              fontWeight: FontWeight.bold, 
              color: themeColor.withOpacity(isNight ? 0.7 : 0.6)
            )),
            const SizedBox(height: 12),
            Row(
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Text(value, style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: isNight ? Colors.white : const Color(0xFF5A3E28))),
                const SizedBox(width: 4),
                Text(unit, style: TextStyle(fontSize: 12, color: isNight ? Colors.white54 : Colors.black45)),
              ],
            )
          ],
        ),
      ),
    );
  }

  Widget _buildMoodProgressBarBento(bool isNight, List<DiaryEntry> filtered, Color themeColor) {
    if (filtered.isEmpty) {
       return _buildGlassCard(
        isNight: isNight,
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildBentoHeader(
              context: context,
              title: '情绪成分',
              helpContent: '量化展示各项情绪在您心灵中的占比，帮助您清晰识别当前的情感季节，看清内心底色的演变。',
              isNight: isNight,
            ),
            const SizedBox(height: 16),
            Container(height: 24, decoration: BoxDecoration(
              color: themeColor.withOpacity(0.1), 
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: themeColor.withOpacity(0.05))
            )),
            const SizedBox(height: 16),
            Text('暂无数据', style: TextStyle(color: isNight ? Colors.white38 : Colors.black38, fontSize: 12)),
          ],
        )
      );
    }

    final unifiedData = _getUnifiedEmotionData(filtered);
    int total = filtered.length;
    List<Widget> barSegments = [];
    List<Widget> legendItems = [];

    for (int i = 0; i < unifiedData.length; i++) {
        var data = unifiedData[i];
        final flex = (data.count / total * 100).toInt();
        if (flex == 0) continue;

        barSegments.add(Expanded(
          flex: flex,
          child: GestureDetector(
            onTap: () {
              if (data.originalMoodIndex != null) {
                _showMoodDetailSheet(context, data.originalMoodIndex!, filtered, isNight);
              }
            },
            child: Container(
              height: 24,
              decoration: BoxDecoration(
                color: data.color,
                borderRadius: BorderRadius.horizontal(
                  left: i == 0 ? const Radius.circular(12) : Radius.zero,
                  right: i == unifiedData.length - 1 ? const Radius.circular(12) : Radius.zero,
                ),
                border: Border.all(color: isNight ? Colors.black12 : Colors.white54, width: 0.5),
              ),
            ),
          ),
        ));
        
        // Legend
        legendItems.add(Padding(
          padding: const EdgeInsets.only(bottom: 8.0),
          child: Row(
            children: [
              Container(width: 8, height: 8, decoration: BoxDecoration(shape: BoxShape.circle, color: data.color)),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  '${data.label} ${(data.count / total * 100).toStringAsFixed(0)}%', 
                  style: TextStyle(
                    fontSize: 12, 
                    color: isNight ? Colors.white70 : Colors.black87,
                    fontFamily: 'LXGWWenKai',
                  ),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
              ),
            ],
          ),
        ));
    }

    return _buildGlassCard(
      isNight: isNight,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildBentoHeader(
            context: context,
            title: '情绪成分',
            helpContent: '量化展示各项情绪在您心灵中的占比，帮助您清晰识别当前的情感季节，看清[[内心底色]]的演变。',
            isNight: isNight,
          ),
          const SizedBox(height: 16),
          ClipRRect(borderRadius: BorderRadius.circular(12), child: Row(children: barSegments)),
          const SizedBox(height: 16),
          if (legendItems.isNotEmpty)
            SizedBox(
              height: 110,
              child: CupertinoScrollbar(
                child: ListView(
                  padding: EdgeInsets.zero,
                  physics: const BouncingScrollPhysics(),
                  children: legendItems,
                ),
              ),
            )
          else 
            Text('暂无数据', style: TextStyle(color: isNight ? Colors.white38 : Colors.black38, fontSize: 12)),
        ],
      )
    );
  }
}
