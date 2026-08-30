import 'package:amplitude_flutter/amplitude.dart';
import 'package:amplitude_flutter/configuration.dart';
import 'package:amplitude_flutter/events/base_event.dart';

// ============================================================
// AnalyticsService (novo ficheiro)
// ============================================================
//
// Centraliza todos os eventos enviados ao Amplitude, para
// perceber comportamento dos utilizadores: onde desistem no
// onboarding, que funcionalidades usam mais, e o que leva à
// conversão para pagante.
//
// IMPORTANTE: troca 'YOUR_AMPLITUDE_API_KEY' pela tua API Key
// real, copiada de Settings -> Projects no painel do Amplitude.
// ============================================================

class AnalyticsService {
  static const String _apiKey = 'f01e037509c3d8eaa26551e01def556e';

  static late final Amplitude _amplitude;
  static bool _initialized = false;

  static Future<void> init() async {
    if (_initialized) return;

    _amplitude = Amplitude(
      Configuration(
        apiKey: _apiKey,
      ),
    );

    await _amplitude.isBuilt;
    _initialized = true;
  }

  /// Regista um evento simples, sem propriedades extra.
  static void track(String eventName) {
    if (!_initialized) return;
    _amplitude.track(BaseEvent(eventName));
  }

  /// Regista um evento com propriedades adicionais
  /// (ex: {'plan': 'weekly', 'price': '6.99'}).
  static void trackWithProperties(
    String eventName,
    Map<String, dynamic> properties,
  ) {
    if (!_initialized) return;
    _amplitude.track(
      BaseEvent(eventName, eventProperties: properties),
    );
  }

  /// Identifica o utilizador (ex: depois de saberes que é premium).
  /// Útil para depois filtrar/segmentar por este atributo no painel.
  static void setUserProperty(String key, dynamic value) {
    if (!_initialized) return;
    _amplitude.identify(
      Identify()..set(key, value),
    );
  }

  // ============================================================
  // EVENTOS PRÉ-DEFINIDOS — usa estes em vez de strings soltas
  // pela app, para manter consistência de nomes.
  // ============================================================

  static void onboardingStarted() => track('onboarding_started');

  static void onboardingPageViewed(int pageIndex) =>
      trackWithProperties('onboarding_page_viewed', {'page_index': pageIndex});

  static void onboardingCompleted() => track('onboarding_completed');

  static void paywallViewed() => track('paywall_viewed');

  static void trialStarted(String plan) =>
      trackWithProperties('trial_started', {'plan': plan});

  static void purchaseCompleted(String plan, String price) =>
      trackWithProperties('purchase_completed', {
        'plan': plan,
        'price': price,
      });

  static void purchaseFailed(String plan, String? error) =>
      trackWithProperties('purchase_failed', {
        'plan': plan,
        'error': error ?? 'unknown',
      });

  static void featureUsed(String featureName) =>
      trackWithProperties('feature_used', {'feature': featureName});

  static void responseCopied(String featureName) =>
      trackWithProperties('response_copied', {'feature': featureName});
}