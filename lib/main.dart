import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:island_diary/core/state/user_state.dart';
import 'package:island_diary/features/home/presentation/pages/home_page.dart';
import 'package:island_diary/features/onboarding/presentation/pages/onboarding_page.dart';
import 'package:island_diary/shared/widgets/security/security_guard.dart';

void main() {
  // 确保 Flutter 底层绑定初始化完毕
  WidgetsFlutterBinding.ensureInitialized();

  // 完全不 await 任何内容，立即启动所有加载并 runApp
  // isMinimalDataLoaded 信号会在 userName 等基础数据就绪后触发 UI 切换
  UserState().loadFromStorage();

  runApp(const IslandDiaryApp());
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
  const IslandDiaryApp({super.key});

  @override
  Widget build(BuildContext context) {
    final userState = UserState();
    return ListenableBuilder(
      listenable: Listenable.merge([
        userState.themeMode,
        userState.selectedIslandThemeId,
      ]),
      builder: (context, child) {
        final isLego = userState.selectedIslandThemeId.value == 'lego';
        final defaultFont = isLego ? 'SweiFistLeg' : 'ArphicKaiti';
        final darkFont = isLego ? 'SweiFistLeg' : 'LXGWWenKai';
        
        final isDark = userState.isNight;

        return MaterialApp(
          key: const ValueKey('IslandDiaryAppRoot'),
          title: '岛屿日记',
          debugShowCheckedModeBanner: false,
          scrollBehavior: AppScrollBehavior(),
          theme: ThemeData(
            colorScheme: ColorScheme.fromSeed(
              seedColor: const Color(0xFF0F172A),
              brightness: Brightness.light,
            ),
            useMaterial3: true,
            scaffoldBackgroundColor: const Color(0xFFE6F3F5),
            fontFamily: defaultFont,
            bottomSheetTheme: const BottomSheetThemeData(
              showDragHandle: false,
              backgroundColor: Colors.white,
              surfaceTintColor: Colors.transparent,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
              ),
            ),
          ),
          darkTheme: ThemeData(
            colorScheme: ColorScheme.fromSeed(
              seedColor: const Color(0xFF0F172A),
              brightness: Brightness.dark,
            ),
            useMaterial3: true,
            scaffoldBackgroundColor: const Color(0xFF0D1B2A),
            fontFamily: darkFont,
            bottomSheetTheme: const BottomSheetThemeData(
              showDragHandle: false,
              backgroundColor: Color(0xFF1A1A1A),
              surfaceTintColor: Colors.transparent,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
              ),
            ),
          ),
          themeMode: isDark ? ThemeMode.dark : ThemeMode.light,
          localizationsDelegates: const [
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: const [Locale('zh', 'CN')],
          locale: const Locale('zh', 'CN'),
          builder: (context, child) => SecurityGuard(child: child!),
          home: ValueListenableBuilder<bool>(
            valueListenable: userState.isMinimalDataLoaded,
            builder: (context, isReady, _) {
              if (isReady) {
                // 最小数据已就绪（userName 已加载），立即进入目标页面
                return userState.userName.value.isNotEmpty
                    ? const HomePage()
                    : const OnboardingPage();
              }
              // SharedPreferences 首次读取期间（约 100~300ms），展示品牌占位屏
              return const Scaffold(
                backgroundColor: Color(0xFFD2E2F9),
                body: Center(
                  child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFD4A373)),
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }
}

