import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/ai_service.dart';
import '../../../main.dart';

class PickLinesScreen extends StatefulWidget {
  const PickLinesScreen({super.key});

  @override
  State<PickLinesScreen> createState() => _PickLinesScreenState();
}

class _PickLinesScreenState extends State<PickLinesScreen>
    with TickerProviderStateMixin {

  // ============================================================
  // STATE
  // ============================================================

  String _currentLine = '';
  String _currentCategoryKey = 'surpreenda_me';
  String _selectedCategoryKey = 'surpreenda_me';

  // Guarda as últimas linhas geradas nesta sessão, para evitar
  // repetição — enviado ao AIService em cada chamada.
  final List<String> _recentLines = [];
  static const int _maxRecentLines = 20;

  bool _loading = false;
  bool _copied = false;

  // ============================================================
  // ANIMATIONS
  // ============================================================

  late AnimationController _pulseController;
  late Animation<double> _pulseAnim;

  late AnimationController _scanController;
  late Animation<double> _scanAnim;

  // ============================================================
  // COLORS
  // ============================================================

  static const _accent = Color(0xFFFF2D55);
  static const _success = Color(0xFF34C759);

  bool get _dark => isDarkModeNotifier.value;

  Color get _bg => _dark ? const Color(0xFF0A0A10) : const Color(0xFFF2F2F7);
  Color get _textPrimary => _dark ? Colors.white : const Color(0xFF1C1C1E);
  Color get _textSecondary => _dark ? Colors.white38 : Colors.black38;
  Color get _cardBg => _dark ? Colors.white.withOpacity(0.06) : Colors.white.withOpacity(0.85);

  // ============================================================
  // INIT
  // ============================================================

  @override
  void initState() {
    super.initState();

    isDarkModeNotifier.addListener(_onThemeChange);

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..repeat(reverse: true);

    _pulseAnim = Tween<double>(begin: 0.4, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _scanController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat();

    _scanAnim = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _scanController, curve: Curves.easeInOut),
    );

    WidgetsBinding.instance.addPostFrameCallback((_) => _gerar());
  }

  // ============================================================
  // DISPOSE
  // ============================================================

  @override
  void dispose() {
    isDarkModeNotifier.removeListener(_onThemeChange);
    _pulseController.dispose();
    _scanController.dispose();
    super.dispose();
  }

  // ============================================================
  // THEME
  // ============================================================

  void _onThemeChange() {
    if (mounted) setState(() {});
  }

  // ============================================================
  // RECENT LINES TRACKING
  // ============================================================

  void _rememberLine(String line) {
    if (line.isEmpty) return;
    _recentLines.add(line);
    // Mantém só as últimas N linhas — suficiente para evitar
    // repetição sem crescer indefinidamente nem sobrecarregar o
    // prompt enviado à IA.
    if (_recentLines.length > _maxRecentLines) {
      _recentLines.removeAt(0);
    }
  }

  // ============================================================
  // LOADING MESSAGE
  // ============================================================

  String _getFunLoadingMsg(String lang) {
    switch (lang) {
      case 'de': return 'Dein nächster Flirt wird vorbereitet... 🌶️';
      case 'es': return 'Preparando tu próximo coqueteo... 🌶️';
      case 'fr': return 'On prépare ton prochain flirt... 🌶️';
      case 'it': return 'Preparando il tuo prossimo flirt... 🌶️';
      case 'tr': return 'Sıradaki flörtün hazırlanıyor... 🌶️';
      case 'pl': return 'Przygotowuję twój kolejny flirt... 🌶️';
      case 'ru': return 'Готовлю твой следующий флирт... 🌶️';
      case 'ar': return '...أجهز غزلك القادم 🌶️';
      case 'pt': return 'Preparando seu próximo flerte... 🌶️';
      default:   return 'Preparing your next flirt... 🌶️';
    }
  }

  // ============================================================
  // GENERATE
  // ============================================================

  Future<void> _gerar() async {
    if (_loading) return;
    if (!mounted) return;

    setState(() {
      _loading = true;
      _copied = false;
    });

    try {
      final categoryKey = _selectedCategoryKey;

      final line = await AIService.gerarPickLine(
        lang: appLang.languageCode,
        categoria: categoryKey,
        recentLines: List<String>.from(_recentLines),
      );

      if (!mounted) return;

      setState(() {
        _currentCategoryKey = categoryKey;
        _currentLine = line;
        _loading = false;
      });

      _rememberLine(line);
    } catch (_) {
      if (!mounted) return;
      setState(() => _loading = false);
    }
  }

  // ============================================================
  // NEXT
  // ============================================================

  void _next() {
    if (_loading) return;
    _gerar();
  }

  Future<void> _selectCategory(String key) async {
    if (_loading || key == _selectedCategoryKey) return;

    HapticFeedback.selectionClick();

    setState(() {
      _selectedCategoryKey = key;
      _currentCategoryKey = key;
    });

    await _gerar();
  }

  Widget _buildCategorySelector(String languageCode) {
    return SizedBox(
      height: 46,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: AIService.cantadaCategoriaKeys.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final key = AIService.cantadaCategoriaKeys[index];
          final selected = key == _selectedCategoryKey;
          final label = AIService.cantadaCategoriaNome(key, languageCode);

          return GestureDetector(
            onTap: _loading ? null : () => _selectCategory(key),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              curve: Curves.easeOut,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: selected
                    ? _accent
                    : (_dark
                        ? Colors.white.withOpacity(0.07)
                        : Colors.white.withOpacity(0.88)),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: selected
                      ? _accent
                      : (_dark
                          ? Colors.white.withOpacity(0.08)
                          : Colors.black.withOpacity(0.05)),
                ),
                boxShadow: selected && !_dark
                    ? [
                        BoxShadow(
                          color: _accent.withOpacity(0.18),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ]
                    : [],
              ),
              child: Center(
                child: Text(
                  label,
                  maxLines: 1,
                  style: TextStyle(
                    color: selected ? Colors.white : _textPrimary,
                    fontSize: 13,
                    fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  // ============================================================
  // COPY
  // ============================================================

  Future<void> _copy() async {
    if (_currentLine.isEmpty) return;

    await Clipboard.setData(ClipboardData(text: _currentLine));
    HapticFeedback.lightImpact();

    if (!mounted) return;
    setState(() => _copied = true);

    await Future.delayed(const Duration(seconds: 2));

    if (!mounted) return;
    setState(() => _copied = false);
  }

  // ============================================================
  // CATEGORY LABEL
  // ============================================================

  Widget _buildCategory(String languageCode) {
    final nomeTraduzido = AIService.cantadaCategoriaNome(_currentCategoryKey, languageCode);
    return Text(
      nomeTraduzido.toUpperCase(),
      textAlign: TextAlign.center,
      style: const TextStyle(
        color: _accent,
        fontSize: 12,
        fontWeight: FontWeight.w800,
        letterSpacing: 0.8,
      ),
    );
  }

  // ============================================================
  // LOADING UI
  // ============================================================

  Widget _buildLoading(String lang) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        AnimatedBuilder(
          animation: _pulseAnim,
          builder: (_, __) => Transform.scale(
            scale: 0.9 + (_pulseAnim.value * 0.1),
            child: const Text('🌶️', style: TextStyle(fontSize: 52)),
          ),
        ),
        const SizedBox(height: 20),
        AnimatedBuilder(
          animation: _pulseAnim,
          builder: (_, __) => Opacity(
            opacity: _pulseAnim.value,
            child: Text(
              _getFunLoadingMsg(lang),
              style: const TextStyle(color: _accent, fontSize: 16, fontWeight: FontWeight.w700),
              textAlign: TextAlign.center,
            ),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: 160,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: AnimatedBuilder(
              animation: _scanAnim,
              builder: (_, __) => LinearProgressIndicator(
                value: _scanAnim.value,
                backgroundColor: _accent.withOpacity(0.12),
                valueColor: const AlwaysStoppedAnimation(_accent),
                minHeight: 3,
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ============================================================
  // RESULT CARD
  // ============================================================

  Widget _buildResultCard(String languageCode) {
    if (_currentLine.isEmpty) return const SizedBox.shrink();

    return GestureDetector(
      onTap: _copy,
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        child: Container(
          key: ValueKey('$_currentCategoryKey$_currentLine'),
          width: double.infinity,
          padding: const EdgeInsets.all(28),
          decoration: BoxDecoration(
            color: _cardBg,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: _copied ? _success.withOpacity(0.4) : _accent.withOpacity(0.15),
              width: _copied ? 1.5 : 1,
            ),
            boxShadow: _dark
              ? []
              : [BoxShadow(color: _accent.withOpacity(0.08), blurRadius: 20, offset: const Offset(0, 8))],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildCategory(languageCode),
              const SizedBox(height: 18),
              Text(
                _currentLine,
                textAlign: TextAlign.center,
                style: TextStyle(color: _textPrimary, fontSize: 20, fontWeight: FontWeight.w600, height: 1.5),
              ),
              const SizedBox(height: 22),
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: _copied ? _success.withOpacity(0.1) : _accent.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: _copied ? _success.withOpacity(0.4) : _accent.withOpacity(0.2)),
                ),
                child: Text(
                  _copied ? appLang.resultCopied : appLang.resultCopy,
                  style: TextStyle(color: _copied ? _success : _accent, fontSize: 13, fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ============================================================
  // NEXT BUTTON
  // ============================================================

  Widget _buildNextButton(String languageCode) {
    String text;
    switch (languageCode) {
      case 'de': text = 'Nächste 🔥'; break;
      case 'pt': text = 'Próxima 🔥'; break;
      case 'es': text = 'Siguiente 🔥'; break;
      case 'fr': text = 'Suivante 🔥'; break;
      case 'it': text = 'Prossima 🔥'; break;
      case 'tr': text = 'Sonraki 🔥'; break;
      case 'pl': text = 'Następna 🔥'; break;
      case 'ru': text = 'Следующая 🔥'; break;
      case 'ar': text = 'التالية 🔥'; break;
      default:   text = 'Next 🔥';
    }

    return Padding(
      padding: EdgeInsets.fromLTRB(16, 0, 16, MediaQuery.of(context).padding.bottom + 16),
      child: SizedBox(
        height: 54,
        width: double.infinity,
        child: ElevatedButton(
          onPressed: _loading ? null : _next,
          style: ElevatedButton.styleFrom(
            backgroundColor: _accent,
            foregroundColor: Colors.white,
            disabledBackgroundColor: _accent.withOpacity(0.5),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            elevation: 0,
          ),
          child: _loading
            ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
            : Text(text, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
        ),
      ),
    );
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder(
      valueListenable: appLangNotifier,
      builder: (_, lang, __) {
        return Scaffold(
          backgroundColor: _bg,
          appBar: AppBar(
            backgroundColor: _bg,
            elevation: 0,
            leading: IconButton(
              icon: Icon(Icons.arrow_back_ios_rounded, color: _textPrimary, size: 20),
              onPressed: () => Navigator.pop(context),
            ),
            title: Text(
              lang.languageCode == 'pt'
                  ? 'Cantadas'
                  : lang.languageCode == 'de'
                      ? 'Flirtsprüche'
                      : lang.languageCode == 'es'
                          ? 'Frases para ligar'
                          : 'Pick Lines',
              style: TextStyle(color: _textPrimary, fontSize: 17, fontWeight: FontWeight.w700),
            ),
          ),
          body: Column(
            children: [
              const SizedBox(height: 8),
              _buildCategorySelector(lang.languageCode),
              const SizedBox(height: 10),
              Expanded(
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 28),
                    child: _loading
                        ? _buildLoading(lang.languageCode)
                        : _buildResultCard(lang.languageCode),
                  ),
                ),
              ),
              _buildNextButton(lang.languageCode),
            ],
          ),
        );
      },
    );
  }
}