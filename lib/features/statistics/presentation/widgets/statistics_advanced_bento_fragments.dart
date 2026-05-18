part of '../pages/statistics_page.dart';

extension _StatisticsAdvancedBentoFragments on _StatisticsPageState {
  
  // ===================== WEEK 专属特异 =====================


  Widget _buildVolatilityIndexBento(bool isNight, List<DiaryEntry> filtered, Color themeColor) {
    if (filtered.length < 2) return const SizedBox.shrink();

    List<DiaryEntry> sorted = List.from(filtered)..sort((a,b)=>a.dateTime.compareTo(b.dateTime));
    double totalDiff = 0;
    for(int i=1; i<sorted.length; i++){
       totalDiff += (sorted[i].intensity - sorted[i-1].intensity).abs();
    }
    double volatility = totalDiff / (sorted.length - 1);

    String desc = "如幽谷止水，内心平稳不惊";
    if (volatility > 0.4) {
      desc = "大起大落，近期情绪像过山车";
    } else if (volatility > 0.2) {
      desc = "略有波折，感受到一定的内在推拉";
    }

    return _buildGlassCard(
       isNight: isNight,
       padding: const EdgeInsets.all(16),
       child: Column(
         crossAxisAlignment: CrossAxisAlignment.start,
         children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                 Text('潮汐节律', style: _bentoTitleStyle(isNight)),
                 Icon(CupertinoIcons.heart_circle, size: 18, color: volatility > 0.4 ? Colors.redAccent : themeColor.withValues(alpha: isNight ? 0.7 : 0.5)),
              ]
            ),
            Text('情绪起伏的潮汐位', style: TextStyle(fontSize: 10, color: isNight ? Colors.white38 : Colors.black38)),
            const SizedBox(height: 12),
            Text((volatility * 10).toStringAsFixed(1), style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: isNight ? Colors.white : Colors.black87)),
            const SizedBox(height: 4),
            Text(desc, style: TextStyle(fontSize: 13, color: isNight ? Colors.white70 : Colors.black54)),
         ]
       )
    );
  }

  // ===================== MONTH 专属特异 =====================

  Widget _buildMonthlyHighlightsBento(bool isNight, List<DiaryEntry> filtered, Color themeColor) {
    if (filtered.length < 2) return const SizedBox.shrink();
    final bool isCottonCandy = UserState().selectedIslandThemeId.value == 'cotton_candy';
    final Color accentColor = isCottonCandy ? const Color(0xFFF7AAB6) : themeColor;
    final Color cottonCandySurface = const Color(0xFFFFF4EF);

    DiaryEntry maxEntry = filtered.first;
    DiaryEntry minEntry = filtered.first;

    for (var e in filtered) {
       if (e.intensity > maxEntry.intensity) {
         maxEntry = e;
       }
       if (e.intensity < minEntry.intensity) {
         minEntry = e;
       }
    }

    final String summaryText =
        '这段时间里，最高点在 ${DateFormat('MM/dd').format(maxEntry.dateTime)}，最低点在 ${DateFormat('MM/dd').format(minEntry.dateTime)}。';

    return _buildGlassCard(
       isNight: isNight,
       backgroundColor: isCottonCandy ? cottonCandySurface : null,
       padding: const EdgeInsets.all(16),
       child: Column(
         crossAxisAlignment: CrossAxisAlignment.start,
         children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                 Text('情绪高低点', style: _bentoTitleStyle(isNight)),
                 Icon(
                   CupertinoIcons.bookmark_fill,
                   size: 18,
                   color: accentColor.withValues(alpha: isNight ? 0.72 : 0.45),
                 ),
              ]
            ),
            const SizedBox(height: 6),
            Text(
              summaryText,
              style: TextStyle(
                fontSize: 12,
                height: 1.35,
                color: isNight ? Colors.white60 : const Color(0xFF8A7462),
                fontFamily: 'LXGWWenKai',
              ),
            ),
            const SizedBox(height: 12),
            _buildHighlightQuote(isNight, maxEntry, '最高点', Colors.orange),
            const SizedBox(height: 10),
            _buildHighlightQuote(isNight, minEntry, '最低点', themeColor),
          ]
       )
    );
  }

  Widget _buildHighlightQuote(bool isNight, DiaryEntry entry, String label, Color accentColor) {
    String content = entry.content.replaceAll('\n', ' ');
    if (content.length > 34) {
      content = '${content.substring(0, 34)}...';
    }

    return Container(
       decoration: BoxDecoration(
         border: Border(
           left: BorderSide(color: accentColor.withValues(alpha: 0.9), width: 2.5),
         ),
         color: isNight
             ? Colors.white10
             : accentColor.withValues(alpha: 0.08),
         borderRadius: BorderRadius.circular(12),
       ),
       padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
       child: Column(
         crossAxisAlignment: CrossAxisAlignment.start,
         children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                 Text(label, style: TextStyle(fontSize: 10, color: accentColor, fontWeight: FontWeight.bold)),
                 Text(DateFormat('MM/dd').format(entry.dateTime), style: TextStyle(fontSize: 10, color: isNight ? Colors.white38 : Colors.black38)),
              ]
            ),
            const SizedBox(height: 6),
            Text(
              '"$content"',
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 12.5,
                height: 1.35,
                color: isNight ? Colors.white70 : Colors.black87,
              ),
            ),
         ]
       )
    );
  }

  // ===================== ALL 专属特异 =====================


  Widget _buildSeasonalityTrendBento(bool isNight, List<DiaryEntry> allEntries, Color themeColor) {
    if (allEntries.length < 5) {
      return const SizedBox.shrink();
    }

    List<double> quarters = [0,0,0,0];
    List<int> quarterCounts = [0,0,0,0];

    for (var e in allEntries) {
      int m = e.dateTime.month;
      int q = (m - 1) ~/ 3; // 0 for Jan-Mar, 1 for Apr-Jun...
      quarters[q] += e.intensity;
      quarterCounts[q]++;
    }

    List<Map<String, dynamic>> data = [];
    double maxAvg = 0;
    for (int i=0; i<4; i++) {
       double avg = quarterCounts[i] > 0 ? (quarters[i] / quarterCounts[i]) : 0;
       if (avg > maxAvg) {
         maxAvg = avg;
       }
       data.add({'label': 'Q${i+1}', 'val': avg});
    }

    if (maxAvg == 0) {
      return const SizedBox.shrink();
    }

    return _buildGlassCard(
      isNight: isNight,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
           Text('四季脉动', style: _bentoTitleStyle(isNight)),
           Text('生命长周期的波动', style: TextStyle(fontSize: 10, color: isNight ? Colors.white38 : Colors.black38)),
           const SizedBox(height: 16),
           Row(
             mainAxisAlignment: MainAxisAlignment.spaceAround,
             crossAxisAlignment: CrossAxisAlignment.end,
             children: data.map((e) {
               double val = e['val'] as double;
               double h = maxAvg > 0 ? (val / maxAvg) * 60 : 0; // 归一化并设置最大高度为 60
               return Column(
                 mainAxisSize: MainAxisSize.min,
                 children: [
                    Container(
                      width: 20, 
                      height: 10 + h, 
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                           begin: Alignment.bottomCenter, end: Alignment.topCenter,
                           colors: [
                             isNight ? themeColor.withValues(alpha: 0.3) : themeColor.withValues(alpha: 0.5), 
                             isNight ? themeColor.withValues(alpha: 0.1) : themeColor.withValues(alpha: 0.1)
                           ]
                        ), 
                        borderRadius: BorderRadius.circular(6)
                      )
                    ),
                    const SizedBox(height: 8),
                    Text(e['label'], style: TextStyle(fontSize: 10, color: isNight ? Colors.white54 : Colors.black54)),
                 ]
               );
             }).toList()
           )
        ]
      )
    );
  }
}
