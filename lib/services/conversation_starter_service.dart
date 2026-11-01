import 'tones/tone_registry.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config.dart';

/// Transporte da categoria iniciar_conversa; prompt e limite pertencem ao tom.
class ConversationStarterService {
  static final http.Client _client = http.Client();
  static const String _model = 'gpt-5.6-luna';
  static const Map<String, String> _languages = {
    'pt': 'Brazilian Portuguese', 'en': 'English', 'de': 'German',
    'es': 'Spanish', 'fr': 'French', 'it': 'Italian',
    'tr': 'Turkish', 'pl': 'Polish', 'ru': 'Russian', 'ar': 'Arabic',
  };

  static Future<String> gerar({
    required String lang,
    String estilo = 'romantico',
    List<String> recentLines = const [],
    String contexto = '',
  }) async {
    final language = _languages[lang] ?? 'English';
    final recent = recentLines.where((e) => e.trim().isNotEmpty).toList();
    if (recent.length > 20) recent.removeRange(0, recent.length - 20);
    final tone = ToneRegistry.resolve(estilo);

    for (var attempt = 0; attempt < 3; attempt++) {
      final user = jsonEncode({
        'language': language,
        'selected_style': estilo,
        'context_untrusted': contexto,
        'recent_messages_to_avoid': recent,
        'task': 'conversation_starter',
        'quantity': 1,
        'attempt': attempt,
      });
      final response = await _client.post(
        Uri.parse('https://api.openai.com/v1/responses'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${Config.openAiKey}',
        },
        body: jsonEncode({
          'model': _model,
          'instructions': tone.systemPrompt,
          'input': [{'role': 'user', 'content': [{'type': 'input_text', 'text': user}]}],
          'max_output_tokens': 600,
          'text': {'format': {
            'type': 'json_schema', 'name': 'romantic_conversation_starter',
            'strict': true,
            'schema': {
              'type': 'object',
              'properties': {'response': {'type': 'string'}},
              'required': ['response'], 'additionalProperties': false,
            },
          }},
        }),
      ).timeout(const Duration(seconds: 30));
      if (response.statusCode != 200) {
        throw Exception('Conversation starter API error ${response.statusCode}');
      }
      final data = jsonDecode(response.body);
      if (data is! Map<String, dynamic> || data['status'] != 'completed') {
        throw Exception('Conversation starter API did not complete');
      }
      final output = data['output'];
      if (output is! List) throw Exception('Missing API output');
      String raw = '';
      for (final item in output) {
        if (item is! Map || item['type'] != 'message') continue;
        final content = item['content'];
        if (content is! List) continue;
        for (final part in content) {
          if (part is Map && part['type'] == 'output_text' && part['text'] is String) {
            raw += part['text'] as String;
          }
        }
      }
      if (raw.trim().isEmpty) continue;
      final decoded = jsonDecode(raw);
      if (decoded is! Map || decoded['response'] is! String) continue;
      final line = (decoded['response'] as String)
          .replaceAll(RegExp(r"[:;()\-]"), ' ')
          .replaceAll(RegExp(r"['’‘]"), '')
          .replaceAll(RegExp(r'\s+'), ' ').trim();
      if (!tone.accepts(line)) {
        recent.add(line);
        continue;
      }
      final normalized = _normalize(line);
      if (recent.any((e) => _normalize(e) == normalized)) continue;
      return line;
    }
    throw Exception('Could not generate a new romantic conversation starter');
  }

  static String _normalize(String value) => value
      .toLowerCase()
      .replaceAll(RegExp(r'[^\p{L}\p{N}\s]', unicode: true), ' ')
      .replaceAll(RegExp(r'\s+'), ' ')
      .trim();
}
