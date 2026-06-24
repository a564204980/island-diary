import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:uuid/uuid.dart';
import '../models/diary_block.dart';
import 'package:island_diary/features/record/domain/models/diary_entry.dart';
import 'package:island_diary/features/record/domain/models/diary_draft.dart';
import 'package:island_diary/features/record/presentation/pages/diary_editor_page.dart';
import '../utils/diary_utils.dart';
import '../../../../core/state/user_state.dart';
import '../../mood_picker/config/mood_config.dart';
import '../../island_alert.dart';

mixin DiaryEditorCoreMixin<T extends DiaryEditorPage> on State<T> {
  late String currentDraftId;
  bool isModified = false;
  bool _isInitializing = false;
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
  DateTime? entryDateTime;
  
  int? currentMoodIndex;
  late double currentIntensity;
  String? currentTag;
  Map<String, String> currentAnnotations = {};

  List<String> get currentTags {
    if (currentTag == null || currentTag!.isEmpty) return [];
    return currentTag!.split(',').map((t) => t.trim()).where((t) => t.isNotEmpty).toList();
  }

  set currentTags(List<String> tags) {
    currentTag = tags.isEmpty ? null : tags.join(',');
  }
  String currentPaperStyle = 'classic';
  bool isMixedLayout = true; // 是否开启图文混排
  bool isImageGrid = false; // 是否开启图片九宫格
  String currentBookId = 'default'; // 当前选择的日记本ID

  String get fixedQuote => _fixedQuote ?? '';

  void initializeEditor({DiaryEntry? entry, DateTime? initialDate}) {
    _isInitializing = true;
    entryDateTime = entry?.dateTime ?? initialDate;
    if (blocks.isEmpty) {
      currentTextColor = UserState().isNight
          ? const Color(0xFFE0C097)
          : const Color(0xFF5D4037);
    }

    currentDraftId = widget.draft?.id ?? 'draft_${DateTime.now().microsecondsSinceEpoch}';

    if (entry != null) {
      _loadFromEntry(entry);
    } else {
      loadDraft(widget.draft);
    }

    // 初始化心情与信纸相关状态
    currentMoodIndex = entry?.moodIndex ?? widget.draft?.moodIndex ?? widget.moodIndex;
    currentIntensity = entry?.intensity ?? widget.draft?.intensity ?? widget.intensity;
    currentTag = entry?.tag ?? widget.draft?.tag ?? widget.tag;
    currentPaperStyle = entry?.paperStyle ?? 
                      widget.draft?.paperStyle ?? 
                      UserState().preferredPaperStyle.value;
    isImageGrid = entry?.isImageGrid ??
                  widget.draft?.isImageGrid ??
                  false;
    isMixedLayout = entry?.isMixedLayout ??
                    widget.draft?.isMixedLayout ??
                    (!isImageGrid && UserState().isVip.value); // 非会员默认关闭
    currentBookId = entry?.bookId ??
                    widget.bookId ??
                    widget.draft?.bookId ??
                    'default';
    
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
    _isInitializing = false;
    isModified = false;
    initialEditorStateJson = getEditorStateJson();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && blocks.isNotEmpty) {
        final firstText = blocks.whereType<TextBlock>().firstOrNull;
        if (firstText != null) {
          firstText.focusNode.requestFocus();
        }
      }
    });
  }

  void updateMoodQuote() {
    if (_fixedQuote != null && _fixedQuote!.isNotEmpty) {
      return;
    }
    if (currentMoodIndex == null || currentMoodIndex! < 0) {
      _fixedQuote = '从心出发，记录此刻的点滴...';
      return;
    }
    final mood = kMoods[currentMoodIndex!];
    _fixedQuote = DiaryUtils.getMoodQuote(mood.label);
  }

  void _loadFromEntry(DiaryEntry entry) {
    currentAnnotations = Map<String, String>.from(entry.annotations);
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
    if (blocks.whereType<TextBlock>().isEmpty) {
      final textBlock = TextBlock('', baseColor: currentTextColor);
      addFocusListener(textBlock);
      blocks.add(textBlock);
      blockKeys[textBlock.id] = GlobalKey();
    }
    weather = entry.weather;
    temp = entry.temp;
    customDate = entry.customDate;
    customTime = entry.customTime;
    replies = List<DiaryReply>.from(entry.replies); // 初始化回复内容
    currentPaperStyle = entry.paperStyle;
    isImageGrid = entry.isImageGrid;
    isMixedLayout = entry.isMixedLayout;
    currentBookId = entry.bookId ?? 'default';
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
    block.controller.addListener(() {
      if (!_isInitializing && !isModified) {
        setState(() {
          isModified = true;
        });
      }
    });
  }

  void loadDraft(DiaryDraft? customDraft) {
    currentAnnotations = {};
    final draft = customDraft?.blocks;
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
      if (blocks.whereType<TextBlock>().isEmpty) {
        final textBlock = TextBlock('', baseColor: currentTextColor);
        addFocusListener(textBlock);
        blocks.add(textBlock);
        blockKeys[textBlock.id] = GlobalKey();
        draftModified = true;
      }
      weather = customDraft?.weather;
      temp = customDraft?.temp;
      location = customDraft?.location;
      customDate = customDraft?.customDate;
      customTime = customDraft?.customTime;
      currentPaperStyle = customDraft?.paperStyle ?? 'classic';
      isImageGrid = customDraft?.isImageGrid ?? false;
      isMixedLayout = customDraft?.isMixedLayout ?? 
                      (!isImageGrid && UserState().isVip.value);
      currentBookId = customDraft?.bookId ?? 'default';

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

  Future<void> saveCurrentAsDraft() async {
    final content = blocks
        .whereType<TextBlock>()
        .map((b) => b.controller.text)
        .join('\n');

    final draft = DiaryDraft(
      id: currentDraftId,
      moodIndex: currentMoodIndex,
      intensity: currentIntensity,
      content: content,
      tag: currentTag,
      weather: weather,
      temp: temp,
      location: location,
      customDate: customDate,
      customTime: customTime,
      dateTime: entryDateTime,
      blocks: blocks.map((b) => b.toMap()).toList(),
      paperStyle: currentPaperStyle,
      isImageGrid: isImageGrid,
      isMixedLayout: isMixedLayout,
      bookId: currentBookId,
    );

    await UserState().saveDraftEntry(draft);
  }

  Future<void> onBlocksChanged() async {
    isModified = true;
    // 如果是编辑已有日记模式，不保存为全局新建草稿，避免污染新建草稿
    if (widget.entry != null) {
      return;
    }

    final content = blocks
        .whereType<TextBlock>()
        .map((b) => b.controller.text)
        .join('\n');

    final hasContent = content.trim().isNotEmpty || 
        blocks.whereType<ImageBlock>().isNotEmpty || 
        blocks.whereType<AudioBlock>().isNotEmpty ||
        currentMoodIndex != null ||
        currentTag != null;
        
    if (!hasContent) {
      return;
    }

    await saveCurrentAsDraft();
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
    // 立即触发触感反馈，提供点击确认感
    debugPrint("DIARY_EDITOR: 收到保存指令 (onSave called)");
    try {
      HapticFeedback.mediumImpact();
    } catch (_) {}

    final fullText = blocks
        .whereType<TextBlock>()
        .map((b) => b.controller.text)
        .join('\n');

    if (fullText.trim().isEmpty &&
        blocks.whereType<ImageBlock>().isEmpty &&
        blocks.whereType<AudioBlock>().isEmpty) {
      // 预先收起键盘，防止与弹窗冲突
      FocusScope.of(context).unfocus();
      if (isEmojiOpen) setState(() => isEmojiOpen = false);
      
      // 延迟到下一帧弹出，规避 Navigator 锁定问题
      Future.microtask(() {
        if (mounted) IslandAlert.show(context, message: '从心出发，总要留下点什么（日记内容不能为空哦）');
      });
      return false;
    }

    final hasMood = (currentMoodIndex != null && currentMoodIndex! >= 0) || (currentTag != null && currentTag!.isNotEmpty);
    if (!hasMood) {
      FocusScope.of(context).unfocus();
      if (isEmojiOpen) setState(() => isEmojiOpen = false);
      
      Future.microtask(() {
        if (mounted) IslandAlert.show(context, message: '先选个心情再出发吧~', icon: '✨');
      });
      return false;
    }

    try {
      final content = blocks
          .whereType<TextBlock>()
          .map((b) => b.controller.text)
          .join('\n');

      List<dynamic> achievements = [];

      if (widget.entry != null) {
        debugPrint("DIARY_EDITOR: 正在保存更新 (修改模式)...");
        // 修改模式
        final updatedEntry = DiaryEntry(
          id: widget.entry!.id,
          dateTime: entryDateTime ?? widget.entry!.dateTime,
          moodIndex: currentMoodIndex ?? 0,
          intensity: currentIntensity,
          content: content,
          tag: currentTag,
          weather: weather,
          temp: temp,
          location: location,
          customDate: customDate,
          blocks: blocks.map((b) => b.toMap()).toList(),
          replies: replies, 
          paperStyle: currentPaperStyle,
          isImageGrid: isImageGrid,
          isMixedLayout: isMixedLayout,
          annotations: currentAnnotations,
          bookId: currentBookId,
        );
        await UserState().updateDiary(updatedEntry);
        await UserState().deleteDraftEntry(currentDraftId);
        debugPrint("DIARY_EDITOR: 更新保存成功。");
      } else {
        debugPrint("DIARY_EDITOR: 正在创建新日记 (新建模式)...");
        // 新建模式
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
          dateTime: entryDateTime,
          blocks: blocks.map((b) => b.toMap()).toList(),
          paperStyle: currentPaperStyle,
          isImageGrid: isImageGrid,
          isMixedLayout: isMixedLayout,
          bookId: currentBookId,
        );
        achievements = await UserState().saveDiary(annotations: currentAnnotations);
        await UserState().deleteDraftEntry(currentDraftId);
        debugPrint("DIARY_EDITOR: 新日记保存成功，获得成就数量: ${achievements.length}");
      }

      if (mounted) {
        debugPrint("DIARY_EDITOR: 正在退出编辑器...");
        // 关键修复：调用方期望 bool? result，因此返回 true 表示保存成功
        // 成就弹窗通常由外部或全局监听处理，或者此处可以先存储成就数据
        Navigator.of(context).pop(true);
      }

      return true;
    } catch (e) {
      debugPrint("DIARY_EDITOR: 保存失败 -> $e");
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
          style: TextStyle(
            fontFamily: currentFontFamily,
            fontSize: currentFontSize,
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

      // 获取光标相对于滚动容器顶部的相对位置
      final Offset caretInScrollOffset = box.localToGlobal(
        Offset(caretOffset.dx, caretOffset.dy + 4),
        ancestor: scrollObject,
      );
      
      final double currentScroll = scrollController.offset;
      final double viewportHeight = scrollObject.size.height;

      // 考虑底部由于表情包/键盘导致的遮挡高度
      final double viewInsetsBottom = MediaQuery.of(context).viewInsets.bottom;
      final double panelHeight = isEmojiOpen ? math.max(viewInsetsBottom, keyboardHeight) : viewInsetsBottom;
      final double visibleViewportHeight = viewportHeight - panelHeight;
      
      // --- 核心优化：安全区逻辑 ---
      // 我们希望光标维持在 visibleViewport 的 15% 到 85% 之间
      final double caretY = caretInScrollOffset.dy;
      final double safeTop = visibleViewportHeight * 0.15;
      final double safeBottom = visibleViewportHeight * 0.85;

      double? targetScroll;

      if (caretY < safeTop) {
        // 1. 光标太靠上（或被页头挡住），将其滚回到 30% 位置
        targetScroll = currentScroll + caretY - (visibleViewportHeight * 0.30);
      } else if (caretY > safeBottom) {
        // 2. 光标太靠下（或被面板挡住），将其滚回到 60% 位置（露出上方上下文）
        targetScroll = currentScroll + caretY - (visibleViewportHeight * 0.60);
      }

      // 如果 targetScroll 不为空且有效，则执行平滑滚动
      if (targetScroll != null &&
          scrollController.hasClients &&
          scrollController.position.hasContentDimensions) {
        scrollController.animateTo(
          targetScroll.clamp(0.0, scrollController.position.maxScrollExtent),
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOutCubic,
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

  String initialEditorStateJson = '';

  String getEditorStateJson() {
    final blockMaps = blocks.map((b) {
      if (b is TextBlock) {
        return {
          'type': 'text',
          'text': b.controller.text,
          'attributes': (b.controller is DiaryTextEditingController)
              ? (b.controller as DiaryTextEditingController).attributes.map((a) => a.toMap()).toList()
              : [],
        };
      } else if (b is ImageBlock) {
        return {
          'type': 'image',
          'path': b.file.path,
        };
      } else if (b is AudioBlock) {
        return {
          'type': 'audio',
          'path': b.path,
          'name': b.name,
        };
      }
      return b.toMap();
    }).toList();

    final state = {
      'blocks': blockMaps,
      'moodIndex': currentMoodIndex,
      'intensity': currentIntensity,
      'tag': currentTag,
      'weather': weather,
      'temp': temp,
      'location': location,
      'customDate': customDate,
      'customTime': customTime,
      'paperStyle': currentPaperStyle,
      'isImageGrid': isImageGrid,
      'isMixedLayout': isMixedLayout,
      'bookId': currentBookId,
    };
    return json.encode(state);
  }
}
