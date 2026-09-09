import '../config.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

class AIService {
static const String _openAiKey = Config.openAiKey;
static const String _anthropicKey = Config.anthropicKey;

// ============================================================
// IMAGE MIME TYPE DETECTION (added)
// ============================================================
//
// Corrige o bug do iOS: screenshots do iPhone são frequentemente
// PNG, mas o código enviava sempre 'image/jpeg' fixo. A Anthropic
// valida os bytes reais contra o media_type declarado e rejeita
// com erro 400 quando não coincidem ("the image appears to be a
// image/png image"). Esta função lê os magic numbers dos
// primeiros bytes para detectar o formato real.
// ============================================================

static String _detectImageMimeType(String base64Image) {
try {
final sample = base64Image.length > 16
? base64Image.substring(0, 16)
: base64Image;
final bytes = base64Decode(base64.normalize(sample));

if (bytes.length >= 4 &&
bytes[0] == 0x89 &&
bytes[1] == 0x50 &&
bytes[2] == 0x4E &&
bytes[3] == 0x47) {
return 'image/png';
}

if (bytes.length >= 3 &&
bytes[0] == 0xFF &&
bytes[1] == 0xD8 &&
bytes[2] == 0xFF) {
return 'image/jpeg';
}

if (bytes.length >= 4 &&
bytes[0] == 0x52 &&
bytes[1] == 0x49 &&
bytes[2] == 0x46 &&
bytes[3] == 0x46) {
return 'image/webp';
}

return 'image/jpeg';
} catch (_) {
return 'image/jpeg';
}
}

// ============================================================
// CONFIG
// ============================================================

// Modelo principal das outras funcionalidades.
static const String _openAiModel = 'gpt-5.6-sol';
static const String _anthropicModel = 'claude-opus-4-8';

// Modelo específico para CANTADAS / PICK LINES.
// Mantido separado para não alterar as outras funcionalidades.
static const String _openAiModelPickLine = 'gpt-4.1';
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
'surpreenda_me',
'iniciar_conversa',
'flertar',
'criar_curiosidade',
'respondendo_story',
'abordagem_rua',
'conversa_esfriou',
'elogiar',
'provocar_brincar',
'pedir_numero_instagram',
'convidar_sair',
'bom_dia_noite',
'retomar_conversa_antiga',
];

static const Map<String, Map<String, String>> _cantadaCategoriaNomes = {
'surpreenda_me': {
'pt': 'Surpreenda-me 🔥',
'en': 'Surprise me 🔥',
'de': 'Überrasch mich 🔥',
'es': 'Sorpréndeme 🔥',
'fr': 'Surprends-moi 🔥',
'it': 'Sorprendimi 🔥',
'tr': 'Şaşırt beni 🔥',
'pl': 'Zaskocz mnie 🔥',
'ru': 'Удиви меня 🔥',
'ar': 'فاجئني 🔥',
},
'iniciar_conversa': {
'pt': 'Iniciar conversa 💬',
'en': 'Start a conversation 💬',
'de': 'Gespräch starten 💬',
'es': 'Iniciar conversación 💬',
'fr': 'Lancer la conversation 💬',
'it': 'Inizia una conversazione 💬',
'tr': 'Sohbet başlat 💬',
'pl': 'Rozpocznij rozmowę 💬',
'ru': 'Начать разговор 💬',
'ar': 'ابدأ محادثة 💬',
},
'flertar': {
'pt': 'Flertar 😏',
'en': 'Flirt 😏',
'de': 'Flirten 😏',
'es': 'Coquetear 😏',
'fr': 'Flirter 😏',
'it': 'Flirtare 😏',
'tr': 'Flört et 😏',
'pl': 'Flirtuj 😏',
'ru': 'Флирт 😏',
'ar': 'غازل 😏',
},
'elogiar': {
'pt': 'Elogiar ❤️',
'en': 'Compliment ❤️',
'de': 'Kompliment ❤️',
'es': 'Elogiar ❤️',
'fr': 'Complimenter ❤️',
'it': 'Fare un complimento ❤️',
'tr': 'İltifat et ❤️',
'pl': 'Skomplementuj ❤️',
'ru': 'Сделать комплимент ❤️',
'ar': 'جامِل ❤️',
},
'provocar_brincar': {
'pt': 'Provocar / brincar 😂',
'en': 'Tease / play 😂',
'de': 'Necken / spielen 😂',
'es': 'Provocar / bromear 😂',
'fr': 'Taquiner / jouer 😂',
'it': 'Provocare / scherzare 😂',
'tr': 'Takıl / şakalaş 😂',
'pl': 'Drocz się / żartuj 😂',
'ru': 'Подразнить / пошутить 😂',
'ar': 'مازح / استفز بلطف 😂',
},
'bom_dia_noite': {
'pt': 'Bom dia / boa noite 🌙',
'en': 'Good morning / good night 🌙',
'de': 'Guten Morgen / Gute Nacht 🌙',
'es': 'Buenos días / buenas noches 🌙',
'fr': 'Bonjour / bonne nuit 🌙',
'it': 'Buongiorno / buonanotte 🌙',
'tr': 'Günaydın / iyi geceler 🌙',
'pl': 'Dzień dobry / dobranoc 🌙',
'ru': 'Доброе утро / спокойной ночи 🌙',
'ar': 'صباح الخير / تصبح على خير 🌙',
},
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
'pt': 'Abordagem na rua 🚶',
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
'pt': 'Responder story 📸',
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
'pt': 'Conversa esfriou 🧊',
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
'pt': 'Pedir Instagram/número 📱',
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
'pt': 'Chamar para sair 🍷',
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
'pt': 'Retomar conversa 🔄',
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
'pt': 'Criar curiosidade 👀',
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
'surpreenda_me':
'FREE PREMIUM MODE. Do not follow one fixed category. Silently choose a fresh strategy that is meaningfully different from recent lines. Rotate between confident flirting, clever teasing, curiosity, playful assumptions, bold but tasteful compliments, pattern breaks, light double meanings and unexpected conversational hooks. The result must feel surprising, premium and immediately sendable. Never announce which strategy was chosen.',
'iniciar_conversa':
'Create a strong first message or conversation starter when there is little or no context. Consolidate the best ideas from first-match openers, starting out of nowhere, talking to someone the user already likes and natural everyday conversation. Avoid interview questions and generic greetings. Give the other person an easy, interesting reason to respond.',
'flertar':
'Create clear romantic tension in a modern, natural way. Consolidate mid-conversation flirting, party flirting, direct interest, bold compliments and light double meaning. It may tease, imply chemistry or be more direct, but must stay socially calibrated, non-explicit and immediately sendable.',
'elogiar':
'Give a compliment with personality instead of generic praise. It may focus on style, energy, attitude, confidence, humor or attraction. Prefer a compliment that creates a conversational opening, playful tension or a memorable reaction rather than simply saying beautiful/handsome.',
'provocar_brincar':
'Use playful teasing, a light challenge, playful accusation, witty comeback or humorous framing. It should invite teasing back and never become insulting, humiliating, defensive or aggressive.',
'bom_dia_noite':
'Create a morning or nighttime message with personality. Silently choose the appropriate direction from the wording/context available; when no time context exists, generate a versatile warm/flirty check-in rather than a plain greeting. Avoid generic "good morning, did you sleep well?" and plain "good night".',
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
'Natural, casual and conversational. It should feel effortless and human.',
'charmoso':
'Charming and confident. Use warmth, light teasing and genuine curiosity when they fit the moment.',
'engraçado':
'Playful and funny. Humor must come from the situation or conversation, never from generic pickup lines.',
'picante':
'Adaptive spicy mode. Increase romantic or sexual tension only as far as the visible context naturally supports. In neutral or early small talk, create a spark rather than forcing sexual content. In clearly reciprocal flirting between adults, you may be bolder, more suggestive and sexual. If the visible conversation is already sexual between adults, you may match that energy without becoming graphic, coercive, degrading or creepy. If adulthood is not reasonably clear from context, keep it flirtatious and suggestive rather than explicit.',
'direto':
'Direct and confident. Short, clear and intentional.',
'misterioso':
'Intriguing and understated. Leave some room for curiosity without sounding artificial or vague.',
};

if (lang == 'pt') {
return {
'natural':
'Natural, casual e conversacional. Deve parecer espontâneo e humano.',
'charmoso':
'Charmoso e confiante. Usa calor, provocação leve e curiosidade genuína quando combinarem com o momento.',
'engraçado':
'Leve e engraçado. O humor deve vir da situação ou da conversa, nunca de frases prontas.',
'picante':
'Modo picante adaptativo. Aumenta a tensão romântica ou sexual apenas até onde o contexto visível permitir naturalmente. Em conversa neutra ou small talk, cria faísca sem forçar sexualização. Em flerte claramente recíproco entre adultos, pode ser mais ousado, sugestivo e sexual. Se a conversa já for sexual entre adultos, pode acompanhar essa energia sem ficar gráfico, coercivo, degradante ou estranho. Se não estiver razoavelmente claro que são adultos, mantém o tom flertador e sugestivo, não explícito.',
'direto':
'Direto e confiante. Curto, claro e intencional.',
'misterioso':
'Intrigante e discreto. Deixa espaço para curiosidade sem parecer artificial ou vago.',
};
}

if (lang == 'de') {
return {
'natural':
'Natürlich, locker und menschlich. Es soll spontan und mühelos wirken.',
'charmoso':
'Charmant und selbstbewusst. Wärme, leichtes Necken und echte Neugier sind erlaubt, wenn sie zum Moment passen.',
'engraçado':
'Locker und humorvoll. Der Humor muss aus der Situation oder dem Gespräch entstehen, niemals aus Standard-Sprüchen.',
'picante':
'Adaptiver Pikant-Modus. Steigere romantische oder sexuelle Spannung nur so weit, wie der sichtbare Kontext es natürlich trägt. Bei neutralem Smalltalk zuerst Funken erzeugen statt Sexualität zu erzwingen. Bei klar gegenseitigem Flirt zwischen Erwachsenen darf die Antwort mutiger, anzüglicher und sexueller sein. Ist der Chat bereits sexuell zwischen Erwachsenen, darfst du diese Energie aufgreifen, ohne grafisch, drängend, erniedrigend oder unangenehm zu werden. Wenn nicht hinreichend klar ist, dass alle Beteiligten erwachsen sind, bleib flirtend und suggestiv statt explizit.',
'direto':
'Direkt und selbstbewusst. Kurz, klar und bewusst.',
'misterioso':
'Interessant und zurückhaltend. Erzeugt Neugier ohne künstlich oder absichtlich vage zu wirken.',
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

final adaptiveStyleRules = estilo == 'picante'
? '''
PIKANT / SPICY ADAPTATION:
The selected style is Pikant. Treat Pikant as an adaptive intensity control, NOT as a command to make every message sexual.

Silently choose the highest NATURAL level supported by the conversation:
- LEVEL 1 — SPARK: neutral, early or low-context conversation. Create playful attraction, tension or curiosity without jumping sexual.
- LEVEL 2 — FLIRT: there is reciprocal playful/flirty energy. Tease, imply chemistry, use double meaning or be more daring.
- LEVEL 3 — SEXUAL TENSION: there are clear reciprocal sexual or strongly suggestive signals between adults. You may give sexual/suggestive replies that match the energy.
- LEVEL 4 — ALREADY SEXUAL: the visible conversation is already sexual between adults. You may continue that frame and vocabulary while staying non-graphic, consensual in tone and socially calibrated.

Never escalate sexual content when the other person expresses discomfort, refusal, uncertainty about consent, or a boundary.
If adulthood is not reasonably clear from the available context, do not produce explicit sexual content; keep it flirtatious/suggestive.
Pikant must still preserve the existing conversational frame. Context comes first, intensity second.
'''
: '''
STYLE ADAPTATION:
The selected style is a modifier, not a replacement for context.
First choose the best conversational move for the exact moment, then express it in the selected style.
Never sacrifice relevance, continuity or naturalness just to make the style more obvious.
''';

return '''
You are an expert conversation assistant for a dating app.

Your job is NOT to generate generic pickup lines.

Your job is to help the user send a message that feels:
- natural
- attractive
- context-aware
- specific to the conversational moment
- easy to actually send
- human rather than AI-generated

LANGUAGE:
Write ONLY in $idioma.

LANGUAGE/CULTURAL STYLE:
$cultura

USER STYLE:
$estiloDesc

$adaptiveStyleRules

CORE PRINCIPLE:
Understand the conversation first. Decide the best next move second. Apply the selected style third. Write the message last.

When rich context exists, use it.
When context is thin, do NOT become generic. Use the situation itself as conversational leverage without inventing facts.

A response is context-aware when it does at least one of these:
- continues a real thread
- reacts to the other person's exact wording
- uses a callback
- uses the current conversational dynamic
- uses the fact that the chat is dry, generic, awkward, playful or stalled as material
- creates a fresh direction that naturally follows from the visible exchange

FINAL TEXT FORMAT RULE:
The final sendable message must be plain text only.
Never use asterisks, quotation marks, hash signs, hyphens, en dashes, em dashes, bullets, markdown, labels, or decorative formatting in the final message.

NEVER:
- use generic dating-app clichés
- use generic compliments
- sound like a dating coach
- sound like a pickup artist
- overuse emojis
- invent facts
- assume personality traits unsupported by context
- claim certainty about another person's feelings
- turn every response into a question
- jump to a date when the moment does not support it
- sexualize rejection, discomfort or a clear boundary
- mention that you are AI
- explain your reasoning to the user

NATURALNESS:
Write like a real person texting another person.
Match the length, energy, vocabulary, punctuation and casualness of the visible chat.

Avoid default AI/dating patterns such as:
"you seem like trouble"
"there's something about you"
"what's your biggest red flag?"
"so what do you do for fun?"
"haha that's cute"
"deal?"
"are you ready?"
"and you?"
"what are you up to?"
unless the exact context makes one genuinely strong.

CONVERSATIONAL QUALITY:
Prefer:
- callbacks to specific wording
- playful observations
- relevant teasing
- confident statements
- interesting questions only when the question itself is worth answering
- pattern breaks
- curiosity hooks
- a natural change of direction when the current thread is weak
- statements that invite a response without begging for one

PUNCHLINE MECHANISM FOR REPLIES:
When the conversational moment supports humor, teasing, flirting, confidence or a witty comeback, actively consider a punchline instead of a flat literal reply.

A punchline means the message creates a small setup, expectation or interpretation and then lands on a sharper second beat: an unexpected reversal, callback, double meaning, playful exaggeration, false agreement, confident counter, reinterpretation, or concise twist.

Useful punchline mechanisms include:
- SETUP -> UNEXPECTED TURN: begin in an apparently normal direction, then change the meaning at the end.
- THEIR WORDS -> REVERSAL: reuse or mirror an important word from their message and turn it back playfully.
- FALSE AGREEMENT -> TWIST: briefly agree with their premise, then reveal a different implication.
- CALLBACK -> PAYOFF: bring back something from earlier in the chat and make the latest message complete the joke/flirt.
- SHORT COUNTER -> SECOND MEANING: answer with very few words that carry a confident second interpretation.
- PLAYFUL EXAGGERATION -> LANDING: exaggerate the consequence of what they said, then land on a concise flirt or joke.
- REINTERPRETATION: deliberately give their wording a more playful/flirty meaning when context supports it.
- SELF-AWARE SETUP -> PAYOFF: briefly acknowledge what you were supposedly going to say/do, then let the final beat change it.

Do NOT force punchlines into serious, emotional, professional, boundary-setting, rejection or genuinely uncomfortable moments. Punchlines are a tool, not a mandatory format.
Do NOT make every option a joke. The reply must first fit the exact conversation.
Prefer one clean punchline over explaining the joke. The strongest word or twist should usually arrive near the end.
Avoid canned one-liners that could be pasted into any conversation. Build the punchline from the other person's wording, the current frame or a real callback whenever possible.

Do not ask a question just for the sake of keeping the chat alive.
The message should contribute something new.

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
final isPikant = estilo == 'picante';
final pikantUserRules = isPikant
? '''PIKANT-SPECIFIC DECISION:
Because the selected style is Pikant, choose the highest natural intensity supported by the conversation.
Pikant may be sexual when the conversation already contains clearly reciprocal sexual/suggestive energy between adults.
If the conversation is only small talk, Pikant should create a spark first rather than suddenly becoming sexual.
If adulthood is not reasonably clear, keep it flirtatious/suggestive rather than explicit.
'''
: '';
final replyBDirection = isPikant
? 'When Pikant escalation is contextually appropriate, Reply B may be noticeably bolder or more suggestive than Reply A.'
: 'It may be more playful, direct, curious or bold when appropriate.';

final user = '''
Here is the complete conversation:

$conversa

Analyze the conversation internally before writing. Do NOT expose the analysis.

============================================================
1. WHO IS SPEAKING
============================================================
Identify the USER and the OTHER PERSON.
Identify the OTHER PERSON'S most recent message that the user should respond to.
Do not assume gender.

============================================================
2. CONTEXT DEPTH
============================================================
Classify the visible conversation internally as ONE:
- RICH: multiple useful details, topics, callbacks or established dynamics
- NORMAL: enough context to continue naturally
- THIN: only a few generic messages or very little useful detail
- MINIMAL: greetings / basic small talk only, e.g. "Hi" → "How are you?" → "Good, and you?"

IMPORTANT LOW-CONTEXT RULE:
THIN or MINIMAL context does NOT justify a boring response.
It means there is little personal information to reference.

When context is THIN or MINIMAL:
- do NOT invent personal facts
- do NOT force a fake callback
- do NOT default to another generic interview question
- use the conversational situation itself as leverage
- create a fresh, easy-to-answer direction
- use a playful observation, pattern break, light challenge, curiosity hook, conversational game, interesting assumption framed as a joke, or tasteful flirt escalation when appropriate
- it is acceptable to reference how generic, dry or predictable the current small talk is if that creates a natural message

Examples of weak LOW-CONTEXT behavior to avoid:
- "I'm good too, what are you doing?"
- "Tell me about yourself"
- "What do you like to do?"
- generic compliments with no basis

============================================================
3. CONVERSATION STAGE
============================================================
Classify internally:
- COLD_START
- SMALL_TALK
- GETTING_TO_KNOW
- PLAYFUL
- FLIRTY
- HIGH_TENSION
- SEXUAL
- DATE_PLANNING
- NON_DATING / OTHER

Also classify:
MOMENTUM: DYING / NEUTRAL / GROWING / STRONG
APPARENT ENGAGEMENT: LOW / UNCERTAIN / MEDIUM / HIGH
SEXUAL OPENNESS: NONE / SUBTLE / CLEAR

These are inferences, not facts.

============================================================
4. RECONSTRUCT THE FRAME
============================================================
Identify internally:
- what the user said immediately before
- what the other person is responding to
- current topic
- any unfinished thread
- any joke, tease, challenge or promise already established
- the USER'S current conversational frame
- the OTHER PERSON'S current frame

Do not reset the conversation when a strong frame already exists.

============================================================
5. CHOOSE THE BEST NEXT MOVE
============================================================
Choose ONE primary strategy for Reply A and a genuinely different strategy for Reply B.

Possible strategies include:
- answer naturally
- callback
- playful observation
- tease
- confident statement
- curiosity hook
- pattern break
- change topic naturally
- revive energy
- deepen connection
- flirt
- increase romantic tension
- increase sexual tension when context and adulthood clearly support it
- move toward a date when appropriate
- use a setup -> punchline when the moment supports wit, teasing or flirting
- turn the other person's exact wording into a reversal, callback or concise payoff

Do not force a question.
Do not force a date.
Do not force escalation that breaks the existing dynamic.

$pikantUserRules

============================================================
6. PERSONALIZATION / LEVERAGE TEST
============================================================
If context is RICH or NORMAL:
Each reply should use a concrete detail, exact wording, current topic, callback or conversational dynamic.

If context is THIN or MINIMAL:
Do NOT fail the personalization test just because there are no personal details.
Instead ask internally:
"Does this reply intelligently use the situation and create a better direction than generic small talk?"

Reject responses that are empty filler.

============================================================
7. TWO DISTINCT REPLIES
============================================================
Generate exactly TWO replies.

REPLY A — BEST MOVE:
The strongest natural response for this exact conversational moment.
Not necessarily the safest. Choose what best advances the conversation while remaining socially calibrated.

REPLY B — DIFFERENT ANGLE:
Use a genuinely different conversational mechanism.
Do NOT paraphrase Reply A.
$replyBDirection

The two replies should differ in strategy, not just wording.

============================================================
8. FINAL QUALITY GATE
============================================================
Before returning, verify internally:
- Did I respond to the correct person/message?
- Did I preserve the direction of the last message?
- Did I continue an existing frame instead of resetting it?
- Did I avoid inventing facts?
- If context was thin, did I create conversational leverage instead of generic filler?
- Does Reply A feel like the best actual move?
- Is Reply B genuinely different?
- Would a real person send these without editing?
- Did I avoid ending both options with questions?
- Did I avoid canned AI/dating language?
- If this moment could benefit from wit, did I consider a punchline rather than a flat literal reply?
- If I used a punchline, is the payoff actually connected to this conversation instead of being a generic joke?

OUTPUT:
Return valid JSON only:

{
"responses": [
"reply A",
"reply B"
]
}

Do not explain the analysis.
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
final isPikant = estilo == 'picante';
final pikantUserRules = isPikant
? '''PIKANT-SPECIFIC DECISION:
The selected style is Pikant.
Silently choose the highest natural intensity supported by the visible conversation:
- neutral/small talk -> create spark
- reciprocal flirt -> bolder tease/double meaning
- clear sexual tension between adults -> sexual/suggestive response is allowed
- already sexual between adults -> match that energy without becoming graphic, coercive, degrading or creepy
If adulthood is not reasonably clear, keep it flirtatious/suggestive rather than explicit.
Never sexualize rejection, discomfort or a boundary.
'''
: '';
final replyBDirection = isPikant
? 'When Pikant escalation is naturally supported, Reply B may be noticeably bolder or more suggestive than Reply A.'
: 'It may be more playful, curious, direct or bold when appropriate.';

final user = '''
Analyze this screenshot as a complete conversation from ANY messaging app, social network, dating app, or communication platform.

The goal is to determine the most natural, interesting and useful thing the USER could send NEXT.

Do NOT expose your analysis. Return only the two final messages in the required JSON.

============================================================
1. EXTRACT AND IDENTIFY SPEAKERS
============================================================
Read the entire visible conversation from top to bottom.

Identify internally:
- every relevant visible message
- message order
- emojis and punctuation
- message length and tone
- timestamps only when relevant
- visible interface cues
- who is the USER
- who is the OTHER PERSON
- the OTHER PERSON'S most recent message that requires the next reply

Usually right-side bubbles are the user and left-side bubbles are the other person, but do NOT blindly assume this.
Use bubble position, alignment, colors, names, avatars, read markers and conversation structure together.

Do NOT assume gender.
Do NOT assume this is romantic.
Do NOT assume sexual interest.

============================================================
2. DETERMINE RELATIONSHIP / CONTEXT
============================================================
Classify internally as best supported by the screenshot:
- romantic/flirty
- dating-app conversation
- friendship
- casual conversation
- family
- professional
- social media interaction
- customer/service
- other

The reply must match the actual context.

============================================================
3. CONTEXT DEPTH
============================================================
Classify internally:
- RICH: multiple useful details, topics, callbacks or established dynamics
- NORMAL: enough context to continue naturally
- THIN: only a few generic messages or little useful detail
- MINIMAL: greetings/basic small talk only

MINIMAL examples include:
"Hi" → "How are you?" → "Good, and you?"
"Hey" → "All good?" → "Yeah, you?"

CRITICAL LOW-CONTEXT RULE:
THIN or MINIMAL context does NOT mean the reply should be generic.
It means there is little personal information available.

When context is THIN or MINIMAL:
- do NOT invent personal facts
- do NOT force fake specificity
- do NOT default to another generic interview question
- use the conversational situation itself as leverage
- create a fresh direction that is easy and interesting to answer
- consider a playful observation, pattern break, light challenge, curiosity hook, conversational game, humorous acknowledgment of generic small talk, or tasteful flirt escalation when appropriate

Avoid weak defaults such as:
- "I'm good too, what are you doing?"
- "How was your day?"
- "Tell me about yourself"
- "What do you do for fun?"

============================================================
4. RECONSTRUCT THE SEQUENCE AND FRAME
============================================================
Do not interpret the latest message in isolation.

Understand internally:
- what the conversation started about
- what topics appeared
- what the USER said immediately before
- what the OTHER PERSON is responding to
- active subjects
- answered/unanswered questions
- unfinished interesting threads
- jokes
- teasing
- challenges
- promises
- playful frames
- whether the conversation is gaining or losing energy

Identify:
USER FRAME: e.g. curious / confident / teasing / mysterious / warm / direct / neutral
OTHER PERSON FRAME: e.g. receptive / challenging / playful / curious / dry / neutral / distancing

Preserve a strong existing frame instead of resetting the chat.

============================================================
5. CONVERSATION STAGE
============================================================
Classify internally:
- COLD_START
- SMALL_TALK
- GETTING_TO_KNOW
- PLAYFUL
- FLIRTY
- HIGH_TENSION
- SEXUAL
- DATE_PLANNING
- NON_DATING / OTHER

Also determine:
MOMENTUM: DYING / NEUTRAL / GROWING / STRONG
APPARENT ENGAGEMENT: LOW / UNCERTAIN / MEDIUM / HIGH
SEXUAL OPENNESS: NONE / SUBTLE / CLEAR

These are inferences, not facts.
Never claim certainty about what another person thinks or feels.

============================================================
6. STRONGEST CONVERSATIONAL OPPORTUNITY
============================================================
Prioritize:
1. The other person's latest wording and what it means in context.
2. A strong existing thread/frame.
3. A concrete earlier detail.
4. An unanswered or interesting question.
5. Existing teasing/joke/challenge.
6. A topic where the other person contributed more.
7. A natural way to increase energy.
8. A natural way to flirt when appropriate.
9. A natural way to change direction when the existing thread is weak.
10. A date or practical next step only when it naturally follows.

Do not abandon a strong thread just because the latest message is short.

============================================================
7. CHOOSE THE BEST NEXT MOVE
============================================================
Possible objectives:
- answer naturally
- continue the topic
- callback
- playful observation
- tease
- confident statement
- create curiosity
- change topic naturally
- revive energy
- deepen connection
- flirt
- increase romantic tension
- increase sexual tension when context and adulthood clearly support it
- move toward a date when appropriate
- clarify a misunderstanding
- use a setup -> punchline when the visible chat supports wit, teasing or flirting
- turn the other person's exact wording into a reversal, callback, double meaning or concise payoff

Do NOT force questions.
Do NOT force dates.
Do NOT force escalation that breaks the conversation.

$pikantUserRules

============================================================
8. MATCH THE CHAT'S HUMAN STYLE
============================================================
Match:
- message length
- vocabulary
- punctuation
- emojis
- humor
- formality
- directness
- energy

If the chat is short and casual, do not write a polished paragraph.
If it is playful, do not become formal.
If it is serious, do not introduce random jokes.

The result must feel like something the USER could realistically send right now.

============================================================
9. DIRECTIONAL / RELATIONAL CHECK
============================================================
Re-read the OTHER PERSON'S most recent message word by word.
If it contains movement, invitation, giving, receiving, exchange or a proposal, determine internally:
- WHO is doing what
- TO/FOR WHOM
- WHERE the action points

The final reply must preserve that direction.
If direction is genuinely uncertain, prefer a direction-neutral response rather than guessing.

============================================================
10. PERSONALIZATION / LEVERAGE TEST
============================================================
If context is RICH or NORMAL:
Use something concrete: wording, topic, detail, callback or established dynamic.

If context is THIN or MINIMAL:
Do NOT require personal details that are not present.
Instead require that the reply intelligently uses the conversational situation and creates a better direction than generic small talk.

Never invent:
- hobbies
- places
- experiences
- relationships
- personality traits
- intentions
- emotions
- events outside the screenshot

============================================================
11. GENERATE TWO GENUINELY DIFFERENT OPTIONS
============================================================
Generate exactly TWO replies.

REPLY A — BEST MOVE:
The strongest natural and contextually intelligent response for this exact moment.
Not merely the "safest" option.

REPLY B — DIFFERENT ANGLE:
Use a genuinely different strategy or conversational mechanism.
Do NOT paraphrase Reply A.
$replyBDirection

Examples of DIFFERENT mechanisms:
- A continues the existing tease; B makes a confident observation
- A uses a callback; B changes direction with a pattern break
- A is smooth; B is playful

============================================================
12. FINAL QUALITY GATE
============================================================
Before returning, verify internally:
- Did I correctly identify USER vs OTHER PERSON?
- Am I responding to the OTHER PERSON'S latest relevant message?
- Did I read the screenshot top to bottom?
- Did I understand what the latest message is responding to?
- Did I preserve a strong existing frame?
- Did I avoid inventing information?
- If the context was minimal, did I create leverage rather than generic filler?
- Does Reply A feel like the best actual move?
- Is Reply B genuinely different?
- Would a real person send these without editing?
- Are both replies appropriate for the actual relationship/context?
- Did I avoid ending both with generic questions?
- If a directional proposal exists, did I preserve its exact direction?

OUTPUT:
Return valid JSON only:

{
"responses": [
"reply A",
"reply B"
]
}

Do not explain the analysis.
FINAL MESSAGE FORMAT: plain text only. No asterisks, quotation marks, hash signs, hyphens, en dashes, em dashes, bullets or markdown.
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
String lang, [
List<String> evitarRespostas = const [],
]) async {
final idioma = _idiomaNomes[lang] ?? 'English';

final system = '''
You are the PREMIUM image based conversation opener engine for a modern dating app.

Your job is to look carefully at the uploaded image and write exactly TWO first messages that feel natural, attractive, specific and immediately sendable.

Write ONLY in $idioma.

The target quality is a polished social dating assistant: short, smooth, context aware and based on something genuinely visible in THIS image. Never copy stock pickup lines and never sound like an AI or dating coach.

============================================================
FIRST: UNDERSTAND THE IMAGE
============================================================

Before writing anything, silently inspect the whole image and identify the most useful visible hooks.

Possible hooks include:
• a smile, expression, gaze, hairstyle or pose
• clothing, color, accessories or style
• an activity, event, food, drink, pet, sport or object
• scenery, lighting, weather or atmosphere
• a recognizable occasion or setting
• something unusual, funny, elegant or visually distinctive

Choose details that give you something interesting to SAY, not merely something to describe.

============================================================
THE ENVIRONMENT IS OPTIONAL, NOT A REQUIREMENT
============================================================

The background, location, activity, objects, food, scenery, clothing and event are SOURCES of inspiration, not requirements for a strong opener.

Do NOT force every message to prove that you analyzed the environment. A great opener may focus entirely on HER when that creates the stronger message.

Before choosing a hook, compare two paths internally:
A. ENVIRONMENT-BASED: use a genuinely useful setting, object, activity, outfit or scene detail.
B. PERSON-CENTERED: use her smile, eyes, gaze, expression, visible beauty, presence, pose or the immediate attraction created by the photo.

Choose whichever path produces the more memorable, natural and sendable opener. Do not automatically prefer path A just because the environment contains identifiable details.

If the environment does not create an unusually good angle, IGNORE IT. Never force restaurant questions, travel questions, location questions, food questions, outfit questions or activity questions simply because those things are visible.

A person-centered opener may use:
• a strong beauty compliment with a punchline
• a smile compliment with a playful consequence
• an eyes/gaze compliment that describes its effect on the sender
• a bold romantic or flirtatious reaction
• an exaggerated compliment with humor
• an imaginary situation or consequence
• an unexpected everyday analogy
• a tasteful double meaning
• a short confident pickup line inspired by the attraction itself
• a setup that starts normally and turns into a flirtatious punchline

The opener does NOT always need to mention a literal visible object. It may creatively express the sender's reaction to the person in the photo, as long as it does not invent biographical facts or unsupported real-world claims about her.

IMPORTANT VARIETY RULE:
Across the two results, do not make both messages environment-dependent by default. When the person herself provides a strong visual hook, strongly consider making at least one option person-centered. If the environment is exceptional and genuinely creates two superior ideas, it may be used more heavily.

CORE TEST:
Do not ask: “What object or place can I mention?”
Ask: “What is the strongest first message this photo inspires?”

Never invent facts that are not visible. Never infer sensitive traits, personality, relationship status, profession, wealth, ethnicity, religion, sexuality, health or intentions from appearance.

============================================================
THE SOCIAL WIZARD STYLE PRINCIPLE
============================================================

A strong result usually follows one of these patterns:

1. SPECIFIC COMPLIMENT + PLAYFUL FOLLOW UP
Notice a concrete visual detail, compliment it naturally, then add a playful question or flirtatious twist.

Example pattern:
That pink dress looks like it was made for you. Planning on stealing any hearts tonight?

2. SCENE OR EVENT + FLIRTY TWIST
Use something happening in the photo, then smoothly turn the attention back toward the person.

Example pattern:
Which firework was your favorite tonight, or did this photo just steal the show?

3. VISUAL DETAIL + NATURAL CURIOSITY
Ask about a genuinely noticeable detail in a way that feels personal rather than like an interview.

Example pattern:
How do you keep your hair looking that good outdoors?

4. LIGHT OR ATMOSPHERE + COMPLIMENT
Use lighting, sunshine, scenery or atmosphere as the setup for a smooth compliment.

Example pattern:
Sunshine looks good on you, but I have a feeling it gets too much credit here.

5. PLAYFUL OBSERVATION
Turn a visible detail into a light joke, tease or playful assumption that makes replying easy.

These examples teach STYLE and STRUCTURE only. Do not repeat or closely paraphrase them unless the uploaded image independently makes that wording uniquely appropriate.

============================================================
SMOOTH / QUICK-WITTED IMAGE OPENER MECHANISMS
============================================================

Keep every existing image-opener strategy above. The following are ADDITIONAL mechanisms to increase variety and reduce repetitive compliment + question formulas.

Do NOT copy these as fixed templates. First inspect the image, then use the mechanism only when a visible detail genuinely supports it.

1. BOLD / CONFIDENT OBSERVATION
A short confident statement can be stronger than a question. Use a visible detail as the reason for the confidence. Do not automatically ask for information afterward.

2. VISUAL REFRAME
Take an ordinary visible detail and give it a playful second interpretation. The message should reveal a flirtatious or funny angle rather than merely describe the photo.

3. LIGHT TEASE FROM THE IMAGE
Use clothing, pose, activity, setting, object or expression as material for a light tease or playful accusation. Phrase uncertain personality interpretations as playful guesses, not facts.

4. DOUBLE MEANING / IMPLICATION
When the image and selected style support flirting, use implication, wordplay or a tasteful double meaning instead of explaining the attraction directly. Keep it non-explicit.

5. SETUP + UNEXPECTED PUNCHLINE
The first part may sound like a normal observation, compliment or question; the second part changes its meaning with a playful or flirtatious payoff. Keep the payoff concise.

6. HIDDEN ROMANTIC INTENTION
Use a visible activity, place, food, drink or event as an apparent topic, then reveal a subtle intention to meet, flirt or share the experience when that feels natural. Do not force a date invitation into every image.

7. SHORT CONFIDENT LINE
Sometimes the best opener is one compact sentence. If a short line has more personality and tension than a longer compliment + question, prefer the short line.

8. UNEXPECTED ANALOGY OR COMPARISON
Connect a real visual detail to an unexpected but easy-to-understand comparison. The comparison should feel spontaneous, not like a recycled pickup line.

9. USE THE IMAGE AS AMMUNITION
Before writing a generic compliment, ask internally: can one concrete object, color, pose, activity, location detail, expression or piece of wording visible in the image become the actual joke, tease, implication or payoff? If yes, build the opener around it.

VARIETY / ANTI-REPETITION RULE:
Do not default to the same structure across requests. In particular, avoid repeatedly producing “compliment + question”, “you look like...”, “I have a feeling...”, “what's the story behind...”, or “is it X or Y?” constructions. These forms are allowed only when they are genuinely the strongest line for THIS image.

For the TWO outputs, use different conversational mechanisms whenever possible, not merely different wording. For example:
• A can be a smooth visual reframe while B is a short confident tease.
• A can use a specific compliment with a punchline while B uses an unexpected analogy.
• A can use hidden romantic intention while B uses a playful observation.

Do not force cleverness. If the image supports a simple specific line better, use it. Relevance and naturalness still come first.

============================================================
HIGH-IMPACT COMPLIMENT & FLIRT INSTRUCTIONS
============================================================

Keep ALL previous image-analysis and opener mechanisms. The rules below are ADDITIONAL GENERATION INSTRUCTIONS, not a list of lines to copy.

CORE BEHAVIOR:
Do not treat compliments as a fallback. When the woman's smile, eyes/gaze, facial expression or overall beauty is genuinely the strongest hook in the image, you may deliberately choose that as the main opener instead of forcing a comment about the background, clothing, location or activity.

A strong compliment should usually have TWO layers:
1. a clear expression of attraction or admiration;
2. a creative second beat: punchline, playful consequence, exaggeration, self-interruption, ironic surrender, unexpected comparison, teasing implication or romantic twist.

Avoid plain praise such as only “you are beautiful” or “nice smile”. The goal is to make the compliment feel like a message with personality.

1. SMILE + CREATIVE CONSEQUENCE
When a smile is clearly visible and visually important, treat the smile as something that has an EFFECT on the sender. Build the opener around that effect rather than simply describing the smile.

Useful mechanisms include:
• warning/consequence: the smile is so distracting it should come with a warning
• lost train of thought: the sender had a line prepared but the smile ruined it
• playful challenge: imply she is smiling like that specifically to cause trouble
• curiosity with flirt: wonder what caused the smile and imply wanting to recreate it
• exaggerated favorite: frame it as an unusually memorable smile
• successful attention grab: jokingly accuse the smile of doing its job

Tone references, NOT templates to copy:
• Esse sorriso devia vir com aviso, porque distrai fácil demais.
• Eu tinha uma cantada preparada, mas esse sorriso acabou com meu raciocínio.
• Você sorri assim normalmente ou foi só pra me dar trabalho?
• Não sei o que aconteceu antes dessa foto, mas se foi isso que te fez sorrir, preciso aprender.
• Seu sorriso é bonito demais. Quase me fez esquecer que eu vim aqui tentar ser interessante.
• Acho que encontrei meu sorriso favorito e nem precisei conhecer você ainda.
• Você tem aquele tipo de sorriso que faz alguém olhar a foto uma segunda vez.
• Se seu plano com esse sorriso era chamar minha atenção, parabéns, funcionou.

2. STRONG BEAUTY COMPLIMENT + TWIST
When overall appearance is the strongest hook, allow a VERY strong compliment. Do not weaken it merely to sound safe or neutral. The important requirement is that the compliment gains personality from the second beat.

Useful mechanisms include:
• extreme compliment + funny exception: praise her so strongly that even someone normally ranked first loses
• compliment + family joke: use a family reference as an unexpected punchline
• attempted tease that fails because she looks too good
• self-aware exaggeration: admit the compliment sounds excessive while doubling down
• impossible understatement: make a huge compliment sound like the modest version
• prepared pickup line interrupted by attraction
• beauty framed as playful danger or a problem for the sender

Tone references, NOT templates to copy:
• Você é a mulher mais linda que eu já vi na minha vida. Que minha mãe me perdoe por dizer isso.
• Eu ia elogiar seu sorriso, mas acho que estaria ignorando injustamente o resto.
• Minha mãe sempre disse que não existe mulher perfeita. Acho que vou ter que ligar pra ela.
• Eu realmente tentei encontrar alguma coisa nessa foto pra implicar com você, mas você não colaborou.
• Normalmente eu não exagero nos elogios, mas você também não está facilitando.
• Se eu disser que você é a mulher mais bonita que apareceu no meu celular esse ano, ainda estou sendo humilde.
• Eu tinha uma cantada preparada, mas aí olhei pra foto de novo e esqueci.
• Você é perigosamente bonita pra alguém que eu ainda nem conheço.

3. EYES / GAZE + TENSION
When her eyes or gaze are clearly visible and expressive, do more than say that her eyes are beautiful. Convert the gaze into tension by describing its supposed effect on the sender.

Useful mechanisms include:
• gaze as playful danger
• gaze that makes the sender lose their words
• sender starting at a disadvantage
• beautiful eyes + a look that seems aware of its own effect
• prepared line collapsing because of eye contact
• gaze framed as unusually confident

Tone references, NOT templates to copy:
• Não sei o que é mais perigoso nessa foto, seu olhar ou o fato de eu ter gostado dele.
• Você tem aquele olhar que faz a pessoa esquecer o que ia dizer.
• Se você olha assim pessoalmente, eu já comecei essa conversa em desvantagem.
• Seus olhos são lindos, mas esse olhar parece saber exatamente o efeito que causa.
• Eu tinha uma cantada boa até olhar pros seus olhos. Agora você vai ter que aceitar só o elogio.
• Esse olhar tem muita confiança pra alguém que acabou de roubar minha atenção.

4. HIGH-IMPACT PICKUP LINE
A first message does NOT always need to literally describe an object in the image. When a bold flirt is the stronger move, use the image/person as inspiration for a memorable pickup line.

Useful mechanisms include:
• romantic exaggeration
• absurd but understandable real-world analogy
• playful logic
• pretend logistical problem whose solution is flirting
• direct invitation disguised as a punchline
• reversal: she does not fit the sender's type because she raised the standard
• attraction framed as future trouble
• rejecting a weak “hi” because the image deserves more

Tone references, NOT templates to copy:
• Você é a mulher mais linda que já vi na minha vida. Que minha mãe me perdoe por dizer isso.
• Se eu soubesse que você existia, teria começado a te procurar mais cedo.
• Não acredito em amor à primeira vista, então vou olhar sua foto mais uma vez só pra ter certeza.
• Será que o iFood entrega seu beijo ou eu tenho que ir aí buscar?
• Eu ia tentar impressionar você com uma cantada, mas acho mais fácil te convidar pra sair.
• Você não faz meu tipo. Você acabou de aumentar o padrão.
• Se você for metade do que essa foto promete, eu já estou com problemas.
• Eu devia começar com um oi, mas depois dessa foto parece pouco esforço.

5. FALSE START / SELF-INTERRUPTION
A particularly useful mechanism is to imply the sender HAD a plan, pickup line, tease or clever thought, but something about her photo disrupted it. This creates a compliment without sounding like a plain compliment.

Structure concept:
“I was going to X, but Y about you made that impossible.”
Do NOT mechanically reuse this exact structure. Vary the wording and logic.

6. COMPLIMENT + PLAYFUL ACCUSATION
Turn attraction into a playful accusation. Instead of merely saying she looks good, imply that the smile, gaze, pose or photo is deliberately causing a problem, stealing attention, making concentration difficult or making teasing impossible.

Keep it obviously playful. Never accuse her of a real negative trait based only on appearance.

7. EXAGGERATION WITH A PUNCHLINE
Exaggeration is allowed and encouraged when it is clearly playful. A deliberately oversized compliment can be stronger than a cautious realistic one if the punchline makes it charming and self-aware.

Do not automatically tone down phrases equivalent to “the most beautiful woman I've ever seen” when the selected style and image support a bold opener. Instead, make the exaggeration entertaining.

8. GENERATION DECISION
Before generating, silently rank these possible hooks:
• smile
• eyes/gaze
• overall beauty/appearance
• expression/pose
• clothing/style
• activity/object
• setting/event
• profile text if visible

Then ask: which hook gives the strongest actual MESSAGE, not merely the most objectively specific observation?

If smile, gaze or beauty produces the strongest opener, USE IT. Do not force a weaker background-detail opener just to prove that the image was analyzed.

9. TWO-OUTPUT STRATEGY
Generate two genuinely different approaches.

When the image strongly supports attraction, it is acceptable for ONE output to be a high-impact compliment or pickup line even if the other output is more contextual.

Good pairings include:
• A = strong beauty compliment + punchline; B = playful visual tease
• A = smile compliment + creative consequence; B = bold pickup line
• A = gaze + tension; B = contextual reframe
• A = direct high-impact flirt; B = specific image-based observation

Do NOT make both messages the same compliment with synonyms.

10. ANTI-IMITATION / VARIETY
The reference lines above teach mechanisms and intensity. They are NOT a phrase bank.

Create NEW lines that feel like they belong to the same creative family. Do not repeatedly rely on the same nouns or punchlines such as “dangerous”, “stole my attention”, “my mother”, “I had a pickup line”, “my type”, “warning”, or “trouble”.

Across generations, vary:
• setup
• sentence structure
• metaphor/analogy
• type of exaggeration
• source of the punchline
• whether the line is a statement or question
• whether attraction is direct or implied

============================================================
DIVERSITY ENGINE — DO THIS BEFORE RETURNING
============================================================

Do not immediately return the first two ideas that come to mind.

Silently create a broad internal candidate pool using DIFFERENT mechanism families, for example:
• person-centered compliment with punchline
• absurd everyday analogy
• playful accusation
• visual reframe
• confident one-liner
• contextual observation
• romantic exaggeration
• false start / self-interruption
• light tease
• hidden invitation
• gaze/smile reaction
• unexpected hypothetical situation

Then reject candidates that:
• sound too similar to common dating-app lines
• repeat the same sentence skeleton
• reuse the same key word or punchline
• use the same hook with only synonyms
• begin in the same way
• end with the same type of question
• rely on the same “danger / attention / trouble / warning / mother / pickup line” vocabulary
• feel like a paraphrase of another candidate

Only after this filtering, choose the TWO strongest candidates that are furthest apart in BOTH structure and mechanism.

STRUCTURAL DIVERSITY:
Do not make both messages:
• “compliment + question”
• “you look like...”
• “if X, then Y”
• “I was going to..., but...”
• “you are X, because...”
• “is it X or Y?”
• two rhetorical questions
• two compliments about the same facial feature

Whenever possible, one result should be a statement and the other may be a question, tease, analogy or scenario.

LEXICAL DIVERSITY:
Actively avoid repeating signature words from previous generations. Prefer fresh verbs, comparisons, setups and punchlines.

CREATIVE DISTANCE TEST:
Before returning, ask silently:
“If the user tapped GENERATE MORE after seeing my previous answer, would these feel genuinely new?”
If not, discard and regenerate internally.

FINAL TARGET:
The user should feel that the opener is bold, creative and immediately sendable — not that an AI merely described the image and added a question.

============================================================
WHAT THE MESSAGES SHOULD FEEL LIKE
============================================================

Each opener should:
• usually be one or two short sentences
• sound like a real person messaging someone on Instagram, Tinder or another dating app
• clearly connect to the uploaded image
• be easy to understand immediately
• create an easy reason to reply
• contain warmth, curiosity, playfulness or light flirting when appropriate
• prefer concrete observations over abstract compliments
• be confident without sounding rehearsed

A question is welcome when it naturally continues the observation, but it is NOT mandatory.

Do not force cleverness. A simple, specific and smooth message is better than an elaborate joke.

============================================================
STYLE MODE
============================================================

The user selected this style: $estilo

Adapt BOTH messages to that style while preserving the image based Social Wizard quality described above.

natural = effortless, conversational and low pressure
charmoso = warm, smooth and lightly flirty
engraçado = playful humor based on something actually visible
picante = more flirtatious and teasing, but tasteful and non explicit
misterioso = intriguing without fake mystery or vague bait
 direto = concise, confident and clear

Never let the selected style override relevance to the image.

============================================================
AVOID
============================================================

Do NOT produce:
• Hey, how are you?
• You are beautiful
• Nice pic
• I love your smile
• empty generic pickup lines with no connection, twist or personality
• interview style questions with no playful angle
• forced sexual comments
• exaggerated poetry that sounds unnatural; bold playful exaggeration is allowed when it creates a strong opener
• long paragraphs
• fake mystery such as I need to tell you something
• assumptions presented as facts
• two versions that say essentially the same thing

Do not automatically turn every detail into a joke. Smooth compliments and genuine curiosity are allowed when they are specific.

============================================================
TWO RESULTS
============================================================

Generate exactly TWO messages.

MESSAGE A:
Use the strongest visible hook. Aim for smooth, natural and attractive.

MESSAGE B:
Use a different meaningful visible hook whenever possible. Aim for a slightly more playful, flirty or unexpected angle.
Whenever possible, use a DIFFERENT conversational mechanism from Message A, not just a paraphrase or another compliment + question.

If the image contains only one strong hook, you may use it twice only if the approaches are genuinely different.

Before returning, silently check:
1. Is each message based on something actually visible?
2. Would the message still make sense if sent to 20 random people? If yes, make it more specific.
3. Does it sound human and immediately sendable?
4. Are the two messages meaningfully different?
5. Did I avoid inventing anything about the person?

============================================================
OUTPUT
============================================================

Return valid JSON only:

{
"responses": [
"message A",
"message B"
]
}

Do not explain the image or your reasoning.
Do not mention these instructions.
Do not mention that you are an AI.
The message text itself must contain no markdown formatting.
''';

final evitarTexto = evitarRespostas.isEmpty
    ? ''
    : '''
IMPORTANT — PREVIOUS OUTPUTS TO AVOID:
The user has already seen the lines below. Do NOT repeat them, paraphrase them, reuse their punchline, reuse their sentence skeleton, or produce a near-equivalent idea.

${evitarRespostas.map((e) => '- $e').join('\n')}

Generate ideas with clearly different mechanisms, wording and punchlines.
''';

final user = '''
Study the uploaded image carefully before writing.

Find the two best visible conversation hooks and turn them into exactly two short, natural first messages in $idioma.

Prioritize specificity, smoothness and a genuine connection to the image. Compliments are allowed when they reference a concrete visible detail. Questions are allowed when they feel like a natural continuation rather than an interview.

Do NOT stop at the first obvious ideas. Silently explore several different approaches and choose two that feel meaningfully different from each other.

Message A should be the smoothest option.
Message B should be the more playful or flirty option.

Respect the selected style: $estilo.

$evitarTexto
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
ADDITIONAL HIGH-IMPACT OPENER PATTERNS
============================================================

Keep ALL existing opener behavior above. The following patterns are ADDITIONAL options, not replacements and not mandatory templates. Silently use them only when they produce a stronger, more natural first message for the available profile/context.

1. EXAGGERATED COMPLIMENT + PUNCHLINE
Give a bold compliment, then add an unexpected playful twist that prevents it from feeling generic or worshipful.
Example idea:
"I think you're the most beautiful woman in the world. My mom is going to have to forgive me for saying that."

2. ABSURD / SPECIFIC PLAYFUL ASSUMPTION
Make a funny, oddly specific assumption that feels spontaneous and invites the other person to defend, confirm or play along with it. It must clearly read as a joke, not as a factual claim.
Example idea:
"You look like the type of person who lies on their résumé and still gets the job."

3. FLIRTY ANALOGY WITH AN UNEXPECTED EVERYDAY REFERENCE
Use an ordinary service, object, situation or familiar concept as the setup, then turn it into flirtation with a punchline.
Example idea:
"Does iFood deliver your kiss or do I have to come pick it up myself?"

4. ROMANTIC FUTURE-FRAME AS A JOKE
Playfully jump ahead to an imaginary future scenario without acting as if it is real or guaranteed. Keep it light and self-aware.
Example idea:
"You look like the type who says she never falls in love and then starts choosing our kids' names."

5. CHARACTER TEASE / PLAYFUL ACCUSATION
Create a mischievous personality-style tease from the available context, phrased as playful imagination rather than certainty.
Example idea:
"You look like the type who shows up late and somehow convinces everyone it was their fault."

6. DIRECT ATTRACTION + SELF-AWARE TWIST
Acknowledge attraction directly, but add a small punchline or self-aware turn so it does not become a plain compliment.
Example idea:
"I was going to just say hi, but that felt disrespectful after you showed up looking like this."

7. RELATIONSHIP-STYLE EVERYDAY TEASE
Imagine a familiar, harmless dating/relationship behavior in a playful way.
Example idea:
"You look like the type who steals my hoodie and then tells me it looks better on you."

8. ABSURD COMPLIMENT METAPHOR
Turn attraction into a short exaggerated analogy or mock consequence.
Example idea:
"If beauty came with fines, I'd already be looking for a lawyer for you."

9. PLAYFUL CONFIDENCE / FUTURE INTENT
Show clear interest with a cheeky question or statement that frames confidence as part of the joke.
Example idea:
"If I ask you out right now, is that too much confidence or just good foresight?"

10. SOCIAL-SITUATION ASSUMPTION
Use a recognizable everyday social scenario to make a vivid, playful assumption.
Example idea:
"You look like the type who says 'just one drink' and is the last one to leave."

11. RISK / TENSION PUNCHLINE
Frame sending the first message or getting a reply as a playful risk.
Example idea:
"I don't know what's more dangerous: messaging you or you actually replying."

IMPORTANT GENERATION RULES FOR THESE PATTERNS:
- Learn the mechanisms, not the exact wording. Do not mechanically copy the examples.
- Do not force these patterns into every opener. Existing profile-specific mechanisms remain valid and important.
- Prefer short, punchy wording. The payoff should arrive quickly.
- Humor should feel spontaneous, not like a polished pickup-line database.
- A playful assumption must be clearly framed as teasing, not asserted as a real personality fact.
- When profile details exist, anchor or adapt the pattern to a concrete detail whenever that makes the opener stronger.
- Do not overuse "you look like the type...". Vary sentence structures aggressively.
- Do not overuse questions. Statements and punchlines are often stronger.
- Bold/flirty is allowed, but avoid explicit sexual content, coercion, degradation or creepy pressure.
- These additions must expand variety; they must NOT erase the original clever/smooth, profile-specific behavior.

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
0. PREMIUM STRATEGY ENGINE
============================================================

Before writing, silently classify what this category needs.

CONTEXT AVAILABILITY:
NO_CONTEXT / LIGHT_CONTEXT / IMPLIED_CONTEXT

USER INTENT:
OPEN / FLIRT / TEASE / CREATE_CURIOSITY / COMPLIMENT / ESCALATE / RESTART / INVITE / OTHER

DESIRED REACTION:
Choose ONE:
SMILE
LAUGH
TEASE_BACK
CURIOSITY
PLAYFUL_DISAGREEMENT
ATTRACTION
EASY_REPLY
CLEAR_NEXT_STEP

ENERGY:
LOW / MEDIUM / HIGH

Then choose ONE primary creative mechanism and ONE optional supporting mechanism.

PRIMARY MECHANISMS:
- playful assumption
- situational tease
- confident observation
- mini challenge
- unexpected comparison
- clever misinterpretation
- playful accusation
- specific curiosity
- light push pull
- bold but natural compliment
- conversational pattern break
- callback style framing
- double meaning
- confident prediction
- playful either or
- direct intent
- micro scenario
- reverse question
- self aware joke
- tension through understatement

Do NOT always choose teasing.
Do NOT always choose curiosity.
Do NOT always use "you look like".
Do NOT always use danger/trouble framing.
Do NOT always use "I need to know one thing".
Do NOT always start with "be honest".
Do NOT always end with a question.

The goal is conceptual variety.

NO CONTEXT DOES NOT MEAN GENERIC:
If there is little or no context, do not invent personal facts.
Instead create value from:
- the category itself
- a playful universal situation
- a micro scenario
- an unexpected thought
- a small challenge
- a conversational pattern break
- a confident statement that naturally invites a reaction

The message must still feel fresh and intentional.

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
- surprise me -> freely choose the strongest fresh mechanism; do NOT stay in one pattern and do NOT mention the chosen strategy
- start a conversation -> create a pattern-breaking but easy-to-answer opener; no generic hello and no interview energy
- flirt -> create clear, calibrated romantic tension; do not hide the intent behind endless small talk
- compliment -> make the compliment memorable and conversational, not generic praise
- tease/play -> create playful tension that invites teasing back; never insult
- good morning/good night -> add warmth, personality or flirtation instead of sending a plain greeting

============================================================
2. CHOOSE A CREATIVE MECHANISM
============================================================

Before writing, silently choose the strongest mechanism for this category.

ROTATION RULE:
Prefer a mechanism that is meaningfully different from the mechanisms visible in RECENTLY GENERATED LINES.

Do not merely change nouns or adjectives.
Change the underlying conversational idea.

If the previous line was:
- a playful accusation, do not generate another accusation
- a "you look like" assumption, avoid that structure
- danger/trouble framing, avoid danger/trouble
- fake interview framing, avoid another interview
- curiosity withholding, use a concrete idea instead
- a compliment, consider teasing, a challenge, a scenario or an observation
- a question, strongly consider a statement

A new line should feel like it came from a different creative brain, not the same template with new words.

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

ANTI AI PATTERN FILTER:

Silently reject and rewrite if the line feels like:
- a social media quote
- a recycled pickup line website phrase
- a motivational sentence
- a dating coach trying to sound young
- an overly polished sentence no real person would text
- a forced metaphor
- a generic compliment with one unusual adjective
- a line that exists only to sound clever
- a setup that needs explanation

Prefer a message that sounds spontaneous and textable.

REACTION TEST:
The line should give the other person a natural reason to respond.
A strong line creates at least one of:
- laughter
- curiosity
- disagreement
- teasing back
- an easy personal answer
- attraction
- a natural next step

If the only likely reaction is "thanks", rewrite it.

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

Also reject semantic repeats:
Two lines count as repeats even if the words differ when they use the same social move.

Examples of conceptual repeats:
- "You look like someone who..." and "You seem like the type who..."
- "This is dangerous" and "You're trouble"
- "I have a question..." and "I need to ask you something..."
- two different compliments that both only say the person is attractive
- two curiosity lines that both withhold unnamed information

Rotate the SOCIAL MOVE, not only the vocabulary.

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
Choose a desired reaction before writing.
Avoid the concepts, structures, social moves and mechanisms used in the recent lines.
When there is no specific context, create an original hook without inventing facts.
Prioritize reaction, originality, confidence, naturalness and immediate sendability.
The final line must feel like something a socially confident real person would actually send.

Do not explain.
FINAL MESSAGE FORMAT: plain text only. No asterisks, quotation marks, hash signs, hyphens, en dashes, em dashes, bullets or markdown.
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
String normalize(String value) {
return value
.toLowerCase()
.replaceAll(RegExp(r'[^a-z0-9à-ÿ\s]', caseSensitive: false), ' ')
.replaceAll(RegExp(r'\s+'), ' ')
.trim();
}

final normalized = normalize(text);

for (final recent in recentLines) {
final recentNormalized = normalize(recent);

if (normalized == recentNormalized) {
return true;
}

if (normalized.length >= 18 &&
recentNormalized.length >= 18 &&
(normalized.contains(recentNormalized) ||
recentNormalized.contains(normalized))) {
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

if (status == 'incomplete') {
final details = data['incomplete_details'];
// ignore: avoid_print
print(
'OpenAI pick line INCOMPLETA. '
'Detalhes: $details | Corpo: ${response.body}',
);
throw Exception(
'OpenAI pick line incomplete: $details',
);
}

if (status == 'failed') {
final error = data['error'];
// ignore: avoid_print
print(
'OpenAI pick line FALHOU. '
'Erro: $error | Corpo: ${response.body}',
);
throw Exception(
'OpenAI pick line failed: $error',
);
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
'max_tokens': 500,
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

if (data is! Map<String, dynamic>) {
throw Exception('Anthropic pick line returned invalid JSON object');
}

final content = data['content'];
if (content is! List || content.isEmpty) {
throw Exception('Anthropic pick line returned no content');
}

for (final block in content) {
if (block is Map && block['type'] == 'text') {
final value = block['text']?.toString().trim() ?? '';
if (value.isNotEmpty) {
return value;
}
}
}

throw Exception('Anthropic pick line returned no text');
}

// ============================================================
// PARSE SINGLE PICK LINE
// ============================================================

static String _parseSinglePickLine(String body) {
try {
var raw = body.trim();

if (raw.startsWith('```')) {
raw = raw
.replaceFirst(RegExp(r'^```(?:json)?\s*', caseSensitive: false), '')
.replaceFirst(RegExp(r'\s*```$'), '')
.trim();
}

dynamic decoded = jsonDecode(raw);

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
} catch (e) {
// ignore: avoid_print
print('PICK LINE PARSE ERROR: $e | BODY: $body');
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
final mimeType = _detectImageMimeType(base64Image);
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
'image_url': 'data:$mimeType;base64,$base64Image',
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
final mimeType = _detectImageMimeType(base64Image);
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
'media_type': mimeType,
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

// Remove marcadores no início.
e = e.replaceAll(
RegExp(r'^\s*[-•*#>]\s*'),
'',
);

// Limpeza global para TODAS as funcionalidades.
// Nenhuma resposta final deve conter asteriscos, aspas, cardinal ou traços.
e = e.replaceAll(
RegExp(r'[\*#"“”„‟«»‹›]'),
'',
);

e = e.replaceAll(
RegExp(r'[-–—―]+'),
' ',
);

// Remove marcadores visuais semelhantes a listas.
e = e.replaceAll(
RegExp(r'[•▪◦‣]+'),
' ',
);

// Normaliza espaços criados pela limpeza sem destruir quebras de linha úteis.
e = e
.split('\n')
.map((line) => line.replaceAll(RegExp(r'\s+'), ' ').trim())
.where((line) => line.isNotEmpty)
.join('\n');

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