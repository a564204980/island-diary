import 'dart:io';
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
  final Function(String)? onRemoveTag;
  final String? weather;
  final String? temp;
  final VoidCallback? onWeatherTap;
  final VoidCallback? onClearWeather;
  final String? location;
  final VoidCallback? onLocationTap;
  final VoidCallback? onClearLocation;

  const MoodSelectorHeader({
    super.key,
    required this.currentMoodIndex,
    this.currentTag,
    this.onClearMood,
    required this.onMoodSelected,
    required this.paperStyle,
    required this.isNight,
    this.onCustomTap,
    this.onRemoveTag,
    this.weather,
    this.temp,
    this.onWeatherTap,
    this.onClearWeather,
    this.location,
    this.onLocationTap,
    this.onClearLocation,
  });

  static const List<Map<String, String>> moods = [
    {'label': '开心', 'icon': 'assets/icons/happy.png', 'color': '0xFFFFA000'},
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
    final bool isLego = themeId == 'lego';

    final Color? containerBgColor = isCottonCandyDark
        ? null
        : (isDark
            ? Colors.white.withValues(alpha: 0.05)
            : const Color(0xFFFEF9F0).withValues(alpha: 0.2)); // 统一增加透明度以隐约呈现底纸纹理

    final pillWidget = Padding(
      key: const ValueKey('mood_selector_pill_widget'),
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: AnimatedContainer(
          duration: const Duration(milliseconds: 400),
          curve: Curves.easeInOutCubic,
          margin: isLego ? const EdgeInsets.only(bottom: 6) : null,
          decoration: BoxDecoration(
            color: containerBgColor,
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
            border: isLego
                ? null
                : Border.all(
                    color: isCottonCandyDark
                        ? const Color(0xFFC0A6FF).withValues(alpha: 0.8)
                        : inkColor.withValues(alpha: isDark ? 0.1 : 0.08),
                    width: isCottonCandyDark ? 1.5 : 1,
                  ),
            boxShadow: isLego
                ? [
                    // 1. 固态 3D 积木厚度实色层（零羽化）
                    BoxShadow(
                      color: isDark ? const Color(0xFF1B160E) : const Color(0xFFEADAB9),
                      blurRadius: 0,
                      offset: const Offset(0, 4.0),
                    ),
                    // 2. 底层环境遮蔽软影
                    BoxShadow(
                      color: isDark ? Colors.black.withValues(alpha: 0.4) : const Color(0xFFDCC8A0).withValues(alpha: 0.4),
                      blurRadius: 4.0,
                      offset: const Offset(0, 5.0),
                    ),
                  ]
                : [
                    BoxShadow(
                      color: isCottonCandyDark
                          ? const Color(0xFFC0A6FF).withValues(alpha: 0.12)
                          : Colors.transparent,
                      blurRadius: isCottonCandyDark ? 16 : 0,
                      spreadRadius: isCottonCandyDark ? 1 : 0,
                    ),
                    const BoxShadow(
                      color: Colors.transparent,
                      blurRadius: 0,
                      offset: Offset.zero,
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
                firstCurve: const Interval(0.0, 0.3, curve: Curves.easeIn),
                secondCurve: const Interval(0.6, 1.0, curve: Curves.easeOut),
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
      );



    final weatherWidget = _buildWeatherPill(context);
    final locationWidget = _buildLocationPill(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (isSelected && themeId == 'lego')
          Padding(
            padding: const EdgeInsets.only(bottom: 24, top: 4),
            child: _buildLegoTopStudsRow(),
          )
        else
          const SizedBox.shrink(),
        const SizedBox.shrink(),
        Wrap(
          spacing: 8,
          runSpacing: 6,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: isSelected ? 220 : double.infinity,
              ),
              child: pillWidget,
            ),
            if (widget.weather != null && widget.weather!.isNotEmpty)
              weatherWidget,
            if (widget.location != null && widget.location!.isNotEmpty)
              locationWidget,
          ],
        ),
      ],
    );
  }

  IconData _getWeatherIcon(String? weather) {
    if (weather == null) return Icons.wb_sunny_outlined;
    if (weather.contains("晴")) return Icons.wb_sunny_outlined;
    if (weather.contains("多云")) return Icons.wb_cloudy_outlined;
    if (weather.contains("阴")) return Icons.cloud_outlined;
    if (weather.contains("雨")) return Icons.umbrella_outlined;
    if (weather.contains("雪")) return Icons.ac_unit_outlined;
    if (weather.contains("风")) return Icons.air_outlined;
    if (weather.contains("雾")) return Icons.grain_outlined;
    if (weather.contains("雷")) return Icons.thunderstorm_outlined;
    if (weather.contains("冰雹")) return Icons.severe_cold_outlined;
    if (weather.contains("炎热") || weather.contains("热")) {
      return Icons.thermostat_outlined;
    }
    if (weather.contains("严寒") || weather.contains("冷")) {
      return Icons.ac_unit_outlined;
    }
    return Icons.wb_sunny_outlined;
  }

  Widget _buildWeatherPill(BuildContext context) {
    final Color inkColor = DiaryUtils.getInkColor(paperStyle, isNight);
    final themeId = UserState().selectedIslandThemeId.value;
    final bool isCottonCandyDark = (themeId == 'cotton_candy') && isNight;
    final bool isLego = themeId == 'lego';
    final bool isDark = isNight;

    final bool hasWeather = widget.weather != null && widget.weather!.isNotEmpty;

    return GestureDetector(
      onTap: widget.onWeatherTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOutCubic,
        margin: isLego ? const EdgeInsets.only(bottom: 6) : null,
        decoration: BoxDecoration(
          color: isCottonCandyDark
              ? null
              : (isDark
                  ? Colors.white.withValues(alpha: 0.05)
                  : const Color(0xFFFEF9F0).withValues(alpha: 0.2)),
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
          border: isLego
              ? null
              : Border.all(
                  color: isCottonCandyDark
                      ? const Color(0xFFC0A6FF).withValues(alpha: 0.8)
                      : inkColor.withValues(alpha: isDark ? 0.1 : 0.08),
                  width: isCottonCandyDark ? 1.5 : 1,
                ),
          boxShadow: isLego
              ? [
                  BoxShadow(
                    color: isDark ? const Color(0xFF1B160E) : const Color(0xFFEADAB9),
                    blurRadius: 0,
                    offset: const Offset(0, 4.0),
                  ),
                  BoxShadow(
                    color: isDark ? Colors.black.withValues(alpha: 0.4) : const Color(0xFFDCC8A0).withValues(alpha: 0.4),
                    blurRadius: 4.0,
                    offset: const Offset(0, 5.0),
                  ),
                ]
              : null,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              hasWeather ? _getWeatherIcon(widget.weather) : Icons.wb_sunny_outlined,
              size: 18,
              color: hasWeather
                  ? (isDark ? Colors.white70 : inkColor.withValues(alpha: 0.5))
                  : inkColor.withValues(alpha: 0.4),
            ),
            const SizedBox(width: 6),
            Text(
              hasWeather ? "${widget.weather} ${widget.temp ?? ''}" : "+ 天气",
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: hasWeather
                    ? (isDark ? Colors.white.withValues(alpha: 0.9) : inkColor.withValues(alpha: 0.8))
                    : inkColor.withValues(alpha: 0.4),
                fontFamily: 'LXGWWenKai',
              ),
            ),
            if (hasWeather) ...[
              const SizedBox(width: 4),
              GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () {
                  widget.onClearWeather?.call();
                },
                child: Container(
                  padding: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.1)
                        : inkColor.withValues(alpha: 0.05),
                  ),
                  child: Icon(
                    Icons.close_rounded,
                    size: 12,
                    color: isDark ? Colors.white70 : inkColor.withValues(alpha: 0.5),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildLocationPill(BuildContext context) {
    final Color inkColor = DiaryUtils.getInkColor(paperStyle, isNight);
    final themeId = UserState().selectedIslandThemeId.value;
    final bool isCottonCandyDark = (themeId == 'cotton_candy') && isNight;
    final bool isLego = themeId == 'lego';
    final bool isDark = isNight;

    final bool hasLocation = widget.location != null && widget.location!.isNotEmpty;

    return GestureDetector(
      onTap: widget.onLocationTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOutCubic,
        margin: isLego ? const EdgeInsets.only(bottom: 6) : null,
        decoration: BoxDecoration(
          color: isCottonCandyDark
              ? null
              : (isDark
                  ? Colors.white.withValues(alpha: 0.05)
                  : const Color(0xFFFEF9F0).withValues(alpha: 0.2)),
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
          border: isLego
              ? null
              : Border.all(
                  color: isCottonCandyDark
                      ? const Color(0xFFC0A6FF).withValues(alpha: 0.8)
                      : inkColor.withValues(alpha: isDark ? 0.1 : 0.08),
                  width: isCottonCandyDark ? 1.5 : 1,
                ),
          boxShadow: isLego
              ? [
                  BoxShadow(
                    color: isDark ? const Color(0xFF1B160E) : const Color(0xFFEADAB9),
                    blurRadius: 0,
                    offset: const Offset(0, 4.0),
                  ),
                  BoxShadow(
                    color: isDark ? Colors.black.withValues(alpha: 0.4) : const Color(0xFFDCC8A0).withValues(alpha: 0.4),
                    blurRadius: 4.0,
                    offset: const Offset(0, 5.0),
                  ),
                ]
              : null,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.location_on_outlined,
              size: 18,
              color: hasLocation
                  ? (isDark ? Colors.white70 : inkColor.withValues(alpha: 0.5))
                  : inkColor.withValues(alpha: 0.4),
            ),
            const SizedBox(width: 6),
            Text(
              hasLocation ? widget.location! : "+ 地点",
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: hasLocation
                    ? (isDark ? Colors.white.withValues(alpha: 0.9) : inkColor.withValues(alpha: 0.8))
                    : inkColor.withValues(alpha: 0.4),
                fontFamily: 'LXGWWenKai',
              ),
            ),
            if (hasLocation) ...[
              const SizedBox(width: 4),
              GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () {
                  widget.onClearLocation?.call();
                },
                child: Container(
                  padding: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.1)
                        : inkColor.withValues(alpha: 0.05),
                  ),
                  child: Icon(
                    Icons.close_rounded,
                    size: 12,
                    color: isDark ? Colors.white70 : inkColor.withValues(alpha: 0.5),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }



  Widget _buildExpandedContent(BuildContext context) {
    final Color inkColor = DiaryUtils.getInkColor(paperStyle, isNight);
    final bool isDark = isNight;
    final double screenWidth = MediaQuery.of(context).size.width;
    final themeId = UserState().selectedIslandThemeId.value;
    final bool isCottonCandyDark = (themeId == 'cotton_candy') && isNight;
    final Color? containerBgColor = isCottonCandyDark
        ? null
        : (isDark
            ? Colors.white.withValues(alpha: 0.05)
            : (paperStyle.startsWith('note') || (paperStyle == 'classic' && themeId == 'cotton_candy')
                ? const Color(0xFFFEF9F0).withValues(alpha: 0.45)
                : const Color(0xFFFEF9F0)));

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
          child: Stack(
            children: [
              SingleChildScrollView(
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
              // 右侧渐变遮罩（替代有问题的 ShaderMask BlendMode.dstIn）
              Positioned(
                right: 0,
                top: 0,
                bottom: 0,
                width: 40,
                child: IgnorePointer(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                        colors: [
                          (containerBgColor ?? (isCottonCandyDark ? const Color(0xFFC0A6FF).withValues(alpha: 0.03) : Colors.transparent)).withValues(alpha: 0.0),
                          containerBgColor ?? (isCottonCandyDark ? const Color(0xFFC0A6FF).withValues(alpha: 0.03) : Colors.transparent),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
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
    final parsed = ParsedTags.parse(_lastValidTag, _lastValidMoodIndex);
    String label = parsed.customMood ?? '开心';
    Color moodColor = const Color(0xFFFFB74D);

    if (parsed.customMood != null && _lastValidMoodIndex != null) {
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

    final bool hasCustomIconFile = parsed.customMoodIconPath != null && parsed.customMoodIconPath!.isNotEmpty;

    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 6, 12, 6),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          hasCustomIconFile
              ? Image.file(
                  File(parsed.customMoodIconPath!),
                  width: 20,
                  height: 20,
                  errorBuilder: (c, e, s) => Icon(Icons.mood, size: 20, color: moodColor),
                )
              : Image.asset(
                  iconPath,
                  width: 20,
                  height: 20,
                  errorBuilder: (c, e, s) => Icon(Icons.mood, size: 20, color: moodColor),
                ),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: isNight ? Colors.white.withValues(alpha: 0.9) : inkColor.withValues(alpha: 0.8),
              fontFamily: 'LXGWWenKai',
            ),
          ),
          const SizedBox(width: 8),
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





  /// 渲染位于信纸顶部、整齐排布的乐高圆形凸起颗粒一排 (Top Studs Row)
  Widget _buildLegoTopStudsRow() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: List.generate(13, (index) => _buildLegoTopStud(UserState().isNight)),
    );
  }

  Widget _buildLegoTopStud(bool isNight) {
    final Color studColor = isNight ? const Color(0xFF2C2518) : const Color(0xFFFCF0D5);
    final Color highlightColor = isNight ? const Color(0xFF4C3E27) : const Color(0xFFFFFCE0);
    final Color shadowColor = isNight ? const Color(0xFF1B160E) : const Color(0xFFDCC8A0);

    return Container(
      width: 11,
      height: 11,
      decoration: BoxDecoration(
        color: studColor.withValues(alpha: 0.85), // 微融底色
        shape: BoxShape.circle,
        border: Border.all(color: highlightColor, width: 0.6),
        boxShadow: [
          // 凸起颗粒的微小下沉投影
          BoxShadow(
            color: shadowColor.withValues(alpha: 0.85),
            blurRadius: 1.5,
            offset: const Offset(0.5, 1.2),
          ),
          // 边缘反光高光
          BoxShadow(
            color: highlightColor.withValues(alpha: 0.7),
            blurRadius: 0.6,
            offset: const Offset(-0.3, -0.3),
          ),
        ],
      ),
    );
  }
}
