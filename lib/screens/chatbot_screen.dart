import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';

import '../main.dart';
import '../services/review_request_service.dart';
import '../models/coach_models.dart';
import '../services/dating_coach_service.dart';
import '../services/coach_history_service.dart';

typedef CoachReply =
    Future<CoachResponse> Function({
      required List<CoachMessage> messages,
      required String lang,
      required CoachPersonality personality,
      String? base64Image,
    });

class ChatbotScreen extends StatefulWidget {
  final bool embedded;
  final CoachReply? reply;

  const ChatbotScreen({super.key, this.embedded = false, this.reply});

  @override
  State<ChatbotScreen> createState() => _ChatbotScreenState();
}

class _ChatbotScreenState extends State<ChatbotScreen> {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  bool _inputFocused = false;
  final ScrollController _scrollController = ScrollController();
  final ImagePicker _imagePicker = ImagePicker();

  final List<CoachHistoryMessage> _messages = [];
  final List<CoachMessage> _history = [];
  final Map<String, CoachResponse> _responses = {};

  CoachConversation? _conversation;
  List<CoachConversation> _allConversations = [];

  bool _loading = false;
  CoachPersonality _personality = CoachPersonality.neutro;

  File? _pendingImage;
  String? _pendingBase64;

  static const Color _accent = Color(0xFFFF2D55);

  bool get _dark => isDarkModeNotifier.value;

  // Cores estilo ChatGPT — limpo, poucas camadas
  Color get _bg => _dark ? const Color(0xFF0E0E12) : Colors.white;
  Color get _bubbleUser =>
      _dark ? const Color(0xFF2A2A32) : const Color(0xFFF0F0F2);
  Color get _textPrimary =>
      _dark ? const Color(0xFFECECF1) : const Color(0xFF1A1A1E);
  Color get _textSecondary => _dark ? Colors.white38 : Colors.black38;
  Color get _inputBg =>
      _dark ? const Color(0xFF1C1C22) : const Color(0xFFF5F5F7);
  Color get _sidebarBg =>
      _dark ? const Color(0xFF090909) : const Color(0xFFF9F9FA);

  @override
  void initState() {
    super.initState();
    isDarkModeNotifier.addListener(_themeChanged);
    _focusNode.addListener(_onFocusChange);
    _startNewConversation();
    _loadAllConversations();
  }

  @override
  void dispose() {
    isDarkModeNotifier.removeListener(_themeChanged);
    _focusNode.removeListener(_onFocusChange);
    _focusNode.dispose();
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _themeChanged() {
    if (mounted) setState(() {});
  }

  void _onFocusChange() {
    if (mounted) setState(() => _inputFocused = _focusNode.hasFocus);
  }

  Future<void> _loadAllConversations() async {
    final list = await CoachHistoryService.loadAll();
    if (mounted) setState(() => _allConversations = list);
  }

  void _startNewConversation() {
    if (_loading) return;
    final now = DateTime.now();
    _conversation = CoachConversation(
      id: now.microsecondsSinceEpoch.toString(),
      title: _newConversationTitle,
      createdAt: now,
      updatedAt: now,
      messages: [],
    );
    _messages.clear();
    _history.clear();
    _responses.clear();
  }

  String get _newConversationTitle {
    switch (appLang.languageCode) {
      case 'pt':
        return 'Nova conversa';
      case 'de':
        return 'Neue Unterhaltung';
      case 'es':
        return 'Nueva conversación';
      default:
        return 'New conversation';
    }
  }

  // ===============================================================
  // HISTORY DRAWER
  // ===============================================================

  void _openHistory() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => DraggableScrollableSheet(
        initialChildSize: 0.75,
        minChildSize: 0.4,
        maxChildSize: 0.92,
        builder: (context, scrollCtrl) => Container(
          decoration: BoxDecoration(
            color: _sidebarBg,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            children: [
              const SizedBox(height: 10),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 16),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  children: [
                    Text(
                      _historyTitle,
                      style: TextStyle(
                        color: _textPrimary,
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const Spacer(),
                    GestureDetector(
                      onTap: () {
                        Navigator.pop(context);
                        _startFreshChat();
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: _accent.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.add_rounded,
                              color: _accent,
                              size: 16,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              _newLabel,
                              style: const TextStyle(
                                color: _accent,
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              Expanded(
                child: _allConversations.isEmpty
                    ? Center(
                        child: Text(
                          _noHistoryLabel,
                          style: TextStyle(color: _textSecondary, fontSize: 14),
                        ),
                      )
                    : ListView.builder(
                        controller: scrollCtrl,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 4,
                        ),
                        itemCount: _allConversations.length,
                        itemBuilder: (context, index) {
                          final conv = _allConversations[index];
                          final isCurrent = conv.id == _conversation?.id;
                          return Dismissible(
                            key: ValueKey(conv.id),
                            direction: DismissDirection.endToStart,
                            background: Container(
                              alignment: Alignment.centerRight,
                              padding: const EdgeInsets.only(right: 20),
                              decoration: BoxDecoration(
                                color: Colors.red.withOpacity(0.15),
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: const Icon(
                                Icons.delete_rounded,
                                color: Colors.red,
                              ),
                            ),
                            onDismissed: (_) async {
                              await CoachHistoryService.delete(conv.id);
                              _loadAllConversations();
                            },
                            child: GestureDetector(
                              onTap: () {
                                Navigator.pop(context);
                                _openConversation(conv);
                              },
                              child: Container(
                                margin: const EdgeInsets.symmetric(vertical: 4),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 14,
                                  vertical: 12,
                                ),
                                decoration: BoxDecoration(
                                  color: isCurrent
                                      ? _accent.withOpacity(0.08)
                                      : Colors.transparent,
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.chat_bubble_outline_rounded,
                                      color: isCurrent
                                          ? _accent
                                          : _textSecondary,
                                      size: 17,
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Text(
                                        conv.title,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                          color: isCurrent
                                              ? _accent
                                              : _textPrimary,
                                          fontSize: 14.5,
                                          fontWeight: isCurrent
                                              ? FontWeight.w700
                                              : FontWeight.w500,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      ),
              ),
              SizedBox(height: MediaQuery.of(context).padding.bottom + 12),
            ],
          ),
        ),
      ),
    );
  }

  void _openConversation(CoachConversation conv) {
    if (_loading) return;
    setState(() {
      _conversation = conv;
      _messages.clear();
      _messages.addAll(conv.messages);
      _history.clear();
      _responses.clear();
      // Reconstrói o histórico completo enviado à IA — assim ela
      // "lembra-se" de tudo o que já foi falado nesta conversa,
      // não só da última mensagem.
      for (final m in conv.messages) {
        if (m.role == 'user') {
          _history.add(CoachMessage.user(m.content));
        } else if (m.role == 'assistant') {
          final data = m.responseData;
          if (data != null) {
            final response = CoachResponse.fromJson(data);
            _responses[m.id] = response;
            _history.add(CoachMessage.assistant(response.toHistoryText()));
          } else {
            _history.add(CoachMessage.assistant(m.content));
          }
        }
      }
    });
    _scrollToBottom();
  }

  void _startFreshChat() {
    setState(() => _startNewConversation());
  }

  String get _historyTitle {
    switch (appLang.languageCode) {
      case 'pt':
        return 'Conversas';
      case 'de':
        return 'Unterhaltungen';
      case 'es':
        return 'Conversaciones';
      default:
        return 'Conversations';
    }
  }

  String get _newLabel {
    switch (appLang.languageCode) {
      case 'pt':
        return 'Nova';
      case 'de':
        return 'Neu';
      case 'es':
        return 'Nueva';
      default:
        return 'New';
    }
  }

  String get _noHistoryLabel {
    switch (appLang.languageCode) {
      case 'pt':
        return 'Ainda não tens conversas';
      case 'de':
        return 'Noch keine Unterhaltungen';
      case 'es':
        return 'Aún no tienes conversaciones';
      default:
        return 'No conversations yet';
    }
  }

  // ===============================================================
  // IMAGE
  // ===============================================================

  Future<void> _chooseImage() async {
    await showModalBottomSheet(
      context: context,
      backgroundColor: _bg,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _attachmentOption(
                Icons.photo_library_outlined,
                _galleryLabel,
                () {
                  Navigator.pop(context);
                  _pickImage(ImageSource.gallery);
                },
              ),
              const SizedBox(height: 6),
              _attachmentOption(Icons.camera_alt_outlined, _cameraLabel, () {
                Navigator.pop(context);
                _pickImage(ImageSource.camera);
              }),
            ],
          ),
        ),
      ),
    );
  }

  Widget _attachmentOption(IconData icon, String title, VoidCallback onTap) {
    return ListTile(
      onTap: onTap,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      leading: Icon(icon, color: _textPrimary),
      title: Text(
        title,
        style: TextStyle(color: _textPrimary, fontWeight: FontWeight.w600),
      ),
    );
  }

  Future<void> _pickImage(ImageSource source) async {
    final image = await _imagePicker.pickImage(
      source: source,
      imageQuality: 70,
    );
    if (image == null || !mounted) return;
    setState(() => _pendingImage = File(image.path));
    final bytes = await File(image.path).readAsBytes();
    if (!mounted) return;
    setState(() => _pendingBase64 = base64Encode(bytes));
  }

  void _removePendingImage() {
    setState(() {
      _pendingImage = null;
      _pendingBase64 = null;
    });
  }

  // ===============================================================
  // SEND
  // ===============================================================

  Future<void> _sendMessage({String? overrideText}) async {
    final text = (overrideText ?? _controller.text).trim();
    if (_loading || (text.isEmpty && _pendingBase64 == null)) return;
    final image = _pendingImage;
    final base64 = _pendingBase64;
    final visibleText = text.isNotEmpty ? text : _imageOnlyText;
    // Lock immediately: a second tap cannot send the same choice twice.
    setState(() => _loading = true);
    try {
      final savedImagePath = image != null
          ? await CoachHistoryService.saveImage(image.path, _conversation!.id)
          : null;
      if (!mounted) return;
      final userMessage = CoachHistoryMessage(
        id: DateTime.now().microsecondsSinceEpoch.toString(),
        role: 'user',
        content: visibleText,
        imagePath: savedImagePath,
        createdAt: DateTime.now(),
      );
      setState(() {
        _messages.add(userMessage);
        _pendingImage = null;
        _pendingBase64 = null;
        _controller.clear();
      });
      _history.add(
        CoachMessage.user(
          text.isNotEmpty
              ? text
              : 'Analyze the attached image and tell me what you think.',
        ),
      );
      _updateTitleFromMessage(text);
      await _saveConversation();
      if (!mounted) return;
      _scrollToBottom();
      final CoachResponse response;
      if (widget.reply != null) {
        response = await widget.reply!(
          messages: List.of(_history),
          base64Image: base64,
          lang: appLang.languageCode,
          personality: _personality,
        );
      } else if (base64 != null) {
        response = await DatingCoachService.chatWithImage(
          messages: _history,
          base64Image: base64,
          lang: appLang.languageCode,
          personality: _personality,
        );
      } else {
        response = await DatingCoachService.chat(
          messages: _history,
          lang: appLang.languageCode,
          personality: _personality,
        );
      }
      if (!mounted) return;
      _history.add(CoachMessage.assistant(response.toHistoryText()));
      final assistantMessage = CoachHistoryMessage(
        id: DateTime.now().microsecondsSinceEpoch.toString(),
        role: 'assistant',
        content: response.message,
        createdAt: DateTime.now(),
        responseData: response.toJson(),
      );
      setState(() {
        _messages.add(assistantMessage);
        _responses[assistantMessage.id] = response;
      });
      await _saveConversation();
      ReviewRequestService.notifySuccess();
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _messages.add(
          CoachHistoryMessage(
            id: DateTime.now().microsecondsSinceEpoch.toString(),
            role: 'assistant',
            content: _errorMessage,
            createdAt: DateTime.now(),
          ),
        );
      });
      // Keep the existing messages in memory if local persistence is unavailable.
      try {
        await _saveConversation();
      } catch (_) {}
    } finally {
      if (mounted) {
        setState(() => _loading = false);
        _scrollToBottom();
      }
    }
  }

  Future<void> _selectCoachChoice(String messageId, String choice) async {
    if (_loading || _messages.isEmpty || _messages.last.id != messageId) return;
    final response = _responses[messageId];
    if (response == null || !response.quickReplies.contains(choice)) return;
    await _sendMessage(overrideText: choice);
  }

  Future<void> _saveConversation() async {
    if (_conversation == null) return;
    _conversation!
      ..messages = List.from(_messages)
      ..updatedAt = DateTime.now();
    await CoachHistoryService.save(_conversation!);
    _loadAllConversations();
  }

  // Gera um título automático a partir da primeira mensagem do
  // utilizador — só corre uma vez, na primeira mensagem da conversa.
  // Não usa mais que 6 palavras para caber bem na lista de histórico.
  void _updateTitleFromMessage(String text) {
    if (_conversation == null) return;
    if (_conversation!.title != _newConversationTitle) return;

    var clean = text.replaceAll('\n', ' ').trim();
    if (clean.isEmpty || clean == _imageOnlyText) {
      clean = _imageConversationTitle;
    }

    // Remove pontuação final e capitaliza a primeira letra
    clean = clean.replaceAll(RegExp(r'[.?!]+$'), '');
    if (clean.isNotEmpty) {
      clean = clean[0].toUpperCase() + clean.substring(1);
    }

    final words = clean.split(' ');
    _conversation!.title = words.length > 6
        ? '${words.take(6).join(' ')}…'
        : clean;
  }

  String get _imageConversationTitle {
    switch (appLang.languageCode) {
      case 'pt':
        return 'Análise de screenshot';
      case 'de':
        return 'Screenshot-Analyse';
      case 'es':
        return 'Análisis de screenshot';
      default:
        return 'Screenshot analysis';
    }
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 150), () {
      if (!_scrollController.hasClients) return;
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    });
  }

  void _copy(String text) {
    Clipboard.setData(ClipboardData(text: text));
    HapticFeedback.lightImpact();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(appLang.resultCopied),
        duration: const Duration(seconds: 1),
        behavior: SnackBarBehavior.floating,
        backgroundColor: const Color(0xFF34C759),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  // ===============================================================
  // BUILD
  // ===============================================================

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder(
      valueListenable: appLangNotifier,
      builder: (context, lang, _) {
        return Scaffold(
          backgroundColor: _bg,
          appBar: _buildAppBar(),
          body: Column(
            children: [
              _buildPersonalitySelector(),
              Expanded(
                child: _messages.isEmpty
                    ? _buildEmptyState()
                    : ListView.builder(
                        controller: _scrollController,
                        physics: const BouncingScrollPhysics(),
                        padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                        itemCount: _messages.length + (_loading ? 1 : 0),
                        itemBuilder: (context, index) {
                          if (index == _messages.length) return _buildTyping();
                          final msg = _messages[index];
                          if (msg.role == 'assistant') {
                            final response = _responses[msg.id];
                            return _buildAssistantBubble(msg, response);
                          }
                          return _buildUserBubble(msg);
                        },
                      ),
              ),
              _buildInput(),
            ],
          ),
        );
      },
    );
  }

  // ===============================================================
  // APP BAR — limpo, estilo ChatGPT
  // ===============================================================

  Widget _buildPersonalitySelector() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      child: Row(
        children: CoachPersonality.values.map((personality) {
          final label = switch (personality) {
            CoachPersonality.neutro => appLang.ui(const {'en': 'Neutral', 'pt': 'Neutro', 'de': 'Neutral', 'es': 'Neutro', 'fr': 'Neutre', 'it': 'Neutro', 'tr': 'Nötr', 'pl': 'Neutralny', 'ru': 'Нейтральный', 'ar': 'محايد'}),
            CoachPersonality.alpha => 'Alpha',
            CoachPersonality.romantico => appLang.ui(const {'en': 'Romantic', 'pt': 'Romântico', 'de': 'Romantisch', 'es': 'Romántico', 'fr': 'Romantique', 'it': 'Romantico', 'tr': 'Romantik', 'pl': 'Romantyczny', 'ru': 'Романтичный', 'ar': 'رومانسي'}),
            CoachPersonality.flerte => appLang.ui(const {'en': 'Flirt', 'pt': 'Flerte', 'de': 'Flirt', 'es': 'Coqueteo', 'fr': 'Flirt', 'it': 'Flirt', 'tr': 'Flört', 'pl': 'Flirt', 'ru': 'Флирт', 'ar': 'غزل'}),
          };
          return Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 2),
              child: ChoiceChip(
                key: ValueKey(personality),
                label: SizedBox(
                  width: double.infinity,
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      label,
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 12),
                    ),
                  ),
                ),
                padding: EdgeInsets.zero,
                labelPadding: const EdgeInsets.symmetric(horizontal: 4),
                showCheckmark: false,
                selected: _personality == personality,
                selectedColor: _accent.withValues(alpha: .15),
                onSelected: _loading
                    ? null
                    : (_) => setState(() => _personality = personality),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: _bg,
      elevation: 0,
      centerTitle: true,
      automaticallyImplyLeading: false,
      leadingWidth: 76,
      leading: TextButton(
        key: const Key('coach-chat-history'),
        onPressed: _loading ? null : _openHistory,
        child: Text(
          'Chat',
          style: TextStyle(color: _textPrimary, fontWeight: FontWeight.w700),
        ),
      ),
      title: GestureDetector(
        onTap: _openHistory,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Dolla IA',
                  style: TextStyle(
                    color: _textPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(width: 4),
                Icon(
                  Icons.keyboard_arrow_down_rounded,
                  color: _textSecondary,
                  size: 18,
                ),
              ],
            ),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 6,
                  height: 6,
                  decoration: const BoxDecoration(
                    color: Color(0xFF34C759),
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 4),
                Text(
                  appLang.ui(const {'en': 'Online', 'pt': 'Online', 'de': 'Online', 'es': 'En línea', 'fr': 'En ligne', 'it': 'Online', 'tr': 'Çevrimiçi', 'pl': 'Online', 'ru': 'В сети', 'ar': 'متصل'}),
                  style: TextStyle(
                    color: Color(0xFF34C759),
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
      actions: [
        if (!widget.embedded)
          IconButton(
            onPressed: () => Navigator.maybePop(context),
            icon: Icon(Icons.arrow_back, color: _textPrimary),
          ),
        IconButton(
          onPressed: _startFreshChat,
          icon: Icon(Icons.edit_square, color: _textPrimary, size: 21),
        ),
      ],
    );
  }

  // ===============================================================
  // EMPTY STATE
  // ===============================================================

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 22),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (!_inputFocused)
              const _BouncingHappyFace()
            else
              const SizedBox(height: 56),
            const SizedBox(height: 16),
            Text(
              'Dolla',
              style: TextStyle(
                color: _textPrimary,
                fontSize: 20,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              _greetingText,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: _textSecondary,
                fontSize: 14,
                fontWeight: FontWeight.w500,
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String get _greetingText {
    switch (appLang.languageCode) {
      case 'pt':
        return 'Olá, eu sou a Dolla, a tua coach pessoal de dating.\nComo posso ajudar?';
      case 'de':
        return 'Hallo, ich bin Dolla, dein persönlicher Dating Coach.\nWie kann ich dir helfen?';
      case 'es':
        return 'Hola, soy Dolla, tu coach personal de dating.\n¿Cómo puedo ayudarte?';
      default:
        return 'Hi, I\'m Dolla, your personal dating coach.\nHow can I help?';
    }
  }

  // ===============================================================
  // USER BUBBLE — simples, alinhada à direita, sem gradiente forte
  // ===============================================================

  Widget _buildUserBubble(CoachHistoryMessage message) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Align(
        alignment: Alignment.centerRight,
        child: GestureDetector(
          onLongPress: () => _copy(message.content),
          child: Container(
            constraints: BoxConstraints(
              maxWidth: MediaQuery.of(context).size.width * 0.78,
            ),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: _bubbleUser,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (message.imagePath != null &&
                    File(message.imagePath!).existsSync())
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.file(
                      File(message.imagePath!),
                      width: 200,
                      height: 140,
                      fit: BoxFit.cover,
                    ),
                  ),
                if (message.imagePath != null && message.content.isNotEmpty)
                  const SizedBox(height: 8),
                if (message.content.isNotEmpty &&
                    message.content != _imageOnlyText)
                  Text(
                    message.content,
                    style: TextStyle(
                      color: _textPrimary,
                      fontSize: 15.5,
                      height: 1.4,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ===============================================================
  // ASSISTANT BUBBLE — texto puro estilo ChatGPT, sem avatar por
  // mensagem, sem cards excessivos. Só mostra "chips" leves se
  // houver dados estruturados relevantes.
  // ===============================================================

  Widget _buildAssistantBubble(
    CoachHistoryMessage message,
    CoachResponse? response,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 22),
      child: Align(
        alignment: Alignment.centerLeft,
        child: GestureDetector(
          onLongPress: () => _copy(message.content),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                message.content,
                style: TextStyle(
                  color: _textPrimary,
                  fontSize: 15.5,
                  height: 1.55,
                  fontWeight: FontWeight.w400,
                ),
              ),

              if (response != null && response.quickReplies.isEmpty) ...[
                const SizedBox(height: 10),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    _chip(
                      _prettyInterest(response.interestLevel),
                      _interestColor(response.interestLevel),
                    ),
                    _chip(
                      _prettyStage(response.datingStage),
                      const Color(0xFF7C3AED),
                    ),
                  ],
                ),
              ],

              if (response != null && response.quickReplies.length == 3) ...[
                const SizedBox(height: 12),
                _buildCoachChoices(message.id, response.quickReplies),
              ],

              if (response != null &&
                  response.shouldSendMessage &&
                  response.suggestedMessage.trim().isNotEmpty) ...[
                const SizedBox(height: 12),
                _buildSuggestedMessage(
                  response.suggestedMessage.trim(),
                  message.id,
                ),
              ],

              const SizedBox(height: 6),
              GestureDetector(
                onTap: () => _copy(message.content),
                child: Icon(
                  Icons.copy_rounded,
                  size: 15,
                  color: _textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCoachChoices(String messageId, List<String> choices) {
    final enabled =
        !_loading && _messages.isNotEmpty && _messages.last.id == messageId;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (var index = 0; index < choices.length; index++)
          Padding(
            padding: EdgeInsets.only(
              bottom: index < choices.length - 1 ? 8 : 0,
            ),
            child: OutlinedButton(
              key: ValueKey('coach-choice-$messageId-$index'),
              onPressed: enabled
                  ? () => _selectCoachChoice(messageId, choices[index])
                  : null,
              style: OutlinedButton.styleFrom(
                alignment: Alignment.centerLeft,
                minimumSize: const Size(double.infinity, 48),
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                foregroundColor: _textPrimary,
                disabledForegroundColor: _textSecondary,
                backgroundColor: _accent.withOpacity(_dark ? 0.08 : 0.04),
                side: BorderSide(
                  color: _accent.withOpacity(enabled ? 0.4 : 0.12),
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: Text(
                choices[index],
                softWrap: true,
                style: const TextStyle(
                  fontSize: 14.5,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _chip(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withOpacity(_dark ? 0.16 : 0.10),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  Widget _buildSuggestedMessage(String message, String messageId) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _accent.withOpacity(_dark ? 0.08 : 0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _accent.withOpacity(0.18)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            message,
            style: TextStyle(
              color: _textPrimary,
              fontSize: 14.5,
              height: 1.4,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              GestureDetector(
                onTap: () => _copy(message),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.copy_rounded, size: 14, color: _accent),
                    const SizedBox(width: 5),
                    Text(
                      _copyLabel,
                      style: const TextStyle(
                        color: _accent,
                        fontSize: 12.5,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 18),
              GestureDetector(
                onTap:
                    !_loading &&
                        _messages.isNotEmpty &&
                        _messages.last.id == messageId
                    ? () => _sendMessage(overrideText: _anotherRequest)
                    : null,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.refresh_rounded,
                      size: 14,
                      color: _textSecondary,
                    ),
                    const SizedBox(width: 5),
                    Text(
                      _anotherLabel,
                      style: TextStyle(
                        color: _textSecondary,
                        fontSize: 12.5,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ===============================================================
  // TYPING
  // ===============================================================

  Widget _buildTyping() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 16),
      child: Align(
        alignment: Alignment.centerLeft,
        child: _CoachTypingDots(color: _textPrimary),
      ),
    );
  }

  // ===============================================================
  // INPUT — limpo, uma linha
  // ===============================================================

  Widget _buildInput() {
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 6, 12, 10),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (_pendingImage != null) _buildImagePreview(),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
              decoration: BoxDecoration(
                color: _inputBg,
                borderRadius: BorderRadius.circular(26),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  IconButton(
                    onPressed: _chooseImage,
                    icon: Icon(
                      Icons.add_rounded,
                      color: _textPrimary,
                      size: 24,
                    ),
                  ),
                  Expanded(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxHeight: 110),
                      child: TextField(
                        controller: _controller,
                        focusNode: _focusNode,
                        maxLines: null,
                        textInputAction: TextInputAction.send,
                        onSubmitted: (_) => _sendMessage(),
                        style: TextStyle(color: _textPrimary, fontSize: 15),
                        decoration: InputDecoration(
                          hintText: _inputHint,
                          hintStyle: TextStyle(
                            color: _textSecondary,
                            fontSize: 15,
                          ),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(
                            vertical: 10,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 4),
                  GestureDetector(
                    onTap: () => _sendMessage(),
                    child: Container(
                      width: 34,
                      height: 34,
                      margin: const EdgeInsets.only(bottom: 4, right: 2),
                      decoration: BoxDecoration(
                        color: _accent,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.arrow_upward_rounded,
                        color: Colors.white,
                        size: 18,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImagePreview() {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      alignment: Alignment.centerLeft,
      child: Stack(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(13),
            child: Image.file(
              _pendingImage!,
              width: 64,
              height: 64,
              fit: BoxFit.cover,
            ),
          ),
          Positioned(
            right: 3,
            top: 3,
            child: GestureDetector(
              onTap: _removePendingImage,
              child: Container(
                width: 19,
                height: 19,
                decoration: const BoxDecoration(
                  color: Colors.black54,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.close_rounded,
                  color: Colors.white,
                  size: 12,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ===============================================================
  // LABELS
  // ===============================================================

  String get _inputHint {
    switch (appLang.languageCode) {
      case 'pt':
        return 'Mensagem';
      case 'de':
        return 'Nachricht';
      case 'es':
        return 'Mensaje';
      default:
        return 'Message';
    }
  }

  String get _imageOnlyText {
    switch (appLang.languageCode) {
      case 'pt':
        return 'Imagem enviada. O que achas?';
      case 'de':
        return 'Bild gesendet. Was denkst du?';
      case 'es':
        return 'Imagen enviada. ¿Qué opinas?';
      default:
        return 'Image sent. What do you think?';
    }
  }

  String get _galleryLabel {
    switch (appLang.languageCode) {
      case 'pt':
        return 'Escolher uma foto';
      case 'de':
        return 'Foto auswählen';
      case 'es':
        return 'Elegir una foto';
      default:
        return 'Choose a photo';
    }
  }

  String get _cameraLabel {
    switch (appLang.languageCode) {
      case 'pt':
        return 'Tirar uma foto';
      case 'de':
        return 'Foto aufnehmen';
      case 'es':
        return 'Tomar una foto';
      default:
        return 'Take a photo';
    }
  }

  String get _errorMessage {
    switch (appLang.languageCode) {
      case 'pt':
        return 'Tive um problema de ligação. Tenta novamente.';
      case 'de':
        return 'Verbindungsfehler. Bitte versuche es erneut.';
      case 'es':
        return 'Hubo un problema de conexión. Inténtalo de nuevo.';
      default:
        return 'I had a connection problem. Please try again.';
    }
  }

  String get _copyLabel {
    switch (appLang.languageCode) {
      case 'de':
        return 'Kopieren';
      case 'es':
        return 'Copiar';
      case 'pt':
        return 'Copiar';
      default:
        return 'Copy';
    }
  }

  String get _anotherRequest => switch (appLang.languageCode) {
    'pt' =>
      'Quero outra abordagem para a mesma situação, com uma ideia diferente.',
    'de' =>
      'Gib mir für dieselbe Situation einen anderen Ansatz mit einer neuen Idee.',
    'es' =>
      'Quiero otro enfoque para la misma situación, con una idea diferente.',
    'fr' =>
      'Propose une autre approche pour la même situation, avec une idée différente.',
    'it' =>
      'Voglio un altro approccio per la stessa situazione, con una nuova idea.',
    'tr' => 'Aynı durum için farklı bir fikirle başka bir yaklaşım öner.',
    'pl' =>
      'Zaproponuj inne podejście do tej samej sytuacji, z nowym pomysłem.',
    'ru' => 'Предложи другой подход к той же ситуации с новой идеей.',
    'ar' => 'أريد أسلوبا آخر لنفس الموقف بفكرة مختلفة.',
    _ => 'Give me a different approach to the same situation, with a new idea.',
  };

  String get _anotherLabel {
    switch (appLang.languageCode) {
      case 'de':
        return 'Andere Option';
      case 'es':
        return 'Otra opción';
      case 'pt':
        return 'Outra opção';
      default:
        return 'Another option';
    }
  }

  String _prettyInterest(String value) {
    final l = appLang.languageCode;
    switch (value.toLowerCase()) {
      case 'high':
      case 'strong':
        return l == 'pt'
            ? 'Interesse forte'
            : l == 'de'
            ? 'Starkes Interesse'
            : l == 'es'
            ? 'Interés fuerte'
            : 'Strong interest';
      case 'medium':
      case 'moderate':
        return l == 'pt'
            ? 'Interesse moderado'
            : l == 'de'
            ? 'Mittleres Interesse'
            : l == 'es'
            ? 'Interés moderado'
            : 'Moderate interest';
      case 'low':
        return l == 'pt'
            ? 'Interesse baixo'
            : l == 'de'
            ? 'Geringes Interesse'
            : l == 'es'
            ? 'Interés bajo'
            : 'Low interest';
      case 'warming_up':
        return l == 'pt'
            ? 'A aquecer'
            : l == 'de'
            ? 'Aufbauend'
            : l == 'es'
            ? 'Creciendo'
            : 'Warming up';
      default:
        return l == 'pt'
            ? 'Incerto'
            : l == 'de'
            ? 'Unklar'
            : l == 'es'
            ? 'Incierto'
            : 'Unclear';
    }
  }

  String _prettyStage(String value) {
    final l = appLang.languageCode;
    switch (value.toLowerCase()) {
      case 'match':
        return 'Match';
      case 'opening':
        return l == 'pt'
            ? 'Abertura'
            : l == 'de'
            ? 'Eröffnung'
            : l == 'es'
            ? 'Apertura'
            : 'Opening';
      case 'getting_to_know':
        return l == 'pt'
            ? 'A conhecer-se'
            : l == 'de'
            ? 'Kennenlernen'
            : l == 'es'
            ? 'Conociéndose'
            : 'Getting to know';
      case 'building_connection':
        return l == 'pt'
            ? 'A criar conexão'
            : l == 'de'
            ? 'Verbindung aufbauen'
            : l == 'es'
            ? 'Creando conexión'
            : 'Building connection';
      case 'flirting':
        return l == 'pt'
            ? 'A flertar'
            : l == 'de'
            ? 'Flirten'
            : l == 'es'
            ? 'Coqueteando'
            : 'Flirting';
      case 'escalating':
        return l == 'pt'
            ? 'A escalar'
            : l == 'de'
            ? 'Eskalierend'
            : l == 'es'
            ? 'Escalando'
            : 'Escalating';
      case 'asking_for_date':
        return l == 'pt'
            ? 'A convidar'
            : l == 'de'
            ? 'Um Date bitten'
            : l == 'es'
            ? 'Pidiendo cita'
            : 'Asking for date';
      case 'date_planned':
        return l == 'pt'
            ? 'Encontro marcado'
            : l == 'de'
            ? 'Date geplant'
            : l == 'es'
            ? 'Cita planeada'
            : 'Date planned';
      case 'post_date':
        return l == 'pt'
            ? 'Pós-encontro'
            : l == 'de'
            ? 'Nach dem Date'
            : l == 'es'
            ? 'Post cita'
            : 'Post-date';
      default:
        return l == 'pt'
            ? 'Incerto'
            : l == 'de'
            ? 'Unklar'
            : l == 'es'
            ? 'Incierto'
            : 'Unclear';
    }
  }

  Color _interestColor(String value) {
    switch (value.toLowerCase()) {
      case 'high':
      case 'strong':
        return const Color(0xFF34C759);
      case 'medium':
      case 'moderate':
      case 'warming_up':
        return const Color(0xFFFF9500);
      case 'low':
        return const Color(0xFFFF3B30);
      default:
        return const Color(0xFF8E8E93);
    }
  }
}

// ===============================================================
// BOUNCING HAPPY FACE — emoji feliz que vibra, "esconde" e volta
// ===============================================================

class _BouncingHappyFace extends StatefulWidget {
  const _BouncingHappyFace();

  @override
  State<_BouncingHappyFace> createState() => _BouncingHappyFaceState();
}

class _BouncingHappyFaceState extends State<_BouncingHappyFace>
    with SingleTickerProviderStateMixin {
  late AnimationController _waveController;
  late Animation<double> _rotateAnim;

  @override
  void initState() {
    super.initState();

    _waveController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2600),
    )..repeat();

    // Movimento de aceno suave e profissional — rotação leve em
    // torno da base do pulso, sem exageros.
    _rotateAnim = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween(
          begin: 0.0,
          end: 0.22,
        ).chain(CurveTween(curve: Curves.easeInOut)),
        weight: 22,
      ),
      TweenSequenceItem(
        tween: Tween(
          begin: 0.22,
          end: -0.08,
        ).chain(CurveTween(curve: Curves.easeInOut)),
        weight: 22,
      ),
      TweenSequenceItem(
        tween: Tween(
          begin: -0.08,
          end: 0.14,
        ).chain(CurveTween(curve: Curves.easeInOut)),
        weight: 18,
      ),
      TweenSequenceItem(
        tween: Tween(
          begin: 0.14,
          end: 0.0,
        ).chain(CurveTween(curve: Curves.easeOut)),
        weight: 38,
      ),
    ]).animate(_waveController);
  }

  @override
  void dispose() {
    _waveController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _rotateAnim,
      builder: (context, child) {
        return Transform.rotate(
          angle: _rotateAnim.value,
          alignment: Alignment.bottomCenter,
          child: child,
        );
      },
      child: const SizedBox(
        width: 56,
        height: 56,
        child: Center(child: Text('👋🏻', style: TextStyle(fontSize: 40))),
      ),
    );
  }
}

class _CoachTypingDots extends StatefulWidget {
  final Color color;
  const _CoachTypingDots({required this.color});
  @override
  State<_CoachTypingDots> createState() => _CoachTypingDotsState();
}

class _CoachTypingDotsState extends State<_CoachTypingDots>
    with SingleTickerProviderStateMixin {
  late final AnimationController _animation = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1100),
  );
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.disableAnimationsOf(context)) {
      _animation.stop();
      _animation.value = .5;
    } else {
      _animation.repeat();
    }
  }

  @override
  void dispose() {
    _animation.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final reduced = MediaQuery.disableAnimationsOf(context);
    return Semantics(
      label: appLang.ui(const {'en': 'Preparing response', 'pt': 'A preparar resposta', 'de': 'Antwort wird vorbereitet', 'es': 'Preparando respuesta', 'fr': 'Préparation de la réponse', 'it': 'Preparazione della risposta', 'tr': 'Yanıt hazırlanıyor', 'pl': 'Przygotowywanie odpowiedzi', 'ru': 'Подготовка ответа', 'ar': 'جارٍ إعداد الرد'}),
      child: AnimatedBuilder(
        animation: _animation,
        builder: (context, _) => Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(3, (i) {
            final opacity = reduced
                ? .65
                : .3 +
                      .7 *
                          (math.sin(_animation.value * 2 * math.pi - i * .8) +
                              1) /
                          2;
            return Padding(
              padding: const EdgeInsets.only(right: 6),
              child: Opacity(
                key: ValueKey('coach-typing-dot-$i'),
                opacity: opacity,
                child: Container(
                  width: 11,
                  height: 11,
                  decoration: BoxDecoration(
                    color: widget.color,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            );
          }),
        ),
      ),
    );
  }
}
