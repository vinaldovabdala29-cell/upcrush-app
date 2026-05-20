import 'dart:convert';
import '../config.dart';
import 'package:http/http.dart' as http;

class AIService {
  static const String _apiKey = Config.openAiKey;

  // ─── IDIOMAS ──────────────────────────────────────────────────────────────
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
    'en': 'Western dating culture — witty, confident, interesting. Sound like a real man.',
    'pt': 'Brazilian dating culture — warm, playful, use Brazilian slang naturally. Sound like a real Brazilian man.',
    'de': 'German dating culture — direct, confident, no small talk. Sound like a real German man.',
    'es': 'Spanish/Latin dating culture — passionate, confident, charming. Sound like a real Spanish/Latin man.',
    'fr': 'French dating culture — elegant, witty, charming. Sound like a real French man.',
    'it': 'Italian dating culture — passionate, charming, confident. Sound like a real Italian man.',
    'tr': 'Turkish dating culture — confident, direct, respectful. Sound like a real Turkish man.',
    'pl': 'Polish dating culture — direct, confident, genuine. Sound like a real Polish man.',
    'ru': 'Russian dating culture — direct, confident, strong. Sound like a real Russian man.',
    'ar': 'Arabic dating culture — respectful, confident, charming. Sound like a real Arab man.',
  };

  // ─── TONS ─────────────────────────────────────────────────────────────────
  static Map<String, String> _estiloPrompts(String lang) => {
    'natural':
        lang == 'pt' ? 'Tom casual e humano, como um cara interessante no dia a dia.'
      : lang == 'de' ? 'Casual und menschlich, wie ein interessanter Mann im Alltag.'
      : lang == 'es' ? 'Tono casual y humano, como un hombre interesante en el día a día.'
      : lang == 'fr' ? 'Ton naturel et humain, comme un homme intéressant au quotidien.'
      : lang == 'it' ? 'Tono casual e umano, come un uomo interessante nella vita di tutti i giorni.'
      : lang == 'tr' ? 'Günlük, doğal ve samimi bir ton. İlginç bir adam gibi konuş.'
      : lang == 'pl' ? 'Casualowy i ludzki ton, jak interesujący mężczyzna na co dzień.'
      : lang == 'ru' ? 'Непринуждённый и человечный тон, как интересный мужчина в повседневной жизни.'
      : lang == 'ar' ? 'نبرة طبيعية وإنسانية، مثل رجل مثير للاهتمام في الحياة اليومية.'
      : 'Casual and human, like an interesting man in everyday life.',

    'charmoso':
        lang == 'pt' ? 'Charmoso e confiante. Levemente provocador, desperta curiosidade.'
      : lang == 'de' ? 'Charmant und selbstbewusst. Leicht provokativ, weckt Neugier.'
      : lang == 'es' ? 'Encantador y seguro. Ligeramente provocador, despierta curiosidad.'
      : lang == 'fr' ? 'Charmant et confiant. Légèrement provocateur, éveille la curiosité.'
      : lang == 'it' ? 'Affascinante e sicuro. Leggermente provocatorio, suscita curiosità.'
      : lang == 'tr' ? 'Karizmatik ve kendinden emin. Hafif provokatif, merak uyandırıyor.'
      : lang == 'pl' ? 'Czarujący i pewny siebie. Lekko prowokacyjny, budzi ciekawość.'
      : lang == 'ru' ? 'Обаятельный и уверенный. Немного провокационный, пробуждает любопытство.'
      : lang == 'ar' ? 'جذاب وواثق. مثير للاهتمام قليلاً، يوقظ الفضول.'
      : 'Charming and confident. Slightly provocative, sparks curiosity.',

    'engraçado':
        lang == 'pt' ? 'Bem-humorado e leve. Humor inteligente, nunca forçado.'
      : lang == 'de' ? 'Lustig und locker. Intelligenter Humor, nie erzwungen.'
      : lang == 'es' ? 'Gracioso y relajado. Humor inteligente, nunca forzado.'
      : lang == 'fr' ? 'Drôle et détendu. Humour intelligent, jamais forcé.'
      : lang == 'it' ? 'Divertente e rilassato. Umorismo intelligente, mai forzato.'
      : lang == 'tr' ? 'Eğlenceli ve rahat. Akıllı mizah, hiçbir zaman zorla değil.'
      : lang == 'pl' ? 'Śmieszny i swobodny. Inteligentny humor, nigdy wymuszony.'
      : lang == 'ru' ? 'Смешной и расслабленный. Умный юмор, никогда не натянутый.'
      : lang == 'ar' ? 'مضحك ومسترخٍ. فكاهة ذكية، لا تبدو مصطنعة أبداً.'
      : 'Funny and relaxed. Smart humor, never forced.',

    'direto':
        lang == 'pt' ? 'Direto e seguro de si. Frases curtas, sem enrolação.'
      : lang == 'de' ? 'Direkt und selbstsicher. Kurze Sätze, kein Drumherumreden.'
      : lang == 'es' ? 'Directo y seguro. Frases cortas, sin rodeos.'
      : lang == 'fr' ? 'Direct et confiant. Phrases courtes, sans détours.'
      : lang == 'it' ? 'Diretto e sicuro. Frasi brevi, senza giri di parole.'
      : lang == 'tr' ? 'Doğrudan ve kendinden emin. Kısa cümleler, dolambaçlı yol yok.'
      : lang == 'pl' ? 'Bezpośredni i pewny siebie. Krótkie zdania, bez owijania w bawełnę.'
      : lang == 'ru' ? 'Прямой и уверенный. Короткие фразы, без лишних слов.'
      : lang == 'ar' ? 'مباشر وواثق من نفسه. جمل قصيرة، بلا تلاعب بالألفاظ.'
      : 'Direct and confident. Short sentences, no beating around the bush.',

    'misterioso':
        lang == 'pt' ? 'Misterioso e intrigante. Diz menos do que poderia.'
      : lang == 'de' ? 'Geheimnisvoll und faszinierend. Sagt weniger als möglich.'
      : lang == 'es' ? 'Misterioso e intrigante. Dice menos de lo que podría.'
      : lang == 'fr' ? 'Mystérieux et fascinant. Dit moins que possible.'
      : lang == 'it' ? 'Misterioso e intrigante. Dice meno di quanto potrebbe.'
      : lang == 'tr' ? 'Gizemli ve büyüleyici. Mümkün olduğunca az söyler.'
      : lang == 'pl' ? 'Tajemniczy i intrygujący. Mówi mniej niż mógłby.'
      : lang == 'ru' ? 'Загадочный и интригующий. Говорит меньше, чем мог бы.'
      : lang == 'ar' ? 'غامض وجذاب. يقول أقل مما يستطيع.'
      : 'Mysterious and intriguing. Says less than possible.',
  };

  // ─── RESPOSTA DE TEXTO ────────────────────────────────────────────────────
  static Future<List<String>> gerarResposta(
    String conversa,
    String estilo,
    String lang,
  ) async {
    final estiloDesc = _estiloPrompts(lang)[estilo] ?? _estiloPrompts(lang)['natural']!;
    final idioma = _idiomaNomes[lang] ?? 'English';
    final cultura = _idiomaCultura[lang] ?? _idiomaCultura['en']!;

    final system = """
You are an expert in dating app and WhatsApp conversations.
$cultura

LANGUAGE RULE — CRITICAL:
You MUST respond ONLY in $idioma.
Every single response must be in $idioma.
Never mix languages.

CONTEXT:
The last message in the conversation is HER message. Respond to it.

STYLE: $estiloDesc

RULES:
- Respond specifically to her last message
- NEVER use: generic filler phrases
- NEVER be submissive or desperate
- Maximum 1 emoji per response
- Vary length: short (1 line) and medium (2 lines)
- Sound like a real confident man
- NO numbers, NO dashes, NO quotes, NO explanations

FORMAT: Exactly 6 responses, one per line, nothing else.
""";

    return _chamarAPI(
      system,
      "Conversation:\n\n$conversa\n\nGenerate 6 responses for me to send her.",
    );
  }

  // ─── RESPOSTA DE IMAGEM (GPT-4o Vision) ──────────────────────────────────
  static Future<List<String>> gerarRespostaDeImagem(
    String base64Image,
    String estilo,
    String lang,
  ) async {
    final url = Uri.parse("https://api.openai.com/v1/chat/completions");
    final estiloDesc = _estiloPrompts(lang)[estilo] ?? _estiloPrompts(lang)['natural']!;
    final idioma = _idiomaNomes[lang] ?? 'English';
    final cultura = _idiomaCultura[lang] ?? _idiomaCultura['en']!;

    final system = """
You are an expert at reading dating app and messaging screenshots to generate replies.
$cultura

LANGUAGE RULE — CRITICAL:
You MUST respond ONLY in $idioma. Never mix languages.

HOW TO IDENTIFY WHO IS WHO — FOLLOW THESE RULES EXACTLY:

POSITION RULE (most reliable):
- RIGHT side bubbles = ME (the user, the person I'm generating replies for)
- LEFT side bubbles = HER (the other person)
- This rule applies to ALL apps: WhatsApp, Telegram, iMessage, Tinder, Bumble, Hinge, Instagram DM, etc.

BUBBLE COLOR RULE (secondary confirmation):
- Colored bubble (green, blue, yellow, purple, pink) = RIGHT side = ME
- White or light gray bubble = LEFT side = HER
- Dark gray bubble on left = HER
- Never confuse colors — always cross-check with POSITION first

SPECIFIC APP RULES:
- WhatsApp: green bubble right = ME, white bubble left = HER
- iMessage: blue bubble right = ME, gray bubble left = HER  
- Instagram DM: blue bubble right = ME, gray bubble left = HER
- Telegram: blue/colored right = ME, white left = HER
- Tinder/Bumble/Hinge: colored right = ME, gray/white left = HER

FINDING HER LAST MESSAGE:
- Scroll to the BOTTOM of the conversation
- Find the LAST bubble on the LEFT side — that is HER most recent message
- That is EXACTLY what you must respond to
- Read the full conversation for context

STYLE: $estiloDesc

RULES:
- Respond ONLY to her last message (the last LEFT bubble)
- NEVER use generic filler phrases
- NEVER be submissive or desperate
- Maximum 1 emoji per response
- Vary length: short (1 line) and medium (2 lines)
- Sound like a real confident man
- Output ONLY the 6 responses — no intro, no explanation, no labels

FORMAT: Exactly 6 responses, one per line, nothing else. No intro text.
""";

    final response = await http.post(
      url,
      headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer $_apiKey",
      },
      body: jsonEncode({
        "model": "gpt-4o",
        "messages": [
          {"role": "system", "content": system},
          {
            "role": "user",
            "content": [
              {
                "type": "image_url",
                "image_url": {
                  "url": "data:image/jpeg;base64,$base64Image",
                  "detail": "high",
                },
              },
              {
                "type": "text",
                "text": "Look at this conversation screenshot. RIGHT side bubbles = ME. LEFT side bubbles = HER. Find HER LAST message (last bubble on the LEFT). Generate 6 responses in $idioma that I can send her right now.",
              },
            ],
          },
        ],
        "max_tokens": 400,
        "temperature": 0.85,
      }),
    );

    if (response.statusCode != 200) {
      throw Exception("Error ${response.statusCode}: ${response.body}");
    }

    return _parse(response.body);
  }

  // ─── RESPOSTA DE OCR ──────────────────────────────────────────────────────
  static Future<List<String>> gerarRespostaDeOCR(
    String conversaCompleta,
    String ultimaMensagemDela,
    String estilo,
    String lang,
  ) async {
    final estiloDesc = _estiloPrompts(lang)[estilo] ?? _estiloPrompts(lang)['natural']!;
    final idioma = _idiomaNomes[lang] ?? 'English';
    final cultura = _idiomaCultura[lang] ?? _idiomaCultura['en']!;

    final system = """
You are an expert in dating app and WhatsApp conversations.
$cultura

LANGUAGE RULE — CRITICAL:
You MUST respond ONLY in $idioma.

HER LAST MESSAGE (confirmed): "$ultimaMensagemDela"
RESPOND TO THIS SPECIFIC MESSAGE.

STYLE: $estiloDesc

RULES:
- NO numbers, NO dashes, NO quotes, NO explanations
- Maximum 1 emoji per response
- Sound like a real confident man

FORMAT: Exactly 6 responses, one per line, nothing else.
""";

    return _chamarAPI(
      system,
      "Full conversation:\n$conversaCompleta\n\nHer last message: $ultimaMensagemDela\n\nGenerate 6 responses in $idioma.",
    );
  }

  // ─── OPENER DE TEXTO ──────────────────────────────────────────────────────
  static Future<List<String>> gerarOpener(
    String descricao,
    String estilo,
    String lang,
  ) async {
    final estiloDesc = _estiloPrompts(lang)[estilo] ?? _estiloPrompts(lang)['charmoso']!;
    final idioma = _idiomaNomes[lang] ?? 'English';
    final cultura = _idiomaCultura[lang] ?? _idiomaCultura['en']!;

    final system = """
You create first messages for dating apps.
$cultura

LANGUAGE RULE — CRITICAL:
You MUST write ONLY in $idioma.

WHAT WORKS:
- Specific reference to something in her profile
- Question she has never heard before
- Smart or funny observation about her profile
- Shows you actually read her profile

WHAT NEVER WORKS:
- "Hey, how are you?" — NEVER
- Generic compliments
- Long messages for a first contact

RULES:
- Max 2 lines per opener
- 100% personalized to the described profile
- Sound like a real confident man
- Max 1 emoji, many with none
- NO numbers, NO dashes, NO explanations

FORMAT: Exactly 6 openers, one per line, nothing else.
""";

    return _chamarAPI(
      system,
      "Her profile:\n$descricao\n\nStyle: $estiloDesc\n\nCreate 6 personalized openers in $idioma.",
    );
  }

  // ─── OPENER DE IMAGEM ─────────────────────────────────────────────────────
  static Future<List<String>> gerarOpenerDeImagem(
    String base64Image,
    String estilo,
    String lang,
  ) async {
    final url = Uri.parse("https://api.openai.com/v1/chat/completions");
    final estiloDesc = _estiloPrompts(lang)[estilo] ?? _estiloPrompts(lang)['charmoso']!;
    final idioma = _idiomaNomes[lang] ?? 'English';
    final cultura = _idiomaCultura[lang] ?? _idiomaCultura['en']!;

    final system = """
You are a dating expert who writes COLD OPENERS — the very FIRST message to send on a dating app to someone you have NEVER spoken to before.
$cultura

LANGUAGE RULE — CRITICAL:
You MUST write ONLY in $idioma. Never mix languages.

CRITICAL: You are writing message number 1. There is NO previous conversation. She has NEVER heard from you.

HOW TO ANALYZE THE PROFILE:
STEP 1 — Scan everything visible: photos (what is she doing? where? what objects?), bio text, job, prompts, captions
STEP 2 — Pick the 3 most unique/interesting details specific to THIS profile
STEP 3 — Build each opener around one of those specific details

QUALITY CHECK: Could you send the same opener to 1000 different girls? If YES — too generic, rewrite.

GOOD OPENER EXAMPLES:
- "Rock climbing AND a dog named after a philosopher? Either the most interesting bio I have seen or you are testing me"
- "Your travel photos make me think you are either a photographer or really good at pretending"
- "The fact that your bio says you make great pasta is either impressive or a trap"

BAD OPENERS — NEVER:
- "Hey, how are you?" ❌
- "You seem interesting" ❌
- "I love your smile" ❌
- Anything generic that ignores her profile ❌

STYLE: $estiloDesc

RULES:
- Maximum 2 lines per opener
- 100% based on THIS specific profile — no generic openers
- Each of the 6 openers references a different detail from her profile
- Max 1 emoji per opener, most with none
- NO numbers, NO dashes, NO labels, NO explanations

FORMAT: Exactly 6 openers in $idioma, one per line, nothing else. No intro text.
""";

    final response = await http.post(
      url,
      headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer $_apiKey",
      },
      body: jsonEncode({
        "model": "gpt-4o",
        "messages": [
          {"role": "system", "content": system},
          {
            "role": "user",
            "content": [
              {
                "type": "image_url",
                "image_url": {
                  "url": "data:image/jpeg;base64,$base64Image",
                  "detail": "high",
                },
              },
              {
                "type": "text",
                "text": "Analyze this dating profile and generate 6 personalized openers in $idioma.",
              },
            ],
          },
        ],
        "max_tokens": 400,
        "temperature": 0.9,
      }),
    );

    if (response.statusCode != 200) {
      throw Exception("Error ${response.statusCode}: ${response.body}");
    }

    return _parse(response.body);
  }

  // ─── API CENTRAL ──────────────────────────────────────────────────────────
  static Future<List<String>> _chamarAPI(
    String systemPrompt,
    String userMessage,
  ) async {
    final url = Uri.parse("https://api.openai.com/v1/chat/completions");

    final response = await http.post(
      url,
      headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer $_apiKey",
      },
      body: jsonEncode({
        "model": "gpt-4o",
        "messages": [
          {"role": "system", "content": systemPrompt},
          {"role": "user", "content": userMessage},
        ],
        "temperature": 0.85,
        "max_tokens": 400,
      }),
    );

    if (response.statusCode != 200) {
      throw Exception("Error ${response.statusCode}: ${response.body}");
    }

    return _parse(response.body);
  }

  // ─── PARSER ───────────────────────────────────────────────────────────────
  static List<String> _parse(String responseBody) {
    final data = jsonDecode(responseBody);
    final content = data["choices"][0]["message"]["content"].toString();

    // Palavras que indicam texto explicativo — não são respostas
    final explicativos = [
      'here are', 'aqui estão', 'hier sind', 'aquí tienes',
      'here\'s', 'aqui tens', 'claro', 'sure', 'natürlich',
      'these are', 'estas son', 'voilà', 'below', 'abaixo',
      'responses:', 'respostas:', 'antworten:', 'respuestas:',
      'options:', 'opções:', 'optionen:', 'opciones:',
    ];

    final lista = content
        .split('\n')
        .map((e) => e.trim())
        // Remove numeração: 1. 1) 1-
        .map((e) => e.replaceAll(RegExp(r'^\d+[.)]\s*'), ''))
        // Remove traços e bullets
        .map((e) => e.replaceAll(RegExp(r'^[-\u2022*]\s*'), ''))
        // Remove aspas no início e fim
        .map((e) => e.replaceAll(RegExp(r'^["\u201c\u201d]|["\u201c\u201d]$'), ''))
        .map((e) => e.trim())
        // Filtra linhas vazias
        .where((e) => e.isNotEmpty)
        // Filtra linhas explicativas da IA
        .where((e) {
          final lower = e.toLowerCase();
          return !explicativos.any((word) => lower.startsWith(word));
        })
        // Filtra linhas muito curtas (menos de 3 chars — provavelmente lixo)
        .where((e) => e.length >= 3)
        .take(6)
        .toList();

    if (lista.isEmpty) throw Exception("Empty response from AI");
    return lista;
  }
}