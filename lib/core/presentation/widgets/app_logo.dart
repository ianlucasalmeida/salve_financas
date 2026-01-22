import 'package:flutter/material.dart';

class AppLogo extends StatelessWidget {
  final double size;
  final bool useHero; // Para animações suaves entre telas

  const AppLogo({
    super.key, 
    this.size = 120, 
    this.useHero = false
  });

  @override
  Widget build(BuildContext context) {
    // O Hero permite que o logo "flutue" da Splash para o Login suavemente
    Widget logoImage = Image.asset(
      'assets/images/salve_logo2.png',
      height: size,
      width: size,
      fit: BoxFit.contain,
      // Fallback seguro: se a imagem falhar, mostra um ícone
      errorBuilder: (context, error, stackTrace) {
        return Icon(
          Icons.account_balance_wallet, // Ícone padrão do app
          size: size,
          color: Colors.greenAccent,
        );
      },
    );

    if (useHero) {
      return Hero(
        tag: 'app_logo_hero',
        child: logoImage,
      );
    }

    return logoImage;
  }
}