part of '../../pages/statistics_page.dart';

extension BentoMoodCalendar on _StatisticsPageState {
  Widget _buildMoodCalendarBento(bool isNight, List<DiaryEntry> allEntries) {
    final now = DateTime.now();
    // 构建本月每一天的数据映射
    Map<int, DiaryEntry> daysMap = {};
    for (var e in allEntries) {
      if (e.dateTime.year == now.year && e.dateTime.month == now.month) {
        // 如果同一天有多篇，保留后写的那篇（也就是最新状态）
        if (!daysMap.containsKey(e.dateTime.day) || daysMap[e.dateTime.day]!.dateTime.isBefore(e.dateTime)) {
            daysMap[e.dateTime.day] = e;
        }
      }
    }

    final int daysInMonth = DateUtils.getDaysInMonth(now.year, now.month);
    final int firstWeekday = DateTime(now.year, now.month, 1).weekday; // 1=Mon, 7=Sun

    return _buildGlassCard(
      isNight: isNight,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('${now.month}月心情墙', style: _bentoTitleStyle(isNight)),
              Icon(CupertinoIcons.calendar, size: 18, color: isNight ? Colors.white54 : Colors.black38),
            ],
          ),
          const SizedBox(height: 12),
          // 星期表头
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: ['一', '二', '三', '四', '五', '六', '日'].map((day) {
              return Text(day, style: TextStyle(fontSize: 12, color: isNight ? Colors.white38 : Colors.black38, fontWeight: FontWeight.bold));
            }).toList(),
          ),
          const SizedBox(height: 8),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 7, 
              childAspectRatio: 1,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
            ),
            itemCount: daysInMonth + firstWeekday - 1,
            itemBuilder: (context, index) {
              if (index < firstWeekday - 1) return const SizedBox.shrink(); // 空白占位
              final day = index - (firstWeekday - 1) + 1;
              final entry = daysMap[day];

              return GestureDetector(
                onTap: () {
                  if (entry != null) {
                    // 已有日记
                  } else {
                    final targetDate = DateTime(now.year, now.month, day);
                    if (targetDate.isBefore(DateTime.now())) {
                       _handleBackfill(context, targetDate, isNight);
                    }
                  }
                },
                child: Container(
                  decoration: BoxDecoration(
                    color: isNight ? Colors.white10 : Colors.black.withOpacity(0.04),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: entry != null && !isNight ? [
                       BoxShadow(color: (kMoods[entry.moodIndex % kMoods.length].glowColor ?? Colors.yellow).withOpacity(0.4), blurRadius: 4, offset: const Offset(0, 2))
                    ] : null,
                  ),
                  child: entry != null 
                      ? Image.asset(kMoods[entry.moodIndex % kMoods.length].iconPath!)
                      : Center(child: Text('$day', style: TextStyle(fontSize: 11, color: isNight ? Colors.white24 : Colors.black26))),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  void _handleBackfill(BuildContext context, DateTime date, bool isNight) {
    showDialog(
      context: context,
      barrierColor: Colors.black.withOpacity(0.7),
      builder: (context) => Center(
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 40),
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: isNight ? const Color(0xFF2D2A26) : const Color(0xFFFDF7E9),
            borderRadius: BorderRadius.circular(24),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text("💧", style: TextStyle(fontSize: 32)),
              const SizedBox(height: 16),
              Text(
                "这一天好像掉在了岁月的迷雾里...",
                style: TextStyle(
                  fontSize: 16,
                  color: isNight ? Colors.white70 : const Color(0xFF5D4037),
                  fontFamily: 'LXGWWenKai',
                ),
              ),
              const SizedBox(height: 8),
              Text(
                "要把 ${date.month}月${date.day}日 找回来吗？",
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: isNight ? Colors.white54 : Colors.black54,
                  fontFamily: 'LXGWWenKai',
                ),
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text("先不找了"),
                  ),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => DiaryEditorPage(
                            moodIndex: 4, // 默认平静
                            intensity: 6.0,
                            initialDate: date,
                          ),
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFD4A373),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text("找回来", style: TextStyle(color: Colors.white)),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
