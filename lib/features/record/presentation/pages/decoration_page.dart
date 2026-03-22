import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:island_diary/core/state/user_state.dart';

class DecorationPage extends StatefulWidget {
  const DecorationPage({super.key});

  @override
  State<DecorationPage> createState() => _DecorationPageState();
}

class _DecorationPageState extends State<DecorationPage> {
  late ScrollController _scrollController;
  double _aspectRatio = 1.0;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _resolveImageSize();

    // 进入装修模式时强制横屏
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);

    // 默认居中滚动
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.jumpTo(
          _scrollController.position.maxScrollExtent / 2,
        );
      }
    });
  }

  void _resolveImageSize() {
    const path = 'assets/images/decoration/furniture/house.png';
    final stream = const AssetImage(path).resolve(ImageConfiguration.empty);
    stream.addListener(
      ImageStreamListener((ImageInfo info, bool _) {
        if (mounted) {
          setState(() {
            _aspectRatio = info.image.width / info.image.height;
          });
        }
      }),
    );
  }

  @override
  void dispose() {
    _scrollController.dispose();
    // 退出时恢复竖屏
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bool isNight = UserState().isNight;
    const String bgPath = 'assets/images/decoration/furniture/house.png';

    return Scaffold(
      backgroundColor: isNight
          ? const Color(0xFF13131F)
          : const Color(0xFFD2B48C),
      body: Stack(
        children: [
          Positioned.fill(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final double currentScale = 1.4;
                final double h = constraints.maxHeight * currentScale;
                final double fullWidth = h * _aspectRatio;

                return SingleChildScrollView(
                  controller: _scrollController,
                  scrollDirection: Axis.horizontal,
                  child: Stack(
                    children: [
                      Image.asset(
                        bgPath,
                        height: h,
                        width: fullWidth,
                        fit: BoxFit.cover,
                      ),
                      Positioned.fill(
                        child: CustomPaint(painter: FloorGridPainter()),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
          Positioned(
            top: 20,
            left: 20,
            child: GestureDetector(
              onTap: () => Navigator.pop(context),
              child: ClipOval(
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.3),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.close_rounded,
                      color: Colors.white,
                      size: 24,
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
}

class FloorGridPainter extends CustomPainter {
  double _getGridX(double i, double t, Size size, double vpX, double tBack) {
    double bottomX = size.width * (i / 38);
    double x = vpX + t * (bottomX - vpX);
    if (i >= 15) {
      // 离顶部越近，收窄程度越大 (t = 1.0 时 factor 为 0，t = tBack 时 factor 为 1.0)
      double factor = (1.0 - t) / (1.0 - tBack);
      x -= (i - 14) * size.width * 0.0015 * factor;
    }
    return x;
  }

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.cyanAccent.withOpacity(0.5)
      ..strokeWidth = 1.2
      ..style = PaintingStyle.stroke;

    final floorPath = _getFloorPath(size);
    canvas.clipPath(floorPath);

    final double vpX = size.width * 0.5;
    final double vpY = size.height * 0.35;
    double currentY = size.height * 0.59;
    double step = (size.height - currentY) * 0.05;
    for (int i = 0; i < 2; i++) {
      currentY += step;
      step *= 1.25;
    }
    final double backY = currentY;
    final double tBack = (backY - vpY) / (size.height - vpY);

    List<double> yLines = [];
    double tempY = backY;
    double tempStep = (size.height - backY) * 0.032;
    for (int row = 0; row <= 10; row++) {
      if (tempY > size.height + 20) break;
      yLines.add(tempY);
      tempY += tempStep;
      tempStep *= 1.25;
    }

    // 绘制纵向线
    for (int i = 3; i <= 55; i++) {
      for (int rowIdx = 0; rowIdx < yLines.length - 1; rowIdx++) {
        final int visibleCol = i - 2;
        final int visibleRow = rowIdx + 1;
        bool shouldDrawCol = false;
        if (!_isGridRemoved(visibleCol, visibleRow)) shouldDrawCol = true;
        if (visibleCol > 1 && !_isGridRemoved(visibleCol - 1, visibleRow))
          shouldDrawCol = true;

        if (shouldDrawCol) {
          final double yTop = yLines[rowIdx];
          final double yBottom = yLines[rowIdx + 1];
          final double tTop = (yTop - vpY) / (size.height - vpY);
          final double tBottom = (yBottom - vpY) / (size.height - vpY);

          final double xTop = _getGridX(i.toDouble(), tTop, size, vpX, tBack);
          final double xBottom = _getGridX(
            i.toDouble(),
            tBottom,
            size,
            vpX,
            tBack,
          );

          canvas.drawLine(Offset(xTop, yTop), Offset(xBottom, yBottom), paint);
        }
      }
    }

    // 绘制水平线
    for (int rowIdx = 0; rowIdx < yLines.length; rowIdx++) {
      final double y = yLines[rowIdx];
      final double t = (y - vpY) / (size.height - vpY);
      for (int i = 3; i < 55; i++) {
        final int visibleCol = i - 2;
        bool shouldDrawLine = false;
        if (rowIdx < yLines.length - 1 &&
            !_isGridRemoved(visibleCol, rowIdx + 1))
          shouldDrawLine = true;
        if (rowIdx > 0 && !_isGridRemoved(visibleCol, rowIdx))
          shouldDrawLine = true;

        if (shouldDrawLine) {
          final double xStart = _getGridX(i.toDouble(), t, size, vpX, tBack);
          final double xEnd = _getGridX(
            (i + 1).toDouble(),
            t,
            size,
            vpX,
            tBack,
          );
          canvas.drawLine(Offset(xStart, y), Offset(xEnd, y), paint);
        }
      }
    }

    // 恢复坐标标注
    final textStyle = TextStyle(
      color: Colors.yellowAccent.withOpacity(0.8),
      fontSize: 8,
      fontWeight: FontWeight.bold,
    );
    for (int rowIdx = 0; rowIdx < yLines.length - 1; rowIdx++) {
      final double yTop = yLines[rowIdx];
      final double yBottom = yLines[rowIdx + 1];
      final double midY = (yTop + yBottom) / 2;
      final double tMid = (midY - vpY) / (size.height - vpY);
      for (int i = 3; i < 55; i++) {
        final int visibleCol = i - 2;
        final int visibleRow = rowIdx + 1;
        if (_isGridRemoved(visibleCol, visibleRow)) continue;

        final double xLeft = _getGridX(i.toDouble(), tMid, size, vpX, tBack);
        final double xRight = _getGridX(
          (i + 1).toDouble(),
          tMid,
          size,
          vpX,
          tBack,
        );
        final double midX = (xLeft + xRight) / 2;

        final tp = TextPainter(
          text: TextSpan(text: '$visibleCol-$visibleRow', style: textStyle),
          textDirection: TextDirection.ltr,
        )..layout();
        tp.paint(canvas, Offset(midX - tp.width / 2, midY - tp.height / 2));
      }
    }
  }

  bool _isGridRemoved(int col, int row) {
    // 左侧初始大块移除
    if (col <= 5 && row <= 5) return true;
    // 左侧精细移除
    if (row == 6 && col <= 5) return true; // 包含 1-6, 2-6 等
    if (col == 6 && row <= 4) return true; // 6-1, 6-2, 6-3, 6-4
    if (col == 1 && row >= 7 && row <= 10) return true; // 1-7 到 1-10
    if (col == 4 && row == 7) return true;
    if (col == 5 && row >= 7 && row <= 8) return true; // 包含 5-7, 5-8
    
    // 右侧精细移除
    if (col == 25 && row <= 6) return true; // 现在包含 25-6
    if (col == 26 && row <= 5) return true; // 包含 26-5
    if (col == 27 && row <= 4) return true; // 包含 27-4
    if (col >= 28 && col <= 31 && row <= 3) return true;
    if (col == 29 && row >= 6 && row <= 8) return true; // 包含 29-6, 29-7, 29-8
    if (col == 30 && row >= 4 && row <= 7) return true; // 包含 30-4 到 30-7
    if (row <= 6 && col >= 31) return true;
    if (row == 7 && col >= 30) return true; // 30-7 之后全部去除
    if (row >= 8 && row <= 9 && col >= 37) return true;
    if (row == 10 && col >= 36) return true;
    return false;
  }

  Path _getFloorPath(Size size) {
    final path = Path();
    final w = size.width;
    final h = size.height;
    double floorTop = 0.59;
    double step = (1.0 - floorTop) * 0.05;
    floorTop += step;
    step *= 1.25;
    floorTop += step;
    path.moveTo(0, h);
    path.lineTo(0, h * 0.92);
    path.lineTo(w * 0.15, h * 0.85);
    path.lineTo(w * 0.15, h * 0.75);
    path.lineTo(w * 0.0, h * 0.70);
    path.lineTo(w * 0.32, h * floorTop);
    path.lineTo(w * 0.98, h * floorTop);
    path.lineTo(w * 0.98, h * 0.95);
    path.lineTo(w, h);
    path.close();
    return path;
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}
