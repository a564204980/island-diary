import 'dart:ui' as ui;
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_windowmanager_plus/flutter_windowmanager_plus.dart';
import 'package:camera/camera.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;

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
  String _currentInput = ""; 
  DateTime? _lastInactiveTime;
  int _failedAttempts = 0;
  bool _isCapturing = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    final userState = UserState();
    _isLocked = userState.isAppLockEnabled.value;
    _pinController.addListener(_onPinChanged);
    
    // 初始化并监听截屏防护
    _updateScreenshotProtection();
    userState.isScreenshotProtected.addListener(_updateScreenshotProtection);
    
    if (_isLocked) {
      _requestLockFocus();
    }
  }

  void _requestLockFocus() {
    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted && _isLocked) {
        _focusNode.requestFocus();
      }
    });
  }

  void _updateScreenshotProtection() {
    if (!kIsWeb && Platform.isAndroid) {
      try {
        if (UserState().isScreenshotProtected.value) {
          FlutterWindowManagerPlus.addFlags(FlutterWindowManagerPlus.FLAG_SECURE);
        } else {
          FlutterWindowManagerPlus.clearFlags(FlutterWindowManagerPlus.FLAG_SECURE);
        }
      } catch (e) {
        debugPrint('Screenshot protection error: $e');
      }
    }
  }

  @override
  void dispose() {
    UserState().isScreenshotProtected.removeListener(_updateScreenshotProtection);
    _pinController.removeListener(_onPinChanged);
    WidgetsBinding.instance.removeObserver(this);
    _pinController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _onPinChanged() {
    if (!mounted) return;
    setState(() {
      _currentInput = _pinController.text;
    });
    // 调试日志输出，帮助定位捕获问题
    debugPrint("PIN Input changed: $_currentInput");
    _handlePinInput(_currentInput);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final userState = UserState();
    
    if (userState.isMistModeEnabled.value) {
      setState(() {
        _isInactive = (state == AppLifecycleState.inactive || state == AppLifecycleState.paused);
      });
    }

    if (state == AppLifecycleState.inactive || state == AppLifecycleState.paused) {
      _lastInactiveTime = DateTime.now();
    }

    if (state == AppLifecycleState.resumed && userState.isAppLockEnabled.value) {
      final lockDuration = userState.autoLockDuration.value;
      bool shouldLock = false;
      
      if (lockDuration == 0) {
        shouldLock = true;
      } else if (_lastInactiveTime != null) {
        final diff = DateTime.now().difference(_lastInactiveTime!).inSeconds;
        if (diff > lockDuration) {
          shouldLock = true;
        }
      }

      if (shouldLock) {
        setState(() {
          _isLocked = true;
          _pinController.clear();
        });
        _requestLockFocus();
      }
    }
  }

  void _handlePinInput(String value) {
    if (value.length >= 4) {
      final userState = UserState();
      
      if (userState.destructionCode.value.isNotEmpty && value == userState.destructionCode.value) {
        _performDestruction();
        return;
      }

      if (value == userState.appLockPin.value) {
        setState(() {
          _isLocked = false;
          _failedAttempts = 0;
        });
        _pinController.clear();
      } else {
        _failedAttempts++;
        _pinController.clear();
        HapticFeedback.heavyImpact();
        
        if (_failedAttempts >= 3 && userState.isIntruderCaptureEnabled.value) {
          _captureIntruder();
        }
      }
    }
  }

  Future<void> _captureIntruder() async {
    if (_isCapturing) return;
    _isCapturing = true;
    
    try {
      final cameras = await availableCameras();
      if (cameras.isEmpty) return;
      
      final frontCamera = cameras.firstWhere(
        (camera) => camera.lensDirection == CameraLensDirection.front,
        orElse: () => cameras.first,
      );

      final controller = CameraController(
        frontCamera,
        ResolutionPreset.medium,
        enableAudio: false,
      );

      await controller.initialize();
      final image = await controller.takePicture();
      
      // 保存到永久目录
      final appDir = await getApplicationDocumentsDirectory();
      final fileName = 'intruder_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final savedPath = path.join(appDir.path, 'intruders', fileName);
      
      final file = File(savedPath);
      if (!await file.parent.exists()) {
        await file.parent.create(recursive: true);
      }
      await File(image.path).copy(savedPath);

      // 更新记录
      await UserState().updateAdvancedSecurity(
        newIntruderLog: {
          'time': DateTime.now().toIso8601String(),
          'photoPath': savedPath,
        },
      );

      await controller.dispose();
    } catch (e) {
      debugPrint('Intruder capture error: $e');
    } finally {
      _isCapturing = false;
    }
  }

  void _performDestruction() async {
    // 播放一个震撼的消失动画然后重置
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: Text('正在删掉所有日记，请稍候...', style: TextStyle(color: Colors.white, fontSize: 18)),
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
              filter: ui.ImageFilter.blur(sigmaX: 30, sigmaY: 30),
              child: Container(
                color: Colors.black.withValues(alpha: 0.5),
                child: const Center(
                  child: Icon(Icons.blur_on, color: Colors.white24, size: 80),
                ),
              ),
            ),
          ),

        // 锁屏界面
        if (_isLocked)
          Positioned.fill(
            child: Scaffold(
              backgroundColor: Colors.transparent,
              resizeToAvoidBottomInset: false,
              body: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => _focusNode.requestFocus(),
                child: BackdropFilter(
                  filter: ui.ImageFilter.blur(sigmaX: 25, sigmaY: 25),
                  child: Container(
                    width: double.infinity,
                    height: double.infinity,
                    color: Colors.black.withValues(alpha: 0.8),
                    child: SafeArea(
                      child: Center(
                        child: SingleChildScrollView(
                          physics: const BouncingScrollPhysics(),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.shield_rounded, size: 64, color: Color(0xFF81C784))
                                  .animate(onPlay: (c) => c.repeat(reverse: true))
                                  .shimmer(duration: 2.seconds),
                              const SizedBox(height: 24),
                              const Text(
                                '岛屿守护已生效',
                                style: TextStyle(
                                  fontSize: 20, 
                                  fontWeight: FontWeight.bold, 
                                  color: Colors.white,
                                  decoration: TextDecoration.none,
                                ),
                              ),
                              const SizedBox(height: 8),
                              const Text(
                                '请输入您的进岛密码',
                                style: TextStyle(
                                  fontSize: 13, 
                                  color: Colors.white38,
                                  decoration: TextDecoration.none,
                                ),
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
                                  autocorrect: false,
                                  enableSuggestions: false,
                                  style: const TextStyle(color: Colors.transparent, fontSize: 1),
                                  decoration: const InputDecoration(
                                    border: InputBorder.none,
                                    isDense: true,
                                    contentPadding: EdgeInsets.all(20), // 扩大点击热区
                                  ),
                                  // 去掉这里的 onChanged，统一由于 Listener 处理
                                ),
                              ),
                              
                              // 密码点显示
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: List.generate(4, (index) {
                                  final isFilled = _currentInput.length > index;
                                  return Container(
                                    width: 20,
                                    height: 20,
                                    margin: const EdgeInsets.symmetric(horizontal: 12),
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: isFilled ? const Color(0xFF81C784) : Colors.transparent,
                                      border: Border.all(color: Colors.white24, width: 2),
                                    ),
                                  ).animate(target: isFilled ? 1 : 0).scale(duration: 200.ms, begin: const ui.Offset(1, 1), end: const ui.Offset(1.2, 1.2));
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
                  ),
                ),
              ),
            ).animate().fadeIn(duration: 400.ms),
          ),
      ],
    );
  }
}
