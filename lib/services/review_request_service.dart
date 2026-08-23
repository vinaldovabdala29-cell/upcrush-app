import 'package:in_app_review/in_app_review.dart';
import 'package:shared_preferences/shared_preferences.dart';

// ============================================================
// ReviewRequestService (novo ficheiro)
// ============================================================
//
// Centraliza a lógica de "quando pedir avaliação" fora do
// onboarding, para os 4 pontos de sucesso da app (Screenshot,
// Opener, Pick Lines, Coach) usarem a MESMA fonte de verdade e
// nunca pedirem duplicado.
//
// Usa 2 flags em SharedPreferences:
// - 'review_requested_first_success': dispara UMA vez, na
//   primeira "vitória" real do utilizador em qualquer
//   funcionalidade (copiar uma resposta, ou receber a primeira
//   resposta da Dolla no Coach).
// - 'review_requested_engaged_user': dispara UMA vez, depois de
//   um número mínimo de sucessos acumulados no total (utilizador
//   engajado a sério).
// ============================================================

class ReviewRequestService {
  static const String _keyFirstSuccess = 'review_requested_first_success';
  static const String _keyEngagedUser = 'review_requested_engaged_user';
  static const String _keySuccessCount = 'review_success_count';

  // Quantos sucessos totais (soma de todas as funcionalidades)
  // são precisos para disparar o pedido de "utilizador engajado".
  static const int _engagedThreshold = 10;

  /// Chama isto sempre que o utilizador tiver uma "vitória" real:
  /// copiar uma resposta gerada, ou receber a primeira resposta
  /// completa da Dolla no Coach.
  ///
  /// Trata sozinho de:
  /// 1. Incrementar o contador de sucessos.
  /// 2. Disparar o pedido de avaliação "primeira vitória" (só 1x).
  /// 3. Disparar o pedido de avaliação "utilizador engajado" depois
  ///    de _engagedThreshold sucessos (só 1x).
  static Future<void> notifySuccess() async {
    final prefs = await SharedPreferences.getInstance();

    final currentCount = (prefs.getInt(_keySuccessCount) ?? 0) + 1;
    await prefs.setInt(_keySuccessCount, currentCount);

    final firstSuccessDone = prefs.getBool(_keyFirstSuccess) ?? false;
    if (!firstSuccessDone) {
      await prefs.setBool(_keyFirstSuccess, true);
      await _requestReview();
      return; // não dispara os dois pedidos na mesma ação
    }

    final engagedDone = prefs.getBool(_keyEngagedUser) ?? false;
    if (!engagedDone && currentCount >= _engagedThreshold) {
      await prefs.setBool(_keyEngagedUser, true);
      await _requestReview();
    }
  }

  static Future<void> _requestReview() async {
    try {
      final inAppReview = InAppReview.instance;
      if (await inAppReview.isAvailable()) {
        await inAppReview.requestReview();
      }
    } catch (_) {
      // Falha silenciosa — nunca deve afetar a experiência do utilizador.
    }
  }
}