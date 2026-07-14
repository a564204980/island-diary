import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:island_diary/shared/widgets/date_picker/island_date_time_picker.dart';

class TravelTicketDialog extends StatefulWidget {
  final String? initialOrigin;
  final String? initialDestination;
  final String flightNumber;

  const TravelTicketDialog({
    super.key,
    this.initialOrigin,
    this.initialDestination,
    required this.flightNumber,
  });

  static Future<Map<String, String>?> show(BuildContext context, {
    String? initialOrigin,
    String? initialDestination,
  }) {
    final now = DateTime.now();
    final flightNumber = 'ISLAND-${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}';
    
    return showGeneralDialog<Map<String, String>>(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'TravelTicketDialog',
      barrierColor: Colors.black.withValues(alpha: 0.4),
      transitionDuration: const Duration(milliseconds: 400),
      pageBuilder: (context, anim1, anim2) {
        return Center(
          child: Material(
            color: Colors.transparent,
            child: TravelTicketDialog(
              initialOrigin: initialOrigin,
              initialDestination: initialDestination,
              flightNumber: flightNumber,
            ),
          ),
        );
      },
      transitionBuilder: (context, anim1, anim2, child) {
        return SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0, 0.1),
            end: Offset.zero,
          ).animate(CurvedAnimation(parent: anim1, curve: Curves.easeOutCubic)),
          child: FadeTransition(
            opacity: anim1,
            child: child,
          ),
        );
      },
    );
  }

  @override
  State<TravelTicketDialog> createState() => _TravelTicketDialogState();
}

enum TransportMode { flight, train, bus, ship }

class _TravelTicketDialogState extends State<TravelTicketDialog> with SingleTickerProviderStateMixin {
  late TextEditingController _originCtrl;
  late TextEditingController _destCtrl;
  TransportMode _mode = TransportMode.flight;
  
  late AnimationController _stampController;
  bool _isConfirmed = false;
  late PageController _transportPageCtrl;
  late DateTime _departureTime;
  late DateTime _arrivalTime;

  @override
  void initState() {
    super.initState();
    _originCtrl = TextEditingController(text: widget.initialOrigin);
    _destCtrl = TextEditingController(text: widget.initialDestination);
    _transportPageCtrl = PageController(
      initialPage: TransportMode.values.indexOf(_mode),
      viewportFraction: 0.45,
    );
    
    final now = DateTime.now();
    _departureTime = now;
    _arrivalTime = now.add(const Duration(hours: 3));
    
    // 总时长延长到 2500 毫秒
    _stampController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2500),
    );
  }

  @override
  void dispose() {
    _originCtrl.dispose();
    _destCtrl.dispose();
    _stampController.dispose();
    _transportPageCtrl.dispose();
    super.dispose();
  }

  void _showDateTimePicker(bool isDeparture) async {
    HapticFeedback.selectionClick();
    DateTime initialTime = isDeparture ? _departureTime : _arrivalTime;
    
    final selectedTime = await IslandDateTimePicker.show(
      context,
      initialDate: initialTime,
    );
    
    if (selectedTime != null && mounted) {
      setState(() {
        if (isDeparture) {
          _departureTime = selectedTime;
          if (_arrivalTime.isBefore(_departureTime)) {
            _arrivalTime = _departureTime.add(const Duration(hours: 3));
          }
        } else {
          _arrivalTime = selectedTime;
        }
      });
    }
  }

  void _onConfirm() async {
    if (_isConfirmed) return;
    
    setState(() {
      _isConfirmed = true;
    });
    
    await _stampController.forward();
    await Future.delayed(const Duration(milliseconds: 100));
    
    if (!mounted) return;
    Navigator.of(context).pop({
      'origin': _originCtrl.text.trim(),
      'destination': _destCtrl.text.trim(),
      'mode': _mode.name,
      'departureTime': _departureTime.toIso8601String(),
      'arrivalTime': _arrivalTime.toIso8601String(),
    });
  }
  
  String get _ticketTitle {
    switch (_mode) {
      case TransportMode.flight: return '登 机 牌';
      case TransportMode.train: return '火 车 票';
      case TransportMode.bus: return '汽 车 票';
      case TransportMode.ship: return '船 票';
    }
  }
  
  String get _vehicleLabel {
    switch (_mode) {
      case TransportMode.flight: return '航班号';
      case TransportMode.train: return '车次';
      case TransportMode.bus: return '车牌号';
      case TransportMode.ship: return '航次';
    }
  }
  

  
  double get _vehicleShadowAngle {
    switch (_mode) {
      case TransportMode.flight:
        return 0.0;
      default:
        return 0.0;
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isNight = Theme.of(context).brightness == Brightness.dark;
    
    final Color ticketBgColor = isNight ? const Color(0xFF1E293B) : Colors.white;
    final Color primaryColor = isNight ? const Color(0xFF38BDF8) : const Color(0xFF0284C7);
    final Color secondaryColor = isNight ? const Color(0xFF7DD3FC) : const Color(0xFF38BDF8);
    final Color textColor = isNight ? Colors.white : const Color(0xFF0F172A);
    final Color subTextColor = isNight ? Colors.white70 : const Color(0xFF64748B);

    final topTicket = PhysicalShape(
      color: ticketBgColor,
      clipper: TicketTopClipper(radius: 20, cutoutRadius: 10),
      elevation: _isConfirmed ? 12 : 24,
      shadowColor: Colors.black.withValues(alpha: 0.5),
      clipBehavior: Clip.antiAlias,
      child: SizedBox(
        width: 320,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              padding: const EdgeInsets.fromLTRB(24, 20, 24, 16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [primaryColor, secondaryColor],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        _ticketTitle,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 4.0,
                          fontSize: 18,
                          fontFamily: 'LXGWWenKai',
                        ),
                      ),
                      // 微型翻页器 (Mini Carousel)
                      SizedBox(
                        width: 100,
                        height: 36,
                        child: PageView.builder(
                          controller: _transportPageCtrl,
                          onPageChanged: (index) {
                            HapticFeedback.selectionClick();
                            setState(() => _mode = TransportMode.values[index]);
                          },
                          itemCount: TransportMode.values.length,
                          itemBuilder: (context, index) {
                            final mode = TransportMode.values[index];
                            final isSelected = _mode == mode;
                            
                            return AnimatedScale(
                              scale: isSelected ? 1.0 : 0.5,
                              duration: const Duration(milliseconds: 300),
                              curve: Curves.easeOutBack,
                              child: AnimatedOpacity(
                                opacity: isSelected ? 1.0 : 0.3,
                                duration: const Duration(milliseconds: 200),
                                child: Center(
                                  child: Transform.rotate(
                                    angle: isSelected ? _vehicleShadowAngle : 0,
                                    child: SizedBox(
                                      width: 24, height: 24,
                                      child: _buildSilhouette(mode, Colors.white),
                                    ),
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 28, 24, 28),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('出发地', style: TextStyle(color: subTextColor, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1.0)),
                        const SizedBox(height: 6),
                        TextField(
                          controller: _originCtrl,
                          maxLines: 2,
                          minLines: 1,
                          keyboardType: TextInputType.text,
                          textInputAction: TextInputAction.next,
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: textColor, fontFamily: 'LXGWWenKai', overflow: TextOverflow.ellipsis),
                          decoration: InputDecoration(
                            isDense: true,
                            contentPadding: EdgeInsets.zero,
                            hintText: '出发地',
                            hintStyle: TextStyle(color: subTextColor.withValues(alpha: 0.4), fontFamily: 'LXGWWenKai'),
                            border: InputBorder.none,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Column(
                      children: [
                        Text(' ', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 6),
                        Icon(Icons.arrow_right_alt_rounded, color: primaryColor.withValues(alpha: 0.6), size: 32),
                      ],
                    ),
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text('目的地', style: TextStyle(color: subTextColor, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1.0)),
                        const SizedBox(height: 6),
                        TextField(
                          controller: _destCtrl,
                          textAlign: TextAlign.right,
                          maxLines: 2,
                          minLines: 1,
                          keyboardType: TextInputType.text,
                          textInputAction: TextInputAction.done,
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: textColor, fontFamily: 'LXGWWenKai', overflow: TextOverflow.ellipsis),
                          decoration: InputDecoration(
                            isDense: true,
                            contentPadding: EdgeInsets.zero,
                            hintText: '目的地',
                            hintStyle: TextStyle(color: subTextColor.withValues(alpha: 0.4), fontFamily: 'LXGWWenKai'),
                            border: InputBorder.none,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );

    final bottomTicket = PhysicalShape(
      color: ticketBgColor,
      clipper: TicketBottomClipper(radius: 20, cutoutRadius: 10),
      elevation: _isConfirmed ? 12 : 24,
      shadowColor: Colors.black.withValues(alpha: 0.5),
      clipBehavior: Clip.antiAlias,
      child: SizedBox(
        width: 320,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      GestureDetector(
                        onTap: () => _showDateTimePicker(true),
                        child: Container(
                          color: Colors.transparent,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('出发时间', style: TextStyle(color: subTextColor, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1.0)),
                              const SizedBox(height: 4),
                              Text(
                                '${_departureTime.hour.toString().padLeft(2, '0')}:${_departureTime.minute.toString().padLeft(2, '0')}',
                                style: TextStyle(color: textColor, fontSize: 24, fontWeight: FontWeight.w800, fontFamily: 'LXGWWenKai'),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                '${_departureTime.year}.${_departureTime.month.toString().padLeft(2, '0')}.${_departureTime.day.toString().padLeft(2, '0')}',
                                style: TextStyle(color: subTextColor, fontSize: 12, fontWeight: FontWeight.w500, fontFamily: 'LXGWWenKai'),
                              ),
                            ],
                          ),
                        ),
                      ),
                      GestureDetector(
                        onTap: () => _showDateTimePicker(false),
                        child: Container(
                          color: Colors.transparent,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text('抵达时间', style: TextStyle(color: subTextColor, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1.0)),
                              const SizedBox(height: 4),
                              Text(
                                '${_arrivalTime.hour.toString().padLeft(2, '0')}:${_arrivalTime.minute.toString().padLeft(2, '0')}',
                                style: TextStyle(color: textColor, fontSize: 24, fontWeight: FontWeight.w800, fontFamily: 'LXGWWenKai'),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                '${_arrivalTime.year}.${_arrivalTime.month.toString().padLeft(2, '0')}.${_arrivalTime.day.toString().padLeft(2, '0')}',
                                style: TextStyle(color: subTextColor, fontSize: 12, fontWeight: FontWeight.w500, fontFamily: 'LXGWWenKai'),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('乘客', style: TextStyle(color: subTextColor, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1.0)),
                          const SizedBox(height: 6),
                          Text(
                            '旅行者 (Me)',
                            style: TextStyle(color: textColor, fontSize: 14, fontWeight: FontWeight.w700, fontFamily: 'LXGWWenKai'),
                          ),
                        ],
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(_vehicleLabel, style: TextStyle(color: subTextColor, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1.0)),
                          const SizedBox(height: 6),
                          Text(
                            widget.flightNumber,
                            style: TextStyle(color: textColor, fontSize: 14, fontWeight: FontWeight.w700, fontFamily: 'LXGWWenKai'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
              child: GestureDetector(
                onTap: _onConfirm,
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [primaryColor, secondaryColor],
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                    ),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: primaryColor.withValues(alpha: 0.3),
                        blurRadius: 12,
                        offset: const Offset(0, 6),
                      )
                    ],
                  ),
                  alignment: Alignment.center,
                  child: const Text(
                    '确认启程',
                    style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 4, fontFamily: 'LXGWWenKai'),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );

    return SizedBox.expand(
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.center,
        children: [
          AnimatedBuilder(
            animation: _stampController,
            builder: (context, child) {
              final progress = _stampController.value;
              // 撕裂动画时间变短，只占总时长的 25% (2500ms * 0.25 = 625ms)
              final tearInterval = (progress / 0.25).clamp(0.0, 1.0);
              final tearProgress = Curves.easeInOutCubic.transform(tearInterval);
              
              final topScale = 1.0 - (tearProgress * 0.15);
              final topOpacity = 1.0 - (tearProgress > 0.8 ? (tearProgress - 0.8) * 5 : 0.0);
              
              final bottomOffset = tearProgress * 350.0;
              final bottomRotation = tearProgress * 0.25;
              final bottomOpacity = 1.0 - (tearProgress > 0.5 ? (tearProgress - 0.5) * 2 : 0.0);
              
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Transform.scale(
                    scale: topScale,
                    child: Opacity(
                      opacity: topOpacity,
                      child: topTicket,
                    ),
                  ),
                  Opacity(
                    opacity: 1.0 - (tearProgress * 2).clamp(0.0, 1.0),
                    child: SizedBox(
                      width: 320,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        child: CustomPaint(
                          painter: DashedLinePainter(color: subTextColor.withValues(alpha: 0.3)),
                          size: const Size(double.infinity, 0),
                        ),
                      ),
                    ),
                  ),
                  Transform.translate(
                    offset: Offset(0, bottomOffset),
                    child: Transform.rotate(
                      angle: bottomRotation,
                      child: Opacity(
                        opacity: bottomOpacity,
                        child: bottomTicket,
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
          
          if (_isConfirmed)
            AnimatedBuilder(
              animation: _stampController,
              builder: (context, child) {
                final progress = _stampController.value;
                // 飞机有充分的 75% 的时间缓慢滑翔 (2500ms * 0.75 = 1875ms)
                final flyInterval = ((progress - 0.25) / 0.75).clamp(0.0, 1.0);
                final flyProgress = Curves.easeInOut.transform(flyInterval);
                
                final screenHeight = MediaQuery.of(context).size.height;
                
                final startY = screenHeight * 0.9;
                final endY = -screenHeight * 0.9;
                
                final currentY = startY + (endY - startY) * flyProgress;
                
                double shadowOpacity = 0.0;
                if (flyProgress > 0.0) {
                  if (flyProgress > 0.1 && flyProgress < 0.9) {
                    shadowOpacity = 0.2; 
                  } else if (flyProgress <= 0.1) {
                    shadowOpacity = flyProgress * 2.0;
                  } else if (flyProgress >= 0.9) {
                    shadowOpacity = (1.0 - flyProgress) * 2.0;
                  }
                }
                
                return Positioned(
                  left: 0,
                  right: 0,
                  top: currentY,
                  child: IgnorePointer(
                    child: Opacity(
                      opacity: shadowOpacity,
                      child: Transform.rotate(
                        angle: _vehicleShadowAngle, 
                        child: Align(
                          alignment: Alignment.center,
                          child: SizedBox(
                            width: 800, height: 800,
                            child: _buildSilhouette(_mode, Colors.black),
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
        ],
      ),
    );
  }

  Widget _buildSilhouette(TransportMode mode, Color color) {
    switch (mode) {
      case TransportMode.flight:
        return CustomPaint(painter: AirplaneSilhouettePainter(color: color));
      case TransportMode.train:
        return CustomPaint(painter: TrainSilhouettePainter(color: color));
      case TransportMode.bus:
        return CustomPaint(painter: BusSilhouettePainter(color: color));
      case TransportMode.ship:
        return CustomPaint(painter: ShipSilhouettePainter(color: color));
    }
  }
}

class AirplaneSilhouettePainter extends CustomPainter {
  final Color color;
  AirplaneSilhouettePainter({this.color = Colors.black});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;
    final path = Path();
    
    final double w = size.width;
    final double h = size.height;
    
    double x(double val) => (val / 100.0) * w;
    double y(double val) => (val / 100.0) * h;
    
    path.moveTo(x(50), y(5)); // Nose tip
    
    // --- RIGHT SIDE ---
    path.quadraticBezierTo(x(56), y(10), x(56), y(35)); // Right nose curve
    
    path.lineTo(x(56), y(40)); // Right Wing LE Root
    
    path.lineTo(x(61), y(42)); // To inner engine
    path.lineTo(x(61), y(37.5)); // Inner engine front left
    path.quadraticBezierTo(x(62.5), y(36.5), x(64), y(37.5)); // Inner engine front curve
    path.lineTo(x(64), y(43.5)); // Inner engine back right
    
    path.lineTo(x(73), y(47.5)); // To outer engine
    path.lineTo(x(73), y(44.5)); // Outer engine front left
    path.quadraticBezierTo(x(74), y(44), x(75), y(44.5)); // Outer engine front curve
    path.lineTo(x(75), y(48.5)); // Outer engine back right
    
    path.lineTo(x(94), y(56)); // Wing LE Tip
    path.quadraticBezierTo(x(96), y(57), x(94), y(59)); // Wing Tip Curve
    
    // Clean trailing edge
    path.lineTo(x(56), y(54)); // Right Wing TE Root
    
    path.lineTo(x(56), y(75)); // Right Fuselage
    path.lineTo(x(54.5), y(82)); // Fuselage tapering
    
    path.lineTo(x(70), y(86)); // Right Stab LE Tip
    path.quadraticBezierTo(x(71), y(87), x(70), y(89)); // Right Stab Tip Curve
    
    path.lineTo(x(53.5), y(87)); // Right Stab TE Root
    
    path.lineTo(x(51), y(92)); // APU Base
    path.lineTo(x(51), y(97)); // APU Tip Right
    path.lineTo(x(50), y(98)); // APU Tip Center
    
    // --- LEFT SIDE ---
    path.lineTo(x(49), y(97)); // APU Tip Left
    path.lineTo(x(49), y(92)); // APU Base Left
    
    path.lineTo(x(46.5), y(87)); // Left Stab TE Root
    
    path.lineTo(x(30), y(89)); // Left Stab Tip
    path.quadraticBezierTo(x(29), y(87), x(30), y(86)); // Left Stab Tip Curve
    
    path.lineTo(x(45.5), y(82)); // Left Stab LE Root
    
    path.lineTo(x(44), y(75)); // Left Fuselage
    
    path.lineTo(x(44), y(54)); // Left Wing TE Root
    
    path.lineTo(x(6), y(59)); // Left Wing TE Tip
    path.quadraticBezierTo(x(4), y(57), x(6), y(56)); // Left Wing Tip Curve
    
    path.lineTo(x(25), y(48.5)); // Outer engine back left
    path.lineTo(x(25), y(44.5)); // Outer engine front left
    path.quadraticBezierTo(x(26), y(44), x(27), y(44.5)); // Outer engine curve
    path.lineTo(x(27), y(47.5)); // Outer engine back right
    
    path.lineTo(x(36), y(43.5)); // Inner engine back left
    path.lineTo(x(36), y(37.5)); // Inner engine front left
    path.quadraticBezierTo(x(37.5), y(36.5), x(39), y(37.5)); // Inner engine curve
    path.lineTo(x(39), y(42)); // Inner engine back right
    
    path.lineTo(x(44), y(40)); // Left Wing LE Root
    
    path.lineTo(x(44), y(35)); // Left Fuselage
    path.quadraticBezierTo(x(44), y(10), x(50), y(5)); // Left nose curve
    
    path.close();
    
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class TrainSilhouettePainter extends CustomPainter {
  final Color color;
  TrainSilhouettePainter({this.color = Colors.black});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;
    final path = Path();
    
    final double w = size.width;
    final double h = size.height;
    
    double x(double val) => (val / 100.0) * w;
    double y(double val) => (val / 100.0) * h;
    
    // Bullet train side view facing right
    path.moveTo(x(10), y(40)); // top left
    path.lineTo(x(60), y(40)); // top flat
    path.quadraticBezierTo(x(85), y(40), x(95), y(75)); // sloping nose
    path.quadraticBezierTo(x(96), y(80), x(90), y(80)); // nose bottom
    path.lineTo(x(10), y(80)); // bottom flat
    path.lineTo(x(10), y(40)); // back flat
    path.close();
    
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class BusSilhouettePainter extends CustomPainter {
  final Color color;
  BusSilhouettePainter({this.color = Colors.black});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;
    final path = Path();
    
    final double w = size.width;
    final double h = size.height;
    
    double x(double val) => (val / 100.0) * w;
    double y(double val) => (val / 100.0) * h;
    
    // Cute Car side view facing right
    path.fillType = PathFillType.evenOdd;
    
    // 1. Main body
    path.moveTo(x(10), y(50)); // Back middle
    path.quadraticBezierTo(x(10), y(25), x(30), y(22)); // Back to roof
    path.lineTo(x(50), y(22)); // Roof flat
    path.lineTo(x(63), y(38)); // Windshield down to mirror
    path.lineTo(x(65), y(34)); // Mirror top
    path.lineTo(x(68), y(42)); // Mirror bottom right
    path.lineTo(x(70), y(42)); // Windshield bottom
    path.quadraticBezierTo(x(85), y(45), x(92), y(50)); // Hood
    path.quadraticBezierTo(x(95), y(65), x(92), y(75)); // Front bumper
    path.lineTo(x(85), y(75)); // Bottom front
    path.arcToPoint(Offset(x(65), y(75)), radius: Radius.circular(x(10)), clockwise: false); // Front arch
    path.lineTo(x(40), y(75)); // Bottom middle
    path.arcToPoint(Offset(x(20), y(75)), radius: Radius.circular(x(10)), clockwise: false); // Back arch
    path.lineTo(x(10), y(75)); // Bottom back
    path.close();

    // 2. Back window
    final Path backWindow = Path();
    backWindow.moveTo(x(35), y(42));
    backWindow.lineTo(x(16), y(42));
    backWindow.quadraticBezierTo(x(16), y(28), x(30), y(26));
    backWindow.lineTo(x(35), y(26));
    backWindow.close();
    path.addPath(backWindow, Offset.zero);

    // 3. Front window
    final Path frontWindow = Path();
    frontWindow.moveTo(x(40), y(42));
    frontWindow.lineTo(x(62), y(42));
    frontWindow.lineTo(x(48), y(26));
    frontWindow.lineTo(x(40), y(26));
    frontWindow.close();
    path.addPath(frontWindow, Offset.zero);

    // 4. Side stripe
    path.addRRect(RRect.fromRectAndRadius(
      Rect.fromLTRB(x(22), y(54), x(72), y(58)),
      Radius.circular(x(2))
    ));

    // 5. Headlight & Taillight
    path.addRRect(RRect.fromRectAndRadius(
      Rect.fromLTRB(x(88), y(48), x(93), y(56)),
      Radius.circular(x(2))
    ));
    path.addRRect(RRect.fromRectAndRadius(
      Rect.fromLTRB(x(10), y(45), x(13), y(56)),
      Radius.circular(x(1.5))
    ));

    // 6. Wheels (Solid circles inside the arches)
    path.addOval(Rect.fromCircle(center: Offset(x(30), y(75)), radius: x(7)));
    path.addOval(Rect.fromCircle(center: Offset(x(75), y(75)), radius: x(7)));
    
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class ShipSilhouettePainter extends CustomPainter {
  final Color color;
  ShipSilhouettePainter({this.color = Colors.black});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;
    final path = Path();
    
    final double w = size.width;
    final double h = size.height;
    
    double x(double val) => (val / 100.0) * w;
    double y(double val) => (val / 100.0) * h;
    
    // Ship side view facing right
    path.moveTo(x(10), y(30)); // top back
    path.lineTo(x(30), y(30));
    path.lineTo(x(30), y(45));
    path.lineTo(x(70), y(45)); // cabin
    path.lineTo(x(75), y(60)); // deck
    path.lineTo(x(95), y(60)); // bow top
    path.quadraticBezierTo(x(95), y(80), x(80), y(80)); // bow curve to bottom
    path.lineTo(x(20), y(80)); // bottom flat
    path.lineTo(x(10), y(60)); // stern curve
    path.close();
    
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class TicketTopClipper extends CustomClipper<Path> {
  final double radius;
  final double cutoutRadius;
  TicketTopClipper({this.radius = 20.0, this.cutoutRadius = 10.0});

  @override
  Path getClip(Size size) {
    final path = Path();
    path.moveTo(radius, 0);
    path.lineTo(size.width - radius, 0);
    path.arcToPoint(Offset(size.width, radius), radius: Radius.circular(radius));
    
    path.lineTo(size.width, size.height - cutoutRadius);
    path.arcToPoint(Offset(size.width - cutoutRadius, size.height), radius: Radius.circular(cutoutRadius), clockwise: false);
    
    path.lineTo(cutoutRadius, size.height);
    path.arcToPoint(Offset(0, size.height - cutoutRadius), radius: Radius.circular(cutoutRadius), clockwise: false);
    
    path.lineTo(0, radius);
    path.arcToPoint(Offset(radius, 0), radius: Radius.circular(radius));
    
    return path;
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}

class TicketBottomClipper extends CustomClipper<Path> {
  final double radius;
  final double cutoutRadius;
  TicketBottomClipper({this.radius = 20.0, this.cutoutRadius = 10.0});

  @override
  Path getClip(Size size) {
    final path = Path();
    path.moveTo(0, cutoutRadius);
    
    path.arcToPoint(Offset(cutoutRadius, 0), radius: Radius.circular(cutoutRadius), clockwise: false);
    path.lineTo(size.width - cutoutRadius, 0);
    path.arcToPoint(Offset(size.width, cutoutRadius), radius: Radius.circular(cutoutRadius), clockwise: false);
    
    path.lineTo(size.width, size.height - radius);
    path.arcToPoint(Offset(size.width - radius, size.height), radius: Radius.circular(radius));
    
    path.lineTo(radius, size.height);
    path.arcToPoint(Offset(0, size.height - radius), radius: Radius.circular(radius));
    
    path.lineTo(0, cutoutRadius);
    
    return path;
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}

// 虚线绘制
class DashedLinePainter extends CustomPainter {
  final Color color;
  DashedLinePainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    var paint = Paint()
      ..color = color
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    var dashWidth = 5.0;
    var dashSpace = 4.0;
    double startX = 0;
    while (startX < size.width) {
      canvas.drawLine(Offset(startX, 0), Offset(startX + dashWidth, 0), paint);
      startX += dashWidth + dashSpace;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// 票根两侧打孔剪裁
class TicketClipper extends CustomClipper<Path> {
  final double radius;
  TicketClipper({this.radius = 20.0});

  @override
  Path getClip(Size size) {
    final path = Path();
    
    // 顶部左侧圆角
    path.moveTo(radius, 0);
    path.lineTo(size.width - radius, 0);
    // 顶部右侧圆角
    path.arcToPoint(Offset(size.width, radius), radius: Radius.circular(radius));
    
    // 计算虚线的大致Y坐标位置 (在 TextField 和 Date 之间)
    final cutoutY = 175.0; 
    final cutoutRadius = 12.0;

    // 右侧边线直到缺口
    path.lineTo(size.width, cutoutY - cutoutRadius);
    // 右侧半圆缺口
    path.arcToPoint(
      Offset(size.width, cutoutY + cutoutRadius), 
      radius: Radius.circular(cutoutRadius), 
      clockwise: false
    );
    
    // 右侧边线到底部
    path.lineTo(size.width, size.height - radius);
    // 底部右侧圆角
    path.arcToPoint(Offset(size.width - radius, size.height), radius: Radius.circular(radius));
    
    // 底部边线
    path.lineTo(radius, size.height);
    // 底部左侧圆角
    path.arcToPoint(Offset(0, size.height - radius), radius: Radius.circular(radius));
    
    // 左侧边线直到缺口
    path.lineTo(0, cutoutY + cutoutRadius);
    // 左侧半圆缺口
    path.arcToPoint(
      Offset(0, cutoutY - cutoutRadius), 
      radius: Radius.circular(cutoutRadius), 
      clockwise: false
    );
    
    // 左侧边线到顶部
    path.lineTo(0, radius);
    // 顶部左侧圆角
    path.arcToPoint(Offset(radius, 0), radius: Radius.circular(radius));
    
    return path;
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => true;
}
