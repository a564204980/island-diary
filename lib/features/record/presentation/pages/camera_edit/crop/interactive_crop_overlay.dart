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
  State<InteractiveCropOverlay> createState() => _InteractiveCropOverlayState();
}

class _InteractiveCropOverlayState extends State<InteractiveCropOverlay>
    with SingleTickerProviderStateMixin {
  static const double edgePadding = 24.0;
  late Rect _physicalRect;
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
          isFinished: false,
        );
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
        } else {
          // If only initialCropRect changed externally (e.g. reset), snap to target rect directly.
          // The only external reset that doesn't change ratio is when it is reset to full image (const Rect.fromLTWH(0, 0, 1, 1)).
          if (widget.initialCropRect == const Rect.fromLTWH(0, 0, 1, 1)) {
            debugPrint("InteractiveCropOverlay: Snapping to full size on Reset");
            setState(() {
              _initPhysicalRect();
            });
          }
        }
      }
    }
  }

  void _startRatioTransitionAnimation(covariant InteractiveCropOverlay oldWidget, covariant InteractiveCropOverlay widget) {
    // 计算目标值
    final targetNormalized = oldWidget.ratio != widget.ratio
        ? _calculateTargetNormalizedRect(widget.ratio)
        : widget.initialCropRect;

    final Rect targetRect;
    if (widget.ratio == 'free') {
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

    debugPrint("InteractiveCropOverlay: targetNormalized=$targetNormalized, targetRect=$targetRect");

    // 最新目标存入 pending，供回调使用（仅在 idle 分支用到）
    _pendingTargetRect = targetRect;
    _pendingTargetNormalized = targetNormalized;

    if (_resetController.isAnimating) {
      // ── 动画进行中 ──
      // 直接用当前 _physicalRect 作 begin 重建 tween，然后 forward(from:0.0)
      // 使用 easeOut（无 ease-in），感觉更连贯；
      // 必须通过 postFrame 调 forward，避免 setState-during-build
      final currentNormalized = _normalizedRectAnimation?.value ?? widget.initialCropRect;
      final curvedAnim = CurvedAnimation(
        parent: _resetController,
        curve: Curves.easeInOutCubic,
      );
      _rectAnimation = RectTween(
        begin: _physicalRect,
        end: targetRect,
      ).animate(curvedAnim);
      _normalizedRectAnimation = SynchronizedCropRectTween(
        beginNormalized: currentNormalized,
        endNormalized: targetNormalized,
        beginPhysical: _physicalRect,
        endPhysical: targetRect,
      ).animate(curvedAnim);
      _pendingTargetRect = null;
      _pendingTargetNormalized = null;
      if (!_pendingAnimation) {
        _pendingAnimation = true;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _pendingAnimation = false;
          if (mounted) _resetController.forward(from: 0.0);
        });
      }
    } else if (!_pendingAnimation) {
      // ── 无动画且无待处理回调 ──
      // postFrame 延迟一帧启动（规避 setState-during-build）
      _pendingAnimation = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _pendingAnimation = false;
        final targetR = _pendingTargetRect;
        final targetN = _pendingTargetNormalized;
        if (!mounted || targetR == null || targetN == null) return;
        _pendingTargetRect = null;
        _pendingTargetNormalized = null;
        final currentNormalized = _normalizedRectAnimation?.value ?? widget.initialCropRect;
        final curvedAnim = CurvedAnimation(
          parent: _resetController,
          curve: Curves.easeInOutCubic,
        );
        _rectAnimation = RectTween(
          begin: _physicalRect,
          end: targetR,
        ).animate(curvedAnim);
        _normalizedRectAnimation = SynchronizedCropRectTween(
          beginNormalized: currentNormalized,
          endNormalized: targetN,
          beginPhysical: _physicalRect,
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

  void _onPanStart(DragStartDetails details) {
    final localOffset =
        details.localPosition - const Offset(edgePadding, edgePadding);
    final handle = _hitTest(localOffset);
    if (handle != CropHandle.none) {
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
    if (_activeHandle == CropHandle.none) return;
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

    if (_activeHandle == CropHandle.inside) {
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
    final cropBoxNormalized = Rect.fromLTWH(
      _physicalRect.left / widget.width,
      _physicalRect.top / widget.height,
      _physicalRect.width / widget.width,
      _physicalRect.height / widget.height,
    );
    widget.onCropRectChanged(cropBoxNormalized, _dragStartNormalizedRect, isFinished: false);
  }

  void _onPanEnd(DragEndDetails details) {
    setState(() {
      _activeHandle = CropHandle.none;
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
    final curvedAnim = CurvedAnimation(
      parent: _resetController,
      curve: Curves.easeInOut,
    );
    _rectAnimation = RectTween(begin: _physicalRect, end: targetRect).animate(curvedAnim);

    _normalizedRectAnimation =
        RectTween(begin: widget.initialCropRect, end: finalNormalized).animate(curvedAnim);

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
        painter: CropOverlayPainter(
          rect: _physicalRect.shift(const Offset(edgePadding, edgePadding)),
          edgePadding: edgePadding,
          isDragging: _isDragging || _activeHandle != CropHandle.none,
        ),
      ),
    );
  }
}
