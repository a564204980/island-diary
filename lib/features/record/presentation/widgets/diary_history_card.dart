import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:island_diary/features/record/domain/models/diary_entry.dart';
import 'package:island_diary/shared/widgets/diary_entry/utils/diary_utils.dart';
import 'package:island_diary/shared/widgets/mood_picker/config/mood_config.dart';
import 'package:island_diary/shared/widgets/diary_entry/utils/emoji_mapping.dart';
import 'package:island_diary/shared/widgets/diary_entry/models/diary_block.dart';
import '../pages/diary_detail_page.dart';

/// 每一份日记卡片
class DiaryHistoryCard extends StatefulWidget {
  final DiaryEntry entry;
  final int index;
  final bool isFilteredMode;
  final bool isNight;
  final bool showDate;

  const DiaryHistoryCard({
    super.key,
    required this.entry,
    required this.index,
    this.isFilteredMode = false,
    this.isNight = false,
    this.showDate = false,
    this.onShare,
  });

  final VoidCallback? onShare;

  @override
  State<DiaryHistoryCard> createState() => _DiaryHistoryCardState();
}

class _DiaryHistoryCardState extends State<DiaryHistoryCard> {
  bool _isExpanded = false;

  List<InlineSpan> _parseTextWithEmojis(String text, TextStyle style) {
    if (text.isEmpty) return [];
    return EmojiMapping.parseText(text).map((chunk) {
      if (chunk.isEmoji) {
        return WidgetSpan(
          alignment: PlaceholderAlignment.middle,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 2),
            child: Image.asset(
              chunk.emojiPath!,
              width: 18,
              height: 18,
            ),
          ),
        );
      }
      return TextSpan(
        text: chunk.text,
        style: style,
      );
    }).toList();
  }

  List<InlineSpan> _buildRichTextSpans(TextStyle baseStyle, {String? filteredContent}) {
    if (widget.entry.blocks.isEmpty) {
      return _parseTextWithEmojis(filteredContent?.trim() ?? widget.entry.content.trim(), baseStyle);
    }

    final spans = <InlineSpan>[];
    for (var b in widget.entry.blocks) {
      if (b['type'] == 'text') {
        final block = DiaryBlock.fromMap(Map<String, dynamic>.from(b as Map));
        if (block is TextBlock) {
          final controller = block.controller;
          if (controller is TopicTextEditingController) {
            controller.baseColor = baseStyle.color ?? Colors.black;
            controller.baseFontFamily = baseStyle.fontFamily ?? 'LXGWWenKai';
            controller.baseFontSize = baseStyle.fontSize ?? 15.5;

            final span = controller.buildTextSpan(
              context: context,
              style: baseStyle,
              withComposing: false,
            );

            if (span.children != null) {
              spans.addAll(span.children!);
            } else {
              spans.add(span);
            }
          }
          block.dispose();
        }
      }
    }

    // fallback
    if (spans.isEmpty && widget.entry.content.trim().isNotEmpty) {
      return _parseTextWithEmojis(widget.entry.content.trim(), baseStyle);
    }

    return spans;
  }

  @override
  Widget build(BuildContext context) {
    final dateStr =
        "${widget.entry.dateTime.month}/${widget.entry.dateTime.day}";
    final timeStr =
        "${widget.entry.dateTime.hour.toString().padLeft(2, '0')}:${widget.entry.dateTime.minute.toString().padLeft(2, '0')}";
    final timelineLabel = widget.showDate ? "$dateStr\n$timeStr" : timeStr;

    final textStyle = TextStyle(
      fontSize: 15.5,
      color: widget.isNight ? Colors.white70 : Colors.black.withOpacity(0.75),
      height: 1.6,
      fontFamily: 'LXGWWenKai',
    );

    return Stack(
      children: [
        // 贯穿全高的轴线 (处于底层)
        Positioned(
          left: 76,
          top: 0,
          bottom: 0,
          child: Container(
            width: 4,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  widget.isNight ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.05),
                  widget.isNight ? Colors.white.withOpacity(0.01) : Colors.black.withOpacity(0.01),
                ],
              ),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        ),
        // 顶层内容
        GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => DiaryDetailPage(
                  entry: widget.entry,
                  isNight: widget.isNight,
                ),
              ),
            );
          },
          child: Container(
            margin: const EdgeInsets.only(bottom: 16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. 左侧：时刻 (字号加大)
                Container(
                  width: 60,
                  padding: const EdgeInsets.only(top: 14),
                  alignment: Alignment.topRight,
                  child: Text(
                    timelineLabel,
                    textAlign: TextAlign.right,
                    style: TextStyle(
                      fontSize: widget.showDate ? 13 : 15,
                      color: widget.isNight ? Colors.white30 : Colors.black.withOpacity(0.35),
                      fontWeight: FontWeight.w600,
                      fontFamily: 'LXGWWenKai',
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                // 2. 中间：书脊装订轴
                SizedBox(
                  width: 24,
                  child: Column(
                    children: [
                      const SizedBox(height: 20),
                      // 实心装订点
                      Container(
                        width: 10,
                        height: 10,
                        decoration: BoxDecoration(
                          color: widget.isNight ? Colors.white10 : const Color(0xFFC4B69E),
                          shape: BoxShape.circle,
                          boxShadow: widget.isNight
                              ? null
                              : [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.1),
                                    blurRadius: 2,
                                    offset: const Offset(1, 1),
                                  ),
                                ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                  // 右侧内容卡片
                  Expanded(
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 24, right: 8),
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: widget.isNight
                            ? const Color(0xFF383531)
                            : Colors.white,
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(
                          color: widget.isNight
                              ? Colors.white.withOpacity(0.05)
                              : Colors.black.withOpacity(0.03),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(
                              widget.isNight ? 0.35 : 0.12,
                            ),
                            blurRadius: 10,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: _buildMoodBadge(
                                  widget.entry.moodIndex,
                                  widget.entry.intensity,
                                  isNight: widget.isNight,
                                  tag: widget.entry.tag,
                                ),
                              ),
                              if (widget.onShare != null)
                                GestureDetector(
                                  onTap: widget.onShare,
                                  child: Padding(
                                    padding: const EdgeInsets.only(
                                      left: 8,
                                      bottom: 8,
                                    ),
                                    child: Icon(
                                      Icons.ios_share_rounded,
                                      size: 18,
                                      color: widget.isNight
                                          ? Colors.white24
                                          : Colors.black.withOpacity(0.15),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Builder(
                            builder: (context) {
                              final screenWidth = MediaQuery.of(context).size.width;
                              final estimateWidth = screenWidth - 165;

                              final filteredContent = DiaryUtils.getFilteredContent(widget.entry.content);
                              final richSpans = _buildRichTextSpans(textStyle, filteredContent: filteredContent);
                              final displaySpan = TextSpan(children: richSpans);
                              
                              final layoutSpan = TextSpan(
                                text: filteredContent,
                                style: textStyle,
                              );

                              final tp = TextPainter(
                                text: layoutSpan,
                                maxLines: 3,
                                textDirection: TextDirection.ltr,
                              )..layout(
                                maxWidth: estimateWidth > 0 ? estimateWidth : 200,
                              );

                              final bool hasOverflow = tp.didExceedMaxLines;

                              return Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  RichText(
                                    maxLines: _isExpanded ? null : 3,
                                    overflow: _isExpanded ? TextOverflow.visible : TextOverflow.clip,
                                    text: displaySpan,
                                  ),
                                  if (hasOverflow) ...[
                                    const SizedBox(height: 8),
                                    Align(
                                      alignment: Alignment.centerLeft,
                                      child: GestureDetector(
                                        onTap: () {
                                          setState(() {
                                            _isExpanded = !_isExpanded;
                                          });
                                        },
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Text(
                                              _isExpanded ? "收起" : "展开全文",
                                              style: TextStyle(
                                                fontSize: 13,
                                                color: widget.isNight
                                                    ? const Color(0xFFD4A373).withOpacity(0.8)
                                                    : const Color(0xFFD4A373),
                                                fontWeight: FontWeight.bold,
                                                fontFamily: 'LXGWWenKai',
                                              ),
                                            ),
                                            const SizedBox(width: 4),
                                            Icon(
                                              _isExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                                              size: 16,
                                              color: widget.isNight
                                                  ? const Color(0xFFD4A373).withOpacity(0.8)
                                                  : const Color(0xFFD4A373),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ],
                                ],
                              );
                            },
                          ),
                          if (widget.entry.blocks.any((b) => b['type'] == 'image')) ...[
                            const SizedBox(height: 8),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: widget.entry.blocks
                                  .where((b) => b['type'] == 'image')
                                  .take(_isExpanded ? 999 : 4)
                                  .map(
                                    (b) => DiaryUtils.buildImage(
                                      b['path'],
                                      width: 46,
                                      height: 46,
                                      fit: BoxFit.cover,
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                  )
                                  .toList(),
                            ),
                          ],
                          // _buildFooterInfo 现在已经不再需要，因为天气和地点已作为标签展示
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ],
    )
    .animate()
    .fadeIn(delay: (widget.index * 60).ms, duration: 350.ms)
    .moveX(begin: 12, end: 0);
  }

  Widget _buildMoodBadge(
    int moodIndex,
    double intensity, {
    bool isNight = false,
    String? tag,
  }) {
    final moodIdx = moodIndex.clamp(0, kMoods.length - 1);
    final mood = kMoods[moodIdx];
    final Color badgeColor = mood.glowColor ?? const Color(0xFFC4B69E);

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        // 1. 心情标签 (图标 + 纯心情文字)
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: badgeColor.withOpacity(isNight ? 0.15 : 0.18),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Hero(
                tag: 'mood_${widget.entry.id}',
                child: Image.asset(
                  mood.iconPath ?? 'assets/images/icons/sun.png',
                  width: 14,
                  height: 14,
                ),
              ),
              const SizedBox(width: 4),
              Text(
                mood.label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: badgeColor.withOpacity(isNight ? 0.8 : 1.0),
                  fontFamily: 'LXGWWenKai',
                ),
              ),
            ],
          ),
        ),

        // 2. 强度标签 (文字描述)
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: badgeColor.withOpacity(isNight ? 0.08 : 0.12),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: badgeColor.withOpacity(isNight ? 0.2 : 0.25),
              width: 0.5,
            ),
          ),
          child: Text(
            DiaryUtils.getMoodIntensityPrefix(mood.label, intensity),
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: badgeColor.withOpacity(isNight ? 0.6 : 1.0),
              fontFamily: 'LXGWWenKai',
            ),
          ),
        ),

        // 3. 天气标签 (如果有)
        if (widget.entry.weather != null)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: badgeColor.withOpacity(isNight ? 0.08 : 0.12),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: badgeColor.withOpacity(isNight ? 0.2 : 0.25),
                width: 0.5,
              ),
            ),
            child: Text(
              "${widget.entry.weather} ${widget.entry.temp ?? ''}",
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: badgeColor.withOpacity(isNight ? 0.6 : 1.0),
                fontFamily: 'LXGWWenKai',
              ),
            ),
          ),

        // 4. 地点标签 (如果有)
        if (widget.entry.location != null)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: badgeColor.withOpacity(isNight ? 0.08 : 0.12),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: badgeColor.withOpacity(isNight ? 0.2 : 0.25),
                width: 0.5,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.location_on_outlined, size: 10, color: badgeColor.withOpacity(isNight ? 0.6 : 1.0)),
                const SizedBox(width: 2),
                Text(
                  widget.entry.location!,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: badgeColor.withOpacity(isNight ? 0.6 : 1.0),
                    fontFamily: 'LXGWWenKai',
                  ),
                ),
              ],
            ),
          ),

        // 5. 话题标签 (如果有)
        if (tag != null && tag.isNotEmpty)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: isNight
                  ? Colors.white.withOpacity(0.08)
                  : const Color(0xFF8B7763).withOpacity(0.08),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: isNight
                    ? Colors.white12
                    : const Color(0xFF8B7763).withOpacity(0.15),
                width: 0.5,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '#',
                  style: TextStyle(
                    fontSize: 12,
                    color: isNight
                        ? Colors.white38
                        : const Color(0xFF8B7763).withOpacity(0.5),
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(width: 2),
                Text(
                  tag,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: isNight ? Colors.white70 : const Color(0xFF8B7763),
                    fontFamily: 'LXGWWenKai',
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

}
