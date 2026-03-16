import 'package:flutter/material.dart';
import 'package:island_diary/core/state/user_state.dart';

class RecordPage extends StatefulWidget {
  const RecordPage({super.key});

  @override
  State<RecordPage> createState() => _RecordPageState();
}

class _RecordPageState extends State<RecordPage> {
  late ScrollController _scrollController;
  double _aspectRatio = 1.0; // 默认比例，加载后会更新

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _resolveImageSize();
  }

  void _resolveImageSize() {
    // 解析图片比例以精确计算物理宽度
    const path = 'assets/images/indoor.png';
    final ImageStream stream = const AssetImage(
      path,
    ).resolve(ImageConfiguration.empty);
    stream.addListener(
      ImageStreamListener((ImageInfo info, bool _) {
        if (mounted) {
          setState(() {
            _aspectRatio = info.image.width / info.image.height;
          });
          // 比例更新后，执行居中跳转
          _centerBackground();
        }
      }),
    );
  }

  void _centerBackground() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        final double maxScroll = _scrollController.position.maxScrollExtent;
        // 修正为真正中心对齐，即床和书桌所在区域
        _scrollController.jumpTo(maxScroll / 2);
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<String>(
      valueListenable: UserState().themeMode,
      builder: (context, themeMode, _) {
        final bool isNight = UserState().isNight;
        final String bgPath = isNight
            ? 'assets/images/indoor3.png'
            : 'assets/images/indoor.png';

        // --- 核心参数调整 ---
        const double bgScale = 1.0;
        const double leftBuffer = 175.0; // 左侧预留缓冲
        const double rightBuffer = 325.0; // 右侧预留缓冲

        // 匹配背景素材的底色，作为兜底（虽然新逻辑下应该看不到它）
        final Color bgColor = isNight
            ? const Color(0xFF13131F)
            : const Color(0xFFD2B48C);

        return Scaffold(
          backgroundColor: bgColor,
          body: Stack(
            children: [
              // 1. 全景背景层 (带动态视角缩放逻辑)
              Positioned.fill(
                child: ListenableBuilder(
                  listenable: _scrollController,
                  builder: (context, child) {
                    return LayoutBuilder(
                      builder: (context, constraints) {
                        final double h = constraints.maxHeight * bgScale;
                        final double fullWidth = h * _aspectRatio;

                        // --- 核心动态缩放逻辑 (多段线性变焦) ---
                        double currentScale = 1.05; // 基础缩放
                        if (_scrollController.hasClients) {
                          final double maxScroll = _scrollController.position.maxScrollExtent;
                          final double currentScroll = _scrollController.offset.clamp(0, maxScroll);
                          final double scrollRatio = maxScroll > 0 ? currentScroll / maxScroll : 0.5;
                          
                          // 定义关键帧比例：[左边缘, 壁炉, 书桌, 餐桌, 右边缘]
                          // 对应比例：[0.0, 0.2, 0.5, 0.8, 1.0]
                          if (scrollRatio < 0.2) {
                            // 从左边缘 (1.05) 到 壁炉 (1.18)
                            final t = scrollRatio / 0.2;
                            currentScale = 1.05 + (0.13 * t);
                          } else if (scrollRatio < 0.5) {
                            // 从壁炉 (1.18) 到 书桌 (1.25)
                            final t = (scrollRatio - 0.2) / 0.3;
                            currentScale = 1.18 + (0.07 * t);
                          } else if (scrollRatio < 0.8) {
                            // 从书桌 (1.25) 到 餐桌 (1.18)
                            final t = (scrollRatio - 0.5) / 0.3;
                            currentScale = 1.25 - (0.07 * t);
                          } else {
                            // 从餐桌 (1.18) 到 右边缘 (1.05)
                            final t = (scrollRatio - 0.8) / 0.2;
                            currentScale = 1.18 - (0.13 * t);
                          }
                        }

                        return SingleChildScrollView(
                          controller: _scrollController,
                          scrollDirection: Axis.horizontal,
                          physics: const BouncingScrollPhysics(),
                          child: Stack(
                            clipBehavior: Clip.none,
                            children: [
                              // 实际图片，应用动态缩放 Transform
                              Positioned(
                                left: -leftBuffer,
                                top: 0,
                                bottom: 0,
                                child: Transform.scale(
                                  scale: currentScale,
                                  alignment: Alignment.center, // 以图片中心为基准缩放
                                  child: Image.asset(
                                    bgPath,
                                    height: h,
                                    fit: BoxFit.fitHeight,
                                  ),
                                ),
                              ),
                              // 撑开滚动范围的透明盒子：总宽 - 左右缓冲
                              SizedBox(
                                width: fullWidth - leftBuffer - rightBuffer,
                                height: h,
                              ),
                            ],
                          ),
                        );
                      },
                    );
                  },
                ),
              ),

              // 2. 内容层 (目前留空，准备接入日记组件)
            ],
          ),
        );
      },
    );
  }
}
