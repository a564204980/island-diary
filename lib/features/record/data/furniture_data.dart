import '../domain/models/furniture_item.dart';
import 'furniture/kitchen.dart';
import 'furniture/bedroom.dart';
import 'furniture/living_room.dart';
import 'furniture/decoration.dart';

final List<FurnitureItem> defaultFurnitureItems = [
  ...kitchenItems,
  ...bedroomItems,
  ...livingRoomItems,
  ...decorationItems,
];
