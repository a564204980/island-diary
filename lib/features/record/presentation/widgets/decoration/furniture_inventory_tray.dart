import 'package:flutter/material.dart';
import '../../../domain/models/furniture_item.dart';
import '../furniture_sprite.dart';


class FurnitureInventoryTray extends StatelessWidget {
  final List<FurnitureItem> availableItems;
  final String selectedCategory;
  final String? selectedSubCategory;
  final Function(String) onCategoryChanged;
  final Function(String?) onSubCategoryChanged;
  final Function(FurnitureItem) onDragStarted;
  final Function(FurnitureItem) onItemTap;
  final VoidCallback? onDragEnd;

  const FurnitureInventoryTray({
    super.key,
    required this.availableItems,
    required this.selectedCategory,
    this.selectedSubCategory,
    required this.onCategoryChanged,
    required this.onSubCategoryChanged,
    required this.onDragStarted,
    required this.onItemTap,
    this.onDragEnd,
  });

  static const Map<String, int> _categoryOrder = {
    '家具': 1,
    '墙饰': 2,
    '摆件': 3,
    '地饰': 4,
    '花盆': 5,
    '室外': 6,
    '硬装': 7,
  };

  @override
  Widget build(BuildContext context) {
    final categories = availableItems.map((e) => e.category).toSet().toList().cast<String>();
    categories.sort((a, b) {
      final orderA = _categoryOrder[a] ?? 999;
      final orderB = _categoryOrder[b] ?? 999;
      return orderA.compareTo(orderB);
    });

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
      width: 320,
      margin: const EdgeInsets.only(right: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFFEF9EB), // 暖米黄色背景
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(40),
          bottomLeft: Radius.circular(40),
        ),
        border: Border.all(
          color: const Color(0xFFE8D4B4), // 褐色边框
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 25,
            offset: const Offset(-8, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          // 1. 一级分类侧边栏 (参考图 1 布局)
          _buildCategorySidebar(categories),

          // 2. 右侧内容区
          Expanded(
            child: Column(
              children: [
                const SizedBox(height: 12),
                // 二级分类选择器 (Pill 样式)
                _buildSubCategorySelector(subCategories),
                const SizedBox(height: 8),
                // 物品网格
                Expanded(
                  child: GridView.builder(
                    key: ValueKey("${selectedCategory}_$selectedSubCategory"),
                    padding: const EdgeInsets.fromLTRB(12, 0, 12, 20),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          crossAxisSpacing: 10,
                          mainAxisSpacing: 12,
                          childAspectRatio: 0.78,
                        ),
                    itemCount: filteredItems.length,
                    itemBuilder: (context, index) {
                      return _buildFurnitureCard(filteredItems[index], index);
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategorySidebar(List<String> categories) {
    return Container(
      width: 75,
      padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: const BoxDecoration(
        border: Border(right: BorderSide(color: Color(0xFFE8D4B4), width: 1)),
      ),
      child: ListView.builder(
        itemCount: categories.length,
        itemBuilder: (context, index) {
          final cat = categories[index];
          final isSelected = cat == selectedCategory;
          return _buildSidebarButton(
            _getCategoryIcon(cat),
            cat,
            isSelected,
            () => onCategoryChanged(cat),
          );
        },
      ),
    );
  }

  Widget _buildSidebarButton(
    IconData icon,
    String label,
    bool isSelected,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        height: 65,
        margin: const EdgeInsets.fromLTRB(8, 4, 8, 4),
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(0xFF8B5E3C)
              : const Color(0xFFF9F3DF), // 选中时为深褐，未选中时为浅黄
          borderRadius: BorderRadius.circular(18),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: const Color(0xFF8B5E3C).withValues(alpha: 0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ]
              : null,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: isSelected ? Colors.white : const Color(0xFF8B5E3C),
              size: 22,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.white : const Color(0xFF8B5E3C),
                fontSize: 10,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSubCategorySelector(List<String> subCategories) {
    final allSubCats = ['全部', ...subCategories];
    return SizedBox(
      height: 40,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 8),
        itemCount: allSubCats.length,
        itemBuilder: (context, index) {
          final subCat = allSubCats[index];
          final isSelected =
              (index == 0 && selectedSubCategory == null) ||
              (subCat == selectedSubCategory);

          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: ActionChip(
              label: Text(subCat),
              onPressed: () => onSubCategoryChanged(index == 0 ? null : subCat),
              backgroundColor: isSelected
                  ? const Color(0xFFD4A373)
                  : const Color(0xFFF9F3DF),
              labelStyle: TextStyle(
                color: isSelected ? Colors.white : const Color(0xFF8B5E3C),
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
              side: BorderSide(
                color: isSelected
                    ? const Color(0xFFD4A373)
                    : const Color(0xFFE8D4B4),
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 4),
            ),
          );
        },
      ),
    );
  }

  Widget _buildFurnitureCard(FurnitureItem item, int index) {
    return _FurnitureCard(
      item: item,
      onTap: () => onItemTap(item),
      onDragStarted: () => onDragStarted(item),
      onDragEnd: onDragEnd,
    );
  }

  IconData _getCategoryIcon(String category) {
    switch (category) {
      case '家具':
        return Icons.chair_rounded;
      case '墙饰':
        return Icons.wallpaper_rounded;
      case '摆件':
        return Icons.auto_awesome_rounded;
      case '地饰':
        return Icons.layers_rounded;
      case '花盆':
        return Icons.local_florist_rounded;
      case '室外':
        return Icons.deck_rounded;
      case '硬装':
        return Icons.construction_rounded;
      default:
        return Icons.category;
    }
  }
}

class _FurnitureCard extends StatefulWidget {
  final FurnitureItem item;
  final VoidCallback onTap;
  final VoidCallback onDragStarted;
  final VoidCallback? onDragEnd;

  const _FurnitureCard({
    required this.item,
    required this.onTap,
    required this.onDragStarted,
    this.onDragEnd,
  });

  @override
  State<_FurnitureCard> createState() => _FurnitureCardState();
}

class _FurnitureCardState extends State<_FurnitureCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 150),
    );
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.92,
    ).animate(CurveTween(curve: Curves.easeInOut).animate(_controller));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bool isOutOfStock = widget.item.quantity <= 0;

    return LongPressDraggable<FurnitureItem>(
      delay: const Duration(milliseconds: 300),
      data: widget.item,
      maxSimultaneousDrags: isOutOfStock ? 0 : 1,
      dragAnchorStrategy: pointerDragAnchorStrategy,
      feedback: const SizedBox.shrink(),
      onDragStarted: () {
        _controller.forward();
        widget.onDragStarted();
      },
      onDragEnd: (details) {
        _controller.reverse();
        widget.onDragEnd?.call();
      },
      child: GestureDetector(
        onTapDown: (_) => _controller.forward(),
        onTapUp: (_) => _controller.reverse(),
        onTapCancel: () => _controller.reverse(),
        onTap: widget.onTap,
        child: ScaleTransition(
          scale: _scaleAnimation,
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.8),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: const Color(0xFFE8D4B4).withValues(alpha: 0.8),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              children: [
                Expanded(
                  child: Stack(
                    children: [
                      Center(
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: AspectRatio(
                            aspectRatio:
                                widget.item.intrinsicWidth /
                                widget.item.intrinsicHeight,
                            child: FurnitureSprite(item: widget.item),
                          ),
                        ),
                      ),
                      // 可染色/改制角标 (左上角)
                      if (widget.item.canBeDyed)
                        Positioned(
                          top: 0,
                          left: 0,
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: const BoxDecoration(
                              color: Color(0xFFA78BFA), // 紫色背景，参考图1
                              borderRadius: BorderRadius.only(
                                topLeft: Radius.circular(18), // 配合外层圆角
                                bottomRight: Radius.circular(14),
                              ),
                            ),
                            child: const Icon(
                              Icons.brush_rounded, // 滚筒刷/刷子图标
                              color: Colors.white,
                              size: 14,
                            ),
                          ),
                        ),
                      // 数量角标 (右上角)
                      Positioned(
                        top: 8,
                        right: 8,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(
                              0xFFD4A373,
                            ).withValues(alpha: 0.8), // 稍微透明一点更高级
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            'x${widget.item.quantity}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 9,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Text(
                    widget.item.name,
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Color(0xFF8B5E3C),
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
