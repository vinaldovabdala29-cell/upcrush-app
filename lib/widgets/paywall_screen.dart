import 'dart:io';
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
  int _step = 0;
  void _next() { if (_step < 2) setState(() => _step++); }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder(
      valueListenable: appLangNotifier,
      builder: (_, lang, __) {
        final l = lang.languageCode;
        return AnimatedSwitcher(
          duration: const Duration(milliseconds: 400),
          transitionBuilder: (child, anim) => FadeTransition(
            opacity: anim,
            child: SlideTransition(
              position: Tween<Offset>(begin: const Offset(0.06, 0), end: Offset.zero)
                  .animate(CurvedAnimation(parent: anim, curve: Curves.easeOutCubic)),
              child: child,
            ),
          ),
          child: switch (_step) {
            0 => _PaywallSlide(key: const ValueKey(0), step: 0, totalSteps: 2,
                headline: PS.get('h1', l), subline: PS.get('s1', l),
                visual: _ConversationPreview(lang: l), onContinue: _next),
            1 => _PaywallSlide(key: const ValueKey(1), step: 1, totalSteps: 2,
                headline: PS.get('h2', l), subline: PS.get('s2', l),
                visual: _CoachPreview(lang: l), onContinue: _next),
            _ => _PaywallPlans(key: const ValueKey(2), onClose: () => Navigator.pop(context)),
          },
        );
      },
    );
  }
}

class _PaywallSlide extends StatelessWidget {
  final int step, totalSteps;
  final String headline, subline;
  final Widget visual;
  final VoidCallback onContinue;
  const _PaywallSlide({required this.step, required this.totalSteps,
      required this.headline, required this.subline,
      required this.visual, required this.onContinue, super.key});

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).padding.bottom;
    return ValueListenableBuilder(
      valueListenable: appLangNotifier,
      builder: (_, lang, __) {
        final l = lang.languageCode;
        return Scaffold(
          backgroundColor: const Color(0xFF08080F),
          body: Column(children: [
            Expanded(flex: 6, child: Stack(children: [
              Container(decoration: const BoxDecoration(
                gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter,
                  colors: [Color(0xFF1A0510), Color(0xFF08080F)]))),
              Positioned(top: -60, left: -40, child: Container(width: 260, height: 260,
                decoration: BoxDecoration(shape: BoxShape.circle,
                  color: const Color(0xFFFF2D55).withOpacity(0.12)))),
              Positioned(top: -40, right: -60, child: Container(width: 200, height: 200,
                decoration: BoxDecoration(shape: BoxShape.circle,
                  color: const Color(0xFF5856D6).withOpacity(0.1)))),
              SafeArea(bottom: false, child: Padding(
                padding: const EdgeInsets.fromLTRB(28, 16, 28, 0),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                    Row(children: List.generate(totalSteps, (i) => AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      margin: const EdgeInsets.only(right: 6),
                      width: i == step ? 22 : 7, height: 7,
                      decoration: BoxDecoration(
                        color: i == step ? const Color(0xFFFF2D55) : Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(4))))),
                    GestureDetector(onTap: () => Navigator.pop(context),
                      child: Container(width: 30, height: 30,
                        decoration: BoxDecoration(color: Colors.white.withOpacity(0.08), shape: BoxShape.circle),
                        child: const Icon(Icons.close, color: Colors.white38, size: 16))),
                  ]),
                  const SizedBox(height: 36),
                  Text(headline, style: const TextStyle(color: Colors.white, fontSize: 38,
                    fontWeight: FontWeight.w900, letterSpacing: -1.2, height: 1.05)),
                  const SizedBox(height: 12),
                  Text(subline, style: TextStyle(color: Colors.white.withOpacity(0.45), fontSize: 15, height: 1.4)),
                  const SizedBox(height: 32),
                  Expanded(child: visual),
                ]),
              )),
            ])),
            Container(color: const Color(0xFF08080F),
              padding: EdgeInsets.fromLTRB(24, 20, 24, bottom + 20),
              child: Column(children: [
                Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                  Container(width: 16, height: 16,
                    decoration: const BoxDecoration(color: Color(0xFF34C759), shape: BoxShape.circle),
                    child: const Icon(Icons.check, color: Colors.white, size: 11)),
                  const SizedBox(width: 8),
                  Text(PS.get('no_payment', l),
                    style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 13)),
                ]),
                const SizedBox(height: 14),
                SizedBox(width: double.infinity, height: 56,
                  child: ElevatedButton(
                    onPressed: onContinue,
                    style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFFF2D55),
                      foregroundColor: Colors.white, elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
                    child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                      Text(step < totalSteps - 1 ? PS.get('continue_btn', l) : PS.get('see_plans', l),
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
                      const SizedBox(width: 8),
                      const Icon(Icons.arrow_forward_rounded, size: 18),
                    ]),
                  )),
                const SizedBox(height: 10),
                _LinksRow(),
              ]),
            ),
          ]),
        );
      },
    );
  }
}

class _ConversationPreview extends StatelessWidget {
  final String lang;
  const _ConversationPreview({required this.lang});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(color: Colors.white.withOpacity(0.04),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.07))),
      padding: const EdgeInsets.all(18),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Container(width: 36, height: 36,
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [Color(0xFFFF9500), Color(0xFFFFCC02)]),
              borderRadius: BorderRadius.circular(12)),
            child: const Icon(Icons.person_rounded, color: Colors.white, size: 20)),
          const SizedBox(width: 10),
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text("Sara", style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w700)),
            Row(children: [
              Container(width: 6, height: 6, decoration: const BoxDecoration(color: Color(0xFF34C759), shape: BoxShape.circle)),
              const SizedBox(width: 5),
              Text(PS.get('online', lang), style: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 11)),
            ]),
          ]),
        ]),
        const SizedBox(height: 16),
        Align(alignment: Alignment.centerLeft, child: _bubble(PS.get('bubble1', lang), isMe: false)),
        const SizedBox(height: 6),
        Align(alignment: Alignment.centerRight, child: _bubble(PS.get('bubble2', lang), isMe: true)),
        const SizedBox(height: 6),
        Align(alignment: Alignment.centerLeft, child: _bubble(PS.get('bubble3', lang), isMe: false)),
        const SizedBox(height: 6),
        Align(alignment: Alignment.centerRight, child: _bubble(PS.get('bubble4', lang), isMe: true, isAI: true)),
        const Spacer(),
        Center(child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: const Color(0xFFFF2D55).withOpacity(0.12),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFFFF2D55).withOpacity(0.25))),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            const Icon(Icons.auto_awesome_rounded, color: Color(0xFFFF2D55), size: 13),
            const SizedBox(width: 6),
            Text(PS.get('generated', lang),
              style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 12, fontWeight: FontWeight.w500)),
          ]),
        )),
      ]),
    );
  }

  Widget _bubble(String text, {required bool isMe, bool isAI = false}) => Container(
    constraints: const BoxConstraints(maxWidth: 240),
    padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 9),
    decoration: BoxDecoration(
      gradient: isAI ? const LinearGradient(colors: [Color(0xFFFF2D55), Color(0xFFFF6B81)],
        begin: Alignment.topLeft, end: Alignment.bottomRight) : null,
      color: isAI ? null : (isMe ? Colors.white.withOpacity(0.12) : Colors.white.withOpacity(0.08)),
      borderRadius: BorderRadius.only(
        topLeft: const Radius.circular(14), topRight: const Radius.circular(14),
        bottomLeft: Radius.circular(isMe ? 14 : 4), bottomRight: Radius.circular(isMe ? 4 : 14)),
      boxShadow: isAI ? [BoxShadow(color: const Color(0xFFFF2D55).withOpacity(0.3), blurRadius: 10, offset: const Offset(0, 4))] : []),
    child: Text(text, style: TextStyle(color: Colors.white, fontSize: 13,
      fontWeight: isAI ? FontWeight.w500 : FontWeight.w400)),
  );
}

class _CoachPreview extends StatelessWidget {
  final String lang;
  const _CoachPreview({required this.lang});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(color: Colors.white.withOpacity(0.04),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.07))),
      padding: const EdgeInsets.all(20),
      child: Column(children: [
        Row(children: [
          Container(width: 36, height: 36,
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [Color(0xFFFF2D55), Color(0xFFFF6B81)]),
              borderRadius: BorderRadius.circular(12),
              boxShadow: [BoxShadow(color: const Color(0xFFFF2D55).withOpacity(0.4), blurRadius: 10, offset: const Offset(0, 3))]),
            child: const Icon(Icons.auto_awesome_rounded, color: Colors.white, size: 18)),
          const SizedBox(width: 10),
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text("UpCrush AI", style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w700)),
            Text(PS.get('coach_label', lang), style: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 11)),
          ]),
        ]),
        const SizedBox(height: 20),
        Align(alignment: Alignment.centerRight,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(color: Colors.white.withOpacity(0.09),
              borderRadius: const BorderRadius.only(topLeft: Radius.circular(16),
                topRight: Radius.circular(16), bottomLeft: Radius.circular(16))),
            child: Text(PS.get('coach_q', lang), style: const TextStyle(color: Colors.white, fontSize: 14)))),
        const SizedBox(height: 8),
        Align(alignment: Alignment.centerLeft,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: [
                const Color(0xFFFF2D55).withOpacity(0.15),
                const Color(0xFF5856D6).withOpacity(0.12)]),
              borderRadius: const BorderRadius.only(topRight: Radius.circular(16),
                bottomLeft: Radius.circular(16), bottomRight: Radius.circular(16)),
              border: Border.all(color: const Color(0xFFFF2D55).withOpacity(0.2))),
            child: Text(PS.get('coach_a', lang), style: const TextStyle(color: Colors.white, fontSize: 13, height: 1.45)))),
        const Spacer(),
        Row(children: [
          _stat("2.4k", PS.get('convos', lang)),
          const SizedBox(width: 10),
          _stat("94%", PS.get('reply_rate', lang)),
          const SizedBox(width: 10),
          _stat("24/7", PS.get('always_on', lang)),
        ]),
      ]),
    );
  }

  Widget _stat(String value, String label) => Expanded(
    child: Container(
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(color: Colors.white.withOpacity(0.05), borderRadius: BorderRadius.circular(12)),
      child: Column(children: [
        Text(value, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w800)),
        const SizedBox(height: 3),
        Text(label, textAlign: TextAlign.center,
          style: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 10, height: 1.3)),
      ]),
    ));
}

class _PaywallPlans extends StatefulWidget {
  final VoidCallback onClose;
  const _PaywallPlans({required this.onClose, super.key});
  @override
  State<_PaywallPlans> createState() => _PaywallPlansState();
}

class _PaywallPlansState extends State<_PaywallPlans> {
  bool _loading = false;

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
    final bottom = MediaQuery.of(context).padding.bottom;
    return ValueListenableBuilder(
      valueListenable: appLangNotifier,
      builder: (_, lang, __) {
        final l = lang.languageCode;
        return Scaffold(
          backgroundColor: const Color(0xFF08080F),
          body: Stack(children: [
            Positioned(top: -80, right: -60, child: Container(width: 260, height: 260,
              decoration: BoxDecoration(shape: BoxShape.circle,
                color: const Color(0xFFFF2D55).withOpacity(0.08)))),
            SafeArea(child: Column(children: [
              Align(alignment: Alignment.topRight,
                child: Padding(padding: const EdgeInsets.fromLTRB(0, 12, 16, 0),
                  child: GestureDetector(onTap: widget.onClose,
                    child: Container(width: 30, height: 30,
                      decoration: BoxDecoration(color: Colors.white.withOpacity(0.08), shape: BoxShape.circle),
                      child: const Icon(Icons.close, color: Colors.white38, size: 16))))),
              Padding(padding: const EdgeInsets.fromLTRB(24, 8, 24, 0),
                child: Column(children: [
                  Container(padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(colors: [Color(0xFFFF2D55), Color(0xFFFF6B81)]),
                      borderRadius: BorderRadius.circular(20)),
                    child: const Text("✦ PREMIUM", style: TextStyle(color: Colors.white, fontSize: 11,
                      fontWeight: FontWeight.w800, letterSpacing: 1.5))),
                  const SizedBox(height: 14),
                  Text(PS.get('plans_title', l), textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.white, fontSize: 26,
                      fontWeight: FontWeight.w900, letterSpacing: -0.8, height: 1.15)),
                  const SizedBox(height: 6),
                  Text(PS.get('plans_sub', l), textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 13)),
                ])),
              const SizedBox(height: 20),
              Padding(padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                  decoration: BoxDecoration(color: Colors.white.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: Colors.white.withOpacity(0.07))),
                  child: Column(children: [
                    _feat("📸", PS.get('feat1', l)),
                    _feat("❤️", PS.get('feat2', l)),
                    _feat("🤖", PS.get('feat3', l)),
                    _feat("⚡", PS.get('feat4', l)),
                  ]))),
              const SizedBox(height: 20),
              Padding(padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 24),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(colors: [Color(0xFFFF2D55), Color(0xFFFF6B81)],
                      begin: Alignment.topLeft, end: Alignment.bottomRight),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [BoxShadow(color: const Color(0xFFFF2D55).withOpacity(0.45),
                      blurRadius: 24, offset: const Offset(0, 10))]),
                  child: Row(children: [
                    Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(8)),
                        child: Text(PS.get('free_days', l), style: const TextStyle(color: Colors.white,
                          fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 0.8))),
                      const SizedBox(height: 10),
                      Text(PS.get('weekly', l), style: const TextStyle(color: Colors.white70, fontSize: 14, fontWeight: FontWeight.w500)),
                      Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
                        Text(Platform.isIOS ? "€9.99" : "€6.99", style: const TextStyle(color: Colors.white, fontSize: 40,
                          fontWeight: FontWeight.w900, letterSpacing: -1)),
                        const SizedBox(width: 4),
                        Padding(padding: const EdgeInsets.only(bottom: 6),
                          child: Text(PS.get('per_week', l), style: const TextStyle(color: Colors.white60, fontSize: 14))),
                      ]),
                    ]),
                    const Spacer(),
                    Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                      Text(PS.get('today', l), style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 12)),
                      const Text("€0.00", style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w800)),
                      const SizedBox(height: 8),
                      Text(PS.get('after_trial', l), style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 12)),
                      Text("${Platform.isIOS ? '€9.99' : '€6.99'}${PS.get('per_week', l)}", style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w700)),
                    ]),
                  ]))),
              const Spacer(),
              Padding(padding: EdgeInsets.fromLTRB(24, 0, 24, bottom + 16),
                child: Column(children: [
                  Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                    Container(width: 16, height: 16,
                      decoration: const BoxDecoration(color: Color(0xFF34C759), shape: BoxShape.circle),
                      child: const Icon(Icons.check, color: Colors.white, size: 11)),
                    const SizedBox(width: 8),
                    Text(PS.get('no_payment', l), style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 13)),
                  ]),
                  const SizedBox(height: 12),
                  SizedBox(width: double.infinity, height: 56,
                    child: ElevatedButton(
                      onPressed: _loading ? null : _handlePurchase,
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.white,
                        foregroundColor: const Color(0xFF1C1C1E),
                        surfaceTintColor: Colors.transparent,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        elevation: 0),
                      child: _loading
                        ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2))
                        : Text(PS.get('trial', l), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
                    )),
                  const SizedBox(height: 8),
                  Text(Platform.isIOS ? PS.get('trial_sub', l) : PS.get('trial_sub', l).replaceAll('9,99', '6,99').replaceAll('9.99', '6.99'), textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.white.withOpacity(0.25), fontSize: 11)),
                  const SizedBox(height: 8),
                  Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                    _link("Terms", () => _openUrl('https://sites.google.com/view/upcrush-terms/p%C3%A1gina-inicial')),
                    _sep(),
                    _link("Privacy", () => _openUrl('https://sites.google.com/view/upcrush-privacy-policy/p%C3%A1gina-inicial')),
                  ]),
                ])),
            ])),
          ]),
        );
      },
    );
  }

  Widget _feat(String emoji, String label) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 5),
    child: Row(children: [
      Text(emoji, style: const TextStyle(fontSize: 17)),
      const SizedBox(width: 12),
      Text(label, style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w500)),
      const Spacer(),
      const Icon(Icons.check_circle_rounded, color: Color(0xFF34C759), size: 17),
    ]));

  Widget _link(String t, VoidCallback onTap) => GestureDetector(onTap: onTap,
    child: Text(t, style: TextStyle(color: Colors.white.withOpacity(0.25), fontSize: 11,
      decoration: TextDecoration.underline, decorationColor: Colors.white.withOpacity(0.2))));
  Widget _sep() => Text("  ·  ", style: TextStyle(color: Colors.white.withOpacity(0.15), fontSize: 11));
}

class _LinksRow extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Row(mainAxisAlignment: MainAxisAlignment.center, children: [
      _link("Terms", () => _openUrl('https://sites.google.com/view/upcrush-terms/p%C3%A1gina-inicial')),
      _sep(),
      _link("Privacy", () => _openUrl('https://sites.google.com/view/upcrush-privacy-policy/p%C3%A1gina-inicial')),
    ]);
  }
  Widget _link(String t, VoidCallback onTap) => GestureDetector(onTap: onTap,
    child: Text(t, style: TextStyle(color: Colors.white.withOpacity(0.25), fontSize: 11,
      decoration: TextDecoration.underline, decorationColor: Colors.white.withOpacity(0.2))));
  Widget _sep() => Text("  ·  ", style: TextStyle(color: Colors.white.withOpacity(0.15), fontSize: 11));
}