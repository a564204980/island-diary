import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:path_provider/path_provider.dart';

/// 照片墙展板离线封面快照截图生成服务
class PhotoWallSnapshotService {
  /// 捕获 RepaintBoundary 组件画幅并保存为离线缩略图文件
  static Future<String?> captureAndSaveSnapshot({
    required GlobalKey boundaryKey,
    required String collectionId,
  }) async {
    try {
      final boundary = boundaryKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
      if (boundary == null || boundary.debugNeedsPaint) {
        return null;
      }

      // 以 1.5 倍精细 pixelRatio 进行超轻离线渲染
      final ui.Image image = await boundary.toImage(pixelRatio: 1.5);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      if (byteData == null) return null;

      final pngBytes = byteData.buffer.asUint8List();

      final docDir = await getApplicationDocumentsDirectory();
      final coverDir = Directory('${docDir.path}/photo_wall_covers');
      if (!await coverDir.exists()) {
        await coverDir.create(recursive: true);
      }

      // 1. 清理该集合所有旧版本的快照文件，防止占用磁盘空间
      try {
        final files = coverDir.listSync();
        for (var f in files) {
          if (f is File && f.path.contains('cover_$collectionId')) {
            await f.delete();
          }
        }
      } catch (_) {}

      // 2. 使用当前时间戳作为文件名，确保路径唯一性，强制刷新 Flutter 的 ImageCache 和内存缓存
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final filePath = '${coverDir.path}/cover_${collectionId}_$timestamp.png';
      final file = File(filePath);

      await file.writeAsBytes(pngBytes, flush: true);

      return filePath;
    } catch (e) {
      debugPrint("生成照片墙封面快照失败: $e");
      return null;
    }
  }
}
