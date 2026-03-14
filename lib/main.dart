import 'package:flutter/material.dart';
import 'package:island_diary/core/state/user_state.dart';
import 'package:island_diary/features/home/presentation/pages/home_page.dart';
import 'package:island_diary/features/onboarding/presentation/pages/onboarding_page.dart';

void main() async {
  // 确保 Flutter 底层绑定初始化完毕，以便在 main 中使用 async 操作
  WidgetsFlutterBinding.ensureInitialized();

  // 启动时读取本地存储中的用户名，并更新全局状态
  await UserState().loadFromStorage();
  final hasSavedName = UserState().userName.value.isNotEmpty;

  // 根据有无本地存储的名字，决定直接进入主页或先过引导页
  runApp(IslandDiaryApp(startWithHome: hasSavedName));
}

class IslandDiaryApp extends StatelessWidget {
  final bool startWithHome;
  const IslandDiaryApp({super.key, required this.startWithHome});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '岛屿日记',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF0F172A)),
        useMaterial3: true,
        fontFamily: 'FZKai',
      ),
      // 根据是否已有本地数据，动态决定首屏
      home: startWithHome ? const HomePage() : const OnboardingPage(),
    );
  }
}
