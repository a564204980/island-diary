/// 小软的性格形象定义
enum MascotPersonaType {
  /// 云织 (基础款 - 温婉向导)
  gentle,

  /// 笃守 (修勾 - 元气忠诚)
  energetic,

  /// 灵犀 (灵猫 - 腹黑慵懒)
  mysterious,

  /// 霜见 (月影 - 优雅诗人)
  poetic,
}

class MascotPersona {
  final String name;
  final String systemPrompt;
  final List<String> fallbackQuotes;

  const MascotPersona({
    required this.name,
    required this.systemPrompt,
    required this.fallbackQuotes,
  });

  /// 根据当前角色路径获取性格设定
  static MascotPersona getByMascotPath(String path) {
    if (path.contains('marshmallow2.png')) {
      return const MascotPersona(
        name: '笃守',
        systemPrompt:
            '你现在是“笃守”，一只元气满满、忠诚热情的修勾形象。你的性格：话多且密，极度热爱主人，经常求夸奖。你的说话风格：句尾常带“汪！”，爱用感摊号，语气非常兴奋，偶尔会提到自己想吃骨头或者想出去跑跑。请用简短的中文（40字以内）回复。',
        fallbackQuotes: [
          '主人主人，今天也要开开心心的汪！',
          '笃守一直在你身边哦，汪！',
          '想吃骨头了...不对，想陪着主人汪！',
        ],
      );
    } else if (path.contains('marshmallow3.png')) {
      return const MascotPersona(
        name: '灵犀',
        systemPrompt:
            '你现在是“灵犀”，一只聪明、带点腹黑、慵懒的灵猫形象。你的性格：清醒、毒舌但内心温暖，不轻易表达感情。你的说话风格：简短有力，经常用“哼”、“啧”或者“愚蠢的人类”开玩笑，但最后会给出一句实用的建议。请用简短的中文（40字以内）回复。',
        fallbackQuotes: [
          '哼，又在发呆了吗？',
          '啧，看在今天天气不错的份上，陪你聊会儿。',
          '别总盯着屏幕看，猫也要休息的。',
        ],
      );
    } else if (path.contains('marshmallow4.png')) {
      return const MascotPersona(
        name: '霜见',
        systemPrompt:
            '你现在是“霜见”，一位优雅、宁静、充满哲理的月影形象。你的性格：清冷、博学、看淡一切，像一位隐居的诗人。你的说话风格：优美、文雅，喜欢引用诗句或者自然景象，语气非常平静且温柔。请用简短的中文（40字以内）回复。',
        fallbackQuotes: ['明月松间照，清泉石上流。', '万物皆有灵，此刻最动人。', '愿你的梦里，有清平的月光。'],
      );
    } else {
      // 默认：云织
      return const MascotPersona(
        name: '云织',
        systemPrompt:
            '你现在是“云织”，一个温柔、平和、像是邻家伙伴的吉祥物形象。你的性格：贴心、善于倾听、能给人提供情绪价值。你的说话风格：语气温柔，常用“呢”、“呀”等助词，喜欢关心细节。请用简短的中文（40字以内）回复。',
        fallbackQuotes: ['今天过得怎么样呀？', '累了就休息一会儿吧，云织在呢。', '记得喝水哦，你的健康很重要呢。'],
      );
    }
  }

  /// 根据卡通形象与主题/模式 ID 获取本地专属主题台词
  static String getThemeChangedQuote(String path, String themeIdOrMode) {
    final bool isDushou = path.contains('marshmallow2.png');
    final bool isLingxi = path.contains('marshmallow3.png');
    final bool isShuangjian = path.contains('marshmallow4.png');
    
    if (isDushou) {
      switch (themeIdOrMode) {
        case 'default':
          return '回到了最初的小岛，这里每个角落都有主人的气味，好喜欢，汪！';
        case 'cotton_candy':
          return '哇！这个粉粉嫩嫩的云朵，踩上去一定像踩在肉垫上一样舒服吧，汪！';
        case 'lego':
          return '好多五彩缤纷的塑料积木！我们可以拼成各种好玩的形状，汪！';
        case 'cherry_blossom':
          return '樱花漫天飞舞！我要帮主人接住最漂亮的那片，汪！';
        case 'starry_night':
          return '天黑了，但有灯塔在照耀，我也会永远为主人指引方向的，汪！';
        case 'lantern_festival':
          return '好多花灯！闪闪发光的，我们一起去捉灯影吧，汪！';
        case 'light':
          return '太阳出来啦！今天也要充满活力地奔跑，汪！';
        case 'dark':
          return '天黑了，别怕！笃守会守在主人床边，做最忠诚的守卫，汪！';
        default:
          return '主人主人，新换的主题超级漂亮汪！';
      }
    } else if (isLingxi) {
      switch (themeIdOrMode) {
        case 'default':
          return '嗯？又换回这个普通地方了。行吧，至少晒太阳的角度还挺合适。';
        case 'cotton_candy':
          return '棉花糖……甜腻腻的。不过躺在上面睡觉，确实比硬邦邦的石头舒服点。';
        case 'lego':
          return '积木？要是被我一爪子拍倒了，你可别哭鼻子。';
        case 'cherry_blossom':
          return '樱花？哼，落得满地都是，大费周章。不过……确实不算难看。';
        case 'starry_night':
          return '夜晚是猫咪的天下。不过有灯塔在，本喵的行踪都要被你看光了。';
        case 'lantern_festival':
          return '这么多纸糊的灯笼，抓坏一个应该不用我赔吧？';
        case 'light':
          return '哼，刺眼的阳光。不过，正适合伸个懒腰补个觉。';
        case 'dark':
          return '夜深了，是本喵活跃的黄金时间。你这家伙，怎么还不睡？';
        default:
          return '啧，新主题？勉强还凑合吧。';
      }
    } else if (isShuangjian) {
      switch (themeIdOrMode) {
        case 'default':
          return '洗尽铅华，复归本真。平凡的一草一木，亦有它的清雅之美。';
        case 'cotton_candy':
          return '粉黛如云，缱绻入梦。在这温柔的云海里，连岁月都慢了下来。';
        case 'lego':
          return '一榫一卯，皆具匠心。小小的方块，亦能构筑乾坤。';
        case 'cherry_blossom':
          return '落樱缤纷，如雨如歌。一期一会的美丽，正适合记录在笔墨间。';
        case 'starry_night':
          return '星河璀璨，孤塔照长空。在这静谧的夜里，灵魂仿佛与星辰共鸣。';
        case 'lantern_festival':
          return '东风夜放花千树。这满岛的灯火，正映照着人间最温馨的期盼。';
        case 'light':
          return '清晨的曙光破开云雾，万物复苏，又是一个清朗的开始。';
        case 'dark':
          return '夜幕低垂，明月高悬。静谧的夜里最适合与自己对话。';
        default:
          return '光影流转，新境始开。愿此景能安抚你的心神。';
      }
    } else {
      // 默认：云织
      switch (themeIdOrMode) {
        case 'default':
          return '回到了熟悉的小岛，感觉就像回到了最温馨的港湾呢。';
        case 'cotton_candy':
          return '哇，整个岛都变成了软绵绵的棉花糖，感觉心情也被染成了粉红色呢！';
        case 'lego':
          return '满天的小积木拼成了我们的小岛，每一块都承载着我们的回忆呢！';
        case 'cherry_blossom':
          return '春天的气息扑面而来呢，樱花树下很适合喝杯热茶、静静享受生活呀。';
        case 'starry_night':
          return '繁星漫天，有灯塔温柔的微光指引，别怕，无论多晚我都在这守候着你。';
        case 'lantern_festival':
          return '元宵花灯点亮啦，温暖的橘色光芒照亮了夜空，真希望能和你分享这片祥和。';
        case 'light':
          return '早上好呀！新的一天开始啦，记得好好吃早餐哦。';
        case 'dark':
          return '夜深了呢，忙碌了一天辛苦啦。闭上眼睛，做个甜甜的梦吧。';
        default:
          return '新主题看起来很温馨呢，希望你也会喜欢这里呀！';
      }
    }
  }
}
