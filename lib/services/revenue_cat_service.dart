import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:flutter/foundation.dart';
import 'dart:io';
import 'credits_service.dart';

class RevenueCatService {
  // Android key — começa com "goog_"
  static const String _androidKey = "goog_FEoxrNpkLgRjsZTtNJZEYuVDqua";
  // iOS key — começa com "appl_"
  static const String _iosKey = "appl_dmwoiqiILydfkRwbGekYzLFWRRb";

  static Future<void> init() async {
    await Purchases.setLogLevel(LogLevel.debug);
    final key = Platform.isIOS ? _iosKey : _androidKey;
    final config = PurchasesConfiguration(key);
    await Purchases.configure(config);
    await _syncPremiumStatus();
  }

  static Future<void> _syncPremiumStatus() async {
    try {
      final info = await Purchases.getCustomerInfo();
      final isPremium = info.entitlements.active.containsKey("premium");
      await CreditsService.setPremium(isPremium);
    } catch (e) {
      debugPrint("RevenueCat sync error: $e");
    }
  }

  static Future<bool> isPremium() async {
    try {
      final info = await Purchases.getCustomerInfo();
      return info.entitlements.active.containsKey("premium");
    } catch (e) {
      return false;
    }
  }

  static Future<PurchaseServiceResult> buyWeekly() async {
    try {
      // Usa Offerings em vez de getProducts — funciona melhor no Android
      final offerings = await Purchases.getOfferings();
      final package = offerings.current?.weekly ??
          offerings.current?.availablePackages.firstOrNull;

      if (package == null) {
        return PurchaseServiceResult(
            success: false, error: "Produto não encontrado");
      }

      await Purchases.purchasePackage(package);

      final info = await Purchases.getCustomerInfo();
      final isPremium = info.entitlements.active.containsKey("premium");

      if (isPremium) {
        await CreditsService.setPremium(true);
        return PurchaseServiceResult(success: true);
      }

      return PurchaseServiceResult(
          success: false, error: "Compra não confirmada");

    } catch (e) {
      final err = e.toString().toLowerCase();
      if (err.contains("cancel") || err.contains("1")) {
        return PurchaseServiceResult(success: false, cancelled: true);
      }
      return PurchaseServiceResult(success: false, error: e.toString());
    }
  }

  static Future<PurchaseServiceResult> restorePurchases() async {
    try {
      final info = await Purchases.restorePurchases();
      final isPremium = info.entitlements.active.containsKey("premium");

      if (isPremium) {
        await CreditsService.setPremium(true);
        return PurchaseServiceResult(success: true, restored: true);
      }

      return PurchaseServiceResult(
          success: false, error: "Nenhuma compra encontrada");
    } catch (e) {
      return PurchaseServiceResult(success: false, error: e.toString());
    }
  }
}

class PurchaseServiceResult {
  final bool success;
  final bool cancelled;
  final bool restored;
  final String? error;

  const PurchaseServiceResult({
    required this.success,
    this.cancelled = false,
    this.restored = false,
    this.error,
  });
}