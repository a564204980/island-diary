import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:island_diary/features/record/presentation/pages/diary_editor_page.dart';

class RecoverDiaryDialog extends StatelessWidget {
  final DateTime date;
  final bool isNight;

  const RecoverDiaryDialog({
    super.key,
    required this.date,
    required this.isNight,
  });

  @override
  Widget build(BuildContext context) {
    // 动态辅助颜色
    final orbColor1 = const Color(0xFFBC8A5F).withOpacity(0.3);
    final orbColor2 = const Color(0xFFAFA296).withOpacity(0.2);

    return Center(
      child: Material(
        type: MaterialType.transparency,
        child: Container(
          constraints: const BoxConstraints(maxWidth: 400),
          margin: const EdgeInsets.symmetric(horizontal: 40),
        child: Stack(
          alignment: Alignment.center,
          children: [
            // 1. 动态背景光晕 (Orbs)
            _buildAnimatedOrb(orbColor1, const Offset(-80, -60), 120),
            _buildAnimatedOrb(orbColor2, const Offset(80, 60), 150),
            
            // 2. 主体玻璃卡片
            ClipRRect(
              borderRadius: BorderRadius.circular(36),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                child: Container(
                  padding: const EdgeInsets.all(32),
                  decoration: BoxDecoration(
                    color: isNight 
                        ? Colors.black.withOpacity(0.6) 
                        : Colors.white.withOpacity(0.4),
                    borderRadius: BorderRadius.circular(36),
                    border: Border.all(
                      color: isNight 
                          ? Colors.white.withOpacity(0.12) 
                          : Colors.white.withOpacity(0.6),
                      width: 1.5,
                    ),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // 图标区：带涟漪动画
                      _buildAnimatedIcon(),
                      
                      const SizedBox(height: 28),
                      
                      // 标题文字
                      Text(
                        "时光的碎片落在了迷雾中",
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: isNight ? Colors.white.withOpacity(0.9) : const Color(0xFF5D4037),
                          fontFamily: 'LXGWWenKai',
                          letterSpacing: 0.8,
                        ),
                      ).animate().fadeIn(duration: 600.ms).moveY(begin: 10, end: 0, curve: Curves.easeOutCubic),
                      
                      const SizedBox(height: 12),
                      
                      // 副标题
                      Text(
                        "我们要把 ${date.month}月${date.day}日 找回吗？",
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 14,
                          color: isNight ? Colors.white38 : Colors.black45,
                          fontFamily: 'LXGWWenKai',
                          letterSpacing: 0.3,
                        ),
                      ).animate().fadeIn(delay: 200.ms, duration: 600.ms),
                      
                      const SizedBox(height: 40),
                      
                      // 操作按钮
                      Row(
                        children: [
                          Expanded(
                            child: _buildSecondaryButton(context),
                          ),
                          const SizedBox(width: 20),
                          Expanded(
                            child: _buildPrimaryButton(context),
                          ),
                        ],
                      ).animate().fadeIn(delay: 400.ms).moveY(begin: 20, end: 0, curve: Curves.elasticOut, duration: 800.ms),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

  Widget _buildAnimatedOrb(Color color, Offset offset, double size) {
    return Transform.translate(
      offset: offset,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: color,
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.2),
              blurRadius: 40,
              spreadRadius: 20,
            )
          ],
        ),
      ),
    ).animate(onPlay: (c) => c.repeat(reverse: true))
     .move(duration: 4.seconds, begin: const Offset(-10, -10), end: const Offset(10, 10), curve: Curves.easeInOutSine)
     .scale(duration: 3.seconds, begin: const Offset(1, 1), end: const Offset(1.2, 1.2));
  }

  Widget _buildAnimatedIcon() {
    return Stack(
      alignment: Alignment.center,
      children: [
        // 外部光晕扩散
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: (isNight ? Colors.cyanAccent : Colors.lightBlueAccent).withOpacity(0.15),
          ),
        ).animate(onPlay: (c) => c.repeat())
         .scale(duration: 2.seconds, begin: const Offset(0.8, 0.8), end: const Offset(1.5, 1.5))
         .fadeOut(duration: 2.seconds),
        
        // 中心图标
        Container(
          width: 72,
          height: 72,
          decoration: BoxDecoration(
            color: (isNight ? Colors.cyanAccent : Colors.lightBlueAccent).withOpacity(0.1),
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white.withOpacity(0.2)),
          ),
          child: const Center(child: Text("💧", style: TextStyle(fontSize: 40))),
        ).animate(onPlay: (c) => c.repeat(reverse: true))
         .shake(hz: 0.5, rotation: 0.05, duration: 3.seconds),
      ],
    );
  }

  Widget _buildPrimaryButton(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.pop(context);
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => DiaryEditorPage(
              moodIndex: 4,
              intensity: 6.0,
              initialDate: date,
            ),
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 18),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFFD4A373), Color(0xFFBC8A5F)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFD4A373).withOpacity(0.4),
              blurRadius: 15,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: const Center(
          child: Text(
            "去寻回",
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 16,
              fontFamily: 'LXGWWenKai',
            ),
          ),
        ),
      ),
    ).animate(onPlay: (c) => c.repeat(reverse: true))
     .shimmer(delay: 2.seconds, duration: 1500.ms, color: Colors.white24);
  }

  Widget _buildSecondaryButton(BuildContext context) {
    return InkWell(
      onTap: () => Navigator.pop(context),
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 18),
        decoration: BoxDecoration(
          color: isNight ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.03),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: isNight ? Colors.white10 : Colors.black12),
        ),
        child: Center(
          child: Text(
            "先不找了",
            style: TextStyle(
              color: isNight ? Colors.white38 : Colors.black38,
              fontFamily: 'LXGWWenKai',
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }
}
