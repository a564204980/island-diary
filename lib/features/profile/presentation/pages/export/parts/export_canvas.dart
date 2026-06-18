part of '../../diary_book_export_page.dart';

final Map<String, ui.Shader> _exportShaderCache = {};

extension _ExportCanvasExtension on _DiaryBookExportPageState {

  // --- 画布组件构建 ---
  Widget _buildCanvas() {
    final int count = _pageCount;
    return Container(
      width: _canvasWidth,
      height: _totalCanvasHeight,
      decoration: const BoxDecoration(
        color: Colors.transparent,
      ),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // 1. 渲染每一页的背景卡片、背景图、页边距辅助线及页脚信息
          for (int i = 0; i < count; i++) ...[
            Positioned(
              left: 0,
              top: i * (_canvasHeight + pageGap),
              width: _canvasWidth,
              height: _canvasHeight,
              child: Container(
                decoration: BoxDecoration(
                  color: _bgSettings.color,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.12),
                      blurRadius: 25,
                      spreadRadius: 2,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: ClipRect(
                  child: Stack(
                    children: [
                      // 渲染背景图片，限制在画布区域内，并应用透明度、位移、缩放、裁剪
                      if (_bgSettings.imagePath != null)
                        Positioned(
                          left: _bgSettings.x,
                          top: _bgSettings.y,
                          width: _canvasWidth * _bgSettings.scale,
                          height: _canvasHeight * _bgSettings.scale,
                          child: Opacity(
                            opacity: _bgSettings.opacity,
                            child: AspectRatio(
                              aspectRatio: _bgSettings.cropRatio == '1:1'
                                  ? 1.0
                                  : _bgSettings.cropRatio == '3:4'
                                      ? 0.75
                                      : _bgSettings.cropRatio == '4:3'
                                          ? 4.0 / 3.0
                                          : _bgSettings.cropRatio == '16:9'
                                              ? 16.0 / 9.0
                                              : _canvasWidth / _canvasHeight,
                              child: _bgSettings.imagePath!.startsWith('http://') || _bgSettings.imagePath!.startsWith('https://')
                                  ? Image.network(_bgSettings.imagePath!, fit: BoxFit.cover)
                                  : Image.file(File(_bgSettings.imagePath!), fit: BoxFit.cover),
                            ),
                          ),
                        ),
                      // 页边距辅助线（仅在选中状态下展示页边距范围提示）
                      Positioned(
                        left: _margin.left,
                        top: _margin.top,
                        right: _margin.right,
                        bottom: _margin.bottom,
                        child: Container(
                          decoration: BoxDecoration(
                            border: Border.all(
                              color: const Color(0xFF5A3E28).withValues(alpha: 0.25),
                              style: BorderStyle.solid,
                              width: 1.5,
                            ),
                          ),
                        ),
                      ),
                      // 页脚页码
                      Positioned(
                        bottom: 8,
                        left: 0,
                        right: 0,
                        child: Center(
                          child: Text(
                            '第 ${i + 1} 页 / 共 $count 页',
                            style: TextStyle(
                              fontSize: 10,
                              color: const Color(0xFF5A3E28).withValues(alpha: 0.4),
                              fontFamily: 'LXGWWenKai',
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],

          // 渲染页面内的所有设计元素（非选中的先画，选中的最后画以保证最高的 Z 层级）
          ..._elements.where((e) => e.isVisible && e.id != _selectedElementId).map((e) => _buildCanvasElement(e)),
          if (_selectedElementId != null)
            ..._elements.where((e) => e.isVisible && e.id == _selectedElementId).map((e) => _buildCanvasElement(e)),

          // 选中的元素悬浮快捷菜单
          _buildSuspendedToolbar(),

          // 实时宽高提示气泡
          _buildDimensionBubble(),
        ],
      ),
    );
  }

  // 构建当前选中元素的悬浮操作栏
  Widget _buildSuspendedToolbar() {
    if (_selectedElementId == null || _activeHandle != null) return const SizedBox.shrink();
    final elementIdx = _elements.indexWhere((e) => e.id == _selectedElementId);
    if (elementIdx == -1) return const SizedBox.shrink();
    final element = _elements[elementIdx];
    if (!element.isVisible) return const SizedBox.shrink();

    final Color darkBlue = const Color(0xFF2B2654);

    return Positioned(
      left: element.x,
      top: getScreenY(element.y) - 84, // 略微往上移以防遮挡选中框
      child: Container(
        height: 64,
        padding: const EdgeInsets.symmetric(horizontal: 26),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(32),
          border: Border.all(color: Colors.black.withValues(alpha: 0.05), width: 0.8),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // 2. 锁图标（未锁定显示开锁图标，已锁定显示闭锁图标）
            GestureDetector(
              onTap: () {
                updateState(() {
                  element.isLocked = !element.isLocked;
                });
              },
              child: Icon(
                element.isLocked ? Icons.lock_rounded : Icons.lock_open_rounded,
                color: element.isLocked ? const Color(0xFFF59E0B) : darkBlue,
                size: 30,
              ),
            ),
            const SizedBox(width: 24),
            
            if (!element.isLocked) ...[
              // 3. 双框加号（复制）
              GestureDetector(
                onTap: () {
                  _saveToHistory();
                  final newElement = element.copy();
                  newElement.x += 20;
                  newElement.y += 20;
                  final newId = 'copy_${DateTime.now().millisecondsSinceEpoch}';
                  updateState(() {
                    _elements.add(
                      ExportElement(
                        id: newId,
                        type: element.type,
                        x: newElement.x,
                        y: newElement.y,
                        width: element.width,
                        height: element.height,
                        content: element.content,
                        fontSize: element.fontSize,
                        color: element.color,
                        fontFamily: element.fontFamily,
                        fontWeight: element.fontWeight,
                        fontStyle: element.fontStyle,
                        textDecoration: element.textDecoration,
                        textAlign: element.textAlign,
                        letterSpacing: element.letterSpacing,
                        lineHeight: element.lineHeight,
                        opacity: element.opacity,
                        borderRadius: element.borderRadius,
                        cropRatio: element.cropRatio,
                        textBackgroundColor: element.textBackgroundColor,
                        textBackgroundBorderRadius: element.textBackgroundBorderRadius,
                        textBackgroundOpacity: element.textBackgroundOpacity,
                        textBackgroundPadding: element.textBackgroundPadding,
                      ),
                    );
                    _selectElement(newId);
                  });
                },
                child: Icon(
                  Icons.library_add_outlined,
                  color: darkBlue,
                  size: 30,
                ),
              ),
              const SizedBox(width: 24),
              // 4. 垃圾桶（删除）
              GestureDetector(
                onTap: () {
                  _saveToHistory();
                  updateState(() {
                    _elements.removeWhere((e) => e.id == element.id);
                    _selectElement(null);
                  });
                },
                child: Icon(
                  Icons.delete_outline_rounded,
                  color: const Color(0xFFEF4444),
                  size: 30,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildDimensionBubble() {
    if (_activeHandle == null || _selectedElementId == null) return const SizedBox.shrink();
    final elementIdx = _elements.indexWhere((e) => e.id == _selectedElementId);
    if (elementIdx == -1) return const SizedBox.shrink();
    final element = _elements[elementIdx];
    
    final bool isRotating = _activeHandle == 'rotate';
    String textContent;
    if (isRotating) {
      int degree = (element.rotation * 180 / pi).round() % 360;
      if (degree > 180) degree -= 360;
      textContent = '$degree°';
    } else {
      textContent = '宽度:${element.width.toInt()} 高度:${element.height.toInt()}';
    }

    return Positioned(
      left: element.x,
      width: element.width,
      top: getScreenY(element.y) + element.height + 24,
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
          decoration: BoxDecoration(
            color: const Color(0xFF1E293B).withValues(alpha: 0.9),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.15),
                blurRadius: 6,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Text(
            textContent,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.bold,
              fontFamily: 'LXGWWenKai',
            ),
          ),
        ),
      ),
    );
  }
}
