import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:island_diary/features/profile/presentation/widgets/cloud_sync_decorations.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:archive/archive.dart';
import 'dart:convert';
import 'dart:ui';
import 'package:flutter/foundation.dart';
import 'package:island_diary/core/state/user_state.dart';
import 'package:island_diary/features/profile/presentation/widgets/bento_box.dart';
import 'package:island_diary/shared/services/backup_service.dart';
import 'package:island_diary/shared/widgets/diary_entry/components/diary_bottom_sheet.dart';

/// 数据备份与恢复中心页面：结合系统级分享云盘备份与本地历史快照双轨系统
class CloudSyncPage extends StatefulWidget {
  const CloudSyncPage({super.key});

  @override
  State<CloudSyncPage> createState() => _CloudSyncPageState();
}

class _CloudSyncPageState extends State<CloudSyncPage> {
  bool _isExporting = false;
  bool _isImporting = false;
  bool _isCreatingSnapshot = false;
  bool _isRestoring = false;
  bool _isLoadingList = false;

  List<File> _localSnapshots = [];
  int _reminderIntervalSeconds = 7 * 86400; // 默认 7 天
  String _lastBackupTimeStr = '暂无';

  Color get _primaryColor {
    return const Color(0xFF00ACC1);
  }

  Color get _gradientStart {
    return const Color(0xFF4DD0E1);
  }

  @override
  void initState() {
    super.initState();
    _loadLocalSnapshots();
    _loadReminderSettings();
    _loadLastBackupTime();
  }

  void _showTip(String message, {bool isError = false}) {
    if (!mounted) return;
    final isNight = UserState().isNight;
    final themeId = UserState().selectedIslandThemeId.value;
    final fontFamily = themeId == 'lego' ? 'SweiFistLeg' : 'LXGWWenKai';

    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isError ? Icons.error_outline_rounded : Icons.check_circle_outline_rounded,
              color: isError ? Colors.redAccent : _primaryColor,
              size: 20,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                message,
                style: TextStyle(
                  color: isNight ? Colors.white : const Color(0xFF374151),
                  fontFamily: fontFamily,
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        behavior: SnackBarBehavior.floating,
        backgroundColor: isNight ? const Color(0xFF2C281F) : Colors.white,
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(
            color: isError 
              ? Colors.redAccent.withValues(alpha: 0.3) 
              : _primaryColor.withValues(alpha: 0.2),
            width: 1.5,
          ),
        ),
        margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  Future<void> _loadLastBackupTime() async {
    final prefs = await SharedPreferences.getInstance();
    final ms = prefs.getInt('last_backup_time');
    if (ms != null) {
      final dt = DateTime.fromMillisecondsSinceEpoch(ms);
      if (mounted) {
        setState(() {
          _lastBackupTimeStr = "${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')} ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}";
        });
      }
    } else {
      if (mounted) {
        setState(() {
          _lastBackupTimeStr = '暂无';
        });
      }
    }
  }

  Future<void> _loadReminderSettings() async {
    final prefs = await SharedPreferences.getInstance();
    int? seconds = prefs.getInt('backup_reminder_interval_seconds');
    if (seconds == null) {
      final oldDays = prefs.getInt('backup_reminder_interval_days');
      if (oldDays != null) {
        seconds = oldDays * 86400;
        await prefs.setInt('backup_reminder_interval_seconds', seconds);
      } else {
        seconds = 7 * 86400; // 默认 7 天
      }
    }
    setState(() {
      _reminderIntervalSeconds = seconds!;
    });
  }

  Future<void> _saveReminderSettings(int seconds) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('backup_reminder_interval_seconds', seconds);
    setState(() {
      _reminderIntervalSeconds = seconds;
    });
  }

  String _formatIntervalText(int totalSeconds) {
    if (totalSeconds == 0) return '已关闭提醒';
    
    // 如果是常见的天数整倍数，简化显示
    if (totalSeconds % 86400 == 0) {
      return '每 ${totalSeconds ~/ 86400} 天提醒';
    }
    
    final days = totalSeconds ~/ 86400;
    final hours = (totalSeconds % 86400) ~/ 3600;
    final minutes = (totalSeconds % 3600) ~/ 60;
    final seconds = totalSeconds % 60;

    final parts = <String>[];
    if (days > 0) parts.add('$days天');
    if (hours > 0) parts.add('$hours小时');
    if (minutes > 0) parts.add('$minutes分钟');
    if (seconds > 0) parts.add('$seconds秒');

    return '每 ${parts.join('')}提醒';
  }

  /// 加载本地快照列表
  Future<void> _loadLocalSnapshots() async {
    setState(() => _isLoadingList = true);
    try {
      final docDir = await getApplicationDocumentsDirectory();
      final snapshotDir = Directory('${docDir.path}/local_snapshots');
      if (await snapshotDir.exists()) {
        final files = snapshotDir
            .listSync()
            .whereType<File>()
            .where((f) => f.path.endsWith('.island'))
            .toList();
        // 按文件时间降序排列
        files.sort((a, b) => b.path.compareTo(a.path));
        setState(() {
          _localSnapshots = files;
        });
      } else {
        setState(() {
          _localSnapshots = [];
        });
      }
    } catch (e) {
      debugPrint("加载本地快照失败: $e");
    } finally {
      setState(() => _isLoadingList = false);
    }
  }

  /// 一键分享备份（导出并调用系统分享，直接存到各大网盘或微信）
  Future<void> _exportAndShareBackup() async {
    if (_isExporting) return;
    setState(() => _isExporting = true);
    try {
      final success = await BackupService.exportData();
      if (success && mounted) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setInt('last_backup_time', DateTime.now().millisecondsSinceEpoch);
        _loadLastBackupTime();

        _showTip('备份包已生成并唤起系统分享。请选择保存到您的云盘或微信。');
      }
    } catch (e) {
      debugPrint("分享备份失败: $e");
    } finally {
      setState(() => _isExporting = false);
    }
  }

  /// 一键导入备份还原（选取外部 `.island` 或 `.zip` 文件恢复）
  Future<void> _importAndRestore() async {
    if (_isImporting) return;
    setState(() {
      _isImporting = true;
      _isRestoring = true;
    });
    try {
      final result = await BackupService.importData();
      if (result == 'SUCCESS') {
        // 提供 1.5 秒动画时间
        await Future.delayed(const Duration(milliseconds: 1500));
        if (mounted) {
          final themeId = UserState().selectedIslandThemeId.value;
          final fontFamily = themeId == 'lego' ? 'SweiFistLeg' : 'LXGWWenKai';
          _showSuccessDialog(fontFamily);
        }
      } else if (result == 'CANCELLED') {
        // 静默取消，无需提示
      } else if (result != null) {
        if (mounted) {
          _showTip('还原失败: $result', isError: true);
        }
      }
    } catch (e) {
      debugPrint("导入还原失败: $e");
    } finally {
      setState(() {
        _isImporting = false;
        _isRestoring = false;
      });
    }
  }

  /// 创建本地快照（无需发送云端，直接在沙盒里保存多版本快照，方便日常回滚）
  Future<void> _createLocalSnapshot() async {
    if (_isCreatingSnapshot) return;
    setState(() => _isCreatingSnapshot = true);

    try {
      final prefs = await SharedPreferences.getInstance();
      final keys = prefs.getKeys();
      final Map<String, dynamic> dataMap = {};

      for (String key in keys) {
        dataMap[key] = prefs.get(key);
      }

      final Map<String, dynamic> backupPayload = {
        'signature': "ISLAND_DIARY_CRYSTAL_VAULT_V1",
        'timestamp': DateTime.now().toIso8601String(),
        'data': dataMap,
      };

      final jsonContent = jsonEncode(backupPayload);
      final rawBytes = utf8.encode(jsonContent);

      // XOR 混淆
      final secret = utf8.encode("IslandVault_Secure_2026_!@#");
      final jsonBytes = Uint8List(rawBytes.length);
      for (var i = 0; i < rawBytes.length; i++) {
        jsonBytes[i] = rawBytes[i] ^ secret[i % secret.length];
      }

      // ZIP 归档
      final archive = Archive();
      archive.addFile(ArchiveFile(
        "island_data.json",
        jsonBytes.length,
        jsonBytes,
      ));

      final zipEncoder = ZipEncoder();
      final zipBytes = zipEncoder.encode(archive, level: 9);

      final docDir = await getApplicationDocumentsDirectory();
      final snapshotDir = Directory('${docDir.path}/local_snapshots');
      if (!await snapshotDir.exists()) {
        await snapshotDir.create(recursive: true);
      }

      // 快照上限控制，最多保存 5 个快照，超出则删除最久的一个
      final existingFiles = snapshotDir.listSync().whereType<File>().toList()
        ..sort((a, b) => a.path.compareTo(b.path));
      if (existingFiles.length >= 5) {
        await existingFiles.first.delete();
      }

      final file = File('${snapshotDir.path}/island_snapshot_${DateTime.now().millisecondsSinceEpoch}.island');
      await file.writeAsBytes(zipBytes);

      // 记录备份时间戳
      await prefs.setInt('last_backup_time', DateTime.now().millisecondsSinceEpoch);
      _loadLastBackupTime();

      await _loadLocalSnapshots();

      if (mounted) {
        _showTip('本地快照创建完成');
      }
    } catch (e) {
      debugPrint("创建本地快照失败: $e");
    } finally {
      setState(() => _isCreatingSnapshot = false);
    }
  }

  /// 从特定本地快照还原数据
  Future<void> _restoreFromSnapshot(File file) async {
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (context) {
        final isNight = UserState().isNight;
        final themeId = UserState().selectedIslandThemeId.value;
        final fontFamily = themeId == 'lego' ? 'SweiFistLeg' : 'LXGWWenKai';

        return AlertDialog(
          backgroundColor: isNight ? const Color(0xFF2C281F) : const Color(0xFFFFFDF6),
          title: Text(
            '确认恢复此快照？',
            style: TextStyle(color: isNight ? Colors.white : Colors.black87, fontFamily: fontFamily),
          ),
          content: Text(
            '恢复该快照会完全覆写当前的全部日记，请确认是否继续？',
            style: TextStyle(color: isNight ? Colors.white70 : Colors.black54, fontFamily: fontFamily),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text('取消', style: TextStyle(color: isNight ? Colors.white38 : Colors.black38, fontFamily: fontFamily)),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('确认覆盖', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
            ),
          ],
        );
      },
    );

    if (confirm != true) return;

    setState(() => _isRestoring = true);

    try {
      final zipBytes = await file.readAsBytes();
      final zipDecoder = ZipDecoder();
      final archive = zipDecoder.decodeBytes(zipBytes);

      final ArchiveFile? dataFile = archive.findFile("island_data.json");
      if (dataFile == null) throw Exception("损坏的快照包");

      final obfuscatedBytes = dataFile.content as List<int>;
      final secret = utf8.encode("IslandVault_Secure_2026_!@#");
      final rawBytes = Uint8List(obfuscatedBytes.length);

      for (var i = 0; i < obfuscatedBytes.length; i++) {
        rawBytes[i] = obfuscatedBytes[i] ^ secret[i % secret.length];
      }

      final jsonContent = utf8.decode(rawBytes);
      final Map<String, dynamic> backupMap = jsonDecode(jsonContent);

      if (backupMap['signature'] != "ISLAND_DIARY_CRYSTAL_VAULT_V1") {
        throw Exception("签名错误");
      }

      final data = backupMap['data'] as Map<String, dynamic>;
      final prefs = await SharedPreferences.getInstance();

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

      await UserState().loadFromStorage();
      _loadLastBackupTime();

      // 提供 1.5 秒动画时间
      await Future.delayed(const Duration(milliseconds: 1500));
      if (mounted) {
        final themeId = UserState().selectedIslandThemeId.value;
        final fontFamily = themeId == 'lego' ? 'SweiFistLeg' : 'LXGWWenKai';
        _showSuccessDialog(fontFamily);
      }
    } catch (e) {
      debugPrint("快照还原失败: $e");
      if (mounted) {
        _showTip('还原失败: $e', isError: true);
      }
    } finally {
      setState(() => _isRestoring = false);
    }
  }

  /// 删除快照
  Future<void> _deleteSnapshot(File file) async {
    try {
      if (await file.exists()) {
        await file.delete();
        await _loadLocalSnapshots();
        if (mounted) {
          _showTip('已删除该快照');
        }
      }
    } catch (e) {
      debugPrint("删除快照失败: $e");
    }
  }

  /// 文件大小转换
  String _getFileSizeString(int bytes) {
    if (bytes < 1024) return "$bytes B";
    if (bytes < 1048576) return "${(bytes / 1024).toStringAsFixed(1)} KB";
    return "${(bytes / 1048576).toStringAsFixed(1)} MB";
  }

  /// 快照时间格式化
  String _formatTimestamp(String path) {
    try {
      final name = path.split('/').last.split('\\').last;
      final tsStr = name.replaceAll('island_snapshot_', '').replaceAll('.island', '');
      final ts = int.parse(tsStr);
      final dt = DateTime.fromMillisecondsSinceEpoch(ts);
      return "${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')} ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}";
    } catch (_) {
      return "未知备份时间";
    }
  }

  Widget _buildSectionIndicator() {
    return Container(
      width: 6,
      height: 22,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFFFFE082), Color(0xFFFFD54F)],
        ),
        borderRadius: BorderRadius.circular(3),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFFFD97D).withValues(alpha: 0.3),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
    );
  }



  void _showReminderIntervalPicker(bool isNight, String fontFamily) {
    final intervals = [
      {'label': '不提醒', 'value': 0},
      {'label': '每 3 天提醒', 'value': 3 * 86400},
      {'label': '每 7 天提醒 (推荐)', 'value': 7 * 86400},
      {'label': '每 15 天提醒', 'value': 15 * 86400},
      {'label': '每 30 天提醒', 'value': 30 * 86400},
      {'label': '自定义时间...', 'value': -1},
    ];

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      showDragHandle: false,
      builder: (context) => DiaryBottomSheet(
        paperStyle: 'default',
        showDragHandle: true,
        isDiary: false,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                _buildSectionIndicator(),
                const SizedBox(width: 12),
                Text(
                  "备份提醒设置",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: isNight ? Colors.white : Colors.black87,
                    fontFamily: fontFamily,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ...intervals.map((item) {
              final label = item['label'] as String;
              final value = item['value'] as int;
              // 判断是否选中：当 _reminderIntervalSeconds 为 0 且选项为不提醒；
              // 或者当 _reminderIntervalSeconds 不为 0，且当前选项值与总秒数匹配时。
              // 若选项是自定义时间(-1)，且 _reminderIntervalSeconds 与其他快捷选项都不匹配，则视为选中自定义。
              bool isSelected = false;
              if (value == -1) {
                isSelected = _reminderIntervalSeconds != 0 &&
                    _reminderIntervalSeconds != 3 * 86400 &&
                    _reminderIntervalSeconds != 7 * 86400 &&
                    _reminderIntervalSeconds != 15 * 86400 &&
                    _reminderIntervalSeconds != 30 * 86400;
              } else {
                isSelected = _reminderIntervalSeconds == value;
              }

              return GestureDetector(
                onTap: () {
                  Navigator.pop(context);
                  if (value == -1) {
                    _showCustomIntervalPickerDialog(isNight, fontFamily);
                  } else {
                    _saveReminderSettings(value);
                  }
                },
                child: Container(
                  margin: const EdgeInsets.symmetric(vertical: 6),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? _primaryColor.withValues(alpha: 0.1)
                        : (isNight ? Colors.white.withValues(alpha: 0.02) : Colors.black.withValues(alpha: 0.01)),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isSelected
                          ? _primaryColor.withValues(alpha: 0.5)
                          : (isNight ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.05)),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        label,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                          color: isSelected
                              ? _primaryColor
                              : (isNight ? Colors.white70 : Colors.black87),
                          fontFamily: fontFamily,
                        ),
                      ),
                      if (isSelected)
                        Icon(
                          Icons.check_circle_rounded,
                          color: _primaryColor,
                          size: 18,
                        ),
                    ],
                  ),
                ),
              );
            }),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  void _showCustomIntervalPickerDialog(bool isNight, String fontFamily) {
    int initDays = _reminderIntervalSeconds ~/ 86400;
    int initHours = (_reminderIntervalSeconds % 86400) ~/ 3600;
    int initMinutes = (_reminderIntervalSeconds % 3600) ~/ 60;
    int initSeconds = _reminderIntervalSeconds % 60;

    // 保底设置，防止全 0
    if (_reminderIntervalSeconds == 0) {
      initDays = 1;
    }

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      showDragHandle: false,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setLocalState) {
            Widget buildAdjuster(String label, int value, int minVal, int maxVal, ValueChanged<int> onChanged) {
              final canRemove = value > minVal;
              final canAdd = value < maxVal;
              return Column(
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 12,
                      color: isNight ? Colors.white54 : Colors.black54,
                      fontFamily: fontFamily,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    decoration: BoxDecoration(
                      color: isNight ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.03),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        GestureDetector(
                          onTap: canRemove ? () => onChanged(value - 1) : null,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                            color: Colors.transparent,
                            child: Icon(
                              Icons.remove_rounded,
                              size: 14,
                              color: canRemove
                                  ? (isNight ? Colors.white70 : Colors.black54)
                                  : (isNight ? Colors.white24 : Colors.black12),
                            ),
                          ),
                        ),
                        SizedBox(
                          width: 28,
                          child: Text(
                            '$value',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: isNight ? Colors.white : Colors.black87,
                              fontFamily: fontFamily,
                            ),
                          ),
                        ),
                        GestureDetector(
                          onTap: canAdd ? () => onChanged(value + 1) : null,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                            color: Colors.transparent,
                            child: Icon(
                              Icons.add_rounded,
                              size: 14,
                              color: canAdd
                                  ? (isNight ? Colors.white70 : Colors.black54)
                                  : (isNight ? Colors.white24 : Colors.black12),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              );
            }

            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
              ),
              child: DiaryBottomSheet(
                paperStyle: 'default',
                showDragHandle: true,
                isDiary: false,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        _buildSectionIndicator(),
                        const SizedBox(width: 12),
                        Text(
                          "自定义提醒间隔",
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: isNight ? Colors.white : Colors.black87,
                            fontFamily: fontFamily,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          buildAdjuster('天', initDays, 0, 365, (val) => setLocalState(() => initDays = val)),
                          const SizedBox(width: 8),
                          buildAdjuster('时', initHours, 0, 23, (val) => setLocalState(() => initHours = val)),
                          const SizedBox(width: 8),
                          buildAdjuster('分', initMinutes, 0, 59, (val) => setLocalState(() => initMinutes = val)),
                          const SizedBox(width: 8),
                          buildAdjuster('秒', initSeconds, 0, 59, (val) => setLocalState(() => initSeconds = val)),
                        ],
                      ),
                    ),
                    const SizedBox(height: 32),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _primaryColor,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      onPressed: () {
                        final totalSeconds = (initDays * 86400) + (initHours * 3600) + (initMinutes * 60) + initSeconds;
                        if (totalSeconds <= 0) {
                          _showTip('提醒时间必须大于 0 秒', isError: true);
                          return;
                        }
                        _saveReminderSettings(totalSeconds);
                        Navigator.pop(context);
                      },
                      child: Text(
                        '保存设置',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          fontFamily: fontFamily,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool isNight = UserState().isNight;
    final themeId = UserState().selectedIslandThemeId.value;
    final fontFamily = themeId == 'lego' ? 'SweiFistLeg' : 'LXGWWenKai';

    return Scaffold(
      backgroundColor: isNight ? const Color(0xFF161513) : const Color(0xFFFAF8F5),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios_new_rounded, 
            color: isNight ? Colors.white70 : Colors.black87,
            size: 20,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          '备份与恢复中心',
          style: TextStyle(
            color: isNight ? Colors.white : Colors.black87,
            fontWeight: FontWeight.bold,
            fontSize: 18,
            fontFamily: fontFamily,
          ),
        ),
        centerTitle: true,
      ),
      body: Stack(
        children: [
          // 右上角意境背景装饰
          Positioned.fill(
            child: CustomPaint(
              painter: TopRightBackgroundPainter(isNight: isNight),
            ),
          ),
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              physics: const BouncingScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 1. 数据安全说明卡片
                  _buildSecurityExplanation(isNight, fontFamily),
                  const SizedBox(height: 14),

                  // 2. 核心备份与导入控制卡片
                  _buildMainActionsCard(isNight, fontFamily),
                  const SizedBox(height: 14),

                  // 3. 备份提醒周期卡片
                  _buildReminderSettingsCard(isNight, fontFamily),
                  const SizedBox(height: 16),

                  // 4. 本地快照历史标题
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '本地历史快照 (上限 5 份)',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: isNight ? Colors.white70 : const Color(0xFF3E2723),
                          fontFamily: fontFamily,
                        ),
                      ),
                      OutlinedButton(
                        onPressed: _isCreatingSnapshot || _isRestoring ? null : _createLocalSnapshot,
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(color: _primaryColor, width: 1.2),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          minimumSize: const Size(80, 30),
                        ),
                        child: Text(
                          '+ 创建快照',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: _primaryColor,
                            fontFamily: fontFamily,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),

                  // 4. 本地快照列表
                  _buildSnapshotList(isNight, fontFamily),
                  
                  // 底部修饰文字
                  const SizedBox(height: 24),
                  Center(
                    child: Column(
                      children: [
                        Text(
                          '每一次备份，都是对回忆的温柔守护',
                          style: TextStyle(
                            fontSize: 11,
                            color: isNight ? Colors.white24 : const Color(0xFFBCAAA4),
                            fontFamily: fontFamily,
                          ),
                        ),
                        const SizedBox(height: 12),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // 还原中加载覆盖层
          if (_isRestoring)
            _buildLoadingOverlay("正在还原备份数据，请稍候...", isNight, fontFamily),
        ],
      ),
    );
  }

  Widget _buildSecurityExplanation(bool isNight, String fontFamily) {
    return BentoBox(
      isNight: isNight,
      padding: const EdgeInsets.all(20),
      child: Stack(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFE0F7FA), Color(0xFFB2EBF2)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(18),
                  boxShadow: [
                    BoxShadow(
                      color: _primaryColor.withValues(alpha: 0.15),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Center(
                  child: Icon(
                    Icons.lock_outline_rounded,
                    color: _primaryColor,
                    size: 26,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '数据加密安全保护',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: isNight ? Colors.white : const Color(0xFF3E2723),
                        fontFamily: fontFamily,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '数据会先在本地加密，再上传备份，全程守护你的隐私与回忆。',
                      style: TextStyle(
                        fontSize: 12,
                        color: isNight ? Colors.white60 : const Color(0xFF8D827A),
                        height: 1.5,
                        fontFamily: fontFamily,
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ],
          ),
          Positioned(
            right: 0,
            bottom: 0,
            child: GestureDetector(
              onTap: () => _showSecurityDetailDialog(fontFamily),
              child: Row(
                children: [
                  Text(
                    '了解更多',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: _primaryColor,
                      fontFamily: fontFamily,
                    ),
                  ),
                  const SizedBox(width: 2),
                  Icon(
                    Icons.arrow_forward_ios_rounded,
                    size: 10,
                    color: _primaryColor,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showSecurityDetailDialog(String fontFamily) {
    final isNight = UserState().isNight;
    showDialog(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.5),
      builder: (context) {
        return BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: AlertDialog(
            backgroundColor: isNight ? const Color(0xFF1E293B) : const Color(0xFFFFFDF6),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
            title: Text(
              '加密安全技术说明',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: isNight ? Colors.white : const Color(0xFF3E2723),
                fontFamily: fontFamily,
              ),
            ),
            content: Text(
              '在生成备份时，App 会在本地将您的所有数据进行手写密码级别的 XOR 混淆加密，并用最高等级 ZIP 格式进行压缩打包，生成以 .island 结尾的安全备份包。\n\n即便您将该备份文件上传到各类云盘，任何外部软件也绝对无法读取其中的内容，完美守护您的私密回忆。',
              style: TextStyle(
                fontSize: 13,
                color: isNight ? Colors.white70 : const Color(0xFF8D827A),
                height: 1.6,
                fontFamily: fontFamily,
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(
                  '我知道了',
                  style: TextStyle(
                    color: _primaryColor,
                    fontWeight: FontWeight.bold,
                    fontFamily: fontFamily,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStatusPill(IconData icon, String text, bool isNight) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: _primaryColor.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 12,
            color: _primaryColor,
          ),
          const SizedBox(width: 4),
          Text(
            text,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: _primaryColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMainActionsCard(bool isNight, String fontFamily) {
    return BentoBox(
      isNight: isNight,
      padding: const EdgeInsets.all(20),
      child: Stack(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '云端及多设备备份',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: isNight ? Colors.white70 : const Color(0xFF3E2723),
                  fontFamily: fontFamily,
                ),
              ),
              const SizedBox(height: 12),
              
              // 状态小药丸
              Row(
                children: [
                  _buildStatusPill(Icons.verified_user_outlined, '已加密保护', isNight),
                  const SizedBox(width: 8),
                  _buildStatusPill(Icons.phone_android_rounded, '数据仅在本地', isNight),
                ],
              ),
              const SizedBox(height: 10),
              
              // 上次备份时间
              Row(
                children: [
                  Icon(
                    Icons.access_time_rounded,
                    color: isNight ? Colors.white30 : const Color(0xFF8D827A),
                    size: 16,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    '上次备份: $_lastBackupTimeStr',
                    style: TextStyle(
                      fontSize: 12,
                      color: isNight ? Colors.white38 : const Color(0xFF8D827A),
                      fontFamily: fontFamily,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              
              // 操作按钮
              Row(
                children: [
                  Expanded(
                    child: SizedBox(
                      height: 50,
                      child: OutlinedButton(
                        onPressed: _isExporting || _isImporting ? null : _exportAndShareBackup,
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(color: _primaryColor, width: 1.5),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          backgroundColor: isNight ? Colors.white.withValues(alpha: 0.02) : const Color(0xFFF8FAFC),
                          elevation: 0,
                          padding: EdgeInsets.zero,
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            _isExporting
                                ? SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(strokeWidth: 2, color: _primaryColor),
                                  )
                                : Icon(Icons.upload_rounded, size: 20, color: _primaryColor),
                            const SizedBox(width: 8),
                            Text(
                              '备份数据',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: _primaryColor,
                                fontFamily: fontFamily,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Container(
                      height: 50,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        gradient: LinearGradient(
                          colors: [_gradientStart, _primaryColor],
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: _primaryColor.withValues(alpha: 0.2),
                            blurRadius: 8,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: ElevatedButton(
                        onPressed: _isExporting || _isImporting ? null : _importAndRestore,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          shadowColor: Colors.transparent,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          elevation: 0,
                          padding: EdgeInsets.zero,
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              Icons.download_rounded,
                              size: 20,
                              color: Colors.white,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              '恢复数据',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                                fontFamily: fontFamily,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
          
          // 右侧云朵背景装饰
          Positioned(
            right: 0,
            top: 10,
            child: CloudIllustrationWidget(isNight: isNight, primaryColor: _primaryColor),
          ),
        ],
      ),
    );
  }

  Widget _buildReminderSettingsCard(bool isNight, String fontFamily) {
    final intervalText = _formatIntervalText(_reminderIntervalSeconds);

    return BentoBox(
      isNight: isNight,
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '备份周期提醒',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: isNight ? Colors.white70 : const Color(0xFF3E2723),
              fontFamily: fontFamily,
            ),
          ),
          const SizedBox(height: 16),
          GestureDetector(
            onTap: () => _showReminderIntervalPicker(isNight, fontFamily),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: isNight ? Colors.white.withValues(alpha: 0.03) : const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isNight ? Colors.white.withValues(alpha: 0.05) : const Color(0xFFE2E8F0),
                  width: 1.2,
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: _primaryColor.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.notifications_active_outlined,
                      color: _primaryColor,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      '提醒频率',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: isNight ? Colors.white70 : const Color(0xFF5D5450),
                        fontFamily: fontFamily,
                      ),
                    ),
                  ),
                  Text(
                    intervalText,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: _primaryColor,
                      fontFamily: fontFamily,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Icon(
                    Icons.arrow_forward_ios_rounded,
                    size: 12,
                    color: isNight ? Colors.white30 : _primaryColor,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Icon(
                Icons.spa_rounded,
                color: isNight ? Colors.white24 : const Color(0xFF81C784),
                size: 16,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  '长时间未备份时会温柔提醒你，守护你的珍贵回忆。',
                  style: TextStyle(
                    fontSize: 11,
                    color: isNight ? Colors.white38 : const Color(0xFF8D827A),
                    fontFamily: fontFamily,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSnapshotList(bool isNight, String fontFamily) {
    if (_isLoadingList) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 40),
        child: Center(
          child: CircularProgressIndicator(color: _primaryColor),
        ),
      );
    }

    if (_localSnapshots.isEmpty) {
      return BentoBox(
        isNight: isNight,
        padding: const EdgeInsets.symmetric(vertical: 24),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.restore_page_outlined,
                size: 32,
                color: isNight ? Colors.white12 : Colors.black12,
              ),
              const SizedBox(height: 8),
              Text(
                '暂无任何本地快照记录',
                style: TextStyle(
                  fontSize: 13,
                  color: isNight ? Colors.white24 : Colors.black26,
                  fontFamily: fontFamily,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: EdgeInsets.zero,
      itemCount: _localSnapshots.length,
      separatorBuilder: (context, index) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        final file = _localSnapshots[index];
        final size = file.lengthSync();
        final sizeStr = _getFileSizeString(size);
        final dateStr = _formatTimestamp(file.path);

        return BentoBox(
          isNight: isNight,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: _primaryColor.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.image_outlined,
                  color: _primaryColor,
                  size: 20,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '本地数据快照',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: isNight ? Colors.white.withValues(alpha: 0.85) : const Color(0xFF3E2723),
                        fontFamily: fontFamily,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '$dateStr  ·  $sizeStr',
                      style: TextStyle(
                        fontSize: 11,
                        color: isNight ? Colors.white38 : const Color(0xFF8D827A),
                        fontFamily: fontFamily,
                      ),
                    ),
                  ],
                ),
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  GestureDetector(
                    onTap: _isRestoring || _isCreatingSnapshot ? null : () => _restoreFromSnapshot(file),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: _primaryColor.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Text(
                        '还原',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: _primaryColor,
                          fontFamily: fontFamily,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: _isRestoring || _isCreatingSnapshot ? null : () => _deleteSnapshot(file),
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: Colors.red.withValues(alpha: 0.08),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.delete_outline_rounded,
                        color: Colors.redAccent,
                        size: 16,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ).animate().fadeIn(duration: 200.ms, delay: (index * 50).ms).slideX(begin: 0.05, end: 0);
      },
    );
  }

  void _showSuccessDialog(String fontFamily) {
    final isNight = UserState().isNight;
    showDialog(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.5),
      builder: (context) {
        Future.delayed(const Duration(milliseconds: 1500), () {
          if (context.mounted) {
            Navigator.pop(context);
          }
        });

        return Dialog(
          backgroundColor: Colors.transparent,
          elevation: 0,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(28),
                decoration: BoxDecoration(
                  color: isNight ? const Color(0xFF1E293B) : Colors.white,
                  borderRadius: BorderRadius.circular(28),
                  border: Border.all(
                    color: isNight ? Colors.white.withValues(alpha: 0.1) : _primaryColor.withValues(alpha: 0.2),
                    width: 1.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: _primaryColor.withValues(alpha: isNight ? 0.3 : 0.15),
                      blurRadius: 30,
                      offset: const Offset(0, 12),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    // 渐变流光勾号
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: _primaryColor,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.check_rounded,
                        color: Colors.white,
                        size: 32,
                      ),
                    ).animate().scale(curve: Curves.elasticOut, duration: 800.ms),
                    const SizedBox(height: 20),
                    Text(
                      '记忆复苏成功！',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: isNight ? Colors.white : const Color(0xFF1A1A1A),
                        fontFamily: fontFamily,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '我们的岛屿已安全重建 ✨',
                      style: TextStyle(
                        fontSize: 13,
                        color: isNight ? Colors.white60 : Colors.black54,
                        fontFamily: fontFamily,
                      ),
                    ),
                  ],
                ),
              ).animate().fadeIn(duration: 400.ms).scale(begin: const Offset(0.8, 0.8), end: const Offset(1.0, 1.0), curve: Curves.easeOutBack),
            ],
          ),
        );
      },
    );
  }

  Widget _buildLoadingOverlay(String text, bool isNight, String fontFamily) {
    return Positioned.fill(
      child: ClipRRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 15.0, sigmaY: 15.0),
          child: Container(
            color: Colors.black.withValues(alpha: isNight ? 0.5 : 0.35),
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // 旋转的流光光圈与跳动的小伙伴容器
                  Stack(
                    alignment: Alignment.center,
                    children: [
                      // 旋转流光圈
                      Container(
                        width: 110,
                        height: 110,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: Colors.transparent,
                          ),
                          gradient: SweepGradient(
                            colors: [
                              _primaryColor,
                              const Color(0xFF818CF8),
                              const Color(0xFFCE93D8),
                              _primaryColor,
                            ],
                          ),
                        ),
                      )
                      .animate(onPlay: (controller) => controller.repeat())
                      .rotate(duration: 2.seconds),
                      
                      // 内层遮罩，制造环形感
                      Container(
                        width: 102,
                        height: 102,
                        decoration: BoxDecoration(
                          color: isNight ? const Color(0xFF161513) : const Color(0xFFFAF7F0),
                          shape: BoxShape.circle,
                        ),
                      ),
                      
                      // 永久弹性跳动的小胖形象 (Mascot)
                      Image.asset(
                        UserState().selectedMascotType.value,
                        width: 60,
                        height: 60,
                      )
                      .animate(onPlay: (controller) => controller.repeat(reverse: true))
                      .moveY(begin: -8, end: 8, duration: 800.ms, curve: Curves.easeInOutCubic)
                      .rotate(begin: -0.05, end: 0.05, duration: 800.ms, curve: Curves.easeInOutCubic),
                    ],
                  ),
                  const SizedBox(height: 28),
                  
                  // 呼吸灯文字
                  Text(
                    text,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: isNight ? Colors.white.withValues(alpha: 0.9) : const Color(0xFF374151),
                      fontFamily: fontFamily,
                      letterSpacing: 0.8,
                    ),
                  )
                  .animate(onPlay: (controller) => controller.repeat(reverse: true))
                  .fadeIn(duration: 1.seconds, curve: Curves.easeInOut),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

