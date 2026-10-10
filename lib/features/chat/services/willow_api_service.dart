import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

/// One turn of prior conversation context. `role` is 'user' or 'model'
/// (the app mirrors Gemini's roles so the API can send alternating turns).
class WillowTurn {
  final String role;
  final String text;

  const WillowTurn({required this.role, required this.text});
}

/// A Willow reply: the message text plus any recommended wellness features.
class WillowChatResult {
  final String text;
  final List<String> recommendations;

  const WillowChatResult({required this.text, this.recommendations = const []});
}

class WillowApiService {
  static const String _apiKey = '';

  /// The fine-tuned model server endpoint. Fixed for this build so users
  /// cannot change it from inside the app.
  static final String _baseUrl =
      'https://paint-assurance-humanitarian-amanda.trycloudflare.com';
  static final bool _serverMode = true;

  /// Model server reachability cache. Probing happens at most once every few
  /// seconds so a server that is down never stalls each message on a timeout;
  /// when it comes back up, the next probe reconnects automatically.
  static bool _serverReachable = false;
  static DateTime _lastProbe = DateTime.fromMillisecondsSinceEpoch(0);

  static Future<bool> _serverUp() async {
    if (DateTime.now().difference(_lastProbe) < const Duration(seconds: 12)) {
      return _serverReachable;
    }
    _lastProbe = DateTime.now();
    _serverReachable = await healthCheck();
    return _serverReachable;
  }

  static void _markServerDown() {
    _lastProbe = DateTime.now();
    _serverReachable = false;
  }

  static String get baseUrl => _baseUrl;

  /// Always true: the in-app Willow brain (curated) can reply.
  static bool get isConfigured => true;

  /// Send a message to Willow and get a response. Never returns null when
  /// configured. Order: hosted model server (if set) -> Gemini -> curated.
  ///
  /// `turns` carries up to the previous ~6 messages of the conversation so the
  /// bot can read the user's state and continue the thread. Crisis signals are
  /// scanned across the whole recent window (a danger statement is never
  /// ignored), while the reply topic is accumulated over every user message so
  /// the conversation follows the user's mind.
  // Session-level mood identification - track across conversation
  static String? _identifiedMindState;
  static int _userMessageCount = 0;
  static DateTime? _sessionStartTime;

  static void resetSession() {
    _identifiedMindState = null;
    _userMessageCount = 0;
    _sessionStartTime = null;
  }

  static Future<WillowChatResult?> chat(
    String message, {
    List<WillowTurn> turns = const [],
  }) async {
    if (!isConfigured) return null;

    final q = _normalize(message);
    final isSi = _looksSinhala(q);
    final userTexts = <String>[
      ...turns.where((t) => t.role == 'user').map((t) => t.text),
      message,
    ];

    // Count user messages in this session
    _userMessageCount = userTexts.length;
    _sessionStartTime ??= DateTime.now();

    // Identify mind/mood after seeing at least 5-6 user messages
    if (_identifiedMindState == null && userTexts.length >= 5) {
      final dominantTopic = _pickTopicAcross(userTexts, isSi);
      if (dominantTopic != null) {
        _identifiedMindState = dominantTopic;
      } else {
        // Fallback to most frequent topic if no clear dominant
        final topicCounts = <String, int>{};
        for (final t in userTexts) {
          final n = _normalize(t);
          if (n.isEmpty) continue;
          for (final trigger in isSi ? _topicTriggers : _topicTriggersEn) {
            if ((isSi
                ? n.contains(trigger.$1)
                : _matchesWholeWord(n, trigger.$1))) {
              for (final tp in trigger.$3) {
                topicCounts[tp] = (topicCounts[tp] ?? 0) + 1;
              }
            }
          }
        }
        if (topicCounts.isNotEmpty) {
          _identifiedMindState = topicCounts.entries
              .reduce((a, b) => a.value > b.value ? a : b)
              .key;
        }
      }
    }

    // Suggestions should be sparse, not on every message. Chips are only shown
    // the first time a topic is raised (a new theme worth acting on), and for
    // crisis. Repeat/follow-up messages, greetings and positives stay clean.
    final singleTopic = _pickTopicForSingle(q, isSi);
    List<String> topicRecsForFirstMention() {
      if (singleTopic == null) return const <String>[];
      if (_topicHits(singleTopic, userTexts, isSi) > 1) {
        return const <String>[];
      }
      return _topicRecs[singleTopic] ?? const <String>[];
    }

    // A danger statement is an emergency in any language: reply in the
    // language that matched, defaulting to the current message's language.
    // This is checked before the model server so safety never depends on a
    // network call or on generation quality.
    final siCrisis = _hasSignal(_crisisSignals, userTexts);
    final enCrisis = _hasSignal(_crisisSignalsEn, userTexts);
    if (siCrisis || enCrisis) {
      final useSi = siCrisis == enCrisis ? isSi : siCrisis;
      return WillowChatResult(
        text: useSi ? _crisisReply : _crisisReplyEn,
        recommendations: const ['counsellorCall', 'findDoctor'],
      );
    }

    if (_serverMode && await _serverUp()) {
      final hosted = await _callServer(message, turns);
      if (hosted != null) {
        // The trained model authors the text. Suggestions stay the app's own
        // on-topic shortcut chips: shown the first time a topic is raised.
        return WillowChatResult(
          text: hosted.text,
          recommendations: topicRecsForFirstMention(),
        );
      }
      // Health said up but the call failed: remember it so we don't keep
      // hammering a dying server, and fall back to the in-app brain.
      _markServerDown();
      debugPrint('Model server unreachable, falling back to in-app brain');
    }

    // Follow the user's mind across the recent window, but never let history
    // override a clear new direction: the current message's own topic wins;
    // a recurring theme (2+ mentions) is only used when the current message
    // doesn't name a topic.
    final topic =
        singleTopic ?? _recurringTopic(userTexts, isSi) ?? _identifiedMindState;
    final recs = topicRecsForFirstMention();

    final bool isGreeting = isSi
        ? _greetingSignals.any(q.contains)
        : _greetingSignalsEn.any((s) => _matchesWholeWord(q, s));
    if (isGreeting) {
      return WillowChatResult(
        text: _pickVariant(
          isSi ? _greetingReplies : _greetingRepliesEn,
          '$q#g',
        ),
      );
    }

    if (_hasUnnegatedPositive(
      isSi ? _positiveSignals : _positiveSignalsEn,
      q,
      isSi,
    )) {
      return WillowChatResult(
        text: _pickVariant(
          isSi ? _positiveReplies : _positiveRepliesEn,
          '$q#${userTexts.length}',
        ),
      );
    }

    // A clear "thank you" deserves a "you're welcome", not a random happy reply.
    if ((isSi && _thanksSignalsSi.any(q.contains)) ||
        (!isSi && _thanksSignalsEn.any((s) => _matchesWholeWord(q, s)))) {
      return WillowChatResult(
        text: _pickVariant(isSi ? _thanksRepliesSi : _thanksRepliesEn, '$q#t'),
      );
    }

    String text = _curatedReply(topic, q, isSi);
    // The bot keeps following the user's mind: when the same dominant topic
    // recurs across the recent window, name it and carry the thread forward.
    if (topic != null &&
        (_topicHits(topic, userTexts, isSi) > 1 ||
            topic == _identifiedMindState)) {
      text = '${isSi ? _continuitySi : _continuityEn} $text';
    } else if (_identifiedMindState != null && userTexts.length >= 5) {
      // After identifying mind state (5+ messages), continue conversation in line with it
      text = _curatedReply(_identifiedMindState, q, isSi);
    }
    debugPrint(
      'Willow topic=$topic identified=$_identifiedMindState msgCount=$_userMessageCount sinhala=$isSi gemini=${_apiKey.isNotEmpty}',
    );
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
          .timeout(const Duration(seconds: 3));
      return response.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  /// Ask the hosted model server (Kaggle notebook via tunnel) for a reply.
  static Future<WillowChatResult?> _callServer(
    String message,
    List<WillowTurn> turns,
  ) async {
    try {
      final response = await http
          .post(
            Uri.parse('$_baseUrl/chat'),
            headers: {
              'Content-Type': 'application/json',
              'cf-access-client-id': 'bypass',
              'User-Agent': 'MindCareApp/1.0',
            },
            body: jsonEncode({
              'message': message,
              'lang': _looksSinhala(message) ? 'si' : 'en',
              'history': [
                for (final t in turns) {'role': t.role, 'content': t.text},
              ],
              if (_identifiedMindState != null &&
                  (_userMessageCount >= 5 ||
                      turns.where((t) => t.role == 'user').length + 1 >= 5))
                'mind_state': _identifiedMindState,
              if (_identifiedMindState != null &&
                  (_userMessageCount >= 5 ||
                      turns.where((t) => t.role == 'user').length + 1 >= 5))
                'identified_mind_state': _identifiedMindState,
              if (_identifiedMindState != null &&
                  (_userMessageCount >= 5 ||
                      turns.where((t) => t.role == 'user').length + 1 >= 5))
                'context':
                    'USER_MIND_STATE: $_identifiedMindState (identified after first $_userMessageCount messages)',
            }),
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
      return WillowChatResult(text: text, recommendations: recommendations);
    } catch (e) {
      debugPrint('Hosted server unreachable: $e');
      return null;
    }
  }

  static bool _isSinhala(int r) => r >= 0x0d80 && r <= 0x0dff;

  /// Rejects incoherent model output (digit-soup, mixed-scrambled, digit-garbage).
  /// A reply is acceptable when it is coherently Sinhala-dominant or
  /// Latin-dominant; muddled mixes of both are rejected. A reply may be short:
  /// the persona answers in 1-3 sentences, and natural Sinhala sentences end
  /// in vowel signs (e.g. ා/ි/ු) or ව, so no trailing-rune rule is applied.
  static bool _looksUsable(String text) {
    final s = text.trim();
    if (s.runes.length < 6) return false;
    if (s.contains('&') || s.contains('#') || s.contains('\uFFFD')) {
      return false;
    }
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
    return true;
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

  static List<String> _tokenizeWords(String text) => RegExp(
    r"[a-zA-Z]+(?:'[a-zA-Z]+)?",
  ).allMatches(text).map((m) => m.group(0)!).toList();

  /// Whole-word phrase matching for English so "hi" never matches inside
  /// "everything" and "rent" never matches inside "parents". Matches when a
  /// phrase's words appear consecutively as complete tokens.
  static bool _matchesWholeWord(String text, String phrase) {
    final tokens = _tokenizeWords(text);
    final words = phrase.split(' ');
    if (words.length > tokens.length) return false;
    for (var i = 0; i + words.length <= tokens.length; i++) {
      var ok = true;
      for (var j = 0; j < words.length; j++) {
        if (tokens[i + j] != words[j]) {
          ok = false;
          break;
        }
      }
      if (ok) return true;
    }
    return false;
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

  /// True when any of the recent user texts contains a signal (used for
  /// crisis: a danger statement anywhere in the window is never ignored).
  static bool _hasSignal(List<String> signals, List<String> texts) {
    for (final t in texts) {
      final n = _normalize(t);
      if (n.isEmpty) continue;
      if (signals.any(n.contains)) return true;
    }
    return false;
  }

  /// A positive signal only counts when it is NOT negated, so "I'm not happy",
  /// "not good" or "unhappy" never get a cheerful reply. English signals are
  /// matched whole-word (so "happy" inside "unhappy" doesn't count); Sinhala
  /// uses a short window around the match to catch "සතුටුයි නෑ".
  static bool _hasUnnegatedPositive(List<String> signals, String q, bool isSi) {
    if (isSi) {
      for (final s in signals) {
        if (!q.contains(s)) continue;
        final idx = q.indexOf(s);
        final from = idx > 12 ? idx - 12 : 0;
        var to = idx + s.length + 12;
        if (to > q.length) to = q.length;
        final window = q.substring(from, to);
        if (_negationWordsSi.any(window.contains)) return false;
      }
      return signals.any(q.contains);
    }
    final tokens = _tokenizeWords(q);
    final negations = _negationWords.toSet();
    for (final s in signals) {
      final phrase = s.split(' ');
      for (var i = 0; i + phrase.length <= tokens.length; i++) {
        var ok = true;
        for (var j = 0; j < phrase.length; j++) {
          if (tokens[i + j] != phrase[j]) {
            ok = false;
            break;
          }
        }
        if (!ok) continue;
        final before = i > 3 ? tokens.sublist(i - 3, i) : tokens.sublist(0, i);
        final afterStart = i + phrase.length;
        final afterEnd = afterStart + 3 < tokens.length
            ? afterStart + 3
            : tokens.length;
        final context = [...before, ...tokens.sublist(afterStart, afterEnd)];
        if (context.any(negations.contains)) return false;
        return true;
      }
    }
    return false;
  }

  static const List<String> _negationWords = [
    'not',
    "isn't",
    'isnt',
    'arent',
    "aren't",
    'wasnt',
    "wasn't",
    'werent',
    "weren't",
    "can't",
    'cant',
    "couldn't",
    'couldnt',
    "don't",
    'dont',
    "doesn't",
    'doesnt',
    "didn't",
    'didnt',
    "won't",
    'wont',
    'never',
    'without',
    'no',
    'hardly',
    'least',
  ];

  static const List<String> _negationWordsSi = [
    ' නෑ',
    ' නැහැ ',
    ' නැ ',
    ' බෑ',
    ' බැරි ',
    ' නෙමෙයි ',
    'කමක් නෑ',
  ];

  /// Picks the topic that dominates the whole recent conversation (used to see
  /// whether a theme recurs, so the reply keeps following the user's mind).
  static String? _pickTopicAcross(List<String> texts, bool isSi) {
    if (texts.isEmpty) return null;
    final bonus = <String, double>{};
    for (final t in texts) {
      _scoreText(t, isSi, bonus);
    }
    return _best(bonus);
  }

  /// Topic of the current message only — always wins over history so a clear
  /// new message is answered on its own terms.
  static String? _pickTopicForSingle(String q, bool isSi) {
    if (q.isEmpty) return null;
    final bonus = <String, double>{};
    _scoreText(q, isSi, bonus);
    return _best(bonus);
  }

  /// The recurring theme of the recent window, but only if it appears in at
  /// least two user messages — that is the "mind identified over 5-6
  /// messages" the bot should keep following.
  static String? _recurringTopic(List<String> texts, bool isSi) {
    final top = _pickTopicAcross(texts, isSi);
    if (top == null) return null;
    return _topicHits(top, texts, isSi) >= 2 ? top : null;
  }

  static void _scoreText(String text, bool isSi, Map<String, double> bonus) {
    final n = _normalize(text);
    if (n.isEmpty) return;
    for (final trigger in isSi ? _topicTriggers : _topicTriggersEn) {
      final word = trigger.$1;
      // Sinhala uses substring matching (word stems like යාළු match යාළුවා);
      // English uses whole-word matching so "rent" can't match "parents".
      final matched = isSi ? n.contains(word) : _matchesWholeWord(n, word);
      if (matched) {
        final weight = trigger.$2;
        for (final tp in trigger.$3) {
          bonus[tp] = (bonus[tp] ?? 0) + weight;
        }
      }
    }
  }

  static String? _best(Map<String, double> bonus) {
    String? best;
    var bestScore = 0.0;
    bonus.forEach((tp, s) {
      if (s > bestScore) {
        bestScore = s;
        best = tp;
      }
    });
    return best;
  }

  static String _curatedReply(String? topic, String q, bool isSi) {
    final replies = isSi ? _topicReplies : _topicRepliesEn;
    final variants = topic == null ? null : replies[topic];
    if (variants == null || variants.isEmpty) {
      // Untracked messages get an echo-reflection built from the user's own
      // words, plus a rotating closer — so replies are never the same twice.
      return _reflectReply(q, isSi);
    }
    final base = _pickVariant(variants, q);
    final closer = _pickVariant(
      isSi ? _reflectionClosersSi : _reflectionClosersEn,
      '$q#${replies.length}',
    );
    return '$base $closer';
  }

  /// Deterministic variant picker seeded by the message so different inputs
  /// surface different reply phrasings.
  static String _pickVariant(List<String> variants, String seed) {
    if (variants.isEmpty) return '';
    return variants[(seed.hashCode & 0x7fffffff) % variants.length];
  }

  /// Warm, natural reply for messages the topic rules don't cover. Each reply
  /// is a complete sentence pair (no quoting back the user's words), picked
  /// deterministically per message so no two inputs get the identical text.
  static String _reflectReply(String q, bool isSi) {
    final opener = _pickVariant(
      isSi ? _reflectionOpenersSi : _reflectionOpenersEn,
      '$q#o',
    );
    final closer = _pickVariant(
      isSi ? _reflectionClosersSi : _reflectionClosersEn,
      '$q#c',
    );
    return '$opener $closer';
  }

  /// How many recent user messages mention a trigger for this topic.
  static int _topicHits(String topic, List<String> texts, bool isSi) {
    var hits = 0;
    for (final t in texts) {
      final n = _normalize(t);
      if (n.isEmpty) continue;
      for (final trigger in isSi ? _topicTriggers : _topicTriggersEn) {
        if (n.contains(trigger.$1) && trigger.$3.contains(topic)) {
          hits++;
          break;
        }
      }
    }
    return hits;
  }

  static const String _crisisReply =
      "ඔයා දැන් ගොඩක් දුෂ්කර තත්වයක් පසු කරනවා. ඔයා තනිවම මේ ජීවිතේ "
      "අරගන්න ඕන නෑ. කරුණාකර වහාම වෘත්තීය උදව් ලබාගන්න: 1926 (මානසික "
      "සුබසාධන හෙල්ප්ලයින්), නැතහොත් ශ්රී ලංකාවේ ස්ත්රීන් සහ ළමයින් "
      "නතර කිරීමේ අංකය 1929 අමතන්න, නැතහොත් ළඟම රෝහලට යන්න. ඔයා වැදගත්.";

  static const List<String> _greetingSignals = [
    "හෙලෝ",
    "ආයුබෝවන්",
    "ආයුබෝ",
    "සුභ",
    "කොහොමද",
  ];

  static const List<String> _greetingReplies = [
    "ආයුබෝ! 😊 ඔයා කොහොමද ඉන්නේ? ඔයාගේ හිතේ ඇති දේ මට කියන්න.",
    "හෙලෝ! 🌿 ඔයාව දැකීම සතුටක්. මොනවද අද හිතේ තියෙන්නේ?",
    "ආයුබෝ! අද දවස කොහොමද? මම මෙතනම ඉන්නවා, ඕන ඕන දේ කියන්න.",
  ];

  static const List<String> _positiveReplies = [
    "හොඳට අහන්න ගොඩක් සතුටුයි! ඔයාට මොනවා හරි උදව්වක් ඕන වුණොත්, ඕනෑම වෙලාවක මෙතන කතා කරන්න.",
    "ඒක ඇහුනාම මට ලොකු සතුටක්. ඒ හොඳ හැඟීම ටිකක් රසවිඳින්න — ඔයා ඒකට වටිනවා.",
    "සතුටුයි! ඔයා කැමති නම්, ඒ හොඳ දවස ගැනත් ටිකක් කියන්න.",
  ];

  static const List<String> _thanksSignalsEn = [
    'thank',
    'thanks',
    'thank you',
    'thx',
  ];

  static const List<String> _thanksRepliesEn = [
    "You're so welcome! 💚 I'm here whenever you need me.",
    "Anytime — that's what I'm here for. 💚",
    "Of course. 🌿 Keep going; you're doing better than you think.",
  ];

  static const List<String> _thanksSignalsSi = ['ස්තූතියි', 'ස්තූතිය', 'ස්තූත'];

  static const List<String> _thanksRepliesSi = [
    "ඔයාට පිළිගන්නම්! 💚 ඕනෑම වෙලාවක මම මෙතන ඉන්නවා.",
    "සතුටක්! 🌿 මේ විදියට කතා කරන්න දිගටම එන්න.",
  ];

  static const String _continuitySi =
      "අපි දිගටම මේ ගැන කතා කරනවා — ඒකට නමක් තියෙනවා. මම ඔයා එක්ක ඉන්නවා.";

  static const List<String> _reflectionOpenersSi = [
    "මම ඔයාට ඇහුම්කන් දෙනවා, ඒක ලොකු දෙයක්.",
    "මේක මට කිව්ව එකට ස්තූතියි.",
    "ඒක ඔයාට ලොකු බරක් වෙන්න ඇති.",
    "මම දැන් මෙතනම ඉන්නවා, ඔයා එක්ක.",
  ];

  static const List<String> _reflectionClosersSi = [
    "අද දවස වුණේ කොහොමද, පොඩ්ඩක් කියන්නකෝ?",
    "ඒ ගැන තව ටිකක් කියන්න කැමතිද?",
    "මේ දේවල් කොච්චර කාලයක් ඔයා එක්ක තියෙනවාද?",
    "ඔයාට දැන්ම හොඳටම බරක් දැනෙන්නේ මොකක්ද?",
  ];

  static const String _crisisReplyEn =
      "You're going through something very hard right now, and you don't "
      "have to carry this alone. Please reach out for professional help "
      "right away: call 1926 (national mental-health helpline) or 1929 "
      "(National Child Protection Authority), or go to your nearest hospital. "
      "You matter, and people can help.";

  static const List<String> _greetingSignalsEn = [
    "hi",
    "hello",
    "hey",
    "good morning",
    "good afternoon",
    "good evening",
    "how are you",
  ];

  static const List<String> _greetingRepliesEn = [
    "Hey there! 😊 How are you doing today?",
    "Hello! 🌿 Good to see you. What's on your mind?",
    "Hi! How's your day going? I'm right here if you want to talk.",
  ];

  static const List<String> _positiveRepliesEn = [
    "That's lovely to hear! If you ever need someone to talk to, I'm always here.",
    "That genuinely makes me glad. Hold on to that good feeling for a moment — you deserve it.",
    "Happy to hear that! If you'd like, tell me a little about what made it good.",
    "You're so welcome! 💚 I'm here whenever you need someone to talk to.",
  ];

  static const String _continuityEn =
      "We keep landing here, and that's worth naming — I'm right here with you.";

  static const List<String> _reflectionOpenersEn = [
    "I hear you, and that counts for a lot.",
    "Thank you for trusting me with that.",
    "That sounds like it carries real weight.",
    "I'm right here with you in this moment.",
  ];

  static const List<String> _reflectionClosersEn = [
    "How has today felt, one small bit at a time?",
    "Would you like to say a little more about it?",
    "How long has this been sitting with you?",
    "If you had to name the hardest part, what would it be?",
  ];

  static const List<String> _crisisSignals = [
    "සියදිවි",
    "මැරෙන්න",
    "මැරෙනවා",
    "මැරුණොත්",
    "මැරිලා",
    "ජීවත් වෙන්න ඕන නෑ",
    "ජීවත් වෙන්න බෑ",
    "කපාගන්න",
    "තුවාල කරගන්න",
    "ඉවසන්න බැරි",
    "මට ඉවසන්න බෑ",
    "මගෙන් කමක් නෑ",
  ];

  static const List<String> _positiveSignals = [
    "ස්තූතියි",
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
    "i want to die",
    "want to die",
    "wanna die",
    "end it all",
    "end everything",
    "not worth living",
    "better off dead",
    "don't want to live",
    "dont want to live",
    "no reason to live",
    "can't take it anymore",
    "cant take it anymore",
    "can't go on",
    "cant go on",
    "give up on life",
    "cut myself",
    "hurt myself",
    "self harm",
    "better off without me",
    "better off dead",
    "no one would miss me",
    "no one will miss me",
    "nobody would miss me",
    "nobody will miss me",
    "wish i was dead",
    "wish i wasn't here",
    "i shouldn't be here",
    "i don't want to be here",
    "dont want to be here",
  ];

  static const List<String> _positiveSignalsEn = [
    "thank you",
    "thanks",
    "feeling good",
    "feel good",
    "feel better",
    "feeling better",
    "i'm fine",
    "im fine",
    "doing well",
    "happy",
    "great day",
    "wonderful",
  ];

  static const Map<String, List<String>> _topicRecs = {
    'academic_stress': ['journal', 'moodTracker'],
    'anxiety': ['breathing', 'calmMusic'],
    'burnout': ['calmMusic', 'journal'],
    'depression': ['moodTracker', 'counsellorCall'],
    'loneliness': ['counsellorCall'],
    'sleep': ['breathing'],
    'relationships': ['journal'],
    'breakup': ['journal', 'moodTracker'],
    'family': ['journal'],
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
    ('කවුරුවත් නෑ', 2.8, ['loneliness']),
    ('කතා කරන්නේ නෑ', 2.6, ['loneliness']),
    ('කතා කරන්න කෙනෙක්', 2.6, ['loneliness']),
    ('මහන්සි', 3.0, ['burnout']),
    ('වෙහෙස', 2.6, ['burnout']),
    ('හෙම්බත්', 2.6, ['burnout']),
    ('බය', 2.2, ['anxiety']),
    ('බිය', 2.2, ['anxiety']),
    ('කලබල', 2.6, ['anxiety']),
    ('භීතිය', 2.6, ['anxiety']),
    ('අවුල්', 2.4, ['anxiety']),
    ('දුක', 3.0, ['depression']),
    ('කඳුළු', 2.6, ['depression']),
    ('අඬන', 2.6, ['depression']),
    ('කන්න ඕන නෑ', 2.6, ['depression']),
    ('අහිමි', 3.0, ['grief']),
    ('මිය', 3.0, ['grief']),
    ('මිය ගිය', 3.6, ['grief']),
    ('මරණ', 2.6, ['grief']),
    ('යාළු', 2.2, ['relationships']),
    ('යහළු', 2.2, ['relationships']),
    ('රණ්ඩු', 2.2, ['relationships']),
    ('කේන්ති', 2.4, ['emotions']),
    ('බැඳීම්', 2.0, ['relationships']),
    ('වෙන් වුණා', 2.8, ['breakup']),
    ('වෙන් වෙන්න', 2.6, ['breakup']),
    ('බිඳීම', 2.6, ['breakup']),
    ('බිඳෙනවා', 2.6, ['breakup']),
    ('අම්මා තාත්තා රණ්ඩු', 2.8, ['family']),
    ('දෙමාපියන් රණ්ඩු', 2.8, ['family']),
    ('දික්කසාද', 3.0, ['family']),
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
    ('ඉගෙන ගන්න බැරි', 2.6, ['academic_stress']),
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
    ('deadlines', 2.4, ['academic_stress']),
    ('assignments', 2.2, ['academic_stress', 'time_management']),
    ('subjects', 2.2, ['academic_stress']),
    ('subject', 2.2, ['academic_stress']),
    ('lecture', 2.0, ['academic_stress']),
    ('sleep', 2.2, ['sleep']),
    ('sleepless', 2.4, ['sleep']),
    ('insomnia', 2.6, ['sleep']),
    ('awake', 2.2, ['sleep']),
    ('bed', 2.0, ['sleep']),
    ("can't sleep", 2.6, ['sleep']),
    ('cant sleep', 2.6, ['sleep']),
    ('trouble sleeping', 2.4, ['sleep']),
    ('lonely', 2.6, ['loneliness']),
    ('loneliness', 2.6, ['loneliness']),
    ('alone', 2.2, ['loneliness']),
    ('isolated', 2.4, ['loneliness']),
    ('no friends', 2.6, ['loneliness']),
    ('any friends', 2.6, ['loneliness']),
    ('have no friends', 2.6, ['loneliness']),
    ('friendless', 2.6, ['loneliness']),
    ('tired', 3.0, ['burnout']),
    ('exhausted', 3.0, ['burnout']),
    ('exhausting', 2.8, ['burnout']),
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
    ('pointless', 3.0, ['depression']),
    ('meaningless', 2.8, ['depression']),
    ('no point', 2.8, ['depression']),
    ('numb', 2.6, ['depression']),
    ('grief', 3.0, ['grief']),
    ('died', 2.6, ['grief']),
    ('death', 2.4, ['grief']),
    ('passed away', 3.0, ['grief']),
    ('loss', 2.6, ['grief']),
    ('funeral', 2.6, ['grief']),
    ('friend', 2.2, ['relationships']),
    ('friends', 2.2, ['relationships']),
    ('relationship', 2.2, ['relationships']),
    ('girlfriend', 2.2, ['relationships']),
    ('boyfriend', 2.2, ['relationships']),
    ('argued', 2.4, ['relationships']),
    ('argument', 2.4, ['relationships']),
    ('fighting', 2.4, ['relationships']),
    ('fights', 2.4, ['relationships']),
    ('fight', 2.2, ['relationships']),
    ('angry', 2.4, ['emotions']),
    ('miss him', 2.2, ['relationships']),
    ('miss her', 2.2, ['relationships']),
    ('broke up', 3.0, ['breakup']),
    ('break up', 2.6, ['breakup']),
    ('breakup', 2.6, ['breakup']),
    ('broken up', 2.8, ['breakup']),
    ('dumped', 2.6, ['breakup']),
    ('broke my heart', 3.0, ['breakup']),
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
    ('broke', 2.4, ['financial']),
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
    ('settling in', 2.6, ['transitions']),
    ('fail', 2.4, ['fear_of_failure']),
    ('failing', 2.6, ['fear_of_failure']),
    ('failed', 2.6, ['fear_of_failure']),
    ('fails', 2.6, ['fear_of_failure']),
    ('failure', 2.6, ['fear_of_failure']),
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
    'breakup': [
      "බිඳීමක් සැබෑ වේදනාවක්. දැන් ඔයාට දැනෙන ඕනෑම හැඟීමක් — වේදනාව, අවුල, සහනය — ඒගොල්ලෝ හැම එකක්ම වලංගුයි. අද දවසේ පොඩි පියවරකින් ඔයාටම කරුණාවන්ත වෙන්න.",
      "වෙන්වීමකට පස්සේ හිතට සැහැල්ලු වෙන්න කාලය ඕන. ඔයා කවුද කියන දේ ඒ සම්බන්ධය තීරණය කරන්නේ නෑ. විශ්වාස කරන කෙනෙක් එක්ක ඒ ගැන කතා කරන්න.",
    ],
    'family': [
      "ආදරය කරන අය අතර ගැටුම් දකිනකොට, හිතට ලොකු බරක් දැනෙනවා. ඒක ඔයාගේ වරදක් නෙමෙයි. මේ කාලයේ ඔයාටම කරුණාවන්ත වෙන්න.",
      "අම්මා තාත්තා අතර වෙනස්කම් දකින එක අසරණ වෙන සුළු දෙයක්. පොඩි නිස්කලංක මොහොතක් ගන්න, පුළුවන් නම් විශ්වාස කරන කෙනෙක් එක්ක ඒ ගැන කතා කරන්න.",
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
    'breakup': [
      "Breakups are genuinely painful, and there's no wrong way to feel right now — hurt, confusion, even relief are all valid. Be gentle with yourself today, hour by hour.",
      "A breakup rearranges things, but it doesn't define who you are. You're still you — worthy of love and respect. Talk it through with someone you trust, and take the hurt one day at a time.",
    ],
    'family': [
      "When the people you love clash, it can feel out of your hands, and that weight is real. You're not responsible for fixing it — be kind to yourself while it settles.",
      "Watching your family argue is unsettling. Give yourself a few quiet minutes, and if you can, tell someone you trust how it's affecting you.",
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
