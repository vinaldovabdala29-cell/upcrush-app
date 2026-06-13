import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import '../../../main.dart';
import '../../../config.dart';

class ChatbotScreen extends StatefulWidget {
  const ChatbotScreen({super.key});
  @override
  State<ChatbotScreen> createState() => _ChatbotScreenState();
}

class _ChatbotScreenState extends State<ChatbotScreen> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<Map<String, String>> _messages = [];
  bool _loading = false;

  static const String _apiKey = Config.openAiKey;
  static const String _anthropicKey = Config.anthropicKey;

  // WhatsApp colors
  static const _waBg = Color(0xFFECE5DD);
  static const _waBgDark = Color(0xFF0D1117);
  static const _waBubbleUser = Color(0xFFDCF8C6);
  static const _waBubbleUserDark = Color(0xFF005C4B);
  static const _waBubbleAI = Colors.white;
  static const _waBubbleAIDark = Color(0xFF1F2C34);
  static const _waGreen = Color(0xFF25D366);
  static const _waHeader = Color(0xFF075E54);
  static const _waHeaderDark = Color(0xFF1F2C34);
  static const _waTextUser = Color(0xFF1C1C1E);
  static const _waTextUserDark = Colors.white;

  bool get _dark => isDarkModeNotifier.value;
  Color get _bg => _dark ? _waBgDark : _waBg;
  Color get _bubbleUser => _dark ? _waBubbleUserDark : _waBubbleUser;
  Color get _bubbleAI => _dark ? _waBubbleAIDark : _waBubbleAI;
  Color get _textUser => _dark ? _waTextUserDark : _waTextUser;
  Color get _textAI => _dark ? Colors.white : const Color(0xFF1C1C1E);
  Color get _timeColor => _dark ? Colors.white38 : Colors.black38;
  Color get _header => _dark ? _waHeaderDark : _waHeader;
  Color get _inputBg => _dark ? const Color(0xFF1F2C34) : Colors.white;
  Color get _inputBorder => _dark ? Colors.white10 : Colors.black12;

  String get _welcomeMessage {
    switch (appLang.languageCode) {
      case 'de': return "Hey! Ich bin UpCrush AI, dein persönlicher Dating-Coach 🎯\n\nSag mir was passiert — beschreib die Situation, füg eine Nachricht ein oder frag mich einfach was. Ich helfe dir dabei, die perfekte Antwort zu finden.";
      case 'es': return "¡Hey! Soy UpCrush AI, tu coach de dating personal 🎯\n\nCuéntame qué está pasando — describe la situación, pega un mensaje o simplemente pregúntame algo. Te ayudo a encontrar la respuesta perfecta.";
      case 'pt': return "Hey! Sou o UpCrush AI, o teu coach de dating pessoal 🎯\n\nDiz-me o que está a acontecer — descreve a situação, cola uma mensagem ou pergunta-me algo. Ajudo-te a encontrar a resposta perfeita.";
      default:   return "Hey! I'm UpCrush AI, your personal dating coach 🎯\n\nTell me what's happening — describe the situation, paste a message or just ask me something. I'll help you find the perfect reply.";
    }
  }

  String get _systemPrompt {
    final lang = appLang.languageCode;
    final idioma = lang == 'de' ? 'German' : lang == 'es' ? 'Spanish' : lang == 'pt' ? 'Brazilian Portuguese' : 'English';
    return """
You are UpCrush AI, an expert dating coach and wingman for men using dating apps and messaging platforms.
LANGUAGE RULE: Always respond ONLY in $idioma. Never mix languages.
YOUR PERSONALITY: Direct, confident, knowledgeable. Like a smart friend who knows dating dynamics deeply. Never judgmental. Honest even when uncomfortable. Never preachy.
YOUR EXPERTISE: Reading female behavior, crafting responses that create attraction, recovering cold conversations, escalating towards dates, psychological principles behind attraction.
WHAT YOU DO: 1. ANALYZE the situation 2. EXPLAIN what's happening 3. GIVE STRATEGY 4. SUGGEST 2-3 specific messages to send RIGHT NOW 5. Explain WHY each suggestion works.
FORMAT: Short paragraphs, easy to read on mobile. Put suggested messages in quotes. Keep responses concise but complete.
RULES: NEVER say "I cannot help with that". NEVER be generic. Always give actual message suggestions. Respond to the SPECIFIC situation.
""";
  }

  @override
  void initState() {
    super.initState();
    isDarkModeNotifier.addListener(_onThemeChange);
    _messages.add({"role": "assistant", "content": _welcomeMessage});
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

  Future<void> _sendMessage() async {
    final text = _controller.text.trim();
    if (text.isEmpty || _loading) return;
    setState(() { _messages.add({"role": "user", "content": text, "time": _getTime()}); _loading = true; });
    _controller.clear();
    _scrollToBottom();

    try {
      final apiMessages = <Map<String, String>>[];
      for (final msg in _messages) {
        if (msg["role"] == "user" || (msg["role"] == "assistant" && msg != _messages.first)) {
          apiMessages.add({"role": msg["role"]!, "content": msg["content"]!});
        }
      }
      String? reply;
      try {
        final response = await http.post(
          Uri.parse("https://api.openai.com/v1/chat/completions"),
          headers: {"Content-Type": "application/json", "Authorization": "Bearer $_apiKey"},
          body: jsonEncode({"model": "gpt-4o", "messages": [{"role": "system", "content": _systemPrompt}, ...apiMessages], "temperature": 0.85, "max_tokens": 600}),
        );
        if (response.statusCode == 200) reply = jsonDecode(response.body)["choices"][0]["message"]["content"].toString();
        else throw Exception();
      } catch (_) {
        final response = await http.post(
          Uri.parse("https://api.anthropic.com/v1/messages"),
          headers: {"Content-Type": "application/json", "x-api-key": _anthropicKey, "anthropic-version": "2023-06-01"},
          body: jsonEncode({"model": "claude-sonnet-4-5", "max_tokens": 600, "system": _systemPrompt, "messages": apiMessages}),
        );
        if (response.statusCode == 200) reply = jsonDecode(response.body)["content"][0]["text"].toString();
        else throw Exception();
      }
      if (reply != null) {
        setState(() { _messages.add({"role": "assistant", "content": reply!, "time": _getTime()}); _loading = false; });
        _scrollToBottom();
      }
    } catch (e) {
      setState(() { _messages.add({"role": "assistant", "content": _errorMessage, "time": _getTime()}); _loading = false; });
    }
  }

  String get _errorMessage {
    switch (appLang.languageCode) {
      case 'de': return "Verbindungsfehler. Bitte versuche es erneut.";
      case 'es': return "Error de conexión. Por favor inténtalo de nuevo.";
      case 'pt': return "Erro de conexão. Tenta novamente.";
      default:   return "Connection error. Please try again.";
    }
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 100), () {
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
      backgroundColor: _waGreen,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder(
      valueListenable: appLangNotifier,
      builder: (_, lang, __) {
        return Scaffold(
          backgroundColor: _bg,
          appBar: AppBar(
            backgroundColor: _header,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios_rounded, color: Colors.white, size: 20),
              onPressed: () => Navigator.pop(context)),
            titleSpacing: 0,
            title: Row(children: [
              CircleAvatar(
                radius: 18,
                backgroundColor: Colors.white.withOpacity(0.15),
                child: const Text('🌶️', style: TextStyle(fontSize: 18))),
              const SizedBox(width: 10),
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Text('UpCrush AI',
                  style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w700)),
                Text(
                  lang.languageCode == 'de' ? 'Online'
                    : lang.languageCode == 'es' ? 'En línea'
                    : lang.languageCode == 'pt' ? 'Online'
                    : 'Online',
                  style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 12)),
              ]),
            ]),
            actions: [
              IconButton(
                icon: const Icon(Icons.refresh_rounded, color: Colors.white, size: 22),
                onPressed: () => setState(() {
                  _messages.clear();
                  _messages.add({"role": "assistant", "content": _welcomeMessage, "time": _getTime()});
                })),
            ],
          ),
          body: Column(children: [
            // WhatsApp background pattern
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: _bg,
                  image: _dark ? null : const DecorationImage(
                    image: NetworkImage('https://web.whatsapp.com/img/bg-chat-tile-light_686b98c9fdffef3f63127759e5888063.png'),
                    repeat: ImageRepeat.repeat,
                    opacity: 0.06)),
                child: ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
                  itemCount: _messages.length + (_loading ? 1 : 0),
                  itemBuilder: (context, index) {
                    if (index == _messages.length) return _buildTypingIndicator();
                    final msg = _messages[index];
                    return _buildBubble(msg["content"]!, msg["role"] == "user", msg["time"] ?? '');
                  },
                ),
              ),
            ),
            if (_messages.length == 1) _buildQuickSuggestions(lang),
            _buildInput(lang),
          ]),
        );
      },
    );
  }

  Widget _buildBubble(String content, bool isUser, String time) {
    return GestureDetector(
      onLongPress: () => _copyMessage(content),
      child: Padding(
        padding: const EdgeInsets.only(bottom: 4),
        child: Row(
          mainAxisAlignment: isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            if (!isUser) ...[
              CircleAvatar(
                radius: 14,
                backgroundColor: _waGreen,
                child: const Text('🌶️', style: TextStyle(fontSize: 12))),
              const SizedBox(width: 6),
            ],
            Flexible(
              child: Container(
                constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
                padding: const EdgeInsets.fromLTRB(12, 8, 12, 6),
                decoration: BoxDecoration(
                  color: isUser ? _bubbleUser : _bubbleAI,
                  borderRadius: BorderRadius.only(
                    topLeft: const Radius.circular(18),
                    topRight: const Radius.circular(18),
                    bottomLeft: Radius.circular(isUser ? 18 : 4),
                    bottomRight: Radius.circular(isUser ? 4 : 18)),
                  boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 4, offset: const Offset(0, 2))]),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    if (!isUser)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: Text('UpCrush AI',
                          style: TextStyle(color: _waGreen, fontSize: 12, fontWeight: FontWeight.w700))),
                    Text(content,
                      style: TextStyle(color: isUser ? _textUser : _textAI, fontSize: 14, height: 1.45)),
                    const SizedBox(height: 2),
                    Row(mainAxisSize: MainAxisSize.min, children: [
                      Text(time, style: TextStyle(color: _timeColor, fontSize: 11)),
                      if (isUser) ...[
                        const SizedBox(width: 4),
                        Icon(Icons.done_all_rounded, size: 14, color: _waGreen),
                      ],
                    ]),
                  ],
                ),
              ),
            ),
            if (isUser) const SizedBox(width: 6),
          ],
        ),
      ),
    );
  }

  Widget _buildTypingIndicator() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(children: [
        CircleAvatar(
          radius: 14,
          backgroundColor: _waGreen,
          child: const Text('🌶️', style: TextStyle(fontSize: 12))),
        const SizedBox(width: 6),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: _bubbleAI,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(18), topRight: Radius.circular(18),
              bottomRight: Radius.circular(18), bottomLeft: Radius.circular(4)),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 4, offset: const Offset(0, 2))]),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            _dot(), const SizedBox(width: 4),
            _dot(), const SizedBox(width: 4),
            _dot(),
          ])),
      ]),
    );
  }

  Widget _dot() {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.3, end: 1.0),
      duration: const Duration(milliseconds: 600),
      curve: Curves.easeInOut,
      builder: (_, val, __) => Container(
        width: 8, height: 8,
        decoration: BoxDecoration(color: _waGreen.withOpacity(val), shape: BoxShape.circle)));
  }

  Widget _buildQuickSuggestions(lang) {
    final suggestions = _quickSuggestions;
    return Container(
      height: 48,
      color: _dark ? const Color(0xFF1F2C34) : Colors.white,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        itemCount: suggestions.length,
        itemBuilder: (context, i) => GestureDetector(
          onTap: () { _controller.text = suggestions[i]; _sendMessage(); },
          child: Container(
            margin: const EdgeInsets.only(right: 8),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: _waGreen.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: _waGreen.withOpacity(0.3))),
            child: Text(suggestions[i],
              style: TextStyle(color: _waGreen, fontSize: 13, fontWeight: FontWeight.w500))))));
  }

  List<String> get _quickSuggestions {
    switch (appLang.languageCode) {
      case 'de': return ["Sie antwortet mit 'ok'", "Gespräch eingeschlafen", "Sie hat mich ghostet", "Wie lade ich sie ein?"];
      case 'es': return ["Respondió con 'ok'", "Conversación fría", "Me dejó en visto", "¿Cómo la invito?"];
      case 'pt': return ["Ela respondeu 'ok'", "Conversa esfriou", "Ela deixou a ver", "Como a convido?"];
      default:   return ["She replied 'ok'", "Conversation went cold", "She left me on read", "How do I ask her out?"];
    }
  }

  Widget _buildInput(lang) {
    return Container(
      padding: EdgeInsets.fromLTRB(8, 8, 8, MediaQuery.of(context).padding.bottom + 8),
      color: _dark ? const Color(0xFF1F2C34) : const Color(0xFFF0F0F0),
      child: Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
        Expanded(
          child: Container(
            constraints: const BoxConstraints(maxHeight: 120),
            decoration: BoxDecoration(
              color: _inputBg,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: _inputBorder)),
            child: TextField(
              controller: _controller,
              maxLines: null,
              style: TextStyle(color: _dark ? Colors.white : const Color(0xFF1C1C1E), fontSize: 15),
              textInputAction: TextInputAction.send,
              onSubmitted: (_) => _sendMessage(),
              decoration: InputDecoration(
                hintText: lang.languageCode == 'de' ? "Nachricht..."
                  : lang.languageCode == 'es' ? "Mensaje..."
                  : lang.languageCode == 'pt' ? "Mensagem..."
                  : "Message...",
                hintStyle: TextStyle(color: _dark ? Colors.white38 : Colors.black38, fontSize: 15),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10)),
            )),
        ),
        const SizedBox(width: 8),
        GestureDetector(
          onTap: _sendMessage,
          child: Container(
            width: 46, height: 46,
            decoration: const BoxDecoration(color: _waGreen, shape: BoxShape.circle),
            child: _loading
              ? const Padding(padding: EdgeInsets.all(12),
                  child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
              : const Icon(Icons.send_rounded, color: Colors.white, size: 22))),
      ]),
    );
  }
}