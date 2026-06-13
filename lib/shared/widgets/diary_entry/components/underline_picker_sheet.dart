import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:island_diary/core/state/user_state.dart';
import '../utils/diary_utils.dart';
import '../models/diary_block.dart';
import 'diary_bottom_sheet.dart';

class UnderlinePickerSheet extends StatelessWidget {
  final ValueChanged<String?> onSelectStyle;
  final String? currentStyle;

  const UnderlinePickerSheet({
    super.key,
    required this.onSelectStyle,
    this.currentStyle,
  });

  @override
  Widget build(BuildContext context) {
    final List<Map<String, dynamic>> styles = [
      {'index': '01', 'label': '细直', 'value': 'solid', 'text': '这是一段文字', 'color': const Color(0xFF4A90E2)},
      {'index': '02', 'label': '粗直', 'value': 'thick', 'text': '这是一段文字', 'color': const Color(0xFF2ECC71)},
      {'index': '03', 'label': '双线', 'value': 'double', 'text': '这是一段文字', 'color': const Color(0xFF9B59B6)},
      {'index': '04', 'label': '虚线', 'value': 'dashed', 'text': '这是一段文字', 'color': const Color(0xFFE67E22)},
      {'index': '05', 'label': '点线', 'value': 'dotted', 'text': '这是一段文字', 'color': const Color(0xFFE91E63)},
      {'index': '06', 'label': '波浪', 'value': 'wavy', 'text': '这是一段文字', 'color': const Color(0xFF1ABC9C)},
      {'index': '07', 'label': '手写', 'value': 'handdrawn', 'text': '这是一段文字', 'color': const Color(0xFFE74C3C)},
      {'index': '08', 'label': '荧光', 'value': 'marker', 'text': '这是一段文字', 'color': const Color(0xFFF1C40F)},
      {'index': '09', 'label': '渐变', 'value': 'gradient', 'text': '这是一段文字', 'color': const Color(0xFF3498DB)},
    ];

    final bool isNight = UserState().isNight;
    final Color textColor = DiaryUtils.getInkColor('standard', isNight);

    return DiaryBottomSheet(
      paperStyle: 'standard',
      isDiary: true,
      showDragHandle: true,
      padding: EdgeInsets.only(
        left: 12,
        right: 12,
        top: 10,
        bottom: 10 + MediaQuery.of(context).padding.bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Text(
                '选择划线样式',
                style: TextStyle(
                  fontFamily: 'LXGWWenKai',
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: textColor.withValues(alpha: 0.9),
                ),
              ),
            ),
          ),
          const SizedBox(height: 14),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              mainAxisSpacing: 8,
              crossAxisSpacing: 8,
              childAspectRatio: 1.75, // 更紧凑比例，缩小上下空隙
            ),
            itemCount: styles.length,
            itemBuilder: (context, index) {
              final item = styles[index];
              final String val = item['value']!;
              final String idxStr = item['index']!;
              final String label = item['label']!;
              final String previewText = item['text']!;
              final Color indexColor = item['color']!;
              final isSelected = currentStyle == val;

              return GestureDetector(
                onTap: () {
                  onSelectStyle(val);
                  Navigator.pop(context);
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
                  decoration: BoxDecoration(
                    color: isNight 
                        ? (isSelected ? Colors.white.withValues(alpha: 0.08) : Colors.white.withValues(alpha: 0.02))
                        : (isSelected ? Colors.white : Colors.white.withValues(alpha: 0.8)),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isSelected ? indexColor : (isNight ? Colors.white10 : Colors.black.withValues(alpha: 0.04)),
                      width: isSelected ? 2.0 : 1.0,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: isSelected ? 0.06 : 0.01),
                        blurRadius: 4,
                        offset: const Offset(0, 1),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Top badge + Label
                      Row(
                        children: [
                          Container(
                            width: 13,
                            height: 13,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: indexColor,
                              shape: BoxShape.circle,
                            ),
                            child: Text(
                              idxStr,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 8,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              label,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontFamily: 'LXGWWenKai',
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: isNight ? Colors.white70 : Colors.black87,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      // Center text with actual style applied
                      Expanded(
                        child: Center(
                           child: Text(
                            previewText,
                            style: TextStyle(
                              fontSize: 11,
                              height: 1.8,
                              fontWeight: FontWeight.bold,
                              color: isNight ? Colors.white.withValues(alpha: 0.9) : const Color(0xDE000000),
                              fontFamily: 'LXGWWenKai',
                              background: Paint()
                                ..shader = DiaryTextEditingController.getUnderlineShader(
                                  val,
                                  indexColor,
                                  11.0 * 1.8,
                                ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
          if (currentStyle != null) ...[
            const SizedBox(height: 8),
            TextButton(
              onPressed: () {
                onSelectStyle(null);
                Navigator.pop(context);
              },
              child: Text(
                '清除当前划线',
                style: TextStyle(
                  fontFamily: 'LXGWWenKai',
                  fontSize: 13,
                  color: Colors.redAccent.withValues(alpha: 0.8),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
