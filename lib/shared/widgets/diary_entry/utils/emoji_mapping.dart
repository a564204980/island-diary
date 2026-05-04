/// 表情映射工具类
/// 使用 Unicode 私用区字符 (U+E001~U+E028) 作为表情占位符。
/// 每个表情对应一个单一的不可见字符，彻底避免文字外露。
class EmojiMapping {
  static const String yunzhiPrefix = 'assets/images/emoji/yunzhi/';
  static const String shuangjianPrefix = 'assets/images/emoji/shuangjian/';
  static const String dushouPrefix = 'assets/images/emoji/dushou/';
  static const String lingxiPrefix = 'assets/images/emoji/lingxi/';

  /// 分类定义（每个表情含唯一 PUA 码点）
  static const List<Map<String, dynamic>> categories = [
    {
      'id': '云织',
      'name': '云织',
      'prefix': yunzhiPrefix,
      'emojis': [
        {'name': '开心', 'file': 'happy.png',      'pua': 0xE001},
        {'name': '生气', 'file': 'angry.png',      'pua': 0xE002},
        {'name': '害羞', 'file': 'shy.png',        'pua': 0xE003},
        {'name': '大哭', 'file': 'wail.png',       'pua': 0xE004},
        {'name': '偷笑', 'file': 'snicker.png',    'pua': 0xE005},
        {'name': '无语', 'file': 'speechless.png', 'pua': 0xE006},
        {'name': '惊讶', 'file': 'surprised.png',  'pua': 0xE007},
        {'name': '委屈', 'file': 'wronged.png',    'pua': 0xE008},
        {'name': '加油', 'file': 'ComeOn.png',     'pua': 0xE009},
        {'name': '吃瓜', 'file': 'eatMelon.png',   'pua': 0xE00A},
        {'name': '拥抱', 'file': 'hug.png',        'pua': 0xE00B},
        {'name': '喜欢', 'file': 'like.png',       'pua': 0xE00C},
        {'name': '比心', 'file': 'makeHeart.png',  'pua': 0xE00D},
        {'name': '想你', 'file': 'missYou.png',    'pua': 0xE00E},
        {'name': '早安', 'file': 'morning.png',    'pua': 0xE00F},
        {'name': '晚安', 'file': 'night.png',      'pua': 0xE010},
        {'name': '好的', 'file': 'okay..png',      'pua': 0xE011},
        {'name': '偷看', 'file': 'peek.png',       'pua': 0xE012},
        {'name': '困',   'file': 'sleepy.png',     'pua': 0xE013},
        {'name': '星星', 'file': 'star.png',       'pua': 0xE014},
        {'name': '谢谢', 'file': 'thank.png',      'pua': 0xE015},
        {'name': '发呆', 'file': 'zoneOut.png',    'pua': 0xE016},
        {'name': '摸头', 'file': 'pathead.png',    'pua': 0xE017},
      ],
    },
    {
      'id': '霜见',
      'name': '霜见',
      'prefix': shuangjianPrefix,
      'emojis': [
        {'name': '开心', 'file': 'happy.png',      'pua': 0xE018},
        {'name': '生气', 'file': 'angry.png',      'pua': 0xE019},
        {'name': '爱心', 'file': 'heart.png',      'pua': 0xE01A},
        {'name': '喜欢', 'file': 'like.png',       'pua': 0xE01B},
        {'name': '想你', 'file': 'missYou.png',    'pua': 0xE01C},
        {'name': '早安', 'file': 'morning.png',    'pua': 0xE01D},
        {'name': '晚安', 'file': 'night.png',      'pua': 0xE01E},
        {'name': '天空', 'file': 'sky.png',        'pua': 0xE01F},
        {'name': '呜呜', 'file': 'sob.png',        'pua': 0xE020},
        {'name': '无语', 'file': 'speechless.png', 'pua': 0xE021},
        {'name': '惊讶', 'file': 'surprised.png',  'pua': 0xE022},
        {'name': '谢谢', 'file': 'thank.png',      'pua': 0xE023},
      ],
    },
    {
      'id': '笃守',
      'name': '笃守',
      'prefix': dushouPrefix,
      'emojis': [
        {'name': '开心', 'file': 'happy.png',      'pua': 0xE024},
        {'name': '生气', 'file': 'angry.png',      'pua': 0xE025},
        {'name': '害羞', 'file': 'shy.png',        'pua': 0xE026},
        {'name': '呜呜', 'file': 'sob.png',        'pua': 0xE027},
        {'name': '惊讶', 'file': 'surprised.png',  'pua': 0xE028},
        {'name': '爱心', 'file': 'heart.png',      'pua': 0xE029},
        {'name': '喜欢', 'file': 'like.png',       'pua': 0xE02A},
        {'name': '叹气', 'file': 'sigh.png',       'pua': 0xE02B},
      ],
    },
    {
      'id': '灵犀',
      'name': '灵犀',
      'prefix': lingxiPrefix,
      'emojis': [
        {'name': '生气', 'file': 'angry.png',      'pua': 0xE02C},
        {'name': '大哭', 'file': 'cry.png',        'pua': 0xE02D},
        {'name': '吃瓜', 'file': 'eatmelon.png',   'pua': 0xE02E},
        {'name': '开心', 'file': 'happy.png',      'pua': 0xE02F},
        {'name': '爱心', 'file': 'heart.png',      'pua': 0xE030},
        {'name': '喜欢', 'file': 'like.png',       'pua': 0xE031},
        {'name': '想你', 'file': 'missyou.png',    'pua': 0xE032},
        {'name': '早安', 'file': 'moring.png',     'pua': 0xE033},
        {'name': '晚安', 'file': 'night.png',      'pua': 0xE034},
        {'name': '偷看', 'file': 'peek.png',       'pua': 0xE035},
        {'name': '疑问', 'file': 'question.png',   'pua': 0xE036},
        {'name': '傲娇', 'file': 'sassy.png',      'pua': 0xE037},
        {'name': '震惊', 'file': 'shocked.png',    'pua': 0xE038},
        {'name': '委屈', 'file': 'smh2.png',       'pua': 0xE039},
        {'name': '偷笑', 'file': 'snicker.png',    'pua': 0xE03A},
        {'name': '谢谢', 'file': 'thank.png',      'pua': 0xE03B},
      ],
    },
  ];

  /// PUA 字符 → 图片路径
  static Map<String, String> get charToPath {
    final map = <String, String>{};
    for (final cat in categories) {
      final prefix = cat['prefix'] as String;
      for (final e in (cat['emojis'] as List)) {
        map[String.fromCharCode(e['pua'] as int)] = '$prefix${e['file']}';
      }
    }
    return map;
  }

  /// 判断单个字符是否是表情 PUA 字符
  static bool isEmojiChar(String char) => charToPath.containsKey(char);

  /// 获取 PUA 字符对应的图片路径
  static String? getPathForEmoji(String char) => charToPath[char];

  /// 正则：匹配任意一个 PUA 表情字符（U+E001~U+E03B）
  static final RegExp emojiPattern = RegExp('[\uE001-\uE03B]');

  /// 同 emojiPattern，以字符串形式提供（供旧代码兼容）
  static String get pattern => '[\uE001-\uE03B]';

  /// 解析文本，拆分为普通文字块和表情块
  static List<TextChunk> parseText(String text) {
    final chunks = <TextChunk>[];
    if (text.isEmpty) return chunks;
    int lastEnd = 0;
    for (final match in emojiPattern.allMatches(text)) {
      if (match.start > lastEnd) {
        chunks.add(TextChunk(text: text.substring(lastEnd, match.start)));
      }
      final char = match.group(0)!;
      chunks.add(TextChunk(text: char, emojiPath: charToPath[char]));
      lastEnd = match.end;
    }
    if (lastEnd < text.length) {
      chunks.add(TextChunk(text: text.substring(lastEnd)));
    }
    return chunks;
  }
}

/// 文本块模型
class TextChunk {
  final String text;
  final String? emojiPath;
  bool get isEmoji => emojiPath != null;
  TextChunk({required this.text, this.emojiPath});
}
