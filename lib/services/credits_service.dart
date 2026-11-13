import 'package:shared_preferences/shared_preferences.dart';
import 'revenue_cat_service.dart';

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
    return !(await isPremium());
  }

  // CHATBOT — 3 mensagens grátis
  static Future<bool> canUseChat() async {
    return isPremium();
  }

  static Future<int> getCredits() async => await isPremium() ? 999999 : 0;

  static Future<int> getChatUsesUsed() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_keyChatUses) ?? 0;
  }

  static Future<int> getChatUsesRemaining() async {
    return await isPremium() ? 999999 : 0;
  }

  static Future<void> useChatCredit() async {
    return; // O bloqueio é controlado pelo entitlement Premium
  }

  // Premium
  static Future<bool> isPremium() async {
    return RevenueCatService.isPremium();
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