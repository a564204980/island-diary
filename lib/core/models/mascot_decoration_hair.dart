part of 'mascot_decoration.dart';

/// 发型及发饰资产数据
const List<MascotDecoration> _hairDecorations = [
  MascotDecoration(
    id: 'moon_glory_silver_crown',
    name: '月华银冠发型',
    path: 'assets/images/emoji/hairstyle/hairstyle1.png',
    description: '银发轻挽成华丽月冠，宝石与珍珠在发间微光流转，像被月光亲吻过的公主发型。',
    rarity: MascotRarity.epic,
    category: MascotDecorationCategory.hair,
    defaultConfig: MascotDecorationConfig(offset: Offset(0, 0), scale: 1.0),
    characterConfigs: {
      'assets/images/emoji/marshmallow.png': MascotDecorationConfig(
        offset: Offset(0, -10),
        scale: 1.24,
      ),
      'assets/images/emoji/marshmallow2.png': MascotDecorationConfig(
        offset: Offset(0, 0),
        scale: 1.24,
      ),
      'assets/images/emoji/marshmallow3.png': MascotDecorationConfig(
        offset: Offset(0, 0),
        scale: 1.24,
      ),
      'assets/images/emoji/marshmallow4.png': MascotDecorationConfig(
        offset: Offset(0, 0),
        scale: 1.24,
      ),
    },
  ),
  MascotDecoration(
    id: 'rose_crown_pink_gold_hair',
    name: '蔷薇华冠发型',
    path: 'assets/images/emoji/hairstyle/hairstyle2.png',
    description: '粉金色发丝上点缀着精美的蔷薇珍珠华冠，粉色宝石微光流转，温柔而华丽。',
    rarity: MascotRarity.rare, // 默认使用卓越或普通，您可以根据需要调整
    category: MascotDecorationCategory.hair,
    defaultConfig: MascotDecorationConfig(offset: Offset(0, 0), scale: 1.0),
    characterConfigs: {
      'assets/images/emoji/marshmallow.png': MascotDecorationConfig(
        offset: Offset(0, 0),
        scale: 1.1,
      ),
      'assets/images/emoji/marshmallow2.png': MascotDecorationConfig(
        offset: Offset(0, 0),
        scale: 1.1,
      ),
      'assets/images/emoji/marshmallow3.png': MascotDecorationConfig(
        offset: Offset(0, 0),
        scale: 1.1,
      ),
      'assets/images/emoji/marshmallow4.png': MascotDecorationConfig(
        offset: Offset(0, 0),
        scale: 1.1,
      ),
    },
  ),
  MascotDecoration(
    id: 'dream_crown_pink_crystal_hair',
    name: '樱月冠发',
    path: 'assets/images/emoji/hairstyle/hairstyle3.png',
    description: '细金发冠点缀珍珠与粉色宝石，右侧垂落小花流苏，整体温柔、优雅，带一点公主感。',
    rarity: MascotRarity.epic,
    category: MascotDecorationCategory.hair,
    defaultConfig: MascotDecorationConfig(offset: Offset(0, 0), scale: 1.0),
    characterConfigs: {
      'assets/images/emoji/marshmallow.png': MascotDecorationConfig(
        offset: Offset(0, -10),
        scale: 1.2,
      ),
      'assets/images/emoji/marshmallow2.png': MascotDecorationConfig(
        offset: Offset(0, -10),
        scale: 1.2,
      ),
      'assets/images/emoji/marshmallow3.png': MascotDecorationConfig(
        offset: Offset(0, -10),
        scale: 1.2,
      ),
      'assets/images/emoji/marshmallow4.png': MascotDecorationConfig(
        offset: Offset(0, -10),
        scale: 1.2,
      ),
    },
  ),
  MascotDecoration(
    id: 'luna_flower_crown_hair',
    name: '月璃花冠发型',
    path: 'assets/images/emoji/hairstyle/hairstyle4.png',
    description: '银紫卷发点缀水晶与珍珠，像月光里的小公主发冠，梦幻又高贵。',
    rarity: MascotRarity.epic,
    category: MascotDecorationCategory.hair,
    defaultConfig: MascotDecorationConfig(offset: Offset(0, 0), scale: 1.0),
    characterConfigs: {
      'assets/images/emoji/marshmallow.png': MascotDecorationConfig(
        offset: Offset(0, -10),
        scale: 1.16,
      ),
      'assets/images/emoji/marshmallow2.png': MascotDecorationConfig(
        offset: Offset(0, -10),
        scale: 1.16,
      ),
      'assets/images/emoji/marshmallow3.png': MascotDecorationConfig(
        offset: Offset(0, -10),
        scale: 1.16,
      ),
      'assets/images/emoji/marshmallow4.png': MascotDecorationConfig(
        offset: Offset(0, -10),
        scale: 1.16,
      ),
    },
  ),
  MascotDecoration(
    id: 'peach_cloud_bun_hair',
    name: '甜桃云团发型',
    path: 'assets/images/emoji/hairstyle/hairstyle5.png',
    description: '粉桃色双团发点缀蝴蝶结和糖果小饰，软萌甜美，像一朵藏着少女心的小云团。',
    rarity: MascotRarity.rare,
    category: MascotDecorationCategory.hair,
    defaultConfig: MascotDecorationConfig(offset: Offset(0, 0), scale: 1.0),
    characterConfigs: {
      'assets/images/emoji/marshmallow.png': MascotDecorationConfig(
        offset: Offset(0, -10),
        scale: 1.0,
      ),
      'assets/images/emoji/marshmallow2.png': MascotDecorationConfig(
        offset: Offset(0, -10),
        scale: 1.0,
      ),
      'assets/images/emoji/marshmallow3.png': MascotDecorationConfig(
        offset: Offset(0, -10),
        scale: 1.0,
      ),
      'assets/images/emoji/marshmallow4.png': MascotDecorationConfig(
        offset: Offset(0, -10),
        scale: 1.0,
      ),
    },
  ),
  MascotDecoration(
    id: 'star_veil_braid_hair',
    name: '星纱编卷发型',
    path: 'assets/images/emoji/hairstyle/hairstyle6.png',
    description: '粉紫渐变的蓬松短卷发，搭配星星发夹与珍珠编发，甜美又带一点梦幻感。',
    rarity: MascotRarity.rare,
    category: MascotDecorationCategory.hair,
    defaultConfig: MascotDecorationConfig(offset: Offset(0, 0), scale: 1.0),
    characterConfigs: {
      'assets/images/emoji/marshmallow.png': MascotDecorationConfig(
        offset: Offset(0, 4),
        scale: 1.1,
      ),
      'assets/images/emoji/marshmallow2.png': MascotDecorationConfig(
        offset: Offset(0, 4),
        scale: 1.1,
      ),
      'assets/images/emoji/marshmallow3.png': MascotDecorationConfig(
        offset: Offset(0, 4),
        scale: 1.1,
      ),
      'assets/images/emoji/marshmallow4.png': MascotDecorationConfig(
        offset: Offset(0, 4),
        scale: 1.1,
      ),
    },
  ),
  MascotDecoration(
    id: 'star_sugar_double_bun_hair',
    name: '星糖双丸卷发型',
    path: 'assets/images/emoji/hairstyle/hairstyle7.png',
    description: '浅金到薄荷紫的渐变双丸卷发，点缀星星、珍珠和蝴蝶结，整体甜美梦幻。',
    rarity: MascotRarity.legendary,
    category: MascotDecorationCategory.hair,
    defaultConfig: MascotDecorationConfig(offset: Offset(0, 0), scale: 1.0),
    characterConfigs: {
      'assets/images/emoji/marshmallow.png': MascotDecorationConfig(
        offset: Offset(0, 0),
        scale: 1.1,
      ),
      'assets/images/emoji/marshmallow2.png': MascotDecorationConfig(
        offset: Offset(0, 0),
        scale: 1.1,
      ),
      'assets/images/emoji/marshmallow3.png': MascotDecorationConfig(
        offset: Offset(0, 0),
        scale: 1.1,
      ),
      'assets/images/emoji/marshmallow4.png': MascotDecorationConfig(
        offset: Offset(0, 0),
        scale: 1.1,
      ),
    },
  ),
  MascotDecoration(
    id: 'purple_cloud_bun_hair',
    name: '紫云小绾发型',
    path: 'assets/images/emoji/hairstyle/hairstyle9.png',
    description: '淡紫卷发轻轻束起，像一朵软软的小云花，温柔又俏皮。',
    rarity: MascotRarity.common,
    category: MascotDecorationCategory.hair,
    defaultConfig: MascotDecorationConfig(offset: Offset(0, 0), scale: 1.0),
    characterConfigs: {
      'assets/images/emoji/marshmallow.png': MascotDecorationConfig(
        offset: Offset(0, 0),
        scale: 1.1,
      ),
      'assets/images/emoji/marshmallow2.png': MascotDecorationConfig(
        offset: Offset(0, 0),
        scale: 1.1,
      ),
      'assets/images/emoji/marshmallow3.png': MascotDecorationConfig(
        offset: Offset(0, 0),
        scale: 1.1,
      ),
      'assets/images/emoji/marshmallow4.png': MascotDecorationConfig(
        offset: Offset(0, 0),
        scale: 1.1,
      ),
    },
  ),
  MascotDecoration(
    id: 'sakura_pink_short_curly_hair',
    name: '樱粉短卷',
    path: 'assets/images/emoji/hairstyle/hairstyle10.png',
    description: '樱粉色空气感短卷发，层次蓬松、发尾微翘，甜软又灵动',
    rarity: MascotRarity.rare,
    category: MascotDecorationCategory.hair,
    defaultConfig: MascotDecorationConfig(offset: Offset(0, 0), scale: 1.0),
    characterConfigs: {
      'assets/images/emoji/marshmallow.png': MascotDecorationConfig(
        offset: Offset(0, -10),
        scale: 1.1,
      ),
      'assets/images/emoji/marshmallow2.png': MascotDecorationConfig(
        offset: Offset(0, -10),
        scale: 1.1,
      ),
      'assets/images/emoji/marshmallow3.png': MascotDecorationConfig(
        offset: Offset(0, -10),
        scale: 1.1,
      ),
      'assets/images/emoji/marshmallow4.png': MascotDecorationConfig(
        offset: Offset(0, -10),
        scale: 1.1,
      ),
    },
  ),
  MascotDecoration(
    id: 'light_tide_star_curly_hair',
    name: '浅汐星卷发型',
    path: 'assets/images/emoji/hairstyle/hairstyle11.png',
    description: '像把海边的薄荷汽水和桃子云朵揉进了头发里，走路时发尾轻轻一晃，连小星星都像在偷偷眨眼',
    rarity: MascotRarity.legendary,
    category: MascotDecorationCategory.hair,
    defaultConfig: MascotDecorationConfig(offset: Offset(0, 0), scale: 1.0),
    characterConfigs: {
      'assets/images/emoji/marshmallow.png': MascotDecorationConfig(
        offset: Offset(0, 14),
        scale: 1.1,
      ),
      'assets/images/emoji/marshmallow2.png': MascotDecorationConfig(
        offset: Offset(0, 14),
        scale: 1.1,
      ),
      'assets/images/emoji/marshmallow3.png': MascotDecorationConfig(
        offset: Offset(0, 14),
        scale: 1.1,
      ),
      'assets/images/emoji/marshmallow4.png': MascotDecorationConfig(
        offset: Offset(0, 14),
        scale: 1.1,
      ),
    },
  ),

  MascotDecoration(
    id: 'peach_flowing_clouds_hair',
    name: '蜜桃流云长发',
    path: 'assets/images/emoji/hairstyle/hairstyle13.png',
    description: '柔软的蜜桃粉渐变长卷发，发尾像云朵一样轻轻散开，整体甜美温柔，又带一点梦幻感',
    rarity: MascotRarity.common,
    category: MascotDecorationCategory.hair,
    defaultConfig: MascotDecorationConfig(offset: Offset(0, 0), scale: 1.0),
    characterConfigs: {
      'assets/images/emoji/marshmallow.png': MascotDecorationConfig(
        offset: Offset(0, 48),
        scale: 1.30,
      ),
      'assets/images/emoji/marshmallow2.png': MascotDecorationConfig(
        offset: Offset(0, 48),
        scale: 1.30,
      ),
      'assets/images/emoji/marshmallow3.png': MascotDecorationConfig(
        offset: Offset(0, 48),
        scale: 1.30,
      ),
      'assets/images/emoji/marshmallow4.png': MascotDecorationConfig(
        offset: Offset(0, 48),
        scale: 1.30,
      ),
    },
  ),
];
