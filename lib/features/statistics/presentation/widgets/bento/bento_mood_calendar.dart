part of '../../pages/statistics_page.dart';

extension _BentoMoodCalendar on _StatisticsPageState {
  Widget _buildMoodCalendarBento(bool isNight, List<DiaryEntry> allEntries) {
    final now = DateTime.now();
    final bool isCottonCandy = UserState().selectedIslandThemeId.value == 'cotton_candy';
    // 构建本月每一天的数据映射（支持一天多篇日记）
    Map<int, List<DiaryEntry>> daysEntriesMap = {};
    for (var e in allEntries) {
      if (e.dateTime.year == now.year && e.dateTime.month == now.month) {
        daysEntriesMap.putIfAbsent(e.dateTime.day, () => []).add(e);
      }
    }
    // 按照时间先后升序排序，保证最后写的一篇在列表末端
    daysEntriesMap.forEach((day, entries) {
      entries.sort((a, b) => a.dateTime.compareTo(b.dateTime));
    });

    final int daysInMonth = DateUtils.getDaysInMonth(now.year, now.month);
    final int firstWeekday = DateTime(now.year, now.month, 1).weekday; // 1=Mon, 7=Sun
    final String themeId = UserState().selectedIslandThemeId.value;
    final bool isLego = themeId == 'lego';

    final Widget cardBody = Column(
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
                final entries = daysEntriesMap[day] ?? [];
                final entry = entries.isNotEmpty ? entries.last : null;

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
                      color: day == now.day
                          ? (isCottonCandy
                              ? const Color(0xFFFFF2F4)
                              : (isNight ? const Color(0xFF3D2C2F) : const Color(0xFFFFF0F2)))
                          : (isCottonCandy
                              ? const Color(0xFFFFEDE7).withValues(alpha: 0.6)
                              : (isNight ? Colors.white10 : Colors.black.withValues(alpha: 0.03))),
                      borderRadius: BorderRadius.circular(isCottonCandy ? 14 : 12),
                      border: Border.all(
                        color: day == now.day
                            ? (isCottonCandy
                                ? const Color(0xFFF7AAB6)
                                : (isNight ? const Color(0xFFF7AAB6).withValues(alpha: 0.6) : const Color(0xFFF7AAB6)))
                            : (isCottonCandy
                                ? const Color(0xFFF8DDD5).withValues(alpha: 0.45)
                                : (isNight ? Colors.white.withValues(alpha: 0.08) : Colors.black.withValues(alpha: 0.05))),
                        width: day == now.day ? 1.5 : 1.0,
                      ),
                      boxShadow: day == now.day && isCottonCandy
                          ? [
                              BoxShadow(
                                color: const Color(0xFFF7AAB6).withValues(alpha: 0.15),
                                blurRadius: 6,
                                offset: const Offset(0, 2),
                              )
                            ]
                          : null,
                    ),
                    child: entry != null
                        ? Stack(
                            fit: StackFit.expand,
                            clipBehavior: Clip.none,
                            children: [
                              Positioned(
                                left: -2,
                                top: -3,
                                child: Text(
                                  '$day',
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: day == now.day ? FontWeight.bold : FontWeight.w600,
                                    color: day == now.day
                                        ? (isCottonCandy ? const Color(0xFFF76F87) : (isNight ? const Color(0xFFF7AAB6) : const Color(0xFFF76F87)))
                                        : (isNight
                                            ? Colors.white70
                                            : (isCottonCandy ? const Color(0xFF7A5A4A) : Colors.black54)),
                                    fontFamily: 'LXGWWenKai',
                                  ),
                                ),
                              ),
                              Center(
                                child: _MoodCalendarIcon(
                                  moodIndex: entry.moodIndex % kMoods.length,
                                  isCottonCandy: isCottonCandy,
                                  size: isCottonCandy ? 24 : 22,
                                ),
                              ),
                              if (entries.length > 1)
                                Positioned(
                                  left: 0,
                                  right: 0,
                                  bottom: 1.5,
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: entries
                                        .take(4)
                                        .map((e) => _buildMoodDot(
                                              e.moodIndex % kMoods.length,
                                              isNight,
                                              isCottonCandy,
                                            ))
                                        .toList(),
                                  ),
                                ),
                            ],
                          )
                        : Stack(
                            clipBehavior: Clip.none,
                            children: [
                              Center(
                                child: Text(
                                  '$day',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: day == now.day ? FontWeight.bold : FontWeight.normal,
                                    color: day == now.day
                                        ? (isCottonCandy ? const Color(0xFFF76F87) : (isNight ? const Color(0xFFF7AAB6) : const Color(0xFFF76F87)))
                                        : (isNight
                                            ? Colors.white70
                                            : (isCottonCandy ? const Color(0xFF7A5A4A) : Colors.black54)),
                                    fontFamily: 'LXGWWenKai',
                                  ),
                                ),
                              ),
                            ],
                          ),
                  ),
                );
              },
            );
          },
        ),
      ],
    );

    if (isLego) {
      return Container(
        decoration: BoxDecoration(
          color: isNight ? const Color(0xFF1E2024) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isNight
                ? Colors.white.withValues(alpha: 0.05)
                : Colors.black.withValues(alpha: 0.05),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: isNight ? Colors.black38 : Colors.black.withValues(alpha: 0.04),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Stack(
            children: [
              Positioned.fill(
                child: CustomPaint(
                  painter: _LegoStudBackgroundPainter(isNight: isNight),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: cardBody,
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
      child: cardBody,
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

  Widget _buildMoodDot(int moodIndex, bool isNight, bool isCottonCandy) {
    final color = _getMoodColor(moodIndex, isNight, isCottonCandy);
    return Container(
      width: 4,
      height: 4,
      margin: const EdgeInsets.symmetric(horizontal: 1),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color,
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.4),
            blurRadius: 1,
            spreadRadius: 0.5,
          ),
        ],
      ),
    );
  }

  Color _getMoodColor(int moodIndex, bool isNight, bool isCottonCandy) {
    switch (moodIndex % 11) {
      case 0:
        return isCottonCandy ? const Color(0xFFFFB2A6) : const Color(0xFFFF8A80);
      case 1:
        return isCottonCandy ? const Color(0xFFC7E5C7) : const Color(0xFF81C784);
      case 2:
        return isCottonCandy ? const Color(0xFFA9D8EB) : const Color(0xFF64B5F6);
      case 3:
        return isCottonCandy ? const Color(0xFFFF8E9B) : const Color(0xFFE57373);
      case 4:
        return isCottonCandy ? const Color(0xFFD9B9E7) : const Color(0xFFBA68C8);
      case 5:
        return isCottonCandy ? const Color(0xFFFFE0A3) : const Color(0xFFFFD54F);
      case 6:
        return isCottonCandy ? const Color(0xFFF9B7FF) : const Color(0xFFF06292);
      case 7:
        return isCottonCandy ? const Color(0xFFB0BEC5) : const Color(0xFF90A4AE);
      case 8:
        return isCottonCandy ? const Color(0xFFB3E5FC) : const Color(0xFF4FC3F7);
      case 9:
        return isCottonCandy ? const Color(0xFFD7CCC8) : const Color(0xFFA1887F);
      case 10:
        return isCottonCandy ? const Color(0xFFFFF59D) : const Color(0xFFFFF176);
      default:
        return Colors.grey;
    }
  }
}

class _MoodCalendarIcon extends StatelessWidget {
  final int moodIndex;
  final bool isCottonCandy;
  final double? size;

  const _MoodCalendarIcon({
    required this.moodIndex,
    required this.isCottonCandy,
    this.size,
  });

  @override
  Widget build(BuildContext context) {
    final double actualSize = size ?? (isCottonCandy ? 26 : 24);
    return Container(
      width: actualSize,
      height: actualSize,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: isCottonCandy ? const Color(0xFFFFF6F2).withValues(alpha: 0.48) : Colors.transparent,
        boxShadow: isCottonCandy
            ? [
                BoxShadow(
                  color: const Color(0xFFD9A49D).withValues(alpha: 0.12),
                  blurRadius: 4,
                  offset: const Offset(0, 1.5),
                ),
                BoxShadow(
                  color: Colors.white.withValues(alpha: 0.85),
                  blurRadius: 1.5,
                  offset: const Offset(-0.5, -0.5),
                ),
              ]
            : null,
      ),
      child: Padding(
        padding: EdgeInsets.all(isCottonCandy ? 1.5 : 0.5),
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
