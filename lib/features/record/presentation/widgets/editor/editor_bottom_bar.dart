import 'package:flutter/material.dart';
import 'package:island_diary/shared/widgets/diary_entry/components/diary_toolbar.dart';
import 'package:island_diary/shared/widgets/diary_entry/components/emoji_panel.dart';
import 'package:island_diary/shared/widgets/diary_entry/utils/diary_utils.dart';
import 'package:island_diary/shared/widgets/diary_entry/models/diary_block.dart';

class EditorBottomBar extends StatelessWidget {
  final bool isEmojiOpen;
  final bool isNight;
  final String paperStyle;
  final Color accentColor;
  final double currentBottomHeight;
  final double viewInsetsBottom;
  final List<DiaryBlock> blocks;
  final bool isMixedLayout;

  // 工具栏回调
  final VoidCallback onEmojiToggle;
  final VoidCallback onImagePick;
  final VoidCallback onColorClick;
  final VoidCallback onBgColorClick;
  final VoidCallback onLocationClick;
  final VoidCallback onFontSizeClick;
  final VoidCallback onFontClick;
  final VoidCallback onDateClick;
  final VoidCallback onTimeClick;
  final VoidCallback onCreateSticker;
  final VoidCallback onWeatherClick;
  final VoidCallback onMoreClick;
  final VoidCallback onClose;
  final VoidCallback onSave;

  // 表情面板回调
  final Function(String) onEmojiSelected;
  final VoidCallback onEmojiBackspace;
  final VoidCallback onEmojiSend;
  final Function(String) onCustomEmojiSelected;
  
  // 图片预览回调
  final Function(int) onRemoveImage;

  const EditorBottomBar({
    super.key,
    required this.isEmojiOpen,
    required this.isNight,
    required this.paperStyle,
    required this.accentColor,
    required this.currentBottomHeight,
    required this.viewInsetsBottom,
    required this.blocks,
    required this.isMixedLayout,
    required this.onEmojiToggle,
    required this.onImagePick,
    required this.onColorClick,
    required this.onBgColorClick,
    required this.onLocationClick,
    required this.onFontSizeClick,
    required this.onFontClick,
    required this.onDateClick,
    required this.onTimeClick,
    required this.onCreateSticker,
    required this.onWeatherClick,
    required this.onMoreClick,
    required this.onClose,
    required this.onSave,
    required this.onEmojiSelected,
    required this.onEmojiBackspace,
    required this.onEmojiSend,
    required this.onCustomEmojiSelected,
    required this.onRemoveImage,
  });

  @override
  Widget build(BuildContext context) {
    final double screenWidth = MediaQuery.of(context).size.width;
    final bool isWide = screenWidth > 800;
    final double toolbarMaxWidth = isWide ? 800.0 : double.infinity;

    return Align(
      alignment: Alignment.bottomCenter,
      child: SizedBox(
        width: toolbarMaxWidth,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 1. 图片上传预览条 (仅在非混排模式下显示图片列表)
            if (!isMixedLayout)
              _buildImageUploadPreviewBar(),
              
            const SizedBox(height: 8),
            
            // 2. 核心工具栏
            DiaryToolbar(
              isEmojiOpen: isEmojiOpen,
              onEmojiToggle: onEmojiToggle,
              onImagePick: onImagePick,
              onColorClick: onColorClick,
              onBgColorClick: onBgColorClick,
              onLocationClick: onLocationClick,
              onFontSizeClick: onFontSizeClick,
              onFontClick: onFontClick,
              onDateClick: onDateClick,
              onTimeClick: onTimeClick,
              onCreateSticker: onCreateSticker,
              onWeatherClick: onWeatherClick,
              onMoreClick: onMoreClick,
              onClose: onClose,
              onSave: onSave,
              accentColor: accentColor,
              isNightOverride: isNight,
              isNoteBackground: paperStyle.startsWith('note'),
              paperStyle: paperStyle,
            ),
            
            // 3. 表情面板/键盘占位区
            AnimatedContainer(
              duration: Duration(milliseconds: isEmojiOpen ? 150 : 250),
              curve: Curves.easeOutCubic,
              height: currentBottomHeight,
              color: (isEmojiOpen || viewInsetsBottom > 0)
                  ? DiaryUtils.getPopupBackgroundColor(paperStyle, isNight).withValues(alpha: 0.98)
                  : Colors.transparent,
              child: Visibility(
                visible: isEmojiOpen,
                maintainState: true,
                child: EmojiPanel(
                  onEmojiSelected: onEmojiSelected,
                  onBackspace: onEmojiBackspace,
                  onSend: onEmojiSend,
                  onCustomEmojiSelected: onCustomEmojiSelected,
                  paperStyle: paperStyle,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImageUploadPreviewBar() {
    final imageBlocks = blocks.whereType<ImageBlock>().toList();
    if (imageBlocks.isEmpty) return const SizedBox.shrink();

    return Container(
      height: 80,
      margin: const EdgeInsets.symmetric(horizontal: 12),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: imageBlocks.length,
        itemBuilder: (context, index) {
          final img = imageBlocks[index];
          return Padding(
            padding: const EdgeInsets.only(right: 12),
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  width: 70,
                  height: 70,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: accentColor.withValues(alpha: 0.2)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.05),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: DiaryUtils.buildImage(img.file.path, fit: BoxFit.cover),
                  ),
                ),
                Positioned(
                  top: -8,
                  right: -8,
                  child: GestureDetector(
                    onTap: () => onRemoveImage(blocks.indexOf(img)),
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(color: Colors.black, shape: BoxShape.circle),
                      child: const Icon(Icons.close_rounded, color: Colors.white, size: 16),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
