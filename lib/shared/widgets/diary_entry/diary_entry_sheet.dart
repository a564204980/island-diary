import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

class MoodDiaryEntrySheet extends StatefulWidget {
  final int moodIndex;
  final double intensity;

  const MoodDiaryEntrySheet({
    super.key,
    required this.moodIndex,
    required this.intensity,
  });

  @override
  State<MoodDiaryEntrySheet> createState() => _MoodDiaryEntrySheetState();
}

class _MoodDiaryEntrySheetState extends State<MoodDiaryEntrySheet> {
  final TextEditingController _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // 获取屏幕高度，设置 30% 顶部留白，即高度为 70%
    final double screenHeight = MediaQuery.of(context).size.height;

    return Container(
      height: screenHeight * 0.7,
      width: double.infinity,
      color: Colors.transparent, // 确保背景透明，不干扰信纸边缘
      child:
          Stack(
                alignment: Alignment.topCenter,
                children: [
                  // 1. 纸张背景 (paper.png)，强制全宽铺满
                  Positioned.fill(
                    child: Image.asset(
                      'assets/images/paper.png',
                      fit: BoxFit.fill,
                      width: double.infinity,
                      gaplessPlayback: true, // 核心：消除图片加载瞬间的白块
                    ),
                  ),

                  // 2. 输入内容区
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 40,
                      vertical: 60,
                    ),
                    child: Column(
                      children: [
                        const Text('✍️', style: TextStyle(fontSize: 24)),
                        const SizedBox(height: 16),
                        Expanded(
                          child: TextField(
                            controller: _controller,
                            maxLines: null,
                            autofocus: true,
                            cursorColor: const Color(0xFF8B5E3C),
                            style: const TextStyle(
                              fontFamily: 'Zhi Mang Xing',
                              fontSize: 21,
                              color: Color(0xFF5D4037),
                              height: 1.6,
                            ),
                            decoration: const InputDecoration(
                              hintText: '写下此刻的心情...',
                              hintStyle: TextStyle(
                                fontFamily: 'Zhi Mang Xing',
                                color: Color(0xFFA68A78),
                              ),
                              border: InputBorder.none,
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
                      ],
                    ),
                  ),
                ],
              )
              .animate()
              .fadeIn(duration: 400.ms)
              .moveY(
                begin: 30,
                end: 0,
                duration: 500.ms,
                curve: Curves.easeOutCubic,
              ),
    );
  }
}
