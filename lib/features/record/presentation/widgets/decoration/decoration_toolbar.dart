import 'dart:ui';
import 'package:flutter/material.dart';
import '../../../domain/models/placed_furniture.dart';
import '../../utils/isometric_coordinate_utils.dart';

/// 瀹跺叿鎿嶄綔宸ュ叿鏍忕粍浠讹紝鍖呭惈鏃嬭浆鍜屽垹闄ゅ姛鑳姐€?
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

    // 2. 鍩哄噯鐐瑰畾浣?(Anchor Point)
    final double centerR;
    final double centerC;
    final double wallZ;

    // 纭畾褰撳墠鏄惁涓洪暅鍍忕姸鎬?(涓?IsometricGridPainter.isFlipped 閫昏緫涓€鑷?
    final bool isFlipped = pf.rotation == 1;
    final double vScale = isFlipped
        ? (pf.item.flippedVisualScale ?? pf.item.visualScale)
        : pf.item.visualScale;
    final Offset vOffset = isFlipped
        ? (pf.item.flippedVisualOffset ?? pf.item.visualOffset)
        : pf.item.visualOffset;

    if (pf.item.isWall) {
      wallZ = pf.z + pf.item.gridH.toDouble(); // 鐗╁搧瀹為檯椤剁 = 搴曢儴楂樺害 + 鑷韩楂樺害
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
      wallZ = pf.z; // 鍚堢悊鏀寔鍦伴潰瀹跺叿鐨?Z 杞?
    }

    final pt = converter.getScreenPoint(centerR, centerC, wallZ);

    // 3. 璁＄畻瀵归綈涓庡亸绉?
    final double s = converter.getTaperScale(centerR, centerC);
    final double visualW;
    final double spriteH;
    final double finalTop;

    if (pf.item.isWall) {
      // 澧欏鐗╁搧锛氳绠楄创鍥炬樉绀虹殑瑙嗚瀹藉害
      visualW = (pf.item.gridW * converter.tw / 2) * s * vScale;
      spriteH = visualW * (pf.item.intrinsicHeight / pf.item.intrinsicWidth);
      final basePt = converter.getScreenPoint(centerR, centerC, pf.z);
      // 閿氬畾鍦ㄨ创鍥鹃《閮紝鍥哄畾 10% 璐村浘楂樺害鐨勭┖闅欍€?
      // 娉ㄦ剰锛歅ainter 涓闈㈡湁 33.0 鐨勫亸绉伙紝姝ゅ涔熷繀椤诲姞涓婁互淇濇寔鍚屾
      const double wallBasePadding = 33.0;
      finalTop =
          basePt.dy +
          wallBasePadding +
          vOffset.dy -
          spriteH * (1.1 + pf.item.toolbarOffset.dy);
    } else {
      // 鍦伴潰瀹跺叿锛氳绠楄创鍥炬樉绀虹殑瑙嗚瀹藉害
      // 淇锛氫互鍓嶇敤 pf.item.gridW 鏄浐瀹氱殑锛岃繖浼氬鑷存棆杞悗瀵逛簬闀挎柟褰㈠鍏蜂及绠楅敊璇?
      visualW = converter.estimateVisualWidth(gw, gh, centerR, centerC, vScale);
      spriteH = visualW * (pf.item.intrinsicHeight / pf.item.intrinsicWidth);
      // 瀹跺叿鐨?pt.dy 鏄簳瑙掍腑蹇冪偣锛岄€氳繃楂樺害琛ュ伩 verticalOffset 淇鍒拌彵褰腑蹇冿紝鍐嶅噺鍘昏创鍥鹃珮搴?
      final double verticalOffset = visualW / 4.0;
      // 杩欓噷鐨?1.1 琛ㄧず鍦ㄩ《閮ㄤ笂鏂逛繚鐣?10% 鐨勭┖闅?
      finalTop =
          pt.dy +
          verticalOffset +
          vOffset.dy -
          spriteH * (1.1 + pf.item.toolbarOffset.dy);
    }

    final isNight = Theme.of(context).brightness == Brightness.dark;

    return Positioned(
      left:
          pt.dx -
          55 +
          vOffset.dx +
          (pf.item.toolbarOffset.dx * visualW) +
          layoutOffset.dx,
      top: finalTop + layoutOffset.dy,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(28),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 0),
            decoration: BoxDecoration(
              color: isNight
                  ? Colors.black.withValues(alpha: 0.5)
                  : Colors.white.withValues(alpha: 0.7),
              borderRadius: BorderRadius.circular(28),
              border: Border.all(
                color: isNight
                    ? Colors.white12
                    : Colors.black.withValues(alpha: 0.08),
                width: 1.0,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 16,
                  offset: const Offset(0, 4),
                ),
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
      color: isNight ? Colors.white12 : Colors.black.withValues(alpha: 0.06),
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
