part of 'camera_edit_overlay.dart';

extension _CameraEditOverlayLogic on _CameraEditOverlayState {
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
        _update(() {
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
    _update(() {
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
      _update(() {
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
          _update(() {
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
}
