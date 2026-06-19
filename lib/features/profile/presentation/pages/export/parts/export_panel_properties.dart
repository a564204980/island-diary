part of '../../diary_book_export_page.dart';

extension _ExportPanelPropertiesExtension on _DiaryBookExportPageState {
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
                    updateState(() {
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

    if (element.isLocked) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.lock_outline_rounded, size: 36, color: Color(0xFF8A7A6E)),
            const SizedBox(height: 10),
            const Text(
              '当前元素已被锁定',
              style: TextStyle(
                fontFamily: 'LXGWWenKai',
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Color(0xFF5A3E28),
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              '请在画布悬浮栏或图层面板中解锁后再进行编辑',
              style: TextStyle(
                fontFamily: 'LXGWWenKai',
                fontSize: 11,
                color: Color(0xFF8A7A6E),
              ),
            ),
          ],
        ),
      );
    }

    return ListView(
      physics: const BouncingScrollPhysics(),
      children: [
        _buildPositionNudgeSection(element),
        const SizedBox(height: 8),
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
                updateState(() {
                  element.content = val;
                  _adjustTextElementWidth(element);
                });
              },
            ),
          ),
          
          // 字体下拉与字号滑块拆分为上下两行
          Container(
            height: 38,
            padding: const EdgeInsets.symmetric(horizontal: 8),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFFECE5DF)),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: element.fontFamily,
                isExpanded: true,
                style: const TextStyle(fontSize: 12, color: Color(0xFF5A3E28), fontFamily: 'LXGWWenKai'),
                items: ['系统内置', '思源黑体', '思源宋体', 'Roboto', 'LXGWWenKai'].map((f) {
                  return DropdownMenuItem(value: f, child: Text(f));
                }).toList(),
                onChanged: (val) {
                  if (val != null) {
                    _saveToHistory();
                    updateState(() {
                      element.fontFamily = val;
                      _adjustTextElementWidth(element);
                    });
                  }
                },
              ),
            ),
          ),
          const SizedBox(height: 10),
          _buildPropertySlider(
            label: '字号',
            value: element.fontSize.clamp(10.0, 72.0),
            min: 10.0,
            max: 72.0,
            displayValue: '${element.fontSize.toInt()}',
            onChanged: (val) {
              _saveToHistory();
              updateState(() {
                element.fontSize = val;
                _adjustTextElementWidth(element);
              });
            },
          ),
          const SizedBox(height: 12),

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
                      updateState(() => element.textAlign = 'left');
                    },
                  ),
                  const SizedBox(width: 8),
                  _buildIconButton(
                    icon: Icons.format_align_center_rounded,
                    isSelected: element.textAlign == 'center',
                    onTap: () {
                      _saveToHistory();
                      updateState(() => element.textAlign = 'center');
                    },
                  ),
                  const SizedBox(width: 8),
                  _buildIconButton(
                    icon: Icons.format_align_right_rounded,
                    isSelected: element.textAlign == 'right',
                    onTap: () {
                      _saveToHistory();
                      updateState(() => element.textAlign = 'right');
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
                      updateState(() {
                        element.fontWeight = element.fontWeight == 'bold' ? 'normal' : 'bold';
                        _adjustTextElementWidth(element);
                      });
                    },
                  ),
                  const SizedBox(width: 8),
                  _buildIconButton(
                    icon: Icons.format_italic_rounded,
                    isSelected: element.fontStyle == 'italic',
                    onTap: () {
                      _saveToHistory();
                      updateState(() {
                        element.fontStyle = element.fontStyle == 'italic' ? 'normal' : 'italic';
                        _adjustTextElementWidth(element);
                      });
                    },
                  ),
                  const SizedBox(width: 8),
                  _buildIconButton(
                    icon: Icons.format_underlined_rounded,
                    isSelected: element.textDecoration == 'underline',
                    onTap: () {
                      _saveToHistory();
                      updateState(() {
                        element.textDecoration = element.textDecoration == 'underline' ? 'none' : 'underline';
                      });
                    },
                  ),
                  const SizedBox(width: 8),
                  _buildIconButton(
                    icon: Icons.format_strikethrough_rounded,
                    isSelected: element.textDecoration == 'line-through',
                    onTap: () {
                      _saveToHistory();
                      updateState(() {
                        element.textDecoration = element.textDecoration == 'line-through' ? 'none' : 'line-through';
                      });
                    },
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),

          // 间距：字间距 & 行高独占一行
          _buildPropertySlider(
            label: '字距',
            value: element.letterSpacing.clamp(0.0, 15.0),
            min: 0.0,
            max: 15.0,
            displayValue: element.letterSpacing.toStringAsFixed(1),
            onChanged: (val) {
              _saveToHistory();
              updateState(() {
                element.letterSpacing = val;
                _adjustTextElementWidth(element);
              });
            },
          ),
          const SizedBox(height: 4),
          _buildPropertySlider(
            label: '行高',
            value: element.lineHeight.clamp(0.8, 3.0),
            min: 0.8,
            max: 3.0,
            displayValue: element.lineHeight.toStringAsFixed(1),
            onChanged: (val) {
              _saveToHistory();
              updateState(() {
                element.lineHeight = val;
              });
            },
          ),
          const SizedBox(height: 4),

          // 透明度
          _buildPropertySlider(
            label: '透明度',
            value: element.opacity.clamp(0.0, 1.0),
            min: 0.0,
            max: 1.0,
            displayValue: '${(element.opacity * 100).toInt()}%',
            onChanged: (val) {
              _saveToHistory();
              updateState(() {
                element.opacity = val;
              });
            },
          ),
          const SizedBox(height: 12),
          const Divider(height: 1, color: Color(0xFFECE5DF)),
          const SizedBox(height: 12),
          // 文本背景颜色
          Row(
            children: [
              const Text(
                '文字背景: ',
                style: TextStyle(fontSize: 10, color: Color(0xFF8A7A6E), fontFamily: 'LXGWWenKai', fontWeight: FontWeight.bold),
              ),
              const SizedBox(width: 8),
              // 无背景按钮
              GestureDetector(
                onTap: () {
                  _saveToHistory();
                  updateState(() {
                    element.textBackgroundColor = null;
                    _adjustTextElementWidth(element);
                  });
                },
                child: Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    color: Colors.transparent,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: element.textBackgroundColor == null ? const Color(0xFF5A3E28) : Colors.grey[300]!,
                      width: element.textBackgroundColor == null ? 2.5 : 1,
                    ),
                  ),
                  child: const Center(
                    child: Icon(Icons.block, size: 14, color: Colors.grey),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              // 自定义背景颜色选择按钮
              GestureDetector(
                onTap: () {
                  showCustomColorPickerBottomSheet(
                    context,
                    initialColor: element.textBackgroundColor ?? Colors.white,
                    onColorSelected: (color) {
                      _saveToHistory();
                      updateState(() {
                        element.textBackgroundColor = color;
                        _adjustTextElementWidth(element);
                      });
                    },
                  );
                },
                child: Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: Colors.transparent,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: (element.textBackgroundColor != null &&
                              !const [
                                Colors.white,
                                Color(0xFFFEE2E2),
                                Color(0xFFFEF3C7),
                                Color(0xFFD1FAE5),
                                Color(0xFFDBEAFE),
                                Color(0xFFF3E8FF)
                              ].contains(element.textBackgroundColor))
                          ? const Color(0xFF5A3E28)
                          : Colors.grey[300]!,
                      width: (element.textBackgroundColor != null &&
                              !const [
                                Colors.white,
                                Color(0xFFFEE2E2),
                                Color(0xFFFEF3C7),
                                Color(0xFFD1FAE5),
                                Color(0xFFDBEAFE),
                                Color(0xFFF3E8FF)
                              ].contains(element.textBackgroundColor))
                          ? 2.5
                          : 1,
                    ),
                  ),
                  child: const Center(
                    child: Icon(Icons.colorize_rounded, size: 14, color: Color(0xFF5A3E28)),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              _ExportColorPicker(
                colors: const [Colors.white, Color(0xFFFEE2E2), Color(0xFFFEF3C7), Color(0xFFD1FAE5), Color(0xFFDBEAFE), Color(0xFFF3E8FF)],
                selectedColor: element.textBackgroundColor,
                size: 28,
                spacing: 10,
                onColorSelected: (c) {
                  _saveToHistory();
                  updateState(() {
                    element.textBackgroundColor = c;
                    _adjustTextElementWidth(element);
                  });
                },
              ),
            ],
          ),
          
          if (element.textBackgroundColor != null) ...[
            const SizedBox(height: 12),
            _buildPropertySlider(
              label: '背景圆角',
              value: element.textBackgroundBorderRadius.clamp(0.0, 30.0),
              min: 0.0,
              max: 30.0,
              displayValue: '${element.textBackgroundBorderRadius.toInt()}px',
              onChanged: (val) {
                _saveToHistory();
                updateState(() {
                  element.textBackgroundBorderRadius = val;
                });
              },
            ),
            const SizedBox(height: 4),
            _buildPropertySlider(
              label: '背景边距',
              value: element.textBackgroundPadding.clamp(0.0, 30.0),
              min: 0.0,
              max: 30.0,
              displayValue: '${element.textBackgroundPadding.toInt()}px',
              onChanged: (val) {
                _saveToHistory();
                updateState(() {
                  element.textBackgroundPadding = val;
                  _adjustTextElementWidth(element);
                });
              },
            ),
            const SizedBox(height: 4),
            _buildPropertySlider(
              label: '背景透明',
              value: element.textBackgroundOpacity.clamp(0.0, 1.0),
              min: 0.0,
              max: 1.0,
              displayValue: '${(element.textBackgroundOpacity * 100).toInt()}%',
              onChanged: (val) {
                _saveToHistory();
                updateState(() {
                  element.textBackgroundOpacity = val;
                });
              },
            ),
          ],
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
              updateState(() {
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
              updateState(() {
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
                    updateState(() {
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
        if (element.type == 'line') ...[
          // 分割线样式选择 (平铺平滑按钮)
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                '线条样式',
                style: TextStyle(fontSize: 10, color: Color(0xFF8A7A6E), fontFamily: 'LXGWWenKai', fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 6),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                child: Row(
                  children: [
                    _buildLineStyleItem(element, 'solid', '实线'),
                    const SizedBox(width: 8),
                    _buildLineStyleItem(element, 'dashed', '虚线'),
                    const SizedBox(width: 8),
                    _buildLineStyleItem(element, 'dotted', '点线'),
                    const SizedBox(width: 8),
                    _buildLineStyleItem(element, 'double', '双线'),
                    const SizedBox(width: 8),
                    _buildLineStyleItem(element, 'wavy', '波浪'),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          
          // 线段粗细
          _buildPropertySlider(
            label: '线条粗细',
            value: element.height.clamp(1.0, 15.0),
            min: 1.0,
            max: 15.0,
            displayValue: '${element.height.toStringAsFixed(1)}px',
            onChanged: (val) {
              _saveToHistory();
              updateState(() {
                element.height = val;
              });
            },
          ),
          const SizedBox(height: 12),
          
          // 透明度
          _buildPropertySlider(
            label: '透明度',
            value: element.opacity.clamp(0.0, 1.0),
            min: 0.0,
            max: 1.0,
            displayValue: '${(element.opacity * 100).toInt()}%',
            onChanged: (val) {
              _saveToHistory();
              updateState(() {
                element.opacity = val;
              });
            },
          ),
        ],
        if (element.type == 'shape') ...[
          // 透明度
          _buildPropertySlider(
            label: '不透明度',
            value: element.opacity.clamp(0.0, 1.0),
            min: 0.0,
            max: 1.0,
            displayValue: '${(element.opacity * 100).toInt()}%',
            onChanged: (val) {
              _saveToHistory();
              updateState(() {
                element.opacity = val;
              });
            },
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
              // 自定义颜色选择按钮
              GestureDetector(
                onTap: () {
                  showCustomColorPickerBottomSheet(
                    context,
                    initialColor: element.color,
                    onColorSelected: (color) {
                      _saveToHistory();
                      updateState(() {
                        element.color = color;
                      });
                    },
                  );
                },
                child: Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: Colors.transparent,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: (!const [
                                Colors.black87,
                                Colors.teal,
                                Colors.red,
                                Colors.blue,
                                Colors.orange,
                                Colors.purple,
                                Colors.green
                              ].contains(element.color))
                          ? const Color(0xFF5A3E28)
                          : Colors.grey[300]!,
                      width: (!const [
                                Colors.black87,
                                Colors.teal,
                                Colors.red,
                                Colors.blue,
                                Colors.orange,
                                Colors.purple,
                                Colors.green
                              ].contains(element.color))
                          ? 2.5
                          : 1,
                    ),
                  ),
                  child: const Center(
                    child: Icon(Icons.colorize_rounded, size: 14, color: Color(0xFF5A3E28)),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              _ExportColorPicker(
                colors: const [Colors.black87, Colors.teal, Colors.red, Colors.blue, Colors.orange, Colors.purple, Colors.green],
                selectedColor: element.color,
                size: 28,
                spacing: 10,
                onColorSelected: (c) {
                  _saveToHistory();
                  updateState(() {
                    element.color = c;
                  });
                },
              ),
            ],
          ),
      ],
    );
  }

  Widget _buildPositionNudgeSection(ExportElement element) {
    return Container(
      margin: const EdgeInsets.only(bottom: 4),
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
                '位置微调',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF5A3E28),
                  fontFamily: 'LXGWWenKai',
                ),
              ),
              const SizedBox(height: 2),
              Text(
                'X: ${element.x.toInt()}  Y: ${element.y.toInt()}',
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
                  element.x -= 1;
                });
              }),
              const SizedBox(width: 8),
              _buildNudgeArrow(Icons.keyboard_arrow_up_rounded, () {
                updateState(() {
                  element.y -= 1;
                });
              }),
              const SizedBox(width: 8),
              _buildNudgeArrow(Icons.keyboard_arrow_down_rounded, () {
                updateState(() {
                  element.y += 1;
                });
              }),
              const SizedBox(width: 8),
              _buildNudgeArrow(Icons.keyboard_arrow_right_rounded, () {
                updateState(() {
                  element.x += 1;
                });
              }),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildNudgeArrow(IconData icon, VoidCallback onMove) {
    return GestureDetector(
      onTapDown: (_) {
        _nudgeTimer?.cancel();
        _saveToHistory();
        onMove();
        // 200毫秒延迟区分点按与长按，随后以50毫秒高频连发移动
        _nudgeTimer = Timer(const Duration(milliseconds: 200), () {
          _nudgeTimer = Timer.periodic(const Duration(milliseconds: 50), (timer) {
            onMove();
          });
        });
      },
      onTapUp: (_) {
        _nudgeTimer?.cancel();
      },
      onTapCancel: () {
        _nudgeTimer?.cancel();
      },
      child: Container(
        width: 32,
        height: 32,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: const Color(0xFFECE5DF), width: 0.8),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: const Color(0xFF5A3E28), size: 20),
      ),
    );
  }

  Widget _buildLineStyleItem(ExportElement element, String styleVal, String label) {
    final currentStyle = element.content.isEmpty ? 'solid' : element.content;
    final bool isSelected = currentStyle == styleVal;
    
    final Color activeColor = const Color(0xFF5A3E28);
    final Color inactiveColor = const Color(0xFF8A7A6E);
    final Color activeBg = const Color(0xFFF4EFEB);
    final Color inactiveBg = const Color(0xFFF7F4F2);

    return GestureDetector(
      onTap: () {
        _saveToHistory();
        updateState(() {
          element.content = styleVal;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? activeBg : inactiveBg,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? activeColor : const Color(0xFFECE5DF),
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            color: isSelected ? activeColor : inactiveColor,
            fontFamily: 'LXGWWenKai',
          ),
        ),
      ),
    );
  }
}
