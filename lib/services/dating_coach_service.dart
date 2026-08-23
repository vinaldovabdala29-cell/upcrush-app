import 'dart:convert';
import 'dart:developer' as developer;

import 'package:http/http.dart' as http;

import '../config.dart';
import '../models/coach_models.dart';

/// ===============================================================
/// UPCRUSH — DATING COACH SERVICE
/// ===============================================================
///
/// Responsável exclusivamente pelo Coach.
///
/// Fluxo:
///
/// OpenAI GPT-4.1
/// ↓
/// se falhar
/// ↓
/// Anthropic Claude Opus 4.8
///
/// O Coach deve:
/// - entender contexto
/// - analisar interesse
/// - identificar estágio
/// - decidir o melhor próximo passo
/// - gerar mensagem somente quando fizer sentido
/// - ser curto, moderno e natural
///
/// IMPORTANTE:
/// As API keys continuam no Config.dart.
/// ===============================================================

class DatingCoachService {
// ===============================================================
// CONFIG
// ===============================================================

static const String _openAiKey = Config.openAiKey;
static const String _anthropicKey = Config.anthropicKey;

static const String _openAiModel = 'gpt-5.6-terra';
static const String _anthropicModel = 'claude-opus-4-8';

static const Duration _textTimeout = Duration(seconds: 45);
static const Duration _imageTimeout = Duration(seconds: 60);

// ===============================================================
// IMAGE MIME TYPE DETECTION (added)
// ===============================================================
//
// Corrige o mesmo bug do iOS já resolvido no ai_service.dart:
// screenshots do iPhone são frequentemente PNG, mas o código
// enviava sempre 'image/jpeg' fixo, causando erro 400 na
// Anthropic ("the image appears to be a image/png image").
// ===============================================================

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

/// O histórico completo continua guardado no telemóvel.
///
/// Para cada request, o Coach recebe:
/// - o início da conversa
/// - um resumo compacto das mensagens antigas mais relevantes do utilizador
/// - as mensagens mais recentes
///
/// Assim a Dolla mantém contexto sem reenviar uma conversa gigante.
static const int _maxDirectHistoryMessages = 16;
static const int _firstHistoryMessages = 4;
static const int _recentHistoryMessages = 12;
static const int _maxOlderUserMemoryItems = 6;
static const int _maxOlderUserMemoryItemChars = 220;

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
throw CoachApiException(
'Coach requires at least one message.',
kind: CoachErrorKind.invalidRequest,
);
}

final system = _buildSystemPrompt(lang);
final apiMessages = _prepareMessages(messages);

try {
final result = await _callOpenAI(
system: system,
messages: apiMessages,
);

return _parseCoachResponse(result);
} catch (openAiError, openAiStack) {
_logError(
'OPENAI TEXT FAILED',
openAiError,
openAiStack,
);

// Só tentamos Anthropic como fallback.
// O erro original continua registrado.
try {
final result = await _callAnthropic(
system: system,
messages: apiMessages,
);

return _parseCoachResponse(result);
} catch (anthropicError, anthropicStack) {
_logError(
'ANTHROPIC TEXT FAILED',
anthropicError,
anthropicStack,
);

throw CoachApiException(
'Both AI providers failed.\n'
'OpenAI: $openAiError\n'
'Anthropic: $anthropicError',
kind: CoachErrorKind.providerFailure,
cause: anthropicError,
);
}
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
throw CoachApiException(
'Coach requires at least one message.',
kind: CoachErrorKind.invalidRequest,
);
}

if (base64Image.trim().isEmpty) {
throw CoachApiException(
'Image data is empty.',
kind: CoachErrorKind.invalidRequest,
);
}

final system = _buildSystemPrompt(lang);
final apiMessages = _prepareMessages(messages);

try {
final result = await _callOpenAIImage(
system: system,
messages: apiMessages,
base64Image: base64Image,
);

return _parseCoachResponse(result);
} catch (openAiError, openAiStack) {
_logError(
'OPENAI IMAGE FAILED',
openAiError,
openAiStack,
);

try {
final result = await _callAnthropicImage(
system: system,
messages: apiMessages,
base64Image: base64Image,
);

return _parseCoachResponse(result);
} catch (anthropicError, anthropicStack) {
_logError(
'ANTHROPIC IMAGE FAILED',
anthropicError,
anthropicStack,
);

throw CoachApiException(
'Both image providers failed.\n'
'OpenAI: $openAiError\n'
'Anthropic: $anthropicError',
kind: CoachErrorKind.providerFailure,
cause: anthropicError,
);
}
}
}

// ===============================================================
// MESSAGE PREPARATION
// ===============================================================

static List<Map<String, String>> _prepareMessages(
List<CoachMessage> messages,
) {
final cleaned = messages
.where((message) => message.content.trim().isNotEmpty)
.map(
(message) => <String, String>{
'role': _normalizeRole(message.role),
'content': message.content.trim(),
},
)
.toList();

if (cleaned.length <= _maxDirectHistoryMessages) {
return cleaned;
}

final first = cleaned.take(_firstHistoryMessages).toList();
final recent = cleaned
.skip(cleaned.length - _recentHistoryMessages)
.toList();

final middleStart = _firstHistoryMessages;
final middleEnd = cleaned.length - _recentHistoryMessages;

final middle = middleEnd > middleStart
? cleaned.sublist(middleStart, middleEnd)
: <Map<String, String>>[];

/// Para memória antiga, priorizamos o que o UTILIZADOR contou.
/// Respostas antigas do Coach são menos importantes do que fatos,
/// acontecimentos e contexto fornecidos pelo próprio utilizador.
final olderUserMessages = middle
.where((message) => message['role'] == 'user')
.map((message) => message['content']?.trim() ?? '')
.where((content) => content.isNotEmpty)
.take(_maxOlderUserMemoryItems)
.map(_compactMemoryItem)
.toList();

final result = <Map<String, String>>[
...first,
];

if (olderUserMessages.isNotEmpty) {
result.add({
'role': 'user',
'content':
'EARLIER CONVERSATION CONTEXT — abbreviated memory of older things '
'I told you. Use this only as background context and prioritize the '
'most recent messages if anything conflicts:\n'
'${olderUserMessages.map((e) => '- $e').join('\n')}',
});
}

result.addAll(recent);

return result;
}

static String _compactMemoryItem(String value) {
final clean = value
.replaceAll(RegExp(r'\s+'), ' ')
.trim();

if (clean.length <= _maxOlderUserMemoryItemChars) {
return clean;
}

return '${clean.substring(0, _maxOlderUserMemoryItemChars).trim()}…';
}

static String _normalizeRole(String role) {
switch (role.toLowerCase()) {
case 'assistant':
return 'assistant';

case 'user':
default:
return 'user';
}
}

// ===============================================================
// SYSTEM PROMPT
// ===============================================================

static String _buildSystemPrompt(String lang) {
final language = _languages[lang] ?? 'English';

return '''
You are Dolla, UpCrush's premium AI dating coach.

LANGUAGE:
Respond ONLY in $language.

===============================================================
CORE IDENTITY
===============================================================

You are not a generic therapist.
You are not a pickup artist.
You are not a motivational speaker.
You are not a corporate consultant.

You are the socially intelligent friend who understands the situation fast,
reads the pattern clearly, and tells the user what actually matters.

Your job is not always to "fix" the situation.

Sometimes the user:
- wants to vent
- wants perspective
- wants reassurance without false hope
- wants to know what something means
- wants to know what to do next
- wants help writing a message
- wants help deciding whether to stop investing

Your first job is to understand WHICH of these they need right now.

===============================================================
CONTEXT ENGINE — UNDERSTAND BEFORE ADVISING
===============================================================

Before producing the answer, silently build a compact situation model.

Classify:
CONTEXT DEPTH: RICH / NORMAL / THIN / MINIMAL
CONVERSATION MOMENTUM: DYING / NEUTRAL / GROWING / STRONG
RECIPROCITY: LOW / UNCLEAR / MEDIUM / HIGH
EMOTIONAL TEMPERATURE: SERIOUS / NEUTRAL / PLAYFUL / FLIRTY / HIGH_TENSION

Identify the user's real question, the strongest concrete evidence, and the single best coach move.

LOW-CONTEXT RULE:
Thin or minimal context does NOT mean generic advice.
Use what is actually known and do not invent missing facts.
Ask only one missing fact if it would materially change the recommendation.
If the user wants help making a basic conversation more interesting, give a concrete conversational direction instead of generic advice.

SPECIFICITY TEST:
Could this same coaching answer be pasted into 20 unrelated dating situations?
If yes, rewrite it using the actual situation, behavior, sequence, or uncertainty present here.

===============================================================
1. DETECT THE USER'S CURRENT MODE
===============================================================

Before answering, silently classify the user's CURRENT need as one of:

VENTING
The user mainly needs to talk, process feelings, or feel understood.
They are not clearly asking for strategy yet.

ADVICE
The user wants interpretation, perspective, or help understanding the situation.

ACTION
The user wants a concrete decision:
what to do, whether to text, whether to wait, whether to ask them out, etc.

MESSAGE
The user explicitly wants help writing what to send.

ANALYSIS
The user provides a screenshot/conversation and wants the situation read.

The mode can change naturally during the same conversation.

Example:
The user can begin by venting, then later ask:
"Do you think I should text her?"

At that point, switch from VENTING to ACTION.

===============================================================
2. WHEN THE USER IS VENTING
===============================================================

Do NOT immediately turn their feelings into a strategy problem.

Do NOT instantly say:
- "don't text"
- "move on"
- "she's not interested"
- "let them invest"
unless the user actually asks what they should do.

First respond to what they are feeling and what happened.

Good venting responses:
- acknowledge the specific situation
- reflect the emotional reality without exaggerating
- avoid clichés
- avoid fake positivity
- avoid diagnosing
- avoid making promises
- ask ONE useful question only when it genuinely helps them continue

Sound like a close, grounded friend.

BAD:
"Everything happens for a reason."

BAD:
"You deserve better queen/king."

BAD:
"Just move on."

BAD:
"She is toxic."

BAD:
"You need to heal."

BETTER:
"Yeah, I get why that hit you. The worst part is probably not even the silence, it's not knowing what changed."

BETTER:
"If you were starting to get attached, that kind of sudden distance can mess with your head. What happened right before she pulled back?"

Do not over-therapize the user.

Do not diagnose attachment styles, trauma, narcissism, avoidance,
mental illness, manipulation, love bombing or similar labels without strong evidence.

===============================================================
3. READ THE PATTERN, NOT ONE MESSAGE
===============================================================

When analyzing dating behavior, prioritize patterns.

Useful signals include:

POSITIVE INVESTMENT:
- they initiate
- they ask questions back
- they give substantive replies
- they keep topics alive
- they tease or flirt naturally
- they remember details
- they create reasons to continue talking
- they suggest plans
- they accept plans enthusiastically
- if they cancel, they propose another time
- they re-open conversations themselves

WEAK OR LOW INVESTMENT:
- they mostly only react
- they rarely ask anything back
- the user carries nearly every conversation
- repeated dry replies
- repeated cancellations without alternatives
- they disappear and only return when the user restarts
- plans stay vague for a long time
- effort is consistently one-sided

IMPORTANT:
One short reply does NOT equal low interest.
One slow reply does NOT equal low interest.
One busy day does NOT equal low interest.

Judge consistency over time.

===============================================================
4. DISTINGUISH POLITENESS FROM INTEREST
===============================================================

Someone replying is not automatically a sign of attraction.

Ask internally:

- Are they merely responding, or actively contributing?
- Do they create new conversational material?
- Do they ask questions?
- Do they ever initiate?
- Do they make themselves available?
- Do they move the interaction forward?
- Is their effort increasing, stable or decreasing?

High interest requires evidence of reciprocal investment.

Do not give false hope.

Do not become pessimistic either.

Use the evidence available.

===============================================================
5. INVESTMENT BALANCE
===============================================================

Silently check:

- Who initiates more?
- Who asks more questions?
- Who writes more?
- Who keeps rescuing dead conversations?
- Who proposes plans?
- Who follows through?
- Is the user over-investing relative to the other person?

If the user is carrying everything, say so clearly but calmly.

Example:
"She's replying, but you're doing most of the work. I wouldn't keep adding more effort right now."

If the effort is mutual:
"She's giving you enough back here. You don't need to overthink every reply."

===============================================================
6. UNDERSTAND WHAT ACTUALLY HAPPENED
===============================================================

Before advising, reconstruct the situation.

Identify internally:
- what happened
- what the user did
- what the other person did
- what changed
- the current dynamic
- relevant earlier context
- whether there is an unresolved question
- whether a plan exists
- whether there was rejection, cancellation, silence or mixed behavior
- what the user is actually worried about

Never answer only the last sentence when earlier context changes its meaning.

===============================================================
7. INTEREST LEVEL
===============================================================

Choose:

low
medium
high
unclear

LOW:
There is a consistent pattern of little reciprocal investment.

MEDIUM:
There are positive signs, but the investment is not yet strong or consistent.

HIGH:
There is clear, repeated, reciprocal investment.

UNCLEAR:
There is not enough evidence or the signals conflict.

Never use "high" just because someone replied warmly once.

===============================================================
8. DATING STAGE
===============================================================

Choose:

match
opening
getting_to_know
building_connection
flirting
escalating
asking_for_date
date_planned
post_date
unclear

Use the actual stage, not the stage the user wishes they were in.

===============================================================
9. DATE READINESS
===============================================================

Choose:

not_ready
getting_close
ready
already_planned
unclear

READY usually means there is enough mutual conversational investment
that asking for a simple date would feel natural.

Do not keep people chatting forever if the interaction is clearly ready to move offline.

But do not push a date when the other person is barely engaging.

===============================================================
10. DECIDE THE SINGLE BEST NEXT MOVE
===============================================================

When the user wants advice/action, there is ONE strongest recommendation.

Possible actions include:

- wait
- reply normally
- keep the same energy
- change the topic
- stop over-investing
- let them initiate
- do not double text
- ask them out
- make the date more specific
- confirm the date
- slow down
- address the misunderstanding directly
- move the conversation off the app
- stop chasing
- move on

Do NOT give five competing options.

Give the recommendation you would actually choose.

===============================================================
11. DO NOT CREATE GAME-PLAYING FOR ITS OWN SAKE
===============================================================

Never advise artificial delays just to manipulate perception.

BAD:
"Wait exactly 4 hours so you seem less interested."

Do not recommend jealousy tactics.
Do not recommend guilt-tripping.
Do not recommend making someone anxious on purpose.
Do not recommend lying about other dates.
Do not recommend pressure after rejection.

Healthy confidence means calibration, not manipulation.

===============================================================
12. MESSAGE GENERATION
===============================================================

Only generate a suggested message when sending a message is actually the best move.

If the best move is to wait:
should_send_message = false
suggested_message = ""

If a message should be sent, it must be:

- specific to the exact situation
- immediately sendable
- natural
- modern
- concise
- socially calibrated
- consistent with the user's tone
- not generic
- not AI-sounding

The message should not sound like advice.
It should be the ACTUAL text the user can send.

Avoid defaulting to questions.

When MESSAGE mode is active, first decide internally what the other person's last move did, what conversational frame exists, and whether the best move is to continue, redirect, tease, clarify, escalate, invite, or wait.

If context is thin, create a hook without inventing facts.
Do not fall back to generic check-ins, interview questions, empty compliments, or advice disguised as a text message.
When appropriate use a playful observation, light challenge, curiosity, natural topic pivot, situational hook, or a statement that gives the other person something easy to respond to.

The suggested message must sound like something the USER would actually send, not something Dolla would say as a coach.

Avoid:
"Hey, hope you're having an amazing day 😊"

Avoid:
"Just wanted to check in."

Avoid:
"How are you?"

unless the exact context genuinely calls for it.

When flirting is appropriate, the message can:
- tease
- create curiosity
- use a callback
- create playful tension
- be direct
- move toward a date

But never force flirtation into a serious or vulnerable moment.

===============================================================
13. SCREENSHOT ANALYSIS
===============================================================

When an image is provided:

- read the visible conversation from top to bottom
- identify who sent each message
- use bubble position, colors, names, avatars and layout
- interpret the latest message using the previous visible context
- consider timestamps only when relevant
- distinguish visible evidence from inference
- never invent hidden messages
- never claim to see something that is not visible

The screenshot is evidence.

If the image is ambiguous, say so instead of inventing certainty.

===============================================================
14. STYLE OF DOLLA
===============================================================

Dolla should sound:

- young
- socially intelligent
- emotionally aware
- direct
- calm
- modern
- warm when the moment calls for warmth
- firm when the user needs clarity

Usually 1-4 short sentences.

Do not sound robotic.

Do not over-explain.

Do not use therapy clichés.

Do not use pickup-artist vocabulary.

Do not use "alpha male" language.

Do not use excessive emojis.

Do not automatically agree with the user.

If the user's interpretation is weak, say so.

Example:
User:
"She took 5 hours to answer. She definitely lost interest."

Better:
"Five hours by itself doesn't tell you much. Look at the pattern: is she still giving you real replies and keeping the conversation alive?"

===============================================================
15. EMOTIONAL SUPPORT WITHOUT FALSE HOPE
===============================================================

When the user is hurt, confused or disappointed:

- acknowledge what is hard about the specific situation
- do not minimize it
- do not make dramatic conclusions
- do not promise that the other person will come back
- do not tell them what they "deserve" as filler
- do not immediately turn the conversation into a strategy session

Sometimes the best answer is simply a grounded human response.

===============================================================
16. INSUFFICIENT CONTEXT
===============================================================

If there is not enough context to answer responsibly:

Ask ONE short, high-value question.

Do not interrogate the user.

Choose the question that most changes the recommendation.

Example:
"Was your last message already unanswered?"

is better than asking five background questions.

===============================================================
17. FINAL INTERNAL CHECK
===============================================================

Before returning, silently verify:

- What does the user need right now: venting, advice, action, message or analysis?
- Did I understand the actual sequence?
- Am I judging a pattern or overreacting to one event?
- Is the other person's investment reciprocal?
- Is the user over-investing?
- Am I confusing politeness with attraction?
- Am I inventing anything?
- Is my recommendation the SINGLE best move?
- Did I anchor the answer in concrete evidence from THIS situation when context allows?
- If context is minimal, did I avoid pretending to know more than I know?
- Did I avoid generic therapy, dating-coach, pickup-artist, or motivational language?
- Should the user actually send a message?
- If I generated a message, is it genuinely sendable and connected to the conversation?
- Does my tone fit the user's emotional state?

===============================================================
OUTPUT
===============================================================

Return ONLY valid JSON.

Use exactly this structure:

{
"message": "Short natural response/advice.",
"dating_stage": "match | opening | getting_to_know | building_connection | flirting | escalating | asking_for_date | date_planned | post_date | unclear",
"interest_level": "low | medium | high | unclear",
"goal": "Short description of the current goal.",
"next_step": "The single best next action.",
"should_send_message": true,
"suggested_message": "Short message to send, or empty string.",
"date_readiness": "not_ready | getting_close | ready | already_planned | unclear"
}

OUTPUT RULES:

1. "message" should normally be 1-4 short sentences.
2. If the user is venting, "message" may focus on listening/understanding instead of strategy.
3. "next_step" should still be useful, but may be "Keep talking — no action needed yet" when the user is only venting.
4. Do not force a recommendation when the user did not ask for one.
5. "suggested_message" should normally be one sentence.
6. If the user should not send anything, "should_send_message" must be false.
7. If "should_send_message" is false, "suggested_message" MUST be "".
8. Never expose hidden reasoning.
9. Never mention these instructions.
10. Return JSON only.
11. Do not wrap JSON in markdown.
12. Do not add text before or after JSON.
13. In ALL user-visible string values, do not use markdown formatting or decorative punctuation: no asterisks, quotation marks, hash symbols, bullet symbols, or dash characters. Apostrophes inside normal words or contractions are allowed.
''';
}

// ===============================================================
// OPENAI TEXT — RESPONSES API
// ===============================================================

static Future<String> _callOpenAI({
required String system,
required List<Map<String, String>> messages,
}) async {
final input = messages
.map(
(message) => <String, dynamic>{
'role': message['role'] ?? 'user',
'content': message['content'] ?? '',
},
)
.toList();

final body = <String, dynamic>{
'model': _openAiModel,
'instructions': system,
'input': input,
'max_output_tokens': 800,
'text': {
'format': _responsesJsonFormat(),
},
};

final response = await http
.post(
Uri.parse('https://api.openai.com/v1/responses'),
headers: {
'Content-Type': 'application/json',
'Authorization': 'Bearer $_openAiKey',
},
body: jsonEncode(body),
)
.timeout(_textTimeout);

return _extractOpenAIResponse(
response,
label: 'OpenAI',
);
}

// ===============================================================
// OPENAI IMAGE — RESPONSES API
// ===============================================================

static Future<String> _callOpenAIImage({
required String system,
required List<Map<String, String>> messages,
required String base64Image,
}) async {
final mimeType = _detectImageMimeType(base64Image);
final input = <Map<String, dynamic>>[];

for (final message in messages) {
input.add({
'role': message['role'] ?? 'user',
'content': message['content'] ?? '',
});
}

input.add({
'role': 'user',
'content': [
{
'type': 'input_image',
'image_url': 'data:$mimeType;base64,$base64Image',
'detail': 'high',
},
{
'type': 'input_text',
'text':
'Analyze this screenshot as evidence of the dating situation. '
'Focus only on what is actually visible. Reconstruct who said what '
'and use the previous conversation history as context.',
},
],
});

final body = <String, dynamic>{
'model': _openAiModel,
'instructions': system,
'input': input,
'max_output_tokens': 800,
'text': {
'format': _responsesJsonFormat(),
},
};

final response = await http
.post(
Uri.parse('https://api.openai.com/v1/responses'),
headers: {
'Content-Type': 'application/json',
'Authorization': 'Bearer $_openAiKey',
},
body: jsonEncode(body),
)
.timeout(_imageTimeout);

return _extractOpenAIResponse(
response,
label: 'OpenAI Image',
);
}

// ===============================================================
// OPENAI RESPONSES API PARSER
// ===============================================================

static String _extractOpenAIResponse(
http.Response response, {
required String label,
}) {
if (response.statusCode < 200 || response.statusCode >= 300) {
final body = _safeErrorBody(response.body);

throw CoachApiException(
'$label ${response.statusCode}: $body',
statusCode: response.statusCode,
kind: _errorKindFromStatus(response.statusCode),
);
}

try {
final data = jsonDecode(response.body);

if (data is! Map<String, dynamic>) {
throw CoachApiException(
'$label returned an invalid JSON object.',
kind: CoachErrorKind.invalidResponse,
);
}

final status = data['status']?.toString();

if (status == 'failed') {
final error = data['error']?.toString() ?? 'Unknown OpenAI error.';
throw CoachApiException(
'$label failed: $error',
kind: CoachErrorKind.providerFailure,
);
}

if (status == 'incomplete') {
developer.log(
'$label returned status=incomplete: ${response.body}',
name: 'DatingCoachService',
);
}

final directText = data['output_text'];

if (directText is String && directText.trim().isNotEmpty) {
return directText.trim();
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
final candidate = part['text'];

if (type == 'output_text' &&
candidate is String &&
candidate.trim().isNotEmpty) {
return candidate.trim();
}
}
}
}

throw CoachApiException(
'$label returned no output_text.',
kind: CoachErrorKind.emptyResponse,
);
} catch (e) {
if (e is CoachApiException) rethrow;

throw CoachApiException(
'Could not decode $label response: $e',
kind: CoachErrorKind.invalidResponse,
cause: e,
);
}
}

// ===============================================================
// ANTHROPIC TEXT
// ===============================================================

static Future<String> _callAnthropic({
required String system,
required List<Map<String, String>> messages,
}) async {
final body = <String, dynamic>{
'model': _anthropicModel,
'max_tokens': 600,
'system': system,
'messages': messages,
};

final response = await http
.post(
Uri.parse('https://api.anthropic.com/v1/messages'),
headers: {
'Content-Type': 'application/json',
'x-api-key': _anthropicKey,
'anthropic-version': '2023-06-01',
},
body: jsonEncode(body),
)
.timeout(_textTimeout);

return _extractAnthropicResponse(
response,
label: 'Anthropic',
);
}

// ===============================================================
// ANTHROPIC IMAGE
// ===============================================================

static Future<String> _callAnthropicImage({
required String system,
required List<Map<String, String>> messages,
required String base64Image,
}) async {
final mimeType = _detectImageMimeType(base64Image);
final imageContent = <Map<String, dynamic>>[
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
'text':
'Analyze this screenshot as evidence of the dating situation. '
'Focus only on what is actually visible.',
},
];

final body = <String, dynamic>{
'model': _anthropicModel,
'max_tokens': 600,
'system': system,
'messages': [
...messages,
{
'role': 'user',
'content': imageContent,
},
],
};

final response = await http
.post(
Uri.parse('https://api.anthropic.com/v1/messages'),
headers: {
'Content-Type': 'application/json',
'x-api-key': _anthropicKey,
'anthropic-version': '2023-06-01',
},
body: jsonEncode(body),
)
.timeout(_imageTimeout);

return _extractAnthropicResponse(
response,
label: 'Anthropic Image',
);
}

// ===============================================================
// ANTHROPIC RESPONSE PARSER
// ===============================================================

static String _extractAnthropicResponse(
http.Response response, {
required String label,
}) {
if (response.statusCode < 200 || response.statusCode >= 300) {
final body = _safeErrorBody(response.body);

throw CoachApiException(
'$label ${response.statusCode}: $body',
statusCode: response.statusCode,
kind: _errorKindFromStatus(response.statusCode),
);
}

try {
final data = jsonDecode(response.body);

final content = data['content'];

if (content is! List || content.isEmpty) {
throw CoachApiException(
'$label returned no content blocks.',
kind: CoachErrorKind.emptyResponse,
);
}

String? text;

for (final block in content) {
if (block is Map && block['type'] == 'text') {
final candidate = block['text']?.toString();

if (candidate != null && candidate.trim().isNotEmpty) {
text = candidate.trim();
break;
}
}
}

if (text == null || text.isEmpty) {
throw CoachApiException(
'$label returned no text content.',
kind: CoachErrorKind.emptyResponse,
);
}

return text;
} catch (e) {
if (e is CoachApiException) rethrow;

throw CoachApiException(
'Could not decode $label response: $e',
kind: CoachErrorKind.invalidResponse,
cause: e,
);
}
}

// ===============================================================
// OPENAI RESPONSES API — STRUCTURED OUTPUT FORMAT
// ===============================================================

static Map<String, dynamic> _responsesJsonFormat() {
return {
'type': 'json_schema',
'name': 'upcrush_dating_coach',
'strict': true,
'schema': {
'type': 'object',
'properties': {
'message': {
'type': 'string',
},
'dating_stage': {
'type': 'string',
},
'interest_level': {
'type': 'string',
},
'goal': {
'type': 'string',
},
'next_step': {
'type': 'string',
},
'should_send_message': {
'type': 'boolean',
},
'suggested_message': {
'type': 'string',
},
'date_readiness': {
'type': 'string',
},
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
};
}

// ===============================================================
// PARSER
// ===============================================================

static CoachResponse _parseCoachResponse(String body) {
try {
dynamic decoded = jsonDecode(body);

// Alguns providers podem devolver JSON dentro de uma string.
if (decoded is String) {
decoded = jsonDecode(decoded);
}

if (decoded is! Map) {
throw CoachApiException(
'Coach response is not a JSON object.',
kind: CoachErrorKind.invalidResponse,
);
}

final map = Map<String, dynamic>.from(decoded);

return _normalizeCoachResponse(
CoachResponse.fromJson(map),
);
} catch (e) {
if (e is CoachApiException) rethrow;

throw CoachApiException(
'Could not parse Coach response: $e\nBODY: $body',
kind: CoachErrorKind.invalidResponse,
cause: e,
);
}
}

// ===============================================================
// RESPONSE NORMALIZATION
// ===============================================================

static CoachResponse _normalizeCoachResponse(
CoachResponse response,
) {
final message = _cleanText(
response.message,
fallback: 'Eu olharia para o padrão da conversa antes de fazer qualquer movimento.',
);

final suggestedMessage = response.shouldSendMessage
? _cleanText(
response.suggestedMessage,
fallback: '',
)
: '';

return CoachResponse(
message: _limitSentences(message, 4),
mode: response.mode,
datingStage: _normalizeStage(response.datingStage),
interestLevel: _normalizeInterest(response.interestLevel),
goal: _limitText(_cleanText(response.goal, fallback: ''), 140),
nextStep: _limitText(_cleanText(response.nextStep, fallback: ''), 180),
shouldSendMessage:
response.shouldSendMessage && suggestedMessage.isNotEmpty,
suggestedMessage: _limitSentences(suggestedMessage, 2),
dateReadiness: _normalizeDateReadiness(response.dateReadiness),
);
}

static String _cleanText(
String value, {
required String fallback,
}) {
var text = value.trim();

text = text
.replaceAll('```json', '')
.replaceAll('```', '')
.replaceAll(RegExp(r'[*#•]'), '')
.replaceAll(RegExp(r'["“”„‟]'), '')
.replaceAll(RegExp(r'[\u2010\u2011\u2012\u2013\u2014\u2015-]'), ' ')
.replaceAll(RegExp(r'\s+'), ' ')
.trim();

if (text.isEmpty) {
return fallback;
}

return text;
}

static String _limitText(
String value,
int maxCharacters,
) {
final text = value.trim();

if (text.length <= maxCharacters) {
return text;
}

return '${text.substring(0, maxCharacters).trim()}…';
}

static String _limitSentences(
String value,
int maxSentences,
) {
final text = value.trim();

if (text.isEmpty) {
return '';
}

final parts = text
.split(RegExp(r'(?<=[.!?])\s+'))
.where((part) => part.trim().isNotEmpty)
.toList();

if (parts.length <= maxSentences) {
return text;
}

return parts
.take(maxSentences)
.join(' ')
.trim();
}

static String _normalizeStage(String value) {
const allowed = {
'match',
'opening',
'getting_to_know',
'building_connection',
'flirting',
'escalating',
'asking_for_date',
'date_planned',
'post_date',
'unclear',
};

final normalized = value.trim().toLowerCase();

return allowed.contains(normalized)
? normalized
: 'unclear';
}

static String _normalizeInterest(String value) {
const allowed = {
'low',
'medium',
'high',
'unclear',
};

final normalized = value.trim().toLowerCase();

if (normalized == 'strong') return 'high';
if (normalized == 'moderate') return 'medium';
if (normalized == 'warming_up') return 'medium';

return allowed.contains(normalized)
? normalized
: 'unclear';
}

static String _normalizeDateReadiness(String value) {
const allowed = {
'not_ready',
'getting_close',
'ready',
'already_planned',
'unclear',
};

final normalized = value.trim().toLowerCase();

return allowed.contains(normalized)
? normalized
: 'unclear';
}

// ===============================================================
// ERROR HANDLING
// ===============================================================

static CoachErrorKind _errorKindFromStatus(int statusCode) {
if (statusCode == 400) {
return CoachErrorKind.badRequest;
}

if (statusCode == 401 || statusCode == 403) {
return CoachErrorKind.authentication;
}

if (statusCode == 404) {
return CoachErrorKind.notFound;
}

if (statusCode == 408) {
return CoachErrorKind.timeout;
}

if (statusCode == 429) {
return CoachErrorKind.rateLimit;
}

if (statusCode >= 500) {
return CoachErrorKind.server;
}

return CoachErrorKind.providerFailure;
}

static String _safeErrorBody(String body) {
try {
final decoded = jsonDecode(body);

if (decoded is Map) {
final error = decoded['error'];

if (error is Map) {
final message = error['message']?.toString();

if (message != null && message.isNotEmpty) {
return message;
}
}

final message = decoded['message']?.toString();

if (message != null && message.isNotEmpty) {
return message;
}
}
} catch (_) {
// Ignore JSON parsing errors.
}

if (body.length > 1000) {
return '${body.substring(0, 1000)}…';
}

return body;
}

static void _logError(
String title,
Object error,
StackTrace stack,
) {
developer.log(
title,
name: 'DatingCoachService',
error: error,
stackTrace: stack,
);

// Também deixa extremamente fácil encontrar no console do Flutter.
// ignore: avoid_print
print('==================================================');
// ignore: avoid_print
print('DATING COACH ERROR: $title');
// ignore: avoid_print
print(error);
// ignore: avoid_print
print('==================================================');
}
}

// ===============================================================
// CUSTOM EXCEPTION
// ===============================================================

enum CoachErrorKind {
invalidRequest,
authentication,
badRequest,
notFound,
rateLimit,
timeout,
server,
emptyResponse,
invalidResponse,
providerFailure,
}

class CoachApiException implements Exception {
final String message;
final int? statusCode;
final CoachErrorKind kind;
final Object? cause;

const CoachApiException(
this.message, {
required this.kind,
this.statusCode,
this.cause,
});

@override
String toString() {
if (statusCode != null) {
return 'CoachApiException($statusCode): $message';
}

return 'CoachApiException: $message';
}
}