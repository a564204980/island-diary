import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// 全局通用的手帐治愈风交互式弹窗 (根据图 2 设计语言与 DraftSaveDialog 高度对齐)
class IslandDialog extends StatelessWidget {
  final String? title;
  final Widget? content;
  final String? contentText;
  final String confirmText;
  final String? cancelText;
  final VoidCallback? onConfirm;
  final VoidCallback? onCancel;

  const IslandDialog({
    super.key,
    this.title,
    this.content,
    this.contentText,
    this.confirmText = '确定',
    this.cancelText = '取消',
    this.onConfirm,
    this.onCancel,
  });

  static Future<T?> show<T>(
    BuildContext context, {
    String? title,
    Widget? content,
    String? contentText,
    String confirmText = '确定',
    String? cancelText = '取消',
    VoidCallback? onConfirm,
    VoidCallback? onCancel,
    bool barrierDismissible = true,
  }) {
    HapticFeedback.lightImpact();
    return showGeneralDialog<T>(
      context: context,
      barrierDismissible: barrierDismissible,
      barrierLabel: 'IslandDialog',
      barrierColor: Colors.black.withValues(alpha: 0.4),
      transitionDuration: const Duration(milliseconds: 250),
      pageBuilder: (context, anim1, anim2) {
        return Center(
          child: IslandDialog(
            title: title,
            content: content,
            contentText: contentText,
            confirmText: confirmText,
            cancelText: cancelText,
            onConfirm: onConfirm,
            onCancel: onCancel,
          ),
        );
      },
      transitionBuilder: (context, anim1, anim2, child) {
        return ScaleTransition(
          scale: CurvedAnimation(parent: anim1, curve: Curves.easeOutBack),
          child: FadeTransition(opacity: anim1, child: child),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool isNight = Theme.of(context).brightness == Brightness.dark;
    const fontFamily = 'LXGWWenKai';

    return BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
      child: Dialog(
        backgroundColor: Colors.transparent,
        elevation: 0,
        child: Container(
          width: 320,
          decoration: BoxDecoration(
            color: isNight ? const Color(0xFF1E293B) : const Color(0xFFFFFDF9),
            borderRadius: BorderRadius.circular(32),
            border: Border.all(
              color: isNight
                  ? Colors.white.withValues(alpha: 0.15)
                  : const Color(0xFFEADCC9),
              width: 2.0,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isNight ? 0.4 : 0.12),
                blurRadius: 36,
                spreadRadius: 2,
                offset: const Offset(0, 16),
              ),
            ],
          ),
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              // 左侧虚线心形线条装饰
              Positioned(
                left: 12,
                top: 45,
                child: CustomPaint(
                  size: const Size(30, 60),
                  painter: _DialogLeftCurvePainter(isNight: isNight),
                ),
              ),
              // 右侧植物分支与星光装饰
              Positioned(
                right: 14,
                top: 28,
                child: Icon(
                  Icons.local_florist_rounded,
                  color: isNight
                      ? Colors.white.withValues(alpha: 0.1)
                      : const Color(0xFFD7CCC8).withValues(alpha: 0.5),
                  size: 26,
                ),
              ),
              Positioned(
                right: 22,
                top: 64,
                child: Icon(
                  Icons.star_rounded,
                  color: isNight
                      ? Colors.white.withValues(alpha: 0.1)
                      : const Color(0xFFFFE082).withValues(alpha: 0.55),
                  size: 14,
                ),
              ),

              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const SizedBox(height: 26),

                    // 标题
                    if (title != null && title!.isNotEmpty) ...[
                      Text(
                        title!,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: isNight
                              ? Colors.white.withValues(alpha: 0.9)
                              : const Color(0xFF3E2723),
                          fontFamily: fontFamily,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],

                    // 内容区
                    if (content != null)
                      content!
                    else if (contentText != null && contentText!.isNotEmpty)
                      Text(
                        contentText!,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 13,
                          color: isNight
                              ? Colors.white60
                              : const Color(0xFF8D827A),
                          fontFamily: fontFamily,
                          height: 1.5,
                        ),
                      ),

                    const SizedBox(height: 24),

                    // 底部胶带/胶囊独立按钮栏
                    Row(
                      children: [
                        if (cancelText != null) ...[
                          Expanded(
                            child: SizedBox(
                              height: 44,
                              child: OutlinedButton(
                                onPressed: () {
                                  Navigator.of(context).pop(false);
                                  if (onCancel != null) onCancel!();
                                },
                                style: OutlinedButton.styleFrom(
                                  backgroundColor: isNight
                                      ? Colors.white.withValues(alpha: 0.05)
                                      : Colors.white,
                                  side: BorderSide(
                                    color: isNight
                                        ? Colors.white.withValues(alpha: 0.15)
                                        : const Color(0xFFE2E8F0),
                                    width: 1.2,
                                  ),
                                  shape: const StadiumBorder(),
                                  elevation: 0,
                                ),
                                child: Text(
                                  cancelText!,
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: isNight
                                        ? Colors.white70
                                        : const Color(0xFF64748B),
                                    fontFamily: fontFamily,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                        ],
                        Expanded(
                          child: Container(
                            height: 44,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(24),
                              gradient: const LinearGradient(
                                colors: [Color(0xFF00C6FF), Color(0xFF00ACC1)],
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFF00ACC1).withValues(alpha: 0.35),
                                  blurRadius: 10,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: ElevatedButton(
                              onPressed: () {
                                Navigator.of(context).pop(true);
                                if (onConfirm != null) onConfirm!();
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.transparent,
                                shadowColor: Colors.transparent,
                                shape: const StadiumBorder(),
                                elevation: 0,
                                padding: EdgeInsets.zero,
                              ),
                              child: Text(
                                confirmText,
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                  fontFamily: fontFamily,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DialogLeftCurvePainter extends CustomPainter {
  final bool isNight;
  _DialogLeftCurvePainter({required this.isNight});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = isNight ? Colors.white.withValues(alpha: 0.12) : const Color(0xFFD7CCC8)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;

    for (var i = 0; i <= 20; i++) {
      final t = i / 20;
      final x = (1 - t) * (1 - t) * 0 + 2 * (1 - t) * t * 22 + t * t * 10;
      final y = (1 - t) * (1 - t) * 0 + 2 * (1 - t) * t * 18 + t * t * 52;

      if (i % 2 == 0) {
        canvas.drawCircle(Offset(x, y), 1.0, paint);
      }
    }

    final heartPaint = Paint()
      ..color = const Color(0xFF81D4FA)
      ..style = PaintingStyle.fill;

    final heartPath = Path();
    const hx = 10.0;
    const hy = 52.0;

    heartPath.moveTo(hx, hy);
    heartPath.cubicTo(hx - 3, hy - 3, hx - 6, hy, hx, hy + 5);
    heartPath.cubicTo(hx + 6, hy, hx + 3, hy - 3, hx, hy);
    canvas.drawPath(heartPath, heartPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
