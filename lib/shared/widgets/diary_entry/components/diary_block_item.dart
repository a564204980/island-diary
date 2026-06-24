import 'package:flutter/material.dart';
import 'dart:ui' as ui;
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:video_player/video_player.dart';
import 'package:island_diary/core/state/user_state.dart';
import '../models/diary_block.dart';
import '../models/image_group_block.dart';
import '../utils/diary_utils.dart';
import 'audio_player.dart';
import 'diary_image_collage.dart';
import 'package:flutter/rendering.dart';
import 'package:island_diary/shared/widgets/diary_entry/components/diary_text_context_menu.dart';

class DiaryBlockItem extends StatelessWidget {
  final DiaryBlock block;
  final int index;
  final bool isEmojiOpen;
  final GlobalKey? blockKey;
  final VoidCallback? onRemoveImage;
  final Function(ImageBlock)? onRemoveImageBlock;
  final VoidCallback? onDeleteAtStart; // 新增：在行首按下回退键的回调
  final Function(ImageBlock)? onShowPreview;
  final bool? isNightOverride;
  final bool isNoteBackground;
  final Color? accentColor;
  final String? paperStyle;
  final Map<String, String>? annotations;
  final Function({
    String? key,
    required int blockIndex,
    required int start,
    required int end,
    required String selectedText,
  })?
  onAddAnnotation;
  final Function(String key)? onDeleteAnnotation;
  final bool isFirstTextBlock;

  const DiaryBlockItem({
    super.key,
    required this.block,
    required this.index,
    this.isEmojiOpen = false,
    this.blockKey,
    this.onRemoveImage,
    this.onRemoveImageBlock,
    this.onDeleteAtStart,
    this.onShowPreview,
    this.isNightOverride,
    this.isNoteBackground = false,
    this.accentColor,
    this.paperStyle,
    this.annotations = const {},
    this.onAddAnnotation,
    this.onDeleteAnnotation,
    this.isFirstTextBlock = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(key: blockKey, child: _buildContent(context));
  }

  Widget _buildContent(BuildContext context) {
    if (block is TextBlock) {
      return _buildTextBlock(block as TextBlock, context);
    } else if (block is ImageBlock) {
      return _buildImageBlock(block as ImageBlock);
    } else if (block is ImageGroupBlock) {
      return _buildImageGroupBlock(block as ImageGroupBlock, context);
    } else if (block is AudioBlock) {
      return _buildAudioBlock(block as AudioBlock);
    } else if (block is RewardBlock) {
      return _buildRewardBlock(block as RewardBlock);
    } else if (block is StickerBlock) {
      return _buildStickerBlock(block as StickerBlock);
    }
    return const SizedBox.shrink();
  }

  Widget _buildStickerBlock(StickerBlock block) {
    // 贴纸现在通过 DiaryEditorPage 的 Stack 悬浮层进行交互式渲染，
    // 这里不再进行重复渲染，仅作为一个占位或返回空。
    return const SizedBox.shrink();
  }

  Widget _buildRewardBlock(RewardBlock block) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFFD4B483).withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        children: [
          Image.asset(block.imagePath, width: 40, height: 40),
          const SizedBox(width: 12),
          Text(
            block.name,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Color(0xFF8B5E3C),
            ),
          ),
          const Spacer(),
          if (onRemoveImage != null)
            IconButton(
              icon: const Icon(Icons.close, size: 20),
              onPressed: onRemoveImage,
            ),
        ],
      ),
    );
  }

  Widget _buildTextBlock(TextBlock block, BuildContext context) {
    final isNight = isNightOverride ?? UserState().isNight;

    final inkColor = paperStyle != null
        ? DiaryUtils.getInkColor(paperStyle!, isNight)
        : (isNight ? const Color(0xFFE0C097) : const Color(0xFF5D4037));

    final tc = block.controller;
    if (tc is DiaryTextEditingController) {
      tc.blockIndex = index;
      tc.annotations = annotations;
      tc.onAnnotationTap = (key) {
        if (onAddAnnotation != null) {
          onAddAnnotation!(
            key: key,
            blockIndex: index,
            start: 0,
            end: 0,
            selectedText: '',
          );
        }
      };
    }

    return Theme(
      data: Theme.of(context).copyWith(
        textSelectionTheme: TextSelectionThemeData(
          cursorColor: inkColor,
          selectionColor: inkColor.withValues(alpha: 0.28),
          selectionHandleColor: inkColor,
        ),
      ),
      child: Focus(
        onKeyEvent: (node, event) {
          if (event is KeyDownEvent &&
              event.logicalKey == LogicalKeyboardKey.backspace) {
            final selection = block.controller.selection;
            if (selection.isCollapsed && selection.baseOffset == 0) {
              onDeleteAtStart?.call();
              return KeyEventResult.handled;
            }
          }
          return KeyEventResult.ignored;
        },
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            if (tc is DiaryTextEditingController)
              Positioned.fill(
                child: IgnorePointer(
                  child: ValueListenableBuilder<TextEditingValue>(
                    valueListenable: tc,
                    builder: (builderContext, value, child) {
                      return CustomPaint(
                        painter: DiaryCirclePainter(
                          context: builderContext,
                          controller: tc,
                          inkColor: inkColor,
                          blockIndex: index,
                        ),
                      );
                    },
                  ),
                ),
              ),
            TextField(
              controller: block.controller,
              focusNode: block.focusNode,
              maxLines: null,
              readOnly: false,
              showCursor: true,
              cursorColor: inkColor,
              cursorHeight: 22, // 强制光标高度，避免随行高(height: 1.8)拉长
              selectionHeightStyle: ui.BoxHeightStyle.tight,
              selectionWidthStyle: ui.BoxWidthStyle.tight,
              style: TextStyle(
                fontSize: 20,
                height: 1.8,
                color: inkColor,
                fontFamilyFallback: const ['LXGWWenKai'],
              ),
              contextMenuBuilder: (context, editableTextState) {
                if (onAddAnnotation == null) return const SizedBox.shrink();
                return DiaryTextContextMenu(
                  editableTextState: editableTextState,
                  blockIndex: index,
                  annotations: annotations ?? const {},
                  onAddAnnotation: onAddAnnotation!,
                  onDeleteAnnotation: onDeleteAnnotation,
                  showAnnotation: false,
                  showUnderline: true,
                  paperStyle: paperStyle,
                );
              },
              decoration: InputDecoration(
                hintText: isFirstTextBlock ? '今天发生了什么？记录此刻的触动...' : '',
                hintStyle: TextStyle(
                  color: isNoteBackground
                      ? (accentColor?.withValues(alpha: 0.4) ??
                            (isNight ? Colors.white38 : Colors.black38))
                      : (isNight
                            ? const Color(0xFFC4B8AD).withValues(alpha: 0.45)
                            : (accentColor ?? const Color(0xFFA68565))
                                  .withValues(alpha: 0.45)),
                ),
                border: InputBorder.none,
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(vertical: 4),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImageBlock(ImageBlock block) {
    return AnimatedDeleteWrapper(
      onDelete: () {
        if (onRemoveImageBlock != null) {
          onRemoveImageBlock!(block);
        } else {
          onRemoveImage?.call();
        }
      },
      builder: (context, startDelete) {
        return Builder(
          builder: (context) {
            final bool isWideScreen = MediaQuery.of(context).size.width > 800;
            final String displayPath = block.localPath ?? block.file.path;

            return Center(
              child: Container(
                constraints: BoxConstraints(
                  maxWidth: isWideScreen ? 760 : double.infinity,
                ),
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    GestureDetector(
                      onTap: block.isUploading
                          ? null
                          : () => onShowPreview?.call(block),
                      child: Container(
                        margin: const EdgeInsets.only(
                          top: 8,
                          bottom: 8,
                        ),
                        child: block.videoPath != null
                            ? ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: _LiveImagePlayer(
                                  videoPath: block.videoPath!,
                                  fallbackPath: displayPath,
                                ),
                              )
                            : DiaryUtils.buildImage(
                                displayPath,
                                fit: BoxFit.contain,
                                borderRadius: BorderRadius.circular(12),
                              ),
                      ),
                    ),
                    if (block.isUploading)
                      Positioned.fill(
                        child: Container(
                          margin: const EdgeInsets.symmetric(vertical: 8),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.25),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Center(
                            child: SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.5,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  Colors.white,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    if (block.videoPath != null && !block.isUploading)
                      Positioned(
                        left: 8,
                        bottom: 16,
                        child: IgnorePointer(
                          child: Container(
                            padding: const EdgeInsets.all(3.5),
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.45),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.motion_photos_on,
                              color: Colors.white,
                              size: 16,
                            ),
                          ),
                        ),
                      ),
                    if (!block.isUploading && (onRemoveImageBlock != null || onRemoveImage != null))
                      Positioned(
                        top: 14,
                        right: 6,
                        child: GestureDetector(
                          onTap: startDelete,
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: const BoxDecoration(
                              color: Colors.black38,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.close,
                              color: Colors.white,
                              size: 18,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            );
          },
        ).animate(key: ValueKey('img_anim_${block.id}')).fadeIn().scale();
      },
    );
  }

  Widget _buildImageGroupBlock(ImageGroupBlock block, BuildContext context) {
    final bool isWideScreen = MediaQuery.of(context).size.width > 800;
    final List<String> paths = block.images
        .map((img) => img.localPath ?? img.file.path)
        .toList();

    return Center(
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 8),
        constraints: BoxConstraints(
          maxWidth: isWideScreen ? 760 : double.infinity,
        ),
        child: DiaryImageCollage(
          imagePaths: paths,
          imageWrapper: onRemoveImageBlock == null
              ? null
              : (idx, child) {
                  final imgBlock = block.images[idx];
                  return LongPressDraggable<ImageBlock>(
                    data: imgBlock,
                    feedback: Material(
                      color: Colors.transparent,
                      child: Opacity(
                        opacity: 0.7,
                        child: SizedBox(
                          width: 120,
                          height: 120,
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: DiaryUtils.buildImage(
                              imgBlock.localPath ?? imgBlock.file.path,
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                      ),
                    ),
                    childWhenDragging: Opacity(
                      opacity: 0.3,
                      child: child,
                    ),
                    child: child,
                  );
                },
          onTapImage: (idx) {
            if (onShowPreview != null) {
              onShowPreview!(block.images[idx]);
            }
          },
          onDeleteImage: onRemoveImageBlock != null
              ? (idx) => onRemoveImageBlock!(block.images[idx])
              : null,
        ),
      ),
    );
  }

  Widget _buildAudioBlock(AudioBlock block) {
    return Stack(
      children: [
        HandDrawnAudioPlayer(path: block.path, name: block.name),
        Positioned(
          top: 15,
          right: 15,
          child: IconButton(
            icon: const Icon(Icons.close, size: 18, color: Color(0xFF8B5E3C)),
            onPressed: onRemoveImage,
          ),
        ),
      ],
    );
  }
}

/// 专用于模拟实况图微动效果的本地视频播放器
class _LiveImagePlayer extends StatefulWidget {
  final String videoPath;
  final String fallbackPath;

  const _LiveImagePlayer({required this.videoPath, required this.fallbackPath});

  @override
  State<_LiveImagePlayer> createState() => _LiveImagePlayerState();
}

class _LiveImagePlayerState extends State<_LiveImagePlayer> {
  late VideoPlayerController _controller;
  bool _initialized = false;

  @override
  void initState() {
    super.initState();
    if (kIsWeb ||
        widget.videoPath.startsWith('http') ||
        widget.videoPath.startsWith('blob:')) {
      _controller = VideoPlayerController.networkUrl(
        Uri.parse(widget.videoPath),
      );
    } else {
      _controller = VideoPlayerController.file(File(widget.videoPath));
    }

    _controller
        .initialize()
        .then((_) {
          if (mounted) {
            setState(() => _initialized = true);
            _controller.setLooping(true);
            _controller.setVolume(0); // 实况图静音播放
            _controller.play();
          }
        })
        .catchError((e) {
          debugPrint('Live Photo Video Error: $e');
        });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: _initialized ? _controller.value.aspectRatio : 1.0,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // 封面占位图 (始终存在，作为背景)
          Positioned.fill(
            child: DiaryUtils.buildImage(
              widget.fallbackPath,
              fit: BoxFit.cover,
            ),
          ),
          // 视频层 (加载完成后淡入)
          AnimatedOpacity(
            opacity: _initialized ? 1.0 : 0.0,
            duration: const Duration(milliseconds: 600),
            curve: Curves.easeIn,
            child: _initialized
                ? VideoPlayer(_controller)
                : const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }
}

/// 专用于内容块（如图片、拼图项）被删除时的缩放与淡出动画包装组件
class AnimatedDeleteWrapper extends StatefulWidget {
  final Widget Function(BuildContext context, VoidCallback startDelete) builder;
  final VoidCallback onDelete;

  const AnimatedDeleteWrapper({
    super.key,
    required this.builder,
    required this.onDelete,
  });

  @override
  State<AnimatedDeleteWrapper> createState() => _AnimatedDeleteWrapperState();
}

class _AnimatedDeleteWrapperState extends State<AnimatedDeleteWrapper>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _opacityAnimation;
  late final Animation<double> _scaleAnimation;
  late final Animation<double> _sizeAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 250),
    );
    _opacityAnimation = Tween<double>(
      begin: 1.0,
      end: 0.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.85,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));
    _sizeAnimation = Tween<double>(
      begin: 1.0,
      end: 0.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _startDelete() {
    _controller.forward().then((_) {
      widget.onDelete();
    });
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Opacity(
          opacity: _opacityAnimation.value,
          child: SizeTransition(
            sizeFactor: _sizeAnimation,
            axis: Axis.vertical,
            child: ScaleTransition(scale: _scaleAnimation, child: child),
          ),
        );
      },
      child: widget.builder(context, _startDelete),
    );
  }
}

class DiaryCirclePainter extends CustomPainter {
  final BuildContext context;
  final DiaryTextEditingController controller;
  final Color inkColor;
  final int blockIndex;

  DiaryCirclePainter({
    required this.context,
    required this.controller,
    required this.inkColor,
    required this.blockIndex,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (controller.text.isEmpty) return;

    // 1. 递归寻找子树中的 RenderEditable (向上爬 3 层至共同父级再向下搜，以解决同级节点无法向下遍历找到的盲区)
    RenderEditable? renderEditable;
    if (context is Element) {
      Element? parentEl = context as Element;
      int count = 0;
      parentEl.visitAncestorElements((ancestor) {
        parentEl = ancestor;
        count++;
        return count < 3;
      });
      final targetEl = parentEl;
      if (targetEl != null) {
        void visitor(Element el) {
          if (renderEditable != null) return;
          final ro = el.renderObject;
          if (ro is RenderEditable) {
            renderEditable = ro;
            return;
          }
          el.visitChildren(visitor);
        }

        targetEl.visitChildren(visitor);
      }
    }

    if (renderEditable == null) return;
    final re = renderEditable!;
    if (!re.attached) return;

    final RenderBox? myBox = context.findRenderObject() as RenderBox?;
    if (myBox == null || !myBox.attached || !myBox.hasSize) return;

    // 计算 RenderEditable 相对于当前 CustomPaint (myBox) 的精确物理偏移量
    final Offset offset =
        re.localToGlobal(Offset.zero) - myBox.localToGlobal(Offset.zero);


    canvas.save();
    canvas.translate(offset.dx, offset.dy);

    for (var attr in controller.attributes) {
      final style = attr.underlineStyle;
      if (style != null && style.startsWith('circle')) {
        final start = attr.start.clamp(0, controller.text.length);
        final end = attr.end.clamp(0, controller.text.length);
        if (start >= end) continue;

        // 1. 寻找覆盖该选区范围的文字前景色属性，若无则默认使用暖红
        Color? rangeColor;
        for (var otherAttr in controller.attributes) {
          if (otherAttr.color != null &&
              otherAttr.start <= start &&
              otherAttr.end >= end) {
            rangeColor = otherAttr.color;
            break;
          }
        }
        final Color lineColor =
            rangeColor ?? attr.color ?? const Color(0xFFFF5A5A);

        final paint = Paint()
          ..color = lineColor
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.6
          ..strokeCap = StrokeCap.round;

        // 2. 直接获取系统当前最真实的文本排版坐标盒子
        final boxes = re.getBoxesForSelection(
          TextSelection(baseOffset: start, extentOffset: end),
        );

        for (var box in boxes) {
          final rect = box.toRect();
          if (rect.isEmpty || rect.width < 2) continue;

          // 稍微向外扩充，并调整垂直微调以平衡文字视觉重心，使其上下边距一致
          final double paddingX = 6.0;
          final double paddingY = 5.0;
          final double visualOffsetY = -0.5; // 视觉向上微调值，平衡中文字体在文本框中偏下的视觉重心

          final double left = rect.left - paddingX;
          final double right = rect.right + paddingX;
          final double top = rect.top - paddingY + visualOffsetY;
          final double bottom = rect.bottom + paddingY + visualOffsetY;
          final double w = right - left;
          final double h = bottom - top;
          final double midY = top + h / 2;

          Path buildCirclePath(
            double l,
            double r,
            double t,
            double b,
            double width,
            double height,
            double centerY,
          ) {
            return Path()
              ..moveTo(l, centerY)
              ..cubicTo(
                l,
                t + height * 0.15,
                l + width * 0.1,
                t,
                l + width * 0.5,
                t,
              )
              ..cubicTo(r - width * 0.1, t, r, t + height * 0.15, r, centerY)
              ..cubicTo(
                r,
                b - height * 0.15,
                r - width * 0.1,
                b,
                l + width * 0.5,
                b,
              )
              ..cubicTo(l + width * 0.08, b, l, b - height * 0.15, l, centerY)
              ..close();
          }

          if (style == 'circle_double') {
            // 绘制双线椭圆圈
            final pathOuter = buildCirclePath(
              left,
              right,
              top,
              bottom,
              w,
              h,
              midY,
            );
            canvas.drawPath(pathOuter, paint);

            final double innerPaddingX = 3.5;
            final double innerPaddingY = 1.2;
            final double iLeft = rect.left - innerPaddingX;
            final double iRight = rect.right + innerPaddingX;
            final double iTop = rect.top - innerPaddingY + visualOffsetY;
            final double iBottom = rect.bottom + innerPaddingY + visualOffsetY;
            final double iW = iRight - iLeft;
            final double iH = iBottom - iTop;
            final double iMidY = iTop + iH / 2;
            final pathInner = buildCirclePath(
              iLeft,
              iRight,
              iTop,
              iBottom,
              iW,
              iH,
              iMidY,
            );
            canvas.drawPath(pathInner, paint);
          } else if (style == 'circle_dashed') {
            // 绘制虚线椭圆圈
            final mainPath = buildCirclePath(
              left,
              right,
              top,
              bottom,
              w,
              h,
              midY,
            );
            final dashPath = Path();
            for (final metric in mainPath.computeMetrics()) {
              double distance = 0.0;
              bool draw = true;
              while (distance < metric.length) {
                final double len = draw ? 6.0 : 4.0;
                if (draw) {
                  dashPath.addPath(
                    metric.extractPath(
                      distance,
                      (distance + len).clamp(0.0, metric.length),
                    ),
                    Offset.zero,
                  );
                }
                distance += len;
                draw = !draw;
              }
            }
            canvas.drawPath(dashPath, paint);
          } else {
            // 默认单线椭圆圈
            final path = buildCirclePath(left, right, top, bottom, w, h, midY);
            canvas.drawPath(path, paint);
          }
        }
      }
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant DiaryCirclePainter oldDelegate) => true;
}
