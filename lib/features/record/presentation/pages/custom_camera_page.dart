import 'dart:io';
import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:camera/camera.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:wechat_assets_picker/wechat_assets_picker.dart';
import '../utils/camera_image_processor.dart';
import '../utils/camera_matting_processor.dart';
import 'package:island_diary/shared/widgets/diary_entry/components/redbook_asset_picker.dart';
import 'package:island_diary/core/state/user_state.dart';
import 'package:island_diary/shared/widgets/top_toast.dart';

class CustomCameraPage extends StatefulWidget {
  const CustomCameraPage({super.key});

  @override
  State<CustomCameraPage> createState() => _CustomCameraPageState();
}

class _CustomCameraPageState extends State<CustomCameraPage> with TickerProviderStateMixin {
  List<CameraDescription> _cameras = [];
  CameraController? _controller;
  bool _isCameraInitialized = false;
  bool _hasPermission = false;
  int _selectedCameraIndex = 0;

  // 画幅比例: '1:1', '4:3', '16:9'
  String _currentRatio = '1:1';

  // 描边参数 (仅在开启魔棒抠图时可用)
  double _strokeWidth = 0.0;
  Color _strokeColor = Colors.white;
  String _strokeStyle = 'solid'; // 'solid', 'glow', 'stars'
  ui.Image? _previewUiImage;

  // 闪光灯模式: 'off', 'auto', 'torch'
  String _currentFlashMode = 'off';

  // 网格线开关
  bool _showGrid = false;

  // 水印样式: 'none' (无), 'film' (复古胶片), 'simple_date' (极简日期), 'device_inner' (相机内嵌), 'polaroid' (拍立得)
  String _watermarkStyle = 'none';

  // 拍照模式固定为单图拍摄
  final String _shootMode = 'single';
  final List<String> _tempCapturedPaths = [];

  // 对焦与曝光控制
  Offset? _focusPoint;
  double _currentExposure = 0.0;
  double _minExposure = -2.0;
  double _maxExposure = 2.0;
  bool _showExposureSlider = false;
  
  // 变焦缩放控制
  double _currentZoom = 1.0;
  double _maxZoom = 1.0;
  double _minZoom = 1.0;
  double _baseZoom = 1.0;

  // 延时倒计时拍照
  int _selfTimerSeconds = 0; // 0=关闭, 3=3s, 5=5s
  int _countdownValue = 0;
  bool _isCountingDown = false;
  Timer? _countdownTimer;
  Timer? _exposureTimer;

  // 实时滤镜/色温控制 ('auto' 自动, 'warm' 暖阳, 'cool' 冷感, 'retro' 复古)
  String _currentFilter = 'auto';

  // 抠图模式: 'none' (无), 'local' (本地AI), 'cloud' (云端高清)
  String _mattingMode = 'none';

  // 马赛克模式 ('none' 无, 'pixel' 像素化, 'blur' 毛玻璃)
  String _mosaicMode = 'none';

  // 当前激活的二级功能参数面板 ('ratio', 'filter', 'adjust', 'watermark', 'matting')
  String _currentSubPanel = 'ratio';

  // 拍照预览确认的本地临时文件路径
  String? _previewPath;
  String? _capturedRawPath;

  // 12种调节参数
  final Map<String, double> _adjustParams = {
    'exposure': 0.0,
    'highlights': 0.0,
    'shadows': 0.0,
    'brightness': 0.0,
    'contrast': 0.0,
    'whites': 0.0,
    'blacks': 0.0,
    'saturation': 0.0,
    'vibrance': 0.0,
    'temp': 0.0,
    'sharpness': 0.0,
    'fade': 0.0,
  };

  String _selectedAdjustKey = 'exposure';

  final List<Map<String, dynamic>> _adjustItems = [
    {'key': 'exposure', 'name': '曝光', 'icon': Icons.exposure_rounded, 'min': -1.0, 'max': 1.0},
    {'key': 'highlights', 'name': '高光', 'icon': Icons.filter_hdr_rounded, 'min': -1.0, 'max': 1.0},
    {'key': 'shadows', 'name': '阴影', 'icon': Icons.wb_twilight_rounded, 'min': -1.0, 'max': 1.0},
    {'key': 'brightness', 'name': '亮度', 'icon': Icons.light_mode_rounded, 'min': -1.0, 'max': 1.0},
    {'key': 'contrast', 'name': '对比度', 'icon': Icons.contrast_rounded, 'min': -1.0, 'max': 1.0},
    {'key': 'whites', 'name': '亮部', 'icon': Icons.brightness_high_rounded, 'min': -1.0, 'max': 1.0},
    {'key': 'blacks', 'name': '暗部', 'icon': Icons.brightness_low_rounded, 'min': -1.0, 'max': 1.0},
    {'key': 'saturation', 'name': '饱和度', 'icon': Icons.palette_rounded, 'min': -1.0, 'max': 1.0},
    {'key': 'vibrance', 'name': '自然饱和度', 'icon': Icons.color_lens_rounded, 'min': -1.0, 'max': 1.0},
    {'key': 'temp', 'name': '色温', 'icon': Icons.device_thermostat_rounded, 'min': -1.0, 'max': 1.0},
    {'key': 'sharpness', 'name': '锐度', 'icon': Icons.details_rounded, 'min': 0.0, 'max': 1.0},
    {'key': 'fade', 'name': '褪色', 'icon': Icons.blur_linear_rounded, 'min': 0.0, 'max': 1.0},
  ];

  List<double> _calculateColorMatrix() {
    double exp = _adjustParams['exposure']! * 0.5;
    double bright = _adjustParams['brightness']! * 40.0;
    double con = _adjustParams['contrast']! * 0.4;
    double high = _adjustParams['highlights']! * 20.0;
    double shd = _adjustParams['shadows']! * 25.0;
    double wht = _adjustParams['whites']! * 20.0;
    double blk = _adjustParams['blacks']! * 20.0;
    double t = _adjustParams['temp']! * 30.0;
    double fd = _adjustParams['fade']! * 0.5;
    double shp = _adjustParams['sharpness']! * 0.15;

    double rMult = 1.0 + exp;
    double gMult = 1.0 + exp;
    double bMult = 1.0 + exp;

    double rOffset = bright + high * 0.8 + shd * 1.2 + wht + blk + t;
    double gOffset = bright + high * 0.8 + shd * 1.2 + wht + blk;
    double bOffset = bright + high * 0.8 + shd * 1.2 + wht + blk - t;

    // 对比度
    double factor = 1.0 + con;
    rMult *= factor;
    gMult *= factor;
    bMult *= factor;
    double conOffset = 128.0 * (1.0 - factor);
    rOffset += conOffset;
    gOffset += conOffset;
    bOffset += conOffset;

    // 褪色
    rMult *= (1.0 - fd * 0.2);
    gMult *= (1.0 - fd * 0.2);
    bMult *= (1.0 - fd * 0.2);
    rOffset += fd * 45.0;
    gOffset += fd * 45.0;
    bOffset += fd * 45.0;

    // 锐度近似
    if (shp > 0) {
      rMult *= (1.0 + shp);
      gMult *= (1.0 + shp);
      bMult *= (1.0 + shp);
      rOffset -= shp * 20;
      gOffset -= shp * 20;
      bOffset -= shp * 20;
    }

    // 饱和度 & 自然饱和度
    double sat = 1.0 + _adjustParams['saturation']! * 0.6 + _adjustParams['vibrance']! * 0.3;
    sat = sat.clamp(0.0, 2.0);

    final double invSat = 1.0 - sat;
    final double rWeight = 0.2126 * invSat;
    final double gWeight = 0.7152 * invSat;
    final double bWeight = 0.0722 * invSat;

    return [
      rMult * (rWeight + sat),  gMult * rWeight,          bMult * rWeight,          0, rOffset,
      rMult * gWeight,          gMult * (gWeight + sat),  bMult * gWeight,          0, gOffset,
      rMult * bWeight,          gMult * bWeight,          bMult * (bWeight + sat),  0, bOffset,
      0,                        0,                        0,                        1, 0,
    ];
  }

  // 相册最新照片预览
  AssetEntity? _latestGalleryAsset;

  // 动画相关
  late AnimationController _shutterAnimationController;
  late AnimationController _focusAnimationController;
  
  late AnimationController _slideOutController;
  late Animation<Offset> _slideOutAnimation;
  String? _slideOutPath;

  late AnimationController _slideInController;
  late Animation<Offset> _slideInAnimation;
  
  @override
  void initState() {
    super.initState();
    _shutterAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 150),
    );
    _focusAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );

    _slideOutController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _slideOutAnimation = Tween<Offset>(
      begin: Offset.zero,
      end: const Offset(1.5, 0.0),
    ).animate(CurvedAnimation(
      parent: _slideOutController,
      curve: Curves.easeOutCubic,
    ));

    _slideInController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
    );
    _slideInAnimation = Tween<Offset>(
      begin: const Offset(-1.5, 0.0),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideInController,
      curve: Curves.easeOutBack,
    ));

    _checkPermissionAndInit();
    _loadLatestGalleryPhoto();
  }

  @override
  void dispose() {
    _controller?.dispose();
    _shutterAnimationController.dispose();
    _focusAnimationController.dispose();
    _slideOutController.dispose();
    _slideInController.dispose();
    _countdownTimer?.cancel();
    _exposureTimer?.cancel();
    super.dispose();
  }

  /// 权限校验与相机初始化
  Future<void> _checkPermissionAndInit() async {
    final cameraStatus = await Permission.camera.request();
    if (cameraStatus.isGranted) {
      setState(() {
        _hasPermission = true;
      });
      _initCamera();
    } else {
      if (mounted) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => AlertDialog(
            title: const Text('需要相机权限', style: TextStyle(fontFamily: 'LXGWWenKai', fontWeight: FontWeight.bold)),
            content: const Text('为了拍摄日记照片，我们需要您授权使用相机。', style: TextStyle(fontFamily: 'LXGWWenKai')),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('返回', style: TextStyle(color: Colors.grey)),
              ),
              TextButton(
                onPressed: () {
                  openAppSettings();
                  Navigator.pop(context);
                },
                child: const Text('去设置', style: TextStyle(color: Color(0xFFD4A373))),
              ),
            ],
          ),
        );
      }
    }
  }

  Future<void> _initCamera() async {
    try {
      _cameras = await availableCameras();
      if (_cameras.isEmpty) return;

      final controller = CameraController(
        _cameras[_selectedCameraIndex],
        ResolutionPreset.high,
        enableAudio: false,
        imageFormatGroup: ImageFormatGroup.jpeg,
      );

      await controller.initialize();
      
      // 获取曝光范围
      _minExposure = await controller.getMinExposureOffset();
      _maxExposure = await controller.getMaxExposureOffset();

      // 获取变焦范围
      _minZoom = await controller.getMinZoomLevel();
      _maxZoom = await controller.getMaxZoomLevel();
      _currentZoom = 1.0;

      if (mounted) {
        setState(() {
          _controller = controller;
          _isCameraInitialized = true;
        });
      }
    } catch (e) {
      debugPrint("相机初始化失败: $e");
    }
  }

  /// 加载相册最新一张照片作为缩略图
  Future<void> _loadLatestGalleryPhoto() async {
    try {
      final List<AssetPathEntity> paths = await PhotoManager.getAssetPathList(
        type: RequestType.image,
      );
      if (paths.isNotEmpty) {
        final List<AssetEntity> assets = await paths.first.getAssetListRange(start: 0, end: 1);
        if (assets.isNotEmpty && mounted) {
          setState(() {
            _latestGalleryAsset = assets.first;
          });
        }
      }
    } catch (e) {
      debugPrint("加载相册最新图片失败: $e");
    }
  }

  /// 切换前后摄像头
  Future<void> _toggleCamera() async {
    if (_cameras.length < 2) return;
    _selectedCameraIndex = (_selectedCameraIndex + 1) % _cameras.length;
    setState(() {
      _isCameraInitialized = false;
    });
    _controller?.dispose();
    _initCamera();
  }

  /// 切换闪光灯模式
  Future<void> _toggleFlashMode() async {
    if (_controller == null) return;
    String nextMode = 'off';
    FlashMode cameraFlashMode = FlashMode.off;

    if (_currentFlashMode == 'off') {
      nextMode = 'auto';
      cameraFlashMode = FlashMode.auto;
    } else if (_currentFlashMode == 'auto') {
      nextMode = 'torch';
      cameraFlashMode = FlashMode.torch;
    } else {
      nextMode = 'off';
      cameraFlashMode = FlashMode.off;
    }

    await _controller!.setFlashMode(cameraFlashMode);
    setState(() {
      _currentFlashMode = nextMode;
    });
  }

  void _resetExposureSliderTimer() {
    _exposureTimer?.cancel();
    _exposureTimer = Timer(const Duration(milliseconds: 2500), () {
      if (mounted) {
        setState(() {
          _showExposureSlider = false;
        });
      }
    });
  }

  /// 对焦与曝光手动调节
  Future<void> _handleTapToFocus(TapUpDetails details, BoxConstraints constraints) async {
    if (_controller == null || !_controller!.value.isInitialized) return;

    final double tapY = details.localPosition.dy;
    final double topBarHeight = MediaQuery.of(context).padding.top + 70;
    final double bottomBarHeight = MediaQuery.of(context).padding.bottom + 140;

    if (tapY < topBarHeight || tapY > constraints.maxHeight - bottomBarHeight) {
      // 拦截顶部栏和底部栏的触控，避免误触发对焦和曝光滑动条
      return;
    }

    final double x = details.localPosition.dx / constraints.maxWidth;
    final double y = details.localPosition.dy / constraints.maxHeight;
    final focusOffset = Offset(x, y);

    setState(() {
      _focusPoint = details.localPosition;
      _showExposureSlider = true;
    });
    _resetExposureSliderTimer();

    _focusAnimationController.forward(from: 0.0);

    try {
      await _controller!.setFocusPoint(focusOffset);
      await _controller!.setExposurePoint(focusOffset);
    } catch (e) {
      debugPrint("手动对焦失败: $e");
    }
  }

  /// 拍摄照片逻辑入口 (支持倒计时)
  Future<void> _takePicture() async {
    if (_controller == null || !_controller!.value.isInitialized || _isCountingDown) return;

    if (_selfTimerSeconds > 0) {
      _startCountdown();
    } else {
      _executeTakePicture();
    }
  }

  /// 启动倒计时计时器
  void _startCountdown() {
    setState(() {
      _isCountingDown = true;
      _countdownValue = _selfTimerSeconds;
    });

    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }

      HapticFeedback.lightImpact(); // 每次倒数嘀声轻微震动提示

      if (_countdownValue <= 1) {
        timer.cancel();
        setState(() {
          _isCountingDown = false;
        });
        _executeTakePicture();
      } else {
        setState(() {
          _countdownValue--;
        });
      }
    });
  }

  /// 执行真实的拍照动作
  Future<void> _executeTakePicture() async {
    _shutterAnimationController.forward().then((_) => _shutterAnimationController.reverse());
    HapticFeedback.mediumImpact();

    try {
      final XFile rawFile = await _controller!.takePicture();
      _tempCapturedPaths.add(rawFile.path);

      int requiredShots = 1;
      if (_shootMode == '2-shot') requiredShots = 2;
      if (_shootMode == '4-shot') requiredShots = 4;

      if (_tempCapturedPaths.length < requiredShots) {
        HapticFeedback.lightImpact();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('已拍摄第 ${_tempCapturedPaths.length} 张，请拍摄下一张', style: const TextStyle(fontFamily: 'LXGWWenKai')),
              duration: const Duration(seconds: 1),
            ),
          );
        }
      } else {
        _processAndReturn();
      }
    } catch (e) {
      debugPrint("拍照出错: $e");
    }
  }

  /// 后期图像处理与返回 (仅生成用于确认的底图)
  Future<void> _processAndReturn() async {
    if (_tempCapturedPaths.isEmpty) return;

    if (_mattingMode == 'cloud') {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => Center(
          child: Card(
            color: Colors.black87,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: const [
                  CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFD4A373))),
                  SizedBox(height: 12),
                  Text('云端AI高清抠图中...', style: TextStyle(color: Colors.white70, fontSize: 13, fontFamily: 'LXGWWenKai', decoration: TextDecoration.none)),
                ],
              ),
            ),
          ),
        ),
      );

      try {
        String inputPath = _tempCapturedPaths.first;
        final mattedPath = await CameraMattingProcessor.processCloudMatting(inputPath);
        if (mounted) {
          Navigator.pop(context); // 关 Loading
          if (mattedPath == inputPath) {
            showTopToast(
              context,
              '智能抠像额度已用完，暂使用原图',
              icon: Icons.warning_amber_rounded,
              iconColor: const Color(0xFFD4A373),
            );
          }
          _runTransition(mattedPath);
        }
      } catch (e) {
        debugPrint("抠图错误: $e");
        if (mounted) {
          Navigator.pop(context); // 关 Loading
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('抠图失败，请重试', style: TextStyle(fontFamily: 'LXGWWenKai'))),
          );
        }
      }
    } else {
      final String rawPath = _tempCapturedPaths.first;
      _runTransition(rawPath);
    }
  }

  /// 拍照完成后的平滑页面切换转场动画 (向右滑出 + 从左滑入)
  Future<void> _runTransition(String resultPath) async {
    setState(() {
      _slideOutPath = _tempCapturedPaths.first;
    });
    _slideOutController.forward(from: 0.0);

    await Future.delayed(const Duration(milliseconds: 280));

    if (mounted) {
      setState(() {
        _capturedRawPath = resultPath;
        _previewPath = resultPath;
        _slideOutPath = null;
      });
      _loadPreviewUiImage(resultPath);
      _slideInController.forward(from: 0.0);
    }
  }

  /// 异步加载预览 ui.Image 缓存
  Future<void> _loadPreviewUiImage(String path) async {
    try {
      final bytes = await File(path).readAsBytes();
      final ui.Codec codec = await ui.instantiateImageCodec(bytes);
      final ui.FrameInfo frameInfo = await codec.getNextFrame();
      if (mounted) {
        setState(() {
          _previewUiImage = frameInfo.image;
        });
      }
    } catch (e) {
      debugPrint("加载预览 ui.Image 失败: $e");
    }
  }
  /// 切换倒计时设置
  void _toggleSelfTimer() {
    setState(() {
      if (_selfTimerSeconds == 0) {
        _selfTimerSeconds = 3;
      } else if (_selfTimerSeconds == 3) {
        _selfTimerSeconds = 5;
      } else {
        _selfTimerSeconds = 0;
      }
    });
    HapticFeedback.lightImpact();
  }

  /// 根据当前选择的滤镜/色温获取相应的 ColorFilter
  ColorFilter _getCurrentColorFilter() {
    if (_currentFilter == 'warm') {
      return ColorFilter.mode(Colors.orange.withValues(alpha: 0.08), BlendMode.softLight);
    } else if (_currentFilter == 'cool') {
      return ColorFilter.mode(Colors.blue.withValues(alpha: 0.08), BlendMode.softLight);
    } else if (_currentFilter == 'retro') {
      return ColorFilter.mode(Colors.brown.withValues(alpha: 0.12), BlendMode.softLight);
    }
    // 自动模式返回无效果滤镜（单位矩阵）
    return const ColorFilter.matrix([
      1, 0, 0, 0, 0,
      0, 1, 0, 0, 0,
      0, 0, 1, 0, 0,
      0, 0, 0, 1, 0,
    ]);
  }

  @override
  Widget build(BuildContext context) {
    if (!_hasPermission) {
      return const Scaffold(backgroundColor: Colors.black);
    }

    return Stack(
      children: [
        Scaffold(
          backgroundColor: Colors.black,
          body: Stack(
            children: [
              // 1. 相机全屏取景框区域
              Positioned.fill(
                child: _isCameraInitialized && _controller != null
                    ? LayoutBuilder(
                        builder: (context, constraints) {
                          final double width = constraints.maxWidth;
                          final double height = constraints.maxHeight;
                          final double cameraRatio = _controller!.value.aspectRatio;

                          final bool isBlurBorder = _watermarkStyle == 'blur_border';
                          final bool isPolaroid = _watermarkStyle == 'polaroid';
                          final double extraScale = isBlurBorder ? 1.15 : (isPolaroid ? 1.12 : 1.0);

                          double targetRatio = 1.0;
                          if (_currentRatio == '4:3') {
                            targetRatio = 4 / 3;
                          } else if (_currentRatio == '16:9') {
                            targetRatio = 16 / 9;
                          }

                          // 计算取景区域的最佳宽度和高度，以保证能完整显示在 Expanded 容器内
                          double displayW = width;
                          double displayH = width * targetRatio;

                          if (displayH * extraScale > height) {
                            // 如果高度超出容器限制，则以容器高度为基准缩放宽度
                            displayH = height / extraScale;
                            displayW = displayH / targetRatio;
                          }

                          final double scale = isBlurBorder ? 0.88 : 1.0;
                          final double topOffset = (height - displayH * extraScale) / 2;
                          final double leftOffset = (width - displayW) / 2;

                          return GestureDetector(
                            onTapUp: (details) => _handleTapToFocus(details, constraints),
                            onScaleStart: (details) {
                              _baseZoom = _currentZoom;
                            },
                            onScaleUpdate: (details) {
                              if (_controller == null || !_controller!.value.isInitialized) return;
                              double targetZoom = (_baseZoom * details.scale).clamp(_minZoom, _maxZoom);
                              _controller!.setZoomLevel(targetZoom);
                              setState(() {
                                _currentZoom = targetZoom;
                              });
                            },
                            child: Stack(
                              children: [
                                // 原始相机取景器画面 (恒定满屏)
                                AnimatedPositioned(
                                  duration: const Duration(milliseconds: 300),
                                  curve: Curves.easeInOut,
                                  top: 0,
                                  left: 0,
                                  width: width,
                                  height: height,
                                  child: ClipRect(
                                    child: FittedBox(
                                      fit: BoxFit.cover,
                                      child: SizedBox(
                                        width: _controller!.value.previewSize?.height ?? 1080,
                                        height: _controller!.value.previewSize?.width ?? 1920,
                                        child: ColorFiltered(
                                          colorFilter: ColorFilter.matrix(_calculateColorMatrix()),
                                          child: ColorFiltered(
                                            colorFilter: _getCurrentColorFilter(),
                                            child: CameraPreview(_controller!),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),

                                // 上边框模糊
                                _buildBlurFrame(
                                  top: topOffset,
                                  left: leftOffset,
                                  width: displayW,
                                  height: isBlurBorder ? displayW * 0.06 : 0,
                                ),
                                // 下边框模糊 (包含水印区域)
                                _buildBlurFrame(
                                  top: topOffset + (isBlurBorder ? (displayW * 0.06 + displayH * 0.88) : displayH),
                                  left: leftOffset,
                                  width: displayW,
                                  height: isBlurBorder ? (displayH * 0.27 - displayW * 0.06) : 0,
                                ),
                                // 左边框模糊
                                _buildBlurFrame(
                                  top: topOffset + (isBlurBorder ? displayW * 0.06 : 0),
                                  left: leftOffset,
                                  width: isBlurBorder ? displayW * 0.06 : 0,
                                  height: isBlurBorder ? displayH * 0.88 : 0,
                                ),
                                // 右边框模糊
                                _buildBlurFrame(
                                  top: topOffset + (isBlurBorder ? displayW * 0.06 : 0),
                                  left: leftOffset + (isBlurBorder ? displayW * 0.94 : displayW),
                                  width: isBlurBorder ? displayW * 0.06 : 0,
                                  height: isBlurBorder ? displayH * 0.88 : 0,
                                ),

                                // 画幅黑色半透明遮罩叠加层
                                _buildRatioOverlay(constraints.maxWidth, constraints.maxHeight, displayH, topOffset),

                                // 实时水印悬浮预览
                                _buildWatermarkPreview(
                                  displayW: displayW,
                                  displayH: displayH,
                                  topOffset: topOffset,
                                  leftOffset: leftOffset,
                                  containerHeight: constraints.maxHeight,
                                ),

                                // 辅助三分法网格线
                                if (_showGrid) _buildGridlines(displayW, displayH, topOffset, leftOffset),

                                // 抠图指示层
                                if (_mattingMode == 'cloud') _buildMattingOverlay(displayW, displayH, topOffset, leftOffset),

                                // 对焦框动效
                                if (_focusPoint != null) _buildFocusIndicator(),

                                // 曝光调节纵向滑动条
                                if (_showExposureSlider) _buildExposureSlider(),

                                // 延时摄影倒计时大数字遮罩
                                if (_isCountingDown)
                                  Positioned.fill(
                                    child: Container(
                                      color: Colors.black.withValues(alpha: 0.35),
                                      child: Center(
                                        child: TweenAnimationBuilder<double>(
                                          key: ValueKey<int>(_countdownValue),
                                          tween: Tween<double>(begin: 1.6, end: 1.0),
                                          duration: const Duration(milliseconds: 300),
                                          builder: (context, val, child) {
                                            return Transform.scale(
                                              scale: val,
                                              child: Text(
                                                '$_countdownValue',
                                                style: TextStyle(
                                                  color: const Color(0xFFD4A373),
                                                  fontSize: 100,
                                                  fontWeight: FontWeight.bold,
                                                  fontFamily: 'LXGWWenKai',
                                                  shadows: [
                                                    Shadow(
                                                      color: Colors.black.withValues(alpha: 0.6),
                                                      offset: const Offset(2, 4),
                                                      blurRadius: 10,
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            );
                                          },
                                        ),
                                      ),
                                    ),
                                  ),
                                if (_slideOutPath != null)
                                  Builder(
                                    builder: (context) {
                                      final bool isBlurBorder = _watermarkStyle == 'blur_border';
                                      final double margin = displayW * 0.06;
                                      return Positioned(
                                        top: topOffset + (isBlurBorder ? margin : 0),
                                        left: leftOffset + (isBlurBorder ? margin : 0),
                                        width: displayW - (isBlurBorder ? margin * 2 : 0),
                                        height: displayH - (isBlurBorder ? margin * 2 : 0),
                                        child: ClipRRect(
                                          borderRadius: BorderRadius.circular(16),
                                          child: SlideTransition(
                                            position: _slideOutAnimation,
                                            child: Image.file(
                                              File(_slideOutPath!),
                                              fit: BoxFit.cover,
                                            ),
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                              ],
                            ),
                          );
                        },
                      )
                    : const Center(
                        child: CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFD4A373)),
                        ),
                      ),
              ),

              // 2. 悬浮顶栏
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: _buildTopBar(),
              ),

              // 3. 悬浮底栏
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: _buildBottomControls(),
              ),
            ],
          ),
        ),
        if (_previewPath != null)
          Positioned.fill(
            child: Material(
              color: Colors.black,
              child: SafeArea(
                child: Column(
                  children: [
                    // 1. 顶部栏 (退出/编辑照片)
                    Container(
                      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.close, color: Colors.white, size: 26),
                            onPressed: () {
                              try {
                                File(_previewPath!).deleteSync();
                              } catch (_) {}
                              setState(() {
                                _previewPath = null;
                                _tempCapturedPaths.clear();
                              });
                            },
                          ),
                          const Text(
                            '编辑照片',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              fontFamily: 'LXGWWenKai',
                              decoration: TextDecoration.none,
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.download_rounded, color: Colors.white, size: 26),
                            onPressed: () async {
                              HapticFeedback.mediumImpact();
                              showDialog(
                                context: context,
                                barrierDismissible: false,
                                builder: (context) => Center(
                                  child: Card(
                                    color: Colors.black87,
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
                                      child: Column(
                                        mainAxisSize: MainAxisSize.min,
                                        children: const [
                                          CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFD4A373))),
                                          SizedBox(height: 12),
                                          Text(
                                            '保存到相册...',
                                            style: TextStyle(
                                              color: Colors.white70,
                                              fontSize: 13,
                                              fontFamily: 'LXGWWenKai',
                                              decoration: TextDecoration.none,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              );

                              try {
                                final finalResultPath = await CameraImageProcessor.processSingleImage(
                                  imagePath: _capturedRawPath!,
                                  ratio: _currentRatio,
                                  watermarkStyle: _watermarkStyle,
                                  filterName: _currentFilter,
                                  mosaicMode: _mosaicMode,
                                  colorMatrix: _calculateColorMatrix(),
                                  strokeWidth: _strokeWidth,
                                  strokeColor: _strokeColor,
                                  strokeStyle: _strokeStyle,
                                );

                                final PermissionState ps = await PhotoManager.requestPermissionExtend();
                                if (!ps.isAuth) {
                                  if (mounted) Navigator.pop(context);
                                  showTopToast(
                                    context,
                                    '保存失败：未获得相册访问权限',
                                    icon: Icons.error_outline_rounded,
                                    iconColor: Colors.redAccent,
                                  );
                                  return;
                                }

                                final AssetEntity? asset = await PhotoManager.editor.saveImageWithPath(
                                  finalResultPath,
                                  title: 'diary_cam_${DateTime.now().millisecondsSinceEpoch}.png',
                                );

                                if (mounted) Navigator.pop(context);

                                if (asset != null) {
                                  showTopToast(
                                    context,
                                    '已成功保存到相册',
                                    icon: Icons.check_circle_outline_rounded,
                                    iconColor: const Color(0xFFD4A373),
                                  );
                                } else {
                                  showTopToast(
                                    context,
                                    '保存相册失败，请重试',
                                    icon: Icons.error_outline_rounded,
                                    iconColor: Colors.redAccent,
                                  );
                                }
                              } catch (e) {
                                debugPrint("保存相册失败: $e");
                                if (mounted) {
                                  Navigator.pop(context);
                                  showTopToast(
                                    context,
                                    '保存出错：$e',
                                    icon: Icons.error_outline_rounded,
                                    iconColor: Colors.redAccent,
                                  );
                                }
                              }
                            },
                          ),
                        ],
                      ),
                    ),

                    // 2. 中间照片预览区 (带滤镜和裁剪、水印的实时预览)
                    Expanded(
                      child: ClipRect(
                        child: Center(
                          child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: LayoutBuilder(
                            builder: (context, constraints) {
                              final bool isPolaroid = _watermarkStyle == 'polaroid';
                              final bool isBlurBorder = _watermarkStyle == 'blur_border';

                              double previewAspect = 1.0;
                              if (_currentRatio == '4:3') {
                                previewAspect = 3 / 4;
                              } else if (_currentRatio == '16:9') {
                                  previewAspect = 9 / 16;
                              }

                              // 计算可用空间限制
                              final double maxW = constraints.maxWidth;
                              double maxH = constraints.maxHeight;
                              if (isPolaroid) {
                                maxH -= 44.0;
                              } else if (isBlurBorder) {
                                maxH = constraints.maxHeight / 1.15;
                              }

                              // 依据可用最大高宽自适应计算缩放后的图片高宽
                              double displayW = maxW;
                              double displayH = maxW / previewAspect;
                              if (displayH > maxH) {
                                displayH = maxH;
                                displayW = maxH * previewAspect;
                              }

                              // 确认实际卡片附加的底部高度
                              double extraHeight = 0.0;
                              if (isPolaroid) {
                                extraHeight = 44.0;
                              } else if (isBlurBorder) {
                                extraHeight = displayH * 0.15;
                              }

                              // 缩放参数
                              double margin = displayW * 0.06;
                              double imgScale = (displayW - margin * 2) / displayW;
                              double fgW = isBlurBorder ? (displayW - margin * 2) : displayW;
                              double fgH = isBlurBorder ? (displayH * imgScale) : displayH;

                              return ClipRRect(
                                borderRadius: BorderRadius.circular(16),
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 300),
                                  curve: Curves.easeInOut,
                                  color: const Color(0xFF1E1E1E),
                                  width: displayW,
                                  height: displayH + extraHeight,
                                  child: Stack(
                                    children: [
                                      // 1. 背景层
                                      if (isBlurBorder)
                                        Positioned.fill(
                                          child: Image.file(
                                            File(_capturedRawPath!),
                                            fit: BoxFit.cover,
                                          ),
                                        ),
                                      if (isBlurBorder)
                                        Positioned.fill(
                                          child: ClipRect(
                                            child: BackdropFilter(
                                              filter: ui.ImageFilter.blur(sigmaX: 25.0, sigmaY: 25.0),
                                              child: Container(
                                                color: Colors.black.withValues(alpha: 0.15),
                                              ),
                                            ),
                                          ),
                                        ),
                                      if (isPolaroid)
                                        Positioned.fill(
                                          child: Container(
                                            color: const Color(0xFFFDFBF7),
                                          ),
                                        ),

                                      // 2. 前景清晰图层
                                      Positioned(
                                        top: isBlurBorder ? margin : 0,
                                        left: isBlurBorder ? margin : 0,
                                        width: fgW,
                                        height: fgH,
                                        child: SlideTransition(
                                          position: _slideInAnimation,
                                          child: ClipRRect(
                                            borderRadius: isBlurBorder ? BorderRadius.circular(4) : BorderRadius.zero,
                                            child: _buildStrokedPreviewImage(
                                              imagePath: _capturedRawPath!,
                                              strokeWidth: _strokeWidth,
                                              strokeColor: _strokeColor,
                                              fgW: fgW,
                                              fgH: fgH,
                                            ),
                                          ),
                                        ),
                                      ),

                                      // 3. 水印层
                                      _buildConfirmPageWatermark(displayW, displayH, extraHeight),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                    ),
                  ),

                    // 3. 编辑子面板
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      height: _currentSubPanel == 'stroke' ? 136.0 : (_currentSubPanel == 'adjust' ? 96.0 : 52.0),
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      alignment: Alignment.center,
                      child: ClipRect(
                        child: _buildSubPanel(),
                      ),
                    ),
                    
                    const Divider(color: Colors.white10, height: 1, thickness: 0.5),
                    const SizedBox(height: 12),

                    // 4. 一级参数分类菜单 (裁剪, 调节, 滤镜, 水印, 描边)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          _buildCategoryItem('ratio', Icons.crop_rounded, '裁剪'),
                          _buildCategoryItem('adjust', Icons.tune_rounded, '调节'),
                          _buildCategoryItem('filter', Icons.color_lens_rounded, '滤镜'),
                          _buildCategoryItem('watermark', Icons.closed_caption_rounded, '水印'),
                          _buildCategoryItem('stroke', Icons.border_outer_rounded, '描边'),
                        ],
                      ),
                    ),

                    const SizedBox(height: 12),

                    // 5. 底部操作按钮
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 12.0),
                      child: Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () {
                                try {
                                  File(_previewPath!).deleteSync();
                                } catch (_) {}
                                setState(() {
                                  _previewPath = null;
                                  _tempCapturedPaths.clear();
                                });
                                HapticFeedback.mediumImpact();
                              },
                              icon: const Icon(Icons.refresh_rounded, color: Colors.white70),
                              label: const Text(
                                '重拍',
                                style: TextStyle(color: Colors.white70, fontFamily: 'LXGWWenKai', fontSize: 16),
                              ),
                              style: OutlinedButton.styleFrom(
                                side: const BorderSide(color: Colors.white30, width: 1.5),
                                padding: const EdgeInsets.symmetric(vertical: 14),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(30),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 20),
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: () async {
                                HapticFeedback.mediumImpact();
                                showDialog(
                                  context: context,
                                  barrierDismissible: false,
                                  builder: (context) => Center(
                                    child: Card(
                                      color: Colors.black87,
                                      child: Padding(
                                        padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
                                        child: Column(
                                          mainAxisSize: MainAxisSize.min,
                                          children: const [
                                            CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFD4A373))),
                                            SizedBox(height: 12),
                                            Text(
                                              '时光洗印中...',
                                              style: TextStyle(
                                                color: Colors.white70,
                                                fontSize: 13,
                                                fontFamily: 'LXGWWenKai',
                                                decoration: TextDecoration.none,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                );

                                try {
                                  final finalResultPath = await CameraImageProcessor.processSingleImage(
                                    imagePath: _capturedRawPath!,
                                    ratio: _currentRatio,
                                    watermarkStyle: _watermarkStyle,
                                    filterName: _currentFilter,
                                    mosaicMode: _mosaicMode,
                                    colorMatrix: _calculateColorMatrix(),
                                    strokeWidth: _strokeWidth,
                                    strokeColor: _strokeColor,
                                    strokeStyle: _strokeStyle,
                                  );
                                  if (mounted) {
                                    Navigator.pop(context); // 关 Loading
                                    Navigator.pop(context, finalResultPath);
                                  }
                                } catch (e) {
                                  debugPrint("图像处理失败: $e");
                                  if (mounted) {
                                    Navigator.pop(context);
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(content: Text('图片处理失败，请重试', style: TextStyle(fontFamily: 'LXGWWenKai'))),
                                    );
                                  }
                                }
                              },
                              icon: const Icon(Icons.check_rounded, color: Colors.black),
                              label: const Text(
                                '确认使用',
                                style: TextStyle(color: Colors.black, fontFamily: 'LXGWWenKai', fontSize: 16, fontWeight: FontWeight.bold),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFFD4A373),
                                padding: const EdgeInsets.symmetric(vertical: 14),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(30),
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
            ),
          ),
      ],
    );
  }

  /// 绘制顶部控制面板
  Widget _buildTopBar() {
    IconData flashIcon = Icons.flash_off;
    if (_currentFlashMode == 'auto') flashIcon = Icons.flash_auto;
    if (_currentFlashMode == 'torch') flashIcon = Icons.highlight;

    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.black54, Colors.transparent],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 12,
        bottom: 24,
        left: 16,
        right: 16,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // 退出按钮
          IconButton(
            icon: const Icon(Icons.close, color: Colors.white, size: 26),
            onPressed: () => Navigator.pop(context),
          ),

          // 延时摄影倒计时
          Stack(
            alignment: Alignment.center,
            children: [
              IconButton(
                icon: Icon(
                  _selfTimerSeconds == 0 ? Icons.timer_outlined : Icons.timer,
                  color: _selfTimerSeconds > 0 ? const Color(0xFFD4A373) : Colors.white54,
                  size: 24,
                ),
                onPressed: _toggleSelfTimer,
              ),
              if (_selfTimerSeconds > 0)
                Positioned(
                  right: 4,
                  bottom: 4,
                  child: Container(
                    padding: const EdgeInsets.all(2),
                    decoration: const BoxDecoration(
                      color: Color(0xFFD4A373),
                      shape: BoxShape.circle,
                    ),
                    child: Text(
                      '${_selfTimerSeconds}s',
                      style: const TextStyle(color: Colors.black, fontSize: 8, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
            ],
          ),

          // 闪光灯
          IconButton(
            icon: Icon(flashIcon, color: _currentFlashMode == 'off' ? Colors.white54 : const Color(0xFFD4A373), size: 24),
            onPressed: _toggleFlashMode,
          ),


          // 辅助网格线
          IconButton(
            icon: Icon(
              _showGrid ? Icons.grid_on : Icons.grid_off,
              color: _showGrid ? const Color(0xFFD4A373) : Colors.white54,
              size: 24,
            ),
            onPressed: () {
              setState(() {
                _showGrid = !_showGrid;
              });
            },
          ),
        ],
      ),
    );
  }

  /// 绘制比例切换和相机的画幅黑色阴影遮罩层
  Widget _buildRatioOverlay(double width, double height, double displayH, double topOffset) {
    return const SizedBox.shrink();
  }

  /// 绘制局部高斯模糊遮罩边框
  Widget _buildBlurFrame({required double top, required double left, required double width, required double height}) {
    return AnimatedPositioned(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      top: top,
      left: left,
      width: width > 0 ? width : 0,
      height: height > 0 ? height : 0,
      child: ClipRect(
        child: BackdropFilter(
          filter: ui.ImageFilter.blur(sigmaX: 25.0, sigmaY: 25.0),
          child: Container(
            color: Colors.black.withValues(alpha: 0.2),
          ),
        ),
      ),
    );
  }

  /// 绘制三分法辅助线
  Widget _buildGridlines(double displayW, double displayH, double topOffset, double leftOffset) {
    final bool isBlurBorder = _watermarkStyle == 'blur_border';
    final double scale = isBlurBorder ? 0.92 : 1.0;
    
    final double borderWidth = displayW * scale;
    final double borderHeight = displayH * scale;
    
    final double finalTop = topOffset + (isBlurBorder ? displayW * 0.04 : 0.0);
    final double finalLeft = leftOffset + (isBlurBorder ? displayW * 0.04 : 0.0);

    return AnimatedPositioned(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      top: finalTop,
      left: finalLeft,
      width: borderWidth,
      height: borderHeight,
      child: IgnorePointer(
        child: Stack(
          children: [
            // 纵向线 1
            Positioned(
              left: borderWidth / 3,
              top: 0,
              bottom: 0,
              width: 0.5,
              child: Container(color: Colors.white30),
            ),
            // 纵向线 2
            Positioned(
              left: borderWidth * 2 / 3,
              top: 0,
              bottom: 0,
              width: 0.5,
              child: Container(color: Colors.white30),
            ),
            // 横向线 1
            Positioned(
              top: borderHeight / 3,
              left: 0,
              right: 0,
              height: 0.5,
              child: Container(color: Colors.white30),
            ),
            // 横向线 2
            Positioned(
              top: borderHeight * 2 / 3,
              left: 0,
              right: 0,
              height: 0.5,
              child: Container(color: Colors.white30),
            ),
          ],
        ),
      ),
    );
  }

  /// 绘制实时水印悬浮预览层
  Widget _buildWatermarkPreview({
    required double displayW,
    required double displayH,
    required double topOffset,
    required double leftOffset,
    required double containerHeight,
  }) {
    if (_watermarkStyle == 'none') return const SizedBox.shrink();

    final now = DateTime.now();
    final String dateStr = "${now.year.toString().substring(2)} ${now.month.toString().padLeft(2, '0')} ${now.day.toString().padLeft(2, '0')}";
    final String timeStr = "${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}";

    final double baseBottom = (containerHeight - (topOffset + displayH)).clamp(0.0, containerHeight);

    Widget previewContent;

    switch (_watermarkStyle) {
      case 'film':
        // 右下角发光橙红水印
        previewContent = AnimatedPositioned(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
          bottom: baseBottom + 12,
          right: leftOffset + 16,
          child: Text(
            "$dateStr  $timeStr",
            style: TextStyle(
              color: const Color(0xFFFF6E40),
              fontSize: 13,
              fontWeight: FontWeight.bold,
              fontFamily: 'LXGWWenKai',
              shadows: [
                Shadow(
                  color: const Color(0xFFFF3D00).withValues(alpha: 0.5),
                  blurRadius: 4,
                ),
                const Shadow(
                  color: Colors.black45,
                  offset: Offset(1, 1),
                  blurRadius: 2,
                ),
              ],
            ),
          ),
        );
        break;
      case 'simple_date':
        // 左下角极简白字
        previewContent = AnimatedPositioned(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
          bottom: baseBottom + 12,
          left: leftOffset + 16,
          child: Text(
            "${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')} $timeStr",
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.85),
              fontSize: 11,
              fontFamily: 'LXGWWenKai',
              shadows: const [
                Shadow(
                  color: Colors.black45,
                  offset: Offset(1, 1),
                  blurRadius: 3,
                ),
              ],
            ),
          ),
        );
        break;
      case 'device_inner':
        // 内嵌机型双行微透水印
        previewContent = AnimatedPositioned(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
          bottom: baseBottom + 12,
          left: leftOffset + 16,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                "岛屿日记 x ${UserState().userName.value.isEmpty ? '我' : UserState().userName.value}",
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 1.0,
                  fontFamily: 'LXGWWenKai',
                  shadows: [Shadow(color: Colors.black45, offset: Offset(1, 1), blurRadius: 3)],
                ),
              ),
              const SizedBox(height: 2),
              Text(
                "50mm F/1.8  1/125s  ISO 100  •  ${now.year}/${now.month.toString().padLeft(2, '0')}/${now.day.toString().padLeft(2, '0')} $timeStr",
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.75),
                  fontSize: 8,
                  fontFamily: 'LXGWWenKai',
                  shadows: const [Shadow(color: Colors.black45, offset: Offset(1, 1), blurRadius: 2)],
                ),
              ),
            ],
          ),
        );
        break;
      case 'polaroid':
        // 拍立得白边预览
        final double barHeight = displayH * 0.12;
        previewContent = AnimatedPositioned(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
          top: topOffset + displayH,
          left: leftOffset,
          width: displayW,
          child: Container(
            height: barHeight,
            color: const Color(0xFFFDFBF7),
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  "Island Diary ╳ Instant",
                  style: TextStyle(
                    fontFamily: 'WanWeiWei',
                    fontSize: 11.0,
                    color: Color(0xFF5D4037),
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  "50mm F/2.0 1/250s ISO100  |  ${now.year}.${now.month.toString().padLeft(2, '0')}.${now.day.toString().padLeft(2, '0')}",
                  style: const TextStyle(
                    fontFamily: 'LXGWWenKai',
                    fontSize: 6.0,
                    color: Color(0xFFA68565),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        );
        break;
      case 'blur_border':
        // 模糊相框中心下方的居中参数水印预览
        final double barHeight = displayH * 0.15;
        previewContent = AnimatedPositioned(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
          top: topOffset + displayH,
          left: leftOffset,
          width: displayW,
          child: ClipRect(
            child: BackdropFilter(
              filter: ui.ImageFilter.blur(sigmaX: 15.0, sigmaY: 15.0),
              child: Container(
                height: barHeight,
                color: Colors.transparent,
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: SingleChildScrollView(
                  physics: const NeverScrollableScrollPhysics(),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        "岛屿日记 x ${UserState().userName.value.isEmpty ? '我' : UserState().userName.value}",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: (displayW * 0.038).clamp(13.0, 28.0),
                          fontWeight: FontWeight.w600,
                          letterSpacing: 2.0,
                          fontFamily: 'LXGWWenKai',
                          shadows: [
                            Shadow(color: Colors.black.withValues(alpha: 0.4), offset: const Offset(1, 1), blurRadius: 2),
                          ],
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        "50mm F/1.8  1/125s  ISO 100  •  ${now.year}/${now.month.toString().padLeft(2, '0')}/${now.day.toString().padLeft(2, '0')} $timeStr",
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.75),
                          fontSize: (displayW * 0.026).clamp(9.5, 18.0),
                          fontFamily: 'LXGWWenKai',
                          shadows: [
                            Shadow(color: Colors.black.withValues(alpha: 0.3), offset: const Offset(1, 1), blurRadius: 2),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
        break;
      default:
        previewContent = const SizedBox.shrink();
    }

    return IgnorePointer(child: Stack(children: [previewContent]));
  }

  /// 点击对焦时的黄色对焦指示框
  Widget _buildFocusIndicator() {
    return Positioned(
      left: _focusPoint!.dx - 30,
      top: _focusPoint!.dy - 30,
      child: AnimatedBuilder(
        animation: _focusAnimationController,
        builder: (context, child) {
          final scale = 1.2 - (_focusAnimationController.value * 0.2);
          final opacity = 1.0 - _focusAnimationController.value;
          return Opacity(
            opacity: opacity.clamp(0.0, 1.0),
            child: Transform.scale(
              scale: scale,
              child: Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  border: Border.all(color: const Color(0xFFD4A373), width: 1.5),
                  shape: BoxShape.circle,
                ),
                child: const Center(
                  child: Icon(Icons.center_focus_strong, color: Color(0xFFD4A373), size: 16),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  /// 纵向曝光度亮度微调滑动条
  Widget _buildExposureSlider() {
    return Positioned(
      right: 16,
      top: 0,
      bottom: 0,
      child: Center(
        child: Container(
          width: 36,
          height: 220,
          decoration: BoxDecoration(
            color: Colors.black38,
            borderRadius: BorderRadius.circular(18),
          ),
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Column(
            children: [
              const Icon(Icons.light_mode, color: Color(0xFFD4A373), size: 14),
              Expanded(
                child: RotatedBox(
                  quarterTurns: 3,
                  child: SliderTheme(
                    data: SliderTheme.of(context).copyWith(
                      trackHeight: 2,
                      thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
                      overlayShape: const RoundSliderOverlayShape(overlayRadius: 10),
                      activeTrackColor: const Color(0xFFD4A373),
                      inactiveTrackColor: Colors.white30,
                      thumbColor: const Color(0xFFD4A373),
                    ),
                    child: Slider(
                      value: _currentExposure,
                      min: _minExposure,
                      max: _maxExposure,
                      onChanged: (val) {
                        setState(() {
                          _currentExposure = val;
                        });
                        if (_controller != null) {
                          _controller!.setExposureOffset(val);
                        }
                      },
                    ),
                  ),
                ),
              ),
              const Icon(Icons.hdr_strong, color: Colors.white70, size: 14),
            ],
          ),
        ),
      ),
    );
  }



  Widget _buildBottomControls() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.transparent, Colors.black87],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      padding: EdgeInsets.only(
        top: 36,
        bottom: MediaQuery.of(context).padding.bottom + 24,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          // 1. 抠像开关
          GestureDetector(
            onTap: () {
              setState(() {
                _mattingMode = _mattingMode == 'none' ? 'cloud' : 'none';
              });
              HapticFeedback.lightImpact();
            },
            child: Container(
              height: 48,
              width: 48,
              decoration: BoxDecoration(
                color: _mattingMode == 'cloud' ? const Color(0xFFD4A373).withValues(alpha: 0.25) : Colors.white.withValues(alpha: 0.1),
                shape: BoxShape.circle,
                border: Border.all(
                  color: _mattingMode == 'cloud' ? const Color(0xFFD4A373) : Colors.white24,
                  width: 1.5,
                ),
              ),
              child: Icon(
                Icons.auto_fix_high_rounded,
                color: _mattingMode == 'cloud' ? const Color(0xFFD4A373) : Colors.white70,
                size: 24,
              ),
            ),
          ),

          // 2. 快门按钮
          GestureDetector(
            onTap: _takePicture,
            child: AnimatedBuilder(
              animation: _shutterAnimationController,
              builder: (context, child) {
                final double scale = 1.0 - (_shutterAnimationController.value * 0.15);
                return Transform.scale(
                  scale: scale,
                  child: Container(
                    height: 80,
                    width: 80,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 4.5),
                    ),
                    padding: const EdgeInsets.all(4.5),
                    child: Container(
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                      ),
                      child: null,
                    ),
                  ),
                );
              },
            ),
          ),

          // 3. 翻转前后摄像头按钮
          IconButton(
            icon: const Icon(Icons.cached, color: Colors.white, size: 30),
            onPressed: _toggleCamera,
          ),
        ],
      ),
    );
  }

  /// 绘制分类选项按钮
  Widget _buildCategoryItem(String panel, IconData icon, String label) {
    final bool isSelected = panel == 'matting' ? (_mattingMode == 'cloud') : (_currentSubPanel == panel);
    return GestureDetector(
      onTap: () {
        if (panel == 'matting') {
          setState(() {
            _mattingMode = _mattingMode == 'none' ? 'cloud' : 'none';
            if (_mattingMode == 'cloud') {
              _currentSubPanel = 'matting';
            } else {
              _currentSubPanel = 'ratio';
            }
          });
        } else {
          setState(() {
            _currentSubPanel = panel;
          });
        }
        HapticFeedback.lightImpact();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white.withValues(alpha: 0.08) : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: isSelected ? const Color(0xFFD4A373) : Colors.white60,
              size: 20,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? const Color(0xFFD4A373) : Colors.white60,
                fontSize: 10,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                fontFamily: 'LXGWWenKai',
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 动态渲染当前的二级菜单参数调节
  Widget _buildSubPanel() {
    Widget content;
    switch (_currentSubPanel) {
      case 'ratio':
        content = Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildRatioButton('1:1'),
            const SizedBox(width: 28),
            _buildRatioButton('4:3'),
            const SizedBox(width: 28),
            _buildRatioButton('16:9'),
          ],
        );
        break;
      case 'filter':
        content = Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildWbButton('auto', '原图'),
            const SizedBox(width: 12),
            _buildWbButton('warm', '暖阳'),
            const SizedBox(width: 12),
            _buildWbButton('cool', '柔冷'),
            const SizedBox(width: 12),
            _buildWbButton('retro', '复古'),
          ],
        );
        break;
      case 'adjust':
        final activeItem = _adjustItems.firstWhere((item) => item['key'] == _selectedAdjustKey);
        content = SingleChildScrollView(
          physics: const NeverScrollableScrollPhysics(),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              // 上层 Slider
              SizedBox(
                height: 36,
                child: Row(
                  children: [
                    const SizedBox(width: 8),
                    Text(
                      '${activeItem['name']}',
                      style: const TextStyle(color: Color(0xFFD4A373), fontSize: 11, fontFamily: 'LXGWWenKai', fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: SliderTheme(
                        data: SliderTheme.of(context).copyWith(
                          trackHeight: 2,
                          thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
                          activeTrackColor: const Color(0xFFD4A373),
                          inactiveTrackColor: Colors.white24,
                          thumbColor: const Color(0xFFD4A373),
                          valueIndicatorColor: const Color(0xFFD4A373),
                          valueIndicatorTextStyle: const TextStyle(color: Colors.black, fontSize: 10, fontWeight: FontWeight.bold),
                        ),
                        child: Slider(
                          value: _adjustParams[_selectedAdjustKey] ?? 0.0,
                          min: activeItem['min'] as double,
                          max: activeItem['max'] as double,
                          label: (_adjustParams[_selectedAdjustKey] ?? 0.0).toStringAsFixed(1),
                          divisions: 20,
                          onChanged: (val) {
                            setState(() {
                              _adjustParams[_selectedAdjustKey] = val;
                            });
                          },
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      (_adjustParams[_selectedAdjustKey] ?? 0.0).toStringAsFixed(1),
                      style: const TextStyle(color: Colors.white70, fontSize: 11, fontFamily: 'LXGWWenKai'),
                    ),
                    const SizedBox(width: 8),
                  ],
                ),
              ),
              const SizedBox(height: 4),
              // 下层 12 个参数选择列表
              SizedBox(
                height: 48,
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  physics: const BouncingScrollPhysics(),
                  child: Row(
                    children: _adjustItems.map((item) {
                      final bool isSelected = _selectedAdjustKey == item['key'];
                      return GestureDetector(
                        onTap: () {
                          setState(() {
                            _selectedAdjustKey = item['key'];
                          });
                          HapticFeedback.lightImpact();
                        },
                        child: Container(
                          margin: const EdgeInsets.symmetric(horizontal: 6),
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: isSelected ? const Color(0xFFD4A373).withValues(alpha: 0.15) : Colors.transparent,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: isSelected ? const Color(0xFFD4A373) : Colors.white12,
                              width: 1,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                item['icon'] as IconData,
                                size: 14,
                                color: isSelected ? const Color(0xFFD4A373) : Colors.white54,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                item['name'] as String,
                                style: TextStyle(
                                  color: isSelected ? const Color(0xFFD4A373) : Colors.white54,
                                  fontSize: 10,
                                  fontFamily: 'LXGWWenKai',
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ),
            ],
          ),
        );
        break;
      case 'stroke':
        content = SingleChildScrollView(
          physics: const NeverScrollableScrollPhysics(),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              // 描边样式选择
              SizedBox(
                height: 36,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _buildStrokeStyleButton('solid', '实线'),
                    const SizedBox(width: 16),
                    _buildStrokeStyleButton('glow', '发光'),
                    const SizedBox(width: 16),
                    _buildStrokeStyleButton('stars', '星光'),
                  ],
                ),
              ),
              const SizedBox(height: 4),
              // 描边粗细 Slider
              SizedBox(
                height: 36,
                child: Row(
                  children: [
                    const SizedBox(width: 8),
                    const Text(
                      '粗细',
                      style: TextStyle(color: Color(0xFFD4A373), fontSize: 11, fontFamily: 'LXGWWenKai', fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: SliderTheme(
                        data: SliderTheme.of(context).copyWith(
                          trackHeight: 2,
                          thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
                          activeTrackColor: const Color(0xFFD4A373),
                          inactiveTrackColor: Colors.white24,
                          thumbColor: const Color(0xFFD4A373),
                          valueIndicatorColor: const Color(0xFFD4A373),
                          valueIndicatorTextStyle: const TextStyle(color: Colors.black, fontSize: 10, fontWeight: FontWeight.bold),
                        ),
                        child: Slider(
                          value: _strokeWidth,
                          min: 0.0,
                          max: 15.0,
                          label: _strokeWidth.toStringAsFixed(1),
                          divisions: 15,
                          onChanged: (val) {
                            setState(() {
                              _strokeWidth = val;
                            });
                          },
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      _strokeWidth.toStringAsFixed(1),
                      style: const TextStyle(color: Colors.white70, fontSize: 11, fontFamily: 'LXGWWenKai'),
                    ),
                    const SizedBox(width: 8),
                  ],
                ),
              ),
              const SizedBox(height: 4),
              // 描边颜色选择
              SizedBox(
                height: 48,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _buildStrokeColorOption(Colors.white),
                    const SizedBox(width: 16),
                    _buildStrokeColorOption(Colors.black),
                    const SizedBox(width: 16),
                    _buildStrokeColorOption(const Color(0xFFD4A373)),
                    const SizedBox(width: 16),
                    _buildStrokeColorOption(Colors.redAccent),
                    const SizedBox(width: 16),
                    _buildStrokeColorOption(Colors.blueAccent),
                  ],
                ),
              ),
            ],
          ),
        );
        break;
      case 'watermark':
        content = Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildWatermarkButton('none', '无'),
            const SizedBox(width: 8),
            _buildWatermarkButton('simple_date', '时间'),
            const SizedBox(width: 8),
            _buildWatermarkButton('device_inner', '内嵌'),
            const SizedBox(width: 8),
            _buildWatermarkButton('polaroid', '留白'),
            const SizedBox(width: 8),
            _buildWatermarkButton('blur_border', '模糊'),
          ],
        );
        break;
      case 'matting':
        content = const SizedBox.shrink();
        break;
      case 'mosaic':
        content = Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildMosaicButton('none', '无'),
            const SizedBox(width: 20),
            _buildMosaicButton('pixel', '像素化'),
            const SizedBox(width: 20),
            _buildMosaicButton('blur', '毛玻璃'),
          ],
        );
        break;
      default:
        content = const SizedBox.shrink();
    }

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 150),
      child: Container(
        key: ValueKey<String>(_currentSubPanel),
        child: content,
      ),
    );
  }

  /// 绘制抠图选择按钮
  Widget _buildMattingButton(String mode, String label) {
    final bool isSelected = _mattingMode == mode;
    return GestureDetector(
      onTap: () {
        setState(() {
          _mattingMode = mode;
        });
        HapticFeedback.lightImpact();
      },
      child: Container(
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFD4A373).withValues(alpha: 0.15) : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? const Color(0xFFD4A373) : Colors.white12,
            width: 1,
          ),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? const Color(0xFFD4A373) : Colors.white70,
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            fontFamily: 'LXGWWenKai',
          ),
        ),
      ),
    );
  }

  /// 绘制水印选择按钮
  Widget _buildWatermarkButton(String style, String label) {
    final bool isSelected = _watermarkStyle == style;
    return GestureDetector(
      onTap: () {
        setState(() {
          _watermarkStyle = style;
        });
        HapticFeedback.lightImpact();
      },
      child: Container(
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFD4A373).withValues(alpha: 0.15) : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? const Color(0xFFD4A373) : Colors.white12,
            width: 1,
          ),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? const Color(0xFFD4A373) : Colors.white54,
            fontSize: 10,
            fontFamily: 'LXGWWenKai',
          ),
        ),
      ),
    );
  }

  /// 绘制描边颜色选择按钮 (仅显示圆形颜色按钮，不要文字，更简约)
  Widget _buildStrokeColorOption(Color color) {
    final bool isSelected = _strokeColor == color;
    return GestureDetector(
      onTap: () {
        setState(() {
          _strokeColor = color;
        });
        HapticFeedback.lightImpact();
      },
      child: Container(
        width: 28,
        height: 28,
        decoration: BoxDecoration(
          color: isSelected ? color.withValues(alpha: 0.2) : Colors.transparent,
          shape: BoxShape.circle,
          border: Border.all(
            color: isSelected ? color : Colors.white24,
            width: 1.5,
          ),
        ),
        padding: const EdgeInsets.all(3),
        child: Container(
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
      ),
    );
  }

  /// 绘制描边样式选择按钮
  Widget _buildStrokeStyleButton(String style, String label) {
    final bool isSelected = _strokeStyle == style;
    return GestureDetector(
      onTap: () {
        setState(() {
          _strokeStyle = style;
        });
        HapticFeedback.lightImpact();
      },
      child: Container(
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFD4A373).withValues(alpha: 0.15) : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? const Color(0xFFD4A373) : Colors.white12,
            width: 1,
          ),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? const Color(0xFFD4A373) : Colors.white54,
            fontSize: 10,
            fontFamily: 'LXGWWenKai',
          ),
        ),
      ),
    );
  }

  /// 绘制焦段选择按钮 (1x / 2x)
  Widget _buildZoomButton(double zoomValue) {
    final bool isSelected = _currentZoom.toStringAsFixed(1) == zoomValue.toStringAsFixed(1);
    return GestureDetector(
      onTap: () async {
        if (_controller == null || !_controller!.value.isInitialized) return;
        final double target = zoomValue.clamp(_minZoom, _maxZoom);
        await _controller!.setZoomLevel(target);
        setState(() {
          _currentZoom = target;
        });
        HapticFeedback.lightImpact();
      },
      child: Container(
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFD4A373) : Colors.transparent,
          shape: BoxShape.circle,
        ),
        padding: const EdgeInsets.all(8),
        child: Text(
          '${zoomValue.toInt()}x',
          style: TextStyle(
            color: isSelected ? Colors.black : Colors.white70,
            fontSize: 10,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  /// 绘制白平衡选择按钮
  Widget _buildWbButton(String wbMode, String label) {
    final bool isSelected = _currentFilter == wbMode;
    return GestureDetector(
      onTap: () {
        setState(() {
          _currentFilter = wbMode;
        });
        HapticFeedback.lightImpact();
      },
      child: Container(
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFD4A373).withValues(alpha: 0.15) : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? const Color(0xFFD4A373) : Colors.white12,
            width: 1,
          ),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? const Color(0xFFD4A373) : Colors.white54,
            fontSize: 10,
            fontFamily: 'LXGWWenKai',
          ),
        ),
      ),
    );
  }

  /// 绘制马赛克按钮
  Widget _buildMosaicButton(String mode, String label) {
    final bool isSelected = _mosaicMode == mode;
    return GestureDetector(
      onTap: () {
        setState(() {
          _mosaicMode = mode;
        });
        HapticFeedback.lightImpact();
      },
      child: Container(
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFD4A373).withValues(alpha: 0.15) : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? const Color(0xFFD4A373) : Colors.white12,
            width: 1,
          ),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? const Color(0xFFD4A373) : Colors.white54,
            fontSize: 10,
            fontFamily: 'LXGWWenKai',
          ),
        ),
      ),
    );
  }

  /// 绘制裁剪比例按钮
  Widget _buildRatioButton(String ratio) {
    final bool isSelected = _currentRatio == ratio;
    return GestureDetector(
      onTap: () {
        setState(() {
          _currentRatio = ratio;
        });
        HapticFeedback.lightImpact();
      },
      child: Container(
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFD4A373).withValues(alpha: 0.15) : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? const Color(0xFFD4A373) : Colors.white12,
            width: 1,
          ),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        child: Text(
          ratio,
          style: TextStyle(
            color: isSelected ? const Color(0xFFD4A373) : Colors.white70,
            fontSize: 11,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            fontFamily: 'LXGWWenKai',
          ),
        ),
      ),
    );
  }

  /// 快速打开相册导入
  Future<void> _openGalleryPicker() async {
    final List<AssetEntity>? result = await RedBookAssetPicker.pick(
      context,
      maxAssets: 1,
      requestType: RequestType.image,
    );
    if (result != null && result.isNotEmpty) {
      final file = await result.first.originFile;
      if (file != null && mounted) {
        Navigator.pop(context, file.path);
      }
    }
  }

  /// 在预览界面上绘制抠好的图的实时描边效果 (利用多重偏移叠色绘制，极致性能防闪烁)
  Widget _buildStrokedPreviewImage({
    required String imagePath,
    required double strokeWidth,
    required Color strokeColor,
    required double fgW,
    required double fgH,
  }) {
    if (strokeWidth <= 0 || _previewUiImage == null) {
      final imageWidget = Image.file(
        File(imagePath),
        fit: BoxFit.cover,
        width: fgW,
        height: fgH,
      );
      return ColorFiltered(
        colorFilter: ColorFilter.matrix(_calculateColorMatrix()),
        child: ColorFiltered(
          colorFilter: _getCurrentColorFilter(),
          child: imageWidget,
        ),
      );
    }

    return ColorFiltered(
      colorFilter: ColorFilter.matrix(_calculateColorMatrix()),
      child: ColorFiltered(
        colorFilter: _getCurrentColorFilter(),
        child: CustomPaint(
          size: Size(fgW, fgH),
          painter: StrokePreviewPainter(
            image: _previewUiImage!,
            strokeWidth: strokeWidth,
            strokeColor: strokeColor,
            strokeStyle: _strokeStyle,
          ),
        ),
      ),
    );
  }

  /// 绘制抠图指示层 (转角框与说明文字)
  Widget _buildMattingOverlay(double displayW, double displayH, double topOffset, double leftOffset) {
    final double margin = 32.0;
    final double frameW = displayW - margin * 2;
    final double frameH = displayH - margin * 2;

    return Positioned(
      top: topOffset + margin,
      left: leftOffset + margin,
      width: frameW,
      height: frameH,
      child: TweenAnimationBuilder<double>(
        tween: Tween<double>(begin: 0.0, end: 1.0),
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeOutBack,
        builder: (context, value, child) {
          return Transform.scale(
            scale: 0.92 + value * 0.08,
            child: Opacity(
              opacity: value.clamp(0.0, 1.0),
              child: child,
            ),
          );
        },
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Positioned.fill(
              child: CustomPaint(
                painter: MattingFramePainter(),
              ),
            ),
            Positioned(
              left: 0,
              right: 0,
              bottom: 24,
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.55),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Text(
                    '请将抠图目标置于取景框内',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontFamily: 'LXGWWenKai',
                      fontWeight: FontWeight.bold,
                      decoration: TextDecoration.none,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 确认页的实时水印文本预览浮层
  Widget _buildConfirmPageWatermark(double displayW, double displayH, double extraHeight) {
    if (_watermarkStyle == 'none') return const SizedBox.shrink();
    final now = DateTime.now();
    final String dateStr = "${now.year.toString().substring(2)} ${now.month.toString().padLeft(2, '0')} ${now.day.toString().padLeft(2, '0')}";
    final String timeStr = "${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}";

    switch (_watermarkStyle) {
      case 'film':
        return Positioned(
          bottom: 12,
          right: 12,
          child: Text(
            "$dateStr  $timeStr",
            style: TextStyle(
              color: const Color(0xFFFF6E40),
              fontSize: 13,
              fontWeight: FontWeight.bold,
              fontFamily: 'LXGWWenKai',
              shadows: [
                Shadow(
                  color: const Color(0xFFFF3D00).withValues(alpha: 0.5),
                  blurRadius: 4,
                ),
                const Shadow(
                  color: Colors.black45,
                  offset: Offset(1, 1),
                  blurRadius: 2,
                ),
              ],
            ),
          ),
        );
      case 'simple_date':
        return Positioned(
          bottom: 12,
          left: 12,
          child: Text(
            "${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')} $timeStr",
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.85),
              fontSize: 11,
              fontFamily: 'LXGWWenKai',
              shadows: const [
                Shadow(
                  color: Colors.black45,
                  offset: Offset(1, 1),
                  blurRadius: 3,
                ),
              ],
            ),
          ),
        );
      case 'device_inner':
        return Positioned(
          bottom: 12,
          left: 12,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                "岛屿日记 x ${UserState().userName.value.isEmpty ? '我' : UserState().userName.value}",
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 1.0,
                  fontFamily: 'LXGWWenKai',
                  shadows: [Shadow(color: Colors.black45, offset: Offset(1, 1), blurRadius: 3)],
                ),
              ),
              const SizedBox(height: 2),
              Text(
                "50mm F/1.8  1/125s  ISO 100  •  ${now.year}/${now.month.toString().padLeft(2, '0')}/${now.day.toString().padLeft(2, '0')} $timeStr",
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.75),
                  fontSize: 8,
                  fontFamily: 'LXGWWenKai',
                  shadows: const [Shadow(color: Colors.black45, offset: Offset(1, 1), blurRadius: 2)],
                ),
              ),
            ],
          ),
        );
      case 'polaroid':
        return Positioned(
          bottom: 0,
          left: 0,
          right: 0,
          height: extraHeight,
          child: Container(
            color: const Color(0xFFFDFBF7),
            padding: const EdgeInsets.symmetric(horizontal: 16),
            alignment: Alignment.center,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  "Island Diary ╳ Instant",
                  style: TextStyle(
                    fontFamily: 'WanWeiWei',
                    fontSize: 12.0,
                    color: Color(0xFF5D4037),
                    fontWeight: FontWeight.bold,
                    decoration: TextDecoration.none,
                  ),
                ),
                Text(
                  "${now.year}.${now.month.toString().padLeft(2, '0')}.${now.day.toString().padLeft(2, '0')}",
                  style: const TextStyle(
                    fontFamily: 'LXGWWenKai',
                    fontSize: 8.0,
                    color: Color(0xFFA68565),
                    fontWeight: FontWeight.w500,
                    decoration: TextDecoration.none,
                  ),
                ),
              ],
            ),
          ),
        );
      case 'blur_border':
        final double margin = displayW * 0.06;
        final double imgScale = (displayW - margin * 2) / displayW;
        final double fgH = displayH * imgScale;
        final double bottomAreaTop = margin + fgH;
        final double bottomAreaHeight = (displayH + extraHeight) - bottomAreaTop;

        return Positioned(
          top: bottomAreaTop,
          left: 0,
          right: 0,
          height: bottomAreaHeight,
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  "岛屿日记 x ${UserState().userName.value.isEmpty ? '我' : UserState().userName.value}",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: (displayW * 0.038).clamp(10.0, 24.0),
                    fontWeight: FontWeight.w600,
                    letterSpacing: 2.0,
                    fontFamily: 'LXGWWenKai',
                    decoration: TextDecoration.none,
                    shadows: [
                      Shadow(color: Colors.black.withValues(alpha: 0.4), offset: const Offset(1, 1), blurRadius: 2),
                    ],
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  "50mm F/1.8  1/125s  ISO 100  •  ${now.year}/${now.month.toString().padLeft(2, '0')}/${now.day.toString().padLeft(2, '0')} $timeStr",
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.75),
                    fontSize: (displayW * 0.026).clamp(7.5, 15.0),
                    fontFamily: 'LXGWWenKai',
                    decoration: TextDecoration.none,
                    shadows: [
                      Shadow(color: Colors.black.withValues(alpha: 0.3), offset: const Offset(1, 1), blurRadius: 2),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      default:
        return const SizedBox.shrink();
    }
  }
}

/// 绘制四个角的白色圆角转角框
class MattingFramePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.9)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0
      ..strokeCap = StrokeCap.round;

    const double lineLength = 24.0;
    const double radius = 12.0;

    // 左上角
    final pathLT = Path()
      ..moveTo(0, lineLength)
      ..lineTo(0, radius)
      ..quadraticBezierTo(0, 0, radius, 0)
      ..lineTo(lineLength, 0);
    canvas.drawPath(pathLT, paint);

    // 右上角
    final pathRT = Path()
      ..moveTo(size.width - lineLength, 0)
      ..lineTo(size.width - radius, 0)
      ..quadraticBezierTo(size.width, 0, size.width, radius)
      ..lineTo(size.width, lineLength);
    canvas.drawPath(pathRT, paint);

    // 左下角
    final pathLB = Path()
      ..moveTo(0, size.height - lineLength)
      ..lineTo(0, size.height - radius)
      ..quadraticBezierTo(0, size.height, radius, size.height)
      ..lineTo(lineLength, size.height);
    canvas.drawPath(pathLB, paint);

    // 右下角
    final pathRB = Path()
      ..moveTo(size.width - lineLength, size.height)
      ..lineTo(size.width - radius, size.height)
      ..quadraticBezierTo(size.width, size.height, size.width, size.height - radius)
      ..lineTo(size.width, size.height - lineLength);
    canvas.drawPath(pathRB, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// 描边渲染预览 CustomPainter，支持实线、发光、星光三种样式
class StrokePreviewPainter extends CustomPainter {
  final ui.Image image;
  final double strokeWidth;
  final Color strokeColor;
  final String strokeStyle;

  StrokePreviewPainter({
    required this.image,
    required this.strokeWidth,
    required this.strokeColor,
    required this.strokeStyle,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final double srcW = image.width.toDouble();
    final double srcH = image.height.toDouble();
    
    // 渲染区域
    final dstRect = Rect.fromLTWH(0, 0, size.width, size.height);
    
    // 计算 BoxFit.cover 对应的源图裁剪区域 srcRect
    final double dstRatio = size.width / size.height;
    final double srcRatio = srcW / srcH;
    
    double cropW, cropH, offsetX, offsetY;
    if (srcRatio > dstRatio) {
      cropH = srcH;
      cropW = srcH * dstRatio;
      offsetX = (srcW - cropW) / 2;
      offsetY = 0.0;
    } else {
      cropW = srcW;
      cropH = srcW / dstRatio;
      offsetX = 0.0;
      offsetY = (srcH - cropH) / 2;
    }
    
    final srcRect = Rect.fromLTWH(offsetX, offsetY, cropW, cropH);

    if (strokeWidth > 0) {
      if (strokeStyle == 'solid') {
        // 实线描边：多方向偏移绘制底图
        final strokePaint = Paint()
          ..colorFilter = ui.ColorFilter.mode(strokeColor, BlendMode.srcIn);

        final double step = strokeWidth;
        final offsets = [
          Offset(-step, 0),
          Offset(step, 0),
          Offset(0, -step),
          Offset(0, step),
          Offset(-step, -step),
          Offset(-step, step),
          Offset(step, -step),
          Offset(step, step),
        ];

        for (final offset in offsets) {
          canvas.save();
          canvas.translate(offset.dx, offset.dy);
          canvas.drawImageRect(image, srcRect, dstRect, strokePaint);
          canvas.restore();
        }
      } else if (strokeStyle == 'glow') {
        // 发光描边：高斯模糊底图
        canvas.saveLayer(dstRect, Paint());
        
        final glowPaint = Paint()
          ..colorFilter = ui.ColorFilter.mode(strokeColor, BlendMode.srcIn)
          ..imageFilter = ui.ImageFilter.blur(sigmaX: strokeWidth, sigmaY: strokeWidth);
        
        canvas.drawImageRect(image, srcRect, dstRect, glowPaint);
        canvas.restore();
      } else if (strokeStyle == 'stars') {
        // 星光描边：用描边底作为 Mask，使用 BlendMode.srcIn 填充星星，最后盖原图
        canvas.saveLayer(dstRect, Paint());

        // 1. 绘制描边底作为遮罩
        final maskPaint = Paint()
          ..colorFilter = ui.ColorFilter.mode(strokeColor, BlendMode.srcIn);
        
        final double step = strokeWidth;
        final offsets = [
          Offset(-step, 0),
          Offset(step, 0),
          Offset(0, -step),
          Offset(0, step),
          Offset(-step, -step),
          Offset(-step, step),
          Offset(step, -step),
          Offset(step, step),
        ];

        for (final offset in offsets) {
          canvas.save();
          canvas.translate(offset.dx, offset.dy);
          canvas.drawImageRect(image, srcRect, dstRect, maskPaint);
          canvas.restore();
        }

        // 2. 剪切：仅在遮罩不透明的区域绘制小星星
        final starPaint = Paint()
          ..color = Colors.white
          ..blendMode = BlendMode.srcIn;

        // 3. 绘制确定性伪随机星星（网格法）
        const double gridStep = 18.0;
        final int cols = (size.width / gridStep).ceil();
        final int rows = (size.height / gridStep).ceil();

        for (int r = 0; r < rows; r++) {
          for (int c = 0; c < cols; c++) {
            final double x = c * gridStep;
            final double y = r * gridStep;
            
            // 简单的确定性伪随机哈希sin
            final double hash = (math.sin(x * 12.9898 + y * 78.233) * 43758.5453).abs() % 1.0;
            if (hash < 0.22) { // 密度控制
              // 偏移微调
              final double dx = (hash * 100) % gridStep;
              final double dy = ((hash * 1000) % gridStep);
              
              final double px = x + dx;
              final double py = y + dy;

              // 星星大小：4 到 8 像素
              final double starSize = 4.0 + (hash * 4.0);
              
              canvas.save();
              canvas.translate(px, py);
              canvas.rotate(hash * 2.0 * math.pi);
              
              _drawStarPath(canvas, starSize, starPaint);
              
              canvas.restore();
            }
          }
        }

        canvas.restore();
      }
    }

    // 绘制原图前景
    canvas.drawImageRect(image, srcRect, dstRect, Paint());
  }

  // 绘制一个小五角星的辅助方法
  void _drawStarPath(Canvas canvas, double size, Paint paint) {
    final Path path = Path();
    final double rx = size / 2;
    final double ry = size / 2;
    // 四角星绘制极为灵动
    path.moveTo(0, -ry);
    path.quadraticBezierTo(0, 0, rx, 0);
    path.quadraticBezierTo(0, 0, 0, ry);
    path.quadraticBezierTo(0, 0, -rx, 0);
    path.quadraticBezierTo(0, 0, 0, -ry);
    path.close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant StrokePreviewPainter oldDelegate) {
    return oldDelegate.image != image ||
           oldDelegate.strokeWidth != strokeWidth ||
           oldDelegate.strokeColor != strokeColor ||
           oldDelegate.strokeStyle != strokeStyle;
  }
}
