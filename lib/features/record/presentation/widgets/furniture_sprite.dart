import 'package:flutter/material.dart';
import 'dart:ui' as ui;
import '../../domain/models/furniture_item.dart';

class FurnitureSprite extends StatefulWidget {
  final FurnitureItem item;
  const FurnitureSprite({super.key, required this.item});

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

  void _updateImage(ImageInfo info, bool _) {
    if (mounted) {
      SpritePainter.cacheImage(widget.item.imagePath, info.image);
      setState(() {
        _image = info.image;
      });
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

  SpritePainter({required this.image, required this.spriteRect}) {
    // 自动缓存，供底座共享显示
    _imageBucket[image.toString()] = image;
  }

  // 修改：改为按 Path 存取
  static void cacheImage(String path, ui.Image img) => _imageBucket[path] = img;
  static ui.Image? getImage(String path) => _imageBucket[path];

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
