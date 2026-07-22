import 'dart:io';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:island_diary/core/state/user_state.dart';
import 'package:island_diary/shared/animations/bouncing_button.dart';
import 'package:island_diary/shared/widgets/top_toast.dart';

/// 展板背景底纹枚举
enum WallTheme {
  dotGrid('🖊️ 手帐点阵', Colors.white, 'dot'),
  warmWood('🪵 温暖木纹', Color(0xFFF7F3E9), 'wood'),
  islandBlue('🌊 海岛水彩', Color(0xFFE0F2FE), 'blue'),
  darkPaper('🌙 暗夜深墨', Color(0xFF1E293B), 'dark');

  final String label;
  final Color bgColor;
  final String id;

  const WallTheme(this.label, this.bgColor, this.id);
}

enum WallLayoutMode {
  scatter('手帐散落'),
  treemap('无缝二叉树');

  final String label;
  const WallLayoutMode(this.label);
}

/// “岁月成书 · 情绪照片墙”全屏沉浸式手帐写真页面
class PhotoWallPage extends StatefulWidget {
  final bool isNight;
  final String themeId;

  const PhotoWallPage({
    super.key,
    required this.isNight,
    required this.themeId,
  });

  @override
  State<PhotoWallPage> createState() => _PhotoWallPageState();
}

class _PhotoWallPageState extends State<PhotoWallPage> {
  late WallTheme _currentTheme;
  WallLayoutMode _layoutMode = WallLayoutMode.scatter;
  final ImagePicker _picker = ImagePicker();
  final List<String> _userPhotos = [];
  int _randomSeed = 42;
  bool _isPureViewMode = false;

  // 预设海岛高颜值写真照片
  final List<String> _presetPhotos = const [
    'assets/images/home_card/me_day.jpg',
    'assets/images/home_card/me_night.jpg',
    'assets/images/theme/miamhuadao/miam1.jpg',
    'assets/images/theme/miamhuadao/miam2.jpg',
    'assets/images/theme/miamhuadao/miam3.jpg',
    'assets/images/theme/miamhuadao/miam4.jpg',
    'assets/images/theme/miamhuadao/miam5.jpg',
  ];

  @override
  void initState() {
    super.initState();
    _currentTheme = widget.isNight ? WallTheme.darkPaper : WallTheme.dotGrid;
    _loadUserPhotos();
  }

  void _loadUserPhotos() {
    _userPhotos.clear();
    // 从用户已保存的日记结构化分块中提取图片路径
    final savedDiaries = UserState().savedDiaries.value;
    for (var diary in savedDiaries) {
      for (var block in diary.blocks) {
        if (block['type'] == 'image' && block['path'] != null) {
          _userPhotos.add(block['path'].toString());
        }
      }
    }
    if (_userPhotos.isEmpty) {
      // 循环充填预设照片至 18 张展现手帐写真全景
      for (int i = 0; i < 18; i++) {
        _userPhotos.add(_presetPhotos[i % _presetPhotos.length]);
      }
    }
  }

  /// 拍照或从相册添加照片
  Future<void> _pickPhoto() async {
    try {
      final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
      if (image != null) {
        setState(() {
          _userPhotos.insert(0, image.path);
          _randomSeed += 1;
        });
        if (mounted) {
          showTopToast(context, '✨ 新照片已钉入手帐照片墙');
        }
      }
    } catch (e) {
      if (mounted) {
        showTopToast(context, '无法打开相册，请重试');
      }
    }
  }

  /// 切换背景衬底
  void _cycleTheme() {
    HapticFeedback.lightImpact();
    setState(() {
      final nextIndex = (_currentTheme.index + 1) % WallTheme.values.length;
      _currentTheme = WallTheme.values[nextIndex];
    });
    showTopToast(context, '🎨 已切换为：${_currentTheme.label}');
  }

  /// 随机重排散落姿态
  void _randomizeScatter() {
    HapticFeedback.mediumImpact();
    setState(() {
      _randomSeed = math.Random().nextInt(10000);
    });
    showTopToast(context, '🎲 已重排手帐拍立得姿态');
  }

  /// 放大预览单张拍立得
  void _previewPhoto(String path, int index) {
    HapticFeedback.lightImpact();
    showDialog(
      context: context,
      barrierDismissible: true,
      barrierColor: Colors.black87,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: const [
                  BoxShadow(
                    color: Colors.black38,
                    blurRadius: 24,
                    offset: Offset(0, 10),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: _buildPhotoWidget(path, index, height: 360),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "时光碎片 #${index + 1}",
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF334155),
                        ),
                      ),
                      Text(
                        "海岛记忆 · 珍藏",
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            BouncingButton(
              onTap: () => Navigator.of(context).pop(),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.white30),
                ),
                child: const Text(
                  "关闭预览",
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 智能加载图片 (支持 Asset、本地 File 文件与多重精美兜底)
  Widget _buildPhotoWidget(String path, int index, {double? height}) {
    if (path.startsWith('assets/')) {
      return Image.asset(
        path,
        fit: BoxFit.cover,
        height: height,
        width: double.infinity,
        errorBuilder: (context, error, stackTrace) => Image.asset(
          _presetPhotos[index % _presetPhotos.length],
          fit: BoxFit.cover,
          height: height,
          width: double.infinity,
        ),
      );
    }
    
    final file = File(path);
    if (file.existsSync()) {
      return Image.file(
        file,
        fit: BoxFit.cover,
        height: height,
        width: double.infinity,
        errorBuilder: (context, error, stackTrace) => Image.asset(
          _presetPhotos[index % _presetPhotos.length],
          fit: BoxFit.cover,
          height: height,
          width: double.infinity,
        ),
      );
    }

    // 默认兜底使用预设写真照片
    return Image.asset(
      _presetPhotos[index % _presetPhotos.length],
      fit: BoxFit.cover,
      height: height,
      width: double.infinity,
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool isDark = (_currentTheme == WallTheme.darkPaper);
    final Color textColor = isDark ? Colors.white : const Color(0xFF1E293B);

    return Scaffold(
      backgroundColor: _currentTheme.bgColor,
      body: Stack(
        children: [
          // 1. 手帐点阵/木纹底纹绘图层
          Positioned.fill(
            child: CustomPaint(
              painter: _WallBackgroundPainter(theme: _currentTheme),
            ),
          ),

          // 2. 主画幅拍立得手帐展板
          Positioned.fill(
            child: SafeArea(
              child: Column(
                children: [
                  // 顶部 AppBar
                  AnimatedOpacity(
                    opacity: _isPureViewMode ? 0.0 : 1.0,
                    duration: const Duration(milliseconds: 260),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      child: Row(
                        children: [
                          BouncingButton(
                            onTap: () => Navigator.of(context).pop(),
                            child: Container(
                              padding: const EdgeInsets.all(9),
                              decoration: BoxDecoration(
                                color: isDark
                                    ? Colors.white.withValues(alpha: 0.12)
                                    : Colors.white.withValues(alpha: 0.7),
                                shape: BoxShape.circle,
                                boxShadow: const [
                                  BoxShadow(
                                    color: Colors.black12,
                                    blurRadius: 8,
                                    offset: Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Icon(
                                Icons.arrow_back_ios_new_rounded,
                                size: 18,
                                color: textColor,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "岁月成书 · 照片墙",
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: textColor,
                                  letterSpacing: 0.5,
                                ),
                              ),
                              Text(
                                "共 ${_userPhotos.length} 张珍藏时光碎片",
                                style: TextStyle(
                                  fontSize: 11,
                                  color: textColor.withValues(alpha: 0.6),
                                ),
                              ),
                            ],
                          ),
                          const Spacer(),
                          BouncingButton(
                            onTap: _cycleTheme,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: isDark
                                    ? Colors.white.withValues(alpha: 0.15)
                                    : Colors.white.withValues(alpha: 0.8),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: isDark
                                      ? Colors.white24
                                      : Colors.white,
                                ),
                              ),
                              child: Text(
                                _currentTheme.label,
                                style: TextStyle(
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w600,
                                  color: textColor,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // 中央手帐画布区 (可上下流畅滚动)
                  Expanded(
                    child: GestureDetector(
                      onTap: () {
                        if (_isPureViewMode) {
                          setState(() => _isPureViewMode = false);
                        }
                      },
                      child: LayoutBuilder(
                        builder: (context, constraints) {
                          final double canvasWidth = constraints.maxWidth;
                          final double viewportHeight = constraints.maxHeight;

                          if (_layoutMode == WallLayoutMode.treemap) {
                            // 二叉切分无缝拼图模式 (Guillotine Treemap Split)
                            final int count = _userPhotos.length;
                            final int rows = (count / 3).ceil();
                            final double computedCanvasHeight = math.max(viewportHeight, rows * 160.0 + 120.0);

                            final bounds = Rect.fromLTWH(12, 12, canvasWidth - 24, computedCanvasHeight - 120.0);
                            final indices = List.generate(count, (i) => i);
                            final leaves = _TreemapSplitter.computeLeaves(bounds, indices, _randomSeed);

                            return SingleChildScrollView(
                              physics: const BouncingScrollPhysics(),
                              child: SizedBox(
                                height: computedCanvasHeight,
                                width: canvasWidth,
                                child: Stack(
                                  clipBehavior: Clip.none,
                                  children: leaves.map((leaf) {
                                    final path = _userPhotos[leaf.index];
                                    const double gap = 4.0; // 4px 呼吸感离缝
                                    final Rect cardRect = leaf.rect.deflate(gap);

                                    return Positioned(
                                      left: cardRect.left,
                                      top: cardRect.top,
                                      width: cardRect.width,
                                      height: cardRect.height,
                                      child: BouncingButton(
                                        onTap: () => _previewPhoto(path, leaf.index),
                                        scaleFactor: 0.96,
                                        child: Container(
                                          decoration: BoxDecoration(
                                            color: Colors.white,
                                            borderRadius: BorderRadius.circular(10),
                                            boxShadow: [
                                              BoxShadow(
                                                color: Colors.black.withValues(alpha: isDark ? 0.4 : 0.16),
                                                blurRadius: 10,
                                                offset: const Offset(0, 4),
                                              ),
                                            ],
                                          ),
                                          padding: const EdgeInsets.all(4),
                                          child: ClipRRect(
                                            borderRadius: BorderRadius.circular(7),
                                            child: _buildPhotoWidget(path, leaf.index),
                                          ),
                                        ),
                                      ),
                                    );
                                  }).toList(),
                                ),
                              ),
                            );
                          } else {
                            // 散落手帐模式 (Honeycomb Scatter)
                            const double cardW = 92.0;
                            const double cardH = 120.0;
                            const int cols = 3;
                            final int totalRows = (_userPhotos.length + cols - 1) ~/ cols;
                            
                            final double computedCanvasHeight = math.max(viewportHeight, totalRows * 135.0 + 140.0);
                            final double rowStep = (computedCanvasHeight - cardH - 140.0) / (totalRows > 1 ? totalRows - 1 : 1);
                            final double colStep = (canvasWidth - cardW - 32) / (cols - 1);

                            return SingleChildScrollView(
                              physics: const BouncingScrollPhysics(),
                              child: SizedBox(
                                height: computedCanvasHeight,
                                width: canvasWidth,
                                child: Stack(
                                  clipBehavior: Clip.none,
                                  children: [
                                    ...List.generate(_userPhotos.length, (index) {
                                      final path = _userPhotos[index];
                                      final rand = math.Random(_randomSeed + index * 17);

                                      final int row = index ~/ cols;
                                      final int col = index % cols;

                                      final double jitterX = (rand.nextDouble() - 0.5) * 22.0;
                                      final double jitterY = (rand.nextDouble() - 0.5) * 18.0;

                                      final double left = (16.0 + col * colStep + jitterX).clamp(10.0, canvasWidth - cardW - 10);
                                      final double top = (12.0 + row * rowStep + jitterY).clamp(10.0, computedCanvasHeight - cardH - 140);

                                      final double angle = (rand.nextDouble() - 0.5) * 0.35;

                                      return Positioned(
                                        left: left,
                                        top: top,
                                        child: Transform.rotate(
                                          angle: angle,
                                          child: BouncingButton(
                                            onTap: () => _previewPhoto(path, index),
                                            scaleFactor: 0.94,
                                            child: Container(
                                              width: cardW,
                                              height: cardH,
                                              padding: const EdgeInsets.only(top: 6, left: 6, right: 6, bottom: 14),
                                              decoration: BoxDecoration(
                                                color: Colors.white,
                                                borderRadius: BorderRadius.circular(8),
                                                boxShadow: [
                                                  BoxShadow(
                                                    color: Colors.black.withValues(alpha: isDark ? 0.45 : 0.18),
                                                    blurRadius: 14,
                                                    spreadRadius: 1,
                                                    offset: const Offset(0, 6),
                                                  ),
                                                ],
                                              ),
                                              child: Column(
                                                children: [
                                                  Expanded(
                                                    child: ClipRRect(
                                                      borderRadius: BorderRadius.circular(4),
                                                      child: _buildPhotoWidget(path, index),
                                                    ),
                                                  ),
                                                  const SizedBox(height: 4),
                                                  Row(
                                                    mainAxisAlignment: MainAxisAlignment.center,
                                                    children: [
                                                      Container(
                                                        width: 14,
                                                        height: 2.5,
                                                        decoration: BoxDecoration(
                                                          color: Colors.grey[300],
                                                          borderRadius: BorderRadius.circular(2),
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ),
                                        ),
                                      );
                                    }),
                                  ],
                                ),
                              ),
                            );
                          }
                        },
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // 3. 底部手帐工具栏 (加装 FittedBox 自适应保护，彻底消除右侧 14px 溢出)
          Positioned(
            left: 12,
            right: 12,
            bottom: 24,
            child: AnimatedSlide(
              offset: _isPureViewMode ? const Offset(0, 2.5) : Offset.zero,
              duration: const Duration(milliseconds: 320),
              curve: Curves.easeInOutBack,
              child: Center(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: isDark
                          ? const Color(0xFF0F172A).withValues(alpha: 0.92)
                          : Colors.white.withValues(alpha: 0.94),
                      borderRadius: BorderRadius.circular(28),
                      border: Border.all(
                        color: isDark ? Colors.white24 : Colors.white,
                        width: 1.5,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.22),
                          blurRadius: 20,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _buildBottomBtn(
                          icon: Icons.add_a_photo_rounded,
                          label: "添加照片",
                          textColor: textColor,
                          onTap: _pickPhoto,
                        ),
                        _buildDivider(isDark),
                        _buildBottomBtn(
                          icon: Icons.dashboard_customize_rounded,
                          label: _layoutMode == WallLayoutMode.scatter ? "二叉切分" : "手帐散落",
                          textColor: textColor,
                          onTap: () {
                            HapticFeedback.mediumImpact();
                            setState(() {
                              _layoutMode = _layoutMode == WallLayoutMode.scatter
                                  ? WallLayoutMode.treemap
                                  : WallLayoutMode.scatter;
                            });
                            showTopToast(context, '✨ 已切换为：${_layoutMode.label}布局');
                          },
                        ),
                        _buildDivider(isDark),
                        _buildBottomBtn(
                          icon: Icons.casino_rounded,
                          label: "随机重排",
                          textColor: textColor,
                          onTap: _randomizeScatter,
                        ),
                        _buildDivider(isDark),
                        _buildBottomBtn(
                          icon: Icons.style_rounded,
                          label: "换衬底",
                          textColor: textColor,
                          onTap: _cycleTheme,
                        ),
                        _buildDivider(isDark),
                        _buildBottomBtn(
                          icon: Icons.fullscreen_rounded,
                          label: "纯享",
                          textColor: textColor,
                          onTap: () {
                            HapticFeedback.lightImpact();
                            setState(() => _isPureViewMode = true);
                            showTopToast(context, '✨ 轻触画面即可退出纯享模式');
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomBtn({
    required IconData icon,
    required String label,
    required Color textColor,
    required VoidCallback onTap,
  }) {
    return BouncingButton(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        child: Row(
          children: [
            Icon(icon, size: 16, color: textColor),
            const SizedBox(width: 5),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: textColor,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDivider(bool isDark) {
    return Container(
      height: 14,
      width: 1,
      margin: const EdgeInsets.symmetric(horizontal: 4),
      color: isDark ? Colors.white24 : Colors.grey[300],
    );
  }
}

/// 手帐展板背景 Painter (绘制手帐点阵、木纹线等)
class _WallBackgroundPainter extends CustomPainter {
  final WallTheme theme;

  _WallBackgroundPainter({required this.theme});

  @override
  void paint(Canvas canvas, Size size) {
    if (theme == WallTheme.dotGrid) {
      final paint = Paint()
        ..color = const Color(0xFFCBD5E1)
        ..strokeWidth = 1.2
        ..strokeCap = StrokeCap.round;

      const double step = 24.0;
      for (double x = 12; x < size.width; x += step) {
        for (double y = 12; y < size.height; y += step) {
          canvas.drawCircle(Offset(x, y), 0.85, paint);
        }
      }
    } else if (theme == WallTheme.warmWood) {
      final paint = Paint()
        ..color = const Color(0xFFE2D9C8).withValues(alpha: 0.4)
        ..strokeWidth = 1.0;

      for (double y = 0; y < size.height; y += 40.0) {
        canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _WallBackgroundPainter oldDelegate) {
    return oldDelegate.theme != theme;
  }
}

/// 二叉切分树叶子节点
class _TreemapLeaf {
  final int index;
  final Rect rect;

  _TreemapLeaf({required this.index, required this.rect});
}

/// 矩形二叉树切分算法引擎 (Guillotine Treemap Split Layout)
class _TreemapSplitter {
  static List<_TreemapLeaf> computeLeaves(Rect bounds, List<int> indices, int seed) {
    final List<_TreemapLeaf> leaves = [];
    final rand = math.Random(seed);

    void splitNode(Rect currentRect, List<int> currentIndices) {
      if (currentIndices.isEmpty) return;
      if (currentIndices.length == 1) {
        leaves.add(_TreemapLeaf(index: currentIndices.first, rect: currentRect));
        return;
      }

      // 根据当前矩形宽高比判断切割方向 (宽大则竖切，高大则横切)
      final double aspect = currentRect.width / currentRect.height;
      final bool splitVertically = aspect > 1.1 ? true : (aspect < 0.9 ? false : rand.nextBool());

      // 计算左右/上下分割的照片数量分配
      final int half = (currentIndices.length / 2).round();
      final leftIndices = currentIndices.sublist(0, half);
      final rightIndices = currentIndices.sublist(half);

      // 分割比例 (结合数量占比与随机扰动)
      final double ratio = (leftIndices.length / currentIndices.length) + (rand.nextDouble() - 0.5) * 0.12;
      final double clampedRatio = ratio.clamp(0.35, 0.65);

      if (splitVertically) {
        // 垂直切割 (左 | 右)
        final double leftW = currentRect.width * clampedRatio;
        final rectLeft = Rect.fromLTWH(currentRect.left, currentRect.top, leftW, currentRect.height);
        final rectRight = Rect.fromLTWH(currentRect.left + leftW, currentRect.top, currentRect.width - leftW, currentRect.height);
        splitNode(rectLeft, leftIndices);
        splitNode(rectRight, rightIndices);
      } else {
        // 水平切割 (上 / 下)
        final double topH = currentRect.height * clampedRatio;
        final rectTop = Rect.fromLTWH(currentRect.left, currentRect.top, currentRect.width, topH);
        final rectBottom = Rect.fromLTWH(currentRect.left, currentRect.top + topH, currentRect.width, currentRect.height - topH);
        splitNode(rectTop, leftIndices);
        splitNode(rectBottom, rightIndices);
      }
    }

    splitNode(bounds, indices);
    return leaves;
  }
}
