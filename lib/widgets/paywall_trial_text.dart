// lib/widgets/paywall_trial_text.dart
import 'package:flutter/material.dart';
import '../services/credits_service.dart';
import '../theme/paywall_strings.dart';

class PaywallTrialText extends StatelessWidget {
  final String price;
  final String lang;
  final bool isTablet;

  const PaywallTrialText({
    super.key,
    required this.price,
    required this.lang,
    required this.isTablet,
  });

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
      future: CreditsService.isPremium(),
      builder: (_, snap) {
        if (snap.data == true) return const SizedBox.shrink();
        // Substitui placeholder pelo preco real do RevenueCat
        // Remove qualquer preco hardcoded e substitui pelo preco real
        var text = PS.get('trial_sub', lang);
        // Substitui padroes de preco (ex: €5,99 / €6,99 / $5.99)
        text = text.replaceAllMapped(
          RegExp(r'[\$€£¥₩]?\s?\d+[.,]\d{2}'),
          (_) => price);
        return Text(text,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Colors.black54,
            fontSize: isTablet ? 15 : 13,
            fontWeight: FontWeight.w500,
            height: 1.5));
      });
  }
}