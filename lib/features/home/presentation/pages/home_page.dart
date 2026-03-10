import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:island_diary/core/state/user_state.dart';
import 'package:island_diary/features/home/presentation/widgets/sparkling_water_effect.dart';
import 'package:island_diary/shared/widgets/bottom_nav_bar.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage>
    with SingleTickerProviderStateMixin {
  int _currentNavIndex = 0;
  late AnimationController _floatController;
  late Animation<double> _floatAnimation;
  Timer? _timeChecker;
  late String _currentBgPath;
  late String _currentIslandPath;

  @override
  void initState() {
    super.initState();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);

    // 1. 初始化当前时间对应的背景图和岛屿图
    _currentBgPath = _getBackgroundImageForCurrentTime();
    _currentIslandPath = _getIslandImageForCurrentTime();

    // 2. 启动分钟级定时器，静默监测时间跨越
    _timeChecker = Timer.periodic(const Duration(minutes: 1), (timer) {
      final newBgPath = _getBackgroundImageForCurrentTime();
      final newIslandPath = _getIslandImageForCurrentTime();
      if (newBgPath != _currentBgPath || newIslandPath != _currentIslandPath) {
        setState(() {
          _currentBgPath = newBgPath;
          _currentIslandPath = newIslandPath;
        });
      }
    });

    // 岛屿缓慢上下浮动动画：8秒一个来回，极缓慢悬浮
    _floatController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 8),
    )..repeat(reverse: true); // 往返循环

    _floatAnimation = Tween<double>(begin: -7.0, end: 7.0).animate(
      CurvedAnimation(parent: _floatController, curve: Curves.easeInOut),
    );
  }

  /// 依据当前设备系统时间的“小时数”获取对应的全时段背景图素材
  String _getBackgroundImageForCurrentTime() {
    final int currentHour = DateTime.now().hour;
    if (currentHour >= 6 && currentHour < 11) {
      return 'assets/images/home_xiatian.png'; // 早上 06:00 ~ 10:59
    } else if (currentHour >= 11 && currentHour < 17) {
      return 'assets/images/home_zhongwu.png'; // 中午 11:00 ~ 16:59
    } else {
      return 'assets/images/home_wanshang.png'; // 晚上 17:00 ~ 次日 05:59
    }
  }

  /// 依据系统时间获取对应的岛屿主体图
  String _getIslandImageForCurrentTime() {
    final int currentHour = DateTime.now().hour;
    if (currentHour >= 17 || currentHour < 6) {
      return 'assets/images/home_island_smal_wanshang.png'; // 夜晚图
    } else {
      return 'assets/images/home_island_small.png'; // 昼间图
    }
  }

  /// 依据系统时间获取对应的岛屿发光颜色 (整体轮廓背光)
  Color _getIslandGlowColorForCurrentTime() {
    final int currentHour = DateTime.now().hour;
    if (currentHour >= 17 || currentHour < 6) {
      // 最终修正：边缘发光转为温馨的暖金色，消除冷白感
      return const Color(0xFFFFEFA1).withOpacity(0.65);
    } else {
      return const Color.fromARGB(
        255,
        255,
        255,
        255,
      ).withOpacity(0.9); // 昼间：冰白高光
    }
  }

  /// 依据系统时间获取小岛底部的照射反射强力光源 (水面辉辉发亮的效果)
  Color _getIslandBottomLightColorForCurrentTime() {
    final int currentHour = DateTime.now().hour;
    if (currentHour >= 17 || currentHour < 6) {
      // 最终修正：回归温馨的夕阳橙/金色，赋予岛屿余温
      return const Color(0xFFFFB347).withOpacity(0.95);
    } else {
      return Colors.transparent; // 白天不需要额外底部强反光
    }
  }

  /// 依据系统时间获取小岛“本体岩石底部”受到的微弱反光（叠加在图片内部）
  Color _getIslandBottomRockLightColorForCurrentTime() {
    final int currentHour = DateTime.now().hour;
    if (currentHour >= 17 || currentHour < 6) {
      // 夜晚：岩石底部的夕阳橙反光
      return const Color(0xFFFFB347).withOpacity(0.65);
    } else {
      return Colors.transparent;
    }
  }

  @override
  void dispose() {
    _timeChecker?.cancel();
    _floatController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // 1. 动态全天候场景背景图 (带无缝溶边交叉渐变切换特效)
          Positioned.fill(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 1500),
              switchInCurve: Curves.easeIn,
              switchOutCurve: Curves.easeOut,
              child: Image.asset(
                _currentBgPath,
                key: ValueKey(_currentBgPath), // 用路径绑定唯一 key 确保触发渐灭渐亮动画
                fit: BoxFit.cover,
                width: double.infinity,
                height: double.infinity,
              ),
            ),
          ),

          // 1.5 湖面波光粼粼特效层 (叠在图片上)
          const Positioned.fill(child: SparklingWaterEffect()),

          // 2. 用户名 —— 左上角
          SafeArea(
            child: Align(
              alignment: Alignment.topLeft,
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: ValueListenableBuilder<String>(
                  valueListenable: UserState().userName,
                  builder: (context, name, child) {
                    return Text(
                      '治愈岛',
                      style: const TextStyle(
                        color: Color(0xFF5A3E28),
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    );
                  },
                ),
              ),
            ),
          ),

          // 3. 岛屿主体图 —— 居中 + 缓慢上下浮动动画
          AnimatedBuilder(
            animation: _floatAnimation,
            builder: (context, child) {
              return Align(
                alignment: const Alignment(0, -0.4), // 上移至 -0.4
                child: Transform.translate(
                  offset: Offset(0, _floatAnimation.value),
                  child: child,
                ),
              );
            },
            child: Stack(
              alignment: Alignment.center,
              children: [
                // 底层：环境光大范围光晕，铺垫冷色发光氛围
                // Container(
                //   width: MediaQuery.of(context).size.width * 0.7,
                //   height: MediaQuery.of(context).size.width * 0.35,
                //   decoration: BoxDecoration(
                //     shape: BoxShape.rectangle,
                //     borderRadius: BorderRadius.circular(200),
                //     boxShadow: [
                //       BoxShadow(
                //         color: const Color(0xFF55CCFF).withOpacity(0.4),
                //         blurRadius: 60.0,
                //         spreadRadius: 25.0,
                //       ),
                //       BoxShadow(
                //         color: const Color.fromARGB(
                //           255,
                //           250,
                //           255,
                //           255,
                //         ).withOpacity(0.6),
                //         blurRadius: 30.0,
                //         spreadRadius: 10.0,
                //       ),
                //     ],
                //   ),
                // ),
                // 中间层0：新增的底部强力暖色倒影环境光束（只在夜间显现）
                Positioned(
                  bottom:
                      MediaQuery.of(context).size.width *
                      0.08, // 定位到岛屿底部岩石尖峰偏下一点
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 1500),
                    width: MediaQuery.of(context).size.width * 0.85,
                    height: MediaQuery.of(context).size.width * 0.45,
                    decoration: BoxDecoration(
                      gradient: RadialGradient(
                        colors: [
                          _getIslandBottomLightColorForCurrentTime(),
                          _getIslandBottomLightColorForCurrentTime()
                              .withOpacity(0.0),
                        ],
                        stops: const [0.15, 1.0],
                      ),
                    ),
                  ),
                ),
                // 中间层1：贴合小岛原图轮廓的强发光层（提高不透明度与稍微放大尺寸进行背光投射）
                Transform.translate(
                  offset: const Offset(0, 5.0), // 偏移量：正数向下，负数向上，目前设定偏下 5 像素
                  child: ImageFiltered(
                    imageFilter: ImageFilter.blur(sigmaX: 5.0, sigmaY: 5.4),
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 1500),
                      child: Image.asset(
                        _currentIslandPath,
                        key: ValueKey('glow_$_currentIslandPath'),
                        width: MediaQuery.of(context).size.width * 1.05,
                        fit: BoxFit.contain,
                        color: _getIslandGlowColorForCurrentTime(),
                      ),
                    ),
                  ),
                ),
                // 顶层：原图，外加一层底部反光遮罩（岩石被照亮的感觉）
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 1500),
                  child: ShaderMask(
                    key: ValueKey(
                      'top_$_currentIslandPath',
                    ), // Key 移到了 ShaderMask 上保证重绘触发
                    blendMode: BlendMode.srcATop, // 仅在图片不透明范围内叠加暖色光
                    shaderCallback: (bounds) {
                      return RadialGradient(
                        center: const Alignment(0, 0.85), // 估算小岛底部岩石尖端在图片里的纵向位置
                        radius: 0.6, // 扩大光照晕染范围
                        colors: [
                          _getIslandBottomRockLightColorForCurrentTime(),
                          Colors.transparent,
                        ],
                        stops: const [0.0, 1.0],
                      ).createShader(bounds);
                    },
                    child: Image.asset(
                      _currentIslandPath,
                      width: MediaQuery.of(context).size.width * 1,
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // 4. 底部导航栏
          Positioned(
            left: 0,
            right: 0,
            bottom: 40, // XL 扩容：拉开底部距离
            child: BottomNavBar(
              currentIndex: _currentNavIndex,
              isNight:
                  DateTime.now().hour >= 17 ||
                  DateTime.now().hour < 6, // 注入夜间判断
              onTap: (index) {
                setState(() {
                  _currentNavIndex = index;
                });
              },
            ),
          ),
        ],
      ),
    );
  }
}
