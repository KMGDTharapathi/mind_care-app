import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mind_care_app/data/models/breathing_pattern.dart';
import 'package:mind_care_app/services/analytics/analytics_service.dart';

// ── Events ────────────────────────────────────────────────────────────────────

abstract class BreathingEvent {}

class StartSession extends BreathingEvent {
  final BreathingPattern pattern;
  StartSession(this.pattern);
}

class Tick extends BreathingEvent {}

class PauseSession extends BreathingEvent {}

class ResumeSession extends BreathingEvent {}

class CompleteSession extends BreathingEvent {}

class ResetSession extends BreathingEvent {}

// ── State ─────────────────────────────────────────────────────────────────────

class BreathingState {
  final BreathingPattern? pattern;
  final int currentPhaseIndex;
  final int secondsRemaining;
  final bool isRunning;
  final bool isCompleted;
  final int currentCycle;
  final int totalCycles;

  const BreathingState({
    this.pattern,
    this.currentPhaseIndex = 0,
    this.secondsRemaining = 0,
    this.isRunning = false,
    this.isCompleted = false,
    this.currentCycle = 1,
    this.totalCycles = 3,
  });

  BreathingState copyWith({
    BreathingPattern? pattern,
    int? currentPhaseIndex,
    int? secondsRemaining,
    bool? isRunning,
    bool? isCompleted,
    int? currentCycle,
    int? totalCycles,
  }) {
    return BreathingState(
      pattern: pattern ?? this.pattern,
      currentPhaseIndex: currentPhaseIndex ?? this.currentPhaseIndex,
      secondsRemaining: secondsRemaining ?? this.secondsRemaining,
      isRunning: isRunning ?? this.isRunning,
      isCompleted: isCompleted ?? this.isCompleted,
      currentCycle: currentCycle ?? this.currentCycle,
      totalCycles: totalCycles ?? this.totalCycles,
    );
  }
}

// ── Bloc ──────────────────────────────────────────────────────────────────────

class BreathingBloc extends Bloc<BreathingEvent, BreathingState> {
  Timer? _timer;
  final AnalyticsService? analyticsService;

  BreathingBloc({this.analyticsService}) : super(const BreathingState()) {
    on<StartSession>(_onStartSession);
    on<Tick>(_onTick);
    on<PauseSession>(_onPauseSession);
    on<ResumeSession>(_onResumeSession);
    on<CompleteSession>(_onCompleteSession);
    on<ResetSession>(_onResetSession);
  }

  void _cancelTimer() {
    _timer?.cancel();
    _timer = null;
  }

  void _startTimer() {
    _cancelTimer();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) => add(Tick()));
  }

  void _onStartSession(StartSession event, Emitter<BreathingState> emit) {
    _cancelTimer();
    final pattern = event.pattern;
    emit(BreathingState(
      pattern: pattern,
      currentPhaseIndex: 0,
      secondsRemaining: pattern.phases[0].durationSeconds,
      isRunning: true,
      isCompleted: false,
      currentCycle: 1,
      totalCycles: 3,
    ));
    _startTimer();
  }

  void _onTick(Tick event, Emitter<BreathingState> emit) {
    final s = state;
    if (!s.isRunning || s.pattern == null) return;

    final newSeconds = s.secondsRemaining - 1;

    if (newSeconds > 0) {
      emit(s.copyWith(secondsRemaining: newSeconds));
      return;
    }

    // Phase complete — advance
    final phases = s.pattern!.phases;
    final nextPhaseIndex = s.currentPhaseIndex + 1;

    if (nextPhaseIndex < phases.length) {
      // Move to next phase in same cycle
      emit(s.copyWith(
        currentPhaseIndex: nextPhaseIndex,
        secondsRemaining: phases[nextPhaseIndex].durationSeconds,
      ));
    } else {
      // All phases done — check cycle
      final nextCycle = s.currentCycle + 1;
      if (nextCycle > s.totalCycles) {
        // Session complete
        _cancelTimer();
        emit(s.copyWith(
          secondsRemaining: 0,
          isRunning: false,
          isCompleted: true,
        ));
        analyticsService?.logEvent(
          'breathing_session_completed',
          parameters: {'pattern': s.pattern!.id},
        );
      } else {
        // Start next cycle from phase 0
        emit(s.copyWith(
          currentPhaseIndex: 0,
          secondsRemaining: phases[0].durationSeconds,
          currentCycle: nextCycle,
        ));
      }
    }
  }

  void _onPauseSession(PauseSession event, Emitter<BreathingState> emit) {
    if (!state.isRunning || state.isCompleted) return;
    _cancelTimer();
    emit(state.copyWith(isRunning: false));
  }

  void _onResumeSession(ResumeSession event, Emitter<BreathingState> emit) {
    if (state.isRunning || state.isCompleted || state.pattern == null) return;
    emit(state.copyWith(isRunning: true));
    _startTimer();
  }

  void _onCompleteSession(CompleteSession event, Emitter<BreathingState> emit) {
    _cancelTimer();
    emit(state.copyWith(isRunning: false, isCompleted: true));
    analyticsService?.logEvent(
      'breathing_session_completed',
      parameters: {'pattern': state.pattern?.id ?? ''},
    );
  }

  void _onResetSession(ResetSession event, Emitter<BreathingState> emit) {
    _cancelTimer();
    emit(const BreathingState());
  }

  @override
  Future<void> close() {
    _cancelTimer();
    return super.close();
  }
}
