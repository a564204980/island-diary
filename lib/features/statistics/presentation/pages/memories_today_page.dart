import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:island_diary/core/state/user_state.dart';
import 'package:island_diary/features/record/domain/models/diary_entry.dart';
import 'package:island_diary/features/record/presentation/pages/diary_detail_page.dart';
import 'package:island_diary/shared/widgets/mood_picker/config/mood_config.dart';

class MemoriesTodayPage extends StatelessWidget {
  final List<DiaryEntry> entries;
  final bool isNight;

  const MemoriesTodayPage({
    super.key,
    required this.entries,
    required this.isNight,
  });

  List<DiaryEntry> _getSameDayEntries() {
    final now = DateTime.now();
    return entries
        .where(
          (entry) =>
              entry.dateTime.month == now.month &&
              entry.dateTime.day == now.day &&
              entry.dateTime.year < now.year,
        )
        .toList()
      ..sort((a, b) => b.dateTime.compareTo(a.dateTime));
  }

  @override
  Widget build(BuildContext context) {
    final sameDayEntries = _getSameDayEntries();
    final bool isCottonCandy = UserState().selectedIslandThemeId.value == 'cotton_candy';
    final Color accentColor = isCottonCandy ? const Color(0xFFF7AAB6) : const Color(0xFFD4A373);
    final DateTime now = DateTime.now();
    final DiaryEntry? heroEntry = sameDayEntries.isNotEmpty ? sameDayEntries.first : null;
    final int yearsAgo = heroEntry == null ? 0 : now.year - heroEntry.dateTime.year;

    return Scaffold(
      backgroundColor: isNight ? const Color(0xFF15131A) : const Color(0xFFF6E3DE),
      body: Stack(
        children: [
          _buildBackground(isCottonCandy),
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.white.withValues(alpha: isNight ? 0.02 : 0.14),
                    Colors.white.withValues(alpha: isNight ? 0.00 : 0.05),
                  ],
                ),
              ),
            ),
          ),
          SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                  child: Row(
                    children: [
                      _buildBackButton(context, isNight),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: isNight ? Colors.white10 : Colors.white.withValues(alpha: 0.36),
                          borderRadius: BorderRadius.circular(999),
                          border: Border.all(
                            color: isNight ? Colors.white12 : Colors.white.withValues(alpha: 0.5),
                          ),
                        ),
                        child: Text(
                          '${sameDayEntries.length} 条',
                          style: TextStyle(
                            fontSize: 12,
                            color: isNight ? Colors.white70 : const Color(0xFF8A6557),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    children: [
                      Image.asset(
                        'assets/images/na_nian_jin_tian.png',
                        width: 340,
                        fit: BoxFit.contain,
                      ),
                      const SizedBox(height: 4),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            CupertinoIcons.sparkles,
                            size: 14,
                            color: isNight ? Colors.white54 : const Color(0xFF8A6557),
                          ),
                          const SizedBox(width: 10),
                          Text(
                            '岛屿替你找回了一段旧日心情',
                            style: TextStyle(
                              fontSize: 16,
                              color: isNight ? Colors.white70 : const Color(0xFF8A6557),
                              fontFamily: 'LXGWWenKai',
                            ),
                          ),
                          const SizedBox(width: 10),
                          Icon(
                            CupertinoIcons.sparkles,
                            size: 14,
                            color: isNight ? Colors.white54 : const Color(0xFF8A6557),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                Expanded(
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 860),
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            if (heroEntry == null)
                              _buildEmptyState(isNight, accentColor)
                            else
                              _buildHeroCard(
                                context: context,
                                entry: heroEntry,
                                yearsAgo: yearsAgo,
                                accentColor: accentColor,
                                isNight: isNight,
                                onTap: () => Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => DiaryDetailPage(
                                      entry: heroEntry,
                                      isNight: isNight,
                                    ),
                                  ),
                                ),
                              ),
                            const SizedBox(height: 24),
                            if (sameDayEntries.length > 1) ...[
                              Row(
                                children: [
                                  Expanded(
                                    child: Divider(
                                      color: isNight ? Colors.white12 : Colors.black.withValues(alpha: 0.08),
                                      thickness: 1,
                                    ),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 12),
                                    child: Text(
                                      '更多同日记忆',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: isNight ? Colors.white54 : const Color(0xFF9A7A69),
                                      ),
                                    ),
                                  ),
                                  Expanded(
                                    child: Divider(
                                      color: isNight ? Colors.white12 : Colors.black.withValues(alpha: 0.08),
                                      thickness: 1,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              ...sameDayEntries.skip(1).map(
                                    (entry) => Padding(
                                      padding: const EdgeInsets.only(bottom: 12),
                                      child: _buildMiniMemoryCard(
                                        context: context,
                                        entry: entry,
                                        accentColor: accentColor,
                                        isNight: isNight,
                                      ),
                                    ),
                                  ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBackground(bool isCottonCandy) {
    if (isCottonCandy) {
      return Positioned.fill(
        child: Stack(
          fit: StackFit.expand,
          children: [
            Image.asset(
              'assets/images/background/page_3_bg.png',
              fit: BoxFit.cover,
            ),
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    const Color(0xFFFFF0EC).withValues(alpha: 0.30),
                    const Color(0xFFFDECE6).withValues(alpha: 0.28),
                  ],
                ),
              ),
            ),
            const _SoftCloud(offset: Offset(-50, 80), size: 180),
            const _SoftCloud(offset: Offset(250, 120), size: 140),
            const _SoftCloud(offset: Offset(40, 620), size: 210),
            const _SoftCloud(offset: Offset(260, 760), size: 160),
          ],
        ),
      );
    }

    return Positioned.fill(
      child: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFF7E5E0), Color(0xFFF4D9D1)],
          ),
        ),
      ),
    );
  }

  Widget _buildBackButton(BuildContext context, bool isNight) {
    return GestureDetector(
      onTap: () => Navigator.pop(context),
      child: Container(
        width: 42,
        height: 42,
        decoration: BoxDecoration(
          color: isNight ? Colors.white10 : Colors.white.withValues(alpha: 0.38),
          shape: BoxShape.circle,
          border: Border.all(
            color: isNight ? Colors.white12 : Colors.white.withValues(alpha: 0.55),
          ),
        ),
        child: Icon(
          CupertinoIcons.chevron_left,
          color: isNight ? Colors.white70 : const Color(0xFF7E5D51),
          size: 20,
        ),
      ),
    );
  }

  Widget _buildEmptyState(bool isNight, Color accentColor) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: isNight ? Colors.white10 : Colors.white.withValues(alpha: 0.45),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(
          color: accentColor.withValues(alpha: isNight ? 0.14 : 0.22),
        ),
      ),
      child: Column(
        children: [
          Icon(
            CupertinoIcons.sparkles,
            color: accentColor,
            size: 28,
          ),
          const SizedBox(height: 12),
          Text(
            '今天还没有找到往年的同日记忆',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: isNight ? Colors.white : const Color(0xFF5E3D2D),
              fontFamily: 'LXGWWenKai',
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '等你在这一天继续写下新日记，明年这里就会多出一页新的回声。',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              height: 1.6,
              color: isNight ? Colors.white70 : const Color(0xFF8A6557),
              fontFamily: 'LXGWWenKai',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeroCard({
    required BuildContext context,
    required DiaryEntry entry,
    required int yearsAgo,
    required Color accentColor,
    required bool isNight,
    required VoidCallback onTap,
  }) {
    final mood = kMoods[entry.moodIndex % kMoods.length];
    final title = '${yearsAgo <= 0 ? 1 : yearsAgo}年前的今天';
    final dateText = DateFormat('yyyy年M月d日').format(entry.dateTime);
    final wordCount = entry.content.trim().isEmpty ? 0 : entry.content.trim().length;
    final excerpt = _truncate(entry.content.replaceAll('\n', ' '), 88);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: isNight ? const Color(0xFF2B252E).withValues(alpha: 0.92) : const Color(0xFFF9EDE2),
          borderRadius: BorderRadius.circular(30),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isNight ? 0.22 : 0.12),
              blurRadius: 28,
              offset: const Offset(0, 16),
            ),
          ],
          border: Border.all(
            color: Colors.white.withValues(alpha: isNight ? 0.06 : 0.34),
          ),
        ),
        child: Stack(
          children: [
            Positioned(
              right: 0,
              top: 0,
              child: _StampBadge(
                accentColor: accentColor,
                isNight: isNight,
              ),
            ),
            Positioned.fill(
              child: IgnorePointer(
                child: Opacity(
                  opacity: 0.12,
                  child: Image.asset(
                    'assets/images/paper.png',
                    fit: BoxFit.cover,
                  ),
                ),
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            style: TextStyle(
                              fontSize: 30,
                              fontWeight: FontWeight.w600,
                              color: isNight ? Colors.white : const Color(0xFF5B3A2D),
                              fontFamily: 'LXGWWenKai',
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            dateText,
                            style: TextStyle(
                              fontSize: 14,
                              color: isNight ? Colors.white54 : const Color(0xFF94756A),
                              letterSpacing: 1.2,
                            ),
                          ),
                          const SizedBox(height: 12),
                          _MoodPill(
                            label: mood.label,
                            accentColor: accentColor,
                            isNight: isNight,
                          ),
                          const SizedBox(height: 10),
                          Text(
                            '$wordCount 字',
                            style: TextStyle(
                              fontSize: 13,
                              color: isNight ? Colors.white54 : const Color(0xFF94756A),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 42),
                Center(
                  child: Text(
                    excerpt.isEmpty ? '那天没有留下文字，但时间替你记住了它。' : excerpt,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 28,
                      height: 1.55,
                      color: isNight ? Colors.white : const Color(0xFF5B3A2D),
                      fontFamily: 'LXGWWenKai',
                    ),
                  ),
                ),
                const SizedBox(height: 36),
                Align(
                  alignment: Alignment.centerRight,
                  child: Text(
                    '—— 来自 ${DateFormat('yyyy.MM.dd').format(entry.dateTime)} 的自己',
                    style: TextStyle(
                      fontSize: 14,
                      color: isNight ? Colors.white54 : const Color(0xFF8A6557),
                      fontFamily: 'LXGWWenKai',
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMiniMemoryCard({
    required BuildContext context,
    required DiaryEntry entry,
    required Color accentColor,
    required bool isNight,
  }) {
    final mood = kMoods[entry.moodIndex % kMoods.length];
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => DiaryDetailPage(entry: entry, isNight: isNight),
        ),
      ),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isNight ? Colors.white10 : Colors.white.withValues(alpha: 0.45),
          borderRadius: BorderRadius.circular(22),
          border: Border.all(
            color: accentColor.withValues(alpha: isNight ? 0.12 : 0.18),
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: accentColor.withValues(alpha: isNight ? 0.18 : 0.14),
                shape: BoxShape.circle,
              ),
              child: Icon(
                CupertinoIcons.book,
                color: accentColor,
                size: 19,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    DateFormat('yyyy.MM.dd').format(entry.dateTime),
                    style: TextStyle(
                      fontSize: 12,
                      color: isNight ? Colors.white54 : const Color(0xFF9A7A69),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    mood.label,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: isNight ? Colors.white : const Color(0xFF5B3A2D),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    _truncate(entry.content.replaceAll('\n', ' '), 56),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 12.5,
                      height: 1.5,
                      color: isNight ? Colors.white70 : const Color(0xFF7B6157),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _truncate(String text, int maxLength) {
    if (text.length <= maxLength) return text;
    return '${text.substring(0, maxLength)}...';
  }
}

class _StampBadge extends StatelessWidget {
  final Color accentColor;
  final bool isNight;

  const _StampBadge({
    required this.accentColor,
    required this.isNight,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 84,
      height: 84,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        color: accentColor.withValues(alpha: isNight ? 0.16 : 0.10),
        border: Border.all(
          color: accentColor.withValues(alpha: isNight ? 0.18 : 0.28),
        ),
      ),
      child: Icon(
        CupertinoIcons.cloud,
        size: 34,
        color: accentColor.withValues(alpha: isNight ? 0.58 : 0.72),
      ),
    );
  }
}

class _MoodPill extends StatelessWidget {
  final String label;
  final Color accentColor;
  final bool isNight;

  const _MoodPill({
    required this.label,
    required this.accentColor,
    required this.isNight,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
      decoration: BoxDecoration(
        color: accentColor.withValues(alpha: isNight ? 0.20 : 0.22),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 12,
          color: Colors.white,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _SoftCloud extends StatelessWidget {
  final Offset offset;
  final double size;

  const _SoftCloud({
    required this.offset,
    required this.size,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: offset.dx,
      top: offset.dy,
      child: IgnorePointer(
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(
              colors: [
                Colors.white.withValues(alpha: 0.34),
                Colors.white.withValues(alpha: 0.0),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
