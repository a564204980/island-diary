import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../pages/decoration_page_constants.dart';

/// 绛夎窛鍧愭爣杞崲宸ュ叿绫伙紝缁熶竴澶勭悊缃戞牸鍧愭爣 (r, c, z) 鍒板睆骞曞儚绱犲潗鏍囩殑杞崲妯″瀷銆?
class IsometricCoordinateConverter {
  final double centerX;
  final double centerY;
  final double tw; // 鍗曞厓鏍煎搴﹀熀鍑?
  final double th; // 鍗曞厓鏍奸珮搴﹀熀鍑?

  IsometricCoordinateConverter({
    required this.centerX,
    required this.centerY,
    required this.tw,
    required this.th,
  });

  /// 鑾峰彇鎸囧畾缃戞牸鍧愭爣澶勭殑鎶曞奖鍙樺舰姣斾緥 (Taper)
  double getTaperScale(double r, double c) {
    final double u = (r / kGridRows).clamp(0, 1);
    final double v = (c / kGridCols).clamp(0, 1);

    return 1.0 +
        (1 - u) * (1 - v) * kGridTopTaper +
        u * (1 - v) * kGridRightTaper +
        (1 - u) * v * kGridLeftTaper +
        u * v * kGridBottomTaper;
  }

  /// 灏嗙綉鏍煎潗鏍?(r, c, z) 杞崲涓哄睆骞曞亸绉婚噺 Offset
  Offset getScreenPoint(double r, double c, [double z = 0]) {
    final double s = getTaperScale(r, c);

    // 鍩虹绛夎窛鎶曞奖鍧愭爣 (鏈棆杞墠)
    // x 杞达細(r - c) 鏂瑰悜
    // y 杞达細(r + c) 鏂瑰悜锛屽苟鍑忓幓涓績鍋忕Щ
    final double x = (r - c) * (tw / 2) * s;
    final double y = (r + c - (kGridRows + kGridCols) / 2) * (th / 2) * s;

    // 鍨傜洿楂樺害琛ュ伩 (Z 杞?
    final double hFactor = th; // 浣跨敤鍗曞厓鏍奸珮搴︿綔涓?Z 杞存闀垮熀鍑嗭紝閫傞厤 30 搴﹁瑙?
    final double verticalY = -z * hFactor * s;

    // 搴旂敤缃戞牸鏁翠綋鏃嬭浆 (kGridRotationDegree)
    final double rad = kGridRotationDegree * math.pi / 180;
    final double cosR = math.cos(rad);
    final double sinR = math.sin(rad);

    final double rotatedX = x * cosR - (y + verticalY) * sinR;
    final double rotatedY = x * sinR + (y + verticalY) * cosR;

    return Offset(centerX + rotatedX, centerY + rotatedY);
  }

  /// 浼扮畻瀹跺叿鍦ㄥ綋鍓嶅潗鏍囦笅鐨勮瑙夊搴?(鍙?Taper 褰卞搷)
  double estimateVisualWidth(
    int gridW,
    int gridH,
    double r,
    double c,
    double visualScale,
  ) {
    final double s = getTaperScale(r, c);
    return tw * (gridW + gridH) * s * 0.5 * visualScale;
  }

  /// 璁＄畻瀹跺叿鍦ㄥ睆骞曚笂鐨勮瑙夌煩褰?(鐢ㄤ簬鍛戒腑妫€娴嬫垨 Overlay 瀹氫綅)
  Rect getFurnitureRect({
    required int r,
    required int c,
    required int gw,
    required int gh,
    required double visualScale,
    required Offset visualOffset,
    required double intrinsicWidth,
    required double intrinsicHeight,
    double z = 0,
  }) {
    final pt = getScreenPoint(r + gw / 2.0, c + gh / 2.0, z);
    final double itemW = estimateVisualWidth(
      gw,
      gh,
      r + gw / 2.0,
      c + gh / 2.0,
      visualScale,
    );
    final double spriteH = itemW * (intrinsicHeight / intrinsicWidth);
    final double verticalOffset = itemW / 4.0;

    return Rect.fromLTWH(
      pt.dx - itemW / 2 + visualOffset.dx,
      pt.dy + verticalOffset - spriteH + visualOffset.dy,
      itemW,
      spriteH,
    );
  }

  /// 鏍稿績鍛戒腑妫€娴嬶細鏍规嵁鍍忕礌鍧愭爣鍙嶆帹鏈€杩戠殑缃戞牸鍧愭爣 (r, c)
  (int, int)? getGridCell(Offset localPos, {double? customThresholdSq}) {
    (int, int)? bestCell;
    double minDistanceSq = double.infinity;

    // 鎼滅储鎵€鏈夋牸瀛愶紝鎵惧埌涓績鐐规渶鎺ヨ繎榧犳爣浣嶇疆鐨?
    for (int r = 0; r < kGridRows; r++) {
      for (int c = 0; c < kGridCols; c++) {
        final pt = getScreenPoint(r + 0.5, c + 0.5, 0);

        final double dx = localPos.dx - pt.dx;
        final double dy = localPos.dy - pt.dy;
        final double distSq = dx * dx + dy * dy;

        if (distSq < minDistanceSq) {
          minDistanceSq = distSq;
          bestCell = (r, c);
        }
      }
    }

    // 鍔ㄦ€侀槇鍊硷細纭繚鍦ㄩ珮鍊嶇缉鏀撅紙tw 寰堝ぇ锛夋垨鏋佷綆缂╂斁锛坱w 寰堝皬锛夋椂鐐瑰嚮閮芥湁鏁?
    // 浣跨敤 tw^2 浣滀负鍩哄噯瀹瑰樊锛岃鐩栨暣涓彵褰㈠尯鍩?
    final double thresholdSq = customThresholdSq ?? (tw * tw * 1.5);

    if (minDistanceSq > thresholdSq) return null;
    return bestCell;
  }

  /// 澧欓潰涓撶敤鎶曞奖锛氬皢鍏夋爣鎶曞奖鍒版寚瀹氬闈紝杩斿洖娌垮鏂瑰悜鐨勬牸瀛愮储寮?
  /// [preferLeftWall] true=浼樺厛宸﹀(r杞? c=0)锛宖alse=浼樺厛鍙冲(c杞? r=0)
  /// 杩斿洖 (r, c) 濮嬬粓淇濇寔瀵瑰簲澧欓潰鐨勭害鏉?(宸﹀ c=0, 鍙冲 r=0)
  (int, int) getWallCell(Offset localPos, {required bool preferLeftWall}) {
    if (preferLeftWall) {
      // 宸﹀悗澧欙細XZ 闈紝c=0锛宺 浠?0 鍒?kGridRows-1
      // 鍦ㄥ悇涓?r 浣嶇疆鍙栧闈腑绾挎潵姣旇緝 x 璺濈锛堝拷鐣?y 鍗抽珮搴︼級
      int bestR = 0;
      double minDistX = double.infinity;
      for (int r = 0; r < kGridRows; r++) {
        // 鍙栬鍒楀簳閮ㄤ腑蹇冪偣鐨?x 鍧愭爣浣滀负鍙傝€?
        final pt = getScreenPoint(r + 0.5, 0);
        final double dx = (localPos.dx - pt.dx).abs();
        if (dx < minDistX) {
          minDistX = dx;
          bestR = r;
        }
      }
      return (bestR.clamp(0, kGridRows - 1), 0);
    } else {
      // 鍙冲悗澧欙細YZ 闈紝r=0锛宑 浠?0 鍒?kGridCols-1
      int bestC = 0;
      double minDistX = double.infinity;
      for (int c = 0; c < kGridCols; c++) {
        final pt = getScreenPoint(0, c + 0.5);
        final double dx = (localPos.dx - pt.dx).abs();
        if (dx < minDistX) {
          minDistX = dx;
          bestC = c;
        }
      }
      return (0, bestC.clamp(0, kGridCols - 1));
    }
  }

  /// 灏嗗厜鏍?Y 鍧愭爣鐩存帴鏄犲皠涓哄闈?Z 鍊硷紙缁濆浣嶇疆锛屾棤澧為噺绱Н锛?
  /// [r], [c]: 澧欓潰涓婂綋鍓嶆牸瀛愮殑鍩哄噯鍧愭爣锛堢敤浜庤绠楄鍒?琛岀殑鍨傜洿鑼冨洿锛?
  /// [maxZ]: 澧欓潰楂樺害涓婇檺锛堝嵆 kWallGridHeight锛?
  double getWallZ(
    Offset localPos, {
    required double r,
    required double c,
    required double maxZ,
  }) {
    final double bottomY = getScreenPoint(r, c, 0).dy;
    final double topY = getScreenPoint(r, c, maxZ).dy;
    if ((bottomY - topY).abs() < 1.0) return 0;
    final double z = maxZ * (bottomY - localPos.dy) / (bottomY - topY);
    return z.clamp(0.0, maxZ);
  }
}
