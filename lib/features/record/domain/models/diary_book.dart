import 'dart:convert';
import 'package:uuid/uuid.dart';

class DiaryBook {
  final String id;
  final String name;
  final String description;
  final int coverColorValue;
  final int coverStyle;
  final DateTime createdAt;
  final String? customCoverPath;

  DiaryBook({
    String? id,
    required this.name,
    this.description = '',
    this.coverColorValue = 0xFF64B5F6,
    this.coverStyle = 0,
    DateTime? createdAt,
    this.customCoverPath,
  })  : id = id ?? const Uuid().v4(),
        createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'coverColorValue': coverColorValue,
      'coverStyle': coverStyle,
      'createdAt': createdAt.toIso8601String(),
      'customCoverPath': customCoverPath,
    };
  }

  factory DiaryBook.fromMap(Map<String, dynamic> map) {
    return DiaryBook(
      id: map['id'],
      name: map['name'] ?? '',
      description: map['description'] ?? '',
      coverColorValue: map['coverColorValue'] ?? 0xFF64B5F6,
      coverStyle: map['coverStyle'] ?? 0,
      createdAt: map['createdAt'] != null
          ? DateTime.parse(map['createdAt'])
          : null,
      customCoverPath: map['customCoverPath'],
    );
  }

  DiaryBook copyWith({
    String? id,
    String? name,
    String? description,
    int? coverColorValue,
    int? coverStyle,
    DateTime? createdAt,
    String? customCoverPath,
  }) {
    return DiaryBook(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      coverColorValue: coverColorValue ?? this.coverColorValue,
      coverStyle: coverStyle ?? this.coverStyle,
      createdAt: createdAt ?? this.createdAt,
      customCoverPath: customCoverPath ?? this.customCoverPath,
    );
  }

  String toJson() => jsonEncode(toMap());

  factory DiaryBook.fromJson(String source) =>
      DiaryBook.fromMap(jsonDecode(source));
}
