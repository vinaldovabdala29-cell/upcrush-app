import 'locked_reply_preview_screen.dart';
import '../services/response_paywall_gate.dart';
import '../theme/tone_options.dart';
import 'dart:io';
import 'dart:convert';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import '../services/romantic_image_opener_service.dart';
import '../widgets/background_blobs.dart';
import '../main.dart';
import '../services/review_request_service.dart';

class OpenerScreen extends StatefulWidget {
  const OpenerScreen({super.key});
  @override
  State<OpenerScreen> createState() => _OpenerScreenState();
}

class _OpenerScreenState extends State<OpenerScreen>
    with TickerProviderStateMixin {
  File? _imagem;
  String? _base64Image;
  bool _analisando = false;
  bool _erro = false;
  String _erroMsg = '';
  List<String> _respostas = [];

  // Cada nova mensagem aparece acima, preservando as anteriores.
  void _adicionarResposta(String resposta) {
    _respostas.insert(0, resposta);
  }

  Duration _scanStartedAt = Duration.zero;

  final List<String> _historicoRespostas = [];
  final ScrollController _respostasScrollController = ScrollController();
  String _estiloAtual = 'flertar';
  bool _loadingEstilo = false;
  String? _stock;
  Future<void>? _stockEmCurso;
  int _versao = 0;
  bool _consumindo = false;
  String _idiomaStock = '';

  late AnimationController _scanController;
  late Animation<double> _scanAnim;

  static const _accent = Color(0xFFFF2D55);

  bool get _dark => isDarkModeNotifier.value;
  Color get _bg => _dark ? const Color(0xFF0A0A10) : const Color(0xFFF2F2F7);
  Color get _cardBg =>
      _dark ? Colors.white.withOpacity(0.06) : Colors.white.withOpacity(0.85);
  Color get _cardBorder =>
      _dark ? Colors.white.withOpacity(0.08) : Colors.white.withOpacity(0.9);
  Color get _textPrimary => _dark ? Colors.white : const Color(0xFF1C1C1E);
  Color get _textSecondary => _dark ? Colors.white38 : Colors.black38;

  List<Map<String, dynamic>> _getEstilos(String lang) => toneOptions(lang);

  @override
  void initState() {
    super.initState();
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
    _scanController.dispose();
    _respostasScrollController.dispose();
    super.dispose();
  }

  void _onThemeChange() {
    if (mounted) setState(() {});
  }

  String _erroMsgLocal(String lang) {
    switch (lang) {
      case 'de':
        return 'Verbindungsfehler.\nPrüfe deine Verbindung und versuche es erneut.';
      case 'es':
        return 'Error de conexión.\nVerifica tu conexión e inténtalo de nuevo.';
      case 'pt':
        return 'Algo deu errado.\nVerifica a conexão e tenta novamente.';
      default:
        return 'Something went wrong.\nCheck your connection and try again.';
    }
  }

  void _guardarNoHistorico(Iterable<String> respostas) {
    for (final resposta in respostas) {
      final limpa = resposta.trim();
      if (limpa.isNotEmpty && !_historicoRespostas.contains(limpa)) {
        _historicoRespostas.add(limpa);
      }
    }
    // Mantém contexto suficiente para variar sem deixar o prompt crescer demais.
    if (_historicoRespostas.length > 12) {
      _historicoRespostas.removeRange(0, _historicoRespostas.length - 12);
    }
  }

  void _invalidarStock() {
    _versao++;
    _stock = null;
    _stockEmCurso = null;
  }

  Future<List<String>> _pedirUma(
    String imagem,
    String estilo,
    String idioma, {
    String orientacao = '',
  }) async {
    final evitar = <String>[..._historicoRespostas, ..._respostas];
    return RomanticImageOpenerService.gerarOpenerDeImagem(
      imagem,
      estilo,
      idioma,
      evitar.toSet().toList(),
      orientacao,
    );
  }

  void _prepararStock() {
    if (_base64Image == null || _stock != null || _stockEmCurso != null) return;
    final versao = _versao;
    final imagem = _base64Image!;
    final estilo = _estiloAtual;
    final idioma = appLang.languageCode;
    _idiomaStock = idioma;
    final tarefa = _pedirUma(imagem, estilo, idioma)
        .then((lista) {
          if (!mounted || versao != _versao || idioma != appLang.languageCode)
            return;
          final nova = lista
              .where(
                (e) =>
                    e.trim().isNotEmpty &&
                    !_respostas.contains(e.trim()) &&
                    !_historicoRespostas.contains(e.trim()),
              )
              .toList();
          if (nova.isNotEmpty) _stock = nova.first.trim();
        })
        .catchError((Object _) {
          // Falha silenciosa do prefetch: a geração normal continua disponível.
        })
        .whenComplete(() {
          if (versao == _versao) _stockEmCurso = null;
        });
    _stockEmCurso = tarefa;
  }

  Future<void> _processarImagem() async {
    final picker = ImagePicker();
    try {
      final img = await picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 25,
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
        _scanStartedAt = _scanController.lastElapsedDuration ?? Duration.zero;
        _analisando = true;
        _erro = false;
        _respostas = [];
        _historicoRespostas.clear();
      });
      final respostas = await _pedirUma(
        base64,
        _estiloAtual,
        appLang.languageCode,
      );
      if (!mounted || versao != _versao) return;
      var respostasFinais = respostas;
      if (respostas.isNotEmpty && !await ResponsePaywallGate.allow(context, returnOnDismiss: false)) {
        if (!mounted) return;
        final direction = await Navigator.of(context).push<String>(
          MaterialPageRoute(builder: (_) => LockedReplyPreviewScreen(image: _imagem)));
        if (!mounted || versao != _versao) return;
        if (direction == null) { Navigator.of(context).maybePop(); return; }
        if (direction.isNotEmpty) {
          respostasFinais = await _pedirUma(base64, _estiloAtual, appLang.languageCode,
            orientacao: direction);
        }
      }
      if (!mounted || versao != _versao) return;
      setState(() {
        _respostas = respostasFinais.take(1).toList();
        _analisando = false;
      });
      ReviewRequestService.onMessageDisplayed();
      _prepararStock();
    } catch (_) {
      if (mounted)
        setState(() {
          _analisando = false;
          _erro = true;
          _erroMsg = _erroMsgLocal(appLang.languageCode);
        });
    }
  }

  Future<void> _gerarComEstilo(String estilo) async {
    if (_base64Image == null || _analisando || _consumindo) return;
    if (estilo != _estiloAtual) {
      _invalidarStock();
      setState(() => _estiloAtual = estilo);
    }
    await _gerarDiferente();
  }

  Future<void> _gerarDiferente() async {
    if (_base64Image == null || _analisando || _consumindo) return;
    _consumindo = true;
    try {
      if (_idiomaStock != appLang.languageCode) _invalidarStock();
      final atual = _versao;
      var proxima = _stock;
      if (proxima == null && _stockEmCurso != null) {
        setState(() => _loadingEstilo = true);
        await _stockEmCurso;
        proxima = _stock;
      }
      if (proxima == null) {
        if (mounted) setState(() => _loadingEstilo = true);
        final lista = await _pedirUma(
          _base64Image!,
          _estiloAtual,
          appLang.languageCode,
        );
        proxima = lista.isNotEmpty ? lista.first.trim() : null;
      }
      if (!mounted || atual != _versao) return;
      if (proxima == null || proxima.isEmpty) throw Exception('Resposta vazia');
      if (!await ResponsePaywallGate.allow(context)) {
        if (mounted) setState(() => _loadingEstilo = false);
        return;
      }
      if (!mounted || atual != _versao) return;
      _guardarNoHistorico(_respostas);
      setState(() {
        _adicionarResposta(proxima!);
        _stock = null;
        _loadingEstilo = false;
        _erro = false;
      });
      ReviewRequestService.onMessageDisplayed();
      _prepararStock();
    } catch (_) {
      if (mounted)
        setState(() {
          _loadingEstilo = false;
          _erro = true;
          _erroMsg = _erroMsgLocal(appLang.languageCode);
        });
    } finally {
      _consumindo = false;
    }
  }

  Future<void> _copiar(String texto, int index) async {
    await Clipboard.setData(ClipboardData(text: texto));
    HapticFeedback.lightImpact();
  }

  List<List<String>> _scanMessages(String lang) {
    const messages = <String, List<List<String>>>{
      'pt': [["Lendo a vibe", "Detalhes que fazem a diferença"], ["A sentir o clima", "Um pouco de charme, uma resposta à altura"], ["Cozinhando os teus flertes", "Quase lá"]],
      'en': [["Discovering the details", "A good conversation starts with something that stands out"], ["Preparing a first impression", "A touch of charm beyond a simple hello"], ["Crafting your opener", "The first move deserves a great line"]],
      'de': [["Wir entdecken die Details", "Ein gutes Gespräch beginnt mit etwas Besonderem"], ["Der erste Eindruck zählt", "Ein Hauch Charme statt einem einfachen Hallo"], ["Dein Einstieg entsteht", "Der erste Schritt verdient einen guten Spruch"]],
      'es': [["Descubriendo los detalles", "Una buena conversación empieza con algo que llama la atención"], ["Preparando la primera impresión", "Un toque de encanto más allá de un simple hola"], ["Cocinando tu primera frase", "El primer paso merece una buena frase"]],
      'fr': [["À la découverte des détails", "Une belle conversation commence par un détail qui attire"], ["Préparons la première impression", "Un peu de charme pour dépasser le simple salut"], ["On prépare ton approche", "Le premier pas mérite une belle phrase"]],
      'it': [["Scopriamo i dettagli", "Una bella conversazione inizia con qualcosa che colpisce"], ["Prepariamo la prima impressione", "Un tocco di fascino oltre un semplice ciao"], ["Prepariamo il tuo approccio", "Il primo passo merita una bella frase"]],
      'tr': [["Detayları keşfediyoruz", "Güzel bir sohbet dikkat çeken bir şeyle başlar"], ["İlk izlenimi hazırlıyoruz", "Basit bir merhabanın ötesine geç"], ["İlk mesajın hazırlanıyor", "İlk adım güzel bir cümleyi hak eder"]],
      'pl': [["Odkrywamy szczegóły", "Dobra rozmowa zaczyna się od czegoś ciekawego"], ["Tworzymy pierwsze wrażenie", "Odrobina uroku zamiast zwykłego cześć"], ["Przygotowujemy pierwszą wiadomość", "Pierwszy krok zasługuje na dobre zdanie"]],
      'ru': [["Замечаем детали", "Хороший разговор начинается с чего-то интересного"], ["Готовим первое впечатление", "Немного обаяния вместо обычного привет"], ["Готовим первое сообщение", "Первый шаг заслуживает хорошей фразы"]],
      'ar': [["نكتشف التفاصيل", "تبدأ المحادثة الجميلة بشيء يلفت الانتباه"], ["نجهز الانطباع الأول", "لمسة من الجاذبية تتجاوز التحية المعتادة"], ["نصوغ رسالتك الأولى", "الخطوة الأولى تستحق عبارة مميزة"]],
    };
    return messages[lang] ?? messages['en']!;
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
            leading: IconButton(
              icon: Icon(
                Icons.arrow_back_ios_rounded,
                color: _textPrimary,
                size: 20,
              ),
              onPressed: () => Navigator.pop(context),
            ),
            title: Text(
              lang.openerTitle,
              style: TextStyle(
                color: _textPrimary,
                fontSize: 17,
                fontWeight: FontWeight.w700,
              ),
            ),
            actions: [
              if (_respostas.isNotEmpty)
                IconButton(
                  icon: Icon(
                    Icons.refresh_rounded,
                    color: _textSecondary,
                    size: 22,
                  ),
                  onPressed: _consumindo ? null : _gerarDiferente,
                ),
              IconButton(
                icon: Icon(
                  Icons.photo_library_outlined,
                  color: _textSecondary,
                  size: 22,
                ),
                onPressed: _analisando
                    ? null
                    : () {
                        _invalidarStock();
                        setState(() {
                          _imagem = null;
                          _base64Image = null;
                          _respostas = [];
                          _historicoRespostas.clear();
                          _erro = false;
                        });
                        _processarImagem();
                      },
              ),
            ],
          ),
          body: _erro ? _buildErro(lang) : _buildBody(estilos),
        );
      },
    );
  }

  Widget _buildBody(List<Map<String, dynamic>> estilos) {
    return BackgroundBlobs(
      isDark: _dark,
      child: LayoutBuilder(
        builder: (context, constraints) {
          if (_imagem == null) {
            return (_analisando || _loadingEstilo)
                ? _buildScanOverlay()
                : _buildRespostas();
          }

          // Keep exactly the same photo size both while scanning and after the
          // result is ready. Only the result panel is hidden during analysis.
          final photoHeight = constraints.maxHeight * 0.70;
          final isLoading = _analisando;

          return Stack(
            children: [
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: _buildImagePreview(height: photoHeight),
              ),

              // During analysis: no message/style panel. Keep the photo at the
              // same size and show only the scanner in the free area below it.
              if (isLoading)
                Positioned(
                  top: photoHeight,
                  left: 0,
                  right: 0,
                  bottom: 0,
                  child: _buildScanOverlay(),
                ),

              // After analysis finishes, reveal the Social-Wizard-inspired
              // UpCrush panel overlapping the lower part of the photo.
              if (!isLoading)
                Positioned(
                  top: photoHeight * 0.72,
                  left: 0,
                  right: 0,
                  bottom: 0,
                  child: Container(
                    decoration: BoxDecoration(
                      color: _dark
                          ? const Color(0xFF111116).withOpacity(0.98)
                          : const Color(0xFFF7F7FA).withOpacity(0.98),
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(28),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(_dark ? 0.35 : 0.14),
                          blurRadius: 24,
                          offset: const Offset(0, -8),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        const SizedBox(height: 10),
                        Container(
                          width: 44,
                          height: 5,
                          decoration: BoxDecoration(
                            color: _textSecondary.withOpacity(0.45),
                            borderRadius: BorderRadius.circular(99),
                          ),
                        ),
                        _buildEstilosBar(estilos),
                        Expanded(child: _buildRespostas()),
                        if (_respostas.isNotEmpty)
                          Padding(
                            padding: EdgeInsets.fromLTRB(
                              16,
                              8,
                              16,
                              MediaQuery.of(context).padding.bottom + 12,
                            ),
                            child: SizedBox(
                              width: double.infinity,
                              height: 54,
                              child: ElevatedButton(
                                onPressed: _gerarDiferente,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: _accent,
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  elevation: 0,
                                ),
                                child: Text(
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
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildImagePreview({required double height}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.fromLTRB(16, 8, 16, 6),
          child: Text(
            'UpCrush AI',
            style: TextStyle(
              color: Color(0xFFFF2D55),
              fontSize: 26,
              fontWeight: FontWeight.w900,
              letterSpacing: -0.5,
            ),
          ),
        ),
        Container(
          height: height - 48,
          width: double.infinity,
          margin: const EdgeInsets.symmetric(horizontal: 10),
          decoration: BoxDecoration(
            color: _dark ? const Color(0xFF111116) : const Color(0xFFE9E9EE),
            borderRadius: BorderRadius.circular(22),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.15),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(22),
            child: Stack(
              fit: StackFit.expand,
              children: [
                // Never crop the selected photo.
                Image.file(_imagem!, fit: BoxFit.contain),
                if (_analisando)
                  Container(color: Colors.black.withOpacity(0.18)),
                if (_analisando)
                  AnimatedBuilder(
                    animation: _scanAnim,
                    builder: (context, _) => Align(
                      alignment: Alignment(0, -1 + 2 * _scanAnim.value),
                      child: Container(
                        height: 5,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [
                              Color(0xFF1677F2),
                              Color(0xFF8DDEFF),
                              Color(0xFF1677F2),
                            ],
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF44B5FF).withOpacity(0.95),
                              blurRadius: 24,
                              spreadRadius: 6,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                Positioned(
                  top: 10,
                  left: 10,
                  child: _corner(top: true, left: true),
                ),
                Positioned(
                  top: 10,
                  right: 10,
                  child: _corner(top: true, left: false),
                ),
                Positioned(
                  bottom: 10,
                  left: 10,
                  child: _corner(top: false, left: true),
                ),
                Positioned(
                  bottom: 10,
                  right: 10,
                  child: _corner(top: false, left: false),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

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

  Widget _buildScanOverlay() {
    final messages = _scanMessages(appLang.languageCode);
    return Semantics(
      label: messages.first.first,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
        child: AnimatedBuilder(
          animation: _scanController,
          builder: (context, _) {
            final reduceMotion = MediaQuery.disableAnimationsOf(context);
            final phase = _scanController.value * 2 * math.pi;
            final elapsed = (_scanController.lastElapsedDuration ?? Duration.zero) - _scanStartedAt;
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
    return SingleChildScrollView(
      controller: _respostasScrollController,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
        child: Column(
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
      ),
    );
  }

  Widget _corner({required bool top, required bool left}) => SizedBox(
    width: 14,
    height: 14,
    child: CustomPaint(
      painter: _CornerPainter(top: top, left: left),
    ),
  );

  Widget _buildErro(lang) {
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
                setState(() => _erro = false);
                _gerarDiferente();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: _accent,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: Text(lang.errorRetry),
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                lang.errorBack,
                style: TextStyle(color: textColor.withOpacity(0.5)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CornerPainter extends CustomPainter {
  final bool top, left;
  _CornerPainter({required this.top, required this.left});
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFFFF2D55)
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    final path = Path();
    if (top && left) {
      path.moveTo(0, size.height);
      path.lineTo(0, 0);
      path.lineTo(size.width, 0);
    } else if (top && !left) {
      path.moveTo(0, 0);
      path.lineTo(size.width, 0);
      path.lineTo(size.width, size.height);
    } else if (!top && left) {
      path.moveTo(0, 0);
      path.lineTo(0, size.height);
      path.lineTo(size.width, size.height);
    } else {
      path.moveTo(0, size.height);
      path.lineTo(size.width, size.height);
      path.lineTo(size.width, 0);
    }
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
