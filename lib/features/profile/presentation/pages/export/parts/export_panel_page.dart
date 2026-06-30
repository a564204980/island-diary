part of '../../diary_book_export_page.dart';

extension _ExportPanelPageExtension on _DiaryBookExportPageState {
  // 1. 页面设置面板
  Widget _buildPageSettingsPanel() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Tab Header 分栏
        Row(
          children: [
            _buildTabHeaderItem(0, '纸张尺寸'),
            const SizedBox(width: 16),
            _buildTabHeaderItem(1, '我的模板'),
          ],
        ),
        const SizedBox(height: 12),
        // Tab 内容区域
        Expanded(
          child: _pageTabIdx == 0
              ? _buildPaperSizeSettingsContent()
              : _buildMyTemplatesContent(),
        ),
      ],
    );
  }

  Widget _buildTabHeaderItem(int index, String title) {
    final bool isSelected = _pageTabIdx == index;
    final Color activeColor = const Color(0xFF5A3E28);
    final Color inactiveColor = const Color(0xFF8A7A6E);
    return GestureDetector(
      onTap: () {
        updateState(() {
          _pageTabIdx = index;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFF4EFEB) : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          title,
          style: TextStyle(
            fontFamily: 'LXGWWenKai',
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
            color: isSelected ? activeColor : inactiveColor,
          ),
        ),
      ),
    );
  }

  Widget _buildPaperSizeSettingsContent() {
    return ListView(
      physics: const BouncingScrollPhysics(),
      padding: EdgeInsets.zero,
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
        _buildPageLocator(),
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
        _buildPropertySlider(
          label: '左边距',
          value: _margin.left,
          min: 0,
          max: 60,
          displayValue: '${_margin.left.toInt()}',
          onChanged: (val) {
            updateState(() => _margin.left = val);
            _updateElementsMargin();
          },
        ),
        const SizedBox(height: 2),
        _buildPropertySlider(
          label: '右边距',
          value: _margin.right,
          min: 0,
          max: 60,
          displayValue: '${_margin.right.toInt()}',
          onChanged: (val) {
            updateState(() => _margin.right = val);
            _updateElementsMargin();
          },
        ),
        const SizedBox(height: 2),
        _buildPropertySlider(
          label: '上边距',
          value: _margin.top,
          min: 0,
          max: 80,
          displayValue: '${_margin.top.toInt()}',
          onChanged: (val) {
            updateState(() => _margin.top = val);
            _updateElementsMargin();
          },
        ),
        const SizedBox(height: 2),
        _buildPropertySlider(
          label: '下边距',
          value: _margin.bottom,
          min: 0,
          max: 80,
          displayValue: '${_margin.bottom.toInt()}',
          onChanged: (val) {
            updateState(() => _margin.bottom = val);
            _updateElementsMargin();
          },
        ),
      ],
    );
  }

  Widget _buildMyTemplatesContent() {
    if (_isLoadingTemplates) {
      return const Center(
        child: SizedBox(
          width: 24,
          height: 24,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF5A3E28)),
          ),
        ),
      );
    }

    if (_savedTemplates.isEmpty) {
      return Container(
        margin: const EdgeInsets.only(top: 4, bottom: 4),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: const Color(0xFFF7F4F2).withValues(alpha: 0.6),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFECE5DF), width: 1),
        ),
        child: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.auto_awesome_motion_outlined,
                size: 28,
                color: Color(0xFFC4B8B0),
              ),
              SizedBox(height: 8),
              Text(
                '暂无自定义模板',
                style: TextStyle(
                  fontFamily: 'LXGWWenKai',
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF8A7A6E),
                ),
              ),
              SizedBox(height: 4),
              Text(
                '可在右上角将当前排版保存为模板哦',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'LXGWWenKai',
                  fontSize: 10,
                  color: Color(0xFFC4B8B0),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      physics: const BouncingScrollPhysics(),
      padding: EdgeInsets.zero,
      itemCount: _savedTemplates.length,
      itemBuilder: (context, index) {
        final template = _savedTemplates[index];
        return _buildTemplateCardItem(template);
      },
    );
  }

  Widget _buildTemplateCardItem(ExportTemplateModel template) {
    final String sizeInfo = "${template.pageSize.name} · ${template.pageSize.width > template.pageSize.height ? '横向' : '纵向'}";
    final int elementCount = template.elements.length;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFF7F4F2),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFECE5DF), width: 1),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _applyTemplate(template),
          borderRadius: BorderRadius.circular(14),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            child: Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF4EFEB),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  alignment: Alignment.center,
                  child: const Icon(
                    Icons.dashboard_customize_outlined,
                    size: 16,
                    color: Color(0xFF5A3E28),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        template.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontFamily: 'LXGWWenKai',
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF5A3E28),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        "$sizeInfo · $elementCount个元素",
                        style: const TextStyle(
                          fontFamily: 'LXGWWenKai',
                          fontSize: 10,
                          color: Color(0xFF8A7A6E),
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline_rounded, size: 18, color: Colors.redAccent),
                  onPressed: () => _showDeleteConfirmDialog(template),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  splashRadius: 20,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showDeleteConfirmDialog(ExportTemplateModel template) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 20),
                  child: Column(
                    children: [
                      const Icon(Icons.warning_amber_rounded, color: Colors.redAccent, size: 36),
                      const SizedBox(height: 12),
                      const Text(
                        '确认删除模板吗？',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1F2937),
                          fontFamily: 'LXGWWenKai',
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '模板 "${template.name}" 删除后将无法找回哦。',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFF6B7280),
                          fontFamily: 'LXGWWenKai',
                        ),
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1, color: Color(0xFFE5E7EB)),
                Row(
                  children: [
                    Expanded(
                      child: InkWell(
                        onTap: () {
                          Navigator.pop(context);
                        },
                        borderRadius: const BorderRadius.only(bottomLeft: Radius.circular(20)),
                        child: Container(
                          height: 48,
                          alignment: Alignment.center,
                          child: const Text(
                            '取消',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey,
                              fontFamily: 'LXGWWenKai',
                            ),
                          ),
                        ),
                      ),
                    ),
                    Container(width: 1, height: 48, color: const Color(0xFFE5E7EB)),
                    Expanded(
                      child: InkWell(
                        onTap: () async {
                          Navigator.pop(context);
                          await _deleteTemplate(template);
                          if (!mounted) return;
                          showTopToast(
                            this.context,
                            '模板 "${template.name}" 已删除',
                            icon: Icons.delete_outline_rounded,
                            iconColor: Colors.redAccent,
                          );
                        },
                        borderRadius: const BorderRadius.only(bottomRight: Radius.circular(20)),
                        child: Container(
                          height: 48,
                          alignment: Alignment.center,
                          child: const Text(
                            '确认删除',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: Colors.redAccent,
                              fontFamily: 'LXGWWenKai',
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
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
            bottom: 24 + MediaQuery.of(context).padding.bottom,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                '选择纸张尺寸',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF5A3E28), fontFamily: 'LXGWWenKai'),
              ),
              const SizedBox(height: 16),
              ...ExportPageSize.presets.map((p) => _buildPageSizeCardItem(p)),
            ],
          ),
        );
      },
    );
  }

  Widget _buildPageSizeCardItem(ExportPageSize p) {
    final bool isSelected = _pageSize.name == p.name;
    
    String subtitle = '自定义比例规格';
    double previewWidth = 18.0;
    double previewHeight = 24.0;
    
    if (p.name.contains('A4')) {
      subtitle = '210 × 297 mm · 适合标准双页打印';
      previewWidth = 18.0;
      previewHeight = 25.4;
    } else if (p.name.contains('A5')) {
      subtitle = '148 × 210 mm · 适合精致便携手帐';
      previewWidth = 18.0;
      previewHeight = 25.4;
    } else if (p.name.contains('Letter')) {
      subtitle = '8.5 × 11 inch · 美标信纸排版';
      previewWidth = 19.5;
      previewHeight = 25.2;
    } else if (p.name.contains('手机屏幕')) {
      subtitle = '9 : 19.5 · 适合移动端无缝预览';
      previewWidth = 12.0;
      previewHeight = 26.0;
    } else if (p.name.contains('自定义')) {
      subtitle = '个性化画布比例规格';
      previewWidth = 20.0;
      previewHeight = 20.0;
    }

    final Color activeColor = const Color(0xFF5A3E28);
    final Color inactiveColor = const Color(0xFF8A7A6E);

    return GestureDetector(
      onTap: () {
        Navigator.pop(context);
        updateState(() {
          _pageSize = p;
        });
        _updateElementsMargin();
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _recenterCanvas(animate: true);
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFF4EFEB) : const Color(0xFFF7F4F2),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? activeColor : const Color(0xFFECE5DF),
            width: isSelected ? 1.5 : 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: activeColor.withValues(alpha: 0.05),
                    blurRadius: 6,
                    offset: const Offset(0, 3),
                  )
                ]
              : null,
        ),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: isSelected ? Colors.white : const Color(0xFFECE5DF),
                borderRadius: BorderRadius.circular(10),
              ),
              alignment: Alignment.center,
              child: Container(
                width: previewWidth,
                height: previewHeight,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(2),
                  border: Border.all(
                    color: isSelected ? activeColor : inactiveColor,
                    width: 1.2,
                  ),
                  color: isSelected ? activeColor.withValues(alpha: 0.08) : Colors.transparent,
                ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    p.name,
                    style: TextStyle(
                      fontFamily: 'LXGWWenKai',
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: activeColor,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontFamily: 'LXGWWenKai',
                      fontSize: 10,
                      color: inactiveColor,
                    ),
                  ),
                ],
              ),
            ),
            if (isSelected)
              Icon(Icons.check_circle_rounded, color: activeColor, size: 18)
            else
              Container(
                width: 18,
                height: 18,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: const Color(0xFFECE5DF), width: 1.5),
                ),
              ),
          ],
        ),
      ),
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
          updateState(() {
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

  Widget _buildPageLocator() {
    final int count = _pageCount;
    if (count <= 1) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '页面定位',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 10,
            color: Color(0xFF8A7A6E),
            fontFamily: 'LXGWWenKai',
          ),
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 38,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            itemCount: count + 1,
            separatorBuilder: (context, index) => const SizedBox(width: 8),
            itemBuilder: (context, index) {
              if (index == 0) {
                return _JumpInputWidget(
                  pageCount: count,
                  onJump: (pIdx) => _navigateToPage(pIdx),
                );
              }

              final int pageIdx = index - 1;
              final bool isSelected = _focusedPageIndex == pageIdx;
              return GestureDetector(
                onTap: () => _navigateToPage(pageIdx),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: isSelected ? Colors.white : const Color(0xFFF7F4F2),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isSelected ? const Color(0xFFECE5DF) : Colors.transparent,
                      width: 1,
                    ),
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
                    '第 ${pageIdx + 1} 页',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                      color: isSelected ? const Color(0xFF5A3E28) : const Color(0xFF8A7A6E),
                      fontFamily: 'LXGWWenKai',
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }
}

// 直接输入页码跳转的小输入框组件
class _JumpInputWidget extends StatefulWidget {
  final int pageCount;
  final Function(int) onJump;

  const _JumpInputWidget({
    required this.pageCount,
    required this.onJump,
  });

  @override
  State<_JumpInputWidget> createState() => _JumpInputWidgetState();
}

class _JumpInputWidgetState extends State<_JumpInputWidget> {
  late TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 76,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: const Color(0xFFF7F4F2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFFECE5DF),
          width: 1,
        ),
      ),
      child: TextField(
        controller: _controller,
        keyboardType: TextInputType.number,
        textAlign: TextAlign.center,
        textInputAction: TextInputAction.go,
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: Color(0xFF5A3E28),
          fontFamily: 'LXGWWenKai',
        ),
        decoration: const InputDecoration(
          isDense: true,
          contentPadding: EdgeInsets.symmetric(horizontal: 2, vertical: 8),
          border: InputBorder.none,
          hintText: '页码跳转',
          hintStyle: TextStyle(
            fontSize: 10,
            color: Color(0xFFC4B8B0),
            fontFamily: 'LXGWWenKai',
          ),
        ),
        onSubmitted: (val) {
          final pageNum = int.tryParse(val.trim());
          if (pageNum != null && pageNum >= 1 && pageNum <= widget.pageCount) {
            widget.onJump(pageNum - 1);
            _controller.clear();
          } else {
            _controller.clear();
          }
        },
      ),
    );
  }
}
