/// Client-side feature recommendation used as a safe fallback when the AI
/// server does not return recommendations.
///
/// Rules are deliberately conservative about the user's current state:
///   * crisis            -> professional help only
///   * deep sadness/grief -> NO meditation, NO games (too much focus/energy)
///   * anxiety           -> quick grounding, calm music (short activities)
///   * exhaustion         -> NO games, NO meditation (the gentlest options only)
///
/// [recommend] returns feature ids (see [WellnessFeature.all]) matching the
/// user's feeling, in priority order, max [maxFeatures].
class WellnessRecommender {
  static const int maxFeatures = 3;

  /// Signal tables (shared with the mood detector / other chat features).
  static const Map<String, List<String>> enSignals = _enSignals;
  static const Map<String, List<String>> siSignals = _siSignals;

  static const List<String> _priority = [
    'crisis',
    'anxiety',
    'stress',
    'heavySad',
    'sad',
    'angry',
    'lonely',
    'exhausted',
    'guilty',
    'exam',
    'positive',
  ];

  static const Map<String, List<String>> _features = {
    'crisis': ['counsellorCall', 'findDoctor'],
    'anxiety': ['breathing', 'calmMusic', 'journal', 'resources'],
    'stress': ['breathing', 'calmMusic', 'journal', 'moodTracker'],
    'heavySad': ['journal', 'calmMusic', 'counsellorCall', 'painting'],
    'sad': ['journal', 'calmMusic', 'motivational'],
    'angry': ['games', 'painting', 'breathing'],
    'lonely': ['counsellorCall', 'findDoctor', 'calmMusic', 'journal'],
    'exhausted': ['calmMusic', 'breathing'],
    'guilty': ['journal', 'counsellorCall', 'motivational', 'painting'],
    'exam': ['breathing', 'calmMusic', 'motivational'],
    'positive': <String>[],
  };

  static const Map<String, List<String>> _enSignals = {
    'crisis': [
      'suicide', 'kill myself', 'end my life', 'end it all',
      'no reason to live', "don't want to live", 'dont want to live',
      'want to die', 'hurt myself', 'cut myself', 'self harm', 'self-harm',
    ],
    'anxiety': [
      'anxious', 'anxiety', 'panic', 'worried', 'worry', 'scared', 'afraid',
      'fear', 'nervous', 'on edge', "can't calm", 'cant calm', 'uneasy',
    ],
    'stress': [
      'stress', 'stressed', 'overwhelmed', 'pressure', 'too much',
      'burnout', 'overloaded',
    ],
    'heavySad': [
      'heartbroken', 'heart broken', 'depressed', 'depression', 'grief',
      'grieving', 'lost someone', 'breakup', 'over him', 'over her',
      'miss him', 'miss her', 'bereavement', 'hopeless',
    ],
    'sad': [
      'sad', 'sadness', 'unhappy', 'down', 'blue', 'cry', 'crying', 'tears',
      'miserable', 'hurt',
    ],
    'angry': [
      'angry', 'anger', 'mad', 'frustrated', 'annoyed', 'hate', 'furious',
      'rage', 'resent',
    ],
    'lonely': [
      'lonely', 'alone', 'isolated', 'no friends', 'everyone left',
      'by myself', 'on my own',
    ],
    'exhausted': [
      'exhausted', 'exhaustion', 'tired', 'fatigue', 'no energy', 'worn out',
      "can't get up", 'cant get up', 'sleepy',
    ],
    'guilty': [
      'guilty', 'guilt', 'my fault', 'blame myself', 'blame me', 'shame',
      'ashamed', 'regret',
    ],
    'exam': [
      'exam', 'exams', 'final', 'finals', 'study', 'studies', 'test',
      'grades',
    ],
    'positive': [
      'happy', 'great', 'wonderful', 'excited', 'grateful', 'thank',
      'good news',
    ],
  };

  static const Map<String, List<String>> _siSignals = {
    'crisis': [
      'සියදිවි', 'මැරෙන්න', 'මැරිලා', 'ජීවත් වෙන්න ඕන නෑ',
      'ජීවත් වෙන්න බෑ', 'කපාගන්න', 'තුවාල කරගන්න', 'මගෙන් කමක් නෑ',
    ],
    'anxiety': [
      'කනස්සල්ල', 'කනස්සලු', 'බය', 'බිය', 'කලබල', 'ටෙන්ෂන්',
      'නර්වස්', 'සන්සුන් වෙන්න බෑ', 'අපහසු',
    ],
    'stress': [
      'ආතතිය', 'පීඩනය', 'බරක්', 'වැඩ ගොඩක්', 'බොහෝ වැඩ', 'වෙහෙසෙනවා',
    ],
    'heavySad': [
      'බ්‍රෑක්අප්', 'හිත බිඳුණා', 'අහිමි වුණා', 'මතකයි', 'මියගිය',
      'බලාපොරොත්තු බිඳුණා',
    ],
    'sad': [
      'දුක', 'දුකයි', 'කඳුළු', 'අඬනවා', 'අඬන්න', 'හිත රිදෙනවා', 'අමාරුයි',
    ],
    'angry': [
      'තරහ', 'කෝප', 'කේන්ති', 'අමනාප', 'හිරිහැර', 'පිළිකුල්',
    ],
    'lonely': [
      'තනිකම', 'තනියම', 'හුදෙකලා', 'යාළුවෝ නෑ', 'කවුරුත් නෑ',
    ],
    'exhausted': [
      'වෙහෙස', 'හෙම්බත්', 'මහන්සි', 'බොහෝ මහන්සි', 'ජීව ශක්තිය නෑ',
      'නිදිමත',
    ],
    'guilty': [
      'වරදකාරී', 'මගේ වරද', 'දොස්', 'දොස් කියනවා', 'ලැජ්ජා', 'පසුතැවිල්ල',
    ],
    'exam': [
      'විභාග', 'පරීක්ෂණ', 'ඉගෙනීම', 'පාඩම්', 'රිසල්ට්',
    ],
    'positive': [
      'සතුටු', 'සතුට', 'හොඳයි', 'ස්තූතියි', 'සුභ පුවත්',
    ],
  };

  static List<String> recommend(String text, {required bool isSinhala}) {
    final lower = text.toLowerCase();
    final signals = isSinhala ? _siSignals : _enSignals;
    final out = <String>[];

    for (final key in _priority) {
      final words = signals[key] ?? const <String>[];
      final matched = words.isNotEmpty &&
          words.any((word) => lower.contains(word));
      if (!matched) continue;
      if (key == 'positive') return const [];
      for (final id in _features[key] ?? const <String>[]) {
        if (out.length >= maxFeatures) return out;
        if (!out.contains(id)) out.add(id);
      }
    }
    return out;
  }
}