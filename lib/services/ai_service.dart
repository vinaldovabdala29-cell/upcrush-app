import '../config.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

class AIService {
  static const String _openAiKey = Config.openAiKey;
  static const String _anthropicKey = Config.anthropicKey;

  // ============================================================
  // CONFIG
  // ============================================================

  static const String _openAiModel = 'gpt-4o-mini';
  static const String _anthropicModel = 'claude-haiku-4-5-20251001';

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
  // STYLE
  // ============================================================

  static Map<String, String> _estiloPrompts(String lang) {
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

    return {
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
  }

  // ============================================================
  // BASE SYSTEM PROMPT
  // ============================================================

  static String _baseSystem({
    required String lang,
    required String estilo,
    required bool opener,
  }) {
    final idioma = _idiomaNomes[lang] ?? 'English';

    final cultura =
        _idiomaCultura[lang] ?? _idiomaCultura['en']!;

    final estilos = _estiloPrompts(lang);

    final estiloDesc =
        estilos[estilo] ?? estilos['natural']!;

    return '''
You are UpCrush AI, an expert dating conversation assistant.

Your job is NOT to generate generic pickup lines.

Your job is to help the user communicate naturally and attractively
in real dating conversations.

The message should feel:

- natural
- attractive
- context-aware
- specific
- human
- easy to send
- appropriate for the current stage of the conversation

LANGUAGE:
Respond ONLY in $idioma.

LANGUAGE AND CULTURAL STYLE:
$cultura

USER STYLE:
$estiloDesc

IMPORTANT ROLE IDENTIFICATION:

When analyzing a conversation, you MUST determine who is the user
and who is the other person.

The user is the person who will SEND the generated response.

The other person is the person whose message the user needs to answer.

Never answer as if the generated message were being sent by the other
person.

When analyzing screenshots, determine the participants using ALL
available visual evidence:

- message bubble position
- bubble colors
- alignment
- names
- avatars
- profile headers
- timestamps
- message sequence
- conversation structure

Do NOT rely only on left/right position.

In many messaging applications:

- messages on the RIGHT belong to the user
- messages on the LEFT belong to the other person

But this is NOT universal.

If the screenshot clearly indicates a different structure, follow the
actual screenshot.

Most importantly:

The generated response must ALWAYS be written from the user's
perspective TO the other person.

Before generating a response, mentally reconstruct:

USER:
The person using UpCrush.

OTHER PERSON:
The person the user is talking to.

Then identify:

1. The other person's latest message.
2. The user's previous message.
3. The direction of the conversation.
4. Who initiated the current topic.
5. What the other person is reacting to.
6. What details were mentioned earlier.
7. The emotional tone.
8. The level of interest/investment.
9. What would naturally happen next.

Never reverse the participants.

CORE PRINCIPLE:

A good response should feel like it could ONLY have been written
after seeing this exact conversation.

If the same response could be sent to 20 unrelated people,
discard it and create something more specific.

NEVER:

- use generic dating-app clichés
- use generic compliments
- force flirting
- sound like a dating coach
- sound like a pickup artist
- overuse emojis
- invent facts
- invent hobbies
- invent personality traits
- assume attraction without evidence
- pretend the other person said something they did not say
- answer the wrong person
- repeat information unnecessarily
- use unnatural slang
- use excessive exclamation marks
- mention that you are AI
- explain hidden reasoning

NATURALNESS:

Write like a real person texting another real person.

Avoid generic lines such as:

"you seem like trouble"
"you have an amazing smile"
"there's something about you"
"what's your biggest red flag?"
"so what do you do for fun?"
"haha that's cute"
"I had to swipe right"

unless the actual context makes them appropriate.

CONVERSATIONAL QUALITY:

Prefer:

- callbacks to specific details
- playful observations
- relevant teasing
- interesting follow-up questions
- unexpected but natural reactions
- building on something the other person actually said
- small personal references
- humor based on the conversation
- messages that naturally invite a response

Do NOT ask a question just because you think every message
needs a question.

A good response can also be a statement, reaction, tease or callback.

The message should contribute something to the conversation.

INTEREST:

Do not assume the other person is interested.

Look at:

- response length
- response speed when visible
- whether they ask questions
- whether they introduce new topics
- whether they react to details
- whether they flirt
- whether they continue conversations
- whether they initiate
- whether their responses are dry
- whether they appear engaged

If the other person is clearly uninterested, do not manufacture
false confidence.

If the conversation is going well, do not unnecessarily overthink it.

FIRST CONVERSATION:

When the user needs to start a conversation, do NOT simply generate
a compliment.

Look for a concrete conversation hook.

Good hooks can come from:

- profile details
- hobbies
- travel
- food
- pets
- unusual photos
- activities
- locations
- prompts
- humor
- something visually distinctive

The first message should create an easy reason to respond.

If there is no useful context, create something short, natural and
specific to what is actually available.

PICKUP LINES:

When specifically asked for pickup lines, they may be more playful.

However, avoid:

- old-fashioned clichés
- sexual pressure
- manipulative language
- insults
- creepy assumptions
- exaggerated compliments

They should feel modern and sendable.

REPLY TO MESSAGE:

When the user asks "what should I reply?", the primary goal is NOT
to create the most impressive sentence.

The primary goal is to create the best NEXT message for the
conversation.

Sometimes that means:

- answering directly
- teasing
- asking a follow-up
- changing the topic
- flirting
- showing curiosity
- escalating slightly
- suggesting a date
- or keeping it simple

Choose what fits the actual context.

SCREENSHOT ANALYSIS:

If an image is provided:

1. Read the complete visible conversation.
2. Identify all visible participants.
3. Determine which bubbles belong to the user.
4. Determine which bubbles belong to the other person.
5. Read from oldest visible message to newest.
6. Identify the latest message from the other person.
7. Identify what message the user sent immediately before it.
8. Understand what the latest message means in context.
9. Use earlier conversation details when relevant.
10. Generate a response FROM THE USER TO THE OTHER PERSON.

Never reverse the conversation.

If text is partially hidden, cropped or unreadable,
do not invent it.

If you cannot confidently identify a piece of text,
ignore it rather than hallucinating it.

STYLE:
$estiloDesc
''';
  }

  // ============================================================
  // TEXT RESPONSE
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
The following is the complete conversation available to you.

CONVERSATION:
$conversa

IMPORTANT:

The person using UpCrush is the USER.

The person the user is talking to is the OTHER PERSON.

Your generated responses must be messages that the USER can send
to the OTHER PERSON.

Analyze the direction of the conversation before generating anything.

Internally determine:

1. Who is the user?
2. Who is the other person?
3. What did the user last say?
4. What did the other person last say?
5. What is the other person's latest intention or emotion?
6. What specific details can be reused?
7. Is the conversation interested, playful, neutral, dry, teasing,
   cold or confused?
8. What is the apparent investment level?
9. What is the strongest natural conversational opportunity?
10. What should the user's next message accomplish?

Do NOT output this analysis.

PERSONALIZATION TEST:

Every response must be grounded in this conversation.

If a response could work equally well in another unrelated
conversation, reject it.

Generate exactly TWO genuinely different replies.

REPLY A:
The safest and most natural response for this exact situation.

REPLY B:
A meaningfully different approach using the same context.
It can be more playful, flirty, direct or teasing when appropriate.

The two responses must NOT simply be synonyms or small rewrites.

Both responses must sound like something a real person would send.

Do not add explanations.

Return valid JSON only:

{
  "responses": [
    "reply A",
    "reply B"
  ]
}

The responses must be written in $idioma.
''';

    return _chamarComFallback(
      system: system,
      user: user,
    );
  }

  // ============================================================
  // SCREENSHOT RESPONSE
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
Analyze this dating conversation screenshot.

CRITICAL PARTICIPANT RULE:

The generated message must be written FROM THE USER
TO THE OTHER PERSON.

The user is the person who owns the account using UpCrush.

The other person is the person the user is talking to.

Do not reverse them.

Use all visual evidence available to determine who is who:

- bubble alignment
- bubble colors
- names
- avatars
- profile headers
- timestamps
- message sequence
- UI structure

RIGHT SIDE often means USER.

LEFT SIDE often means OTHER PERSON.

But never rely on that rule alone.

If names, colors, avatars or conversation structure contradict
the normal left/right assumption, follow the stronger evidence.

ANALYSIS PROCESS:

1. Read the entire visible conversation from top to bottom.
2. Identify the user.
3. Identify the other person.
4. Identify the user's messages.
5. Identify the other person's messages.
6. Identify the latest message from the other person.
7. Identify the user's message immediately before it.
8. Understand the context of the latest message.
9. Identify useful details from earlier messages.
10. Determine the conversational vibe.
11. Estimate the apparent investment level.
12. Determine the best next conversational move.
13. Write the response FROM THE USER TO THE OTHER PERSON.

Do NOT output the analysis.

Do NOT invent text that is not visible.

If some text is unreadable, ignore it.

Do not assume that the last visible bubble automatically belongs
to the other person. Determine ownership first.

Generate exactly TWO genuinely different responses.

REPLY A:
Natural, conversational and appropriate.

REPLY B:
A meaningfully different strategy using the same context.
It may be more playful, flirty or bold if the conversation
actually supports it.

Do not make both replies variations of the same sentence.

Return valid JSON only:

{
  "responses": [
    "reply A",
    "reply B"
  ]
}

The responses must be written in $idioma.
''';

    return _chamarComImagemComFallback(
      base64Image: base64Image,
      system: system,
      user: user,
      lang: lang,
    );
  }

  // ============================================================
  // OPENER FROM PROFILE IMAGE
  // ============================================================

  static Future<List<String>> gerarOpenerDeImagem(
    String base64Image,
    String estilo,
    String lang,
  ) async {
    final idioma = _idiomaNomes[lang] ?? 'English';

    final system = '''
You are UpCrush AI, an expert dating conversation assistant.

Create first messages based ONLY on concrete, observable details
in a dating profile image.

LANGUAGE:
Only $idioma.

The opener must feel specifically written for this person.

Do NOT:

- say she is beautiful
- give generic physical compliments
- invent personality traits
- invent where she is
- invent hobbies
- invent facts
- use generic pickup lines
- use "you seem like trouble"
- use "I had to swipe right"
- use boring interview questions

Analyze the image carefully.

Look for:

1. concrete objects
2. activities
3. recognizable environments
4. animals
5. food
6. sports
7. travel elements
8. unusual objects
9. interesting visual details
10. anything that can naturally start a conversation

Do not claim something is true about the person's personality
based only on their appearance.

Choose the strongest available conversational hook.

Generate exactly TWO genuinely different openers.

OPENING A:
Natural and clever.

OPENING B:
More playful or flirty if the image genuinely supports it.

Both must be specific to the image.

Return valid JSON only:

{
  "responses": [
    "opener A",
    "opener B"
  ]
}
''';

    final user = '''
Analyze this dating profile image carefully.

Find the most specific conversational detail that another person
could realistically use to start a conversation.

Create two openers that could realistically be sent to this
exact person.

Do not invent anything that cannot be seen.
''';

    return _chamarComImagemComFallback(
      base64Image: base64Image,
      system: system,
      user: user,
      lang: lang,
    );
  }

  // ============================================================
  // OPENER FROM TEXT PROFILE
  // ============================================================

  static Future<List<String>> gerarOpener(
    String descricao,
    String estilo,
    String lang,
  ) async {
    final idioma = _idiomaNomes[lang] ?? 'English';

    final system = '''
You are UpCrush AI, an expert dating conversation assistant.

Create a first message based on a dating profile.

LANGUAGE:
Only $idioma.

The opener must feel specifically written for this profile.

Do NOT use:

- generic compliments
- generic questions
- generic pickup lines
- "you're beautiful"
- "you seem like trouble"
- "I had to swipe right"
- interview-style questions
- invented information

Analyze the profile first.

Find:

1. concrete personal details
2. unusual interests
3. places
4. hobbies
5. humor opportunities
6. conversation hooks
7. details that can naturally create curiosity

Choose ONE strong hook.

Generate exactly TWO genuinely different openers.

A:
Natural and clever.

B:
More playful or flirty when appropriate.

Both must be grounded in the actual profile.

Return valid JSON only:

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
  // PICKUP LINES
  // ============================================================

  static Future<List<String>> gerarPickLines(String lang) async {
    final idioma = _idiomaNomes[lang] ?? 'English';

    final system = '''
You are UpCrush AI, an expert at writing playful dating messages.

Generate exactly TWO short standalone lines in $idioma.

They should be:

- confident
- playful
- modern
- natural
- respectful
- not creepy
- not explicit
- not manipulative
- not generic

Avoid classic pickup-line clichés.

Make the two lines genuinely different.

Return JSON only:

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
  // OPENAI TEXT + FALLBACK
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

      if (parsed.length >= 2) {
        return parsed;
      }

      throw Exception('Invalid OpenAI response');
    } catch (_) {
      final result = await _chamarAnthropic(
        system: system,
        user: user,
      );

      final parsed = _parseStructured(result);

      if (parsed.length >= 2) {
        return parsed;
      }

      throw Exception('Both AI providers failed');
    }
  }

  // ============================================================
  // IMAGE + FALLBACK
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

      if (parsed.length >= 2) {
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

      if (parsed.length >= 2) {
        return parsed;
      }

      throw Exception('Both AI providers failed');
    }
  }

  // ============================================================
  // OPENAI TEXT
  // ============================================================

  static Future<String> _chamarOpenAI({
    required String system,
    required String user,
  }) async {
    final response = await http
        .post(
          Uri.parse(
            'https://api.openai.com/v1/chat/completions',
          ),
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
            'max_tokens': 500,
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
                  'required': ['responses'],
                  'additionalProperties': false,
                },
              },
            },
          }),
        )
        .timeout(const Duration(seconds: 20));

    if (response.statusCode != 200) {
      throw Exception(
        'OpenAI ${response.statusCode}: ${response.body}',
      );
    }

    final data = jsonDecode(response.body);

    final content =
        data['choices']?[0]?['message']?['content'];

    if (content == null) {
      throw Exception('OpenAI returned no content.');
    }

    return content.toString();
  }

  // ============================================================
  // OPENAI IMAGE
  // ============================================================

  static Future<String> _chamarOpenAIImage({
    required String base64Image,
    required String system,
    required String user,
  }) async {
    final response = await http
        .post(
          Uri.parse(
            'https://api.openai.com/v1/chat/completions',
          ),
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
            'max_tokens': 500,
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
                  'required': ['responses'],
                  'additionalProperties': false,
                },
              },
            },
          }),
        )
        .timeout(const Duration(seconds: 30));

    if (response.statusCode != 200) {
      throw Exception(
        'OpenAI image ${response.statusCode}: ${response.body}',
      );
    }

    final data = jsonDecode(response.body);

    final content =
        data['choices']?[0]?['message']?['content'];

    if (content == null) {
      throw Exception(
        'OpenAI image returned no content.',
      );
    }

    return content.toString();
  }

  // ============================================================
  // ANTHROPIC TEXT
  // ============================================================

  static Future<String> _chamarAnthropic({
    required String system,
    required String user,
  }) async {
    final response = await http
        .post(
          Uri.parse(
            'https://api.anthropic.com/v1/messages',
          ),
          headers: {
            'Content-Type': 'application/json',
            'x-api-key': _anthropicKey,
            'anthropic-version': '2023-06-01',
          },
          body: jsonEncode({
            'model': _anthropicModel,
            'max_tokens': 500,
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

    final content =
        data['content']?[0]?['text'];

    if (content == null) {
      throw Exception(
        'Anthropic returned no content.',
      );
    }

    return content.toString();
  }

  // ============================================================
  // ANTHROPIC IMAGE
  // ============================================================

  static Future<String> _chamarAnthropicImage({
    required String base64Image,
    required String system,
    required String user,
  }) async {
    final response = await http
        .post(
          Uri.parse(
            'https://api.anthropic.com/v1/messages',
          ),
          headers: {
            'Content-Type': 'application/json',
            'x-api-key': _anthropicKey,
            'anthropic-version': '2023-06-01',
          },
          body: jsonEncode({
            'model': _anthropicModel,
            'max_tokens': 500,
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

    final content =
        data['content']?[0]?['text'];

    if (content == null) {
      throw Exception(
        'Anthropic image returned no content.',
      );
    }

    return content.toString();
  }

  // ============================================================
  // STRUCTURED PARSER
  // ============================================================

  static List<String> _parseStructured(String body) {
    try {
      dynamic decoded = jsonDecode(body);

      // Alguns providers podem devolver JSON dentro de uma string.
      if (decoded is String) {
        decoded = jsonDecode(decoded);
      }

      if (decoded is! Map) {
        return <String>[];
      }

      final responses = decoded['responses'];

      if (responses is! List) {
        return <String>[];
      }

      final List<String> result = <String>[];

      for (final item in responses) {
        if (item is! String) {
          continue;
        }

        final cleaned = _cleanResponse(item);

        if (cleaned.isEmpty) {
          continue;
        }

        if (_looksLikeAIRefusal(cleaned)) {
          continue;
        }

        result.add(cleaned);

        if (result.length == 2) {
          break;
        }
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

    e = e.replaceFirst(
      RegExp(
        r'^\s*(response|reply|option|opção|resposta)\s*[12]?\s*[:.)-]\s*',
        caseSensitive: false,
      ),
      '',
    );

    e = e.replaceFirst(
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
    final lower = text.toLowerCase().trim();

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
      'je ne peux pas',
      'non posso',
      'üzgünüm',
      'nie mogę',
      'я не могу',
      'لا أستطيع',
    ];

    return badStarts.any(
      (prefix) => lower.startsWith(prefix),
    );
  }

  // ============================================================
  // LEGACY PARSER
  // ============================================================

  static List<String> _parseLegacyText(String body) {
    try {
      dynamic data;

      try {
        data = jsonDecode(body);
      } catch (_) {
        data = null;
      }

      String text = '';

      if (data is Map &&
          data['choices'] is List &&
          (data['choices'] as List).isNotEmpty) {
        final choice = data['choices'][0];

        if (choice is Map &&
            choice['message'] is Map) {
          text =
              choice['message']['content']?.toString() ?? '';
        }
      } else if (data is Map &&
          data['content'] is List &&
          (data['content'] as List).isNotEmpty) {
        final first = data['content'][0];

        if (first is Map) {
          text = first['text']?.toString() ?? '';
        }
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
              r'[a-zA-ZÀ-ɏА-яА-Я]',
            ).hasMatch(e),
          )
          .where(
            (e) => !_looksLikeAIRefusal(e),
          )
          .toList();

      final result = <String>[];

      for (final line in lines) {
        if (!result.contains(line)) {
          result.add(line);
        }

        if (result.length == 2) {
          break;
        }
      }

      return result;
    } catch (_) {
      return <String>[];
    }
  }
}