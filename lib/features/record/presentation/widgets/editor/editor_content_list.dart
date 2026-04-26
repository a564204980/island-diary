import 'package:flutter/material.dart';
import 'package:island_diary/shared/widgets/diary_entry/components/diary_block_item.dart';
import 'package:island_diary/shared/widgets/diary_entry/models/diary_block.dart';

class EditorContentList extends StatelessWidget {
  final List<DiaryBlock> blocks;
  final Map<String, GlobalKey> blockKeys;
  final bool isMixedLayout;
  final bool isEmojiOpen;
  final bool isNight;
  final String paperStyle;
  final Color accentColor;
  final double bottomPadding;
  final Function(int) onRemoveImage;
  final Function(int) onDeleteAtStart;
  final void Function(ImageBlock)? onShowPreview;

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
    required this.onRemoveImage,
    required this.onDeleteAtStart,
    required this.onShowPreview,
  });

  @override
  Widget build(BuildContext context) {
    return SliverPadding(
      padding: EdgeInsets.fromLTRB(24, 12, 24, bottomPadding),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate(
          (context, index) {
            // 如果关闭了图文混排模式，只渲染非图片块
            if (!isMixedLayout) {
              final nonImageBlocks = blocks.where((b) => b is! ImageBlock).toList();
              if (index >= nonImageBlocks.length) return null;
              
              final block = nonImageBlocks[index];
              return _buildBlockItem(block, blocks.indexOf(block));
            }

            // 混排模式下按序渲染
            if (index >= blocks.length) return null;
            final block = blocks[index];
            return _buildBlockItem(block, index);
          },
          childCount: isMixedLayout 
              ? blocks.length 
              : blocks.where((b) => b is! ImageBlock).length,
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
