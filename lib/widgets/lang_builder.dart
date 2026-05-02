import 'package:flutter/material.dart';
import '../../../main.dart';
import '../theme/app_localizations.dart';

/// Usa este widget em vez de chamar appLang diretamente nas telas.
/// Reconstrói automaticamente quando o idioma muda.
///
/// Exemplo:
/// LangBuilder(builder: (lang) => Text(lang.appTagline))
class LangBuilder extends StatelessWidget {
  final Widget Function(AppLocalizations lang) builder;

  const LangBuilder({super.key, required this.builder});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<AppLocalizations>(
      valueListenable: appLangNotifier,
      builder: (context, lang, _) => builder(lang),
    );
  }
}