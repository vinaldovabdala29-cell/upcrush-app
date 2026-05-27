import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../main.dart';
import '../services/revenue_cat_service.dart';
import '../services/credits_service.dart';
import '../theme/paywall_strings.dart';

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
  String _price = '5.99';
  String _perWeekPrice = '5.99';

  @override
  void initState() {
    super.initState();
    RevenueCatService.getPrice().then((p) {
      if (mounted) setState(() {
        _price = p;
        _perWeekPrice = p;
      });
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

                    // ── Features ──────────────────────────────────────
                    Container(
                      width: double.infinity,
                      padding: EdgeInsets.symmetric(
                        horizontal: isTablet ? 28 : 20,
                        vertical: isTablet ? 20 : 14),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8F8F8),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Colors.black.withOpacity(0.06))),
                      child: Column(children: [
                        _feat("📸", PS.get('feat1', l), isTablet),
                        _feat("❤️", PS.get('feat2', l), isTablet),
                        _feat("🤖", PS.get('feat3', l), isTablet),
                        _feat("⚡", PS.get('feat4', l), isTablet),
                      ])),

                    SizedBox(height: isTablet ? 28 : 20),

                    // ── Price card ────────────────────────────────────
                    Container(
                      width: double.infinity,
                      padding: EdgeInsets.all(isTablet ? 28 : 22),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFFFF2D55), Color(0xFFFF6B81)],
                          begin: Alignment.topLeft, end: Alignment.bottomRight),
                        borderRadius: BorderRadius.circular(22),
                        boxShadow: [BoxShadow(
                          color: const Color(0xFFFF2D55).withOpacity(0.35),
                          blurRadius: 20, offset: const Offset(0, 8))]),
                      child: Row(children: [
                        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          // 3 dias grátis — some após primeiro pagamento
                          FutureBuilder<bool>(
                            future: CreditsService.isPremium(),
                            builder: (_, snap) {
                              if (snap.data == true) return const SizedBox.shrink();
                              return Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withOpacity(0.25),
                                      borderRadius: BorderRadius.circular(8)),
                                    child: Text(PS.get('free_days', l), style: TextStyle(
                                      color: Colors.white,
                                      fontSize: isTablet ? 13 : 11,
                                      fontWeight: FontWeight.w800, letterSpacing: 0.8))),
                                  SizedBox(height: isTablet ? 14 : 10),
                                ]);
                            }),
                          Text(PS.get('weekly', l), style: TextStyle(
                            color: Colors.white70,
                            fontSize: isTablet ? 16 : 14,
                            fontWeight: FontWeight.w500)),
                          Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
                            Text(_price, style: TextStyle(
                              color: Colors.white,
                              fontSize: isTablet ? 52 : 40,
                              fontWeight: FontWeight.w900, letterSpacing: -1)),
                            Padding(
                              padding: const EdgeInsets.only(bottom: 6),
                              child: Text(PS.get('per_week', l), style: TextStyle(
                                color: Colors.white60,
                                fontSize: isTablet ? 16 : 14))),
                          ]),
                        ]),
                        const Spacer(),
                        Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                          Text(PS.get('today', l), style: TextStyle(
                            color: Colors.white.withOpacity(0.6),
                            fontSize: isTablet ? 14 : 12)),
                          const Text("0.00", style: TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.w800)),
                          SizedBox(height: isTablet ? 12 : 8),
                          Text(PS.get('after_trial', l), style: TextStyle(
                            color: Colors.white.withOpacity(0.6),
                            fontSize: isTablet ? 14 : 12)),
                          Text("$_perWeekPrice${PS.get('per_week', l)}", style: TextStyle(
                            color: Colors.white,
                            fontSize: isTablet ? 16 : 14,
                            fontWeight: FontWeight.w700)),
                        ]),
                      ])),

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

                    // ── Trial sub — some após primeiro pagamento ───────
                    FutureBuilder<bool>(
                      future: CreditsService.isPremium(),
                      builder: (_, snap) {
                        if (snap.data == true) return const SizedBox.shrink();
                        return Text(
                          PS.get('trial_sub', l).replaceAll('5,99', _price).replaceAll('5.99', _price),
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.black54,
                            fontSize: isTablet ? 15 : 13,
                            fontWeight: FontWeight.w500,
                            height: 1.5));
                      }),

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

  Widget _feat(String emoji, String label, bool isTablet) => Padding(
    padding: EdgeInsets.symmetric(vertical: isTablet ? 8 : 5),
    child: Row(children: [
      Text(emoji, style: TextStyle(fontSize: isTablet ? 22 : 17)),
      SizedBox(width: isTablet ? 16 : 12),
      Text(label, style: TextStyle(
        color: const Color(0xFF1C1C1E),
        fontSize: isTablet ? 16 : 14,
        fontWeight: FontWeight.w500)),
      const Spacer(),
      Icon(Icons.check_circle_rounded,
        color: const Color(0xFF34C759),
        size: isTablet ? 22 : 17),
    ]));

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