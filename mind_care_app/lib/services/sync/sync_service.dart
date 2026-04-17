import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:uuid/uuid.dart';

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

/// Concrete implementation that orchestrates Hive ↔ Firestore sync.
class FirestoreSyncService implements SyncService {
  FirestoreSyncService({
    required AuthService authService,
    required WriteQueue writeQueue,
    FirebaseFirestore? firestore,
    CrashlyticsService? crashlyticsService,
  })  : _authService = authService,
        _writeQueue = writeQueue,
        _firestore = firestore ?? FirebaseFirestore.instance,
        _crashlyticsService = crashlyticsService;

  final AuthService _authService;
  final WriteQueue _writeQueue;
  final FirebaseFirestore _firestore;
  final CrashlyticsService? _crashlyticsService;

  String? _currentUid;
  final List<StreamSubscription<dynamic>> _firestoreSubscriptions = [];
  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;
  bool _wasOffline = false;

  // ─── Connectivity monitoring ────────────────────────────────────────────────

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

  // ─── startSync ──────────────────────────────────────────────────────────────

  @override
  Future<void> startSync(String uid) async {
    _currentUid = uid;
    _startConnectivityMonitoring();

    // mood_entries
    try {
      _firestoreSubscriptions.add(
        _firestore
            .collection('users')
            .doc(uid)
            .collection('mood_entries')
            .snapshots()
            .listen(
              (snapshot) => _onMoodEntriesSnapshot(snapshot),
              onError: (e, stack) => _crashlyticsService?.recordError(
                e,
                stack,
                reason: 'mood_entries listener error',
              ),
            ),
      );
    } catch (e, stack) {
      await _crashlyticsService?.recordError(e, stack,
          reason: 'startSync mood_entries failed');
    }

    // journal_entries
    try {
      _firestoreSubscriptions.add(
        _firestore
            .collection('users')
            .doc(uid)
            .collection('journal_entries')
            .snapshots()
            .listen(
              (snapshot) => _onJournalEntriesSnapshot(snapshot),
              onError: (e, stack) => _crashlyticsService?.recordError(
                e,
                stack,
                reason: 'journal_entries listener error',
              ),
            ),
      );
    } catch (e, stack) {
      await _crashlyticsService?.recordError(e, stack,
          reason: 'startSync journal_entries failed');
    }

    // bookmarks
    try {
      _firestoreSubscriptions.add(
        _firestore
            .collection('users')
            .doc(uid)
            .collection('bookmarks')
            .snapshots()
            .listen(
              (snapshot) => _onBookmarksSnapshot(snapshot),
              onError: (e, stack) => _crashlyticsService?.recordError(
                e,
                stack,
                reason: 'bookmarks listener error',
              ),
            ),
      );
    } catch (e, stack) {
      await _crashlyticsService?.recordError(e, stack,
          reason: 'startSync bookmarks failed');
    }

    // settings/preferences
    try {
      _firestoreSubscriptions.add(
        _firestore
            .collection('users')
            .doc(uid)
            .collection('settings')
            .doc('preferences')
            .snapshots()
            .listen(
              (snapshot) => _onSettingsSnapshot(snapshot),
              onError: (e, stack) => _crashlyticsService?.recordError(
                e,
                stack,
                reason: 'settings listener error',
              ),
            ),
      );
    } catch (e, stack) {
      await _crashlyticsService?.recordError(e, stack,
          reason: 'startSync settings failed');
    }
  }

  // ─── Firestore listener handlers ────────────────────────────────────────────

  void _onMoodEntriesSnapshot(QuerySnapshot<Map<String, dynamic>> snapshot) {
    for (final change in snapshot.docChanges) {
      if (change.type == DocumentChangeType.removed) continue;
      final data = change.doc.data();
      if (data == null) continue;
      try {
        final remoteUpdatedAt = (data['updatedAt'] as Timestamp?)?.toDate();
        final entryId = data['id'] as String? ?? change.doc.id;
        final localEntry = HiveService.moodEntries.get(entryId);

        // Only update Hive if remote is newer (or no local copy exists)
        if (localEntry == null ||
            remoteUpdatedAt == null ||
            remoteUpdatedAt.isAfter(localEntry.timestamp)) {
          final moodName = data['mood'] as String? ?? '';
          final mood = MoodType.values.firstWhere(
            (m) => m.name == moodName,
            orElse: () => MoodType.calm,
          );
          final entry = MoodEntry(
            id: entryId,
            mood: mood,
            note: data['note'] as String?,
            timestamp: (data['timestamp'] as Timestamp?)?.toDate() ??
                DateTime.now(),
          );
          HiveService.moodEntries.put(entryId, entry);
        }
      } catch (_) {
        // Silently ignore malformed documents
      }
    }
  }

  void _onJournalEntriesSnapshot(
      QuerySnapshot<Map<String, dynamic>> snapshot) {
    for (final change in snapshot.docChanges) {
      if (change.type == DocumentChangeType.removed) continue;
      final data = change.doc.data();
      if (data == null) continue;
      try {
        final remoteUpdatedAt = (data['updatedAt'] as Timestamp?)?.toDate();
        final entryId = data['id'] as String? ?? change.doc.id;
        final localEntry = HiveService.journalEntries.get(entryId);

        if (localEntry == null ||
            remoteUpdatedAt == null ||
            remoteUpdatedAt.isAfter(localEntry.updatedAt)) {
          final entry = JournalEntry(
            id: entryId,
            title: data['title'] as String? ?? '',
            body: data['body'] as String? ?? '',
            createdAt: (data['createdAt'] as Timestamp?)?.toDate() ??
                DateTime.now(),
            updatedAt: remoteUpdatedAt ?? DateTime.now(),
          );
          HiveService.journalEntries.put(entryId, entry);
        }
      } catch (_) {
        // Silently ignore malformed documents
      }
    }
  }

  void _onBookmarksSnapshot(QuerySnapshot<Map<String, dynamic>> snapshot) {
    for (final change in snapshot.docChanges) {
      final resourceId = change.doc.id;
      if (change.type == DocumentChangeType.removed) {
        HiveService.bookmarks.delete(resourceId);
        continue;
      }
      final data = change.doc.data();
      if (data == null) continue;
      try {
        final bookmarked = data['bookmarked'] as bool? ?? false;
        if (bookmarked) {
          HiveService.bookmarks.put(resourceId, resourceId);
        } else {
          HiveService.bookmarks.delete(resourceId);
        }
      } catch (_) {
        // Silently ignore malformed documents
      }
    }
  }

  void _onSettingsSnapshot(DocumentSnapshot<Map<String, dynamic>> snapshot) {
    // Settings are read by the SettingsCubit directly; no Hive model for them.
    // This listener is registered to keep the subscription alive for future use.
  }

  // ─── stopSync ───────────────────────────────────────────────────────────────

  @override
  Future<void> stopSync() async {
    for (final sub in _firestoreSubscriptions) {
      await sub.cancel();
    }
    _firestoreSubscriptions.clear();
    _connectivitySubscription?.cancel();
    _connectivitySubscription = null;
    _currentUid = null;

    // Clear user-specific Hive data
    await HiveService.moodEntries.clear();
    await HiveService.journalEntries.clear();
    await HiveService.bookmarks.clear();
  }

  // ─── flushQueue ─────────────────────────────────────────────────────────────

  @override
  Future<void> flushQueue() async {
    final uid = _currentUid;
    if (uid == null) return;
    if (_authService.currentUser?.isAnonymous == true) return;

    final entries = _writeQueue.getAll(); // already FIFO sorted
    for (final entry in entries) {
      try {
        final docRef = _firestore
            .collection('users')
            .doc(uid)
            .collection(entry.collection)
            .doc(entry.documentId);

        if (entry.operation == WriteOperation.upsert) {
          await docRef.set(
            {...entry.data, 'updatedAt': FieldValue.serverTimestamp()},
            SetOptions(merge: true),
          );
        } else {
          await docRef.delete();
        }

        await _writeQueue.dequeue(entry.id);
      } catch (e, stack) {
        await _crashlyticsService?.recordError(
          e,
          stack,
          reason: 'flushQueue write failed for ${entry.collection}/${entry.documentId}',
        );
        // Keep in queue — will retry on next flush
      }
    }
  }

  // ─── Helper: is authenticated (non-anonymous) ────────────────────────────────

  bool get _isAuthenticatedUser =>
      _authService.currentUser != null &&
      _authService.currentUser!.isAnonymous == false;

  // ─── Helper: enqueue to WriteQueue ──────────────────────────────────────────

  Future<void> _enqueue(
    String collection,
    String documentId,
    Map<String, dynamic> data, {
    WriteOperation operation = WriteOperation.upsert,
  }) async {
    await _writeQueue.enqueue(WriteQueueEntry(
      id: const Uuid().v4(),
      collection: collection,
      documentId: documentId,
      data: data,
      operation: operation,
      enqueuedAt: DateTime.now(),
    ));
  }

  // ─── Helper: write directly to Firestore ────────────────────────────────────

  Future<void> _writeToFirestore(
    String collection,
    String documentId,
    Map<String, dynamic> data,
  ) async {
    final uid = _currentUid ?? _authService.currentUser?.uid;
    if (uid == null) return;
    try {
      await _firestore
          .collection('users')
          .doc(uid)
          .collection(collection)
          .doc(documentId)
          .set(
            {...data, 'updatedAt': FieldValue.serverTimestamp()},
            SetOptions(merge: true),
          );
    } catch (e, stack) {
      await _crashlyticsService?.recordError(
        e,
        stack,
        reason: 'Firestore write failed for $collection/$documentId',
      );
      // Silently retain — caller decides whether to queue
    }
  }

  // ─── enqueueMoodEntry ────────────────────────────────────────────────────────

  @override
  Future<void> enqueueMoodEntry(MoodEntry entry) async {
    // Write to Hive first
    await HiveService.moodEntries.put(entry.id, entry);

    final data = {
      'id': entry.id,
      'mood': entry.mood.name,
      if (entry.note != null) 'note': entry.note,
      'timestamp': Timestamp.fromDate(entry.timestamp),
    };

    if (_authService.currentUser?.isAnonymous == true) {
      // NEVER write to Firestore for anonymous users
      await _enqueue('mood_entries', entry.id, data);
      return;
    }

    if (_isAuthenticatedUser) {
      await _writeToFirestore('mood_entries', entry.id, data);
    } else {
      await _enqueue('mood_entries', entry.id, data);
    }
  }

  // ─── enqueueJournalEntry ─────────────────────────────────────────────────────

  @override
  Future<void> enqueueJournalEntry(JournalEntry entry) async {
    // Write to Hive first
    await HiveService.journalEntries.put(entry.id, entry);

    final data = {
      'id': entry.id,
      'title': entry.title,
      'body': entry.body,
      'createdAt': Timestamp.fromDate(entry.createdAt),
      'updatedAt': Timestamp.fromDate(entry.updatedAt),
    };

    if (_authService.currentUser?.isAnonymous == true) {
      await _enqueue('journal_entries', entry.id, data);
      return;
    }

    if (_isAuthenticatedUser) {
      await _writeToFirestore('journal_entries', entry.id, data);
    } else {
      await _enqueue('journal_entries', entry.id, data);
    }
  }

  // ─── enqueueBookmark ─────────────────────────────────────────────────────────

  @override
  Future<void> enqueueBookmark(String resourceId, bool bookmarked) async {
    // Write to Hive first
    if (bookmarked) {
      await HiveService.bookmarks.put(resourceId, resourceId);
    } else {
      await HiveService.bookmarks.delete(resourceId);
    }

    final data = {
      'bookmarked': bookmarked,
      'updatedAt': Timestamp.fromDate(DateTime.now()),
    };

    if (_authService.currentUser?.isAnonymous == true) {
      await _enqueue('bookmarks', resourceId, data);
      return;
    }

    if (_isAuthenticatedUser) {
      await _writeToFirestore('bookmarks', resourceId, data);
    } else {
      await _enqueue('bookmarks', resourceId, data);
    }
  }

  // ─── enqueueSettings ─────────────────────────────────────────────────────────

  @override
  Future<void> enqueueSettings(Map<String, dynamic> settings) async {
    // Settings are stored in SharedPreferences locally; no Hive write needed here.

    if (_authService.currentUser?.isAnonymous == true) {
      await _enqueue('settings', 'preferences', settings);
      return;
    }

    if (_isAuthenticatedUser) {
      await _writeToFirestore('settings', 'preferences', settings);
    } else {
      await _enqueue('settings', 'preferences', settings);
    }
  }

  // ─── enqueueStreak ───────────────────────────────────────────────────────────

  @override
  Future<void> enqueueStreak(int count, String lastActiveDate) async {
    final data = {
      'streakCount': count,
      'lastActiveDate': lastActiveDate,
    };

    if (_authService.currentUser?.isAnonymous == true) {
      await _enqueue('settings', 'preferences', data);
      return;
    }

    if (_isAuthenticatedUser) {
      await _writeToFirestore('settings', 'preferences', data);
    } else {
      await _enqueue('settings', 'preferences', data);
    }
  }
}
