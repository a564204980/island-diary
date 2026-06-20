import 'package:flutter/material.dart';
import 'package:island_diary/core/state/user_state.dart';

/// 全局顶置卡片式通知召唤方法
OverlayEntry showTopToast(
  BuildContext context,
  String message, {
  IconData icon = Icons.info_outline_rounded,
  Color? iconColor,
  Duration duration = const Duration(milliseconds: 2500),
}) {
  final overlayState = Overlay.of(context);
  
  late OverlayEntry overlayEntry;
  overlayEntry = OverlayEntry(
    builder: (context) {
      return TopToast(
        message: message,
        icon: icon,
        iconColor: iconColor,
        duration: duration,
        onDismiss: () {
          try {
            overlayEntry.remove();
          } catch (_) {}
        },
      );
    },
  );
  
  overlayState.insert(overlayEntry);
  return overlayEntry;
}

/// 顶部胶囊通知公共组件，支持高度自定义
class TopToast extends StatefulWidget {
  final String message;
  final IconData icon;
  final Color? iconColor;
  final Duration duration;
  final VoidCallback onDismiss;

  const TopToast({
    super.key,
    required this.message,
    this.icon = Icons.info_outline_rounded,
    this.iconColor,
    this.duration = const Duration(milliseconds: 2500),
    required this.onDismiss,
  });

  @override
  State<TopToast> createState() => _TopToastState();
}

class _TopToastState extends State<TopToast> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _offsetAnimation;
  late Animation<double> _opacityAnimation;
  bool _isDismissed = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 320),
    );

    _offsetAnimation = Tween<Offset>(
      begin: const Offset(0.0, -1.2),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutBack,
    ));

    _opacityAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOut,
    ));

    _controller.forward();

    // 默认到达时长后自动隐藏
    Future.delayed(widget.duration, () {
      if (mounted && !_isDismissed) {
        _dismiss();
      }
    });
  }

  void _dismiss() {
    if (_isDismissed) return;
    _isDismissed = true;
    _controller.reverse().then((_) {
      widget.onDismiss();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isNight = UserState().isNight;
    final themeId = UserState().selectedIslandThemeId.value;
    final String fontFamily = themeId == 'lego' ? 'SweiFistLeg' : 'LXGWWenKai';

    final Color defaultIconColor = isNight ? const Color(0xFF818CF8) : const Color(0xFF6366F1);

    return SafeArea(
      child: Align(
        alignment: Alignment.topCenter,
        child: Padding(
          padding: const EdgeInsets.only(top: 12, left: 24, right: 24),
          child: SlideTransition(
            position: _offsetAnimation,
            child: FadeTransition(
              opacity: _opacityAnimation,
              child: Dismissible(
                key: UniqueKey(),
                direction: DismissDirection.up,
                onDismissed: (_) {
                  _isDismissed = true;
                  widget.onDismiss();
                },
                child: Material(
                  color: Colors.transparent,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    decoration: BoxDecoration(
                      color: isNight
                          ? const Color(0xFF1E293B).withValues(alpha: 0.95)
                          : Colors.white.withValues(alpha: 0.95),
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(
                        color: isNight
                            ? Colors.white.withValues(alpha: 0.08)
                            : Colors.black.withValues(alpha: 0.04),
                        width: 1.0,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: isNight ? 0.25 : 0.06),
                          blurRadius: 18,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Icon(
                          widget.icon,
                          color: widget.iconColor ?? defaultIconColor,
                          size: 16,
                        ),
                        const SizedBox(width: 8),
                        Flexible(
                          child: Text(
                            widget.message,
                            style: TextStyle(
                              color: isNight ? Colors.white : const Color(0xFF1F2937),
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              fontFamily: fontFamily,
                            ),
                          ),
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
  }
}
