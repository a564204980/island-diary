import 'package:flutter/material.dart';
import 'dart:ui' as ui;
import '../../../domain/models/furniture_item.dart';
import '../furniture_sprite.dart';

class FurnitureInventoryTray extends StatelessWidget {
  final List<FurnitureItem> availableItems;
  final String selectedCategory;
  final String? selectedSubCategory;
  final Function(String) onCategoryChanged;
  final Function(String?) onSubCategoryChanged;
  final Function(FurnitureItem) onDragStarted;
  final VoidCallback? onDragEnd;

  const FurnitureInventoryTray({
    super.key,
    required this.availableItems,
    required this.selectedCategory,
    this.selectedSubCategory,
    required this.onCategoryChanged,
    required this.onSubCategoryChanged,
    required this.onDragStarted,
    this.onDragEnd,
  });

  @override
  Widget build(BuildContext context) {
    final categories = availableItems.map((e) => e.category).toSet().toList();
    final subCategories = availableItems
        .where((e) => e.category == selectedCategory)
        .map((e) => e.subCategory)
        .toSet()
        .toList();

    final filteredItems = availableItems.where((item) {
      bool matchCat = item.category == selectedCategory;
      bool matchSub =
          selectedSubCategory == null ||
          item.subCategory == selectedSubCategory;
      return matchCat && matchSub;
    }).toList();

    return Container(
      width: 280,
      margin: const EdgeInsets.only(right: 12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.65),
        borderRadius: BorderRadius.circular(32),
        border: Border.all(color: const Color(0xFF5C8D89).withValues(alpha: 0.2)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 20,
            offset: const Offset(-5, 5),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(32),
        child: BackdropFilter(
          filter: ui.ImageFilter.blur(sigmaX: 12, sigmaY: 12),
          child: Row(
            children: [
              // 一级分类侧边栏
              _buildCategorySidebar(categories),
              // 右侧内容区
              Expanded(
                child: Column(
                  children: [
                    // 二级分类选择器
                    _buildSubCategorySelector(subCategories),
                    // 物品网格
                    Expanded(
                      child: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 300),
                        child: GridView.builder(
                          key: ValueKey(
                            "${selectedCategory}_$selectedSubCategory",
                          ),
                          padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
                          gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 2,
                                crossAxisSpacing: 12,
                                mainAxisSpacing: 16,
                                childAspectRatio: 0.75,
                              ),
                          itemCount: filteredItems.length,
                          itemBuilder: (context, index) {
                            return _buildFurnitureCard(
                              filteredItems[index],
                              index,
                            );
                          },
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

  Widget _buildCategorySidebar(List<String> categories) {
    return Container(
      width: 65,
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.03),
        border: Border(right: BorderSide(color: Colors.black.withValues(alpha: 0.05))),
      ),
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(vertical: 20),
        itemCount: categories.length,
        itemBuilder: (context, index) {
          final cat = categories[index];
          final isSelected = cat == selectedCategory;
          return GestureDetector(
            onTap: () => onCategoryChanged(cat),
            child: Container(
              height: 70,
              margin: const EdgeInsets.symmetric(vertical: 4),
              decoration: BoxDecoration(
                border: isSelected
                    ? const Border(
                        right: BorderSide(color: Color(0xFF5C8D89), width: 3),
                      )
                    : null,
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    _getCategoryIcon(cat),
                    color: isSelected ? const Color(0xFF5C8D89) : const Color(0xFF5C8D89).withValues(alpha: 0.3),
                    size: 24,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    cat,
                    style: TextStyle(
                      color: isSelected ? const Color(0xFF4A6F6C) : const Color(0xFF5C8D89).withValues(alpha: 0.4),
                      fontSize: 10,
                      fontWeight: isSelected
                          ? FontWeight.bold
                          : FontWeight.normal,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildSubCategorySelector(List<String> subCategories) {
    if (subCategories.length <= 1) return const SizedBox(height: 16);

    return Container(
      height: 50,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: subCategories.length + 1,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final isAll = index == 0;
          final subCat = isAll ? '全部' : subCategories[index - 1];
          final isSelected = isAll
              ? selectedSubCategory == null
              : subCat == selectedSubCategory;

          return Center(
            child: GestureDetector(
              onTap: () => onSubCategoryChanged(isAll ? null : subCat),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: isSelected
                      ? const Color(0xFF5C8D89).withValues(alpha: 0.1)
                      : Colors.black.withValues(alpha: 0.02),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isSelected
                        ? const Color(0xFF5C8D89).withValues(alpha: 0.3)
                        : Colors.black.withValues(alpha: 0.05),
                  ),
                ),
                child: Text(
                  subCat,
                  style: TextStyle(
                    fontSize: 11,
                    color: isSelected ? const Color(0xFF4A6F6C) : const Color(0xFF5C8D89).withValues(alpha: 0.5),
                    fontWeight: isSelected
                        ? FontWeight.bold
                        : FontWeight.normal,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildFurnitureCard(FurnitureItem item, int index) {
    final bool isOutOfStock = item.quantity <= 0;

    // 鎵嬮鐞撮樁姊紡杩涘満鍔ㄧ敾
    return TweenAnimationBuilder<double>(
      key: ValueKey("${item.id}_${selectedCategory}_$index"),
      tween: Tween<double>(begin: 0.0, end: 1.0),
      duration: Duration(milliseconds: 400 + (index * 40).clamp(0, 400)),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) {
        // 浣跨敤 Curves.easeOutBack 妯℃嫙鐗╃悊鍥炲脊锛屼骇鐢熸墜椋庣惔灞曞紑鐨勮川鎰?
        final double slideOffset =
            60 * (1.0 - Curves.easeOutBack.transform(value));
        return Transform.translate(
          offset: Offset(slideOffset, 0),
          child: Opacity(opacity: value.clamp(0.0, 1.0), child: child),
        );
      },
      child: LongPressDraggable<FurnitureItem>(
        delay: const Duration(milliseconds: 300),
        dragAnchorStrategy: pointerDragAnchorStrategy,
        onDragStarted: () => onDragStarted(item),
        onDragEnd: (_) => onDragEnd?.call(),
        onDragCompleted: () => onDragEnd?.call(),
        onDraggableCanceled: (_, __) => onDragEnd?.call(),
        data: item,
        maxSimultaneousDrags: isOutOfStock ? 0 : 1,
        feedback: const SizedBox.shrink(),
        childWhenDragging: Opacity(
          opacity: 0.3,
          child: _buildCardContent(item),
        ),
        child: Opacity(
          opacity: isOutOfStock ? 0.4 : 1.0,
          child: _buildCardContent(item),
        ),
      ),
    );
  }

  Widget _buildCardContent(FurnitureItem item) {
    return Column(
      children: [
        Stack(
          clipBehavior: Clip.none,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.black.withValues(alpha: 0.05)),
              ),
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: AspectRatio(
                    aspectRatio: item.intrinsicWidth / item.intrinsicHeight,
                    child: FurnitureSprite(item: item),
                  ),
                ),
              ),
            ),
            Positioned(
              top: -5,
              right: -5,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: item.quantity > 0 ? Colors.blueAccent : Colors.grey,
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: [
                    const BoxShadow(
                      color: Colors.black26,
                      blurRadius: 4,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                child: Text(
                  'x${item.quantity}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          item.name,
          style: const TextStyle(
            color: Color(0xFF4A6F6C),
            fontSize: 10,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  IconData _getCategoryIcon(String category) {
    switch (category) {
      case '地板':
        return Icons.grid_view_rounded;
      case '墙壁':
        return Icons.view_quilt_rounded;
      case '厨房':
        return Icons.kitchen;
      case '卧室':
        return Icons.bed;
      case '客厅':
        return Icons.chair;
      case '装饰':
        return Icons.palette;
      default:
        return Icons.category;
    }
  }
}
