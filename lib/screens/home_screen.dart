import 'dart:ui';
import '../widgets/home_hero_image.dart';
import 'package:flutter/material.dart';

import '../main.dart';
import '../services/revenue_cat_service.dart';
import '../services/response_paywall_gate.dart';
import '../widgets/paywall_screen.dart';
import '../widgets/feature_card.dart';
import '../widgets/settings_sheet.dart';

import 'screenshot_screen.dart';
import 'opener_screen.dart';
import 'pick_lines_screen.dart';
import 'chatbot_screen.dart';
import 'saved_chats_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;
  int _chatsRefreshToken = 0;

  Future<void> _selectTab(int index) async {
    if (index == 2 && _selectedIndex != 2) {
      final allowed = await ResponsePaywallGate.allow(context, returnOnDismiss: false);
      if (!mounted || !allowed) return;
    }
    if (mounted) setState(() {
      _selectedIndex = index;
      if (index == 1) _chatsRefreshToken++;
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
                        SavedChatsScreen(
                          key: ValueKey('saved-chats-${lang.languageCode}'),
                          refreshToken: _chatsRefreshToken,
                        ),
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

  Future<void> _openPremiumFeature(BuildContext context, Widget screen) async {
    await Navigator.of(context).push(MaterialPageRoute(builder: (_) => screen));
  }

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
                  const SizedBox(height: 6),
                  // Cabeçalho: título centrado na mesma linha dos controlos.
                  SizedBox(
                    height: 52,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        Center(
                          child: RichText(
                            text: TextSpan(children: [
                              TextSpan(text: 'Up', style: TextStyle(
                                fontSize: 35, fontWeight: FontWeight.w900,
                                color: _dark ? Colors.white : const Color(0xFF1C1C1E),
                                letterSpacing: -1.4)),
                              const TextSpan(text: 'Crush AI', style: TextStyle(
                                fontSize: 35, fontWeight: FontWeight.w900,
                                color: Color(0xFFFF2D55), letterSpacing: -1.4)),
                            ]),
                          ),
                        ),
                        Align(
                          alignment: Alignment.centerLeft,
                          child: GestureDetector(
                            onTap: () => _openSettings(context),
                            child: Container(
                              width: 40, height: 40,
                              decoration: BoxDecoration(
                                color: _dark ? Colors.white.withOpacity(0.08) : Colors.white.withOpacity(0.7),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: _dark ? Colors.white.withOpacity(0.08) : Colors.black.withOpacity(0.06))),
                              child: Icon(Icons.menu_rounded, color: _textPrimary, size: 20),
                            ),
                          ),
                        ),
                        const Align(
                          alignment: Alignment.centerRight,
                          child: Text('🌶️', style: TextStyle(fontSize: 28)),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),

                  // Subtítulo localizado, centralizado e sem badge.
                  Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      child: Text(
                        appLang.ui(const {
                          'pt': 'Melhore a falar com garotas',
                          'en': 'Get better at speaking with girls',
                          'de': 'Werde besser darin, mit Mädchen zu reden',
                          'es': 'Mejora al hablar con chicas',
                          'fr': 'Apprends à mieux parler aux filles',
                          'it': 'Impara a parlare meglio con le ragazze',
                          'tr': 'Kızlarla konuşmada daha iyi ol',
                          'pl': 'Naucz się lepiej rozmawiać z dziewczynami',
                          'ru': 'Научись лучше общаться с девушками',
                          'ar': 'تعلّم كيف تتحدث مع الفتيات بشكل أفضل',
                        }),
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: _textPrimary.withOpacity(0.78),
                          fontSize: 17,
                          fontWeight: FontWeight.w600,
                          height: 1.3,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),

                  Expanded(
                    child: LayoutBuilder(
                      builder: (context, constraints) => FittedBox(
                        fit: BoxFit.scaleDown,
                        // Centraliza imagem e três cartões como um só bloco
                        // no espaço entre o subtítulo e a navegação inferior.
                        alignment: Alignment.center,
                        child: SizedBox(
                          width: constraints.maxWidth,
                          height: 650,
                          child: Column(
                        children: [
                          // Ilustração integrada entre o cabeçalho e os cartões.
                          const HomeHeroImage(),
                          const SizedBox(height: 30),
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
                            cardBackgroundColor: const Color(0xFFFCE5EB),
                            isDarkMode: _dark,
                            subtitleColor: _dark ? Colors.white70 : const Color(0xFF444444),
                            onTap: () => _openPremiumFeature(context, const ScreenshotScreen()),
                          ),
                          const SizedBox(height: 12),

                          // ── 2 + 3. Cartões inferiores em triângulo ──
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: _TriangleFeatureCard(
                                  title: appLang.languageCode == 'de'
                                      ? 'Eisbrecher 🧊'
                                      : appLang.languageCode == 'es'
                                          ? 'Rompehielos 🧊'
                                          : appLang.languageCode == 'pt'
                                              ? 'Quebrar Gelo 🧊'
                                              : 'Break the Ice 🧊',
                                  subtitle: appLang.ui(const {
                                    'pt': 'Responda a stories e comece conversas',
                                    'en': 'Reply to stories and start conversations',
                                    'de': 'Antworte auf Storys und starte Gespräche',
                                    'es': 'Responde a historias e inicia conversaciones',
                                    'fr': 'Réponds aux stories et lance des conversations',
                                    'it': 'Rispondi alle storie e avvia conversazioni',
                                    'tr': 'Hikâyelere yanıt ver ve sohbet başlat',
                                    'pl': 'Odpowiadaj na relacje i zaczynaj rozmowy',
                                    'ru': 'Отвечай на истории и начинай общение',
                                    'ar': 'رد على القصص وابدأ المحادثات',
                                  }),
                                  icon: Icons.chat_bubble_rounded,
                                  colors: const [Color(0xFFFF9500), Color(0xFFFFCC02)],
                                  cardBackgroundColor: Colors.white,
                                  dark: _dark,
                                  onTap: () => _openPremiumFeature(context, const OpenerScreen()),
                                ),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: _TriangleFeatureCard(
                                  title: appLang.languageCode == 'de'
                                      ? 'Anmachsprüche 💘'
                                      : appLang.languageCode == 'es'
                                          ? 'Piropos 💘'
                                          : appLang.languageCode == 'pt'
                                              ? 'Cantadas 💘'
                                              : 'Pickup Lines 💘',
                                  subtitle: appLang.ui(const {
                                    'pt': 'Descubra frases para conquistar e flertar',
                                    'en': 'Discover lines to charm and flirt',
                                    'de': 'Entdecke Sprüche zum Flirten und Erobern',
                                    'es': 'Descubre frases para conquistar y coquetear',
                                    'fr': 'Découvre des phrases pour séduire et flirter',
                                    'it': 'Scopri frasi per conquistare e flirtare',
                                    'tr': 'Etkilemek ve flört etmek için sözler keşfet',
                                    'pl': 'Odkryj teksty na podryw i flirt',
                                    'ru': 'Найди фразы для знакомства и флирта',
                                    'ar': 'اكتشف عبارات للإعجاب والمغازلة',
                                  }),
                                  icon: Icons.rocket_launch_rounded,
                                  colors: const [Color(0xFF007AFF), Color(0xFF5AC8FA)],
                                  cardBackgroundColor: Colors.white,
                                  dark: _dark,
                                  onTap: () => _openPremiumFeature(context, const PickLinesScreen()),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                        ],
                      ),
                        ),
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

// Cartões compactos: apenas os dois cartões inferiores da Home.
class _TriangleFeatureCard extends StatelessWidget {
  final String title;
  final String? subtitle;
  final IconData icon;
  final List<Color> colors;
  final bool dark;
  final Color cardBackgroundColor;
  final VoidCallback onTap;

  const _TriangleFeatureCard({
    required this.title,
    this.subtitle,
    required this.icon,
    required this.colors,
    required this.dark,
    required this.cardBackgroundColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(24),
        onTap: onTap,
        child: Container(
          constraints: const BoxConstraints(minHeight: 150),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 18),
          decoration: BoxDecoration(
            color: dark ? Color.alphaBlend(cardBackgroundColor.withOpacity(0.20), const Color(0xFF19191C)) : cardBackgroundColor,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: dark ? Colors.white.withOpacity(0.08) : Colors.black.withOpacity(0.06)),
            boxShadow: dark ? [] : [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 3))],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: colors),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [BoxShadow(color: colors.first.withOpacity(0.35), blurRadius: 10, offset: const Offset(0, 4))],
                ),
                child: Icon(icon, color: Colors.white, size: 26),
              ),
              const SizedBox(height: 12),
              Text(title,
                textAlign: TextAlign.center,
                style: TextStyle(color: dark ? Colors.white : const Color(0xFF1C1C1E), fontSize: 15, fontWeight: FontWeight.w800),
              ),
              if (subtitle != null) ...[
                const SizedBox(height: 7),
                Text(
                  subtitle!,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: dark ? Colors.white70 : const Color(0xFF62626A),
                    fontSize: 11.5,
                    fontWeight: FontWeight.w500,
                    height: 1.25,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
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
                  _item(index: 1, label: appLang.ui(const {'en': 'Chats', 'pt': 'Conversas', 'de': 'Chats', 'es': 'Chats', 'fr': 'Conversations', 'it': 'Chat', 'tr': 'Sohbetler', 'pl': 'Czaty', 'ru': 'Чаты', 'ar': 'المحادثات'})),
                  _item(index: 2, label: 'Coach'),
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