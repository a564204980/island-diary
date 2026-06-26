import 'dart:io';
import 'dart:async';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:island_diary/core/state/user_state.dart';
import 'package:island_diary/shared/widgets/top_toast.dart';
// ignore: depend_on_referenced_packages
import 'package:photo_manager/photo_manager.dart';
import '../../utils/camera_image_processor.dart';
import '../../utils/camera_matting_processor.dart';
import '../custom_camera_painters.dart';
import 'crop/interactive_crop_overlay.dart';

part 'camera_edit_logic.dart';
part 'camera_edit_widgets.dart';

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
  void _update(VoidCallback fn) {
    if (mounted) setState(fn);
  }

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
  final ValueNotifier<int> _cropRepaintNotifier = ValueNotifier<int>(0);

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
    _cropRepaintNotifier.dispose();
    super.dispose();
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

                                if (isRatioMode)
                                  Positioned(
                                    top: topPos,
                                    left: leftPos,
                                    width: fgW,
                                    height: fgH,
                                    child: SlideTransition(
                                      position: _slideInAnimation,
                                      child: _buildStrokedPreviewImage(
                                        imagePath: _capturedRawPath,
                                        strokeWidth: _strokeWidth,
                                        strokeColor: _strokeColor,
                                        fgW: fgW,
                                        fgH: fgH,
                                        repaint: _cropRepaintNotifier,
                                      ),
                                    ),
                                  )
                                else
                                  AnimatedPositioned(
                                    duration: const Duration(milliseconds: 300),
                                    curve: Curves.easeInOut,
                                    top: topPos,
                                    left: leftPos,
                                    width: fgW,
                                    height: fgH,
                                    child: SlideTransition(
                                      position: _slideInAnimation,
                                      child: ClipRRect(
                                        borderRadius: isBlurBorder
                                            ? BorderRadius.circular(4)
                                            : BorderRadius.zero,
                                        child: _buildStrokedPreviewImage(
                                          imagePath: _capturedRawPath,
                                          strokeWidth: _strokeWidth,
                                          strokeColor: _strokeColor,
                                          fgW: fgW,
                                          fgH: fgH,
                                          repaint: _cropRepaintNotifier,
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
                                      onCropRectChanged: (cropBox, normalized, {bool isFinished = false}) {
                                        _activeCropBoxRect = cropBox;
                                        _normalizedCropRect = normalized;
                                        _cropRepaintNotifier.value++;
                                        if (isFinished) {
                                          setState(() {});
                                        }
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
}
