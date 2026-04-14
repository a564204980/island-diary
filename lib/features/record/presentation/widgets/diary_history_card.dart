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
  final bool isFirst;
  final bool isLast;

  const DiaryHistoryCard({
    super.key,
    required this.entry,
    required this.index,
    this.isFilteredMode = false,
    this.isNight = false,
    this.showDate = false,
    this.isFirst = false,
    this.isLast = false,
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
          if (controller is DiaryTextEditingController) {
            controller.baseColor = baseStyle.color ?? Colors.black;
            controller.baseFontFamily = baseStyle.fontFamily ?? 'LXGWWenKai';
            controller.baseFontSize = baseStyle.fontSize ?? 15.5;

            final span = controller.buildTextSpan(
              context: context,
              style: baseStyle,
              withComposing: false,
              hideMarkdownSymbols: true, // 隐藏 Markdown 符号
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
      color: widget.isNight ? Colors.white70 : Colors.black.withValues(alpha: 0.75),
      height: 1.6,
      fontFamily: 'LXGWWenKai',
    );

    return Stack(
      children: [
        // 贯穿全高的轴线 (处于底层) - 拆分为两段，并避开圆点区域
        // 上半段：从顶部到圆点顶缘 (6px)
        if (!widget.isFirst)
          Positioned(
            left: 76,
            top: 0,
            height: 6, 
            child: _buildTimelineLine(isTop: true),
          ),
        // 下半段：从圆点底缘 (6px padding + 10px 直径 = 16px) 向下延伸
        if (!widget.isLast)
          Positioned(
            left: 76,
            top: 16,
            bottom: 0,
            child: _buildTimelineLine(isTop: false),
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
                  padding: const EdgeInsets.only(top: 6), // 稍微留白，更精致
                  alignment: Alignment.topRight,
                  child: Text(
                    timelineLabel,
                    textAlign: TextAlign.right,
                    style: TextStyle(
                      fontSize: widget.showDate ? 13 : 15,
                      color: widget.isNight ? Colors.white30 : Colors.black.withValues(alpha: 0.35),
                      fontWeight: FontWeight.w600,
                      fontFamily: 'LXGWWenKai',
                    ),
                  ),
                ),
                const SizedBox(width: 6), 
                // 2. 中间：书脊装订轴
                SizedBox(
                  width: 24,
                  child: Column(
                    children: [
                      const SizedBox(height: 6), // 对齐时刻
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
                                    color: Colors.black.withValues(alpha: 0.1),
                                    blurRadius: 2,
                                    offset: const Offset(1, 1),
                                  ),
                                ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 22), // 本来是 12，增加 10px 补偿位置并保持卡片不动
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
                              ? Colors.white.withValues(alpha: 0.05)
                              : Colors.black.withValues(alpha: 0.03),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 
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
                                          : Colors.black.withValues(alpha: 0.15),
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
                                                    ? const Color(0xFFD4A373).withValues(alpha: 0.8)
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
                                                  ? const Color(0xFFD4A373).withValues(alpha: 0.8)
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
                          _buildPhotoGrid(context),
                          const SizedBox(height: 12),
                          // 底部信息行：日期+时刻 (左) & 回复数 (右)
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Builder(
                                builder: (context) {
                                  final dt = widget.entry.dateTime;
                                  final weekDays = ["星期一", "星期二", "星期三", "星期四", "星期五", "星期六", "星期日"];
                                  final weekDay = weekDays[dt.weekday - 1];
                                  final m = dt.month.toString().padLeft(2, '0');
                                  final d = dt.day.toString().padLeft(2, '0');
                                  final dateStr = "${dt.year}/$m/$d $weekDay ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}";
                                  return Text(
                                    dateStr,
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: widget.isNight ? Colors.white24 : Colors.black26,
                                      fontFamily: 'LXGWWenKai',
                                    ),
                                  );
                                },
                              ),
                              if (widget.entry.replies.isNotEmpty)
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.chat_bubble_outline_rounded,
                                      size: 14,
                                      color: widget.isNight ? Colors.white24 : Colors.black26,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      widget.entry.replies.length.toString(),
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: widget.isNight ? Colors.white24 : Colors.black26,
                                        fontFamily: 'LXGWWenKai',
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                            ],
                          ),
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

  Widget _buildPhotoGrid(BuildContext context) {
    final images = widget.entry.blocks.where((b) => b['type'] == 'image').toList();
    if (images.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final double gridWidth = constraints.maxWidth;
          
          if (!widget.entry.isImageGrid) {
            // 普通模式：精致的小图标排列
            return Wrap(
              spacing: 8,
              runSpacing: 8,
              children: images
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
            );
          }

          // 九宫格模式
          if (images.length == 1) {
            // 单张：比例较大的展示
            return ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: DiaryUtils.buildImage(
                images[0]['path'],
                width: gridWidth * 0.7,
                height: gridWidth * 0.5,
                fit: BoxFit.cover,
              ),
            );
          }

          final double spacing = 6;
          final int crossAxisCount = 3; // 无论多少图（除单图外），列表都用 3 列更加整齐
          final double itemSize = (gridWidth - (spacing * (crossAxisCount - 1))) / crossAxisCount;

          return Wrap(
            spacing: spacing,
            runSpacing: spacing,
            children: images.take(9).map((img) {
              return ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: DiaryUtils.buildImage(
                  img['path'],
                  width: itemSize,
                  height: itemSize,
                  fit: BoxFit.cover,
                ),
              );
            }).toList(),
          );
        },
      ),
    );
  }

  Widget _buildTimelineLine({required bool isTop}) {
    return Container(
      width: 4,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            widget.isNight ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.05),
            widget.isNight ? Colors.white.withValues(alpha: 0.01) : Colors.black.withValues(alpha: 0.01),
          ],
        ),
        borderRadius: BorderRadius.circular(2),
      ),
    );
  }

  Widget _buildMoodBadge(
    int moodIndex,
    double intensity, {
    bool isNight = false,
    String? tag,
  }) {
    final hasCustomMood = tag != null && tag.trim().isNotEmpty;
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
            color: badgeColor.withValues(alpha: isNight ? 0.15 : 0.18),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Hero(
                tag: 'mood_${widget.entry.id}',
                child: Image.asset(
                  hasCustomMood 
                      ? 'assets/images/icons/custom.png' 
                      : (mood.iconPath ?? 'assets/images/icons/sun.png'),
                  width: 14,
                  height: 14,
                ),
              ),
              const SizedBox(width: 4),
              Text(
                hasCustomMood ? tag.trim() : mood.label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: badgeColor.withValues(alpha: isNight ? 0.8 : 1.0),
                  fontFamily: 'LXGWWenKai',
                ),
              ),
            ],
          ),
        ),

        // 2. 强度标签 (文字描述)
        // 如果是自定义心情，不再显示基于系统心情名称生成的强度修饰词，避免冲突（如“满心向往”）
        if (!hasCustomMood)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: badgeColor.withValues(alpha: isNight ? 0.08 : 0.12),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: badgeColor.withValues(alpha: isNight ? 0.2 : 0.25),
                width: 0.5,
              ),
            ),
            child: Text(
              DiaryUtils.getMoodIntensityPrefix(mood.label, intensity),
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: badgeColor.withValues(alpha: isNight ? 0.6 : 1.0),
                fontFamily: 'LXGWWenKai',
              ),
            ),
          ),

        // 3. 天气标签 (如果有)
        if (widget.entry.weather != null)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: badgeColor.withValues(alpha: isNight ? 0.08 : 0.12),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: badgeColor.withValues(alpha: isNight ? 0.2 : 0.25),
                width: 0.5,
              ),
            ),
            child: Text(
              "${widget.entry.weather} ${widget.entry.temp ?? ''}",
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: badgeColor.withValues(alpha: isNight ? 0.6 : 1.0),
                fontFamily: 'LXGWWenKai',
              ),
            ),
          ),

        // 4. 地点标签 (如果有)
        if (widget.entry.location != null)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: badgeColor.withValues(alpha: isNight ? 0.08 : 0.12),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: badgeColor.withValues(alpha: isNight ? 0.2 : 0.25),
                width: 0.5,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.location_on_outlined, size: 10, color: badgeColor.withValues(alpha: isNight ? 0.6 : 1.0)),
                const SizedBox(width: 2),
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 160),
                  child: Text(
                    widget.entry.location!,
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: badgeColor.withValues(alpha: isNight ? 0.6 : 1.0),
                      fontFamily: 'LXGWWenKai',
                    ),
                  ),
                ),
              ],
            ),
          ),

        // 5. 话题标签 (如果有)
        // 如果已经作为自定义心情展示在了第一个位置，则此处不再重复展示
        if (!hasCustomMood && tag != null && tag.isNotEmpty)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: isNight
                  ? Colors.white.withValues(alpha: 0.08)
                  : const Color(0xFF8B7763).withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: isNight
                    ? Colors.white12
                    : const Color(0xFF8B7763).withValues(alpha: 0.15),
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
                        : const Color(0xFF8B7763).withValues(alpha: 0.5),
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(width: 2),
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 160),
                  child: Text(
                    tag,
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: isNight ? Colors.white70 : const Color(0xFF8B7763),
                      fontFamily: 'LXGWWenKai',
                    ),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }


}
