part of '../../diary_book_export_page.dart';

extension _ExportLayoutLogic on _DiaryBookExportPageState {
  void _animateMatrixTo(Matrix4 targetMatrix) {
    _matrixAnimationController?.dispose();
    _matrixAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
    );
    
    final Matrix4 startMatrix = _transformationController.value;
    
    _matrixAnimation = Matrix4Tween(
      begin: startMatrix,
      end: targetMatrix,
    ).animate(
      CurvedAnimation(
        parent: _matrixAnimationController!,
        curve: Curves.easeInOutCubic,
      ),
    )..addListener(() {
        _transformationController.value = _matrixAnimation!.value;
      });
      
    _matrixAnimationController!.forward();
  }


  void _recenterCanvas({bool animate = true}) {
    final constraints = _lastConstraints;
    if (constraints == null) return;
    
    const padding = 32.0;
    final targetWidth = constraints.maxWidth - padding;
    final scale = targetWidth / _canvasWidth;
    
    final dx = (constraints.maxWidth - _canvasWidth * scale) / 2;
    final dy = 16.0;
    
    final targetMatrix = Matrix4.identity()
      ..translateByDouble(dx, dy, 0.0, 1.0)
      ..scaleByDouble(scale, scale, 1.0, 1.0);
      
    if (animate) {
      _animateMatrixTo(targetMatrix);
    } else {
      _transformationController.value = targetMatrix;
    }
  }


  void _zoom(double factor) {
    final matrix = _transformationController.value.clone();
    final double currentScale = matrix.getMaxScaleOnAxis();
    final double newScale = (currentScale * factor).clamp(0.2, 3.0);
    final double finalFactor = newScale / currentScale;
    updateState(() {
      _transformationController.value = matrix..scaleByDouble(finalFactor, finalFactor, 1.0, 1.0);
    });
  }


  double getScreenY(double y) {
    final int pageIndex = y ~/ _canvasHeight;
    final double yInPage = y % _canvasHeight;
    return pageIndex * (_canvasHeight + pageGap) + yInPage;
  }


  double getLayoutY(double screenY) {
    final int pageIndex = screenY ~/ (_canvasHeight + pageGap);
    final double yInPage = screenY % (_canvasHeight + pageGap);
    final double clampedYInPage = yInPage.clamp(0.0, _canvasHeight);
    return pageIndex * _canvasHeight + clampedYInPage;
  }


  void _onViewportChanged() {
    final constraints = _lastConstraints;
    if (constraints == null) return;

    final matrix = _transformationController.value;
    final double scale = matrix.getMaxScaleOnAxis();
    if (scale <= 0) return;
    
    final double translationY = matrix.getTranslation().y;
    final double screenCenterY = constraints.maxHeight / 2;
    final double layoutCenterY = (screenCenterY - translationY) / scale;
    
    final double pageHeightWithGap = _canvasHeight + pageGap;
    if (pageHeightWithGap <= 0) return;
    
    int newPageIndex = (layoutCenterY / pageHeightWithGap).floor();
    newPageIndex = newPageIndex.clamp(0, _pageCount - 1);
    
    if (newPageIndex != _focusedPageIndex) {
      if (_isPanelExpanded) {
        updateState(() {
          _focusedPageIndex = newPageIndex;
        });
      } else {
        _focusedPageIndex = newPageIndex;
      }
    }

    final double translationX = matrix.getTranslation().x;
    final Rect viewport = Rect.fromLTWH(
      -translationX / scale,
      -translationY / scale,
      constraints.maxWidth / scale,
      constraints.maxHeight / scale,
    );

    // 如果视口滑出了当前剔除框的安全内边距，则更新剔除框并触发一次按需渲染
    if (_currentCullingRect.isEmpty ||
        !_currentCullingRect.deflate(500).contains(viewport.topLeft) ||
        !_currentCullingRect.deflate(500).contains(viewport.bottomRight)) {
      _currentCullingRect = viewport.inflate(2000);
      _canvasRefreshTrigger.value++;
    }
  }


  void _onInteractionEnd(ScaleEndDetails details) {
    if (_initialScale == null || _lastConstraints == null) return;
    
    final matrix = _transformationController.value;
    final scale = matrix.getMaxScaleOnAxis();
    
    // 如果缩小到默认级别附近，强制 X 轴回正
    if (scale <= _initialScale! + 0.05) {
      final targetDx = (_lastConstraints!.maxWidth - _canvasWidth * scale) / 2;
      final currentDx = matrix.getTranslation().x;
      
      // 容差大于 1 px，认为发生了偏移，执行回弹动画
      if ((currentDx - targetDx).abs() > 1.0) {
        final targetMatrix = matrix.clone()..setTranslationRaw(targetDx, matrix.getTranslation().y, 0.0);
        
        _alignAnimationController?.dispose();
        _alignAnimationController = AnimationController(
          vsync: this,
          duration: const Duration(milliseconds: 300), // 回弹耗时
        );
        _alignAnimation = Matrix4Tween(
          begin: matrix,
          end: targetMatrix,
        ).animate(CurvedAnimation(
          parent: _alignAnimationController!,
          curve: Curves.easeOutCubic, // 果冻般的回弹曲线
        ));
        
        _alignAnimation!.addListener(() {
          _transformationController.value = _alignAnimation!.value;
        });
        
        _alignAnimationController!.forward();
      }
    }
  }

  // 截图某个预渲染图表，返回临时文件路径
  Future<String?> _captureChart(GlobalKey key) async {
    try {
      final boundary = key.currentContext?.findRenderObject() as RenderRepaintBoundary?;
      if (boundary == null) return null;
      final ui.Image image = await boundary.toImage(pixelRatio: 2.0);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      if (byteData == null) return null;
      final bytes = byteData.buffer.asUint8List();
      final dir = await getTemporaryDirectory();
      final filePath = '${dir.path}/chart_${DateTime.now().millisecondsSinceEpoch}.png';
      await File(filePath).writeAsBytes(bytes);
      return filePath;
    } catch (e) {
      debugPrint('图表截图失败: $e');
      return null;
    }
  }


}
