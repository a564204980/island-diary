part of '../../diary_book_export_page.dart';

extension _ExportPanelBackgroundExtension on _DiaryBookExportPageState {
  // 2. 背景设置面板
  Widget _buildBackgroundPanel() {
    final colors = [
      const Color(0xFFE8F4F8),
      const Color(0xFFFDF6EC),
      const Color(0xFFF0F9EB),
      Colors.white,
      const Color(0xFFF5F7FA),
    ];
    return ListView(
      physics: const BouncingScrollPhysics(),
      children: [
        const Text('背景纯色', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.black54)),
        const SizedBox(height: 8),
        Row(
          children: [
            GestureDetector(
              onTap: () {
                _showColorPickerBottomSheet(
                  _bgSettings.color,
                  (color) {
                    _saveToHistory();
                    updateState(() {
                      _bgSettings.color = color;
                      _bgSettings.imagePath = null;
                    });
                  },
                );
              },
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: Colors.transparent,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: (_bgSettings.imagePath == null &&
                            !const [
                              Color(0xFFE8F4F8),
                              Color(0xFFFDF6EC),
                              Color(0xFFF0F9EB),
                              Colors.white,
                              Color(0xFFF5F7FA),
                            ].contains(_bgSettings.color))
                        ? const Color(0xFF5A3E28)
                        : Colors.grey[300]!,
                    width: (_bgSettings.imagePath == null &&
                            !const [
                              Color(0xFFE8F4F8),
                              Color(0xFFFDF6EC),
                              Color(0xFFF0F9EB),
                              Colors.white,
                              Color(0xFFF5F7FA),
                            ].contains(_bgSettings.color))
                        ? 2.5
                        : 1,
                  ),
                ),
                child: const Center(
                  child: Icon(Icons.colorize_rounded, size: 18, color: Color(0xFF5A3E28)),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: SizedBox(
                height: 40,
                child: _ExportColorPicker(
                  colors: colors,
                  selectedColor: _bgSettings.imagePath == null ? _bgSettings.color : null,
                  size: 40,
                  spacing: 12,
                  onColorSelected: (c) {
                    _saveToHistory();
                    updateState(() {
                      _bgSettings.color = c;
                      _bgSettings.imagePath = null;
                    });
                  },
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        const Text('背景插图', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.black54)),
        const SizedBox(height: 8),
        SizedBox(
          height: 50,
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: [
              GestureDetector(
                onTap: () {
                  updateState(() {
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
                  updateState(() {
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
        if (_bgSettings.imagePath != null) ...[
          const SizedBox(height: 16),
          const Divider(height: 1, color: Color(0xFFECE5DF)),
          const SizedBox(height: 12),
          // 透明度 Slider
          _buildBgPropertySlider(
            label: '透明度',
            value: _bgSettings.opacity.clamp(0.0, 1.0),
            min: 0.0,
            max: 1.0,
            displayValue: '${(_bgSettings.opacity * 100).toInt()}%',
            onChanged: (val) {
              _saveToHistory();
              updateState(() {
                _bgSettings.opacity = val;
              });
            },
          ),
          const SizedBox(height: 8),
          // 缩放 Slider
          _buildBgPropertySlider(
            label: '缩放',
            value: _bgSettings.scale.clamp(0.5, 3.0),
            min: 0.5,
            max: 3.0,
            displayValue: '${(_bgSettings.scale * 100).toInt()}%',
            onChanged: (val) {
              _saveToHistory();
              updateState(() {
                _bgSettings.scale = val;
              });
            },
          ),
          const SizedBox(height: 12),
          // 裁剪比例按钮
          ElevatedButton.icon(
            icon: const Icon(Icons.crop_rounded, size: 14),
            label: Text(
              _bgSettings.cropRatio != null ? '裁剪: ${_bgSettings.cropRatio}' : '比例裁剪',
              style: const TextStyle(fontSize: 11, fontFamily: 'LXGWWenKai'),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF5A3E28),
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              padding: const EdgeInsets.symmetric(vertical: 10),
            ),
            onPressed: () => _showBgImageCropSelection(),
          ),
          // 位置微调
          _buildBgPositionNudgeSection(),
        ],
      ],
    );
  }

  Widget _buildBgPropertySlider({
    required String label,
    required double value,
    required double min,
    required double max,
    required String displayValue,
    required ValueChanged<double> onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: const TextStyle(fontSize: 11, color: Color(0xFF8A7A6E), fontFamily: 'LXGWWenKai', fontWeight: FontWeight.bold),
            ),
            Text(
              displayValue,
              style: const TextStyle(fontSize: 10, color: Color(0xFF8A7A6E), fontFamily: 'LXGWWenKai'),
            ),
          ],
        ),
        const SizedBox(height: 2),
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            activeTrackColor: const Color(0xFF5A3E28),
            inactiveTrackColor: const Color(0xFFECE5DF),
            thumbColor: const Color(0xFF5A3E28),
            overlayColor: const Color(0xFF5A3E28).withValues(alpha: 0.12),
            trackHeight: 3,
            thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
            overlayShape: const RoundSliderOverlayShape(overlayRadius: 12),
          ),
          child: Slider(
            value: value,
            min: min,
            max: max,
            onChanged: onChanged,
          ),
        ),
      ],
    );
  }

  void _showBgImageCropSelection() {
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
                '选择背景裁剪比例',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF5A3E28), fontFamily: 'LXGWWenKai'),
              ),
              const SizedBox(height: 12),
              ...[
                ('填充画布 (默认)', null),
                ('正方形 (1:1)', '1:1'),
                ('人像 (3:4)', '3:4'),
                ('风景 (4:3)', '4:3'),
                ('超宽屏 (16:9)', '16:9'),
              ].map((item) {
                final String label = item.$1;
                final String? ratio = item.$2;
                final bool isSelected = _bgSettings.cropRatio == ratio;
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
                    updateState(() {
                      _bgSettings.cropRatio = ratio;
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

  Widget _buildBgPositionNudgeSection() {
    return Container(
      margin: const EdgeInsets.only(top: 12),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFF4EFEB),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFECE5DF)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                '背景图位置微调',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF5A3E28),
                  fontFamily: 'LXGWWenKai',
                ),
              ),
              const SizedBox(height: 2),
              Text(
                'X: ${_bgSettings.x.toInt()}  Y: ${_bgSettings.y.toInt()}',
                style: const TextStyle(
                  fontSize: 10,
                  color: Color(0xFF8A7A6E),
                  fontFamily: 'LXGWWenKai',
                ),
              ),
            ],
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildNudgeArrow(Icons.keyboard_arrow_left_rounded, () {
                updateState(() {
                  _bgSettings.x -= 1;
                });
              }),
              const SizedBox(width: 8),
              _buildNudgeArrow(Icons.keyboard_arrow_up_rounded, () {
                updateState(() {
                  _bgSettings.y -= 1;
                });
              }),
              const SizedBox(width: 8),
              _buildNudgeArrow(Icons.keyboard_arrow_down_rounded, () {
                updateState(() {
                  _bgSettings.y += 1;
                });
              }),
              const SizedBox(width: 8),
              _buildNudgeArrow(Icons.keyboard_arrow_right_rounded, () {
                updateState(() {
                  _bgSettings.x += 1;
                });
              }),
            ],
          ),
        ],
      ),
    );
  }
}
