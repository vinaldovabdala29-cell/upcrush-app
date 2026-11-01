import 'tone_definition.dart';
import 'romantico_tone.dart';
import 'charmoso_tone.dart';
import 'engracado_tone.dart';
import 'picante_tone.dart';
import 'flertar_tone.dart';
import 'misterioso_tone.dart';
import 'toxico_tone.dart';

/// Ponto único de seleção. A chave antiga continua compatível.
class ToneRegistry {
  static const Map<String, ToneDefinition> _tones = {
    'romantico': tomRomantico,
    'charmoso': tomCharmoso,
    'engraçado': tomEngracado,
    'picante': tomPicante,
    'flertar': tomFlertar,
    'misterioso': tomMisterioso,
    'toxico': tomToxico,
  };

  static String normalize(String key) {
    final value = key.trim().toLowerCase();
    if (value == 'natural' || value == 'romântico') return 'romantico';
    if (value == 'direto') return 'flertar';
    if (value == 'engracado') return 'engraçado';
    if (value == 'tóxico') return 'toxico';
    return _tones.containsKey(value) ? value : 'romantico';
  }

  static ToneDefinition resolve(String key) => _tones[normalize(key)]!;
}
