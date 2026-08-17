import 'dart:convert';
import 'dart:io';

import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

// ===============================================================
// COACH HISTORY MODELS — usados só para PERSISTÊNCIA/HISTÓRICO
// ===============================================================
//
// Estes modelos são diferentes dos que estão em coach_models.dart:
// - CoachMessage (coach_models.dart) → enviado à API, simples
// - CoachHistoryMessage (aqui)       → guardado no disco, completo
//   (tem id, imagePath, createdAt — necessário para exibir
//   histórico de conversas na UI)
// ===============================================================

class CoachHistoryMessage {
  final String id;
  final String role;
  final String content;
  final String? imagePath;
  final DateTime createdAt;

  CoachHistoryMessage({
    required this.id,
    required this.role,
    required this.content,
    this.imagePath,
    required this.createdAt,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'role': role,
      'content': content,
      'imagePath': imagePath,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory CoachHistoryMessage.fromJson(Map<String, dynamic> json) {
    return CoachHistoryMessage(
      id: json['id']?.toString() ?? '',
      role: json['role']?.toString() ?? 'user',
      content: json['content']?.toString() ?? '',
      imagePath: json['imagePath']?.toString(),
      createdAt: DateTime.tryParse(json['createdAt']?.toString() ?? '') ?? DateTime.now(),
    );
  }
}

class CoachConversation {
  final String id;
  String title;
  DateTime createdAt;
  DateTime updatedAt;
  List<CoachHistoryMessage> messages;

  CoachConversation({
    required this.id,
    required this.title,
    required this.createdAt,
    required this.updatedAt,
    required this.messages,
  });

  factory CoachConversation.create() {
    final now = DateTime.now();
    return CoachConversation(
      id: now.microsecondsSinceEpoch.toString(),
      title: 'New conversation',
      createdAt: now,
      updatedAt: now,
      messages: [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'messages': messages.map((e) => e.toJson()).toList(),
    };
  }

  factory CoachConversation.fromJson(Map<String, dynamic> json) {
    return CoachConversation(
      id: json['id']?.toString() ?? '',
      title: json['title']?.toString() ?? 'New conversation',
      createdAt: DateTime.tryParse(json['createdAt']?.toString() ?? '') ?? DateTime.now(),
      updatedAt: DateTime.tryParse(json['updatedAt']?.toString() ?? '') ?? DateTime.now(),
      messages: (json['messages'] as List? ?? [])
          .whereType<Map>()
          .map((e) => CoachHistoryMessage.fromJson(Map<String, dynamic>.from(e)))
          .toList(),
    );
  }
}

// ===============================================================
// COACH HISTORY SERVICE
// ===============================================================

class CoachHistoryService {
  static const String _storageKey = 'upcrush_coach_conversations';

  static Future<List<CoachConversation>> loadAll() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_storageKey);

    if (raw == null || raw.isEmpty) return [];

    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) return [];

      final conversations = decoded
          .whereType<Map>()
          .map((item) => CoachConversation.fromJson(Map<String, dynamic>.from(item)))
          .toList();

      conversations.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
      return conversations;
    } catch (_) {
      return [];
    }
  }

  static Future<void> save(CoachConversation conversation) async {
    final conversations = await loadAll();
    final index = conversations.indexWhere((item) => item.id == conversation.id);

    if (index >= 0) {
      conversations[index] = conversation;
    } else {
      conversations.insert(0, conversation);
    }

    conversations.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _storageKey,
      jsonEncode(conversations.map((e) => e.toJson()).toList()),
    );
  }

  static Future<void> delete(String id) async {
    final conversations = await loadAll();
    conversations.removeWhere((conversation) => conversation.id == id);

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _storageKey,
      jsonEncode(conversations.map((e) => e.toJson()).toList()),
    );
  }

  static Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_storageKey);
  }

  static Future<String> saveImage(String sourcePath, String conversationId) async {
    final directory = await getApplicationDocumentsDirectory();
    final imageDirectory = '${directory.path}/upcrush_coach_images';

    final directoryObject = await Directory(imageDirectory).create(recursive: true);

    final extension = sourcePath.contains('.')
        ? sourcePath.substring(sourcePath.lastIndexOf('.'))
        : '.jpg';

    final fileName = '${conversationId}_${DateTime.now().millisecondsSinceEpoch}$extension';
    final targetPath = '${directoryObject.path}/$fileName';

    final source = File(sourcePath);
    await source.copy(targetPath);

    return targetPath;
  }
}