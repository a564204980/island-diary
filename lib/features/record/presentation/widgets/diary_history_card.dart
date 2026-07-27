import 'dart:io';
import 'dart:ui';
import 'package:flutter/material.dart';
// Analysis Flush: 强制刷新库摘要以解决 Bad state 错误
import 'package:flutter_animate/flutter_animate.dart';
import 'package:island_diary/features/record/domain/models/diary_entry.dart';
import 'package:island_diary/shared/widgets/diary_entry/utils/diary_utils.dart';
import 'package:island_diary/shared/widgets/mood_picker/config/mood_config.dart';
import 'package:island_diary/shared/widgets/diary_entry/utils/emoji_mapping.dart';
import 'package:island_diary/shared/widgets/diary_entry/models/diary_block.dart';
import 'package:island_diary/shared/widgets/diary_entry/components/diary_image_collage.dart';
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
            child: Image.asset(chunk.emojiPath!, width: 18, height: 18),
          ),
        );
      }
      return TextSpan(text: chunk.text, style: style);
    }).toList();
  }

  List<InlineSpan> _buildRichTextSpans(
    TextStyle baseStyle, {
    String? filteredContent,
  }) {
    if (widget.entry.blocks.isEmpty) {
      return _parseTextWithEmojis(
        filteredContent?.trim() ?? widget.entry.content.trim(),
        baseStyle,
      );
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

    String bgAsset = DiaryUtils.getPaperBackgroundPath(widget.entry.paperStyle, widget.isNight);
    if (bgAsset.isEmpty) {
      bgAsset = widget.isNight
          ? 'assets/images/note/note_night_bg1.png'
          : 'assets/images/note/note_bg1.png';
    }
    precacheImage(AssetImage(bgAsset), context);

    final textStyle = TextStyle(
      fontSize: 15.5,
      color: widget.isNight ? Colors.white70 : Colors.black.withValues(alpha: 0.75),
      height: 1.6,
      fontFamily: 'LXGWWenKai',
    );

    return Stack(
      children: [
        // 贯穿全高的轴线 (处于底层，对齐中心 x = 12)
        if (!widget.isFirst)
          Positioned(
            left: 10.5,
            top: 0,
            height: 32,
            child: _buildTimelineLine(isTop: true),
          ),
        if (!widget.isLast)
          Positioned(
            left: 10.5,
            top: 46,
            bottom: 0,
            child: _buildTimelineLine(isTop: false),
          ),

        // 顶层内容
        GestureDetector(
          behavior: HitTestBehavior.opaque,
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
            margin: const EdgeInsets.only(bottom: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. 节点正上方的时间戳标头 (带有醒目的时钟图标与精致文字)
                Padding(
                  padding: const EdgeInsets.only(left: 2, bottom: 6),
                  child: Row(
                    children: [
                      Text(
                        widget.showDate ? "$dateStr  $timeStr" : timeStr,
                        style: TextStyle(
                          fontSize: 13.5,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'LXGWWenKai',
                          color: widget.isNight
                              ? const Color(0xFFE1AF78)
                              : const Color(0xFF8B7763),
                        ),
                      ),
                      if (widget.entry.imageLayoutStyle == 'chunshan') ...[
                        const SizedBox(width: 6),
                        const Icon(
                          Icons.eco_rounded,
                          size: 12,
                          color: Color(0xFF66BB6A),
                        ),
                      ],
                    ],
                  ),
                ),

                // 2. 时间轴节点与内容卡片 Row
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 左侧同心圆节点 (宽度 24px)
                    SizedBox(
                      width: 24,
                      child: Column(
                        children: [
                          const SizedBox(height: 12),
                          Container(
                            width: 16,
                            height: 16,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: widget.isNight
                                    ? const Color(0xFFE1AF78).withValues(alpha: 0.9)
                                    : const Color(0xFFD4A373),
                                width: 1.5,
                              ),
                            ),
                            child: Container(
                              width: 8,
                              height: 8,
                              decoration: BoxDecoration(
                                color: widget.isNight
                                    ? const Color(0xFFE1AF78).withValues(alpha: 0.9)
                                    : const Color(0xFFD4A373),
                                shape: BoxShape.circle,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),

                    // 右侧内容卡片
                    Expanded(
                      child: Container(
                        margin: const EdgeInsets.only(right: 16),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(20),
                          child: BackdropFilter(
                            filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                              decoration: BoxDecoration(
                                color: widget.isNight
                                    ? Colors.black.withValues(alpha: 0.18)
                                    : Colors.white.withValues(alpha: 0.55),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: widget.isNight
                                      ? Colors.white.withValues(alpha: 0.12)
                                      : Colors.white.withValues(alpha: 0.6),
                                  width: 0.8,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 
                                      widget.isNight ? 0.12 : 0.04,
                                    ),
                                    blurRadius: 10,
                                    offset: const Offset(0, 3),
                                  ),
                                ],
                                image: DecorationImage(
                                  image: AssetImage(bgAsset),
                                  fit: BoxFit.cover,
                                  opacity: widget.isNight ? 0.25 : 0.65,
                                ),
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
                                      final screenWidth = MediaQuery.of(
                                        context,
                                      ).size.width;
                                      final estimateWidth = screenWidth - 165;

                                      final filteredContent =
                                          DiaryUtils.getFilteredContent(
                                            widget.entry.content,
                                          );
                                      final richSpans = _buildRichTextSpans(
                                        textStyle,
                                        filteredContent: filteredContent,
                                      );
                                      final displaySpan = TextSpan(
                                        children: richSpans,
                                      );

                                      final layoutSpan = TextSpan(
                                        text: filteredContent,
                                        style: textStyle,
                                      );

                                      final tp =
                                          TextPainter(
                                            text: layoutSpan,
                                            maxLines: 2,
                                            textDirection: TextDirection.ltr,
                                          )..layout(
                                            maxWidth: estimateWidth > 0
                                                ? estimateWidth
                                                : 200,
                                          );

                                      final bool textOverflow = tp.didExceedMaxLines;
                                      final bool imagesOverflow = !widget.entry.isImageGrid && widget.entry.blocks.where((b) => b['type'] == 'image').length > 4;
                                      final bool hasOverflow = textOverflow || imagesOverflow;

                                      return Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          AnimatedSize(
                                            duration: const Duration(milliseconds: 250),
                                            curve: Curves.easeInOut,
                                            alignment: Alignment.topLeft,
                                            child: RichText(
                                              maxLines: (hasOverflow && _isExpanded) ? null : 2,
                                              overflow: (hasOverflow && _isExpanded)
                                                  ? TextOverflow.visible
                                                  : TextOverflow.clip,
                                              text: displaySpan,
                                            ),
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
                                                            ? const Color(
                                                                0xFFD4A373,
                                                              ).withValues(alpha: 0.8)
                                                            : const Color(0xFFD4A373),
                                                        fontWeight: FontWeight.bold,
                                                        fontFamily: 'LXGWWenKai',
                                                      ),
                                                    ),
                                                    const SizedBox(width: 4),
                                                    AnimatedRotation(
                                                      turns: _isExpanded ? 0.5 : 0.0,
                                                      duration: const Duration(milliseconds: 200),
                                                      child: Icon(
                                                        Icons.keyboard_arrow_down,
                                                        size: 16,
                                                        color: widget.isNight
                                                            ? const Color(
                                                                0xFFD4A373,
                                                              ).withValues(alpha: 0.8)
                                                            : const Color(0xFFD4A373),
                                                      ),
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
                                          final weekDays = [
                                            "星期一",
                                            "星期二",
                                            "星期三",
                                            "星期四",
                                            "星期五",
                                            "星期六",
                                            "星期日",
                                          ];
                                          final weekDay = weekDays[dt.weekday - 1];
                                          final m = dt.month.toString().padLeft(
                                            2,
                                            '0',
                                          );
                                          final d = dt.day.toString().padLeft(2, '0');
                                          final dateStr =
                                              "${dt.year}/$m/$d $weekDay ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}";
                                          return Text(
                                            dateStr,
                                            style: TextStyle(
                                              fontSize: 11,
                                              color: widget.isNight
                                                  ? Colors.white24
                                                  : Colors.black26,
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
                                              color: widget.isNight
                                                  ? Colors.white24
                                                  : Colors.black26,
                                            ),
                                            const SizedBox(width: 4),
                                            Text(
                                              widget.entry.replies.length.toString(),
                                              style: TextStyle(
                                                fontSize: 12,
                                                color: widget.isNight
                                                    ? Colors.white24
                                                    : Colors.black26,
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
                        ),
                      ),
                    ),
                  ],
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
    final images = widget.entry.blocks
        .where((b) => b['type'] == 'image')
        .toList();
    if (images.isEmpty) return const SizedBox.shrink();

    return LayoutBuilder(
        builder: (context, constraints) {
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
          if (images.length <= 3) {
            final paths = images.map((img) => img['path'] as String).toList();
            return DiaryImageCollage(
              imagePaths: paths,
              spacing: 6.0,
              borderRadius: 8.0,
            );
          }

          // 超过3张：只显示前3张，第3张加遮罩+剩余数量
          final double spacing = 6;
          final displayImages = images.take(3).toList();
          final remaining = images.length - 3;

          return Row(
            spacing: spacing,
            children: List.generate(3, (index) {
              final img = displayImages[index];
              final isLast = index == 2;
              return Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: AspectRatio(
                    aspectRatio: 1.0, // 保持正方形
                    child: Stack(
                      children: [
                        Positioned.fill(
                          child: DiaryUtils.buildImage(
                            img['path'],
                            fit: BoxFit.cover,
                          ),
                        ),
                        if (isLast)
                          Positioned.fill(
                            child: Container(
                              color: Colors.black.withValues(alpha: 0.45),
                              child: Center(
                                child: Text(
                                  '+$remaining',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 18,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              );
            }),
          );
        },
      );
    }

  Widget _buildTimelineLine({required bool isTop}) {
    return Container(
      width: 3,
      decoration: BoxDecoration(
        color: widget.isNight
            ? const Color(0xFFE1AF78).withValues(alpha: 0.15)
            : const Color(0xFFD4A373).withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(1.5),
      ),
    );
  }

  Widget _buildMoodBadge(
    int moodIndex,
    double intensity, {
    bool isNight = false,
    String? tag,
  }) {
    final parsed = ParsedTags.parse(tag, moodIndex);
    final moodIdx = moodIndex.clamp(0, kMoods.length - 1);
    final mood = kMoods[moodIdx];
    final String moodLabel = parsed.customMood ?? mood.label;
    final String iconPath = mood.iconPath ?? 'assets/icons/happy.png';

    final bool hasCustomIcon = parsed.customMoodIconPath != null && parsed.customMoodIconPath!.isNotEmpty;

    Widget buildGlassPill(Widget child) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(100),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4.5),
            decoration: BoxDecoration(
              color: isNight
                  ? Colors.white.withValues(alpha: 0.12)
                  : Colors.white.withValues(alpha: 0.42),
              borderRadius: BorderRadius.circular(100),
              border: Border.all(
                color: isNight
                    ? Colors.white.withValues(alpha: 0.22)
                    : Colors.white.withValues(alpha: 0.55),
                width: 0.8,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 4,
                  offset: const Offset(0, 1.5),
                ),
              ],
            ),
            child: child,
          ),
        ),
      );
    }

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        // 1. 心情标签 (表情图片 + 心情文字)
        buildGlassPill(
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              hasCustomIcon
                  ? Image.file(
                      File(parsed.customMoodIconPath!),
                      width: 14,
                      height: 14,
                      errorBuilder: (c, e, s) => Icon(
                        Icons.mood,
                        size: 14,
                        color: isNight ? Colors.white70 : const Color(0xFF5C5C5C),
                      ),
                    )
                  : Image.asset(
                      iconPath,
                      width: 14,
                      height: 14,
                      errorBuilder: (c, e, s) => Icon(
                        Icons.mood,
                        size: 14,
                        color: isNight ? Colors.white70 : const Color(0xFF5C5C5C),
                      ),
                    ),
              const SizedBox(width: 4),
              Text(
                moodLabel,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: isNight ? Colors.white.withValues(alpha: 0.9) : const Color(0xFF4A3E37),
                  fontFamily: 'LXGWWenKai',
                ),
              ),
            ],
          ),
        ),

        // 3. 天气标签 (如果有)
        if (widget.entry.weather != null)
          buildGlassPill(
            Text(
              "${widget.entry.weather} ${widget.entry.temp ?? ''}",
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: isNight ? Colors.white.withValues(alpha: 0.85) : const Color(0xFF4A3E37),
                fontFamily: 'LXGWWenKai',
              ),
            ),
          ),

        // 4. 地点标签 (如果有)
        if (widget.entry.location != null)
          buildGlassPill(
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.location_on_outlined,
                  size: 11,
                  color: isNight ? Colors.white70 : const Color(0xFF4A3E37),
                ),
                const SizedBox(width: 2),
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 160),
                  child: Text(
                    widget.entry.location!,
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: isNight ? Colors.white.withValues(alpha: 0.85) : const Color(0xFF4A3E37),
                      fontFamily: 'LXGWWenKai',
                    ),
                  ),
                ),
              ],
            ),
          ),

        // 5. 话题标签 (如果有)
        ...parsed.tags.map((singleTag) => buildGlassPill(
              Text(
                '#$singleTag',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: isNight
                      ? Colors.white.withValues(alpha: 0.85)
                      : const Color(0xFF4A3E37),
                  fontFamily: 'LXGWWenKai',
                ),
              ),
            )),
      ],
    );
  }
}
