import 'package:flutter/material.dart';
import 'package:island_diary/core/state/user_state.dart';

class IslandTheme {
  final String id;
  final String name;
  final String previewPath;
  final String? islandPath;

  const IslandTheme({
    required this.id,
    required this.name,
    required this.previewPath,
    this.islandPath,
  });
}

class IslandThemePicker extends StatefulWidget {
  const IslandThemePicker({super.key});

  @override
  State<IslandThemePicker> createState() => _IslandThemePickerState();
}

class _IslandThemePickerState extends State<IslandThemePicker> {
  late String _focusedId; // 滑动中的焦点 ID (用于待选展示)
  late String _activeId;  // 实际上已经应用 ID (用于显示"当前使用")
  late PageController _pageController;

  final List<IslandTheme> _themes = [
    const IslandTheme(
      id: 'default',
      name: '默认小岛',
      previewPath: 'assets/images/home_small_demo.png',
    ),
    const IslandTheme(
      id: 'cotton_candy',
      name: '云朵棉花糖岛',
      previewPath: 'assets/images/theme/miamhuadao/mianhuadao_xiaodao.png',
      islandPath: 'assets/images/theme/miamhuadao/mianhuadao_xiaodao.png',
    ),
    const IslandTheme(
      id: 'cherry_blossom',
      name: '春日樱花岛',
      previewPath: 'assets/images/home_small_demo.png',
    ),
    const IslandTheme(
      id: 'starry_night',
      name: '星夜灯塔岛',
      previewPath: 'assets/images/home_small_demo2.png',
      islandPath: 'assets/images/home_small_demo2.png',
    ),
    const IslandTheme(
      id: 'lantern_festival',
      name: '元宵花灯岛',
      previewPath: 'assets/images/home5.png',
      islandPath: 'assets/images/home5.png',
    ),
  ];

  @override
  void initState() {
    super.initState();
    _activeId = UserState().selectedIslandThemeId.value;
    _focusedId = _activeId;
    final initialPage = _themes.indexWhere((t) => t.id == _activeId);
    _pageController = PageController(
      viewportFraction: 0.42, // 保持紧凑感
      initialPage: initialPage >= 0 ? initialPage : 0,
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isNight = UserState().isNight;
    final Color mainTextColor = isNight ? Colors.white : const Color(0xFF6B4B5A);
    final Color subTextColor = isNight ? Colors.white70 : const Color(0xFF8D7A84);
    final Color accentPink = const Color(0xFFFFBCCB);
    final Color buttonGradientStart = const Color(0xFFFDB7A7);
    final Color buttonGradientEnd = const Color(0xFFE58B8B);

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: isNight
              ? [const Color(0xFF1A1A24), const Color(0xFF252535)]
              : [const Color(0xFFFFF1F1), Colors.white],
        ),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(40)),
      ),
      child: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(0, 12, 0, 40),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // 顶部把手
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: mainTextColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 24),

                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
                      "✦",
                      style: TextStyle(color: Color(0xFFFFBCCB), fontSize: 18),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      "切换主题",
                      style: TextStyle(
                        fontSize: 24,
                        fontFamily: 'LXGWWenKai',
                        fontWeight: FontWeight.bold,
                        color: mainTextColor,
                        letterSpacing: 1.2,
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      "✦",
                      style: TextStyle(color: Color(0xFFFFBCCB), fontSize: 18),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  "选择你喜欢的小岛外观",
                  style: TextStyle(
                    fontSize: 15,
                    fontFamily: 'LXGWWenKai',
                    color: subTextColor,
                  ),
                ),
                const SizedBox(height: 32),

                // 轮播图区域 - 使用 AnimatedBuilder 局部重绘
                SizedBox(
                  height: 250,
                  child: AnimatedBuilder(
                    animation: _pageController,
                    builder: (context, child) {
                      return PageView.builder(
                        controller: _pageController,
                        physics: const BouncingScrollPhysics(),
                        itemCount: _themes.length,
                        onPageChanged: (index) {
                          setState(() {
                            _focusedId = _themes[index].id;
                          });
                        },
                        itemBuilder: (context, index) {
                          final theme = _themes[index];

                          // 动态计算缩放
                          double currentPage = 0;
                          try {
                            currentPage =
                                _pageController.page ??
                                _pageController.initialPage.toDouble();
                          } catch (_) {
                            currentPage = _pageController.initialPage
                                .toDouble();
                          }

                          double relativePosition = index - currentPage;
                          double scale = (1 - (relativePosition.abs() * 0.25))
                              .clamp(0.8, 1.2);
                          
                          // 区分焦点和当前使用
                          final isFocused = _focusedId == theme.id;
                          final isCurrentlyUsed = _activeId == theme.id;

                          return Transform.scale(
                            scale: scale,
                            child: GestureDetector(
                              onTap: () {
                                _pageController.animateToPage(
                                  index,
                                  duration: const Duration(milliseconds: 500),
                                  curve: Curves.easeOutQuint,
                                );
                              },
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Container(
                                    width: 160,
                                    height: 190,
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(32),
                                      border: Border.all(
                                        color: isFocused
                                            ? accentPink
                                            : Colors.black.withValues(
                                                alpha: 0.05,
                                              ),
                                        width: isFocused ? 4 : 1,
                                      ),
                                      boxShadow: [
                                        BoxShadow(
                                          color: isFocused
                                              ? accentPink.withValues(
                                                  alpha: 0.5,
                                                )
                                              : Colors.black.withValues(
                                                  alpha: 0.05,
                                                ),
                                          blurRadius: isFocused ? 20 : 10,
                                          offset: const Offset(0, 6),
                                        ),
                                      ],
                                    ),
                                    child: Stack(
                                      children: [
                                        Padding(
                                          padding: const EdgeInsets.all(8.0),
                                          child: ClipRRect(
                                            borderRadius: BorderRadius.circular(
                                              24,
                                            ),
                                            child: Image.asset(
                                              theme.previewPath,
                                              fit: BoxFit.cover,
                                              width: double.infinity,
                                              height: double.infinity,
                                            ),
                                          ),
                                        ),
                                        // 右上角图标跟随焦点
                                        if (isFocused)
                                          Positioned(
                                            top: 12,
                                            right: 12,
                                            child: Container(
                                              width: 28,
                                              height: 28,
                                              decoration: BoxDecoration(
                                                color: buttonGradientEnd,
                                                shape: BoxShape.circle,
                                                border: Border.all(
                                                  color: Colors.white,
                                                  width: 2,
                                                ),
                                              ),
                                              child: const Icon(
                                                Icons.check,
                                                size: 16,
                                                color: Colors.white,
                                              ),
                                            ),
                                          ),
                                        // "当前使用" 标签固定在 activeId 上
                                        if (isCurrentlyUsed)
                                          Positioned(
                                            bottom: 15,
                                            left: 15,
                                            right: 15,
                                            child: Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    vertical: 5,
                                                  ),
                                              decoration: BoxDecoration(
                                                color: buttonGradientEnd
                                                    .withValues(alpha: 0.9),
                                                borderRadius:
                                                    BorderRadius.circular(15),
                                              ),
                                              child: const Text(
                                                "当前使用",
                                                textAlign: TextAlign.center,
                                                style: TextStyle(
                                                  color: Colors.white,
                                                  fontSize: 11,
                                                  fontWeight: FontWeight.bold,
                                                  fontFamily: 'LXGWWenKai',
                                                ),
                                              ),
                                            ),
                                          ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  Opacity(
                                    opacity: (1 - relativePosition.abs()).clamp(
                                      0.0,
                                      1.0,
                                    ),
                                    child: Text(
                                      theme.name,
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontFamily: 'LXGWWenKai',
                                        fontWeight: FontWeight.bold,
                                        color: mainTextColor,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),

                const SizedBox(height: 24),

                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: GestureDetector(
                    onTap: () {
                      UserState().setSelectedIslandThemeId(_focusedId);
                      Navigator.pop(context);
                    },
                    child: Container(
                      width: double.infinity,
                      height: 64,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [buttonGradientStart, buttonGradientEnd],
                        ),
                        borderRadius: BorderRadius.circular(32),
                        boxShadow: [
                          BoxShadow(
                            color: buttonGradientEnd.withValues(alpha: 0.3),
                            blurRadius: 15,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: Center(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Text(
                              "✦",
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 16,
                              ),
                            ),
                            const SizedBox(width: 12),
                            const Text(
                              "应 用 主 题",
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontFamily: 'LXGWWenKai',
                                fontWeight: FontWeight.bold,
                                letterSpacing: 4,
                              ),
                            ),
                            const SizedBox(width: 12),
                            const Text(
                              "✦",
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(
                    "取消",
                    style: TextStyle(
                      color: subTextColor,
                      fontSize: 16,
                      fontFamily: 'LXGWWenKai',
                    ),
                  ),
                ),
              ],
            ),
          ),

          Positioned(
            top: 20,
            right: 20,
            child: GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: mainTextColor.withValues(alpha: 0.05),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.close_rounded, size: 20, color: subTextColor),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
