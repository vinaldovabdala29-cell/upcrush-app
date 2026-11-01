/// Contrato de dados. Não contém nem acrescenta instruções de personalidade.
class ToneDefinition {
  final String key;
  final String systemPrompt;
  final int maxWords;

  const ToneDefinition({
    required this.key,
    required this.systemPrompt,
    required this.maxWords,
  });

  bool accepts(String text) {
    final value = text.trim();
    return value.isNotEmpty &&
        value.split(RegExp(r'\s+')).length <= maxWords;
  }
}
