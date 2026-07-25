import 'dart:io';
import 'dart:typed_data';

/// 照片墙图片内存字节缓存服务
/// 用于预载入与高速获取解包图片字节，消除网格和卡片渲染时的加载闪落与白屏
class PhotoWallImageCache {
  static final Map<String, Uint8List> _cache = {};

  /// 获取指定路径的图片字节
  static Uint8List? get(String path) {
    return _cache[path];
  }

  /// 放入/更新指定路径的图片字节
  static void put(String path, Uint8List? bytes) {
    if (bytes != null) {
      _cache[path] = bytes;
    }
  }

  /// 移除指定路径的缓存
  static void remove(String path) {
    _cache.remove(path);
  }

  /// 清空内存缓存
  static void clear() {
    _cache.clear();
  }

  /// 同步预热所有本地图片路径到内存
  static void preloadSync(List<String> paths) {
    for (final path in paths) {
      if (_cache.containsKey(path)) continue;
      if (path.startsWith('assets/')) continue;
      try {
        final file = File(path);
        if (file.existsSync()) {
          _cache[path] = file.readAsBytesSync();
        }
      } catch (_) {}
    }
  }

  /// 异步预热所有本地图片路径到内存
  static Future<void> preload(List<String> paths) async {
    for (final path in paths) {
      if (_cache.containsKey(path)) continue;
      if (path.startsWith('assets/')) continue;
      try {
        final file = File(path);
        if (await file.exists()) {
          final bytes = await file.readAsBytes();
          _cache[path] = bytes;
        }
      } catch (_) {}
    }
  }
}
