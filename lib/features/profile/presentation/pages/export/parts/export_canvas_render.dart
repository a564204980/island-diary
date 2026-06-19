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

    // 完美抵消居中排版带来的文本下沉量，并使用 clamp 限制坐标在图片高度内以防溢出消失
    final double y = (fontSize * 1.2 + (lineHeight - 1.0) * fontSize * 0.5).clamp(0.0, rectHeight - 2.5);

    paint.strokeWidth = 1.4;
    paint.strokeCap = StrokeCap.round;
    canvas.drawLine(Offset(0, y), Offset(10, y), paint);

    final picture = recorder.endRecording();
    final width = 10;
    final height = rectHeight.clamp(1.0, 1000.0).toInt();
    final img = picture.toImageSync(width, height);
    final shader = ImageShader(
      img,
      TileMode.repeated,
      TileMode.repeated,
      Float64List.fromList([
        1.0, 0.0, 0.0, 0.0,
        0.0, 1.0, 0.0, 0.0,
        0.0, 0.0, 1.0, 0.0,
        0.0, 0.0, 0.0, 1.0,
      ]),
    );
    _exportShaderCache[key] = shader;
    return shader;
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
        if (element.textDecoration == 'underline') {
          backgroundPaint = Paint()
            ..shader = _getExportUnderlineShader('solid', element.color, element.fontSize, element.lineHeight);
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

          if (element.textBackgroundColor != null) {
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

        Widget textWidget = SizedBox(
          width: element.width - ((element.textBackgroundColor != null) ? (element.textBackgroundPadding * 2) : 0.0),
          child: Text.rich(
            _buildRichTextSpan(element.content, textStyle) as TextSpan,
            textAlign: align,
            strutStyle: strutStyle,
          ),
        );

        if (element.textBackgroundColor != null) {
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
