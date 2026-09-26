import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mind_care_app/data/models/mood_entry.dart';
import 'package:mind_care_app/data/repositories/mood_repository.dart';
import 'package:mind_care_app/services/analytics/analytics_service.dart';
import 'package:mind_care_app/services/sync/sync_service.dart';
import 'package:uuid/uuid.dart';

// ── Events ────────────────────────────────────────────────────────────────────

abstract class MoodEvent extends Equatable {
  const MoodEvent();

  @override
  List<Object?> get props => [];
}

class MoodSelected extends MoodEvent {
  final int level;
  const MoodSelected(this.level);

  @override
  List<Object?> get props => [level];
}

class NoteChanged extends MoodEvent {
  final String note;
  const NoteChanged(this.note);

  @override
  List<Object?> get props => [note];
}

class MoodSubmitted extends MoodEvent {
  const MoodSubmitted();
}

// ── State ─────────────────────────────────────────────────────────────────────

class MoodState extends Equatable {
  final int? selectedLevel;
  final String note;
  final bool isSubmitting;
  final bool isSubmitted;
  final String? validationError;

  const MoodState({
    this.selectedLevel,
    this.note = '',
    this.isSubmitting = false,
    this.isSubmitted = false,
    this.validationError,
  });

  MoodState copyWith({
    int? selectedLevel,
    bool clearSelectedLevel = false,
    String? note,
    bool? isSubmitting,
    bool? isSubmitted,
    String? validationError,
    bool clearValidationError = false,
  }) {
    return MoodState(
      selectedLevel: clearSelectedLevel
          ? null
          : (selectedLevel ?? this.selectedLevel),
      note: note ?? this.note,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      isSubmitted: isSubmitted ?? this.isSubmitted,
      validationError: clearValidationError
          ? null
          : (validationError ?? this.validationError),
    );
  }

  @override
  List<Object?> get props =>
      [selectedLevel, note, isSubmitting, isSubmitted, validationError];
}

// ── Bloc ──────────────────────────────────────────────────────────────────────

class MoodBloc extends Bloc<MoodEvent, MoodState> {
  final MoodRepository _repository;
  final SyncService? _syncService;
  final AnalyticsService? _analyticsService;

  MoodBloc({
    required MoodRepository repository,
    SyncService? syncService,
    AnalyticsService? analyticsService,
  })  : _repository = repository,
        _syncService = syncService,
        _analyticsService = analyticsService,
        super(const MoodState()) {
    on<MoodSelected>(_onMoodSelected);
    on<NoteChanged>(_onNoteChanged);
    on<MoodSubmitted>(_onMoodSubmitted);
  }

  void _onMoodSelected(MoodSelected event, Emitter<MoodState> emit) {
    emit(state.copyWith(
      selectedLevel: event.level,
      clearValidationError: true,
    ));
  }

  void _onNoteChanged(NoteChanged event, Emitter<MoodState> emit) {
    final truncated = event.note.length > 200
        ? event.note.substring(0, 200)
        : event.note;
    emit(state.copyWith(note: truncated));
  }

  Future<void> _onMoodSubmitted(
    MoodSubmitted event,
    Emitter<MoodState> emit,
  ) async {
    if (state.selectedLevel == null) {
      emit(state.copyWith(validationError: 'Please select a mood level'));
      return;
    }

    emit(state.copyWith(isSubmitting: true, clearValidationError: true));

    final entry = MoodEntry(
      id: const Uuid().v4(),
      mood: MoodEntry.mapLevelToMoodType(state.selectedLevel!),
      levelValue: state.selectedLevel!,
      note: state.note.isEmpty ? null : state.note,
      timestamp: DateTime.now(),
    );

    await _repository.saveMoodEntry(entry);
    await _syncService?.enqueueMoodEntry(entry);
    await _analyticsService?.logEvent(
      'mood_logged',
      parameters: {'level': entry.level},
    );

    emit(state.copyWith(isSubmitting: false, isSubmitted: true));
  }
}
