import '../config.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

class AIService {
static const String _openAiKey = Config.openAiKey;
static const String _anthropicKey = Config.anthropicKey;

// ============================================================
// CONFIG
// ============================================================

// Modelo principal das outras funcionalidades.
static const String _openAiModel = 'gpt-5.6-sol';
static const String _anthropicModel = 'claude-opus-4-8';

// Modelo específico para CANTADAS / PICK LINES.
// Mantido separado para não alterar as outras funcionalidades.
static const String _openAiModelPickLine = 'gpt-5.6-luna';
static const String _anthropicModelPickLine =
'claude-haiku-4-5-20251001';

static const Map<String, String> _idiomaNomes = {
'en': 'English',
'pt': 'Brazilian Portuguese',
'de': 'German',
'es': 'Spanish',
'fr': 'French',
'it': 'Italian',
'tr': 'Turkish',
'pl': 'Polish',
'ru': 'Russian',
'ar': 'Arabic',
};

static const Map<String, String> _idiomaCultura = {
'en':
'Use natural contemporary English dating-app communication. Avoid stereotypes.',
'pt':
'Use natural contemporary Brazilian Portuguese. Casual, fluid and culturally natural. Avoid forced slang.',
'de':
'Use natural contemporary German dating-app communication. Direct when appropriate, but not artificially blunt.',
'es':
'Use natural contemporary Spanish dating-app communication. Warm, playful and natural.',
'fr':
'Use natural contemporary French dating-app communication. Natural, witty and relaxed.',
'it':
'Use natural contemporary Italian dating-app communication. Warm, playful and confident.',
'tr':
'Use natural contemporary Turkish dating-app communication. Confident and respectful.',
'pl':
'Use natural contemporary Polish dating-app communication. Natural, direct and genuine.',
'ru':
'Use natural contemporary Russian dating-app communication. Natural, confident and genuine.',
'ar':
'Use natural contemporary Arabic dating-app communication. Respectful, warm and confident.',
};

// ============================================================
// PICK LINE CATEGORIES
// ============================================================

static const List<String> cantadaCategoriaKeys = [
'elogios_duplo_sentido',
'meio_da_conversa',
'abordagem_rua',
'respondendo_story',
'conhecida',
'esta_rindo',
'te_olha_varias_vezes',
'mexe_no_cabelo',
'provoca_voce',
'diz_que_bonito',
'diz_que_engracado',
'diz_nao_interessado',
'elogios_coragem',
'flerte_festa',
'ambiente_a_favor',
'elogios_provocacao',
'elogios_ousados',
'conversa_esfriou',
'monossilabos',
'primeira_msg_match',
'match_sumiu',
'pedir_numero_instagram',
'convidar_sair',
'confirmar_date',
'depois_ignorada',
'testando_voce',
'depois_primeiro_encontro',
'elogio_primeiro_date',
'retomar_conversa_antiga',

// NOVA CATEGORIA
'criar_curiosidade',

// INICIAR UMA CONVERSA
'dar_bom_dia',
'dar_boa_tarde',
'dar_boa_noite',
'como_foi_seu_dia',
'puxar_assunto_do_nada',
'comecar_com_quem_gosto',
];

static const Map<String, Map<String, String>> _cantadaCategoriaNomes = {
'elogios_duplo_sentido': {
'pt': 'Duplo sentido 😏',
'en': 'Compliments with double meaning',
'de': 'Komplimente mit Doppeldeutigkeit',
'es': 'Elogios con doble sentido',
'fr': 'Compliments à double sens',
'it': 'Complimenti a doppio senso',
'tr': 'Çift anlamlı iltifatlar',
'pl': 'Komplementy z podwójnym znaczeniem',
'ru': 'Комплименты с двойным смыслом',
'ar': 'مجاملات ذات معنى مزدوج',
},
'meio_da_conversa': {
'pt': 'Esquentar a conversa 🔥',
'en': 'Mid-conversation',
'de': 'Mitten im Gespräch',
'es': 'En medio de la conversación',
'fr': 'Au milieu de la conversation',
'it': 'Nel mezzo della conversazione',
'tr': 'Sohbetin ortasında',
'pl': 'W trakcie rozmowy',
'ru': 'В середине разговора',
'ar': 'في منتصف المحادثة',
},
'abordagem_rua': {
'pt': 'Chegar pessoalmente 👀',
'en': 'Street approach',
'de': 'Ansprache auf der Straße',
'es': 'Abordaje en la calle',
'fr': 'Approche dans la rue',
'it': 'Approccio in strada',
'tr': 'Sokakta yaklaşım',
'pl': 'Podryw na ulicy',
'ru': 'Знакомство на улице',
'ar': 'التعارف في الشارع',
},
'respondendo_story': {
'pt': 'Responder story 📲',
'en': 'Replying to a story',
'de': 'Auf eine Story antworten',
'es': 'Respondiendo a un story',
'fr': 'Répondre à une story',
'it': 'Rispondere a una storia',
'tr': 'Hikayeye cevap verme',
'pl': 'Odpowiadanie na relację',
'ru': 'Ответ на историю',
'ar': 'الرد على القصة',
},
'conhecida': {
'pt': 'Já se conhecem 😉',
'en': 'Someone you know',
'de': 'Bekannte Person',
'es': 'Conocida/o',
'fr': 'Connaissance',
'it': 'Conoscente',
'tr': 'Tanıdık biri',
'pl': 'Znajoma/y',
'ru': 'Знакомый человек',
'ar': 'شخص تعرفه',
},
'esta_rindo': {
'pt': 'Ela/ele está rindo 😂',
'en': 'They are laughing',
'de': 'Sie/er lacht',
'es': 'Ella/él se está riendo',
'fr': 'Elle/il rit',
'it': 'Sta ridendo',
'tr': 'Gülüyor',
'pl': 'Ona/on się śmieje',
'ru': 'Она/он смеётся',
'ar': 'هو/هي يضحك',
},
'te_olha_varias_vezes': {
'pt': 'Troca de olhares 👀',
'en': 'They keep looking at you',
'de': 'Sie/er schaut dich immer wieder an',
'es': 'Ella/él te mira varias veces',
'fr': 'Elle/il te regarde plusieurs fois',
'it': 'Continua a guardarti',
'tr': 'Sürekli sana bakıyor',
'pl': 'Ona/on ciągle na ciebie patrzy',
'ru': 'Она/он всё время на тебя смотрит',
'ar': 'ينظر إليك مرارًا',
},
'mexe_no_cabelo': {
'pt': 'Mexe no cabelo 😏',
'en': 'They play with their hair while talking',
'de': 'Sie/er spielt beim Reden mit den Haaren',
'es': 'Ella/él juega con el pelo al hablar',
'fr': 'Elle/il joue avec ses cheveux en parlant',
'it': 'Gioca con i capelli mentre parla',
'tr': 'Konuşurken saçıyla oynuyor',
'pl': 'Ona/on bawi się włosami podczas rozmowy',
'ru': 'Она/он крутит волосы во время разговора',
'ar': 'يعبث بشعره أثناء الحديث',
},
'provoca_voce': {
'pt': 'Ela/ele te provoca 😈',
'en': 'They tease you',
'de': 'Sie/er neckt dich',
'es': 'Ella/él te provoca',
'fr': 'Elle/il te taquine',
'it': 'Ti provoca',
'tr': 'Seninle takılıyor',
'pl': 'Ona/on cię prowokuje',
'ru': 'Она/он тебя дразнит',
'ar': 'يستفزك',
},
'diz_que_bonito': {
'pt': 'Ela/ele te elogiou 😏',
'en': 'They say you are attractive',
'de': 'Sie/er sagt, du bist attraktiv',
'es': 'Ella/él dice que eres guapo/a',
'fr': 'Elle/il dit que tu es beau/belle',
'it': 'Dice che sei bello/a',
'tr': 'Yakışıklı/güzel olduğunu söylüyor',
'pl': 'Ona/on mówi, że jesteś atrakcyjna/y',
'ru': 'Она/он говорит, что ты привлекательный(ая)',
'ar': 'يقول إنك جذاب',
},
'diz_que_engracado': {
'pt': 'Ela/ele te acha engraçado 😂',
'en': 'They say you are funny',
'de': 'Sie/er sagt, du bist lustig',
'es': 'Ella/él dice que eres gracioso/a',
'fr': 'Elle/il dit que tu es drôle',
'it': 'Dice che sei divertente',
'tr': 'Komik olduğunu söylüyor',
'pl': 'Ona/on mówi, że jesteś zabawna/y',
'ru': 'Она/он говорит, что ты смешной(ая)',
'ar': 'يقول إنك مضحك',
},
'diz_nao_interessado': {
'pt': 'Não está interessada/o',
'en': 'They say they are not interested',
'de': 'Sie/er sagt, sie/er hat kein Interesse',
'es': 'Ella/él dice que no está interesada/o',
'fr': 'Elle/il dit qu’elle/il n’est pas intéressé(e)',
'it': 'Dice di non essere interessato/a',
'tr': 'İlgilenmediğini söylüyor',
'pl': 'Ona/on mówi, że nie jest zainteresowana/y',
'ru': 'Она/он говорит, что не заинтересован(а)',
'ar': 'يقول إنه غير مهتم',
},
'elogios_coragem': {
'pt': 'Mostrar interesse 🔥',
'en': 'Compliments on boldness',
'de': 'Komplimente für Mut',
'es': 'Elogios de valentía',
'fr': 'Compliments sur le courage',
'it': 'Complimenti per il coraggio',
'tr': 'Cesaret iltifatları',
'pl': 'Komplementy za odwagę',
'ru': 'Комплименты за смелость',
'ar': 'مجاملات على الشجاعة',
},
'flerte_festa': {
'pt': 'Flerte na festa 🪩',
'en': 'Party flirting',
'de': 'Flirten auf der Party',
'es': 'Coqueteo para fiesta',
'fr': 'Flirt en soirée',
'it': 'Flirt in festa',
'tr': 'Parti flörtü',
'pl': 'Flirt na imprezie',
'ru': 'Флирт на вечеринке',
'ar': 'غزل في الحفلة',
},
'ambiente_a_favor': {
'pt': 'Usar o momento 👀',
'en': 'Using the environment to your advantage',
'de': 'Die Umgebung zu deinem Vorteil nutzen',
'es': 'Usando el entorno a tu favor',
'fr': 'Utiliser l’environnement à ton avantage',
'it': 'Usare l’ambiente a tuo favore',
'tr': 'Ortamı avantajına kullanma',
'pl': 'Wykorzystanie otoczenia na swoją korzyść',
'ru': 'Использование обстановки в свою пользу',
'ar': 'استخدام البيئة لصالحك',
},
'elogios_provocacao': {
'pt': 'Provocar ela/ele 😈',
'en': 'Teasing compliments',
'de': 'Neckende Komplimente',
'es': 'Elogios provocadores',
'fr': 'Compliments taquins',
'it': 'Complimenti provocatori',
'tr': 'Takılma iltifatları',
'pl': 'Prowokacyjne komplementy',
'ru': 'Дразнящие комплименты',
'ar': 'مجاملات استفزازية',
},
'elogios_ousados': {
'pt': 'Aumentar a tensão 🫦',
'en': 'Bold compliments',
'de': 'Mutige Komplimente',
'es': 'Elogios atrevidos',
'fr': 'Compliments audacieux',
'it': 'Complimenti audaci',
'tr': 'Cesur iltifatlar',
'pl': 'Odważne komplementy',
'ru': 'Смелые комплименты',
'ar': 'مجاملات جريئة',
},
'conversa_esfriou': {
'pt': 'Conversa esfriou 🥶',
'en': 'Conversation that went cold',
'de': 'Gespräch ist eingeschlafen',
'es': 'Conversación que se enfrió',
'fr': 'Conversation qui s’est refroidie',
'it': 'Conversazione che si è raffreddata',
'tr': 'Soğuyan sohbet',
'pl': 'Rozmowa, która wystygła',
'ru': 'Разговор, который остыл',
'ar': 'محادثة بردت',
},
'monossilabos': {
'pt': 'Respostas secas 😶',
'en': 'They reply with one-word answers',
'de': 'Sie/er antwortet einsilbig',
'es': 'Ella/él responde con monosílabos',
'fr': 'Elle/il répond avec des réponses courtes',
'it': 'Risponde a monosillabi',
'tr': 'Tek kelimeyle cevap veriyor',
'pl': 'Ona/on odpowiada monosylabami',
'ru': 'Она/он отвечает односложно',
'ar': 'يرد بكلمة واحدة',
},
'primeira_msg_match': {
'pt': 'Depois do match 💘',
'en': 'First message after the match',
'de': 'Erste Nachricht nach dem Match',
'es': 'Primer mensaje después del match',
'fr': 'Premier message après le match',
'it': 'Primo messaggio dopo il match',
'tr': 'Eşleşmeden sonraki ilk mesaj',
'pl': 'Pierwsza wiadomość po dopasowaniu',
'ru': 'Первое сообщение после мэтча',
'ar': 'أول رسالة بعد التطابق',
},
'match_sumiu': {
'pt': 'Match sumiu 👻',
'en': 'After the match, they went quiet',
'de': 'Nach dem Match verschwunden',
'es': 'Después del match y desapareció',
'fr': 'Après le match, silence radio',
'it': 'Dopo il match è sparito/a',
'tr': 'Eşleştikten sonra kayboldu',
'pl': 'Po dopasowaniu zniknęła/zniknął',
'ru': 'После мэтча пропал(а)',
'ar': 'اختفى بعد التطابق',
},
'pedir_numero_instagram': {
'pt': 'Pedir Instagram 📲',
'en': 'Asking for their number or Instagram',
'de': 'Nach Nummer oder Instagram fragen',
'es': 'Pedir el número o Instagram',
'fr': 'Demander le numéro ou Instagram',
'it': 'Chiedere il numero o Instagram',
'tr': 'Numara veya Instagram isteme',
'pl': 'Prośba o numer lub Instagram',
'ru': 'Просьба дать номер или Instagram',
'ar': 'طلب الرقم أو الإنستغرام',
},
'convidar_sair': {
'pt': 'Chamar pra sair 🍸',
'en': 'Asking them out',
'de': 'Zum Date einladen',
'es': 'Invitar a salir',
'fr': 'Inviter à sortir',
'it': 'Invitare a uscire',
'tr': 'Çıkmaya davet etme',
'pl': 'Zaproszenie na randkę',
'ru': 'Приглашение на свидание',
'ar': 'دعوة للخروج',
},
'confirmar_date': {
'pt': 'Confirmar o date 📅',
'en': 'Confirming a planned date',
'de': 'Ein geplantes Date bestätigen',
'es': 'Confirmar una cita ya planeada',
'fr': 'Confirmer un rendez-vous déjà prévu',
'it': 'Confermare un appuntamento già fissato',
'tr': 'Planlanmış randevuyu onaylama',
'pl': 'Potwierdzenie zaplanowanej randki',
'ru': 'Подтверждение запланированного свидания',
'ar': 'تأكيد موعد مخطط له',
},
'depois_ignorada': {
'pt': 'Fui ignorado 👻',
'en': 'After being left on read',
'de': 'Nachdem man ignoriert wurde',
'es': 'Después de ser ignorada/o',
'fr': 'Après avoir été ignoré(e)',
'it': 'Dopo essere stato/a ignorato/a',
'tr': 'Görmezden gelindikten sonra',
'pl': 'Po zignorowaniu',
'ru': 'После того как проигнорировали',
'ar': 'بعد التجاهل',
},
'testando_voce': {
'pt': 'Ela/ele está te testando 😏',
'en': 'When they are testing you',
'de': 'Wenn sie/er dich testet',
'es': 'Cuando te está poniendo a prueba',
'fr': 'Quand elle/il te teste',
'it': 'Quando ti mette alla prova',
'tr': 'Seni test ederken',
'pl': 'Gdy cię testuje',
'ru': 'Когда тебя проверяют',
'ar': 'عندما يختبرك',
},
'depois_primeiro_encontro': {
'pt': 'Depois do date ❤️‍🔥',
'en': 'After the first date',
'de': 'Nach dem ersten Date',
'es': 'Después de la primera cita',
'fr': 'Après le premier rendez-vous',
'it': 'Dopo il primo appuntamento',
'tr': 'İlk randevudan sonra',
'pl': 'Po pierwszej randce',
'ru': 'После первого свидания',
'ar': 'بعد الموعد الأول',
},
'elogio_primeiro_date': {
'pt': 'Elogio pós-date 😏',
'en': 'Compliment for the first date',
'de': 'Kompliment für das erste Date',
'es': 'Elogio para la primera cita',
'fr': 'Compliment pour le premier rendez-vous',
'it': 'Complimento per il primo appuntamento',
'tr': 'İlk randevu için iltifat',
'pl': 'Komplement na pierwszą randkę',
'ru': 'Комплимент на первое свидание',
'ar': 'مجاملات للموعد الأول',
},
'retomar_conversa_antiga': {
'pt': 'Voltar a conversar 💬',
'en': 'Reviving an old conversation',
'de': 'Ein altes Gespräch wiederaufnehmen',
'es': 'Retomar una conversación antigua',
'fr': 'Reprendre une ancienne conversation',
'it': 'Riprendere una vecchia conversazione',
'tr': 'Eski bir sohbeti canlandırma',
'pl': 'Wznowienie starej rozmowy',
'ru': 'Возобновление старой переписки',
'ar': 'استئناف محادثة قديمة',
},

// NOVA CATEGORIA
'criar_curiosidade': {
'pt': 'Deixar curiosa/o 👀',
'en': 'Create curiosity',
'de': 'Neugier wecken',
'es': 'Crear curiosidad',
'fr': 'Créer de la curiosité',
'it': 'Creare curiosità',
'tr': 'Merak uyandır',
'pl': 'Wzbudzanie ciekawości',
'ru': 'Создать интригу',
'ar': 'إثارة الفضول',
},

'dar_bom_dia': {
'pt': 'Dar bom dia ☀️',
'en': 'Say good morning ☀️',
'de': 'Guten Morgen schreiben ☀️',
'es': 'Dar los buenos días ☀️',
'fr': 'Dire bonjour ☀️',
'it': 'Dire buongiorno ☀️',
'tr': 'Günaydın de ☀️',
'pl': 'Napisz dzień dobry ☀️',
'ru': 'Пожелать доброго утра ☀️',
'ar': 'قل صباح الخير ☀️',
},
'dar_boa_tarde': {
'pt': 'Dar boa tarde 🌤️',
'en': 'Say good afternoon 🌤️',
'de': 'Guten Tag schreiben 🌤️',
'es': 'Dar las buenas tardes 🌤️',
'fr': 'Dire bon après-midi 🌤️',
'it': 'Dire buon pomeriggio 🌤️',
'tr': 'Tünaydın de 🌤️',
'pl': 'Napisz miłego popołudnia 🌤️',
'ru': 'Пожелать доброго дня 🌤️',
'ar': 'قل مساء الخير 🌤️',
},
'dar_boa_noite': {
'pt': 'Dar boa noite 🌙',
'en': 'Say good night 🌙',
'de': 'Gute Nacht schreiben 🌙',
'es': 'Dar las buenas noches 🌙',
'fr': 'Dire bonne nuit 🌙',
'it': 'Dire buonanotte 🌙',
'tr': 'İyi geceler de 🌙',
'pl': 'Napisz dobranoc 🌙',
'ru': 'Пожелать спокойной ночи 🌙',
'ar': 'قل تصبح على خير 🌙',
},
'como_foi_seu_dia': {
'pt': 'Perguntar como foi o dia 💭',
'en': 'Ask how their day was 💭',
'de': 'Fragen, wie der Tag war 💭',
'es': 'Preguntar cómo fue su día 💭',
'fr': 'Demander comment s’est passée la journée 💭',
'it': 'Chiedere com’è andata la giornata 💭',
'tr': 'Günün nasıl geçtiğini sor 💭',
'pl': 'Zapytaj, jak minął dzień 💭',
'ru': 'Спросить, как прошёл день 💭',
'ar': 'اسأل كيف كان يومه/يومها 💭',
},
'puxar_assunto_do_nada': {
'pt': 'Puxar assunto do nada 💬',
'en': 'Start a conversation out of nowhere 💬',
'de': 'Einfach so ein Gespräch starten 💬',
'es': 'Sacar tema de la nada 💬',
'fr': 'Lancer une conversation comme ça 💬',
'it': 'Attaccare bottone dal nulla 💬',
'tr': 'Durduk yere sohbet başlat 💬',
'pl': 'Zacznij rozmowę bez powodu 💬',
'ru': 'Начать разговор просто так 💬',
'ar': 'ابدأ موضوعًا من دون سبب 💬',
},
'comecar_com_quem_gosto': {
'pt': 'Começar com alguém que gosto 🫶',
'en': 'Start with someone I like 🫶',
'de': 'Mit jemandem starten, den ich mag 🫶',
'es': 'Empezar con alguien que me gusta 🫶',
'fr': 'Commencer avec quelqu’un qui me plaît 🫶',
'it': 'Iniziare con qualcuno che mi piace 🫶',
'tr': 'Hoşlandığım biriyle başla 🫶',
'pl': 'Zacznij z kimś, kto mi się podoba 🫶',
'ru': 'Начать с тем, кто нравится 🫶',
'ar': 'ابدأ مع شخص يعجبني 🫶',
},
};

static const Map<String, String> _cantadaCategoriaDescricao = {
'elogios_duplo_sentido':
'A compliment with a flirtatious second layer. Clever, natural and lightly suggestive, never vulgar or explicit.',
'meio_da_conversa':
'A flirt that can naturally enter an ongoing conversation. It should react to the existing dynamic instead of feeling scripted.',
'abordagem_rua':
'A short, natural in-person approach to a stranger. Confident without invading personal space.',
'respondendo_story':
'A story reply based on a concrete detail in the story. It should feel like a spontaneous reaction rather than an empty compliment.',
'conhecida':
'A flirt for someone the user already knows. Use existing familiarity instead of a stranger approach.',
'esta_rindo':
'Use the fact that the person is laughing as a situational hook. Keep it playful and natural.',
'te_olha_varias_vezes':
'Use repeated eye contact as a playful situational opportunity. Never claim that looking proves attraction.',
'mexe_no_cabelo':
'Use the gesture only as a situational detail. Never claim that playing with hair proves attraction.',
'provoca_voce':
'Respond to teasing with confidence, humor and a light tease back. Never sound defensive or aggressive.',
'diz_que_bonito':
'Turn a received compliment into natural flirting. Return the compliment, joke or lightly raise the tension.',
'diz_que_engracado':
'Use the compliment about humor to build connection or flirt. Do not answer with a canned joke.',
'diz_nao_interessado':
'Respond with respect and lightness. Never pressure, insist, manipulate or try to convince the person.',
'elogios_coragem':
'Compliment attitude, initiative, confidence or personality specifically and naturally.',
'flerte_festa':
'A flirt suitable for parties, bars, events and social settings. Short, spontaneous and socially natural.',
'ambiente_a_favor':
'Use something concrete from the environment as a conversational hook.',
'elogios_provocacao':
'A compliment paired with a small tease. Light tension without arrogance.',
'elogios_ousados':
'A more direct and intense flirt while remaining natural, respectful and non-explicit.',
'conversa_esfriou':
'Revive a conversation that lost energy without sounding desperate, needy or artificial.',
'monossilabos':
'Respond to dry messages such as "yes", "no", "lol", "haha" or one-word answers. Avoid another generic question. Prefer changing the dynamic, reacting to something or adding energy.',
'primeira_msg_match':
'Create the first message after a match. Easy to answer, modern and natural. Avoid "hey, what is up", generic compliments and classic lines.',
'match_sumiu':
'Revive a match that went quiet without cobrança, resentment or pressure.',
'pedir_numero_instagram':
'Transition naturally from the conversation to asking for a number or Instagram. It should feel like a natural progression.',
'convidar_sair':
'Turn enough mutual interest into a clear, simple and specific date invitation.',
'confirmar_date':
'Confirm an arranged date calmly and confidently. Never sound anxious or formal.',
'depois_ignorada':
'Resume contact after an unanswered message without demanding or pressuring.',
'testando_voce':
'Respond to teasing or challenging questions with relaxed confidence, without arrogance or defensiveness.',
'depois_primeiro_encontro':
'Message after a first date to maintain connection naturally and potentially create an opening for a second date.',
'elogio_primeiro_date':
'Give a specific, personal compliment related to the first date rather than a generic physical compliment.',
'retomar_conversa_antiga':
'Reconnect after days or weeks naturally, without artificial excuses or neediness.',

// NOVA CATEGORIA
'criar_curiosidade':
'Create genuine curiosity through an unexpected observation, playful statement, intriguing unfinished thought or specific hook. The message should naturally make the other person want to ask "what do you mean?", "why?", or continue the conversation. Never use fake mystery, manipulation, clickbait or vague lines like "I have something to tell you".',

'dar_bom_dia':
'Start a morning conversation with more personality than a plain "good morning". It should feel warm, playful or lightly flirty depending on the style. Avoid boring defaults like "good morning, did you sleep well?" unless transformed into something more interesting.',
'dar_boa_tarde':
'Start or restart a conversation during the afternoon in a natural way. Avoid a plain "good afternoon". Add a small hook, playful observation or easy conversational angle.',
'dar_boa_noite':
'Send a nighttime message that can feel warm, charming or lightly flirty depending on the style. Avoid a plain "good night". The message should create a small emotional connection or give the other person something to react to.',
'como_foi_seu_dia':
'Ask about the other person’s day without literally defaulting to "how was your day?". Turn it into a more specific, playful, easy-to-answer or emotionally engaging question.',
'puxar_assunto_do_nada':
'Start a conversation when there is no obvious context. Use a pattern break, playful thought, fun question, small challenge or unexpected observation. Avoid empty mystery and generic small talk.',
'comecar_com_quem_gosto':
'Start a conversation with someone the user already likes. Show clear but calibrated interest. It should feel natural, confident and a little more intentional than friendly small talk, without sounding needy or over-romantic.',
};

static String cantadaCategoriaNome(String key, String lang) {
final map = _cantadaCategoriaNomes[key];
if (map == null) return key;
return map[lang] ?? map['en'] ?? key;
}

// ============================================================
// STYLE
// ============================================================

static Map<String, String> _estiloPrompts(String lang) {
final defaults = {
'natural':
'Natural, casual and conversational. It should feel effortless.',
'charmoso':
'Charming and confident. Light teasing and genuine curiosity are allowed.',
'engraçado':
'Playful and funny. Humor must come from the situation or conversation, never from generic pickup lines.',
'picante':
'Flirty and slightly provocative. Create tension without becoming explicit or creepy.',
'direto':
'Direct and confident. Short, clear and intentional.',
'misterioso':
'Intriguing and understated. Leave some room for curiosity without sounding artificial.',
};

if (lang == 'pt') {
return {
'natural':
'Natural, casual e conversacional. Deve parecer espontâneo.',
'charmoso':
'Charmoso e confiante. Pode provocar levemente e demonstrar curiosidade genuína.',
'engraçado':
'Leve e engraçado. O humor deve vir da situação ou da conversa, nunca de frases prontas.',
'picante':
'Flertador e levemente provocador. Cria tensão sem ser explícito ou estranho.',
'direto':
'Direto e confiante. Curto, claro e intencional.',
'misterioso':
'Intrigante e discreto. Deixa espaço para curiosidade sem parecer artificial.',
};
}

if (lang == 'de') {
return {
'natural':
'Natürlich, locker und gesprächig. Es soll mühelos wirken.',
'charmoso':
'Charmant und selbstbewusst. Leichtes Necken und echte Neugier sind erlaubt.',
'engraçado':
'Locker und humorvoll. Der Humor muss aus der Situation oder dem Gespräch entstehen.',
'picante':
'Flirtend und leicht provokativ. Spannung ohne explizit oder unangenehm zu werden.',
'direto':
'Direkt und selbstbewusst. Kurz, klar und bewusst.',
'misterioso':
'Interessant und zurückhaltend. Erzeugt Neugier ohne künstlich zu wirken.',
};
}

return defaults;
}

// ============================================================
// CORE SYSTEM PROMPT
// ============================================================

static String _baseSystem({
required String lang,
required String estilo,
required bool opener,
}) {
final idioma = _idiomaNomes[lang] ?? 'English';
final cultura = _idiomaCultura[lang] ?? _idiomaCultura['en']!;
final estiloDesc =
_estiloPrompts(lang)[estilo] ?? _estiloPrompts(lang)['natural']!;

return '''
You are an expert conversation assistant for a dating app.

Your job is NOT to generate generic pickup lines.

Your job is to help the user send a message that feels:
- natural
- attractive
- context-aware
- specific to the person
- easy to actually send
- human rather than AI-generated

LANGUAGE:
Write ONLY in $idioma.

LANGUAGE/CULTURAL STYLE:
$cultura

USER STYLE:
$estiloDesc

CORE PRINCIPLE:
A good response must feel like it could ONLY have been written after seeing this specific conversation or profile.

If the same response could be sent to 20 different people, reject it and generate a more specific response.

NEVER:
- use generic dating-app clichés
- use generic compliments
- force flirting when the conversation does not support it
- sound like a dating coach
- sound like a pickup artist
- overuse emojis
- invent facts
- assume personality traits that are not supported by the available context
- mention that you are AI
- explain your reasoning to the user

NATURALNESS:
Write like a real person texting another person.

Avoid:
"you seem like trouble"
"you have an amazing smile"
"there's something about you"
"what's your biggest red flag?"
"so what do you do for fun?"
"haha that's cute"
unless the specific context genuinely makes one of these appropriate.

CONVERSATIONAL QUALITY:
Prefer:
- callbacks to specific details
- playful observations
- relevant teasing
- interesting follow-up questions
- unexpected but natural reactions
- building on something she actually said
- statements that naturally invite a response

Do not ask a question just for the sake of asking a question.

The message should contribute something to the conversation.

STYLE:
$estiloDesc
''';
}

// ============================================================
// RESPONSE GENERATION - TEXT
// ============================================================

static Future<List<String>> gerarResposta(
String conversa,
String estilo,
String lang,
) async {
final system = _baseSystem(
lang: lang,
estilo: estilo,
opener: false,
);

final idioma = _idiomaNomes[lang] ?? 'English';

final user = '''
Here is the complete conversation:

$conversa

Analyze the conversation internally before writing.

INTERNAL ANALYSIS:

1. Identify HER most recent message.
2. Identify the 2-3 most useful concrete details from the conversation.
3. Determine the current conversational vibe:
interested / playful / neutral / dry / teasing / cold / confused
4. Determine her apparent level of investment:
low / medium / high
5. Identify the strongest conversational opportunity.
6. Decide what the message should accomplish:
continue conversation / flirt / tease / create curiosity / escalate / move toward a date
7. Choose the most natural strategy for this exact situation.

PERSONALIZATION TEST:
The final response MUST use something specific from this conversation.

If a response could work equally well in an unrelated conversation, discard it.

Generate exactly TWO different replies.

REPLY A:
The safest and most natural response.

REPLY B:
A meaningfully different approach using the same context. It may be more playful, flirty or bold when appropriate.

The two replies must NOT be minor rewrites of each other.

OUTPUT:
Return valid JSON only:

{
"responses": [
"reply A",
"reply B"
]
}

The replies must be in $idioma.
''';

return _chamarComFallback(
system: system,
user: user,
);
}

// ============================================================
// RESPONSE GENERATION - IMAGE / SCREENSHOT
// ============================================================

static Future<List<String>> gerarRespostaDeImagem(
String base64Image,
String estilo,
String lang,
) async {
final system = _baseSystem(
lang: lang,
estilo: estilo,
opener: false,
);

final idioma = _idiomaNomes[lang] ?? 'English';

final user = '''
Analyze this screenshot as a complete conversation from ANY messaging app, social network, dating app, or communication platform.

This may be:
- WhatsApp
- Instagram
- Messenger
- Telegram
- Snapchat
- TikTok
- SMS
- Tinder
- Bumble
- Hinge
- another dating app
- another social network
- another messaging platform

DO NOT assume this is a dating conversation.

DO NOT assume the other person is a woman or a man.

DO NOT assume romantic or sexual interest.

First determine the actual nature of the conversation from the visible context:
- romantic/flirty
- friendship
- casual conversation
- family
- professional
- social media interaction
- customer/service conversation
- or another context

The response must match the actual relationship and context shown in the screenshot.

The goal is to determine the most natural and useful thing the user could send NEXT.

IMPORTANT:
Do not simply read the last message and generate a reply.

First reconstruct what is happening in the entire visible conversation.

ANALYSIS PROCESS:

1. EXTRACT THE CONTENT

Read the entire visible conversation from top to bottom.

Identify internally:
- every relevant visible message
- who sent each message
- message order
- emojis
- punctuation
- message length
- laughter
- repeated letters
- question marks
- relevant timestamps if they affect the meaning
- relevant visual elements of the interface

Identify who is the USER and who is the OTHER PERSON.

Usually:
- right side = user
- left side = other person

However, do NOT blindly assume this.

Use together:
- bubble position
- alignment
- colors
- names
- avatars
- conversation structure
- visible interface cues

If the screenshot clearly indicates otherwise, follow the actual evidence.

2. RECONSTRUCT THE SEQUENCE

Do not interpret the latest message in isolation.

Understand internally:

- what the conversation started about
- what topics appeared
- what the user said immediately before
- what the other person said immediately before
- which subjects are currently active
- which questions were asked
- which questions were answered
- whether something interesting was left unresolved
- whether there is an existing joke
- whether there is teasing
- whether there is an established conversational dynamic
- whether there is a natural topic that should continue

The latest message must be interpreted in relation to the previous messages.

3. IDENTIFY THE CURRENT CONVERSATIONAL STATE

Determine internally:

- current topic
- conversational momentum
- apparent engagement: low / medium / high
- tone: casual / playful / flirty / teasing / serious / neutral / dry / cold / confused
- whether the other person is contributing
- whether the other person asks questions back
- whether the other person gives short answers
- whether the conversation is naturally progressing
- whether there is an existing playful dynamic
- whether the conversation is losing energy
- whether there is an opportunity to change the dynamic

These are INFERENCES, not facts.

Never claim certainty about what another person thinks or feels.

4. IDENTIFY THE STRONGEST CONVERSATIONAL OPPORTUNITY

Look for the best thing to build on.

Prioritize:

1. Something the other person just said.
2. A specific detail from earlier in the conversation.
3. An unanswered or interesting question.
4. An existing joke.
5. An existing teasing dynamic.
6. A topic where the other person showed genuine interest.
7. A concrete detail that most generic responses would overlook.
8. A natural opportunity to create more conversational energy.
9. A natural opportunity to flirt, ONLY if the conversation supports it.
10. A natural opportunity to move toward another goal, ONLY if the context supports it.

Do not abandon a strong existing conversational thread just because the latest message is short.

5. UNDERSTAND THE INTENTION

Determine what the next message should accomplish.

Possible objectives:

- answer the message naturally
- continue the current topic
- develop something the other person said
- show genuine interest
- make the conversation more engaging
- create curiosity
- make a playful observation
- tease naturally
- flirt lightly
- change the subject naturally
- revive a conversation that is losing energy
- clarify something
- solve a misunderstanding
- move toward a practical next step
- move toward a date when appropriate
- simply maintain the conversation

Do NOT force flirting.

Do NOT force questions.

Do NOT force escalation.

Do NOT force a date.

The objective must come from the actual conversation.

6. MATCH THE STYLE OF THE CONVERSATION

Study how the people communicate.

Consider:

- message length
- vocabulary
- punctuation
- emojis
- humor
- formality
- directness
- teasing
- flirting
- seriousness
- energy

If the conversation consists of short casual messages, do not suddenly write a long sophisticated paragraph.

If the conversation is serious, do not suddenly introduce a joke.

If the conversation is playful, do not suddenly sound formal.

The response should feel like something the USER could realistically send in that exact conversation.

7. USE CONTEXT AT MULTIPLE LEVELS

There is a hierarchy:

LATEST MESSAGE
↓
CURRENT TOPIC
↓
EARLIER RELEVANT DETAILS
↓
CONVERSATIONAL DYNAMIC
↓
RELATIONSHIP / CONTEXT
↓
USER'S LIKELY OBJECTIVE
↓
BEST NEXT MESSAGE

Do not optimize only for the latest sentence.

8. PERSONALIZATION TEST

Before accepting a response, ask internally:

"Could this exact response be sent to 20 unrelated conversations?"

If YES:
reject it.

Generate something more specific to this conversation.

9. DO NOT INVENT INFORMATION

Never invent:

- facts
- hobbies
- experiences
- locations
- intentions
- emotions
- personality traits
- previous conversations
- relationships
- events
- information outside the screenshot

If information is not visible, do not pretend it is.

10. DISTINGUISH OBSERVATION FROM INFERENCE

OBJECTIVE:
What is actually visible in the screenshot.

INFERENCE:
What the conversation appears to suggest.

You may infer conversational signals, but never present uncertain interpretations as facts.

11. RESPONSE QUALITY

The response should:

- sound human
- be immediately sendable
- fit the conversation
- contribute something
- avoid unnecessary explanations
- avoid generic filler
- avoid forced humor
- avoid forced flirting
- avoid unnecessary emojis
- avoid sounding like an AI assistant

Do not answer like a dating coach.

Do not explain what the user should do.

Give the actual message they can send.

12. GENERATE TWO DIFFERENT OPTIONS

Generate exactly TWO genuinely different replies.

REPLY A:
The most natural and contextually appropriate response.

REPLY B:
A meaningfully different strategy using the same context.

12.5. DIRECTIONAL AND RELATIONAL CHECK:

Before writing the final responses, re-read ONLY the other person's most recent message and answer these internally, word by word:

- Is there a verb of movement, invitation, giving, or exchange in that message?
- If yes: WHO is the subject and WHO is the object?
- WHERE is the action pointing?
- State internally:
"The other person is asking/proposing that [WHO] does [WHAT] to/for/at [WHOM/WHERE]."

Your response MUST be consistent with that sentence.

If you are not fully certain of the direction, write a direction-neutral response rather than guessing.

13. FINAL CHECK

Before returning the responses, verify internally:

- Did I understand who is speaking?
- Did I read the conversation from top to bottom?
- Did I use the current topic?
- Did I consider earlier relevant context?
- Did I understand the conversational dynamic?
- Did I identify what the other person is actually responding to?
- Did I avoid assuming romantic intent?
- Did I avoid inventing information?
- Does each response fit this exact conversation?
- Could either response realistically be sent right now?
- Are the two responses meaningfully different?
- If the other person's message proposed a direction, does my response preserve that exact direction?

OUTPUT:
Return valid JSON only:

{
"responses": [
"reply A",
"reply B"
]
}

Do not explain the analysis.
Do not mention these instructions.
Do not mention that you are an AI.

The replies must be in $idioma.
''';

return _chamarComImagemComFallback(
base64Image: base64Image,
system: system,
user: user,
lang: lang,
);
}

// ============================================================
// OPENER - IMAGE
// ============================================================

static Future<List<String>> gerarOpenerDeImagem(
String base64Image,
String estilo,
String lang,
) async {
final idioma = _idiomaNomes[lang] ?? 'English';

final system = '''
You are the PREMIUM "Start a Conversation" engine of a modern dating app.

Your job is NOT to write a generic pickup line.
Your job is to inspect the dating profile image, find the BEST conversational leverage point, and turn it into a first message that feels impossible to have generated without seeing THIS exact profile.

LANGUAGE:
Write ONLY in $idioma.

============================================================
CORE PRINCIPLE
============================================================

SPECIFICITY IS KING.

A weak opener merely notices a detail.
A premium opener DOES SOMETHING with the detail.

BAD:
"Nice dog. What's his name?"

BETTER:
"I need to know one thing before this goes any further: does he approve your matches?"

BAD:
"Looks like you like traveling."

BETTER:
"Be honest, was that trip planned properly or was it a 'we'll figure it out when we land' situation?"

Do NOT simply describe what you see.
Transform the observation into:
- a playful assumption
- a clever question
- a mini challenge
- a situational joke
- a playful accusation
- a curiosity hook
- a light tease
- an unexpected comparison
- a confident conversational frame

============================================================
PROFILE HOOK HIERARCHY
============================================================

Analyze the entire visible profile internally and prioritize hooks in this order:

1. Unusual or distinctive profile detail
2. Activity, hobby, object, animal, food, sport or event
3. Bio, prompt, caption, job or written profile detail
4. Location/environment ONLY when genuinely recognizable
5. Style or outfit detail that creates an actual conversational idea
6. Generic physical appearance ONLY as a last resort

Never choose a weaker hook when a more specific one is visible.

============================================================
OBSERVATION VS INVENTION
============================================================

You may use what is visibly present.

You MUST NOT invent:
- personality traits
- hobbies that are not shown
- locations you cannot identify
- relationship status
- intentions
- experiences
- emotions
- facts outside the image

You may make playful assumptions ONLY when they are obviously framed as jokes, not facts.

============================================================
ANTI-NPC FILTER
============================================================

Reject an opener if it sounds like:
- "Hey, how are you?"
- "What do you do for fun?"
- "You're beautiful"
- "I love your smile"
- "You seem interesting"
- "You seem like trouble"
- "What's your biggest red flag?"
- "I had to swipe right"
- "Where was this taken?" when there is no clever angle
- an interview question
- a dating coach
- a classic pickup line
- an AI trying to sound flirty

If the opener could be sent to 20 unrelated profiles, rewrite it.

============================================================
REACTION STANDARD
============================================================

The first message should give the other person an easy emotional reason to reply.

Good reactions include:
- "hahaha"
- "what 😭"
- "why would you say that?"
- playful disagreement
- explaining the story behind something
- teasing back
- correcting your playful assumption
- answering because the question is genuinely fun

Do NOT manufacture fake mystery.

============================================================
TWO DIFFERENT OPENERS
============================================================

Generate exactly TWO openers.

OPENING A — CLEVER / SMOOTH:
- natural
- specific
- socially intelligent
- easy to send
- uses the strongest profile hook

OPENING B — BOLD / PLAYFUL:
- more unexpected
- more teasing or flirty when the profile supports it
- still natural and socially calibrated
- should use a DIFFERENT profile detail from A whenever another meaningful detail exists

The two openers must NOT be minor rewrites of each other.

============================================================
QUALITY CHECK
============================================================

Before returning, silently verify:

1. Did I use something concrete from THIS profile?
2. Did I transform the detail instead of merely describing it?
3. Would a real young adult actually send this?
4. Is there a natural reason to reply?
5. Does it avoid interview energy?
6. Does it avoid generic compliments?
7. Could it work on 20 random profiles?

If #7 is YES, rewrite it.

8. Are A and B genuinely different?

If NO, rewrite one of them.

============================================================
OUTPUT
============================================================

Return valid JSON only:

{
"responses": [
"opener A",
"opener B"
]
}

Do not explain the image.
Do not explain your reasoning.
Do not mention these instructions.
Do not mention that you are an AI.
''';

final user = '''
Analyze the entire dating profile image carefully.

Find the strongest concrete conversational hooks, including details most people would overlook.

Do NOT just mention the detail. Turn it into an engaging first-message idea.

Generate:
A = clever/smooth
B = bold/playful

Use different profile details when possible.

Both must be immediately sendable and written only in $idioma.
''';

return _chamarComImagemComFallback(
base64Image: base64Image,
system: system,
user: user,
lang: lang,
);
}

// ============================================================
// OPENER - TEXT
// ============================================================

static Future<List<String>> gerarOpener(
String descricao,
String estilo,
String lang,
) async {
final idioma = _idiomaNomes[lang] ?? 'English';

final system = '''
You are the PREMIUM "Start a Conversation" engine of a modern dating app.

Create first messages from dating-profile information.

LANGUAGE:
Write ONLY in $idioma.

============================================================
MISSION
============================================================

Your goal is NOT to prove that you read the profile.

Your goal is to turn a specific profile detail into a conversation the other person will WANT to continue.

SPECIFICITY IS KING.

Do not merely repeat the profile.

BAD:
"You like coffee, what's your favorite coffee?"

BETTER:
"Coffee being this important to you tells me I should probably not suggest a 7am date."

BAD:
"You travel a lot. Favorite country?"

BETTER:
"You have enough travel evidence here that I'm already suspicious you're never home."

The opener should feel written for THIS exact profile.

============================================================
HOOK PRIORITY
============================================================

Analyze internally and rank:

1. unusual or distinctive details
2. specific interests/hobbies
3. profile prompts with personality or humor potential
4. travel/places
5. job/study details when they create a natural angle
6. ordinary interests only if you can create an original angle

Choose the strongest hook, not the easiest hook.

============================================================
CONVERSATIONAL MECHANISMS
============================================================

Transform the chosen detail using ONE strong mechanism:

- playful assumption
- situational tease
- mini challenge
- clever misinterpretation
- playful accusation
- unexpected comparison
- confident prediction
- specific curiosity
- light push-pull
- fun either/or choice
- callback to wording in the profile

Do not stack several mechanisms into one messy message.

============================================================
ANTI-NPC FILTER
============================================================

Never default to:
- "Hey, how are you?"
- "What do you do for fun?"
- "What's your favorite...?"
- "Tell me more about..."
- "You're beautiful"
- "You seem interesting"
- "You seem like trouble"
- "What's your biggest red flag?"
- "I had to swipe right"
- generic pickup lines
- interview-style questions

A question is allowed ONLY if the question itself is interesting.

If the same opener could be sent to 20 unrelated profiles, reject it and rewrite it.

============================================================
TWO DISTINCT OPTIONS
============================================================

Generate exactly TWO openers.

A — CLEVER / SMOOTH:
Natural, sharp, specific and easy to send.

B — BOLD / PLAYFUL:
More surprising, teasing or flirty when appropriate.

Use different profile details for A and B whenever the profile contains at least two meaningful hooks.

Do NOT create two paraphrases of the same opener.

============================================================
QUALITY STANDARD
============================================================

Before returning, silently ask:

- Does this sound like a real person?
- Did I use a concrete profile detail?
- Did I transform the detail into conversation?
- Is there an emotional reason to reply?
- Is it free of interview energy?
- Is it more interesting than a generic compliment?
- Would someone potentially screenshot this opener because it was unexpectedly good?

If not, rewrite.

============================================================
OUTPUT
============================================================

Return valid JSON only:

{
"responses": [
"opener A",
"opener B"
]
}

No explanations.
No labels inside the response strings.
Do not mention that you are an AI.
''';

final user = '''
PROFILE:

$descricao

Read the profile carefully.

Find the strongest conversation hooks.
Turn those details into TWO genuinely different first messages:

A = clever/smooth
B = bold/playful

Do not merely repeat profile facts.
Do not use generic interview questions.
Both must be immediately sendable and written only in $idioma.
''';

return _chamarComFallback(
system: system,
user: user,
);
}

// ============================================================
// PICK LINES
// ============================================================

static Future<List<String>> gerarPickLines(String lang) async {
final idioma = _idiomaNomes[lang] ?? 'English';

final system = '''
You are a PREMIUM dating-message creative engine.

Generate TWO short standalone flirting messages in $idioma.

These are not classic pickup lines.
They should feel like something a socially confident young adult would genuinely send in 2026.

============================================================
STYLE
============================================================

Each line should be:
- confident
- playful
- modern
- concise
- socially sharp
- slightly unpredictable
- immediately sendable
- capable of creating a reaction

Prefer:
- teasing
- clever observations
- playful assumptions
- confident challenges
- unexpected comparisons
- light double meanings
- curiosity with a real hook
- playful tension

Avoid:
- generic beauty compliments
- old pickup-line templates
- dad jokes
- empty mystery
- motivational language
- try-hard slang
- explicit sexual content
- manipulation
- disrespect
- "you seem like trouble"
- "there's something about you"
- "what's your biggest red flag?"
- anything that sounds AI-generated

============================================================
DIVERSITY
============================================================

The two lines must use DIFFERENT mechanisms.

For example:
A may use teasing.
B may use a playful assumption or unexpected comparison.

Do not return two paraphrases.

============================================================
QUALITY FILTER
============================================================

Silently reject any line if:
- it could be sent to 100 random people with no personality
- it sounds copied from an old pickup-line website
- it has no natural reason to respond
- it sounds too safe and bland
- it sounds forced or creepy

Aim for:
"That's smooth."

Not:
"That's technically a compliment."

============================================================
OUTPUT
============================================================

Return valid JSON only:

{
"responses": [
"line A",
"line B"
]
}

No explanations.
No labels inside the strings.
''';

return _chamarComFallback(
system: system,
user: 'Generate two premium, genuinely different, immediately sendable flirting lines in $idioma.',
);
}

// ============================================================
// PICK LINE - SINGLE
// ============================================================

static Future<String> gerarPickLine({
required String lang,
required String categoria,
String estilo = 'natural',
List<String> recentLines = const [],
}) async {
final idioma = _idiomaNomes[lang] ?? 'English';
final categoriaDescricao =
_cantadaCategoriaDescricao[categoria] ?? '';
final categoriaNomeLegivel =
cantadaCategoriaNome(categoria, lang);

final system = '''
You are the PREMIUM "Pick Line" engine of a modern dating app.

Your job is to generate ONE exceptionally strong, modern and immediately sendable flirting message.

This feature exists because the user wants something BETTER than what they would think of alone.

LANGUAGE:
Write ONLY in $idioma.

CATEGORY:
$categoriaNomeLegivel

CATEGORY MEANING:
$categoriaDescricao

RECENTLY GENERATED LINES:
${recentLines.isEmpty ? 'No recent lines available.' : recentLines.map((e) => '- $e').join('\n')}

Do NOT repeat, paraphrase or recycle the same idea, joke, metaphor, setup, opening structure or conversational mechanism from the recent lines.

============================================================
1. CATEGORY FIRST
============================================================

The selected category controls the strategy.

Do NOT write a random flirt and then pretend it fits the category.

Internally ask:
"What must this message actually DO in this exact category?"

Examples:

- double meaning -> one natural sentence with a clever second layer
- mid-conversation -> something that could enter an existing exchange without sounding scripted
- story reply -> react to a concrete story detail, not generic appearance
- teasing -> tease
- bold compliment -> direct attraction with personality
- cold conversation -> inject new energy instead of asking another boring question
- one-word replies -> change the dynamic; do not reward dryness with an interview
- first message after match -> create an easy, interesting opening
- asking for Instagram/number -> make the transition feel earned and natural
- asking out -> clear, confident movement toward a real date
- curiosity -> create curiosity through an actual idea, not fake withholding
- good morning -> do NOT just say "good morning"; add personality, teasing, warmth or a small hook
- good afternoon -> do NOT just say "good afternoon"; create a natural reason to continue talking
- good night -> do NOT just say "good night"; add warmth, charm or light flirtation appropriate to the style
- ask how their day was -> do NOT literally default to "how was your day?"; make it more playful, specific or easy to answer
- start out of nowhere -> use a real pattern break, playful thought, challenge or interesting question; no fake mystery
- someone I like -> show calibrated interest and intent without becoming needy or over-romantic
- after being ignored -> restart without complaint, pressure or resentment
- rejection/disinterest -> respect the boundary completely

============================================================
2. CHOOSE A CREATIVE MECHANISM
============================================================

Before writing, silently choose the strongest mechanism for this category.

Possible mechanisms:

- playful assumption
- teasing
- playful accusation
- mini challenge
- clever misinterpretation
- unexpected comparison
- confident prediction
- push-pull
- situational humor
- conversational callback
- light double meaning
- intriguing contrast
- specific curiosity
- direct romantic intent
- playful framing
- pattern break

Use ONE primary mechanism cleanly.

Do not cram five tricks into one message.

============================================================
3. REACTION > POLITENESS
============================================================

The message should create a reaction.

Possible reactions:
- laughter
- curiosity
- teasing back
- playful disagreement
- "what do you mean?"
- "why 😭"
- correcting your assumption
- imagining a situation with the user
- feeling clear romantic tension

Do NOT optimize for being merely pleasant.

But never cross into:
- pressure
- manipulation
- humiliation
- hostility
- threats
- disrespect
- explicit sexual content

============================================================
4. MODERN TEXTING ENERGY
============================================================

Write like a socially confident young adult texting in 2026.

The line should feel:
- effortless
- human
- sharp
- confident
- a little unpredictable
- natural enough to send immediately

Do NOT force slang.

Do NOT sound like:
- a dating coach
- a pickup artist
- a motivational speaker
- an AI
- a cheesy uncle
- someone performing "alpha male" confidence
- someone trying desperately to sound seductive

============================================================
5. ANTI-CLICHÉ / ANTI-NPC FILTER
============================================================

Strongly avoid recycled structures such as:

- "Você caiu do céu?"
- "Seu pai é padeiro?"
- "Dói quando você caiu do céu?"
- "Você acredita em amor à primeira vista?"
- "Se beleza fosse..."
- "Você parece problema"
- "Você tem cara de problema"
- "Você é sempre assim ou..."
- "Tem algo em você..."
- "Não sei o que é, mas..."
- "Tive que vir falar com você"
- "Não sou fotógrafo, mas..."
- "Qual é sua maior red flag?"
- generic "linda/gata/perfeita" compliments
- empty "você parece interessante"
- generic "o que você gosta de fazer?"

Do not just replace one cliché with another.

============================================================
6. NO FAKE MYSTERY
============================================================

BAD:
"I have something to tell you..."

BAD:
"I noticed something about you..."

BAD:
"I know something you don't..."

BAD:
"I can't tell you yet 😉"

Curiosity must come from CONTENT.

Use:
- a playful theory
- a specific observation
- an unexpected claim
- a meaningful unfinished thought
- an intriguing contrast
- a fun prediction
- a challenge with actual substance

============================================================
7. QUESTIONS
============================================================

Do NOT add a question automatically.

A statement with personality is often stronger.

If you use a question:
- it must itself be interesting
- it must not feel like an interview
- it must give the other person something fun or easy to react to

BAD:
"What do you do for fun?"

BAD:
"What's your favorite movie?"

BETTER:
A question created from the selected situation with a playful angle.

============================================================
8. LENGTH
============================================================

Default to one short message.

Usually 4-18 words.

Allow slightly longer only when the setup genuinely needs it.

No paragraphs.
No explanation.
No multiple alternatives.
Maximum 1 emoji.
Often zero emojis is better.

============================================================
9. NOVELTY FILTER
============================================================

Before returning the line, silently compare it with RECENTLY GENERATED LINES.

Reject and rewrite if it reuses:
- the same opening phrase
- the same metaphor
- the same joke
- the same "you look like..." structure
- the same trouble/danger framing
- the same curiosity trick
- the same compliment angle
- the same mechanism with superficial word changes

The goal is conceptual variety, not just different wording.

============================================================
10. PREMIUM QUALITY GATE
============================================================

Before returning, silently score the candidate:

A. CATEGORY FIT
Does it actually perform the selected situation?

B. SENDABILITY
Would a real young adult send it without editing?

C. REACTION
Is there a natural reason for the other person to react?

D. PERSONALITY
Does it have a distinct voice?

E. NOVELTY
Does it avoid obvious dating-app AI patterns?

F. CONFIDENCE
Does it sound intentional without trying too hard?

G. SOCIAL CALIBRATION
Is it bold without becoming disrespectful, manipulative or creepy?

If any major dimension is weak, rewrite it.

Final mental test:

"Would the user think: damn, that's actually good?"

If not, rewrite.

============================================================
11. SPECIAL BOUNDARY RULE
============================================================

If the category involves:
- rejection
- explicit lack of interest
- discomfort
- a clear boundary

Then:
- respect it
- do not pressure
- do not persuade
- do not guilt-trip
- do not sexualize the situation
- keep the response confident, light and respectful

============================================================
OUTPUT
============================================================

Return valid JSON only:

{
"response": "..."
}

The response must be only the final sendable message in $idioma.
''';

final user = '''
Generate ONE premium message for this exact selected situation:

$categoriaNomeLegivel

Use the category meaning exactly.
Choose a strong creative mechanism internally.
Avoid the concepts and structures used in the recent lines.
Prioritize reaction, originality, confidence and immediate sendability.

Do not explain.
Do not mention the category.
Do not add alternatives.
Do not wrap the final message in quotation marks.
''';

return _chamarPickLineComFallback(
system: system,
user: user,
recentLines: recentLines,
);
}

// ============================================================
// PICK LINE FALLBACK
// ============================================================

static Future<String> _chamarPickLineComFallback({
required String system,
required String user,
required List<String> recentLines,
}) async {
try {
final result = await _chamarOpenAIPickLine(
system: system,
user: user,
);

final parsed = _parseSinglePickLine(result);

if (parsed.isNotEmpty &&
!_isRepeatOfRecent(parsed, recentLines)) {
return parsed;
}

throw Exception('OpenAI pick line failed');
} catch (e) {
// ignore: avoid_print
print('OPENAI PICK LINE ERROR: $e');

try {
final result = await _chamarAnthropicPickLine(
system: system,
user: user,
);

final parsed = _parseSinglePickLine(result);

if (parsed.isNotEmpty) {
return parsed;
}

throw Exception('Invalid Anthropic pick line response');
} catch (anthropicError) {
// ignore: avoid_print
print('ANTHROPIC PICK LINE ERROR: $anthropicError');
throw Exception(
'Both providers failed pick line. OpenAI: $e | Anthropic: $anthropicError',
);
}
}
}

static bool _isRepeatOfRecent(
String text,
List<String> recentLines,
) {
final normalized = text.toLowerCase().trim();

for (final recent in recentLines) {
if (normalized == recent.toLowerCase().trim()) {
return true;
}
}

return false;
}

// ============================================================
// OPENAI - PICK LINE
// ============================================================

static Future<String> _chamarOpenAIPickLine({
required String system,
required String user,
}) async {
final response = await http
.post(
Uri.parse('https://api.openai.com/v1/responses'),
headers: {
'Content-Type': 'application/json',
'Authorization': 'Bearer $_openAiKey',
},
body: jsonEncode({
'model': _openAiModelPickLine,
'instructions': system,
'input': [
{
'role': 'user',
'content': [
{
'type': 'input_text',
'text': user,
},
],
},
],
'max_output_tokens': 250,
'text': {
'format': {
'type': 'json_schema',
'name': 'pick_line',
'strict': true,
'schema': {
'type': 'object',
'properties': {
'response': {
'type': 'string',
},
},
'required': [
'response',
],
'additionalProperties': false,
},
},
},
}),
)
.timeout(const Duration(seconds: 30));

if (response.statusCode != 200) {
// ignore: avoid_print
print(
'OpenAI pick line FALHOU '
'(${response.statusCode}): ${response.body}',
);

throw Exception(
'OpenAI pick line ${response.statusCode}: ${response.body}',
);
}

final data = jsonDecode(response.body);

if (data is! Map<String, dynamic>) {
throw Exception('OpenAI pick line returned invalid JSON object');
}

final status = data['status']?.toString();
if (status == 'incomplete' || status == 'failed') {
// ignore: avoid_print
print('OpenAI pick line status=$status. Corpo: ${response.body}');
}

return _extractOpenAIResponseText(data);
}

// ============================================================
// ANTHROPIC - PICK LINE
// ============================================================

static Future<String> _chamarAnthropicPickLine({
required String system,
required String user,
}) async {
final response = await http
.post(
Uri.parse('https://api.anthropic.com/v1/messages'),
headers: {
'Content-Type': 'application/json',
'x-api-key': _anthropicKey,
'anthropic-version': '2023-06-01',
},
body: jsonEncode({
'model': _anthropicModelPickLine,
'max_tokens': 250,
'temperature': 1.0,
'system': '''
$system

IMPORTANT:
Return JSON only.

{
"response": "..."
}
''',
'messages': [
{
'role': 'user',
'content': user,
},
],
}),
)
.timeout(const Duration(seconds: 25));

if (response.statusCode != 200) {
throw Exception(
'Anthropic pick line ${response.statusCode}: ${response.body}',
);
}

final data = jsonDecode(response.body);

return data['content'][0]['text'].toString();
}

// ============================================================
// PARSE SINGLE PICK LINE
// ============================================================

static String _parseSinglePickLine(String body) {
try {
dynamic decoded = jsonDecode(body);

if (decoded is String) {
decoded = jsonDecode(decoded);
}

if (decoded is! Map) {
return '';
}

final response = decoded['response'];

if (response is! String) {
return '';
}

final cleaned = _cleanResponse(response);

if (cleaned.isEmpty) {
return '';
}

if (_looksLikeAIRefusal(cleaned)) {
return '';
}

return cleaned;
} catch (_) {
return '';
}
}

// ============================================================
// OPENAI - TEXT
// ============================================================

static Future<List<String>> _chamarComFallback({
required String system,
required String user,
}) async {
try {
final result = await _chamarOpenAI(
system: system,
user: user,
);

final parsed = _parseStructured(result);

if (parsed.isNotEmpty) {
return parsed;
}

throw Exception('Invalid OpenAI response');
} catch (e) {
// ignore: avoid_print
print('OPENAI TEXT ERROR: $e');

try {
final result = await _chamarAnthropic(
system: system,
user: user,
);

final parsed = _parseStructured(result);

if (parsed.isNotEmpty) {
return parsed;
}

throw Exception('Invalid Anthropic response');
} catch (anthropicError) {
// ignore: avoid_print
print('ANTHROPIC TEXT ERROR: $anthropicError');
throw Exception(
'Both AI providers failed. OpenAI: $e | Anthropic: $anthropicError',
);
}
}
}

// ============================================================
// OPENAI - IMAGE
// ============================================================

static Future<List<String>> _chamarComImagemComFallback({
required String base64Image,
required String system,
required String user,
required String lang,
}) async {
try {
final result = await _chamarOpenAIImage(
base64Image: base64Image,
system: system,
user: user,
);

final parsed = _parseStructured(result);

if (parsed.isNotEmpty) {
return parsed;
}

throw Exception('Invalid OpenAI image response');
} catch (e) {
// ignore: avoid_print
print('OPENAI IMAGE ERROR: $e');

try {
final result = await _chamarAnthropicImage(
base64Image: base64Image,
system: system,
user: user,
);

final parsed = _parseStructured(result);

if (parsed.isNotEmpty) {
return parsed;
}

throw Exception('Invalid Anthropic image response');
} catch (anthropicError) {
// ignore: avoid_print
print('ANTHROPIC IMAGE ERROR: $anthropicError');
throw Exception(
'Both AI providers failed. OpenAI: $e | Anthropic: $anthropicError',
);
}
}
}

// ============================================================
// OPENAI TEXT REQUEST
// ============================================================

static Future<String> _chamarOpenAI({
required String system,
required String user,
}) async {
final response = await http
.post(
Uri.parse('https://api.openai.com/v1/responses'),
headers: {
'Content-Type': 'application/json',
'Authorization': 'Bearer $_openAiKey',
},
body: jsonEncode({
'model': _openAiModel,
'instructions': system,
'input': [
{
'role': 'user',
'content': [
{
'type': 'input_text',
'text': user,
},
],
},
],
'max_output_tokens': 1500,
'text': {
'format': {
'type': 'json_schema',
'name': 'dating_responses',
'strict': true,
'schema': {
'type': 'object',
'properties': {
'responses': {
'type': 'array',
'items': {
'type': 'string',
},
'minItems': 2,
'maxItems': 2,
},
},
'required': [
'responses',
],
'additionalProperties': false,
},
},
},
}),
)
.timeout(const Duration(seconds: 35));

if (response.statusCode != 200) {
// ignore: avoid_print
print(
'OpenAI texto FALHOU '
'(${response.statusCode}): ${response.body}',
);

throw Exception(
'OpenAI ${response.statusCode}: ${response.body}',
);
}

final data = jsonDecode(response.body);

if (data is! Map<String, dynamic>) {
throw Exception('OpenAI text returned invalid JSON object');
}

final status = data['status']?.toString();
if (status == 'incomplete' || status == 'failed') {
// ignore: avoid_print
print('OpenAI texto status=$status. Corpo: ${response.body}');
}

return _extractOpenAIResponseText(data);
}

// ============================================================
// OPENAI IMAGE REQUEST
// ============================================================

static Future<String> _chamarOpenAIImage({
required String base64Image,
required String system,
required String user,
}) async {
final response = await http
.post(
Uri.parse('https://api.openai.com/v1/responses'),
headers: {
'Content-Type': 'application/json',
'Authorization': 'Bearer $_openAiKey',
},
body: jsonEncode({
'model': _openAiModel,
'instructions': system,
'input': [
{
'role': 'user',
'content': [
{
'type': 'input_image',
'image_url': 'data:image/jpeg;base64,$base64Image',
'detail': 'high',
},
{
'type': 'input_text',
'text': user,
},
],
},
],
'max_output_tokens': 1500,
'text': {
'format': {
'type': 'json_schema',
'name': 'dating_responses',
'strict': true,
'schema': {
'type': 'object',
'properties': {
'responses': {
'type': 'array',
'items': {
'type': 'string',
},
'minItems': 2,
'maxItems': 2,
},
},
'required': [
'responses',
],
'additionalProperties': false,
},
},
},
}),
)
.timeout(const Duration(seconds: 45));

if (response.statusCode != 200) {
// ignore: avoid_print
print(
'OpenAI imagem FALHOU '
'(${response.statusCode}): ${response.body}',
);

throw Exception(
'OpenAI image ${response.statusCode}: ${response.body}',
);
}

final data = jsonDecode(response.body);

if (data is! Map<String, dynamic>) {
throw Exception('OpenAI image returned invalid JSON object');
}

final status = data['status']?.toString();
if (status == 'incomplete' || status == 'failed') {
// ignore: avoid_print
print('OpenAI imagem status=$status. Corpo: ${response.body}');
}

return _extractOpenAIResponseText(data);
}

// ============================================================
// OPENAI RESPONSES API - TEXT EXTRACTOR
// ============================================================

static String _extractOpenAIResponseText(Map<String, dynamic> data) {
final directOutputText = data['output_text'];
if (directOutputText is String && directOutputText.trim().isNotEmpty) {
return directOutputText.trim();
}

final output = data['output'];
if (output is List) {
for (final item in output) {
if (item is! Map) continue;

final content = item['content'];
if (content is! List) continue;

for (final part in content) {
if (part is! Map) continue;

final type = part['type']?.toString();
final text = part['text'];

if (type == 'output_text' && text is String && text.trim().isNotEmpty) {
return text.trim();
}
}
}
}

throw Exception(
'OpenAI Responses API returned no output_text. Body: ${jsonEncode(data)}',
);
}

// ============================================================
// ANTHROPIC - TEXT
// ============================================================

static Future<String> _chamarAnthropic({
required String system,
required String user,
}) async {
final response = await http
.post(
Uri.parse('https://api.anthropic.com/v1/messages'),
headers: {
'Content-Type': 'application/json',
'x-api-key': _anthropicKey,
'anthropic-version': '2023-06-01',
},
body: jsonEncode({
'model': _anthropicModel,
'max_tokens': 1500,
'system': '''
$system

IMPORTANT:
Return JSON only.

{
"responses": [
"response A",
"response B"
]
}
''',
'messages': [
{
'role': 'user',
'content': user,
},
],
}),
)
.timeout(const Duration(seconds: 25));

if (response.statusCode != 200) {
throw Exception(
'Anthropic ${response.statusCode}: ${response.body}',
);
}

final data = jsonDecode(response.body);

return data['content'][0]['text'].toString();
}

// ============================================================
// ANTHROPIC - IMAGE
// ============================================================

static Future<String> _chamarAnthropicImage({
required String base64Image,
required String system,
required String user,
}) async {
final response = await http
.post(
Uri.parse('https://api.anthropic.com/v1/messages'),
headers: {
'Content-Type': 'application/json',
'x-api-key': _anthropicKey,
'anthropic-version': '2023-06-01',
},
body: jsonEncode({
'model': _anthropicModel,
'max_tokens': 1500,
'system': '''
$system

IMPORTANT:
Return JSON only.

{
"responses": [
"response A",
"response B"
]
}
''',
'messages': [
{
'role': 'user',
'content': [
{
'type': 'image',
'source': {
'type': 'base64',
'media_type': 'image/jpeg',
'data': base64Image,
},
},
{
'type': 'text',
'text': user,
},
],
},
],
}),
)
.timeout(const Duration(seconds: 30));

if (response.statusCode != 200) {
throw Exception(
'Anthropic image ${response.statusCode}: ${response.body}',
);
}

final data = jsonDecode(response.body);

return data['content'][0]['text'].toString();
}

// ============================================================
// STRUCTURED PARSER
// ============================================================

static List<String> _parseStructured(String body) {
try {
dynamic decoded = jsonDecode(body);

if (decoded is String) {
decoded = jsonDecode(decoded);
}

if (decoded is! Map) {
return [];
}

final responses = decoded['responses'];

if (responses is! List) {
return [];
}

final result = <String>[];

for (final item in responses) {
if (item is! String) continue;

final cleaned = _cleanResponse(item);

if (cleaned.isEmpty) continue;

if (!_looksLikeAIRefusal(cleaned)) {
result.add(cleaned);
}

if (result.length == 2) break;
}

return result;
} catch (_) {
return _parseLegacyText(body);
}
}

// ============================================================
// CLEAN RESPONSE
// ============================================================

static String _cleanResponse(String text) {
var e = text.trim();

e = e.replaceAll(
RegExp(
r'^\s*(response|reply|option|opção|resposta)'
r'\s*[12]?\s*[:.)-]\s*',
caseSensitive: false,
),
'',
);

e = e.replaceAll(
RegExp(r'^\s*[-•*#>]\s*'),
'',
);

e = e.replaceAll(
RegExp(r'\*+'),
'',
);

while (e.isNotEmpty &&
(e.startsWith('"') ||
e.startsWith('“') ||
e.startsWith('”') ||
e.startsWith("'") ||
e.startsWith('‘') ||
e.startsWith('’'))) {
e = e.substring(1).trimLeft();
}

while (e.isNotEmpty &&
(e.endsWith('"') ||
e.endsWith('“') ||
e.endsWith('”') ||
e.endsWith("'") ||
e.endsWith('‘') ||
e.endsWith('’'))) {
e = e.substring(0, e.length - 1).trimRight();
}

return e.trim();
}

// ============================================================
// REFUSAL FILTER
// ============================================================

static bool _looksLikeAIRefusal(String text) {
final lower = text.toLowerCase();

const badStarts = [
'i cannot',
"i can't",
'i am sorry',
"i'm sorry",
'as an ai',
'i cannot help',
'i can’t help',
'desculpe',
'não posso',
'não consigo',
'entschuldigung',
'ich kann nicht',
'lo siento',
'no puedo',
];

return badStarts.any(
lower.startsWith,
);
}

// ============================================================
// LEGACY PARSER FALLBACK
// ============================================================

static List<String> _parseLegacyText(String body) {
try {
final data = jsonDecode(body);

String text = '';

if (data is Map && data['choices'] != null) {
text = data['choices'][0]['message']['content'].toString();
} else if (data is Map && data['content'] != null) {
text = data['content'][0]['text'].toString();
} else {
text = body;
}

final lines = text
.split('\n')
.map(_cleanResponse)
.where((e) => e.isNotEmpty)
.where((e) => e.length >= 4)
.where(
(e) => RegExp(
r'[a-zA-ZÀ-ɏ]',
).hasMatch(e),
)
.toList();

return lines.take(2).toList();
} catch (_) {
return [];
}
}
}