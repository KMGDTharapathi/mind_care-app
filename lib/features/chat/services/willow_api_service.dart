import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

/// A Willow reply: the message text plus any recommended wellness features.
class WillowChatResult {
  final String text;
  final List<String> recommendations;

  const WillowChatResult({required this.text, this.recommendations = const []});
}

/// Calls Google Gemini (gemini-3.8-flash) directly from the app.
///
/// A Sinhala-first mental-health persona ("Willow") is enforced through the
/// system prompt inside the API call. Crisis and very positive messages are
/// short-circuited locally for speed and safety. If Gemini is unreachable or
/// overloaded, a curated in-app reply is returned so the chat always responds.
class WillowApiService {
  static const String _apiKey = String.fromEnvironment('GEMINI_API_KEY');
  static final Uri _endpoint = Uri.parse(
    'https://generativelanguage.googleapis.com/v1beta/models/'
    'gemini-3.8-flash:generateContent',
  );

  static String _baseUrl =
      'https://paint-assurance-humanitarian-amanda.trycloudflare.com';
  static bool _serverMode = false;

  /// Connect to a model server (e.g. the Kaggle notebook via tunnel). When set,
  /// hosted replies are used first; Gemini/curated replies remain the fallback.
  static void setBaseUrl(String url) {
    _baseUrl = url.endsWith('/') ? url.substring(0, url.length - 1) : url;
    _serverMode = true;
  }

  static String get baseUrl => _baseUrl;

  /// Always true: the in-app Willow brain (server, Gemini or curated) can reply.
  static bool get isConfigured => true;

  /// Send a message to Willow and get a response. Never returns null when
  /// configured. Order: hosted model server (if set) -> Gemini -> curated.
  static Future<WillowChatResult?> chat(String message) async {
    if (!isConfigured) return null;

    if (_serverMode) {
      final hosted = await _callServer(message);
      if (hosted != null) return hosted;
      debugPrint('Hosted server unavailable, falling back to in-app brain');
    }

    final q = _normalize(message);
    final isSi = _looksSinhala(q);

    if ((isSi ? _crisisSignals : _crisisSignalsEn).any(q.contains)) {
      return WillowChatResult(
        text: isSi ? _crisisReply : _crisisReplyEn,
        recommendations: const ['counsellorCall', 'findDoctor'],
      );
    }

    if ((isSi ? _positiveSignals : _positiveSignalsEn).any(q.contains)) {
      return WillowChatResult(
        text: isSi ? _positiveReply : _positiveReplyEn,
      );
    }

    final topic = _pickTopic(q, isSi);
    final recs = topic == null
        ? const <String>[]
        : _topicRecs[topic] ?? const <String>[];

    String text = _curatedReply(topic, q, isSi);
    if (_apiKey.isNotEmpty) {
      try {
        text = await _callGemini(message).timeout(const Duration(seconds: 90));
        if (text.trim().isEmpty) throw Exception('empty Gemini reply');
        text = text.trim();
      } catch (e) {
        debugPrint('Gemini unavailable, using curated reply: $e');
        text = _curatedReply(topic, q, isSi);
      }
    }
    debugPrint('Willow topic=$topic sinhala=$isSi gemini=${_apiKey.isNotEmpty}');
    return WillowChatResult(text: text, recommendations: recs);
  }

  /// Check the (legacy) server is alive; kept for compatibility.
  static Future<bool> healthCheck() async {
    if (!isConfigured) return false;
    try {
      final response = await http
          .get(
            Uri.parse('$_baseUrl/health'),
            headers: {
              'cf-access-client-id': 'bypass',
              'User-Agent': 'MindCareApp/1.0',
            },
          )
          .timeout(const Duration(seconds: 10));
      return response.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  /// Ask the hosted model server (Kaggle notebook via tunnel) for a reply.
  static Future<WillowChatResult?> _callServer(String message) async {
    try {
      final response = await http
          .post(
            Uri.parse('$_baseUrl/chat'),
            headers: {
              'Content-Type': 'application/json',
              'User-Agent': 'MindCareApp/1.0',
            },
            body: jsonEncode({'message': message}),
          )
          .timeout(const Duration(seconds: 30));
      if (response.statusCode != 200) {
        debugPrint('Hosted server error: ${response.statusCode}');
        return null;
      }
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final text = data['response'] as String?;
      if (text == null || text.trim().isEmpty) return null;
      if (!_looksUsable(text)) {
        debugPrint('Hosted reply rejected (low quality)');
        return null;
      }
      final raw = data['recommendations'];
      final recommendations = raw is List
          ? raw.whereType<String>().toList()
          : const <String>[];
      return WillowChatResult(
        text: text,
        recommendations: recommendations,
      );
    } catch (e) {
      debugPrint('Hosted server unreachable: $e');
      return null;
    }
  }

  static bool _isSinhala(int r) => r >= 0x0d80 && r <= 0x0dff;

  /// Rejects incoherent model output (digit-soup, mixed-scrambled, truncated).
  /// A reply is acceptable when it is coherently Sinhala-dominant or
  /// Latin-dominant; muddled mixes of both are rejected.
  static bool _looksUsable(String text) {
    final s = text.trim();
    if (s.length < 30) return false;
    if (s.contains('&') || s.contains('#') || s.contains('\uFFFD')) return false;
    final runes = s.runes.toList();
    var sinhala = 0;
    var latin = 0;
    for (final r in runes) {
      if (_isSinhala(r)) {
        sinhala++;
      } else if ((r >= 0x41 && r <= 0x5a) || (r >= 0x61 && r <= 0x7a)) {
        latin++;
      }
    }
    final letters = sinhala + latin;
    if (letters == 0) return false;
    final sinhalaDominant = sinhala / letters >= 0.6;
    final latinDominant = latin / letters >= 0.6;
    if (!sinhalaDominant && !latinDominant) return false;
    for (var i = 0; i < runes.length; i++) {
      final r = runes[i];
      if (r < 0x30 || r > 0x39) continue;
      if ((i > 0 && _isSinhala(runes[i - 1])) ||
          (i < runes.length - 1 && _isSinhala(runes[i + 1]))) {
        return false;
      }
    }
    final last = runes.last;
    if (last >= 0x0dc0 && last <= 0x0dff) return false;
    return true;
  }

  static Future<String> _callGemini(String userText) async {
    final body = jsonEncode({
      'system_instruction': {
        'parts': [
          {'text': _systemPrompt},
        ],
      },
      'contents': [
        {
          'role': 'user',
          'parts': [
            {'text': userText},
          ],
        },
      ],
      'generationConfig': {
        'temperature': 0.7,
        'maxOutputTokens': 800,
        'topP': 0.9,
      },
    });
    final uri = _endpoint.replace(queryParameters: {'key': _apiKey});
    for (var attempt = 0; attempt < 3; attempt++) {
      if (attempt > 0) {
        await Future.delayed(Duration(seconds: 4 * attempt));
      }
      final response = await http.post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: body,
      );
      if (response.statusCode == 503 || response.statusCode == 429) continue;
      if (response.statusCode != 200) {
        throw Exception('Gemini HTTP ${response.statusCode}: ${response.body}');
      }
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final text = _extractText(data);
      if (text == null) throw Exception('Gemini returned no text');
      return text;
    }
    throw Exception('Gemini unavailable (503/429)');
  }

  static String? _extractText(Map<String, dynamic> data) {
    final candidates = data['candidates'] as List<dynamic>?;
    if (candidates == null || candidates.isEmpty) return null;
    final first = candidates.first as Map<String, dynamic>?;
    final content = first?['content'] as Map<String, dynamic>?;
    final parts = content?['parts'] as List<dynamic>?;
    if (parts == null || parts.isEmpty) return null;
    final text = (parts.first as Map<String, dynamic>)['text'] as String?;
    return text;
  }

  static String _normalize(String text) {
    return text
        .toLowerCase()
        .replaceAll('\u200d', '')
        .replaceAll('\u200c', '')
        .replaceAll(RegExp(r'[\u200b\u200e\u200f\ufeff]'), '')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }

  /// True when a message is predominantly Sinhala (used to route reply language).
  static bool _looksSinhala(String text) {
    if (text.isEmpty) return false;
    var sinhala = 0;
    for (final r in text.runes) {
      if (r >= 0x0d80 && r <= 0x0dff) sinhala++;
    }
    return sinhala / text.runes.length >= 0.3;
  }

  static String? _pickTopic(String q, bool isSi) {
    if (q.isEmpty) return null;
    final bonus = <String, double>{};
    for (final trigger in isSi ? _topicTriggers : _topicTriggersEn) {
      final word = trigger.$1;
      if (q.contains(word)) {
        final weight = trigger.$2;
        for (final t in trigger.$3) {
          bonus[t] = (bonus[t] ?? 0) + weight;
        }
      }
    }
    String? best;
    var bestScore = 0.0;
    bonus.forEach((t, s) {
      if (s > bestScore) {
        bestScore = s;
        best = t;
      }
    });
    return best;
  }

  static String _curatedReply(String? topic, String q, bool isSi) {
    final replies = isSi ? _topicReplies : _topicRepliesEn;
    final variants = topic == null ? null : replies[topic];
    if (variants == null || variants.isEmpty) {
      return isSi ? _genericReply : _genericReplyEn;
    }
    final idx = q.runes.fold<int>(0, (a, r) => a + r) % variants.length;
    return variants[idx];
  }

  static const String _systemPrompt =
      "You are 'Willow', a warm, caring mental-health support assistant for Sri Lankan "
      "students and young people. ALWAYS reply in Sinhala unless the user writes in another "
      "language, in which case match their language. Keep answers short and human: 2-5 "
      "short sentences. Never diagnose, do not prescribe medication, do not sound clinical. "
      "Acknowledge the person's feelings, normalize them, offer one small concrete step for "
      "today, and invite them to keep talking. If the message involves self-harm, suicide, "
      "or being in danger, urge immediate professional help and mention the free national "
      "helplines: 1926 (mental health helpline) and 1929 (National Child Protection "
      "Authority), and suggest going to the nearest hospital.";

  static const String _crisisReply =
      "ඔයා දැන් ගොඩක් දුෂ්කර තත්වයක් පසු කරනවා. ඔයා තනිවම මේ ජීවිතේ "
      "අරගන්න ඕන නෑ. කරුණාකර වහාම වෘත්තීය උදව් ලබාගන්න: 1926 (මානසික "
      "සුබසාධන හෙල්ප්ලයින්), නැතහොත් ශ්රී ලංකාවේ ස්ත්රීන් සහ ළමයින් "
      "නතර කිරීමේ අංකය 1929 අමතන්න, නැතහොත් ළඟම රෝහලට යන්න. ඔයා වැදගත්.";

  static const String _positiveReply =
      "හොඳට අහන්න ගොඩක් සතුටුයි! ඔයාට මොනවා හරි උදව්වක් ඕන වුණොත්, "
      "ඕනෑම වෙලාවක මෙතන කතා කරන්න.";

  static const String _genericReply =
      "ඔයා මේ ගැන මට කිව්ව එක ලොකු ශක්තියක්. අපි පොඩි පියවරකින් පටන් "
      "ගමු — හෙමින් හුස්ම ටිකක් ගන්න, නැතහොත් ඔයාට හොඳ දැනෙන දෙයක් "
      "ටික වේලාවක් කරන්න. ඔයාට වැඩියෙන් කියන්න ඕන නම්, කියන්න.";

  static const String _crisisReplyEn =
      "You're going through something very hard right now, and you don't "
      "have to carry this alone. Please reach out for professional help "
      "right away: call 1926 (national mental-health helpline) or 1929 "
      "(National Child Protection Authority), or go to your nearest hospital. "
      "You matter, and people can help.";

  static const String _positiveReplyEn =
      "That's lovely to hear! I'm really glad. If you ever need someone to "
      "talk to, I'm always here.";

  static const String _genericReplyEn =
      "Thank you for sharing that with me — it takes strength. Let's start "
      "with one small step: take a few slow breaths or do something that "
      "feels comforting. Tell me more whenever you're ready.";

  static const List<String> _crisisSignals = [
    "සියදිවි",
    "මැරෙන්න",
    "මැරිලා",
    "ජීවත් වෙන්න ඕන නෑ",
    "ජීවත් වෙන්න බෑ",
    "කපාගන්න",
    "තුවාල කරගන්න",
    "මගෙන් කමක් නෑ",
  ];

  static const List<String> _positiveSignals = [
    "ස්තූතියි",
    "හෙලෝ",
    "ආයුබෝවන්",
    "හොඳින් ඉන්නවා",
    "සතුටුයි",
    "හොඳ දවසක්",
    "ස්තූතිය",
  ];

  static const List<String> _crisisSignalsEn = [
    "kill myself",
    "suicide",
    "suicidal",
    "end my life",
    "don't want to live",
    "dont want to live",
    "cut myself",
    "hurt myself",
    "self harm",
    "worthless",
    "no reason to live",
    "can't go on",
    "cant go on",
  ];

  static const List<String> _positiveSignalsEn = [
    "thank you",
    "thanks",
    "hello",
    "hi",
    "good morning",
    "good evening",
    "feeling good",
    "happy",
    "great day",
    "doing well",
  ];

  static const Map<String, List<String>> _topicRecs = {
    'academic_stress': ['journal', 'moodTracker'],
    'anxiety': ['breathing', 'calmMusic'],
    'burnout': ['calmMusic', 'journal'],
    'depression': ['moodTracker', 'counsellorCall'],
    'loneliness': ['counsellorCall'],
    'sleep': ['breathing'],
    'relationships': ['journal'],
    'financial': ['resources'],
    'grief': ['counsellorCall'],
    'emotions': ['journal', 'moodTracker'],
    'cbt_thinking': ['journal'],
    'fear_of_failure': ['moodTracker'],
    'help_seeking': ['resources'],
    'imposter': ['journal'],
    'mindfulness': ['breathing'],
    'motivation': ['moodTracker'],
    'self_esteem': ['journal'],
    'transitions': ['journal'],
    'time_management': ['moodTracker', 'journal'],
  };

  static const List<(String, double, List<String>)> _topicTriggers = [
    ('විභාග', 2.2, ['academic_stress', 'fear_of_failure']),
    ('පරීක්ෂණ', 2.2, ['academic_stress']),
    ('රිසල්ට්', 2.2, ['academic_stress', 'fear_of_failure']),
    ('පාඩම්', 2.2, ['academic_stress', 'time_management']),
    ('කැම්පස්', 2.2, ['academic_stress']),
    ('විශ්වවිද්යාල', 2.6, ['academic_stress']),
    ('විෂය', 2.2, ['academic_stress']),
    ('නින්ද', 2.2, ['sleep']),
    ('නිදා', 2.2, ['sleep']),
    ('ඇඳට යන්න', 2.2, ['sleep']),
    ('තනිකම', 2.2, ['loneliness']),
    ('තනියම', 2.2, ['loneliness']),
    ('හුදෙකලා', 2.6, ['loneliness']),
    ('මහන්සි', 3.0, ['burnout']),
    ('වෙහෙස', 2.6, ['burnout']),
    ('හෙම්බත්', 2.6, ['burnout']),
    ('බය', 2.2, ['anxiety']),
    ('බිය', 2.2, ['anxiety']),
    ('කලබල', 2.6, ['anxiety']),
    ('භීතිය', 2.6, ['anxiety']),
    ('දුක', 3.0, ['depression']),
    ('කඳුළු', 2.6, ['depression']),
    ('අඬන', 2.6, ['depression']),
    ('අහිමි', 3.0, ['grief']),
    ('මිය', 2.2, ['grief']),
    ('මරණ', 2.2, ['grief']),
    ('යාළු', 2.2, ['relationships']),
    ('යහළු', 2.2, ['relationships']),
    ('රණ්ඩු', 2.6, ['relationships']),
    ('කේන්ති', 2.2, ['relationships']),
    ('බැඳීම්', 2.0, ['relationships']),
    ('රිදුම', 2.6, ['emotions']),
    ('රිදෙනවා', 2.2, ['emotions']),
    ('මුදල්', 2.2, ['financial']),
    ('සල්ලි', 2.2, ['financial']),
    ('ගෙවලා', 2.6, ['financial']),
    ('වියදම', 2.6, ['financial']),
    ('ස්වයං විශ්වාස', 2.6, ['self_esteem']),
    ('වටිනාකම', 2.2, ['self_esteem']),
    ('මම ප්රමාණවත්', 2.6, ['imposter', 'self_esteem']),
    ('අයිති නෑ', 2.6, ['imposter']),
    ('වැරදුණොත්', 2.6, ['fear_of_failure']),
    ('fail', 2.6, ['fear_of_failure']),
    ('අනුගත', 3.0, ['transitions']),
    ('අලුත් තැන', 2.6, ['transitions']),
    ('මුල් දවස්', 2.6, ['transitions']),
    ('වෙනස්කම්', 2.2, ['transitions']),
  ];

  static const List<(String, double, List<String>)> _topicTriggersEn = [
    ('exam', 2.6, ['academic_stress', 'fear_of_failure']),
    ('exams', 2.6, ['academic_stress', 'fear_of_failure']),
    ('results', 2.4, ['academic_stress', 'fear_of_failure']),
    ('study', 2.2, ['academic_stress', 'time_management']),
    ('studying', 2.2, ['academic_stress', 'time_management']),
    ('university', 2.2, ['academic_stress', 'transitions']),
    ('campus', 2.2, ['academic_stress']),
    ('assignment', 2.2, ['academic_stress', 'time_management']),
    ('deadline', 2.4, ['academic_stress']),
    ('subject', 2.2, ['academic_stress']),
    ('lecture', 2.0, ['academic_stress']),
    ('sleep', 2.2, ['sleep']),
    ('sleepless', 2.4, ['sleep']),
    ('insomnia', 2.6, ['sleep']),
    ('awake', 2.2, ['sleep']),
    ('bed', 2.0, ['sleep']),
    ('lonely', 2.6, ['loneliness']),
    ('loneliness', 2.6, ['loneliness']),
    ('alone', 2.2, ['loneliness']),
    ('isolated', 2.4, ['loneliness']),
    ('no friends', 2.6, ['loneliness']),
    ('tired', 3.0, ['burnout']),
    ('exhausted', 3.0, ['burnout']),
    ('burnout', 3.0, ['burnout']),
    ('burned out', 3.0, ['burnout']),
    ('drained', 2.6, ['burnout']),
    ('overwhelmed', 2.6, ['burnout']),
    ('anxious', 2.6, ['anxiety']),
    ('anxiety', 2.6, ['anxiety']),
    ('panic', 2.6, ['anxiety']),
    ('worried', 2.4, ['anxiety']),
    ('worry', 2.4, ['anxiety']),
    ('nervous', 2.2, ['anxiety']),
    ('afraid', 2.2, ['anxiety']),
    ('scared', 2.4, ['anxiety']),
    ('fear', 2.2, ['anxiety']),
    ('sad', 3.0, ['depression']),
    ('depressed', 3.0, ['depression']),
    ('depression', 3.0, ['depression']),
    ('hopeless', 3.0, ['depression']),
    ('empty', 2.4, ['depression']),
    ('crying', 2.4, ['depression']),
    ('lost', 3.0, ['grief']),
    ('grief', 3.0, ['grief']),
    ('died', 2.6, ['grief']),
    ('death', 2.4, ['grief']),
    ('passed away', 3.0, ['grief']),
    ('friend', 2.2, ['relationships']),
    ('friends', 2.2, ['relationships']),
    ('relationship', 2.2, ['relationships']),
    ('girlfriend', 2.2, ['relationships']),
    ('boyfriend', 2.2, ['relationships']),
    ('argued', 2.4, ['relationships']),
    ('argument', 2.4, ['relationships']),
    ('fight', 2.2, ['relationships']),
    ('angry', 2.2, ['relationships']),
    ('miss him', 2.2, ['relationships']),
    ('miss her', 2.2, ['relationships']),
    ('hurt', 2.4, ['emotions']),
    ('feelings', 2.4, ['emotions']),
    ('emotion', 2.2, ['emotions']),
    ('emotional', 2.2, ['emotions']),
    ('money', 2.2, ['financial']),
    ('bills', 2.4, ['financial']),
    ('rent', 2.4, ['financial']),
    ('fees', 2.6, ['financial']),
    ('debt', 2.6, ['financial']),
    ('loan', 2.6, ['financial']),
    ('brok', 2.4, ['financial']),
    ('afford', 2.4, ['financial']),
    ('self esteem', 2.6, ['self_esteem']),
    ('self confidence', 2.6, ['self_esteem']),
    ('worthless', 2.6, ['self_esteem']),
    ('not good enough', 3.0, ['self_esteem', 'imposter']),
    ('imposter', 3.0, ['imposter']),
    ("don't belong", 2.6, ['imposter']),
    ('fraud', 2.6, ['imposter']),
    ('fake', 2.2, ['imposter']),
    ('inadequate', 2.6, ['imposter']),
    ('overthinking', 2.6, ['cbt_thinking']),
    ('negative thoughts', 2.6, ['cbt_thinking']),
    ('thoughts racing', 2.4, ['cbt_thinking']),
    ('catastrophising', 2.6, ['cbt_thinking']),
    ('what if', 2.2, ['cbt_thinking', 'anxiety']),
    ('help', 2.2, ['help_seeking']),
    ('talk to someone', 2.6, ['help_seeking']),
    ('counsellor', 2.6, ['help_seeking']),
    ('counseling', 2.6, ['help_seeking']),
    ('mindfulness', 2.6, ['mindfulness']),
    ('mindful', 2.4, ['mindfulness']),
    ('grounding', 2.6, ['mindfulness']),
    ('present moment', 2.4, ['mindfulness']),
    ('calm', 2.2, ['mindfulness', 'anxiety']),
    ('motivation', 2.6, ['motivation']),
    ('unmotivated', 2.8, ['motivation']),
    ('lazy', 2.4, ['motivation']),
    ('procrastinate', 2.6, ['motivation', 'time_management']),
    ('can\'t start', 2.6, ['motivation']),
    ('making progress', 2.2, ['motivation']),
    ('time management', 2.6, ['time_management']),
    ('schedule', 2.2, ['time_management']),
    ('organised', 2.2, ['time_management']),
    ('managing time', 2.6, ['time_management']),
    ('moving', 2.6, ['transitions']),
    ('new place', 2.6, ['transitions']),
    ('new city', 2.6, ['transitions']),
    ('starting over', 2.6, ['transitions']),
    ('change', 2.2, ['transitions']),
    ('settling in', 2.6, ['transitions']),
    ('fail', 2.4, ['fear_of_failure']),
    ('failing', 2.6, ['fear_of_failure']),
    ("afraid of failing", 3.0, ['fear_of_failure']),
    ('let down', 2.6, ['fear_of_failure', 'self_esteem']),
  ];

  static const Map<String, List<String>> _topicReplies = {
    'academic_stress': [
      "විභාග ආතතිය සාමාන්‍ය දෙයක්, ඒත් ඒක ඔයාව පාලනය කරන්න දෙන්න ඕන නෑ. පොඩි කොටසකින් පටන් ගමු: විනාඩි 25ක් පාඩම් කරලා විනාඩි 5ක් විවේකයක් ගන්න. මේ වේලාවට ඔයාට වැඩිපුරම ඕන ඒ විවේකයයි.",
      "ඔයා දැන් දැනෙන ආතතිය ඇත්ත, ඒත් ඒකට ඔයාව නිර්වචනය වෙන්න දෙන්න එපා. හෙට වැඩ ලැයිස්තුවක් ලියලා, වැදගත්ම එකක් විතරක් තෝරගමු. ඒක ඉවර වුණාම ඊළඟ එක.",
    ],
    'anxiety': [
      "හිත දුවනකොට, ඒක අනාගතයට යනවා. අපි ඒක මේ වෙලාවට ගේමු: හෙමින් හුස්ම 4ක් ඇතුළට, 4ක් අල්ලගෙන, 4කින් එළියට. වාර 4ක් එහෙම කරමු.",
      "බයක් ආවම, එක්ක ඉන්න එක තමයි දුෂ්කරම දේ. අවට පේන වස්තු 5ක්, ඇහෙන හඬ 4ක්, දැනෙන දේ 3ක් — ගණන් කරන්න. ඒක හිත මේ වෙලාවට ගේනවා.",
    ],
    'burnout': [
      "දවස් ගණනක් තිස්සේ මහන්සියි කියන එක, ශරීරය දෙන පණිවිඩයක්. ඒකට ඇහුම්කන් දෙන්න ඕන. අද රෑ මුලින්ම නිදාගන්න එක ප්‍රමුඛතාවයක් කරමු, අනිත් දේවල් හෙටට.",
      "විවේකයක් ගත්තාට ඔයාට වරදක් නෑ. පැය භාගයක් හරි ඔයා විතරක් වෙන කාලයක් දෙන්න — සංගීතයක් ඇහුවත්, ඇවිදින්න ගියත් කමක් නෑ.",
    ],
    'depression': [
      "මේ දවස්වල හිතට බරක් තියෙනවා කියලා මට තේරෙනවා. ඔයා මේ ගැන කතා කරන එකම ලොකු පියවරක්. අද ඉතාම පොඩි දෙයක් වත් කරමු — උදේට කවුළුවක් ඇරලා පිට සුළඟට මුණගැසෙන්න වගේ.",
      "හැම වෙලාවකම හොඳට දැනෙන්නේ නෑ, ඒක සාමාන්‍යයි. ඔයා තනියම නෙමෙයි කියන එක ඔයාට දැනෙන්න ඕන. විශ්වාස කරන කෙනෙක් එක්ක ටිකක් කතා කරන්න පුළුවන්ද?",
    ],
    'loneliness': [
      "තනිකමට නමක් දෙනකොට, ඒක ටිකක් ලිහිල් වෙනවා. ඔයාට ඕනම වෙලාවක මෙතන කතා කරන්න පුළුවන්. අද, ටික වේලාවකට හරි, ඔයාට හොඳක් දැනෙන කෙනෙකුට පණිවිඩයක් යවන්න හිතමු.",
      "ඔයාගේ හැඟීම ඇත්ත, ඒත් ඒක සදාකාලික නෑ. බැඳීම් ගොඩනැගෙන්නේ කුඩා පියවරකින් — අද, සිනාසෙන්න පුළුවන් කෙනෙක් එක්ක කතා කරන්න උත්සාහ කරමු.",
    ],
    'sleep': [
      "නින්ද නොයාම කියන්නේ ශරීරය දෙන පණිවිඩයක්. නිදාගන්න පැයකට කලින් තිරයෙන් ඈත් වෙලා, උණු වතුර ටිකක් බීලා, අඳුරේ සන්සුන්ව ඉන්න උත්සාහ කරමු.",
      "නින්ද ගැන වැඩිය හිතීම, නින්දට බාධාවක්. 'බලාගෙන' ඉන්න එපා — නිදිමත ආවාම ඇඳට යමු. දවල් හොඳට එළියට ගියොත් රෑ නින්දත් යහපත් වෙනවා.",
    ],
    'relationships': [
      "යාළුවෙක් එක්ක ගැටුමක් ආවම, හිතට අමාරුයි. ඒක සාමාන්‍යයි. සන්සුන් වුණාට පස්සේ, 'මට තේරුණ අයුරින්...' කියලා ඒ ගැන කතා කරන්න උත්සාහ කරමු.",
      "බැඳීම්වල ගැටුම් ඇති වෙනවා, ඒවා ඔයාගේ හැඟීම් අඩු කරන්නේ නෑ. ඔයාට බරක් වෙන දේක් බෙදගන්න කෙනෙක් හොයලා බලමු.",
    ],
    'financial': [
      "මුදල් ප්‍රශ්න ඕනෑම කෙනෙකුට බරක්. මුලින්ම වියදම් ලියලා බලමු — කුඩා ඉතුරුමක් වත් කරන්න පුළුවන් තැනක් පේනවා. ලැජ්ජා වෙන්න එපා, ඔයා තනියම නෙමෙයි.",
      "හොඳම දෙය තමයි සැලැස්මක්. මාසක වියදම් ලියලා වැදගත්ම ඒවා මුලින් තියමු. පුළුවන් නම්, ශිෂ්‍ය උපදේශකයෙකුගේ උදව් ගන්න.",
    ],
    'grief': [
      "අහිමි වීමක් කියන්නේ ජීවිතයේ දුෂ්කරම දේවලින් එකක්. ඔයාට දැනෙන දුක, හිස්බව — ඒ හැම එකක්ම වලංගුයි. කාලය දෙන්න, කතා කරන්න, අඬන්නත් අවසර තියෙනවා.",
      "දුක්බර මතකවලට තනියම මුහුණ දෙන්න ඕන නෑ. විශ්වාස කරන කෙනෙක් එක්ක ඒ ගැන කතා කරන්න, නැත්නම් ලියලා බලන්න. උපකාරයක් ඕන නම් 1926 අමතන්න.",
    ],
    'emotions': [
      "ඔයාගේ හැඟීම්වලට නමක් දෙන්න උත්සාහ කරන එකම ලොකු පියවරක්. මේ දැන් දැනෙන හැඟීම මොකක්ද? ඒකට ඉඩ දෙන්න — හැඟීම් ආවා වගේම යනවා.",
    ],
    'cbt_thinking': [
      "හිතේ ඇති වෙන 'මම ප්‍රමාණවත් නෑ' වගේ විශ්වාස, සත්‍යයක් නෙමෙයි. ඒ හිතුවිල්ලට සාක්ෂි මොනවාද කියලා බලමු, විරුද්ධ සාක්ෂි මොනවාද කියලත්.",
      "හිතුවිල්ලක් සත්‍යයක් නොවේ. නිෂේධාත්මක හිතුවිල්ලක් ආවම, ඒකත් එක්ක ඔයා දන්න සත්‍ය දේත් ලියලා බලමු.",
    ],
    'fear_of_failure': [
      "fail වෙයි කියන බය, උත්සාහ කරන කෙනෙක්ටයි තියෙන්නේ. වැරදීමකින් ඔයාගේ වටිනාකම අඩු වෙන්නේ නෑ. ඉලක්කයම පොඩි කරමු — අදට පුළුවන් එක පියවරක් විතරයි.",
      "බයත් එක්කම වැඩ කරන්න කියලා හිතමු. 'වැරදුණොත් මොකද වෙන්නේ?' — ඒක ලියලා බලමු. බොහෝ විට බය තියෙන තරම් ලොකු වෙන්නේ නෑ.",
    ],
    'help_seeking': [
      "උදව් ඉල්ලන එක දුර්වලකමක් නෙමෙයි — ඒක තමයි නුවණ. මෙතනදී වගේම, විශ්වාස කරන කෙනෙක්, උපදේශකයෙක් එක්කත් කතා කරන එක හොඳයි.",
      "ඔයා මේ ගැන කතා කරපු එකම ලොකු ධෛර්යයක්. දිගටම මේ විදියට උදව් හොයන එක නවත්තන්න එපා.",
    ],
    'imposter': [
      "'මම මෙතනට අයිති නෑ' වගේ හැඟීමක් බොහෝ දෙනෙකුට දැනෙනවා. ඒක ඔයාගේ හැකියාව ගැන සාක්ෂියක් නෙමෙයි. මෙච්චර දුරට එන්න ඔයා කරපු දේවල් ලියමු.",
      "ඔයා එතනට ආවේ අයිතියෙන්. ඔයා කරන දේ ගැන ඔයාටම ඇත්තම සැකයක් නැත්නම්, හොඳ පෙරළියක් තියෙන බව ඒක පෙන්නනවා.",
    ],
    'mindfulness': [
      "සිහියෙන් ඉන්න උත්සාහ කරන එක හොඳ දෙයක්. දැන් සිරුරේ දැනෙන දේ, හුස්ම — ඒක තමයි මේ විනාඩියේ ඇත්ත. පුරුද්දක් වගේ කරමු, බලාපොරොත්තුවක් වගේ නෙමෙයි.",
      "මේ හුස්ම, මේ විනාඩිය — වෙන තැනක් මොකක්වත් ඕන නෑ. කෝපි එකක් බොනකොට වගේ, සම්පූර්ණයෙන් මේ වෙලාවේ ඉන්න උත්සාහ කරමු.",
    ],
    'motivation': [
      "පටන් ගන්න එක තමයි ලොකුම දේ. කම්මැලිකම හැමෝටම තියෙනවා. පොඩි කොටසක්, විනාඩි 10ක් වත් — ඒක තමයි අද ඉලක්කය.",
      "ඔයාට ඇත්තටම වැදගත් දේ මොකක්ද? ඒ දිහා බලමු, 'වැඩෙන් බැහැ' කියන හිතුවිල්ලට වෙනුවට. එක පියවරක්, ඒයි.",
    ],
    'self_esteem': [
      "ඔයා වටිනාකමක් ඇති කෙනෙක් — ඒක ලකුණු මත, අනෙක් අයගේ අදහස් මත තියෙන්නේ නෑ. ඔයා හොඳින් කරපු දෙයක් මතක් කරගන්න, ඒක සාක්ෂියක්.",
      "ඔයා ආදරයට සහ ගෞරවයට සුදුසුයි. දවස අන්තිමට, ඔයා හොඳින් කරපු දෙයක් ලියන්න — පොඩි පොඩි දේවල් ගැන අවධානය යොමු වෙනවා.",
    ],
    'transitions': [
      "නව තැනකට අනුවර්තනය වෙන්න කාලය ඕන. මුල් දවස්වල තනිකමක්, අපහසුවක් දැනෙන එක සාමාන්‍යයි. අද පොඩි පියවරක් — අළුත් කෙනෙක් එක්ක කතා කරන්න උත්සාහ කරමු.",
      "වෙනස්කම් කාලය ගන්නවා. ඔයාගේ වේගයට, ඔයාගේ පහසුවට අනුව ඉදිරියට යමු.",
    ],
  };

  static const Map<String, List<String>> _topicRepliesEn = {
    'academic_stress': [
      "Exam stress is so normal, but it doesn't have to take over. Let's make it small: 25 minutes of focused study, then a 5-minute break. Breathing is allowed between deadlines.",
      "What you're feeling is real, but it's not who you are. Write tomorrow's list tonight, pick the one thing that matters most, and start there. One step at a time is a plan.",
    ],
    'anxiety': [
      "When your thoughts race ahead, anchor back to now: four slow breaths in, hold, four out — four rounds. Your body will start to follow your breath.",
      "Anxiety feels heavy, and it's exhausting. Try naming five things you can see, four you can hear, three you can feel. It gently pulls you back to this moment.",
    ],
    'burnout': [
      "Being tired for days is your body's honest message, and it deserves listening to. Rest isn't a reward you have to earn; let tonight end early for once.",
      "You're allowed to stop. Half an hour that's just yours — music, a walk, nothing — is essential maintenance, not a waste.",
    ],
    'depression': [
      "The heaviness you're carrying is real, and it makes everything harder. Talking about it is already a big step. Let's pick one tiny thing for today — open a window, listen to one song.",
      "You won't feel alright every day, and that's okay. You're not alone in this, even when it feels that way. Can you reach out to one person you trust?",
    ],
    'loneliness': [
      "Naming loneliness helps it loosen its grip a little. I'm here whenever you want to talk. Today, maybe send one message to someone who feels like home.",
      "Your feelings are valid, and they won't last forever. Connections grow one small step at a time — let's try a short chat with a friendly face today.",
    ],
    'sleep': [
      "Sleeplessness is often the body's way of staying alert. An hour before bed, step away from screens, sip something warm, and let yourself slow down.",
      "Trying too hard to sleep makes it harder. Trust the tiredness — go to bed when it arrives, and get daylight early so your nights fall into place.",
    ],
    'relationships': [
      "A disagreement with someone you care about hurts. That's natural. Once you're both a little calmer, try saying 'what I heard was…' and give each other space to explain.",
      "Friction in close bonds doesn't erase your worth. It's okay to ask for what you need; relationships survive honesty.",
    ],
    'financial': [
      "Money worries weigh on anyone, and you're not failing for having them. Write down your spending for a week — clarity is the first step, and small wins count.",
      "A simple plan helps more than worry. List this month's essentials, set them first, and realistically trim the rest. If campus support offers financial guidance, it's worth a meeting.",
    ],
    'grief': [
      "Grief is one of life's hardest roads, and every feeling you have is valid — the sadness, the missing, the numbness. Give yourself time, and let people in when you can.",
      "You don't have to face loss alone. Talking it through with someone you trust, or writing it down, can help. If it gets too heavy, the 1926 helpline is there for you.",
    ],
    'emotions': [
      "Trying to name what you're feeling is a big step. What's the emotion right now — sadness, anger, fear? Feelings arrive like weather; they pass too. You're allowed to feel it.",
    ],
    'cbt_thinking': [
      "Thoughts like 'I'm not enough' are thoughts, not facts. Let's look for evidence — what makes it true, and what gently contradicts it? Writing both down helps.",
      "A thought isn't a verdict. When a harsh thought shows up, jot down the facts you actually know alongside it, and notice the difference.",
    ],
    'fear_of_failure': [
      "Being afraid of failing means you care, and that already puts you ahead. A mistake can't erase your worth. Let's shrink the goal — one small step today is enough.",
      "Let's run the worst-case script: what would actually happen if it went wrong? Most fears shrink when we look at them directly.",
    ],
    'help_seeking': [
      "Asking for help isn't weakness — it's wisdom. It's okay to talk to a counsellor or a trusted person, just like you are with me. There's strength in reaching out.",
      "The courage you're showing by talking is real. Keep reaching — for a friend, a lecturer, a counsellor. You deserve support.",
    ],
    'imposter': [
      "The feeling of 'I don't belong here' shows up for so many capable people. It isn't evidence about your ability. Let's list what you've done to get exactly this far.",
      "You earned your place. Caring enough to doubt yourself is often a sign of depth, not fraud. Let's look at what's actually true about your achievements.",
    ],
    'mindfulness': [
      "Practising mindfulness is a kindness, not another task. This breath, this minute — you don't need to be anywhere else. Start with one minute of simply noticing.",
      "Notice the breath, the weight of your feet, the shape of the room. That's the practice. Not a escape, just presence for one minute.",
    ],
    'motivation': [
      "Starting is the hardest and bravest part. Everyone feels stuck sometimes. Ten focused minutes count as progress — that's today's whole goal.",
      "What actually matters to you underneath the tiredness? Let's aim at that, one small move, not at 'all of it'. Small is enough today.",
    ],
    'self_esteem': [
      "Your worth isn't decided by marks or anyone's opinion. Remember something you did well recently — that's evidence. You carry value that isn't conditional.",
      "You deserve care and respect, full stop. At the end of today, write down one small thing you did well. Watch what it does to your eyes' focus.",
    ],
    'transitions': [
      "New places take time to feel like home. Feeling a little lost in the first weeks is completely normal. Today, one small step — say hello to someone new.",
      "Change takes longer than we expect. You can move at your own pace; adjusting isn't a race.",
    ],
  };
}
