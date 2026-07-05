import '../config.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

class AIService {
  static const String _openAiKey = Config.openAiKey;
  static const String _anthropicKey = Config.anthropicKey;

  static const Map<String, String> _idiomaNomes = {
    'en': 'English', 'pt': 'Brazilian Portuguese', 'de': 'German',
    'es': 'Spanish', 'fr': 'French', 'it': 'Italian',
    'tr': 'Turkish', 'pl': 'Polish', 'ru': 'Russian', 'ar': 'Arabic',
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

  static Map<String, String> _estiloPrompts(String lang) => {
    'natural':    lang == 'pt' ? 'Tom casual e humano, como um cara interessante no dia a dia.'
                : lang == 'de' ? 'Casual und menschlich, wie ein interessanter Mann im Alltag.'
                : lang == 'es' ? 'Tono casual y humano, como un hombre interesante en el día a día.'
                : 'Casual and human, like an interesting man in everyday life.',
    'charmoso':   lang == 'pt' ? 'Charmoso e confiante. Levemente provocador, desperta curiosidade.'
                : lang == 'de' ? 'Charmant und selbstbewusst. Leicht provokativ, weckt Neugier.'
                : lang == 'es' ? 'Encantador y seguro. Ligeramente provocador, despierta curiosidad.'
                : 'Charming and confident. Slightly provocative, sparks curiosity.',
    'engraçado':  lang == 'pt' ? 'Bem-humorado e leve. Humor inteligente, nunca forçado.'
                : lang == 'de' ? 'Lustig und locker. Intelligenter Humor, nie erzwungen.'
                : lang == 'es' ? 'Gracioso y relajado. Humor inteligente, nunca forzado.'
                : 'Funny and relaxed. Smart humor, never forced.',
    'picante':    lang == 'pt' ? 'Picante e confiante. Cria tensão psicológica, duplo sentido.'
                : lang == 'de' ? 'Pikant und selbstbewusst. Erzeugt Spannung, Doppeldeutigkeit.'
                : lang == 'es' ? 'Picante y seguro. Crea tensión psicológica, doble sentido.'
                : 'Spicy and confident. Creates psychological tension, double meaning.',
    'direto':     lang == 'pt' ? 'Direto e seguro de si. Frases curtas, sem enrolação.'
                : lang == 'de' ? 'Direkt und selbstsicher. Kurze Sätze, kein Drumherumreden.'
                : lang == 'es' ? 'Directo y seguro. Frases cortas, sin rodeos.'
                : 'Direct and confident. Short sentences, no beating around the bush.',
    'misterioso': lang == 'pt' ? 'Misterioso e intrigante. Diz menos do que poderia.'
                : lang == 'de' ? 'Geheimnisvoll und faszinierend. Sagt weniger als möglich.'
                : lang == 'es' ? 'Misterioso e intrigante. Dice menos de lo que podría.'
                : 'Mysterious and intriguing. Says less than possible.',
  };

  // ─── RESPOSTA DE IMAGEM ───────────────────────────────────────────────────
  static Future<List<String>> gerarRespostaDeImagem(
    String base64Image, String estilo, String lang) async {
    final estiloDesc = _estiloPrompts(lang)[estilo] ?? _estiloPrompts(lang)['natural']!;
    final idioma = _idiomaNomes[lang] ?? 'English';
    final cultura = _idiomaCultura[lang] ?? _idiomaCultura['en']!;

    final system = """
You are an elite dating coach generating replies to messaging conversations.
$cultura

LANGUAGE RULE — CRITICAL: You MUST respond ONLY in $idioma. Never mix languages.

WHO IS WHO — READ THIS CAREFULLY:

STEP 1 — IDENTIFY BUBBLES BY POSITION:
- Bubbles aligned to the RIGHT side of the screen = MY messages (the person asking for help)
- Bubbles aligned to the LEFT side of the screen = HER messages (the girl)
- This is the MOST RELIABLE rule — always use position first

STEP 2 — CONFIRM WITH COLOR:
- WhatsApp: green/dark bubbles on RIGHT = ME, white bubbles on LEFT = HER
- iMessage: blue bubbles on RIGHT = ME, gray bubbles on LEFT = HER
- Instagram/Tinder/Bumble: colored bubbles on RIGHT = ME, gray on LEFT = HER
- Telegram: colored on RIGHT = ME, white on LEFT = HER

STEP 3 — FIND HER LAST MESSAGE:
- Go to the VERY BOTTOM of the conversation
- The last bubble on the LEFT = her most recent message
- THIS is what you must respond to

STEP 4 — READ THE FULL CONTEXT:
- Read ALL bubbles from top to bottom
- Understand the conversation flow, topics, her vibe
- Use this to make your reply feel natural, not random

CONTEXT ANALYSIS:
1. What is the overall vibe? (flirty, cold, playful, dry?)
2. What topics have come up?
3. How interested does she seem?
4. What would be the MOST interesting reply given everything?

STYLE: $estiloDesc

WHAT MAKES A GREAT REPLY:
- It references or builds on something from the conversation
- It creates curiosity or makes her smile
- It moves the conversation forward naturally
- It sounds like a real confident man — not a dating app script

RULES:
- NEVER ignore context — read everything before writing
- NEVER be generic or predictable
- NEVER be submissive or desperate
- Maximum 1 emoji per response
- NO intro ("here are", "claro!", "sure!", "aqui estao", etc)
- NO numbers, NO asterisks, NO hashtags, NO quotes, NO dashes
- NO labels ("Option 1:", "Response 1:", etc)
- Write the reply text immediately — nothing before it

FORMAT: Exactly 2 responses in $idioma, one per line. ONLY the replies, nothing else.
""";

    try {
      final response = await http.post(
        Uri.parse("https://api.openai.com/v1/chat/completions"),
        headers: {"Content-Type": "application/json", "Authorization": "Bearer $_openAiKey"},
        body: jsonEncode({
          "model": "gpt-4o-mini",
          "messages": [
            {"role": "system", "content": system},
            {"role": "user", "content": [
              {"type": "image_url", "image_url": {"url": "data:image/jpeg;base64,$base64Image", "detail": "high"}},
              {"type": "text", "text": "STEP 1: Identify bubbles — RIGHT side = ME, LEFT side = HER. STEP 2: Find her LAST message (bottom-most LEFT bubble). STEP 3: Read all context. STEP 4: Generate 2 replies in $idioma to her last message that feel natural given the full conversation."},
            ]},
          ],
          "max_tokens": 150, "temperature": 0.85,
        }),
      ).timeout(const Duration(seconds: 15));
      if (response.statusCode == 200) return _parse(response.body, isOpenAI: true);
      throw Exception("OpenAI ${response.statusCode}");
    } catch (_) {
      // Fallback Anthropic
      final response = await http.post(
        Uri.parse("https://api.anthropic.com/v1/messages"),
        headers: {"Content-Type": "application/json", "x-api-key": _anthropicKey, "anthropic-version": "2023-06-01"},
        body: jsonEncode({
          "model": "claude-haiku-4-5-20251001",
          "max_tokens": 150,
          "system": system,
          "messages": [{"role": "user", "content": "Generate 2 replies in $idioma. Output only the 2 lines."}],
        }),
      ).timeout(const Duration(seconds: 15));
      if (response.statusCode == 200) return _parse(response.body, isOpenAI: false);
      throw Exception("Both APIs failed");
    }
  }

  // ─── OPENER DE IMAGEM ─────────────────────────────────────────────────────
  static Future<List<String>> gerarOpenerDeImagem(
    String base64Image, String estilo, String lang) async {
    final estiloDesc = _estiloPrompts(lang)[estilo] ?? _estiloPrompts(lang)['charmoso']!;
    final idioma = _idiomaNomes[lang] ?? 'English';
    final cultura = _idiomaCultura[lang] ?? _idiomaCultura['en']!;

    final system = """
You are an elite dating coach creating the perfect first message based on a dating profile photo.
$cultura

LANGUAGE RULE — CRITICAL: You MUST write ONLY in $idioma.

PROFILE ANALYSIS (do this before writing):
1. What does she look like — style, vibe, energy?
2. Where is she — location, setting, activity?
3. What objects or details are visible — pets, sports, food, travel?
4. What does this tell you about her personality?
5. What would genuinely surprise or intrigue HER specifically?

STYLE: $estiloDesc

WHAT MAKES A PERFECT OPENER:
- References something SPECIFIC from the photo that 99% of guys would miss
- Feels like it could only be sent to HER — not copy-pasted to anyone
- Creates instant curiosity or makes her laugh out loud
- Opens a conversation naturally — not a dead end
- Sounds like a real, confident, interesting man

NEVER:
- Generic compliments ("you're beautiful", "love your smile")
- Questions she's heard 100 times
- Anything that could be sent to any girl

RULES:
- Max 2 lines per opener
- Max 1 emoji, many with none
- NO numbers, NO dashes, NO explanations

FORMAT: Exactly 2 openers in $idioma, one per line, nothing else.
""";

    try {
      final response = await http.post(
        Uri.parse("https://api.openai.com/v1/chat/completions"),
        headers: {"Content-Type": "application/json", "Authorization": "Bearer $_openAiKey"},
        body: jsonEncode({
          "model": "gpt-4o-mini",
          "messages": [
            {"role": "system", "content": system},
            {"role": "user", "content": [
              {"type": "image_url", "image_url": {"url": "data:image/jpeg;base64,$base64Image", "detail": "high"}},
              {"type": "text", "text": "Analyze every detail of this profile photo carefully. Generate 2 openers in $idioma that feel like they could ONLY be sent to this specific person."},
            ]},
          ],
          "max_tokens": 150, "temperature": 0.9,
        }),
      ).timeout(const Duration(seconds: 15));
      if (response.statusCode == 200) return _parse(response.body, isOpenAI: true);
      throw Exception("OpenAI ${response.statusCode}");
    } catch (_) {
      final response = await http.post(
        Uri.parse("https://api.anthropic.com/v1/messages"),
        headers: {"Content-Type": "application/json", "x-api-key": _anthropicKey, "anthropic-version": "2023-06-01"},
        body: jsonEncode({
          "model": "claude-haiku-4-5-20251001",
          "max_tokens": 150,
          "system": system,
          "messages": [{"role": "user", "content": "Generate 2 dating app openers in $idioma. Output only the 2 lines."}],
        }),
      ).timeout(const Duration(seconds: 15));
      if (response.statusCode == 200) return _parse(response.body, isOpenAI: false);
      throw Exception("Both APIs failed");
    }
  }

  // ─── PICK LINES ───────────────────────────────────────────────────────────
  static Future<List<String>> gerarPickLines(String lang) async {
    final idioma = _idiomaNomes[lang] ?? 'English';
    final cultura = _idiomaCultura[lang] ?? _idiomaCultura['en']!;
    final system = 'You are the undisputed Gen Z seduction master.\n'
        '$cultura\n'
        'LANGUAGE: Write ONLY in $idioma.\n'
        'ENERGY: Bold. Psychological tension. Double meaning. Makes her laugh AND feel something.\n'
        'NEVER: generic compliments, boring, try-hard, explicit.\n'
        'FORMAT: Exactly 2 lines in $idioma, one per line, nothing else.';
    return _chamarDual(system,
      'Generate 2 irresistible Gen Z pick-up lines in $idioma. Output only the 2 lines.');
  }

  // ─── RESPOSTA DE TEXTO ────────────────────────────────────────────────────
  static Future<List<String>> gerarResposta(
    String conversa, String estilo, String lang) async {
    final estiloDesc = _estiloPrompts(lang)[estilo] ?? _estiloPrompts(lang)['natural']!;
    final idioma = _idiomaNomes[lang] ?? 'English';
    final cultura = _idiomaCultura[lang] ?? _idiomaCultura['en']!;
    final system = """
You are an elite dating coach generating replies. $cultura
LANGUAGE: ONLY in $idioma. STYLE: $estiloDesc

BEFORE WRITING:
- Read the FULL conversation to understand the vibe and dynamic
- Note what topics came up and her interest level
- Her LAST message is what you respond to

GREAT REPLY = references context + creates curiosity + moves conversation forward
RULES: Max 1 emoji. Confident. NO explanations. NEVER generic.
FORMAT: Exactly 2 responses, one per line, nothing else.
""";
    return _chamarDual(system, "Full conversation:\n$conversa\n\nRead all context. Generate 2 natural replies to her last message in $idioma.");
  }

  // ─── OPENER DE TEXTO ──────────────────────────────────────────────────────
  static Future<List<String>> gerarOpener(
    String descricao, String estilo, String lang) async {
    final estiloDesc = _estiloPrompts(lang)[estilo] ?? _estiloPrompts(lang)['charmoso']!;
    final idioma = _idiomaNomes[lang] ?? 'English';
    final cultura = _idiomaCultura[lang] ?? _idiomaCultura['en']!;
    final system = """
You create first messages for dating apps. $cultura
LANGUAGE: ONLY in $idioma. STYLE: $estiloDesc
RULES: Specific to her profile. Max 2 lines. Confident. NO generic compliments.
FORMAT: Exactly 2 openers, one per line, nothing else.
""";
    return _chamarDual(system, "Her profile:\n$descricao\n\nGenerate 2 openers in $idioma.");
  }

  // ─── DUAL API ─────────────────────────────────────────────────────────────
  static Future<List<String>> _chamarDual(String system, String user) async {
    try {
      final response = await http.post(
        Uri.parse("https://api.openai.com/v1/chat/completions"),
        headers: {"Content-Type": "application/json", "Authorization": "Bearer $_openAiKey"},
        body: jsonEncode({
          "model": "gpt-4o-mini",
          "messages": [{"role": "system", "content": system}, {"role": "user", "content": user}],
          "temperature": 0.9, "max_tokens": 150,
        }),
      ).timeout(const Duration(seconds: 12));
      if (response.statusCode == 200) return _parse(response.body, isOpenAI: true);
      throw Exception("OpenAI ${response.statusCode}");
    } catch (_) {
      final response = await http.post(
        Uri.parse("https://api.anthropic.com/v1/messages"),
        headers: {"Content-Type": "application/json", "x-api-key": _anthropicKey, "anthropic-version": "2023-06-01"},
        body: jsonEncode({
          "model": "claude-haiku-4-5-20251001",
          "max_tokens": 150,
          "system": system,
          "messages": [{"role": "user", "content": user}],
        }),
      ).timeout(const Duration(seconds: 12));
      if (response.statusCode == 200) return _parse(response.body, isOpenAI: false);
      throw Exception("Both APIs failed");
    }
  }

  // ─── PARSER ───────────────────────────────────────────────────────────────
  static List<String> _parse(String body, {required bool isOpenAI}) {
    final data = jsonDecode(body);
    final text = isOpenAI
        ? data["choices"][0]["message"]["content"].toString()
        : data["content"][0]["text"].toString();

    const prefixosLixo = [
      'here are', 'aqui estao', 'hier sind', 'aqui tienes', 'these are',
      'voila', 'below', 'responses:', 'respostas:', 'options:', 'opcoes:',
      'i cannot', "i can't", "i'm sorry", 'i am sorry', 'desculpe',
      'lo siento', 'entschuldigung', 'sure here', 'of course', 'certainly',
      'claro', 'sure!', 'naturlich', 'aqui vao', 'here you go',
      'duas respostas', 'two responses', 'zwei antworten', 'dos respuestas',
      'option 1', 'option 2', 'opcao 1', 'opcao 2', 'resposta 1', 'resposta 2',
      'response 1', 'response 2', 'antwort 1', 'antwort 2',
    ];

    String clean(String e) {
      e = e.trim();
      e = e.replaceAll(RegExp(r'^\d+[.):\-]\s*'), '');
      e = e.replaceAll(RegExp(r'^[-•*#>]\s*'), '');
      e = e.replaceAll(RegExp(r'\*+'), '');
      e = e.replaceAll(RegExp(r'^#+\s*'), '');
      e = e.replaceAll(RegExp(r'_+'), '');
      // Remove leading/trailing quotes
      while (e.isNotEmpty && (e[0] == '"' || e[0] == '“' || e[0] == '”')) {
        e = e.substring(1);
      }
      while (e.isNotEmpty && (e[e.length-1] == '"' || e[e.length-1] == '“' || e[e.length-1] == '”')) {
        e = e.substring(0, e.length-1);
      }
      while (e.isNotEmpty && (e[0] == "'" || e[0] == '‘' || e[0] == '’')) {
        e = e.substring(1);
      }
      while (e.isNotEmpty && (e[e.length-1] == "'" || e[e.length-1] == '‘' || e[e.length-1] == '’')) {
        e = e.substring(0, e.length-1);
      }
      return e.trim();
    }

    final lista = text.split('\n')
        .map(clean)
        .where((e) => e.isNotEmpty)
        .where((e) {
          final l = e.toLowerCase()
            .replaceAll('ã', 'a').replaceAll('ç', 'c')
            .replaceAll('é', 'e').replaceAll('ü', 'u');
          return !prefixosLixo.any((w) => l.startsWith(w.toLowerCase()));
        })
        .where((e) => e.length >= 4)
        .where((e) => RegExp(r'[a-zA-ZÀ-ɏ]').hasMatch(e))
        .take(2)
        .toList();

    if (lista.isEmpty) throw Exception("Empty response from AI");
    return lista;
  }
}