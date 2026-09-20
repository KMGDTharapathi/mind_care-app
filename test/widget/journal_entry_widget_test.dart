import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:mind_care_app/data/models/journal_entry.dart';
import 'package:mind_care_app/data/repositories/journal_repository.dart';
import 'package:mind_care_app/features/journal/bloc/journal_bloc.dart';
import 'package:mind_care_app/features/journal/screens/journal_entry_screen.dart';

// ── Mock ──────────────────────────────────────────────────────────────────────

class MockJournalRepository extends Mock implements JournalRepository {}

// ── Helpers ───────────────────────────────────────────────────────────────────

Widget buildJournalEntryScreen(
  JournalRepository repository, {
  String? entryId,
}) {
  return MaterialApp(
    home: BlocProvider(
      create: (_) => JournalBloc(repository: repository),
      child: JournalEntryScreen(entryId: entryId),
    ),
  );
}

void main() {
  late MockJournalRepository mockRepository;

  setUp(() {
    mockRepository = MockJournalRepository();
  });

  setUpAll(() {
    registerFallbackValue(
      JournalEntry(
        id: 'fallback',
        title: 'Fallback',
        body: 'Fallback body',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
    );
  });

  group('JournalEntryScreen widget tests', () {
    testWidgets('word count updates as user types', (tester) async {
      await tester.pumpWidget(buildJournalEntryScreen(mockRepository));
      await tester.pump();

      // Initially 0 words
      expect(find.text('0 words'), findsOneWidget);

      // Type some text in the body field
      await tester.enterText(
        find.byWidgetPredicate(
          (w) =>
              w is TextField &&
              (w.decoration?.hintText == 'Write your thoughts...'),
        ),
        'Hello world test',
      );
      await tester.pump();

      // Should show 3 words
      expect(find.text('3 words'), findsOneWidget);
    });

    testWidgets('saving with empty body shows validation error snackbar',
        (tester) async {
      await tester.pumpWidget(buildJournalEntryScreen(mockRepository));
      await tester.pump();

      // Tap save (check icon) without entering body
      await tester.tap(find.byIcon(Icons.check));
      await tester.pump();

      // Snackbar with validation error should appear
      expect(find.text('Journal body cannot be empty.'), findsOneWidget);
    });

    testWidgets('delete button shows confirmation dialog for existing entry',
        (tester) async {
      // Set up mock for loading entries
      final existingEntry = JournalEntry(
        id: 'entry-1',
        title: 'My Entry',
        body: 'Some body text',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      when(() => mockRepository.getAllEntries())
          .thenAnswer((_) async => [existingEntry]);

      await tester.pumpWidget(
        buildJournalEntryScreen(mockRepository, entryId: 'entry-1'),
      );
      await tester.pump();
      await tester.pump(); // allow BLoC to emit

      // Delete icon should be visible for existing entry
      expect(find.byIcon(Icons.delete_outline), findsOneWidget);

      // Tap delete
      await tester.tap(find.byIcon(Icons.delete_outline));
      await tester.pumpAndSettle();

      // Confirmation dialog should appear
      expect(find.text('Delete Entry'), findsOneWidget);
      expect(
        find.text('Are you sure you want to permanently delete this entry?'),
        findsOneWidget,
      );
      expect(find.text('Cancel'), findsOneWidget);
      expect(find.text('Delete'), findsOneWidget);
    });

    testWidgets('cancelling delete dialog does not delete entry', (tester) async {
      final existingEntry = JournalEntry(
        id: 'entry-2',
        title: 'Keep Me',
        body: 'Do not delete',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      when(() => mockRepository.getAllEntries())
          .thenAnswer((_) async => [existingEntry]);

      await tester.pumpWidget(
        buildJournalEntryScreen(mockRepository, entryId: 'entry-2'),
      );
      await tester.pump();
      await tester.pump();

      await tester.tap(find.byIcon(Icons.delete_outline));
      await tester.pumpAndSettle();

      // Tap Cancel
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();

      // deleteEntry should NOT have been called
      verifyNever(() => mockRepository.deleteEntry(any()));
    });
  });
}
