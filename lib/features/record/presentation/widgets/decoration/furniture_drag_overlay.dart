import 'package:flutter/material.dart';
import '../../../domain/models/furniture_item.dart';
import '../../../domain/models/placed_furniture.dart';
import '../../utils/isometric_coordinate_utils.dart';

/// 家具拖拽热区遮罩组件，提供选中后的透明交互层。
class FurnitureDragOverlay extends StatelessWidget {
  final PlacedFurniture pf;
  final IsometricCoordinateConverter converter;
  final Function(FurnitureItem item, int rotation, (int, int) cell) onDragStarted;
  final VoidCallback onDragCanceled;

  const FurnitureDragOverlay({
    super.key,
    required this.pf,
    required this.converter,
    required this.onDragStarted,
    required this.onDragCanceled,
  });

  @override
  Widget build(BuildContext context) {
    int gw = pf.item.gridW;
    int gh = pf.item.gridH;
    if (pf.rotation % 2 != 0) {
      gw = pf.item.gridH;
      gh = pf.item.gridW;
    }

    // 计算中心定位点
    final pt = converter.getScreenPoint(pf.r + gw / 2.0, pf.c + gh / 2.0, 0);

    // 计算视觉尺寸，用于确定点击热区 (与 getFurnitureRect 逻辑同步)
    final double visualW = converter.estimateVisualWidth(gw, gh, pf.r + gw / 2.0, pf.c + gh / 2.0, pf.item.visualScale);
    final double spriteH = visualW * (pf.item.intrinsicHeight / pf.item.intrinsicWidth);
    final double verticalOffset = visualW / 4.0;
    final double overlayH = spriteH + 60;

    return Positioned(
      left: pt.dx - visualW / 2 + pf.item.visualOffset.dx,
      top: pt.dy + verticalOffset - spriteH - 30 + pf.item.visualOffset.dy,
      width: visualW,
      height: overlayH,
      child: LongPressDraggable<FurnitureItem>(
        delay: const Duration(milliseconds: 300),
        hapticFeedbackOnStart: true,
        dragAnchorStrategy: pointerDragAnchorStrategy,
        data: pf.item,
        feedback: const SizedBox.shrink(),
        onDragStarted: () => onDragStarted(pf.item, pf.rotation, (pf.r, pf.c)),
        onDraggableCanceled: (_, __) => onDragCanceled(),
        child: Container(color: Colors.transparent),
      ),
    );
  }
}
