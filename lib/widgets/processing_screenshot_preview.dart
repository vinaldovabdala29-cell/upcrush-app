import 'dart:io';
import 'package:flutter/material.dart';

/// Preview exclusivo da etapa de processamento: mostra a imagem completa.
/// O scanner percorre apenas a moldura, sem recortar o screenshot.
class ProcessingScreenshotPreview extends StatelessWidget {
  final File image;
  final Animation<double> scanAnimation;
  final bool dark;

  const ProcessingScreenshotPreview({
    super.key,
    required this.image,
    required this.scanAnimation,
    required this.dark,
  });

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.sizeOf(context);
    final availableHeight = screenSize.height;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Container(
        constraints: BoxConstraints(maxHeight: availableHeight * 0.48),
        width: screenSize.width * 0.58,
        decoration: BoxDecoration(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(24),

        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          alignment: Alignment.center,
          children: [
            Image.file(
              image,
              fit: BoxFit.contain,
              width: screenSize.width * 0.58,
            ),
            Positioned.fill(
              child: IgnorePointer(
                child: AnimatedBuilder(
                  animation: scanAnimation,
                  builder: (context, _) => Align(
                    alignment: Alignment(0, -1 + 2 * scanAnimation.value),
                    child: Container(
                      height: 3,
                      decoration: BoxDecoration(
                        color: const Color(0xFF44B5FF),
                        boxShadow: [BoxShadow(
                          color: const Color(0xFF1677F2).withOpacity(0.85),
                          blurRadius: 14,
                          spreadRadius: 3,
                        )],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
