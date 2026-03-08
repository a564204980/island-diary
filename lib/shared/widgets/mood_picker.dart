import 'dart:math' as math;
import 'package:flutter/material.dart';

class MoodItem {
  final String label;
  final String? imagePath;
  final double angle; // 圆盘方位角
  final double? imageRotation; // 贴图自身旋转角(角度)
  final double? imageTop; // 现在定义为：径向偏移 (正数远离圆心，负数靠近圆心)
  final double? imageLeft; // 现在定义为：切向偏移 (左右微调)
  final double? width;
  final double? height;
  final double? scale;

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
  });
}

// 示例数据，参数现在变得非常直观
const List<MoodItem> kMoods = [
  MoodItem(
    label: '期待',
    imagePath: 'assets/images/icons/select1.png',
    angle: 0,
    imageRotation: 0,
    imageTop: 8, // 正数往上推
    imageLeft: -60,
    width: 205,
    height: 286,
    scale: 0.30,
  ),
  MoodItem(
    label: '厌恶',
    imagePath: 'assets/images/icons/select2.png',
    angle: 315,
    imageRotation: 40,
    imageTop: 6, // 往外推 10 像素
    imageLeft: 82,
    width: 324,
    height: 237,
    scale: 0.3,
  ),
  MoodItem(
    label: '恐惧',
    imagePath: 'assets/images/icons/select3.png',
    angle: 270,
    imageRotation: 90,
    imageTop: -72, // 负数往右
    imageLeft: 112, // 居中
    width: 324,
    height: 241,
    scale: 0.33,
  ),
  MoodItem(
    label: '惊喜',
    imagePath: 'assets/images/icons/select4.png',
    angle: 225,
    imageRotation: 135,
    imageTop: -204, // 负数往上推
    imageLeft: 149, // 正数往左推
    width: 230,
    height: 345,
    scale: 0.28,
  ),
  MoodItem(
    label: '惊喜',
    imagePath: 'assets/images/icons/select5.png',
    angle: 180,
  ),
  MoodItem(
    label: '恐惧',
    imagePath: 'assets/images/icons/select6.png',
    angle: 225,
  ),
  MoodItem(
    label: '厌恶',
    imagePath: 'assets/images/icons/select7.png',
    angle: 270,
  ),
  MoodItem(
    label: '期待',
    imagePath: 'assets/images/icons/select8.png',
    angle: 315,
  ),
];

class MoodPickerSheet extends StatelessWidget {
  const MoodPickerSheet({super.key});

  @override
  Widget build(BuildContext context) {
    const double wheelSize = 400.0;

    return GestureDetector(
      onTap: () => Navigator.pop(context),
      behavior: HitTestBehavior.opaque,
      child: Material(
        color: Colors.black.withOpacity(0.35),
        child: Center(
          child: GestureDetector(
            onTap: () {},
            child: SizedBox(
              width: wheelSize,
              height: wheelSize,
              child: Stack(
                alignment: Alignment.center,
                clipBehavior: Clip.none,
                children: [
                  ...List.generate(kMoods.length, (index) {
                    final item = kMoods[index];
                    if (item.imagePath == null) return const SizedBox.shrink();

                    // 核心重构：解耦旋转与位移
                    // 我们让每个分片都从中心点 (0,0) 开始，先做垂直位移，再做旋转
                    return Transform.rotate(
                      angle: item.angle * math.pi / 180,
                      child: Stack(
                        alignment: Alignment.center,
                        clipBehavior: Clip.none,
                        children: [
                          Positioned(
                            // 1. 设置径向和切向偏移
                            // 此时在局部坐标系中，顶部就是圆外，底部就是圆心
                            bottom: (wheelSize / 2) + (item.imageTop ?? 0),
                            left: item.imageLeft,
                            right: 0,
                            child: Transform.rotate(
                              // 2. 贴图自身相位校准
                              angle: (item.imageRotation ?? 0) * math.pi / 180,
                              child: Transform.scale(
                                // 3. 缩放
                                scale: item.scale ?? 1.0,
                                alignment: Alignment.bottomCenter,
                                child: Image.asset(
                                  item.imagePath!,
                                  width: item.width,
                                  height: item.height,
                                  fit:
                                      (item.width != null ||
                                          item.height != null)
                                      ? BoxFit.contain
                                      : BoxFit.none,
                                  alignment: Alignment.bottomCenter,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  }),

                  // 中心基准点
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
    );
  }
}
