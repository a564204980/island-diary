import 'dart:math' as math;
import 'dart:io' as io;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'components/diary_paper_canvas.dart';
import 'components/diary_toolbar.dart';
import 'components/emoji_panel.dart';
import 'models/diary_block.dart';
import 'components/diary_block_item.dart';
import 'components/mood_tag.dart';
import '../mood_picker/config/mood_config.dart';
import '../../../core/state/user_state.dart';
import 'utils/diary_utils.dart';

class MoodDiaryEntrySheet extends StatefulWidget {
  final int moodIndex;
  final double intensity;

  const MoodDiaryEntrySheet({
    super.key,
    required this.moodIndex,
    required this.intensity,
  });

  @override
  State<MoodDiaryEntrySheet> createState() => _MoodDiaryEntrySheetState();
}

class _MoodDiaryEntrySheetState extends State<MoodDiaryEntrySheet> {
  final List<DiaryBlock> _blocks = [];
  final ScrollController _scrollController = ScrollController();

  bool _isEmojiOpen = false;
  bool _isRecording = false;
  double _keyboardHeight = 280;

  // 当前全局颜色（默认为咖啡色）
  Color _currentTextColor = const Color(0xFF5D4037);

  @override
  void initState() {
    super.initState();
    _loadDraft();
  }

  void _loadDraft() {
    final draft = UserState().diaryDraft.value?.blocks;
    if (draft != null && draft.isNotEmpty) {
      for (var item in draft) {
        _blocks.add(DiaryBlock.fromMap(item));
      }
    } else {
      _blocks.add(TextBlock(''));
    }
  }

  void _onBlocksChanged() {
    final content = _blocks
        .whereType<TextBlock>()
        .map((b) => b.controller.text)
        .join('\n');

    UserState().saveDraft(
      moodIndex: widget.moodIndex,
      intensity: widget.intensity,
      content: content,
      blocks: _blocks.map((b) => b.toMap()).toList(),
    );
  }

  TextBlock? get _activeTextBlock {
    final focused = _blocks.whereType<TextBlock>().where(
      (b) => b.focusNode.hasFocus,
    );
    if (focused.isNotEmpty) return focused.first;
    if (_blocks.whereType<TextBlock>().isNotEmpty) {
      return _blocks.whereType<TextBlock>().last;
    }
    return null;
  }

  void _onImageButtonPressed() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);

    if (image != null) {
      setState(() {
        _blocks.add(ImageBlock(image));
        _blocks.add(TextBlock(''));
      });
      _onBlocksChanged();
      Future.delayed(const Duration(milliseconds: 100), () {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      });
    }
  }

  void _removeImage(int index) {
    setState(() {
      _blocks.removeAt(index);
    });
    _onBlocksChanged();
  }

  void _showImagePreview(ImageBlock block) {
    final bool isWeb = kIsWeb;
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: Stack(
          alignment: Alignment.center,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: isWeb
                  ? Image.network(block.file.path)
                  : Image.file(io.File(block.file.path)),
            ),
            Positioned(
              top: 10,
              right: 10,
              child: IconButton(
                icon: const Icon(Icons.close, color: Colors.white, size: 30),
                onPressed: () => Navigator.pop(context),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _toggleEmoji() {
    setState(() {
      if (_isEmojiOpen) {
        _isEmojiOpen = false;
      } else {
        _isEmojiOpen = true;
        FocusScope.of(context).unfocus();
      }
    });
  }

  void _onEmojiSelected(String emoji) {
    final activeBlock = _activeTextBlock;
    if (activeBlock != null) {
      final controller = activeBlock.controller;
      final text = controller.text;
      final selection = controller.selection;
      final newText = text.replaceRange(
        selection.start.clamp(0, text.length),
        selection.end.clamp(0, text.length),
        emoji,
      );
      controller.text = newText;
      controller.selection = TextSelection.collapsed(
        offset: selection.start + emoji.length,
      );
    }
  }

  void _toggleRecord() {
    setState(() {
      _isRecording = !_isRecording;
    });
  }

  void _insertTopic() {
    final activeBlock = _activeTextBlock;
    if (activeBlock == null) return;

    final controller = activeBlock.controller;
    final text = controller.text;
    final selection = controller.selection;
    final insertion = "#话题 ";
    final newText = text.replaceRange(
      selection.start.clamp(0, text.length),
      selection.end.clamp(0, text.length),
      insertion,
    );

    controller.value = controller.value.copyWith(
      text: newText,
      selection: TextSelection.collapsed(offset: selection.start + 1),
    );

    activeBlock.focusNode.requestFocus();
    _onBlocksChanged();
  }

  void _showColorPicker() {
    final colors = [
      const Color(0xFF5D4037),
      const Color(0xFF2C3E50),
      const Color(0xFF34495E),
      const Color(0xFF27AE60),
      const Color(0xFF16A085),
      const Color(0xFFC0392B),
      const Color(0xFFE74C3C),
      const Color(0xFF8E44AD),
      const Color(0xFF9B59B6),
      const Color(0xFFF39C12),
      const Color(0xFFD35400),
      const Color(0xFF2980B9),
      const Color(0xFF7F8C8D),
      const Color(0xFF1ABC9C),
      const Color(0xFFD4AC0D),
    ];

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => _CustomColorPickerSheet(
        title: '选择文字颜色',
        currentTextColor: _currentTextColor,
        colors: colors,
        onApplyColor: (color) {
          final activeBlock = _activeTextBlock;
          final selection = activeBlock?.controller.selection;

          setState(() {
            _currentTextColor = color;
            if (activeBlock != null &&
                selection != null &&
                !selection.isCollapsed) {
              (activeBlock.controller as TopicTextEditingController)
                  .applyAttributeToSelection(selection, color: color);
            } else {
              for (var block in _blocks) {
                if (block is TextBlock) {
                  (block.controller as TopicTextEditingController)
                      .updateBaseColor(color);
                }
              }
            }
          });
          _onBlocksChanged();
          Navigator.pop(context);
        },
        onClear: () {
          final activeBlock = _activeTextBlock;
          final selection = activeBlock?.controller.selection;
          if (activeBlock != null &&
              selection != null &&
              !selection.isCollapsed) {
            setState(() {
              (activeBlock.controller as TopicTextEditingController)
                  .applyAttributeToSelection(selection, clearColor: true);
            });
            _onBlocksChanged();
          }
          Navigator.pop(context);
        },
      ),
    );
  }

  void _showBackgroundColorPicker() {
    final colors = [
      const Color(0xFFFFF9EE),
      const Color(0xFFF9EED8),
      const Color(0xFFE8F5E9),
      const Color(0xFFE3F2FD),
      const Color(0xFFFFF3E0),
      const Color(0xFFFFEBEE),
      const Color(0xFFF3E5F5),
      const Color(0xFFE0F2F1),
      const Color(0xFFF1F8E9),
      const Color(0xFFFFFDE7),
      const Color(0xFFFFFF00),
      const Color(0xFF00FF00),
      const Color(0xFF00FFFF),
      const Color(0xFFFF00FF),
      const Color(0xFFC0C0C0),
    ];

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => _CustomColorPickerSheet(
        title: '选择文字背景色',
        currentTextColor: Colors.transparent,
        colors: colors,
        onApplyColor: (color) {
          final activeBlock = _activeTextBlock;
          final selection = activeBlock?.controller.selection;

          setState(() {
            if (activeBlock != null &&
                selection != null &&
                !selection.isCollapsed) {
              (activeBlock.controller as TopicTextEditingController)
                  .applyAttributeToSelection(selection, bgColor: color);
            }
          });
          _onBlocksChanged();
          Navigator.pop(context);
        },
        onClear: () {
          final activeBlock = _activeTextBlock;
          final selection = activeBlock?.controller.selection;
          if (activeBlock != null &&
              selection != null &&
              !selection.isCollapsed) {
            setState(() {
              (activeBlock.controller as TopicTextEditingController)
                  .applyAttributeToSelection(selection, clearBgColor: true);
            });
            _onBlocksChanged();
          }
          Navigator.pop(context);
        },
      ),
    );
  }

  void _onSave() {
    final fullText = _blocks
        .whereType<TextBlock>()
        .map((b) => b.controller.text)
        .join('\n');
    debugPrint('Saving content: $fullText');
    UserState().clearDraft();
    Navigator.of(context).pop();
  }

  // 辅助方法：确保光标可见
  void _ensureCursorVisible() {
    final activeBlock = _activeTextBlock;
    if (activeBlock == null) return;
    Future.delayed(const Duration(milliseconds: 100), () {
      if (!mounted) return;
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final double screenHeight = MediaQueryData.fromView(
      View.of(context),
    ).size.height;
    final mood = kMoods[widget.moodIndex];

    return PopScope(
      canPop: false,
      child: Scaffold(
        resizeToAvoidBottomInset: false,
        backgroundColor: Colors.transparent,
        body: Stack(
          children: [
            GestureDetector(
              onTap: () {
                FocusScope.of(context).unfocus();
                setState(() => _isEmojiOpen = false);
              },
              child: Container(
                width: double.infinity,
                height: double.infinity,
                color: Colors.transparent, // 保持透明，显示底层的 barrier 模糊
                child: SafeArea(
                  child: Column(
                    children: [
                      const SizedBox(height: 120),
                      Expanded(
                        child: Stack(
                          clipBehavior: Clip.none,
                          alignment: Alignment.topCenter,
                          children: [
                            Builder(
                              builder: (context) {
                                final viewInsets = MediaQuery.of(
                                  context,
                                ).viewInsets;
                                if (viewInsets.bottom > 200) {
                                  _keyboardHeight = viewInsets.bottom;
                                }
                                final double bottomOffset = math.max(
                                  viewInsets.bottom,
                                  _isEmojiOpen ? _keyboardHeight : 0,
                                );
                                final double baseHeight = screenHeight * 0.85;
                                final double availableHeight =
                                    screenHeight -
                                    (screenHeight * 0.11) -
                                    bottomOffset;
                                final double dynamicHeight =
                                    (availableHeight < baseHeight)
                                    ? availableHeight
                                    : baseHeight;

                                final double screenWidthForPadding =
                                    MediaQuery.of(context).size.width;
                                final double horizontalPadding =
                                    screenWidthForPadding > 600 ? 50.0 : 32.0;

                                return AnimatedContainer(
                                  duration: const Duration(milliseconds: 250),
                                  curve: Curves.easeOutCubic,
                                  onEnd: _ensureCursorVisible,
                                  height: dynamicHeight,
                                  width: double.infinity,
                                  child: DiaryPaperCanvas(
                                    shadowColor: mood.glowColor,
                                    padding: EdgeInsets.fromLTRB(
                                      horizontalPadding,
                                      40,
                                      horizontalPadding,
                                      64,
                                    ),
                                    child: Column(
                                      children: [
                                        Expanded(
                                          child: ListView.builder(
                                            controller: _scrollController,
                                            padding: EdgeInsets.zero,
                                            itemCount: _blocks.length,
                                            itemBuilder: (context, index) {
                                              return DiaryBlockItem(
                                                block: _blocks[index],
                                                index: index,
                                                onRemoveImage: () =>
                                                    _removeImage(index),
                                                onShowPreview:
                                                    _showImagePreview,
                                              );
                                            },
                                          ),
                                        ),
                                        Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceBetween,
                                          children: [
                                            TextButton(
                                              onPressed: () =>
                                                  Navigator.of(context).pop(),
                                              child: const Text(
                                                '返回',
                                                style: TextStyle(
                                                  fontFamily: 'FZKai',
                                                  fontSize: 18,
                                                  color: Color(0xFFA68A78),
                                                ),
                                              ),
                                            ),
                                            TextButton(
                                              onPressed: _onSave,
                                              child: const Text(
                                                '保存',
                                                style: TextStyle(
                                                  fontFamily: 'FZKai',
                                                  fontSize: 18,
                                                  fontWeight: FontWeight.bold,
                                                  color: Color(0xFF8B5E3C),
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ).animate().fadeIn(duration: 500.ms),
                            Positioned(
                              top: -18,
                              child: MoodTag(
                                iconPath:
                                    mood.iconPath ??
                                    'assets/images/icons/sun.png',
                                description:
                                    DiaryUtils.getPersonifiedMoodDescription(
                                      mood.label,
                                      widget.intensity,
                                    ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            Positioned(
              bottom: MediaQuery.of(context).viewInsets.bottom,
              left: 0,
              right: 0,
              child: Builder(
                builder: (context) {
                  final double currentBottomAreaHeight = _isEmojiOpen
                      ? _keyboardHeight
                      : 0;
                  return Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      DiaryToolbar(
                        isEmojiOpen: _isEmojiOpen,
                        isRecording: _isRecording,
                        onEmojiToggle: _toggleEmoji,
                        onRecordToggle: _toggleRecord,
                        onImagePick: _onImageButtonPressed,
                        onTopicClick: _insertTopic,
                        onColorClick: _showColorPicker,
                        onBgColorClick: _showBackgroundColorPicker,
                      ),
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 250),
                        curve: Curves.easeOutCubic,
                        height: currentBottomAreaHeight,
                        color: const Color(0xFFF9EED8).withOpacity(0.95),
                        child: _isEmojiOpen
                            ? EmojiPanel(onEmojiSelected: _onEmojiSelected)
                            : const SizedBox.shrink(),
                      ),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CustomColorPickerSheet extends StatefulWidget {
  final String title;
  final Color currentTextColor;
  final ValueChanged<Color> onApplyColor;
  final VoidCallback onClear;
  final List<Color> colors;

  const _CustomColorPickerSheet({
    required this.title,
    required this.currentTextColor,
    required this.onApplyColor,
    required this.onClear,
    required this.colors,
  });

  @override
  State<_CustomColorPickerSheet> createState() =>
      _CustomColorPickerSheetState();
}

class _CustomColorPickerSheetState extends State<_CustomColorPickerSheet> {
  late bool showCustom;
  late Color pickerColor;

  @override
  void initState() {
    super.initState();
    showCustom = false;
    pickerColor = widget.currentTextColor;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: 20 + MediaQuery.of(context).viewInsets.bottom,
      ),
      decoration: const BoxDecoration(
        color: Color(0xFFFDF7E9),
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(28),
          topRight: Radius.circular(28),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 顶部标题栏
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                showCustom ? '自定义颜色' : widget.title,
                style: const TextStyle(
                  fontFamily: 'FZKai',
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF8B5E3C),
                ),
              ),
              IconButton(
                icon: Icon(
                  showCustom ? Icons.grid_view : Icons.colorize_rounded,
                  color: const Color(0xFF8B5E3C),
                ),
                onPressed: () => setState(() => showCustom = !showCustom),
              ),
            ],
          ),
          const SizedBox(height: 12),

          if (!showCustom)
            // 模式 A：快捷预设网格
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: Wrap(
                spacing: 14,
                runSpacing: 14,
                alignment: WrapAlignment.center,
                children: [
                  ...widget.colors.map((color) {
                    final isSelected = widget.currentTextColor == color;
                    return GestureDetector(
                      onTap: () => widget.onApplyColor(color),
                      child: AnimatedContainer(
                        duration: 200.ms,
                        width: 46,
                        height: 46,
                        decoration: BoxDecoration(
                          color: color,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: isSelected
                                ? const Color(0xFF8B5E3C)
                                : Colors.white.withOpacity(0.5),
                            width: isSelected ? 3 : 1.5,
                          ),
                          boxShadow: isSelected
                              ? [
                                  BoxShadow(
                                    color: color.withOpacity(0.3),
                                    blurRadius: 10,
                                    spreadRadius: 2,
                                  ),
                                ]
                              : [],
                        ),
                      ),
                    );
                  }),
                  // 清除按钮
                  GestureDetector(
                    onTap: widget.onClear,
                    child: Container(
                      width: 46,
                      height: 46,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.8),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: const Color(0xFF8B5E3C).withOpacity(0.3),
                          width: 1.5,
                        ),
                      ),
                      child: const Icon(
                        Icons.block,
                        color: Color(0xFFC0392B),
                        size: 26,
                      ),
                    ),
                  ),
                ],
              ),
            )
          else
            // 模式 B：方阵专业取色
            Column(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: ColorPicker(
                    pickerColor: pickerColor,
                    onColorChanged: (color) =>
                        setState(() => pickerColor = color),
                    pickerAreaHeightPercent: 0.6,
                    enableAlpha: false,
                    displayThumbColor: true,
                    labelTypes: const [], // 隐藏数字标签，保持简洁
                    paletteType: PaletteType.hsvWithHue,
                    pickerAreaBorderRadius: BorderRadius.circular(12),
                  ),
                ),
                const SizedBox(height: 16),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4.0),
                  child: Row(
                    children: [
                      // 颜色预览块
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: pickerColor,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: const Color(0xFF8B5E3C).withOpacity(0.3),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () => widget.onApplyColor(pickerColor),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF8B5E3C),
                            foregroundColor: Colors.white,
                            elevation: 0,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          child: const Text(
                            '落地此色',
                            style: TextStyle(
                              fontFamily: 'FZKai',
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          const SizedBox(height: 12),
        ],
      ),
    );
  }
}
