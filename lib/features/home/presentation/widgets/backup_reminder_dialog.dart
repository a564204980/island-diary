import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:island_diary/core/state/user_state.dart';
import 'package:island_diary/features/profile/presentation/pages/cloud_sync_page.dart';

class BackupReminderDialog extends StatelessWidget {
  final int overdueSeconds;
  final bool isNight;
  final String fontFamily;

  const BackupReminderDialog({
    super.key,
    required this.overdueSeconds,
    required this.isNight,
    required this.fontFamily,
  });

  static void show(BuildContext context, {
    required int overdueSeconds,
    required bool isNight,
    required String fontFamily,
  }) {
    showDialog(
      context: context,
      barrierDismissible: true,
      barrierColor: Colors.black.withValues(alpha: 0.4),
      builder: (context) {
        return BackupReminderDialog(
          overdueSeconds: overdueSeconds,
          isNight: isNight,
          fontFamily: fontFamily,
        );
      },
    );
  }

  String _formatOverdueTime(int totalSeconds) {
    final days = totalSeconds ~/ 86400;
    final hours = (totalSeconds % 86400) ~/ 3600;
    final minutes = (totalSeconds % 3600) ~/ 60;
    final seconds = totalSeconds % 60;

    final parts = <String>[];
    if (days > 0) parts.add('$days天');
    if (hours > 0) parts.add('$hours小时');
    if (minutes > 0) parts.add('$minutes分钟');
    if (seconds > 0 || parts.isEmpty) parts.add('$seconds秒');

    return parts.join('');
  }

  @override
  Widget build(BuildContext context) {
    final overdueStr = _formatOverdueTime(overdueSeconds);

    return BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
      child: Dialog(
        backgroundColor: Colors.transparent,
        elevation: 0,
        child: Stack(
          clipBehavior: Clip.none,
          alignment: Alignment.topCenter,
          children: [
            // 1. 主体卡片
            Container(
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
                    top: 60,
                    child: CustomPaint(
                      size: const Size(30, 60),
                      painter: _LeftCurvePainter(isNight: isNight),
                    ),
                  ),
                  // 右侧植物分支与星光装饰
                  Positioned(
                    right: 12,
                    top: 40,
                    child: Icon(
                      Icons.local_florist_rounded,
                      color: isNight ? Colors.white.withValues(alpha: 0.1) : const Color(0xFFD7CCC8).withValues(alpha: 0.5),
                      size: 28,
                    ),
                  ),
                  Positioned(
                    right: 20,
                    top: 80,
                    child: Icon(
                      Icons.star_rounded,
                      color: isNight ? Colors.white.withValues(alpha: 0.1) : const Color(0xFFFFE082).withValues(alpha: 0.5),
                      size: 14,
                    ),
                  ),
                  
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const SizedBox(height: 54),
                        
                        // 标题
                        Text(
                          '别忘了备份今天的回忆',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: isNight ? Colors.white.withValues(alpha: 0.9) : const Color(0xFF3E2723),
                            fontFamily: fontFamily,
                            letterSpacing: 0.5,
                          ),
                        ),
                        const SizedBox(height: 16),
                        
                        // 状态小药丸布局
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(
                            color: isNight
                                ? Colors.white.withValues(alpha: 0.05)
                                : const Color(0xFFEDF2F7),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.access_time_rounded,
                                color: Color(0xFF00ACC1),
                                size: 16,
                              ),
                              const SizedBox(width: 6),
                              RichText(
                                text: TextSpan(
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: isNight ? Colors.white70 : const Color(0xFF5D5450),
                                    fontFamily: fontFamily,
                                  ),
                                  children: [
                                    const TextSpan(text: '已 '),
                                    TextSpan(
                                      text: overdueStr,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFF00ACC1),
                                      ),
                                    ),
                                    const TextSpan(text: ' 未备份'),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),
                        
                        // 描述内容
                        Column(
                          children: [
                            Text(
                              '你的日记和回忆还没有完成备份',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 13,
                                color: isNight ? Colors.white60 : const Color(0xFF8D827A),
                                fontFamily: fontFamily,
                                height: 1.5,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '去给珍贵的数据加一份安心守护吧',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 13,
                                color: isNight ? Colors.white60 : const Color(0xFF8D827A),
                                fontFamily: fontFamily,
                                height: 1.5,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 28),
                        
                        // 按钮栏
                        Row(
                          children: [
                            Expanded(
                              child: _buildReminderOutlineButton(
                                context: context,
                                label: '稍后提醒',
                                isNight: isNight,
                                fontFamily: fontFamily,
                                onPressed: () => Navigator.pop(context),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _buildReminderGradientButton(
                                context: context,
                                label: '立即备份',
                                isNight: isNight,
                                fontFamily: fontFamily,
                                onPressed: () {
                                  Navigator.pop(context);
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => const CloudSyncPage(),
                                    ),
                                  );
                                },
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            
            // 2. 头部悬浮的 Mascot 头像（半个圆在主体卡片上方）
            Positioned(
              top: -42, // 直径 84，向上偏移 42
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isNight ? const Color(0xFF0F172A) : Colors.white,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isNight
                        ? const Color(0xFF00ACC1).withValues(alpha: 0.4)
                        : const Color(0xFFE0F7FA),
                    width: 4.0,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF00ACC1).withValues(alpha: isNight ? 0.3 : 0.15),
                      blurRadius: 18,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Image.asset(
                  UserState().selectedMascotType.value,
                  width: 60,
                  height: 60,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReminderOutlineButton({
    required BuildContext context,
    required String label,
    required bool isNight,
    required String fontFamily,
    required VoidCallback onPressed,
  }) {
    return SizedBox(
      height: 48,
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          side: BorderSide(
            color: isNight ? Colors.white24 : const Color(0xFFE2E8F0),
            width: 1.5,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          backgroundColor: isNight ? Colors.white.withValues(alpha: 0.03) : const Color(0xFFF8FAFC),
          elevation: 0,
          padding: EdgeInsets.zero,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.access_alarm_rounded,
              size: 18,
              color: isNight ? Colors.white70 : const Color(0xFF64748B),
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: isNight ? Colors.white70 : const Color(0xFF64748B),
                fontFamily: fontFamily,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReminderGradientButton({
    required BuildContext context,
    required String label,
    required bool isNight,
    required String fontFamily,
    required VoidCallback onPressed,
  }) {
    return Container(
      height: 48,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: const LinearGradient(
          colors: [Color(0xFF4DD0E1), Color(0xFF00ACC1)],
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
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          elevation: 0,
          padding: EdgeInsets.zero,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.cloud_upload_rounded,
              size: 18,
              color: Colors.white,
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Colors.white,
                fontFamily: fontFamily,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LeftCurvePainter extends CustomPainter {
  final bool isNight;
  _LeftCurvePainter({required this.isNight});

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
