// lib/widgets/paywall_screen.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../main.dart';
import '../services/revenue_cat_service.dart';
import '../services/credits_service.dart';

Future<void> _openUrl(String url) async {
  try {
    await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
  } catch (_) {}
}

class PaywallFlow extends StatefulWidget {
  final VoidCallback? onSuccess;
  const PaywallFlow({super.key, this.onSuccess});
  @override
  State<PaywallFlow> createState() => _PaywallFlowState();
}

class _PaywallFlowState extends State<PaywallFlow> {
  bool _loading = false;
  String _price = '';
  bool? _eligibleForTrial;
  int _currentPhoto = 0;
  late Timer _timer;
  late PageController _pageController;

  static const _bgTop    = Color(0xFF050008);
  static const _bgBottom = Color(0xFF0D0118);
  static const _accent   = Color(0xFFFF2D55);
  static const _green    = Color(0xFF34C759);
  static const _purple   = Color(0xFFBB86FC);

  static const _photos = [
    'assets/images/casal1.jpg',
    'assets/images/casal2.jpg',
    'assets/images/casal3.jpg',
  ];

  @override
  void initState() {
    super.initState();
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle.light);
    _pageController = PageController();
    RevenueCatService.getPrice().then((p) {
      if (mounted) setState(() => _price = p);
    });
    // Verifica se o utilizador já usou o trial de 7 dias antes,
    // para mostrar o texto certo por baixo do botão.
    RevenueCatService.isEligibleForTrial().then((eligible) {
      if (mounted) setState(() => _eligibleForTrial = eligible);
    });
    _timer = Timer.periodic(const Duration(seconds: 5), (_) {
      if (!mounted) return;
      final next = (_currentPhoto + 1) % _photos.length;
      _pageController.animateToPage(next,
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOut);
    });
  }

  @override
  void dispose() {
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle.dark);
    _timer.cancel();
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _handlePurchase() async {
    setState(() => _loading = true);
    final result = await RevenueCatService.buyWeekly();
    setState(() => _loading = false);
    if (!mounted) return;
    if (result.success) {
      await CreditsService.setPremium(true);
      if (widget.onSuccess != null) {
        widget.onSuccess!();
      } else if (mounted) {
        Navigator.pop(context, true);
      }
    } else if (!result.cancelled) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(result.error ?? 'Error'),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))));
    }
  }

  Future<void> _handleRestore() async {
    setState(() => _loading = true);
    final result = await RevenueCatService.restorePurchases();
    setState(() => _loading = false);
    if (!mounted) return;
    if (result.success) {
      await CreditsService.setPremium(true);
      if (widget.onSuccess != null) {
        widget.onSuccess!();
      } else if (mounted) {
        Navigator.pop(context, true);
      }
    }
  }

  // ── Textos ──────────────────────────────────────────────────────────────
  String _headline(String l) {
    switch (l) {
      case 'de': return 'Verbessere dein Sozialleben';
      case 'es': return 'Mejora tu vida social';
      case 'pt': return 'Melhore a tua vida social';
      default:   return 'Improve Your Social Life';
    }
  }

  String _subHeadline(String l) {
    switch (l) {
      case 'de': return 'Werde besser darin, mit Mädels zu sprechen';
      case 'es': return 'Mejora hablando con chicas';
      case 'pt': return 'Melhora a falar com garotas';
      default:   return 'Get better at speaking with girls';
    }
  }

  String _ctaLabel(String l) {
    switch (l) {
      case 'de': return 'Weiter';
      case 'es': return 'Continuar';
      case 'pt': return 'Continuar';
      default:   return 'Continue';
    }
  }

  String _noCommitment(String l) {
    switch (l) {
      case 'de': return 'Keine Verpflichtung, jederzeit kündbar';
      case 'es': return 'Sin compromiso, cancela cuando quieras';
      case 'pt': return 'Sem compromisso, cancele quando quiser';
      default:   return 'No commitment, cancel anytime';
    }
  }

  String _trialLine(String l) {
    // Preço fixo visual — não usa o valor devolvido pela API do
    // RevenueCat, para evitar mostrar moeda errada (ex: dólar em
    // vez de euro) consoante a região da conta do dispositivo.
    const price = '6,99 €';
    final eligible = _eligibleForTrial ?? true;

    if (eligible) {
      switch (l) {
        case 'de': return '7 Tage kostenlos, danach $price/Woche';
        case 'es': return '7 días gratis, luego $price/semana';
        case 'pt': return '7 dias grátis, depois $price/semana';
        default:   return '7 days free, then $price per week';
      }
    } else {
      switch (l) {
        case 'de': return 'Abgerechnet $price/Woche';
        case 'es': return 'Se factura $price/semana';
        case 'pt': return 'Cobrado $price/semana';
        default:   return 'Billed $price per week';
      }
    }
  }

  String _restore(String l) {
    switch (l) {
      case 'de': return 'Wiederherstellen';
      case 'es': return 'Restaurar';
      case 'pt': return 'Restaurar';
      default:   return 'Restore';
    }
  }

  List<Map<String, String>> _features(String l) {
    switch (l) {
      case 'de': return [
        {'icon': '🎯', 'text': 'Nachrichten, die echte Reaktionen erzeugen'},
        {'icon': '🔥', 'text': 'Gespräche aufwärmen oder eskalieren'},
        {'icon': '📆', 'text': 'Mehr echte Dates, weniger Ghosting'},
      ];
      case 'es': return [
        {'icon': '🎯', 'text': 'Mensajes que generan reacciones reales'},
        {'icon': '🔥', 'text': 'Calienta conversaciones o escala'},
        {'icon': '📆', 'text': 'Más citas reales, menos ghosting'},
      ];
      case 'pt': return [
        {'icon': '🎯', 'text': 'Mensagens que geram reações reais'},
        {'icon': '🔥', 'text': 'Reaqueça conversas ou escale'},
        {'icon': '📆', 'text': 'Mais encontros reais, menos ghosting'},
      ];
      default: return [
        {'icon': '🎯', 'text': 'Messages that generate real reactions'},
        {'icon': '🔥', 'text': 'Warm up conversations or escalate'},
        {'icon': '📆', 'text': 'More real dates, less ghosting'},
      ];
    }
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder(
      valueListenable: appLangNotifier,
      builder: (_, lang, __) {
        final l = lang.languageCode;
        final bottom = MediaQuery.of(context).padding.bottom;

        return Scaffold(
          body: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [_bgTop, _bgBottom],
              ),
            ),
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: SingleChildScrollView(
                  child: Column(
                    children: [

                      const SizedBox(height: 16),

                      // ── Headline + subheadline ───────────────────
                      Text(
                        _headline(l),
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: _purple,
                          fontSize: 30,
                          fontWeight: FontWeight.w700,
                          letterSpacing: -0.7,
                          height: 1.08,
                        ),
                      ),

                      const SizedBox(height: 8),

                      Text(
                        _subHeadline(l),
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.78),
                          fontSize: 17,
                          fontWeight: FontWeight.w500,
                          height: 1.25,
                        ),
                      ),

                      const SizedBox(height: 28),

                      // ── Carrossel centralizado ─────────────────────────
                      SizedBox(
                        height: 355,
                        child: Center(
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 390),
                            child: PageView.builder(
                              controller: _pageController,
                              onPageChanged: (i) =>
                                  setState(() => _currentPhoto = i),
                              itemCount: _photos.length,
                              itemBuilder: (_, i) => Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 4),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(24),
                                  child: Image.asset(
                                    _photos[i],
                                    fit: BoxFit.cover,
                                    width: double.infinity,
                                    height: double.infinity,
                                    errorBuilder: (_, __, ___) => Container(
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(24),
                                        gradient: LinearGradient(
                                          colors: [
                                            [
                                              const Color(0xFF6C3483),
                                              const Color(0xFFAB47BC)
                                            ],
                                            [
                                              const Color(0xFF1A237E),
                                              const Color(0xFF42A5F5)
                                            ],
                                            [
                                              const Color(0xFF880E4F),
                                              const Color(0xFFEC407A)
                                            ],
                                          ][i],
                                          begin: Alignment.topLeft,
                                          end: Alignment.bottomRight,
                                        ),
                                      ),
                                      child: Center(
                                        child: Text(
                                          ['💑', '🛋️', '💬'][i],
                                          style: const TextStyle(fontSize: 60),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 12),

                      // ── Dots ──────────────────────────────────────────
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(
                          _photos.length,
                          (i) => AnimatedContainer(
                            duration: const Duration(milliseconds: 300),
                            margin: const EdgeInsets.symmetric(horizontal: 4),
                            width: 7,
                            height: 7,
                            decoration: BoxDecoration(
                              color: _currentPhoto == i
                                  ? Colors.white
                                  : Colors.white.withOpacity(0.30),
                              shape: BoxShape.circle,
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 26),

                      // ── No commitment ─────────────────────────────────
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            width: 17,
                            height: 17,
                            decoration: const BoxDecoration(
                              color: _green,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.check,
                              color: Colors.white,
                              size: 12,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Flexible(
                            child: Text(
                              _noCommitment(l),
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 18),

                      // ── CTA Button ────────────────────────────────────
                      SizedBox(
                        width: double.infinity,
                        height: 58,
                        child: ElevatedButton(
                          onPressed: _loading ? null : _handlePurchase,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _accent,
                            foregroundColor: Colors.white,
                            disabledBackgroundColor: _accent.withOpacity(0.4),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(18),
                            ),
                            elevation: 0,
                          ),
                          child: _loading
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2,
                                  ),
                                )
                              : Text(
                                  _ctaLabel(l),
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                        ),
                      ),

                      const SizedBox(height: 10),

                      // ── Trial line ────────────────────────────────────
                      Text(
                        _trialLine(l),
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),

                      const SizedBox(height: 18),

                      // ── Terms · Privacy ───────────────────────────────
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _link(
                            'Terms',
                            () => _openUrl(
                              'https://sites.google.com/view/upcrush-terms/p%C3%A1gina-inicial',
                            ),
                          ),
                          _sep(),
                          _link(
                            'Privacy',
                            () => _openUrl(
                              'https://sites.google.com/view/upcrush-privacy-policy/p%C3%A1gina-inicial',
                            ),
                          ),
                        ],
                      ),

                      SizedBox(height: bottom + 12),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _link(String t, VoidCallback onTap) => GestureDetector(
    onTap: onTap,
    child: Text(t,
      style: TextStyle(
        color: Colors.white.withOpacity(0.5),
        fontSize: 13,
        fontWeight: FontWeight.w500,
        decoration: TextDecoration.underline,
        decorationColor: Colors.white.withOpacity(0.2),
      ),
    ),
  );

  Widget _sep() => Text('     ',
    style: TextStyle(color: Colors.white.withOpacity(0.2), fontSize: 13));
}