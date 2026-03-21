import 'package:flutter/services.dart';
import 'dart:io';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:island_diary/features/record/domain/models/diary_entry.dart';
import 'package:island_diary/shared/widgets/mood_picker/config/mood_config.dart';
import 'package:island_diary/shared/widgets/diary_entry/utils/emoji_mapping.dart';

class ExportService {
  static Future<void> exportToPdf(
      List<DiaryEntry> entries, String title, String userName) async {
    final pdf = pw.Document();

    try {
      // 1. 并行加载核心字体与基础资源 (优化点：减少线性等待)
      print("PDF CORE: Parallel loading started...");
      final fontFuture = rootBundle.load("assets/fonts/LXGWWenKai-Regular.ttf");
      final emojiFontFuture = rootBundle.load("assets/fonts/nishiki-teki.ttf");
      
      final results = await Future.wait([fontFuture, emojiFontFuture]);
      final ttf = pw.Font.ttf(results[0]);
      final emojiFont = pw.Font.ttf(results[1]);

      // 2. 并行加载心情图标
      print("PDF CORE: Preloading mood icons...");
      final Map<int, pw.ImageProvider> moodIcons = {};
      final List<Future<void>> moodFutures = [];
      
      for (var i = 0; i < kMoods.length; i++) {
        final idx = i;
        moodFutures.add(() async {
          try {
            final iconData = await rootBundle.load(kMoods[idx].iconPath!);
            moodIcons[idx] = pw.MemoryImage(iconData.buffer.asUint8List());
          } catch (e) {
             print("PDF CORE: Icon $idx load error: $e");
          }
        }());
      }

      // 3. 预分析并并行加载表情图片
      print("PDF CORE: Preloading emoji images...");
      final Set<String> usedEmojiPaths = {};
      for (var entry in entries) {
        final chunks = EmojiMapping.parseText(entry.content);
        for (var chunk in chunks) {
          if (chunk.isEmoji) {
            usedEmojiPaths.add(chunk.emojiPath!);
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
            print("PDF CORE: Emoji load error ($currentPath): $e");
          }
        }());
      }

      // 等待所有异步资源完成
      await Future.wait([...moodFutures, ...emojiFutures]);
      print("PDF CORE: All assets ready.");

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
      final finalUserName = _cleanString(userName, fallback: "岛屿居民");

      // 5. 生成 MultiPage 内容
      print("PDF CORE: Generating MultiPage layout...");
      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          theme: pw.ThemeData.withFont(
            base: ttf,
            fontFallback: [emojiFont],
          ),
          header: (context) => _buildHeader(title, ttf, finalUserName, emojiFont: emojiFont, pageNumber: context.pageNumber),
          footer: (context) => _buildFooter(context.pageNumber, context.pagesCount, ttf, randomQuote),
          build: (context) => [
             _buildStats(entries, ttf, randomQuote),
             pw.Padding(
               padding: const pw.EdgeInsets.symmetric(vertical: 20),
               child: pw.Divider(height: 1, color: PdfColors.brown50, thickness: 0.5),
             ),
             for (var e in sortedEntries) ..._buildEntryWidgets(e, moodIcons, emojiImages, ttf),
          ],
        ),
      );

      // 6. 最终导出并拉起预览
      print("PDF CORE: Finalizing layout...");
      final bytes = await pdf.save();
      
      await Printing.layoutPdf(
        onLayout: (PdfPageFormat format) async => bytes,
        name: 'isle_diary_book_${DateTime.now().millisecondsSinceEpoch}.pdf',
      );
    } catch (e, stack) {
      print("PDF CORE ERROR: $e\n$stack");
      rethrow;
    }
  }

  static pw.Widget _buildHeader(String title, pw.Font font, String userName, {pw.Font? emojiFont, required int pageNumber}) {
    if (pageNumber > 1) {
      return pw.Container(
        margin: const pw.EdgeInsets.only(bottom: 15),
        padding: const pw.EdgeInsets.only(bottom: 5),
        decoration: const pw.BoxDecoration(
          border: pw.Border(bottom: pw.BorderSide(color: PdfColors.brown50, width: 0.5))
        ),
        child: pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Text(title, style: pw.TextStyle(font: font, fontSize: 10, color: PdfColors.brown400)),
            pw.Text('第 $pageNumber 页', style: pw.TextStyle(font: font, fontSize: 8, color: PdfColors.brown200)),
          ],
        ),
      );
    }

    return pw.Container(
      padding: const pw.EdgeInsets.only(bottom: 10),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(title, style: pw.TextStyle(font: font, fontSize: 18, color: PdfColors.brown900)),
          pw.Text(
            '笔名：$userName', 
            style: pw.TextStyle(
              font: font, 
              fontFallback: emojiFont != null ? [emojiFont] : [],
              fontSize: 10, 
              color: PdfColors.brown400
            )
          ),
        ],
      ),
    );
  }

  static pw.Widget _buildFooter(int pageNumber, int totalPages, pw.Font font, String quote) {
    return pw.Container(
      alignment: pw.Alignment.centerRight,
      margin: const pw.EdgeInsets.only(top: 20),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.end, // 关键修正点：pw.CrossAxisAlignment.end
        children: [
          pw.Text(
            quote,
            style: pw.TextStyle(font: font, fontSize: 10, color: PdfColors.brown400),
          ),
          pw.SizedBox(height: 5),
          pw.Text(
            '第 $pageNumber / $totalPages 页 · 岛屿日记',
            style: pw.TextStyle(font: font, fontSize: 10, color: PdfColors.brown300),
          ),
        ],
      ),
    );
  }

  static pw.Widget _buildStats(List<DiaryEntry> entries, pw.Font font, String quote) {
    final days = _countUniqueDays(entries);
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Row(
           children: [
             _buildStatItem("记录时光", "$days天", font),
             pw.SizedBox(width: 40),
             _buildStatItem("岛屿累计", "${entries.length}篇", font),
           ]
        ),
        pw.SizedBox(height: 10),
        pw.Text(quote, style: pw.TextStyle(font: font, fontSize: 11, color: PdfColors.brown500)),
        pw.SizedBox(height: 10),
      ],
    );
  }

  static pw.Widget _buildStatItem(String label, String value, pw.Font font) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(value, style: pw.TextStyle(font: font, fontSize: 18, fontWeight: pw.FontWeight.bold, color: PdfColors.brown400)),
        pw.Text(label, style: pw.TextStyle(font: font, fontSize: 10, color: PdfColors.grey400)),
      ],
    );
  }

  static List<pw.Widget> _buildEntryWidgets(DiaryEntry entry, Map<int, pw.ImageProvider> icons, Map<String, pw.ImageProvider> emojiImages, pw.Font font) {
    final weekdays = ["", "周一", "周二", "周三", "周四", "周五", "周六", "周日"];
    final dateStr = "${entry.dateTime.year}/${entry.dateTime.month}/${entry.dateTime.day}";
    final weekdayStr = weekdays[entry.dateTime.weekday];
    final timeStr = "${entry.dateTime.hour.toString().padLeft(2, '0')}:${entry.dateTime.minute.toString().padLeft(2, '0')}";

    return [
      pw.SizedBox(height: 8),
      pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        crossAxisAlignment: pw.CrossAxisAlignment.center,
        children: [
          pw.Row(
            children: [
              pw.Text(dateStr, style: pw.TextStyle(font: font, fontSize: 10, fontWeight: pw.FontWeight.bold, color: PdfColors.brown700)),
              pw.SizedBox(width: 8),
              pw.Text(weekdayStr, style: pw.TextStyle(font: font, fontSize: 8, color: PdfColors.brown400)),
              pw.SizedBox(width: 8),
              pw.Text(timeStr, style: pw.TextStyle(font: font, fontSize: 8, color: PdfColors.brown300)),
            ],
          ),
          _buildMoodTagCapsule(entry, icons, font),
        ],
      ),
      pw.SizedBox(height: 3),

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
                    color: PdfColors.brown900,
                    height: 1.25,
                  ),
                );
              }).toList(),
            ),
          )
        else
          pw.SizedBox(height: 6),

      if (entry.blocks.any((b) => b['type'] == 'image')) ...[
        pw.SizedBox(height: 8),
        pw.Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            for (var block in entry.blocks)
              if (block['type'] == 'image')
                _buildImageBlock(block['path'] as String),
          ],
        ),
      ],

      pw.SizedBox(height: 12),
      pw.Divider(height: 1, color: PdfColors.brown50, thickness: 0.5),
    ];
  }

  static int _countUniqueDays(List<DiaryEntry> entries) {
    final Set<String> days = {};
    for (var e in entries) {
      days.add("${e.dateTime.year}-${e.dateTime.month}-${e.dateTime.day}");
    }
    return days.length;
  }

  static pw.Widget _buildMoodTagCapsule(DiaryEntry entry, Map<int, pw.ImageProvider> icons, pw.Font font) {
    final moodIdx = entry.moodIndex.clamp(0, kMoods.length - 1);
    final hasTag = entry.tag != null && entry.tag!.isNotEmpty;
    final labelText = hasTag ? "#${_cleanString(entry.tag!)}" : kMoods[moodIdx].label;
    
    PdfColor bgColor;
    PdfColor textColor;

    if (hasTag) {
      bgColor = const PdfColor.fromInt(0xFFF4F2EE);
      textColor = const PdfColor.fromInt(0xFFC4B69E);
    } else {
      final bgColors = [0xFFFEF0F0, 0xFFEEFBEE, 0xFFF3EEFB, 0xFFFFF3E4, 0xFFEEF7FB, 0xFFFEE4E4, 0xFFE4EEFB, 0xFFFFFBE4];
      final textColors = [0xFFFFA4A4, 0xFFA4E4A4, 0xFFC4A4E4, 0xFFFFC484, 0xFFA4D4E4, 0xFFFF8484, 0xFF84A4E4, 0xFFFFE484];
      bgColor = PdfColor.fromInt(bgColors[moodIdx]);
      textColor = PdfColor.fromInt(textColors[moodIdx]);
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
}
