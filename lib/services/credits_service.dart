import 'package:shared_preferences/shared_preferences.dart';

class CreditsService {
  static const String _keyIsPremium = 'is_premium';
  static const String _keyChatUses = 'chat_uses_used';
  static const int _freeChatMessages = 3;

  static Future<void> init() async {}

  // SCREENSHOT e OPENER — abre galeria primeiro, paywall depois
  static Future<bool> canUseScanner() async {
    return true; // galeria sempre abre
  }

  static Future<bool> shouldShowPaywallAfterScan() async {
    return false; // Versão gratuita: nunca mostrar paywall
  }

  // CHATBOT — 3 mensagens grátis
  static Future<bool> canUseChat() async {
    return true;
  }

  static Future<int> getChatUsesUsed() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_keyChatUses) ?? 0;
  }

  static Future<int> getChatUsesRemaining() async {
    return 999999;
  }

  static Future<void> useChatCredit() async {
    return; // Sem limite de mensagens
  }

  // Premium
  static Future<bool> isPremium() async {
    return true; // Acesso ilimitado local, sem cobrança
  }

  static Future<void> setPremium(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyIsPremium, value);
  }

  static Future<void> resetForTesting() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyIsPremium);
    await prefs.remove(_keyChatUses);
  }
}