import 'package:flutter/material.dart';
import 'package:island_diary/shared/widgets/diary_entry/utils/diary_utils.dart';
import 'package:island_diary/core/state/user_state.dart';

class MoodSelectorHeader extends StatefulWidget {
  final int? currentMoodIndex;
  final String? currentTag;
  final VoidCallback? onClearMood;
  final Function(int) onMoodSelected;
  final String paperStyle;
  final bool isNight;
  final VoidCallback? onCustomTap;

  const MoodSelectorHeader({
    super.key,
    required this.currentMoodIndex,
    this.currentTag,
    this.onClearMood,
    required this.onMoodSelected,
    required this.paperStyle,
    required this.isNight,
    this.onCustomTap,
  });

  static const List<Map<String, String>> moods = [
    {'label': '开心', 'icon': 'assets/icons/happy.png', 'color': '0xFFFFE484'},
    {'label': '平静', 'icon': 'assets/icons/calm.png', 'color': '0xFFA4D4E4'},
    {'label': '低落', 'icon': 'assets/icons/down.png', 'color': '0xFF84A4E4'},
    {
      'label': '烦躁',
      'icon': 'assets/icons/irritated.png',
      'color': '0xFFFF8484',
    },
    {'label': '疲惫', 'icon': 'assets/icons/tired.png', 'color': '0xFFC4A4E4'},
    {'label': '惊喜', 'icon': 'assets/icons/surprise.png', 'color': '0xFF81C784'},
    {'label': '害羞', 'icon': 'assets/icons/shy.png', 'color': '0xFFF06292'},
    {'label': '焦虑', 'icon': 'assets/icons/anxious.png', 'color': '0xFF90A4AE'},
    {'label': '委屈', 'icon': 'assets/icons/wronged.png', 'color': '0xFF9575CD'},
    {'label': '无聊', 'icon': 'assets/icons/bored.png', 'color': '0xFFA1887F'},
    {'label': '期待', 'icon': 'assets/icons/expect.png', 'color': '0xFFFFB74D'},
  ];

  @override
  State<MoodSelectorHeader> createState() => _MoodSelectorHeaderState();
}

class _MoodSelectorHeaderState extends State<MoodSelectorHeader> {
  int? _lastValidMoodIndex;
  String? _lastValidTag;

  int? get currentMoodIndex => widget.currentMoodIndex;
  String? get currentTag => widget.currentTag;
  VoidCallback? get onClearMood => widget.onClearMood;
  Function(int) get onMoodSelected => widget.onMoodSelected;
  String get paperStyle => widget.paperStyle;
  bool get isNight => widget.isNight;
  VoidCallback? get onCustomTap => widget.onCustomTap;
  List<Map<String, String>> get moods => MoodSelectorHeader.moods;

  @override
  Widget build(BuildContext context) {
    if (currentMoodIndex != null) {
      _lastValidMoodIndex = currentMoodIndex;
      _lastValidTag = currentTag;
    }

    final bool isSelected = currentMoodIndex != null;
    final Color inkColor = DiaryUtils.getInkColor(paperStyle, isNight);
    final bool isDark = isNight;
    final double screenWidth = MediaQuery.of(context).size.width;
    final themeId = UserState().selectedIslandThemeId.value;
    final bool isCottonCandyDark = (themeId == 'cotton_candy') && isNight;

    return Padding(
      padding: EdgeInsets.only(
        top: 8,
        bottom: isSelected ? 8 : 24,
      ),
      child: Align(
        alignment: Alignment.topLeft,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 400),
          curve: Curves.easeInOutCubic,
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            color: isCottonCandyDark
                ? null
                : (isDark
                    ? Colors.white.withValues(alpha: 0.05)
                    : const Color(0xFFFEF9F0)),
            gradient: isCottonCandyDark
                ? LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      const Color(0xFFC0A6FF).withValues(alpha: 0.18),
                      const Color(0xFFC0A6FF).withValues(alpha: 0.03),
                    ],
                  )
                : null,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: isCottonCandyDark
                  ? const Color(0xFFC0A6FF).withValues(alpha: 0.8)
                  : inkColor.withValues(alpha: isDark ? 0.1 : 0.08),
              width: isCottonCandyDark ? 1.5 : 1,
            ),
            boxShadow: [
              if (isCottonCandyDark)
                BoxShadow(
                  color: const Color(0xFFC0A6FF).withValues(alpha: 0.12),
                  blurRadius: 16,
                  spreadRadius: 1,
                ),
              if (!isDark && !isSelected)
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.03),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: isSelected ? () => onClearMood?.call() : null,
              borderRadius: BorderRadius.circular(24),
              child: AnimatedCrossFade(
                firstChild: KeyedSubtree(
                  key: const ValueKey('expanded_content'),
                  child: SizedBox(
                    width: screenWidth - 48,
                    child: SingleChildScrollView(
                      physics: const NeverScrollableScrollPhysics(),
                      child: _buildExpandedContent(context),
                    ),
                  ),
                ),
                secondChild: KeyedSubtree(
                  key: const ValueKey('pill_content'),
                  child: SingleChildScrollView(
                    physics: const NeverScrollableScrollPhysics(),
                    child: _buildPillContent(context),
                  ),
                ),
                crossFadeState: isSelected
                    ? CrossFadeState.showSecond
                    : CrossFadeState.showFirst,
                duration: const Duration(milliseconds: 400),
                firstCurve: Curves.easeIn,
                secondCurve: Curves.easeOut,
                sizeCurve: Curves.easeInOutCubic,
                alignment: Alignment.topLeft,
                layoutBuilder: (Widget topChild, Key topChildKey, Widget bottomChild, Key bottomChildKey) {
                  return Stack(
                    clipBehavior: Clip.none,
                    alignment: Alignment.topLeft,
                    children: <Widget>[
                      Positioned(
                        key: bottomChildKey,
                        left: 0.0,
                        top: 0.0,
                        // 不设置 right: 0.0，防止强制挤压底层组件宽度导致 Row 溢出
                        child: bottomChild,
                      ),
                      Positioned(
                        key: topChildKey,
                        child: topChild,
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildExpandedContent(BuildContext context) {
    final Color inkColor = DiaryUtils.getInkColor(paperStyle, isNight);
    final bool isDark = isNight;
    final double screenWidth = MediaQuery.of(context).size.width;

    final double availableWidth = screenWidth - 40;
    final double itemWidth = availableWidth / 5.8;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 14, 20, 4),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    "此刻心情",
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: inkColor.withValues(alpha: isDark ? 1.0 : 0.8),
                      fontFamily: 'LXGWWenKai',
                    ),
                  ),
                  const SizedBox(width: 4),
                  Icon(
                    Icons.auto_awesome_rounded,
                    size: 12,
                    color: inkColor.withValues(alpha: 0.4),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text(
                    "选一个最接近的心情吧",
                    style: TextStyle(
                      fontSize: 12,
                      color: inkColor.withValues(alpha: isDark ? 0.7 : 0.4),
                      fontFamily: 'LXGWWenKai',
                    ),
                  ),
                  const Spacer(),
                  Text(
                    "滑动查看更多",
                    style: TextStyle(
                      fontSize: 12,
                      color: inkColor.withValues(alpha: 0.4),
                      fontFamily: 'LXGWWenKai',
                    ),
                  ),
                  const SizedBox(width: 4),
                  Icon(
                    Icons.arrow_forward_ios_rounded,
                    size: 10,
                    color: inkColor.withValues(alpha: 0.4),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 115,
          child: ShaderMask(
            shaderCallback: (Rect bounds) {
              return LinearGradient(
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
                colors: [Colors.white, Colors.white.withValues(alpha: 0.0)],
                stops: const [0.9, 1.0],
              ).createShader(bounds);
            },
            blendMode: BlendMode.dstIn,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  ...List.generate(moods.length, (index) {
                    final mood = moods[index];
                    final bool isSelected = currentMoodIndex == index;
                    final Color moodColor = Color(
                      int.parse(mood['color']!),
                    );

                    return Container(
                      width: itemWidth,
                      margin: const EdgeInsets.symmetric(vertical: 8),
                      child: InkWell(
                        onTap: () => onMoodSelected(index),
                        splashColor: Colors.transparent,
                        highlightColor: Colors.transparent,
                        hoverColor: Colors.transparent,
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 500),
                          curve: Curves.fastOutSlowIn,
                          margin: const EdgeInsets.symmetric(horizontal: 2),
                          padding: const EdgeInsets.symmetric(
                            vertical: 12,
                            horizontal: 4,
                          ),
                          transform: Matrix4.translationValues(
                            0,
                            isSelected ? -6 : 0,
                            0,
                          ),
                          decoration: BoxDecoration(
                            color: isDark
                                ? Colors.white.withValues(alpha: 0.15)
                                : Colors.white,
                            borderRadius: BorderRadius.circular(32),
                            border: Border.all(
                              color: isSelected
                                  ? moodColor.withValues(alpha: 0.6)
                                  : Colors.transparent,
                              width: 1.5,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: isSelected
                                    ? moodColor.withValues(
                                        alpha: isDark ? 0.4 : 0.2,
                                      )
                                    : Colors.transparent,
                                blurRadius: isDark ? 20 : 15,
                                offset: Offset(0, isDark ? 4 : 8),
                              ),
                            ],
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              AnimatedScale(
                                scale: isSelected ? 1.15 : 1.0,
                                duration: const Duration(milliseconds: 400),
                                curve: Curves.easeOutBack,
                                child: SizedBox(
                                  width: 44,
                                  height: 44,
                                  child: Center(
                                    child: Image.asset(
                                      mood['icon']!,
                                      width: 28,
                                      height: 28,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 8),
                              FittedBox(
                                fit: BoxFit.scaleDown,
                                child: Text(
                                  mood['label']!,
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: isSelected
                                        ? FontWeight.bold
                                        : FontWeight.normal,
                                    color: isSelected
                                        ? moodColor
                                        : inkColor.withValues(
                                            alpha: isDark ? 0.7 : 0.5,
                                          ),
                                    fontFamily: 'LXGWWenKai',
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }),
                  Container(
                    width: itemWidth * 0.8,
                    margin: const EdgeInsets.only(left: 8, right: 16),
                    child: InkWell(
                      onTap: onCustomTap,
                      splashColor: Colors.transparent,
                      highlightColor: Colors.transparent,
                      hoverColor: Colors.transparent,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: (isDark ? Colors.white : inkColor)
                                    .withValues(alpha: 0.2),
                                width: 1,
                              ),
                            ),
                            child: Icon(
                              Icons.edit_note_rounded,
                              color: (isDark ? Colors.white : inkColor)
                                  .withValues(alpha: 0.4),
                              size: 24,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            "自定义",
                            style: TextStyle(
                              fontSize: 11,
                              color: (isDark ? Colors.white : inkColor)
                                  .withValues(alpha: 0.4),
                              fontFamily: 'LXGWWenKai',
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        Padding(
          padding: const EdgeInsets.only(bottom: 14.0),
          child: Center(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildDashLine(inkColor, width: 20),
                  const SizedBox(width: 8),
                  Icon(
                    Icons.eco_rounded,
                    size: 14,
                    color: inkColor.withValues(alpha: 0.5),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    "先记录此刻的感受，再慢慢写下今天的故事",
                    style: TextStyle(
                      fontSize: 12,
                      color: inkColor.withValues(alpha: 0.5),
                      fontFamily: 'LXGWWenKai',
                    ),
                  ),
                  const SizedBox(width: 8),
                  _buildDashLine(inkColor, width: 20),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDashLine(Color color, {double width = 30}) {
    return Container(
      width: width,
      height: 1,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.transparent,
            color.withValues(alpha: 0.1),
            Colors.transparent,
          ],
        ),
      ),
    );
  }

  Widget _buildPillContent(BuildContext context) {
    final Color inkColor = DiaryUtils.getInkColor(paperStyle, isNight);
    
    String iconPath = 'assets/icons/happy.png';
    String label = _lastValidTag ?? '开心';
    Color moodColor = const Color(0xFFFFB74D);

    if (_lastValidTag != null && _lastValidMoodIndex != null) {
      if (_lastValidMoodIndex! >= 0 && _lastValidMoodIndex! <= 23) {
        iconPath = 'assets/icons/custom${_lastValidMoodIndex! + 1}.png';
      }
    } else if (_lastValidMoodIndex != null && _lastValidMoodIndex! < moods.length) {
      iconPath = moods[_lastValidMoodIndex!]['icon']!;
      label = moods[_lastValidMoodIndex!]['label']!;
      moodColor = Color(int.parse(moods[_lastValidMoodIndex!]['color']!));
    }

    final themeId = UserState().selectedIslandThemeId.value;
    final bool isCottonCandyDark = (themeId == 'cotton_candy') && isNight;

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 16, 8),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Image.asset(
            iconPath,
            width: 20,
            height: 20,
            errorBuilder: (c, e, s) => Icon(Icons.mood, size: 20, color: moodColor),
          ),
          const SizedBox(width: 8),
          Text(
            label,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: moodColor,
              fontFamily: 'LXGWWenKai',
            ),
          ),
          const SizedBox(width: 12),
          Text(
            "更换",
            style: TextStyle(
              fontSize: 12,
              color: isCottonCandyDark
                  ? Colors.white
                  : inkColor.withValues(alpha: 0.5),
              fontFamily: 'LXGWWenKai',
            ),
          ),
        ],
      ),
    );
  }
}
