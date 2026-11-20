import 'package:flutter/material.dart';
import 'revenue_cat_service.dart';
import '../widgets/paywall_screen.dart';

/// Permite a ação apenas a assinantes ativos ou após compra no paywall.
class ResponsePaywallGate {
  static Future<bool> allow(BuildContext context, {bool returnOnDismiss = true}) async {
    if (await RevenueCatService.isPremium()) return true;
    if (!context.mounted) return false;
    final result = await Navigator.of(context).push<bool>(
      MaterialPageRoute(fullscreenDialog: true, builder: (_) => const PaywallFlow()),
    );
    if (result != true) return false;
    return RevenueCatService.isPremium();
  }
}
