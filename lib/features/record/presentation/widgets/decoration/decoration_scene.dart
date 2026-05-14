import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../controllers/decoration_controller.dart';
import '../isometric_grid_painter.dart';
import 'furniture_drag_overlay.dart';
import 'decoration_toolbar.dart';
import 'furniture_dyeing_dialog.dart';
import '../../utils/isometric_coordinate_utils.dart';
import '../../pages/decoration_page_constants.dart';

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

    final double w =
        imgW * baseScale * kSceneScaleFactor * controller.currentScale;
    final double h =
        imgH * baseScale * kSceneScaleFactor * controller.currentScale;

    // 使用统一的坐标转换工具，确保点击检测与绘制逻辑一致
    // 增加分母（从 28 改为 50），配合更大的画布（kSceneScaleFactor），确保截图时能完美收纳整个房间
    final double tw = w / 50;
    final double th = tw * kGridAspectRatio;
    final double centerYFactor = _getGridCenterYFactor(context);

    final converter = IsometricCoordinateConverter(
      centerX: w / 2,
      centerY: h * centerYFactor,
      tw: tw,
      th: th,
    );

    return SizedBox(
      width: screenW,
      height: screenH,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned.fill(
            child: Stack(
              alignment: Alignment.center,
              children: [
                // 1. 渲染层 (被平移的画布)
                Transform.translate(
                  offset: controller.sceneOffset,
                  child: SizedBox(
                    key: gridKey,
                    width: w,
                    height: h,
                    child: RepaintBoundary(
                      key: repaintKey,
                      child: CustomPaint(
                        painter: IsometricGridPainter(
                          rows: kGridRows,
                          cols: kGridCols,
                          fullWidth: w,
                          fullHeight: h,
                          centerYFactor: centerYFactor,
                          selectedCell: controller.selectedCell,
                          placedItems: controller.placedFurniture,
                          selectedFurniture: controller.selectedFurniture,
                          isCapturing: controller.isCapturingSnapshot,
                          showGrid: controller.showGrid,
                          isInteracting: controller.isInteracting,
                          currentScale: controller.currentScale,
                          dyeVersion: controller.dyeVersion,
                          ghostItem:
                              controller.draggingItem != null &&
                                  controller.ghostCell != null
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
                          wallColorLeft: controller.wallColorLeft,
                          wallColorRight: controller.wallColorRight,
                          wallPattern: controller.wallPattern,
                          floorColor: controller.floorColor,
                          floorPattern: controller.floorPattern,
                        ),
                      ),
                    ),
                  ),
                ),

                // 2. 交互层 (GestureDetector)
                Positioned.fill(
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onPanStart: (_) => controller.updateInteracting(true),
                    onPanUpdate: (details) {
                      if (!controller.isLongPressDragging) {
                        controller.updateSceneOffset(details.delta);
                      }
                    },
                    onPanEnd: (_) => controller.updateInteracting(false),
                    onTapUp: (details) {
                      final localPos =
                          (gridKey.currentContext?.findRenderObject()
                                  as RenderBox)
                              .globalToLocal(details.globalPosition);
                      final hit = controller.findVisualHit(localPos, converter);
                      if (hit != null) {
                        controller.selectFurniture(hit);
                      } else {
                        // 点击空白处，取消选中
                        controller.selectFurniture(null);
                      }
                    },
                    onLongPressStart: (details) {
                      if (controller.draggingItem != null) return;
                      final localPos =
                          (gridKey.currentContext?.findRenderObject()
                                  as RenderBox)
                              .globalToLocal(details.globalPosition);
                      final hit = controller.findVisualHit(localPos, converter);
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
                        controller.updateDragPosition(
                          localPos,
                          converter,
                          isFirstFrame: true,
                        );
                      } else {
                        // 不再选中网格
                      }
                    },
                    onLongPressMoveUpdate: (details) {
                      if (controller.isLongPressDragging) {
                        controller.updateDragPosition(
                          (gridKey.currentContext?.findRenderObject()
                                  as RenderBox)
                              .globalToLocal(details.globalPosition),
                          converter,
                        );
                      }
                    },
                    onLongPressEnd: (details) {
                      if (controller.isLongPressDragging) {
                        final bool hasMoved =
                            controller.originalFurnitureData == null ||
                            (controller.ghostCell?.$1 !=
                                    controller.originalFurnitureData!.r ||
                                controller.ghostCell?.$2 !=
                                    controller.originalFurnitureData!.c ||
                                controller.ghostZ !=
                                    controller.originalFurnitureData!.z ||
                                controller.draggingRotation !=
                                    controller.originalFurnitureData!.rotation);

                        if (controller.ghostCell != null &&
                            (!hasMoved ||
                                controller.isAreaAvailable(
                                  controller.draggingItem!,
                                  controller.ghostCell!.$1,
                                  controller.ghostCell!.$2,
                                  controller.draggingRotation,
                                  converter,
                                  z: controller.ghostZ,
                                  exclude: controller.draggingOriginalPF,
                                ))) {
                          controller.placeFurniture(
                            controller.draggingItem!,
                            r: controller.ghostCell!.$1,
                            c: controller.ghostCell!.$2,
                            z: controller.ghostZ,
                            rotation: controller.draggingRotation,
                          );
                        } else {
                          controller.cancelDragging();
                        }
                      }
                    },
                  ),
                ),
              ],
            ),
          ),
          // 4. UI 覆盖层：通过 gridKey 直接获取场景 SizedBox 的屏幕原点，
          // 避免任何手动坐标计算误差，确保工具栏精准对齐。
          () {
            final RenderBox? sceneBox =
                gridKey.currentContext?.findRenderObject() as RenderBox?;
            final Offset sceneOrigin =
                sceneBox?.localToGlobal(Offset.zero) ?? Offset.zero;
            return Positioned.fill(
              child: IgnorePointer(
                ignoring: controller.selectedFurniture == null,
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    if (controller.selectedFurniture != null) ...[
                      FurnitureDragOverlay(
                        pf: controller.selectedFurniture!,
                        converter: converter,
                        sceneOffset: sceneOrigin,
                        onDragStarted: (item, rot, cell) {
                          controller.draggingItem = item;
                          controller.draggingRotation = rot;
                          controller.ghostCell = cell;
                          controller.ghostZ =
                              controller.selectedFurniture?.z ?? 0.0;
                          controller.draggingOriginalPF =
                              controller.selectedFurniture;
                          controller.selectFurniture(null);
                        },
                        onDragCanceled: controller.cancelDragging,
                      ),
                      DecorationToolbar(
                        pf: controller.selectedFurniture!,
                        converter: converter,
                        sceneOffset: sceneOrigin,
                        onRotate: () =>
                            controller.rotateFurniture(converter),
                        onDelete: () => controller.deleteFurniture(
                          controller.selectedFurniture!,
                        ),
                        onFillAll: () => {},
                        onDye: () {
                          showDialog(
                            context: context,
                            builder: (context) => FurnitureDyeingDialog(
                              pf: controller.selectedFurniture!,
                              onVariantSelected: (variant) {
                                controller.updatePlacedFurnitureVariant(
                                  controller.selectedFurniture!,
                                  variant,
                                );
                              },
                            ),
                          );
                        },
                      ),
                    ],
                  ],
                ),
              ),
            );
          }(),
        ],
      ),
    );
  }

  double _getGridCenterYFactor(BuildContext context) {
    final bool isIPad = MediaQuery.of(context).size.width > 600;
    return isIPad ? kGridCenterYFactorIPad : kGridCenterYFactorPhone;
  }
}
