import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/rendering.dart';
import 'dart:ui' as ui;
import 'package:island_diary/core/state/user_state.dart';
import '../controllers/decoration_controller.dart';
import '../widgets/decoration/decoration_scene.dart';
import '../widgets/decoration/decoration_overlay_ui.dart';
import '../widgets/decoration/wall_color_picker_overlay.dart';
import './decoration_page_constants.dart';

class DecorationPage extends StatefulWidget {
  const DecorationPage({super.key});

  @override
  State<DecorationPage> createState() => _DecorationPageState();
}

class _DecorationPageState extends State<DecorationPage>
    with TickerProviderStateMixin {
  late DecorationController _controller;
  final GlobalKey _gridKey = GlobalKey();
  final GlobalKey _repaintKey = GlobalKey();

  bool _isTrayExpanded = true;
  bool _isInitialized = false;
  bool _showColorPicker = false;

  AnimationController? _zoomAnimationController;
  double _zoomStartScale = 0.4;
  double _zoomEndScale = 0.4;

  @override
  void initState() {
    super.initState();
    _controller = DecorationController();
    _controller.addListener(_onControllerUpdate);

    // 强制横屏并进入沉浸模式
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);

    _zoomAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 250),
    );
    _zoomAnimationController!.addListener(() {
      if (_zoomAnimationController!.isAnimating) {
        final double t = CurvedAnimation(
          parent: _zoomAnimationController!,
          curve: Curves.easeOutCubic,
        ).value;
        _controller.currentScale =
            _zoomStartScale + (_zoomEndScale - _zoomStartScale) * t;
        _controller.updateInteracting(true);
      }
    });

    _zoomAnimationController!.addStatusListener((status) {
      if (status == AnimationStatus.completed ||
          status == AnimationStatus.dismissed) {
        if (mounted) _controller.updateInteracting(false);
      }
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_isInitialized) {
      _isInitialized = true;
      _controller.init(context, vsync: this);
    }
  }

  void _onControllerUpdate() => setState(() {});

  @override
  void dispose() {
    _controller.removeListener(_onControllerUpdate);
    _zoomAnimationController?.dispose();
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF606054),
      body: Stack(
        children: [
          // 核心场景层
          DecorationScene(
            gridKey: _gridKey,
            repaintKey: _repaintKey,
            controller: _controller,
          ),

          // 用户界面层
          DecorationOverlayUI(
            controller: _controller,
            isTrayExpanded: _isTrayExpanded,
            onToggleTray: () =>
                setState(() => _isTrayExpanded = !_isTrayExpanded),
            onZoom: _handleZoom,
            onClearAll: _handleClearAll,
            onBack: _handleBack,
            onShowPaint: () => setState(() => _showColorPicker = true),
          ),

          // 3. 墙面颜色选择器覆盖层
          if (_showColorPicker)
            WallColorPickerOverlay(
              controller: _controller,
              onClose: () => setState(() => _showColorPicker = false),
            ),

          // 资源加载遮罩
          if (_controller.isInitializing) _buildLoadingOverlay(),
        ],
      ),
    );
  }

  Widget _buildLoadingOverlay() {
    return Container(
      color: const Color(0xFF606054),
      width: double.infinity,
      height: double.infinity,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // 自定义进度条容器
            Container(
              width: 300,
              height: 12,
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: Colors.white10, width: 1),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: LinearProgressIndicator(
                  value: _controller.loadingProgress,
                  backgroundColor: Colors.transparent,
                  valueColor: const AlwaysStoppedAnimation<Color>(
                    Colors.white70,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              '正在搬运家具元件... ${((_controller.loadingProgress * 100).toInt())}%',
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 14,
                letterSpacing: 1.2,
                fontWeight: FontWeight.w300,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _handleZoom(double delta) {
    if (_controller.selectedFurniture != null) return;
    _zoomStartScale = _controller.currentScale;
    _zoomEndScale = (_zoomStartScale + delta).clamp(0.3, 3.5);
    _zoomAnimationController!.forward(from: 0);
  }

  void _handleBack() async {
    final bytes = await _captureSnapshot();
    await UserState().setDecorationSnapshot(bytes);
    if (mounted) Navigator.of(context).pop();
  }

  void _handleClearAll() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.grey[900],
        title: const Text('一键清除', style: TextStyle(color: Colors.white)),
        content: const Text(
          '确定要清除房间内所有已摆放的家具吗？',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('取消', style: TextStyle(color: Colors.white38)),
          ),
          TextButton(
            onPressed: () {
              _controller.clearAll();
              Navigator.pop(ctx);
            },
            child: const Text(
              '确定清除',
              style: TextStyle(color: Colors.redAccent),
            ),
          ),
        ],
      ),
    );
  }

  Future<Uint8List?> _captureSnapshot() async {
    try {
      final size = MediaQuery.of(context).size;
      final double screenW = size.width;
      final double screenH = size.height;

      // 1. 提升全景缩放比例 (从 0.45 提升至 0.55) 以增大房屋在快照中的占比
      const double targetScale = 0.55;
      _controller.currentScale = targetScale;
      
      // 2. 几何算法：动态计算居中偏移量
      const double imgW = 2000;
      const double imgH = 2000;
      double baseScale = screenH / imgH;
      if (imgW * baseScale < screenW) baseScale = screenW / imgW;
      
      final double w = imgW * baseScale * kSceneScaleFactor * targetScale;
      final double h = imgH * baseScale * kSceneScaleFactor * targetScale;
      
      final double tw = w / 50;
      final double th = tw * kGridAspectRatio; 
      final double centerY = h * 0.40;

      // 强力对齐：确保视觉重心在 X/Y 轴都绝对居中
      _controller.sceneOffset = Offset(
        (screenW - w) / 2,
        (screenH / 2) - (centerY - 7 * th),
      );

      _controller.updateCapturing(true);
      _controller.selectFurniture(null);
      
      // 3. 增加等待时长，确保场景已经平滑地“瞬移”回中心并完成重绘
      await Future.delayed(const Duration(milliseconds: 180));

      final boundary =
          _repaintKey.currentContext?.findRenderObject()
              as RenderRepaintBoundary?;
      if (boundary == null) return null;

      final ui.Image image = await boundary.toImage(pixelRatio: 0.8);
      final ByteData? byteData = await image.toByteData(
        format: ui.ImageByteFormat.png,
      );

      _controller.updateCapturing(false);
      return byteData?.buffer.asUint8List();
    } catch (e) {
      _controller.updateCapturing(false);
      return null;
    }
  }
}
