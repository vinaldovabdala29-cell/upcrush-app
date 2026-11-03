import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class FavoriteLinesService {
  static const _key = 'upcrush_favorite_pick_lines_v1';

  static Future<List<String>> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw == null) return [];
    try { return (jsonDecode(raw) as List).whereType<String>().toList(); }
    catch (_) { return []; }
  }

  static Future<bool> toggle(String line) async {
    final text = line.trim();
    if (text.isEmpty) return false;
    final lines = await load();
    final exists = lines.contains(text);
    if (exists) { lines.remove(text); } else { lines.insert(0, text); }
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, jsonEncode(lines));
    return !exists;
  }
}
