import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:island_diary/features/record/domain/models/diary_book.dart';
import 'package:island_diary/features/record/domain/models/diary_entry.dart';
import 'package:island_diary/shared/widgets/diary_entry/utils/diary_utils.dart';

class DiaryBookExportHelper {
  static String getFallbackTitle(DiaryEntry entry) {
    if (entry.content.trim().isEmpty) return '无标题';
    String plain = entry.content.replaceAll(RegExp(r'[#*`_\-–—]'), '').trim();
    plain = plain.replaceAll(RegExp(r'mood(_icon)?:\s*[^\n,;]+[,;]?'), '').trim();
    final lines = plain.split('\n').map((l) => l.trim()).where((l) => l.isNotEmpty).toList();
    if (lines.isEmpty) return '无标题';
    return lines.first;
  }

  static PdfColor _toPdfColor(Color c) {
    return PdfColor.fromInt(c.value);
  }

  static pw.TextAlign _toPdfAlign(TextAlign align) {
    switch (align) {
      case TextAlign.center:
        return pw.TextAlign.center;
      case TextAlign.right:
        return pw.TextAlign.right;
      default:
        return pw.TextAlign.left;
    }
  }

  static List<pw.Widget> buildDiaryBlocksPdf({
    required DiaryEntry entry,
    required List<DiaryEntry> allDiaries,
    required List<String> bodyLayout,
    required pw.Font ttf,
    required PdfColor textColor,
    required double titleFontSize,
    required TextAlign titleAlignment,
    required double metaFontSize,
    required double dividerThickness,
    required double dividerPadding,
    required double imageHeight,
    required double bodyFontSize,
    required double bodyLineSpacing,
  }) {
    final List<pw.Widget> widgets = [];

    for (var elementKey in bodyLayout) {
      if (elementKey == 'title') {
        final titleStr = (entry.title != null && entry.title!.trim().isNotEmpty)
            ? entry.title!.trim()
            : getFallbackTitle(entry);
        widgets.add(
          pw.Padding(
            padding: const pw.EdgeInsets.symmetric(vertical: 4),
            child: pw.Text(
              '第 ${allDiaries.indexOf(entry) + 1} 章  $titleStr',
              style: pw.TextStyle(
                font: ttf,
                fontSize: titleFontSize,
                fontWeight: pw.FontWeight.bold,
                color: textColor,
              ),
              textAlign: _toPdfAlign(titleAlignment),
            ),
          ),
        );
      } else if (elementKey == 'meta') {
        final dateStr = DateFormat('yyyy-MM-dd HH:mm').format(entry.dateTime);
        widgets.add(
          pw.Padding(
            padding: const pw.EdgeInsets.symmetric(vertical: 4),
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text(
                  dateStr,
                  style: pw.TextStyle(font: ttf, fontSize: metaFontSize, color: PdfColors.grey600),
                ),
                pw.Text(
                  '${entry.weather ?? ""}  ${entry.location ?? ""}',
                  style: pw.TextStyle(font: ttf, fontSize: metaFontSize, color: PdfColors.grey600),
                ),
              ],
            ),
          ),
        );
      } else if (elementKey == 'divider') {
        widgets.add(
          pw.Padding(
            padding: pw.EdgeInsets.symmetric(vertical: dividerPadding),
            child: pw.Divider(thickness: dividerThickness, color: PdfColors.brown100),
          ),
        );
      } else if (elementKey == 'images') {
        for (var block in entry.blocks) {
          if (block['type'] == 'image') {
            final path = block['path']?.toString() ?? '';
            if (path.isNotEmpty) {
              try {
                final file = File(path);
                if (file.existsSync()) {
                  final imageBytes = file.readAsBytesSync();
                  widgets.add(
                    pw.Padding(
                      padding: const pw.EdgeInsets.symmetric(vertical: 8),
                      child: pw.Center(
                        child: pw.Image(
                          pw.MemoryImage(imageBytes),
                          height: imageHeight,
                          fit: pw.BoxFit.contain,
                        ),
                      ),
                    ),
                  );
                }
              } catch (_) {}
            }
          }
        }
      } else if (elementKey == 'text') {
        final List<String> textBlocks = [];
        if (entry.blocks.isEmpty) {
          textBlocks.add(entry.content);
        } else {
          for (var block in entry.blocks) {
            if (block['type'] == 'text') {
              final content = block['content'] ?? '';
              if (content.toString().trim().isNotEmpty) {
                textBlocks.add(content.toString());
              }
            }
          }
        }
        for (var text in textBlocks) {
          widgets.add(
            pw.Padding(
              padding: const pw.EdgeInsets.symmetric(vertical: 4),
              child: pw.Text(
                text,
                style: pw.TextStyle(
                  font: ttf,
                  fontSize: bodyFontSize,
                  lineSpacing: bodyLineSpacing,
                  color: textColor,
                ),
              ),
            ),
          );
        }
      }
    }

    return widgets;
  }

  static Future<pw.Document> generatePdf({
    required DiaryBook book,
    required List<DiaryEntry> diaries,
    required List<String> coverLayout,
    required List<String> bodyLayout,
    required bool includeTOC,
    required bool useOriginalPaperTheme,
    required bool showMeta,
    required double titleFontSize,
    required TextAlign titleAlignment,
    required double metaFontSize,
    required double dividerThickness,
    required double dividerPadding,
    required double imageHeight,
    required double bodyFontSize,
    required double bodyLineSpacing,
  }) async {
    final pdf = pw.Document();
    final fontData = await rootBundle.load("assets/fonts/LXGWWenKai-Regular.ttf");
    final ttf = pw.Font.ttf(fontData);

    final pdfTheme = pw.ThemeData.withFont(
      base: ttf,
      bold: ttf,
      italic: ttf,
      boldItalic: ttf,
    );

    // 1. 封面页
    if (coverLayout.isNotEmpty) {
      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          theme: pdfTheme,
          build: (pw.Context context) {
            final List<pw.Widget> coverWidgets = [];
            for (var key in coverLayout) {
              if (key == 'title') {
                coverWidgets.add(
                  pw.Text(
                    book.name,
                    style: pw.TextStyle(
                      fontSize: 32,
                      fontWeight: pw.FontWeight.bold,
                      color: PdfColors.brown800,
                    ),
                    textAlign: pw.TextAlign.center,
                  ),
                );
                coverWidgets.add(pw.SizedBox(height: 16));
              } else if (key == 'description' && book.description.isNotEmpty) {
                coverWidgets.add(
                  pw.Text(
                    book.description,
                    style: const pw.TextStyle(fontSize: 14, color: PdfColors.grey700),
                    textAlign: pw.TextAlign.center,
                  ),
                );
                coverWidgets.add(pw.SizedBox(height: 24));
              } else if (key == 'divider') {
                coverWidgets.add(
                  pw.Padding(
                    padding: const pw.EdgeInsets.symmetric(vertical: 16),
                    child: pw.Divider(color: PdfColors.brown200, thickness: 1.5),
                  ),
                );
              } else if (key == 'stats') {
                coverWidgets.add(
                  pw.Column(
                    children: [
                      pw.Text(
                        '共记录 ${diaries.length} 篇日记',
                        style: const pw.TextStyle(fontSize: 12, color: PdfColors.grey600),
                      ),
                      pw.Text(
                        '自 ${DateFormat('yyyy-MM-dd').format(book.createdAt)} 启程',
                        style: const pw.TextStyle(fontSize: 12, color: PdfColors.grey600),
                      ),
                    ],
                  ),
                );
              }
            }

            return pw.Container(
              padding: const pw.EdgeInsets.all(40),
              decoration: pw.BoxDecoration(
                border: pw.Border.all(color: PdfColors.brown200, width: 2),
              ),
              child: pw.Center(
                child: pw.Column(
                  mainAxisAlignment: pw.MainAxisAlignment.center,
                  children: coverWidgets,
                ),
              ),
            );
          },
        ),
      );
    }

    // 2. 目录页
    if (includeTOC) {
      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          theme: pdfTheme,
          build: (pw.Context context) {
            return pw.Padding(
              padding: const pw.EdgeInsets.symmetric(horizontal: 40, vertical: 30),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    '目录',
                    style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold),
                  ),
                  pw.SizedBox(height: 10),
                  pw.Divider(),
                  pw.SizedBox(height: 20),
                  ...diaries.asMap().entries.map((entryItem) {
                    final idx = entryItem.key + 1;
                    final entry = entryItem.value;
                    final titleStr = (entry.title != null && entry.title!.trim().isNotEmpty)
                        ? entry.title!.trim()
                        : getFallbackTitle(entry);
                    final dateStr = DateFormat('yyyy-MM-dd').format(entry.dateTime);

                    return pw.Padding(
                      padding: const pw.EdgeInsets.symmetric(vertical: 6),
                      child: pw.Row(
                        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                        children: [
                          pw.Text('第 $idx 章   $titleStr', style: const pw.TextStyle(fontSize: 12)),
                          pw.Text(dateStr, style: const pw.TextStyle(fontSize: 11, color: PdfColors.grey600)),
                        ],
                      ),
                    );
                  }),
                ],
              ),
            );
          },
        ),
      );
    }

    // 3. 正文页
    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        theme: pdfTheme,
        build: (pw.Context context) {
          final List<pw.Widget> widgets = [];
          for (var entry in diaries) {
            final bool hasPaperTheme = useOriginalPaperTheme;
            final paperColor = hasPaperTheme
                ? DiaryUtils.getPaperBaseColor(entry.paperStyle, false)
                : Colors.transparent;
            final inkColor = hasPaperTheme
                ? DiaryUtils.getInkColor(entry.paperStyle, false)
                : Colors.black87;

            final cardDecoration = hasPaperTheme
                ? pw.BoxDecoration(
                    color: _toPdfColor(paperColor),
                    borderRadius: const pw.BorderRadius.all(pw.Radius.circular(12)),
                  )
                : null;

            widgets.add(
              pw.Container(
                margin: const pw.EdgeInsets.only(bottom: 28),
                padding: hasPaperTheme ? const pw.EdgeInsets.all(18) : pw.EdgeInsets.zero,
                decoration: cardDecoration,
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: buildDiaryBlocksPdf(
                    entry: entry,
                    allDiaries: diaries,
                    bodyLayout: bodyLayout,
                    ttf: ttf,
                    textColor: _toPdfColor(inkColor),
                    titleFontSize: titleFontSize,
                    titleAlignment: titleAlignment,
                    metaFontSize: metaFontSize,
                    dividerThickness: dividerThickness,
                    dividerPadding: dividerPadding,
                    imageHeight: imageHeight,
                    bodyFontSize: bodyFontSize,
                    bodyLineSpacing: bodyLineSpacing,
                  ),
                ),
              ),
            );
          }
          return widgets;
        },
      ),
    );

    return pdf;
  }

  static String generateTxtContent({
    required DiaryBook book,
    required List<DiaryEntry> diaries,
    required List<String> coverLayout,
    required List<String> bodyLayout,
    required bool includeTOC,
    required bool showMeta,
  }) {
    final buffer = StringBuffer();
    if (coverLayout.isNotEmpty) {
      for (var key in coverLayout) {
        if (key == 'title') {
          buffer.writeln('========================================');
          buffer.writeln(book.name.toUpperCase());
          buffer.writeln('========================================\n');
        } else if (key == 'description' && book.description.isNotEmpty) {
          buffer.writeln(book.description);
          buffer.writeln();
        } else if (key == 'divider') {
          buffer.writeln('----------------------------------------\n');
        } else if (key == 'stats') {
          buffer.writeln('共记录 ${diaries.length} 篇日记');
          buffer.writeln('创建时间: ${DateFormat('yyyy-MM-dd').format(book.createdAt)}');
          buffer.writeln();
        }
      }
      buffer.writeln('\n\n');
    }

    if (includeTOC) {
      buffer.writeln('目录');
      buffer.writeln('----------------------------------------');
      for (int i = 0; i < diaries.length; i++) {
        final entry = diaries[i];
        final titleStr = (entry.title != null && entry.title!.trim().isNotEmpty)
            ? entry.title!.trim()
            : getFallbackTitle(entry);
        final dateStr = DateFormat('yyyy-MM-dd').format(entry.dateTime);
        buffer.writeln('第 ${i + 1} 章  $titleStr  ......  $dateStr');
      }
      buffer.writeln('\n\n========================================\n\n');
    }

    for (int i = 0; i < diaries.length; i++) {
      final entry = diaries[i];
      for (var elementKey in bodyLayout) {
        if (elementKey == 'title') {
          final titleStr = (entry.title != null && entry.title!.trim().isNotEmpty)
              ? entry.title!.trim()
              : getFallbackTitle(entry);
          buffer.writeln('第 ${i + 1} 章  $titleStr');
        } else if (elementKey == 'meta') {
          final dateStr = DateFormat('yyyy-MM-dd HH:mm').format(entry.dateTime);
          buffer.write(dateStr);
          if (showMeta) {
            buffer.write('  天气: ${entry.weather ?? "无"}  地点: ${entry.location ?? "无"}');
          }
          buffer.writeln();
        } else if (elementKey == 'divider') {
          buffer.writeln('------------------');
        } else if (elementKey == 'images') {
          for (var block in entry.blocks) {
            if (block['type'] == 'image') {
              final path = block['path']?.toString() ?? '';
              if (path.isNotEmpty) {
                buffer.writeln('[图片: $path]');
              }
            }
          }
        } else if (elementKey == 'text') {
          final List<String> textBlocks = [];
          if (entry.blocks.isEmpty) {
            textBlocks.add(entry.content);
          } else {
            for (var block in entry.blocks) {
              if (block['type'] == 'text') {
                final content = block['content'] ?? '';
                if (content.toString().trim().isNotEmpty) {
                  textBlocks.add(content.toString());
                }
              }
            }
          }
          for (var text in textBlocks) {
            buffer.writeln(text);
          }
        }
      }
      buffer.writeln('\n\n');
    }
    return buffer.toString();
  }

  static String generateMarkdownContent({
    required DiaryBook book,
    required List<DiaryEntry> diaries,
    required List<String> coverLayout,
    required List<String> bodyLayout,
    required bool includeTOC,
    required bool showMeta,
  }) {
    final buffer = StringBuffer();
    if (coverLayout.isNotEmpty) {
      for (var key in coverLayout) {
        if (key == 'title') {
          buffer.writeln('# ${book.name}\n');
        } else if (key == 'description' && book.description.isNotEmpty) {
          buffer.writeln('> ${book.description}\n');
        } else if (key == 'divider') {
          buffer.writeln('---\n');
        } else if (key == 'stats') {
          buffer.writeln('* 共记录 ${diaries.length} 篇日记');
          buffer.writeln('* 创建时间: ${DateFormat('yyyy-MM-dd').format(book.createdAt)}\n');
        }
      }
      buffer.writeln('\n');
    }

    if (includeTOC) {
      buffer.writeln('## 目录\n');
      for (int i = 0; i < diaries.length; i++) {
        final entry = diaries[i];
        final titleStr = (entry.title != null && entry.title!.trim().isNotEmpty)
            ? entry.title!.trim()
            : getFallbackTitle(entry);
        buffer.writeln('- [第 ${i + 1} 章  $titleStr](#第-${i + 1}-章--${Uri.encodeComponent(titleStr)})');
      }
      buffer.writeln('\n---\n');
    }

    for (int i = 0; i < diaries.length; i++) {
      final entry = diaries[i];
      for (var elementKey in bodyLayout) {
        if (elementKey == 'title') {
          final titleStr = (entry.title != null && entry.title!.trim().isNotEmpty)
              ? entry.title!.trim()
              : getFallbackTitle(entry);
          buffer.writeln('## 第 ${i + 1} 章  $titleStr\n');
        } else if (elementKey == 'meta') {
          final dateStr = DateFormat('yyyy-MM-dd HH:mm').format(entry.dateTime);
          buffer.write('*时间: $dateStr*');
          if (showMeta) {
            buffer.write(' | *天气: ${entry.weather ?? "无"}* | *地点: ${entry.location ?? "无"}*');
          }
          buffer.writeln('\n');
        } else if (elementKey == 'divider') {
          buffer.writeln('---\n');
        } else if (elementKey == 'images') {
          for (var block in entry.blocks) {
            if (block['type'] == 'image') {
              final path = block['path']?.toString() ?? '';
              if (path.isNotEmpty) {
                buffer.writeln('![插图](file://$path)\n');
              }
            }
          }
        } else if (elementKey == 'text') {
          final List<String> textBlocks = [];
          if (entry.blocks.isEmpty) {
            textBlocks.add(entry.content);
          } else {
            for (var block in entry.blocks) {
              if (block['type'] == 'text') {
                final content = block['content'] ?? '';
                if (content.toString().trim().isNotEmpty) {
                  textBlocks.add(content.toString());
                }
              }
            }
          }
          for (var text in textBlocks) {
            buffer.writeln('$text\n');
          }
        }
      }
      buffer.writeln('\n');
    }
    return buffer.toString();
  }
}
