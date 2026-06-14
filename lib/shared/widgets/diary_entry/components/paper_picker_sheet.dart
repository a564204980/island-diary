import 'package:flutter/material.dart';
import 'package:island_diary/core/state/user_state.dart';
import 'diary_bottom_sheet.dart';
import '../utils/diary_utils.dart';
import 'diary_painters.dart';

class PaperPickerSheet extends StatefulWidget {
  final String currentStyle;
  final ValueChanged<String> onStyleSelected;
  final Color accentColor;

  const PaperPickerSheet({
    super.key,
    required this.currentStyle,
    required this.onStyleSelected,
    required this.accentColor,
  });

  static final Map<String, String> styles = {
    'note1': '海屿呼吸',
    'note2': '时光叙事',
    'note3': '云端独白',
    'note4': '晨曦物语',
    'note5': '山野诗篇',
    'note7': '林间听雨',
    'note8': '暮色温柔',
    'note9': '星河梦境',
  };

  @override
  State<PaperPickerSheet> createState() => _PaperPickerSheetState();
}

class _PaperPickerSheetState extends State<PaperPickerSheet> {
  late ScrollController _scrollController;
  late String _localStyle;
  static const double itemTotalWidth =
      96.0; // 80 (width) + 8*2 (horizontal margin)
  static const double listPadding = 16.0;

  Map<String, String> _getEffectiveStyles() {
    final themeId = UserState().selectedIslandThemeId.value;
    if (themeId == 'cotton_candy' || themeId == 'lego') {
      return {
        'classic': '默认',
        ...PaperPickerSheet.styles,
      };
    }
    return PaperPickerSheet.styles;
  }

  @override
  void initState() {
    super.initState();
    _localStyle = widget.currentStyle;
    final stylesMap = _getEffectiveStyles();
    // 找出当前选中的索引
    final int selectedIndex = stylesMap.keys.toList().indexOf(
      _localStyle,
    );

    // 计算初始滚动位置：尽可能让选中项居中
    double initialOffset = 0;
    if (selectedIndex != -1) {
      initialOffset = (selectedIndex * itemTotalWidth);
    }

    _scrollController = ScrollController(initialScrollOffset: initialOffset);

    // 在首帧渲染后，根据屏幕宽度进行二次修正，使选中项真正居中
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;

      final double screenWidth = MediaQuery.of(context).size.width;
      final double targetOffset =
          (selectedIndex * itemTotalWidth) +
          listPadding +
          (itemTotalWidth / 2) -
          (screenWidth / 2);

      // 限制在有效滚动范围内
      final double maxScroll = _scrollController.position.maxScrollExtent;
      final double minScroll = _scrollController.position.minScrollExtent;
      final double safeOffset = targetOffset.clamp(minScroll, maxScroll);

      _scrollController.animateTo(
        safeOffset,
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeOutCubic,
      );
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bool isNight = UserState().isNight;
    final themeId = UserState().selectedIslandThemeId.value;
    final bool isLego = themeId == 'lego';
    final String fontFamily = isLego ? 'SweiFistLeg' : 'LXGWWenKai';

    final Color inkColor;
    if (isNight) {
      inkColor = Colors.white;
    } else {
      inkColor = themeId == 'cotton_candy' ? const Color(0xFF7C3AED) : const Color(0xFF1F2937);
    }

    final Color textColor = inkColor.withValues(alpha: 0.9);

    return DiaryBottomSheet(
      paperStyle: 'classic',
      showDragHandle: true,
      isDiary: false,
      padding: const EdgeInsets.only(top: 8, bottom: 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "选择信纸风格",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: textColor,
                      fontFamily: fontFamily,
                    ),
                  ),
                  TextButton(
                    onPressed: () {
                      widget.onStyleSelected('classic');
                      Navigator.pop(context);
                    },
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    child: Text(
                      "去掉背景",
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: textColor.withValues(alpha: 0.6),
                        fontFamily: fontFamily,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 130,
              child: ListView.builder(
                controller: _scrollController,
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(
                  horizontal: listPadding,
                  vertical: 8,
                ),
                clipBehavior: Clip.none,
                itemCount: _getEffectiveStyles().length,
                itemBuilder: (context, index) {
                  final stylesMap = _getEffectiveStyles();
                  final key = stylesMap.keys.elementAt(index);
                  final label = stylesMap.values.elementAt(index);
                  final isSelected = _localStyle == key;
                  final itemAccentColor = DiaryUtils.getAccentColor(key, isNight);

                  return GestureDetector(
                    onTap: () {
                      if (_localStyle == key) return;
                      setState(() {
                        _localStyle = key;
                      });
                      widget.onStyleSelected(key);
                    },
                    child: AnimatedScale(
                      scale: isSelected ? 1.08 : 1.0,
                      duration: const Duration(milliseconds: 250),
                      curve: Curves.easeOutBack,
                      child: Container(
                        width: 80,
                        margin: const EdgeInsets.symmetric(horizontal: 8),
                        child: Column(
                          children: [
                            AnimatedContainer(
                                duration: const Duration(milliseconds: 250),
                                curve: Curves.easeInOut,
                                padding: const EdgeInsets.all(3.0), // 优雅的间距
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(19),
                                  border: Border.all(
                                    color: isSelected
                                        ? itemAccentColor.withValues(alpha: 0.85)
                                        : Colors.transparent,
                                    width: 2.2, // 加粗的外圈，更加显眼精致
                                  ),
                                ),
                                child: AnimatedContainer(
                                    duration: const Duration(milliseconds: 250),
                                    curve: Curves.easeInOut,
                                    width: 64,
                                    height: 74,
                                    decoration: BoxDecoration(
                                      color: isNight
                                          ? Colors.black26
                                          : (UserState().selectedIslandThemeId.value == 'lego' && key == 'classic'
                                              ? const Color(0xFFFDF3E3)
                                              : (UserState().selectedIslandThemeId.value == 'cotton_candy' && key == 'classic'
                                                  ? const Color(0xFFFBF3E9)
                                                  : Colors.white)),
                                      borderRadius: BorderRadius.circular(14),
                                      border: Border.all(
                                        color: isNight ? Colors.white10 : Colors.black.withValues(alpha: 0.05),
                                        width: 1.0,
                                      ),
                                      boxShadow: [
                                        if (isSelected)
                                          BoxShadow(
                                            color: itemAccentColor.withValues(alpha: 0.35),
                                            blurRadius: 10,
                                            spreadRadius: 0.5,
                                            offset: const Offset(0, 3),
                                          ),
                                        if (!isSelected)
                                          BoxShadow(
                                            color: Colors.black.withValues(alpha: 0.05),
                                            blurRadius: 5,
                                            offset: const Offset(0, 2),
                                          ),
                                      ],
                                    ),
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(13),
                                      child: Stack(
                                        children: [
                                          if (key.startsWith('note') || (key == 'classic' && UserState().selectedIslandThemeId.value == 'cotton_candy'))
                                            Positioned.fill(
                                              child: Image.asset(
                                                key == 'classic'
                                                    ? (isNight
                                                        ? 'assets/images/theme/miamhuadao/note/mianhuadao_note_defalut_night_bg.png'
                                                        : 'assets/images/theme/miamhuadao/note/mianhuadao_note_defalut_bg.png')
                                                    : DiaryUtils.getPaperBackgroundPath(
                                                        key,
                                                        isNight,
                                                      ),
                                                fit: BoxFit.cover,
                                              ),
                                            ),
                                          Positioned.fill(
                                            child: CustomPaint(
                                              painter: PaperBackgroundPainter(
                                                style: key,
                                                isNight: isNight,
                                                accentColor: widget.accentColor,
                                              ),
                                            ),
                                          ),
                                          Positioned(
                                            bottom: 4,
                                            right: 4,
                                            child: AnimatedScale(
                                              scale: isSelected ? 1.0 : 0.05,
                                              duration: const Duration(milliseconds: 250),
                                              curve: Curves.easeOutBack,
                                              child: AnimatedOpacity(
                                                opacity: isSelected ? 1.0 : 0.0,
                                                duration: const Duration(milliseconds: 200),
                                                child: Container(
                                                  padding: const EdgeInsets.all(2.5),
                                                  decoration: BoxDecoration(
                                                    color: itemAccentColor,
                                                    shape: BoxShape.circle,
                                                    boxShadow: [
                                                      BoxShadow(
                                                        color: Colors.black.withValues(alpha: 0.15),
                                                        blurRadius: 3,
                                                        offset: const Offset(0, 1),
                                                      ),
                                                    ],
                                                  ),
                                                  child: const Icon(
                                                    Icons.check_rounded,
                                                    size: 10,
                                                    color: Colors.white,
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                              ),
                            const SizedBox(height: 8),
                            Text(
                              label,
                              style: TextStyle(
                                fontSize: 12,
                                color: isSelected
                                    ? itemAccentColor
                                    : textColor.withValues(alpha: 0.6),
                                fontWeight: isSelected
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                                fontFamily: fontFamily,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
    );
  }
}
