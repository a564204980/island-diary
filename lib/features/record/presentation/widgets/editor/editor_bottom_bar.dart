import 'dart:ui';
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

    final bool isFloating = !isEmojiOpen;
    final bool showPreviewBar = !isMixedLayout && blocks.whereType<ImageBlock>().isNotEmpty;

    final themeId = UserState().selectedIslandThemeId.value;
    final bool isLego = themeId == 'lego';

    // 动态色彩与立体装饰配置
    final Color barBgColor = isLego
        ? (isNight ? const Color(0xFF2C2518) : const Color(0xFFFCF0D5))
        : (isNight 
            ? const Color(0xFF1E1E1E).withValues(alpha: 0.98) 
            : const Color(0xFFFAF8F5).withValues(alpha: 0.98));

    final List<BoxShadow> barShadows = isLego
        ? [
            // 1. 紧致的 3D 积木厚度实色层（零羽化）
            BoxShadow(
              color: isNight
                  ? const Color(0xFF1B160E)
                  : const Color(0xFFEADAB9),
              blurRadius: 0,
              offset: const Offset(0, 4.0),
            ),
            // 2. 底部极为克制的微羽化软影
            BoxShadow(
              color: isNight
                  ? Colors.black.withValues(alpha: 0.4)
                  : const Color(0xFFDCC8A0).withValues(alpha: 0.4),
              blurRadius: 3.0,
              offset: const Offset(0, 5.0),
            ),
          ]
        : [
            BoxShadow(
              color: Colors.black.withValues(alpha: isFloating ? 0.12 : 0.05),
              blurRadius: isFloating ? 25 : 10,
              offset: Offset(0, isFloating ? 8 : -2),
            ),
          ];

    final Border? barBorder = null;

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
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            // 1. 立体积木大底板
            Container(
              width: toolbarMaxWidth,
              decoration: BoxDecoration(
                color: barBgColor,
                borderRadius: isFloating 
                    ? BorderRadius.circular(32)
                    : const BorderRadius.vertical(top: Radius.circular(24)),
                border: barBorder,
                boxShadow: barShadows,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // 1.1 图片上传预览条 (仅在非混排模式下显示图片列表)
                  if (!isMixedLayout)
                    _buildImageUploadPreviewBar(),
                    
                  // 1.2 标签式工具栏 (为两侧积木突起 Studs 拓宽左右 Padding)
                  Padding(
                    padding: EdgeInsets.fromLTRB(
                      isLego ? 26 : 4,
                      showPreviewBar ? 8 : 18,
                      isLego ? 26 : 4,
                      12,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildNavItem("图片", Icons.image_outlined, false, onImagePick),
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
            
            // 2. 乐高底板专属：圆形突起积木颗粒 (Studs) - 营造 3D 拼装凸出视觉
            if (isLego && isFloating) ...[
              // 左边大 Stud
              Positioned(
                left: 10,
                top: 20,
                child: _buildLegoStud(isNight, size: 14),
              ),
              // 左边小 Stud
              Positioned(
                left: 17,
                bottom: 14,
                child: _buildLegoStud(isNight, size: 10),
              ),
              // 右边大 Stud
              Positioned(
                right: 10,
                top: 20,
                child: _buildLegoStud(isNight, size: 14),
              ),
              // 右边小 Stud
              Positioned(
                right: 17,
                bottom: 14,
                child: _buildLegoStud(isNight, size: 10),
              ),
            ],
          ],
        ),
      ),
    );
  }

  /// 渲染逼真的乐高拼装圆形突起 (Studs) - 带有独立的微距高光与阴影
  Widget _buildLegoStud(bool isNight, {required double size}) {
    final Color studColor = isNight ? const Color(0xFF2C2518) : const Color(0xFFFCF0D5);
    final Color highlightColor = isNight ? const Color(0xFF433927) : const Color(0xFFFFFCEE);
    final Color shadowColor = isNight ? const Color(0xFF1B160E) : const Color(0xFFDCC8A0);

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: studColor,
        shape: BoxShape.circle,
        boxShadow: [
          // 凸起下方的颗粒投影
          BoxShadow(
            color: shadowColor.withValues(alpha: 0.95),
            blurRadius: 1.8,
            offset: const Offset(0.5, 1.2),
          ),
          // 凸起边缘微亮边模拟软反射
          BoxShadow(
            color: highlightColor.withValues(alpha: 0.8),
            blurRadius: 0.8,
            offset: const Offset(-0.3, -0.3),
          ),
        ],
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

    Widget iconWidget;
    if (themeId == 'lego') {
      final Map<String, String> legoIcons = {
        "图片": "assets/images/theme/legao/pages/tupian.png",
        "表情": "assets/images/theme/legao/pages/biaoqing.png",
        "文字": "assets/images/theme/legao/pages/wenzi.png",
        "涂鸦": "assets/images/theme/legao/pages/tuya.png",
        "背景": "assets/images/theme/legao/pages/beijing.png",
        "更多": "assets/images/theme/legao/pages/gengduo.png",
      };
      final iconPath = legoIcons[label];
      if (iconPath != null) {
        iconWidget = Opacity(
          opacity: isActive ? 1.0 : 0.65,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              // 1. 底层：通过高斯模糊与暗色叠加制作的超写实异形软阴影
              Positioned(
                top: 2.2, // 向下偏移以形成写实的浮空立体感
                left: 0.5,
                right: -0.5,
                bottom: -2.2,
                child: ImageFiltered(
                  imageFilter: ImageFilter.blur(sigmaX: 1.6, sigmaY: 1.6), // 恰到好处的模糊半径
                  child: Image.asset(
                    iconPath,
                    width: 26,
                    height: 26,
                    fit: BoxFit.contain,
                    color: Colors.black.withValues(alpha: 0.16), // 极其柔和的阴影纯色
                    colorBlendMode: BlendMode.srcIn,
                  ),
                ),
              ),
              // 2. 顶层：精美的乐高积木原图
              Image.asset(
                iconPath,
                width: 26,
                height: 26,
                fit: BoxFit.contain,
              ),
            ],
          ),
        );
      } else {
        iconWidget = Icon(icon, size: 26, color: itemColor);
      }
    } else {
      iconWidget = Icon(icon, size: 26, color: itemColor);
    }

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          iconWidget,
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
