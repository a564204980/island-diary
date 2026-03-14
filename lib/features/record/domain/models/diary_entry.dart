import 'dart:convert';
import 'package:uuid/uuid.dart';

/// 日记条目模型，用于持久化存储
class DiaryEntry {
  final String id;
  final DateTime dateTime;
  final int moodIndex;
  final double intensity;
  final String content;
  final List<Map<String, dynamic>> blocks; // 结构化分块数据

  DiaryEntry({
    String? id,
    required this.dateTime,
    required this.moodIndex,
    required this.intensity,
    required this.content,
    required this.blocks,
  }) : id = id ?? const Uuid().v4();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'dateTime': dateTime.toIso8601String(),
      'moodIndex': moodIndex,
      'intensity': intensity,
      'content': content,
      'blocks': blocks,
    };
  }

  factory DiaryEntry.fromMap(Map<String, dynamic> map) {
    return DiaryEntry(
      id: map['id'],
      dateTime: DateTime.parse(map['dateTime']),
      moodIndex: map['moodIndex'],
      intensity: (map['intensity'] as num).toDouble(),
      content: map['content'],
      blocks: List<Map<String, dynamic>>.from(map['blocks'] ?? []),
    );
  }

  String toJson() => jsonEncode(toMap());

  factory DiaryEntry.fromJson(String source) =>
      DiaryEntry.fromMap(jsonDecode(source));
}
