import 'dart:io';
import 'dart:math' as math;
import 'dart:ui';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image/image.dart' as img;
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import 'package:island_diary/features/record/presentation/pages/custom_camera/custom_camera_page.dart';
import 'travel_ticket_result_page.dart';
import 'package:island_diary/core/state/user_state.dart';

class TravelTicketPrinterPage extends StatefulWidget {
  final String destination;
  final String origin;
  final String mode;
  final String date;
  final VoidCallback onFinished;

  const TravelTicketPrinterPage({
    super.key,
    required this.destination,
    required this.origin,
    this.mode = 'flight',
    this.date = '',
    required this.onFinished,
  });

  @override
  State<TravelTicketPrinterPage> createState() =>
      _TravelTicketPrinterPageState();
}

class _TravelTicketPrinterPageState extends State<TravelTicketPrinterPage>
    with TickerProviderStateMixin {
  File? _selectedImage;
  bool _isScanned = false; // Photo selected and scan complete

  late AnimationController _introController;
  late Animation<double> _slideAnimation;
  late Animation<double> _floatAnimation;
  late Animation<double> _flipAnimation;

  late AnimationController _scanController;
  late Animation<double> _scanLineAnimation;

  @override
  void initState() {
    super.initState();

    // 1. Intro Animation (Slide up & Float)
    _introController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    );
    _slideAnimation = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _introController,
        curve: const Interval(0.0, 0.4, curve: Curves.easeOutCubic),
      ),
    );
    _floatAnimation = Tween<double>(begin: 0.0, end: 10.0).animate(
      CurvedAnimation(
        parent: _introController,
        curve: const Interval(0.4, 1.0, curve: Curves.easeInOutSine),
      ),
    );
    _flipAnimation = Tween<double>(begin: math.pi, end: 0.0).animate(
      CurvedAnimation(
        parent: _introController,
        curve: const Interval(0.2, 0.8, curve: Curves.easeOutBack),
      ),
    );

    // 2. Scan Animation (after selecting image)
    _scanController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
    _scanLineAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _scanController, curve: Curves.easeInOutCubic),
    );

    _scanController.addListener(() {
      if (_scanController.value > 0.95 && !_isScanned) {
        setState(() {
          _isScanned = true;
        });
        HapticFeedback.heavyImpact();
      }
    });

    _introController.forward();
    _introController.repeat(reverse: true, min: 0.4, max: 1.0); // Keep floating
  }

  @override
  void dispose() {
    _introController.dispose();
    _scanController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    if (_selectedImage != null) return;

    HapticFeedback.lightImpact();

    final Widget cameraPage = const CustomCameraPage(isAutoMatting: true);

    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => cameraPage),
    );

    if (result != null && result is Map) {
      final imagePath =
          (result['mattedPath'] ?? result['editedPath'] ?? result['image'])
              as String?;
      if (imagePath != null) {
        if (!mounted) return;

        // Crop transparent pixels in isolate
        final tempDir = await getTemporaryDirectory();
        final croppedPath = await compute(_cropImageIsolate, {
          'inputPath': imagePath,
          'tempPath': tempDir.path,
        });

        if (!mounted) return;
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => TravelTicketResultPage(
              image: File(croppedPath),
              origin: widget.origin,
              destination: widget.destination,
            ),
          ),
        );
        if (mounted) {
          widget.onFinished();
        }
      }
    }
  }

  static Future<String> _cropImageIsolate(Map<String, String> args) async {
    final inputPath = args['inputPath']!;
    final tempPath = args['tempPath']!;
    try {
      final bytes = await File(inputPath).readAsBytes();
      final image = img.decodeImage(bytes);
      if (image == null) return inputPath;

      int minX = image.width;
      int minY = image.height;
      int maxX = 0;
      int maxY = 0;
      bool found = false;

      // Fast iteration in image v4
      for (final p in image) {
        if (p.a > 10) {
          // Slightly higher threshold to ignore shadow/noise
          if (p.x < minX) minX = p.x;
          if (p.x > maxX) maxX = p.x;
          if (p.y < minY) minY = p.y;
          if (p.y > maxY) maxY = p.y;
          found = true;
        }
      }

      if (found &&
          (minX > 0 ||
              minY > 0 ||
              maxX < image.width - 1 ||
              maxY < image.height - 1)) {
        final cropped = img.copyCrop(
          image,
          x: minX,
          y: minY,
          width: maxX - minX + 1,
          height: maxY - minY + 1,
        );
        final newPath = path.join(
          tempPath,
          'cropped_${DateTime.now().millisecondsSinceEpoch}.png',
        );
        await File(newPath).writeAsBytes(img.encodePng(cropped));
        return newPath;
      } else {
        // If not found, or image is already tightly cropped, just return original
        return inputPath;
      }
    } catch (e) {
      debugPrint("Crop error: $e");
      return inputPath;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          // Background Blur
          Positioned.fill(
            child: GestureDetector(
              onTap: _isScanned ? widget.onFinished : null,
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                child: Container(color: Colors.black.withValues(alpha: 0.7)),
              ),
            ),
          ),

          SafeArea(
            child: AnimatedBuilder(
              animation: _introController,
              builder: (context, child) {
                final height = MediaQuery.of(context).size.height;
                final slideOffset = _slideAnimation.value * height;
                final floatOffset = _floatAnimation.value;

                return Transform.translate(
                  offset: Offset(0, slideOffset - floatOffset),
                  child: Center(
                    child: SingleChildScrollView(
                      clipBehavior: Clip.none,
                      physics: const BouncingScrollPhysics(),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              AnimatedBuilder(
                                animation: _introController,
                                builder: (context, child) {
                                  final isBack =
                                      _flipAnimation.value > math.pi / 2;
                                  return Transform(
                                    transform: Matrix4.identity()
                                      ..setEntry(3, 2, 0.001)
                                      ..rotateX(_flipAnimation.value),
                                    alignment: Alignment.bottomCenter,
                                    child: isBack
                                        ? Container(
                                            width: 320,
                                            height: 540 * 0.45,
                                            decoration: BoxDecoration(
                                              color: const Color(0xFF1E2024),
                                              borderRadius:
                                                  const BorderRadius.vertical(
                                                    top: Radius.circular(24),
                                                  ),
                                              border: Border.all(
                                                color: Colors.white10,
                                                width: 1,
                                              ),
                                            ),
                                          )
                                        : child,
                                  );
                                },
                                child: ClipRect(
                                  child: Align(
                                    alignment: Alignment.topCenter,
                                    heightFactor: 0.45,
                                    child: _buildTicketCard(),
                                  ),
                                ),
                              ),
                              ClipRect(
                                child: Align(
                                  alignment: Alignment.bottomCenter,
                                  heightFactor: 0.55,
                                  child: _buildTicketCard(),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 40),
                          if (!_isScanned)
                            TextButton(
                              onPressed: widget.onFinished,
                              style: TextButton.styleFrom(
                                foregroundColor: Colors.white54,
                              ),
                              child: const Text("直接跳过"),
                            )
                          else
                            ElevatedButton.icon(
                              onPressed: widget.onFinished,
                              icon: const Icon(Icons.check),
                              label: const Text("完成并保存"),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.white,
                                foregroundColor: Colors.black87,
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(24),
                                ),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 32,
                                  vertical: 14,
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
          ),
        ],
      ),
    );
  }

  Widget _buildTicketCard() {
    return ClipPath(
      clipper: _ModernTicketClipper(holeRadius: 12.0, splitRatio: 0.45),
      child: Container(
        width: 320,
        height: 540,
        decoration: BoxDecoration(
          color: const Color(0xFF1E2024), // Dark elegant card
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.4),
              blurRadius: 30,
              offset: const Offset(0, 15),
            ),
          ],
        ),
        child: Stack(
          children: [
            Column(
              children: [
                // Top Half: Cover Photo Area
                SizedBox(height: 540 * 0.45, child: _buildPhotoArea()),

                // Divider line
                const _DashedLine(color: Colors.white24),

                // Bottom Half: Ticket Information
                Expanded(child: _buildTicketInfo()),
              ],
            ),

            // Scan Laser Effect
            if (_selectedImage != null && !_isScanned)
              AnimatedBuilder(
                animation: _scanLineAnimation,
                builder: (context, child) {
                  final topOffset = _scanLineAnimation.value * (540 * 0.45);
                  return Positioned(
                    top: topOffset,
                    left: 0,
                    right: 0,
                    child: Container(
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.cyanAccent,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.cyanAccent.withValues(alpha: 0.8),
                            blurRadius: 10,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildPhotoArea() {
    return GestureDetector(
      onTap: _pickImage,
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (_selectedImage != null)
            Image.file(_selectedImage!, fit: BoxFit.cover)
          else
            Container(
              margin: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                border: Border.all(
                  color: Colors.white24,
                  width: 2,
                  style: BorderStyle.none,
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: CustomPaint(
                painter: _DashedRectPainter(color: Colors.white38),
                child: const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.camera_alt_outlined,
                        color: Colors.white54,
                        size: 40,
                      ),
                      SizedBox(height: 12),
                      Text(
                        "SELECT COVER PHOTO",
                        style: TextStyle(
                          color: Colors.white54,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 2,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

          // Subtle inner shadow for the photo area to give depth
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black.withValues(alpha: 0.3),
                  Colors.transparent,
                  Colors.black.withValues(alpha: 0.1),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTicketInfo() {
    final userName = UserState().userName.value.isNotEmpty
        ? UserState().userName.value
        : 'TRAVELER';
    final String flightNum = "ISL-${DateTime.now().month}${DateTime.now().day}";

    String dateStr =
        "${DateTime.now().year}.${DateTime.now().month.toString().padLeft(2, '0')}.${DateTime.now().day.toString().padLeft(2, '0')}";
    if (widget.date.isNotEmpty) {
      try {
        final parsed = DateTime.parse(widget.date);
        dateStr =
            "${parsed.year}.${parsed.month.toString().padLeft(2, '0')}.${parsed.day.toString().padLeft(2, '0')} ${parsed.hour.toString().padLeft(2, '0')}:${parsed.minute.toString().padLeft(2, '0')}";
      } catch (e) {
        dateStr = widget.date;
      }
    }

    // Simulate some realistic codes
    final String originCode = widget.origin.length > 4
        ? widget.origin.substring(0, 4)
        : widget.origin;
    final String destCode = widget.destination.length > 4
        ? widget.destination.substring(0, 4)
        : widget.destination;

    String modeLabel = "FLIGHT";
    IconData modeIcon = Icons.flight_takeoff_rounded;
    if (widget.mode == 'train') {
      modeLabel = "TRAIN";
      modeIcon = Icons.train;
    } else if (widget.mode == 'ship') {
      modeLabel = "SHIP";
      modeIcon = Icons.directions_boat;
    } else if (widget.mode == 'bus') {
      modeLabel = "BUS";
      modeIcon = Icons.directions_bus;
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header: Origin -> Destination
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                originCode,
                style: const TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                  letterSpacing: -1,
                ),
              ),
              Icon(modeIcon, color: Colors.blueAccent, size: 32),
              Text(
                destCode,
                style: const TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                  letterSpacing: -1,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                widget.origin,
                style: const TextStyle(
                  color: Colors.white54,
                  fontSize: 12,
                  letterSpacing: 1,
                ),
              ),
              Text(
                widget.destination,
                style: const TextStyle(
                  color: Colors.white54,
                  fontSize: 12,
                  letterSpacing: 1,
                ),
              ),
            ],
          ),

          const Spacer(),

          // Grid Data
          Row(
            children: [
              Expanded(
                flex: 3,
                child: _buildDataBlock(
                  "PASSENGER",
                  userName.toUpperCase(),
                  CrossAxisAlignment.start,
                ),
              ),
              Expanded(
                flex: 4,
                child: _buildDataBlock("DATE", dateStr, CrossAxisAlignment.end),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: _buildDataBlock(
                  modeLabel,
                  flightNum,
                  CrossAxisAlignment.start,
                ),
              ),
              Expanded(
                child: _buildDataBlock(
                  "SEAT",
                  "42A",
                  CrossAxisAlignment.center,
                ),
              ),
              Expanded(
                child: _buildDataBlock(
                  "CLASS",
                  "FIRST",
                  CrossAxisAlignment.end,
                ),
              ),
            ],
          ),

          const Spacer(),

          // Barcode
          AnimatedOpacity(
            duration: const Duration(milliseconds: 500),
            opacity: _isScanned ? 1.0 : 0.2,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                45,
                (index) => Container(
                  width: (index % 4 == 0)
                      ? 3.0
                      : ((index % 7 == 0) ? 5.0 : 1.5),
                  height: 36,
                  margin: const EdgeInsets.only(right: 2),
                  color: _isScanned ? Colors.white : Colors.white24,
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Center(
            child: Text(
              "202${DateTime.now().millisecondsSinceEpoch.toString().substring(5, 11)}",
              style: TextStyle(
                color: _isScanned ? Colors.white70 : Colors.white24,
                fontSize: 10,
                letterSpacing: 6,
                fontFamily: 'monospace',
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDataBlock(
    String label,
    String value, [
    CrossAxisAlignment align = CrossAxisAlignment.start,
  ]) {
    return Column(
      crossAxisAlignment: align,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.5,
            color: Colors.white38,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.white,
            letterSpacing: 1,
            fontFamily: 'monospace',
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------
// Custom Clippers & Painters
// ---------------------------------------------------------

/// Clips the ticket shape with side holes
class _ModernTicketClipper extends CustomClipper<Path> {
  final double holeRadius;
  final double splitRatio;

  _ModernTicketClipper({required this.holeRadius, required this.splitRatio});

  @override
  Path getClip(Size size) {
    final path = Path();
    final cornerRadius = 24.0;

    // Start at top-left
    path.moveTo(0, cornerRadius);
    path.quadraticBezierTo(0, 0, cornerRadius, 0);

    // Top-right
    path.lineTo(size.width - cornerRadius, 0);
    path.quadraticBezierTo(size.width, 0, size.width, cornerRadius);

    // Right hole
    final splitY = size.height * splitRatio;
    path.lineTo(size.width, splitY - holeRadius);
    path.arcToPoint(
      Offset(size.width, splitY + holeRadius),
      radius: Radius.circular(holeRadius),
      clockwise: false,
    );

    // Bottom-right
    path.lineTo(size.width, size.height - cornerRadius);
    path.quadraticBezierTo(
      size.width,
      size.height,
      size.width - cornerRadius,
      size.height,
    );

    // Bottom-left
    path.lineTo(cornerRadius, size.height);
    path.quadraticBezierTo(0, size.height, 0, size.height - cornerRadius);

    // Left hole
    path.lineTo(0, splitY + holeRadius);
    path.arcToPoint(
      Offset(0, splitY - holeRadius),
      radius: Radius.circular(holeRadius),
      clockwise: false,
    );

    path.close();
    return path;
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => true;
}

class _DashedLine extends StatelessWidget {
  final Color color;
  const _DashedLine({required this.color});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final boxWidth = constraints.constrainWidth();
        final dashWidth = 6.0;
        final dashHeight = 2.0;
        final dashCount = (boxWidth / (2 * dashWidth)).floor();
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: List.generate(dashCount, (_) {
              return SizedBox(
                width: dashWidth,
                height: dashHeight,
                child: DecoratedBox(decoration: BoxDecoration(color: color)),
              );
            }),
          ),
        );
      },
    );
  }
}

class _DashedRectPainter extends CustomPainter {
  final Color color;
  _DashedRectPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    final dashWidth = 8.0;
    final dashSpace = 6.0;

    final rect = Rect.fromLTWH(0, 0, size.width, size.height);
    bool draw = true;

    // Draw top
    for (
      double i = rect.left;
      i < rect.right;
      i += (draw ? dashWidth : dashSpace)
    ) {
      if (draw) {
        canvas.drawLine(
          Offset(i, rect.top),
          Offset(i + dashWidth, rect.top),
          paint,
        );
      }
      draw = !draw;
    }
    // Draw right
    draw = true;
    for (
      double i = rect.top;
      i < rect.bottom;
      i += (draw ? dashWidth : dashSpace)
    ) {
      if (draw) {
        canvas.drawLine(
          Offset(rect.right, i),
          Offset(rect.right, i + dashWidth),
          paint,
        );
      }
      draw = !draw;
    }
    // Draw bottom
    draw = true;
    for (
      double i = rect.right;
      i > rect.left;
      i -= (draw ? dashWidth : dashSpace)
    ) {
      if (draw) {
        canvas.drawLine(
          Offset(i, rect.bottom),
          Offset(i - dashWidth, rect.bottom),
          paint,
        );
      }
      draw = !draw;
    }
    // Draw left
    draw = true;
    for (
      double i = rect.bottom;
      i > rect.top;
      i -= (draw ? dashWidth : dashSpace)
    ) {
      if (draw) {
        canvas.drawLine(
          Offset(rect.left, i),
          Offset(rect.left, i - dashWidth),
          paint,
        );
      }
      draw = !draw;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
