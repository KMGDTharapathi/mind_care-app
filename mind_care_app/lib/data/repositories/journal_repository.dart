import '../local/hive_service.dart';
import '../models/journal_entry.dart';

abstract class JournalRepository {
  Future<void> saveEntry(JournalEntry entry);
  Future<void> deleteEntry(String id);
  Future<List<JournalEntry>> getAllEntries();
}

class HiveJournalRepository implements JournalRepository {
  @override
  Future<void> saveEntry(JournalEntry entry) async {
    await HiveService.journalEntries.put(entry.id, entry);
  }

  @override
  Future<void> deleteEntry(String id) async {
    await HiveService.journalEntries.delete(id);
  }

  @override
  Future<List<JournalEntry>> getAllEntries() async {
    final entries = HiveService.journalEntries.values.toList();
    entries.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return entries;
  }
}
