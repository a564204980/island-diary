import 'package:flutter/material.dart';
import '../models/diary_block.dart';
import 'package:island_diary/features/record/presentation/pages/diary_editor_page.dart';
import '../components/font_size_picker_sheet.dart';
import '../components/color_picker_sheet.dart';
import '../components/font_picker_sheet.dart';
import '../utils/emoji_mapping.dart';
import 'package:island_diary/core/state/user_state.dart';
import './diary_editor_core_mixin.dart';

mixin DiaryEditorFormatMixin<T extends DiaryEditorPage> on State<T>, DiaryEditorCoreMixin<T> {
  void showUnifiedColorPicker() {
    FocusScope.of(context).unfocus();
    setState(() => isColorPickerOpen = true);
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => DiaryColorPickerSheet(
        currentTextColor: currentTextColor,
        currentBgColor: currentHighlightColor,
        paperStyle: currentPaperStyle,
        onApplyColor: (color, isBackground) {
          final activeBlock = activeTextBlock;
          final selection = activeBlock?.controller.selection;

          setState(() {
            if (isBackground) {
              currentHighlightColor = color;
              if (activeBlock != null && selection != null && !selection.isCollapsed) {
                (activeBlock.controller as DiaryTextEditingController)
                    .applyAttributeToSelection(selection, bgColor: color);
              }
            } else {
              currentTextColor = color;
              if (activeBlock != null && selection != null && !selection.isCollapsed) {
                (activeBlock.controller as DiaryTextEditingController)
                    .applyAttributeToSelection(selection, color: color);
              } else {
                for (var block in blocks) {
                  if (block is TextBlock) {
                    (block.controller as DiaryTextEditingController).updateBaseColor(color);
                  }
                }
              }
            }
          });
          onBlocksChanged();
          Navigator.pop(context);
        },
        onClear: (isBackground) {
          final activeBlock = activeTextBlock;
          final selection = activeBlock?.controller.selection;
          if (activeBlock != null && selection != null && !selection.isCollapsed) {
            setState(() {
              if (isBackground) {
                (activeBlock.controller as DiaryTextEditingController)
                    .applyAttributeToSelection(selection, clearBgColor: true);
              } else {
                (activeBlock.controller as DiaryTextEditingController)
                    .applyAttributeToSelection(selection, clearColor: true);
              }
            });
            onBlocksChanged();
          }
          Navigator.pop(context);
        },
      ),
    ).then((_) {
      if (mounted) setState(() => isColorPickerOpen = false);
    });
  }

  void showFontSizePicker() {
    FocusScope.of(context).unfocus();
    setState(() => isColorPickerOpen = true);
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) {
          return DiaryFontSizePickerSheet(
            currentFontSize: currentFontSize,
            paperStyle: currentPaperStyle,
            onApplyFontSize: (size) {
              setModalState(() {
                currentFontSize = size;
              });
              onApplyFontSize(size);
            },
          );
        },
      ),
    ).then((_) {
      if (mounted) setState(() => isColorPickerOpen = false);
    });
  }

  void onApplyFontSize(double size) {
    final activeBlock = activeTextBlock;
    final selection = activeBlock?.controller.selection;

    setState(() {
      currentFontSize = size;
      if (activeBlock != null &&
          selection != null &&
          !selection.isCollapsed) {
        (activeBlock.controller as DiaryTextEditingController)
            .applyAttributeToSelection(selection, fontSize: size);
      } else {
        // 全局应用
        for (var block in blocks) {
          if (block is TextBlock) {
            (block.controller as DiaryTextEditingController)
                .updateBaseFontSize(size);
          }
        }
      }
    });
    UserState().setPreferredFontSize(size);
    onBlocksChanged();
    scrollToActiveBlock();
  }

  void showFontPicker() {
    FocusScope.of(context).unfocus();
    setState(() => isColorPickerOpen = true);
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => DiaryFontPickerSheet(
        currentFontFamily: currentFontFamily,
        onApplyFontFamily: onApplyFontFamily,
      ),
    ).then((_) {
      if (mounted) setState(() => isColorPickerOpen = false);
    });
  }

  void onApplyFontFamily(String family) {
    setState(() {
      currentFontFamily = family;
      for (var block in blocks) {
        if (block is TextBlock) {
          (block.controller as DiaryTextEditingController).updateBaseFontFamily(family);
        }
      }
    });
    UserState().setPreferredFontFamily(family);
    onBlocksChanged();
    Navigator.pop(context);
  }

  void toggleEmoji() {
    setState(() {
      isEmojiOpen = !isEmojiOpen;
      if (isEmojiOpen) {
        FocusScope.of(context).unfocus();
        // 延时等待面板动画（约 250ms）开启后，触发自动滚动以确保光标可见
        Future.delayed(const Duration(milliseconds: 300), () {
          if (mounted && isEmojiOpen) {
            scrollToActiveBlock();
          }
        });
      } else {
        activeTextBlock?.focusNode.requestFocus();
      }
    });
  }

  void onEmojiSelected(String emoji) {
    final activeBlock = activeTextBlock;
    if (activeBlock == null) return;
    final controller = activeBlock.controller;
    final text = controller.text;
    final selection = controller.selection;
    
    final int start = selection.isValid ? selection.start : text.length;
    final int end = selection.isValid ? selection.end : text.length;
    
    final newText = text.replaceRange(
      start.clamp(0, text.length),
      end.clamp(0, text.length),
      emoji,
    );
    
    controller.value = controller.value.copyWith(
      text: newText,
      selection: TextSelection.collapsed(offset: start + emoji.length),
    );
    onBlocksChanged();
    scrollToActiveBlock();
  }

  void handleEmojiBackspace() {
    final activeBlock = activeTextBlock;
    if (activeBlock == null) return;
    final controller = activeBlock.controller;
    final text = controller.text;
    final selection = controller.selection;
    if (!selection.isValid || selection.start == 0) return;

    if (selection.isCollapsed) {
      int start = selection.start - 1;
      
      if (text[start] == ']') {
        final openBracketIndex = text.lastIndexOf('[', start);
        if (openBracketIndex != -1) {
          final content = text.substring(openBracketIndex + 1, start);
          if (EmojiMapping.nameToPath.containsKey(content)) {
            start = openBracketIndex;
          } else if (start > 0 && 
              text.codeUnitAt(start - 1) >= 0xD800 && 
              text.codeUnitAt(start - 1) <= 0xDBFF) {
            start -= 1; 
          }
        }
      } else if (start > 0 && 
          text.codeUnitAt(start - 1) >= 0xD800 && 
          text.codeUnitAt(start - 1) <= 0xDBFF) {
        start -= 1; 
      }
      final newText = text.replaceRange(start, selection.start, '');
      controller.value = controller.value.copyWith(
        text: newText,
        selection: TextSelection.collapsed(offset: start),
      );
    } else {
      final newText = text.replaceRange(selection.start, selection.end, '');
      controller.value = controller.value.copyWith(
        text: newText,
        selection: TextSelection.collapsed(offset: selection.start),
      );
    }
    onBlocksChanged();
    scrollToActiveBlock();
  }

  void handleEmojiSend() {
    onSave();
  }
}
