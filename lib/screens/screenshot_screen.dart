import 'locked_reply_preview_screen.dart';
import '../services/response_paywall_gate.dart';
import '../theme/tone_options.dart';
import 'dart:io';
import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';

import '../services/ai_service.dart';
import '../widgets/background_blobs.dart';
import '../widgets/processing_screenshot_preview.dart';
import '../main.dart';
import '../services/review_request_service.dart';
import '../services/chat_history_service.dart';

class ScreenshotScreen extends StatefulWidget {
  final SavedChat? savedChat;
  const ScreenshotScreen({super.key, this.savedChat});

  @override
  State<ScreenshotScreen> createState() => _ScreenshotScreenState();
}

class _ScreenshotScreenState extends State<ScreenshotScreen>
    with TickerProviderStateMixin {
  File? _imagem;
  double _previewAlignmentY = 0.18;
  String? _base64Image;

  bool _analisando = false;
  bool _erro = false;
  String _erroMsg = '';

  List<String> _respostas = [];
  final TextEditingController _replyController = TextEditingController();
  final FocusNode _replyFocus = FocusNode();
  String _savedChatId = DateTime.now().microsecondsSinceEpoch.toString();

  Future<void> _saveGeneratedChat() async {
    if (_respostas.isEmpty) return;
    final imagePath = await ChatHistoryService.persistImage(_imagem, _savedChatId) ?? widget.savedChat?.imagePath;
    await ChatHistoryService.save(SavedChat(
      id: _savedChatId,
      kind: 'reply',
      title: ChatHistoryService.automaticTitle(_respostas.last, 'Responder conversa'),
      imagePath: imagePath,
      prompt: '',
      lastMessage: '',
      style: _estiloAtual,
      replies: List<String>.from(_respostas),
      updatedAt: DateTime.now(),
    ));
  }


  // Novas respostas entram acima; o histórico continua acessível ao rolar.
  void _adicionarResposta(String resposta) {
    _replyFocus.unfocus();
    _respostas.insert(0, resposta);
    _replyController.text = resposta;
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

    if (widget.savedChat != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _restoreSavedChat());
    } else {
      WidgetsBinding.instance.addPostFrameCallback((_) => _processarImagem());
    }
  }

  Future<void> _restoreSavedChat() async {
    final chat = widget.savedChat;
    if (chat == null || !mounted) return;
    final path = chat.imagePath;
    final image = path == null ? null : File(path);
    String? base64;
    if (image != null && await image.exists()) {
      base64 = base64Encode(await image.readAsBytes());
    }
    if (!mounted) return;
    setState(() {
      _savedChatId = chat.id;
      _imagem = base64 == null ? null : image;
      _base64Image = base64;
      _respostas = List<String>.from(chat.replies);
      _replyController.text = _respostas.isEmpty ? '' : _respostas.first;
      _estiloAtual = chat.style;
      _analisando = false;
      _erro = false;
    });
  }

  @override
  void dispose() {
    isDarkModeNotifier.removeListener(_onThemeChange);

    _respostasScrollController.dispose();
    _replyController.dispose();
    _replyFocus.dispose();
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

  Future<String?> _pedirUma(String imagem, String estilo, String idioma, {String orientacao = ''}) async {
    final lista = await AIService.gerarRespostaDeImagem(
      imagem,
      estilo,
      idioma,
      quantidade: 1,
      modoRapido: true,
      orientacao: orientacao,
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
        _savedChatId = DateTime.now().microsecondsSinceEpoch.toString();
        _imagem = File(img.path);
        _previewAlignmentY = 0.18;
        _base64Image = base64;
        _analisando = true;
        _erro = false;
        _respostas = [];
        _replyController.clear();
      });
      final resposta = await _pedirUma(
        base64,
        _estiloAtual,
        appLang.languageCode,
      );
      if (!mounted || versao != _versao) return;
      var respostaFinal = resposta;
      if (resposta != null && !await ResponsePaywallGate.allow(context, returnOnDismiss: false)) {
        if (!mounted) return;
        final direction = await Navigator.of(context).push<String>(
          MaterialPageRoute(builder: (_) => LockedReplyPreviewScreen(image: _imagem)));
        if (!mounted || versao != _versao) return;
        if (direction == null) { Navigator.of(context).maybePop(); return; }
        if (direction.isNotEmpty) {
          respostaFinal = await _pedirUma(base64, _estiloAtual, appLang.languageCode,
            orientacao: direction);
        }
      }
      if (!mounted || versao != _versao) return;
      setState(() {
        _respostas = respostaFinal == null ? [] : [respostaFinal];
        _replyController.text = respostaFinal ?? '';
        _analisando = false;
      });
      _revelarRespostasIniciais();
      _saveGeneratedChat();
      ReviewRequestService.onMessageDisplayed();
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
      if (!await ResponsePaywallGate.allow(context)) return;
      if (!mounted || versao != _versao) return;
      setState(() {
        _adicionarResposta(resposta!);
        _stock = null;
      });
      _revelarRespostasIniciais();
      _saveGeneratedChat();
      ReviewRequestService.onMessageDisplayed();
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
      if (!await ResponsePaywallGate.allow(context)) {
        if (mounted) setState(() => _loadingEstilo = false);
        return;
      }
      if (!mounted || versao != _versao) return;
      setState(() {
        _adicionarResposta(resposta!);
        _stock = null;
        _loadingEstilo = false;
      });
      _revelarRespostasIniciais();
      _saveGeneratedChat();
      ReviewRequestService.onMessageDisplayed();
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
            toolbarHeight: 150,
            leadingWidth: 64,
            leading: Padding(
              padding: const EdgeInsets.only(left: 14, top: 76),
              child: _premiumHeaderIcon(
                Icons.arrow_back_ios_new_rounded,
                () => Navigator.pop(context),
              ),
            ),
            title: const Padding(
              padding: EdgeInsets.only(top: 84),
              child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                'UpCrush AI',
                style: TextStyle(
                  color: _accent,
                  fontSize: 35,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -1.1,
                ),
              ),
              ),
            ),
            actions: [
              Padding(
                padding: const EdgeInsets.only(right: 14, top: 76),
                child: _premiumHeaderIcon(
                  Icons.photo_library_rounded,
                  _analisando
                      ? null
                      : () {
                          setState(() {
                            _imagem = null;
                            _base64Image = null;
                            _respostas = [];
                            _replyController.clear();
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
                if (_imagem != null) const SizedBox(height: 24),
                if (_imagem != null && _analisando)
                  ProcessingScreenshotPreview(
                    image: _imagem!,
                    scanAnimation: _scanAnim,
                    dark: _dark,
                  ),
                if (_imagem != null && !_analisando)
                  _buildImagePreview(
                    height: math.min(220.0, MediaQuery.sizeOf(context).height * 0.29),
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
  // IMAGE PREVIEW — janela compacta focada na parte inferior da conversa.
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
            horizontal: 16,
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
                GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onVerticalDragUpdate: (details) {
                    setState(() {
                      _previewAlignmentY = (_previewAlignmentY -
                          details.delta.dy / 115).clamp(-1.0, 1.0);
                    });
                  },
                  child: _buildBottomAnchoredImage(),
                ),
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

  // Recorte visual inferior, sem deformar o screenshot original.
  Widget _buildBottomAnchoredImage() {
    return Container(
      color: _dark ? const Color(0xFF16161D) : Colors.white,
      alignment: Alignment.center,
      child: Image.file(
        _imagem!,
        width: double.infinity,
        height: double.infinity,
        fit: BoxFit.cover,
        // Desloca o recorte para cima, evitando enquadrar o teclado
        // e privilegiando as ultimas mensagens acima da caixa de escrita.
        alignment: Alignment(0, _previewAlignmentY),
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

  // Uma unica area de resposta, editavel, sem baloes de chat.
  // As respostas anteriores permanecem apenas no historico interno
  // para evitar repeticoes e preservar a compatibilidade com os chats salvos.
  Widget _buildRespostas() {
    if (_respostas.isEmpty) return const SizedBox.shrink();
    const copyHints = <String, String>{
      'pt': 'Toque para copiar',
      'en': 'Tap to copy',
      'de': 'Zum Kopieren tippen',
      'es': 'Toca para copiar',
      'fr': 'Appuyez pour copier',
      'it': 'Tocca per copiare',
      'tr': 'Kopyalamak için dokun',
      'pl': 'Dotknij, aby skopiować',
      'ru': 'Нажмите, чтобы скопировать',
      'ar': 'اضغط للنسخ',
    };
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(child: TextButton(
            onPressed: () async {
              _respostas[0] = _replyController.text;
              await _copiar(_replyController.text, 0);
              await _saveGeneratedChat();
            },
            child: Text(copyHints[appLang.languageCode] ?? copyHints['en']!,
              style: TextStyle(color: _dark ? Colors.white60 : Colors.black45, fontSize: 13)),
          )),
          Align(
            alignment: Alignment.center,
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: MediaQuery.sizeOf(context).width * 0.78),
              child: Container(
        key: _respostasIniciaisKey,
        padding: const EdgeInsets.fromLTRB(16, 10, 10, 4),
        decoration: BoxDecoration(
          color: const Color(0xFF1688F7),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFF1688F7)),
          boxShadow: [BoxShadow(
            color: Colors.black.withOpacity(_dark ? 0.08 : 0.05),
            blurRadius: 16,
            offset: const Offset(0, 5),
          )],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            TextField(
              controller: _replyController,
              focusNode: _replyFocus,
              maxLines: null,
              minLines: 1,
              keyboardType: TextInputType.multiline,
              textCapitalization: TextCapitalization.sentences,
              style: TextStyle(color: Colors.white, fontSize: 16, height: 1.4),
              decoration: const InputDecoration(
                border: InputBorder.none,
                isDense: true,
                contentPadding: EdgeInsets.symmetric(vertical: 2),
              ),
              onChanged: (value) {
                if (_respostas.isNotEmpty) _respostas[0] = value;
              },
              onEditingComplete: () { _saveGeneratedChat(); },
              onTapOutside: (_) {
                _replyFocus.unfocus();
                _saveGeneratedChat();
              },
            ),
            SizedBox(
              height: 34,
              child: IconButton(
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 34, minHeight: 34),
              tooltip: appLang.languageCode == 'pt' ? 'Copiar resposta' : 'Copy reply',
              onPressed: () async {
                if (_respostas.isNotEmpty) {
                  _respostas[0] = _replyController.text;
                  await _copiar(_replyController.text, 0);
                  await _saveGeneratedChat();
                }
              },
              icon: const Icon(Icons.copy_rounded, color: Colors.white, size: 21),
              ),
            ),
          ],
        ),
            ),
          ),
          ),
        ],
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
                  _replyController.clear();
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
