import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

class MomentsReplySheet extends StatefulWidget {
  final String title;
  final String hintText;
  final String confirmText;
  final Function(String) onConfirm;
  final bool isNight;

  const MomentsReplySheet({
    super.key,
    this.title = '留下此刻的回响',
    this.hintText = '记录下这一刻的触动...',
    this.confirmText = '完成回应',
    required this.onConfirm,
    this.isNight = false,
  });

  @override
  State<MomentsReplySheet> createState() => _MomentsReplySheetState();
}

class _MomentsReplySheetState extends State<MomentsReplySheet> {
  final TextEditingController _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bgColor = widget.isNight
        ? const Color(0xFF1A1C1E)
        : const Color(0xFFFDF9F0);
    final accentColor = const Color(0xFFD4A373);
    final inkColor = widget.isNight
        ? Colors.white.withValues(alpha: 0.8)
        : const Color(0xFF5D4037);

    return Container(
      // 动态响应键盘高度
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child:
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(32),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 30,
                  offset: const Offset(0, -10),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 顶部装饰手柄
                Center(
                  child: Container(
                    width: 44,
                    height: 5,
                    margin: const EdgeInsets.only(bottom: 20),
                    decoration: BoxDecoration(
                      color: inkColor.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: accentColor.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.auto_awesome_rounded,
                        size: 18,
                        color: accentColor,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      widget.title,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'LXGWWenKai',
                        color: accentColor,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Container(
                  decoration: BoxDecoration(
                    color: widget.isNight
                        ? Colors.white.withValues(alpha: 0.07)
                        : Colors.black.withValues(alpha: 0.03),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: widget.isNight
                          ? Colors.white.withValues(alpha: 0.12)
                          : const Color(0xFFE8D5B5).withValues(alpha: 0.5),
                      width: 1,
                    ),
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 4,
                  ),
                  child: TextField(
                    controller: _controller,
                    maxLines: 4,
                    autofocus: true,
                    decoration: InputDecoration(
                      hintText: widget.hintText,
                      hintStyle: TextStyle(
                        fontSize: 14,
                        color: inkColor.withValues(alpha: 0.45),
                        fontFamily: 'LXGWWenKai',
                      ),
                      border: InputBorder.none,
                    ),
                    style: TextStyle(
                      fontSize: 15,
                      color: inkColor,
                      fontFamily: 'LXGWWenKai',
                      height: 1.5,
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: Text(
                        '取消',
                        style: TextStyle(
                          color: inkColor.withValues(alpha: 0.4),
                          fontFamily: 'LXGWWenKai',
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                          onPressed: () {
                            if (_controller.text.trim().isNotEmpty) {
                              widget.onConfirm(_controller.text.trim());
                            }
                            Navigator.pop(context);
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: accentColor,
                            foregroundColor: Colors.white,
                            elevation: 0,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 24,
                              vertical: 12,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: Text(
                            widget.confirmText,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontFamily: 'LXGWWenKai',
                              fontSize: 14,
                              letterSpacing: 0.5,
                            ),
                          ),
                        )
                        .animate(
                          onPlay: (controller) =>
                              controller.repeat(reverse: true),
                        )
                        .shimmer(
                          duration: 2000.ms,
                          color: Colors.white.withValues(alpha: 0.1),
                        ),
                  ],
                ),
              ],
            ),
          ).animate().slideY(
            begin: 0.3,
            end: 0,
            duration: 400.ms,
            curve: Curves.easeOutQuart,
          ),
    );
  }
}

/// 通用的确认对话框（美化版）
class MomentsConfirmDialog extends StatelessWidget {
  final String title;
  final String content;
  final String confirmText;
  final Color confirmColor;
  final VoidCallback onConfirm;
  final bool isNight;

  const MomentsConfirmDialog({
    super.key,
    required this.title,
    required this.content,
    required this.onConfirm,
    this.confirmText = '确认',
    this.confirmColor = Colors.redAccent,
    this.isNight = false,
  });

  @override
  Widget build(BuildContext context) {
    final bgColor = isNight ? const Color(0xFF1A1C1E) : const Color(0xFFFDF9F0);
    final inkColor = isNight
        ? Colors.white.withValues(alpha: 0.8)
        : const Color(0xFF5D4037);

    return Center(
      child: Material(
        color: Colors.transparent,
        child:
            Container(
                  width: MediaQuery.of(context).size.width * 0.8,
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: bgColor,
                    borderRadius: BorderRadius.circular(28),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.1),
                        blurRadius: 30,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'LXGWWenKai',
                          color: inkColor,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        content,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 14,
                          color: inkColor.withValues(alpha: 0.6),
                          fontFamily: 'LXGWWenKai',
                          height: 1.5,
                        ),
                      ),
                      const SizedBox(height: 24),
                      Row(
                        children: [
                          Expanded(
                            child: TextButton(
                              onPressed: () => Navigator.pop(context),
                              style: TextButton.styleFrom(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 14,
                                ),
                              ),
                              child: Text(
                                '取消',
                                style: TextStyle(
                                  color: inkColor.withValues(alpha: 0.4),
                                  fontFamily: 'LXGWWenKai',
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: ElevatedButton(
                              onPressed: () {
                                Navigator.pop(context);
                                onConfirm();
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: confirmColor.withValues(
                                  alpha: 0.1,
                                ),
                                foregroundColor: confirmColor,
                                elevation: 0,
                                padding: const EdgeInsets.symmetric(
                                  vertical: 14,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: Text(
                                confirmText,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontFamily: 'LXGWWenKai',
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                )
                .animate()
                .fadeIn(duration: 250.ms)
                .scale(begin: const Offset(0.95, 0.95)),
      ),
    );
  }
}
