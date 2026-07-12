part of '../../diary_book_export_page.dart';

extension _ExportPanelsExtension on _DiaryBookExportPageState {
  // --- 底部配置面板及 Tab 切换 ---
  Widget _buildBottomPanel() {
    return ValueListenableBuilder<(bool, int)>(
      valueListenable: _panelStateNotifier,
      builder: (context, panelState, _) {
        final isPanelExpanded = panelState.$1;
        final activeTabIndex = panelState.$2;
        return Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF8A7A6E).withValues(alpha: 0.06),
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
                  height: isPanelExpanded ? 220 : 0,
                  child: ClipRect(
                    child: OverflowBox(
                      minHeight: 0,
                      maxHeight: 220,
                      alignment: Alignment.topCenter,
                      child: Container(
                        height: 220,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 16,
                        ),
                        child: _buildActiveTabContent(activeTabIndex),
                      ),
                    ),
                  ),
                ),
                // 底部分类 Tab 按钮栏
                Container(
                  height: 68,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: const BoxDecoration(
                    color: Colors.transparent,
                    border: Border(
                      top: BorderSide(color: Color(0xFFF3EDE6), width: 1),
                    ),
                  ),
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final double tabWidth = constraints.maxWidth / 6;
                      final activeColor = const Color(0xFF8A7A6E);
                      final inactiveColor = const Color(0xFF9E9185);

                      return Stack(
                        children: [
                          // 滑动背景滑块
                          AnimatedPositioned(
                            duration: const Duration(milliseconds: 250),
                            curve: Curves.easeOutCubic,
                            left: activeTabIndex * tabWidth + 4,
                            top: 2,
                            bottom: 2,
                            width: tabWidth - 8,
                            child: AnimatedOpacity(
                              duration: const Duration(milliseconds: 200),
                              opacity: isPanelExpanded ? 1.0 : 0.0,
                              child: Container(
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF4EFEB),
                                  borderRadius: BorderRadius.circular(16),
                                ),
                              ),
                            ),
                          ),
                          // 选项按钮排布
                          Row(
                            children: List.generate(6, (index) {
                              final isSelected =
                                  isPanelExpanded && activeTabIndex == index;
                              IconData icon;
                              String label;
                              switch (index) {
                                case 0:
                                  icon = Icons.description_outlined;
                                  label = '页面';
                                  break;
                                case 1:
                                  icon = Icons.wallpaper_outlined;
                                  label = '背景';
                                  break;
                                case 2:
                                  icon = Icons.add_circle_outline_rounded;
                                  label = '添加';
                                  break;
                                case 3:
                                  icon = Icons.tune_rounded;
                                  label = '属性';
                                  break;
                                case 4:
                                  icon = Icons.layers_outlined;
                                  label = '图层';
                                  break;
                                case 5:
                                  icon = Icons.ios_share_rounded;
                                  label = '导出';
                                  break;
                                default:
                                  icon = Icons.description_outlined;
                                  label = '';
                              }

                              return Expanded(
                                child: GestureDetector(
                                  behavior: HitTestBehavior.opaque,
                                  onTap: () {
                                    if (_activeTabIndex == index &&
                                        _isPanelExpanded) {
                                      _isPanelExpanded = false;
                                    } else {
                                      _activeTabIndex = index;
                                      _isPanelExpanded = true;
                                    }
                                    _panelStateNotifier.value = (
                                      _isPanelExpanded,
                                      _activeTabIndex,
                                    );
                                  },
                                  child: Container(
                                    color: Colors.transparent,
                                    alignment: Alignment.center,
                                    child: Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        AnimatedScale(
                                          duration: const Duration(
                                            milliseconds: 200,
                                          ),
                                          scale: isSelected ? 1.06 : 1.0,
                                          child: Icon(
                                            icon,
                                            color: isSelected
                                                ? activeColor
                                                : inactiveColor,
                                            size: 20,
                                          ),
                                        ),
                                        const SizedBox(height: 3),
                                        Text(
                                          label,
                                          style: TextStyle(
                                            color: isSelected
                                                ? activeColor
                                                : inactiveColor,
                                            fontSize: 10,
                                            fontWeight: isSelected
                                                ? FontWeight.bold
                                                : FontWeight.w500,
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
      },
    );
  }

  Widget _buildActiveTabContent(int activeTabIndex) {
    Widget content;
    switch (activeTabIndex) {
      case 0:
        content = KeyedSubtree(
          key: const ValueKey(0),
          child: _buildPageSettingsPanel(),
        );
        break;
      case 1:
        content = KeyedSubtree(
          key: const ValueKey(1),
          child: _buildBackgroundPanel(),
        );
        break;
      case 2:
        content = KeyedSubtree(
          key: const ValueKey(2),
          child: _buildAddElementsPanel(),
        );
        break;
      case 3:
        // 属性面板监听 _selectionNotifier，选中新元素时局部刷新
        content = KeyedSubtree(
          key: const ValueKey(3),
          child: ValueListenableBuilder<String?>(
            valueListenable: _selectionNotifier,
            builder: (context, _, _) => _buildPropertiesPanel(),
          ),
        );
        break;
      case 4:
        content = KeyedSubtree(
          key: const ValueKey(4),
          child: _buildLayersPanel(),
        );
        break;
      case 5:
        content = KeyedSubtree(
          key: const ValueKey(5),
          child: _buildExportSettingsPanel(),
        );
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
            position:
                Tween<Offset>(
                  begin: const Offset(0.0, 0.08),
                  end: Offset.zero,
                ).animate(
                  CurvedAnimation(
                    parent: animation,
                    curve: Curves.easeOutCubic,
                  ),
                ),
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
            color: isSelected
                ? const Color(0xFF8A7A6E)
                : const Color(0xFFECE5DF),
            width: 1,
          ),
        ),
        child: Icon(
          icon,
          size: 18,
          color: isSelected ? const Color(0xFF8A7A6E) : const Color(0xFF8A7A6E),
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
              style: const TextStyle(
                fontSize: 10,
                color: Color(0xFF8A7A6E),
                fontFamily: 'LXGWWenKai',
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          Expanded(
            child: SliderTheme(
              data: SliderThemeData(
                activeTrackColor: const Color(0xFF8A7A6E),
                inactiveTrackColor: const Color(0xFFEFECE9),
                thumbColor: const Color(0xFF8A7A6E),
                trackHeight: 3.0,
                thumbShape: const RoundSliderThumbShape(
                  enabledThumbRadius: 6.0,
                ),
                overlayColor: const Color(0xFF8A7A6E).withValues(alpha: 0.12),
                overlayShape: const RoundSliderOverlayShape(
                  overlayRadius: 14.0,
                ),
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
              style: const TextStyle(
                fontSize: 10,
                color: Color(0xFF8A7A6E),
                fontFamily: 'LXGWWenKai',
              ),
              textAlign: TextAlign.end,
            ),
          ),
        ],
      ),
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
        return _AnimatedColorThumbnail(
          color: c,
          isSelected: isSelected,
          onTap: () => onColorSelected(c),
          size: size,
          spacing: spacing,
        );
      }).toList(),
    );
  }
}

class _AnimatedColorThumbnail extends StatefulWidget {
  final Color color;
  final bool isSelected;
  final VoidCallback onTap;
  final double size;
  final double spacing;

  const _AnimatedColorThumbnail({
    required this.color,
    required this.isSelected,
    required this.onTap,
    required this.size,
    required this.spacing,
  });

  @override
  State<_AnimatedColorThumbnail> createState() => _AnimatedColorThumbnailState();
}

class _AnimatedColorThumbnailState extends State<_AnimatedColorThumbnail> with SingleTickerProviderStateMixin {
  bool _isPressed = false;
  late AnimationController _sweepController;

  @override
  void initState() {
    super.initState();
    _sweepController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    if (widget.isSelected) {
      _sweepController.value = 1.0;
    }
  }

  @override
  void didUpdateWidget(_AnimatedColorThumbnail oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isSelected && !oldWidget.isSelected) {
      _sweepController.forward(from: 0.0);
    }
  }

  @override
  void dispose() {
    _sweepController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) {
        setState(() => _isPressed = false);
        widget.onTap();
      },
      onTapCancel: () => setState(() => _isPressed = false),
      child: AnimatedScale(
        scale: _isPressed ? 0.90 : 1.0,
        duration: const Duration(milliseconds: 150),
        curve: Curves.easeOutQuad,
        child: Container(
          width: widget.size,
          height: widget.size,
          margin: EdgeInsets.only(right: widget.spacing),
          child: Stack(
            fit: StackFit.expand,
            clipBehavior: Clip.none,
            children: [
              // 1. 选中框
              if (widget.isSelected)
                Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: widget.color,
                      width: 2,
                    ),
                  ),
                ),
              // 2. 底色
              Container(
                margin: widget.isSelected ? const EdgeInsets.all(3.0) : EdgeInsets.zero,
                decoration: BoxDecoration(
                  color: widget.color,
                  shape: BoxShape.circle,
                ),
              ),
              
              // 2. 扫光效果 (只在动画中绘制)
              if (widget.isSelected)
                Positioned.fill(
                  child: ClipOval(
                    child: AnimatedBuilder(
                      animation: _sweepController,
                      builder: (context, child) {
                        if (_sweepController.isCompleted) return const SizedBox.shrink();
                        
                        final val = -1.0 + (_sweepController.value * 3.0);
                        return FractionalTranslation(
                          translation: Offset(val, 0),
                          child: Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  Colors.white.withValues(alpha: 0.0),
                                  Colors.white.withValues(alpha: 0.5),
                                  Colors.white.withValues(alpha: 0.0),
                                ],
                                stops: const [0.1, 0.5, 0.9],
                                // 使用 0.523 弧度 (约 pi/6) 避免引入 dart:math 依赖
                                transform: const GradientRotation(0.523),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
                
              // 3. 边框渐显
              Positioned.fill(
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  curve: Curves.easeOut,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: widget.isSelected ? const Color(0xFF8A7A6E) : Colors.grey[200]!,
                      width: widget.isSelected ? 2 : 1,
                    ),
                    boxShadow: widget.isSelected
                        ? [
                            BoxShadow(
                              color: const Color(0xFF8A7A6E).withValues(alpha: 0.15),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ]
                        : null,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
