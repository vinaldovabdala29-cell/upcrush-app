import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import '../../../main.dart';
import '../../../config.dart';

class ChatbotScreen extends StatefulWidget {
  const ChatbotScreen({super.key});
  @override
  State<ChatbotScreen> createState() => _ChatbotScreenState();
}

class _ChatbotScreenState extends State<ChatbotScreen>
    with TickerProviderStateMixin {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<Map<String, dynamic>> _messages = [];
  bool _loading = false;
  File? _imagemAnexada;
  String? _base64Imagem;

  static const String _apiKey = Config.openAiKey;
  static const String _anthropicKey = Config.anthropicKey;
  static const _accent = Color(0xFFFF2D55);
  static const _accentDark = Color(0xFFFF6B81);

  bool get _dark => isDarkModeNotifier.value;
  Color get _bg => _dark ? const Color(0xFF0A0A10) : const Color(0xFFF5F5F7);
  Color get _textPrimary => _dark ? Colors.white : const Color(0xFF1C1C1E);
  Color get _textSecondary => _dark ? Colors.white54 : Colors.black45;
  Color get _bubbleAI => _dark ? const Color(0xFF1E1E2E) : Colors.white;
  Color get _inputBg => _dark ? const Color(0xFF1A1A24) : Colors.white;

  String get _welcomeMessage {
    switch (appLang.languageCode) {
      case 'de': return "Hey! Ich bin dein UpCrush AI Coach 🎯\n\nBeschreib die Situation oder füge ein Screenshot hinzu. Ich gebe dir die perfekte Antwort.";
      case 'es': return "¡Hey! Soy tu UpCrush AI Coach 🎯\n\nDescribe la situación o añade una captura. Te doy la respuesta perfecta.";
      case 'pt': return "Hey! Sou o teu UpCrush AI Coach 🎯\n\nDescreve a situação ou anexa um screenshot. Dou-te a resposta perfeita.";
      default:   return "Hey! I'm your UpCrush AI Coach 🎯\n\nDescribe the situation or add a screenshot. I'll give you the perfect reply.";
    }
  }

  String get _systemPrompt {
    final lang = appLang.languageCode;
    final idioma = lang == 'de' ? 'German' : lang == 'es' ? 'Spanish' : lang == 'pt' ? 'Brazilian Portuguese' : 'English';
    return """
You are UpCrush AI — a sharp, experienced dating coach. Think of yourself as a smart friend who has seen it all.
LANGUAGE: ONLY in $idioma.

YOUR PERSONALITY:
- Conversational and natural — not robotic
- You give advice and move on. You don't repeat what you already said.
- You suggest the next move WITHOUT being asked
- You read between the lines of what he tells you
- You are direct. If something won't work, say it fast and give the fix.

WHAT YOU DO IN EVERY RESPONSE:
1. Answer what he asked or analyze what he shared (1-2 sentences, sharp)
2. Give the move to make RIGHT NOW (specific, not general)
3. Write 1-2 messages he can send immediately
4. At the end: suggest the NEXT step he should think about (1 short line)

EMOTIONAL TRIGGERS IN YOUR MESSAGES:
Use whichever fits: curiosity, tension, desire, excitement, mystery, challenge, fear of missing out.
Make her feel something. Not politeness — emotion.

CONVERSATION RULES:
- If he asks a question: answer it directly, then give the next move
- If he updates you: react to the update, adjust strategy, give new messages
- If something is working: tell him to escalate
- If something is failing: diagnose why fast, pivot strategy
- NEVER repeat advice you already gave unless he asks
- NEVER over-explain — say it once, move forward
- Keep replies short: max 100 words unless the situation genuinely needs more

MESSAGE FORMAT:
Plain text only. No asterisks, no quotes around messages, no hashtags, no dashes, no numbers before messages.
""";
  }

  @override
  void initState() {
    super.initState();
    isDarkModeNotifier.addListener(_onThemeChange);
    _messages.add({"role": "assistant", "content": _welcomeMessage, "time": _getTime()});
  }

  @override
  void dispose() {
    isDarkModeNotifier.removeListener(_onThemeChange);
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _onThemeChange() { if (mounted) setState(() {}); }

  String _getTime() {
    final now = DateTime.now();
    return '${now.hour.toString().padLeft(2,'0')}:${now.minute.toString().padLeft(2,'0')}';
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final img = await picker.pickImage(source: ImageSource.gallery, imageQuality: 60);
    if (img == null || !mounted) return;
    final bytes = await File(img.path).readAsBytes();
    setState(() {
      _imagemAnexada = File(img.path);
      _base64Imagem = base64Encode(bytes);
    });
  }

  void _removeImage() => setState(() { _imagemAnexada = null; _base64Imagem = null; });

  // Clean AI response from formatting symbols
  String _cleanReply(String text) {
    return text
      .replaceAll(RegExp(r'\*+'), '')
      .replaceAll(RegExp(r'#+'), '')
      .replaceAll(RegExp(r'_+'), '')
      .replaceAll(RegExp(r'^\d+[.)]\s*', multiLine: true), '')
      .replaceAll(RegExp(r'^[-•]\s*', multiLine: true), '')
      .replaceAll(RegExp(r'^["""]+|["""]+$', multiLine: true), '')
      .replaceAll(RegExp(r"^['']+|['']+$", multiLine: true), '')
      .trim();
  }

  Future<void> _sendMessage() async {
    final text = _controller.text.trim();
    if ((text.isEmpty && _base64Imagem == null) || _loading) return;

    final displayText = text.isNotEmpty ? text : (appLang.languageCode == 'pt' ? '[Imagem anexada]' : appLang.languageCode == 'de' ? '[Bild angehängt]' : '[Image attached]');

    setState(() {
      _messages.add({
        "role": "user",
        "content": displayText,
        "time": _getTime(),
        if (_imagemAnexada != null) "image": _imagemAnexada!.path,
      });
      _loading = true;
    });
    _controller.clear();
    final base64 = _base64Imagem;
    setState(() { _imagemAnexada = null; _base64Imagem = null; });
    _scrollToBottom();

    try {
      // Build API messages
      final apiMessages = <Map<String, dynamic>>[];
      for (final msg in _messages.where((m) => m["role"] == "user" || (m["role"] == "assistant" && m != _messages.first))) {
        if (msg["role"] == "user" && msg == _messages.last) {
          // Last user message — may include image
          if (base64 != null) {
            apiMessages.add({"role": "user", "content": [
              {"type": "image_url", "image_url": {"url": "data:image/jpeg;base64,$base64", "detail": "high"}},
              {"type": "text", "text": text.isNotEmpty ? text : "Analyze this screenshot and give me the perfect reply."},
            ]});
          } else {
            apiMessages.add({"role": "user", "content": msg["content"]});
          }
        } else {
          apiMessages.add({"role": msg["role"]!, "content": msg["content"]!});
        }
      }

      String? reply;
      try {
        final res = await http.post(
          Uri.parse("https://api.openai.com/v1/chat/completions"),
          headers: {"Content-Type": "application/json", "Authorization": "Bearer $_apiKey"},
          body: jsonEncode({"model": "gpt-4o", "messages": [{"role": "system", "content": _systemPrompt}, ...apiMessages], "temperature": 0.85, "max_tokens": 200}),
        ).timeout(const Duration(seconds: 20));
        if (res.statusCode == 200) reply = jsonDecode(res.body)["choices"][0]["message"]["content"].toString();
        else throw Exception();
      } catch (_) {
        // Text-only fallback to Anthropic
        final textMessages = apiMessages.map((m) {
          if (m["content"] is List) return {"role": m["role"], "content": text.isNotEmpty ? text : "Analyze this conversation and give me the perfect reply."};
          return {"role": m["role"], "content": m["content"]};
        }).toList();
        final res = await http.post(
          Uri.parse("https://api.anthropic.com/v1/messages"),
          headers: {"Content-Type": "application/json", "x-api-key": _anthropicKey, "anthropic-version": "2023-06-01"},
          body: jsonEncode({"model": "claude-sonnet-4-5", "max_tokens": 200, "system": _systemPrompt, "messages": textMessages}),
        ).timeout(const Duration(seconds: 20));
        if (res.statusCode == 200) reply = jsonDecode(res.body)["content"][0]["text"].toString();
        else throw Exception();
      }

      if (reply != null && mounted) {
        setState(() {
          _messages.add({"role": "assistant", "content": _cleanReply(reply!), "time": _getTime()});
          _loading = false;
        });
        _scrollToBottom();
      }
    } catch (e) {
      if (mounted) setState(() {
        _messages.add({"role": "assistant", "content": _errorMessage, "time": _getTime()});
        _loading = false;
      });
    }
  }

  String get _errorMessage {
    switch (appLang.languageCode) {
      case 'de': return "Verbindungsfehler. Bitte versuche es erneut.";
      case 'es': return "Error de conexión. Inténtalo de nuevo.";
      case 'pt': return "Erro de conexão. Tenta novamente.";
      default:   return "Connection error. Please try again.";
    }
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 150), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(_scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
      }
    });
  }

  void _copyMessage(String text) {
    Clipboard.setData(ClipboardData(text: text));
    HapticFeedback.lightImpact();
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(appLang.resultCopied),
      duration: const Duration(seconds: 1),
      backgroundColor: const Color(0xFF34C759),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))));
  }

  List<String> get _quickSuggestions {
    switch (appLang.languageCode) {
      case 'de': return ["Sie antwortet mit 'ok'", "Gespräch eingeschlafen", "Sie hat mich ghostet", "Wie lade ich sie ein?"];
      case 'es': return ["Respondió con 'ok'", "Conversación fría", "Me dejó en visto", "¿Cómo la invito?"];
      case 'pt': return ["Ela respondeu 'ok'", "Conversa esfriou", "Ela deixou a ver", "Como a convido?"];
      default:   return ["She replied 'ok'", "Conversation went cold", "She left me on read", "How do I ask her out?"];
    }
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder(
      valueListenable: appLangNotifier,
      builder: (_, lang, __) {
        return Scaffold(
          backgroundColor: _bg,
          appBar: AppBar(
            backgroundColor: _bg, elevation: 0,
            leading: IconButton(
              icon: Icon(Icons.arrow_back_ios_rounded, color: _textPrimary, size: 20),
              onPressed: () => Navigator.pop(context)),
            title: Row(children: [
              Container(
                width: 36, height: 36,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(colors: [_accent, _accentDark]),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [BoxShadow(color: _accent.withOpacity(0.35), blurRadius: 8, offset: const Offset(0, 3))]),
                child: const Center(child: Text('🌶️', style: TextStyle(fontSize: 18)))),
              const SizedBox(width: 10),
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('UpCrush AI',
                  style: TextStyle(color: _textPrimary, fontSize: 15, fontWeight: FontWeight.w800)),
                Row(children: [
                  Container(width: 6, height: 6,
                    decoration: const BoxDecoration(color: Color(0xFF34C759), shape: BoxShape.circle)),
                  const SizedBox(width: 4),
                  Text('Online',
                    style: const TextStyle(color: Color(0xFF34C759), fontSize: 11, fontWeight: FontWeight.w600)),
                ]),
              ]),
            ]),
            actions: [
              IconButton(
                icon: Icon(Icons.refresh_rounded, color: _textSecondary, size: 22),
                onPressed: () => setState(() {
                  _messages.clear();
                  _messages.add({"role": "assistant", "content": _welcomeMessage, "time": _getTime()});
                })),
            ],
          ),
          body: Column(children: [
            Expanded(
              child: ListView.builder(
                controller: _scrollController,
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                itemCount: _messages.length + (_loading ? 1 : 0),
                itemBuilder: (context, index) {
                  if (index == _messages.length) return _buildTyping();
                  final msg = _messages[index];
                  return _buildBubble(
                    msg["content"] as String,
                    msg["role"] == "user",
                    msg["time"] as String? ?? '',
                    msg["image"] as String?,
                  );
                },
              ),
            ),
            if (_messages.length == 1) _buildQuickSuggestions(lang),
            _buildInput(lang),
          ]),
        );
      },
    );
  }

  Widget _buildBubble(String content, bool isUser, String time, String? imagePath) {
    return GestureDetector(
      onLongPress: () => _copyMessage(content),
      child: Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Row(
          mainAxisAlignment: isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            if (!isUser) ...[
              Container(
                width: 32, height: 32,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(colors: [_accent, _accentDark]),
                  borderRadius: BorderRadius.circular(10)),
                child: const Center(child: Text('🌶️', style: TextStyle(fontSize: 15)))),
              const SizedBox(width: 8),
            ],
            Flexible(
              child: Container(
                constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.78),
                padding: const EdgeInsets.fromLTRB(14, 10, 14, 8),
                decoration: BoxDecoration(
                  color: isUser ? _accent : _bubbleAI,
                  borderRadius: BorderRadius.only(
                    topLeft: const Radius.circular(20),
                    topRight: const Radius.circular(20),
                    bottomLeft: Radius.circular(isUser ? 20 : 4),
                    bottomRight: Radius.circular(isUser ? 4 : 20)),
                  border: isUser ? null : Border.all(
                    color: _dark ? Colors.white.withOpacity(0.08) : Colors.black.withOpacity(0.06)),
                  boxShadow: [BoxShadow(
                    color: isUser ? _accent.withOpacity(0.25) : Colors.black.withOpacity(0.06),
                    blurRadius: 8, offset: const Offset(0, 3))]),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (!isUser)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: Text('UpCrush AI',
                          style: TextStyle(color: _accent, fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 0.3))),
                    if (imagePath != null) ...[
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.file(File(imagePath), width: 180, height: 120, fit: BoxFit.cover)),
                      const SizedBox(height: 6),
                    ],
                    if (content.isNotEmpty && content != '[Imagem anexada]' && content != '[Image attached]' && content != '[Bild angehängt]')
                      Text(content,
                        style: TextStyle(color: isUser ? Colors.white : _textPrimary, fontSize: 14, height: 1.5)),
                    const SizedBox(height: 4),
                    Align(
                      alignment: Alignment.bottomRight,
                      child: Row(mainAxisSize: MainAxisSize.min, children: [
                        Text(time, style: TextStyle(
                          color: isUser ? Colors.white.withOpacity(0.6) : _textSecondary, fontSize: 10)),
                        if (isUser) ...[
                          const SizedBox(width: 3),
                          Icon(Icons.done_all_rounded, size: 13, color: Colors.white.withOpacity(0.7)),
                        ],
                      ])),
                  ],
                ),
              ),
            ),
            if (isUser) const SizedBox(width: 8),
          ],
        ),
      ),
    );
  }

  Widget _buildTyping() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
        Container(
          width: 32, height: 32,
          decoration: BoxDecoration(
            gradient: const LinearGradient(colors: [_accent, _accentDark]),
            borderRadius: BorderRadius.circular(10)),
          child: const Center(child: Text('🌶️', style: TextStyle(fontSize: 15)))),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: _bubbleAI,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(20), topRight: Radius.circular(20),
              bottomRight: Radius.circular(20), bottomLeft: Radius.circular(4)),
            border: Border.all(
              color: _dark ? Colors.white.withOpacity(0.08) : Colors.black.withOpacity(0.06))),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            _dot(0), const SizedBox(width: 5),
            _dot(200), const SizedBox(width: 5),
            _dot(400),
          ])),
      ]),
    );
  }

  Widget _dot(int delayMs) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.3, end: 1.0),
      duration: Duration(milliseconds: 500 + delayMs),
      curve: Curves.easeInOut,
      builder: (_, val, __) => Container(
        width: 7, height: 7,
        decoration: BoxDecoration(color: _accent.withOpacity(val), shape: BoxShape.circle)));
  }

  Widget _buildQuickSuggestions(lang) {
    return Container(
      height: 50, color: _bg,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
        itemCount: _quickSuggestions.length,
        itemBuilder: (_, i) => GestureDetector(
          onTap: () { _controller.text = _quickSuggestions[i]; _sendMessage(); },
          child: Container(
            margin: const EdgeInsets.only(right: 8),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            decoration: BoxDecoration(
              color: _accent.withOpacity(0.08),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: _accent.withOpacity(0.25))),
            child: Text(_quickSuggestions[i],
              style: TextStyle(color: _accent, fontSize: 13, fontWeight: FontWeight.w600))))));
  }

  Widget _buildInput(lang) {
    final hintText = lang.languageCode == 'de' ? "Situation beschreiben..."
      : lang.languageCode == 'es' ? "Describe la situación..."
      : lang.languageCode == 'pt' ? "Descreve a situação..."
      : "Describe the situation...";

    return Container(
      padding: EdgeInsets.fromLTRB(12, 6, 12, MediaQuery.of(context).padding.bottom + 10),
      decoration: BoxDecoration(
        color: _bg,
        border: Border(top: BorderSide(
          color: _dark ? Colors.white.withOpacity(0.06) : Colors.black.withOpacity(0.06)))),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        // Image preview
        if (_imagemAnexada != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Stack(children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.file(_imagemAnexada!, width: 80, height: 80, fit: BoxFit.cover)),
              Positioned(top: 2, right: 2,
                child: GestureDetector(
                  onTap: _removeImage,
                  child: Container(
                    width: 20, height: 20,
                    decoration: const BoxDecoration(color: Colors.black54, shape: BoxShape.circle),
                    child: const Icon(Icons.close, color: Colors.white, size: 13)))),
            ])),
        Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
          // Photo button
          GestureDetector(
            onTap: _pickImage,
            child: Container(
              width: 44, height: 44,
              decoration: BoxDecoration(
                color: _accent.withOpacity(0.1),
                borderRadius: BorderRadius.circular(22),
                border: Border.all(color: _accent.withOpacity(0.2))),
              child: Icon(Icons.image_outlined, color: _accent, size: 20))),
          const SizedBox(width: 8),
          // Text field
          Expanded(
            child: Container(
              constraints: const BoxConstraints(maxHeight: 120),
              decoration: BoxDecoration(
                color: _inputBg,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: _dark ? Colors.white.withOpacity(0.1) : Colors.black.withOpacity(0.08)),
                boxShadow: _dark ? [] : [
                  BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 2))]),
              child: TextField(
                controller: _controller,
                maxLines: null,
                style: TextStyle(color: _textPrimary, fontSize: 14),
                textInputAction: TextInputAction.send,
                onSubmitted: (_) => _sendMessage(),
                decoration: InputDecoration(
                  hintText: hintText,
                  hintStyle: TextStyle(color: _textSecondary, fontSize: 14),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12))))),
          const SizedBox(width: 8),
          // Send button
          GestureDetector(
            onTap: _sendMessage,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              width: 46, height: 46,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: _loading
                    ? [_accent.withOpacity(0.5), _accentDark.withOpacity(0.5)]
                    : [_accent, _accentDark]),
                shape: BoxShape.circle,
                boxShadow: _loading ? [] : [
                  BoxShadow(color: _accent.withOpacity(0.4), blurRadius: 10, offset: const Offset(0, 4))]),
              child: _loading
                ? const Padding(padding: EdgeInsets.all(12),
                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                : const Icon(Icons.send_rounded, color: Colors.white, size: 20))),
        ]),
      ]),
    );
  }
}