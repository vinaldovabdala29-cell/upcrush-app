import 'dart:io';
import 'package:flutter/material.dart';
import '../../../main.dart';
import '../services/revenue_cat_service.dart';
import '../services/credits_service.dart';

// ── Textos do paywall em 10 idiomas ──────────────────────────────────────────
String _t(String key) {
  final code = appLang.languageCode;
  final Map<String, Map<String, String>> all = {
    'continue':    {'de':'Weiter','es':'Continuar','fr':'Continuer','it':'Continua','tr':'Devam et','pl':'Dalej','ru':'Далее','ar':'استمر','en':'Continue','pt':'Continuar'},
    'see_plans':   {'de':'Pläne sehen','es':'Ver planes','fr':'Voir les plans','it':'Vedi piani','tr':'Planları gör','pl':'Zobacz plany','ru':'Планы','ar':'عرض الخطط','en':'See plans','pt':'Ver planos'},
    'no_payment':  {'de':'Keine Zahlung jetzt','es':'Sin pago ahora','fr':'Pas de paiement','it':'Nessun pagamento','tr':'Şimdi ödeme yok','pl':'Brak płatności','ru':'Без оплаты','ar':'لا دفع الآن','en':'No payment now','pt':'Sem pagamento agora'},
    'trial':       {'de':'3 Tage kostenlos →','es':'Probar gratis 3 días →','fr':'3 jours gratuits →','it':'3 giorni gratis →','tr':'3 gün ücretsiz →','pl':'3 dni gratis →','ru':'3 дня бесплатно →','ar':'3 أيام مجاناً →','en':'Try free 3 days →','pt':'Experimentar 3 dias →'},
    'trial_sub':   {'de':'3 Tage gratis, dann €6,99/Wo. Jederzeit kündbar.','es':'3 días gratis, luego €6,99/sem.','fr':'3 jours gratuits, puis €6,99/sem.','it':'3 giorni gratis, poi €6,49/sett.','tr':'3 gün ücretsiz, sonra €6,49/hafta.','pl':'3 dni gratis, potem €6,49/tydz.','ru':'3 дня бесплатно, затем €6,49/нед.','ar':'3 أيام مجاناً، ثم €6.49 أسبوعياً.','en':'3 days free, then €6.99/wk. Cancel anytime.','pt':'3 dias grátis, depois €6.99/sem.'},
    'plans_title': {'de':'Bereit für\nmehr Dates?','es':'¿Listo para\nmás citas?','fr':'Prêt pour\nplus de dates?','it':'Pronto per\npiù appuntamenti?','tr':'Daha fazla\nrandevu için?','pl':'Gotowy na\nwięcej randek?','ru':'Готов к\nбольшему?','ar':'مستعد لمزيد\nمن المواعيد؟','en':'Ready for\nmore dates?','pt':'Pronto para\nmais datas?'},
    'plans_sub':   {'de':'Keine Verpflichtung. Jederzeit kündbar.','es':'Sin compromiso. Cancela cuando quieras.','fr':'Sans engagement. Annulable à tout moment.','it':'Senza impegno. Cancella quando vuoi.','tr':'Taahhüt yok. İstediğinde iptal et.','pl':'Bez zobowiązań. Anuluj kiedy chcesz.','ru':'Без обязательств. Отмени когда угодно.','ar':'بدون التزام. ألغِ متى تشاء.','en':'No commitment. Cancel anytime.','pt':'Sem compromisso. Cancela quando quiseres.'},
    'feat1':       {'de':'Unbegrenzte Screenshots','es':'Screenshots ilimitados','fr':'Screenshots illimités','it':'Screenshot illimitati','tr':'Sınırsız ekran görüntüsü','pl':'Nieograniczone zrzuty','ru':'Безлимитные скриншоты','ar':'لقطات غير محدودة','en':'Unlimited screenshots','pt':'Screenshots ilimitados'},
    'feat2':       {'de':'Unbegrenzte Opener','es':'Openers ilimitados','fr':'Openers illimités','it':'Opener illimitati','tr':'Sınırsız opener','pl':'Nieograniczone openers','ru':'Безлимитные опенеры','ar':'رسائل افتتاحية غير محدودة','en':'Unlimited openers','pt':'Openers ilimitados'},
    'feat3':       {'de':'Chatbot AI ohne Limits','es':'Chatbot AI sin límites','fr':'Chatbot AI sans limites','it':'Chatbot AI senza limiti','tr':'Sınırsız AI chatbot','pl':'Chatbot AI bez limitów','ru':'Чатбот без ограничений','ar':'روبوت AI بلا حدود','en':'Unlimited AI chatbot','pt':'Chatbot AI sem limites'},
    'feat4':       {'de':'Sofortige Antworten','es':'Respuestas instantáneas','fr':'Réponses instantanées','it':'Risposte istantanee','tr':'Anında yanıtlar','pl':'Natychmiastowe odpowiedzi','ru':'Мгновенные ответы','ar':'ردود فورية','en':'Instant responses','pt':'Respostas instantâneas'},
    'free_days':   {'de':'✓  3 TAGE GRATIS','es':'✓  3 DÍAS GRATIS','fr':'✓  3 JOURS GRATUITS','it':'✓  3 GIORNI GRATIS','tr':'✓  3 GÜN ÜCRETSİZ','pl':'✓  3 DNI GRATIS','ru':'✓  3 ДНЯ БЕСПЛАТНО','ar':'✓  3 أيام مجاناً','en':'✓  3 DAYS FREE','pt':'✓  3 DIAS GRÁTIS'},
    'weekly':      {'de':'Wöchentlich','es':'Semanal','fr':'Hebdomadaire','it':'Settimanale','tr':'Haftalık','pl':'Tygodniowy','ru':'Еженедельно','ar':'أسبوعي','en':'Weekly','pt':'Semanal'},
    'per_week':    {'de':'/Wo','es':'/sem','fr':'/sem','it':'/sett','tr':'/haf','pl':'/tydz','ru':'/нед','ar':'/أسبوع','en':'/wk','pt':'/sem'},
    'today':       {'de':'Heute','es':'Hoy','fr':"Aujourd'hui",'it':'Oggi','tr':'Bugün','pl':'Dzisiaj','ru':'Сегодня','ar':'اليوم','en':'Today','pt':'Hoje'},
    'after_trial': {'de':'Nach Trial','es':'Tras el trial','fr':'Après le trial','it':'Dopo il trial','tr':'Deneme sonrası','pl':'Po próbie','ru':'После пробного','ar':'بعد التجربة','en':'After trial','pt':'Após trial'},
    'welcome':     {'de':'Willkommen bei Premium! 🎉','es':'¡Bienvenido a Premium! 🎉','fr':'Bienvenue dans Premium ! 🎉','it':'Benvenuto in Premium! 🎉','tr':"Premium'a hoş geldin! 🎉",'pl':'Witaj w Premium! 🎉','ru':'Добро пожаловать в Premium! 🎉','ar':'مرحباً بك في Premium! 🎉','en':'Welcome to Premium! 🎉','pt':'Bem-vindo ao Premium! 🎉'},
    'restored':    {'de':'Kauf wiederhergestellt! 🎉','es':'¡Compra restaurada! 🎉','fr':'Achat restauré ! 🎉','it':'Acquisto ripristinato! 🎉','tr':'Satın alma geri yüklendi! 🎉','pl':'Zakup przywrócony! 🎉','ru':'Покупка восстановлена! 🎉','ar':'تمت استعادة الشراء! 🎉','en':'Purchase restored! 🎉','pt':'Compra restaurada! 🎉'},
    'no_purchase': {'de':'Kein Kauf gefunden','es':'No se encontró compra','fr':'Aucun achat trouvé','it':'Nessun acquisto trovato','tr':'Satın alma bulunamadı','pl':'Nie znaleziono zakupu','ru':'Покупка не найдена','ar':'لم يُعثر على شراء','en':'No purchase found','pt':'Nenhuma compra encontrada'},
    'error':       {'de':'Fehler bei der Zahlung','es':'Error al procesar','fr':'Erreur de paiement','it':'Errore nel pagamento','tr':'Ödeme hatası','pl':'Błąd płatności','ru':'Ошибка оплаты','ar':'خطأ في المعالجة','en':'Error processing payment','pt':'Erro ao processar compra'},
    'online':      {'de':'online','es':'en línea','fr':'en ligne','it':'online','tr':'çevrimiçi','pl':'online','ru':'онлайн','ar':'متصل','en':'online now','pt':'online agora'},
    'bubble1':     {'de':'Was machst du dieses Wochenende? 🙂','es':'¿Qué haces este fin de semana? 🙂','fr':'Tu fais quoi ce weekend? 🙂','it':'Cosa fai questo weekend? 🙂','tr':'Bu hafta sonu ne yapıyorsun? 🙂','pl':'Co robisz w ten weekend? 🙂','ru':'Что делаешь на выходных? 🙂','ar':'ماذا تفعل هذا الأسبوع؟ 🙂','en':'What are you doing this weekend? 🙂','pt':'O que estás a fazer este fim de semana? 🙂'},
    'bubble2':     {'de':'Nichts Besonderes...','es':'Nada especial...','fr':'Rien de spécial...','it':'Niente di speciale...','tr':'Özel bir şey yok...','pl':'Nic szczególnego...','ru':'Ничего особенного...','ar':'لا شيء خاص...','en':'Nothing special...','pt':'Nada de especial...'},
    'bubble3':     {'de':'Keine Pläne? 😏','es':'¿Sin planes? 😏','fr':'Pas de plans? 😏','it':'Nessun piano? 😏','tr':'Plan yok mu? 😏','pl':'Brak planów? 😏','ru':'Нет планов? 😏','ar':'لا خطط؟ 😏','en':'No plans? 😏','pt':'Sem planos? 😏'},
    'bubble4':     {'de':'Doch — lad mich ein 😈','es':'Sí — invítame 😈','fr':'Si — invite-moi 😈','it':'Sì — invitami 😈','tr':'Var — beni davet et 😈','pl':'Mam — zaproś mnie 😈','ru':'Есть — пригласи 😈','ar':'لدي — ادعني 😈','en':'I do — invite me 😈','pt':'Tenho — convida-me 😈'},
    'generated':   {'de':'Von UpCrush AI generiert','es':'Generado por UpCrush AI','fr':'Généré par UpCrush AI','it':'Generato da UpCrush AI','tr':'UpCrush AI tarafından','pl':'Przez UpCrush AI','ru':'Создано UpCrush AI','ar':'بواسطة UpCrush AI','en':'Generated by UpCrush AI','pt':'Gerado pelo UpCrush AI'},
    'coach_label': {'de':'Dating Coach','es':'Coach de Citas','fr':'Coach de Dating','it':'Coach di Dating','tr':'Flört Koçu','pl':'Coach randkowy','ru':'Коуч по свиданиям','ar':'مدرب المواعيد','en':'Dating Coach','pt':'Coach de Dating'},
    'coach1':      {'de':'Sie hat mich seit 2 Tagen gesehen 😟','es':'Me dejó en visto hace 2 días 😟','fr':"Elle m'a vu il y a 2 jours 😟",'it':'Mi ha visto 2 giorni fa 😟','tr':'2 gün önce gördü 😟','pl':'Zostawiła mnie 2 dni temu 😟','ru':'Видела 2 дня назад 😟','ar':'تركتني منذ يومين 😟','en':'She left me on seen 2 days ago 😟','pt':'Ela deixou a ver há 2 dias 😟'},
    'coach2':      {'de':'Schreib nicht. Sie testet dich. Warte 2 Tage. 🎯','es':'No la contactes. Te está probando. Espera 2 días. 🎯','fr':'Ne la contacte pas. Elle te teste. Attends 2 jours. 🎯','it':'Non scrivere. Ti sta testando. Aspetta 2 giorni. 🎯','tr':'Yazma. Seni test ediyor. 2 gün bekle. 🎯','pl':'Nie pisz. Testuje cię. Czekaj 2 dni. 🎯','ru':'Не пиши. Она проверяет тебя. Жди 2 дня. 🎯','ar':'لا تكتب. إنها تختبرك. انتظر يومين. 🎯','en':"Don't text. She's testing you. Wait 2 days. 🎯",'pt':'Não escrevas. Ela está a testar-te. Espera 2 dias. 🎯'},
    'convos':      {'de':'Gespräche\ngelöst','es':'Conversaciones\nresueltas','fr':'Conversations\nrésolues','it':'Conversazioni\nrisolte','tr':'Çözülen\nkonuşmalar','pl':'Rozmowy\nrozwiązane','ru':'Решённых\nразговоров','ar':'محادثات\nمحلولة','en':'Convos\nresolved','pt':'Conversas\nresolvidas'},
    'reply_rate':  {'de':'Antwort-\nquote','es':'Tasa de\nrespuesta','fr':'Taux de\nréponse','it':'Tasso di\nrisposta','tr':'Yanıt\noranı','pl':'Wskaźnik\nodpowiedzi','ru':'Процент\nответов','ar':'معدل\nالردود','en':'Reply\nrate','pt':'Taxa de\nresposta'},
    'always_on':   {'de':'Immer\nverfügbar','es':'Siempre\ndisponible','fr':'Toujours\ndisponible','it':'Sempre\ndisponibile','tr':'Her zaman\nmevcut','pl':'Zawsze\ndostępny','ru':'Всегда\nдоступен','ar':'متاح\nدائماً','en':'Always\non','pt':'Sempre\ndisponível'},
    'h1':          {'de':'Mehr Dates.\nWeniger Zögern.','es':'Más citas.\nMenos dudas.','fr':"Plus de dates.\nMoins d'hésitation.",'it':'Più appuntamenti.\nMeno esitazione.','tr':'Daha fazla randevu.\nDaha az tereddüt.','pl':'Więcej randek.\nMniej wahania.','ru':'Больше свиданий.\nМеньше сомнений.','ar':'مواعيد أكثر.\nتردد أقل.','en':'More dates.\nLess hesitation.','pt':'Mais datas.\nMenos hesitação.'},
    's1':          {'de':'Screenshot machen und perfekte Antwort in Sekunden erhalten.','es':'Saca una captura y recibe la respuesta perfecta en segundos.','fr':'Prends une capture et reçois la réponse parfaite en secondes.','it':'Fai uno screenshot e ricevi la risposta perfetta in secondi.','tr':'Ekran görüntüsü al ve mükemmel yanıtı saniyeler içinde al.','pl':'Zrób zrzut i otrzymaj idealną odpowiedź w sekundy.','ru':'Сделай скриншот и получи идеальный ответ за секунды.','ar':'التقط صورة وتلقَّ الرد المثالي في ثوانٍ.','en':'Take a screenshot and get the perfect reply in seconds.','pt':'Tira um print e recebe a resposta perfeita em segundos.'},
    'h2':          {'de':'Dein persönlicher\nCoach 24/7.','es':'Tu coach\npersonal 24/7.','fr':'Ton coach\npersonnel 24/7.','it':'Il tuo coach\npersonale 24/7.','tr':'Kişisel\nkoçun 24/7.','pl':'Twój osobisty\ncoach 24/7.','ru':'Твой личный\nкоуч 24/7.','ar':'مدربك\nالشخصي 24/7.','en':'Your personal\ncoach 24/7.','pt':'O teu coach\npessoal 24/7.'},
    's2':          {'de':'Analysiert die Situation und sagt dir genau, was zu tun ist.','es':'Analiza la situación y te dice exactamente qué hacer.','fr':'Analyse la situation et te dit exactement quoi faire.','it':'Analizza la situazione e ti dice esattamente cosa fare.','tr':'Durumu analiz eder ve tam olarak ne yapman gerektiğini söyler.','pl':'Analizuje sytuację i mówi ci dokładnie, co robić.','ru':'Анализирует ситуацию и говорит что делать.','ar':'يحلل الموقف ويخبرك بالضبط بما يجب فعله.','en':'Analyzes the situation and tells you exactly what to do.','pt':'Analisa a situação e diz-te exactamente o que fazer.'},
  };
  return all[key]?[code] ?? all[key]?['en'] ?? '';
}

// ─── ENTRY POINT ─────────────────────────────────────────────────────────────
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
                headline: _t('h1'), subline: _t('s1'),
                visual: const _ConversationPreview(), onContinue: _next),
            1 => _PaywallSlide(key: const ValueKey(1), step: 1, totalSteps: 2,
                headline: _t('h2'), subline: _t('s2'),
                visual: const _CoachPreview(), onContinue: _next),
            _ => _PaywallPlans(key: const ValueKey(2), onClose: () => Navigator.pop(context)),
          },
        );
      },
    );
  }
}

// ─── SLIDE ───────────────────────────────────────────────────────────────────
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
    return ValueListenableBuilder(
      valueListenable: appLangNotifier,
      builder: (_, lang, __) {
        final bottom = MediaQuery.of(context).padding.bottom;
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
                  Text(_t('no_payment'), style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 13)),
                ]),
                const SizedBox(height: 14),
                SizedBox(width: double.infinity, height: 56,
                  child: ElevatedButton(
                    onPressed: onContinue,
                    style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFFF2D55),
                      foregroundColor: Colors.white, elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
                    child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                      Text(step < totalSteps - 1 ? _t('continue') : _t('see_plans'),
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
                      const SizedBox(width: 8),
                      const Icon(Icons.arrow_forward_rounded, size: 18),
                    ]),
                  ),
                ),
                const SizedBox(height: 10),
                Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                  _link("Terms", () {}), _sep(),
                  _link("Restore", () {}), _sep(),
                  _link("Privacy", () {}),
                ]),
              ]),
            ),
          ]),
        );
      },
    );
  }

  Widget _link(String t, VoidCallback onTap) => GestureDetector(onTap: onTap,
    child: Text(t, style: TextStyle(color: Colors.white.withOpacity(0.25), fontSize: 11,
      decoration: TextDecoration.underline, decorationColor: Colors.white.withOpacity(0.2))));
  Widget _sep() => Text("  ·  ", style: TextStyle(color: Colors.white.withOpacity(0.15), fontSize: 11));
}

// ─── VISUAL 1 ────────────────────────────────────────────────────────────────
class _ConversationPreview extends StatelessWidget {
  const _ConversationPreview();
  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder(
      valueListenable: appLangNotifier,
      builder: (_, lang, __) {
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
                  Text(_t('online'), style: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 11)),
                ]),
              ]),
            ]),
            const SizedBox(height: 16),
            Align(alignment: Alignment.centerLeft, child: _bubble(_t('bubble1'), isMe: false)),
            const SizedBox(height: 6),
            Align(alignment: Alignment.centerRight, child: _bubble(_t('bubble2'), isMe: true, isAI: false)),
            const SizedBox(height: 6),
            Align(alignment: Alignment.centerLeft, child: _bubble(_t('bubble3'), isMe: false)),
            const SizedBox(height: 6),
            Align(alignment: Alignment.centerRight, child: _bubble(_t('bubble4'), isMe: true, isAI: true)),
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
                Text(_t('generated'), style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 12, fontWeight: FontWeight.w500)),
              ]),
            )),
          ]),
        );
      },
    );
  }

  Widget _bubble(String text, {required bool isMe, bool isAI = false}) {
    return Container(
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
}

// ─── VISUAL 2 ────────────────────────────────────────────────────────────────
class _CoachPreview extends StatelessWidget {
  const _CoachPreview();
  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder(
      valueListenable: appLangNotifier,
      builder: (_, lang, __) {
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
                Text(_t('coach_label'), style: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 11)),
              ]),
            ]),
            const SizedBox(height: 20),
            Align(alignment: Alignment.centerRight,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(color: Colors.white.withOpacity(0.09),
                  borderRadius: const BorderRadius.only(topLeft: Radius.circular(16),
                    topRight: Radius.circular(16), bottomLeft: Radius.circular(16))),
                child: Text(_t('coach1'), style: const TextStyle(color: Colors.white, fontSize: 14)),
              )),
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
                child: Text(_t('coach2'), style: const TextStyle(color: Colors.white, fontSize: 13, height: 1.45)),
              )),
            const Spacer(),
            Row(children: [
              _stat("2.4k", _t('convos')),
              const SizedBox(width: 10),
              _stat("94%", _t('reply_rate')),
              const SizedBox(width: 10),
              _stat("24/7", _t('always_on')),
            ]),
          ]),
        );
      },
    );
  }

  Widget _stat(String value, String label) => Expanded(
    child: Container(
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(color: Colors.white.withOpacity(0.05), borderRadius: BorderRadius.circular(12)),
      child: Column(children: [
        Text(value, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w800)),
        const SizedBox(height: 3),
        Text(label, textAlign: TextAlign.center, style: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 10, height: 1.3)),
      ]),
    ));
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
    final result = await RevenueCatService.buyWeekly();
    setState(() => _loading = false);
    if (!mounted) return;
    if (result.success) {
      await CreditsService.setPremium(true);
      Navigator.pop(context, true);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(_t('welcome')),
        backgroundColor: const Color(0xFF34C759),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))));
    } else if (!result.cancelled) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(result.error ?? _t('error')),
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
      Navigator.pop(context, true);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(_t('restored')),
        backgroundColor: const Color(0xFF34C759),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(_t('no_purchase')),
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
        final bottom = MediaQuery.of(context).padding.bottom;
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
                  Text(_t('plans_title'), textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.white, fontSize: 26,
                      fontWeight: FontWeight.w900, letterSpacing: -0.8, height: 1.15)),
                  const SizedBox(height: 6),
                  Text(_t('plans_sub'), textAlign: TextAlign.center,
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
                    _feat("📸", _t('feat1')),
                    _feat("❤️", _t('feat2')),
                    _feat("🤖", _t('feat3')),
                    _feat("⚡", _t('feat4')),
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
                        child: Text(_t('free_days'), style: const TextStyle(color: Colors.white,
                          fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 0.8))),
                      const SizedBox(height: 10),
                      Text(_t('weekly'), style: const TextStyle(color: Colors.white70, fontSize: 14, fontWeight: FontWeight.w500)),
                      Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
                        Text(Platform.isIOS ? "€9.99" : "€6.49", style: TextStyle(color: Colors.white, fontSize: 40,
                          fontWeight: FontWeight.w900, letterSpacing: -1)),
                        const SizedBox(width: 4),
                        Padding(padding: const EdgeInsets.only(bottom: 6),
                          child: Text(_t('per_week'), style: const TextStyle(color: Colors.white60, fontSize: 14))),
                      ]),
                    ]),
                    const Spacer(),
                    Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                      Text(_t('today'), style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 12)),
                      const Text("€0.00", style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w800)),
                      const SizedBox(height: 8),
                      Text(_t('after_trial'), style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 12)),
                      Text(Platform.isIOS ? "€9.99/sem" : "€6.49/sem", style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w700)),
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
                    Text(_t('no_payment'), style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 13)),
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
                        : Text(_t('trial'), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
                    )),
                  const SizedBox(height: 8),
                  Text(_t('trial_sub'), textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.white.withOpacity(0.25), fontSize: 11)),
                  const SizedBox(height: 8),
                  Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                    _link("Terms", () {}), _sep(),
                    _link("Restore", _handleRestore), _sep(),
                    _link("Privacy", () {}),
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