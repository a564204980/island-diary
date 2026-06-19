import 'package:flutter/material.dart';

class ExportPageSize {
  final String name;
  final double width;
  final double height;

  const ExportPageSize({
    required this.name,
    required this.width,
    required this.height,
  });

  static const List<ExportPageSize> presets = [
    ExportPageSize(name: 'A4 纸张', width: 595, height: 842),
    ExportPageSize(name: 'A5 纸张', width: 420, height: 595),
    ExportPageSize(name: 'Letter', width: 612, height: 792),
    ExportPageSize(name: '手机屏幕', width: 375, height: 812),
    ExportPageSize(name: '自定义尺寸', width: 500, height: 700),
  ];

  Map<String, dynamic> toMap() => {
        'name': name,
        'width': width,
        'height': height,
      };

  factory ExportPageSize.fromMap(Map<String, dynamic> map) {
    return ExportPageSize(
      name: map['name'] ?? '自定义尺寸',
      width: (map['width'] as num?)?.toDouble() ?? 595.0,
      height: (map['height'] as num?)?.toDouble() ?? 842.0,
    );
  }
}

class ExportPageMargin {
  double top;
  double bottom;
  double left;
  double right;

  ExportPageMargin({
    this.top = 40.0,
    this.bottom = 40.0,
    this.left = 30.0,
    this.right = 30.0,
  });

  ExportPageMargin copy() => ExportPageMargin(
        top: top,
        bottom: bottom,
        left: left,
        right: right,
      );

  Map<String, dynamic> toMap() => {
        'top': top,
        'bottom': bottom,
        'left': left,
        'right': right,
      };

  factory ExportPageMargin.fromMap(Map<String, dynamic> map) {
    return ExportPageMargin(
      top: (map['top'] as num?)?.toDouble() ?? 40.0,
      bottom: (map['bottom'] as num?)?.toDouble() ?? 40.0,
      left: (map['left'] as num?)?.toDouble() ?? 30.0,
      right: (map['right'] as num?)?.toDouble() ?? 30.0,
    );
  }
}

class ExportBackgroundSettings {
  Color color;
  String? imagePath; // 可选的背景图片
  double opacity;
  double x;
  double y;
  double scale;
  String? cropRatio;

  ExportBackgroundSettings({
    this.color = const Color(0xFFE8F4F8),
    this.imagePath,
    this.opacity = 1.0,
    this.x = 0.0,
    this.y = 0.0,
    this.scale = 1.0,
    this.cropRatio,
  });

  ExportBackgroundSettings copy() => ExportBackgroundSettings(
        color: color,
        imagePath: imagePath,
        opacity: opacity,
        x: x,
        y: y,
        scale: scale,
        cropRatio: cropRatio,
      );

  Map<String, dynamic> toMap() => {
        'color': color.value,
        'imagePath': imagePath,
        'opacity': opacity,
        'x': x,
        'y': y,
        'scale': scale,
        'cropRatio': cropRatio,
      };

  factory ExportBackgroundSettings.fromMap(Map<String, dynamic> map) {
    return ExportBackgroundSettings(
      color: Color(map['color'] as int? ?? 0xFFE8F4F8),
      imagePath: map['imagePath'] as String?,
      opacity: (map['opacity'] as num?)?.toDouble() ?? 1.0,
      x: (map['x'] as num?)?.toDouble() ?? 0.0,
      y: (map['y'] as num?)?.toDouble() ?? 0.0,
      scale: (map['scale'] as num?)?.toDouble() ?? 1.0,
      cropRatio: map['cropRatio'] as String?,
    );
  }
}

class ExportElement {
  final String id;
  final String type; // 'text', 'image', 'shape', 'line', 'chart'
  double x;
  double y;
  double width;
  double height;
  String content; // 文本内容、图片路径、或者形状类型、图表类型
  double fontSize;
  Color color;
  bool isLocked;
  bool isVisible;
  double rotation;
  String fontFamily;
  String fontWeight;
  String fontStyle;
  String textDecoration;
  String textAlign;
  double letterSpacing;
  double lineHeight;
  double opacity;
  double borderRadius;
  String? cropRatio;
  Color? textBackgroundColor;
  double textBackgroundBorderRadius;
  double textBackgroundOpacity;
  double textBackgroundPadding;

  ExportElement({
    required this.id,
    required this.type,
    required this.x,
    required this.y,
    required this.width,
    required this.height,
    required this.content,
    this.fontSize = 18.0,
    this.color = Colors.black87,
    this.isLocked = false,
    this.isVisible = true,
    this.rotation = 0.0,
    this.fontFamily = '系统内置',
    this.fontWeight = 'normal',
    this.fontStyle = 'normal',
    this.textDecoration = 'none',
    this.textAlign = 'left',
    this.letterSpacing = 0.0,
    this.lineHeight = 1.2,
    this.opacity = 1.0,
    this.borderRadius = 0.0,
    this.cropRatio,
    this.textBackgroundColor,
    this.textBackgroundBorderRadius = 0.0,
    this.textBackgroundOpacity = 1.0,
    this.textBackgroundPadding = 0.0,
  });

  ExportElement copy() => ExportElement(
        id: id,
        type: type,
        x: x,
        y: y,
        width: width,
        height: height,
        content: content,
        fontSize: fontSize,
        color: color,
        isLocked: isLocked,
        isVisible: isVisible,
        rotation: rotation,
        fontFamily: fontFamily,
        fontWeight: fontWeight,
        fontStyle: fontStyle,
        textDecoration: textDecoration,
        textAlign: textAlign,
        letterSpacing: letterSpacing,
        lineHeight: lineHeight,
        opacity: opacity,
        borderRadius: borderRadius,
        cropRatio: cropRatio,
        textBackgroundColor: textBackgroundColor,
        textBackgroundBorderRadius: textBackgroundBorderRadius,
        textBackgroundOpacity: textBackgroundOpacity,
        textBackgroundPadding: textBackgroundPadding,
      );

  Map<String, dynamic> toMap() => {
        'id': id,
        'type': type,
        'x': x,
        'y': y,
        'width': width,
        'height': height,
        'content': content,
        'fontSize': fontSize,
        'color': color.value,
        'isLocked': isLocked,
        'isVisible': isVisible,
        'rotation': rotation,
        'fontFamily': fontFamily,
        'fontWeight': fontWeight,
        'fontStyle': fontStyle,
        'textDecoration': textDecoration,
        'textAlign': textAlign,
        'letterSpacing': letterSpacing,
        'lineHeight': lineHeight,
        'opacity': opacity,
        'borderRadius': borderRadius,
        'cropRatio': cropRatio,
        'textBackgroundColor': textBackgroundColor?.value,
        'textBackgroundBorderRadius': textBackgroundBorderRadius,
        'textBackgroundOpacity': textBackgroundOpacity,
        'textBackgroundPadding': textBackgroundPadding,
      };

  factory ExportElement.fromMap(Map<String, dynamic> map) {
    final intColorVal = map['color'] as int?;
    final intBgColorVal = map['textBackgroundColor'] as int?;
    return ExportElement(
      id: map['id'] as String? ?? '',
      type: map['type'] as String? ?? 'text',
      x: (map['x'] as num?)?.toDouble() ?? 0.0,
      y: (map['y'] as num?)?.toDouble() ?? 0.0,
      width: (map['width'] as num?)?.toDouble() ?? 100.0,
      height: (map['height'] as num?)?.toDouble() ?? 100.0,
      content: map['content'] as String? ?? '',
      fontSize: (map['fontSize'] as num?)?.toDouble() ?? 18.0,
      color: intColorVal != null ? Color(intColorVal) : Colors.black87,
      isLocked: map['isLocked'] as bool? ?? false,
      isVisible: map['isVisible'] as bool? ?? true,
      rotation: (map['rotation'] as num?)?.toDouble() ?? 0.0,
      fontFamily: map['fontFamily'] as String? ?? '系统内置',
      fontWeight: map['fontWeight'] as String? ?? 'normal',
      fontStyle: map['fontStyle'] as String? ?? 'normal',
      textDecoration: map['textDecoration'] as String? ?? 'none',
      textAlign: map['textAlign'] as String? ?? 'left',
      letterSpacing: (map['letterSpacing'] as num?)?.toDouble() ?? 0.0,
      lineHeight: (map['lineHeight'] as num?)?.toDouble() ?? 1.2,
      opacity: (map['opacity'] as num?)?.toDouble() ?? 1.0,
      borderRadius: (map['borderRadius'] as num?)?.toDouble() ?? 0.0,
      cropRatio: map['cropRatio'] as String?,
      textBackgroundColor: intBgColorVal != null ? Color(intBgColorVal) : null,
      textBackgroundBorderRadius: (map['textBackgroundBorderRadius'] as num?)?.toDouble() ?? 0.0,
      textBackgroundOpacity: (map['textBackgroundOpacity'] as num?)?.toDouble() ?? 1.0,
      textBackgroundPadding: (map['textBackgroundPadding'] as num?)?.toDouble() ?? 0.0,
    );
  }
}

class ExportSettings {
  String fileName;
  String dpi; // '72', '150', '300'
  String colorMode; // 'RGB', 'CMYK'
  String pageRange; // 'all', 'current'

  ExportSettings({
    this.fileName = '未命名导出文档',
    this.dpi = '300',
    this.colorMode = 'RGB',
    this.pageRange = 'all',
  });

  ExportSettings copy() => ExportSettings(
        fileName: fileName,
        dpi: dpi,
        colorMode: colorMode,
        pageRange: pageRange,
      );
}

class ExportTemplateModel {
  final String name;
  final ExportPageSize pageSize;
  final ExportPageMargin margin;
  final Map<int, ExportBackgroundSettings> pageBgSettings;
  final List<ExportElement> elements;
  final String createdAt;

  ExportTemplateModel({
    required this.name,
    required this.pageSize,
    required this.margin,
    required this.pageBgSettings,
    required this.elements,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    final Map<String, dynamic> bgMap = {};
    pageBgSettings.forEach((k, v) {
      bgMap[k.toString()] = v.toMap();
    });

    return {
      'name': name,
      'pageSize': pageSize.toMap(),
      'margin': margin.toMap(),
      'pageBgSettings': bgMap,
      'elements': elements.map((e) => e.toMap()).toList(),
      'createdAt': createdAt,
    };
  }

  factory ExportTemplateModel.fromMap(Map<String, dynamic> map) {
    final Map<int, ExportBackgroundSettings> bgSettings = {};
    final rawBgMap = map['pageBgSettings'] as Map<dynamic, dynamic>? ?? {};
    rawBgMap.forEach((k, v) {
      final intKey = int.tryParse(k.toString()) ?? 0;
      bgSettings[intKey] = ExportBackgroundSettings.fromMap(Map<String, dynamic>.from(v as Map));
    });

    final rawElements = map['elements'] as List<dynamic>? ?? [];

    return ExportTemplateModel(
      name: map['name'] as String? ?? '未命名模板',
      pageSize: ExportPageSize.fromMap(Map<String, dynamic>.from(map['pageSize'] as Map)),
      margin: ExportPageMargin.fromMap(Map<String, dynamic>.from(map['margin'] as Map)),
      pageBgSettings: bgSettings,
      elements: rawElements.map((e) => ExportElement.fromMap(Map<String, dynamic>.from(e as Map))).toList(),
      createdAt: map['createdAt'] as String? ?? '',
    );
  }
}
