import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:island_diary/shared/widgets/mood_picker/config/mood_config.dart';
import 'package:island_diary/core/state/user_state.dart';
import 'dart:ui';
import 'dart:math' as math;
import 'components/mood_tag.dart';
import 'components/diary_toolbar.dart';
import 'components/emoji_panel.dart';

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
  final ScrollController _scrollController = ScrollController();
  final FocusNode _focusNode = FocusNode();
  bool _isEmojiOpen = false;
  double _keyboardHeight = 330.0; // 逻辑像素单位

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

    // 监听焦点变化，如果文字输入框获得焦点，自动收起表情面板
    _focusNode.addListener(() {
      if (_focusNode.hasFocus && _isEmojiOpen) {
        setState(() {
          _isEmojiOpen = false;
        });
      }
    });
  }

  void _updateDraft() {
    UserState().saveDraft(widget.moodIndex, widget.intensity, _controller.text);
    _ensureCursorVisible();
  }

  void _ensureCursorVisible() {
    if (!_scrollController.hasClients) return;

    // 状态守护：如果既没有焦点也能量没开表情，说明用户已经退出编辑模式，不执行强制对齐
    if (!_focusNode.hasFocus && !_isEmojiOpen) return;

    final text = _controller.text;
    final selection = _controller.selection;

    // 如果没有有效选择或内容为空，不执行
    if (!selection.isValid) return;

    // 稍微延迟确保组件高度已经更新完成
    Future.delayed(const Duration(milliseconds: 100), () {
      if (!_scrollController.hasClients) return;

      // 1. 获取物理尺寸
      final double screenWidth = MediaQuery.of(context).size.width;
      // 文本区域的真实约束宽度（BoxConstraints maxWidth 为 600）
      final double textFieldWidth =
          math.min(600, screenWidth) - 64; // 减去左右内间距 (32*2)

      // 2. 计算光标在文本中的 Y 坐标
      final textStyle = const TextStyle(
        fontFamily: 'FZKai',
        fontSize: 20,
        height: 1.6,
      );

      final textPainter = TextPainter(
        text: TextSpan(
          text: text.substring(0, selection.extentOffset),
          style: textStyle,
        ),
        textDirection: TextDirection.ltr,
        textAlign: TextAlign.left,
      );

      textPainter.layout(maxWidth: textFieldWidth);

      // 光标相对于 TextField 顶部的偏移
      final double cursorY = textPainter.height;

      // 3. 获取当前滚动状态
      final double currentScroll = _scrollController.offset;
      final double viewportHeight =
          _scrollController.position.viewportDimension;

      // 4. 计算光标在视口中的相对位置
      final double cursorInWindowY = cursorY - currentScroll;

      // 5. 智能避让滚动逻辑
      // 如果光标在视口下方（被遮挡）
      if (cursorInWindowY > viewportHeight - 40) {
        final double targetScroll = cursorY - viewportHeight + 60;
        _scrollController.animateTo(
          targetScroll.clamp(0.0, _scrollController.position.maxScrollExtent),
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOutCubic,
        );
      } else if (cursorInWindowY < 0) {
        // 如果光标在视口上方（被遮挡）
        _scrollController.animateTo(
          (cursorY - 20).clamp(0.0, _scrollController.position.maxScrollExtent),
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOutCubic,
        );
      }
    });
  }

  void _toggleEmoji() {
    setState(() {
      _isEmojiOpen = !_isEmojiOpen;
    });

    if (_isEmojiOpen) {
      // 打开表情面板，收起键盘
      _focusNode.unfocus();
    } else {
      // 打开键盘，收起表情面板
      _focusNode.requestFocus();
    }
  }

  void _onEmojiSelected(String emoji) {
    final text = _controller.text;
    final selection = _controller.selection;
    final newText = text.replaceRange(selection.start, selection.end, emoji);
    _controller.value = _controller.value.copyWith(
      text: newText,
      selection: TextSelection.collapsed(
        offset: selection.start + emoji.length,
      ),
    );
    _ensureCursorVisible();
  }

  @override
  void dispose() {
    _controller.removeListener(_updateDraft);
    _controller.dispose();
    _scrollController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  String _getFormattedDate() {
    final now = DateTime.now();
    return '${now.year}年${now.month}月${now.day}日';
  }

  /// 拟人化强度描述文案映射（优化版：数据驱动 + 解决 Lint 警告）
  String _getPersonifiedMoodDescription(String label, double intensity) {
    // 强度等级的前缀映射表
    const Map<String, List<String>> moodPrefixes = {
      '期待': ['略带憧憬', '满心向往', '迫不及待'],
      '厌恶': ['有些反感', '深感蹙眉', '嫌弃至极'],
      '恐惧': ['隐约不安', '忐忑紧锁', '灵魂颤栗'],
      '惊喜': ['意料之外', '万分激动', '喜从天降'],
      '平静': ['凡事从容', '岁月安好', '万籁俱寂'],
      '愤怒': ['隐隐不快', '火冒三丈', '怒气冲天'],
      '悲伤': ['隐隐哀愁', '满怀感伤', '痛彻心扉'],
      '开心': ['眉开眼笑', '神采飞扬', '狂喜雀跃'],
    };

    final int level = (intensity * 10).toInt(); // 0-10
    final List<String>? options = moodPrefixes[label];

    if (options == null) return label;

    // 根据强度等级 (0-10) 确定索引：轻微(0-3), 中等(4-7), 强烈(8-10)
    final int index = level <= 3 ? 0 : (level <= 7 ? 1 : 2);

    return '${options[index]}的$label';
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

    return PopScope(
      canPop: false, // 禁止通过系统返回键/手势关闭
      child: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(), // 点击空白处收起键盘，而不是关闭页面
        behavior: HitTestBehavior.opaque,
        child: Stack(
          children: [
            // 1. 顶部标题与日期
            Positioned(
              top: screenHeight * 0.04,
              left: 0,
              right: 0,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  const Text(
                    '记下这一刻的心情',
                    style: TextStyle(
                      fontFamily: 'FZKai',
                      fontSize: 26,
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
                  const SizedBox(width: 12),
                  Text(
                    _getFormattedDate(),
                    style: TextStyle(
                      fontFamily: 'FZKai',
                      fontSize: 16,
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
                padding: EdgeInsets.only(top: screenHeight * 0.11, bottom: 0),
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
                            // 信纸容器（高度随键盘/表情面板动态变化）
                            Builder(
                              builder: (context) {
                                final viewInsets = MediaQuery.of(
                                  context,
                                ).viewInsets;

                                // 持续捕捉真实的键盘高度
                                if (viewInsets.bottom > 200) {
                                  _keyboardHeight = viewInsets.bottom;
                                }

                                // 无缝切换核心：取键盘高度和表情面板高度的最大值作为占位底座
                                final double bottomOffset = math.max(
                                  viewInsets.bottom,
                                  _isEmojiOpen ? _keyboardHeight : 0,
                                );

                                final double baseHeight = screenHeight * 0.85;
                                // 计算从信纸顶部到工具栏顶部的垂直距离
                                final double availableHeight =
                                    screenHeight -
                                    (screenHeight * 0.11) -
                                    bottomOffset -
                                    74; // 减小底部间隙，让信纸更长
                                final double dynamicHeight =
                                    availableHeight < baseHeight
                                    ? availableHeight
                                    : baseHeight;

                                return AnimatedContainer(
                                  duration: const Duration(milliseconds: 250),
                                  curve: Curves.easeOutCubic,
                                  onEnd: _ensureCursorVisible, // 切换完成时滚动以纠正光标位置
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
                                          32, // 恢复标准边距，因为高度已自动避让工具栏
                                        ),
                                        child: Column(
                                          children: [
                                            Expanded(
                                              child: TextField(
                                                controller: _controller,
                                                scrollController:
                                                    _scrollController,
                                                focusNode: _focusNode,
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
                                                decoration:
                                                    const InputDecoration(
                                                      hintText: '记录下这一刻的想法吧...',
                                                      hintStyle: TextStyle(
                                                        fontFamily: 'FZKai',
                                                        color: Color(
                                                          0xFFA68A78,
                                                        ),
                                                      ),
                                                      border: InputBorder.none,
                                                    ),
                                              ),
                                            ),
                                            // 操作按钮区：返回 & 保存
                                            Padding(
                                              padding: const EdgeInsets.only(
                                                top: 0,
                                              ),
                                              child: Row(
                                                mainAxisAlignment:
                                                    MainAxisAlignment
                                                        .spaceBetween,
                                                children: [
                                                  TextButton(
                                                    onPressed: () =>
                                                        Navigator.of(
                                                          context,
                                                        ).pop(),
                                                    child: const Text(
                                                      '返回',
                                                      style: TextStyle(
                                                        fontFamily: 'FZKai',
                                                        fontSize: 18,
                                                        color: Color(
                                                          0xFFA68A78,
                                                        ),
                                                      ),
                                                    ),
                                                  ),
                                                  TextButton(
                                                    onPressed: _onSave,
                                                    child: const Text(
                                                      '保存',
                                                      style: TextStyle(
                                                        fontFamily: 'FZKai',
                                                        fontSize: 18,
                                                        fontWeight:
                                                            FontWeight.bold,
                                                        color: Color(
                                                          0xFF8B5E3C,
                                                        ),
                                                      ),
                                                    ),
                                                  ),
                                                ],
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
                              top: -18,
                              child: MoodTag(
                                iconPath:
                                    mood.iconPath ??
                                    'assets/images/icons/sun.png',
                                description: _getPersonifiedMoodDescription(
                                  mood.label,
                                  widget.intensity,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            // 3. 稳健定位：底部抽屉式工具栏与面板组
            Builder(
              builder: (context) {
                final viewInsets = MediaQuery.of(context).viewInsets;

                // 核心高度捕捉逻辑：仅在键盘完全弹起（非缩回动画中）时记忆高度
                if (viewInsets.bottom > 200) {
                  _keyboardHeight = viewInsets.bottom;
                }

                // 取键盘高度和表情面板高度的最大值作为占位底座
                final double currentBottomAreaHeight = math.max(
                  viewInsets.bottom,
                  _isEmojiOpen ? _keyboardHeight : 0,
                );

                return Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      DiaryToolbar(
                        isEmojiOpen: _isEmojiOpen,
                        onEmojiToggle: _toggleEmoji,
                      ),
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 250),
                        curve: Curves.easeOutCubic,
                        height: currentBottomAreaHeight,
                        color: const Color(
                          0xFFF9EED8,
                        ).withOpacity(0.95), // 面板背景色
                        child: _isEmojiOpen
                            ? EmojiPanel(onEmojiSelected: _onEmojiSelected)
                            : const SizedBox.shrink(),
                      ),
                    ],
                  ).animate().fadeIn(duration: 300.ms),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
