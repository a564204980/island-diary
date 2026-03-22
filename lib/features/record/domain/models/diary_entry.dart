import 'dart:convert';
import 'package:uuid/uuid.dart';

/// 日记条目模型，用于持久化存储
class DiaryEntry {
  final String id;
  final DateTime dateTime;
  final int moodIndex;
  final double intensity;
  final String content;
  final String? tag;
  final List<Map<String, dynamic>> blocks; // 结构化分块数据
  final String? weather;
  final String? temp;
  final String? location;
  final String? customDate;
  final String? customTime;

  DiaryEntry({
    String? id,
    required this.dateTime,
    required this.moodIndex,
    required this.intensity,
    required this.content,
    required this.blocks,
    this.tag,
    this.weather,
    this.temp,
    this.location,
    this.customDate,
    this.customTime,
  }) : id = id ?? const Uuid().v4();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'dateTime': dateTime.toIso8601String(),
      'moodIndex': moodIndex,
      'intensity': intensity,
      'content': content,
      'tag': tag,
      'blocks': blocks,
      'weather': weather,
      'temp': temp,
      'location': location,
      'customDate': customDate,
      'customTime': customTime,
    };
  }

  factory DiaryEntry.fromMap(Map<String, dynamic> map) {
    return DiaryEntry(
      id: map['id'],
      dateTime: DateTime.parse(map['dateTime']),
      moodIndex: map['moodIndex'],
      intensity: (map['intensity'] as num).toDouble(),
      content: map['content'],
      tag: map['tag'],
      blocks: List<Map<String, dynamic>>.from(map['blocks'] ?? []),
      weather: map['weather'],
      temp: map['temp'],
      location: map['location'],
      customDate: map['customDate'],
      customTime: map['customTime'],
    );
  }

  String toJson() => jsonEncode(toMap());

  factory DiaryEntry.fromJson(String source) =>
      DiaryEntry.fromMap(jsonDecode(source));
}
