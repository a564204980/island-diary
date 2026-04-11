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
          _buildBentoHeader(
            context: context,
            title: '${now.month}月的时光印记',
            helpContent: '以月为单位，将每日主色调映射至日历，拼凑成完整的[[心灵色彩拼图]]。点击具体日期，可回溯当下的珍贵思绪。',
            isNight: isNight,
            rightAction: Icon(CupertinoIcons.calendar, size: 18, color: isNight ? Colors.white54 : Colors.black38),
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
          LayoutBuilder(
            builder: (context, constraints) {
              final double screenWidth = MediaQuery.of(context).size.width;
              final double aspectRatio = screenWidth > 600 ? 1.3 : 1.0;
              
              return GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 7, 
                  childAspectRatio: aspectRatio,
                  crossAxisSpacing: 8,
                  mainAxisSpacing: 8,
                ),
                itemCount: daysInMonth + firstWeekday - 1,
                itemBuilder: (context, index) {
                  if (index < firstWeekday - 1) return const SizedBox.shrink();
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
              );
            },
          ),
        ],
      ),
    );
  }

  void _handleBackfill(BuildContext context, DateTime date, bool isNight) {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: "Dismiss",
      barrierColor: Colors.black.withOpacity(0.4), // 调暗背景增强沉浸感
      transitionDuration: const Duration(milliseconds: 600),
      pageBuilder: (context, anim1, anim2) {
        return RecoverDiaryDialog(date: date, isNight: isNight);
      },
      transitionBuilder: (context, anim1, anim2, child) {
        final curve = Curves.easeOutBack.transform(anim1.value);
        return Transform.scale(
          scale: 0.8 + (curve * 0.2),
          child: Opacity(
            opacity: anim1.value,
            child: child,
          ),
        );
      },
    );
  }
}
