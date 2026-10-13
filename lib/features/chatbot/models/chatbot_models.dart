// chatbot_models.dart
// Data models for the AgriGuard chatbot

class ChatMessage {
  final String id;
  final String role;
  final String content;
  final DateTime timestamp;
  final String? imagePath;
  final MessageStatus status;

  ChatMessage({
    String? id,
    required this.role,
    required this.content,
    required this.timestamp,
    this.imagePath,
    this.status = MessageStatus.sent,
  }) : id = id ?? DateTime.now().microsecondsSinceEpoch.toString();

  ChatMessage copyWith({
    String? role,
    String? content,
    DateTime? timestamp,
    String? imagePath,
    MessageStatus? status,
  }) {
    return ChatMessage(
      id: id,
      role: role ?? this.role,
      content: content ?? this.content,
      timestamp: timestamp ?? this.timestamp,
      imagePath: imagePath ?? this.imagePath,
      status: status ?? this.status,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'role': role,
        'content': content,
        'timestamp': timestamp.toIso8601String(),
        'imagePath': imagePath,
        'status': status.index,
      };

  factory ChatMessage.fromJson(Map<String, dynamic> json) => ChatMessage(
        id: json['id'] as String?,
        role: json['role'] as String,
        content: json['content'] as String,
        timestamp: DateTime.parse(json['timestamp'] as String),
        imagePath: json['imagePath'] as String?,
        status: MessageStatus.values[json['status'] as int? ?? 0],
      );
}

enum MessageStatus { sending, sent, error }

class ChatSession {
  final String id;
  final DateTime createdAt;
  final List<ChatMessage> messages;

  ChatSession({
    String? id,
    DateTime? createdAt,
    List<ChatMessage>? messages,
  })  : id = id ?? DateTime.now().millisecondsSinceEpoch.toString(),
        createdAt = createdAt ?? DateTime.now(),
        messages = messages ?? [];

  Map<String, dynamic> toJson() => {
        'id': id,
        'createdAt': createdAt.toIso8601String(),
        'messages': messages.map((m) => m.toJson()).toList(),
      };

  factory ChatSession.fromJson(Map<String, dynamic> json) => ChatSession(
        id: json['id'] as String?,
        createdAt: DateTime.parse(json['createdAt'] as String),
        messages: (json['messages'] as List<dynamic>)
            .map((m) => ChatMessage.fromJson(m as Map<String, dynamic>))
            .toList(),
      );
}
