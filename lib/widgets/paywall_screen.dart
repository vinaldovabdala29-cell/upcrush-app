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
  String _annualPrice = '';
  String _weeklyPrice = '';
  String _selectedPlan = 'annual';

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
    // NOTA: estes valores já NÃO alimentam a UI (preços agora fixos
    // em _planText/_belowButtonLines, ver comentário lá). Mantidos
    // aqui apenas para diagnóstico/uso futuro depois de resolvido
    // o problema de região da conta de teste (preço em dólar).
    RevenueCatService.getAnnualPrice().then((p) {
      if (mounted) setState(() => _annualPrice = p);
    });
    RevenueCatService.getWeeklyNoTrialPrice().then((p) {
      if (mounted) setState(() => _weeklyPrice = p);
    });
  }

  @override
  void dispose() {
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle.dark);
    super.dispose();
  }

  Future<void> _handlePurchase() async {
    setState(() => _loading = true);
    final result = await RevenueCatService.buyNewPlan(_selectedPlan);
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

  String _planText(String l, String key) {
    // Preços fixos visuais — não usam o valor devolvido pela API
    // do RevenueCat, para evitar mostrar moeda errada (ex: dólar
    // em vez de euro) quando a conta/região do utilizador de teste
    // está configurada incorretamente.
    const annualPrice = '34,99 €';
    const weeklyPrice = '6,99 €';

    String monthlyEquivalent() {
      switch (l) {
        case 'de': return '2,91 €/Mon';
        case 'es': return '2,91 €/mes';
        case 'pt': return '2,91 €/mês';
        case 'fr': return '2,91 €/mois';
        case 'it': return '2,91 €/mese';
        default: return '€2.91/mo';
      }
    }

    final m = {
      'pt': {'weekly':'SEMANAL','annual':'ANUAL','save':'ECONOMIZE 75%','month':monthlyEquivalent(),'annualPrice':'$annualPrice/ano','after':'após 3 dias grátis','old':'9,99 €/sem','week':'$weeklyPrice/sem'},
      'de': {'weekly':'WÖCHENTLICH','annual':'JÄHRLICH','save':'75% SPAREN','month':monthlyEquivalent(),'annualPrice':'$annualPrice/Jr','after':'nach 3 kostenlosen Tagen','old':'9,99 €/Wo','week':'$weeklyPrice/Wo'},
      'es': {'weekly':'SEMANAL','annual':'ANUAL','save':'AHORRA 75%','month':monthlyEquivalent(),'annualPrice':'$annualPrice/año','after':'después de 3 días gratis','old':'9,99 €/sem','week':'$weeklyPrice/sem'},
      'fr': {'weekly':'HEBDOMADAIRE','annual':'ANNUEL','save':'ÉCONOMISEZ 75%','month':monthlyEquivalent(),'annualPrice':'$annualPrice/an','after':'après 3 jours gratuits','old':'9,99 €/sem','week':'$weeklyPrice/sem'},
      'it': {'weekly':'SETTIMANALE','annual':'ANNUALE','save':'RISPARMIA IL 75%','month':monthlyEquivalent(),'annualPrice':'$annualPrice/anno','after':'dopo 3 giorni gratis','old':'9,99 €/sett','week':'$weeklyPrice/sett'},
      'en': {'weekly':'WEEKLY','annual':'ANNUAL','save':'SAVE 75%','month':monthlyEquivalent(),'annualPrice':'$annualPrice/yr','after':'after 3 free days','old':'€9.99/wk','week':'$weeklyPrice/wk'},
    };
    return (m[l] ?? m['en']!)[key]!;
  }

  String _noPaymentNow(String l) {
    switch (l) {
      case 'de': return 'Keine Zahlung jetzt';
      case 'es': return 'Sin pago ahora';
      case 'pt': return 'Sem pagamento agora';
      case 'fr': return 'Aucun paiement maintenant';
      case 'it': return 'Nessun pagamento ora';
      default: return 'No payment now';
    }
  }

  // Texto dinâmico por baixo do botão principal, consoante o plano
  // selecionado (anual vs semanal). Devolve 2 linhas para o plano
  // anual (garante que cabe mesmo em ecrãs pequenos como o iPhone SE).
  List<String> _belowButtonLines(String l) {
    // Mesmo raciocínio: preços fixos visuais, não vindos da API.
    const annualPrice = '34,99 €';
    const weeklyPrice = '6,99 €';

    if (_selectedPlan == 'annual') {
      switch (l) {
        case 'de': return ['3 Tage kostenlos, danach $annualPrice pro Jahr', 'Jederzeit kündbar'];
        case 'es': return ['3 días gratis, luego $annualPrice al año', 'Cancela cuando quieras'];
        case 'pt': return ['3 dias grátis, depois $annualPrice por ano', 'Cancele quando quiser'];
        case 'fr': return ['3 jours gratuits, puis $annualPrice par an', 'Annulable à tout moment'];
        case 'it': return ['3 giorni gratis, poi $annualPrice all’anno', 'Annulla quando vuoi'];
        default: return ['3 days free, then $annualPrice per year', 'Cancel anytime'];
      }
    } else {
      switch (l) {
        case 'de': return ['Abgerechnet $weeklyPrice pro Woche'];
        case 'es': return ['Se factura $weeklyPrice por semana'];
        case 'pt': return ['Cobrado $weeklyPrice por semana'];
        case 'fr': return ['Facturé $weeklyPrice par semaine'];
        case 'it': return ['Fatturato $weeklyPrice a settimana'];
        default: return ['Billed $weeklyPrice per week'];
      }
    }
  }

  String _ctaLabelDynamic(String l) {
    switch (l) {
      case 'de': return 'Weiter';
      case 'es': return 'Continuar';
      case 'pt': return 'Continuar';
      case 'fr': return 'Continuer';
      case 'it': return 'Continua';
      default: return 'Continue';
    }
  }

  List<String> _features(String l) {
    switch (l) {
      case 'de':
        return const [
          'Immer wissen, was du antworten kannst',
          'Nachrichten, die zu dir und zur Situation passen',
          'Sei unberechenbar. Nie langweilig.',
          'Gespräche, bei denen das Interesse von beiden Seiten kommt',
          'Du bleibst du selbst — du weißt nur besser, was du sagen sollst',
        ];
      case 'es':
        return const [
          'Saber siempre qué responder',
          'Mensajes que encajan contigo y con la situación',
          'Sé impredecible. Nunca aburrido.',
          'Conversaciones donde el interés viene de ambos lados',
          'Sigues siendo tú, solo que sabes mejor qué decir',
        ];
      case 'pt':
        return const [
          'Sempre saiba o que responder',
          'Mensagens que combinam com você e com a situação',
          'Seja imprevisível. Nunca monótono.',
          'Conversas em que o interesse vem dos dois lados',
          'Você continua sendo você, só sabe melhor o que dizer',
        ];
      case 'fr':
        return const [
          'Toujours savoir quoi répondre',
          'Des messages adaptés à toi et à la situation',
          'Sois imprévisible. Jamais monotone.',
          'Des conversations où l’intérêt vient des deux côtés',
          'Tu restes toi-même, tu sais juste mieux quoi dire',
        ];
      case 'it':
        return const [
          'Sapere sempre cosa rispondere',
          'Messaggi adatti a te e alla situazione',
          'Sii imprevedibile. Mai monotono.',
          'Conversazioni in cui l’interesse arriva da entrambe le parti',
          'Resti sempre te stesso, solo che sai meglio cosa dire',
        ];
      default:
        return const [
          'Always know what to reply',
          'Messages that fit you and the situation',
          'Be unpredictable. Never boring.',
          'Conversations where the interest goes both ways',
          'You\u2019re still you — you just know what to say better',
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
              child: Center(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                    const SizedBox(height: 28),

                    // Headline — tamanho reduzido de 32 para 26
                    Text(
                      _headline(l),
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: _text,
                        fontSize: 26,
                        height: 1.08,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -1.0,
                      ),
                    ),

                    const SizedBox(height: 12),

                    // Subheadline — cor alterada para preto (_text)
                    Text(
                      _subHeadline(l),
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: _text,
                        fontSize: 17,
                        height: 1.45,
                        fontWeight: FontWeight.w500,
                      ),
                    ),

                    const SizedBox(height: 24),

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
                                // Barra vertical — cor verde
                                Container(
                                  width: 3,
                                  height: 24,
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF22C55E),
                                    borderRadius: BorderRadius.circular(99),
                                  ),
                                ),
                                const SizedBox(width: 9),

                                // Check simples em verde
                                const SizedBox(
                                  width: 24,
                                  height: 24,
                                  child: Icon(
                                    Icons.check_rounded,
                                    color: Color(0xFF22C55E),
                                    size: 22,
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

                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(child: Stack(
                          clipBehavior: Clip.none,
                          alignment: Alignment.topCenter,
                          children: [
                            _planCard(
                              selected: _selectedPlan == 'annual',
                              onTap: () => setState(() => _selectedPlan = 'annual'),
                              topPadding: 19,
                              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                Row(children: [
                                  Expanded(child: Text(_planText(l,'annual'), style: const TextStyle(fontSize:12,fontWeight:FontWeight.w900))),
                                  Text(_planText(l,'month'), style: const TextStyle(color:_muted,fontSize:10.5,fontWeight:FontWeight.w700)),
                                ]),
                                const SizedBox(height:9),
                                Text(_planText(l,'annualPrice'), style: const TextStyle(fontSize:16,fontWeight:FontWeight.w900)),
                                const SizedBox(height:2),
                                Text(_planText(l,'after'), style: const TextStyle(color:_muted,fontSize:10.5,fontWeight:FontWeight.w600)),
                              ]),
                            ),
                            Positioned(top:-10, child: Container(
                              padding: const EdgeInsets.symmetric(horizontal:10,vertical:4),
                              decoration: BoxDecoration(color:const Color(0xFF6C63FF),borderRadius:BorderRadius.circular(999)),
                              child: Text(_planText(l,'save'), style: const TextStyle(color:Colors.white,fontSize:10,fontWeight:FontWeight.w900)),
                            )),
                          ],
                        )),

                        const SizedBox(width:12),
                        Expanded(child: _planCard(
                          selected: _selectedPlan == 'weekly',
                          onTap: () => setState(() => _selectedPlan = 'weekly'),
                          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            Text(_planText(l,'weekly'), style: const TextStyle(fontSize:12,fontWeight:FontWeight.w900)),
                            const SizedBox(height:10),
                            Text(_planText(l,'old'), style: const TextStyle(color:_muted,fontSize:12,decoration:TextDecoration.lineThrough)),
                            const SizedBox(height:2),
                            Text(_planText(l,'week'), style: const TextStyle(fontSize:16,fontWeight:FontWeight.w900)),
                          ]),
                        )),

                      ],
                    ),

                    const SizedBox(height: 14),

                    Column(
                      children: _belowButtonLines(l).map((line) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 2),
                          child: Text(
                            line,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: Color(0xFF66666D),
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        );
                      }).toList(),
                    ),

                    const SizedBox(height: 10),

                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton(
                        onPressed: _loading ? null : _handlePurchase,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _text,
                          foregroundColor: Colors.white,
                          disabledBackgroundColor: _text.withOpacity(0.35),
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(26),
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
                                _ctaLabelDynamic(l),
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                      ),
                    ),

                    const SizedBox(height: 16),

                    Wrap(
                      alignment: WrapAlignment.center,
                      spacing: 14,
                      runSpacing: 8,
                      children: [
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
          ),
        );
      },
    );
  }

  Widget _planCard({
    required bool selected,
    required VoidCallback onTap,
    required Widget child,
    double topPadding = 15,
  }) => GestureDetector(
    onTap: onTap,
    child: Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(13, topPadding, 13, 13),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: selected ? const Color(0xFF6C63FF) : const Color(0xFFE3E3E8),
          width: selected ? 2 : 1.2,
        ),
      ),
      child: child,
    ),
  );

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