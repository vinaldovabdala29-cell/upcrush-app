import 'dart:ui';
import 'package:flutter/material.dart';

import '../../../main.dart';
import '../widgets/feature_card.dart';
import '../widgets/settings_sheet.dart';

import 'screenshot_screen.dart';
import 'opener_screen.dart';
import 'pick_lines_screen.dart';
import 'chatbot_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;

  void _selectTab(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder(
      valueListenable: appLangNotifier,
      builder: (context, lang, _) {
        return ValueListenableBuilder(
          valueListenable: isDarkModeNotifier,
          builder: (context, isDark, _) {
            return Scaffold(
              body: Stack(
                children: [
                  Padding(
                    padding: const EdgeInsets.only(bottom: 64),
                    child: IndexedStack(
                      index: _selectedIndex,
                      children: [
                        _HomeContent(key: ValueKey(lang.languageCode)),
                        const ChatbotScreen(embedded: true),
                      ],
                    ),
                  ),
                  Positioned(
                    left: 0, right: 0, bottom: 0,
                    child: _BottomNavigation(
                      selectedIndex: _selectedIndex,
                      isDark: isDark,
                      onSelected: _selectTab,
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}

// ===============================================================
// HOME CONTENT
// ===============================================================

class _HomeContent extends StatelessWidget {
  const _HomeContent({super.key});

  bool get _dark => isDarkModeNotifier.value;

  Color get _bg => _dark ? const Color(0xFF212121) : const Color(0xFFF2F2F7);
  Color get _textPrimary => _dark ? Colors.white : const Color(0xFF1C1C1E);
  Color get _textSecondary => _dark ? Colors.white38 : Colors.black38;

  Future<void> _openSettings(BuildContext context) async {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) {
        return ValueListenableBuilder(
          valueListenable: isDarkModeNotifier,
          builder: (context, dark, _) {
            return SettingsSheet(
              isDarkMode: dark,
              onThemeChanged: (value) {
                isDarkModeNotifier.value = value;
              },
              onLanguageChanged: (_) {},
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder(
      valueListenable: appLangNotifier,
      builder: (context, lang, _) {
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
                color: const Color(0xFFFF2D55).withOpacity(_dark ? 0.07 : 0.08)),
            ),
          ),
          Positioned(
            bottom: 100, left: -80,
            child: Container(
              width: 220, height: 220,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF007AFF).withOpacity(_dark ? 0.06 : 0.07)),
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
                            color: _dark ? Colors.white.withOpacity(0.08) : Colors.white.withOpacity(0.7),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: _dark ? Colors.white.withOpacity(0.08) : Colors.black.withOpacity(0.06))),
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
                          color: _dark ? Colors.white : const Color(0xFF1C1C1E),
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
                      physics: const BouncingScrollPhysics(),
                      padding: const EdgeInsets.only(bottom: 100),
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
                            isDarkMode: _dark,
                            subtitleColor: _dark ? Colors.white70 : const Color(0xFF444444),
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
                            isDarkMode: _dark,
                            subtitleColor: _dark ? Colors.white70 : const Color(0xFF444444),
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
                            isDarkMode: _dark,
                            subtitleColor: _dark ? Colors.white70 : const Color(0xFF444444),
                            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const OpenerScreen())),
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
      },
    );
  }
}

// ===============================================================
// BOTTOM NAVIGATION
// ===============================================================

class _BottomNavigation extends StatelessWidget {
  final int selectedIndex;
  final bool isDark;
  final ValueChanged<int> onSelected;

  const _BottomNavigation({
    required this.selectedIndex,
    required this.isDark,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    final bg = isDark ? const Color(0xFF0A0A0F) : Colors.white;

    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 30, sigmaY: 30),
        child: Container(
          decoration: BoxDecoration(
            color: bg.withOpacity(isDark ? 0.55 : 0.65),
            border: Border(
              top: BorderSide(
                color: isDark ? Colors.white.withOpacity(0.08) : Colors.black.withOpacity(0.06),
                width: 0.5,
              ),
            ),
          ),
          child: SafeArea(
            top: false,
            child: SizedBox(
              height: 64,
              child: Row(
                children: [
                  _item(index: 0, label: _homeLabel()),
                  _item(index: 1, label: 'Coach'),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  String _homeLabel() {
    switch (appLang.languageCode) {
      case 'de': return 'Home';
      case 'es': return 'Inicio';
      case 'pt': return 'Casa';
      default:   return 'Home';
    }
  }

  Widget _item({
    required int index,
    required String label,
  }) {
    final selected = selectedIndex == index;
    const accent = Color(0xFFFF2D55);

    return Expanded(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => onSelected(index),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedDefaultTextStyle(
              duration: const Duration(milliseconds: 200),
              style: TextStyle(
                fontSize: selected ? 16 : 15,
                fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
                letterSpacing: 0.2,
                color: selected
                  ? accent
                  : (isDark ? Colors.white54 : Colors.black45),
              ),
              child: Text(label),
            ),
            const SizedBox(height: 6),
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeOut,
              height: 3,
              width: selected ? 22 : 0,
              decoration: BoxDecoration(
                color: accent,
                borderRadius: BorderRadius.circular(2),
                boxShadow: selected ? [
                  BoxShadow(color: accent.withOpacity(0.4), blurRadius: 6, offset: const Offset(0, 1)),
                ] : [],
              ),
            ),
          ],
        ),
      ),
    );
  }
}