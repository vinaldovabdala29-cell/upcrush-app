import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../main.dart';
import 'home_screen.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});
  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen>
    with TickerProviderStateMixin {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  String? _selectedGender;
  String? _selectedGoal;
  String? _selectedApp;

  late AnimationController _fadeController;
  late Animation<double> _fadeAnim;

  static const _accent = Color(0xFFFF2D55);
  static const _bg = Colors.white;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 400));
    _fadeAnim = CurvedAnimation(parent: _fadeController, curve: Curves.easeOut);
    _fadeController.forward();
  }

  @override
  void dispose() {
    _pageController.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  void _nextPage() {
    if (_currentPage < 3) {
      _fadeController.reset();
      _pageController.nextPage(
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeInOut);
      _fadeController.forward();
    }
  }

  Future<void> _finish() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('user_gender', _selectedGender ?? '');
    await prefs.setString('user_goal', _selectedGoal ?? '');
    await prefs.setString('user_app', _selectedApp ?? '');
    await prefs.setBool('onboarding_done', true);
    if (!mounted) return;
    Navigator.pushReplacement(context,
      PageRouteBuilder(
        pageBuilder: (_, __, ___) => const HomeScreen(),
        transitionDuration: const Duration(milliseconds: 500),
        transitionsBuilder: (_, anim, __, child) =>
          FadeTransition(opacity: anim, child: child)));
  }

  bool get _canProceed {
    switch (_currentPage) {
      case 1: return _selectedGender != null;
      case 2: return _selectedGoal != null;
      case 3: return _selectedApp != null;
      default: return true;
    }
  }

  String _continueLabel(String lang) {
    switch (lang) {
      case 'de': return 'Weiter';
      case 'es': return 'Continuar';
      case 'fr': return 'Continuer';
      case 'it': return 'Continua';
      case 'tr': return 'Devam et';
      case 'pl': return 'Dalej';
      case 'ru': return 'Далее';
      case 'ar': return 'استمر';
      case 'pt': return 'Continuar';
      default: return 'Continue';
    }
  }

  String _startLabel(String lang) {
    switch (lang) {
      case 'de': return 'Starten 🚀';
      case 'es': return 'Comenzar 🚀';
      case 'fr': return 'Commencer 🚀';
      case 'it': return 'Inizia 🚀';
      case 'tr': return 'Başla 🚀';
      case 'pl': return 'Zaczynamy 🚀';
      case 'ru': return 'Начать 🚀';
      case 'ar': return 'ابدأ 🚀';
      case 'pt': return 'Começar 🚀';
      default: return 'Get Started 🚀';
    }
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder(
      valueListenable: appLangNotifier,
      builder: (_, lang, __) {
        final l = lang.languageCode;
        final size = MediaQuery.of(context).size;
        final isTablet = size.shortestSide >= 600;
        final bottom = MediaQuery.of(context).padding.bottom;

        return Scaffold(
          backgroundColor: _bg,
          body: Column(children: [
            // ── Progress dots ─────────────────────────────────────────
            SafeArea(
              bottom: false,
              child: Padding(
                padding: EdgeInsets.fromLTRB(28, isTablet ? 24 : 16, 28, 0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(4, (i) => AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    width: i == _currentPage ? (isTablet ? 32 : 24) : (isTablet ? 10 : 8),
                    height: isTablet ? 10 : 8,
                    decoration: BoxDecoration(
                      color: i == _currentPage ? _accent : _accent.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(10)),
                  )),
                ),
              ),
            ),

            // ── Pages ─────────────────────────────────────────────────
            Expanded(
              child: PageView(
                controller: _pageController,
                physics: const BouncingScrollPhysics(),
                onPageChanged: (i) => setState(() => _currentPage = i),
                children: [
                  _WelcomePage(isTablet: isTablet, lang: l),
                  _GenderPage(
                    isTablet: isTablet, lang: l,
                    selected: _selectedGender,
                    onSelect: (v) => setState(() => _selectedGender = v)),
                  _GoalPage(
                    isTablet: isTablet, lang: l,
                    selected: _selectedGoal,
                    onSelect: (v) => setState(() => _selectedGoal = v)),
                  _AppPage(
                    isTablet: isTablet, lang: l,
                    selected: _selectedApp,
                    onSelect: (v) => setState(() => _selectedApp = v)),
                ],
              ),
            ),

            // ── Button ────────────────────────────────────────────────
            Padding(
              padding: EdgeInsets.fromLTRB(28, 12, 28, bottom + 28),
              child: SizedBox(
                width: double.infinity,
                height: isTablet ? 68 : 58,
                child: ElevatedButton(
                  onPressed: _canProceed
                    ? (_currentPage < 3 ? _nextPage : _finish)
                    : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _accent,
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: _accent.withOpacity(0.25),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(isTablet ? 20 : 16)),
                    elevation: 0),
                  child: Text(
                    _currentPage < 3 ? _continueLabel(l) : _startLabel(l),
                    style: TextStyle(
                      fontSize: isTablet ? 20 : 17,
                      fontWeight: FontWeight.w800)),
                ),
              ),
            ),
          ]),
        );
      },
    );
  }
}

// ── PAGE 1 — Welcome ─────────────────────────────────────────────────────────
class _WelcomePage extends StatelessWidget {
  final bool isTablet;
  final String lang;
  const _WelcomePage({required this.isTablet, required this.lang});

  String _title() {
    switch (lang) {
      case 'de': return 'Willkommen bei\nUpCrush 🌶️';
      case 'es': return 'Bienvenido a\nUpCrush 🌶️';
      case 'fr': return 'Bienvenue sur\nUpCrush 🌶️';
      case 'it': return 'Benvenuto su\nUpCrush 🌶️';
      case 'tr': return "UpCrush'a\nHoş Geldin 🌶️";
      case 'pl': return 'Witaj w\nUpCrush 🌶️';
      case 'ru': return 'Добро пожаловать\nв UpCrush 🌶️';
      case 'ar': return 'مرحباً في\nUpCrush 🌶️';
      case 'pt': return 'Bem-vindo ao\nUpCrush 🌶️';
      default: return 'Welcome to\nUpCrush 🌶️';
    }
  }

  String _sub() {
    switch (lang) {
      case 'de': return 'Dein KI-Assistent für bessere\nDating-App-Gespräche.';
      case 'es': return 'Tu asistente de IA para mejores\nconversaciones en apps de citas.';
      case 'fr': return 'Ton assistant IA pour de meilleures\nconversations sur les apps de rencontre.';
      case 'it': return 'Il tuo assistente AI per conversazioni\nmigliori sulle app di appuntamenti.';
      case 'tr': return 'Flört uygulamalarında daha iyi\nsohbetler için yapay zeka asistanın.';
      case 'pl': return 'Twój asystent AI do lepszych\nrozmów na aplikacjach randkowych.';
      case 'ru': return 'Твой ИИ-помощник для лучших\nбесед в приложениях для знакомств.';
      case 'ar': return 'مساعدك الذكي لمحادثات أفضل\nفي تطبيقات المواعدة.';
      case 'pt': return 'O teu assistente de IA para melhores\nconversas em apps de namoro.';
      default: return 'Your AI assistant for better\ndating app conversations.';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: isTablet ? 60 : 32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Big emoji
          Container(
            width: isTablet ? 140 : 110,
            height: isTablet ? 140 : 110,
            decoration: BoxDecoration(
              color: const Color(0xFFFF2D55).withOpacity(0.08),
              shape: BoxShape.circle),
            child: Center(child: Text('🌶️',
              style: TextStyle(fontSize: isTablet ? 72 : 56)))),

          SizedBox(height: isTablet ? 40 : 32),

          // Logo
          RichText(text: TextSpan(children: [
            TextSpan(text: "Up", style: TextStyle(
              fontSize: isTablet ? 52 : 40,
              fontWeight: FontWeight.w900,
              color: const Color(0xFF1C1C1E), letterSpacing: -1.5)),
            TextSpan(text: "Crush", style: TextStyle(
              fontSize: isTablet ? 52 : 40,
              fontWeight: FontWeight.w900,
              color: const Color(0xFFFF2D55), letterSpacing: -1.5)),
          ])),

          SizedBox(height: isTablet ? 20 : 16),

          Text(_title(),
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: isTablet ? 36 : 28,
              fontWeight: FontWeight.w900,
              color: const Color(0xFF1C1C1E),
              letterSpacing: -0.8, height: 1.15)),

          SizedBox(height: isTablet ? 20 : 14),

          Text(_sub(),
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: isTablet ? 18 : 15,
              color: Colors.black45, height: 1.5)),

          SizedBox(height: isTablet ? 40 : 32),

          // Features preview
          _FeatureRow(emoji: '📸', text: _feat1(), isTablet: isTablet),
          const SizedBox(height: 12),
          _FeatureRow(emoji: '🚀', text: _feat2(), isTablet: isTablet),
          const SizedBox(height: 12),
          _FeatureRow(emoji: '🤖', text: _feat3(), isTablet: isTablet),
        ],
      ),
    );
  }

  String _feat1() {
    switch (lang) {
      case 'de': return 'Analysiere Gespräche & erhalte perfekte Antworten';
      case 'es': return 'Analiza conversaciones y obtén respuestas perfectas';
      case 'pt': return 'Analisa conversas e recebe respostas perfeitas';
      default: return 'Analyze chats & get perfect replies instantly';
    }
  }

  String _feat2() {
    switch (lang) {
      case 'de': return 'Generiere Opener für Profile';
      case 'es': return 'Genera openers para perfiles';
      case 'pt': return 'Gera openers para perfis';
      default: return 'Generate openers for profiles';
    }
  }

  String _feat3() {
    switch (lang) {
      case 'de': return 'Dein persönlicher Dating-Coach 24/7';
      case 'es': return 'Tu coach de citas personal 24/7';
      case 'pt': return 'O teu coach de dating pessoal 24/7';
      default: return 'Your personal dating coach 24/7';
    }
  }
}

class _FeatureRow extends StatelessWidget {
  final String emoji, text;
  final bool isTablet;
  const _FeatureRow({required this.emoji, required this.text, required this.isTablet});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isTablet ? 24 : 18,
        vertical: isTablet ? 16 : 12),
      decoration: BoxDecoration(
        color: const Color(0xFFF8F8F8),
        borderRadius: BorderRadius.circular(isTablet ? 18 : 14),
        border: Border.all(color: Colors.black.withOpacity(0.05))),
      child: Row(children: [
        Text(emoji, style: TextStyle(fontSize: isTablet ? 26 : 20)),
        SizedBox(width: isTablet ? 16 : 12),
        Expanded(child: Text(text, style: TextStyle(
          fontSize: isTablet ? 16 : 13,
          fontWeight: FontWeight.w500,
          color: const Color(0xFF1C1C1E)))),
        Icon(Icons.check_circle_rounded,
          color: const Color(0xFF34C759), size: isTablet ? 22 : 18),
      ]),
    );
  }
}

// ── PAGE 2 — Gender ──────────────────────────────────────────────────────────
class _GenderPage extends StatelessWidget {
  final bool isTablet;
  final String lang;
  final String? selected;
  final Function(String) onSelect;
  const _GenderPage({required this.isTablet, required this.lang,
    required this.selected, required this.onSelect});

  String _title() {
    switch (lang) {
      case 'de': return 'Wer bist du?';
      case 'es': return '¿Quién eres?';
      case 'fr': return 'Qui es-tu ?';
      case 'it': return 'Chi sei?';
      case 'tr': return 'Sen kimsin?';
      case 'pl': return 'Kim jesteś?';
      case 'ru': return 'Кто ты?';
      case 'ar': return 'من أنت؟';
      case 'pt': return 'Quem és tu?';
      default: return 'Who are you?';
    }
  }

  String _sub() {
    switch (lang) {
      case 'de': return 'Das hilft uns, bessere Antworten für dich zu generieren.';
      case 'es': return 'Esto nos ayuda a generar mejores respuestas para ti.';
      case 'fr': return 'Cela nous aide à générer de meilleures réponses pour toi.';
      case 'it': return 'Questo ci aiuta a generare risposte migliori per te.';
      case 'tr': return 'Bu, senin için daha iyi yanıtlar oluşturmamıza yardımcı olur.';
      case 'pl': return 'Pomaga nam to generować lepsze odpowiedzi dla Ciebie.';
      case 'ru': return 'Это помогает нам создавать лучшие ответы для тебя.';
      case 'ar': return 'يساعدنا هذا في توليد ردود أفضل لك.';
      case 'pt': return 'Isto ajuda-nos a gerar melhores respostas para ti.';
      default: return 'This helps us generate better replies for you.';
    }
  }

  List<Map<String, String>> _options() {
    switch (lang) {
      case 'de': return [
        {'value': 'man', 'emoji': '👨', 'label': 'Mann'},
        {'value': 'woman', 'emoji': '👩', 'label': 'Frau'},
        {'value': 'other', 'emoji': '', 'label': 'Andere'},
      ];
      case 'es': return [
        {'value': 'man', 'emoji': '👨', 'label': 'Hombre'},
        {'value': 'woman', 'emoji': '👩', 'label': 'Mujer'},
        {'value': 'other', 'emoji': '', 'label': 'Otro'},
      ];
      case 'pt': return [
        {'value': 'man', 'emoji': '👨', 'label': 'Homem'},
        {'value': 'woman', 'emoji': '👩', 'label': 'Mulher'},
        {'value': 'other', 'emoji': '', 'label': 'Outro'},
      ];
      default: return [
        {'value': 'man', 'emoji': '👨', 'label': 'Man'},
        {'value': 'woman', 'emoji': '👩', 'label': 'Woman'},
        {'value': 'other', 'emoji': '', 'label': 'Other'},
      ];
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: isTablet ? 60 : 32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(_title(),
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: isTablet ? 42 : 32,
              fontWeight: FontWeight.w900,
              color: const Color(0xFF1C1C1E),
              letterSpacing: -1)),

          SizedBox(height: isTablet ? 14 : 10),

          Text(_sub(),
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: isTablet ? 17 : 14,
              color: Colors.black45, height: 1.4)),

          SizedBox(height: isTablet ? 48 : 36),

          ..._options().map((opt) => Padding(
            padding: const EdgeInsets.only(bottom: 14),
            child: _OptionCard(
              emoji: opt['emoji']!,
              label: opt['label']!,
              isSelected: selected == opt['value'],
              isTablet: isTablet,
              onTap: () => onSelect(opt['value']!)),
          )),
        ],
      ),
    );
  }
}

// ── PAGE 3 — Goal ────────────────────────────────────────────────────────────
class _GoalPage extends StatelessWidget {
  final bool isTablet;
  final String lang;
  final String? selected;
  final Function(String) onSelect;
  const _GoalPage({required this.isTablet, required this.lang,
    required this.selected, required this.onSelect});

  String _title() {
    switch (lang) {
      case 'de': return 'Was ist dein Ziel?';
      case 'es': return '¿Cuál es tu objetivo?';
      case 'fr': return 'Quel est ton objectif ?';
      case 'it': return 'Qual è il tuo obiettivo?';
      case 'tr': return 'Amacın ne?';
      case 'pl': return 'Jaki jest Twój cel?';
      case 'ru': return 'Какова твоя цель?';
      case 'ar': return 'ما هو هدفك؟';
      case 'pt': return 'Qual é o teu objetivo?';
      default: return 'What\'s your goal?';
    }
  }

  String _sub() {
    switch (lang) {
      case 'de': return 'Wähle, was du mit UpCrush erreichen möchtest.';
      case 'es': return 'Elige lo que quieres lograr con UpCrush.';
      case 'fr': return 'Choisis ce que tu veux accomplir avec UpCrush.';
      case 'it': return 'Scegli cosa vuoi ottenere con UpCrush.';
      case 'tr': return 'UpCrush ile ne başarmak istediğini seç.';
      case 'pl': return 'Wybierz, co chcesz osiągnąć z UpCrush.';
      case 'ru': return 'Выбери, чего хочешь достичь с UpCrush.';
      case 'ar': return 'اختر ما تريد تحقيقه مع UpCrush.';
      case 'pt': return 'Escolhe o que queres alcançar com o UpCrush.';
      default: return 'Choose what you want to achieve with UpCrush.';
    }
  }

  List<Map<String, String>> _options() {
    switch (lang) {
      case 'de': return [
        {'value': 'more_dates', 'emoji': '🎯', 'label': 'Mehr Dates bekommen'},
        {'value': 'better_replies', 'emoji': '', 'label': 'Bessere Antworten senden'},
        {'value': 'confidence', 'emoji': '🔥', 'label': 'Mehr Selbstbewusstsein'},
        {'value': 'relationship', 'emoji': '💎', 'label': 'Eine Beziehung finden'},
      ];
      case 'es': return [
        {'value': 'more_dates', 'emoji': '🎯', 'label': 'Conseguir más citas'},
        {'value': 'better_replies', 'emoji': '', 'label': 'Enviar mejores respuestas'},
        {'value': 'confidence', 'emoji': '🔥', 'label': 'Más confianza'},
        {'value': 'relationship', 'emoji': '💎', 'label': 'Encontrar una relación'},
      ];
      case 'pt': return [
        {'value': 'more_dates', 'emoji': '🎯', 'label': 'Conseguir mais datas'},
        {'value': 'better_replies', 'emoji': '', 'label': 'Enviar melhores respostas'},
        {'value': 'confidence', 'emoji': '🔥', 'label': 'Mais confiança'},
        {'value': 'relationship', 'emoji': '💎', 'label': 'Encontrar um relacionamento'},
      ];
      default: return [
        {'value': 'more_dates', 'emoji': '🎯', 'label': 'Get more dates'},
        {'value': 'better_replies', 'emoji': '', 'label': 'Send better replies'},
        {'value': 'confidence', 'emoji': '🔥', 'label': 'Build more confidence'},
        {'value': 'relationship', 'emoji': '💎', 'label': 'Find a relationship'},
      ];
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: isTablet ? 60 : 32),
      child: SingleChildScrollView(
        child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(height: 8),
          Text(_title(),
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: isTablet ? 42 : 32,
              fontWeight: FontWeight.w900,
              color: const Color(0xFF1C1C1E),
              letterSpacing: -1)),

          SizedBox(height: isTablet ? 14 : 10),

          Text(_sub(),
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: isTablet ? 17 : 14,
              color: Colors.black45, height: 1.4)),

          SizedBox(height: isTablet ? 40 : 28),

          ..._options().map((opt) => Padding(
            padding: const EdgeInsets.only(bottom: 14),
            child: _OptionCard(
              emoji: opt['emoji']!,
              label: opt['label']!,
              isSelected: selected == opt['value'],
              isTablet: isTablet,
              onTap: () => onSelect(opt['value']!)),
          )),
        ],
        ),
      ),
    );
  }
}

// ── PAGE 4 — App ─────────────────────────────────────────────────────────────
class _AppPage extends StatelessWidget {
  final bool isTablet;
  final String lang;
  final String? selected;
  final Function(String) onSelect;
  const _AppPage({required this.isTablet, required this.lang,
    required this.selected, required this.onSelect});

  String _title() {
    switch (lang) {
      case 'de': return 'Welche App nutzt du?';
      case 'es': return '¿Qué app usas?';
      case 'fr': return 'Quelle app utilises-tu ?';
      case 'it': return 'Quale app usi?';
      case 'tr': return 'Hangi uygulamayı kullanıyorsun?';
      case 'pl': return 'Jakiej aplikacji używasz?';
      case 'ru': return 'Какое приложение ты используешь?';
      case 'ar': return 'ما التطبيق الذي تستخدمه؟';
      case 'pt': return 'Que app usas?';
      default: return 'Which app do you use?';
    }
  }

  String _sub() {
    switch (lang) {
      case 'de': return 'Wir personalisieren deine Erfahrung.';
      case 'es': return 'Personalizamos tu experiencia.';
      case 'fr': return 'Nous personnalisons ton expérience.';
      case 'it': return 'Personalizziamo la tua esperienza.';
      case 'tr': return 'Deneyimini kişiselleştiriyoruz.';
      case 'pl': return 'Personalizujemy Twoje doświadczenie.';
      case 'ru': return 'Мы персонализируем твой опыт.';
      case 'ar': return 'نقوم بتخصيص تجربتك.';
      case 'pt': return 'Personalizamos a tua experiência.';
      default: return 'We\'ll personalize your experience.';
    }
  }

  @override
  Widget build(BuildContext context) {
    final apps = [
      {'value': 'tinder', 'emoji': '', 'label': 'Tinder'},
      {'value': 'bumble', 'emoji': '', 'label': 'Bumble'},
      {'value': 'hinge', 'emoji': '', 'label': 'Hinge'},
      {'value': 'instagram', 'emoji': '', 'label': 'Instagram'},
      {'value': 'whatsapp', 'emoji': '', 'label': 'WhatsApp'},
      {'value': 'other', 'emoji': '', 'label': lang == 'de' ? 'Andere' : lang == 'es' ? 'Otra' : lang == 'pt' ? 'Outra' : 'Other'},
    ];

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: isTablet ? 60 : 32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(_title(),
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: isTablet ? 42 : 32,
              fontWeight: FontWeight.w900,
              color: const Color(0xFF1C1C1E),
              letterSpacing: -1)),

          SizedBox(height: isTablet ? 14 : 10),

          Text(_sub(),
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: isTablet ? 17 : 14,
              color: Colors.black45, height: 1.4)),

          SizedBox(height: isTablet ? 48 : 36),

          // Grid 2x3
          GridView.count(
            shrinkWrap: true,
            physics: const BouncingScrollPhysics(),
            crossAxisCount: 2,
            crossAxisSpacing: 14,
            mainAxisSpacing: 14,
            childAspectRatio: isTablet ? 2.2 : 2.0,
            children: apps.map((app) => _AppCard(
              emoji: app['emoji']!,
              label: app['label']!,
              isSelected: selected == app['value'],
              isTablet: isTablet,
              onTap: () => onSelect(app['value']!),
            )).toList(),
          ),
        ],
      ),
    );
  }
}

// ── SHARED WIDGETS ───────────────────────────────────────────────────────────
class _OptionCard extends StatelessWidget {
  final String emoji, label;
  final bool isSelected, isTablet;
  final VoidCallback onTap;
  const _OptionCard({required this.emoji, required this.label,
    required this.isSelected, required this.isTablet, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: double.infinity,
        padding: EdgeInsets.symmetric(
          horizontal: isTablet ? 28 : 22,
          vertical: isTablet ? 22 : 18),
        decoration: BoxDecoration(
          color: isSelected
            ? const Color(0xFFFF2D55).withOpacity(0.06)
            : const Color(0xFFF8F8F8),
          borderRadius: BorderRadius.circular(isTablet ? 20 : 16),
          border: Border.all(
            color: isSelected ? const Color(0xFFFF2D55) : Colors.transparent,
            width: isSelected ? 2 : 0)),
        child: Row(children: [
          if (emoji.isNotEmpty) ...[
            Text(emoji, style: TextStyle(fontSize: isTablet ? 30 : 24)),
            SizedBox(width: isTablet ? 18 : 14),
          ],
          Text(label, style: TextStyle(
            fontSize: isTablet ? 20 : 17,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
            color: isSelected ? const Color(0xFFFF2D55) : const Color(0xFF1C1C1E))),
          const Spacer(),
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: isTablet ? 28 : 24,
            height: isTablet ? 28 : 24,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isSelected ? const Color(0xFFFF2D55) : Colors.transparent,
              border: Border.all(
                color: isSelected ? const Color(0xFFFF2D55) : Colors.black.withOpacity(0.2),
                width: 2)),
            child: isSelected
              ? Icon(Icons.check_rounded, color: Colors.white, size: isTablet ? 18 : 14)
              : null),
        ]),
      ),
    );
  }
}

class _AppCard extends StatelessWidget {
  final String emoji, label;
  final bool isSelected, isTablet;
  final VoidCallback onTap;
  const _AppCard({required this.emoji, required this.label,
    required this.isSelected, required this.isTablet, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          color: isSelected
            ? const Color(0xFFFF2D55).withOpacity(0.06)
            : const Color(0xFFF8F8F8),
          borderRadius: BorderRadius.circular(isTablet ? 20 : 16),
          border: Border.all(
            color: isSelected ? const Color(0xFFFF2D55) : Colors.transparent,
            width: isSelected ? 2 : 0)),
        child: Center(
          child: Text(label, style: TextStyle(
            fontSize: isTablet ? 18 : 15,
            fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
            color: isSelected ? const Color(0xFFFF2D55) : const Color(0xFF1C1C1E),
            letterSpacing: -0.3)),
        ),
      ),
    );
  }
}