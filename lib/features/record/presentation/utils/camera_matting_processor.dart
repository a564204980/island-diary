import 'dart:io';
import 'package:http/http.dart' as http;

class CameraMattingProcessor {
  // 维护一个 Remove.bg API Keys 密钥池
  static final List<String> _apiKeys = [
    'mrxFo3U2XiPehVZU4qM5Wixd',
    '4ZXkKRPRWHnZqpdLY85U9Q8V',
    'P3EJNmhHUmfqQnreV5WtkkPM',
    '9sGoaPNuitopAa23FqU7C2gZ',
    'mgLub8VEQauSDPMoLshPPeph', // 新增的密钥
  ];

  static int _currentKeyIndex = 0;

  /// 使用 Remove.bg 的云端 API 进行高精度发丝级抠图
  static Future<String> processCloudMatting(String inputPath) async {
    final file = File(inputPath);
    if (!file.existsSync()) return inputPath;

    int attempts = 0;
    while (attempts < _apiKeys.length) {
      final String apiKey = _apiKeys[_currentKeyIndex];
      print("正在尝试使用 Remove.bg 密钥 [索引 $_currentKeyIndex]: $apiKey");

      try {
        final request = http.MultipartRequest(
          'POST',
          Uri.parse('https://api.remove.bg/v1.0/removebg'),
        );
        request.headers['X-Api-Key'] = apiKey;
        request.files.add(await http.MultipartFile.fromPath('image_file', file.path));
        request.fields['size'] = 'auto';

        final response = await request.send();
        if (response.statusCode == 200) {
          final responseBytes = await response.stream.toBytes();
          final String tempDir = Directory.systemTemp.path;
          final String outPath = '$tempDir/cloud_matting_${DateTime.now().millisecondsSinceEpoch}.png';
          await File(outPath).writeAsBytes(responseBytes);
          return outPath;
        } else {
          final errText = await response.stream.bytesToString();
          print("Remove.bg 密钥 [$apiKey] 发生错误: Code ${response.statusCode}, Msg: $errText");
          
          // 只要响应不是 200 (例如 402 余额不足，403 无效)，即视为当前 Key 失效，自动推移至下一个 Key
          _currentKeyIndex = (_currentKeyIndex + 1) % _apiKeys.length;
          attempts++;
        }
      } catch (e) {
        print("密钥 [$apiKey] 抠图过程网络异常: $e");
        _currentKeyIndex = (_currentKeyIndex + 1) % _apiKeys.length;
        attempts++;
      }
    }

    print("所有的 Remove.bg 密钥都已尝试失败");
    return inputPath;
  }
}
