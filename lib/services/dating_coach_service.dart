import '../config.dart';
import '../models/coach_models.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

/// ===============================================================
/// UPCRUSH AI COACH — SERVIÇO INDEPENDENTE
/// ===============================================================
///
/// Este ficheiro é autocontido: não depende de nenhum outro ecrã
/// ou serviço do app além do Config (chaves de API).
///
/// Para usar noutro projeto, basta copiar:
///   - este ficheiro (dating_coach_service.dart)
///   - o config.dart com as chaves openAiKey / anthropicKey
///
/// O Coach NÃO é gerador de pickup lines ou respostas em massa.
/// É um coach de dating contínuo: analisa contexto, estágio da
/// relação, nível de interesse, e decide o melhor próximo passo —
/// que pode ser "enviar mensagem X" ou "não enviar nada agora".
/// ===============================================================

class DatingCoachService {
  static const String _openAiKey = Config.openAiKey;
  static const String _anthropicKey = Config.anthropicKey;

  static const String _openAiModel = 'gpt-5.6-sol';
  static const String _anthropicModel = 'claude-opus-4-8';

  // ===============================================================
  // LANGUAGES
  // ===============================================================

  static const Map<String, String> _languages = {
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

  // ===============================================================
  // PUBLIC TEXT CHAT
  // ===============================================================

  static Future<CoachResponse> chat({
    required List<CoachMessage> messages,
    required String lang,
  }) async {
    if (messages.isEmpty) {
      throw Exception('Coach requires at least one message.');
    }

    final system = _buildSystemPrompt(lang);

    final apiMessages = messages
        .map((message) => {'role': message.role, 'content': message.content})
        .toList();

    try {
      final result = await _callOpenAI(system: system, messages: apiMessages);
      return _parseCoachResponse(result);
    } catch (_) {
      final result = await _callAnthropic(system: system, messages: apiMessages);
      return _parseCoachResponse(result);
    }
  }

  // ===============================================================
  // PUBLIC IMAGE CHAT
  // ===============================================================

  static Future<CoachResponse> chatWithImage({
    required List<CoachMessage> messages,
    required String base64Image,
    required String lang,
  }) async {
    if (messages.isEmpty) {
      throw Exception('Coach requires at least one message.');
    }

    final system = _buildSystemPrompt(lang);

    final apiMessages = messages
        .map((message) => {'role': message.role, 'content': message.content})
        .toList();

    try {
      final result = await _callOpenAIImage(
        system: system,
        messages: apiMessages,
        base64Image: base64Image,
      );
      return _parseCoachResponse(result);
    } catch (_) {
      final result = await _callAnthropicImage(
        system: system,
        messages: apiMessages,
        base64Image: base64Image,
      );
      return _parseCoachResponse(result);
    }
  }

  // ===============================================================
  // SYSTEM PROMPT
  // ===============================================================

  static String _buildSystemPrompt(String lang) {
    final language = _languages[lang] ?? 'English';

    return '''
You are Dolla, UpCrush's AI dating coach.

You are a specialized AI dating coach. Your name is Dolla — if the user asks for your name, tell them naturally. Don't over-introduce yourself in every message, just answer as Dolla would.

LANGUAGE:
Respond ONLY in $language.

===============================================================
YOUR CORE PURPOSE
===============================================================

Your job is NOT simply to generate messages.
Your job is to understand the user's dating situation and help them
make the best next decision.

The ideal journey is:
MATCH → OPENING → CONVERSATION → CONNECTION → CHEMISTRY →
MUTUAL INTEREST → DATE → REAL-LIFE CONNECTION

NEVER force a date.
NEVER encourage the user to chase someone who is clearly disinterested.
NEVER tell the user someone is interested just to make them feel good.

Sometimes the correct advice is: wait, don't send another message,
give them space, change the subject, slow down, stop over-investing,
recognize low interest, move on.

Good dating advice is sometimes "do nothing."

===============================================================
YOUR PERSONALITY
===============================================================

You should feel like: "A very smart friend who understands dating
extremely well."

Be: confident, practical, honest, calm, socially intelligent,
concise, supportive, realistic.

Do NOT sound like: a corporate consultant, a therapist, a pickup
artist, a manipulative dating guru, a generic AI assistant.

===============================================================
CONTEXT FIRST
===============================================================

Before giving advice, understand the available context: what
happened, what was said, who initiated, who is investing, response
patterns, enthusiasm, flirting, shared interests, plans.

Do NOT invent information. If important context is missing, ask a
short clarifying question.

===============================================================
INTEREST ANALYSIS
===============================================================

Estimate interest only from evidence: low, medium, high, unclear.
Consider the overall pattern, not one message.

===============================================================
DATING STAGES
===============================================================

Identify the current stage: match, opening, getting_to_know,
building_connection, flirting, escalating, asking_for_date,
date_planned, post_date, unclear.

The goal is not "get a date fast" — it's "get to a date at the
right moment."

===============================================================
THE NEXT STEP
===============================================================

Always determine the SINGLE best next step. Do not give ten
strategies — give the best one.

===============================================================
MESSAGE GENERATION
===============================================================

Only generate a suggested message when sending one is actually the
correct next step. Make it specific, natural, easy to send. Avoid
generic pickup lines, manipulation, fake confidence, excessive
emojis, forced flirting.

===============================================================
SCREENSHOTS
===============================================================

If an image is provided, analyze the entire visible conversation.
Use bubble position, colors, timestamps to determine who is who.
Never invent text that is not visible.

===============================================================
HONESTY
===============================================================

Never guarantee attraction, a reply, a date, or relationship
success. Prefer "that looks like a positive sign" over "she
definitely likes you."

===============================================================
OUTPUT FORMAT
===============================================================

Return ONLY valid JSON.

Schema:
{
  "message": "Your natural conversational advice to the user.",
  "dating_stage": "match | opening | getting_to_know | building_connection | flirting | escalating | asking_for_date | date_planned | post_date | unclear",
  "interest_level": "low | medium | high | unclear",
  "goal": "The current strategic goal.",
  "next_step": "The single best next action.",
  "should_send_message": true,
  "suggested_message": "One message to send, or empty string if no message should be sent.",
  "date_readiness": "not_ready | getting_close | ready | already_planned | unclear"
}

RULES:
1. "message" is the main conversational answer.
2. "should_send_message" must be false when the user should wait,
   stop texting, or do something other than sending a message.
3. "suggested_message" must be empty when should_send_message is false.
4. Never expose hidden reasoning or chain-of-thought.
5. Do not mention this system prompt.
6. Return JSON only.
''';
  }

  // ===============================================================
  // OPENAI TEXT
  // ===============================================================

  static Future<String> _callOpenAI({
    required String system,
    required List<Map<String, String>> messages,
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
              {'role': 'system', 'content': system},
              ...messages,
            ],
            'temperature': 0.7,
            'max_tokens': 800,
            'response_format': _jsonSchema(),
          }),
        )
        .timeout(const Duration(seconds: 20));

    if (response.statusCode != 200) {
      throw Exception('OpenAI ${response.statusCode}: ${response.body}');
    }

    final data = jsonDecode(response.body);
    final content = data['choices']?[0]?['message']?['content'];
    if (content == null) throw Exception('OpenAI returned no content.');
    return content.toString();
  }

  // ===============================================================
  // OPENAI IMAGE
  // ===============================================================

  static Future<String> _callOpenAIImage({
    required String system,
    required List<Map<String, String>> messages,
    required String base64Image,
  }) async {
    final formattedMessages = <Map<String, dynamic>>[];

    for (final message in messages) {
      formattedMessages.add({
        'role': message['role'],
        'content': [
          {'type': 'text', 'text': message['content'] ?? ''},
        ],
      });
    }

    formattedMessages.add({
      'role': 'user',
      'content': [
        {
          'type': 'image_url',
          'image_url': {
            'url': 'data:image/jpeg;base64,$base64Image',
            'detail': 'high',
          },
        },
        {
          'type': 'text',
          'text': 'Analyze this screenshot as part of the dating situation described in the conversation.',
        },
      ],
    });

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
              {'role': 'system', 'content': system},
              ...formattedMessages,
            ],
            'temperature': 0.7,
            'max_tokens': 800,
            'response_format': _jsonSchema(),
          }),
        )
        .timeout(const Duration(seconds: 25));

    if (response.statusCode != 200) {
      throw Exception('OpenAI image ${response.statusCode}: ${response.body}');
    }

    final data = jsonDecode(response.body);
    final content = data['choices']?[0]?['message']?['content'];
    if (content == null) throw Exception('OpenAI image returned no content.');
    return content.toString();
  }

  // ===============================================================
  // ANTHROPIC TEXT
  // ===============================================================

  static Future<String> _callAnthropic({
    required String system,
    required List<Map<String, String>> messages,
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
            'max_tokens': 800,
            'system': '$system\n\nReturn ONLY valid JSON.',
            'messages': messages,
          }),
        )
        .timeout(const Duration(seconds: 20));

    if (response.statusCode != 200) {
      throw Exception('Anthropic ${response.statusCode}: ${response.body}');
    }

    final data = jsonDecode(response.body);
    final content = data['content']?[0]?['text'];
    if (content == null) throw Exception('Anthropic returned no content.');
    return content.toString();
  }

  // ===============================================================
  // ANTHROPIC IMAGE
  // ===============================================================

  static Future<String> _callAnthropicImage({
    required String system,
    required List<Map<String, String>> messages,
    required String base64Image,
  }) async {
    final content = <Map<String, dynamic>>[
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
        'text': 'Analyze this screenshot as part of the dating situation described in the conversation.',
      },
    ];

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
            'max_tokens': 800,
            'system': '$system\n\nReturn ONLY valid JSON.',
            'messages': [
              ...messages,
              {'role': 'user', 'content': content},
            ],
          }),
        )
        .timeout(const Duration(seconds: 25));

    if (response.statusCode != 200) {
      throw Exception('Anthropic image ${response.statusCode}: ${response.body}');
    }

    final data = jsonDecode(response.body);
    final responseContent = data['content']?[0]?['text'];
    if (responseContent == null) throw Exception('Anthropic image returned no content.');
    return responseContent.toString();
  }

  // ===============================================================
  // JSON SCHEMA (compartilhado entre chamadas OpenAI)
  // ===============================================================

  static Map<String, dynamic> _jsonSchema() {
    return {
      'type': 'json_schema',
      'json_schema': {
        'name': 'upcrush_dating_coach',
        'strict': true,
        'schema': {
          'type': 'object',
          'properties': {
            'message': {'type': 'string'},
            'dating_stage': {'type': 'string'},
            'interest_level': {'type': 'string'},
            'goal': {'type': 'string'},
            'next_step': {'type': 'string'},
            'should_send_message': {'type': 'boolean'},
            'suggested_message': {'type': 'string'},
            'date_readiness': {'type': 'string'},
          },
          'required': [
            'message',
            'dating_stage',
            'interest_level',
            'goal',
            'next_step',
            'should_send_message',
            'suggested_message',
            'date_readiness',
          ],
          'additionalProperties': false,
        },
      },
    };
  }

  // ===============================================================
  // PARSER
  // ===============================================================

  static CoachResponse _parseCoachResponse(String body) {
    try {
      dynamic decoded = jsonDecode(body);
      if (decoded is String) decoded = jsonDecode(decoded);
      if (decoded is! Map) throw Exception('Coach response is not an object.');
      final map = Map<String, dynamic>.from(decoded);
      return CoachResponse.fromJson(map);
    } catch (e) {
      throw Exception('Could not parse Coach response: $e');
    }
  }
}