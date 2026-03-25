import '../domain/models/furniture_item.dart';
import 'furniture/kitchen.dart';
import 'furniture/bedroom.dart';
import 'furniture/living_room.dart';
import 'furniture/decoration.dart';
import 'furniture/floor.dart';
import 'furniture/wall.dart';

final List<FurnitureItem> defaultFurnitureItems = [
  ...floorItems,
  ...wallItems,
  ...kitchenItems,
  ...bedroomItems,
  ...livingRoomItems,
  ...decorationItems,
];
