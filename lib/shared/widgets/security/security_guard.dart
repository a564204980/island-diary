import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';

import 'package:island_diary/core/state/user_state.dart';

/// 全局安全守护卫士
/// 负责：
/// 1. 应用启动/切前台时的 PIN 码解锁
/// 2. 切后台时的“迷雾模式”高斯模糊
/// 3. 处理紧急自毁逻辑
class SecurityGuard extends StatefulWidget {
  final Widget child;
  const SecurityGuard({super.key, required this.child});

  @override
  State<SecurityGuard> createState() => _SecurityGuardState();
}

class _SecurityGuardState extends State<SecurityGuard> with WidgetsBindingObserver {
  bool _isLocked = false;
  bool _isInactive = false;
  final TextEditingController _pinController = TextEditingController();
  final FocusNode _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // 初始化锁定状态：如果开启了应用锁，启动即锁定
    _isLocked = UserState().isAppLockEnabled.value;
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _pinController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final userState = UserState();
    
    // 迷雾模式逻辑：系统处于 inactive 或 paused 时模糊界面
    if (userState.isMistModeEnabled.value) {
      setState(() {
        _isInactive = (state == AppLifecycleState.inactive || state == AppLifecycleState.paused);
      });
    }

    // 切回到前台时，如果开启了应用锁，则进入锁定状态
    if (state == AppLifecycleState.resumed && userState.isAppLockEnabled.value) {
      setState(() {
        _isLocked = true;
        _pinController.clear();
      });
    }
  }

  void _handlePinInput(String value) {
    if (value.length >= 4) {
      final userState = UserState();
      
      // 1. 检查自毁码
      if (userState.destructionCode.value.isNotEmpty && value == userState.destructionCode.value) {
        _performDestruction();
        return;
      }

      // 2. 检查正确密码
      if (value == userState.appLockPin.value) {
        setState(() {
          _isLocked = false;
        });
        _pinController.clear();
      } else {
        // 密码错误，震动反馈或清空
        _pinController.clear();
        HapticFeedback.heavyImpact();
      }
    }
  }

  void _performDestruction() async {
    // 播放一个震撼的消失动画然后重置
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: Text('岛屿正在回归沉寂...', style: TextStyle(color: Colors.white, fontSize: 18)),
      ),
    );
    
    await Future.delayed(const Duration(seconds: 2));
    await UserState().factoryReset();
    
    // 重启应用感知：这里简单地通过 Navigator 刷新
    if (mounted) {
      Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // 原始应用内容
        widget.child,

        // 迷雾模式遮罩 (近期任务预览模糊)
        if (_isInactive)
          Positioned.fill(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 30, sigmaY: 30),
              child: Container(
                color: Colors.black.withOpacity(0.5),
                child: const Center(
                  child: Icon(Icons.blur_on, color: Colors.white24, size: 80),
                ),
              ),
            ),
          ),

        // 锁屏界面
        if (_isLocked)
          Positioned.fill(
            child: GestureDetector(
              onTap: () => _focusNode.requestFocus(),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 25, sigmaY: 25),
                child: Container(
                  color: Colors.black.withOpacity(0.8),
                  child: SafeArea(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.lock_person_outlined, size: 64, color: Color(0xFF81C784))
                            .animate(onPlay: (c) => c.repeat(reverse: true))
                            .shimmer(duration: 2.seconds),
                        const SizedBox(height: 24),
                        const Text(
                          '心灵结界已开启',
                          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          '请输入您的岛屿密钥',
                          style: TextStyle(fontSize: 13, color: Colors.white38),
                        ),
                        const SizedBox(height: 48),
                        
                        // 隐形输入框
                        SizedBox(
                          width: 200,
                          child: TextField(
                            controller: _pinController,
                            focusNode: _focusNode,
                            autofocus: true,
                            showCursor: false,
                            cursorWidth: 0,
                            keyboardType: TextInputType.number,
                            textAlign: TextAlign.center,
                            style: const TextStyle(color: Colors.transparent, fontSize: 0),
                            decoration: const InputDecoration(border: InputBorder.none),
                            onChanged: _handlePinInput,
                          ),
                        ),
                        
                        // 密码点显示
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: List.generate(4, (index) {
                            bool isFilled = _pinController.text.length > index;
                            return Container(
                              width: 20,
                              height: 20,
                              margin: const EdgeInsets.symmetric(horizontal: 12),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: isFilled ? const Color(0xFF81C784) : Colors.transparent,
                                border: Border.all(color: Colors.white24, width: 2),
                              ),
                            ).animate(target: isFilled ? 1 : 0).scale(duration: 200.ms, begin: const Offset(1, 1), end: const Offset(1.2, 1.2));
                          }),
                        ),
                        
                        const SizedBox(height: 60),
                        if (UserState().isBiometricEnabled.value)
                          IconButton(
                            icon: const Icon(Icons.fingerprint, size: 40, color: Colors.white70),
                            onPressed: () {
                              // TODO: 调用 local_auth 验证
                            },
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            ).animate().fadeIn(duration: 400.ms),
          ),
      ],
    );
  }
}
