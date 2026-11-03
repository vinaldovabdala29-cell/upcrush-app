import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SavedChat {
  final String id;
  final String kind;
  String title;
  final String prompt;
  final String lastMessage;
  final String? imagePath;
  String style;
  List<String> replies;
  DateTime updatedAt;

  SavedChat({required this.id, required this.kind, required this.title,
    required this.prompt, required this.lastMessage, this.imagePath, required this.style,
    required this.replies, required this.updatedAt});

  factory SavedChat.fromJson(Map<String, dynamic> j) => SavedChat(
    id: j['id'] as String, kind: j['kind'] as String,
    title: j['title'] as String? ?? 'Chat', prompt: j['prompt'] as String? ?? '',
    lastMessage: j['lastMessage'] as String? ?? '', imagePath: j['imagePath'] as String?,
    style: j['style'] as String? ?? 'flertar',
    replies: (j['replies'] as List? ?? []).map((e) => e.toString()).toList(),
    updatedAt: DateTime.tryParse(j['updatedAt']?.toString() ?? '') ?? DateTime.now());

  Map<String, dynamic> toJson() => {
    'id': id, 'kind': kind, 'title': title, 'prompt': prompt,
    'lastMessage': lastMessage, 'imagePath': imagePath, 'style': style, 'replies': replies,
    'updatedAt': updatedAt.toIso8601String(),
  };
}

class ChatHistoryService {
  static const _key = 'upcrush_saved_chats_v1';
  static Future<List<SavedChat>> load() async {
    final prefs = await SharedPreferences.getInstance();
    try {
      final data = jsonDecode(prefs.getString(_key) ?? '[]') as List;
      final chats = data.map((e) => SavedChat.fromJson(Map<String, dynamic>.from(e as Map))).toList();
      chats.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
      return chats;
    } catch (_) { return []; }
  }

  static String automaticTitle(String text, String fallback) {
    final clean = text.replaceAll(RegExp(r'\s+'), ' ').trim();
    if (clean.isEmpty) return fallback;
    final words = clean.split(' ');
    final shortened = words.take(7).join(' ');
    return shortened.length > 48 ? '${shortened.substring(0, 48).trim()}…'
        : words.length > 7 ? '$shortened…' : shortened;
  }

  static Future<String?> persistImage(File? source, String chatId) async {
    if (source == null || !await source.exists()) return null;
    final directory = Directory('${(await getApplicationDocumentsDirectory()).path}/upcrush_chat_images');
    if (!await directory.exists()) await directory.create(recursive: true);
    final destination = File('${directory.path}/$chatId.jpg');
    if (source.path != destination.path) await source.copy(destination.path);
    return destination.path;
  }

  static Future<void> save(SavedChat chat) async {
    final chats = await load();
    final previous = chats.where((c) => c.id == chat.id).toList();
    if (previous.isNotEmpty) {
      // Keep a user-renamed title and previously saved image when updating replies.
      if (previous.first.title != automaticTitle(previous.first.replies.isEmpty ? '' : previous.first.replies.last, previous.first.kind == 'opener' ? 'Iniciar conversa' : 'Responder conversa') && previous.first.title != 'Iniciar conversa' && previous.first.title != 'Responder conversa') {
        chat.title = previous.first.title;
      }
    }
    chats.removeWhere((c) => c.id == chat.id);
    chats.insert(0, chat);
    await _write(chats);
  }

  static Future<void> rename(String id, String title) async {
    final chats = await load();
    for (final chat in chats) { if (chat.id == id) chat.title = title; }
    await _write(chats);
  }

  static Future<void> delete(String id) async {
    final chats = await load();
    chats.removeWhere((chat) => chat.id == id);
    await _write(chats);
  }

  static Future<void> _write(List<SavedChat> chats) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, jsonEncode(chats.map((e) => e.toJson()).toList()));
  }
}
