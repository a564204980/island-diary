import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' as ui;

// --- 网格校准常量 (统一在此修改) ---
const int kGridRows = 19;
const int kGridCols = 19;
const double kGridCenterYFactor = 0.33; // 中心高度比例
const double kGridRotationDegree = -0.4; // 整体旋转角度
const double kGridTopTaper = 0.01; // 远端顶点 (0,0) 缩放 (调节右上角)
const double kGridBottomTaper = 0.06; // 近端顶点 (19,19) 缩放 (调节左下角)
const double kGridLeftTaper = 0; // 左端顶点 (0,19) 缩放 (调节左上角)
const double kGridRightTaper = 0.04; // 右端顶点 (19,0) 缩放 (调节右下角)
// ------------------------------

class DecorationPage extends StatefulWidget {
  const DecorationPage({super.key});

  @override
  State<DecorationPage> createState() => _DecorationPageState();
}

class _DecorationPageState extends State<DecorationPage> {
  final ScrollController _scrollController = ScrollController();
  double _aspectRatio = 16 / 9;
  bool _showHint = true;
  Timer? _hintTimer;
  (int, int)? _selectedCell;
  bool _showTray = true;
  final List<PlacedFurniture> _placedFurniture = [];
  (int, int)? _ghostCell;

  final List<FurnitureItem> _availableItems = [
    FurnitureItem(
      id: 'fridge_1',
      name: '复古冰箱',
      imagePath: 'assets/images/decoration/furniture/fridges2.png',
      spriteRect: const Rect.fromLTWH(0, 0, 0.5, 1.0), // 第1个面
      gridW: 3,
      gridH: 3,
      intrinsicWidth: 605,
      intrinsicHeight: 1072,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _resolveImageSize();
    _forceLandscape();
    _startHintTimer();
  }

  void _startHintTimer() {
    _hintTimer = Timer(const Duration(seconds: 10), () {
      if (mounted) {
        setState(() {
          _showHint = false;
        });
      }
    });
  }

  Future<void> _forceLandscape() async {
    await SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
    await SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  }

  Future<void> _resetOrientation() async {
    await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    await SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  }

  @override
  void dispose() {
    _hintTimer?.cancel();
    _resetOrientation();
    _scrollController.dispose();
    super.dispose();
  }

  void _resolveImageSize() {
    const path = 'assets/images/decoration/furniture/house.png';
    final image = AssetImage(path);
    image
        .resolve(const ImageConfiguration())
        .addListener(
          ImageStreamListener((info, _) {
            if (mounted) {
              setState(() {
                _aspectRatio = info.image.width / info.image.height;
              });
              // 初始滚动到中间
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (_scrollController.hasClients) {
                  final maxScroll = _scrollController.position.maxScrollExtent;
                  _scrollController.jumpTo(maxScroll / 2);
                }
              });
            }
          }),
        );
  }

  void _handleTap(Offset position, double fullWidth, double h) {
    final cell = _hitTestGrid(position, fullWidth, h);
    setState(() {
      _selectedCell = cell;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1A2E), // 深色背景
      body: Stack(
        children: [
          // 背景层：居中的房间
          LayoutBuilder(
            builder: (context, constraints) {
              // 调低缩放比例，确保地板 (0.664 处) 在手机屏幕高度范围内可见
              final bool isTablet =
                  MediaQuery.of(context).size.shortestSide >= 600;
              final double scale = isTablet ? 2.0 : 1.2;

              final double h = constraints.maxHeight * scale;
              final double fullWidth = h * _aspectRatio;

              return SingleChildScrollView(
                controller: _scrollController,
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    minWidth: constraints.maxWidth,
                    minHeight: constraints.maxHeight,
                  ),
                  child: Align(
                    alignment: Alignment.bottomCenter, // 地板在 0.664，贴底更稳
                    child: Stack(
                      children: [
                        // 1. 背景室
                        Image.asset(
                          'assets/images/decoration/furniture/house.png',
                          height: h,
                          width: fullWidth,
                          fit: BoxFit.cover,
                        ),
                        // 2. 网格与拖拽层
                        Positioned(
                          left: 0,
                          top: 0,
                          width: fullWidth,
                          height: h,
                          child: DragTarget<FurnitureItem>(
                            onMove: (details) {
                              final cell = _hitTestGrid(
                                details.offset,
                                fullWidth,
                                h,
                              );
                              if (cell != _ghostCell) {
                                setState(() {
                                  _ghostCell = cell;
                                });
                              }
                            },
                            onAccept: (item) {
                              if (_ghostCell != null) {
                                setState(() {
                                  _placedFurniture.add(
                                    PlacedFurniture(
                                      item: item,
                                      r: _ghostCell!.$1,
                                      c: _ghostCell!.$2,
                                    ),
                                  );
                                  _ghostCell = null;
                                });
                              }
                            },
                            onLeave: (data) =>
                                setState(() => _ghostCell = null),
                            builder: (context, candidateData, rejectedData) {
                              return GestureDetector(
                                behavior: HitTestBehavior.opaque,
                                onTapDown: (details) => _handleTap(
                                  details.localPosition,
                                  fullWidth,
                                  h,
                                ),
                                child: CustomPaint(
                                  painter: IsometricGridPainter(
                                    rows: kGridRows,
                                    cols: kGridCols,
                                    fullWidth: fullWidth,
                                    fullHeight: h,
                                    selectedCell: _selectedCell,
                                    placedItems: _placedFurniture,
                                    ghostItem: candidateData.isNotEmpty
                                        ? (candidateData.first!, _ghostCell)
                                        : null,
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                        // 撑开 Stack
                      ],
                    ),
                  ),
                ),
              );
            },
          ),

          // 顶栏：返回按钮
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Align(
                alignment: Alignment.topLeft,
                child: _buildIconButton(
                  icon: Icons.arrow_back_ios_new_rounded,
                  onTap: () => Navigator.pop(context),
                ),
              ),
            ),
          ),

          // 提示语
          Positioned(
            bottom: 40,
            left: 0,
            right: 0,
            child: Center(
              child: AnimatedOpacity(
                opacity: _showHint ? 1.0 : 0.0,
                duration: const Duration(milliseconds: 500),
                child: const Text(
                  '装修模式：您可以自由布置房间',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    letterSpacing: 1.2,
                  ),
                ),
              ),
            ),
          ),

          // 3. 家具选择托盘
          _buildFurnitureTray(),
        ],
      ),
    );
  }

  Widget _buildFurnitureTray() {
    return AnimatedPositioned(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      bottom: _showTray ? 20 : -140,
      left: 20,
      right: 20,
      child: Container(
        height: 120,
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.6),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: Colors.white10),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.3),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: BackdropFilter(
            filter: ColorFilter.mode(
              Colors.black.withOpacity(0.1),
              BlendMode.srcOver,
            ),
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
              scrollDirection: Axis.horizontal,
              itemCount: _availableItems.length,
              separatorBuilder: (_, __) => const SizedBox(width: 15),
              itemBuilder: (context, index) {
                final item = _availableItems[index];
                return _buildFurnitureCard(item);
              },
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFurnitureCard(FurnitureItem item) {
    return Draggable<FurnitureItem>(
      data: item,
      feedback: const SizedBox.shrink(),
      childWhenDragging: Opacity(opacity: 0.3, child: _buildCardContent(item)),
      child: _buildCardContent(item),
    );
  }

  Widget _buildCardContent(FurnitureItem item) {
    return Column(
      children: [
        Container(
          width: 70,
          height: 70,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.05),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white10),
          ),
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: AspectRatio(
                aspectRatio: item.intrinsicWidth / item.intrinsicHeight,
                child: FurnitureSprite(item: item),
              ),
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          item.name,
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 10,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  (int, int)? _hitTestGrid(Offset localPos, double fullWidth, double h) {
    final double centerX = fullWidth / 2;
    final double centerY = h * kGridCenterYFactor;
    final double dx = localPos.dx - centerX;
    final double dy = localPos.dy - centerY;

    final double rad = kGridRotationDegree * math.pi / 180;
    final double cosA = math.cos(rad);
    final double sinA = math.sin(rad);
    final double rx = dx * cosA + dy * sinA;
    final double ry = -dx * sinA + dy * cosA;

    final double tw = fullWidth / 22;
    final double th = tw / 2;

    final double roughA = rx / (tw / 2);
    final double roughB = ry / (th / 2) + (kGridRows + kGridCols) / 2;
    final double roughI = (roughA + roughB) / 2;
    final double roughJ = (roughB - roughA) / 2;

    final double u = (roughI / kGridRows).clamp(0.0, 1.0);
    final double v = (roughJ / kGridCols).clamp(0.0, 1.0);
    final double scale =
        1.0 +
        (1 - u) * (1 - v) * kGridTopTaper +
        u * (1 - v) * kGridRightTaper +
        (1 - u) * v * kGridLeftTaper +
        u * v * kGridBottomTaper;

    final double A = rx / ((tw / 2) * scale);
    final double B = ry / ((th / 2) * scale) + (kGridRows + kGridCols) / 2;
    final int i = ((A + B) / 2).round();
    final int j = ((B - A) / 2).round();
    if (i >= 0 && i < kGridRows && j >= 0 && j < kGridCols) {
      return (i, j);
    }
    return null;
  }

  Widget _buildIconButton({
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.4),
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Icon(icon, color: Colors.white, size: 20),
      ),
    );
  }
}

class IsometricGridPainter extends CustomPainter {
  final int rows;
  final int cols;
  final double fullWidth;
  final double fullHeight;
  final List<PlacedFurniture> placedItems;
  final (FurnitureItem, (int, int)?)? ghostItem;
  final (int, int)? selectedCell;

  IsometricGridPainter({
    required this.rows,
    required this.cols,
    required this.fullWidth,
    required this.fullHeight,
    this.selectedCell,
    this.placedItems = const [],
    this.ghostItem,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFFFF0000)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0;

    final double centerX = fullWidth / 2;
    final double centerY = fullHeight * kGridCenterYFactor;

    // 旋转整体网格
    canvas.save();
    canvas.translate(centerX, centerY);
    canvas.rotate(kGridRotationDegree * 3.14159 / 180);
    canvas.translate(-centerX, -centerY);

    // 单个菱形格子的尺寸 (2:1 比例)
    final double tw = fullWidth / 22;
    final double th = tw / 2;

    // 网格线绘制逻辑 (移到高亮之前背景绘制)

    // 绘制逻辑
    for (int j = 0; j <= cols; j++) {
      for (int i = 0; i < rows; i++) {
        final start = _getPoint(
          i.toDouble(),
          j.toDouble(),
          centerX,
          centerY,
          tw,
          th,
        );
        final end = _getPoint(
          (i + 1).toDouble(),
          j.toDouble(),
          centerX,
          centerY,
          tw,
          th,
        );
        canvas.drawLine(start, end, paint);
      }
    }
    for (int i = 0; i <= rows; i++) {
      for (int j = 0; j < cols; j++) {
        final start = _getPoint(
          i.toDouble(),
          j.toDouble(),
          centerX,
          centerY,
          tw,
          th,
        );
        final end = _getPoint(
          i.toDouble(),
          (j + 1).toDouble(),
          centerX,
          centerY,
          tw,
          th,
        );
        canvas.drawLine(start, end, paint);
      }
    }

    // 绘制序号
    final textStyle = const TextStyle(
      color: Colors.white,
      fontSize: 8,
      fontWeight: FontWeight.bold,
    );
    for (int i = 0; i < rows; i++) {
      for (int j = 0; j < cols; j++) {
        final pt = _getPoint(i + 0.5, j + 0.5, centerX, centerY, tw, th);
        final tp = TextPainter(
          text: TextSpan(text: '$i-$j', style: textStyle),
          textDirection: TextDirection.ltr,
        )..layout();
        tp.paint(canvas, Offset(pt.dx - tp.width / 2, pt.dy - tp.height / 2));
      }
    }

    // --- 绘制已摆放的家具 ---
    for (final pf in placedItems) {
      _drawFurniture(
        canvas,
        pf.item,
        pf.r,
        pf.c,
        centerX,
        centerY,
        tw,
        th,
        1.0,
      );
    }

    // --- 绘制拖拽预览 (Ghost) ---
    if (ghostItem != null && ghostItem!.$2 != null) {
      _drawFurniture(
        canvas,
        ghostItem!.$1,
        ghostItem!.$2!.$1,
        ghostItem!.$2!.$2,
        centerX,
        centerY,
        tw,
        th,
        0.5,
      );
    }

    // --- 绘制选中高亮 (移到最顶层绘制，确保可见) ---
    if (selectedCell != null) {
      final i = selectedCell!.$1.toDouble();
      final j = selectedCell!.$2.toDouble();

      final path = Path()
        ..moveTo(
          _getPoint(i, j, centerX, centerY, tw, th).dx,
          _getPoint(i, j, centerX, centerY, tw, th).dy,
        )
        ..lineTo(
          _getPoint(i + 1, j, centerX, centerY, tw, th).dx,
          _getPoint(i + 1, j, centerX, centerY, tw, th).dy,
        )
        ..lineTo(
          _getPoint(i + 1, j + 1, centerX, centerY, tw, th).dx,
          _getPoint(i + 1, j + 1, centerX, centerY, tw, th).dy,
        )
        ..lineTo(
          _getPoint(i, j + 1, centerX, centerY, tw, th).dx,
          _getPoint(i, j + 1, centerX, centerY, tw, th).dy,
        )
        ..close();

      // 1. 填充
      canvas.drawPath(
        path,
        Paint()
          ..color = Colors.yellow.withOpacity(0.3)
          ..style = PaintingStyle.fill,
      );

      // 2. 边框 (亮色)
      canvas.drawPath(
        path,
        Paint()
          ..color = Colors.white
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3.0,
      );
    }

    canvas.restore();
  }

  Offset _getPoint(
    double i,
    double j,
    double cx,
    double cy,
    double tw,
    double th,
  ) {
    // 使用双线性插值计算四个角落的独立缩放
    final double u = i / kGridRows;
    final double v = j / kGridCols;

    final double scale =
        1.0 +
        (1 - u) * (1 - v) * kGridTopTaper +
        u * (1 - v) * kGridRightTaper +
        (1 - u) * v * kGridLeftTaper +
        u * v * kGridBottomTaper;

    // 基础等距投影坐标
    final double x = (i - j) * (tw / 2) * scale;
    final double y = (i + j - (kGridRows + kGridCols) / 2) * (th / 2) * scale;

    return Offset(cx + x, cy + y);
  }

  void _drawFurniture(
    Canvas canvas,
    FurnitureItem item,
    int r,
    int c,
    double cx,
    double cy,
    double tw,
    double th,
    double opacity,
  ) {
    // 渲染家具占位的 3x3 范围 (仅预览/高亮时)
    final paint = Paint()
      ..color = Colors.blue.withOpacity(0.1 * opacity)
      ..style = PaintingStyle.fill;

    final path = Path();
    final p0 = _getPoint(r.toDouble(), c.toDouble(), cx, cy, tw, th);
    final p1 = _getPoint(
      (r + item.gridW).toDouble(),
      c.toDouble(),
      cx,
      cy,
      tw,
      th,
    );
    final p2 = _getPoint(
      (r + item.gridW).toDouble(),
      (c + item.gridH).toDouble(),
      cx,
      cy,
      tw,
      th,
    );
    final p3 = _getPoint(
      r.toDouble(),
      (c + item.gridH).toDouble(),
      cx,
      cy,
      tw,
      th,
    );
    path.moveTo(p0.dx, p0.dy);
    path.lineTo(p1.dx, p1.dy);
    path.lineTo(p2.dx, p2.dy);
    path.lineTo(p3.dx, p3.dy);
    path.close();
    canvas.drawPath(path, paint);

    // 绘制家具图片容器 (这里暂时通过 FurnitureSprite 绘制，但 Painter 需要同步)
    // 注意：Painter 无法直接插入 Widget，我们需要直接在 Painter 里通过 _infosCache 或传参拿到 ui.Image
    // 为了满足 KISS，我们假设家具图片已加载 (由托盘预览图触发加载)，
    // 然后在 Painter 里利用 _FurnitureSpriteState 中的记录（或改为全局 Cache）
    final image = _SpritePainter.getImage(item.imagePath);
    if (image != null) {
      // 重新计算该位置的 scale
      final double u = r / rows;
      final double v = c / cols;
      final double s =
          1.0 +
          (1 - u) * (1 - v) * kGridTopTaper +
          u * (1 - v) * kGridRightTaper +
          (1 - u) * v * kGridLeftTaper +
          u * v * kGridBottomTaper;

      // 家具显示尺寸：3个格子的宽度约 3 * tw
      // 这里的比例改为 605:1072 (约 1.77)
      // 乘数由 1.5 降为 1.1，使模型“瘦身”并显得更协调
      // 校正家具尺寸：缩放系数恢复至 0.8，使家具在场景中显得更精致
      final double itemW = tw * item.gridW * s * 0.8;
      final double itemH = itemW * (1072 / 605);

      final basePoint = _getPoint(
        r + item.gridW / 2.0,
        c + item.gridH / 2.0,
        cx,
        cy,
        tw,
        th,
      );

      // 垂直对齐逻辑：使容器底边中点与 3x3 地基菱形的底角对齐
      // 在等轴 2:1 投影下，底角相对于中心的垂直偏移是 (gridW * tw / 4)
      final double verticalOffset = (item.gridW * tw / 4.0) * s;
      final dst = Rect.fromCenter(
        center: Offset(
          basePoint.dx,
          basePoint.dy - (itemH / 2.0) + verticalOffset,
        ),
        width: itemW,
        height: itemH,
      );

      final src = Rect.fromLTWH(
        item.spriteRect.left * image.width,
        item.spriteRect.top * image.height,
        item.spriteRect.width * image.width,
        item.spriteRect.height * image.height,
      );

      canvas.drawImageRect(
        image,
        src,
        dst,
        Paint()..color = Colors.white.withOpacity(opacity),
      );
    }
  }

  @override
  bool shouldRepaint(covariant IsometricGridPainter oldDelegate) =>
      oldDelegate.selectedCell != selectedCell ||
      oldDelegate.fullWidth != fullWidth ||
      oldDelegate.fullHeight != fullHeight ||
      oldDelegate.placedItems != placedItems ||
      oldDelegate.ghostItem != ghostItem;
}

class FurnitureItem {
  final String id;
  final String name;
  final String imagePath;
  final Rect spriteRect;
  final int gridW;
   final int gridH;
  final double intrinsicWidth;
  final double intrinsicHeight;

  FurnitureItem({
    required this.id,
    required this.name,
    required this.imagePath,
    required this.spriteRect,
    this.gridW = 1,
    this.gridH = 1,
    this.intrinsicWidth = 1,
    this.intrinsicHeight = 1,
  });
}

class PlacedFurniture {
  final FurnitureItem item;
  final int r;
  final int c;

  PlacedFurniture({required this.item, required this.r, required this.c});
}

class FurnitureSprite extends StatefulWidget {
  final FurnitureItem item;
  const FurnitureSprite({super.key, required this.item});

  @override
  State<FurnitureSprite> createState() => _FurnitureSpriteState();
}

class _FurnitureSpriteState extends State<FurnitureSprite> {
  ui.Image? _image;
  ImageStream? _imageStream;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _loadImage();
  }

  void _loadImage() {
    final ImageStream newStream = AssetImage(
      widget.item.imagePath,
    ).resolve(createLocalImageConfiguration(context));
    if (newStream.key == _imageStream?.key) return;

    _imageStream?.removeListener(ImageStreamListener(_updateImage));
    _imageStream = newStream;
    _imageStream!.addListener(ImageStreamListener(_updateImage));
  }

  void _updateImage(ImageInfo info, bool _) {
    if (mounted) {
      _SpritePainter.cacheImage(widget.item.imagePath, info.image);
      setState(() {
        _image = info.image;
      });
    }
  }

  @override
  void dispose() {
    _imageStream?.removeListener(ImageStreamListener(_updateImage));
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_image == null) return const SizedBox.shrink();
    return CustomPaint(
      painter: _SpritePainter(
        image: _image!,
        spriteRect: widget.item.spriteRect,
      ),
    );
  }
}

class _SpritePainter extends CustomPainter {
  final ui.Image image;
  final Rect spriteRect;
  static final Map<String, ui.Image> _imageBucket = {};

  _SpritePainter({required this.image, required this.spriteRect}) {
    // 自动缓存，供底座共享显示
    _imageBucket[image.toString()] = image; // 这里用 toString 并不稳，最好用资源的 Key
  }

  // 修改：改为按 Path 存取
  static void cacheImage(String path, ui.Image img) => _imageBucket[path] = img;
  static ui.Image? getImage(String path) => _imageBucket[path];

  @override
  void paint(Canvas canvas, Size size) {
    final src = Rect.fromLTWH(
      spriteRect.left * image.width,
      spriteRect.top * image.height,
      spriteRect.width * image.width,
      spriteRect.height * image.height,
    );
    final dst = Rect.fromLTWH(0, 0, size.width, size.height);
    canvas.drawImageRect(
      image,
      src,
      dst,
      Paint()..filterQuality = ui.FilterQuality.high,
    );
  }

  @override
  bool shouldRepaint(covariant _SpritePainter oldDelegate) =>
      oldDelegate.image != image || oldDelegate.spriteRect != spriteRect;
}
