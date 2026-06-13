import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:island_diary/core/state/user_state.dart';
import 'package:island_diary/shared/widgets/diary_entry/utils/diary_utils.dart';
import 'package:island_diary/shared/widgets/diary_entry/models/diary_block.dart';

class EditorBottomBar extends StatelessWidget {
  final bool isEmojiOpen;
  final bool isNight;
  final String paperStyle;
  final Color accentColor;
  final double currentBottomHeight;
  final List<DiaryBlock> blocks;
  final bool isMixedLayout;

  final VoidCallback onEmojiToggle;
  final VoidCallback onImagePick;

  // 工具栏回调
  final VoidCallback onColorClick;
  final VoidCallback onBgColorClick;
  final VoidCallback onLocationClick;
  final VoidCallback onFontSizeClick;
  final VoidCallback onFontClick;
  final VoidCallback onDateClick;
  final VoidCallback onTimeClick;
  final VoidCallback onWeatherClick;
  final VoidCallback onMoreClick;
  final VoidCallback onClose;
  final VoidCallback onSave;

  final VoidCallback? onTagClick;
  final VoidCallback? onMusicPick;
  final List<String> currentTags;
  final Function(String)? onRemoveTag;

  // 表情面板回调
  final Function(String) onEmojiSelected;
  final VoidCallback onEmojiBackspace;
  final VoidCallback onEmojiSend;
  final Function(String) onCustomEmojiSelected;
  
  // 图片预览回调
  final Function(int) onRemoveImage;

  const EditorBottomBar({
    super.key,
    required this.isEmojiOpen,
    required this.isNight,
    required this.paperStyle,
    required this.accentColor,
    required this.currentBottomHeight,
    required this.blocks,
    required this.isMixedLayout,
    required this.onEmojiToggle,
    required this.onImagePick,
    required this.onColorClick,
    required this.onBgColorClick,
    required this.onLocationClick,
    required this.onFontSizeClick,
    required this.onFontClick,
    required this.onDateClick,
    required this.onTimeClick,
    required this.onWeatherClick,
    required this.onMoreClick,
    required this.onClose,
    required this.onSave,
    this.onTagClick,
    this.onMusicPick,
    this.currentTags = const [],
    this.onRemoveTag,
    required this.onEmojiSelected,
    required this.onEmojiBackspace,
    required this.onEmojiSend,
    required this.onCustomEmojiSelected,
    required this.onRemoveImage,
  });

  @override
  Widget build(BuildContext context) {
    // 注意：不在此处读取 paddingOf / viewInsets，避免订阅后每帧重建
    // safeAreaBottom 改由底部独立 Builder 读取（见下方）
    final double screenWidth = MediaQuery.sizeOf(context).width;
    final bool isWide = screenWidth > 800;
    final double toolbarMaxWidth = isWide ? 800.0 : double.infinity;

    final themeId = UserState().selectedIslandThemeId.value;
    final bool hasPaper = paperStyle.startsWith('note') || 
        (paperStyle == 'classic' && themeId == 'cotton_candy');

    // 动态色彩配置（支持深色/浅色模式）
    final Color baseColor = isNight 
        ? const Color(0xFF141426) 
        : const Color(0xFFFAF9F6);

    final Color barBgColor = hasPaper 
        ? baseColor.withValues(alpha: 0.9) 
        : baseColor;

    final Color iconColor = isNight
        ? Colors.white70
        : Colors.black87;

    Widget bottomBarContent = Container(
      margin: EdgeInsets.zero,
      width: toolbarMaxWidth,
      decoration: BoxDecoration(
        color: barBgColor,
        borderRadius: BorderRadius.zero,
      ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 标签 chip 行（仅有标签时显示）
            if (currentTags.isNotEmpty) _buildTagBar(),

            // 图片上传预览条 (仅在非混排模式下显示图片列表)
            if (!isMixedLayout)
              _buildImageUploadPreviewBar(),
              
            // 工具栏主内容
            Container(
              height: 52,
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Row(
                children: [
                  // 左侧工具图标组，水平滑动以防小屏溢出
                  Expanded(
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      physics: const ClampingScrollPhysics(),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const SizedBox(width: 4),
                          // 1. A 按钮 (文字样式)
                          _buildTextButton(iconColor),
                          const SizedBox(width: 4),
                          // 2. 标签按钮（带角标）
                          _buildTagIconWithBadge(context, iconColor),
                          const SizedBox(width: 4),
                          // 3. 图片
                          _buildToolbarIcon(Icons.image_outlined, onImagePick, iconColor),
                          const SizedBox(width: 4),
                          // 4. 地点定位
                          _buildToolbarIcon(Icons.location_on_outlined, onLocationClick, iconColor),
                          const SizedBox(width: 4),
                          // 5. 调色盘 (背景模板)
                          _buildToolbarIcon(Icons.palette_outlined, onBgColorClick, iconColor),
                          const SizedBox(width: 4),
                          // 6. 麦克风 (语音输入)
                          _buildToolbarIcon(Icons.mic_none_outlined, () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('语音输入功能开发中...')),
                            );
                          }, iconColor),
                          const SizedBox(width: 4),
                          // 7. 太阳 (天气)
                          _buildToolbarIcon(Icons.wb_sunny_outlined, onWeatherClick, iconColor),
                          const SizedBox(width: 4),
                          // 8. 设置
                          _buildToolbarIcon(Icons.settings_outlined, onMoreClick, iconColor),
                          const SizedBox(width: 4),
                          // 9. 笑脸 (表情)
                          _buildToolbarIcon(
                            isEmojiOpen ? Icons.keyboard_alt_outlined : Icons.sentiment_satisfied_alt_outlined,
                            onEmojiToggle,
                            iconColor,
                          ),
                          const SizedBox(width: 8),
                        ],
                      ),
                    ),
                  ),
                  
                  // 右侧保存确认按钮
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: GestureDetector(
                      onTap: onSave,
                      child: Container(
                        width: 46,
                        height: 32,
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFF0E5),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: const Center(
                          child: Icon(
                            Icons.check_rounded,
                            color: Color(0xFFFA6400),
                            size: 20,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // 用独立 Builder 读取 paddingOf，仅此 SizedBox 重建，不影响整个工具栏
            Builder(
              builder: (ctx) {
                final double safeArea = MediaQuery.paddingOf(ctx).bottom;
                return SizedBox(height: safeArea);
              },
            ),
          ],
        ),
    );

    if (hasPaper) {
      return ClipRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: bottomBarContent,
        ),
      );
    }
    return bottomBarContent;
  }

  Widget _buildTagIconWithBadge(BuildContext context, Color iconColor) {
    final count = currentTags.length;
    return InkWell(
      onTap: () {
        if (onTagClick != null) {
          onTagClick!();
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('标签功能开发中...')),
          );
        }
      },
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.all(8),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Icon(
              Icons.local_offer_outlined,
              size: 22,
              color: count > 0
                  ? const Color(0xFFFA6400)
                  : iconColor.withValues(alpha: 0.8),
            ),
            if (count > 0)
              Positioned(
                top: -4,
                right: -6,
                child: Container(
                  padding: const EdgeInsets.all(2),
                  constraints: const BoxConstraints(minWidth: 15, minHeight: 15),
                  decoration: const BoxDecoration(
                    color: Color(0xFFFA6400),
                    shape: BoxShape.circle,
                  ),
                  child: Text(
                    '$count',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 9,
                      fontWeight: FontWeight.bold,
                      height: 1.1,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildTagBar() {
    return AnimatedTagList(
      tags: currentTags,
      isNight: isNight,
      onRemoveTag: onRemoveTag,
    );
  }

  Widget _buildTextButton(Color iconColor) {
    return InkWell(
      onTap: onFontSizeClick,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        child: Container(
          decoration: BoxDecoration(
            border: Border.all(color: iconColor.withValues(alpha: 0.8), width: 1.5),
            borderRadius: BorderRadius.circular(4),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
          child: Text(
            'A',
            style: TextStyle(
              color: iconColor.withValues(alpha: 0.8),
              fontSize: 12,
              fontWeight: FontWeight.bold,
              fontFamily: 'sans-serif',
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildToolbarIconButton({
    required Widget child,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.all(8),
        child: child,
      ),
    );
  }

  Widget _buildToolbarIcon(IconData icon, VoidCallback onTap, Color iconColor) {
    return _buildToolbarIconButton(
      onTap: onTap,
      child: Icon(
        icon,
        size: 22,
        color: iconColor.withValues(alpha: 0.8),
      ),
    );
  }

  Widget _buildImageUploadPreviewBar() {
    final imageBlocks = blocks.whereType<ImageBlock>().toList();
    if (imageBlocks.isEmpty) return const SizedBox.shrink();

    return Container(
      height: 60,
      margin: const EdgeInsets.only(left: 14, right: 12, top: 8, bottom: 0),
      child: AnimatedImagePreviewList(
        blocks: blocks,
        accentColor: accentColor,
        onRemoveImage: onRemoveImage,
      ),
    );
  }
}

class AnimatedImagePreviewList extends StatefulWidget {
  final List<DiaryBlock> blocks;
  final Color accentColor;
  final Function(int) onRemoveImage;

  const AnimatedImagePreviewList({
    super.key,
    required this.blocks,
    required this.accentColor,
    required this.onRemoveImage,
  });

  @override
  State<AnimatedImagePreviewList> createState() => _AnimatedImagePreviewListState();
}

class _AnimatedImagePreviewListState extends State<AnimatedImagePreviewList> {
  final GlobalKey<AnimatedListState> _listKey = GlobalKey<AnimatedListState>();
  late List<ImageBlock> _localImages;

  @override
  void initState() {
    super.initState();
    _localImages = widget.blocks.whereType<ImageBlock>().toList();
  }

  @override
  void didUpdateWidget(AnimatedImagePreviewList oldWidget) {
    super.didUpdateWidget(oldWidget);
    final newImages = widget.blocks.whereType<ImageBlock>().toList();

    // 1. 处理移除的元素
    for (int i = _localImages.length - 1; i >= 0; i--) {
      final img = _localImages[i];
      if (!newImages.any((n) => n.id == img.id)) {
        _localImages.removeAt(i);
        _listKey.currentState?.removeItem(
          i,
          (context, animation) => _buildItem(img, animation),
          duration: const Duration(milliseconds: 250),
        );
      }
    }

    // 2. 处理新增的元素
    for (int i = 0; i < newImages.length; i++) {
      final img = newImages[i];
      if (!_localImages.any((l) => l.id == img.id)) {
        _localImages.insert(i, img);
        _listKey.currentState?.insertItem(
          i,
          duration: const Duration(milliseconds: 250),
        );
      }
    }
  }

  Widget _buildItem(ImageBlock img, Animation<double> animation) {
    return SizeTransition(
      sizeFactor: animation,
      axis: Axis.horizontal,
      axisAlignment: -1.0,
      child: FadeTransition(
        opacity: animation,
        child: Padding(
          padding: const EdgeInsets.only(right: 10, top: 4),
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: widget.accentColor.withValues(alpha: 0.2)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: DiaryUtils.buildImage(img.file.path, fit: BoxFit.cover),
                ),
              ),
              if (img.videoPath != null)
                Positioned(
                  left: 3,
                  bottom: 3,
                  child: IgnorePointer(
                    child: Container(
                      padding: const EdgeInsets.all(2),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.45),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.motion_photos_on,
                        color: Colors.white,
                        size: 11,
                      ),
                    ),
                  ),
                ),
              Positioned(
                top: -5,
                right: -5,
                child: GestureDetector(
                  onTap: () {
                    final indexInBlocks = widget.blocks.indexOf(img);
                    if (indexInBlocks != -1) {
                      widget.onRemoveImage(indexInBlocks);
                    }
                  },
                  child: Container(
                    padding: const EdgeInsets.all(3),
                    decoration: const BoxDecoration(color: Colors.black, shape: BoxShape.circle),
                    child: const Icon(Icons.close_rounded, color: Colors.white, size: 10),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedList(
      key: _listKey,
      scrollDirection: Axis.horizontal,
      initialItemCount: _localImages.length,
      itemBuilder: (context, index, animation) {
        if (index < _localImages.length) {
          return _buildItem(_localImages[index], animation);
        }
        return const SizedBox.shrink();
      },
    );
  }
}

class AnimatedTagList extends StatefulWidget {
  final List<String> tags;
  final Function(String)? onRemoveTag;
  final bool isNight;

  const AnimatedTagList({
    super.key,
    required this.tags,
    this.onRemoveTag,
    required this.isNight,
  });

  @override
  State<AnimatedTagList> createState() => _AnimatedTagListState();
}

class _AnimatedTagListState extends State<AnimatedTagList> {
  final GlobalKey<AnimatedListState> _listKey = GlobalKey<AnimatedListState>();
  late List<String> _localTags;

  @override
  void initState() {
    super.initState();
    _localTags = List.from(widget.tags);
  }

  @override
  void didUpdateWidget(AnimatedTagList oldWidget) {
    super.didUpdateWidget(oldWidget);
    final newTags = widget.tags;

    // 1. 处理移除的元素
    for (int i = _localTags.length - 1; i >= 0; i--) {
      final t = _localTags[i];
      if (!newTags.contains(t)) {
        _localTags.removeAt(i);
        _listKey.currentState?.removeItem(
          i,
          (context, animation) => _buildItem(t, animation),
          duration: const Duration(milliseconds: 250),
        );
      }
    }

    // 2. 处理新增的元素
    for (int i = 0; i < newTags.length; i++) {
      final t = newTags[i];
      if (!_localTags.contains(t)) {
        _localTags.insert(i, t);
        _listKey.currentState?.insertItem(
          i,
          duration: const Duration(milliseconds: 250),
        );
      }
    }
  }

  Widget _buildItem(String tag, Animation<double> animation) {
    return SizeTransition(
      sizeFactor: animation,
      axis: Axis.horizontal,
      axisAlignment: -1.0,
      child: FadeTransition(
        opacity: animation,
        child: Padding(
          padding: const EdgeInsets.only(right: 6),
          child: Center(
            child: _TagChip(
              tag: tag,
              isNight: widget.isNight,
              onRemove: () => widget.onRemoveTag?.call(tag),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // 外层保留相同高度和边距，确保布局稳定性
    return Container(
      height: 26,
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 2),
      child: AnimatedList(
        key: _listKey,
        scrollDirection: Axis.horizontal,
        initialItemCount: _localTags.length,
        itemBuilder: (context, index, animation) {
          if (index < _localTags.length) {
            return _buildItem(_localTags[index], animation);
          }
          return const SizedBox.shrink();
        },
      ),
    );
  }
}

class _TagChip extends StatelessWidget {
  final String tag;
  final bool isNight;
  final VoidCallback onRemove;

  const _TagChip({
    required this.tag,
    required this.isNight,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
      decoration: BoxDecoration(
        color: isNight
            ? Colors.white.withValues(alpha: 0.06)
            : Colors.black.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isNight
              ? Colors.white.withValues(alpha: 0.1)
              : Colors.black.withValues(alpha: 0.08),
          width: 0.6,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            '#$tag',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              letterSpacing: 0.2,
              color: isNight
                  ? Colors.white.withValues(alpha: 0.65)
                  : Colors.black.withValues(alpha: 0.5),
              fontFamily: 'LXGWWenKai',
            ),
          ),
          const SizedBox(width: 3),
          GestureDetector(
            onTap: onRemove,
            child: Icon(
              Icons.close_rounded,
              size: 11,
              color: isNight
                  ? Colors.white.withValues(alpha: 0.3)
                  : Colors.black.withValues(alpha: 0.25),
            ),
          ),
        ],
      ),
    );
  }
}
