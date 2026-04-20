import 'dart:ui';
import 'dart:math' as math;
import 'package:flutter/material.dart';

import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:island_diary/core/state/user_state.dart';

class SecurityCenterPage extends StatefulWidget {
  const SecurityCenterPage({super.key});

  @override
  State<SecurityCenterPage> createState() => _SecurityCenterPageState();
}

class _SecurityCenterPageState extends State<SecurityCenterPage> {
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    // 延迟 50ms 启动复杂动效，确保 Scaffold 背景色先渲染
    Future.delayed(const Duration(milliseconds: 50), () {
      if (mounted) {
        setState(() => _isInitialized = true);
      }
    });
  }

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
              '岛屿安全中心', 
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
              // 1. 灵魂迷雾背景 (仅在初始化后渲染)
              if (_isInitialized)
                Positioned.fill(
                  child: _SoulMistyBackground(isEnabled: isEnabled, isNight: isNight),
                ),
              
              SafeArea(
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 800),
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
              _RotatingRing(isEnabled: isEnabled, radius: 65, color: const Color(0xFF81C784), speed: 3),
              _RotatingRing(isEnabled: isEnabled, radius: 50, color: const Color(0xFF64B5F6), speed: -2),
              
              CustomPaint(
                size: const Size(64, 74),
                painter: _GuardianShieldPainter(
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
                          color: const Color(0xFF81C784).withValues(alpha: isNight ? 0.15 : 0.08),
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
          isEnabled ? '岛屿已守护 · 闲人勿进' : '防线已撤离 · 建议开启',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w900,
            letterSpacing: 2,
            color: isNight ? Colors.white : const Color(0xFF1E3A34),
            shadows: isNight ? [const Shadow(color: Colors.black26, offset: Offset(2, 2), blurRadius: 4)] : null,
          ),
        ),
        const SizedBox(height: 8),
        Opacity(
          opacity: 0.6,
          child: Text(
            isEnabled ? '岛屿正处于严密保护中，您的日记非常安全' : '还没开启守护，您的秘密可能会被别人看到',
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
        _buildAppLockPremiumCard(context, state),
        const SizedBox(height: 16),
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(child: _buildMistPremiumBento(state)),
              const SizedBox(width: 16),
              Expanded(child: _buildScreenshotPremiumBento(state)),
            ],
          ),
        ),
        const SizedBox(height: 16),
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
              _buildNeonIcon(Icons.security_rounded, const Color(0xFF81C784)),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('进岛密码', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w900, color: isNight ? Colors.white : const Color(0xFF1E3A34))),
                    const SizedBox(height: 2),
                    Text('给日记加把锁，只有你能进', style: TextStyle(fontSize: 12, color: (isNight ? Colors.white : const Color(0xFF4A615C)).withValues(alpha: 0.4))),
                  ],
                ),
              ),
              const SizedBox(width: 8),
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
              child: Divider(height: 1, color: isNight ? Colors.white10 : Colors.black.withValues(alpha: 0.05)),
            ),
            _buildActionItem(
              icon: Icons.fingerprint_rounded,
              title: '刷脸 / 指纹',
              subtitle: '不用敲密码，刷一下就能进',
              isNight: isNight,
              trailing: Switch.adaptive(
                value: state.isBiometricEnabled.value,
                activeColor: const Color(0xFF81C784),
                onChanged: (val) => state.updateSecuritySettings(biometric: val),
              ),
            ),
            const SizedBox(height: 16),
            _buildActionItem(
              icon: Icons.lock_reset_rounded,
              title: '修改进岛密码',
              subtitle: '觉得当前密码不安全？在这里改一个新的',
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
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: isNight 
          ? [const Color(0xFF64B5F6).withValues(alpha: 0.08), Colors.transparent]
          : [const Color(0xFFE3F2FD).withValues(alpha: 0.5), Colors.white.withValues(alpha: 0.1)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildNeonIcon(Icons.blur_on_rounded, const Color(0xFF64B5F6)),
              Switch.adaptive(
                value: state.isMistModeEnabled.value,
                activeColor: const Color(0xFF64B5F6),
                onChanged: (val) => state.updateSecuritySettings(mistMode: val),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Text('后台模糊', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: isNight ? Colors.white : const Color(0xFF2D3436))),
          const SizedBox(height: 6),
          Text('切换App时，把日记内容弄模糊', style: TextStyle(fontSize: 11, color: (isNight ? Colors.white70 : Colors.black54).withValues(alpha: 0.5), height: 1.4)),
        ],
      ),
    ).animate().fadeIn(delay: 400.ms).slideY(begin: 0.1, end: 0);
  }


  Widget _buildScreenshotPremiumBento(UserState state) {
    final isNight = state.isNight;
    return ListenableBuilder(
      listenable: state.isScreenshotProtected,
      builder: (context, _) => _buildGlassContainer(
        isNight: isNight,
        padding: const EdgeInsets.all(24),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isNight 
            ? [const Color(0xFF4DB6AC).withValues(alpha: 0.08), Colors.transparent]
            : [const Color(0xFFE0F2F1).withValues(alpha: 0.5), Colors.white.withValues(alpha: 0.1)],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildNeonIcon(Icons.monitor_rounded, const Color(0xFF4DB6AC)),
                Switch.adaptive(
                  value: state.isScreenshotProtected.value,
                  activeColor: const Color(0xFF4DB6AC),
                  onChanged: (val) => state.updateAdvancedSecurity(screenshot: val),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Text('潮汐屏障', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: isNight ? Colors.white : const Color(0xFF2D3436))),
            const SizedBox(height: 6),
            Text('禁止在图内截屏', style: TextStyle(fontSize: 11, color: (isNight ? Colors.white70 : Colors.black54).withValues(alpha: 0.5), height: 1.4)),
          ],
        ),
      ).animate().fadeIn(delay: 500.ms).slideY(begin: 0.1, end: 0),
    );
  }



  Widget _buildGlassContainer({required Widget child, EdgeInsets? padding, required bool isNight, Gradient? gradient}) {
    return Container(
      padding: padding ?? const EdgeInsets.all(26),
      decoration: BoxDecoration(
        color: isNight ? Colors.white.withValues(alpha: 0.06) : Colors.white.withValues(alpha: 0.85),
        gradient: gradient,
        borderRadius: BorderRadius.circular(32),
        border: Border.all(
          color: isNight ? Colors.white.withValues(alpha: 0.12) : Colors.white.withValues(alpha: 0.5),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: isNight ? Colors.black.withValues(alpha: 0.5) : const Color(0xFF7090B0).withValues(alpha: 0.15),
            blurRadius: 28,
            offset: const Offset(0, 14),
          ),
          BoxShadow(
            color: Colors.white.withValues(alpha: isNight ? 0.01 : 0.6),
            spreadRadius: -2,
            blurRadius: 10,
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
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: color.withValues(alpha: 0.2), blurRadius: 15, spreadRadius: 1),
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
            decoration: BoxDecoration(color: (isNight ? Colors.white : Colors.black).withValues(alpha: 0.05), shape: BoxShape.circle),
            child: Icon(icon, size: 18, color: isNight ? Colors.white70 : Colors.black54),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: isNight ? Colors.white : const Color(0xFF1E3A34))),
                Text(subtitle, style: TextStyle(fontSize: 11, color: isNight ? Colors.white30 : const Color(0xFF4A615C).withValues(alpha: 0.5))),
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
          Container(width: 40, height: 1, color: isNight ? Colors.white10 : Colors.black.withValues(alpha: 0.05)),
          const SizedBox(height: 16),
          Text(
            'ISLAND GUARDIAN SYSTEM 1.0',
            style: TextStyle(fontSize: 9, color: isNight ? Colors.white24 : Colors.black12, letterSpacing: 4, fontFamily: 'monospace'),
          ),
        ],
      ),
    ).animate(onPlay: (c) => isEnabled ? c.repeat() : null);
  }

  void _showSetPinDialog(BuildContext context, UserState state) {
    final controller = TextEditingController();
    final focusNode = FocusNode();
    final isNight = state.isNight;
    
    showDialog(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.5),
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          controller.addListener(() => setState(() {}));
          
          return BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
            child: Dialog(
              backgroundColor: Colors.transparent,
              elevation: 0,
              child: Container(
                width: 320,
                padding: const EdgeInsets.all(32),
                decoration: BoxDecoration(
                  color: isNight ? const Color(0xFF1E1E1E).withValues(alpha: 0.8) : Colors.white.withValues(alpha: 0.9),
                  borderRadius: BorderRadius.circular(32),
                  border: Border.all(
                    color: isNight ? Colors.white.withValues(alpha: 0.1) : Colors.black.withValues(alpha: 0.05),
                    width: 1.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: isNight ? 0.3 : 0.1),
                      blurRadius: 30,
                      offset: const Offset(0, 15),
                    )
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // 1. 顶部视觉标识
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFF81C784).withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.lock_person_rounded, color: Color(0xFF81C784), size: 28),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      '设置安全密码',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                        color: isNight ? Colors.white : const Color(0xFF1E3A34),
                        letterSpacing: 1,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '输入4位数字，守护日记私密',
                      style: TextStyle(
                        fontSize: 12,
                        color: (isNight ? Colors.white : const Color(0xFF4A615C)).withValues(alpha: 0.5),
                      ),
                    ),
                    const SizedBox(height: 32),

                    // 2. 4位方格输入区
                    Stack(
                      alignment: Alignment.center,
                      children: [
                        // 隐藏的可操作输入框
                        Opacity(
                          opacity: 0,
                          child: TextField(
                            controller: controller,
                            focusNode: focusNode,
                            autofocus: true,
                            keyboardType: TextInputType.number,
                            maxLength: 4,
                            onChanged: (val) {
                              if (val.length == 4) {
                                // 自动补完
                              }
                            },
                            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                          ),
                        ),
                        // 展示用的方格 Row
                        GestureDetector(
                          onTap: () => focusNode.requestFocus(),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: List.generate(4, (index) {
                              final bool hasChar = controller.text.length > index;
                              final bool isCurrent = controller.text.length == index;
                              
                              return AnimatedContainer(
                                duration: const Duration(milliseconds: 200),
                                width: 50,
                                height: 60,
                                decoration: BoxDecoration(
                                  color: isNight ? Colors.white.withValues(alpha: 0.03) : Colors.black.withValues(alpha: 0.02),
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color: isCurrent 
                                        ? const Color(0xFF81C784) 
                                        : (isNight ? Colors.white10 : Colors.black12),
                                    width: isCurrent ? 2 : 1,
                                  ),
                                  boxShadow: isCurrent ? [
                                    BoxShadow(
                                      color: const Color(0xFF81C784).withValues(alpha: 0.2),
                                      blurRadius: 10,
                                      spreadRadius: 1,
                                    )
                                  ] : [],
                                ),
                                child: Center(
                                  child: hasChar
                                      ? Container(
                                          width: 12,
                                          height: 12,
                                          decoration: const BoxDecoration(
                                            color: Color(0xFF81C784),
                                            shape: BoxShape.circle,
                                          ),
                                        ).animate().scale(begin: const Offset(0.5, 0.5), end: const Offset(1, 1))
                                      : Container(
                                          width: 4,
                                          height: 4,
                                          decoration: BoxDecoration(
                                            color: isNight ? Colors.white24 : Colors.black12,
                                            shape: BoxShape.circle,
                                          ),
                                        ),
                                ),
                              );
                            }),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 40),

                    // 3. 操作按钮
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton(
                        onPressed: controller.text.length == 4
                            ? () {
                                state.updateSecuritySettings(pin: controller.text, appLock: true);
                                Navigator.pop(context);
                              }
                            : null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF81C784),
                          foregroundColor: Colors.white,
                          disabledBackgroundColor: isNight ? Colors.white12 : Colors.black12,
                          elevation: 0,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                        ),
                        child: const Text('确认修改', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 1)),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: Text(
                        '取消',
                        style: TextStyle(
                          color: (isNight ? Colors.white : const Color(0xFF4A615C)).withValues(alpha: 0.4),
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
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
                          const Color(0xFFFFD54F).withValues(alpha: 0.15),
                          const Color(0xFFFFD54F).withValues(alpha: 0),
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
              border: Border.all(color: widget.color.withValues(alpha: widget.isEnabled ? 0.2 : 0.05), width: 1.5),
            ),
            child: Stack(
              children: [
                Positioned(
                  top: 0,
                  left: widget.radius - 3,
                  child: Container(width: 6, height: 6, decoration: BoxDecoration(shape: BoxShape.circle, color: widget.color.withValues(alpha: 0.5))),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _GuardianShieldPainter extends CustomPainter {
  final Color color;
  final double glowIntensity;
  _GuardianShieldPainter({required this.color, required this.glowIntensity});

  @override
  void paint(Canvas canvas, Size size) {
    if (!size.isFinite || size.width <= 0 || size.height <= 0) return;
    
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.8
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    double w = size.width;
    double h = size.height;

    // 绘制外层主盾牌路径 (经典的圣盾造型)
    final outerPath = Path();
    outerPath.moveTo(w * 0.5, 0); // 顶部中点
    outerPath.lineTo(w * 0.9, h * 0.1); // 右耳
    outerPath.quadraticBezierTo(w * 1.0, h * 0.5, w * 0.9, h * 0.7); // 右侧弧度
    outerPath.quadraticBezierTo(w * 0.75, h * 0.95, w * 0.5, h); // 底部尖端
    outerPath.quadraticBezierTo(w * 0.25, h * 0.95, w * 0.1, h * 0.7); // 左侧弧度
    outerPath.quadraticBezierTo(0, h * 0.5, w * 0.1, h * 0.1); // 左耳
    outerPath.close();

    // 绘制内层装饰线
    final innerPath = Path();
    double inset = 6.0;
    innerPath.moveTo(w * 0.5, inset);
    innerPath.lineTo(w * 0.82, h * 0.15);
    innerPath.quadraticBezierTo(w * 0.9, h * 0.5, w * 0.82, h * 0.65);
    innerPath.quadraticBezierTo(w * 0.7, h * 0.88, w * 0.5, h - inset);
    innerPath.quadraticBezierTo(w * 0.3, h * 0.88, w * 0.18, h * 0.65);
    innerPath.quadraticBezierTo(w * 0.1, h * 0.5, w * 0.18, h * 0.15);
    innerPath.close();

    // 1. 绘制内部微光填充
    if (glowIntensity > 0) {
      final fillPaint = Paint()
        ..shader = RadialGradient(
          colors: [
            color.withValues(alpha: 0.25 * glowIntensity),
            color.withValues(alpha: 0.05 * glowIntensity),
            Colors.transparent,
          ],
        ).createShader(Rect.fromLTWH(0, 0, w, h));
      canvas.drawPath(outerPath, fillPaint);
    }

    // 2. 绘制外边框
    canvas.drawPath(outerPath, paint);

    // 3. 绘制内边框 (细线)
    final innerPaint = Paint()
      ..color = color.withValues(alpha: 0.4)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;
    canvas.drawPath(innerPath, innerPaint);

    // 4. 绘制中心守护纹章 (一个星芒结合几何的符号)
    final decoPaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    double cx = w * 0.5;
    double cy = h * 0.45;
    double r = 8.0;

    // 绘制一个菱形核心
    final corePath = Path();
    corePath.moveTo(cx, cy - r);
    corePath.lineTo(cx + r, cy);
    corePath.lineTo(cx, cy + r);
    corePath.lineTo(cx - r, cy);
    corePath.close();
    canvas.drawPath(corePath, decoPaint);

    // 延伸出的守护光芒
    canvas.drawLine(Offset(cx, cy - r - 4), Offset(cx, cy - r - 8), decoPaint);
    canvas.drawLine(Offset(cx, cy + r + 4), Offset(cx, cy + r + 8), decoPaint);
    canvas.drawLine(Offset(cx - r - 4, cy), Offset(cx - r - 8, cy), decoPaint);
    canvas.drawLine(Offset(cx + r + 4, cy), Offset(cx + r + 8, cy), decoPaint);

    // 5. 整体外发光
    if (glowIntensity > 0) {
      final glowPaint = Paint()
        ..color = color.withValues(alpha: 0.15 * glowIntensity)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 15);
      canvas.drawPath(outerPath, glowPaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
