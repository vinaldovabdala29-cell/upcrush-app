import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import '../../../main.dart';
import '../../../config.dart';
import '../services/credits_service.dart';
import '../widgets/paywall_screen.dart';

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

  bool get _dark => isDarkModeNotifier.value;
  Color get _bg => _dark ? const Color(0xFF0A0A10) : const Color(0xFFF2F2F7);
  Color get _cardBg => _dark ? Colors.white.withOpacity(0.06) : Colors.white.withOpacity(0.75);
  Color get _cardBorder => _dark ? Colors.white.withOpacity(0.07) : Colors.white.withOpacity(0.9);
  Color get _textPrimary => _dark ? Colors.white : const Color(0xFF1C1C1E);
  Color get _textSecondary => _dark ? Colors.white54 : Colors.black45;
  static const _accent = Color(0xFFFF2D55);

  // Mensagens de boas vindas por idioma
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
You are UpCrush AI, an expert dating coach and wingman for men using dating apps and messaging platforms (WhatsApp, Tinder, Bumble, Hinge, Instagram DM, etc.).

LANGUAGE RULE — CRITICAL:
Always respond ONLY in $idioma. Never mix languages.

YOUR PERSONALITY:
- Direct, confident, and knowledgeable
- Like a smart friend who knows dating dynamics deeply
- Never judgmental — always supportive
- Honest even when the truth is uncomfortable
- Never preachy or moralistic

YOUR EXPERTISE:
- Reading female behavior and interest levels
- Crafting responses that create attraction
- Recovering cold conversations
- Escalating towards dates
- Understanding red flags and green flags
- Psychological principles behind attraction

WHAT YOU DO:
1. ANALYZE the situation the user describes
2. EXPLAIN what's happening (why she responded that way, what it means)
3. GIVE STRATEGY (what to do and why)
4. SUGGEST 2-3 specific messages they can send RIGHT NOW
5. Explain WHY each suggestion works

FORMAT YOUR RESPONSES:
- Use short paragraphs, easy to read on mobile
- Use emojis sparingly but effectively
- Put suggested messages in quotes like: "mensagem aqui"
- Keep responses concise but complete — not too long

RULES:
- NEVER say "I cannot help with that"
- NEVER be generic — give specific, actionable advice
- Always give actual message suggestions when relevant
- Respond to the SPECIFIC situation, not generic advice
- If they paste a conversation, analyze it thoroughly
""";
  }

  @override
  void initState() {
    super.initState();
    // Mensagem de boas-vindas
    _messages.add({"role": "assistant", "content": _welcomeMessage});
  }

  Future<void> _sendMessage() async {
    final text = _controller.text.trim();
    if (text.isEmpty || _loading) return;

    // ── CHATBOT: 3 mensagens grátis, paywall na 4ª ──────────────────────
    final podeUsar = await CreditsService.canUseChat();
    if (!podeUsar) {
      if (mounted) {
        await Navigator.push(context, MaterialPageRoute(
          fullscreenDialog: true,
          builder: (_) => const PaywallFlow(),
        ));
        final isPremium = await CreditsService.isPremium();
        if (!isPremium) return;
      } else {
        return;
      }
    }
    await CreditsService.useChatCredit();

    setState(() {
      _messages.add({"role": "user", "content": text});
      _loading = true;
    });
    _controller.clear();
    _scrollToBottom();

    try {
      // Constrói histórico para a API (exclui mensagem de boas-vindas do sistema)
      final apiMessages = <Map<String, String>>[];
      for (final msg in _messages) {
        if (msg["role"] == "user" || (msg["role"] == "assistant" && msg != _messages.first)) {
          apiMessages.add({"role": msg["role"]!, "content": msg["content"]!});
        }
      }

      final response = await http.post(
        Uri.parse("https://api.openai.com/v1/chat/completions"),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $_apiKey",
        },
        body: jsonEncode({
          "model": "gpt-4o",
          "messages": [
            {"role": "system", "content": _systemPrompt},
            ...apiMessages,
          ],
          "temperature": 0.85,
          "max_tokens": 600,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final reply = data["choices"][0]["message"]["content"].toString();
        setState(() {
          _messages.add({"role": "assistant", "content": reply});
          _loading = false;
        });
        _scrollToBottom();
      } else {
        throw Exception("Error ${response.statusCode}");
      }
    } catch (e) {
      setState(() {
        _messages.add({"role": "assistant", "content": _errorMessage});
        _loading = false;
      });
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
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _copyMessage(String text) {
    Clipboard.setData(ClipboardData(text: text));
    HapticFeedback.lightImpact();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(appLang.resultCopied),
        duration: const Duration(seconds: 1),
        backgroundColor: const Color(0xFF34C759),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder(
      valueListenable: appLangNotifier,
      builder: (_, lang, __) {
        return Scaffold(
          backgroundColor: _bg,
          appBar: AppBar(
            backgroundColor: _bg,
            elevation: 0,
            leading: IconButton(
              icon: Icon(Icons.arrow_back_ios_rounded, color: _textPrimary, size: 20),
              onPressed: () => Navigator.pop(context),
            ),
            title: Row(
              children: [
                Container(
                  width: 34, height: 34,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFFFF2D55), Color(0xFFFF6B81)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: [BoxShadow(
                        color: const Color(0xFFFF2D55).withOpacity(0.3),
                        blurRadius: 8, offset: const Offset(0, 3))],
                  ),
                  child: const Icon(Icons.auto_awesome_rounded, color: Colors.white, size: 18),
                ),
                const SizedBox(width: 10),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("UpCrush AI",
                        style: TextStyle(color: _textPrimary,
                            fontWeight: FontWeight.w700, fontSize: 15)),
                    Text(
                      lang.languageCode == 'de' ? "Online • Bereit zu helfen"
                          : lang.languageCode == 'es' ? "Online • Listo para ayudar"
                          : lang.languageCode == 'pt' ? "Online • Pronto para ajudar"
                          : "Online • Ready to help",
                      style: const TextStyle(color: Color(0xFF34C759),
                          fontSize: 11, fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
              ],
            ),
            actions: [
              IconButton(
                icon: Icon(Icons.refresh_rounded, color: _textSecondary, size: 22),
                onPressed: () {
                  setState(() {
                    _messages.clear();
                    _messages.add({"role": "assistant", "content": _welcomeMessage});
                  });
                },
              ),
            ],
          ),
          body: Column(
            children: [
              Expanded(
                child: ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                  itemCount: _messages.length + (_loading ? 1 : 0),
                  itemBuilder: (context, index) {
                    if (index == _messages.length) return _buildTypingIndicator();
                    final msg = _messages[index];
                    final isUser = msg["role"] == "user";
                    return _buildMessage(msg["content"]!, isUser);
                  },
                ),
              ),
              if (_messages.length == 1) _buildQuickSuggestions(lang),
              _buildInput(lang),
            ],
          ),
        );
      },
    );
  }

  // ─── MENSAGEM ────────────────────────────────────────────────────────────
  Widget _buildMessage(String content, bool isUser) {
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
                width: 28, height: 28,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(colors: [Color(0xFFFF2D55), Color(0xFFFF6B81)]),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.auto_awesome_rounded, color: Colors.white, size: 14),
              ),
              const SizedBox(width: 8),
            ],
            Flexible(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                decoration: BoxDecoration(
                  color: isUser ? _accent : _cardBg,
                  borderRadius: BorderRadius.only(
                    topLeft: const Radius.circular(18),
                    topRight: const Radius.circular(18),
                    bottomLeft: Radius.circular(isUser ? 18 : 4),
                    bottomRight: Radius.circular(isUser ? 4 : 18),
                  ),
                  border: isUser ? null : Border.all(color: _cardBorder),
                  boxShadow: isUser
                      ? [BoxShadow(color: _accent.withOpacity(0.3), blurRadius: 8, offset: const Offset(0, 3))]
                      : _dark ? [] : [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 2))],
                ),
                child: Text(
                  content,
                  style: TextStyle(
                    color: isUser ? Colors.white : _textPrimary,
                    fontSize: 14,
                    height: 1.5,
                  ),
                ),
              ),
            ),
            if (isUser) const SizedBox(width: 8),
          ],
        ),
      ),
    );
  }

  // ─── TYPING INDICATOR ────────────────────────────────────────────────────
  Widget _buildTypingIndicator() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(
            width: 28, height: 28,
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [Color(0xFFFF2D55), Color(0xFFFF6B81)]),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.auto_awesome_rounded, color: Colors.white, size: 14),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: _cardBg,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(18),
                topRight: Radius.circular(18),
                bottomRight: Radius.circular(18),
                bottomLeft: Radius.circular(4),
              ),
              border: Border.all(color: _cardBorder),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _dot(0),
                const SizedBox(width: 4),
                _dot(150),
                const SizedBox(width: 4),
                _dot(300),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _dot(int delayMs) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.4, end: 1.0),
      duration: const Duration(milliseconds: 600),
      curve: Curves.easeInOut,
      builder: (_, val, __) => Container(
        width: 7, height: 7,
        decoration: BoxDecoration(
          color: _accent.withOpacity(val),
          shape: BoxShape.circle,
        ),
      ),
    );
  }

  // ─── SUGESTÕES RÁPIDAS ───────────────────────────────────────────────────
  Widget _buildQuickSuggestions(lang) {
    final suggestions = _quickSuggestions;
    return SizedBox(
      height: 44,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: suggestions.length,
        itemBuilder: (context, i) {
          return GestureDetector(
            onTap: () {
              _controller.text = _quickSuggestions[i];
              _sendMessage();
            },
            child: Container(
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: _cardBg,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: _cardBorder),
              ),
              child: Text(
                suggestions[i],
                style: TextStyle(color: _textPrimary, fontSize: 13, fontWeight: FontWeight.w500),
              ),
            ),
          );
        },
      ),
    );
  }

  List<String> get _quickSuggestions {
    switch (appLang.languageCode) {
      case 'de': return ["Sie antwortet mit 'ok'", "Gespräch ist eingeschlafen", "Sie hat mich ghostet", "Wie lade ich sie ein?"];
      case 'es': return ["Respondió con 'ok'", "La conversación se enfrió", "Me dejó en visto", "¿Cómo la invito?"];
      case 'pt': return ["Ela respondeu 'ok'", "Conversa esfriou", "Ela deixou a ver", "Como a convido?"];
      default:   return ["She replied 'ok'", "Conversation went cold", "She left me on read", "How do I ask her out?"];
    }
  }

  // ─── INPUT ───────────────────────────────────────────────────────────────
  Widget _buildInput(lang) {
    return Container(
      padding: EdgeInsets.fromLTRB(16, 10, 16, MediaQuery.of(context).padding.bottom + 12),
      decoration: BoxDecoration(
        color: _bg,
        border: Border(top: BorderSide(color: _cardBorder, width: 0.5)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: Container(
              constraints: const BoxConstraints(maxHeight: 120),
              decoration: BoxDecoration(
                color: _cardBg,
                borderRadius: BorderRadius.circular(22),
                border: Border.all(color: _cardBorder),
                boxShadow: _dark ? [] : [
                  BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 2)),
                ],
              ),
              child: TextField(
                controller: _controller,
                maxLines: null,
                style: TextStyle(color: _textPrimary, fontSize: 14),
                textInputAction: TextInputAction.send,
                onSubmitted: (_) => _sendMessage(),
                decoration: InputDecoration(
                  hintText: lang.languageCode == 'de' ? "Beschreib die Situation..."
                      : lang.languageCode == 'es' ? "Describe la situación..."
                      : lang.languageCode == 'pt' ? "Descreve a situação..."
                      : "Describe the situation...",
                  hintStyle: TextStyle(color: _textSecondary, fontSize: 14),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          GestureDetector(
            onTap: _sendMessage,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 46, height: 46,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFFF2D55), Color(0xFFFF6B81)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                shape: BoxShape.circle,
                boxShadow: [BoxShadow(color: const Color(0xFFFF2D55).withOpacity(0.35), blurRadius: 10, offset: const Offset(0, 4))],
              ),
              child: _loading
                  ? const Padding(
                      padding: EdgeInsets.all(12),
                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                    )
                  : const Icon(Icons.send_rounded, color: Colors.white, size: 20),
            ),
          ),
        ],
      ),
    );
  }

}