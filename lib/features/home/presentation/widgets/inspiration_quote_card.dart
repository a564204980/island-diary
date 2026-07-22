import 'package:flutter/material.dart';

/// 每日灵感金句卡片 (新拓展卡片示例)
class InspirationQuoteCard extends StatefulWidget {
  final Color textColor;
  final Color subtitleColor;
  final Color accentColor;
  final String fontFamily;
  final bool isNight;
  final bool isEditMode;

  const InspirationQuoteCard({
    super.key,
    required this.textColor,
    required this.subtitleColor,
    required this.accentColor,
    required this.fontFamily,
    required this.isNight,
    this.isEditMode = false,
  });

  @override
  State<InspirationQuoteCard> createState() => _InspirationQuoteCardState();
}

class _InspirationQuoteCardState extends State<InspirationQuoteCard> {
  static const List<Map<String, String>> _quotes = [
    {"quote": "风会吹散海浪的疲倦，也会带走生活的纷扰。", "author": "《岛屿诗集》"},
    {"quote": "你记录下的每一个平凡瞬间，都是岁月赠予的宝藏。", "author": "时光书签"},
    {"quote": "生活就像一座孤岛，但只要拥抱阳光，就能开满鲜花。", "author": "岛屿日记"},
    {"quote": "向着月亮出发，即使迷路，也是在星辰之中。", "author": "夜航星"},
    {"quote": "温柔是黑暗世界里唯一不需要修饰的光芒。", "author": "云朵收藏家"},
  ];

  int _currentIndex = 0;

  void _nextQuote() {
    setState(() {
      _currentIndex = (_currentIndex + 1) % _quotes.length;
    });
  }

  @override
  Widget build(BuildContext context) {
    final item = _quotes[_currentIndex];

    final cardBg = widget.isNight
        ? Colors.black.withValues(alpha: 0.2)
        : Colors.white.withValues(alpha: 0.35);
    final borderColor = widget.isNight
        ? Colors.white.withValues(alpha: 0.1)
        : Colors.white.withValues(alpha: 0.5);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: borderColor, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: widget.isNight
                ? Colors.black.withValues(alpha: 0.2)
                : Colors.black.withValues(alpha: 0.04),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.format_quote_rounded,
                    size: 18,
                    color: widget.accentColor,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    "每日灵感",
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      fontFamily: widget.fontFamily,
                      color: widget.textColor,
                    ),
                  ),
                ],
              ),
              AnimatedScale(
                scale: widget.isEditMode ? 0.0 : 1.0,
                duration: const Duration(milliseconds: 280),
                curve: Curves.easeOutBack,
                child: AnimatedOpacity(
                  duration: const Duration(milliseconds: 200),
                  opacity: widget.isEditMode ? 0.0 : 1.0,
                  child: IgnorePointer(
                    ignoring: widget.isEditMode,
                    child: GestureDetector(
                      onTap: _nextQuote,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: widget.accentColor.withValues(alpha: 0.12),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.refresh_rounded,
                          size: 16,
                          color: widget.accentColor,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            "“${item['quote']}”",
            style: TextStyle(
              fontSize: 13.5,
              height: 1.5,
              fontFamily: widget.fontFamily,
              color: widget.textColor.withValues(alpha: 0.9),
              fontStyle: FontStyle.italic,
            ),
          ),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerRight,
            child: Text(
              "—— ${item['author']}",
              style: TextStyle(
                fontSize: 11,
                fontFamily: widget.fontFamily,
                color: widget.subtitleColor,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
