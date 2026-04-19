import 'dart:math';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:island_diary/core/models/mascot_persona.dart';
import 'package:island_diary/core/models/mascot_event.dart';

class AIService {
  static final AIService _instance = AIService._internal();
  factory AIService() => _instance;
  AIService._internal();

  final Dio _dio = Dio(BaseOptions(
    baseUrl: 'https://api.deepseek.com',
    connectTimeout: const Duration(seconds: 30),
    receiveTimeout: const Duration(seconds: 60),
    sendTimeout: const Duration(seconds: 30),
  ));

  /// 获取 DeepSeek 的回复
  Future<String> getPersonaReply(String mascotPath, String apiKey) async {
    final persona = MascotPersona.getByMascotPath(mascotPath);
    
    // 如果没有配置 Key，直接返回本地兜底
    if (apiKey.isEmpty || apiKey == 'YOUR_API_KEY') {
      return _getRandomFallback(persona);
    }

    try {
      final response = await _dio.post(
        '/chat/completions',
        data: {
          'model': 'deepseek-chat',
          'messages': [
            {'role': 'system', 'content': persona.systemPrompt},
            {'role': 'user', 'content': '和我打个招呼吧，或者说点和你性格符合的感想。'},
          ],
          'temperature': 0.8,
          'max_tokens': 60,
        },
        options: Options(
          headers: {
            'Authorization': 'Bearer $apiKey',
            'Content-Type': 'application/json',
          },
        ),
      );

      if (response.statusCode == 200) {
        final String reply = response.data['choices'][0]['message']['content'];
        return reply.trim();
      }
      return _getRandomFallback(persona);
    } catch (e) {
      debugPrint('AI Service Error: $e');
      return _getRandomFallback(persona);
    }
  }

  /// 针对特定事件触发表情和台词
  Future<String> triggerEventReply(String mascotPath, String apiKey, MascotEvent event) async {
    final persona = MascotPersona.getByMascotPath(mascotPath);

    if (apiKey.isEmpty || apiKey == 'YOUR_API_KEY') return ''; // 静默不打扰

    String userPrompt = "";
    switch (event.type) {
      case MascotEventType.decorationChanged:
        userPrompt = "你的朋友刚刚给你换了装扮：${event.description}。请根据你的性格给出评价。";
        break;
      case MascotEventType.diarySaved:
        userPrompt = "你的朋友刚刚记了篇日记：${event.description}。如果他心情不好，请温柔安慰；如果他很高兴，请陪他一起开心。";
        break;
      case MascotEventType.achievementUnlocked:
        userPrompt = "太棒了！你的朋友刚刚解锁了成就：${event.description}。请按照你的性格表达祝贺。";
        break;
      case MascotEventType.idle:
        userPrompt = "现在是闲暇时光，请随便说句符合你性格的话，就像对老朋友聊天那样。";
        break;
    }

    try {
      debugPrint("AI_SERVICE: 正在发送请求到 DeepSeek... API_KEY 前缀: ${apiKey.substring(0, min(5, apiKey.length))}...");
      final response = await _dio.post(
        '/v1/chat/completions',
        data: {
          'model': 'deepseek-chat',
          'messages': [
            {'role': 'system', 'content': "${persona.systemPrompt}\n重要规则：\n1. 绝对禁止使用'主人'、'主子'、'Mister/Miss'等称称呼，请使用'你'、'伙伴'或者直接像朋友一样交流。\n2. 你们的关系是平等的挚友、岛屿上的搭伴，语气要自然、真诚且富有情感。\n3. 如果检测到对方心情低落，请跳出原有性格框架，表现出最温柔可靠的支持。"},
            {'role': 'user', 'content': userPrompt},
          ],
          'temperature': 0.8,
          'max_tokens': 60,
          'stream': false,
        },
        options: Options(
          headers: {
            'Authorization': 'Bearer $apiKey',
            'Content-Type': 'application/json',
            'Accept': 'application/json',
          },
        ),
      );
      debugPrint("AI_SERVICE: 请求结果状态码 -> ${response.statusCode}");

      if (response.statusCode == 200) {
        return response.data['choices'][0]['message']['content'].toString().trim();
      } else {
        debugPrint("AI_SERVICE: 请求失败，状态码: ${response.statusCode}, 错误原文: ${response.data}");
        return "";
      }
    } catch (e) {
      debugPrint("AI_SERVICE: 抛出异常 -> $e");
      return "";
    }
  }

  String _getRandomFallback(MascotPersona persona) {
    return persona.fallbackQuotes[Random().nextInt(persona.fallbackQuotes.length)];
  }
}
