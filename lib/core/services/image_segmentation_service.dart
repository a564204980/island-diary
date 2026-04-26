import 'dart:io' as io;
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:google_mlkit_subject_segmentation/google_mlkit_subject_segmentation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

/// AI 图像分割服务：实现智能抠图与自定义贴纸创造
class ImageSegmentationService {
  static final ImageSegmentationService _instance = ImageSegmentationService._internal();
  factory ImageSegmentationService() => _instance;
  ImageSegmentationService._internal();

  final SubjectSegmenter _segmenter = SubjectSegmenter(
    options: SubjectSegmenterOptions(
      enableForegroundBitmap: true,
      enableForegroundConfidenceMask: true,
      enableMultipleSubjects: SubjectResultOptions(
        enableConfidenceMask: true,
        enableSubjectBitmap: true,
      ), // 0.0.3 版本需要具体配置项
    ),
  );

  /// 核心方法：抠出照片中的主体并返回透明底 PNG 数据
  Future<Uint8List?> segmentSubject(String imagePath) async {
    final inputImage = InputImage.fromFilePath(imagePath);
    
    try {
      // 1. 先通过原始文件获取图片的真实宽高
      final Uint8List originalBytes = await io.File(imagePath).readAsBytes();
      final ui.Codec codec = await ui.instantiateImageCodec(originalBytes);
      final ui.FrameInfo frameInfo = await codec.getNextFrame();
      final int width = frameInfo.image.width;
      final int height = frameInfo.image.height;

      // 2. 执行 AI 抠图
      final result = await _segmenter.processImage(inputImage);
      
      // 提取前景位图数据
      final Uint8List? foregroundRGBA = result.foregroundBitmap;
      if (foregroundRGBA == null) return null;

      if (width == 0 || height == 0) return null;

      final ui.ImmutableBuffer buffer = await ui.ImmutableBuffer.fromUint8List(foregroundRGBA);
      final ui.ImageDescriptor descriptor = ui.ImageDescriptor.raw(
        buffer,
        width: width,
        height: height,
        pixelFormat: ui.PixelFormat.rgba8888,
      );
      
      final ui.Codec pngCodec = await descriptor.instantiateCodec();
      final ui.FrameInfo pngFrameInfo = await pngCodec.getNextFrame();
      final ui.Image image = pngFrameInfo.image;
      
      final ByteData? byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      return byteData?.buffer.asUint8List();
    } catch (e) {
      debugPrint("AI Segmentation Error: $e");
      return null;
    }
  }

  /// 将抠出的贴纸保存到本地“我的贴纸”目录
  Future<String?> saveAsSticker(Uint8List pngBytes) async {
    try {
      final appDocDir = await getApplicationDocumentsDirectory();
      final stickerDir = io.Directory(p.join(appDocDir.path, 'custom_stickers'));
      
      if (!await stickerDir.exists()) {
        await stickerDir.create(recursive: true);
      }

      final String fileName = "sticker_${DateTime.now().millisecondsSinceEpoch}.png";
      final io.File file = io.File(p.join(stickerDir.path, fileName));
      await file.writeAsBytes(pngBytes);
      
      return file.path;
    } catch (e) {
      debugPrint("Failed to save sticker: $e");
      return null;
    }
  }

  /// 获取所有已创造的自定义贴纸
  Future<List<String>> getCustomStickers() async {
    try {
      final appDocDir = await getApplicationDocumentsDirectory();
      final stickerDir = io.Directory(p.join(appDocDir.path, 'custom_stickers'));
      
      if (!await stickerDir.exists()) return [];

      final List<io.FileSystemEntity> files = stickerDir.listSync();
      return files
          .whereType<io.File>()
          .where((f) => f.path.endsWith('.png'))
          .map((f) => f.path)
          .toList()
          ..sort((a, b) => b.compareTo(a)); // 按时间倒序
    } catch (e) {
      debugPrint("Failed to list stickers: $e");
      return [];
    }
  }

  void dispose() {
    _segmenter.close();
  }
}
