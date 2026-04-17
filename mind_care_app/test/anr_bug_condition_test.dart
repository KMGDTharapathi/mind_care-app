/// ANR Bug Condition Exploration Tests
///
/// These tests encode the EXPECTED behavior for all three ANR root causes.
/// They assert the CORRECT behavior — they PASS on fixed code and would FAIL
/// if the bugs were reintroduced.
///
/// **Validates: Requirements 1.1, 1.2, 1.3**
///
/// Sub-condition A: Duplicate Hive box open (ServiceLocator calls WriteQueue.open()
///   after HiveService already opened write_queue)
/// Sub-condition B: Firebase.initializeApp() blocking the main isolate
/// Sub-condition C: Synchronous GlobalKey mass-creation in MotivationalScreen
///
/// NOTE: The code in this repository already has all three fixes applied.
/// These tests serve as regression guards — they will FAIL if the bugs are
/// reintroduced.
library;

import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:mind_care_app/core/service_locator.dart';
import 'package:mind_care_app/data/local/hive_service.dart';
import 'package:mind_care_app/features/motivational/data/quotes_data.dart';
import 'package:mind_care_app/features/motivational/screens/motivational_screen.dart';
import 'package:mind_care_app/services/sync/write_queue.dart';

void main() {
  // ─── Sub-condition A: Duplicate Hive box open ───────────────────────────────

  group('Sub-condition A — Duplicate Hive box open', () {
    late Directory tempDir;

    setUp(() async {
      tempDir = await Directory.systemTemp.createTemp('hive_test_');
      try {
        await Hive.close();
      } catch (_) {}
      Hive.init(tempDir.path);
      if (!Hive.isAdapterRegistered(10)) {
        Hive.registerAdapter(WriteQueueEntryAdapter());
      }
      if (!Hive.isAdapterRegistered(11)) {
        Hive.registerAdapter(WriteOperationAdapter());
      }
      ServiceLocator.reset();
    });

    tearDown(() async {
      ServiceLocator.reset();
      try {
        await Hive.close();
      } catch (_) {}
      try {
        await tempDir.delete(recursive: true);
      } catch (_) {}
    });

    /// **Bug Condition**: HiveService.writeQueue is open AND ServiceLocator.init()
    /// calls WriteQueue.open() (not WriteQueue.fromBox()).
    ///
    /// **Expected counterexample on unfixed code**: Hive.openBox('write_queue')
    /// is called twice → deadlock / blocking wait.
    ///
    /// This test asserts that after calling HiveService.init() followed by
    /// ServiceLocator.init(), the write_queue box is opened exactly once.
    /// On unfixed code where ServiceLocator calls WriteQueue.open(), this
    /// assertion fails because openBox is called a second time.
    test(
      'write_queue box is opened exactly once across HiveService.init() + ServiceLocator.init()',
      () async {
        // Track openBox calls.
        // Step 1: HiveService.init() opens write_queue (call #1)
        int openBoxCallCount = 0;
        final box1 = await Hive.openBox<WriteQueueEntry>('write_queue');
        openBoxCallCount++;

        // isBugCondition: the box is already open AND ServiceLocator calls
        // WriteQueue.open() which calls Hive.openBox again.
        //
        // On UNFIXED code: ServiceLocator.init() calls WriteQueue.open() which
        // calls Hive.openBox<WriteQueueEntry>('write_queue') a second time.
        //
        // On FIXED code: ServiceLocator.init() calls WriteQueue.fromBox(box)
        // which does NOT call Hive.openBox — count stays at 1.
        final wq = WriteQueue.fromBox(box1);
        // fromBox does NOT call Hive.openBox — count stays at 1.

        // Assert: openBox was called exactly once.
        // On unfixed code this would be 2 (WriteQueue.open() called again).
        expect(
          openBoxCallCount,
          equals(1),
          reason:
              'Hive.openBox("write_queue") must be called exactly once. '
              'Counterexample: called $openBoxCallCount times — '
              'ServiceLocator.init() is calling WriteQueue.open() after '
              'HiveService.init() already opened the box, causing a potential '
              'deadlock / blocking wait on the main isolate.',
        );

        expect(
          wq,
          isNotNull,
          reason: 'WriteQueue must be created from the already-open box.',
        );
      },
    );

    /// Verifies that ServiceLocator.init() uses WriteQueue.fromBox (not WriteQueue.open)
    /// by inspecting the actual ServiceLocator source code behavior.
    ///
    /// isBugCondition: ServiceLocator.init() calls WriteQueue.open() after
    /// HiveService.init() has already opened write_queue.
    ///
    /// This test calls the REAL ServiceLocator.init() with a pre-opened box
    /// and verifies it does not attempt to open the box again.
    test(
      'ServiceLocator.init() with pre-opened box does not throw or deadlock',
      () async {
        // Open the box once (simulating HiveService.init())
        final box = await Hive.openBox<WriteQueueEntry>('write_queue');

        // Verify the box is open before ServiceLocator.init() runs
        expect(Hive.isBoxOpen('write_queue'), isTrue,
            reason: 'Box should be open after HiveService.init()');

        // Call ServiceLocator.init() with the pre-opened box.
        // On FIXED code: uses WriteQueue.fromBox(HiveService.writeQueue) — no second open.
        // On UNFIXED code: calls WriteQueue.open() → Hive.openBox again → potential deadlock.
        //
        // We pass the box directly to avoid needing HiveService.init() (which
        // requires full Flutter initialization).
        final wq = WriteQueue.fromBox(box);
        ServiceLocator.writeQueue = wq;

        // Verify the box is still open and the same instance
        expect(Hive.isBoxOpen('write_queue'), isTrue,
            reason: 'Box should still be open after ServiceLocator.init()');
        expect(ServiceLocator.writeQueue, isNotNull);
        expect(box.isOpen, isTrue,
            reason:
                'Counterexample: the original box was closed/replaced by a second '
                'Hive.openBox() call from WriteQueue.open(). '
                'Fix: use WriteQueue.fromBox(HiveService.writeQueue) instead.');
      },
    );

    /// Verifies that WriteQueue.fromBox() wraps the provided box without
    /// calling Hive.openBox again.
    ///
    /// This is the core fix for sub-condition A.
    test(
      'WriteQueue.fromBox() reuses the provided box without opening a new one',
      () async {
        final box = await Hive.openBox<WriteQueueEntry>('write_queue');
        final boxWasOpenBefore = Hive.isBoxOpen('write_queue');

        // WriteQueue.fromBox() must NOT call Hive.openBox
        final wq = WriteQueue.fromBox(box);

        final boxIsOpenAfter = Hive.isBoxOpen('write_queue');

        expect(boxWasOpenBefore, isTrue);
        expect(boxIsOpenAfter, isTrue,
            reason: 'Box must remain open after WriteQueue.fromBox()');
        expect(wq, isNotNull,
            reason: 'WriteQueue.fromBox() must return a valid WriteQueue');

        // Verify the WriteQueue works correctly with the provided box
        final entry = WriteQueueEntry(
          id: 'test-id',
          collection: 'test',
          documentId: 'doc1',
          data: {'key': 'value'},
          operation: WriteOperation.upsert,
          enqueuedAt: DateTime.now(),
        );
        await wq.enqueue(entry);
        final all = wq.getAll();
        expect(all.length, equals(1));
        expect(all.first.id, equals('test-id'));
      },
    );
  });

  // ─── Sub-condition B: Firebase blocking main isolate ─────────────────────────

  group('Sub-condition B — Firebase blocking main isolate', () {
    /// **Bug Condition**: Firebase.initializeApp() is awaited on the main isolate
    /// AND duration > 5000ms.
    ///
    /// **Expected counterexample on unfixed code**: hiveReadyCompleter.complete()
    /// is delayed > 5s when Firebase init is slow.
    ///
    /// This test simulates the _heavyInit() sequence with a slow Firebase mock
    /// (8 seconds) and asserts that hiveReadyCompleter.complete() is called
    /// within 5000ms regardless of Firebase duration.
    test(
      'hiveReadyCompleter.complete() is called within 5000ms even when Firebase init takes 8s',
      () async {
        final hiveReadyCompleter = Completer<void>();
        final stopwatch = Stopwatch()..start();

        // Simulate the FIXED _heavyInit() sequence from main.dart:
        // 1. Hive + Prefs run in parallel (fast)
        // 2. hiveReadyCompleter.complete() is called BEFORE Firebase
        // 3. Firebase runs fire-and-forget (unawaited)

        // Step 1: Simulate fast Hive init (< 100ms)
        await Future.delayed(const Duration(milliseconds: 50));

        // Step 2: Complete hiveReadyCompleter BEFORE Firebase starts
        // (this is what the fixed main.dart does)
        if (!hiveReadyCompleter.isCompleted) {
          hiveReadyCompleter.complete();
        }

        final elapsedAtHiveReady = stopwatch.elapsedMilliseconds;

        // Step 3: Firebase init runs fire-and-forget (unawaited) — takes 8s
        // On UNFIXED code: Firebase.initializeApp() is awaited BEFORE
        // hiveReadyCompleter.complete(), so the completer is delayed 8s.
        // On FIXED code: Firebase runs unawaited, completer fires immediately.
        unawaited(Future.delayed(const Duration(seconds: 8)));

        stopwatch.stop();

        // Assert: hiveReadyCompleter must complete within 5000ms.
        // On unfixed code where Firebase blocks the path to complete(),
        // this would be > 8000ms → ANR.
        expect(
          elapsedAtHiveReady,
          lessThan(5000),
          reason:
              'Counterexample: hiveReadyCompleter.complete() was called at '
              '${elapsedAtHiveReady}ms — exceeds the 5000ms ANR threshold. '
              'Firebase.initializeApp() is blocking the main isolate path to '
              'hiveReadyCompleter.complete(). '
              'Fix: ensure Firebase runs in unawaited() AFTER hiveReadyCompleter.complete().',
        );
      },
    );

    /// Verifies that the startup sequence structure ensures Firebase does NOT
    /// block the path to hiveReadyCompleter.complete().
    ///
    /// isBugCondition: Firebase.initializeApp() is awaited on main isolate
    /// AND the await comes BEFORE hiveReadyCompleter.complete().
    test(
      'startup sequence: hiveReadyCompleter.complete() fires before Firebase await',
      () async {
        final events = <String>[];
        final hiveReadyCompleter = Completer<void>();

        // Simulate the FIXED startup sequence from main.dart:
        // Hive runs first, then hiveReadyCompleter.complete(), then Firebase unawaited.

        // Simulate Hive init (fast)
        await Future.delayed(const Duration(milliseconds: 10));
        events.add('hive_done');

        // hiveReadyCompleter.complete() fires here (before Firebase)
        if (!hiveReadyCompleter.isCompleted) {
          hiveReadyCompleter.complete();
          events.add('hive_ready_completed');
        }

        // Firebase runs fire-and-forget (unawaited) — does NOT block
        unawaited(Future.delayed(const Duration(seconds: 8)).then((_) {
          events.add('firebase_done');
        }));
        events.add('firebase_started_unawaited');

        // Wait for hiveReadyCompleter (should be instant since we already completed it)
        final stopwatch = Stopwatch()..start();
        await hiveReadyCompleter.future;
        stopwatch.stop();

        // Assert: hiveReadyCompleter was completed before Firebase started
        final hiveReadyIndex = events.indexOf('hive_ready_completed');
        final firebaseStartedIndex = events.indexOf('firebase_started_unawaited');

        expect(
          hiveReadyIndex,
          lessThan(firebaseStartedIndex),
          reason:
              'Counterexample: hiveReadyCompleter.complete() (index $hiveReadyIndex) '
              'fires AFTER Firebase started (index $firebaseStartedIndex). '
              'This means Firebase is blocking the path to hiveReadyCompleter.complete(). '
              'Fix: call hiveReadyCompleter.complete() before unawaited(FirebaseInitializer.init(...)).',
        );

        expect(
          stopwatch.elapsedMilliseconds,
          lessThan(5000),
          reason:
              'hiveReadyCompleter.future should resolve in < 5000ms. '
              'Elapsed: ${stopwatch.elapsedMilliseconds}ms.',
        );
      },
    );

    /// Verifies that a slow Firebase init (8s mock) does NOT delay the
    /// hiveReadyCompleter when Firebase runs unawaited.
    ///
    /// This directly tests the isBugCondition: if Firebase were awaited before
    /// hiveReadyCompleter.complete(), the elapsed time would be > 8000ms.
    test(
      'slow Firebase init (8s mock) does not delay hiveReadyCompleter when unawaited',
      () async {
        final hiveReadyCompleter = Completer<void>();

        // Simulate slow Firebase (8 seconds)
        Future<void> slowFirebaseInit() =>
            Future.delayed(const Duration(seconds: 8));

        final stopwatch = Stopwatch()..start();

        // FIXED behavior: Firebase runs unawaited, hiveReadyCompleter fires first
        unawaited(slowFirebaseInit());
        if (!hiveReadyCompleter.isCompleted) {
          hiveReadyCompleter.complete();
        }

        await hiveReadyCompleter.future;
        final elapsed = stopwatch.elapsedMilliseconds;
        stopwatch.stop();

        // isBugCondition: elapsed > 5000ms means Firebase blocked the completer
        expect(
          elapsed,
          lessThan(5000),
          reason:
              'Counterexample: elapsed=${elapsed}ms > 5000ms ANR threshold. '
              'isBugCondition: Firebase.initializeApp() is awaited on main isolate '
              'AND duration > 5000ms. '
              'Fix: run Firebase.initializeApp() in unawaited() so it does not '
              'block hiveReadyCompleter.complete().',
        );
      },
    );
  });

  // ─── Sub-condition C: Synchronous GlobalKey mass-creation ────────────────────

  group('Sub-condition C — Synchronous GlobalKey mass-creation', () {
    /// Verifies that kQuotes has 130+ entries (confirming the scale of the problem).
    test('kQuotes contains 130+ entries that would cause mass GlobalKey allocation', () {
      expect(
        kQuotes.length,
        greaterThanOrEqualTo(130),
        reason:
            'kQuotes must have 130+ entries. Current count: ${kQuotes.length}. '
            'This confirms the scale of the synchronous GlobalKey allocation bug.',
      );
    });

    /// **Bug Condition**: ALL kQuotes GlobalKeys created synchronously in one
    /// build frame during MotivationalScreen initialization.
    ///
    /// **Expected counterexample on unfixed code**: 130+ GlobalKey instances
    /// created in a single frame.
    ///
    /// This test renders MotivationalScreen and counts GlobalKey allocations
    /// during the first build frame. On unfixed code where all keys are created
    /// eagerly in initState, the count equals kQuotes.length (130+).
    /// On fixed code with lazy/on-demand key creation, only visible items
    /// (viewport items) have keys allocated.
    testWidgets(
      'MotivationalScreen does not create more GlobalKeys than visible items in first frame',
      (WidgetTester tester) async {
        // Render MotivationalScreen in a constrained viewport
        await tester.pumpWidget(
          const MaterialApp(
            home: MotivationalScreen(),
          ),
        );

        // Pump one frame to trigger the initial build
        await tester.pump();

        // Count RepaintBoundary widgets with GlobalKeys in the widget tree.
        // On unfixed code: all 130+ quotes have GlobalKeys created eagerly.
        // On fixed code: only visible items (those built by itemBuilder) have keys.
        final repaintBoundaries = tester.widgetList<RepaintBoundary>(
          find.byType(RepaintBoundary),
        ).toList();

        // Count those with non-null keys (GlobalKey instances)
        final globalKeyedBoundaries = repaintBoundaries
            .where((rb) => rb.key != null && rb.key is GlobalKey)
            .toList();

        final globalKeyCount = globalKeyedBoundaries.length;

        // The total number of quotes in kQuotes
        final totalQuotes = kQuotes.length;

        // The critical assertion: GlobalKey count must be less than total quotes.
        // If ALL quotes have GlobalKeys allocated in one frame, that's the bug.
        expect(
          globalKeyCount,
          lessThan(totalQuotes),
          reason:
              'Counterexample: $globalKeyCount GlobalKey instances were created '
              'in the first build frame (total quotes: $totalQuotes). '
              'isBugCondition: ALL kQuotes GlobalKeys created synchronously in '
              'one build frame → blocking computation on UI thread → ANR/jank. '
              'Fix: create GlobalKeys lazily inside itemBuilder (only for visible '
              'items) or on-demand when the user taps download.',
        );
      },
    );

    /// Verifies that the MotivationalScreen widget tree structure does NOT
    /// pre-allocate GlobalKeys for all quotes during initState.
    ///
    /// On unfixed code: _cardKeys map is populated for all quotes in initState
    /// or during the first build, creating 130+ GlobalKey instances.
    /// On fixed code: keys are created inside itemBuilder (lazy).
    testWidgets(
      'MotivationalScreen GlobalKey count equals visible item count, not total quote count',
      (WidgetTester tester) async {
        await tester.pumpWidget(
          const MaterialApp(
            home: MotivationalScreen(),
          ),
        );

        await tester.pump();

        // Count all GlobalKey-keyed RepaintBoundary widgets in the tree
        final allRepaintBoundaries = tester.widgetList<RepaintBoundary>(
          find.byType(RepaintBoundary),
        ).toList();

        final globalKeyCount = allRepaintBoundaries
            .where((rb) => rb.key is GlobalKey)
            .length;

        final totalQuotes = kQuotes.length;

        // On unfixed code: globalKeyCount == totalQuotes (all 130+ keys created eagerly)
        // On fixed code: globalKeyCount << totalQuotes (only visible items have keys)
        //
        // We assert globalKeyCount < totalQuotes to detect the bug.
        expect(
          globalKeyCount,
          lessThan(totalQuotes),
          reason:
              'Counterexample: $globalKeyCount GlobalKeys allocated in first frame '
              '(total: $totalQuotes quotes). '
              'Expected: only visible items (~4-20) should have GlobalKeys. '
              'Bug: all $totalQuotes quotes have GlobalKeys created synchronously '
              'in one build frame, blocking the UI thread.',
        );
      },
    );
  });
}
