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
              if (!isNight)
                Positioned(
                  top: -100,
                  right: -50,
                  child: Container(
                    width: 300,
                    height: 300,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          const Color(0xFFFFD97D).withValues(alpha: 0.1),
                          Colors.transparent,
                        ],
                      ),
                    ),
                  ),
                ),
              if (!isNight)
                Positioned(
                  bottom: 100,
                  left: -80,
                  child: Container(
                    width: 250,
                    height: 250,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          const Color(0xFFEFEBE9).withValues(alpha: 0.3),
                          Colors.transparent,
                        ],
                      ),
                    ),
                  ),
                ),

              SafeArea(
                child: Column(
                  children: [
                    _buildAppBar(context, isNight),
                    _buildPreviewHero(currentDecoration, isNight),
                    const SizedBox(height: 8),

                    Expanded(
                      child: SingleChildScrollView(
                        physics: const BouncingScrollPhysics(),
                        child: Column(
                          children: [
                            const SizedBox(height: 16),
                            // 2. 选择列表标题
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 24,
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    width: 6,
                                    height: 22,
                                    decoration: BoxDecoration(
                                      gradient: const LinearGradient(
                                        begin: Alignment.topCenter,
                                        end: Alignment.bottomCenter,
                                        colors: [
                                          Color(0xFFFFE082),
                                          Color(0xFFFFD54F),
                                        ],
                                      ),
                                      borderRadius: BorderRadius.circular(3),
                                      boxShadow: [
                                        BoxShadow(
                                          color: const Color(
                                            0xFFFFD97D,
                                          ).withValues(alpha: 0.3),
                                          blurRadius: 4,
                                          offset: const Offset(0, 2),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Text(
                                    '挑选装扮',
                                    style: TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                      color: isNight
                                          ? Colors.white
                                          : const Color(0xFF3E2723),
                                      fontFamily: 'LXGWWenKai',
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                  const Spacer(),
                                  Text(
                                    '${MascotDecoration.allDecorations.length + 1} 个选项',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: isNight
                                          ? Colors.white38
                                          : Colors.black26,
                                      fontFamily: 'LXGWWenKai',
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            const SizedBox(height: 16),

                            // 3. 装扮网格
                            GridView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
                              gridDelegate:
                                  const SliverGridDelegateWithFixedCrossAxisCount(
                                    crossAxisCount: 2,
                                    mainAxisSpacing: 16,
                                    crossAxisSpacing: 16,
                                    childAspectRatio: 0.8,
                                  ),
                              itemCount:
                                  MascotDecoration.allDecorations.length + 1,
                              itemBuilder: (context, index) {
                                if (index == 0) {
                                  // 裸装选项
                                  final bool isSelected =
                                      currentDecoration == null;
                                  return _buildDecorationItem(
                                        null,
                                        isSelected,
                                        isNight,
                                      )
                                      .animate(delay: (index * 50).ms)
                                      .fadeIn(duration: 400.ms)
                                      .moveY(
                                        begin: 20,
                                        end: 0,
                                        curve: Curves.easeOutCubic,
                                      );
                                }

                                final deco =
                                    MascotDecoration.allDecorations[index - 1];
                                final bool isSelected =
                                    (currentDecoration == deco.path);

                                return _buildDecorationItem(
                                      deco,
                                      isSelected,
                                      isNight,
                                    )
                                    .animate(delay: (index * 50).ms)
                                    .fadeIn(duration: 400.ms)
                                    .moveY(
                                      begin: 20,
                                      end: 0,
                                      curve: Curves.easeOutCubic,
                                    );
                              },
                            ),
                          ],
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
      height: 280,
      margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
      decoration: BoxDecoration(
        color: isNight
            ? Colors.white.withValues(alpha: 0.03)
            : const Color(0xFFF9F8F1).withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(32),
        border: Border.all(
          color: isNight
              ? Colors.white10
              : const Color(0xFFEFEBE9).withValues(alpha: 0.5),
          width: 1,
        ),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // 小软本体与装扮
          Padding(
            padding: const EdgeInsets.only(top: 10),
            child:
                StaticSprite(
                      key: ValueKey(decorationPath), // 强制重建以触发动画
                      assetPath: 'assets/images/emoji/marshmallow.png',
                      decorationPath: decorationPath,
                      size: 200,
                    )
                    .animate()
                    .scale(
                      duration: 400.ms,
                      curve: Curves.easeOutBack,
                      begin: const Offset(0.9, 0.9),
                    )
                    .fadeIn(duration: 400.ms)
                    .shimmer(
                      delay: 800.ms,
                      duration: 2000.ms,
                      color: Colors.white.withValues(alpha: 0.1),
                    ),
          ),

          Positioned(
            bottom: 16,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              decoration: BoxDecoration(
                color: isNight
                    ? Colors.white.withValues(alpha: 0.05)
                    : const Color(0xFF3E2723).withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isNight
                      ? Colors.white10
                      : Colors.black.withValues(alpha: 0.05),
                  width: 1,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.remove_red_eye_outlined,
                    size: 14,
                    color: isNight
                        ? Colors.white38
                        : const Color(0xFF3E2723).withValues(alpha: 0.4),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    "当前外观预览",
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: isNight
                          ? Colors.white38
                          : const Color(0xFF3E2723).withValues(alpha: 0.4),
                      fontFamily: 'LXGWWenKai',
                    ),
                  ),
                ],
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
        curve: Curves.easeOutCubic,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isSelected
              ? (isNight
                    ? const Color(0xFFFFD97D).withValues(alpha: 0.15)
                    : const Color(0xFFFFF9C4))
              : (isNight ? Colors.white.withValues(alpha: 0.03) : Colors.white),
          borderRadius: BorderRadius.circular(28),
          border: Border.all(
            color: isSelected
                ? const Color(0xFFFFD97D)
                : (isNight ? Colors.white10 : const Color(0xFFEFEBE9)),
            width: isSelected ? 2 : 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: const Color(
                      0xFFFFD97D,
                    ).withValues(alpha: isNight ? 0.2 : 0.4),
                    blurRadius: 15,
                    spreadRadius: -2,
                    offset: const Offset(0, 8),
                  ),
                ]
              : [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: isNight ? 0.1 : 0.02),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
        ),
        child: Stack(
          children: [
            Column(
              children: [
                Expanded(
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isNight
                          ? Colors.white.withValues(alpha: 0.02)
                          : const Color(0xFFFDFCF7),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: deco == null
                        ? Center(
                            child: Icon(
                              Icons.block_rounded,
                              size: 40,
                              color: isNight ? Colors.white24 : Colors.black12,
                            ),
                          )
                        : Image.asset(deco.path, fit: BoxFit.contain)
                              .animate(target: isSelected ? 1 : 0)
                              .scale(
                                duration: 300.ms,
                                begin: const Offset(1, 1),
                                end: const Offset(1.1, 1.1),
                              ),
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  deco?.name ?? '取消',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: isNight ? Colors.white : const Color(0xFF3E2723),
                    fontFamily: 'LXGWWenKai',
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  deco?.description ?? '回归最初的纯净模样',
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 10,
                    color: isNight ? Colors.white38 : const Color(0xFF8D6E63),
                    fontFamily: 'LXGWWenKai',
                  ),
                ),
              ],
            ),
            if (isSelected)
              Positioned(
                top: 0,
                right: 0,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: const BoxDecoration(
                    color: Color(0xFFFFD97D),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.check,
                    size: 14,
                    color: Color(0xFF3E2723),
                  ),
                ).animate().scale(duration: 300.ms, curve: Curves.easeOutBack),
              ),
          ],
        ),
      ),
    );
  }
}
