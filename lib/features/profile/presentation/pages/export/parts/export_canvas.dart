part of '../../diary_book_export_page.dart';

final Map<String, ui.Shader> _exportShaderCache = {};

final Map<int, Widget> _exportCanvasElementWidgetCache = {};

class _ElementSelectionBuilder extends StatefulWidget {
  final ValueNotifier<String?> notifier;
  final String elementId;
  final Widget Function(BuildContext context, bool isSelected) builder;

  const _ElementSelectionBuilder({
    Key? key,
    required this.notifier,
    required this.elementId,
    required this.builder,
  }) : super(key: key);

  @override
  _ElementSelectionBuilderState createState() => _ElementSelectionBuilderState();
}

class _ElementSelectionBuilderState extends State<_ElementSelectionBuilder> {
  late bool _isSelected;

  @override
  void initState() {
    super.initState();
    _isSelected = widget.notifier.value == widget.elementId;
    widget.notifier.addListener(_listener);
  }

  @override
  void didUpdateWidget(covariant _ElementSelectionBuilder oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.notifier != widget.notifier) {
      oldWidget.notifier.removeListener(_listener);
      widget.notifier.addListener(_listener);
    }
    _isSelected = widget.notifier.value == widget.elementId;
  }

  @override
  void dispose() {
    widget.notifier.removeListener(_listener);
    super.dispose();
  }

  void _listener() {
    final newIsSelected = widget.notifier.value == widget.elementId;
    if (_isSelected != newIsSelected) {
      setState(() {
        _isSelected = newIsSelected;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return widget.builder(context, _isSelected);
  }
}

extension _ExportCanvasExtension on _DiaryBookExportPageState {

  Widget _buildCanvasElementWithCache(ExportElement element) {
    // 缓存 key 【不再包含选中状态】，因为选中高亮通过 _ElementSelectionBuilder 独立驱动，
    // 无需因选中变化而使缓存失效并重建整个元素 widget。
    final h1 = Object.hash(
      element.id, element.x, element.y, element.width, element.height, element.rotation,
      element.content, element.fontSize, element.color.value, element.fontFamily,
      element.fontWeight, element.fontStyle, element.textDecoration, element.textAlign,
      element.letterSpacing, element.lineHeight, element.opacity, element.borderRadius,
      element.cropRatio, element.textBackgroundColor?.value
    );
    final h2 = Object.hash(
      element.textBackgroundBorderRadius, element.textBackgroundOpacity, element.textBackgroundPadding, 
      element.isLocked
    );
    final key = Object.hash(h1, h2);

    if (_exportCanvasElementWidgetCache.containsKey(key)) {
      return _exportCanvasElementWidgetCache[key]!;
    }
    
    // 用 _ElementSelectionBuilder 包裹每个元素，它比 ValueListenableBuilder 聪明，
    // 只有当该元素的选中状态【发生翻转】（被选中/取消选中）时，它才会触发重绘。
    // 这将复杂度从 O(N) 降到了 O(1)（每次点击最多只有 2 个元素重绘）！
    const double handlePadding = 12.0;
    final widget = Positioned(
      key: ValueKey(element.id),
      left: element.x - handlePadding,
      top: getScreenY(element.y) - handlePadding,
      child: _ElementSelectionBuilder(
        notifier: _selectionNotifier,
        elementId: element.id,
        builder: (context, isSelected) {
          // 由于 _buildCanvasElement 内部会用到 isSelected 的状态，直接传递
          // 注意：内部如果还有读取 _selectedElementId 的地方，现在可以依赖传入的 isSelected 了
          return _buildCanvasElement(element, isSelected);
        },
      ),
    );
    _exportCanvasElementWidgetCache[key] = widget;
    
    if (_exportCanvasElementWidgetCache.length > 50000) {
       _exportCanvasElementWidgetCache.clear();
    }
    return widget;
  }

  // --- 画布组件构建 ---
  Widget _buildCanvas() {
    final int count = _pageCount;

    // 1. 渲染每一页的背景卡片、背景图、页边距辅助线及页脚信息
    if (_cachedBackgroundWidgets == null) {
      _cachedBackgroundWidgets = [];
      for (int i = 0; i < count; i++) {
        final bg = getBgSettingsForPage(i);
        _cachedBackgroundWidgets!.add(
          Builder(
            builder: (context) {
              return Positioned(
                left: 0,
                top: i * (_canvasHeight + pageGap),
                width: _canvasWidth,
                height: _canvasHeight,
                child: Container(
                  decoration: BoxDecoration(
                    color: bg.color,
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
                        if (bg.imagePath != null)
                          Positioned(
                            left: bg.x,
                            top: bg.y,
                            width: _canvasWidth * bg.scale,
                            height: _canvasHeight * bg.scale,
                            child: Opacity(
                              opacity: bg.opacity,
                              child: AspectRatio(
                                aspectRatio: bg.cropRatio == '1:1'
                                    ? 1.0
                                    : bg.cropRatio == '3:4'
                                        ? 0.75
                                        : bg.cropRatio == '4:3'
                                            ? 4.0 / 3.0
                                            : bg.cropRatio == '16:9'
                                                ? 16.0 / 9.0
                                                : _canvasWidth / _canvasHeight,
                                child: bg.imagePath!.startsWith('http://') || bg.imagePath!.startsWith('https://')
                                    ? Image.network(bg.imagePath!, fit: BoxFit.cover)
                                    : bg.imagePath!.startsWith('assets/')
                                        ? Image.asset(bg.imagePath!, fit: BoxFit.cover)
                                        : Image.file(File(bg.imagePath!), fit: BoxFit.cover),
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
              );
            }
          )
        );
      }
    }

    final allWidgets = <Widget>[];

    for (final e in _elements) {
      if (!e.isVisible) continue;
      allWidgets.add(_buildCanvasElementWithCache(e));
    }

    return Container(
      width: _canvasWidth,
      height: _totalCanvasHeight,
      decoration: const BoxDecoration(
        color: Colors.transparent,
      ),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          ..._cachedBackgroundWidgets!,

          // 所有元素按 Z-order 渲染，每个元素通过 ValueListenableBuilder(_selectionNotifier) 独立响应选中
          ...allWidgets,

          // 选中元素的悬浮快捷菜单 + 尺寸气泡：监听 _selectionNotifier 即时响应，无需画布重建
          ValueListenableBuilder<String?>(
            valueListenable: _selectionNotifier,
            builder: (context, _, __) => Stack(
              children: [
                _buildSuspendedToolbar(),
                _buildDimensionBubble(),
              ],
            ),
          ),
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
            
            if (!element.isLocked) ...[
              const SizedBox(width: 24),
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
