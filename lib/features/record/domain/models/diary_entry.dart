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
  final List<DiaryReply> replies; // 自我回复/回响列表

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
    List<DiaryReply>? replies,
  })  : id = id ?? const Uuid().v4(),
        replies = replies ?? [];

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
      'replies': replies.map((x) => x.toMap()).toList(),
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
      replies: map['replies'] != null
          ? List<DiaryReply>.from(
              (map['replies'] as List).map((x) => DiaryReply.fromMap(x)))
          : [],
    );
  }

  String toJson() => jsonEncode(toMap());

  factory DiaryEntry.fromJson(String source) =>
      DiaryEntry.fromMap(jsonDecode(source));
}

/// 自我回复/回响模型
class DiaryReply {
  final String id;
  final String content;
  final DateTime dateTime;

  DiaryReply({
    String? id,
    required this.content,
    required this.dateTime,
  }) : id = id ?? const Uuid().v4();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'content': content,
      'dateTime': dateTime.toIso8601String(),
    };
  }

  factory DiaryReply.fromMap(Map<String, dynamic> map) {
    return DiaryReply(
      id: map['id'],
      content: map['content'],
      dateTime: DateTime.parse(map['dateTime']),
    );
  }
}
