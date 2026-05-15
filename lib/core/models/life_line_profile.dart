import 'dart:convert';

/// 人生线（角色档案）模型
/// 用于存储多角色的基础信息，如姓名、简介、头像等。
class LifeLineProfile {
  final String id;          // 唯一标识符
  final String name;        // 角色名称
  final String bio;         // 角色简介
  final String? avatarPath; // 自定义头像的本地路径
  final int createdAt;      // 创建时间戳

  LifeLineProfile({
    required this.id,
    required this.name,
    this.bio = '',
    this.avatarPath,
    required this.createdAt,
  });

  /// 将对象转换为 Map，用于持久化存储
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'bio': bio,
      'avatarPath': avatarPath,
      'createdAt': createdAt,
    };
  }

  /// 从 Map 创建对象
  factory LifeLineProfile.fromMap(Map<String, dynamic> map) {
    return LifeLineProfile(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      bio: map['bio'] ?? '',
      avatarPath: map['avatarPath'],
      createdAt: map['createdAt'] ?? DateTime.now().millisecondsSinceEpoch,
    );
  }

  /// 将对象转换为 JSON 字符串
  String toJson() => json.encode(toMap());

  /// 从 JSON 字符串创建对象
  factory LifeLineProfile.fromJson(String source) => LifeLineProfile.fromMap(json.decode(source));

  /// 创建对象的副本并更新部分字段
  LifeLineProfile copyWith({
    String? id,
    String? name,
    String? bio,
    String? avatarPath,
    int? createdAt,
  }) {
    return LifeLineProfile(
      id: id ?? this.id,
      name: name ?? this.name,
      bio: bio ?? this.bio,
      avatarPath: avatarPath ?? this.avatarPath,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
