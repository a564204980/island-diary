/// 小软感知的事件类型
enum MascotEventType {
  /// 换装/戴饰品
  decorationChanged,
  /// 存日记 (心情记录)
  diarySaved,
  /// 解锁成就
  achievementUnlocked,
  /// 随机互动 (闲聊)
  idle,
  /// 应用启动问候 (包含时间、久别、节日检测)
  appStarted,
}

/// AI 感知事件模型
class MascotEvent {
  final MascotEventType type;
  final String description; // 事件的具体描述，如“戴上了萌萌猫耳”
  final Map<String, dynamic>? metadata; // 额外数据，如心情指数

  MascotEvent({required this.type, required this.description, this.metadata});
}
