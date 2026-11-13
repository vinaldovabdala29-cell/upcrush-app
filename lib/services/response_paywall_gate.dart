import 'package:flutter/material.dart';
import '../services/revenue_cat_service.dart';
import '../widgets/paywall_screen.dart';

/// Confirma o entitlement na RevenueCat; nunca confia num flag local.
class ResponsePaywallGate {
  static Future<bool> allow(BuildContext context, {bool returnOnDismiss = true}) async {
    if (await RevenueCatService.isPremium()) return true;
    if (!context.mounted) return false;
    final unlocked = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (_) => const PaywallFlow(),
      ),
    );
    return unlocked == true && await RevenueCatService.isPremium();
  }
}
