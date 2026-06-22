import 'dart:convert';
import 'dart:typed_data';
import 'dart:ui' as ui;
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
        if (controller is DiaryTextEditingController) {
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
        final isFloating = map['isFloating'] as bool? ?? false;
        final floatAlignment = map['floatAlignment']?.toString() ?? 'left';
        return ImageBlock(
          XFile(path.toString()),
          id: id,
          videoPath: videoPath,
          isFloating: isFloating,
          floatAlignment: floatAlignment,
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
    } else if (type == 'sticker') {
      final path = map['path'];
      if (path != null && path.toString().isNotEmpty) {
        return StickerBlock(
          path.toString(),
          id: id,
          rotation: (map['rotation'] ?? 0.0).toDouble(),
          scale: (map['scale'] ?? 1.0).toDouble(),
          dx: (map['dx'] ?? 0.0).toDouble(),
          dy: (map['dy'] ?? 0.0).toDouble(),
        );
      }
      return TextBlock('');
    }
    return TextBlock('');
  }
}

/// 贴纸块
class StickerBlock extends DiaryBlock {
  final String path;
  double rotation;
  double scale;
  double dx; // 相对横向坐标
  double dy; // 相对纵向坐标

  StickerBlock(
    this.path, {
    super.id,
    this.rotation = 0.0,
    this.scale = 1.0,
    this.dx = 0.0,
    this.dy = 0.0,
  });

  @override
  Map<String, dynamic> toMap() => {
    'id': id,
    'type': 'sticker',
    'path': path,
    'rotation': rotation,
    'scale': scale,
    'dx': dx,
    'dy': dy,
  };
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

/// 文本属性记录（用于局部变色与样式）
class TextAttribute {
  final int start;
  final int end;
  final Color? color;
  final Color? backgroundColor;
  final double? fontSize;
  final bool? underline;
  final String? underlineStyle; // 新增下划线样式: solid, double, dashed, dotted, wavy, marker

  TextAttribute({
    required this.start,
    required this.end,
    this.color,
    this.backgroundColor,
    this.fontSize,
    this.underline,
    this.underlineStyle,
  });

  Map<String, dynamic> toMap() => {
    'start': start,
    'end': end,
    if (color != null) 'color': color!.toARGB32(),
    if (backgroundColor != null) 'backgroundColor': backgroundColor!.toARGB32(),
    if (fontSize != null) 'fontSize': fontSize,
    if (underline != null) 'underline': underline,
    if (underlineStyle != null) 'underlineStyle': underlineStyle,
  };

  factory TextAttribute.fromMap(Map<String, dynamic> map) => TextAttribute(
    start: map['start'] ?? 0,
    end: map['end'] ?? 0,
    color: map['color'] != null ? Color(map['color']) : null,
    backgroundColor: map['backgroundColor'] != null
        ? Color(map['backgroundColor'])
        : null,
    fontSize: map['fontSize']?.toDouble(),
    underline: map['underline'],
    underlineStyle: map['underlineStyle']?.toString(),
  );
}

class DiaryTextEditingController extends TextEditingController {
  static final Map<String, ui.Shader> _shaderCache = {};

  static TextStyle getUnderlineStyle({
    required String style,
    required Color color,
    required Color baseColor,
    double? fontSize,
  }) {
    if (style == 'marker') {
      return TextStyle(
        color: baseColor,
        fontSize: fontSize,
        height: 1.8,
        backgroundColor: color.withValues(alpha: 0.3),
      );
    }

    TextDecorationStyle decStyle;
    double thickness = 1.2;
    if (style == 'thick') {
      decStyle = TextDecorationStyle.solid;
      thickness = 3.0;
    } else if (style == 'double') {
      decStyle = TextDecorationStyle.double;
      thickness = 1.5;
    } else if (style == 'dashed') {
      decStyle = TextDecorationStyle.dashed;
      thickness = 1.2;
    } else if (style == 'dotted') {
      decStyle = TextDecorationStyle.dotted;
      thickness = 2.0;
    } else if (style == 'wavy') {
      decStyle = TextDecorationStyle.wavy;
      thickness = 1.2;
    } else if (style == 'handdrawn') {
      decStyle = TextDecorationStyle.wavy;
      thickness = 2.0;
    } else if (style == 'gradient') {
      decStyle = TextDecorationStyle.solid;
      thickness = 2.0;
    } else {
      decStyle = TextDecorationStyle.solid;
      thickness = 1.2;
    }

    return TextStyle(
      color: baseColor,
      fontSize: fontSize,
      height: 1.8,
      decoration: TextDecoration.underline,
      decorationStyle: decStyle,
      decorationColor: color,
      decorationThickness: thickness,
    );
  }

  static ui.Shader getUnderlineShader(String style, Color color, double rectHeight) {
    final key = "${style}_${color.toARGB32()}_${rectHeight.toStringAsFixed(1)}";
    if (_shaderCache.containsKey(key)) {
      return _shaderCache[key]!;
    }

    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke;

    final double fontSize = rectHeight / 1.8;
    final double y = fontSize * 1.6;

    if (style == 'circle') {
      paint.strokeWidth = 1.6;
      paint.strokeCap = StrokeCap.round;
      
      final double startY = rectHeight * 0.12;
      final double endY = rectHeight * 0.94;
      final double midY = startY + (endY - startY) / 2;
      
      final path = Path();
      // 使用贝塞尔曲线画一个稍带手绘抖动感的封闭椭圆
      path.moveTo(1.2, midY - 1);
      path.quadraticBezierTo(2.0, startY + 0.5, 7.0, startY);
      path.quadraticBezierTo(13.5, startY + 0.2, 13.5, midY + 0.8);
      path.quadraticBezierTo(13.2, endY - 0.5, 7.0, endY);
      path.quadraticBezierTo(1.0, endY - 0.2, 1.2, midY - 1);
      path.close();
      
      canvas.drawPath(path, paint);

      final picture = recorder.endRecording();
      final width = 14;
      final height = rectHeight.clamp(1.0, 1000.0).toInt();
      final img = picture.toImageSync(width, height);
      final shader = ImageShader(
        img,
        TileMode.repeated,
        TileMode.repeated,
        Float64List.fromList([
          1.0, 0.0, 0.0, 0.0,
          0.0, 1.0, 0.0, 0.0,
          0.0, 0.0, 1.0, 0.0,
          0.0, 0.0, 0.0, 1.0,
        ]),
      );
      _shaderCache[key] = shader;
      return shader;
    } else if (style == 'wavy') {
      paint.strokeWidth = 2.6; // 从 1.8 加粗到 2.6
      paint.strokeCap = StrokeCap.round;
      final path = Path();
      path.moveTo(0, y);
      path.quadraticBezierTo(3, y - 2.2, 6, y);
      path.quadraticBezierTo(9, y + 2.2, 12, y);
      canvas.drawPath(path, paint);

      final picture = recorder.endRecording();
      final width = 12;
      final height = rectHeight.clamp(1.0, 1000.0).toInt();
      final img = picture.toImageSync(width, height);
      final shader = ImageShader(
        img,
        TileMode.repeated,
        TileMode.repeated,
        Float64List.fromList([
          1.0, 0.0, 0.0, 0.0,
          0.0, 1.0, 0.0, 0.0,
          0.0, 0.0, 1.0, 0.0,
          0.0, 0.0, 0.0, 1.0,
        ]),
      );
      _shaderCache[key] = shader;
      return shader;
    } else if (style == 'dashed') {
      paint.strokeWidth = 2.6; // 从 1.8 加粗到 2.6
      paint.strokeCap = StrokeCap.round;
      canvas.drawLine(Offset(1, y), Offset(6, y), paint);
      final picture = recorder.endRecording();
      final width = 10;
      final height = rectHeight.clamp(1.0, 1000.0).toInt();
      final img = picture.toImageSync(width, height);
      final shader = ImageShader(
        img,
        TileMode.repeated,
        TileMode.repeated,
        Float64List.fromList([
          1.0, 0.0, 0.0, 0.0,
          0.0, 1.0, 0.0, 0.0,
          0.0, 0.0, 1.0, 0.0,
          0.0, 0.0, 0.0, 1.0,
        ]),
      );
      _shaderCache[key] = shader;
      return shader;
    } else if (style == 'dotted') {
      paint.strokeWidth = 3.2; // 从 2.4 加粗到 3.2
      paint.strokeCap = StrokeCap.round;
      canvas.drawLine(Offset(2, y), Offset(2.1, y), paint);
      final picture = recorder.endRecording();
      final width = 8;
      final height = rectHeight.clamp(1.0, 1000.0).toInt();
      final img = picture.toImageSync(width, height);
      final shader = ImageShader(
        img,
        TileMode.repeated,
        TileMode.repeated,
        Float64List.fromList([
          1.0, 0.0, 0.0, 0.0,
          0.0, 1.0, 0.0, 0.0,
          0.0, 0.0, 1.0, 0.0,
          0.0, 0.0, 0.0, 1.0,
        ]),
      );
      _shaderCache[key] = shader;
      return shader;
    } else if (style == 'double') {
      paint.strokeWidth = 1.4; // 从 1.0 加粗到 1.4
      canvas.drawLine(Offset(0, y - 1.8), Offset(10, y - 1.8), paint); // 间距和粗细按比例微调
      canvas.drawLine(Offset(0, y + 1.8), Offset(10, y + 1.8), paint);
      final picture = recorder.endRecording();
      final width = 10;
      final height = rectHeight.clamp(1.0, 1000.0).toInt();
      final img = picture.toImageSync(width, height);
      final shader = ImageShader(
        img,
        TileMode.repeated,
        TileMode.repeated,
        Float64List.fromList([
          1.0, 0.0, 0.0, 0.0,
          0.0, 1.0, 0.0, 0.0,
          0.0, 0.0, 1.0, 0.0,
          0.0, 0.0, 0.0, 1.0,
        ]),
      );
      _shaderCache[key] = shader;
      return shader;
    } else if (style == 'handdrawn') {
      paint.strokeWidth = 2.8; // 从 2.0 加粗到 2.8
      paint.strokeCap = StrokeCap.round;
      final path = Path();
      path.moveTo(0, y + 0.4);
      path.quadraticBezierTo(3, y - 0.8, 6, y + 0.6);
      path.quadraticBezierTo(9, y - 0.6, 12, y + 0.3);
      canvas.drawPath(path, paint);

      final picture = recorder.endRecording();
      final width = 12;
      final height = rectHeight.clamp(1.0, 1000.0).toInt();
      final img = picture.toImageSync(width, height);
      final shader = ImageShader(
        img,
        TileMode.repeated,
        TileMode.repeated,
        Float64List.fromList([
          1.0, 0.0, 0.0, 0.0,
          0.0, 1.0, 0.0, 0.0,
          0.0, 0.0, 1.0, 0.0,
          0.0, 0.0, 0.0, 1.0,
        ]),
      );
      _shaderCache[key] = shader;
      return shader;
    } else if (style == 'thick') {
      final shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          Colors.transparent,
          Colors.transparent,
          color,
          color,
          Colors.transparent,
          Colors.transparent,
        ],
        stops: const [
          0.0,
          0.77, // 从 0.83 下移，增加厚度
          0.79,
          0.94, // 从 0.93 展宽
          0.96,
          1.0,
        ],
        tileMode: TileMode.repeated,
      ).createShader(Rect.fromLTWH(0, 0, 1, rectHeight));
      _shaderCache[key] = shader;
      return shader;
    } else if (style == 'marker') {
      final shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          Colors.transparent,
          Colors.transparent,
          color.withValues(alpha: 0.35),
          color.withValues(alpha: 0.35),
          Colors.transparent,
          Colors.transparent,
        ],
        stops: const [
          0.0,
          0.28,
          0.30,
          0.58,
          0.60,
          1.0,
        ],
        tileMode: TileMode.repeated,
      ).createShader(Rect.fromLTWH(0, 0, 1, rectHeight));
      _shaderCache[key] = shader;
      return shader;
    } else if (style == 'gradient') {
      final gradientShader = LinearGradient(
        colors: [
          const Color(0xFFFF5E62), // 红
          const Color(0xFFFF9966), // 橙
          const Color(0xFFFFD97D), // 黄
          const Color(0xFFC8E688), // 黄绿
          const Color(0xFF6DE195), // 绿
          const Color(0xFF4DE2C6), // 青
          const Color(0xFF3498DB), // 蓝
          const Color(0xFF667EEA), // 靛
          const Color(0xFF9B59B6), // 紫
          const Color(0xFF667EEA), // 靛
          const Color(0xFF3498DB), // 蓝
          const Color(0xFF4DE2C6), // 青
          const Color(0xFF6DE195), // 绿
          const Color(0xFFC8E688), // 黄绿
          const Color(0xFFFFD97D), // 黄
          const Color(0xFFFF9966), // 橙
        ],
      ).createShader(Rect.fromLTWH(0, 0, 160, rectHeight));
      
      paint.shader = gradientShader;
      paint.strokeWidth = 3.0; // 从 2.0 加粗到 3.0
      canvas.drawLine(Offset(0, y), Offset(160, y), paint);
      final picture = recorder.endRecording();
      final width = 160;
      final height = rectHeight.clamp(1.0, 1000.0).toInt();
      final img = picture.toImageSync(width, height);
      final shader = ImageShader(
        img,
        TileMode.repeated,
        TileMode.repeated,
        Float64List.fromList([
          1.0, 0.0, 0.0, 0.0,
          0.0, 1.0, 0.0, 0.0,
          0.0, 0.0, 1.0, 0.0,
          0.0, 0.0, 0.0, 1.0,
        ]),
      );
      _shaderCache[key] = shader;
      return shader;
    }

    // Default 'solid' style (加粗)
    final shader = LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [
        Colors.transparent,
        Colors.transparent,
        color,
        color,
        Colors.transparent,
        Colors.transparent,
      ],
      stops: const [
        0.0,
        0.83, // 从 0.87 下移，使起始位置更早，增加厚度
        0.85,
        0.93, // 从 0.91 展宽，使线条更粗壮
        0.95,
        1.0,
      ],
      tileMode: TileMode.repeated,
    ).createShader(Rect.fromLTWH(0, 0, 1, rectHeight));
    _shaderCache[key] = shader;
    return shader;
  }

  Color baseColor;
  double baseFontSize;
  String baseFontFamily;
  late List<TextAttribute> attributes;
  Map<String, String>? annotations;
  void Function(String key)? onAnnotationTap;
  int blockIndex = 0; // 记录当前的 blockIndex

  DiaryTextEditingController({
    super.text,
    Color? baseColor,
    double? baseFontSize,
    String? baseFontFamily,
    List<TextAttribute>? attributes,
    this.annotations,
    this.onAnnotationTap,
    this.blockIndex = 0,
  }) : baseColor =
           baseColor ??
           (UserState().isNight
               ? const Color(0xFFE0C097)
               : const Color(0xFF5D4037)),
       baseFontSize = baseFontSize ?? 20.0,
       baseFontFamily = baseFontFamily ?? 'LXGWWenKai' {
    this.attributes = attributes ?? [];
  }

  @override
  set value(TextEditingValue newValue) {
    TextEditingValue finalValue = newValue;

    // 原子删除表情标签逻辑已废弃
    // 现在使用 PUA 字符，每个表情就是一个单字符，退格键天然支持原子删除，不需要任何特殊拦截。

    final String oldText = value.text;
    final String newText = finalValue.text;

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
            ),
          );
        }
      }
      attributes.clear();
      attributes.addAll(updatedAttributes);
    }

    super.value = finalValue;
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
    bool? underline,
    String? underlineStyle,
    bool clearColor = false,
    bool clearBgColor = false,
    bool clearFontSize = false,
    bool clearUnderline = false,
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

    // 处理下划线逻辑
    if (clearUnderline || underline != null || underlineStyle != null) {
      attributes.removeWhere(
        (attr) =>
            (attr.underline != null || attr.underlineStyle != null) &&
            ((attr.start >= start && attr.start < end) ||
                (attr.end > start && attr.end <= end) ||
                (attr.start <= start && attr.end >= end)),
      );
      if (underlineStyle != null) {
        attributes.add(
          TextAttribute(
            start: start,
            end: end,
            underline: true,
            underlineStyle: underlineStyle,
          ),
        );
      } else if (underline == true) {
        attributes.add(
          TextAttribute(
            start: start,
            end: end,
            underline: true,
            underlineStyle: 'solid',
          ),
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
    bool hideMarkdownSymbols = false,
    Map<String, String>? annotations,
    int blockIndex = 0,
    void Function(String key)? onAnnotationTap,
    bool trimTrailing = false,
  }) {
    final textContent = trimTrailing ? text.trimRight() : text;
    if (textContent.isEmpty) return TextSpan(style: style, text: textContent);

    final int effectiveBlockIndex = blockIndex != 0 ? blockIndex : this.blockIndex;
    final List<Map<String, dynamic>> blockAnnotations = [];
    final effectiveAnnotations = annotations ?? this.annotations;
    final effectiveOnAnnotationTap = onAnnotationTap ?? this.onAnnotationTap;

    if (effectiveAnnotations != null) {
      effectiveAnnotations.forEach((key, value) {
        final parts = key.split('_');
        if (parts.length == 3 && int.tryParse(parts[0]) == effectiveBlockIndex) {
          final startVal = int.tryParse(parts[1]);
          final endVal = int.tryParse(parts[2]);
          if (startVal != null && endVal != null) {
            int start = startVal;
            int end = endVal;
            // 裁剪掉批注高亮范围末尾的换行符和空格，防止气泡图标换行
            while (end > start && end <= textContent.length &&
                (textContent[end - 1] == '\n' ||
                 textContent[end - 1] == '\r' ||
                 textContent[end - 1] == ' ' ||
                 textContent[end - 1] == '\u200B')) {
              end--;
            }

            Map<String, dynamic>? data;
            try {
              data = jsonDecode(value);
            } catch (_) {}
            
            final colorHex = data?['colorHex'] ?? '#F7E5B4';
            final comment = data?['comment'] ?? value;
            
            blockAnnotations.add({
              'key': key,
              'start': start,
              'end': end,
              'color': Color(int.parse(colorHex.replaceFirst('#', '0xFF'))),
              'comment': comment,
            });
          }
        }
      });
    }

    final TextStyle rootStyle =
        style?.copyWith(
          color: baseColor,
          fontSize: baseFontSize,
          fontFamily: baseFontFamily,
          height: 1.8,
        ) ??
        TextStyle(
          color: baseColor,
          fontSize: baseFontSize,
          fontFamily: baseFontFamily,
          height: 1.8,
        );

    final List<Map<String, dynamic>> highlights = [];

    for (var ann in blockAnnotations) {
      highlights.add({
        'start': ann['start'],
        'end': ann['end'],
        'style': const TextStyle(), // 仅用于分割边界，背景色使用 WidgetSpan 渲染
        'priority': 8,
      });
    }

    // 1. 获取所有表情范围
    final String pattern = EmojiMapping.pattern;

    if (pattern.isNotEmpty) {
      final RegExp emojiRegExp = RegExp(pattern);
      for (final Match match in emojiRegExp.allMatches(textContent)) {
        final matchedStr = match.group(0)!;
        final path = EmojiMapping.getPathForEmoji(matchedStr);

        if (path != null) {
          highlights.add({
            'start': match.start,
            'end': match.end,
            'emojiPath': path,
            'priority': 2,
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
        color: baseSymbolStyle.color!.withValues(alpha: 
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
        color: baseSymbolStyle.color!.withValues(alpha: 
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
        color: baseSymbolStyle.color!.withValues(alpha: 
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
        final hashGroup = match.group(1)!;
        final level = hashGroup.length;
        final startPos = (currentOffset + line.indexOf(hashGroup)).clamp(0, textContent.length);

        // 标题颜色跟随文字的基础颜色 (baseColor)
        final headerColor = baseColor;

        final double headerFontSize =
            level == 1
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
          color: headerColor.withValues(alpha: 
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
      currentOffset += line.length + 1;
    }

    // 列表识别 (单独过滤识别避免冲突)
    currentOffset = 0;
    for (var line in lines) {
      final trimmedLine = line.trimLeft();
      if (trimmedLine.startsWith('- ') || trimmedLine.startsWith('* ')) {
        final startChar = trimmedLine.substring(0, 1);
        final startPos =
            (currentOffset + line.indexOf(startChar)).clamp(
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

      final bool hasUnderline = attr.underline == true || attr.underlineStyle != null;
      highlights.add({
        'start': start,
        'end': end,
        'style': hasUnderline
            ? () {
                final double fs = attr.fontSize ?? baseFontSize;
                const double lh = 1.8;
                final double rectHeight = fs * lh;
                final String style = attr.underlineStyle ?? 'solid';
                if (style.startsWith('circle')) {
                  return TextStyle(
                    color: attr.color ?? baseColor,
                    fontSize: attr.fontSize,
                    height: 1.8,
                  );
                }
                final lineColor = attr.color ?? () {
                  switch (style) {
                    case 'solid': return const Color(0xFF4A90E2);
                    case 'thick': return const Color(0xFF2ECC71);
                    case 'double': return const Color(0xFF9B59B6);
                    case 'dashed': return const Color(0xFFE67E22);
                    case 'dotted': return const Color(0xFFE91E63);
                    case 'wavy': return const Color(0xFF1ABC9C);
                    case 'handdrawn': return const Color(0xFFE74C3C);
                    case 'marker': return const Color(0xFFF1C40F);
                    case 'gradient': return const Color(0xFF3498DB);
                    default: return isNight ? const Color(0xFFE0C097) : const Color(0xFFA68565);
                  }
                }();
                return TextStyle(
                  color: attr.color ?? baseColor,
                  fontSize: attr.fontSize,
                  height: 1.8,
                  background: Paint()
                    ..shader = DiaryTextEditingController.getUnderlineShader(style, lineColor, rectHeight),
                );
              }()
            : TextStyle(
                color: attr.color,
                backgroundColor: attr.backgroundColor,
                fontSize: attr.fontSize,
                height: 1.8,
              ),
        'priority': 1,
      });
    }

    // -----------------------------------------------------------

    if (highlights.isEmpty) {
      return TextSpan(style: rootStyle, text: textContent);
    }

    // 4. 按照索引动态切分并在渲染时合并样式
    final int len = textContent.length;
    final Set<int> boundaries = {0, len};
    for (var h in highlights) {
      final int s = (h['start'] as int).clamp(0, len);
      final int e = (h['end'] as int).clamp(s, len);
      boundaries.add(s);
      boundaries.add(e);
    }

    // 过滤掉位于 Unicode 代理对 (Surrogate Pairs) 中间的边界，防止 substring 产生无效字符
    final sortedBoundaries = boundaries.toList()..sort();
    final List<int> safeBoundaries = [];
    for (int b in sortedBoundaries) {
      if (b > 0 && b < textContent.length) {
        final prev = textContent.codeUnitAt(b - 1);
        final next = textContent.codeUnitAt(b);
        // 如果 prev 是高代理且 next 是低代理，则 b 处于代理对中间，应跳过
        if (prev >= 0xD800 &&
            prev <= 0xDBFF &&
            next >= 0xDC00 &&
            next <= 0xDFFF) {
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

      TextStyle combinedStyle = rootStyle;
      final sortedHighlights = List<Map<String, dynamic>>.from(
        highlights,
      )..sort((a, b) => (a['priority'] as int).compareTo(b['priority'] as int));

      for (var h in sortedHighlights) {
        if (start >= h['start'] && end <= h['end'] && h['style'] != null) {
          combinedStyle = combinedStyle.merge(h['style']);
        }
      }

      Map<String, dynamic>? emojiMatch;
      for (var h in highlights) {
        if (h['emojiPath'] != null && start >= h['start'] && end <= h['end']) {
          emojiMatch = h;
          break;
        }
      }

      if (emojiMatch != null) {
        // PUA 字符渲染极简模式：
        // 这个 chunk 实际上就是一个不可见的 PUA 字符
        // 我们直接把它替换成图片，不需要任何隐藏文本的玄学逻辑！
        children.add(
          WidgetSpan(
            alignment: PlaceholderAlignment.middle,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 1.0), // 稍微减小间距，让排版更紧凑
              child: Image.asset(
                emojiMatch['emojiPath'],
                width: combinedStyle.fontSize! * 1.45,
                height: combinedStyle.fontSize! * 1.45,
                fit: BoxFit.contain,
              ),
            ),
          ),
        );
        continue;
      }

      // 判断当前 chunk 是否属于批注高亮范围
      Map<String, dynamic>? activeAnnotation;
      for (var ann in blockAnnotations) {
        if (start >= ann['start'] && end <= ann['end']) {
          activeAnnotation = ann;
          break;
        }
      }

      if (activeAnnotation != null) {
        final Color color = (activeAnnotation['color'] as Color).withValues(alpha: 0.4);
        children.add(
          TextSpan(
            text: chunk,
            style: combinedStyle.copyWith(
              backgroundColor: color,
              height: 1.15,
            ),
          ),
        );
      } else {
        children.add(TextSpan(text: chunk, style: combinedStyle));
      }

      // Append bubble icon if this chunk ends exactly at an annotation's end
      for (var ann in blockAnnotations) {
        if (end == ann['end']) {
          final annKey = ann['key'] as String;
          children.add(
            WidgetSpan(
              alignment: PlaceholderAlignment.top,
              child: SelectionContainer.disabled(
                child: Padding(
                  padding: const EdgeInsets.only(left: 1),
                  child: SizedBox(
                    width: 20,
                    height: 18,
                    child: Listener(
                      behavior: HitTestBehavior.opaque,
                      onPointerDown: (_) {
                        if (effectiveOnAnnotationTap != null) {
                          effectiveOnAnnotationTap(annKey);
                        }
                      },
                      child: CustomPaint(
                        painter: _CommentBubblePainter(
                          fillColor: isNight ? const Color(0xFF3E3A36) : const Color(0xFFFDFBF7),
                          strokeColor: isNight ? Colors.white38 : const Color(0xFF8B7355).withValues(alpha: 0.5),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          );
        }
      }
    }

    // 如果末尾是 WidgetSpan，增加一个微小的空节点，以解决 WidgetSpan (如气泡或表情) 作为行末元素时在只读模式下折行、或在编辑模式下光标无法落位的问题
    if (children.isNotEmpty && children.last is WidgetSpan) {
      children.add(const TextSpan(text: '\u200B' , style: TextStyle(fontSize: 0.001)));
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
  }) : controller = DiaryTextEditingController(
         text: text,
         attributes: attributes,
         baseColor: baseColor,
       ),
       focusNode = FocusNode();

  @override
  Map<String, dynamic> toMap() {
    final tc = controller;
    if (tc is DiaryTextEditingController) {
      return {
        'id': id,
        'type': 'text',
        'content': tc.text,
        'attributes': tc.attributes.map((a) => a.toMap()).toList(),
        'baseColor': tc.baseColor.toARGB32(),
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
  final String? localPath; // 编辑时本地缓存或原图路径
  final bool isUploading; // 是否正在上传
  bool isFloating;
  String floatAlignment; // 'left' or 'right'

  ImageBlock(
    this.file, {
    super.id,
    this.videoPath,
    this.localPath,
    this.isUploading = false,
    this.isFloating = false,
    this.floatAlignment = 'left',
  });

  @override
  Map<String, dynamic> toMap() => {
    'id': id,
    'type': 'image',
    'path': file.path,
    if (videoPath != null) 'videoPath': videoPath,
    'isFloating': isFloating,
    'floatAlignment': floatAlignment,
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

class _CommentBubblePainter extends CustomPainter {
  final Color fillColor;
  final Color strokeColor;

  _CommentBubblePainter({
    required this.fillColor,
    required this.strokeColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = fillColor
      ..style = PaintingStyle.fill;

    final strokePaint = Paint()
      ..color = strokeColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.8;

    final path = Path();
    
    double w = size.width;
    double h = size.height;
    double mainH = h - 3; // 留出 3px 给底部的尖角

    // 画圆角矩形主体
    final rect = RRect.fromRectAndRadius(
      Rect.fromLTWH(0, 0, w, mainH),
      const Radius.circular(5),
    );
    path.addRRect(rect);

    // 在左下角拉出一个三角尖角指向文字
    final trianglePath = Path()
      ..moveTo(4, mainH)
      ..lineTo(1, h)
      ..lineTo(8, mainH)
      ..close();

    // 合并路径
    final combinedPath = Path.combine(PathOperation.union, path, trianglePath);

    canvas.drawPath(combinedPath, paint);
    canvas.drawPath(combinedPath, strokePaint);

    // 画三个小点。小点在主体矩形的正中央。
    final dotPaint = Paint()
      ..color = strokeColor.withValues(alpha: 0.8)
      ..style = PaintingStyle.fill;

    double centerY = mainH / 2;
    double centerX = w / 2;
    double dotSpacing = 3.5;
    
    canvas.drawCircle(Offset(centerX - dotSpacing, centerY), 0.7, dotPaint);
    canvas.drawCircle(Offset(centerX, centerY), 0.7, dotPaint);
    canvas.drawCircle(Offset(centerX + dotSpacing, centerY), 0.7, dotPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class TextWrapGroupBlock extends DiaryBlock {
  final ImageBlock imageBlock;
  final TextBlock textBlock;
  final String alignment; // 'left' or 'right'

  TextWrapGroupBlock({
    required this.imageBlock,
    required this.textBlock,
    required this.alignment,
    super.id,
  });

  @override
  Map<String, dynamic> toMap() => {};
}
