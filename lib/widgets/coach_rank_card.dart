import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Progress is self-reported practice, never a score of romantic success.
class CoachChallenge {
  final String id, pt, en;
  const CoachChallenge(this.id, this.pt, this.en);
}

const coachChallenges = <CoachChallenge>[
  CoachChallenge(
    'intro',
    'Pratica uma apresentação curta em voz alta.',
    'Practise a short introduction out loud.',
  ),
  CoachChallenge(
    'detail',
    'Escreve uma abertura a partir de um detalhe real de um perfil.',
    'Write an opener based on a real profile detail.',
  ),
  CoachChallenge(
    'listen',
    'Pratica uma pergunta de continuação ligada ao que alguém disse.',
    'Practise a follow-up question about something someone said.',
  ),
  CoachChallenge(
    'chat',
    'Experimenta uma abertura no chat e reflete sobre como correu.',
    'Try a chat opener and reflect on how it went.',
  ),
  CoachChallenge(
    'pause',
    'Pratica uma abordagem presencial num momento apropriado, ou ensaia em voz alta.',
    'Try an in-person approach at a suitable moment, or rehearse out loud.',
  ),
  CoachChallenge(
    'compliment',
    'Cria um elogio específico e sincero, sem copiar uma frase pronta.',
    'Create a specific, sincere compliment in your own words.',
  ),
  CoachChallenge(
    'romance',
    'Transforma um detalhe real numa frase romântica curta.',
    'Turn a real detail into a short romantic line.',
  ),
  CoachChallenge(
    'story',
    'Conta em voz alta uma pequena história tua em três frases.',
    'Tell a small story about yourself out loud in three sentences.',
  ),
  CoachChallenge(
    'invite',
    'Prepara um convite com uma atividade e um dia, sem pressão.',
    'Prepare a low-pressure invitation with an activity and a day.',
  ),
  CoachChallenge(
    'space',
    'Pratica como dar espaço quando alguém não quer continuar.',
    'Practise giving someone space when they do not want to continue.',
  ),
  CoachChallenge(
    'followup',
    'Escreve uma mensagem depois de um encontro usando um detalhe partilhado, real ou de um ensaio.',
    'Write a post-date message using a shared detail from a real date or a rehearsal.',
  ),
  CoachChallenge(
    'reflect',
    'Escolhe uma dica que praticaste e explica o que mudarias na próxima vez.',
    'Choose a tip you practised and explain what you would change next time.',
  ),
];

class CoachProgress {
  final Map<String, String> completed;
  CoachProgress(Map<String, String> entries)
    : completed = Map.unmodifiable(entries);
  int get xp =>
      completed.keys
          .where((id) => coachChallenges.any((c) => c.id == id))
          .length *
      25;
  static const thresholds = [0, 50, 125, 225, 300];
  int get level => thresholds.lastIndexWhere((value) => xp >= value);
  bool get finished => level == thresholds.length - 1;
  double get fraction => finished
      ? 1
      : (xp - thresholds[level]) / (thresholds[level + 1] - thresholds[level]);
  CoachChallenge? get next {
    for (final challenge in coachChallenges) {
      if (!completed.containsKey(challenge.id)) return challenge;
    }
    return null;
  }
}

class CoachProgressStore {
  static const key = 'upcrush_coach_practice_v1';
  static Future<void>? _tail;

  static Future<CoachProgress> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(key);
    if (raw == null) return CoachProgress({});
    final decoded = jsonDecode(raw) as Map<String, dynamic>;
    return CoachProgress(
      decoded.map((key, value) => MapEntry(key, value as String)),
    );
  }

  static Future<CoachProgress> complete(String id, String reflection) {
    final task = (_tail ?? Future<void>.value()).then((_) async {
      final current = await load();
      if (current.completed.containsKey(id)) return current;
      if (current.next?.id != id) throw StateError('Challenge is not unlocked');
      final text = reflection.trim();
      if (text.length < 8 || text.length > 240)
        throw ArgumentError('Invalid reflection');
      final updated = CoachProgress({...current.completed, id: text});
      final prefs = await SharedPreferences.getInstance();
      final saved = await prefs.setString(key, jsonEncode(updated.completed));
      if (!saved) throw StateError('Progress was not saved');
      return updated;
    });
    final barrier = task.then<void>(
      (_) {},
      onError: (Object _, StackTrace __) {},
    );
    _tail = barrier;
    return task.whenComplete(() {
      if (identical(_tail, barrier)) _tail = null;
    });
  }
}

class CoachRankCard extends StatefulWidget {
  final String lang;
  const CoachRankCard({super.key, required this.lang});
  @override
  State<CoachRankCard> createState() => _CoachRankCardState();
}

class _CoachRankCardState extends State<CoachRankCard> {
  CoachProgress? _progress;
  bool _failed = false;
  String _t(String pt, String en) => widget.lang.startsWith('pt') ? pt : en;
  String _name(int level) => _t(
    [
      'Primeiro passo',
      'Quebra-gelo',
      'Bom de papo',
      'Encantador',
      'Mestre do charme',
    ][level],
    [
      'First step',
      'Icebreaker',
      'Smooth talker',
      'Charmer',
      'Master of charm',
    ][level],
  );
  static const _emoji = ['🌱', '💬', '😉', '💘', '👑'];
  static const _accent = Color(0xFFFF2D55);

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final progress = await CoachProgressStore.load();
      if (mounted)
        setState(() {
          _progress = progress;
          _failed = false;
        });
    } catch (_) {
      if (mounted) setState(() => _failed = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final progress = _progress;
    if (progress == null && !_failed) return const SizedBox.shrink();
    if (_failed) {
      return TextButton(
        onPressed: _load,
        child: Text(
          _t('Tentar carregar o progresso', 'Retry loading progress'),
        ),
      );
    }
    final p = progress!;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 6),
      child: Material(
        color: _accent.withValues(alpha: .07),
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          key: const Key('coach-rank-open'),
          borderRadius: BorderRadius.circular(16),
          onTap: _openProgress,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            child: Row(
              children: [
                AnimatedSwitcher(
                  duration: MediaQuery.disableAnimationsOf(context)
                      ? Duration.zero
                      : const Duration(milliseconds: 450),
                  transitionBuilder: (child, animation) =>
                      ScaleTransition(scale: animation, child: child),
                  child: Text(
                    _emoji[p.level],
                    key: ValueKey(p.level),
                    style: const TextStyle(fontSize: 25),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _name(p.level),
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 5),
                      TweenAnimationBuilder<double>(
                        tween: Tween(end: p.fraction),
                        duration: MediaQuery.disableAnimationsOf(context)
                            ? Duration.zero
                            : const Duration(milliseconds: 650),
                        builder: (context, value, _) => LinearProgressIndicator(
                          value: value,
                          color: _accent,
                          backgroundColor: _accent.withValues(alpha: .12),
                          borderRadius: BorderRadius.circular(8),
                          minHeight: 4,
                          semanticsLabel: _t(
                            'Progresso do rank',
                            'Rank progress',
                          ),
                          semanticsValue: '${(p.fraction * 100).round()}',
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                Text(
                  '${p.xp} XP',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Icon(Icons.chevron_right, size: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _openProgress() async {
    FocusManager.instance.primaryFocus?.unfocus();
    final controller = TextEditingController();
    var saving = false;
    String? error;
    var p = _progress!;
    try {
      await showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        useSafeArea: true,
        showDragHandle: true,
        builder: (sheetContext) => StatefulBuilder(
          builder: (context, updateSheet) {
            final challenge = p.next;
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.viewInsetsOf(context).bottom,
              ),
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${_emoji[p.level]} ${_name(p.level)}',
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      p.finished
                          ? _t(
                              'Percurso concluído. Continua a praticar ao teu ritmo.',
                              'Path completed. Keep practising at your own pace.',
                            )
                          : _t(
                              '${p.xp} XP · Faltam ${CoachProgress.thresholds[p.level + 1] - p.xp} para ${_name(p.level + 1)}',
                              '${p.xp} XP · ${CoachProgress.thresholds[p.level + 1] - p.xp} to ${_name(p.level + 1)}',
                            ),
                    ),
                    const SizedBox(height: 16),
                    Wrap(
                      spacing: 8,
                      runSpacing: 6,
                      children: List.generate(
                        5,
                        (i) => Chip(
                          avatar: Icon(
                            i <= p.level
                                ? Icons.check_circle
                                : Icons.lock_outline,
                            size: 16,
                            color: i <= p.level ? _accent : null,
                          ),
                          label: Text('${_emoji[i]} ${_name(i)}'),
                        ),
                      ),
                    ),
                    const SizedBox(height: 18),
                    if (challenge != null) ...[
                      Text(
                        _t(
                          'Próximo desafio · +25 XP',
                          'Next challenge · +25 XP',
                        ),
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      Text(_t(challenge.pt, challenge.en)),
                      const SizedBox(height: 12),
                      TextField(
                        key: const Key('coach-rank-reflection'),
                        controller: controller,
                        enabled: !saving,
                        minLines: 2,
                        maxLines: 3,
                        maxLength: 240,
                        decoration: InputDecoration(
                          labelText: _t(
                            'O que praticaste ou aprendeste?',
                            'What did you practise or learn?',
                          ),
                          helperText: _t(
                            'Não precisas de partilhar nomes ou mensagens privadas.',
                            'No names or private messages needed.',
                          ),
                          helperMaxLines: 2,
                          errorText: error,
                          border: const OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 8),
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton.icon(
                          key: const Key('coach-rank-complete'),
                          icon: const Icon(Icons.check),
                          label: Text(
                            _t(
                              'Concluí o desafio',
                              'I completed the challenge',
                            ),
                          ),
                          onPressed: saving
                              ? null
                              : () async {
                                  if (controller.text.trim().length < 8) {
                                    updateSheet(
                                      () => error = _t(
                                        'Conta brevemente o que praticaste.',
                                        'Briefly describe what you practised.',
                                      ),
                                    );
                                    return;
                                  }
                                  updateSheet(() {
                                    saving = true;
                                    error = null;
                                  });
                                  try {
                                    final before = p.level;
                                    final result =
                                        await CoachProgressStore.complete(
                                          challenge.id,
                                          controller.text,
                                        );
                                    if (!mounted) return;
                                    setState(() => _progress = result);
                                    if (!sheetContext.mounted) return;
                                    controller.clear();
                                    updateSheet(() {
                                      p = result;
                                      saving = false;
                                    });
                                    if (result.level > before) {
                                      Navigator.of(sheetContext).pop();
                                      _celebrate(result.level);
                                    } else {
                                      ScaffoldMessenger.of(
                                        this.context,
                                      ).showSnackBar(
                                        SnackBar(
                                          content: Text(
                                            _t(
                                              '+25 XP · Desafio concluído',
                                              '+25 XP · Challenge completed',
                                            ),
                                          ),
                                        ),
                                      );
                                    }
                                  } catch (_) {
                                    if (sheetContext.mounted)
                                      updateSheet(() {
                                        saving = false;
                                        error = _t(
                                          'Não foi possível guardar. Tenta novamente.',
                                          'Could not save. Try again.',
                                        );
                                      });
                                  }
                                },
                        ),
                      ),
                    ],
                    const SizedBox(height: 12),
                    Text(
                      _t(
                        'O rank acompanha os desafios que confirmas ter praticado, não o interesse de outra pessoa. Progresso guardado neste dispositivo.',
                        'Your rank tracks practice you confirm, not another person’s interest. Progress is saved on this device.',
                      ),
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      );
    } finally {
      // The route may still be reversing its animation when its future completes.
      await Future<void>.delayed(const Duration(milliseconds: 500));
      controller.dispose();
    }
  }

  void _celebrate(int level) {
    final reduced = MediaQuery.disableAnimationsOf(context);
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TweenAnimationBuilder<double>(
              tween: Tween(begin: reduced ? 1 : .65, end: 1),
              duration: reduced
                  ? Duration.zero
                  : const Duration(milliseconds: 650),
              curve: Curves.easeOutBack,
              builder: (_, scale, child) =>
                  Transform.scale(scale: scale, child: child),
              child: Text(_emoji[level], style: const TextStyle(fontSize: 64)),
            ),
            const SizedBox(height: 12),
            Text(
              _t('Novo rank!', 'New rank!'),
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            Text(_name(level)),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(_t('Continuar', 'Continue')),
          ),
        ],
      ),
    );
  }
}
