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
      case MascotEventType.appStarted:
        // 解析描述中的复合信息：时间、离别天数、节日
        userPrompt = "现在是应用启动时刻，你的朋友${event.description}。请给他一个自然、温馨且符合你性格的综合问候语。";
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

  /// 自动心灵分析：基于时节和情绪分布生成深度洞察
  Future<String?> analyzeSoulSeason(String apiKey, {
    required String seasonName,
    required String moodDistribution,
    required String topTags,
  }) async {
    if (apiKey.isEmpty || apiKey == 'YOUR_API_KEY') return null;

    final String systemPrompt = """
你现在是朋友的‘内心独白’。请基于他在岛屿上留下的情绪印记和当前灵魂时节，写一段深度的、极具诗意的自我剖析。

要求：
1. 必须使用第一人称（‘我’）进行叙事。
2. 语气要像是在寂静深夜里，自己与灵魂的窃窃私语。要深邃、空灵且带有治愈感。
3. 结合当前时节（$seasonName）以及情绪特征（$moodDistribution）和关键词（$topTags），挖掘出‘我’这段时间内心真实的渴求、避风港或生命力的流转。
4. 篇幅在 40-70 字左右，直接返回独白内容，不要有任何前缀或标题。
5. 严禁使用陈词滥调，要写出那种‘击中心灵’的独特性。
""";

    try {
      final response = await _dio.post(
        '/v1/chat/completions',
        data: {
          'model': 'deepseek-chat',
          'messages': [
            {'role': 'system', 'content': systemPrompt},
            {'role': 'user', 'content': "朋友，这是我最近的心灵气象报告。请对我此刻的状态进行一次温柔的解析吧。"},
          ],
          'temperature': 0.8,
          'max_tokens': 150,
        },
        options: Options(
          headers: {
            'Authorization': 'Bearer $apiKey',
            'Content-Type': 'application/json',
          },
        ),
      );

      if (response.statusCode == 200) {
        return response.data['choices'][0]['message']['content'].toString().trim();
      }
      return null;
    } catch (e) {
      debugPrint("SOUL_ANALYSIS_ERROR: $e");
      return null;
    }
  }

  String _getRandomFallback(MascotPersona persona) {
    return persona.fallbackQuotes[Random().nextInt(persona.fallbackQuotes.length)];
  }
}
