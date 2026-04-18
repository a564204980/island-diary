import 'package:flutter/material.dart';
import '../../controllers/decoration_controller.dart';

class WallColorPickerOverlay extends StatefulWidget {
  final DecorationController controller;
  final VoidCallback onClose;

  const WallColorPickerOverlay({
    super.key,
    required this.controller,
    required this.onClose,
  });

  @override
  State<WallColorPickerOverlay> createState() => _WallColorPickerOverlayState();
}

class _WallColorPickerOverlayState extends State<WallColorPickerOverlay>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  final List<Color> _presetColors = [
    const Color(0xFFDEDCCE), // 默认暖沙
    const Color(0xFFF5F5DC), // 奶油白
    const Color(0xFFE0F2F1), // 淡薄荷
    const Color(0xFFF8BBD0), // 干枯玫瑰
    const Color(0xFFE3F2FD), // 雾霾蓝
    const Color(0xFFECEFF1), // 浅板岩
    const Color(0xFFF5F5F5), // 极地白
    const Color(0xFFD7CCC8), // 浅褐
    const Color(0xFFCFD8DC), // 蓝灰
    const Color(0xFFDCEDC8), // 浅草绿
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: Center(
        child: Container(
          width: 400,
          height: 220,
          decoration: BoxDecoration(
            color: const Color(0xFF2C2C26).withValues(alpha: 0.95),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: Colors.white10, width: 1),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.5),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            children: [
              const SizedBox(height: 12),
              // 标题与切换
              TabBar(
                controller: _tabController,
                dividerColor: Colors.transparent,
                indicatorColor: Colors.white70,
                indicatorSize: TabBarIndicatorSize.label,
                labelStyle: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                  letterSpacing: 1,
                ),
                tabs: const [
                  Tab(text: '左墙上色'),
                  Tab(text: '右墙上色'),
                ],
              ),

              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [_buildColorGrid(true), _buildColorGrid(false)],
                ),
              ),

              const Divider(color: Colors.white10, height: 1),

              Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: widget.onClose,
                      child: const Text(
                        '完成',
                        style: TextStyle(
                          color: Colors.white70,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildColorGrid(bool isLeft) {
    final currentColor = isLeft
        ? widget.controller.wallColorLeft
        : widget.controller.wallColorRight;

    return GridView.builder(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 5,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 1,
      ),
      itemCount: _presetColors.length,
      itemBuilder: (context, index) {
        final color = _presetColors[index];
        final bool isSelected = currentColor.value == color.value;

        return GestureDetector(
          onTap: () {
            widget.controller.setWallColor(isLeft, color);
            setState(() {});
          },
          child: Container(
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
              border: Border.all(
                color: isSelected ? Colors.white : Colors.transparent,
                width: 2.5,
              ),
              boxShadow: [
                if (isSelected)
                  BoxShadow(
                    color: color.withValues(alpha: 0.4),
                    blurRadius: 8,
                    spreadRadius: 1,
                  ),
              ],
            ),
            child: isSelected
                ? const Icon(Icons.check, color: Colors.black54, size: 16)
                : null,
          ),
        );
      },
    );
  }
}
