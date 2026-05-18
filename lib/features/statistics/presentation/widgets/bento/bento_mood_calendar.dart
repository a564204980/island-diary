part of '../../pages/statistics_page.dart';

extension _BentoMoodCalendar on _StatisticsPageState {
  Widget _buildMoodCalendarBento(bool isNight, List<DiaryEntry> allEntries) {
    final now = DateTime.now();
    final bool isCottonCandy = UserState().selectedIslandThemeId.value == 'cotton_candy';
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
      backgroundColor: isCottonCandy ? const Color(0xFFFFF4EF) : null,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildBentoHeader(
            context: context,
            title: '情绪日历',
            helpContent: '每个日期会显示当天最主要的心情。点开某一天，可以回看那天写下的日记和情绪。',
            isNight: isNight,
            rightAction: Icon(
              CupertinoIcons.calendar,
              size: 18,
              color: isCottonCandy
                  ? const Color(0xFFF7AAB6)
                  : (isNight ? Colors.white54 : Colors.black38),
            ),
          ),
          const SizedBox(height: 12),
          // 星期表头
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: ['一', '二', '三', '四', '五', '六', '日'].map((day) {
              return Text(
                day,
                style: TextStyle(
                  fontSize: 12,
                  color: isNight
                      ? Colors.white38
                      : (isCottonCandy ? const Color(0xFF9A7A69) : Colors.black38),
                  fontWeight: FontWeight.bold,
                  fontFamily: 'LXGWWenKai',
                ),
              );
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
                        color: entry != null
                            ? Colors.transparent
                            : (isCottonCandy
                                ? const Color(0xFFFFEDE7).withValues(alpha: 0.72)
                                : (isNight ? Colors.white10 : Colors.black.withValues(alpha: 0.04))),
                        borderRadius: BorderRadius.circular(isCottonCandy ? 14 : 12),
                        border: entry == null && isCottonCandy
                            ? Border.all(color: const Color(0xFFF8DDD5).withValues(alpha: 0.45))
                            : null,
                        boxShadow: null,
                      ),
                      child: entry != null
                          ? Center(
                              child: _MoodCalendarIcon(
                                moodIndex: entry.moodIndex % kMoods.length,
                                isCottonCandy: isCottonCandy,
                              ),
                            )
                          : Center(
                              child: Text(
                                '$day',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: isNight
                                      ? Colors.white24
                                      : (isCottonCandy ? const Color(0xFFC4A99B) : Colors.black26),
                                  fontFamily: 'LXGWWenKai',
                                ),
                              ),
                            ),
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
      barrierColor: Colors.black.withValues(alpha: 0.4), // 调暗背景增强沉浸感
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

class _MoodCalendarIcon extends StatelessWidget {
  final int moodIndex;
  final bool isCottonCandy;

  const _MoodCalendarIcon({
    required this.moodIndex,
    required this.isCottonCandy,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: isCottonCandy ? 38 : 34,
      height: isCottonCandy ? 38 : 34,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: isCottonCandy ? const Color(0xFFFFF6F2).withValues(alpha: 0.48) : Colors.transparent,
        boxShadow: isCottonCandy
            ? [
                BoxShadow(
                  color: const Color(0xFFD9A49D).withValues(alpha: 0.18),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
                BoxShadow(
                  color: Colors.white.withValues(alpha: 0.85),
                  blurRadius: 2,
                  offset: const Offset(-1, -1),
                ),
              ]
            : null,
      ),
      child: Padding(
        padding: EdgeInsets.all(isCottonCandy ? 2 : 1),
        child: Image.asset(
          _moodCalendarIconPath(moodIndex),
          fit: BoxFit.contain,
          filterQuality: FilterQuality.high,
        ),
      ),
    );
  }

  String _moodCalendarIconPath(int index) {
    switch (index % kMoods.length) {
      case 0:
        return 'assets/icons/happy.png';
      case 1:
        return 'assets/icons/calm.png';
      case 2:
        return 'assets/icons/down.png';
      case 3:
        return 'assets/icons/irritated.png';
      case 4:
        return 'assets/icons/tired.png';
      case 5:
        return 'assets/icons/surprise.png';
      case 6:
        return 'assets/icons/shy.png';
      case 7:
        return 'assets/icons/anxious.png';
      case 8:
        return 'assets/icons/wronged.png';
      case 9:
        return 'assets/icons/bored.png';
      case 10:
        return 'assets/icons/expect.png';
      default:
        return 'assets/icons/happy.png';
    }
  }
}
