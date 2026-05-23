import 'package:flutter/material.dart';
import '../widgets/feature_card.dart';
import '../widgets/settings_sheet.dart';
import '../../../main.dart';
import '../theme/app_localizations.dart';
import 'screenshot_screen.dart';
import 'chatbot_screen.dart';
import 'opener_screen.dart';
import 'pick_lines_screen.dart';

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
                color: const Color(0xFFFF2D55).withOpacity(isDark ? 0.07 : 0.08),
              ),
            ),
          ),
          Positioned(
            bottom: 100, left: -80,
            child: Container(
              width: 220, height: 220,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF007AFF).withOpacity(isDark ? 0.06 : 0.07),
              ),
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
                            border: Border.all(color: isDark ? Colors.white.withOpacity(0.08) : Colors.black.withOpacity(0.06)),
                          ),
                          child: Icon(Icons.menu_rounded, color: _textPrimary, size: 20),
                        ),
                      ),
                      const Text("🌶️", style: TextStyle(fontSize: 28)),
                    ],
                  ),
                  const SizedBox(height: 28),

                  // ── Nome ─────────────────────────────────────────────
                  RichText(
                    text: TextSpan(children: [
                      TextSpan(
                        text: "Up",
                        style: TextStyle(
                          fontSize: 42,
                          fontWeight: FontWeight.w900,
                          color: isDark ? Colors.white : const Color(0xFF1C1C1E),
                          letterSpacing: -1.5,
                          height: 1.0,
                        ),
                      ),
                      const TextSpan(
                        text: "Crush",
                        style: TextStyle(
                          fontSize: 42,
                          fontWeight: FontWeight.w900,
                          color: Color(0xFFFF2D55),
                          letterSpacing: -1.5,
                          height: 1.0,
                        ),
                      ),
                    ]),
                  ),

                  const SizedBox(height: 10),

                  // ── Badge ─────────────────────────────────────────────
                  Row(children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFFFF2D55), Color(0xFFFF6B81)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [BoxShadow(
                          color: const Color(0xFFFF2D55).withOpacity(0.35),
                          blurRadius: 10, offset: const Offset(0, 3))],
                      ),
                      child: Row(mainAxisSize: MainAxisSize.min, children: [
                        const Text("✦", style: TextStyle(
                          color: Colors.white, fontSize: 10,
                          fontWeight: FontWeight.w800)),
                        const SizedBox(width: 4),
                        Text(
                          appLang.appTagline,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.2,
                          ),
                        ),
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
                            title: appLang.featureScreenshot,
                            subtitle: appLang.featureScreenshotSub,
                            icon: Icons.camera_alt_rounded,
                            iconBgColors: const [Color(0xFFFF2D55), Color(0xFFFF6B81)],
                            iconShadowColor: const Color(0xFFFF2D55),
                            isDarkMode: isDark,
                            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ScreenshotScreen())),
                          ),
                          const SizedBox(height: 14),

                          // ── 2. Get Pick Lines ──────────────────────────
                          FeatureCard(
                            title: "Get Pick Lines",
                            subtitle: appLang.languageCode == 'de'
                                ? "Eröffne jedes Gespräch mit Stil"
                                : appLang.languageCode == 'es'
                                    ? "Abre cada conversación con estilo"
                                    : appLang.languageCode == 'pt'
                                        ? "Abre cada conversa com estilo"
                                        : "Open every conversation with style",
                            icon: Icons.rocket_launch_rounded,
                            iconBgColors: const [Color(0xFFFF9500), Color(0xFFFFCC02)],
                            iconShadowColor: const Color(0xFFFF9500),
                            isDarkMode: isDark,
                            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const PickLinesScreen())),
                          ),
                          const SizedBox(height: 14),

                          // ── 3. Create Opener ───────────────────────────
                          FeatureCard(
                            title: appLang.featureOpener,
                            subtitle: appLang.languageCode == 'de'
                                ? "Analysiere ihr Profil und erstelle die perfekte erste Nachricht"
                                : appLang.languageCode == 'es'
                                    ? "Analiza su perfil y genera el primer mensaje perfecto"
                                    : appLang.languageCode == 'pt'
                                        ? "Analisa o perfil dela e gera a primeira mensagem perfeita"
                                        : "Analyze her profile and generate the perfect first message",
                            icon: Icons.chat_bubble_rounded,
                            iconBgColors: const [Color(0xFF007AFF), Color(0xFF5AC8FA)],
                            iconShadowColor: const Color(0xFF007AFF),
                            isDarkMode: isDark,
                            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const OpenerScreen())),
                          ),
                          const SizedBox(height: 10),

                          // ── 4. Chat IA (botão pequeno preto) ──────────
                          Center(
                            child: GestureDetector(
                              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ChatbotScreen())),
                              child: Container(
                                padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 20),
                                decoration: BoxDecoration(
                                  color: Colors.black,
                                  borderRadius: BorderRadius.circular(20),
                                  boxShadow: [
                                    BoxShadow(color: Colors.black.withOpacity(0.3), blurRadius: 6, offset: const Offset(0, 2)),
                                  ],
                                ),
                                child: const Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.auto_awesome_rounded, color: Colors.white, size: 13),
                                    SizedBox(width: 6),
                                    Text("Chat IA", style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w700)),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 20),
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