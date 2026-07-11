part of '../../diary_book_export_page.dart';

extension _ExportElementsLogic on _DiaryBookExportPageState {
  void _initDefaultElements() {
    _elements = [];
    _pageBgSettings.clear();
    if (widget.diaries.isEmpty) return;

    double currentY = _margin.top;
    final double availableWidth = _canvasWidth - _margin.left - _margin.right;
    const double spacing = 8.0;

    // 辅助方法：分页检查
    double checkPagination(double targetY, double itemHeight) {
      int pageIndex = (targetY / _canvasHeight).floor();
      double pageBottom = (pageIndex + 1) * _canvasHeight - _margin.bottom;
      if (targetY + itemHeight > pageBottom) {
        return (pageIndex + 1) * _canvasHeight + _margin.top;
      }
      return targetY;
    }

    // 辅助方法：将正文切分成独立的句子，保留句末标点符号及处理换行
    List<String> splitIntoSentences(String text) {
      if (text.isEmpty) return [];
      // 正则：匹配遇到标点（。？！；）或者换行符（\n）进行断句并保留标点
      final RegExp regExp = RegExp(r'[^。？！;\n]+[。？！;\n]?');
      final Iterable<Match> matches = regExp.allMatches(text);
      
      List<String> result = [];
      for (final match in matches) {
        final s = match.group(0)?.trim() ?? '';
        if (s.isNotEmpty) {
          result.add(s);
        }
      }
      if (result.isEmpty) {
        result.add(text);
      }
      return result;
    }

    for (int diaryIdx = 0; diaryIdx < widget.diaries.length; diaryIdx++) {
      final diary = widget.diaries[diaryIdx];
      final dt = diary.dateTime;
      final inkColor = DiaryUtils.getInkColor(diary.paperStyle, false);

      // 如果不是第一篇日记，默认另起一页排版（每一篇日记独占新的一页开始）
      if (diaryIdx > 0) {
        int currentPageIndex = (currentY / _canvasHeight).floor();
        currentY = (currentPageIndex + 1) * _canvasHeight + _margin.top;
      }
      final int startPageIndex = (currentY / _canvasHeight).floor();

      // 1. 日期天数元素 (Georgia 68)
      final dayElement = ExportElement(
        id: 'diary_date_day_${diary.id}_${DateTime.now().millisecondsSinceEpoch}',
        type: 'text',
        x: _margin.left,
        y: currentY,
        width: 80,
        height: 68,
        content: dt.day.toString(),
        fontSize: 68,
        color: inkColor,
        fontFamily: 'Georgia',
        lineHeight: 1.0,
      );
      _adjustTextElementWidth(dayElement);
      _elements.add(dayElement);

      // 2. 年月文本元素 (LXGWWenKai 14, 带有 alpha 0.6 柔和色彩)
      final yearMonthElement = ExportElement(
        id: 'diary_date_year_month_${diary.id}_${DateTime.now().millisecondsSinceEpoch}',
        type: 'text',
        x: _margin.left + dayElement.width - 4,
        y: currentY + 13,
        width: 150,
        height: 25,
        content: "${dt.year}年${dt.month}月",
        fontSize: 14,
        color: inkColor.withValues(alpha: 0.6),
        fontFamily: 'LXGWWenKai',
        lineHeight: 1.2,
      );
      _adjustTextElementWidth(yearMonthElement);
      _elements.add(yearMonthElement);

      // 3. 星期与具体时刻元素 (LXGWWenKai 16, FontWeight.bold 粗体)
      final weekTimeElement = ExportElement(
        id: 'diary_date_week_time_${diary.id}_${DateTime.now().millisecondsSinceEpoch}',
        type: 'text',
        x: _margin.left + dayElement.width - 4,
        y: currentY + 32,
        width: 180,
        height: 30,
        content: "${["星期一", "星期二", "星期三", "星期四", "星期五", "星期六", "星期日"][dt.weekday - 1]}  ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}",
        fontSize: 16,
        fontWeight: 'bold',
        color: inkColor.withValues(alpha: 0.8),
        fontFamily: 'LXGWWenKai',
        lineHeight: 1.2,
      );
      _adjustTextElementWidth(weekTimeElement);
      _elements.add(weekTimeElement);

      currentY += 70;

      // 4. 将心情、标签、天气、地点作为独立的文本标签元素进行流式排布并计算高度
      final parsed = ParsedTags.parse(diary.tag, diary.moodIndex);
      final mood = kMoods[diary.moodIndex.clamp(0, kMoods.length - 1)];
      final String moodLabel = parsed.customMood ?? mood.label;
      
      final List<String> tagTexts = [];
      final String mascotPath = UserState().selectedMascotType.value;
      String categoryId = '云织';
      if (mascotPath.contains('marshmallow2')) {
        categoryId = '笃守';
      } else if (mascotPath.contains('marshmallow3')) {
        categoryId = '灵犀';
      } else if (mascotPath.contains('marshmallow4')) {
        categoryId = '霜见';
      }

      final moodMap = const {
        '低落': ['低落', '呜呜', '大哭', '委屈'],
        '烦躁': ['烦躁', '生气', '叹气'],
        '疲惫': ['疲惫', '困', '叹气'],
        '惊喜': ['惊喜', '惊讶', '震惊'],
        '平静': ['平静', '好的', '发呆'],
        '焦虑': ['焦虑', '委屈', '生气'],
        '无聊': ['无聊', '无语', '发呆'],
        '期待': ['期待', '比心', '星星', '喜欢'],
      };

      int? matchedPua;
      final category = EmojiMapping.categories.firstWhere((c) => c['id'] == categoryId, orElse: () => EmojiMapping.categories.first);
      final emojis = category['emojis'] as List;

      for (var e in emojis) {
        if (e['name'] == moodLabel) {
          matchedPua = e['pua'] as int;
          break;
        }
      }

      if (matchedPua == null && moodMap.containsKey(moodLabel)) {
        for (var altName in moodMap[moodLabel]!) {
          for (var e in emojis) {
            if (e['name'] == altName) {
              matchedPua = e['pua'] as int;
              break;
            }
          }
          if (matchedPua != null) break;
        }
      }

      if (matchedPua == null) {
        for (var e in emojis) {
          if (e['name'] == '开心') {
            matchedPua = e['pua'] as int;
            break;
          }
        }
      }

      final String moodEmoji = matchedPua != null ? String.fromCharCode(matchedPua) : '😊';
      tagTexts.add("$moodEmoji $moodLabel");
      for (var t in parsed.tags) {
        tagTexts.add("#$t");
      }
      if (diary.weather != null) {
        tagTexts.add("☀️ ${diary.weather} ${diary.temp ?? ''}");
      }
      if (diary.location != null) {
        tagTexts.add("📍 ${diary.location!}");
      }

      double currentTagX = _margin.left;
      double currentTagY = currentY;
      final double maxTagRight = _canvasWidth - _margin.right;

      for (int i = 0; i < tagTexts.length; i++) {
        final String text = tagTexts[i];
        
        final tempElem = ExportElement(
          id: 'temp_tag_${diary.id}_$i',
          type: 'text',
          x: 0,
          y: 0,
          width: 100,
          height: 24,
          content: text,
          fontSize: 11,
          fontWeight: 'bold',
          textAlign: 'center',
          color: const Color(0xFF5E6C6D),
          textBackgroundColor: const Color(0xFF000000),
          textBackgroundBorderRadius: 12.0,
          textBackgroundPadding: 6.0,
          textBackgroundOpacity: 0.04,
        );
        _adjustTextElementWidth(tempElem);
        
        if (currentTagX + tempElem.width > maxTagRight && currentTagX > _margin.left) {
          currentTagX = _margin.left;
          currentTagY += 36;
        }

        _elements.add(
          ExportElement(
            id: 'diary_metadata_tag_${diary.id}_${i}_${DateTime.now().millisecondsSinceEpoch}',
            type: 'text',
            x: currentTagX,
            y: currentTagY,
            width: tempElem.width,
            height: 24,
            content: text,
            fontSize: 11,
            fontWeight: 'bold',
            textAlign: 'center',
            color: const Color(0xFF5E6C6D),
            textBackgroundColor: const Color(0xFF000000),
            textBackgroundBorderRadius: 12.0,
            textBackgroundPadding: 6.0,
            textBackgroundOpacity: 0.04,
          ),
        );

        currentTagX += tempElem.width + 8;
      }

      currentY = tagTexts.isEmpty ? currentY : (currentTagY + 36);

      final rawContent = diary.content;

      final List<String> sentences = splitIntoSentences(rawContent);

      for (int i = 0; i < sentences.length; i++) {
        final sentence = sentences[i];
        final sentenceElement = ExportElement(
          id: 'diary_content_${diary.id}_$i',
          type: 'text',
          x: _margin.left,
          y: currentY,
          width: availableWidth,
          height: 30,
          content: sentence,
          fontSize: 15,
          color: Colors.black87,
        );

        _adjustTextElementWidth(sentenceElement);

        final sStyle = TextStyle(
          fontSize: sentenceElement.fontSize,
          fontFamily: 'LXGWWenKai',
          height: sentenceElement.lineHeight,
        );
        final sPainter = TextPainter(
          text: TextSpan(text: sentenceElement.content, style: sStyle),
          textDirection: TextDirection.ltr,
        )..layout(maxWidth: availableWidth);

        sentenceElement.height = sPainter.height;

        // 检查分页定位
        currentY = checkPagination(currentY, sentenceElement.height);
        sentenceElement.y = currentY;
        _elements.add(sentenceElement);

        // 每句话留 12 像素的段落句间距
        currentY += sentenceElement.height + 12;
      }

      // 6. 解析日记的 blocks 数据并计算图片坐标
      final List<DiaryBlock> diaryBlocks = diary.blocks.map((b) => DiaryBlock.fromMap(b)).toList();
      final List<DiaryBlock> processedBlocks = ImageGroupBlock.preprocess(
        diaryBlocks,
        isMixedLayout: true,
        isImageGrid: true,
      );

      for (var block in processedBlocks) {
        if (block is ImageBlock) {
          final double h = availableWidth / 1.5;
          currentY = checkPagination(currentY, h);
          _elements.add(
            ExportElement(
              id: 'diary_image_${diary.id}_${block.id}',
              type: 'image',
              x: _margin.left,
              y: currentY,
              width: availableWidth,
              height: h,
              content: block.file.path,
              borderRadius: 16.0,
            ),
          );
          currentY += h + 8.0;
        } else if (block is ImageGroupBlock) {
          final images = block.images;
          int index = 0;
          while (index < images.length) {
            final chunk = images.sublist(index, (index + 5).clamp(0, images.length));
            final n = chunk.length;
            if (n == 1) {
              final double h = availableWidth / 1.5;
              currentY = checkPagination(currentY, h);
              _elements.add(
                ExportElement(
                  id: 'diary_image_${diary.id}_${chunk[0].id}',
                  type: 'image',
                  x: _margin.left,
                  y: currentY,
                  width: availableWidth,
                  height: h,
                  content: chunk[0].file.path,
                  borderRadius: 16.0,
                ),
              );
              currentY += h;
            } else if (n == 2) {
              final double colW = (availableWidth - spacing) / 2;
              final double h = colW / 0.75;
              currentY = checkPagination(currentY, h);
              _elements.add(
                ExportElement(
                  id: 'diary_image_${diary.id}_${chunk[0].id}',
                  type: 'image',
                  x: _margin.left,
                  y: currentY,
                  width: colW,
                  height: h,
                  content: chunk[0].file.path,
                  borderRadius: 16.0,
                ),
              );
              _elements.add(
                ExportElement(
                  id: 'diary_image_${diary.id}_${chunk[1].id}',
                  type: 'image',
                  x: _margin.left + colW + spacing,
                  y: currentY,
                  width: colW,
                  height: h,
                  content: chunk[1].file.path,
                  borderRadius: 16.0,
                ),
              );
              currentY += h;
            } else if (n == 3) {
              final double h = availableWidth / 1.2;
              final double leftW = (availableWidth - spacing) * 2 / 3;
              final double rightW = (availableWidth - spacing) / 3;
              final double rightH = (h - spacing) / 2;
              currentY = checkPagination(currentY, h);
              _elements.add(
                ExportElement(
                  id: 'diary_image_${diary.id}_${chunk[0].id}',
                  type: 'image',
                  x: _margin.left,
                  y: currentY,
                  width: leftW,
                  height: h,
                  content: chunk[0].file.path,
                  borderRadius: 16.0,
                ),
              );
              _elements.add(
                ExportElement(
                  id: 'diary_image_${diary.id}_${chunk[1].id}',
                  type: 'image',
                  x: _margin.left + leftW + spacing,
                  y: currentY,
                  width: rightW,
                  height: rightH,
                  content: chunk[1].file.path,
                  borderRadius: 16.0,
                ),
              );
              _elements.add(
                ExportElement(
                  id: 'diary_image_${diary.id}_${chunk[2].id}',
                  type: 'image',
                  x: _margin.left + leftW + spacing,
                  y: currentY + rightH + spacing,
                  width: rightW,
                  height: rightH,
                  content: chunk[2].file.path,
                  borderRadius: 16.0,
                ),
              );
              currentY += h;
            } else if (n == 4) {
              final double h = availableWidth / 1.1;
              final double leftW = (availableWidth - spacing) * 2 / 3;
              final double rightW = (availableWidth - spacing) / 3;
              final double rightH = (h - 2 * spacing) / 3;
              currentY = checkPagination(currentY, h);
              _elements.add(
                ExportElement(
                  id: 'diary_image_${diary.id}_${chunk[0].id}',
                  type: 'image',
                  x: _margin.left,
                  y: currentY,
                  width: leftW,
                  height: h,
                  content: chunk[0].file.path,
                  borderRadius: 16.0,
                ),
              );
              _elements.add(
                ExportElement(
                  id: 'diary_image_${diary.id}_${chunk[1].id}',
                  type: 'image',
                  x: _margin.left + leftW + spacing,
                  y: currentY,
                  width: rightW,
                  height: rightH,
                  content: chunk[1].file.path,
                  borderRadius: 16.0,
                ),
              );
              _elements.add(
                ExportElement(
                  id: 'diary_image_${diary.id}_${chunk[2].id}',
                  type: 'image',
                  x: _margin.left + leftW + spacing,
                  y: currentY + rightH + spacing,
                  width: rightW,
                  height: rightH,
                  content: chunk[2].file.path,
                  borderRadius: 16.0,
                ),
              );
              _elements.add(
                ExportElement(
                  id: 'diary_image_${diary.id}_${chunk[3].id}',
                  type: 'image',
                  x: _margin.left + leftW + spacing,
                  y: currentY + 2 * (rightH + spacing),
                  width: rightW,
                  height: rightH,
                  content: chunk[3].file.path,
                  borderRadius: 16.0,
                ),
              );
              currentY += h;
            } else { // n == 5
              final double topH = availableWidth / 1.1;
              final double bottomH = availableWidth / 3.0;
              final double leftW = (availableWidth - spacing) * 2 / 3;
              final double rightW = (availableWidth - spacing) / 3;
              final double rightH = (topH - 2 * spacing) / 3;
              
              currentY = checkPagination(currentY, topH);
              
              _elements.add(
                ExportElement(
                  id: 'diary_image_${diary.id}_${chunk[0].id}',
                  type: 'image',
                  x: _margin.left,
                  y: currentY,
                  width: leftW,
                  height: topH,
                  content: chunk[0].file.path,
                  borderRadius: 16.0,
                ),
              );
              _elements.add(
                ExportElement(
                  id: 'diary_image_${diary.id}_${chunk[1].id}',
                  type: 'image',
                  x: _margin.left + leftW + spacing,
                  y: currentY,
                  width: rightW,
                  height: rightH,
                  content: chunk[1].file.path,
                  borderRadius: 16.0,
                ),
              );
              _elements.add(
                ExportElement(
                  id: 'diary_image_${diary.id}_${chunk[2].id}',
                  type: 'image',
                  x: _margin.left + leftW + spacing,
                  y: currentY + rightH + spacing,
                  width: rightW,
                  height: rightH,
                  content: chunk[2].file.path,
                  borderRadius: 16.0,
                ),
              );
              _elements.add(
                ExportElement(
                  id: 'diary_image_${diary.id}_${chunk[3].id}',
                  type: 'image',
                  x: _margin.left + leftW + spacing,
                  y: currentY + 2 * (rightH + spacing),
                  width: rightW,
                  height: rightH,
                  content: chunk[3].file.path,
                  borderRadius: 16.0,
                ),
              );
              
              currentY += topH + spacing;
              
              currentY = checkPagination(currentY, bottomH);
              
              _elements.add(
                ExportElement(
                  id: 'diary_image_${diary.id}_${chunk[4].id}',
                  type: 'image',
                  x: _margin.left,
                  y: currentY,
                  width: availableWidth,
                  height: bottomH,
                  content: chunk[4].file.path,
                  borderRadius: 16.0,
                ),
              );
              currentY += bottomH;
            }
            index += 5;
            if (index < images.length) {
              currentY += 8.0;
            }
          }
          currentY += 8.0;
        }
      }

      final int endPageIndex = (currentY / _canvasHeight).floor();
      for (int pIdx = startPageIndex; pIdx <= endPageIndex; pIdx++) {
        final String paperBg = DiaryUtils.getPaperBackgroundPath(diary.paperStyle, false);
        final Color paperColor = DiaryUtils.getPaperBaseColor(diary.paperStyle, false);
        _pageBgSettings.putIfAbsent(
          pIdx,
          () => ExportBackgroundSettings(
            color: paperColor,
            imagePath: paperBg.isNotEmpty ? paperBg : null,
            opacity: 1.0,
            x: 0.0,
            y: 0.0,
            scale: 1.0,
            cropRatio: null,
          ),
        );
      }
    }

    // 针对短文本元素自适应测量实际文字宽度以紧贴文本内容
    for (var element in _elements) {
      if (element.type == 'text' && !element.id.contains('diary_content_') && !element.id.contains('diary_metadata_tag_')) {
        _adjustTextElementWidth(element);
      }
    }
  }


  void _updateElementsMargin() {
    updateState(() {
      _initDefaultElements();
    });
  }


  void _adjustTextElementWidth(ExportElement element) {
    if (element.type != 'text') return;
    final textStyle = TextStyle(
      fontSize: element.fontSize,
      fontFamily: element.fontFamily == '系统内置' ? 'LXGWWenKai' : element.fontFamily,
      fontWeight: element.fontWeight == 'bold' ? FontWeight.bold : FontWeight.normal,
      fontStyle: element.fontStyle == 'italic' ? FontStyle.italic : FontStyle.normal,
      letterSpacing: element.letterSpacing,
      height: element.lineHeight,
    );
    double extraWidgetWidth = 0.0;
    
    // 1. Calculate mood_icon width (width: fontSize * 1.2, plus padding right 4.0)
    final moodPattern = RegExp(r'\[mood_icon:(.*?)\]');
    final moodMatches = moodPattern.allMatches(element.content);
    final double moodIconWidth = (element.fontSize) * 1.2 + 4.0;
    extraWidgetWidth += moodMatches.length * moodIconWidth;
    
    // 2. Clean text string without mood_icons for emoji parsing
    String textWithoutMood = element.content.replaceAll(moodPattern, '');
    
    // 3. Calculate PUA emojis width (width: fontSize * 1.3, plus padding horizontal 1.0*2)
    final chunks = EmojiMapping.parseText(textWithoutMood);
    final double puaEmojiWidth = (element.fontSize) * 1.3 + 2.0;
    
    StringBuffer plainTextBuilder = StringBuffer();
    for (var chunk in chunks) {
      if (chunk.isEmoji) {
        extraWidgetWidth += puaEmojiWidth;
      } else {
        plainTextBuilder.write(chunk.text);
      }
    }
    
    final plainText = plainTextBuilder.toString();

    final textPainter = TextPainter(
      text: TextSpan(text: plainText, style: textStyle),
      textDirection: TextDirection.ltr,
    )..layout(maxWidth: _canvasWidth - _margin.left - _margin.right);
    // 额外留出 16dp 容错间距与文本背景的 padding (防止意外换行)
    final double paddingOffset = (element.textBackgroundColor != null) ? (element.textBackgroundPadding * 2) : 0.0;
    element.width = (textPainter.maxIntrinsicWidth + extraWidgetWidth + 16.0 + paddingOffset).clamp(50.0, _canvasWidth - _margin.left - _margin.right);
  }


}
