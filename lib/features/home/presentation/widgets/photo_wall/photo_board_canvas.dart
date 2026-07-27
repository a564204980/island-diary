import 'dart:io';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:island_diary/core/services/wind_service.dart';
import 'package:island_diary/features/home/domain/models/photo_wall_collection.dart';
import 'package:island_diary/features/home/presentation/widgets/photo_wall/photo_board_decorations.dart';
import 'package:island_diary/features/home/presentation/widgets/photo_wall/treemap_splitter.dart';
import 'package:island_diary/features/home/presentation/widgets/photo_wall/wall_layout_mode.dart';
import 'package:island_diary/shared/animations/bouncing_button.dart';
import 'package:island_diary/shared/animations/wind_dissolve_effect.dart';

class PhotoDissolveData {
  final String id;
  final Offset position;
  final Size size;
  final double angle;
  final WindMode windMode;

  const PhotoDissolveData({
    required this.id,
    required this.position,
    required this.size,
    required this.angle,
    required this.windMode,
  });
}

/// 展板画布与拖拽交互主体渲染组件 (PhotoBoardCanvas)
class PhotoBoardCanvas extends StatefulWidget {
  final PhotoWallCollection collection;
  final WallLayoutMode layoutMode;
  final bool showWashiTape;
  final bool isDark;
  final double boardWidth;
  final double boardHeight;
  final List<String> photoIds;
  final Map<String, Offset> photoCustomPositions;
  final Map<String, double> photoCustomAngles;
  final Map<String, double> photoCustomScales;
  final int randomSeed;
  final List<String> presetPhotos;
  final Function(String path, int index) onPreviewPhoto;
  final Function(String photoId) onRemovePhoto;
  final VoidCallback onStateChanged;
  final GlobalKey? canvasBoundaryKey;
  final bool isEditing;

  const PhotoBoardCanvas({
    super.key,
    required this.collection,
    required this.layoutMode,
    required this.showWashiTape,
    required this.isDark,
    required this.boardWidth,
    required this.boardHeight,
    required this.photoIds,
    required this.photoCustomPositions,
    required this.photoCustomAngles,
    required this.photoCustomScales,
    required this.randomSeed,
    required this.presetPhotos,
    required this.onPreviewPhoto,
    required this.onRemovePhoto,
    required this.onStateChanged,
    this.canvasBoundaryKey,
    this.isEditing = true,
  });

  @override
  State<PhotoBoardCanvas> createState() => PhotoBoardCanvasState();
}

class PhotoBoardCanvasState extends State<PhotoBoardCanvas> {
  String? _selectedPhotoId;
  int? _draggingTreemapIndex;
  double? _rotateStartTouchAngle;
  double? _rotateStartCardAngle;
  Offset? _panStartGlobalPos;
  Offset? _panStartCardPos;
  final List<PhotoDissolveData> _activeDissolves = [];
  bool _isAnimationDone = false;

  @override
  void initState() {
    super.initState();
    _startAnimationTimer();
  }

  void _startAnimationTimer() {
    _isAnimationDone = false;
    final delayMs = widget.photoIds.length * 130 + 1000;
    Future.delayed(Duration(milliseconds: delayMs), () {
      if (mounted) {
        setState(() => _isAnimationDone = true);
      }
    });
  }

  @override
  void deactivate() {
    _selectedPhotoId = null;
    super.deactivate();
  }

  @override
  void dispose() {
    _selectedPhotoId = null;
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant PhotoBoardCanvas oldWidget) {
    super.didUpdateWidget(oldWidget);
    if ((!widget.isEditing || oldWidget.layoutMode != widget.layoutMode) && _selectedPhotoId != null) {
      setState(() {
        _selectedPhotoId = null;
      });
    }
    if (oldWidget.layoutMode != widget.layoutMode || oldWidget.photoIds.length != widget.photoIds.length) {
      _startAnimationTimer();
    }
  }

  void clearSelection() {
    if (_selectedPhotoId != null) {
      setState(() {
        _selectedPhotoId = null;
      });
    }
  }

  void _selectPhoto(String id) {
    setState(() {
      _selectedPhotoId = id;
    });
  }

  void _rotatePhoto(String id, double currentAngle) {
    HapticFeedback.lightImpact();
    setState(() {
      widget.photoCustomAngles[id] = (widget.photoCustomAngles[id] ?? currentAngle) + (math.pi / 4);
    });
    widget.onStateChanged();
  }

  void _swapTreemapPhotos(int srcIndex, int targetIndex) {
    if (srcIndex < 0 || srcIndex >= widget.photoIds.length) return;
    if (targetIndex < 0 || targetIndex >= widget.photoIds.length) return;

    HapticFeedback.heavyImpact();
    setState(() {
      final tempId = widget.photoIds[srcIndex];
      widget.photoIds[srcIndex] = widget.photoIds[targetIndex];
      widget.photoIds[targetIndex] = tempId;

      final tempPath = widget.collection.photoPaths[srcIndex];
      widget.collection.photoPaths[srcIndex] = widget.collection.photoPaths[targetIndex];
      widget.collection.photoPaths[targetIndex] = tempPath;
    });
    widget.onStateChanged();
  }

  void _scalePhoto(String id) {
    HapticFeedback.lightImpact();
    setState(() {
      final currentScale = widget.photoCustomScales[id] ?? 1.0;
      double nextScale;
      if (currentScale < 1.15) {
        nextScale = 1.35;
      } else if (currentScale < 1.45) {
        nextScale = 1.70;
      } else {
        nextScale = 1.0;
      }
      widget.photoCustomScales[id] = nextScale;
    });
    widget.onStateChanged();
  }

  void _removePhotoWithDissolve(String id, {Size cardSize = const Size(80, 92)}) {
    HapticFeedback.mediumImpact();
    final pos = widget.photoCustomPositions[id] ?? Offset.zero;
    final angle = widget.photoCustomAngles[id] ?? 0.0;

    final currentWindMode = WindService.currentWind.value;

    setState(() {
      _selectedPhotoId = null;
      _activeDissolves.add(
        PhotoDissolveData(
          id: id,
          position: pos,
          size: cardSize,
          angle: angle,
          windMode: currentWindMode,
        ),
      );
    });

    widget.onRemovePhoto(id);
  }

  void _showLayerMenu(BuildContext btnContext, String id) {
    HapticFeedback.selectionClick();

    final RenderBox renderBox = btnContext.findRenderObject() as RenderBox;
    final Offset buttonOffset = renderBox.localToGlobal(Offset.zero);
    final Size buttonSize = renderBox.size;

    showMenu<String>(
      context: context,
      position: RelativeRect.fromLTRB(
        buttonOffset.dx,
        buttonOffset.dy + buttonSize.height,
        buttonOffset.dx + buttonSize.width,
        buttonOffset.dy + buttonSize.height + 100,
      ),
      color: widget.isDark ? const Color(0xFF1E293B) : Colors.white,
      elevation: 12,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      items: [
        PopupMenuItem<String>(
          value: 'front',
          height: 38,
          child: Row(
            children: [
              Icon(Icons.vertical_align_top_rounded,
                  size: 16,
                  color: widget.isDark ? Colors.white70 : const Color(0xFF1E293B)),
              const SizedBox(width: 8),
              Text("移至最顶层",
                  style: TextStyle(
                      fontSize: 13,
                      color: widget.isDark ? Colors.white : const Color(0xFF1E293B))),
            ],
          ),
        ),
        PopupMenuItem<String>(
          value: 'back',
          height: 38,
          child: Row(
            children: [
              Icon(Icons.vertical_align_bottom_rounded,
                  size: 16,
                  color: widget.isDark ? Colors.white70 : const Color(0xFF1E293B)),
              const SizedBox(width: 8),
              Text("移至最底层",
                  style: TextStyle(
                      fontSize: 13,
                      color: widget.isDark ? Colors.white : const Color(0xFF1E293B))),
            ],
          ),
        ),
      ],
    ).then((val) {
      if (val == null) return;
      final index = widget.photoIds.indexOf(id);
      if (index == -1) return;

      setState(() {
        if (val == 'front') {
          final targetId = widget.photoIds.removeAt(index);
          widget.photoIds.add(targetId);
          final targetPath = widget.collection.photoPaths.removeAt(index);
          widget.collection.photoPaths.add(targetPath);
        } else if (val == 'back') {
          final targetId = widget.photoIds.removeAt(index);
          widget.photoIds.insert(0, targetId);
          final targetPath = widget.collection.photoPaths.removeAt(index);
          widget.collection.photoPaths.insert(0, targetPath);
        }
      });
      widget.onStateChanged();
    });
  }

  Widget _buildWashiTapeWidget(int seed, double handlePadding) {
    if (!widget.showWashiTape) return const SizedBox.shrink();

    const tapeConfigs = [
      WashiTapeConfig(color: Color(0xFFE6C594), angle: -0.28, isLeft: true, width: 34.0, height: 12.0),
      WashiTapeConfig(color: Color(0xFFA3C9A8), angle: 0.30, isLeft: false, width: 34.0, height: 12.0),
      WashiTapeConfig(color: Color(0xFFF2B5D4), angle: -0.24, isLeft: true, width: 34.0, height: 12.0),
      WashiTapeConfig(color: Color(0xFFC4B2E6), angle: 0.26, isLeft: false, width: 34.0, height: 12.0),
    ];
    final config = tapeConfigs[seed.abs() % tapeConfigs.length];

    return Positioned(
      top: handlePadding + 3,
      left: config.isLeft ? handlePadding - 4 : null,
      right: !config.isLeft ? handlePadding - 4 : null,
      child: Transform.rotate(
        angle: config.angle,
        child: SizedBox(
          width: config.width,
          height: config.height,
          child: CustomPaint(
            painter: WashiTapePainter(color: config.color),
          ),
        ),
      ),
    );
  }

  static const List<String> _fallbackSceneryBgs = [
    'assets/images/backgrounds/bg1.png',
    'assets/images/backgrounds/bg2.png',
    'assets/images/backgrounds/bg3.png',
    'assets/images/backgrounds/bg4.png',
    'assets/images/backgrounds/bg5.png',
  ];

  Widget _buildPhotoWidget(String path, int seed, {double? height}) {
    final double h = height ?? double.infinity;
    final fallbackAsset = _fallbackSceneryBgs[seed.abs() % _fallbackSceneryBgs.length];

    if (path.isNotEmpty && path.startsWith('assets/')) {
      return Image.asset(
        path,
        fit: BoxFit.cover,
        height: h,
        width: double.infinity,
        errorBuilder: (context, error, stackTrace) => Image.asset(
          fallbackAsset,
          fit: BoxFit.cover,
          height: h,
          width: double.infinity,
        ),
      );
    }
    if (path.isNotEmpty) {
      final file = File(path);
      if (file.existsSync()) {
        return Image.file(
          file,
          fit: BoxFit.cover,
          height: h,
          width: double.infinity,
          errorBuilder: (context, error, stackTrace) => Image.asset(
            fallbackAsset,
            fit: BoxFit.cover,
            height: h,
            width: double.infinity,
          ),
        );
      }
    }
    return Image.asset(
      fallbackAsset,
      fit: BoxFit.cover,
      height: h,
      width: double.infinity,
    );
  }

  Widget _buildHandleButton({
    required IconData icon,
    VoidCallback? onTap,
    void Function(BuildContext context)? onTapWithContext,
    GestureDragStartCallback? onPanStart,
    GestureDragUpdateCallback? onPanUpdate,
    GestureDragEndCallback? onPanEnd,
  }) {
    return Builder(
      builder: (btnContext) {
        void handleTap() {
          HapticFeedback.selectionClick();
          if (onTapWithContext != null) {
            onTapWithContext(btnContext);
          } else if (onTap != null) {
            onTap();
          }
        }

        return GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: handleTap,
          onPanStart: onPanStart,
          onPanUpdate: onPanUpdate,
          onPanEnd: onPanEnd,
          child: BouncingButton(
            onTap: handleTap,
            scaleFactor: 0.88,
            child: Container(
              width: 48,
              height: 48,
              color: Colors.transparent,
              child: Center(
                child: Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: const Color(0xFF64748B).withValues(alpha: 0.25),
                      width: 1.0,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.28),
                        blurRadius: 7,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Center(
                    child: Icon(
                      icon,
                      size: 17,
                      color: const Color(0xFF334155),
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final boardWidth = widget.boardWidth;
    final boardHeight = widget.boardHeight;
    final isDark = widget.isDark;
    late Widget canvasContent;

    if (widget.collection.photoPaths.isEmpty) {
      canvasContent = Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.collections_outlined,
              size: 42,
              color: isDark
                  ? Colors.white.withValues(alpha: 0.35)
                  : const Color(0xFF64748B).withValues(alpha: 0.5),
            ),
            const SizedBox(height: 10),
            Text(
              "暂无照片",
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                fontFamily: 'LXGWWenKai',
                color: isDark ? Colors.white70 : const Color(0xFF334155),
                decoration: TextDecoration.none,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              "点击下方「钉入照片」放入画框",
              style: TextStyle(
                fontSize: 12,
                fontFamily: 'LXGWWenKai',
                color: isDark
                    ? Colors.white38
                    : const Color(0xFF64748B),
                decoration: TextDecoration.none,
              ),
            ),
          ],
        ),
      );
    } else if (widget.layoutMode == WallLayoutMode.treemap) {
      final count = widget.collection.photoPaths.length;
      const double refW = 330.0;
      const double refH = 568.0;
      final double scaleX = boardWidth / refW;
      final double scaleY = boardHeight / refH;

      final refBounds = Rect.fromLTWH(10, 10, refW - 20, refH - 20);
      final indices = List.generate(count, (i) => i);
      final leaves = TreemapSplitter.computeLeaves(refBounds, indices, widget.randomSeed);

      canvasContent = SizedBox(
        height: boardHeight,
        width: boardWidth,
        child: Stack(
          clipBehavior: _isAnimationDone ? Clip.hardEdge : Clip.none,
          children: leaves.map((leaf) {
            final path = widget.collection.photoPaths[leaf.index];
            const gap = 3.0;
            final cardRect = Rect.fromLTRB(
              leaf.rect.left * scaleX,
              leaf.rect.top * scaleY,
              leaf.rect.right * scaleX,
              leaf.rect.bottom * scaleY,
            ).deflate(gap);

            final bool isDraggingAny = _draggingTreemapIndex != null;
            final bool isThisDragging = _draggingTreemapIndex == leaf.index;

            Widget buildTreemapCardWidget({bool isFeedback = false, bool isHovered = false, bool isDraggingOther = false}) {
              final hoverBorderColor = widget.isDark ? const Color(0xFF38BDF8) : const Color(0xFF0284C7);

              return Stack(
                clipBehavior: Clip.none,
                alignment: Alignment.topCenter,
                children: [
                  Positioned.fill(
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 220),
                      curve: Curves.easeOutCubic,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: isHovered
                            ? Border.all(
                                color: hoverBorderColor,
                                width: 3.0,
                              )
                            : null,
                        boxShadow: [
                          if (isHovered)
                            BoxShadow(
                              color: hoverBorderColor.withValues(alpha: 0.55),
                              blurRadius: 12,
                              spreadRadius: 2,
                            )
                          else if (isDraggingOther)
                            BoxShadow(
                              color: hoverBorderColor.withValues(alpha: 0.20),
                              blurRadius: 10,
                              spreadRadius: 1,
                            )
                          else
                            BoxShadow(
                              color: isFeedback ? Colors.black.withValues(alpha: 0.45) : Colors.black38,
                              blurRadius: isFeedback ? 14 : 6,
                              offset: isFeedback ? const Offset(0, 6) : const Offset(0, 3),
                            ),
                        ],
                      ),
                      padding: const EdgeInsets.all(3),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(14),
                        child: _buildPhotoWidget(path, widget.photoIds[leaf.index].hashCode),
                      ),
                    ),
                  ),
                  _buildWashiTapeWidget(widget.photoIds[leaf.index].hashCode, 0.0),
                  Positioned(
                    top: -6,
                    child: PushPinWidget(index: widget.photoIds[leaf.index].hashCode).animate(
                      key: ValueKey('anim_treemap_pin_${leaf.index}'),
                    ).fadeIn(
                      duration: 1.ms,
                      delay: (leaf.index * 140 + 460).ms,
                    ).scale(
                      begin: const Offset(1.8, 1.8),
                      end: const Offset(1.0, 1.0),
                      duration: 260.ms,
                      curve: Curves.bounceOut,
                      delay: (leaf.index * 140 + 460).ms,
                    ).slideY(
                      begin: -1.5,
                      end: 0,
                      duration: 260.ms,
                      curve: Curves.easeOutCubic,
                      delay: (leaf.index * 140 + 460).ms,
                    ),
                  ),
                ],
              );
            }

            return Positioned(
              left: cardRect.left,
              top: cardRect.top,
              width: cardRect.width,
              height: cardRect.height,
              child: DragTarget<int>(
                onWillAcceptWithDetails: (details) => details.data != leaf.index,
                onAcceptWithDetails: (details) {
                  _swapTreemapPhotos(details.data, leaf.index);
                },
                builder: (context, candidateData, rejectedData) {
                  final isHovered = candidateData.isNotEmpty;
                  final isDraggingOther = isDraggingAny && !isThisDragging && !isHovered;
                  final double scaleTarget = isHovered ? 0.93 : (isDraggingOther ? 0.965 : 1.0);

                  return AnimatedScale(
                    scale: scaleTarget,
                    duration: const Duration(milliseconds: 220),
                    curve: Curves.easeOutCubic,
                    child: LongPressDraggable<int>(
                      data: leaf.index,
                      feedback: Material(
                        color: Colors.transparent,
                        child: Transform.rotate(
                          angle: -0.06,
                          child: SizedBox(
                            width: cardRect.width * 1.05,
                            height: cardRect.height * 1.05,
                            child: buildTreemapCardWidget(isFeedback: true),
                          ),
                        ),
                      ),
                      childWhenDragging: Opacity(
                        opacity: 0.35,
                        child: buildTreemapCardWidget(),
                      ),
                      onDragStarted: () {
                        HapticFeedback.heavyImpact();
                        setState(() {
                          _draggingTreemapIndex = leaf.index;
                        });
                      },
                      onDragEnd: (_) {
                        setState(() {
                          _draggingTreemapIndex = null;
                        });
                      },
                      onDraggableCanceled: (_, _) {
                        setState(() {
                          _draggingTreemapIndex = null;
                        });
                      },
                      child: BouncingButton(
                        onTap: () {
                          if (_selectedPhotoId != null) {
                            setState(() => _selectedPhotoId = null);
                          }
                        },
                        scaleFactor: 1.05,
                        child: buildTreemapCardWidget(isHovered: isHovered, isDraggingOther: isDraggingOther),
                      ),
                    ),
                  );
                },
              ).animate(
                key: ValueKey('anim_treemap_card_${leaf.index}'),
                target: _isAnimationDone ? 1.0 : null,
              ).custom(
                duration: 850.ms,
                delay: (leaf.index * 130).ms,
                curve: Curves.easeOutBack,
                builder: (context, value, child) {
                  final double rotateY = (1.0 - value) * math.pi * 4.0;
                  final double rotateX = (1.0 - value) * (leaf.index % 2 == 0 ? 0.35 : -0.35);
                  final double scale = 1.0 + (1.0 - value) * 0.40;
                  final double opacity = value.clamp(0.0, 1.0);

                  final matrix = Matrix4.identity()
                    ..setEntry(3, 2, 0.0018)
                    ..rotateY(rotateY)
                    ..rotateX(rotateX);

                  return Transform(
                    transform: matrix,
                    alignment: Alignment.center,
                    child: Transform.scale(
                      scale: scale,
                      child: Opacity(
                        opacity: opacity,
                        child: child,
                      ),
                    ),
                  );
                },
              ),
            );
          }).toList(),
        ),
      );
    } else {
      final count = widget.collection.photoPaths.length;
      const int cols = 3;
      const int maxRows = 3;

      final maxAvailableW = (boardWidth - 24.0) / cols;
      final cardW = (maxAvailableW * 0.90).clamp(48.0, 96.0);
      final cardH = (cardW * 1.15).clamp(55.0, 110.0);

      final rowStep = (boardHeight - cardH - 24.0) / (maxRows - 1);
      final colStep = (boardWidth - cardW - 24.0) / (cols - 1);

      canvasContent = GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => setState(() => _selectedPhotoId = null),
        child: SizedBox(
          height: boardHeight,
          width: boardWidth,
          child: Stack(
            clipBehavior: _isAnimationDone ? Clip.hardEdge : Clip.none,
            children: [
              ...List.generate(count, (index) {
                final path = widget.collection.photoPaths[index];
                final id = widget.photoIds[index];

                if (!widget.photoCustomPositions.containsKey(id)) {
                  final rand = math.Random(widget.randomSeed + id.hashCode);
                  final col = id.hashCode.abs() % cols;
                  final row = (id.hashCode.abs() ~/ cols) % maxRows;

                  final offsetX = (rand.nextDouble() - 0.5) * 12.0;
                  final offsetY = (rand.nextDouble() - 0.5) * 12.0;

                  final defaultLeft = (16.0 + col * colStep + offsetX)
                      .clamp(16.0, boardWidth - cardW - 16.0);
                  final defaultTop = (16.0 + row * rowStep + offsetY)
                      .clamp(16.0, boardHeight - cardH - 16.0);
                  widget.photoCustomPositions[id] = Offset(defaultLeft, defaultTop);

                  final defaultAngle = (rand.nextDouble() - 0.5) * 0.32;
                  widget.photoCustomAngles[id] ??= defaultAngle;
                }

                final currentPos = widget.photoCustomPositions[id]!;
                final currentAngle = widget.photoCustomAngles[id] ?? 0.0;
                final userScale = widget.photoCustomScales[id] ?? 1.0;

                final double scaledCardW = cardW * userScale;
                final double scaledCardH = cardH * userScale;

                final left = currentPos.dx.clamp(14.0, math.max(14.0, boardWidth - scaledCardW - 14.0)).toDouble();
                final top = currentPos.dy.clamp(14.0, math.max(14.0, boardHeight - scaledCardH - 14.0)).toDouble();
                final isSelected = _selectedPhotoId == id;
                const double handlePadding = 24.0;
                final double totalW = scaledCardW + handlePadding * 2;
                final double totalH = scaledCardH + handlePadding * 2;

                // 计算旋转与放大后卡片的外接矩形，确保 Positioned 的 HitTest 区域完整包裹旋转后的四个角按钮
                final double cosA = math.cos(currentAngle).abs();
                final double sinA = math.sin(currentAngle).abs();
                final double maxScale = isSelected ? 1.08 : 1.0;
                final double boundingW = (totalW * cosA + totalH * sinA) * maxScale + 16.0;
                final double boundingH = (totalW * sinA + totalH * cosA) * maxScale + 16.0;

                final double centerX = left + scaledCardW / 2;
                final double centerY = top + scaledCardH / 2;

                return Positioned(
                  key: ValueKey(id),
                  left: centerX - boundingW / 2,
                  top: centerY - boundingH / 2,
                  width: boundingW,
                  height: boundingH,
                  child: Center(
                    child: AnimatedScale(
                      scale: isSelected ? 1.04 : 1.0,
                      duration: const Duration(milliseconds: 160),
                      curve: Curves.easeOutBack,
                      child: Transform.rotate(
                        angle: currentAngle,
                        child: SizedBox(
                          width: totalW,
                          height: totalH,
                          child: Stack(
                            clipBehavior: Clip.none,
                            alignment: Alignment.topCenter,
                            children: [
                              Padding(
                                padding: const EdgeInsets.all(handlePadding),
                                child: GestureDetector(
                                  behavior: HitTestBehavior.opaque,
                                  onTap: () {
                                    HapticFeedback.selectionClick();
                                    _selectPhoto(id);
                                  },
                                  onLongPressStart: (details) {
                                    HapticFeedback.heavyImpact();
                                    _selectPhoto(id);
                                    _panStartGlobalPos = details.globalPosition;
                                    _panStartCardPos = widget.photoCustomPositions[id] ?? Offset(left, top);
                                  },
                                  onLongPressMoveUpdate: (details) {
                                    if (_selectedPhotoId == id && _panStartGlobalPos != null && _panStartCardPos != null) {
                                      final double dx = details.globalPosition.dx - _panStartGlobalPos!.dx;
                                      final double dy = details.globalPosition.dy - _panStartGlobalPos!.dy;

                                      final double newX = (_panStartCardPos!.dx + dx)
                                          .clamp(14.0, math.max(14.0, boardWidth - scaledCardW - 14.0))
                                          .toDouble();
                                      final double newY = (_panStartCardPos!.dy + dy)
                                          .clamp(14.0, math.max(14.0, boardHeight - scaledCardH - 14.0))
                                          .toDouble();

                                      setState(() {
                                        widget.photoCustomPositions[id] = Offset(newX, newY);
                                      });
                                    }
                                  },
                                  onLongPressEnd: (_) {
                                    _panStartGlobalPos = null;
                                    _panStartCardPos = null;
                                    widget.onStateChanged();
                                  },
                                  onLongPressUp: () {
                                    _panStartGlobalPos = null;
                                    _panStartCardPos = null;
                                    widget.onStateChanged();
                                  },
                                  onPanStart: (details) {
                                    _selectPhoto(id);
                                    _panStartGlobalPos = details.globalPosition;
                                    _panStartCardPos = widget.photoCustomPositions[id] ?? Offset(left, top);
                                  },
                                  onPanUpdate: (details) {
                                    if (_selectedPhotoId == id && _panStartGlobalPos != null && _panStartCardPos != null) {
                                      final double dx = details.globalPosition.dx - _panStartGlobalPos!.dx;
                                      final double dy = details.globalPosition.dy - _panStartGlobalPos!.dy;

                                      final double newX = (_panStartCardPos!.dx + dx)
                                          .clamp(14.0, math.max(14.0, boardWidth - scaledCardW - 14.0))
                                          .toDouble();
                                      final double newY = (_panStartCardPos!.dy + dy)
                                          .clamp(14.0, math.max(14.0, boardHeight - scaledCardH - 14.0))
                                          .toDouble();

                                      setState(() {
                                        widget.photoCustomPositions[id] = Offset(newX, newY);
                                      });
                                    }
                                  },
                                  onPanEnd: (_) {
                                    _panStartGlobalPos = null;
                                    _panStartCardPos = null;
                                    widget.onStateChanged();
                                  },
                                  child: AnimatedContainer(
                                    duration: const Duration(milliseconds: 160),
                                    width: scaledCardW,
                                    height: scaledCardH,
                                    padding: const EdgeInsets.all(4.5),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(16),
                                      boxShadow: [
                                        BoxShadow(
                                          color: isSelected
                                              ? Colors.black.withValues(alpha: 0.45)
                                              : Colors.black38,
                                          blurRadius: isSelected ? 14 : 6,
                                          offset: isSelected ? const Offset(0, 6) : const Offset(0, 3),
                                        ),
                                      ],
                                    ),
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(14),
                                      child: SizedBox.expand(
                                        child: _buildPhotoWidget(path, id.hashCode),
                                      ),
                                    ),
                                  ),
                                ),
                              ),

                              _buildWashiTapeWidget(id.hashCode, handlePadding),

                              Positioned(
                                top: handlePadding - 6,
                                child: PushPinWidget(index: id.hashCode).animate(
                                  key: ValueKey('anim_pin_$id'),
                                  target: _isAnimationDone ? 1.0 : null,
                                ).fadeIn(
                                  duration: 1.ms,
                                  delay: (index * 140 + 460).ms,
                                ).scale(
                                  begin: const Offset(1.8, 1.8),
                                  end: const Offset(1.0, 1.0),
                                  duration: 260.ms,
                                  curve: Curves.bounceOut,
                                  delay: (index * 140 + 460).ms,
                                ).slideY(
                                  begin: -1.5,
                                  end: 0,
                                  duration: 260.ms,
                                  curve: Curves.easeOutCubic,
                                  delay: (index * 140 + 460).ms,
                                ),
                              ),

                              if (isSelected && widget.isEditing) ...[
                                Positioned(
                                  left: handlePadding,
                                  top: handlePadding,
                                  right: handlePadding,
                                  bottom: handlePadding,
                                  child: IgnorePointer(
                                    child: CustomPaint(
                                      painter: DashedBorderPainter(
                                        color: Colors.white.withValues(alpha: 0.95),
                                      ),
                                    ),
                                  ),
                                ),
                                Positioned(
                                  top: 0,
                                  left: 0,
                                  child: _buildHandleButton(
                                    icon: Icons.layers_rounded,
                                    onTapWithContext: (btnCtx) => _showLayerMenu(btnCtx, id),
                                  ),
                                ),
                                Positioned(
                                  bottom: 0,
                                  left: 0,
                                  child: _buildHandleButton(
                                    icon: Icons.aspect_ratio_rounded,
                                    onTap: () => _scalePhoto(id),
                                    onPanUpdate: (details) {
                                      setState(() {
                                        final currentScale = widget.photoCustomScales[id] ?? 1.0;
                                        final delta = (details.delta.dy - details.delta.dx) * 0.005;
                                        widget.photoCustomScales[id] = (currentScale + delta).clamp(0.4, 3.0);
                                      });
                                    },
                                  ),
                                ),
                                Positioned(
                                  top: 0,
                                  right: 0,
                                  child: _buildHandleButton(
                                    icon: Icons.close_rounded,
                                    onTap: () => _removePhotoWithDissolve(id, cardSize: Size(scaledCardW, scaledCardH)),
                                  ),
                                ),
                                Positioned(
                                  bottom: 0,
                                  right: 0,
                                  child: _buildHandleButton(
                                    icon: Icons.rotate_right_rounded,
                                    onTap: () => _rotatePhoto(id, currentAngle),
                                    onPanStart: (details) {
                                      final renderBox = context.findRenderObject() as RenderBox?;
                                      if (renderBox != null) {
                                        final cardCenterLocal = Offset(left + scaledCardW / 2 + handlePadding, top + scaledCardH / 2 + handlePadding);
                                        final cardCenterGlobal = renderBox.localToGlobal(cardCenterLocal);
                                        final touchPos = details.globalPosition;
                                        _rotateStartTouchAngle = math.atan2(
                                          touchPos.dy - cardCenterGlobal.dy,
                                          touchPos.dx - cardCenterGlobal.dx,
                                        );
                                        _rotateStartCardAngle = widget.photoCustomAngles[id] ?? currentAngle;
                                      }
                                    },
                                    onPanUpdate: (details) {
                                      if (_rotateStartTouchAngle != null && _rotateStartCardAngle != null) {
                                        final renderBox = context.findRenderObject() as RenderBox?;
                                        if (renderBox != null) {
                                          final cardCenterLocal = Offset(left + scaledCardW / 2 + handlePadding, top + scaledCardH / 2 + handlePadding);
                                          final cardCenterGlobal = renderBox.localToGlobal(cardCenterLocal);
                                          final touchPos = details.globalPosition;
                                          final currentTouchAngle = math.atan2(
                                            touchPos.dy - cardCenterGlobal.dy,
                                            touchPos.dx - cardCenterGlobal.dx,
                                          );
                                          final deltaAngle = currentTouchAngle - _rotateStartTouchAngle!;
                                          setState(() {
                                            widget.photoCustomAngles[id] = _rotateStartCardAngle! + deltaAngle;
                                          });
                                        }
                                      }
                                    },
                                    onPanEnd: (_) {
                                      _rotateStartTouchAngle = null;
                                      _rotateStartCardAngle = null;
                                      widget.onStateChanged();
                                    },
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ).animate(
                  key: ValueKey('anim_card_$id'),
                  target: _isAnimationDone ? 1.0 : null,
                ).custom(
                  duration: 850.ms,
                  delay: (index * 130).ms,
                  curve: Curves.easeOutBack,
                  builder: (context, value, child) {
                    final double rotateY = (1.0 - value) * math.pi * 4.0;
                    final double rotateX = (1.0 - value) * (index % 2 == 0 ? 0.35 : -0.35);
                    final double scale = 1.0 + (1.0 - value) * 0.40;
                    final double opacity = value.clamp(0.0, 1.0);

                    final matrix = Matrix4.identity()
                      ..setEntry(3, 2, 0.0018)
                      ..rotateY(rotateY)
                      ..rotateX(rotateX);

                    return Transform(
                      transform: matrix,
                      alignment: Alignment.center,
                      child: Transform.scale(
                        scale: scale,
                        child: Opacity(
                          opacity: opacity,
                          child: child,
                        ),
                      ),
                    );
                  },
                );
              }),

              ..._activeDissolves.map((dissolve) {
                return Positioned(
                  key: ValueKey('dissolve_${dissolve.id}'),
                  left: dissolve.position.dx,
                  top: dissolve.position.dy,
                  child: WindDissolveEffectWidget(
                    position: Offset.zero,
                    size: dissolve.size,
                    angle: dissolve.angle,
                    windMode: dissolve.windMode,
                    onComplete: () {
                      if (mounted) {
                        setState(() {
                          _activeDissolves.removeWhere((d) => d.id == dissolve.id);
                        });
                      }
                    },
                  ),
                );
              }),
            ],
          ),
        ),
      );
    }

    return RepaintBoundary(
      key: widget.canvasBoundaryKey,
      child: Material(
        color: Colors.transparent,
        child: canvasContent,
      ),
    );
  }
}
