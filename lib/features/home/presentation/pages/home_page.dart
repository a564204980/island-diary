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

  @override
  void initState() {
    super.initState();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);

    // 岛屿缓慢上下浮动动画：8秒一个来回，极缓慢悬浮
    _floatController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 8),
    )..repeat(reverse: true); // 往返循环

    _floatAnimation = Tween<double>(begin: -7.0, end: 7.0).animate(
      CurvedAnimation(parent: _floatController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _floatController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // 1. 夏日场景背景图
          Positioned.fill(
            child: Image.asset(
              'assets/images/home_xiatian.png',
              fit: BoxFit.cover,
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
                alignment: const Alignment(0, 0.3),
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
                // 中间层：贴合小岛原图轮廓的强发光层（提高不透明度与稍微放大尺寸进行背光投射）
                Transform.translate(
                  offset: const Offset(0, 5.0), // 偏移量：正数向下，负数向上，目前设定偏下 5 像素
                  child: ImageFiltered(
                    imageFilter: ImageFilter.blur(sigmaX: 5.0, sigmaY: 5.4),
                    child: Image.asset(
                      'assets/images/home_island_small.png',
                      width: MediaQuery.of(context).size.width * 1.05,
                      fit: BoxFit.contain,
                      color: const Color.fromARGB(
                        255,
                        255,
                        255,
                        255,
                      ).withOpacity(0.9), // 高亮度的冰蓝背光
                    ),
                  ),
                ),
                // 顶层：原图
                Image.asset(
                  'assets/images/home_island_small.png',
                  width: MediaQuery.of(context).size.width * 1,
                  fit: BoxFit.contain,
                ),
              ],
            ),
          ),

          // 4. 底部导航栏
          Positioned(
            left: 0,
            right: 0,
            bottom: 24,
            child: BottomNavBar(
              currentIndex: _currentNavIndex,
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
