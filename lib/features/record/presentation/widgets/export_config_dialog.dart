import 'dart:typed_data';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:printing/printing.dart';
import 'package:pdf/pdf.dart';
import 'package:share_plus/share_plus.dart';
import 'package:island_diary/core/state/user_state.dart';
import 'package:island_diary/features/record/domain/models/diary_entry.dart';
import 'package:island_diary/shared/services/export_service.dart';
import 'package:island_diary/shared/widgets/diary_entry/utils/diary_utils.dart';
import 'package:island_diary/shared/widgets/mood_picker/config/mood_config.dart';

/// 导出设置弹窗：提供时间范围过滤与 PDF 实时预览
class ExportConfigDialog extends StatefulWidget {
  final List<DiaryEntry> allDiaries;

  const ExportConfigDialog({super.key, required this.allDiaries});

  @override
  State<ExportConfigDialog> createState() => _ExportConfigDialogState();
}

class _ExportConfigDialogState extends State<ExportConfigDialog> {
  int _selectedFilterIdx = 0; // 0:全部, 1:最近30天, 2:本月, 3:今年
  int? _selectedMoodIdx; // null:全部心情, 其他代表具体的 moodIndex
  PdfThemeType _selectedTheme = PdfThemeType.classic;
  late List<DiaryEntry> _filteredDiaries;
  bool _isGenerating = false;
  int _previewRevision = 0;

  @override
  void initState() {
    super.initState();
    _filteredDiaries = List.from(widget.allDiaries);
  }

  void _updateFilter({int? timeIndex, int? moodIndex}) {
    setState(() {
      _previewRevision++;
      if (timeIndex != null) _selectedFilterIdx = timeIndex;
      if (moodIndex != null) {
        _selectedMoodIdx = moodIndex == -1 ? null : moodIndex;
      }

      final now = DateTime.now();

      _filteredDiaries = widget.allDiaries.where((d) {
        // 时间过滤
        if (_selectedFilterIdx == 1) { // 最近30天
          if (now.difference(d.dateTime).inDays > 30) return false;
        } else if (_selectedFilterIdx == 2) { // 本月
          if (d.dateTime.year != now.year || d.dateTime.month != now.month) return false;
        } else if (_selectedFilterIdx == 3) { // 今年
          if (d.dateTime.year != now.year) return false;
        }

        // 心情过滤
        if (_selectedMoodIdx != null) {
          if (d.moodIndex != _selectedMoodIdx) return false;
        }

        return true;
      }).toList();
    });
  }

  Future<void> _handleConfirmExport() async {
    if (_filteredDiaries.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("选定的时间范围内没有日记可以导出哦~")),
      );
      return;
    }

    setState(() => _isGenerating = true);
    final userName = UserState().userName.value.isNotEmpty ? UserState().userName.value : "旅人";
    
    try {
      await ExportService.exportToPdf(_filteredDiaries, "岛屿日记 · 岁月成书", userName, theme: _selectedTheme);
    } catch (e) {
      if (mounted) {
        if (e == 'PRINT_SERVICE_NOT_FOUND') {
          try {
            final bytes = await ExportService.generatePdfBytes(_filteredDiaries, "岛屿日记 · 岁月成书", userName, theme: _selectedTheme);
            if (bytes != null) {
              final fileName = 'isle_diary_book_${DateTime.now().millisecondsSinceEpoch}.pdf';
              final path = await DiaryUtils.saveDataToTempFile(bytes, fileName: fileName);
              if (path != null) {
                await Share.shareXFiles([XFile(path)], text: '这是我的岛屿日记书 ✨');
              }
            }
          } catch (shareError) {
             ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('导出与分享均失败: $shareError'), backgroundColor: Colors.redAccent),
            );
          }
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('导出失败: $e'), backgroundColor: Colors.redAccent),
          );
        }
      }
    } finally {
      if (mounted) {
        setState(() => _isGenerating = false);
        Navigator.pop(context);
      }
    }
  }

  Widget _buildFilterChip(int index, String label, IconData iconData, Color textColor) {
    final isSelected = _selectedFilterIdx == index;
    final isNight = UserState().isNight;
    
    return GestureDetector(
      onTap: () => _updateFilter(timeIndex: index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(right: 12),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected 
              ? const Color(0xFFD4A373) 
              : (isNight ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.04)),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected 
                ? const Color(0xFFD4A373) 
                : (isNight ? Colors.white10 : Colors.black.withOpacity(0.05)),
          ),
          boxShadow: isSelected ? [
            BoxShadow(
              color: const Color(0xFFD4A373).withOpacity(0.3),
              blurRadius: 8,
              offset: const Offset(0, 2),
            )
          ] : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              iconData,
              size: 16,
              color: isSelected ? Colors.white : textColor.withOpacity(0.5),
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                fontFamily: 'LXGWWenKai',
                color: isSelected ? Colors.white : textColor.withOpacity(0.8),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isNight = UserState().isNight;
    final bgColor = isNight ? const Color(0xFF1E1E1E) : const Color(0xFFFDF9F0);
    final textColor = isNight ? Colors.white : Colors.black87;

    return Dialog(
      backgroundColor: bgColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 32),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 20, 12, 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "导出日记本",
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'LXGWWenKai',
                    color: textColor,
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.close, color: textColor.withOpacity(0.5)),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),
          
          // Date Filter Action
          SizedBox(
            width: double.infinity,
            height: 38,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Row(
                children: [
                  _buildFilterChip(0, "全部时光", Icons.all_inclusive_rounded, textColor),
                  _buildFilterChip(1, "最近30天", Icons.timelapse_rounded, textColor),
                  _buildFilterChip(2, "本月记录", Icons.calendar_month_rounded, textColor),
                  _buildFilterChip(3, "今年拾起", Icons.auto_awesome_rounded, textColor),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          
          // Mood Filter Action
          SizedBox(
            width: double.infinity,
            height: 38,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Row(
                children: [
                  _buildMoodChip(-1, "全部心情", textColor),
                  for (int i = 0; i < kMoods.length; i++)
                    _buildMoodChip(i, kMoods[i].label, textColor, iconPath: kMoods[i].iconPath),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Theme Filter Action
          SizedBox(
            width: double.infinity,
            height: 38,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Row(
                children: [
                  _buildThemeChip(PdfThemeType.classic, "经典手账", Icons.menu_book_rounded, textColor),
                  _buildThemeChip(PdfThemeType.minimalist, "极简纯白", Icons.article_rounded, textColor),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Row(
              children: [
                Text(
                  "共 ${_filteredDiaries.length} 篇日记",
                  style: TextStyle(
                    fontSize: 13,
                    fontFamily: 'LXGWWenKai',
                    color: textColor.withOpacity(0.6),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // PDF Preview Area
          Expanded(
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 24),
              decoration: BoxDecoration(
                color: isNight ? Colors.black26 : Colors.black.withOpacity(0.02),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isNight ? Colors.white10 : Colors.black.withOpacity(0.05),
                ),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: _filteredDiaries.isEmpty 
                  ? Center(
                      child: Text(
                        "预览为空",
                        style: TextStyle(color: textColor.withOpacity(0.4), fontFamily: 'LXGWWenKai'),
                      ),
                    )
                  : PdfPreview(
                      key: ValueKey(_previewRevision),
                      build: (format) async {
                        // 强制让出主线程一瞬间，确保 UI 先刷新出 Loading 动画
                        await Future.delayed(const Duration(milliseconds: 100));
                        
                        final userName = UserState().userName.value.isNotEmpty ? UserState().userName.value : "旅人";
                        final bytes = await ExportService.generatePdfBytes(_filteredDiaries, "岛屿日记 · 岁月成书", userName, theme: _selectedTheme);
                        return bytes ?? Uint8List(0);
                      },
                      canChangePageFormat: false,
                      canChangeOrientation: false,
                      canDebug: false,
                      allowPrinting: false,  // 隐藏自带的打印按钮
                      allowSharing: false,   // 隐藏自带的分享按钮
                      useActions: false,     // 完全隐藏自带操作栏，由我们自己的按钮接管
                      initialPageFormat: PdfPageFormat.a4,
                      pdfFileName: "diary_preview.pdf",
                      loadingWidget: Center(
                        child: CircularProgressIndicator(color: const Color(0xFFD4A373)),
                      ),
                      scrollViewDecoration: BoxDecoration(
                        color: isNight ? Colors.black26 : Colors.black.withOpacity(0.02),
                      ),
                    ),
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Confirm Button
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
            child: SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: (_isGenerating || _filteredDiaries.isEmpty) ? null : _handleConfirmExport,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFD4A373),
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  disabledBackgroundColor: const Color(0xFFD4A373).withOpacity(0.4),
                ),
                child: _isGenerating
                  ? const SizedBox(
                      width: 20, 
                      height: 20, 
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)
                    )
                  : const Text(
                      "确认并导出 PDF", 
                      style: TextStyle(
                        fontSize: 16, 
                        fontWeight: FontWeight.bold,
                        fontFamily: 'LXGWWenKai',
                      )
                    ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMoodChip(int index, String label, Color textColor, {String? iconPath}) {
    final isSelected = (_selectedMoodIdx ?? -1) == index;
    final isNight = UserState().isNight;
    
    return GestureDetector(
      onTap: () => _updateFilter(moodIndex: index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(right: 12),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected 
              ? const Color(0xFFD4A373) 
              : (isNight ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.04)),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected 
                ? const Color(0xFFD4A373) 
                : (isNight ? Colors.white10 : Colors.black.withOpacity(0.05)),
          ),
          boxShadow: isSelected ? [
            BoxShadow(
              color: const Color(0xFFD4A373).withOpacity(0.3),
              blurRadius: 8,
              offset: const Offset(0, 2),
            )
          ] : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (iconPath != null) ...[
              Image.asset(iconPath, width: 16, height: 16),
              const SizedBox(width: 6),
            ] else ...[
              Icon(
                Icons.mood_rounded,
                size: 16,
                color: isSelected ? Colors.white : textColor.withOpacity(0.5),
              ),
              const SizedBox(width: 6),
            ],
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                fontFamily: 'LXGWWenKai',
                color: isSelected ? Colors.white : textColor.withOpacity(0.8),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildThemeChip(PdfThemeType type, String label, IconData iconData, Color textColor) {
    final isSelected = _selectedTheme == type;
    final isNight = UserState().isNight;
    
    return GestureDetector(
      onTap: () => setState(() {
        _selectedTheme = type;
        _previewRevision++;
      }),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(right: 12),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected 
              ? const Color(0xFFD4A373) 
              : (isNight ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.04)),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected 
                ? const Color(0xFFD4A373) 
                : (isNight ? Colors.white10 : Colors.black.withOpacity(0.05)),
          ),
          boxShadow: isSelected ? [
            BoxShadow(
              color: const Color(0xFFD4A373).withOpacity(0.3),
              blurRadius: 8,
              offset: const Offset(0, 2),
            )
          ] : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              iconData,
              size: 16,
              color: isSelected ? Colors.white : textColor.withOpacity(0.5),
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                fontFamily: 'LXGWWenKai',
                color: isSelected ? Colors.white : textColor.withOpacity(0.8),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
