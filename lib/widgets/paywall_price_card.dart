// lib/widgets/paywall_price_card.dart
import 'package:flutter/material.dart';
import '../services/credits_service.dart';
import '../theme/paywall_strings.dart';

class PaywallPriceCard extends StatelessWidget {
  final String price;
  final String lang;
  final bool isTablet;

  const PaywallPriceCard({
    super.key,
    required this.price,
    required this.lang,
    required this.isTablet,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(isTablet ? 28 : 22),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFFF2D55), Color(0xFFFF6B81)],
          begin: Alignment.topLeft, end: Alignment.bottomRight),
        borderRadius: BorderRadius.circular(22),
        boxShadow: [BoxShadow(
          color: const Color(0xFFFF2D55).withOpacity(0.35),
          blurRadius: 20, offset: const Offset(0, 8))]),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Lado esquerdo
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            // Badge 3 dias grátis — some após pagamento
            FutureBuilder<bool>(
              future: CreditsService.isPremium(),
              builder: (_, snap) {
                if (snap.data == true) return const SizedBox.shrink();
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.25),
                        borderRadius: BorderRadius.circular(8)),
                      child: Text(PS.get('free_days', lang), style: TextStyle(
                        color: Colors.white,
                        fontSize: isTablet ? 13 : 11,
                        fontWeight: FontWeight.w800, letterSpacing: 0.8))),
                    SizedBox(height: isTablet ? 14 : 10),
                  ]);
              }),
            Text(PS.get('weekly', lang), style: TextStyle(
              color: Colors.white70,
              fontSize: isTablet ? 16 : 14,
              fontWeight: FontWeight.w500)),
            Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
              Text(price, style: TextStyle(
                color: Colors.white,
                fontSize: isTablet ? 52 : 40,
                fontWeight: FontWeight.w900, letterSpacing: -1)),
              Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Text(PS.get('per_week', lang), style: TextStyle(
                  color: Colors.white60,
                  fontSize: isTablet ? 16 : 14))),
            ]),
          ]),
          const Spacer(),
          // Lado direito
          Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
            Text(PS.get('today', lang), style: TextStyle(
              color: Colors.white.withOpacity(0.6),
              fontSize: isTablet ? 14 : 12)),
            const Text("0.00", style: TextStyle(
              color: Colors.white, fontSize: 22,
              fontWeight: FontWeight.w800)),
            SizedBox(height: isTablet ? 12 : 8),
            Text(PS.get('after_trial', lang), style: TextStyle(
              color: Colors.white.withOpacity(0.6),
              fontSize: isTablet ? 14 : 12)),
            Text("$price${PS.get('per_week', lang)}", style: TextStyle(
              color: Colors.white,
              fontSize: isTablet ? 16 : 14,
              fontWeight: FontWeight.w700)),
          ]),
        ]));
  }
}