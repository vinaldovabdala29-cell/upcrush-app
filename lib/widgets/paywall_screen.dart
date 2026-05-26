import 'package:flutter/material.dart';
import '../../../main.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/revenue_cat_service.dart';
import '../services/credits_service.dart';


// ── Função global de textos do paywall ───────────────────────────────────────
String _paywallText(String code, String key) {
  const Map<String, Map<String, String>> texts = {
    'no_payment': {
      'de': 'Keine Zahlung jetzt', 'es': 'Sin pago ahora', 'fr': 'Pas de paiement maintenant',
      'it': 'Nessun pagamento ora', 'tr': 'Şimdi ödeme yok', 'pl': 'Brak płatności teraz',
      'ru': 'Без оплаты сейчас', 'ar': 'لا دفع الآن', 'en': 'No payment now', 'pt': 'Sem pagamento agora',
    },
    'trial': {
      'de': '3 Tage kostenlos testen →', 'es': 'Probar gratis 3 días →', 'fr': 'Essayer gratuitement 3 jours →',
      'it': 'Prova gratis 3 giorni →', 'tr': '3 gün ücretsiz dene →', 'pl': 'Wypróbuj za darmo 3 dni →',
      'ru': 'Попробовать 3 дня бесплатно →', 'ar': 'جرب مجاناً 3 أيام →', 'en': 'Try free for 3 days →', 'pt': 'Experimentar grátis 3 dias →',
    },
    'trial_sub': {
      'de': '3 Tage kostenlos, dann €6,99/Woche. Jederzeit kündbar.', 'es': '3 días gratis, luego €6,99/sem. Cancela cuando quieras.',
      'fr': '3 jours gratuits, puis €6,99/semaine. Annulable à tout moment.', 'it': '3 giorni gratis, poi €6,99/settimana.',
      'tr': '3 gün ücretsiz, sonra €6,99/hafta.', 'pl': '3 dni za darmo, potem €6,99/tydzień.',
      'ru': '3 дня бесплатно, затем €6,99/неделю.', 'ar': '3 أيام مجاناً، ثم €6.99 أسبوعياً.',
      'en': '3 days free, then €6.99/week. Cancel anytime.', 'pt': '3 dias grátis, depois €6.99/sem. Cancela quando quiseres.',
    },
    'plans_title': {
      'de': 'Bereit für\nmehr Dates?', 'es': '¿Listo para\nmás citas?', 'fr': 'Prêt pour\nplus de dates?',
      'it': 'Pronto per\npiù appuntamenti?', 'tr': 'Daha fazla randevu\niçin hazır mısın?',
      'pl': 'Gotowy na\nwięcej randek?', 'ru': 'Готов к\nбольшему числу свиданий?',
      'ar': 'مستعد لمزيد\nمن المواعيد؟', 'en': 'Ready for\nmore dates?', 'pt': 'Pronto para\nconseguir mais datas?',
    },
    'plans_sub': {
      'de': 'Keine Verpflichtung. Jederzeit kündbar.', 'es': 'Sin compromiso. Cancela cuando quieras.',
      'fr': 'Sans engagement. Annulable à tout moment.', 'it': 'Senza impegno. Cancella quando vuoi.',
      'tr': 'Taahhüt yok. İstediğinde iptal et.', 'pl': 'Bez zobowiązań. Anuluj kiedy chcesz.',
      'ru': 'Без обязательств. Отмени когда угодно.', 'ar': 'بدون التزام. ألغِ متى تشاء.',
      'en': 'No commitment. Cancel anytime.', 'pt': 'Sem compromisso. Cancela quando quiseres.',
    },
    'feat1': {
      'de': 'Unbegrenzte Screenshots', 'es': 'Screenshots ilimitados', 'fr': 'Screenshots illimités',
      'it': 'Screenshot illimitati', 'tr': 'Sınırsız ekran görüntüsü', 'pl': 'Nieograniczone zrzuty ekranu',
      'ru': 'Неограниченные скриншоты', 'ar': 'لقطات شاشة غير محدودة', 'en': 'Unlimited screenshots', 'pt': 'Screenshots ilimitados',
    },
    'feat2': {
      'de': 'Unbegrenzte Opener', 'es': 'Openers ilimitados', 'fr': 'Openers illimités',
      'it': 'Opener illimitati', 'tr': 'Sınırsız açılış mesajı', 'pl': 'Nieograniczone openers',
      'ru': 'Неограниченные опенеры', 'ar': 'رسائل افتتاحية غير محدودة', 'en': 'Unlimited openers', 'pt': 'Openers ilimitados',
    },
    'feat3': {
      'de': 'Chatbot AI ohne Limits', 'es': 'Chatbot AI sin límites', 'fr': 'Chatbot AI sans limites',
      'it': 'Chatbot AI senza limiti', 'tr': 'Sınırsız AI chatbot', 'pl': 'Chatbot AI bez limitów',
      'ru': 'Чатбот AI без ограничений', 'ar': 'روبوت دردشة AI بلا حدود', 'en': 'Unlimited AI chatbot', 'pt': 'Chatbot AI sem limites',
    },
    'feat4': {
      'de': 'Sofortige Antworten', 'es': 'Respuestas instantáneas', 'fr': 'Réponses instantanées',
      'it': 'Risposte istantanee', 'tr': 'Anında yanıtlar', 'pl': 'Natychmiastowe odpowiedzi',
      'ru': 'Мгновенные ответы', 'ar': 'ردود فورية', 'en': 'Instant responses', 'pt': 'Respostas instantâneas',
    },
    'welcome': {
      'de': 'Willkommen bei Premium! 🎉', 'es': '¡Bienvenido a Premium! 🎉', 'fr': 'Bienvenue dans Premium ! 🎉',
      'it': 'Benvenuto in Premium! 🎉', 'tr': "Premium'a hoş geldin! 🎉", 'pl': 'Witaj w Premium! 🎉',
      'ru': 'Добро пожаловать в Premium! 🎉', 'ar': 'مرحباً بك في Premium! 🎉', 'en': 'Welcome to Premium! 🎉', 'pt': 'Bem-vindo ao Premium! 🎉',
    },
    'restored': {
      'de': 'Kauf wiederhergestellt! 🎉', 'es': '¡Compra restaurada! 🎉', 'fr': 'Achat restauré ! 🎉',
      'it': 'Acquisto ripristinato! 🎉', 'tr': 'Satın alma geri yüklendi! 🎉', 'pl': 'Zakup przywrócony! 🎉',
      'ru': 'Покупка восстановлена! 🎉', 'ar': 'تمت استعادة الشراء! 🎉', 'en': 'Purchase restored! 🎉', 'pt': 'Compra restaurada! 🎉',
    },
    'no_purchase': {
      'de': 'Kein Kauf gefunden', 'es': 'No se encontró ninguna compra', 'fr': 'Aucun achat trouvé',
      'it': 'Nessun acquisto trovato', 'tr': 'Satın alma bulunamadı', 'pl': 'Nie znaleziono zakupu',
      'ru': 'Покупка не найдена', 'ar': 'لم يُعثر على أي شراء', 'en': 'No purchase found', 'pt': 'Nenhuma compra encontrada',
    },
  };
  return texts[key]?[code] ?? texts[key]?['en'] ?? '';
}


// ─── ENTRY POINT ─────────────────────────────────────────────────────────────
class PaywallFlow extends StatefulWidget {
  const PaywallFlow({super.key});

  @override
  State<PaywallFlow> createState() => _PaywallFlowState();
}

class _PaywallFlowState extends State<PaywallFlow> {
  int _step = 0;

  void _next() {
    if (_step < 2) setState(() => _step++);
  }

  // Textos em todos os idiomas
  String _headline1(String code) {
    switch (code) {
      case 'de': return "Mehr Dates.\nWeniger Zögern.";
      case 'es': return "Más citas.\nMenos dudas.";
      case 'fr': return "Plus de dates.\nMoins d'hésitation.";
      case 'it': return "Più appuntamenti.\nMeno esitazione.";
      case 'tr': return "Daha fazla randevu.\nDaha az tereddüt.";
      case 'pl': return "Więcej randek.\nMniej wahania.";
      case 'ru': return "Больше свиданий.\nМеньше сомнений.";
      case 'ar': return "مواعيد أكثر.\nتردد أقل.";
      default:   return "More dates.\nLess hesitation.";
    }
  }

  String _subline1(String code) {
    switch (code) {
      case 'de': return "Screenshot aufnehmen und in Sekunden die perfekte Antwort erhalten.";
      case 'es': return "Saca una captura y recibe la respuesta perfecta en segundos.";
      case 'fr': return "Prends une capture et reçois la réponse parfaite en secondes.";
      case 'it': return "Fai uno screenshot e ricevi la risposta perfetta in secondi.";
      case 'tr': return "Ekran görüntüsü al ve saniyeler içinde mükemmel yanıtı al.";
      case 'pl': return "Zrób zrzut ekranu i otrzymaj idealną odpowiedź w sekundy.";
      case 'ru': return "Сделай скриншот и получи идеальный ответ за секунды.";
      case 'ar': return "التقط صورة وتلقَّ الرد المثالي في ثوانٍ.";
      default:   return "Take a screenshot and get the perfect reply in seconds.";
    }
  }

  String _headline2(String code) {
    switch (code) {
      case 'de': return "Dein persönlicher\nCoach 24/7.";
      case 'es': return "Tu coach\npersonal 24/7.";
      case 'fr': return "Ton coach\npersonnel 24/7.";
      case 'it': return "Il tuo coach\npersonale 24/7.";
      case 'tr': return "Kişisel\nkoçun 24/7.";
      case 'pl': return "Twój osobisty\ncoach 24/7.";
      case 'ru': return "Твой личный\nкоуч 24/7.";
      case 'ar': return "مدربك\nالشخصي 24/7.";
      default:   return "Your personal\ncoach 24/7.";
    }
  }

  String _subline2(String code) {
    switch (code) {
      case 'de': return "Analysiert die Situation und sagt dir genau, was zu tun ist.";
      case 'es': return "Analiza la situación y te dice exactamente qué hacer.";
      case 'fr': return "Analyse la situation et te dit exactement quoi faire.";
      case 'it': return "Analizza la situazione e ti dice esattamente cosa fare.";
      case 'tr': return "Durumu analiz eder ve tam olarak ne yapman gerektiğini söyler.";
      case 'pl': return "Analizuje sytuację i mówi ci dokładnie, co robić.";
      case 'ru': return "Анализирует ситуацию и говорит тебе что именно делать.";
      case 'ar': return "يحلل الموقف ويخبرك بالضبط بما يجب فعله.";
      default:   return "Analyzes the situation and tells you exactly what to do.";
    }
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder(
      valueListenable: appLangNotifier,
      builder: (_, lang, __) {
        final code = lang.languageCode;
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
            0 => _PaywallSlide(
                key: const ValueKey(0),
                step: 0,
                totalSteps: 2,
                headline: _headline1(code),
                subline: _subline1(code),
                visual: const _ConversationPreview(),
                onContinue: _next,
              ),
            1 => _PaywallSlide(
                key: const ValueKey(1),
                step: 1,
                totalSteps: 2,
                headline: _headline2(code),
                subline: _subline2(code),
                visual: const _CoachPreview(),
                onContinue: _next,
              ),
            _ => _PaywallPlans(
                key: const ValueKey(2),
                onClose: () => Navigator.pop(context),
              ),
          },
        );
      },
    );
  }
}

// ─── SLIDE BASE ───────────────────────────────────────────────────────────────
class _PaywallSlide extends StatelessWidget {
  final int step;
  final int totalSteps;
  final String headline;
  final String subline;
  final Widget visual;
  final VoidCallback onContinue;

  const _PaywallSlide({
    required this.step,
    required this.totalSteps,
    required this.headline,
    required this.subline,
    required this.visual,
    required this.onContinue,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).padding.bottom;
    final lang = appLang.languageCode; // String

    return Scaffold(
      backgroundColor: const Color(0xFF08080F),
      body: Column(
        children: [
          // ── Área superior com visual ──────────────────────────────────────
          Expanded(
            flex: 6,
            child: Stack(
              children: [
                // Gradiente de fundo
                Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Color(0xFF1A0510), Color(0xFF08080F)],
                    ),
                  ),
                ),
                // Blob vermelho no topo
                Positioned(
                  top: -60, left: -40,
                  child: Container(
                    width: 260, height: 260,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: const Color(0xFFFF2D55).withOpacity(0.12),
                    ),
                  ),
                ),
                Positioned(
                  top: -40, right: -60,
                  child: Container(
                    width: 200, height: 200,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: const Color(0xFF5856D6).withOpacity(0.1),
                    ),
                  ),
                ),

                // Conteúdo
                SafeArea(
                  bottom: false,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(28, 16, 28, 0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Top bar
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            // Dots
                            Row(
                              children: List.generate(totalSteps, (i) =>
                                AnimatedContainer(
                                  duration: const Duration(milliseconds: 300),
                                  margin: const EdgeInsets.only(right: 6),
                                  width: i == step ? 22 : 7,
                                  height: 7,
                                  decoration: BoxDecoration(
                                    color: i == step
                                        ? const Color(0xFFFF2D55)
                                        : Colors.white.withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                ),
                              ),
                            ),
                            // Fechar
                            GestureDetector(
                              onTap: () => Navigator.pop(context),
                              child: Container(
                                width: 30, height: 30,
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.08),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(Icons.close,
                                    color: Colors.white38, size: 16),
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 36),

                        // Headline
                        Text(
                          headline,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 38,
                            fontWeight: FontWeight.w900,
                            letterSpacing: -1.2,
                            height: 1.05,
                          ),
                        ),

                        const SizedBox(height: 12),

                        Text(
                          subline,
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.45),
                            fontSize: 15,
                            height: 1.4,
                          ),
                        ),

                        const SizedBox(height: 32),

                        // Visual
                        Expanded(child: visual),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          // ── Área inferior com botão ───────────────────────────────────────
          Container(
            color: const Color(0xFF08080F),
            padding: EdgeInsets.fromLTRB(24, 20, 24, bottom + 20),
            child: Column(
              children: [
                // Check
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 16, height: 16,
                      decoration: const BoxDecoration(
                          color: Color(0xFF34C759), shape: BoxShape.circle),
                      child: const Icon(Icons.check, color: Colors.white, size: 11),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      _paywallText(appLang.languageCode, "no_payment"),
                      style: TextStyle(
                          color: Colors.white.withOpacity(0.5), fontSize: 13),
                    ),
                  ],
                ),
                const SizedBox(height: 14),

                // Botão
                SizedBox(
                  width: double.infinity, height: 56,
                  child: ElevatedButton(
                    onPressed: onContinue,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFFF2D55),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shadowColor: Colors.transparent,
                      surfaceTintColor: Colors.transparent,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          step < totalSteps - 1 ? "Continuar" : "Ver planos",
                          style: const TextStyle(
                              fontSize: 16, fontWeight: FontWeight.w800),
                        ),
                        const SizedBox(width: 8),
                        const Icon(Icons.arrow_forward_rounded, size: 18),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 10),
                _TermsRow(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── VISUAL 1 — Conversa ─────────────────────────────────────────────────────
class _ConversationPreview extends StatelessWidget {
  const _ConversationPreview();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.04),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.07)),
      ),
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header tipo chat
          Row(children: [
            Container(
              width: 36, height: 36,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                    colors: [Color(0xFFFF9500), Color(0xFFFFCC02)]),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.person_rounded, color: Colors.white, size: 20),
            ),
            const SizedBox(width: 10),
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text("Sara", style: TextStyle(color: Colors.white,
                  fontSize: 14, fontWeight: FontWeight.w700)),
              Row(children: [
                Container(width: 6, height: 6,
                    decoration: const BoxDecoration(
                        color: Color(0xFF34C759), shape: BoxShape.circle)),
                const SizedBox(width: 5),
                Text("online agora", style: TextStyle(
                    color: Colors.white.withOpacity(0.4), fontSize: 11)),
              ]),
            ]),
          ]),

          const SizedBox(height: 16),

          // Mensagem 1 dela
          Align(alignment: Alignment.centerLeft,
            child: _bubble("O que estás a fazer este fim de semana? 🙂",
                isMe: false)),
          const SizedBox(height: 6),
          // Resposta 1 (user sem IA)
          Align(alignment: Alignment.centerRight,
            child: _bubble("Nada de especial...", isMe: true, isAI: false)),
          const SizedBox(height: 6),
          // Mensagem 2 dela
          Align(alignment: Alignment.centerLeft,
            child: _bubble("Lol então não tens planos? 😏", isMe: false)),
          const SizedBox(height: 6),
          // Resposta gerada pela IA
          Align(alignment: Alignment.centerRight,
            child: _bubble("Tenho — convida-me a mudar isso 😈",
                isMe: true, isAI: true)),

          const Spacer(),

          // Badge
          Center(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFFFF2D55).withOpacity(0.12),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFFFF2D55).withOpacity(0.25)),
              ),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                const Icon(Icons.auto_awesome_rounded,
                    color: Color(0xFFFF2D55), size: 13),
                const SizedBox(width: 6),
                Text("Gerado pelo UpCrush AI",
                    style: TextStyle(color: Colors.white.withOpacity(0.7),
                        fontSize: 12, fontWeight: FontWeight.w500)),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _bubble(String text, {required bool isMe, bool isAI = false}) {
    return Container(
      constraints: const BoxConstraints(maxWidth: 240),
      padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 9),
      decoration: BoxDecoration(
        gradient: isAI ? const LinearGradient(
          colors: [Color(0xFFFF2D55), Color(0xFFFF6B81)],
          begin: Alignment.topLeft, end: Alignment.bottomRight) : null,
        color: isAI ? null : (isMe
            ? Colors.white.withOpacity(0.12)
            : Colors.white.withOpacity(0.08)),
        borderRadius: BorderRadius.only(
          topLeft: const Radius.circular(14),
          topRight: const Radius.circular(14),
          bottomLeft: Radius.circular(isMe ? 14 : 4),
          bottomRight: Radius.circular(isMe ? 4 : 14),
        ),
        boxShadow: isAI ? [BoxShadow(
            color: const Color(0xFFFF2D55).withOpacity(0.3),
            blurRadius: 10, offset: const Offset(0, 4))] : [],
      ),
      child: Text(text, style: TextStyle(
          color: Colors.white,
          fontSize: 13,
          fontWeight: isAI ? FontWeight.w500 : FontWeight.w400)),
    );
  }
}

// ─── VISUAL 2 — Coach ────────────────────────────────────────────────────────
class _CoachPreview extends StatelessWidget {
  const _CoachPreview();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.04),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.07)),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          // Header UpCrush AI
          Row(children: [
            Container(
              width: 36, height: 36,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                    colors: [Color(0xFFFF2D55), Color(0xFFFF6B81)]),
                borderRadius: BorderRadius.circular(12),
                boxShadow: [BoxShadow(
                    color: const Color(0xFFFF2D55).withOpacity(0.4),
                    blurRadius: 10, offset: const Offset(0, 3))],
              ),
              child: const Icon(Icons.auto_awesome_rounded,
                  color: Colors.white, size: 18),
            ),
            const SizedBox(width: 10),
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text("UpCrush AI",
                  style: TextStyle(color: Colors.white, fontSize: 14,
                      fontWeight: FontWeight.w700)),
              Text("Coach de Dating",
                  style: TextStyle(
                      color: Colors.white.withOpacity(0.4), fontSize: 11)),
            ]),
          ]),

          const SizedBox(height: 20),

          // Pergunta do utilizador
          Align(
            alignment: Alignment.centerRight,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.09),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(16), topRight: Radius.circular(16),
                  bottomLeft: Radius.circular(16)),
              ),
              child: const Text("Ela deixou a ver há 2 dias 😟",
                  style: TextStyle(color: Colors.white, fontSize: 14)),
            ),
          ),

          const SizedBox(height: 8),

          // Resposta do coach
          Align(
            alignment: Alignment.centerLeft,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: [
                  const Color(0xFFFF2D55).withOpacity(0.15),
                  const Color(0xFF5856D6).withOpacity(0.12),
                ]),
                borderRadius: const BorderRadius.only(
                  topRight: Radius.circular(16), bottomLeft: Radius.circular(16),
                  bottomRight: Radius.circular(16)),
                border: Border.all(color: const Color(0xFFFF2D55).withOpacity(0.2)),
              ),
              child: const Text(
                "Não entres em contacto. Ela está a testar o teu valor. Espera mais 2 dias e manda algo curto e sem pressão. 🎯",
                style: TextStyle(color: Colors.white, fontSize: 13, height: 1.45),
              ),
            ),
          ),

          const Spacer(),

          // Stats
          Row(children: [
            _stat("2.4k", "Conversas\nresolvidas"),
            const SizedBox(width: 10),
            _stat("94%", "Taxa de\nresposta"),
            const SizedBox(width: 10),
            _stat("24/7", "Sempre\ndisponível"),
          ]),
        ],
      ),
    );
  }

  Widget _stat(String value, String label) => Expanded(
    child: Container(
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(children: [
        Text(value, style: const TextStyle(color: Colors.white, fontSize: 16,
            fontWeight: FontWeight.w800)),
        const SizedBox(height: 3),
        Text(label, textAlign: TextAlign.center,
            style: TextStyle(color: Colors.white.withOpacity(0.4),
                fontSize: 10, height: 1.3)),
      ]),
    ),
  );
}

// ─── PLANOS ───────────────────────────────────────────────────────────────────
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
    final code = appLang.languageCode;
    final result = await RevenueCatService.buyWeekly();
    setState(() => _loading = false);
    if (!mounted) return;
    if (result.success) {
      await CreditsService.setPremium(true);
      Navigator.pop(context, true);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(_paywallText(appLang.languageCode, "welcome")),
        backgroundColor: const Color(0xFF34C759),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ));
    } else if (!result.cancelled) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(result.error ?? "Erro ao processar compra"),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ));
    }
  }

  Future<void> _handleRestore() async {
    setState(() => _loading = true);
    final result = await RevenueCatService.restorePurchases();
    setState(() => _loading = false);
    if (!mounted) return;
    if (result.success) {
      Navigator.pop(context, true);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(_paywallText(appLang.languageCode, "restored")),
        backgroundColor: const Color(0xFF34C759),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(_paywallText(appLang.languageCode, "no_purchase")),
        backgroundColor: Colors.orange,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).padding.bottom;
    final lang = appLang.languageCode; // String

    return Scaffold(
      backgroundColor: const Color(0xFF08080F),
      body: Stack(children: [
        Positioned(top: -80, right: -60,
          child: Container(width: 260, height: 260,
            decoration: BoxDecoration(shape: BoxShape.circle,
              color: const Color(0xFFFF2D55).withOpacity(0.08)))),

        SafeArea(child: Column(children: [
          // Fechar
          Align(alignment: Alignment.topRight,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(0, 12, 16, 0),
              child: GestureDetector(
                onTap: widget.onClose,
                child: Container(
                  width: 30, height: 30,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.08),
                    shape: BoxShape.circle),
                  child: const Icon(Icons.close, color: Colors.white38, size: 16)),
              ),
            ),
          ),

          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 8, 24, 0),
            child: Column(children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFFF2D55), Color(0xFFFF6B81)]),
                  borderRadius: BorderRadius.circular(20)),
                child: const Text("✦ PREMIUM",
                  style: TextStyle(color: Colors.white, fontSize: 11,
                    fontWeight: FontWeight.w800, letterSpacing: 1.5)),
              ),
              const SizedBox(height: 14),
              Text(_paywallText(appLang.languageCode, "plans_title"),
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white, fontSize: 26,
                  fontWeight: FontWeight.w900, letterSpacing: -0.8, height: 1.15)),
              const SizedBox(height: 6),
              Text(_paywallText(appLang.languageCode, "plans_sub"),
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 13)),
            ]),
          ),

          const SizedBox(height: 20),

          // Features
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.05),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: Colors.white.withOpacity(0.07))),
              child: Column(children: [
                _feat("📸", _paywallText(appLang.languageCode, "feat1")),
                _feat("❤️", _paywallText(appLang.languageCode, "feat2")),
                _feat("🤖", _paywallText(appLang.languageCode, "feat3")),
                _feat("⚡", _paywallText(appLang.languageCode, "feat4")),
              ]),
            ),
          ),

          const SizedBox(height: 20),

          // ── ÚNICO PLANO €6.99/semana ─────────────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 24),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFFF2D55), Color(0xFFFF6B81)],
                  begin: Alignment.topLeft, end: Alignment.bottomRight),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [BoxShadow(
                  color: const Color(0xFFFF2D55).withOpacity(0.45),
                  blurRadius: 24, offset: const Offset(0, 10))]),
              child: Row(children: [
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(8)),
                    child: const Text("✓  3 DIAS GRÁTIS",
                      style: TextStyle(color: Colors.white, fontSize: 11,
                        fontWeight: FontWeight.w800, letterSpacing: 0.8)),
                  ),
                  const SizedBox(height: 10),
                  const Text("Semanal",
                    style: TextStyle(color: Colors.white70, fontSize: 14,
                      fontWeight: FontWeight.w500)),
                  Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
                    const Text("€6.99",
                      style: TextStyle(color: Colors.white, fontSize: 40,
                        fontWeight: FontWeight.w900, letterSpacing: -1)),
                    const SizedBox(width: 4),
                    const Padding(
                      padding: EdgeInsets.only(bottom: 6),
                      child: Text("/sem",
                        style: TextStyle(color: Colors.white60, fontSize: 14))),
                  ]),
                ]),
                const Spacer(),
                Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                  Text("Hoje", style: TextStyle(
                    color: Colors.white.withOpacity(0.5), fontSize: 12)),
                  const Text("€0.00",
                    style: TextStyle(color: Colors.white, fontSize: 22,
                      fontWeight: FontWeight.w800)),
                  const SizedBox(height: 8),
                  Text("Após trial",
                    style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 12)),
                  const Text("€6.99/sem",
                    style: TextStyle(color: Colors.white, fontSize: 14,
                      fontWeight: FontWeight.w700)),
                ]),
              ]),
            ),
          ),

          const Spacer(),

          // Bottom
          Padding(
            padding: EdgeInsets.fromLTRB(24, 0, 24, bottom + 16),
            child: Column(children: [
              // Sem pagamento agora
              Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                Container(width: 16, height: 16,
                  decoration: const BoxDecoration(
                    color: Color(0xFF34C759), shape: BoxShape.circle),
                  child: const Icon(Icons.check, color: Colors.white, size: 11)),
                const SizedBox(width: 8),
                Text(_paywallText(appLang.languageCode, "no_payment"),
                  style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 13)),
              ]),
              const SizedBox(height: 12),

              // Botão
              SizedBox(
                width: double.infinity, height: 56,
                child: ElevatedButton(
                  onPressed: _loading ? null : _handlePurchase,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: const Color(0xFF1C1C1E),
                    surfaceTintColor: Colors.transparent,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16)),
                    elevation: 0),
                  child: _loading
                    ? const SizedBox(width: 22, height: 22,
                        child: CircularProgressIndicator(strokeWidth: 2))
                    : Text(_paywallText(appLang.languageCode, "trial"),
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
                ),
              ),
              const SizedBox(height: 8),
              Text(_paywallText(appLang.languageCode, "trial_sub"),
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white.withOpacity(0.25), fontSize: 11)),
              const SizedBox(height: 8),
              Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                _link("Terms", () {}),
                _sep(),
                _link("Restore", _handleRestore),
                _sep(),
                _link("Privacy", () {}),
              ]),
            ]),
          ),
        ])),
      ]),
    );
  }

  Widget _feat(String emoji, String label) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 5),
    child: Row(children: [
      Text(emoji, style: const TextStyle(fontSize: 17)),
      const SizedBox(width: 12),
      Text(label, style: const TextStyle(color: Colors.white, fontSize: 14,
        fontWeight: FontWeight.w500)),
      const Spacer(),
      const Icon(Icons.check_circle_rounded, color: Color(0xFF34C759), size: 17),
    ]),
  );

  Widget _link(String t, VoidCallback onTap) => GestureDetector(
    onTap: onTap,
    child: Text(t, style: TextStyle(
      color: Colors.white.withOpacity(0.25), fontSize: 11,
      decoration: TextDecoration.underline,
      decorationColor: Colors.white.withOpacity(0.2))));

  Widget _sep() => Text("  ·  ",
    style: TextStyle(color: Colors.white.withOpacity(0.15), fontSize: 11));
}


// ─── TERMS ROW ────────────────────────────────────────────────────────────────
class _TermsRow extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Row(mainAxisAlignment: MainAxisAlignment.center, children: [
      _link("Terms"), _sep(), _link("Restore"), _sep(), _link("Privacy"),
    ]);
  }

  Widget _link(String t) => GestureDetector(onTap: () {},
    child: Text(t, style: TextStyle(
        color: Colors.white.withOpacity(0.25), fontSize: 11,
        decoration: TextDecoration.underline,
        decorationColor: Colors.white.withOpacity(0.2))));

  Widget _sep() => Text("  ·  ",
      style: TextStyle(color: Colors.white.withOpacity(0.15), fontSize: 11));
}