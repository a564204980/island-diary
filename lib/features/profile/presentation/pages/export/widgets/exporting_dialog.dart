import 'package:flutter/material.dart';


// 模拟导出过程的精美进度条 Dialog
class ExportingDialog extends StatefulWidget {
  final String fileName;
  final String dpi;

  const ExportingDialog({required this.fileName, required this.dpi});

  @override
  State<ExportingDialog> createState() => _ExportingDialogState();
}

class _ExportingDialogState extends State<ExportingDialog> {
  double _progress = 0.0;

  @override
  void initState() {
    super.initState();
    _startProgress();
  }

  void _startProgress() {
    Future.doWhile(() async {
      await Future.delayed(const Duration(milliseconds: 100));
      if (!mounted) return false;
      setState(() {
        _progress += 0.05;
      });
      if (_progress >= 1.0) {
        Navigator.pop(context); // 关闭进度对话框
        _showSuccessDialog(); // 显示导出成功
        return false;
      }
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
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('确定', style: TextStyle(color: Colors.teal, fontWeight: FontWeight.bold)),
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

