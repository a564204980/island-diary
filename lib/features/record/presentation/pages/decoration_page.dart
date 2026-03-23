import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:async';

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
                          child: CustomPaint(
                            painter: IsometricGridPainter(
                              rows: 19,
                              cols: 19,
                              fullWidth: fullWidth,
                              fullHeight: h,
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

  IsometricGridPainter({
    required this.rows,
    required this.cols,
    required this.fullWidth,
    required this.fullHeight,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFFFF0000)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0;

    final double centerX = fullWidth / 2;
    // 使用用户微调后的 0.664
    final double centerY = fullHeight * 0.33;

    // 旋转整体网格 (用户微调后的 -0.16 度)
    canvas.save();
    canvas.translate(centerX, centerY);
    canvas.rotate(-0.16 * 3.14159 / 180);
    canvas.translate(-centerX, -centerY);

    // 单个菱形格子的尺寸 (2:1 比例)
    final double tw = fullWidth / 22;
    final double th = tw / 2;

    // 透视收缩因子 (用户微调后的 0.01)
    const double taperFactor = 0.01;

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
          taperFactor,
        );
        final end = _getPoint(
          (i + 1).toDouble(),
          j.toDouble(),
          centerX,
          centerY,
          tw,
          th,
          taperFactor,
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
          taperFactor,
        );
        final end = _getPoint(
          i.toDouble(),
          (j + 1).toDouble(),
          centerX,
          centerY,
          tw,
          th,
          taperFactor,
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
        final pt = _getPoint(
          i + 0.5,
          j + 0.5,
          centerX,
          centerY,
          tw,
          th,
          taperFactor,
        );
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
    double taper,
  ) {
    // 深度比例 (0-1)
    final double depthT = (i + j) / (rows + cols);
    final double scale = 1.0 - (depthT - 0.5) * taper;

    // 基础等距投影坐标
    final double x = (i - j) * (tw / 2) * scale;
    final double y = (i + j - (rows + cols) / 2) * (th / 2) * scale;

    return Offset(cx + x, cy + y);
  }

  @override
  bool shouldRepaint(covariant IsometricGridPainter oldDelegate) => true;
}
