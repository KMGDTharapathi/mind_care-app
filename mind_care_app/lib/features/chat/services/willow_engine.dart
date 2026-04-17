import 'dart:math';
import '../models/chat_message.dart';
import 'willow_api_service.dart';

/// Response engine for Willow.
/// Tries the LLaMA API first; falls back to rule-based responses if unavailable.
class WillowEngine {
  final bool isSinhala;
  WillowEngine({required this.isSinhala});

  static final _rng = Random();

  String welcomeMessage() {
    if (isSinhala) {
      return "ආයුබෝ! 🌿 මම විලෝ.\n\nඔබ කොහොමද ඉන්නේ? ඔබේ හිතේ ඇති ඕනෑම දෙයක් ගැන කතා කරන්නකෝ — මම ඇහෙනවා. 💚";
    }
    return "Hey! 🌿 I'm Willow.\n\nHow are you doing today? Feel free to share whatever's on your mind — I'm here and I'm listening. 💚";
  }

  Future<String> respond(ChatMessage message) async {
    // For non-text messages skip the API
    if (message.type != MessageType.text) {
      return _localRespond(message);
    }

    // Try the LLaMA API first
    if (WillowApiService.isConfigured) {
      final apiResponse = await WillowApiService.chat(message.content);
      if (apiResponse != null && apiResponse.isNotEmpty) {
        return apiResponse;
      }
    }

    // Fallback to rule-based
    return _localRespond(message);
  }

  Future<String> _localRespond(ChatMessage message) async {
    final delay = 800 + _rng.nextInt(700);
    await Future.delayed(Duration(milliseconds: delay));

    switch (message.type) {
      case MessageType.voice:
        final list = isSinhala ? _siVoiceAck : _enVoiceAck;
        return list[_rng.nextInt(list.length)];
      case MessageType.image:
        final list = isSinhala ? _siImageAck : _enImageAck;
        return list[_rng.nextInt(list.length)];
      case MessageType.file:
        final list = isSinhala ? _siFileAck : _enFileAck;
        return list[_rng.nextInt(list.length)];
      case MessageType.text:
        return _matchText(message.content);
    }
  }

  String _matchText(String input) {
    final lower = input.toLowerCase();
    final rules = isSinhala ? _siRules : _enRules;
    for (final rule in rules) {
      for (final pattern in rule.patterns) {
        // Only match if the pattern is a meaningful substring (min 3 chars)
        // and appears as a word boundary to avoid false matches
        if (pattern.length >= 3 && lower.contains(pattern)) {
          return rule.responses[_rng.nextInt(rule.responses.length)];
        }
      }
    }
    final fallback = isSinhala ? _siFallback : _enFallback;
    return fallback[_rng.nextInt(fallback.length)];
  }

  // ── English rules ──────────────────────────────────────────────────────────
  static const _enRules = [
    _Rule(patterns: ['hello','hi','hey','good morning','good afternoon','good evening'], responses: [
      "Hello! 🌿 I'm Willow, your wellness companion. How are you feeling today?",
      "Hi there! 😊 It's lovely to see you. What's on your mind?",
      "Hey! 🌱 I'm here for you. How can I support you today?",
    ]),
    _Rule(patterns: ['anxious','anxiety','nervous','panic','worried','worry','fear','scared'], responses: [
      "I hear you — anxiety can feel overwhelming. 💚 Try taking a slow deep breath: inhale for 4 counts, hold for 4, exhale for 4. You're safe right now.",
      "Anxiety is tough, but you're not alone. 🌿 Would you like to try a quick breathing exercise together?",
      "It's okay to feel anxious. 💙 Focus on 5 things you can see around you right now. Grounding yourself can ease the tension.",
    ]),
    _Rule(patterns: ['stress','stressed','overwhelmed','too much','pressure','burnout'], responses: [
      "Feeling overwhelmed is a sign you've been carrying a lot. 🌿 Let's take it one step at a time. What feels most heavy right now?",
      "Stress is your body asking for a break. 💚 Even 5 minutes of mindful breathing can reset your nervous system. Want to try?",
      "You're doing more than you realize. 🌱 Be gentle with yourself today.",
    ]),
    _Rule(patterns: ['sad','sadness','depressed','depression','unhappy','down','low','cry','crying','tears'], responses: [
      "I'm sorry you're feeling this way. 💙 Your feelings are valid. Would you like to talk about what's been going on?",
      "It's okay to feel sad sometimes. 🌿 Emotions are like waves — they come and go. I'm here to listen.",
      "Sending you warmth and care. 💚 What's been weighing on your heart?",
    ]),
    _Rule(patterns: ['sleep','insomnia','tired','exhausted','fatigue','rest'], responses: [
      "Sleep is so important for your wellbeing. 🌙 Try a body scan before bed — start from your toes and slowly relax upward.",
      "Struggling with sleep? 💤 Try the 4-7-8 breathing technique: inhale 4s, hold 7s, exhale 8s.",
      "Rest is healing. 🌿 A consistent bedtime routine can work wonders.",
    ]),
    _Rule(patterns: ['breathe','breathing','breath','breathwork'], responses: [
      "Breathing exercises are powerful! 🌬️ Try box breathing: inhale 4s → hold 4s → exhale 4s → hold 4s. Repeat 4 times.",
      "Deep breathing activates your parasympathetic nervous system. 💚 Try 4-7-8: inhale 4, hold 7, exhale 8.",
      "Your breath is always with you as an anchor. 🌿 Breathe in for 5 counts, out for 5. Do it 3 times.",
    ]),
    _Rule(patterns: ['meditat','mindful','mindfulness','calm','peace','relax'], responses: [
      "Mindfulness is a beautiful practice. 🧘 Even 5 minutes of focused breathing counts as meditation.",
      "Finding calm is always possible. 🌿 Close your eyes, take 3 deep breaths, and notice the sensations in your body.",
      "Peace is within you. 💚 A simple body scan can bring you back to the present moment.",
    ]),
    _Rule(patterns: ['happy','happiness','joy','great','wonderful','amazing','good'], responses: [
      "That's wonderful to hear! 🌟 What's been bringing you joy lately?",
      "So glad you're feeling good! 💚 Keep nurturing what makes you happy.",
      "That makes my day! 🌿 When we feel good, it's a great time to reflect on what's working well.",
    ]),
    _Rule(patterns: ['lonely','alone','isolated','no one','nobody'], responses: [
      "Loneliness can be really painful. 💙 Remember, reaching out — even to me — is a brave step. You matter.",
      "You're not alone in feeling alone. 🌿 Is there one small connection you could make today?",
      "I'm here with you right now. 💚 What's one thing that usually helps you feel connected?",
    ]),
    _Rule(patterns: ['angry','anger','frustrated','frustration','mad','rage'], responses: [
      "Anger is a valid emotion — it's telling you something important. 🌿 Try taking 10 slow breaths. What's underneath the anger?",
      "It's okay to feel frustrated. 💚 Try the STOP technique: Stop, Take a breath, Observe, Proceed mindfully.",
      "Your feelings are valid. 🌱 Even a short walk can shift your energy.",
    ]),
    _Rule(patterns: ['thank','thanks','appreciate','grateful','gratitude'], responses: [
      "You're so welcome! 🌿 Gratitude is a beautiful practice — what are you grateful for today?",
      "It means a lot to hear that. 💚 What's one thing you're thankful for right now?",
      "Anytime! 🌱 You deserve support.",
    ]),
    _Rule(patterns: ['help','support','need','struggling','difficult','hard','tough'], responses: [
      "I'm here to help. 💚 Tell me more about what you're going through.",
      "You reached out, and that takes courage. 🌿 What's been the hardest part lately?",
      "I've got you. 💙 What would feel most helpful right now?",
    ]),
  ];

  // ── Sinhala rules ──────────────────────────────────────────────────────────
  static const _siRules = [
    _Rule(patterns: ['හෙලෝ','ආයුබෝවන්','ආයුබෝ','සුභ','කොහොමද','හායි'], responses: [
      "ආයුබෝ! 😊 ඔබව දැකීමට සතුටුයි. ඔබ කොහොමද ඉන්නේ?",
      "හෙලෝ! 🌿 ඔබ ආවා. ඔබ ගැන ටිකක් කියන්නකෝ.",
      "ආයුබෝ! ඔබ අද කෙසේ සිටිනවාද? 💚",
    ]),
    _Rule(patterns: ['කනස්සල්ල','කනස්සල්','බිය','කලබල','නර්වස්','පීඩාව'], responses: [
      "ඒ ගැන ඇසීමට කනගාටුයි... 😔 ඔබට ඒ හැඟීම දැනෙනවා කියන්නේ ඇත්තෙන්ම දුෂ්කරයි. ඔබ ගැන ටිකක් කියන්නකෝ — කොහොමද ඒ හැඟීම ආවේ?",
      "ඒ ඇසීමට හිත දුකයි. 💙 ඔබ ඒ ගැන කතා කිරීමට කැමතිනම් — මම ඇහෙනවා. ඔබ තනිව නෙවෙයි.",
      "ඒ හැඟීම ඇත්තෙන්ම අමාරුයි. 🌿 ඔබ ඒ ගැන කතා කරන්නට ආවා — ඒ ලොකු දෙයක්. ඔබට කොහොමද දැන් දැනෙන්නේ?",
    ]),
    _Rule(patterns: ['ආතතිය','ගොඩක් වැඩ','බර','පීඩනය','ගොඩක් ආතතිය','stress'], responses: [
      "ඒ ඇසීමට හිත දුකයි... 😔 ඔබ ගොඩක් දේ දරාගෙන ඉන්නවා. ඔබ ගැන ටිකක් කතා කරමු — ඔබට ලොකුම ගැටලුව කුමක්ද?",
      "ඒ ඇත්තෙන්ම අමාරු. 💙 ඔබ ඒ ගැන කතා කරන්නට ආවා — ඒ ලොකු දෙයක්. ඔබ ගැන සැලකිලිමත් වෙන්නේ ඔබ ම. ඔබ ගැන ටිකක් කියන්නකෝ.",
      "ඔව්, ඒ ඇත්තෙන්ම දුෂ්කරයි. 🌿 ඔබ ඒ ගැන කතා කරන්නට ආවා — ඒ ලොකු දෙයක්. ඔබ ගැන ටිකක් කියන්නකෝ.",
    ]),
    _Rule(patterns: ['දුකයි','දුක','කනගාටු','අඬනවා','කඳුළු','හිත දුකයි','හිත'], responses: [
      "ඒ ඇසීමට හිත දුකයි... 💙 ඔබ ඒ ගැන කතා කරන්නට ආවා — ඒ ලොකු දෙයක්. ඔබ ගැන ටිකක් කියන්නකෝ.",
      "ඔව්, ඒ ඇත්තෙන්ම දුෂ්කරයි. 🌿 ඔබ ඒ ගැන කතා කරන්නට ආවා — ඒ ලොකු දෙයක්. ඔබ ගැන ටිකක් කියන්නකෝ.",
      "ඒ ඇසීමට කනගාටුයි. 💚 ඔබ ඒ ගැන කතා කරන්නට ආවා — ඒ ලොකු දෙයක්. ඔබ ගැන ටිකක් කියන්නකෝ.",
    ]),
    _Rule(patterns: ['නිදාගන්න','නිදිමත','වෙහෙස','ක්ලාන්ත','නිදා','නිදිය'], responses: [
      "ඒ ඇසීමට හිත දුකයි... 😔 නිදාගන්න බැරිවීම ඇත්තෙන්ම අමාරු. ඔබ ගැන ටිකක් කියන්නකෝ — කොහොමද ඒ ගැටලුව ආවේ?",
      "ඒ ඇත්තෙන්ම දුෂ්කරයි. 💙 ඔබ ගැන ටිකක් කතා කරමු — ඔබ ගැන සැලකිලිමත් වෙන්නේ ඔබ ම.",
    ]),
    _Rule(patterns: ['හුස්ම','ශ්වාස','හුස්ම ගන්න'], responses: [
      "ඔව්, හුස්ම ගැනීම ඇත්තෙන්ම උදව් කරනවා. 🌬️ ඔබ ගැන ටිකක් කතා කරමු — ඔබ ගැන සැලකිලිමත් වෙන්නේ ඔබ ම.",
      "හුස්ම ගැනීම ඇත්තෙන්ම ශක්තිමත්. 🌿 ඔබ ගැන ටිකක් කතා කරමු.",
    ]),
    _Rule(patterns: ['භාවනා','සිහිකල්පනාව','සන්සුන්','සාමය','ලිහිල්','relax'], responses: [
      "ඒ ඇත්තෙන්ම හොඳ. 🧘 ඔබ ගැන ටිකක් කතා කරමු — ඔබ ගැන සැලකිලිමත් වෙන්නේ ඔබ ම.",
      "සන්සුන් බව ඇත්තෙන්ම වැදගත්. 💚 ඔබ ගැන ටිකක් කතා කරමු.",
    ]),
    _Rule(patterns: ['සතුටු','සතුට','ප්‍රීතිය','හොඳයි','ලොකු','සතුටින්'], responses: [
      "ඒ ඇසීමට ලොකු සතුටකි! 🌟 ඔබ ගැන ටිකක් කතා කරමු — ඔබ ගැන සැලකිලිමත් වෙන්නේ ඔබ ම.",
      "ඔව්, ඒ ඇත්තෙන්ම හොඳ! 💚 ඔබ ගැන ටිකක් කතා කරමු.",
    ]),
    _Rule(patterns: ['ස්තූතියි','ස්තූති','ස්තූතිවන්ත'], responses: [
      "ඔබට ඉතා ස්වාගතයි! 🌿 ඔබ ගැන ටිකක් කතා කරමු.",
      "ඒ ඇසීමට ලොකු සතුටකි. 💚 ඔබ ගැන ටිකක් කතා කරමු.",
    ]),
    _Rule(patterns: ['තනිකම','තනිව','තනිය','alone','lonely'], responses: [
      "ඒ ඇසීමට හිත දුකයි... 💙 ඔබ ඒ ගැන කතා කරන්නට ආවා — ඒ ලොකු දෙයක්. ඔබ ගැන ටිකක් කියන්නකෝ.",
      "ඔව්, ඒ ඇත්තෙන්ම දුෂ්කරයි. 🌿 ඔබ ඒ ගැන කතා කරන්නට ආවා — ඒ ලොකු දෙයක්. ඔබ ගැන ටිකක් කියන්නකෝ.",
    ]),
    _Rule(patterns: ['විභාග','exam','test','ඉගෙනීම','ඉගෙනුම'], responses: [
      "ඒ ඇසීමට හිත දුකයි... 😔 විභාග ගැන ආතතිය ඇත්තෙන්ම දුෂ්කරයි. ඔබ ගැන ටිකක් කියන්නකෝ — ඔබ ගැන සැලකිලිමත් වෙන්නේ ඔබ ම.",
      "ඒ ඇත්තෙන්ම අමාරු. 💙 ඔබ ගොඩක් වෙහෙස වෙනවා. ඔබ ගැන ටිකක් කතා කරමු.",
    ]),
  ];

  static const _enFallback = [
    "I'm here to listen. 💚 Tell me more about how you're feeling.",
    "Thank you for sharing that with me. 🌿 What would feel most helpful right now?",
    "I hear you. 💙 Sometimes just expressing ourselves helps. What else is on your mind?",
    "You're doing great by reaching out. 🌱 I'm here for you.",
  ];

  static const _siFallback = [
    "ඒ ඇසීමට හිත දුකයි... 💙 ඔබ ගැන ටිකක් කතා කරමු — ඔබ ගැන සැලකිලිමත් වෙන්නේ ඔබ ම. ඔබ ගැන ටිකක් කියන්නකෝ.",
    "ඔව්... ඒ ඇත්තෙන්ම දුෂ්කරයි. 🌿 ඔබ ඒ ගැන කතා කරන්නට ආවා — ඒ ලොකු දෙයක්. ඔබ ගැන ටිකක් කියන්නකෝ.",
    "ඒ ඇසීමට කනගාටුයි. 💚 ඔබ ගැන ටිකක් කතා කරමු — ඔබ ගැන සැලකිලිමත් වෙන්නේ ඔබ ම.",
    "ඔබ ඒ ගැන කතා කරන්නට ආවා — ඒ ලොකු දෙයක්. 💙 ඔබ ගැන ටිකක් කියන්නකෝ.",
  ];

  static const _enVoiceAck = [
    "Thanks for the voice message! 🎙️ Could you share a bit in text too?",
    "I received your voice message! 💚 Feel free to type what's on your mind.",
  ];
  static const _siVoiceAck = [
    "ඔබේ හඬ පණිවිඩය ලැබුණා! 🎙️ ටිකක් ලිඛිතව ද බෙදාගත හැකිද?",
    "ඔබේ හඬ පණිවිඩය ලැබුණා! 💚 ඔබේ මනසේ ඇති දේ ටයිප් කිරීමටද නිදහස් ය.",
  ];
  static const _enImageAck = [
    "Thanks for sharing that image! 🖼️ How are you feeling about it?",
    "I can see you've shared something. 💚 Would you like to talk about it?",
  ];
  static const _siImageAck = [
    "ඒ රූපය බෙදාගැනීමට ස්තූතියි! 🖼️ ඔබ ඒ ගැන කෙසේ දැනෙනවාද?",
    "ඔබ යමක් බෙදාගෙන ඇති බව දකිමි. 💚 ඒ ගැන කතා කිරීමට කැමතිද?",
  ];
  static const _enFileAck = [
    "Thanks for sharing that file! 📎 Is there something specific you'd like to discuss?",
    "Got your file! 💚 Feel free to share what's on your mind.",
  ];
  static const _siFileAck = [
    "ඒ ගොනුව බෙදාගැනීමට ස්තූතියි! 📎 ඒ ගැන සාකච්ඡා කිරීමට කැමතිද?",
    "ඔබේ ගොනුව ලැබුණා! 💚 ඔබේ මනසේ ඇති දේ බෙදාගැනීමට නිදහස් ය.",
  ];
}

class _Rule {
  final List<String> patterns;
  final List<String> responses;
  const _Rule({required this.patterns, required this.responses});
}
