import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../main.dart';
import 'home_screen.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  String? _selectedGender;

  static const _privacyUrl = 'https://sites.google.com/view/upcrush-privacy-policy/p%C3%A1gina-inicial';
  static const _termsUrl = 'https://sites.google.com/view/upcrush-terms/p%C3%A1gina-inicial';

  String _t(String key) {
    final code = appLang.languageCode;
    const Map<String, Map<String, String>> texts = {
      'title': {
        'de': 'Willkommen bei\nUpCrush 🌶️',
        'es': 'Bienvenido a\nUpCrush 🌶️',
        'fr': 'Bienvenue sur\nUpCrush 🌶️',
        'it': 'Benvenuto su\nUpCrush 🌶️',
        'tr': "UpCrush'a\nHoş Geldin 🌶️",
        'pl': 'Witaj w\nUpCrush 🌶️',
        'ru': 'Добро пожаловать\nв UpCrush 🌶️',
        'ar': 'مرحباً بك في\nUpCrush 🌶️',
        'en': 'Welcome to\nUpCrush 🌶️',
        'pt': 'Bem-vindo ao\nUpCrush 🌶️',
      },
      'subtitle': {
        'de': 'Wer bist du?',
        'es': '¿Quién eres?',
        'fr': 'Qui es-tu ?',
        'it': 'Chi sei?',
        'tr': 'Sen kimsin?',
        'pl': 'Kim jesteś?',
        'ru': 'Кто ты?',
        'ar': 'من أنت؟',
        'en': 'Who are you?',
        'pt': 'Quem és tu?',
      },
      'man': {
        'de': 'Mann', 'es': 'Hombre', 'fr': 'Homme', 'it': 'Uomo',
        'tr': 'Erkek', 'pl': 'Mężczyzna', 'ru': 'Мужчина', 'ar': 'رجل',
        'en': 'Man', 'pt': 'Homem',
      },
      'woman': {
        'de': 'Frau', 'es': 'Mujer', 'fr': 'Femme', 'it': 'Donna',
        'tr': 'Kadın', 'pl': 'Kobieta', 'ru': 'Женщина', 'ar': 'امرأة',
        'en': 'Woman', 'pt': 'Mulher',
      },

      'continue_btn': {
        'de': 'Weiter', 'es': 'Continuar', 'fr': 'Continuer', 'it': 'Continua',
        'tr': 'Devam et', 'pl': 'Dalej', 'ru': 'Далее', 'ar': 'استمر',
        'en': 'Continue', 'pt': 'Continuar',
      },
      'select_hint': {
        'de': 'Wähle eine Option', 'es': 'Elige una opción', 'fr': 'Choisissez une option',
        'it': 'Scegli un\'opzione', 'tr': 'Bir seçenek seçin', 'pl': 'Wybierz opcję',
        'ru': 'Выберите вариант', 'ar': 'اختر خياراً',
        'en': 'Select an option', 'pt': 'Seleciona uma opção',
      },
      'terms_note': {
        'de': 'Mit dem Fortfahren stimmst du unseren Nutzungsbedingungen und Datenschutzrichtlinien zu.',
        'es': 'Al continuar, aceptas nuestros Términos de uso y Política de privacidad.',
        'fr': "En continuant, vous acceptez nos Conditions d'utilisation et notre Politique de confidentialité.",
        'it': 'Continuando, accetti i nostri Termini di utilizzo e la nostra Informativa sulla privacy.',
        'tr': 'Devam ederek Kullanım Koşullarımızı ve Gizlilik Politikamızı kabul etmiş olursunuz.',
        'pl': 'Kontynuując, akceptujesz nasze Warunki użytkowania i Politykę prywatności.',
        'ru': 'Продолжая, вы соглашаетесь с нашими Условиями использования и Политикой конфиденциальности.',
        'ar': 'بالمتابعة، فإنك توافق على شروط الاستخدام وسياسة الخصوصية.',
        'en': 'By continuing, you agree to our Terms of Use and Privacy Policy.',
        'pt': 'Ao continuar, aceitas os nossos Termos de Uso e Política de Privacidade.',
      },
    };
    return texts[key]?[code] ?? texts[key]?['en'] ?? '';
  }

  Future<void> _continue() async {
    if (_selectedGender == null) return;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('user_gender', _selectedGender!);
    await prefs.setBool('onboarding_done', true);
    if (!mounted) return;
    Navigator.pushReplacement(context,
      MaterialPageRoute(builder: (_) => const HomeScreen()));
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder(
      valueListenable: appLangNotifier,
      builder: (_, lang, __) {
        final bottom = MediaQuery.of(context).padding.bottom;
        return Scaffold(
          backgroundColor: const Color(0xFF08080F),
          body: Stack(children: [
            // Background blobs
            Positioned(top: -80, left: -60, child: Container(width: 280, height: 280,
              decoration: BoxDecoration(shape: BoxShape.circle,
                color: const Color(0xFFFF2D55).withOpacity(0.10)))),
            Positioned(bottom: 100, right: -80, child: Container(width: 220, height: 220,
              decoration: BoxDecoration(shape: BoxShape.circle,
                color: const Color(0xFF5856D6).withOpacity(0.08)))),

            SafeArea(child: Padding(
              padding: EdgeInsets.fromLTRB(28, 40, 28, bottom + 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Logo
                  RichText(text: const TextSpan(children: [
                    TextSpan(text: "Up", style: TextStyle(
                      fontSize: 32, fontWeight: FontWeight.w900,
                      color: Colors.white, letterSpacing: -1)),
                    TextSpan(text: "Crush", style: TextStyle(
                      fontSize: 32, fontWeight: FontWeight.w900,
                      color: Color(0xFFFF2D55), letterSpacing: -1)),
                  ])),

                  const SizedBox(height: 40),

                  // Title
                  Text(_t('title'), style: const TextStyle(
                    color: Colors.white, fontSize: 36,
                    fontWeight: FontWeight.w900, letterSpacing: -1.2, height: 1.1)),

                  const SizedBox(height: 12),

                  Text(_t('subtitle'), style: TextStyle(
                    color: Colors.white.withOpacity(0.45), fontSize: 17, height: 1.4)),

                  const SizedBox(height: 48),

                  // Gender options
                  _genderCard('man', '👨', _t('man')),
                  const SizedBox(height: 14),
                  _genderCard('woman', '👩', _t('woman')),


                  const Spacer(),

                  // Terms note
                  Text(_t('terms_note'),
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.white.withOpacity(0.25),
                      fontSize: 11, height: 1.5)),

                  const SizedBox(height: 16),

                  // Continue button
                  SizedBox(width: double.infinity, height: 56,
                    child: ElevatedButton(
                      onPressed: _selectedGender != null ? _continue : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFFF2D55),
                        foregroundColor: Colors.white,
                        disabledBackgroundColor: const Color(0xFFFF2D55).withOpacity(0.3),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        elevation: 0),
                      child: Text(_t('continue_btn'),
                        style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800)),
                    )),
                ],
              ),
            )),
          ]),
        );
      },
    );
  }

  Widget _genderCard(String value, String emoji, String label) {
    final isSelected = _selectedGender == value;
    return GestureDetector(
      onTap: () => setState(() => _selectedGender = value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
        decoration: BoxDecoration(
          color: isSelected
            ? const Color(0xFFFF2D55).withOpacity(0.12)
            : Colors.white.withOpacity(0.05),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: isSelected ? const Color(0xFFFF2D55) : Colors.white.withOpacity(0.1),
            width: isSelected ? 1.5 : 1)),
        child: Row(children: [
          if (emoji.isNotEmpty) ...[
            Text(emoji, style: const TextStyle(fontSize: 28)),
            const SizedBox(width: 16),
          ],
          Text(label, style: TextStyle(
            color: isSelected ? Colors.white : Colors.white.withOpacity(0.7),
            fontSize: 18, fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500)),
          const Spacer(),
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: 24, height: 24,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isSelected ? const Color(0xFFFF2D55) : Colors.transparent,
              border: Border.all(
                color: isSelected ? const Color(0xFFFF2D55) : Colors.white.withOpacity(0.3),
                width: 2)),
            child: isSelected
              ? const Icon(Icons.check_rounded, color: Colors.white, size: 14)
              : null),
        ]),
      ),
    );
  }
}