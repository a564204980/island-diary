import 'dart:async';
import 'dart:math' as math;
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
  String? customDate;
  String? customTime;
  List<DiaryReply> replies = []; // 新增：保存当前日记的回复内容
  double keyboardHeight = 330;
  Color currentTextColor = UserState().isNight
      ? const Color(0xFFE0C097)
      : const Color(0xFF5D4037);
  Color currentHighlightColor = Colors.transparent;
  double currentFontSize = UserState().preferredFontSize.value;
  String currentFontFamily = UserState().preferredFontFamily.value;
  String? lastFocusedBlockId;
  String? _fixedQuote;
  DateTime? _entryDateTime;
  
  int? currentMoodIndex;
  late double currentIntensity;
  String? currentTag;
  String currentPaperStyle = 'classic';
  bool isMixedLayout = true; // 是否开启图文混排

  String get fixedQuote => _fixedQuote ?? '';

  void initializeEditor({DiaryEntry? entry, DateTime? initialDate}) {
    _entryDateTime = entry?.dateTime ?? initialDate;
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

    // 初始化心情与信纸相关状态
    currentMoodIndex = entry?.moodIndex ?? widget.moodIndex;
    currentIntensity = entry?.intensity ?? widget.intensity;
    currentTag = entry?.tag ?? widget.tag;
    currentPaperStyle = entry?.paperStyle ?? 
                      UserState().diaryDraft.value?.paperStyle ?? 
                      UserState().preferredPaperStyle.value;
    syncBlockColors();

    updateMoodQuote();

    final firstTextBlock = blocks.whereType<TextBlock>().firstOrNull;
    if (firstTextBlock != null &&
        firstTextBlock.controller is DiaryTextEditingController) {
      final tc = firstTextBlock.controller as DiaryTextEditingController;
      currentFontFamily = tc.baseFontFamily;
      currentFontSize = tc.baseFontSize;
      if (tc.text.isNotEmpty) {
        currentTextColor = tc.baseColor;
      }
    }
  }

  void updateMoodQuote() {
    if (currentMoodIndex == null || currentMoodIndex! < 0) {
      _fixedQuote = '从心出发，记录此刻的点滴...';
      return;
    }
    final mood = kMoods[currentMoodIndex!];
    _fixedQuote = DiaryUtils.getMoodQuote(mood.label);
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
    customDate = entry.customDate;
    customTime = entry.customTime;
    replies = List<DiaryReply>.from(entry.replies); // 初始化回复内容
    currentPaperStyle = entry.paperStyle;
  }

  void addFocusListener(TextBlock block) {
    block.focusNode.addListener(() {
      if (block.focusNode.hasFocus) {
        lastFocusedBlockId = block.id;
        // 如果当前开启了表情面板，点击正文自动收起以弹出键盘
        if (isEmojiOpen) {
          setState(() => isEmojiOpen = false);
        }
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
            final attrs = (tc is DiaryTextEditingController)
                ? tc.attributes
                : null;
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
      customDate = UserState().diaryDraft.value?.customDate;
      customTime = UserState().diaryDraft.value?.customTime;
      currentPaperStyle = UserState().diaryDraft.value?.paperStyle ?? 'classic';

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
      moodIndex: currentMoodIndex ?? 4,
      intensity: currentIntensity,
      content: content,
      tag: currentTag,
      weather: weather,
      temp: temp,
      location: location,
      customDate: customDate,
      customTime: customTime,
      dateTime: _entryDateTime,
      blocks: blocks.map((b) => b.toMap()).toList(),
      paperStyle: currentPaperStyle,
    );
  }

  TextBlock? get activeTextBlock {
    final focused = blocks.whereType<TextBlock>().where(
      (b) => b.focusNode.hasFocus,
    );
    if (focused.isNotEmpty) {
      return focused.first;
    }
    if (lastFocusedBlockId != null) {
      final lastFocused = blocks.whereType<TextBlock>().where(
        (b) => b.id == lastFocusedBlockId,
      );
      if (lastFocused.isNotEmpty) {
        return lastFocused.first;
      }
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
      IslandAlert.show(context, message: '从心出发，总要留下点什么（日记内容不能为空哦）');
      return false;
    }

    final hasMood = (currentMoodIndex != null && currentMoodIndex! >= 0) || (currentTag != null && currentTag!.isNotEmpty);
    if (!hasMood) {
      IslandAlert.show(context, message: '先选个心情再出发吧~', icon: '✨');
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
          moodIndex: currentMoodIndex ?? 0, // 如果是纯自定义标签，默认给 0
          intensity: currentIntensity,
          content: content,
          tag: currentTag,
          weather: weather,
          temp: temp,
          location: location,
          customDate: customDate,
          blocks: blocks.map((b) => b.toMap()).toList(),
          replies: replies, // 使用本地维护的回复状态
          paperStyle: currentPaperStyle,
        );
        await UserState().updateDiary(updatedEntry);
      } else {
        // 新建模式
        // 在保存草稿/正式保存时也要确保 moodIndex 有值
        await UserState().saveDraft(
          moodIndex: currentMoodIndex ?? 0,
          intensity: currentIntensity,
          content: content,
          tag: currentTag,
          weather: weather,
          temp: temp,
          location: location,
          customDate: customDate,
          customTime: customTime,
          dateTime: _entryDateTime,
          blocks: blocks.map((b) => b.toMap()).toList(),
          paperStyle: currentPaperStyle,
        );
        await UserState().saveDiary();
      }

      if (mounted) {
        Navigator.of(context).pop(true);
      }
      return true;
    } catch (e) {
      if (mounted) {
        IslandAlert.show(context, icon: '🏮', message: '日记暂时无法保存: $e');
      }
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
      if (blockContext == null) {
        return;
      }
      final scrollable = Scrollable.of(blockContext);
      final scrollObject = scrollable.context.findRenderObject();
      if (scrollObject is! RenderBox) {
        return;
      }

      final Offset caretInScrollOffset = box.localToGlobal(
        Offset(caretOffset.dx, caretOffset.dy + 4),
        ancestor: scrollObject,
      );
      final double currentScroll = scrollController.offset;
      final double viewportHeight = scrollObject.size.height;

      // 核心迭代：考虑底部由于表情包/键盘导致的遮挡高度
      final double viewInsetsBottom = MediaQuery.of(context).viewInsets.bottom;
      final double panelHeight = isEmojiOpen ? math.max(viewInsetsBottom, keyboardHeight) : viewInsetsBottom;
      
      // 有效视口高度 = 总高度 - 底部遮挡 - 顶部状态栏等安全区（估算值或从 Padding 获取）
      final double visibleViewportHeight = viewportHeight - panelHeight;
      
      // 目标：将光标定位在“有效视口”的中间偏上位置（约 1/3 处最舒适）
      final double targetScroll =
          currentScroll + caretInScrollOffset.dy - (visibleViewportHeight * 0.35);

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
    if (!mounted) {
      return;
    }
    final activeBlock = activeTextBlock;
    if (activeBlock != null) {
      activeBlock.focusNode.requestFocus();
      scrollToActiveBlock();
    }
  }

  void handleBackspaceAtStart(int index) {
    if (index <= 0) {
      return;
    }

    final currentBlock = blocks[index];
    if (currentBlock is! TextBlock) {
      return;
    }

    final prevBlock = blocks[index - 1];

    if (prevBlock is TextBlock) {
      // 合并两个文本块的逻辑
      final currentController = currentBlock.controller as DiaryTextEditingController;
      final prevController = prevBlock.controller as DiaryTextEditingController;
      
      final String oldText = prevController.text;
      final String newText = oldText + currentController.text;
      
      // 合并属性，当前块的属性需要增加 oldText.length 的偏移
      final List<TextAttribute> mergedAttributes = List.from(prevController.attributes);
      for (var attr in currentController.attributes) {
        mergedAttributes.add(TextAttribute(
          start: attr.start + oldText.length,
          end: attr.end + oldText.length,
          color: attr.color,
          backgroundColor: attr.backgroundColor,
          fontSize: attr.fontSize,
        ));
      }

      setState(() {
        prevController.text = newText;
        prevController.attributes.clear();
        prevController.attributes.addAll(mergedAttributes);
        
        blocks.removeAt(index);
        blockKeys.remove(currentBlock.id);
        
        lastFocusedBlockId = prevBlock.id;
      });
      
      onBlocksChanged();
      
      // 移动光标到衔接点并强关焦点
      Future.delayed(Duration.zero, () {
        prevBlock.focusNode.requestFocus();
        prevController.selection = TextSelection.collapsed(offset: oldText.length);
      });
    } else {
      // 删除上方媒体块的逻辑
      setState(() {
        blocks.removeAt(index - 1);
        blockKeys.remove(prevBlock.id);
      });
      onBlocksChanged();
      // 当前块焦点保持，不需额外操作，索引自动变化
    }
  }

  void toggleRecord() {
    setState(() => isRecording = !isRecording);
  }

  /// 集中处理所有文本块的颜色同步，避免在 build 阶段触发状态更新
  void syncBlockColors() {
    final bool isNight = UserState().isNight;
    final Color targetColor = DiaryUtils.getInkColor(currentPaperStyle, isNight);

    for (var block in blocks) {
      if (block is TextBlock && block.controller is DiaryTextEditingController) {
        final tc = block.controller as DiaryTextEditingController;
        if (tc.baseColor != targetColor) {
          tc.updateBaseColor(targetColor);
        }
      }
    }
    
    // 同步当前默认文字颜色，用于后续新生成的块
    currentTextColor = targetColor;
  }
}
