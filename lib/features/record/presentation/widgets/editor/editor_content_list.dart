import 'package:flutter/material.dart';
import 'package:island_diary/shared/widgets/diary_entry/components/diary_block_item.dart';
import 'package:island_diary/shared/widgets/diary_entry/models/diary_block.dart';
import 'package:island_diary/shared/widgets/diary_entry/models/image_group_block.dart';
import 'package:island_diary/features/record/presentation/widgets/editor/mood_selector_header.dart';
import 'package:island_diary/features/record/presentation/widgets/editor/editor_date_header.dart';

class EditorContentList extends StatelessWidget {
  final List<DiaryBlock> blocks;
  final Map<String, GlobalKey> blockKeys;
  final bool isMixedLayout;
  final bool isImageGrid;
  final bool isEmojiOpen;
  final bool isNight;
  final String paperStyle;
  final Color accentColor;
  final double bottomPadding;
  final int? currentMoodIndex;
  final String? currentTag;
  final VoidCallback? onClearMood;
  final DateTime dateTime;
  final VoidCallback onDateTap;
  final VoidCallback? onClearWeather;

  final Function(int) onRemoveImage;
  final Function(int) onDeleteAtStart;
  final Function(ImageBlock) onShowPreview;
  final Function(int) onMoodSelected;
  final VoidCallback onCustomTap;
  final Function(String)? onRemoveTag;
  final Map<String, String>? annotations;
  final Function({
    String? key,
    required int blockIndex,
    required int start,
    required int end,
    required String selectedText,
  })? onAddAnnotation;
  final Function(String key)? onDeleteAnnotation;

  final String? weather;
  final String? temp;
  final VoidCallback? onWeatherTap;
  final String? location;
  final VoidCallback? onLocationTap;
  final VoidCallback? onClearLocation;

  const EditorContentList({
    super.key,
    required this.blocks,
    required this.blockKeys,
    required this.isMixedLayout,
    required this.isImageGrid,
    required this.isEmojiOpen,
    required this.isNight,
    required this.paperStyle,
    required this.accentColor,
    required this.bottomPadding,
    this.currentMoodIndex,
    this.currentTag,
    this.onClearMood,
    required this.dateTime,
    required this.onDateTap,
    this.onClearWeather,
    this.weather,
    this.temp,
    this.onWeatherTap,
    this.location,
    this.onLocationTap,
    this.onClearLocation,
    required this.onRemoveImage,
    required this.onDeleteAtStart,
    required this.onShowPreview,
    required this.onMoodSelected,
    required this.onCustomTap,
    this.onRemoveTag,
    this.annotations = const {},
    this.onAddAnnotation,
    this.onDeleteAnnotation,
  });

  @override
  Widget build(BuildContext context) {
    final processedBlocks = ImageGroupBlock.preprocess(
      blocks,
      isMixedLayout: isMixedLayout,
      isImageGrid: isImageGrid,
    );

    return SliverPadding(
      padding: EdgeInsets.fromLTRB(24, 0, 24, bottomPadding),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate(
          (context, index) {
            // 顶部大日期头部模块
            if (index == 0) {
              return EditorDateHeader(
                dateTime: dateTime,
                paperStyle: paperStyle,
                isNight: isNight,
                onDateTap: onDateTap,
              );
            }

            // 心情与天气胶囊模块
            if (index == 1) {
              return MoodSelectorHeader(
                currentMoodIndex: currentMoodIndex,
                currentTag: currentTag,
                onMoodSelected: onMoodSelected,
                onClearMood: onClearMood,
                paperStyle: paperStyle,
                isNight: isNight,
                onCustomTap: onCustomTap,
                onRemoveTag: onRemoveTag,
                weather: weather,
                temp: temp,
                onWeatherTap: onWeatherTap,
                onClearWeather: onClearWeather,
                location: location,
                onLocationTap: onLocationTap,
                onClearLocation: onClearLocation,
              );
            }

            final int contentIndex = index - 2;

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
            if (contentIndex >= processedBlocks.length) return null;
            final block = processedBlocks[contentIndex];
            return _buildBlockItem(block, blocks.indexOf(block));
          },
          childCount:
              (isMixedLayout
                  ? processedBlocks.length
                  : blocks.where((b) => b is! ImageBlock).length) +
              2,
        ),
      ),
    );
  }

  Widget _buildBlockItem(DiaryBlock block, int index) {
    final key = blockKeys[block.id];
    final bool isFirstTextBlock = block == blocks.whereType<TextBlock>().firstOrNull;
    return DiaryBlockItem(
      key: ValueKey(block.id),
      block: block,
      index: index,
      isEmojiOpen: isEmojiOpen,
      blockKey: key,
      onRemoveImage: () => onRemoveImage(index),
      onRemoveImageBlock: (imgBlock) {
        final idx = blocks.indexOf(imgBlock);
        if (idx != -1) {
          onRemoveImage(idx);
        }
      },
      onDeleteAtStart: () => onDeleteAtStart(index),
      onShowPreview: onShowPreview,
      isNightOverride: isNight,
      isNoteBackground: paperStyle.startsWith('note'),
      paperStyle: paperStyle,
      accentColor: accentColor,
      annotations: annotations,
      onAddAnnotation: onAddAnnotation,
      onDeleteAnnotation: onDeleteAnnotation,
      isFirstTextBlock: isFirstTextBlock,
    );
  }
}
