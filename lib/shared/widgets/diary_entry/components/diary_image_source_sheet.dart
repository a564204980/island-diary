import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'diary_bottom_sheet.dart';
import '../utils/diary_utils.dart';
import 'package:island_diary/core/state/user_state.dart';
import 'package:island_diary/shared/widgets/island_vip_guard_dialog.dart';

import 'package:island_diary/shared/widgets/top_toast.dart';

class DiaryImageSourceSheet extends StatefulWidget {
  final String paperStyle;
  final bool? isMixedLayout;
  final bool? isImageGrid;
  final bool? isTextWrap;
  final Function(bool)? onMixedLayoutChanged;
  final Function(bool)? onImageGridChanged;
  final Function(bool)? onTextWrapChanged;

  const DiaryImageSourceSheet({
    key,
    this.paperStyle = 'standard',
    this.isMixedLayout,
    this.isImageGrid,
    this.isTextWrap,
    this.onMixedLayoutChanged,
    this.onImageGridChanged,
    this.onTextWrapChanged,
  }) : super(key: key);

  @override
  State<DiaryImageSourceSheet> createState() => _DiaryImageSourceSheetState();
}

class _DiaryImageSourceSheetState extends State<DiaryImageSourceSheet> {
  late bool _localMixedLayout;
  late bool _localImageGrid;
  late bool _localTextWrap;

  @override
  void initState() {
    super.initState();
    _localMixedLayout = widget.isMixedLayout ?? false;
    _localImageGrid = widget.isImageGrid ?? false;
    _localTextWrap = widget.isTextWrap ?? false;
  }

  @override
  Widget build(BuildContext context) {
    final bool isNight = UserState().isNight;
    final themeId = UserState().selectedIslandThemeId.value;
    final bool isLego = themeId == 'lego';
    final String fontFamily = isLego ? 'SweiFistLeg' : 'LXGWWenKai';

    final Color accentColor = DiaryUtils.getAccentColor(widget.paperStyle, isNight);
    final Color inkColor = DiaryUtils.getInkColor(widget.paperStyle, isNight);

    final showLayoutSettings = widget.onMixedLayoutChanged != null && widget.onImageGridChanged != null;

    return DiaryBottomSheet(
      paperStyle: widget.paperStyle,
      isDiary: false,
      showDragHandle: true,
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
      child: SafeArea(
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
                  Container(
                    decoration: BoxDecoration(
                      color: isNight ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.03),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    padding: const EdgeInsets.all(2.5),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _buildSegmentButton(
                          label: '图文混排',
                          isSelected: _localMixedLayout,
                          onTap: () {
                            if (!UserState().isVip.value) {
                              _showVipDialog('解锁高级编辑模式', '“图文混排”功能属于“星光计划”会员专享。开启后，您的图片将不再受布局限制。');
                              return;
                            }
                            setState(() {
                              _localMixedLayout = true;
                            });
                            widget.onMixedLayoutChanged?.call(true);
                          },
                          accentColor: accentColor,
                          inkColor: inkColor,
                          fontFamily: fontFamily,
                          isNight: isNight,
                        ),
                        _buildSegmentButton(
                          label: '统一置底',
                          isSelected: !_localMixedLayout,
                          onTap: () {
                            setState(() {
                              _localMixedLayout = false;
                              if (_localTextWrap) {
                                _localTextWrap = false;
                                widget.onTextWrapChanged?.call(false);
                              }
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
                  Container(
                    decoration: BoxDecoration(
                      color: isNight ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.03),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    padding: const EdgeInsets.all(2.5),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _buildSegmentButton(
                          label: '智能拼图',
                          isSelected: _localImageGrid,
                          onTap: () {
                            if (!UserState().isVip.value) {
                              _showVipDialog('解锁智能拼图排版', '“图片智能排版”功能属于“星光计划”会员专享。开启后，您的图片将以精致的海报拼图或网格形式呈现。');
                              return;
                            }
                            setState(() {
                              _localImageGrid = true;
                            });
                            widget.onImageGridChanged?.call(true);
                          },
                          accentColor: accentColor,
                          inkColor: inkColor,
                          fontFamily: fontFamily,
                          isNight: isNight,
                        ),
                        _buildSegmentButton(
                          label: '单图直排',
                          isSelected: !_localImageGrid,
                          onTap: () {
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
                  ),
                ],
              ),
              if (widget.onTextWrapChanged != null) ...[
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '文字环绕',
                      style: TextStyle(
                        fontSize: 14.5,
                        fontWeight: FontWeight.bold,
                        fontFamily: fontFamily,
                        color: inkColor.withValues(alpha: 0.75),
                      ),
                    ),
                    Container(
                      decoration: BoxDecoration(
                        color: isNight ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.03),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      padding: const EdgeInsets.all(2.5),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _buildSegmentButton(
                            label: '开启环绕',
                            isSelected: _localTextWrap,
                            onTap: () {
                              if (!_localMixedLayout) {
                                showTopToast(context, '开启环绕需启用图文混排');
                                return;
                              }
                              setState(() {
                                _localTextWrap = true;
                              });
                              widget.onTextWrapChanged?.call(true);
                            },
                            accentColor: accentColor,
                            inkColor: inkColor,
                            fontFamily: fontFamily,
                            isNight: isNight,
                          ),
                          _buildSegmentButton(
                            label: '独占整行',
                            isSelected: !_localTextWrap,
                            onTap: () {
                              setState(() {
                                _localTextWrap = false;
                              });
                              widget.onTextWrapChanged?.call(false);
                            },
                            accentColor: accentColor,
                            inkColor: inkColor,
                            fontFamily: fontFamily,
                            isNight: isNight,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ],
            const SizedBox(height: 8),
          ],
        ),
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
  }) {
    return Container(
      decoration: BoxDecoration(
        color: accentColor.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: accentColor.withValues(alpha: 0.1),
          width: 1.2,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => Navigator.pop(context, source),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  icon,
                  color: accentColor,
                  size: 28,
                ),
                const SizedBox(height: 8),
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
    );
  }

  Widget _buildSegmentButton({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
    required Color accentColor,
    required Color inkColor,
    required String fontFamily,
    required bool isNight,
  }) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOutCubic,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? (isNight ? Colors.white.withValues(alpha: 0.15) : Colors.white)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            if (isSelected)
              BoxShadow(
                color: Colors.black.withValues(alpha: isNight ? 0.2 : 0.06),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
          ],
        ),
        child: AnimatedDefaultTextStyle(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOutCubic,
          style: TextStyle(
            fontFamily: fontFamily,
            fontSize: 13,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
            color: isSelected
                ? (isNight ? accentColor : inkColor)
                : inkColor.withValues(alpha: 0.4),
          ),
          child: Text(label),
        ),
      ),
    );
  }
}
