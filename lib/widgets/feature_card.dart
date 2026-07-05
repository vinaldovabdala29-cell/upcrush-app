import 'package:flutter/material.dart';

class FeatureCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final IconData icon;
  final List<Color> iconBgColors;
  final Color iconShadowColor;
  final bool isDarkMode;
  final Color? subtitleColor;

  const FeatureCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.onTap,
    required this.icon,
    required this.iconBgColors,
    required this.iconShadowColor,
    required this.isDarkMode,
    this.subtitleColor,
  });

  @override
  Widget build(BuildContext context) {
    final cardBg = isDarkMode
        ? Colors.white.withOpacity(0.06)
        : Colors.white.withOpacity(0.9);
    final titleColor = isDarkMode ? Colors.white : const Color(0xFF1C1C1E);
    final subColor = subtitleColor
        ?? (isDarkMode ? Colors.white.withOpacity(0.85) : const Color(0xFF333333));

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 22),
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: isDarkMode
                ? Colors.white.withOpacity(0.08)
                : Colors.black.withOpacity(0.06)),
          boxShadow: isDarkMode ? [] : [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10, offset: const Offset(0, 3)),
          ]),
        child: Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
          // Icon
          Container(
            width: 52, height: 52,
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: iconBgColors),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [BoxShadow(
                color: iconShadowColor.withOpacity(0.35),
                blurRadius: 10, offset: const Offset(0, 4))]),
            child: Icon(icon, color: Colors.white, size: 26)),
          const SizedBox(width: 16),
          // Texts
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                  style: TextStyle(
                    color: titleColor,
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.3)),
                const SizedBox(height: 4),
                Text(subtitle,
                  style: TextStyle(
                    color: subColor,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    height: 1.35)),
              ])),
          const SizedBox(width: 8),
          Icon(Icons.arrow_forward_ios_rounded,
            color: isDarkMode ? Colors.white24 : Colors.black26,
            size: 14),
        ]),
      ),
    );
  }
}