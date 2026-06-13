import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import '../services/ai_service.dart';
import '../services/revenue_cat_service.dart';
import '../widgets/paywall_screen.dart';
import '../widgets/background_blobs.dart';
import '../../../main.dart';

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
  String _estiloAtual = 'picante';
  int? _copiedIndex;
  bool _loadingEstilo = false;

  late AnimationController _scanController;
  late Animation<double> _scanAnim;
  late AnimationController _pulseController;
  late Animation<double> _pulseAnim;

  static const _accent = Color(0xFFFF2D55);
  static const _success = Color(0xFF34C759);

  bool get _dark => isDarkModeNotifier.value;
  Color get _bg => _dark ? const Color(0xFF0A0A10) : const Color(0xFFF2F2F7);
  Color get _cardBg => _dark ? Colors.white.withOpacity(0.06) : Colors.white.withOpacity(0.85);
  Color get _cardBorder => _dark ? Colors.white.withOpacity(0.08) : Colors.white.withOpacity(0.9);
  Color get _textPrimary => _dark ? Colors.white : const Color(0xFF1C1C1E);
  Color get _textSecondary => _dark ? Colors.white38 : Colors.black38;

  List<Map<String, dynamic>> _getEstilos(String lang) => [
    {'key': 'engraçado', 'label': lang=='de'?'Lustig':lang=='es'?'Gracioso':lang=='fr'?'Drôle':lang=='pt'?'Engraçado':lang=='it'?'Divertente':lang=='tr'?'Komik':lang=='ru'?'Смешной':'Funny', 'icon': Icons.sentiment_very_satisfied_rounded, 'colors': [const Color(0xFFFF9500), const Color(0xFFFFCC02)], 'shadow': const Color(0xFFFF9500)},
    {'key': 'picante',   'label': lang=='de'?'Pikant':lang=='es'?'Picante':lang=='fr'?'Piquant':lang=='pt'?'Picante':lang=='it'?'Piccante':lang=='tr'?'Ateşli':lang=='ru'?'Пикантный':'Spicy', 'icon': Icons.local_fire_department_rounded, 'colors': [const Color(0xFFFF2D55), const Color(0xFFFF6B81)], 'shadow': const Color(0xFFFF2D55)},
    {'key': 'misterioso','label': lang=='de'?'Mysteriös':lang=='es'?'Misterioso':lang=='fr'?'Mystérieux':lang=='pt'?'Misterioso':lang=='it'?'Misterioso':lang=='tr'?'Gizemli':lang=='ru'?'Загадочный':'Mysterious', 'icon': Icons.nightlight_round, 'colors': [const Color(0xFF5856D6), const Color(0xFFAF52DE)], 'shadow': const Color(0xFF5856D6)},
    {'key': 'direto',    'label': lang=='de'?'Direkt':lang=='es'?'Directo':lang=='fr'?'Direct':lang=='pt'?'Direto':lang=='it'?'Diretto':lang=='tr'?'Doğrudan':lang=='ru'?'Прямой':'Direct', 'icon': Icons.bolt_rounded, 'colors': [const Color(0xFF007AFF), const Color(0xFF5AC8FA)], 'shadow': const Color(0xFF007AFF)},
  ];

  @override
  void initState() {
    super.initState();
    isDarkModeNotifier.addListener(_onThemeChange);
    _scanController = AnimationController(vsync: this, duration: const Duration(milliseconds: 1800))..repeat();
    _scanAnim = Tween<double>(begin: 0.0, end: 1.0).animate(CurvedAnimation(parent: _scanController, curve: Curves.easeInOut));
    _pulseController = AnimationController(vsync: this, duration: const Duration(milliseconds: 800))..repeat(reverse: true);
    _pulseAnim = Tween<double>(begin: 0.4, end: 1.0).animate(CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut));
    WidgetsBinding.instance.addPostFrameCallback((_) => _processarImagem());
  }

  @override
  void dispose() {
    isDarkModeNotifier.removeListener(_onThemeChange);
    _scanController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  void _onThemeChange() { if (mounted) setState(() {}); }

  Future<void> _processarImagem() async {
    final premium = await RevenueCatService.isPremium();
    if (!mounted) return;
    if (!premium) {
      final result = await Navigator.push(context, MaterialPageRoute(
        fullscreenDialog: true, builder: (_) => const PaywallFlow()));
      if (result != true) { if (mounted) Navigator.pop(context); return; }
    }
    final picker = ImagePicker();
    try {
      final img = await picker.pickImage(source: ImageSource.gallery, imageQuality: 25);
      if (img == null) { if (mounted) Navigator.pop(context); return; }
      final bytes = await File(img.path).readAsBytes();
      final base64 = base64Encode(bytes);
      setState(() { _imagem = File(img.path); _base64Image = base64; _analisando = true; _erro = false; _respostas = []; });
      final respostas = await AIService.gerarOpenerDeImagem(base64, _estiloAtual, appLang.languageCode);
      if (!mounted) return;
      setState(() { _respostas = respostas; _analisando = false; });
    } catch (e) {
      if (mounted) setState(() { _analisando = false; _erro = true; _erroMsg = appLang.errorGeneral; });
    }
  }

  Future<void> _gerarComEstilo(String estilo) async {
    if (_base64Image == null) return;
    setState(() { _estiloAtual = estilo; _loadingEstilo = true; });
    try {
      final respostas = await AIService.gerarOpenerDeImagem(_base64Image!, estilo, appLang.languageCode);
      if (mounted) setState(() { _respostas = respostas; _loadingEstilo = false; });
    } catch (e) { if (mounted) setState(() => _loadingEstilo = false); }
  }

  Future<void> _gerarDiferente() async {
    if (_base64Image == null) return;
    setState(() => _loadingEstilo = true);
    try {
      final respostas = await AIService.gerarOpenerDeImagem(_base64Image!, _estiloAtual, appLang.languageCode);
      if (mounted) setState(() { _respostas = respostas; _loadingEstilo = false; });
    } catch (e) { if (mounted) setState(() => _loadingEstilo = false); }
  }

  Future<void> _copiar(String texto, int index) async {
    await Clipboard.setData(ClipboardData(text: texto));
    HapticFeedback.lightImpact();
    setState(() => _copiedIndex = index);
    await Future.delayed(const Duration(seconds: 2));
    if (mounted) setState(() => _copiedIndex = null);
  }

  String _getFunLoadingMsg(String lang) {
    switch (lang) {
      case 'de': return 'Koche deine Flirts... 🌶️';
      case 'es': return 'Cocinando tus flirts... 🌶️';
      case 'fr': return 'On cuisine tes flirts... 🌶️';
      case 'it': return 'Cucinando i tuoi flirt... 🌶️';
      case 'tr': return 'Flörtlerin pişiyor... 🌶️';
      case 'pl': return 'Gotuję twoje flirty... 🌶️';
      case 'ru': return 'Готовлю твой флирт... 🌶️';
      case 'ar': return '...يُطبخ غزلك 🌶️';
      case 'pt': return 'Cozinhando seus flertins... 🌶️';
      default:   return 'Cooking your flirts... 🌶️';
    }
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
            backgroundColor: _bg, elevation: 0,
            leading: IconButton(
              icon: Icon(Icons.arrow_back_ios_rounded, color: _textPrimary, size: 20),
              onPressed: () => Navigator.pop(context)),
            title: Text(lang.openerTitle,
              style: TextStyle(color: _textPrimary, fontSize: 17, fontWeight: FontWeight.w700)),
            actions: [
              if (_respostas.isNotEmpty)
                IconButton(
                  icon: Icon(Icons.refresh_rounded, color: _textSecondary, size: 22),
                  onPressed: _loadingEstilo ? null : _gerarDiferente),
              IconButton(
                icon: Icon(Icons.photo_library_outlined, color: _textSecondary, size: 22),
                onPressed: _analisando ? null : () {
                  setState(() { _imagem = null; _base64Image = null; _respostas = []; _erro = false; });
                  _processarImagem();
                }),
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
      child: Column(children: [
        if (_imagem != null) _buildImagePreview(),
        if (_imagem != null && !_analisando) _buildEstilosBar(estilos),
        Expanded(child: _analisando ? _buildScanOverlay() : _buildRespostas()),
        if (_respostas.isNotEmpty)
          Padding(
            padding: EdgeInsets.fromLTRB(16, 8, 16, MediaQuery.of(context).padding.bottom + 16),
            child: SizedBox(width: double.infinity, height: 54,
              child: ElevatedButton(
                onPressed: _loadingEstilo ? null : _gerarDiferente,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _accent, foregroundColor: Colors.white,
                  disabledBackgroundColor: _accent.withOpacity(0.5),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  elevation: 0),
                child: _loadingEstilo
                  ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : Text(appLang.resultMoreButton, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
              )),
          ),
      ]),
    );
  }

  Widget _buildImagePreview() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.fromLTRB(16, 8, 16, 6),
          child: Text('UpCrush AI',
            style: TextStyle(
              color: Color(0xFFFF2D55),
              fontSize: 26,
              fontWeight: FontWeight.w900,
              letterSpacing: -0.5))),
        Container(
          height: 360,
          width: double.infinity,
          margin: const EdgeInsets.fromLTRB(16, 0, 16, 0),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.15), blurRadius: 12, offset: const Offset(0, 4))]),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(18),
            child: Stack(fit: StackFit.expand, children: [
              Image.file(_imagem!, fit: BoxFit.cover),
              if (_analisando) Container(color: Colors.black.withOpacity(0.25)),
              Positioned(top: 8, left: 8, child: _corner(top: true, left: true)),
              Positioned(top: 8, right: 8, child: _corner(top: true, left: false)),
              Positioned(bottom: 8, left: 8, child: _corner(top: false, left: true)),
              Positioned(bottom: 8, right: 8, child: _corner(top: false, left: false)),
            ]))),
      ],
    );
  }

  Widget _buildEstilosBar(List<Map<String, dynamic>> estilos) {
    return SizedBox(
      height: 72,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
        itemCount: estilos.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (_, i) {
          final e = estilos[i];
          final ativo = e['key'] == _estiloAtual;
          final colors = e['colors'] as List<Color>;
          return GestureDetector(
            onTap: () => _gerarComEstilo(e['key']),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: ativo ? null : _cardBg,
                gradient: ativo ? LinearGradient(colors: [colors[0].withOpacity(0.2), colors[1].withOpacity(0.1)]) : null,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: ativo ? colors[0].withOpacity(0.6) : _cardBorder, width: ativo ? 1.5 : 1)),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                Container(width: 28, height: 28,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(colors: colors),
                    borderRadius: BorderRadius.circular(8),
                    boxShadow: [BoxShadow(color: (e['shadow'] as Color).withOpacity(ativo ? 0.45 : 0.2), blurRadius: 6, offset: const Offset(0, 2))]),
                  child: Icon(e['icon'] as IconData, color: Colors.white, size: 15)),
                const SizedBox(width: 8),
                Text(e['label'], style: TextStyle(
                  fontSize: 13, fontWeight: ativo ? FontWeight.w700 : FontWeight.w500,
                  color: _textPrimary)),
              ]),
            ),
          );
        },
      ),
    );
  }

  Widget _buildScanOverlay() {
    final lang = appLang.languageCode;
    return Center(
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        AnimatedBuilder(
          animation: _pulseAnim,
          builder: (_, __) => Transform.scale(
            scale: 0.9 + (_pulseAnim.value * 0.1),
            child: const Text('🌶️', style: TextStyle(fontSize: 52)))),
        const SizedBox(height: 20),
        AnimatedBuilder(
          animation: _pulseAnim,
          builder: (_, __) => Opacity(
            opacity: _pulseAnim.value,
            child: Text(_getFunLoadingMsg(lang),
              style: const TextStyle(color: _accent, fontSize: 16, fontWeight: FontWeight.w700),
              textAlign: TextAlign.center))),
        const SizedBox(height: 12),
        SizedBox(width: 160, child: ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: AnimatedBuilder(
            animation: _scanAnim,
            builder: (_, __) => LinearProgressIndicator(
              value: _scanAnim.value,
              backgroundColor: _accent.withOpacity(0.12),
              valueColor: const AlwaysStoppedAnimation(_accent),
              minHeight: 3)))),
      ]),
    );
  }

  Widget _buildRespostas() {
    if (_respostas.isEmpty) return const SizedBox.shrink();
    if (_loadingEstilo) {
      final lang = appLang.languageCode;
      return Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        AnimatedBuilder(
          animation: _pulseAnim,
          builder: (_, __) => Transform.scale(
            scale: 0.9 + (_pulseAnim.value * 0.1),
            child: const Text('🌶️', style: TextStyle(fontSize: 52)))),
        const SizedBox(height: 20),
        AnimatedBuilder(
          animation: _pulseAnim,
          builder: (_, __) => Opacity(
            opacity: _pulseAnim.value,
            child: Text(_getFunLoadingMsg(lang),
              style: const TextStyle(color: _accent, fontSize: 16, fontWeight: FontWeight.w700),
              textAlign: TextAlign.center))),
        const SizedBox(height: 12),
        SizedBox(width: 160, child: ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: AnimatedBuilder(
            animation: _scanAnim,
            builder: (_, __) => LinearProgressIndicator(
              value: _scanAnim.value,
              backgroundColor: _accent.withOpacity(0.12),
              valueColor: const AlwaysStoppedAnimation(_accent),
              minHeight: 3)))),
      ]));
    }
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      itemCount: _respostas.length,
      itemBuilder: (_, index) {
        final isCopied = _copiedIndex == index;
        return GestureDetector(
          onTap: () => _copiar(_respostas[index], index),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: isCopied ? _success.withOpacity(_dark ? 0.12 : 0.08) : _cardBg,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isCopied ? _success.withOpacity(0.4) : _cardBorder,
                width: isCopied ? 1.5 : 1),
              boxShadow: _dark ? [] : [
                BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 2))]),
            child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Expanded(child: Text(_respostas[index],
                style: TextStyle(color: _textPrimary, fontSize: 13, height: 1.4, fontWeight: FontWeight.w400))),
              const SizedBox(width: 10),
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                decoration: BoxDecoration(
                  color: isCopied ? _success.withOpacity(0.12) : _accent.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: isCopied ? _success.withOpacity(0.4) : _accent.withOpacity(0.2))),
                child: Text(
                  isCopied ? appLang.resultCopied : appLang.resultCopy,
                  style: TextStyle(color: isCopied ? _success : _accent, fontSize: 10, fontWeight: FontWeight.w600))),
            ]),
          ),
        );
      },
    );
  }

  Widget _corner({required bool top, required bool left}) =>
    SizedBox(width: 14, height: 14, child: CustomPaint(painter: _CornerPainter(top: top, left: left)));

  Widget _buildErro(lang) {
    final textColor = _dark ? Colors.white70 : Colors.black54;
    return Center(child: Padding(
      padding: const EdgeInsets.all(32),
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        const Text('😕', style: TextStyle(fontSize: 52)),
        const SizedBox(height: 20),
        Text(_erroMsg, textAlign: TextAlign.center,
          style: TextStyle(color: textColor, fontSize: 15, height: 1.5)),
        const SizedBox(height: 32),
        ElevatedButton(
          onPressed: () { setState(() { _erro = false; _imagem = null; _base64Image = null; _respostas = []; }); _processarImagem(); },
          style: ElevatedButton.styleFrom(backgroundColor: _accent, foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
          child: Text(lang.errorRetry)),
        const SizedBox(height: 12),
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(lang.errorBack, style: TextStyle(color: textColor.withOpacity(0.5)))),
      ]),
    ));
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
    if (top && left) { path.moveTo(0, size.height); path.lineTo(0, 0); path.lineTo(size.width, 0); }
    else if (top && !left) { path.moveTo(0, 0); path.lineTo(size.width, 0); path.lineTo(size.width, size.height); }
    else if (!top && left) { path.moveTo(0, 0); path.lineTo(0, size.height); path.lineTo(size.width, size.height); }
    else { path.moveTo(0, size.height); path.lineTo(size.width, size.height); path.lineTo(size.width, 0); }
    canvas.drawPath(path, paint);
  }
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}