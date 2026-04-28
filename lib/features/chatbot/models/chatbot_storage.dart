// chatbot_storage.dart
// Persistent storage for chat messages using SharedPreferences

import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'chatbot_models.dart';

class ChatStorageService {
  static const String _sessionKey = 'agriguard_chat_session';
  static const int _maxMessages = 200; // Keep last 200 messages

  /// Load saved messages from local storage
  static Future<List<ChatMessage>> loadMessages() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_sessionKey);
      if (raw == null || raw.isEmpty) return [];

      final json = jsonDecode(raw) as Map<String, dynamic>;
      final session = ChatSession.fromJson(json);
      return session.messages;
    } catch (e) {
      // If corrupted, clear and return empty
      await clearMessages();
      return [];
    }
  }

  /// Save messages to local storage
  static Future<void> saveMessages(List<ChatMessage> messages) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final toSave = messages.length > _maxMessages
          ? messages.sublist(messages.length - _maxMessages)
          : messages;
      final session = ChatSession(messages: toSave);
      await prefs.setString(_sessionKey, jsonEncode(session.toJson()));
    } catch (_) {
      // Silent fail — chat still works without persistence
    }
  }

  /// Append a single message (more efficient than re-saving all)
  static Future<void> appendMessage(ChatMessage message) async {
    final existing = await loadMessages();
    existing.add(message);
    await saveMessages(existing);
  }

  /// Clear all saved messages
  static Future<void> clearMessages() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_sessionKey);
    } catch (_) {}
  }

  /// Get message count
  static Future<int> getMessageCount() async {
    final messages = await loadMessages();
    return messages.length;
  }
}
