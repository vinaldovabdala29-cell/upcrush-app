// lib/widgets/paywall_features.dart
import 'package:flutter/material.dart';
import '../theme/paywall_strings.dart';

class PaywallFeatures extends StatelessWidget {
  final String lang;
  final bool isTablet;

  const PaywallFeatures({
    super.key,
    required this.lang,
    required this.isTablet,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(
        horizontal: isTablet ? 28 : 20,
        vertical: isTablet ? 20 : 14),
      decoration: BoxDecoration(
        color: const Color(0xFFF8F8F8),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.black.withOpacity(0.06))),
      child: Column(children: [
        _feat("📸", PS.get('feat1', lang), isTablet),
        _feat("❤️", PS.get('feat2', lang), isTablet),
        _feat("🤖", PS.get('feat3', lang), isTablet),
        _feat("⚡", PS.get('feat4', lang), isTablet),
      ]));
  }

  Widget _feat(String emoji, String label, bool isTablet) => Padding(
    padding: EdgeInsets.symmetric(vertical: isTablet ? 8 : 5),
    child: Row(children: [
      Text(emoji, style: TextStyle(fontSize: isTablet ? 22 : 17)),
      SizedBox(width: isTablet ? 16 : 12),
      Text(label, style: TextStyle(
        color: const Color(0xFF1C1C1E),
        fontSize: isTablet ? 16 : 14,
        fontWeight: FontWeight.w500)),
      const Spacer(),
      Icon(Icons.check_circle_rounded,
        color: const Color(0xFF34C759),
        size: isTablet ? 22 : 17),
    ]));
}