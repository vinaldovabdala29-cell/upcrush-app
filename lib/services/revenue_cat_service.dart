import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:flutter/foundation.dart';
import 'dart:io';
import 'credits_service.dart';

class RevenueCatService {
  static const String _androidKey = "goog_FEoxrNpkLgRjsZTtNJZEYuVDqua";
  static const String _iosKey = "appl_dmwoiqiILydfkRwbGekYzLFWRRb";

  // ============================================================
  // NOVO OFFERING (added) — identifier configurado no RevenueCat
  // para o novo paywall (planos Annual + Weekly sem trial).
  //
  // Novo paywall usa o Offering "default", que agora contém
  // os packages $rc_weekly e $rc_annual associados aos produtos
  // novos _v2 configurados no App Store Connect / RevenueCat.
  // ============================================================
  static const String _newOfferingId = 'default';

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

  // Retorna o preco real do produto na moeda local do utilizador
  // (mantido exatamente como estava — continua a usar o offering
  // "current", que e o antigo com upcrush_premium_weekly).
  static Future<String> getPrice() async {
    try {
      final offerings = await Purchases.getOfferings();
      final package = offerings.current?.weekly ??
          offerings.current?.availablePackages.firstOrNull;
      // Retorna string vazia se nao encontrar — UI mostra loading
      return package?.storeProduct.priceString ?? '';
    } catch (e) {
      return '';
    }
  }

  static Future<PurchaseServiceResult> buyWeekly() async {
    try {
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

  // ============================================================
  // NOVO OFFERING — FUNÇÕES ADICIONADAS (added)
  // ============================================================
  //
  // Tudo o que vem a seguir usa explicitamente o Offering "default".
  // Esse offering contém os novos packages Weekly e Annual.
  // As funções antigas buyWeekly() e getPrice() continuam preservadas
  // para compatibilidade com qualquer fluxo legado do app.
  // ============================================================

  /// Busca o novo Offering pelo identifier configurado.
  /// Devolve null se ainda nao existir/nao estiver acessivel
  /// (ex: por causa do "Missing Metadata" no App Store Connect).
  static Future<Offering?> _getNewOffering() async {
    try {
      final offerings = await Purchases.getOfferings();
      return offerings.all[_newOfferingId];
    } catch (e) {
      debugPrint("RevenueCat: erro ao buscar novo offering: $e");
      return null;
    }
  }

  /// Devolve o package do plano ANUAL do novo offering
  /// (upcrush_premium_yearly_trial_v2, com trial).
  static Future<Package?> _getAnnualPackage() async {
    final offering = await _getNewOffering();
    return offering?.annual;
  }

  /// Devolve o package do plano SEMANAL sem trial do novo offering
  /// (UpCrush_Premium_Weekly_No_Trial_v2).
  static Future<Package?> _getWeeklyNoTrialPackage() async {
    final offering = await _getNewOffering();
    return offering?.weekly;
  }

  /// Preco formatado (na moeda local) do plano anual do novo offering.
  /// Nao interfere com getPrice() — usa o novo offering especificamente.
  static Future<String> getAnnualPrice() async {
    try {
      final package = await _getAnnualPackage();
      return package?.storeProduct.priceString ?? '';
    } catch (e) {
      return '';
    }
  }

  /// Preco formatado (na moeda local) do plano semanal sem trial
  /// do novo offering.
  static Future<String> getWeeklyNoTrialPrice() async {
    try {
      final package = await _getWeeklyNoTrialPackage();
      return package?.storeProduct.priceString ?? '';
    } catch (e) {
      return '';
    }
  }

  /// Compra o plano ANUAL (upcrush_premium_yearly_trial_v2, com trial).
  static Future<PurchaseServiceResult> buyAnnual() async {
    try {
      final package = await _getAnnualPackage();

      if (package == null) {
        return PurchaseServiceResult(
            success: false,
            error: "Plano anual não encontrado. Verifica a configuração no RevenueCat.");
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

  /// Compra o plano SEMANAL sem trial
  /// (UpCrush_Premium_Weekly_No_Trial_v2).
  static Future<PurchaseServiceResult> buyWeeklyNoTrial() async {
    try {
      final package = await _getWeeklyNoTrialPackage();

      if (package == null) {
        return PurchaseServiceResult(
            success: false,
            error: "Plano semanal não encontrado. Verifica a configuração no RevenueCat.");
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

  /// Compra o package de acordo com o plano escolhido no novo
  /// paywall ('annual' ou 'weekly'). Função de conveniência para
  /// o paywall_screen.dart não precisar de decidir qual método
  /// chamar diretamente.
  static Future<PurchaseServiceResult> buyNewPlan(String planKey) {
    if (planKey == 'annual') {
      return buyAnnual();
    }
    return buyWeeklyNoTrial();
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