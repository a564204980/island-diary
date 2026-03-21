import 'package:flutter/material.dart';
import 'package:island_diary/features/record/domain/models/diary_entry.dart';
import 'package:island_diary/shared/widgets/mood_picker/config/mood_config.dart';
import 'package:island_diary/shared/widgets/diary_entry/utils/diary_utils.dart';
import 'package:island_diary/shared/widgets/diary_entry/utils/emoji_mapping.dart';

class DiaryShareCardBuilder extends StatelessWidget {
  final List<DiaryEntry> entries;
  final String title;
  final bool isMonthMode;
  final bool isBookMode;
  final GlobalKey boundaryKey;

  const DiaryShareCardBuilder({
    super.key,
    required this.boundaryKey,
    required this.entries,
    required this.title,
    this.isMonthMode = false,
    this.isBookMode = false,
  });

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      key: boundaryKey,
      child: Container(
        width: 375,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
        decoration: const BoxDecoration(
          color: Color(0xFFFDF9F0),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            const SizedBox(height: 24),
            if (isBookMode)
              _buildBookContent()
            else if (isMonthMode)
              _buildMonthContent()
            else
              _buildDayContent(),
            const SizedBox(height: 40),
            _buildFooter(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Color(0xFF5D4037),
                fontFamily: 'LXGWWenKai',
                fontFamilyFallback: const ['Nishiki'],
              ),
            ),
            const Icon(Icons.auto_awesome, color: Color(0xFFD4A373), size: 24),
          ],
        ),
        const SizedBox(height: 8),
        Container(
          width: 60,
          height: 3,
          decoration: BoxDecoration(
            color: const Color(0xFFD4A373).withOpacity(0.3),
            borderRadius: BorderRadius.circular(1.5),
          ),
        ),
      ],
    );
  }

  Widget _buildDayContent() {
    if (entries.isEmpty) {
      return const Center(child: Text("这一天没有记录哦", style: TextStyle(fontFamily: 'LXGWWenKai')));
    }

    return Column(
      children: entries.map((entry) {
        final mood = kMoods[entry.moodIndex.clamp(0, kMoods.length - 1)];
        return Container(
          margin: const EdgeInsets.only(bottom: 20),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.5),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFD4A373).withOpacity(0.1)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Image.asset(mood.iconPath ?? '', width: 18, height: 18),
                  const SizedBox(width: 8),
                  Text(
                    "${entry.dateTime.hour.toString().padLeft(2, '0')}:${entry.dateTime.minute.toString().padLeft(2, '0')}",
                    style: const TextStyle(
                      fontSize: 12,
                      color: Colors.black38,
                      fontFamily: 'LXGWWenKai',
                    ),
                  ),
                  const Spacer(),
                  if (entry.tag != null && entry.tag!.isNotEmpty)
                    _buildTag(entry.tag!, mood.glowColor ?? const Color(0xFFD4A373)),
                ],
              ),
              const SizedBox(height: 12),
              RichText(
                text: TextSpan(
                  children: EmojiMapping.parseText(entry.content.trim()).map((chunk) {
                    if (chunk.isEmoji) {
                      return WidgetSpan(
                        alignment: PlaceholderAlignment.middle,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 2),
                          child: Image.asset(
                            chunk.emojiPath!,
                            width: 16,
                            height: 16,
                          ),
                        ),
                      );
                    }
                    return TextSpan(
                      text: chunk.text,
                      style: const TextStyle(
                        fontSize: 15,
                        height: 1.6,
                        color: Color(0xFF5D4037),
                        fontFamily: 'LXGWWenKai',
                      ),
                    );
                  }).toList(),
                ),
              ),
              if (entry.blocks.any((b) => b['type'] == 'image')) ...[
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: entry.blocks
                      .where((b) => b['type'] == 'image')
                      .map((b) => DiaryUtils.buildImage(
                            b['path'],
                            width: 60,
                            height: 60,
                            fit: BoxFit.cover,
                            borderRadius: BorderRadius.circular(8),
                          ))
                      .toList(),
                ),
              ],
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildMonthContent() {
    final Map<int, int> moodStats = {};
    for (var entry in entries) {
      moodStats[entry.moodIndex] = (moodStats[entry.moodIndex] ?? 0) + 1;
    }

    // 按入选次数排序
    final sortedMoods = moodStats.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 1. 统计概览
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildStatItem("记录天数", "${_countUniqueDays(entries)}天"),
            _buildStatItem("日记篇数", "${entries.length}篇"),
          ],
        ),
        const SizedBox(height: 32),
        // 2. 心情分布
        const Text(
          "心情关键词",
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Color(0xFF5D4037),
            fontFamily: 'LXGWWenKai',
          ),
        ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: sortedMoods.map((e) {
            final mood = kMoods[e.key.clamp(0, kMoods.length - 1)];
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: (mood.glowColor ?? const Color(0xFFD4A373)).withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: (mood.glowColor ?? const Color(0xFFD4A373)).withOpacity(0.2)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                   Image.asset(mood.iconPath ?? '', width: 16, height: 16),
                   const SizedBox(width: 6),
                   Text(
                     "${mood.label} ${e.value}",
                     style: TextStyle(
                       fontSize: 13,
                       color: (mood.glowColor ?? const Color(0xFF5D4037)).withOpacity(0.8),
                       fontFamily: 'LXGWWenKai',
                       fontFamilyFallback: const ['Nishiki'],
                       fontWeight: FontWeight.w600,
                     ),
                   ),
                ],
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 32),
        // 3. 随机寄语 (或者可以选一个小岛语录)
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: const Color(0xFFD4A373).withOpacity(0.05),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            children: [
              const Icon(Icons.format_quote_rounded, color: Color(0xFFD4A373), size: 32),
              const SizedBox(height: 12),
              const Text(
                "每一个普通的日子，都因为记录而变得闪亮。愿你在接下来的日子里，依然心有所期，行有所向。",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  fontStyle: FontStyle.italic,
                  color: Color(0xFF8B7763),
                  height: 1.6,
                  fontFamily: 'LXGWWenKai',
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStatItem(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: Color(0xFFD4A373),
            fontFamily: 'LXGWWenKai',
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(fontSize: 12, color: Colors.black26, fontFamily: 'LXGWWenKai'),
        ),
      ],
    );
  }

  int _countUniqueDays(List<DiaryEntry> entries) {
    final Set<String> days = {};
    for (var e in entries) {
      days.add("${e.dateTime.year}-${e.dateTime.month}-${e.dateTime.day}");
    }
    return days.length;
  }

  Widget _buildTag(String tag, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        "#$tag",
        style: TextStyle(
          fontSize: 10, 
          color: color.withOpacity(0.8), 
          fontWeight: FontWeight.bold, 
          fontFamily: 'LXGWWenKai',
          fontFamilyFallback: const ['Nishiki'],
        ),
      ),
    );
  }

  Widget _buildFooter() {
    return Row(
      children: [
        const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "岛屿日记 · Island Diary",
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.2,
                color: Color(0xFFD4A373),
                fontFamily: 'LXGWWenKai',
              ),
            ),
            Text(
              "用记录治愈生活",
              style: TextStyle(fontSize: 10, color: Colors.black12, fontFamily: 'LXGWWenKai'),
            ),
          ],
        ),
        const Spacer(),
        // 模拟一个手绘的小岛 Logo
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: const Color(0xFFD4A373).withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.eco_rounded, color: Color(0xFFD4A373), size: 18),
        ),
      ],
    );
  }
 
  Widget _buildBookContent() {
    if (entries.isEmpty) {
      return const Center(
          child:
              Text("还没有任何记录哦", style: TextStyle(fontFamily: 'LXGWWenKai')));
    }
 
    // 按日期倒序排列
    final sortedEntries = List<DiaryEntry>.from(entries)
      ..sort((a, b) => b.dateTime.compareTo(a.dateTime));
 
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildStatItem("记录时光", "${_countUniqueDays(entries)}天"),
            _buildStatItem("点滴故事", "${entries.length}篇"),
          ],
        ),
        const SizedBox(height: 32),
        const Text(
          "往日回响",
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Color(0xFF5D4037),
            fontFamily: 'LXGWWenKai',
          ),
        ),
        const SizedBox(height: 16),
        ...sortedEntries.map((entry) => _buildBookEntryItem(entry)),
      ],
    );
  }
 
  Widget _buildBookEntryItem(DiaryEntry entry) {
    final mood = kMoods[entry.moodIndex.clamp(0, kMoods.length - 1)];
    final dateStr =
        "${entry.dateTime.year}/${entry.dateTime.month}/${entry.dateTime.day}";
    final timeStr =
        "${entry.dateTime.hour.toString().padLeft(2, '0')}:${entry.dateTime.minute.toString().padLeft(2, '0')}";
 
    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 左侧时间轴感
            Column(
              children: [
                Text(
                  dateStr,
                  style: const TextStyle(
                    fontSize: 10,
                    color: Colors.black26,
                    fontFamily: 'LXGWWenKai',
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  timeStr,
                  style: const TextStyle(
                    fontSize: 10,
                    color: Colors.black12,
                    fontFamily: 'LXGWWenKai',
                  ),
                ),
                const SizedBox(height: 8),
                Expanded(
                  child: Container(
                    width: 1,
                    color: const Color(0xFFD4A373).withOpacity(0.2),
                  ),
                ),
              ],
            ),
            const SizedBox(width: 16),
            // 右侧内容
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Image.asset(mood.iconPath ?? '', width: 14, height: 14),
                      const SizedBox(width: 6),
                      Text(
                        mood.label,
                        style: TextStyle(
                          fontSize: 11,
                          color: (mood.glowColor ?? const Color(0xFFD4A373))
                              .withOpacity(0.7),
                          fontFamily: 'LXGWWenKai',
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (entry.tag != null && entry.tag!.isNotEmpty) ...[
                        const SizedBox(width: 8),
                        _buildTag(entry.tag!,
                            mood.glowColor ?? const Color(0xFFD4A373)),
                      ],
                    ],
                  ),
                  const SizedBox(height: 8),
                  RichText(
                    text: TextSpan(
                      children: EmojiMapping.parseText(entry.content.trim()).map((chunk) {
                        if (chunk.isEmoji) {
                          return WidgetSpan(
                            alignment: PlaceholderAlignment.middle,
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 2),
                              child: Image.asset(
                                chunk.emojiPath!,
                                width: 14,
                                height: 14,
                              ),
                            ),
                          );
                        }
                        return TextSpan(
                          text: chunk.text,
                          style: const TextStyle(
                            fontSize: 14,
                            height: 1.5,
                            color: Color(0xFF5D4037),
                            fontFamily: 'LXGWWenKai',
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                  if (entry.blocks.any((b) => b['type'] == 'image')) ...[
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: entry.blocks
                          .where((b) => b['type'] == 'image')
                          .map((b) => DiaryUtils.buildImage(
                                b['path'],
                                width: 50,
                                height: 50,
                                fit: BoxFit.cover,
                                borderRadius: BorderRadius.circular(6),
                              ))
                          .toList(),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
