import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../../data/models/journal_entry.dart';
import '../../../data/repositories/journal_repository.dart';
import '../../../services/analytics/analytics_service.dart';
import '../../../services/sync/sync_service.dart';
import '../../../services/remote_config/remote_config_service.dart';

// Events
abstract class JournalEvent extends Equatable {
  const JournalEvent();
  @override
  List<Object?> get props => [];
}

class LoadEntries extends JournalEvent {
  const LoadEntries();
}

class SaveEntry extends JournalEvent {
  final JournalEntry entry;
  const SaveEntry(this.entry);
  @override
  List<Object?> get props => [entry];
}

class DeleteEntry extends JournalEvent {
  final String id;
  const DeleteEntry(this.id);
  @override
  List<Object?> get props => [id];
}

class EntryBodyChanged extends JournalEvent {
  final String body;
  const EntryBodyChanged(this.body);
  @override
  List<Object?> get props => [body];
}

// State
class JournalState extends Equatable {
  final List<JournalEntry> entries;
  final bool isLoading;
  final bool isSaved;
  final bool isDeleted;
  final String? validationError;
  final int wordCount;

  const JournalState({
    this.entries = const [],
    this.isLoading = false,
    this.isSaved = false,
    this.isDeleted = false,
    this.validationError,
    this.wordCount = 0,
  });

  JournalState copyWith({
    List<JournalEntry>? entries,
    bool? isLoading,
    bool? isSaved,
    bool? isDeleted,
    String? validationError,
    bool clearValidationError = false,
    int? wordCount,
  }) {
    return JournalState(
      entries: entries ?? this.entries,
      isLoading: isLoading ?? this.isLoading,
      isSaved: isSaved ?? this.isSaved,
      isDeleted: isDeleted ?? this.isDeleted,
      validationError: clearValidationError ? null : (validationError ?? this.validationError),
      wordCount: wordCount ?? this.wordCount,
    );
  }

  @override
  List<Object?> get props => [entries, isLoading, isSaved, isDeleted, validationError, wordCount];
}

// Bloc
class JournalBloc extends Bloc<JournalEvent, JournalState> {
  final JournalRepository repository;
  final SyncService? syncService;
  final RemoteConfigService? remoteConfigService;
  final AnalyticsService? analyticsService;

  JournalBloc({
    required this.repository,
    this.syncService,
    this.remoteConfigService,
    this.analyticsService,
  }) : super(const JournalState()) {
    on<LoadEntries>(_onLoadEntries);
    on<SaveEntry>(_onSaveEntry);
    on<DeleteEntry>(_onDeleteEntry);
    on<EntryBodyChanged>(_onEntryBodyChanged);
  }

  Future<void> _onLoadEntries(LoadEntries event, Emitter<JournalState> emit) async {
    emit(state.copyWith(isLoading: true));
    final entries = await repository.getAllEntries();
    emit(state.copyWith(isLoading: false, entries: entries));
  }

  Future<void> _onSaveEntry(SaveEntry event, Emitter<JournalState> emit) async {
    if (event.entry.body.trim().isEmpty) {
      emit(state.copyWith(validationError: 'Journal body cannot be empty.'));
      return;
    }

    // Enforce max_journal_entries limit from RemoteConfig
    if (remoteConfigService != null) {
      final maxEntries = remoteConfigService!.getInt('max_journal_entries');
      final currentCount = state.entries.length;
      if (currentCount >= maxEntries) {
        emit(state.copyWith(
          validationError:
              'You have reached the maximum of $maxEntries journal entries. '
              'Please delete some entries before adding new ones.',
        ));
        return;
      }
    }

    await repository.saveEntry(event.entry);
    await syncService?.enqueueJournalEntry(event.entry);
    final isNew = !state.entries.any((e) => e.id == event.entry.id);
    if (isNew) {
      await analyticsService?.logEvent('journal_entry_created');
    }
    final entries = await repository.getAllEntries();
    emit(state.copyWith(
      entries: entries,
      isSaved: true,
      clearValidationError: true,
    ));
  }

  Future<void> _onDeleteEntry(DeleteEntry event, Emitter<JournalState> emit) async {
    await repository.deleteEntry(event.id);
    final entries = await repository.getAllEntries();
    emit(state.copyWith(entries: entries, isDeleted: true));
  }

  void _onEntryBodyChanged(EntryBodyChanged event, Emitter<JournalState> emit) {
    final words = event.body.trim().isEmpty
        ? 0
        : event.body.trim().split(RegExp(r'\s+')).where((w) => w.isNotEmpty).length;
    emit(state.copyWith(wordCount: words));
  }
}
