import 'package:flutter/material.dart';
import '../../../domain/models/placed_furniture.dart';
import '../../utils/isometric_coordinate_utils.dart';

/// 家具操作工具栏组件，包含旋转和删除功能。
class DecorationToolbar extends StatelessWidget {
  final PlacedFurniture pf;
  final IsometricCoordinateConverter converter;
  final VoidCallback onRotate;
  final VoidCallback onDelete;
  final VoidCallback onFillAll;

  const DecorationToolbar({
    super.key,
    required this.pf,
    required this.converter,
    required this.onRotate,
    required this.onDelete,
    required this.onFillAll,
  });

  @override
  Widget build(BuildContext context) {
    int gw = pf.item.gridW;
    int gh = pf.item.gridH;
    if (pf.rotation % 2 != 0) {
      gw = pf.item.gridH;
      gh = pf.item.gridW;
    }

    // 2. 基准点定位 (Anchor Point)
    final double centerR;
    final double centerC;
    final double wallZ;

    if (pf.item.isWall) {
      wallZ = pf.z + pf.item.gridH.toDouble(); // 物品实际顶端 = 底部高度 + 自身高度
      if (pf.rotation % 2 == 0) {
        centerR = pf.r + pf.item.gridW / 2.0;
        centerC = pf.c.toDouble();
      } else {
        centerR = pf.r.toDouble();
        centerC = pf.c + pf.item.gridW / 2.0;
      }
    } else {
      centerR = pf.r + gw / 2.0;
      centerC = pf.c + gh / 2.0;
      wallZ = 0; // 家具基准点在地面
    }

    final pt = converter.getScreenPoint(centerR, centerC, wallZ);

    // 3. 计算垂直偏移 (Vertical Offset)
    final double finalTop;
    if (pf.item.isWall) {
      // 墙壁工具栏直接浮动在顶端探测点上方
      finalTop = pt.dy - 60 + pf.item.visualOffset.dy;
    } else {
      // 家具类沿用广告牌高度补偿算法
      final double visualW = converter.estimateVisualWidth(gw, gh, centerR, centerC, pf.item.visualScale);
      final double spriteH = visualW * (pf.item.intrinsicHeight / pf.item.intrinsicWidth);
      final double verticalOffset = visualW / 4.0;
      finalTop = pt.dy + verticalOffset - spriteH - 70 + pf.item.visualOffset.dy;
    }

    return Positioned(
      left: pt.dx - 50 + pf.item.visualOffset.dx,
      top: finalTop,
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
            if (pf.item.isFloor)
              IconButton(
                icon: const Icon(Icons.grid_view, color: Colors.blueAccent, size: 20),
                onPressed: onFillAll,
                tooltip: '铺满地板',
              ),
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
