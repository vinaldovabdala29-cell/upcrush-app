import 'dart:convert';
import '../config.dart';
import 'package:http/http.dart' as http;

class AIService {
  static const String _apiKey = Config.openAiKey;

  static const Map<String, String> _idiomaNomes = {
    'en': 'English', 'pt': 'Brazilian Portuguese', 'de': 'German',
    'es': 'Spanish', 'fr': 'French', 'it': 'Italian',
    'tr': 'Turkish', 'pl': 'Polish', 'ru': 'Russian', 'ar': 'Arabic',
  };

  static const Map<String, String> _idiomaCultura = {
    'en': 'Western dating culture, witty and confident.',
    'pt': 'Brazilian dating culture, warm and playful.',
    'de': 'German dating culture, direct and confident.',
    'es': 'Spanish dating culture, passionate and charming.',
    'fr': 'French dating culture, elegant and witty.',
    'it': 'Italian dating culture, passionate and charming.',
    'tr': 'Turkish dating culture, confident and respectful.',
    'pl': 'Polish dating culture, direct and genuine.',
    'ru': 'Russian dating culture, direct and strong.',
    'ar': 'Arabic dating culture, respectful and charming.',
  };

  static Map<String, String> _estiloPrompts(String lang) => {
    'engraçado': 'Witty and playful Gen Z style. Clever humor that creates attraction. Unexpected and fun. Short and punchy. Never generic.',

    'picante': 'Confident and charming Gen Z style. Creates romantic tension with clever wordplay. Bold but tasteful. Makes her smile and think.',

    'misterioso': 'Intriguing and magnetic Gen Z style. Says just enough to spark curiosity. Unpredictable and interesting. Leaves her wanting more.',

    'direto': 'Confident and straightforward Gen Z style. Says exactly what he wants with calm confidence. Short powerful sentences. No games.',
  };

  // RESPOSTA DE TEXTO
  static Future<List<String>> gerarResposta(
    String conversa, String estilo, String lang) async {
    final estiloDesc = _estiloPrompts(lang)[estilo] ?? _estiloPrompts(lang)['picante']!;
    final idioma = _idiomaNomes[lang] ?? 'English';
    final cultura = _idiomaCultura[lang] ?? _idiomaCultura['en']!;
    final system = """
You are an expert at writing witty confident replies for dating app conversations.
$cultura
LANGUAGE RULE: Respond ONLY in $idioma. Never mix languages.
The last message in the conversation is from her. Write 6 confident replies for me to send.
STYLE: $estiloDesc
RULES:
- Reply specifically to her last message
- Gen Z energy: casual, confident, spontaneous
- Short and punchy, 1-2 lines max
- Max 1 emoji, many with none
- No generic phrases
- Sound like a real person
FORMAT: Exactly 6 responses, one per line, nothing else.
""";
    return _chamarAPI(system, "Conversation:\n\n$conversa\n\nGenerate 6 responses for me to send her.");
  }

  // RESPOSTA DE IMAGEM
  static Future<List<String>> gerarRespostaDeImagem(
    String base64Image, String estilo, String lang) async {
    final url = Uri.parse("https://api.openai.com/v1/chat/completions");
    final estiloDesc = _estiloPrompts(lang)[estilo] ?? _estiloPrompts(lang)['picante']!;
    final idioma = _idiomaNomes[lang] ?? 'English';
    final cultura = _idiomaCultura[lang] ?? _idiomaCultura['en']!;
    final system = """
You are an expert at generating witty confident replies for dating app conversations.
$cultura
LANGUAGE RULE: Respond ONLY in $idioma. Never mix languages.
HOW TO READ: RIGHT side bubbles = ME. LEFT side bubbles = HER.
WhatsApp: green right = ME, white left = HER. iMessage: blue right = ME, gray left = HER.
TASK: Find her LAST message (last bubble on the LEFT). Generate 6 confident replies.
STYLE: $estiloDesc
RULES: Reply specifically to what she said. Short, witty, confident. Max 1 emoji.
FORMAT: Exactly 6 responses in $idioma, one per line, nothing else.
""";
    final response = await http.post(url,
      headers: {"Content-Type": "application/json", "Authorization": "Bearer $_apiKey"},
      body: jsonEncode({
        "model": "gpt-4o",
        "messages": [
          {"role": "system", "content": system},
          {"role": "user", "content": [
            {"type": "image_url", "image_url": {"url": "data:image/jpeg;base64,$base64Image", "detail": "high"}},
            {"type": "text", "text": "This is a dating app conversation screenshot. RIGHT = ME, LEFT = HER. Find her last message (last LEFT bubble) and generate 6 replies in $idioma."},
          ]},
        ],
        "max_tokens": 400, "temperature": 0.85,
      }),
    );
    if (response.statusCode != 200) throw Exception("Error ${response.statusCode}: ${response.body}");
    return _parse(response.body);
  }

  // RESPOSTA DE OCR
  static Future<List<String>> gerarRespostaDeOCR(
    String conversaCompleta, String ultimaMensagemDela, String estilo, String lang) async {
    final estiloDesc = _estiloPrompts(lang)[estilo] ?? _estiloPrompts(lang)['picante']!;
    final idioma = _idiomaNomes[lang] ?? 'English';
    final cultura = _idiomaCultura[lang] ?? _idiomaCultura['en']!;
    final system = """
You are an expert at writing replies for dating app conversations.
$cultura
LANGUAGE RULE: Respond ONLY in $idioma. Never mix languages.
Her last message: "$ultimaMensagemDela"
STYLE: $estiloDesc
RULES: Short, witty, confident. Max 1 emoji. No generic phrases.
FORMAT: Exactly 6 responses, one per line, nothing else.
""";
    return _chamarAPI(system, "Conversation:\n$conversaCompleta\n\nHer last message: $ultimaMensagemDela\n\nGenerate 6 responses in $idioma.");
  }

  // OPENER DE TEXTO
  static Future<List<String>> gerarOpener(
    String descricao, String estilo, String lang) async {
    final estiloDesc = _estiloPrompts(lang)[estilo] ?? _estiloPrompts(lang)['picante']!;
    final idioma = _idiomaNomes[lang] ?? 'English';
    final cultura = _idiomaCultura[lang] ?? _idiomaCultura['en']!;
    final system = """
You write creative first messages for dating apps based on profile descriptions.
$cultura
LANGUAGE RULE: Write ONLY in $idioma. Never mix languages.
STYLE: $estiloDesc
RULES: Reference specific details from her profile. Bold and confident. Max 2 lines.
FORMAT: Exactly 6 openers, one per line, nothing else.
""";
    return _chamarAPI(system, "Her profile:\n$descricao\n\nCreate 6 personalized openers in $idioma.");
  }

  // OPENER DE IMAGEM
  static Future<List<String>> gerarOpenerDeImagem(
    String base64Image, String estilo, String lang) async {
    final url = Uri.parse("https://api.openai.com/v1/chat/completions");
    final estiloDesc = _estiloPrompts(lang)[estilo] ?? _estiloPrompts(lang)['picante']!;
    final idioma = _idiomaNomes[lang] ?? 'English';
    final cultura = _idiomaCultura[lang] ?? _idiomaCultura['en']!;
    final system = """
You are a creative writer generating opening messages for a dating app user.
$cultura
LANGUAGE RULE: Write ONLY in $idioma. Never mix languages.
You will receive a dating profile image. Your job is to read any visible TEXT (bio, interests, job, location, prompts, captions) and notice activities, hobbies, sports, travel, food, animals, or objects visible. Use these details to write 6 creative witty opening messages.
Important: Generate TEXT messages only. Do not describe or identify any person. Only use the profile information and context.
STYLE: $estiloDesc
QUALITY STANDARD:
- Com esse sorriso voce deve fazer a academia brilhar
- Seus treinos sao tao bons quanto seu sorriso
- Se voce me ensinar maquiagem eu te ensino a dancar
- Sem Ausbildung? Entao ja sei: voce se especializou no curso de me fazer sorrir

RULES: Each message references something specific from THIS profile. Gen Z casual energy. Bold and playful. Max 2 lines. Sound like a real person not an AI.
FORMAT: Exactly 6 messages in $idioma, one per line, nothing else.
""";
    final response = await http.post(url,
      headers: {"Content-Type": "application/json", "Authorization": "Bearer $_apiKey"},
      body: jsonEncode({
        "model": "gpt-4o",
        "messages": [
          {"role": "system", "content": system},
          {"role": "user", "content": [
            {"type": "image_url", "image_url": {"url": "data:image/jpeg;base64,$base64Image", "detail": "high"}},
            {"type": "text", "text": "Dating app profile image attached. Read the visible text and context (bio, interests, activities, objects). Generate 6 creative opening messages in $idioma based on the profile information. Focus on the content only."},
          ]},
        ],
        "max_tokens": 400, "temperature": 0.9,
      }),
    );
    if (response.statusCode != 200) throw Exception("Error ${response.statusCode}: ${response.body}");
    return _parse(response.body);
  }

  // PICK LINES
  static Future<List<String>> gerarPickLines(String lang) async {
    final idioma = _idiomaNomes[lang] ?? 'English';
    final cultura = _idiomaCultura[lang] ?? _idiomaCultura['en']!;
    final system = """
You generate bold flirty pick-up lines for adult dating apps (18+ audience). Gen Z energy.
$cultura
LANGUAGE RULE: Write ONLY in $idioma. Never mix languages.

STYLE: Confident Gen Z energy, clever wordplay, playful tension, 1-2 lines max.
Mix: funny and charming, bold and witty, mysterious and intriguing.
NEVER: generic, bland, try-hard, creepy, boring, explicit.
FORMAT: Exactly 6 pick-up lines in $idioma, one per line, nothing else.
""";
    return _chamarAPI(system, "Generate 6 bold flirty pick-up lines in $idioma for an adult audience. Mix funny, suggestive, mysterious and provocative.");
  }

  // API CENTRAL
  static Future<List<String>> _chamarAPI(String systemPrompt, String userMessage) async {
    final url = Uri.parse("https://api.openai.com/v1/chat/completions");
    final response = await http.post(url,
      headers: {"Content-Type": "application/json", "Authorization": "Bearer $_apiKey"},
      body: jsonEncode({
        "model": "gpt-4o",
        "messages": [
          {"role": "system", "content": systemPrompt},
          {"role": "user", "content": userMessage},
        ],
        "temperature": 0.85, "max_tokens": 400,
      }),
    );
    if (response.statusCode != 200) throw Exception("Error ${response.statusCode}: ${response.body}");
    return _parse(response.body);
  }

  // PARSER
  static List<String> _parse(String responseBody) {
    final data = jsonDecode(responseBody);
    final content = data["choices"][0]["message"]["content"].toString();
    final explicativos = [
      'here are', 'these are', 'below', 'responses:', 'options:',
      'aqui estao', 'aqui estão', 'hier sind', 'voila', 'respostas:',
      'opcoes:', 'here is', 'aqui esta', 'aqui está', 'sure here',
      'claro aqui', 'claro!', 'sure!', 'of course', 'certainly',
      'i cannot', 'i can not', 'i am sorry', "i'm sorry",
      'desculpe', 'lo siento', 'entschuldigung',
      'as requested', 'como pedido', 'como solicitado',
      'here you go', 'aqui vao', 'aqui vão',
      '6 response', '6 message', '6 mensagem', '6 resposta',
      'seis resposta', 'seis mensagem',
    ];
    final lista = content.split('\n')
        .map((e) => e.trim())
        .map((e) => e.replaceAll(RegExp(r'^\d+[.)]\s*'), ''))
        .map((e) => e.replaceAll(RegExp(r'^[-\u2022*]\s*'), ''))
        .map((e) => e.replaceAll(RegExp(r'^["\u201c\u201d]|["\u201c\u201d]$'), ''))
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .where((e) { final l = e.toLowerCase(); return !explicativos.any((w) => l.startsWith(w)); })
        .where((e) => e.length >= 3)
        .take(6)
        .toList();
    if (lista.isEmpty) throw Exception("Empty response from AI");
    return lista;
  }
}