import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:island_diary/features/record/domain/models/diary_entry.dart';
import 'package:island_diary/shared/widgets/diary_entry/components/diary_toolbar.dart';
import 'package:island_diary/shared/widgets/diary_entry/components/emoji_panel.dart';
import 'package:island_diary/shared/widgets/diary_entry/components/diary_block_item.dart';
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

class _StickyTabBarDelegate extends SliverPersistentHeaderDelegate {
  final Widget child;
  final Color backgroundColor;

  _StickyTabBarDelegate({required this.child, required this.backgroundColor});

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(
      color: backgroundColor,
      alignment: Alignment.centerLeft,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      child: child,
    );
  }

  @override
  double get maxExtent => 54;
  @override
  double get minExtent => 54;

  @override
  bool shouldRebuild(covariant _StickyTabBarDelegate oldDelegate) => true;
}

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
    final mood = (currentMoodIndex != null && currentMoodIndex! >= 0) ? kMoods[currentMoodIndex!] : null;
    final bool isNight = UserState().isNight;
    // 如果使用自定义信纸背景（note系列），即便在晚上也不使用夜间模式样式
    final bool effectiveIsNight = isNight && !currentPaperStyle.startsWith('note');
    final bgColor = effectiveIsNight ? const Color(0xFF13131F) : const Color(0xFFF7F2E9);
    
    // 如果没有选择心情，则使用默认的强调色。针对 note 系列使用更中性的色调以适配不同底纹。
    final Color standardDefaultColor = const Color(0xFF8B5E3C);
    final Color noteDefaultColor = currentPaperStyle == 'note1' 
        ? const Color(0xFF5A7285) // note1 为蓝绿色调，默认强调色改为灰蓝色
        : const Color(0xFF7D6B5D); // 其他 note 默认为中性茶褐色
    
    final defaultAccentColor = effectiveIsNight 
        ? const Color(0xFFE0C097) 
        : (currentPaperStyle.startsWith('note') ? noteDefaultColor : standardDefaultColor);
    final moodGlowColor = mood?.glowColor;
    
    // UI 强调色固定为基于纸张样式的颜色，不再随心情动态变化
    final Color accentColor = defaultAccentColor;

    final double viewInsetsBottom = MediaQuery.of(context).viewInsets.bottom;
    // 实时捕获并记忆最大键盘高度，移至主 build 以供内容区域 padding 使用
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

    return PopScope(
      canPop: true,
      child: Scaffold(
        resizeToAvoidBottomInset: false,
        backgroundColor: bgColor,
        body: Stack(
          children: [
            // 背景层
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
                        'assets/images/note/${currentPaperStyle.replaceFirst('note', 'note_bg')}${['note1', 'note2', 'note3', 'note4'].contains(currentPaperStyle) ? '.png' : '.jpg'}',
                        fit: BoxFit.cover,
                        color: (isNight && !currentPaperStyle.startsWith('note')) 
                            ? Colors.black.withValues(alpha: 0.3) 
                            : null,
                        colorBlendMode: (isNight && !currentPaperStyle.startsWith('note')) 
                            ? BlendMode.darken 
                            : null,
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
            
            // 主内容：模拟详情页结构
            GestureDetector(
              onTap: () {
                FocusScope.of(context).unfocus();
                if (isEmojiOpen) toggleEmoji();
              },
              child: Container(
                width: double.infinity,
                height: double.infinity,
                color: Colors.transparent,
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
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              crossAxisAlignment: CrossAxisAlignment.baseline,
                              textBaseline: TextBaseline.alphabetic,
                              children: [
                                Text(
                                  DiaryUtils.getFormattedTime(),
                                  style: TextStyle(
                                    fontSize: 60,
                                    fontWeight: FontWeight.bold,
                                    color: DiaryUtils.getInkColor(currentPaperStyle, effectiveIsNight),
                                    fontFamily: 'LXGWWenKai',
                                    letterSpacing: -1,
                                  ),
                                ),
                                Text(
                                  DiaryUtils.getFormattedDate(),
                                  style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.w500,
                                    color: DiaryUtils.getInkColor(currentPaperStyle, effectiveIsNight).withValues(alpha: 0.7),
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
                                color: DiaryUtils.getInkColor(currentPaperStyle, effectiveIsNight).withValues(alpha: 0.6),
                              ),
                            ),
                            const SizedBox(height: 12),
                            CustomPaint(
                              size: const Size(double.infinity, 2),
                              painter: HandDrawnLinePainter(
                                color: effectiveIsNight 
                                  ? DiaryUtils.getInkColor(currentPaperStyle, effectiveIsNight).withValues(alpha: 0.1) 
                                  : DiaryUtils.getInkColor(currentPaperStyle, effectiveIsNight).withValues(alpha: 0.3),
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
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                        child: Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            // 心情标签
                            GestureDetector(
                              onTap: _showMoodPicker,
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: currentPaperStyle.startsWith('note') 
                                      ? Colors.white.withValues(alpha: 0.4) 
                                      : accentColor.withValues(alpha: 0.08),
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(color: accentColor.withValues(alpha: 0.15)),
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
                                    if (mood == null && (currentTag == null || currentTag!.isEmpty))
                                      Icon(Icons.add_circle_outline, size: 14, color: accentColor)
                                    else
                                      Image.asset(
                                        (currentTag != null && currentTag!.isNotEmpty) 
                                            ? 'assets/images/icons/custom.png' 
                                            : (mood!.iconPath!),
                                        width: 14,
                                        height: 14,
                                        color: mood == null ? accentColor : null,
                                      ),
                                    const SizedBox(width: 4),
                                    Text(
                                      mood == null && (currentTag == null || currentTag!.isEmpty)
                                          ? '选择心情'
                                          : (currentTag != null && currentTag!.isNotEmpty)
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
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: currentPaperStyle.startsWith('note') 
                                      ? Colors.white.withValues(alpha: 0.4) 
                                      : accentColor.withValues(alpha: 0.08),
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(
                                    color: accentColor.withValues(alpha: currentPaperStyle.startsWith('note') ? 0.2 : 0.15), 
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
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: currentPaperStyle.startsWith('note') 
                                      ? Colors.white.withValues(alpha: 0.4) 
                                      : accentColor.withValues(alpha: 0.08),
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(
                                    color: accentColor.withValues(alpha: currentPaperStyle.startsWith('note') ? 0.2 : 0.15), 
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.location_on_outlined, size: 12, color: accentColor),
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
                            // 自定义日期
                            if (customDate != null)
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: currentPaperStyle.startsWith('note') 
                                      ? Colors.white.withValues(alpha: 0.4) 
                                      : accentColor.withValues(alpha: 0.08),
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(
                                    color: accentColor.withValues(alpha: currentPaperStyle.startsWith('note') ? 0.2 : 0.15), 
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.calendar_today_outlined, size: 12, color: accentColor),
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
                            // 自定义时间
                            if (customTime != null)
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: currentPaperStyle.startsWith('note') 
                                      ? Colors.white.withValues(alpha: 0.4) 
                                      : accentColor.withValues(alpha: 0.08),
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(
                                    color: accentColor.withValues(alpha: currentPaperStyle.startsWith('note') ? 0.2 : 0.15), 
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.access_time_outlined, size: 12, color: accentColor),
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

                    // LIST AREA: Blocks
                    SliverPadding(
                      padding: EdgeInsets.fromLTRB(
                        24, 
                        12, 
                        24, 
                        math.max(160, currentBottomHeight + 100)
                      ),
                      sliver: SliverList(
                        delegate: SliverChildBuilderDelegate(
                          (context, index) {
                            final block = blocks[index];
                            final key = blockKeys[block.id];
                            return DiaryBlockItem(
                              key: ValueKey(block.id),
                              block: block,
                              index: index,
                              isEmojiOpen: (isEmojiOpen || isColorPickerOpen || isImagePickerOpen),
                              blockKey: key,
                              onRemoveImage: () => removeImage(index),
                              onShowPreview: showImagePreview,
                              isNightOverride: effectiveIsNight,
                              isNoteBackground: currentPaperStyle.startsWith('note'),
                              paperStyle: currentPaperStyle,
                              accentColor: accentColor,
                            );
                          },
                          childCount: blocks.length,
                        ),
                      ),
                    ),

                    const SliverToBoxAdapter(
                      child: SizedBox(height: 48),
                    ),
                  ],
                ),
              ),
            ),
            
            // 底部工具栏 (根据要求：不要动)
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Builder(
                builder: (context) {
                  final double screenWidth = MediaQuery.of(context).size.width;
                  final bool isWide = screenWidth > 600;
                  final double paperMaxWidth = isWide ? screenWidth * 0.7 : double.infinity;
                  final double toolbarMaxWidth = isWide ? paperMaxWidth + 24 : double.infinity;
                  
                  final double totalBottomHeight = currentBottomHeight;
                  
                  return Align(
                    alignment: Alignment.bottomCenter,
                    child: SizedBox(
                      width: toolbarMaxWidth,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const SizedBox(height: 8),
                          DiaryToolbar(
                            isEmojiOpen: isEmojiOpen,
                            onEmojiToggle: toggleEmoji,
                            onImagePick: onImageButtonPressed,
                            onColorClick: showColorPicker,
                            onBgColorClick: showBackgroundColorPicker,
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
                            isNoteBackground: currentPaperStyle.startsWith('note'),
                          ),
                          AnimatedContainer(
                            duration: Duration(milliseconds: isEmojiOpen ? 150 : 250),
                            curve: Curves.easeOutCubic,
                            height: totalBottomHeight,
                            color: (isEmojiOpen || viewInsetsBottom > 0) 
                              ? (effectiveIsNight ? const Color(0xFF1E1E2C) : accentColor.withValues(alpha: 0.12)).withValues(alpha: 0.95)
                              : Colors.transparent,
                            child: Visibility(
                              visible: isEmojiOpen,
                              maintainState: true,
                              child: EmojiPanel(
                                onEmojiSelected: onEmojiSelected,
                                onBackspace: handleEmojiBackspace,
                                onSend: handleEmojiSend,
                                onCustomEmojiSelected: handleCustomEmojiSelected,
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
  }

  Future<void> _showMoodPicker() async {
    final result = await showModalBottomSheet<Map<String, dynamic>>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => MoodPopupPicker(
        initialIndex: currentMoodIndex,
        initialIntensity: currentIntensity,
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
}
