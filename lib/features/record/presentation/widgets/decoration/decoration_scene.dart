import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../controllers/decoration_controller.dart';
import '../isometric_grid_painter.dart';
import 'furniture_drag_overlay.dart';
import 'decoration_toolbar.dart';
import '../../utils/isometric_coordinate_utils.dart';
import '../../pages/decoration_page_constants.dart';
import '../../../domain/models/furniture_item.dart';

class DecorationScene extends StatelessWidget {
  final GlobalKey gridKey;
  final GlobalKey repaintKey;
  final DecorationController controller;

  const DecorationScene({
    super.key,
    required this.gridKey,
    required this.repaintKey,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    final double screenW = MediaQuery.of(context).size.width;
    final double screenH = MediaQuery.of(context).size.height;

    // 基础尺寸计算 (基于 2000x2000 原始画布)
    const double imgW = 2000;
    const double imgH = 2000;
    double baseScale = screenH / imgH;
    if (imgW * baseScale < screenW) baseScale = screenW / imgW;

    final double w = imgW * baseScale * kSceneScaleFactor * controller.currentScale;
    final double h = imgH * baseScale * kSceneScaleFactor * controller.currentScale;

    // 获取坐标转换工具实例
    final converter = IsometricCoordinateConverter(
      centerX: w / 2,
      centerY: h * _getGridCenterYFactor(context),
      tw: w / 28,
      th: w / 56,
    );

    return Container(
      width: screenW,
      height: screenH,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned.fill(
            child: Container(
              alignment: Alignment.center,
              child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onPanStart: (_) => controller.updateInteracting(true),
        onPanUpdate: (details) {
          // 仅在非搬动且非选中家具时允许场景平移
          if (controller.draggingItem == null && controller.selectedFurniture == null) {
            controller.updateSceneOffset(details.delta);
          }
        },
        onPanEnd: (_) => controller.updateInteracting(false),
        onTapUp: (details) {
          // 单击选择家具或单元格
          final hit = controller.findVisualHit(
            (gridKey.currentContext?.findRenderObject() as RenderBox).globalToLocal(details.globalPosition),
            converter,
          );
          controller.selectFurniture(hit);
        },
        onLongPressStart: (details) {
          // 长按开始搬动家具
          if (controller.draggingItem != null) return;
          final hit = controller.findVisualHit(
            (gridKey.currentContext?.findRenderObject() as RenderBox).globalToLocal(details.globalPosition),
            converter,
          );
          if (hit != null) {
            HapticFeedback.mediumImpact();
            controller.originalFurnitureData = hit;
            controller.draggingOriginalPF = hit;
            controller.draggingItem = hit.item;
            controller.draggingRotation = hit.rotation;
            controller.ghostCell = (hit.r, hit.c);
            controller.ghostZ = hit.z;
            controller.isLongPressDragging = true;
            controller.updateInteracting(true);
            controller.selectFurniture(null);
            
            // 关键：立即执行一次带 isFirstFrame 的位置更新来校准偏移量
            controller.updateDragPosition(
              (gridKey.currentContext?.findRenderObject() as RenderBox).globalToLocal(details.globalPosition),
              converter,
              isFirstFrame: true,
            );
          } else {
            // 如果没点中家具，则尝试选中格子
            final cell = converter.getGridCell((gridKey.currentContext?.findRenderObject() as RenderBox).globalToLocal(details.globalPosition));
            controller.selectCell(cell);
          }
        },
        onLongPressMoveUpdate: (details) {
          if (controller.isLongPressDragging) {
            controller.updateDragPosition(
              (gridKey.currentContext?.findRenderObject() as RenderBox).globalToLocal(details.globalPosition),
              converter,
            );
          }
        },
        onLongPressEnd: (details) {
          if (controller.isLongPressDragging) {
            final bool hasMoved = controller.originalFurnitureData == null || 
              (controller.ghostCell?.$1 != controller.originalFurnitureData!.r || 
               controller.ghostCell?.$2 != controller.originalFurnitureData!.c || 
               controller.ghostZ != controller.originalFurnitureData!.z || 
               controller.draggingRotation != controller.originalFurnitureData!.rotation);

            if (controller.ghostCell != null && 
                (!hasMoved || controller.isAreaAvailable(controller.draggingItem!, controller.ghostCell!.$1, controller.ghostCell!.$2, controller.draggingRotation, converter, z: controller.ghostZ, exclude: controller.draggingOriginalPF))) {
              controller.placeFurniture(controller.draggingItem!, r: controller.ghostCell!.$1, c: controller.ghostCell!.$2, z: controller.ghostZ, rotation: controller.draggingRotation);
            } else {
              controller.cancelDragging();
            }
          }
        },
        child: RepaintBoundary(
          key: repaintKey,
          child: Transform.translate(
            offset: controller.sceneOffset,
            child: SizedBox(
              key: gridKey,
              width: w,
              height: h,
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  // 1. 核心绘制层
                  Positioned.fill(
                    child: CustomPaint(
                      painter: IsometricGridPainter(
                        rows: kGridRows,
                        cols: kGridCols,
                        fullWidth: w,
                        fullHeight: h,
                        centerYFactor: _getGridCenterYFactor(context),
                        selectedCell: controller.selectedCell,
                        placedItems: controller.placedFurniture,
                        selectedFurniture: controller.selectedFurniture,
                        isCapturing: controller.isCapturingSnapshot,
                        showGrid: controller.showGrid,
                        isInteracting: controller.isInteracting,
                        currentScale: controller.currentScale,
                        ghostItem: controller.draggingItem != null && controller.ghostCell != null
                            ? (
                                controller.draggingItem!,
                                controller.ghostCell,
                                controller.draggingRotation,
                                controller.isAreaAvailable(
                                  controller.draggingItem!,
                                  controller.ghostCell!.$1,
                                  controller.ghostCell!.$2,
                                  controller.draggingRotation,
                                  converter,
                                  z: controller.ghostZ,
                                  exclude: controller.draggingOriginalPF,
                                ),
                                controller.ghostZ,
                              )
                            : null,
                        draggingOriginalPF: controller.draggingOriginalPF,
                        bouncingItem: controller.bouncingFurniture,
                        bounceScale: controller.bounceScale,
                      ),
                    ),
                  ),

                  // 2. 交互感知层 (DragTarget)
                  Positioned.fill(
                    child: DragTarget<FurnitureItem>(
                      onMove: (details) => controller.updateDragPosition(
                        (gridKey.currentContext?.findRenderObject() as RenderBox).globalToLocal(details.offset),
                        converter,
                      ),
                      onAccept: (FurnitureItem item) {
                        controller.updateInteracting(false);
                        if (controller.ghostCell != null && item.quantity > 0) {
                          if (controller.isAreaAvailable(item, controller.ghostCell!.$1, controller.ghostCell!.$2, controller.draggingRotation, converter, z: controller.ghostZ, exclude: controller.draggingOriginalPF)) {
                            controller.placeFurniture(item, r: controller.ghostCell!.$1, c: controller.ghostCell!.$2, z: controller.ghostZ, rotation: controller.draggingRotation);
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('该区域无法放置家具'), duration: Duration(seconds: 1)));
                            controller.cancelDragging();
                          }
                        }
                      },
                      onLeave: (_) => controller.selectCell(null),
                      builder: (context, _, __) => const SizedBox.shrink(),
                    ),
                  ),

                  // 3. 编辑工具栏与拖拽 Overlay
                  if (controller.selectedFurniture != null)
                    FurnitureDragOverlay(
                      pf: controller.selectedFurniture!,
                      converter: converter,
                      onDragStarted: (item, rot, cell) {
                        controller.draggingItem = item;
                        controller.draggingRotation = rot;
                        controller.ghostCell = cell;
                        controller.ghostZ = controller.selectedFurniture?.z ?? 0.0;
                        controller.draggingOriginalPF = controller.selectedFurniture;
                        controller.selectFurniture(null);
                      },
                      onDragCanceled: controller.cancelDragging,
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
            ),
          ),
          if (controller.selectedFurniture != null)
            DecorationToolbar(
              pf: controller.selectedFurniture!,
              converter: converter,
              layoutOffset: Offset(
                (screenW - w) / 2 + controller.sceneOffset.dx,
                (screenH - h) / 2 + controller.sceneOffset.dy,
              ),
              onRotate: () => controller.rotateFurniture(converter),
              onDelete: () => controller.deleteFurniture(controller.selectedFurniture!),
              onFillAll: () => {},
            ),
        ],
      ),
    );
  }

  double _getGridCenterYFactor(BuildContext context) {
    bool isLandscape = MediaQuery.of(context).orientation == Orientation.landscape;
    return isLandscape ? 0.35 : 0.42;
  }
}
