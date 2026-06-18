part of '../../diary_book_export_page.dart';

extension _ExportPanelExportExtension on _DiaryBookExportPageState {
  // 6. 导出配置面板
  Widget _buildExportSettingsPanel() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 文件名输入框
        TextField(
          controller: TextEditingController(text: _exportSettings.fileName),
          decoration: InputDecoration(
            labelText: '导出 PDF 文件名',
            labelStyle: const TextStyle(color: Color(0xFF8A7A6E), fontSize: 10, fontFamily: 'LXGWWenKai', fontWeight: FontWeight.bold),
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            filled: true,
            fillColor: const Color(0xFFF7F4F2),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFFECE5DF)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFF5A3E28)),
            ),
          ),
          style: const TextStyle(color: Color(0xFF5A3E28), fontSize: 12, fontFamily: 'LXGWWenKai', fontWeight: FontWeight.w600),
          onSubmitted: (val) {
            updateState(() {
              _exportSettings.fileName = val;
            });
          },
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '输出分辨率',
                    style: TextStyle(fontSize: 10, color: Color(0xFF8A7A6E), fontFamily: 'LXGWWenKai', fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 6),
                  InkWell(
                    onTap: _showDpiSelector,
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF7F4F2),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFECE5DF), width: 1),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            '${_exportSettings.dpi} DPI',
                            style: const TextStyle(fontSize: 12, color: Color(0xFF5A3E28), fontFamily: 'LXGWWenKai', fontWeight: FontWeight.w600),
                          ),
                          const Icon(Icons.expand_more_rounded, size: 16, color: Color(0xFF8A7A6E)),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '颜色模式',
                    style: TextStyle(fontSize: 10, color: Color(0xFF8A7A6E), fontFamily: 'LXGWWenKai', fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 6),
                  InkWell(
                    onTap: _showColorModeSelector,
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF7F4F2),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFECE5DF), width: 1),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            _exportSettings.colorMode,
                            style: const TextStyle(fontSize: 12, color: Color(0xFF5A3E28), fontFamily: 'LXGWWenKai', fontWeight: FontWeight.w600),
                          ),
                          const Icon(Icons.expand_more_rounded, size: 16, color: Color(0xFF8A7A6E)),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  void _showDpiSelector() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      showDragHandle: false,
      builder: (context) {
        return DiaryBottomSheet(
          paperStyle: 'default',
          showDragHandle: true,
          isDiary: false,
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 12,
            bottom: 24 + MediaQuery.of(context).padding.bottom,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                '选择输出分辨率',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF5A3E28), fontFamily: 'LXGWWenKai'),
              ),
              const SizedBox(height: 16),
              ...['72', '150', '300'].map((d) => _buildDpiCardItem(d)),
            ],
          ),
        );
      },
    );
  }

  Widget _buildDpiCardItem(String d) {
    final bool isSelected = _exportSettings.dpi == d;
    final Color activeColor = const Color(0xFF5A3E28);
    final Color inactiveColor = const Color(0xFF8A7A6E);

    String subtitle = '';
    if (d == '72') subtitle = '适合快速预览 · 文件体积小';
    if (d == '150') subtitle = '日常保存与电子手帐 · 清晰度适中';
    if (d == '300') subtitle = '印刷级超清导出 · 适合打印成册';

    return GestureDetector(
      onTap: () {
        Navigator.pop(context);
        updateState(() {
          _exportSettings.dpi = d;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFF4EFEB) : const Color(0xFFF7F4F2),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? activeColor : const Color(0xFFECE5DF),
            width: isSelected ? 1.5 : 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: activeColor.withValues(alpha: 0.05),
                    blurRadius: 6,
                    offset: const Offset(0, 3),
                  )
                ]
              : null,
        ),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: isSelected ? Colors.white : const Color(0xFFECE5DF),
                borderRadius: BorderRadius.circular(10),
              ),
              alignment: Alignment.center,
              child: Icon(
                d == '300' ? Icons.hd_rounded : Icons.grid_on_rounded,
                color: isSelected ? activeColor : inactiveColor,
                size: 18,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '$d DPI',
                    style: TextStyle(
                      fontFamily: 'LXGWWenKai',
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: activeColor,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontFamily: 'LXGWWenKai',
                      fontSize: 10,
                      color: inactiveColor,
                    ),
                  ),
                ],
              ),
            ),
            if (isSelected)
              Icon(Icons.check_circle_rounded, color: activeColor, size: 18)
            else
              Container(
                width: 18,
                height: 18,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: const Color(0xFFECE5DF), width: 1.5),
                ),
              ),
          ],
        ),
      ),
    );
  }

  void _showColorModeSelector() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      showDragHandle: false,
      builder: (context) {
        return DiaryBottomSheet(
          paperStyle: 'default',
          showDragHandle: true,
          isDiary: false,
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 12,
            bottom: 24 + MediaQuery.of(context).padding.bottom,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                '选择导出颜色模式',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF5A3E28), fontFamily: 'LXGWWenKai'),
              ),
              const SizedBox(height: 16),
              ...['RGB', 'CMYK'].map((m) => _buildColorModeCardItem(m)),
            ],
          ),
        );
      },
    );
  }

  Widget _buildColorModeCardItem(String m) {
    final bool isSelected = _exportSettings.colorMode == m;
    final Color activeColor = const Color(0xFF5A3E28);
    final Color inactiveColor = const Color(0xFF8A7A6E);

    String subtitle = '';
    if (m == 'RGB') subtitle = '电子设备屏幕显示 · 适合网络社交分享';
    if (m == 'CMYK') subtitle = '专业印刷色彩模式 · 适合实体书册印刷';

    return GestureDetector(
      onTap: () {
        Navigator.pop(context);
        updateState(() {
          _exportSettings.colorMode = m;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFF4EFEB) : const Color(0xFFF7F4F2),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? activeColor : const Color(0xFFECE5DF),
            width: isSelected ? 1.5 : 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: activeColor.withValues(alpha: 0.05),
                    blurRadius: 6,
                    offset: const Offset(0, 3),
                  )
                ]
              : null,
        ),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: isSelected ? Colors.white : const Color(0xFFECE5DF),
                borderRadius: BorderRadius.circular(10),
              ),
              alignment: Alignment.center,
              child: Icon(
                Icons.palette_outlined,
                color: isSelected ? activeColor : inactiveColor,
                size: 18,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    m,
                    style: TextStyle(
                      fontFamily: 'LXGWWenKai',
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: activeColor,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontFamily: 'LXGWWenKai',
                      fontSize: 10,
                      color: inactiveColor,
                    ),
                  ),
                ],
              ),
            ),
            if (isSelected)
              Icon(Icons.check_circle_rounded, color: activeColor, size: 18)
            else
              Container(
                width: 18,
                height: 18,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: const Color(0xFFECE5DF), width: 1.5),
                ),
              ),
          ],
        ),
      ),
    );
  }

  // --- 实际的画布导出 PDF 流程 ---
  Future<String?> _performCanvasPdfExport() async {
    try {
      // 1. 取消选中任何元素，防止红色边框和操作气泡被导出进 PDF
      _selectElement(null);
      await Future.delayed(const Duration(milliseconds: 100));

      // 2. 截图画布组件 (包含所有页面的一张长图)
      final boundary = _canvasBoundaryKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
      if (boundary == null) return null;
      
      const double exportPixelRatio = 2.0;
      final ui.Image fullImage = await boundary.toImage(pixelRatio: exportPixelRatio);
      
      final int count = _pageCount;
      final pdf = pw.Document();

      // 3. 循环切割每一页并添加到 PDF 页面中
      for (int i = 0; i < count; i++) {
        final double srcY = i * (_canvasHeight + pageGap);
        final double srcH = _canvasHeight;

        final recorder = ui.PictureRecorder();
        final canvas = Canvas(recorder);
        canvas.drawImageRect(
          fullImage,
          Rect.fromLTWH(
            0,
            srcY * exportPixelRatio,
            fullImage.width.toDouble(),
            srcH * exportPixelRatio,
          ),
          Rect.fromLTWH(
            0,
            0,
            fullImage.width.toDouble(),
            srcH * exportPixelRatio,
          ),
          Paint(),
        );
        final picture = recorder.endRecording();
        final slicedImg = await picture.toImage(fullImage.width, (srcH * exportPixelRatio).toInt());
        final byteData = await slicedImg.toByteData(format: ui.ImageByteFormat.png);
        if (byteData == null) continue;
        final pngBytes = byteData.buffer.asUint8List();

        pdf.addPage(
          pw.Page(
            pageFormat: PdfPageFormat(_canvasWidth, _canvasHeight),
            build: (pw.Context context) {
              return pw.FullPage(
                ignoreMargins: true,
                child: pw.Image(pw.MemoryImage(pngBytes)),
              );
            },
          ),
        );
      }

      // 4. 保存为临时文件
      final dir = await getTemporaryDirectory();
      final file = File('${dir.path}/${_exportSettings.fileName}.pdf');
      await file.writeAsBytes(await pdf.save());
      return file.path;
    } catch (e) {
      debugPrint('Export PDF Error: $e');
      return null;
    }
  }

  // --- 导出对话框 ---
  void _showExportDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return ExportingDialog(
          fileName: _exportSettings.fileName,
          dpi: _exportSettings.dpi,
          onExport: _performCanvasPdfExport,
        );
      },
    );
  }
}
