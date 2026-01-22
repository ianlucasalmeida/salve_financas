import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _rotationAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<double> _slideAnimation;
  late Animation<double> _textFadeAnimation;

  @override
  void initState() {
    super.initState();

    // Configuração da duração total da animação
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2500),
    );

    // 1. Animação de Rotação (Gira 2 voltas completas e desacelera)
    _rotationAnimation = Tween<double>(begin: 0, end: 4 * math.pi).animate(
      CurvedAnimation(parent: _controller, curve: const Interval(0.0, 0.7, curve: Curves.easeInOutCubic)),
    );

    // 2. Animação de Escala (Cresce do zero)
    _scaleAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: const Interval(0.0, 0.5, curve: Curves.elasticOut)),
    );

    // 3. Animação de Queda (Vem de cima para o centro)
    _slideAnimation = Tween<double>(begin: -200.0, end: 0.0).animate(
      CurvedAnimation(parent: _controller, curve: const Interval(0.0, 0.7, curve: Curves.bounceOut)),
    );

    // 4. Texto aparece suavemente no final
    _textFadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: const Interval(0.6, 1.0, curve: Curves.easeIn)),
    );

    // Inicia a animação
    _controller.forward();

    // Navega para a próxima tela após terminar
    _navigateToNext();
  }

  Future<void> _navigateToNext() async {
    await Future.delayed(const Duration(seconds: 3)); // Tempo total de espera
    if (mounted) {
      // ✅ Substitua '/login' pela sua rota inicial correta (ex: '/auth' ou '/')
      context.go('/login'); 
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black, // Fundo preto profundo
      body: Center(
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            return Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // O LOGO ANIMADO
                Transform.translate(
                  offset: Offset(0, _slideAnimation.value),
                  child: Transform.rotate(
                    angle: _rotationAnimation.value,
                    child: Transform.scale(
                      scale: _scaleAnimation.value,
                      child: const FacetedTriangleLogo(size: 100),
                    ),
                  ),
                ),
                
                const SizedBox(height: 30),

                // O TEXTO "SALVE"
                Opacity(
                  opacity: _textFadeAnimation.value,
                  child: Column(
                    children: [
                      const Text(
                        "SALVE",
                        style: TextStyle(
                          fontFamily: 'monospace', // Ou sua fonte customizada
                          fontSize: 32,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 8,
                          color: Colors.white,
                        ),
                      ),
                      Text(
                        "FINANÇAS",
                        style: TextStyle(
                          fontFamily: 'monospace',
                          fontSize: 12,
                          letterSpacing: 4,
                          color: Colors.greenAccent.withOpacity(0.7),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

// ==========================================================
// DESENHO DO LOGO (Triângulo Facetado com Degradê)
// ==========================================================
class FacetedTriangleLogo extends StatelessWidget {
  final double size;

  const FacetedTriangleLogo({super.key, required this.size});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _TrianglePainter(),
      ),
    );
  }
}

class _TrianglePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // Coordenadas dos pontos do triângulo equilátero
    final top = Offset(w / 2, 0);
    final bottomLeft = Offset(0, h);
    final bottomRight = Offset(w, h);
    final center = Offset(w / 2, h * 0.65); // Ponto central para criar as facetas

    // Tinta para a faceta ESQUERDA (Verde mais escuro/azulado)
    final leftPath = Path()
      ..moveTo(top.dx, top.dy)
      ..lineTo(bottomLeft.dx, bottomLeft.dy)
      ..lineTo(center.dx, center.dy)
      ..close();

    final leftPaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFF004D40), Color(0xFF009688)], // Verde petróleo escuro
      ).createShader(Rect.fromLTWH(0, 0, w, h));

    // Tinta para a faceta DIREITA (Verde Vibrante / Neon)
    final rightPath = Path()
      ..moveTo(top.dx, top.dy)
      ..lineTo(bottomRight.dx, bottomRight.dy)
      ..lineTo(center.dx, center.dy)
      ..close();

    final rightPaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topRight,
        end: Alignment.bottomLeft,
        colors: [Colors.greenAccent, Color(0xFF69F0AE)], // Verde neon brilhante
      ).createShader(Rect.fromLTWH(0, 0, w, h));

    // Tinta para a faceta BASE (Opcional, dá profundidade)
    final bottomPath = Path()
      ..moveTo(bottomLeft.dx, bottomLeft.dy)
      ..lineTo(bottomRight.dx, bottomRight.dy)
      ..lineTo(center.dx, center.dy)
      ..close();

    final bottomPaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.bottomCenter,
        end: Alignment.topCenter,
        colors: [Color(0xFF00695C), Color(0xFF004D40)], // Sombra na base
      ).createShader(Rect.fromLTWH(0, 0, w, h));

    // Desenhar as facetas
    canvas.drawPath(leftPath, leftPaint);
    canvas.drawPath(rightPath, rightPaint);
    canvas.drawPath(bottomPath, bottomPaint); // Comente essa linha se quiser um triângulo plano embaixo
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}