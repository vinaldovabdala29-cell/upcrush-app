import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:video_player/video_player.dart';
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
  final PageController _pageController = PageController();
  int _currentPage = 0;
  String _audience = 'women'; // women | men | both

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
    _pageController.dispose();
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

  void _goNext() {
    HapticFeedback.mediumImpact();
    _pageController.nextPage(
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeInOutCubic);
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
          backgroundColor: _currentPage < 19 ? Colors.white : const Color(0xFF1C1C1E),
          body: SafeArea(
            child: PageView(
              controller: _pageController,
              physics: const NeverScrollableScrollPhysics(),
              onPageChanged: (i) => setState(() => _currentPage = i),
              children: [
                // 1
                _FeatureShowcasePage(lang: lang, onContinue: _goNext),

                // 2 — Com quem conversa
                _AudienceChoicePage(
                  lang: lang,
                  initialAudience: _audience,
                  onSelected: (audience) {
                    setState(() => _audience = audience);
                  },
                  onContinue: _goNext,
                ),

                // 3
                _DesireScreenshotsPage(
                  lang: lang,
                  audience: _audience,
                  onContinue: _goNext,
                ),

                // 4
                _RecognitionPage(lang: lang, onContinue: _goNext),

                // 5
                _CompetitionAwarenessPage(
                  lang: lang,
                  audience: _audience,
                  onContinue: _goNext,
                ),

                // 6
                _DesireShiftPage(
                  lang: lang,
                  audience: _audience,
                  onContinue: _goNext,
                ),

                // 7
                _MorningMessageDesirePage(
                  lang: lang,
                  audience: _audience,
                  onContinue: _goNext,
                ),

                // 8 — Introdução às perguntas
                _QuestionIntroPage(lang: lang, onContinue: _goNext),

                // 9 — Idade
                _SingleChoicePage(
                  lang: lang,
                  titlePt: 'Quantos anos você tem?',
                  titleDe: 'Wie alt bist du?',
                  optionsPt: const ['18–20', '21–24', '25–29', '30–34', '35–44', '45+'],
                  optionsDe: const ['18–20', '21–24', '25–29', '30–34', '35–44', '45+'],
                  onContinue: _goNext,
                ),

                // 10 — Plataformas
                _MultiChoicePage(
                  lang: lang,
                  titlePt: 'Onde suas conversas acontecem com mais frequência?',
                  titleDe: 'Wo finden deine Chats am häufigsten statt?',
                  options: const [
                    'Instagram',
                    'Tinder',
                    'Bumble',
                    'Hinge',
                    'WhatsApp',
                    'Snapchat',
                    'Outro',
                  ],
                  maxSelections: 3,
                  onContinue: _goNext,
                ),

                // 11 — Dor
                _SingleChoicePage(
                  lang: lang,
                  titlePt: 'O que mais te incomoda nas tuas conversas?',
                  titleDe: 'Was stört dich beim Schreiben am meisten?',
                  optionsPt: const [
                    'Não saber o que responder',
                    'Ficar sem assunto',
                    'Receber respostas frias',
                    'Ser ignorado',
                    'Não saber como flertar',
                    'Não conseguir transformar conversa em encontro',
                  ],
                  optionsDe: const [
                    'Nicht wissen, was ich antworten soll',
                    'Nicht wissen, worüber ich schreiben soll',
                    'Trockene Antworten bekommen',
                    'Ignoriert werden',
                    'Nicht wissen, wie ich flirten soll',
                    'Aus Chats werden keine Dates',
                  ],
                  onContinue: _goNext,
                ),

                // 12 — Desejo
                _MultiChoicePage(
                  lang: lang,
                  titlePt: 'O que você mais gostaria que mudasse nas suas conversas?',
                  titleDe: 'Was würdest du dir beim Schreiben am meisten wünschen?',
                  optionsPt: const [
                    '💬 Sempre saber o que dizer',
                    '🔥 Criar mais química',
                    '❤️ Perceber mais interesse do outro lado',
                    '📱 Receber mais mensagens primeiro',
                    '😏 Flertar com mais confiança',
                    '📅 Transformar conversas em encontros',
                  ],
                  optionsDe: const [
                    '💬 Immer wissen, was ich sagen soll',
                    '🔥 Mehr Chemie aufbauen',
                    '❤️ Mehr Interesse von der anderen Person spüren',
                    '📱 Öfter zuerst angeschrieben werden',
                    '😏 Selbstbewusster flirten',
                    '📅 Aus Gesprächen echte Dates machen',
                  ],
                  maxSelections: 3,
                  onContinue: _goNext,
                ),

                // 13 — Reação quando demora
                _SingleChoicePage(
                  lang: lang,
                  titlePt: 'Quando alguém de quem você gosta demora para responder, o que você costuma fazer?',
                  titleDe: 'Wenn jemand, den du magst, länger nicht antwortet – was machst du normalerweise?',
                  optionsPt: const [
                    'Espero e não mando mais nada',
                    'Mando outra mensagem depois',
                    'Fico pensando no que fiz de errado',
                    'Tento puxar outro assunto',
                    'Finjo que não me importo',
                    'Depende da pessoa',
                  ],
                  optionsDe: const [
                    'Ich warte und schreibe nichts mehr',
                    'Ich schreibe später nochmal',
                    'Ich frage mich, was ich falsch gemacht habe',
                    'Ich versuche, ein neues Thema anzufangen',
                    'Ich tue so, als wäre es mir egal',
                    'Kommt auf die Person an',
                  ],
                  onContinue: _goNext,
                ),

                // 14 — Onde trava
                _SingleChoicePage(
                  lang: lang,
                  titlePt: 'Em que momento da conversa você mais sente que não sabe o que dizer?',
                  titleDe: 'In welchem Moment weißt du am häufigsten nicht, was du schreiben sollst?',
                  optionsPt: const [
                    '👋 Na primeira mensagem',
                    '💬 Depois que a conversa começa',
                    '😶 Quando fico sem assunto',
                    '😏 Quando quero começar a flertar',
                    '❤️ Quando realmente gosto da pessoa',
                    '📅 Quando quero levar a conversa para um encontro',
                  ],
                  optionsDe: const [
                    '👋 Bei der ersten Nachricht',
                    '💬 Nachdem das Gespräch angefangen hat',
                    '😶 Wenn mir die Gesprächsthemen ausgehen',
                    '😏 Wenn ich anfangen möchte zu flirten',
                    '❤️ Wenn ich die Person wirklich mag',
                    '📅 Wenn ich aus dem Chat ein Date machen möchte',
                  ],
                  onContinue: _goNext,
                ),

                // 15 — Confiança
                _ConfidencePage(lang: lang, onContinue: _goNext),

                // 16 — Preparando experiência (0% → 100%)
                _PersonalizationBridgePage(lang: lang, onContinue: _goNext),

                // 17 — Já estamos começando a entender você
                _UnderstandingYouPage(lang: lang, onContinue: _goNext),

                // 18 — Objetivo para os próximos 30 dias
                _SingleChoicePage(
                  lang: lang,
                  titlePt: 'Se suas conversas mudassem nos próximos 30 dias, qual resultado significaria mais para você?',
                  titleDe: 'Wenn sich deine Gespräche in den nächsten 30 Tagen verändern würden – welches Ergebnis würde dir am meisten bedeuten?',
                  optionsPt: const [
                    '💬 Sempre saber o que escrever',
                    '🔥 Sentir mais química nas conversas',
                    '❤️ Perceber que o interesse é recíproco',
                    '📱 Fazer a outra pessoa me procurar mais',
                    '😏 Conversar e flertar com mais confiança',
                    '📅 Ter mais encontros reais',
                  ],
                  optionsDe: const [
                    '💬 Immer wissen, was ich schreiben soll',
                    '🔥 Mehr Chemie in meinen Gesprächen spüren',
                    '❤️ Merken, dass das Interesse gegenseitig ist',
                    '📱 Öfter von der anderen Person angeschrieben werden',
                    '😏 Selbstbewusster schreiben und flirten',
                    '📅 Mehr echte Dates haben',
                  ],
                  onContinue: _goNext,
                ),

                // 19 — Prova social
                // Ao continuar, abre diretamente o paywall.
                _SocialProofPage(
                  lang: lang,
                  onContinue: () => _finish(context),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════
// PÁGINA 1 — Vídeo do UpCrush
// ═══════════════════════════════════════════════════════════════════════

class _FeatureShowcasePage extends StatefulWidget {
  final String lang;
  final VoidCallback onContinue;

  const _FeatureShowcasePage({
    required this.lang,
    required this.onContinue,
  });

  @override
  State<_FeatureShowcasePage> createState() => _FeatureShowcasePageState();
}

class _FeatureShowcasePageState extends State<_FeatureShowcasePage> {
  late final VideoPlayerController _videoController;

  bool _videoReady = false;
  bool _videoFailed = false;

  @override
  void initState() {
    super.initState();

    _videoController = VideoPlayerController.asset(
      'assets/videos/onboarding_intro.mp4',
    );

    _initializeVideo();
  }

  Future<void> _initializeVideo() async {
    try {
      await _videoController.initialize();

      await _videoController.setVolume(0);
      await _videoController.setLooping(true);
      await _videoController.play();

      if (!mounted) return;

      setState(() {
        _videoReady = true;
      });
    } catch (_) {
      if (!mounted) return;

      setState(() {
        _videoFailed = true;
      });
    }
  }

  @override
  void dispose() {
    _videoController.dispose();
    super.dispose();
  }

  String _headline(String lang) {
    switch (lang) {
      case 'de':
        return 'Deine Chats werden sich verändern.';
      case 'es':
        return 'Tus conversaciones están a punto de cambiar.';
      case 'pt':
        return 'As tuas conversas estão prestes a mudar.';
      case 'fr':
        return 'Tes conversations sont sur le point de changer.';
      case 'it':
        return 'Le tue conversazioni stanno per cambiare.';
      case 'tr':
        return 'Sohbetlerin değişmek üzere.';
      case 'pl':
        return 'Twoje rozmowy zaraz się zmienią.';
      case 'ru':
        return 'Твои переписки скоро изменятся.';
      case 'ar':
        return 'محادثاتك على وشك أن تتغير.';
      default:
        return 'Your conversations are about to change.';
    }
  }

  String _buttonLabel(String lang) {
    switch (lang) {
      case 'de':
        return 'Loslegen';
      case 'es':
        return 'Empezar';
      case 'pt':
        return 'Começar';
      case 'fr':
        return 'Commencer';
      case 'it':
        return 'Inizia';
      case 'tr':
        return 'Başla';
      case 'pl':
        return 'Zaczynamy';
      case 'ru':
        return 'Начать';
      case 'ar':
        return 'ابدأ';
      default:
        return 'Get started';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(0, 24, 0, 26),
      child: Column(
        children: [
          // Vídeo direto, sem mockup, com a mesma área visual da Tela 2.
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 7),
              child: Center(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(22),
                  child: _buildVideo(fit: BoxFit.contain),
                ),
              ),
            ),
          ),

          const SizedBox(height: 18),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Text(
              _headline(widget.lang),
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Color(0xFF080808),
                fontSize: 30,
                height: 1.10,
                fontWeight: FontWeight.w900,
                letterSpacing: -0.9,
              ),
            ),
          ),

          const SizedBox(height: 20),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: SizedBox(
              width: double.infinity,
              height: 60,
              child: ElevatedButton(
              onPressed: () {
                HapticFeedback.mediumImpact();
                widget.onContinue();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.black,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
              ),
              child: Text(
                _buttonLabel(widget.lang),
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.15,
                ),
              ),
            ),
          ),
          ),

          const SizedBox(height: 6),
        ],
      ),
    );
  }

  Widget _buildVideo({BoxFit fit = BoxFit.contain}) {
    if (_videoFailed) {
      return Container(
        color: const Color(0xFFF5F5F7),
        alignment: Alignment.center,
        child: const Text(
          'UpCrush',
          style: TextStyle(
            color: Color(0xFFFF2D55),
            fontSize: 36,
            fontWeight: FontWeight.w900,
            letterSpacing: -1.0,
          ),
        ),
      );
    }

    if (!_videoReady) {
      return Container(
        color: const Color(0xFFF7F7F8),
        alignment: Alignment.center,
        child: const SizedBox(
          width: 28,
          height: 28,
          child: CircularProgressIndicator(
            strokeWidth: 2.4,
            color: Color(0xFF111111),
          ),
        ),
      );
    }

    final size = _videoController.value.size;

    return FittedBox(
      fit: fit,
      alignment: Alignment.center,
      child: SizedBox(
        width: size.width,
        height: size.height,
        child: VideoPlayer(_videoController),
      ),
    );
  }
}


// ═══════════════════════════════════════════════════════════════════════
// PÁGINA 2 — DESEJO + 3 SCREENSHOTS REAIS
// ═══════════════════════════════════════════════════════════════════════

class _DesireScreenshotsPage extends StatefulWidget {
  final String lang;
  final String audience;
  final VoidCallback onContinue;

  const _DesireScreenshotsPage({
    required this.lang,
    required this.audience,
    required this.onContinue,
  });

  @override
  State<_DesireScreenshotsPage> createState() =>
      _DesireScreenshotsPageState();
}

class _DesireScreenshotsPageState extends State<_DesireScreenshotsPage> {
  final PageController _screensController =
      PageController(viewportFraction: 0.88);

  int _currentScreenshot = 0;

  final List<String> _screenshots = const [
    'assets/images/onboarding/chat_1.png',
    'assets/images/onboarding/chat_2.png',
    'assets/images/onboarding/chat_3.jpeg',
  ];

  @override
  void dispose() {
    _screensController.dispose();
    super.dispose();
  }

  String _headline(String lang) {
    final a = widget.audience;

    switch (lang) {
      case 'de':
        if (a == 'men') {
          return 'Sorg dafür, dass er aufs Handy schaut und hofft, dass du es bist.';
        }
        if (a == 'both') {
          return 'Sorg dafür, dass die Person aufs Handy schaut und hofft, dass du es bist.';
        }
        return 'Sorg dafür, dass sie aufs Handy schaut und hofft, dass du es bist.';

      case 'pt':
        if (a == 'men') {
          return 'Faça ele olhar para o celular esperando que seja você.';
        }
        if (a == 'both') {
          return 'Faça a pessoa olhar para o celular esperando que seja você.';
        }
        return 'Faça ela olhar para o celular esperando que seja você.';

      case 'es':
        if (a == 'men') return 'Haz que mire el teléfono esperando que seas tú.';
        if (a == 'both') return 'Haz que esa persona mire el teléfono esperando que seas tú.';
        return 'Haz que mire el teléfono esperando que seas tú.';

      case 'fr':
        if (a == 'men') {
          return 'Fais en sorte qu’il regarde son téléphone en espérant que ce soit toi.';
        }
        if (a == 'both') {
          return 'Fais en sorte que cette personne regarde son téléphone en espérant que ce soit toi.';
        }
        return 'Fais en sorte qu’elle regarde son téléphone en espérant que ce soit toi.';

      case 'it':
        if (a == 'men') {
          return 'Fai in modo che guardi il telefono sperando che sia tu.';
        }
        if (a == 'both') {
          return 'Fai in modo che quella persona guardi il telefono sperando che sia tu.';
        }
        return 'Fai in modo che guardi il telefono sperando che sia tu.';

      default:
        if (a == 'men') return 'Make him check his phone hoping it’s you.';
        if (a == 'both') return 'Make them check their phone hoping it’s you.';
        return 'Make her check her phone hoping it’s you.';
    }
  }

  String _buttonLabel(String lang) {
    switch (lang) {
      case 'de':
        return 'Weiter';
      case 'es':
        return 'Continuar';
      case 'pt':
        return 'Continuar';
      case 'fr':
        return 'Continuer';
      case 'it':
        return 'Continua';
      case 'tr':
        return 'Devam et';
      case 'pl':
        return 'Dalej';
      case 'ru':
        return 'Далее';
      case 'ar':
        return 'متابعة';
      default:
        return 'Continue';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(0, 24, 0, 26),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Text(
              _headline(widget.lang),
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Color(0xFF080808),
                fontSize: 30,
                height: 1.10,
                fontWeight: FontWeight.w900,
                letterSpacing: -0.9,
              ),
            ),
          ),

          const SizedBox(height: 24),

          Expanded(
            child: PageView.builder(
              controller: _screensController,
              physics: const BouncingScrollPhysics(),
              itemCount: _screenshots.length,
              onPageChanged: (index) {
                HapticFeedback.selectionClick();

                setState(() {
                  _currentScreenshot = index;
                });
              },
              itemBuilder: (context, index) {
                final selected = index == _currentScreenshot;

                return AnimatedScale(
                  duration: const Duration(milliseconds: 220),
                  curve: Curves.easeOut,
                  scale: selected ? 1.0 : 0.96,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 7),
                    child: Center(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(22),
                        child: Image.asset(
                          _screenshots[index],
                          fit: BoxFit.contain,
                          errorBuilder: (_, __, ___) {
                            return const Center(
                              child: Icon(
                                Icons.image_not_supported_outlined,
                                color: Color(0xFF8E8E93),
                                size: 38,
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),

          const SizedBox(height: 18),

          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(
              _screenshots.length,
              (index) {
                final active = index == _currentScreenshot;

                return AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  width: active ? 22 : 7,
                  height: 7,
                  decoration: BoxDecoration(
                    color: active
                        ? const Color(0xFF111111)
                        : const Color(0xFFD1D1D6),
                    borderRadius: BorderRadius.circular(99),
                  ),
                );
              },
            ),
          ),

          const SizedBox(height: 20),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: SizedBox(
              width: double.infinity,
              height: 60,
              child: ElevatedButton(
                onPressed: () {
                  HapticFeedback.mediumImpact();
                  widget.onContinue();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.black,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                ),
                child: Text(
                  _buttonLabel(widget.lang),
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.15,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}



// ═══════════════════════════════════════════════════════════════════════
// PÁGINA 3 — RECONHECIMENTO
// ═══════════════════════════════════════════════════════════════════════
class _RecognitionPage extends StatelessWidget {
  final String lang;
  final VoidCallback onContinue;

  const _RecognitionPage({
    required this.lang,
    required this.onContinue,
  });

  static const List<String> _messages = [
    'Hey',
    'Wie geht’s?',
    'Was machst du?',
    'Wie war dein Tag?',
    'Du bist hübsch',
    'Was machst du so?',
    'Warum antwortest du mir nicht?',
    'Guten Morgen',
    'Was suchst du hier?',
  ];

  String _title(String lang) {
    switch (lang) {
      case 'de':
        return 'Kommt dir eine davon bekannt vor?';
      case 'pt':
        return 'Alguma delas te parece familiar?';
      case 'es':
        return '¿Alguna te resulta familiar?';
      case 'fr':
        return 'L’une d’elles te semble familière ?';
      case 'it':
        return 'Una di queste ti sembra familiare?';
      default:
        return 'Does any of this look familiar?';
    }
  }

  String _button(String lang) {
    switch (lang) {
      case 'de':
        return 'Weiter';
      case 'pt':
        return 'Continuar';
      case 'es':
        return 'Continuar';
      case 'fr':
        return 'Continuer';
      case 'it':
        return 'Continua';
      default:
        return 'Continue';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 26),
      child: Column(
        children: [
          Text(
            _title(lang),
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Color(0xFF080808),
              fontSize: 30,
              height: 1.10,
              fontWeight: FontWeight.w900,
              letterSpacing: -0.9,
            ),
          ),

          const SizedBox(height: 22),

          Expanded(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 430),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(
                    _messages.length,
                    (index) => Padding(
                      padding: EdgeInsets.only(
                        bottom: index == _messages.length - 1 ? 0 : 8,
                      ),
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 18,
                          vertical: 11,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF5F5F7),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Text(
                          _messages[index],
                          textAlign: TextAlign.center,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Color(0xFF111111),
                            fontSize: 17,
                            height: 1.15,
                            fontWeight: FontWeight.w700,
                            letterSpacing: -0.25,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),

          const SizedBox(height: 20),

          SizedBox(
            width: double.infinity,
            height: 60,
            child: ElevatedButton(
              onPressed: () {
                HapticFeedback.mediumImpact();
                onContinue();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.black,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
              ),
              child: Text(
                _button(lang),
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}


// ═══════════════════════════════════════════════════════════════════════
// PÁGINA 4 — Boas-vindas (design original)
// ═══════════════════════════════════════════════════════════════════════

// ═══════════════════════════════════════════════════════════════════════
// PÁGINA 4 — CONSCIÊNCIA / COMPETIÇÃO
// ═══════════════════════════════════════════════════════════════════════

class _CompetitionAwarenessPage extends StatelessWidget {
  final String lang;
  final String audience;
  final VoidCallback onContinue;

  const _CompetitionAwarenessPage({
    required this.lang,
    required this.audience,
    required this.onContinue,
  });

  String _headline() {
    switch (lang) {
      case 'de':
        if (audience == 'men') return 'Du schreibst ihm nicht allein.';
        if (audience == 'both') {
          return 'Du bist nicht die einzige Person, die um Aufmerksamkeit kämpft.';
        }
        return 'Du schreibst ihr nicht allein.';
      case 'pt':
        if (audience == 'men') {
          return 'Você não é o único que manda mensagem para ele.';
        }
        if (audience == 'both') {
          return 'Você não é a única pessoa tentando chamar atenção.';
        }
        return 'Você não é o único que manda mensagem para ela.';
      default:
        if (audience == 'men') return 'You’re not the only one messaging him.';
        if (audience == 'both') {
          return 'You’re not the only person competing for their attention.';
        }
        return 'You’re not the only one messaging her.';
    }
  }

  String _body() {
    switch (lang) {
      case 'de':
        if (audience == 'men') {
          return 'Während du versuchst, seine Aufmerksamkeit zu bekommen, tun andere genau das Gleiche.';
        }
        if (audience == 'both') {
          return 'Während du versuchst, die Aufmerksamkeit der anderen Person zu bekommen, tun andere genau das Gleiche.';
        }
        return 'Während du versuchst, ihre Aufmerksamkeit zu bekommen, tun andere genau das Gleiche.';
      case 'pt':
        if (audience == 'men') {
          return 'Enquanto você tenta chamar a atenção dele, outras pessoas estão fazendo exatamente a mesma coisa.';
        }
        if (audience == 'both') {
          return 'Enquanto você tenta chamar a atenção da outra pessoa, outras pessoas estão fazendo exatamente a mesma coisa.';
        }
        return 'Enquanto você tenta chamar a atenção dela, outros estão fazendo exatamente a mesma coisa.';
      default:
        if (audience == 'men') {
          return 'While you’re trying to get his attention, others are doing exactly the same thing.';
        }
        if (audience == 'both') {
          return 'While you’re trying to get their attention, others are doing exactly the same thing.';
        }
        return 'While you’re trying to get her attention, others are doing exactly the same thing.';
    }
  }

  String _closing() {
    switch (lang) {
      case 'de':
        return 'Und wenn eure Nachrichten gleich klingen, warum sollte ausgerechnet deine auffallen?';
      case 'pt':
        return 'E se as mensagens de vocês parecem iguais, por que justamente a tua deveria se destacar?';
      default:
        return 'And if all the messages sound the same, why should yours be the one that stands out?';
    }
  }

  String _button() {
    switch (lang) {
      case 'de':
        return 'Weiter';
      case 'pt':
        return 'Continuar';
      default:
        return 'Continue';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(28, 30, 28, 26),
      child: Column(
        children: [
          const Spacer(flex: 2),
          Text(
            _headline(),
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Color(0xFF080808),
              fontSize: 34,
              height: 1.08,
              fontWeight: FontWeight.w900,
              letterSpacing: -1,
            ),
          ),
          const SizedBox(height: 28),
          Text(
            _body(),
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Color(0xFF66666D),
              fontSize: 18,
              height: 1.48,
              fontWeight: FontWeight.w500,
            ),
          ),
          const Spacer(),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: const Color(0xFFF5F5F7),
              borderRadius: BorderRadius.circular(24),
            ),
            child: Text(
              _closing(),
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Color(0xFF111111),
                fontSize: 22,
                height: 1.30,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          const Spacer(flex: 2),
          SizedBox(
            width: double.infinity,
            height: 60,
            child: ElevatedButton(
              onPressed: () {
                HapticFeedback.mediumImpact();
                onContinue();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.black,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
              ),
              child: Text(
                _button(),
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════
// PÁGINA 5 — DESEJO
// ═══════════════════════════════════════════════════════════════════════

class _DesireShiftPage extends StatelessWidget {
  final String lang;
  final String audience;
  final VoidCallback onContinue;

  const _DesireShiftPage({
    required this.lang,
    required this.audience,
    required this.onContinue,
  });

  String _headline() {
    switch (lang) {
      case 'de':
        if (audience == 'men') {
          return 'Stell dir vor, deine Nachricht wäre die, auf die er wartet.';
        }
        if (audience == 'both') {
          return 'Stell dir vor, deine Nachricht wäre genau die, auf die die andere Person wartet.';
        }
        return 'Stell dir vor, deine Nachricht wäre die, auf die sie wartet.';
      case 'pt':
        if (audience == 'men') {
          return 'Imagine se a tua mensagem fosse aquela que ele está esperando.';
        }
        if (audience == 'both') {
          return 'Imagine se a tua mensagem fosse justamente aquela que a outra pessoa está esperando.';
        }
        return 'Imagine se a tua mensagem fosse aquela que ela está esperando.';
      default:
        if (audience == 'men') {
          return 'Imagine if your message was the one he was waiting for.';
        }
        if (audience == 'both') {
          return 'Imagine if your message was the one they were waiting for.';
        }
        return 'Imagine if your message was the one she was waiting for.';
    }
  }

  String _mine() {
    switch (lang) {
      case 'de':
        return 'Nicht irgendeine Nachricht.\nDeine.';
      case 'pt':
        return 'Não qualquer mensagem.\nA tua.';
      default:
        return 'Not just any message.\nYours.';
    }
  }

  String _feeling() {
    switch (lang) {
      case 'de':
        if (audience == 'men') {
          return 'Es geht um dieses Gefühl, wenn du merkst, dass er wirklich mit dir reden will.';
        }
        if (audience == 'both') {
          return 'Es geht um dieses Gefühl, wenn du merkst, dass die andere Person wirklich mit dir reden will.';
        }
        return 'Es geht um dieses Gefühl, wenn du merkst, dass sie wirklich mit dir reden will.';
      case 'pt':
        if (audience == 'men') {
          return 'É sobre aquela sensação de perceber que ele realmente quer falar com você.';
        }
        if (audience == 'both') {
          return 'É sobre aquela sensação de perceber que a outra pessoa realmente quer falar com você.';
        }
        return 'É sobre aquela sensação de perceber que ela realmente quer falar com você.';
      default:
        if (audience == 'men') {
          return 'It’s that feeling when you realize he actually wants to talk to you.';
        }
        if (audience == 'both') {
          return 'It’s that feeling when you realize they actually want to talk to you.';
        }
        return 'It’s that feeling when you realize she actually wants to talk to you.';
    }
  }

  String _closing() {
    switch (lang) {
      case 'de':
        return 'Die richtige Nachricht verändert nicht nur die Antwort.\nSie verändert die ganze Dynamik.';
      case 'pt':
        return 'A mensagem certa não muda apenas a resposta.\nEla muda toda a dinâmica da conversa.';
      default:
        return 'The right message doesn’t just change the reply.\nIt changes the whole dynamic.';
    }
  }

  String _button() {
    switch (lang) {
      case 'de':
        return 'Weiter';
      case 'pt':
        return 'Continuar';
      default:
        return 'Continue';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(28, 30, 28, 26),
      child: Column(
        children: [
          const Spacer(flex: 2),
          Text(
            _headline(),
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Color(0xFF080808),
              fontSize: 33,
              height: 1.08,
              fontWeight: FontWeight.w900,
              letterSpacing: -1,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            _mine(),
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Color(0xFF111111),
              fontSize: 25,
              height: 1.28,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 26),
          Text(
            _feeling(),
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Color(0xFF66666D),
              fontSize: 18,
              height: 1.50,
              fontWeight: FontWeight.w500,
            ),
          ),
          const Spacer(),
          Text(
            _closing(),
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Color(0xFF111111),
              fontSize: 23,
              height: 1.32,
              fontWeight: FontWeight.w800,
            ),
          ),
          const Spacer(flex: 2),
          SizedBox(
            width: double.infinity,
            height: 60,
            child: ElevatedButton(
              onPressed: () {
                HapticFeedback.mediumImpact();
                onContinue();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.black,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
              ),
              child: Text(
                _button(),
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}


// ═══════════════════════════════════════════════════════════════════════
// PÁGINA 6 — DESEJO: PRIMEIRA MENSAGEM DA MANHÃ
// ═══════════════════════════════════════════════════════════════════════

class _MorningMessageDesirePage extends StatelessWidget {
  final String lang;
  final String audience;
  final VoidCallback onContinue;

  const _MorningMessageDesirePage({
    required this.lang,
    required this.audience,
    required this.onContinue,
  });

  String _headline(String lang) {
    switch (lang) {
      case 'de':
        if (audience == 'men') {
          return 'Sorg dafür, dass du die erste Person bist, der er schreiben will, wenn er aufwacht.';
        }
        if (audience == 'both') {
          return 'Sorg dafür, dass du die erste Person bist, der die andere Person schreiben will, wenn sie aufwacht.';
        }
        return 'Sorg dafür, dass du die erste Person bist, der sie schreiben will, wenn sie aufwacht.';

      case 'pt':
        if (audience == 'men') {
          return 'Faça com que você seja a primeira pessoa para quem ele queira mandar mensagem quando acordar.';
        }
        if (audience == 'both') {
          return 'Faça com que você seja a primeira pessoa para quem a outra pessoa queira mandar mensagem quando acordar.';
        }
        return 'Faça com que você seja a primeira pessoa para quem ela queira mandar mensagem quando acordar.';

      default:
        if (audience == 'men') {
          return 'Make yourself the first person he wants to text when he wakes up.';
        }
        if (audience == 'both') {
          return 'Make yourself the first person they want to text when they wake up.';
        }
        return 'Make yourself the first person she wants to text when she wakes up.';
    }
  }

  String _button(String lang) {
    switch (lang) {
      case 'de':
        return 'Weiter';
      case 'pt':
        return 'Continuar';
      case 'es':
        return 'Continuar';
      case 'fr':
        return 'Continuer';
      case 'it':
        return 'Continua';
      case 'tr':
        return 'Devam et';
      case 'pl':
        return 'Dalej';
      case 'ru':
        return 'Далее';
      case 'ar':
        return 'متابعة';
      default:
        return 'Continue';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(28, 30, 28, 26),
      child: Column(
        children: [
          const Spacer(),

          Text(
            _headline(lang),
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Color(0xFF080808),
              fontSize: 36,
              height: 1.10,
              fontWeight: FontWeight.w900,
              letterSpacing: -1.1,
            ),
          ),

          const Spacer(),

          SizedBox(
            width: double.infinity,
            height: 60,
            child: ElevatedButton(
              onPressed: () {
                HapticFeedback.mediumImpact();
                onContinue();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.black,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
              ),
              child: Text(
                _button(lang),
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}




// ═══════════════════════════════════════════════════════════════════════
// TELA 2 — PÚBLICO / PRONOMES PARA PERSONALIZAR O STORYTELLING
// ═══════════════════════════════════════════════════════════════════════

class _AudienceChoicePage extends StatefulWidget {
  final String lang;
  final String initialAudience;
  final ValueChanged<String> onSelected;
  final VoidCallback onContinue;

  const _AudienceChoicePage({
    required this.lang,
    required this.initialAudience,
    required this.onSelected,
    required this.onContinue,
  });

  @override
  State<_AudienceChoicePage> createState() => _AudienceChoicePageState();
}

class _AudienceChoicePageState extends State<_AudienceChoicePage> {
  late String selected;

  @override
  void initState() {
    super.initState();
    selected = widget.initialAudience;
  }

  @override
  Widget build(BuildContext context) {
    final isDe = widget.lang == 'de';
    final isPt = widget.lang == 'pt';

    final title = isDe
        ? 'Mit wem möchtest du deine Gespräche verbessern?'
        : isPt
            ? 'Com quem você quer melhorar suas conversas?'
            : 'Who do you want to improve your conversations with?';

    final options = [
      (
        value: 'women',
        label: isDe ? '👩 Frauen' : isPt ? '👩 Mulheres' : '👩 Women',
      ),
      (
        value: 'men',
        label: isDe ? '👨 Männer' : isPt ? '👨 Homens' : '👨 Men',
      ),
      (
        value: 'both',
        label: isDe ? '🫶 Beide' : isPt ? '🫶 Ambos' : '🫶 Both',
      ),
    ];

    return _QuestionScaffold(
      title: title,
      buttonLabel: isDe ? 'Weiter' : isPt ? 'Continuar' : 'Continue',
      buttonEnabled: true,
      onContinue: () {
        widget.onSelected(selected);
        widget.onContinue();
      },
      child: ListView.separated(
        padding: EdgeInsets.zero,
        itemCount: options.length,
        separatorBuilder: (_, __) => const SizedBox(height: 10),
        itemBuilder: (_, index) {
          final option = options[index];
          final active = selected == option.value;

          return _ChoiceTile(
            text: option.label,
            active: active,
            trailing: active ? Icons.check_rounded : null,
            onTap: () {
              HapticFeedback.selectionClick();
              setState(() => selected = option.value);
              widget.onSelected(option.value);
            },
          );
        },
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════
// TELAS DE PERSONALIZAÇÃO REUTILIZÁVEIS
// ═══════════════════════════════════════════════════════════════════════

class _SingleChoicePage extends StatefulWidget {
  final String lang;
  final String titlePt;
  final String titleDe;
  final List<String> optionsPt;
  final List<String> optionsDe;
  final VoidCallback onContinue;

  const _SingleChoicePage({
    required this.lang,
    required this.titlePt,
    required this.titleDe,
    required this.optionsPt,
    required this.optionsDe,
    required this.onContinue,
  });

  @override
  State<_SingleChoicePage> createState() => _SingleChoicePageState();
}

class _SingleChoicePageState extends State<_SingleChoicePage> {
  int? selected;

  @override
  Widget build(BuildContext context) {
    final isDe = widget.lang == 'de';
    final options = isDe ? widget.optionsDe : widget.optionsPt;
    final title = isDe ? widget.titleDe : widget.titlePt;

    return _QuestionScaffold(
      title: title,
      buttonLabel: isDe ? 'Weiter' : 'Continuar',
      buttonEnabled: selected != null,
      onContinue: widget.onContinue,
      child: ListView.separated(
        padding: EdgeInsets.zero,
        itemCount: options.length,
        separatorBuilder: (_, __) => const SizedBox(height: 10),
        itemBuilder: (_, index) {
          final active = selected == index;
          return _ChoiceTile(
            text: options[index],
            active: active,
            onTap: () {
              HapticFeedback.selectionClick();
              setState(() => selected = index);
            },
          );
        },
      ),
    );
  }
}

class _MultiChoicePage extends StatefulWidget {
  final String lang;
  final String titlePt;
  final String titleDe;
  final List<String>? options;
  final List<String>? optionsPt;
  final List<String>? optionsDe;
  final int maxSelections;
  final VoidCallback onContinue;

  const _MultiChoicePage({
    required this.lang,
    required this.titlePt,
    required this.titleDe,
    this.options,
    this.optionsPt,
    this.optionsDe,
    required this.maxSelections,
    required this.onContinue,
  });

  @override
  State<_MultiChoicePage> createState() => _MultiChoicePageState();
}

class _MultiChoicePageState extends State<_MultiChoicePage> {
  final Set<int> selected = {};

  @override
  Widget build(BuildContext context) {
    final isDe = widget.lang == 'de';
    final options = widget.options ??
        (isDe ? (widget.optionsDe ?? const []) : (widget.optionsPt ?? const []));

    return _QuestionScaffold(
      title: isDe ? widget.titleDe : widget.titlePt,
      subtitle: isDe
          ? 'Wähle bis zu ${widget.maxSelections}.'
          : 'Escolha até ${widget.maxSelections}.',
      buttonLabel: isDe ? 'Weiter' : 'Continuar',
      buttonEnabled: selected.isNotEmpty,
      onContinue: widget.onContinue,
      child: ListView.separated(
        padding: EdgeInsets.zero,
        itemCount: options.length,
        separatorBuilder: (_, __) => const SizedBox(height: 10),
        itemBuilder: (_, index) {
          final active = selected.contains(index);
          return _ChoiceTile(
            text: options[index],
            active: active,
            trailing: active ? Icons.check_rounded : null,
            onTap: () {
              HapticFeedback.selectionClick();
              setState(() {
                if (active) {
                  selected.remove(index);
                } else if (selected.length < widget.maxSelections) {
                  selected.add(index);
                }
              });
            },
          );
        },
      ),
    );
  }
}

class _QuestionScaffold extends StatelessWidget {
  final String title;
  final String? subtitle;
  final Widget child;
  final String buttonLabel;
  final bool buttonEnabled;
  final VoidCallback onContinue;

  const _QuestionScaffold({
    required this.title,
    this.subtitle,
    required this.child,
    required this.buttonLabel,
    required this.buttonEnabled,
    required this.onContinue,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 26),
      child: Column(
        children: [
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Color(0xFF080808),
              fontSize: 29,
              height: 1.10,
              fontWeight: FontWeight.w900,
              letterSpacing: -0.85,
            ),
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 9),
            Text(
              subtitle!,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Color(0xFF8E8E93),
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
          const SizedBox(height: 24),
          Expanded(child: child),
          const SizedBox(height: 18),
          SizedBox(
            width: double.infinity,
            height: 60,
            child: ElevatedButton(
              onPressed: buttonEnabled
                  ? () {
                      HapticFeedback.mediumImpact();
                      onContinue();
                    }
                  : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.black,
                disabledBackgroundColor: const Color(0xFFE5E5EA),
                foregroundColor: Colors.white,
                disabledForegroundColor: const Color(0xFF9A9A9F),
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
              ),
              child: Text(
                buttonLabel,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ChoiceTile extends StatelessWidget {
  final String text;
  final bool active;
  final VoidCallback onTap;
  final IconData? trailing;

  const _ChoiceTile({
    required this.text,
    required this.active,
    required this.onTap,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: active ? const Color(0xFF111111) : const Color(0xFFF5F5F7),
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          constraints: const BoxConstraints(minHeight: 58),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 15),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  text,
                  style: TextStyle(
                    color: active ? Colors.white : const Color(0xFF111111),
                    fontSize: 16.5,
                    height: 1.20,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.2,
                  ),
                ),
              ),
              if (trailing != null)
                Icon(trailing, color: Colors.white, size: 22),
            ],
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════
// TELA 8 — INTRODUÇÃO À PERSONALIZAÇÃO
// ═══════════════════════════════════════════════════════════════════════

class _QuestionIntroPage extends StatelessWidget {
  final String lang;
  final VoidCallback onContinue;

  const _QuestionIntroPage({
    required this.lang,
    required this.onContinue,
  });

  @override
  Widget build(BuildContext context) {
    final isDe = lang == 'de';

    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(28, 30, 28, 26),
      child: Column(
        children: [
          const Spacer(flex: 2),
          Text(
            isDe
                ? 'Bevor wir weitermachen, habe ich ein paar wichtige Fragen an dich.'
                : 'Antes de continuarmos, tenho algumas perguntas importantes para você.',
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Color(0xFF080808),
              fontSize: 32,
              height: 1.10,
              fontWeight: FontWeight.w900,
              letterSpacing: -0.95,
            ),
          ),
          const SizedBox(height: 30),
          Text(
            isDe
                ? 'Je ehrlicher du antwortest, desto persönlicher und relevanter kann deine Erfahrung werden.'
                : 'Quanto mais honestas forem as suas respostas, mais pessoal e relevante a experiência pode se tornar.',
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Color(0xFF66666D),
              fontSize: 18,
              height: 1.48,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            isDe
                ? 'Deine Antworten werden vertraulich behandelt.'
                : 'Suas respostas são tratadas com privacidade.',
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Color(0xFF111111),
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
          const Spacer(flex: 3),
          SizedBox(
            width: double.infinity,
            height: 60,
            child: ElevatedButton(
              onPressed: () {
                HapticFeedback.mediumImpact();
                onContinue();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.black,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
              ),
              child: Text(
                isDe ? 'Weiter' : 'Continuar',
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════
// TELA 15 — CONFIANÇA
// ═══════════════════════════════════════════════════════════════════════

class _ConfidencePage extends StatefulWidget {
  final String lang;
  final VoidCallback onContinue;

  const _ConfidencePage({
    required this.lang,
    required this.onContinue,
  });

  @override
  State<_ConfidencePage> createState() => _ConfidencePageState();
}

class _ConfidencePageState extends State<_ConfidencePage> {
  int? selected;

  @override
  Widget build(BuildContext context) {
    final isDe = widget.lang == 'de';

    return _QuestionScaffold(
      title: isDe
          ? 'Wie selbstsicher fühlst du dich, wenn du mit jemandem schreibst, an dem du wirklich interessiert bist?'
          : 'Quão confiante você se sente quando conversa com alguém por quem realmente se interessa?',
      buttonLabel: isDe ? 'Weiter' : 'Continuar',
      buttonEnabled: selected != null,
      onContinue: widget.onContinue,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            children: List.generate(5, (index) {
              final number = index + 1;
              final active = selected == number;
              return Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(18),
                    onTap: () {
                      HapticFeedback.selectionClick();
                      setState(() => selected = number);
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 160),
                      height: 64,
                      decoration: BoxDecoration(
                        color: active ? Colors.black : const Color(0xFFF5F5F7),
                        borderRadius: BorderRadius.circular(18),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        '$number',
                        style: TextStyle(
                          color: active ? Colors.white : const Color(0xFF111111),
                          fontSize: 23,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  ),
                ),
              );
            }),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: Text(
                  isDe ? 'Gar nicht selbstsicher' : 'Nada confiante',
                  style: const TextStyle(
                    color: Color(0xFF8E8E93),
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Expanded(
                child: Text(
                  isDe ? 'Sehr selbstsicher' : 'Muito confiante',
                  textAlign: TextAlign.right,
                  style: const TextStyle(
                    color: Color(0xFF8E8E93),
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════
// TELA 16 — PONTE DE PERSONALIZAÇÃO
// ═══════════════════════════════════════════════════════════════════════

class _PersonalizationBridgePage extends StatefulWidget {
  final String lang;
  final VoidCallback onContinue;

  const _PersonalizationBridgePage({
    required this.lang,
    required this.onContinue,
  });

  @override
  State<_PersonalizationBridgePage> createState() =>
      _PersonalizationBridgePageState();
}

class _PersonalizationBridgePageState
    extends State<_PersonalizationBridgePage>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulseController;
  Timer? _progressTimer;

  int _progress = 0;
  bool _done = false;

  @override
  void initState() {
    super.initState();

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
      lowerBound: 0.94,
      upperBound: 1.06,
    )..repeat(reverse: true);

    _progressTimer = Timer.periodic(
      const Duration(milliseconds: 55),
      (timer) {
        if (!mounted) {
          timer.cancel();
          return;
        }

        if (_progress >= 100) {
          timer.cancel();

          setState(() {
            _progress = 100;
            _done = true;
          });

          HapticFeedback.mediumImpact();
          return;
        }

        setState(() {
          _progress++;
        });
      },
    );
  }

  @override
  void dispose() {
    _progressTimer?.cancel();
    _pulseController.dispose();
    super.dispose();
  }

  String _title() {
    switch (widget.lang) {
      case 'de':
        return 'Wir bereiten deine Erfahrung vor.';
      case 'pt':
        return 'Estamos preparando sua experiência.';
      case 'es':
        return 'Estamos preparando tu experiencia.';
      case 'fr':
        return 'Nous préparons ton expérience.';
      case 'it':
        return 'Stiamo preparando la tua esperienza.';
      default:
        return 'We’re preparing your experience.';
    }
  }

  String _status() {
    if (_done) {
      switch (widget.lang) {
        case 'de':
          return 'Alles bereit.';
        case 'pt':
          return 'Tudo pronto.';
        case 'es':
          return 'Todo listo.';
        case 'fr':
          return 'Tout est prêt.';
        case 'it':
          return 'Tutto pronto.';
        default:
          return 'All set.';
      }
    }

    if (_progress < 30) {
      switch (widget.lang) {
        case 'de':
          return 'Deine Antworten werden ausgewertet...';
        case 'pt':
          return 'Analisando suas respostas...';
        case 'es':
          return 'Analizando tus respuestas...';
        case 'fr':
          return 'Analyse de tes réponses...';
        case 'it':
          return 'Analisi delle tue risposte...';
        default:
          return 'Reviewing your answers...';
      }
    }

    if (_progress < 65) {
      switch (widget.lang) {
        case 'de':
          return 'Wir verstehen deinen Gesprächsstil...';
        case 'pt':
          return 'Entendendo seu estilo de conversa...';
        case 'es':
          return 'Entendiendo tu estilo de conversación...';
        case 'fr':
          return 'Compréhension de ton style de conversation...';
        case 'it':
          return 'Stiamo capendo il tuo stile di conversazione...';
        default:
          return 'Understanding your conversation style...';
      }
    }

    switch (widget.lang) {
      case 'de':
        return 'Deine Erfahrung wird angepasst...';
      case 'pt':
        return 'Ajustando sua experiência...';
      case 'es':
        return 'Ajustando tu experiencia...';
      case 'fr':
        return 'Ajustement de ton expérience...';
      case 'it':
        return 'Personalizzazione della tua esperienza...';
      default:
        return 'Tailoring your experience...';
    }
  }

  String _button() {
    switch (widget.lang) {
      case 'de':
        return 'Weiter';
      case 'pt':
        return 'Continuar';
      case 'es':
        return 'Continuar';
      case 'fr':
        return 'Continuer';
      case 'it':
        return 'Continua';
      default:
        return 'Continue';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(28, 30, 28, 26),
      child: Column(
        children: [
          Text(
            _title(),
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Color(0xFF080808),
              fontSize: 32,
              height: 1.10,
              fontWeight: FontWeight.w900,
              letterSpacing: -0.95,
            ),
          ),

          const Spacer(),

          AnimatedBuilder(
            animation: _pulseController,
            builder: (_, child) {
              return Transform.scale(
                scale: _done ? 1.0 : _pulseController.value,
                child: child,
              );
            },
            child: Container(
              width: 178,
              height: 178,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFFF5F5F7),
                border: Border.all(
                  color: _done
                      ? const Color(0xFF34C759)
                      : const Color(0xFF111111),
                  width: 3,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.06),
                    blurRadius: 24,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Center(
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 220),
                  child: _done
                      ? const Icon(
                          Icons.check_rounded,
                          key: ValueKey('done'),
                          color: Color(0xFF34C759),
                          size: 68,
                        )
                      : Text(
                          '$_progress%',
                          key: ValueKey(_progress),
                          style: const TextStyle(
                            color: Color(0xFF111111),
                            fontSize: 40,
                            fontWeight: FontWeight.w900,
                            letterSpacing: -1.1,
                          ),
                        ),
                ),
              ),
            ),
          ),

          const SizedBox(height: 30),

          AnimatedSwitcher(
            duration: const Duration(milliseconds: 250),
            child: Text(
              _status(),
              key: ValueKey('${_done}_$_progress'),
              textAlign: TextAlign.center,
              style: TextStyle(
                color: _done
                    ? const Color(0xFF111111)
                    : const Color(0xFF66666D),
                fontSize: 17,
                height: 1.45,
                fontWeight: _done
                    ? FontWeight.w800
                    : FontWeight.w500,
              ),
            ),
          ),

          const Spacer(),

          SizedBox(
            width: double.infinity,
            height: 60,
            child: ElevatedButton(
              onPressed: _done
                  ? () {
                      HapticFeedback.mediumImpact();
                      widget.onContinue();
                    }
                  : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.black,
                disabledBackgroundColor: const Color(0xFFE5E5EA),
                foregroundColor: Colors.white,
                disabledForegroundColor: const Color(0xFF9A9A9F),
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
              ),
              child: Text(
                _button(),
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}


// ═══════════════════════════════════════════════════════════════════════
// TELA 17 — ENTENDENDO O JEITO DE CONVERSAR
// ═══════════════════════════════════════════════════════════════════════

class _UnderstandingYouPage extends StatelessWidget {
  final String lang;
  final VoidCallback onContinue;

  const _UnderstandingYouPage({
    required this.lang,
    required this.onContinue,
  });

  String _headline() {
    switch (lang) {
      case 'de':
        return 'Wir beginnen zu verstehen, wie du kommunizierst.';
      case 'pt':
        return 'Já estamos começando a entender o seu jeito de conversar.';
      case 'es':
        return 'Ya estamos empezando a entender tu forma de conversar.';
      case 'fr':
        return 'Nous commençons à comprendre ta façon de communiquer.';
      case 'it':
        return 'Stiamo iniziando a capire il tuo modo di comunicare.';
      default:
        return 'We’re starting to understand how you communicate.';
    }
  }

  String _bodyOne() {
    switch (lang) {
      case 'de':
        return 'Was für jemand anderen funktioniert, muss nicht unbedingt zu dir passen.';
      case 'pt':
        return 'O que funciona para uma pessoa pode não funcionar para você.';
      case 'es':
        return 'Lo que funciona para otra persona puede no funcionar para ti.';
      case 'fr':
        return 'Ce qui fonctionne pour quelqu’un d’autre ne fonctionnera pas forcément pour toi.';
      case 'it':
        return 'Ciò che funziona per qualcun altro potrebbe non funzionare per te.';
      default:
        return 'What works for someone else may not work for you.';
    }
  }

  String _bodyTwo() {
    switch (lang) {
      case 'de':
        return 'Deine Nachrichten sollten zu dir, deinen Absichten und der Person auf der anderen Seite passen.';
      case 'pt':
        return 'Suas conversas precisam combinar com o seu jeito, suas intenções e a pessoa do outro lado.';
      case 'es':
        return 'Tus conversaciones deben encajar con tu forma de ser, tus intenciones y la persona al otro lado.';
      case 'fr':
        return 'Tes conversations doivent correspondre à ta façon d’être, à tes intentions et à la personne en face.';
      case 'it':
        return 'Le tue conversazioni devono rispecchiare il tuo modo di essere, le tue intenzioni e la persona dall’altra parte.';
      default:
        return 'Your conversations should fit your style, your intentions, and the person on the other side.';
    }
  }

  String _button() {
    switch (lang) {
      case 'de':
        return 'Weiter';
      case 'pt':
        return 'Continuar';
      case 'es':
        return 'Continuar';
      case 'fr':
        return 'Continuer';
      case 'it':
        return 'Continua';
      default:
        return 'Continue';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(28, 30, 28, 26),
      child: Column(
        children: [
          const Spacer(flex: 2),

          Text(
            _headline(),
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Color(0xFF080808),
              fontSize: 32,
              height: 1.10,
              fontWeight: FontWeight.w900,
              letterSpacing: -0.95,
            ),
          ),

          const SizedBox(height: 30),

          Text(
            _bodyOne(),
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Color(0xFF66666D),
              fontSize: 18,
              height: 1.48,
              fontWeight: FontWeight.w500,
            ),
          ),

          const SizedBox(height: 24),

          Text(
            _bodyTwo(),
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Color(0xFF111111),
              fontSize: 18,
              height: 1.45,
              fontWeight: FontWeight.w700,
            ),
          ),

          const Spacer(flex: 3),

          SizedBox(
            width: double.infinity,
            height: 60,
            child: ElevatedButton(
              onPressed: () {
                HapticFeedback.mediumImpact();
                onContinue();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.black,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
              ),
              child: Text(
                _button(),
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════
// TELA 19 — PROVA SOCIAL
//
// Observação:
// Os textos abaixo NÃO inventam número de utilizadores ou avaliações.
// São apresentados como exemplos de experiências de utilizadores.
// Substitui-os por reviews reais assim que tiveres os textos finais.
// ═══════════════════════════════════════════════════════════════════════

class _SocialProofPage extends StatelessWidget {
  final String lang;
  final VoidCallback onContinue;

  const _SocialProofPage({
    required this.lang,
    required this.onContinue,
  });

  static const List<String> _heroPhotos = [
    'assets/images/social_1.jpg',
    'assets/images/social_2.jpg',
    'assets/images/social_3.jpg',
    'assets/images/social_4.jpg',
    'assets/images/social_5.jpg',
    'assets/images/social_6.jpg',
  ];

  static const List<String> _reviewPhotos = [
    'assets/images/review_1.jpg',
    'assets/images/review_2.jpg',
    'assets/images/review_3.jpg',
  ];

  String _headline() {
    switch (lang) {
      case 'de':
        return 'Du bist nicht der Einzige, der besser schreiben will.';
      case 'pt':
        return 'Você não é o único que quer conversar melhor.';
      case 'es':
        return 'No eres el único que quiere conversar mejor.';
      case 'fr':
        return 'Tu n’es pas le seul à vouloir mieux communiquer.';
      case 'it':
        return 'Non sei l’unico che vuole comunicare meglio.';
      default:
        return 'You’re not the only one who wants to communicate better.';
    }
  }

  String _button() {
    switch (lang) {
      case 'de':
        return 'Weiter';
      case 'pt':
        return 'Continuar';
      case 'es':
        return 'Continuar';
      case 'fr':
        return 'Continuer';
      case 'it':
        return 'Continua';
      default:
        return 'Continue';
    }
  }

  List<Map<String, String>> _reviews() {
    switch (lang) {
      case 'de':
        return const [
          {
            'name': 'Lucas',
            'age': '18',
            'text': 'Ich denke viel weniger darüber nach, was ich als Nächstes schreiben soll.',
          },
          {
            'name': 'Matteo',
            'age': '19',
            'text': 'Meine Gespräche fühlen sich inzwischen viel natürlicher an.',
          },
          {
            'name': 'Sofia',
            'age': '24',
            'text': 'Ich bin beim Schreiben deutlich selbstsicherer geworden.',
          },
        ];
      case 'pt':
        return const [
          {
            'name': 'Lucas',
            'age': '18',
            'text': 'Penso muito menos no que devo mandar a seguir.',
          },
          {
            'name': 'Matteo',
            'age': '19',
            'text': 'Minhas conversas começaram a parecer muito mais naturais.',
          },
          {
            'name': 'Sofia',
            'age': '24',
            'text': 'Passei a me sentir muito mais confiante ao conversar.',
          },
        ];
      default:
        return const [
          {
            'name': 'Lucas',
            'age': '18',
            'text': 'I overthink what to send next much less now.',
          },
          {
            'name': 'Matteo',
            'age': '19',
            'text': 'My conversations feel much more natural now.',
          },
          {
            'name': 'Sofia',
            'age': '24',
            'text': 'I feel much more confident when I text.',
          },
        ];
    }
  }

  @override
  Widget build(BuildContext context) {
    final reviews = _reviews();

    return Container(
      color: Colors.white,
      child: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 20),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 28),
              child: Text(
                _headline(),
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Color(0xFF080808),
                  fontSize: 31,
                  height: 1.08,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -0.95,
                ),
              ),
            ),

            const SizedBox(height: 18),

            Expanded(
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  // ───────────────────────────────────────────────────
                  // 6 FOTOS — 3 x 2, exatamente como referência
                  // ───────────────────────────────────────────────────
                  Positioned(
                    left: 0,
                    right: 0,
                    top: 0,
                    height: 330,
                    child: GridView.builder(
                      padding: EdgeInsets.zero,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 3,
                        crossAxisSpacing: 0,
                        mainAxisSpacing: 0,
                        childAspectRatio: 0.82,
                      ),
                      itemCount: _heroPhotos.length,
                      itemBuilder: (_, index) {
                        return Image.asset(
                          _heroPhotos[index],
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Container(
                            color: const Color(0xFFEDEDEF),
                            alignment: Alignment.center,
                            child: const Icon(
                              Icons.person_rounded,
                              color: Color(0xFFB3B3B8),
                              size: 38,
                            ),
                          ),
                        );
                      },
                    ),
                  ),

                  // ───────────────────────────────────────────────────
                  // FADE — desaparecimento da base das fotos
                  // ───────────────────────────────────────────────────
                  Positioned(
                    left: 0,
                    right: 0,
                    top: 215,
                    height: 165,
                    child: IgnorePointer(
                      child: Container(
                        decoration: const BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Color(0x00FFFFFF),
                              Color(0x66FFFFFF),
                              Color(0xD9FFFFFF),
                              Color(0xFFFFFFFF),
                            ],
                            stops: [0.0, 0.34, 0.70, 1.0],
                          ),
                        ),
                      ),
                    ),
                  ),

                  // ───────────────────────────────────────────────────
                  // REVIEWS — sobrepostos, como na referência
                  // ───────────────────────────────────────────────────
                  Positioned(
                    left: 22,
                    right: 22,
                    top: 285,
                    bottom: 6,
                    child: PageView.builder(
                      scrollDirection: Axis.vertical,
                      physics: const BouncingScrollPhysics(),
                      controller: PageController(viewportFraction: 0.48),
                      itemCount: reviews.length,
                      itemBuilder: (_, index) {
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 5),
                          child: _ReviewCard(
                            photo: _reviewPhotos[index],
                            name: reviews[index]['name']!,
                            age: reviews[index]['age']!,
                            text: reviews[index]['text']!,
                          ),
                        );
                      },
                    ),
                  ),

                  // Setas decorativas/laterais como na referência.
                ],
              ),
            ),

            Padding(
              padding: const EdgeInsets.fromLTRB(24, 12, 24, 18),
              child: SizedBox(
                width: double.infinity,
                height: 60,
                child: ElevatedButton(
                  onPressed: () {
                    HapticFeedback.mediumImpact();
                    onContinue();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF08101F),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                  ),
                  child: Text(
                    _button(),
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ReviewCard extends StatelessWidget {
  final String photo;
  final String name;
  final String age;
  final String text;

  const _ReviewCard({
    required this.photo,
    required this.name,
    required this.age,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      constraints: const BoxConstraints(minHeight: 132),
      padding: const EdgeInsets.fromLTRB(14, 14, 16, 14),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.96),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: const Color(0xFFE8E8EB),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.055),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          ClipOval(
            child: Image.asset(
              photo,
              width: 74,
              height: 74,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(
                width: 74,
                height: 74,
                color: const Color(0xFFEDEDEF),
                alignment: Alignment.center,
                child: const Icon(
                  Icons.person_rounded,
                  color: Color(0xFFAAAAAF),
                  size: 34,
                ),
              ),
            ),
          ),

          const SizedBox(width: 14),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.star_rounded,
                        color: Color(0xFFFFB41F), size: 18),
                    Icon(Icons.star_rounded,
                        color: Color(0xFFFFB41F), size: 18),
                    Icon(Icons.star_rounded,
                        color: Color(0xFFFFB41F), size: 18),
                    Icon(Icons.star_rounded,
                        color: Color(0xFFFFB41F), size: 18),
                    Icon(Icons.star_rounded,
                        color: Color(0xFFFFB41F), size: 18),
                  ],
                ),

                const SizedBox(height: 6),

                Text(
                  '“$text”',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xFF111111),
                    fontSize: 14.5,
                    height: 1.32,
                    fontWeight: FontWeight.w500,
                  ),
                ),

                const SizedBox(height: 4),

                Text.rich(
                  TextSpan(
                    children: [
                      TextSpan(
                        text: '$name, ',
                        style: const TextStyle(
                          color: Color(0xFF111111),
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      TextSpan(
                        text: '$age anos',
                        style: const TextStyle(
                          color: Color(0xFF66666D),
                          fontSize: 15,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

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
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          minHeight: MediaQuery.of(context).size.height -
            MediaQuery.of(context).padding.top -
            MediaQuery.of(context).padding.bottom),
        child: IntrinsicHeight(
          child: Column(
            children: [
              const Spacer(flex: 2),
              const Text('🌶️', style: TextStyle(fontSize: 64)),
              const SizedBox(height: 28),
              _TypewriterText(
                text: title(),
                fontSize: 34,
                fontWeight: FontWeight.w900,
                letterSpacing: -0.8,
                height: 1.15,
                textAlign: TextAlign.center,
                speedMs: 90,
                withHaptics: true,
              ),
              const Spacer(flex: 2),
              ...List.generate(features().length, (index) {
                final f = features()[index];
                final visible = index < visibleFeatures;
                return AnimatedOpacity(
                  duration: const Duration(milliseconds: 400),
                  opacity: visible ? 1.0 : 0.0,
                  child: AnimatedSlide(
                    duration: const Duration(milliseconds: 400),
                    offset: visible ? Offset.zero : const Offset(0, 0.15),
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 24),
                      child: Row(children: [
                        Text(f['icon']!, style: const TextStyle(fontSize: 28)),
                        const SizedBox(width: 16),
                        Expanded(
                          child: visible
                            ? _TypewriterText(text: f['text']!, speedMs: 70)
                            : const SizedBox.shrink()),
                      ]),
                    ),
                  ),
                );
              }),
              const Spacer(flex: 3),
              RichText(
                textAlign: TextAlign.center,
                text: TextSpan(
                  style: const TextStyle(color: Colors.white54, fontSize: 12, height: 1.4),
                  children: termsSpans())),
              const SizedBox(height: 14),
              SizedBox(
                width: double.infinity,
                height: 58,
                child: ElevatedButton(
                  onPressed: onFinish,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF34C759),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    elevation: 0),
                  child: Text(btnLabel(),
                    style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800)))),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
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
