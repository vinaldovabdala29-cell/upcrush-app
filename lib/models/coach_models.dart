// ===============================================================
// COACH MODELS — usados na comunicação com o DatingCoachService
// ===============================================================
//
// Este ficheiro contém APENAS os modelos usados para falar com a
// API (dating_coach_service.dart).
//
// Para modelos de HISTÓRICO/PERSISTÊNCIA (guardar conversas no
// telemóvel), ver coach_history_service.dart — lá vivem
// CoachHistoryMessage e CoachConversation.
// ===============================================================

class CoachMessage {
  final String role;
  final String content;

  const CoachMessage({
    required this.role,
    required this.content,
  });

  factory CoachMessage.user(String content) {
    return CoachMessage(role: 'user', content: content);
  }

  factory CoachMessage.assistant(String content) {
    return CoachMessage(role: 'assistant', content: content);
  }
}

class CoachResponse {
  final String message;
  final String mode;
  final String datingStage;
  final String interestLevel;
  final String goal;
  final String nextStep;
  final bool shouldSendMessage;
  final String suggestedMessage;
  final String dateReadiness;

  const CoachResponse({
    required this.message,
    required this.mode,
    required this.datingStage,
    required this.interestLevel,
    required this.goal,
    required this.nextStep,
    required this.shouldSendMessage,
    required this.suggestedMessage,
    required this.dateReadiness,
  });

  factory CoachResponse.fromJson(Map<String, dynamic> json) {
    return CoachResponse(
      message: json['message']?.toString() ?? '',
      mode: json['mode']?.toString() ?? 'conversation',
      datingStage: json['dating_stage']?.toString() ?? 'unclear',
      interestLevel: json['interest_level']?.toString() ?? 'unclear',
      goal: json['goal']?.toString() ?? '',
      nextStep: json['next_step']?.toString() ?? '',
      shouldSendMessage: json['should_send_message'] == true,
      suggestedMessage: json['suggested_message']?.toString() ?? '',
      dateReadiness: json['date_readiness']?.toString() ?? 'unclear',
    );
  }
}