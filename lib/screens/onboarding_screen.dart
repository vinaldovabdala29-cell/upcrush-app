import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../main.dart';
import '../widgets/paywall_screen.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});
  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  int _visibleFeatures = 0;
  Timer? _typingTimer;

  @override
  void initState() {
    super.initState();
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle.light);
    Future.delayed(const Duration(milliseconds: 1800), () {
      if (mounted) _startTypingSequence();
    });
  }

  @override
  void dispose() {
    _typingTimer?.cancel();
    super.dispose();
  }

  void _startTypingSequence() {
    _typingTimer = Timer.periodic(const Duration(milliseconds: 2200), (timer) {
      if (!mounted) { timer.cancel(); return; }
      HapticFeedback.lightImpact();
      setState(() => _visibleFeatures++);
      if (_visibleFeatures >= 3) timer.cancel();
    });
  }

  Future<void> _finish(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('onboarding_done', true);
    if (!context.mounted) return;
    HapticFeedback.mediumImpact();
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => PaywallFlow(
        onSuccess: () {
          Navigator.pushReplacementNamed(context, '/home');
        },
      )),
    );
  }

  Future<void> _openUrl(String url) async {
    try {
      await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
    } catch (_) {}
  }

  void _showLanguagePicker(BuildContext context) {
    final languages = [
      {'code': 'en', 'flag': '🇺🇸', 'name': 'English'},
      {'code': 'pt', 'flag': '🇧🇷', 'name': 'Português'},
      {'code': 'de', 'flag': '🇩🇪', 'name': 'Deutsch'},
      {'code': 'es', 'flag': '🇪🇸', 'name': 'Español'},
      {'code': 'fr', 'flag': '🇫🇷', 'name': 'Français'},
      {'code': 'it', 'flag': '🇮🇹', 'name': 'Italiano'},
      {'code': 'tr', 'flag': '🇹🇷', 'name': 'Türkçe'},
      {'code': 'pl', 'flag': '🇵🇱', 'name': 'Polski'},
      {'code': 'ru', 'flag': '🇷🇺', 'name': 'Русский'},
      {'code': 'ar', 'flag': '🇸🇦', 'name': 'العربية'},
    ];

    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF2C2C2E),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40, height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(2))),
              ...languages.map((l) => ListTile(
                leading: Text(l['flag']!, style: const TextStyle(fontSize: 24)),
                title: Text(l['name']!,
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
                trailing: appLang.languageCode == l['code']
                  ? const Icon(Icons.check_circle_rounded, color: Color(0xFF34C759))
                  : null,
                onTap: () {
                  changeLanguage(l['code']!);
                  Navigator.pop(ctx);
                },
              )),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder(
      valueListenable: appLangNotifier,
      builder: (context, _, __) {
        final lang = appLang.languageCode;

        return Scaffold(
          backgroundColor: const Color(0xFF1C1C1E),
          body: SafeArea(
            child: _WelcomePage(
              lang: lang,
              visibleFeatures: _visibleFeatures,
              onFinish: () => _finish(context),
              onOpenUrl: _openUrl,
            ),
          ),
        );
      },
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════
// ONBOARDING — Boas-vindas
// ═══════════════════════════════════════════════════════════════════════
class _WelcomePage extends StatelessWidget {
  final String lang;
  final int visibleFeatures;
  final VoidCallback onFinish;
  final Future<void> Function(String) onOpenUrl;

  const _WelcomePage({
    required this.lang,
    required this.visibleFeatures,
    required this.onFinish,
    required this.onOpenUrl,
  });

  String title() {
    switch (lang) {
      case 'de': return 'Willkommen bei\nUpCrush AI';
      case 'es': return 'Bienvenido a\nUpCrush AI';
      case 'pt': return 'Bem-vindo ao\nUpCrush AI';
      default:   return 'Welcome to\nUpCrush AI';
    }
  }

  List<Map<String, String>> features() {
    switch (lang) {
      case 'de': return [
        {'icon': '💬', 'text': 'Gespräche einfach starten'},
        {'icon': '📝', 'text': 'Deine Antworten verbessern'},
        {'icon': '😏', 'text': 'Die Emotionen anderer lesen'},
      ];
      case 'es': return [
        {'icon': '💬', 'text': 'Inicia conversaciones fácilmente'},
        {'icon': '📝', 'text': 'Mejora tus respuestas'},
        {'icon': '😏', 'text': 'Lee las emociones de las personas'},
      ];
      case 'pt': return [
        {'icon': '💬', 'text': 'Inicie conversas facilmente'},
        {'icon': '📝', 'text': 'Melhore suas respostas'},
        {'icon': '😏', 'text': 'Leia as emoções das pessoas'},
      ];
      default: return [
        {'icon': '💬', 'text': 'Start conversations easily'},
        {'icon': '📝', 'text': 'Improve your replies'},
        {'icon': '😏', 'text': 'Read people\'s emotions'},
      ];
    }
  }

  String btnLabel() {
    switch (lang) {
      case 'de': return 'Loslegen';
      case 'es': return 'Empezar';
      case 'pt': return 'Começar';
      default:   return 'Get started';
    }
  }

  List<TextSpan> termsSpans() {
    final accentColor = const Color(0xFF34C759);
    switch (lang) {
      case 'de':
        return [
          const TextSpan(text: 'Durch Tippen auf "Loslegen" stimmst du unseren '),
          TextSpan(text: 'Nutzungsbedingungen',
            style: TextStyle(color: accentColor, fontWeight: FontWeight.w700),
            recognizer: TapGestureRecognizer()..onTap = () => onOpenUrl(
              'https://sites.google.com/view/upcrush-terms/p%C3%A1gina-inicial')),
          const TextSpan(text: ' und '),
          TextSpan(text: 'Datenschutzrichtlinie',
            style: TextStyle(color: accentColor, fontWeight: FontWeight.w700),
            recognizer: TapGestureRecognizer()..onTap = () => onOpenUrl(
              'https://sites.google.com/view/upcrush-privacy-policy/p%C3%A1gina-inicial')),
          const TextSpan(text: ' zu.'),
        ];
      case 'es':
        return [
          const TextSpan(text: 'Al tocar "Empezar", aceptas nuestros '),
          TextSpan(text: 'Términos de Servicio',
            style: TextStyle(color: accentColor, fontWeight: FontWeight.w700),
            recognizer: TapGestureRecognizer()..onTap = () => onOpenUrl(
              'https://sites.google.com/view/upcrush-terms/p%C3%A1gina-inicial')),
          const TextSpan(text: ' y '),
          TextSpan(text: 'Política de Privacidad',
            style: TextStyle(color: accentColor, fontWeight: FontWeight.w700),
            recognizer: TapGestureRecognizer()..onTap = () => onOpenUrl(
              'https://sites.google.com/view/upcrush-privacy-policy/p%C3%A1gina-inicial')),
          const TextSpan(text: '.'),
        ];
      case 'pt':
        return [
          const TextSpan(text: 'Ao tocar em "Começar", você concorda com o nosso '),
          TextSpan(text: 'Termos de Serviço',
            style: TextStyle(color: accentColor, fontWeight: FontWeight.w700),
            recognizer: TapGestureRecognizer()..onTap = () => onOpenUrl(
              'https://sites.google.com/view/upcrush-terms/p%C3%A1gina-inicial')),
          const TextSpan(text: ' e '),
          TextSpan(text: 'Política de Privacidade',
            style: TextStyle(color: accentColor, fontWeight: FontWeight.w700),
            recognizer: TapGestureRecognizer()..onTap = () => onOpenUrl(
              'https://sites.google.com/view/upcrush-privacy-policy/p%C3%A1gina-inicial')),
          const TextSpan(text: '.'),
        ];
      default:
        return [
          const TextSpan(text: 'By tapping "Get started", you agree to our '),
          TextSpan(text: 'Terms of Service',
            style: TextStyle(color: accentColor, fontWeight: FontWeight.w700),
            recognizer: TapGestureRecognizer()..onTap = () => onOpenUrl(
              'https://sites.google.com/view/upcrush-terms/p%C3%A1gina-inicial')),
          const TextSpan(text: ' and '),
          TextSpan(text: 'Privacy Policy',
            style: TextStyle(color: accentColor, fontWeight: FontWeight.w700),
            recognizer: TapGestureRecognizer()..onTap = () => onOpenUrl(
              'https://sites.google.com/view/upcrush-privacy-policy/p%C3%A1gina-inicial')),
          const TextSpan(text: '.'),
        ];
    }
  }

  @override
  Widget build(BuildContext context) {
    final items = features();

    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxHeight < 700;
        final veryCompact = constraints.maxHeight < 620;

        final titleSize = veryCompact ? 28.0 : (compact ? 31.0 : 34.0);
        final featureSize = veryCompact ? 16.0 : (compact ? 17.0 : 18.0);
        final emojiSize = veryCompact ? 24.0 : (compact ? 26.0 : 28.0);

        return Container(
          color: const Color(0xFF1C1C1E),
          padding: EdgeInsets.fromLTRB(
            28,
            compact ? 16 : 24,
            28,
            compact ? 16 : 24,
          ),
          child: Column(
            children: [
              const Spacer(flex: 2),

              Text(
                '🌶️',
                style: TextStyle(
                  fontSize: veryCompact ? 50 : 58,
                ),
              ),

              SizedBox(height: compact ? 14 : 20),

              _TypewriterText(
                text: title(),
                fontSize: titleSize,
                fontWeight: FontWeight.w900,
                letterSpacing: -0.8,
                height: 1.12,
                textAlign: TextAlign.center,
                speedMs: 90,
                withHaptics: true,
              ),

              const Spacer(flex: 2),

              // Os 3 benefícios ficam centralizados no meio da tela.
              Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 360),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: List.generate(items.length, (index) {
                      final f = items[index];
                      final visible = index < visibleFeatures;

                      return AnimatedOpacity(
                        duration: const Duration(milliseconds: 400),
                        opacity: visible ? 1.0 : 0.0,
                        child: AnimatedSlide(
                          duration: const Duration(milliseconds: 400),
                          offset: visible
                              ? Offset.zero
                              : const Offset(0, 0.15),
                          child: Padding(
                            padding: EdgeInsets.only(
                              bottom: index == items.length - 1
                                  ? 0
                                  : (compact ? 18 : 22),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  f['icon']!,
                                  style: TextStyle(fontSize: emojiSize),
                                ),
                                const SizedBox(width: 14),
                                Flexible(
                                  child: visible
                                      ? _TypewriterText(
                                          text: f['text']!,
                                          fontSize: featureSize,
                                          fontWeight: FontWeight.w600,
                                          textAlign: TextAlign.center,
                                          speedMs: 70,
                                        )
                                      : const SizedBox.shrink(),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    }),
                  ),
                ),
              ),

              const Spacer(flex: 3),

              RichText(
                textAlign: TextAlign.center,
                text: TextSpan(
                  style: TextStyle(
                    color: Colors.white54,
                    fontSize: veryCompact ? 10.5 : 12,
                    height: 1.35,
                  ),
                  children: termsSpans(),
                ),
              ),

              SizedBox(height: compact ? 12 : 16),

              SizedBox(
                width: double.infinity,
                height: compact ? 54 : 58,
                child: ElevatedButton(
                  onPressed: onFinish,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF34C759),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 0,
                  ),
                  child: Text(
                    btnLabel(),
                    style: TextStyle(
                      fontSize: compact ? 16 : 17,
                      fontWeight: FontWeight.w800,
                    ),
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

class _TypewriterText extends StatefulWidget {
  final String text;
  final double fontSize;
  final FontWeight fontWeight;
  final double? letterSpacing;
  final double height;
  final TextAlign textAlign;
  final int speedMs;
  final bool withHaptics;

  const _TypewriterText({
    required this.text,
    this.fontSize = 17,
    this.fontWeight = FontWeight.w600,
    this.letterSpacing,
    this.height = 1.3,
    this.textAlign = TextAlign.start,
    this.speedMs = 60,
    this.withHaptics = false,
  });

  @override
  State<_TypewriterText> createState() => _TypewriterTextState();
}

class _TypewriterTextState extends State<_TypewriterText> {
  String _displayed = '';
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    int i = 0;
    _timer = Timer.periodic(Duration(milliseconds: widget.speedMs), (timer) {
      if (!mounted) { timer.cancel(); return; }
      if (i >= widget.text.length) { timer.cancel(); return; }
      if (widget.withHaptics && widget.text[i] != ' ' && widget.text[i] != '\n') {
        HapticFeedback.selectionClick();
      }
      setState(() => _displayed = widget.text.substring(0, i + 1));
      i++;
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Text(_displayed,
      textAlign: widget.textAlign,
      style: TextStyle(
        color: Colors.white,
        fontSize: widget.fontSize,
        fontWeight: widget.fontWeight,
        letterSpacing: widget.letterSpacing,
        height: widget.height));
  }
}