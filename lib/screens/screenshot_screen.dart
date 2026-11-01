import '../theme/tone_options.dart';
import 'dart:io';
import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';

import '../services/ai_service.dart';
import '../widgets/background_blobs.dart';
import '../main.dart';
import '../services/review_request_service.dart';

class ScreenshotScreen extends StatefulWidget {
  const ScreenshotScreen({super.key});

  @override
  State<ScreenshotScreen> createState() => _ScreenshotScreenState();
}

class _ScreenshotScreenState extends State<ScreenshotScreen>
    with TickerProviderStateMixin {
  File? _imagem;
  String? _base64Image;

  bool _analisando = false;
  bool _erro = false;
  String _erroMsg = '';

  List<String> _respostas = [];

  // Novas respostas entram acima; o histórico continua acessível ao rolar.
  void _adicionarResposta(String resposta) {
    _respostas.insert(0, resposta);
  }

  final GlobalKey _respostasIniciaisKey = GlobalKey();

  void _revelarRespostasIniciais() {
    if (_respostas.isEmpty || _respostas.length > 2) return;
    final versao = _versao;
    final quantidade = _respostas.length;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || versao != _versao || _respostas.length != quantidade)
        return;
      final alvo = _respostasIniciaisKey.currentContext;
      if (alvo == null) return;
      Scrollable.ensureVisible(
        alvo,
        alignment: 1,
        duration: const Duration(milliseconds: 280),
        curve: Curves.easeOut,
        alignmentPolicy: ScrollPositionAlignmentPolicy.explicit,
      );
    });
  }

  final ScrollController _respostasScrollController = ScrollController();

  String _estiloAtual = 'flertar';

  bool _loadingEstilo = false;
  String? _stock;
  Future<void>? _stockEmCurso;
  int _versao = 0;
  String _idiomaStock = '';

  late AnimationController _scanController;
  late Animation<double> _scanAnim;

  static const _accent = Color(0xFFFF2D55);

  bool get _dark => isDarkModeNotifier.value;

  Color get _bg => _dark ? const Color(0xFF0A0A10) : const Color(0xFFEDE4F3);

  Color get _cardBg =>
      _dark ? Colors.white.withOpacity(0.06) : Colors.white.withOpacity(0.85);

  Color get _cardBorder =>
      _dark ? Colors.white.withOpacity(0.08) : Colors.white.withOpacity(0.9);

  Color get _textPrimary => _dark ? Colors.white : const Color(0xFF1C1C1E);

  Color get _textSecondary => _dark ? Colors.white38 : Colors.black38;

  // ============================================================
  // ESTILOS
  // ============================================================

  List<Map<String, dynamic>> _getEstilos(String lang) => toneOptions(lang);

  // ============================================================
  // INIT
  // ============================================================

  @override
  void initState() {
    super.initState();

    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle.dark);

    isDarkModeNotifier.addListener(_onThemeChange);

    _scanController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat();

    _scanAnim = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _scanController, curve: Curves.easeInOut),
    );

    WidgetsBinding.instance.addPostFrameCallback((_) => _processarImagem());
  }

  @override
  void dispose() {
    isDarkModeNotifier.removeListener(_onThemeChange);

    _respostasScrollController.dispose();
    _scanController.dispose();

    super.dispose();
  }

  void _onThemeChange() {
    if (mounted) {
      setState(() {});
    }
  }

  // ============================================================
  // PROCESSAR IMAGEM
  // ============================================================

  void _invalidarStock() {
    _versao++;
    _stock = null;
    _stockEmCurso = null;
  }

  Future<String?> _pedirUma(String imagem, String estilo, String idioma) async {
    final lista = await AIService.gerarRespostaDeImagem(
      imagem,
      estilo,
      idioma,
      quantidade: 1,
      modoRapido: true,
      recentResponses: _respostas.take(24).toList().reversed.toList(),
    );
    for (final texto in lista) {
      final limpa = texto.trim();
      if (limpa.isNotEmpty && !_respostas.contains(limpa)) return limpa;
    }
    return null;
  }

  void _prepararStock() {
    if (_base64Image == null || _stock != null || _stockEmCurso != null) return;
    final versao = _versao;
    final idioma = appLang.languageCode;
    _idiomaStock = idioma;
    _stockEmCurso = _pedirUma(_base64Image!, _estiloAtual, idioma)
        .then((texto) {
          if (mounted && versao == _versao && idioma == appLang.languageCode)
            _stock = texto;
        })
        .catchError((Object _) {})
        .whenComplete(() {
          if (versao == _versao) _stockEmCurso = null;
        });
  }

  Future<void> _processarImagem() async {
    final picker = ImagePicker();
    try {
      final img = await picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 60,
      );
      if (img == null) {
        if (mounted) Navigator.pop(context);
        return;
      }
      final base64 = base64Encode(await File(img.path).readAsBytes());
      if (!mounted) return;
      _invalidarStock();
      final versao = _versao;
      setState(() {
        _estiloAtual = 'flertar';
        _loadingEstilo = false;
        _imagem = File(img.path);
        _base64Image = base64;
        _analisando = true;
        _erro = false;
        _respostas = [];
      });
      final resposta = await _pedirUma(
        base64,
        _estiloAtual,
        appLang.languageCode,
      );
      if (!mounted || versao != _versao) return;
      setState(() {
        _respostas = resposta == null ? [] : [resposta];
        _analisando = false;
      });
      _revelarRespostasIniciais();
      _prepararStock();
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _analisando = false;
        _erro = true;
        _erroMsg = _erroMsg2(appLang.languageCode);
      });
    }
  }

  // ============================================================
  // MENSAGEM DE ERRO
  // ============================================================

  String _erroMsg2(String lang) {
    switch (lang) {
      case 'de':
        return 'Verbindungsfehler.\nPrüfe deine Verbindung und versuche es erneut.';

      case 'es':
        return 'Error de conexión.\nVerifica tu conexión e inténtalo de nuevo.';

      case 'pt':
        return 'Algo deu errado.\nVerifica a conexão e tenta novamente.';

      case 'fr':
        return 'Une erreur est survenue.\nVérifie ta connexion et réessaie.';

      case 'it':
        return 'Qualcosa è andato storto.\nControlla la connessione e riprova.';

      case 'tr':
        return 'Bir şeyler ters gitti.\nBağlantını kontrol edip tekrar dene.';

      case 'ru':
        return 'Что-то пошло не так.\nПроверь соединение и попробуй снова.';

      default:
        return 'Something went wrong.\nCheck your connection and try again.';
    }
  }

  // ============================================================
  // GERAR COM ESTILO
  // ============================================================

  Future<void> _gerarComEstilo(String estilo) async {
    if (_base64Image == null || _analisando || _loadingEstilo) return;
    if (_estiloAtual != estilo) {
      _invalidarStock();
      setState(() => _estiloAtual = estilo);
    }
    await _gerarDiferente();
  }

  Future<void> _gerarDiferente() async {
    if (_base64Image == null || _analisando || _loadingEstilo) return;
    if (_idiomaStock != appLang.languageCode) _invalidarStock();
    final versao = _versao;
    var resposta = _stock;
    if (resposta != null) {
      setState(() {
        _adicionarResposta(resposta!);
        _stock = null;
      });
      _revelarRespostasIniciais();
      _prepararStock();
      return;
    }
    setState(() {
      _loadingEstilo = true;
      _erro = false;
    });
    try {
      if (_stockEmCurso != null) await _stockEmCurso;
      resposta = _stock;
      resposta ??= await _pedirUma(
        _base64Image!,
        _estiloAtual,
        appLang.languageCode,
      );
      if (!mounted || versao != _versao) return;
      if (resposta == null) throw Exception('Resposta vazia');
      setState(() {
        _adicionarResposta(resposta!);
        _stock = null;
        _loadingEstilo = false;
      });
      _revelarRespostasIniciais();
      _prepararStock();
    } catch (_) {
      if (mounted)
        setState(() {
          _loadingEstilo = false;
          _erro = true;
          _erroMsg = _erroMsg2(appLang.languageCode);
        });
    }
  }

  // ============================================================
  // COPIAR
  // ============================================================

  Future<void> _copiar(String texto, int index) async {
    await Clipboard.setData(ClipboardData(text: texto));
    HapticFeedback.lightImpact();
    ReviewRequestService.notifySuccess();
  }

  // ============================================================
  // LOADING
  // ============================================================

  String _getFunLoadingMsg(String lang) => switch (lang) {
    'pt' => 'Cozinhando seus flertes...',
    'de' => 'Koche deine Flirts...',
    'es' => 'Cocinando tus flirts...',
    'fr' => 'On cuisine tes flirts...',
    'it' => 'Cucinando i tuoi flirt...',
    'tr' => 'Flörtlerin pişiyor...',
    'pl' => 'Gotuję twoje flirty...',
    'ru' => 'Готовлю твой флирт...',
    'ar' => 'يُطبخ غزلك...',
    _ => 'Cooking your flirts...',
  };

  // ============================================================
  // BUILD
  // ============================================================

  Widget _premiumHeaderIcon(IconData icon, VoidCallback? onPressed) {
    return Center(
      child: Container(
        width: 42,
        height: 42,
        decoration: BoxDecoration(
          color: _dark
              ? Colors.white.withOpacity(0.08)
              : Colors.white.withOpacity(0.96),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: _dark ? Colors.white24 : const Color(0xFFE8DCEB),
          ),
          boxShadow: _dark
              ? null
              : [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.045),
                    blurRadius: 12,
                    offset: const Offset(0, 3),
                  ),
                ],
        ),
        child: IconButton(
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(),
          onPressed: onPressed,
          icon: Icon(
            icon,
            size: 21,
            color: onPressed == null ? _textSecondary : _textPrimary,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder(
      valueListenable: appLangNotifier,
      builder: (_, lang, __) {
        final estilos = _getEstilos(lang.languageCode);

        return Scaffold(
          backgroundColor: _bg,

          appBar: AppBar(
            backgroundColor: _bg,
            elevation: 0,
            centerTitle: true,
            toolbarHeight: 72,
            leadingWidth: 64,
            leading: Padding(
              padding: const EdgeInsets.only(left: 14),
              child: _premiumHeaderIcon(
                Icons.arrow_back_ios_new_rounded,
                () => Navigator.pop(context),
              ),
            ),
            title: const FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                'UpCrush AI',
                style: TextStyle(
                  color: _accent,
                  fontSize: 30,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -1.1,
                ),
              ),
            ),
            actions: [
              if (_respostas.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: _premiumHeaderIcon(
                    Icons.refresh_rounded,
                    _loadingEstilo ? null : _gerarDiferente,
                  ),
                ),
              Padding(
                padding: const EdgeInsets.only(right: 14),
                child: _premiumHeaderIcon(
                  Icons.photo_library_rounded,
                  _analisando
                      ? null
                      : () {
                          setState(() {
                            _imagem = null;
                            _base64Image = null;
                            _respostas = [];
                            _erro = false;
                          });
                          _processarImagem();
                        },
                ),
              ),
            ],
          ),

          body: _erro && _respostas.isEmpty
              ? _buildErro()
              : _buildBody(estilos),
        );
      },
    );
  }

  // ============================================================
  // BODY
  // ============================================================

  Widget _buildBody(List<Map<String, dynamic>> estilos) {
    return BackgroundBlobs(
      isDark: _dark,
      child: Column(
        children: [
          Expanded(
            child: ListView(
              controller: _respostasScrollController,
              padding: EdgeInsets.zero,
              children: [
                if (_imagem != null)
                  _buildImagePreview(
                    height: MediaQuery.sizeOf(context).height * 0.665,
                  ),
                if (_analisando) _buildScanOverlay(),
                if (!_analisando) _buildRespostas(),
              ],
            ),
          ),
          if (_imagem != null && !_analisando) ...[
            _buildEstilosBar(estilos),
            Padding(
              padding: EdgeInsets.fromLTRB(
                16,
                8,
                16,
                MediaQuery.of(context).padding.bottom + 16,
              ),
              child: SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton(
                  onPressed: _loadingEstilo ? null : _gerarDiferente,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _accent,
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: _accent.withOpacity(0.5),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 0,
                  ),
                  child: _loadingEstilo
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : Text(
                          appLang.resultMoreButton,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ============================================================
  // IMAGE PREVIEW — screenshot completo, sem cortar mensagens.
  // A imagem original continua a ser enviada integralmente à IA.
  // ============================================================

  Widget _buildImagePreview({required double height}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          // Proporcoes da moldura de screenshot na referencia Rizz.
          height: height,
          width: double.infinity,

          margin: EdgeInsets.symmetric(
            horizontal: MediaQuery.sizeOf(context).width * 0.15,
          ),

          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),

            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.15),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),

          child: ClipRRect(
            borderRadius: BorderRadius.circular(18),

            child: Stack(
              fit: StackFit.expand,

              children: [
                _buildBottomAnchoredImage(),
                if (_analisando)
                  AnimatedBuilder(
                    animation: _scanAnim,
                    builder: (context, _) => Align(
                      alignment: Alignment(0, -1 + 2 * _scanAnim.value),
                      child: Container(
                        height: 3,
                        decoration: BoxDecoration(
                          color: const Color(0xFF44B5FF),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF1677F2).withOpacity(0.9),
                              blurRadius: 14,
                              spreadRadius: 3,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                if (_analisando || _loadingEstilo)
                  Container(color: Colors.black.withOpacity(0.25)),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // Mostrar o screenshot inteiro, sem zoom/corte das mensagens.
  Widget _buildBottomAnchoredImage() {
    return Container(
      color: _dark ? const Color(0xFF16161D) : Colors.white,
      alignment: Alignment.center,
      child: Image.file(
        _imagem!,
        width: double.infinity,
        height: double.infinity,
        fit: BoxFit.contain,
      ),
    );
  }

  // ============================================================
  // ESTILOS BAR
  // ============================================================

  Widget _buildEstilosBar(List<Map<String, dynamic>> estilos) {
    const rows = [
      ['flertar', 'romantico', 'picante'],
      ['engraçado', 'misterioso', 'toxico'],
    ];
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (var row = 0; row < rows.length; row++) ...[
            if (row > 0) const SizedBox(height: 6),
            Row(
              children: [
                for (var col = 0; col < rows[row].length; col++) ...[
                  if (col > 0) const SizedBox(width: 6),
                  Expanded(
                    child: _buildToneButton(
                      estilos.firstWhere(
                        (tone) => tone['key'] == rows[row][col],
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildToneButton(Map<String, dynamic> tone) {
    final selected = tone['key'] == _estiloAtual;
    final colors = tone['colors'] as List<Color>;
    final enabled = !_analisando && !_loadingEstilo;
    return Semantics(
      selected: selected,
      button: true,
      enabled: enabled,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: enabled ? () => _gerarComEstilo(tone['key'] as String) : null,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            constraints: const BoxConstraints(minHeight: 44),
            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 7),
            decoration: BoxDecoration(
              color: selected ? colors.first.withOpacity(0.16) : _cardBg,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: selected ? colors.first : _cardBorder,
                width: selected ? 1.5 : 1,
              ),
            ),
            child: Row(
              children: [
                if (tone['key'] == 'flertar')
                  const Text('❣️', style: TextStyle(fontSize: 16))
                else if (tone['key'] == 'picante')
                  const Text('😈', style: TextStyle(fontSize: 16))
                else
                  Icon(tone['icon'] as IconData, size: 17, color: colors.first),
                const SizedBox(width: 4),
                Expanded(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Text(
                      tone['label'] as String,
                      maxLines: 1,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: selected
                            ? FontWeight.w700
                            : FontWeight.w500,
                        color: _textPrimary,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ============================================================
  // SCAN / LOADING
  // ============================================================

  List<List<String>> _scanMessages(String lang) {
    const messages = <String, List<List<String>>>{
      'pt': [["Lendo a conversa", "Cada detalhe pode render um bom flerte"], ["A sentir o clima", "O charme começa com o contexto"], ["Cozinhando seus flertes", "Um pouco de ousadia, uma resposta à altura"]],
      'en': [["Reading the conversation", "Every detail can inspire a great flirt"], ["Feeling the vibe", "Charm starts with context"], ["Cooking your flirts", "A little boldness, a reply to match"]],
      'de': [["Wir lesen den Chat", "Jedes Detail kann einen Flirt inspirieren"], ["Wir fühlen den Vibe", "Charme beginnt mit dem richtigen Kontext"], ["Dein Flirt wird zubereitet", "Ein bisschen Mut, eine passende Antwort"]],
      'es': [["Leyendo la conversación", "Cada detalle puede inspirar un buen coqueteo"], ["Sintiendo la química", "El encanto empieza con el contexto"], ["Cocinando tus coqueteos", "Un poco de atrevimiento, una respuesta a la altura"]],
      'fr': [["Lecture de la conversation", "Chaque détail peut inspirer un flirt"], ["On capte l’ambiance", "Le charme commence par le contexte"], ["On prépare tes flirts", "Un peu d’audace, une réponse à la hauteur"]],
      'it': [["Leggiamo la conversazione", "Ogni dettaglio può ispirare un flirt"], ["Sentiamo la sintonia", "Il fascino inizia dal contesto"], ["Prepariamo i tuoi flirt", "Un po’ di audacia, una risposta all’altezza"]],
    };
    return messages[lang] ?? messages['en']!;
  }

  Widget _buildScanOverlay() {
    final messages = _scanMessages(appLang.languageCode);
    return Semantics(
      label: _getFunLoadingMsg(appLang.languageCode),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
        child: AnimatedBuilder(
          animation: _scanController,
          builder: (context, _) {
            final reduceMotion = MediaQuery.disableAnimationsOf(context);
            final phase = _scanController.value * 2 * math.pi;
            final elapsed = _scanController.lastElapsedDuration ?? Duration.zero;
            final index = (elapsed.inMilliseconds ~/ 3000) % messages.length;
            final message = messages[index];
            return Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                AnimatedSwitcher(
                  duration: reduceMotion ? Duration.zero : const Duration(milliseconds: 300),
                  child: Semantics(
                    key: ValueKey(index),
                    liveRegion: true,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(message[0], textAlign: TextAlign.center,
                          style: const TextStyle(color: _accent, fontSize: 22,
                            fontWeight: FontWeight.w700)),
                        const SizedBox(height: 8),
                        Text(message[1], textAlign: TextAlign.center,
                          style: TextStyle(color: _textSecondary, fontSize: 14,
                            height: 1.35)),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(3, (index) {
                    final pulse = reduceMotion
                        ? 1.0
                        : (math.sin(phase - index * 0.8) + 1) / 2;
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: Opacity(
                        opacity: 0.35 + 0.65 * pulse,
                        child: Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            color: Color(0xFF1677F2),
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                    );
                  }),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildRespostas() {
    if (_respostas.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: Column(
        key: _respostasIniciaisKey,
        children: List.generate(_respostas.length, (index) {
          final text = _respostas[index];
          return Align(
            alignment: Alignment.center,
            child: Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxWidth: MediaQuery.sizeOf(context).width * 0.84,
                ),
                child: Material(
                  color: const Color(0xFF1677F2),
                  borderRadius: BorderRadius.circular(24),
                  child: InkWell(
                    onTap: () => _copiar(text, index),
                    borderRadius: BorderRadius.circular(24),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 14,
                      ),
                      child: Text(
                        text,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w400,
                          height: 1.35,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  // ============================================================
  // ERRO
  // ============================================================

  Widget _buildErro() {
    final textColor = _dark ? Colors.white70 : Colors.black54;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),

        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,

          children: [
            const Text('😕', style: TextStyle(fontSize: 52)),

            const SizedBox(height: 20),

            Text(
              _erroMsg,

              textAlign: TextAlign.center,

              style: TextStyle(color: textColor, fontSize: 15, height: 1.5),
            ),

            const SizedBox(height: 32),

            ElevatedButton(
              onPressed: () {
                setState(() {
                  _erro = false;
                  _respostas = [];
                });

                _gerarDiferente();
              },

              style: ElevatedButton.styleFrom(
                backgroundColor: _accent,

                foregroundColor: Colors.white,

                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),

              child: Text(appLang.errorRetry),
            ),

            const SizedBox(height: 12),

            TextButton(
              onPressed: () => Navigator.pop(context),

              child: Text(
                appLang.errorBack,

                style: TextStyle(color: textColor.withOpacity(0.5)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
