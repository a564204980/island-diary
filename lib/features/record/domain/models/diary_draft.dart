/// 日记草稿模型
/// 封装了日记编辑过程中的中间状态，支持多草稿序列化
class DiaryDraft {
  final String id;
  final DateTime updatedAt;
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
  final String? bookId;

  DiaryDraft({
    String? id,
    DateTime? updatedAt,
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
    this.bookId = 'default',
  })  : id = id ?? 'draft_${DateTime.now().microsecondsSinceEpoch}',
        updatedAt = updatedAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'updatedAt': updatedAt.toIso8601String(),
      'moodIndex': moodIndex,
      'intensity': intensity,
      'content': content,
      'tag': tag,
      'weather': weather,
      'temp': temp,
      'location': location,
      'customDate': customDate,
      'customTime': customTime,
      'dateTime': dateTime?.toIso8601String(),
      'blocks': blocks,
      'paperStyle': paperStyle,
      'isImageGrid': isImageGrid,
      'isMixedLayout': isMixedLayout,
      'bookId': bookId,
    };
  }

  factory DiaryDraft.fromMap(Map<String, dynamic> map) {
    return DiaryDraft(
      id: map['id'] as String?,
      updatedAt: map['updatedAt'] != null ? DateTime.tryParse(map['updatedAt'] as String) : null,
      moodIndex: map['moodIndex'] as int?,
      intensity: (map['intensity'] as num?)?.toDouble() ?? 5.0,
      content: map['content'] as String? ?? '',
      tag: map['tag'] as String?,
      weather: map['weather'] as String?,
      temp: map['temp'] as String?,
      location: map['location'] as String?,
      customDate: map['customDate'] as String?,
      customTime: map['customTime'] as String?,
      dateTime: map['dateTime'] != null ? DateTime.tryParse(map['dateTime'] as String) : null,
      blocks: map['blocks'] != null
          ? (map['blocks'] as List).map((e) => Map<String, dynamic>.from(e as Map)).toList()
          : null,
      paperStyle: map['paperStyle'] as String? ?? 'classic',
      isImageGrid: map['isImageGrid'] as bool? ?? false,
      isMixedLayout: map['isMixedLayout'] as bool? ?? true,
      bookId: map['bookId'] as String? ?? 'default',
    );
  }

  DiaryDraft copyWith({
    String? id,
    DateTime? updatedAt,
    int? moodIndex,
    double? intensity,
    String? content,
    String? tag,
    String? weather,
    String? temp,
    String? location,
    String? customDate,
    String? customTime,
    DateTime? dateTime,
    List<Map<String, dynamic>>? blocks,
    String? paperStyle,
    bool? isImageGrid,
    bool? isMixedLayout,
    String? bookId,
  }) {
    return DiaryDraft(
      id: id ?? this.id,
      updatedAt: updatedAt ?? this.updatedAt,
      moodIndex: moodIndex ?? this.moodIndex,
      intensity: intensity ?? this.intensity,
      content: content ?? this.content,
      tag: tag ?? this.tag,
      weather: weather ?? this.weather,
      temp: temp ?? this.temp,
      location: location ?? this.location,
      customDate: customDate ?? this.customDate,
      customTime: customTime ?? this.customTime,
      dateTime: dateTime ?? this.dateTime,
      blocks: blocks ?? this.blocks,
      paperStyle: paperStyle ?? this.paperStyle,
      isImageGrid: isImageGrid ?? this.isImageGrid,
      isMixedLayout: isMixedLayout ?? this.isMixedLayout,
      bookId: bookId ?? this.bookId,
    );
  }
}
