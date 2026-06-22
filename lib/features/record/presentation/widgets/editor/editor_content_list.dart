import 'package:flutter/material.dart';
import 'dart:ui' as ui;
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

  Rect? _originalBlockRect;
  String? _cachedBlockId;

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
      // 全部文字都在窄列旁边，计算实际总高度供图片对齐
      double narrowTextHeightValue = 0;
      for (var line in lines) {
        narrowTextHeightValue += line.height;
      }
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
        'narrowTextHeight': narrowTextHeightValue,
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

    final List<TextAttribute> origAttrs = tc.attributes;
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
      // 已拆分时，narrow 列密地展示 fittingLines 行，高度即 targetHeight
      'narrowTextHeight': targetHeight,
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
        if (hoveringTextBlockId == textBlock.id || textBlock.focusNode.hasFocus) {
          return _buildBlockItem(textBlock, textIndex);
        }



        return LayoutBuilder(
          builder: (context, constraints) {
            final double totalWidth = constraints.maxWidth;
            final double narrowWidth = totalWidth - 140 - 12;
            // 文字行高 = fontSize(20) × height(1.8) = 36dp，4行 = 144dp，与图片底部精确对齐
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
            // 图片高度动态对齐：SizedBox.height = narrowTextHeight + 8
            // margin.top(12) + 内容(narrowTextHeight-12) + margin.bottom(8) 内容占习精确与文字底部对齐
            final double narrowTextHeight = (splitResult['narrowTextHeight'] as double?) ?? targetHeight;
            final double imageSizedBoxHeight = narrowTextHeight;

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (alignment == 'left') ...[
                      SizedBox(
                        width: 140,
                        height: imageSizedBoxHeight,
                        child: _buildBlockItem(
                          imageBlock,
                          imageIndex,
                          forceFloating: true,
                          floatingHeight: narrowTextHeight - 16,
                        ),
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
                        height: imageSizedBoxHeight,
                        child: _buildBlockItem(
                          imageBlock,
                          imageIndex,
                          forceFloating: true,
                          floatingHeight: narrowTextHeight - 16,
                        ),
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
              if (_cachedBlockId != textBlock.id || _originalBlockRect == null) {
                _cachedBlockId = textBlock.id;
                final position = renderBox.localToGlobal(Offset.zero);
                _originalBlockRect = position & renderBox.size;
              }

              final String alignment = (details.offset.dx - _originalBlockRect!.left) < _originalBlockRect!.width / 2 ? 'left' : 'right';
              double targetLocalY = details.offset.dy - _originalBlockRect!.top - 30;
              if (targetLocalY < 0) targetLocalY = 0;
              if (targetLocalY > _originalBlockRect!.height) targetLocalY = _originalBlockRect!.height;

              // 直接用锁定的原始 Y 坐标查询字符位置，与 _getCharacterOffsetAtLocalY 使用的全宽排版完全匹配
              final int? splitOffset = _getCharacterOffsetAtLocalY(targetContext, textBlock, targetLocalY, _originalBlockRect!.width);
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
            _cachedBlockId = null;
            _originalBlockRect = null;
          },
          onAcceptWithDetails: (details) {
            final String alignment = hoveringAlignment ?? 'left';
            final int? splitOffset = hoveringSplitOffset;
            setState(() {
              hoveringTextBlockId = null;
              hoveringAlignment = null;
              hoveringSplitOffset = null;
            });
            _cachedBlockId = null;
            _originalBlockRect = null;
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

  int? _getCharacterOffsetAtLocalY(BuildContext context, TextBlock textBlock, double localY, double totalWidth) {
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
      textScaler: MediaQuery.textScalerOf(context),
    );
    textPainter.layout(maxWidth: totalWidth - 8);

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

  Widget _buildBlockItem(DiaryBlock block, int index, {bool? forceFloating, bool disableDraggable = false, double? floatingHeight}) {
    final key = widget.blockKeys[block.id];
    final bool isFirstTextBlock = block == widget.blocks.whereType<TextBlock>().firstOrNull;
    
    final int blockIndex = widget.blocks.indexOf(block);
    final bool canWrap = block is ImageBlock &&
        blockIndex != -1 &&
        blockIndex < widget.blocks.length - 1 &&
        widget.blocks[blockIndex + 1] is TextBlock;

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
      onWrapImageBlock: canWrap
          ? (imgBlock) {
              final nextBlock = widget.blocks[blockIndex + 1] as TextBlock;
              widget.onWrapImage?.call(imgBlock, nextBlock, imgBlock.floatAlignment, splitOffset: imgBlock.floatSplitOffset);
            }
          : null,
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
      floatingHeight: floatingHeight,
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
        childWhenDragging: Container(
          width: (forceFloating ?? block.isFloating) ? 140 : double.infinity,
          height: (forceFloating ?? block.isFloating) ? 128 : 200,
          decoration: BoxDecoration(
            color: Colors.red.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(12),
          ),
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
            // 文字行高 = fontSize(20) × height(1.8) = 36dp，4行 = 144dp，与图片底部精确对齐
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
            while (topText.endsWith('\n') || topText.endsWith('\r')) {
              topText = topText.substring(0, topText.length - 1);
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
            // 图片高度动态对齐，与放置后保持一致
            final double narrowTextHeight = (splitResult['narrowTextHeight'] as double?) ?? targetHeight;
            final double imageSizedBoxHeight = narrowTextHeight + 8;

            Widget buildPlaceholder() {
              return Container(
                margin: const EdgeInsets.only(top: 12, bottom: 8),
                width: 140,
                // 高度 = imageSizedBoxHeight - margin.top(12) - margin.bottom(8)，与文字底部精确对齐
                height: (imageSizedBoxHeight - 20).clamp(36.0, 200.0),
                decoration: BoxDecoration(
                  color: widget.accentColor.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: widget.accentColor.withValues(alpha: 0.35),
                    width: 1.5,
                  ),
                ),
                child: Center(
                  child: Icon(
                    Icons.add_photo_alternate_rounded,
                    size: 32,
                    color: widget.accentColor.withValues(alpha: 0.5),
                  ),
                ),
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
            if (_cachedBlockId != block.id || _originalBlockRect == null) {
              _cachedBlockId = block.id;
              final position = renderBox.localToGlobal(Offset.zero);
              _originalBlockRect = position & renderBox.size;
            }

            final String alignment = (details.offset.dx - _originalBlockRect!.left) < _originalBlockRect!.width / 2 ? 'left' : 'right';
            // 将定位基准从手指向上微调 30 像素（避开手指遮挡），以更精准地与拖拽图片位置对齐
            double targetLocalY = details.offset.dy - _originalBlockRect!.top - 30;
            if (targetLocalY < 0) targetLocalY = 0;
            if (targetLocalY > _originalBlockRect!.height) targetLocalY = _originalBlockRect!.height;

            // 直接用锁定的原始 Y 坐标查询字符位置，与 _getCharacterOffsetAtLocalY 使用的全宽排版完全匹配
            final int? splitOffset = _getCharacterOffsetAtLocalY(context, block, targetLocalY, _originalBlockRect!.width);
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
          _cachedBlockId = null;
          _originalBlockRect = null;
        },
        onAcceptWithDetails: (details) {
          final String alignment = hoveringAlignment ?? 'left';
          final int? splitOffset = hoveringSplitOffset;
          setState(() {
            hoveringTextBlockId = null;
            hoveringAlignment = null;
            hoveringSplitOffset = null;
          });
          _cachedBlockId = null;
          _originalBlockRect = null;
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
