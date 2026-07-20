// ignore_for_file: avoid_print
import 'dart:io';
import 'package:image/image.dart' as img;

void main() {
  final dir = Directory('assets');
  if (!dir.existsSync()) {
    print('未找到 Assets 目录！');
    return;
  }
  
  final files = dir.listSync(recursive: true).whereType<File>().toList();
  int processedCount = 0;
  double totalSavedMB = 0;

  print('正在扫描 assets 目录中的大型图片文件...');

  for (final file in files) {
    final path = file.path.toLowerCase();
    if (!path.endsWith('.png') && !path.endsWith('.jpg') && !path.endsWith('.jpeg')) {
      continue;
    }
    
    final length = file.lengthSync();
    // 仅压缩大于 1.5 MB 的图片
    if (length < 1.5 * 1024 * 1024) {
      continue;
    }

    final originalMB = length / 1024 / 1024;
    print('正在处理: ${file.path} (${originalMB.toStringAsFixed(2)} MB)');
    
    try {
      final bytes = file.readAsBytesSync();
      final image = img.decodeImage(bytes);
      if (image == null) {
        print('  解码图片失败。');
        continue;
      }
      
      img.Image processedImage = image;
      bool modified = false;

      // 如果尺寸过大则进行缩放（主流设备不需要大于 1600px 的背景）
      const int maxDimension = 1600;
      if (image.width > maxDimension || image.height > maxDimension) {
        if (image.width > image.height) {
          final height = (image.height * (maxDimension / image.width)).round();
          processedImage = img.copyResize(image, width: maxDimension, height: height);
        } else {
          final width = (image.width * (maxDimension / image.height)).round();
          processedImage = img.copyResize(image, width: width, height: maxDimension);
        }
        modified = true;
        print('  已缩放：从 ${image.width}x${image.height} 到 ${processedImage.width}x${processedImage.height}');
      }

      List<int> outBytes;
      if (path.endsWith('.png')) {
        outBytes = img.encodePng(processedImage, level: 9);
      } else {
        outBytes = img.encodeJpg(processedImage, quality: 85);
      }

      final compressedMB = outBytes.length / 1024 / 1024;
      final savedMB = originalMB - compressedMB;

      if (savedMB > 0.1 || modified) {
        file.writeAsBytesSync(outBytes);
        totalSavedMB += savedMB;
        processedCount++;
        print('  已保存，节省了: ${savedMB.toStringAsFixed(2)} MB (新大小: ${compressedMB.toStringAsFixed(2)} MB)');
      } else {
        print('  体积没有明显减小，跳过保存。');
      }
    } catch (e) {
      print('  处理文件时发生错误: $e');
    }
  }

  print('\n压缩完成！');
  print('共处理了 $processedCount 张图片。');
  print('总计节省空间: ${totalSavedMB.toStringAsFixed(2)} MB');
}
