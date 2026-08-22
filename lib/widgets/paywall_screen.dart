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

  static const _bg = Color(0xFFFFFFFF);
  static const _text = Color(0xFF0A0A0A);
  static const _muted = Color(0xFF6B6B70);
  static const _soft = Color(0xFFF5F5F7);

  @override
  void initState() {
    super.initState();
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle.dark);
    RevenueCatService.getPrice().then((p) {
      if (mounted) setState(() => _price = p);
    });
  }

  @override
  void dispose() {
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle.dark);
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
      case 'de': return 'Bereit, anders zu schreiben?';
      case 'es': return '¿Listo para conversar de otra manera?';
      case 'pt': return 'Pronto para conversar de um jeito diferente?';
      case 'fr': return 'Prêt à écrire autrement ?';
      case 'it': return 'Pronto a scrivere in modo diverso?';
      default: return 'Ready to text differently?';
    }
  }

  String _subHeadline(String l) {
    switch (l) {
      case 'de': return 'Mach aus Unsicherheit echte Sicherheit in deinen Gesprächen.';
      case 'es': return 'Convierte la inseguridad en confianza en tus conversaciones.';
      case 'pt': return 'Transforme a insegurança em confiança nas suas conversas.';
      case 'fr': return 'Transforme l’hésitation en confiance dans tes conversations.';
      case 'it': return 'Trasforma l’insicurezza in sicurezza nelle tue conversazioni.';
      default: return 'Turn uncertainty into confidence in your conversations.';
    }
  }

  String _ctaLabel(String l) {
    switch (l) {
      case 'de': return 'Kostenlos testen';
      case 'es': return 'Probar gratis';
      case 'pt': return 'Experimentar grátis';
      case 'fr': return 'Essayer gratuitement';
      case 'it': return 'Prova gratis';
      default: return 'Try for free';
    }
  }

  String _todayFree(String l) {
    switch (l) {
      case 'de': return 'Heute zahlst du nichts.';
      case 'es': return 'Hoy no pagas nada.';
      case 'pt': return 'Hoje você não paga nada.';
      case 'fr': return 'Aujourd’hui, tu ne paies rien.';
      case 'it': return 'Oggi non paghi nulla.';
      default: return 'You pay nothing today.';
    }
  }

  String _trialBadge(String l) {
    switch (l) {
      case 'de': return '3 TAGE KOSTENLOS';
      case 'es': return '3 DÍAS GRATIS';
      case 'pt': return '3 DIAS GRÁTIS';
      case 'fr': return '3 JOURS GRATUITS';
      case 'it': return '3 GIORNI GRATIS';
      default: return '3 DAYS FREE';
    }
  }

  String _trialLine(String l) {
    final price = _price.isEmpty ? '—' : _price;
    switch (l) {
      case 'de': return '0,00 € heute · danach 6,99 €/Woche';
      case 'es': return '0,00 € hoy · después 6,99 €/semana';
      case 'pt': return '0,00 € hoje · depois 6,99 €/semana';
      case 'fr': return '0,00 € aujourd’hui · puis 6,99 €/semaine';
      case 'it': return '0,00 € oggi · poi 6,99 €/settimana';
      default: return '0.00 today · then €6.99/week';
    }
  }

  String _cancelLine(String l) {
    switch (l) {
      case 'de': return 'Jederzeit kündbar.';
      case 'es': return 'Cancela cuando quieras.';
      case 'pt': return 'Cancele quando quiser.';
      case 'fr': return 'Annulable à tout moment.';
      case 'it': return 'Annulla quando vuoi.';
      default: return 'Cancel anytime.';
    }
  }

  String _restore(String l) {
    switch (l) {
      case 'de': return 'Wiederherstellen';
      case 'es': return 'Restaurar';
      case 'pt': return 'Restaurar compras';
      case 'fr': return 'Restaurer';
      case 'it': return 'Ripristina';
      default: return 'Restore';
    }
  }

  String _terms(String l) {
    switch (l) {
      case 'de': return 'Bedingungen';
      case 'es': return 'Términos';
      case 'pt': return 'Termos';
      case 'fr': return 'Conditions';
      case 'it': return 'Termini';
      default: return 'Terms';
    }
  }

  String _privacy(String l) {
    switch (l) {
      case 'de': return 'Datenschutz';
      case 'es': return 'Privacidad';
      case 'pt': return 'Privacidade';
      case 'fr': return 'Confidentialité';
      case 'it': return 'Privacy';
      default: return 'Privacy';
    }
  }

  List<String> _features(String l) {
    switch (l) {
      case 'de':
        return const [
          'Immer wissen, was du antworten kannst',
          'Nachrichten, die zu dir und zur Situation passen',
          'Mehr Chemie in deinen Gesprächen',
          'Gespräche, bei denen das Interesse von beiden Seiten kommt',
        ];
      case 'es':
        return const [
          'Saber siempre qué responder',
          'Mensajes que encajan contigo y con la situación',
          'Crear más química en tus conversaciones',
          'Conversaciones donde el interés viene de ambos lados',
        ];
      case 'pt':
        return const [
          'Sempre saiba o que responder',
          'Mensagens que combinam com você e com a situação',
          'Crie mais química nas suas conversas',
          'Conversas em que o interesse vem dos dois lados',
        ];
      case 'fr':
        return const [
          'Toujours savoir quoi répondre',
          'Des messages adaptés à toi et à la situation',
          'Créer plus de complicité dans tes conversations',
          'Des conversations où l’intérêt vient des deux côtés',
        ];
      case 'it':
        return const [
          'Sapere sempre cosa rispondere',
          'Messaggi adatti a te e alla situazione',
          'Creare più chimica nelle conversazioni',
          'Conversazioni in cui l’interesse arriva da entrambe le parti',
        ];
      default:
        return const [
          'Always know what to reply',
          'Messages that fit you and the situation',
          'Create more chemistry in your conversations',
          'Conversations where the interest goes both ways',
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
        final features = _features(l);

        return Scaffold(
          backgroundColor: _bg,
          body: SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Column(
                  children: [
                    const SizedBox(height: 28),

                    Text(
                      _headline(l),
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: _text,
                        fontSize: 32,
                        height: 1.08,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -1.0,
                      ),
                    ),

                    const SizedBox(height: 12),

                    Text(
                      _subHeadline(l),
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: _muted,
                        fontSize: 17,
                        height: 1.45,
                        fontWeight: FontWeight.w500,
                      ),
                    ),

                    const SizedBox(height: 30),

                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.fromLTRB(18, 20, 18, 6),
                      decoration: BoxDecoration(
                        color: _soft,
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: Column(
                        children: features.map((feature) {
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 14),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  width: 24,
                                  height: 24,
                                  decoration: const BoxDecoration(
                                    color: _text,
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.check_rounded,
                                    color: Colors.white,
                                    size: 16,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    feature,
                                    style: const TextStyle(
                                      color: _text,
                                      fontSize: 16,
                                      height: 1.35,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                      ),
                    ),

                    const SizedBox(height: 26),

                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.fromLTRB(20, 18, 20, 18),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(22),
                        border: Border.all(
                          color: const Color(0xFFE3E3E8),
                          width: 1.2,
                        ),
                      ),
                      child: Column(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 7,
                            ),
                            decoration: BoxDecoration(
                              color: _text,
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: Text(
                              _trialBadge(l),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                          const SizedBox(height: 14),
                          Text(
                            _trialLine(l),
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: _text,
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            _cancelLine(l),
                            style: const TextStyle(
                              color: _muted,
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 18),

                    SizedBox(
                      width: double.infinity,
                      height: 60,
                      child: ElevatedButton(
                        onPressed: _loading ? null : _handlePurchase,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _text,
                          foregroundColor: Colors.white,
                          disabledBackgroundColor: _text.withOpacity(0.35),
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                        ),
                        child: _loading
                            ? const SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
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

                    Text(
                      _todayFree(l),
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: _muted,
                        fontSize: 13.5,
                        fontWeight: FontWeight.w600,
                      ),
                    ),

                    const SizedBox(height: 18),

                    Wrap(
                      alignment: WrapAlignment.center,
                      spacing: 14,
                      runSpacing: 8,
                      children: [
                        _link(_restore(l), _handleRestore),
                        _link(
                          _terms(l),
                          () => _openUrl(
                            'https://sites.google.com/view/upcrush-terms/p%C3%A1gina-inicial',
                          ),
                        ),
                        _link(
                          _privacy(l),
                          () => _openUrl(
                            'https://sites.google.com/view/upcrush-privacy-policy/p%C3%A1gina-inicial',
                          ),
                        ),
                      ],
                    ),

                    SizedBox(height: bottom + 18),
                  ],
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
        child: Text(
          t,
          style: const TextStyle(
            color: _muted,
            fontSize: 12.5,
            fontWeight: FontWeight.w600,
            decoration: TextDecoration.underline,
          ),
        ),
      );

}