import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'dart:ui' as ui;
import 'dart:io' as io;
import 'package:island_diary/shared/widgets/diary_entry/components/diary_block_item.dart';
import 'package:island_diary/shared/widgets/diary_entry/models/diary_block.dart';
import 'package:island_diary/shared/widgets/diary_entry/models/image_group_block.dart';
import 'package:island_diary/features/record/presentation/widgets/editor/mood_selector_header.dart';
import 'package:island_diary/features/record/presentation/widgets/editor/editor_date_header.dart';
import 'package:island_diary/shared/widgets/diary_entry/utils/diary_utils.dart';

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

  final Function(ImageBlock imageBlock, TextBlock targetTextBlock, String alignment, {int? splitOffset})? onWrapImage;
  final Function(ImageBlock imageBlock)? onUnwrapImage;

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
    this.onWrapImage,
    this.onUnwrapImage,
  });

  @override
  State<EditorContentList> createState() => _EditorContentListState();
}

class _EditorContentListState extends State<EditorContentList> {
  String? hoveringTextBlockId;
  String? hoveringAlignment;
  int? hoveringSplitOffset;
  String? draggingImageBlockId;

  @override
  Widget build(BuildContext context) {
    final processedBlocks = ImageGroupBlock.preprocess(
      widget.blocks,
      isMixedLayout: widget.isMixedLayout,
      isImageGrid: widget.isImageGrid,
    );

    final List<DiaryBlock> displayBlocks = [];
    if (widget.isMixedLayout) {
      final List<DiaryBlock> listToProcess = List.from(processedBlocks);
      final Set<String> groupedIds = {};

      for (int i = 0; i < listToProcess.length; i++) {
        final block = listToProcess[i];
        if (groupedIds.contains(block.id)) continue;

        if (block is ImageBlock && block.isFloating) {
          TextBlock? nextTextBlock;
          for (int j = i + 1; j < listToProcess.length; j++) {
            final nextB = listToProcess[j];
            if (groupedIds.contains(nextB.id)) continue;
            if (nextB is TextBlock) {
              if (nextB.controller.text.trim().isNotEmpty) {
                nextTextBlock = nextB;
              }
              break;
            } else {
              break;
            }
          }

          if (nextTextBlock != null) {
            groupedIds.add(block.id);
            groupedIds.add(nextTextBlock.id);
            displayBlocks.add(
              TextWrapGroupBlock(
                imageBlock: block,
                textBlock: nextTextBlock,
                alignment: block.floatAlignment,
                id: '${block.id}_wrap_${nextTextBlock.id}',
              ),
            );
          } else {
            displayBlocks.add(block);
          }
        } else {
          displayBlocks.add(block);
        }
      }
    }

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
               return _buildBlockItem(block, widget.blocks.indexOf(block), forceFloating: false);
             }

             // 混排模式下按序渲染
             if (contentIndex >= displayBlocks.length) return null;
             final block = displayBlocks[contentIndex];
             if (block is TextWrapGroupBlock) {
               return _buildTextWrapGroupItem(block);
             }
             return _buildBlockItem(block, widget.blocks.indexOf(block), forceFloating: false);
          },
          findChildIndexCallback: (Key key) {
            if (key is ValueKey<String>) {
              final String val = key.value;
              if (val == 'date_header') return 0;
              if (val == 'mood_header') return 1;

              if (widget.isMixedLayout) {
                for (int i = 0; i < displayBlocks.length; i++) {
                  final block = displayBlocks[i];
                  if (block is TextWrapGroupBlock) {
                    if (val == block.id) {
                      return i + 2;
                    }
                  } else {
                    if (val == block.id ||
                        val == 'draggable_${block.id}' ||
                        val == 'drag_target_${block.id}') {
                      return i + 2;
                    }
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

  Map<String, dynamic> splitTextSpan({
    required TextBlock textBlock,
    required BuildContext context,
    required TextStyle textStyle,
    required double narrowWidth,
    required double totalWidth,
    required double targetHeight,
    required Map<String, String>? annotations,
    required int blockIndex,
    required Function(String)? onAnnotationTap,
    int? customSplitOffset,
  }) {
    final String text = textBlock.controller.text;
    if (text.isEmpty) {
      return {'narrowSpan': const TextSpan(), 'remainingSpan': const TextSpan()};
    }

    final tc = textBlock.controller as DiaryTextEditingController;
    final textPainter = TextPainter(
      text: TextSpan(text: text, style: textStyle),
      textDirection: TextDirection.ltr,
      textScaler: MediaQuery.textScalerOf(context),
    );
    // 减去 8 像素安全边距以对齐 SelectableText 的内部 padding，避免边缘字符溢出折行
    textPainter.layout(maxWidth: narrowWidth - 8);

    final lines = textPainter.computeLineMetrics();
    final int linesLength = lines.length;
    int endChar = 0;
    int fittingLines = 0;

    if (customSplitOffset != null && customSplitOffset > 0 && customSplitOffset < text.length) {
      endChar = customSplitOffset;
    } else {
      double accumulatedHeight = 0;
      int currentOffset = 0;
      for (var line in lines) {
        if (accumulatedHeight + line.height <= targetHeight + 1.0) {
          if (currentOffset < text.length) {
            final range = textPainter.getLineBoundary(TextPosition(offset: currentOffset));
            endChar = range.end;
            currentOffset = range.end > currentOffset ? range.end : currentOffset + 1;
          }
          accumulatedHeight += line.height;
          fittingLines++;
        } else {
          break;
        }
      }
    }

    debugPrint('--- splitTextSpan Call ---');
    debugPrint('text: $text');
    debugPrint('narrowWidth: $narrowWidth');
    debugPrint('targetHeight: $targetHeight');
    debugPrint('lines.length: ${lines.length}');
    debugPrint('fittingLines: $fittingLines');
    debugPrint('endChar: $endChar');
    debugPrint('text.length: ${text.length}');
    debugPrint('lines heights: ${lines.map((l) => l.height).toList()}');

    // 如果是按高度拆分，且所有行都能放入，或者没有有效的截断点，则不拆分
    final bool shouldNotSplit = customSplitOffset == null &&
        (fittingLines == 0 || fittingLines >= lines.length || endChar <= 0 || endChar >= text.length);

    if (shouldNotSplit) {
      final span = tc.buildTextSpan(
        context: context,
        style: textStyle,
        withComposing: false,
        hideMarkdownSymbols: true,
        annotations: annotations,
        blockIndex: blockIndex,
        onAnnotationTap: onAnnotationTap,
      );
      return {
        'narrowSpan': span,
        'remainingSpan': null,
        'remainingText': '',
        'narrowController': null,
        'remainingController': null,
        'linesLength': lines.length,
        'fittingLines': fittingLines,
        'endChar': endChar,
        'textLength': text.length,
      };
    }

    // 代理对边界保护
    if (endChar < text.length - 1) {
      final prev = text.codeUnitAt(endChar - 1);
      final next = text.codeUnitAt(endChar);
      if (prev >= 0xD800 && prev <= 0xDBFF && next >= 0xDC00 && next <= 0xDFFF) {
        endChar++;
      }
    }

    // 去除 narrowText 尾部的换行符，避免绕排区域底部出现空白行
    String narrowText = text.substring(0, endChar);
    while (narrowText.isNotEmpty &&
        (narrowText[narrowText.length - 1] == '\n' ||
            narrowText[narrowText.length - 1] == '\r')) {
      narrowText = narrowText.substring(0, narrowText.length - 1);
    }

    // 去除 remainingText 开头的换行符，避免绕排下方出现难看的空行
    int trimStartOffset = endChar;
    while (trimStartOffset < text.length && (text[trimStartOffset] == '\n' || text[trimStartOffset] == '\r')) {
      trimStartOffset++;
    }
    final remainingText = text.substring(trimStartOffset);

    final List<TextAttribute> origAttrs = (tc as DiaryTextEditingController).attributes;
    final List<TextAttribute> narrowAttrs = [];
    final List<TextAttribute> remainingAttrs = [];

    for (var attr in origAttrs) {
      if (attr.start < narrowText.length) {
        narrowAttrs.add(
          TextAttribute(
            start: attr.start,
            end: attr.end.clamp(0, narrowText.length),
            color: attr.color,
            backgroundColor: attr.backgroundColor,
            fontSize: attr.fontSize,
            underline: attr.underline,
            underlineStyle: attr.underlineStyle,
          ),
        );
      }
      if (attr.end > trimStartOffset) {
        remainingAttrs.add(
          TextAttribute(
            start: (attr.start - trimStartOffset).clamp(0, remainingText.length),
            end: (attr.end - trimStartOffset).clamp(0, remainingText.length),
            color: attr.color,
            backgroundColor: attr.backgroundColor,
            fontSize: attr.fontSize,
            underline: attr.underline,
            underlineStyle: attr.underlineStyle,
          ),
        );
      }
    }

    final narrowController = DiaryTextEditingController(
      text: narrowText,
      attributes: narrowAttrs,
    );
    narrowController.baseColor = textStyle.color ?? Colors.black;
    narrowController.baseFontFamily = textStyle.fontFamily ?? 'LXGWWenKai';
    narrowController.baseFontSize = textStyle.fontSize ?? 20;

    final remainingController = DiaryTextEditingController(
      text: remainingText,
      attributes: remainingAttrs,
    );
    remainingController.baseColor = textStyle.color ?? Colors.black;
    remainingController.baseFontFamily = textStyle.fontFamily ?? 'LXGWWenKai';
    remainingController.baseFontSize = textStyle.fontSize ?? 20;

    final narrowSpan = narrowController.buildTextSpan(
      context: context,
      style: textStyle,
      withComposing: false,
      hideMarkdownSymbols: true,
      annotations: annotations,
      blockIndex: blockIndex,
      onAnnotationTap: onAnnotationTap,
    );

    final remainingSpan = remainingController.buildTextSpan(
      context: context,
      style: textStyle,
      withComposing: false,
      hideMarkdownSymbols: true,
      annotations: annotations,
      blockIndex: blockIndex,
      onAnnotationTap: onAnnotationTap,
    );

    return {
      'narrowSpan': narrowSpan,
      'remainingSpan': remainingSpan,
      'remainingText': remainingText,
      'narrowController': narrowController,
      'remainingController': remainingController,
      'linesLength': lines.length,
      'fittingLines': fittingLines,
      'endChar': endChar,
      'textLength': text.length,
    };
  }

  Widget _buildTextWrapGroupItem(TextWrapGroupBlock wrapBlock) {
    final imageBlock = wrapBlock.imageBlock;
    final textBlock = wrapBlock.textBlock;
    final alignment = wrapBlock.alignment;

    final imageIndex = widget.blocks.indexOf(imageBlock);
    final textIndex = widget.blocks.indexOf(textBlock);

    final Widget groupItem = AnimatedBuilder(
      key: ValueKey(wrapBlock.id),
      animation: textBlock.focusNode,
      builder: (context, child) {
        if (hoveringTextBlockId == textBlock.id && draggingImageBlockId != imageBlock.id) {
          return _buildBlockItem(textBlock, textIndex);
        }



        return LayoutBuilder(
          builder: (context, constraints) {
            final double totalWidth = constraints.maxWidth;
            final double narrowWidth = totalWidth - 140 - 12;
            final double targetHeight = 144.0;

            final textStyle = TextStyle(
              fontSize: 20,
              height: 1.8,
              color: DiaryUtils.getInkColor(widget.paperStyle, widget.isNight),
              fontFamily: 'LXGWWenKai',
              fontFamilyFallback: const ['LXGWWenKai'],
            );

            final splitResult = splitTextSpan(
              textBlock: textBlock,
              context: context,
              textStyle: textStyle,
              narrowWidth: narrowWidth,
              totalWidth: totalWidth,
              targetHeight: targetHeight,
              annotations: widget.annotations,
              blockIndex: textIndex,
              onAnnotationTap: (key) {
                if (widget.onAddAnnotation != null) {
                  widget.onAddAnnotation!(
                    key: key,
                    blockIndex: textIndex,
                    start: 0,
                    end: 0,
                    selectedText: '',
                  );
                }
              },
            );

            final narrowSpan = splitResult['narrowSpan'] as TextSpan;
            final remainingSpan = splitResult['remainingSpan'] as TextSpan?;
            final remainingText = splitResult['remainingText'] as String? ?? '';
            final narrowController = splitResult['narrowController'] as DiaryTextEditingController?;
            final remainingController = splitResult['remainingController'] as DiaryTextEditingController?;

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (alignment == 'left') ...[
                      SizedBox(
                        width: 140,
                        child: _buildBlockItem(imageBlock, imageIndex, forceFloating: true),
                      ),
                      const SizedBox(width: 12),
                    ],
                    Expanded(
                      child: GestureDetector(
                        onTap: () {
                          textBlock.focusNode.requestFocus();
                        },
                        child: Stack(
                          clipBehavior: Clip.none,
                          children: [
                            if (narrowController != null)
                              Positioned.fill(
                                child: IgnorePointer(
                                  child: ValueListenableBuilder<TextEditingValue>(
                                    valueListenable: narrowController,
                                    builder: (builderContext, value, child) {
                                      return CustomPaint(
                                        painter: DiaryCirclePainter(
                                          context: builderContext,
                                          controller: narrowController,
                                          inkColor: textStyle.color ?? Colors.black,
                                          blockIndex: textIndex,
                                        ),
                                      );
                                    },
                                  ),
                                ),
                              ),
                            SelectableText.rich(
                              narrowSpan,
                              style: textStyle,
                              selectionHeightStyle: ui.BoxHeightStyle.tight,
                              selectionWidthStyle: ui.BoxWidthStyle.tight,
                            ),
                          ],
                        ),
                      ),
                    ),
                    if (alignment == 'right') ...[
                      const SizedBox(width: 12),
                      SizedBox(
                        width: 140,
                        child: _buildBlockItem(imageBlock, imageIndex, forceFloating: true),
                      ),
                    ],
                  ],
                ),
                if (remainingSpan != null && remainingText.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  GestureDetector(
                    onTap: () {
                      textBlock.focusNode.requestFocus();
                    },
                    child: Stack(
                      clipBehavior: Clip.none,
                      children: [
                        if (remainingController != null)
                          Positioned.fill(
                            child: IgnorePointer(
                              child: ValueListenableBuilder<TextEditingValue>(
                                valueListenable: remainingController,
                                builder: (builderContext, value, child) {
                                  return CustomPaint(
                                    painter: DiaryCirclePainter(
                                      context: builderContext,
                                      controller: remainingController,
                                      inkColor: textStyle.color ?? Colors.black,
                                      blockIndex: textIndex,
                                    ),
                                  );
                                },
                              ),
                            ),
                          ),
                        SelectableText.rich(
                          remainingSpan,
                          style: textStyle,
                          selectionHeightStyle: ui.BoxHeightStyle.tight,
                          selectionWidthStyle: ui.BoxWidthStyle.tight,
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            );
          },
        );
      },
    );

    return Builder(
      builder: (targetContext) {
        return DragTarget<ImageBlock>(
          key: ValueKey('drag_target_${wrapBlock.id}'),
          onWillAcceptWithDetails: (details) => true,
          onMove: (details) {
            final RenderBox? renderBox = targetContext.findRenderObject() as RenderBox?;
            if (renderBox != null) {
              final localOffset = renderBox.globalToLocal(details.offset);
              final String alignment = localOffset.dx < renderBox.size.width / 2 ? 'left' : 'right';
              double targetLocalY = localOffset.dy - 110;
              if (targetLocalY < 0) targetLocalY = 0;
              final int? splitOffset = _getCharacterOffsetAtLocalY(textBlock, targetLocalY, renderBox.size.width);
              if (hoveringTextBlockId != textBlock.id || hoveringAlignment != alignment || hoveringSplitOffset != splitOffset) {
                setState(() {
                  hoveringTextBlockId = textBlock.id;
                  hoveringAlignment = alignment;
                  hoveringSplitOffset = splitOffset;
                });
              }
            }
          },
          onLeave: (data) {
            setState(() {
              hoveringTextBlockId = null;
              hoveringAlignment = null;
              hoveringSplitOffset = null;
            });
          },
          onAcceptWithDetails: (details) {
            final String alignment = hoveringAlignment ?? 'left';
            final int? splitOffset = hoveringSplitOffset;
            setState(() {
              hoveringTextBlockId = null;
              hoveringAlignment = null;
              hoveringSplitOffset = null;
            });
            widget.onWrapImage?.call(details.data, textBlock, alignment, splitOffset: splitOffset);
            textBlock.focusNode.unfocus();
            FocusScope.of(targetContext).unfocus();
          },
          builder: (context, candidateData, rejectedData) {
            return groupItem;
          },
        );
      },
    );
  }

  int? _getCharacterOffsetAtLocalY(TextBlock textBlock, double localY, double totalWidth) {
    final String text = textBlock.controller.text;
    if (text.isEmpty) return 0;

    final textStyle = TextStyle(
      fontSize: 20,
      height: 1.8,
      color: DiaryUtils.getInkColor(widget.paperStyle, widget.isNight),
      fontFamily: 'LXGWWenKai',
      fontFamilyFallback: const ['LXGWWenKai'],
    );

    final textPainter = TextPainter(
      text: TextSpan(text: text, style: textStyle),
      textDirection: TextDirection.ltr,
    );
    textPainter.layout(maxWidth: totalWidth);

    final lines = textPainter.computeLineMetrics();
    double accumulatedHeight = 0;
    
    for (var line in lines) {
      if (localY >= accumulatedHeight && localY <= accumulatedHeight + line.height) {
        final position = textPainter.getPositionForOffset(
          Offset(0, accumulatedHeight + line.height / 2),
        );
        return position.offset;
      }
      accumulatedHeight += line.height;
    }
    
    if (localY > accumulatedHeight) {
      return text.length;
    }
    return 0;
  }

  Widget _buildBlockItem(DiaryBlock block, int index, {bool? forceFloating, bool disableDraggable = false}) {
    final key = widget.blockKeys[block.id];
    final bool isFirstTextBlock = block == widget.blocks.whereType<TextBlock>().firstOrNull;
    
    Widget item = DiaryBlockItem(
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
      onUnwrapImageBlock: widget.onUnwrapImage,
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
      isFloatingOverride: forceFloating,
    );

    if (block is ImageBlock && widget.isMixedLayout && !disableDraggable) {
      item = LongPressDraggable<ImageBlock>(
        key: ValueKey('draggable_${block.id}'),
        data: block,
        rootOverlay: false,
        onDragStarted: () {
          setState(() {
            draggingImageBlockId = block.id;
          });
        },
        onDragEnd: (details) {
          Future.delayed(const Duration(milliseconds: 50), () {
            if (mounted) {
              setState(() {
                draggingImageBlockId = null;
              });
            }
          });
        },
        onDraggableCanceled: (velocity, offset) {
          Future.delayed(const Duration(milliseconds: 50), () {
            if (mounted) {
              setState(() {
                draggingImageBlockId = null;
              });
            }
          });
        },
        feedback: Material(
          color: Colors.transparent,
          child: Opacity(
            opacity: 0.7,
            child: SizedBox(
              width: 120,
              height: 120,
              child: DiaryUtils.buildImage(
                block.localPath ?? block.file.path,
                fit: BoxFit.cover,
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
        childWhenDragging: Opacity(
          opacity: 0.25,
          child: item,
        ),
        child: item,
      );
    }

    if (block is TextBlock && widget.isMixedLayout) {
      final Widget childItem = item; // 保存当前值，避免闭包在 item 被重新赋值后捕获到 DragTarget 自身导致无限递归
      
      final bool isThisHovering = hoveringTextBlockId == block.id;
      final String? align = isThisHovering ? hoveringAlignment : null;

      Widget dragTargetChild = childItem;
      if (isThisHovering && align != null) {
        dragTargetChild = LayoutBuilder(
          builder: (context, constraints) {
            final double totalWidth = constraints.maxWidth;
            final double narrowWidth = totalWidth - 140 - 12;
            final double targetHeight = 144.0;

            final textStyle = TextStyle(
              fontSize: 20,
              height: 1.8,
              color: DiaryUtils.getInkColor(widget.paperStyle, widget.isNight),
              fontFamily: 'LXGWWenKai',
              fontFamilyFallback: const ['LXGWWenKai'],
            );

            final String fullText = block.controller.text;
            final int splitOffset = hoveringSplitOffset ?? 0;

            String topText = (splitOffset > 0 && splitOffset < fullText.length)
                ? fullText.substring(0, splitOffset)
                : '';
            String bottomText = (splitOffset > 0 && splitOffset < fullText.length)
                ? fullText.substring(splitOffset)
                : fullText;

            // 去除 topText 尾部的换行符，防止拖拽点上方出现空行
            int topTrimCount = 0;
            while (topText.endsWith('\n') || topText.endsWith('\r')) {
              topText = topText.substring(0, topText.length - 1);
              topTrimCount++;
            }

            // 去除 bottomText 头部的换行符，避免绕排顶部和下方出现空行
            int bottomTrimCount = 0;
            while (bottomText.startsWith('\n') || bottomText.startsWith('\r')) {
              bottomText = bottomText.substring(1);
              bottomTrimCount++;
            }

            // 获取 topText 的 TextSpan
            TextSpan? topSpan;
            DiaryTextEditingController? topController;
            if (topText.isNotEmpty) {
              // 构造一个临时的 Controller 来 buildTextSpan
              final List<TextAttribute> origAttrs = (block.controller as DiaryTextEditingController).attributes;
              final List<TextAttribute> topAttrs = [];
              for (var attr in origAttrs) {
                if (attr.start < splitOffset) {
                  topAttrs.add(
                    TextAttribute(
                      start: attr.start,
                      end: attr.end.clamp(0, topText.length),
                      color: attr.color,
                      backgroundColor: attr.backgroundColor,
                      fontSize: attr.fontSize,
                      underline: attr.underline,
                      underlineStyle: attr.underlineStyle,
                    ),
                  );
                }
              }
              topController = DiaryTextEditingController(
                text: topText,
                attributes: topAttrs,
              );
              topController.baseColor = textStyle.color ?? Colors.black;
              topController.baseFontFamily = textStyle.fontFamily ?? 'LXGWWenKai';
              topController.baseFontSize = textStyle.fontSize ?? 20;

              topSpan = topController.buildTextSpan(
                context: context,
                style: textStyle,
                withComposing: false,
                hideMarkdownSymbols: true,
                annotations: widget.annotations,
                blockIndex: index,
                onAnnotationTap: null,
              );
            }

            // 对 bottomText 调用 splitTextSpan 自动计算绕排前几行和剩余行
            final tempBottomBlock = TextBlock(bottomText, baseColor: (block.controller as DiaryTextEditingController).baseColor);
            // 复制原有的 controller attributes
            final List<TextAttribute> origAttrs = (block.controller as DiaryTextEditingController).attributes;
            final List<TextAttribute> bottomAttrs = [];
            final int bottomStartOffset = splitOffset + bottomTrimCount;
            for (var attr in origAttrs) {
              if (attr.end > bottomStartOffset) {
                bottomAttrs.add(
                  TextAttribute(
                    start: (attr.start - bottomStartOffset).clamp(0, bottomText.length),
                    end: (attr.end - bottomStartOffset).clamp(0, bottomText.length),
                    color: attr.color,
                    backgroundColor: attr.backgroundColor,
                    fontSize: attr.fontSize,
                    underline: attr.underline,
                    underlineStyle: attr.underlineStyle,
                  ),
                );
              }
            }
            final bottomController = tempBottomBlock.controller as DiaryTextEditingController;
            bottomController.attributes.clear();
            bottomController.attributes.addAll(bottomAttrs);
            bottomController.baseColor = textStyle.color ?? Colors.black;
            bottomController.baseFontFamily = textStyle.fontFamily ?? 'LXGWWenKai';
            bottomController.baseFontSize = textStyle.fontSize ?? 20;

            final splitResult = splitTextSpan(
              textBlock: tempBottomBlock,
              context: context,
              textStyle: textStyle,
              narrowWidth: narrowWidth,
              totalWidth: totalWidth,
              targetHeight: targetHeight,
              annotations: widget.annotations,
              blockIndex: index,
              onAnnotationTap: (key) {
                if (widget.onAddAnnotation != null) {
                  widget.onAddAnnotation!(
                    key: key,
                    blockIndex: index,
                    start: 0,
                    end: 0,
                    selectedText: '',
                  );
                }
              },
            );

            final narrowSpan = splitResult['narrowSpan'] as TextSpan;
            final remainingSpan = splitResult['remainingSpan'] as TextSpan?;
            final remainingText = splitResult['remainingText'] as String? ?? '';
            final narrowController = splitResult['narrowController'] as DiaryTextEditingController?;
            final remainingController = splitResult['remainingController'] as DiaryTextEditingController?;

            Widget buildPlaceholder() {
              return Container(
                margin: const EdgeInsets.only(top: 12, bottom: 8),
                width: 140,
                height: 128,
                color: Colors.red.withValues(alpha: 0.3),
              );
            }

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (topSpan != null && topText.isNotEmpty) ...[
                  Stack(
                    clipBehavior: Clip.none,
                    children: [
                      if (topController != null)
                        Positioned.fill(
                          child: IgnorePointer(
                            child: ValueListenableBuilder<TextEditingValue>(
                              valueListenable: topController,
                              builder: (builderContext, value, child) {
                                return CustomPaint(
                                  painter: DiaryCirclePainter(
                                    context: builderContext,
                                    controller: topController!,
                                    inkColor: textStyle.color ?? Colors.black,
                                    blockIndex: index,
                                  ),
                                );
                              },
                            ),
                          ),
                        ),
                      SelectableText.rich(
                        topSpan,
                        style: textStyle,
                        selectionHeightStyle: ui.BoxHeightStyle.tight,
                        selectionWidthStyle: ui.BoxWidthStyle.tight,
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                ],
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (align == 'left') ...[
                      buildPlaceholder(),
                      const SizedBox(width: 12),
                    ],
                    Expanded(
                      child: Stack(
                        clipBehavior: Clip.none,
                        children: [
                          if (narrowController != null)
                            Positioned.fill(
                              child: IgnorePointer(
                                child: ValueListenableBuilder<TextEditingValue>(
                                  valueListenable: narrowController,
                                  builder: (builderContext, value, child) {
                                    return CustomPaint(
                                      painter: DiaryCirclePainter(
                                        context: builderContext,
                                        controller: narrowController,
                                        inkColor: textStyle.color ?? Colors.black,
                                        blockIndex: index,
                                      ),
                                    );
                                  },
                                ),
                              ),
                            ),
                          SelectableText.rich(
                            narrowSpan,
                            style: textStyle,
                            selectionHeightStyle: ui.BoxHeightStyle.tight,
                            selectionWidthStyle: ui.BoxWidthStyle.tight,
                          ),
                        ],
                      ),
                    ),
                    if (align == 'right') ...[
                      const SizedBox(width: 12),
                      buildPlaceholder(),
                    ],
                  ],
                ),
                if (remainingSpan != null && remainingText.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Stack(
                    clipBehavior: Clip.none,
                    children: [
                      if (remainingController != null)
                        Positioned.fill(
                          child: IgnorePointer(
                            child: ValueListenableBuilder<TextEditingValue>(
                              valueListenable: remainingController,
                              builder: (builderContext, value, child) {
                                return CustomPaint(
                                  painter: DiaryCirclePainter(
                                    context: builderContext,
                                    controller: remainingController,
                                    inkColor: textStyle.color ?? Colors.black,
                                    blockIndex: index,
                                  ),
                                );
                              },
                            ),
                          ),
                        ),
                      SelectableText.rich(
                        remainingSpan,
                        style: textStyle,
                        selectionHeightStyle: ui.BoxHeightStyle.tight,
                        selectionWidthStyle: ui.BoxWidthStyle.tight,
                      ),
                    ],
                  ),
                ],
              ],
            );
          },
        );
      }

      item = DragTarget<ImageBlock>(
        key: ValueKey('drag_target_${block.id}'),
        onWillAcceptWithDetails: (details) => true,
        onMove: (details) {
          final RenderBox? renderBox = key?.currentContext?.findRenderObject() as RenderBox?;
          if (renderBox != null) {
            final localOffset = renderBox.globalToLocal(details.offset);
            final String alignment = localOffset.dx < renderBox.size.width / 2 ? 'left' : 'right';
            // 将定位基准从手指（图片中心）向上偏移 110 像素（契合 120 像素高度反馈图的顶部边缘及触控偏移），对齐到图片顶部边缘
            double targetLocalY = localOffset.dy - 110;
            if (targetLocalY < 0) targetLocalY = 0;
            final int? splitOffset = _getCharacterOffsetAtLocalY(block, targetLocalY, renderBox.size.width);
            if (hoveringTextBlockId != block.id || hoveringAlignment != alignment || hoveringSplitOffset != splitOffset) {
              setState(() {
                hoveringTextBlockId = block.id;
                hoveringAlignment = alignment;
                hoveringSplitOffset = splitOffset;
              });
            }
          }
        },
        onLeave: (data) {
          setState(() {
            hoveringTextBlockId = null;
            hoveringAlignment = null;
            hoveringSplitOffset = null;
          });
        },
        onAcceptWithDetails: (details) {
          final String alignment = hoveringAlignment ?? 'left';
          final int? splitOffset = hoveringSplitOffset;
          setState(() {
            hoveringTextBlockId = null;
            hoveringAlignment = null;
            hoveringSplitOffset = null;
          });
          widget.onWrapImage?.call(details.data, block, alignment, splitOffset: splitOffset);
          // 拖放完成后主动取消焦点，让文字进入绕排阅读模式
          block.focusNode.unfocus();
          FocusScope.of(context).unfocus();
        },
        builder: (context, candidateData, rejectedData) {
          final isHovering = candidateData.isNotEmpty;
          return AnimatedContainer(
            key: key,
            duration: const Duration(milliseconds: 200),
            decoration: BoxDecoration(
              color: isHovering ? widget.accentColor.withValues(alpha: 0.04) : Colors.transparent,
              borderRadius: BorderRadius.circular(8),
            ),
            child: dragTargetChild,
          );
        },
      );
    }

    return item;
  }
}
