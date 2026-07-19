import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:island_diary/core/state/user_state.dart';
import 'package:island_diary/features/home/presentation/pages/home_page.dart';
import 'package:island_diary/features/onboarding/presentation/pages/onboarding_page.dart';
import 'package:island_diary/shared/widgets/security/security_guard.dart';
import 'package:island_diary/core/theme/app_theme.dart';
import 'package:island_diary/core/plugins/plugin_manager.dart';
import 'package:island_diary/core/plugins/island_plugin.dart';
import 'package:island_diary/features/record/presentation/plugins/standard_camera_plugin.dart';
import 'package:island_diary/features/record/presentation/plugins/dynamic_island_camera_plugin.dart';
import 'package:island_diary/plugins/travel_experience/travel_experience_plugin.dart';

final GlobalKey<NavigatorState> globalNavigatorKey = GlobalKey<NavigatorState>();

void main() {
  // 确保 Flutter 底层绑定初始化完毕
  WidgetsFlutterBinding.ensureInitialized();

  // 完全不 await 任何内容，立即启动所有加载并 runApp
  // isMinimalDataLoaded 信号会在 userName 等基础数据就绪后触发 UI 切换
  UserState().loadFromStorage();

  // 预埋（注册）系统支持的插件
  final pm = PluginManager.instance;
  final standardCam = StandardCameraPlugin();
  pm.registerPlugin(standardCam);
  pm.registerPlugin(DynamicIslandCameraPlugin());
  final travelExp = TravelExperiencePlugin();
  pm.registerPlugin(travelExp);
  
  // 从本地存储加载插件状态
  pm.init().then((_) {
    // 初始化默认插件状态 (如果是初次运行，或者没有任何相机插件被激活)
    if (pm.getActivePlugin(PluginCategory.camera) == null) {
      // 静默安装并激活基础版
      pm.installPlugin(standardCam.pluginId).then((_) {
        pm.enablePlugin(standardCam.pluginId);
      });
    }
    if (pm.getActivePlugin(PluginCategory.experience) == null) {
      pm.installPlugin(travelExp.pluginId).then((_) {
        pm.enablePlugin(travelExp.pluginId);
      });
    }
  });

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
          navigatorKey: globalNavigatorKey,
          title: '岛屿日记',
          debugShowCheckedModeBanner: false,
          scrollBehavior: AppScrollBehavior(),
          theme: AppTheme.lightTheme(defaultFont),
          darkTheme: AppTheme.darkTheme(darkFont),
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

