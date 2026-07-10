import sys
import re

with open('d:/project/island_diary/lib/shared/widgets/diary_entry/components/diary_text_context_menu.dart', 'r', encoding='utf-8') as f:
    code = f.read()

# Make it Stateful
code = code.replace('class DiaryTextContextMenu extends StatelessWidget {', 'class DiaryTextContextMenu extends StatefulWidget {')

# Add State class
code = code.replace(
'''  const DiaryTextContextMenu({
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
  });''',
'''  const DiaryTextContextMenu({
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
  bool _isColorMode = false;
''')

# Replace field accesses with widget.
fields = [
    'editableTextState', 'blockIndex', 'annotations', 'onAddAnnotation',
    'onDeleteAnnotation', 'showAnnotation', 'showUnderline', 'paperStyle',
    'controllerOverride', 'selectionOffset', 'onAttributeApplied'
]
parts = code.split('class _DiaryTextContextMenuState extends State<DiaryTextContextMenu> {')
state_code = parts[1]

for field in fields:
    state_code = re.sub(r'(?<!\.)\b' + field + r'\b(?!\s*:)', 'widget.' + field, state_code)

code = parts[0] + 'class _DiaryTextContextMenuState extends State<DiaryTextContextMenu> {' + state_code

# Replace the layout
layout_start = code.find('            child: Row(')
layout_start = code.find('              children: [', layout_start) + len('              children: [\n')

layout_end = code.find('            ),\n          ),\n          CustomPaint(', layout_start)

new_layout = '''                AnimatedSize(
                  duration: const Duration(milliseconds: 250),
                  curve: Curves.easeOutCubic,
                  child: _isColorMode ? const SizedBox.shrink() : Row(
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
                    child: _isColorMode ? const SizedBox.shrink() : Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const SizedBox(width: 4),
                        _buildToolbarButton(Icons.format_color_text_rounded, () {
                          final controller = widget.controllerOverride ?? widget.editableTextState.widget.controller;
                          if (controller is DiaryTextEditingController) {
                            final targetSelection = widget.selectionOffset != null && widget.selectionOffset! > 0
                                ? TextSelection(
                                    baseOffset: selection.baseOffset + widget.selectionOffset!,
                                    extentOffset: selection.extentOffset + widget.selectionOffset!,
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
                            widget.editableTextState.hideToolbar();
                            showModalBottomSheet(
                              context: context,
                              backgroundColor: Colors.transparent,
                              builder: (ctx) => DiaryColorPickerSheet(
                                currentTextColor: currentTextColor,
                                currentBgColor: currentBgColor,
                                paperStyle: widget.paperStyle ?? 'classic',
                                initialIsBackground: false,
                                onApplyColor: (color, isBg) {
                                  if (isBg) {
                                    controller.applyAttributeToSelection(targetSelection, bgColor: color);
                                  } else {
                                    controller.applyAttributeToSelection(targetSelection, color: color);
                                  }
                                  Navigator.pop(ctx);
                                  widget.onAttributeApplied?.call();
                                },
                                onClear: (isBg) {
                                  if (isBg) {
                                    controller.applyAttributeToSelection(targetSelection, clearBgColor: true);
                                  } else {
                                    controller.applyAttributeToSelection(targetSelection, clearColor: true);
                                  }
                                  Navigator.pop(ctx);
                                  widget.onAttributeApplied?.call();
                                },
                              ),
                            );
                          }
                        }, false),
                        const SizedBox(width: 4),
                      ],
                    ),
                  ),
                  _buildToolbarButton(Icons.format_color_fill_rounded, () {
                    setState(() {
                      _isColorMode = !_isColorMode;
                    });
                  }, _isColorMode),
                  AnimatedSize(
                    duration: const Duration(milliseconds: 250),
                    curve: Curves.easeOutCubic,
                    child: _isColorMode ? const SizedBox.shrink() : Row(
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
                ],
                AnimatedSize(
                  duration: const Duration(milliseconds: 250),
                  curve: Curves.easeOutCubic,
                  alignment: Alignment.centerLeft,
                  child: !_isColorMode ? const SizedBox.shrink() : Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const SizedBox(width: 8),
                      ..._buildColorModeChildren(context).skip(2),
                    ],
                  ),
                ),
'''

code = code[:layout_start] + new_layout + code[layout_end:]

# Add _buildColorModeChildren
# Put it just before the final }
end_of_state_idx = code.rfind('}')

method_code = '''
  List<Widget> _buildColorModeChildren(BuildContext context) {
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
      _buildToolbarButton(Icons.format_color_fill_rounded, () {
        setState(() {
          _isColorMode = false;
        });
      }, true),
      const SizedBox(width: 8),
      ...colors.map((color) => GestureDetector(
        onTap: () {
          if (controller is DiaryTextEditingController) {
             controller.applyAttributeToSelection(targetSelection, bgColor: color);
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
             controller.applyAttributeToSelection(targetSelection, clearBgColor: true);
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

code = code[:end_of_state_idx] + method_code + code[end_of_state_idx:]
code = "import 'package:island_diary/shared/widgets/diary_entry/utils/diary_utils.dart';\n" + code

with open('d:/project/island_diary/lib/shared/widgets/diary_entry/components/diary_text_context_menu.dart', 'w', encoding='utf-8') as f:
    f.write(code)
