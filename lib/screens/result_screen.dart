import '../services/tones/tone_registry.dart';
import '../theme/tone_options.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/ai_service.dart';
import '../services/chat_history_service.dart';
import '../main.dart';
import '../widgets/background_blobs.dart';

class ResultScreen extends StatefulWidget {
  final String title;
  final List<String> replies;
  final String originalPrompt;
  final String ultimaMensagem;
  final String style;
  final bool isDarkMode;
  final String? savedChatId;

  const ResultScreen({
    super.key,
    required this.title,
    required this.replies,
    this.originalPrompt = "",
    this.ultimaMensagem = "",
    this.style = "romantico",
    this.isDarkMode = false,
    this.savedChatId,
  });

  @override
  State<ResultScreen> createState() => _ResultScreenState();
}

class _ResultScreenState extends State<ResultScreen> {
  late List<String> replies;
  bool loading = false;
  late final String _chatId;
  Future<void> _saveChat() async {
    if (replies.isEmpty) return;
    await ChatHistoryService.save(SavedChat(
      id: _chatId, kind: 'reply', title: widget.title,
      prompt: widget.originalPrompt, lastMessage: widget.ultimaMensagem,
      style: estiloAtual, replies: List.of(replies), updatedAt: DateTime.now()));
  }
  String estiloAtual = "romantico";
  int? copiedIndex;
  String? _stock;
  Future<void>? _stockEmCurso;
  int _versao = 0;
  String _idiomaStock = '';


  bool get _dark => isDarkModeNotifier.value;
  Color get _bg => _dark ? const Color(0xFF0A0A10) : const Color(0xFFF2F2F7);
  Color get _cardBg => _dark ? Colors.white.withOpacity(0.06) : Colors.white.withOpacity(0.75);
  Color get _cardBorder => _dark ? Colors.white.withOpacity(0.07) : Colors.white.withOpacity(0.9);
  Color get _textPrimary => _dark ? Colors.white : const Color(0xFF1C1C1E);
  Color get _textSecondary => _dark ? Colors.white38 : Colors.black38;
  static const _accent = Color(0xFFFF2D55);
  static const _success = Color(0xFF34C759);

  List<Map<String, dynamic>> _getEstilos(String lang) => toneOptions(lang);

  @override
  void initState() {
    super.initState();
    _chatId = widget.savedChatId ?? DateTime.now().microsecondsSinceEpoch.toString();
    replies = widget.savedChatId == null ? widget.replies.take(1).toList() : List.of(widget.replies);
    WidgetsBinding.instance.addPostFrameCallback((_) => _prepararStock());
    final normalizedStyle = ToneRegistry.normalize(widget.style);
    estiloAtual = toneOptions('pt').any((tone) => tone['key'] == normalizedStyle)
        ? normalizedStyle
        : 'romantico';
    if (widget.savedChatId == null) _saveChat();
  }

  Future<void> copy(String text, int index) async {
    await Clipboard.setData(ClipboardData(text: text));
    HapticFeedback.lightImpact();
    setState(() => copiedIndex = index);
    await Future.delayed(const Duration(seconds: 2));
    if (mounted) setState(() => copiedIndex = null);
  }

  Future<String?> _pedirUma(String estilo, String idioma) async {
    final prompt = widget.originalPrompt;
    List<String> novas;
    if (prompt.startsWith('opener:')) {
      novas = await AIService.gerarOpenerDeImagem(prompt.substring(7), estilo, idioma);
    } else if (prompt.startsWith('imagem:')) {
      novas = await AIService.gerarRespostaDeImagem(prompt.substring(7), estilo, idioma, quantidade: 1);
    } else if (widget.ultimaMensagem.isNotEmpty) {
      novas = await AIService.gerarRespostaDeOCR(prompt, widget.ultimaMensagem, estilo, idioma);
    } else {
      novas = await AIService.gerarResposta(prompt, estilo, idioma, quantidade: 1);
    }
    for (final item in novas) {
      if (item.trim().isNotEmpty && !replies.contains(item.trim())) return item.trim();
    }
    return null;
  }

  void _invalidarStock() { _versao++; _stock = null; _stockEmCurso = null; }

  void _prepararStock() {
    if (!mounted || replies.isEmpty || _stock != null || _stockEmCurso != null) return;
    final versao = _versao;
    final idioma = appLang.languageCode;
    _idiomaStock = idioma;
    _stockEmCurso = _pedirUma(estiloAtual, idioma).then((resposta) {
      if (mounted && versao == _versao && idioma == appLang.languageCode) _stock = resposta;
    }).catchError((Object _) {}).whenComplete(() {
      if (versao == _versao) _stockEmCurso = null;
    });
  }

  Future<void> _gerar(String estilo, {bool diferente = false}) async {
    if (loading) return;
    if (estiloAtual != estilo || _idiomaStock != appLang.languageCode) _invalidarStock();
    if (estiloAtual != estilo) setState(() => estiloAtual = estilo);
    final versao = _versao;
    var resposta = _stock;
    if (resposta != null) {
      setState(() { replies.insert(0, resposta!); _stock = null; copiedIndex = null; });
      _saveChat();
      _prepararStock();
      return;
    }
    setState(() => loading = true);
    try {
      if (_stockEmCurso != null) await _stockEmCurso;
      resposta = _stock;
      resposta ??= await _pedirUma(estilo, appLang.languageCode);
      if (!mounted || versao != _versao) return;
      if (resposta == null) throw Exception('Resposta vazia');
      setState(() { replies.insert(0, resposta!); _stock = null; loading = false; });
      _saveChat();
      _prepararStock();
    } catch (e) {
      if (!mounted) return;
      setState(() => loading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro: $e'), backgroundColor: Colors.red));
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
              separatorBuilder: (_, __) => const SizedBox(height: 6),
              itemBuilder: (context, i) {
                final e = estilos[i];
                final ativo = e["key"] == estiloAtual;
                final colors = e["colors"] as List<Color>;
                return GestureDetector(
                  onTap: () => _gerar(e["key"]),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 6),
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
                          width: 30, height: 30,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: colors),
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [BoxShadow(color: (e["shadow"] as Color).withOpacity(ativo ? 0.45 : 0.25), blurRadius: 8, offset: const Offset(0, 3))],
                          ),
                          child: e["key"] == 'flertar'
                      ? const Center(child: Text('❣️', style: TextStyle(fontSize: 17)))
                      : Icon(e["icon"] as IconData, color: Colors.white, size: 18),
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
                            color: const Color(0xFF1677F2),
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
                                  style: TextStyle(color: Colors.white, fontSize: 14, height: 1.5, fontWeight: FontWeight.w400)),
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