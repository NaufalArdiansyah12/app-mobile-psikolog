class ChatMessage {
  final String role; // 'user' atau 'assistant'
  final String content;
  final DateTime timestamp;
  final bool isCrisis;

  ChatMessage({
    required this.role,
    required this.content,
    DateTime? timestamp,
    this.isCrisis = false,
  }) : timestamp = timestamp ?? DateTime.now();

  Map<String, dynamic> toJson() => {
        'role': role,
        'content': content,
      };

  factory ChatMessage.fromJson(Map<String, dynamic> json) => ChatMessage(
        role: json['role'] ?? 'assistant',
        content: json['content'] ?? '',
        isCrisis: json['is_crisis'] ?? false,
      );
}

class ChatAnalysisResult {
  final int distressScore;
  final String distressLevel;
  final List<String> dominantEmotions;
  final List<String> cognitiveDistortions;
  final String summary;
  final String cbtInsights;
  final List<String> actionRecommendations;

  ChatAnalysisResult({
    required this.distressScore,
    required this.distressLevel,
    required this.dominantEmotions,
    required this.cognitiveDistortions,
    required this.summary,
    required this.cbtInsights,
    required this.actionRecommendations,
  });

  Map<String, dynamic> toJson() => {
        'distress_score': distressScore,
        'distress_level': distressLevel,
        'dominant_emotions': dominantEmotions,
        'cognitive_distortions': cognitiveDistortions,
        'summary': summary,
        'cbt_insights': cbtInsights,
        'action_recommendations': actionRecommendations,
      };

  factory ChatAnalysisResult.fromJson(Map<String, dynamic> json) =>
      ChatAnalysisResult(
        distressScore: json['distress_score'] ?? 4,
        distressLevel: json['distress_level'] ?? 'Sedang',
        dominantEmotions: List<String>.from(json['dominant_emotions'] ?? []),
        cognitiveDistortions: List<String>.from(json['cognitive_distortions'] ?? []),
        summary: json['summary'] ?? '',
        cbtInsights: json['cbt_insights'] ?? '',
        actionRecommendations: List<String>.from(json['action_recommendations'] ?? []),
      );
}

class ChatSession {
  final String id;
  final DateTime createdAt;
  final List<ChatMessage> messages;
  final ChatAnalysisResult? analysis;

  ChatSession({
    required this.id,
    required this.messages,
    DateTime? createdAt,
    this.analysis,
  }) : createdAt = createdAt ?? DateTime.now();

  // Judul otomatis dari pesan user pertama
  String get title {
    final firstUser = messages.firstWhere(
      (m) => m.role == 'user',
      orElse: () => ChatMessage(role: 'user', content: 'Sesi Chat'),
    );
    final text = firstUser.content;
    return text.length > 50 ? '${text.substring(0, 50)}...' : text;
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'created_at': createdAt.toIso8601String(),
        'messages': messages.map((m) => {
          'role': m.role,
          'content': m.content,
          'is_crisis': m.isCrisis,
          'timestamp': m.timestamp.toIso8601String(),
        }).toList(),
        'analysis': analysis?.toJson(),
      };

  factory ChatSession.fromJson(Map<String, dynamic> json) => ChatSession(
        id: json['id'] ?? '',
        createdAt: json['created_at'] != null
            ? DateTime.parse(json['created_at'])
            : DateTime.now(),
        messages: (json['messages'] as List? ?? []).map((m) {
          return ChatMessage(
            role: m['role'] ?? 'user',
            content: m['content'] ?? '',
            isCrisis: m['is_crisis'] ?? false,
            timestamp: m['timestamp'] != null ? DateTime.parse(m['timestamp']) : null,
          );
        }).toList(),
        analysis: json['analysis'] != null
            ? ChatAnalysisResult.fromJson(json['analysis'])
            : null,
      );
}

class MoodEntry {
  final String id;
  final int score; // 1 - 5
  final String label;
  final List<String> triggers;
  final String? notes;
  final DateTime timestamp;

  MoodEntry({
    required this.id,
    required this.score,
    required this.label,
    required this.triggers,
    this.notes,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();

  Map<String, dynamic> toJson() => {
        'id': id,
        'score': score,
        'label': label,
        'triggers': triggers,
        'notes': notes,
        'timestamp': timestamp.toIso8601String(),
      };

  factory MoodEntry.fromJson(Map<String, dynamic> json) => MoodEntry(
        id: json['id'] ?? '',
        score: json['score'] ?? 3,
        label: json['label'] ?? 'Netral',
        triggers: List<String>.from(json['triggers'] ?? []),
        notes: json['notes'],
        timestamp: json['timestamp'] != null
            ? DateTime.parse(json['timestamp'])
            : DateTime.now(),
      );
}
