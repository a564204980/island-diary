import 'dart:ui';
import 'dart:math' as math;
import 'package:flutter/material.dart';

import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:island_diary/core/state/user_state.dart';

class SecurityCenterPage extends StatelessWidget {
  const SecurityCenterPage({super.key});

  @override
  Widget build(BuildContext context) {
    final userState = UserState();

    return ListenableBuilder(
      listenable: Listenable.merge([
        userState.isAppLockEnabled,
        userState.appLockPin,
        userState.isBiometricEnabled,
        userState.isMistModeEnabled,
        userState.destructionCode,
        userState.themeMode,
      ]),
      builder: (context, child) {
        final isNight = userState.isNight;
        final isEnabled = userState.isAppLockEnabled.value;

        return Scaffold(
          backgroundColor: isNight ? Colors.black : const Color(0xFFFDFCF7), 
          extendBodyBehindAppBar: true,
          appBar: AppBar(
            title: Text(
              '灵魂避难所', 
              style: TextStyle(
                fontWeight: FontWeight.w900, 
                color: isNight ? Colors.white : const Color(0xFF1E3A34), 
                fontSize: 18, 
                letterSpacing: 2
              )
            ),
            backgroundColor: Colors.transparent,
            elevation: 0,
            centerTitle: true,
            leading: IconButton(
              icon: Icon(Icons.arrow_back_ios_new, size: 18, color: isNight ? Colors.white70 : Colors.black54),
              onPressed: () => Navigator.pop(context),
            ),
          ),
          body: Stack(
            children: [
              // 1. 灵魂迷雾背景
              Positioned.fill(
                child: _SoulMistyBackground(isEnabled: isEnabled, isNight: isNight),
              ),
              
              SafeArea(
                child: ListView(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  physics: const BouncingScrollPhysics(),
                  children: [
                    const SizedBox(height: 20),
                    // 2. 圣洁棱镜核心
                    _buildSacredCore(isEnabled, isNight),
                    const SizedBox(height: 60),

                    // 3. 玻璃触感 BentoGrid
                    _buildPremiumBentoGrid(context, userState, isNight),
                    
                    const SizedBox(height: 40),
                    // 4. 底部图腾
                    _buildBottomTotem(isEnabled, isNight),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }



  Widget _buildSacredCore(bool isEnabled, bool isNight) {
    return Column(
      children: [
        SizedBox(
          width: 140,
          height: 140,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // 旋转的灵气环
              _RotatingRing(isEnabled: isEnabled, radius: 65, color: const Color(0xFF81C784), speed: 3),
              _RotatingRing(isEnabled: isEnabled, radius: 50, color: const Color(0xFF64B5F6), speed: -2),
              
              // 核心棱镜
              CustomPaint(
                size: const Size(60, 70),
                painter: _SacredPrismPainter(
                  color: isEnabled 
                      ? const Color(0xFF81C784) 
                      : (isNight ? Colors.white12 : Colors.black12),
                  glowIntensity: isEnabled ? 1.0 : 0.0,
                ),
              ).animate(onPlay: (c) => c.repeat(reverse: true)).moveY(
                duration: 2.seconds,
                begin: -5,
                end: 5,
                curve: Curves.easeInOutSine,
              ),

              if (isEnabled)
                Positioned.fill(
                  child: Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF81C784).withOpacity(isNight ? 0.15 : 0.08),
                          blurRadius: 40,
                          spreadRadius: 5,
                        )
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 32),
        Text(
          isEnabled ? '结界已立 · 万念皆安' : '圣殿静默 · 守护待启',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w900,
            letterSpacing: 3,
            color: isNight ? Colors.white : const Color(0xFF1E3A34), // 深森林绿
            shadows: isNight ? [const Shadow(color: Colors.black26, offset: Offset(2, 2), blurRadius: 4)] : null,
          ),
        ),
        const SizedBox(height: 8),
        Opacity(
          opacity: 0.6,
          child: Text(
            isEnabled ? '岛屿正被神圣的结界温柔笼罩' : '尚未开启结界，灵魂在旷野中流浪',
            style: TextStyle(
              fontSize: 12, 
              color: isNight ? Colors.white70 : const Color(0xFF4A615C), 
              letterSpacing: 0.5,
              fontWeight: isNight ? FontWeight.normal : FontWeight.w500,
            ),
          ),
        ),
      ],

    ).animate().fadeIn(duration: 1.seconds).scale(begin: const Offset(0.95, 0.95));
  }


  Widget _buildPremiumBentoGrid(BuildContext context, UserState state, bool isNight) {
    return Column(
      children: [
        // 主卡片：结界钥匙
        _buildAppLockPremiumCard(context, state),
        const SizedBox(height: 16),
        
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 迷雾模式
              Expanded(child: _buildMistPremiumBento(state)),
              const SizedBox(width: 16),
              // 自毁指令
              Expanded(child: _buildDestructionPremiumBento(context, state)),
            ],
          ),
        ),

      ],
    );
  }

  Widget _buildAppLockPremiumCard(BuildContext context, UserState state) {
    final isEnabled = state.isAppLockEnabled.value;
    final isNight = state.isNight;
    
    return _buildGlassContainer(
      isNight: isNight,
      child: Column(
        children: [
          Row(
            children: [
              _buildNeonIcon(Icons.key_rounded, const Color(0xFF81C784)),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('心灵结界', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w900, color: isNight ? Colors.white : const Color(0xFF1E3A34))),
                    const SizedBox(height: 2),
                    Text('岛屿的唯一进出口凭证', style: TextStyle(fontSize: 12, color: (isNight ? Colors.white : const Color(0xFF4A615C)).withOpacity(0.4))),
                  ],
                ),
              ),

              Switch.adaptive(
                value: isEnabled,
                activeColor: const Color(0xFF81C784),
                onChanged: (val) {
                  if (val && state.appLockPin.value.isEmpty) {
                    _showSetPinDialog(context, state);
                  } else {
                    state.updateSecuritySettings(appLock: val);
                  }
                },
              ),
            ],
          ),
          if (isEnabled) ...[
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 20),
              child: Divider(height: 1, color: isNight ? Colors.white10 : Colors.black.withOpacity(0.05)),
            ),
            _buildActionItem(
              icon: Icons.fingerprint_rounded,
              title: '生物骨骼密码',
              subtitle: '指纹或面孔即是钥匙',
              isNight: isNight,
              trailing: Switch.adaptive(
                value: state.isBiometricEnabled.value,
                activeColor: const Color(0xFF81C784),
                onChanged: (val) => state.updateSecuritySettings(biometric: val),
              ),
            ),
            const SizedBox(height: 16),
            _buildActionItem(
              icon: Icons.password_rounded,
              title: '重铸数字密钥',
              subtitle: '手动修改当前：${state.appLockPin.value.replaceAll(RegExp(r'.'), '*')}',
              isNight: isNight,
              onTap: () => _showSetPinDialog(context, state),
            ),
          ],
        ],
      ),
    ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.1, end: 0);
  }


  Widget _buildMistPremiumBento(UserState state) {
    final isNight = state.isNight;
    return _buildGlassContainer(
      isNight: isNight,
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildNeonIcon(Icons.waves_rounded, const Color(0xFF64B5F6)),
          const SizedBox(height: 20),
          Text('幽冥护盾', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: isNight ? Colors.white : const Color(0xFF2D3436))),
          const SizedBox(height: 6),
          Text('后台任务中隐藏记忆', style: TextStyle(fontSize: 10, color: (isNight ? Colors.white : Colors.black).withOpacity(0.3), height: 1.4)),
          const SizedBox(height: 16),
          Align(
            alignment: Alignment.centerRight,
            child: Switch.adaptive(
              value: state.isMistModeEnabled.value,
              activeColor: const Color(0xFF64B5F6),
              onChanged: (val) => state.updateSecuritySettings(mistMode: val),
            ),
          ),
        ],
      ),
    ).animate().fadeIn(delay: 400.ms).slideY(begin: 0.1, end: 0);
  }


  Widget _buildDestructionPremiumBento(BuildContext context, UserState state) {
    final hasCode = state.destructionCode.value.isNotEmpty;
    final isNight = state.isNight;
    
    return _buildGlassContainer(
      isNight: isNight,
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildNeonIcon(Icons.flare_rounded, const Color(0xFFF06292)),
          const SizedBox(height: 20),
          Text('星尘湮灭', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: isNight ? Colors.white : const Color(0xFF2D3436))),
          const SizedBox(height: 6),
          GestureDetector(
            onTap: () => _showSetDestructionDialog(context, state),
            child: Text(
              hasCode ? '湮灭法阵：已契约' : '未缔结契约',
              style: TextStyle(
                fontSize: 10, 
                color: hasCode ? const Color(0xFFF06292) : (isNight ? Colors.white : Colors.black).withOpacity(0.3),
                decoration: TextDecoration.underline,
              ),
            ),
          ),
          const SizedBox(height: 8), 
        ],
      ),
    ).animate().fadeIn(delay: 600.ms).slideY(begin: 0.1, end: 0);


  }

  Widget _buildGlassContainer({required Widget child, EdgeInsets? padding, required bool isNight}) {
    return Container(
      padding: padding ?? const EdgeInsets.all(26),
      decoration: BoxDecoration(
        color: isNight ? Colors.white.withOpacity(0.06) : Colors.white.withOpacity(0.85),
        borderRadius: BorderRadius.circular(32),
        border: Border.all(
          color: isNight ? Colors.white.withOpacity(0.12) : Colors.white,
          width: 0.8,
        ),
        boxShadow: [
          BoxShadow(
            color: isNight 
                ? Colors.black.withOpacity(0.4) 
                : const Color(0xFF7090B0).withOpacity(0.12),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
          // 内发光 / 反光层
          BoxShadow(
            color: Colors.white.withOpacity(isNight ? 0.02 : 0.4),
            spreadRadius: isNight ? -10 : -2,
            blurRadius: isNight ? 20 : 10,
          ),
        ],
      ),
      child: child,
    );
  }



  Widget _buildNeonIcon(IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: color.withOpacity(0.2), blurRadius: 15, spreadRadius: 1),
        ],
      ),
      child: Icon(icon, size: 24, color: color),
    );
  }

  Widget _buildActionItem({required IconData icon, required String title, required String subtitle, Widget? trailing, VoidCallback? onTap, required bool isNight}) {
    return InkWell(
      onTap: onTap,
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: (isNight ? Colors.white : Colors.black).withOpacity(0.05), shape: BoxShape.circle),
            child: Icon(icon, size: 18, color: isNight ? Colors.white70 : Colors.black54),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: isNight ? Colors.white : const Color(0xFF1E3A34))),
                Text(subtitle, style: TextStyle(fontSize: 11, color: isNight ? Colors.white30 : const Color(0xFF4A615C).withOpacity(0.5))),
              ],
            ),
          ),

          trailing ?? Icon(Icons.chevron_right_rounded, size: 20, color: isNight ? Colors.white24 : Colors.black26),
        ],
      ),
    );
  }

  Widget _buildBottomTotem(bool isEnabled, bool isNight) {
    return Center(
      child: Column(
        children: [
          Container(width: 40, height: 1, color: isNight ? Colors.white10 : Colors.black.withOpacity(0.05)),
          const SizedBox(height: 16),
          Text(
            'ISLAND GUARDIAN SYSTEM 1.0',
            style: TextStyle(fontSize: 9, color: isNight ? Colors.white24 : Colors.black12, letterSpacing: 4, fontFamily: 'monospace'),
          ),
        ],
      ),
    ).animate(onPlay: (c) => isEnabled ? c.repeat() : null);
  }



  // --- Dialogs (保持逻辑不变，仅美化样式) ---
  void _showSetPinDialog(BuildContext context, UserState state) {
    final controller = TextEditingController();
    final isNight = state.isNight;
    showDialog(
      context: context,
      builder: (context) => BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: AlertDialog(
          backgroundColor: isNight ? const Color(0xFF1A1A1A) : Colors.white,
          surfaceTintColor: Colors.transparent,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28), side: BorderSide(color: isNight ? Colors.white10 : Colors.black.withOpacity(0.05))),
          title: Text('重铸密钥', style: TextStyle(color: isNight ? Colors.white : const Color(0xFF2D3436), fontWeight: FontWeight.w900)),
          content: TextField(
            controller: controller,
            autofocus: true,
            keyboardType: TextInputType.number,
            maxLength: 4,
            style: TextStyle(color: isNight ? Colors.white : const Color(0xFF2D3436), fontSize: 24, letterSpacing: 10),
            decoration: const InputDecoration(hintText: '四个数字', hintStyle: TextStyle(fontSize: 14, letterSpacing: 0), border: InputBorder.none, counterText: ''),
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('取消')),
            TextButton(
              onPressed: () {
                if (controller.text.length == 4) {
                  state.updateSecuritySettings(pin: controller.text, appLock: true);
                  Navigator.pop(context);
                }
              },
              child: const Text('注入能量', style: TextStyle(color: Color(0xFF81C784))),
            ),
          ],
        ),
      ),
    );
  }

  void _showSetDestructionDialog(BuildContext context, UserState state) {
    final controller = TextEditingController();
    final isNight = state.isNight;
    showDialog(
      context: context,
      builder: (context) => BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: AlertDialog(
          backgroundColor: isNight ? const Color(0xFF1A1A1A) : Colors.white,
          surfaceTintColor: Colors.transparent,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28), side: BorderSide(color: isNight ? Colors.white10 : Colors.black.withOpacity(0.05))),
          title: const Text('契约湮灭', style: TextStyle(color: Color(0xFFF06292), fontWeight: FontWeight.w900)),
          content: TextField(
            controller: controller,
            maxLength: 6,
            style: TextStyle(color: isNight ? Colors.white : const Color(0xFF2D3436), letterSpacing: 5),
            decoration: const InputDecoration(hintText: '核心指令...', hintStyle: TextStyle(color: Colors.white24), border: InputBorder.none, counterText: ''),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('取消')),
            TextButton(
              onPressed: () {
                if (controller.text.isNotEmpty) {
                  state.updateSecuritySettings(destCode: controller.text);
                  Navigator.pop(context);
                }
              },
              child: const Text('建立契约', style: TextStyle(color: Color(0xFFF06292))),
            ),
          ],
        ),
      ),
    );
  }
}

class _SoulMistyBackground extends StatefulWidget {
  final bool isEnabled;
  final bool isNight;
  const _SoulMistyBackground({required this.isEnabled, required this.isNight});

  @override
  State<_SoulMistyBackground> createState() => _SoulMistyBackgroundState();
}

class _SoulMistyBackgroundState extends State<_SoulMistyBackground> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(seconds: 20))..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isNight = widget.isNight;
    
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final double animVal = _controller.value.isFinite ? _controller.value : 0.0;
        
        return Container(
          decoration: BoxDecoration(
            color: isNight ? Colors.black : const Color(0xFFFDFCF7), // 临时屏蔽渐变
            /* 暂时注释掉渐变以排查 NaN
            gradient: RadialGradient(
              center: Alignment(
                0.5 * math.sin(animVal * 2 * math.pi),
                0.3 * math.cos(animVal * 2 * math.pi),
              ),
              colors: isNight 
                ? [
                    widget.isEnabled ? const Color(0xFF0F2D1A) : const Color(0xFF1A1A1A),
                    Colors.black,
                  ]
                : [
                    widget.isEnabled ? const Color(0xFFF1F8E9) : const Color(0xFFFFFDF7),
                    const Color(0xFFFDFCF7),
                  ],
              radius: 2.0,
            ),
            */
          ),
          child: Stack(
            children: [
              // 晨曦光斑 (白天模式特有)
              if (!isNight)
                Positioned(
                  top: -100,
                  left: -100,
                  child: Container(
                    width: 300,
                    height: 300,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          const Color(0xFFFFD54F).withOpacity(0.15),
                          const Color(0xFFFFD54F).withOpacity(0),
                        ],
                      ),
                    ),
                  ),
                ),
              // 暂时屏蔽粒子绘制以定位 NaN 问题
              // CustomPaint(
              //   painter: _StardustPainter(animVal, isNight),
              // ),


            ],
          ),
        );
      },
    );
  }
}

class _StardustPainter extends CustomPainter {
  final double progress;
  final bool isNight;
  _StardustPainter(this.progress, this.isNight);

  @override
  void paint(Canvas canvas, Size size) {
    if (!size.isFinite || size.width <= 0 || size.height <= 0) return; // 严格有效性检查
    
    // 确保 progress 为合法数值
    final safeProgress = progress.isFinite ? progress : 0.0;
    final paint = Paint()..color = (isNight ? Colors.white : const Color(0xFFBDB183)).withOpacity(0.12);


    final random = math.Random(42);
    for (int i = 0; i < 40; i++) {
      final x = random.nextDouble() * size.width;
      final y = (random.nextDouble() * size.height + safeProgress * 50) % size.height;
      
      if (x.isFinite && y.isFinite) {
        canvas.drawCircle(Offset(x, y), random.nextDouble() * 1.5, paint);
      }
    }

  }


  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class _RotatingRing extends StatefulWidget {
  final bool isEnabled;
  final double radius;
  final Color color;
  final double speed;

  const _RotatingRing({required this.isEnabled, required this.radius, required this.color, required this.speed});

  @override
  State<_RotatingRing> createState() => _RotatingRingState();
}

class _RotatingRingState extends State<_RotatingRing> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    // 确保时长至少为1秒，防止除零或过小导致的数值溢出
    final seconds = (10 / (widget.speed.abs() > 0 ? widget.speed.abs() : 1)).toInt();
    _controller = AnimationController(
      vsync: this, 
      duration: Duration(seconds: seconds > 0 ? seconds : 1),
    )..repeat();
  }


  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        // final isEnabled = isEnabled; // 暂时只在此层处理，如果还报错就屏蔽这行
        final animVal = _controller.value.isFinite ? _controller.value : 0.0;
        final angle = animVal * 2 * math.pi * (widget.speed > 0 ? 1 : -1);
        
        return Transform.rotate(
          angle: angle.isFinite ? angle : 0.0,
          child: Container(


            width: widget.radius * 2,
            height: widget.radius * 2,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: widget.color.withOpacity(widget.isEnabled ? 0.2 : 0.05), width: 1.5),
            ),
            child: Stack(
              children: [
                Positioned(
                  top: 0,
                  left: widget.radius - 3,
                  child: Container(width: 6, height: 6, decoration: BoxDecoration(shape: BoxShape.circle, color: widget.color.withOpacity(0.5))),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _SacredPrismPainter extends CustomPainter {
  final Color color;
  final double glowIntensity;
  _SacredPrismPainter({required this.color, required this.glowIntensity});

  @override
  void paint(Canvas canvas, Size size) {
    if (!size.isFinite || size.width <= 0 || size.height <= 0) return; // 严格有效性检查
    final paint = Paint()




      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    final path = Path();
    path.moveTo(size.width / 2, 0);
    path.lineTo(size.width, size.height * 0.3);
    path.lineTo(size.width, size.height * 0.7);
    path.lineTo(size.width / 2, size.height);
    path.lineTo(0, size.height * 0.7);
    path.lineTo(0, size.height * 0.3);
    path.close();

    canvas.drawPath(path, paint);
    
    // 内部棱线 (增加 Offset 有效性检查)
    void drawSafeLine(Offset p1, Offset p2) {
      if (p1.dx.isFinite && p1.dy.isFinite && p2.dx.isFinite && p2.dy.isFinite) {
        canvas.drawLine(p1, p2, paint);
      }
    }

    drawSafeLine(Offset(size.width / 2, 0), Offset(size.width, size.height * 0.3));
    drawSafeLine(Offset(size.width / 2, 0), Offset(0, size.height * 0.3));
    drawSafeLine(Offset(size.width / 2, size.height), Offset(size.width, size.height * 0.7));
    drawSafeLine(Offset(size.width / 2, size.height), Offset(0, size.height * 0.7));
    drawSafeLine(Offset(size.width, size.height * 0.3), Offset(0, size.height * 0.7));
    drawSafeLine(Offset(0, size.height * 0.3), Offset(size.width, size.height * 0.7));

    
    if (glowIntensity > 0) {
      final glowPaint = Paint()
        ..color = color.withOpacity(0.2 * glowIntensity)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10);
      canvas.drawPath(path, glowPaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
