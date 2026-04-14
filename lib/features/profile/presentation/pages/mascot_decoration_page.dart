import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:island_diary/core/state/user_state.dart';
import 'package:island_diary/shared/widgets/static_sprite.dart';
import 'package:island_diary/core/models/mascot_decoration.dart';

class MascotDecorationPage extends StatefulWidget {
  const MascotDecorationPage({super.key});

  @override
  State<MascotDecorationPage> createState() => _MascotDecorationPageState();
}

class _MascotDecorationPageState extends State<MascotDecorationPage> {
  // 不再需要本地定义的 _decorations 列表，统一使用 MascotDecoration.allDecorations

  @override
  Widget build(BuildContext context) {
    final userState = UserState();
    final bool isNight = userState.isNight;

    return ListenableBuilder(
      listenable: userState.selectedMascotDecoration,
      builder: (context, _) {
        final currentDecoration = userState.selectedMascotDecoration.value;

        return Scaffold(
          backgroundColor: isNight
              ? const Color(0xFF13131F)
              : const Color(0xFFFDFCF7),
          body: Stack(
            children: [
              // 背景装饰
              _buildBackgroundDecoration(isNight),

              SafeArea(
                child: Column(
                  children: [
                    _buildAppBar(context, isNight),

                    // 1. 顶部大预览
                    _buildPreviewHero(currentDecoration, isNight),

                    const SizedBox(height: 32),

                    // 2. 选择列表标题
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Row(
                        children: [
                          Container(
                            width: 4,
                            height: 18,
                            decoration: BoxDecoration(
                              color: const Color(0xFFFFD97D),
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Text(
                            '挑选装扮',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: isNight
                                  ? Colors.white
                                  : const Color(0xFF3E2723),
                              fontFamily: 'LXGWWenKai',
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 20),

                    // 3. 装扮网格
                    Expanded(
                      child: GridView.builder(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 10,
                        ),
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          mainAxisSpacing: 16,
                          crossAxisSpacing: 16,
                          childAspectRatio: 0.85,
                        ),
                        itemCount: MascotDecoration.allDecorations.length + 1,
                        itemBuilder: (context, index) {
                          if (index == 0) {
                            // 裸装选项
                            final bool isSelected = currentDecoration == null;
                            return _buildDecorationItem(
                              null,
                              isSelected,
                              isNight,
                            );
                          }

                          final deco = MascotDecoration.allDecorations[index - 1];
                          final bool isSelected = (currentDecoration == deco.path);

                          return _buildDecorationItem(
                            deco,
                            isSelected,
                            isNight,
                          );
                        },
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

  Widget _buildAppBar(BuildContext context, bool isNight) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: Icon(
              Icons.arrow_back_ios_new_rounded,
              color: isNight ? Colors.white70 : const Color(0xFF3E2723),
            ),
          ),
          const Spacer(),
          Text(
            '小软装扮中心',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: isNight ? Colors.white : const Color(0xFF3E2723),
              fontFamily: 'LXGWWenKai',
            ),
          ),
          const Spacer(),
          const SizedBox(width: 48), // 占位
        ],
      ),
    );
  }

  Widget _buildPreviewHero(String? decorationPath, bool isNight) {
    return Container(
      width: double.infinity,
      height: 240,
      margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // 呼吸光晕
          Container(
                width: 160,
                height: 160,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFFFFD97D).withOpacity(0.15),
                ),
              )
              .animate(onPlay: (c) => c.repeat(reverse: true))
              .scale(
                begin: const Offset(0.8, 0.8),
                end: const Offset(1.1, 1.1),
                duration: 2000.ms,
              ),

          // 小软本体与装扮
          StaticSprite(
            assetPath: 'assets/images/emoji/pedding.png',
            decorationPath: decorationPath,
            size: 200,
          ).animate().slideY(begin: 0.1, end: 0, curve: Curves.easeOutBack),

          Positioned(
            bottom: 20,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              decoration: BoxDecoration(
                color: isNight
                    ? Colors.white.withOpacity(0.05)
                    : Colors.black.withOpacity(0.03),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                "当前外观预览",
                style: TextStyle(
                  fontSize: 12,
                  color: isNight ? Colors.white38 : Colors.black38,
                  fontFamily: 'LXGWWenKai',
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDecorationItem(
    MascotDecoration? deco,
    bool isSelected,
    bool isNight,
  ) {
    return GestureDetector(
      onTap: () {
        if (deco == null) {
          UserState().setMascotDecoration(null);
        } else {
          UserState().setMascotDecoration(deco.path);
        }
      },
      child: AnimatedContainer(
        duration: 300.ms,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(0xFFFFD97D).withOpacity(isNight ? 0.2 : 0.4)
              : (isNight ? Colors.white.withOpacity(0.05) : Colors.white),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: isSelected ? const Color(0xFFFFD97D) : Colors.transparent,
            width: 2,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: const Color(0xFFFFD97D).withOpacity(0.3),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ]
              : [],
        ),
        child: Column(
          children: [
            Expanded(
              child: deco == null
                  ? Icon(
                      Icons.close_rounded,
                      size: 48,
                      color: isNight ? Colors.white24 : Colors.black12,
                    )
                  : Image.asset(deco.path, fit: BoxFit.contain),
            ),
            const SizedBox(height: 12),
            Text(
              deco?.name ?? '裸装',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: isNight ? Colors.white : const Color(0xFF3E2723),
                fontFamily: 'LXGWWenKai',
              ),
            ),
            Text(
              deco?.description ?? '回归最初的纯净模样',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 10,
                color: isNight ? Colors.white38 : Colors.black38,
                fontFamily: 'LXGWWenKai',
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBackgroundDecoration(bool isNight) {
    return Positioned.fill(
      child: Stack(
        children: [
          Positioned(
            top: -100,
            right: -100,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(
                  0xFFFFD97D,
                ).withOpacity(isNight ? 0.05 : 0.08),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
