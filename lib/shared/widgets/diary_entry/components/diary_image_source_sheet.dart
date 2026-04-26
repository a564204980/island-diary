import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../utils/diary_utils.dart';
import 'package:island_diary/core/state/user_state.dart';

class DiaryImageSourceSheet extends StatelessWidget {
  final String paperStyle;

  const DiaryImageSourceSheet({
    super.key,
    this.paperStyle = 'standard',
  });

  @override
  Widget build(BuildContext context) {
    final bool isNight = UserState().isNight;
    final Color accentColor = DiaryUtils.getAccentColor(paperStyle, isNight);
    final Color bgColor = DiaryUtils.getPopupBackgroundColor(paperStyle, isNight).withValues(alpha: 0.98);
    final Color inkColor = DiaryUtils.getInkColor(paperStyle, isNight);

    return Container(
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(32),
          topRight: Radius.circular(32),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 20,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 顶部装饰条
            const SizedBox(height: 12),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: accentColor.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 12),
            _buildOption(
              context,
              icon: Icons.photo_library_rounded,
              title: '从相册选择',
              source: ImageSource.gallery,
              accentColor: accentColor,
              inkColor: inkColor,
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Divider(height: 1, color: accentColor.withValues(alpha: 0.05)),
            ),
            _buildOption(
              context,
              icon: Icons.camera_alt_rounded,
              title: '拍照',
              source: ImageSource.camera,
              accentColor: accentColor,
              inkColor: inkColor,
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.2, end: 0, curve: Curves.easeOutCubic);
  }

  Widget _buildOption(
    BuildContext context, {
    required IconData icon,
    required String title,
    required ImageSource source,
    required Color accentColor,
    required Color inkColor,
  }) {
    return Material(
      color: Colors.transparent,
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: accentColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: accentColor, size: 24),
        ),
        title: Text(
          title,
          style: TextStyle(
            fontFamily: 'LXGWWenKai',
            fontSize: 17,
            fontWeight: FontWeight.w600,
            color: inkColor.withValues(alpha: 0.8),
          ),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
        onTap: () => Navigator.pop(context, source),
      ),
    );
  }
}
