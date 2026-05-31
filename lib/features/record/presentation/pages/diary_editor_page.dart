import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:island_diary/features/record/domain/models/diary_entry.dart';
import 'package:island_diary/shared/widgets/diary_entry/models/diary_block.dart';
import 'package:island_diary/core/state/user_state.dart';
import 'package:island_diary/shared/widgets/diary_entry/mixins/diary_editor_core_mixin.dart';
import 'package:island_diary/shared/widgets/diary_entry/mixins/diary_editor_media_mixin.dart';
import 'package:island_diary/shared/widgets/diary_entry/mixins/diary_editor_format_mixin.dart';
import 'package:island_diary/shared/widgets/diary_entry/mixins/diary_editor_insert_mixin.dart';
import 'package:island_diary/shared/widgets/diary_entry/utils/diary_utils.dart';
import 'package:island_diary/shared/widgets/island_vip_guard_dialog.dart';
import '../widgets/editor/editor_header.dart';
import '../widgets/editor/editor_content_list.dart';
import '../widgets/editor/editor_bottom_bar.dart';
import 'package:island_diary/shared/widgets/mood_picker/custom_mood_picker_popup.dart';
import 'package:island_diary/shared/widgets/sticker_picker/sticker_picker_popup.dart';
import 'package:island_diary/shared/widgets/diary_entry/components/interactive_sticker.dart';

class DiaryEditorPage extends StatefulWidget {
  final int? moodIndex;
  final double intensity;
  final String? tag;
  final DiaryEntry? entry;
  final DateTime? initialDate;
  const DiaryEditorPage({
    super.key,
    this.moodIndex,
    required this.intensity,
    this.tag,
    this.entry,
    this.initialDate,
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
  double _scrollOffset = 0;
  String? _activeStickerId;

  @override
  void initState() {
    super.initState();
    initializeEditor(entry: widget.entry, initialDate: widget.initialDate);
    
    // 监听滚动，用于同步贴纸位置
    scrollController.addListener(() {
      if (mounted) {
        setState(() {
          _scrollOffset = scrollController.offset;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final double viewInsetsBottom = MediaQuery.of(context).viewInsets.bottom;
    
    // 实时捕捉并记忆最大键盘高度
    if (viewInsetsBottom > 100 && viewInsetsBottom > keyboardHeight) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && viewInsetsBottom != keyboardHeight) {
          setState(() => keyboardHeight = viewInsetsBottom);
        }
      });
    }

    final double currentBottomHeight = isEmojiOpen
        ? math.max(viewInsetsBottom, keyboardHeight)
        : viewInsetsBottom;

    return ValueListenableBuilder<String>(
      valueListenable: UserState().themeMode,
      builder: (context, themeMode, _) {
        final bool isNight = UserState().isNight;
        final Color accentColor = DiaryUtils.getAccentColor(currentPaperStyle, isNight);
        final themeId = UserState().selectedIslandThemeId.value;
        final Color bgColor = isNight
            ? const Color(0xFF121212)
            : (themeId == 'lego'
                ? const Color(0xFFFDF3E3)
                : (themeId == 'cotton_candy' && currentPaperStyle == 'classic'
                    ? const Color(0xFFFBF3E9)
                    : const Color(0xFFFAF8F5)));

        return PopScope(
          canPop: true,
          child: Scaffold(
            resizeToAvoidBottomInset: false,
            backgroundColor: bgColor,
            body: Stack(
              children: [
                // 1. 信纸底色层
                Positioned.fill(
                  child: Container(
                    color: bgColor,
                    child: (UserState().selectedIslandThemeId.value == 'cotton_candy' && currentPaperStyle == 'classic')
                        ? Image.asset(
                            isNight
                                ? 'assets/images/theme/miamhuadao/note/mianhuadao_note_defalut_night_bg.png'
                                : 'assets/images/theme/miamhuadao/note/mianhuadao_note_defalut_bg.png',
                            fit: BoxFit.cover,
                          )
                        : null,
                  ),
                ),
                
                // 2. 主编辑区 (文字与图片块)
                GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () {
                    FocusScope.of(context).unfocus();
                    if (isEmojiOpen) toggleEmoji();
                    // 点击空白处取消贴纸选中
                    if (_activeStickerId != null) {
                      setState(() => _activeStickerId = null);
                    }
                  },
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 800),
                      child: CustomScrollView(
                        controller: scrollController,
                        physics: const BouncingScrollPhysics(),
                        slivers: [
                          // 顶部留白，为固定页头腾出位置
                          const SliverToBoxAdapter(
                            child: SafeArea(
                              bottom: false,
                              child: SizedBox(height: 60), // 对应 Header 的高度
                            ),
                          ),
                          // 编辑主体：内容块列表
                          EditorContentList(
                            blocks: blocks,
                            blockKeys: blockKeys,
                            isMixedLayout: isMixedLayout,
                            isEmojiOpen: isEmojiOpen || isColorPickerOpen || isImagePickerOpen,
                            isNight: isNight,
                            paperStyle: currentPaperStyle,
                            accentColor: accentColor,
                            bottomPadding: (!isMixedLayout) ? 12 : math.max(160, currentBottomHeight + 100),
                            currentMoodIndex: currentMoodIndex,
                            currentTag: currentTag,
                            onClearMood: () {
                              setState(() {
                                currentMoodIndex = null;
                                currentTag = null;
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
                          ),
                          // 底部留白
                          SliverToBoxAdapter(
                            child: SizedBox(
                              height: (isImageGrid && !isMixedLayout) ? 48 : math.max(120, currentBottomHeight + 50),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                // 2.5 固定页头层
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  child: SafeArea(
                    bottom: false,
                    child: Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 800),
                        child: EditorHeader(
                          paperStyle: currentPaperStyle,
                          isNight: isNight,
                          dateTime: entryDateTime ?? DateTime.now(),
                          onBack: () => Navigator.of(context).pop(),
                          onSave: onSave,
                          onDateTap: onDateClick,
                        ),
                      ),
                    ),
                  ),
                ),

                // 3. 贴纸悬浮层 (层级高于文字，但受到顶部裁剪约束)
                Positioned.fill(
                  top: 80, // 顶部裁剪线（避开 Header）
                  bottom: 100, // 底部裁剪线（避开工具栏）
                  child: ClipRect(
                    child: Stack(
                      children: [
                        ...blocks.whereType<StickerBlock>().map((sticker) {
                          return InteractiveSticker(
                            key: ValueKey(sticker.id),
                            block: sticker,
                            isSelected: sticker.id == _activeStickerId,
                            scrollOffset: _scrollOffset,
                            onTap: () {
                              setState(() {
                                _activeStickerId = sticker.id;
                                // 置顶逻辑
                                blocks.remove(sticker);
                                blocks.add(sticker);
                              });
                            },
                            onRemove: () {
                              setState(() {
                                blocks.remove(sticker);
                                _activeStickerId = null;
                              });
                              onBlocksChanged();
                            },
                            onChanged: onBlocksChanged,
                          );
                        }),
                      ],
                    ),
                  ),
                ),

                // 4. 底部悬浮工具栏
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: EditorBottomBar(
                    isEmojiOpen: isEmojiOpen,
                    isNight: isNight,
                    paperStyle: currentPaperStyle,
                    accentColor: accentColor,
                    currentBottomHeight: currentBottomHeight,
                    viewInsetsBottom: viewInsetsBottom,
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
                    onStickerClick: _showStickerPicker,
                    onCreateSticker: () {}, 
                    onWeatherClick: onWeatherClick,
                    onMoreClick: onMoreClick,
                    onClose: () => Navigator.of(context).pop(),
                    onSave: onSave,
                    onEmojiSelected: onEmojiSelected,
                    onEmojiBackspace: handleEmojiBackspace,
                    onEmojiSend: handleEmojiSend,
                    onCustomEmojiSelected: handleCustomEmojiSelected,
                    onRemoveImage: removeImage,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _showCustomMoodPicker() async {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      showDragHandle: false,
      builder: (context) => CustomMoodPickerPopup(
        paperStyle: currentPaperStyle,
        isNight: UserState().isNight,
        onSave: (result) {
          if (mounted) {
            setState(() {
              currentMoodIndex = result['index'];
              currentIntensity = result['intensity'];
              if (result['tag'] != null) {
                currentTag = result['tag'];
              }
              updateMoodQuote();
            });
            onBlocksChanged();
          }
        },
      ),
    );
  }

  void _showStickerPicker() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      showDragHandle: false,
      builder: (context) => StickerPickerPopup(
        paperStyle: currentPaperStyle,
        isNight: UserState().isNight,
        onStickerSelected: (path) {
          Navigator.pop(context);
          setState(() {
            // 将新贴纸初始位置设为屏幕中心附近
            final double initialX = MediaQuery.of(context).size.width / 2 - 75;
            final double initialY = _scrollOffset + MediaQuery.of(context).size.height / 3;
            final newSticker = StickerBlock(path, dx: initialX, dy: initialY);
            blocks.add(newSticker);
            _activeStickerId = newSticker.id; // 新贴纸默认选中
          });
          onBlocksChanged();
        },
      ),
    );
  }

  void onMoreClick() {
    _showMoreBottomSheet();
  }

  void _showMoreBottomSheet() {
    final bool isNight = UserState().isNight;
    // 使用与主 build 一致的逻辑
    final bool effectiveIsNight = isNight;
    final Color accentColor = DiaryUtils.getAccentColor(
      currentPaperStyle,
      effectiveIsNight,
    );
    final Color bgColor = DiaryUtils.getPopupBackgroundColor(
      currentPaperStyle,
      effectiveIsNight,
    );
    final Color textColor = DiaryUtils.getInkColor(
      currentPaperStyle,
      effectiveIsNight,
    ).withValues(alpha: 0.9);
    final String fontFamily = UserState().selectedIslandThemeId.value == 'lego' ? 'SweiFistLeg' : 'LXGWWenKai';
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      showDragHandle: false,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) {
          final Color opaqueBgColor = bgColor.withValues(alpha: 1.0);
          return Container(
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
            decoration: DiaryUtils.getPopupDecoration(
              currentPaperStyle,
              effectiveIsNight,
              customBgColor: opaqueBgColor,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 顶部指示条
                const SizedBox(height: 12),
                DiaryUtils.buildPopupDragHandle(
                  currentPaperStyle,
                  effectiveIsNight,
                  textColor,
                ),
                const SizedBox(height: 16),
                Text(
                  "更多工具",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: textColor,
                    fontFamily: fontFamily,
                  ),
                ),
                const SizedBox(height: 24),
                // 图文混排开启?
                _buildMoreMenuItem(
                  icon: Icons.layers_rounded,
                  title: "开启图文混排",
                  subtitle: "允许图片随文字光标位置插入",
                  trailing: Switch(
                    value: isMixedLayout,
                    activeThumbColor: accentColor,
                    onChanged: (value) {
                      if (value && !UserState().isVip.value) {
                        Navigator.pop(context);
                        showDialog(
                          context: context,
                          builder: (context) => const IslandVipGuardDialog(
                            title: '解锁高级编辑模式',
                            description:
                                '“图文混排”功能属于“星光计划”会员专享。开启后，您的图片将不再受布局限制。',
                          ),
                        );
                        return;
                      }
                      setModalState(() {
                        isMixedLayout = value;
                        if (value) isImageGrid = false; // 互斥逻辑
                      });
                      setState(() {
                        isMixedLayout = value;
                        if (value) isImageGrid = false;
                      });
                      onBlocksChanged(); // 即便是在关闭也触发同步?
                    },
                  ),
                  accentColor: accentColor,
                  textColor: textColor,
                ),
                const SizedBox(height: 12),
                // 占位功能 2
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
                // 图片九宫格开启?
                _buildMoreMenuItem(
                  icon: Icons.grid_view_rounded,
                  title: "开启图片九宫格",
                  subtitle: "图片不再混排，统一于末尾网格展示",
                  trailing: Switch(
                    value: isImageGrid,
                    activeThumbColor: accentColor,
                    onChanged: (value) {
                      if (value && !UserState().isVip.value) {
                        Navigator.pop(context);
                        showDialog(
                          context: context,
                          builder: (context) => const IslandVipGuardDialog(
                            title: '解锁九宫格布局',
                            description: '“图片九宫格”功能属于“星光计划”会员专享。开启后，您的图片将以精致的网格形式呈现。',
                          ),
                        );
                        return;
                      }
                      setModalState(() {
                        isImageGrid = value;
                        if (value) {
                          isMixedLayout = false; // 互斥逻辑
                          // 清理逻辑：开启九宫格时，移除文末由于自动插入产生的冗余空格?
                          if (blocks.length > 1 &&
                              blocks.last is TextBlock &&
                              (blocks.last as TextBlock)
                                  .controller
                                  .text
                                  .isEmpty) {
                            blocks.removeLast();
                          }
                        }
                      });
                      setState(() {
                        isImageGrid = value;
                        if (value) {
                          isMixedLayout = false;
                          if (blocks.length > 1 &&
                              blocks.last is TextBlock &&
                              (blocks.last as TextBlock)
                                  .controller
                                  .text
                                  .isEmpty) {
                            blocks.removeLast();
                          }
                        }
                      });
                      onBlocksChanged();
                    },
                  ),
                  accentColor: accentColor,
                  textColor: textColor,
                ),
                const SizedBox(height: 20),
              ],
            ),
          );
        },
      ),
    );
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
    final String fontFamily = UserState().selectedIslandThemeId.value == 'lego' ? 'SweiFistLeg' : 'LXGWWenKai';
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
}