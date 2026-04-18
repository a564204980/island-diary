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
        color: Colors.black.withValues(alpha: 0.85),
        borderRadius: BorderRadius.circular(32),
        border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.4),
            blurRadius: 20,
            offset: const Offset(-10, 0),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(32),
        child: Row(
          children: [
            // 涓€绾у垎绫讳晶杈规爮
            _buildCategorySidebar(categories),
            // 鍙充晶鍐呭鍖?
            Expanded(
              child: Column(
                children: [
                  // 浜岀骇鍒嗙被閫夋嫨鍣?
                  _buildSubCategorySelector(subCategories),
                  // 鐗╁搧缃戞牸
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
    );
  }

  Widget _buildCategorySidebar(List<String> categories) {
    return Container(
      width: 65,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.03),
        border: const Border(right: BorderSide(color: Colors.white10)),
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
                        right: BorderSide(color: Colors.blueAccent, width: 3),
                      )
                    : null,
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    _getCategoryIcon(cat),
                    color: isSelected ? Colors.blueAccent : Colors.white24,
                    size: 24,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    cat,
                    style: TextStyle(
                      color: isSelected ? Colors.white : Colors.white30,
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
          final subCat = isAll ? '鍏ㄩ儴' : subCategories[index - 1];
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
                      ? Colors.blueAccent.withValues(alpha: 0.15)
                      : Colors.white.withValues(alpha: 0.03),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isSelected
                        ? Colors.blueAccent.withValues(alpha: 0.4)
                        : Colors.white.withValues(alpha: 0.08),
                  ),
                ),
                child: Text(
                  subCat,
                  style: TextStyle(
                    fontSize: 11,
                    color: isSelected ? Colors.white : Colors.white38,
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
                color: Colors.white.withValues(alpha: 0.04),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
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
            color: Colors.white70,
            fontSize: 10,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  IconData _getCategoryIcon(String category) {
    switch (category) {
      case '鍦版澘':
        return Icons.grid_view_rounded;
      case '澧欏':
        return Icons.view_quilt_rounded;
      case '鍘ㄦ埧':
        return Icons.kitchen;
      case '鍗у':
        return Icons.bed;
      case '瀹㈠巺':
        return Icons.chair;
      case '瑁呴グ':
        return Icons.palette;
      default:
        return Icons.category;
    }
  }
}
