import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:island_diary/core/state/user_state.dart';
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
  static const double itemTotalWidth =
      96.0; // 80 (width) + 8*2 (horizontal margin)
  static const double listPadding = 16.0;

  @override
  void initState() {
    super.initState();
    // 找出当前选中的索引
    final int selectedIndex = PaperPickerSheet.styles.keys.toList().indexOf(
      widget.currentStyle,
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
    final Color bgColor = DiaryUtils.getPopupBackgroundColor(
      widget.currentStyle,
      isNight,
    );
    final Color textColor = DiaryUtils.getInkColor(
      widget.currentStyle,
      isNight,
    ).withValues(alpha: 0.9);

    return BackdropFilter(
      filter: ImageFilter.blur(
        sigmaX: isNight ? 15 : 0,
        sigmaY: isNight ? 15 : 0,
      ),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 24),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 20,
              offset: const Offset(0, -5),
            ),
          ],
        ),
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
                      fontFamily: 'LXGWWenKai',
                    ),
                  ),
                  IconButton(
                    icon: Icon(
                      Icons.close,
                      color: textColor.withValues(alpha: 0.5),
                    ),
                    onPressed: () => Navigator.pop(context),
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
                itemCount: PaperPickerSheet.styles.length,
                itemBuilder: (context, index) {
                  final key = PaperPickerSheet.styles.keys.elementAt(index);
                  final label = PaperPickerSheet.styles.values.elementAt(index);
                  final isSelected = widget.currentStyle == key;

                  return GestureDetector(
                    onTap: () => widget.onStyleSelected(key),
                    child: AnimatedScale(
                      scale: isSelected ? 1.05 : 1.0,
                      duration: const Duration(milliseconds: 200),
                      curve: Curves.easeOutBack,
                      child: Container(
                        width: 80,
                        margin: const EdgeInsets.symmetric(horizontal: 8),
                        child: Column(
                          children: [
                            Container(
                                width: 70,
                                height: 80,
                                decoration: BoxDecoration(
                                  color: isNight ? Colors.black26 : Colors.white,
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color: isSelected
                                        ? widget.accentColor.withValues(alpha: 0.8)
                                        : (isNight ? Colors.white10 : Colors.black.withValues(alpha: 0.05)),
                                    width: isSelected ? 2.5 : 1.0,
                                  ),
                                  boxShadow: [
                                    if (isSelected)
                                      BoxShadow(
                                        color: widget.accentColor.withValues(alpha: 0.35),
                                        blurRadius: 15,
                                        spreadRadius: 2,
                                        offset: const Offset(0, 4),
                                      ),
                                    if (!isSelected)
                                      BoxShadow(
                                        color: Colors.black.withValues(alpha: 0.05),
                                        blurRadius: 6,
                                        offset: const Offset(0, 3),
                                      ),
                                  ],
                                ),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(14),
                                  child: Stack(
                                    children: [
                                      if (key.startsWith('note'))
                                        Positioned.fill(
                                          child: Image.asset(
                                            DiaryUtils.getPaperBackgroundPath(
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
                                      if (isSelected)
                                        Positioned(
                                          bottom: 6,
                                          right: 6,
                                          child: Container(
                                            padding: const EdgeInsets.all(3),
                                            decoration: BoxDecoration(
                                              color: widget.accentColor,
                                              shape: BoxShape.circle,
                                              boxShadow: [
                                                BoxShadow(
                                                  color: Colors.black.withValues(alpha: 0.2),
                                                  blurRadius: 4,
                                                  offset: const Offset(0, 1),
                                                ),
                                              ],
                                            ),
                                            child: const Icon(
                                              Icons.check,
                                              size: 10,
                                              color: Colors.white,
                                            ),
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                              ),
                            const SizedBox(height: 8),
                            Text(
                              label,
                              style: TextStyle(
                                fontSize: 12,
                                color: isSelected
                                    ? widget.accentColor
                                    : textColor.withValues(alpha: 0.6),
                                fontWeight: isSelected
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                                fontFamily: 'LXGWWenKai',
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
      ),
    );
  }
}
