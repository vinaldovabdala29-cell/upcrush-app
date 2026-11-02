import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
  bool _showTrial = false;

  static const _strings = <String, List<String>>{
    // en, pt, de, es, fr, it, tr, pl, ru, ar
    'close': ['Close','Fechar','Schließen','Cerrar','Fermer','Chiudi','Kapat','Zamknij','Закрыть','إغلاق'],
    'offer': ['Your one time offer','Sua única oferta','Dein einmaliges Angebot','Tu oferta única','Votre offre unique','La tua offerta unica','Tek seferlik teklifin','Twoja jedyna oferta','Ваше единственное предложение','عرضك الوحيد'],
    'gone': ["Once you close this offer, it’s gone.",'Depois de fechares esta oferta, ela desaparece.','Wenn du dieses Angebot schließt, ist es weg.','Cuando cierres esta oferta, desaparecerá.',"Une fois cette offre fermée, elle disparaît.",'Se chiudi questa offerta, non tornerà.','Bu teklifi kapatırsan bir daha görünmez.','Gdy zamkniesz tę ofertę, zniknie.','Если закрыть предложение, оно исчезнет.','بمجرد إغلاق هذا العرض، سيختفي.'],
    'save': ['SAVE 80%','Economize 80%','80% SPAREN','AHORRA 80%','ÉCONOMISEZ 80%','RISPARMIA L’80%','%80 TASARRUF','OSZCZĘDŹ 80%','ЭКОНОМИЯ 80%','وفّر 80%'],
    'weekly': ['Weekly','Semanal','Wöchentlich','Semanal','Hebdomadaire','Settimanale','Haftalık','Tygodniowo','Еженедельно','أسبوعيًا'],
    'billed': ['Billed {price} per week','Cobrado {price} por semana','{price} pro Woche','Cobro de {price} por semana','Facturé {price} par semaine','Addebito di {price} a settimana','Haftalık {price} tahsil edilir','Opłata {price} tygodniowo','Оплата {price} в неделю','يُخصم {price} أسبوعيًا'],
    'loading': ['Loading price…','A carregar preço…','Preis wird geladen…','Cargando precio…','Chargement du prix…','Caricamento prezzo…','Fiyat yükleniyor…','Wczytywanie ceny…','Загрузка цены…','جارٍ تحميل السعر…'],
    'buy': ['Take my offer','Aproveitar oferta','Angebot sichern','Aprovechar oferta','Profiter de l’offre','Approfitta dell’offerta','Teklifi al','Skorzystaj z oferty','Получить предложение','احصل على العرض'],
    'cancel': ['No commitment. Cancel anytime.','Sem compromisso. Cancela quando quiseres.','Keine Bindung. Jederzeit kündbar.','Sin compromiso. Cancela cuando quieras.','Sans engagement. Résiliation à tout moment.','Nessun impegno. Annulla quando vuoi.','Taahhüt yok. İstediğin zaman iptal et.','Bez zobowiązań. Anuluj w dowolnej chwili.','Без обязательств. Отмена в любое время.','بدون التزام. يمكنك الإلغاء في أي وقت.'],
    'terms': ['Terms','Termos','AGB','Términos','Conditions','Termini','Koşullar','Warunki','Условия','الشروط'],
    'privacy': ['Privacy','Privacidade','Datenschutz','Privacidad','Confidentialité','Privacy','Gizlilik','Prywatność','Конфиденциальность','الخصوصية'],
    'error': ['Purchase unavailable','Compra indisponível','Kauf nicht verfügbar','Compra no disponible','Achat indisponible','Acquisto non disponibile','Satın alma kullanılamıyor','Zakup niedostępny','Покупка недоступна','الشراء غير متاح'],
    'trial': ['3 days free','3 dias grátis','3 Tage kostenlos','3 días gratis','3 jours gratuits','3 giorni gratis','3 gün ücretsiz','3 dni za darmo','3 дня бесплатно','3 أيام مجانًا'],
    'afterTrial': ['Then {price}/week','Depois {price}/semana','Danach {price}/Woche','Después {price}/semana','Puis {price}/semaine','Poi {price}/settimana','Sonra {price}/hafta','Potem {price}/tydzień','Затем {price}/неделю','ثم {price} أسبوعيًا'],
    'startTrial': ['Start free trial','Começar teste grátis','Kostenlos testen','Empezar prueba gratis','Commencer l’essai gratuit','Inizia la prova gratuita','Ücretsiz denemeyi başlat','Rozpocznij darmowy okres','Начать бесплатный период','ابدأ التجربة المجانية'],
    'day': ['/day','/dia','/Tag','/día','/jour','/giorno','/gün','/dzień','/день','/يوم'],
  };
  static const _langs = ['en','pt','de','es','fr','it','tr','pl','ru','ar'];
  String _t(String language, String key) {
    final index = _langs.indexOf(language);
    return _strings[key]![index < 0 ? 0 : index];
  }

  @override
  void initState() {
    super.initState();
    RevenueCatService.getWeeklyPaywallOffer().then((offer) {
      if (mounted) setState(() {
        _price = offer.price;
        _showTrial = offer.showTrial;
      });
    }).catchError((Object _) {
      if (mounted) setState(() { _price = ''; _showTrial = false; });
    });
  }

  // Display a daily equivalent only for a recognized currency/price.
  // The charged weekly price always comes from RevenueCat.
  String? _daily(String language) {
    final match = RegExp(r'\d[\d.,\s]*').firstMatch(_price);
    if (match == null) return null;
    var number = match.group(0)!.replaceAll(' ', '');
    final comma = number.lastIndexOf(',');
    final dot = number.lastIndexOf('.');
    if (comma > dot) {
      number = number.replaceAll('.', '').replaceAll(',', '.');
    } else if (dot > comma && comma >= 0) {
      number = number.replaceAll(',', '');
    }
    final amount = double.tryParse(number);
    if (amount == null || amount <= 0) return null;
    final currency = _price.contains('€') ? '€' : _price.contains('R\$') ? 'R\$' : _price.contains('\$') ? '\$' : null;
    if (currency == null) return null;
    final value = (amount / 7).toStringAsFixed(2).replaceAll('.', language == 'en' ? '.' : ',');
    return '$value $currency${_t(language, 'day')}';
  }

  Future<void> _buy(String language) async {
    if (_loading || _price.isEmpty) return;
    setState(() => _loading = true);
    try {
      final result = await RevenueCatService.buyWeekly();
      if (!mounted) return;
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
          SnackBar(content: Text(result.error ?? _t(language, 'error'))),
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(_t(language, 'error'))),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _open(String url) async {
    await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
  }

  Widget _heading(String value, double size, {Color color = Colors.white}) =>
      Text(value, textAlign: TextAlign.center, maxLines: 3,
        style: TextStyle(color: color, fontSize: size, fontWeight: FontWeight.w900,
          height: 1.04, letterSpacing: -0.6));

  Widget _legal(String title, String url) => SizedBox(
    height: 40,
    child: TextButton(
      onPressed: () => _open(url),
      style: TextButton.styleFrom(backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        padding: const EdgeInsets.symmetric(horizontal: 18)),
      child: Text(title, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14)),
    ),
  );

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder(
      valueListenable: appLangNotifier,
      builder: (context, locale, _) {
        final language = locale.languageCode;
        final daily = _daily(language);
        return AnnotatedRegion<SystemUiOverlayStyle>(
          value: SystemUiOverlayStyle.light.copyWith(
            statusBarColor: Colors.transparent,
            statusBarIconBrightness: Brightness.light,
            statusBarBrightness: Brightness.dark,
            systemNavigationBarColor: Colors.black,
            systemNavigationBarIconBrightness: Brightness.light,
          ),
          child: Scaffold(
            backgroundColor: Colors.black,
            body: SafeArea(
              child: LayoutBuilder(builder: (context, limits) {
                // Fixed, non-scrolling composition. FittedBox scales to the
                // available iPhone/Android viewport, including small devices.
                final designWidth = limits.maxWidth.clamp(280.0, 440.0);
                const designHeight = 735.0;
                return Stack(children: [
                  const Positioned.fill(child: IgnorePointer(child: DecoratedBox(
                    decoration: BoxDecoration(gradient: RadialGradient(
                      center: Alignment(0, -0.12), radius: 0.85,
                      colors: [Color(0xFF68108F), Color(0xFF39094F), Color(0xFF100619), Colors.black],
                      stops: [0, 0.37, 0.75, 1],
                    )),
                  ))),
                  Positioned.fill(child: Center(child: FittedBox(
                    fit: BoxFit.contain,
                    child: SizedBox(width: designWidth, height: designHeight,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: Column(children: [
                          SizedBox(height: 54, child: Stack(children: [
                            Center(child: _heading('UPCRUSH', 32)),
                            Positioned(right: 0, top: 0, child: IconButton(
                              tooltip: _t(language, 'close'),
                              onPressed: () => Navigator.of(context).pop(false),
                              icon: const Icon(Icons.close, color: Colors.white, size: 30),
                            )),
                          ])),
                          const Spacer(flex: 2),
                          _heading(_t(language, 'offer'), 27),
                          const SizedBox(height: 15),
                          _heading('80%\nOFF', 77),
                          const Spacer(flex: 2),
                          _heading(_t(language, 'gone'), 17),
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
                                child: _heading(_t(language, 'save'), 19, color: Colors.black)),
                              Padding(padding: const EdgeInsets.fromLTRB(13, 12, 13, 13),
                                child: Row(children: [
                                  const Icon(Icons.radio_button_checked, color: Colors.white, size: 26),
                                  const SizedBox(width: 11),
                                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                                    SizedBox(width: double.infinity, child: Row(children: [
                                      Expanded(child: Text(_showTrial ? _t(language, 'trial') : _t(language, 'weekly'),
                                        style: const TextStyle(color: Colors.white, fontSize: 21, fontWeight: FontWeight.w800))),
                                      if (!_showTrial && daily != null) Text(daily, textAlign: TextAlign.right,
                                        style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w800)),
                                    ])),
                                    const SizedBox(height: 5),
                                    Text(_price.isEmpty ? _t(language, 'loading') :
                                      (_showTrial ? _t(language, 'afterTrial') : _t(language, 'billed')).replaceAll('{price}', _price),
                                      style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600)),
                                  ])),
                                ])),
                            ]),
                          ),
                          const SizedBox(height: 15),
                          SizedBox(width: double.infinity, height: 58, child: ElevatedButton(
                            onPressed: _loading || _price.isEmpty ? null : () => _buy(language),
                            style: ElevatedButton.styleFrom(backgroundColor: Colors.white,
                              foregroundColor: Colors.black, disabledBackgroundColor: Colors.white70,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24))),
                            child: _loading ? const CircularProgressIndicator(color: Colors.black)
                              : Text(_t(language, _showTrial ? 'startTrial' : 'buy'), textAlign: TextAlign.center,
                                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900)),
                          )),
                          const SizedBox(height: 10),
                          Text(_t(language, 'cancel'), textAlign: TextAlign.center,
                            style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w700)),
                          const SizedBox(height: 13),
                          Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                            _legal(_t(language, 'terms'), 'https://sites.google.com/view/upcrush-terms/p%C3%A1gina-inicial'),
                            const SizedBox(width: 14),
                            _legal(_t(language, 'privacy'), 'https://sites.google.com/view/upcrush-privacy-policy/p%C3%A1gina-inicial'),
                          ]),
                          const SizedBox(height: 8),
                        ]),
                      ),
                    ),
                  ))),
                ]);
              }),
            ),
          ),
        );
      },
    );
  }
}
