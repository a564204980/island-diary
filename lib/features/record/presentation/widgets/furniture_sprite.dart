import 'dart:async';
import 'package:flutter/material.dart';
import 'dart:ui' as ui;
import 'dart:typed_data';
import '../../domain/models/furniture_item.dart';

class FurnitureSprite extends StatefulWidget {
  final FurnitureItem item;
  const FurnitureSprite({super.key, required this.item});

  static Future<void> precacheItem(FurnitureItem item, BuildContext context) async {
    final ImageStream stream = AssetImage(
      item.imagePath,
    ).resolve(createLocalImageConfiguration(context));
    final Completer<void> completer = Completer();
    
    ImageStreamListener? listener;
    listener = ImageStreamListener((ImageInfo info, bool _) async {
      await SpritePainter.cacheImage(item.imagePath, info.image);
      if (!completer.isCompleted) {
        completer.complete();
      }
      // 成功后移除监听，防止内存泄露
      if (listener != null) {
        stream.removeListener(listener);
      }
    }, onError: (exception, stackTrace) {
      debugPrint('Failed to precache furniture: ${item.imagePath}');
      if (!completer.isCompleted) {
        completer.complete();
      }
    });

    stream.addListener(listener);
    return completer.future;
  }

  @override
  State<FurnitureSprite> createState() => _FurnitureSpriteState();
}

class _FurnitureSpriteState extends State<FurnitureSprite> {
  ui.Image? _image;
  ImageStream? _imageStream;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _loadImage();
  }

  void _loadImage() {
    final ImageStream newStream = AssetImage(
      widget.item.imagePath,
    ).resolve(createLocalImageConfiguration(context));
    if (newStream.key == _imageStream?.key) return;

    _imageStream?.removeListener(ImageStreamListener(_updateImage));
    _imageStream = newStream;
    _imageStream!.addListener(ImageStreamListener(_updateImage));
  }

  void _updateImage(ImageInfo info, bool _) async {
    if (mounted) {
      await SpritePainter.cacheImage(widget.item.imagePath, info.image);
      setState(() {
        _image = info.image;
      });
    }
  }

  @override
  void didUpdateWidget(covariant FurnitureSprite oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.item.id != oldWidget.item.id || 
        widget.item.imagePath != oldWidget.item.imagePath) {
      _loadImage();
    }
  }

  @override
  void dispose() {
    _imageStream?.removeListener(ImageStreamListener(_updateImage));
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_image == null) return const SizedBox.shrink();
    return CustomPaint(
      painter: SpritePainter(
        image: _image!,
        spriteRect: widget.item.spriteRect,
      ),
    );
  }
}

class SpritePainter extends CustomPainter {
  final ui.Image image;
  final Rect spriteRect;
  static final Map<String, ui.Image> _imageBucket = {};
  static final Map<String, Uint8List> _alphaBucket = {};

  SpritePainter({required this.image, required this.spriteRect});

  static Future<void> cacheImage(String path, ui.Image img) async {
    _imageBucket[path] = img;
    // 异步提取 Alpha 通道
    if (!_alphaBucket.containsKey(path)) {
      final byteData = await img.toByteData(format: ui.ImageByteFormat.rawRgba);
      if (byteData != null) {
        final buffer = byteData.buffer.asUint8List();
        final alphaMask = Uint8List(img.width * img.height);
        for (int i = 0; i < alphaMask.length; i++) {
          alphaMask[i] = buffer[i * 4 + 3]; // 每四个字节的第 4 位是 Alpha
        }
        _alphaBucket[path] = alphaMask;
      }
    }
  }

  static ui.Image? getImage(String path) => _imageBucket[path];

  /// 获取指定路径图片的像素透明度
  /// [x], [y] 是图片原始像素坐标
  static int getAlphaAt(String path, int x, int y) {
    final img = _imageBucket[path];
    final mask = _alphaBucket[path];
    if (img == null || mask == null) return 255; // 未加载完则默认通过矩形碰撞
    if (x < 0 || y < 0 || x >= img.width || y >= img.height) return 0;
    return mask[y * img.width + x];
  }

  @override
  void paint(Canvas canvas, Size size) {
    final src = Rect.fromLTWH(
      spriteRect.left * image.width,
      spriteRect.top * image.height,
      spriteRect.width * image.width,
      spriteRect.height * image.height,
    );
    final dst = Rect.fromLTWH(0, 0, size.width, size.height);
    canvas.drawImageRect(
      image,
      src,
      dst,
      Paint()..filterQuality = ui.FilterQuality.high,
    );
  }

  @override
  bool shouldRepaint(covariant SpritePainter oldDelegate) =>
      oldDelegate.image != image || oldDelegate.spriteRect != spriteRect;
}
