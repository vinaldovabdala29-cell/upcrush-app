import 'package:flutter/material.dart';
import '../widgets/feature_card.dart';
import '../widgets/settings_sheet.dart';
import '../../../main.dart';
import '../theme/app_localizations.dart';
import 'screenshot_screen.dart';
import 'opener_screen.dart';
import 'pick_lines_screen.dart';
import 'chatbot_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<AppLocalizations>(
      valueListenable: appLangNotifier,
      builder: (context, lang, _) {
        return ValueListenableBuilder<bool>(
          valueListenable: isDarkModeNotifier,
          builder: (context, isDark, _) {
            return _HomeBody(isDark: isDark);
          },
        );
      },
    );
  }
}

class _HomeBody extends StatelessWidget {
  final bool isDark;
  const _HomeBody({required this.isDark});

  Color get _bg => isDark ? const Color(0xFF212121) : const Color(0xFFF2F2F7);
  Color get _textPrimary => isDark ? Colors.white : const Color(0xFF1C1C1E);
  Color get _textSecondary => isDark ? Colors.white38 : Colors.black38;

  void _openSettings(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => ValueListenableBuilder<bool>(
        valueListenable: isDarkModeNotifier,
        builder: (context, dark, _) => SettingsSheet(
          isDarkMode: dark,
          onThemeChanged: (val) => isDarkModeNotifier.value = val,
          onLanguageChanged: (lang) {},
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      body: Stack(
        children: [
          Positioned(
            top: -120, right: -80,
            child: Container(
              width: 280, height: 280,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFFFF2D55).withOpacity(isDark ? 0.07 : 0.08)),
            ),
          ),
          Positioned(
            bottom: 100, left: -80,
            child: Container(
              width: 220, height: 220,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF007AFF).withOpacity(isDark ? 0.06 : 0.07)),
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      GestureDetector(
                        onTap: () => _openSettings(context),
                        child: Container(
                          width: 40, height: 40,
                          decoration: BoxDecoration(
                            color: isDark ? Colors.white.withOpacity(0.08) : Colors.white.withOpacity(0.7),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: isDark ? Colors.white.withOpacity(0.08) : Colors.black.withOpacity(0.06))),
                          child: Icon(Icons.menu_rounded, color: _textPrimary, size: 20)),
                      ),
                      const Text("🌶️", style: TextStyle(fontSize: 28)),
                    ],
                  ),
                  const SizedBox(height: 28),

                  // ── Nome ──────────────────────────────────────────────
                  RichText(
                    text: TextSpan(children: [
                      TextSpan(text: "Up",
                        style: TextStyle(
                          fontSize: 42, fontWeight: FontWeight.w900,
                          color: isDark ? Colors.white : const Color(0xFF1C1C1E),
                          letterSpacing: -1.5, height: 1.0)),
                      const TextSpan(text: "Crush",
                        style: TextStyle(
                          fontSize: 42, fontWeight: FontWeight.w900,
                          color: Color(0xFFFF2D55),
                          letterSpacing: -1.5, height: 1.0)),
                    ]),
                  ),

                  const SizedBox(height: 10),

                  // ── Badge — "Melhore a tua vida social" ───────────────
                  Row(children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFFFF2D55), Color(0xFFFF6B81)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight),
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [BoxShadow(
                          color: const Color(0xFFFF2D55).withOpacity(0.35),
                          blurRadius: 10, offset: const Offset(0, 3))]),
                      child: Row(mainAxisSize: MainAxisSize.min, children: [
                        const Text("✦", style: TextStyle(
                          color: Colors.white, fontSize: 10, fontWeight: FontWeight.w800)),
                        const SizedBox(width: 4),
                        Text(
                          appLang.languageCode == 'de'
                            ? 'Verbessere dein Sozialleben'
                            : appLang.languageCode == 'es'
                                ? 'Mejora tu vida social'
                                : appLang.languageCode == 'pt'
                                    ? 'Melhore a tua vida social'
                                    : 'Improve your social life',
                          style: const TextStyle(
                            color: Colors.white, fontSize: 12,
                            fontWeight: FontWeight.w700, letterSpacing: 0.2)),
                      ]),
                    ),
                  ]),
                  const SizedBox(height: 36),

                  Expanded(
                    child: SingleChildScrollView(
                      child: Column(
                        children: [
                          // ── 1. Screenshot ──────────────────────────────
                          FeatureCard(
                            title: appLang.languageCode == 'de'
                                ? "Was soll ich antworten?"
                                : appLang.languageCode == 'es'
                                    ? "Qué debo responder?"
                                    : appLang.languageCode == 'pt'
                                        ? "Oque devo responder?"
                                        : "What should I reply?",
                            subtitle: appLang.languageCode == 'de'
                                ? "Lade einen Chat-Screenshot hoch für Antwortvorschläge"
                                : appLang.languageCode == 'es'
                                    ? "Sube una captura del chat para sugerencias de respuesta"
                                    : appLang.languageCode == 'pt'
                                        ? "Faça upload de uma captura de tela do bate-papo para sugestões de resposta"
                                        : "Upload a chat screenshot for reply suggestions",
                            icon: Icons.camera_alt_rounded,
                            iconBgColors: const [Color(0xFFFF2D55), Color(0xFFFF6B81)],
                            iconShadowColor: const Color(0xFFFF2D55),
                            isDarkMode: isDark,
                            subtitleColor: isDark ? Colors.white70 : const Color(0xFF444444),
                            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ScreenshotScreen())),
                          ),
                          const SizedBox(height: 14),

                          // ── 2. Get Pick Lines ──────────────────────────
                          FeatureCard(
                            title: appLang.languageCode == 'de'
                                ? "Erste Nachricht"
                                : appLang.languageCode == 'es'
                                    ? "Primer mensaje"
                                    : appLang.languageCode == 'pt'
                                        ? "Primeira mensagem"
                                        : "First message",
                            subtitle: appLang.languageCode == 'de'
                                ? "Personalisierte Nachrichten, um jedes Gespräch zu starten"
                                : appLang.languageCode == 'es'
                                    ? "Mensajes personalizados para iniciar cualquier conversación"
                                    : appLang.languageCode == 'pt'
                                        ? "Mensagens personalizadas para iniciar qualquer conversa"
                                        : "Personalized messages to start any conversation",
                            icon: Icons.rocket_launch_rounded,
                            iconBgColors: const [Color(0xFFFF9500), Color(0xFFFFCC02)],
                            iconShadowColor: const Color(0xFFFF9500),
                            isDarkMode: isDark,
                            subtitleColor: isDark ? Colors.white70 : const Color(0xFF444444),
                            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const PickLinesScreen())),
                          ),
                          const SizedBox(height: 14),

                          // ── 3. Create Opener ───────────────────────────
                          FeatureCard(
                            title: appLang.languageCode == 'de'
                                ? "Beginne ein Gespräch"
                                : appLang.languageCode == 'es'
                                    ? "Inicia una conversación"
                                    : appLang.languageCode == 'pt'
                                        ? "Inicie uma conversa"
                                        : "Start a conversation",
                            subtitle: appLang.languageCode == 'de'
                                ? "Sende ein Foto einer Person oder Aktivität, um Gespräche zu starten"
                                : appLang.languageCode == 'es'
                                    ? "Envía una foto de una persona o actividad para iniciar conversaciones"
                                    : appLang.languageCode == 'pt'
                                        ? "Envie uma foto de uma pessoa ou atividade para iniciar conversas"
                                        : "Send a photo of a person or activity to start conversations",
                            icon: Icons.chat_bubble_rounded,
                            iconBgColors: const [Color(0xFF007AFF), Color(0xFF5AC8FA)],
                            iconShadowColor: const Color(0xFF007AFF),
                            isDarkMode: isDark,
                            subtitleColor: isDark ? Colors.white70 : const Color(0xFF444444),
                            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const OpenerScreen())),
                          ),
                          const SizedBox(height: 10),

                          // ── 4. UpCrush AI Coach ────────────────────────
                          Center(
                            child: GestureDetector(
                              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ChatbotScreen())),
                              child: Container(
                                padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 22),
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(
                                    colors: [Color(0xFFFF2D55), Color(0xFFFF6B81)],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight),
                                  borderRadius: BorderRadius.circular(22),
                                  boxShadow: [BoxShadow(
                                    color: const Color(0xFFFF2D55).withOpacity(0.35),
                                    blurRadius: 10, offset: const Offset(0, 4))]),
                                child: const Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text('🧠', style: TextStyle(fontSize: 16)),
                                    SizedBox(width: 8),
                                    Text('UpCrush AI Coach',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 14,
                                        fontWeight: FontWeight.w800,
                                        letterSpacing: 0.2)),
                                  ]),
                              ),
                            ),
                          ),
                          const SizedBox(height: 24),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}