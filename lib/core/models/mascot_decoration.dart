import 'package:flutter/material.dart';

/// 单个装扮针对不同形象的个性化配置（偏移与缩放）
class MascotDecorationConfig {
  final Offset offset;
  final double scale;

  const MascotDecorationConfig({this.offset = Offset.zero, this.scale = 1.0});
}

enum MascotRarity {
  common('普通', Color(0xFF94A3B8)),
  rare('稀有', Color(0xFF38BDF8)),
  epic('卓越', Color(0xFFA855F7)),
  legendary('传说', Color(0xFFF59E0B));

  final String label;
  final Color color;
  const MascotRarity(this.label, this.color);
}

class MascotDecoration {
  final String id;
  final String name;
  final String path;
  final String description;
  final MascotRarity rarity;

  /// 默认的配置（如果未针对某个形象进行特殊配置，则使用此默认值）
  final MascotDecorationConfig defaultConfig;

  /// 针对不同形象（assetPath）的特定配置字典
  final Map<String, MascotDecorationConfig> characterConfigs;

  const MascotDecoration({
    required this.id,
    required this.name,
    required this.path,
    required this.description,
    this.rarity = MascotRarity.common,
    this.defaultConfig = const MascotDecorationConfig(),
    this.characterConfigs = const {},
  });

  /// 获取指定卡通形象对应的装扮配置
  MascotDecorationConfig getConfigForCharacter(String characterPath) {
    return characterConfigs[characterPath] ?? defaultConfig;
  }

  /// 全局饰品注册表
  static const List<MascotDecoration> allDecorations = [
    MascotDecoration(
      id: 'mask',
      name: '高达头盔',
      path: 'assets/images/emoji/decorate/decorate1.png',
      description: '机魂觉醒，星海远征。在金属的轰鸣中，守护最后一份纯净的梦想。',
      rarity: MascotRarity.legendary,
      defaultConfig: MascotDecorationConfig(offset: Offset(0, -6), scale: 1.1),
      characterConfigs: {
        'assets/images/emoji/pedding3.png': MascotDecorationConfig(
          offset: Offset(0, -6),
          scale: 1.1,
        ),
        'assets/images/emoji/marshmallow.png': MascotDecorationConfig(
          offset: Offset(0, -4),
          scale: 1.4,
        ), // 示例：雪团儿的微调
      },
    ),
    MascotDecoration(
      id: 'glasses',
      name: '粉色向阳花',
      path: 'assets/images/emoji/decorate/decorate2.png',
      description: '向着阳光而生，收藏每一寸粉色的温柔',
      defaultConfig: MascotDecorationConfig(offset: Offset(0, -20), scale: 1.2),
      characterConfigs: {
        'assets/images/emoji/pedding3.png': MascotDecorationConfig(
          offset: Offset(0, -20),
          scale: 1.2,
        ),
        'assets/images/emoji/marshmallow.png': MascotDecorationConfig(
          offset: Offset(0, -54),
          scale: 1.25,
        ),
      },
    ),
    MascotDecoration(
      id: 'flower',
      name: '蝴蝶盔（刀马旦）',
      path: 'assets/images/emoji/decorate/decorate3.png',
      description: '采下一朵最娇艳的记忆',
      rarity: MascotRarity.epic,
      defaultConfig: MascotDecorationConfig(offset: Offset(0, -28), scale: 1.8),
      characterConfigs: {
        'assets/images/emoji/pedding3.png': MascotDecorationConfig(
          offset: Offset(0, -28),
          scale: 1.8,
        ),
        'assets/images/emoji/marshmallow.png': MascotDecorationConfig(
          offset: Offset(0, -12),
          scale: 2,
        ),
      },
    ),
    MascotDecoration(
      id: 'reindeer',
      name: '麋鹿头饰',
      path: 'assets/images/emoji/decorate/decorate4.png',
      description: '戴上鹿角，奔向冬日的旷野',
      rarity: MascotRarity.rare,
      defaultConfig: MascotDecorationConfig(offset: Offset(0, -20), scale: 1.5),
      characterConfigs: {
        'assets/images/emoji/pedding3.png': MascotDecorationConfig(
          offset: Offset(0, -20),
          scale: 1.5,
        ),
        'assets/images/emoji/marshmallow.png': MascotDecorationConfig(
          offset: Offset(0, -22),
          scale: 1.65,
        ),
      },
    ),
    MascotDecoration(
      id: 'tiger',
      name: '虎头帽',
      path: 'assets/images/emoji/decorate/decorate5.png',
      description: '虎虎生威，勇往直前',
      rarity: MascotRarity.rare,
      defaultConfig: MascotDecorationConfig(offset: Offset(0, -12), scale: 1.2),
      characterConfigs: {
        'assets/images/emoji/pedding3.png': MascotDecorationConfig(
          offset: Offset(0, -12),
          scale: 1.2,
        ),
        'assets/images/emoji/marshmallow.png': MascotDecorationConfig(
          offset: Offset(0, -16),
          scale: 1.4,
        ),
      },
    ),
    MascotDecoration(
      id: 'egret',
      name: '白鹭帽',
      path: 'assets/images/emoji/decorate/decorate6.png',
      description: '云中白鹭，清雅悠然',
      rarity: MascotRarity.epic,
      defaultConfig: MascotDecorationConfig(offset: Offset(0, -40), scale: 1.0),
      characterConfigs: {
        'assets/images/emoji/pedding3.png': MascotDecorationConfig(
          offset: Offset(0, -40),
          scale: 1.0,
        ),
        'assets/images/emoji/marshmallow.png': MascotDecorationConfig(
          offset: Offset(0, -24),
          scale: 1.34,
        ),
      },
    ),
    MascotDecoration(
      id: 'snake_rabbit',
      name: '蛇年兔子帽',
      path: 'assets/images/emoji/decorate/decorate7.png',
      description: '蛇年新春，灵动可爱',
      rarity: MascotRarity.epic,
      defaultConfig: MascotDecorationConfig(offset: Offset(0, -6), scale: 2.2),
      characterConfigs: {
        'assets/images/emoji/pedding3.png': MascotDecorationConfig(
          offset: Offset(0, -6),
          scale: 2.2,
        ),
        'assets/images/emoji/marshmallow.png': MascotDecorationConfig(
          offset: Offset(0, 30),
          scale: 2.4,
        ),
      },
    ),
    MascotDecoration(
      id: 'six_six_six_hat',
      name: '666',
      path: 'assets/images/emoji/decorate/decorate8.png',
      description: '刷个666，好运常驻！这顶带有魔力的帽子能为你带来无限顺遂。',
      defaultConfig: MascotDecorationConfig(offset: Offset(0, -20), scale: 1.6),
      characterConfigs: {
        'assets/images/emoji/pedding3.png': MascotDecorationConfig(
          offset: Offset(0, -20),
          scale: 1.6,
        ),
        'assets/images/emoji/marshmallow.png': MascotDecorationConfig(
          offset: Offset(0, 4),
          scale: 1.34,
        ),
      },
    ),
    MascotDecoration(
      id: 'panda_hat',
      name: '熊猫帽',
      path: 'assets/images/emoji/decorate/decorate9.png',
      description: '国宝卖萌，憨态可掬',
      defaultConfig: MascotDecorationConfig(offset: Offset(0, -18), scale: 1.4),
      characterConfigs: {
        'assets/images/emoji/pedding3.png': MascotDecorationConfig(
          offset: Offset(0, -18),
          scale: 1.4,
        ),
        'assets/images/emoji/marshmallow.png': MascotDecorationConfig(
          offset: Offset(0, 10),
          scale: 1.2,
        ),
      },
    ),
    MascotDecoration(
      id: 'phoenix_crown',
      name: '如意凤冠',
      path: 'assets/images/emoji/decorate/decorate10.png',
      description: '吉祥如意，华贵非凡',
      rarity: MascotRarity.legendary,
      defaultConfig: MascotDecorationConfig(offset: Offset(0, -30), scale: 1.8),
      characterConfigs: {
        'assets/images/emoji/pedding3.png': MascotDecorationConfig(
          offset: Offset(0, -30),
          scale: 1.8,
        ),
        'assets/images/emoji/marshmallow.png': MascotDecorationConfig(
          offset: Offset(0, 10),
          scale: 1.4,
        ),
      },
    ),
    MascotDecoration(
      id: 'cowboy_hat',
      name: '牛仔帽',
      path: 'assets/images/emoji/decorate/decorate11.png',
      description: '荒野镖客，率性而行',
      rarity: MascotRarity.rare,
      defaultConfig: MascotDecorationConfig(offset: Offset(0, -15), scale: 1.4),
      characterConfigs: {
        'assets/images/emoji/pedding3.png': MascotDecorationConfig(
          offset: Offset(0, -15),
          scale: 1.4,
        ),
        'assets/images/emoji/marshmallow.png': MascotDecorationConfig(
          offset: Offset(0, 0),
          scale: 1.3,
        ),
      },
    ),
    MascotDecoration(
      id: 'red_reindeer',
      name: '红色鹿角',
      path: 'assets/images/emoji/decorate/decorate12.png',
      description: '红红火火，灵动可爱',
      defaultConfig: MascotDecorationConfig(offset: Offset(0, -22), scale: 1.5),
      characterConfigs: {
        'assets/images/emoji/pedding3.png': MascotDecorationConfig(
          offset: Offset(0, -22),
          scale: 1.5,
        ),
        'assets/images/emoji/marshmallow.png': MascotDecorationConfig(
          offset: Offset(0, -24),
          scale: 1.50,
        ),
      },
    ),
    MascotDecoration(
      id: 'sunflower_hat',
      name: '向日葵草帽',
      path: 'assets/images/emoji/decorate/decorate13.png',
      description: '采撷夏日阳光，满载向阳心意',
      defaultConfig: MascotDecorationConfig(offset: Offset(0, -12), scale: 1.6),
      characterConfigs: {
        'assets/images/emoji/pedding3.png': MascotDecorationConfig(
          offset: Offset(0, -12),
          scale: 1.6,
        ),
        'assets/images/emoji/marshmallow.png': MascotDecorationConfig(
          offset: Offset(0, -10),
          scale: 1.2,
        ),
      },
    ),
    MascotDecoration(
      id: 'lily_hat',
      name: '铃兰草帽',
      path: 'assets/images/emoji/decorate/decorate14.png',
      description: '铃兰花开，捎来清新的微风',
      rarity: MascotRarity.epic,
      defaultConfig: MascotDecorationConfig(offset: Offset(0, -12), scale: 1.6),
      characterConfigs: {
        'assets/images/emoji/pedding3.png': MascotDecorationConfig(
          offset: Offset(0, -12),
          scale: 1.6,
        ),
        'assets/images/emoji/marshmallow.png': MascotDecorationConfig(
          offset: Offset(0, -10),
          scale: 1.2,
        ),
      },
    ),
    MascotDecoration(
      id: 'funny_tails',
      name: '搞怪双马尾发带',
      path: 'assets/images/emoji/decorate/decorate15.png',
      description: '古灵精怪，可爱翻倍',
      rarity: MascotRarity.epic,
      defaultConfig: MascotDecorationConfig(offset: Offset(0, -10), scale: 1.4),
      characterConfigs: {
        'assets/images/emoji/pedding3.png': MascotDecorationConfig(
          offset: Offset(0, -10),
          scale: 1.4,
        ),
        'assets/images/emoji/marshmallow.png': MascotDecorationConfig(
          offset: Offset(0, -12),
          scale: 1.2,
        ),
      },
    ),
    MascotDecoration(
      id: 'butterfly_wreath',
      name: '幻彩蝶影花环',
      path: 'assets/images/emoji/decorate/decorate16.png',
      description: '蝶舞翩跹，织就梦幻花冠',
      rarity: MascotRarity.epic,
      defaultConfig: MascotDecorationConfig(offset: Offset(0, -20), scale: 1.8),
      characterConfigs: {
        'assets/images/emoji/pedding3.png': MascotDecorationConfig(
          offset: Offset(0, -20),
          scale: 1.8,
        ),
        'assets/images/emoji/marshmallow.png': MascotDecorationConfig(
          offset: Offset(0, -22),
          scale: 1.4,
        ),
      },
    ),
    MascotDecoration(
      id: 'knit_hat',
      name: '温暖针织帽',
      path: 'assets/images/emoji/decorate/decorate17.png',
      description: '冬日暖阳，织就一份贴心的温度',
      rarity: MascotRarity.rare,
      defaultConfig: MascotDecorationConfig(offset: Offset(0, -15), scale: 1.4),
      characterConfigs: {
        'assets/images/emoji/pedding3.png': MascotDecorationConfig(
          offset: Offset(0, -15),
          scale: 1.4,
        ),
        'assets/images/emoji/marshmallow.png': MascotDecorationConfig(
          offset: Offset(0, -50),
          scale: 1.3,
        ),
      },
    ),
    MascotDecoration(
      id: 'sheep_band',
      name: '小绵羊发带',
      path: 'assets/images/emoji/decorate/decorate18.png',
      description: '软绵绵的质感，治愈每一天',
      rarity: MascotRarity.rare,
      defaultConfig: MascotDecorationConfig(offset: Offset(0, -12), scale: 1.5),
      characterConfigs: {
        'assets/images/emoji/pedding3.png': MascotDecorationConfig(
          offset: Offset(0, -12),
          scale: 1.5,
        ),
        'assets/images/emoji/marshmallow.png': MascotDecorationConfig(
          offset: Offset(0, -8),
          scale: 1.1,
        ),
      },
    ),
    MascotDecoration(
      id: 'psyduck_hat_pink',
      name: '粉色可达鸭帽',
      path: 'assets/images/emoji/decorate/decorate21.png',
      description: '呆萌可爱，粉色心情',
      defaultConfig: MascotDecorationConfig(offset: Offset(0, -15), scale: 1.4),
      characterConfigs: {
        'assets/images/emoji/pedding3.png': MascotDecorationConfig(
          offset: Offset(0, -15),
          scale: 1.4,
        ),
        'assets/images/emoji/marshmallow.png': MascotDecorationConfig(
          offset: Offset(0, 10),
          scale: 1.12,
        ),
      },
    ),
    MascotDecoration(
      id: 'yellow_duck_hat',
      name: '可爱粉色发夹怪',
      path: 'assets/images/emoji/decorate/decorate22.png',
      description: '藏在发间的粉色小心思，捕捉每一份轻盈的快乐',
      rarity: MascotRarity.legendary,
      defaultConfig: MascotDecorationConfig(offset: Offset(0, 10), scale: 1.12),
      characterConfigs: {
        'assets/images/emoji/pedding3.png': MascotDecorationConfig(
          offset: Offset(0, 10),
          scale: 1.12,
        ),
        'assets/images/emoji/marshmallow.png': MascotDecorationConfig(
          offset: Offset(0, -54),
          scale: 1.94,
        ),
      },
    ),
    MascotDecoration(
      id: 'chen_yu',
      name: '沉鱼',
      path: 'assets/images/emoji/decorate/decorate23.png',
      description: '西子浣纱，美艳令游鱼也忘却游动而潜入水底',
      rarity: MascotRarity.legendary,
      defaultConfig: MascotDecorationConfig(offset: Offset(0, -20), scale: 1.5),
      characterConfigs: {
        'assets/images/emoji/pedding3.png': MascotDecorationConfig(
          offset: Offset(0, -20),
          scale: 1.5,
        ),
        'assets/images/emoji/marshmallow.png': MascotDecorationConfig(
          offset: Offset(0, -30),
          scale: 1.3,
        ),
      },
    ),
    MascotDecoration(
      id: 'luo_yan',
      name: '落雁',
      path: 'assets/images/emoji/decorate/decorate24.png',
      description: '昭君出塞，其惊世容颜令南飞的大雁也惊忘落翅，坠于平沙',
      rarity: MascotRarity.legendary,
      defaultConfig: MascotDecorationConfig(offset: Offset(0, -30), scale: 1.3),
      characterConfigs: {
        'assets/images/emoji/pedding3.png': MascotDecorationConfig(
          offset: Offset(0, -30),
          scale: 1.3,
        ),
        'assets/images/emoji/marshmallow.png': MascotDecorationConfig(
          offset: Offset(0, -20),
          scale: 1.3,
        ),
      },
    ),
    MascotDecoration(
      id: 'lucky_tiger',
      name: '好运虎头',
      path: 'assets/images/emoji/decorate/decorate25.png',
      description: '虎头虎脑，好运来到！传统虎头帽，守护你的每一天。',
      rarity: MascotRarity.legendary,
      defaultConfig: MascotDecorationConfig(offset: Offset(0, -10), scale: 1.3),
      characterConfigs: {
        'assets/images/emoji/pedding3.png': MascotDecorationConfig(
          offset: Offset(0, -10),
          scale: 1.3,
        ),
        'assets/images/emoji/marshmallow.png': MascotDecorationConfig(
          offset: Offset(0, -10),
          scale: 1.4,
        ),
      },
    ),
    MascotDecoration(
      id: 'sea_breeze_hat',
      name: '长耳海风帽',
      path: 'assets/images/emoji/decorate/decorate26.png',
      description: '长长的耳朵捕捉着海风的低语，带来清凉夏日的温柔气息',
      rarity: MascotRarity.epic,
      defaultConfig: MascotDecorationConfig(offset: Offset(0, -20), scale: 1.5),
      characterConfigs: {
        'assets/images/emoji/pedding3.png': MascotDecorationConfig(
          offset: Offset(0, 0),
          scale: 1.5,
        ),
        'assets/images/emoji/marshmallow.png': MascotDecorationConfig(
          offset: Offset(0, -25),
          scale: 1.2,
        ),
      },
    ),
    MascotDecoration(
      id: 'pink_long_tassel',
      name: '粉色长流苏',
      path: 'assets/images/emoji/decorate/decorate27.png',
      description: '桃夭灼灼，流苏摇曳。在轻盈的舞动中，捕捉春日最温柔的一抹悸动。',
      rarity: MascotRarity.legendary,
      defaultConfig: MascotDecorationConfig(offset: Offset(0, -10), scale: 1.4),
      characterConfigs: {
        'assets/images/emoji/pedding3.png': MascotDecorationConfig(
          offset: Offset(0, -10),
          scale: 1.4,
        ),
        'assets/images/emoji/marshmallow.png': MascotDecorationConfig(
          offset: Offset(0, 0),
          scale: 1.2,
        ),
      },
    ),
    MascotDecoration(
      id: 'red_long_tassel',
      name: '红色长流苏',
      path: 'assets/images/emoji/decorate/decorate28.png',
      description: '丹枫似火，瑞意呈祥。明艳的流苏如红豆般，寄托着最深沉的祈愿。',
      rarity: MascotRarity.legendary,
      defaultConfig: MascotDecorationConfig(offset: Offset(0, -10), scale: 1.4),
      characterConfigs: {
        'assets/images/emoji/pedding3.png': MascotDecorationConfig(
          offset: Offset(0, -10),
          scale: 1.4,
        ),
        'assets/images/emoji/marshmallow.png': MascotDecorationConfig(
          offset: Offset(0, 0),
          scale: 1.38,
        ),
      },
    ),
  ];

  /// 根据路径查找配置
  static MascotDecoration? getByPath(String? path) {
    if (path == null || path.isEmpty) return null;
    try {
      return allDecorations.firstWhere((d) => d.path == path);
    } catch (_) {
      return null;
    }
  }
}
