import 'package:flutter/material.dart';
import '../../domain/models/furniture.dart';

class FurniturePanel extends StatelessWidget {
  final List<FurnitureItem> availableItems;
  final List<FurnitureInstance> placedFurniture;
  final Function(FurnitureItem) onToggleItem;

  const FurniturePanel({
    super.key,
    required this.availableItems,
    required this.placedFurniture,
    required this.onToggleItem,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: 0,
      right: 0,
      bottom: 0,
      width: 200,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.black.withAlpha(180),
          boxShadow: [
            BoxShadow(color: Colors.black26, blurRadius: 10, offset: const Offset(-5, 0)),
          ],
        ),
        child: Column(
          children: [
            const SizedBox(height: 80),
            const Text(
              '家具库',
              style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: availableItems.length,
                itemBuilder: (context, index) {
                  final item = availableItems[index];
                  // 检查是否已经放置在场景中
                  final bool isPlaced = placedFurniture.any((e) => e.item.id == item.id);
                  
                  return GestureDetector(
                    onTap: () => onToggleItem(item),
                    child: Opacity(
                      opacity: isPlaced ? 0.6 : 1.0,
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 16),
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: isPlaced ? Colors.cyanAccent.withOpacity(0.1) : Colors.white10,
                          borderRadius: BorderRadius.circular(12),
                          border: isPlaced ? Border.all(color: Colors.cyanAccent.withOpacity(0.5), width: 1) : null,
                        ),
                        child: Column(
                          children: [
                            if (item.image != null)
                              RawImage(image: item.image, height: 60, fit: BoxFit.contain)
                            else
                              const SizedBox(height: 60, child: Center(child: CircularProgressIndicator())),
                            const SizedBox(height: 8),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(item.name, style: const TextStyle(color: Colors.white, fontSize: 12)),
                                if (isPlaced) ...[
                                  const SizedBox(width: 4),
                                  const Icon(Icons.check_circle_rounded, color: Colors.cyanAccent, size: 14),
                                ],
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
