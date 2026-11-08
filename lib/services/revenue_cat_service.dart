import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:flutter/foundation.dart';
import 'dart:io';
import 'credits_service.dart';

class RevenueCatService {
  // ============================================================
  // BYPASS TEMPORÁRIO PARA TESTES
  // true  = Premium desbloqueado sem compra
  // false = RevenueCat / App Store funcionam normalmente
  // IMPORTANTE: colocar false antes de publicar na App Store.
  // ============================================================
  static const bool testPremiumBypass = false;

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

  // Novo plano principal do paywall antigo:
  // assinatura semanal com 3 dias grátis configurados no App Store Connect.
  static const String _weeklyTrial3ProductId =
      'upcrush_premium_weekly_trial3';

  /// Procura especificamente o package que contém o produto
  /// upcrush_premium_weekly_trial3 dentro do offering "default".
  ///
  /// Fazemos a busca pelo Product ID da App Store em vez de depender
  /// do identifier do package do RevenueCat. Assim o código continua
  /// funcionando mesmo sendo um package Custom.
  static Future<Package?> _getWeeklyTrial3Package() async {
    try {
      final offerings = await Purchases.getOfferings();
      final offering = offerings.all[_newOfferingId] ?? offerings.current;

      if (offering == null) {
        debugPrint('RevenueCat: offering "$_newOfferingId" não encontrado.');
        return null;
      }

      for (final package in offering.availablePackages) {
        if (package.storeProduct.identifier == _weeklyTrial3ProductId) {
          return package;
        }
      }

      debugPrint(
        'RevenueCat: produto $_weeklyTrial3ProductId não encontrado '
        'no offering "$_newOfferingId".',
      );
      return null;
    } catch (e) {
      debugPrint('RevenueCat: erro ao buscar weekly trial3: $e');
      return null;
    }
  }

  static Future<void> init() async {
    await Purchases.setLogLevel(LogLevel.debug);
    final key = Platform.isIOS ? _iosKey : _androidKey;
    final config = PurchasesConfiguration(key);
    await Purchases.configure(config);
    await _syncPremiumStatus();
  }

  static Future<void> _syncPremiumStatus() async {
    if (testPremiumBypass) {
      await CreditsService.setPremium(true);
      debugPrint("RevenueCat: TEST BYPASS ativo — Premium desbloqueado.");
      return;
    }

    try {
      final info = await Purchases.getCustomerInfo();
      final isPremium = info.entitlements.active.containsKey("premium");
      await CreditsService.setPremium(isPremium);
    } catch (e) {
      debugPrint("RevenueCat sync error: $e");
    }
  }

  static Future<bool> isPremium() async {
    if (testPremiumBypass) {
      await CreditsService.setPremium(true);
      return true;
    }

    try {
      final info = await Purchases.getCustomerInfo();
      return info.entitlements.active.containsKey("premium");
    } catch (e) {
      return false;
    }
  }

  // Retorna o preço real do NOVO plano semanal Trial3 na moeda local
  // do utilizador. O paywall antigo continua chamando getPrice(),
  // mas agora recebe o preço de upcrush_premium_weekly_trial3.
  static Future<String> getPrice() async {
    try {
      final package = await _getWeeklyTrial3Package();
      return package?.storeProduct.priceString ?? '';
    } catch (e) {
      debugPrint('RevenueCat getPrice trial3 error: $e');
      return '';
    }
  }

  // ============================================================
  // ELEGIBILIDADE PARA O TRIAL DE 7 DIAS (added)
  // ============================================================
  //
  // A Apple só permite usar o Free Trial de 3 dias UMA VEZ por
  // utilizador/produto. Se ele já usou antes (ex: cancelou e está
  // a voltar), a compra será cobrada diretamente, sem trial.
  //
  // Esta função determina isso ANTES da compra, para mostrarmos o
  // texto certo no paywall ("3 dias grátis..." vs "Billed 6,99€...").
  //
  // iOS: usa checkTrialOrIntroductoryPriceEligibility (API oficial
  // da RevenueCat para isto).
  // Android: essa API não existe — usamos o fallback recomendado
  // pela própria RevenueCat: se o utilizador já teve QUALQUER
  // entitlement antes (mesmo expirado), assumimos que já não é
  // elegível para trial.
  //
  // Em caso de status "unknown" (comum em sandbox/primeira instalação
  // sem recibo ainda), assumimos elegível — mostrar a oferta de trial
  // é o comportamento mais seguro; a App Store aplica a regra real
  // no momento da compra de qualquer forma.
  // ============================================================

  static Future<bool> isEligibleForTrial() async {
    if (testPremiumBypass) return true;

    try {
      if (Platform.isIOS) {
        final eligibilityMap =
            await Purchases.checkTrialOrIntroductoryPriceEligibility(
          [_weeklyTrial3ProductId],
        );

        final eligibility = eligibilityMap[_weeklyTrial3ProductId];

        if (eligibility == null) return true;

        switch (eligibility.status) {
          case IntroEligibilityStatus.introEligibilityStatusIneligible:
            return false;
          case IntroEligibilityStatus.introEligibilityStatusEligible:
          case IntroEligibilityStatus.introEligibilityStatusNoIntroOfferExists:
          case IntroEligibilityStatus.introEligibilityStatusUnknown:
            return true;
        }
      } else {
        // Android: sem API dedicada. Fallback recomendado pela
        // RevenueCat — se já teve algum entitlement (mesmo expirado),
        // já não é elegível para um novo trial.
        final info = await Purchases.getCustomerInfo();
        return info.entitlements.all.isEmpty;
      }
    } catch (e) {
      debugPrint('RevenueCat: erro ao checar elegibilidade de trial: $e');
      // Em caso de erro, assume elegível — comportamento mais seguro
      // (a App Store valida a regra real na hora da compra).
      return true;
    }
  }

  static Future<PurchaseServiceResult> buyWeekly() async {
    try {
      final package = await _getWeeklyTrial3Package();

      if (package == null) {
        return const PurchaseServiceResult(
          success: false,
          error:
              'Plano semanal com 3 dias grátis não encontrado no RevenueCat.',
        );
      }

      await Purchases.purchasePackage(package);

      final info = await Purchases.getCustomerInfo();
      final isPremium = info.entitlements.active.containsKey('premium');

      if (isPremium) {
        await CreditsService.setPremium(true);
        return const PurchaseServiceResult(success: true);
      }

      return const PurchaseServiceResult(
        success: false,
        error: 'Compra não confirmada',
      );
    } catch (e) {
      final err = e.toString().toLowerCase();
      if (err.contains('cancel') || err.contains('1')) {
        return const PurchaseServiceResult(
          success: false,
          cancelled: true,
        );
      }
      return PurchaseServiceResult(
        success: false,
        error: e.toString(),
      );
    }
  }

  static Future<PurchaseServiceResult> restorePurchases() async {
    if (testPremiumBypass) {
      await CreditsService.setPremium(true);
      return const PurchaseServiceResult(success: true, restored: true);
    }

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
  static Future<PurchaseServiceResult> buyNewPlan(String planKey) async {
    if (testPremiumBypass) {
      await CreditsService.setPremium(true);
      debugPrint(
        "RevenueCat: TEST BYPASS — plano $planKey liberado sem cobrança.",
      );
      return const PurchaseServiceResult(success: true);
    }

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