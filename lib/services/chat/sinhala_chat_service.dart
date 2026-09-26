import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:uuid/uuid.dart';

class SinhalaChatResponse {
  final String response;
  final String sessionId;
  final bool safeMessagingChecked;
  final bool crisisDetected;

  const SinhalaChatResponse({
    required this.response,
    required this.sessionId,
    required this.safeMessagingChecked,
    required this.crisisDetected,
  });

  factory SinhalaChatResponse.fromJson(Map<String, dynamic> json) {
    final response = json['response'];
    if (response is! String || response.isEmpty) {
      throw const FormatException('Server response missing "response".');
    }
    return SinhalaChatResponse(
      response: response,
      sessionId: (json['session_id'] as String?) ?? '',
      safeMessagingChecked: json['safe_messaging_checked'] as bool? ?? true,
      crisisDetected: json['crisis_detected'] as bool? ?? false,
    );
  }
}

class ChatTurn {
  final String role;
  final String content;
  const ChatTurn({required this.role, required this.content});
  Map<String, String> toJson() => {'role': role, 'content': content};
}

class SinhalaChatService {
  final String baseUrl;
  final String bearerToken;
  final http.Client _client;
  final List<ChatTurn> _history = [];
  static const int _maxTurns = 20;
  final String sessionId = const Uuid().v4();

  SinhalaChatService({
    required this.baseUrl,
    required this.bearerToken,
    http.Client? client,
  }) : _client = client ?? http.Client();

  List<ChatTurn> get history => List.unmodifiable(_history);

  void _addTurn(ChatTurn turn) {
    _history.add(turn);
    if (_history.length > _maxTurns) _history.removeAt(0);
  }

  Future<SinhalaChatResponse> sendMessage(String message) async {
    _addTurn(ChatTurn(role: 'user', content: message));
    final uri = Uri.parse('$baseUrl/chat');
    final body = jsonEncode({
      'session_id': sessionId,
      'message': message,
      'history': _history.sublist(0, _history.length - 1).map((t) => t.toJson()).toList(),
    });
    final response = await _client.post(
      uri,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $bearerToken',
      },
      body: body,
    ).timeout(const Duration(seconds: 10));

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final chatResponse = SinhalaChatResponse.fromJson(data);
      _addTurn(ChatTurn(role: 'assistant', content: chatResponse.response));
      return chatResponse;
    } else if (response.statusCode == 400) {
      throw Exception('Message too long. Please shorten your message.');
    } else if (response.statusCode == 401) {
      throw Exception('Authentication failed.');
    } else {
      throw Exception('Server error (${response.statusCode}). Please try again.');
    }
  }

  void clearHistory() => _history.clear();
  void dispose() => _client.close();
}
