import 'package:flutter/material.dart';
import 'revenue_cat_service.dart';
import '../widgets/paywall_screen.dart';

/// Verifica a assinatura e apresenta o paywall quando necessário.
/// Por padrão, fechar o paywall também volta ao ecrã anterior.
class ResponsePaywallGate {
  static Future<bool> allow(
    BuildContext context, {
    bool returnOnDismiss = true,
  }) async {
    final premium = await RevenueCatService.isPremium();
    if (!context.mounted) return false;
    if (premium) return true;

    final purchased = await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(
        fullscreenDialog: true,
        builder: (_) => const PaywallFlow(),
      ),
    );
    if (!context.mounted) return false;
    if (purchased == true) return true;

    if (returnOnDismiss) {
      final navigator = Navigator.of(context);
      if (navigator.canPop()) {
        navigator.pop();
      }
    }
    return false;
  }
}
