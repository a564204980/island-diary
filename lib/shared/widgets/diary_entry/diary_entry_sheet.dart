import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:island_diary/shared/widgets/mood_picker/config/mood_config.dart';
import 'package:island_diary/core/state/user_state.dart';
import 'dart:ui';
import 'dart:math' as math;
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:permission_handler/permission_handler.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'components/mood_tag.dart';
import 'components/diary_toolbar.dart';
import 'components/emoji_panel.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

/// ---------------------------------------------------------------------------
/// 分块编辑器模型定义
/// ---------------------------------------------------------------------------
abstract class DiaryBlock {}

class TextBlock extends DiaryBlock {
  final TextEditingController controller;
  final FocusNode focusNode;
  TextBlock(String text)
    : controller = TextEditingController(text: text),
      focusNode = FocusNode();

  void dispose() {
    controller.dispose();
    focusNode.dispose();
  }
}

class ImageBlock extends DiaryBlock {
  final XFile file;
  final String id;
  ImageBlock(this.file) : id = DateTime.now().millisecondsSinceEpoch.toString();
}

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
  final ScrollController _scrollController = ScrollController();
  bool _isEmojiOpen = false;
  double _keyboardHeight = 330.0; // 逻辑像素单位

  // 语音识别相关
  final stt.SpeechToText _speech = stt.SpeechToText();
  bool _isRecording = false;

  // 图片与分块编辑相关
  final ImagePicker _picker = ImagePicker();
  final List<DiaryBlock> _blocks = [];
  int _activeBlockIndex = 0; // 当前获取焦点的文本块索引

  @override
  void initState() {
    super.initState();
    final draft = UserState().diaryDraft.value;

    if (draft != null && draft.blocks != null && draft.blocks!.isNotEmpty) {
      // 1. 从结构化草稿恢复
      for (var blockData in draft.blocks!) {
        if (blockData['type'] == 'text') {
          final block = TextBlock(blockData['content'] ?? '');
          _blocks.add(block);
          _setupTextBlockListeners(block);
        } else if (blockData['type'] == 'image') {
          _blocks.add(ImageBlock(XFile(blockData['path'] ?? '')));
        }
      }
    } else {
      // 2. 默认初始化首个文本块
      final initialText = draft?.content ?? '';
      final firstBlock = TextBlock(initialText);
      _blocks.add(firstBlock);
      _setupTextBlockListeners(firstBlock);
    }
  }

  void _setupTextBlockListeners(TextBlock block) {
    // 监听内容变化以更新草稿
    block.controller.addListener(_onBlocksChanged);

    // 监听焦点以追踪当前活跃块索引
    block.focusNode.addListener(() {
      if (block.focusNode.hasFocus) {
        setState(() {
          _activeBlockIndex = _blocks.indexOf(block);
          // 聚焦时如果表情面板开着，自动关闭（键盘弹出）
          if (_isEmojiOpen) _isEmojiOpen = false;
        });
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    for (var block in _blocks) {
      if (block is TextBlock) {
        block.dispose();
      }
    }
    super.dispose();
  }

  // --- 辅助方法：获取当前活跃的文本块 ---
  TextBlock? get _activeTextBlock {
    if (_activeBlockIndex >= 0 && _activeBlockIndex < _blocks.length) {
      final block = _blocks[_activeBlockIndex];
      if (block is TextBlock) return block;
    }
    // 降级处理：寻找列表中第一个文本块
    for (var block in _blocks) {
      if (block is TextBlock) return block;
    }
    return null;
  }

  void _onBlocksChanged() {
    // 1. 聚合文本内容
    final fullText = _blocks
        .whereType<TextBlock>()
        .map((b) => b.controller.text)
        .join('\n');

    // 2. 序列化全量分块数据
    final List<Map<String, dynamic>> blocksData = _blocks.map((block) {
      if (block is TextBlock) {
        return {'type': 'text', 'content': block.controller.text};
      } else if (block is ImageBlock) {
        return {'type': 'image', 'path': block.file.path};
      }
      return <String, dynamic>{};
    }).toList();

    // 3. 保存到持久化状态
    UserState().saveDraft(
      moodIndex: widget.moodIndex,
      intensity: widget.intensity,
      content: fullText,
      blocks: blocksData,
    );
    _ensureCursorVisible();
  }

  void _ensureCursorVisible() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) return;

      final activeBlock = _activeTextBlock;
      if (activeBlock == null) return;

      final context = activeBlock.focusNode.context;
      if (context == null) return;

      final RenderBox? box = context.findRenderObject() as RenderBox?;
      if (box == null || !box.hasSize) return;

      // 1. 获取当前块相对于视口顶部的物理偏移 (BlockTopInViewportY)
      final ScrollableState? scrollable = Scrollable.of(context);
      if (scrollable == null) return;
      final RenderBox viewport =
          scrollable.context.findRenderObject() as RenderBox;
      final Offset blockOffsetInViewport = box.localToGlobal(
        Offset.zero,
        ancestor: viewport,
      );

      // 2. 计算光标相对于该块顶部的偏移 (InternalCursorY)
      final _controller = activeBlock.controller;
      final selection = _controller.selection;
      if (!selection.isValid) return;

      final double screenWidth = MediaQuery.of(this.context).size.width;
      final double textFieldWidth = math.min(600, screenWidth) - 64;

      final textPainter = TextPainter(
        text: TextSpan(
          text: _controller.text.substring(0, selection.extentOffset),
          style: const TextStyle(
            fontFamily: 'FZKai',
            fontSize: 20,
            height: 1.6,
          ),
        ),
        textDirection: TextDirection.ltr,
        textAlign: TextAlign.left,
      );
      textPainter.layout(maxWidth: textFieldWidth);
      final double internalCursorY = textPainter.height;

      // 3. 计算光标相对于视口顶部的绝对坐标
      final double cursorInViewportY =
          blockOffsetInViewport.dy + internalCursorY;
      final double viewportHeight =
          _scrollController.position.viewportDimension;

      // 4. 稳健的滚动校准逻辑
      if (cursorInViewportY > viewportHeight - 60) {
        // 下方遮挡：向下滚动差值
        final double delta = cursorInViewportY - (viewportHeight - 100);
        _scrollController.animateTo(
          (_scrollController.offset + delta).clamp(
            0.0,
            _scrollController.position.maxScrollExtent,
          ),
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOutCubic,
        );
      } else if (cursorInViewportY < 40) {
        // 上方遮挡：向上滚动插值
        final double delta = cursorInViewportY - 60; // 负值
        _scrollController.animateTo(
          (_scrollController.offset + delta).clamp(
            0.0,
            _scrollController.position.maxScrollExtent,
          ),
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOutCubic,
        );
      }
    });
  }

  void _toggleRecord() async {
    final activeBlock = _activeTextBlock;
    if (activeBlock == null) return;
    final _controller = activeBlock.controller;

    print('STT: 开始/停止语音识别请求...');
    if (!_isRecording) {
      // 1. 显式请求权限
      var status = await Permission.microphone.request();
      print('STT: 麦克风权限状态: $status');

      if (status != PermissionStatus.granted) {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('请开启麦克风权限以使用语音功能')));
        }
        return;
      }

      // 2. 初始化引擎
      print('STT: 正在尝试初始化语音引擎...');
      try {
        bool available = await _speech.initialize(
          onStatus: (status) {
            print('STT 状态回调: $status');
            if (status == 'done' || status == 'notListening') {
              if (mounted) setState(() => _isRecording = false);
            }
          },
          onError: (error) {
            print('STT 错误回调: ${error.errorMsg}');
            if (mounted) {
              setState(() => _isRecording = false);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('语音功能提示: ${error.errorMsg}')),
              );
            }
          },
        );

        print('STT: 引擎是否可用: $available');

        if (available) {
          if (mounted) setState(() => _isRecording = true);
          _speech.listen(
            onResult: (result) {
              print(
                'STT 识别结果: ${result.recognizedWords}, 是否最终结果: ${result.finalResult}',
              );
              if (mounted) {
                setState(() {
                  if (result.finalResult) {
                    final String recognized = result.recognizedWords;
                    if (recognized.isNotEmpty) {
                      final int cursorPosition =
                          _controller.selection.baseOffset;
                      final String originalText = _controller.text;

                      if (cursorPosition >= 0) {
                        final String prefix = originalText.substring(
                          0,
                          cursorPosition,
                        );
                        final String suffix = originalText.substring(
                          cursorPosition,
                        );
                        _controller.text = prefix + recognized + suffix;
                        _controller.selection = TextSelection.collapsed(
                          offset: cursorPosition + recognized.length,
                        );
                      } else {
                        _controller.text += recognized;
                        _controller.selection = TextSelection.collapsed(
                          offset: _controller.text.length,
                        );
                      }
                      _ensureCursorVisible();
                    }
                  }
                });
              }
            },
            localeId: 'zh_CN',
          );
        } else {
          print('STT: 初始化返回 false，可能模拟器不支持 Speech Services');
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('设备暂不支持语音识别（模拟器需安装语音引擎）')),
            );
          }
        }
      } catch (e) {
        print('STT: 初始化异常: $e');
      }
    } else {
      print('STT: 主动停止监听');
      if (mounted) setState(() => _isRecording = false);
      _speech.stop();
    }
  }

  void _toggleEmoji() {
    setState(() {
      _isEmojiOpen = !_isEmojiOpen;
    });

    if (_isEmojiOpen) {
      // 打开表情面板，收起键盘
      _activeTextBlock?.focusNode.unfocus();
    } else {
      // 打开键盘，收起表情面板
      _activeTextBlock?.focusNode.requestFocus();
    }
  }

  // --- 图片处理逻辑 ---

  void _onImageButtonPressed() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
        decoration: const BoxDecoration(
          color: Color(0xFFFDF7E9),
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(24),
            topRight: Radius.circular(24),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(
                Icons.photo_library,
                color: Color(0xFF8B5E3C),
              ),
              title: const Text(
                '从照片库选择',
                style: TextStyle(fontFamily: 'FZKai', fontSize: 18),
              ),
              onTap: () {
                Navigator.pop(context);
                _pickMultiImages();
              },
            ),
            const Divider(height: 1),
            ListTile(
              leading: const Icon(Icons.camera_alt, color: Color(0xFF8B5E3C)),
              title: const Text(
                '拍摄照片记录',
                style: TextStyle(fontFamily: 'FZKai', fontSize: 18),
              ),
              onTap: () {
                Navigator.pop(context);
                _pickCameraImage();
              },
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }

  Future<void> _pickMultiImages() async {
    final imageCount = _blocks.whereType<ImageBlock>().length;
    if (imageCount >= 9) {
      _showError('最多只能添加 9 张图片哦');
      return;
    }

    try {
      final List<XFile> pickedFiles = await _picker.pickMultiImage(
        imageQuality: 80,
        maxWidth: 1200,
      );

      if (pickedFiles.isNotEmpty) {
        for (var file in pickedFiles) {
          _splitAndInsertImage(file);
        }
      }
    } catch (e) {
      _showError('无法打开相册: $e');
    }
  }

  Future<void> _pickCameraImage() async {
    final imageCount = _blocks.whereType<ImageBlock>().length;
    if (imageCount >= 9) {
      _showError('最多只能添加 9 张图片哦');
      return;
    }

    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 80,
        maxWidth: 1200,
      );

      if (pickedFile != null) {
        _splitAndInsertImage(pickedFile);
      }
    } catch (e) {
      _showError('无法开启相机: $e');
    }
  }

  void _splitAndInsertImage(XFile image) {
    final activeBlock = _activeTextBlock;
    if (activeBlock == null) {
      setState(() {
        _blocks.add(ImageBlock(image));
        final nextText = TextBlock('');
        _blocks.add(nextText);
        _setupTextBlockListeners(nextText);
        _activeBlockIndex = _blocks.indexOf(nextText);
      });
      return;
    }

    final controller = activeBlock.controller;
    final selection = controller.selection;
    final text = controller.text;

    setState(() {
      final index = _blocks.indexOf(activeBlock);

      // 情况 1: 空行或者光标在段首 -> 图片插在当前文字块之前
      // 解决用户反馈的“第一行没写东西上传图片跑第二行”的问题
      if (text.isEmpty || (selection.isValid && selection.start == 0)) {
        _blocks.insert(index, ImageBlock(image));
        // activeBlock 此时自动变为 index + 1，光标和焦点逻辑自然顺延
        _activeBlockIndex = _blocks.indexOf(activeBlock);
      }
      // 情况 2: 光标在段末 -> 图片插在当前块之后，并补充一个后续空行
      else if (!selection.isValid || selection.start == text.length) {
        _blocks.insert(index + 1, ImageBlock(image));
        final nextText = TextBlock('');
        _blocks.insert(index + 2, nextText);
        _setupTextBlockListeners(nextText);
        _activeBlockIndex = index + 2;
      }
      // 情况 3: 段中切分 -> 将当前块一分为二，图片嵌在中间
      else {
        final beforeText = text.substring(0, selection.start);
        final afterText = text.substring(selection.end);

        activeBlock.controller.text = beforeText;
        _blocks.insert(index + 1, ImageBlock(image));
        final nextText = TextBlock(afterText);
        // 显式重置光标至起始，防止跳转末尾
        nextText.controller.selection = const TextSelection.collapsed(
          offset: 0,
        );
        _blocks.insert(index + 2, nextText);
        _setupTextBlockListeners(nextText);
        _activeBlockIndex = index + 2;
      }
    });

    _onBlocksChanged(); // 插入图片后主动保存

    // 自动聚焦新产生的输入区
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_activeBlockIndex >= 0 && _activeBlockIndex < _blocks.length) {
        final targetBlock = _blocks[_activeBlockIndex];
        if (targetBlock is TextBlock) {
          targetBlock.focusNode.requestFocus();
        }
      }
    });
  }

  void _removeImage(int index) {
    setState(() {
      _blocks.removeAt(index);
      // TODO: 可选：合并相邻文本块
    });
    _onBlocksChanged(); // 删除图片后主动保存
  }

  void _showImagePreview(ImageBlock block) {
    Navigator.of(context).push(
      PageRouteBuilder(
        opaque: false,
        barrierDismissible: true,
        pageBuilder: (context, _, __) => Scaffold(
          backgroundColor: Colors.black.withOpacity(0.9),
          body: GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Center(
              child: Hero(
                tag: block.id,
                child: kIsWeb
                    ? Image.network(block.file.path, fit: BoxFit.contain)
                    : Image.file(File(block.file.path), fit: BoxFit.contain),
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _showError(String message) {
    if (mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message)));
    }
  }

  void _onEmojiSelected(String emoji) {
    final activeBlock = _activeTextBlock;
    if (activeBlock == null) return;

    final controller = activeBlock.controller;
    final text = controller.text;
    final selection = controller.selection;
    final newText = text.replaceRange(selection.start, selection.end, emoji);

    controller.value = controller.value.copyWith(
      text: newText,
      selection: TextSelection.collapsed(
        offset: selection.start + emoji.length,
      ),
    );
    _ensureCursorVisible();
  }

  String _getFormattedDate() {
    final now = DateTime.now();
    return '${now.year}年${now.month}月${now.day}日';
  }

  /// 拟人化强度描述文案映射
  String _getPersonifiedMoodDescription(String label, double intensity) {
    const Map<String, List<String>> moodPrefixes = {
      '期待': ['略带憧憬', '满心向往', '迫不及待'],
      '厌恶': ['有些反感', '深感蹙眉', '嫌弃至极'],
      '恐惧': ['隐约不安', '忐忑紧锁', '灵魂颤栗'],
      '惊喜': ['意料之外', '万分激动', '喜从天降'],
      '平静': ['凡事从容', '岁月安好', '万籁寂静'],
      '愤怒': ['隐隐不快', '火冒三丈', '怒气冲天'],
      '悲伤': ['隐隐哀愁', '满怀感伤', '痛彻心扉'],
      '开心': ['眉开眼笑', '神采飞扬', '狂喜雀跃'],
    };

    final int level = (intensity * 10).toInt();
    final List<String>? options = moodPrefixes[label];
    if (options == null) return label;
    final int index = level <= 3 ? 0 : (level <= 7 ? 1 : 2);
    return "${options[index]}的$label/${(intensity).toInt()}";
  }

  void _onSave() {
    final fullText = _blocks
        .whereType<TextBlock>()
        .map((b) => b.controller.text)
        .join('\n');
    debugPrint('Saving content: $fullText');
    UserState().clearDraft();
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
        onTap: () => FocusScope.of(context).unfocus(), // 点击空白处收起键盘
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
                                final double availableHeight =
                                    screenHeight -
                                    (screenHeight * 0.11) -
                                    bottomOffset -
                                    74;
                                final double dynamicHeight =
                                    availableHeight < baseHeight
                                    ? availableHeight
                                    : baseHeight;

                                return AnimatedContainer(
                                  duration: const Duration(milliseconds: 250),
                                  curve: Curves.easeOutCubic,
                                  onEnd: _ensureCursorVisible,
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
                                          40,
                                          32,
                                          32,
                                        ),
                                        child: Column(
                                          children: [
                                            Expanded(
                                              child: ListView.builder(
                                                controller: _scrollController,
                                                padding: EdgeInsets.zero,
                                                itemCount: _blocks.length,
                                                itemBuilder: (context, index) {
                                                  final block = _blocks[index];
                                                  if (block is TextBlock) {
                                                    return TextField(
                                                      controller:
                                                          block.controller,
                                                      focusNode:
                                                          block.focusNode,
                                                      maxLines: null,
                                                      cursorColor: const Color(
                                                        0xFF8B5E3C,
                                                      ),
                                                      style: const TextStyle(
                                                        fontFamily: 'FZKai',
                                                        fontSize: 20,
                                                        color: Color(
                                                          0xFF5D4037,
                                                        ),
                                                        height: 1.6,
                                                      ),
                                                      decoration: InputDecoration(
                                                        hintText: index == 0
                                                            ? '记录下这一刻的想法吧...'
                                                            : '',
                                                        hintStyle:
                                                            const TextStyle(
                                                              fontFamily:
                                                                  'FZKai',
                                                              color: Color(
                                                                0xFFA68A78,
                                                              ),
                                                            ),
                                                        border:
                                                            InputBorder.none,
                                                        isDense: true,
                                                        contentPadding:
                                                            const EdgeInsets.symmetric(
                                                              vertical: 4,
                                                            ),
                                                      ),
                                                    );
                                                  } else if (block
                                                      is ImageBlock) {
                                                    return Container(
                                                      margin:
                                                          const EdgeInsets.symmetric(
                                                            vertical: 12,
                                                          ),
                                                      constraints: BoxConstraints(
                                                        maxHeight:
                                                            MediaQuery.of(
                                                                  context,
                                                                ).size.width <
                                                                600
                                                            ? 200
                                                            : 300,
                                                      ),
                                                      width: double.infinity,
                                                      child: Stack(
                                                        children: [
                                                          GestureDetector(
                                                            onTap: () =>
                                                                _showImagePreview(
                                                                  block,
                                                                ),
                                                            child: Hero(
                                                              tag: block.id,
                                                              child: ClipRRect(
                                                                borderRadius:
                                                                    BorderRadius.circular(
                                                                      12,
                                                                    ),
                                                                child: kIsWeb
                                                                    ? Image.network(
                                                                        block
                                                                            .file
                                                                            .path,
                                                                        fit: BoxFit
                                                                            .contain,
                                                                        width: double
                                                                            .infinity,
                                                                        height:
                                                                            double.infinity,
                                                                      )
                                                                    : Image.file(
                                                                        File(
                                                                          block
                                                                              .file
                                                                              .path,
                                                                        ),
                                                                        fit: BoxFit
                                                                            .contain,
                                                                        width: double
                                                                            .infinity,
                                                                        height:
                                                                            double.infinity,
                                                                      ),
                                                              ),
                                                            ),
                                                          ),
                                                          Positioned(
                                                            top: 8,
                                                            right: 8,
                                                            child: GestureDetector(
                                                              onTap: () =>
                                                                  _removeImage(
                                                                    index,
                                                                  ),
                                                              child: Container(
                                                                padding:
                                                                    const EdgeInsets.all(
                                                                      4,
                                                                    ),
                                                                decoration: const BoxDecoration(
                                                                  color: Colors
                                                                      .black54,
                                                                  shape: BoxShape
                                                                      .circle,
                                                                ),
                                                                child: const Icon(
                                                                  Icons.close,
                                                                  size: 18,
                                                                  color: Colors
                                                                      .white,
                                                                ),
                                                              ),
                                                            ),
                                                          ),
                                                        ],
                                                      ),
                                                    ).animate().scale(
                                                      duration: 200.ms,
                                                    );
                                                  }
                                                  return const SizedBox.shrink();
                                                },
                                              ),
                                            ),
                                            // 操作按钮区：返回 & 保存
                                            Padding(
                                              padding: const EdgeInsets.only(
                                                top: 8,
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
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Builder(
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

                  return Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      DiaryToolbar(
                        isEmojiOpen: _isEmojiOpen,
                        isRecording: _isRecording,
                        onEmojiToggle: _toggleEmoji,
                        onRecordToggle: _toggleRecord,
                        onImagePick: _onImageButtonPressed,
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
                  ).animate().fadeIn(duration: 300.ms);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
