import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
import 'dart:io';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:island_diary/features/record/domain/models/diary_entry.dart';
import 'package:island_diary/shared/widgets/mood_picker/config/mood_config.dart';
import 'package:island_diary/shared/widgets/diary_entry/utils/emoji_mapping.dart';

enum PdfThemeType { classic, minimalist }

class _PdfThemeColors {
  final PdfColor primaryText;
  final PdfColor secondaryText;
  final PdfColor tertiaryText;
  final PdfColor divider;

  const _PdfThemeColors({
    required this.primaryText,
    required this.secondaryText,
    required this.tertiaryText,
    required this.divider,
  });

  static const classic = _PdfThemeColors(
    primaryText: PdfColors.brown900,
    secondaryText: PdfColors.brown400,
    tertiaryText: PdfColors.brown300,
    divider: PdfColors.brown50,
  );

  static const minimalist = _PdfThemeColors(
    primaryText: PdfColors.grey900,
    secondaryText: PdfColors.grey600,
    tertiaryText: PdfColors.grey400,
    divider: PdfColors.grey200,
  );
}

class ExportService {
  static Future<void> exportToPdf(
      List<DiaryEntry> entries, String title, String userName, {PdfThemeType theme = PdfThemeType.classic, bool includeBackground = false}) async {
    try {
      final bytes = await generatePdfBytes(entries, title, userName, theme: theme, includeBackground: includeBackground);
      if (bytes == null) return;
      
      try {
        await Printing.layoutPdf(
          onLayout: (PdfPageFormat format) async => bytes,
          name: 'isle_diary_book_${DateTime.now().millisecondsSinceEpoch}.pdf',
        );
      } catch (e) {
        debugPrint("PDF CORE: Printing.layoutPdf failed, falling back to share: $e");
        throw 'PRINT_SERVICE_NOT_FOUND';
      }
    } catch (e, stack) {
      if (e == 'PRINT_SERVICE_NOT_FOUND') rethrow;
      debugPrint("PDF CORE ERROR: $e\n$stack");
      rethrow;
    }
  }

  static Future<Uint8List?> generatePdfBytes(
      List<DiaryEntry> entries, String title, String userName, {PdfThemeType theme = PdfThemeType.classic, bool includeBackground = false}) async {
    final pdf = pw.Document();
    final colors = theme == PdfThemeType.minimalist ? _PdfThemeColors.minimalist : _PdfThemeColors.classic;

    try {
      // 1. 并行加载核心字体与基础资源
      debugPrint("PDF CORE: Parallel loading started...");
      final fontFuture = rootBundle.load("assets/fonts/LXGWWenKai-Regular.ttf");
      final emojiFontFuture = rootBundle.load("assets/fonts/nishiki-teki.ttf");
      
      final results = await Future.wait([fontFuture, emojiFontFuture]);
      final ttf = pw.Font.ttf(results[0]);
      final emojiFont = pw.Font.ttf(results[1]);

      // 2. 并行加载心情图标
      debugPrint("PDF CORE: Preloading mood icons...");
      final Map<int, pw.ImageProvider> moodIcons = {};
      final List<Future<void>> moodFutures = [];
      
      for (var i = 0; i < kMoods.length; i++) {
        final idx = i;
        moodFutures.add(() async {
          try {
            final iconPath = kMoods[idx].iconPath;
            if (iconPath != null) {
              final iconData = await rootBundle.load(iconPath);
              moodIcons[idx] = pw.MemoryImage(iconData.buffer.asUint8List());
            }
          } catch (e) {
             debugPrint("PDF CORE: Icon $idx load error: $e");
          }
        }());
      }

      // 3. 预分析并并行加载表情图片
      debugPrint("PDF CORE: Preloading emoji images...");
      final Set<String> usedEmojiPaths = {};
      for (var entry in entries) {
        final chunks = EmojiMapping.parseText(entry.content);
        for (var chunk in chunks) {
          if (chunk.isEmoji) {
            usedEmojiPaths.add(chunk.emojiPath!);
          }
        }
        // 扫描回复中的表情
        for (var reply in entry.replies) {
          final replyChunks = EmojiMapping.parseText(reply.content);
          for (var chunk in replyChunks) {
            if (chunk.isEmoji) {
              usedEmojiPaths.add(chunk.emojiPath!);
            }
          }
        }
      }

      final Map<String, pw.ImageProvider> emojiImages = {};
      final List<Future<void>> emojiFutures = [];
      for (var path in usedEmojiPaths) {
        final currentPath = path;
        emojiFutures.add(() async {
          try {
            final data = await rootBundle.load(currentPath);
            emojiImages[currentPath] = pw.MemoryImage(data.buffer.asUint8List());
          } catch (e) {
            debugPrint("PDF CORE: Emoji load error ($currentPath): $e");
          }
        }());
      }

      // 4. 并行加载信纸背景资源 (如果开启)
      final Map<String, pw.ImageProvider> paperBackgrounds = {};
      final List<Future<void>> backgroundFutures = [];
      if (includeBackground) {
        debugPrint("PDF CORE: Preloading paper backgrounds...");
        final Set<String> neededPaperStyles = entries.map((e) => e.paperStyle).where((s) => s.startsWith('note')).toSet();
        for (var style in neededPaperStyles) {
          final currentStyle = style;
          backgroundFutures.add(() async {
            try {
              final fileName = currentStyle.replaceFirst('note', 'note_bg');
              final ext = ['note1', 'note2', 'note3', 'note4', 'note5'].contains(currentStyle) ? '.png' : '.jpg';
              final path = 'assets/images/note/$fileName$ext';
              final data = await rootBundle.load(path);
              paperBackgrounds[currentStyle] = pw.MemoryImage(data.buffer.asUint8List());
            } catch (e) {
              debugPrint("PDF CORE: Paper background load error ($currentStyle): $e");
            }
          }());
        }
      }

      // 等待所有异步资源完成
      await Future.wait([...moodFutures, ...emojiFutures, ...backgroundFutures]);
      debugPrint("PDF CORE: All assets ready.");

      // 4. 内容排序与文案准备
      final sortedEntries = List<DiaryEntry>.from(entries)
        ..sort((a, b) => b.dateTime.compareTo(a.dateTime));

      final quotes = [
        "每一个普通的日子，都因为记录而变得闪亮。",
        "岁月的波纹，在笔尖轻轻荡漾。",
        "记录每一寸时光，都是对生活的热望。",
        "这里的每一页，都藏着当下的自己。",
        "时间会带走一切，但文字会留下印记。",
      ];
      final randomQuote = quotes[DateTime.now().millisecond % quotes.length];

      // 5. 生成扉页（封面）
      debugPrint("PDF CORE: Generating cover page...");
      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          theme: pw.ThemeData.withFont(
            base: ttf,
            fontFallback: [emojiFont],
          ),
          build: (context) => _buildCoverPage(entries, title, userName, ttf, colors, emojiFont: emojiFont),
        ),
      );

      // 6. 生成 MultiPage 内容 (正文)
      debugPrint("PDF CORE: Generating MultiPage layout...");
      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          theme: pw.ThemeData.withFont(
            base: ttf,
            fontFallback: [emojiFont],
          ),
          header: (context) => _buildHeader(title, ttf, userName, colors, emojiFont: emojiFont, pageNumber: context.pageNumber),
          footer: (context) => _buildFooter(context.pageNumber, context.pagesCount, ttf, randomQuote, colors),
          build: (context) => [
             // 正文直接开始，不再显示统计（已移至封面）
             for (var e in sortedEntries) ..._buildEntryWidgets(e, moodIcons, emojiImages, paperBackgrounds, ttf, colors, theme, includeBackground),
          ],
        ),
      );

      debugPrint("PDF CORE: Finalizing layout...");
      return await pdf.save();
    } catch (e, stack) {
      debugPrint("PDF CORE ERROR: $e\n$stack");
      return null;
    }
  }

  static pw.Widget _buildHeader(String title, pw.Font font, String userName, _PdfThemeColors colors, {pw.Font? emojiFont, required int pageNumber}) {
    final finalUserName = _cleanString(userName, fallback: "岛屿居民");
    if (pageNumber > 1) {
      return pw.Container(
        margin: const pw.EdgeInsets.only(bottom: 15),
        padding: const pw.EdgeInsets.only(bottom: 5),
        decoration: pw.BoxDecoration(
          border: pw.Border(bottom: pw.BorderSide(color: colors.divider, width: 0.5))
        ),
        child: pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Text(title, style: pw.TextStyle(font: font, fontSize: 10, color: colors.secondaryText)),
            pw.Text('第 $pageNumber 页', style: pw.TextStyle(font: font, fontSize: 8, color: colors.tertiaryText)),
          ],
        ),
      );
    }

    return pw.Container(
      padding: const pw.EdgeInsets.only(bottom: 10),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(title, style: pw.TextStyle(font: font, fontSize: 18, color: colors.primaryText)),
          pw.Text(
            '笔名：$finalUserName', 
            style: pw.TextStyle(
              font: font, 
              fontFallback: emojiFont != null ? [emojiFont] : [],
              fontSize: 10, 
              color: colors.secondaryText
            )
          ),
        ],
      ),
    );
  }

  static pw.Widget _buildFooter(int pageNumber, int totalPages, pw.Font font, String quote, _PdfThemeColors colors) {
    if (pageNumber == 1) return pw.SizedBox(); // 扉页不显示页脚 (pw.Page 不会自动带此页脚，但为保险起见)
    
    return pw.Container(
      alignment: pw.Alignment.centerRight,
      margin: const pw.EdgeInsets.only(top: 20),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.end,
        children: [
          pw.Text(
            quote,
            style: pw.TextStyle(font: font, fontSize: 10, color: colors.secondaryText),
          ),
          pw.SizedBox(height: 5),
          pw.Text(
            '第 $pageNumber / $totalPages 页 · 岛屿日记',
            style: pw.TextStyle(font: font, fontSize: 10, color: colors.tertiaryText),
          ),
        ],
      ),
    );
  }

  /// 渲染独立扉页（封面）
  static pw.Widget _buildCoverPage(List<DiaryEntry> entries, String title, String userName, pw.Font font, _PdfThemeColors colors, {pw.Font? emojiFont}) {
    final days = _countUniqueDays(entries);
    final count = entries.length;
    final finalUserName = _cleanString(userName, fallback: "岛屿居民");

    return pw.FullPage(
      ignoreMargins: false,
      child: pw.Container(
        padding: const pw.EdgeInsets.all(60),
        child: pw.Column(
          mainAxisAlignment: pw.MainAxisAlignment.center,
          crossAxisAlignment: pw.CrossAxisAlignment.center,
          children: [
            pw.Spacer(flex: 2),
            // 标题
            pw.Text(
              title,
              style: pw.TextStyle(
                font: font,
                fontSize: 32,
                fontWeight: pw.FontWeight.bold,
                color: colors.primaryText,
                letterSpacing: 2,
              ),
            ),
            pw.SizedBox(height: 12),
            // 副标题
            pw.Text(
              "心灵栖息的岛屿，时光记录的港湾",
              style: pw.TextStyle(
                font: font,
                fontSize: 14,
                color: colors.secondaryText,
                fontStyle: pw.FontStyle.italic,
              ),
            ),
            pw.SizedBox(height: 40),
            // 装饰线
            pw.Container(
              width: 100,
              height: 1,
              color: colors.divider,
            ),
            pw.SizedBox(height: 40),
            // 统计区域
            pw.Text(
              "于此静谧之岛，已同行 $days 昼夜",
              style: pw.TextStyle(font: font, fontSize: 13, color: colors.secondaryText),
            ),
            pw.SizedBox(height: 10),
            pw.Text(
              "共镌刻了 $count 篇灵魂的回响",
              style: pw.TextStyle(font: font, fontSize: 13, color: colors.secondaryText),
            ),
            pw.Spacer(flex: 3),
            // 底部作者与寄语
            pw.Column(
              children: [
                pw.Text(
                  "笔名：$finalUserName",
                  style: pw.TextStyle(
                    font: font,
                    fontFallback: emojiFont != null ? [emojiFont] : [],
                    fontSize: 12,
                    color: colors.tertiaryText,
                  ),
                ),
                pw.SizedBox(height: 20),
                pw.Text(
                  "“愿这些文字，像岛屿上的微光，照亮未来的每一个清晨。”",
                  style: pw.TextStyle(
                    font: font,
                    fontSize: 11,
                    color: colors.secondaryText,
                    fontStyle: pw.FontStyle.italic,
                  ),
                ),
              ],
            ),
            pw.SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  static List<pw.Widget> _buildEntryWidgets(
    DiaryEntry entry, 
    Map<int, pw.ImageProvider> icons, 
    Map<String, pw.ImageProvider> emojiImages, 
    Map<String, pw.ImageProvider> paperBackgrounds,
    pw.Font font, 
    _PdfThemeColors colors, 
    PdfThemeType theme,
    bool includeBackground,
  ) {
    final weekdays = ["", "周一", "周二", "周三", "周四", "周五", "周六", "周日"];
    final dateStr = "${entry.dateTime.year}/${entry.dateTime.month}/${entry.dateTime.day}";
    final weekdayStr = weekdays[entry.dateTime.weekday];
    final timeStr = "${entry.dateTime.hour.toString().padLeft(2, '0')}:${entry.dateTime.minute.toString().padLeft(2, '0')}";
    
    final widgets = <pw.Widget>[
      pw.SizedBox(height: 8),
      pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        crossAxisAlignment: pw.CrossAxisAlignment.center,
        children: [
          pw.Row(
            children: [
              pw.Text(dateStr, style: pw.TextStyle(font: font, fontSize: 10, fontWeight: pw.FontWeight.bold, color: colors.primaryText)),
              pw.SizedBox(width: 8),
              pw.Text(weekdayStr, style: pw.TextStyle(font: font, fontSize: 8, color: colors.secondaryText)),
              pw.SizedBox(width: 8),
              pw.Text(timeStr, style: pw.TextStyle(font: font, fontSize: 8, color: colors.tertiaryText)),
            ],
          ),
          _buildMoodTagCapsule(entry, icons, font, theme),
        ],
      ),
      pw.SizedBox(height: 3),

      // 内容区域：遍历 blocks 按顺序渲染
      if (entry.blocks.isNotEmpty)
        for (var block in entry.blocks)
          if (block['type'] == 'text')
            _buildStyledTextBlock(block, font, colors, emojiImages)
          else if (block['type'] == 'image')
            pw.Padding(
              padding: const pw.EdgeInsets.only(bottom: 12),
              child: _buildImageBlock(block['path'] as String),
            )
          else if (block['type'] == 'reward')
            pw.Padding(
              padding: const pw.EdgeInsets.only(bottom: 12),
              child: _buildRewardBlock(block, font, colors),
            )
      else // 回退到旧逻辑（针对无 blocks 的旧数据）
        for (var paragraph in entry.content.split('\n'))
          if (paragraph.trim().isNotEmpty)
            pw.Padding(
              padding: const pw.EdgeInsets.only(bottom: 6),
              child: pw.Wrap(
                crossAxisAlignment: pw.WrapCrossAlignment.center,
                children: EmojiMapping.parseText(paragraph).map((chunk) {
                  if (chunk.isEmoji && emojiImages.containsKey(chunk.emojiPath)) {
                    return pw.Padding(
                      padding: const pw.EdgeInsets.symmetric(horizontal: 1),
                      child: pw.Image(
                        emojiImages[chunk.emojiPath!]!,
                        width: 14,
                        height: 14,
                      ),
                    );
                  }
                  return pw.Text(
                    chunk.text,
                    style: pw.TextStyle(
                      font: font,
                      fontSize: 10.5,
                      color: colors.primaryText,
                      height: 1.25,
                    ),
                  );
                }).toList(),
              ),
            )
          else
            pw.SizedBox(height: 6),

      // 整合回复部分
      if (entry.replies.isNotEmpty)
        _buildPdfReplies(entry, font, colors, emojiImages),

      pw.SizedBox(height: 12),
      pw.Divider(height: 1, color: colors.divider, thickness: 0.5),
    ];

    // 如果开启了背景且有对应的背景图，则进行包裹
    if (includeBackground && paperBackgrounds.containsKey(entry.paperStyle)) {
      return [
        pw.Container(
          margin: const pw.EdgeInsets.symmetric(vertical: 10),
          decoration: pw.BoxDecoration(
            image: pw.DecorationImage(
              image: paperBackgrounds[entry.paperStyle]!,
              fit: pw.BoxFit.cover,
              alignment: pw.Alignment.topCenter,
            ),
            borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
            border: pw.Border.all(color: colors.divider, width: 0.5),
          ),
          child: pw.Padding(
            padding: const pw.EdgeInsets.all(12),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: widgets,
            ),
          ),
        ),
      ];
    }

    return widgets;
  }

  /// 渲染并解析带样式的文本块（支持背景色、前景色、表情、话题）
  static pw.Widget _buildStyledTextBlock(Map<String, dynamic> block, pw.Font font, _PdfThemeColors colors, Map<String, pw.ImageProvider> emojiImages) {
    final textContent = block['content']?.toString() ?? "";
    if (textContent.isEmpty) return pw.SizedBox(height: 0);

    final List<Map<String, dynamic>> attributes = List<Map<String, dynamic>>.from(block['attributes'] ?? []);
    final PdfColor baseColor = block['baseColor'] != null ? PdfColor.fromInt(block['baseColor']) : colors.primaryText;
    
    // 1. 收集所有关键边界点
    final Set<int> boundaries = {0, textContent.length};

    // a. 表情边界 (Unicode 或 [名称])
    final emojiKeys = EmojiMapping.unicodeToPath.keys.toList()..sort((a, b) => b.length.compareTo(a.length));
    final emojiPattern = emojiKeys.map((e) => RegExp.escape(e)).join('|');
    final nameKeys = EmojiMapping.nameToPath.keys.toList()..sort((a, b) => b.length.compareTo(a.length));
    final namePattern = nameKeys.map((e) => RegExp.escape('[$e]')).join('|');
    final pattern = [if (emojiPattern.isNotEmpty) emojiPattern, if (namePattern.isNotEmpty) namePattern].join('|');
    if (pattern.isNotEmpty) {
      final emojiRegExp = RegExp(pattern);
      for (final match in emojiRegExp.allMatches(textContent)) {
        boundaries.add(match.start);
        boundaries.add(match.end);
      }
    }

    // c. 样式属性边界
    for (var attr in attributes) {
      boundaries.add((attr['start'] as int).clamp(0, textContent.length));
      boundaries.add((attr['end'] as int).clamp(0, textContent.length));
    }

    final sortedBoundaries = boundaries.toList()..sort();
    final List<pw.InlineSpan> spans = [];

    // 2. 按边界切分并合并样式渲染
    for (int i = 0; i < sortedBoundaries.length - 1; i++) {
        final start = sortedBoundaries[i];
        final end = sortedBoundaries[i + 1];
        if (start >= end) continue;
        final chunk = textContent.substring(start, end);

        // 优先检查是否完全匹配某个表情
        String? emojiPath;
        if (pattern.isNotEmpty) {
          if (chunk.startsWith('[') && chunk.endsWith(']')) {
            final name = chunk.substring(1, chunk.length - 1);
            emojiPath = EmojiMapping.nameToPath[name];
          } else {
            emojiPath = EmojiMapping.getPathForEmoji(chunk);
          }
        }

        if (emojiPath != null && emojiImages.containsKey(emojiPath)) {
          spans.add(pw.WidgetSpan(
            child: pw.Padding(
              padding: const pw.EdgeInsets.symmetric(horizontal: 1),
              child: pw.Image(emojiImages[emojiPath]!, width: 14, height: 14),
            ),
          ));
          continue;
        }

        // 默认基础样式
        PdfColor currentTextColor = baseColor;
        PdfColor? currentBgColor;

        // 手动属性样式叠加
        for (var attr in attributes) {
          if (start >= attr['start'] && end <= attr['end']) {
            if (attr['color'] != null) currentTextColor = PdfColor.fromInt(attr['color']);
            if (attr['backgroundColor'] != null) currentBgColor = PdfColor.fromInt(attr['backgroundColor']);
          }
        }
        spans.add(pw.TextSpan(
          text: chunk,
          style: pw.TextStyle(
            font: font,
            fontSize: 10.5,
            color: currentTextColor,
            background: currentBgColor != null ? pw.BoxDecoration(color: currentBgColor) : null,
            fontWeight: pw.FontWeight.normal,
            decoration: pw.TextDecoration.none,
            decorationColor: currentTextColor,
            height: 1.25,
          ),
        ));
    }

    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 6),
      child: pw.RichText(text: pw.TextSpan(children: spans)),
    );
  }

  /// 渲染成就/奖励块
  static pw.Widget _buildRewardBlock(Map<String, dynamic> block, pw.Font font, _PdfThemeColors colors) {
    try {
      final name = block['name']?.toString() ?? "成就空间";
      return pw.Container(
        padding: const pw.EdgeInsets.all(12),
        margin: const pw.EdgeInsets.only(bottom: 8),
        decoration: pw.BoxDecoration(
          color: const PdfColor.fromInt(0xFFF9F6F0),
          borderRadius: const pw.BorderRadius.all(pw.Radius.circular(12)),
          border: pw.Border.all(color: colors.divider, width: 0.5),
        ),
        child: pw.Row(
          mainAxisSize: pw.MainAxisSize.min,
          children: [
            pw.Text("你在今天遇见了", style: pw.TextStyle(font: font, fontSize: 9, color: colors.secondaryText)),
            pw.SizedBox(width: 6),
            pw.Text(name, style: pw.TextStyle(font: font, fontSize: 10, fontWeight: pw.FontWeight.bold, color: const PdfColor.fromInt(0xFFD4A373))),
          ],
        ),
      );
    } catch (e) {
      return pw.SizedBox();
    }
  }

  static int _countUniqueDays(List<DiaryEntry> entries) {
    final Set<String> days = {};
    for (var e in entries) {
      days.add("${e.dateTime.year}-${e.dateTime.month}-${e.dateTime.day}");
    }
    return days.length;
  }

  static pw.Widget _buildMoodTagCapsule(DiaryEntry entry, Map<int, pw.ImageProvider> icons, pw.Font font, PdfThemeType theme) {
    final moodIdx = entry.moodIndex.clamp(0, kMoods.length - 1);
    final hasTag = entry.tag != null && entry.tag!.isNotEmpty;
    final labelText = hasTag ? "#${_cleanString(entry.tag!)}" : kMoods[moodIdx].label;
    
    PdfColor bgColor;
    PdfColor textColor;

    if (theme == PdfThemeType.minimalist) {
      bgColor = const PdfColor.fromInt(0xFFF5F5F5);
      textColor = const PdfColor.fromInt(0xFF424242);
    } else {
      if (hasTag) {
        bgColor = const PdfColor.fromInt(0xFFF4F2EE);
        textColor = const PdfColor.fromInt(0xFFC4B69E);
      } else {
        final bgColors = [0xFFFEF0F0, 0xFFEEFBEE, 0xFFF3EEFB, 0xFFFFF3E4, 0xFFEEF7FB, 0xFFFEE4E4, 0xFFE4EEFB, 0xFFFFFBE4];
        final textColors = [0xFFFFA4A4, 0xFFA4E4A4, 0xFFC4A4E4, 0xFFFFC484, 0xFFA4D4E4, 0xFFFF8484, 0xFF84A4E4, 0xFFFFE484];
        bgColor = PdfColor.fromInt(bgColors[moodIdx]);
        textColor = PdfColor.fromInt(textColors[moodIdx]);
      }
    }

    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: pw.BoxDecoration(
        color: bgColor,
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(10)),
      ),
      child: pw.Row(
        mainAxisSize: pw.MainAxisSize.min,
        children: [
          if (!hasTag && icons.containsKey(moodIdx)) ...[
             pw.Image(icons[moodIdx]!, width: 12, height: 12),
             pw.SizedBox(width: 4),
          ],
          pw.Text(
            labelText,
            style: pw.TextStyle(
              font: font,
              fontSize: 9,
              fontWeight: pw.FontWeight.bold,
              color: textColor,
            ),
          ),
        ],
      ),
    );
  }

  static pw.Widget _buildImageBlock(String path) {
    if (kIsWeb) return pw.SizedBox(height: 0, width: 0);
    try {
      final file = File(path);
      if (file.existsSync()) {
        final image = pw.MemoryImage(file.readAsBytesSync());
        return pw.ConstrainedBox(
            constraints: const pw.BoxConstraints(maxHeight: 120, maxWidth: 120),
            child: pw.Image(image, fit: pw.BoxFit.contain),
        );
      }
    } catch (e) {
      // 忽略
    }
    return pw.SizedBox(height: 0, width: 0);
  }

  static String _cleanString(String text, {String fallback = ""}) {
    final regex = RegExp(r'[^\n\r\u0020-\u007E\u4e00-\u9fa5\u3000-\u303F\uff00-\uffef]');
    final cleaned = text.replaceAll(regex, '').trim();
    return cleaned.isEmpty ? fallback : cleaned;
  }

  static pw.Widget _buildPdfReplies(DiaryEntry entry, pw.Font font, _PdfThemeColors colors, Map<String, pw.ImageProvider> emojiImages) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.SizedBox(height: 8),
        for (var reply in entry.replies)
          pw.Container(
            margin: const pw.EdgeInsets.only(bottom: 6),
            padding: const pw.EdgeInsets.only(left: 10),
            decoration: pw.BoxDecoration(
              border: pw.Border(left: pw.BorderSide(color: colors.divider, width: 2)),
            ),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Wrap(
                  crossAxisAlignment: pw.WrapCrossAlignment.center,
                  children: EmojiMapping.parseText(reply.content).map((chunk) {
                    if (chunk.isEmoji && emojiImages.containsKey(chunk.emojiPath)) {
                      return pw.Padding(
                        padding: const pw.EdgeInsets.symmetric(horizontal: 1),
                        child: pw.Image(emojiImages[chunk.emojiPath!]!, width: 12, height: 12),
                      );
                    }
                    return pw.Text(
                      chunk.text,
                      style: pw.TextStyle(
                        font: font,
                        fontSize: 9.5,
                        color: colors.secondaryText,
                        height: 1.2,
                      ),
                    );
                  }).toList(),
                ),
                pw.SizedBox(height: 2),
                pw.Text(
                  "${reply.dateTime.year}/${reply.dateTime.month}/${reply.dateTime.day} ${reply.dateTime.hour.toString().padLeft(2, '0')}:${reply.dateTime.minute.toString().padLeft(2, '0')}",
                  style: pw.TextStyle(font: font, fontSize: 7, color: colors.tertiaryText),
                ),
              ],
            ),
          ),
      ],
    );
  }
}
