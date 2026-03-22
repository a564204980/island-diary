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
                  controller: scrollController, // 确保关联控制器
                  physics: const BouncingScrollPhysics(),
                  padding: EdgeInsets.fromLTRB(
                    24, 
                    32, 
                    24, 
                    math.max(160, currentBottomHeight + 100) // 动态 Padding：根据键盘/面板高度留白
                  ),
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
                          // 自定义日期标签
                          if (customDate != null)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: accentColor.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(10),
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
                          // 自定义时间标签
                          if (customTime != null)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: accentColor.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(10),
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
                          ),
                          AnimatedContainer(
                            duration: Duration(milliseconds: isEmojiOpen ? 150 : 250),
                            curve: Curves.easeOutCubic,
                            height: totalBottomHeight,
                            color: (isEmojiOpen || viewInsetsBottom > 0) 
                              ? const Color(0xFFF9EED8).withOpacity(0.95)
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
}
