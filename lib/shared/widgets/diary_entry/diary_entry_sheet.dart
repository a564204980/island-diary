import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:island_diary/shared/widgets/mood_picker/config/mood_config.dart';
import 'package:island_diary/core/state/user_state.dart';
import 'dart:ui';
import 'dart:math' as math;

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
                            // 信纸容器（高度随键盘动态变化）
                            Builder(
                              builder: (context) {
                                final viewInsets = MediaQuery.of(
                                  context,
                                ).viewInsets;
                                final double baseHeight = screenHeight * 0.85;
                                // 计算从信纸顶部到工具栏顶部的垂直距离，确保信纸底边刚好贴合工具栏
                                final double availableHeight =
                                    screenHeight -
                                    (screenHeight * 0.11) -
                                    viewInsets.bottom -
                                    70; // 留一点呼吸间隙
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
                                          32, // 恢复标准边距，因为高度已自动避让工具栏
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
                              top: -18, // 稍微移下来一点
                              child:
                                  CustomPaint(
                                        painter: HandDrawnTagPainter(
                                          color: const Color.fromRGBO(
                                            249,
                                            238,
                                            216,
                                            0.75,
                                          ).withOpacity(0.95),
                                          borderColor: const Color(
                                            0xFF8B5E3C,
                                          ).withOpacity(0.4),
                                        ),
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 20,
                                            vertical: 10,
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
                                                _getPersonifiedMoodDescription(
                                                  mood.label,
                                                  widget.intensity,
                                                ),
                                                style: const TextStyle(
                                                  fontFamily: 'FZKai',
                                                  color: Color(0xFF5D4037),
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 16,
                                                ),
                                              ),
                                            ],
                                          ),
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
            // 3. 动态吸附工具栏
            Builder(
              builder: (context) {
                final viewInsets = MediaQuery.of(context).viewInsets;
                final double rowWidth =
                    MediaQuery.of(context).size.width - 16; // 减去水平 Padding

                return Positioned(
                  bottom: viewInsets.bottom,
                  left: 0,
                  right: 0,
                  child: Container(
                    height: 110,
                    width: double.infinity,
                    child: Stack(
                      children: [
                        // 背景 - 磨砂玻璃 + 手绘线条
                        Positioned.fill(
                          child: ClipRect(
                            child: BackdropFilter(
                              filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
                              child: CustomPaint(
                                painter: HandDrawnToolbarPainter(
                                  color: const Color(
                                    0xFFF9EED8,
                                  ).withOpacity(0.85),
                                  borderColor: const Color(0xFF8B5E3C),
                                ),
                              ),
                            ),
                          ),
                        ),
                        // 双行图标列表
                        Padding(
                          padding: const EdgeInsets.symmetric(
                            vertical: 12,
                            horizontal: 8,
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: _buildDualRowToolbarIcons(rowWidth),
                          ),
                        ),
                      ],
                    ),
                  ),
                ).animate().fadeIn(duration: 300.ms);
              },
            ),
          ],
        ),
      ),
    );
  }

  /// 构建双行工具栏图标组
  List<Widget> _buildDualRowToolbarIcons(double rowWidth) {
    final List<String> iconPaths = [
      'assets/images/icons/emoji_icon.png',
      'assets/images/icons/record_icon.png',
      'assets/images/icons/photo_icon.png',
      'assets/images/icons/topic_icon.png',
      'assets/images/icons/pencil_icon.png',
      'assets/images/icons/calligraphy_icon.png',
      'assets/images/icons/time_icon.png',
      'assets/images/icons/address_icon.png',
      'assets/images/icons/music_icon.png',
      'assets/images/icons/link_icon.png',
      'assets/images/icons/fontSize_icon.png',
      'assets/images/icons/utils_icons.png',
    ];

    // 每个图标单元格的宽度，确保垂直对齐
    final double itemWidth = rowWidth / 6;

    // 将 12 个图标分为两行，每行 6 个
    final row1 = iconPaths.sublist(0, 6);
    final row2 = iconPaths.sublist(6, 12);

    return [
      Row(
        mainAxisAlignment: MainAxisAlignment.start,
        children: row1
            .map((path) => _buildToolbarItem(path, itemWidth))
            .toList(),
      ),
      Row(
        mainAxisAlignment: MainAxisAlignment.start,
        children: row2
            .map((path) => _buildToolbarItem(path, itemWidth))
            .toList(),
      ),
    ];
  }

  Widget _buildToolbarItem(String assetPath, double width) {
    return SizedBox(
      width: width,
      child: Center(
        child: InkWell(
          onTap: () {
            // TODO: 具体功能逻辑
          },
          child: Image.asset(
            assetPath,
            width: 34,
            height: 34,
            fit: BoxFit.contain,
          ),
        ),
      ),
    );
  }
}

/// 精细化手绘风格标签背景绘制器（支持外发光与水彩“花色”背景）
class HandDrawnTagPainter extends CustomPainter {
  final Color color;
  final Color borderColor;

  HandDrawnTagPainter({required this.color, required this.borderColor});

  @override
  void paint(Canvas canvas, Size size) {
    final path = _createOrganicPath(size);

    // 1. 绘制复合外发光 (Glow Effect)
    _drawOuterGlow(canvas, path);

    // 2. 绘制基础背景
    final basePaint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;
    canvas.drawPath(path, basePaint);

    // 3. 绘制“花色”水彩纹理
    _drawWatercolorTexture(canvas, size, path);

    // 4. 绘制主边框线条（圆润写意）
    final borderPaint = Paint()
      ..color = borderColor.withOpacity(0.35)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    canvas.drawPath(path, borderPaint);

    // 5. 断续草稿复笔
    final extraPath = _createOrganicPath(size, offset: 0.8);
    canvas.drawPath(
      extraPath,
      borderPaint
        ..strokeWidth = 0.4
        ..color = borderColor.withOpacity(0.12),
    );
  }

  /// 绘制多层复合外发光（白色柔光 + 核心阴影）
  void _drawOuterGlow(Canvas canvas, Path path) {
    // 基础柔和投影
    canvas.drawShadow(
      path.shift(const Offset(0, 1)),
      Colors.black.withOpacity(0.1),
      4.0,
      true,
    );

    // 白色外发光扩散感
    final glowPaint = Paint()
      ..color = Colors.white.withOpacity(0.7)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4.0
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5.0);
    canvas.drawPath(path, glowPaint);
  }

  /// 绘制模拟水彩纸的“花色”纹理
  void _drawWatercolorTexture(Canvas canvas, Size size, Path clipPath) {
    canvas.save();
    canvas.clipPath(clipPath);

    final random = math.Random(12345); // 固定种子

    // A. 基础多色晕染（形成“花”的基调，参考图中的青、粉色调）
    final List<Map<String, dynamic>> blooms = [
      {
        'color': const Color(0xFFA2D2FF),
        'center': const Alignment(0.8, -0.6),
        'radius': 1.6,
      },
      {
        'color': const Color(0xFFFFC2D1),
        'center': const Alignment(-0.7, 0.4),
        'radius': 1.3,
      },
      {
        'color': const Color(0xFFD8F3DC),
        'center': const Alignment(0.5, 0.8),
        'radius': 1.0,
      },
      {
        'color': const Color(0xFFFFF7ED),
        'center': const Alignment(-0.9, -0.9),
        'radius': 1.2,
      },
    ];

    for (var bloom in blooms) {
      final paint = Paint()
        ..shader = RadialGradient(
          colors: [
            (bloom['color'] as Color).withOpacity(0.18),
            Colors.transparent,
          ],
          center: bloom['center'] as Alignment,
          radius: bloom['radius'] as double,
        ).createShader(Offset.zero & size);
      canvas.drawRect(Offset.zero & size, paint);
    }

    // B. 随机“花点”纹理（模拟水彩纸张的细节噪点）
    for (int i = 0; i < 25; i++) {
      final double x = random.nextDouble() * size.width;
      final double y = random.nextDouble() * size.height;
      final double dotRadius = random.nextDouble() * 3 + 1;

      final colorType = random.nextInt(3);
      Color dotColor;
      if (colorType == 0)
        dotColor = const Color(0xFFA2D2FF);
      else if (colorType == 1)
        dotColor = const Color(0xFFFFC2D1);
      else
        dotColor = const Color(0xFFE2B6FF);

      final dotPaint = Paint()
        ..color = dotColor.withOpacity(0.08)
        ..maskFilter = MaskFilter.blur(
          BlurStyle.normal,
          random.nextDouble() * 1.5 + 0.5,
        );

      canvas.drawCircle(Offset(x, y), dotRadius, dotPaint);
    }

    canvas.restore();
  }

  /// 创建一个具有圆润感和轻微波动的有机矩形路径
  Path _createOrganicPath(Size size, {double offset = 0}) {
    final path = Path();
    final double w = size.width;
    final double h = size.height;
    final double r = 16.0;

    path.moveTo(r + offset, offset);
    path.quadraticBezierTo(w / 2, -0.6 + offset, w - r - offset, offset + 0.3);
    path.quadraticBezierTo(
      w + 0.2 - offset,
      offset + 0.2,
      w - offset,
      r + offset,
    );
    path.quadraticBezierTo(w + 0.8 - offset, h / 2, w - offset, h - r - offset);
    path.quadraticBezierTo(
      w - 0.2 - offset,
      h + 0.4 - offset,
      w - r - offset,
      h - offset,
    );
    path.quadraticBezierTo(
      w / 2,
      h + 0.6 - offset,
      r + offset,
      h - offset + 0.2,
    );
    path.quadraticBezierTo(
      offset - 0.4,
      h + 0.2 - offset,
      offset,
      h - r - offset,
    );
    path.quadraticBezierTo(offset - 0.6, h / 2, offset + 0.2, r + offset);
    path.quadraticBezierTo(offset + 0.1, offset - 0.5, r + offset, offset);

    return path;
  }

  @override
  bool shouldRepaint(covariant HandDrawnTagPainter oldDelegate) =>
      oldDelegate.color != color || oldDelegate.borderColor != borderColor;
}

/// 手绘风格工具栏背景绘制器
class HandDrawnToolbarPainter extends CustomPainter {
  final Color color;
  final Color borderColor;

  HandDrawnToolbarPainter({required this.color, required this.borderColor});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    // 创建一个稍微带点波动的长条路径
    final path = Path();
    final w = size.width;
    final h = size.height;

    // 绘制稍微不规则的顶部边缘
    path.moveTo(0, 5);
    for (double i = 0; i <= w; i += 20) {
      path.lineTo(i, 2.0 + (i % 40 == 0 ? 3.0 : -1.0));
    }
    path.lineTo(w, 0);
    path.lineTo(w, h);
    path.lineTo(0, h);
    path.close();

    canvas.drawPath(path, paint);

    // 绘制顶部分隔细线，带点手绘感
    final linePaint = Paint()
      ..color = borderColor.withOpacity(0.2)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    final linePath = Path();
    linePath.moveTo(0, 5);
    for (double i = 0; i <= w; i += 30) {
      linePath.lineTo(i, 3.0 + (i % 60 == 0 ? 2.0 : -0.5));
    }
    canvas.drawPath(linePath, linePaint);
  }

  @override
  bool shouldRepaint(covariant HandDrawnToolbarPainter oldDelegate) =>
      oldDelegate.color != color || oldDelegate.borderColor != borderColor;
}
