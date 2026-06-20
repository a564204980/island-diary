import 'dart:math' as math;
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:island_diary/core/state/user_state.dart';
import 'package:island_diary/core/models/mascot_decoration.dart';
import 'pseudo_3d_prop_widget.dart';
import '../diary_entry/components/diary_bottom_sheet.dart';
import 'package:island_diary/shared/utils/toast_utils.dart';

/// 调出道具获得半屏弹窗（针对普通稀有度自动采用纯色简约风格）
Future<void> showPropObtainedPopup(BuildContext context, MascotDecoration decoration, {VoidCallback? onEquip}) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    barrierColor: Colors.black.withValues(alpha: 0.3), // 极简半透明遮罩
    showDragHandle: false, // 禁用系统默认手势条，避免出现双重拖拽条
    builder: (context) {
      return _PropObtainedPopupWidget(
        decoration: decoration,
        onEquip: onEquip,
      );
    },
  );
}

class _PropObtainedPopupWidget extends StatefulWidget {
  final MascotDecoration decoration;
  final VoidCallback? onEquip;

  const _PropObtainedPopupWidget({
    required this.decoration,
    this.onEquip,
  });

  @override
  State<_PropObtainedPopupWidget> createState() => _PropObtainedPopupWidgetState();
}

class _PropObtainedPopupWidgetState extends State<_PropObtainedPopupWidget>
    with TickerProviderStateMixin {
  late AnimationController _particleController;
  
  final List<_CozyParticle> _particles = [];
  final int _particleCount = 12;

  @override
  void initState() {
    super.initState();
    _particleController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 7),
    )..repeat();

    // 随机粒子（仅高阶饰品使用）
    final random = math.Random();
    for (int i = 0; i < _particleCount; i++) {
      _particles.add(_CozyParticle(
        xRatio: random.nextDouble(),
        yRatio: random.nextDouble() * 0.8,
        speed: 1.0 + random.nextInt(2), // 整数位移倍数，消除循环跳变
        size: 1.5 + random.nextDouble() * 2.5,
        opacity: 0.15 + random.nextDouble() * 0.4,
        amplitude: 8 + random.nextDouble() * 12,
        frequency: 1.0 + random.nextInt(2), // 整数周期，确保正弦曲线无缝首尾衔接
        phase: random.nextDouble() * math.pi * 2,
      ));
    }
  }

  @override
  void dispose() {
    _particleController.dispose();
    super.dispose();
  }

  void _autoEquip() {
    final path = widget.decoration.path;
    switch (widget.decoration.category) {
      case MascotDecorationCategory.hat:
      case MascotDecorationCategory.hair:
      case MascotDecorationCategory.hairAccessory:
        UserState().setMascotDecoration(path);
        break;
      case MascotDecorationCategory.glasses:
        UserState().setSelectedGlassesDecoration(path);
        break;
      case MascotDecorationCategory.face:
        UserState().setSelectedEarringDecoration(path);
        break;
      case MascotDecorationCategory.other:
        UserState().setSelectedBackgroundDecoration(path);
        break;
    }
    
    widget.onEquip?.call();
    Navigator.pop(context);
    
    showTopToast(context, '已佩戴 ${widget.decoration.name} ✨');
  }

  String _getCategoryActionText(MascotDecorationCategory category) {
    switch (category) {
      case MascotDecorationCategory.hat:
        return '解锁了新发饰';
      case MascotDecorationCategory.hair:
        return '解锁了新发型';
      case MascotDecorationCategory.hairAccessory:
        return '解锁了新发饰';
      case MascotDecorationCategory.glasses:
        return '解锁了新眼镜';
      case MascotDecorationCategory.face:
        return '解锁了新耳饰';
      case MascotDecorationCategory.other:
        return '解锁了新背景';
    }
  }

  IconData _getCategoryIcon(MascotDecorationCategory category) {
    switch (category) {
      case MascotDecorationCategory.hat:
      case MascotDecorationCategory.hair:
      case MascotDecorationCategory.hairAccessory:
        return Icons.auto_awesome_rounded;
      case MascotDecorationCategory.glasses:
        return Icons.face_retouching_natural_rounded;
      case MascotDecorationCategory.face:
        return Icons.star_rounded;
      case MascotDecorationCategory.other:
        return Icons.wallpaper_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isNight = UserState().isNight;
    final rarityColor = widget.decoration.rarity.color;

    // 是否是普通/史诗/传说饰品
    final bool isCommon = widget.decoration.rarity == MascotRarity.common;
    final bool isLegendary = widget.decoration.rarity == MascotRarity.legendary;
    final bool isEpic = widget.decoration.rarity == MascotRarity.epic;

    final Color textColor = isNight ? Colors.white70 : const Color(0xFF2D3748);
    final Color titleColor = isNight ? Colors.white : const Color(0xFF1A1A1A);
    final Color subtitleColor = isNight ? Colors.white38 : Colors.black38;

    // 背景装饰 (传说和卓越采用精美微弱渐变，烘托高级感)
    final BoxDecoration bgDecoration;
    final Border? topRim;
    if (isLegendary) {
      topRim = Border(
        top: BorderSide(
          color: const Color(0xFFFBBF24).withValues(alpha: 0.35),
          width: 2.0,
        ),
      );
      bgDecoration = BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: isNight
              ? [
                  const Color(0xFF18130B),
                  const Color(0xFF2D2314),
                  const Color(0xFF18130B),
                ]
              : [
                  const Color(0xFFFFFDF5),
                  const Color(0xFFFFF9E6),
                  const Color(0xFFFFF3CE),
                ],
        ),
      );
    } else if (isEpic) {
      topRim = Border(
        top: BorderSide(
          color: const Color(0xFFA78BFA).withValues(alpha: 0.35),
          width: 2.0,
        ),
      );
      bgDecoration = BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: isNight
              ? [
                  const Color(0xFF130F1F),
                  const Color(0xFF221A37),
                  const Color(0xFF130F1F),
                ]
              : [
                  const Color(0xFFFAF5FF),
                  const Color(0xFFF5E6FF),
                  const Color(0xFFE8D4FF),
                ],
        ),
      );
    } else {
      topRim = null;
      bgDecoration = BoxDecoration(
        color: isNight 
            ? (UserState().selectedIslandThemeId.value == 'cotton_candy' 
                ? const Color(0xFF1E1B2E) 
                : (UserState().selectedIslandThemeId.value == 'lego' ? const Color(0xFF18181B) : const Color(0xFF162537)))
            : (UserState().selectedIslandThemeId.value == 'cotton_candy' 
                ? const Color(0xFFFAF5FF)
                : (UserState().selectedIslandThemeId.value == 'lego' ? const Color(0xFFF9FAFB) : Colors.white)),
      );
    }

    final containerDecoration = bgDecoration.copyWith(
      borderRadius: const BorderRadius.only(
        topLeft: Radius.circular(32),
        topRight: Radius.circular(32),
      ),
      border: topRim,
    );

    final bool shouldOverflow = widget.decoration.shouldOverflowInPopup;

    // 专属背景图片层资产路径（当非夜间模式时使用，与衣帽间保持一致）
    String? customBgAsset;
    if (!isNight) {
      if (widget.decoration.id == 'mask') {
        customBgAsset = 'assets/images/emoji/modules_bg/gaoda_bg.png';
      } else if (widget.decoration.id == 'phoenix_crown') {
        customBgAsset = 'assets/images/emoji/modules_bg/ruyifengguan_bg.png';
      } else if (widget.decoration.id == 'yellow_duck_hat') {
        customBgAsset = 'assets/images/emoji/modules_bg/9.png';
      } else if (widget.decoration.id == 'candy_heart_lion') {
        customBgAsset = 'assets/images/emoji/modules_bg/4.png';
      } else if (widget.decoration.id == 'flower_appointment') {
        customBgAsset = 'assets/images/emoji/modules_bg/5.png';
      } else if (widget.decoration.id == 'ultraman') {
        customBgAsset = 'assets/images/emoji/modules_bg/6.png';
      } else if (widget.decoration.id == 'flower') {
        customBgAsset = 'assets/images/emoji/modules_bg/7.png';
      } else if (widget.decoration.id == 'butterfly_wreath') {
        customBgAsset = 'assets/images/emoji/modules_bg/8.png';
      } else if (widget.decoration.id == 'reindeer') {
        customBgAsset = 'assets/images/emoji/modules_bg/10.png';
      } else if (widget.decoration.id == 'luo_yan') {
        customBgAsset = 'assets/images/emoji/modules_bg/11.png';
      } else if (widget.decoration.id == 'chen_yu') {
        customBgAsset = 'assets/images/emoji/modules_bg/12.png';
      } else if (widget.decoration.id == 'red_long_tassel') {
        customBgAsset = 'assets/images/emoji/modules_bg/13.png';
      } else if (widget.decoration.rarity == MascotRarity.legendary && 
                 widget.decoration.category != MascotDecorationCategory.hat) {
        customBgAsset = 'assets/images/review/chuanshuo_bg.png';
      } else if (widget.decoration.rarity == MascotRarity.epic) {
        customBgAsset = 'assets/images/review/zhuoyue_bg.png';
      } else if (widget.decoration.rarity == MascotRarity.rare) {
        customBgAsset = 'assets/images/review/xiyou_bg.png';
      }
    }

    return DiaryBottomSheet(
      paperStyle: 'default',
      showDragHandle: false,
      isDiary: false,
      padding: EdgeInsets.zero,
      clipBehavior: shouldOverflow ? Clip.none : Clip.antiAlias,
      child: Container(
        decoration: containerDecoration,
        clipBehavior: shouldOverflow ? Clip.none : Clip.antiAlias,
        child: Stack(
          clipBehavior: shouldOverflow ? Clip.none : Clip.antiAlias,
          children: [
            // 0. 专属背景图片层
            if (customBgAsset != null)
              Positioned.fill(
                child: ClipRRect(
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(32),
                    topRight: Radius.circular(32),
                  ),
                  child: Image.asset(
                    customBgAsset,
                    fit: BoxFit.cover,
                  ),
                ),
              ),

            // 1. 微风星光粒子层 (卓越/传说饰品使用四角星光辉)
            if (!isCommon)
              Positioned.fill(
                child: AnimatedBuilder(
                  animation: _particleController,
                  builder: (context, child) {
                    return CustomPaint(
                      painter: _CozyParticlePainter(
                        particles: _particles,
                        progress: _particleController.value,
                        color: isLegendary
                            ? (isNight ? const Color(0xFFFBBF24) : const Color(0xFFD97706))
                            : (isEpic 
                                ? (isNight ? const Color(0xFFC084FC) : const Color(0xFF9333EA))
                                : (isNight ? const Color(0xFFFFD54F) : const Color(0xFFF59E0B))),
                        isPremium: isLegendary || isEpic,
                      ),
                    );
                  },
                ),
              ),

            // 2. 主页面内容
            Padding(
              padding: EdgeInsets.only(
                left: 24,
                right: 24,
                top: 0,
                bottom: 20 + MediaQuery.of(context).padding.bottom,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (shouldOverflow) ...[
                    // 溢出布局：顶部留空 90 像素供图片超出部分占位
                    const SizedBox(height: 90),

                    // 顶部获得副标题 (加图标与更优雅的话术)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          _getCategoryIcon(widget.decoration.category),
                          size: 13,
                          color: isCommon 
                              ? subtitleColor 
                              : rarityColor.withValues(alpha: 0.8),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          _getCategoryActionText(widget.decoration.category),
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: subtitleColor,
                            letterSpacing: 1.0,
                            fontFamily: 'LXGWWenKai',
                          ),
                        ),
                        const SizedBox(width: 8),
                        Icon(
                          _getCategoryIcon(widget.decoration.category),
                          size: 13,
                          color: isCommon 
                              ? subtitleColor 
                              : rarityColor.withValues(alpha: 0.8),
                        ),
                      ],
                    ).animate().fadeIn(duration: 250.ms),

                    const SizedBox(height: 12),
                  ] else ...[
                    // 经典布局
                    // 顶部拖拽手势条
                    const SizedBox(height: 12),
                    Center(
                      child: Container(
                        width: 40,
                        height: 4.5,
                        decoration: BoxDecoration(
                          color: isLegendary
                              ? const Color(0xFFF59E0B).withValues(alpha: 0.3)
                              : (isEpic 
                                  ? const Color(0xFFA855F7).withValues(alpha: 0.3)
                                  : (isNight ? Colors.white24 : Colors.black12)),
                          borderRadius: BorderRadius.circular(2.25),
                        ),
                      ),
                    ),
                    const SizedBox(height: 18),

                    // 顶部获得副标题
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          _getCategoryIcon(widget.decoration.category),
                          size: 13,
                          color: isCommon 
                              ? subtitleColor 
                              : rarityColor.withValues(alpha: 0.8),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          _getCategoryActionText(widget.decoration.category),
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: subtitleColor,
                            letterSpacing: 1.0,
                            fontFamily: 'LXGWWenKai',
                          ),
                        ),
                        const SizedBox(width: 8),
                        Icon(
                          _getCategoryIcon(widget.decoration.category),
                          size: 13,
                          color: isCommon 
                              ? subtitleColor 
                              : rarityColor.withValues(alpha: 0.8),
                        ),
                      ],
                    ).animate().fadeIn(duration: 250.ms),

                    const SizedBox(height: 12),

                    // 伪 3D 道具展示 (不溢出时直接作为 Column 的子组件排在这里)
                    Pseudo3DPropWidget(
                      imagePath: widget.decoration.path,
                      glowColor: isCommon ? Colors.transparent : rarityColor,
                      size: 180,
                    ).animate().scale(
                      duration: 500.ms,
                      curve: Curves.easeOutCubic,
                      begin: const Offset(0.7, 0.7),
                    ),

                    const SizedBox(height: 14),
                  ],

                  // 饰品名称与等级标签 (标签在上居中，名称在下居中)
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // 饰品等级标签
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
                        decoration: BoxDecoration(
                          color: rarityColor.withValues(alpha: isNight ? 0.15 : 0.08),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                            color: rarityColor.withValues(alpha: 0.25),
                            width: 0.8,
                          ),
                        ),
                        child: Text(
                          widget.decoration.rarity.label,
                          style: TextStyle(
                            color: rarityColor,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'LXGWWenKai',
                          ),
                        ),
                      ),
                      const SizedBox(height: 4),
                      // 饰品名称（居中）
                      Text(
                        widget.decoration.name,
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          color: titleColor,
                          fontFamily: 'LXGWWenKai',
                          letterSpacing: 1.5,
                        ),
                      ),
                    ],
                  ).animate().fadeIn(delay: 100.ms, duration: 250.ms),


                  // 极细高级感横向分割线 (更换为国风两端渐变 + 中间小菱形点缀设计)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // 左侧渐变线
                        Container(
                          width: 36,
                          height: 0.8,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                rarityColor.withValues(alpha: 0.0),
                                rarityColor.withValues(alpha: 0.4),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        // 中间点缀小菱形
                        Transform.rotate(
                          angle: 45 * 3.1415926535 / 180,
                          child: Container(
                            width: 5,
                            height: 5,
                            color: rarityColor.withValues(alpha: 0.6),
                          ),
                        ),
                        const SizedBox(width: 6),
                        // 右侧渐变线
                        Container(
                          width: 36,
                          height: 0.8,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                rarityColor.withValues(alpha: 0.4),
                                rarityColor.withValues(alpha: 0.0),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // 温馨文字介绍 (提升行高与主次对比)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 48),
                    child: Text(
                      widget.decoration.description,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 13,
                        color: textColor.withValues(alpha: 0.65), // 正文微弱淡化，突出标题
                        height: 1.75, // 宽行距，视觉呼吸感
                        letterSpacing: 0.4,
                        fontFamily: 'LXGWWenKai',
                      ),
                    ),
                  ).animate().fadeIn(delay: 200.ms, duration: 250.ms),

                  const SizedBox(height: 8),

                  // 底部操作按钮：华为风格简约纯色药丸设计
                  Row(
                    children: [
                      // “收下”按钮
                      Expanded(
                        child: GestureDetector(
                          onTap: () => Navigator.pop(context),
                          child: Container(
                            height: 48,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(24),
                              color: isNight 
                                  ? Colors.white.withValues(alpha: 0.06) 
                                  : Colors.black.withValues(alpha: 0.04),
                            ),
                            child: Text(
                              '收下',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                                color: isNight ? Colors.white70 : Colors.black87,
                                fontFamily: 'LXGWWenKai',
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      // “立即戴上”按钮
                      Expanded(
                        child: GestureDetector(
                          onTap: _autoEquip,
                          child: Container(
                            height: 48,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(24),
                              gradient: isLegendary
                                  ? const LinearGradient(
                                      colors: [Color(0xFFFBBF24), Color(0xFFD97706)],
                                    )
                                  : (isEpic
                                      ? const LinearGradient(
                                          colors: [Color(0xFFA78BFA), Color(0xFF7C3AED)],
                                        )
                                      : null),
                              color: (isLegendary || isEpic)
                                  ? null
                                  : (isCommon 
                                      ? (isNight ? Colors.white : const Color(0xFF1A1A1A)) 
                                      : rarityColor),
                              boxShadow: isCommon 
                                  ? null 
                                  : [
                                      BoxShadow(
                                        color: isLegendary
                                            ? const Color(0xFFF59E0B).withValues(alpha: 0.35)
                                            : (isEpic
                                                ? const Color(0xFFA855F7).withValues(alpha: 0.35)
                                                : rarityColor.withValues(alpha: 0.25)),
                                        blurRadius: 12,
                                        offset: const Offset(0, 4),
                                      ),
                                    ],
                            ),
                            child: Text(
                              '立即戴上',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                                color: isCommon
                                    ? (isNight ? const Color(0xFF1A1A1A) : Colors.white)
                                    : Colors.white,
                                fontFamily: 'LXGWWenKai',
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ).animate().fadeIn(delay: 300.ms, duration: 250.ms),
                ],
              ),
            ),

            // 3. 悬浮溢出的饰品图片展示 (仅在 shouldOverflow 为 true 时，通过 Stack 定位在顶部中心，向上溢出 90 像素)
            if (shouldOverflow)
              Positioned(
                top: -90,
                left: 0,
                right: 0,
                child: Center(
                  child: Pseudo3DPropWidget(
                    imagePath: widget.decoration.path,
                    glowColor: isCommon ? Colors.transparent : rarityColor,
                    size: 180,
                  ).animate().scale(
                    duration: 500.ms,
                    curve: Curves.easeOutCubic,
                    begin: const Offset(0.7, 0.7),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _CozyParticle {
  final double xRatio;
  final double yRatio;
  final double speed;
  final double size;
  final double opacity;
  final double amplitude;
  final double frequency;
  final double phase;

  _CozyParticle({
    required this.xRatio,
    required this.yRatio,
    required this.speed,
    required this.size,
    required this.opacity,
    required this.amplitude,
    required this.frequency,
    required this.phase,
  });
}

class _CozyParticlePainter extends CustomPainter {
  final List<_CozyParticle> particles;
  final double progress;
  final Color color;
  final bool isPremium;

  _CozyParticlePainter({
    required this.particles,
    required this.progress,
    required this.color,
    required this.isPremium,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;

    for (var particle in particles) {
      double y = (particle.yRatio * size.height + progress * particle.speed * size.height) % size.height;
      double sweep = math.sin(progress * math.pi * 2 * particle.frequency + particle.phase) * particle.amplitude;
      double x = (particle.xRatio * size.width + sweep) % size.width;

      double localOpacity = particle.opacity;
      if (y < 40) {
        localOpacity *= (y / 40);
      } else if (y > size.height - 40) {
        localOpacity *= ((size.height - y) / 40);
      }

      paint.color = color.withValues(alpha: (localOpacity * (isPremium ? 0.75 : 0.4)).clamp(0.0, 1.0));
      
      if (isPremium) {
        final starSize = particle.size * 2.2;
        _drawStar(canvas, Offset(x, y), starSize, paint);
      } else {
        canvas.drawCircle(Offset(x, y), particle.size / 2, paint);
      }
    }
  }

  void _drawStar(Canvas canvas, Offset center, double size, Paint paint) {
    final path = Path();
    path.moveTo(center.dx, center.dy - size);
    path.quadraticBezierTo(center.dx, center.dy, center.dx + size, center.dy);
    path.quadraticBezierTo(center.dx, center.dy, center.dx, center.dy + size);
    path.quadraticBezierTo(center.dx, center.dy, center.dx - size, center.dy);
    path.quadraticBezierTo(center.dx, center.dy, center.dx, center.dy - size);
    path.close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _CozyParticlePainter oldDelegate) => true;
}
