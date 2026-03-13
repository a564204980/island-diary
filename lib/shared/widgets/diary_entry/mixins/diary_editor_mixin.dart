import 'dart:io' as io;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:uuid/uuid.dart';
import '../models/diary_block.dart';
import '../diary_entry_sheet.dart';
import '../utils/diary_utils.dart';
import '../../../../core/state/user_state.dart';
import '../../mood_picker/config/mood_config.dart';
import '../components/color_picker_sheet.dart';

/// 抽离日记编辑器的核心逻辑，包括内容块管理、焦点追踪、异步插入（图片/定位）等
mixin DiaryEditorMixin<T extends MoodDiaryEntrySheet> on State<T> {
  final List<DiaryBlock> _blocks = [];
  final ScrollController _scrollController = ScrollController();
  final Map<String, GlobalKey> _blockKeys = {};

  bool _isEmojiOpen = false;
  bool _isRecording = false;
  double _keyboardHeight = 280;
  Color _currentTextColor = const Color(0xFF5D4037);
  String? _lastFocusedBlockId;
  String? _fixedQuote;

  // 暴露给 build 方法使用的变量
  List<DiaryBlock> get blocks => _blocks;
  ScrollController get scrollController => _scrollController;
  Map<String, GlobalKey> get blockKeys => _blockKeys;
  bool get isEmojiOpen => _isEmojiOpen;
  bool get isRecording => _isRecording;
  double get keyboardHeight => _keyboardHeight;
  Color get currentTextColor => _currentTextColor;
  String get fixedQuote => _fixedQuote ?? '';

  void initializeEditor() {
    loadDraft();
    final mood = kMoods[widget.moodIndex];
    _fixedQuote = DiaryUtils.getMoodQuote(mood.label);
  }

  void _addFocusListener(TextBlock block) {
    block.focusNode.addListener(() {
      if (block.focusNode.hasFocus) {
        _lastFocusedBlockId = block.id;
      }
    });
  }

  void loadDraft() {
    final draft = UserState().diaryDraft.value?.blocks;
    final Set<String> existingIds = {};
    bool draftModified = false;

    if (draft != null && draft.isNotEmpty) {
      for (var item in draft) {
        var block = DiaryBlock.fromMap(item);
        if (existingIds.contains(block.id)) {
          final newId = const Uuid().v4();
          if (block is TextBlock) {
            final tc = block.controller;
            final attrs = (tc is TopicTextEditingController)
                ? tc.attributes
                : null;
            block = TextBlock(tc.text, attributes: attrs, id: newId);
          } else if (block is ImageBlock) {
            block = ImageBlock(block.file, id: newId);
          }
          draftModified = true;
        }
        if (block is TextBlock) {
          _addFocusListener(block);
        }
        existingIds.add(block.id);
        _blocks.add(block);
        _blockKeys[block.id] = GlobalKey();
      }
      if (draftModified) {
        onBlocksChanged();
      }
    } else {
      final initialBlock = TextBlock('');
      _addFocusListener(initialBlock);
      _blocks.add(initialBlock);
      _blockKeys[initialBlock.id] = GlobalKey();
    }
  }

  void onBlocksChanged() {
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

  TextBlock? get activeTextBlock {
    final focused = _blocks.whereType<TextBlock>().where(
      (b) => b.focusNode.hasFocus,
    );
    if (focused.isNotEmpty) return focused.first;
    if (_lastFocusedBlockId != null) {
      final lastFocused = _blocks.whereType<TextBlock>().where(
        (b) => b.id == _lastFocusedBlockId,
      );
      if (lastFocused.isNotEmpty) return lastFocused.first;
    }
    if (_blocks.whereType<TextBlock>().isNotEmpty) {
      return _blocks.whereType<TextBlock>().last;
    }
    return null;
  }

  void onImageButtonPressed() async {
    final activeBlock = activeTextBlock;
    TextSelection? savedSelection;
    if (activeBlock != null) savedSelection = activeBlock.controller.selection;

    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);

    if (image != null) {
      final int insertIndex;
      TextBlock? newBottomBlock;

      if (activeBlock != null) {
        final controller = activeBlock.controller;
        final selection = savedSelection ?? controller.selection;
        final text = controller.text;
        final int splitOffset = selection.isValid
            ? selection.extentOffset
            : text.length;
        final beforeText = text.substring(0, splitOffset);
        final afterText = text.substring(splitOffset);
        final originalIndex = _blocks.indexOf(activeBlock);
        controller.text = beforeText;
        insertIndex = originalIndex + 1;
        newBottomBlock = TextBlock(afterText);
      } else {
        insertIndex = _blocks.length;
        newBottomBlock = TextBlock('');
      }

      final imageBlock = ImageBlock(image);

      setState(() {
        _blocks.insert(insertIndex, imageBlock);
        _blocks.insert(insertIndex + 1, newBottomBlock!);
        _blockKeys[imageBlock.id] = GlobalKey();
        _blockKeys[newBottomBlock.id] = GlobalKey();
        _lastFocusedBlockId = newBottomBlock.id;
        _addFocusListener(newBottomBlock);
      });

      onBlocksChanged();

      Future.delayed(const Duration(milliseconds: 100), () {
        if (mounted && newBottomBlock != null) {
          newBottomBlock.controller.selection = const TextSelection.collapsed(
            offset: 0,
          );
          newBottomBlock.focusNode.requestFocus();
          scrollToActiveBlock();
        }
      });
    }
  }

  void onLocationClick() async {
    final activeBlock = activeTextBlock;
    TextSelection? savedSelection;
    if (activeBlock != null) savedSelection = activeBlock.controller.selection;

    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('请开启定位服务')));
      }
      return;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('定位权限被拒绝')));
        }
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('定位权限被永久拒绝，请在设置中开启')));
      }
      return;
    }

    try {
      final position = await Geolocator.getCurrentPosition();
      final placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );
      if (placemarks.isNotEmpty) {
        final p = placemarks.first;
        final address =
            "${p.administrativeArea}${p.locality}${p.subLocality}${p.street}";
        if (activeBlock != null) {
          final controller = activeBlock.controller;
          final text = controller.text;
          final selection = savedSelection ?? controller.selection;
          final insertion = "\n#地点: $address ";
          final newText = text.replaceRange(
            selection.start.clamp(0, text.length),
            selection.end.clamp(0, text.length),
            insertion,
          );
          setState(() {
            controller.value = controller.value.copyWith(
              text: newText,
              selection: TextSelection.collapsed(
                offset: selection.start + insertion.length,
              ),
            );
          });
          onBlocksChanged();
          Future.delayed(Duration.zero, () {
            if (mounted) {
              activeBlock.focusNode.requestFocus();
              scrollToActiveBlock();
            }
          });
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('获取地址失败')));
      }
    }
  }

  void removeImage(int index) {
    if (index < 0 || index >= _blocks.length) return;
    final block = _blocks[index];
    setState(() {
      _blocks.removeAt(index);
      _blockKeys.remove(block.id);
    });
    onBlocksChanged();
  }

  void showImagePreview(ImageBlock block) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: Stack(
          alignment: Alignment.center,
          children: [
            GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Hero(
                tag: block.id,
                child: kIsWeb
                    ? Image.network(block.file.path, fit: BoxFit.contain)
                    : Image.file(io.File(block.file.path), fit: BoxFit.contain),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void scrollToActiveBlock() {
    _performScrollToActiveBlock();
  }

  void _performScrollToActiveBlock({int retryCount = 0}) {
    if (!mounted) return;
    final activeBlock = activeTextBlock;
    if (activeBlock == null) return;

    final key = _blockKeys[activeBlock.id];
    if (key == null) {
      return;
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final RenderBox? box =
          key.currentContext?.findRenderObject() as RenderBox?;
      if (box == null || !box.hasSize) {
        if (retryCount < 5) {
          Future.delayed(const Duration(milliseconds: 50), () {
            if (mounted) {
              _performScrollToActiveBlock(retryCount: retryCount + 1);
            }
          });
        }
        return;
      }

      final controller = activeBlock.controller;
      final selection = controller.selection;
      final text = controller.text;

      final textPainter = TextPainter(
        text: TextSpan(
          text: text,
          style: const TextStyle(
            fontFamily: 'FZKai',
            fontSize: 20,
            height: 1.6,
          ),
        ),
        textDirection: TextDirection.ltr,
      );
      textPainter.layout(maxWidth: box.size.width);

      final offset = selection.isValid
          ? selection.extentOffset.clamp(0, text.length)
          : text.length;
      final caretOffset = textPainter.getOffsetForCaret(
        TextPosition(offset: offset),
        Rect.zero,
      );

      final ScrollableState? scrollable = Scrollable.of(context);
      final RenderObject? scrollObject = scrollable?.context.findRenderObject();
      if (scrollObject is! RenderBox) {
        return;
      }

      final Offset caretInScrollOffset = box.localToGlobal(
        Offset(caretOffset.dx, caretOffset.dy + 4),
        ancestor: scrollObject,
      );
      final double currentScroll = _scrollController.offset;
      final double viewportHeight = scrollObject.size.height;
      final double targetScroll =
          currentScroll + caretInScrollOffset.dy - (viewportHeight / 2);

      _scrollController.animateTo(
        targetScroll.clamp(0.0, _scrollController.position.maxScrollExtent),
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    });
  }

  void ensureCursorVisible() {
    if (!mounted) return;
    final activeBlock = activeTextBlock;
    if (activeBlock != null) {
      activeBlock.focusNode.requestFocus();
      scrollToActiveBlock();
    }
  }

  void insertTopic() {
    final activeBlock = activeTextBlock;
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
    _addFocusListener(activeBlock);
    activeBlock.focusNode.requestFocus();
    onBlocksChanged();
  }

  void showColorPicker() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => DiaryColorPickerSheet(
        title: '选择文字颜色',
        currentTextColor: _currentTextColor,
        colors: DiaryUtils.presetTextColors,
        onApplyColor: (color) {
          final activeBlock = activeTextBlock;
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
          onBlocksChanged();
          Navigator.pop(context);
        },
        onClear: () {
          final activeBlock = activeTextBlock;
          final selection = activeBlock?.controller.selection;
          if (activeBlock != null &&
              selection != null &&
              !selection.isCollapsed) {
            setState(() {
              (activeBlock.controller as TopicTextEditingController)
                  .applyAttributeToSelection(selection, clearColor: true);
            });
            onBlocksChanged();
          }
          Navigator.pop(context);
        },
      ),
    );
  }

  void showBackgroundColorPicker() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => DiaryColorPickerSheet(
        title: '选择文字背景色',
        currentTextColor: Colors.transparent,
        colors: DiaryUtils.presetBgColors,
        onApplyColor: (color) {
          final activeBlock = activeTextBlock;
          final selection = activeBlock?.controller.selection;
          setState(() {
            if (activeBlock != null &&
                selection != null &&
                !selection.isCollapsed) {
              (activeBlock.controller as TopicTextEditingController)
                  .applyAttributeToSelection(selection, bgColor: color);
            }
          });
          onBlocksChanged();
          Navigator.pop(context);
        },
        onClear: () {
          final activeBlock = activeTextBlock;
          final selection = activeBlock?.controller.selection;
          if (activeBlock != null &&
              selection != null &&
              !selection.isCollapsed) {
            setState(() {
              (activeBlock.controller as TopicTextEditingController)
                  .applyAttributeToSelection(selection, clearBgColor: true);
            });
            onBlocksChanged();
          }
          Navigator.pop(context);
        },
      ),
    );
  }

  void onSave() {
    final fullText = _blocks
        .whereType<TextBlock>()
        .map((b) => b.controller.text)
        .join('\n');
    debugPrint('Saving content: $fullText');
    UserState().clearDraft();
    Navigator.of(context).pop();
  }

  void toggleEmoji() {
    setState(() {
      _isEmojiOpen = !_isEmojiOpen;
      if (_isEmojiOpen) {
        FocusScope.of(context).unfocus();
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
    final newText = text.replaceRange(
      selection.start.clamp(0, text.length),
      selection.end.clamp(0, text.length),
      emoji,
    );
    controller.value = controller.value.copyWith(
      text: newText,
      selection: TextSelection.collapsed(
        offset: selection.start + emoji.length,
      ),
    );
    onBlocksChanged();
  }

  void toggleRecord() {
    setState(() => _isRecording = !_isRecording);
  }
}
