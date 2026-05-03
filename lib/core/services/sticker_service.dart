import 'dart:io' as io;
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

/// 贴纸服务：负责自定义贴纸的本地存储与获取
class StickerService {
  static final StickerService _instance = StickerService._internal();
  factory StickerService() => _instance;
  StickerService._internal();

  /// 将图片字节保存到本地"我的贴纸"目录
  Future<String?> saveAsSticker(Uint8List bytes) async {
    try {
      final appDocDir = await getApplicationDocumentsDirectory();
      final stickerDir = io.Directory(p.join(appDocDir.path, 'custom_stickers'));
      
      if (!await stickerDir.exists()) {
        await stickerDir.create(recursive: true);
      }

      final String fileName = "sticker_${DateTime.now().millisecondsSinceEpoch}.png";
      final io.File file = io.File(p.join(stickerDir.path, fileName));
      await file.writeAsBytes(bytes);
      
      return file.path;
    } catch (e) {
      debugPrint("Failed to save sticker: $e");
      return null;
    }
  }

  /// 获取所有已保存的自定义贴纸路径
  Future<List<String>> getCustomStickers() async {
    try {
      final appDocDir = await getApplicationDocumentsDirectory();
      final stickerDir = io.Directory(p.join(appDocDir.path, 'custom_stickers'));
      
      if (!await stickerDir.exists()) return [];

      final List<io.FileSystemEntity> files = stickerDir.listSync();
      return files
          .whereType<io.File>()
          .where((f) {
            final lower = f.path.toLowerCase();
            return lower.endsWith('.png') || lower.endsWith('.jpg') || lower.endsWith('.jpeg');
          })
          .map((f) => f.path)
          .toList()
          ..sort((a, b) => b.compareTo(a)); 
    } catch (e) {
      debugPrint("Failed to list stickers: $e");
      return [];
    }
  }
}
