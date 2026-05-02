import 'package:flutter/material.dart';

class BackgroundBlobs extends StatelessWidget {
  final bool isDark;
  final Widget child;

  const BackgroundBlobs({
    super.key,
    required this.isDark,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Fundo base
        Container(
          color: isDark ? const Color(0xFF0A0A10) : const Color(0xFFF2F2F7),
        ),

        // Blob vermelho/rosa — canto superior direito
        Positioned(
          top: -80, right: -60,
          child: Container(
            width: 260, height: 260,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color(0xFFFF2D55).withOpacity(isDark ? 0.07 : 0.10),
            ),
          ),
        ),

        // Blob azul — canto inferior esquerdo
        Positioned(
          bottom: 80, left: -80,
          child: Container(
            width: 200, height: 200,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color(0xFF007AFF).withOpacity(isDark ? 0.06 : 0.08),
            ),
          ),
        ),

        // Blob rosa claro — centro inferior
        Positioned(
          bottom: -40, right: 40,
          child: Container(
            width: 160, height: 160,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color(0xFFFF2D55).withOpacity(isDark ? 0.04 : 0.06),
            ),
          ),
        ),

        // Conteúdo por cima
        child,
      ],
    );
  }
}