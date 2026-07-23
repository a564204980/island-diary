import 'dart:convert';

/// 用户自定义的照片墙集合（相册框）数据模型
class PhotoWallCollection {
  final String id;
  final String title;
  final String? description;
  final List<String> photoPaths;
  final DateTime createdAt;
  final bool isDefault;
  final Map<String, List<double>>? customPositions;
  final Map<String, double>? customScales;
  final Map<String, double>? customAngles;
  final String? layoutMode;

  PhotoWallCollection({
    required this.id,
    required this.title,
    this.description,
    required this.photoPaths,
    required this.createdAt,
    this.isDefault = false,
    this.customPositions,
    this.customScales,
    this.customAngles,
    this.layoutMode,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'photoPaths': photoPaths,
      'createdAt': createdAt.toIso8601String(),
      'isDefault': isDefault,
      'customPositions': customPositions,
      'customScales': customScales,
      'customAngles': customAngles,
      'layoutMode': layoutMode,
    };
  }

  factory PhotoWallCollection.fromMap(Map<String, dynamic> map) {
    Map<String, List<double>>? positions;
    if (map['customPositions'] != null) {
      positions = (map['customPositions'] as Map).map(
        (k, v) => MapEntry(
          k.toString(),
          (v as List).map((e) => (e as num).toDouble()).toList(),
        ),
      );
    }

    Map<String, double>? scales;
    if (map['customScales'] != null) {
      scales = (map['customScales'] as Map).map(
        (k, v) => MapEntry(k.toString(), (v as num).toDouble()),
      );
    }

    Map<String, double>? angles;
    if (map['customAngles'] != null) {
      angles = (map['customAngles'] as Map).map(
        (k, v) => MapEntry(k.toString(), (v as num).toDouble()),
      );
    }

    return PhotoWallCollection(
      id: map['id'] ?? '',
      title: map['title'] ?? '未命名集合',
      description: map['description'],
      photoPaths: List<String>.from(map['photoPaths'] ?? []),
      createdAt: map['createdAt'] != null
          ? DateTime.parse(map['createdAt'])
          : DateTime.now(),
      isDefault: map['isDefault'] ?? false,
      customPositions: positions,
      customScales: scales,
      customAngles: angles,
      layoutMode: map['layoutMode'],
    );
  }

  String toJson() => json.encode(toMap());

  factory PhotoWallCollection.fromJson(String source) =>
      PhotoWallCollection.fromMap(json.decode(source));

  PhotoWallCollection copyWith({
    String? id,
    String? title,
    String? description,
    List<String>? photoPaths,
    DateTime? createdAt,
    bool? isDefault,
    Map<String, List<double>>? customPositions,
    Map<String, double>? customScales,
    Map<String, double>? customAngles,
    String? layoutMode,
  }) {
    return PhotoWallCollection(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      photoPaths: photoPaths ?? this.photoPaths,
      createdAt: createdAt ?? this.createdAt,
      isDefault: isDefault ?? this.isDefault,
      customPositions: customPositions ?? this.customPositions,
      customScales: customScales ?? this.customScales,
      customAngles: customAngles ?? this.customAngles,
      layoutMode: layoutMode ?? this.layoutMode,
    );
  }
}
