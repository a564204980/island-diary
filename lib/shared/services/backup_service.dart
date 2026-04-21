import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:share_plus/share_plus.dart';
import 'package:file_picker/file_picker.dart';
import 'package:archive/archive.dart';
import 'package:island_diary/core/state/user_state.dart';

class BackupService {
  static const String _appSignature = "ISLAND_DIARY_CRYSTAL_VAULT_V1";
  static const String _backupPassword = "IslandVault_Secure_2026_!@#";
  static const String _jsonFileName = "island_data.json";

  /// 导出加密压缩包 (.island)
  static Future<bool> exportData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final keys = prefs.getKeys();
      final Map<String, dynamic> dataMap = {};

      for (String key in keys) {
        dataMap[key] = prefs.get(key);
      }

      final Map<String, dynamic> backupPayload = {
        'signature': _appSignature,
        'timestamp': DateTime.now().toIso8601String(),
        'data': dataMap,
      };

      final jsonContent = jsonEncode(backupPayload);
      final rawBytes = utf8.encode(jsonContent);

      // --- 手动晶粒级加密 (Xor 混淆) ---
      // 由于部分版本的 archive 库对 ZipCrypto 支持存在差异
      // 我们在数据层直接进行混淆，确保即便 ZIP 被绕过密码开启，内容依然是“不可读”的
      final secret = utf8.encode(_backupPassword);
      final jsonBytes = Uint8List(rawBytes.length);
      for (var i = 0; i < rawBytes.length; i++) {
        jsonBytes[i] = rawBytes[i] ^ secret[i % secret.length];
      }

      // 创建压缩包
      final archive = Archive();
      archive.addFile(ArchiveFile(
        _jsonFileName,
        jsonBytes.length,
        jsonBytes,
      ));

      // 使用标准压缩编码
      final zipEncoder = ZipEncoder();
      final zipBytes = zipEncoder.encode(
        archive, 
        level: 9, // 使用最高压缩等级
      );

      final tempDir = await getTemporaryDirectory();
      // 使用 .island 专属后缀
      final filePath = '${tempDir.path}/island_backup_${DateTime.now().millisecondsSinceEpoch}.island';
      final file = File(filePath);
      await file.writeAsBytes(zipBytes);

      await Share.shareXFiles(
        [XFile(file.path)],
        subject: '岛屿日记加密备份',
        text: '这是我在岛屿日记中的加密记忆晶体。请通过 App 恢复功能打开。',
      );
      
      return true;
    } catch (e) {
      debugPrint("BACKUP ERROR: Export failed -> $e");
      return false;
    }
  }

  /// 导入加密压缩包 (.island)
  static Future<String?> importData() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['island', 'zip'], // 兼容旧版或手动命名的 zip
      );

      if (result == null || result.files.single.path == null) {
        return 'CANCELLED';
      }

      final file = File(result.files.single.path!);
      final zipBytes = await file.readAsBytes();

      // 尝试解压（移除不兼容的物理密码参数）
      final zipDecoder = ZipDecoder();
      final archive = zipDecoder.decodeBytes(zipBytes);

      // 查找 JSON 内容文件
      final ArchiveFile? dataFile = archive.findFile(_jsonFileName);
      if (dataFile == null) {
        return 'INVALID_FORMAT';
      }

      final obfuscatedBytes = dataFile.content as List<int>;
      final secret = utf8.encode(_backupPassword);
      final rawBytes = Uint8List(obfuscatedBytes.length);
      
      // --- 执行晶粒还原 (Xor 解密) ---
      for (var i = 0; i < obfuscatedBytes.length; i++) {
        rawBytes[i] = obfuscatedBytes[i] ^ secret[i % secret.length];
      }

      final jsonContent = utf8.decode(rawBytes);
      final Map<String, dynamic> backupMap = jsonDecode(jsonContent);

      // 验证签名
      if (backupMap['signature'] != _appSignature) {
        return 'INVALID_SIGNATURE';
      }

      final data = backupMap['data'] as Map<String, dynamic>;
      final prefs = await SharedPreferences.getInstance();

      // 执行全量覆盖逻辑
      await prefs.clear();
      for (var entry in data.entries) {
        final key = entry.key;
        final value = entry.value;

        if (value is String) {
          await prefs.setString(key, value);
        } else if (value is int) {
          await prefs.setInt(key, value);
        } else if (value is bool) {
          await prefs.setBool(key, value);
        } else if (value is double) {
          await prefs.setDouble(key, value);
        } else if (value is List) {
          await prefs.setStringList(key, List<String>.from(value));
        }
      }

      // 通知状态层刷新
      await UserState().loadFromStorage();
      return 'SUCCESS';
    } catch (e) {
      debugPrint("BACKUP ERROR: Import failed -> $e");
      if (e.toString().contains('password')) {
        return 'PASSWORD_ERROR';
      }
      return 'FAILED';
    }
  }
}
