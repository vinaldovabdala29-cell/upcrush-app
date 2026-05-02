import 'package:flutter/material.dart';

class FeatureCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final List<Color> iconBgColors;
  final Color iconShadowColor;
  final bool isDarkMode;
  final VoidCallback onTap;

  const FeatureCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.iconBgColors,
    required this.iconShadowColor,
    required this.isDarkMode,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 26),
        decoration: BoxDecoration(
          color: isDarkMode
              ? Colors.white.withOpacity(0.06)
              : Colors.white.withOpacity(0.75),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: isDarkMode
                ? Colors.white.withOpacity(0.07)
                : Colors.white.withOpacity(0.9),
          ),
          boxShadow: isDarkMode
              ? []
              : [
                  BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 16, offset: const Offset(0, 4)),
                  BoxShadow(color: Colors.white.withOpacity(0.8), blurRadius: 0, offset: const Offset(0, 1)),
                ],
        ),
        child: Row(
          children: [
            // Ícone grande como o Plug AI
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: iconBgColors,
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: iconShadowColor.withOpacity(0.4),
                    blurRadius: 14,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Icon(icon, color: Colors.white, size: 30),
            ),

            const SizedBox(width: 20),

            // Texto
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: isDarkMode ? Colors.white : const Color(0xFF1C1C1E),
                      letterSpacing: -0.3,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 13,
                      color: isDarkMode
                          ? Colors.white.withOpacity(0.4)
                          : Colors.black.withOpacity(0.4),
                      fontWeight: FontWeight.w400,
                      height: 1.3,
                    ),
                  ),
                ],
              ),
            ),

            // Seta
            Icon(
              Icons.arrow_forward_ios_rounded,
              size: 16,
              color: isDarkMode
                  ? Colors.white.withOpacity(0.2)
                  : Colors.black.withOpacity(0.18),
            ),
          ],
        ),
      ),
    );
  }
}