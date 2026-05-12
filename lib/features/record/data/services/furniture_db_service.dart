import '../../domain/models/furniture_item.dart';
import '../furniture_data.dart';

class FurnitureDbService {
  static List<FurnitureItem> getAllItems() {
    return defaultFurnitureItems
        .map((item) => FurnitureItem.fromMap(item.toMap()))
        .toList();
  }
}
