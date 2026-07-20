import 'dart:math';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:island_diary/shared/widgets/diary_entry/mixins/diary_editor_sheets_mixin.dart';
import 'package:island_diary/features/record/presentation/widgets/editor/keyboard_follower.dart';
import 'package:island_diary/features/record/presentation/widgets/editor/animated_paper_background.dart';

import '../widgets/draft_save_dialog.dart';
import 'package:island_diary/features/record/domain/models/diary_entry.dart';
import 'package:island_diary/features/record/domain/models/diary_draft.dart';
import 'package:island_diary/features/record/domain/models/diary_book.dart';
import 'package:island_diary/shared/widgets/diary_entry/models/diary_block.dart';
import 'package:island_diary/core/state/user_state.dart';
import 'package:island_diary/shared/widgets/diary_entry/mixins/diary_editor_core_mixin.dart';
import 'package:island_diary/shared/widgets/diary_entry/mixins/diary_editor_media_mixin.dart';
import 'package:island_diary/shared/widgets/diary_entry/mixins/diary_editor_format_mixin.dart';
import 'package:island_diary/shared/widgets/diary_entry/mixins/diary_editor_insert_mixin.dart';
import 'package:island_diary/shared/widgets/diary_entry/utils/diary_utils.dart';
import '../widgets/editor/editor_header.dart';
import '../widgets/editor/editor_content_list.dart';
import '../widgets/editor/editor_bottom_bar.dart';

class DiaryEditorPage extends StatefulWidget {
  final int? moodIndex;
  final double intensity;
  final String? tag;
  final DiaryEntry? entry;
  final DateTime? initialDate;
  final String? bookId; // 新增：默认归属的书籍ID
  final DiaryDraft? draft; // 新增：草稿恢复
  const DiaryEditorPage({
    super.key,
    this.moodIndex,
    this.intensity = 5.0,
    this.tag,
    this.entry,
    this.initialDate,
    this.bookId,
    this.draft,
  });
  @override
  State<DiaryEditorPage> createState() => _DiaryEditorPageState();
}

class _DiaryEditorPageState extends State<DiaryEditorPage>
    with
        DiaryEditorCoreMixin<DiaryEditorPage>,
        DiaryEditorMediaMixin<DiaryEditorPage>,
        DiaryEditorFormatMixin<DiaryEditorPage>,
        DiaryEditorInsertMixin<DiaryEditorPage>,
        DiaryEditorSheetsMixin {
  @override
  void initState() {
    super.initState();
    initializeEditor(entry: widget.entry, initialDate: widget.initialDate);
  }

  // didChangeDependencies 监听键盘高度变化，仅在高度真正增大时才 setState
  // 这样 build() 不订阅 viewInsets，键盘动画期间父级完全不重建
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final double inset = MediaQuery.viewInsetsOf(context).bottom;
    if (inset > 100 && inset > keyboardHeight) {
      final bool isFirstPop = keyboardHeight == 0; // 只在首次弹起时触发动画
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && inset > keyboardHeight) {
          setState(() => keyboardHeight = inset);

          // 仅在键盘初次弹起时，顺势将页面往上顶，避免每帧重复调用 animateTo 导致卡顿
          if (isFirstPop && scrollController.hasClients) {
            final double headerHeight = 160.0;
            if (scrollController.offset < headerHeight) {
              final targetOffset = headerHeight.clamp(
                0.0,
                scrollController.position.maxScrollExtent,
              );
              if (targetOffset > scrollController.offset) {
                scrollController.animateTo(
                  targetOffset,
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeOutCubic,
                );
              }
            }
          }
        }
      });
    } else if (inset < 10 && keyboardHeight > 0) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          setState(() => keyboardHeight = 0);
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<String>(
      valueListenable: UserState().themeMode,
      builder: (context, themeMode, _) {
        final bool isNight = UserState().isNight;
        final Color accentColor = DiaryUtils.getAccentColor(
          currentPaperStyle,
          isNight,
        );
        final themeId = UserState().selectedIslandThemeId.value;
        final Color bgColor = isNight
            ? const Color(0xFF121212)
            : (themeId == 'cotton_candy' && currentPaperStyle == 'classic'
                  ? const Color(0xFFFBF3E9)
                  : const Color(0xFFFAF8F5));

        return PopScope(
          canPop: false,
          onPopInvokedWithResult: (didPop, result) {
            if (didPop) return;
            _handleBack(context);
          },
          child: Scaffold(
            resizeToAvoidBottomInset: false,
            backgroundColor: bgColor,
            body: Stack(
              children: [
                // 1. 信纸底色层与手绘边框装饰 (带切换扩散动画)
                Positioned.fill(
                  child: AnimatedPaperBackground(
                    paperStyle: currentPaperStyle,
                    bgColor: bgColor,
                    isNight: isNight,
                    accentColor: accentColor,
                  ),
                ),

                // 2. 主编辑区 (文字与图片块)
                Builder(
                  builder: (context) {
                    final bool hasTags = currentTags
                        .where(
                          (t) =>
                              !t.startsWith('mood:') &&
                              !t.startsWith('mood_icon:'),
                        )
                        .isNotEmpty;
                    final bool hasImages =
                        !isMixedLayout &&
                        blocks.whereType<ImageBlock>().isNotEmpty;

                    double baseBottomBarHeight = 46.0 + 32.0; // 46工具栏 + 32收纳至胶囊
                    if (hasTags) {
                      baseBottomBarHeight +=
                          22.0 + 12.0; // 22标签高度 + 12期望间隙（控制图片与标签之间的留白）
                    }
                    if (hasImages) {
                      baseBottomBarHeight += 50.0;
                    }

                    final double toolbarOnlyHeight = baseBottomBarHeight - 32.0;

                    final double bottomInset = MediaQuery.viewInsetsOf(
                      context,
                    ).bottom;
                    final double bottomBounds =
                        (isEmojiOpen || isColorPickerOpen || isImagePickerOpen)
                        ? max(
                                keyboardHeight,
                                MediaQuery.paddingOf(context).bottom,
                              ) +
                              toolbarOnlyHeight
                        : bottomInset +
                              toolbarOnlyHeight +
                              MediaQuery.paddingOf(context).bottom;

                    return Positioned(
                      top: MediaQuery.paddingOf(context).top + 56,
                      left: 0,
                      right: 0,
                      bottom: bottomBounds,
                      child: GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: () {
                          FocusScope.of(context).unfocus();
                          if (isEmojiOpen) toggleEmoji();
                        },
                        child: Center(
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 800),
                            child: CustomScrollView(
                              clipBehavior: Clip.hardEdge,
                              controller: scrollController,
                              physics: const BouncingScrollPhysics(),
                              slivers: [
                                // 顶部留白，给内容留出适当呼吸感
                                const SliverToBoxAdapter(
                                  child: SizedBox(height: 0),
                                ),
                                // 编辑主体：内容块列表
                                EditorContentList(
                                  blocks: blocks,
                                  blockKeys: blockKeys,
                                  isMixedLayout: isMixedLayout,
                                  imageLayoutStyle: imageLayoutStyle,
                                  isEmojiOpen:
                                      isEmojiOpen ||
                                      isColorPickerOpen ||
                                      isImagePickerOpen,
                                  isNight: isNight,
                                  paperStyle: currentPaperStyle,
                                  accentColor: accentColor,
                                  bottomPadding: 8,
                                  currentMoodIndex: currentMoodIndex,
                                  currentTag: currentTag,
                                  weather: weather,
                                  temp: temp,
                                  onWeatherTap: onWeatherClick,
                                  location: location,
                                  onLocationTap: onLocationClick,
                                  onClearLocation: () {
                                    setState(() {
                                      location = null;
                                    });
                                    onBlocksChanged();
                                  },
                                  dateTime: entryDateTime ?? DateTime.now(),
                                  onDateTap: onDateClick,
                                  onClearWeather: () {
                                    setState(() {
                                      weather = null;
                                      temp = null;
                                    });
                                    onBlocksChanged();
                                  },
                                  onClearMood: () {
                                    setState(() {
                                      currentMoodIndex = null;
                                      currentTags = currentTags
                                          .where(
                                            (t) =>
                                                !t.startsWith('mood:') &&
                                                !t.startsWith('mood_icon:'),
                                          )
                                          .toList();
                                      updateMoodQuote();
                                    });
                                    onBlocksChanged();
                                  },
                                  onRemoveImage: removeImage,
                                  onDeleteAtStart: handleBackspaceAtStart,
                                  onShowPreview: showImagePreview,
                                  onEditImageBlock: editImageBlock,
                                  onMoodSelected: (index) {
                                    setState(() {
                                      currentMoodIndex = index;
                                      updateMoodQuote();
                                    });
                                    onBlocksChanged();
                                  },
                                  onCustomTap: showCustomMoodPicker,
                                  onRemoveTag: (tagToRemove) {
                                    setState(() {
                                      currentTags = currentTags
                                          .where((t) => t != tagToRemove)
                                          .toList();
                                    });
                                    onBlocksChanged();
                                  },
                                  annotations: currentAnnotations,
                                  onAddAnnotation:
                                      ({
                                        key,
                                        required blockIndex,
                                        required start,
                                        required end,
                                        required selectedText,
                                      }) {
                                        showAnnotationSheet(
                                          key: key,
                                          blockIndex: blockIndex,
                                          start: start,
                                          end: end,
                                          selectedText: selectedText,
                                        );
                                      },
                                  onDeleteAnnotation: (key) {
                                    setState(() {
                                      currentAnnotations.remove(key);
                                    });
                                  },
                                ),
                                // 底部留白
                                SliverToBoxAdapter(
                                  child: SizedBox(
                                    height:
                                        100 +
                                        baseBottomBarHeight +
                                        MediaQuery.paddingOf(
                                          context,
                                        ).bottom, // 恢复合理的底部安全余量留白，确保最后一行能完全滚出悬浮底部工具栏
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),

                // 2.5 固定页头层
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  child: Container(
                    color: Colors.transparent,
                    child: SafeArea(
                      bottom: false,
                      child: Center(
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 800),
                          child: EditorHeader(
                            paperStyle: currentPaperStyle,
                            isNight: isNight,
                            isDraft: widget.entry == null,
                            onBack: () => _handleBack(context),
                            onSave: onSave,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),

                // 4. 底部工具栏
                KeyboardFollower(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      ValueListenableBuilder<List<DiaryBook>>(
                        valueListenable: UserState().savedBooks,
                        builder: (context, books, _) {
                          final currentBook = books.firstWhere(
                            (b) => b.id == currentBookId,
                            orElse: () => DiaryBook(id: 'default', name: '未分类'),
                          );
                          return Transform.translate(
                            offset: const Offset(0, -12), // 视觉上往上嵌入封面图片区域
                            child: Padding(
                              padding: const EdgeInsets.only(
                                top: 4.0,
                                bottom: 2.0,
                              ),
                              child: GestureDetector(
                                onTap: showBookSelector,
                                child: Container(
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(20),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withValues(
                                          alpha: 0.05,
                                        ),
                                        blurRadius: 6,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(20),
                                    child: Stack(
                                      children: [
                                        Positioned.fill(
                                          child: BackdropFilter(
                                            filter: ImageFilter.blur(
                                              sigmaX: 12.0,
                                              sigmaY: 12.0,
                                            ),
                                            child: const SizedBox.shrink(),
                                          ),
                                        ),
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 14,
                                            vertical: 6,
                                          ),
                                          decoration: BoxDecoration(
                                            color: isNight
                                                ? const Color(
                                                    0xFF2C2E30,
                                                  ).withValues(alpha: 0.4)
                                                : Colors.white.withValues(
                                                    alpha: 0.4,
                                                  ),
                                            borderRadius: BorderRadius.circular(
                                              20,
                                            ),
                                            border: Border.all(
                                              color: isNight
                                                  ? Colors.white.withValues(
                                                      alpha: 0.08,
                                                    )
                                                  : const Color(
                                                      0xFFE6E1D5,
                                                    ).withValues(alpha: 0.8),
                                            ),
                                          ),
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Icon(
                                                Icons.menu_book_rounded,
                                                size: 14,
                                                color: isNight
                                                    ? const Color(0xFFFFB74D)
                                                    : const Color(0xFFD4A373),
                                              ),
                                              const SizedBox(width: 6),
                                              Text(
                                                '收纳至：${currentBook.name}',
                                                style: TextStyle(
                                                  fontSize: 11,
                                                  fontWeight: FontWeight.bold,
                                                  color: isNight
                                                      ? Colors.white70
                                                      : Colors.black87,
                                                  fontFamily:
                                                      UserState()
                                                              .selectedIslandThemeId
                                                              .value ==
                                                          'lego'
                                                      ? 'SweiFistLeg'
                                                      : 'LXGWWenKai',
                                                ),
                                              ),
                                              const SizedBox(width: 4),
                                              Icon(
                                                Icons
                                                    .keyboard_arrow_down_rounded,
                                                size: 14,
                                                color: isNight
                                                    ? Colors.white30
                                                    : Colors.black38,
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ), // Transform.translate 结束
                          );
                        },
                      ),
                      EditorBottomBar(
                        isEmojiOpen: isEmojiOpen,
                        isNight: isNight,
                        paperStyle: currentPaperStyle,
                        accentColor: accentColor,
                        currentBottomHeight: keyboardHeight,
                        blocks: blocks,
                        isMixedLayout: isMixedLayout,
                        onEmojiToggle: toggleEmoji,
                        onImagePick: onImageButtonPressed,
                        onColorClick: showUnifiedColorPicker,
                        onBgColorClick: showPaperPicker,
                        onLocationClick: onLocationClick,
                        onFontSizeClick: showTextStylePicker,
                        onFontClick: showTextStylePicker,
                        onDateClick: onDateClick,
                        onTimeClick: onTimeClick,
                        onWeatherClick: onWeatherClick,
                        onMoreClick: onMoreClick,
                        onClose: () => Navigator.of(context).pop(),
                        onSave: onSave,
                        onTagClick: onTagClick,
                        onMusicPick: onMusicButtonPressed,
                        currentTags: currentTags
                            .where(
                              (t) =>
                                  !t.startsWith('mood:') &&
                                  !t.startsWith('mood_icon:'),
                            )
                            .toList(),
                        onRemoveTag: (tag) {
                          setState(() {
                            currentTags = currentTags
                                .where((t) => t != tag)
                                .toList();
                          });
                          onBlocksChanged();
                        },
                        onEmojiSelected: onEmojiSelected,
                        onEmojiBackspace: handleEmojiBackspace,
                        onEmojiSend: handleEmojiSend,
                        onCustomEmojiSelected: handleCustomEmojiSelected,
                        onRemoveImage: removeImage,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void onMoreClick() {
    showMoreBottomSheet();
  }

  void _handleBack(BuildContext context) async {
    final bool isActuallyModified =
        initialEditorStateJson != getEditorStateJson();

    if (!isActuallyModified) {
      Navigator.of(context).pop(false);
      return;
    }

    final shouldSave = await DraftSaveDialog.show(context);

    if (shouldSave == true) {
      await saveCurrentAsDraft();
      if (context.mounted) {
        Navigator.of(context).pop(false);
      }
    } else if (shouldSave == false) {
      if (widget.entry == null) {
        UserState().deleteDraftEntry(currentDraftId);
      }
      if (context.mounted) {
        Navigator.of(context).pop(false);
      }
    }
  }
}
