part of '../../pages/statistics_page.dart';

extension BentoUtils on _StatisticsPageState {
  void _showPosterPreview(BuildContext context, bool isNight) {
    final filtered = _getFilteredDiaries();
    if (filtered.isEmpty) {
        showCupertinoDialog(
          context: context,
          builder: (context) => CupertinoAlertDialog(
            title: const Text('数据不足'),
            content: const Text('记录更多日记，才能生成专属的情感海报哦 🎨'),
            actions: [
              CupertinoDialogAction(child: const Text('我知道了'), onPressed: () => Navigator.pop(context)),
            ],
          ),
        );
        return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (context) => MoodPosterWidget(
          entries: filtered,
          isNight: isNight,
        ),
      ),
    );
  }

  void _showMoodDetailSheet(BuildContext context, int moodIndex, List<DiaryEntry> subset, bool isNight) {
    final config = kMoods[moodIndex % kMoods.length];
    final moodColor = config.glowColor ?? Colors.yellow;
    final entries = subset.where((e) => e.moodIndex == moodIndex).toList();
    entries.sort((a,b) => b.dateTime.compareTo(a.dateTime));

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        return Container(
          height: MediaQuery.of(context).size.height * 0.7,
          decoration: BoxDecoration(
            color: isNight ? const Color(0xFF1E1E1E) : Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            children: [
              const SizedBox(height: 8),
              Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey.withOpacity(0.3), borderRadius: BorderRadius.circular(2))),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(width: 12, height: 12, decoration: BoxDecoration(shape: BoxShape.circle, color: moodColor)),
                  const SizedBox(width: 8),
                  Text('${config.label} (${entries.length}篇)', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: isNight ? Colors.white : Colors.black87)),
                ]
              ),
              const Divider(height: 32),
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  itemCount: entries.length,
                  itemBuilder: (context, index) {
                    final e = entries[index];
                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(color: isNight ? Colors.white10 : Colors.black.withOpacity(0.04), borderRadius: BorderRadius.circular(16)),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                           Text(DateFormat('MM月dd日 HH:mm').format(e.dateTime), style: TextStyle(fontSize: 12, color: isNight ? Colors.white54 : Colors.black45)),
                           const SizedBox(height: 8),
                           Text(e.content, style: TextStyle(fontSize: 14, color: isNight ? Colors.white : Colors.black87), maxLines: 3, overflow: TextOverflow.ellipsis),
                        ],
                      )
                    );
                  }
                )
              )
            ]
          )
        );
      }
    );
  }

  Widget _buildGlassCard({required bool isNight, required Widget child, EdgeInsetsGeometry? padding}) {
    return GlassBento(
      isNight: isNight,
      padding: padding,
      child: child,
    );
  }

  TextStyle _bentoTitleStyle(bool isNight) {
    return TextStyle(
      fontSize: 16,
      fontWeight: FontWeight.bold,
      color: isNight ? Colors.white : const Color(0xFF5A3E28),
      letterSpacing: 0.5,
    );
  }

  void _showBentoInfoDialog({
    required BuildContext context,
    required String title,
    required String content,
    required bool isNight,
  }) {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: "BentoInfo",
      barrierColor: Colors.black.withOpacity(isNight ? 0.7 : 0.4),
      transitionDuration: const Duration(milliseconds: 400),
      pageBuilder: (context, anim1, anim2) => const SizedBox(),
      transitionBuilder: (context, anim1, anim2, child) {
        final curve = Curves.easeOutBack.transform(anim1.value);
        return Transform.scale(
          scale: 0.85 + (curve * 0.15),
          child: Opacity(
            opacity: anim1.value,
            child: Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 40),
                child: Material(
                  color: Colors.transparent,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(28),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                      child: Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: isNight 
                              ? const Color(0xFF1A1A1A).withOpacity(0.8) 
                              : Colors.white.withOpacity(0.85),
                          borderRadius: BorderRadius.circular(28),
                          border: Border.all(
                            color: isNight ? Colors.white10 : Colors.black.withOpacity(0.05),
                          ),
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(title, style: TextStyle(
                                  fontSize: 18, 
                                  fontWeight: FontWeight.bold, 
                                  color: isNight ? Colors.white : const Color(0xFF5A3E28),
                                )),
                                GestureDetector(
                                  onTap: () => Navigator.pop(context),
                                  child: Icon(
                                    CupertinoIcons.clear_circled_solid, 
                                    color: isNight ? Colors.white24 : Colors.black12,
                                    size: 22,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 18),
                            _buildHighlightedText(
                              context,
                              content,
                              isNight,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildHighlightedText(BuildContext context, String content, bool isNight) {
    // 使用正则拆分文字，识别 [[...]] 语法
    final regex = RegExp(r'\[\[(.*?)\]\]');
    final matches = regex.allMatches(content);
    
    if (matches.isEmpty) {
      return Text(
        content,
        style: TextStyle(
          fontSize: 14,
          height: 1.6,
          color: isNight ? Colors.white70 : Colors.black87,
          fontFamily: 'LXGWWenKai',
        ),
      );
    }

    final List<InlineSpan> spans = [];
    int lastIndex = 0;

    // 获取当前的主题色用于下划线
    final themeColor = isNight ? const Color(0xFFFFD54F) : const Color(0xFFD4A373);

    for (var match in matches) {
      // 添加普通文本
      if (match.start > lastIndex) {
        spans.add(TextSpan(
          text: content.substring(lastIndex, match.start),
          style: TextStyle(
            fontSize: 14,
            height: 1.6,
            color: isNight ? Colors.white70 : Colors.black87,
            fontFamily: 'LXGWWenKai',
          ),
        ));
      }

      // 添加高亮文本
      final highlightText = match.group(1)!;
      spans.add(WidgetSpan(
        alignment: PlaceholderAlignment.middle,
        child: _HandDrawnHighlight(
          text: highlightText,
          color: themeColor.withOpacity(0.5),
          isNight: isNight,
        ),
      ));

      lastIndex = match.end;
    }

    // 最后的剩余文本
    if (lastIndex < content.length) {
      spans.add(TextSpan(
        text: content.substring(lastIndex),
        style: TextStyle(
          fontSize: 14,
          height: 1.6,
          color: isNight ? Colors.white70 : Colors.black87,
          fontFamily: 'LXGWWenKai',
        ),
      ));
    }

    return RichText(
      text: TextSpan(children: spans),
    );
  }

  Widget _buildBentoHeader({
    required BuildContext context,
    required String title,
    required String helpContent,
    required bool isNight,
    Widget? rightAction,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(title, style: _bentoTitleStyle(isNight)),
            const SizedBox(width: 4),
            GestureDetector(
              onTap: () => _showBentoInfoDialog(
                context: context, 
                title: title, 
                content: helpContent, 
                isNight: isNight
              ),
              child: Icon(
                CupertinoIcons.info_circle, 
                size: 14, 
                color: isNight ? Colors.white24 : Colors.black.withOpacity(0.2)
              ),
            ),
          ],
        ),
        if (rightAction != null) rightAction,
      ],
    );
  }

  /// 通用 Bento 图表提示框
  Widget _buildBentoTooltip({
    required String title,
    required List<_BentoTooltipItem> items,
    required double relativeX, // 0.0 - 1.0 用于决定左右位置
    required double chartWidth,
    required bool isNight,
    double? top,
    double? bottom,
    double width = 150,
    double maxHeight = 140,
  }) {
    if (items.isEmpty) return const SizedBox.shrink();

    // 计算水平位置
    bool isLeft = relativeX > 0.5;
    double left = relativeX * chartWidth;
    if (isLeft) {
      left -= (width + 12);
    } else {
      left += 12;
    }

    return Positioned(
      left: left,
      top: top ?? 10,
      bottom: bottom,
      child: Container(
        width: width,
        constraints: BoxConstraints(maxHeight: maxHeight),
        decoration: BoxDecoration(
          color: isNight ? const Color(0xE6262626) : const Color(0xE6FFFFFF),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: isNight ? Colors.white10 : Colors.black12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(isNight ? 0.3 : 0.1),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
            child: Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: isNight ? Colors.white38 : Colors.black38,
                      fontFamily: 'LXGWWenKai',
                    ),
                  ),
                  const SizedBox(height: 8),
                  Flexible(
                    child: SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      child: Column(
                        children: items.map((item) {
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 6),
                            child: Row(
                              children: [
                                if (item.color != null)
                                  Container(
                                    width: 4,
                                    height: 4,
                                    decoration: BoxDecoration(color: item.color, shape: BoxShape.circle),
                                  ),
                                if (item.color != null) const SizedBox(width: 6),
                                Expanded(
                                  child: Text(
                                    item.label,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      color: item.color?.withOpacity(0.9) ?? (isNight ? Colors.white70 : Colors.black87),
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                      fontFamily: 'LXGWWenKai',
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  item.value,
                                  style: TextStyle(
                                    color: (isNight ? Colors.white38 : Colors.black38),
                                    fontSize: 10,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ).animate().fadeIn(duration: 200.ms).slideX(begin: isLeft ? 0.05 : -0.05, end: 0, curve: Curves.easeOutCubic),
    );
  }
}

/// Bento 提示框数据项
class _BentoTooltipItem {
  final String label;
  final String value;
  final Color? color;

  _BentoTooltipItem({
    required this.label,
    required this.value,
    this.color,
  });
}

/// 手绘风格高亮 Widget
class _HandDrawnHighlight extends StatelessWidget {
  final String text;
  final Color color;
  final bool isNight;

  const _HandDrawnHighlight({
    required this.text,
    required this.color,
    required this.isNight,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        // 背景下划线
        Positioned(
          left: -2,
          right: -2,
          bottom: 2,
          child: CustomPaint(
            size: const Size(double.infinity, 8),
            painter: _HandDrawnUnderlinePainter(color),
          ),
        ),
        // 文字
        Text(
          text,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: isNight ? Colors.white : Colors.black87,
            fontFamily: 'LXGWWenKai',
          ),
        ),
      ],
    );
  }
}

/// 手绘波纹下划线绘制器
class _HandDrawnUnderlinePainter extends CustomPainter {
  final Color color;
  _HandDrawnUnderlinePainter(this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0
      ..strokeCap = StrokeCap.round;

    final path = Path();
    final double w = size.width;
    final double h = size.height;

    // 手绘感算法：随机波动的三次贝塞尔曲线
    path.moveTo(0, h * 0.8);
    
    // 第一段：略微下弧
    path.quadraticBezierTo(
      w * 0.25, h * 1.1, 
      w * 0.5, h * 0.9,
    );
    
    // 第二段：略微上扬
    path.quadraticBezierTo(
      w * 0.75, h * 0.7, 
      w, h * 0.85,
    );

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
