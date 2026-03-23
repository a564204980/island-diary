import 'furniture.dart';

class FurnitureData {
  static List<FurnitureItem> get defaultItems => [
    FurnitureItem(
      id: 'bed',
      name: '温馨大床',
      imagePath: 'assets/images/decoration/furniture/bed.png',
      gridWidth: 4,
      gridHeight: 5,
      offsetX: -0.6,
      widthStretch: 1.24,
      heightStretch: 1.2,
    ),
    // 可以在这里添加更多家具...
  ];
}
