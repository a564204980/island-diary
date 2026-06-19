part of '../../diary_book_export_page.dart';

extension _ExportPanelAddExtension on _DiaryBookExportPageState {
  // 3. 添加元素面板
  Widget _buildAddElementsPanel() {
    return GridView.count(
      crossAxisCount: 4,
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: 1.1,
      children: [
        _buildAddBtn(Icons.text_format, '文本', () {
          _saveToHistory();
          final double targetY = _focusedPageIndex * _canvasHeight + 150.0;
          final id = 'text_${DateTime.now().millisecondsSinceEpoch}';
          final newElem = ExportElement(
            id: id,
            type: 'text',
            x: 100,
            y: targetY,
            width: 200,
            height: 40,
            content: '双击或点击属性编辑文字',
          );
          _adjustTextElementWidth(newElem);
          _elements.add(newElem);
          _selectElement(id);
        }),
        _buildAddBtn(Icons.image_outlined, '图片', () async {
          final List<AssetEntity>? result = await RedBookAssetPicker.pick(
            context,
            maxAssets: 1,
            requestType: RequestType.image,
          );
          if (result == null || result.isEmpty) return;
          final file = await result.first.file;
          if (file == null) return;

          _saveToHistory();
          final double targetY = _focusedPageIndex * _canvasHeight + 150.0;
          final id = 'image_${DateTime.now().millisecondsSinceEpoch}';
          _elements.add(
            ExportElement(
              id: id,
              type: 'image',
              x: 100,
              y: targetY,
              width: 150,
              height: 150,
              content: file.path,
            ),
          );
          _selectElement(id);
        }),
        _buildAddBtn(Icons.crop_square, '形状', () {
          _showShapeTypeSelection();
        }),
        _buildAddBtn(Icons.horizontal_rule, '分割线', () {
          _saveToHistory();
          final double targetY = _focusedPageIndex * _canvasHeight + 200.0;
          final id = 'line_${DateTime.now().millisecondsSinceEpoch}';
          _elements.add(
            ExportElement(
              id: id,
              type: 'line',
              x: 50,
              y: targetY,
              width: 300,
              height: 4,
              content: 'solid',
              color: const Color(0xFF5A3E28),
            ),
          );
          _selectElement(id);
        }),
        _buildAddBtn(Icons.bar_chart, '图表', () {
          _showChartTypeSelection();
        }),
      ],
    );
  }

  // 图表选择弹窗：点击后截图对应预渲染 Widget 并插入画布
  void _showChartTypeSelection() {
    final allDiaries = UserState().savedDiaries.value;
    final charts = [
      (
        icon: Icons.radar,
        title: '心境雷达',
        subtitle: '展示各种心情强度的平均分布',
        key: _chartKeyRadar,
        type: 'radar',
        builder: () => ExportRadarChart(diaries: allDiaries),
      ),
      (
        icon: Icons.show_chart,
        title: '情绪起伏',
        subtitle: '展示时间线上的情绪起伏折线',
        key: _chartKeyTrend,
        type: 'trend',
        builder: () => ExportTrendChart(diaries: allDiaries),
      ),
      (
        icon: Icons.bar_chart,
        title: '周活动规律',
        subtitle: '展示一周内各天的心情分布与记录频次',
        key: _chartKeyWeekly,
        type: 'weekly',
        builder: () => ExportWeeklyChart(diaries: allDiaries),
      ),
      (
        icon: Icons.palette_outlined,
        title: '时光调色盘',
        subtitle: '由每日心情色块拼贴出的抽象艺术长卷',
        key: _chartKeyPalette,
        type: 'palette',
        builder: () => ExportPaletteChart(diaries: allDiaries),
      ),
      (
        icon: Icons.stacked_line_chart,
        title: '情绪分布趋势',
        subtitle: '多条情绪线对比，展示各类心境发展规律',
        key: _chartKeyMoodFlow,
        type: 'mood_flow',
        builder: () => ExportMoodFlowChart(diaries: allDiaries),
      ),
      (
        icon: Icons.grid_on,
        title: '心境图谱 / 时光足迹(热力图)',
        subtitle: '使用色块深浅反映记录密度与心境足迹',
        key: _chartKeyHeatmap,
        type: 'heatmap',
        builder: () => ExportHeatmapChart(diaries: allDiaries),
      ),
    ];

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (sheetContext) {
        return SafeArea(
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 16),
                  child: Text(
                    '选择要插入的图表',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
                ...charts.map((c) => ListTile(
                  leading: Icon(c.icon, color: const Color(0xFF5A3E28)),
                  title: Text(c.title),
                  subtitle: Text(c.subtitle),
                  onTap: () {
                    Navigator.pop(sheetContext);
                    _captureAndInsertChart(c.key, c.type, c.builder());
                  },
                )),
                const SizedBox(height: 8),
              ],
            ),
          ),
        );
      },
    );
  }

  // 动态将图表组件挂载到渲染树，并在下一帧完成截图后立即销毁
  Future<void> _captureAndInsertChart(GlobalKey key, String chartType, Widget chartWidget) async {
    final double targetHeight = (chartType == 'radar')
        ? 360
        : (chartType == 'mood_flow' ? 240 : 220);

    // 1. 将该图表放入 _capturingChartWidget 进行挂载
    updateState(() {
      _capturingChartWidget = SizedBox(
        width: 300,
        height: targetHeight,
        child: RepaintBoundary(
          key: key,
          child: chartWidget,
        ),
      );
    });

    // 2. 在下一帧（Layout & Paint 完毕后）进行截图，随后销毁该组件
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await Future.delayed(const Duration(milliseconds: 150));
      if (!mounted) return;
      final path = await _captureChart(key);

      // 截图完成，从渲染树卸载
      if (mounted) {
        updateState(() {
          _capturingChartWidget = null;
        });
      }

      _saveToHistory();
      final double targetY = _focusedPageIndex * _canvasHeight + 200.0;
      final id = 'chart_${chartType}_${DateTime.now().millisecondsSinceEpoch}';

      if (path != null) {
        // 截图成功：作为本地图片元素插入
        updateState(() {
          _elements.add(
            ExportElement(
              id: id,
              type: 'image',
              x: 50,
              y: targetY,
              width: 300,
              height: targetHeight,
              content: path,
            ),
          );
          _selectElement(id);
        });
      } else {
        // 备用：用 chart 元素渲染
        updateState(() {
          _elements.add(
            ExportElement(
              id: id,
              type: 'chart',
              x: 50,
              y: targetY,
              width: 300,
              height: targetHeight,
              content: chartType,
              color: Colors.white,
            ),
          );
          _selectElement(id);
        });
      }
    });
  }

  Widget _buildAddBtn(IconData icon, String label, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFFF5F7FA),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: const Color(0xFF5A3E28), size: 24),
            const SizedBox(height: 6),
            Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
          ],
        ),
      ),
    );
  }

  void _showShapeTypeSelection() {
    final shapes = [
      (icon: Icons.crop_square_rounded, title: '矩形', type: 'rectangle'),
      (icon: Icons.check_box_outline_blank_rounded, title: '圆角矩形', type: 'rounded_rect'),
      (icon: Icons.circle_outlined, title: '圆形', type: 'circle'),
      (icon: Icons.change_history_rounded, title: '三角形', type: 'triangle'),
      (icon: Icons.star_border_rounded, title: '五角星', type: 'star'),
      (icon: Icons.favorite_border_rounded, title: '心形', type: 'heart'),
    ];

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      showDragHandle: false,
      builder: (sheetContext) {
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
                '选择要插入的形状',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF5A3E28), fontFamily: 'LXGWWenKai'),
              ),
              const SizedBox(height: 16),
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 1.3,
                ),
                itemCount: shapes.length,
                itemBuilder: (context, idx) {
                  final s = shapes[idx];
                  return InkWell(
                    onTap: () {
                      Navigator.pop(sheetContext);
                      _saveToHistory();
                      final double targetY = _focusedPageIndex * _canvasHeight + 150.0;
                      final id = 'shape_${DateTime.now().millisecondsSinceEpoch}';
                      updateState(() {
                        _elements.add(
                          ExportElement(
                            id: id,
                            type: 'shape',
                            x: 100,
                            y: targetY,
                            width: 100,
                            height: 100,
                            content: s.type,
                            color: const Color(0xFF5A3E28).withValues(alpha: 0.5),
                          ),
                        );
                      });
                      _selectElement(id);
                    },
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFFF7F4F2),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFECE5DF), width: 1),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(s.icon, color: const Color(0xFF5A3E28), size: 24),
                          const SizedBox(height: 4),
                          Text(
                            s.title,
                            style: const TextStyle(fontSize: 11, color: Color(0xFF5A3E28), fontFamily: 'LXGWWenKai', fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }
}
