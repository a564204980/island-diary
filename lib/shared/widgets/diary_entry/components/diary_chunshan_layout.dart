import 'package:flutter/material.dart';
import 'package:island_diary/shared/widgets/diary_entry/utils/diary_utils.dart';
import 'package:island_diary/core/state/user_state.dart';

class DiaryChunshanLayout extends StatelessWidget {
  final List<String> imagePaths;
  final Function(int)? onDeleteImage;
  final Function(int)? onTapImage;

  const DiaryChunshanLayout({
    super.key,
    required this.imagePaths,
    this.onDeleteImage,
    this.onTapImage,
  });

  @override
  Widget build(BuildContext context) {
    if (imagePaths.isEmpty) {
      return const SizedBox.shrink();
    }

    final isNight = Theme.of(context).brightness == Brightness.dark;
    
    // High-end aesthetic variables
    final bgColor = isNight ? const Color(0xFF1A1A1A) : const Color(0xFFF9F9F9);
    final borderColor = isNight ? const Color(0xFF333333) : const Color(0xFFE5E5E5);
    final labelColor = isNight ? Colors.white54 : Colors.black54;

    return ListenableBuilder(
      listenable: Listenable.merge([
        UserState().chunshanBorderRadius,
        UserState().chunshanSpacing,
        UserState().chunshanAspectRatio,
        UserState().chunshanHasBackground,
      ]),
      builder: (context, _) {
        final borderRadius = UserState().chunshanBorderRadius.value;
        final spacing = UserState().chunshanSpacing.value;
        final aspectRatio = UserState().chunshanAspectRatio.value;
        final hasBackground = UserState().chunshanHasBackground.value;

        Widget content = Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header / Branding (only if hasBackground)
            if (hasBackground)
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'CHUNSHAN · JING',
                      style: TextStyle(
                        fontSize: 11,
                        letterSpacing: 2.5,
                        fontWeight: FontWeight.w600,
                        color: labelColor,
                        fontFamily: 'Inter',
                        fontFamilyFallback: const ['LXGWWenKai'],
                      ),
                    ),
                    Icon(
                      Icons.camera_outlined,
                      size: 16,
                      color: labelColor,
                    ),
                  ],
                ),
              ),
            
            // Film strip
            ...List.generate(imagePaths.length, (index) {
              final isLast = index == imagePaths.length - 1;
              final path = imagePaths[index];
              
              return Padding(
                padding: EdgeInsets.only(
                  left: hasBackground ? 12.0 : 0.0, 
                  right: hasBackground ? 12.0 : 0.0, 
                  bottom: isLast ? (hasBackground ? 20.0 : 0.0) : spacing,
                ),
                child: GestureDetector(
                  onTap: onTapImage != null ? () => onTapImage!(index) : null,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(borderRadius),
                    child: Stack(
                      children: [
                        AspectRatio(
                          aspectRatio: aspectRatio, // Cinematic wide format (approx 21:9)
                          child: Container(
                            color: isNight ? Colors.black26 : const Color(0xFFEAEAEA),
                            child: DiaryUtils.buildImage(
                              path, 
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                      if (onDeleteImage != null)
                        Positioned(
                          top: 14,
                          right: 14,
                          child: GestureDetector(
                            onTap: () => onDeleteImage!(index),
                            child: Container(
                              padding: const EdgeInsets.all(6),
                              decoration: const BoxDecoration(
                                color: Colors.black38,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.close,
                                color: Colors.white,
                                size: 18,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            );
          }),
          ],
        );

        if (!hasBackground) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 16.0),
            child: content,
          );
        }

        return Container(
          width: double.infinity,
          margin: const EdgeInsets.symmetric(vertical: 24.0),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(16.0),
            border: Border.all(color: borderColor, width: 1.0),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isNight ? 0.2 : 0.04),
                blurRadius: 16,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: content,
        );
      },
    );
  }
}
