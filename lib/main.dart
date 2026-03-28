import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:island_diary/core/state/user_state.dart';
import 'package:island_diary/features/home/presentation/pages/home_page.dart';
import 'package:island_diary/features/onboarding/presentation/pages/onboarding_page.dart';

void main() async {
  // 确保 Flutter 底层绑定初始化完毕
  WidgetsFlutterBinding.ensureInitialized();

  // 启动时读取本地存储
  await UserState().loadFromStorage();
  final hasSavedName = UserState().userName.value.isNotEmpty;

  runApp(IslandDiaryApp(startWithHome: hasSavedName));
}

class AppScrollBehavior extends MaterialScrollBehavior {
  @override
  Set<PointerDeviceKind> get dragDevices => {
        PointerDeviceKind.touch,
        PointerDeviceKind.mouse,
        PointerDeviceKind.trackpad,
      };
}

class IslandDiaryApp extends StatelessWidget {
  final bool startWithHome;
  const IslandDiaryApp({super.key, required this.startWithHome});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '岛屿日记',
      debugShowCheckedModeBanner: false,
      scrollBehavior: AppScrollBehavior(),
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF0F172A)),
        useMaterial3: true,
        fontFamily: 'LXGWWenKai',
      ),
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('zh', 'CN'),
      ],
      locale: const Locale('zh', 'CN'),
      home: startWithHome ? const HomePage() : const OnboardingPage(),
    );
  }
}
