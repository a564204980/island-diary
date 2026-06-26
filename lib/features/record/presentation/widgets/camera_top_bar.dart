import 'package:flutter/material.dart';

class CameraTopBar extends StatelessWidget {
  final String currentFlashMode;
  final bool showGrid;
  final int selfTimerSeconds;
  final VoidCallback onClose;
  final VoidCallback onToggleFlash;
  final VoidCallback onToggleGrid;
  final VoidCallback onToggleSelfTimer;

  const CameraTopBar({
    super.key,
    required this.currentFlashMode,
    required this.showGrid,
    required this.selfTimerSeconds,
    required this.onClose,
    required this.onToggleFlash,
    required this.onToggleGrid,
    required this.onToggleSelfTimer,
  });

  @override
  Widget build(BuildContext context) {
    IconData flashIcon = Icons.flash_off;
    if (currentFlashMode == 'auto') flashIcon = Icons.flash_auto;
    if (currentFlashMode == 'torch') flashIcon = Icons.highlight;

    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.black54, Colors.transparent],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 12,
        bottom: 24,
        left: 16,
        right: 16,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // 退出按钮
          IconButton(
            icon: const Icon(Icons.close, color: Colors.white, size: 26),
            onPressed: onClose,
          ),

          // 延时摄影倒计时
          Stack(
            alignment: Alignment.center,
            children: [
              IconButton(
                icon: Icon(
                  selfTimerSeconds == 0 ? Icons.timer_outlined : Icons.timer,
                  color: selfTimerSeconds > 0 ? const Color(0xFFD4A373) : Colors.white54,
                  size: 24,
                ),
                onPressed: onToggleSelfTimer,
              ),
              if (selfTimerSeconds > 0)
                Positioned(
                  right: 4,
                  bottom: 4,
                  child: Container(
                    padding: const EdgeInsets.all(2),
                    decoration: const BoxDecoration(
                      color: Color(0xFFD4A373),
                      shape: BoxShape.circle,
                    ),
                    child: Text(
                      '${selfTimerSeconds}s',
                      style: const TextStyle(color: Colors.black, fontSize: 8, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
            ],
          ),

          // 闪光灯
          IconButton(
            icon: Icon(flashIcon, color: currentFlashMode == 'off' ? Colors.white54 : const Color(0xFFD4A373), size: 24),
            onPressed: onToggleFlash,
          ),

          // 辅助网格线
          IconButton(
            icon: Icon(
              showGrid ? Icons.grid_on : Icons.grid_off,
              color: showGrid ? const Color(0xFFD4A373) : Colors.white54,
              size: 24,
            ),
            onPressed: onToggleGrid,
          ),
        ],
      ),
    );
  }
}
