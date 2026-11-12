import 'package:flutter/material.dart';

/// Ordem e rótulos partilhados pelos seletores de tom.
List<Map<String, dynamic>> toneOptions(String lang) => [
      {
        'key': 'natural',
        'label': lang == 'de' ? 'Natürlich 💬' : lang == 'fr' ? 'Naturel 💬' : lang == 'it' ? 'Naturale 💬' : lang == 'tr' ? 'Doğal 💬' : lang == 'ru' ? 'Естественный 💬' : lang == 'pl' ? 'Naturalny 💬' : lang == 'ar' ? 'طبيعي 💬' : 'Natural 💬',
        'icon': Icons.chat_bubble_outline_rounded,
        'colors': [const Color(0xFF34C759), const Color(0xFF70D78D)],
        'shadow': const Color(0xFF34C759),
      },
      {
        'key': 'romantico',
        'label': lang == 'de' ? 'Romantisch 💕' : lang == 'es' ? 'Romántico 💕' : lang == 'fr' ? 'Romantique 💕' : lang == 'pt' ? 'Romântico 💕' : lang == 'it' ? 'Romantico 💕' : lang == 'tr' ? 'Romantik 💕' : lang == 'ru' ? 'Романтичный 💕' : lang == 'pl' ? 'Romantyczny 💕' : lang == 'ar' ? 'رومانسي 💕' : 'Romantic 💕',
        'icon': Icons.favorite_rounded,
        'colors': [const Color(0xFFFF2D55), const Color(0xFFFF85A2)],
        'shadow': const Color(0xFFFF2D55),
      },
      {
        'key': 'engraçado',
        'label': lang == 'de'
            ? 'Lustig'
            : lang == 'es'
                ? 'Gracioso'
                : lang == 'fr'
                    ? 'Drôle'
                    : lang == 'pt'
                        ? 'Engraçado'
                        : lang == 'it'
                            ? 'Divertente'
                            : lang == 'tr'
                                ? 'Komik'
                                : lang == 'ru'
                                    ? 'Смешной'
                                    : 'Funny',
        'icon': Icons.sentiment_very_satisfied_rounded,
        'colors': [
          const Color(0xFFFF9500),
          const Color(0xFFFFCC02),
        ],
        'shadow': const Color(0xFFFF9500),
      },
      {
        'key': 'flertar',
        'label': lang == 'de'
            ? 'Flirten 💘'
            : lang == 'es'
                ? 'Coquetear 💘'
                : lang == 'fr'
                    ? 'Flirter 💘'
                    : lang == 'pt'
                        ? 'Flertar 💘'
                        : lang == 'it'
                            ? 'Flirtare 💘'
                            : lang == 'tr'
                                ? 'Flört 💘'
                                : lang == 'ru'
                                    ? 'Флирт 💘'
                                    : 'Flirt 💘',
        'icon': Icons.bolt_rounded,
        'colors': [
          const Color(0xFF007AFF),
          const Color(0xFF5AC8FA),
        ],
        'shadow': const Color(0xFF007AFF),
      },
      {
        'key': 'picante',
        'label': lang == 'de'
            ? 'Pikant'
            : lang == 'es'
                ? 'Picante'
                : lang == 'fr'
                    ? 'Piquant'
                    : lang == 'pt'
                        ? 'Picante'
                        : lang == 'it'
                            ? 'Piccante'
                            : lang == 'tr'
                                ? 'Ateşli'
                                : lang == 'ru'
                                    ? 'Пикантный'
                                    : 'Spicy',
        'icon': Icons.local_fire_department_rounded,
        'emoji': '😈',
        'colors': [
          const Color(0xFFFF2D55),
          const Color(0xFFFF6B81),
        ],
        'shadow': const Color(0xFFFF2D55),
      },
      {
        'key': 'misterioso',
        'label': lang == 'de'
            ? 'Mysteriös'
            : lang == 'es'
                ? 'Misterioso'
                : lang == 'fr'
                    ? 'Mystérieux'
                    : lang == 'pt'
                        ? 'Misterioso'
                        : lang == 'it'
                            ? 'Misterioso'
                            : lang == 'tr'
                                ? 'Gizemli'
                                : lang == 'ru'
                                    ? 'Загадочный'
                                    : 'Mysterious',
        'icon': Icons.nightlight_round,
        'colors': [
          const Color(0xFF5856D6),
          const Color(0xFFAF52DE),
        ],
        'shadow': const Color(0xFF5856D6),
      },
      {
        'key': 'toxico',
        'label': lang == 'de' ? 'Toxisch' : lang == 'es' ? 'Tóxico' : lang == 'fr' ? 'Toxique' : lang == 'pt' ? 'Tóxico' : lang == 'it' ? 'Tossico' : lang == 'tr' ? 'Toksik' : lang == 'ru' ? 'Токсичный' : 'Toxic',
        'icon': Icons.ac_unit_rounded,
        'colors': [const Color(0xFF5B6574), const Color(0xFF222831)],
        'shadow': const Color(0xFF5B6574),
      },
];
