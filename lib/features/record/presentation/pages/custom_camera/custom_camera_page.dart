import 'dart:io';
import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:camera/camera.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../utils/camera_matting_processor.dart';
import 'package:island_diary/shared/widgets/top_toast.dart';
import '../camera_edit/camera_edit_overlay.dart';
import '../../widgets/camera_top_bar.dart';
import '../../widgets/camera_bottom_controls.dart';
import '../../widgets/camera_viewfinder.dart';
import 'custom_camera_gallery.dart';

import 'package:flutter_animate/flutter_animate.dart';


class CustomCameraPage extends StatefulWidget {
  final String? initialImagePath;
  final String? initialMattedPath;
  final bool enableDynamicViewfinder;
  const CustomCameraPage({
    super.key, 
    this.initialImagePath, 
    this.initialMattedPath,
    this.enableDynamicViewfinder = false,
  });

  @override
  State<CustomCameraPage> createState() => _CustomCameraPageState();
}

class _CustomCameraPageState extends State<CustomCameraPage> with TickerProviderStateMixin {
  List<CameraDescription> _cameras = [];
  CameraController? _controller;
  bool _isCameraInitialized = false;
  bool _hasPermission = false;
  int _selectedCameraIndex = 0;

  final String _currentRatio = '4:3';

  // 闪光灯模式: 'off', 'auto', 'torch'
  String _currentFlashMode = 'off';

  // 网格线开关
  bool _showGrid = false;

  // 水印样式: 'none' (无), 'film' (复古胶片), 'simple_date' (极简日期), 'device_inner' (相机内嵌), 'polaroid' (拍立得)
  final String _watermarkStyle = 'none';

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
  double _targetZoom = 1.0;
  double _maxZoom = 1.0;
  double _minZoom = 1.0;
  double _baseZoom = 1.0;

  // 动态计算变焦控制按钮的显示选项
  List<double> get _availableZoomLevels {
    if (_minZoom == 1.0 && _maxZoom == 1.0) return [1.0];
    final levels = <double>{};
    
    // 超广角 (0.5x 或 0.6x)
    if (_minZoom < 1.0) {
      levels.add(double.parse(_minZoom.toStringAsFixed(1)));
    }
    // 主摄 1x
    if (_minZoom <= 1.0 && _maxZoom >= 1.0) {
      levels.add(1.0);
    }
    // 长焦 2x
    if (_maxZoom >= 2.0) {
      levels.add(2.0);
    }
    // 如果按钮太少（比如没有超广角）但支持高倍变焦，补充一个高倍选项
    if (levels.length < 3 && _maxZoom >= 3.0) {
      levels.add(3.0);
    }
    
    final result = levels.toList();
    result.sort();
    return result.isEmpty ? [1.0] : result;
  }

  // 延时倒计时拍照
  int _selfTimerSeconds = 0; // 0=关闭, 3=3s, 5=5s
  int _countdownValue = 0;
  bool _isCountingDown = false;
  Timer? _countdownTimer;
  Timer? _exposureTimer;

  // 实时滤镜/色温控制 ('auto' 自动, 'warm' 暖阳, 'cool' 冷感, 'retro' 复古)
  final String _currentFilter = 'auto';

  // 抠图模式: 'none' (无), 'local' (本地AI), 'cloud' (云端高清)
  String _mattingMode = 'none';

  // 拍照预览确认的本地临时文件路径
  String? _previewPath;
  String? _capturedRawPath;
  String? _cachedMattedPath;

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



  // 动画相关
  late AnimationController _unfoldAnimationController;
  late AnimationController _shutterAnimationController;
  late AnimationController _focusAnimationController;
  late AnimationController _zoomAnimationController;
  Animation<double>? _zoomAnimation;
  
  late AnimationController _slideOutController;
  late Animation<Offset> _slideOutAnimation;
  String? _slideOutPath;

  // 打印动画相关 (灵动取景相框专属)
  late AnimationController _printAnimationController;
  bool _isPrintingAnimationRunning = false;
  String? _printPhotoPath;

  bool _hasCompletedInitialUnfold = false;

  late CurvedAnimation _unfoldCurvedAnimation;

  @override
  void initState() {
    super.initState();
    
    _hasCompletedInitialUnfold = !widget.enableDynamicViewfinder;

    if (widget.enableDynamicViewfinder) {
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.manual, overlays: [SystemUiOverlay.bottom]);
    } else {
      // 通过把状态栏图标变成黑色 (dark)，在暗色的相机背景下会显得非常“暗淡”
      // 从而在视觉上达到类似“降低透明度”的隐藏效果
      SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
      ));
    }
    
    _unfoldAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600), // 稍微加快整体动画速度 800 -> 600
      value: widget.enableDynamicViewfinder ? 0.0 : 1.0,
    );

    _unfoldCurvedAnimation = CurvedAnimation(
      parent: _unfoldAnimationController,
      curve: Curves.easeOutCubic,
      reverseCurve: Curves.easeOutCubic, // 使收起动画也呈现“先快后慢”的物理规律
    );

    _unfoldAnimationController.addStatusListener((status) {
      if (status == AnimationStatus.completed && !_hasCompletedInitialUnfold) {
        if (mounted) {
          setState(() {
            _hasCompletedInitialUnfold = true;
          });
        }
      }
    });

    // Extreme delay (1000ms) to ensure the user is completely ready to watch the animation
    // This gives them 1 full second to stare at the black capsule over the dynamic island
    Future.delayed(const Duration(milliseconds: 1000), () {
      if (mounted && widget.enableDynamicViewfinder) {
        _unfoldAnimationController.forward();
      }
    });

    _shutterAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 150),
    );
    _focusAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    
    _zoomAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 250),
    );
    _zoomAnimationController.addListener(() {
      if (_controller == null || !_controller!.value.isInitialized || _zoomAnimation == null) return;
      final target = _zoomAnimation!.value;
      _controller!.setZoomLevel(target);
      setState(() {
        _currentZoom = target;
      });
    });

    _slideOutController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    
    _printAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 5500),
    );
    _slideOutAnimation = Tween<Offset>(
      begin: Offset.zero,
      end: const Offset(1.5, 0.0),
    ).animate(CurvedAnimation(
      parent: _slideOutController,
      curve: Curves.easeOutCubic,
    ));

    if (widget.initialImagePath != null) {
      _hasPermission = true;
      _capturedRawPath = widget.initialImagePath;
      
      // 判断是否已有抠图，或者原图本身就是带透明通道 of PNG
      if (widget.initialMattedPath != null) {
        _cachedMattedPath = widget.initialMattedPath;
      } else if (_isTransparentPng(widget.initialImagePath!)) {
        _cachedMattedPath = widget.initialImagePath;
      }

      final bool hasMatted = _cachedMattedPath != null && File(_cachedMattedPath!).existsSync();
      if (hasMatted) {
        _previewPath = _cachedMattedPath;
        _mattingMode = 'cloud';
      } else {
        _previewPath = widget.initialImagePath;
      }
    } else {
      _checkPermissionAndInit();
    }
  }

  /// 快速检测一个本地文件是否是带 Alpha 通道（透明度）的 PNG 文件
  bool _isTransparentPng(String path) {
    try {
      final file = File(path);
      if (!file.existsSync()) return false;
      if (path.toLowerCase().endsWith('.png')) return true;
      final bytes = file.readAsBytesSync();
      if (bytes.length < 4) return false;
      if (bytes[0] == 0x89 && bytes[1] == 0x50 && bytes[2] == 0x4E && bytes[3] == 0x47) {
        return true;
      }
      return false;
    } catch (e) {
      debugPrint("检测 PNG 透明通道异常: $e");
      return false;
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    _unfoldAnimationController.dispose();
    _shutterAnimationController.dispose();
    _focusAnimationController.dispose();
    _zoomAnimationController.dispose();
    _slideOutController.dispose();
    _printAnimationController.dispose();
    _countdownTimer?.cancel();
    _exposureTimer?.cancel();
    
    // 退出相机时恢复系统的暗黑/高亮状态栏样式，依靠外层页面的 Theme 自动接管
    // 如果之前隐藏了状态栏，现在恢复显示
    if (widget.enableDynamicViewfinder) {
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    }
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
          if (widget.enableDynamicViewfinder) {
            _runPrintAnimation(mattedPath);
          } else {
            _runTransition(mattedPath);
          }
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
      if (widget.enableDynamicViewfinder) {
        _runPrintAnimation(rawPath);
      } else {
        _runTransition(rawPath);
      }
    }
  }

  /// 灵动岛“吐相纸”打印动画
  Future<void> _runPrintAnimation(String resultPath) async {
    setState(() {
      _printPhotoPath = resultPath;
      _isPrintingAnimationRunning = true;
    });
    
    // 收回取景器变成小岛，并开始播放打印动效
    _unfoldAnimationController.reverse();
    _printAnimationController.forward(from: 0.0);
    
    // 等待打印动画前面部分的播放（吐纸 + 掉落 + 悬停），共 5000ms
    await Future.delayed(const Duration(milliseconds: 5000));
    
    if (mounted) {
      setState(() {
        _capturedRawPath = resultPath;
        _previewPath = resultPath; // 这会触发 CameraEditOverlay 显示并开始 400ms 的淡入
      });
      
      // 等待最后 500ms 放大动画结束（此时编辑界面也在同步淡入）
      await Future.delayed(const Duration(milliseconds: 500));
      
      if (mounted) {
        setState(() {
          _printPhotoPath = null;
          _isPrintingAnimationRunning = false;
          _cachedMattedPath = null;
        });
      }
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
        _cachedMattedPath = null;
      });
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

  Widget _buildPrintingPhoto(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    return AnimatedBuilder(
      animation: _printAnimationController,
      builder: (context, child) {
        final t = _printAnimationController.value;
        
        final startWidth = 250.0; // 宽胶囊形态
        
        // 确保计算出正确的高比例 (避免因设备方向导致 targetHeight 过小而被 BoxFit.cover 剧烈放大裁切)
        final cameraAspect = _controller?.value.aspectRatio ?? (4 / 3);
        final realAspect = cameraAspect > 1.0 ? cameraAspect : 1.0 / cameraAspect;
        
        // --- 严格模拟 CameraEditOverlay 的布局逻辑，确保像素级对齐 ---
        final topOffset = MediaQuery.of(context).padding.top + 64.0; // 编辑页顶部栏约 64px
        final bottomOffset = MediaQuery.of(context).padding.bottom + 207.0; // 编辑页底部菜单栏总计 EXACTLY 207px
        final expandedHeight = MediaQuery.of(context).size.height - topOffset - bottomOffset;

        final maxW = screenWidth - 64.0;
        final maxH = expandedHeight - 64.0;

        double displayW = maxW;
        double displayH = maxW * realAspect;
        if (displayH > maxH) {
          displayH = maxH;
          displayW = maxH / realAspect;
        }

        // 匹配 CameraEditOverlay 实际尺寸
        final targetWidth = displayW;
        final targetHeight = displayH;

        final capsuleClosedTop = 11.0;
        
        double photoTop;
        double photoScale;
        double opacity = 1.0;
        double shadowOpacity = 0.3;
        double heightFactor = 1.0;

        if (t < 0.245) { // 5500ms * 0.245 ≈ 1350ms (350ms收缩 + 1000ms停顿)
          photoTop = capsuleClosedTop + 15;
          photoScale = startWidth / targetWidth;
          opacity = 0.0;
          shadowOpacity = 0.0;
          heightFactor = 0.0;
        } else if (t < 0.70) { // 5500ms * 0.455 ≈ 2500ms 的缓慢出纸时间
          final slideProgress = (t - 0.245) / 0.455;
          photoTop = capsuleClosedTop + 15;
          photoScale = startWidth / targetWidth;
          opacity = 1.0;
          shadowOpacity = 0.3;
          heightFactor = slideProgress.clamp(0.001, 1.0);
        } else if (t < 0.818) { // 5500ms * 0.118 ≈ 650ms 的掉落时间
          final scaleProgress = Curves.easeOutBack.transform(((t - 0.70) / 0.118).clamp(0.0, 1.0));
          final startDrop = capsuleClosedTop + 15;
          final finalTop = MediaQuery.of(context).size.height / 2 - (targetHeight / 2);
          photoTop = lerpDouble(startDrop, finalTop, scaleProgress)!;
          photoScale = startWidth / targetWidth; // 保持原有大小不放大
          opacity = 1.0;
          shadowOpacity = 0.3;
          heightFactor = 1.0;
        } else if (t < 0.909) { // 5500ms * 0.091 ≈ 500ms 的悬停停留时间
          photoTop = MediaQuery.of(context).size.height / 2 - (targetHeight / 2);
          photoScale = startWidth / targetWidth; // 保持原有大小不放大
          opacity = 1.0;
          shadowOpacity = 0.3;
          heightFactor = 1.0;
        } else { // 最后的 500ms (5500ms - 5000ms)，执行放大和位移动画，严格对齐编辑界面的位置
          final scaleProgress = Curves.easeInOutCubic.transform(((t - 0.909) / 0.091).clamp(0.0, 1.0));
          final startTop = MediaQuery.of(context).size.height / 2 - (targetHeight / 2);
          // 计算编辑界面中照片的实际居中位置
          final finalTop = topOffset + (expandedHeight / 2) - (targetHeight / 2);
          
          photoTop = lerpDouble(startTop, finalTop, scaleProgress)!;
          photoScale = lerpDouble(startWidth / targetWidth, 1.0, scaleProgress)!;
          opacity = 1.0;
          shadowOpacity = lerpDouble(0.3, 0.0, scaleProgress)!;
          heightFactor = 1.0;
        }

        return Positioned(
          top: photoTop,
          left: (screenWidth - targetWidth) / 2,
          width: targetWidth,
          // height 必须移除，以便让 Align 根据 heightFactor 自由决定容器在垂直方向的渲染尺寸
          child: Transform.scale(
            scale: photoScale,
            alignment: Alignment.topCenter,
            child: Opacity(
              opacity: opacity,
              child: ClipRect(
                child: Align(
                  alignment: Alignment.bottomCenter,
                  heightFactor: heightFactor,
                  child: Container(
                    width: targetWidth,
                    height: targetHeight,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.zero,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: shadowOpacity),
                          blurRadius: 15,
                          spreadRadius: 2,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.zero,
                      child: Image.file(
                        File(_printPhotoPath!),
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!_hasPermission) {
      return const Scaffold(backgroundColor: Colors.black);
    }

    // Force night mode for the camera page to ensure white icons on the dark blurred background
    // Use dark grey background before camera initializes so the black capsule is visible
    final bool isNight = true; 
    final Color bgColor = const Color(0xFF272727);

    final screenWidth = MediaQuery.of(context).size.width;
    
    // Viewfinder dimensions
    final viewfinderWidth = screenWidth - 32; // 16 padding on each side
    final viewfinderHeight = _currentRatio == '4:3' ? viewfinderWidth * 4 / 3 : viewfinderWidth;
    
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light.copyWith(
        statusBarColor: Colors.transparent,
        systemNavigationBarColor: Colors.black, // 修复安卓底部的白边
        systemNavigationBarIconBrightness: Brightness.light,
        systemNavigationBarDividerColor: Colors.transparent,
      ),
      child: Stack(
        children: [
          Scaffold(
            backgroundColor: bgColor,
            body: Stack(
              children: [
              // 0. Waterfall Album (Bottom layer, revealed when pushing up)
              if (widget.enableDynamicViewfinder)
                Positioned.fill(
                  child: Visibility(
                    visible: _hasCompletedInitialUnfold,
                    child: NotificationListener<ScrollNotification>(
                      onNotification: (notification) {
                        if (notification is OverscrollNotification) {
                          if (notification.overscroll < 0 && notification.dragDetails != null) {
                            final double dragDelta = notification.dragDetails!.primaryDelta! / 500.0;
                            _unfoldAnimationController.value += dragDelta;
                          }
                        } else if (notification is ScrollUpdateNotification) {
                          if (_unfoldAnimationController.value > 0.0 && notification.dragDetails != null) {
                            final double dragDelta = notification.dragDetails!.primaryDelta! / 500.0;
                            _unfoldAnimationController.value += dragDelta;
                          }
                        } else if (notification is ScrollEndNotification) {
                          if (_unfoldAnimationController.value > 0.0 && _unfoldAnimationController.value < 1.0) {
                            if (_unfoldAnimationController.value > 0.5) {
                              _unfoldAnimationController.forward();
                            } else {
                              _unfoldAnimationController.reverse();
                            }
                          }
                        }
                        return false;
                      },
                      child: WaterfallAlbumGallery(
                        animation: _unfoldCurvedAnimation,
                        viewfinderHeight: viewfinderHeight,
                      ),
                    ),
                  ),
                ),

              // 0.5 Top Fade Bar for Gallery (Smooth fade into background color)
              if (widget.enableDynamicViewfinder)
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  height: 90, // 给定 90px 的渐变空间，拉长过渡距离
                  child: IgnorePointer(
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            bgColor, // 0px
                            bgColor.withValues(alpha: 0.85), // 约 20px (胶囊中上部)
                            bgColor.withValues(alpha: 0.25), // 约 55px (胶囊底部稍下)
                            bgColor.withValues(alpha: 0.0),  // 90px (完全透明)
                          ],
                          stops: const [0.0, 0.2, 0.6, 1.0], // 非线性渐变，模拟真实的物理消融感
                        ),
                      ),
                    ),
                  ),
                ),

              // 1. Blurred Camera Background (Fades out when pushing up)
              if (_isCameraInitialized && _controller != null)
                Positioned.fill(
                  child: AnimatedBuilder(
                    animation: _unfoldAnimationController,
                    builder: (context, child) {
                      final isCollapsed = _unfoldAnimationController.value < 0.01;
                      return Visibility(
                        visible: !isCollapsed,
                        child: IgnorePointer(
                          ignoring: _unfoldAnimationController.value < 0.5,
                          child: child,
                        ),
                      );
                    },
                    child: FadeTransition(
                      opacity: _unfoldAnimationController,
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          // Using raw CameraPreview for the background is lightweight
                          CameraPreview(_controller!),
                          BackdropFilter(
                            filter: ImageFilter.blur(sigmaX: 40.0, sigmaY: 40.0),
                            child: Container(
                              color: Colors.black.withValues(alpha: 0.6), // Dark overlay for contrast
                            ),
                          ),
                        ],
                      ).animate().fadeIn(duration: 800.ms),
                    ),
                  ),
                ),
              // 0.5 Background Gesture Detector for dragging anywhere
              if (widget.enableDynamicViewfinder)
                Positioned.fill(
                  child: AnimatedBuilder(
                    animation: _unfoldAnimationController,
                    builder: (context, child) {
                      return IgnorePointer(
                        ignoring: _unfoldAnimationController.value < 0.5,
                        child: child,
                      );
                    },
                    child: GestureDetector(
                      behavior: HitTestBehavior.translucent,
                      onVerticalDragUpdate: (details) {
                        if (_isPrintingAnimationRunning) return;
                        final double dragDelta = details.primaryDelta! / 500.0;
                        _unfoldAnimationController.value += dragDelta;
                      },
                      onVerticalDragEnd: (details) {
                        if (_isPrintingAnimationRunning) return;
                        final velocity = details.primaryVelocity!;
                        if (velocity > 300) {
                          _unfoldAnimationController.forward();
                        } else if (velocity < -300) {
                          _unfoldAnimationController.reverse();
                        } else {
                          if (_unfoldAnimationController.value > 0.5) {
                            _unfoldAnimationController.forward();
                          } else {
                            _unfoldAnimationController.reverse();
                          }
                        }
                      },
                    ),
                  ),
                ),
              // 1. Dynamic Viewfinder centered
              AnimatedBuilder(
                animation: _unfoldAnimationController,
                builder: (context, child) {
                  final tValue = _unfoldCurvedAnimation.value;
                  final t = widget.enableDynamicViewfinder ? tValue : 1.0;
                  final startTop = 11.0; 
                  final endTop = MediaQuery.of(context).padding.top + 70;
                  final currentTop = widget.enableDynamicViewfinder ? lerpDouble(startTop, endTop, t)! : 0.0;

                  final startWidth = _isPrintingAnimationRunning ? 250.0 : 125.0; // 打印时胶囊变宽
                  final endWidth = viewfinderWidth;
                  final currentWidth = widget.enableDynamicViewfinder ? lerpDouble(startWidth, endWidth, t)! : screenWidth;

                  final startHeight = 37.0; // Dynamic island height
                  final endHeight = viewfinderHeight;
                  final currentHeight = widget.enableDynamicViewfinder ? lerpDouble(startHeight, endHeight, t)! : MediaQuery.of(context).size.height;

                  final startRadius = 18.0;
                  final endRadius = 32.0;
                  final currentRadius = widget.enableDynamicViewfinder ? lerpDouble(startRadius, endRadius, t)! : 0.0;

                  final startBorder = 0.0;
                  final endBorder = 24.0;
                  final currentBorder = widget.enableDynamicViewfinder ? lerpDouble(startBorder, endBorder, t)! : 0.0;

                  final currentLeft = (screenWidth - currentWidth) / 2;

                  double feedOpacity = 1.0;
                  if (widget.enableDynamicViewfinder) {
                    if (_isCameraInitialized && _controller != null) {
                      // 提早淡入相机画面：动画前 50% 的进度中就完成 0 到 1 的透明度过渡
                      feedOpacity = (t * 2.0).clamp(0.0, 1.0);
                    } else {
                      feedOpacity = 0.0;
                    }
                  }

                  return Positioned(
                    top: currentTop,
                    left: currentLeft,
                    width: currentWidth,
                    height: currentHeight,
                    child: GestureDetector(
                      onTap: () {
                        if (!widget.enableDynamicViewfinder || _isPrintingAnimationRunning) return;
                        if (_unfoldAnimationController.value < 0.5) {
                          _unfoldAnimationController.forward();
                        }
                      },
                      onVerticalDragUpdate: (details) {
                        if (!widget.enableDynamicViewfinder || _isPrintingAnimationRunning) return;
                        final double dragDelta = details.primaryDelta! / 500.0;
                        _unfoldAnimationController.value += dragDelta;
                      },
                      onVerticalDragEnd: (details) {
                        if (!widget.enableDynamicViewfinder || _isPrintingAnimationRunning) return;
                        final velocity = details.primaryVelocity!;
                        if (velocity > 300) {
                          // 快速下拉：展开
                          _unfoldAnimationController.forward();
                        } else if (velocity < -300) {
                          // 快速上推：收起
                          _unfoldAnimationController.reverse();
                        } else {
                          // 慢速拖动：根据松手时的位置决定
                          if (_unfoldAnimationController.value > 0.5) {
                            _unfoldAnimationController.forward();
                          } else {
                            _unfoldAnimationController.reverse();
                          }
                        }
                      },
                      child: Container(
                        decoration: BoxDecoration(
                        // The capsule is pure black
                        color: Colors.black, 
                        borderRadius: BorderRadius.circular(currentRadius),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.5 * t),
                            blurRadius: 24,
                            offset: Offset(0, 8 * t),
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(currentRadius),
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            // Fade in camera feed ONLY when capsule is expanding and ready
                            Opacity(
                              opacity: feedOpacity,
                              child: (_isCameraInitialized && _controller != null)
                                  ? CameraViewfinder(
                                      controller: _controller!,
                                      currentRatio: _currentRatio,
                                      watermarkStyle: _watermarkStyle,
                                      showGrid: _showGrid,
                                      isMattingMode: _mattingMode == 'cloud',
                                      isCountingDown: _isCountingDown,
                                      countdownValue: _countdownValue,
                                      focusPoint: _focusPoint,
                                      showExposureSlider: _showExposureSlider,
                                      currentExposure: _currentExposure,
                                      minExposure: _minExposure,
                                      maxExposure: _maxExposure,
                                      focusAnimation: _focusAnimationController,
                                      slideOutPath: _slideOutPath,
                                      slideOutAnimation: _slideOutAnimation,
                                      colorMatrix: _calculateColorMatrix(),
                                      colorFilter: _getCurrentColorFilter(),
                                      onTapToFocus: _handleTapToFocus,
                                      onScaleStart: (details) {
                                        _baseZoom = _currentZoom;
                                      },
                                      onScaleUpdate: (details) {
                                        if (_controller == null || !_controller!.value.isInitialized) return;
                                        if (_zoomAnimationController.isAnimating) _zoomAnimationController.stop();
                                        final targetZoom = (_baseZoom * details.scale).clamp(_minZoom, _maxZoom);
                                        _controller!.setZoomLevel(targetZoom);
                                        setState(() {
                                          _currentZoom = targetZoom;
                                          _targetZoom = targetZoom;
                                        });
                                      },
                                      onExposureChanged: (val) {
                                        setState(() => _currentExposure = val);
                                        _controller?.setExposureOffset(val);
                                      },
                                    )
                                  : const SizedBox(),
                            ),
                            // Border overlay to cover any gaps
                            Container(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(currentRadius),
                                border: Border.all(
                                  color: Colors.black,
                                  width: currentBorder,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      ),
                    ),
                  );
                },
              ),              if (!widget.enableDynamicViewfinder) ...[


                // Top Gradient for Top Bar
              Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  height: MediaQuery.of(context).padding.top + 100,
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.black.withValues(alpha: 0.6),
                          Colors.transparent,
                        ],
                      ),
                    ),
                  ),
                ),
                // Bottom Gradient for Zoom and Bottom Controls
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  height: 280,
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.bottomCenter,
                        end: Alignment.topCenter,
                        colors: [
                          Colors.black.withValues(alpha: 0.8),
                          Colors.black.withValues(alpha: 0.4),
                          Colors.transparent,
                        ],
                      ),
                    ),
                  ),
                ),
              ],

              // 1.5 Zoom Controls (Capsules below viewfinder)
              Positioned(
                top: widget.enableDynamicViewfinder ? MediaQuery.of(context).padding.top + 70 + viewfinderHeight + 20 : null,
                bottom: widget.enableDynamicViewfinder ? null : 160,
                left: 0,
                right: 0,
                child: AnimatedBuilder(
                  animation: _unfoldAnimationController,
                  builder: (context, child) {
                    return IgnorePointer(
                      ignoring: _unfoldAnimationController.value < 0.5,
                      child: child,
                    );
                  },
                  child: FadeTransition(
                    opacity: _unfoldAnimationController,
                    child: SlideTransition(
                      position: Tween<Offset>(begin: const Offset(0, 0.5), end: Offset.zero).animate(
                        CurvedAnimation(parent: _unfoldAnimationController, curve: Curves.easeOutQuad),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                    children: _availableZoomLevels.map((zoom) {
                      final isSelected = (_targetZoom - zoom).abs() < 0.1;
                      return GestureDetector(
                        onTap: () {
                          if (_controller == null || !_controller!.value.isInitialized) return;
                          if ((_currentZoom - zoom).abs() < 0.01) return;
                          
                          setState(() {
                            _targetZoom = zoom;
                          });
                          
                          _zoomAnimation = Tween<double>(begin: _currentZoom, end: zoom).animate(
                            CurvedAnimation(parent: _zoomAnimationController, curve: Curves.easeOutQuad),
                          );
                          _zoomAnimationController.forward(from: 0.0);
                          
                          HapticFeedback.lightImpact();
                        },
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          margin: const EdgeInsets.symmetric(horizontal: 8),
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(
                            color: isSelected 
                                ? Colors.white24
                                : Colors.white10,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: AnimatedDefaultTextStyle(
                            duration: const Duration(milliseconds: 200),
                            style: TextStyle(
                              color: isSelected ? Colors.white : Colors.white54,
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                              fontSize: 14,
                              fontFamily: 'LXGWWenKai',
                            ),
                            child: Text('${zoom == 1.0 || zoom % 1 == 0 ? zoom.toInt() : zoom}x'),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ),
                ),
              ),

              // 2. 悬浮顶栏
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: AnimatedBuilder(
                  animation: _unfoldAnimationController,
                  builder: (context, child) {
                    return IgnorePointer(
                      ignoring: _unfoldAnimationController.value < 0.5,
                      child: child,
                    );
                  },
                  child: FadeTransition(
                    opacity: _unfoldAnimationController,
                    child: CameraTopBar(
                      isNight: isNight,
                      currentFlashMode: _currentFlashMode,
                      showGrid: _showGrid,
                      selfTimerSeconds: _selfTimerSeconds,
                      onClose: () => Navigator.pop(context),
                      onToggleFlash: _toggleFlashMode,
                      onToggleGrid: () => setState(() => _showGrid = !_showGrid),
                      onToggleSelfTimer: _toggleSelfTimer,
                    ),
                  ),
                ),
              ),

              // 3. 悬浮底栏
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: AnimatedBuilder(
                  animation: _unfoldAnimationController,
                  builder: (context, child) {
                    return IgnorePointer(
                      ignoring: _unfoldAnimationController.value < 0.5,
                      child: child,
                    );
                  },
                  child: FadeTransition(
                    opacity: _unfoldAnimationController,
                    child: CameraBottomControls(
                      isNight: isNight,
                      mattingMode: _mattingMode,
                      shutterAnimation: _shutterAnimationController,
                      onToggleMatting: () => setState(() {
                        _mattingMode = _mattingMode == 'none' ? 'cloud' : 'none';
                      }),
                      onTakePicture: _takePicture,
                      onToggleCamera: _toggleCamera,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        if (_previewPath != null)
          CameraEditOverlay(
            isFromAlbum: widget.initialImagePath != null,
            capturedRawPath: _capturedRawPath!,
            initialMattedPath: _cachedMattedPath,
            initialRatio: _currentRatio,
            initialWatermarkStyle: _watermarkStyle,
            initialFilter: _currentFilter,
            initialAdjustParams: _adjustParams,
            initialMattingMode: _mattingMode,
            isTransitioning: _isPrintingAnimationRunning, // 在放大动画期间隐藏自带的照片
            onReTake: () {
              if (widget.initialImagePath != null) {
                Navigator.pop(context);
              } else {
                setState(() {
                  _previewPath = null;
                  _tempCapturedPaths.clear();
                  _cachedMattedPath = null;
                });
              }
            },
            onConfirm: (editedPath, mattedPath) {
              Navigator.pop(context, {
                'editedPath': editedPath,
                'mattedPath': mattedPath,
              });
            },
          ),
        
        // 0.5 The printing photo (Animated Polaroid sliding out) - Kept in outer Stack to prevent Image widget reload
        if (_isPrintingAnimationRunning && _printPhotoPath != null)
          _buildPrintingPhoto(context),
      ],
    ),
    );
  }





}

