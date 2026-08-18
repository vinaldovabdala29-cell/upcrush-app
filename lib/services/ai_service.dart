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
];

static const Map<String, Map<String, String>> _cantadaCategoriaNomes = {
'elogios_duplo_sentido': {
'pt': 'Elogios com duplo sentido',
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
'pt': 'No meio da conversa',
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
'pt': 'Abordagem na rua',
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
'pt': 'Respondendo story',
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
'pt': 'Conhecida/o',
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
'pt': 'Ela/ele está rindo',
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
'pt': 'Ela/ele te olha várias vezes',
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
'pt': 'Ela/ele mexe no cabelo enquanto conversa',
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
'pt': 'Ela/ele provoca você',
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
'pt': 'Ela/ele diz que você é bonito',
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
'pt': 'Ela/ele diz que você é engraçado',
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
'pt': 'Ela/ele diz que não está interessado',
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
'pt': 'Elogios de coragem',
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
'pt': 'Flerte para festa',
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
'pt': 'Usando o ambiente ao seu favor',
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
'pt': 'Elogios de provocação',
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
'pt': 'Elogios ousados',
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
'pt': 'Conversa que esfriou',
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
'pt': 'Ela/ele responde com monossílabos',
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
'pt': 'Primeira mensagem depois do match',
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
'pt': 'Depois do match e sumiu',
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
'pt': 'Pedir o número ou Instagram',
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
'pt': 'Convidar para sair',
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
'pt': 'Confirmar um date já marcado',
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
'pt': 'Depois de ser ignorada/o',
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
'pt': 'Quando está testando você',
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
'pt': 'Depois do primeiro encontro',
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
'pt': 'Elogio para o primeiro date',
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
'pt': 'Retomar uma conversa antiga',
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
'pt': 'Criar curiosidade',
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
You are an expert dating conversation assistant.

Your job is to create an opener based ONLY on concrete, observable details in a dating profile image.

LANGUAGE:
Only $idioma.

The opener must feel specifically written for this person.

DO NOT:
- say she is beautiful
- compliment generic physical appearance
- invent personality traits
- invent where she is
- invent hobbies
- use generic pickup lines
- use "you seem like trouble"
- use "I had to swipe right"
- use boring interview questions

ANALYZE FIRST:

1. What concrete objects/details are visible?
2. Is there an identifiable activity?
3. Is there a recognizable location or environment?
4. Is there an animal, food, sport, travel element, unusual object or visual detail?
5. Which detail gives the strongest conversational opening?
6. Can the opener naturally create curiosity, humor or playful tension?

IMPORTANT:
Do not claim something is true about her personality based only on appearance.

The opener should reference something visible.

Generate TWO genuinely different openers.

OPENING A:
Natural and clever.

OPENING B:
More playful or flirty, if the image supports it.

Both must be specific to the image.

OUTPUT JSON ONLY:

{
"responses": [
"opener A",
"opener B"
]
}
''';

final user = '''
Analyze this dating profile image carefully.

Find the most specific conversational detail that most people would overlook.

Create two openers that could realistically be sent to this exact person.
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
You are an expert dating conversation assistant.

Create a first message based on the person's dating profile.

LANGUAGE:
Only $idioma.

The opener must feel specifically written for this profile.

Do not use:
- generic compliments
- generic questions
- generic pickup lines
- "you're beautiful"
- "you seem like trouble"
- "I had to swipe right"
- interview-style questions

FIRST analyze the profile internally.

Find:
1. concrete personal details
2. unusual interests
3. places
4. hobbies
5. humor opportunities
6. potential conversation hooks

Then choose ONE strong hook.

Generate TWO genuinely different openers.

A = natural and clever
B = more playful/flirty

Both must be grounded in the actual profile.

OUTPUT JSON ONLY:

{
"responses": [
"opener A",
"opener B"
]
}
''';

final user = '''
HER PROFILE:

$descricao

Generate two openers in $idioma.
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
You are an expert at writing playful dating messages.

Generate short standalone lines in $idioma.

They must be:
- confident
- playful
- modern
- natural
- not creepy
- not explicit
- not generic

Avoid classic pickup-line clichés.

Generate two genuinely different lines.

OUTPUT JSON ONLY:

{
"responses": [
"line A",
"line B"
]
}
''';

return _chamarComFallback(
system: system,
user: 'Generate two lines in $idioma.',
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

Your job is to generate ONE extremely strong, modern, sendable flirting message.

This is NOT a generic pickup-line generator.

The user wants a line that makes them think:

"Ok, this is actually good. I would send this."

LANGUAGE:
Write ONLY in $idioma.

SELECTED SITUATION:

CATEGORY:
$categoriaNomeLegivel

CATEGORY MEANING:
$categoriaDescricao

RECENTLY GENERATED LINES:

Do NOT repeat or closely imitate these:

${recentLines.isEmpty ? 'No recent lines available.' : recentLines.map((e) => '- $e').join('\n')}

============================================================
CORE STYLE
============================================================

Be:

- bold
- confident
- modern
- attractive
- playful
- unpredictable
- socially sharp
- concise
- immediately sendable

The line should have enough personality that it feels PREMIUM.

Do NOT sound like:

- a dating coach
- a pickup artist from 2015
- a cheesy uncle
- an AI
- a motivational speaker
- a teenager trying too hard

============================================================
IMPACT
============================================================

The first few words matter.

Prefer lines that create an immediate reaction.

The person should naturally feel like responding, laughing, teasing back, disagreeing playfully, or asking what you mean.

The message should create an emotional reaction or conversational opening.

Do NOT rely on empty mystery.

BAD:
"I have something to tell you..."

BAD:
"I know something about you..."

BAD:
"There's something about you..."

BAD:
"I can't tell you yet 😉"

GOOD:
Use an actual observation, playful accusation, unexpected comparison, confident tease, clever challenge or intriguing statement.

============================================================
MODERN YOUNG ADULT STYLE
============================================================

Write like someone socially confident in 2026.

Use contemporary dating-app, Instagram and messaging culture naturally.

Do NOT force slang.

Do NOT use outdated pickup-line structures.

Avoid:

- "Você caiu do céu?"
- "Seu pai é padeiro?"
- "Dói quando você caiu do céu?"
- "Você acredita em amor à primeira vista?"
- "Se beleza fosse tempo..."
- "Você é sempre assim ou..."
- "Você parece problema"
- "Tive que vir falar com você"
- "Não sou fotógrafo, mas..."
- generic "linda/gata/perfeita" compliments

Unless the exact category and context make something similar genuinely clever.

============================================================
BOLDNESS
============================================================

Be willing to take a risk.

A strong line can:

- tease
- challenge
- flirt directly
- imply chemistry
- create playful tension
- make a confident assumption as a joke
- turn a normal situation into flirting
- make the other person curious
- use a clever double meaning

But it must remain socially calibrated.

BOLD does NOT mean:

- desperate
- disrespectful
- threatening
- manipulative
- insulting
- sexually explicit

============================================================
FLIRTING
============================================================

When the category supports flirting, do not be afraid of clear romantic tension.

Weak:
"Você parece legal."

Better:
"Você tem uma energia perigosamente fácil de gostar."

Stronger:
"Você tem cara de quem começa uma conversa inocente e termina me fazendo perder a hora."

The final line should generally be closer to the stronger end of the spectrum.

However, do not force sexual content.

============================================================
CURIOSITY
============================================================

When the category is "Criar curiosidade", curiosity must come from a REAL conversational hook.

Use:

- unexpected observations
- playful theories
- specific teasing
- unfinished but meaningful thoughts
- intriguing contrasts
- confident predictions
- playful challenges

Do NOT manufacture fake suspense.

The person should want to respond because the message is interesting, not because the AI artificially withholds information.

============================================================
HUMOR
============================================================

Humor should feel spontaneous and socially intelligent.

Prefer:

- playful exaggeration
- unexpected comparisons
- confident teasing
- observations
- callbacks to the situation

Avoid:

- dad jokes
- obvious puns
- corny wordplay
- forced "😂😂😂"
- scripted jokes

============================================================
LENGTH
============================================================

Default to ONE short message.

Usually:
5-18 words.

Sometimes slightly longer if necessary for the joke or setup.

Do not write paragraphs.

Do not explain anything.

Do not add multiple alternatives inside the same response.

============================================================
EMOJIS
============================================================

Use emojis rarely.

Maximum 1 emoji.

Often no emoji is better.

============================================================
QUALITY FILTER
============================================================

Before returning the line, silently ask:

1. Would a young adult actually send this?
2. Does it sound confident?
3. Does it create some reaction?
4. Is there a reason to answer?
5. Is it stronger than a generic compliment?
6. Does it fit the selected category?
7. Could this be used on 100 random people?

If #7 is YES, rewrite it.

8. Does it sound like something an AI would generate?

If YES, rewrite it.

9. Does it sound like an outdated pickup line?

If YES, rewrite it.

10. Is it bold without crossing into disrespect, pressure or explicit sexual content?

If NO, rewrite it.

============================================================
MOST IMPORTANT RULE
============================================================

Do NOT optimize for politeness at the expense of personality.

Do NOT make every line safe and bland.

The user chose a PICK LINE feature because they want something they would not have thought of themselves.

Give them something with personality.

Make the line feel:

"That was smooth."

Not:

"That's a nice compliment."

============================================================

CATEGORY-SPECIFIC REQUIREMENT
============================================================

The category is not just a label.

The generated message MUST actually use the strategy implied by the category.

For example:

- teasing category = tease
- bold compliment = bold compliment
- story reply = react to the story context
- cold conversation = change the dynamic
- curiosity = create a genuine curiosity hook
- asking out = move naturally toward a date

Never simply mention the category.

============================================================
SOCIAL CALIBRATION
============================================================

If the selected category involves someone expressing disinterest, rejection or discomfort:

- respect the boundary
- do not pressure
- do not manipulate
- do not guilt-trip
- do not try to "convince" them
- keep the response light and respectful

For all other categories, maximize confidence and conversational impact.

============================================================

OUTPUT JSON ONLY:

{
"response": "..."
}

The response must be in $idioma.
''';

final user = '''
Create ONE contemporary, bold and genuinely usable message for:

$categoriaNomeLegivel

Push the creativity and confidence.

The message should feel premium, modern and immediately sendable.

Do not explain anything.
Do not mention the category.
Do not use quotation marks around the final response.
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
} catch (_) {
final result = await _chamarAnthropicPickLine(
system: system,
user: user,
);

final parsed = _parseSinglePickLine(result);

if (parsed.isNotEmpty) {
return parsed;
}

throw Exception('Both providers failed pick line');
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
Uri.parse('https://api.openai.com/v1/chat/completions'),
headers: {
'Content-Type': 'application/json',
'Authorization': 'Bearer $_openAiKey',
},
body: jsonEncode({
'model': _openAiModelPickLine,
'messages': [
{
'role': 'system',
'content': system,
},
{
'role': 'user',
'content': user,
},
],

// Um pouco mais de criatividade para as cantadas.
'temperature': 1.0,

// Uma única cantada não precisa de 1200 tokens.
'max_tokens': 250,

'response_format': {
'type': 'json_schema',
'json_schema': {
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
.timeout(const Duration(seconds: 25));

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

final choice = data['choices'][0];
final finishReason = choice['finish_reason'];

if (finishReason == 'length') {
// ignore: avoid_print
print(
'OpenAI pick line: cortado por max_tokens '
'(finish_reason=length). Corpo: ${response.body}',
);
}

return choice['message']['content'].toString();
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
} catch (_) {
final result = await _chamarAnthropic(
system: system,
user: user,
);

final parsed = _parseStructured(result);

if (parsed.isNotEmpty) {
return parsed;
}

throw Exception('Both AI providers failed');
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
} catch (_) {
final result = await _chamarAnthropicImage(
base64Image: base64Image,
system: system,
user: user,
);

final parsed = _parseStructured(result);

if (parsed.isNotEmpty) {
return parsed;
}

throw Exception('Both AI providers failed');
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
Uri.parse('https://api.openai.com/v1/chat/completions'),
headers: {
'Content-Type': 'application/json',
'Authorization': 'Bearer $_openAiKey',
},
body: jsonEncode({
'model': _openAiModel,
'messages': [
{
'role': 'system',
'content': system,
},
{
'role': 'user',
'content': user,
},
],
'temperature': 0.8,
'max_tokens': 1500,
'response_format': {
'type': 'json_schema',
'json_schema': {
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
.timeout(const Duration(seconds: 25));

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

final choice = data['choices'][0];

if (choice['finish_reason'] == 'length') {
// ignore: avoid_print
print(
'OpenAI texto: cortado por max_tokens '
'(finish_reason=length). Corpo: ${response.body}',
);
}

return choice['message']['content'].toString();
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
Uri.parse('https://api.openai.com/v1/chat/completions'),
headers: {
'Content-Type': 'application/json',
'Authorization': 'Bearer $_openAiKey',
},
body: jsonEncode({
'model': _openAiModel,
'messages': [
{
'role': 'system',
'content': system,
},
{
'role': 'user',
'content': [
{
'type': 'image_url',
'image_url': {
'url':
'data:image/jpeg;base64,$base64Image',
'detail': 'high',
},
},
{
'type': 'text',
'text': user,
},
],
},
],
'temperature': 0.8,
'max_tokens': 1500,
'response_format': {
'type': 'json_schema',
'json_schema': {
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
.timeout(const Duration(seconds: 30));

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

final choice = data['choices'][0];

if (choice['finish_reason'] == 'length') {
// ignore: avoid_print
print(
'OpenAI imagem: cortado por max_tokens '
'(finish_reason=length). Corpo: ${response.body}',
);
}

return choice['message']['content'].toString();
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