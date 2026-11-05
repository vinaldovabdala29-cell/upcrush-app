import 'dart:ui';
import 'opener_screen.dart';
import 'screenshot_screen.dart';
import 'package:flutter/services.dart';
import '../services/favorite_lines_service.dart';
import 'dart:io';
import 'package:flutter/material.dart';
import '../main.dart';
import '../services/chat_history_service.dart';
import 'result_screen.dart';

class SavedChatsScreen extends StatefulWidget {
  final int refreshToken;
  const SavedChatsScreen({super.key, this.refreshToken = 0});
  @override
  State<SavedChatsScreen> createState() => _SavedChatsScreenState();
}

class _SavedChatsScreenState extends State<SavedChatsScreen> {
  List<SavedChat> _chats = [];
  String _search = '';
  bool _showFavorites = false;
  List<String> _favorites = [];
  @override
  void initState() { super.initState(); _refresh(); }
  @override
  void didUpdateWidget(covariant SavedChatsScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.refreshToken != widget.refreshToken) _refresh();
  }
  Future<void> _refresh() async {
    final chats = await ChatHistoryService.load();
    final favorites = await FavoriteLinesService.load();
    if (mounted) setState(() { _chats = chats; _favorites = favorites; });
  }
  Future<void> _rename(SavedChat chat) async {
    final controller = TextEditingController(text: chat.title);
    final title = await showDialog<String>(context: context, builder: (ctx) => AlertDialog(
      title: Text(appLang.ui(const {'en': 'Rename conversation', 'pt': 'Renomear conversa', 'de': 'Chat umbenennen', 'es': 'Renombrar conversación', 'fr': 'Renommer la conversation', 'it': 'Rinomina conversazione', 'tr': 'Sohbeti yeniden adlandır', 'pl': 'Zmień nazwę rozmowy', 'ru': 'Переименовать беседу', 'ar': 'إعادة تسمية المحادثة'})),
      content: TextField(controller: controller, autofocus: true),
      actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: Text(appLang.ui(const {'en': 'Cancel', 'pt': 'Cancelar', 'de': 'Abbrechen', 'es': 'Cancelar', 'fr': 'Annuler', 'it': 'Annulla', 'tr': 'İptal', 'pl': 'Anuluj', 'ru': 'Отмена', 'ar': 'إلغاء'}))),
        TextButton(onPressed: () => Navigator.pop(ctx, controller.text.trim()), child: Text(appLang.ui(const {'en': 'Save', 'pt': 'Guardar', 'de': 'Speichern', 'es': 'Guardar', 'fr': 'Enregistrer', 'it': 'Salva', 'tr': 'Kaydet', 'pl': 'Zapisz', 'ru': 'Сохранить', 'ar': 'حفظ'})))]));
    controller.dispose();
    if (title != null && title.isNotEmpty) { await ChatHistoryService.rename(chat.id, title); await _refresh(); }
  }
  Future<void> _delete(SavedChat chat) async {
    final ok = await showDialog<bool>(context: context, builder: (ctx) => AlertDialog(
      title: Text(appLang.ui(const {'en': 'Delete conversation?', 'pt': 'Eliminar conversa?', 'de': 'Chat löschen?', 'es': '¿Eliminar conversación?', 'fr': 'Supprimer la conversation ?', 'it': 'Eliminare la conversazione?', 'tr': 'Sohbet silinsin mi?', 'pl': 'Usunąć rozmowę?', 'ru': 'Удалить беседу?', 'ar': 'حذف المحادثة؟'})),
      content: Text(appLang.ui(const {'en': 'This action cannot be undone.', 'pt': 'Esta ação não pode ser desfeita.', 'de': 'Diese Aktion kann nicht rückgängig gemacht werden.', 'es': 'Esta acción no se puede deshacer.', 'fr': 'Cette action est irréversible.', 'it': 'Questa azione non può essere annullata.', 'tr': 'Bu işlem geri alınamaz.', 'pl': 'Tej operacji nie można cofnąć.', 'ru': 'Это действие нельзя отменить.', 'ar': 'لا يمكن التراجع عن هذا الإجراء.'})),
      actions: [TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(appLang.ui(const {'en': 'Cancel', 'pt': 'Cancelar', 'de': 'Abbrechen', 'es': 'Cancelar', 'fr': 'Annuler', 'it': 'Annulla', 'tr': 'İptal', 'pl': 'Anuluj', 'ru': 'Отмена', 'ar': 'إلغاء'}))),
        TextButton(onPressed: () => Navigator.pop(ctx, true), child: Text(appLang.ui(const {'en': 'Delete', 'pt': 'Eliminar', 'de': 'Löschen', 'es': 'Eliminar', 'fr': 'Supprimer', 'it': 'Elimina', 'tr': 'Sil', 'pl': 'Usuń', 'ru': 'Удалить', 'ar': 'حذف'})))]));
    if (ok == true) { await ChatHistoryService.delete(chat.id); await _refresh(); }
  }
  Future<void> _open(SavedChat chat) async {
    if (chat.kind == 'opener') {
      await Navigator.push(context, MaterialPageRoute(builder: (_) => OpenerScreen(savedChat: chat)));
    } else if (chat.imagePath != null) {
      await Navigator.push(context, MaterialPageRoute(builder: (_) => ScreenshotScreen(savedChat: chat)));
    } else {
      // Compatibilidade com históricos antigos que não guardavam imagem.
      await Navigator.push(context, MaterialPageRoute(builder: (_) => ResultScreen(
        title: chat.title, replies: chat.replies, originalPrompt: chat.prompt,
        ultimaMensagem: chat.lastMessage, style: chat.style, savedChatId: chat.id)));
    }
    await _refresh();
  }
  Widget _favoriteCard(String line, Color fg, bool dark) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(22),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
          child: Container(
            decoration: BoxDecoration(
              color: dark
                  ? Colors.white.withOpacity(0.09)
                  : Colors.white.withOpacity(0.76),
              borderRadius: BorderRadius.circular(22),
              border: Border.all(
                color: dark
                    ? Colors.white.withOpacity(0.20)
                    : Colors.white.withOpacity(0.94),
                width: 1.2,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(dark ? 0.12 : 0.055),
                  blurRadius: 20,
                  offset: const Offset(0, 7),
                ),
              ],
            ),
            padding: const EdgeInsets.fromLTRB(18, 18, 12, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  line,
                  style: TextStyle(
                    color: fg,
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    height: 1.45,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    IconButton(
                      tooltip: 'Copy',
                      icon: Icon(Icons.copy_rounded, color: fg.withOpacity(.72)),
                      onPressed: () => Clipboard.setData(ClipboardData(text: line)),
                    ),
                    IconButton(
                      tooltip: 'Remove',
                      icon: const Icon(Icons.favorite_rounded),
                      color: const Color(0xFFFF2D55),
                      onPressed: () async {
                        await FavoriteLinesService.toggle(line);
                        await _refresh();
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final dark = isDarkModeNotifier.value;
    final fg = dark ? Colors.white : const Color(0xFF1C1C1E);
    final matches = _chats.where((c) => (c.title + ' ' + c.replies.join(' ')).toLowerCase().contains(_search.toLowerCase())).toList();
    return Scaffold(backgroundColor: Colors.transparent, body: SafeArea(bottom: false, child: Column(
      crossAxisAlignment: CrossAxisAlignment.start, children: [
      Padding(padding: const EdgeInsets.fromLTRB(22, 24, 22, 14), child: Text(appLang.ui(const {'en': 'Chats', 'pt': 'Conversas', 'de': 'Chats', 'es': 'Chats', 'fr': 'Conversations', 'it': 'Chat', 'tr': 'Sohbetler', 'pl': 'Czaty', 'ru': 'Чаты', 'ar': 'المحادثات'}),
        style: TextStyle(color: fg, fontSize: 30, fontWeight: FontWeight.bold))),
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Row(children: [
          Expanded(child: ChoiceChip(label: Text(appLang.ui(const {'pt':'Conversas','en':'Chats','de':'Chats','es':'Conversaciones','fr':'Conversations','it':'Chat','tr':'Sohbetler','pl':'Czaty','ru':'Чаты','ar':'المحادثات'})),
            selected: !_showFavorites, onSelected: (_) => setState(() => _showFavorites = false))),
          const SizedBox(width: 12),
          Expanded(child: ChoiceChip(label: Text(appLang.ui(const {'pt':'❤️ Favoritos','en':'❤️ Favorites','de':'❤️ Favoriten','es':'❤️ Favoritos','fr':'❤️ Favoris','it':'❤️ Preferiti','tr':'❤️ Favoriler','pl':'❤️ Ulubione','ru':'❤️ Избранное','ar':'❤️ المفضلة'})),
            selected: _showFavorites, onSelected: (_) async { await _refresh(); if (mounted) setState(() => _showFavorites = true); })),
        ]),
      ),
      const SizedBox(height: 12),
      if (_showFavorites)
        Expanded(
          child: RefreshIndicator(
            onRefresh: _refresh,
            child: _favorites.isEmpty
                ? ListView(children: [
                    Padding(
                      padding: const EdgeInsets.only(top: 100),
                      child: Center(
                        child: Text(
                          appLang.ui(const {
                            'pt': 'Ainda não guardaste cantadas favoritas',
                            'en': 'No favorite lines yet',
                            'de': 'Noch keine Favoriten',
                            'es': 'Aún no hay favoritos',
                            'fr': 'Aucun favori',
                            'it': 'Nessun preferito',
                            'tr': 'Henüz favori yok',
                            'pl': 'Brak ulubionych',
                            'ru': 'Пока нет избранного',
                            'ar': 'لا توجد مفضلات بعد',
                          }),
                          style: TextStyle(color: fg),
                        ),
                      ),
                    ),
                  ])
                : ListView.builder(
                    padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
                    itemCount: _favorites.length,
                    itemBuilder: (context, i) => _favoriteCard(
                      _favorites[i], fg, dark,
                    ),
                  ),
          ),
        ),
      if (!_showFavorites) ...[
      Padding(padding: const EdgeInsets.symmetric(horizontal: 20), child: TextField(
        onChanged: (s) => setState(() => _search = s),
        decoration: InputDecoration(prefixIcon: const Icon(Icons.search), hintText: appLang.ui(const {'en': 'Search conversations', 'pt': 'Pesquisar conversas', 'de': 'Chats durchsuchen', 'es': 'Buscar conversaciones', 'fr': 'Rechercher des conversations', 'it': 'Cerca conversazioni', 'tr': 'Sohbetlerde ara', 'pl': 'Szukaj rozmów', 'ru': 'Поиск бесед', 'ar': 'البحث في المحادثات'}),
          filled: true, fillColor: dark ? Colors.white10 : Colors.white,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none)))),
      const SizedBox(height: 12),
      Expanded(child: RefreshIndicator(onRefresh: _refresh, child: matches.isEmpty
        ? ListView(children: [Padding(padding: const EdgeInsets.only(top: 110), child: Column(children: [
          Icon(Icons.chat_bubble_outline, size: 52, color: fg.withOpacity(.35)),
          const SizedBox(height: 12), Text(_chats.isEmpty ? appLang.ui(const {'en': 'No saved conversations yet', 'pt': 'Ainda não tens conversas guardadas', 'de': 'Noch keine gespeicherten Chats', 'es': 'Aún no tienes conversaciones guardadas', 'fr': 'Aucune conversation enregistrée', 'it': 'Nessuna conversazione salvata', 'tr': 'Henüz kayıtlı sohbet yok', 'pl': 'Brak zapisanych rozmów', 'ru': 'Сохранённых бесед пока нет', 'ar': 'لا توجد محادثات محفوظة بعد'}) : appLang.ui(const {'en': 'No conversations found', 'pt': 'Nenhuma conversa encontrada', 'de': 'Keine Chats gefunden', 'es': 'No se encontraron conversaciones', 'fr': 'Aucune conversation trouvée', 'it': 'Nessuna conversazione trovata', 'tr': 'Sohbet bulunamadı', 'pl': 'Nie znaleziono rozmów', 'ru': 'Беседы не найдены', 'ar': 'لم يتم العثور على محادثات'}),
            style: TextStyle(color: fg.withOpacity(.65))) ]))])
        : ListView.separated(itemCount: matches.length, separatorBuilder: (_, __) => const Divider(height: 1),
          itemBuilder: (ctx, i) {
            final chat = matches[i];
            return ListTile(contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 7),
              leading: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: SizedBox(width: 52, height: 52,
                  child: chat.imagePath != null && File(chat.imagePath!).existsSync()
                    ? Image.file(File(chat.imagePath!), fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => const Icon(Icons.chat_bubble_outline, color: Color(0xFFFF2D55)))
                    : Container(color: const Color(0xFFFF2D55).withOpacity(.12),
                        child: const Icon(Icons.chat_bubble_outline, color: Color(0xFFFF2D55))),
                ),
              ),
              title: Text(chat.title, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(color: fg, fontWeight: FontWeight.w600)),
              subtitle: Text(chat.replies.isEmpty ? '' : chat.replies.first, maxLines: 1, overflow: TextOverflow.ellipsis),
              onTap: () => _open(chat),
              trailing: PopupMenuButton<String>(onSelected: (action) => action == 'rename' ? _rename(chat) : _delete(chat),
                itemBuilder: (_) => [PopupMenuItem(value: 'rename', child: Text(appLang.ui(const {'en': 'Rename', 'pt': 'Renomear', 'de': 'Umbenennen', 'es': 'Renombrar', 'fr': 'Renommer', 'it': 'Rinomina', 'tr': 'Yeniden adlandır', 'pl': 'Zmień nazwę', 'ru': 'Переименовать', 'ar': 'إعادة تسمية'}))),
                  PopupMenuItem(value: 'delete', child: Text(appLang.ui(const {'en': 'Delete', 'pt': 'Eliminar', 'de': 'Löschen', 'es': 'Eliminar', 'fr': 'Supprimer', 'it': 'Elimina', 'tr': 'Sil', 'pl': 'Usuń', 'ru': 'Удалить', 'ar': 'حذف'})))]));
          }))),
      ],
    ])));
  }
}
