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
  final Offset layoutOffset;

  const DecorationToolbar({
    super.key,
    required this.pf,
    required this.converter,
    required this.onRotate,
    required this.onDelete,
    required this.onFillAll,
    this.layoutOffset = Offset.zero,
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

    // 3. 计算对齐与偏移 (垂直位置)
    final double finalTop;
    final double s = converter.getTaperScale(centerR, centerC);
    
    if (pf.item.isWall) {
      // 墙壁工具栏：基于贴图实际高度进行浮动，防止遮挡高挑家具
      final double visualW = (pf.item.gridW * converter.tw / 2) * s * pf.item.visualScale;
      final double spriteH = visualW * (pf.item.intrinsicHeight / pf.item.intrinsicWidth);
      
      // 计算底边基准点
      final basePt = converter.getScreenPoint(centerR, centerC, pf.z);
      
      // 向上大幅偏移 70 像素，确保在任何高挑家具（如落地窗、高挂帘）上方都有足够呼吸空间
      finalTop = basePt.dy - spriteH - 70 + pf.item.visualOffset.dy;
    } else {
      // 家具类：沿用高度补偿算法，并保持 30 像素间距
      final double visualW = converter.estimateVisualWidth(gw, gh, centerR, centerC, pf.item.visualScale);
      final double spriteH = visualW * (pf.item.intrinsicHeight / pf.item.intrinsicWidth);
      final double verticalOffset = visualW / 4.0;
      finalTop = pt.dy + verticalOffset - spriteH - 30 + pf.item.visualOffset.dy;
    }

    return Positioned(
      left: pt.dx - 50 + pf.item.visualOffset.dx + layoutOffset.dx,
      top: finalTop + layoutOffset.dy,
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
