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
    return SinhalaChatResponse(
      response: json['response'] as String,
      sessionId: json['session_id'] as String,
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
  String? _identifiedMood;
  int _userMessageCount = 0;

  SinhalaChatService({
    required this.baseUrl,
    required this.bearerToken,
    http.Client? client,
  }) : _client = client ?? http.Client();

  List<ChatTurn> get history => List.unmodifiable(_history);
  String? get identifiedMood => _identifiedMood;
  int get userMessageCount => _userMessageCount;

  void _addTurn(ChatTurn turn) {
    _history.add(turn);
    if (turn.role == 'user') {
      _userMessageCount++;
      if (_identifiedMood == null && _userMessageCount >= 5) {
        _identifyMoodFromHistory();
      }
    }
    if (_history.length > _maxTurns) _history.removeAt(0);
  }

  void _identifyMoodFromHistory() {
    final moodKeywords = <String, List<String>>{
      'anxiety': [
        'anxious',
        'anxiety',
        'panic',
        'worried',
        'nervous',
        'fear',
        'scared',
      ],
      'stress': [
        'stress',
        'stressed',
        'overwhelmed',
        'pressure',
        'too much',
        'burnout',
      ],
      'sad': [
        'sad',
        'sadness',
        'depressed',
        'unhappy',
        'down',
        'cry',
        'tears',
        'miserable',
      ],
      'tired': ['tired', 'exhausted', 'fatigue', 'sleepy', 'drained'],
      'angry': ['angry', 'mad', 'frustrated', 'annoyed', 'furious'],
      'lonely': ['lonely', 'alone', 'isolated'],
      'happy': ['happy', 'great', 'good', 'excited', 'joy'],
    };

    final scores = <String, int>{};
    for (final turn in _history.where((t) => t.role == 'user')) {
      final text = turn.content.toLowerCase();
      for (final entry in moodKeywords.entries) {
        for (final keyword in entry.value) {
          if (text.contains(keyword)) {
            scores[entry.key] = (scores[entry.key] ?? 0) + 1;
          }
        }
      }
    }

    if (scores.isNotEmpty) {
      _identifiedMood = scores.entries
          .reduce((a, b) => a.value > b.value ? a : b)
          .key;
    }
  }

  Future<SinhalaChatResponse> sendMessage(String message) async {
    _addTurn(ChatTurn(role: 'user', content: message));
    final uri = Uri.parse('$baseUrl/chat');
    final bodyMap = <String, dynamic>{
      'session_id': sessionId,
      'message': message,
      'history': _history
          .sublist(0, _history.length - 1)
          .map((t) => t.toJson())
          .toList(),
    };
    if (_identifiedMood != null && _userMessageCount >= 5) {
      bodyMap['mind_state'] = _identifiedMood;
      bodyMap['identified_mind_state'] = _identifiedMood;
      bodyMap['context'] =
          'USER_MIND_STATE: $_identifiedMood (identified after first $_userMessageCount messages)';
    }
    final body = jsonEncode(bodyMap);
    final response = await _client
        .post(
          uri,
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $bearerToken',
          },
          body: body,
        )
        .timeout(const Duration(seconds: 10));

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
      throw Exception(
        'Server error (${response.statusCode}). Please try again.',
      );
    }
  }

  void clearHistory() {
    _history.clear();
    _identifiedMood = null;
    _userMessageCount = 0;
  }

  void dispose() => _client.close();
}
