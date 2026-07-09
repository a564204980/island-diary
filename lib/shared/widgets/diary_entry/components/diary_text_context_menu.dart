import 'package:flutter/material.dart';
import 'package:island_diary/shared/widgets/diary_entry/models/diary_block.dart';
import 'underline_picker_sheet.dart';
import 'color_picker_sheet.dart';
import 'circle_picker_sheet.dart';

class DiaryTextContextMenu extends StatelessWidget {
  final EditableTextState editableTextState;
  final int blockIndex;
  final Map<String, String> annotations;
  final Function({
    String? key,
    required int blockIndex,
    required int start,
    required int end,
    required String selectedText,
  }) onAddAnnotation;
  final Function(String key)? onDeleteAnnotation;
  final bool showAnnotation;
  final bool showUnderline;
  final String? paperStyle;
  final DiaryTextEditingController? controllerOverride;
  final int? selectionOffset;
  final VoidCallback? onAttributeApplied;

  const DiaryTextContextMenu({
    super.key,
    required this.editableTextState,
    required this.blockIndex,
    required this.annotations,
    required this.onAddAnnotation,
    this.onDeleteAnnotation,
    this.showAnnotation = true,
    this.showUnderline = false,
    this.paperStyle,
    this.controllerOverride,
    this.selectionOffset,
    this.onAttributeApplied,
  });

  @override
  Widget build(BuildContext context) {
    final selection = editableTextState.textEditingValue.selection;
    if (selection.isCollapsed) return const SizedBox.shrink();

    final text = editableTextState.textEditingValue.text;
    final selectedText = selection.start >= 0 && selection.end <= text.length
        ? text.substring(selection.start, selection.end)
        : '';

    // 如果选择的文本仅包含 Object Replacement Character (\uFFFC，代表 WidgetSpan，如小气泡或图片)
    // 则直接隐藏选区工具栏，不弹出 tooltip
    if (selectedText.isEmpty || selectedText.trim().runes.every((r) => r == 0xFFFC)) {
      return const SizedBox.shrink();
    }

    // 检查选区是否与已有批注有重叠
    Map<String, dynamic>? overlappingAnn;
    for (var entry in annotations.entries) {
      final parts = entry.key.split('_');
      if (parts.length == 3 && int.tryParse(parts[0]) == blockIndex) {
        final annStart = int.tryParse(parts[1]);
        final annEnd = int.tryParse(parts[2]);
        if (annStart != null && annEnd != null) {
          if (selection.start < annEnd && selection.end > annStart) {
            overlappingAnn = {
              'key': entry.key,
              'start': annStart,
              'end': annEnd,
            };
            break;
          }
        }
      }
    }

    // 如果存在重叠的批注，且当前选区未完全覆盖它，则自动扩展选区至整个批注范围
    if (showAnnotation && overlappingAnn != null) {
      final int annStart = overlappingAnn['start'];
      final int annEnd = overlappingAnn['end'];
      if (selection.start != annStart || selection.end != annEnd) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          editableTextState.updateEditingValue(
            editableTextState.textEditingValue.copyWith(
              selection: TextSelection(baseOffset: annStart, extentOffset: annEnd),
            ),
          );
        });
        return const SizedBox.shrink();
      }
    }

    final double screenWidth = MediaQuery.sizeOf(context).width;
    final Offset primaryAnchor = editableTextState.contextMenuAnchors.primaryAnchor;
    final Offset? secondaryAnchor = editableTextState.contextMenuAnchors.secondaryAnchor;
    
    // In some custom editors (like ExtendedText), primaryAnchor is the start of the selection 
    // and secondaryAnchor is the end. Averaging them gives the exact visual center.
    double anchorDx = primaryAnchor.dx;
    if (secondaryAnchor != null && (secondaryAnchor.dx - primaryAnchor.dx).abs() > 0.1) {
      anchorDx = (primaryAnchor.dx + secondaryAnchor.dx) / 2.0;
    }

    return CustomSingleChildLayout(
      delegate: TextSelectionToolbarLayoutDelegate(
        anchorAbove: Offset(anchorDx, primaryAnchor.dy),
        anchorBelow: secondaryAnchor != null 
            ? Offset(anchorDx, secondaryAnchor.dy)
            : Offset(anchorDx, primaryAnchor.dy),
      ),
      child: IntrinsicWidth(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFF2F2F2F),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.15),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildToolbarButton(Icons.copy_rounded, () {
                  editableTextState.copySelection(SelectionChangedCause.toolbar);
                  editableTextState.hideToolbar();
                }, false),
                if (showAnnotation) ...[
                  const SizedBox(width: 4),
                  _buildToolbarButton(Icons.add_comment_rounded, () {
                    editableTextState.hideToolbar();
                    onAddAnnotation(
                      blockIndex: blockIndex,
                      start: selection.start,
                      end: selection.end,
                      selectedText: selectedText,
                    );
                  }, false),
                  if (overlappingAnn != null && onDeleteAnnotation != null) ...[
                    const SizedBox(width: 4),
                    _buildToolbarButton(Icons.delete_outline_rounded, () {
                      editableTextState.hideToolbar();
                      onDeleteAnnotation!(overlappingAnn!['key']);
                    }, false),
                  ],
                ],
                if (showUnderline) ...[
                  const SizedBox(width: 4),
                  _buildToolbarButton(Icons.format_color_text_rounded, () {
                    final controller = controllerOverride ?? editableTextState.widget.controller;
                    if (controller is DiaryTextEditingController) {
                      final targetSelection = selectionOffset != null && selectionOffset! > 0
                          ? TextSelection(
                              baseOffset: selection.baseOffset + selectionOffset!,
                              extentOffset: selection.extentOffset + selectionOffset!,
                            )
                          : selection;
                      Color currentTextColor = controller.baseColor;
                      Color currentBgColor = Colors.transparent;
                      for (var attr in controller.attributes) {
                        if (attr.start <= targetSelection.start && attr.end >= targetSelection.end) {
                          if (attr.color != null) currentTextColor = attr.color!;
                          if (attr.backgroundColor != null) currentBgColor = attr.backgroundColor!;
                        }
                      }
                      editableTextState.hideToolbar();
                      showModalBottomSheet(
                        context: context,
                        backgroundColor: Colors.transparent,
                        builder: (ctx) => DiaryColorPickerSheet(
                          currentTextColor: currentTextColor,
                          currentBgColor: currentBgColor,
                          paperStyle: paperStyle ?? 'classic',
                          initialIsBackground: false,
                          onApplyColor: (color, isBg) {
                            if (isBg) {
                              controller.applyAttributeToSelection(targetSelection, bgColor: color);
                            } else {
                              controller.applyAttributeToSelection(targetSelection, color: color);
                            }
                            Navigator.pop(ctx);
                            onAttributeApplied?.call();
                          },
                          onClear: (isBg) {
                            if (isBg) {
                              controller.applyAttributeToSelection(targetSelection, clearBgColor: true);
                            } else {
                              controller.applyAttributeToSelection(targetSelection, clearColor: true);
                            }
                            Navigator.pop(ctx);
                            onAttributeApplied?.call();
                          },
                        ),
                      );
                    }
                  }, false),
                  const SizedBox(width: 4),
                  _buildToolbarButton(Icons.format_color_fill_rounded, () {
                    final controller = controllerOverride ?? editableTextState.widget.controller;
                    if (controller is DiaryTextEditingController) {
                      final targetSelection = selectionOffset != null && selectionOffset! > 0
                          ? TextSelection(
                              baseOffset: selection.baseOffset + selectionOffset!,
                              extentOffset: selection.extentOffset + selectionOffset!,
                            )
                          : selection;
                      Color currentTextColor = controller.baseColor;
                      Color currentBgColor = Colors.transparent;
                      for (var attr in controller.attributes) {
                        if (attr.start <= targetSelection.start && attr.end >= targetSelection.end) {
                          if (attr.color != null) currentTextColor = attr.color!;
                          if (attr.backgroundColor != null) currentBgColor = attr.backgroundColor!;
                        }
                      }
                      editableTextState.hideToolbar();
                      showModalBottomSheet(
                        context: context,
                        backgroundColor: Colors.transparent,
                        builder: (ctx) => DiaryColorPickerSheet(
                          currentTextColor: currentTextColor,
                          currentBgColor: currentBgColor,
                          paperStyle: paperStyle ?? 'classic',
                          initialIsBackground: true,
                          onApplyColor: (color, isBg) {
                            if (isBg) {
                              controller.applyAttributeToSelection(targetSelection, bgColor: color);
                            } else {
                              controller.applyAttributeToSelection(targetSelection, color: color);
                            }
                            Navigator.pop(ctx);
                            onAttributeApplied?.call();
                          },
                          onClear: (isBg) {
                            if (isBg) {
                              controller.applyAttributeToSelection(targetSelection, clearBgColor: true);
                            } else {
                              controller.applyAttributeToSelection(targetSelection, clearColor: true);
                            }
                            Navigator.pop(ctx);
                            onAttributeApplied?.call();
                          },
                        ),
                      );
                    }
                  }, false),
                  const SizedBox(width: 4),
                  _buildToolbarButton(Icons.format_bold_rounded, () {
                    final controller = controllerOverride ?? editableTextState.widget.controller;
                    if (controller is DiaryTextEditingController) {
                      final targetSelection = selectionOffset != null && selectionOffset! > 0
                          ? TextSelection(
                              baseOffset: selection.baseOffset + selectionOffset!,
                              extentOffset: selection.extentOffset + selectionOffset!,
                            )
                          : selection;
                      bool isBold = false;
                      for (var attr in controller.attributes) {
                        if (attr.bold == true &&
                            attr.start <= targetSelection.start &&
                            attr.end >= targetSelection.end) {
                          isBold = true;
                          break;
                        }
                      }
                      
                      editableTextState.hideToolbar();
                      if (isBold) {
                        controller.applyAttributeToSelection(targetSelection, clearBold: true);
                      } else {
                        controller.applyAttributeToSelection(targetSelection, bold: true);
                      }
                      onAttributeApplied?.call();
                    }
                  }, false),
                  _buildToolbarButton(Icons.format_underlined_rounded, () {
                    final controller = controllerOverride ?? editableTextState.widget.controller;
                    if (controller is DiaryTextEditingController) {
                      final targetSelection = selectionOffset != null && selectionOffset! > 0
                          ? TextSelection(
                              baseOffset: selection.baseOffset + selectionOffset!,
                              extentOffset: selection.extentOffset + selectionOffset!,
                            )
                          : selection;
                      String? currentStyle;
                      for (var attr in controller.attributes) {
                        if ((attr.underline == true || attr.underlineStyle != null) &&
                            attr.start <= targetSelection.start &&
                            attr.end >= targetSelection.end) {
                          currentStyle = attr.underlineStyle ?? 'solid';
                          break;
                        }
                      }
                      
                      editableTextState.hideToolbar();
                      
                      showModalBottomSheet(
                        context: context,
                        backgroundColor: Colors.transparent,
                        isScrollControlled: true,
                        showDragHandle: false,
                        builder: (ctx) => UnderlinePickerSheet(
                          currentStyle: currentStyle,
                          paperStyle: paperStyle ?? 'classic',
                          onSelectStyle: (style) {
                            if (style == null) {
                              controller.applyAttributeToSelection(
                                targetSelection,
                                clearUnderline: true,
                              );
                            } else {
                              controller.applyAttributeToSelection(
                                targetSelection,
                                underlineStyle: style,
                              );
                            }
                            onAttributeApplied?.call();
                          },
                        ),
                      );
                    }
                  }, false),
                  const SizedBox(width: 4),
                  _buildToolbarButton(Icons.gesture_rounded, () {
                    final controller = controllerOverride ?? editableTextState.widget.controller;
                    if (controller is DiaryTextEditingController) {
                      final targetSelection = selectionOffset != null && selectionOffset! > 0
                          ? TextSelection(
                              baseOffset: selection.baseOffset + selectionOffset!,
                              extentOffset: selection.extentOffset + selectionOffset!,
                            )
                          : selection;
                      String? currentStyle;
                      Color? currentColor;
                      for (var attr in controller.attributes) {
                        if (attr.underlineStyle != null &&
                            attr.underlineStyle!.startsWith('circle') &&
                            attr.start <= targetSelection.start &&
                            attr.end >= targetSelection.end) {
                          currentStyle = attr.underlineStyle;
                          currentColor = attr.color;
                          break;
                        }
                      }
                      
                      editableTextState.hideToolbar();
 
                      showModalBottomSheet(
                        context: context,
                        backgroundColor: Colors.transparent,
                        isScrollControlled: true,
                        builder: (ctx) => CirclePickerSheet(
                          currentStyle: currentStyle,
                          currentColor: currentColor,
                          paperStyle: paperStyle ?? 'classic',
                          onApply: (style, color) {
                            controller.applyAttributeToSelection(
                              targetSelection,
                              underlineStyle: style,
                              color: color,
                            );
                            onAttributeApplied?.call();
                          },
                          onClear: () {
                            controller.applyAttributeToSelection(
                              targetSelection,
                              clearUnderline: true,
                            );
                            onAttributeApplied?.call();
                          },
                        ),
                      );
                    }
                  }, false),
                ],
              ],
            ),
          ),
          CustomPaint(
            size: const Size(double.infinity, 6),
            painter: _ToolbarArrowPainter(anchorDx, screenWidth),
          ),
        ],
      ),
      ),
    );
  }

  Widget _buildToolbarButton(IconData icon, VoidCallback onTap, bool isHighlighted) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isHighlighted ? Colors.white.withValues(alpha: 0.15) : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(
          icon,
          size: 20,
          color: Colors.white,
        ),
      ),
    );
  }
}

class _ToolbarArrowPainter extends CustomPainter {
  final double anchorDx;
  final double screenWidth;

  _ToolbarArrowPainter(this.anchorDx, this.screenWidth);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF2F2F2F)
      ..style = PaintingStyle.fill;
      
    final double padding = 8.0; 
    final double actualLeft = (anchorDx - size.width / 2).clamp(padding, screenWidth - padding - size.width);
    final double arrowCenterX = (anchorDx - actualLeft).clamp(12.0, size.width - 12.0);

    final double radius = 1.5;
    final double arrowWidth = 12.0;
    
    final path = Path()
      ..moveTo(arrowCenterX - arrowWidth / 2, 0)
      ..lineTo(arrowCenterX - radius, size.height - radius)
      ..quadraticBezierTo(
          arrowCenterX, size.height, arrowCenterX + radius, size.height - radius)
      ..lineTo(arrowCenterX + arrowWidth / 2, 0)
      ..close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _ToolbarArrowPainter oldDelegate) {
    return oldDelegate.anchorDx != anchorDx || oldDelegate.screenWidth != screenWidth;
  }
}
