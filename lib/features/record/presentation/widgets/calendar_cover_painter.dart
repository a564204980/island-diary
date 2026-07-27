import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:island_diary/features/home/presentation/services/photo_wall_storage_service.dart';

/// 日历封面图内存 ImageCache 离屏缓存器
class CalendarImageCache {
  static final Map<String, ui.Image> _cache = {};
  static final Map<String, List<ui.VoidCallback>> _listeners = {};

  /// 获取离屏 ui.Image 对象
  static ui.Image? get(String path) => _cache[path];

  /// 异步加载并将位图解析存入 Canvas 内存映射中
  static void load(String path, ui.VoidCallback onLoaded) {
    if (_cache.containsKey(path)) return;

    _listeners.putIfAbsent(path, () => []).add(onLoaded);
    if (_listeners[path]!.length > 1) return;

    ImageProvider provider;
    if (path.startsWith('http') || path.startsWith('blob:')) {
      provider = NetworkImage(path);
    } else if (path.startsWith('data:')) {
      try {
        final commaIdx = path.indexOf(',');
        final base64Str = commaIdx != -1 ? path.substring(commaIdx + 1) : path;
        final bytes = base64Decode(base64Str);
        provider = MemoryImage(bytes);
      } catch (e) {
        _listeners.remove(path);
        return;
      }
    } else if (path.startsWith('assets/')) {
      provider = AssetImage(path);
    } else {
      var file = File(path);
      if (!file.existsSync()) {
        final repairedPath = PhotoWallStorageService.toValidAbsolutePathSync(path);
        file = File(repairedPath);
      }
      if (!file.existsSync()) {
        _listeners.remove(path);
        return;
      }
      provider = FileImage(file);
    }

    final stream = provider.resolve(const ImageConfiguration());
    ImageStreamListener? listener;
    listener = ImageStreamListener(
      (ImageInfo info, bool _) {
        _cache[path] = info.image;
        final callbacks = _listeners.remove(path) ?? [];
        for (var cb in callbacks) {
          cb();
        }
        if (listener != null) {
          stream.removeListener(listener);
        }
      },
      onError: (dynamic exception, StackTrace? stackTrace) {
        _listeners.remove(path);
        if (listener != null) {
          stream.removeListener(listener);
        }
      },
    );
    stream.addListener(listener);
  }
}

/// 基于 Canvas 直接绘制的高性能日历封面 CustomPainter
class CalendarCoverPainter extends CustomPainter {
  final List<String> images;
  final bool isNight;
  final ui.VoidCallback onRequestRepaint;

  CalendarCoverPainter({
    required this.images,
    required this.isNight,
    required this.onRequestRepaint,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (images.isEmpty) return;

    final paint = Paint()
      ..isAntiAlias = true
      ..filterQuality = FilterQuality.medium;

    // 优雅软调底色：在解压极其短暂的瞬间自动填充与纸张调和的微光色，绝对不出现任何硬灰块
    final fallbackPaint = Paint()
      ..color = isNight
          ? Colors.white.withValues(alpha: 0.1)
          : const Color(0xFFE8E2DA);

    final count = images.length;
    final List<Rect> rects = [];

    if (count == 1) {
      rects.add(Rect.fromLTWH(0, 0, size.width, size.height));
    } else if (count == 2) {
      final halfW = (size.width - 1.0) / 2.0;
      rects.add(Rect.fromLTWH(0, 0, halfW, size.height));
      rects.add(Rect.fromLTWH(halfW + 1.0, 0, halfW, size.height));
    } else if (count == 3) {
      final halfW = (size.width - 1.0) / 2.0;
      final halfH = (size.height - 1.0) / 2.0;
      rects.add(Rect.fromLTWH(0, 0, halfW, size.height));
      rects.add(Rect.fromLTWH(halfW + 1.0, 0, halfW, halfH));
      rects.add(Rect.fromLTWH(halfW + 1.0, halfH + 1.0, halfW, halfH));
    } else {
      final halfW = (size.width - 1.0) / 2.0;
      final halfH = (size.height - 1.0) / 2.0;
      rects.add(Rect.fromLTWH(0, 0, halfW, halfH));
      rects.add(Rect.fromLTWH(halfW + 1.0, 0, halfW, halfH));
      rects.add(Rect.fromLTWH(0, halfH + 1.0, halfW, halfH));
      rects.add(Rect.fromLTWH(halfW + 1.0, halfH + 1.0, halfW, halfH));
    }

    final int renderCount = count.clamp(0, rects.length);

    for (int i = 0; i < renderCount; i++) {
      final path = images[i];
      final rect = rects[i];

      final ui.Image? img = CalendarImageCache.get(path);
      if (img != null) {
        // 居中裁剪 (BoxFit.cover) 离屏绘制 srcRect
        final double srcW = img.width.toDouble();
        final double srcH = img.height.toDouble();
        final double dstAspect = rect.width / rect.height;
        final double srcAspect = srcW / srcH;

        Rect srcRect;
        if (srcAspect > dstAspect) {
          final double targetW = srcH * dstAspect;
          final double left = (srcW - targetW) / 2.0;
          srcRect = Rect.fromLTWH(left, 0, targetW, srcH);
        } else {
          final double targetH = srcW / dstAspect;
          final double top = (srcH - targetH) / 2.0;
          srcRect = Rect.fromLTWH(0, top, srcW, targetH);
        }

        canvas.drawImageRect(img, srcRect, rect, paint);
      } else {
        // 解码微秒瞬间：绘制高雅软浅调，零灰块遮挡
        canvas.drawRect(rect, fallbackPaint);
        CalendarImageCache.load(path, onRequestRepaint);
      }

      // 如果超出 4 张照片，在第 4 个格子(index 3)上绘制黑调透明遮罩与 +N 数字
      if (images.length > 4 && i == 3) {
        final overlayPaint = Paint()
          ..color = Colors.black.withValues(alpha: 0.5);
        canvas.drawRect(rect, overlayPaint);

        final textPainter = TextPainter(
          text: TextSpan(
            text: '+${images.length - 4}',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w900,
            ),
          ),
          textDirection: TextDirection.ltr,
        )..layout();

        final textOffset = Offset(
          rect.left + (rect.width - textPainter.width) / 2.0,
          rect.top + (rect.height - textPainter.height) / 2.0,
        );
        textPainter.paint(canvas, textOffset);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CalendarCoverPainter oldDelegate) {
    return true;
  }
}
