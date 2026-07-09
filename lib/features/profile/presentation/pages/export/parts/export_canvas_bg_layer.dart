part of '../../diary_book_export_page.dart';

class CircularRevealClipper extends CustomClipper<Path> {
  final double fraction;
  CircularRevealClipper(this.fraction);

  @override
  Path getClip(Size size) {
    final center = Offset(size.width / 2, size.height);
    final maxRadius = size.width + size.height;
    final radius = maxRadius * fraction;
    
    final path = Path();
    path.addOval(Rect.fromCircle(center: center, radius: radius));
    return path;
  }

  @override
  bool shouldReclip(CircularRevealClipper oldClipper) => fraction != oldClipper.fraction;
}

class CanvasBackgroundLayer extends StatefulWidget {
  final String? imagePath;
  final Color color;
  final double width;
  final double height;
  final String? cropRatio;
  final double bgX;
  final double bgY;
  final double bgScale;
  final double bgOpacity;
  final ExportPageMargin margin;
  final int pageIndex;
  final int pageCount;

  const CanvasBackgroundLayer({
    super.key,
    required this.imagePath,
    required this.color,
    required this.width,
    required this.height,
    required this.cropRatio,
    required this.bgX,
    required this.bgY,
    required this.bgScale,
    required this.bgOpacity,
    required this.margin,
    required this.pageIndex,
    required this.pageCount,
  });

  @override
  State<CanvasBackgroundLayer> createState() => _CanvasBackgroundLayerState();
}

class _CanvasBackgroundLayerState extends State<CanvasBackgroundLayer> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  String? _oldImagePath;
  String? _currentImagePath;
  Color? _oldColor;
  late Color _currentColor;
  
  @override
  void initState() {
    super.initState();
    _currentImagePath = widget.imagePath;
    _currentColor = widget.color;
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        if (mounted) {
          setState(() {
            _oldImagePath = null;
            _oldColor = null;
          });
        }
      }
    });
    _controller.value = 1.0;
  }

  @override
  void didUpdateWidget(CanvasBackgroundLayer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.imagePath != widget.imagePath || oldWidget.color != widget.color) {
      _oldImagePath = oldWidget.imagePath;
      _oldColor = oldWidget.color;
      
      _currentImagePath = widget.imagePath;
      _currentColor = widget.color;
      _controller.forward(from: 0.0);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Widget _buildImage(String path) {
    return Positioned(
      left: widget.bgX,
      top: widget.bgY,
      width: widget.width * widget.bgScale,
      height: widget.height * widget.bgScale,
      child: Opacity(
        opacity: widget.bgOpacity,
        child: AspectRatio(
          aspectRatio: widget.cropRatio == '1:1'
              ? 1.0
              : widget.cropRatio == '3:4'
              ? 0.75
              : widget.cropRatio == '4:3'
              ? 4.0 / 3.0
              : widget.cropRatio == '16:9'
              ? 16.0 / 9.0
              : widget.width / widget.height,
          child: path.startsWith('http://') || path.startsWith('https://')
              ? Image.network(path, fit: BoxFit.cover)
              : path.startsWith('assets/')
              ? Image.asset(path, fit: BoxFit.cover)
              : Image.file(File(path), fit: BoxFit.cover),
        ),
      ),
    );
  }

  Widget _buildBackgroundLayer({String? path, required Color color}) {
    return Stack(
      fit: StackFit.expand,
      children: [
        Container(color: color),
        if (path != null) _buildImage(path),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool isAnimating = _oldColor != null;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.12),
            blurRadius: 25,
            spreadRadius: 2,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: ClipRect(
        child: Stack(
          fit: StackFit.expand,
          children: [
            // 1. 底层：新背景（动画结束后也是它）
            _buildBackgroundLayer(path: _currentImagePath, color: _currentColor),

            // 2. 中层：老背景带遮罩。ShaderMask 在老背景中心挖一个扩大的柔和洞，透出底层的新背景
            if (isAnimating)
              AnimatedBuilder(
                animation: _controller,
                builder: (context, child) {
                  final curve = Curves.easeOutQuart;
                  final val = curve.transform(_controller.value);
                  
                  return ShaderMask(
                    blendMode: BlendMode.dstOut,
                    shaderCallback: (Rect bounds) {
                      // 从当前页面的底部中心向外扩散。最大半径是底边中点到顶部顶角的距离。
                      final maxRadius = sqrt(pow(bounds.width / 2, 2) + pow(bounds.height, 2));
                      final currentRadius = maxRadius * val;
                      
                      // 模糊边缘逐渐变宽，最大到180像素
                      final fuzzyRadius = currentRadius + (val * 180.0); 

                      // Flutter 中 RadialGradient 的 radius: 1.0 对应 shortestSide
                      final shortestSide = min(bounds.width, bounds.height);
                      final double effectiveRadius = maxRadius / shortestSide;
                      
                      // 核心修复：防止 stops 出现 [0.0, 0.0, 0.0] 导致底层渲染引擎（如 Impeller）着色器崩溃！
                      // 必须确保 stops 严格递增
                      final double stop1 = max((currentRadius / maxRadius).clamp(0.0, 1.0), 0.0001);
                      final double stop2 = max((fuzzyRadius / maxRadius).clamp(0.0, 1.0), stop1 + 0.0001);

                      return RadialGradient(
                        center: Alignment.bottomCenter,
                        radius: effectiveRadius,
                        colors: const [
                          Colors.black, // 核心区是黑的，挖空旧图
                          Colors.black,
                          Colors.transparent, // 外围透明，保留旧图
                        ],
                        stops: [
                          0.0,
                          stop1,
                          stop2,
                        ],
                      ).createShader(bounds);
                    },
                    child: child,
                  );
                },
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    _buildBackgroundLayer(path: _oldImagePath, color: _oldColor!),
                  ],
                ),
              ),

            // 4. 页边距辅助线
            Positioned(
              left: widget.margin.left,
              top: widget.margin.top,
              right: widget.margin.right,
              bottom: widget.margin.bottom,
              child: Container(
                decoration: BoxDecoration(
                  border: Border.all(
                    color: const Color(0xFF5A3E28).withValues(alpha: 0.25),
                    style: BorderStyle.solid,
                    width: 1.5,
                  ),
                ),
              ),
            ),
            
            // 页脚页码
            Positioned(
              bottom: 8,
              left: 0,
              right: 0,
              child: Center(
                child: Text(
                  '第 ${widget.pageIndex + 1} 页 / 共 ${widget.pageCount} 页',
                  style: TextStyle(
                    fontSize: 10,
                    color: const Color(0xFF5A3E28).withValues(alpha: 0.4),
                    fontFamily: 'LXGWWenKai',
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
