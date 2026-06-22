import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('Test TextPainter getPositionForOffset', (WidgetTester tester) async {
    final String text = '大中型屏幕手机（大部分手机）：使用LayoutBuilder动态检测可用宽度。当检测到横向空间充裕时，不再采用滚动条，而是采用spaceBetween自动平铺并均匀分配间距。';
    final textStyle = TextStyle(
      fontSize: 20,
      height: 1.8,
    );

    final textPainter = TextPainter(
      text: TextSpan(text: text, style: textStyle),
      textDirection: TextDirection.ltr,
    );
    textPainter.layout(maxWidth: 200);

    final lines = textPainter.computeLineMetrics();
    print('Lines count: ${lines.length}');
    for (int i = 0; i < lines.length; i++) {
      print('Line $i: width=${lines[i].width}, height=${lines[i].height}');
    }

    double accumulatedHeight = 0;
    int endChar = 0;
    int fittingLines = 0;
    double targetHeight = 120.0;

    for (var line in lines) {
      if (accumulatedHeight + line.height <= targetHeight) {
        final position = textPainter.getPositionForOffset(
          Offset(200 + 9999, accumulatedHeight + line.height / 2),
        );
        endChar = position.offset;
        accumulatedHeight += line.height;
        fittingLines++;
        print('Fitting line $fittingLines: endChar=$endChar, accumulatedHeight=$accumulatedHeight');
      } else {
        break;
      }
    }

    print('Final fittingLines: $fittingLines');
    print('Final endChar: $endChar');
    print('Text length: ${text.length}');
  });
}
