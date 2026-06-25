import 'dart:io';
import 'dart:async';
import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:island_diary/features/record/presentation/utils/camera_matting_processor.dart';
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

      // 2. 调用 Remove.bg 云端 API 处理图像，返回抠图后的透明 PNG 路径
      final String mattingResultPath = await CameraMattingProcessor.processCloudMatting(workingPath);

      // 如果抠图失败（返回了原图路径，即没有扣成功），我们就不做描边，直接返回原图
      if (mattingResultPath == workingPath) {
        final Uint8List originalBytes = await File(workingPath).readAsBytes();
        if (workingPath != imagePath) {
          try {
            await File(workingPath).delete();
          } catch (_) {}
        }
        return originalBytes;
      }

      // 3. 解码抠图后的透明 PNG 为 ui.Image 对象
      final Uint8List croppedBytes = await File(mattingResultPath).readAsBytes();
      final ui.Codec codec = await ui.instantiateImageCodec(croppedBytes);
      final ui.FrameInfo frameInfo = await codec.getNextFrame();
      final ui.Image croppedSubjectImage = frameInfo.image;

      final int width = croppedSubjectImage.width;
      final int height = croppedSubjectImage.height;

      // 4. 新建 PictureRecorder 并通过 Canvas 开始烘焙卡通白色描边
      final recorder = ui.PictureRecorder();
      final canvas = ui.Canvas(recorder);
      final paint = ui.Paint();

      // 5. 极致 360 度多向平滑叠加算法，烘焙出完美的 12px 白色实心描边
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

      // 6. 导出并返回透明带白边的 PNG
      final ui.Picture finalPicture = recorder.endRecording();
      final ui.Image finalImage = await finalPicture.toImage(width, height);
      final ByteData? pngBytes = await finalImage.toByteData(format: ui.ImageByteFormat.png);

      // 释放所有中间 Image 对象，彻底避免 GPU 内存泄漏
      croppedSubjectImage.dispose();
      finalImage.dispose();

      // 删除产生的临时缩放文件和抠图结果文件，保持磁盘整洁
      if (workingPath != imagePath) {
        try {
          await File(workingPath).delete();
        } catch (_) {}
      }
      try {
        await File(mattingResultPath).delete();
      } catch (_) {}

      return pngBytes?.buffer.asUint8List();
    } catch (e) {
      debugPrint("StickerSegmentationService Error: $e");
      return null;
    }
  }
}
