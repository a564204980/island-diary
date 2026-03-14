import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:uuid/uuid.dart';

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
        }
      }
      return block;
    } else if (type == 'image') {
      final path = map['path'];
      if (path != null && path.toString().isNotEmpty) {
        return ImageBlock(XFile(path.toString()), id: id);
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
  late List<TextAttribute> attributes;

  TopicTextEditingController({
    String? text,
    Color? baseColor,
    double? baseFontSize,
    List<TextAttribute>? attributes,
  }) : baseColor = baseColor ?? const Color(0xFF5D4037),
       baseFontSize = baseFontSize ?? 20.0,
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
          height: 1.6,
        ) ??
        TextStyle(color: baseColor, fontSize: baseFontSize, height: 1.6);

    // 1. 获取所有正则话题范围
    final RegExp regExp = RegExp(r'#[^\s#]+', multiLine: true);
    final List<Map<String, dynamic>> highlights = [];

    for (final Match match in regExp.allMatches(textContent)) {
      highlights.add({
        'start': match.start,
        'end': match.end,
        'style': const TextStyle(
          color: Color(0xFFE67E22),
          fontWeight: FontWeight.bold,
          decoration: TextDecoration.underline,
          decorationColor: Color(0xFFE67E22),
          height: 1.6,
        ),
        'priority': 2,
      });
    }

    // 2. 获取所有手动属性范围
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

    // 3. 按照索引动态切分并在渲染时合并样式
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

      TextStyle combinedStyle = rootStyle;
      // 先应用手动属性（低优先级）
      for (var h in highlights) {
        if (h['priority'] == 1 && start >= h['start'] && end <= h['end']) {
          combinedStyle = combinedStyle.merge(h['style']);
        }
      }
      // 后应用话题样式（高优先级），确保话题样式能覆盖手动设置的颜色但不破坏基础字体/行高
      for (var h in highlights) {
        if (h['priority'] == 2 && start >= h['start'] && end <= h['end']) {
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

  TextBlock(String text, {List<TextAttribute>? attributes, super.id})
    : controller = TopicTextEditingController(
        text: text,
        attributes: attributes,
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

  ImageBlock(this.file, {super.id});

  @override
  Map<String, dynamic> toMap() => {
    'id': id,
    'type': 'image',
    'path': file.path,
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
