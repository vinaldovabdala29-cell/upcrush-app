import 'package:shared_preferences/shared_preferences.dart';

class CreditsService {
  static const String _keyIsPremium = 'is_premium';
  static const String _keyChatUses = 'chat_uses_used';

  // Chatbot: 3 mensagens grátis (para sempre, não reset diário)
  static const int _freeChatMessages = 3;

  // ─── Inicializar ──────────────────────────────────────────────────────────
  static Future<void> init() async {
    // Nada a inicializar — sem reset diário
  }

  // ─── SCREENSHOT e OPENER — abre galeria primeiro, paywall depois ─────────
  static Future<bool> canUseScanner() async {
    return true; // galeria sempre abre
  }

  // Mostra paywall após scan se não é premium
  static Future<bool> shouldShowPaywallAfterScan() async {
    return !(await isPremium());
  }

  // ─── CHATBOT — 3 mensagens grátis ────────────────────────────────────────
  static Future<bool> canUseChat() async {
    if (await isPremium()) return true;
    final used = await getChatUsesUsed();
    return used < _freeChatMessages;
  }

  static Future<int> getChatUsesUsed() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_keyChatUses) ?? 0;
  }

  static Future<int> getChatUsesRemaining() async {
    if (await isPremium()) return 999;
    final used = await getChatUsesUsed();
    final remaining = _freeChatMessages - used;
    return remaining < 0 ? 0 : remaining;
  }

  static Future<void> useChatCredit() async {
    if (await isPremium()) return;
    final prefs = await SharedPreferences.getInstance();
    final used = prefs.getInt(_keyChatUses) ?? 0;
    await prefs.setInt(_keyChatUses, used + 1);
  }

  // ─── Premium ──────────────────────────────────────────────────────────────
  static Future<bool> isPremium() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keyIsPremium) ?? false;
  }

  static Future<void> setPremium(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyIsPremium, value);
  }

  // ─── Para testes ─────────────────────────────────────────────────────────
  static Future<void> resetForTesting() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyIsPremium);
    await prefs.remove(_keyChatUses);
  }
}