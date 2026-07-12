part of '../../diary_book_export_page.dart';

extension _ExportCanvasRenderExtension on _DiaryBookExportPageState {


  ui.Shader _getExportUnderlineShader(String style, Color color, double fontSize, double lineHeight) {
    final double rectHeight = fontSize * lineHeight;
    final key = "${style}_${color.toARGB32()}_${fontSize.toStringAsFixed(1)}_${lineHeight.toStringAsFixed(1)}";
    if (_exportShaderCache.containsKey(key)) {
      return _exportShaderCache[key]!;
    }

    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke;

    final double y = (fontSize * 1.2 + (lineHeight - 1.0) * fontSize * 0.5).clamp(0.0, rectHeight - 2.5);

    if (style == 'circle') {
      paint.strokeWidth = 1.6;
      paint.strokeCap = StrokeCap.round;
      final double startY = rectHeight * 0.12;
      final double endY = rectHeight * 0.94;
      final double midY = startY + (endY - startY) / 2;
      final path = Path();
      path.moveTo(1.2, midY - 1);
      path.quadraticBezierTo(2.0, startY + 0.5, 7.0, startY);
      path.quadraticBezierTo(13.5, startY + 0.2, 13.5, midY + 0.8);
      path.quadraticBezierTo(13.2, endY - 0.5, 7.0, endY);
      path.quadraticBezierTo(1.0, endY - 0.2, 1.2, midY - 1);
      path.close();
      canvas.drawPath(path, paint);

      final img = recorder.endRecording().toImageSync(14, rectHeight.clamp(1.0, 1000.0).toInt());
      return _exportShaderCache[key] = ImageShader(img, TileMode.repeated, TileMode.repeated, Float64List.fromList([1.0, 0.0, 0.0, 0.0, 0.0, 1.0, 0.0, 0.0, 0.0, 0.0, 1.0, 0.0, 0.0, 0.0, 0.0, 1.0]));
    } else if (style == 'marker') {
      final shader = LinearGradient(
        begin: Alignment.topCenter, end: Alignment.bottomCenter,
        colors: [Colors.transparent, Colors.transparent, color.withValues(alpha: 0.35), color.withValues(alpha: 0.35), Colors.transparent, Colors.transparent],
        stops: const [0.0, 0.28, 0.30, 0.58, 0.60, 1.0],
        tileMode: TileMode.repeated,
      ).createShader(Rect.fromLTWH(0, 0, 1, rectHeight));
      return _exportShaderCache[key] = shader;
    } else if (style == 'wavy') {
      paint.strokeWidth = 2.6; paint.strokeCap = StrokeCap.round;
      final path = Path(); path.moveTo(0, y); path.quadraticBezierTo(3, y - 2.2, 6, y); path.quadraticBezierTo(9, y + 2.2, 12, y);
      canvas.drawPath(path, paint);
      final img = recorder.endRecording().toImageSync(12, rectHeight.clamp(1.0, 1000.0).toInt());
      return _exportShaderCache[key] = ImageShader(img, TileMode.repeated, TileMode.repeated, Float64List.fromList([1.0, 0.0, 0.0, 0.0, 0.0, 1.0, 0.0, 0.0, 0.0, 0.0, 1.0, 0.0, 0.0, 0.0, 0.0, 1.0]));
    } else if (style == 'dashed') {
      paint.strokeWidth = 2.6; paint.strokeCap = StrokeCap.round;
      canvas.drawLine(Offset(1, y), Offset(6, y), paint);
      final img = recorder.endRecording().toImageSync(10, rectHeight.clamp(1.0, 1000.0).toInt());
      return _exportShaderCache[key] = ImageShader(img, TileMode.repeated, TileMode.repeated, Float64List.fromList([1.0, 0.0, 0.0, 0.0, 0.0, 1.0, 0.0, 0.0, 0.0, 0.0, 1.0, 0.0, 0.0, 0.0, 0.0, 1.0]));
    } else if (style == 'dotted') {
      paint.strokeWidth = 3.2; paint.strokeCap = StrokeCap.round;
      canvas.drawLine(Offset(2, y), Offset(2.1, y), paint);
      final img = recorder.endRecording().toImageSync(8, rectHeight.clamp(1.0, 1000.0).toInt());
      return _exportShaderCache[key] = ImageShader(img, TileMode.repeated, TileMode.repeated, Float64List.fromList([1.0, 0.0, 0.0, 0.0, 0.0, 1.0, 0.0, 0.0, 0.0, 0.0, 1.0, 0.0, 0.0, 0.0, 0.0, 1.0]));
    }

    paint.strokeWidth = 1.4;
    paint.strokeCap = StrokeCap.round;
    canvas.drawLine(Offset(0, y), Offset(10, y), paint);

    final img = recorder.endRecording().toImageSync(10, rectHeight.clamp(1.0, 1000.0).toInt());
    return _exportShaderCache[key] = ImageShader(img, TileMode.repeated, TileMode.repeated, Float64List.fromList([1.0, 0.0, 0.0, 0.0, 0.0, 1.0, 0.0, 0.0, 0.0, 0.0, 1.0, 0.0, 0.0, 0.0, 0.0, 1.0]));
  }

  InlineSpan _buildRichTextSpanForElement(ExportElement element, TextStyle baseStyle, {List<Map<String, dynamic>>? bgHighlights}) {
    final String text = element.content;
    final List<Map<String, dynamic>> highlights = element.textAttributes ?? [];

    if (highlights.isEmpty) {
      return _buildRichTextSpan(text, baseStyle);
    }

    final int len = text.length;
    final Set<int> boundaries = {0, len};
    for (var h in highlights) {
      final int s = (h['start'] as int).clamp(0, len);
      final int e = (h['end'] as int).clamp(s, len);
      boundaries.add(s);
      boundaries.add(e);
    }

    final sortedBoundaries = boundaries.toList()..sort();
    final List<int> safeBoundaries = [];
    for (int b in sortedBoundaries) {
      if (b > 0 && b < len) {
        final prev = text.codeUnitAt(b - 1);
        final next = text.codeUnitAt(b);
        if (prev >= 0xD800 && prev <= 0xDBFF && next >= 0xDC00 && next <= 0xDFFF) continue;
      }
      safeBoundaries.add(b);
    }

    final List<InlineSpan> spans = [];
    int plainTextOffset = 0;

    for (int i = 0; i < safeBoundaries.length - 1; i++) {
      final start = safeBoundaries[i];
      final end = safeBoundaries[i + 1];
      if (start >= end) continue;

      final chunk = text.substring(start, end);
      TextStyle combinedStyle = baseStyle;

      Color? bgColor;

      for (var h in highlights) {
        final int s = (h['start'] as int).clamp(0, len);
        final int e = (h['end'] as int).clamp(s, len);
        if (s <= start && e >= end) {
          final double fs = (h['fontSize'] as num?)?.toDouble() ?? baseStyle.fontSize ?? 18.0;
          final Color? textColor = h['color'] != null ? Color((h['color'] as num).toInt()) : null;
          final bool bold = h['bold'] == true;
          final bool hasUnderline = h['underline'] == true;

          if (hasUnderline) {
             final String uStyle = h['underlineStyle'] ?? 'solid';
             final Color uColor = h['underlineColor'] != null ? Color((h['underlineColor'] as num).toInt()) : (textColor ?? Colors.black);
             combinedStyle = combinedStyle.copyWith(
               fontSize: fs,
               color: textColor ?? combinedStyle.color,
               fontWeight: bold ? FontWeight.bold : combinedStyle.fontWeight,
               background: Paint()..shader = _getExportUnderlineShader(uStyle, uColor, fs, baseStyle.height ?? 1.2),
             );
          } else {
             combinedStyle = combinedStyle.copyWith(
               fontSize: fs,
               color: textColor ?? combinedStyle.color,
               fontWeight: bold ? FontWeight.bold : combinedStyle.fontWeight,
             );
             if (h['backgroundColor'] != null) {
               bgColor = Color((h['backgroundColor'] as num).toInt());
             }
          }
        }
      }
      
      final pattern = RegExp(r'\[mood_icon:(.*?)\]');
      int lastEnd = 0;
      final List<InlineSpan> chunkSpans = [];
      int chunkPlainLen = 0;

      for (final match in pattern.allMatches(chunk)) {
        if (match.start > lastEnd) {
          final sub = chunk.substring(lastEnd, match.start);
          final parsed = _parseEmojiMapping(sub, combinedStyle);
          chunkSpans.addAll(parsed);
          for (var p in parsed) { chunkPlainLen += p.toPlainText().length; }
        }
        chunkSpans.add(WidgetSpan(
          alignment: PlaceholderAlignment.middle,
          child: Padding(
            padding: const EdgeInsets.only(right: 4.0),
            child: Image.asset(match.group(1)!, width: (combinedStyle.fontSize ?? 18.0) * 1.2, height: (combinedStyle.fontSize ?? 18.0) * 1.2, fit: BoxFit.contain),
          ),
        ));
        chunkPlainLen += 1; // WidgetSpan takes 1 char in plain text
        lastEnd = match.end;
      }
      if (lastEnd < chunk.length) {
        final sub = chunk.substring(lastEnd);
        final parsed = _parseEmojiMapping(sub, combinedStyle);
        chunkSpans.addAll(parsed);
        for (var p in parsed) { chunkPlainLen += p.toPlainText().length; }
      }

      if (bgColor != null && bgHighlights != null) {
        bgHighlights.add({
          'start': plainTextOffset,
          'end': plainTextOffset + chunkPlainLen,
          'color': bgColor,
        });
      }
      plainTextOffset += chunkPlainLen;
      spans.addAll(chunkSpans);
    }
    return TextSpan(children: spans);
  }

  InlineSpan _buildRichTextSpan(String text, TextStyle baseStyle) {
    final List<InlineSpan> spans = [];
    final pattern = RegExp(r'\[mood_icon:(.*?)\]');
    int lastEnd = 0;
    
    for (final match in pattern.allMatches(text)) {
      if (match.start > lastEnd) {
        final sub = text.substring(lastEnd, match.start);
        spans.addAll(_parseEmojiMapping(sub, baseStyle));
      }
      final path = match.group(1)!;
      spans.add(
        WidgetSpan(
          alignment: PlaceholderAlignment.middle,
          child: Padding(
            padding: const EdgeInsets.only(right: 4.0),
            child: Image.asset(
              path,
              width: (baseStyle.fontSize ?? 18.0) * 1.2,
              height: (baseStyle.fontSize ?? 18.0) * 1.2,
              fit: BoxFit.contain,
            ),
          ),
        ),
      );
      lastEnd = match.end;
    }
    if (lastEnd < text.length) {
      spans.addAll(_parseEmojiMapping(text.substring(lastEnd), baseStyle));
    }
    return TextSpan(children: spans);
  }

  List<InlineSpan> _parseEmojiMapping(String text, TextStyle baseStyle) {
    final chunks = EmojiMapping.parseText(text);
    if (chunks.isEmpty) {
      return [TextSpan(text: text, style: baseStyle)];
    }
    return chunks.map((chunk) {
      if (chunk.isEmoji) {
        return WidgetSpan(
          alignment: PlaceholderAlignment.middle,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 1.0),
            child: Image.asset(
              chunk.emojiPath!,
              width: (baseStyle.fontSize ?? 18.0) * 1.3,
              height: (baseStyle.fontSize ?? 18.0) * 1.3,
              fit: BoxFit.contain,
            ),
          ),
        );
      }
      return TextSpan(text: chunk.text, style: baseStyle);
    }).toList();
  }

  Widget _renderElementContent(ExportElement element) {
    final isEditing = element.id == _editingElementId;
    switch (element.type) {

      case 'text':
        Paint? backgroundPaint;
        final validDecorations = ['underline', 'solid', 'circle', 'marker', 'wavy', 'dashed', 'dotted', 'double'];
        if (validDecorations.contains(element.textDecoration)) {
          final styleStr = element.textDecoration == 'underline' ? 'solid' : element.textDecoration;
          backgroundPaint = Paint()
            ..shader = _getExportUnderlineShader(styleStr, element.color, element.fontSize, element.lineHeight);
        }

        final textStyle = TextStyle(
          fontSize: element.fontSize,
          color: element.color,
          fontFamily: element.fontFamily == '系统内置' ? 'LXGWWenKai' : element.fontFamily,
          fontWeight: element.fontWeight == 'bold' ? FontWeight.bold : FontWeight.normal,
          fontStyle: element.fontStyle == 'italic' ? FontStyle.italic : FontStyle.normal,
          decoration: element.textDecoration == 'line-through'
              ? TextDecoration.lineThrough
              : TextDecoration.none,
          letterSpacing: element.letterSpacing,
          height: element.lineHeight,
          background: backgroundPaint,
        );
        final align = element.textAlign == 'center'
            ? TextAlign.center
            : element.textAlign == 'right'
                ? TextAlign.right
                : TextAlign.left;
        final strutStyle = StrutStyle(
          fontSize: element.fontSize,
          height: element.lineHeight,
          fontFamily: element.fontFamily == '系统内置' ? 'LXGWWenKai' : element.fontFamily,
          forceStrutHeight: true,
        );

        if (isEditing) {
          Widget editorWidget = TextField(
            controller: _textEditorController,
            focusNode: _inlineFocusNode,
            autofocus: true,
            maxLines: null,
            textAlign: align,
            style: textStyle,
            strutStyle: strutStyle,
            decoration: const InputDecoration(
              border: InputBorder.none,
              isDense: true,
              contentPadding: EdgeInsets.zero,
            ),
            onChanged: (val) {
              updateState(() {
                element.content = val;
                _adjustTextElementWidth(element);
              });
            },
            onSubmitted: (_) {
              updateState(() {
                _editingElementId = null;
              });
            },
          );

          bool isSystemTag = element.id.startsWith('diary_metadata_tag_');
          if (element.textBackgroundColor != null && isSystemTag) {
            editorWidget = Container(
              padding: EdgeInsets.all(element.textBackgroundPadding),
              decoration: BoxDecoration(
                color: element.textBackgroundColor!.withValues(alpha: element.textBackgroundOpacity),
                borderRadius: BorderRadius.circular(element.textBackgroundBorderRadius),
              ),
              child: editorWidget,
            );
          }

          return Opacity(
            opacity: element.opacity,
            child: editorWidget,
          );
        }

        List<Map<String, dynamic>> bgHighlights = [];
        final TextSpan finalSpan = _buildRichTextSpanForElement(element, textStyle, bgHighlights: bgHighlights) as TextSpan;

        bool isSystemTag = element.id.startsWith('diary_metadata_tag_');
        if (element.textBackgroundColor != null && !isSystemTag) {
          bgHighlights.insert(0, {
            'start': 0,
            'end': finalSpan.toPlainText().length,
            'color': element.textBackgroundColor,
          });
        }

        Widget textWidget = SizedBox(
          width: element.width - ((element.textBackgroundColor != null && isSystemTag) ? (element.textBackgroundPadding * 2) : 0.0),
          child: CustomPaint(
            painter: ExportBrushBackgroundPainter(
              textSpan: finalSpan,
              textAlign: align,
              strutStyle: strutStyle,
              bgHighlights: bgHighlights,
            ),
            child: Text.rich(
              finalSpan,
              textAlign: align,
              strutStyle: strutStyle,
            ),
          ),
        );

        if (element.textBackgroundColor != null && isSystemTag) {
          textWidget = Container(
            padding: EdgeInsets.all(element.textBackgroundPadding),
            decoration: BoxDecoration(
              color: element.textBackgroundColor!.withValues(alpha: element.textBackgroundOpacity),
              borderRadius: BorderRadius.circular(element.textBackgroundBorderRadius),
            ),
            child: textWidget,
          );
        }

        return Opacity(
          opacity: element.opacity,
          child: textWidget,
        );

      case 'image':
        final isNetwork = element.content.startsWith('http://') || element.content.startsWith('https://');
        final isChart = element.content.contains('chart_') || element.id.contains('chart_');
        final fit = isChart ? BoxFit.contain : BoxFit.cover;
        return Opacity(
          opacity: element.opacity,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(element.borderRadius),
            child: isNetwork
                ? Image.network(
                    element.content,
                    fit: fit,
                    errorBuilder: (_, _, _) => const Center(
                      child: Icon(Icons.image, color: Colors.grey),
                    ),
                  )
                : Image.file(
                    File(element.content),
                    fit: fit,
                    errorBuilder: (_, _, _) => const Center(
                      child: Icon(Icons.broken_image, color: Colors.grey),
                    ),
                  ),
          ),
        );
      case 'line':
        return Opacity(
          opacity: element.opacity,
          child: CustomPaint(
            size: Size(element.width, element.height < 30.0 ? 30.0 : element.height),
            painter: LinePainter(
              color: element.color,
              thickness: element.height,
              style: element.content.isEmpty ? 'solid' : element.content,
            ),
          ),
        );
      case 'shape':
        return Opacity(
          opacity: element.opacity,
          child: CustomPaint(
            size: Size(element.width, element.height),
            painter: ShapePainter(
              shapeType: element.content,
              color: element.color,
            ),
          ),
        );
      case 'chart':
        return _renderChartElement(element);
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _renderChartElement(ExportElement element) {
    final String chartType = element.content;
    final allDiaries = UserState().savedDiaries.value;
    Widget chartWidget;
    if (chartType == 'radar') {
      chartWidget = ExportRadarChart(diaries: allDiaries);
    } else if (chartType == 'trend') {
      chartWidget = ExportTrendChart(diaries: allDiaries);
    } else if (chartType == 'weekly') {
      chartWidget = ExportWeeklyChart(diaries: allDiaries);
    } else if (chartType == 'palette') {
      chartWidget = ExportPaletteChart(diaries: allDiaries);
    } else if (chartType == 'mood_flow') {
      chartWidget = ExportMoodFlowChart(diaries: allDiaries);
    } else if (chartType == 'heatmap') {
      chartWidget = ExportHeatmapChart(diaries: allDiaries);
    } else {
      return const SizedBox.shrink();
    }

    final double targetHeight = (chartType == 'radar')
        ? 360
        : (chartType == 'mood_flow' ? 240 : 220);

    return FittedBox(
      fit: BoxFit.contain,
      child: SizedBox(
        width: 300,
        height: targetHeight,
        child: chartWidget,
      ),
    );
  }
}

class LinePainter extends CustomPainter {
  final Color color;
  final double thickness;
  final String style; // 'solid', 'dashed', 'dotted', 'double', 'wavy'

  LinePainter({required this.color, required this.thickness, required this.style});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = thickness
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final double y = size.height / 2;

    if (style == 'dashed') {
      const double dashWidth = 8;
      const double dashSpace = 4;
      double startX = 0;
      while (startX < size.width) {
        final double endX = (startX + dashWidth).clamp(0, size.width);
        canvas.drawLine(Offset(startX, y), Offset(endX, y), paint);
        startX += dashWidth + dashSpace;
      }
    } else if (style == 'dotted') {
      final double spacing = (thickness * 2.5).clamp(6.0, 24.0);
      double startX = 0;
      final dotPaint = Paint()
        ..color = color
        ..style = PaintingStyle.fill;
      while (startX <= size.width) {
        canvas.drawCircle(Offset(startX, y), thickness / 2, dotPaint);
        startX += spacing;
      }
    } else if (style == 'double') {
      final double lineThickness = (thickness / 3).clamp(0.5, 5.0);
      final double offset = (thickness / 2).clamp(1.5, 10.0);
      final double y1 = y - offset;
      final double y2 = y + offset;
      
      final dPaint = Paint()
        ..color = color
        ..strokeWidth = lineThickness
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round;
        
      canvas.drawLine(Offset(0, y1), Offset(size.width, y1), dPaint);
      canvas.drawLine(Offset(0, y2), Offset(size.width, y2), dPaint);
    } else if (style == 'wavy') {
      final path = Path();
      const double waveLength = 12.0;
      final double waveHeight = (thickness * 1.5).clamp(2.0, 10.0);
      
      path.moveTo(0, y);
      double x = 0;
      bool up = true;
      
      while (x < size.width) {
        final nextX = (x + waveLength / 2).clamp(0.0, size.width);
        final controlX = x + waveLength / 4;
        final controlY = up ? y - waveHeight : y + waveHeight;
        path.quadraticBezierTo(controlX, controlY, nextX, y);
        x = nextX;
        up = !up;
      }
      canvas.drawPath(path, paint);
    } else {
      // 默认 solid 实线
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant LinePainter oldDelegate) {
    return oldDelegate.color != color || oldDelegate.thickness != thickness || oldDelegate.style != style;
  }
}

class ShapePainter extends CustomPainter {
  final String shapeType;
  final Color color;

  ShapePainter({required this.shapeType, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    if (shapeType == 'circle') {
      canvas.drawCircle(Offset(size.width / 2, size.height / 2), size.width / 2, paint);
    } else if (shapeType == 'rounded_rect') {
      final rrect = RRect.fromRectAndRadius(
        Rect.fromLTWH(0, 0, size.width, size.height),
        Radius.circular((size.width * 0.15).clamp(4.0, 24.0)),
      );
      canvas.drawRRect(rrect, paint);
    } else if (shapeType == 'triangle') {
      final path = Path()
        ..moveTo(size.width / 2, 0)
        ..lineTo(size.width, size.height)
        ..lineTo(0, size.height)
        ..close();
      canvas.drawPath(path, paint);
    } else if (shapeType == 'star') {
      final path = Path();
      final double cx = size.width / 2;
      final double cy = size.height / 2;
      final double r = size.width / 2;
      final double innerR = r * 0.4;
      const int points = 5;
      
      double angle = -pi / 2;
      final double dAngle = pi / points;
      
      path.moveTo(cx + r * cos(angle), cy + r * sin(angle));
      
      for (int i = 0; i < points * 2 - 1; i++) {
        angle += dAngle;
        final double currR = i.isEven ? innerR : r;
        path.lineTo(cx + currR * cos(angle), cy + currR * sin(angle));
      }
      path.close();
      canvas.drawPath(path, paint);
    } else if (shapeType == 'heart') {
      final path = Path();
      final double width = size.width;
      final double height = size.height;
      
      path.moveTo(width / 2, height * 0.25);
      path.cubicTo(width * 0.2, 0, 0, height * 0.2, 0, height * 0.5);
      path.cubicTo(0, height * 0.8, width * 0.35, height, width / 2, height);
      path.cubicTo(width * 0.65, height, width, height * 0.8, width, height * 0.5);
      path.cubicTo(width, height * 0.2, width * 0.8, 0, width / 2, height * 0.25);
      
      canvas.drawPath(path, paint);
    } else {
      // 默认 rectangle 矩形
      canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), paint);
    }
  }

  @override
  bool shouldRepaint(covariant ShapePainter oldDelegate) {
    return oldDelegate.shapeType != shapeType || oldDelegate.color != color;
  }
}

class ExportBrushBackgroundPainter extends CustomPainter {
  final TextSpan textSpan;
  final TextAlign textAlign;
  final StrutStyle? strutStyle;
  final List<Map<String, dynamic>> bgHighlights;

  ExportBrushBackgroundPainter({
    required this.textSpan,
    required this.textAlign,
    this.strutStyle,
    required this.bgHighlights,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (bgHighlights.isEmpty) return;

    final textPainter = TextPainter(
      text: textSpan,
      textAlign: textAlign,
      strutStyle: strutStyle,
      textDirection: TextDirection.ltr,
    );
    textPainter.layout(maxWidth: size.width);

    for (var region in bgHighlights) {
      final bgColor = region['color'] as Color;
      final start = region['start'] as int;
      final end = region['end'] as int;
      if (start >= end) continue;

      final boxes = textPainter.getBoxesForSelection(
        TextSelection(baseOffset: start, extentOffset: end),
      );

      for (var box in boxes) {
        final rect = box.toRect();
        if (rect.isEmpty || rect.width < 2) continue;

        final double padX = 0.0;
        final double padY = 3.0;
        final double l = rect.left - padX;
        final double r = rect.right + padX;
        final double t = rect.top + padY;
        final double b = rect.bottom - padY;
        final double h = b - t;
        if (h <= 0) continue;

        final paint = Paint()
          ..style = PaintingStyle.fill
          ..color = bgColor.withValues(alpha: 0.35);

        final rRect = RRect.fromLTRBR(l, t + h * 0.1, r, b - h * 0.1, const Radius.circular(4.0));
        canvas.drawRRect(rRect, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant ExportBrushBackgroundPainter oldDelegate) {
    return oldDelegate.textSpan != textSpan || oldDelegate.bgHighlights != bgHighlights;
  }
}
