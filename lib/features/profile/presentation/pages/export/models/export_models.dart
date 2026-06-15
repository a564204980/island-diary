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
}

class ExportBackgroundSettings {
  Color color;
  String? imagePath; // 可选的背景图片

  ExportBackgroundSettings({
    this.color = const Color(0xFFE8F4F8),
    this.imagePath,
  });

  ExportBackgroundSettings copy() => ExportBackgroundSettings(
        color: color,
        imagePath: imagePath,
      );
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
      );
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
