import 'package:hive_flutter/hive_flutter.dart';
import '../models/mood_entry.dart';
import '../models/journal_entry.dart';
import '../models/resource.dart';
import '../models/breathing_pattern.dart';
import '../../services/sync/write_queue.dart';
import '../../features/chat/models/chat_message.dart';

class HiveService {
  static const String _moodEntriesBox = 'mood_entries';
  static const String _journalEntriesBox = 'journal_entries';
  static const String _bookmarksBox = 'bookmarks';

  static Box<MoodEntry>? _moodBox;
  static Box<JournalEntry>? _journalBox;
  static Box<String>? _bookmarksBox_;
  static Box<WriteQueueEntry>? _writeQueueBox;

  static Box<MoodEntry> get moodEntries {
    assert(_moodBox != null && _moodBox!.isOpen, 'HiveService not initialized');
    return _moodBox!;
  }

  static Box<JournalEntry> get journalEntries {
    assert(
      _journalBox != null && _journalBox!.isOpen,
      'HiveService not initialized',
    );
    return _journalBox!;
  }

  static Box<String> get bookmarks {
    assert(
      _bookmarksBox_ != null && _bookmarksBox_!.isOpen,
      'HiveService not initialized',
    );
    return _bookmarksBox_!;
  }

  static Box<WriteQueueEntry> get writeQueue {
    assert(
      _writeQueueBox != null && _writeQueueBox!.isOpen,
      'HiveService not initialized',
    );
    return _writeQueueBox!;
  }

  static Future<void> init() async {
    await Hive.initFlutter();

    // Register adapters
    if (!Hive.isAdapterRegistered(0)) {
      Hive.registerAdapter(MoodTypeAdapter());
    }
    if (!Hive.isAdapterRegistered(1)) {
      Hive.registerAdapter(MoodEntryAdapter());
    }
    if (!Hive.isAdapterRegistered(2)) {
      Hive.registerAdapter(JournalEntryAdapter());
    }
    if (!Hive.isAdapterRegistered(3)) {
      Hive.registerAdapter(ResourceAdapter());
    }
    if (!Hive.isAdapterRegistered(4)) {
      Hive.registerAdapter(BreathingPhaseAdapter());
    }
    if (!Hive.isAdapterRegistered(5)) {
      Hive.registerAdapter(BreathingPatternAdapter());
    }

    if (!Hive.isAdapterRegistered(10)) {
      Hive.registerAdapter(WriteQueueEntryAdapter());
    }
    if (!Hive.isAdapterRegistered(11)) {
      Hive.registerAdapter(WriteOperationAdapter());
    }
    if (!Hive.isAdapterRegistered(20)) {
      Hive.registerAdapter(ChatMessageAdapter());
    }

    // Open all boxes in parallel — much faster than sequential awaits
    final results = await Future.wait([
      Hive.openBox<MoodEntry>(_moodEntriesBox),
      Hive.openBox<JournalEntry>(_journalEntriesBox),
      Hive.openBox<String>(_bookmarksBox),
      Hive.openBox<WriteQueueEntry>('write_queue'),
    ]);
    _moodBox = results[0] as Box<MoodEntry>;
    _journalBox = results[1] as Box<JournalEntry>;
    _bookmarksBox_ = results[2] as Box<String>;
    _writeQueueBox = results[3] as Box<WriteQueueEntry>;
  }

  static Future<void> close() async {
    await Hive.close();
  }
}
