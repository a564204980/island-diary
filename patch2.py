import sys
import re

with open('d:/project/island_diary/lib/shared/widgets/diary_entry/components/diary_text_context_menu.dart', 'r', encoding='utf-8') as f:
    code = f.read()

# 1. State class definition
code = code.replace('class DiaryTextContextMenu extends StatelessWidget {', 'class DiaryTextContextMenu extends StatefulWidget {')

state_definition = '''  const DiaryTextContextMenu({
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
'''

code = code.replace('''  const DiaryTextContextMenu({
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
  });''', state_definition)

# 2. Add widget. to fields inside the State class body (before the painter class)
parts = code.split('class _ToolbarArrowPainter extends CustomPainter {')
state_body = parts[0]
painter_body = 'class _ToolbarArrowPainter extends CustomPainter {' + parts[1]

fields = [
    'editableTextState', 'blockIndex', 'annotations', 'onAddAnnotation',
    'onDeleteAnnotation', 'showAnnotation', 'showUnderline', 'paperStyle',
    'controllerOverride', 'selectionOffset', 'onAttributeApplied'
]

# Only replace fields after `bool _isColorMode = false;`
body_parts = state_body.split('bool _isColorMode = false;')
pre_body = body_parts[0] + 'bool _isColorMode = false;'
post_body = body_parts[1]

for field in fields:
    post_body = re.sub(r'(?<!\.)\b' + field + r'\b(?!\s*:)', 'widget.' + field, post_body)

state_body = pre_body + post_body

# 3. Replace the layout row children
# Find the exact Row children
layout_start = state_body.find('            child: Row(')
layout_start = state_body.find('              children: [\n', layout_start) + len('              children: [\n')

layout_end = state_body.find('              ],\n            ),\n          ),\n          CustomPaint(', layout_start)

if layout_end == -1:
    print("Could not find layout end!")
    sys.exit(1)

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

state_body = state_body[:layout_start] + new_layout + state_body[layout_end:]

# 4. Insert _buildColorModeChildren before the end of the state class
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

# Find the last `}` in state_body
end_of_state_idx = state_body.rfind('}')
state_body = state_body[:end_of_state_idx] + method_code + state_body[end_of_state_idx:]

code = state_body + painter_body
code = "import 'package:island_diary/shared/widgets/diary_entry/utils/diary_utils.dart';\n" + code

with open('d:/project/island_diary/lib/shared/widgets/diary_entry/components/diary_text_context_menu.dart', 'w', encoding='utf-8') as f:
    f.write(code)
print("Done!")
