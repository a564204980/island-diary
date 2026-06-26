part of 'camera_edit_overlay.dart';

extension _CameraEditOverlayWidgets on _CameraEditOverlayState {
  Widget _buildCategoryItem(String panel, IconData icon, String label) {
    final bool isSelected = panel == 'matting'
        ? (_mattingMode == 'cloud')
        : (_currentSubPanel == panel);
    return GestureDetector(
      onTap: () {
        if (panel == 'matting') {
          _update(() {
            _mattingMode = _mattingMode == 'none' ? 'cloud' : 'none';
            if (_mattingMode == 'cloud') {
              _currentSubPanel = 'matting';
            } else {
              _currentSubPanel = 'ratio';
            }
          });
        } else {
          _update(() {
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
              Spacer() /* dummy wrapper to satisfy minSize */,
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
                            _update(() {
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
                          _update(() {
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
                                  _update(() {
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
                                  _update(() {
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
        _update(() {
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
        _update(() {
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
          _update(() {
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
          _update(() {
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
        _update(() {
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

  Widget _buildRatioButton(String ratio) {
    final bool isSelected = _currentRatio == ratio;
    return GestureDetector(
      onTap: () {
        _update(() {
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
    required Listenable repaint,
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
            getNormalizedCropRect: () => _normalizedCropRect,
            getActiveCropBoxRect: () {
              Rect effective = _activeCropBoxRect;
              if (effective == const Rect.fromLTWH(0, 0, 1, 1)) {
                double imgAspect = 1.0;
                if (_previewUiImage != null) {
                  imgAspect = _previewUiImage!.width / _previewUiImage!.height;
                }
                final double containerAspect = fgW / fgH;
                if (imgAspect > containerAspect) {
                  double w = 1.0;
                  double h = containerAspect / imgAspect;
                  effective = Rect.fromLTWH(0, (1.0 - h) / 2, w, h);
                } else {
                  double h = 1.0;
                  double w = imgAspect / containerAspect;
                  effective = Rect.fromLTWH((1.0 - w) / 2, 0, w, h);
                }
              }
              return effective;
            },
            isRatioMode: _currentSubPanel == 'ratio',
            repaint: repaint,
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
