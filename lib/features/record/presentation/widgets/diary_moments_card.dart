import 'package:flutter/material.dart';
import 'package:island_diary/features/record/domain/models/diary_entry.dart';
import 'package:island_diary/shared/widgets/diary_entry/utils/diary_utils.dart';
import 'package:island_diary/shared/widgets/mood_picker/config/mood_config.dart';
import 'package:island_diary/shared/widgets/sprite_animation.dart';
import 'package:island_diary/shared/widgets/diary_entry/utils/emoji_mapping.dart';
import 'package:island_diary/shared/widgets/diary_entry/models/diary_block.dart';

class DiaryMomentsCard extends StatefulWidget {
  final DiaryEntry entry;
  final bool isNight;
  final String userName;

  const DiaryMomentsCard({
    super.key,
    required this.entry,
    this.isNight = false,
    this.userName = "我",
  });

  @override
  State<DiaryMomentsCard> createState() => _DiaryMomentsCardState();
}

class _DiaryMomentsCardState extends State<DiaryMomentsCard> {
  bool _isExpanded = false;

  String _getMoodAnimation(int moodIndex) {
    // 映射心情 ID 到对应的史莱姆动画
    // 0: 期待, 1: 厌恶, 2: 恐惧, 3: 惊喜, 4: 平静, 5: 愤怒, 6: 悲伤, 7: 开心
    if (moodIndex == 7) return 'assets/images/emoji/weixiao.png'; // 开心
    if (moodIndex == 3) return 'assets/images/emoji/daxiao.png';  // 惊喜 -> 大笑
    if (moodIndex == 6) return 'assets/images/emoji/nanguo.png';  // 悲伤 -> 南过
    if (moodIndex == 1 || moodIndex == 5) return 'assets/images/emoji/sikao.png'; // 愤怒/厌恶 -> 思考
    return 'assets/images/emoji/weixiao.png'; // 默认微笑
  }

  List<InlineSpan> _buildRichTextSpans(TextStyle baseStyle) {
    if (widget.entry.blocks.isEmpty) {
      final filteredContent = DiaryUtils.getFilteredContent(widget.entry.content);
      return EmojiMapping.parseText(filteredContent).map((chunk) {
        if (chunk.isEmoji) {
          return WidgetSpan(
            alignment: PlaceholderAlignment.middle,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 2),
              child: Image.asset(chunk.emojiPath!, width: 18, height: 18),
            ),
          );
        }
        return TextSpan(text: chunk.text, style: baseStyle);
      }).toList();
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
            controller.baseFontSize = baseStyle.fontSize ?? 15.0;
            final span = controller.buildTextSpan(
              context: context,
              style: baseStyle,
              withComposing: false,
              hideMarkdownSymbols: true,
            );
            if (span.children != null) spans.addAll(span.children!);
            else spans.add(span);
          }
          block.dispose();
        }
      }
    }
    return spans;
  }

  @override
  Widget build(BuildContext context) {
    final textStyle = TextStyle(
      fontSize: 15.0,
      color: widget.isNight ? Colors.white70 : Colors.black.withOpacity(0.85),
      height: 1.5,
      fontFamily: 'LXGWWenKai',
    );

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: widget.isNight ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.05),
            width: 0.5,
          ),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. 左侧：动态头像
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: widget.isNight ? const Color(0xFF2C2E30) : const Color(0xFFFDF9F0),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Center(
              child: SpriteAnimation(
                assetPath: _getMoodAnimation(widget.entry.moodIndex),
                frameCount: 9,
                duration: const Duration(milliseconds: 1000),
                size: 36.0,
                isPlaying: true,
              ),
            ),
          ),
          const SizedBox(width: 12),

          // 2. 右侧主体
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 昵称
                Text(
                  widget.userName.isEmpty ? "我" : widget.userName,
                  style: const TextStyle(
                    color: Color(0xFF576B95),
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                    fontFamily: 'LXGWWenKai',
                  ),
                ),
                const SizedBox(height: 6),

                // 正文
                RichText(
                  maxLines: _isExpanded ? null : 6,
                  overflow: _isExpanded ? TextOverflow.visible : TextOverflow.ellipsis,
                  text: TextSpan(children: _buildRichTextSpans(textStyle)),
                ),

                // 展开/收起 (如果有需要)
                
                // 图片展示 (九宫格)
                _buildPhotoGrid(),

                const SizedBox(height: 8),

                // 心情话题标签 (模拟朋友圈位置)
                _buildMoodTags(),

                const SizedBox(height: 8),

                // 底部时间与互动
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      _formatTime(widget.entry.dateTime),
                      style: TextStyle(
                        fontSize: 11,
                        color: widget.isNight ? Colors.white24 : Colors.black26,
                        fontFamily: 'LXGWWenKai',
                      ),
                    ),
                    Icon(
                      Icons.more_horiz_rounded,
                      size: 20,
                      color: widget.isNight ? Colors.white30 : const Color(0xFF576B95).withOpacity(0.6),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatTime(DateTime dt) {
    final now = DateTime.now();
    if (now.year == dt.year && now.month == dt.month && now.day == dt.day) {
      return "今天 ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}";
    }
    return "${dt.month}月${dt.day}日 ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}";
  }

  Widget _buildPhotoGrid() {
    final images = widget.entry.blocks.where((b) => b['type'] == 'image').toList();
    if (images.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final double gridWidth = constraints.maxWidth * 0.9;
          if (images.length == 1) {
             // 单张图大图
             return ClipRRect(
               borderRadius: BorderRadius.circular(4),
               child: DiaryUtils.buildImage(
                 images[0]['path'],
                 width: gridWidth * 0.6,
                 height: gridWidth * 0.6,
                 fit: BoxFit.cover,
               ),
             );
          }

          final int crossAxisCount = (images.length == 4) ? 2 : 3;
          final double spacing = 4.0;
          final double itemSize = (gridWidth - (spacing * (crossAxisCount - 1))) / crossAxisCount;

          return Wrap(
            spacing: spacing,
            runSpacing: spacing,
            children: images.take(9).map((img) {
              return ClipRRect(
                borderRadius: BorderRadius.circular(2),
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

  Widget _buildMoodTags() {
    final moodIdx = widget.entry.moodIndex.clamp(0, kMoods.length - 1);
    final mood = kMoods[moodIdx];
    final Color tagColor = (mood.glowColor ?? const Color(0xFF576B95)).withOpacity(0.7);

    return Wrap(
      spacing: 6,
      children: [
        if (widget.entry.tag != null && widget.entry.tag!.isNotEmpty)
          Text(
            "#${widget.entry.tag}",
            style: const TextStyle(
              color: Color(0xFF576B95),
              fontSize: 12,
              fontFamily: 'LXGWWenKai',
            ),
          ),
        Text(
          mood.label,
          style: TextStyle(
            color: tagColor,
            fontSize: 12,
            fontWeight: FontWeight.w500,
            fontFamily: 'LXGWWenKai',
          ),
        ),
      ],
    );
  }
}
