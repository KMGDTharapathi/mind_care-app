import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';

import '../../data/local/hive_service.dart';
import '../../data/models/journal_entry.dart';
import '../../data/models/mood_entry.dart';
import '../auth/auth_service.dart';
import '../crashlytics/crashlytics_service.dart';
import 'write_queue.dart';

/// Abstract interface for the sync service.
abstract class SyncService {
  Future<void> startSync(String uid);
  Future<void> stopSync();
  Future<void> flushQueue();
  Future<void> enqueueMoodEntry(MoodEntry entry);
  Future<void> enqueueJournalEntry(JournalEntry entry);
  Future<void> enqueueBookmark(String resourceId, bool bookmarked);
  Future<void> enqueueSettings(Map<String, dynamic> settings);
  Future<void> enqueueStreak(int count, String lastActiveDate);
}

/// No-op implementation when running without Firebase.
class NoOpSyncService implements SyncService {
  NoOpSyncService({
    required AuthService authService,
    required WriteQueue writeQueue,
    CrashlyticsService? crashlyticsService,
  });

  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;
  bool _wasOffline = false;

  void _startConnectivityMonitoring() {
    _connectivitySubscription?.cancel();
    _connectivitySubscription = Connectivity()
        .onConnectivityChanged
        .listen((List<ConnectivityResult> results) {
      final isOnline = results.any((r) => r != ConnectivityResult.none);
      if (_wasOffline && isOnline) {
        flushQueue();
      }
      _wasOffline = !isOnline;
    });
  }

  @override
  Future<void> startSync(String uid) async {
    _startConnectivityMonitoring();
  }

  @override
  Future<void> stopSync() async {
    _connectivitySubscription?.cancel();
    _connectivitySubscription = null;
  }

  @override
  Future<void> flushQueue() async {
    // No-op when Firebase is not configured
  }

  @override
  Future<void> enqueueMoodEntry(MoodEntry entry) async {
    await HiveService.moodEntries.put(entry.id, entry);
  }

  @override
  Future<void> enqueueJournalEntry(JournalEntry entry) async {
    await HiveService.journalEntries.put(entry.id, entry);
  }

  @override
  Future<void> enqueueBookmark(String resourceId, bool bookmarked) async {
    if (bookmarked) {
      await HiveService.bookmarks.put(resourceId, resourceId);
    } else {
      await HiveService.bookmarks.delete(resourceId);
    }
  }

  @override
  Future<void> enqueueSettings(Map<String, dynamic> settings) async {
    // Settings stored in SharedPreferences locally; no Hive write needed here.
  }

  @override
  Future<void> enqueueStreak(int count, String lastActiveDate) async {
    // No-op
  }
}