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
