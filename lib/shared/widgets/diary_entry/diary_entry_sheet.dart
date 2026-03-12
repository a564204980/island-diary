import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:island_diary/shared/widgets/mood_picker/config/mood_config.dart';
import 'package:island_diary/core/state/user_state.dart';
import 'dart:ui';

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
  void initState() {
    super.initState();
    // 初始化时尝试从草稿恢复内容（仅当心情匹配时，或者用户直接进入时）
    final draft = UserState().diaryDraft.value;
    if (draft != null && draft.moodIndex == widget.moodIndex) {
      _controller.text = draft.content;
    }

    // 监听输入，实时保存草稿
    _controller.addListener(_updateDraft);
  }

  void _updateDraft() {
    UserState().saveDraft(widget.moodIndex, widget.intensity, _controller.text);
  }

  @override
  void dispose() {
    _controller.removeListener(_updateDraft);
    _controller.dispose();
    super.dispose();
  }

  String _getFormattedDate() {
    final now = DateTime.now();
    return '${now.year}年${now.month}月${now.day}日';
  }

  void _onSave() {
    // 1. 执行保存逻辑（此处可扩展持久化到数据库）
    debugPrint('Saving diary: ${_controller.text}');

    // 2. 清空草稿
    UserState().clearDraft();

    // 3. 退出页面
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    // 锁定物理屏幕高度，确保信纸定位基准不随键盘缩短
    final double screenHeight = MediaQueryData.fromView(
      View.of(context),
    ).size.height;
    final mood = kMoods[widget.moodIndex];

    return GestureDetector(
      onTap: () => Navigator.of(context).pop(),
      behavior: HitTestBehavior.opaque,
      child: Stack(
        children: [
          // 1. 顶部标题与日期
          Positioned(
            top: screenHeight * 0.07,
            left: 0,
            right: 0,
            child: Column(
              children: [
                const Text(
                  '记下这一刻的心情',
                  style: TextStyle(
                    fontFamily: 'FZKai',
                    fontSize: 32,
                    color: Colors.white,
                    shadows: [
                      Shadow(
                        color: Colors.black26,
                        offset: Offset(0, 2),
                        blurRadius: 4,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  _getFormattedDate(),
                  style: TextStyle(
                    fontFamily: 'FZKai',
                    fontSize: 18,
                    color: Colors.white.withOpacity(0.9),
                  ),
                ),
              ],
            ).animate().fadeIn(duration: 400.ms).moveY(begin: -20, end: 0),
          ),

          // 2. 信纸主体
          Align(
            alignment: Alignment.topCenter,
            child: Padding(
              padding: EdgeInsets.only(top: screenHeight * 0.20, bottom: 0),
              child: Container(
                constraints: const BoxConstraints(maxWidth: 600),
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    GestureDetector(
                      onTap: () {}, // 消费点击
                      child: Stack(
                        clipBehavior: Clip.none,
                        alignment: Alignment.topCenter,
                        children: [
                          // 信纸容器（高度随键盘动态变化）
                          Builder(
                            builder: (context) {
                              final viewInsets = MediaQuery.of(
                                context,
                              ).viewInsets;
                              final double baseHeight = screenHeight * 0.64;
                              // 计算从信纸顶部到键盘顶部的垂直距离，预留 8 像素间隙
                              final double availableHeight =
                                  screenHeight -
                                  viewInsets.bottom -
                                  (screenHeight * 0.19) -
                                  8;
                              final double dynamicHeight =
                                  availableHeight < baseHeight
                                  ? availableHeight
                                  : baseHeight;

                              return AnimatedContainer(
                                duration: const Duration(milliseconds: 250),
                                curve: Curves.easeOutCubic,
                                height: dynamicHeight,
                                width: double.infinity,
                                decoration: BoxDecoration(
                                  boxShadow: [
                                    BoxShadow(
                                      color: (mood.glowColor ?? Colors.amber)
                                          .withOpacity(0.3),
                                      blurRadius: 40,
                                      spreadRadius: -10,
                                    ),
                                  ],
                                ),
                                child: Stack(
                                  children: [
                                    Positioned.fill(
                                      child: Image.asset(
                                        'assets/images/paper.png',
                                        fit: BoxFit.fill,
                                        gaplessPlayback: true,
                                      ),
                                    ),
                                    Padding(
                                      padding: const EdgeInsets.fromLTRB(
                                        32,
                                        20,
                                        32,
                                        20,
                                      ),
                                      child: Column(
                                        children: [
                                          Expanded(
                                            child: TextField(
                                              controller: _controller,
                                              maxLines: null,
                                              autofocus: true,
                                              cursorColor: const Color(
                                                0xFF8B5E3C,
                                              ),
                                              style: const TextStyle(
                                                fontFamily: 'FZKai',
                                                fontSize: 20,
                                                color: Color(0xFF5D4037),
                                                height: 1.6,
                                              ),
                                              decoration: const InputDecoration(
                                                hintText: '记录下这一刻的想法吧...',
                                                hintStyle: TextStyle(
                                                  fontFamily: 'FZKai',
                                                  color: Color(0xFFA68A78),
                                                ),
                                                border: InputBorder.none,
                                              ),
                                            ),
                                          ),
                                          // 保存按钮
                                          Align(
                                            alignment: Alignment.bottomRight,
                                            child: TextButton(
                                              onPressed: _onSave,
                                              child: const Text(
                                                '保存并封存',
                                                style: TextStyle(
                                                  fontFamily: 'FZKai',
                                                  fontSize: 18,
                                                  fontWeight: FontWeight.bold,
                                                  color: Color(0xFF8B5E3C),
                                                ),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ).animate().fadeIn(duration: 500.ms),

                          // 心情图标与强度标签
                          Positioned(
                            top: -24,
                            child:
                                Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 16,
                                        vertical: 8,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Colors.white.withOpacity(0.85),
                                        borderRadius: BorderRadius.circular(20),
                                        border: Border.all(
                                          color: Colors.white.withAlpha(50),
                                          width: 1.5,
                                        ),
                                        boxShadow: const [
                                          BoxShadow(
                                            color: Colors.black12,
                                            blurRadius: 10,
                                            offset: Offset(0, 4),
                                          ),
                                        ],
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Image.asset(
                                            mood.iconPath ??
                                                'assets/images/icons/sun.png',
                                            width: 24,
                                            height: 24,
                                          ),
                                          const SizedBox(width: 8),
                                          Text(
                                            '强度 ${(widget.intensity * 10).toInt()}',
                                            style: const TextStyle(
                                              color: Color(0xFF5D4037),
                                              fontWeight: FontWeight.bold,
                                              fontSize: 15,
                                            ),
                                          ),
                                        ],
                                      ),
                                    )
                                    .animate()
                                    .fadeIn(delay: 300.ms)
                                    .moveY(begin: 10, end: 0),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
