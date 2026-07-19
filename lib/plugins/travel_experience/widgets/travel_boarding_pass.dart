import 'dart:io';
import 'package:flutter/material.dart';

class TravelBoardingPass extends StatelessWidget {
  final File imageFile;
  final String destination;
  final String origin;
  final String flightNumber;
  final String name;

  const TravelBoardingPass({
    super.key,
    required this.imageFile,
    required this.destination,
    required this.origin,
    required this.flightNumber,
    required this.name,
  });

  @override
  Widget build(BuildContext context) {
    // 票根的整体比例和样式
    return AspectRatio(
      aspectRatio: 9 / 19.5,
      child: ClipPath(
        clipper: _TicketClipper(),
        child: Container(
          color: const Color(0xFFE8E5E1), // 纸张底色
          child: Stack(
            children: [
              // 1. 底层：稍微高斯模糊的照片作为打底氛围
              Positioned.fill(
                child: Opacity(
                  opacity: 0.3,
                  child: Image.file(
                    imageFile,
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              
              // 2. 巨大背景文字（目的地大写）
              Positioned.fill(
                child: Align(
                  alignment: Alignment.topCenter,
                  child: Padding(
                    padding: const EdgeInsets.only(top: 80.0),
                    child: Text(
                      destination.toUpperCase(),
                      style: const TextStyle(
                        fontFamily: 'serif',
                        fontSize: 100,
                        height: 0.8,
                        fontWeight: FontWeight.w900,
                        color: Color(0x33000000), // 半透明黑色
                        letterSpacing: -4,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.clip,
                    ),
                  ),
                ),
              ),

              // 3. “抠像”主体层（目前因为没有 API，所以用完整图片带一点羽化遮罩来代替主体）
              Positioned(
                top: 150,
                bottom: 120,
                left: 40,
                right: 40,
                child: Image.file(
                  imageFile,
                  fit: BoxFit.cover,
                ),
              ),

              // 4. 左侧排版信息
              Positioned(
                top: 40,
                left: 16,
                bottom: 120,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildVerticalInfo('FLT', flightNumber),
                    _buildVerticalInfo('GATE', '42'),
                    _buildVerticalInfo('TIME', '00:42'),
                    _buildVerticalInfo('SEAT', '42A'),
                    const Spacer(),
                    _buildVerticalInfo('FROM', origin.toUpperCase()),
                    _buildVerticalInfo('TO', destination.toUpperCase()),
                  ],
                ),
              ),

              // 5. 右侧边条信息
              Positioned(
                top: 0,
                right: 0,
                bottom: 0,
                child: Container(
                  width: 44,
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Color(0xFFB4C8E0), Color(0xFFE2C4C6)],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                  ),
                  child: Column(
                    children: [
                      const SizedBox(height: 30),
                      const RotatedBox(
                        quarterTurns: 1,
                        child: Text(
                          'BOARDING PASS',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            letterSpacing: 2,
                          ),
                        ),
                      ),
                      const Spacer(),
                      RotatedBox(
                        quarterTurns: 1,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.flight, color: Colors.blue, size: 20),
                            const SizedBox(width: 8),
                            Text(
                              'ISLAND AIRLINES',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w900,
                                color: Colors.blue.shade700,
                                letterSpacing: 1,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Spacer(),
                      const RotatedBox(
                        quarterTurns: 1,
                        child: Text(
                          'BOARDING PASS',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            letterSpacing: 2,
                          ),
                        ),
                      ),
                      const SizedBox(height: 30),
                    ],
                  ),
                ),
              ),
              
              // 6. 顶部乘客姓名信息
              Positioned(
                top: 30,
                right: 60,
                child: _buildVerticalInfo('NAME', name),
              ),

              // 7. 底部条形码和时间信息
              Positioned(
                bottom: 24,
                left: 24,
                right: 24,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'BAGGAGE UPC',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 2,
                        color: Colors.black54,
                      ),
                    ),
                    const SizedBox(height: 8),
                    // 简单的模拟条形码
                    Row(
                      children: List.generate(
                        40,
                        (index) => Container(
                          width: (index % 3 == 0) ? 3.0 : ((index % 5 == 0) ? 4.0 : 1.5),
                          height: 40,
                          margin: const EdgeInsets.only(right: 2),
                          color: Colors.black87,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildVerticalInfo(String title, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: RotatedBox(
        quarterTurns: 1,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                letterSpacing: 1,
                color: Colors.black54,
              ),
            ),
            const SizedBox(width: 12),
            Text(
              value,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                letterSpacing: 2,
                color: Colors.black87,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 绘制带有票据缺口和打孔线的裁剪器
class _TicketClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final path = Path();
    path.lineTo(0, size.height);
    path.lineTo(size.width, size.height);
    path.lineTo(size.width, 0);
    path.close();

    // 简单实现一个底部和顶部的半圆缺口
    final cutoutRadius = 12.0;
    
    // 扣掉右上角缺口（模拟撕口）
    path.addOval(Rect.fromCircle(center: Offset(size.width - 44, 0), radius: cutoutRadius));
    path.addOval(Rect.fromCircle(center: Offset(size.width - 44, size.height), radius: cutoutRadius));
    
    return Path.combine(PathOperation.difference, path, path);
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}
