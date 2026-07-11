part of '../../diary_book_export_page.dart';

extension _ExportHistoryLogic on _DiaryBookExportPageState {
  void _saveToHistory() {
    updateState(() {
      _undoStack.add(_elements.map((e) => e.copy()).toList());
      _redoStack.clear();
    });
  }


  void _undo() {
    if (_undoStack.isNotEmpty) {
      updateState(() {
        _redoStack.add(_elements.map((e) => e.copy()).toList());
        _elements = _undoStack.removeLast();
      });
    }
  }


  void _redo() {
    if (_redoStack.isNotEmpty) {
      updateState(() {
        _undoStack.add(_elements.map((e) => e.copy()).toList());
        _elements = _redoStack.removeLast();
      });
    }
  }

  // 获取当前编辑画布的实际像素宽度和高度，与印刷纸张尺寸规格动态绑定
  double get _canvasWidth => _isLandscape ? _pageSize.height : _pageSize.width;
  double get _canvasHeight => _isLandscape ? _pageSize.width : _pageSize.height;

  double get pageGap => 20.0;

  int get _pageCount {
    double maxY = 0;
    for (var element in _elements) {
      if (element.isVisible) {
        final double bottom = element.y + element.height;
        if (bottom > maxY) {
          maxY = bottom;
        }
      }
    }
    final double contentHeightLimit = _canvasHeight - _margin.bottom;
    if (maxY <= contentHeightLimit) return 1;
    int maxPage = (maxY / _canvasHeight).floor();
    final double pageOffset = maxY % _canvasHeight;
    if (pageOffset > contentHeightLimit) {
      maxPage += 1;
    }
    // 取消了 10 页的强制上限，以支持整本日记的完整渲染和导出
    return (maxPage + 1);
  }


}
