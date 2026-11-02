import 'dart:io';
import 'package:flutter/material.dart';
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

  @override
  Widget build(BuildContext context) => ValueListenableBuilder(
    valueListenable: appLangNotifier,
    builder: (context, locale, _) {
      final t = _translations[locale.languageCode] ?? _translations['en']!;
      return Scaffold(
        backgroundColor: const Color(0xFFF3F3F7),
        appBar: AppBar(
          backgroundColor: const Color(0xFFF3F3F7),
          foregroundColor: const Color(0xFF1D1D1F),
          elevation: 0,
          centerTitle: true,
          title: const Text('UpCrush AI', style: TextStyle(fontWeight: FontWeight.w900, color: Colors.black)),
        ),
        body: SafeArea(child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
          child: Column(children: [
            Expanded(child: SingleChildScrollView(child: Column(children: [
              if (widget.image != null) ClipRRect(borderRadius: BorderRadius.circular(18),
                child: ConstrainedBox(constraints: const BoxConstraints(maxHeight: 250),
                  child: Image.file(widget.image!, fit: BoxFit.contain,
                    errorBuilder: (_, __, ___) => const SizedBox.shrink()))),
              const SizedBox(height: 22),
              _benefit(t[4]),
              const SizedBox(height: 16),
              _benefit(t[0]),
              const SizedBox(height: 16),
              _benefit(t[1]),
              const SizedBox(height: 22),
              TextField(controller: _direction, maxLength: 140, maxLines: 2,
                style: const TextStyle(color: Color(0xFF1D1D1F)),
                decoration: InputDecoration(hintText: t[2], hintStyle: const TextStyle(color: Color(0xFF777780)),
                  filled: true, fillColor: Colors.white,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none))),
            ]))),
            const SizedBox(height: 12),
            Row(children: [
              const CircleAvatar(backgroundColor: Colors.black,
                child: Icon(Icons.bolt, color: Color(0xFFFFD54F))),
              const SizedBox(width: 10),
              Expanded(child: FilledButton.icon(onPressed: _busy ? null : _unlock,
                icon: const Icon(Icons.lock_outline),
                style: FilledButton.styleFrom(backgroundColor: const Color(0xFFF04461), foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 17)),
                label: Text(t[3], textAlign: TextAlign.center,
                  style: const TextStyle(fontWeight: FontWeight.bold)))),
            ]),
          ]),
        )),
      );
    },
  );

  Widget _benefit(String text) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 8),
    child: Text(
      text,
      textAlign: TextAlign.center,
      style: const TextStyle(
        color: Color(0xFF1D1D1F),
        fontWeight: FontWeight.w700,
        fontSize: 18,
      ),
    ),
  );
}
