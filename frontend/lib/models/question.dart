class Question {
  final int id;
  final int sessionId;
  final int participantId;
  final String participantName;
  final String questionText;
  final bool isAnonymous;
  final bool isAnswered;
  final String? answerText;
  final String? answeredBy;
  final DateTime createdAt;
  final DateTime? answeredAt;

  Question({
    required this.id,
    required this.sessionId,
    required this.participantId,
    required this.participantName,
    required this.questionText,
    this.isAnonymous = false,
    this.isAnswered = false,
    this.answerText,
    this.answeredBy,
    required this.createdAt,
    this.answeredAt,
  });

  factory Question.fromJson(Map<String, dynamic> json) {
    // Helper function to safely parse integer values
    int parseInt(dynamic value) {
      if (value == null) return 0;
      if (value is int) return value;
      if (value is String) return int.tryParse(value) ?? 0;
      return 0;
    }

    return Question(
      id: parseInt(json['id']),
      sessionId: parseInt(json['session_id'] ?? json['session']),
      participantId: parseInt(json['participant_id'] ?? json['participant']),
      participantName: (json['participant_name'] as String?) ?? 'Anonymous',
      questionText: (json['question_text'] ?? '') as String,
      isAnonymous: (json['is_anonymous'] ?? false) as bool,
      isAnswered: (json['is_answered'] ?? false) as bool,
      answerText: json['answer_text'] as String?,
      answeredBy: json['answered_by'] as String?,
      createdAt: json['created_at'] != null 
          ? DateTime.tryParse(json['created_at'].toString()) ?? DateTime.now()
          : DateTime.now(),
      answeredAt: json['answered_at'] != null 
          ? DateTime.tryParse(json['answered_at'].toString())
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'session_id': sessionId,
      'participant_id': participantId,
      'participant_name': participantName,
      'question_text': questionText,
      'is_anonymous': isAnonymous,
      'is_answered': isAnswered,
      'answer_text': answerText,
      'answered_by': answeredBy,
      'created_at': createdAt.toIso8601String(),
      'answered_at': answeredAt?.toIso8601String(),
    };
  }

  // Create a copyWith method for immutability
  Question copyWith({
    int? id,
    int? sessionId,
    int? participantId,
    String? participantName,
    String? questionText,
    bool? isAnonymous,
    bool? isAnswered,
    String? answerText,
    String? answeredBy,
    DateTime? createdAt,
    DateTime? answeredAt,
  }) {
    return Question(
      id: id ?? this.id,
      sessionId: sessionId ?? this.sessionId,
      participantId: participantId ?? this.participantId,
      participantName: participantName ?? this.participantName,
      questionText: questionText ?? this.questionText,
      isAnonymous: isAnonymous ?? this.isAnonymous,
      isAnswered: isAnswered ?? this.isAnswered,
      answerText: answerText ?? this.answerText,
      answeredBy: answeredBy ?? this.answeredBy,
      createdAt: createdAt ?? this.createdAt,
      answeredAt: answeredAt ?? this.answeredAt,
    );
  }
}
