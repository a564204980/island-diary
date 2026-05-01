import 'package:flutter/material.dart';
import 'package:island_diary/shared/widgets/diary_entry/components/diary_block_item.dart';
import 'package:island_diary/shared/widgets/diary_entry/models/diary_block.dart';
import 'package:island_diary/features/record/presentation/widgets/editor/mood_selector_header.dart';

class EditorContentList extends StatelessWidget {
  final List<DiaryBlock> blocks;
  final Map<String, GlobalKey> blockKeys;
  final bool isMixedLayout;
  final bool isEmojiOpen;
  final bool isNight;
  final String paperStyle;
  final Color accentColor;
  final double bottomPadding;
  final int? currentMoodIndex;
  final String? currentTag;
  final VoidCallback? onClearMood;

  final Function(int) onRemoveImage;
  final Function(int) onDeleteAtStart;
  final Function(ImageBlock) onShowPreview;
  final Function(int) onMoodSelected;
  final VoidCallback onCustomTap;

  const EditorContentList({
    super.key,
    required this.blocks,
    required this.blockKeys,
    required this.isMixedLayout,
    required this.isEmojiOpen,
    required this.isNight,
    required this.paperStyle,
    required this.accentColor,
    required this.bottomPadding,
    this.currentMoodIndex,
    this.currentTag,
    this.onClearMood,
    required this.onRemoveImage,
    required this.onDeleteAtStart,
    required this.onShowPreview,
    required this.onMoodSelected,
    required this.onCustomTap,
  });

  @override
  Widget build(BuildContext context) {
    return SliverPadding(
      padding: EdgeInsets.fromLTRB(24, 12, 24, bottomPadding),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate(
          (context, index) {
            // 顶部心情选择模块
            if (index == 0) {
              return MoodSelectorHeader(
                currentMoodIndex: currentMoodIndex,
                currentTag: currentTag,
                onMoodSelected: onMoodSelected,
                onClearMood: onClearMood,
                paperStyle: paperStyle,
                isNight: isNight,
                onCustomTap: onCustomTap,
              );
            }

            final int contentIndex = index - 1;

            // 如果关闭了图文混排模式，只渲染非图片块
            if (!isMixedLayout) {
              final nonImageBlocks = blocks
                  .where((b) => b is! ImageBlock)
                  .toList();
              if (contentIndex >= nonImageBlocks.length) return null;

              final block = nonImageBlocks[contentIndex];
              return _buildBlockItem(block, blocks.indexOf(block));
            }

            // 混排模式下按序渲染
            if (contentIndex >= blocks.length) return null;
            final block = blocks[contentIndex];
            return _buildBlockItem(block, contentIndex);
          },
          childCount:
              (isMixedLayout
                  ? blocks.length
                  : blocks.where((b) => b is! ImageBlock).length) +
              1,
        ),
      ),
    );
  }

  Widget _buildBlockItem(DiaryBlock block, int index) {
    final key = blockKeys[block.id];
    return DiaryBlockItem(
      key: ValueKey(block.id),
      block: block,
      index: index,
      isEmojiOpen: isEmojiOpen,
      blockKey: key,
      onRemoveImage: () => onRemoveImage(index),
      onDeleteAtStart: () => onDeleteAtStart(index),
      onShowPreview: onShowPreview,
      isNightOverride: isNight,
      isNoteBackground: paperStyle.startsWith('note'),
      paperStyle: paperStyle,
      accentColor: accentColor,
    );
  }
}
