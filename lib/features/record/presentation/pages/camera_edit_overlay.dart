import 'dart:io';
import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:island_diary/core/state/user_state.dart';
import 'package:island_diary/shared/widgets/top_toast.dart';
// ignore: depend_on_referenced_packages
import 'package:photo_manager/photo_manager.dart';
import '../utils/camera_image_processor.dart';
import '../utils/camera_matting_processor.dart';
import 'custom_camera_painters.dart';

class CameraEditOverlay extends StatefulWidget {
  final bool isFromAlbum;
  final String capturedRawPath;
  final String? initialMattedPath;
  final String initialRatio;
  final String initialWatermarkStyle;
  final String initialFilter;
  final Map<String, double> initialAdjustParams;
  final String initialMattingMode;
  final VoidCallback onReTake;
  final Function(String editedPath, String? mattedPath) onConfirm;

  const CameraEditOverlay({
    super.key,
    required this.isFromAlbum,
    required this.capturedRawPath,
    this.initialMattedPath,
    required this.initialRatio,
    required this.initialWatermarkStyle,
    required this.initialFilter,
    required this.initialAdjustParams,
    required this.initialMattingMode,
    required this.onReTake,
    required this.onConfirm,
  });

  @override
  State<CameraEditOverlay> createState() => _CameraEditOverlayState();
}

class _CameraEditOverlayState extends State<CameraEditOverlay>
    with TickerProviderStateMixin {
  late String _capturedRawPath;
  String? _previewPath;
  String? _cachedMattedPath;

  late String _currentRatio;
  late String _watermarkStyle;
  late String _currentFilter;
  late Map<String, double> _adjustParams;
  late String _mattingMode;
  Rect _normalizedCropRect = const Rect.fromLTWH(0, 0, 1, 1);
  Rect _activeCropBoxRect = const Rect.fromLTWH(0, 0, 1, 1);

  String _mosaicMode = 'none';
  double _strokeWidth = 0.0;
  Color _strokeColor = Colors.white;
  String _strokeStyle = 'solid'; // 'solid', 'glow', 'stars'
  double _strokeDistance = 6.0;

  ui.Image? _previewUiImage;
  List<ContourPoint> _contourPoints = [];

  String _currentSubPanel = 'ratio';
  String _selectedAdjustKey = 'exposure';

  late AnimationController _slideInController;
  late Animation<Offset> _slideInAnimation;
  late AnimationController _strokeAnimationController;

  final List<Map<String, dynamic>> _adjustItems = [
    {
      'key': 'exposure',
      'name': '曝光',
      'icon': Icons.exposure_rounded,
      'min': -1.0,
      'max': 1.0,
    },
    {
      'key': 'highlights',
      'name': '高光',
      'icon': Icons.filter_hdr_rounded,
      'min': -1.0,
      'max': 1.0,
    },
    {
      'key': 'shadows',
      'name': '阴影',
      'icon': Icons.wb_twilight_rounded,
      'min': -1.0,
      'max': 1.0,
    },
    {
      'key': 'brightness',
      'name': '亮度',
      'icon': Icons.light_mode_rounded,
      'min': -1.0,
      'max': 1.0,
    },
    {
      'key': 'contrast',
      'name': '对比度',
      'icon': Icons.contrast_rounded,
      'min': -1.0,
      'max': 1.0,
    },
    {
      'key': 'whites',
      'name': '亮部',
      'icon': Icons.brightness_high_rounded,
      'min': -1.0,
      'max': 1.0,
    },
    {
      'key': 'blacks',
      'name': '暗部',
      'icon': Icons.brightness_low_rounded,
      'min': -1.0,
      'max': 1.0,
    },
    {
      'key': 'saturation',
      'name': '饱和度',
      'icon': Icons.palette_rounded,
      'min': -1.0,
      'max': 1.0,
    },
    {
      'key': 'vibrance',
      'name': '自然饱和度',
      'icon': Icons.color_lens_rounded,
      'min': -1.0,
      'max': 1.0,
    },
    {
      'key': 'temp',
      'name': '色温',
      'icon': Icons.device_thermostat_rounded,
      'min': -1.0,
      'max': 1.0,
    },
    {
      'key': 'sharpness',
      'name': '锐度',
      'icon': Icons.details_rounded,
      'min': 0.0,
      'max': 1.0,
    },
    {
      'key': 'fade',
      'name': '褪色',
      'icon': Icons.blur_linear_rounded,
      'min': 0.0,
      'max': 1.0,
    },
  ];

  @override
  void initState() {
    super.initState();
    _capturedRawPath = widget.capturedRawPath;
    _currentRatio = 'free';
    _watermarkStyle = widget.initialWatermarkStyle;
    _currentFilter = widget.initialFilter;
    _adjustParams = Map<String, double>.from(widget.initialAdjustParams);
    _mattingMode = widget.initialMattingMode;

    if (widget.initialMattedPath != null) {
      _cachedMattedPath = widget.initialMattedPath;
    } else if (_isTransparentPng(_capturedRawPath)) {
      _cachedMattedPath = _capturedRawPath;
    }

    final bool hasMatted =
        _cachedMattedPath != null && File(_cachedMattedPath!).existsSync();
    if (hasMatted) {
      _previewPath = _cachedMattedPath;
      _mattingMode = 'cloud';
      _loadPreviewUiImage(_cachedMattedPath!);
    } else {
      _previewPath = _capturedRawPath;
      _loadPreviewUiImage(_capturedRawPath);
    }

    _slideInController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
    );
    _slideInAnimation =
        Tween<Offset>(begin: const Offset(-1.5, 0.0), end: Offset.zero).animate(
          CurvedAnimation(
            parent: _slideInController,
            curve: Curves.easeOutBack,
          ),
        );

    _strokeAnimationController =
        AnimationController(
          vsync: this,
          duration: const Duration(milliseconds: 800),
        )..addListener(() {
          setState(() {});
        });

    _slideInController.value = 1.0; // 默认展示完，若有转场可以直接播放
  }

  @override
  void dispose() {
    _slideInController.dispose();
    _strokeAnimationController.dispose();
    super.dispose();
  }

  bool _isTransparentPng(String path) {
    try {
      final file = File(path);
      if (!file.existsSync()) return false;
      if (path.toLowerCase().endsWith('.png')) return true;
      final bytes = file.readAsBytesSync();
      if (bytes.length < 4) return false;
      if (bytes[0] == 0x89 &&
          bytes[1] == 0x50 &&
          bytes[2] == 0x4E &&
          bytes[3] == 0x47) {
        return true;
      }
      return false;
    } catch (e) {
      debugPrint("检测 PNG 透明通道异常: $e");
      return false;
    }
  }

  Future<void> _loadPreviewUiImage(String path) async {
    try {
      final bytes = await File(path).readAsBytes();
      final ui.Codec codec = await ui.instantiateImageCodec(bytes);
      final ui.FrameInfo frameInfo = await codec.getNextFrame();
      if (mounted) {
        final img = frameInfo.image;
        final pts = await CameraImageProcessor.extractContourPoints(img);
        setState(() {
          _previewUiImage = img;
          _contourPoints = pts;
          if (_mattingMode == 'cloud' && pts.isEmpty) {
            _mattingMode = 'none';
            _cachedMattedPath = null;
            _previewPath = _capturedRawPath;
          }
        });
      }
    } catch (e) {
      debugPrint("加载预览 ui.Image 失败: $e");
    }
  }

  void _resetAllOptions() {
    setState(() {
      _currentRatio = 'free';
      _watermarkStyle = 'none';
      _currentFilter = 'auto';
      _mosaicMode = 'none';
      _strokeWidth = 0.0;
      _strokeColor = Colors.white;
      _strokeStyle = 'solid';
      _strokeDistance = 6.0;
      _normalizedCropRect = const Rect.fromLTWH(0, 0, 1, 1);
      _activeCropBoxRect = const Rect.fromLTWH(0, 0, 1, 1);
      
      _adjustParams.forEach((key, value) {
        _adjustParams[key] = 0.0;
      });
      
      _mattingMode = 'none';
      _previewPath = _capturedRawPath;
    });
    _loadPreviewUiImage(_capturedRawPath);
  }


  Future<bool> _runCloudMattingInPreview() async {
    if (_cachedMattedPath != null && File(_cachedMattedPath!).existsSync()) {
      setState(() {
        _previewPath = _cachedMattedPath;
        _mattingMode = 'cloud';
      });
      await _loadPreviewUiImage(_cachedMattedPath!);
      return true;
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Center(
        child: Card(
          color: Colors.black87,
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 24.0,
              vertical: 16.0,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: const [
                CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFD4A373)),
                ),
                SizedBox(height: 12),
                Text(
                  '云端AI高清抠图中...',
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
      final mattedPath = await CameraMattingProcessor.processCloudMatting(
        _capturedRawPath,
      );
      if (mounted) {
        Navigator.pop(context);
        if (mattedPath == _capturedRawPath) {
          showTopToast(
            context,
            '智能抠像额度已用完，暂使用原图',
            icon: Icons.warning_amber_rounded,
            iconColor: const Color(0xFFD4A373),
          );
          return false;
        } else {
          setState(() {
            _previewPath = mattedPath;
            _mattingMode = 'cloud';
            _cachedMattedPath = mattedPath;
          });
          await _loadPreviewUiImage(mattedPath);
          return true;
        }
      }
      return false;
    } catch (e) {
      debugPrint("抠图错误: $e");
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              '抠图失败，请重试',
              style: TextStyle(fontFamily: 'LXGWWenKai'),
            ),
          ),
        );
      }
      return false;
    }
  }

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

    double factor = 1.0 + con;
    rMult *= factor;
    gMult *= factor;
    bMult *= factor;
    double conOffset = 128.0 * (1.0 - factor);
    rOffset += conOffset;
    gOffset += conOffset;
    bOffset += conOffset;

    rMult *= (1.0 - fd * 0.2);
    gMult *= (1.0 - fd * 0.2);
    bMult *= (1.0 - fd * 0.2);
    rOffset += fd * 45.0;
    gOffset += fd * 45.0;
    bOffset += fd * 45.0;

    if (shp > 0) {
      rMult *= (1.0 + shp);
      gMult *= (1.0 + shp);
      bMult *= (1.0 + shp);
      rOffset -= shp * 20;
      gOffset -= shp * 20;
      bOffset -= shp * 20;
    }

    double sat =
        1.0 +
        _adjustParams['saturation']! * 0.6 +
        _adjustParams['vibrance']! * 0.3;
    sat = sat.clamp(0.0, 2.0);

    final double invSat = 1.0 - sat;
    final double rWeight = 0.2126 * invSat;
    final double gWeight = 0.7152 * invSat;
    final double bWeight = 0.0722 * invSat;

    return [
      rMult * (rWeight + sat),
      gMult * rWeight,
      bMult * rWeight,
      0,
      rOffset,
      rMult * gWeight,
      gMult * (gWeight + sat),
      bMult * gWeight,
      0,
      gOffset,
      rMult * bWeight,
      gMult * bWeight,
      bMult * (bWeight + sat),
      0,
      bOffset,
      0,
      0,
      0,
      1,
      0,
    ];
  }

  ColorFilter _getCurrentColorFilter() {
    if (_currentFilter == 'warm') {
      return ColorFilter.mode(
        Colors.orange.withValues(alpha: 0.08),
        BlendMode.softLight,
      );
    } else if (_currentFilter == 'cool') {
      return ColorFilter.mode(
        Colors.blue.withValues(alpha: 0.08),
        BlendMode.softLight,
      );
    } else if (_currentFilter == 'retro') {
      return ColorFilter.mode(
        Colors.brown.withValues(alpha: 0.12),
        BlendMode.softLight,
      );
    }
    return const ColorFilter.matrix([
      1,
      0,
      0,
      0,
      0,
      0,
      1,
      0,
      0,
      0,
      0,
      0,
      1,
      0,
      0,
      0,
      0,
      0,
      1,
      0,
    ]);
  }

  @override
  Widget build(BuildContext context) {
    if (_previewPath == null) return const SizedBox.shrink();

    return Positioned.fill(
      child: Material(
        color: Colors.black,
        child: SafeArea(
          child: Column(
            children: [
              // 1. 顶部栏 (退出/编辑照片)
              Container(
                padding: const EdgeInsets.symmetric(
                  vertical: 8,
                  horizontal: 16,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      icon: const Icon(
                        Icons.close,
                        color: Colors.white,
                        size: 26,
                      ),
                      onPressed: () {
                        try {
                          File(_previewPath!).deleteSync();
                        } catch (_) {}
                        if (_cachedMattedPath != null &&
                            _cachedMattedPath != _previewPath) {
                          try {
                            File(_cachedMattedPath!).deleteSync();
                          } catch (_) {}
                        }
                        widget.onReTake();
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
                      icon: const Icon(
                        Icons.download_rounded,
                        color: Colors.white,
                        size: 26,
                      ),
                      onPressed: () async {
                        HapticFeedback.mediumImpact();
                        showDialog(
                          context: context,
                          barrierDismissible: false,
                          builder: (context) => Center(
                            child: Card(
                              color: Colors.black87,
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 24.0,
                                  vertical: 16.0,
                                ),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: const [
                                    CircularProgressIndicator(
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                        Color(0xFFD4A373),
                                      ),
                                    ),
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
                          final finalResultPath =
                              await CameraImageProcessor.processSingleImage(
                                imagePath: _capturedRawPath,
                                ratio: _currentRatio,
                                watermarkStyle: _watermarkStyle,
                                filterName: _currentFilter,
                                mosaicMode: _mosaicMode,
                                colorMatrix: _calculateColorMatrix(),
                                strokeWidth: _strokeWidth,
                                strokeColor: _strokeColor,
                                strokeStyle: _strokeStyle,
                                strokeDistance: _strokeDistance,
                              );

                          final PermissionState ps =
                              await PhotoManager.requestPermissionExtend();
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

                          final AssetEntity?
                          asset = await PhotoManager.editor.saveImageWithPath(
                            finalResultPath,
                            title:
                                'diary_cam_${DateTime.now().millisecondsSinceEpoch}.png',
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

              // 2. 中间照片预览区
              Expanded(
                child: ClipRect(
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: LayoutBuilder(
                        builder: (context, constraints) {
                          if (_previewUiImage == null) {
                            return const Center(
                              child: CircularProgressIndicator(
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  Color(0xFFD4A373),
                                ),
                              ),
                            );
                          }
                          final bool isPolaroid = _watermarkStyle == 'polaroid';
                          final bool isBlurBorder =
                              _watermarkStyle == 'blur_border';

                          double previewAspect = 1.0;
                          double imgAspect = 1.0;
                          if (_previewUiImage != null) {
                            imgAspect =
                                _previewUiImage!.width /
                                _previewUiImage!.height;
                          }

                          if (_currentSubPanel == 'ratio') {
                            previewAspect = imgAspect;
                          } else {
                            previewAspect =
                                (_normalizedCropRect.width /
                                    _normalizedCropRect.height) *
                                imgAspect;
                          }

                          final double maxW = constraints.maxWidth;
                          double maxH = constraints.maxHeight;
                          if (isPolaroid) {
                            maxH -= 44.0;
                          } else if (isBlurBorder) {
                            maxH = constraints.maxHeight / 1.15;
                          }

                          double displayW = maxW;
                          double displayH = maxW / previewAspect;
                          if (displayH > maxH) {
                            displayH = maxH;
                            displayW = maxH * previewAspect;
                          }

                          double extraHeight = 0.0;
                          if (isPolaroid) {
                            extraHeight = 44.0;
                          } else if (isBlurBorder) {
                            extraHeight = displayH * 0.15;
                          }

                          final bool isRatioMode = _currentSubPanel == 'ratio';
                          if (isRatioMode) {
                            displayW = maxW;
                            displayH = maxH;
                            extraHeight = 0.0;
                          }

                          double margin = displayW * 0.04;
                          double imgScale = (displayW - margin * 2) / displayW;
                          double fgW = (isBlurBorder || isRatioMode)
                              ? (displayW - margin * 2)
                              : displayW;
                          double fgH = (isBlurBorder || isRatioMode)
                              ? (displayH * imgScale)
                              : displayH;

                          final double topPos = (isBlurBorder || isRatioMode)
                              ? (displayH - fgH) / 2
                              : 0.0;
                          final double leftPos = (isBlurBorder || isRatioMode)
                              ? (displayW - fgW) / 2
                              : 0.0;

                          final Widget mainContent = AnimatedContainer(
                            duration: _currentSubPanel == 'ratio'
                                ? Duration.zero
                                : const Duration(milliseconds: 300),
                            curve: Curves.easeInOut,
                            color:
                                (_mattingMode == 'cloud' ||
                                    _currentSubPanel == 'ratio')
                                ? Colors.transparent
                                : const Color(0xFF1E1E1E),
                            width: displayW,
                            height: displayH + extraHeight,
                            child: Stack(
                              clipBehavior: isRatioMode
                                  ? Clip.none
                                  : Clip.hardEdge,
                              children: [
                                if (isBlurBorder)
                                  Positioned.fill(
                                    child: Image.file(
                                      File(_capturedRawPath),
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                if (isBlurBorder)
                                  Positioned.fill(
                                    child: ClipRect(
                                      child: BackdropFilter(
                                        filter: ui.ImageFilter.blur(
                                          sigmaX: 25.0,
                                          sigmaY: 25.0,
                                        ),
                                        child: Container(
                                          color: Colors.black.withValues(
                                            alpha: 0.15,
                                          ),
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

                                 AnimatedPositioned(
                                  duration: _currentSubPanel == 'ratio'
                                      ? Duration.zero
                                      : const Duration(milliseconds: 300),
                                  curve: Curves.easeInOut,
                                  top: topPos,
                                  left: leftPos,
                                  width: fgW,
                                  height: fgH,
                                  child: SlideTransition(
                                    position: _slideInAnimation,
                                    child: isRatioMode
                                        ? _buildStrokedPreviewImage(
                                            imagePath: _capturedRawPath,
                                            strokeWidth: _strokeWidth,
                                            strokeColor: _strokeColor,
                                            fgW: fgW,
                                            fgH: fgH,
                                          )
                                        : ClipRRect(
                                            borderRadius: isBlurBorder
                                                ? BorderRadius.circular(4)
                                                : BorderRadius.zero,
                                            child: _buildStrokedPreviewImage(
                                              imagePath: _capturedRawPath,
                                              strokeWidth: _strokeWidth,
                                              strokeColor: _strokeColor,
                                              fgW: fgW,
                                              fgH: fgH,
                                            ),
                                          ),
                                  ),
                                ),

                                if (_currentSubPanel == 'ratio')
                                  Positioned(
                                    top: topPos - 24.0,
                                    left: leftPos - 24.0,
                                    width: fgW + 48.0,
                                    height: fgH + 48.0,
                                    child: InteractiveCropOverlay(
                                      width: fgW,
                                      height: fgH,
                                      imgAspect: imgAspect,
                                      ratio: _currentRatio,
                                      initialCropRect: _normalizedCropRect,
                                      onCropRectChanged: (cropBox, normalized) {
                                        setState(() {
                                          _activeCropBoxRect = cropBox;
                                          _normalizedCropRect = normalized;
                                        });
                                      },
                                    ),
                                  ),

                                _buildConfirmPageWatermark(
                                  displayW,
                                  displayH,
                                  extraHeight,
                                ),
                              ],
                            ),
                          );

                          if (isRatioMode) {
                            return mainContent;
                          } else {
                            return ClipRRect(
                              borderRadius: BorderRadius.circular(16),
                              child: mainContent,
                            );
                          }
                        },
                      ),
                    ),
                  ),
                ),
              ),

              // 3. 编辑子面板
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                height: _currentSubPanel == 'stroke'
                    ? 208.0
                    : (_currentSubPanel == 'adjust' ? 96.0 : 52.0),
                padding: const EdgeInsets.symmetric(horizontal: 16),
                alignment: Alignment.center,
                child: ClipRect(child: _buildSubPanel()),
              ),

              const Divider(color: Colors.white10, height: 1, thickness: 0.5),
              const SizedBox(height: 12),

              // 4. 一级参数分类菜单
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildCategoryItem('ratio', Icons.crop_rounded, '裁剪'),
                    _buildCategoryItem('adjust', Icons.tune_rounded, '调节'),
                    _buildCategoryItem(
                      'filter',
                      Icons.color_lens_rounded,
                      '滤镜',
                    ),
                    _buildCategoryItem(
                      'watermark',
                      Icons.closed_caption_rounded,
                      '水印',
                    ),
                    _buildCategoryItem(
                      'stroke',
                      Icons.border_outer_rounded,
                      '描边',
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 12),

              // 5. 底部操作按钮
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24.0,
                  vertical: 12.0,
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () {
                          if (widget.isFromAlbum) {
                            _resetAllOptions();
                          } else {
                            try {
                              File(_previewPath!).deleteSync();
                            } catch (_) {}
                            if (_cachedMattedPath != null &&
                                _cachedMattedPath != _previewPath) {
                              try {
                                File(_cachedMattedPath!).deleteSync();
                              } catch (_) {}
                            }
                            widget.onReTake();
                          }
                          HapticFeedback.mediumImpact();
                        },
                        icon: const Icon(
                          Icons.refresh_rounded,
                          color: Colors.white70,
                        ),
                        label: Text(
                          widget.isFromAlbum ? '重置' : '重拍',
                          style: const TextStyle(
                            color: Colors.white70,
                            fontFamily: 'LXGWWenKai',
                            fontSize: 16,
                          ),
                        ),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(
                            color: Colors.white30,
                            width: 1.5,
                          ),
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
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 24.0,
                                    vertical: 16.0,
                                  ),
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: const [
                                      CircularProgressIndicator(
                                        valueColor:
                                            AlwaysStoppedAnimation<Color>(
                                              Color(0xFFD4A373),
                                            ),
                                      ),
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
                            final finalResultPath =
                                await CameraImageProcessor.processSingleImage(
                                  imagePath: _previewPath!,
                                  ratio: _currentRatio,
                                  watermarkStyle: _watermarkStyle,
                                  filterName: _currentFilter,
                                  mosaicMode: _mosaicMode,
                                  colorMatrix: _calculateColorMatrix(),
                                  strokeWidth: _strokeWidth,
                                  strokeColor: _strokeColor,
                                  strokeStyle: _strokeStyle,
                                  strokeDistance: _strokeDistance,
                                  normalizedCropRect: _normalizedCropRect,
                                );
                            if (mounted) {
                              Navigator.pop(context);
                              widget.onConfirm(
                                finalResultPath,
                                _mattingMode == 'cloud'
                                    ? _cachedMattedPath
                                    : null,
                              );
                            }
                          } catch (e) {
                            debugPrint("图像处理失败: $e");
                            if (mounted) {
                              Navigator.pop(context);
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    '图片处理失败，请重试',
                                    style: TextStyle(fontFamily: 'LXGWWenKai'),
                                  ),
                                ),
                              );
                            }
                          }
                        },
                        icon: const Icon(
                          Icons.check_rounded,
                          color: Colors.white,
                        ),
                        label: const Text(
                          '确认使用',
                          style: TextStyle(
                            color: Colors.white,
                            fontFamily: 'LXGWWenKai',
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
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
    );
  }

  Widget _buildCategoryItem(String panel, IconData icon, String label) {
    final bool isSelected = panel == 'matting'
        ? (_mattingMode == 'cloud')
        : (_currentSubPanel == panel);
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
          if (panel == 'stroke') {
            _strokeAnimationController.forward(from: 0.0);
          }
        }
        HapticFeedback.lightImpact();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected
              ? Colors.white.withValues(alpha: 0.08)
              : Colors.transparent,
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

  Widget _buildSubPanel() {
    Widget content;
    switch (_currentSubPanel) {
      case 'ratio':
        content = SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildRatioButton('free'),
              const SizedBox(width: 12),
              _buildRatioButton('1:1'),
              const SizedBox(width: 12),
              _buildRatioButton('4:3'),
              const SizedBox(width: 12),
              _buildRatioButton('3:4'),
              const SizedBox(width: 12),
              _buildRatioButton('16:9'),
              const SizedBox(width: 12),
              _buildRatioButton('9:16'),
            ],
          ),
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
        final activeItem = _adjustItems.firstWhere(
          (item) => item['key'] == _selectedAdjustKey,
        );
        content = SingleChildScrollView(
          physics: const NeverScrollableScrollPhysics(),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                height: 36,
                child: Row(
                  children: [
                    const SizedBox(width: 8),
                    Text(
                      '${activeItem['name']}',
                      style: const TextStyle(
                        color: Color(0xFFD4A373),
                        fontSize: 11,
                        fontFamily: 'LXGWWenKai',
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: SliderTheme(
                        data: SliderTheme.of(context).copyWith(
                          trackHeight: 2,
                          thumbShape: const RoundSliderThumbShape(
                            enabledThumbRadius: 6,
                          ),
                          activeTrackColor: const Color(0xFFD4A373),
                          inactiveTrackColor: Colors.white24,
                          thumbColor: const Color(0xFFD4A373),
                          valueIndicatorColor: const Color(0xFFD4A373),
                          valueIndicatorTextStyle: const TextStyle(
                            color: Colors.black,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        child: Slider(
                          value: _adjustParams[_selectedAdjustKey] ?? 0.0,
                          min: activeItem['min'] as double,
                          max: activeItem['max'] as double,
                          label: (_adjustParams[_selectedAdjustKey] ?? 0.0)
                              .toStringAsFixed(1),
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
                      (_adjustParams[_selectedAdjustKey] ?? 0.0)
                          .toStringAsFixed(1),
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 11,
                        fontFamily: 'LXGWWenKai',
                      ),
                    ),
                    const SizedBox(width: 8),
                  ],
                ),
              ),
              const SizedBox(height: 4),
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
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? const Color(
                                    0xFFD4A373,
                                  ).withValues(alpha: 0.15)
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: isSelected
                                  ? const Color(0xFFD4A373)
                                  : Colors.white12,
                              width: 1,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                item['icon'] as IconData,
                                size: 14,
                                color: isSelected
                                    ? const Color(0xFFD4A373)
                                    : Colors.white54,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                item['name'] as String,
                                style: TextStyle(
                                  color: isSelected
                                      ? const Color(0xFFD4A373)
                                      : Colors.white54,
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
              SizedBox(
                height: 62,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _buildStrokeStyleCard('none', '原图'),
                    const SizedBox(width: 12),
                    _buildStrokeStyleCard('solid', '实线'),
                    const SizedBox(width: 12),
                    _buildStrokeStyleCard('glow', '发光'),
                    const SizedBox(width: 12),
                    _buildStrokeStyleCard('stars', '星光'),
                  ],
                ),
              ),
              const SizedBox(height: 4),
              SizedBox(
                height: 36,
                child: Row(
                  children: [
                    const SizedBox(width: 8),
                    const Text(
                      '粗细',
                      style: TextStyle(
                        color: Color(0xFFD4A373),
                        fontSize: 11,
                        fontFamily: 'LXGWWenKai',
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: SliderTheme(
                        data: SliderTheme.of(context).copyWith(
                          trackHeight: 2,
                          thumbShape: const RoundSliderThumbShape(
                            enabledThumbRadius: 6,
                          ),
                          activeTrackColor: _mattingMode == 'cloud'
                              ? const Color(0xFFD4A373)
                              : Colors.white24,
                          inactiveTrackColor: Colors.white10,
                          thumbColor: _mattingMode == 'cloud'
                              ? const Color(0xFFD4A373)
                              : Colors.white24,
                          valueIndicatorColor: const Color(0xFFD4A373),
                          valueIndicatorTextStyle: const TextStyle(
                            color: Colors.black,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        child: Slider(
                          value: _strokeWidth,
                          min: 0.0,
                          max: 15.0,
                          label: _strokeWidth.toStringAsFixed(1),
                          divisions: 15,
                          onChanged: _mattingMode == 'cloud'
                              ? (val) {
                                  setState(() {
                                    _strokeWidth = val;
                                  });
                                }
                              : null,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      _strokeWidth.toStringAsFixed(1),
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 11,
                        fontFamily: 'LXGWWenKai',
                      ),
                    ),
                    const SizedBox(width: 8),
                  ],
                ),
              ),
              const SizedBox(height: 4),
              SizedBox(
                height: 36,
                child: Row(
                  children: [
                    const SizedBox(width: 8),
                    const Text(
                      '距离',
                      style: TextStyle(
                        color: Color(0xFFD4A373),
                        fontSize: 11,
                        fontFamily: 'LXGWWenKai',
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: SliderTheme(
                        data: SliderTheme.of(context).copyWith(
                          trackHeight: 2,
                          thumbShape: const RoundSliderThumbShape(
                            enabledThumbRadius: 6,
                          ),
                          activeTrackColor: _mattingMode == 'cloud'
                              ? const Color(0xFFD4A373)
                              : Colors.white24,
                          inactiveTrackColor: Colors.white10,
                          thumbColor: _mattingMode == 'cloud'
                              ? const Color(0xFFD4A373)
                              : Colors.white24,
                          valueIndicatorColor: const Color(0xFFD4A373),
                          valueIndicatorTextStyle: const TextStyle(
                            color: Colors.black,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        child: Slider(
                          value: _strokeDistance,
                          min: 0.0,
                          max: 30.0,
                          label: _strokeDistance.toStringAsFixed(1),
                          divisions: 30,
                          onChanged: _mattingMode == 'cloud'
                              ? (val) {
                                  setState(() {
                                    _strokeDistance = val;
                                  });
                                }
                              : null,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      _strokeDistance.toStringAsFixed(1),
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 11,
                        fontFamily: 'LXGWWenKai',
                      ),
                    ),
                    const SizedBox(width: 8),
                  ],
                ),
              ),
              const SizedBox(height: 4),
              SizedBox(
                height: 48,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildStrokeColorOption(Colors.white),
                      _buildStrokeColorOption(Colors.black),
                      _buildStrokeColorOption(const Color(0xFFD4A373)),
                      _buildStrokeColorOption(const Color(0xFFFF69B4)),
                      _buildStrokeColorOption(const Color(0xFF8A2BE2)),
                      _buildStrokeColorOption(const Color(0xFF00FF7F)),
                      _buildStrokeColorOption(const Color(0xFF00FFFF)),
                      _buildStrokeColorOption(const Color(0xFFFFD700)),
                      _buildStrokeColorOption(Colors.redAccent),
                      _buildStrokeColorOption(Colors.blueAccent),
                    ],
                  ),
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
      default:
        content = const SizedBox.shrink();
    }

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 150),
      child: Container(key: ValueKey<String>(_currentSubPanel), child: content),
    );
  }

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
          color: isSelected
              ? const Color(0xFFD4A373).withValues(alpha: 0.15)
              : Colors.transparent,
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

  Widget _buildStrokeColorOption(Color color) {
    final bool isSelected = _strokeColor == color && _mattingMode == 'cloud';
    return GestureDetector(
      onTap: () {
        if (_mattingMode != 'cloud') return;
        setState(() {
          _strokeColor = color;
        });
        HapticFeedback.lightImpact();
      },
      child: Container(
        width: 24,
        height: 24,
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
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
      ),
    );
  }

  Widget _buildStrokeStyleCard(String style, String label) {
    final bool isSelected =
        (style == 'none' && _mattingMode == 'none') ||
        (_strokeStyle == style && _mattingMode == 'cloud');
    return GestureDetector(
      onTap: () async {
        if (style == 'none') {
          setState(() {
            _strokeStyle = 'none';
            _mattingMode = 'none';
            _strokeWidth = 0.0;
            _previewPath = _capturedRawPath;
          });
          await _loadPreviewUiImage(_capturedRawPath);
        } else {
          if (_mattingMode != 'cloud') {
            final success = await _runCloudMattingInPreview();
            if (!success) return;
          }
          setState(() {
            _strokeStyle = style;
            if (_strokeWidth == 0.0) {
              _strokeWidth = 4.0;
            }
          });
          _strokeAnimationController.forward(from: 0.0);
        }
        HapticFeedback.lightImpact();
      },
      child: Container(
        width: 54,
        height: 54,
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(0xFFD4A373).withValues(alpha: 0.15)
              : Colors.black45,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? const Color(0xFFD4A373) : Colors.white12,
            width: isSelected ? 1.5 : 1.0,
          ),
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            Positioned(
              top: 3,
              left: 3,
              right: 3,
              bottom: 15,
              child: CustomPaint(
                painter: StrokeStylePreviewPainter(style: style),
              ),
            ),
            Positioned(
              bottom: 3,
              child: Text(
                label,
                style: TextStyle(
                  color: isSelected ? const Color(0xFFD4A373) : Colors.white54,
                  fontSize: 8.5,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  fontFamily: 'LXGWWenKai',
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

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
          color: isSelected
              ? const Color(0xFFD4A373).withValues(alpha: 0.15)
              : Colors.transparent,
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

  void _resetCropRectForRatio(String ratio) {
    if (ratio == 'free') {
      _normalizedCropRect = const Rect.fromLTWH(0, 0, 1, 1);
      return;
    }
    double targetRatio = 1.0;
    if (ratio == '4:3') {
      targetRatio = 4 / 3;
    } else if (ratio == '16:9') {
      targetRatio = 16 / 9;
    } else if (ratio == '3:4') {
      targetRatio = 3 / 4;
    } else if (ratio == '9:16') {
      targetRatio = 9 / 16;
    }

    double imgAspect = 1.0;
    if (_previewUiImage != null) {
      imgAspect = _previewUiImage!.width / _previewUiImage!.height;
    }

    double w = 1.0;
    double h = 1.0;
    double relativeRatio = targetRatio / imgAspect;

    if (relativeRatio > 1.0) {
      w = 1.0;
      h = 1.0 / relativeRatio;
    } else {
      h = 1.0;
      w = relativeRatio;
    }

    double x = (1.0 - w) / 2;
    double y = (1.0 - h) / 2;
    _normalizedCropRect = Rect.fromLTWH(x, y, w, h);
  }

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
          color: isSelected
              ? const Color(0xFFD4A373).withValues(alpha: 0.15)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? const Color(0xFFD4A373) : Colors.white12,
            width: 1,
          ),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        child: Text(
          ratio == 'free' ? '自由' : ratio,
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

  Widget _buildStrokedPreviewImage({
    required String imagePath,
    required double strokeWidth,
    required Color strokeColor,
    required double fgW,
    required double fgH,
  }) {
    Rect effectiveCropBox = _activeCropBoxRect;
    if (effectiveCropBox == const Rect.fromLTWH(0, 0, 1, 1) && _currentRatio == 'free') {
      double imgAspect = 1.0;
      if (_previewUiImage != null) {
        imgAspect = _previewUiImage!.width / _previewUiImage!.height;
      }
      final double containerAspect = fgW / fgH;
      if (imgAspect > containerAspect) {
        double w = 1.0;
        double h = containerAspect / imgAspect;
        effectiveCropBox = Rect.fromLTWH(0, (1.0 - h) / 2, w, h);
      } else {
        double h = 1.0;
        double w = imgAspect / containerAspect;
        effectiveCropBox = Rect.fromLTWH((1.0 - w) / 2, 0, w, h);
      }
    }

    if (_previewUiImage == null) {
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
            animationProgress: _strokeAnimationController.value,
            contourPoints: _contourPoints,
            strokeDistance: _strokeDistance,
            normalizedCropRect: _normalizedCropRect,
            activeCropBoxRect: effectiveCropBox,
            isRatioMode: _currentSubPanel == 'ratio',
          ),
        ),
      ),
    );
  }

  Widget _buildConfirmPageWatermark(
    double displayW,
    double displayH,
    double extraHeight,
  ) {
    if (_watermarkStyle == 'none') return const SizedBox.shrink();
    final now = DateTime.now();
    final String dateStr =
        "${now.year.toString().substring(2)} ${now.month.toString().padLeft(2, '0')} ${now.day.toString().padLeft(2, '0')}";
    final String timeStr =
        "${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}";

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
                  shadows: [
                    Shadow(
                      color: Colors.black45,
                      offset: Offset(1, 1),
                      blurRadius: 3,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 2),
              Text(
                "50mm F/1.8  1/125s  ISO 100  •  ${now.year}/${now.month.toString().padLeft(2, '0')}/${now.day.toString().padLeft(2, '0')} $timeStr",
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.75),
                  fontSize: 8,
                  fontFamily: 'LXGWWenKai',
                  shadows: const [
                    Shadow(
                      color: Colors.black45,
                      offset: Offset(1, 1),
                      blurRadius: 2,
                    ),
                  ],
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
        final double bottomAreaHeight =
            (displayH + extraHeight) - bottomAreaTop;

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
                      Shadow(
                        color: Colors.black.withValues(alpha: 0.4),
                        offset: const Offset(1, 1),
                        blurRadius: 2,
                      ),
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
                      Shadow(
                        color: Colors.black.withValues(alpha: 0.3),
                        offset: const Offset(1, 1),
                        blurRadius: 2,
                      ),
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

class SynchronizedCropRectTween extends Tween<Rect?> {
  final Rect beginPhysical;
  final Rect endPhysical;

  SynchronizedCropRectTween({
    required Rect beginNormalized,
    required Rect endNormalized,
    required this.beginPhysical,
    required this.endPhysical,
  }) : super(begin: beginNormalized, end: endNormalized);

  @override
  Rect lerp(double t) {
    if (begin == null || end == null) return super.lerp(t)!;

    final pNow = Rect.lerp(beginPhysical, endPhysical, t)!;

    final iwBegin = beginPhysical.width / begin!.width;
    final iwEnd = endPhysical.width / end!.width;
    final iwNow = ui.lerpDouble(iwBegin, iwEnd, t)!;

    final ihBegin = beginPhysical.height / begin!.height;
    final ihEnd = endPhysical.height / end!.height;
    final ihNow = ui.lerpDouble(ihBegin, ihEnd, t)!;

    final nwNow = pNow.width / iwNow;
    final nhNow = pNow.height / ihNow;

    final pcxBegin = beginPhysical.center.dx;
    final pcyBegin = beginPhysical.center.dy;
    final icxBegin = pcxBegin - begin!.center.dx * iwBegin;
    final icyBegin = pcyBegin - begin!.center.dy * ihBegin;

    final pcxEnd = endPhysical.center.dx;
    final pcyEnd = endPhysical.center.dy;
    final icxEnd = pcxEnd - end!.center.dx * iwEnd;
    final icyEnd = pcyEnd - end!.center.dy * ihEnd;

    final icxNow = ui.lerpDouble(icxBegin, icxEnd, t)!;
    final icyNow = ui.lerpDouble(icyBegin, icyEnd, t)!;

    final pcxNow = pNow.center.dx;
    final pcyNow = pNow.center.dy;

    final ncxNow = (pcxNow - icxNow) / iwNow;
    final ncyNow = (pcyNow - icyNow) / ihNow;

    return Rect.fromCenter(
      center: Offset(ncxNow, ncyNow),
      width: nwNow,
      height: nhNow,
    );
  }
}

class InteractiveCropOverlay extends StatefulWidget {
  final double width;
  final double height;
  final double imgAspect;
  final String ratio; // '1:1', '4:3', '16:9', 'free'
  final Rect initialCropRect; // 0..1 相对坐标
  final Function(Rect cropBoxRect, Rect normalizedCropRect) onCropRectChanged;

  const InteractiveCropOverlay({
    Key? key,
    required this.width,
    required this.height,
    required this.imgAspect,
    required this.ratio,
    required this.initialCropRect,
    required this.onCropRectChanged,
  }) : super(key: key);

  @override
  _InteractiveCropOverlayState createState() => _InteractiveCropOverlayState();
}

enum _CropHandle {
  topLeft,
  topRight,
  bottomLeft,
  bottomRight,
  top,
  bottom,
  left,
  right,
  inside,
  none,
}

class _InteractiveCropOverlayState extends State<InteractiveCropOverlay>
    with SingleTickerProviderStateMixin {
  static const double edgePadding = 24.0;
  late Rect _physicalRect;
  _CropHandle _activeHandle = _CropHandle.none;
  Offset _dragStartOffset = Offset.zero;
  Rect _dragStartRect = Rect.zero;
  Rect _dragStartNormalizedRect = Rect.zero;
  bool _isDragging = false;

  late AnimationController _resetController;
  Animation<Rect?>? _rectAnimation;
  Animation<Rect?>? _normalizedRectAnimation;

  @override
  void initState() {
    super.initState();
    _initPhysicalRect();
    _resetController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _resetController.addListener(() {
      if (_rectAnimation != null && _rectAnimation!.value != null) {
        setState(() {
          _physicalRect = _rectAnimation!.value!;
        });
      }
      if (_normalizedRectAnimation != null &&
          _normalizedRectAnimation!.value != null &&
          _rectAnimation != null &&
          _rectAnimation!.value != null) {
        final cropBoxNormalized = Rect.fromLTWH(
          _rectAnimation!.value!.left / widget.width,
          _rectAnimation!.value!.top / widget.height,
          _rectAnimation!.value!.width / widget.width,
          _rectAnimation!.value!.height / widget.height,
        );
        widget.onCropRectChanged(
          cropBoxNormalized,
          _normalizedRectAnimation!.value!,
        );
      }
    });
  }

  @override
  void dispose() {
    _resetController.dispose();
    super.dispose();
  }

  Rect _calculateTargetNormalizedRect(String ratio) {
    double targetRatio = widget.imgAspect;
    if (ratio == '1:1') {
      targetRatio = 1.0;
    } else if (ratio == '4:3') {
      targetRatio = 4 / 3;
    } else if (ratio == '16:9') {
      targetRatio = 16 / 9;
    } else if (ratio == '3:4') {
      targetRatio = 3 / 4;
    } else if (ratio == '9:16') {
      targetRatio = 9 / 16;
    }

    double w = 1.0;
    double h = 1.0;
    double relativeRatio = targetRatio / widget.imgAspect;

    if (relativeRatio > 1.0) {
      w = 1.0;
      h = 1.0 / relativeRatio;
    } else {
      h = 1.0;
      w = relativeRatio;
    }

    double x = (1.0 - w) / 2;
    double y = (1.0 - h) / 2;
    return Rect.fromLTWH(x, y, w, h);
  }

  Rect _calculateTargetPhysicalRect(String ratio) {
    double targetRatio = widget.imgAspect;
    if (ratio == '1:1') {
      targetRatio = 1.0;
    } else if (ratio == '4:3') {
      targetRatio = 4 / 3;
    } else if (ratio == '16:9') {
      targetRatio = 16 / 9;
    } else if (ratio == '3:4') {
      targetRatio = 3 / 4;
    } else if (ratio == '9:16') {
      targetRatio = 9 / 16;
    }

    if (widget.width <= 0 || widget.height <= 0) {
      return Rect.zero;
    }
    final double containerAspect = widget.width / widget.height;
    double w = widget.width;
    double h = widget.height;
    double relativeRatio = targetRatio / containerAspect;

    if (relativeRatio > 1.0) {
      w = widget.width;
      h = widget.width / targetRatio;
    } else {
      h = widget.height;
      w = widget.height * targetRatio;
    }

    double x = (widget.width - w) / 2;
    double y = (widget.height - h) / 2;
    return Rect.fromLTWH(x, y, w, h);
  }

  @override
  void didUpdateWidget(covariant InteractiveCropOverlay oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.width != widget.width ||
        oldWidget.height != widget.height ||
        oldWidget.ratio != widget.ratio ||
        oldWidget.imgAspect != widget.imgAspect ||
        oldWidget.initialCropRect != widget.initialCropRect) {
      if (!_isDragging) {
        if (!_resetController.isAnimating) {
          if (oldWidget.ratio != widget.ratio ||
              oldWidget.initialCropRect != widget.initialCropRect) {
            final targetNormalized = oldWidget.ratio != widget.ratio
                ? _calculateTargetNormalizedRect(widget.ratio)
                : widget.initialCropRect;

            Rect targetRect;
            if (widget.ratio == 'free') {
              // 自由比例下，裁剪区域默认为照片的物理比例尺寸大小
              final double containerAspect = widget.width / widget.height;
              double w = widget.width;
              double h = widget.height;
              if (widget.imgAspect > containerAspect) {
                w = widget.width;
                h = widget.width / widget.imgAspect;
              } else {
                h = widget.height;
                w = widget.height * widget.imgAspect;
              }
              final double x = (widget.width - w) / 2;
              final double y = (widget.height - h) / 2;
              targetRect = Rect.fromLTWH(x, y, w, h);
            } else {
              targetRect = _calculateTargetPhysicalRect(widget.ratio);
            }

            _rectAnimation = RectTween(begin: _physicalRect, end: targetRect)
                .animate(
                  CurvedAnimation(
                    parent: _resetController,
                    curve: Curves.easeInOut,
                  ),
                );

            _normalizedRectAnimation =
                SynchronizedCropRectTween(
                  beginNormalized: widget.initialCropRect,
                  endNormalized: targetNormalized,
                  beginPhysical: _physicalRect,
                  endPhysical: targetRect,

                ).animate(
                  CurvedAnimation(
                    parent: _resetController,
                    curve: Curves.easeInOut,
                  ),
                );

            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) {
                _resetController.forward(from: 0.0);
              }
            });
          } else {
            setState(() {
              _initPhysicalRect();
            });
          }
        }
      }
    }
  }

  void _initPhysicalRect() {
    if (widget.width <= 0 || widget.height <= 0) {
      _physicalRect = Rect.zero;
      return;
    }
    double left = widget.initialCropRect.left * widget.width;
    double top = widget.initialCropRect.top * widget.height;
    double width = widget.initialCropRect.width * widget.width;
    double height = widget.initialCropRect.height * widget.height;

    if (widget.ratio == 'free') {
      const double eps = 0.01;
      if (widget.initialCropRect.left < eps &&
          widget.initialCropRect.top < eps &&
          widget.initialCropRect.width > 1.0 - eps &&
          widget.initialCropRect.height > 1.0 - eps) {
        final double containerAspect = widget.width / widget.height;
        double w = widget.width;
        double h = widget.height;
        if (widget.imgAspect > containerAspect) {
          w = widget.width;
          h = widget.width / widget.imgAspect;
        } else {
          h = widget.height;
          w = widget.height * widget.imgAspect;
        }
        left = (widget.width - w) / 2;
        top = (widget.height - h) / 2;
        width = w;
        height = h;
      }
    }

    _physicalRect = Rect.fromLTWH(left, top, width, height);
  }

  double? _getRatioValue() {
    if (widget.ratio == '1:1') return 1.0;
    if (widget.ratio == '4:3') return 4 / 3;
    if (widget.ratio == '16:9') return 16 / 9;
    if (widget.ratio == '3:4') return 3 / 4;
    if (widget.ratio == '9:16') return 9 / 16;
    return null;
  }

  _CropHandle _hitTest(Offset localOffset) {
    const double handleRadius = 32.0;

    // 检测四个角
    if ((localOffset - _physicalRect.topLeft).distance < handleRadius)
      return _CropHandle.topLeft;
    if ((localOffset - _physicalRect.topRight).distance < handleRadius)
      return _CropHandle.topRight;
    if ((localOffset - _physicalRect.bottomLeft).distance < handleRadius)
      return _CropHandle.bottomLeft;
    if ((localOffset - _physicalRect.bottomRight).distance < handleRadius)
      return _CropHandle.bottomRight;

    // 检测四条边
    // 上边
    final topMid = Offset(
      _physicalRect.left + _physicalRect.width / 2,
      _physicalRect.top,
    );
    if ((localOffset - topMid).distance < handleRadius) return _CropHandle.top;
    // 下边
    final bottomMid = Offset(
      _physicalRect.left + _physicalRect.width / 2,
      _physicalRect.bottom,
    );
    if ((localOffset - bottomMid).distance < handleRadius)
      return _CropHandle.bottom;
    // 左边
    final leftMid = Offset(
      _physicalRect.left,
      _physicalRect.top + _physicalRect.height / 2,
    );
    if ((localOffset - leftMid).distance < handleRadius)
      return _CropHandle.left;
    // 右边
    final rightMid = Offset(
      _physicalRect.right,
      _physicalRect.top + _physicalRect.height / 2,
    );
    if ((localOffset - rightMid).distance < handleRadius)
      return _CropHandle.right;

    // 检测内部
    if (_physicalRect.contains(localOffset)) return _CropHandle.inside;

    return _CropHandle.none;
  }

  void _onPanStart(DragStartDetails details) {
    final localOffset =
        details.localPosition - const Offset(edgePadding, edgePadding);
    final handle = _hitTest(localOffset);
    if (handle != _CropHandle.none) {
      _resetController.stop();
      setState(() {
        _isDragging = true;
        _activeHandle = handle;
        _dragStartOffset = localOffset;
        _dragStartRect = _physicalRect;
        _dragStartNormalizedRect = widget.initialCropRect;
      });
    }
  }

  void _onPanUpdate(DragUpdateDetails details) {
    if (_activeHandle == _CropHandle.none) return;
    if (widget.width <= 0 ||
        widget.height <= 0 ||
        _dragStartRect.width <= 0 ||
        _dragStartRect.height <= 0)
      return;

    final Offset currentOffset =
        details.localPosition - const Offset(edgePadding, edgePadding);
    final Offset totalDelta = currentOffset - _dragStartOffset;

    double left = _dragStartRect.left;
    double top = _dragStartRect.top;
    double right = _dragStartRect.right;
    double bottom = _dragStartRect.bottom;

    final double? ratioVal = _getRatioValue();

    const double minSize = 40.0;

    if (_activeHandle == _CropHandle.inside) {
      // 移动图片内容，框在屏幕上不动。
      double rx = totalDelta.dx / widget.width;
      double ry = totalDelta.dy / widget.height;

      double rawLeft = _dragStartNormalizedRect.left - rx;
      double rawTop = _dragStartNormalizedRect.top - ry;

      double maxLeft = 1.0 - _dragStartNormalizedRect.width;
      double newLeft = rawLeft;
      if (rawLeft < 0.0) {
        newLeft = rawLeft * 0.70;
      } else if (rawLeft > maxLeft) {
        newLeft = maxLeft + (rawLeft - maxLeft) * 0.70;
      }

      double maxTop = 1.0 - _dragStartNormalizedRect.height;
      double newTop = rawTop;
      if (rawTop < 0.0) {
        newTop = rawTop * 0.70;
      } else if (rawTop > maxTop) {
        newTop = maxTop + (rawTop - maxTop) * 0.70;
      }

      _physicalRect = _dragStartRect; // 裁剪框保持静止不动

      final normalized = Rect.fromLTWH(
        newLeft,
        newTop,
        _dragStartNormalizedRect.width,
        _dragStartNormalizedRect.height,
      );
      final cropBoxNormalized = Rect.fromLTWH(
        _physicalRect.left / widget.width,
        _physicalRect.top / widget.height,
        _physicalRect.width / widget.width,
        _physicalRect.height / widget.height,
      );
      widget.onCropRectChanged(cropBoxNormalized, normalized);
      return;
    } else if (ratioVal != null) {
      // 固定比例缩放：只响应对角手柄，或者单边手柄也转换为等比缩放
      double deltaX = totalDelta.dx;
      double deltaY = totalDelta.dy;

      switch (_activeHandle) {
        case _CropHandle.topLeft:
          double targetW = _dragStartRect.width - deltaX;
          double targetH = _dragStartRect.height - deltaY;
          double scale = math.max(
            targetW / _dragStartRect.width,
            targetH / _dragStartRect.height,
          );
          double newW = (_dragStartRect.width * scale).clamp(
            minSize,
            _dragStartRect.right,
          );
          double newH = newW / ratioVal;
          if (newH > _dragStartRect.bottom) {
            newH = _dragStartRect.bottom;
            newW = newH * ratioVal;
          }
          _physicalRect = Rect.fromLTRB(
            _dragStartRect.right - newW,
            _dragStartRect.bottom - newH,
            _dragStartRect.right,
            _dragStartRect.bottom,
          );
          break;
        case _CropHandle.topRight:
          double targetW = _dragStartRect.width + deltaX;
          double targetH = _dragStartRect.height - deltaY;
          double scale = math.max(
            targetW / _dragStartRect.width,
            targetH / _dragStartRect.height,
          );
          double newW = (_dragStartRect.width * scale).clamp(
            minSize,
            widget.width - _dragStartRect.left,
          );
          double newH = newW / ratioVal;
          if (newH > _dragStartRect.bottom) {
            newH = _dragStartRect.bottom;
            newW = newH * ratioVal;
          }
          _physicalRect = Rect.fromLTRB(
            _dragStartRect.left,
            _dragStartRect.bottom - newH,
            _dragStartRect.left + newW,
            _dragStartRect.bottom,
          );
          break;
        case _CropHandle.bottomLeft:
          double targetW = _dragStartRect.width - deltaX;
          double targetH = _dragStartRect.height + deltaY;
          double scale = math.max(
            targetW / _dragStartRect.width,
            targetH / _dragStartRect.height,
          );
          double newW = (_dragStartRect.width * scale).clamp(
            minSize,
            _dragStartRect.right,
          );
          double newH = newW / ratioVal;
          if (newH > widget.height - _dragStartRect.top) {
            newH = widget.height - _dragStartRect.top;
            newW = newH * ratioVal;
          }
          _physicalRect = Rect.fromLTRB(
            _dragStartRect.right - newW,
            _dragStartRect.top,
            _dragStartRect.right,
            _dragStartRect.top + newH,
          );
          break;
        case _CropHandle.bottomRight:
          double targetW = _dragStartRect.width + deltaX;
          double targetH = _dragStartRect.height + deltaY;
          double scale = math.max(
            targetW / _dragStartRect.width,
            targetH / _dragStartRect.height,
          );
          double newW = (_dragStartRect.width * scale).clamp(
            minSize,
            widget.width - _dragStartRect.left,
          );
          double newH = newW / ratioVal;
          if (newH > widget.height - _dragStartRect.top) {
            newH = widget.height - _dragStartRect.top;
            newW = newH * ratioVal;
          }
          _physicalRect = Rect.fromLTRB(
            _dragStartRect.left,
            _dragStartRect.top,
            _dragStartRect.left + newW,
            _dragStartRect.top + newH,
          );
          break;
        case _CropHandle.top:
          double newH = (_dragStartRect.height - deltaY).clamp(
            minSize,
            _dragStartRect.bottom,
          );
          double newW = newH * ratioVal;
          if (newW > widget.width) {
            newW = widget.width;
            newH = newW / ratioVal;
          }
          double centerX = _dragStartRect.left + _dragStartRect.width / 2;
          double newLeft = centerX - newW / 2;
          if (newLeft < 0) newLeft = 0;
          if (newLeft + newW > widget.width) newLeft = widget.width - newW;
          _physicalRect = Rect.fromLTRB(
            newLeft,
            _dragStartRect.bottom - newH,
            newLeft + newW,
            _dragStartRect.bottom,
          );
          break;
        case _CropHandle.bottom:
          double newH = (_dragStartRect.height + deltaY).clamp(
            minSize,
            widget.height - _dragStartRect.top,
          );
          double newW = newH * ratioVal;
          if (newW > widget.width) {
            newW = widget.width;
            newH = newW / ratioVal;
          }
          double centerX = _dragStartRect.left + _dragStartRect.width / 2;
          double newLeft = centerX - newW / 2;
          if (newLeft < 0) newLeft = 0;
          if (newLeft + newW > widget.width) newLeft = widget.width - newW;
          _physicalRect = Rect.fromLTRB(
            newLeft,
            _dragStartRect.top,
            newLeft + newW,
            _dragStartRect.top + newH,
          );
          break;
        case _CropHandle.left:
          double newW = (_dragStartRect.width - deltaX).clamp(
            minSize,
            _dragStartRect.right,
          );
          double newH = newW / ratioVal;
          if (newH > widget.height) {
            newH = widget.height;
            newW = newH * ratioVal;
          }
          double centerY = _dragStartRect.top + _dragStartRect.height / 2;
          double newTop = centerY - newH / 2;
          if (newTop < 0) newTop = 0;
          if (newTop + newH > widget.height) newTop = widget.height - newH;
          _physicalRect = Rect.fromLTRB(
            _dragStartRect.right - newW,
            newTop,
            _dragStartRect.right,
            newTop + newH,
          );
          break;
        case _CropHandle.right:
          double newW = (_dragStartRect.width + deltaX).clamp(
            minSize,
            widget.width - _dragStartRect.left,
          );
          double newH = newW / ratioVal;
          if (newH > widget.height) {
            newH = widget.height;
            newW = newH * ratioVal;
          }
          double centerY = _dragStartRect.top + _dragStartRect.height / 2;
          double newTop = centerY - newH / 2;
          if (newTop < 0) newTop = 0;
          if (newTop + newH > widget.height) newTop = widget.height - newH;
          _physicalRect = Rect.fromLTRB(
            _dragStartRect.left,
            newTop,
            _dragStartRect.left + newW,
            _dragStartRect.top + newH,
          );
          break;
        case _CropHandle.inside:
        case _CropHandle.none:
          break;
      }
    } else {
      // 自由比例
      switch (_activeHandle) {
        case _CropHandle.topLeft:
          left = (left + totalDelta.dx).clamp(0.0, right - minSize);
          top = (top + totalDelta.dy).clamp(0.0, bottom - minSize);
          break;
        case _CropHandle.topRight:
          right = (right + totalDelta.dx).clamp(left + minSize, widget.width);
          top = (top + totalDelta.dy).clamp(0.0, bottom - minSize);
          break;
        case _CropHandle.bottomLeft:
          left = (left + totalDelta.dx).clamp(0.0, right - minSize);
          bottom = (bottom + totalDelta.dy).clamp(top + minSize, widget.height);
          break;
        case _CropHandle.bottomRight:
          right = (right + totalDelta.dx).clamp(left + minSize, widget.width);
          bottom = (bottom + totalDelta.dy).clamp(top + minSize, widget.height);
          break;
        case _CropHandle.top:
          top = (top + totalDelta.dy).clamp(0.0, bottom - minSize);
          break;
        case _CropHandle.bottom:
          bottom = (bottom + totalDelta.dy).clamp(top + minSize, widget.height);
          break;
        case _CropHandle.left:
          left = (left + totalDelta.dx).clamp(0.0, right - minSize);
          break;
        case _CropHandle.right:
          right = (right + totalDelta.dx).clamp(left + minSize, widget.width);
          break;
        default:
          break;
      }
      _physicalRect = Rect.fromLTRB(left, top, right, bottom);
    }

    setState(() {});
    final cropBoxNormalized = Rect.fromLTWH(
      _physicalRect.left / widget.width,
      _physicalRect.top / widget.height,
      _physicalRect.width / widget.width,
      _physicalRect.height / widget.height,
    );
    widget.onCropRectChanged(cropBoxNormalized, _dragStartNormalizedRect);
  }

  void _onPanEnd(DragEndDetails details) {
    setState(() {
      _activeHandle = _CropHandle.none;
      _isDragging = false;
    });
    _startResetAnimation();
  }

  void _startResetAnimation() {
    if (_physicalRect.width <= 0 ||
        _physicalRect.height <= 0 ||
        _dragStartRect.width <= 0 ||
        _dragStartRect.height <= 0 ||
        widget.width <= 0 ||
        widget.height <= 0) {
      return;
    }
    // 1. Calculate the final normalized crop rect relative to the original image based on drag-end _physicalRect
    final double rx =
        (_physicalRect.left - _dragStartRect.left) / _dragStartRect.width;
    final double ry =
        (_physicalRect.top - _dragStartRect.top) / _dragStartRect.height;
    final double rw = _physicalRect.width / _dragStartRect.width;
    final double rh = _physicalRect.height / _dragStartRect.height;

    double newLeft =
        (_dragStartNormalizedRect.left + rx * _dragStartNormalizedRect.width);
    double newTop =
        (_dragStartNormalizedRect.top + ry * _dragStartNormalizedRect.height);
    double newWidth = (rw * _dragStartNormalizedRect.width).clamp(0.0, 1.0);
    double newHeight = (rh * _dragStartNormalizedRect.height).clamp(0.0, 1.0);

    newLeft = newLeft.clamp(0.0, 1.0 - newWidth);
    newTop = newTop.clamp(0.0, 1.0 - newHeight);

    Rect finalNormalized = Rect.fromLTWH(newLeft, newTop, newWidth, newHeight);

    // 2. Define the target crop box position in the container (centered/fitted)
    final double aspect = _physicalRect.width / _physicalRect.height;
    final double containerAspect = widget.width / widget.height;

    double targetW;
    double targetH;
    if (aspect > containerAspect) {
      targetW = widget.width;
      targetH = targetW / aspect;
    } else {
      targetH = widget.height;
      targetW = targetH * aspect;
    }

    double targetLeft = (widget.width - targetW) / 2;
    double targetTop = (widget.height - targetH) / 2;
    Rect targetRect = Rect.fromLTWH(targetLeft, targetTop, targetW, targetH);

    if (widget.ratio == 'free') {
      const double snapThreshold = 18.0; // pixels
      if (targetLeft < snapThreshold &&
          targetTop < snapThreshold &&
          (widget.width - targetW) < snapThreshold * 2 &&
          (widget.height - targetH) < snapThreshold * 2) {
        targetRect = Rect.fromLTWH(0, 0, widget.width, widget.height);
        finalNormalized = const Rect.fromLTWH(0, 0, 1, 1);
      }
    }

    // 3. Set up the animations for both the crop box and the image crop region
    _rectAnimation = RectTween(begin: _physicalRect, end: targetRect).animate(
      CurvedAnimation(parent: _resetController, curve: Curves.easeInOut),
    );

    _normalizedRectAnimation =
        RectTween(begin: widget.initialCropRect, end: finalNormalized).animate(
          CurvedAnimation(parent: _resetController, curve: Curves.easeInOut),
        );

    _resetController.forward(from: 0.0);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onPanStart: _onPanStart,
      onPanUpdate: _onPanUpdate,
      onPanEnd: _onPanEnd,
      child: CustomPaint(
        size: Size(
          widget.width + edgePadding * 2,
          widget.height + edgePadding * 2,
        ),
        painter: _CropOverlayPainter(
          rect: _physicalRect.shift(const Offset(edgePadding, edgePadding)),
          edgePadding: edgePadding,
          isDragging: _isDragging || _activeHandle != _CropHandle.none,
        ),
      ),
    );
  }
}

class _CropOverlayPainter extends CustomPainter {
  final Rect rect;
  final double edgePadding;
  final bool isDragging;

  _CropOverlayPainter({
    required this.rect,
    required this.edgePadding,
    required this.isDragging,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // 移除背景遮罩绘制，避免与底图 StrokePreviewPainter 遮罩重复叠加导致颜色不一致

    final borderPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.85)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;
    canvas.drawRect(rect, borderPaint);

    // 绘制九宫格构图线
    if (isDragging) {
      final gridPaint = Paint()
        ..color = Colors.white.withValues(alpha: 0.35)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.0;

      // 垂直分割线
      final double thirdW = rect.width / 3;
      canvas.drawLine(
        Offset(rect.left + thirdW, rect.top),
        Offset(rect.left + thirdW, rect.bottom),
        gridPaint,
      );
      canvas.drawLine(
        Offset(rect.left + thirdW * 2, rect.top),
        Offset(rect.left + thirdW * 2, rect.bottom),
        gridPaint,
      );

      // 水平分割线
      final double thirdH = rect.height / 3;
      canvas.drawLine(
        Offset(rect.left, rect.top + thirdH),
        Offset(rect.right, rect.top + thirdH),
        gridPaint,
      );
      canvas.drawLine(
        Offset(rect.left, rect.top + thirdH * 2),
        Offset(rect.right, rect.top + thirdH * 2),
        gridPaint,
      );
    }

    final handlePaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0
      ..strokeCap = StrokeCap.round;

    const double len = 16.0;

    canvas.drawPath(
      Path()
        ..moveTo(rect.left, rect.top + len)
        ..lineTo(rect.left, rect.top)
        ..lineTo(rect.left + len, rect.top),
      handlePaint,
    );
    canvas.drawPath(
      Path()
        ..moveTo(rect.right - len, rect.top)
        ..lineTo(rect.right, rect.top)
        ..lineTo(rect.right, rect.top + len),
      handlePaint,
    );
    canvas.drawPath(
      Path()
        ..moveTo(rect.left, rect.bottom - len)
        ..lineTo(rect.left, rect.bottom)
        ..lineTo(rect.left + len, rect.bottom),
      handlePaint,
    );
    canvas.drawPath(
      Path()
        ..moveTo(rect.right - len, rect.bottom)
        ..lineTo(rect.right, rect.bottom)
        ..lineTo(rect.right, rect.bottom - len),
      handlePaint,
    );

    const double sideLen = 14.0;
    final topMid = Offset(rect.left + rect.width / 2, rect.top);
    canvas.drawLine(
      Offset(topMid.dx - sideLen / 2, topMid.dy),
      Offset(topMid.dx + sideLen / 2, topMid.dy),
      handlePaint,
    );
    final bottomMid = Offset(rect.left + rect.width / 2, rect.bottom);
    canvas.drawLine(
      Offset(bottomMid.dx - sideLen / 2, bottomMid.dy),
      Offset(bottomMid.dx + sideLen / 2, bottomMid.dy),
      handlePaint,
    );
    final leftMid = Offset(rect.left, rect.top + rect.height / 2);
    canvas.drawLine(
      Offset(leftMid.dx, leftMid.dy - sideLen / 2),
      Offset(leftMid.dx, leftMid.dy + sideLen / 2),
      handlePaint,
    );
    final rightMid = Offset(rect.right, rect.top + rect.height / 2);
    canvas.drawLine(
      Offset(rightMid.dx, rightMid.dy - sideLen / 2),
      Offset(rightMid.dx, rightMid.dy + sideLen / 2),
      handlePaint,
    );
  }

  @override
  bool shouldRepaint(covariant _CropOverlayPainter oldDelegate) {
    return oldDelegate.rect != rect ||
        oldDelegate.edgePadding != edgePadding ||
        oldDelegate.isDragging != isDragging;
  }
}
