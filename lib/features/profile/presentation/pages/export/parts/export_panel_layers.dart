part of '../../diary_book_export_page.dart';

extension _ExportPanelLayersExtension on _DiaryBookExportPageState {
  // 5. 图层管理面板
  Widget _buildLayersPanel() {
    final double pageStartY = _focusedPageIndex * (_canvasHeight + pageGap);
    final double pageEndY = pageStartY + _canvasHeight;

    final visibleElements = _elements.where((e) {
      return (e.y + e.height >= pageStartY) && (e.y <= pageEndY);
    }).toList();

    if (visibleElements.isEmpty) {
      return const Center(
        child: Text(
          '当前页面没有任何元素',
          style: TextStyle(fontFamily: 'LXGWWenKai', color: Color(0xFF8A7A6E)),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4.0, bottom: 12.0),
          child: Text(
            '图层列表 (第 ${_focusedPageIndex + 1} 页) - 长按列表项拖拽',
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 13,
              color: Color(0xFF8A7A6E),
              fontFamily: 'LXGWWenKai',
            ),
          ),
        ),
        Expanded(
          child: ReorderableListView(
            padding: const EdgeInsets.only(bottom: 20),
            proxyDecorator: (Widget child, int index, Animation<double> animation) {
              return Material(
                color: Colors.transparent,
                elevation: 4,
                shadowColor: Colors.black12,
                child: child,
              );
            },
            onReorderItem: (oldIndex, newIndex) {
              _saveToHistory();
              updateState(() {
                if (oldIndex == newIndex) return;

                final itemToMove = visibleElements[oldIndex];
                _elements.remove(itemToMove);

                if (newIndex == visibleElements.length - 1) {
                  final referenceItem = visibleElements.lastWhere((e) => e != itemToMove);
                  final insertIndex = _elements.indexOf(referenceItem) + 1;
                  _elements.insert(insertIndex, itemToMove);
                } else {
                  final referenceItem = visibleElements.where((e) => e != itemToMove).toList()[newIndex];
                  final insertIndex = _elements.indexOf(referenceItem);
                  _elements.insert(insertIndex, itemToMove);
                }
              });
            },
            children: List.generate(visibleElements.length, (index) {
              final element = visibleElements[index];
              final bool isSelected = element.id == _selectedElementId;

              return Container(
                key: Key(element.id),
                margin: const EdgeInsets.only(bottom: 10),
                decoration: BoxDecoration(
                  color: isSelected ? const Color(0xFF8B5CF6).withValues(alpha: 0.06) : Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isSelected ? const Color(0xFF8B5CF6).withValues(alpha: 0.3) : const Color(0xFFECE5DF),
                    width: 1,
                  ),
                  boxShadow: isSelected
                      ? []
                      : [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.02),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          )
                        ],
                ),
                child: Material(
                  color: Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: () {
                      updateState(() {
                        _selectedElementId = element.id;
                      });
                    },
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      child: Row(
                        children: [
                          // 元素类型图标
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: isSelected ? const Color(0xFF8B5CF6).withValues(alpha: 0.1) : const Color(0xFFF5F1ED),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(
                              element.type == 'text'
                                  ? Icons.text_format_rounded
                                  : element.type == 'image'
                                      ? Icons.image_rounded
                                      : element.type == 'chart'
                                          ? Icons.bar_chart_rounded
                                          : Icons.layers_rounded,
                              color: isSelected ? const Color(0xFF8B5CF6) : const Color(0xFF8A7A6E),
                              size: 18,
                            ),
                          ),
                          const SizedBox(width: 12),
                          // 元素内容文本
                          Expanded(
                            child: Text(
                              element.type == 'text'
                                  ? element.content
                                  : element.type == 'chart'
                                      ? '图表: ${element.content}'
                                      : '图片素材',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontFamily: 'LXGWWenKai',
                                fontSize: 14,
                                color: isSelected ? const Color(0xFF8B5CF6) : const Color(0xFF5A3E28),
                                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                              ),
                            ),
                          ),
                          // 操作按钮区
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              GestureDetector(
                                onTap: () {
                                  updateState(() {
                                    element.isVisible = !element.isVisible;
                                  });
                                },
                                child: Padding(
                                  padding: const EdgeInsets.all(6.0),
                                  child: Icon(
                                    element.isVisible ? Icons.visibility_rounded : Icons.visibility_off_rounded,
                                    size: 20,
                                    color: element.isVisible ? const Color(0xFF8A7A6E) : Colors.grey.shade400,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 4),
                              GestureDetector(
                                onTap: () {
                                  updateState(() {
                                    element.isLocked = !element.isLocked;
                                  });
                                },
                                child: Padding(
                                  padding: const EdgeInsets.all(6.0),
                                  child: Icon(
                                    element.isLocked ? Icons.lock_rounded : Icons.lock_open_rounded,
                                    size: 20,
                                    color: element.isLocked ? const Color(0xFFE57373) : const Color(0xFF8A7A6E),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 10),
                              // 拖拽提示图标
                              const Icon(Icons.drag_indicator_rounded, color: Color(0xFFD4C9C1), size: 20),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            }),
          ),
        ),
      ],
    );
  }
}
