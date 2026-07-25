import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:island_diary/shared/animations/bouncing_button.dart';
import 'package:island_diary/shared/widgets/diary_entry/components/diary_bottom_sheet.dart';
import 'package:island_diary/shared/widgets/top_toast.dart';

/// 展板参数控制底部弹窗组件 (PhotoWallSettingsSheet)
class PhotoWallSettingsSheet extends StatefulWidget {
  final bool isNight;
  final bool showWashiTape;
  final ValueChanged<bool> onShowWashiTapeChanged;
  final VoidCallback onResetLayout;

  const PhotoWallSettingsSheet({
    super.key,
    required this.isNight,
    required this.showWashiTape,
    required this.onShowWashiTapeChanged,
    required this.onResetLayout,
  });

  /// 静态辅助弹出方法
  static void show(
    BuildContext context, {
    required bool isNight,
    required bool showWashiTape,
    required ValueChanged<bool> onShowWashiTapeChanged,
    required VoidCallback onResetLayout,
  }) {
    HapticFeedback.mediumImpact();

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (modalContext) {
        return PhotoWallSettingsSheet(
          isNight: isNight,
          showWashiTape: showWashiTape,
          onShowWashiTapeChanged: onShowWashiTapeChanged,
          onResetLayout: onResetLayout,
        );
      },
    );
  }

  @override
  State<PhotoWallSettingsSheet> createState() => _PhotoWallSettingsSheetState();
}

class _PhotoWallSettingsSheetState extends State<PhotoWallSettingsSheet> {
  late bool _showWashiTape;

  @override
  void initState() {
    super.initState();
    _showWashiTape = widget.showWashiTape;
  }

  @override
  Widget build(BuildContext context) {
    final bool isDark = widget.isNight;
    final Color textColor = isDark ? Colors.white : const Color(0xFF1E293B);
    final Color cardBg = isDark
        ? const Color(0xFF1E293B).withValues(alpha: 0.55)
        : const Color(0xFFF1F5F9).withValues(alpha: 0.75);
    final Color cardBorder = isDark
        ? Colors.white.withValues(alpha: 0.12)
        : const Color(0xFFE2E8F0);

    return DiaryBottomSheet(
      paperStyle: 'default',
      isDiary: false,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. 标题栏
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: isDark
                        ? [const Color(0xFF0EA5E9).withValues(alpha: 0.25), const Color(0xFF38BDF8).withValues(alpha: 0.15)]
                        : [const Color(0xFFE0F2FE), const Color(0xFFBAE6FD)],
                  ),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isDark ? const Color(0xFF38BDF8).withValues(alpha: 0.3) : const Color(0xFF7DD3FC),
                    width: 0.8,
                  ),
                ),
                child: Icon(
                  Icons.tune_rounded,
                  color: isDark ? const Color(0xFF38BDF8) : const Color(0xFF0284C7),
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                "展板风格设置",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: textColor,
                  letterSpacing: 0.3,
                ),
              ),
              const Spacer(),
              const DiaryBottomSheetCloseButton(),
            ],
          ),
          const SizedBox(height: 22),

          // 2. 饰品开关：手撕和纸胶带
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: cardBg,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: cardBorder, width: 0.8),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: isDark
                            ? Colors.amber.shade400.withValues(alpha: 0.15)
                            : const Color(0xFFFEF3C7),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        Icons.style_rounded,
                        size: 18,
                        color: isDark ? Colors.amber.shade300 : const Color(0xFFD97706),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "手撕和纸胶带饰品",
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: textColor.withValues(alpha: 0.95),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          "为照片顶角贴上复古和纸胶带",
                          style: TextStyle(
                            fontSize: 12,
                            color: textColor.withValues(alpha: 0.55),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                CupertinoSwitch(
                  value: _showWashiTape,
                  activeTrackColor: isDark ? const Color(0xFF38BDF8) : const Color(0xFF0284C7),
                  onChanged: (val) {
                    HapticFeedback.selectionClick();
                    setState(() {
                      _showWashiTape = val;
                    });
                    widget.onShowWashiTapeChanged(val);
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // 3. 重置散落排版按钮
          BouncingButton(
            onTap: () {
              HapticFeedback.mediumImpact();
              Navigator.pop(context);
              widget.onResetLayout();
              showTopToast(context, "🧹 已重置照片排版与姿态角度", icon: Icons.refresh_rounded);
            },
            scaleFactor: 0.98,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 14),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: isDark
                      ? [const Color(0xFF334155).withValues(alpha: 0.6), const Color(0xFF1E293B).withValues(alpha: 0.8)]
                      : [const Color(0xFFF8FAFC), const Color(0xFFF1F5F9)],
                ),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: isDark ? Colors.white.withValues(alpha: 0.15) : const Color(0xFFCBD5E1),
                  width: 0.8,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.restart_alt_rounded,
                    size: 19,
                    color: isDark ? const Color(0xFF38BDF8) : const Color(0xFF0284C7),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    "重置照片散落位置与角度",
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: isDark ? const Color(0xFFE2E8F0) : const Color(0xFF334155),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
        ],
      ),
    );
  }
}
