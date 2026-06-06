import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/ai_service.dart';
import '../../../main.dart';
import '../services/revenue_cat_service.dart';
import '../widgets/paywall_screen.dart';

class PickLinesScreen extends StatefulWidget {
  const PickLinesScreen({super.key});

  @override
  State<PickLinesScreen> createState() => _PickLinesScreenState();
}

class _PickLinesScreenState extends State<PickLinesScreen> {
  List<String> _lines = [];
  int _currentIndex = 0;
  bool _loading = false;
  bool _copied = false;

  static const _accent = Color(0xFFFF2D55);
  static const _success = Color(0xFF34C759);

  bool get _dark => isDarkModeNotifier.value;
  Color get _bg => _dark ? const Color(0xFF0A0A10) : const Color(0xFFF2F2F7);
  Color get _textPrimary => _dark ? Colors.white : const Color(0xFF1C1C1E);
  Color get _textSecondary => _dark ? Colors.white38 : Colors.black38;

  @override
  void initState() {
    super.initState();
    isDarkModeNotifier.addListener(() { if (mounted) setState(() {}); });
    WidgetsBinding.instance.addPostFrameCallback((_) => _gerar());
  }

  Future<void> _gerar() async {
    final premium = await RevenueCatService.isPremium();
    if (!mounted) return;
    if (!premium) {
      final result = await Navigator.push(context, MaterialPageRoute(
        fullscreenDialog: true, builder: (_) => const PaywallFlow()));
      if (result != true) { if (mounted) Navigator.pop(context); return; }
    }
    setState(() { _loading = true; _copied = false; });
    try {
      final lines = await AIService.gerarPickLines(appLang.languageCode);
      setState(() {
        _lines = lines;
        _currentIndex = 0;
        _loading = false;
      });
    } catch (e) {
      setState(() => _loading = false);
    }
  }

  void _next() {
    setState(() {
      _copied = false;
      if (_currentIndex < _lines.length - 1) {
        _currentIndex++;
      } else {
        _gerar();
      }
    });
  }

  Future<void> _copy() async {
    if (_lines.isEmpty) return;
    await Clipboard.setData(ClipboardData(text: _lines[_currentIndex]));
    HapticFeedback.lightImpact();
    setState(() => _copied = true);
    await Future.delayed(const Duration(seconds: 2));
    if (mounted) setState(() => _copied = false);
  }

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
            title: Text("Get Pick Lines",
                style: TextStyle(color: _textPrimary, fontSize: 17, fontWeight: FontWeight.w700)),
          ),
          body: Column(
            children: [
              Expanded(
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 28),
                    child: _loading
                        ? Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const CircularProgressIndicator(color: _accent, strokeWidth: 2.5),
                              const SizedBox(height: 20),
                              Text(
                                lang.languageCode == 'de' ? "Generiere..."
                                    : lang.languageCode == 'pt' ? "A gerar..."
                                    : lang.languageCode == 'es' ? "Generando..."
                                    : "Generating...",
                                style: TextStyle(color: _textSecondary, fontSize: 14),
                              ),
                            ],
                          )
                        : _lines.isEmpty
                            ? const SizedBox.shrink()
                            : GestureDetector(
                                onTap: _copy,
                                child: AnimatedSwitcher(
                                  duration: const Duration(milliseconds: 300),
                                  child: Container(
                                    key: ValueKey(_currentIndex),
                                    width: double.infinity,
                                    padding: const EdgeInsets.all(28),
                                    decoration: BoxDecoration(
                                      color: _dark
                                          ? Colors.white.withOpacity(0.06)
                                          : Colors.white.withOpacity(0.85),
                                      borderRadius: BorderRadius.circular(24),
                                      border: Border.all(
                                        color: _copied
                                            ? _success.withOpacity(0.4)
                                            : _accent.withOpacity(0.15),
                                        width: _copied ? 1.5 : 1,
                                      ),
                                      boxShadow: _dark ? [] : [
                                        BoxShadow(
                                          color: _accent.withOpacity(0.08),
                                          blurRadius: 20,
                                          offset: const Offset(0, 8),
                                        ),
                                      ],
                                    ),
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text(
                                          _lines[_currentIndex],
                                          textAlign: TextAlign.center,
                                          style: TextStyle(
                                            color: _textPrimary,
                                            fontSize: 20,
                                            fontWeight: FontWeight.w600,
                                            height: 1.5,
                                          ),
                                        ),
                                        const SizedBox(height: 20),
                                        AnimatedContainer(
                                          duration: const Duration(milliseconds: 200),
                                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                          decoration: BoxDecoration(
                                            color: _copied
                                                ? _success.withOpacity(0.1)
                                                : _accent.withOpacity(0.08),
                                            borderRadius: BorderRadius.circular(20),
                                            border: Border.all(
                                              color: _copied
                                                  ? _success.withOpacity(0.4)
                                                  : _accent.withOpacity(0.2),
                                            ),
                                          ),
                                          child: Text(
                                            _copied ? appLang.resultCopied : appLang.resultCopy,
                                            style: TextStyle(
                                              color: _copied ? _success : _accent,
                                              fontSize: 13,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                  ),
                ),
              ),
              Padding(
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
                        ? const SizedBox(width: 22, height: 22,
                            child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                        : Text(
                            lang.languageCode == 'de' ? "Nächste 🔥"
                                : lang.languageCode == 'pt' ? "Próxima 🔥"
                                : lang.languageCode == 'es' ? "Siguiente 🔥"
                                : "Next 🔥",
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                          ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}