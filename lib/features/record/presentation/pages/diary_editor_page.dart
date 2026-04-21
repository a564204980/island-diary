import 'dart:ui';
// Analysis Flush: 强制刷新库摘要以解决 Bad state 错误
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:island_diary/features/record/domain/models/diary_entry.dart';
import 'package:island_diary/shared/widgets/diary_entry/components/diary_toolbar.dart';
import 'package:island_diary/shared/widgets/diary_entry/components/emoji_panel.dart';
import 'package:island_diary/shared/widgets/diary_entry/components/diary_block_item.dart';
import 'package:island_diary/shared/widgets/diary_entry/models/diary_block.dart';
import 'package:island_diary/shared/widgets/diary_entry/components/hand_drawn_divider.dart';
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
import 'package:flutter_animate/flutter_animate.dart';
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
    
    // 实时捕捉并记忆最大键盘高度，移至 build 以供内容区域 padding 使用
    if (viewInsetsBottom > 100 && viewInsetsBottom > keyboardHeight) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && viewInsetsBottom != keyboardHeight) {
          setState(() => keyboardHeight = viewInsetsBottom);
        }
      });
    }

    // 计算当前底部遮挡总高度
    final double currentBottomHeight = isEmojiOpen
        ? math.max(viewInsetsBottom, keyboardHeight)
        : viewInsetsBottom;

    return ValueListenableBuilder<String>(
      valueListenable: UserState().themeMode,
      builder: (context, themeMode, child) {
        final bool isNight = UserState().isNight;
        // 使用 isNight 决定配色，DiaryUtils 会根据信纸类型自动适配
        final bool effectiveIsNight = isNight;
        final Color accentColor = DiaryUtils.getAccentColor(
          currentPaperStyle,
          effectiveIsNight,
        );
        final Color bgColor = DiaryUtils.getPaperBaseColor(
          currentPaperStyle,
          effectiveIsNight,
        );
        return PopScope(
      canPop: true,
      child: Scaffold(
        resizeToAvoidBottomInset: false,
        backgroundColor: bgColor,
        body: Stack(
          children: [
            // 背景图?
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: effectiveIsNight
                        ? [bgColor, bgColor.withValues(alpha: 0.8)]
                        : [bgColor, bgColor.withValues(alpha: 0.9)],
                  ),
                ),
              ),
            ),
            // 信纸底色与纹理层
            Positioned.fill(
              child: Stack(
                children: [
                  if (currentPaperStyle.startsWith('note'))
                    Positioned.fill(
                      child: Image.asset(
                        DiaryUtils.getPaperBackgroundPath(
                          currentPaperStyle,
                          isNight,
                        ),
                        fit: BoxFit.cover,
                      ),
                    ),
                  Positioned.fill(
                    child: CustomPaint(
                      painter: PaperBackgroundPainter(
                        style: currentPaperStyle,
                        isNight: effectiveIsNight,
                        accentColor: accentColor,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // 主内容：模拟详情页结构?
            GestureDetector(
              onTap: () {
                FocusScope.of(context).unfocus();
                if (isEmojiOpen) {
                  toggleEmoji();
                }
              },
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 800),
                  child: CustomScrollView(
                    controller: scrollController,
                    physics: const BouncingScrollPhysics(),
                    slivers: [
                      // TOP AREA: Header + Quote
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(24, 32, 24, 0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                crossAxisAlignment: CrossAxisAlignment.baseline,
                                textBaseline: TextBaseline.alphabetic,
                                children: [
                                  Text(
                                    DiaryUtils.getFormattedTime(),
                                    style: TextStyle(
                                      fontSize: 60,
                                      fontWeight: FontWeight.bold,
                                      color: DiaryUtils.getInkColor(
                                        currentPaperStyle,
                                        effectiveIsNight,
                                      ),
                                      fontFamily: 'LXGWWenKai',
                                      letterSpacing: -1,
                                    ),
                                  ),
                                  Text(
                                    DiaryUtils.getFormattedDate(),
                                    style: TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.w500,
                                      color: DiaryUtils.getInkColor(
                                        currentPaperStyle,
                                        effectiveIsNight,
                                      ).withValues(alpha: 0.7),
                                      fontFamily: 'LXGWWenKai',
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Text(
                                fixedQuote,
                                style: TextStyle(
                                  fontFamily: 'LXGWWenKai',
                                  fontSize: 16,
                                  fontStyle: FontStyle.italic,
                                  color: DiaryUtils.getInkColor(
                                    currentPaperStyle,
                                    effectiveIsNight,
                                  ).withValues(alpha: 0.6),
                                ),
                              ),
                              const SizedBox(height: 12),
                              CustomPaint(
                                size: const Size(double.infinity, 2),
                                painter: HandDrawnLinePainter(
                                  color: effectiveIsNight
                                      ? DiaryUtils.getInkColor(
                                          currentPaperStyle,
                                          effectiveIsNight,
                                        ).withValues(alpha: 0.1)
                                      : DiaryUtils.getInkColor(
                                          currentPaperStyle,
                                          effectiveIsNight,
                                        ).withValues(alpha: 0.3),
                                  strokeWidth: 1.5,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      // TAG BAR: All Tags (Dynamic height)
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 8,
                          ),
                          child: Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              // 心情标签
                              GestureDetector(
                                onTap: _showMoodPicker,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: currentPaperStyle.startsWith('note')
                                        ? Colors.white.withValues(alpha: 0.4)
                                        : effectiveIsNight ? Colors.white.withValues(alpha: 0.2) : accentColor.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(
                                      color: accentColor.withValues(alpha: 0.15),
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withValues(alpha: 0.03),
                                        blurRadius: 4,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      if (mood == null &&
                                          (currentTag == null ||
                                              currentTag!.isEmpty))
                                        Icon(
                                          Icons.add_circle_outline,
                                          size: 14,
                                          color: accentColor,
                                        )
                                      else
                                        Image.asset(
                                          (currentTag != null &&
                                                  currentTag!.isNotEmpty)
                                              ? 'assets/images/icons/custom.png'
                                              : (mood!.iconPath!),
                                          width: 14,
                                          height: 14,
                                          color: mood == null
                                              ? accentColor
                                              : null,
                                        ),
                                      const SizedBox(width: 4),
                                      Text(
                                        mood == null &&
                                                (currentTag == null ||
                                                    currentTag!.isEmpty)
                                            ? '选择心情'
                                            : (currentTag != null &&
                                                  currentTag!.isNotEmpty)
                                            ? '心情：$currentTag'
                                            : '心情：${mood!.label}',
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                          color: accentColor,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              // 天气
                              if (weather != null)
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: currentPaperStyle.startsWith('note')
                                        ? Colors.white.withValues(alpha: 0.4)
                                        : effectiveIsNight ? Colors.white.withValues(alpha: 0.2) : accentColor.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(
                                      color: effectiveIsNight
                                           ? Colors.white.withValues(alpha: 0.55)
                                           : accentColor.withValues(alpha: currentPaperStyle.startsWith('note') ? 0.2 : 0.25),
                                    ),
                                  ),
                                  child: Text(
                                    "$weather ${temp ?? ''}",
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      color: accentColor,
                                    ),
                                  ),
                                ),
                              // 地点
                              if (location != null)
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: currentPaperStyle.startsWith('note')
                                        ? Colors.white.withValues(alpha: 0.4)
                                        : effectiveIsNight ? Colors.white.withValues(alpha: 0.2) : accentColor.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(
                                      color: effectiveIsNight
                                           ? Colors.white.withValues(alpha: 0.55)
                                           : accentColor.withValues(alpha: currentPaperStyle.startsWith('note') ? 0.2 : 0.25),
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        Icons.location_on_outlined,
                                        size: 12,
                                        color: accentColor,
                                      ),
                                      const SizedBox(width: 2),
                                      Text(
                                        location!,
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                          color: accentColor,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              // 自定义日期?
                              if (customDate != null)
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: currentPaperStyle.startsWith('note')
                                        ? Colors.white.withValues(alpha: 0.4)
                                        : effectiveIsNight ? Colors.white.withValues(alpha: 0.2) : accentColor.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(
                                      color: effectiveIsNight
                                           ? Colors.white.withValues(alpha: 0.55)
                                           : accentColor.withValues(alpha: currentPaperStyle.startsWith('note') ? 0.2 : 0.25),
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        Icons.calendar_today_outlined,
                                        size: 12,
                                        color: accentColor,
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        customDate!,
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                          color: accentColor,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              // 自定义时间?
                              if (customTime != null)
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: currentPaperStyle.startsWith('note')
                                        ? Colors.white.withValues(alpha: 0.4)
                                        : effectiveIsNight ? Colors.white.withValues(alpha: 0.2) : accentColor.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(
                                      color: effectiveIsNight
                                           ? Colors.white.withValues(alpha: 0.55)
                                           : accentColor.withValues(alpha: currentPaperStyle.startsWith('note') ? 0.2 : 0.25),
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        Icons.access_time_outlined,
                                        size: 12,
                                        color: accentColor,
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        customTime!,
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                          color: accentColor,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                      SliverPadding(
                        padding: EdgeInsets.fromLTRB(
                          24,
                          12,
                          24,
                          (!isMixedLayout)
                              ? 12
                              : math.max(160, currentBottomHeight + 100),
                        ),
                        sliver: SliverList(
                          delegate: SliverChildBuilderDelegate(
                            (context, index) {
                              // 如果关闭了图文混排模式，非图片块按原样渲染，图片块统一在底部预览条显示
                              if (!isMixedLayout) {
                                final nonImageBlocks = blocks
                                    .where((b) => b is! ImageBlock)
                                    .toList();
                                if (index >= nonImageBlocks.length) return null;
                                final block = nonImageBlocks[index];
                                final key = blockKeys[block.id];
                                return DiaryBlockItem(
                                  key: ValueKey(block.id),
                                  block: block,
                                  index: blocks.indexOf(block),
                                  isEmojiOpen:
                                      (isEmojiOpen ||
                                      isColorPickerOpen ||
                                      isImagePickerOpen),
                                  blockKey: key,
                                  onRemoveImage: () =>
                                      removeImage(blocks.indexOf(block)),
                                  onDeleteAtStart: () => handleBackspaceAtStart(
                                    blocks.indexOf(block),
                                  ),
                                  onShowPreview: showImagePreview,
                                  isNightOverride: effectiveIsNight,
                                  isNoteBackground: currentPaperStyle
                                      .startsWith('note'),
                                  paperStyle: currentPaperStyle,
                                  accentColor: accentColor,
                                );
                              }
                              final block = blocks[index];
                              final key = blockKeys[block.id];
                              return DiaryBlockItem(
                                key: ValueKey(block.id),
                                block: block,
                                index: index,
                                isEmojiOpen:
                                    (isEmojiOpen ||
                                    isColorPickerOpen ||
                                    isImagePickerOpen),
                                blockKey: key,
                                onRemoveImage: () => removeImage(index),
                                onDeleteAtStart: () =>
                                    handleBackspaceAtStart(index),
                                onShowPreview: showImagePreview,
                                isNightOverride: effectiveIsNight,
                                isNoteBackground: currentPaperStyle.startsWith(
                                  'note',
                                ),
                                paperStyle: currentPaperStyle,
                                accentColor: accentColor,
                              );
                            },
                            childCount: (!isMixedLayout)
                                ? blocks.where((b) => b is! ImageBlock).length
                                : blocks.length,
                          ),
                        ),
                      ),
                      SliverToBoxAdapter(
                        child: SizedBox(
                          height: (isImageGrid && !isMixedLayout)
                              ? 48
                              : math.max(120, currentBottomHeight + 50),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            // 底部工具栏(根据要求：不要动)
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Builder(
                builder: (context) {
                  final double screenWidth = MediaQuery.of(context).size.width;
                  final bool isWide = screenWidth > 800;
                  final double toolbarMaxWidth = isWide
                      ? 800.0
                      : double.infinity;
                  final double totalBottomHeight = currentBottomHeight;
                  return Align(
                    alignment: Alignment.bottomCenter,
                    child: SizedBox(
                      width: toolbarMaxWidth,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _buildImageUploadPreviewBar(
                            effectiveIsNight,
                            accentColor,
                          ),
                          const SizedBox(height: 8),
                          DiaryToolbar(
                            isEmojiOpen: isEmojiOpen,
                            onEmojiToggle: toggleEmoji,
                            onImagePick: onImageButtonPressed,
                            onColorClick: showUnifiedColorPicker,
                            onBgColorClick: showPaperPicker,
                            onLocationClick: onLocationClick,
                            onFontSizeClick: showFontSizePicker,
                            onFontClick: showFontPicker,
                            onDateClick: onDateClick,
                            onTimeClick: onTimeClick,
                            onTagClick: onTagClick,
                            onWeatherClick: onWeatherClick,
                            onMoreClick: onMoreClick,
                            onClose: () => Navigator.of(context).pop(),
                            onSave: onSave,
                            accentColor: accentColor,
                            isNightOverride: effectiveIsNight,
                            isNoteBackground: currentPaperStyle.startsWith(
                              'note',
                            ),
                            paperStyle: currentPaperStyle,
                          ),
                          AnimatedContainer(
                            duration: Duration(
                              milliseconds: isEmojiOpen ? 150 : 250,
                            ),
                            curve: Curves.easeOutCubic,
                            height: totalBottomHeight,
                            color: (isEmojiOpen || viewInsetsBottom > 0)
                                ? DiaryUtils.getPopupBackgroundColor(
                                    currentPaperStyle,
                                    effectiveIsNight,
                                  ).withValues(alpha: 0.98)
                                : Colors.transparent,
                            child: Visibility(
                              visible: isEmojiOpen,
                              maintainState: true,
                              child: EmojiPanel(
                                onEmojiSelected: onEmojiSelected,
                                onBackspace: handleEmojiBackspace,
                                onSend: handleEmojiSend,
                                onCustomEmojiSelected:
                                    handleCustomEmojiSelected,
                                paperStyle: currentPaperStyle,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
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
  Widget _buildImageUploadPreviewBar(bool isNight, Color accentColor) {
    if (isMixedLayout) return const SizedBox.shrink();
    final images = blocks.whereType<ImageBlock>().toList();
    if (images.isEmpty) return const SizedBox.shrink();
    return Container(
      height: 90,
      margin: const EdgeInsets.fromLTRB(12, 0, 12, 0),
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        itemCount: images.length,
        separatorBuilder: (context, index) => const SizedBox(width: 12),
        itemBuilder: (context, index) {
          final img = images[index];
          final imgIndex = blocks.indexOf(img);
          return Padding(
            padding: const EdgeInsets.only(top: 8, right: 8),
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                GestureDetector(
                  onTap: () => showImagePreview(img),
                  child: Container(
                    width: 70,
                    height: 70,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: isNight
                              ? Colors.white.withValues(alpha: 0.12)
                              : const Color(0xFFD4A373).withValues(alpha: 0.2),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Hero(
                        tag: 'preview_${img.id}',
                        child: DiaryUtils.buildImage(
                          img.file.path,
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                  ),
                ),
                Positioned(
                  top: -8,
                  right: -8,
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () => removeImage(imgIndex),
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(
                        color: Colors.black,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.close_rounded,
                        color: Colors.white,
                        size: 16,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    ).animate().slideY(begin: 0.5, end: 0).fadeIn();
  }
}