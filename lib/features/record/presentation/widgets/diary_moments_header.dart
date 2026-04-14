import 'package:flutter/material.dart';
import 'package:island_diary/core/state/user_state.dart';
import 'package:island_diary/shared/widgets/diary_entry/utils/diary_utils.dart';
import 'package:image_picker/image_picker.dart';

class DiaryMomentsHeader extends StatelessWidget {
  final bool isNight;
  final VoidCallback? onBack;
  const DiaryMomentsHeader({super.key, this.isNight = false, this.onBack});

  Future<void> _pickCover(BuildContext context) async {
    final picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      await UserState().setMomentsCoverPath(image.path);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isWide = MediaQuery.of(context).size.width > 800;
    final double headerHeight = isWide ? 420.0 : 320.0;

    return ValueListenableBuilder<String?>(
      valueListenable: UserState().momentsCoverPath,
      builder: (context, coverPath, _) {
        return Container(
          height: headerHeight,
          margin: EdgeInsets.only(bottom: isWide ? 40 : 20),
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              // 1. 封面背景图
              Positioned.fill(
                bottom: isWide ? 60 : 40,
                child: GestureDetector(
                  onTap: () => _pickCover(context),
                  child: Container(
                    decoration: BoxDecoration(
                      color: isNight ? const Color(0xFF1A1C1E) : const Color(0xFFF0F0F0),
                    ),
                    child: coverPath != null
                        ? DiaryUtils.buildImage(
                            coverPath,
                            fit: BoxFit.cover,
                          )
                        : Image.asset(
                            'assets/images/note/note_bg1.png',
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) => Container(
                              color: isNight ? const Color(0xFF1A1C1E) : const Color(0xFFD4A373).withValues(alpha: 0.1),
                              child: Center(
                                child: Icon(
                                  Icons.landscape_rounded,
                                  color: isNight ? Colors.white12 : Colors.black12,
                                  size: 48,
                                ),
                              ),
                            ),
                          ),
                  ),
                ),
              ),

              // 底部通透渐变遮罩 (增强内容衔接)
              Positioned(
                left: 0, right: 0, bottom: isWide ? 60 : 40,
                height: 80,
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        (isNight ? Colors.black : Colors.white).withValues(alpha: 0.2),
                      ],
                    ),
                  ),
                ),
              ),

              // 顶部阴影遮罩 (增强按钮可见性)
              Positioned(
                top: 0, left: 0, right: 0,
                height: 100,
                child: IgnorePointer(
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.black.withValues(alpha: 0.35),
                          Colors.transparent,
                        ],
                      ),
                    ),
                  ),
                ),
              ),

              // 2. 左上角返回按钮
              if (onBack != null)
                Positioned(
                  top: 20,
                  left: 20,
                  child: GestureDetector(
                    onTap: onBack,
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.25),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.arrow_back_ios_new_rounded,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                  ),
                ),

              // 3. 右上角相机图标 (更换封面)
              Positioned(
                top: 20,
                right: 20,
                child: GestureDetector(
                  onTap: () => _pickCover(context),
                  child: Icon(
                    Icons.camera_alt_rounded,
                    color: Colors.white.withValues(alpha: 0.9),
                    size: 26,
                    shadows: const [
                      Shadow(
                        color: Colors.black45,
                        blurRadius: 15,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
