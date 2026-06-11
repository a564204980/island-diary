import 'dart:convert';
import 'package:uuid/uuid.dart';

/// 日记条目模型，用于持久化存储。
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
  final String paperStyle; // 信纸样式
  final bool isImageGrid; // 是否开启图片九宫格
  final bool isMixedLayout; // 是否开启图文混排
  final bool isLiked; // 是否已点赞（朋友圈模式交互）
  final Map<String, String> annotations; // 批注数据 (Key: 块索引_段落索引, Value: 批注内容)
  final String? bookId; // 所属日记本ID
  final String? title; // 日记目录小标题

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
    this.paperStyle = 'note1',
    this.isImageGrid = false,
    this.isMixedLayout = false,
    this.isLiked = false,
    Map<String, String>? annotations,
    this.bookId = 'default',
    this.title,
  }) : id = id ?? const Uuid().v4(),
       replies = replies ?? [],
       annotations = annotations ?? {};

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
      'paperStyle': paperStyle,
      'isImageGrid': isImageGrid,
      'isMixedLayout': isMixedLayout,
      'isLiked': isLiked,
      'annotations': annotations,
      'bookId': bookId,
      'title': title,
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
              (map['replies'] as List).map((x) => DiaryReply.fromMap(x)),
            )
          : [],
      paperStyle: map['paperStyle'] ?? 'note1',
      isImageGrid: map['isImageGrid'] ?? false,
      isMixedLayout: map['isMixedLayout'] ?? false,
      isLiked: map['isLiked'] ?? false,
      annotations: map['annotations'] != null
          ? Map<String, String>.from(map['annotations'])
          : {},
      bookId: map['bookId'] ?? 'default',
      title: map['title'],
    );
  }

  DiaryEntry copyWith({
    String? id,
    DateTime? dateTime,
    int? moodIndex,
    double? intensity,
    String? content,
    String? tag,
    List<Map<String, dynamic>>? blocks,
    String? weather,
    String? temp,
    String? location,
    String? customDate,
    String? customTime,
    List<DiaryReply>? replies,
    String? paperStyle,
    bool? isImageGrid,
    bool? isMixedLayout,
    bool? isLiked,
    Map<String, String>? annotations,
    String? bookId,
    String? title,
  }) {
    return DiaryEntry(
      id: id ?? this.id,
      dateTime: dateTime ?? this.dateTime,
      moodIndex: moodIndex ?? this.moodIndex,
      intensity: intensity ?? this.intensity,
      content: content ?? this.content,
      tag: tag ?? this.tag,
      blocks: blocks ?? this.blocks,
      weather: weather ?? this.weather,
      temp: temp ?? this.temp,
      location: location ?? this.location,
      customDate: customDate ?? this.customDate,
      customTime: customTime ?? this.customTime,
      replies: replies ?? this.replies,
      paperStyle: paperStyle ?? this.paperStyle,
      isImageGrid: isImageGrid ?? this.isImageGrid,
      isMixedLayout: isMixedLayout ?? this.isMixedLayout,
      isLiked: isLiked ?? this.isLiked,
      annotations: annotations ?? this.annotations,
      bookId: bookId ?? this.bookId,
      title: title ?? this.title,
    );
  }

  String toJson() => jsonEncode(toMap());

  factory DiaryEntry.fromJson(String source) =>
      DiaryEntry.fromMap(jsonDecode(source));
}

/// 自我回复/回响模型。
class DiaryReply {
  final String id;
  final String content;
  final DateTime dateTime;

  DiaryReply({String? id, required this.content, required this.dateTime})
    : id = id ?? const Uuid().v4();

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
