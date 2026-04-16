import 'package:flutter/foundation.dart';

/// 日记草稿模型
/// 封装了日记编辑过程中的中间状态
class DiaryDraft {
  final int? moodIndex;
  final double intensity;
  final String content;
  final String? tag;
  final String? weather;
  final String? temp;
  final String? location;
  final String? customDate;
  final String? customTime;
  final DateTime? dateTime;
  final List<Map<String, dynamic>>? blocks; // 结构化分块数据
  final String paperStyle;
  final bool isImageGrid;
  final bool isMixedLayout;

  DiaryDraft({
    required this.moodIndex,
    required this.intensity,
    required this.content,
    this.tag,
    this.weather,
    this.temp,
    this.location,
    this.customDate,
    this.customTime,
    this.dateTime,
    this.blocks,
    this.paperStyle = 'classic',
    this.isImageGrid = false,
    this.isMixedLayout = true,
  });
}
