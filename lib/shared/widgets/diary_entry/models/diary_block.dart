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
        return ImageBlock(
          XFile(path.toString()), 
          id: id, 
          videoPath: videoPath,
        );
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

  TextAttribute({
    required this.start,
    required this.end,
    this.color,
    this.backgroundColor,
    this.fontSize,
  });

  Map<String, dynamic> toMap() => {
    'start': start,
    'end': end,
    if (color != null) 'color': color!.value,
    if (backgroundColor != null) 'backgroundColor': backgroundColor!.value,
    if (fontSize != null) 'fontSize': fontSize,
  };

  factory TextAttribute.fromMap(Map<String, dynamic> map) => TextAttribute(
    start: map['start'] ?? 0,
    end: map['end'] ?? 0,
    color: map['color'] != null ? Color(map['color']) : null,
    backgroundColor: map['backgroundColor'] != null
        ? Color(map['backgroundColor'])
        : null,
    fontSize: map['fontSize']?.toDouble(),
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
  }) : baseColor = baseColor ??
            (UserState().isNight
                ? const Color(0xFFE0C097)
                : const Color(0xFF5D4037)),
       baseFontSize = baseFontSize ?? 20.0,
       baseFontFamily = baseFontFamily ?? 'LXGWWenKai',
       super(text: text) {
    this.attributes = attributes ?? [];
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
  }) {
    if (selection.isCollapsed) return;

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

    // 2. 排序以优化渲染性能
    attributes.sort((a, b) => a.start.compareTo(b.start));

    notifyListeners();
  }

  @override
  TextSpan buildTextSpan({
    required BuildContext context,
    TextStyle? style,
    required bool withComposing,
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

    // 1. 获取所有正则话题范围
    final RegExp topicRegExp = RegExp(r'#[^\s#]*', multiLine: true);
    for (final Match match in topicRegExp.allMatches(textContent)) {
      highlights.add({
        'start': match.start,
        'end': match.end,
        'style': const TextStyle(
          color: Color(0xFFE67E22),
          fontWeight: FontWeight.bold,
          height: 1.6,
        ),
        'priority': 2,
      });
    }

    // 2. 获取所有表情范围
    final emojiKeys = EmojiMapping.unicodeToPath.keys.toList()..sort((a, b) => b.length.compareTo(a.length));
    final emojiPattern = emojiKeys.map((e) => RegExp.escape(e)).join('|');
    
    final nameKeys = EmojiMapping.nameToPath.keys.toList()..sort((a, b) => b.length.compareTo(a.length));
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

    // 3. 获取所有手动属性范围
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

    if (highlights.isEmpty) {
      return TextSpan(style: rootStyle, text: textContent);
    }

    // 4. 按照索引动态切分并在渲染时合并样式
    final Set<int> boundaries = {0, textContent.length};
    for (var h in highlights) {
      boundaries.add(h['start']);
      boundaries.add(h['end']);
    }
    final sortedBoundaries = boundaries.toList()..sort();

    final List<InlineSpan> children = [];
    for (int i = 0; i < sortedBoundaries.length - 1; i++) {
      final start = sortedBoundaries[i];
      final end = sortedBoundaries[i + 1];
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
        children.add(WidgetSpan(
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
        ));
        continue;
      }

      TextStyle combinedStyle = rootStyle;
      for (var h in highlights) {
        if (h['priority'] == 1 && start >= h['start'] && end <= h['end']) {
          combinedStyle = combinedStyle.merge(h['style']);
        } else if (h['priority'] == 2 && start >= h['start'] && end <= h['end']) {
          combinedStyle = combinedStyle.merge(h['style']);
        }
      }

      children.add(TextSpan(text: chunk, style: combinedStyle));
    }

    return TextSpan(style: rootStyle, children: children);
  }
}

class TextBlock extends DiaryBlock {
  final TextEditingController controller;
  final FocusNode focusNode;

  TextBlock(String text, {List<TextAttribute>? attributes, Color? baseColor, super.id})
    : controller = TopicTextEditingController(
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
