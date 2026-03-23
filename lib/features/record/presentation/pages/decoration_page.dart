import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:async';

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
    final double centerX = fullWidth / 2;
    final double centerY = h * kGridCenterYFactor;

    // 1. 相对中心点
    final double dx = position.dx - centerX;
    final double dy = position.dy - centerY;

    // 2. 反向旋转
    final double cosA = 0.999996; // cos(-0.16)
    final double sinA = 0.00279; // sin(0.16)，反号即反转
    final double rx = dx * cosA + dy * sinA;
    final double ry = -dx * sinA + dy * cosA;

    // 3. 基础参数
    final double tw = fullWidth / 22;
    final double th = tw / 2;

    // 4. 初步估算 i, j 用于比例
    final double roughA = rx / (tw / 2);
    final double roughB = ry / (th / 2) + (kGridRows + kGridCols) / 2;
    final double roughI = (roughA + roughB) / 2;
    final double roughJ = (roughB - roughA) / 2;

    // 5. 双线性插值估算 scale
    final double u = (roughI / kGridRows).clamp(0.0, 1.0);
    final double v = (roughJ / kGridCols).clamp(0.0, 1.0);
    final double scale =
        1.0 +
        (1 - u) * (1 - v) * kGridTopTaper +
        u * (1 - v) * kGridRightTaper +
        (1 - u) * v * kGridLeftTaper +
        u * v * kGridBottomTaper;

    // 6. 最终计算 i, j
    final double A = rx / ((tw / 2) * scale);
    final double B = ry / ((th / 2) * scale) + (kGridRows + kGridCols) / 2;

    final int i = ((A + B) / 2).round();
    final int j = ((B - A) / 2).round();

    if (i >= 0 && i < kGridRows && j >= 0 && j < kGridCols) {
      setState(() {
        _selectedCell = (i, j);
      });
    } else {
      setState(() {
        _selectedCell = null;
      });
    }
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
                        // 2. 网格层
                        Positioned(
                          left: 0,
                          top: 0,
                          width: fullWidth,
                          height: h,
                          child: GestureDetector(
                            onTapUp: (details) =>
                                _handleTap(details.localPosition, fullWidth, h),
                            child: CustomPaint(
                              painter: IsometricGridPainter(
                                rows: kGridRows,
                                cols: kGridCols,
                                fullWidth: fullWidth,
                                fullHeight: h,
                                selectedCell: _selectedCell,
                              ),
                            ),
                          ),
                        ),
                        // 撑开 Stack
                        SizedBox(width: fullWidth, height: h),
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
        ],
      ),
    );
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
  final (int, int)? selectedCell;

  IsometricGridPainter({
    required this.rows,
    required this.cols,
    required this.fullWidth,
    required this.fullHeight,
    this.selectedCell,
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

    // 绘制选中高亮
    if (selectedCell != null) {
      final highlightPaint = Paint()
        ..color = Colors.blue.withOpacity(0.4)
        ..style = PaintingStyle.fill;

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
      canvas.drawPath(path, highlightPaint);
    }

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

  @override
  bool shouldRepaint(covariant IsometricGridPainter oldDelegate) =>
      oldDelegate.selectedCell != selectedCell ||
      oldDelegate.fullWidth != fullWidth ||
      oldDelegate.fullHeight != fullHeight;
}
