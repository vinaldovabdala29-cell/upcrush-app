import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../main.dart';
import '../services/revenue_cat_service.dart';
import '../services/credits_service.dart';

class PaywallFlow extends StatefulWidget {
  final VoidCallback? onSuccess;
  const PaywallFlow({super.key, this.onSuccess});
  @override
  State<PaywallFlow> createState() => _PaywallFlowState();
}

class _PaywallFlowState extends State<PaywallFlow> {
  bool _loading = false;
  String _price = '';

  @override
  void initState() {
    super.initState();
    RevenueCatService.getPrice().then((value) {
      if (mounted) setState(() => _price = value);
    });
  }

  String _t(String l, String en, String pt, String de, String es) {
    switch (l) {
      case 'pt': return pt;
      case 'de': return de;
      case 'es': return es;
      default: return en;
    }
  }

  Future<void> _buy() async {
    if (_loading || _price.isEmpty) return;
    setState(() => _loading = true);
    final result = await RevenueCatService.buyWeekly();
    if (!mounted) return;
    setState(() => _loading = false);
    if (result.success) {
      await CreditsService.setPremium(true);
      if (!mounted) return;
      if (widget.onSuccess != null) {
        widget.onSuccess!();
      } else {
        Navigator.of(context).pop(true);
      }
    } else if (!result.cancelled) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result.error ?? 'Purchase unavailable')),
      );
    }
  }

  Future<void> _open(String url) async {
    await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder(
      valueListenable: appLangNotifier,
      builder: (context, locale, _) {
        final l = locale.languageCode;
        return Scaffold(
          backgroundColor: Colors.black,
          body: SafeArea(
            child: LayoutBuilder(builder: (context, constraints) {
              // Compact, non-scrollable layout that fits small iPhones and Androids.
              // Keep breathing room at the top and bottom, and never enlarge
              // the reference design on tall devices.
              final scale = ((constraints.maxHeight - 32) / 850)
                  .clamp(0.45, 1.0);
              final width = constraints.maxWidth;
              final horizontal = 22.0;
              final designWidth = (width - horizontal * 2) / scale;
              Widget heading(String text, double fontSize, {Color color = Colors.white}) =>
                  Text(text, textAlign: TextAlign.center,
                    style: TextStyle(color: color, fontSize: fontSize,
                      fontWeight: FontWeight.w900, height: 1.02, letterSpacing: -0.7));

              return Stack(children: [
                const Positioned.fill(child: IgnorePointer(child: DecoratedBox(
                  decoration: BoxDecoration(gradient: RadialGradient(
                    center: Alignment(0, -0.10), radius: 0.85,
                    colors: [Color(0xFF68108F), Color(0xFF39094F), Color(0xFF100619), Colors.black],
                    stops: [0, 0.37, 0.75, 1],
                  )),
                ))),
                Positioned.fill(child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: horizontal),
                  child: Center(child: SizedBox(
                    width: designWidth * scale,
                    height: 760 * scale,
                    child: Transform.scale(
                      scale: scale, alignment: Alignment.center,
                      child: SizedBox(width: designWidth, height: 760,
                        child: Column(children: [
                          SizedBox(height: 55, child: Stack(children: [
                            Center(child: heading('UPCRUSH', 32)),
                            Positioned(right: 0, top: 2, child: IconButton(
                              tooltip: _t(l, 'Close', 'Fechar', 'Schließen', 'Cerrar'),
                              onPressed: () => Navigator.of(context).pop(false),
                              icon: const Icon(Icons.close, color: Colors.white, size: 30),
                            )),
                          ])),
                          const Spacer(flex: 2),
                          heading(_t(l, 'Your one time offer', 'Sua única oferta',
                            'Dein einmaliges Angebot', 'Tu oferta única'), 27),
                          const SizedBox(height: 19),
                          heading('80%\nOFF', 73),
                          const Spacer(flex: 2),
                          heading('Once you close this offer, it’s gone.', 17),
                          const Spacer(flex: 3),
                          Container(
                            decoration: BoxDecoration(color: Colors.black,
                              border: Border.all(color: Colors.white, width: 2),
                              borderRadius: BorderRadius.circular(20)),
                            child: Column(mainAxisSize: MainAxisSize.min, children: [
                              Container(width: double.infinity,
                                padding: const EdgeInsets.symmetric(vertical: 7),
                                decoration: const BoxDecoration(color: Colors.white,
                                  borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
                                child: heading(_t(l, 'SAVE 80%', 'Economize 80%',
                                  '80% SPAREN', 'AHORRA 80%'), 19, color: Colors.black)),
                              Padding(padding: const EdgeInsets.fromLTRB(15, 13, 15, 15),
                                child: Row(children: [
                                  const Icon(Icons.radio_button_checked, color: Colors.white, size: 26),
                                  const SizedBox(width: 12),
                                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                    Row(children: [
                                      Expanded(child: Text(_t(l, 'Weekly', 'Semanal', 'Wöchentlich', 'Semanal'),
                                        style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w800))),
                                      // A 7.99 EUR weekly subscription costs 1.14 EUR/day.
                                      // Never advertise 0.86 EUR/day with that weekly price.
                                      if (_price.contains('7,99') || _price.contains('7.99'))
                                        const Text('1,14 €/dia', style: TextStyle(color: Colors.white,
                                          fontSize: 16, fontWeight: FontWeight.w800)),
                                    ]),
                                    const SizedBox(height: 4),
                                    Text(_price.isEmpty
                                      ? _t(l, 'Loading price…', 'A carregar preço…', 'Preis wird geladen…', 'Cargando precio…')
                                      : _t(l, 'Billed $_price per week', 'Cobrado $_price por semana',
                                          '$_price pro Woche', 'Cobro de $_price por semana'),
                                      style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600)),
                                  ])),
                                ])),
                            ]),
                          ),
                          const SizedBox(height: 16),
                          SizedBox(width: double.infinity, height: 59, child: ElevatedButton(
                            onPressed: _loading || _price.isEmpty ? null : _buy,
                            style: ElevatedButton.styleFrom(backgroundColor: Colors.white,
                              foregroundColor: Colors.black, disabledBackgroundColor: Colors.white70,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24))),
                            child: _loading ? const CircularProgressIndicator(color: Colors.black)
                              : Text(_t(l, 'Take my offer', 'Aproveitar oferta',
                                'Angebot sichern', 'Aprovechar oferta'),
                                style: const TextStyle(fontSize: 21, fontWeight: FontWeight.w900)),
                          )),
                          const SizedBox(height: 10),
                          Text(_t(l, 'No commitment. Cancel anytime.',
                            'Sem compromisso. Cancela quando quiseres.',
                            'Keine Bindung. Jederzeit kündbar.',
                            'Sin compromiso. Cancela cuando quieras.'),
                            textAlign: TextAlign.center,
                            style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w700)),
                          const SizedBox(height: 12),
                          Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                            _legalButton('Terms', 'https://sites.google.com/view/upcrush-terms/p%C3%A1gina-inicial'),
                            const SizedBox(width: 16),
                            _legalButton('Privacy', 'https://sites.google.com/view/upcrush-privacy-policy/p%C3%A1gina-inicial'),
                          ]),
                          const SizedBox(height: 8),
                        ]),
                      ),
                    ),
                  )),
                )),
              ]);
            }),
          ),
        );
      },
    );
  }

  Widget _legalButton(String title, String url) => SizedBox(
    height: 36,
    child: TextButton(
      onPressed: () => _open(url),
      style: TextButton.styleFrom(backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        padding: const EdgeInsets.symmetric(horizontal: 22)),
      child: Text(title, style: const TextStyle(fontWeight: FontWeight.w800)),
    ),
  );
}
