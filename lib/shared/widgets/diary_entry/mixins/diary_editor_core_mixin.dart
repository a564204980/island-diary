import 'dart:async';
import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../models/diary_block.dart';
import 'package:island_diary/features/record/domain/models/diary_entry.dart';
import 'package:island_diary/features/record/presentation/pages/diary_editor_page.dart';
import '../utils/diary_utils.dart';
import '../../../../core/state/user_state.dart';
import '../../mood_picker/config/mood_config.dart';
import '../../island_alert.dart';

mixin DiaryEditorCoreMixin<T extends DiaryEditorPage> on State<T> {
  final List<DiaryBlock> blocks = [];
  final ScrollController scrollController = ScrollController();
  final Map<String, GlobalKey> blockKeys = {};

  bool isEmojiOpen = false;
  String? weather;
  String? temp;
  String? location;
  bool isColorPickerOpen = false;
  bool isImagePickerOpen = false;
  bool isRecording = false;
  double keyboardHeight = 280;
  Color currentTextColor = UserState().isNight
      ? const Color(0xFFE0C097)
      : const Color(0xFF5D4037);
  double currentFontSize = 20.0;
  String currentFontFamily = 'LXGWWenKai';
  String? lastFocusedBlockId;
  String? _fixedQuote;

  String get fixedQuote => _fixedQuote ?? '';

  void initializeEditor({DiaryEntry? entry}) {
    if (blocks.isEmpty) {
      currentTextColor = UserState().isNight
          ? const Color(0xFFE0C097)
          : const Color(0xFF5D4037);
    }
    
    if (entry != null) {
      _loadFromEntry(entry);
    } else {
      loadDraft();
    }
    
    final mood = kMoods[widget.moodIndex];
    _fixedQuote = DiaryUtils.getMoodQuote(mood.label);
    
    final firstTextBlock = blocks.whereType<TextBlock>().firstOrNull;
    if (firstTextBlock != null && firstTextBlock.controller is TopicTextEditingController) {
      final tc = firstTextBlock.controller as TopicTextEditingController;
      currentFontFamily = tc.baseFontFamily;
      currentFontSize = tc.baseFontSize;
      if (tc.text.isNotEmpty) {
        currentTextColor = tc.baseColor;
      }
    }
  }

  void _loadFromEntry(DiaryEntry entry) {
    blocks.clear();
    blockKeys.clear();
    for (var item in entry.blocks) {
      final block = DiaryBlock.fromMap(item);
      if (block is TextBlock) {
        addFocusListener(block);
      }
      blocks.add(block);
      blockKeys[block.id] = GlobalKey();
    }
    weather = entry.weather;
    temp = entry.temp;
    location = entry.location;
  }

  void addFocusListener(TextBlock block) {
    block.focusNode.addListener(() {
      if (block.focusNode.hasFocus) {
        lastFocusedBlockId = block.id;
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
            final attrs = (tc is TopicTextEditingController) ? tc.attributes : null;
            block = TextBlock(tc.text, attributes: attrs, id: newId);
          } else if (block is ImageBlock) {
            block = ImageBlock(block.file, id: newId);
          }
          draftModified = true;
        }
        if (block is TextBlock) {
          addFocusListener(block);
        }
        existingIds.add(block.id);
        blocks.add(block);
        blockKeys[block.id] = GlobalKey();
      }
      weather = UserState().diaryDraft.value?.weather;
      temp = UserState().diaryDraft.value?.temp;
      location = UserState().diaryDraft.value?.location;
      
      if (draftModified) {
        onBlocksChanged();
      }
    } else {
      final initialBlock = TextBlock('', baseColor: currentTextColor);
      addFocusListener(initialBlock);
      blocks.add(initialBlock);
      blockKeys[initialBlock.id] = GlobalKey();
    }
  }

  Future<void> onBlocksChanged() async {
    final content = blocks
        .whereType<TextBlock>()
        .map((b) => b.controller.text)
        .join('\n');

    await UserState().saveDraft(
      moodIndex: widget.moodIndex,
      intensity: widget.intensity,
      content: content,
      tag: widget.tag,
      weather: weather,
      temp: temp,
      location: location,
      blocks: blocks.map((b) => b.toMap()).toList(),
    );
  }

  TextBlock? get activeTextBlock {
    final focused = blocks.whereType<TextBlock>().where((b) => b.focusNode.hasFocus);
    if (focused.isNotEmpty) return focused.first;
    if (lastFocusedBlockId != null) {
      final lastFocused = blocks.whereType<TextBlock>().where((b) => b.id == lastFocusedBlockId);
      if (lastFocused.isNotEmpty) return lastFocused.first;
    }
    if (blocks.whereType<TextBlock>().isNotEmpty) {
      return blocks.whereType<TextBlock>().last;
    }
    return null;
  }

  Future<bool> onSave() async {
    final fullText = blocks
        .whereType<TextBlock>()
        .map((b) => b.controller.text)
        .join('\n');

    if (fullText.trim().isEmpty &&
        blocks.whereType<ImageBlock>().isEmpty &&
        blocks.whereType<AudioBlock>().isEmpty) {
      IslandAlert.show(
        context,
        message: '从心出发，总要留下点什么（日记内容不能为空哦）',
      );
      return false;
    }

    try {
      final content = blocks
          .whereType<TextBlock>()
          .map((b) => b.controller.text)
          .join('\n');

      if (widget.entry != null) {
        // 修改模式
        final updatedEntry = DiaryEntry(
          id: widget.entry!.id,
          dateTime: widget.entry!.dateTime,
          moodIndex: widget.moodIndex,
          intensity: widget.intensity,
          content: content,
          tag: widget.tag,
          weather: weather,
          temp: temp,
          location: location,
          blocks: blocks.map((b) => b.toMap()).toList(),
        );
        await UserState().updateDiary(updatedEntry);
      } else {
        // 新建模式
        await onBlocksChanged();
        await UserState().saveDiary();
      }
      
      if (mounted) Navigator.of(context).pop(true);
      return true;
    } catch (e) {
      IslandAlert.show(
        context,
        icon: '🏮',
        message: '日记暂时无法保存: $e',
      );
      return false;
    }
  }

  void scrollToActiveBlock() {
    _performScrollToActiveBlock();
  }

  void _performScrollToActiveBlock({int retryCount = 0}) {
    if (!mounted) return;
    final activeBlock = activeTextBlock;
    if (activeBlock == null) return;

    final key = blockKeys[activeBlock.id];
    if (key == null) return;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final RenderBox? box = key.currentContext?.findRenderObject() as RenderBox?;
      if (box == null || !box.hasSize) {
        if (retryCount < 5) {
          Future.delayed(const Duration(milliseconds: 50), () {
            if (mounted) _performScrollToActiveBlock(retryCount: retryCount + 1);
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
            fontFamily: 'LXGWWenKai',
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

      final blockContext = key.currentContext;
      if (blockContext == null) return;
      
      final scrollable = Scrollable.of(blockContext);
      final scrollObject = scrollable.context.findRenderObject();
      if (scrollObject is! RenderBox) return;

      final Offset caretInScrollOffset = box.localToGlobal(
        Offset(caretOffset.dx, caretOffset.dy + 4),
        ancestor: scrollObject,
      );
      final double currentScroll = scrollController.offset;
      final double viewportHeight = scrollObject.size.height;
      final double targetScroll =
          currentScroll + caretInScrollOffset.dy - (viewportHeight / 2);

      if (scrollController.hasClients &&
          scrollController.position.hasContentDimensions) {
        scrollController.animateTo(
          targetScroll.clamp(0.0, scrollController.position.maxScrollExtent),
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
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

  void toggleRecord() {
    setState(() => isRecording = !isRecording);
  }
}
