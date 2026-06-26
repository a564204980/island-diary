import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'synchronized_crop_rect_tween.dart';
import 'crop_overlay_painter.dart';

class InteractiveCropOverlay extends StatefulWidget {
  final double width;
  final double height;
  final double imgAspect;
  final String ratio; // '1:1', '4:3', '16:9', 'free'
  final Rect initialCropRect; // 0..1 相对坐标
  final Function(Rect cropBoxRect, Rect normalizedCropRect, {bool isFinished}) onCropRectChanged;

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
  State<InteractiveCropOverlay> createState() => InteractiveCropOverlayState();
}

class InteractiveCropOverlayState extends State<InteractiveCropOverlay>
    with SingleTickerProviderStateMixin {
  static const double edgePadding = 24.0;
  late Rect _physicalRect;
  late Rect _currentNormalizedRect;
  CropHandle _activeHandle = CropHandle.none;
  Offset _dragStartOffset = Offset.zero;
  Rect _dragStartRect = Rect.zero;
  Rect _dragStartNormalizedRect = Rect.zero;
  bool _isDragging = false;
  bool _pendingAnimation = false;
  Rect? _pendingTargetRect;
  Rect? _pendingTargetNormalized;

  late AnimationController _resetController;
  Animation<Rect?>? _rectAnimation;
  Animation<Rect?>? _normalizedRectAnimation;

  @override
  void initState() {
    super.initState();
    _initPhysicalRect();
    _currentNormalizedRect = widget.initialCropRect;
    _resetController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _resetController.addListener(() {
      if (_rectAnimation != null && _rectAnimation!.value != null) {
        setState(() {
          _physicalRect = _rectAnimation!.value!;
        });
      }
      if (_normalizedRectAnimation != null &&
          _normalizedRectAnimation!.value != null) {
        _currentNormalizedRect = _normalizedRectAnimation!.value!;
        if (_rectAnimation != null && _rectAnimation!.value != null) {
          final cropBoxNormalized = Rect.fromLTWH(
            _rectAnimation!.value!.left / widget.width,
            _rectAnimation!.value!.top / widget.height,
            _rectAnimation!.value!.width / widget.width,
            _rectAnimation!.value!.height / widget.height,
          );
          widget.onCropRectChanged(
            cropBoxNormalized,
            _currentNormalizedRect,
            isFinished: false,
          );
        }
      }
    });
    _resetController.addStatusListener((status) {
      if (status == AnimationStatus.completed || status == AnimationStatus.dismissed) {
        if (_rectAnimation != null && _rectAnimation!.value != null &&
            _normalizedRectAnimation != null && _normalizedRectAnimation!.value != null) {
          final cropBoxNormalized = Rect.fromLTWH(
            _rectAnimation!.value!.left / widget.width,
            _rectAnimation!.value!.top / widget.height,
            _rectAnimation!.value!.width / widget.width,
            _rectAnimation!.value!.height / widget.height,
          );
          widget.onCropRectChanged(
            cropBoxNormalized,
            _normalizedRectAnimation!.value!,
            isFinished: true,
          );
        }
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
    debugPrint("InteractiveCropOverlay.didUpdateWidget: oldRatio=${oldWidget.ratio}, newRatio=${widget.ratio}, isAnimating=${_resetController.isAnimating}, isDragging=$_isDragging");
    if (oldWidget.width != widget.width ||
        oldWidget.height != widget.height ||
        oldWidget.ratio != widget.ratio ||
        oldWidget.imgAspect != widget.imgAspect ||
        oldWidget.initialCropRect != widget.initialCropRect) {
      if (oldWidget.initialCropRect != widget.initialCropRect) {
        _currentNormalizedRect = widget.initialCropRect;
      }
      if (!_isDragging) {
        if (_resetController.isAnimating) {
          // If already animating, only interrupt and restart if the target ratio changed
          if (oldWidget.ratio != widget.ratio) {
            debugPrint("InteractiveCropOverlay: Ratio changed during animation, restarting");
            _startRatioTransitionAnimation(oldWidget, widget);
          }
          return;
        }

        if (oldWidget.ratio != widget.ratio) {
          debugPrint("InteractiveCropOverlay: Ratio changed, starting animation");
          _startRatioTransitionAnimation(oldWidget, widget);
        }
      }
    }
  }

  void triggerResetAnimation() {
    _startRatioTransitionAnimation(widget, widget, forceResetToFull: true);
  }

  void _startRatioTransitionAnimation(covariant InteractiveCropOverlay oldWidget, covariant InteractiveCropOverlay widget, {bool forceResetToFull = false}) {
    // 计算目标值
    final targetNormalized = (oldWidget.ratio != widget.ratio || forceResetToFull)
        ? _calculateTargetNormalizedRect(forceResetToFull ? 'free' : widget.ratio)
        : widget.initialCropRect;

    final Rect targetRect;
    final String targetRatio = forceResetToFull ? 'free' : widget.ratio;
    if (targetRatio == 'free') {
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
      targetRect = _calculateTargetPhysicalRect(targetRatio);
    }

    final currentNormalized = _normalizedRectAnimation?.value ?? oldWidget.initialCropRect;
    final currentPhysical = _physicalRect;

    _pendingTargetRect = targetRect;
    _pendingTargetNormalized = targetNormalized;

    if (!_pendingAnimation) {
      _pendingAnimation = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _pendingAnimation = false;
        final targetR = _pendingTargetRect;
        final targetN = _pendingTargetNormalized;
        if (!mounted || targetR == null || targetN == null) return;
        
        _pendingTargetRect = null;
        _pendingTargetNormalized = null;

        final curvedAnim = CurvedAnimation(
          parent: _resetController,
          curve: Curves.easeOutCubic,
        );
        _rectAnimation = RectTween(
          begin: currentPhysical,
          end: targetR,
        ).animate(curvedAnim);
        _normalizedRectAnimation = SynchronizedCropRectTween(
          beginNormalized: currentNormalized,
          endNormalized: targetN,
          beginPhysical: currentPhysical,
          endPhysical: targetR,
        ).animate(curvedAnim);
        
        _resetController.forward(from: 0.0);
      });
    }
  }

  void _initPhysicalRect() {
    if (widget.width <= 0 || widget.height <= 0) {
      _physicalRect = Rect.zero;
      return;
    }

    final double containerAspect = widget.width / widget.height;
    double imgW = widget.width;
    double imgH = widget.height;
    if (widget.imgAspect > containerAspect) {
      imgW = widget.width;
      imgH = widget.width / widget.imgAspect;
    } else {
      imgH = widget.height;
      imgW = widget.height * widget.imgAspect;
    }
    final double imgLeft = (widget.width - imgW) / 2;
    final double imgTop = (widget.height - imgH) / 2;

    double left = imgLeft + widget.initialCropRect.left * imgW;
    double top = imgTop + widget.initialCropRect.top * imgH;
    double width = widget.initialCropRect.width * imgW;
    double height = widget.initialCropRect.height * imgH;

    if (widget.ratio == 'free') {
      const double eps = 0.01;
      if (widget.initialCropRect.left < eps &&
          widget.initialCropRect.top < eps &&
          widget.initialCropRect.width > 1.0 - eps &&
          widget.initialCropRect.height > 1.0 - eps) {
        left = imgLeft;
        top = imgTop;
        width = imgW;
        height = imgH;
      }
    }

    _physicalRect = Rect.fromLTWH(left, top, width, height);
  }

  Rect _physicalToNormalized(Rect physical) {
    if (widget.width <= 0 || widget.height <= 0) return const Rect.fromLTWH(0, 0, 1, 1);

    final double containerAspect = widget.width / widget.height;
    double imgW = widget.width;
    double imgH = widget.height;
    if (widget.imgAspect > containerAspect) {
      imgW = widget.width;
      imgH = widget.width / widget.imgAspect;
    } else {
      imgH = widget.height;
      imgW = widget.height * widget.imgAspect;
    }
    final double imgLeft = (widget.width - imgW) / 2;
    final double imgTop = (widget.height - imgH) / 2;

    if (imgW <= 0 || imgH <= 0) return const Rect.fromLTWH(0, 0, 1, 1);

    return Rect.fromLTWH(
      (physical.left - imgLeft) / imgW,
      (physical.top - imgTop) / imgH,
      physical.width / imgW,
      physical.height / imgH,
    );
  }

  double? _getRatioValue() {
    if (widget.ratio == '1:1') return 1.0;
    if (widget.ratio == '4:3') return 4 / 3;
    if (widget.ratio == '16:9') return 16 / 9;
    if (widget.ratio == '3:4') return 3 / 4;
    if (widget.ratio == '9:16') return 9 / 16;
    return null;
  }

  CropHandle _hitTest(Offset localOffset) {
    const double handleRadius = 32.0;

    // 检测四个角
    if ((localOffset - _physicalRect.topLeft).distance < handleRadius)
      return CropHandle.topLeft;
    if ((localOffset - _physicalRect.topRight).distance < handleRadius)
      return CropHandle.topRight;
    if ((localOffset - _physicalRect.bottomLeft).distance < handleRadius)
      return CropHandle.bottomLeft;
    if ((localOffset - _physicalRect.bottomRight).distance < handleRadius)
      return CropHandle.bottomRight;

    // 检测四条边
    // 上边
    final topMid = Offset(
      _physicalRect.left + _physicalRect.width / 2,
      _physicalRect.top,
    );
    if ((localOffset - topMid).distance < handleRadius) return CropHandle.top;
    // 下边
    final bottomMid = Offset(
      _physicalRect.left + _physicalRect.width / 2,
      _physicalRect.bottom,
    );
    if ((localOffset - bottomMid).distance < handleRadius)
      return CropHandle.bottom;
    // 左边
    final leftMid = Offset(
      _physicalRect.left,
      _physicalRect.top + _physicalRect.height / 2,
    );
    if ((localOffset - leftMid).distance < handleRadius)
      return CropHandle.left;
    // 右边
    final rightMid = Offset(
      _physicalRect.right,
      _physicalRect.top + _physicalRect.height / 2,
    );
    if ((localOffset - rightMid).distance < handleRadius)
      return CropHandle.right;

    // 检测内部
    if (_physicalRect.contains(localOffset)) return CropHandle.inside;

    return CropHandle.none;
  }

  void _onScaleStart(ScaleStartDetails details) {
    final localOffset =
        details.localFocalPoint - const Offset(edgePadding, edgePadding);
    final handle = _hitTest(localOffset);
    if (handle != CropHandle.none) {
      _resetController.stop();
      setState(() {
        _isDragging = true;
        _activeHandle = handle;
        _dragStartOffset = localOffset;
        _dragStartRect = _physicalRect;
        _dragStartNormalizedRect = _currentNormalizedRect;
      });
    }
  }

  void _onScaleUpdate(ScaleUpdateDetails details) {
    if (_activeHandle == CropHandle.none) return;
    if (widget.width <= 0 ||
        widget.height <= 0 ||
        _dragStartRect.width <= 0 ||
        _dragStartRect.height <= 0)
      return;

    final Offset currentOffset =
        details.localFocalPoint - const Offset(edgePadding, edgePadding);
    final Offset totalDelta = currentOffset - _dragStartOffset;

    double left = _dragStartRect.left;
    double top = _dragStartRect.top;
    double right = _dragStartRect.right;
    double bottom = _dragStartRect.bottom;

    final double? ratioVal = _getRatioValue();

    const double minSize = 40.0;

    if (_activeHandle == CropHandle.inside) {
      // 移动图片内容，框在屏幕上不动。
      double rx = totalDelta.dx / widget.width;
      double ry = totalDelta.dy / widget.height;

      // 双指放大和缩小处理
      double currentScale = details.scale.clamp(0.2, 5.0);
      double newNormalizedWidth = _dragStartNormalizedRect.width / currentScale;
      double newNormalizedHeight = _dragStartNormalizedRect.height / currentScale;

      newNormalizedWidth = newNormalizedWidth.clamp(0.05, 1.0);
      newNormalizedHeight = newNormalizedHeight.clamp(0.05, 1.0);

      // 非自由模式保持裁剪框比例
      if (widget.ratio != 'free') {
        final double normalizedAspect = _dragStartNormalizedRect.width / _dragStartNormalizedRect.height;
        if (newNormalizedWidth > 1.0 || newNormalizedHeight > 1.0) {
          if (newNormalizedWidth > 1.0) {
            newNormalizedWidth = 1.0;
            newNormalizedHeight = 1.0 / normalizedAspect;
          }
          if (newNormalizedHeight > 1.0) {
            newNormalizedHeight = 1.0;
            newNormalizedWidth = 1.0 * normalizedAspect;
          }
        }
      }

      // 移动位置与缩放中心点计算
      double cx = _dragStartNormalizedRect.center.dx - totalDelta.dx * (_dragStartNormalizedRect.width / _dragStartRect.width);
      double cy = _dragStartNormalizedRect.center.dy - totalDelta.dy * (_dragStartNormalizedRect.height / _dragStartRect.height);

      double leftBound = 0.0;
      double topBound = 0.0;
      double rightBound = 1.0 - newNormalizedWidth;
      double bottomBound = 1.0 - newNormalizedHeight;

      double finalLeft = cx - newNormalizedWidth / 2;
      double finalTop = cy - newNormalizedHeight / 2;

      // 边缘阻尼弹性处理
      if (finalLeft < leftBound) {
        finalLeft = leftBound + (finalLeft - leftBound) * 0.70;
      } else if (finalLeft > rightBound) {
        finalLeft = rightBound + (finalLeft - rightBound) * 0.70;
      }

      if (finalTop < topBound) {
        finalTop = topBound + (finalTop - topBound) * 0.70;
      } else if (finalTop > bottomBound) {
        finalTop = bottomBound + (finalTop - bottomBound) * 0.70;
      }

      final normalized = Rect.fromLTWH(
        finalLeft,
        finalTop,
        newNormalizedWidth,
        newNormalizedHeight,
      );
      _currentNormalizedRect = normalized;

      _physicalRect = _dragStartRect; // 裁剪框保持静止不动

      final cropBoxNormalized = Rect.fromLTWH(
        _physicalRect.left / widget.width,
        _physicalRect.top / widget.height,
        _physicalRect.width / widget.width,
        _physicalRect.height / widget.height,
      );
      widget.onCropRectChanged(cropBoxNormalized, normalized, isFinished: false);
      return;
    } else if (ratioVal != null) {
      // 固定比例缩放：只响应对角手柄，或者单边手柄也转换为等比缩放
      double deltaX = totalDelta.dx;
      double deltaY = totalDelta.dy;

      switch (_activeHandle) {
        case CropHandle.topLeft:
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
        case CropHandle.topRight:
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
        case CropHandle.bottomLeft:
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
        case CropHandle.bottomRight:
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
        case CropHandle.top:
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
        case CropHandle.bottom:
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
        case CropHandle.left:
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
        case CropHandle.right:
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
        case CropHandle.inside:
        case CropHandle.none:
          break;
      }
    } else {
      // 自由比例
      switch (_activeHandle) {
        case CropHandle.topLeft:
          left = (left + totalDelta.dx).clamp(0.0, right - minSize);
          top = (top + totalDelta.dy).clamp(0.0, bottom - minSize);
          break;
        case CropHandle.topRight:
          right = (right + totalDelta.dx).clamp(left + minSize, widget.width);
          top = (top + totalDelta.dy).clamp(0.0, bottom - minSize);
          break;
        case CropHandle.bottomLeft:
          left = (left + totalDelta.dx).clamp(0.0, right - minSize);
          bottom = (bottom + totalDelta.dy).clamp(top + minSize, widget.height);
          break;
        case CropHandle.bottomRight:
          right = (right + totalDelta.dx).clamp(left + minSize, widget.width);
          bottom = (bottom + totalDelta.dy).clamp(top + minSize, widget.height);
          break;
        case CropHandle.top:
          top = (top + totalDelta.dy).clamp(0.0, bottom - minSize);
          break;
        case CropHandle.bottom:
          bottom = (bottom + totalDelta.dy).clamp(top + minSize, widget.height);
          break;
        case CropHandle.left:
          left = (left + totalDelta.dx).clamp(0.0, right - minSize);
          break;
        case CropHandle.right:
          right = (right + totalDelta.dx).clamp(left + minSize, widget.width);
          break;
        default:
          break;
      }
      _physicalRect = Rect.fromLTRB(left, top, right, bottom);
    }

    setState(() {});

    final double iwStart = _dragStartRect.width / _dragStartNormalizedRect.width;
    final double ihStart = _dragStartRect.height / _dragStartNormalizedRect.height;
    final double icxStart = _dragStartRect.center.dx - _dragStartNormalizedRect.center.dx * iwStart;
    final double icyStart = _dragStartRect.center.dy - _dragStartNormalizedRect.center.dy * ihStart;

    final double newNormalizedWidth = _physicalRect.width / iwStart;
    final double newNormalizedHeight = _physicalRect.height / ihStart;
    final double newNormalizedCx = (_physicalRect.center.dx - icxStart) / iwStart;
    final double newNormalizedCy = (_physicalRect.center.dy - icyStart) / ihStart;

    final newNormalized = Rect.fromCenter(
      center: Offset(newNormalizedCx, newNormalizedCy),
      width: newNormalizedWidth,
      height: newNormalizedHeight,
    );
    _currentNormalizedRect = newNormalized;

    final cropBoxNormalized = Rect.fromLTWH(
      _physicalRect.left / widget.width,
      _physicalRect.top / widget.height,
      _physicalRect.width / widget.width,
      _physicalRect.height / widget.height,
    );
    widget.onCropRectChanged(cropBoxNormalized, newNormalized, isFinished: false);
  }

  void _onScaleEnd(ScaleEndDetails details) {
    final CropHandle handle = _activeHandle;
    setState(() {
      _activeHandle = CropHandle.none;
      _isDragging = false;
    });
    _startResetAnimation(handle);
  }

  void _startResetAnimation(CropHandle handle) {
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

    double newLeft;
    double newTop;
    double newWidth;
    double newHeight;

    if (handle == CropHandle.inside) {
      newLeft = _currentNormalizedRect.left;
      newTop = _currentNormalizedRect.top;
      newWidth = _currentNormalizedRect.width;
      newHeight = _currentNormalizedRect.height;
    } else {
      newLeft =
          (_dragStartNormalizedRect.left + rx * _dragStartNormalizedRect.width);
      newTop =
          (_dragStartNormalizedRect.top + ry * _dragStartNormalizedRect.height);
      newWidth = rw * _dragStartNormalizedRect.width;
      newHeight = rh * _dragStartNormalizedRect.height;
    }

    newWidth = newWidth.clamp(0.0, 1.0);
    newHeight = newHeight.clamp(0.0, 1.0);
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
    final curvedAnim = CurvedAnimation(
      parent: _resetController,
      curve: Curves.easeOutCubic,
    );
    _rectAnimation = RectTween(begin: _physicalRect, end: targetRect).animate(curvedAnim);

    _normalizedRectAnimation =
        RectTween(begin: _currentNormalizedRect, end: finalNormalized).animate(curvedAnim);

    _resetController.forward(from: 0.0);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onScaleStart: _onScaleStart,
      onScaleUpdate: _onScaleUpdate,
      onScaleEnd: _onScaleEnd,
      child: CustomPaint(
        size: Size(
          widget.width + edgePadding * 2,
          widget.height + edgePadding * 2,
        ),
        painter: CropOverlayPainter(
          rect: _physicalRect.shift(const Offset(edgePadding, edgePadding)),
          edgePadding: edgePadding,
          isDragging: _isDragging || _activeHandle != CropHandle.none,
        ),
      ),
    );
  }
}
