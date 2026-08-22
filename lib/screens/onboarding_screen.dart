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
  String _userName = '';
  String? _audience; // women | men | both — começa sem seleção
  String? _age;
  List<String> _platforms = [];
  String? _pain;
  List<String> _desires = [];
  String? _reaction;
  String? _stuckMoment;
  int? _confidence;

  @override
  void initState() {
    super.initState();
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark, // Android
        statusBarBrightness: Brightness.light,    // iOS
        systemNavigationBarColor: Colors.white,
        systemNavigationBarIconBrightness: Brightness.dark,
        systemNavigationBarDividerColor: Colors.transparent,
      ),
    );
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

        return AnnotatedRegion<SystemUiOverlayStyle>(
          value: const SystemUiOverlayStyle(
            statusBarColor: Colors.transparent,
            statusBarIconBrightness: Brightness.dark, // Android
            statusBarBrightness: Brightness.light,    // iOS
            systemNavigationBarColor: Colors.white,
            systemNavigationBarIconBrightness: Brightness.dark,
            systemNavigationBarDividerColor: Colors.transparent,
          ),
          child: Scaffold(
            backgroundColor: Colors.white,
            body: SafeArea(
            child: Stack(
              children: [
                Padding(
                  padding: EdgeInsets.only(top: _currentPage == 0 ? 0 : 68),
                  child: PageView(
                    controller: _pageController,
                    physics: const NeverScrollableScrollPhysics(),
                    onPageChanged: (i) => setState(() => _currentPage = i),
                    children: [
                // 1
                _FeatureShowcasePage(lang: lang, onContinue: _goNext),

                // 2 — Nome
                _NamePage(
                  lang: lang,
                  initialName: _userName,
                  onNameChanged: (value) {
                    setState(() => _userName = value.trim());
                  },
                  onContinue: _goNext,
                ),

                // 3 — Com quem conversa
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
                  audience: _audience ?? 'both',
                  onContinue: _goNext,
                ),

                // 4
                _RecognitionPage(lang: lang, onContinue: _goNext),

                // 5
                _CompetitionAwarenessPage(
                  lang: lang,
                  audience: _audience ?? 'both',
                  onContinue: _goNext,
                ),

                // 6
                _DesireShiftPage(
                  lang: lang,
                  audience: _audience ?? 'both',
                  onContinue: _goNext,
                ),

                // 7
                _MorningMessageDesirePage(
                  lang: lang,
                  audience: _audience ?? 'both',
                  onContinue: _goNext,
                ),

                // 8 — Introdução às perguntas
                _QuestionIntroPage(lang: lang, userName: _userName, onContinue: _goNext),

                // 9 — Idade
                _SingleChoicePage(
                  lang: lang,
                  titlePt: 'Quantos anos você tem?',
                  titleDe: 'Wie alt bist du?',
                  optionsPt: const ['18–20', '21–24', '25–29', '30–34', '35–44', '45+'],
                  optionsDe: const ['18–20', '21–24', '25–29', '30–34', '35–44', '45+'],
                  centerOptions: true,
                  onSelected: (value) => setState(() => _age = value),
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
                  onSelected: (values) => setState(() => _platforms = values),
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
                  onSelected: (value) => setState(() => _pain = value),
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
                  onSelected: (values) => setState(() => _desires = values),
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
                  onSelected: (value) => setState(() => _reaction = value),
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
                  onSelected: (value) => setState(() => _stuckMoment = value),
                  onContinue: _goNext,
                ),

                // 15 — Confiança
                _ConfidencePage(
                  lang: lang,
                  onSelected: (value) => setState(() => _confidence = value),
                  onContinue: _goNext,
                ),

                // 16 — Preparando experiência (0% → 100%)
                _PersonalizationBridgePage(
                  lang: lang,
                  userName: _userName,
                  audience: _audience,
                  age: _age,
                  platforms: _platforms,
                  pain: _pain,
                  desires: _desires,
                  reaction: _reaction,
                  stuckMoment: _stuckMoment,
                  confidence: _confidence,
                  onContinue: _goNext,
                ),

                // 17 — Já estamos começando a entender você
                _UnderstandingYouPage(
                  lang: lang,
                  userName: _userName,
                  onContinue: _goNext,
                ),

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
                if (_currentPage > 0 && _currentPage < 20)
                  Positioned(
                    left: 22,
                    right: 22,
                    top: 10,
                    child: Row(
                      children: [
                        Material(
                          color: const Color(0xFFF7F7FA),
                          shape: const CircleBorder(),
                          child: InkWell(
                            customBorder: const CircleBorder(),
                            onTap: () {
                              HapticFeedback.lightImpact();
                              _pageController.previousPage(
                                duration: const Duration(milliseconds: 350),
                                curve: Curves.easeOutCubic,
                              );
                            },
                            child: const SizedBox(
                              width: 46,
                              height: 46,
                              child: Icon(
                                Icons.arrow_back_rounded,
                                color: Color(0xFF19151F),
                                size: 25,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 22),
                        Expanded(
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(99),
                            child: LinearProgressIndicator(
                              value: (_currentPage + 1) / 21,
                              minHeight: 5,
                              backgroundColor: const Color(0xFFE8E8EA),
                              valueColor: const AlwaysStoppedAnimation<Color>(
                                Color(0xFF1D1822),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
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



class _NamePage extends StatefulWidget {
  final String lang;
  final String initialName;
  final ValueChanged<String> onNameChanged;
  final VoidCallback onContinue;

  const _NamePage({
    required this.lang,
    required this.initialName,
    required this.onNameChanged,
    required this.onContinue,
  });

  @override
  State<_NamePage> createState() => _NamePageState();
}

class _NamePageState extends State<_NamePage> {
  late final TextEditingController _controller;
  late final FocusNode _focusNode;

  bool get _canContinue => _controller.text.trim().isNotEmpty;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialName);
    _focusNode = FocusNode();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _focusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  String _eyebrow() {
    switch (widget.lang) {
      case 'de': return 'Zuerst das Wichtigste.';
      case 'pt': return 'Primeiro, o mais importante.';
      case 'es': return 'Primero lo primero';
      case 'fr': return 'Commençons par le début';
      case 'it': return 'Prima le cose importanti';
      default: return 'First, what matters most.';
    }
  }

  String _title() {
    switch (widget.lang) {
      case 'de': return 'Wie dürfen wir dich nennen?';
      case 'pt': return 'Como podemos te chamar?';
      case 'es': return '¿Cómo podemos llamarte?';
      case 'fr': return 'Comment pouvons-nous t’appeler ?';
      case 'it': return 'Come possiamo chiamarti?';
      default: return 'What can we call you?';
    }
  }

  String _hint() {
    switch (widget.lang) {
      case 'de': return 'Dein Name';
      case 'pt': return 'Seu nome';
      case 'es': return 'Tu nombre';
      case 'fr': return 'Ton prénom';
      case 'it': return 'Il tuo nome';
      default: return 'Your name';
    }
  }

  String _button() {
    switch (widget.lang) {
      case 'de': return 'Weiter';
      case 'pt': return 'Continuar';
      case 'es': return 'Continuar';
      case 'fr': return 'Continuer';
      case 'it': return 'Continua';
      default: return 'Continue';
    }
  }

  Future<void> _submit() async {
    if (!_canContinue) return;

    widget.onNameChanged(_controller.text.trim());

    // Fecha o teclado antes de iniciar a transição para a próxima tela.
    // No iOS, navegar enquanto o teclado ainda está a reduzir o viewInset
    // pode causar um RenderFlex overflow minúsculo durante alguns frames.
    _focusNode.unfocus();
    FocusManager.instance.primaryFocus?.unfocus();

    HapticFeedback.mediumImpact();

    await Future.delayed(const Duration(milliseconds: 300));
    if (!mounted) return;

    widget.onContinue();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(28, 18, 28, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 14),
          Text(
            _eyebrow(),
            style: const TextStyle(
              color: Color(0xFFB0B0B5),
              fontSize: 17,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _title(),
            style: const TextStyle(
              color: Color(0xFF080808),
              fontSize: 30,
              height: 1.08,
              fontWeight: FontWeight.w900,
              letterSpacing: -0.8,
            ),
          ),
          const Spacer(flex: 2),
          Container(
            height: 78,
            decoration: BoxDecoration(
              color: const Color(0xFFF6F6F7),
              borderRadius: BorderRadius.circular(22),
            ),
            alignment: Alignment.center,
            padding: const EdgeInsets.symmetric(horizontal: 22),
            child: TextField(
              controller: _controller,
              focusNode: _focusNode,
              textAlign: TextAlign.center,
              textCapitalization: TextCapitalization.words,
              textInputAction: TextInputAction.done,
              autocorrect: false,
              enableSuggestions: false,
              onSubmitted: (_) => _submit(),
              onChanged: (value) {
                widget.onNameChanged(value.trim());
                setState(() {});
              },
              style: const TextStyle(
                color: Color(0xFF080808),
                fontSize: 28,
                fontWeight: FontWeight.w700,
              ),
              decoration: InputDecoration(
                border: InputBorder.none,
                hintText: _hint(),
                hintStyle: const TextStyle(
                  color: Color(0xFFC8C8CC),
                  fontSize: 28,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
          const Spacer(flex: 3),
          SizedBox(
            width: double.infinity,
            height: 64,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              decoration: BoxDecoration(
                color: _canContinue
                    ? const Color(0xFF080808)
                    : const Color(0xFFE1E1E3),
                borderRadius: BorderRadius.circular(32),
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(32),
                  onTap: _canContinue ? _submit : null,
                  child: Center(
                    child: Text(
                      _button(),
                      style: TextStyle(
                        color: _canContinue
                            ? Colors.white
                            : const Color(0xFF9B9B9F),
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

String _audienceSubjectPt(String? audience) {
  switch (audience) {
    case 'men':
      return 'ele';
    case 'both':
      return 'a outra pessoa';
    case 'women':
    default:
      return 'ela';
  }
}

String _audienceObjectPt(String? audience) {
  switch (audience) {
    case 'men':
      return 'ele';
    case 'both':
      return 'a outra pessoa';
    case 'women':
    default:
      return 'ela';
  }
}

String _audiencePossessivePt(String? audience) {
  switch (audience) {
    case 'men':
      return 'dele';
    case 'both':
      return 'da outra pessoa';
    case 'women':
    default:
      return 'dela';
  }
}

String _audienceSubjectDe(String? audience) {
  switch (audience) {
    case 'men':
      return 'er';
    case 'both':
      return 'die andere Person';
    case 'women':
    default:
      return 'sie';
  }
}

String _audiencePossessiveDe(String? audience) {
  switch (audience) {
    case 'men':
      return 'seine';
    case 'both':
      return 'die Aufmerksamkeit der anderen Person';
    case 'women':
    default:
      return 'ihre';
  }
}

String _audienceTargetDe(String? audience) {
  switch (audience) {
    case 'men':
      return 'ihm';
    case 'both':
      return 'der anderen Person';
    case 'women':
    default:
      return 'ihr';
  }
}

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
          // Vídeo menor dentro apenas da estrutura física do iPhone.
          // O vídeo já contém a interface do telefone, por isso não
          // desenhamos notch, Dynamic Island ou status bar sobre ele.
          Expanded(
            child: Center(
              child: SizedBox(
                width: 272,
                child: Stack(
                  clipBehavior: Clip.none,
                  alignment: Alignment.center,
                  children: [
                    // Botões de volume.
                    Positioned(
                      left: -4,
                      top: 140,
                      child: Container(
                        width: 5,
                        height: 52,
                        decoration: BoxDecoration(
                          color: const Color(0xFF232326),
                          borderRadius: BorderRadius.circular(3),
                        ),
                      ),
                    ),
                    Positioned(
                      left: -4,
                      top: 200,
                      child: Container(
                        width: 5,
                        height: 52,
                        decoration: BoxDecoration(
                          color: const Color(0xFF232326),
                          borderRadius: BorderRadius.circular(3),
                        ),
                      ),
                    ),

                    // Botão lateral direito.
                    Positioned(
                      right: -4,
                      top: 156,
                      child: Container(
                        width: 5,
                        height: 76,
                        decoration: BoxDecoration(
                          color: const Color(0xFF232326),
                          borderRadius: BorderRadius.circular(3),
                        ),
                      ),
                    ),

                    // Corpo físico do iPhone.
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: const Color(0xFF171719),
                        borderRadius: BorderRadius.circular(42),
                        border: Border.all(
                          color: const Color(0xFF4A4A4E),
                          width: 1.2,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.16),
                            blurRadius: 26,
                            offset: const Offset(0, 12),
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(36),
                        child: AspectRatio(
                          aspectRatio: 9 / 19.5,
                          child: _buildVideo(fit: BoxFit.cover),
                        ),
                      ),
                    ),
                  ],
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
    switch (lang) {
      case 'de':
        if (widget.audience == 'men') {
          return 'Sorg dafür, dass er aufs Handy schaut und hofft, dass du es bist.';
        }
        if (widget.audience == 'both') {
          return 'Sorg dafür, dass die andere Person aufs Handy schaut und hofft, dass du es bist.';
        }
        return 'Sorg dafür, dass sie aufs Handy schaut und hofft, dass du es bist.';

      case 'pt':
        if (widget.audience == 'men') {
          return 'Faça com que ele olhe para o celular esperando que seja você.';
        }
        if (widget.audience == 'both') {
          return 'Faça com que a outra pessoa olhe para o celular esperando que seja você.';
        }
        return 'Faça com que ela olhe para o celular esperando que seja você.';

      default:
        if (widget.audience == 'men') {
          return 'Make him check his phone hoping it’s you.';
        }
        if (widget.audience == 'both') {
          return 'Make the other person check their phone hoping it’s you.';
        }
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

  // Mensagens de exemplo "clichê" — traduzidas para cada idioma.
  static const Map<String, List<String>> _messagesByLang = {
    'de': [
      'Hey',
      'Wie geht’s?',
      'Was machst du?',
      'Wie war dein Tag?',
      'Du bist hübsch',
      'Was machst du so?',
      'Warum antwortest du mir nicht?',
      'Guten Morgen',
      'Was suchst du hier?',
    ],
    'pt': [
      'Oi',
      'Tudo bem?',
      'O que você está fazendo?',
      'Como foi seu dia?',
      'Você é muito bonita',
      'O que você anda fazendo?',
      'Por que você não me responde?',
      'Bom dia',
      'O que você procura por aqui?',
    ],
    'es': [
      'Hola',
      '¿Qué tal?',
      '¿Qué haces?',
      '¿Cómo estuvo tu día?',
      'Eres muy guapa',
      '¿Qué andas haciendo?',
      '¿Por qué no me respondes?',
      'Buenos días',
      '¿Qué buscas por aquí?',
    ],
    'fr': [
      'Salut',
      'Ça va ?',
      'Tu fais quoi ?',
      'C’était comment ta journée ?',
      'Tu es très jolie',
      'Tu fais quoi de beau ?',
      'Pourquoi tu ne me réponds pas ?',
      'Bonjour',
      'Tu cherches quoi ici ?',
    ],
    'it': [
      'Ciao',
      'Come va?',
      'Cosa fai?',
      'Com’è andata la giornata?',
      'Sei molto carina',
      'Cosa combini?',
      'Perché non mi rispondi?',
      'Buongiorno',
      'Cosa cerchi qui?',
    ],
    'en': [
      'Hey',
      'How are you?',
      'What are you up to?',
      'How was your day?',
      'You’re pretty',
      'What have you been up to?',
      'Why aren’t you answering me?',
      'Good morning',
      'What are you looking for here?',
    ],
  };

  List<String> get _messages =>
      _messagesByLang[lang] ?? _messagesByLang['en']!;

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

  // Rótulo curto de "Nota" em cada idioma.
  String _noteLabel(String lang) {
    switch (lang) {
      case 'de':
        return 'Hinw.:';
      case 'pt':
        return 'Obs.:';
      case 'es':
        return 'N.:';
      case 'fr':
        return 'Rem.:';
      case 'it':
        return 'N.:';
      default:
        return 'N.B.:';
    }
  }

  String _warning(String lang) {
    switch (lang) {
      case 'de':
        return 'Verlier keine guten Gespräche, nur weil du nicht weißt, was du schreiben sollst.';
      case 'pt':
        return 'Pare de perder conversas boas por não saber o que dizer.';
      case 'es':
        return 'Deja de perder buenas conversaciones por no saber qué decir.';
      case 'fr':
        return 'Arrête de perdre de bonnes conversations parce que tu ne sais pas quoi dire.';
      case 'it':
        return 'Smetti di perdere belle conversazioni perché non sai cosa dire.';
      default:
        return 'Stop losing good conversations because you don’t know what to say.';
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
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 22),
      child: Column(
        children: [
          // Título fixo.
          Text(
            _title(lang),
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Color(0xFF080808),
              fontSize: 30,
              height: 1.08,
              fontWeight: FontWeight.w900,
              letterSpacing: -0.9,
            ),
          ),

          const SizedBox(height: 16),

          // SOMENTE as mensagens fazem scroll vertical.
          Expanded(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 430),
              child: Scrollbar(
                thumbVisibility: false,
                child: ListView.separated(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.symmetric(vertical: 2),
                  itemCount: _messages.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (_, index) {
                    return Container(
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
                    );
                  },
                ),
              ),
            ),
          ),

          const SizedBox(height: 12),

          // Nota fixa, fora do scroll, em vermelho.
          Text.rich(
            TextSpan(
              children: [
                TextSpan(
                  text: '${_noteLabel(lang)} ',
                  style: const TextStyle(fontWeight: FontWeight.w900),
                ),
                TextSpan(text: _warning(lang)),
              ],
            ),
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Color(0xFFFF3B30),
              fontSize: 15.5,
              height: 1.24,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.15,
            ),
          ),

          const SizedBox(height: 14),

          // Botão fixo.
          SizedBox(
            width: double.infinity,
            height: 58,
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
          return 'Você não é a única pessoa tentando chamar a atenção.';
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
        return 'Enquanto você tenta chamar a atenção dela, outras pessoas estão fazendo exatamente a mesma coisa.';
      default:
        if (audience == 'men') {
          return 'While you’re trying to get his attention, others are doing exactly the same thing.';
        }
        if (audience == 'both') {
          return 'While you’re trying to get the other person’s attention, others are doing exactly the same thing.';
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

  String _luckLine() {
    switch (lang) {
      case 'de':
        return 'Hinw.: Verlass dich nicht auf Glück, um das Interesse aufrechtzuerhalten.';
      case 'pt':
        return 'Obs.: Não dependa de sorte para manter o interesse.';
      case 'es':
        return 'Nota: No dependas de la suerte para mantener el interés.';
      case 'fr':
        return 'N.B. : Ne compte pas sur la chance pour maintenir son intérêt.';
      case 'it':
        return 'N.B.: Non affidarti alla fortuna per mantenere vivo l’interesse.';
      case 'tr':
        return 'Not: İlgiyi sürdürmek için şansa güvenme.';
      case 'pl':
        return 'Uwaga: Nie licz na szczęście, żeby utrzymać zainteresowanie.';
      case 'ru':
        return 'Прим.: Не полагайся на удачу, чтобы удерживать интерес.';
      case 'ar':
        return 'ملاحظة: لا تعتمد على الحظ للحفاظ على الاهتمام.';
      default:
        return 'Note: Don’t rely on luck to keep their interest.';
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
          const SizedBox(height: 18),
          Text(
            _luckLine(),
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Color(0xFF111111),
              fontSize: 19,
              height: 1.25,
              fontWeight: FontWeight.w900,
              letterSpacing: -0.35,
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
        if (audience == 'men') return 'Imagine if your message was the one he was waiting for.';
        if (audience == 'both') return 'Imagine if your message was the one the other person was waiting for.';
        return 'Imagine if your message was the one she was waiting for.';
    }
  }

  String _mine() {
    switch (lang) {
      case 'de': return 'Nicht irgendeine Nachricht.\nDeine.';
      case 'pt': return 'Não qualquer mensagem.\nA tua.';
      default: return 'Not just any message.\nYours.';
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
        if (audience == 'men') return 'It’s that feeling when you realize he actually wants to talk to you.';
        if (audience == 'both') return 'It’s that feeling when you realize the other person actually wants to talk to you.';
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
        if (audience == 'men') return 'Make yourself the first person he wants to text when he wakes up.';
        if (audience == 'both') return 'Make yourself the first person the other person wants to text when they wake up.';
        return 'Make yourself the first person she wants to text when she wakes up.';
    }
  }

  String _painLine(String lang) {
    switch (lang) {
      case 'de':
        return 'Hör auf, dieselbe Nachricht immer wieder zu löschen und neu zu schreiben.';
      case 'pt':
        return 'Pare de apagar e reescrever a mesma mensagem.';
      case 'es':
        return 'Deja de borrar y reescribir el mismo mensaje una y otra vez.';
      case 'fr':
        return 'Arrête d’effacer et de réécrire le même message encore et encore.';
      case 'it':
        return 'Smetti di cancellare e riscrivere lo stesso messaggio.';
      default:
        return 'Stop deleting and rewriting the same message.';
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
            _painLine(lang),
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Color(0xFF111111),
              fontSize: 19,
              height: 1.35,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.25,
            ),
          ),

          const SizedBox(height: 28),

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
  final String? initialAudience;
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
  String? selected;

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
      buttonEnabled: selected != null,
      onContinue: () {
        if (selected == null) return;
        widget.onSelected(selected!);
        widget.onContinue();
      },
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: options.map((option) {
            final active = selected == option.value;
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _ChoiceTile(
                text: option.label,
                active: active,
                trailing: active ? Icons.check_rounded : null,
                onTap: () {
                  HapticFeedback.selectionClick();
                  setState(() => selected = option.value);
                  widget.onSelected(option.value);
                },
              ),
            );
          }).toList(),
        ),
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
  final bool centerOptions;
  final ValueChanged<String>? onSelected;
  final VoidCallback onContinue;

  const _SingleChoicePage({
    required this.lang,
    required this.titlePt,
    required this.titleDe,
    required this.optionsPt,
    required this.optionsDe,
    this.centerOptions = false,
    this.onSelected,
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
      child: widget.centerOptions
          ? Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: List.generate(options.length, (index) {
                  final active = selected == index;
                  return Padding(
                    padding: EdgeInsets.only(
                      bottom: index == options.length - 1 ? 0 : 10,
                    ),
                    child: _ChoiceTile(
                      text: options[index],
                      active: active,
                      onTap: () {
                        HapticFeedback.selectionClick();
                        setState(() => selected = index);
                        widget.onSelected?.call(options[index]);
                      },
                    ),
                  );
                }),
              ),
            )
          : ListView.separated(
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
                        widget.onSelected?.call(options[index]);
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
  final ValueChanged<List<String>>? onSelected;
  final VoidCallback onContinue;

  const _MultiChoicePage({
    required this.lang,
    required this.titlePt,
    required this.titleDe,
    this.options,
    this.optionsPt,
    this.optionsDe,
    required this.maxSelections,
    this.onSelected,
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
              widget.onSelected?.call(selected.map((i) => options[i]).toList());
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
  final String userName;
  final VoidCallback onContinue;

  const _QuestionIntroPage({
    required this.lang,
    required this.userName,
    required this.onContinue,
  });

  String _title() {
    final name = userName.trim();

    switch (lang) {
      case 'de':
        return name.isEmpty
            ? 'Bevor wir weitermachen, habe ich ein paar wichtige Fragen an dich.'
            : '$name, bevor wir weitermachen, habe ich ein paar wichtige Fragen an dich.';
      case 'pt':
        return name.isEmpty
            ? 'Antes de continuarmos, tenho algumas perguntas importantes para você.'
            : '$name, antes de continuarmos, tenho algumas perguntas importantes para você.';
      case 'es':
        return name.isEmpty
            ? 'Antes de continuar, tengo algunas preguntas importantes para ti.'
            : '$name, antes de continuar, tengo algunas preguntas importantes para ti.';
      case 'fr':
        return name.isEmpty
            ? 'Avant de continuer, j’ai quelques questions importantes pour toi.'
            : '$name, avant de continuer, j’ai quelques questions importantes pour toi.';
      case 'it':
        return name.isEmpty
            ? 'Prima di continuare, ho alcune domande importanti per te.'
            : '$name, prima di continuare, ho alcune domande importanti per te.';
      default:
        return name.isEmpty
            ? 'Before we continue, I have a few important questions for you.'
            : '$name, before we continue, I have a few important questions for you.';
    }
  }

  String _honesty() {
    switch (lang) {
      case 'de':
        return 'Je ehrlicher du antwortest, desto persönlicher kann sich deine Erfahrung anfühlen.';
      case 'pt':
        return 'Quanto mais honesto você for, mais pessoal sua experiência pode parecer.';
      case 'es':
        return 'Cuanto más sincero seas, más personal podrá sentirse tu experiencia.';
      case 'fr':
        return 'Plus tu seras honnête, plus ton expérience pourra être personnalisée.';
      case 'it':
        return 'Più sarai sincero, più la tua esperienza potrà sembrare personale.';
      default:
        return 'The more honest you are, the more personal your experience can feel.';
    }
  }

  String _privacy() {
    switch (lang) {
      case 'de':
        return 'Alles, was du teilst, wird vertraulich behandelt.';
      case 'pt':
        return 'Tudo o que você compartilha é tratado de forma confidencial.';
      case 'es':
        return 'Todo lo que compartas será tratado de forma confidencial.';
      case 'fr':
        return 'Tout ce que tu partages reste confidentiel.';
      case 'it':
        return 'Tutto ciò che condividi viene trattato in modo confidenziale.';
      default:
        return 'Everything you share is treated confidentially.';
    }
  }

  String _button() {
    switch (lang) {
      case 'de': return 'Weiter';
      case 'pt': return 'Continuar';
      case 'es': return 'Continuar';
      case 'fr': return 'Continuer';
      case 'it': return 'Continua';
      default: return 'Continue';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(28, 28, 28, 26),
      child: Column(
        children: [
          const Spacer(flex: 2),
          Text(
            _title(),
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Color(0xFF080808),
              fontSize: 30,
              height: 1.12,
              fontWeight: FontWeight.w900,
              letterSpacing: -0.8,
            ),
          ),
          const SizedBox(height: 28),
          Text(
            _honesty(),
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Color(0xFF111111),
              fontSize: 18,
              height: 1.45,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 22),
          Text(
            _privacy(),
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Color(0xFF2C2C2E),
              fontSize: 15.5,
              height: 1.45,
              fontWeight: FontWeight.w600,
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

class _ConfidencePage extends StatefulWidget {
  final String lang;
  final ValueChanged<int>? onSelected;
  final VoidCallback onContinue;

  const _ConfidencePage({
    required this.lang,
    this.onSelected,
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
                      widget.onSelected?.call(number);
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
  final String userName;
  final String? audience;
  final String? age;
  final List<String> platforms;
  final String? pain;
  final List<String> desires;
  final String? reaction;
  final String? stuckMoment;
  final int? confidence;
  final VoidCallback onContinue;

  const _PersonalizationBridgePage({
    required this.lang,
    required this.userName,
    required this.audience,
    required this.age,
    required this.platforms,
    required this.pain,
    required this.desires,
    required this.reaction,
    required this.stuckMoment,
    required this.confidence,
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
      lowerBound: 0.95,
      upperBound: 1.05,
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
          HapticFeedback.heavyImpact();
          return;
        }
        setState(() => _progress++);

        // Feedback háptico durante a contagem.
        // Funciona em iOS e Android quando o dispositivo permite haptics.
        if (_progress % 4 == 0) {
          HapticFeedback.selectionClick();
        }
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
      case 'de': return 'Wir bereiten deine Erfahrung vor.';
      case 'pt': return 'Estamos preparando sua experiência.';
      default: return 'We’re preparing your experience.';
    }
  }

  String _summaryTitle() {
    switch (widget.lang) {
      case 'de': return 'Deine Antworten';
      case 'pt': return 'Suas escolhas';
      default: return 'Your choices';
    }
  }

  String _audienceText() {
    switch (widget.audience) {
      case 'women': return widget.lang == 'de' ? 'Frauen' : widget.lang == 'pt' ? 'Mulheres' : 'Women';
      case 'men': return widget.lang == 'de' ? 'Männer' : widget.lang == 'pt' ? 'Homens' : 'Men';
      case 'both': return widget.lang == 'de' ? 'Beide' : widget.lang == 'pt' ? 'Ambos' : 'Both';
      default: return '—';
    }
  }

  String _status() {
    if (_done) {
      return widget.lang == 'de'
          ? 'Alles bereit.'
          : widget.lang == 'pt'
              ? 'Tudo pronto.'
              : 'All set.';
    }

    if (_progress < 30) {
      return widget.lang == 'de'
          ? 'Deine Antworten werden ausgewertet...'
          : widget.lang == 'pt'
              ? 'Analisando suas respostas...'
              : 'Reviewing your answers...';
    }

    if (_progress < 65) {
      return widget.lang == 'de'
          ? 'Wir verstehen deinen Gesprächsstil...'
          : widget.lang == 'pt'
              ? 'Entendendo seu estilo de conversa...'
              : 'Understanding your conversation style...';
    }

    return widget.lang == 'de'
        ? 'Deine Erfahrung wird angepasst...'
        : widget.lang == 'pt'
            ? 'Ajustando sua experiência...'
            : 'Tailoring your experience...';
  }

  String _button() {
    switch (widget.lang) {
      case 'de': return 'Weiter';
      case 'pt': return 'Continuar';
      default: return 'Continue';
    }
  }

  List<Map<String, String>> _rows() {
    final de = widget.lang == 'de';
    final pt = widget.lang == 'pt';

    return [
      {
        'label': de ? 'Name' : pt ? 'Nome' : 'Name',
        'value': widget.userName.isEmpty ? '—' : widget.userName,
      },
      {
        'label': de ? 'Gespräche mit' : pt ? 'Conversas com' : 'Conversations with',
        'value': _audienceText(),
      },
      {
        'label': de ? 'Alter' : pt ? 'Idade' : 'Age',
        'value': widget.age ?? '—',
      },
      {
        'label': de ? 'Plattformen' : pt ? 'Plataformas' : 'Platforms',
        'value': widget.platforms.isEmpty ? '—' : widget.platforms.join(', '),
      },
      {
        'label': de ? 'Größte Herausforderung' : pt ? 'Maior dificuldade' : 'Biggest challenge',
        'value': widget.pain ?? '—',
      },
      {
        'label': de ? 'Ziele' : pt ? 'Objetivos' : 'Goals',
        'value': widget.desires.isEmpty ? '—' : widget.desires.join(' · '),
      },
      {
        'label': de ? 'Wenn eine Antwort dauert' : pt ? 'Quando demora a responder' : 'When replies take time',
        'value': widget.reaction ?? '—',
      },
      {
        'label': de ? 'Schwierigster Moment' : pt ? 'Onde mais trava' : 'Hardest moment',
        'value': widget.stuckMoment ?? '—',
      },
      {
        'label': de ? 'Selbstsicherheit' : pt ? 'Confiança' : 'Confidence',
        'value': widget.confidence == null ? '—' : '${widget.confidence}/5',
      },
    ];
  }

  @override
  Widget build(BuildContext context) {
    final rows = _rows();

    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(24, 18, 24, 22),
      child: Column(
        children: [
          Text(
            _title(),
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Color(0xFF080808),
              fontSize: 28,
              height: 1.10,
              fontWeight: FontWeight.w900,
              letterSpacing: -0.8,
            ),
          ),
          const SizedBox(height: 16),
          AnimatedBuilder(
            animation: _pulseController,
            builder: (_, child) {
              return Transform.scale(
                scale: _done ? 1.0 : _pulseController.value,
                child: child,
              );
            },
            child: Container(
              width: 132,
              height: 132,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFFF5F5F7),
                border: Border.all(
                  color: _done
                      ? const Color(0xFF34C759)
                      : const Color(0xFF111111),
                  width: 3,
                ),
              ),
              child: Center(
                child: _done
                    ? const Icon(
                        Icons.check_rounded,
                        color: Color(0xFF34C759),
                        size: 56,
                      )
                    : Text(
                        '$_progress%',
                        style: const TextStyle(
                          color: Color(0xFF111111),
                          fontSize: 34,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            _status(),
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Color(0xFF66666D),
              fontSize: 15,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 14),
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              _summaryTitle(),
              style: const TextStyle(
                color: Color(0xFF111111),
                fontSize: 16,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: const Color(0xFFF7F7F9),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Builder(
                builder: (context) {
                  // 8 respostas -> uma nova aparece a cada ~12,5% do progresso.
                  final visibleCount = _done
                      ? rows.length
                      : ((_progress / 100) * rows.length).ceil().clamp(1, rows.length);

                  return ListView.separated(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    itemCount: visibleCount,
                    separatorBuilder: (_, __) => const Divider(
                      height: 18,
                      color: Color(0xFFE4E4E8),
                    ),
                    itemBuilder: (_, index) {
                      final row = rows[index];

                      return TweenAnimationBuilder<double>(
                        key: ValueKey('answer_$index'),
                        tween: Tween(begin: 0.0, end: 1.0),
                        duration: const Duration(milliseconds: 360),
                        curve: Curves.easeOutCubic,
                        builder: (_, value, child) {
                          return Opacity(
                            opacity: value,
                            child: Transform.translate(
                              offset: Offset(0, 10 * (1 - value)),
                              child: child,
                            ),
                          );
                        },
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              row['label']!,
                              style: const TextStyle(
                                color: Color(0xFF8E8E93),
                                fontSize: 12.5,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              row['value']!,
                              style: const TextStyle(
                                color: Color(0xFF111111),
                                fontSize: 14.5,
                                height: 1.28,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            height: 58,
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
                  borderRadius: BorderRadius.circular(29),
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

class _UnderstandingYouPage extends StatelessWidget {
  final String lang;
  final String userName;
  final VoidCallback onContinue;

  const _UnderstandingYouPage({
    required this.lang,
    required this.userName,
    required this.onContinue,
  });

  String _headline() {
    final name = userName.trim();
    switch (lang) {
      case 'de':
        return name.isEmpty
            ? 'Wir beginnen zu verstehen, wie du kommunizierst.'
            : '$name, wir beginnen zu verstehen, wie du kommunizierst.';
      case 'pt':
        return name.isEmpty
            ? 'Já estamos começando a entender o seu jeito de conversar.'
            : '$name, já estamos começando a entender o seu jeito de conversar.';
      case 'es':
        return name.isEmpty
            ? 'Ya estamos empezando a entender tu forma de conversar.'
            : '$name, ya estamos empezando a entender tu forma de conversar.';
      case 'fr':
        return name.isEmpty
            ? 'Nous commençons à comprendre ta façon de communiquer.'
            : '$name, nous commençons à comprendre ta façon de communiquer.';
      case 'it':
        return name.isEmpty
            ? 'Stiamo iniziando a capire il tuo modo di comunicare.'
            : '$name, stiamo iniziando a capire il tuo modo di comunicare.';
      default:
        return name.isEmpty
            ? 'We’re starting to understand how you communicate.'
            : '$name, we’re starting to understand how you communicate.';
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

  String _headline() {
    switch (lang) {
      case 'de':
        return 'Schließ dich über 10.000 Menschen wie dir an.';
      case 'pt':
        return 'Junte-se a mais de 10 mil pessoas como você.';
      default:
        return 'Join more than 10,000 people like you.';
    }
  }

  String _usersLabel() {
    switch (lang) {
      case 'de':
        return 'Über 10.000 UpCrush Nutzer:innen';
      case 'pt':
        return 'Mais de 10 mil usuários do UpCrush';
      default:
        return 'More than 10,000 UpCrush users';
    }
  }

  String _button() {
    switch (lang) {
      case 'de': return 'Weiter';
      case 'pt': return 'Continuar';
      default: return 'Continue';
    }
  }

  List<Map<String, String>> _reviews() {
    switch (lang) {
      case 'de':
        return const [
          {
            'name': 'Lucas',
            'date': 'März 2025',
            'text': 'Ich denke viel weniger darüber nach, was ich als Nächstes schreiben soll. Meine Gespräche fühlen sich dadurch viel natürlicher an.',
          },
          {
            'name': 'Matteo',
            'date': 'Mai 2025',
            'text': 'Früher habe ich jede Nachricht viel zu lange überdacht. Jetzt schreibe ich selbstsicherer und Gespräche laufen leichter.',
          },
          {
            'name': 'Sofia',
            'date': 'Juli 2025',
            'text': 'Mir gefällt besonders, dass die Vorschläge zur Situation passen und nicht wie generische Nachrichten wirken.',
          },
          {
            'name': 'Noah',
            'date': 'September 2025',
            'text': 'Der Chat Dolla hat mir besonders gefallen. Er hilft mir, eine Unterhaltung weiterzuführen, ohne dass sich meine Antworten gezwungen anfühlen.',
          },
          {
            'name': 'Amelia',
            'date': 'November 2025',
            'text': 'Ich bin beim Schreiben viel entspannter geworden und weiß schneller, wie ich antworten möchte.',
          },
          {
            'name': 'Elias',
            'date': 'Januar 2026',
            'text': 'Die Antworten fühlen sich persönlicher an und ich verbringe nicht mehr ewig damit, eine einzige Nachricht zu formulieren.',
          },
          {
            'name': 'Mia',
            'date': 'März 2026',
            'text': 'Ich nutze es vor allem dann, wenn eine Unterhaltung ins Stocken gerät. Es gibt mir schnell eine neue Richtung.',
          },
          {
            'name': 'Leo',
            'date': 'Mai 2026',
            'text': 'Ich bin deutlich selbstbewusster beim Schreiben geworden und denke nicht mehr über jede einzelne Nachricht nach.',
          },
          {
            'name': 'Nora',
            'date': 'Juli 2026',
            'text': 'Die Vorschläge helfen mir, meinen eigenen Ton beizubehalten und trotzdem interessanter zu antworten.',
          },
        ];
      case 'pt':
        return const [
          {
            'name': 'Lucas',
            'date': 'Março de 2025',
            'text': 'Penso muito menos no que devo mandar a seguir. As minhas conversas ficaram muito mais naturais.',
          },
          {
            'name': 'Matteo',
            'date': 'Maio de 2025',
            'text': 'Antes eu pensava demais em cada mensagem. Agora converso com muito mais confiança e tudo flui melhor.',
          },
          {
            'name': 'Sofia',
            'date': 'Julho de 2025',
            'text': 'O que mais gosto é que as sugestões combinam com a situação e não parecem mensagens genéricas.',
          },
          {
            'name': 'Noah',
            'date': 'Setembro de 2025',
            'text': 'Gostei especialmente do Chat Dolla. Ele me ajuda a continuar a conversa sem fazer as respostas parecerem forçadas.',
          },
          {
            'name': 'Amelia',
            'date': 'Novembro de 2025',
            'text': 'Passei a ficar muito mais tranquila ao conversar e sei mais rápido como quero responder.',
          },
          {
            'name': 'Elias',
            'date': 'Janeiro de 2026',
            'text': 'As respostas parecem mais pessoais e já não passo uma eternidade pensando em uma única mensagem.',
          },
          {
            'name': 'Mia',
            'date': 'Março de 2026',
            'text': 'Uso principalmente quando a conversa começa a travar. Rapidamente encontro uma nova direção para continuar.',
          },
          {
            'name': 'Leo',
            'date': 'Maio de 2026',
            'text': 'Fiquei muito mais confiante ao conversar e já não penso demais em cada mensagem.',
          },
          {
            'name': 'Nora',
            'date': 'Julho de 2026',
            'text': 'As sugestões me ajudam a manter o meu próprio jeito e ainda responder de forma mais interessante.',
          },
        ];
      default:
        return const [
          {'name':'Lucas','date':'March 2025','text':'I overthink what to send next much less now. My conversations feel much more natural.'},
          {'name':'Matteo','date':'May 2025','text':'I used to overthink every message. Now I text with much more confidence and conversations flow better.'},
          {'name':'Sofia','date':'July 2025','text':'What I like most is that the suggestions fit the situation and do not feel generic.'},
          {'name':'Noah','date':'September 2025','text':'I especially like Chat Dolla. It helps me keep a conversation going without making my replies feel forced.'},
          {'name':'Amelia','date':'November 2025','text':'I feel much more relaxed when texting and know much faster how I want to reply.'},
          {'name':'Elias','date':'January 2026','text':'The replies feel more personal and I no longer spend forever thinking about a single message.'},
          {'name':'Mia','date':'March 2026','text':'I mainly use it when a conversation starts to stall. It quickly gives me a new direction.'},
          {'name':'Leo','date':'May 2026','text':'I feel much more confident texting and no longer overthink every single message.'},
          {'name':'Nora','date':'July 2026','text':'The suggestions help me keep my own tone while still replying in a more interesting way.'},
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
            // Cabeçalho fixo: não faz scroll.
            Padding(
              padding: const EdgeInsets.fromLTRB(26, 28, 26, 0),
              child: Column(
                children: [
                  Text(
                    _headline(),
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.black,
                      fontSize: 34,
                      height: 1.12,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -1.1,
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Fotos manuais + texto sobreposto, no estilo da referência.
                  SizedBox(
                    height: 92,
                    child: Align(
                      alignment: Alignment.centerRight,
                      child: SizedBox(
                        width: 245,
                        child: Stack(
                          clipBehavior: Clip.none,
                          alignment: Alignment.centerRight,
                          children: [
                            const Positioned(
                              right: 104,
                              top: 2,
                              child: _MiniAvatar(asset: 'assets/images/review_1.jpg'),
                            ),
                            const Positioned(
                              right: 70,
                              top: 2,
                              child: _MiniAvatar(asset: 'assets/images/review_2.jpg'),
                            ),
                            const Positioned(
                              right: 36,
                              top: 2,
                              child: _MiniAvatar(asset: 'assets/images/review_3.jpg'),
                            ),
                            Positioned(
                              right: 0,
                              top: 43,
                              child: Container(
                                constraints: const BoxConstraints(maxWidth: 190),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 14,
                                  vertical: 8,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.96),
                                  borderRadius: BorderRadius.circular(18),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.06),
                                      blurRadius: 14,
                                      offset: const Offset(0, 6),
                                    ),
                                  ],
                                ),
                                child: Text(
                                  _usersLabel(),
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                    color: Color(0xFF5E5E63),
                                    fontSize: 14,
                                    height: 1.18,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),
                ],
              ),
            ),

            // Somente os comentários fazem scroll vertical.
            Expanded(
              child: ListView.separated(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(26, 0, 26, 18),
                itemCount: reviews.length,
                separatorBuilder: (_, __) => const SizedBox(height: 14),
                itemBuilder: (_, index) {
                  final review = reviews[index];
                  return _LongReviewCard(
                    name: review['name']!,
                    date: review['date']!,
                    text: review['text']!,
                  );
                },
              ),
            ),

            // Botão sempre fixo.
            Container(
              color: Colors.white,
              padding: const EdgeInsets.fromLTRB(22, 12, 22, 18),
              child: SizedBox(
                width: double.infinity,
                height: 60,
                child: ElevatedButton(
                  onPressed: () {
                    HapticFeedback.mediumImpact();
                    onContinue();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1D1822),
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

class _MiniAvatar extends StatelessWidget {
  final String asset;
  const _MiniAvatar({required this.asset});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 50,
      height: 50,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 2),
      ),
      child: ClipOval(
        child: Image.asset(
          asset,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => Container(
            color: const Color(0xFFEDEDEF),
            alignment: Alignment.center,
            child: const Icon(
              Icons.person_rounded,
              color: Color(0xFFAAAAAF),
              size: 25,
            ),
          ),
        ),
      ),
    );
  }
}

class _LongReviewCard extends StatelessWidget {
  final String name;
  final String date;
  final String text;

  const _LongReviewCard({
    required this.name,
    required this.date,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 20),
      decoration: BoxDecoration(
        color: const Color(0xFFF8F8FB),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFE8E8EE)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Expanded(
                child: Row(
                  children: [
                    Icon(Icons.star_rounded, color: Color(0xFFE9B657), size: 22),
                    Icon(Icons.star_rounded, color: Color(0xFFE9B657), size: 22),
                    Icon(Icons.star_rounded, color: Color(0xFFE9B657), size: 22),
                    Icon(Icons.star_rounded, color: Color(0xFFE9B657), size: 22),
                    Icon(Icons.star_rounded, color: Color(0xFFE9B657), size: 22),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Flexible(
                child: Text(
                  '$name, $date',
                  textAlign: TextAlign.right,
                  style: const TextStyle(
                    color: Color(0xFF8D8D92),
                    fontSize: 14,
                    height: 1.2,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            text,
            style: const TextStyle(
              color: Color(0xFF111111),
              fontSize: 18,
              height: 1.38,
              fontWeight: FontWeight.w500,
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
