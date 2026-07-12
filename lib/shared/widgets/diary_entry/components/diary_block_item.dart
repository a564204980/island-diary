import 'package:flutter/material.dart';
import 'dart:ui' as ui;
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'dart:io';
import 'dart:convert';
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

OverlayEntry? _activeImageToolbarEntry;



class DiaryBlockItem extends StatelessWidget {
  final DiaryBlock block;
  final int index;
  final bool isEmojiOpen;
  final GlobalKey? blockKey;
  final VoidCallback? onRemoveImage;
  final Function(ImageBlock)? onRemoveImageBlock;
  final VoidCallback? onDeleteAtStart; // 新增：在行首按下回退键的回调
  final Function(ImageBlock)? onShowPreview;
  final Function(ImageBlock)? onEditImageBlock;
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
    this.onEditImageBlock,
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

    final inkColor = isNight
        ? Colors.white.withValues(alpha: 0.9)
        : (paperStyle != null
            ? DiaryUtils.getInkColor(paperStyle!, isNight)
            : const Color(0xFF5D4037));
        
    final String fontFamily = UserState().selectedIslandThemeId.value == 'lego'
        ? 'SweiFistLeg'
        : 'LXGWWenKai';

    final tc = block.controller;
    if (tc is DiaryTextEditingController) {
      // 动态适配当前主题的文字颜色（如果之前保存的是默认色）
      if (tc.baseColor.toARGB32() == 0xFF333333 || 
          tc.baseColor.toARGB32() == 0xFFE0C097 || 
          tc.baseColor.toARGB32() == Colors.white.withValues(alpha: 0.9).toARGB32()) {
        tc.baseColor = inkColor;
      }

      // 动态适配字体
      if (tc.baseFontFamily == 'LXGWWenKai' || tc.baseFontFamily == 'SweiFistLeg' || tc.baseFontFamily.isEmpty) {
        tc.baseFontFamily = fontFamily;
      }
      
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
          selectionColor: Colors.transparent, // Disable native selection, drawn by DiaryBrushBackgroundPainter
          selectionHandleColor: const Color(0xFF38383A),
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
                        // 笔刷背景画在底层（先画）
                        foregroundPainter: DiaryCirclePainter(
                          context: builderContext,
                          controller: tc,
                          inkColor: inkColor,
                          blockIndex: index,
                        ),
                        painter: DiaryBrushBackgroundPainter(
                          context: builderContext,
                          controller: tc,
                          selectionColor: inkColor.withValues(alpha: 0.28),
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
                fontFamily: fontFamily,
                fontFamilyFallback: const ['LXGWWenKai'],
              ),
              selectionControls: tc is DiaryTextEditingController 
                  ? BubbleAwareSelectionControls(
                      controller: tc,
                      blockIndex: index,
                      onAddAnnotation: onAddAnnotation,
                      onDeleteAnnotation: onDeleteAnnotation,
                      paperStyle: paperStyle,
                    )
                  : null,
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
                  fontFamily: fontFamily,
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
            final String displayPath = (block.file.path.isNotEmpty &&
                    File(block.file.path).existsSync())
                ? block.file.path
                : (block.localPath ?? block.file.path);

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
                          : () {
                              final RenderBox? renderBox = context.findRenderObject() as RenderBox?;
                              if (renderBox != null) {
                                final size = renderBox.size;
                                final globalOffset = renderBox.localToGlobal(Offset.zero);
                                // 计算图片顶部正中间的全局坐标点
                                final double centerX = globalOffset.dx + size.width / 2;
                                final double topY = globalOffset.dy;
                                _showImageMenu(context, Offset(centerX, topY), block);
                              }
                            },
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
        .map((img) {
          final String fPath = img.file.path;
          return (fPath.isNotEmpty && File(fPath).existsSync())
              ? fPath
              : (img.localPath ?? fPath);
        })
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
                              (imgBlock.file.path.isNotEmpty && File(imgBlock.file.path).existsSync())
                                  ? imgBlock.file.path
                                  : (imgBlock.localPath ?? imgBlock.file.path),
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
          onTapImage: (idx, ctx) {
            if (onRemoveImageBlock != null) {
              final RenderBox? renderBox = ctx.findRenderObject() as RenderBox?;
              if (renderBox != null) {
                final size = renderBox.size;
                final globalOffset = renderBox.localToGlobal(Offset.zero);
                final double centerX = globalOffset.dx + size.width / 2;
                final double topY = globalOffset.dy;
                _showImageMenu(ctx, Offset(centerX, topY), block.images[idx]);
              }
            } else {
              if (onShowPreview != null) {
                onShowPreview!(block.images[idx]);
              }
            }
          },
          onDeleteImage: onRemoveImageBlock != null
              ? (idx) => onRemoveImageBlock!(block.images[idx])
              : null,
        ),
      ),
    );
  }

  void _showImageMenu(BuildContext context, Offset topCenterPos, ImageBlock block) {
    // 自动清理之前的气泡，确保页面唯一性
    _activeImageToolbarEntry?.remove();
    _activeImageToolbarEntry = null;

    final RenderBox overlay = Overlay.of(context).context.findRenderObject() as RenderBox;
    
    // 胶囊气泡的假定宽高 (横向排列)
    final double toolbarW = 160.0;
    final double toolbarH = 42.0;
    
    // 居中左右定位，并进行屏幕安全边距限制 (16dp)
    double left = topCenterPos.dx - toolbarW / 2;
    if (left < 16) left = 16;
    if (left + toolbarW > overlay.size.width - 16) {
      left = overlay.size.width - toolbarW - 16;
    }
    
    // 始终弹在图片顶部正上方的 10 像素处
    double top = topCenterPos.dy - toolbarH - 10;
    if (top < 60) {
      // 如果位置太靠屏幕顶端，则弹在图片顶部边缘下方 10 像素处
      top = topCenterPos.dy + 10;
    }

    _activeImageToolbarEntry = OverlayEntry(
      builder: (ctx) {
        return Stack(
          children: [
            // 全屏点击劫持层：点击气泡外任何地方，均会隐式销毁当前浮动气泡
            GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () {
                _activeImageToolbarEntry?.remove();
                _activeImageToolbarEntry = null;
              },
              child: const SizedBox.expand(),
            ),
            Positioned(
              left: left,
              top: top,
              child: Material(
                color: Colors.transparent,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF2F2F2F), // 完美匹配文字选区气泡颜色
                    borderRadius: BorderRadius.circular(20), // 胶囊圆角
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.3),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _buildToolbarItem("编辑", () {
                        _activeImageToolbarEntry?.remove();
                        _activeImageToolbarEntry = null;
                        onEditImageBlock?.call(block);
                      }),
                      _buildToolbarDivider(),
                      _buildToolbarItem("预览", () {
                        _activeImageToolbarEntry?.remove();
                        _activeImageToolbarEntry = null;
                        onShowPreview?.call(block);
                      }),
                      _buildToolbarDivider(),
                      _buildToolbarItem("删除", () {
                        _activeImageToolbarEntry?.remove();
                        _activeImageToolbarEntry = null;
                        if (onRemoveImageBlock != null) {
                          onRemoveImageBlock!(block);
                        } else {
                          onRemoveImage?.call();
                        }
                      }, isDanger: true),
                    ],
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );

    Overlay.of(context).insert(_activeImageToolbarEntry!);
  }

  Widget _buildToolbarItem(String text, VoidCallback onTap, {bool isDanger = false}) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
        child: Text(
          text,
          style: TextStyle(
            color: isDanger ? Colors.redAccent : Colors.white,
            fontSize: 13,
            fontWeight: FontWeight.w600,
            fontFamily: 'LXGWWenKai',
          ),
        ),
      ),
    );
  }

  Widget _buildToolbarDivider() {
    return Container(
      width: 1,
      height: 12,
      color: Colors.white24,
      margin: const EdgeInsets.symmetric(horizontal: 2),
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

/// 在文字下方绘制笔刷高亮背景，突破 TextStyle.background 的矩形裁剪限制
class DiaryBrushBackgroundPainter extends CustomPainter {
  final BuildContext context;
  final DiaryTextEditingController controller;
  final Color? selectionColor;

  DiaryBrushBackgroundPainter({
    required this.context,
    required this.controller,
    this.selectionColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (controller.text.isEmpty) return;

    // 找到 RenderEditable（复用 DiaryCirclePainter 的思路）
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

    final Offset offset =
        re.localToGlobal(Offset.zero) - myBox.localToGlobal(Offset.zero);

    canvas.save();
    canvas.translate(offset.dx, offset.dy);

    final List<Map<String, dynamic>> regionsToPaint = [];

    for (var attr in controller.attributes) {
      if (attr.backgroundColor != null) {
        regionsToPaint.add({
          'start': attr.start,
          'end': attr.end,
          'color': attr.backgroundColor,
        });
      }
    }

    final annotations = controller.annotations;
    if (annotations != null) {
      annotations.forEach((key, value) {
        final parts = key.split('_');
        if (parts.length == 3 && int.tryParse(parts[0]) == controller.blockIndex) {
          final startVal = int.tryParse(parts[1]);
          final endVal = int.tryParse(parts[2]);
          if (startVal != null && endVal != null) {
            int start = startVal;
            int end = endVal;
            while (end > start && end <= controller.text.length &&
                (controller.text[end - 1] == '\n' ||
                 controller.text[end - 1] == '\r' ||
                 controller.text[end - 1] == ' ' ||
                 controller.text[end - 1] == '\u200B')) {
              end--;
            }
            if (start < end) {
              Map<String, dynamic>? data;
              try {
                data = jsonDecode(value);
              } catch (_) {}
              final colorHex = data?['colorHex'] ?? '#F7E5B4';
              final color = Color(int.parse(colorHex.replaceFirst('#', '0xFF')));
              regionsToPaint.add({
                'start': start,
                'end': end,
                'color': color.withValues(alpha: 0.4),
                'isAnnotation': true,
              });
            }
          }
        }
      });
    }

    for (var region in regionsToPaint) {
      final bgColor = region['color'] as Color;
      final start = (region['start'] as int).clamp(0, controller.text.length);
      final end = (region['end'] as int).clamp(0, controller.text.length);
      if (start >= end) continue;

      final boxes = re.getBoxesForSelection(
        TextSelection(baseOffset: start, extentOffset: end),
      );

      final isAnnotation = region['isAnnotation'] == true;

      for (int i = 0; i < boxes.length; i++) {
        final box = boxes[i];
        final rect = box.toRect();
        if (rect.isEmpty || rect.width < 2) continue;

        // 去除左右向外延伸，因为 StrokeCap.round 会自动两端增加半个线宽的圆角
        const double padX = 0.0;
        const double padY = 3.0;
        final double l = rect.left - padX;
        double r = rect.right + padX;

        // 如果是批注，且是最后一个 box，需要减去气泡图标的宽度 (21px)，以免背景色涂到气泡上
        if (isAnnotation && i == boxes.length - 1) {
          r -= 21.0;
        }

        final double t = rect.top + padY;
        final double b = rect.bottom - padY;
        final double h = b - t;
        if (h <= 0) continue;

        _drawBrushStroke(canvas, l, r, t, b, h, bgColor);
      }
    }

    // 绘制自定义的文本选择高亮（为了避开批注的气泡）
    if (selectionColor != null && controller.selection.isValid && !controller.selection.isCollapsed) {
      final selection = controller.selection;
      final selBoxes = re.getBoxesForSelection(selection);
      final paint = Paint()..color = selectionColor!..style = PaintingStyle.fill;

      Path selectionPath = Path();
      for (var box in selBoxes) {
        selectionPath.addRect(box.toRect());
      }

      final currentAnnotations = controller.annotations;
      if (currentAnnotations != null) {
        currentAnnotations.forEach((key, value) {
          final parts = key.split('_');
          if (parts.length == 3 && int.tryParse(parts[0]) == controller.blockIndex) {
            final startVal = int.tryParse(parts[1]);
            final endVal = int.tryParse(parts[2]);
            if (startVal != null && endVal != null) {
              int annEnd = endVal;
              while (annEnd > startVal && annEnd <= controller.text.length &&
                  (controller.text[annEnd - 1] == '\n' ||
                   controller.text[annEnd - 1] == '\r' ||
                   controller.text[annEnd - 1] == ' ' ||
                   controller.text[annEnd - 1] == '\u200B')) {
                annEnd--;
              }
              
              if (annEnd > selection.start && annEnd <= selection.end) {
                final bBoxes = re.getBoxesForSelection(TextSelection(baseOffset: annEnd - 1, extentOffset: annEnd));
                if (bBoxes.isNotEmpty) {
                  final bBox = bBoxes.last.toRect();
                  // 气泡位于最后一个字符的右侧 21 像素区域，将其从选择高亮区域中挖掉
                  final bubbleRect = Rect.fromLTRB(bBox.right - 21.0, bBox.top, bBox.right, bBox.bottom);
                  selectionPath = Path.combine(PathOperation.difference, selectionPath, Path()..addRect(bubbleRect));
                }
              }
            }
          }
        });
      }
      canvas.drawPath(selectionPath, paint);
    }

    canvas.restore();
  }

    void _drawBrushStroke(
    Canvas canvas,
    double l,
    double r,
    double t,
    double b,
    double h,
    Color color,
  ) {
    // Draw a clean, standard rounded rectangle highlight
    final double paddingX = 0.0;
    l += paddingX;
    r -= paddingX;

    final w = r - l;
    if (w <= 0) return;

    final paint = Paint()
      ..style = PaintingStyle.fill
      ..color = color.withValues(alpha: 0.35);

    // Provide a small border radius for a polished look
    final rect = RRect.fromLTRBR(l, t + h * 0.1, r, b - h * 0.1, const Radius.circular(4.0));
    canvas.drawRRect(rect, paint);
  }

  @override
  bool shouldRepaint(DiaryBrushBackgroundPainter oldDelegate) {
    return oldDelegate.controller != controller ||
        oldDelegate.controller.attributes != controller.attributes;
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

class BubbleAwareSelectionControls extends MaterialTextSelectionControls {
  final DiaryTextEditingController controller;
  final int blockIndex;
  final Function({
    String? key,
    required int blockIndex,
    required int start,
    required int end,
    required String selectedText,
  })? onAddAnnotation;
  final Function(String key)? onDeleteAnnotation;
  final String? paperStyle;

  BubbleAwareSelectionControls({
    required this.controller,
    required this.blockIndex,
    this.onAddAnnotation,
    this.onDeleteAnnotation,
    this.paperStyle,
  });

  @override
  Widget buildHandle(BuildContext context, TextSelectionHandleType type, double textHeight, [VoidCallback? onTap]) {
    Widget handle = super.buildHandle(context, type, textHeight, onTap);

    bool isBubbleEnd = false;
    final annotations = controller.annotations;
    if (annotations != null) {
      annotations.forEach((key, value) {
        final parts = key.split('_');
        if (parts.length == 3 && int.tryParse(parts[0]) == controller.blockIndex) {
          final startVal = int.tryParse(parts[1]);
          final endVal = int.tryParse(parts[2]);
          if (startVal != null && endVal != null) {
            int annEnd = endVal;
            while (annEnd > startVal && annEnd <= controller.text.length &&
                (controller.text[annEnd - 1] == '\n' ||
                 controller.text[annEnd - 1] == '\r' ||
                 controller.text[annEnd - 1] == ' ' ||
                 controller.text[annEnd - 1] == '\u200B')) {
              annEnd--;
            }
            if (type == TextSelectionHandleType.right && controller.selection.end == annEnd) {
              isBubbleEnd = true;
            }
            if (type == TextSelectionHandleType.left && controller.selection.start == annEnd) {
              isBubbleEnd = true;
            }
            if (type == TextSelectionHandleType.collapsed && controller.selection.extentOffset == annEnd) {
              isBubbleEnd = true;
            }
          }
        }
      });
    }

    if (isBubbleEnd) {
      return Transform.translate(
        offset: const Offset(-21.0, 0),
        child: handle,
      );
    }
    return handle;
  }

  @override
  Widget buildToolbar(
    BuildContext context,
    Rect globalEditableRegion,
    double textLineHeight,
    Offset selectionMidpoint,
    List<TextSelectionPoint> endpoints,
    TextSelectionDelegate delegate,
    dynamic clipboardStatus,
    Offset? lastSecondaryTapDownPosition,
  ) {
    if (onAddAnnotation == null) {
      return super.buildToolbar(
        context,
        globalEditableRegion,
        textLineHeight,
        selectionMidpoint,
        endpoints,
        delegate,
        clipboardStatus,
        lastSecondaryTapDownPosition,
      );
    }
    return DiaryTextContextMenu(
      editableTextState: delegate as EditableTextState,
      blockIndex: blockIndex,
      annotations: controller.annotations ?? const {},
      onAddAnnotation: onAddAnnotation!,
      onDeleteAnnotation: onDeleteAnnotation,
      showAnnotation: false,
      showUnderline: true,
      paperStyle: paperStyle,
    );
  }
}
