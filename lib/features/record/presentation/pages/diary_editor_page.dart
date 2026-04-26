import 'dart:typed_data';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:island_diary/features/record/domain/models/diary_entry.dart';
import 'package:island_diary/shared/widgets/diary_entry/models/diary_block.dart';
import 'package:island_diary/shared/widgets/mood_picker/config/mood_config.dart';
import 'package:island_diary/core/state/user_state.dart';
import 'package:island_diary/shared/widgets/diary_entry/mixins/diary_editor_core_mixin.dart';
import 'package:island_diary/shared/widgets/diary_entry/mixins/diary_editor_media_mixin.dart';
import 'package:island_diary/shared/widgets/diary_entry/mixins/diary_editor_format_mixin.dart';
import 'package:island_diary/shared/widgets/diary_entry/mixins/diary_editor_insert_mixin.dart';
import 'package:island_diary/shared/widgets/mood_picker/mood_popup_picker.dart';
import 'package:island_diary/shared/widgets/diary_entry/utils/diary_utils.dart';
import 'package:island_diary/shared/widgets/diary_entry/components/diary_painters.dart';
import 'package:island_diary/shared/widgets/island_vip_guard_dialog.dart';
import 'package:island_diary/core/services/image_segmentation_service.dart';
import '../widgets/editor/editor_header.dart';
import '../widgets/editor/editor_tag_bar.dart';
import '../widgets/editor/editor_content_list.dart';
import '../widgets/editor/editor_bottom_bar.dart';
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
  @override
  void initState() {
    super.initState();
    initializeEditor(entry: widget.entry, initialDate: widget.initialDate);
  }
  @override
  Widget build(BuildContext context) {
    final mood = (currentMoodIndex != null && currentMoodIndex! >= 0)
        ? kMoods[currentMoodIndex!]
        : null;
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
      builder: (context, themeMode, child) {
        final bool isNight = UserState().isNight;
        final Color accentColor = DiaryUtils.getAccentColor(currentPaperStyle, isNight);
        final Color bgColor = DiaryUtils.getPaperBaseColor(currentPaperStyle, isNight);

        return PopScope(
          canPop: true,
          child: Scaffold(
            resizeToAvoidBottomInset: false,
            backgroundColor: bgColor,
            body: Stack(
              children: [
                // 1. 信纸底色与纹理层
                Positioned.fill(
                  child: Stack(
                    children: [
                      if (currentPaperStyle.startsWith('note'))
                        Positioned.fill(
                          child: Image.asset(
                            DiaryUtils.getPaperBackgroundPath(currentPaperStyle, isNight),
                            fit: BoxFit.cover,
                          ),
                        ),
                      Positioned.fill(
                        child: CustomPaint(
                          painter: PaperBackgroundPainter(
                            style: currentPaperStyle,
                            isNight: isNight,
                            accentColor: accentColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                
                // 2. 主编辑区
                GestureDetector(
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
                          // 页头：时间日期与每日一语
                          SliverToBoxAdapter(
                            child: EditorHeader(
                              paperStyle: currentPaperStyle,
                              isNight: isNight,
                              quote: fixedQuote,
                            ),
                          ),
                          // 标签栏：心情、天气、地点等
                          SliverToBoxAdapter(
                            child: EditorTagBar(
                              paperStyle: currentPaperStyle,
                              isNight: isNight,
                              accentColor: accentColor,
                              mood: mood,
                              currentTag: currentTag,
                              weather: weather,
                              temp: temp,
                              location: location,
                              customDate: customDate,
                              customTime: customTime,
                              onMoodTap: _showMoodPicker,
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
                            onRemoveImage: removeImage,
                            onDeleteAtStart: handleBackspaceAtStart,
                            onShowPreview: showImagePreview,
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

                // 3. 底部悬浮工具栏
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
                    onFontSizeClick: showFontSizePicker,
                    onFontClick: showFontPicker,
                    onDateClick: onDateClick,
                    onTimeClick: onTimeClick,
                    onCreateSticker: _handleCreateSticker,
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
  Future<void> _showMoodPicker() async {
    final result = await showModalBottomSheet<Map<String, dynamic>>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => MoodPopupPicker(
        initialIndex: currentMoodIndex,
        initialIntensity: currentIntensity,
        paperStyle: currentPaperStyle,
      ),
    );
    if (result != null && mounted) {
      setState(() {
        currentMoodIndex = result['index'];
        currentIntensity = result['intensity'];
        if (result['tag'] != null) {
          currentTag = result['tag'];
        }
        updateMoodQuote();
      });
    }
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
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) {
          return Container(
            padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 24),
            decoration: BoxDecoration(
              color: bgColor.withValues(alpha: 0.98),
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(32),
              ),
              border: Border.all(color: accentColor.withValues(alpha: 0.15)),
              boxShadow: [
                BoxShadow(
                  color: accentColor.withValues(alpha: 0.1),
                  blurRadius: 20,
                  offset: const Offset(0, -5),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "更多工具",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: textColor,
                    fontFamily: 'LXGWWenKai',
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
                      fontFamily: 'LXGWWenKai',
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 12,
                      color: textColor.withValues(alpha: 0.5),
                      fontFamily: 'LXGWWenKai',
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

  // --- AI 贴纸创作逻辑 ---


  Future<void> _handleCreateSticker() async {
    // 1. 调用相册/拍照
    final String? path = await pickSingleImage();
    if (path == null) return;

    // 2. 显示 AI 抠图加载中
    if (!mounted) return;
    _showAISegmentationLoading();

    // 3. 执行 AI 抠图
    final Uint8List? pngBytes = await ImageSegmentationService().segmentSubject(path);
    
    // 4. 关闭加载弹窗
    if (mounted) Navigator.pop(context);

    if (pngBytes == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("AI 没能在这张图中找到清晰的主体，换张照片试试？"),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
      return;
    }

    // 5. 展示预览并确认保存
    if (mounted) {
      _showStickerPreviewResult(pngBytes);
    }
  }

  void _showAISegmentationLoading() {
    final bool isNight = UserState().isNight;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Center(
        child: Container(
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            color: isNight ? const Color(0xFF2C2E30) : Colors.white,
            borderRadius: BorderRadius.circular(24),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(
                  isNight ? const Color(0xFFE0C097) : const Color(0xFFD4A373),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                "AI 正在为你捕捉灵感...", 
                style: TextStyle(
                  color: isNight ? Colors.white70 : Colors.black87,
                  fontFamily: 'LXGWWenKai', 
                  fontWeight: FontWeight.bold,
                  decoration: TextDecoration.none,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showStickerPreviewResult(Uint8List bytes) {
    final bool isNight = UserState().isNight;
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: isNight ? const Color(0xFF2C2E30) : Colors.white,
            borderRadius: BorderRadius.circular(32),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                "创作成功！", 
                style: TextStyle(
                  fontSize: 18, 
                  fontWeight: FontWeight.bold,
                  color: isNight ? Colors.white : Colors.black87,
                  fontFamily: 'LXGWWenKai',
                ),
              ),
              const SizedBox(height: 20),
              // 模拟贴纸效果：带白边和投影
              Container(
                constraints: const BoxConstraints(maxHeight: 200),
                decoration: BoxDecoration(
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.15), 
                      blurRadius: 15,
                      spreadRadius: 2,
                    )
                  ],
                ),
                child: Image.memory(bytes),
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text("再选选", style: TextStyle(color: isNight ? Colors.white38 : Colors.grey)),
                  ),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFD4A373),
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: () async {
                      await ImageSegmentationService().saveAsSticker(bytes);
                      if (!context.mounted) return;
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text("✨ 贴纸已保存至个人收藏！"),
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    },
                    child: const Text("保存贴纸", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
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