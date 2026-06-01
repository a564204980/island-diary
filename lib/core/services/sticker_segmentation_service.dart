import 'dart:io';
import 'dart:async';
import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:google_mlkit_selfie_segmentation/google_mlkit_selfie_segmentation.dart';
import 'package:path_provider/path_provider.dart';

/// 贴纸分割与描边烘焙服务
class StickerSegmentationService {
  static final StickerSegmentationService _instance = StickerSegmentationService._internal();
  factory StickerSegmentationService() => _instance;
  StickerSegmentationService._internal();

  /// 辅助工具：将大图等比例缩放到最大 1000px 以内并存为临时文件，防止高分辨率 OOM 与 ANR
  Future<String?> _resizeImageToTemp(String imagePath) async {
    try {
      final Uint8List originalBytes = await File(imagePath).readAsBytes();
      ui.Codec codec = await ui.instantiateImageCodec(originalBytes);
      ui.FrameInfo frameInfo = await codec.getNextFrame();
      ui.Image tempImage = frameInfo.image;

      final int width = tempImage.width;
      final int height = tempImage.height;
      tempImage.dispose();

      if (width <= 1000 && height <= 1000) {
        return imagePath; // 小于 1000 像素，不需要缩放，直接使用原路径
      }

      final double ratio = 1000.0 / math.max(width, height);
      final int targetWidth = (width * ratio).round();
      final int targetHeight = (height * ratio).round();

      codec = await ui.instantiateImageCodec(
        originalBytes,
        targetWidth: targetWidth,
        targetHeight: targetHeight,
      );
      frameInfo = await codec.getNextFrame();
      final ui.Image scaledImage = frameInfo.image;

      final ByteData? pngData = await scaledImage.toByteData(format: ui.ImageByteFormat.png);
      scaledImage.dispose();

      if (pngData == null) return null;

      final tempDir = await getTemporaryDirectory();
      final tempFile = File('${tempDir.path}/temp_resizing_sticker.png');
      await tempFile.writeAsBytes(pngData.buffer.asUint8List());

      return tempFile.path;
    } catch (e) {
      debugPrint("Resize image failed: $e");
      return null;
    }
  }

  /// 传入本地照片路径，自动分割人像主体，在其边缘烘焙 12 像素的精美白色卡通描边，并导出为 PNG 字节数组。
  Future<Uint8List?> segmentAndCropSubject(String imagePath) async {
    try {
      // 1. 预处理：先将可能存在的超大原图缩放到 1000px 内，规避 GPU 显存及 CPU 像素大数组 OOM
      final String? workingPath = await _resizeImageToTemp(imagePath);
      if (workingPath == null) return null;

      final inputImage = InputImage.fromFilePath(workingPath);
      final segmenter = SelfieSegmenter(
        mode: SegmenterMode.single,
        enableRawSizeMask: true, // 保持与照片等大，防止变形
      );

      // 2. 调用谷歌 ML Kit 处理图像，返回分割掩码
      final mask = await segmenter.processImage(inputImage);
      await segmenter.close();

      if (mask == null) return null;

      // 3. 解码工作路径下的缩放图片为 ui.Image 对象
      final Uint8List originalBytes = await File(workingPath).readAsBytes();
      final ui.Codec codec = await ui.instantiateImageCodec(originalBytes);
      final ui.FrameInfo frameInfo = await codec.getNextFrame();
      final ui.Image originalImage = frameInfo.image;

      final int width = originalImage.width;
      final int height = originalImage.height;

      // 4. 构建掩码图像（将置信度转化为非透明色和透明色）
      final List<double> confidences = mask.confidences;
      final int maskWidth = mask.width;
      final int maskHeight = mask.height;

      final Uint32List pixels = Uint32List(maskWidth * maskHeight);
      for (int i = 0; i < confidences.length; i++) {
        final double confidence = confidences[i];
        if (confidence > 0.7) {
          pixels[i] = 0xFFFFFFFF; // 纯白色（完全不透明）保留主体
        } else {
          pixels[i] = 0x00000000; // 完全透明过滤背景
        }
      }

      final ui.Image maskImage = await _createImageFromPixels(pixels, maskWidth, maskHeight);

      // 5. 新建 PictureRecorder 并通过 Canvas 开始烘焙融合与卡通白色描边
      final recorder = ui.PictureRecorder();
      final canvas = ui.Canvas(recorder);
      final paint = ui.Paint();

      // 先创建主体透明图层
      final transparentRecorder = ui.PictureRecorder();
      final transparentCanvas = ui.Canvas(transparentRecorder);
      transparentCanvas.drawImage(originalImage, ui.Offset.zero, paint);
      
      // 使用 BlendMode.dstIn 融切掉背景
      final paintDstIn = ui.Paint()..blendMode = ui.BlendMode.dstIn;
      transparentCanvas.drawImageRect(
        maskImage,
        ui.Rect.fromLTWH(0, 0, maskWidth.toDouble(), maskHeight.toDouble()),
        ui.Rect.fromLTWH(0, 0, width.toDouble(), height.toDouble()),
        paintDstIn,
      );

      final ui.Image croppedSubjectImage = await (await transparentRecorder.endRecording().toImage(width, height));

      // 6. 极致 360 度多向平滑叠加算法，烘焙出完美的 12px 白色实心描边
      final double strokeWidth = 12.0; // 卡通贴纸经典描边宽度
      final double angleStep = 0.2;     // 高采样率保证绝对圆滑
      final ui.Paint strokePaint = ui.Paint()
        ..colorFilter = const ui.ColorFilter.mode(Colors.white, ui.BlendMode.srcIn);

      final ui.Rect imgRect = ui.Rect.fromLTWH(0, 0, width.toDouble(), height.toDouble());

      // 绘制四周的白色影子，形成描边
      for (double angle = 0; angle < 2 * math.pi; angle += angleStep) {
        final double dx = strokeWidth * math.cos(angle);
        final double dy = strokeWidth * math.sin(angle);
        canvas.drawImageRect(
          croppedSubjectImage,
          imgRect,
          imgRect.translate(dx, dy),
          strokePaint,
        );
      }

      // 最后把清晰的裁切主体盖在白色描边层最中央
      canvas.drawImageRect(croppedSubjectImage, imgRect, imgRect, paint);

      // 7. 导出并返回透明带白边的 PNG
      final ui.Picture finalPicture = recorder.endRecording();
      final ui.Image finalImage = await finalPicture.toImage(width, height);
      final ByteData? pngBytes = await finalImage.toByteData(format: ui.ImageByteFormat.png);

      // 释放所有中间 Image 对象，彻底避免 GPU 内存泄漏
      originalImage.dispose();
      maskImage.dispose();
      croppedSubjectImage.dispose();
      finalImage.dispose();

      // 删除产生的临时缩放文件，保持磁盘整洁
      if (workingPath != imagePath) {
        try {
          await File(workingPath).delete();
        } catch (_) {}
      }

      return pngBytes?.buffer.asUint8List();
    } catch (e) {
      debugPrint("StickerSegmentationService Error: $e");
      return null;
    }
  }

  /// 辅助工具：从像素值创建 Image
  Future<ui.Image> _createImageFromPixels(Uint32List pixels, int width, int height) {
    final completer = Completer<ui.Image>();
    ui.decodeImageFromPixels(
      pixels.buffer.asUint8List(),
      width,
      height,
      ui.PixelFormat.rgba8888,
      (ui.Image image) => completer.complete(image),
    );
    return completer.future;
  }
}
