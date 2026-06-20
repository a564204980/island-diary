import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:island_diary/features/record/domain/models/diary_entry.dart';
import 'package:island_diary/features/record/domain/models/diary_draft.dart';
import 'package:island_diary/features/record/domain/models/diary_book.dart';
import 'package:island_diary/shared/widgets/diary_entry/models/diary_block.dart';
import 'package:island_diary/shared/widgets/diary_entry/components/diary_painters.dart';
import 'package:island_diary/core/state/user_state.dart';
import 'package:island_diary/shared/widgets/diary_entry/mixins/diary_editor_core_mixin.dart';
import 'package:island_diary/shared/widgets/diary_entry/mixins/diary_editor_media_mixin.dart';
import 'package:island_diary/shared/widgets/diary_entry/mixins/diary_editor_format_mixin.dart';
import 'package:island_diary/shared/widgets/diary_entry/mixins/diary_editor_insert_mixin.dart';
import 'package:island_diary/shared/widgets/diary_entry/utils/diary_utils.dart';
import 'package:island_diary/shared/widgets/diary_entry/components/diary_bottom_sheet.dart';
import '../widgets/editor/editor_header.dart';
import '../widgets/editor/editor_content_list.dart';
import '../widgets/editor/editor_bottom_bar.dart';
import 'package:island_diary/shared/widgets/mood_picker/custom_mood_picker_popup.dart';

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
        DiaryEditorInsertMixin<DiaryEditorPage> {
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
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && inset > keyboardHeight) {
          setState(() => keyboardHeight = inset);
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

        final double safeArea = MediaQuery.paddingOf(context).bottom;
        final double tagsHeight = currentTags.where((t) => !t.startsWith('mood:')).isNotEmpty ? 40.0 : 0.0;
        final double imagesHeight = !isMixedLayout && blocks.any((b) => b is ImageBlock) ? 68.0 : 0.0;
        final double bottomOffset = keyboardHeight + 98.0 + safeArea + tagsHeight + imagesHeight;

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
                // 1. 信纸底色层与手绘边框装饰
                Positioned.fill(
                  child: Container(
                    color: bgColor,
                    child: Stack(
                      children: [
                        if (currentPaperStyle.startsWith('note') || (currentPaperStyle == 'classic' && UserState().selectedIslandThemeId.value == 'cotton_candy'))
                          Positioned.fill(
                            child: Image.asset(
                              currentPaperStyle == 'classic'
                                  ? (isNight
                                      ? 'assets/images/theme/miamhuadao/note/mianhuadao_note_defalut_night_bg.png'
                                      : 'assets/images/theme/miamhuadao/note/mianhuadao_note_defalut_bg.png')
                                  : DiaryUtils.getPaperBackgroundPath(currentPaperStyle, isNight),
                              fit: BoxFit.cover,
                            ),
                          ),
                        Positioned.fill(
                          child: CustomPaint(
                            painter: PaperBackgroundPainter(
                              style: currentPaperStyle,
                              isNight: isNight && 
                                  !currentPaperStyle.startsWith('note') && 
                                  !(currentPaperStyle == 'classic' && UserState().selectedIslandThemeId.value == 'cotton_candy'),
                              accentColor: accentColor,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // 2. 主编辑区 (文字与图片块)
                Positioned(
                  top: MediaQuery.paddingOf(context).top + 56,
                  left: 0,
                  right: 0,
                  bottom: bottomOffset,
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
                              isImageGrid: isImageGrid,
                              isEmojiOpen:
                                  isEmojiOpen ||
                                  isColorPickerOpen ||
                                  isImagePickerOpen,
                              isNight: isNight,
                              paperStyle: currentPaperStyle,
                              accentColor: accentColor,
                              bottomPadding: 16,
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
                                  currentTags = currentTags.where((t) => !t.startsWith('mood:')).toList();
                                  updateMoodQuote();
                                });
                                onBlocksChanged();
                              },
                              onRemoveImage: removeImage,
                              onDeleteAtStart: handleBackspaceAtStart,
                              onShowPreview: showImagePreview,
                              onMoodSelected: (index) {
                                setState(() {
                                  currentMoodIndex = index;
                                  updateMoodQuote();
                                });
                                onBlocksChanged();
                              },
                              onCustomTap: _showCustomMoodPicker,
                              onRemoveTag: (tagToRemove) {
                                setState(() {
                                  currentTags = currentTags.where((t) => t != tagToRemove).toList();
                                });
                                onBlocksChanged();
                              },
                              annotations: currentAnnotations,
                              onAddAnnotation: ({key, required blockIndex, required start, required end, required selectedText}) {
                                _showAnnotationSheet(
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
                            const SliverToBoxAdapter(
                              child: SizedBox(
                                height: 40,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
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
                _KeyboardFollower(
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
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 8.0),
                            child: GestureDetector(
                              onTap: _showBookSelector,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 14,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: isNight
                                      ? const Color(0xFF2C2E30).withValues(alpha: 0.9)
                                      : Colors.white.withValues(alpha: 0.9),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                    color: isNight
                                        ? Colors.white.withValues(alpha: 0.08)
                                        : const Color(0xFFE6E1D5),
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withValues(alpha: 0.05),
                                      blurRadius: 6,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
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
                                        fontFamily: UserState().selectedIslandThemeId.value == 'lego'
                                            ? 'SweiFistLeg'
                                            : 'LXGWWenKai',
                                      ),
                                    ),
                                    const SizedBox(width: 4),
                                    Icon(
                                      Icons.keyboard_arrow_down_rounded,
                                      size: 14,
                                      color: isNight ? Colors.white30 : Colors.black38,
                                    ),
                                  ],
                                ),
                              ),
                            ),
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
                        currentTags: currentTags.where((t) => !t.startsWith('mood:')).toList(),
                        onRemoveTag: (tag) {
                          setState(() {
                            currentTags = currentTags.where((t) => t != tag).toList();
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

  void _showBookSelector() {
    final bool isNight = UserState().isNight;
    final String fontFamily = UserState().selectedIslandThemeId.value == 'lego'
        ? 'SweiFistLeg'
        : 'LXGWWenKai';
    
    void createNewBook() {
      final TextEditingController nameController = TextEditingController();
      showDialog(
        context: context,
        builder: (ctx) {
          return AlertDialog(
            backgroundColor: isNight ? const Color(0xFF2C2E30) : Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: Text(
              '新建日记本',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: isNight ? Colors.white : Colors.black87,
                fontFamily: fontFamily,
              ),
            ),
            content: TextField(
              controller: nameController,
              autofocus: true,
              decoration: InputDecoration(
                hintText: '输入日记本名称...',
                hintStyle: TextStyle(
                  color: isNight ? Colors.white38 : Colors.black38,
                  fontSize: 14,
                  fontFamily: fontFamily,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(
                    color: isNight ? Colors.white10 : Colors.black12,
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(
                    color: Color(0xFFD4A373),
                  ),
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              ),
              style: TextStyle(
                color: isNight ? Colors.white : Colors.black87,
                fontFamily: fontFamily,
                fontSize: 14,
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: Text(
                  '取消',
                  style: TextStyle(
                    color: isNight ? Colors.white54 : Colors.black54,
                    fontFamily: fontFamily,
                  ),
                ),
              ),
              TextButton(
                onPressed: () async {
                  final name = nameController.text.trim();
                  if (name.isNotEmpty) {
                    final newBook = DiaryBook(name: name);
                    await UserState().createBook(newBook);
                    setState(() {
                      currentBookId = newBook.id;
                    });
                    onBlocksChanged();
                    if (ctx.mounted) {
                      Navigator.pop(ctx);
                    }
                    if (context.mounted) {
                      Navigator.pop(context);
                    }
                  }
                },
                child: Text(
                  '创建',
                  style: TextStyle(
                    color: const Color(0xFFD4A373),
                    fontWeight: FontWeight.bold,
                    fontFamily: fontFamily,
                  ),
                ),
              ),
            ],
          );
        },
      );
    }

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      showDragHandle: false,
      builder: (context) {
        return DiaryBottomSheet(
          paperStyle: currentPaperStyle,
          showDragHandle: true,
          isDiary: false,
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 12,
            bottom: 20 + MediaQuery.of(context).padding.bottom,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '选择归属的书籍',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: isNight ? Colors.white : Colors.black87,
                      fontFamily: fontFamily,
                    ),
                  ),
                  GestureDetector(
                    onTap: createNewBook,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.add_rounded,
                          size: 16,
                          color: Color(0xFFD4A373),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '新建',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFFD4A373),
                            fontFamily: fontFamily,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                '这篇日记会收纳到选中的书籍中',
                style: TextStyle(
                  fontSize: 11.5,
                  color: isNight ? Colors.white38 : Colors.black38,
                  fontFamily: fontFamily,
                ),
              ),
              const SizedBox(height: 16),
              ValueListenableBuilder<List<DiaryBook>>(
                valueListenable: UserState().savedBooks,
                builder: (context, books, _) {
                  return Column(
                    children: [
                      if (books.isEmpty)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 24),
                          child: Column(
                            children: [
                              Icon(
                                Icons.library_books_outlined,
                                size: 36,
                                color: isNight ? Colors.white24 : Colors.black26,
                              ),
                              const SizedBox(height: 10),
                              Text(
                                '暂无日记本',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontFamily: fontFamily,
                                  color: isNight ? Colors.white38 : Colors.black45,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '可到「岁月成书」页面创建自己的日记本',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontFamily: fontFamily,
                                  color: isNight ? Colors.white24 : Colors.black26,
                                ),
                              ),
                              const SizedBox(height: 16),
                              OutlinedButton.icon(
                                onPressed: createNewBook,
                                style: OutlinedButton.styleFrom(
                                  side: const BorderSide(color: Color(0xFFD4A373), width: 1),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                ),
                                icon: const Icon(
                                  Icons.add_rounded,
                                  size: 16,
                                  color: Color(0xFFD4A373),
                                ),
                                label: Text(
                                  '直接在此创建',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontFamily: fontFamily,
                                    color: const Color(0xFFD4A373),
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        )
                      else
                        ...books.map<Widget>((book) {
                        final bool isSelected = book.id == currentBookId;
                      // 选中浅橙底，未选中极其轻微的透明度背景
                      final Color itemBgColor = isSelected
                          ? (isNight ? const Color(0xFF2C241E) : const Color(0xFFFFF5EA))
                          : (isNight ? Colors.white.withValues(alpha: 0.02) : Colors.black.withValues(alpha: 0.015));
                      // 未选中图标使用灰蓝色，选中则为主题橙色
                      final Color iconColor = isSelected
                          ? const Color(0xFFD4A373)
                          : (isNight ? const Color(0xFF5E7588) : const Color(0xFF8BA3B5));
                      
                      return Container(
                        margin: const EdgeInsets.only(bottom: 10),
                        decoration: BoxDecoration(
                          color: itemBgColor,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isSelected
                                ? (isNight ? const Color(0xFF4A3419) : const Color(0xFFFFE2C2))
                                : (isNight ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.04)),
                            width: 1,
                          ),
                        ),
                        child: ListTile(
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
                          leading: Icon(
                            Icons.book_rounded,
                            color: iconColor,
                            size: 20,
                          ),
                          title: Text(
                            book.name,
                            style: TextStyle(
                              color: isSelected
                                  ? (isNight ? const Color(0xFFFFCC99) : const Color(0xFF8E5A30))
                                  : (isNight ? Colors.white70 : Colors.black87),
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                              fontFamily: fontFamily,
                              fontSize: 14,
                            ),
                          ),
                          trailing: isSelected
                              ? Container(
                                  width: 24,
                                  height: 24,
                                  decoration: const BoxDecoration(
                                    color: Color(0xFFFFEAD2),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.check_rounded,
                                    size: 14,
                                    color: Color(0xFFD4A373),
                                  ),
                                )
                              : null,
                          onTap: () {
                            setState(() {
                              currentBookId = book.id;
                            });
                            onBlocksChanged();
                            Navigator.pop(context);
                          },
                        ),
                      );
                        }),
                    ],
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _showCustomMoodPicker() async {
    final result = await Navigator.push<Map<String, dynamic>>(
      context,
      MaterialPageRoute(
        builder: (context) => CustomMoodPickerPage(
          paperStyle: currentPaperStyle,
          isNight: UserState().isNight,
        ),
      ),
    );
    
    if (result != null && mounted) {
      setState(() {
        currentMoodIndex = result['index'];
        currentIntensity = result['intensity'];
        if (result['tag'] != null) {
          final generalTags = currentTags.where((t) => !t.startsWith('mood:') && !t.startsWith('mood_icon:')).toList();
          if (result['customMoodIcon'] != null) {
            currentTags = ['mood:${result['tag']}', 'mood_icon:${result['customMoodIcon']}', ...generalTags];
          } else {
            currentTags = ['mood:${result['tag']}', ...generalTags];
          }
        }
        updateMoodQuote();
      });
      onBlocksChanged();
    }
  }

  void onMoreClick() {
    _showMoreBottomSheet();
  }

  void _showMoreBottomSheet() {
    final bool isNight = UserState().isNight;
    final Color accentColor = DiaryUtils.getAccentColor(
      currentPaperStyle,
      isNight,
    );
    final Color textColor = DiaryUtils.getInkColor(
      currentPaperStyle,
      isNight,
    ).withValues(alpha: 0.9);
    final String fontFamily = UserState().selectedIslandThemeId.value == 'lego'
        ? 'SweiFistLeg'
        : 'LXGWWenKai';
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      showDragHandle: false,
      builder: (context) => DiaryBottomSheet(
        paperStyle: currentPaperStyle,
        showDragHandle: true,
        padding: const EdgeInsets.fromLTRB(24, 8, 24, 16),
        child: StatefulBuilder(
          builder: (context, setModalState) {
            return Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "更多工具",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: textColor,
                    fontFamily: fontFamily,
                  ),
                ),
                const SizedBox(height: 20),
                // 智能排版 (开发中)
                _buildMoreMenuItem(
                  icon: Icons.auto_awesome_motion_rounded,
                  title: "智能排版 (开发中)",
                  subtitle: "根据心情自动调整内容布局",
                  trailing: Icon(
                    Icons.lock_outline_rounded,
                    size: 20,
                    color: textColor.withValues(alpha: 0.3),
                  ),
                  accentColor: accentColor,
                  textColor: textColor,
                  onTap: () {},
                ),
                const SizedBox(height: 12),
                _buildMoreMenuItem(
                  icon: Icons.mood_rounded,
                  title: "管理自定义心情",
                  subtitle: "自定义表情、灵感标签与最近记录",
                  trailing: Icon(
                    Icons.chevron_right_rounded,
                    size: 20,
                    color: textColor.withValues(alpha: 0.3),
                  ),
                  accentColor: accentColor,
                  textColor: textColor,
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => CustomMoodPickerPage(
                          paperStyle: currentPaperStyle,
                          isNight: UserState().isNight,
                          isFromEditor: false,
                        ),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 12),
                
                // 新增：图片压缩管理卡片
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  decoration: BoxDecoration(
                    color: accentColor.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: accentColor.withValues(alpha: 0.1),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(Icons.image_aspect_ratio_rounded, color: accentColor, size: 18),
                              ),
                              const SizedBox(width: 12),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    "上传前自动压缩图片",
                                    style: TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.bold,
                                      color: textColor,
                                      fontFamily: fontFamily,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    "开启后将有效节省云端空间",
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: textColor.withValues(alpha: 0.5),
                                      fontFamily: fontFamily,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          Transform.scale(
                            scale: 0.85,
                            child: Switch(
                              value: UserState().isImageCompressEnabled.value,
                              activeColor: accentColor,
                              onChanged: (val) {
                                setModalState(() {
                                  UserState().setImageCompressEnabled(val);
                                });
                              },
                            ),
                          ),
                        ],
                      ),
                      if (UserState().isImageCompressEnabled.value) ...[
                        const SizedBox(height: 10),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          child: Row(
                            children: [
                              Text(
                                "压缩质量",
                                style: TextStyle(
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.bold,
                                  color: textColor.withValues(alpha: 0.7),
                                  fontFamily: fontFamily,
                                ),
                              ),
                              Expanded(
                                child: SliderTheme(
                                  data: SliderThemeData(
                                    trackHeight: 3,
                                    activeTrackColor: accentColor,
                                    inactiveTrackColor: accentColor.withValues(alpha: 0.15),
                                    thumbColor: accentColor,
                                    overlayColor: accentColor.withValues(alpha: 0.1),
                                    valueIndicatorColor: accentColor,
                                    valueIndicatorTextStyle: const TextStyle(color: Colors.white, fontSize: 10),
                                  ),
                                  child: Slider(
                                    value: UserState().imageCompressQuality.value.toDouble(),
                                    min: 30,
                                    max: 100,
                                    divisions: 70, // 30% - 100% 步进为 1%
                                    label: "${UserState().imageCompressQuality.value}%",
                                    onChanged: (val) {
                                      setModalState(() {
                                        UserState().setImageCompressQuality(val.round());
                                      });
                                    },
                                  ),
                                ),
                              ),
                              Text(
                                "${UserState().imageCompressQuality.value}%",
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                  color: accentColor,
                                  fontFamily: fontFamily,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 20),
              ],
            );
          },
        ),
      ),
    ).then((_) {
      if (mounted) {
        FocusManager.instance.primaryFocus?.unfocus();
      }
    });
  }

  Widget _buildMoreMenuItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required Widget trailing,
    required Color accentColor,
    required Color textColor,
    VoidCallback? onTap,
  }) {
    final String fontFamily = UserState().selectedIslandThemeId.value == 'lego'
        ? 'SweiFistLeg'
        : 'LXGWWenKai';
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: accentColor.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: accentColor.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: accentColor, size: 20),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: textColor,
                      fontFamily: fontFamily,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 12,
                      color: textColor.withValues(alpha: 0.5),
                      fontFamily: fontFamily,
                    ),
                  ),
                ],
              ),
            ),
            trailing,
          ],
        ),
      ),
    );
  }

  static const List<Map<String, String>> _annotationColors = [
    {'name': '经典黄', 'value': '#F7E5B4'},
    {'name': '柔和粉', 'value': '#F7DAD3'},
    {'name': '天空灰', 'value': '#DFE5E6'},
  ];

  void _showAnnotationSheet({
    String? key,
    int? blockIndex,
    int? start,
    int? end,
    String? selectedText,
  }) {
    final bool isEdit = key != null;
    final String actualKey = key ?? "${blockIndex}_${start}_$end";
    
    Map<String, dynamic>? annData;
    if (isEdit) {
      final jsonStr = currentAnnotations[actualKey] ?? '';
      try {
        annData = jsonDecode(jsonStr);
      } catch (_) {}
    }
    
    final String initialText = annData?['comment'] ?? (isEdit ? currentAnnotations[actualKey] ?? '' : '');
    final String initialColor = annData?['colorHex'] ?? '#F7E5B4';
    final String actualSelectedText = annData?['selectedText'] ?? selectedText ?? '';
    
    final textController = TextEditingController(text: initialText);
    String selectedColorHex = initialColor;
 
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      showDragHandle: false,
      builder: (context) {
        final isNight = UserState().isNight;
        final inkColor = DiaryUtils.getInkColor(currentPaperStyle, isNight);

        return StatefulBuilder(
          builder: (context, setSheetState) {
            return DiaryBottomSheet(
              paperStyle: currentPaperStyle,
              showDragHandle: true,
              child: Padding(
                padding: EdgeInsets.only(
                  bottom: MediaQuery.of(context).viewInsets.bottom,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.edit_note_rounded,
                          color: inkColor.withValues(alpha: 0.8),
                          size: 24,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          isEdit ? "修改批注" : "添加批注",
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: inkColor,
                            fontFamily: 'LXGWWenKai',
                          ),
                        ),
                      ],
                    ),
                    if (actualSelectedText.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        decoration: BoxDecoration(
                          color: isNight ? Colors.white.withValues(alpha: 0.03) : const Color(0xFFF9F6EE),
                          borderRadius: BorderRadius.circular(12),
                          border: Border(
                            left: BorderSide(
                              color: Color(int.parse(selectedColorHex.replaceFirst('#', '0xFF'))),
                              width: 4.5,
                            ),
                          ),
                        ),
                        child: Text(
                          "“$actualSelectedText”",
                          style: TextStyle(
                            fontSize: 14,
                            color: inkColor.withValues(alpha: 0.65),
                            fontStyle: FontStyle.italic,
                            fontFamily: 'LXGWWenKai',
                            height: 1.5,
                          ),
                        ),
                      ),
                    ],
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        color: isNight ? Colors.white.withValues(alpha: 0.03) : Colors.black.withValues(alpha: 0.015),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: TextField(
                        controller: textController,
                        maxLines: 3,
                        minLines: 1,
                        style: TextStyle(color: inkColor, fontSize: 15, fontFamily: 'LXGWWenKai'),
                        decoration: InputDecoration(
                          hintText: "写下关于这段文字的所思所想...",
                          hintStyle: TextStyle(color: inkColor.withValues(alpha: 0.35)),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        autofocus: true,
                      ),
                    ),
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        Text(
                          "批注底色",
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: inkColor.withValues(alpha: 0.7),
                            fontFamily: 'LXGWWenKai',
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: _annotationColors.map((colorMap) {
                        final hex = colorMap['value']!;
                        final isSelected = selectedColorHex == hex;
                        final color = Color(int.parse(hex.replaceFirst('#', '0xFF')));

                        return GestureDetector(
                          onTap: () {
                            setSheetState(() {
                              selectedColorHex = hex;
                            });
                          },
                          child: Padding(
                            padding: const EdgeInsets.only(right: 16.0),
                            child: Container(
                              width: 38,
                              height: 38,
                              decoration: BoxDecoration(
                                color: color,
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: isSelected
                                      ? (isNight ? Colors.white : const Color(0xFF333333))
                                      : (isNight ? Colors.white24 : Colors.black.withValues(alpha: 0.08)),
                                  width: isSelected ? 3.0 : 1.0,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: color.withValues(alpha: isSelected ? 0.4 : 0.1),
                                    blurRadius: isSelected ? 8 : 4,
                                    spreadRadius: isSelected ? 1 : 0,
                                  ),
                                ],
                              ),
                              child: isSelected
                                  ? const Icon(
                                      Icons.check_rounded,
                                      size: 18,
                                      color: Color(0xFF333333),
                                    )
                                  : null,
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 28),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          onPressed: () {
                            FocusManager.instance.primaryFocus?.unfocus();
                            Navigator.pop(context);
                          },
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: Text(
                            "取消",
                            style: TextStyle(
                              color: inkColor.withValues(alpha: 0.6),
                              fontSize: 15,
                              fontFamily: 'LXGWWenKai',
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        ElevatedButton(
                          onPressed: () {
                            final text = textController.text.trim();
                            if (text.isNotEmpty) {
                              final newAnnotations = Map<String, String>.from(currentAnnotations);
                              if (!isEdit && blockIndex != null && start != null && end != null) {
                                newAnnotations.removeWhere((k, v) {
                                  final parts = k.split('_');
                                  if (parts.length == 3 && int.tryParse(parts[0]) == blockIndex) {
                                    final annStart = int.tryParse(parts[1]);
                                    final annEnd = int.tryParse(parts[2]);
                                    if (annStart != null && annEnd != null) {
                                      return start < annEnd && end > annStart;
                                    }
                                  }
                                  return false;
                                });
                              }
                              final data = {
                                'selectedText': actualSelectedText,
                                'comment': text,
                                'colorHex': selectedColorHex,
                              };
                              setState(() {
                                currentAnnotations[actualKey] = jsonEncode(data);
                              });
                            }
                            FocusManager.instance.primaryFocus?.unfocus();
                            Navigator.pop(context);
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Color(int.parse(selectedColorHex.replaceFirst('#', '0xFF'))),
                            foregroundColor: const Color(0xFF333333),
                            elevation: 0,
                            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: Text(
                            "确认",
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontFamily: 'LXGWWenKai',
                              fontSize: 15,
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
        );
      },
    );
  }

  void _handleBack(BuildContext context) async {
    final content = blocks.whereType<TextBlock>().map((b) => b.controller.text).join('\n');
    final bool hasContent = content.trim().isNotEmpty || 
        blocks.whereType<ImageBlock>().isNotEmpty || 
        blocks.whereType<AudioBlock>().isNotEmpty ||
        currentMoodIndex != null ||
        currentTag != null ||
        weather != null;

    final bool shouldPrompt = widget.entry == null ? hasContent : isModified;

    if (!shouldPrompt) {
      Navigator.of(context).pop(false);
      return;
    }

    final isNight = UserState().isNight;
    final String fontFamily = UserState().selectedIslandThemeId.value == 'lego' ? 'SweiFistLeg' : 'LXGWWenKai';

    showDialog(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.6),
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        elevation: 0,
        child: Container(
          decoration: BoxDecoration(
            color: isNight
                ? const Color(0xFF2C2C2E)
                : Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isNight
                  ? Colors.white.withValues(alpha: 0.08)
                  : Colors.black.withValues(alpha: 0.05),
              width: 0.5,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.only(top: 32, bottom: 20, left: 24, right: 24),
                child: Text(
                  "是否将本次记录保存为草稿？",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: isNight
                        ? Colors.white.withValues(alpha: 0.9)
                        : const Color(0xFF2C2C2C),
                    fontFamily: fontFamily,
                  ),
                ),
              ),
              Container(
                height: 0.5,
                color: isNight ? Colors.white10 : Colors.black.withValues(alpha: 0.05),
              ),
              Row(
                children: [
                  Expanded(
                    child: InkWell(
                      onTap: () {
                        if (widget.entry == null) {
                          UserState().deleteDraftEntry(currentDraftId);
                        }
                        Navigator.pop(ctx);
                        Navigator.of(context).pop(false);
                      },
                      borderRadius: const BorderRadius.only(bottomLeft: Radius.circular(16)),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        child: Text(
                          "丢弃",
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontFamily: fontFamily,
                            fontSize: 15,
                            color: isNight ? Colors.white54 : const Color(0xFF8E8E93),
                          ),
                        ),
                      ),
                    ),
                  ),
                  Container(
                    width: 0.5,
                    height: 50,
                    color: isNight ? Colors.white10 : Colors.black.withValues(alpha: 0.05),
                  ),
                  Expanded(
                    child: InkWell(
                      onTap: () async {
                        await saveCurrentAsDraft();
                        if (ctx.mounted) {
                          Navigator.pop(ctx);
                        }
                        if (context.mounted) {
                          Navigator.of(context).pop(false);
                        }
                      },
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        child: Text(
                          "保存草稿",
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontFamily: fontFamily,
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFFD4A373),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// 极轻量键盘跟随组件。
/// 这是页面中**唯一**读取 viewInsets 的 widget，因此键盘动画的每一帧
/// 只有此 widget 重建（仅更新一个 Positioned 的 bottom 值），
/// 其 child（EditorBottomBar）作为外部传入，不会随之重建，彻底消除卡顿。
class _KeyboardFollower extends StatelessWidget {
  final Widget child;
  const _KeyboardFollower({required this.child});

  @override
  Widget build(BuildContext context) {
    final double keyboardHeight = MediaQuery.viewInsetsOf(context).bottom;
    return AnimatedPositioned(
      duration: const Duration(milliseconds: 80), // 控制底部菜单跟随键盘速度的
      curve: Curves.easeOutCubic,
      bottom: keyboardHeight,
      left: 0,
      right: 0,
      child: child,
    );
  }
}
