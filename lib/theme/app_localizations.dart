import 'dart:ui';

class AppLocalizations {
  final String languageCode;

  AppLocalizations(this.languageCode);

  // Todos os idiomas suportados
  static const List<String> _supported = [
    'en', 'pt', 'de', 'es', 'fr', 'it', 'tr', 'pl', 'ru', 'ar',
  ];

  // Detecta automaticamente pelo idioma do sistema
  factory AppLocalizations.fromDevice() {
    final locale = PlatformDispatcher.instance.locale;
    final code = locale.languageCode.toLowerCase();

    // Mapeamento de variantes regionais
    const Map<String, String> variants = {
      'pt': 'pt', // pt, pt_PT, pt_BR
      'de': 'de', // de, de_AT, de_CH
      'es': 'es', // es, es_MX, es_AR...
      'fr': 'fr', // fr, fr_BE, fr_CH...
      'it': 'it',
      'tr': 'tr',
      'pl': 'pl',
      'ru': 'ru',
      'ar': 'ar', // ar, ar_SA, ar_EG...
      'en': 'en',
    };

    return AppLocalizations(variants[code] ?? 'en');
  }

  // Helper com fallback para inglês — nunca crasha
  String _t(Map<String, String> map) =>
      map[languageCode] ?? map['en'] ?? '';

  // ─── HOME SCREEN ──────────────────────────────────────────────────────────
  String get appTagline => _t(const {
    'de': 'Dein digitaler Wingman',
    'pt': 'O teu copiloto de conversa',
    'es': 'Tu copiloto de conversación',
    'en': 'Your digital wingman',

    'fr':'Ton assistant de conversation',
    'it':'Il tuo assistente digitale',
    'pl':'Twój cyfrowy pomocnik',
    'ru':'Твой цифровой помощник',
    'tr':'Dijital yardımcın',
    'ar':'مساعدك الرقمي',
  });

  String get featureScreenshot => _t(const {
    'de': 'Screenshot analysieren',
    'pt': 'Analisar Screenshot',
    'es': 'Analizar Screenshot',
    'en': 'Analyze Screenshot',

    'fr':'Analyser la capture',
    'it':'Analizza Screenshot',
    'pl':'Analizuj zrzut ekranu',
    'ru':'Анализ скриншота',
    'tr':'Ekran görüntüsü analiz',
    'ar':'تحليل لقطة الشاشة',
  });

  String get featureScreenshotSub => _t(const {
    'de': 'KI analysiert dein Gespräch',
    'pt': 'IA analisa a tua conversa',
    'es': 'IA analiza tu conversación',
    'en': 'AI analyzes your conversation',

    'fr':"L'IA analyse ta conversation",
    'it':"L'IA analizza la tua conversazione",
    'pl':'AI analizuje twoją rozmowę',
    'ru':'ИИ анализирует твой разговор',
    'tr':'AI konuşmanı analiz eder',
    'ar':'الذكاء الاصطناعي يحلل محادثتك',
  });

  String get featurePasteText => _t(const {
    'de': 'Text einfügen',
    'pt': 'Colar texto',
    'es': 'Pegar texto',
    'en': 'Paste text',

    'fr':'Coller le texte',
    'it':'Incolla testo',
    'pl':'Wklej tekst',
    'ru':'Вставить текст',
    'tr':'Metin yapıştır',
    'ar':'لصق النص',
  });

  String get featurePasteTextSub => _t(const {
    'de': 'Gespräch manuell eingeben',
    'pt': 'Cola a conversa manualmente',
    'es': 'Pega la conversación manualmente',
    'en': 'Paste the conversation manually',

    'fr':'Colle la conversation manuellement',
    'it':'Incolla la conversazione manualmente',
    'pl':'Wklej rozmowę ręcznie',
    'ru':'Вставьте разговор вручную',
    'tr':'Konuşmayı manuel yapıştır',
    'ar':'الصق المحادثة يدوياً',
  });

  String get featureOpener => _t(const {
    'de': 'Opener erstellen',
    'pt': 'Criar abertura',
    'es': 'Crear apertura',
    'en': 'Create opener',

    'fr':'Créer une accroche',
    'it':'Crea un opener',
    'pl':'Stwórz opener',
    'ru':'Создать opener',
    'tr':'Opener oluştur',
    'ar':'إنشاء رسالة افتتاحية',
  });

  String get featureOpenerSub => _t(const {
    'de': 'Perfekte erste Nachricht generieren',
    'pt': 'Gera a primeira mensagem perfeita',
    'es': 'Genera el primer mensaje perfecto',
    'en': 'Generate the perfect first message',

    'fr':'Génère le premier message parfait',
    'it':'Genera il primo messaggio perfetto',
    'pl':'Wygeneruj idealną pierwszą wiadomość',
    'ru':'Создай идеальное первое сообщение',
    'tr':'Mükemmel ilk mesajı oluştur',
    'ar':'أنشئ الرسالة الأولى المثالية',
  });

  // ─── TONS ─────────────────────────────────────────────────────────────────
  String get toneNatural => _t(const {
    'de': 'Natürlich',
    'pt': 'Natural',
    'es': 'Natural',
    'en': 'Natural',

    'fr':'Naturel',
    'it':'Naturale',
    'pl':'Naturalny',
    'ru':'Естественный',
    'tr':'Doğal',
    'ar':'طبيعي',
  });

  String get toneCharming => _t(const {
    'de': 'Charmant',
    'pt': 'Charmoso',
    'es': 'Encantador',
    'en': 'Charming',

    'fr':'Charmant',
    'it':'Affascinante',
    'pl':'Czarujący',
    'ru':'Обаятельный',
    'tr':'Çekici',
    'ar':'ساحر',
  });

  String get toneFunny => _t(const {
    'de': 'Lustig',
    'pt': 'Engraçado',
    'es': 'Gracioso',
    'en': 'Funny',

    'fr':'Drôle',
    'it':'Divertente',
    'pl':'Śmieszny',
    'ru':'Смешной',
    'tr':'Komik',
    'ar':'مضحك',
  });

  String get toneDirect => _t(const {
    'de': 'Direkt',
    'pt': 'Direto',
    'es': 'Directo',
    'en': 'Direct',

    'fr':'Direct',
    'it':'Diretto',
    'pl':'Bezpośredni',
    'ru':'Прямой',
    'tr':'Doğrudan',
    'ar':'مباشر',
  });

  String get toneMysterious => _t(const {
    'de': 'Geheimnisvoll',
    'pt': 'Misterioso',
    'es': 'Misterioso',
    'en': 'Mysterious',

    'fr':'Mystérieux',
    'it':'Misterioso',
    'pl':'Tajemniczy',
    'ru':'Загадочный',
    'tr':'Gizemli',
    'ar':'غامض',
  });

  // ─── SCREENSHOT SCREEN ────────────────────────────────────────────────────
  String get screenshotTitle => _t(const {
    'de': 'Gespräch analysieren',
    'pt': 'Analisar conversa',
    'es': 'Analizar conversación',
    'en': 'Analyze conversation',

    'fr':'Analyser la conversation',
    'it':'Analizza conversazione',
    'pl':'Analizuj rozmowę',
    'ru':'Анализ разговора',
    'tr':'Konuşmayı analiz et',
    'ar':'تحليل المحادثة',
  });

  String get screenshotInstruction => _t(const {
    'de': 'Screenshot des Gesprächs aufnehmen',
    'pt': 'Tira print da conversa',
    'es': 'Toma captura de pantalla',
    'en': 'Take a screenshot of the conversation',

    'fr':"Prends une capture d'écran",
    'it':'Fai uno screenshot della conversazione',
    'pl':'Zrób zrzut ekranu rozmowy',
    'ru':'Сделай скриншот разговора',
    'tr':'Konuşmanın ekran görüntüsünü al',
    'ar':'التقط لقطة شاشة للمحادثة',
  });

  String get screenshotInstructionSub => _t(const {
    'de': 'Die KI erkennt automatisch, wer wer ist',
    'pt': 'A IA identifica automaticamente quem é quem',
    'es': 'La IA identifica automáticamente quién es quién',
    'en': 'AI automatically identifies who is who',

    'fr':"L'IA identifie automatiquement qui est qui",
    'it':"L'IA identifica automaticamente chi è chi",
    'pl':'AI automatycznie identyfikuje kto jest kim',
    'ru':'ИИ автоматически определяет кто есть кто',
    'tr':'AI otomatik olarak kimin kim olduğunu tanımlar',
    'ar':'يحدد الذكاء الاصطناعي تلقائياً من هو من',
  });

  String get screenshotButton => _t(const {
    'de': 'Bild auswählen',
    'pt': 'Escolher print',
    'es': 'Elegir imagen',
    'en': 'Choose image',

    'fr':'Choisir image',
    'it':'Scegli immagine',
    'pl':'Wybierz obraz',
    'ru':'Выбрать изображение',
    'tr':'Resim seç',
    'ar':'اختر صورة',
  });

  String get screenshotAnalyzing => _t(const {
    'de': 'KI analysiert das Gespräch',
    'pt': 'IA a analisar a conversa',
    'es': 'IA analizando la conversación',
    'en': 'AI analyzing conversation',

    'fr':"IA en train d'analyser",
    'it':'IA sta analizzando',
    'pl':'AI analizuje rozmowę',
    'ru':'ИИ анализирует разговор',
    'tr':'AI konuşmayı analiz ediyor',
    'ar':'الذكاء الاصطناعي يحلل المحادثة',
  });

  String get screenshotAnalyzingSub => _t(const {
    'de': 'Nachrichten werden erkannt und die besten Antworten generiert...',
    'pt': 'Identificando mensagens e gerando as melhores respostas...',
    'es': 'Identificando mensajes y generando las mejores respuestas...',
    'en': 'Identifying messages and generating the best responses...',

    'fr':'Identification des messages et génération des meilleures réponses...',
    'it':'Identificazione messaggi e generazione risposte migliori...',
    'pl':'Identyfikowanie wiadomości i generowanie najlepszych odpowiedzi...',
    'ru':'Определение сообщений и генерация лучших ответов...',
    'tr':'Mesajlar tanımlanıyor ve en iyi yanıtlar oluşturuluyor...',
    'ar':'تحديد الرسائل وإنشاء أفضل الردود...',
  });

  // ─── PASTE TEXT SCREEN ────────────────────────────────────────────────────
  String get pasteTitle => _t(const {
    'de': 'Text einfügen',
    'pt': 'Colar texto',
    'es': 'Pegar texto',
    'en': 'Paste text',

    'fr':'Coller le texte',
    'it':'Incolla testo',
    'pl':'Wklej tekst',
    'ru':'Вставить текст',
    'tr':'Metin yapıştır',
    'ar':'لصق النص',
  });

  String get pasteLabel => _t(const {
    'de': 'Gespräch hier einfügen',
    'pt': 'Cola a conversa aqui',
    'es': 'Pega la conversación aquí',
    'en': 'Paste the conversation here',

    'fr':'Colle la conversation ici',
    'it':'Incolla la conversazione qui',
    'pl':'Wklej rozmowę tutaj',
    'ru':'Вставьте разговор сюда',
    'tr':'Konuşmayı buraya yapıştır',
    'ar':'الصق المحادثة هنا',
  });

  String get pasteHint => _t(const {
    'en': "Her: hey how are you?\nMe: good thanks! you?\nHer: good haha",
    'de': "Sie: Hey, wie geht's?\nIch: Gut, danke! Und dir?",
    'pt': "Ela: oi tudo bem?\nEu: tudo sim e vc?\nEla: tô bem haha",
    'es': "Ella: hola qué tal?\nYo: bien y tú?\nElla: bien jaja",
    'fr': "Elle: salut ça va?\nMoi: bien merci! et toi?\nElle: bien haha",
    'it': "Lei: ciao come stai?\nIo: bene grazie! tu?\nLei: bene haha",
    'pl': "Ona: hej jak sie masz?\nJa: dobrze dzieki! ty?\nOna: dobrze haha",
    'ru': "Ona: privet kak dela?\nYa: horosho spasibo! ty?\nOna: horosho haha",
    'tr': "O: hey nasilsin?\nBen: iyiyim tesekkurler! sen?\nO: iyi haha",
    'ar': "Hi: marhaba kayfa haluk?\nAna: bikhayr shukran!\nHi: bikhayr haha",
  });

  String get toneLabel => _t(const {
    'de': 'Antwort-Stil',
    'pt': 'Tom da resposta',
    'es': 'Tono de respuesta',
    'en': 'Response tone',

    'fr':'Ton de réponse',
    'it':'Tono della risposta',
    'pl':'Ton odpowiedzi',
    'ru':'Тон ответа',
    'tr':'Yanıt tonu',
    'ar':'نبرة الرد',
  });

  String get generateButton => _t(const {
    'de': 'Antworten generieren',
    'pt': 'Gerar respostas',
    'es': 'Generar respuestas',
    'en': 'Generate responses',

    'fr':'Générer des réponses',
    'it':'Genera risposte',
    'pl':'Generuj odpowiedzi',
    'ru':'Создать ответы',
    'tr':'Yanıt oluştur',
    'ar':'إنشاء ردود',
  });

  // ─── OPENER SCREEN ────────────────────────────────────────────────────────
  String get openerTitle => _t(const {
    'de': 'Opener erstellen',
    'pt': 'Criar abertura',
    'es': 'Crear apertura',
    'en': 'Create opener',

    'fr':'Créer une accroche',
    'it':'Crea opener',
    'pl':'Stwórz opener',
    'ru':'Создать opener',
    'tr':'Opener oluştur',
    'ar':'إنشاء رسالة افتتاحية',
  });

  String get openerTip => _t(const {
    'de': 'Je mehr Details über ihr Profil, desto besser der Opener',
    'pt': 'Quanto mais detalhes do perfil dela, melhor o opener',
    'es': 'Cuantos más detalles del perfil, mejor el opener',
    'en': 'The more profile details, the better the opener',

    'fr':"Plus de détails sur son profil, meilleure sera l'accroche",
    'it':"Più dettagli sul profilo, migliore sarà l\'opener",
    'pl':'Im więcej szczegółów profilu, tym lepszy opener',
    'ru':'Чем больше деталей профиля, тем лучше opener',
    'tr':'Profil detayları ne kadar fazlaysa opener o kadar iyi olur',
    'ar':'كلما زادت تفاصيل الملف الشخصي كانت الرسالة أفضل',
  });

  String get openerLabel => _t(const {
    'de': 'Ihr Profil beschreiben',
    'pt': 'Descreve o perfil dela',
    'es': 'Describe su perfil',
    'en': 'Describe her profile',

    'fr':'Décris son profil',
    'it':'Descrivi il suo profilo',
    'pl':'Opisz jej profil',
    'ru':'Опиши её профиль',
    'tr':'Onun profilini tanımla',
    'ar':'صف ملفها الشخصي',
  });

  String get openerHint => _t(const {
    'de': 'z.B. Reisefotos, liebt Sushi, arbeitet im Marketing, hat einen Hund...',
    'pt': 'Ex: tem fotos viajando, adora sushi, trabalha com marketing, tem um cachorro...',
    'es': 'Ej: fotos viajando, ama el sushi, trabaja en marketing, tiene un perro...',
    'en': 'E.g. travel photos, loves sushi, works in marketing, has a dog...',

    'fr':'Ex: photos de voyage, adore les sushis, travaille en marketing, a un chien...',
    'it':'Es: foto di viaggio, ama il sushi, lavora nel marketing, ha un cane...',
    'pl':'Np: zdjęcia z podróży, uwielbia sushi, pracuje w marketingu, ma psa...',
    'ru':'Напр: фото путешествий, любит суши, работает в маркетинге, есть собака...',
    'tr':'Örn: seyahat fotoğrafları, sushi sever, pazarlamada çalışır, köpeği var...',
    'ar':'مثال: صور السفر، تحب السوشي، تعمل في التسويق، لديها كلب...',
  });

  String get openerStyleLabel => _t(const {
    'de': 'Opener-Stil',
    'pt': 'Estilo do opener',
    'es': 'Estilo del opener',
    'en': 'Opener style',

    'fr':"Style de l'accroche",
    'it':"Stile dell'opener",
    'pl':'Styl openera',
    'ru':'Стиль opener',
    'tr':'Opener stili',
    'ar':'أسلوب الرسالة',
  });

  String get openerButton => _t(const {
    'de': 'Opener generieren',
    'pt': 'Gerar abertura',
    'es': 'Generar apertura',
    'en': 'Generate opener',

    'fr':"Générer l'accroche",
    'it':'Genera opener',
    'pl':'Generuj opener',
    'ru':'Создать opener',
    'tr':'Opener oluştur',
    'ar':'إنشاء الرسالة',
  });

  // ─── RESULT SCREEN ────────────────────────────────────────────────────────
  String get resultGenerating => _t(const {
    'de': 'Antworten werden generiert...',
    'pt': 'Gerando respostas...',
    'es': 'Generando respuestas...',
    'en': 'Generating responses...',

    'fr':'Génération des réponses...',
    'it':'Generazione risposte...',
    'pl':'Generowanie odpowiedzi...',
    'ru':'Генерация ответов...',
    'tr':'Yanıtlar oluşturuluyor...',
    'ar':'جارٍ إنشاء الردود...',
  });

  String get resultCopy => _t(const {
    'de': 'Kopieren',
    'pt': 'Copiar',
    'es': 'Copiar',
    'en': 'Copy',

    'fr':'Copier',
    'it':'Copia',
    'pl':'Kopiuj',
    'ru':'Копировать',
    'tr':'Kopyala',
    'ar':'نسخ',
  });

  String get resultCopied => _t(const {
    'de': '✓ Kopiert',
    'pt': '✓ Copiado',
    'es': '✓ Copiado',
    'en': '✓ Copied',

    'fr':'✓ Copié',
    'it':'✓ Copiato',
    'pl':'✓ Skopiowano',
    'ru':'✓ Скопировано',
    'tr':'✓ Kopyalandı',
    'ar':'✓ تم النسخ',
  });

  String get resultMoreButton => _t(const {
    'de': 'Mehr Antworten generieren',
    'pt': 'Gerar mais respostas',
    'es': 'Generar más respuestas',
    'en': 'Generate more responses',

    'fr':'Générer plus de réponses',
    'it':'Genera altre risposte',
    'pl':'Generuj więcej odpowiedzi',
    'ru':'Создать больше ответов',
    'tr':'Daha fazla yanıt oluştur',
    'ar':'إنشاء ردود أكثر',
  });

  String get resultSheLabel => _t(const {
    'de': 'Sie',
    'pt': 'Ela',
    'es': 'Ella',
    'en': 'Her',

    'fr':'Elle',
    'it':'Lei',
    'pl':'Ona',
    'ru':'Она',
    'tr':'O',
    'ar':'هي',
  });

  // ─── ERROS ────────────────────────────────────────────────────────────────
  String get errorGeneral => _t(const {
    'en': "Something went wrong.\nCheck your connection and try again.",
    'de': "Etwas ist schiefgelaufen.\nBitte Verbindung pruefen und nochmal versuchen.",
    'pt': "Algo deu errado.\nVerifica a tua conexao e tenta novamente.",
    'es': "Algo salio mal.\nVerifica tu conexion e intenta de nuevo.",
    'fr': "Quelque chose s est mal passe.\nVerifie ta connexion et reessaie.",
    'it': "Qualcosa e andato storto.\nControlla la connessione e riprova.",
    'pl': "Cos poszlo nie tak.\nSprawdz polaczenie i sprobuj ponownie.",
    'ru': "Что-то пошло не так.\nПроверь соединение и попробуй снова.",
    'tr': "Bir seyler ters gitti.\nBaglantini kontrol et ve tekrar dene.",
    'ar': "حدث خطأ ما.\nتحقق من اتصالك وحاول مرة أخرى.",
  });

  String get errorRetry => _t(const {
    'de': 'Nochmal versuchen',
    'pt': 'Tentar novamente',
    'es': 'Intentar de nuevo',
    'en': 'Try again',

    'fr':'Réessayer',
    'it':'Riprova',
    'pl':'Spróbuj ponownie',
    'ru':'Попробовать снова',
    'tr':'Tekrar dene',
    'ar':'حاول مرة أخرى',
  });

  String get errorBack => _t(const {
    'de': 'Zurück',
    'pt': 'Voltar',
    'es': 'Volver',
    'en': 'Back',

    'fr':'Retour',
    'it':'Indietro',
    'pl':'Wstecz',
    'ru':'Назад',
    'tr':'Geri',
    'ar':'رجوع',
  });
}