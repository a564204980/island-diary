import '../../domain/models/furniture_item.dart';
import '../furniture_data.dart';

class FurnitureDbService {
  static List<FurnitureItem> getAllItems() {
    return defaultFurnitureItems.map((item) {
      final mapped = FurnitureItem.fromMap(item.toMap());
      _remapItem(mapped);
      return mapped;
    }).toList();
  }

  static void _remapItem(FurnitureItem item) {
    // Categories and subcategories are now statically defined in the data files.
  }
}
