part of '../../diary_book_export_page.dart';

extension _ExportPanelsExtension on _DiaryBookExportPageState {
  void setState(VoidCallback fn) => updateState(fn);

  // --- 底部配置面板及 Tab 切换 ---
  Widget _buildBottomPanel() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF5A3E28).withValues(alpha: 0.06),
            blurRadius: 20,
            offset: const Offset(0, -8),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 分类控制区内容展示
            Container(
              height: 220,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: _buildActiveTabContent(),
            ),
            // 底部分类 Tab 按钮栏
            Container(
              height: 68,
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: const BoxDecoration(
                color: Colors.transparent,
                border: Border(top: BorderSide(color: Color(0xFFF3EDE6), width: 1)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildTabButton(0, Icons.description_outlined, '页面'),
                  _buildTabButton(1, Icons.wallpaper_outlined, '背景'),
                  _buildTabButton(2, Icons.add_circle_outline_rounded, '添加'),
                  _buildTabButton(3, Icons.tune_rounded, '属性'),
                  _buildTabButton(4, Icons.layers_outlined, '图层'),
                  _buildTabButton(5, Icons.ios_share_rounded, '导出'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTabButton(int index, IconData icon, String label) {
    final isSelected = _activeTabIndex == index;
    final activeColor = const Color(0xFF5A3E28);
    final inactiveColor = const Color(0xFF9E9185);

    return GestureDetector(
      onTap: () {
        setState(() {
          _activeTabIndex = index;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeInOut,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFF4EFEB) : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: isSelected ? activeColor : inactiveColor,
              size: 20,
            ),
            const SizedBox(height: 3),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? activeColor : inactiveColor,
                fontSize: 10,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                fontFamily: 'LXGWWenKai',
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActiveTabContent() {
    switch (_activeTabIndex) {
      case 0:
        return _buildPageSettingsPanel();
      case 1:
        return _buildBackgroundPanel();
      case 2:
        return _buildAddElementsPanel();
      case 3:
        return _buildPropertiesPanel();
      case 4:
        return _buildLayersPanel();
      case 5:
        return _buildExportSettingsPanel();
      default:
        return const SizedBox.shrink();
    }
  }

  // 1. 页面设置面板
  Widget _buildPageSettingsPanel() {
    return ListView(
      physics: const BouncingScrollPhysics(),
      children: [
        Row(
          children: [
            Expanded(
              child: _buildPaperSizeCard(),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildOrientationSelector(),
            ),
          ],
        ),
        const SizedBox(height: 16),
        const Text(
          '页边距调节',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 10,
            color: Color(0xFF8A7A6E),
            fontFamily: 'LXGWWenKai',
          ),
        ),
        const SizedBox(height: 6),
        Row(
          children: [
            Expanded(
              child: Row(
                children: [
                  const Text('左: ', style: TextStyle(fontSize: 10, color: Color(0xFF5A3E28), fontFamily: 'LXGWWenKai')),
                  Expanded(
                    child: _buildCozySlider(
                      value: _margin.left,
                      min: 0,
                      max: 60,
                      onChanged: (val) {
                        setState(() => _margin.left = val);
                        _updateElementsMargin();
                      },
                    ),
                  ),
                  SizedBox(
                    width: 18,
                    child: Text(
                      '${_margin.left.toInt()}',
                      style: const TextStyle(fontSize: 10, color: Color(0xFF5A3E28), fontFamily: 'LXGWWenKai'),
                      textAlign: TextAlign.end,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Row(
                children: [
                  const Text('右: ', style: TextStyle(fontSize: 10, color: Color(0xFF5A3E28), fontFamily: 'LXGWWenKai')),
                  Expanded(
                    child: _buildCozySlider(
                      value: _margin.right,
                      min: 0,
                      max: 60,
                      onChanged: (val) {
                        setState(() => _margin.right = val);
                        _updateElementsMargin();
                      },
                    ),
                  ),
                  SizedBox(
                    width: 18,
                    child: Text(
                      '${_margin.right.toInt()}',
                      style: const TextStyle(fontSize: 10, color: Color(0xFF5A3E28), fontFamily: 'LXGWWenKai'),
                      textAlign: TextAlign.end,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        Row(
          children: [
            Expanded(
              child: Row(
                children: [
                  const Text('上: ', style: TextStyle(fontSize: 10, color: Color(0xFF5A3E28), fontFamily: 'LXGWWenKai')),
                  Expanded(
                    child: _buildCozySlider(
                      value: _margin.top,
                      min: 0,
                      max: 80,
                      onChanged: (val) {
                        setState(() => _margin.top = val);
                        _updateElementsMargin();
                      },
                    ),
                  ),
                  SizedBox(
                    width: 18,
                    child: Text(
                      '${_margin.top.toInt()}',
                      style: const TextStyle(fontSize: 10, color: Color(0xFF5A3E28), fontFamily: 'LXGWWenKai'),
                      textAlign: TextAlign.end,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Row(
                children: [
                  const Text('下: ', style: TextStyle(fontSize: 10, color: Color(0xFF5A3E28), fontFamily: 'LXGWWenKai')),
                  Expanded(
                    child: _buildCozySlider(
                      value: _margin.bottom,
                      min: 0,
                      max: 80,
                      onChanged: (val) {
                        setState(() => _margin.bottom = val);
                        _updateElementsMargin();
                      },
                    ),
                  ),
                  SizedBox(
                    width: 18,
                    child: Text(
                      '${_margin.bottom.toInt()}',
                      style: const TextStyle(fontSize: 10, color: Color(0xFF5A3E28), fontFamily: 'LXGWWenKai'),
                      textAlign: TextAlign.end,
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

  Widget _buildPaperSizeCard() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '纸张大小',
          style: TextStyle(fontSize: 10, color: Color(0xFF8A7A6E), fontFamily: 'LXGWWenKai', fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 6),
        InkWell(
          onTap: _showPageSizeSelector,
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
                  _pageSize.name,
                  style: const TextStyle(fontSize: 12, color: Color(0xFF5A3E28), fontFamily: 'LXGWWenKai', fontWeight: FontWeight.w600),
                ),
                const Icon(Icons.expand_more_rounded, size: 16, color: Color(0xFF8A7A6E)),
              ],
            ),
          ),
        ),
      ],
    );
  }

  void _showPageSizeSelector() {
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
            bottom: 16 + MediaQuery.of(context).padding.bottom,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                '选择纸张尺寸',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF5A3E28), fontFamily: 'LXGWWenKai'),
              ),
              const SizedBox(height: 12),
              ...ExportPageSize.presets.map((p) {
                final bool isSelected = _pageSize.name == p.name;
                return ListTile(
                  title: Text(
                    p.name,
                    style: TextStyle(
                      fontFamily: 'LXGWWenKai',
                      fontSize: 13,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      color: isSelected ? const Color(0xFF5A3E28) : const Color(0xFF8A7A6E),
                    ),
                  ),
                  trailing: isSelected
                      ? const Icon(Icons.check_circle_rounded, color: Color(0xFF5A3E28), size: 18)
                      : null,
                  onTap: () {
                    Navigator.pop(context);
                    setState(() {
                      _pageSize = p;
                    });
                    _updateElementsMargin();
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      _recenterCanvas(animate: true);
                    });
                  },
                );
              }),
            ],
          ),
        );
      },
    );
  }

  Widget _buildOrientationSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '排版方向',
          style: TextStyle(fontSize: 10, color: Color(0xFF8A7A6E), fontFamily: 'LXGWWenKai', fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 6),
        Container(
          height: 38,
          decoration: BoxDecoration(
            color: const Color(0xFFF7F4F2),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFECE5DF), width: 1),
          ),
          padding: const EdgeInsets.all(2),
          child: Row(
            children: [
              Expanded(
                child: _buildOrientationItem(false, '纵向 (Portrait)'),
              ),
              Expanded(
                child: _buildOrientationItem(true, '横向 (Landscape)'),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildOrientationItem(bool landscape, String label) {
    final bool isSelected = _isLandscape == landscape;
    return GestureDetector(
      onTap: () {
        if (_isLandscape != landscape) {
          setState(() {
            _isLandscape = landscape;
          });
          _updateElementsMargin();
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _recenterCanvas(animate: true);
          });
        }
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: isSelected ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: const Color(0xFF5A3E28).withValues(alpha: 0.05),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  )
                ]
              : null,
        ),
        child: Text(
          label.split(' ')[0], // 只显示 纵向 或 横向
          style: TextStyle(
            fontSize: 11,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
            color: isSelected ? const Color(0xFF5A3E28) : const Color(0xFF8A7A6E),
            fontFamily: 'LXGWWenKai',
          ),
        ),
      ),
    );
  }

  Widget _buildCozySlider({
    required double value,
    required double min,
    required double max,
    required ValueChanged<double> onChanged,
  }) {
    return SliderTheme(
      data: SliderThemeData(
        activeTrackColor: const Color(0xFF5A3E28),
        inactiveTrackColor: const Color(0xFFEFECE9),
        thumbColor: const Color(0xFF5A3E28),
        trackHeight: 3.0,
        thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6.0),
        overlayColor: const Color(0xFF5A3E28).withValues(alpha: 0.12),
        overlayShape: const RoundSliderOverlayShape(overlayRadius: 16.0),
      ),
      child: Slider(
        value: value,
        min: min,
        max: max,
        onChanged: onChanged,
      ),
    );
  }

  // 2. 背景设置面板
  Widget _buildBackgroundPanel() {
    final colors = [
      const Color(0xFFE8F4F8),
      const Color(0xFFFDF6EC),
      const Color(0xFFF0F9EB),
      Colors.white,
      const Color(0xFFF5F7FA),
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('背景纯色', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.black54)),
        const SizedBox(height: 8),
        _ExportColorPicker(
          colors: colors,
          selectedColor: _bgSettings.imagePath == null ? _bgSettings.color : null,
          size: 36,
          spacing: 12,
          onColorSelected: (c) {
            setState(() {
              _bgSettings.color = c;
              _bgSettings.imagePath = null;
            });
          },
        ),
        const SizedBox(height: 16),
        const Text('背景插图', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.black54)),
        const SizedBox(height: 8),
        Expanded(
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: [
              GestureDetector(
                onTap: () {
                  setState(() {
                    _bgSettings.imagePath = null;
                  });
                },
                child: Container(
                  width: 50,
                  margin: const EdgeInsets.only(right: 10),
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: _bgSettings.imagePath == null ? const Color(0xFF5A3E28) : Colors.transparent, width: 2),
                  ),
                  child: const Center(child: Icon(Icons.block, size: 18, color: Colors.grey)),
                ),
              ),
              GestureDetector(
                onTap: () async {
                  final List<AssetEntity>? result = await RedBookAssetPicker.pick(
                    context,
                    maxAssets: 1,
                    requestType: RequestType.image,
                  );
                  if (result == null || result.isEmpty) return;
                  final file = await result.first.file;
                  if (file == null) return;

                  _saveToHistory();
                  setState(() {
                    _bgSettings.imagePath = file.path;
                  });
                },
                child: Container(
                  width: 50,
                  margin: const EdgeInsets.only(right: 10),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      color: _bgSettings.imagePath != null ? const Color(0xFF5A3E28) : Colors.transparent,
                      width: 2,
                    ),
                    image: _bgSettings.imagePath != null
                        ? DecorationImage(
                            image: FileImage(File(_bgSettings.imagePath!)),
                            fit: BoxFit.cover,
                          )
                        : null,
                  ),
                  child: _bgSettings.imagePath == null
                      ? const Center(
                          child: Icon(
                            Icons.add_photo_alternate_outlined,
                            size: 20,
                            color: Color(0xFF9E9185),
                          ),
                        )
                      : null,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // 3. 添加元素面板
  Widget _buildAddElementsPanel() {
    return GridView.count(
      crossAxisCount: 5,
      crossAxisSpacing: 8,
      mainAxisSpacing: 10,
      childAspectRatio: 0.9,
      children: [
        _buildAddBtn(Icons.text_format, '文本', () {
          _saveToHistory();
          final id = 'text_${DateTime.now().millisecondsSinceEpoch}';
          final newElem = ExportElement(
            id: id,
            type: 'text',
            x: 100,
            y: 150,
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
          final id = 'image_${DateTime.now().millisecondsSinceEpoch}';
          _elements.add(
            ExportElement(
              id: id,
              type: 'image',
              x: 100,
              y: 150,
              width: 150,
              height: 150,
              content: file.path,
            ),
          );
          _selectElement(id);
        }),
        _buildAddBtn(Icons.crop_square, '形状', () {
          _saveToHistory();
          final id = 'shape_${DateTime.now().millisecondsSinceEpoch}';
          _elements.add(
            ExportElement(
              id: id,
              type: 'shape',
              x: 100,
              y: 150,
              width: 100,
              height: 100,
              content: 'rectangle',
              color: const Color(0xFF5A3E28).withValues(alpha: 0.5),
            ),
          );
          _selectElement(id);
        }),
        _buildAddBtn(Icons.horizontal_rule, '分割线', () {
          _saveToHistory();
          final id = 'line_${DateTime.now().millisecondsSinceEpoch}';
          _elements.add(
            ExportElement(
              id: id,
              type: 'line',
              x: 50,
              y: 200,
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
    setState(() {
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
        setState(() {
          _capturingChartWidget = null;
        });
      }

      _saveToHistory();
      final id = 'chart_${chartType}_${DateTime.now().millisecondsSinceEpoch}';

      if (path != null) {
        // 截图成功：作为本地图片元素插入
        setState(() {
          _elements.add(
            ExportElement(
              id: id,
              type: 'image',
              x: 50,
              y: 200,
              width: 300,
              height: targetHeight,
              content: path,
            ),
          );
          _selectElement(id);
        });
      } else {
        // 备用：用 chart 元素渲染
        setState(() {
          _elements.add(
            ExportElement(
              id: id,
              type: 'chart',
              x: 50,
              y: 200,
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

  // 辅助方法：构建排版格式样式图标按钮
  Widget _buildIconButton({
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 30,
        height: 30,
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFF4EFEB) : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: isSelected ? const Color(0xFF5A3E28) : const Color(0xFFECE5DF),
            width: 1,
          ),
        ),
        child: Icon(
          icon,
          size: 16,
          color: isSelected ? const Color(0xFF5A3E28) : const Color(0xFF8A7A6E),
        ),
      ),
    );
  }

  // 辅助方法：构建紧凑参数滑块
  Widget _buildPropertySlider({
    required String label,
    required double value,
    required double min,
    required double max,
    required String displayValue,
    required ValueChanged<double> onChanged,
  }) {
    return Row(
      children: [
        SizedBox(
          width: 42,
          child: Text(
            label,
            style: const TextStyle(fontSize: 10, color: Color(0xFF8A7A6E), fontFamily: 'LXGWWenKai', fontWeight: FontWeight.bold),
          ),
        ),
        Expanded(
          child: SliderTheme(
            data: SliderThemeData(
              activeTrackColor: const Color(0xFF5A3E28),
              inactiveTrackColor: const Color(0xFFEFECE9),
              thumbColor: const Color(0xFF5A3E28),
              trackHeight: 2.0,
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 5.0),
              overlayColor: const Color(0xFF5A3E28).withValues(alpha: 0.1),
              overlayShape: const RoundSliderOverlayShape(overlayRadius: 10.0),
            ),
            child: Slider(
              value: value,
              min: min,
              max: max,
              onChanged: onChanged,
            ),
          ),
        ),
        const SizedBox(width: 4),
        SizedBox(
          width: 30,
          child: Text(
            displayValue,
            style: const TextStyle(fontSize: 10, color: Color(0xFF5A3E28), fontFamily: 'LXGWWenKai'),
            textAlign: TextAlign.end,
          ),
        ),
      ],
    );
  }

  void _showImageCropSelection(ExportElement element) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return DiaryBottomSheet(
          paperStyle: 'default',
          showDragHandle: true,
          isDiary: false,
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 12,
            bottom: 16 + MediaQuery.of(context).padding.bottom,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                '选择裁剪比例',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF5A3E28), fontFamily: 'LXGWWenKai'),
              ),
              const SizedBox(height: 12),
              ...[
                ('自由比例', null),
                ('正方形 (1:1)', '1:1'),
                ('人像 (3:4)', '3:4'),
                ('风景 (4:3)', '4:3'),
                ('超宽屏 (16:9)', '16:9'),
              ].map((item) {
                final String label = item.$1;
                final String? ratio = item.$2;
                final bool isSelected = element.cropRatio == ratio;
                return ListTile(
                  title: Text(
                    label,
                    style: TextStyle(
                      fontFamily: 'LXGWWenKai',
                      fontSize: 13,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      color: isSelected ? const Color(0xFF5A3E28) : const Color(0xFF8A7A6E),
                    ),
                  ),
                  trailing: isSelected
                      ? const Icon(Icons.check_circle_rounded, color: Color(0xFF5A3E28), size: 18)
                      : null,
                  onTap: () {
                    Navigator.pop(context);
                    _saveToHistory();
                    setState(() {
                      element.cropRatio = ratio;
                      if (ratio == '1:1') {
                        element.height = element.width;
                      } else if (ratio == '3:4') {
                        element.height = element.width * 4 / 3;
                      } else if (ratio == '4:3') {
                        element.height = element.width * 3 / 4;
                      } else if (ratio == '16:9') {
                        element.height = element.width * 9 / 16;
                      }
                    });
                  },
                );
              }),
            ],
          ),
        );
      },
    );
  }

  // 4. 属性编辑面板
  Widget _buildPropertiesPanel() {
    if (_selectedElementId == null) {
      return const Center(
        child: Text(
          '在画布中选中一个元素来调节其属性',
          style: TextStyle(fontFamily: 'LXGWWenKai', color: Color(0xFF8A7A6E)),
        ),
      );
    }

    final elementIdx = _elements.indexWhere((e) => e.id == _selectedElementId);
    if (elementIdx == -1) return const SizedBox.shrink();

    final element = _elements[elementIdx];

    return ListView(
      physics: const BouncingScrollPhysics(),
      children: [
        if (element.type == 'text') ...[
          // 文字内容输入
          Container(
            margin: const EdgeInsets.only(bottom: 8),
            height: 38,
            child: TextField(
              controller: _textEditorController,
              style: const TextStyle(fontSize: 12, fontFamily: 'LXGWWenKai'),
              decoration: InputDecoration(
                hintText: '文字内容',
                contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                isDense: true,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: Color(0xFFECE5DF)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: Color(0xFFECE5DF)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: Color(0xFF5A3E28)),
                ),
              ),
              onChanged: (val) {
                _saveToHistory();
                setState(() {
                  element.content = val;
                  _adjustTextElementWidth(element);
                });
              },
            ),
          ),
          
          // 字体下拉 & 字号滑块
          Row(
            children: [
              Expanded(
                flex: 4,
                child: Container(
                  height: 32,
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFFECE5DF)),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: element.fontFamily,
                      isExpanded: true,
                      style: const TextStyle(fontSize: 11, color: Color(0xFF5A3E28), fontFamily: 'LXGWWenKai'),
                      items: ['系统内置', '思源黑体', '思源宋体', 'Roboto', 'LXGWWenKai'].map((f) {
                        return DropdownMenuItem(value: f, child: Text(f));
                      }).toList(),
                      onChanged: (val) {
                        if (val != null) {
                          _saveToHistory();
                          setState(() {
                            element.fontFamily = val;
                            _adjustTextElementWidth(element);
                          });
                        }
                      },
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                flex: 5,
                child: _buildPropertySlider(
                  label: '字号',
                  value: element.fontSize.clamp(10.0, 72.0),
                  min: 10.0,
                  max: 72.0,
                  displayValue: '${element.fontSize.toInt()}',
                  onChanged: (val) {
                    _saveToHistory();
                    setState(() {
                      element.fontSize = val;
                      _adjustTextElementWidth(element);
                    });
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // 样式与格式对齐
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // 对齐方式
              Row(
                children: [
                  _buildIconButton(
                    icon: Icons.format_align_left_rounded,
                    isSelected: element.textAlign == 'left',
                    onTap: () {
                      _saveToHistory();
                      setState(() => element.textAlign = 'left');
                    },
                  ),
                  const SizedBox(width: 4),
                  _buildIconButton(
                    icon: Icons.format_align_center_rounded,
                    isSelected: element.textAlign == 'center',
                    onTap: () {
                      _saveToHistory();
                      setState(() => element.textAlign = 'center');
                    },
                  ),
                  const SizedBox(width: 4),
                  _buildIconButton(
                    icon: Icons.format_align_right_rounded,
                    isSelected: element.textAlign == 'right',
                    onTap: () {
                      _saveToHistory();
                      setState(() => element.textAlign = 'right');
                    },
                  ),
                ],
              ),
              // 文字样式
              Row(
                children: [
                  _buildIconButton(
                    icon: Icons.format_bold_rounded,
                    isSelected: element.fontWeight == 'bold',
                    onTap: () {
                      _saveToHistory();
                      setState(() {
                        element.fontWeight = element.fontWeight == 'bold' ? 'normal' : 'bold';
                        _adjustTextElementWidth(element);
                      });
                    },
                  ),
                  const SizedBox(width: 4),
                  _buildIconButton(
                    icon: Icons.format_italic_rounded,
                    isSelected: element.fontStyle == 'italic',
                    onTap: () {
                      _saveToHistory();
                      setState(() {
                        element.fontStyle = element.fontStyle == 'italic' ? 'normal' : 'italic';
                        _adjustTextElementWidth(element);
                      });
                    },
                  ),
                  const SizedBox(width: 4),
                  _buildIconButton(
                    icon: Icons.format_underlined_rounded,
                    isSelected: element.textDecoration == 'underline',
                    onTap: () {
                      _saveToHistory();
                      setState(() {
                        element.textDecoration = element.textDecoration == 'underline' ? 'none' : 'underline';
                      });
                    },
                  ),
                  const SizedBox(width: 4),
                  _buildIconButton(
                    icon: Icons.format_strikethrough_rounded,
                    isSelected: element.textDecoration == 'line-through',
                    onTap: () {
                      _saveToHistory();
                      setState(() {
                        element.textDecoration = element.textDecoration == 'line-through' ? 'none' : 'line-through';
                      });
                    },
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 8),

          // 间距：字间距 & 行高
          Row(
            children: [
              Expanded(
                child: _buildPropertySlider(
                  label: '字距',
                  value: element.letterSpacing.clamp(0.0, 15.0),
                  min: 0.0,
                  max: 15.0,
                  displayValue: element.letterSpacing.toStringAsFixed(1),
                  onChanged: (val) {
                    _saveToHistory();
                    setState(() {
                      element.letterSpacing = val;
                      _adjustTextElementWidth(element);
                    });
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildPropertySlider(
                  label: '行高',
                  value: element.lineHeight.clamp(0.8, 3.0),
                  min: 0.8,
                  max: 3.0,
                  displayValue: element.lineHeight.toStringAsFixed(1),
                  onChanged: (val) {
                    _saveToHistory();
                    setState(() {
                      element.lineHeight = val;
                    });
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // 透明度
          _buildPropertySlider(
            label: '透明度',
            value: element.opacity.clamp(0.0, 1.0),
            min: 0.0,
            max: 1.0,
            displayValue: '${(element.opacity * 100).toInt()}%',
            onChanged: (val) {
              _saveToHistory();
              setState(() {
                element.opacity = val;
              });
            },
          ),
        ],
        if (element.type == 'image') ...[
          // 圆角 Slider
          _buildPropertySlider(
            label: '圆角',
            value: element.borderRadius.clamp(0.0, 50.0),
            min: 0.0,
            max: 50.0,
            displayValue: '${element.borderRadius.toInt()}px',
            onChanged: (val) {
              _saveToHistory();
              setState(() {
                element.borderRadius = val;
              });
            },
          ),
          const SizedBox(height: 12),
          
          // 透明度 Slider
          _buildPropertySlider(
            label: '透明度',
            value: element.opacity.clamp(0.0, 1.0),
            min: 0.0,
            max: 1.0,
            displayValue: '${(element.opacity * 100).toInt()}%',
            onChanged: (val) {
              _saveToHistory();
              setState(() {
                element.opacity = val;
              });
            },
          ),
          const SizedBox(height: 16),
          
          // 操作按钮组：插入（相册更换） + 比例裁剪
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.photo_library_outlined, size: 14),
                  label: const Text('更换图片', style: TextStyle(fontSize: 11, fontFamily: 'LXGWWenKai')),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFF4EFEB),
                    foregroundColor: const Color(0xFF5A3E28),
                    elevation: 0,
                    side: const BorderSide(color: Color(0xFFECE5DF)),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                  ),
                  onPressed: () async {
                    final List<AssetEntity>? result = await RedBookAssetPicker.pick(
                      context,
                      maxAssets: 1,
                      requestType: RequestType.image,
                    );
                    if (result == null || result.isEmpty) return;
                    final file = await result.first.file;
                    if (file == null) return;

                    _saveToHistory();
                    setState(() {
                      element.content = file.path;
                    });
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.crop_rounded, size: 14),
                  label: Text(
                    element.cropRatio != null ? '裁剪: ${element.cropRatio}' : '比例裁剪',
                    style: const TextStyle(fontSize: 11, fontFamily: 'LXGWWenKai'),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF5A3E28),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                  ),
                  onPressed: () => _showImageCropSelection(element),
                ),
              ),
            ],
          ),
        ],
        const SizedBox(height: 12),
        // 颜色设置（仅在非图片类型下显示）
        if (element.type != 'image')
          Row(
            children: [
              const Text(
                '颜色选择: ',
                style: TextStyle(fontSize: 10, color: Color(0xFF8A7A6E), fontFamily: 'LXGWWenKai', fontWeight: FontWeight.bold),
              ),
              const SizedBox(width: 8),
              _ExportColorPicker(
                colors: const [Colors.black87, Colors.teal, Colors.red, Colors.blue, Colors.orange, Colors.purple, Colors.green],
                selectedColor: element.color,
                size: 24,
                spacing: 8,
                onColorSelected: (c) {
                  _saveToHistory();
                  setState(() {
                    element.color = c;
                  });
                },
              ),
            ],
          ),
      ],
    );
  }

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
              setState(() {
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
                dense: true,
                contentPadding: EdgeInsets.zero,
                leading: Icon(
                  element.type == 'text'
                      ? Icons.text_format
                      : element.type == 'image'
                          ? Icons.image
                          : element.type == 'chart'
                              ? Icons.bar_chart
                              : Icons.layers,
                  color: const Color(0xFF5A3E28),
                  size: 18,
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
                        size: 16,
                      ),
                      onPressed: () {
                        setState(() {
                          element.isVisible = !element.isVisible;
                        });
                      },
                    ),
                    IconButton(
                      icon: Icon(
                        element.isLocked ? Icons.lock : Icons.lock_open,
                        size: 16,
                      ),
                      onPressed: () {
                        setState(() {
                          element.isLocked = !element.isLocked;
                        });
                      },
                    ),
                    const Icon(Icons.drag_handle, color: Colors.grey, size: 20),
                  ],
                ),
              );
            }),
          ),
        ),
      ],
    );
  }

  // 6. 导出配置面板
  Widget _buildExportSettingsPanel() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: TextEditingController(text: _exportSettings.fileName),
          decoration: const InputDecoration(labelText: '文件名', contentPadding: EdgeInsets.zero),
          onSubmitted: (val) {
            setState(() {
              _exportSettings.fileName = val;
            });
          },
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: DropdownButtonFormField<String>(
                initialValue: _exportSettings.dpi,
                decoration: const InputDecoration(labelText: '分辨率', contentPadding: EdgeInsets.zero),
                items: ['72', '150', '300'].map((d) {
                  return DropdownMenuItem(value: d, child: Text('$d DPI'));
                }).toList(),
                onChanged: (val) {
                  if (val != null) {
                    setState(() {
                      _exportSettings.dpi = val;
                    });
                  }
                },
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: DropdownButtonFormField<String>(
                initialValue: _exportSettings.colorMode,
                decoration: const InputDecoration(labelText: '颜色模式', contentPadding: EdgeInsets.zero),
                items: ['RGB', 'CMYK'].map((m) {
                  return DropdownMenuItem(value: m, child: Text(m));
                }).toList(),
                onChanged: (val) {
                  if (val != null) {
                    setState(() {
                      _exportSettings.colorMode = val;
                    });
                  }
                },
              ),
            ),
          ],
        ),
      ],
    );
  }

  // --- 导出对话框模拟 ---
  void _showExportDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return ExportingDialog(
          fileName: _exportSettings.fileName,
          dpi: _exportSettings.dpi,
        );
      },
    );
  }
}

class _ExportColorPicker extends StatelessWidget {
  final List<Color> colors;
  final Color? selectedColor;
  final ValueChanged<Color> onColorSelected;
  final double size;
  final double spacing;

  const _ExportColorPicker({
    required this.colors,
    required this.selectedColor,
    required this.onColorSelected,
    this.size = 28,
    this.spacing = 8,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: colors.map((c) {
        final isSelected = selectedColor == c;
        return GestureDetector(
          onTap: () => onColorSelected(c),
          child: Container(
            margin: EdgeInsets.only(right: spacing),
            width: size,
            height: size,
            decoration: BoxDecoration(
              color: c,
              shape: BoxShape.circle,
              border: Border.all(
                color: isSelected ? const Color(0xFF5A3E28) : Colors.grey[200]!,
                width: isSelected ? 2.5 : 1,
              ),
              boxShadow: isSelected
                  ? [
                      BoxShadow(
                        color: const Color(0xFF5A3E28).withValues(alpha: 0.15),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      )
                    ]
                  : null,
            ),
          ),
        );
      }).toList(),
    );
  }
}
