import 'package:flutter/material.dart';
import '../../controllers/decoration_controller.dart';
import 'furniture_inventory_tray.dart';
import '../../../domain/models/furniture_item.dart';

class DecorationOverlayUI extends StatelessWidget {
  final DecorationController controller;
  final bool isTrayExpanded;
  final VoidCallback onToggleTray;
  final VoidCallback onBack;
  final VoidCallback onClearAll;
  final Function(double) onZoom;

  const DecorationOverlayUI({
    super.key,
    required this.controller,
    required this.isTrayExpanded,
    required this.onToggleTray,
    required this.onBack,
    required this.onClearAll,
    required this.onZoom,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // 1. 底部物品库托盘 (Animated)
        AnimatedPositioned(
          duration: const Duration(milliseconds: 400),
          curve: Curves.fastOutSlowIn,
          top: 20,
          bottom: 20,
          right: isTrayExpanded ? 0 : -295,
          child: Row(
            children: [
              _buildTrayToggle(),
              FurnitureInventoryTray(
                availableItems: controller.availableItems,
                selectedCategory: controller.selectedCategory,
                selectedSubCategory: controller.selectedSubCategory,
                onCategoryChanged: controller.setCategory,
                onSubCategoryChanged: controller.setSubCategory,
                onDragStarted: (item) {
                  controller.draggingItem = item;
                  controller.draggingRotation = 0;
                  controller.ghostZ = 0.0;
                },
                onDragEnd: () => controller.cancelDragging(),
              ),
            ],
          ),
        ),

        // 2. 左上角基础控制按钮 (返回、网格开关、清除)
        Positioned(
          top: 40,
          left: 20,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
                    onPressed: onBack,
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    icon: Icon(controller.showGrid ? Icons.grid_on : Icons.grid_off, color: Colors.white70),
                    onPressed: controller.toggleGrid,
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete_sweep, color: Colors.redAccent, size: 24),
                    onPressed: onClearAll,
                    tooltip: '一键清除',
                  ),
                ],
              ),
              const SizedBox(height: 16),
              
              // 3. 垂直缩放栏
              Container(
                decoration: BoxDecoration(color: Colors.black26, borderRadius: BorderRadius.circular(12)),
                child: Column(
                  children: [
                    IconButton(
                      icon: Icon(Icons.add, color: controller.selectedFurniture != null ? Colors.white24 : Colors.white70), 
                      onPressed: controller.selectedFurniture != null ? null : () => onZoom(0.2), 
                      tooltip: '放大',
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Text(
                        '${(controller.currentScale * 100).toInt()}%',
                        style: TextStyle(
                          color: controller.selectedFurniture != null ? Colors.white24 : Colors.white70, 
                          fontSize: 10, 
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const Divider(color: Colors.white10, height: 1, indent: 8, endIndent: 8),
                    IconButton(
                      icon: Icon(Icons.remove, color: controller.selectedFurniture != null ? Colors.white24 : Colors.white70), 
                      onPressed: controller.selectedFurniture != null ? null : () => onZoom(-0.2), 
                      tooltip: '缩小',
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTrayToggle() {
    return GestureDetector(
      onTap: onToggleTray,
      child: Container(
        width: 32,
        height: 60,
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.7),
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(16),
            bottomLeft: Radius.circular(16),
          ),
          border: Border.all(color: Colors.white.withOpacity(0.1)),
        ),
        child: Icon(
          isTrayExpanded ? Icons.chevron_right : Icons.chevron_left,
          color: Colors.white70,
          size: 20,
        ),
      ),
    );
  }
}
