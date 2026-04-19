part of 'mascot_decoration.dart';

/// 杂项装扮数据 (面饰、其他)
const List<MascotDecoration> _otherDecorations = [
    MascotDecoration(
      id: 'sausage_lips',
      name: '玫红香肠嘴',
      path: 'assets/images/emoji/decorate/decorate29.png',
      description: '火热的玫红，性感的轮廓，这是岛上最吸睛的时尚焦点。',
      rarity: MascotRarity.rare,
      category: MascotDecorationCategory.face,
      defaultConfig: MascotDecorationConfig(offset: Offset(0, 30), scale: 0.8),
      characterConfigs: {
        'assets/images/emoji/marshmallow.png': MascotDecorationConfig(
          offset: Offset(0, -50),
          scale: 1,
        ),
        'assets/images/emoji/marshmallow2.png': MascotDecorationConfig(
          offset: Offset(0, -50),
          scale: 1,
        ),
        'assets/images/emoji/marshmallow3.png': MascotDecorationConfig(
          offset: Offset(0, -50),
          scale: 1,
        ),
        'assets/images/emoji/marshmallow4.png': MascotDecorationConfig(
          offset: Offset(0, -50),
          scale: 1,
        ),
      },
    ),
];
