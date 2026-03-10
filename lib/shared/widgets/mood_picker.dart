import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flutter/material.dart';

class MoodItem {
  final String label;
  final String? imagePath;
  final double angle; // 圆盘方位角
  final double? imageRotation; // 贴图自身旋转角(角度)
  final double? imageTop; // 径向偏移 (正数远离圆心，负数靠近圆心)
  final double? imageLeft; // 切向偏移 (左右微调)
  final double? width;
  final double? height;
  final double? scale;

  // 图文组配置 (不受切片旋转和偏移影响，基于圆心绝对定位)
  final String? iconPath; // 小图标路径
  final double? iconSize; // 图标大小 (由于主要为正方形，提供一个 size)
  final double? fontSize; // 文字大小
  final Offset? iconOffset; // 图标相对于圆盘中心的绝对偏移
  final Offset? textOffset; // 文字相对于圆盘中心的绝对偏移
  final double? iconRotation; // 图标自身的旋转
  final double? textRotation; // 文字自身的旋转
  final Color? glowColor; // 选中时的外圈发光色

  const MoodItem({
    required this.label,
    this.imagePath,
    required this.angle,
    this.imageRotation,
    this.imageTop,
    this.imageLeft,
    this.width,
    this.height,
    this.scale,
    this.iconPath,
    this.iconSize,
    this.fontSize,
    this.iconOffset,
    this.textOffset,
    this.iconRotation,
    this.textRotation,
    this.glowColor,
  });
}

const List<MoodItem> kMoods = [
  MoodItem(
    label: '期待',
    imagePath: 'assets/images/icons/select1.png',
    angle: 0,
    imageRotation: 0,
    imageTop: 8,
    imageLeft: -78,
    width: 205,
    height: 286,
    scale: 0.38,
    // 图文绝对坐标偏移 (x 为正向右，y 为正向下)
    iconPath: 'assets/images/icons/sprout.png',
    iconSize: 40,
    fontSize: 14,
    iconOffset: const Offset(-28, -84),
    textOffset: const Offset(-26, -60),
    glowColor: const Color(0xFFFFA4A4), // 粉红色
  ),
  MoodItem(
    label: '厌恶',
    imagePath: 'assets/images/icons/select2.png',
    angle: 315,
    imageRotation: 40,
    imageTop: 13,
    imageLeft: 60,
    width: 324,
    height: 237,
    scale: 0.34,
    // 图文绝对坐标偏移
    iconPath: 'assets/images/icons/upset.png',
    iconSize: 40,
    fontSize: 14,
    iconOffset: const Offset(-74, -38),
    textOffset: const Offset(-72, -14),
    glowColor: const Color(0xFFA4E4A4), // 浅绿色
  ),
  MoodItem(
    label: '恐惧',
    imagePath: 'assets/images/icons/select3.png',
    angle: 270,
    imageRotation: 90,
    imageTop: -60,
    imageLeft: 72,
    width: 324,
    height: 241,
    scale: 0.33,
    // 图文绝对坐标偏移
    iconPath: 'assets/images/icons/eyes.png',
    iconSize: 52,
    fontSize: 14,
    iconOffset: const Offset(-76, 28),
    textOffset: const Offset(-76, 50),
    glowColor: const Color(0xFFC4A4E4), // 紫色
  ),
  MoodItem(
    label: '惊喜',
    imagePath: 'assets/images/icons/select4.png',
    angle: 225,
    imageRotation: 135,
    imageTop: -178,
    imageLeft: 123,
    width: 230,
    height: 345,
    scale: 0.35,
    // 图文绝对坐标偏移
    iconPath: 'assets/images/icons/star.png',
    iconSize: 40,
    fontSize: 14,
    iconOffset: const Offset(-28, 78),
    textOffset: const Offset(-28, 102),
    glowColor: const Color(0xFFFFC484), // 橘黄色
  ),
  MoodItem(
    label: '平静',
    imagePath: 'assets/images/icons/select5.png',
    angle: 180,
    imageRotation: 180,
    imageTop: -294,
    imageLeft: -88,
    width: 306,
    height: 420,
    scale: 0.274,
    // 图文绝对坐标偏移
    iconPath: 'assets/images/icons/leaf.png',
    iconSize: 56,
    fontSize: 14,
    iconOffset: const Offset(34, 78),
    textOffset: const Offset(34, 102),
    glowColor: const Color(0xFFA4D4E4), // 浅蓝色
  ),
  MoodItem(
    label: '愤怒',
    imagePath: 'assets/images/icons/select6.png',
    angle: 225,
    imageRotation: 134,
    imageTop: -176,
    imageLeft: -58,
    width: 301,
    height: 221,
    scale: 0.38,
    // 图文绝对坐标偏移
    iconPath: 'assets/images/icons/angry.png',
    iconSize: 56,
    fontSize: 14,
    iconOffset: const Offset(86, 28),
    textOffset: const Offset(86, 52),
    glowColor: const Color(0xFFFF8484), // 红色
  ),
  MoodItem(
    label: '悲伤',
    imagePath: 'assets/images/icons/select7.png',
    angle: 270,
    imageRotation: 90,
    imageTop: -158,
    imageLeft: 180,
    width: 245,
    height: 181,
    scale: 0.52,
    // 图文绝对坐标偏移
    iconPath: 'assets/images/icons/raindrop.png',
    iconSize: 58,
    fontSize: 14,
    iconOffset: const Offset(86, -42),
    textOffset: const Offset(86, -14),
    glowColor: const Color(0xFF84A4E4), // 深蓝色
  ),
  MoodItem(
    label: '开心',
    imagePath: 'assets/images/icons/select8.png',
    angle: 4,
    imageRotation: 0,
    imageTop: 10,
    imageLeft: 72,
    width: 175,
    height: 230,
    scale: 0.48,
    // 图文绝对坐标偏移
    iconPath: 'assets/images/icons/sun.png',
    iconSize: 46,
    fontSize: 14,
    iconOffset: const Offset(33, -88),
    textOffset: const Offset(33, -60),
    glowColor: const Color(0xFFFFE484), // 黄色
  ),
];

class MoodPickerSheet extends StatefulWidget {
  const MoodPickerSheet({super.key});

  @override
  State<MoodPickerSheet> createState() => _MoodPickerSheetState();
}

class _MoodPickerSheetState extends State<MoodPickerSheet> {
  int? _selectedIndex;

  void _handleTap(Offset localPosition, double baseWheelSize) {
    // 中心点就是宽度/高度的一半
    final double center = baseWheelSize / 2;
    final double dx = localPosition.dx - center;
    final double dy = localPosition.dy - center;
    final double distance = math.sqrt(dx * dx + dy * dy);

    // 如果点击实在太靠近中心（小白点区域）或者太靠外，忽略它
    if (distance < 20 || distance > baseWheelSize / 2) {
      if (_selectedIndex != null) {
        setState(() => _selectedIndex = null);
      }
      return;
    }

    // 以中心点为原点，计算手指触摸的角度 (-pi to pi)
    final double tapAngle = math.atan2(dy, dx);

    int? bestIndex;
    double minAngleDiff = double.infinity;

    for (int i = 0; i < kMoods.length; i++) {
      final item = kMoods[i];
      // 我们用对应图标的向量位置来代表该切片最准确的极座标分布方向
      final offset = item.iconOffset ?? Offset.zero;
      final itemAngle = math.atan2(offset.dy, offset.dx);

      double diff = (tapAngle - itemAngle).abs();
      // 将差值约束在 0 到 pi 之间，寻找最短几何夹角
      if (diff > math.pi) {
        diff = 2 * math.pi - diff;
      }

      if (diff < minAngleDiff) {
        minAngleDiff = diff;
        bestIndex = i;
      }
    }

    if (bestIndex != null) {
      setState(() {
        if (_selectedIndex == bestIndex) {
          _selectedIndex = null; // 再次点击取消高亮
        } else {
          _selectedIndex = bestIndex;
        }
      });
    }
  }

  // 构建一个包含外围阴影发光的辅助图层组件，通过 8 个圆周方向偏移生成等厚度的外轮廓
  Widget _buildGlowLayer({
    required Widget child,
    required Color color,
    required double strokeWidth,
    double blurRadius = 0,
  }) {
    Widget coloredImage = ColorFiltered(
      colorFilter: ColorFilter.mode(color, BlendMode.srcIn),
      child: child,
    );

    if (blurRadius > 0) {
      coloredImage = ImageFiltered(
        imageFilter: ui.ImageFilter.blur(
          sigmaX: blurRadius,
          sigmaY: blurRadius,
        ),
        child: coloredImage,
      );
    }

    return Stack(
      alignment: Alignment.center,
      children: [
        for (double angle = 0; angle < 2 * math.pi; angle += math.pi / 4)
          Transform.translate(
            offset: Offset(
              math.cos(angle) * strokeWidth,
              math.sin(angle) * strokeWidth,
            ),
            child: coloredImage,
          ),
      ],
    );
  }

  // 辅助函数：当某个切片被选中时，沿其图文所在的极座标径向向外推离中心一段距离
  Offset _getPopOutOffset(int index) {
    if (_selectedIndex != index) return Offset.zero;
    final item = kMoods[index];
    final offset = item.iconOffset ?? Offset.zero;
    if (offset.dx == 0 && offset.dy == 0) return Offset.zero;

    // 向外弹射的位移量 (像素)
    const double popDistance = 15.0;

    // 计算方向 (弧度)
    final double angleRad = math.atan2(offset.dy, offset.dx);

    return Offset(
      math.cos(angleRad) * popDistance,
      math.sin(angleRad) * popDistance,
    );
  }

  @override
  Widget build(BuildContext context) {
    // 获取当前屏幕的宽度，做响应式适配
    final screenWidth = MediaQuery.of(context).size.width;

    // 设定转盘占屏幕宽度的比例 (1.25 表示超出屏幕一点，显得更饱满)
    final displaySize = screenWidth * 1;

    // 微调各种偏移量的基准画布大小
    const double baseWheelSize = 400.0;

    return GestureDetector(
      onTap: () => Navigator.pop(context),
      behavior: HitTestBehavior.opaque,
      child: Material(
        color: Colors.black.withOpacity(0.6), // 遮罩层背景
        child: Center(
          child: GestureDetector(
            onTap: () {}, // 拦截点击事件，防止误触关闭
            // 外层的 SizedBox 决定最终在屏幕上显示的物理大小
            child: SizedBox(
              width: displaySize,
              height: displaySize,
              child: FittedBox(
                fit: BoxFit.cover,
                child: SizedBox(
                  width: baseWheelSize,
                  height: baseWheelSize,
                  child: Stack(
                    alignment: Alignment.center,
                    clipBehavior: Clip.none,
                    children: [
                      // 底层白色圆盘背景 (增加透明度，呈现磨砂质感)
                      Container(
                        width: 320,
                        height: 320,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(
                            0.30,
                          ), // 稍微提亮一点核心白色底，显得通透
                          shape: BoxShape.circle,
                          boxShadow: [
                            // 第一层外围光：极大面积的空气感散光 (偏暖白)
                            BoxShadow(
                              color: const Color.fromARGB(255, 255, 250, 240)
                                  .withOpacity(
                                    0.30,
                                  ), // 提升透明度，同时颜色大幅偏向白色 (FloralWhite)
                              blurRadius: 60,
                              spreadRadius: 10,
                            ),
                            // 第二层内交界光：贴合白色底盘边缘的实体高光
                            BoxShadow(
                              color: const Color.fromARGB(
                                255,
                                255,
                                255,
                                250,
                              ).withOpacity(0.5), // 几乎纯白带一点点暖意 (Snow)
                              blurRadius: 20,
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                      ),

                      // 全盘手势接管层区
                      GestureDetector(
                        onTapUp: (details) {
                          _handleTap(details.localPosition, baseWheelSize);
                        },
                        child: Container(
                          width: baseWheelSize,
                          height: baseWheelSize,
                          color: Colors.transparent, // 设置透明色拦截手指事件
                          child: Stack(
                            alignment: Alignment.center,
                            clipBehavior: Clip.none,
                            children: [
                              // 心情选项图标层 (因为原来的切片偏右下一点，所以全局往左上平移一点来纠正视觉居中)
                              Transform.translate(
                                offset: const Offset(-5, -4),
                                child: Stack(
                                  alignment: Alignment.center,
                                  clipBehavior: Clip.none,
                                  children: [
                                    // 1. 独立渲染在最底层的“扇形图片块”
                                    ...List.generate(kMoods.length, (index) {
                                      final item = kMoods[index];
                                      if (item.imagePath == null) {
                                        return const SizedBox.shrink();
                                      }

                                      final offset = _getPopOutOffset(index);

                                      return AnimatedContainer(
                                        duration: const Duration(
                                          milliseconds: 300,
                                        ),
                                        curve: Curves.easeOutBack,
                                        transform: Matrix4.translationValues(
                                          offset.dx,
                                          offset.dy,
                                          0,
                                        ),
                                        child: Transform.rotate(
                                          angle: item.angle * math.pi / 180,
                                          child: Stack(
                                            alignment: Alignment.center,
                                            clipBehavior: Clip.none,
                                            children: [
                                              Positioned(
                                                bottom:
                                                    (baseWheelSize / 2) +
                                                    (item.imageTop ?? 0),
                                                left: item.imageLeft,
                                                right: 0,
                                                child: Transform.rotate(
                                                  angle:
                                                      (item.imageRotation ??
                                                          0) *
                                                      math.pi /
                                                      180,
                                                  child: Transform.scale(
                                                    scale: item.scale ?? 1.0,
                                                    alignment:
                                                        Alignment.bottomCenter,
                                                    child: Stack(
                                                      alignment: Alignment
                                                          .bottomCenter,
                                                      children: [
                                                        // 1. 最外层的柔和彩色发光
                                                        if (_selectedIndex ==
                                                            index)
                                                          _buildGlowLayer(
                                                            child: Image.asset(
                                                              item.imagePath!,
                                                              width: item.width,
                                                              height:
                                                                  item.height,
                                                              fit:
                                                                  (item.width !=
                                                                          null ||
                                                                      item.height !=
                                                                          null)
                                                                  ? BoxFit
                                                                        .contain
                                                                  : BoxFit.none,
                                                              alignment: Alignment
                                                                  .bottomCenter,
                                                            ),
                                                            color:
                                                                item.glowColor ??
                                                                Colors.white,
                                                            strokeWidth: 6.0,
                                                            blurRadius: 8.0,
                                                          ),
                                                        // 2. 内层的锐利白色描边
                                                        if (_selectedIndex ==
                                                            index)
                                                          _buildGlowLayer(
                                                            child: Image.asset(
                                                              item.imagePath!,
                                                              width: item.width,
                                                              height:
                                                                  item.height,
                                                              fit:
                                                                  (item.width !=
                                                                          null ||
                                                                      item.height !=
                                                                          null)
                                                                  ? BoxFit
                                                                        .contain
                                                                  : BoxFit.none,
                                                              alignment: Alignment
                                                                  .bottomCenter,
                                                            ),
                                                            color: Colors.white,
                                                            strokeWidth: 6.0,
                                                          ),
                                                        // 3. 原本的图片
                                                        Image.asset(
                                                          item.imagePath!,
                                                          width: item.width,
                                                          height: item.height,
                                                          fit:
                                                              (item.width !=
                                                                      null ||
                                                                  item.height !=
                                                                      null)
                                                              ? BoxFit.contain
                                                              : BoxFit.none,
                                                          alignment: Alignment
                                                              .bottomCenter,
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      );
                                    }),

                                    // 2. 独立渲染在层上的“图标”
                                    ...List.generate(kMoods.length, (index) {
                                      final item = kMoods[index];
                                      if (item.iconPath == null)
                                        return const SizedBox.shrink();

                                      final offsetAnim = _getPopOutOffset(
                                        index,
                                      );

                                      return AnimatedContainer(
                                        duration: const Duration(
                                          milliseconds: 300,
                                        ),
                                        curve: Curves.easeOutBack,
                                        transform: Matrix4.translationValues(
                                          offsetAnim.dx,
                                          offsetAnim.dy,
                                          0,
                                        ),
                                        child: Center(
                                          child: Transform.translate(
                                            offset:
                                                item.iconOffset ?? Offset.zero,
                                            child: Transform.rotate(
                                              angle:
                                                  (item.iconRotation ?? 0) *
                                                  math.pi /
                                                  180,
                                              child: Image.asset(
                                                item.iconPath!,
                                                width: item.iconSize ?? 40,
                                                height: item.iconSize ?? 40,
                                                fit: BoxFit.contain,
                                              ),
                                            ),
                                          ),
                                        ),
                                      );
                                    }),

                                    // 3. 独立渲染在层上的“文字”
                                    ...List.generate(kMoods.length, (index) {
                                      final item = kMoods[index];
                                      if (item.label.isEmpty)
                                        return const SizedBox.shrink();

                                      final offsetAnim = _getPopOutOffset(
                                        index,
                                      );

                                      return AnimatedContainer(
                                        duration: const Duration(
                                          milliseconds: 300,
                                        ),
                                        curve: Curves.easeOutBack,
                                        transform: Matrix4.translationValues(
                                          offsetAnim.dx,
                                          offsetAnim.dy,
                                          0,
                                        ),
                                        child: Center(
                                          child: Transform.translate(
                                            offset:
                                                item.textOffset ?? Offset.zero,
                                            child: Transform.rotate(
                                              angle:
                                                  (item.textRotation ?? 0) *
                                                  math.pi /
                                                  180,
                                              child: Text(
                                                item.label,
                                                textAlign: TextAlign.center,
                                                style: TextStyle(
                                                  color: const Color(
                                                    0xFF4A3424,
                                                  ), // 深棕色字体
                                                  fontSize: item.fontSize ?? 16,
                                                  fontWeight: FontWeight.w600,
                                                  height: 1.0, // 去除默认行高间隙
                                                ),
                                              ),
                                            ),
                                          ),
                                        ),
                                      );
                                    }),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      // 3. 中心基准小白点
                      Container(
                        width: 10,
                        height: 10,
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(color: Colors.black26, blurRadius: 4),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
