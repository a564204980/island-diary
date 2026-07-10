import sys

with open('d:/project/island_diary/lib/shared/widgets/diary_entry/components/diary_text_context_menu.dart', 'r', encoding='utf-8') as f:
    code = f.read()

code = code.replace('bool _isColorMode = false;', 'int _colorMode = 0;')

layout_start = code.find('            child: SingleChildScrollView(')
layout_end = code.find('              ],\n              ),\n            ),\n          ),\n          CustomPaint(')

new_layout = '''            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              physics: const NeverScrollableScrollPhysics(),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  AnimatedSize(
                    duration: const Duration(milliseconds: 250),
                    curve: Curves.easeOutCubic,
                    child: _colorMode != 0 ? const SizedBox.shrink() : Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _buildToolbarButton(Icons.copy_rounded, () {
                          widget.editableTextState.copySelection(SelectionChangedCause.toolbar);
                          widget.editableTextState.hideToolbar();
                        }, false),
                        if (widget.showAnnotation) ...[
                          const SizedBox(width: 4),
                          _buildToolbarButton(Icons.add_comment_rounded, () {
                            widget.editableTextState.hideToolbar();
                            widget.onAddAnnotation(
                              blockIndex: widget.blockIndex,
                              start: selection.start,
                              end: selection.end,
                              selectedText: selectedText,
                            );
                          }, false),
                          if (overlappingAnn != null && widget.onDeleteAnnotation != null) ...[
                            const SizedBox(width: 4),
                            _buildToolbarButton(Icons.delete_outline_rounded, () {
                              widget.editableTextState.hideToolbar();
                              widget.onDeleteAnnotation!(overlappingAnn!['key']);
                            }, false),
                          ],
                        ],
                      ],
                    ),
                  ),
                  if (widget.showUnderline) ...[
                    AnimatedSize(
                      duration: const Duration(milliseconds: 250),
                      curve: Curves.easeOutCubic,
                      child: _colorMode == 2 ? const SizedBox.shrink() : Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const SizedBox(width: 4),
                          _buildToolbarButton(Icons.format_color_text_rounded, () {
                            setState(() {
                              _colorMode = _colorMode == 1 ? 0 : 1;
                            });
                          }, _colorMode == 1),
                        ],
                      ),
                    ),
                    AnimatedSize(
                      duration: const Duration(milliseconds: 250),
                      curve: Curves.easeOutCubic,
                      child: _colorMode == 1 ? const SizedBox.shrink() : Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const SizedBox(width: 4),
                          _buildToolbarButton(Icons.format_color_fill_rounded, () {
                            setState(() {
                              _colorMode = _colorMode == 2 ? 0 : 2;
                            });
                          }, _colorMode == 2),
                        ],
                      ),
                    ),
                  ],
                  AnimatedSize(
                    duration: const Duration(milliseconds: 250),
                    curve: Curves.easeOutCubic,
                    child: _colorMode != 0 ? const SizedBox.shrink() : Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const SizedBox(width: 4),
                        _buildToolbarButton(Icons.format_bold_rounded, () {
                          final controller = widget.controllerOverride ?? widget.editableTextState.widget.controller;
                          if (controller is DiaryTextEditingController) {
                            final targetSelection = widget.selectionOffset != null && widget.selectionOffset! > 0
                                ? TextSelection(
                                    baseOffset: selection.baseOffset + widget.selectionOffset!,
                                    extentOffset: selection.extentOffset + widget.selectionOffset!,
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
                            if (isBold) {
                              controller.applyAttributeToSelection(targetSelection, clearBold: true);
                            } else {
                              controller.applyAttributeToSelection(targetSelection, bold: true);
                            }
                            widget.onAttributeApplied?.call();
                            widget.editableTextState.hideToolbar();
                          }
                        }, false),
                        const SizedBox(width: 4),
                        _buildToolbarButton(Icons.format_underlined_rounded, () {
                          final controller = widget.controllerOverride ?? widget.editableTextState.widget.controller;
                          if (controller is DiaryTextEditingController) {
                            final targetSelection = widget.selectionOffset != null && widget.selectionOffset! > 0
                                ? TextSelection(
                                    baseOffset: selection.baseOffset + widget.selectionOffset!,
                                    extentOffset: selection.extentOffset + widget.selectionOffset!,
                                  )
                                : selection;
                            String? currentStyle;
                            for (var attr in controller.attributes) {
                              if (attr.underlineStyle != null &&
                                  !attr.underlineStyle!.startsWith('circle') &&
                                  attr.start <= targetSelection.start &&
                                  attr.end >= targetSelection.end) {
                                currentStyle = attr.underlineStyle;
                                break;
                              }
                            }
                            widget.editableTextState.hideToolbar();
                            showModalBottomSheet(
                              context: context,
                              backgroundColor: Colors.transparent,
                              isScrollControlled: true,
                              builder: (ctx) => UnderlinePickerSheet(
                                currentStyle: currentStyle,
                                paperStyle: widget.paperStyle ?? 'classic',
                                onSelectStyle: (style) {
                                  if (style == null || style.isEmpty) {
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
                                  Navigator.pop(ctx);
                                  widget.onAttributeApplied?.call();
                                },
                              ),
                            );
                          }
                        }, false),
                        if (widget.paperStyle != null &&
                            widget.paperStyle != 'classic' &&
                            widget.paperStyle != 'dark_paper' &&
                            widget.paperStyle != 'leather' &&
                            widget.paperStyle != 'starry') ...[
                          const SizedBox(width: 4),
                          _buildToolbarButton(Icons.circle_outlined, () {
                            final controller = widget.controllerOverride ?? widget.editableTextState.widget.controller;
                            if (controller is DiaryTextEditingController) {
                              final targetSelection = widget.selectionOffset != null && widget.selectionOffset! > 0
                                  ? TextSelection(
                                      baseOffset: selection.baseOffset + widget.selectionOffset!,
                                      extentOffset: selection.extentOffset + widget.selectionOffset!,
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
                              widget.editableTextState.hideToolbar();
                              showModalBottomSheet(
                                context: context,
                                backgroundColor: Colors.transparent,
                                isScrollControlled: true,
                                builder: (ctx) => CirclePickerSheet(
                                  currentStyle: currentStyle,
                                  currentColor: currentColor,
                                  paperStyle: widget.paperStyle ?? 'classic',
                                  onApply: (style, color) {
                                    controller.applyAttributeToSelection(
                                      targetSelection,
                                      underlineStyle: style,
                                      color: color,
                                    );
                                    Navigator.pop(ctx);
                                    widget.onAttributeApplied?.call();
                                  },
                                  onClear: () {
                                    controller.applyAttributeToSelection(
                                      targetSelection,
                                      clearUnderline: true,
                                    );
                                    Navigator.pop(ctx);
                                    widget.onAttributeApplied?.call();
                                  },
                                ),
                              );
                            }
                          }, false),
                        ],
                      ],
                    ),
                  ),
                  AnimatedSize(
                    duration: const Duration(milliseconds: 250),
                    curve: Curves.easeOutCubic,
                    alignment: Alignment.centerLeft,
                    child: _colorMode == 0 ? const SizedBox.shrink() : Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const SizedBox(width: 8),
                        ..._buildColorModeChildren(context),
                      ],
                    ),
                  ),'''

code = code[:layout_start] + new_layout + code[layout_end:]

# Replace _buildColorModeChildren
start_method = code.find('  List<Widget> _buildColorModeChildren(BuildContext context) {')
end_method = code.find('}\n\nclass _ToolbarArrowPainter extends CustomPainter {', start_method)

new_method = '''  List<Widget> _buildColorModeChildren(BuildContext context) {
    final selection = widget.editableTextState.textEditingValue.selection;
    final targetSelection = widget.selectionOffset != null && widget.selectionOffset! > 0
        ? TextSelection(
            baseOffset: selection.baseOffset + widget.selectionOffset!,
            extentOffset: selection.extentOffset + widget.selectionOffset!,
          )
        : selection;
    final controller = widget.controllerOverride ?? widget.editableTextState.widget.controller;
    
    final List<Color> colors = DiaryUtils.presetTextColors.sublist(0, 5);
    
    return [
      ...colors.map((color) => GestureDetector(
        onTap: () {
          if (controller is DiaryTextEditingController) {
             if (_colorMode == 1) {
               controller.applyAttributeToSelection(targetSelection, color: color);
             } else {
               controller.applyAttributeToSelection(targetSelection, bgColor: color);
             }
             widget.onAttributeApplied?.call();
             widget.editableTextState.hideToolbar();
          }
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 6.0),
          child: Container(
            width: 20,
            height: 20,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: color,
              border: Border.all(color: Colors.white.withValues(alpha: 0.3), width: 1.5),
            ),
          ),
        ),
      )),
      const SizedBox(width: 8),
      GestureDetector(
        onTap: () {
          if (controller is DiaryTextEditingController) {
             if (_colorMode == 1) {
               controller.applyAttributeToSelection(targetSelection, clearColor: true);
             } else {
               controller.applyAttributeToSelection(targetSelection, clearBgColor: true);
             }
             widget.onAttributeApplied?.call();
             widget.editableTextState.hideToolbar();
          }
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4.0),
          child: Icon(Icons.format_color_reset_rounded, color: Colors.white.withValues(alpha: 0.54), size: 20),
        ),
      ),
      const SizedBox(width: 4),
    ];
  }
'''

code = code[:start_method] + new_method + code[end_method:]

with open('d:/project/island_diary/lib/shared/widgets/diary_entry/components/diary_text_context_menu.dart', 'w', encoding='utf-8') as f:
    f.write(code)

print("Replacement complete.")
