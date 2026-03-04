import 'package:flutter/material.dart';
import 'package:island_diary/features/onboarding/presentation/pages/onboarding_page.dart';

void main() {
  runApp(const IslandDiaryApp());
}

class IslandDiaryApp extends StatelessWidget {
  const IslandDiaryApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '岛屿日记',
      // 取消右上角的 DEBUG 横幅，不破坏沉浸感
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF0F172A)),
        useMaterial3: true, // 使用最新的 Material 3 风格设计
      ),
      // 将应用的启动页直接设置为了我们刚刚写的引导页
      home: const OnboardingPage(),
    );
  }
}
