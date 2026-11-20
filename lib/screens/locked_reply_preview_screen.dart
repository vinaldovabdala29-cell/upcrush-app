import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../main.dart';
import '../services/response_paywall_gate.dart';

/// Shown only when a non-subscriber dismisses the first paywall.
/// Returns a direction string on purchase; null on back/close.
class LockedReplyPreviewScreen extends StatefulWidget {
  final File? image;
  const LockedReplyPreviewScreen({super.key, this.image});
  @override
  State<LockedReplyPreviewScreen> createState() => _LockedReplyPreviewScreenState();
}

class _LockedReplyPreviewScreenState extends State<LockedReplyPreviewScreen> {
  final _direction = TextEditingController();
  bool _busy = false;

  static const _addScreenshotLabels = <String, String>{
    'en': 'Add screenshot', 'pt': 'Adicionar screenshot', 'de': 'Screenshot hinzufügen',
    'es': 'Añadir captura', 'fr': 'Ajouter une capture', 'it': 'Aggiungi screenshot',
    'tr': 'Ekran görüntüsü ekle', 'pl': 'Dodaj zrzut ekranu',
    'ru': 'Добавить скриншот', 'ar': 'إضافة لقطة شاشة',
  };

  static const _translations = <String, List<String>>{
    'pt': ['Nunca fiques sem saber o que dizer', 'Respostas que combinam com a situação e personalidade', 'Como queres orientar a resposta? (opcional)', 'Desbloquear Rizz Infinito', 'Melhore suas habilidades sociais'],
    'en': ['Never run out of things to say', 'Replies that match the situation and personality', 'How should the reply sound? (optional)', 'Unlock Infinite Rizz', 'Improve your social life'],
    'de': ['Wisse immer, was du sagen kannst', 'Antworten passend zur Situation und Persönlichkeit', 'Wie soll die Antwort klingen? (optional)', 'Unbegrenzten Rizz freischalten', 'Verbessere dein Sozialleben'],
    'es': ['Nunca te quedes sin saber qué decir', 'Respuestas según la situación y personalidad', '¿Cómo quieres orientar la respuesta? (opcional)', 'Desbloquear Rizz infinito', 'Mejora tu vida social'],
    'fr': ['Ne manque jamais de mots', 'Des réponses adaptées à la situation et à la personnalité', 'Quel ton souhaites-tu ? (facultatif)', 'Débloquer le Rizz illimité', 'Améliore ta vie sociale'],
    'it': ['Non restare mai senza parole', 'Risposte adatte alla situazione e alla personalità', 'Come vuoi impostare la risposta? (facoltativo)', 'Sblocca Rizz illimitato', 'Migliora la tua vita sociale'],
    'tr': ['Ne söyleyeceğini asla şaşırma', 'Duruma ve kişiliğe uygun yanıtlar', 'Yanıt nasıl olsun? (isteğe bağlı)', 'Sınırsız Rizz kilidini aç', 'Sosyal hayatını geliştir'],
    'pl': ['Zawsze wiedz, co powiedzieć', 'Odpowiedzi dopasowane do sytuacji i osobowości', 'Jaki ma być ton odpowiedzi? (opcjonalnie)', 'Odblokuj nieskończony Rizz', 'Popraw swoje życie towarzyskie'],
    'ru': ['Всегда знай, что сказать', 'Ответы с учётом ситуации и характера', 'Какой должна быть реакция? (необязательно)', 'Открыть безлимитный Rizz', 'Улучши свою социальную жизнь'],
    'ar': ['اعرف دائمًا ماذا تقول', 'ردود تناسب الموقف والشخصية', 'كيف تريد أن يكون الرد؟ (اختياري)', 'افتح ريز بلا حدود', 'حسّن حياتك الاجتماعية'],
  };

  @override
  void dispose() { _direction.dispose(); super.dispose(); }

  Future<void> _unlock() async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      final allowed = await ResponsePaywallGate.allow(context, returnOnDismiss: false);
      if (!mounted) return;
      if (allowed) Navigator.of(context).pop(_direction.text.trim());
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _chooseAnotherScreenshot() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery);
    if (picked == null || !mounted) return;
    setState(() => _selectedImage = File(picked.path));
  }

  File? _selectedImage;

  @override
  void initState() {
    super.initState();
    _selectedImage = widget.image;
  }

  @override
  Widget build(BuildContext context) => ValueListenableBuilder(
    valueListenable: appLangNotifier,
    builder: (context, locale, _) {
      final t = _translations[locale.languageCode] ?? _translations['en']!;
      const accent = Color(0xFFFF2D55);
      return Scaffold(
        backgroundColor: const Color(0xFFF5F2F6),
        resizeToAvoidBottomInset: true,
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(18, 8, 18, 18),
            child: Column(children: [
              Row(children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 27),
                  color: Colors.black,
                  tooltip: MaterialLocalizations.of(context).backButtonTooltip,
                  onPressed: () => Navigator.of(context).pop(),
                ),
                Expanded(child: Center(child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: RichText(text: const TextSpan(children: [
                    TextSpan(text: 'Up', style: TextStyle(
                      fontSize: 35, fontWeight: FontWeight.w900,
                      color: Color(0xFF1C1C1E), letterSpacing: -1.4)),
                    TextSpan(text: 'Crush AI', style: TextStyle(
                      fontSize: 35, fontWeight: FontWeight.w900,
                      color: Color(0xFFFF2D55), letterSpacing: -1.4)),
                  ])),
                ))),
                IconButton(
                  icon: const Icon(Icons.add_rounded, size: 34),
                  color: Colors.black,
                  tooltip: _addScreenshotLabels[locale.languageCode] ?? _addScreenshotLabels['en']!,
                  onPressed: _chooseAnotherScreenshot,
                ),
              ]),
              const SizedBox(height: 14),
              // Keep the screenshot at its natural aspect ratio. The previous
              // full-height black Container created empty bands around it.
              Flexible(
                fit: FlexFit.loose,
                child: _selectedImage == null
                    ? const Icon(Icons.image_outlined,
                        color: Colors.black38, size: 56)
                    : Image.file(
                        _selectedImage!,
                        fit: BoxFit.contain,
                        alignment: Alignment.topCenter,
                        errorBuilder: (_, __, ___) =>
                            const Icon(Icons.broken_image_outlined,
                                color: Colors.black38, size: 48),
                      ),
              ),
              const SizedBox(height: 20),
              TextField(
                controller: _direction,
                maxLength: 140,
                maxLines: 1,
                textInputAction: TextInputAction.done,
                style: const TextStyle(color: Colors.black87),
                decoration: InputDecoration(
                  counterText: '',
                  hintText: t[2],
                  hintStyle: const TextStyle(color: Color(0xFFAAAAAF), fontSize: 14),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(35),
                    borderSide: BorderSide.none,
                  ),
                ),
                onSubmitted: (_) => _unlock(),
              ),
              const SizedBox(height: 24),
              Row(children: [
                Material(
                  color: Colors.black,
                  shape: const CircleBorder(),
                  child: InkWell(
                    customBorder: const CircleBorder(),
                    onTap: _busy ? null : _unlock,
                    child: const SizedBox(width: 60, height: 60,
                      child: Icon(Icons.bolt_rounded, color: Color(0xFFFFC247), size: 32)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(child: SizedBox(
                  height: 60,
                  child: ElevatedButton(
                    onPressed: _busy ? null : _unlock,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: Colors.black,
                      elevation: 0,
                      shape: const StadiumBorder(),
                    ),
                    child: _busy
                      ? const SizedBox(width: 22, height: 22,
                          child: CircularProgressIndicator(strokeWidth: 2, color: accent))
                      : Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                          Flexible(child: Text(t[3], maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800))),
                          const SizedBox(width: 7),
                          const Icon(Icons.lock_outline_rounded, size: 21),
                        ]),
                  ),
                )),
              ]),
            ]),
          ),
        ),
      );
    },
  );
}
