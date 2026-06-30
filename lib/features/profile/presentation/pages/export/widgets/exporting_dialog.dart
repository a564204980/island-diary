import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';

// 模拟导出过程的精美进度条 Dialog
class ExportingDialog extends StatefulWidget {
  final String fileName;
  final String dpi;
  final Future<String?> Function() onExport;

  const ExportingDialog({
    super.key,
    required this.fileName,
    required this.dpi,
    required this.onExport,
  });

  @override
  State<ExportingDialog> createState() => _ExportingDialogState();
}

class _ExportingDialogState extends State<ExportingDialog> {
  double _progress = 0.0;
  String? _exportedFilePath;

  @override
  void initState() {
    super.initState();
    _startProgress();
  }

  void _startProgress() {
    widget.onExport().then((path) {
      if (mounted) {
        setState(() {
          _exportedFilePath = path;
          _progress = 1.0;
        });
        Navigator.pop(context); // 关闭进度对话框
        _showSuccessDialog(); // 显示导出成功
      }
    });

    Future.doWhile(() async {
      await Future.delayed(const Duration(milliseconds: 100));
      if (!mounted || _progress >= 1.0) return false;
      setState(() {
        if (_progress < 0.9) {
          _progress += 0.05;
        }
      });
      return true;
    });
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.check_circle, color: Colors.teal),
            SizedBox(width: 10),
            Text('导出成功'),
          ],
        ),
        content: Text('已成功为您生成高质量 PDF 文件：\n"${widget.fileName}.pdf" (${widget.dpi} DPI)。'),
        actions: [
          if (_exportedFilePath != null)
            TextButton(
              onPressed: () {
                SharePlus.instance.share(
                  ShareParams(
                    files: [XFile(_exportedFilePath!)],
                    text: '我的日记 PDF',
                  ),
                );
              },
              child: const Text('分享到微信/社交软件', style: TextStyle(color: Colors.teal, fontWeight: FontWeight.bold)),
            ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('确定', style: TextStyle(color: Colors.grey)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(
              color: Colors.teal,
              value: _progress,
            ),
            const SizedBox(height: 24),
            Text(
              '正在导出为 PDF (${(_progress * 100).toInt()}%)...',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Text(
              '渲染文件: ${widget.fileName}.pdf',
              style: const TextStyle(color: Colors.grey, fontSize: 12),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
