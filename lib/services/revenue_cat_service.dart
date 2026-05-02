import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:flutter/foundation.dart';
import 'credits_service.dart';

class RevenueCatService {
  static const String _apiKey = "test_XXXXXXXXXXXXXXXXXXXXXXXX";

  static const String _weeklyId  = "replysnap_weekly";
  static const String _weekly2Id = "replysnap_weekly2";
  static const String _monthlyId = "replysnap_monthly";

  static Future<void> init() async {
    await Purchases.setLogLevel(LogLevel.debug);
    final config = PurchasesConfiguration(_apiKey);
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
    return await _purchase(_weeklyId);
  }

  static Future<PurchaseServiceResult> _purchase(String productId) async {
    try {
      final products = await Purchases.getProducts([productId]);

      if (products.isEmpty) {
        return PurchaseServiceResult(success: false, error: "Produto não encontrado");
      }

      // Na v9.x purchaseStoreProduct não retorna CustomerInfo diretamente
      // Fazemos a compra e depois buscamos o CustomerInfo separadamente
      await Purchases.purchaseStoreProduct(products.first);

      // Verifica o estado após compra
      final info = await Purchases.getCustomerInfo();
      final isPremium = info.entitlements.active.containsKey("premium");

      if (isPremium) {
        await CreditsService.setPremium(true);
        return PurchaseServiceResult(success: true);
      }

      return PurchaseServiceResult(success: false, error: "Compra não confirmada");

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

      return PurchaseServiceResult(success: false, error: "Nenhuma compra encontrada");
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