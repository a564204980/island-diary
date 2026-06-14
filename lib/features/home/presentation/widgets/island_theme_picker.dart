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
  late String _activeId; // 实际上已经应用 ID (用于显示"当前使用")
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
      id: 'lego',
      name: '乐高工坊',
      previewPath: 'assets/images/theme/legao/legao_xiaodao.png',
      islandPath: 'assets/images/theme/legao/legao_xiaodao.png',
    ),
    // const IslandTheme(
    //   id: 'cherry_blossom',
    //   name: '春日樱花岛',
    //   previewPath: 'assets/images/home_small_demo.png',
    // ),
    // const IslandTheme(
    //   id: 'starry_night',
    //   name: '星夜灯塔岛',
    //   previewPath: 'assets/images/home_small_demo2.png',
    //   islandPath: 'assets/images/home_small_demo2.png',
    // ),
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
    final themeId = _focusedId; // 使用聚焦的预览主题 ID，实现底栏颜色跟随滑动而变化
    final isCottonCandy = themeId == 'cotton_candy';
    final isNight = UserState().isNight;

    // --- 动态色彩系统配置 ---
    Color mainTextColor;
    Color subTextColor;
    Color accentPink;
    Color buttonGradientStart;
    Color buttonGradientEnd;
    List<Color> bgColors;
    Border? topBorder;

    if (themeId == 'cotton_candy') {
      mainTextColor = isNight
          ? const Color(0xFFF1EAFF)
          : const Color(0xFF6B4B5A);
      subTextColor = isNight
          ? const Color(0xFFB3A8DE)
          : const Color(0xFF8D7A84);
      accentPink = isNight ? const Color(0xFFE2C4FF) : const Color(0xFFFFBCCB);
      buttonGradientStart = const Color(0xFFFF9EB7);
      buttonGradientEnd = isNight
          ? const Color(0xFFAC92FF)
          : const Color(0xFFE58B8B);
      bgColors = isNight
          ? [const Color(0xFF2C2250), const Color(0xFF181232)]
          : [const Color(0xFFFFF1F1), Colors.white];
      topBorder = isNight
          ? const Border(top: BorderSide(color: Color(0xFFC0A6FF), width: 1.5))
          : null;
    } else if (themeId == 'starry_night') {
      mainTextColor = isNight
          ? const Color(0xFFE0E6ED)
          : const Color(0xFF1B2A4A);
      subTextColor = isNight
          ? const Color(0xFF90A4AE)
          : const Color(0xFF4A607A);
      accentPink = const Color(0xFF80DEEA);
      buttonGradientStart = const Color(0xFF26A69A);
      buttonGradientEnd = const Color(0xFF3F51B5);
      bgColors = isNight
          ? [const Color(0xFF0F172A), const Color(0xFF020617)]
          : [const Color(0xFFF0F4F8), Colors.white];
      topBorder = isNight
          ? const Border(top: BorderSide(color: Color(0xFF00E5FF), width: 1.5))
          : null;
    } else if (themeId == 'cherry_blossom') {
      mainTextColor = isNight
          ? const Color(0xFFFFEBEE)
          : const Color(0xFF5D4037);
      subTextColor = isNight
          ? const Color(0xFFFFCDD2)
          : const Color(0xFF8D6E63);
      accentPink = const Color(0xFFF48FB1);
      buttonGradientStart = const Color(0xFFFF8A80);
      buttonGradientEnd = const Color(0xFFEC407A);
      bgColors = isNight
          ? [const Color(0xFF2D161A), const Color(0xFF1B0B0D)]
          : [const Color(0xFFFFF8F8), Colors.white];
      topBorder = isNight
          ? const Border(top: BorderSide(color: Color(0xFFF48FB1), width: 1.5))
          : null;
    } else if (themeId == 'lego') {
      mainTextColor = isNight
          ? const Color(0xFFFFF0D0)
          : const Color(0xFF2C3E50);
      subTextColor = isNight
          ? const Color(0xFFBDC3C7)
          : const Color(0xFF7F8C8D);
      accentPink = const Color(0xFFF39C12);
      buttonGradientStart = const Color(0xFFF1C40F);
      buttonGradientEnd = const Color(0xFFE74C3C);
      bgColors = isNight
          ? [const Color(0xFF1E272C), const Color(0xFF0F171A)]
          : [const Color(0xFFFFFDF0), Colors.white];
      topBorder = isNight
          ? const Border(top: BorderSide(color: Color(0xFFF1C40F), width: 1.5))
          : null;
    } else {
      // 默认小岛/其他主题
      mainTextColor = isNight
          ? const Color(0xFFECEFF1)
          : const Color(0xFF4E3629);
      subTextColor = isNight
          ? const Color(0xFF78909C)
          : const Color(0xFF7D8C7A);
      accentPink = const Color(0xFF81C784);
      buttonGradientStart = const Color(0xFFAED581); // 柔和青草绿
      buttonGradientEnd = const Color(0xFF66BB6A);   // 郁郁葱葱的草木绿
      bgColors = isNight
          ? [const Color(0xFF1E291E), const Color(0xFF0F150F)]
          : [const Color(0xFFF4F9F4), Colors.white];
      topBorder = isNight
          ? const Border(top: BorderSide(color: Color(0xFF81C784), width: 1.5))
          : null;
    }

    return AnimatedContainer(
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeInOut,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: bgColors,
        ),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(40)),
        border: topBorder,
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
                    color: isCottonCandy && isNight
                        ? const Color(0xFFC0A6FF).withValues(alpha: 0.4)
                        : mainTextColor.withValues(alpha: 0.1),
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
                                  AnimatedContainer(
                                    duration: const Duration(milliseconds: 300),
                                    curve: Curves.easeOut,
                                    width: 160,
                                    height: 190,
                                    decoration: BoxDecoration(
                                      color: isCottonCandy && isNight
                                          ? const Color(
                                              0xFFE8E4FF,
                                            ).withValues(alpha: 0.15)
                                          : Colors.white.withValues(alpha: 0.2),
                                      borderRadius: BorderRadius.circular(32),
                                      border: Border.all(
                                        color: isFocused
                                            ? accentPink
                                            : (isCottonCandy && isNight
                                                  ? const Color(
                                                      0xFFFFFFFF,
                                                    ).withValues(alpha: 0.15)
                                                  : Colors.black.withValues(
                                                      alpha: 0.05,
                                                    )),
                                        width: isFocused ? 4 : 1,
                                      ),
                                      boxShadow: null,
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
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 500),
                      curve: Curves.easeInOut,
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
                  color: isCottonCandy && isNight
                      ? const Color(0xFFC0A6FF).withValues(alpha: 0.15)
                      : mainTextColor.withValues(alpha: 0.05),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.close_rounded,
                  size: 20,
                  color: isCottonCandy && isNight
                      ? const Color(0xFFE8DDFF)
                      : subTextColor,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
