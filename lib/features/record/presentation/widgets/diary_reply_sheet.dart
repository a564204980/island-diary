import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:island_diary/shared/widgets/diary_entry/components/diary_bottom_sheet.dart';

class DiaryReplySheet extends StatefulWidget {
  final String title;
  final String hintText;
  final String confirmText;
  final Function(String) onConfirm;
  final bool isNight;
  final String paperStyle;

  const DiaryReplySheet({
    super.key,
    this.title = '留下此刻的回响',
    this.hintText = '记录下这一刻的触动...',
    this.confirmText = '完成回应',
    required this.onConfirm,
    this.isNight = false,
    this.paperStyle = 'default',
  });

  @override
  State<DiaryReplySheet> createState() => _DiaryReplySheetState();
}

class _DiaryReplySheetState extends State<DiaryReplySheet> {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  bool _isFocused = false;

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(() {
      setState(() {
        _isFocused = _focusNode.hasFocus;
      });
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final accentColor = const Color(0xFFD4A373);
    
    final inkColor = widget.isNight
        ? Colors.white.withValues(alpha: 0.9)
        : const Color(0xFF2C2C2C); // 使用高级深灰，搭配白底更显清爽现代

    final inputBgColor = widget.isNight
        ? Colors.black.withValues(alpha: 0.25)
        : const Color(0xFFF5F7FA); // 在白底上使用极淡的冷灰文本域，增加极简层次感

    final borderActiveColor = widget.isNight
        ? const Color(0xFFE1AF78)
        : const Color(0xFFD4A373);

    final borderInactiveColor = widget.isNight
        ? Colors.white.withValues(alpha: 0.08)
        : const Color(0xFFE8D5B5).withValues(alpha: 0.25);

    return DiaryBottomSheet(
      paperStyle: widget.paperStyle,
      showDragHandle: true,
      isDiary: false,
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(7),
                decoration: BoxDecoration(
                  color: accentColor.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.auto_awesome_rounded,
                  size: 16,
                  color: accentColor,
                ),
              ),
              const SizedBox(width: 10),
              Text(
                widget.title,
                style: TextStyle(
                  fontSize: 16.5,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'LXGWWenKai',
                  color: inkColor.withValues(alpha: 0.95), // 避免纯亮色以降低压迫感
                  letterSpacing: 0.3,
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          // 带有聚焦呼吸边框效果的输入框容器
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOutCubic,
            decoration: BoxDecoration(
              color: inputBgColor,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: _isFocused ? borderActiveColor : borderInactiveColor,
                width: 1.5,
              ),
              boxShadow: _isFocused
                  ? [
                      BoxShadow(
                        color: borderActiveColor.withValues(alpha: 0.12),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      )
                    ]
                  : [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.01),
                        blurRadius: 3,
                        offset: const Offset(0, 1),
                      )
                    ],
            ),
            padding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 6,
            ),
            child: TextField(
              controller: _controller,
              focusNode: _focusNode,
              maxLines: 4,
              autofocus: true,
              decoration: InputDecoration(
                hintText: widget.hintText,
                hintStyle: TextStyle(
                  fontSize: 14,
                  color: inkColor.withValues(alpha: 0.38),
                  fontFamily: 'LXGWWenKai',
                ),
                border: InputBorder.none,
              ),
              style: TextStyle(
                fontSize: 14.5,
                color: inkColor,
                fontFamily: 'LXGWWenKai',
                height: 1.5,
              ),
            ),
          ),
          const SizedBox(height: 22),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              // 升级的“取消”扁平胶囊
              GestureDetector(
                onTap: () {
                  FocusManager.instance.primaryFocus?.unfocus();
                  Navigator.pop(context);
                },
                behavior: HitTestBehavior.opaque,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(14),
                    color: widget.isNight
                        ? Colors.white.withValues(alpha: 0.04)
                        : Colors.black.withValues(alpha: 0.03),
                  ),
                  child: Text(
                    '取消',
                    style: TextStyle(
                      color: inkColor.withValues(alpha: 0.55),
                      fontFamily: 'LXGWWenKai',
                      fontSize: 13.5,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              // 渐变高光阴影的“完成回应”高级按钮
              GestureDetector(
                onTap: () {
                  if (_controller.text.trim().isNotEmpty) {
                    widget.onConfirm(_controller.text.trim());
                  }
                  FocusManager.instance.primaryFocus?.unfocus();
                  Navigator.pop(context);
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 10),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(14),
                    gradient: LinearGradient(
                      colors: widget.isNight
                          ? [const Color(0xFFE1AF78), const Color(0xFFC7955F)]
                          : [const Color(0xFFE5B582), const Color(0xFFD4A373)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: (widget.isNight ? const Color(0xFFE1AF78) : const Color(0xFFD4A373))
                            .withValues(alpha: widget.isNight ? 0.25 : 0.35),
                        blurRadius: 10,
                        offset: const Offset(0, 3),
                      )
                    ],
                  ),
                  child: Text(
                    widget.confirmText,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontFamily: 'LXGWWenKai',
                      fontSize: 13.5,
                      color: Colors.white,
                      letterSpacing: 0.3,
                    ),
                  ),
                ),
              ).animate(
                onPlay: (controller) => controller.repeat(reverse: true),
              ).shimmer(
                duration: 2200.ms,
                color: Colors.white.withValues(alpha: 0.12),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
