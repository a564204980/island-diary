part of '../../diary_book_export_page.dart';

extension _ExportPanelLayersExtension on _DiaryBookExportPageState {
  // 5. 图层管理面板
  Widget _buildLayersPanel() {
    if (_elements.isEmpty) {
      return const Center(child: Text('当前画布没有任何元素'));
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('图层列表（按住右侧图标上下拖拽调整遮挡层级）', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: Colors.black54)),
        const SizedBox(height: 6),
        Expanded(
          child: ReorderableListView(
            onReorder: (oldIndex, newIndex) {
              _saveToHistory();
              updateState(() {
                if (newIndex > oldIndex) {
                  newIndex -= 1;
                }
                final item = _elements.removeAt(oldIndex);
                _elements.insert(newIndex, item);
              });
            },
            children: List.generate(_elements.length, (index) {
              final element = _elements[index];
              return ListTile(
                key: Key(element.id),
                contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                leading: Icon(
                  element.type == 'text'
                      ? Icons.text_format
                      : element.type == 'image'
                          ? Icons.image
                          : element.type == 'chart'
                              ? Icons.bar_chart
                              : Icons.layers,
                  color: const Color(0xFF5A3E28),
                  size: 20,
                ),
                title: Text(
                  element.type == 'text'
                      ? element.content
                      : element.type == 'chart'
                          ? '图层: 图表 (${element.content})'
                          : '图层: ${element.type}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 13),
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: Icon(
                        element.isVisible ? Icons.visibility : Icons.visibility_off,
                        size: 20,
                      ),
                      onPressed: () {
                        updateState(() {
                          element.isVisible = !element.isVisible;
                        });
                      },
                    ),
                    IconButton(
                      icon: Icon(
                        element.isLocked ? Icons.lock : Icons.lock_open,
                        size: 20,
                      ),
                      onPressed: () {
                        updateState(() {
                          element.isLocked = !element.isLocked;
                        });
                      },
                    ),
                    const Icon(Icons.drag_handle, color: Colors.grey, size: 22),
                  ],
                ),
              );
            }),
          ),
        ),
      ],
    );
  }
}
