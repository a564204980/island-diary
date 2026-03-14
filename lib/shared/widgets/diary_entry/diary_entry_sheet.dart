import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'components/diary_paper_canvas.dart';
import 'components/diary_toolbar.dart';
import 'components/emoji_panel.dart';
import 'components/diary_block_item.dart';
import 'components/mood_tag.dart';
import 'components/hand_drawn_divider.dart';
import '../mood_picker/config/mood_config.dart';
import 'utils/diary_utils.dart';
import 'mixins/diary_editor_mixin.dart';

class MoodDiaryEntrySheet extends StatefulWidget {
  final int moodIndex;
  final double intensity;

  const MoodDiaryEntrySheet({
    super.key,
    required this.moodIndex,
    required this.intensity,
  });

  @override
  State<MoodDiaryEntrySheet> createState() => _MoodDiaryEntrySheetState();
}

class _MoodDiaryEntrySheetState extends State<MoodDiaryEntrySheet>
    with DiaryEditorMixin {
  @override
  void initState() {
    super.initState();
    initializeEditor();
  }

  @override
  Widget build(BuildContext context) {
    final double screenHeight = MediaQuery.of(context).size.height;
    final mood = kMoods[widget.moodIndex];

    return PopScope(
      canPop: false,
      child: Scaffold(
        resizeToAvoidBottomInset: false,
        backgroundColor: Colors.transparent,
        body: Stack(
          children: [
            GestureDetector(
              onTap: () {
                FocusScope.of(context).unfocus();
                if (isEmojiOpen) toggleEmoji();
              },
              child: Container(
                width: double.infinity,
                height: double.infinity,
                color: Colors.transparent,
                child: SafeArea(
                  child: Column(
                    children: [
                      const SizedBox(height: 84),
                      Expanded(
                        child: Stack(
                          clipBehavior: Clip.none,
                          alignment: Alignment.topCenter,
                          children: [
                            Builder(
                              builder: (context) {
                                final viewInsets = MediaQuery.of(
                                  context,
                                ).viewInsets;
                                final double bottomOffset = math.max(
                                  viewInsets.bottom,
                                  isEmojiOpen ? keyboardHeight : 0,
                                );

                                final double topAreaHeight = 84.0;
                                final double bottomAreaHeight = 60.0;
                                final double maxPaperHeight =
                                    screenHeight * 0.88;

                                final double availableHeight =
                                    screenHeight -
                                    topAreaHeight -
                                    bottomAreaHeight -
                                    bottomOffset;
                                final double dynamicHeight =
                                    availableHeight < maxPaperHeight
                                    ? availableHeight
                                    : maxPaperHeight;

                                final double screenWidthForPadding =
                                    MediaQuery.of(context).size.width;
                                final bool isWide = screenWidthForPadding > 600;
                                final double horizontalPadding = isWide
                                    ? 50.0
                                    : 32.0;
                                final double paperMaxWidth = isWide
                                    ? screenWidthForPadding * 0.7
                                    : double.infinity;

                                return AnimatedContainer(
                                  duration: const Duration(milliseconds: 250),
                                  curve: Curves.easeOutCubic,
                                  onEnd: ensureCursorVisible,
                                  height: dynamicHeight,
                                  constraints: BoxConstraints(
                                    maxWidth: paperMaxWidth,
                                  ),
                                  width: double.infinity,
                                  child: DiaryPaperCanvas(
                                    shadowColor: mood.glowColor,
                                    padding: EdgeInsets.fromLTRB(
                                      horizontalPadding,
                                      28,
                                      horizontalPadding,
                                      48,
                                    ),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceBetween,
                                          crossAxisAlignment:
                                              CrossAxisAlignment.end,
                                          children: [
                                            Text(
                                              DiaryUtils.getFormattedTime(),
                                              style: const TextStyle(
                                                fontSize: 28,
                                                fontWeight: FontWeight.bold,
                                                color: Color(0xFF8B5E3C),
                                              ),
                                            ),
                                            Text(
                                              DiaryUtils.getFormattedDate(),
                                              style: const TextStyle(
                                                fontSize: 16,
                                                color: Color(0xFFA68A78),
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 8),
                                        Text(
                                          fixedQuote,
                                          style: TextStyle(
                                            fontFamily: 'FZKai',
                                            fontSize: 14,
                                            fontStyle: FontStyle.italic,
                                            color: const Color(
                                              0xFF8B5E3C,
                                            ).withOpacity(0.7),
                                          ),
                                        ),
                                        const SizedBox(height: 6),
                                        CustomPaint(
                                          size: const Size(double.infinity, 2),
                                          painter: HandDrawnLinePainter(
                                            color: const Color(
                                              0xFF8B5E3C,
                                            ).withOpacity(0.8),
                                            strokeWidth: 1.5,
                                          ),
                                        ),
                                        const SizedBox(height: 8),
                                        Expanded(
                                          child: ListView.builder(
                                            controller: scrollController,
                                            padding: EdgeInsets.zero,
                                            itemCount: blocks.length,
                                            itemBuilder: (context, index) {
                                              final block = blocks[index];
                                              final key = blockKeys[block.id];

                                              return DiaryBlockItem(
                                                key: ValueKey(block.id),
                                                block: block,
                                                index: index,
                                                isEmojiOpen:
                                                    (isEmojiOpen ||
                                                    isColorPickerOpen),
                                                blockKey: key,
                                                onRemoveImage: () =>
                                                    removeImage(index),
                                                onShowPreview: showImagePreview,
                                              );
                                            },
                                          ),
                                        ),
                                        Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceBetween,
                                          children: [
                                            TextButton(
                                              onPressed: () =>
                                                  Navigator.of(context).pop(),
                                              child: const Text(
                                                '返回',
                                                style: TextStyle(
                                                  fontSize: 18,
                                                  color: Color(0xFFA68A78),
                                                ),
                                              ),
                                            ),
                                            TextButton(
                                              onPressed: onSave,
                                              child: const Text(
                                                '保存',
                                                style: TextStyle(
                                                  fontSize: 18,
                                                  fontWeight: FontWeight.bold,
                                                  color: Color(0xFF8B5E3C),
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
                            ).animate().fadeIn(duration: 500.ms),
                            Positioned(
                              top: -18,
                              child: MoodTag(
                                iconPath:
                                    mood.iconPath ??
                                    'assets/images/icons/sun.png',
                                description:
                                    DiaryUtils.getPersonifiedMoodDescription(
                                      mood.label,
                                      widget.intensity,
                                    ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            Positioned(
              bottom: MediaQuery.of(context).viewInsets.bottom,
              left: 0,
              right: 0,
              child: Builder(
                builder: (context) {
                  final double currentBottomAreaHeight = isEmojiOpen
                      ? keyboardHeight
                      : 0;
                  return Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      DiaryToolbar(
                        isEmojiOpen: isEmojiOpen,
                        isRecording: isRecording,
                        onEmojiToggle: toggleEmoji,
                        onRecordToggle: toggleRecord,
                        onImagePick: onImageButtonPressed,
                        onTopicClick: insertTopic,
                        onColorClick: showColorPicker,
                        onBgColorClick: showBackgroundColorPicker,
                        onLocationClick: onLocationClick,
                        onMusicPick: onMusicButtonPressed,
                        onFontSizeClick: showFontSizePicker,
                      ),
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 250),
                        curve: Curves.easeOutCubic,
                        height: currentBottomAreaHeight,
                        color: const Color(0xFFF9EED8).withOpacity(0.95),
                        child: isEmojiOpen
                            ? EmojiPanel(onEmojiSelected: onEmojiSelected)
                            : const SizedBox.shrink(),
                      ),
                    ],
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
