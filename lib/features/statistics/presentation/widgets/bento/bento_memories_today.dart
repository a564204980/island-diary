part of '../../pages/statistics_page.dart';

class _TodayMemoryGroup {
  final int year;
  final List<DiaryEntry> entries;

  const _TodayMemoryGroup({
    required this.year,
    required this.entries,
  });

  DiaryEntry get representative => entries.first;
}

extension _BentoMemoriesToday on _StatisticsPageState {
  Widget _buildMemoriesTodayBento(bool isNight, List<DiaryEntry> allEntries, Color themeColor) {
    final now = DateTime.now();
    final List<DiaryEntry> matches = allEntries
        .where((entry) => entry.dateTime.month == now.month && entry.dateTime.day == now.day)
        .toList()
      ..sort((a, b) => b.dateTime.compareTo(a.dateTime));

    final List<_TodayMemoryGroup> grouped = _groupMemoriesByYear(matches);
    final bool isCottonCandy = UserState().selectedIslandThemeId.value == 'cotton_candy';
    final Color accentColor = isCottonCandy ? const Color(0xFFF7AAB6) : themeColor;
    final Color cottonCandySurface = const Color(0xFFFFFAF8);

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => _openMemoriesTodayPage(isNight),
      child: _buildGlassCard(
        isNight: isNight,
        backgroundColor: isCottonCandy ? cottonCandySurface : null,
        padding: const EdgeInsets.all(16),
        child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildBentoHeader(
            context: context,
            title: '那年今天',
            helpContent: '筛选历史上和今天同月同日的日记，按年份倒序展示。点开卡片可以查看完整的往年记录。',
            isNight: isNight,
            rightAction: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  CupertinoIcons.clock,
                  size: 18,
                  color: isNight ? Colors.white54 : accentColor.withValues(alpha: 0.8),
                ),
                const SizedBox(width: 6),
                Text(
                  '${grouped.length} 年',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: isNight ? Colors.white54 : accentColor.withValues(alpha: 0.9),
                  ),
                ),
              ],
            ),
            ),
            const SizedBox(height: 12),
          if (grouped.isEmpty)
            _buildTodayMemoryEmptyState(isNight, accentColor)
          else ...[
            _buildTodayMemoryHeroCard(
              isNight: isNight,
              accentColor: accentColor,
              entry: grouped.first.representative,
              matchCount: matches.length,
            ),
          ],
        ],
        ),
      ),
    );
  }

  void _openMemoriesTodayPage(bool isNight) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => MemoriesTodayPage(
          entries: _allDiaries,
          isNight: isNight,
        ),
      ),
    );
  }

  List<_TodayMemoryGroup> _groupMemoriesByYear(List<DiaryEntry> matches) {
    final Map<int, List<DiaryEntry>> byYear = {};
    for (final entry in matches) {
      byYear.putIfAbsent(entry.dateTime.year, () => []).add(entry);
    }

    final groups = byYear.entries
        .map((e) {
          final entries = List<DiaryEntry>.from(e.value)
            ..sort((a, b) => b.dateTime.compareTo(a.dateTime));
          return _TodayMemoryGroup(year: e.key, entries: entries);
        })
        .toList()
      ..sort((a, b) => b.year.compareTo(a.year));

    return groups;
  }

  Widget _buildTodayMemoryEmptyState(bool isNight, Color accentColor) {
    final bool isCottonCandy = UserState().selectedIslandThemeId.value == 'cotton_candy';
    final Color surfaceColor = isCottonCandy ? const Color(0xFFFFFAF8) : accentColor.withValues(alpha: 0.06);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 18),
      decoration: BoxDecoration(
        color: isNight ? Colors.white10 : surfaceColor,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: accentColor.withValues(alpha: isNight ? 0.18 : 0.14),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                CupertinoIcons.sparkles,
                size: 18,
                color: accentColor,
              ),
              const SizedBox(width: 8),
              Text(
                '今天还没有同日记忆',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: isNight ? Colors.white : const Color(0xFF5A3E28),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            '等未来的今天再次来到，这里会自动收集你往年的同一天记录。',
            style: TextStyle(
              fontSize: 12,
              height: 1.45,
              color: isNight ? Colors.white70 : Colors.black54,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTodayMemoryHeroCard({
    required bool isNight,
    required Color accentColor,
    required DiaryEntry entry,
    required int matchCount,
  }) {
    final String content = _truncateMemoryText(entry.content, 96);
    final String dateLabel = DateFormat('yyyy / MM-dd').format(entry.dateTime);
    final bool isCottonCandy = UserState().selectedIslandThemeId.value == 'cotton_candy';
    final Color surfaceColor = isCottonCandy ? const Color(0xFFFFF4EF) : accentColor.withValues(alpha: 0.05);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        color: isNight
            ? Colors.white.withValues(alpha: 0.04)
            : surfaceColor,
        border: Border(
          left: BorderSide(
            color: accentColor.withValues(alpha: 0.55),
            width: 3,
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: accentColor.withValues(alpha: isNight ? 0.22 : 0.16),
                ),
                child: Icon(
                  CupertinoIcons.book,
                  color: accentColor,
                  size: 20,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      dateLabel,
                      style: TextStyle(
                        fontSize: 12,
                        color: isNight ? Colors.white54 : Colors.black45,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      entry.tag != null && entry.tag!.isNotEmpty
                          ? entry.tag!
                          : '那一年，你也在记录这一天',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: isNight ? Colors.white : const Color(0xFF5A3E28),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            content,
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 13,
              height: 1.55,
              color: isNight ? Colors.white70 : Colors.black87,
              fontFamily: 'LXGWWenKai',
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Icon(
                CupertinoIcons.arrow_right_circle_fill,
                size: 16,
                color: accentColor,
              ),
              const SizedBox(width: 6),
              Text(
                '共 $matchCount 条同日记忆',
                style: TextStyle(
                  fontSize: 12,
                  color: isNight ? Colors.white54 : Colors.black45,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showTodayMemorySheet({
    required BuildContext context,
    required bool isNight,
    required List<_TodayMemoryGroup> groups,
    required Color accentColor,
    int? initialYear,
  }) {
    final targetYear = initialYear ?? groups.first.year;
    final bool isCottonCandy = UserState().selectedIslandThemeId.value == 'cotton_candy';
    final Color sheetSurface = isCottonCandy ? const Color(0xFFFFFAF8) : (isNight ? const Color(0xFF1E1E1E) : Colors.white);

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        return Container(
          height: MediaQuery.of(context).size.height * 0.78,
          decoration: BoxDecoration(
            color: sheetSurface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            children: [
              const SizedBox(height: 8),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 16),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  children: [
                    Container(
                      width: 14,
                      height: 14,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: accentColor,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '那年今天 · ${groups.length} 年记录',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: isNight ? Colors.white : Colors.black87,
                        ),
                      ),
                    ),
                    Text(
                      DateFormat('MM-dd').format(DateTime.now()),
                      style: TextStyle(
                        fontSize: 12,
                        color: isNight ? Colors.white54 : Colors.black45,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                height: 36,
                child: ListView.separated(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  scrollDirection: Axis.horizontal,
                  itemCount: groups.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 8),
                  itemBuilder: (context, index) {
                    final group = groups[index];
                    final selected = group.year == targetYear;
                    return Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: selected
                            ? accentColor.withValues(alpha: isNight ? 0.26 : 0.16)
                            : (isNight ? Colors.white10 : Colors.black.withValues(alpha: 0.04)),
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(
                          color: selected
                              ? accentColor.withValues(alpha: 0.4)
                              : Colors.transparent,
                        ),
                      ),
                      child: Text(
                        '${group.year}',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: selected
                              ? accentColor
                              : (isNight ? Colors.white70 : Colors.black54),
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 12),
              const Divider(height: 1),
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
                  itemCount: groups.length,
                  itemBuilder: (context, index) {
                    final group = groups[index];
                    return _buildTodayMemoryGroupCard(
                      isNight: isNight,
                      accentColor: accentColor,
                      group: group,
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildTodayMemoryGroupCard({
    required bool isNight,
    required Color accentColor,
    required _TodayMemoryGroup group,
  }) {
    final entry = group.representative;
    final bool isCottonCandy = UserState().selectedIslandThemeId.value == 'cotton_candy';
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isNight
            ? Colors.white10
            : (isCottonCandy ? const Color(0xFFFFFBF8) : Colors.black.withValues(alpha: 0.03)),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: accentColor.withValues(alpha: isNight ? 0.14 : 0.1),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                '${group.year}',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: accentColor,
                ),
              ),
              const SizedBox(width: 10),
              Text(
                DateFormat('MM-dd HH:mm').format(entry.dateTime),
                style: TextStyle(
                  fontSize: 11,
                  color: isNight ? Colors.white54 : Colors.black45,
                ),
              ),
              const Spacer(),
              if (group.entries.length > 1)
                Text(
                  '${group.entries.length} 条',
                  style: TextStyle(
                    fontSize: 11,
                    color: isNight ? Colors.white54 : Colors.black45,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            entry.content,
            style: TextStyle(
              fontSize: 13,
              height: 1.55,
              color: isNight ? Colors.white70 : Colors.black87,
              fontFamily: 'LXGWWenKai',
            ),
          ),
          if (group.entries.length > 1) ...[
            const SizedBox(height: 10),
            ExpansionTile(
              tilePadding: EdgeInsets.zero,
              childrenPadding: const EdgeInsets.only(top: 8),
              collapsedIconColor: accentColor,
              iconColor: accentColor,
              title: Text(
                '查看同年其他记录',
                style: TextStyle(
                  fontSize: 12,
                  color: accentColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
              children: group.entries.skip(1).map((item) {
                return Container(
                  width: double.infinity,
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isNight
                        ? Colors.white10
                        : (isCottonCandy ? const Color(0xFFFFFBF8) : Colors.white),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Text(
                    item.content,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 12.5,
                      height: 1.5,
                      color: isNight ? Colors.white70 : Colors.black87,
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ],
      ),
    );
  }

  String _truncateMemoryText(String text, int maxLength) {
    final normalized = text.replaceAll('\n', ' ').trim();
    if (normalized.length <= maxLength) {
      return normalized;
    }
    return '${normalized.substring(0, maxLength)}...';
  }
}
