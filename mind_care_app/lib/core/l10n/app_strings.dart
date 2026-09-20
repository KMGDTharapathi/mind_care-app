/// All app strings in English and Sinhala.
class AppStrings {
  final String languageCode;
  const AppStrings._(this.languageCode);

  static const AppStrings en = AppStrings._('en');
  static const AppStrings si = AppStrings._('si');

  bool get isSinhala => languageCode == 'si';
  String _s(String si, String en) => isSinhala ? si : en;

  // ── Home ──────────────────────────────────────────────────────────────────
  String get homeTitle => _s('ඔබ ගැන\nසැලකිලිමත් වන්න', 'Take care\nof yourself');
  String get chatWithWillow => _s('විලෝ සමග\nකතා කරන්න', 'Chat with\nWillow');
  String get counselorCall => _s('ඇමතුම් උපදේශක', 'Counselor\nCall');
  String get calmMusic => _s('සන්සුන් සංගීතය', 'Calm Music');
  String get stressGames => _s('මානසික පීඩනය\nදුරු කරන ක්‍රීඩා', 'Stress-Relief\nGames');
  String get guidedMeditation => _s('මග පෙන්වන භාවනාව', 'Guided\nMeditation');
  String get dailyReminders => _s('දෛනික මතක් කිරීම්', 'Daily\nReminders');
  String get motivationalBoost => _s('ප්‍රබෝධමත්\nදිරිගැන්වීම', 'Motivational\nBoost');
  String get tipsAdvice => _s('අදහස් සහ උපදෙස්', 'Tips &\nAdvice');
  String get offlineBanner => _s(
    'ඔබ නොබැඳිව සිටී — නැවත සම්බන්ධ වූ විට සමමුහුර්ත වේ.',
    "You're offline — changes will sync when reconnected.",
  );

  // ── Bottom Nav ────────────────────────────────────────────────────────────
  String get navHome => _s('මූල් පිටුව', 'Home');
  String get navProgress => _s('ප්‍රගතිය', 'Progress');
  String get navProfile => _s('ගිණුම', 'Profile');

  // ── Onboarding ────────────────────────────────────────────────────────────
  String get onboardingTagline => _s('ඔබේ මානසික සෞඛ්‍යයේ ආරක්ෂිත අවකාශය', 'Your safe space for mental wellness');
  String get onboardingHiThere => _s('හෙලෝ! 👋', 'Hi there! 👋');
  String get onboardingWhoAmI => _s('ඔබේ නම කුමක්ද?', 'Who am I chatting with?');
  String get onboardingNameHint => _s('ඔබේ නම ටයිප් කරන්න...', 'Type your name here...');
  String get onboardingNameError => _s('🌸 ඔබේ නම ඇතුළත් කරන්න!', '🌸 Psst… I need your name to say hello!');
  String get onboardingFindCalm => _s('සන්සුන් බව සොයා ගන්න', 'Find Your Calm');
  String get onboardingFindCalmDesc => _s(
    'ඔබව ලිහිල් කිරීමට සහ ඔබේ අභ්‍යන්තර සාමය යථා තත්ත්වයට පත් කිරීමට මග පෙන්වන හුස්ම ගැනීමේ අභ්‍යාස සහ භාවනා.',
    'Guided breathing exercises and meditations to help you relax and restore your inner peace.',
  );
  String get onboardingLetsStart => _s("අපි ආරම්භ කරමු", "Let's get started");
  String get onboardingGetStarted => _s('ආරම්භ කරන්න', 'Get Started');
  String get onboardingNext => _s('ඊළඟ', 'Next');
  String get onboardingContinue => _s('ඉදිරියට', 'Continue');

  // ── Onboarding — Welcome back ─────────────────────────────────────────────
  String get welcomeBackGreeting => _s('නැවත සාදරයෙන් පිළිගනිමු', 'Welcome back');
  String get welcomeBackSubtitle => _s('ඔබ නැවත ආවාට සතුටුයි!', 'Great to see you again!');

  // ── Settings ──────────────────────────────────────────────────────────────
  String get settingsTitle => _s('සැකසුම්', 'Settings');
  String get sectionAccount => _s('ගිණුම', 'Account');
  String get signedInAs => _s('ලෙස ලොග් වී ඇත', 'Signed in as');
  String get signOut => _s('ලොග් අවුට්', 'Sign Out');
  String get signIn => _s('ලොග් ඉන්', 'Sign In');
  String get signInSubtitle => _s('ඔබේ දත්ත උපාංග හරහා සමමුහුර්ත කරන්න', 'Sync your data across devices');
  String get sectionAppearance => _s('පෙනුම', 'Appearance');
  String get darkMode => _s('අඳුරු මාදිලිය', 'Dark Mode');
  String get darkModeSubtitle => _s('ආලෝකමත් සහ අඳුරු තේමාව අතර මාරු වන්න', 'Switch between light and dark theme');
  String get sectionNotifications => _s('දැනුම්දීම්', 'Notifications');
  String get dailyRemindersTitle => _s('දෛනික මතක් කිරීම්', 'Daily Reminders');
  String get dailyRemindersSubtitle => _s('මෘදු දෛනික පරීක්ෂා කිරීමේ මතක් කිරීමක් ලබා ගන්න', 'Receive a gentle daily check-in reminder');
  String get reminderTime => _s('මතක් කිරීමේ වේලාව', 'Reminder Time');
  String get enableNotifications => _s('දැනුම්දීම් සක්‍රිය කරන්න', 'Enable Notifications');
  String get notificationExplanation => _s(
    'MindCare ඔබේ මානසික සෞඛ්‍යය පිළිබඳ දෛනික මතක් කිරීමක් යැවීමට කැමතිය. ඔබට ඕනෑම වේලාවක සැකසුම් වලින් මෙය වෙනස් කළ හැකිය.',
    'MindCare would like to send you a gentle daily reminder to check in with your mental wellness. You can change this at any time in Settings.',
  );
  String get notNow => _s('දැන් නොවේ', 'Not Now');
  String get allow => _s('ඉඩ දෙන්න', 'Allow');
  String get openSettings => _s('සැකසුම් විවෘත කරන්න', 'Open Settings');
  String get notificationsDisabledTitle => _s('දැනුම්දීම් අහෝසි කිරීම්', 'Notifications Disabled');
  String get notificationsDisabledMessage => _s(
    'දැනුම්දීම් සදහා අවශ්‍ය අනුමැතිය නොලැබී ඇත. කරුණු කරන්න උපාංග සැකසුම් වලින් ඉඩ දෙන්න.',
    'Notification permission was not granted. Please enable it in your device settings.',
  );

  // ── Settings — Language section ───────────────────────────────────────────
  String get sectionLanguage => _s('භාෂාව', 'Language');
  String get languageEnglish => _s('ඉංග්‍රීසි', 'English');
  String get languageSinhala => _s('සිංහල', 'සිංහල');
  String get languageSaveError => _s('භාෂා මනාපය සුරැකීමට නොහැකි විය', 'Failed to save language preference');

  // ── Settings — Profile section ────────────────────────────────────────────
  String get sectionProfile => _s('පැතිකඩ', 'Profile');
  String get yourName => _s('ඔබේ නම', 'Your Name');
  String get nameNotSet => _s('සකසා නැත', 'Not set');
  String get changeName => _s('නම වෙනස් කරන්න', 'Change Name');
  String get enterYourName => _s('ඔබේ නම ඇතුළත් කරන්න', 'Enter your name');
  String get logAsNewUser => _s('නව පරිශීලකයෙකු ලෙස ලොග් වන්න', 'Log as New User');
  String get logAsNewUserSubtitle => _s('ඔබේ නම මකා නැවත ආරම්භ කරන්න', 'Clear your name and restart onboarding');
  String get logAsNewUserContent => _s('මෙය ඔබේ නම මකා ආයාචනා තිරයට ආපසු යයි. ඔබේ අනෙකුත් දත්ත රඳවා ගනී.', 'This will clear your name and take you back to the welcome screen. Your other data will be kept.');

  // ── Mood ──────────────────────────────────────────────────────────────────
  String get moodHistory => _s('මනෝභාවය ඉතිහාසය', 'Mood History');
  String get last7Days => _s('පසුගිය දින 7', 'Last 7 Days');
  String get moodOverPastWeek => _s('පසුගිය සතිය තුළ ඔබේ මනෝභාවය', 'Your mood over the past week');
  String get noMoodEntries => _s('තවම මනෝභාව ඇතුළත් කිරීම් නැත', 'No mood entries yet');
  String get startLoggingMood => _s(
    'ඔබේ ඉතිහාසය මෙහි බැලීමට ඔබේ මනෝභාවය ලොග් කිරීම ආරම්භ කරන්න.',
    'Start logging your mood to see your history here.',
  );
  String get moodEncouragementTitle => _s('නොගැඹුරුවෙන් ඉන්න — ඔබ විසින් වැඩි බලවත්', 'Don\'t give up — you are stronger than this');
  String get moodEncouragementBody => _s(
    'ඔබේ මනෝභාව අඳුරු වූ විටත්, ඔබේ අභ්‍යන්තර සාමය සහ බලවත්කම වැඩි ය. මෙම සතිය නිවැරදි කිරීමට සියලු පුරුදු කර ගන්න.',
    'Even when things feel dark, your inner strength shines brighter. Take this week one moment at a time.',
  );
  String get moodAppreciationTitle => _s('ඔබ හොඳින් කටයුතු කරනවා — ඉතිරියට පැමිණෙන්න', 'You\'re doing great — keep shining');
  String get moodAppreciationBody => _s(
    'ඔබේ සතුටු මනෝභාව අවශ්‍යතාව පෙන්වන අතර, ඔබ සියල්ලත් නිසිව කටයුතු කරනවා. මෙම සාමාධිරූප ස්ථාවර රඳවා ගන්න.',
    'Your positive moods show you\'re on the right path. Keep nurturing your wellbeing with the same care.',
  );
  String get recentEntries => _s('මෑත ඇතුළත් කිරීම්', 'Recent Entries');
  String get yesterdayLabel => _s('ඊයේ', 'Yesterday');
  String get moodHappy => _s('සතුටු', 'Happy');
  String get moodSad => _s('දුකින්', 'Sad');
  String get moodAnxious => _s('කනස්සල්ලෙන්', 'Anxious');
  String get moodFrustrated => _s('කලකිරීමෙන්', 'Frustrated');
  String get moodCalm => _s('සන්සුන්', 'Calm');
  String get moodExcited => _s('උද්යෝගිමත්', 'Excited');
  String get moodTired => _s('වෙහෙසට', 'Tired');

  // ── Journal ───────────────────────────────────────────────────────────────
  String get journal => _s('දිනපොත', 'Journal');
  String get newEntry => _s('නව ඇතුළත් කිරීම', 'New Entry');
  String get noJournalEntries => _s('තවම දිනපොත් ඇතුළත් කිරීම් නැත', 'No journal entries yet');

  // ── Breathing Patterns ───────────────────────────────────────────────────
  String get boxBreathingName => _s('කොටු හුස්ම ගැනීම', 'Box Breathing');
  String get boxBreathingDesc => _s('අවධානය සහ සන්සුන් බව සඳහා සමාන හුස්ම ගැනීම', 'Equal breathing for focus and calm');
  String get boxBreathingBenefit => _s('😌 ආතතිය සහනය', '😌 Stress Relief');
  String get breathing478Name => _s('4-7-8 හුස්ම ගැනීම', '4-7-8 Breathing');
  String get breathing478Desc => _s('කනස්සල්ල සහ නිදිමත සඳහා ලිහිල් කිරීමේ ක්‍රමය', 'Relaxation technique for anxiety and sleep');
  String get breathing478Benefit => _s('💤 වඩා හොඳ නිදිමත', '💤 Better Sleep');
  String get deepCalmName => _s('ගැඹුරු සන්සුන් බව', 'Deep Calm');
  String get deepCalmDesc => _s('ආතතිය සහනය සඳහා ගැඹුරු ඩයෆ්‍රෑම් හුස්ම ගැනීම', 'Deep diaphragmatic breathing for stress relief');
  String get deepCalmBenefit => _s('🧘 ගැඹුරු සන්සුන් බව', '🧘 Deep Calm');
  String get phaseInhale => _s('ගන්න', 'Inhale');
  String get phaseHold => _s('රඳවන්න', 'Hold');
  String get phaseExhale => _s('හෙළන්න', 'Exhale');


  String get mindBreath => _s('මනස සහ හුස්ම', 'Mind & Breath');
  String get meditationsTab => _s('භාවනා', 'Meditations');
  String get breathingTab => _s('හුස්ම ගැනීම', 'Breathing');
  String get buddhistMeditations => _s('බෞද්ධ භාවනා', 'Buddhist Meditations');
  String get buddhistMeditationsDesc => _s('භාවනා ${8} ක් • පියවරෙන් පියවර මග පෙන්වීම', '8 practices • Step-by-step guidance');
  String get choosePractice => _s('භාවනාවක් තෝරන්න', 'Choose a Practice');
  String get breathingExercises => _s('හුස්ම ගැනීමේ අභ්‍යාස', 'Breathing Exercises');
  String get breathingExercisesDesc => _s('ක්‍රම 3 ක් • සජීවී මග පෙන්වීම', '3 techniques • Animated guidance');
  String get chooseTechnique => _s('ක්‍රමයක් තෝරන්න', 'Choose a Technique');
  String get steps => _s('පියවර', 'steps');
  String get beginMeditation => _s('භාවනාව ආරම්භ කරන්න', 'Begin Meditation');
  String get techniques => _s('ක්‍රම', 'Techniques');
  String get howYouWillPractice => _s('ඔබ භාවිතා කරන ආකාරය', 'How you will practice');
  String get goals => _s('ඉලක්ක', 'Goals');
  String get whatYouWillAchieve => _s('ඔබ ළඟා කර ගන්නා දේ', 'What you will achieve');
  String get duration => _s('කාලය', 'Duration');
  String get level => _s('මට්ටම', 'Level');
  String get wellDone => _s('ශාබාශ්!', 'Well Done!');
  String get youCompleted => _s('ඔබ සම්පූර්ණ කළා', 'You completed');
  String get goalsAchieved => _s('🎯 ළඟා කළ ඉලක්ක', '🎯 Goals Achieved');
  String get backToMeditations => _s('භාවනා වෙත ආපසු', 'Back to Meditations');
  String get practiceAgain => _s('නැවත භාවිතා කරන්න', 'Practice Again');
  String get leaveMeditation => _s('භාවනාව හැර යන්නද?', 'Leave Meditation?');
  String get progressWillBeLost => _s('ඔබේ ප්‍රගතිය නැති වේ.', 'Your progress will be lost.');
  String get stay => _s('රැඳෙන්න', 'Stay');
  String get leave => _s('හැර යන්න', 'Leave');
  String get skipStep => _s('මෙම පියවර මඟ හරින්න →', 'Skip this step →');
  String get complete => _s('සම්පූර්ණයි ✓', 'Complete ✓');
  String get remaining => _s('ඉතිරිව ඇත', 'remaining');
  String get ready => _s('සූදානම්', 'ready');
  String get paused => _s('විරාම', 'paused');
  String get pause => _s('විරාමය', 'Pause');
  String get resume => _s('නැවත ආරම්භ කරන්න', 'Resume');
  String get endSession => _s('අවසන් කරන්න', 'End');
  String get endSessionTitle => _s('හුස්ම අභ්‍යාසය අවසන් කරන්නද?', 'End breathing session?');
  String get endSessionContent => _s('ඔබේ ප්‍රගතිය නැති වේ.', 'Your progress will be lost.');
  String get stepLabel => _s('පියවර', 'Step');
  String get beginner => _s('ආරම්භක', 'Beginner');
  String get intermediate => _s('මධ්‍යම', 'Intermediate');
  String get advanced => _s('උසස්', 'Advanced');

  // ── Calm Music ────────────────────────────────────────────────────────────
  String get calmMusicTitle => _s('සන්සුන් සංගීතය', 'Calm Music');
  String get libraryTab => _s('පුස්තකාලය', 'Library');
  String get nowPlayingTab => _s('දැන් වාදනය', 'Now Playing');
  String get myPlaylistTab => _s('මගේ ලැයිස්තුව', 'My Playlist');
  String get allTracks => _s('සියලු ගීත', 'All Tracks');
  String get myMusic => _s('මගේ සංගීතය', 'My Music');
  String get holdDragReorder => _s('රඳවා ඇදගෙන නැවත සකසන්න', 'Hold & drag to reorder');
  String get playlistEmpty => _s('ඔබේ ලැයිස්තුව හිස්ය', 'Your playlist is empty');
  String get tapAddMusic => _s('+ සංගීතය එකතු කරන්න ක්ලික් කරන්න', 'Tap + Add Music to get started');
  String get addMusic => _s('සංගීතය එකතු කරන්න', 'Add Music');
  String get queue => _s('පෝලිම', 'Queue');
  String get nowPlaying => _s('දැන් වාදනය', 'Now Playing');
  String get myPlaylist => _s('මගේ ලැයිස්තුව', 'My Playlist');
  String get addToMyPlaylist => _s('මගේ ලැයිස්තුවට එකතු කරන්න', 'Add to My Playlist');
  String get editTrack => _s('ගීතය සංස්කරණය කරන්න', 'Edit Track');
  String get musicSource => _s('සංගීත මූලාශ්‍රය', 'Music source');
  String get fromPhone => _s('දුරකථනයෙන්', 'From Phone');
  String get pasteUrl => _s('URL ඇලවීම', 'Paste URL');
  String get browseYourPhone => _s('ඔබේ දුරකථනය බ්‍රවුස් කරන්න', 'Browse your phone');
  String get pickAnIcon => _s('අයිකනයක් තෝරන්න', 'Pick an icon');
  String get pickAColor => _s('වර්ණයක් තෝරන්න', 'Pick a color');
  String get songTitle => _s('ගීතයේ නම *', 'Song Title *');
  String get artistName => _s('ශිල්පියාගේ නම (අත්‍යවශ්‍ය නොවේ)', 'Artist name (optional)');
  String get audioUrl => _s('ශ්‍රව්‍ය URL (mp3 / ogg / m4a)', 'Audio URL (mp3 / ogg / m4a)');
  String get addToPlaylist => _s('ලැයිස්තුවට එකතු කරන්න', 'Add to Playlist');
  String get saveChanges => _s('වෙනස්කම් සුරකින්න', 'Save Changes');
  String get removeTrack => _s('ගීතය ඉවත් කරන්න', 'Remove Track');
  String get couldNotPlay => _s('වාදනය කළ නොහැකිය', 'Could not play');
  String get titleRequired => _s('නම අවශ්‍යයි', 'Title is required');
  String get urlRequired => _s('URL අවශ්‍යයි', 'URL is required');
  String get selectAudioFile => _s('ශ්‍රව්‍ය ගොනුවක් තෝරන්න', 'Please select an audio file');
  String get tapToChangeFile => _s('ගොනුව වෙනස් කිරීමට ක්ලික් කරන්න', 'Tap to change file');
  String get pasteDirectLink => _s('ශ්‍රව්‍ය ගොනුවකට සෘජු සබැඳියක් ඇලවීම', 'Paste a direct link to an audio file');
  String get more => _s('තවත්', 'More');
  String get less => _s('අඩු', 'Less');

  // ── Games ─────────────────────────────────────────────────────────────────
  String get gameHub => _s('ක්‍රීඩා මධ්‍යස්ථානය', 'Game Hub');
  String get playToRelax => _s('ලිහිල් කිරීමට ක්‍රීඩා කරන්න. ඔබේ මනෝභාවය තෝරන්න 🧠', 'Play to relax. Pick your mood 🧠');
  String get gameBubbleTitle => _s('වර්ණ බුබුළු පිපිරවීම', 'Color Bubble Blaster');
  String get gameBubbleDesc => _s('එකම වර්ණයේ බුබුළු 3 ක් ගැලපීමෙන් පිපිරවීම. ඉලක්ක මග පෙන්වීම ඇතුළත්!', 'Shoot & match 3 same-color bubbles to blast them. Aim guide included!');
  String get gameBubbleMood => _s('😰 කනස්සල්ල', '😰 Anxious');
  String get gameSnakeTitle => _s('සර්ප ක්‍රීඩාව', 'Snake Game');
  String get gameSnakeDesc => _s('සම්භාව්‍ය සර්පයා — ඵල කා, දිගු වෙන්න. සරල පාලන, ලිහිල් වේගය.', 'Classic snake — eat fruit, grow longer. Simple controls, relaxing pace.');
  String get gameSnakeMood => _s('😴 කම්මැලිකම', '😴 Lazy');
  String get gameCandyCrushTitle => _s('කැන්ඩි ක්‍රශ්', 'Candy Crush');
  String get gameCandyCrushDesc => _s('සමාන කැන්ඩි එකතු කර පිපිරවන්න. ස්වභාවිකව ලිහිල් වේගය.', 'Match same candies to pop them. Naturally relaxing pace.');
  String get gameCandyCrushMood => _s('🍬 සුන්දර ස්තුති', '🍬 Sweet Joy');
  String get gamePuzzleTitle => _s('පැසුල් ක්‍රීඩා', 'Puzzle Game');
  String get gamePuzzleDesc => _s('පැසුල් සකස් කර රූප සකසන්න. නිශ්චල සහ සුන්දර වේගය.', 'Arrange pieces to form pictures. Calm and beautiful pace.');
  String get gamePuzzleMood => _s('🧩 සන්සුන් පුරුදු', '🧩 Mindful Focus');
  String get gameWordPuzzleTitle => _s('අකුරු පැසුල්', 'Word Puzzle');
  String get gameWordPuzzleDesc => _s('අකුරු සකස් කර ශබ්ද සොයන්න. මැදිහත්කරණීය සහ දැනුම් වර්ධනී.', 'Form words by arranging letters. Meditative and vocabulary building.');
  String get gameWordPuzzleMood => _s('🔤 දැනුම් වර්ධනය', '🔤 Brain Boost');

  // ── Game UI strings ────────────────────────────────────────────────────────
  String get gameOver => _s('ක්‍රීඩාව අවසන්!', 'Game Over!');
  String get playAgain => _s('නැවත ක්‍රීඩා කරන්න', 'Play Again');
  String get start => _s('ආරම්භ කරන්න', 'START');
  String get play => _s('ක්‍රීඩා කරන්න', 'PLAY');
  String get score => _s('ලකුණු', 'Score');
  String get round => _s('වටය', 'Round');
  String get moves => _s('ගමන්', 'Moves');
  String get pairs => _s('යුගල', 'Pairs');
  String get blocks => _s('කොටස්', 'Blocks');
  String get tapToDrop => _s('හෙළීමට ස්පර්ශ කරන්න!', 'TAP TO DROP!');
  String get dropInto => _s('හෙළන්න:', 'Drop into:');

  // ── Exit game dialog ───────────────────────────────────────────────────────
  String get exitGameTitle => _s('ක්‍රීඩාව හැර යන්නද? 🎮', 'Leave the game? 🎮');
  String get exitGameMsg => _s(
    'ඔබ ඉතා හොඳින් ක්‍රීඩා කරමින් සිටී!\nදැන් ගියොත් ප්‍රගතිය නැති වේ. 😢',
    'You\'re doing so well!\nYour progress will be lost if you leave. 😢',
  );
  String get exitGameYes => _s('ඔව්, යනවා 👋', 'Yes, leave 👋');
  String get exitGameNo => _s('නැහැ, ක්‍රීඩා කරනවා! 🎮', 'No, keep playing! 🎮');

  // Snake
  String get snakeInstructions => _s(
    'ගමන් කිරීමට ඊතල බොත්තම් භාවිතා කරන්න.\nඵල කා, දිගු වෙන්න!\nකිසිදු බිත්තියකට හෝ ඔබටම නොගැටෙන්න.',
    'Use the arrow buttons to move.\nEat the fruit to grow!\nDon\'t hit the walls or yourself.',
  );
  String get snakeHint => _s('💡 සර්පයා ගෙන යාමට පහළ ඊතල භාවිතා කරන්න!', '💡 Use the arrows below to move the snake!');

  // ── Game how-to-play & assistant ───────────────────────────────────────────
  String get howToPlay => _s('ක්‍රීඩා කරන ආකාරය', 'How to Play');
  String get gameAssistantTitle => _s('ක්‍රීඩා සහකාර', 'Game Assistant');
  String get gameAssistantTipLabel => _s('ඉඟිය', 'Tip');
  String get gameAssistantGotIt => _s('හරි, තේරුණා!', 'Got it!');

  List<String> get bubbleHowTo => isSinhala
      ? [
          'ඉහළට ඇද හෝ තට්ටු කර ඉලක්ක කරන්න.',
          'එකම වර්ණයේ බුබුළු 3ක් ස්පර්ශ වන සේ වෙඩි තබන්න.',
          'වර්ණ 3ක් එකට ගැලපීමෙන් බුබුළු පිපිරේ.',
          'සියලු බුබුළු ඉවත් කර මට්ටම දිනන්න!',
        ]
      : [
          'Aim by dragging or tapping above the bubbles.',
          'Shoot to touch 3 same-colored bubbles together.',
          'Bubbles pop when 3+ of the same color connect.',
          'Clear ALL bubbles to win the level!',
        ];
  List<String> get snakeHowTo => isSinhala
      ? [
          'සර්පයා ගෙන යාමට ඊතල භාවිතා කරන්න.',
          'ඵල කා වර්ධනය වන්න.',
          'බිත්ති හෝ ඔබටම නොගැටෙන්න.',
          'සෑම ඵලයක්ම ලකුණු 10කි!',
        ]
      : [
          'Use the arrows to move the snake.',
          'Eat the fruit to grow longer.',
          'Avoid the walls and yourself.',
          'Every fruit is worth 10 points!',
        ];
  List<String> get candyHowTo => isSinhala
      ? [
          'යාබද කැන්ඩි දෙකක් මාරු කරන්න.',
          'එකම ඒවා 3ක් පෙළගස්වා ගන්න.',
          '4+ක් ගැලපුවොත් විශේෂ කැන්ඩි සෑදේ!',
          'ගමන් අවසන් වන තුළ ඉලක්ක ලකුණු ලබා ගන්න.',
        ]
      : [
          'Swap two adjacent candies.',
          'Line up 3 of the same type.',
          'Match 4+ to create special candies!',
          'Reach the target score before the moves run out.',
        ];
  List<String> get puzzleHowTo => isSinhala
      ? [
          'හිස් තැනට යාබද උළුවල් ස්පර්ශ කරන්න.',
          'සංඛ්‍යා 1–15 නිවැරදි පිළිවෙළට සකසන්න.',
          'හැකි තරම් අඩු ගමන් වලින් විසඳන්න!',
          'සියල්ල පිළිවෙළට විට ඔබ දිනනවා!',
        ]
      : [
          'Tap tiles next to the empty space.',
          'Arrange tiles 1 to 15 in order.',
          'Solve it in as few moves as possible!',
          'You win when every number is in place!',
        ];
  List<String> get wordHowTo => isSinhala
      ? [
          'අකුරු තේරීමෙන් වචනය තනන්න.',
          'ආපසු තැබීමට තෝරාගත් අකුරක් ස්පර්ශ කරන්න.',
          'වැරදි නම් අකුරු නැවත මුසු වේ.',
          'අඛණ්ඩව නිවැරදි වීමෙන් ලකුණු උපයන්න!',
        ]
      : [
          'Tap letters in the pool to build the word.',
          'Tap a chosen letter to return it.',
          'A wrong guess reshuffles the letters.',
          'Keep a streak of correct words for bonus points!',
        ];

  List<String> get bubbleTips => isSinhala
      ? [
          'ඉලක්කය පැත්තේ බිත්තියෙන් පැනිය හැක — කෝණික වෙඩි බොහෝ විට වඩා හොඳයි!',
          'වර්ණ 2 වත් ඇති මට්ටම්වලදී බිත්ති පැනීමෙන් පහසුවෙන් ගැලපිය හැක.',
          'වෙඩි තැබීමට පෙර මීළඟ බුබුළු වර්ණය බලන්න — ඊළඟට එන්නේ එයයි.',
        ]
      : [
          'Shots can bounce off the side walls — angled shots often line up better!',
          'In 2-color levels, a wall bounce can help you reach tough spots.',
          'Watch the NEXT bubble color — that\'s what you\'ll shoot right after.',
        ];
  List<String> get snakeTips => isSinhala
      ? [
          'ක්‍රීඩාව ආරම්භයේ උපදෙස් මතක තබා ගන්න — දිශා අතරට විරුද්ධ පැත්තට හැරවීම වළක්වන්න.',
          'බිත්තියට ආසන්නව යන විට දිශාව කලින්ම හරවන්න.',
          'ලකුණු 50කට වරක් වේගය ඉහළ යයි — සූදානම් වන්න!',
        ]
      : [
          'You can\'t reverse directly backwards — plan your turns.',
          'When close to a wall, change direction early.',
          'Every 50 points the speed increases — stay sharp!',
        ];
  List<String> get candyTips => isSinhala
      ? [
          'කැන්ඩි 4ක් හෝ 5ක් පෙළගැස්වීමෙන් විශේෂ කැන්ඩි සෑදේ — ඒවා මාරු කිරීමෙන් පිපිරවිය හැක!',
          'කොම්බෝ පිපිරුම් වැඩි ලකුණු ගෙන දේ — ගැලපීම් දාමයක් තැනීමට උත්සාහ කරන්න.',
          'ඉලක්ක ලකුණු වෙත අවධානය යොමු කරන්න — ගමන් ඉතිරි කර ගන්න.',
        ]
      : [
          'Matching 4 or 5 candies creates specials — swap them to detonate!',
          'Combos score extra — try to chain matches together.',
          'Keep your eye on the target score and save your moves.',
        ];
  List<String> get puzzleTips => isSinhala
      ? [
          'පළමුව ඉහළම පේළිය නිවැරදි කරන්න, පසුව ඉදිරියට යන්න.',
          'ඉහළ පේළි සවි කළ පසු ඒවා යළි නොකැඩෙන සේ වැඩ කරන්න.',
          'හොඳම කාලය ගණන අඩු කිරීමට හිස් තැන ආසන්නයේම තබා ගන්න.',
        ]
      : [
          'Fix the top row first, then work your way down.',
          'Once the top rows are set, avoid disturbing them.',
          'Keep the empty space near the tiles you\'re arranging.',
        ];
  List<String> get wordTips => isSinhala
      ? [
          'තේරීමෙන් පෙර වචනයේ අකුරු ගණන බලන්න.',
          'ස්වර සහ ව්‍යාංජන එකිනෙක අසල තබා උත්සාහ කරන්න.',
          'අඛණ්ඩ නිවැරදි වචන ස්ට්‍රීක් බෝනස් ලකුණු දෙයි!',
        ]
      : [
          'Check the letter count before you start choosing.',
          'Look for common patterns — vowels beside consonants.',
          'A correct-word streak earns bonus points each time!',
        ];

  // Pattern Match
  String get patternInstructions => _s(
    'ගැලපෙන යුගල සොයා ගැනීමට කාඩ් පෙරළන්න!\nකාඩ් දෙකක් ස්පර්ශ කරන්න — ගැලපෙන්නේ නම්, ඒවා විවෘතව රැඳේ.\nසියලු යුගල ඉවත් කිරීමට ඉදිරියට යන්න!',
    'Flip cards to find matching pairs!\nTap two cards — if they match, they stay open.\nClear all pairs to advance!',
  );

  // Aim & Drop
  String get aimInstructions => _s(
    'බෝලය වමට සහ දකුණට ඉදිරියට යයි.\nගැලපෙන වර්ණ කලාපයට හෙළීමට ස්පර්ශ කරන්න!\nබෝල වර්ණය කලාපයට ගැලපෙන්නට ඕනෑ.',
    'A ball swings left and right.\nTap to drop it into the matching colored zone!\nMatch the ball color to the zone.',
  );

  // Stack Builder
  String get stackInstructions => _s(
    'කාර්යය, විවේකය, විනෝදය සහ තවත් කොටස් ගොඩ ගසන්න!\nගමන් කරන කොටස හෙළීමට ස්පර්ශ කරන්න.\nපරිපූර්ණ ලෙස සකසන්න.\nසම්පූර්ණයෙන් මඟ හැරෙන්නේ නම් = ක්‍රීඩාව අවසන්!',
    'Stack blocks of Work, Rest, Fun & more!\nTap to drop each moving block.\nAlign perfectly for max score.\nMiss completely = game over!',
  );
  String get towerFell => _s('කුළුණ ඇද වැටුණා!', 'Tower Fell!');
  String get buildAgain => _s('නැවත ගොඩ ගසන්න', 'Build Again');
  String get masterBuilder => _s('ශ්‍රේෂ්ඨ ගොඩ ගැසීම! පරිපූර්ණ සමතුලිතතාව! 🏆', 'Master builder! Perfect balance! 🏆');
  String get greatStack => _s('විශිෂ්ට ගොඩ ගැසීම! සමතුලිතතාව ඉදිරියට! 🏗️', 'Great stack! Keep balancing! 🏗️');
  String get towerFellMsg => _s('කුළුණ ඇද වැටුණා... මගේ සැලසුම් මෙන් 😂', 'The tower fell... like my plans 😂');
  String get foundation => _s('පදනම', 'Foundation');
  String get stackWork => _s('කාර්යය', 'Work');
  String get stackRest => _s('විවේකය', 'Rest');
  String get stackFun => _s('විනෝදය', 'Fun');
  String get stackSleep => _s('නිදිමත', 'Sleep');
  String get stackFriends => _s('මිතුරන්', 'Friends');
  String get stackHobby => _s('විනෝදාංශය', 'Hobby');
  String get stackExercise => _s('ව්‍යායාම', 'Exercise');
  String get stackMeTime => _s('මගේ කාලය', 'Me Time');

  // ── Auth ──────────────────────────────────────────────────────────────────
  String get welcomeBack => _s('නැවත සාදරයෙන් පිළිගනිමු', 'Welcome back');
  String get signInSubtitleAuth => _s('ඔබේ සෞඛ්‍ය ගමන ඉදිරියට ගෙන යන්න', 'Sign in to continue your wellness journey');
  String get email => _s('විද්‍යුත් තැපෑල', 'Email');
  String get password => _s('මුරපදය', 'Password');
  String get forgotPassword => _s('මුරපදය අමතකද?', 'Forgot password?');
  String get orText => _s('හෝ', 'or');
  String get continueWithGoogle => _s('Google සමඟ ඉදිරියට', 'Continue with Google');
  String get noAccount => _s('ගිණුමක් නැද්ද?', "Don't have an account?");
  String get createAccount => _s('ගිණුමක් සාදන්න', 'Create account');
  String get startJourney => _s('ඔබේ සෞඛ්‍ය ගමන අද ආරම්භ කරන්න', 'Start your wellness journey today');
  String get confirmPassword => _s('මුරපදය තහවුරු කරන්න', 'Confirm password');
  String get passwordMinLength => _s('මුරපදය අවම අකුරු 6 ක් විය යුතුය', 'Password must be at least 6 characters');
  String get passwordsNoMatch => _s('මුරපද ගැලපෙන්නේ නැත', 'Passwords do not match');
  String get alreadyHaveAccount => _s('දැනටමත් ගිණුමක් තිබේද?', 'Already have an account?');
  String get enterEmail => _s('ඔබේ විද්‍යුත් තැපෑල ඇතුළත් කරන්න', 'Please enter your email');
  String get enterPassword => _s('ඔබේ මුරපදය ඇතුළත් කරන්න', 'Please enter your password');

  // ── Resources ─────────────────────────────────────────────────────────────
  String get resources => _s('සම්පත්', 'Resources');
  String get saved => _s('සුරකින ලද', 'Saved');
  String get searchResources => _s('සම්පත් සොයන්න...', 'Search resources...');
  String get noResultsFound => _s('ප්‍රතිඵල හමු නොවීය', 'No results found');
  String get removeBookmark => _s('පිටු සලකුණ ඉවත් කරන්න', 'Remove bookmark');
  String get bookmark => _s('පිටු සලකුණ', 'Bookmark');

  // ── Reminders ─────────────────────────────────────────────────────────────
  String get remindersTitle => _s('මතක් කිරීම්', 'Reminders');
  String get pushTab => _s('තල්ලු', 'Push');
  String get calendarTab => _s('දිනදර්ශනය', 'Calendar');
  String get pushRemindersTitle => _s('තල්ලු මතක් කිරීම්', 'Push Reminders');
  String get pushRemindersSubtitle => _s('ඔබේ තෝරාගත් වේලාවේ ඔබේ උපාංගයේ මෘදු ඇඟවීමක් ලබා ගන්න 🌿', 'Get a gentle nudge on your device at your chosen time 🌿');
  String get dailyReminderToggle => _s('දෛනික මතක් කිරීම', 'Daily Reminder');
  String get tapToEnable => _s('සක්‍රිය කිරීමට තට්ටු කරන්න', 'Tap to enable');
  String get activeLabel => _s('සක්‍රිය', 'Active');
  String get tapToChange => _s('වෙනස් කිරීමට තට්ටු කරන්න', 'Tap to change');
  String get repeatLabel => _s('නැවත කිරීම', 'Repeat');
  String get reminderMessage => _s('මතක් කිරීමේ පණිවිඩය', 'Reminder Message');
  String get pushInfoNote => _s('යෙදුම වසා ඇති විට පවා තල්ලු මතක් කිරීම් ක්‍රියා කරයි.', 'Push reminders work even when the app is closed.');
  String get calendarReminderTitle => _s('දිනදර්ශන මතක් කිරීම', 'Calendar Reminder');
  String get calendarReminderSubtitle => _s('ඔබේ උපාංග දිනදර්ශනයට සෞඛ්‍ය සිදුවීමක් සෘජුවම එකතු කරන්න 📅', 'Add a wellness event directly to your device calendar 📅');
  String get reminderType => _s('මතක් කිරීමේ වර්ගය', 'Reminder Type');
  String get dateLabel => _s('දිනය', 'Date');
  String get timeLabel => _s('වේලාව', 'Time');
  String get tapToChoose => _s('තෝරා ගැනීමට තට්ටු කරන්න', 'Tap to choose');
  String get recurringLabel => _s('නැවත නැවත', 'Recurring');
  String get repeatsWeekly => _s('සතිපතා නැවත කෙරේ', 'Repeats weekly');
  String get oneTimeEvent => _s('එක් වරක් සිදුවීම', 'One-time event');
  String get addToCalendarBtn => _s('දිනදර්ශනයට එකතු කරන්න', 'Add to Calendar');
  String get calendarInfoNote => _s('මෙය සිදුවීම තහවුරු කිරීමට ඔබේ උපාංග දිනදර්ශන යෙදුම විවෘත කරයි. MindCare වෙත දත්ත යවන්නේ නැත.', 'This opens your device calendar app to confirm the event. No data is sent to MindCare.');
  String get calendarProviderLabel => _s('දිනදර්ශනය', 'Calendar');
  String get calendarProviderHint => _s('එය එකතු කළ යුතු දිනදර්ශනය තෝරන්න', 'Choose which calendar to add it to');
  String get providerGoogle => _s('Google දිනදර්ශනය', 'Google Calendar');
  String get providerApple => _s('Apple දිනදර්ශනය', 'Apple Calendar');
  String get providerOutlook => _s('Outlook', 'Outlook');
  String get providerSamsung => _s('Samsung දිනදර්ශනය', 'Samsung Calendar');
  String get providerOther => _s('වෙනත් / පෙරනිමිය', 'Other / Default');
  String get calendarAddedSnack => _s(
        'දිනදර්ශනයට එකතු කරන ලදී',
        'Added to calendar',
      );
  // Reminder type labels
  String get typeMoodCheckin => _s('මනෝභාව පරීක්ෂාව', 'Mood Check-in');
  String get typeBreathing => _s('හුස්ම ගැනීමේ සැසිය', 'Breathing Session');
  String get typeMeditation => _s('භාවනාව', 'Meditation');
  String get typeJournal => _s('දිනපොත් ඇතුළත් කිරීම', 'Journal Entry');
  String get typeCustom => _s('අභිරුචි', 'Custom');
  // Preset reminder messages
  List<String> get reminderPresets => isSinhala ? [
    'ඔබේ දෛනික සෞඛ්‍ය පරීක්ෂාවේ වේලාව 🌿',
    'ඔබ අද කෙසේ සිටිනවාද? ඔබ වෙනුවෙන් මොහොතක් ගන්න 💚',
    'හුස්ම ගන්න. ඔබට හැකිය. MindCare විවෘත කරන්න 🧘',
    'ඔබේ මානසික සෞඛ්‍යය වැදගත්. දැන් පරීක්ෂා කරන්න 🌸',
    'සිහිකල්පනාවේ මොහොතක් ඔබ බලා සිටී 🌟',
  ] : [
    'Time for your daily wellness check-in 🌿',
    'How are you feeling today? Take a moment for yourself 💚',
    'Breathe. You\'ve got this. Open MindCare 🧘',
    'Your mental health matters. Check in now 🌸',
    'A moment of mindfulness awaits you 🌟',
  ];

  // ── Counsellor Call ───────────────────────────────────────────────────────
  String get counsellorCallTitle => _s('උපදේශක ඇමතුම', 'Counsellor Call');
  String get doctorsTab => _s('වෛද්‍යවරු', 'Doctors');
  String get hotlinesTab => _s('හොට්ලයින්', 'Hotlines');
  String get specializationFilter => _s('විශේෂීකරණය', 'Specialization');
  String get languageFilter => _s('භාෂාව', 'Language');
  String get specAll => _s('සියල්ල', 'All');
  String get specClinicalPsychologist => _s('සායනික මනෝවිද්‍යාඥ', 'Clinical Psychologist');
  String get specCounsellor => _s('උපදේශක', 'Counsellor');
  String get specPsychiatrist => _s('මනෝ වෛද්‍යවරයා', 'Psychiatrist');
  String get specGP => _s('සාමාන්‍ය වෛද්‍යවරයා', 'GP');
  String get langAll => _s('සියල්ල', 'All');
  String get langSinhala => _s('සිංහල', 'Sinhala');
  String get langEnglish => _s('ඉංග්‍රීසි', 'English');
  String get langTamil => _s('දෙමළ', 'Tamil');
  String get noDoctorsFound => _s('තෝරාගත් පෙරහන් සඳහා වෛද්‍යවරු හමු නොවීය.', 'No doctors found for selected filters.');
  String get ratingLabel => _s('ශ්‍රේණිගත කිරීම', 'Rating');
  String get reviewsLabel => _s('සමාලෝචන', 'Reviews');
  String get feeLabel => _s('ගාස්තුව', 'Fee');
  String get freeLabel => _s('නොමිලේ', 'Free');
  String get availableNow => _s('දැන් ලබා ගත හැකිය', 'Available Now');
  String get currentlyUnavailable => _s('දැනට ලබා ගත නොහැකිය', 'Currently Unavailable');
  String get aboutSection => _s('ගැන', 'About');
  String get qualificationsSection => _s('සුදුසුකම්', 'Qualifications');
  String get languagesSection => _s('භාෂා', 'Languages');
  String get bookAudioSession => _s('ශ්‍රව්‍ය සැසිය වෙන් කරන්න', 'Book Audio Session');
  String get bookingComingSoon => _s('වෙන් කිරීම ඉක්මනින් ලැබේ! අංගය සංවර්ධනය වෙමින් පවතී.', 'Booking coming soon! Feature in development.');
  String get contactSection => _s('සම්බන්ධ වන්න සහ ස්ථානය', 'Contact & Location');
  String get hotlineInfoNote => _s('සියලු හොට්ලයින් නොමිලේ සහ රහස්‍ය ය. ඇමතීමට අංකයක් ස්පර්ශ කරන්න.', 'All hotlines are free and confidential. Tap a number to call.');
  String get catMentalHealth => _s('මානසික සෞඛ්‍යය', 'Mental Health');
  String get catCrisisSupport => _s('අර්බුද සහාය', 'Crisis Support');
  String get catDomesticViolence => _s('ගෘහස්ත හිංසනය', 'Domestic Violence');
  String get catEmergency => _s('හදිසි', 'Emergency');
  String get catGeneral => _s('සාමාන්‍ය', 'General');
  String get couldNotLoadDoctors => _s('වෛද්‍යවරු පූරණය කළ නොහැකිය.', 'Could not load doctors.');

  // ── Motivational ─────────────────────────────────────────────────────────
  String get motivationalBoostTitle => _s('ප්‍රබෝධමත් දිරිගැන්වීම', 'Motivational Boost');
  String get searchQuotesHint => _s('උද්ධෘත, කතුවරුන් සොයන්න...', 'Search quotes, authors...');
  String get noQuotesFound => _s('උද්ධෘත හමු නොවීය', 'No quotes found');
  String get saveQuote => _s('උද්ධෘතය සුරකින්න', 'Save Quote');
  String get categoryAll => _s('සියල්ල', 'All');
  String get categoryLove => _s('ආදරය', 'Love');
  String get categoryStrength => _s('ශක්තිය', 'Strength');
  String get categorySuccess => _s('සාර්ථකත්වය', 'Success');
  String get categoryMindfulness => _s('සිහිකල්පනාව', 'Mindfulness');
  String get categoryCourage => _s('ධෛර්යය', 'Courage');
  String get categoryHappiness => _s('සතුට', 'Happiness');
  String get categoryGrowth => _s('වර්ධනය', 'Growth');
  String get categoryCaring => _s('සැලකිලිමත්කම', 'Caring');
  String get categoryResilience => _s('ඔරොත්තු දීම', 'Resilience');
  String get categoryPeace => _s('සාමය', 'Peace');

  // ── Common ────────────────────────────────────────────────────────────────
  String get continueBtn => _s('ඉදිරියට', 'Continue');
  String get back => _s('ආපසු', 'Back');
  String get save => _s('සුරකින්න', 'Save');
  String get cancel => _s('අවලංගු කරන්න', 'Cancel');
  String get remove => _s('ඉවත් කරන්න', 'Remove');
  String get edit => _s('සංස්කරණය', 'Edit');
  String get delete => _s('මකන්න', 'Delete');
  String get close => _s('වසන්න', 'Close');
  String get ok => _s('හරි', 'OK');
  String get yes => _s('ඔව්', 'Yes');
  String get no => _s('නැහැ', 'No');
  String get loading => _s('පූරණය වෙමින්...', 'Loading...');
  String get error => _s('දෝෂය', 'Error');
  String get retry => _s('නැවත උත්සාහ කරන්න', 'Retry');
  String get today => _s('අද', 'Today');
}
