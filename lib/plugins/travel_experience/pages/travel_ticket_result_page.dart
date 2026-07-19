import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:island_diary/core/state/user_state.dart';

class TravelTicketResultPage extends StatefulWidget {
  final File image;
  final String origin;
  final String destination;
  
  const TravelTicketResultPage({
    super.key, 
    required this.image,
    required this.origin,
    required this.destination,
  });

  @override
  State<TravelTicketResultPage> createState() => _TravelTicketResultPageState();
}

class _TravelTicketResultPageState extends State<TravelTicketResultPage> with SingleTickerProviderStateMixin {
  late AnimationController _printerController;
  late Animation<double> _slideAnimation;
  bool _isImageSelected = true;
  double _customScale = 0.8; // 增加用于角落拖拽缩放，默认小一点
  
  @override
  void initState() {
    super.initState();
    _printerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
    
    // 从略微偏上的位置动画滑动到最终位置
    _slideAnimation = Tween<double>(begin: -0.8, end: 0.0).animate(
      CurvedAnimation(parent: _printerController, curve: Curves.easeOutCubic)
    );

    // 针对大图的初始缩放调整
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // 稍作延迟以让图像自然渲染，然后开始滑动
      Future.delayed(const Duration(milliseconds: 300), () {
        if (mounted) _printerController.forward();
      });
    });
  }

  @override
  void dispose() {
    _printerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black, // 纯黑背景
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SafeArea(
        child: GestureDetector(
          behavior: HitTestBehavior.translucent,
          onTap: () {
            if (_isImageSelected) {
              setState(() => _isImageSelected = false);
            }
          },
          child: Column(
            children: [
              // 打印机出口凹槽（顶部线条）
            Container(
              height: 2,
              width: double.infinity,
              margin: const EdgeInsets.symmetric(horizontal: 20),
              decoration: BoxDecoration(
                color: Colors.grey.shade800,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.5),
                    blurRadius: 10,
                    offset: const Offset(0, 5),
                  )
                ]
              ),
            ),
            
            // 滑动的机票
            Expanded(
              child: ClipRect(
                child: AnimatedBuilder(
                  animation: _printerController,
                  builder: (context, child) {
                    return FractionalTranslation(
                      translation: Offset(0.0, _slideAnimation.value),
                      child: child,
                    );
                  },
                  child: Align(
                    alignment: Alignment.topCenter,
                    child: Padding(
                      padding: const EdgeInsets.only(top: 0, bottom: 20),
                      child: _buildVerticalBoardingPass(),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
        ),
      ),
    );
  }

  Widget _buildVerticalBoardingPass() {
    final now = DateTime.now();
    final timeStr = DateFormat('HHmm').format(now);
    final dateStr = DateFormat('yyyy.MM.dd').format(now);
    
    final userState = UserState();
    final userName = userState.userName.value.toUpperCase();
    final displayName = userName.isNotEmpty ? userName : 'ISLAND/TRAVELER';
    
    // 生成伪随机航班信息以保持稳定但具有动态感
    final hash = widget.destination.hashCode.abs();
    final flightNum = 'NX${(hash % 9000) + 1000}';
    final gate = '${(hash % 50) + 1}';
    final seat = '${(hash % 40) + 1}${['A', 'B', 'C', 'D', 'E', 'F'][hash % 6]}';
    
    return Container(
      width: MediaQuery.of(context).size.width * 0.88,
      height: MediaQuery.of(context).size.height * 0.78,
      decoration: BoxDecoration(
        color: const Color(0xFFF2EFE9), // 米白/米黄纹理纸张色
        borderRadius: BorderRadius.circular(4),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white.withValues(alpha: 0.9),
            const Color(0xFFEFECE5),
            const Color(0xFFE2DFD6),
          ],
          stops: const [0.1, 0.6, 1.0],
        ),
      ),
      child: Stack(
        children: [
          // 纹理叠加层（模拟纸张纹理）
          Positioned.fill(
            child: GestureDetector(
              onTap: () {
                if (_isImageSelected) {
                  setState(() => _isImageSelected = false);
                }
              },
              child: Opacity(
                opacity: 0.05,
                child: Image.network(
                  'https://www.transparenttextures.com/patterns/dust.png', // 降级使用通用噪点
                  repeat: ImageRepeat.repeat,
                  errorBuilder: (context, error, stackTrace) => const SizedBox(),
                ),
              ),
            ),
          ),
          
          // ==== 巨大的人物图像（置于大部分UI文本的下方） ====
          // 我们将图像的边界框放在主区域并将其放大。
          // 因为它在 Stack 中绘制于蓝色右边栏和文字内容之前，
          // 所以任何溢出都会自然地“滑入” UI 元素的后方，而不会被一条难看的直线生硬裁切！
          Positioned(
            top: 120, // 从顶部虚线附近开始
            bottom: 60, // 从底部条形码附近开始
            left: 0, 
            right: 45, // 在蓝色右边栏之前停止
            child: InteractiveViewer(
              clipBehavior: Clip.none, // 关键：防止 InteractiveViewer 裁切掉人物的手臂！
              boundaryMargin: const EdgeInsets.all(2000), // 允许在任何地方拖拽
              minScale: 0.1,
              maxScale: 10.0,
              child: Transform.scale(
                scale: _customScale, // 由角落拖拽控制的自定义缩放比例
                alignment: Alignment.center, // 居中对齐使角落缩放更加直观
                child: Center(
                  child: GestureDetector(
                    onTap: () {
                      if (!_isImageSelected) {
                        setState(() => _isImageSelected = true);
                      }
                    },
                  child: Stack(
                    alignment: Alignment.center,
                    fit: StackFit.loose,
                    children: [
                      Image.file(
                        widget.image,
                        fit: BoxFit.contain, // Contain 可防止原生布局裁切（避免直线裁切）
                        alignment: Alignment.center,
                      ),
                      Positioned.fill(
                        child: IgnorePointer(
                          ignoring: !_isImageSelected,
                          child: AnimatedOpacity(
                            duration: const Duration(milliseconds: 200),
                            opacity: _isImageSelected ? 1.0 : 0.0,
                            child: Container(
                              decoration: BoxDecoration(
                                border: Border.all(
                                  color: Colors.white.withValues(alpha: 0.9),
                                  width: 1.5,
                                ),
                              ),
                              child: Stack(
                                children: [
                                  _buildDragHandle(Alignment.topLeft),
                                  _buildDragHandle(Alignment.topRight),
                                  _buildDragHandle(Alignment.bottomLeft),
                                  _buildDragHandle(Alignment.bottomRight),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          ),
          
          // 巨大的背景文字（英文目的地）
          Positioned(
            top: 45,
            left: -10,
            right: 45,
            child: Text(
              widget.destination.toUpperCase(),
              style: TextStyle(
                fontSize: 90,
                fontWeight: FontWeight.w900,
                color: Colors.grey.withValues(alpha: 0.15),
                letterSpacing: 2,
              ),
              maxLines: 1,
              overflow: TextOverflow.clip,
            ),
          ),
          
          // 巨大的背景文字（中文目的地）
          Positioned(
            top: 150,
            left: 10,
            child: Text(
              widget.destination,
              style: TextStyle(
                fontSize: 180,
                fontWeight: FontWeight.bold,
                color: Colors.grey.withValues(alpha: 0.12),
              ),
            ),
          ),
          
          // ==== 全高右侧蓝色边栏 ====
          Positioned(
            top: 0,
            bottom: 0,
            right: 0,
            width: 45,
            child: Container(
              color: const Color(0xFF88A8CD), // 浅蓝色
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const SizedBox(height: 20),
                  const RotatedBox(
                    quarterTurns: 1,
                    child: Text(
                      'BOARDING PASS',
                      style: TextStyle(color: Colors.white, fontSize: 10, letterSpacing: 2, fontWeight: FontWeight.bold),
                    ),
                  ),
                  const Spacer(),
                  const RotatedBox(
                    quarterTurns: 1,
                    child: Icon(Icons.flight_takeoff, color: Colors.white),
                  ),
                  const SizedBox(height: 20),
                  const RotatedBox(
                    quarterTurns: 1,
                    child: Text(
                      'TAOAGOU AIRLINES',
                      style: TextStyle(color: Colors.white, fontSize: 16, letterSpacing: 2, fontWeight: FontWeight.bold),
                    ),
                  ),
                  const Spacer(),
                  const RotatedBox(
                    quarterTurns: 1,
                    child: Text(
                      'BOARDING PASS',
                      style: TextStyle(color: Colors.white, fontSize: 10, letterSpacing: 2, fontWeight: FontWeight.bold),
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
          
          // ==== 顶部副联区域 ====
          Positioned(
            top: 15,
            left: 15,
            right: 55, // 增加右侧约束
            height: 90,
            child: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 条形码
                  RotatedBox(
                    quarterTurns: 1,
                    child: _buildBarcode(height: 40),
                  ),
                  const SizedBox(width: 25),
                  _buildTopStubText(seat),
                  const SizedBox(width: 25),
                  _buildTopStubText(timeStr),
                  const SizedBox(width: 25),
                  _buildTopStubText(gate),
                  const SizedBox(width: 25),
                  _buildTopStubText(flightNum),
                  const SizedBox(width: 25),
                  _buildTopStubText(displayName),
                ],
              ),
            ),
          ),
          
          // 虚线撕开线
          Positioned(
            top: 120,
            left: 0,
            right: 45,
            child: Row(
              children: List.generate(
                30,
                (index) => Expanded(
                  child: Container(
                    height: 1,
                    color: index % 2 == 0 ? Colors.grey.withValues(alpha: 0.5) : Colors.transparent,
                  ),
                ),
              ),
            ),
          ),
          
          // ==== 主区域左侧边缘 ====
          Positioned(
            top: 150,
            left: 15,
            bottom: 60,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const RotatedBox(
                  quarterTurns: 1,
                  child: Text(
                    'GATE CLOSES 25 MINUTES BEFORE DEPARTURE',
                    style: TextStyle(fontSize: 10, letterSpacing: 2, color: Colors.black87),
                  ),
                ),
                RotatedBox(
                  quarterTurns: 1,
                  child: Text(
                    'BAGGAGE CHECKED',
                    style: TextStyle(fontSize: 10, letterSpacing: 2, color: Colors.black.withValues(alpha: 0.5)),
                  ),
                ),
              ],
            ),
          ),
          
          // ==== 主区域内部左侧（从 / 到） ====
          Positioned(
            top: 250,
            left: 55,
            child: RotatedBox(
              quarterTurns: 1,
              child: Row(
                children: [
                  _buildFromToText('FROM', widget.origin.toUpperCase()),
                  const SizedBox(width: 50),
                  _buildFromToText('TO', widget.destination.toUpperCase()),
                ],
              ),
            ),
          ),
          
          // ==== 主区域右侧边缘（详细信息） ====
          Positioned(
            top: 150,
            right: 60,
            child: RotatedBox(
              quarterTurns: 1,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildMainDetailText('NAME', displayName),
                  const SizedBox(width: 35),
                  _buildMainDetailText('GATE', gate),
                  const SizedBox(width: 35),
                  _buildMainDetailText('TIME', timeStr),
                  const SizedBox(width: 35),
                  _buildMainDetailText('SEAT', seat),
                  const SizedBox(width: 35),
                  _buildMainDetailText('CLS', 'Y'),
                ],
              ),
            ),
          ),
          
          // ==== 主区域内部右侧（航班号） ====
          Positioned(
            top: 150,
            right: 100,
            child: RotatedBox(
              quarterTurns: 1,
              child: _buildMainDetailText('FLT', flightNum),
            ),
          ),

          // ==== 底部条形码区域 ====
          Positioned(
            bottom: 15,
            left: 45, // 增加左边距以防止与左侧垂直文字重叠
            right: 60,
            child: Column(
              children: [
                SizedBox(
                  height: 45, // 高度稍微增加以匹配参考图
                  width: double.infinity,
                  child: Row(
                    children: List.generate(
                      51, 
                      (index) {
                        // 看起来逼真的条形码条/空隙宽度序列
                        final flexValues = [
                          3, 2, 1, 2, 2, 1, 4, 1, 1, 2, 
                          3, 2, 1, 1, 2, 2, 1, 3, 2, 2, 
                          1, 1, 3, 2, 1, 4, 1, 2, 2, 1, 
                          3, 1, 1, 2, 4, 2, 1, 1, 2, 2, 
                          1, 3, 2, 2, 1, 1, 3, 2, 1, 4, 2
                        ];
                        return Expanded(
                          flex: flexValues[index],
                          child: Container(
                            color: index % 2 == 0 ? Colors.black87 : Colors.transparent,
                          ),
                        );
                      }
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '$dateStr  ${DateFormat('HH:mm').format(now)}  ${widget.origin}',
                  style: const TextStyle(
                    fontSize: 8,
                    color: Colors.black54,
                    letterSpacing: 2,
                  ),
                )
              ],
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildTopStubText(String value) {
    return RotatedBox(
      quarterTurns: 1,
      child: Text(value, style: const TextStyle(fontSize: 10, letterSpacing: 2, color: Colors.black87)),
    );
  }
  
  Widget _buildFromToText(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1, color: Colors.black87)),
        const SizedBox(height: 4),
        Text(value, style: const TextStyle(fontSize: 14, letterSpacing: 2, color: Colors.black87)),
      ],
    );
  }

  Widget _buildMainDetailText(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 2, color: Colors.black87)),
        const SizedBox(height: 4),
        Text(value, style: const TextStyle(fontSize: 14, letterSpacing: 1, color: Colors.black87)),
      ],
    );
  }

  Widget _buildBarcode({double height = 30}) {
    final List<int> widths = [2, 1, 3, 1, 2, 2, 1, 4, 1, 2, 1, 3, 2, 1, 1, 2, 3, 1, 2, 1, 2, 3, 1, 2, 1, 4, 1];
    return Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: widths.map((w) => Container(
        width: w.toDouble(),
        height: height,
        color: Colors.black87,
        margin: const EdgeInsets.only(right: 1.5),
      )).toList(),
    );
  }

  Widget _buildDragHandle(Alignment alignment) {
    return Align(
      alignment: alignment,
      child: Transform.translate(
        // 偏移手柄以将其精确地居中在角顶点上
        offset: Offset(
          alignment.x * 0.0, // 根据需要调整以居中在边框上
          alignment.y * 0.0,
        ),
        child: GestureDetector(
          onPanUpdate: (details) {
            // 根据拖拽方向计算缩放变化
            double dx = details.delta.dx;
            double dy = details.delta.dy;
            double scaleChange = 0;
            
            if (alignment == Alignment.topLeft) {
              scaleChange = -dx - dy;
            } else if (alignment == Alignment.topRight) {
              scaleChange = dx - dy;
            } else if (alignment == Alignment.bottomLeft) {
              scaleChange = -dx + dy;
            } else if (alignment == Alignment.bottomRight) {
              scaleChange = dx + dy;
            }
            
            setState(() {
              // 调整灵敏度并限制缩放比例范围
              _customScale += scaleChange * 0.005;
              if (_customScale < 0.2) _customScale = 0.2;
              if (_customScale > 10.0) _customScale = 10.0;
            });
          },
          child: Container(
            width: 10.0,
            height: 10.0,
            decoration: BoxDecoration(
              color: Colors.transparent, // 内部镂空
              border: Border.all(
                color: Colors.white,
                width: 1.5,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
