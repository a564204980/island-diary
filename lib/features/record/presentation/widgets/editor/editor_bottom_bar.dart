import 'package:flutter/material.dart';
import 'package:island_diary/shared/widgets/diary_entry/components/emoji_panel.dart';
import 'package:island_diary/shared/widgets/diary_entry/utils/diary_utils.dart';
import 'package:island_diary/shared/widgets/diary_entry/models/diary_block.dart';
import 'package:island_diary/core/state/user_state.dart';

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
  final VoidCallback onStickerClick;
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
    required this.onStickerClick,
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

    final bool isFloating = !isEmojiOpen && viewInsetsBottom <= 0;
    final bool showPreviewBar = !isMixedLayout && blocks.whereType<ImageBlock>().isNotEmpty;

    return Align(
      alignment: Alignment.bottomCenter,
      child: AnimatedPadding(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOutCubic,
        padding: EdgeInsets.fromLTRB(
          isFloating ? 20 : 0,
          0,
          isFloating ? 20 : 0,
          isFloating ? (6 + MediaQuery.of(context).padding.bottom) : 0,
        ),
        child: Container(
          width: toolbarMaxWidth,
          decoration: BoxDecoration(
            color: isNight 
                ? const Color(0xFF1E1E1E).withValues(alpha: 0.98) 
                : const Color(0xFFFAF8F5).withValues(alpha: 0.98),
            borderRadius: isFloating 
                ? BorderRadius.circular(32)
                : const BorderRadius.vertical(top: Radius.circular(24)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isFloating ? 0.12 : 0.05),
                blurRadius: isFloating ? 25 : 10,
                offset: Offset(0, isFloating ? 8 : -2),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // 1. 图片上传预览条 (仅在非混排模式下显示图片列表)
              if (!isMixedLayout)
                _buildImageUploadPreviewBar(),
                
              // 2. 标签式工具栏
              Padding(
                padding: EdgeInsets.fromLTRB(
                  4,
                  showPreviewBar ? 8 : 18,
                  4,
                  12,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildNavItem("图片", Icons.image_outlined, false, onImagePick),
                    _buildNavItem("贴纸", Icons.auto_awesome_motion_outlined, false, onStickerClick),
                    _buildNavItem("表情", Icons.face_rounded, isEmojiOpen, onEmojiToggle),
                    _buildNavItem("文字", Icons.title_rounded, false, onFontSizeClick),
                    _buildNavItem("涂鸦", Icons.brush_outlined, false, onColorClick),
                    _buildNavItem("背景", Icons.wallpaper_rounded, false, onBgColorClick),
                    _buildNavItem("更多", Icons.more_horiz_rounded, false, onMoreClick),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(String label, IconData icon, bool isActive, VoidCallback onTap) {
    final themeId = UserState().selectedIslandThemeId.value;
    final bool isCottonCandyDark = (themeId == 'cotton_candy') && isNight;

    final Color color = isNight ? Colors.white70 : Colors.black54;
    final Color activeColor = isNight ? const Color(0xFFE0C097) : const Color(0xFF7A7A6A);

    final Color itemColor = isCottonCandyDark
        ? (isActive
            ? const Color(0xFFC3AFFD)
            : const Color(0xFFC3AFFD).withValues(alpha: 0.7))
        : (isActive ? activeColor : color.withValues(alpha: 0.6));

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 26,
            color: itemColor,
          ),
          const SizedBox(height: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: itemColor,
              fontFamily: 'LXGWWenKai',
              fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
            ),
          ),
          if (isActive)
            Container(
              margin: const EdgeInsets.only(top: 4),
              width: 12,
              height: 2,
              decoration: BoxDecoration(
                color: itemColor,
                borderRadius: BorderRadius.circular(1),
              ),
            )
          else
            const SizedBox(height: 6),
        ],
      ),
    );
  }

  Widget _buildImageUploadPreviewBar() {
    final imageBlocks = blocks.whereType<ImageBlock>().toList();
    if (imageBlocks.isEmpty) return const SizedBox.shrink();

    return Container(
      height: 86,
      margin: const EdgeInsets.only(left: 20, right: 12, top: 12),
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
