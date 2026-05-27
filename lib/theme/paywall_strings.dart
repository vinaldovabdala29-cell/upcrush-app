// lib/theme/paywall_strings.dart
// Todos os textos do paywall num só lugar — fácil de editar

class PS {
  static String get(String key, String lang) {
    return _t[key]?[lang] ?? _t[key]?['en'] ?? '';
  }

  static const Map<String, Map<String, String>> _t = {
    'continue_btn': {
      'de': 'Weiter', 'es': 'Continuar', 'fr': 'Continuer', 'it': 'Continua',
      'tr': 'Devam et', 'pl': 'Dalej', 'ru': 'Далее', 'ar': 'استمر',
      'en': 'Continue', 'pt': 'Continuar',
    },
    'see_plans': {
      'de': 'Pläne sehen', 'es': 'Ver planes', 'fr': 'Voir les plans', 'it': 'Vedi piani',
      'tr': 'Planları gör', 'pl': 'Zobacz plany', 'ru': 'Планы', 'ar': 'عرض الخطط',
      'en': 'See plans', 'pt': 'Ver planos',
    },
    'no_payment': {
      'de': 'Keine Zahlung jetzt', 'es': 'Sin pago ahora', 'fr': 'Pas de paiement maintenant',
      'it': 'Nessun pagamento ora', 'tr': 'Şimdi ödeme yok', 'pl': 'Brak płatności teraz',
      'ru': 'Без оплаты сейчас', 'ar': 'لا دفع الآن', 'en': 'No payment now', 'pt': 'Sem pagamento agora',
    },
    'trial': {
      'de': '3 Tage kostenlos testen →', 'es': 'Probar gratis 3 días →', 'fr': 'Essayer gratuitement 3 jours →',
      'it': 'Prova gratis 3 giorni →', 'tr': '3 gün ücretsiz dene →', 'pl': 'Wypróbuj za darmo 3 dni →',
      'ru': 'Попробовать 3 дня бесплатно →', 'ar': 'جرب مجاناً 3 أيام →',
      'en': 'Try free for 3 days →', 'pt': 'Experimentar grátis 3 dias →',
    },
    'trial_sub': {
      'de': '3 Tage kostenlos, dann €9,99/Woche. Jederzeit kündbar.',
      'es': '3 días gratis, luego €9,99/sem. Cancela cuando quieras.',
      'fr': '3 jours gratuits, puis €9,99/semaine. Annulable à tout moment.',
      'it': '3 giorni gratis, poi €9,99/settimana.',
      'tr': '3 gün ücretsiz, sonra €9,99/hafta.',
      'pl': '3 dni za darmo, potem €9,99/tydzień.',
      'ru': '3 дня бесплатно, затем €9,99/неделю.',
      'ar': '3 أيام مجاناً، ثم €9.99 أسبوعياً.',
      'en': '3 days free, then €9.99/week. Cancel anytime.',
      'pt': '3 dias grátis, depois €9.99/sem. Cancela quando quiseres.',
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
    'free_days': {
      'de': '✓  3 TAGE GRATIS', 'es': '✓  3 DÍAS GRATIS', 'fr': '✓  3 JOURS GRATUITS',
      'it': '✓  3 GIORNI GRATIS', 'tr': '✓  3 GÜN ÜCRETSİZ', 'pl': '✓  3 DNI GRATIS',
      'ru': '✓  3 ДНЯ БЕСПЛАТНО', 'ar': '✓  3 أيام مجاناً', 'en': '✓  3 DAYS FREE', 'pt': '✓  3 DIAS GRÁTIS',
    },
    'weekly': {
      'de': 'Wöchentlich', 'es': 'Semanal', 'fr': 'Hebdomadaire', 'it': 'Settimanale',
      'tr': 'Haftalık', 'pl': 'Tygodniowy', 'ru': 'Еженедельно', 'ar': 'أسبوعي',
      'en': 'Weekly', 'pt': 'Semanal',
    },
    'per_week': {
      'de': '/Wo', 'es': '/sem', 'fr': '/sem', 'it': '/sett',
      'tr': '/haf', 'pl': '/tydz', 'ru': '/нед', 'ar': '/أسبوع',
      'en': '/wk', 'pt': '/sem',
    },
    'today': {
      'de': 'Heute', 'es': 'Hoy', 'fr': "Aujourd'hui", 'it': 'Oggi',
      'tr': 'Bugün', 'pl': 'Dzisiaj', 'ru': 'Сегодня', 'ar': 'اليوم',
      'en': 'Today', 'pt': 'Hoje',
    },
    'after_trial': {
      'de': 'Nach Trial', 'es': 'Tras el trial', 'fr': 'Après le trial', 'it': 'Dopo il trial',
      'tr': 'Deneme sonrası', 'pl': 'Po próbie', 'ru': 'После пробного', 'ar': 'بعد التجربة',
      'en': 'After trial', 'pt': 'Após trial',
    },
    'welcome': {
      'de': 'Willkommen bei Premium! 🎉', 'es': '¡Bienvenido a Premium! 🎉', 'fr': 'Bienvenue dans Premium ! 🎉',
      'it': 'Benvenuto in Premium! 🎉', 'tr': "Premium'a hoş geldin! 🎉", 'pl': 'Witaj w Premium! 🎉',
      'ru': 'Добро пожаловать в Premium! 🎉', 'ar': 'مرحباً بك في Premium! 🎉',
      'en': 'Welcome to Premium! 🎉', 'pt': 'Bem-vindo ao Premium! 🎉',
    },
    'restored': {
      'de': 'Kauf wiederhergestellt! 🎉', 'es': '¡Compra restaurada! 🎉', 'fr': 'Achat restauré ! 🎉',
      'it': 'Acquisto ripristinato! 🎉', 'tr': 'Satın alma geri yüklendi! 🎉', 'pl': 'Zakup przywrócony! 🎉',
      'ru': 'Покупка восстановлена! 🎉', 'ar': 'تمت استعادة الشراء! 🎉',
      'en': 'Purchase restored! 🎉', 'pt': 'Compra restaurada! 🎉',
    },
    'no_purchase': {
      'de': 'Kein Kauf gefunden', 'es': 'No se encontró ninguna compra', 'fr': 'Aucun achat trouvé',
      'it': 'Nessun acquisto trovato', 'tr': 'Satın alma bulunamadı', 'pl': 'Nie znaleziono zakupu',
      'ru': 'Покупка не найдена', 'ar': 'لم يُعثر على أي شراء',
      'en': 'No purchase found', 'pt': 'Nenhuma compra encontrada',
    },
    'online': {
      'de': 'online', 'es': 'en línea', 'fr': 'en ligne', 'it': 'online',
      'tr': 'çevrimiçi', 'pl': 'online', 'ru': 'онлайн', 'ar': 'متصل',
      'en': 'online now', 'pt': 'online agora',
    },
    'h1': {
      'de': 'Mehr Dates.\nWeniger Zögern.', 'es': 'Más citas.\nMenos dudas.',
      'fr': "Plus de dates.\nMoins d'hésitation.", 'it': 'Più appuntamenti.\nMeno esitazione.',
      'tr': 'Daha fazla randevu.\nDaha az tereddüt.', 'pl': 'Więcej randek.\nMniej wahania.',
      'ru': 'Больше свиданий.\nМеньше сомнений.', 'ar': 'مواعيد أكثر.\nتردد أقل.',
      'en': 'More dates.\nLess hesitation.', 'pt': 'Mais datas.\nMenos hesitação.',
    },
    's1': {
      'de': 'Screenshot aufnehmen und in Sekunden die perfekte Antwort erhalten.',
      'es': 'Saca una captura y recibe la respuesta perfecta en segundos.',
      'fr': 'Prends une capture et reçois la réponse parfaite en secondes.',
      'it': 'Fai uno screenshot e ricevi la risposta perfetta in secondi.',
      'tr': 'Ekran görüntüsü al ve saniyeler içinde mükemmel yanıtı al.',
      'pl': 'Zrób zrzut ekranu i otrzymaj idealną odpowiedź w sekundy.',
      'ru': 'Сделай скриншот и получи идеальный ответ за секунды.',
      'ar': 'التقط صورة وتلقَّ الرد المثالي في ثوانٍ.',
      'en': 'Take a screenshot and get the perfect reply in seconds.',
      'pt': 'Tira um print e recebe a resposta perfeita em segundos.',
    },
    'h2': {
      'de': 'Dein persönlicher\nCoach 24/7.', 'es': 'Tu coach\npersonal 24/7.',
      'fr': 'Ton coach\npersonnel 24/7.', 'it': 'Il tuo coach\npersonale 24/7.',
      'tr': 'Kişisel\nkoçun 24/7.', 'pl': 'Twój osobisty\ncoach 24/7.',
      'ru': 'Твой личный\nкоуч 24/7.', 'ar': 'مدربك\nالشخصي 24/7.',
      'en': 'Your personal\ncoach 24/7.', 'pt': 'O teu coach\npessoal 24/7.',
    },
    's2': {
      'de': 'Analysiert die Situation und sagt dir genau, was zu tun ist.',
      'es': 'Analiza la situación y te dice exactamente qué hacer.',
      'fr': 'Analyse la situation et te dit exactement quoi faire.',
      'it': 'Analizza la situazione e ti dice esattamente cosa fare.',
      'tr': 'Durumu analiz eder ve tam olarak ne yapman gerektiğini söyler.',
      'pl': 'Analizuje sytuację i mówi ci dokładnie, co robić.',
      'ru': 'Анализирует ситуацию и говорит тебе что именно делать.',
      'ar': 'يحلل الموقف ويخبرك بالضبط بما يجب فعله.',
      'en': 'Analyzes the situation and tells you exactly what to do.',
      'pt': 'Analisa a situação e diz-te exactamente o que fazer.',
    },
    'coach_label': {
      'de': 'Dating Coach', 'es': 'Coach de Citas', 'fr': 'Coach de Dating', 'it': 'Coach di Dating',
      'tr': 'Flört Koçu', 'pl': 'Coach randkowy', 'ru': 'Коуч по свиданиям', 'ar': 'مدرب المواعيد',
      'en': 'Dating Coach', 'pt': 'Coach de Dating',
    },
    'coach_q': {
      'de': 'Sie hat mich seit 2 Tagen gesehen 😟', 'es': 'Me dejó en visto hace 2 días 😟',
      'fr': "Elle m'a vu il y a 2 jours 😟", 'it': 'Mi ha visto 2 giorni fa 😟',
      'tr': '2 gün önce gördü 😟', 'pl': 'Zostawiła mnie 2 dni temu 😟',
      'ru': 'Видела 2 дня назад 😟', 'ar': 'تركتني منذ يومين 😟',
      'en': 'She left me on seen 2 days ago 😟', 'pt': 'Ela deixou a ver há 2 dias 😟',
    },
    'coach_a': {
      'de': 'Schreib nicht. Sie testet dich. Warte 2 Tage. 🎯',
      'es': 'No la contactes. Te está probando. Espera 2 días. 🎯',
      'fr': 'Ne la contacte pas. Elle te teste. Attends 2 jours. 🎯',
      'it': 'Non scrivere. Ti sta testando. Aspetta 2 giorni. 🎯',
      'tr': 'Yazma. Seni test ediyor. 2 gün bekle. 🎯',
      'pl': 'Nie pisz. Testuje cię. Czekaj 2 dni. 🎯',
      'ru': 'Не пиши. Она проверяет тебя. Жди 2 дня. 🎯',
      'ar': 'لا تكتب. إنها تختبرك. انتظر يومين. 🎯',
      'en': "Don't text. She's testing you. Wait 2 days. 🎯",
      'pt': 'Não escrevas. Ela está a testar-te. Espera 2 dias. 🎯',
    },
    'convos': {
      'de': 'Gespräche\ngelöst', 'es': 'Conversaciones\nresueltas', 'fr': 'Conversations\nrésolues',
      'it': 'Conversazioni\nrisolte', 'tr': 'Çözülen\nkonuşmalar', 'pl': 'Rozmowy\nrozwiązane',
      'ru': 'Решённых\nразговоров', 'ar': 'محادثات\nمحلولة', 'en': 'Convos\nresolved', 'pt': 'Conversas\nresolvidas',
    },
    'reply_rate': {
      'de': 'Antwort-\nquote', 'es': 'Tasa de\nrespuesta', 'fr': 'Taux de\nréponse',
      'it': 'Tasso di\nrisposta', 'tr': 'Yanıt\noranı', 'pl': 'Wskaźnik\nodpowiedzi',
      'ru': 'Процент\nответов', 'ar': 'معدل\nالردود', 'en': 'Reply\nrate', 'pt': 'Taxa de\nresposta',
    },
    'always_on': {
      'de': 'Immer\nverfügbar', 'es': 'Siempre\ndisponible', 'fr': 'Toujours\ndisponible',
      'it': 'Sempre\ndisponibile', 'tr': 'Her zaman\nmevcut', 'pl': 'Zawsze\ndostępny',
      'ru': 'Всегда\nдоступен', 'ar': 'متاح\nدائماً', 'en': 'Always\non', 'pt': 'Sempre\ndisponível',
    },
    'generated': {
      'de': 'Von UpCrush AI generiert', 'es': 'Generado por UpCrush AI', 'fr': 'Généré par UpCrush AI',
      'it': 'Generato da UpCrush AI', 'tr': 'UpCrush AI tarafından', 'pl': 'Przez UpCrush AI',
      'ru': 'Создано UpCrush AI', 'ar': 'بواسطة UpCrush AI',
      'en': 'Generated by UpCrush AI', 'pt': 'Gerado pelo UpCrush AI',
    },
    'bubble1': {
      'de': 'Was machst du dieses Wochenende? 🙂', 'es': '¿Qué haces este fin de semana? 🙂',
      'fr': 'Tu fais quoi ce weekend? 🙂', 'it': 'Cosa fai questo weekend? 🙂',
      'tr': 'Bu hafta sonu ne yapıyorsun? 🙂', 'pl': 'Co robisz w ten weekend? 🙂',
      'ru': 'Что делаешь на выходных? 🙂', 'ar': 'ماذا تفعل هذا الأسبوع؟ 🙂',
      'en': 'What are you doing this weekend? 🙂', 'pt': 'O que estás a fazer este fim de semana? 🙂',
    },
    'bubble2': {
      'de': 'Nichts Besonderes...', 'es': 'Nada especial...', 'fr': 'Rien de spécial...',
      'it': 'Niente di speciale...', 'tr': 'Özel bir şey yok...', 'pl': 'Nic szczególnego...',
      'ru': 'Ничего особенного...', 'ar': 'لا شيء خاص...', 'en': 'Nothing special...', 'pt': 'Nada de especial...',
    },
    'bubble3': {
      'de': 'Keine Pläne? 😏', 'es': '¿Sin planes? 😏', 'fr': 'Pas de plans? 😏',
      'it': 'Nessun piano? 😏', 'tr': 'Plan yok mu? 😏', 'pl': 'Brak planów? 😏',
      'ru': 'Нет планов? 😏', 'ar': 'لا خطط؟ 😏', 'en': 'No plans? 😏', 'pt': 'Sem planos? 😏',
    },
    'bubble4': {
      'de': 'Doch — lad mich ein 😈', 'es': 'Sí — invítame 😈', 'fr': 'Si — invite-moi 😈',
      'it': 'Sì — invitami 😈', 'tr': 'Var — beni davet et 😈', 'pl': 'Mam — zaproś mnie 😈',
      'ru': 'Есть — пригласи 😈', 'ar': 'لدي — ادعني 😈', 'en': 'I do — invite me 😈', 'pt': 'Tenho — convida-me 😈',
    },
  };
}