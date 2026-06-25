import 'package:flutter/material.dart';
import 'package:island_diary/shared/widgets/diary_entry/components/diary_block_item.dart';
import 'package:island_diary/shared/widgets/diary_entry/models/diary_block.dart';
import 'package:island_diary/shared/widgets/diary_entry/models/image_group_block.dart';
import 'package:island_diary/features/record/presentation/widgets/editor/mood_selector_header.dart';
import 'package:island_diary/features/record/presentation/widgets/editor/editor_date_header.dart';

class EditorContentList extends StatefulWidget {
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
  State<EditorContentList> createState() => _EditorContentListState();
}

class _EditorContentListState extends State<EditorContentList> {
  @override
  Widget build(BuildContext context) {
    final processedBlocks = ImageGroupBlock.preprocess(
      widget.blocks,
      isMixedLayout: widget.isMixedLayout,
      isImageGrid: widget.isImageGrid,
    );

    final displayBlocks = processedBlocks;

    return SliverPadding(
      padding: EdgeInsets.fromLTRB(24, 0, 24, widget.bottomPadding),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate(
          (context, index) {
            // 顶部大日期头部模块
            if (index == 0) {
              return EditorDateHeader(
                key: const ValueKey('date_header'),
                dateTime: widget.dateTime,
                paperStyle: widget.paperStyle,
                isNight: widget.isNight,
                onDateTap: widget.onDateTap,
              );
            }

            // 心情与天气胶囊模块
            if (index == 1) {
              return MoodSelectorHeader(
                key: const ValueKey('mood_header'),
                currentMoodIndex: widget.currentMoodIndex,
                currentTag: widget.currentTag,
                onMoodSelected: widget.onMoodSelected,
                onClearMood: widget.onClearMood,
                paperStyle: widget.paperStyle,
                isNight: widget.isNight,
                onCustomTap: widget.onCustomTap,
                onRemoveTag: widget.onRemoveTag,
                weather: widget.weather,
                temp: widget.temp,
                onWeatherTap: widget.onWeatherTap,
                onClearWeather: widget.onClearWeather,
                location: widget.location,
                onLocationTap: widget.onLocationTap,
                onClearLocation: widget.onClearLocation,
              );
            }

            final int contentIndex = index - 2;

             // 如果关闭了图文混排模式，只渲染非图片块
             if (!widget.isMixedLayout) {
               final nonImageBlocks = widget.blocks
                   .where((b) => b is! ImageBlock)
                   .toList();
               if (contentIndex >= nonImageBlocks.length) return null;

               final block = nonImageBlocks[contentIndex];
               return _buildBlockItem(block, widget.blocks.indexOf(block));
             }

             // 混排模式下按序渲染
             if (contentIndex >= displayBlocks.length) return null;
             final block = displayBlocks[contentIndex];
             return _buildBlockItem(block, widget.blocks.indexOf(block));
          },
          findChildIndexCallback: (Key key) {
            if (key is ValueKey<String>) {
              final String val = key.value;
              if (val == 'date_header') return 0;
              if (val == 'mood_header') return 1;

              if (widget.isMixedLayout) {
                for (int i = 0; i < displayBlocks.length; i++) {
                  final block = displayBlocks[i];
                  if (val == block.id ||
                      val == 'draggable_${block.id}' ||
                      val == 'drag_target_${block.id}') {
                    return i + 2;
                  }
                }
              } else {
                final nonImageBlocks = widget.blocks
                    .where((b) => b is! ImageBlock)
                    .toList();
                for (int i = 0; i < nonImageBlocks.length; i++) {
                  final block = nonImageBlocks[i];
                  if (val == block.id ||
                      val == 'draggable_${block.id}' ||
                      val == 'drag_target_${block.id}') {
                    return i + 2;
                  }
                }
              }
            }
            return null;
          },
          childCount:
              (widget.isMixedLayout
                  ? displayBlocks.length
                  : widget.blocks.where((b) => b is! ImageBlock).length) +
              2,
        ),
      ),
    );
  }

  Widget _buildBlockItem(DiaryBlock block, int index) {
    final key = widget.blockKeys[block.id];
    final bool isFirstTextBlock = block == widget.blocks.whereType<TextBlock>().firstOrNull;

    return DiaryBlockItem(
      key: ValueKey(block.id),
      block: block,
      index: index,
      isEmojiOpen: widget.isEmojiOpen,
      blockKey: widget.isMixedLayout ? null : key,
      onRemoveImage: () => widget.onRemoveImage(index),
      onRemoveImageBlock: (imgBlock) {
        final idx = widget.blocks.indexOf(imgBlock);
        if (idx != -1) {
          widget.onRemoveImage(idx);
        }
      },
      onDeleteAtStart: () => widget.onDeleteAtStart(index),
      onShowPreview: widget.onShowPreview,
      isNightOverride: widget.isNight,
      isNoteBackground: widget.paperStyle.startsWith('note'),
      paperStyle: widget.paperStyle,
      accentColor: widget.accentColor,
      annotations: widget.annotations,
      onAddAnnotation: widget.onAddAnnotation,
      onDeleteAnnotation: widget.onDeleteAnnotation,
      isFirstTextBlock: isFirstTextBlock,
    );
  }
}
