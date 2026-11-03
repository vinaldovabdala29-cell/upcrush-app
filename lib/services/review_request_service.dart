import 'package:flutter/foundation.dart';
import 'package:in_app_review/in_app_review.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Solicita a avaliação nativa sem interromper a geração ou a compra.
class ReviewRequestService {
  static const _launchKey = 'upcrush_review_launch_requested_v2';
  static const _secondKey = 'upcrush_review_second_message_requested_v2';
  static const _countKey = 'upcrush_review_generated_messages_v2';
  static bool _busy = false;

  /// Uma única solicitação na abertura do app (após renderizar a Home).
  static Future<void> onAppOpened() async {
    final prefs = await SharedPreferences.getInstance();
    if (prefs.getBool(_launchKey) ?? false) return;
    await prefs.setBool(_launchKey, true);
    await _requestReview();
  }

  /// Contabiliza mensagens efetivamente exibidas, não pré-geradas ou copiadas.
  /// O pedido ocorre na segunda mensagem gerada, uma única vez por instalação.
  static Future<void> onMessageDisplayed() async {
    final prefs = await SharedPreferences.getInstance();
    final count = (prefs.getInt(_countKey) ?? 0) + 1;
    await prefs.setInt(_countKey, count);
    if (count < 2 || (prefs.getBool(_secondKey) ?? false)) return;
    await prefs.setBool(_secondKey, true);
    await _requestReview();
  }

  static Future<void> _requestReview() async {
    if (_busy) return;
    _busy = true;
    try {
      if (kIsWeb) return;
      final review = InAppReview.instance;
      if (await review.isAvailable()) await review.requestReview();
    } catch (_) {
      // O sistema pode não apresentar a janela; nunca bloquear o app.
    } finally {
      _busy = false;
    }
  }
}
