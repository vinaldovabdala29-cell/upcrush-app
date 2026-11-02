import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config.dart';
import 'conversation_starter_service.dart';
import 'tones/tone_registry.dart';

/// Transporte, histórico, formato e validação. Os prompts vivem em tones/.
class AIService {
  static final http.Client _client = http.Client();
  static const String _openAiKey = Config.openAiKey;
  static const String _openAiModel = 'gpt-5.6-luna';
  static const String _openAiModelPickLine = 'gpt-5.6-luna';
  static const List<String> cantadaCategoriaKeys = _CantadaCategories.cantadaCategoriaKeys;
  static String cantadaCategoriaNome(String key, String lang) =>
      _CantadaCategories.cantadaCategoriaNome(key, lang);

  static String _imagePayload(String image) {
    final trimmed = image.trim();
    final payload = trimmed.startsWith('data:')
        ? trimmed.substring(trimmed.indexOf(',') + 1)
        : trimmed;
    if (trimmed.startsWith('data:') && !trimmed.contains(',')) {
      throw ArgumentError('Invalid image data URL');
    }
    return payload.replaceAll(RegExp(r'\s+'), '');
  }

  static String _detectImageMimeType(String base64Image) {
    final payload = _imagePayload(base64Image);
    if (payload.isEmpty) throw ArgumentError('Empty image');
    final sample = payload.substring(
      0,
      payload.length > 16 ? 16 : payload.length,
    );
    final bytes = base64Decode(base64.normalize(sample));
    if (bytes.length >= 8 &&
        bytes[0] == 0x89 &&
        bytes[1] == 0x50 &&
        bytes[2] == 0x4e &&
        bytes[3] == 0x47 &&
        bytes[4] == 0x0d &&
        bytes[5] == 0x0a &&
        bytes[6] == 0x1a &&
        bytes[7] == 0x0a)
      return 'image/png';
    if (bytes.length >= 3 &&
        bytes[0] == 0xff &&
        bytes[1] == 0xd8 &&
        bytes[2] == 0xff)
      return 'image/jpeg';
    if (bytes.length >= 12 &&
        ascii.decode(bytes.sublist(0, 4), allowInvalid: true) == 'RIFF' &&
        ascii.decode(bytes.sublist(8, 12), allowInvalid: true) == 'WEBP')
      return 'image/webp';
    if (bytes.length >= 6 &&
        (ascii.decode(bytes.sublist(0, 6), allowInvalid: true) == 'GIF87a' ||
            ascii.decode(bytes.sublist(0, 6), allowInvalid: true) == 'GIF89a'))
      return 'image/gif';
    throw ArgumentError('Unsupported image. Use PNG, JPEG, WEBP or GIF.');
  }

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

  static final Map<String, List<String>> _responseHistory = {};
  static const int _historyLimit = 24;
  static const int _historyScopesLimit = 40;

  static String _scope(
    String feature,
    String lang,
    String context, [
    String? conversationId,
  ]) {
    // Dois hashes limitam colisões sem guardar screenshots inteiros em memória.
    var a = 2166136261;
    var b = 5381;
    for (final unit in (conversationId ?? context).codeUnits) {
      a = ((a ^ unit) * 16777619) & 0xffffffff;
      b = ((b * 33) ^ unit) & 0xffffffff;
    }
    return '$feature:$lang:${context.isEmpty && conversationId == null ? "empty" : "$a:$b"}';
  }

  static List<String> _recent(String scope, List<String> supplied) {
    final combined = [
      ...?_responseHistory[scope],
      ...supplied,
    ].map(_cleanResponse).where((s) => s.isNotEmpty).toList();
    return combined
        .skip(
          combined.length > _historyLimit ? combined.length - _historyLimit : 0,
        )
        .toList();
  }

  static void _remember(String scope, List<String> replies) {
    final merged = _recent(scope, replies);
    _responseHistory.remove(scope);
    _responseHistory[scope] = merged;
    while (_responseHistory.length > _historyScopesLimit) {
      _responseHistory.remove(_responseHistory.keys.first);
    }
  }

  static void limparHistoricoRespostas() {
    _responseHistory.clear();
  }


  static int _checkedQuantity(int requested) {
    if (requested < 1 || requested > 8) {
      throw ArgumentError.value(requested, 'quantidade', 'Use de 1 a 8 respostas');
    }
    return requested;
  }

  static Future<List<String>> gerarResposta(
    String conversa,
    String estilo,
    String lang, {
    int quantidade = 1,
    List<String> recentResponses = const [],
    String? conversationId,
  }) => _generate(
    task: 'chat', context: conversa, estilo: estilo, lang: lang,
    quantity: quantidade, recentResponses: recentResponses,
    conversationId: conversationId,
  );

  static Future<List<String>> gerarRespostaDeImagem(
    String base64Image,
    String estilo,
    String lang, {
    int quantidade = 1,
    bool modoRapido = false,
    List<String> recentResponses = const [],
    String? conversationId,
    String contexto = '',
    String orientacao = '',
  }) {
    _checkedQuantity(quantidade);
    return _generate(
      task: 'screenshot', context: contexto, estilo: estilo, lang: lang,
      extraData: orientacao.trim().isEmpty ? const {} : {'user_direction_untrusted': orientacao.trim()},
      quantity: modoRapido ? 1 : quantidade,
      recentResponses: recentResponses, conversationId: conversationId,
      base64Image: base64Image, includeChatContext: true, fastMode: modoRapido,
    );
  }

  // Compatibilidade com a chamada OCR existente em ResultScreen.
  static Future<List<String>> gerarRespostaDeOCR(
    String conversa, String ultimaMensagem, String estilo, String lang,
  ) => _generate(
    task: 'ocr', context: conversa, estilo: estilo, lang: lang,
    quantity: 1, extraData: {'last_incoming': ultimaMensagem},
  );

  static Future<List<String>> gerarOpenerDeImagem(
    String base64Image, String estilo, String lang, [
    List<String> evitarRespostas = const [],
  ]) => _generate(
    task: 'opener_image', context: '', estilo: estilo, lang: lang,
    quantity: 1, base64Image: base64Image,
    recentResponses: evitarRespostas,
  );

  static Future<List<String>> gerarOpener(
    String descricao, String estilo, String lang, {
    List<String> recentResponses = const [],
    String? conversationId,
  }) => _generate(
    task: 'opener_text', context: descricao, estilo: estilo, lang: lang,
    quantity: 1, recentResponses: recentResponses,
    conversationId: conversationId,
  );

  static Future<List<String>> gerarPickLines(
    String lang, {
    List<String> recentResponses = const [],
  }) => _generate(
    task: 'pick_line', context: '', estilo: 'romantico', lang: lang,
    quantity: 1, recentResponses: recentResponses,
  );

  static Future<String> gerarPickLine({
    required String lang,
    required String categoria,
    String estilo = 'romantico',
    List<String> recentLines = const [],
    String contexto = '',
  }) async {
    if (categoria == 'iniciar_conversa') {
      return ConversationStarterService.gerar(
        lang: lang, estilo: estilo, recentLines: recentLines, contexto: contexto,
      );
    }
    if (!_CantadaCategories.descricoes.containsKey(categoria)) {
      throw ArgumentError.value(categoria, 'categoria', 'Categoria desconhecida');
    }
    final tone = ToneRegistry.resolve(estilo);
    final scope = _scope('pick_line:$categoria:${tone.key}', lang, contexto);
    final recent = _recent(scope, recentLines);
    final rejected = <String>[];
    for (var attempt = 0; attempt < 2; attempt++) {
      final raw = await _chamarOpenAIPickLine(
        model: _openAiModelPickLine,
        system: tone.systemPrompt,
        user: jsonEncode({
          'task': 'pick_line', 'quantity': 1,
          'language': _idiomaNomes[lang] ?? 'English',
          'context_untrusted': contexto,
          'category': categoria,
          'category_description': _CantadaCategories.descricoes[categoria],
          'recent_messages_to_avoid': recent,
          'rejected_drafts': rejected,
          'attempt': attempt,
        }),
      );
      final line = _parseSinglePickLine(raw);
      if (tone.accepts(line) && !_isRepeatOfRecent(line, recent)) {
        _remember(scope, [line]);
        return line;
      }
      rejected.add(line);
    }
    throw Exception('Pick line returned invalid or repeated output after retry');
  }

  static Future<List<String>> _generate({
    required String task,
    required String context,
    required String estilo,
    required String lang,
    required int quantity,
    List<String> recentResponses = const [],
    String? conversationId,
    String? base64Image,
    bool includeChatContext = false,
    bool fastMode = false,
    Map<String, dynamic> extraData = const {},
  }) async {
    _checkedQuantity(quantity);
    final tone = ToneRegistry.resolve(estilo);
    final scope = _scope('$task:${tone.key}', lang,
        base64Image ?? context, conversationId);
    final recent = _recent(scope, recentResponses);
    final accepted = <String>[];
    final rejected = <String>[];
    // Mantém geração de alternativas e repetição técnica, sem avaliador de tom.
    final candidateCount = quantity;
    for (var attempt = 0; attempt < 2; attempt++) {
      final user = jsonEncode({
        'task': task,
        'language': _idiomaNomes[lang] ?? 'English',
        'quantity': candidateCount,
        'context_untrusted': context,
        'recent_messages_to_avoid': [...recent, ...accepted],
        'rejected_drafts': rejected,
        'attempt': attempt,
        ...extraData,
      });
      final raw = base64Image == null
          ? await _chamarOpenAI(
              system: tone.systemPrompt, user: user, quantidade: candidateCount)
          : await _chamarOpenAIImage(
              base64Image: base64Image, system: tone.systemPrompt,
              user: user, quantidade: candidateCount,
              includeChatContext: includeChatContext);
      for (final line in _parseStructured(raw)) {
        if (!tone.accepts(line) ||
            _isRepeatOfRecent(line, [...recent, ...accepted])) {
          rejected.add(line);
          continue;
        }
        accepted.add(line);
        if (accepted.length == quantity) {
          _remember(scope, accepted);
          return accepted;
        }
      }
    }
    throw Exception('Could not generate enough distinct valid responses');
  }

  static String _normalize(String value) => value
      .toLowerCase()
      .replaceAll(RegExp(r'[^\p{L}\p{N}\s]', unicode: true), ' ')
      .replaceAll(RegExp(r'\s+'), ' ')
      .trim();

  static bool _isRepeatOfRecent(String text, List<String> recentLines) {
    final normalized = _normalize(text);
    if (normalized.isEmpty) return false;
    return recentLines.any((recent) {
      final other = _normalize(recent);
      return other.isNotEmpty &&
          (normalized == other || _tooSimilar(text, recent));
    });
  }

  static bool _tooSimilar(String a, String b) {
    final na = _normalize(a);
    final nb = _normalize(b);
    if (na == nb) return true;
    final wa = na.split(' ').where((x) => x.isNotEmpty).toList();
    final wb = nb.split(' ').where((x) => x.isNotEmpty).toList();
    // Heurística lexical conservadora; diversidade conceptual é avaliada no prompt.
    if (wa.length < 5 || wb.length < 5) return false;
    final sa = wa.toSet();
    final sb = wb.toSet();
    final union = sa.union(sb).length;
    return union > 0 && sa.intersection(sb).length / union >= 0.85;
  }

  static Future<String> _chamarOpenAIPickLine({
    required String model,
    required String system,
    required String user,
  }) async {
    final response = await _client
        .post(
          Uri.parse('https://api.openai.com/v1/responses'),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $_openAiKey',
          },
          body: jsonEncode({
            'model': model,
            'instructions': system,
            'input': [
              {
                'role': 'user',
                'content': [
                  {'type': 'input_text', 'text': user},
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
                    'response': {'type': 'string'},
                  },
                  'required': ['response'],
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
        '(${response.statusCode})',
      );

      throw Exception('OpenAI pick line ${response.statusCode}');
    }

    final data = jsonDecode(response.body);

    if (data is! Map<String, dynamic>) {
      throw Exception('OpenAI pick line returned invalid JSON object');
    }

    final status = data['status']?.toString();

    if (status == 'incomplete' || status == 'failed' || status == 'cancelled') {
      final details = data['incomplete_details'];
      // ignore: avoid_print
      print(
        'OpenAI pick line INCOMPLETA. '
        'Detalhes: $details',
      );
      throw Exception('OpenAI pick line incomplete: $details');
    }

    return _extractOpenAIResponseText(data);
  }

  // ============================================================

  static Future<String> _chamarOpenAI({
    required String system,
    required String user,
    int quantidade = 1,
  }) async {
    final response = await _client
        .post(
          Uri.parse('https://api.openai.com/v1/responses'),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $_openAiKey',
          },
          body: jsonEncode({
            'model': _openAiModel,
            'service_tier': 'fast',
            'instructions': system,
            'input': [
              {
                'role': 'user',
                'content': [
                  {'type': 'input_text', 'text': user},
                ],
              },
            ],
            'max_output_tokens': 200 + quantidade * 160,
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
                      'items': {'type': 'string'},
                      'minItems': quantidade,
                      'maxItems': quantidade,
                    },
                  },
                  'required': ['responses'],
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
        '(${response.statusCode})',
      );

      throw Exception('OpenAI ${response.statusCode}');
    }

    final data = jsonDecode(response.body);

    if (data is! Map<String, dynamic>) {
      throw Exception('OpenAI text returned invalid JSON object');
    }

    final status = data['status']?.toString();
    if (status == 'incomplete' || status == 'failed' || status == 'cancelled') {
      // ignore: avoid_print
      throw Exception('OpenAI text response status: $status');
    }

    return _extractOpenAIResponseText(data);
  }

  // ============================================================
  // OPENAI IMAGE REQUEST
  // ============================================================

  static Map<String, dynamic> _datingSchema(
    int quantity, {
    bool includeChatContext = false,
  }) {
    return {
      'type': 'object',
      'properties': {
        if (includeChatContext)
          'chat': {
            'type': 'object',
            'properties': {
              'readable': {'type': 'boolean'},
              'speaker_confident': {'type': 'boolean'},
              'last_incoming': {'type': 'string'},
              'last_incoming_in_output_language': {'type': 'string'},
              'prior_context': {'type': 'string'},
              'intent': {'type': 'string'},
              'concrete_hook': {'type': 'string'},
            },
            'required': [
              'readable',
              'speaker_confident',
              'last_incoming',
              'last_incoming_in_output_language',
              'prior_context',
              'intent',
              'concrete_hook',
            ],
            'additionalProperties': false,
          },
        'responses': {
          'type': 'array',
          'items': {'type': 'string'},
          'minItems': quantity,
          'maxItems': quantity,
        },
      },
      'required': [if (includeChatContext) 'chat', 'responses'],
      'additionalProperties': false,
    };
  }

  static Future<String> _chamarOpenAIImage({
    required String base64Image,
    required String system,
    required String user,
    int quantidade = 1,
    bool includeChatContext = false,
  }) async {
    final mimeType = _detectImageMimeType(base64Image);
    final response = await _client
        .post(
          Uri.parse('https://api.openai.com/v1/responses'),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $_openAiKey',
          },
          body: jsonEncode({
            'model': _openAiModel,
            'service_tier': 'fast',
            'instructions': system,
            'input': [
              {
                'role': 'user',
                'content': [
                  {
                    'type': 'input_image',
                    'image_url':
                        'data:$mimeType;base64,${_imagePayload(base64Image)}',
                    'detail': includeChatContext ? 'high' : 'auto',
                  },
                  {'type': 'input_text', 'text': user},
                ],
              },
            ],
            'max_output_tokens':
                (includeChatContext ? 550 : 200) + quantidade * 160,
            'text': {
              'format': {
                'type': 'json_schema',
                'name': 'dating_responses',
                'strict': true,
                'schema': _datingSchema(
                  quantidade,
                  includeChatContext: includeChatContext,
                ),
              },
            },
          }),
        )
        .timeout(const Duration(seconds: 45));

    if (response.statusCode != 200) {
      // ignore: avoid_print
      print(
        'OpenAI imagem FALHOU '
        '(${response.statusCode})',
      );

      throw Exception('OpenAI image ${response.statusCode}');
    }

    final data = jsonDecode(response.body);

    if (data is! Map<String, dynamic>) {
      throw Exception('OpenAI image returned invalid JSON object');
    }

    final status = data['status']?.toString();
    if (status == 'incomplete' || status == 'failed' || status == 'cancelled') {
      // ignore: avoid_print
      throw Exception('OpenAI image response status: $status');
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

          if (type == 'output_text' &&
              text is String &&
              text.trim().isNotEmpty) {
            return text.trim();
          }
        }
      }
    }

    return '';
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
      print('PICK LINE PARSE ERROR: $e');
      return '';
    }
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

        if (result.length == 8) break;
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
    e = e.replaceAll(RegExp(r'^\s*[-•*#>]\s*'), '');

    // Limpeza global para TODAS as funcionalidades.
    // Nenhuma resposta final deve conter asteriscos, aspas, cardinal ou traços.
    e = e.replaceAll(RegExp(r'[\*#"“”„‟«»‹›]'), '');

    e = e.replaceAll(RegExp(r'\s+[-–—―]+\s+|[–—―]+|-{2,}'), ' ');

    // Remove marcadores visuais semelhantes a listas.
    e = e.replaceAll(RegExp(r'[•▪◦‣]+'), ' ');

    e = e.replaceAll(RegExp(r"[:;()\-]"), ' ')
        .replaceAll(RegExp(r"['’‘]"), '');

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
    final lower = text.toLowerCase().trim();
    return RegExp(
      r'^(as an ai\b|as a language model\b|como (uma? )?ia\b|'
      r'como modelo de linguagem\b|als (eine? )?ki\b|'
      r"i (cannot|can't|can’t) (assist with|help (with|you with)|generate)\b)",
      caseSensitive: false,
    ).hasMatch(lower);
  }

  // ============================================================
  // LEGACY PARSER FALLBACK
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
          .where((e) => RegExp(r'\p{L}', unicode: true).hasMatch(e))
          .toList();

      return lines.take(8).toList();
    } catch (_) {
      return [];
    }
  }
}


// Metadados das categorias; os prompts continuam nos ficheiros de cada tom.
class _CantadaCategories {
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

  static const Map<String, Map<String, String>> nomes = {
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

  static const Map<String, String> descricoes = {
    'surpreenda_me': 'FREE PREMIUM MODE. Do not follow one fixed category. Silently choose a fresh strategy that is meaningfully different from recent lines. Rotate between confident flirting, clever teasing, curiosity, playful assumptions, bold but tasteful compliments, pattern breaks, light double meanings and unexpected conversational hooks. The result must feel surprising, premium and immediately sendable. Never announce which strategy was chosen.',
    'iniciar_conversa': 'Create a strong first message or conversation starter when there is little or no context. Consolidate the best ideas from first-match openers, starting out of nowhere, talking to someone the user already likes and natural everyday conversation. Avoid interview questions and generic greetings. Give the other person an easy, interesting reason to respond.',
    'flertar': 'Create clear romantic tension in a modern, natural way. Consolidate mid-conversation flirting, party flirting, direct interest, bold compliments and light double meaning. It may tease, imply chemistry or be more direct, but must stay socially calibrated, non-explicit and immediately sendable.',
    'elogiar': 'Give a compliment with personality instead of generic praise. It may focus on style, energy, attitude, confidence, humor or attraction. Prefer a compliment that creates a conversational opening, playful tension or a memorable reaction rather than simply saying beautiful/handsome.',
    'provocar_brincar': 'Use playful teasing, a affectionate reversal, playful accusation, witty comeback or humorous framing. It should invite teasing back and never become insulting, humiliating, defensive or aggressive.',
    'bom_dia_noite': 'Create a morning or nighttime message with personality. Silently choose the appropriate direction from the wording/context available; when no time context exists, generate a versatile warm/flirty check-in rather than a plain greeting. Avoid generic "good morning, did you sleep well?" and plain "good night".',
    'elogios_duplo_sentido': 'A compliment with a flirtatious second layer. Clever, natural and lightly suggestive, never vulgar or explicit.',
    'meio_da_conversa': 'A flirt that can naturally enter an ongoing conversation. It should react to the existing dynamic instead of feeling scripted.',
    'abordagem_rua': 'A short, natural in-person approach to a stranger. Confident without invading personal space.',
    'respondendo_story': 'A story reply based on a concrete detail in the story. It should feel like a spontaneous reaction rather than an empty compliment.',
    'conhecida': 'A flirt for someone the user already knows. Use existing familiarity instead of a stranger approach.',
    'esta_rindo': 'Use the fact that the person is laughing as a situational hook. Keep it playful and natural.',
    'te_olha_varias_vezes': 'Use repeated eye contact as a playful situational opportunity. Never claim that looking proves attraction.',
    'mexe_no_cabelo': 'Use the gesture only as a situational detail. Never claim that playing with hair proves attraction.',
    'provoca_voce': 'Respond to teasing with confidence, humor and a light tease back. Never sound defensive or aggressive.',
    'diz_que_bonito': 'Turn a received compliment into natural flirting. Return the compliment, joke or lightly raise the tension.',
    'diz_que_engracado': 'Use the compliment about humor to build connection or flirt. Do not answer with a canned joke.',
    'diz_nao_interessado': 'Respond with respect and lightness. Never pressure, insist, manipulate or try to convince the person.',
    'elogios_coragem': 'Compliment attitude, initiative, confidence or personality specifically and naturally.',
    'flerte_festa': 'A flirt suitable for parties, bars, events and social settings. Short, spontaneous and socially natural.',
    'ambiente_a_favor':
        'Use something concrete from the environment as a conversational hook.',
    'elogios_provocacao': 'A compliment paired with a small tease. Light tension without arrogance.',
    'elogios_ousados': 'A more direct and intense flirt while remaining natural, respectful and non-explicit.',
    'conversa_esfriou': 'Revive a conversation that lost energy without sounding desperate, needy or artificial.',
    'monossilabos': 'Respond to dry messages such as "yes", "no", "lol", "haha" or one-word answers. Avoid another generic question. Prefer changing the dynamic, reacting to something or adding energy.',
    'primeira_msg_match': 'Create the first message after a match. Easy to answer, modern and natural. Avoid "hey, what is up", generic compliments and classic lines.',
    'match_sumiu': 'Revive a match that went quiet without cobrança, resentment or pressure.',
    'pedir_numero_instagram': 'Transition naturally from the conversation to asking for a number or Instagram. It should feel like a natural progression.',
    'convidar_sair': 'Turn enough mutual interest into a clear, simple and specific date invitation.',
    'confirmar_date': 'Confirm an arranged date calmly and confidently. Never sound anxious or formal.',
    'depois_ignorada': 'Resume contact after an unanswered message without demanding or pressuring.',
    'testando_voce': 'Respond to teasing or challenging questions with relaxed confidence, without arrogance or defensiveness.',
    'depois_primeiro_encontro': 'Message after a first date to maintain connection naturally and potentially create an opening for a second date.',
    'elogio_primeiro_date': 'Give a specific, personal compliment related to the first date rather than a generic physical compliment.',
    'retomar_conversa_antiga': 'Reconnect after days or weeks naturally, without artificial excuses or neediness.',

    // NOVA CATEGORIA
    'criar_curiosidade': 'Create genuine curiosity through an unexpected observation, playful statement, intriguing unfinished thought or specific hook. The message should naturally make the other person want to ask "what do you mean?", "why?", or continue the conversation. Never use fake mystery, manipulation, clickbait or vague lines like "I have something to tell you".',

    'dar_bom_dia': 'Start a morning conversation with more personality than a plain "good morning". It should feel warm, playful or lightly flirty depending on the style. Avoid boring defaults like "good morning, did you sleep well?" unless transformed into something more interesting.',
    'dar_boa_tarde': 'Start or restart a conversation during the afternoon in a natural way. Avoid a plain "good afternoon". Add a small hook, playful observation or easy conversational angle.',
    'dar_boa_noite': 'Send a nighttime message that can feel warm, charming or lightly flirty depending on the style. Avoid a plain "good night". The message should create a small emotional connection or give the other person something to react to.',
    'como_foi_seu_dia': 'Ask about the other person’s day without literally defaulting to "how was your day?". Turn it into a more specific, playful, easy-to-answer or emotionally engaging question.',
    'puxar_assunto_do_nada': 'Start a conversation when there is no obvious context. Use a pattern break, playful thought, fun question, specific romantic image or unexpected observation. Avoid empty mystery and generic small talk.',
    'comecar_com_quem_gosto': 'Start a conversation with someone the user already likes. Show clear but calibrated interest. It should feel natural, confident and a little more intentional than friendly small talk, without sounding needy or over-romantic.',
  };

  static String cantadaCategoriaNome(String key, String lang) {
    final map = nomes[key];
    if (map == null) return key;
    return map[lang] ?? map['en'] ?? key;
  }

}
