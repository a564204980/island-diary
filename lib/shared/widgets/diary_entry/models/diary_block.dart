import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:uuid/uuid.dart';
import 'package:island_diary/core/state/user_state.dart';
import '../utils/emoji_mapping.dart';

abstract class DiaryBlock {
  final String id;
  DiaryBlock({String? id}) : id = id ?? const Uuid().v4();

  Map<String, dynamic> toMap();

  static DiaryBlock fromMap(Map<String, dynamic> map) {
    final type = map['type'];
    final id = map['id']?.toString();
    if (type == 'text') {
      final content = map['content'] ?? '';
      final List<TextAttribute> attrs = [];
      if (map['attributes'] != null && map['attributes'] is List) {
        final List list = map['attributes'];
        for (var item in list) {
          if (item is Map<String, dynamic>) {
            attrs.add(TextAttribute.fromMap(item));
          }
        }
      }
      final block = TextBlock(content, attributes: attrs, id: id);
      if (map['baseColor'] != null) {
        final controller = block.controller;
        if (controller is TopicTextEditingController) {
          controller.baseColor = Color(map['baseColor']);
          if (map['baseFontSize'] != null) {
            controller.baseFontSize = map['baseFontSize'].toDouble();
          }
          if (map['baseFontFamily'] != null) {
            controller.baseFontFamily = map['baseFontFamily'].toString();
          }
        }
      }
      return block;
    } else if (type == 'image') {
      final path = map['path'];
      if (path != null && path.toString().isNotEmpty) {
        final videoPath = map['videoPath']?.toString();
        return ImageBlock(XFile(path.toString()), id: id, videoPath: videoPath);
      }
      return TextBlock('');
    } else if (type == 'audio') {
      final path = map['path'];
      final name = map['name'] ?? '未命名音乐';
      if (path != null && path.toString().isNotEmpty) {
        return AudioBlock(path.toString(), name, id: id);
      }
      return TextBlock('');
    } else if (type == 'reward') {
      final rewardId = map['rewardId']?.toString() ?? '';
      final path = map['path']?.toString() ?? '';
      final name = map['name']?.toString() ?? '';
      return RewardBlock(rewardId, path, name, id: id);
    }
    return TextBlock('');
  }
}

/// 奖励块 (用于存储动植物等成就)
class RewardBlock extends DiaryBlock {
  final String rewardId;
  final String imagePath;
  final String name;

  RewardBlock(this.rewardId, this.imagePath, this.name, {super.id});

  @override
  Map<String, dynamic> toMap() => {
    'id': id,
    'type': 'reward',
    'rewardId': rewardId,
    'path': imagePath,
    'name': name,
  };
}

/// 文本属性记录（用于局部变色）
class TextAttribute {
  final int start;
  final int end;
  final Color? color;
  final Color? backgroundColor;
  final double? fontSize;
  final bool isTopic;

  TextAttribute({
    required this.start,
    required this.end,
    this.color,
    this.backgroundColor,
    this.fontSize,
    this.isTopic = false, // 是否为话题标签
  });

  Map<String, dynamic> toMap() => {
    'start': start,
    'end': end,
    if (color != null) 'color': color!.value,
    if (backgroundColor != null) 'backgroundColor': backgroundColor!.value,
    if (fontSize != null) 'fontSize': fontSize,
    if (isTopic) 'isTopic': true,
  };

  factory TextAttribute.fromMap(Map<String, dynamic> map) => TextAttribute(
    start: map['start'] ?? 0,
    end: map['end'] ?? 0,
    color: map['color'] != null ? Color(map['color']) : null,
    backgroundColor: map['backgroundColor'] != null
        ? Color(map['backgroundColor'])
        : null,
    fontSize: map['fontSize']?.toDouble(),
    isTopic: map['isTopic'] ?? false,
  );
}

class TopicTextEditingController extends TextEditingController {
  Color baseColor;
  double baseFontSize;
  String baseFontFamily;
  late List<TextAttribute> attributes;

  TopicTextEditingController({
    String? text,
    Color? baseColor,
    double? baseFontSize,
    String? baseFontFamily,
    List<TextAttribute>? attributes,
  }) : baseColor =
           baseColor ??
           (UserState().isNight
               ? const Color(0xFFE0C097)
               : const Color(0xFF5D4037)),
       baseFontSize = baseFontSize ?? 20.0,
       baseFontFamily = baseFontFamily ?? 'LXGWWenKai',
       super(text: text) {
    this.attributes = attributes ?? [];
  }

  @override
  set value(TextEditingValue newValue) {
    final String oldText = value.text;
    final String newText = newValue.text;

    if (oldText != newText && attributes.isNotEmpty) {
      // 计算变化发生的起始点和长度差异
      int start = 0;
      while (start < oldText.length &&
          start < newText.length &&
          oldText[start] == newText[start]) {
        start++;
      }

      int oldEnd = oldText.length;
      int newEnd = newText.length;
      while (oldEnd > start &&
          newEnd > start &&
          oldText[oldEnd - 1] == newText[newEnd - 1]) {
        oldEnd--;
        newEnd--;
      }

      final int replaceLength = oldEnd - start;
      final int insertLength = newEnd - start;
      final int diff = insertLength - replaceLength;

      // 更新属性
      final List<TextAttribute> updatedAttributes = [];
      for (var attr in attributes) {
        int attrStart = attr.start;
        int attrEnd = attr.end;

        // 1. 完全在删除/替换区域之后的属性，平移
        if (attrStart >= oldEnd) {
          attrStart += diff;
          attrEnd += diff;
        }
        // 2. 包含或重叠在变化区域的属性，根据具体逻辑缩放或移动
        else if (attrEnd > start) {
          // 修改点在属性内部或紧邻后面
          if (attrStart >= start) {
            attrStart = (attrStart + diff).clamp(start, newText.length);
          }
          attrEnd = (attrEnd + diff).clamp(attrStart, newText.length);
        }

        if (attrStart < attrEnd &&
            attrStart >= 0 &&
            attrEnd <= newText.length) {
          updatedAttributes.add(
            TextAttribute(
              start: attrStart,
              end: attrEnd,
              color: attr.color,
              backgroundColor: attr.backgroundColor,
              fontSize: attr.fontSize,
              isTopic: attr.isTopic,
            ),
          );
        }
      }
      attributes.clear();
      attributes.addAll(updatedAttributes);
    }

    super.value = newValue;
  }

  void updateBaseColor(Color newColor) {
    if (baseColor != newColor) {
      baseColor = newColor;
      notifyListeners();
    }
  }

  void updateBaseFontSize(double newSize) {
    if (baseFontSize != newSize) {
      baseFontSize = newSize;
      notifyListeners();
    }
  }

  void updateBaseFontFamily(String newFamily) {
    if (baseFontFamily != newFamily) {
      baseFontFamily = newFamily;
      notifyListeners();
    }
  }

  /// 将前景色或背景色应用到指定选区（传入 null 表示清除该选区在该维度的属性）
  void applyAttributeToSelection(
    TextSelection selection, {
    Color? color,
    Color? bgColor,
    double? fontSize,
    bool clearColor = false,
    bool clearBgColor = false,
    bool clearFontSize = false,
    bool? isTopic,
  }) {
    if (selection.isCollapsed && isTopic == null) return;

    final start = selection.start;
    final end = selection.end;

    // 处理前景色逻辑
    if (clearColor || color != null) {
      attributes.removeWhere(
        (attr) =>
            attr.color != null &&
            ((attr.start >= start && attr.start < end) ||
                (attr.end > start && attr.end <= end) ||
                (attr.start <= start && attr.end >= end)),
      );
      if (color != null) {
        attributes.add(TextAttribute(start: start, end: end, color: color));
      }
    }

    // 处理背景色逻辑
    if (clearBgColor || bgColor != null) {
      attributes.removeWhere(
        (attr) =>
            attr.backgroundColor != null &&
            ((attr.start >= start && attr.start < end) ||
                (attr.end > start && attr.end <= end) ||
                (attr.start <= start && attr.end >= end)),
      );
      if (bgColor != null) {
        attributes.add(
          TextAttribute(start: start, end: end, backgroundColor: bgColor),
        );
      }
    }

    // 处理字号逻辑
    if (clearFontSize || fontSize != null) {
      attributes.removeWhere(
        (attr) =>
            attr.fontSize != null &&
            ((attr.start >= start && attr.start < end) ||
                (attr.end > start && attr.end <= end) ||
                (attr.start <= start && attr.end >= end)),
      );
      if (fontSize != null) {
        attributes.add(
          TextAttribute(start: start, end: end, fontSize: fontSize),
        );
      }
    }

    // 处理话题逻辑
    if (isTopic != null) {
      attributes.removeWhere(
        (attr) =>
            attr.isTopic &&
            ((attr.start >= start && attr.start < end) ||
                (attr.end > start && attr.end <= end) ||
                (attr.start <= start && attr.end >= end)),
      );
      if (isTopic) {
        attributes.add(TextAttribute(start: start, end: end, isTopic: true));
      }
    }

    // 2. 排序以优化渲染性能
    attributes.sort((a, b) => a.start.compareTo(b.start));

    notifyListeners();
  }

  @override
  TextSpan buildTextSpan({
    required BuildContext context,
    TextStyle? style,
    required bool withComposing,
    bool hideMarkdownSymbols = false, // 新增：是否隐藏 Markdown 符号（详情页使用）
  }) {
    final textContent = this.text;
    if (textContent.isEmpty) return TextSpan(style: style, text: textContent);

    final TextStyle rootStyle =
        style?.copyWith(
          color: baseColor,
          fontSize: baseFontSize,
          fontFamily: baseFontFamily,
          height: 1.6,
        ) ??
        TextStyle(
          color: baseColor,
          fontSize: baseFontSize,
          fontFamily: baseFontFamily,
          height: 1.6,
        );

    final List<Map<String, dynamic>> highlights = [];

    // 1. 话题范围 (仅手动标记，即：点击话题按钮插入的内容)
    // 根据用户要求，移除正则表达式自动识别话题的逻辑，
    // 确保只有点击图标输入的才是橙色话题，手动输入的 # 均为标题。

    // b. 手动标记的话题 (由按钮插入，具有 isTopic 属性)
    // 根据用户要求：只要探测到标记，就自动扩展到整个连续单词（从 # 到空格），解决编辑时断色问题。
    for (var attr in attributes) {
      if (attr.isTopic) {
        int start = attr.start.clamp(0, textContent.length);
        int end = attr.end.clamp(0, textContent.length);
        
        // 向前寻找 #
        while (start > 0 && textContent[start - 1] != '#' && !textContent[start - 1].contains(RegExp(r'\s'))) {
          start--;
        }
        if (start > 0 && textContent[start - 1] == '#') {
          start--;
        }
        
        // 向后寻找空格或换行
        while (end < textContent.length && !textContent[end].contains(RegExp(r'\s'))) {
          end++;
        }

        if (start >= end) continue;

        highlights.add({
          'start': start,
          'end': end,
          'style': const TextStyle(
            color: Color(0xFFE67E22),
            fontWeight: FontWeight.bold,
          ),
          'priority': 10,
        });
      }
    }

    // 2. 获取所有表情范围
    final emojiKeys = EmojiMapping.unicodeToPath.keys.toList()
      ..sort((a, b) => b.length.compareTo(a.length));
    final emojiPattern = emojiKeys.map((e) => "(?:${RegExp.escape(e)})[\ufe00-\ufe0f\u200d]*").join('|');

    final nameKeys = EmojiMapping.nameToPath.keys.toList()
      ..sort((a, b) => b.length.compareTo(a.length));
    final namePattern = nameKeys.map((e) => RegExp.escape('[$e]')).join('|');

    final pattern = [
      if (emojiPattern.isNotEmpty) emojiPattern,
      if (namePattern.isNotEmpty) namePattern,
    ].join('|');

    if (pattern.isNotEmpty) {
      final RegExp emojiRegExp = RegExp(pattern);
      for (final Match match in emojiRegExp.allMatches(textContent)) {
        final matchedStr = match.group(0)!;
        String? path;

        if (matchedStr.startsWith('[') && matchedStr.endsWith(']')) {
          final name = matchedStr.substring(1, matchedStr.length - 1);
          path = EmojiMapping.nameToPath[name];
        } else {
          path = EmojiMapping.getPathForEmoji(matchedStr);
        }

        if (path != null) {
          highlights.add({
            'start': match.start,
            'end': match.end,
            'emojiPath': path,
            'priority': 3,
          });
        }
      }
    }

    // 3. Markdown 支持
    final bool isNight = UserState().isNight;
    final baseSymbolStyle = TextStyle(
      color: (isNight ? Colors.white : Colors.black),
    );

    // 加粗: **text** 或 __text__
    final boldRegExp = RegExp(r'(\*\*|__)(.*?)\1');
    for (final match in boldRegExp.allMatches(textContent)) {
      final symbol = match.group(1)!;
      final bool isFocused =
          !hideMarkdownSymbols &&
          selection.start >= match.start &&
          selection.start <= match.end;

      final currentSymbolStyle = baseSymbolStyle.copyWith(
        color: baseSymbolStyle.color!.withOpacity(
          hideMarkdownSymbols ? 0 : (isFocused ? 0.3 : 0),
        ),
        fontSize: (hideMarkdownSymbols || !isFocused) ? 0.01 : baseFontSize,
      );

      final int start = match.start.clamp(0, textContent.length);
      final int end = match.end.clamp(0, textContent.length);
      final int sym1End = (start + symbol.length).clamp(0, textContent.length);
      final int sym2Start = (end - symbol.length).clamp(0, textContent.length);

      highlights.add({
        'start': start,
        'end': sym1End,
        'style': currentSymbolStyle,
        'priority': 4,
        'isSymbol': true,
      });
      highlights.add({
        'start': sym1End,
        'end': sym2Start,
        'style': const TextStyle(fontWeight: FontWeight.bold),
        'priority': 4,
      });
      highlights.add({
        'start': sym2Start,
        'end': end,
        'style': currentSymbolStyle,
        'priority': 4,
        'isSymbol': true,
      });
    }

    // 斜体: *text* 或 _text_
    final italicRegExp = RegExp(
      r'(?<!\*)\*(?!\*)(.*?)(?<!\*)\*(?!\*)|(?<!_)_(?!_)(.*?)(?<!_)_(?!_)',
    );
    for (final match in italicRegExp.allMatches(textContent)) {
      final bool isFocused =
          !hideMarkdownSymbols &&
          selection.start >= match.start &&
          selection.start <= match.end;
      final currentSymbolStyle = baseSymbolStyle.copyWith(
        color: baseSymbolStyle.color!.withOpacity(
          hideMarkdownSymbols ? 0 : (isFocused ? 0.3 : 0),
        ),
        fontSize: (hideMarkdownSymbols || !isFocused) ? 0.01 : baseFontSize,
      );

      final int start = match.start.clamp(0, textContent.length);
      final int end = match.end.clamp(0, textContent.length);
      final int sym1End = (start + 1).clamp(0, textContent.length);
      final int sym2Start = (end - 1).clamp(0, textContent.length);

      highlights.add({
        'start': start,
        'end': sym1End,
        'style': currentSymbolStyle,
        'priority': 4,
        'isSymbol': true,
      });
      highlights.add({
        'start': sym1End,
        'end': sym2Start,
        'style': const TextStyle(fontStyle: FontStyle.italic),
        'priority': 4,
      });
      highlights.add({
        'start': sym2Start,
        'end': end,
        'style': currentSymbolStyle,
        'priority': 4,
        'isSymbol': true,
      });
    }

    // 删除线: ~~text~~
    final strikeRegExp = RegExp(r'~~(.*?)~~');
    for (final match in strikeRegExp.allMatches(textContent)) {
      final bool isFocused =
          !hideMarkdownSymbols &&
          selection.start >= match.start &&
          selection.start <= match.end;
      final currentSymbolStyle = baseSymbolStyle.copyWith(
        color: baseSymbolStyle.color!.withOpacity(
          hideMarkdownSymbols ? 0 : (isFocused ? 0.3 : 0),
        ),
        fontSize: (hideMarkdownSymbols || !isFocused) ? 0.01 : baseFontSize,
      );

      final int start = match.start.clamp(0, textContent.length);
      final int end = match.end.clamp(0, textContent.length);
      final int sym1End = (start + 2).clamp(0, textContent.length);
      final int sym2Start = (end - 2).clamp(0, textContent.length);

      highlights.add({
        'start': start,
        'end': sym1End,
        'style': currentSymbolStyle,
        'priority': 4,
        'isSymbol': true,
      });
      highlights.add({
        'start': sym1End,
        'end': sym2Start,
        'style': const TextStyle(decoration: TextDecoration.lineThrough),
        'priority': 4,
      });
      highlights.add({
        'start': sym2Start,
        'end': end,
        'style': currentSymbolStyle,
        'priority': 4,
        'isSymbol': true,
      });
    }

    // 标题 (行首识别)
    final lines = textContent.split('\n');
    int currentOffset = 0;
    for (var line in lines) {
      final match = RegExp(r'(?:^|\s)(#+)\s*(.*)$').firstMatch(line);
      if (match != null) {
        final level = match.group(1)!.length;
        final hashGroup = match.group(1)!;
        final hashOffsetInMatch = match.group(0)!.indexOf(hashGroup);
        final startPos = currentOffset + match.start + hashOffsetInMatch;

        // 核心冲突处理：区分手动输入与按钮话题
        // 如果该位置的 # 带有 isTopic 属性（说明由话题按钮插入），则不将其识别为 Markdown 标题
        final isButtonTopic = attributes.any((attr) =>
            attr.isTopic && attr.start <= startPos && attr.end > startPos);

        if (!isButtonTopic) {
          // 标题颜色跟随文字的基础颜色 (baseColor)
          final headerColor = baseColor;

          final double headerFontSize = level == 1
              ? baseFontSize + 10
              : (level == 2 ? baseFontSize + 6 : baseFontSize + 4);

          final int lineEnd = (currentOffset + line.length).clamp(
            0,
            textContent.length,
          );
          final int symbolEnd = (startPos + hashGroup.length).clamp(
            0,
            textContent.length,
          );

          // 标题符号隐藏逻辑：仅当光标直接处于符号上方时才显示，输入内容后即自动隐藏
          final bool isSymbolFocused =
              !hideMarkdownSymbols &&
              selection.start >= startPos &&
              selection.start <= symbolEnd;

          final currentSymbolStyle = TextStyle(
            color: headerColor.withOpacity(
              hideMarkdownSymbols ? 0 : (isSymbolFocused ? 0.3 : 0),
            ),
            fontSize: (hideMarkdownSymbols || !isSymbolFocused)
                ? 0.01
                : headerFontSize,
          );

          // 为整行应用标题字号（低优先级），确保行内话题能正确继承大小
          highlights.add({
            'start': currentOffset,
            'end': lineEnd,
            'style': TextStyle(fontSize: headerFontSize),
            'priority': 0,
          });

          // 符号部分 (#)
          highlights.add({
            'start': startPos,
            'end': symbolEnd,
            'style': currentSymbolStyle,
            'priority': 5,
            'isSymbol': true,
          });
          // 文本部分
          highlights.add({
            'start': symbolEnd,
            'end': lineEnd,
            'style': TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: headerFontSize,
              color: headerColor,
            ),
            'priority': 5,
          });
        }
    }
      currentOffset += line.length + 1;
    }

    // 列表识别 (单独过滤识别避免冲突)
    currentOffset = 0;
    for (var line in lines) {
      final trimmedLine = line.trimLeft();
      if (trimmedLine.startsWith('- ') || trimmedLine.startsWith('* ')) {
        final startPos =
            (currentOffset + line.indexOf(trimmedLine.substring(0, 1))).clamp(
              0,
              textContent.length,
            );
        final endPos = (startPos + 2).clamp(0, textContent.length);
        highlights.add({
          'start': startPos,
          'end': endPos,
          'style': TextStyle(
            fontWeight: FontWeight.bold,
            color: isNight ? const Color(0xFFD4A373) : const Color(0xFF8B5E3C),
          ),
          'priority': 5,
        });
      }
      currentOffset += line.length + 1;
    }

    // 4. 获取所有手动属性范围
    for (var attr in attributes) {
      final start = attr.start.clamp(0, textContent.length);
      final end = attr.end.clamp(0, textContent.length);
      if (start >= end) continue;

      highlights.add({
        'start': start,
        'end': end,
        'style': TextStyle(
          color: attr.color,
          backgroundColor: attr.backgroundColor,
          fontSize: attr.fontSize,
          height: 1.6,
        ),
        'priority': 1,
      });
    }

    // --- 预处理：移除所有与话题（Priority 10）重叠的语法符号高亮 ---
    final List<Map<String, int>> topicRanges = highlights
        .where((h) => h['priority'] == 10)
        .map((h) => {'start': h['start'] as int, 'end': h['end'] as int})
        .toList();

    highlights.removeWhere((h) {
      if (h['isSymbol'] != true) return false;
      final int hStart = h['start'] as int;
      final int hEnd = h['end'] as int;
      return topicRanges.any(
        (tr) => hStart < tr['end']! && hEnd > tr['start']!,
      );
    });
    // -----------------------------------------------------------

    if (highlights.isEmpty) {
      return TextSpan(style: rootStyle, text: textContent);
    }

    // 4. 按照索引动态切分并在渲染时合并样式
    final Set<int> boundaries = {0, textContent.length};
    for (var h in highlights) {
      boundaries.add(h['start']);
      boundaries.add(h['end']);
    }
    
    // 过滤掉位于 Unicode 代理对 (Surrogate Pairs) 中间的边界，防止 substring 产生无效字符
    final sortedBoundaries = boundaries.toList()..sort();
    final List<int> safeBoundaries = [];
    for (int b in sortedBoundaries) {
      if (b > 0 && b < textContent.length) {
        final prev = textContent.codeUnitAt(b - 1);
        final next = textContent.codeUnitAt(b);
        // 如果 prev 是高代理且 next 是低代理，则 b 处于代理对中间，应跳过
        if (prev >= 0xD800 && prev <= 0xDBFF && next >= 0xDC00 && next <= 0xDFFF) {
          continue;
        }
      }
      safeBoundaries.add(b);
    }

    final List<InlineSpan> children = [];
    for (int i = 0; i < safeBoundaries.length - 1; i++) {
      final start = safeBoundaries[i];
      final end = safeBoundaries[i + 1];
      if (start >= end) continue;

      final chunk = textContent.substring(start, end);

      Map<String, dynamic>? emojiMatch;
      for (var h in highlights) {
        if (h['priority'] == 3 && start >= h['start'] && end <= h['end']) {
          emojiMatch = h;
          break;
        }
      }

      if (emojiMatch != null) {
        children.add(
          WidgetSpan(
            alignment: PlaceholderAlignment.middle,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 2.0),
              child: Image.asset(
                emojiMatch['emojiPath'],
                width: 20,
                height: 20,
                fit: BoxFit.contain,
              ),
            ),
          ),
        );
        continue;
      }

      TextStyle combinedStyle = rootStyle;
      final sortedHighlights = List<Map<String, dynamic>>.from(
        highlights,
      )..sort((a, b) => (a['priority'] as int).compareTo(b['priority'] as int));

      final bool isTopicSegment = highlights.any(
        (h) => h['priority'] == 10 && start >= h['start'] && end <= h['end'],
      );

      for (var h in sortedHighlights) {
        if (h['priority'] == 3) continue;
        if (start >= h['start'] && end <= h['end']) {
          combinedStyle = combinedStyle.merge(h['style'] as TextStyle?);
        }
      }

      // 最终保障：如果是话题片段，强制锁定样式，确保可见并保持颜色一致
      if (isTopicSegment) {
        combinedStyle = combinedStyle.copyWith(
          color: const Color(0xFFE67E22),
          fontWeight: FontWeight.bold,
          fontSize:
              (combinedStyle.fontSize != null && combinedStyle.fontSize! > 1)
              ? combinedStyle.fontSize
              : baseFontSize,
          decoration: TextDecoration.none,
        );
      }

      children.add(TextSpan(text: chunk, style: combinedStyle));
    }

    return TextSpan(style: rootStyle, children: children);
  }
}

class TextBlock extends DiaryBlock {
  final TextEditingController controller;
  final FocusNode focusNode;

  TextBlock(
    String text, {
    List<TextAttribute>? attributes,
    Color? baseColor,
    super.id,
  }) : controller = TopicTextEditingController(
         text: text,
         attributes: attributes,
         baseColor: baseColor,
       ),
       focusNode = FocusNode();

  @override
  Map<String, dynamic> toMap() {
    final tc = controller;
    if (tc is TopicTextEditingController) {
      return {
        'id': id,
        'type': 'text',
        'content': tc.text,
        'attributes': tc.attributes.map((a) => a.toMap()).toList(),
        'baseColor': tc.baseColor.value,
        'baseFontSize': tc.baseFontSize,
        'baseFontFamily': tc.baseFontFamily,
      };
    }
    return {'id': id, 'type': 'text', 'content': tc.text};
  }

  void dispose() {
    controller.dispose();
    focusNode.dispose();
  }
}

class ImageBlock extends DiaryBlock {
  final XFile file;
  final String? videoPath; // 实况图对应的视频路径

  ImageBlock(this.file, {super.id, this.videoPath});

  @override
  Map<String, dynamic> toMap() => {
    'id': id,
    'type': 'image',
    'path': file.path,
    if (videoPath != null) 'videoPath': videoPath,
  };
}

class AudioBlock extends DiaryBlock {
  final String path;
  final String name;

  AudioBlock(this.path, this.name, {super.id});

  @override
  Map<String, dynamic> toMap() => {
    'id': id,
    'type': 'audio',
    'path': path,
    'name': name,
  };
}
