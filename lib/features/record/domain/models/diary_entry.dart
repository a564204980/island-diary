import 'dart:convert';
import 'package:uuid/uuid.dart';

/// 鏃ヨ鏉＄洰妯″瀷锛岀敤浜庢寔涔呭寲瀛樺偍
class DiaryEntry {
  final String id;
  final DateTime dateTime;
  final int moodIndex;
  final double intensity;
  final String content;
  final String? tag;
  final List<Map<String, dynamic>> blocks; // 缁撴瀯鍖栧垎鍧楁暟鎹?
  final String? weather;
  final String? temp;
  final String? location;
  final String? customDate;
  final String? customTime;
  final List<DiaryReply> replies; // 鑷垜鍥炲/鍥炲搷鍒楄〃
  final String paperStyle; // 淇＄焊鏍峰紡
  final bool isImageGrid; // 鏄惁寮€鍚浘鐗囦節瀹牸
  final bool isMixedLayout; // 鏄惁寮€鍚浘鏂囨贩鎺?
  final bool isLiked; // 鏄惁宸茬偣璧烇紙鏈嬪弸鍦堟ā寮忎氦浜掞級

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
  }) : id = id ?? const Uuid().v4(),
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
      'paperStyle': paperStyle,
      'isImageGrid': isImageGrid,
      'isMixedLayout': isMixedLayout,
      'isLiked': isLiked,
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
    );
  }

  String toJson() => jsonEncode(toMap());

  factory DiaryEntry.fromJson(String source) =>
      DiaryEntry.fromMap(jsonDecode(source));
}

/// 鑷垜鍥炲/鍥炲搷妯″瀷
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
