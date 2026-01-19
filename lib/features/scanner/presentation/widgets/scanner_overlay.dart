import 'package:flutter/material.dart';

class ScannerOverlay extends StatefulWidget {
  const ScannerOverlay({super.key});

  @override
  State<ScannerOverlay> createState() => _ScannerOverlayState();
}

class _ScannerOverlayState extends State<ScannerOverlay> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat(reverse: true);
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
        return CustomPaint(
          size: Size.infinite,
          painter: _OverlayPainter(_controller.value),
        );
      },
    );
  }
}

class _OverlayPainter extends CustomPainter {
  final double animationValue;
  _OverlayPainter(this.animationValue);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF00E676).withOpacity(0.5)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    final laserPaint = Paint()
      ..color = const Color(0xFF00E676)
      ..strokeWidth = 3.0
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5);

    // Desenha o quadrado central de foco
    double scanArea = size.width * 0.7;
    Rect rect = Rect.fromCenter(
      center: Offset(size.width / 2, size.height / 2),
      width: scanArea,
      height: scanArea,
    );

    canvas.drawRect(rect, paint);

    // Desenha a linha do laser animada
    double laserY = rect.top + (rect.height * animationValue);
    canvas.drawLine(Offset(rect.left, laserY), Offset(rect.right, laserY), laserPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}