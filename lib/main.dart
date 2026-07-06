import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'screens/home_screen.dart';
import 'screens/onboarding_screen.dart';
import 'theme/app_localizations.dart';
import 'services/credits_service.dart';
import 'services/revenue_cat_service.dart';
import 'widgets/paywall_screen.dart';

final ValueNotifier<AppLocalizations> appLangNotifier =
    ValueNotifier(AppLocalizations.fromDevice());

final ValueNotifier<bool> isDarkModeNotifier = ValueNotifier(false);

AppLocalizations get appLang => appLangNotifier.value;

Future<void> changeLanguage(String code) async {
  appLangNotifier.value = AppLocalizations(code);
  final prefs = await SharedPreferences.getInstance();
  await prefs.setString('selected_language', code);
}

Future<void> changeTheme(bool isDark) async {
  isDarkModeNotifier.value = isDark;
  final prefs = await SharedPreferences.getInstance();
  await prefs.setBool('is_dark_mode', isDark);
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.dark,
  ));

  final prefs = await SharedPreferences.getInstance();
  final savedLang = prefs.getString('selected_language');
  if (savedLang != null) {
    appLangNotifier.value = AppLocalizations(savedLang);
  }
  isDarkModeNotifier.value = prefs.getBool('is_dark_mode') ?? false;

  await Future.wait([
    CreditsService.init(),
    RevenueCatService.init(),
  ]);

  runApp(const UpCrushApp());
}

class UpCrushApp extends StatelessWidget {
  const UpCrushApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<AppLocalizations>(
      valueListenable: appLangNotifier,
      builder: (_, lang, __) => ValueListenableBuilder<bool>(
        valueListenable: isDarkModeNotifier,
        builder: (_, isDark, __) {
          SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle(
            statusBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
            statusBarColor: Colors.transparent,
          ));
          return MaterialApp(
            debugShowCheckedModeBanner: false,
            title: 'UpCrush',
            themeMode: isDark ? ThemeMode.dark : ThemeMode.light,
            theme: ThemeData(
              useMaterial3: true,
              brightness: Brightness.light,
              scaffoldBackgroundColor: const Color(0xFFF2F2F7),
              colorScheme: const ColorScheme.light(
                primary: Color(0xFFFF2D55),
                secondary: Color(0xFF007AFF),
              ),
              appBarTheme: const AppBarTheme(
                backgroundColor: Colors.transparent, elevation: 0),
            ),
            darkTheme: ThemeData(
              useMaterial3: true,
              brightness: Brightness.dark,
              scaffoldBackgroundColor: const Color(0xFF0A0A10),
              colorScheme: const ColorScheme.dark(
                primary: Color(0xFFFF2D55),
                secondary: Color(0xFF0A84FF),
              ),
              appBarTheme: const AppBarTheme(
                backgroundColor: Colors.transparent, elevation: 0),
            ),
            home: const _AppEntry(),
          );
        },
      ),
    );
  }
}

class _AppEntry extends StatelessWidget {
  const _AppEntry();

  static Future<Map<String, bool>> _check() async {
    final prefs = await SharedPreferences.getInstance();
    final onboardingDone = prefs.getBool('onboarding_done') ?? false;
    final isPremium = await RevenueCatService.isPremium();
    return {'onboarding': onboardingDone, 'premium': isPremium};
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, bool>>(
      future: _check(),
      builder: (context, snap) {
        if (!snap.hasData) {
          return const Scaffold(
            backgroundColor: Color(0xFF08080F),
            body: Center(
              child: CircularProgressIndicator(color: Color(0xFFFF2D55))));
        }
        final onboardingDone = snap.data!['onboarding']!;

        // 1. Onboarding primeiro
        if (!onboardingDone) return const OnboardingScreen();
        // 2. Home (paywall temporariamente desativado)
        return const HomeScreen();
      },
    );
  }
}

// Paywall rígido — sem botão de fechar, bloqueia back
class _PaywallGate extends StatelessWidget {
  const _PaywallGate();

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async => false,
      child: PaywallFlow(
        onSuccess: () => Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const HomeScreen())),
      ),
    );
  }
}