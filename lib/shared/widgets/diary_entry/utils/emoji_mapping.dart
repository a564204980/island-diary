import 'package:flutter/material.dart';

/// 表情映射工具类，用于 Unicode 字符与高清图片路径的对应
class EmojiMapping {
  static const String assetPrefix = 'assets/images/emoji/wechat/face/';

  /// Unicode 到本地高清 PNG 路径的映射 (覆盖 75 个主要表情)
  static const Map<String, String> unicodeToPath = {
    '😊': '微笑.png',
    '🥰': '脸红.png', 
    '🥳': '愉快.png',
    '🤩': '色.png',
    '😘': '亲亲.png',
    '😋': '呲牙.png',
    '😎': '得意.png',
    '😇': '笑脸.png',
    '🤫': '嘘.png',
    '🤪': '调皮.png',
    '🤗': '嘿哈.png',
    '🥺': '可怜.png',
    '😭': '流泪.png',
    '😱': '惊恐.png',
    '😡': '发怒.png',
    '😏': '悠闲.png',
    '🥱': '困.png',
    '😴': '睡.png',
    '🙄': '白眼.png',
    '🤔': '疑问.png',
    '🤤': '流口水.png',
    '🤢': '吐.png',
    '🥴': '晕.png',
    '😵': '晕.png',
    '😁': '呲牙.png',
    '😂': '破涕为笑.png',
    '🤣': '破涕为笑.png',
    '😅': '尴尬.png',
    '😑': '😑.png',
    '😒': '撇嘴.png',
    '😔': '衰.png',
    '🤮': '吐.png',
    '🤬': '咒骂.png',
    '🤯': '天啊.png',
    '😳': '害羞.png',
    '😵‍💫': '晕.png',
    '🤐': '闭嘴.png',
    '🤭': '偷笑.png',
    '😌': '悠闲.png',
    '😜': '调皮.png',
    '😝': '调皮.png',
    '😷': '生病.png',
    '🤒': '生病.png',
    '🤕': '生病.png',
    '😈': '坏笑.png',
    '👿': '坏笑.png',
    '💀': '骷髅.png',
    '💩': '大便.png',
    '🤡': '小丑.png',
    '👹': '鬼脸.png',
    '👺': '鬼脸.png',
    '👏': '鼓掌.png',
    '👌': '好的.png',
    '👍': '点赞.png',
    '👎': '踩.png',
    '👊': '敲打.png',
    '✌️': '耶.png',
    '👋': '再见.png',
    '💪': '嘿哈.png',
    '🙏': '🙏.png',
    '🤝': '🤝.png',
    '❤️': '爱心.png',
    '💖': '爱心.png',
    '💔': '心碎.png',
    '💯': '100.png',
    '🔥': '火.png',
    '✨': '闪亮.png',
    '🌟': '星星.png',
    '🌙': '月亮.png',
    '☀️': '太阳.png',
    '☁️': '云.png',
    '🌧️': '下雨.png',
    '❄️': '雪花.png',
    '🌈': '虹.png',
    '🎀': '礼物.png',
    '🎁': '礼物.png',
    '🎂': '蛋糕.png',
    '🧧': '红包.png',
    '🐕': '旺柴.png',
  };

  /// 微信表情原生名称到路径的映射 (用于 EmojiPanel)
  static const Map<String, String> nameToPath = {
    '微笑': 'assets/images/emoji/wechat/face/微笑.png',
    '撇嘴': 'assets/images/emoji/wechat/face/撇嘴.png',
    '色': 'assets/images/emoji/wechat/face/色.png',
    '发呆': 'assets/images/emoji/wechat/face/发呆.png',
    '得意': 'assets/images/emoji/wechat/face/得意.png',
    '流泪': 'assets/images/emoji/wechat/face/流泪.png',
    '害羞': 'assets/images/emoji/wechat/face/害羞.png',
    '闭嘴': 'assets/images/emoji/wechat/face/闭嘴.png',
    '睡': 'assets/images/emoji/wechat/face/睡.png',
    '大哭': 'assets/images/emoji/wechat/face/大哭.png',
    '尴尬': 'assets/images/emoji/wechat/face/尴尬.png',
    '发怒': 'assets/images/emoji/wechat/face/发怒.png',
    '调皮': 'assets/images/emoji/wechat/face/调皮.png',
    '呲牙': 'assets/images/emoji/wechat/face/呲牙.png',
    '惊讶': 'assets/images/emoji/wechat/face/惊讶.png',
    '难过': 'assets/images/emoji/wechat/face/难过.png',
    '囧': 'assets/images/emoji/wechat/face/囧.png',
    '抓狂': 'assets/images/emoji/wechat/face/抓狂.png',
    '吐': 'assets/images/emoji/wechat/face/吐.png',
    '偷笑': 'assets/images/emoji/wechat/face/偷笑.png',
    '愉快': 'assets/images/emoji/wechat/face/愉快.png',
    '白眼': 'assets/images/emoji/wechat/face/白眼.png',
    '傲慢': 'assets/images/emoji/wechat/face/傲慢.png',
    '困': 'assets/images/emoji/wechat/face/困.png',
    '惊恐': 'assets/images/emoji/wechat/face/惊恐.png',
    '憨笑': 'assets/images/emoji/wechat/face/憨笑.png',
    '悠闲': 'assets/images/emoji/wechat/face/悠闲.png',
    '咒骂': 'assets/images/emoji/wechat/face/咒骂.png',
    '疑问': 'assets/images/emoji/wechat/face/疑问.png',
    '嘘': 'assets/images/emoji/wechat/face/嘘.png',
    '晕': 'assets/images/emoji/wechat/face/晕.png',
    '衰': 'assets/images/emoji/wechat/face/衰.png',
    '骷髅': 'assets/images/emoji/wechat/face/骷髅.png',
    '敲打': 'assets/images/emoji/wechat/face/敲打.png',
    '再见': 'assets/images/emoji/wechat/face/再见.png',
    '擦汗': 'assets/images/emoji/wechat/face/擦汗.png',
    '抠鼻': 'assets/images/emoji/wechat/face/抠鼻.png',
    '鼓掌': 'assets/images/emoji/wechat/face/鼓掌.png',
    '坏笑': 'assets/images/emoji/wechat/face/坏笑.png',
    '破涕为笑': 'assets/images/emoji/wechat/face/破涕为笑.png',
    '好的': 'assets/images/emoji/wechat/face/好的.png',
    '捂脸': 'assets/images/emoji/wechat/face/捂脸.png',
    '旺柴': 'assets/images/emoji/wechat/face/旺柴.png',
    '耶': 'assets/images/emoji/wechat/face/耶.png',
    '嘿哈': 'assets/images/emoji/wechat/face/嘿哈.png',
  };

  /// 获取对应的图片路径
  static String? getPathForEmoji(String emoji) {
    if (unicodeToPath.containsKey(emoji)) {
      final fileName = unicodeToPath[emoji]!;
      return '$assetPrefix$fileName';
    }
    return null;
  }

  /// 获取常用表情列表 (用于 EmojiPanel 展示)
  static List<Map<String, String>> get commonEmojis {
    final List<Map<String, String>> list = [];
    
    // 反转 unicodeToPath 以便查找
    final pathToUnicode = <String, String>{};
    unicodeToPath.forEach((key, value) {
      pathToUnicode[value] = key;
    });

    nameToPath.forEach((name, path) {
      final fileName = path.split('/').last;
      final unicode = pathToUnicode[fileName] ?? '';
      list.add({
        'name': name,
        'path': path,
        'unicode': unicode,
      });
    });
    return list;
  }

  /// 简单的 Unicode 转 [名称] 回退逻辑
  static const Map<String, String> unicodeToName = {
    '😊': '微笑',
    '🥰': '脸红',
    '🥳': '愉快',
    '🤩': '色',
    '😘': '亲亲',
    '😋': '呲牙',
    '😎': '得意',
    '🙄': '白眼',
    '🤔': '疑问',
    '😭': '流泪',
    '😡': '发怒',
    '😏': '悠闲',
    '😴': '睡',
    '😱': '惊恐',
    '🤫': '嘘',
    '😜': '调皮',
    '嘿': '嘿哈',
    '👋': '再见',
  };

  /// 解析文本，将其拆分为文字和表情块
  static List<TextChunk> parseText(String text) {
    final List<TextChunk> chunks = [];
    if (text.isEmpty) return chunks;

    final keys = unicodeToPath.keys.toList()..sort((a, b) => b.length.compareTo(a.length));
    final emojiPattern = keys.map((e) => RegExp.escape(e)).join('|');
    
    final nameKeys = nameToPath.keys.toList()..sort((a, b) => b.length.compareTo(a.length));
    final namePattern = nameKeys.map((e) => RegExp.escape('[$e]')).join('|');

    final pattern = [
      if (emojiPattern.isNotEmpty) emojiPattern,
      if (namePattern.isNotEmpty) namePattern,
    ].join('|');
    
    if (pattern.isEmpty) {
      chunks.add(TextChunk(text: text));
      return chunks;
    }

    final regExp = RegExp(pattern);
    int lastMatchEnd = 0;

    for (final match in regExp.allMatches(text)) {
      if (match.start > lastMatchEnd) {
        chunks.add(TextChunk(text: text.substring(lastMatchEnd, match.start)));
      }

      final matchedStr = match.group(0)!;
      String? path;
      if (matchedStr.startsWith('[') && matchedStr.endsWith(']')) {
        final name = matchedStr.substring(1, matchedStr.length - 1);
        path = nameToPath[name];
      } else {
        path = getPathForEmoji(matchedStr);
      }
      
      chunks.add(TextChunk(text: matchedStr, emojiPath: path));

      lastMatchEnd = match.end;
    }

    if (lastMatchEnd < text.length) {
      chunks.add(TextChunk(text: text.substring(lastMatchEnd)));
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
