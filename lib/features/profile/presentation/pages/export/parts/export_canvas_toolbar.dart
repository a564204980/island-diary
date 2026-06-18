part of '../../diary_book_export_page.dart';

extension _ExportCanvasToolbarExtension on _DiaryBookExportPageState {
  // --- 快速工具栏 ---
  Widget _buildQuickToolbar() {
    final Color activeColor = const Color(0xFF5A3E28);
    final Color disabledColor = const Color(0xFFD0C6BE);

    Widget buildToolIcon({
      required IconData icon,
      required VoidCallback? onPressed,
      required String tooltip,
    }) {
      return Tooltip(
        message: tooltip,
        textStyle: const TextStyle(fontSize: 10, color: Colors.white, fontFamily: 'LXGWWenKai'),
        decoration: BoxDecoration(
          color: const Color(0xFF5A3E28).withValues(alpha: 0.9),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Material(
          color: Colors.transparent,
          child: IconButton(
            icon: Icon(icon),
            onPressed: onPressed,
            color: activeColor,
            disabledColor: disabledColor,
            iconSize: 18,
            splashRadius: 18,
            padding: const EdgeInsets.all(6),
            constraints: const BoxConstraints(),
          ),
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.95),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.9),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF5A3E28).withValues(alpha: 0.08),
            blurRadius: 16,
            spreadRadius: 1,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 0),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          buildToolIcon(
            icon: Icons.undo_rounded,
            onPressed: _undoStack.isNotEmpty ? _undo : null,
            tooltip: '撤销',
          ),
          const SizedBox(width: 8),
          buildToolIcon(
            icon: Icons.redo_rounded,
            onPressed: _redoStack.isNotEmpty ? _redo : null,
            tooltip: '重做',
          ),
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 10),
            width: 1,
            height: 16,
            color: const Color(0xFFE5DDD5),
          ),
          buildToolIcon(
            icon: Icons.align_horizontal_center_rounded,
            onPressed: _selectedElementId == null ? null : _alignSelectedElementCenter,
            tooltip: '水平居中',
          ),
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 10),
            width: 1,
            height: 16,
            color: const Color(0xFFE5DDD5),
          ),
          buildToolIcon(
            icon: Icons.zoom_out_rounded,
            onPressed: () => _zoom(1 / 1.15),
            tooltip: '缩小画布',
          ),
          const SizedBox(width: 8),
          buildToolIcon(
            icon: Icons.zoom_in_rounded,
            onPressed: () => _zoom(1.15),
            tooltip: '放大画布',
          ),
        ],
      ),
    );
  }

  void _alignSelectedElementCenter() {
    if (_selectedElementId != null) {
      _saveToHistory();
      final idx = _elements.indexWhere((e) => e.id == _selectedElementId);
      if (idx != -1) {
        updateState(() {
          _elements[idx].x = (_canvasWidth - _elements[idx].width) / 2;
        });
      }
    }
  }
}
