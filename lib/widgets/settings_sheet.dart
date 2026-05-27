import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../main.dart';
import 'paywall_screen.dart';

class SettingsSheet extends StatefulWidget {
  final Function(String) onLanguageChanged;
  final Function(bool) onThemeChanged;
  final bool isDarkMode;

  const SettingsSheet({
    super.key,
    required this.onLanguageChanged,
    required this.onThemeChanged,
    required this.isDarkMode,
  });

  @override
  State<SettingsSheet> createState() => _SettingsSheetState();
}

class _SettingsSheetState extends State<SettingsSheet> {
  final List<Map<String, String>> _languages = [
    {"code": "en", "flag": "🇬🇧", "name": "English"},
    {"code": "pt", "flag": "🇵🇹", "name": "Português"},
    {"code": "de", "flag": "🇩🇪", "name": "Deutsch"},
    {"code": "es", "flag": "🇪🇸", "name": "Español"},
    {"code": "fr", "flag": "🇫🇷", "name": "Français"},
    {"code": "it", "flag": "🇮🇹", "name": "Italiano"},
    {"code": "tr", "flag": "🇹🇷", "name": "Türkçe"},
    {"code": "pl", "flag": "🇵🇱", "name": "Polski"},
    {"code": "ru", "flag": "🇷🇺", "name": "Русский"},
    {"code": "ar", "flag": "🇸🇦", "name": "العربية"},
  ];

  bool get _dark => widget.isDarkMode;
  Color get _bg => _dark ? const Color(0xFF0A0A10) : Colors.white;
  Color get _textPrimary => _dark ? Colors.white : const Color(0xFF1C1C1E);
  Color get _textSecondary => _dark ? Colors.white38 : Colors.black38;
  Color get _divider => _dark ? Colors.white10 : Colors.black.withOpacity(0.06);
  static const _accent = Color(0xFFFF2D55);

  String _settingsTitle(String code) {
    switch (code) {
      case 'de': return 'Einstellungen';
      case 'es': return 'Ajustes';
      case 'fr': return 'Paramètres';
      case 'it': return 'Impostazioni';
      case 'tr': return 'Ayarlar';
      case 'pl': return 'Ustawienia';
      case 'ru': return 'Настройки';
      case 'ar': return 'الإعدادات';
      case 'en': return 'Settings';
      default:   return 'Definições';
    }
  }

  String _langLabel(String code) {
    switch (code) {
      case 'de': return 'Sprache';
      case 'es': return 'Idioma';
      case 'fr': return 'Langue';
      case 'it': return 'Lingua';
      case 'tr': return 'Dil';
      case 'pl': return 'Język';
      case 'ru': return 'Язык';
      case 'ar': return 'اللغة';
      case 'en': return 'Language';
      default:   return 'Idioma';
    }
  }

  String _themeLabel(String code, bool isDark) {
    // Mostra o modo OPOSTO — se está escuro mostra "Modo claro" e vice-versa
    if (isDark) {
      // Está em modo escuro → opção para mudar para claro
      switch (code) {
        case 'de': return 'Dunkelmodus';
        case 'es': return 'Modo oscuro';
        case 'fr': return 'Mode sombre';
        case 'it': return 'Modalità scura';
        case 'tr': return 'Koyu mod';
        case 'pl': return 'Tryb ciemny';
        case 'ru': return 'Тёмный режим';
        case 'ar': return 'الوضع الداكن';
        case 'en': return 'Dark mode';
        default:   return 'Modo escuro';
      }
    } else {
      // Está em modo claro → opção para mudar para escuro
      switch (code) {
        case 'de': return 'Hellmodus';
        case 'es': return 'Modo claro';
        case 'fr': return 'Mode clair';
        case 'it': return 'Modalità chiara';
        case 'tr': return 'Açık mod';
        case 'pl': return 'Tryb jasny';
        case 'ru': return 'Светлый режим';
        case 'ar': return 'الوضع الفاتح';
        case 'en': return 'Light mode';
        default:   return 'Modo claro';
      }
    }
  }

  String _currentLangName(String code) {
    final l = _languages.firstWhere(
      (x) => x["code"] == code, orElse: () => _languages[0]);
    return "${l["flag"]}  ${l["name"]}";
  }

  // Fecha as definições e abre o picker de idioma
  void _openLangPicker(String currentCode) {
    Navigator.pop(context); // fecha definições
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _LangPickerSheet(
        languages: _languages,
        selectedCode: currentCode,
        isDark: _dark,
        onSelect: (code) async {
          await changeLanguage(code);
          widget.onLanguageChanged(code);
        },
      ),
    );
  }

  void _openPaywall() {
    Navigator.pop(context);
    Navigator.push(context, MaterialPageRoute(
      fullscreenDialog: true, builder: (_) => const PaywallFlow()));
  }

  void _openEmail() {
    Clipboard.setData(const ClipboardData(text: "support@upcrush.app"));
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: const Text("Email copiado!"),
      backgroundColor: const Color(0xFF34C759),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      duration: const Duration(seconds: 2),
    ));
  }

  void _shareApp() {
    Clipboard.setData(const ClipboardData(text: "https://upcrush.app"));
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: const Text("Link copiado!"),
      backgroundColor: const Color(0xFF34C759),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      duration: const Duration(seconds: 2),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder(
      valueListenable: appLangNotifier,
      builder: (_, lang, __) {
        return Container(
          decoration: BoxDecoration(
            color: _bg,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Handle
              Container(
                margin: const EdgeInsets.only(top: 12, bottom: 8),
                width: 36, height: 4,
                decoration: BoxDecoration(
                  color: _dark ? Colors.white24 : Colors.black12,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),

              // Título
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(_settingsTitle(lang.languageCode),
                        style: TextStyle(color: _textPrimary, fontSize: 17,
                            fontWeight: FontWeight.w700)),
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Container(
                        width: 28, height: 28,
                        decoration: BoxDecoration(
                          color: _dark ? Colors.white12 : Colors.black.withOpacity(0.07),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(Icons.close, size: 16,
                            color: _dark ? Colors.white60 : Colors.black45),
                      ),
                    ),
                  ],
                ),
              ),

              // Idioma — clique fecha definições e abre picker
              _buildItem(
                "🌍", _langLabel(lang.languageCode),
                onTap: () => _openLangPicker(lang.languageCode),
                trailing: Text(_currentLangName(lang.languageCode),
                    style: TextStyle(color: _textSecondary, fontSize: 13)),
              ),

              // Tema
              _buildItem(
                widget.isDarkMode ? "☀️" : "🌙",
                _themeLabel(lang.languageCode, widget.isDarkMode),
                onTap: () => changeTheme(!widget.isDarkMode),
                trailing: Switch(
                  value: widget.isDarkMode,
                  onChanged: changeTheme,
                  activeColor: _accent,
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
              ),

              _buildItem("🔗", _shareLabel(lang.languageCode), onTap: _shareApp),
              _buildItem("📧", _supportLabel(lang.languageCode), onTap: _openEmail),
              _buildItem("💎", _premiumLabel(lang.languageCode),
                  onTap: _openPaywall, isAccent: true),

              const SizedBox(height: 20),

              Text("UpCrush", style: TextStyle(fontSize: 16,
                  fontWeight: FontWeight.w800, color: _textPrimary, letterSpacing: -0.5)),
              const SizedBox(height: 10),

              Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                GestureDetector(
                  onTap: () async { try { await launchUrl(Uri.parse('https://sites.google.com/view/upcrush-terms/p%C3%A1gina-inicial'), mode: LaunchMode.externalApplication); } catch (_) {} },
                  child: Text("Terms", style: TextStyle(fontSize: 13,
                      color: _textSecondary, decoration: TextDecoration.underline))),
                Text("  ·  ", style: TextStyle(color: _textSecondary, fontSize: 13)),
                GestureDetector(
                  onTap: () async { try { await launchUrl(Uri.parse('https://sites.google.com/view/upcrush-privacy-policy/p%C3%A1gina-inicial'), mode: LaunchMode.externalApplication); } catch (_) {} },
                  child: Text("Privacy", style: TextStyle(fontSize: 13,
                      color: _textSecondary, decoration: TextDecoration.underline))),
              ]),

              SizedBox(height: MediaQuery.of(context).padding.bottom + 20),
            ],
          ),
        );
      },
    );
  }

  String _shareLabel(String code) {
    switch (code) {
      case 'de': return 'App teilen';
      case 'es': return 'Compartir app';
      case 'fr': return "Partager l'app";
      case 'it': return 'Condividi app';
      case 'tr': return 'Uygulamayı paylaş';
      case 'pl': return 'Udostępnij app';
      case 'ru': return 'Поделиться';
      case 'ar': return 'مشاركة التطبيق';
      case 'en': return 'Share app';
      default:   return 'Partilhar app';
    }
  }

  String _supportLabel(String code) {
    switch (code) {
      case 'de': return 'Support kontaktieren';
      case 'es': return 'Contactar soporte';
      case 'fr': return 'Contacter le support';
      case 'it': return 'Contatta supporto';
      case 'tr': return 'Destek ile iletişim';
      case 'pl': return 'Skontaktuj się z pomocą';
      case 'ru': return 'Связаться с поддержкой';
      case 'ar': return 'التواصل مع الدعم';
      case 'en': return 'Contact support';
      default:   return 'Contactar suporte';
    }
  }

  String _premiumLabel(String code) {
    return 'Upgrade';
  }

  Widget _buildItem(String icon, String label, {
    required VoidCallback onTap, Widget? trailing, bool isAccent = false}) {
    return Column(children: [
      InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          child: Row(children: [
            Text(icon, style: const TextStyle(fontSize: 20)),
            const SizedBox(width: 16),
            Text(label, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500,
                color: isAccent ? _accent : _textPrimary)),
            const Spacer(),
            if (trailing != null) trailing
            else Icon(Icons.arrow_forward_ios, size: 14, color: _textSecondary),
          ]),
        ),
      ),
      Divider(height: 1, thickness: 0.5, color: _divider, indent: 20, endIndent: 20),
    ]);
  }
}

// ─── PICKER DE IDIOMA — bottom sheet separado ────────────────────────────────
class _LangPickerSheet extends StatefulWidget {
  final List<Map<String, String>> languages;
  final String selectedCode;
  final bool isDark;
  final Function(String) onSelect;

  const _LangPickerSheet({
    required this.languages,
    required this.selectedCode,
    required this.isDark,
    required this.onSelect,
  });

  @override
  State<_LangPickerSheet> createState() => _LangPickerSheetState();
}

class _LangPickerSheetState extends State<_LangPickerSheet> {
  late String _selected;

  @override
  void initState() {
    super.initState();
    _selected = widget.selectedCode;
  }

  bool get _dark => widget.isDark;
  Color get _bg => _dark ? const Color(0xFF0A0A10) : Colors.white;
  Color get _surface => _dark ? Colors.white.withOpacity(0.06) : const Color(0xFFF2F2F7);
  Color get _textPrimary => _dark ? Colors.white : const Color(0xFF1C1C1E);
  Color get _textSecondary => _dark ? Colors.white38 : Colors.black38;
  Color get _divider => _dark ? Colors.white10 : Colors.black.withOpacity(0.06);
  static const _accent = Color(0xFFFF2D55);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: _bg,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle
          Container(
            margin: const EdgeInsets.only(top: 12, bottom: 8),
            width: 36, height: 4,
            decoration: BoxDecoration(
              color: _dark ? Colors.white24 : Colors.black12,
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: Row(
              children: [
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    width: 32, height: 32,
                    decoration: BoxDecoration(
                      color: _dark ? Colors.white12 : Colors.black.withOpacity(0.07),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.arrow_back_ios_rounded, size: 14,
                        color: _dark ? Colors.white60 : Colors.black45),
                  ),
                ),
                const SizedBox(width: 12),
                Text("Idioma / Language",
                    style: TextStyle(color: _textPrimary, fontSize: 17,
                        fontWeight: FontWeight.w700)),
              ],
            ),
          ),

          // Lista de idiomas
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            itemCount: widget.languages.length,
            separatorBuilder: (_, __) => Divider(
                height: 1, thickness: 0.5, color: _divider,
                indent: 16, endIndent: 16),
            itemBuilder: (context, i) {
              final lang = widget.languages[i];
              final active = lang["code"] == _selected;
              return GestureDetector(
                onTap: () {
                  setState(() => _selected = lang["code"]!);
                  widget.onSelect(lang["code"]!);
                  Navigator.pop(context);
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  decoration: BoxDecoration(
                    color: active ? _accent.withOpacity(0.06) : Colors.transparent,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(children: [
                    Text(lang["flag"]!, style: const TextStyle(fontSize: 24)),
                    const SizedBox(width: 14),
                    Text(lang["name"]!, style: TextStyle(
                        fontSize: 16,
                        color: active ? _accent : _textPrimary,
                        fontWeight: active ? FontWeight.w700 : FontWeight.w400)),
                    const Spacer(),
                    if (active)
                      Container(
                        width: 24, height: 24,
                        decoration: const BoxDecoration(
                            color: _accent, shape: BoxShape.circle),
                        child: const Icon(Icons.check_rounded,
                            color: Colors.white, size: 14),
                      ),
                  ]),
                ),
              );
            },
          ),

          SizedBox(height: MediaQuery.of(context).padding.bottom + 16),
        ],
      ),
    );
  }
}