import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/ai_service.dart';
import '../../../main.dart';
import '../widgets/background_blobs.dart';

class ResultScreen extends StatefulWidget {
  final String title;
  final List<String> replies;
  final String originalPrompt;
  final String ultimaMensagem;
  final String style;
  final bool isDarkMode;

  const ResultScreen({
    super.key,
    required this.title,
    required this.replies,
    this.originalPrompt = "",
    this.ultimaMensagem = "",
    this.style = "natural",
    this.isDarkMode = false,
  });

  @override
  State<ResultScreen> createState() => _ResultScreenState();
}

class _ResultScreenState extends State<ResultScreen> {
  late List<String> replies;
  bool loading = false;
  String estiloAtual = "natural";
  int? copiedIndex;

  bool get _dark => isDarkModeNotifier.value;
  Color get _bg => _dark ? const Color(0xFF0A0A10) : const Color(0xFFF2F2F7);
  Color get _cardBg => _dark ? Colors.white.withOpacity(0.06) : Colors.white.withOpacity(0.75);
  Color get _cardBorder => _dark ? Colors.white.withOpacity(0.07) : Colors.white.withOpacity(0.9);
  Color get _textPrimary => _dark ? Colors.white : const Color(0xFF1C1C1E);
  Color get _textSecondary => _dark ? Colors.white38 : Colors.black38;
  static const _accent = Color(0xFFFF2D55);
  static const _success = Color(0xFF34C759);

  List<Map<String, dynamic>> _getEstilos(String lang) => [
    {"key": "engraçado",  "label": lang=='de'?'Lustig':lang=='es'?'Gracioso':lang=='fr'?'Drôle':lang=='pt'?'Engraçado':lang=='it'?'Divertente':lang=='tr'?'Komik':lang=='ru'?'Смешной':'Funny', "icon": Icons.sentiment_very_satisfied_rounded, "colors": [Color(0xFFFF9500), Color(0xFFFFCC02)], "shadow": Color(0xFFFF9500)},
    {"key": "picante",    "label": lang=='de'?'Pikant':lang=='es'?'Picante':lang=='fr'?'Piquant':lang=='pt'?'Picante':lang=='it'?'Piccante':lang=='tr'?'Ateşli':lang=='ru'?'Пикантный':'Spicy', "icon": Icons.local_fire_department_rounded, "colors": [Color(0xFFFF2D55), Color(0xFFFF6B81)], "shadow": Color(0xFFFF2D55)},
    {"key": "misterioso", "label": lang=='de'?'Mysteriös':lang=='es'?'Misterioso':lang=='fr'?'Mystérieux':lang=='pt'?'Misterioso':lang=='it'?'Misterioso':lang=='tr'?'Gizemli':lang=='ru'?'Загадочный':'Mysterious', "icon": Icons.nightlight_round, "colors": [Color(0xFF5856D6), Color(0xFFAF52DE)], "shadow": Color(0xFF5856D6)},
    {"key": "direto",     "label": lang=='de'?'Direkt':lang=='es'?'Directo':lang=='fr'?'Direct':lang=='pt'?'Direto':lang=='it'?'Diretto':lang=='tr'?'Doğrudan':lang=='ru'?'Прямой':'Direct', "icon": Icons.bolt_rounded, "colors": [Color(0xFF007AFF), Color(0xFF5AC8FA)], "shadow": Color(0xFF007AFF)},
  ];

  @override
  void initState() {
    super.initState();
    replies = widget.replies;
    estiloAtual = (['engraçado','picante','misterioso','direto'].contains(widget.style)) ? widget.style : 'picante';
  }

  Future<void> copy(String text, int index) async {
    await Clipboard.setData(ClipboardData(text: text));
    HapticFeedback.lightImpact();
    setState(() => copiedIndex = index);
    await Future.delayed(const Duration(seconds: 2));
    if (mounted) setState(() => copiedIndex = null);
  }

  Future<void> _gerar(String estilo, {bool diferente = false}) async {
    setState(() { estiloAtual = estilo; loading = true; });
    try {
      List<String> novas;
      final prompt = diferente
          ? widget.originalPrompt + "\nGenerate completely different responses."
          : widget.originalPrompt;

      if (prompt.startsWith("opener:")) {
        final base64 = prompt.substring(7);
        novas = await AIService.gerarOpenerDeImagem(base64, estilo, appLang.languageCode);
      } else if (prompt.startsWith("imagem:")) {
        final base64 = prompt.substring(7);
        novas = await AIService.gerarRespostaDeImagem(base64, estilo, appLang.languageCode);
      } else if (widget.ultimaMensagem.isNotEmpty) {
        novas = await AIService.gerarRespostaDeOCR(prompt, widget.ultimaMensagem, estilo, appLang.languageCode);
      } else {
        novas = await AIService.gerarResposta(prompt, estilo, appLang.languageCode);
      }
      setState(() { replies = novas; loading = false; });
    } catch (e) {
      setState(() => loading = false);
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Erro: $e"), backgroundColor: Colors.red));
    }
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder(
      valueListenable: appLangNotifier,
      builder: (context, lang, _) {
        final estilos = _getEstilos(lang.languageCode);
        return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: _bg,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_rounded, color: _textPrimary, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(widget.title,
            style: TextStyle(color: _textPrimary, fontSize: 17, fontWeight: FontWeight.w700, letterSpacing: -0.3)),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh_rounded, color: _textSecondary, size: 22),
            onPressed: loading ? null : () => _gerar(estiloAtual, diferente: true),
          ),
        ],
      ),
      body: BackgroundBlobs(
        isDark: _dark,
        child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Painel lateral de tom — cards verticais iguais à home
          SizedBox(
            width: 90,
            child: ListView.separated(
              padding: const EdgeInsets.fromLTRB(10, 4, 6, 20),
              itemCount: estilos.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (context, i) {
                final e = estilos[i];
                final ativo = e["key"] == estiloAtual;
                final colors = e["colors"] as List<Color>;
                return GestureDetector(
                  onTap: () => _gerar(e["key"]),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
                    decoration: BoxDecoration(
                      color: ativo ? null : _cardBg,
                      gradient: ativo ? LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [colors[0].withOpacity(0.18), colors[1].withOpacity(0.10)],
                      ) : null,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: ativo ? colors[0].withOpacity(0.5) : _cardBorder,
                        width: ativo ? 1.5 : 1,
                      ),
                      boxShadow: _dark ? [] : [
                        BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 2)),
                      ],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 38, height: 38,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: colors),
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [BoxShadow(color: (e["shadow"] as Color).withOpacity(ativo ? 0.45 : 0.25), blurRadius: 8, offset: const Offset(0, 3))],
                          ),
                          child: Icon(e["icon"] as IconData, color: Colors.white, size: 18),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          e["label"],
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: ativo ? FontWeight.w700 : FontWeight.w500,
                            color: _textPrimary,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),

          // Lista de respostas
          Expanded(
            child: loading
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const CircularProgressIndicator(color: _accent, strokeWidth: 2.5),
                        const SizedBox(height: 16),
                        Text(appLang.resultGenerating,
                            style: TextStyle(color: _textSecondary, fontSize: 14)),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.fromLTRB(6, 4, 16, 120),
                    itemCount: replies.length,
                    itemBuilder: (context, index) {
                      final isCopied = copiedIndex == index;
                      return GestureDetector(
                        onTap: () => copy(replies[index], index),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          margin: const EdgeInsets.only(bottom: 12),
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: isCopied ? _success.withOpacity(_dark ? 0.12 : 0.08) : _cardBg,
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(
                              color: isCopied ? _success.withOpacity(0.4) : _cardBorder,
                              width: isCopied ? 1.5 : 1,
                            ),
                            boxShadow: _dark ? [] : [
                              BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 3)),
                              BoxShadow(color: Colors.white.withOpacity(0.8), blurRadius: 0, offset: const Offset(0, 1)),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(replies[index],
                                  style: TextStyle(color: _textPrimary, fontSize: 14, height: 1.5, fontWeight: FontWeight.w400)),
                              const SizedBox(height: 10),
                              Align(
                                alignment: Alignment.centerRight,
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 200),
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: isCopied ? _success.withOpacity(0.12) : _accent.withOpacity(0.08),
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(color: isCopied ? _success.withOpacity(0.4) : _accent.withOpacity(0.2)),
                                  ),
                                  child: Text(
                                    isCopied ? appLang.resultCopied : appLang.resultCopy,
                                    style: TextStyle(
                                      color: isCopied ? _success : _accent,
                                      fontSize: 12, fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
      ),
      bottomNavigationBar: Padding(
        padding: EdgeInsets.fromLTRB(16, 0, 16, MediaQuery.of(context).padding.bottom + 16),
        child: SizedBox(
          height: 54,
          child: ElevatedButton(
            onPressed: loading ? null : () => _gerar(estiloAtual, diferente: true),
            style: ElevatedButton.styleFrom(
              backgroundColor: _accent, foregroundColor: Colors.white,
              disabledBackgroundColor: _accent.withOpacity(0.5),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              elevation: 0,
            ),
            child: loading
                ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                : Text(appLang.resultMoreButton,
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
          ),
        ),
      ),
        );
      },
    );
  }
}