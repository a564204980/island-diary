part of '../pages/statistics_page.dart';

extension StatisticsAdvancedBentoFragments on _StatisticsPageState {
  
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
    if (volatility > 0.4) desc = "大起大落，近期情绪像过山车";
    else if (volatility > 0.2) desc = "略有波折，感受到一定的内在推拉";

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
                 Icon(CupertinoIcons.heart_circle, size: 18, color: volatility > 0.4 ? Colors.redAccent : themeColor.withOpacity(isNight ? 0.7 : 0.5)),
              ]
            ),
            Text('情绪起伏的潮汐位', style: TextStyle(fontSize: 10, color: isNight ? Colors.white38 : Colors.black38)),
            const SizedBox(height: 12),
            Text('${(volatility * 10).toStringAsFixed(1)}', style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: isNight ? Colors.white : Colors.black87)),
            const SizedBox(height: 4),
            Text(desc, style: TextStyle(fontSize: 13, color: isNight ? Colors.white70 : Colors.black54)),
         ]
       )
    );
  }

  // ===================== MONTH 专属特异 =====================

  Widget _buildMonthlyHighlightsBento(bool isNight, List<DiaryEntry> filtered, Color themeColor) {
    if (filtered.length < 2) return const SizedBox.shrink();

    DiaryEntry maxEntry = filtered.first;
    DiaryEntry minEntry = filtered.first;

    for (var e in filtered) {
       if (e.intensity > maxEntry.intensity) maxEntry = e;
       if (e.intensity < minEntry.intensity) minEntry = e;
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
                 Text('时光刻痕', style: _bentoTitleStyle(isNight)),
                 Icon(CupertinoIcons.bookmark_fill, size: 18, color: themeColor.withOpacity(isNight ? 0.6 : 0.4)),
              ]
            ),
            const SizedBox(height: 16),
            _buildHighlightQuote(isNight, maxEntry, '极度高昂', Colors.orange),
            const SizedBox(height: 12),
            _buildHighlightQuote(isNight, minEntry, '情绪至暗', themeColor),
         ]
       )
    );
  }

  Widget _buildHighlightQuote(bool isNight, DiaryEntry entry, String label, Color accentColor) {
    String content = entry.content.replaceAll('\n', ' ');
    if (content.length > 40) content = '${content.substring(0, 40)}...';
    
    return Container(
       decoration: BoxDecoration(
         border: Border(left: BorderSide(color: accentColor, width: 3)),
         color: isNight ? Colors.white10 : Colors.black.withOpacity(0.04),
       ),
       padding: const EdgeInsets.all(12),
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
            Text('"$content"', style: TextStyle(fontSize: 13, fontStyle: FontStyle.italic, color: isNight ? Colors.white70 : Colors.black87)),
         ]
       )
    );
  }

  Widget _buildTrendExtrapolationBento(bool isNight, List<DiaryEntry> filtered, Color themeColor) {
     if (filtered.length < 4) return const SizedBox.shrink();
     
     final sorted = List.from(filtered)..sort((a,b)=>a.dateTime.compareTo(b.dateTime));
     int mid = sorted.length ~/ 2;
     double firstHalf = sorted.sublist(0, mid).fold(0.0, (sum, e) => sum + e.intensity) / mid;
     double secondHalf = sorted.sublist(mid).fold(0.0, (sum, e) => sum + e.intensity) / (sorted.length - mid);
     
     double diff = secondHalf - firstHalf;
     bool isUp = diff >= 0;

     return _buildGlassCard(
       isNight: isNight,
       padding: const EdgeInsets.all(16),
       child: Row(
         mainAxisAlignment: MainAxisAlignment.spaceBetween,
         children: [
           Column(
             crossAxisAlignment: CrossAxisAlignment.start,
             children: [
                Text('近期水位', style: _bentoTitleStyle(isNight)),
                const SizedBox(height: 8),
                Text(isUp ? '状态正在回暖' : '近期略显疲惫', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: isNight ? Colors.white : Colors.black87)),
             ]
           ),
           Container(
             padding: const EdgeInsets.all(12),
             decoration: BoxDecoration(shape: BoxShape.circle, color: isUp ? Colors.green.withOpacity(0.2) : themeColor.withOpacity(0.2)),
             child: Icon(isUp ? CupertinoIcons.arrow_up_right : CupertinoIcons.arrow_down_right, color: isUp ? Colors.green : themeColor),
           )
         ]
       )
     );
  }

  // ===================== ALL 专属特异 =====================


  Widget _buildSeasonalityTrendBento(bool isNight, List<DiaryEntry> allEntries, Color themeColor) {
    if (allEntries.length < 5) return const SizedBox.shrink();

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
       if (avg > maxAvg) maxAvg = avg;
       data.add({'label': 'Q${i+1}', 'val': avg});
    }

    if (maxAvg == 0) return const SizedBox.shrink();

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
                             isNight ? themeColor.withOpacity(0.3) : themeColor.withOpacity(0.5), 
                             isNight ? themeColor.withOpacity(0.1) : themeColor.withOpacity(0.1)
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
