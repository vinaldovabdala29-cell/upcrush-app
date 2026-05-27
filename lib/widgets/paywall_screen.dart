// lib/widgets/paywall_screen.dart
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../main.dart';
import '../services/revenue_cat_service.dart';
import '../services/credits_service.dart';
import '../theme/paywall_strings.dart';
import 'paywall_price_card.dart';
import 'paywall_features.dart';
import 'paywall_trial_text.dart';

Future<void> _openUrl(String url) async {
  try {
    await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
  } catch (_) {}
}

class PaywallFlow extends StatefulWidget {
  const PaywallFlow({super.key});
  @override
  State<PaywallFlow> createState() => _PaywallFlowState();
}

class _PaywallFlowState extends State<PaywallFlow> {
  bool _loading = false;
  // Começa vazio — mostra loading até buscar o preço real
  String _price = '';

  @override
  void initState() {
    super.initState();
    // Busca o preço real da App Store/Play Store via RevenueCat
    RevenueCatService.getPrice().then((p) {
      if (mounted) setState(() => _price = p);
    });
  }

  Future<void> _handlePurchase() async {
    setState(() => _loading = true);
    final result = await RevenueCatService.buyWeekly();
    setState(() => _loading = false);
    if (!mounted) return;
    if (result.success) {
      await CreditsService.setPremium(true);
      Navigator.pop(context, true);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(PS.get('welcome', appLang.languageCode)),
        backgroundColor: const Color(0xFF34C759),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))));
    } else if (!result.cancelled) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(result.error ?? "Error"),
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
    final l = appLang.languageCode;
    if (result.success) {
      Navigator.pop(context, true);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(PS.get('restored', l)),
        backgroundColor: const Color(0xFF34C759),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(PS.get('no_purchase', l)),
        backgroundColor: Colors.orange,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))));
    }
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder(
      valueListenable: appLangNotifier,
      builder: (_, lang, __) {
        final l = lang.languageCode;
        final size = MediaQuery.of(context).size;
        final isTablet = size.shortestSide >= 600;
        final bottom = MediaQuery.of(context).padding.bottom;

        // Mostra loading enquanto busca o preço
        if (_price.isEmpty) {
          return const Scaffold(
            backgroundColor: Colors.white,
            body: Center(child: CircularProgressIndicator(
              color: Color(0xFFFF2D55), strokeWidth: 2)));
        }

        return Scaffold(
          backgroundColor: Colors.white,
          body: SafeArea(
            child: SingleChildScrollView(
              child: Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: isTablet ? size.width * 0.15 : 28,
                  vertical: 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [

                    // ── Close ─────────────────────────────────────────
                    Align(
                      alignment: Alignment.topRight,
                      child: GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: Container(
                          width: 32, height: 32,
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.07),
                            shape: BoxShape.circle),
                          child: const Icon(Icons.close, size: 16, color: Colors.black45)),
                      ),
                    ),

                    SizedBox(height: isTablet ? 32 : 20),

                    // ── Logo ──────────────────────────────────────────
                    RichText(text: TextSpan(children: [
                      TextSpan(text: "Up", style: TextStyle(
                        fontSize: isTablet ? 48 : 38,
                        fontWeight: FontWeight.w900,
                        color: const Color(0xFF1C1C1E), letterSpacing: -1.5)),
                      TextSpan(text: "Crush", style: TextStyle(
                        fontSize: isTablet ? 48 : 38,
                        fontWeight: FontWeight.w900,
                        color: const Color(0xFFFF2D55), letterSpacing: -1.5)),
                    ])),

                    SizedBox(height: isTablet ? 8 : 6),

                    // ── Badge ─────────────────────────────────────────
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFFFF2D55), Color(0xFFFF6B81)]),
                        borderRadius: BorderRadius.circular(20)),
                      child: Text("✦ PREMIUM", style: TextStyle(
                        color: Colors.white,
                        fontSize: isTablet ? 13 : 11,
                        fontWeight: FontWeight.w800, letterSpacing: 1.5)),
                    ),

                    SizedBox(height: isTablet ? 40 : 28),

                    // ── Title ─────────────────────────────────────────
                    Text(PS.get('plans_title', l),
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: const Color(0xFF1C1C1E),
                        fontSize: isTablet ? 34 : 26,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -0.8, height: 1.15)),

                    SizedBox(height: isTablet ? 12 : 8),

                    Text(PS.get('plans_sub', l),
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.black54,
                        fontSize: isTablet ? 16 : 14,
                        fontWeight: FontWeight.w500)),

                    SizedBox(height: isTablet ? 40 : 28),

                    // ── Features (ficheiro separado) ───────────────────
                    PaywallFeatures(lang: l, isTablet: isTablet),

                    SizedBox(height: isTablet ? 28 : 20),

                    // ── Price Card (ficheiro separado) ────────────────
                    PaywallPriceCard(
                      price: _price,
                      lang: l,
                      isTablet: isTablet),

                    SizedBox(height: isTablet ? 28 : 20),

                    // ── No payment ────────────────────────────────────
                    Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                      Container(width: 16, height: 16,
                        decoration: const BoxDecoration(
                          color: Color(0xFF34C759), shape: BoxShape.circle),
                        child: const Icon(Icons.check, color: Colors.white, size: 11)),
                      const SizedBox(width: 8),
                      Text(PS.get('no_payment', l), style: TextStyle(
                        color: Colors.black54,
                        fontSize: isTablet ? 17 : 15,
                        fontWeight: FontWeight.w600)),
                    ]),

                    SizedBox(height: isTablet ? 16 : 12),

                    // ── CTA Button ────────────────────────────────────
                    SizedBox(
                      width: double.infinity,
                      height: isTablet ? 64 : 56,
                      child: ElevatedButton(
                        onPressed: _loading ? null : _handlePurchase,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFFF2D55),
                          foregroundColor: Colors.white,
                          disabledBackgroundColor: const Color(0xFFFF2D55).withOpacity(0.5),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16)),
                          elevation: 0),
                        child: _loading
                          ? const SizedBox(width: 22, height: 22,
                              child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                          : Text(PS.get('trial', l), style: TextStyle(
                              fontSize: isTablet ? 18 : 16,
                              fontWeight: FontWeight.w800)),
                      )),

                    SizedBox(height: isTablet ? 12 : 8),

                    // ── Trial sub (ficheiro separado) ─────────────────
                    PaywallTrialText(
                      price: _price,
                      lang: l,
                      isTablet: isTablet),

                    SizedBox(height: isTablet ? 16 : 12),

                    // ── Terms · Privacy ───────────────────────────────
                    Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                      _link("Terms", () => _openUrl(
                        'https://sites.google.com/view/upcrush-terms/p%C3%A1gina-inicial'), isTablet),
                      _sep(isTablet),
                      _link("Privacy", () => _openUrl(
                        'https://sites.google.com/view/upcrush-privacy-policy/p%C3%A1gina-inicial'), isTablet),
                    ]),

                    SizedBox(height: bottom + 8),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _link(String t, VoidCallback onTap, bool isTablet) => GestureDetector(
    onTap: onTap,
    child: Text(t, style: TextStyle(
      color: Colors.black54,
      fontSize: isTablet ? 15 : 13,
      fontWeight: FontWeight.w500,
      decoration: TextDecoration.underline,
      decorationColor: Colors.black38)));

  Widget _sep(bool isTablet) => Text("  ·  ",
    style: TextStyle(color: Colors.black38, fontSize: isTablet ? 15 : 13));
}