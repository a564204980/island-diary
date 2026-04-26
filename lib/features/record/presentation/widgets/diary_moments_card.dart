import 'package:flutter/material.dart';
// Analysis Flush: 强制刷新库摘要以解决 Bad state 错误
import 'package:island_diary/features/record/domain/models/diary_entry.dart';
import 'package:island_diary/shared/widgets/diary_entry/utils/diary_utils.dart';
import 'package:island_diary/shared/widgets/mood_picker/config/mood_config.dart';
import 'package:island_diary/shared/widgets/static_sprite.dart';
import 'package:island_diary/shared/widgets/diary_entry/utils/emoji_mapping.dart';
import 'package:island_diary/features/record/presentation/pages/diary_editor_page.dart';
import 'package:island_diary/core/state/user_state.dart';
import 'package:island_diary/shared/widgets/diary_entry/models/diary_block.dart';
import 'moments_interaction_popover.dart';
import 'moments_reply_dialog.dart';

class DiaryMomentsCard extends StatefulWidget {
  final DiaryEntry entry;
  final bool isNight;
  final String userName;

  const DiaryMomentsCard({
    super.key,
    required this.entry,
    this.isNight = false,
    this.userName = '我',
  });

  @override
  State<DiaryMomentsCard> createState() => _DiaryMomentsCardState();
}

class _DiaryMomentsCardState extends State<DiaryMomentsCard> {
  bool _isExpanded = false;
  final LayerLink _layerLink = LayerLink();
  OverlayEntry? _overlayEntry;

  @override
  void dispose() {
    _hidePopover();
    super.dispose();
  }

  void _togglePopover() {
    if (_overlayEntry != null) {
      _hidePopover();
    } else {
      _showInteractionPopover();
    }
  }

  void _hidePopover() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }

  void _showInteractionPopover() {
    _overlayEntry = OverlayEntry(
      builder: (context) => Stack(
        children: [
          // 全屏遮罩，用于点击外部自动收起
          GestureDetector(
            onTap: _hidePopover,
            behavior: HitTestBehavior.translucent,
            child: Container(color: Colors.transparent),
          ),
          Positioned(
            width: 320, // 增加宽度以容纳 4 个功能项，防止溢出
            child: CompositedTransformFollower(
              link: _layerLink,
              showWhenUnlinked: false,
              targetAnchor: Alignment.centerLeft,
              followerAnchor: Alignment.centerRight,
              offset: const Offset(-10, -10), // 向左微调并微调高度
              child: Material(
                color: Colors.transparent,
                child: MomentsInteractionPopover(
                  isLiked: widget.entry.isLiked,
                  onLike: _handleLike,
                  onComment: _handleReply,
                  onEdit: _handleEdit,
                  onDelete: _handleDelete,
                  isNight: widget.isNight,
                ),
              ),
            ),
          ),
        ],
      ),
    );
    Overlay.of(context).insert(_overlayEntry!);
  }

  void _handleLike() async {
    await UserState().toggleLike(widget.entry.id);
    _hidePopover();
    if (mounted) setState(() {});
  }

  void _handleReply() {
    _hidePopover();
    _showReplyDialog();
  }

  void _handleEdit() {
    _hidePopover();
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => DiaryEditorPage(
          moodIndex: widget.entry.moodIndex,
          intensity: widget.entry.intensity,
          tag: widget.entry.tag,
          entry: widget.entry,
        ),
      ),
    );
  }

  void _handleDelete() {
    _hidePopover();
    showDialog(
      context: context,
      builder: (context) => MomentsConfirmDialog(
        title: '确认删除',
        content: '这段记忆将被永久抹去，确认要删除吗？',
        confirmText: '确认删除',
        isNight: widget.isNight,
        onConfirm: () async {
          await UserState().deleteDiary(widget.entry.id);
        },
      ),
    );
  }

  void _showReplyDialog() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => MomentsReplySheet(
        isNight: widget.isNight,
        onConfirm: (text) async {
          await UserState().addReplyToDiary(widget.entry.id, text);
        },
      ),
    );
  }

  String _getMoodAnimation(int moodIndex) {
    // 关键重构：按照需求，目前全站统一使用 marshmallow.png 作为小软的静态形象
    return 'assets/images/emoji/marshmallow.png';
  }

  List<InlineSpan> _buildRichTextSpans(TextStyle baseStyle) {
    if (widget.entry.blocks.isEmpty) {
      final filteredContent = DiaryUtils.getFilteredContent(
        widget.entry.content,
      );
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
    return spans;
  }

  @override
  Widget build(BuildContext context) {
    final textStyle = TextStyle(
      fontSize: 15.0,
      color: widget.isNight ? Colors.white.withValues(alpha: 0.9) : Colors.black.withValues(alpha: 0.85),
      height: 1.5,
      fontFamily: 'LXGWWenKai',
    );

    final bool isWide = MediaQuery.of(context).size.width > 800;

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isWide ? 20 : 16,
        vertical: isWide ? 16 : 12,
      ),
      decoration: BoxDecoration(
        color: widget.isNight ? const Color(0xFF212831) : Colors.white,
        border: Border(
          bottom: BorderSide(
            color: widget.isNight
                ? Colors.white.withValues(alpha: 0.05)
                : Colors.black.withValues(alpha: 0.03),
            width: 1,
          ),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. 左侧：动态头像
          Container(
            width: isWide ? 52 : 44,
            height: isWide ? 52 : 44,
            decoration: BoxDecoration(
              color: widget.isNight
                  ? const Color(0xFF2C2E30)
                  : const Color(0xFFFDF9F0),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Center(
              child: ListenableBuilder(
                listenable: Listenable.merge([
                  UserState().selectedMascotDecoration,
                  UserState().selectedGlassesDecoration,
                ]),
                builder: (context, _) {
                  return StaticSprite(
                    assetPath: _getMoodAnimation(widget.entry.moodIndex),
                    size: isWide ? 42.0 : 36.0,
                  );
                },
              ),
            ),
          ),
          SizedBox(width: isWide ? 16 : 12),

          // 2. 右侧主体
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 昵称
                Text(
                  widget.userName.isEmpty ? '我' : widget.userName,
                  style: const TextStyle(
                    color: Color(0xFF576B95),
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                    fontFamily: 'LXGWWenKai',
                  ),
                ),
                const SizedBox(height: 6),

                Builder(
                  builder: (context) {
                    final screenWidth = MediaQuery.of(context).size.width;
                    final estimateWidth = screenWidth - 100; // 减去头像和间距

                    final richSpans = _buildRichTextSpans(textStyle);
                    final displaySpan = TextSpan(children: richSpans);

                    final tp =
                        TextPainter(
                          text: displaySpan,
                          maxLines: 6,
                          textDirection: TextDirection.ltr,
                        )..layout(
                          maxWidth: estimateWidth > 0 ? estimateWidth : 200,
                        );

                    final bool hasOverflow = tp.didExceedMaxLines;

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        RichText(
                          maxLines: _isExpanded ? null : 6,
                          overflow: _isExpanded
                              ? TextOverflow.visible
                              : TextOverflow.clip,
                          text: displaySpan,
                        ),
                        if (hasOverflow) ...[
                          const SizedBox(height: 4),
                          GestureDetector(
                            onTap: () =>
                                setState(() => _isExpanded = !_isExpanded),
                            child: Text(
                              _isExpanded ? '收起' : '全文',
                              style: const TextStyle(
                                color: Color(0xFF576B95),
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                fontFamily: 'LXGWWenKai',
                              ),
                            ),
                          ),
                        ],
                      ],
                    );
                  },
                ),

                // 图片展示（九宫格）
                _buildPhotoGrid(),

                const SizedBox(height: 8),

                // 心情话题标签（模拟朋友圈位置）
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
                    CompositedTransformTarget(
                      link: _layerLink,
                      child: GestureDetector(
                        onTap: _togglePopover,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          child: Icon(
                            Icons.more_horiz_rounded,
                            size: 20,
                            color: widget.isNight
                                ? Colors.white30
                                : const Color(0xFF576B95).withValues(alpha: 0.6),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                if (widget.entry.isLiked ||
                    widget.entry.replies.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  _buildReplyList(),
                ],
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
    final images = widget.entry.blocks
        .where((b) => b['type'] == 'image')
        .toList();
    if (images.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final double totalWidth = constraints.maxWidth;
          final int crossAxisCount = (images.length == 4) ? 2 : 3;
          final bool isWide = MediaQuery.of(context).size.width > 800;
          final double spacing = isWide ? 8.0 : 4.0;

          // 更稳健的尺寸计算：手动预留 2.0 像素的排版误差空间
          final double itemSize =
              (totalWidth - (spacing * (crossAxisCount - 1)) - 2.0) /
              crossAxisCount;

          if (images.length == 1) {
            final double singleImageSize = isWide ? 240.0 : totalWidth * 0.45;
            return ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: DiaryUtils.buildImage(
                images[0]['path'] ?? '',
                width: singleImageSize,
                height: isWide ? 240.0 : singleImageSize,
                fit: BoxFit.cover,
              ),
            );
          }

          return GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            padding: EdgeInsets.zero,
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: crossAxisCount,
              mainAxisSpacing: spacing,
              crossAxisSpacing: spacing,
            ),
            itemCount: images.length > 9 ? 9 : images.length,
            itemBuilder: (context, index) {
              return ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: DiaryUtils.buildImage(
                  images[index]['path'] ?? '',
                  width: itemSize,
                  height: itemSize,
                  fit: BoxFit.cover,
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildMoodTags() {
    final moodIdx = widget.entry.moodIndex.clamp(0, kMoods.length - 1);
    final mood = kMoods[moodIdx];
    final Color baseColor = (mood.glowColor ?? const Color(0xFF576B95));
    final Color tagColor = widget.isNight
        ? baseColor.withValues(alpha: 0.9)
        : baseColor;

    return Wrap(
      spacing: 8,
      runSpacing: 6,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        // 1. 心情标签（必选）
        _buildTagPill(
          icon: mood.iconPath != null
              ? Image.asset(
                  mood.iconPath!,
                  width: 12,
                  height: 12,
                  color: tagColor.withValues(alpha: 0.8),
                  fit: BoxFit.contain,
                )
              : null,
          label: mood.label,
          color: tagColor,
          isPill: true,
        ),

        // 2. 天气标签（可选）
        if (widget.entry.weather != null && widget.entry.weather!.isNotEmpty)
          _buildTagPill(
            icon: Icon(
              _getWeatherIcon(widget.entry.weather!),
              size: 13,
              color: (widget.isNight ? Colors.white70 : Colors.black45),
            ),
            label:
                "${widget.entry.weather}${widget.entry.temp != null ? ' ${widget.entry.temp}°' : ''}",
            color: widget.isNight ? Colors.white54 : Colors.black45,
          ),

        // 3. 地点标签（可选）
        if (widget.entry.location != null && widget.entry.location!.isNotEmpty)
          _buildTagPill(
            icon: Icon(
              Icons.location_on_rounded,
              size: 12,
              color: const Color(0xFF576B95).withValues(alpha: 0.7),
            ),
            label: widget.entry.location!,
            color: const Color(0xFF576B95),
          ),

        // 4. 自定义话题标签（可选）
        if (widget.entry.tag != null && widget.entry.tag!.isNotEmpty)
          _buildTagPill(
            label: "#${widget.entry.tag}",
            color: const Color(0xFF576B95),
            isBold: true,
            bgColorAlpha: 0.08,
            borderRadius: 4,
          ),
      ],
    );
  }

  Widget _buildTagPill({
    Widget? icon,
    required String label,
    required Color color,
    bool isPill = false,
    bool isBold = false,
    double bgColorAlpha = 0.1,
    double borderRadius = 100,
  }) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: isPill ? 10 : 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(
          alpha: widget.isNight ? bgColorAlpha * 1.5 : bgColorAlpha,
        ),
        borderRadius: BorderRadius.circular(isPill ? 100 : borderRadius),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[icon, const SizedBox(width: 4)],
          Text(
            label,
            style: TextStyle(
              color: color.withValues(alpha: widget.isNight ? 0.7 : 0.8),
              fontSize: 11,
              fontWeight: isBold ? FontWeight.bold : FontWeight.w500,
              fontFamily: 'LXGWWenKai',
            ),
          ),
        ],
      ),
    );
  }

  IconData _getWeatherIcon(String weather) {
    if (weather.contains('晴')) return Icons.wb_sunny_rounded;
    if (weather.contains('阴') || weather.contains('云'))
      return Icons.wb_cloudy_rounded;
    if (weather.contains('雨')) return Icons.umbrella_rounded;
    if (weather.contains('雪')) return Icons.ac_unit_rounded;
    return Icons.wb_sunny_outlined;
  }

  Widget _buildReplyList() {
    final bool hasLikes = widget.entry.isLiked;
    final bool hasReplies = widget.entry.replies.isNotEmpty;

    if (!hasLikes && !hasReplies) return const SizedBox.shrink();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      decoration: BoxDecoration(
        color: widget.isNight
            ? Colors.white.withValues(alpha: 0.06)
            : const Color(0xFFF3F3F5),
        borderRadius: BorderRadius.circular(8),
        border: widget.isNight
            ? Border.all(color: Colors.white.withValues(alpha: 0.05))
            : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. 点赞区
          if (hasLikes)
            Padding(
              padding: EdgeInsets.only(bottom: hasReplies ? 6 : 0),
              child: Row(
                children: [
                  const Icon(
                    Icons.favorite_border_rounded,
                    size: 14,
                    color: Color(0xFF576B95),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    widget.userName.isEmpty ? '我' : widget.userName,
                    style: const TextStyle(
                      color: Color(0xFF576B95),
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                      fontFamily: 'LXGWWenKai',
                    ),
                  ),
                ],
              ),
            ),

          // 2. 分隔线（如果既有点赞又有回复）
          if (hasLikes && hasReplies)
            Divider(
              height: 12,
              thickness: 0.5,
              color: widget.isNight
                  ? Colors.white10
                  : Colors.black.withValues(alpha: 0.05),
            ),

          // 3. 回复列表
          ...widget.entry.replies.map((reply) {
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 2),
              child: RichText(
                text: TextSpan(
                  style: TextStyle(
                    fontSize: 13,
                    color: widget.isNight ? Colors.white70 : Colors.black87,
                    fontFamily: 'LXGWWenKai',
                    height: 1.4,
                  ),
                  children: [
                    TextSpan(
                      text:
                          '${widget.userName.isEmpty ? '我' : widget.userName}: ',
                      style: const TextStyle(
                        color: Color(0xFF576B95),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    TextSpan(text: reply.content),
                  ],
                ),
              ),
            );
          }),
        ],
      ),
    );
  }
}
