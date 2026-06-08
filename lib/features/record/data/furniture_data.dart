import '../domain/models/furniture_item.dart';
import 'furniture/kitchen.dart';
import 'furniture/bedroom.dart';
import 'furniture/living_room.dart';
import 'furniture/decoration.dart';
import 'furniture/floor.dart';
import 'furniture/wall.dart';

final List<FurnitureItem> defaultFurnitureItems = () {
  final list = [
    ...floorItems,
    ...wallItems,
    ...kitchenItems,
    ...bedroomItems,
    ...livingRoomItems,
    ...decorationItems,
  ];

  FurnitureItem.itemMigrator = (item) {
    for (final e in list) {
      if (e.id == item.id) {
        item.imagePath = e.imagePath;
        item.category = e.category;
        item.subCategory = e.subCategory;

        for (var i = 0; i < item.colorVariants.length; i++) {
          final v = item.colorVariants[i];
          for (final ev in e.colorVariants) {
            if (ev.id == v.id) {
              item.colorVariants[i] = FurnitureColorVariant(
                id: v.id,
                name: v.name,
                imagePath: ev.imagePath,
                colorValue: v.colorValue,
                dyeCost: v.dyeCost,
                goldCost: v.goldCost,
              );
              break;
            }
          }
        }
        break;
      }
    }
  };

  return list;
}();
