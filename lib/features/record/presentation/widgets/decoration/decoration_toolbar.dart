import 'package:flutter/material.dart';
import '../../../domain/models/placed_furniture.dart';
import '../../utils/isometric_coordinate_utils.dart';

/// 家具操作工具栏组件，包含旋转和删除功能。
class DecorationToolbar extends StatelessWidget {
  final PlacedFurniture pf;
  final IsometricCoordinateConverter converter;
  final VoidCallback onRotate;
  final VoidCallback onDelete;

  const DecorationToolbar({
    super.key,
    required this.pf,
    required this.converter,
    required this.onRotate,
    required this.onDelete,
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
    final pt = converter.getScreenPoint(
      pf.r + gw / 2.0,
      pf.c + gh / 2.0,
      pf.item.isWall ? pf.item.gridH / 2.0 : 0,
    );

    // 计算家具视觉高度，以便将工具栏定位在家具上方
    final double visualW = converter.estimateVisualWidth(gw, gh, pf.r + gw / 2.0, pf.c + gh / 2.0, pf.item.visualScale);
    final double spriteH = visualW * (pf.item.intrinsicHeight / pf.item.intrinsicWidth);
    final double verticalOffset = visualW / 4.0;

    return Positioned(
      left: pt.dx - 50 + pf.item.visualOffset.dx,
      top: pt.dy + verticalOffset - spriteH - 70 + pf.item.visualOffset.dy,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.black87,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white24),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.rotate_right, color: Colors.white, size: 20),
              onPressed: onRotate,
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline, color: Colors.redAccent, size: 20),
              onPressed: onDelete,
            ),
          ],
        ),
      ),
    );
  }
}
