import 'package:flutter/material.dart';
import 'package:island_diary/shared/widgets/diary_entry/models/diary_block.dart';
import 'underline_picker_sheet.dart';
import 'circle_picker_sheet.dart';

class DiaryTextContextMenu extends StatefulWidget {
  final EditableTextState editableTextState;
  final int blockIndex;
  final Map<String, String> annotations;
  final Function({
    String? key,
    required int blockIndex,
    required int start,
    required int end,
    required String selectedText,
  })
  onAddAnnotation;
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
  State<DiaryTextContextMenu> createState() => _DiaryTextContextMenuState();
}

class _DiaryTextContextMenuState extends State<DiaryTextContextMenu> {
  int _colorMode = 0;

  @override
  Widget build(BuildContext context) {
    final selection = widget.editableTextState.textEditingValue.selection;
    if (selection.isCollapsed) return const SizedBox.shrink();

    final text = widget.editableTextState.textEditingValue.text;
    final selectedText = selection.start >= 0 && selection.end <= text.length
        ? text.substring(selection.start, selection.end)
        : '';

    // 如果选择的文本仅包含 Object Replacement Character (\uFFFC，代表 WidgetSpan，如小气泡或图片)
    // 则直接隐藏选区工具栏，不弹出 tooltip
    if (selectedText.isEmpty ||
        selectedText.trim().runes.every((r) => r == 0xFFFC)) {
      return const SizedBox.shrink();
    }

    // 检查选区是否与已有批注有重叠
    Map<String, dynamic>? overlappingAnn;
    for (var entry in widget.annotations.entries) {
      final parts = entry.key.split('_');
      if (parts.length == 3 && int.tryParse(parts[0]) == widget.blockIndex) {
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
    if (widget.showAnnotation && overlappingAnn != null) {
      final int annStart = overlappingAnn['start'];
      final int annEnd = overlappingAnn['end'];
      if (selection.start != annStart || selection.end != annEnd) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          widget.editableTextState.updateEditingValue(
            widget.editableTextState.textEditingValue.copyWith(
              selection: TextSelection(
                baseOffset: annStart,
                extentOffset: annEnd,
              ),
            ),
          );
        });
        return const SizedBox.shrink();
      }
    }

    final double screenWidth = MediaQuery.sizeOf(context).width;
    final Offset primaryAnchor =
        widget.editableTextState.contextMenuAnchors.primaryAnchor;
    final Offset? secondaryAnchor =
        widget.editableTextState.contextMenuAnchors.secondaryAnchor;

    // In some custom editors (like ExtendedText), primaryAnchor is the start of the selection
    // and secondaryAnchor is the end. Averaging them gives the exact visual center.
    double anchorDx = primaryAnchor.dx;
    if (secondaryAnchor != null &&
        (secondaryAnchor.dx - primaryAnchor.dx).abs() > 0.1) {
      anchorDx = (primaryAnchor.dx + secondaryAnchor.dx) / 2.0;
    }

    // 针对阅读模式和编辑模式光标计算差异，设置不同的偏移量
    final double yOffset = widget.showUnderline ? 13 : 0;

    return CustomSingleChildLayout(
      delegate: TextSelectionToolbarLayoutDelegate(
        anchorAbove: Offset(anchorDx, primaryAnchor.dy + yOffset),
        anchorBelow: secondaryAnchor != null
            ? Offset(anchorDx, secondaryAnchor.dy - 6)
            : Offset(anchorDx, primaryAnchor.dy + yOffset),
      ),
      child: IntrinsicWidth(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFF38383A),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.15),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                physics: const NeverScrollableScrollPhysics(),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // 1. 复制按钮
                    AnimatedSize(
                      duration: const Duration(milliseconds: 250),
                      curve: Curves.easeOutCubic,
                      child: _colorMode != 0
                          ? const SizedBox.shrink()
                          : Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                _buildToolbarButton(Icons.copy_rounded, () {
                                  widget.editableTextState.copySelection(
                                    SelectionChangedCause.toolbar,
                                  );
                                  widget.editableTextState.hideToolbar();
                                }, false),
                              ],
                            ),
                    ),

                    // 2. 文字样式 (加粗、下划线、圈线)
                    if (widget.showUnderline)
                      AnimatedSize(
                        duration: const Duration(milliseconds: 250),
                        curve: Curves.easeOutCubic,
                        child: _colorMode != 0
                            ? const SizedBox.shrink()
                            : Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const SizedBox(width: 4),
                                _buildToolbarButton(
                                  Icons.format_bold_rounded,
                                  () {
                                    final controller =
                                        widget.controllerOverride ??
                                        widget
                                            .editableTextState
                                            .widget
                                            .controller;
                                    if (controller
                                        is DiaryTextEditingController) {
                                      final targetSelection =
                                          widget.selectionOffset != null &&
                                              widget.selectionOffset! > 0
                                          ? TextSelection(
                                              baseOffset:
                                                  selection.baseOffset +
                                                  widget.selectionOffset!,
                                              extentOffset:
                                                  selection.extentOffset +
                                                  widget.selectionOffset!,
                                            )
                                          : selection;
                                      bool isBold = false;
                                      for (var attr in controller.attributes) {
                                        if (attr.bold == true &&
                                            attr.start <=
                                                targetSelection.start &&
                                            attr.end >= targetSelection.end) {
                                          isBold = true;
                                          break;
                                        }
                                      }
                                      if (isBold) {
                                        controller.applyAttributeToSelection(
                                          targetSelection,
                                          clearBold: true,
                                        );
                                      } else {
                                        controller.applyAttributeToSelection(
                                          targetSelection,
                                          bold: true,
                                        );
                                      }
                                      widget.onAttributeApplied?.call();
                                      widget.editableTextState.hideToolbar();
                                    }
                                  },
                                  false,
                                  iconSize: 22,
                                ),
                                const SizedBox(width: 4),
                                _buildToolbarButton(
                                  Icons.format_underlined_rounded,
                                  () {
                                    final controller =
                                        widget.controllerOverride ??
                                        widget
                                            .editableTextState
                                            .widget
                                            .controller;
                                    if (controller
                                        is DiaryTextEditingController) {
                                      final targetSelection =
                                          widget.selectionOffset != null &&
                                              widget.selectionOffset! > 0
                                          ? TextSelection(
                                              baseOffset:
                                                  selection.baseOffset +
                                                  widget.selectionOffset!,
                                              extentOffset:
                                                  selection.extentOffset +
                                                  widget.selectionOffset!,
                                            )
                                          : selection;
                                      String? currentStyle;
                                      Color? currentColor;
                                      for (var attr in controller.attributes) {
                                        if (attr.underlineStyle != null &&
                                            !attr.underlineStyle!.startsWith(
                                              'circle',
                                            ) &&
                                            attr.start <=
                                                targetSelection.start &&
                                            attr.end >= targetSelection.end) {
                                          currentStyle = attr.underlineStyle;
                                          currentColor =
                                              attr.underlineColor ?? attr.color;
                                          break;
                                        }
                                      }
                                      widget.editableTextState.hideToolbar();
                                      showModalBottomSheet(
                                        context: context,
                                        backgroundColor: Colors.transparent,
                                        barrierColor: Colors.transparent,
                                        isScrollControlled: true,
                                        builder: (ctx) => UnderlinePickerSheet(
                                          currentStyle: currentStyle,
                                          currentColor: currentColor,
                                          paperStyle:
                                              widget.paperStyle ?? 'classic',
                                          onSelectStyle: (style, color) {
                                            if (style == null ||
                                                style.isEmpty) {
                                              controller
                                                  .applyAttributeToSelection(
                                                    targetSelection,
                                                    clearUnderline: true,
                                                  );
                                            } else {
                                              controller
                                                  .applyAttributeToSelection(
                                                    targetSelection,
                                                    underlineStyle: style,
                                                    underlineColor: color,
                                                  );
                                            }
                                            widget.onAttributeApplied?.call();
                                          },
                                        ),
                                      ).then((_) {
                                        if (controller.selection.baseOffset !=
                                            controller.selection.extentOffset) {
                                          controller.selection =
                                              TextSelection.collapsed(
                                                offset:
                                                    controller.selection.end,
                                              );
                                        }
                                      });
                                    }
                                  },
                                  false,
                                  iconSize: 22,
                                ),
                                if (widget.paperStyle != null &&
                                    widget.paperStyle != 'classic' &&
                                    widget.paperStyle != 'dark_paper' &&
                                    widget.paperStyle != 'leather' &&
                                    widget.paperStyle != 'starry') ...[
                                  const SizedBox(width: 4),
                                  _buildToolbarButton(
                                    Icons.circle_outlined,
                                    () {
                                      final controller =
                                          widget.controllerOverride ??
                                          widget
                                              .editableTextState
                                              .widget
                                              .controller;
                                      if (controller
                                          is DiaryTextEditingController) {
                                        final targetSelection =
                                            widget.selectionOffset != null &&
                                                widget.selectionOffset! > 0
                                            ? TextSelection(
                                                baseOffset:
                                                    selection.baseOffset +
                                                    widget.selectionOffset!,
                                                extentOffset:
                                                    selection.extentOffset +
                                                    widget.selectionOffset!,
                                              )
                                            : selection;
                                        String? currentStyle;
                                        Color? currentColor;
                                        for (var attr
                                            in controller.attributes) {
                                          if (attr.underlineStyle != null &&
                                              attr.underlineStyle!.startsWith(
                                                'circle',
                                              ) &&
                                              attr.start <=
                                                  targetSelection.start &&
                                              attr.end >= targetSelection.end) {
                                            currentStyle = attr.underlineStyle;
                                            currentColor =
                                                attr.underlineColor ??
                                                attr.color;
                                            break;
                                          }
                                        }
                                        widget.editableTextState.hideToolbar();
                                        showModalBottomSheet(
                                          context: context,
                                          backgroundColor: Colors.transparent,
                                          barrierColor: Colors.transparent,
                                          isScrollControlled: true,
                                          builder: (ctx) => CirclePickerSheet(
                                            currentStyle: currentStyle,
                                            currentColor: currentColor,
                                            paperStyle:
                                                widget.paperStyle ?? 'classic',
                                            onApply: (style, color) {
                                              if (style == null ||
                                                  style.isEmpty) {
                                                controller
                                                    .applyAttributeToSelection(
                                                      targetSelection,
                                                      clearUnderline: true,
                                                    );
                                              } else {
                                                controller
                                                    .applyAttributeToSelection(
                                                      targetSelection,
                                                      underlineStyle: style,
                                                      underlineColor: color,
                                                    );
                                              }
                                              widget.onAttributeApplied?.call();
                                            },
                                          ),
                                        ).then((_) {
                                          if (controller.selection.baseOffset !=
                                              controller
                                                  .selection
                                                  .extentOffset) {
                                            controller.selection =
                                                TextSelection.collapsed(
                                                  offset:
                                                      controller.selection.end,
                                                );
                                          }
                                        });
                                      }
                                    },
                                    false,
                                  ),
                                ],
                              ],
                            ),
                    ),

                    // 3. 颜色设置 (文字颜色、背景颜色)
                    if (widget.showUnderline) ...[
                      AnimatedSize(
                        duration: const Duration(milliseconds: 250),
                        curve: Curves.easeOutCubic,
                        child: _colorMode == 2
                            ? const SizedBox.shrink()
                            : Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const SizedBox(width: 4),
                                  _buildToolbarButton(
                                    Icons.draw_rounded,
                                    () {
                                      setState(() {
                                        _colorMode = _colorMode == 1 ? 0 : 1;
                                      });
                                    },
                                    _colorMode == 1,
                                    verticalPadding: _colorMode == 1 ? 14 : 8,
                                    iconSize: 22,
                                  ),
                                ],
                              ),
                      ),
                      AnimatedSize(
                        duration: const Duration(milliseconds: 250),
                        curve: Curves.easeOutCubic,
                        child: _colorMode == 1
                            ? const SizedBox.shrink()
                            : Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const SizedBox(width: 4),
                                  _buildToolbarButton(
                                    Icons.format_paint_rounded,
                                    () {
                                      setState(() {
                                        _colorMode = _colorMode == 2 ? 0 : 2;
                                      });
                                    },
                                    _colorMode == 2,
                                    verticalPadding: _colorMode == 2 ? 14 : 8,
                                    iconSize: 20,
                                  ),
                                ],
                              ),
                      ),
                    ],

                    // 4. 注释功能
                    AnimatedSize(
                      duration: const Duration(milliseconds: 250),
                      curve: Curves.easeOutCubic,
                      child: _colorMode != 0
                          ? const SizedBox.shrink()
                          : Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                if (widget.showAnnotation) ...[
                                  const SizedBox(width: 4),
                                  _buildToolbarButton(
                                    Icons.add_comment_rounded,
                                    () {
                                      widget.editableTextState.hideToolbar();
                                      widget.onAddAnnotation(
                                        blockIndex: widget.blockIndex,
                                        start: selection.start,
                                        end: selection.end,
                                        selectedText: selectedText,
                                      );
                                    },
                                    false,
                                  ),
                                  if (overlappingAnn != null &&
                                      widget.onDeleteAnnotation != null) ...[
                                    const SizedBox(width: 4),
                                    _buildToolbarButton(
                                      Icons.delete_outline_rounded,
                                      () {
                                        widget.editableTextState.hideToolbar();
                                        widget.onDeleteAnnotation!(
                                          overlappingAnn!['key'],
                                        );
                                      },
                                      false,
                                    ),
                                  ],
                                ],
                              ],
                            ),
                    ),

                    // 5. 颜色展开盘
                    AnimatedSize(
                      duration: const Duration(milliseconds: 250),
                      curve: Curves.easeOutCubic,
                      alignment: Alignment.centerLeft,
                      child: _colorMode == 0
                          ? const SizedBox.shrink()
                          : Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const SizedBox(width: 8),
                                ..._buildColorModeChildren(context),
                              ],
                            ),
                    ),
                  ],
                ),
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

  Widget _buildToolbarButton(
    IconData icon,
    VoidCallback onTap,
    bool isHighlighted, {
    double verticalPadding = 8,
    double iconSize = 20,
  }) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: 14,
          vertical: verticalPadding,
        ),
        decoration: BoxDecoration(
          color: isHighlighted
              ? Colors.white.withValues(alpha: 0.15)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, size: iconSize, color: Colors.white),
      ),
    );
  }

  List<Widget> _buildColorModeChildren(BuildContext context) {
    final selection = widget.editableTextState.textEditingValue.selection;
    final targetSelection =
        widget.selectionOffset != null && widget.selectionOffset! > 0
        ? TextSelection(
            baseOffset: selection.baseOffset + widget.selectionOffset!,
            extentOffset: selection.extentOffset + widget.selectionOffset!,
          )
        : selection;
    final controller =
        widget.controllerOverride ?? widget.editableTextState.widget.controller;

    final bool isBackground = _colorMode == 2;

    // Unified 2x6 custom colors for both text and background
    final List<Color> customColors = [
      const Color(0xFFFC2E1F),
      const Color(0xFFFE9027),
      const Color(0xFFFECE34),
      const Color(0xFF93D140),
      const Color(0xFF28C0B5),
      const Color(0xFF3A8AFD),
      const Color(0xFF9168FA),
      const Color(0xFFFC7CBA),
      const Color(0xFFFB7774),
      const Color(0xFFFCC286),
      const Color(0xFFB3B2B4),
      const Color(0xFF4D4D4D),
    ];

    return [
      const SizedBox(width: 4),
      Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: customColors
                .sublist(0, 6)
                .map(
                  (color) => _buildColorCircle(
                    color,
                    controller,
                    targetSelection,
                    isBackground,
                  ),
                )
                .toList(),
          ),
          const SizedBox(height: 6),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: customColors
                .sublist(6, 12)
                .map(
                  (color) => _buildColorCircle(
                    color,
                    controller,
                    targetSelection,
                    isBackground,
                  ),
                )
                .toList(),
          ),
        ],
      ),
      const SizedBox(width: 4),
      _buildClearFormatIcon(controller, targetSelection, isBackground),
      const SizedBox(width: 4),
    ];
  }

  Widget _buildColorCircle(
    Color color,
    TextEditingController controller,
    TextSelection targetSelection,
    bool isBackground,
  ) {
    return GestureDetector(
      onTap: () {
        if (controller is DiaryTextEditingController) {
          if (!isBackground) {
            controller.applyAttributeToSelection(targetSelection, color: color);
          } else {
            controller.applyAttributeToSelection(
              targetSelection,
              bgColor: color,
            );
          }
          widget.onAttributeApplied?.call();
          widget.editableTextState.hideToolbar();
          if (controller.selection.baseOffset !=
              controller.selection.extentOffset) {
            controller.selection = TextSelection.collapsed(
              offset: controller.selection.end,
            );
          }
        }
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 5.0),
        child: Container(
          width: 22,
          height: 22,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: color,
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.3),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
                blurRadius: 2,
                offset: const Offset(0, 1),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildClearFormatIcon(
    TextEditingController controller,
    TextSelection targetSelection,
    bool isBackground,
  ) {
    return _buildToolbarButton(
      Icons.not_interested_rounded,
      () {
        if (controller is DiaryTextEditingController) {
          if (!isBackground) {
            controller.applyAttributeToSelection(
              targetSelection,
              clearColor: true,
            );
          } else {
            controller.applyAttributeToSelection(
              targetSelection,
              clearBgColor: true,
            );
          }
          widget.onAttributeApplied?.call();
          widget.editableTextState.hideToolbar();
          if (controller.selection.baseOffset !=
              controller.selection.extentOffset) {
            controller.selection = TextSelection.collapsed(
              offset: controller.selection.end,
            );
          }
        }
      },
      false,
      verticalPadding: 14,
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
      ..color = const Color(0xFF38383A)
      ..style = PaintingStyle.fill;

    final double padding = 8.0;
    final double actualLeft = (anchorDx - size.width / 2).clamp(
      padding,
      screenWidth - padding - size.width,
    );
    final double arrowCenterX = (anchorDx - actualLeft).clamp(
      12.0,
      size.width - 12.0,
    );

    final double radius = 1.5;
    final double arrowWidth = 12.0;

    final path = Path()
      ..moveTo(arrowCenterX - arrowWidth / 2, 0)
      ..lineTo(arrowCenterX - radius, size.height - radius)
      ..quadraticBezierTo(
        arrowCenterX,
        size.height,
        arrowCenterX + radius,
        size.height - radius,
      )
      ..lineTo(arrowCenterX + arrowWidth / 2, 0)
      ..close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _ToolbarArrowPainter oldDelegate) {
    return oldDelegate.anchorDx != anchorDx ||
        oldDelegate.screenWidth != screenWidth;
  }
}
