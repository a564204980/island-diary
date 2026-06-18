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
    final chunks = EmojiMapping.parseText(text);
    if (chunks.isEmpty) {
      return TextSpan(text: text, style: baseStyle);
    }
    return TextSpan(
      children: chunks.map((chunk) {
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
      }).toList(),
    );
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
        return Divider(
          color: element.color,
          thickness: element.height,
        );
      case 'shape':
        if (element.content == 'circle') {
          return Container(
            decoration: BoxDecoration(
              color: element.color,
              shape: BoxShape.circle,
            ),
          );
        } else {
          return Container(
            color: element.color,
          );
        }
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
