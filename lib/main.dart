import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'screens/home_screen.dart';
import 'theme/app_localizations.dart';
import 'services/credits_service.dart';
import 'services/revenue_cat_service.dart';

final ValueNotifier<AppLocalizations> appLangNotifier =
    ValueNotifier(AppLocalizations.fromDevice());

final ValueNotifier<bool> isDarkModeNotifier = ValueNotifier(false);

AppLocalizations get appLang => appLangNotifier.value;

Future<void> changeLanguage(String code) async {
  appLangNotifier.value = AppLocalizations(code);
  final prefs = await SharedPreferences.getInstance();
  await prefs.setString('user_selected_language', code);
  await prefs.setBool('user_changed_language', true);
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

  // Só usa idioma guardado se o utilizador mudou MANUALMENTE nas definições
  // Caso contrário usa SEMPRE o idioma do telemóvel
  final userChangedLang = prefs.getBool('user_changed_language') ?? false;
  if (userChangedLang) {
    final savedLang = prefs.getString('user_selected_language');
    if (savedLang != null) {
      appLangNotifier.value = AppLocalizations(savedLang);
    }
  }
  // else: fromDevice() já está ativo desde o início ✅

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
              scaffoldBackgroundColor: const Color(0xFF212121),
              colorScheme: const ColorScheme.dark(
                primary: Color(0xFFFF2D55),
                secondary: Color(0xFF0A84FF),
              ),
              appBarTheme: const AppBarTheme(
                  backgroundColor: Colors.transparent, elevation: 0),
            ),
            home: const HomeScreen(),
          );
        },
      ),
    );
  }
}