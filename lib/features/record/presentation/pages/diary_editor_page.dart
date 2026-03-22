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
import 'package:island_diary/shared/widgets/diary_entry/utils/diary_utils.dart';

class DiaryEditorPage extends StatefulWidget {
  final int moodIndex;
  final double intensity;
  final String? tag;
  final DiaryEntry? entry;

  const DiaryEditorPage({
    super.key,
    required this.moodIndex,
    required this.intensity,
    this.tag,
    this.entry,
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
    initializeEditor(entry: widget.entry);
  }

  @override
  Widget build(BuildContext context) {
    final mood = kMoods[widget.moodIndex];
    final bool isNight = UserState().isNight;
    final bgColor = isNight ? const Color(0xFF13131F) : const Color(0xFFF7F2E9);
    final accentColor = isNight 
        ? (mood.glowColor ?? const Color(0xFFE0C097)) 
        : Color.lerp(mood.glowColor ?? const Color(0xFF8B5E3C), Colors.black, 0.45)!;

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
                    colors: isNight 
                      ? [bgColor, bgColor.withOpacity(0.8)]
                      : [bgColor, bgColor.withOpacity(0.9)],
                  ),
                ),
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
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(24, 32, 24, 160), // 底部留出工具栏空间
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header：大字号时间 + 日期
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
                              color: isNight ? accentColor : const Color(0xFF8B5E3C),
                              fontFamily: 'LXGWWenKai',
                              letterSpacing: -1,
                            ),
                          ),
                          Text(
                            DiaryUtils.getFormattedDate(),
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w500,
                              color: isNight ? Colors.white38 : const Color(0xFFAFA296),
                              fontFamily: 'LXGWWenKai',
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      // 治愈语录
                      Text(
                        fixedQuote,
                        style: TextStyle(
                          fontFamily: 'LXGWWenKai',
                          fontSize: 16,
                          fontStyle: FontStyle.italic,
                          color: (isNight ? Colors.white38 : const Color(0xFFAFA296)).withOpacity(0.7),
                        ),
                      ),
                      const SizedBox(height: 12),
                      // 手绘分割线
                      CustomPaint(
                        size: const Size(double.infinity, 2),
                        painter: HandDrawnLinePainter(
                          color: isNight ? Colors.white10 : const Color(0xFF8B5E3C).withOpacity(0.5),
                          strokeWidth: 1.5,
                        ),
                      ),
                      const SizedBox(height: 20),
                      // 标签行
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          // 心情标签
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: accentColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Image.asset(
                                  mood.iconPath ?? 'assets/images/icons/sun.png',
                                  width: 14,
                                  height: 14,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  mood.label,
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: accentColor,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          // 强度标签
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: accentColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              DiaryUtils.getMoodIntensityPrefix(mood.label, widget.intensity),
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: accentColor,
                              ),
                            ),
                          ),
                          // 天气标签
                          if (weather != null)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: accentColor.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(10),
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
                          // 地点标签
                          if (location != null)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: accentColor.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(10),
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
                        ],
                      ),
                      const SizedBox(height: 24),
                      
                      // 编辑块列表
                      ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        padding: EdgeInsets.zero,
                        itemCount: blocks.length,
                        itemBuilder: (context, index) {
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
                          );
                        },
                      ),
                      
                      const SizedBox(height: 48),
                    ],
                  ),
                ),
              ),
            ),
            
            // 底部工具栏 (根据要求：不要动)
            Positioned(
              bottom: MediaQuery.of(context).viewInsets.bottom,
              left: 0,
              right: 0,
              child: Builder(
                builder: (context) {
                  final double screenWidth = MediaQuery.of(context).size.width;
                  final bool isWide = screenWidth > 600;
                  final double paperMaxWidth = isWide ? screenWidth * 0.7 : double.infinity;
                  final double toolbarMaxWidth = isWide ? paperMaxWidth + 24 : double.infinity;
                  final double currentBottomAreaHeight = isEmojiOpen ? keyboardHeight : 0;
                      
                  return Align(
                    alignment: Alignment.bottomCenter,
                    child: SizedBox(
                      width: toolbarMaxWidth,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // 移到底部的快捷操作按钮 (紧贴工具栏上方)
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                TextButton(
                                  onPressed: () => Navigator.of(context).pop(),
                                  style: TextButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(horizontal: 12),
                                    minimumSize: Size.zero,
                                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                  ),
                                  child: Text(
                                    '关闭',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontFamily: 'LXGWWenKai',
                                      color: isNight 
                                          ? Colors.white.withOpacity(0.4) 
                                          : const Color(0xFFA68A78).withOpacity(0.8),
                                    ),
                                  ),
                                ),
                                TextButton(
                                  onPressed: onSave,
                                  style: TextButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(horizontal: 12),
                                    minimumSize: Size.zero,
                                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                  ),
                                  child: Text(
                                    '完成',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      fontFamily: 'LXGWWenKai',
                                      color: isNight 
                                          ? (mood.glowColor ?? const Color(0xFFE0C097))
                                          : const Color(0xFF8B5E3C),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          DiaryToolbar(
                            isEmojiOpen: isEmojiOpen,
                            onEmojiToggle: toggleEmoji,
                            onImagePick: onImageButtonPressed,
                            onTopicClick: insertTopic,
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
                          ),
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 250),
                            curve: Curves.easeOutCubic,
                            height: currentBottomAreaHeight,
                            color: const Color(0xFFF9EED8).withOpacity(0.95),
                            child: isEmojiOpen
                                ? EmojiPanel(
                                    onEmojiSelected: onEmojiSelected,
                                    onBackspace: handleEmojiBackspace,
                                    onSend: handleEmojiSend,
                                    onCustomEmojiSelected: handleCustomEmojiSelected,
                                  )
                                : const SizedBox.shrink(),
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
}
