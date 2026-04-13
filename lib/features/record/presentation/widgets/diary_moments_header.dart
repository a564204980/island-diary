import 'dart:io';
import 'package:flutter/material.dart';
import 'package:island_diary/core/state/user_state.dart';
import 'package:island_diary/shared/widgets/sprite_animation.dart';
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
    return ValueListenableBuilder<String?>(
      valueListenable: UserState().momentsCoverPath,
      builder: (context, coverPath, _) {
        return Container(
          height: 320,
          margin: const EdgeInsets.only(bottom: 20),
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              // 1. 封面背景图
              Positioned.fill(
                bottom: 40,
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
                            'assets/images/decoration/furniture/house.png',
                            fit: BoxFit.cover,
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
                          Colors.black.withOpacity(0.3),
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
                        color: Colors.black.withOpacity(0.2),
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
                    color: Colors.white.withOpacity(0.8),
                    size: 24,
                    shadows: const [
                      Shadow(
                        color: Colors.black26,
                        blurRadius: 10,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                ),
              ),

              // 4. 个人信息叠加层
              Positioned(
                right: 20,
                bottom: 10,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(bottom: 35, right: 12),
                      child: ValueListenableBuilder<String>(
                        valueListenable: UserState().userName,
                        builder: (context, name, _) {
                          return Text(
                            name.isEmpty ? "我" : name,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              fontFamily: 'LXGWWenKai',
                              shadows: [
                                Shadow(
                                  color: Colors.black45,
                                  blurRadius: 8,
                                  offset: Offset(0, 2),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                    Container(
                      width: 76,
                      height: 76,
                      padding: const EdgeInsets.all(2),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: Container(
                          color: isNight ? const Color(0xFF2C2E30) : const Color(0xFFFDF9F0),
                          child: const Center(
                            child: SpriteAnimation(
                              assetPath: 'assets/images/emoji/weixiao.png',
                              frameCount: 9,
                              duration: Duration(milliseconds: 1000),
                              size: 60.0,
                              isPlaying: true,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
