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
            AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              curve: Curves.easeInOut,
              height: _isPanelExpanded ? 220 : 0,
              child: ClipRect(
                child: OverflowBox(
                  minHeight: 0,
                  maxHeight: 220,
                  alignment: Alignment.topCenter,
                  child: Container(
                    height: 220,
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                    child: _buildActiveTabContent(),
                  ),
                ),
              ),
            ),
            // 底部分类 Tab 按钮栏
            Container(
              height: 68,
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: const BoxDecoration(
                color: Colors.transparent,
                border: Border(top: BorderSide(color: Color(0xFFF3EDE6), width: 1)),
              ),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final double tabWidth = constraints.maxWidth / 6;
                  final activeColor = const Color(0xFF5A3E28);
                  final inactiveColor = const Color(0xFF9E9185);

                  return Stack(
                     children: [
                       // 滑动背景滑块
                       AnimatedPositioned(
                         duration: const Duration(milliseconds: 250),
                         curve: Curves.easeOutCubic,
                         left: _activeTabIndex * tabWidth + 4,
                         top: 2,
                         bottom: 2,
                         width: tabWidth - 8,
                         child: Container(
                           decoration: BoxDecoration(
                             color: const Color(0xFFF4EFEB),
                             borderRadius: BorderRadius.circular(16),
                           ),
                         ),
                       ),
                       // 选项按钮排布
                       Row(
                         children: List.generate(6, (index) {
                           final isSelected = _activeTabIndex == index;
                           IconData icon;
                           String label;
                           switch (index) {
                             case 0: icon = Icons.description_outlined; label = '页面'; break;
                             case 1: icon = Icons.wallpaper_outlined; label = '背景'; break;
                             case 2: icon = Icons.add_circle_outline_rounded; label = '添加'; break;
                             case 3: icon = Icons.tune_rounded; label = '属性'; break;
                             case 4: icon = Icons.layers_outlined; label = '图层'; break;
                             case 5: icon = Icons.ios_share_rounded; label = '导出'; break;
                             default: icon = Icons.description_outlined; label = '';
                           }

                           return Expanded(
                             child: GestureDetector(
                               behavior: HitTestBehavior.opaque,
                               onTap: () {
                                 setState(() {
                                   if (_activeTabIndex == index && _isPanelExpanded) {
                                     _isPanelExpanded = false;
                                   } else {
                                     _activeTabIndex = index;
                                     _isPanelExpanded = true;
                                   }
                                 });
                               },
                               child: Container(
                                 color: Colors.transparent,
                                 alignment: Alignment.center,
                                 child: Column(
                                   mainAxisAlignment: MainAxisAlignment.center,
                                   mainAxisSize: MainAxisSize.min,
                                   children: [
                                     AnimatedScale(
                                       duration: const Duration(milliseconds: 200),
                                       scale: isSelected ? 1.06 : 1.0,
                                       child: Icon(
                                         icon,
                                         color: isSelected ? activeColor : inactiveColor,
                                         size: 20,
                                       ),
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
                             ),
                           );
                         }),
                       ),
                     ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActiveTabContent() {
    Widget content;
    switch (_activeTabIndex) {
      case 0:
        content = KeyedSubtree(key: const ValueKey(0), child: _buildPageSettingsPanel());
        break;
      case 1:
        content = KeyedSubtree(key: const ValueKey(1), child: _buildBackgroundPanel());
        break;
      case 2:
        content = KeyedSubtree(key: const ValueKey(2), child: _buildAddElementsPanel());
        break;
      case 3:
        content = KeyedSubtree(key: const ValueKey(3), child: _buildPropertiesPanel());
        break;
      case 4:
        content = KeyedSubtree(key: const ValueKey(4), child: _buildLayersPanel());
        break;
      case 5:
        content = KeyedSubtree(key: const ValueKey(5), child: _buildExportSettingsPanel());
        break;
      default:
        content = const SizedBox.shrink();
    }

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 250),
      transitionBuilder: (Widget child, Animation<double> animation) {
        return FadeTransition(
          opacity: animation,
          child: SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0.0, 0.08),
              end: Offset.zero,
            ).animate(CurvedAnimation(parent: animation, curve: Curves.easeOutCubic)),
            child: child,
          ),
        );
      },
      child: content,
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
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFF4EFEB) : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? const Color(0xFF5A3E28) : const Color(0xFFECE5DF),
            width: 1,
          ),
        ),
        child: Icon(
          icon,
          size: 18,
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
    return SizedBox(
      height: 38,
      child: Row(
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
                trackHeight: 3.0,
                thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6.0),
                overlayColor: const Color(0xFF5A3E28).withValues(alpha: 0.12),
                overlayShape: const RoundSliderOverlayShape(overlayRadius: 14.0),
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
            width: 32,
            child: Text(
              displayValue,
              style: const TextStyle(fontSize: 10, color: Color(0xFF5A3E28), fontFamily: 'LXGWWenKai'),
              textAlign: TextAlign.end,
            ),
          ),
        ],
      ),
    );
  }

  void _showColorPickerBottomSheet(Color initialColor, ValueChanged<Color> onColorSelected) {
    final hsv = HSVColor.fromColor(initialColor);
    double currentHue = hsv.hue;
    double currentSaturation = hsv.saturation;
    double currentValue = hsv.value;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            final pickerColor = HSVColor.fromAHSV(1.0, currentHue, currentSaturation, currentValue).toColor();
            final String hexColor = '#${pickerColor.value.toRadixString(16).substring(2).toUpperCase()}';
            
            return DiaryBottomSheet(
              paperStyle: 'default',
              showDragHandle: true,
              isDiary: false,
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 8,
                bottom: 24 + MediaQuery.of(context).padding.bottom,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.palette_outlined, size: 20, color: Color(0xFF5A3E28)),
                          SizedBox(width: 8),
                          Text(
                            '自定义背景颜色',
                            style: TextStyle(
                              fontFamily: 'LXGWWenKai',
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF5A3E28),
                            ),
                          ),
                        ],
                      ),
                      IconButton(
                        icon: const Icon(Icons.close_rounded, color: Colors.grey, size: 20),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  
                  // 1. 色相卡片
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    margin: const EdgeInsets.only(bottom: 12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF7F4F2),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFFECE5DF), width: 1),
                    ),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              '色调',
                              style: TextStyle(fontSize: 11, color: Color(0xFF8A7A6E), fontFamily: 'LXGWWenKai', fontWeight: FontWeight.bold),
                            ),
                            Text(
                              '${currentHue.toInt()}°',
                              style: const TextStyle(fontSize: 11, color: Color(0xFF5A3E28), fontFamily: 'LXGWWenKai', fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Stack(
                          alignment: Alignment.center,
                          children: [
                            Container(
                              height: 10,
                              margin: const EdgeInsets.symmetric(horizontal: 22),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(5),
                                gradient: const LinearGradient(
                                  colors: [
                                    Color(0xFFFF0000),
                                    Color(0xFFFFFF00),
                                    Color(0xFF00FF00),
                                    Color(0xFF00FFFF),
                                    Color(0xFF0000FF),
                                    Color(0xFFFF00FF),
                                    Color(0xFFFF0000),
                                  ],
                                ),
                              ),
                            ),
                            SliderTheme(
                              data: SliderThemeData(
                                activeTrackColor: Colors.transparent,
                                inactiveTrackColor: Colors.transparent,
                                thumbColor: Colors.white,
                                trackHeight: 10.0,
                                thumbShape: const RoundSliderThumbShape(
                                  enabledThumbRadius: 8.0,
                                  elevation: 2.0,
                                  pressedElevation: 4.0,
                                ),
                                overlayColor: Colors.white.withValues(alpha: 0.2),
                                overlayShape: const RoundSliderOverlayShape(overlayRadius: 12.0),
                              ),
                              child: Slider(
                                value: currentHue,
                                min: 0.0,
                                max: 360.0,
                                onChanged: (val) {
                                  setSheetState(() {
                                    currentHue = val;
                                  });
                                },
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // 2. 饱和度卡片
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    margin: const EdgeInsets.only(bottom: 12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF7F4F2),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFFECE5DF), width: 1),
                    ),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              '鲜艳度',
                              style: TextStyle(fontSize: 11, color: Color(0xFF8A7A6E), fontFamily: 'LXGWWenKai', fontWeight: FontWeight.bold),
                            ),
                            Text(
                              '${(currentSaturation * 100).toInt()}%',
                              style: const TextStyle(fontSize: 11, color: Color(0xFF5A3E28), fontFamily: 'LXGWWenKai', fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Stack(
                          alignment: Alignment.center,
                          children: [
                            Container(
                              height: 10,
                              margin: const EdgeInsets.symmetric(horizontal: 22),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(5),
                                gradient: LinearGradient(
                                  colors: [
                                    Colors.white,
                                    HSVColor.fromAHSV(1.0, currentHue, 1.0, 1.0).toColor(),
                                  ],
                                ),
                              ),
                            ),
                            SliderTheme(
                              data: SliderThemeData(
                                activeTrackColor: Colors.transparent,
                                inactiveTrackColor: Colors.transparent,
                                thumbColor: Colors.white,
                                trackHeight: 10.0,
                                thumbShape: const RoundSliderThumbShape(
                                  enabledThumbRadius: 8.0,
                                  elevation: 2.0,
                                  pressedElevation: 4.0,
                                ),
                                overlayColor: Colors.white.withValues(alpha: 0.2),
                                overlayShape: const RoundSliderOverlayShape(overlayRadius: 12.0),
                              ),
                              child: Slider(
                                value: currentSaturation,
                                min: 0.0,
                                max: 1.0,
                                onChanged: (val) {
                                  setSheetState(() {
                                    currentSaturation = val;
                                  });
                                },
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // 3. 亮度卡片
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    margin: const EdgeInsets.only(bottom: 20),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF7F4F2),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFFECE5DF), width: 1),
                    ),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              '明暗度',
                              style: TextStyle(fontSize: 11, color: Color(0xFF8A7A6E), fontFamily: 'LXGWWenKai', fontWeight: FontWeight.bold),
                            ),
                            Text(
                              '${(currentValue * 100).toInt()}%',
                              style: const TextStyle(fontSize: 11, color: Color(0xFF5A3E28), fontFamily: 'LXGWWenKai', fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Stack(
                          alignment: Alignment.center,
                          children: [
                            Container(
                              height: 10,
                              margin: const EdgeInsets.symmetric(horizontal: 22),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(5),
                                gradient: LinearGradient(
                                  colors: [
                                    Colors.black,
                                    HSVColor.fromAHSV(1.0, currentHue, currentSaturation, 1.0).toColor(),
                                  ],
                                ),
                              ),
                            ),
                            SliderTheme(
                              data: SliderThemeData(
                                activeTrackColor: Colors.transparent,
                                inactiveTrackColor: Colors.transparent,
                                thumbColor: Colors.white,
                                trackHeight: 10.0,
                                thumbShape: const RoundSliderThumbShape(
                                  enabledThumbRadius: 8.0,
                                  elevation: 2.0,
                                  pressedElevation: 4.0,
                                ),
                                overlayColor: Colors.white.withValues(alpha: 0.2),
                                overlayShape: const RoundSliderOverlayShape(overlayRadius: 12.0),
                              ),
                              child: Slider(
                                value: currentValue,
                                min: 0.0,
                                max: 1.0,
                                onChanged: (val) {
                                  setSheetState(() {
                                    currentValue = val;
                                  });
                                },
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // 预览与确定
                  Row(
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: pickerColor,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.black.withValues(alpha: 0.08), width: 1.5),
                          boxShadow: [
                            BoxShadow(
                              color: pickerColor.withValues(alpha: 0.2),
                              blurRadius: 8,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        hexColor,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF5A3E28),
                          fontFamily: 'LXGWWenKai',
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {
                            onColorSelected(pickerColor);
                            Navigator.pop(context);
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF5A3E28),
                            foregroundColor: Colors.white,
                            elevation: 0,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          ),
                          child: const Text(
                            '确定使用该颜色',
                            style: TextStyle(
                              fontFamily: 'LXGWWenKai',
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          }
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
