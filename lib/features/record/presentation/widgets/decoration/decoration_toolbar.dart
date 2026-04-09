import 'dart:ui';
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

    // 确定当前是否为镜像状态 (与 IsometricGridPainter.isFlipped 逻辑一致)
    final bool isFlipped = pf.rotation == 1;
    final double vScale = isFlipped ? (pf.item.flippedVisualScale ?? pf.item.visualScale) : pf.item.visualScale;
    final Offset vOffset = isFlipped ? (pf.item.flippedVisualOffset ?? pf.item.visualOffset) : pf.item.visualOffset;

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
      wallZ = pf.z; // 合理支持地面家具的 Z 轴
    }

    final pt = converter.getScreenPoint(centerR, centerC, wallZ);

    // 3. 计算对齐与偏移
    final double s = converter.getTaperScale(centerR, centerC);
    final double visualW;
    final double spriteH;
    final double finalTop;

    if (pf.item.isWall) {
      // 墙壁物品：计算贴图显示的视觉宽度
      visualW = (pf.item.gridW * converter.tw / 2) * s * vScale;
      spriteH = visualW * (pf.item.intrinsicHeight / pf.item.intrinsicWidth);
      final basePt = converter.getScreenPoint(centerR, centerC, pf.z);
      // 锚定在贴图顶部，固定 10% 贴图高度的空隙。
      // 注意：Painter 中墙面有 33.0 的偏移，此处也必须加上以保持同步
      const double wallBasePadding = 33.0;
      finalTop = basePt.dy + wallBasePadding + vOffset.dy - spriteH * (1.1 + pf.item.toolbarOffset.dy);
    } else {
      // 地面家具：计算贴图显示的视觉宽度
      // 修正：以前用 pf.item.gridW 是固定的，这会导致旋转后对于长方形家具估算错误
      visualW = converter.estimateVisualWidth(gw, gh, centerR, centerC, vScale);
      spriteH = visualW * (pf.item.intrinsicHeight / pf.item.intrinsicWidth);
      // 家具的 pt.dy 是底角中心点，通过高度补偿 verticalOffset 修正到菱形中心，再减去贴图高度
      final double verticalOffset = visualW / 4.0;
      // 这里的 1.1 表示在顶部上方保留 10% 的空隙
      finalTop = pt.dy + verticalOffset + vOffset.dy - spriteH * (1.1 + pf.item.toolbarOffset.dy);
    }

    final isNight = Theme.of(context).brightness == Brightness.dark;

    return Positioned(
      left: pt.dx - 55 + vOffset.dx + (pf.item.toolbarOffset.dx * visualW) + layoutOffset.dx,
      top: finalTop + layoutOffset.dy,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(28),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 0),
            decoration: BoxDecoration(
              color: isNight 
                ? Colors.black.withOpacity(0.5) 
                : Colors.white.withOpacity(0.7),
              borderRadius: BorderRadius.circular(28),
              border: Border.all(
                color: isNight ? Colors.white12 : Colors.black.withOpacity(0.08),
                width: 1.0,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 16,
                  offset: const Offset(0, 4),
                )
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (pf.item.isFloor) ...[
                  _ToolbarButton(
                    icon: Icons.grid_view_rounded,
                    color: Colors.blueAccent,
                    onPressed: onFillAll,
                  ),
                  _buildDivider(isNight),
                ],
                _ToolbarButton(
                  icon: Icons.rotate_right_rounded,
                  color: isNight ? ColorsHex.whiteEE : Colors.black87,
                  onPressed: onRotate,
                ),
                _buildDivider(isNight),
                _ToolbarButton(
                  icon: Icons.delete_outline_rounded,
                  color: const Color(0xFFFF6B6B),
                  onPressed: onDelete,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDivider(bool isNight) {
    return Container(
      width: 1,
      height: 18,
      margin: const EdgeInsets.symmetric(horizontal: 4),
      color: isNight ? Colors.white12 : Colors.black.withOpacity(0.06),
    );
  }
}

class _ToolbarButton extends StatelessWidget {
  final IconData icon;
  final Color color;
  final VoidCallback onPressed;

  const _ToolbarButton({
    required this.icon,
    required this.color,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.all(10),
          child: Icon(icon, color: color, size: 22),
        ),
      ),
    );
  }
}

extension ColorsHex on Colors {
  static const Color whiteEE = Color(0xFFEEEEEE);
}
