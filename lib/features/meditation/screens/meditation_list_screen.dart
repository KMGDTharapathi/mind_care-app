import 'package:flutter/material.dart';
import 'meditation_session_screen.dart';

// ─────────────────────────────────────────────────────────────────────────────
//  DATA MODEL
// ─────────────────────────────────────────────────────────────────────────────
class MeditationStep {
  final String title;
  final String instruction;
  final String? siTitle;
  final String? siInstruction;
  final int durationSeconds;
  final String emoji;
  final Color color;

  const MeditationStep({
    required this.title,
    required this.instruction,
    this.siTitle,
    this.siInstruction,
    required this.durationSeconds,
    required this.emoji,
    required this.color,
  });

  String localTitle(bool si) => (si && siTitle != null) ? siTitle! : title;
  String localInstruction(bool si) => (si && siInstruction != null) ? siInstruction! : instruction;
}

class MeditationData {
  final String id;
  final String name;
  final String pali;
  final String description;
  final String? siDescription;
  final String emoji;
  final List<Color> gradient;
  final String duration;
  final String level;
  final List<MeditationStep> steps;
  final List<String> techniques;
  final List<String> goals;
  final List<String>? siTechniques;
  final List<String>? siGoals;

  const MeditationData({
    required this.id,
    required this.name,
    required this.pali,
    required this.description,
    this.siDescription,
    required this.emoji,
    required this.gradient,
    required this.duration,
    required this.level,
    required this.steps,
    required this.techniques,
    required this.goals,
    this.siTechniques,
    this.siGoals,
  });

  List<String> localTechniques(bool si) => (si && siTechniques != null) ? siTechniques! : techniques;
  List<String> localGoals(bool si) => (si && siGoals != null) ? siGoals! : goals;
  String localDescription(bool si) => (si && siDescription != null) ? siDescription! : description;
}

// ─────────────────────────────────────────────────────────────────────────────
//  MEDITATION LIBRARY
// ─────────────────────────────────────────────────────────────────────────────
final List<MeditationData> kMeditations = [
  // 1. Anapanasati
  MeditationData(
    id: 'anapanasati',
    name: 'Anapanasati',
    pali: 'ආනාපානසති',
    description: 'Mindfulness of breathing — the Buddha\'s core meditation. Follow each breath in and out to calm the mind.',
    siDescription: 'හුස්ම ගැනීමේ සිහිය — බුදුරජාණන් වහන්සේගේ මූලික භාවනාව. සිත සන්සුන් කිරීමට හුස්ම ගැනීම නිරීක්ෂණය කරන්න.',
    emoji: '🌬️',
    gradient: [const Color(0xFF4FC3F7), const Color(0xFF0288D1), const Color(0xFF01579B)],
    duration: '10 min',
    level: 'Beginner',
    techniques: [
      '🎯 Single-point focus — anchor attention at one spot (nostrils, chest, or belly)',
      '🔢 Breath counting — count out-breaths 1–10 to stabilise the wandering mind',
      '🔄 Return practice — each time the mind wanders, gently bring it back without judgment',
      '⏸️ Gap awareness — notice the natural pause between in-breath and out-breath',
      '📍 Bare attention — observe the breath exactly as it is, without controlling it',
    ],
    siTechniques: [
      '🎯 එකම ස්ථානයකට අවධානය — නාසය, පපුව හෝ බඩ යන එකක් තෝරා රැඳෙන්න',
      '🔢 හුස්ම ගණනය — 1 සිට 10 දක්වා හෙළන හුස්ම ගණනය කර සිත ස්ථාවර කරන්න',
      '🔄 ආපසු ගෙනෙන ක්‍රමය — සිත ඈත් වූ විට, විනිශ්චයකින් තොරව නැවත හුස්ම වෙත ගෙන එන්න',
      '⏸️ හිස් අවකාශය දැකීම — හෙළන හුස්ම සහ ගන්නා හුස්ම අතර ස්වාභාවික විරාමය දකින්න',
      '📍 සිදු වන දේ දැකීම — හුස්ම ගැනීම පාලනය නොකර, ඇති ආකාරයෙන්ම නිරීක්ෂණය කරන්න',
    ],
    goals: [
      '✅ Calm and stabilise the mind (samatha)',
      '✅ Develop sustained concentration (samadhi)',
      '✅ Reduce anxiety and mental chatter',
      '✅ Build the foundation for all deeper meditation',
      '✅ Experience moments of pure stillness and peace',
    ],
    siGoals: [
      '✅ සිත සන්සුන් කිරීම (සමථ)',
      '✅ ස්ථිර සමාධිය (සමාධි) වර්ධනය කිරීම',
      '✅ කනස්සල්ල සහ සිතේ කලබලය අඩු කිරීම',
      '✅ ගැඹුරු භාවනාවන් සඳහා පදනම ගොඩ නැගීම',
      '✅ පිරිසිදු නිශ්ශබ්දතාවය සහ සාමය අත්විඳීම',
    ],
    steps: [
      MeditationStep(title: 'Find Your Seat', siTitle: 'ආසනය සොයා ගන්න',
        instruction: 'Sit comfortably with your back straight. Rest your hands on your knees. Close your eyes gently. 🪷',
        siInstruction: 'පිටුපස කෙළින් තබා සුවපහසුව ඉඳගන්න. දෙඅත් දෙදණ මත තබන්න. ඇස් සෙමෙන් වසා ගන්න. 🪷',
        durationSeconds: 30, emoji: '🧘', color: const Color(0xFF4FC3F7)),
      MeditationStep(title: 'Arrive Here', siTitle: 'මෙහි පැමිණෙන්න',
        instruction: 'Take three deep breaths. Let your body settle. Feel the weight of your body on the seat. You are safe here. ✨',
        siInstruction: 'ගැඹුරු හුස්ම තුනක් ගන්න. ශරීරය ස්ථාවර වීමට ඉඩ දෙන්න. ආසනය මත ශරීරයේ බර දැනෙන්නට ඉඩ දෙන්න. ඔබ මෙහි ආරක්ෂිතයි. ✨',
        durationSeconds: 30, emoji: '🌟', color: const Color(0xFF81D4FA)),
      MeditationStep(title: 'Find the Breath', siTitle: 'හුස්ම සොයා ගන්න',
        instruction: 'Notice where you feel the breath most clearly — at the nostrils, the chest, or the belly. Choose one spot and stay there. 👃',
        siInstruction: 'හුස්ම වඩාත් පැහැදිලිව දැනෙන ස්ථානය — නාසය, පපුව හෝ බඩ — දකින්න. එක් ස්ථානයක් තෝරා එහිම රැඳෙන්න. 👃',
        durationSeconds: 30, emoji: '🌬️', color: const Color(0xFF29B6F6)),
      MeditationStep(title: 'Breathe In', siTitle: 'හුස්ම ගන්න',
        instruction: 'Breathe in slowly and naturally. Feel the cool air entering. Notice the rise of your chest or belly. Don\'t force it — just observe. 🌊',
        siInstruction: 'සෙමෙන් ස්වාභාවිකව හුස්ම ගන්න. ඇතුළු වන සිසිල් වාතය දැනෙන්නට ඉඩ දෙන්න. පපුව හෝ බඩ ඉහළ යාම දකින්න. 🌊',
        durationSeconds: 60, emoji: '⬆️', color: const Color(0xFF0288D1)),
      MeditationStep(title: 'Breathe Out', siTitle: 'හුස්ම හෙළන්න',
        instruction: 'Breathe out gently. Feel the warm air leaving. Notice the fall of your chest or belly. Let go of any tension. 🍃',
        siInstruction: 'සෙමෙන් හුස්ම හෙළන්න. නිකුත් වන උණුසුම් වාතය දැනෙන්නට ඉඩ දෙන්න. පපුව හෝ බඩ පහළ යාම දකින්න. ආතතිය අත් හරින්න. 🍃',
        durationSeconds: 60, emoji: '⬇️', color: const Color(0xFF0277BD)),
      MeditationStep(title: 'Count the Breaths', siTitle: 'හුස්ම ගණනය කරන්න',
        instruction: 'Count each out-breath: 1... 2... 3... up to 10, then start again. If you lose count, smile and start at 1. 🔢',
        siInstruction: 'හෙළන හුස්ම ගණනය කරන්න: 1... 2... 3... 10 දක්වා, ඉන්පසු නැවත ආරම්භ කරන්න. ගණන් නැති වූවොත්, සිනාසී 1 සිට ආරම්භ කරන්න. 🔢',
        durationSeconds: 120, emoji: '🔢', color: const Color(0xFF01579B)),
      MeditationStep(title: 'Notice Wandering', siTitle: 'සිත ඈත් වීම දකින්න',
        instruction: 'When your mind wanders — and it will! — gently notice it. Say "thinking" softly in your mind, then return to the breath. 🦋',
        siInstruction: 'සිත ඈත් වූ විට — එය සිදු වේ! — සෙමෙන් දකින්න. "සිතීම" යැයි සිතේ කියා, නැවත හුස්ම වෙත ආපසු යන්න. 🦋',
        durationSeconds: 60, emoji: '🦋', color: const Color(0xFF039BE5)),
      MeditationStep(title: 'Just Breathing', siTitle: 'හුස්ම ගැනීම පමණයි',
        instruction: 'Now let go of counting. Simply be with each breath as it comes and goes. In... out... in... out... 🌸',
        siInstruction: 'දැන් ගණනය කිරීම අත් හරින්න. එන සහ යන හුස්ම සමඟ සිටින්න. ඇතුළට... පිටට... ඇතුළට... පිටට... 🌸',
        durationSeconds: 120, emoji: '🌸', color: const Color(0xFF0288D1)),
      MeditationStep(title: 'Rest in Stillness', siTitle: 'නිශ්ශබ්දතාවයේ විවේකය',
        instruction: 'Rest in the stillness between breaths. Notice the pause after the out-breath. A moment of pure peace. 🌙',
        siInstruction: 'හුස්ම අතර නිශ්ශබ්දතාවයේ විවේකය ගන්න. හෙළන හුස්ම පසු විරාමය දකින්න. පිරිසිදු සාමයේ මොහොතක්. 🌙',
        durationSeconds: 60, emoji: '🌙', color: const Color(0xFF01579B)),
      MeditationStep(title: 'Gently Return', siTitle: 'සෙමෙන් ආපසු',
        instruction: 'Slowly bring awareness back to the room. Wiggle your fingers and toes. Open your eyes softly. Carry this peace with you. 🙏',
        siInstruction: 'සෙමෙන් දැනුවත්භාවය කාමරය වෙත ගෙන එන්න. ඇඟිලි සොලවන්න. ඇස් සෙමෙන් විවෘත කරන්න. මෙම සාමය ඔබ සමඟ රැගෙන යන්න. 🙏',
        durationSeconds: 30, emoji: '🙏', color: const Color(0xFF4FC3F7)),
    ],
  ),

  // 2. Metta Bhavana
  MeditationData(
    id: 'metta',
    name: 'Metta Bhavana',
    pali: 'මෙත්තා භාවනා',
    description: 'Loving-kindness meditation — cultivate boundless love for yourself and all beings.',
    siDescription: 'මෙත්තා භාවනාව — ඔබ සඳහා සහ සියලු සත්ත්වයන් සඳහා අසීමිත ආදරය වර්ධනය කරන්න.',
    emoji: '💗',
    gradient: [const Color(0xFFF48FB1), const Color(0xFFE91E63), const Color(0xFF880E4F)],
    duration: '12 min',
    level: 'Beginner',
    siTechniques: [
      '💬 මෙත්තා වාක්‍ය — "මා සතුටු වේවා. මා නිරෝගී වේවා. මා ආරක්ෂිත වේවා. මා සාමයෙන් සිටිවා."',
      '🔵 පුළුල් කිරීම — ඔබ → ආදරය කරන කෙනා → මධ්‍යස්ථ කෙනා → අපහසු කෙනා → සියලු සත්ත්වයන්',
      '🖼️ දෘශ්‍යකරණය — එක් එක් කෙනාගේ සිනාසෙන මුහුණ සිතේ ඇඳ ගන්න',
      '💛 හදවත් කේන්ද්‍රය — පපුවෙන් පිටතට විහිදෙන උණුසුම දැනෙන්නට ඉඩ දෙන්න',
      '🌊 විකිරණ ක්‍රමය — ආදරය සියලු දිශාවලට ආලෝකය ලෙස විහිදෙන බව සිතන්න',
    ],
    siGoals: [
      '✅ ස්වයං-ද්වේෂය දිය කර ස්වයං-කරුණාව වර්ධනය කිරීම',
      '✅ ක්‍රෝධය සුව කිරීම සහ ඔබට හිංසා කළ අය සමාව දීම',
      '✅ මෙත්තාව (metta) මානසික ගුණයක් ලෙස වර්ධනය කිරීම',
      '✅ ක්‍රෝධය, භය සහ සමාජ කනස්සල්ල අඩු කිරීම',
      '✅ සීමාවකින් තොර හිතවත්කමේ (Brahmavihara) ප්‍රීතිය අත්විඳීම',
    ],
    techniques: [
      '💬 Metta phrases — silently repeat "May I/you be happy, healthy, safe, at peace"',
      '🔵 Expanding circles — start with self → loved one → neutral → difficult → all beings',
      '🖼️ Visualisation — picture each person\'s face glowing with warmth and happiness',
      '💛 Heart-centre focus — feel warmth radiating from the chest outward',
      '🌊 Radiation practice — imagine love spreading like light in all directions',
    ],
    goals: [
      '✅ Dissolve self-hatred and cultivate self-compassion',
      '✅ Heal resentment and forgive those who have hurt you',
      '✅ Develop unconditional love (metta) as a mental quality',
      '✅ Reduce anger, fear, and social anxiety',
      '✅ Experience the joy of boundless goodwill (one of the Four Brahmaviharas)',
    ],
    steps: [
      MeditationStep(title: 'Open Your Heart', siTitle: 'හදවත විවෘත කරන්න',
        instruction: 'Sit comfortably. Place one hand on your heart. Feel its gentle beat — the rhythm of life within you. 💓',
        siInstruction: 'සුවපහසුව ඉඳගන්න. එක් අතක් හදවත මත තබන්න. එහි සෙමෙන් ගැහෙන ස්පන්දනය දැනෙන්නට ඉඩ දෙන්න. 💓',
        durationSeconds: 30, emoji: '💓', color: const Color(0xFFF48FB1)),
      MeditationStep(title: 'Love for Yourself', siTitle: 'ඔබ සඳහා ආදරය',
        instruction: 'Picture yourself as a small child, innocent and pure. Send yourself love:\n"May I be happy.\nMay I be healthy.\nMay I be safe.\nMay I be at peace." 🌟',
        siInstruction: 'ඔබව නිර්දෝෂ, පිරිසිදු කුඩා දරුවෙකු ලෙස සිතන්න. ඔබටම ආදරය යවන්න:\n"මා සතුටු වේවා.\nමා නිරෝගී වේවා.\nමා ආරක්ෂිත වේවා.\nමා සාමයෙන් සිටිවා." 🌟',
        durationSeconds: 90, emoji: '🌟', color: const Color(0xFFEC407A)),
      MeditationStep(title: 'A Loved One', siTitle: 'ආදරය කරන කෙනෙකු',
        instruction: 'Think of someone you love deeply — a parent, friend, or pet. See their smiling face. Send them love:\n"May you be happy.\nMay you be healthy.\nMay you be safe.\nMay you be at peace." 💝',
        siInstruction: 'ඔබ ගැඹුරින් ආදරය කරන කෙනෙකු — දෙමාපියෙකු, මිතුරෙකු — ගැන සිතන්න. ඔවුන්ගේ සිනාසෙන මුහුණ දකින්න. ආදරය යවන්න:\n"ඔබ සතුටු වේවා.\nඔබ නිරෝගී වේවා.\nඔබ ආරක්ෂිත වේවා.\nඔබ සාමයෙන් සිටිවා." 💝',
        durationSeconds: 90, emoji: '💝', color: const Color(0xFFE91E63)),
      MeditationStep(title: 'A Neutral Person', siTitle: 'මධ්‍යස්ථ කෙනෙකු',
        instruction: 'Think of someone you neither like nor dislike — a neighbour or shopkeeper. Send them the same love:\n"May you be happy.\nMay you be healthy.\nMay you be safe.\nMay you be at peace." 🤝',
        siInstruction: 'ඔබ ආදරය හෝ ද්වේෂ නොකරන කෙනෙකු — අසල්වැසියෙකු — ගැන සිතන්න. ඔවුන්ටද ආදරය යවන්න:\n"ඔබ සතුටු වේවා.\nඔබ නිරෝගී වේවා.\nඔබ ආරක්ෂිත වේවා.\nඔබ සාමයෙන් සිටිවා." 🤝',
        durationSeconds: 90, emoji: '🤝', color: const Color(0xFFD81B60)),
      MeditationStep(title: 'A Difficult Person', siTitle: 'අපහසු කෙනෙකු',
        instruction: 'Think of someone who has hurt you. This is hard — but try. Send them love too:\n"May you be happy.\nMay you be healthy.\nMay you be safe.\nMay you be at peace." 🕊️',
        siInstruction: 'ඔබට හිංසා කළ කෙනෙකු ගැන සිතන්න. මෙය අපහසුයි — නමුත් උත්සාහ කරන්න. ඔවුන්ටද ආදරය යවන්න:\n"ඔබ සතුටු වේවා.\nඔබ නිරෝගී වේවා.\nඔබ ආරක්ෂිත වේවා.\nඔබ සාමයෙන් සිටිවා." 🕊️',
        durationSeconds: 90, emoji: '🕊️', color: const Color(0xFFC2185B)),
      MeditationStep(title: 'All Beings', siTitle: 'සියලු සත්ත්වයන්',
        instruction: 'Now expand your love like a golden light spreading in all directions — to all people, all animals, all beings everywhere:\n"May all beings be happy.\nMay all beings be at peace." 🌍',
        siInstruction: 'දැන් ඔබේ ආදරය රන් ආලෝකයක් ලෙස සියලු දිශාවලට විහිදෙන්නට ඉඩ දෙන්න:\n"සියලු සත්ත්වයෝ සතුටු වෙත්වා.\nසියලු සත්ත්වයෝ සාමයෙන් සිටිත්වා." 🌍',
        durationSeconds: 120, emoji: '🌍', color: const Color(0xFF880E4F)),
      MeditationStep(title: 'Rest in Love', siTitle: 'ආදරයේ විවේකය',
        instruction: 'Sit in this warm glow of loving-kindness. Feel your heart open and soft. You are connected to all life. 🌸',
        siInstruction: 'මෙත්තාවේ උණුසුම් දීප්තිය තුළ ඉඳගන්න. ඔබේ හදවත විවෘත සහ මෘදු බව දැනෙන්නට ඉඩ දෙන්න. ඔබ සියලු ජීවිතයට සම්බන්ධ වී ඇත. 🌸',
        durationSeconds: 60, emoji: '🌸', color: const Color(0xFFAD1457)),
      MeditationStep(title: 'Closing', siTitle: 'නිමාව',
        instruction: 'Gently return. Take a deep breath. Smile. Carry this loving heart into your day. 🙏',
        siInstruction: 'සෙමෙන් ආපසු යන්න. ගැඹුරු හුස්මක් ගන්න. සිනාසෙන්න. මෙම ආදරය ඔබේ දවසට රැගෙන යන්න. 🙏',
        durationSeconds: 30, emoji: '🙏', color: const Color(0xFFF48FB1)),
    ],
  ),

  // 3. Vipassana
  MeditationData(
    id: 'vipassana',
    name: 'Vipassana',
    pali: 'විපස්සනා',
    description: 'Insight meditation — see the true nature of mind and body through clear, direct observation.',
    siDescription: 'විදර්ශනා භාවනාව — පැහැදිලි, සෘජු නිරීක්ෂණය මගින් මනස සහ ශරීරයේ සත්‍ය ස්වභාවය දකින්න.',
    emoji: '👁️',
    gradient: [const Color(0xFFCE93D8), const Color(0xFF7B1FA2), const Color(0xFF4A148C)],
    duration: '15 min',
    level: 'Intermediate',
    techniques: [
      '🔍 Systematic body scan — move attention methodically from head to feet',
      '🏷️ Mental noting — silently label sensations: "tingling," "pressure," "warmth"',
      '⚡ Impermanence observation — watch how every sensation arises and passes away',
      '🪞 Three Characteristics — observe Anicca (impermanence), Dukkha (unsatisfactoriness), Anatta (non-self)',
      '🌌 Open awareness — rest in choiceless awareness, observing whatever arises',
    ],
    siTechniques: [
      '🔍 ක්‍රමානුකූල ශරීර ස්කෑන් — හිසෙන් පාද දක්වා අවධානය ක්‍රමානුකූලව ගෙන යන්න',
      '🏷️ මානසික සටහන් — "කැකෑරීම," "පීඩනය," "උෂ්ණය" ලෙස සංවේදනා නිශ්ශබ්දව ලේබල් කරන්න',
      '⚡ අනිත්‍ය නිරීක්ෂණය — සෑම සංවේදනාවක්ම ඇති වී නැති වන ආකාරය නිරීක්ෂණය කරන්න',
      '🪞 ත්‍රිලක්ෂණ — අනිත්‍ය, දුක්ඛ, අනාත්ම නිරීක්ෂණය කරන්න',
      '🌌 විවෘත දැනුවත්භාවය — ඇති වන ඕනෑම දෙයක් නිරීක්ෂණය කරමින් විකල්ප රහිත දැනුවත්භාවයේ රැඳෙන්න',
    ],
    goals: [
      '✅ Directly experience the impermanent nature of all phenomena',
      '✅ Weaken attachment and aversion through clear seeing',
      '✅ Develop insight (vipassana) into the true nature of self',
      '✅ Progress toward liberation from suffering (nibbana)',
      '✅ Cultivate equanimity — unshakeable peace amid changing experience',
    ],
    siGoals: [
      '✅ සියලු සංසිද්ධිවල අනිත්‍ය ස්වභාවය සෘජුව අත්විඳීම',
      '✅ පැහැදිලිව දැකීම මගින් ඇල්ම සහ ගැටීම දුර්වල කිරීම',
      '✅ ආත්මයේ සත්‍ය ස්වභාවය පිළිබඳ ප්‍රඥාව (විපස්සනා) වර්ධනය කිරීම',
      '✅ දුකෙන් මිදීම (නිර්වාණ) කරා ප්‍රගතිය',
      '✅ වෙනස් වන අත්දැකීම් මධ්‍යයේ නොසෙල්වෙන සාමය — උපේක්ෂාව වර්ධනය කිරීම',
    ],
    steps: [
      MeditationStep(title: 'Settle the Mind', siTitle: 'සිත ස්ථාවර කරන්න',
        instruction: 'Sit still. Take five slow breaths to calm the mind. Let thoughts settle like dust in still water. 🌊',
        siInstruction: 'නිශ්චලව ඉඳගන්න. සිත සන්සුන් කිරීමට සෙමෙන් හුස්ම පහක් ගන්න. සිතුවිලි නිශ්චල ජලයේ දූවිලි ලෙස ස්ථාවර වීමට ඉඩ දෙන්න. 🌊',
        durationSeconds: 60, emoji: '🌊', color: const Color(0xFFCE93D8)),
      MeditationStep(title: 'Body Scan — Head', siTitle: 'ශරීර ස්කෑන් — හිස',
        instruction: 'Bring attention to the top of your head. Notice any sensations — tingling, warmth, pressure, or nothing at all. Just observe without judging. 🧠',
        siInstruction: 'ඔබේ හිසෙහි ඉහළට අවධානය ගෙන යන්න. ඕනෑම සංවේදනාවක් — කැකෑරීම, උෂ්ණය, පීඩනය — දකින්න. විනිශ්චයකින් තොරව නිරීක්ෂණය කරන්න. 🧠',
        durationSeconds: 60, emoji: '🧠', color: const Color(0xFFBA68C8)),
      MeditationStep(title: 'Body Scan — Face & Neck', siTitle: 'ශරීර ස්කෑන් — මුහුණ සහ බෙල්ල',
        instruction: 'Move attention slowly down to your face and neck. Notice every sensation — tightness, relaxation, temperature. See how sensations arise and pass. 😌',
        siInstruction: 'අවධානය සෙමෙන් මුහුණ සහ බෙල්ල දෙසට ගෙන යන්න. සෑම සංවේදනාවක්ම — ආතතිය, ලිහිල් බව, උෂ්ණත්වය — දකින්න. 😌',
        durationSeconds: 60, emoji: '😌', color: const Color(0xFFAB47BC)),
      MeditationStep(title: 'Body Scan — Chest', siTitle: 'ශරීර ස්කෑන් — පපුව',
        instruction: 'Feel your chest rising and falling. Notice the heartbeat. Observe any emotions stored here — without holding on or pushing away. 💜',
        siInstruction: 'පපුව ඉහළ යාම සහ පහළ යාම දැනෙන්නට ඉඩ දෙන්න. හදවතේ ස්පන්දනය දකින්න. මෙහි ගබඩා ඕනෑම හැඟීමක් — රඳවා නොගෙන, ඈත් නොකර — නිරීක්ෂණය කරන්න. 💜',
        durationSeconds: 60, emoji: '💜', color: const Color(0xFF9C27B0)),
      MeditationStep(title: 'Body Scan — Belly & Back', siTitle: 'ශරීර ස්කෑන් — බඩ සහ පිට',
        instruction: 'Scan your belly and back. Notice tension, ease, warmth. Everything is impermanent — sensations arise and pass like clouds. ☁️',
        siInstruction: 'බඩ සහ පිට ස්කෑන් කරන්න. ආතතිය, ලිහිල් බව, උෂ්ණය දකින්න. සෑම දෙයක්ම අනිත්‍ය — සංවේදනා වලාකුළු ලෙස ඇති වී ගෙවී යයි. ☁️',
        durationSeconds: 60, emoji: '☁️', color: const Color(0xFF8E24AA)),
      MeditationStep(title: 'Body Scan — Arms & Hands', siTitle: 'ශරීර ස්කෑන් — අත් සහ ඇඟිලි',
        instruction: 'Feel your arms and hands. Notice the pulse in your fingertips. Observe without reacting — this is the practice of equanimity. 🤲',
        siInstruction: 'අත් සහ ඇඟිලි දැනෙන්නට ඉඩ දෙන්න. ඇඟිලිකරවල ස්පන්දනය දකින්න. ප්‍රතික්‍රියා නොකර නිරීක්ෂණය කරන්න — මෙය උපේක්ෂාවේ ක්‍රමවේදයයි. 🤲',
        durationSeconds: 60, emoji: '🤲', color: const Color(0xFF7B1FA2)),
      MeditationStep(title: 'Body Scan — Legs & Feet', siTitle: 'ශරීර ස්කෑන් — කකුල් සහ පාද',
        instruction: 'Scan down through your legs to your feet. Feel the contact with the floor. Notice the boundary between self and world. 🦶',
        siInstruction: 'කකුල් හරහා පාද දක්වා ස්කෑන් කරන්න. බිම සමඟ ස්පර්ශය දැනෙන්නට ඉඩ දෙන්න. ආත්මය සහ ලෝකය අතර සීමාව දකින්න. 🦶',
        durationSeconds: 60, emoji: '🦶', color: const Color(0xFF6A1B9A)),
      MeditationStep(title: 'Three Characteristics', siTitle: 'ත්‍රිලක්ෂණ',
        instruction: 'Now observe the whole body at once. Notice:\n• Impermanence (Anicca) — everything changes\n• Unsatisfactoriness (Dukkha) — clinging causes suffering\n• Non-self (Anatta) — who is observing? 🔮',
        siInstruction: 'දැන් සම්පූර්ණ ශරීරය එකවර නිරීක්ෂණය කරන්න. දකින්න:\n• අනිත්‍ය (Anicca) — සෑම දෙයක්ම වෙනස් වේ\n• දුක්ඛ (Dukkha) — ඇල්ම දුකට හේතු වේ\n• අනාත්ම (Anatta) — නිරීක්ෂණය කරන්නේ කවුද? 🔮',
        durationSeconds: 120, emoji: '🔮', color: const Color(0xFF4A148C)),
      MeditationStep(title: 'Open Awareness', siTitle: 'විවෘත දැනුවත්භාවය',
        instruction: 'Let go of the body scan. Rest in open awareness — like a clear sky. Thoughts, sounds, sensations arise and pass. You are the sky, not the clouds. 🌌',
        siInstruction: 'ශරීර ස්කෑන් අත් හරින්න. විවෘත දැනුවත්භාවයේ රැඳෙන්න — පැහැදිලි ආකාශයක් ලෙස. සිතුවිලි, ශබ්ද, සංවේදනා ඇති වී ගෙවී යයි. ඔබ ආකාශය, වලාකුළු නොවේ. 🌌',
        durationSeconds: 120, emoji: '🌌', color: const Color(0xFF6A1B9A)),
      MeditationStep(title: 'Insight Moment', siTitle: 'ප්‍රඥා මොහොත',
        instruction: 'In this stillness, notice: the observer and the observed are one. There is just awareness, aware of itself. This is the beginning of insight. ✨',
        siInstruction: 'මෙම නිශ්ශබ්දතාවයේ, දකින්න: නිරීක්ෂකයා සහ නිරීක්ෂිතය එකක්. දැනුවත්භාවය පමණයි, ඒ ගැනම දැනුවත්. මෙය ප්‍රඥාවේ ආරම්භයයි. ✨',
        durationSeconds: 60, emoji: '✨', color: const Color(0xFF7B1FA2)),
      MeditationStep(title: 'Return Gently', siTitle: 'සෙමෙන් ආපසු',
        instruction: 'Slowly return. Wiggle fingers and toes. Open your eyes. Bow to yourself for this practice. 🙏',
        siInstruction: 'සෙමෙන් ආපසු යන්න. ඇඟිලි සොලවන්න. ඇස් විවෘත කරන්න. මෙම භාවනාව සඳහා ඔබටම නමස්කාර කරන්න. 🙏',
        durationSeconds: 30, emoji: '🙏', color: const Color(0xFFCE93D8)),
    ],
  ),

  // 4. Karuna Bhavana
  MeditationData(
    id: 'karuna',
    name: 'Karuna Bhavana',
    pali: 'කරුණා භාවනා',
    description: 'Compassion meditation — open your heart to the suffering of all beings and wish them freedom from pain.',
    siDescription: 'කරුණා භාවනාව — සියලු සත්ත්වයන්ගේ දුකට ඔබේ හදවත විවෘත කර ඔවුන්ට දුකෙන් නිදහස ප්‍රාර්ථනා කරන්න.',
    emoji: '🤲',
    gradient: [const Color(0xFFFFCC80), const Color(0xFFFF9800), const Color(0xFFE65100)],
    duration: '10 min',
    level: 'Beginner',
    siTechniques: [
      '💬 කරුණා වාක්‍ය — "ඔබ දුකෙන් නිදහස් වේවා. ඔබ සාමය සොයා ගනිවා."',
      '🔵 පුළුල් කිරීම — ඔබ → දුකෙන් සිටින ආදරය කරන කෙනා → නොදන්නා අය → සියලු සත්ත්වයන්',
      '🖼️ දුක් දෘශ්‍යකරණය — යටපත් නොවී, කෙනෙකුගේ දුක සෙමෙන් සිතේ ඇඳ ගන්න',
      '🛡️ කරුණාව vs. සංවේදනය — ඔවුන්ගේ දුක ඔබ ගෙන නොගෙන, ඔවුන්ට නිදහස ප්‍රාර්ථනා කරන්න',
      '🌊 හදවත මෘදු කිරීම — පපුවේ ඇති ඕනෑම ආතතියකට හෝ ප්‍රතිරෝධයකට හුස්ම ගන්න',
    ],
    siGoals: [
      '✅ සැබෑ කරුණාව (කරුණා) — දෙවන බ්‍රහ්මවිහාරය — වර්ධනය කිරීම',
      '✅ අන් අයගේ දුක ගැන උදාසීනත්වය සහ ක්‍රෝධය ජය ගැනීම',
      '✅ විශ්වීය දුකට සම්බන්ධ වීමෙන් ඔබේ ම දුක සුව කිරීම',
      '✅ පෞද්ගලික ආතතිය අඩු කිරීම සහ චිත්තවේගීය ශක්‍යතාව ගොඩ නැගීම',
      '✅ ලෝකයේ දුක සහ ආතතිය සහන කිරීමට ප්‍රේරණාව වර්ධනය කිරීම',
    ],
    techniques: [
      '💬 Karuna phrases — "May you be free from suffering. May you find peace."',
      '🔵 Expanding circles — self → loved one in pain → strangers → all beings',
      '🖼️ Suffering visualisation — gently picture someone\'s pain without being overwhelmed',
      '🛡️ Compassion vs. empathy — wish freedom from pain without absorbing it yourself',
      '🌊 Softening the heart — breathe into any tightness or resistance in the chest',
    ],
    goals: [
      '✅ Develop genuine compassion (karuna) — the second Brahmavihara',
      '✅ Overcome indifference and cruelty toward others\' suffering',
      '✅ Heal your own pain by connecting with universal suffering',
      '✅ Reduce personal distress and build emotional resilience',
      '✅ Cultivate the motivation to help and relieve suffering in the world',
    ],
    steps: [
      MeditationStep(title: 'Ground Yourself', siTitle: 'ඔබව ස්ථාවර කරන්න',
        instruction: 'Sit comfortably. Feel the earth beneath you — solid and supportive. Take three deep breaths. 🌍',
        siInstruction: 'සුවපහසුව ඉඳගන්න. ඔබ යට පොළොව — ශක්තිමත් සහ ආධාරක — දැනෙන්නට ඉඩ දෙන්න. ගැඹුරු හුස්ම තුනක් ගන්න. 🌍',
        durationSeconds: 30, emoji: '🌍', color: const Color(0xFFFFCC80)),
      MeditationStep(title: 'Your Own Suffering', siTitle: 'ඔබේ ම දුක',
        instruction: 'Acknowledge your own pain and struggles. Say gently:\n"I am suffering. This is hard. May I be free from this suffering." 💛',
        siInstruction: 'ඔබේ ම දුක සහ අරගල පිළිගන්න. සෙමෙන් කියන්න:\n"මම දුකෙන් සිටිමි. මෙය අපහසුයි. මා දුකෙන් නිදහස් වේවා." 💛',
        durationSeconds: 60, emoji: '💛', color: const Color(0xFFFFB74D)),
      MeditationStep(title: 'A Suffering Loved One', siTitle: 'දුකෙන් සිටින ආදරය කරන කෙනෙකු',
        instruction: 'Think of someone you love who is struggling. Feel their pain in your heart. Say:\n"You are suffering. May you be free from this suffering." 🧡',
        siInstruction: 'ඔබ ආදරය කරන, දුකෙන් සිටින කෙනෙකු ගැන සිතන්න. ඔවුන්ගේ දුක හදවතේ දැනෙන්නට ඉඩ දෙන්න. කියන්න:\n"ඔබ දුකෙන් සිටී. ඔබ දුකෙන් නිදහස් වේවා." 🧡',
        durationSeconds: 90, emoji: '🧡', color: const Color(0xFFFF9800)),
      MeditationStep(title: 'Strangers in Pain', siTitle: 'දුකෙන් සිටින නොදන්නා අය',
        instruction: 'Think of people you don\'t know who are suffering — the sick, the lonely, the afraid. Open your heart to them:\n"May you be free from suffering." 🌏',
        siInstruction: 'ඔබ නොදන්නා, දුකෙන් සිටින අය — රෝගීන්, තනිකරුවන් — ගැන සිතන්න. ඔවුන්ට හදවත විවෘත කරන්න:\n"ඔබ දුකෙන් නිදහස් වේවා." 🌏',
        durationSeconds: 90, emoji: '🌏', color: const Color(0xFFF57C00)),
      MeditationStep(title: 'All Beings', siTitle: 'සියලු සත්ත්වයන්',
        instruction: 'Expand compassion to all beings everywhere — every creature that suffers:\n"May all beings be free from suffering.\nMay all beings find peace." 🌈',
        siInstruction: 'සියලු සත්ත්වයන් දෙසට කරුණාව පුළුල් කරන්න:\n"සියලු සත්ත්වයෝ දුකෙන් නිදහස් වෙත්වා.\nසියලු සත්ත්වයෝ සාමය සොයා ගනිත්වා." 🌈',
        durationSeconds: 120, emoji: '🌈', color: const Color(0xFFE65100)),
      MeditationStep(title: 'Rest in Compassion', siTitle: 'කරුණාවේ විවේකය',
        instruction: 'Sit in this warm, open-hearted space. Compassion doesn\'t mean taking on others\' pain — it means wishing them free from it. 🕊️',
        siInstruction: 'මෙම උණුසුම්, විවෘත හදවතේ ඉඳගන්න. කරුණාව යනු අන් අයගේ දුක ගැනීම නොවේ — ඔවුන්ට නිදහස ප්‍රාර්ථනා කිරීමයි. 🕊️',
        durationSeconds: 60, emoji: '🕊️', color: const Color(0xFFBF360C)),
      MeditationStep(title: 'Closing', siTitle: 'නිමාව',
        instruction: 'Take a deep breath. Place your hand on your heart. Carry this compassion into the world. 🙏',
        siInstruction: 'ගැඹුරු හුස්මක් ගන්න. අත හදවත මත තබන්න. මෙම කරුණාව ලෝකයට රැගෙන යන්න. 🙏',
        durationSeconds: 30, emoji: '🙏', color: const Color(0xFFFFCC80)),
    ],
  ),

  // 5. Mudita Bhavana
  MeditationData(
    id: 'mudita',
    name: 'Mudita Bhavana',
    pali: 'මුදිතා භාවනා',
    description: 'Sympathetic joy — rejoice in the happiness and success of others without envy.',
    siDescription: 'මුදිතා භාවනාව — ඊර්ෂ්‍යාවකින් තොරව අන් අයගේ සතුට සහ සාර්ථකත්වය ගැන ප්‍රීති වන්න.',
    emoji: '🌻',
    gradient: [const Color(0xFFFFF176), const Color(0xFFFDD835), const Color(0xFFF57F17)],
    duration: '8 min',
    level: 'Beginner',
    siTechniques: [
      '💬 මුදිතා වාක්‍ය — "ඔබේ සතුට දිගටම පවතිවා! ඔබේ ප්‍රීතිය වර්ධනය වේවා!"',
      '🎉 ප්‍රීතිය විශාල කිරීම — සැබෑ සතුටේ මොහොතක් සිහිපත් කර එය පුළුල් වීමට ඉඩ දෙන්න',
      '🔵 පුළුල් කිරීම — ආදරය කරන කෙනා → මධ්‍යස්ථ කෙනා → අපහසු කෙනා → සියලු සත්ත්වයන්',
      '🪞 ඊර්ෂ්‍යාවට ප්‍රතිකාරය — ඊර්ෂ්‍යාව ඇති වූ විට, ඒ වෙනුවට ප්‍රීති වීමට සිතාමතාම තෝරා ගන්න',
      '☀️ හිරු ආලෝකය දෘශ්‍යකරණය — ප්‍රීතිය අනෙකා පිරවෙන උණුසුම් රන් ආලෝකයක් ලෙස සිතන්න',
    ],
    siGoals: [
      '✅ මුදිතාව — තෙවන බ්‍රහ්මවිහාරය — වර්ධනය කිරීම',
      '✅ අන් අයගේ සාර්ථකත්වය ගැන ඊර්ෂ්‍යාව, ද්වේෂය සහ ක්‍රෝධය මුලිනුපුටා දැමීම',
      '✅ ඔබේ ම තත්ත්වය මත රඳා නොපවතින සැබෑ සතුටක් අත්විඳීම',
      '✅ ධනාත්මක සම්බන්ධතා සහ සමාජ සම්බන්ධය ශක්තිමත් කිරීම',
      '✅ ස්වාභාවිකව ප්‍රීතිමත්, කෘතඥ සිතක් වර්ධනය කිරීම',
    ],
    techniques: [
      '💬 Mudita phrases — "May your happiness continue! May your joy grow!"',
      '🎉 Joy amplification — recall a genuine moment of happiness and let it expand',
      '🔵 Expanding circles — loved one → neutral person → difficult person → all beings',
      '🪞 Envy antidote — when jealousy arises, consciously choose to rejoice instead',
      '☀️ Sunshine visualisation — picture joy as warm golden light filling the other person',
    ],
    goals: [
      '✅ Develop sympathetic joy (mudita) — the third Brahmavihara',
      '✅ Uproot jealousy, envy, and resentment at others\' success',
      '✅ Experience genuine happiness that doesn\'t depend on your own circumstances',
      '✅ Strengthen positive relationships and social connection',
      '✅ Cultivate a naturally joyful, appreciative mind',
    ],
    steps: [
      MeditationStep(title: 'Begin with Joy', siTitle: 'ප්‍රීතියෙන් ආරම්භ කරන්න',
        instruction: 'Think of something that makes you genuinely happy — a memory, a person, a place. Let that joy fill your chest like sunshine. ☀️',
        siInstruction: 'ඔබව සැබවින්ම සතුටු කරන දෙයක් — මතකයක්, කෙනෙකු, ස්ථානයක් — ගැන සිතන්න. ඒ ප්‍රීතිය හිරු ආලෝකය ලෙස පපුව පිරෙන්නට ඉඩ දෙන්න. ☀️',
        durationSeconds: 45, emoji: '☀️', color: const Color(0xFFFFF176)),
      MeditationStep(title: 'Joy for a Loved One', siTitle: 'ආදරය කරන කෙනෙකු සඳහා ප්‍රීතිය',
        instruction: 'Think of someone who is happy and successful. Instead of comparing, rejoice with them:\n"I am happy that you are happy!\nMay your joy continue and grow!" 🎉',
        siInstruction: 'සතුටු සහ සාර්ථක කෙනෙකු ගැන සිතන්න. සංසන්දනය කිරීම වෙනුවට, ඔවුන් සමඟ ප්‍රීති වන්න:\n"ඔබ සතුටු නිසා මාත් සතුටුයි!\nඔබේ ප්‍රීතිය දිගටම පවතිවා!" 🎉',
        durationSeconds: 90, emoji: '🎉', color: const Color(0xFFFDD835)),
      MeditationStep(title: 'Joy for a Neutral Person', siTitle: 'මධ්‍යස්ථ කෙනෙකු සඳහා ප්‍රීතිය',
        instruction: 'Think of someone you barely know who seems content. Rejoice in their happiness:\n"May your happiness continue!\nMay your joy grow!" 🌟',
        siInstruction: 'ඔබ ඉතා ටිකක් දන්නා, සතුටු ලෙස පෙනෙන කෙනෙකු ගැන සිතන්න. ඔවුන්ගේ සතුටේ ප්‍රීති වන්න:\n"ඔබේ සතුට දිගටම පවතිවා!\nඔබේ ප්‍රීතිය වර්ධනය වේවා!" 🌟',
        durationSeconds: 90, emoji: '🌟', color: const Color(0xFFFBC02D)),
      MeditationStep(title: 'Joy for a Difficult Person', siTitle: 'අපහසු කෙනෙකු සඳහා ප්‍රීතිය',
        instruction: 'Think of someone you find difficult. Can you find joy in their happiness? This is the hardest practice — and the most freeing:\n"May your happiness continue." 🌸',
        siInstruction: 'ඔබ අපහසු ලෙස සලකන කෙනෙකු ගැන සිතන්න. ඔවුන්ගේ සතුටේ ප්‍රීතිය සොයා ගත හැකිද? මෙය අපහසුම ක්‍රමවේදය — සහ වඩාත්ම නිදහස් කරන:\n"ඔබේ සතුට දිගටම පවතිවා." 🌸',
        durationSeconds: 90, emoji: '🌸', color: const Color(0xFFF9A825)),
      MeditationStep(title: 'Universal Joy', siTitle: 'විශ්වීය ප්‍රීතිය',
        instruction: 'Expand joy to all beings:\n"May all beings be happy!\nMay all beings rejoice!\nMay joy fill the whole world!" 🌍',
        siInstruction: 'සියලු සත්ත්වයන් දෙසට ප්‍රීතිය පුළුල් කරන්න:\n"සියලු සත්ත්වයෝ සතුටු වෙත්වා!\nසියලු සත්ත්වයෝ ප්‍රීති වෙත්වා!\nප්‍රීතිය සමස්ත ලෝකය පිරෙත්වා!" 🌍',
        durationSeconds: 90, emoji: '🌍', color: const Color(0xFFF57F17)),
      MeditationStep(title: 'Rest in Joy', siTitle: 'ප්‍රීතියේ විවේකය',
        instruction: 'Sit in this bright, expansive feeling. Notice how rejoicing in others\' happiness actually increases your own. 🌻',
        siInstruction: 'මෙම දීප්තිමත්, පුළුල් හැඟීම තුළ ඉඳගන්න. අන් අයගේ සතුටේ ප්‍රීති වීම ඔබේ ම සතුට ඇත්ත වශයෙන්ම වැඩි කරන ආකාරය දකින්න. 🌻',
        durationSeconds: 60, emoji: '🌻', color: const Color(0xFFE65100)),
      MeditationStep(title: 'Closing', siTitle: 'නිමාව',
        instruction: 'Smile. Take a deep breath. Carry this joyful heart into your day. 🙏',
        siInstruction: 'සිනාසෙන්න. ගැඹුරු හුස්මක් ගන්න. මෙම ප්‍රීතිමත් හදවත ඔබේ දවසට රැගෙන යන්න. 🙏',
        durationSeconds: 30, emoji: '🙏', color: const Color(0xFFFFF176)),
    ],
  ),

  // 6. Upekkha Bhavana
  MeditationData(
    id: 'upekkha',
    name: 'Upekkha Bhavana',
    pali: 'උපේක්ෂා භාවනා',
    description: 'Equanimity meditation — cultivate a balanced, peaceful mind that is neither attached nor averse.',
    siDescription: 'උපේක්ෂා භාවනාව — ඇලීමකින් හෝ ගැටීමකින් තොරව සමබර, සාමකාමී සිතක් වර්ධනය කරන්න.',
    emoji: '⚖️',
    gradient: [const Color(0xFFA5D6A7), const Color(0xFF388E3C), const Color(0xFF1B5E20)],
    duration: '10 min',
    level: 'Intermediate',
    siTechniques: [
      '💬 උපේක්ෂා වාක්‍ය — "ඔබ ඔබේ ක්‍රියාවන්හි හිමිකරු. ඔබ සියලු තත්ත්වයන්හිදී සාමය සොයා ගනිවා."',
      '🏔️ කඳු ඉරියව — සියලු කාලගුණ තත්ත්වයන්හිදී කඳු මෙන් ස්ථිරව, නොසෙල්වෙන ලෙස ඉඳගන්න',
      '👂 විකල්ප රහිත ශ්‍රවණය — ශබ්ද හොඳ හෝ නරක ලෙස ලේබල් නොකර ඇසෙන්නට ඉඩ දෙන්න',
      '🌊 මධ්‍යම මාර්ගය — සිත සතුට හෝ දුක දෙසට නැඹුරු වූ විට, මධ්‍යයට ආපසු යන්න',
      '🌌 ආකාශ සිත — විවෘත ආකාශය ලෙස රැඳෙන්න; සිතුවිලි සහ හැඟීම් වලාකුළු ලෙස ගෙවී යාමට ඉඩ දෙන්න',
    ],
    siGoals: [
      '✅ උපේක්ෂාව — හතරවන සහ ශ්‍රේෂ්ඨතම බ්‍රහ්මවිහාරය — වර්ධනය කිරීම',
      '✅ අන් අයගේ සතුට හෝ දුක පාලනය කිරීමේ අවශ්‍යතාව අත් හැරීම',
      '✅ ජීවිතයේ නැගීම් සහ බැසීම් මධ්‍යයේ ස්ථාවරව, නොසෙල්වෙන ලෙස සිටීම',
      '✅ අධික ඇල්ම සහ ගැටීම ජය ගැනීම',
      '✅ දෛනික ජීවිතයේ බුදුරජාණන් වහන්සේගේ මධ්‍යම ප්‍රතිපදාව втілිත කිරීම',
    ],
    techniques: [
      '💬 Upekkha phrases — "You are the owner of your actions. May you find peace."',
      '🏔️ Mountain posture — sit immovably stable, like a mountain in all weather',
      '👂 Choiceless listening — hear sounds without labelling them good or bad',
      '🌊 Middle Way practice — notice when the mind leans toward pleasure or pain, return to centre',
      '🌌 Sky mind — rest as the open sky; let thoughts and feelings pass like clouds',
    ],
    goals: [
      '✅ Develop equanimity (upekkha) — the fourth and highest Brahmavihara',
      '✅ Release the need to control others\' happiness or suffering',
      '✅ Remain stable and undisturbed amid life\'s ups and downs',
      '✅ Overcome excessive attachment and aversion',
      '✅ Embody the Buddha\'s Middle Way in daily life',
    ],
    steps: [
      MeditationStep(title: 'Find Balance', siTitle: 'සමතුලිතතාව සොයා ගන්න',
        instruction: 'Sit like a mountain — stable, unmoving. Feel the balance in your posture. Neither leaning forward nor back. 🏔️',
        siInstruction: 'කඳු මෙන් ඉඳගන්න — ස්ථාවර, නොසෙල්වෙන. ඔබේ ඉරියව්වේ සමතුලිතතාව දැනෙන්නට ඉඩ දෙන්න. ඉදිරියටත් නොනැඹුරු, පිටුපසටත් නොනැඹුරු. 🏔️',
        durationSeconds: 45, emoji: '🏔️', color: const Color(0xFFA5D6A7)),
      MeditationStep(title: 'Observe Without Reacting', siTitle: 'ප්‍රතික්‍රියා නොකර නිරීක්ෂණය කරන්න',
        instruction: 'Notice sounds around you. Don\'t label them as good or bad — just hear them. This is equanimity: clear seeing without preference. 👂',
        siInstruction: 'ඔබ වටා ශබ්ද දකින්න. ඒවා හොඳ හෝ නරක ලෙස ලේබල් නොකරන්න — ඇසෙන්නට ඉඩ දෙන්න. මෙය උපේක්ෂාව: කැමැත්තකින් තොරව පැහැදිලිව දැකීම. 👂',
        durationSeconds: 60, emoji: '👂', color: const Color(0xFF81C784)),
      MeditationStep(title: 'Equanimity for Yourself', siTitle: 'ඔබ සඳහා උපේක්ෂාව',
        instruction: 'Say gently:\n"I am the owner of my actions.\nHappiness and suffering come from my own mind.\nMay I find peace in all circumstances." ⚖️',
        siInstruction: 'සෙමෙන් කියන්න:\n"මම මගේ ක්‍රියාවන්හි හිමිකරු.\nසතුට සහ දුක මගේ ම සිතෙන් ඇති වේ.\nමා සියලු තත්ත්වයන්හිදී සාමය සොයා ගනිවා." ⚖️',
        durationSeconds: 90, emoji: '⚖️', color: const Color(0xFF66BB6A)),
      MeditationStep(title: 'Equanimity for Others', siTitle: 'අන් අය සඳහා උපේක්ෂාව',
        instruction: 'Think of people you love. Say:\n"You are the owner of your actions.\nI cannot control your happiness.\nMay you find peace in all circumstances." 🌿',
        siInstruction: 'ඔබ ආදරය කරන අය ගැන සිතන්න. කියන්න:\n"ඔබ ඔබේ ක්‍රියාවන්හි හිමිකරු.\nඔබේ සතුට මට පාලනය කළ නොහැකිය.\nඔබ සියලු තත්ත්වයන්හිදී සාමය සොයා ගනිවා." 🌿',
        durationSeconds: 90, emoji: '🌿', color: const Color(0xFF4CAF50)),
      MeditationStep(title: 'The Middle Way', siTitle: 'මධ්‍යම ප්‍රතිපදාව',
        instruction: 'The Buddha taught the Middle Way — neither extreme pleasure nor extreme pain. Rest in the middle: calm, clear, undisturbed. 🌊',
        siInstruction: 'බුදුරජාණන් වහන්සේ මධ්‍යම ප්‍රතිපදාව ඉගැන්වූ සේක — අධික සතුටත් නොව, අධික දුකත් නොව. මධ්‍යයේ රැඳෙන්න: සන්සුන්, පැහැදිලි, නොසෙල්වෙන. 🌊',
        durationSeconds: 90, emoji: '🌊', color: const Color(0xFF388E3C)),
      MeditationStep(title: 'Universal Equanimity', siTitle: 'විශ්වීය උපේක්ෂාව',
        instruction: 'Extend equanimity to all beings:\n"May all beings find peace.\nMay all beings be free from suffering and clinging.\nMay all beings rest in equanimity." 🌍',
        siInstruction: 'සියලු සත්ත්වයන් දෙසට උපේක්ෂාව විහිදෙන්නට ඉඩ දෙන්න:\n"සියලු සත්ත්වයෝ සාමය සොයා ගනිත්වා.\nසියලු සත්ත්වයෝ දුකෙන් සහ ඇල්මෙන් නිදහස් වෙත්වා.\nසියලු සත්ත්වයෝ උපේක්ෂාවේ රැඳෙත්වා." 🌍',
        durationSeconds: 90, emoji: '🌍', color: const Color(0xFF2E7D32)),
      MeditationStep(title: 'Rest as the Sky', siTitle: 'ආකාශය ලෙස රැඳෙන්න',
        instruction: 'You are like the sky — vast, open, undisturbed. Clouds of thought and feeling pass through, but you remain clear and still. 🌌',
        siInstruction: 'ඔබ ආකාශය ලෙස — විශාල, විවෘත, නොසෙල්වෙන. සිතුවිලි සහ හැඟීම්වල වලාකුළු ගෙවී යයි, නමුත් ඔබ පැහැදිලිව සහ නිශ්චලව රැඳේ. 🌌',
        durationSeconds: 60, emoji: '🌌', color: const Color(0xFF1B5E20)),
      MeditationStep(title: 'Closing', siTitle: 'නිමාව',
        instruction: 'Gently return. Carry this balanced, peaceful mind into whatever comes next. 🙏',
        siInstruction: 'සෙමෙන් ආපසු යන්න. මෙම සමබර, සාමකාමී සිත ඉදිරියට ඇති ඕනෑම දෙයකට රැගෙන යන්න. 🙏',
        durationSeconds: 30, emoji: '🙏', color: const Color(0xFFA5D6A7)),
    ],
  ),

  // 7. Maranasati
  MeditationData(
    id: 'maranasati',
    name: 'Maranasati',
    pali: 'මරණසති',
    description: 'Mindfulness of death — contemplate impermanence to live more fully and let go of fear.',
    siDescription: 'මරණ සිහිය — භය අත් හැරීමට සහ වඩාත් සම්පූර්ණව ජීවත් වීමට අනිත්‍ය ගැන සිතා බලන්න.',
    emoji: '🌺',
    gradient: [const Color(0xFFEF9A9A), const Color(0xFFE53935), const Color(0xFF7F0000)],
    duration: '10 min',
    level: 'Advanced',
    siTechniques: [
      '⏳ මරණ සිතීම — "මම මිය යනු ඇත. මෙය නිශ්චිතයි. කාලය අනිශ්චිතයි." ලෙස සිතා බලන්න',
      '🌬️ වටිනා හුස්ම — එක් එක් හුස්ම ගැනීම තෑග්ගක් ලෙස සලකන්න; එය අවසාන එක විය හැකිය',
      '🍂 අනිත්‍ය ස්කෑන් — ශරීරය, සිතුවිලි සහ හැඟීම් නිරන්තරයෙන් වෙනස් වන ආකාරය නිරීක්ෂණය කරන්න',
      '🕊️ අත් හැරීමේ ක්‍රමය — ඔබ ඇලී සිටින එක් දෙයක් — කනස්සල්ලක්, ක්‍රෝධයක්, ආශාවක් — සිතාමතාම අත් හරින්න',
      '🌟 කෘතඥතාව වර්ධනය — ජීවත් වීමේ ආශ්චර්යය ගැන ගැඹුරු කෘතඥතාවක් දැනෙන්නට ඉඩ දෙන්න',
    ],
    siGoals: [
      '✅ සෘජු, සන්සුන් සිතීම මගින් මරණ භය ජය ගැනීම',
      '✅ සැබවින්ම වැදගත් දේ දැකීමෙන් සුළු කනස්සල්ල දිය කිරීම',
      '✅ වැඩි ප්‍රේරණාව, හදිසිය සහ කෘතඥතාවෙන් ජීවත් වීම',
      '✅ දේපළ, තත්ත්වය සහ සම්බන්ධතා ගැන ඇල්ම අත් හැරීම',
      '✅ සාමකාමී, දැනුවත් මරණයකට සිත සූදානම් කිරීම (පාලි කානනයේ ඉගැන්වූ ආකාරයට)',
    ],
    techniques: [
      '⏳ Death contemplation — reflect: "I will die. This is certain. The time is uncertain."',
      '🌬️ Precious breath — treat each breath as a gift; it may be the last',
      '🍂 Impermanence scan — observe how the body, thoughts, and feelings constantly change',
      '🕊️ Letting go practice — consciously release one attachment, worry, or grudge',
      '🌟 Gratitude cultivation — feel deep appreciation for the miracle of being alive',
    ],
    goals: [
      '✅ Overcome the fear of death through direct, calm contemplation',
      '✅ Dissolve trivial worries by seeing what truly matters',
      '✅ Live with greater presence, urgency, and appreciation',
      '✅ Release clinging to possessions, status, and relationships',
      '✅ Prepare the mind for a peaceful, conscious death (as taught in the Pali Canon)',
    ],
    steps: [
      MeditationStep(title: 'A Gentle Beginning', siTitle: 'සෙමෙන් ආරම්භය',
        instruction: 'This meditation is about life, not fear. Sit comfortably. Take three deep breaths. Open your heart to what is true. 🌸',
        siInstruction: 'මෙම භාවනාව ජීවිතය ගැනයි, භය ගැන නොවේ. සුවපහසුව ඉඳගන්න. ගැඹුරු හුස්ම තුනක් ගන්න. සත්‍ය දෙයට හදවත විවෘත කරන්න. 🌸',
        durationSeconds: 45, emoji: '🌸', color: const Color(0xFFEF9A9A)),
      MeditationStep(title: 'All Things Change', siTitle: 'සෑම දෙයක්ම වෙනස් වේ',
        instruction: 'Look at your hand. This hand was once tiny. It will one day be old. Everything changes — this is not sad, it is simply true. 🍂',
        siInstruction: 'ඔබේ අත දෙස බලන්න. මෙම අත කලෙක කුඩා විය. එය දිනෙක වෙහෙසකාර වනු ඇත. සෑම දෙයක්ම වෙනස් වේ — මෙය දුකක් නොවේ, සරලව සත්‍යයකි. 🍂',
        durationSeconds: 60, emoji: '🍂', color: const Color(0xFFE57373)),
      MeditationStep(title: 'This Breath May Be the Last', siTitle: 'මෙම හුස්ම අවසාන එක විය හැකිය',
        instruction: 'Breathe in. This breath is a gift. Breathe out. Notice: you don\'t know if the next breath will come. This awareness makes each breath precious. 🌬️',
        siInstruction: 'හුස්ම ගන්න. මෙම හුස්ම තෑග්ගකි. හුස්ම හෙළන්න. දකින්න: ඊළඟ හුස්ම ලැබෙනු ඇතිදැයි ඔබ නොදනී. මෙම දැනුවත්භාවය එක් එක් හුස්ම වටිනා කරයි. 🌬️',
        durationSeconds: 90, emoji: '🌬️', color: const Color(0xFFEF5350)),
      MeditationStep(title: 'What Truly Matters', siTitle: 'සැබවින්ම වැදගත් දේ',
        instruction: 'If today were your last day, what would matter? Not worries, not grudges — but love, kindness, presence. Let this truth guide you. 💝',
        siInstruction: 'අද ඔබේ අවසාන දිනය නම්, කුමක් වැදගත් වේද? කනස්සල්ල නොවේ, ක්‍රෝධය නොවේ — ආදරය, කරුණාව, ප්‍රේරණාව. මෙම සත්‍යය ඔබව මෙහෙයවීමට ඉඩ දෙන්න. 💝',
        durationSeconds: 90, emoji: '💝', color: const Color(0xFFE53935)),
      MeditationStep(title: 'Letting Go', siTitle: 'අත් හැරීම',
        instruction: 'Practice letting go of one thing you\'re clinging to — a worry, a resentment, a desire. Feel the lightness of release. 🕊️',
        siInstruction: 'ඔබ ඇලී සිටින එක් දෙයක් — කනස්සල්ලක්, ක්‍රෝධයක්, ආශාවක් — අත් හැරීම ක්‍රමවේදය ලෙස ක්‍රියාත්මක කරන්න. නිදහස් කිරීමේ සැහැල්ලු බව දැනෙන්නට ඉඩ දෙන්න. 🕊️',
        durationSeconds: 90, emoji: '🕊️', color: const Color(0xFFC62828)),
      MeditationStep(title: 'Gratitude for Life', siTitle: 'ජීවිතය ගැන කෘතඥතාව',
        instruction: 'Feel deep gratitude for this life — for breath, for sensation, for consciousness. Every moment is a miracle. 🌟',
        siInstruction: 'මෙම ජීවිතය ගැන — හුස්ම, සංවේදනා, දැනුවත්භාවය ගැන — ගැඹුරු කෘතඥතාවක් දැනෙන්නට ඉඩ දෙන්න. සෑම මොහොතක්ම ආශ්චර්යයකි. 🌟',
        durationSeconds: 60, emoji: '🌟', color: const Color(0xFFB71C1C)),
      MeditationStep(title: 'Live Fully Now', siTitle: 'දැන් සම්පූර්ණව ජීවත් වන්න',
        instruction: 'Return to this moment — fully alive, fully present. The awareness of impermanence is not a burden; it is freedom. 🌺',
        siInstruction: 'මෙම මොහොතට ආපසු යන්න — සම්පූර්ණයෙන් ජීවත්, සම්පූර්ණයෙන් ප්‍රේරිත. අනිත්‍ය ගැන දැනුවත්භාවය බරක් නොවේ; එය නිදහසකි. 🌺',
        durationSeconds: 60, emoji: '🌺', color: const Color(0xFF7F0000)),
      MeditationStep(title: 'Closing', siTitle: 'නිමාව',
        instruction: 'Take a deep breath of gratitude. Open your eyes. Go live fully. 🙏',
        siInstruction: 'කෘතඥතාවෙන් ගැඹුරු හුස්මක් ගන්න. ඇස් විවෘත කරන්න. සම්පූර්ණව ජීවත් වීමට යන්න. 🙏',
        durationSeconds: 30, emoji: '🙏', color: const Color(0xFFEF9A9A)),
    ],
  ),

  // 8. Buddho Mantra
  MeditationData(
    id: 'buddho',
    name: 'Buddho Mantra',
    pali: 'බුද්ධෝ',
    description: 'Recite "Buddho" — the name of the awakened one — in sync with the breath to still the mind.',
    siDescription: '"බුද්ධෝ" — අවදිවූ තැනැත්තාගේ නාමය — හුස්ම සමඟ සමමුහුර්ත කරමින් සිත සන්සුන් කිරීමට ජප කරන්න.',
    emoji: '🪷',
    gradient: [const Color(0xFF80DEEA), const Color(0xFF00ACC1), const Color(0xFF006064)],
    duration: '8 min',
    level: 'Beginner',
    siTechniques: [
      '🔤 මන්ත්‍ර සමමුහුර්ත කිරීම — ගන්නා හුස්මේ "බුද්—", හෙළන හුස්මේ "—ධෝ"',
      '🌊 හුස්ම-මන්ත්‍ර ඒකාබද්ධ කිරීම — වචනය සහ හුස්ම එකම අඛණ්ඩ ප්‍රවාහයක් බවට පත් වීමට ඉඩ දෙන්න',
      '🔄 ආපසු නැංගුරම — අවධානය ඈත් වූ විට, මන්ත්‍රය ආපසු යාමේ නැංගුරම වේ',
      '🔇 අභ්‍යන්තරකරණය — ප්‍රයෝජනවත් නම්声 ශබ්දෙන් ආරම්භ කරන්න, ඉන්පසු කෙසෙල් ශබ්දෙන්, ඉන්පසු සිතේ පමණක්',
      '🌙 ගැඹුරු නිශ්ශබ්දතාව — සමාධිය වර්ධනය වන විට, මන්ත්‍රය ඉතා සූක්ෂ්ම වීමට ඉඩ දෙන්න',
    ],
    siGoals: [
      '✅ විසිරුණු සිත ඉක්මනින් සන්සුන් කිරීම සහ ඒකාබද්ධ කිරීම',
      '✅ ශ්‍රද්ධාව (සද්ධා) සහ විශ්වාසය ක්‍රමවේදයේ ආධාරයක් ලෙස වර්ධනය කිරීම',
      '✅ ඒකාග්‍ර සමාධිය (එකග්ගතා) ළඟා කිරීම',
      '✅ එක් එක් හුස්ම ගැනීමේ අවදිවීමේ ගුණය සමඟ සම්බන්ධ වීම',
      '✅ ඕනෑම ස්ථානයක, ඕනෑම වේලාවක භාවිතා කළ හැකි සරල, ජංගම ක්‍රමවේදයක් ගොඩ නැගීම',
    ],
    techniques: [
      '🔤 Mantra synchronisation — "Bud—" on the in-breath, "—dho" on the out-breath',
      '🌊 Breath-mantra fusion — let the word and breath become one continuous flow',
      '🔄 Return anchor — when distracted, the mantra is the anchor to return to',
      '🔇 Internalisation — begin aloud if helpful, then whisper, then purely mental',
      '🌙 Deepening stillness — as concentration grows, let the mantra become very subtle',
    ],
    goals: [
      '✅ Rapidly calm and unify the scattered mind',
      '✅ Develop devotion (saddha) and faith as a support for practice',
      '✅ Achieve one-pointed concentration (ekaggata)',
      '✅ Connect with the quality of awakening in every breath',
      '✅ Build a simple, portable practice usable anywhere, anytime',
    ],
    steps: [
      MeditationStep(title: 'Sit in Reverence', instruction: 'Sit with a straight back. Bow your head slightly in respect. Feel a sense of peace and reverence fill the space. 🪷', durationSeconds: 30, emoji: '🪷', color: const Color(0xFF80DEEA)),
      MeditationStep(title: 'Learn the Mantra', instruction: '"Buddho" means "the Awakened One."\nOn the in-breath, silently say: "Bud—"\nOn the out-breath, silently say: "—dho"\nBud... dho... Bud... dho... 🌊', durationSeconds: 45, emoji: '🌊', color: const Color(0xFF4DD0E1)),
      MeditationStep(title: 'Breathe In — "Bud"', instruction: 'Breathe in slowly. In your mind, say "Bud—" Feel the word fill you like light. ⬆️', durationSeconds: 60, emoji: '⬆️', color: const Color(0xFF26C6DA)),
      MeditationStep(title: 'Breathe Out — "dho"', instruction: 'Breathe out slowly. In your mind, say "—dho." Feel peace flowing out with the breath. ⬇️', durationSeconds: 60, emoji: '⬇️', color: const Color(0xFF00BCD4)),
      MeditationStep(title: 'Continue the Mantra', instruction: 'Continue: Bud... dho... Bud... dho...\nLet the mantra become the breath and the breath become the mantra. They are one. 🌀', durationSeconds: 120, emoji: '🌀', color: const Color(0xFF00ACC1)),
      MeditationStep(title: 'When Mind Wanders', instruction: 'When thoughts arise, gently return to "Buddho." The mantra is your anchor. Each return is a moment of awakening. 🦋', durationSeconds: 90, emoji: '🦋', color: const Color(0xFF0097A7)),
      MeditationStep(title: 'Deepen the Stillness', instruction: 'As the mind settles, the mantra may become very quiet — almost a whisper in the mind. Rest in this deep stillness. 🌙', durationSeconds: 90, emoji: '🌙', color: const Color(0xFF00838F)),
      MeditationStep(title: 'Closing', instruction: 'Let the mantra fade. Sit in silence for a moment. Bow your head in gratitude. 🙏', durationSeconds: 30, emoji: '🙏', color: const Color(0xFF80DEEA)),
    ],
  ),
];

// ─────────────────────────────────────────────────────────────────────────────
//  LIST SCREEN
// ─────────────────────────────────────────────────────────────────────────────
class MeditationListScreen extends StatelessWidget {
  const MeditationListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0D1A1A) : const Color(0xFFF0F9F9),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 12, 16, 0),
              child: Row(
                children: [
                  IconButton(
                    icon: Icon(Icons.arrow_back_ios_new_rounded,
                        color: isDark ? Colors.white : const Color(0xFF1A4A4A)),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                  const Spacer(),
                  Text('Meditation',
                      style: TextStyle(
                          fontSize: 20, fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : const Color(0xFF1A4A4A))),
                  const Spacer(),
                  const SizedBox(width: 48),
                ],
              ),
            ),
            // Hero banner
            Container(
              margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF4DB6AC), Color(0xFF00796B)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(color: const Color(0xFF00796B).withOpacity(0.3),
                      blurRadius: 16, offset: const Offset(0, 6)),
                ],
              ),
              child: Row(
                children: [
                  const Text('🪷', style: TextStyle(fontSize: 48)),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Buddhist Meditations',
                            style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold,
                                color: Colors.white)),
                        const SizedBox(height: 4),
                        Text('${kMeditations.length} practices • Anapanasati & more',
                            style: TextStyle(fontSize: 12,
                                color: Colors.white.withOpacity(0.85))),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Text('Choose a Practice',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600,
                      color: isDark ? Colors.white54 : const Color(0xFF2A5A5A))),
            ),
            const SizedBox(height: 10),
            Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                itemCount: kMeditations.length,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (_, i) => _MeditationCard(
                  data: kMeditations[i],
                  isDark: isDark,
                  onTap: () => Navigator.push(context,
                      MaterialPageRoute(builder: (_) =>
                          MeditationSessionScreen(meditation: kMeditations[i]))),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MeditationCard extends StatelessWidget {
  final MeditationData data;
  final bool isDark;
  final VoidCallback onTap;

  const _MeditationCard({required this.data, required this.isDark, required this.onTap});

  Color get _levelColor {
    switch (data.level) {
      case 'Intermediate': return const Color(0xFFF9A825);
      case 'Advanced': return const Color(0xFFE53935);
      default: return const Color(0xFF43A047);
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: isDark ? Colors.white.withOpacity(0.06) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.06),
                blurRadius: 10, offset: const Offset(0, 3)),
          ],
        ),
        child: Row(
          children: [
            // Gradient left strip
            Container(
              width: 80, height: 90,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: data.gradient,
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(20),
                  bottomLeft: Radius.circular(20),
                ),
              ),
              child: Center(child: Text(data.emoji,
                  style: const TextStyle(fontSize: 36))),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(data.name,
                              style: TextStyle(fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                  color: isDark ? Colors.white : const Color(0xFF1A3333))),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: _levelColor.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(data.level,
                              style: TextStyle(fontSize: 9,
                                  color: _levelColor, fontWeight: FontWeight.bold)),
                        ),
                        const SizedBox(width: 10),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(data.pali,
                        style: TextStyle(fontSize: 11,
                            color: isDark ? Colors.white38 : Colors.black38,
                            fontStyle: FontStyle.italic)),
                    const SizedBox(height: 5),
                    Text(data.description,
                        maxLines: 2, overflow: TextOverflow.ellipsis,
                        style: TextStyle(fontSize: 11,
                            color: isDark ? Colors.white54 : const Color(0xFF4A6A6A),
                            height: 1.4)),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Icon(Icons.timer_outlined, size: 12,
                            color: isDark ? Colors.white38 : Colors.black38),
                        const SizedBox(width: 4),
                        Text(data.duration,
                            style: TextStyle(fontSize: 11,
                                color: isDark ? Colors.white38 : Colors.black38)),
                        const SizedBox(width: 12),
                        Icon(Icons.format_list_numbered_rounded, size: 12,
                            color: isDark ? Colors.white38 : Colors.black38),
                        const SizedBox(width: 4),
                        Text('${data.steps.length} steps',
                            style: TextStyle(fontSize: 11,
                                color: isDark ? Colors.white38 : Colors.black38)),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(right: 14),
              child: Icon(Icons.play_circle_rounded,
                  color: data.gradient[1], size: 32),
            ),
          ],
        ),
      ),
    );
  }
}
