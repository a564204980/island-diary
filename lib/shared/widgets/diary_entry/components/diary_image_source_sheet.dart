import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'diary_bottom_sheet.dart';
import 'package:island_diary/core/state/user_state.dart';
import 'package:island_diary/shared/widgets/island_vip_guard_dialog.dart';


class DiaryImageSourceSheet extends StatefulWidget {
  final String paperStyle;
  final bool? isMixedLayout;
  final bool? isImageGrid;
  final Function(bool)? onMixedLayoutChanged;
  final Function(bool)? onImageGridChanged;

  const DiaryImageSourceSheet({
    super.key,
    this.paperStyle = 'standard',
    this.isMixedLayout,
    this.isImageGrid,
    this.onMixedLayoutChanged,
    this.onImageGridChanged,
  });

  @override
  State<DiaryImageSourceSheet> createState() => _DiaryImageSourceSheetState();
}

class _DiaryImageSourceSheetState extends State<DiaryImageSourceSheet> {
  late bool _localMixedLayout;
  late bool _localImageGrid;

  @override
  void initState() {
    super.initState();
    _localMixedLayout = widget.isMixedLayout ?? false;
    _localImageGrid = widget.isImageGrid ?? false;
  }

  @override
  Widget build(BuildContext context) {
    final bool isNight = UserState().isNight;
    final themeId = UserState().selectedIslandThemeId.value;
    final bool isLego = themeId == 'lego';
    final String fontFamily = isLego ? 'SweiFistLeg' : 'LXGWWenKai';

    final Color inkColor;
    final Color accentColor;
    
    if (isNight) {
      inkColor = Colors.white;
      accentColor = themeId == 'cotton_candy' ? const Color(0xFFC0A6FF) : const Color(0xFFE0C097);
    } else {
      inkColor = themeId == 'cotton_candy' ? const Color(0xFF7C3AED) : const Color(0xFF1F2937);
      accentColor = themeId == 'cotton_candy' ? const Color(0xFF7C3AED) : const Color(0xFF9C785A);
    }

    final showLayoutSettings = widget.onMixedLayoutChanged != null && widget.onImageGridChanged != null;

    return DiaryBottomSheet(
      paperStyle: widget.paperStyle,
      isDiary: false,
      showDragHandle: true,
      padding: const EdgeInsets.only(left: 24, right: 24, bottom: 24),
      child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header
            Padding(
              padding: EdgeInsets.zero,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '选择照片来源',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      fontFamily: fontFamily,
                      color: inkColor.withValues(alpha: 0.9),
                    ),
                  ),
                  IconButton(
                    icon: Icon(
                      Icons.close_rounded,
                      color: inkColor.withValues(alpha: 0.5),
                      size: 20,
                    ),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // Sources Row (Album & Camera side-by-side)
            Row(
              children: [
                Expanded(
                  child: _buildSourceButton(
                    context,
                    icon: Icons.photo_library_rounded,
                    label: '从相册选择',
                    source: ImageSource.gallery,
                    accentColor: accentColor,
                    inkColor: inkColor,
                    fontFamily: fontFamily,
                    isNight: isNight,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildSourceButton(
                    context,
                    icon: Icons.camera_alt_rounded,
                    label: '拍照',
                    source: ImageSource.camera,
                    accentColor: accentColor,
                    inkColor: inkColor,
                    fontFamily: fontFamily,
                    isNight: isNight,
                  ),
                ),
              ],
            ),

            if (showLayoutSettings) ...[
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '图片位置',
                    style: TextStyle(
                      fontSize: 14.5,
                      fontWeight: FontWeight.bold,
                      fontFamily: fontFamily,
                      color: inkColor.withValues(alpha: 0.75),
                    ),
                  ),
                  _buildSlidingSegmentControl(
                    firstLabel: '图文混排',
                    secondLabel: '统一置底',
                    isFirstSelected: _localMixedLayout,
                    onFirstTap: () {
                      if (!UserState().isVip.value) {
                        _showVipDialog('解锁高级编辑模式', '“图文混排”功能属于“星光计划”会员专享。开启后，您的图片将不再受布局限制。');
                        return;
                      }
                      setState(() {
                        _localMixedLayout = true;
                      });
                      widget.onMixedLayoutChanged?.call(true);
                    },
                    onSecondTap: () {
                      setState(() {
                        _localMixedLayout = false;
                      });
                      widget.onMixedLayoutChanged?.call(false);
                    },
                    accentColor: accentColor,
                    inkColor: inkColor,
                    fontFamily: fontFamily,
                    isNight: isNight,
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '拼图排版',
                    style: TextStyle(
                      fontSize: 14.5,
                      fontWeight: FontWeight.bold,
                      fontFamily: fontFamily,
                      color: inkColor.withValues(alpha: 0.75),
                    ),
                  ),
                  _buildSlidingSegmentControl(
                    firstLabel: '智能拼图',
                    secondLabel: '单图直排',
                    isFirstSelected: _localImageGrid,
                    onFirstTap: () {
                      if (!UserState().isVip.value) {
                        _showVipDialog('解锁智能拼图排版', '“图片智能排版”功能属于“星光计划”会员专享。开启后，您的图片将以精致的海报拼图或网格形式呈现。');
                        return;
                      }
                      setState(() {
                        _localImageGrid = true;
                      });
                      widget.onImageGridChanged?.call(true);
                    },
                    onSecondTap: () {
                      setState(() {
                        _localImageGrid = false;
                      });
                      widget.onImageGridChanged?.call(false);
                    },
                    accentColor: accentColor,
                    inkColor: inkColor,
                    fontFamily: fontFamily,
                    isNight: isNight,
                  ),
                  ],
                ),
              ],
            const SizedBox(height: 8),
          ],
        ),
    ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.15, end: 0, curve: Curves.easeOutCubic);
  }

  void _showVipDialog(String title, String description) {
    showDialog(
      context: context,
      builder: (context) => IslandVipGuardDialog(
        title: title,
        description: description,
      ),
    );
  }

  Widget _buildSourceButton(
    BuildContext context, {
    required IconData icon,
    required String label,
    required ImageSource source,
    required Color accentColor,
    required Color inkColor,
    required String fontFamily,
    required bool isNight,
  }) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isNight
              ? [
                  accentColor.withValues(alpha: 0.15),
                  accentColor.withValues(alpha: 0.03),
                ]
              : [
                  accentColor.withValues(alpha: 0.12),
                  accentColor.withValues(alpha: 0.02),
                ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isNight ? accentColor.withValues(alpha: 0.2) : accentColor.withValues(alpha: 0.15),
          width: 1.2,
        ),
        boxShadow: isNight
            ? []
            : [
                BoxShadow(
                  color: accentColor.withValues(alpha: 0.08),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                )
              ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () => Navigator.pop(context, source),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 12),
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    height: 80,
                    child: Center(
                      child: source == ImageSource.gallery
                          ? _buildAlbumIllustration(accentColor, isNight)
                          : _buildCameraIllustration(accentColor, isNight),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    label,
                    style: TextStyle(
                      fontFamily: fontFamily,
                      fontSize: 14.5,
                      fontWeight: FontWeight.bold,
                      color: inkColor.withValues(alpha: 0.85),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAlbumIllustration(Color accentColor, bool isNight) {
    return SizedBox(
      width: 70,
      height: 70,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Back photo
          Transform.translate(
            offset: const Offset(-8, -4),
            child: Transform.rotate(
              angle: -0.25,
              child: _buildPolaroid(accentColor.withValues(alpha: 0.4), isNight),
            ),
          ),
          // Front photo
          Transform.translate(
            offset: const Offset(4, 4),
            child: Transform.rotate(
              angle: 0.1,
              child: _buildPolaroid(accentColor, isNight),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPolaroid(Color color, bool isNight) {
    return Container(
      width: 44,
      height: 52,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: isNight ? Colors.grey[850] : Colors.white,
        borderRadius: BorderRadius.circular(6),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Column(
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Center(
                child: Icon(Icons.landscape_rounded, size: 20, color: color),
              ),
            ),
          ),
          const SizedBox(height: 10), // Bottom polaroid space
        ],
      ),
    );
  }

  Widget _buildCameraIllustration(Color accentColor, bool isNight) {
    return SizedBox(
      width: 70,
      height: 70,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Flash / Top piece
          Positioned(
            top: 14,
            child: Container(
              width: 24,
              height: 12,
              decoration: BoxDecoration(
                color: accentColor.withValues(alpha: 0.6),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
              ),
            ),
          ),
          // Camera body
          Positioned(
            top: 22,
            child: Container(
              width: 58,
              height: 40,
              decoration: BoxDecoration(
                color: accentColor,
                borderRadius: BorderRadius.circular(10),
                boxShadow: [
                  BoxShadow(
                    color: accentColor.withValues(alpha: 0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  )
                ],
              ),
            ),
          ),
          // Lens outer
          Positioned(
            top: 28,
            child: Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: isNight ? Colors.grey[850] : Colors.white,
                shape: BoxShape.circle,
              ),
              child: Center(
                // Lens inner
                child: Container(
                  width: 16,
                  height: 16,
                  decoration: BoxDecoration(
                    color: accentColor.withValues(alpha: 0.8),
                    shape: BoxShape.circle,
                  ),
                  child: Align(
                    alignment: Alignment.topLeft,
                    child: Padding(
                      padding: const EdgeInsets.only(left: 3, top: 3),
                      child: Container(
                        width: 4,
                        height: 4,
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }


  Widget _buildSlidingSegmentControl({
    required String firstLabel,
    required String secondLabel,
    required bool isFirstSelected,
    required VoidCallback onFirstTap,
    required VoidCallback onSecondTap,
    required Color accentColor,
    required Color inkColor,
    required String fontFamily,
    required bool isNight,
  }) {
    return Container(
      width: 172,
      height: 36,
      decoration: BoxDecoration(
        color: isNight ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(20),
      ),
      padding: const EdgeInsets.all(2.5),
      child: Stack(
        children: [
          // Sliding Thumb
          AnimatedAlign(
            duration: const Duration(milliseconds: 350),
            curve: Curves.easeOutCubic,
            alignment: isFirstSelected ? Alignment.centerLeft : Alignment.centerRight,
            child: FractionallySizedBox(
              widthFactor: 0.5,
              heightFactor: 1.0,
              child: Container(
                decoration: BoxDecoration(
                  color: isNight ? Colors.white.withValues(alpha: 0.15) : Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: isNight ? 0.2 : 0.06),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
              ),
            ),
          ),
          // Buttons
          Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: onFirstTap,
                  behavior: HitTestBehavior.opaque,
                  child: Center(
                    child: _buildSegmentButtonText(
                      label: firstLabel,
                      isSelected: isFirstSelected,
                      accentColor: accentColor,
                      inkColor: inkColor,
                      fontFamily: fontFamily,
                      isNight: isNight,
                    ),
                  ),
                ),
              ),
              Expanded(
                child: GestureDetector(
                  onTap: onSecondTap,
                  behavior: HitTestBehavior.opaque,
                  child: Center(
                    child: _buildSegmentButtonText(
                      label: secondLabel,
                      isSelected: !isFirstSelected,
                      accentColor: accentColor,
                      inkColor: inkColor,
                      fontFamily: fontFamily,
                      isNight: isNight,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSegmentButtonText({
    required String label,
    required bool isSelected,
    required Color accentColor,
    required Color inkColor,
    required String fontFamily,
    required bool isNight,
  }) {
    return AnimatedDefaultTextStyle(
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOutCubic,
      style: TextStyle(
        fontFamily: fontFamily,
        fontSize: 13,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
        color: isSelected
            ? accentColor
            : inkColor.withValues(alpha: 0.4),
      ),
      child: Text(label),
    );
  }
}
