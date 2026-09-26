import 'dart:math';
import '../models/chat_message.dart';
import 'feature_recommender.dart';
import 'willow_api_service.dart';

/// A Willow chat reply: the message text and any suggested wellness features.
class WillowReply {
  final String text;
  final List<String> recommendations;

  const WillowReply({required this.text, this.recommendations = const []});
}

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

  Future<WillowReply> respond(ChatMessage message) async {
    if (message.type != MessageType.text) {
      return WillowReply(text: await _localRespond(message));
    }
    if (WillowApiService.isConfigured) {
      final apiResponse = await WillowApiService.chat(message.content);
      if (apiResponse != null && apiResponse.text.isNotEmpty) {
        // Trust the server's recommendations; fall back to the local matcher
        // when the server (older version) did not return any.
        var recommendations = apiResponse.recommendations;
        if (recommendations.isEmpty) {
          recommendations = WellnessRecommender.recommend(
            message.content,
            isSinhala: isSinhala,
          );
        }
        return WillowReply(
          text: apiResponse.text,
          recommendations: recommendations,
        );
      }
    }
    return WillowReply(
      text: await _localRespond(message),
      recommendations: WellnessRecommender.recommend(
        message.content,
        isSinhala: isSinhala,
      ),
    );
  }

  Future<String> _localRespond(ChatMessage message) async {
    final delay = 900 + _rng.nextInt(800);
    await Future.delayed(Duration(milliseconds: delay));
    switch (message.type) {
      case MessageType.voice:
        return (_siVoiceAck + _enVoiceAck)[_rng.nextInt(isSinhala ? _siVoiceAck.length : _enVoiceAck.length)];
      case MessageType.image:
        return (isSinhala ? _siImageAck : _enImageAck)[_rng.nextInt(isSinhala ? _siImageAck.length : _enImageAck.length)];
      case MessageType.file:
        return (isSinhala ? _siFileAck : _enFileAck)[_rng.nextInt(isSinhala ? _siFileAck.length : _enFileAck.length)];
      case MessageType.text:
        return _matchText(message.content);
    }
  }

  String _matchText(String input) {
    final lower = input.toLowerCase();
    final rules = isSinhala ? _siRules : _enRules;
    for (final rule in rules) {
      for (final pattern in rule.patterns) {
        if (pattern.length >= 3 && lower.contains(pattern)) {
          return rule.responses[_rng.nextInt(rule.responses.length)];
        }
      }
    }
    final fallback = isSinhala ? _siFallback : _enFallback;
    return fallback[_rng.nextInt(fallback.length)];
  }

  static const _siRules = [
    _Rule(patterns: ['හෙලෝ','ආයුබෝවන්','ආයුබෝ','සුභ','කොහොමද','හායි'], responses: [
      "ආයුබෝ! 😊 ඔබව දැකීමට සතුටුයි. ඔබ කොහොමද?",
      "හෙලෝ! 🌿 ඔබ ආවා. මට ඔබ ගැන ටිකක් කියන්නකෝ.",
      "ආයුබෝ! අද ඔබ කොහොමද? 💚",
    ]),
    _Rule(patterns: ['කනස්සල්ල','කනස්සල්','බිය','කලබල','නර්වස්'], responses: [
      "ඔව්... ඒ හැඟීම ඇත්තෙන්ම අමාරුයි. 💙 ඔබට ඒ බිය දැනෙන්නේ කොහොමද?",
      "ඒ ඇසීමට හිත දුකයි... කනස්සල්ල ඇත්තෙන්ම දුෂ්කරයි. ඔබ ගැන ටිකක් කියන්නකෝ.",
      "ඔබ ඒ ගැන කතා කරන්නට ආවා — ඒ ලොකු දෙයක්. 🌿 ඔබට ඒ කනස්සල්ල ආවේ කොහොමද?",
      "ඒ හැඟීම දැනීම ඇත්තෙන්ම අමාරුයි... 💙 ඔබ ගැන ටිකක් කියන්නකෝ.",
    ]),
    _Rule(patterns: ['ආතතිය','ගොඩක් වැඩ','බර','පීඩනය','stress'], responses: [
      "ඔව්... ඔබ ගොඩක් දේ දරාගෙන ඉන්නවා. 😔 ඔබට ලොකුම ගැටලුව කුමක්ද?",
      "ඒ ඇත්තෙන්ම අමාරු. 💙 ඔබ ගැන ටිකක් කියන්නකෝ — ඔබට දැන් වඩාත් බරක් දැනෙන්නේ කුමක්ද?",
      "ඔබ ඒ ගැන කතා කරන්නට ආවා — ඒ ලොකු දෙයක්. 🌿 ඔබ ගැන ටිකක් කියන්නකෝ.",
      "ඒ ඇසීමට හිත දුකයි... ඔබ ගොඩක් වෙහෙස වෙනවා. 💚 ඔබ ගැන ටිකක් කතා කරමු.",
    ]),
    _Rule(patterns: ['දුකයි','දුක','කනගාටු','අඬනවා','කඳුළු'], responses: [
      "ඒ ඇසීමට හිත දුකයි... 💙 ඔබ ගැන ටිකක් කියන්නකෝ.",
      "ඔව්... ඒ ඇත්තෙන්ම දුෂ්කරයි. 🌿 ඔබට ඒ දුක දැනෙන්නේ ඇයිද?",
      "ඔබ ඒ ගැන කතා කරන්නට ආවා — ඒ ලොකු දෙයක්. 💚 ඔබ ගැන ටිකක් කියන්නකෝ.",
      "ඒ ඇසීමට කනගාටුයි... ඔබ ගැන ටිකක් කතා කරමු. 💙",
    ]),
    _Rule(patterns: ['නිදාගන්න','නිදිමත','වෙහෙස','ක්ලාන්ත','නිදා'], responses: [
      "ඔව්... නිදාගන්න බැරිවීම ඇත්තෙන්ම අමාරු. 😔 ඔබ ගැන ටිකක් කියන්නකෝ.",
      "ඒ ඇත්තෙන්ම දුෂ්කරයි. 💙 ඔබට ඒ ගැටලුව ආවේ කොහොමද?",
      "ඒ ඇසීමට හිත දුකයි... නිදාගන්න බැරිවීම ශරීරයටත් මනසටත් බරක්. 🌿 ඔබ ගැන ටිකක් කියන්නකෝ.",
    ]),
    _Rule(patterns: ['තනිකම','තනිව','තනිය','lonely'], responses: [
      "ඒ ඇසීමට හිත දුකයි... 💙 තනිකම ඇත්තෙන්ම වේදනාකාරීයි. ඔබ ගැන ටිකක් කියන්නකෝ.",
      "ඔව්... ඒ හැඟීම ඇත්තෙන්ම දුෂ්කරයි. 🌿 ඔබ ඒ ගැන කතා කරන්නට ආවා — ඒ ලොකු දෙයක්.",
      "ඒ ඇසීමට කනගාටුයි. 💚 ඔබ ගැන ටිකක් කතා කරමු.",
    ]),
    _Rule(patterns: ['විභාග','exam','ඉගෙනීම'], responses: [
      "ඔව්... විභාග ගැන ආතතිය ඇත්තෙන්ම දුෂ්කරයි. 😔 ඔබ ගොඩක් වෙහෙස වෙනවා. ඔබ ගැන ටිකක් කියන්නකෝ.",
      "ඒ ඇත්තෙන්ම අමාරු. 💙 ඔබ ගැන ටිකක් කතා කරමු.",
    ]),
    _Rule(patterns: ['fail','අසාර්ථක','නොහැකි'], responses: [
      "ඒ ඇසීමට හිත දුකයි... 💙 ඔබ ඒ ගැන ගොඩක් කලකිරිලා ඉන්නවා. ඔබ ගැන ටිකක් කියන්නකෝ.",
      "ඔව්... ඒ හැඟීම ඇත්තෙන්ම දුෂ්කරයි. 🌿 ඔබ ගැන ටිකක් කතා කරමු.",
    ]),
    _Rule(patterns: ['කවුරුවත්','තේරුම්','තේරෙන්නේ'], responses: [
      "ඒ ඇසීමට හිත දුකයි... 💙 ඔබව නොතේරෙන්නේ කවුද?",
      "ඔව්... ඒ හැඟීම ඇත්තෙන්ම වේදනාකාරීයි. 🌿 ඔබ ගැන ටිකක් කියන්නකෝ.",
    ]),
    _Rule(patterns: ['ජීවිතය','ජීවිත','ජීවිතේ','අමාරුයි'], responses: [
      "ඔව්... ජීවිතය සමහර වෙලාවට ගොඩක් බරක් දැනෙනවා. 💙 ඔබ ගැන ටිකක් කියන්නකෝ.",
      "ඒ ඇසීමට හිත දුකයි... ඔබ ගොඩක් දේ දරාගෙන ඉන්නවා. 🌿 ඔබ ගැන ටිකක් කතා කරමු.",
    ]),
    _Rule(patterns: ['සතුටු','සතුට','හොඳයි'], responses: [
      "ඒ ඇසීමට ලොකු සතුටකි! 🌟 ඔබ ගැන ටිකක් කියන්නකෝ.",
      "ඔව්, ඒ හොඳයි! 💚 ඔබ ගැන ටිකක් කතා කරමු.",
    ]),
    _Rule(patterns: ['ස්තූතියි','ස්තූති'], responses: [
      "ඔබට ස්වාගතයි! 🌿",
      "ඒ ඇසීමට සතුටයි. 💚",
    ]),
  ];

  static const _enRules = [
    _Rule(patterns: ['hello','hi','hey','morning','afternoon','evening'], responses: [
      "Hey! 😊 **How are you doing?**",
      "Hi there! 🌿 *What's on your mind?*",
    ]),
    _Rule(patterns: ['anxious','anxiety','nervous','panic','worried','fear','scared'], responses: [
      "That sounds really tough... 💙 **Tell me more** about what's making you feel this way.",
      "I hear you. Anxiety can feel overwhelming. 🌿 *What's been going on?*",
    ]),
    _Rule(patterns: ['stress','stressed','overwhelmed','pressure','burnout'], responses: [
      "That sounds really hard... 😔 You're carrying a lot. **What's weighing on you most?**",
      "I'm sorry you're feeling this way. 💙 *Tell me more about what's happening.*",
    ]),
    _Rule(patterns: ['sad','sadness','depressed','depression','unhappy','down','cry','tears'], responses: [
      "I'm sorry you're feeling this way... 💙 **Tell me more** about what's been going on.",
      "That sounds really tough. 🌿 *What's been weighing on your heart?*",
    ]),
    _Rule(patterns: ['sleep','insomnia','tired','exhausted','fatigue'], responses: [
      "That sounds really hard... 😔 Not being able to sleep is tough. **Tell me more about it.**",
      "I'm sorry you're struggling with sleep. 💙 *How long has this been going on?*",
    ]),
    _Rule(patterns: ['lonely','alone','isolated'], responses: [
      "That sounds really painful... 💙 **Loneliness is so hard.** Tell me more.",
      "I'm sorry you're feeling this way. 🌿 *You're not alone — I'm here.*",
    ]),
    _Rule(patterns: ['happy','happiness','joy','great','wonderful','good'], responses: [
      "That's **wonderful** to hear! 🌟 **Tell me more!**",
      "I'm so glad! 💚 *What's been making you feel good?*",
    ]),
    _Rule(patterns: ['thank','thanks'], responses: [
      "You're welcome! 🌿",
      "Anytime! 💚",
    ]),
  ];

  static const _enFallback = [
    "I hear you... 💙 **Tell me more** about what's going on.",
    "That sounds really hard. 🌿 *What's been happening?*",
    "I'm here. 💚 *What's on your mind?*",
    "Thanks for sharing that with me. 🌱 **How long have you been feeling this way?**",
  ];

  static const _siFallback = [
    "ඔව්... ඒ ඇසීමට හිත දුකයි. 💙 **ඔබ ගැන ටිකක් කියන්නකෝ.**",
    "ඒ ඇත්තෙන්ම අමාරු. 🌿 *ඔබ ගැන ටිකක් කතා කරමු.*",
    "ඔබ ඒ ගැන කතා කරන්නට ආවා — ඒ ලොකු දෙයක්. 💚 **ඔබ ගැන ටිකක් කියන්නකෝ.**",
    "ඒ ඇසීමට කනගාටුයි... **ඔබ ගැන ටිකක් කතා කරමු.** 💙",
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
