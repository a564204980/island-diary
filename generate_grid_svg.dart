import 'dart:io';
import 'dart:math';

void main() {
  final int gridW = 4;
  final int gridH = 3;
  // 放大倍数，以便获得高清晰度的垫图参考
  final double tw = 300.0; 
  final double th = tw * tan(30 * pi / 180);
  
  final double offsetX = 600.0;
  final double offsetY = 100.0;
  
  double getX(int r, int c) => offsetX + (r - c) * (tw / 2);
  double getY(int r, int c) => offsetY + (r + c) * (th / 2);

  String svg = '<svg width="1200" height="800" xmlns="http://www.w3.org/2000/svg">\n';
  // 纯白背景，便于 AI 作为透明/白底素材处理
  svg += '  <rect width="100%" height="100%" fill="#ffffff" />\n';
  
  // 绘制内部网格参考线 (浅色)
  svg += '  <g stroke="#ffd54f" stroke-width="2" opacity="0.6">\n';
  for (int c = 1; c < gridH; c++) {
    svg += '    <line x1="${getX(0, c).toStringAsFixed(2)}" y1="${getY(0, c).toStringAsFixed(2)}" x2="${getX(gridW, c).toStringAsFixed(2)}" y2="${getY(gridW, c).toStringAsFixed(2)}" />\n';
  }
  for (int r = 1; r < gridW; r++) {
    svg += '    <line x1="${getX(r, 0).toStringAsFixed(2)}" y1="${getY(r, 0).toStringAsFixed(2)}" x2="${getX(r, gridH).toStringAsFixed(2)}" y2="${getY(r, gridH).toStringAsFixed(2)}" />\n';
  }
  svg += '  </g>\n';

  // 绘制外部边界框 (加粗深色)
  svg += '  <polygon points="';
  svg += '${getX(0,0).toStringAsFixed(2)},${getY(0,0).toStringAsFixed(2)} ';
  svg += '${getX(gridW,0).toStringAsFixed(2)},${getY(gridW,0).toStringAsFixed(2)} ';
  svg += '${getX(gridW,gridH).toStringAsFixed(2)},${getY(gridW,gridH).toStringAsFixed(2)} ';
  svg += '${getX(0,gridH).toStringAsFixed(2)},${getY(0,gridH).toStringAsFixed(2)}" ';
  svg += 'fill="none" stroke="#ffb300" stroke-width="5" />\n';
  
  svg += '</svg>';

  File('4x3_30deg_grid_reference.svg').writeAsStringSync(svg);
  print('Reference grid saved to 4x3_30deg_grid_reference.svg');
}
