import 'package:flutter/material.dart';
import 'package:island_diary/shared/widgets/diary_entry/utils/diary_utils.dart';
import 'package:island_diary/shared/widgets/diary_entry/models/diary_block.dart';

class EditorBottomBar extends StatelessWidget {
  final bool isEmojiOpen;
  final bool isNight;
  final String paperStyle;
  final Color accentColor;
  final double currentBottomHeight;
  final List<DiaryBlock> blocks;
  final bool isMixedLayout;

  final VoidCallback onEmojiToggle;
  final VoidCallback onImagePick;

  // 工具栏回调
  final VoidCallback onColorClick;
  final VoidCallback onBgColorClick;
  final VoidCallback onLocationClick;
  final VoidCallback onFontSizeClick;
  final VoidCallback onFontClick;
  final VoidCallback onDateClick;
  final VoidCallback onTimeClick;
  final VoidCallback onWeatherClick;
  final VoidCallback onMoreClick;
  final VoidCallback onClose;
  final VoidCallback onSave;

  final VoidCallback? onTagClick;
  final VoidCallback? onMusicPick;

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
    required this.onWeatherClick,
    required this.onMoreClick,
    required this.onClose,
    required this.onSave,
    this.onTagClick,
    this.onMusicPick,
    required this.onEmojiSelected,
    required this.onEmojiBackspace,
    required this.onEmojiSend,
    required this.onCustomEmojiSelected,
    required this.onRemoveImage,
  });

  @override
  Widget build(BuildContext context) {
    // 注意：不在此处读取 paddingOf / viewInsets，避免订阅后每帧重建
    // safeAreaBottom 改由底部独立 Builder 读取（见下方）
    final double screenWidth = MediaQuery.sizeOf(context).width;
    final bool isWide = screenWidth > 800;
    final double toolbarMaxWidth = isWide ? 800.0 : double.infinity;

    // 动态色彩配置（支持深色/浅色模式）
    final Color barBgColor = isNight 
        ? const Color(0xFF141426).withValues(alpha: 0.92) 
        : const Color(0xFFFAF9F6).withValues(alpha: 0.95);

    final Color iconColor = isNight
        ? Colors.white70
        : Colors.black87;

    return Container(
      margin: EdgeInsets.zero,
      width: toolbarMaxWidth,
      decoration: BoxDecoration(
        color: barBgColor,
        borderRadius: BorderRadius.zero,
      ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 图片上传预览条 (仅在非混排模式下显示图片列表)
            if (!isMixedLayout)
              _buildImageUploadPreviewBar(),
              
            // 工具栏主内容
            Container(
              height: 52,
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Row(
                children: [
                  // 左侧工具图标组，水平滑动以防小屏溢出
                  Expanded(
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      physics: const ClampingScrollPhysics(),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const SizedBox(width: 4),
                          // 1. A 按钮 (文字样式)
                          _buildTextButton(iconColor),
                          const SizedBox(width: 4),
                          // 2. 标签按钮
                          _buildToolbarIcon(Icons.local_offer_outlined, () {
                            if (onTagClick != null) {
                              onTagClick!();
                            } else {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('标签功能开发中...')),
                              );
                            }
                          }, iconColor),
                          const SizedBox(width: 4),
                          // 3. 图片
                          _buildToolbarIcon(Icons.image_outlined, onImagePick, iconColor),
                          const SizedBox(width: 4),
                          // 4. 视频
                          _buildToolbarIcon(Icons.play_circle_outline_rounded, () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('视频功能开发中...')),
                            );
                          }, iconColor),
                          const SizedBox(width: 4),
                          // 5. 音频
                          _buildToolbarIcon(Icons.music_note_outlined, () {
                            if (onMusicPick != null) {
                              onMusicPick!();
                            } else {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('音频录制/上传功能开发中...')),
                              );
                            }
                          }, iconColor),
                          const SizedBox(width: 4),
                          // 6. 文件夹 (背景模板)
                          _buildToolbarIcon(Icons.folder_open_outlined, onBgColorClick, iconColor),
                          const SizedBox(width: 4),
                          // 7. 麦克风 (语音输入)
                          _buildToolbarIcon(Icons.mic_none_outlined, () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('语音输入功能开发中...')),
                            );
                          }, iconColor),
                          const SizedBox(width: 4),
                          // 8. 太阳 (天气)
                          _buildToolbarIcon(Icons.wb_sunny_outlined, onWeatherClick, iconColor),
                          const SizedBox(width: 4),
                          // 9. 笑脸 (表情)
                          _buildToolbarIcon(
                            isEmojiOpen ? Icons.keyboard_alt_outlined : Icons.sentiment_satisfied_alt_outlined,
                            onEmojiToggle,
                            iconColor,
                          ),
                          const SizedBox(width: 4),
                          // 10. 定位 (位置)
                          _buildToolbarIcon(Icons.location_on_outlined, onLocationClick, iconColor),
                          const SizedBox(width: 8),
                        ],
                      ),
                    ),
                  ),
                  
                  // 右侧保存确认按钮
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: GestureDetector(
                      onTap: onSave,
                      child: Container(
                        width: 46,
                        height: 32,
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFF0E5),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: const Center(
                          child: Icon(
                            Icons.check_rounded,
                            color: Color(0xFFFA6400),
                            size: 20,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // 用独立 Builder 读取 paddingOf，仅此 SizedBox 重建，不影响整个工具栏
            Builder(
              builder: (ctx) {
                final double safeArea = MediaQuery.paddingOf(ctx).bottom;
                return SizedBox(height: safeArea);
              },
            ),
          ],
        ),
    );
  }

  Widget _buildTextButton(Color iconColor) {
    return InkWell(
      onTap: onFontSizeClick,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        child: Container(
          decoration: BoxDecoration(
            border: Border.all(color: iconColor.withValues(alpha: 0.8), width: 1.5),
            borderRadius: BorderRadius.circular(4),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
          child: Text(
            'A',
            style: TextStyle(
              color: iconColor.withValues(alpha: 0.8),
              fontSize: 12,
              fontWeight: FontWeight.bold,
              fontFamily: 'sans-serif',
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildToolbarIconButton({
    required Widget child,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.all(8),
        child: child,
      ),
    );
  }

  Widget _buildToolbarIcon(IconData icon, VoidCallback onTap, Color iconColor) {
    return _buildToolbarIconButton(
      onTap: onTap,
      child: Icon(
        icon,
        size: 22,
        color: iconColor.withValues(alpha: 0.8),
      ),
    );
  }

  Widget _buildImageUploadPreviewBar() {
    final imageBlocks = blocks.whereType<ImageBlock>().toList();
    if (imageBlocks.isEmpty) return const SizedBox.shrink();

    return Container(
      height: 60,
      margin: const EdgeInsets.only(left: 14, right: 12, top: 8, bottom: 0),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: imageBlocks.length,
        itemBuilder: (context, index) {
          final img = imageBlocks[index];
          return Padding(
            padding: const EdgeInsets.only(right: 10, top: 4),
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
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
                    borderRadius: BorderRadius.circular(10),
                    child: DiaryUtils.buildImage(img.file.path, fit: BoxFit.cover),
                  ),
                ),
                if (img.videoPath != null)
                  Positioned(
                    left: 3,
                    bottom: 3,
                    child: IgnorePointer(
                      child: Container(
                        padding: const EdgeInsets.all(2),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.45),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.motion_photos_on,
                          color: Colors.white,
                          size: 11,
                        ),
                      ),
                    ),
                  ),
                Positioned(
                  top: -5,
                  right: -5,
                  child: GestureDetector(
                    onTap: () => onRemoveImage(blocks.indexOf(img)),
                    child: Container(
                      padding: const EdgeInsets.all(3),
                      decoration: const BoxDecoration(color: Colors.black, shape: BoxShape.circle),
                      child: const Icon(Icons.close_rounded, color: Colors.white, size: 10),
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
