import 'dart:io';
import 'package:path/path.dart' as path_utils;
import 'package:path_provider/path_provider.dart';

/// 照片墙专属磁盘持久化服务
///
/// 解决系统相册选图产生的临时缓存路径 (tmp/cache) 被系统清理
/// 导致的列表页及首页相框出现白色空白块的问题。
class PhotoWallStorageService {
  static Directory? _storageDir;

  /// 获取或创建照片墙专属永久存储目录
  static Future<Directory> getStorageDirectory() async {
    if (_storageDir != null && _storageDir!.existsSync()) {
      return _storageDir!;
    }
    final appDocDir = await getApplicationDocumentsDirectory();
    final targetDir = Directory(path_utils.join(appDocDir.path, 'photo_wall_photos'));
    if (!targetDir.existsSync()) {
      await targetDir.create(recursive: true);
    }
    _storageDir = targetDir;
    return targetDir;
  }

  /// 将相册中选中的图片物理复制并持久化到专属目录中
  ///
  /// 如果路径已在专属目录中或是内置 assets 资源，则直接返回原路径
  static Future<String> savePhotoToPermanentStorage(String srcPath) async {
    if (srcPath.isEmpty || srcPath.startsWith('assets/')) {
      return srcPath;
    }

    try {
      final srcFile = File(srcPath);
      if (!srcFile.existsSync()) {
        return srcPath;
      }

      final permDir = await getStorageDirectory();

      // 如果已经在永久存储目录中，无需重复复制
      if (path_utils.equals(srcFile.parent.path, permDir.path)) {
        return srcPath;
      }

      final String ext = path_utils.extension(srcPath).isNotEmpty
          ? path_utils.extension(srcPath)
          : '.jpg';
      final String fileName =
          'pw_${DateTime.now().microsecondsSinceEpoch}_${srcPath.hashCode.abs()}$ext';
      final String destPath = path_utils.join(permDir.path, fileName);

      await srcFile.copy(destPath);
      return destPath;
    } catch (_) {
      return srcPath;
    }
  }

  /// 批量持久化图片路径
  static Future<List<String>> savePhotosToPermanentStorage(List<String> srcPaths) async {
    final List<String> result = [];
    for (final p in srcPaths) {
      final permPath = await savePhotoToPermanentStorage(p);
      result.add(permPath);
    }
    return result;
  }

  /// 智能自动修复失效路径（解决 iOS 沙盒 UUID 重置、盘符变动导致的图片无法回显问题）
  static String toValidAbsolutePathSync(String rawPath) {
    if (rawPath.isEmpty || rawPath.startsWith('assets/')) {
      return rawPath;
    }

    try {
      final directFile = File(rawPath);
      if (directFile.existsSync()) {
        return rawPath;
      }
    } catch (_) {}

    final fileName = path_utils.basename(rawPath);
    if (_storageDir != null && _storageDir!.existsSync()) {
      final repairedPath = path_utils.join(_storageDir!.path, fileName);
      try {
        if (File(repairedPath).existsSync()) {
          return repairedPath;
        }
      } catch (_) {}
    }

    return rawPath;
  }

  /// 智能自动修复失效路径（异步版本）
  static Future<String> toValidAbsolutePath(String rawPath) async {
    if (rawPath.isEmpty || rawPath.startsWith('assets/')) {
      return rawPath;
    }

    try {
      final directFile = File(rawPath);
      if (await directFile.exists()) {
        return rawPath;
      }
    } catch (_) {}

    final fileName = path_utils.basename(rawPath);
    final permDir = await getStorageDirectory();
    final repairedPath = path_utils.join(permDir.path, fileName);
    try {
      if (await File(repairedPath).exists()) {
        return repairedPath;
      }
    } catch (_) {}

    return rawPath;
  }
}
