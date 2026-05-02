import 'package:flutter/material.dart';
import 'credits_service.dart';
import '../widgets/paywall_screen.dart';

/// Chama esta função antes de qualquer ação que consome crédito.
/// Se tiver créditos → executa [onAllowed]
/// Se não tiver → mostra paywall
Future<void> checkCreditsAndProceed({
  required BuildContext context,
  required Future<void> Function() onAllowed,
}) async {
  final canProceed = await CreditsService.useCredit();

  if (!context.mounted) return;

  if (canProceed) {
    await onAllowed();
  } else {
    // Sem créditos → mostra paywall
    await Navigator.push(
      context,
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (_) => const PaywallFlow(),
      ),
    );
  }
}

/// Badge de créditos — mostra quantos usos restam
/// Coloca na AppBar ou onde quiseres
class CreditsBadge extends StatefulWidget {
  const CreditsBadge({super.key});

  @override
  State<CreditsBadge> createState() => _CreditsBadgeState();
}

class _CreditsBadgeState extends State<CreditsBadge> {
  int _credits = 5;
  bool _isPremium = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final credits = await CreditsService.getCredits();
    final premium = await CreditsService.isPremium();
    if (mounted) setState(() { _credits = credits; _isPremium = premium; });
  }

  @override
  Widget build(BuildContext context) {
    if (_isPremium) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
              colors: [Color(0xFFFF2D55), Color(0xFFFF6B81)]),
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.diamond_rounded, color: Colors.white, size: 12),
            SizedBox(width: 4),
            Text("PRO", style: TextStyle(color: Colors.white, fontSize: 11,
                fontWeight: FontWeight.w800)),
          ],
        ),
      );
    }

    final color = _credits <= 1
        ? const Color(0xFFFF2D55)
        : _credits <= 3
            ? const Color(0xFFFF9500)
            : const Color(0xFF34C759);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.bolt_rounded, color: color, size: 13),
          const SizedBox(width: 3),
          Text("$_credits", style: TextStyle(color: color, fontSize: 12,
              fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}

/// Banner que aparece quando os créditos estão a acabar
class LowCreditsBar extends StatefulWidget {
  final VoidCallback? onUpgrade;
  const LowCreditsBar({super.key, this.onUpgrade});

  @override
  State<LowCreditsBar> createState() => _LowCreditsBarState();
}

class _LowCreditsBarState extends State<LowCreditsBar> {
  int _credits = 5;
  bool _isPremium = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final c = await CreditsService.getCredits();
    final p = await CreditsService.isPremium();
    if (mounted) setState(() { _credits = c; _isPremium = p; });
  }

  @override
  Widget build(BuildContext context) {
    if (_isPremium || _credits > 2) return const SizedBox.shrink();

    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTap: widget.onUpgrade ?? () => Navigator.push(context,
        MaterialPageRoute(fullscreenDialog: true,
            builder: (_) => const PaywallFlow())),
      child: Container(
        margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: const Color(0xFFFF2D55).withOpacity(0.08),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFFF2D55).withOpacity(0.25)),
        ),
        child: Row(children: [
          const Text("⚡", style: TextStyle(fontSize: 16)),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              _credits == 0
                  ? "Esgotaste os usos de hoje. Faz upgrade para continuar."
                  : "Último uso grátis de hoje. Faz upgrade para ilimitado.",
              style: TextStyle(
                color: isDark ? Colors.white : const Color(0xFF1C1C1E),
                fontSize: 13, fontWeight: FontWeight.w500),
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                  colors: [Color(0xFFFF2D55), Color(0xFFFF6B81)]),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Text("Premium",
                style: TextStyle(color: Colors.white, fontSize: 12,
                    fontWeight: FontWeight.w700)),
          ),
        ]),
      ),
    );
  }
}