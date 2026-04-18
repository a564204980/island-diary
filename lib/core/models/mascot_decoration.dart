import 'package:flutter/material.dart';

/// 单个装扮针对不同形象的个性化配置
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

  /// 默认的配置
  final MascotDecorationConfig defaultConfig;

  /// 针对不同形象的特定配置字典
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
        'assets/images/emoji/marshmallow.png': MascotDecorationConfig(
          offset: Offset(0, -14),
          scale: 1,
        ),
        'assets/images/emoji/marshmallow2.png': MascotDecorationConfig(
          offset: Offset(0, -14),
          scale: 1,
        ),
        'assets/images/emoji/marshmallow3.png': MascotDecorationConfig(
          offset: Offset(0, -14),
          scale: 1,
        ),
        'assets/images/emoji/marshmallow4.png': MascotDecorationConfig(
          offset: Offset(0, -14),
          scale: 1,
        ),
        'assets/images/emoji/marshmallow5.png': MascotDecorationConfig(
          offset: Offset(0, -14),
          scale: 1,
        ),
      },
    ),
    MascotDecoration(
      id: 'glasses',
      name: '粉色向阳花',
      path: 'assets/images/emoji/decorate/decorate2.png',
      description: '向着阳光而生，收藏每一寸粉色的温柔',
      defaultConfig: MascotDecorationConfig(offset: Offset(0, -20), scale: 1.2),
      characterConfigs: {
        'assets/images/emoji/marshmallow.png': MascotDecorationConfig(
          offset: Offset(0, -74),
          scale: 0.8,
        ),
        'assets/images/emoji/marshmallow2.png': MascotDecorationConfig(
          offset: Offset(0, -74),
          scale: 0.8,
        ),
        'assets/images/emoji/marshmallow3.png': MascotDecorationConfig(
          offset: Offset(0, -74),
          scale: 0.8,
        ),
        'assets/images/emoji/marshmallow4.png': MascotDecorationConfig(
          offset: Offset(0, -74),
          scale: 0.8,
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
        'assets/images/emoji/marshmallow.png': MascotDecorationConfig(
          offset: Offset(0, 10),
          scale: 1.5,
        ),
        'assets/images/emoji/marshmallow2.png': MascotDecorationConfig(
          offset: Offset(0, 10),
          scale: 1.5,
        ),
        'assets/images/emoji/marshmallow3.png': MascotDecorationConfig(
          offset: Offset(0, 10),
          scale: 1.5,
        ),
        'assets/images/emoji/marshmallow4.png': MascotDecorationConfig(
          offset: Offset(0, 10),
          scale: 1.5,
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
        'assets/images/emoji/marshmallow.png': MascotDecorationConfig(
          offset: Offset(5, -62),
          scale: 1.34,
        ),
        'assets/images/emoji/marshmallow2.png': MascotDecorationConfig(
          offset: Offset(5, -62),
          scale: 1.34,
        ),
        'assets/images/emoji/marshmallow3.png': MascotDecorationConfig(
          offset: Offset(5, -62),
          scale: 1.34,
        ),
        'assets/images/emoji/marshmallow4.png': MascotDecorationConfig(
          offset: Offset(5, -70),
          scale: 1.32,
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
        'assets/images/emoji/marshmallow.png': MascotDecorationConfig(
          offset: Offset(0, -46),
          scale: 0.9,
        ),
        'assets/images/emoji/marshmallow2.png': MascotDecorationConfig(
          offset: Offset(0, -46),
          scale: 0.9,
        ),
        'assets/images/emoji/marshmallow3.png': MascotDecorationConfig(
          offset: Offset(0, -46),
          scale: 0.9,
        ),
        'assets/images/emoji/marshmallow4.png': MascotDecorationConfig(
          offset: Offset(0, -46),
          scale: 0.9,
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
        'assets/images/emoji/marshmallow.png': MascotDecorationConfig(
          offset: Offset(-2, -34),
          scale: 1.0,
        ),
        'assets/images/emoji/marshmallow2.png': MascotDecorationConfig(
          offset: Offset(-2, -34),
          scale: 1.0,
        ),
        'assets/images/emoji/marshmallow3.png': MascotDecorationConfig(
          offset: Offset(-2, -34),
          scale: 1.0,
        ),
        'assets/images/emoji/marshmallow4.png': MascotDecorationConfig(
          offset: Offset(-2, -34),
          scale: 1.0,
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
        'assets/images/emoji/marshmallow.png': MascotDecorationConfig(
          offset: Offset(0, 10),
          scale: 1.78,
        ),
        'assets/images/emoji/marshmallow2.png': MascotDecorationConfig(
          offset: Offset(0, 10),
          scale: 1.78,
        ),
        'assets/images/emoji/marshmallow3.png': MascotDecorationConfig(
          offset: Offset(0, 10),
          scale: 1.78,
        ),
        'assets/images/emoji/marshmallow4.png': MascotDecorationConfig(
          offset: Offset(0, 10),
          scale: 1.78,
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
        'assets/images/emoji/marshmallow.png': MascotDecorationConfig(
          offset: Offset(0, -60),
          scale: 0.7,
        ),
        'assets/images/emoji/marshmallow2.png': MascotDecorationConfig(
          offset: Offset(0, -60),
          scale: 0.54,
        ),
        'assets/images/emoji/marshmallow3.png': MascotDecorationConfig(
          offset: Offset(0, -60),
          scale: 0.7,
        ),
        'assets/images/emoji/marshmallow4.png': MascotDecorationConfig(
          offset: Offset(0, -60),
          scale: 0.7,
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
        'assets/images/emoji/marshmallow.png': MascotDecorationConfig(
          offset: Offset(0, -40),
          scale: 0.78,
        ),
        'assets/images/emoji/marshmallow2.png': MascotDecorationConfig(
          offset: Offset(0, -40),
          scale: 0.7,
        ),
        'assets/images/emoji/marshmallow3.png': MascotDecorationConfig(
          offset: Offset(0, -40),
          scale: 0.78,
        ),
        'assets/images/emoji/marshmallow4.png': MascotDecorationConfig(
          offset: Offset(0, -40),
          scale: 0.78,
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
        'assets/images/emoji/marshmallow.png': MascotDecorationConfig(
          offset: Offset(2, 10),
          scale: 1.4,
        ),
        'assets/images/emoji/marshmallow2.png': MascotDecorationConfig(
          offset: Offset(2, 10),
          scale: 1.4,
        ),
        'assets/images/emoji/marshmallow3.png': MascotDecorationConfig(
          offset: Offset(2, 10),
          scale: 1.4,
        ),
        'assets/images/emoji/marshmallow4.png': MascotDecorationConfig(
          offset: Offset(2, 10),
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
        'assets/images/emoji/marshmallow.png': MascotDecorationConfig(
          offset: Offset(-4, -40),
          scale: 1.1,
        ),
        'assets/images/emoji/marshmallow2.png': MascotDecorationConfig(
          offset: Offset(-4, -40),
          scale: 1,
        ),
        'assets/images/emoji/marshmallow3.png': MascotDecorationConfig(
          offset: Offset(-4, -40),
          scale: 1.0,
        ),
        'assets/images/emoji/marshmallow4.png': MascotDecorationConfig(
          offset: Offset(-4, -40),
          scale: 1.0,
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
        'assets/images/emoji/marshmallow.png': MascotDecorationConfig(
          offset: Offset(0, -74),
          scale: 1.10,
        ),
        'assets/images/emoji/marshmallow2.png': MascotDecorationConfig(
          offset: Offset(0, -74),
          scale: 0.86,
        ),
        'assets/images/emoji/marshmallow3.png': MascotDecorationConfig(
          offset: Offset(0, -74),
          scale: 1.0,
        ),
        'assets/images/emoji/marshmallow4.png': MascotDecorationConfig(
          offset: Offset(0, -74),
          scale: 1.0,
        ),
      },
    ),
    MascotDecoration(
      id: 'sunflower_hat',
      name: '向日葵草帽',
      path: 'assets/images/emoji/decorate/decorate13.png',
      description: '采撷夏日阳光，满载向阳心意',
      rarity: MascotRarity.rare,
      defaultConfig: MascotDecorationConfig(offset: Offset(0, -12), scale: 1.6),
      characterConfigs: {
        'assets/images/emoji/marshmallow.png': MascotDecorationConfig(
          offset: Offset(0, -40),
          scale: 1,
        ),
        'assets/images/emoji/marshmallow2.png': MascotDecorationConfig(
          offset: Offset(0, -40),
          scale: 1,
        ),
        'assets/images/emoji/marshmallow3.png': MascotDecorationConfig(
          offset: Offset(0, -40),
          scale: 1,
        ),
        'assets/images/emoji/marshmallow4.png': MascotDecorationConfig(
          offset: Offset(0, -40),
          scale: 1,
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
        'assets/images/emoji/marshmallow.png': MascotDecorationConfig(
          offset: Offset(-4, -50),
          scale: 1.24,
        ),
        'assets/images/emoji/marshmallow2.png': MascotDecorationConfig(
          offset: Offset(-4, -50),
          scale: 1.24,
        ),
        'assets/images/emoji/marshmallow3.png': MascotDecorationConfig(
          offset: Offset(-4, -50),
          scale: 1.24,
        ),
        'assets/images/emoji/marshmallow4.png': MascotDecorationConfig(
          offset: Offset(-4, -50),
          scale: 1.24,
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
        'assets/images/emoji/marshmallow.png': MascotDecorationConfig(
          offset: Offset(0, -20),
          scale: 1.14,
        ),
        'assets/images/emoji/marshmallow2.png': MascotDecorationConfig(
          offset: Offset(0, -20),
          scale: 1.14,
        ),
        'assets/images/emoji/marshmallow3.png': MascotDecorationConfig(
          offset: Offset(0, -20),
          scale: 1.14,
        ),
        'assets/images/emoji/marshmallow4.png': MascotDecorationConfig(
          offset: Offset(0, -20),
          scale: 1.14,
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
        'assets/images/emoji/marshmallow.png': MascotDecorationConfig(
          offset: Offset(4, -22),
          scale: 1.0,
        ),
        'assets/images/emoji/marshmallow2.png': MascotDecorationConfig(
          offset: Offset(4, -22),
          scale: 1.0,
        ),
        'assets/images/emoji/marshmallow3.png': MascotDecorationConfig(
          offset: Offset(4, -22),
          scale: 1.0,
        ),
        'assets/images/emoji/marshmallow4.png': MascotDecorationConfig(
          offset: Offset(4, -22),
          scale: 1.0,
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
        'assets/images/emoji/marshmallow.png': MascotDecorationConfig(
          offset: Offset(0, -74),
          scale: 0.9,
        ),
        'assets/images/emoji/marshmallow2.png': MascotDecorationConfig(
          offset: Offset(0, -74),
          scale: 0.84,
        ),
        'assets/images/emoji/marshmallow3.png': MascotDecorationConfig(
          offset: Offset(0, -74),
          scale: 0.9,
        ),
        'assets/images/emoji/marshmallow4.png': MascotDecorationConfig(
          offset: Offset(0, -74),
          scale: 0.9,
        ),
      },
    ),
    MascotDecoration(
      id: 'sheep_band',
      name: '小绵羊发带',
      path: 'assets/images/emoji/decorate/decorate18.png',
      description: '软绵绵的质感，治愈每一天',
      rarity: MascotRarity.common,
      defaultConfig: MascotDecorationConfig(offset: Offset(0, -12), scale: 1.5),
      characterConfigs: {
        'assets/images/emoji/marshmallow.png': MascotDecorationConfig(
          offset: Offset(0, -40),
          scale: 0.8,
        ),
        'assets/images/emoji/marshmallow2.png': MascotDecorationConfig(
          offset: Offset(0, -40),
          scale: 0.8,
        ),
        'assets/images/emoji/marshmallow3.png': MascotDecorationConfig(
          offset: Offset(0, -40),
          scale: 0.8,
        ),
        'assets/images/emoji/marshmallow4.png': MascotDecorationConfig(
          offset: Offset(0, -40),
          scale: 0.8,
        ),
      },
    ),
    MascotDecoration(
      id: 'psyduck_hat_pink',
      name: '粉色可达鸭帽',
      path: 'assets/images/emoji/decorate/decorate21.png',
      description: '呆萌可爱，粉色心情',
      rarity: MascotRarity.rare,
      defaultConfig: MascotDecorationConfig(offset: Offset(0, -15), scale: 1.4),
      characterConfigs: {
        'assets/images/emoji/marshmallow.png': MascotDecorationConfig(
          offset: Offset(0, -40),
          scale: 0.8,
        ),
        'assets/images/emoji/marshmallow2.png': MascotDecorationConfig(
          offset: Offset(0, -30),
          scale: 0.8,
        ),
        'assets/images/emoji/marshmallow3.png': MascotDecorationConfig(
          offset: Offset(0, -40),
          scale: 0.8,
        ),
        'assets/images/emoji/marshmallow4.png': MascotDecorationConfig(
          offset: Offset(0, -40),
          scale: 0.8,
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
        'assets/images/emoji/marshmallow.png': MascotDecorationConfig(
          offset: Offset(0, -54),
          scale: 1.5,
        ),
        'assets/images/emoji/marshmallow2.png': MascotDecorationConfig(
          offset: Offset(0, -54),
          scale: 1.5,
        ),
        'assets/images/emoji/marshmallow3.png': MascotDecorationConfig(
          offset: Offset(0, -54),
          scale: 1.5,
        ),
        'assets/images/emoji/marshmallow4.png': MascotDecorationConfig(
          offset: Offset(0, -54),
          scale: 1.5,
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
        'assets/images/emoji/marshmallow.png': MascotDecorationConfig(
          offset: Offset(0, -40),
          scale: 1.2,
        ),
        'assets/images/emoji/marshmallow2.png': MascotDecorationConfig(
          offset: Offset(0, -40),
          scale: 1.2,
        ),
        'assets/images/emoji/marshmallow3.png': MascotDecorationConfig(
          offset: Offset(0, -40),
          scale: 1.2,
        ),
        'assets/images/emoji/marshmallow4.png': MascotDecorationConfig(
          offset: Offset(0, -40),
          scale: 1.2,
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
        'assets/images/emoji/marshmallow.png': MascotDecorationConfig(
          offset: Offset(-2, -20),
          scale: 1.1,
        ),
        'assets/images/emoji/marshmallow2.png': MascotDecorationConfig(
          offset: Offset(-2, -20),
          scale: 1.1,
        ),
        'assets/images/emoji/marshmallow3.png': MascotDecorationConfig(
          offset: Offset(-2, -20),
          scale: 1.1,
        ),
        'assets/images/emoji/marshmallow4.png': MascotDecorationConfig(
          offset: Offset(-2, -20),
          scale: 1.1,
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
        'assets/images/emoji/marshmallow.png': MascotDecorationConfig(
          offset: Offset(0, -50),
          scale: 1.2,
        ),
        'assets/images/emoji/marshmallow2.png': MascotDecorationConfig(
          offset: Offset(0, -50),
          scale: 1.2,
        ),
        'assets/images/emoji/marshmallow3.png': MascotDecorationConfig(
          offset: Offset(0, -50),
          scale: 1.2,
        ),
        'assets/images/emoji/marshmallow4.png': MascotDecorationConfig(
          offset: Offset(0, -50),
          scale: 1.2,
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
        'assets/images/emoji/marshmallow.png': MascotDecorationConfig(
          offset: Offset(0, -25),
          scale: 1,
        ),
        'assets/images/emoji/marshmallow2.png': MascotDecorationConfig(
          offset: Offset(0, -25),
          scale: 1,
        ),
        'assets/images/emoji/marshmallow3.png': MascotDecorationConfig(
          offset: Offset(0, -25),
          scale: 1,
        ),
        'assets/images/emoji/marshmallow4.png': MascotDecorationConfig(
          offset: Offset(0, -25),
          scale: 1,
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
        'assets/images/emoji/marshmallow.png': MascotDecorationConfig(
          offset: Offset(2, 0),
          scale: 1.2,
        ),
        'assets/images/emoji/marshmallow2.png': MascotDecorationConfig(
          offset: Offset(2, 0),
          scale: 1.2,
        ),
        'assets/images/emoji/marshmallow3.png': MascotDecorationConfig(
          offset: Offset(2, 0),
          scale: 1.2,
        ),
        'assets/images/emoji/marshmallow4.png': MascotDecorationConfig(
          offset: Offset(2, 0),
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
        'assets/images/emoji/marshmallow.png': MascotDecorationConfig(
          offset: Offset(0, 0),
          scale: 1.38,
        ),
        'assets/images/emoji/marshmallow2.png': MascotDecorationConfig(
          offset: Offset(0, 0),
          scale: 1.38,
        ),
        'assets/images/emoji/marshmallow3.png': MascotDecorationConfig(
          offset: Offset(0, 0),
          scale: 1.38,
        ),
        'assets/images/emoji/marshmallow4.png': MascotDecorationConfig(
          offset: Offset(0, 0),
          scale: 1.38,
        ),
      },
    ),
    MascotDecoration(
      id: 'sausage_lips',
      name: '玫红香肠嘴',
      path: 'assets/images/emoji/decorate/decorate29.png',
      description: '火热的玫红，性感的轮廓，这是岛上最吸睛的时尚焦点。',
      rarity: MascotRarity.rare,
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
    MascotDecoration(
      id: 'orange_knit_hat',
      name: '橘色帽子',
      path: 'assets/images/emoji/decorate/decorate30.png',
      description: '明亮的橘色，温暖的针织纹理，是冬日里最亮眼的小太阳。',
      rarity: MascotRarity.rare,
      defaultConfig: MascotDecorationConfig(offset: Offset(0, -15), scale: 1.2),
      characterConfigs: {
        'assets/images/emoji/marshmallow.png': MascotDecorationConfig(
          offset: Offset(0, -65),
          scale: 0.9,
        ),
        'assets/images/emoji/marshmallow2.png': MascotDecorationConfig(
          offset: Offset(0, -65),
          scale: 0.82,
        ),
        'assets/images/emoji/marshmallow3.png': MascotDecorationConfig(
          offset: Offset(0, -65),
          scale: 0.9,
        ),
        'assets/images/emoji/marshmallow4.png': MascotDecorationConfig(
          offset: Offset(0, -65),
          scale: 0.9,
        ),
      },
    ),
    MascotDecoration(
      id: 'purple_knit_hat',
      name: '紫色帽子',
      path: 'assets/images/emoji/decorate/decorate31.png',
      description: '神秘且柔和的紫色，编织出属于小岛冬日的浪漫。',
      rarity: MascotRarity.rare,
      defaultConfig: MascotDecorationConfig(offset: Offset(0, -15), scale: 1.2),
      characterConfigs: {
        'assets/images/emoji/marshmallow.png': MascotDecorationConfig(
          offset: Offset(0, -65),
          scale: 0.9,
        ),
        'assets/images/emoji/marshmallow2.png': MascotDecorationConfig(
          offset: Offset(0, -65),
          scale: 0.82,
        ),
        'assets/images/emoji/marshmallow3.png': MascotDecorationConfig(
          offset: Offset(0, -65),
          scale: 0.9,
        ),
        'assets/images/emoji/marshmallow4.png': MascotDecorationConfig(
          offset: Offset(0, -65),
          scale: 0.9,
        ),
      },
    ),
    MascotDecoration(
      id: 'party_pig_hat',
      name: '派对小猪',
      path: 'assets/images/emoji/decorate/decorate32.png',
      description: '呆萌的小猪造型，配上俏皮的派对帽，你就是全场最闪耀的主角！',
      rarity: MascotRarity.rare,
      defaultConfig: MascotDecorationConfig(offset: Offset(0, -10), scale: 1.5),
      characterConfigs: {
        'assets/images/emoji/marshmallow.png': MascotDecorationConfig(
          offset: Offset(0, 0),
          scale: 1.0,
        ),
        'assets/images/emoji/marshmallow2.png': MascotDecorationConfig(
          offset: Offset(0, 0),
          scale: 1.0,
        ),
        'assets/images/emoji/marshmallow3.png': MascotDecorationConfig(
          offset: Offset(0, 0),
          scale: 1.0,
        ),
        'assets/images/emoji/marshmallow4.png': MascotDecorationConfig(
          offset: Offset(0, 0),
          scale: 1.0,
        ),
      },
    ),
    MascotDecoration(
      id: 'little_monster_hat',
      name: '小怪兽',
      path: 'assets/images/emoji/decorate/decorate33.png',
      description: '并不吓人的小怪兽发箍，顶着闪亮的小皇冠，调皮中带着一丝高贵。',
      rarity: MascotRarity.common,
      defaultConfig: MascotDecorationConfig(offset: Offset(0, -10), scale: 1.6),
      characterConfigs: {
        'assets/images/emoji/marshmallow.png': MascotDecorationConfig(
          offset: Offset(0, -40),
          scale: 0.6,
        ),
        'assets/images/emoji/marshmallow2.png': MascotDecorationConfig(
          offset: Offset(0, -40),
          scale: 0.6,
        ),
        'assets/images/emoji/marshmallow3.png': MascotDecorationConfig(
          offset: Offset(0, -40),
          scale: 0.6,
        ),
        'assets/images/emoji/marshmallow4.png': MascotDecorationConfig(
          offset: Offset(0, -40),
          scale: 0.6,
        ),
      },
    ),
    MascotDecoration(
      id: 'pink_cherry_dancer',
      name: '粉樱小花旦',
      path: 'assets/images/emoji/decorate/decorate34.png',
      description: '粉樱如雪，旦角点妆。一颦一笑皆是戏，最美不过这春日容颜。',
      rarity: MascotRarity.epic,
      defaultConfig: MascotDecorationConfig(offset: Offset(0, -20), scale: 1.5),
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
      id: 'big_ear_fluffy_hat',
      name: '大耳绒绒帽',
      path: 'assets/images/emoji/decorate/decorate35.png',
      description: '软乎乎的大兔耳朵，包裹住冬日所有的温柔，治愈每一个寒冷的清晨。',
      rarity: MascotRarity.rare,
      defaultConfig: MascotDecorationConfig(offset: Offset(0, -18), scale: 1.5),
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
      id: 'retro_heart_bow',
      name: '复古爱心蝴蝶结',
      path: 'assets/images/emoji/decorate/decorate36.png',
      description: '旧时光里的红色蝴蝶结，中心嵌着一颗炽热的心，那是岁月赠予的最浪漫的饰章。',
      rarity: MascotRarity.common,
      defaultConfig: MascotDecorationConfig(offset: Offset(0, -10), scale: 1.4),
      characterConfigs: {
        'assets/images/emoji/marshmallow.png': MascotDecorationConfig(
          offset: Offset(0, 10),
          scale: 1.0,
        ),
        'assets/images/emoji/marshmallow2.png': MascotDecorationConfig(
          offset: Offset(0, 10),
          scale: 1.0,
        ),
        'assets/images/emoji/marshmallow3.png': MascotDecorationConfig(
          offset: Offset(0, 10),
          scale: 1.0,
        ),
        'assets/images/emoji/marshmallow4.png': MascotDecorationConfig(
          offset: Offset(0, 10),
          scale: 1.0,
        ),
      },
    ),
    MascotDecoration(
      id: 'candy_heart_lion',
      name: '糖心醒狮',
      path: 'assets/images/emoji/decorate/decorate37.png',
      description: '甜美糖心遇上威武醒狮，传统与软萌的奇妙碰撞，守护你每一份红火的心意。',
      rarity: MascotRarity.legendary,
      defaultConfig: MascotDecorationConfig(offset: Offset(0, -10), scale: 1.4),
      characterConfigs: {
        'assets/images/emoji/marshmallow.png': MascotDecorationConfig(
          offset: Offset(0, -10),
          scale: 1.5,
        ),
        'assets/images/emoji/marshmallow2.png': MascotDecorationConfig(
          offset: Offset(0, -10),
          scale: 1.5,
        ),
        'assets/images/emoji/marshmallow3.png': MascotDecorationConfig(
          offset: Offset(0, -10),
          scale: 1.5,
        ),
        'assets/images/emoji/marshmallow4.png': MascotDecorationConfig(
          offset: Offset(0, -10),
          scale: 1.5,
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
