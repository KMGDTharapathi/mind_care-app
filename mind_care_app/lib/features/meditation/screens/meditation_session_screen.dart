import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:mind_care_app/core/l10n/language_provider.dart';
import 'meditation_list_screen.dart';

class MeditationSessionScreen extends StatefulWidget {
  final MeditationData meditation;
  const MeditationSessionScreen({super.key, required this.meditation});

  @override
  State<MeditationSessionScreen> createState() =>
      _MeditationSessionScreenState();
}

class _MeditationSessionScreenState extends State<MeditationSessionScreen>
    with SingleTickerProviderStateMixin {
  int _stepIndex = 0;
  bool _showIntro = true;
  bool _finished = false;

  // ValueNotifiers — only subscribed widgets rebuild, not the whole screen
  final ValueNotifier<int> _secondsLeft = ValueNotifier(0);
  final ValueNotifier<bool> _running = ValueNotifier(false);

  Timer? _timer;

  late AnimationController _slideCtrl;
  late Animation<Offset> _slideAnim;

  MeditationStep get _step => widget.meditation.steps[_stepIndex];
  int get _totalSteps => widget.meditation.steps.length;

  @override
  void initState() {
    super.initState();
    _slideCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
    );
    _slideAnim = Tween<Offset>(
      begin: const Offset(0.25, 0),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _slideCtrl, curve: Curves.easeOut));
    _loadStep();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _slideCtrl.dispose();
    _secondsLeft.dispose();
    _running.dispose();
    super.dispose();
  }

  void _loadStep() {
    _timer?.cancel();
    _secondsLeft.value = _step.durationSeconds;
    _running.value = false;
    _slideCtrl.forward(from: 0);
  }

  void _startTimer() {
    _running.value = true;
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (_secondsLeft.value <= 1) {
        t.cancel();
        _secondsLeft.value = 0;
        _running.value = false;
      } else {
        _secondsLeft.value--;
      }
    });
  }

  void _pauseTimer() {
    _timer?.cancel();
    _running.value = false;
  }

  void _nextStep() {
    _timer?.cancel();
    _running.value = false;
    if (_stepIndex < _totalSteps - 1) {
      setState(() => _stepIndex++);
      _loadStep();
    } else {
      setState(() => _finished = true);
    }
  }

  void _prevStep() {
    if (_stepIndex > 0) {
      _timer?.cancel();
      _running.value = false;
      setState(() => _stepIndex--);
      _loadStep();
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = LanguageProvider.of(context);
    if (_showIntro) return _buildIntro(s);
    if (_finished) return _buildFinished(s);
    return _buildSession(s);
  }

  // ── Intro ──────────────────────────────────────────────────────────────────
  Widget _buildIntro(dynamic s) {
    final m = widget.meditation;
    final grad = m.gradient;
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [grad[0], grad[2]],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(8, 8, 16, 0),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(
                        Icons.arrow_back_ios_new_rounded,
                        color: Colors.white70,
                      ),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                    Expanded(
                      child: Column(
                        children: [
                          Text(
                            m.name,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          Text(
                            m.pali,
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.white.withValues(alpha: 0.7),
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 48),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 14),
                child: Text(m.emoji, style: const TextStyle(fontSize: 60)),
              ),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _sectionHeader(
                        '🛠️ ${s.techniques}',
                        s.howYouWillPractice,
                      ),
                      const SizedBox(height: 8),
                      ...m
                          .localTechniques(s.isSinhala)
                          .map(
                            (t) => _infoRow(
                              t,
                              Colors.white.withValues(alpha: 0.15),
                            ),
                          ),
                      const SizedBox(height: 16),
                      _sectionHeader('🎯 ${s.goals}', s.whatYouWillAchieve),
                      const SizedBox(height: 8),
                      ...m
                          .localGoals(s.isSinhala)
                          .map(
                            (g) => _infoRow(
                              g,
                              Colors.white.withValues(alpha: 0.1),
                            ),
                          ),
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            _miniStat('⏱️', m.duration, s.duration),
                            _miniStat('📋', '${m.steps.length}', s.steps),
                            _miniStat('📊', m.level, s.level),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => setState(() => _showIntro = false),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: grad[1],
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      elevation: 0,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          LanguageProvider.of(context).beginMeditation,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Icon(Icons.play_arrow_rounded, size: 22),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Session ────────────────────────────────────────────────────────────────
  Widget _buildSession(dynamic s) {
    final step = _step;
    final grad = widget.meditation.gradient;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [grad[0], grad[2]],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Top bar — only rebuilds on step change (setState)
              Padding(
                padding: const EdgeInsets.fromLTRB(8, 8, 16, 0),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(
                        Icons.close_rounded,
                        color: Colors.white70,
                      ),
                      onPressed: _showExitDialog,
                    ),
                    Expanded(
                      child: Column(
                        children: [
                          Text(
                            widget.meditation.name,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          Text(
                            widget.meditation.pali,
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.white.withValues(alpha: 0.7),
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '${_stepIndex + 1} / $_totalSteps',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              // Step progress bar
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 10, 20, 0),
                child: Row(
                  children: List.generate(
                    _totalSteps,
                    (i) => Expanded(
                      child: Container(
                        height: i == _stepIndex ? 6 : 4,
                        margin: const EdgeInsets.symmetric(horizontal: 2),
                        decoration: BoxDecoration(
                          color: i < _stepIndex
                              ? Colors.white
                              : i == _stepIndex
                              ? Colors.white.withValues(alpha: 0.9)
                              : Colors.white.withValues(alpha: 0.3),
                          borderRadius: BorderRadius.circular(3),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              // Step content — static, only rebuilds on step change
              Expanded(
                child: SlideTransition(
                  position: _slideAnim,
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
                    child: Column(
                      children: [
                        // Emoji circle — static, no animation
                        Container(
                          width: 130,
                          height: 130,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white.withValues(alpha: 0.2),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.white.withValues(alpha: 0.25),
                                blurRadius: 24,
                                spreadRadius: 4,
                              ),
                            ],
                          ),
                          child: Center(
                            child: Text(
                              step.emoji,
                              style: const TextStyle(fontSize: 68),
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            '${s.stepLabel} ${_stepIndex + 1}: ${step.localTitle(s.isSinhala)}',
                            style: const TextStyle(
                              fontSize: 13,
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(18),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.18),
                            borderRadius: BorderRadius.circular(22),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.3),
                              width: 1.5,
                            ),
                          ),
                          child: Text(
                            step.localInstruction(s.isSinhala),
                            style: const TextStyle(
                              fontSize: 15,
                              color: Colors.white,
                              height: 1.7,
                              fontWeight: FontWeight.w500,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                        const SizedBox(height: 22),
                        // ── Isolated timer widget — ONLY this rebuilds every second ──
                        _TimerCircle(
                          secondsLeft: _secondsLeft,
                          running: _running,
                          totalSeconds: step.durationSeconds,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              // Controls — only rebuilds on step change
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 12, 24, 0),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _circleBtn(
                          Icons.skip_previous_rounded,
                          28,
                          _stepIndex > 0 ? _prevStep : null,
                          opacity: _stepIndex > 0 ? 1.0 : 0.3,
                        ),
                        const SizedBox(width: 20),
                        // Play/pause — only this rebuilds on running change
                        ValueListenableBuilder<bool>(
                          valueListenable: _running,
                          builder: (_, running, _) => GestureDetector(
                            onTap: running ? _pauseTimer : _startTimer,
                            child: Container(
                              width: 70,
                              height: 70,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.white,
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.18),
                                    blurRadius: 14,
                                    spreadRadius: 2,
                                  ),
                                ],
                              ),
                              child: Icon(
                                running
                                    ? Icons.pause_rounded
                                    : Icons.play_arrow_rounded,
                                size: 38,
                                color: step.color,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 20),
                        _circleBtn(Icons.skip_next_rounded, 28, _nextStep),
                      ],
                    ),
                    const SizedBox(height: 10),
                    TextButton(
                      onPressed: _nextStep,
                      child: Text(
                        _stepIndex < _totalSteps - 1
                            ? LanguageProvider.of(context).skipStep
                            : LanguageProvider.of(context).complete,
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.8),
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }

  // ── Finished ───────────────────────────────────────────────────────────────
  Widget _buildFinished(dynamic s) {
    final grad = widget.meditation.gradient;
    final m = widget.meditation;
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [grad[0], grad[2]],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(28),
            child: Column(
              children: [
                const SizedBox(height: 16),
                const Text('🙏', style: TextStyle(fontSize: 72)),
                const SizedBox(height: 16),
                Text(
                  LanguageProvider.of(context).wellDone,
                  style: const TextStyle(
                    fontSize: 30,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  s.isSinhala
                      ? '${s.youCompleted}\n${m.name}'
                      : '${s.youCompleted}\n${m.name}',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 17,
                    color: Colors.white.withValues(alpha: 0.9),
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  m.pali,
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.white.withValues(alpha: 0.7),
                    fontStyle: FontStyle.italic,
                  ),
                ),
                const SizedBox(height: 24),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _stat('⏱️', m.duration, s.duration),
                      _stat('📋', '$_totalSteps', s.steps),
                      _stat('🌟', m.level, s.level),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    LanguageProvider.of(context).goalsAchieved,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                ...m
                    .localGoals(s.isSinhala)
                    .map(
                      (g) => Container(
                        margin: const EdgeInsets.only(bottom: 7),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 9,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            const Text('✨', style: TextStyle(fontSize: 14)),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                g.replaceFirst('✅ ', ''),
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Colors.white,
                                  height: 1.4,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: grad[1],
                      padding: const EdgeInsets.symmetric(vertical: 15),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      elevation: 0,
                    ),
                    child: Text(
                      LanguageProvider.of(context).backToMeditations,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                TextButton(
                  onPressed: () {
                    setState(() {
                      _stepIndex = 0;
                      _finished = false;
                      _showIntro = true;
                    });
                    _loadStep();
                  },
                  child: Text(
                    LanguageProvider.of(context).practiceAgain,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.8),
                      fontSize: 14,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ── Helpers ────────────────────────────────────────────────────────────────
  Widget _circleBtn(
    IconData icon,
    double size,
    VoidCallback? onTap, {
    double opacity = 1.0,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Opacity(
        opacity: opacity,
        child: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white.withValues(alpha: 0.2),
          ),
          child: Icon(icon, size: size, color: Colors.white),
        ),
      ),
    );
  }

  Widget _sectionHeader(String title, String subtitle) => Row(
    children: [
      Text(
        title,
        style: const TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),
      const SizedBox(width: 8),
      Text(
        subtitle,
        style: TextStyle(
          fontSize: 11,
          color: Colors.white.withValues(alpha: 0.6),
        ),
      ),
    ],
  );

  Widget _infoRow(String text, Color bg) => Container(
    margin: const EdgeInsets.only(bottom: 8),
    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
    decoration: BoxDecoration(
      color: bg,
      borderRadius: BorderRadius.circular(12),
    ),
    child: Text(
      text,
      style: const TextStyle(fontSize: 13, color: Colors.white, height: 1.4),
    ),
  );

  Widget _miniStat(String emoji, String value, String label) => Column(
    children: [
      Text(emoji, style: const TextStyle(fontSize: 20)),
      const SizedBox(height: 2),
      Text(
        value,
        style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),
      Text(
        label,
        style: TextStyle(
          fontSize: 10,
          color: Colors.white.withValues(alpha: 0.7),
        ),
      ),
    ],
  );

  Widget _stat(String emoji, String value, String label) => Column(
    children: [
      Text(emoji, style: const TextStyle(fontSize: 22)),
      const SizedBox(height: 3),
      Text(
        value,
        style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),
      Text(
        label,
        style: TextStyle(
          fontSize: 10,
          color: Colors.white.withValues(alpha: 0.7),
        ),
      ),
    ],
  );

  void _showExitDialog() {
    _pauseTimer();
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(LanguageProvider.of(context).leaveMeditation),
        content: Text(LanguageProvider.of(context).progressWillBeLost),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              LanguageProvider.of(context).stay,
              style: const TextStyle(color: Color(0xFF5BA8A0)),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context);
            },
            child: Text(
              LanguageProvider.of(context).leave,
              style: const TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  ISOLATED TIMER WIDGET — only this rebuilds every second
// ─────────────────────────────────────────────────────────────────────────────
class _TimerCircle extends StatelessWidget {
  final ValueNotifier<int> secondsLeft;
  final ValueNotifier<bool> running;
  final int totalSeconds;

  const _TimerCircle({
    required this.secondsLeft,
    required this.running,
    required this.totalSeconds,
  });

  String _fmt(int s) {
    final m = (s ~/ 60).toString().padLeft(2, '0');
    final sec = (s % 60).toString().padLeft(2, '0');
    return '$m:$sec';
  }

  @override
  Widget build(BuildContext context) {
    final s = LanguageProvider.of(context);
    // Only this widget rebuilds on every tick
    return ValueListenableBuilder2<int, bool>(
      first: secondsLeft,
      second: running,
      builder: (_, secs, isRunning, _) {
        final progress = totalSeconds > 0 ? 1.0 - (secs / totalSeconds) : 1.0;
        final label = isRunning
            ? s.remaining
            : secs == totalSeconds
            ? s.ready
            : s.paused;
        return SizedBox(
          width: 108,
          height: 108,
          child: Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                width: 108,
                height: 108,
                child: CircularProgressIndicator(
                  value: progress,
                  strokeWidth: 7,
                  backgroundColor: Colors.white.withValues(alpha: 0.2),
                  valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              ),
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    _fmt(secs),
                    style: const TextStyle(
                      fontSize: 25,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 10,
                      color: Colors.white.withValues(alpha: 0.8),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  ValueListenableBuilder2 helper (listens to two notifiers)
// ─────────────────────────────────────────────────────────────────────────────
class ValueListenableBuilder2<A, B> extends StatelessWidget {
  final ValueListenable<A> first;
  final ValueListenable<B> second;
  final Widget Function(BuildContext, A, B, Widget?) builder;
  final Widget? child;

  const ValueListenableBuilder2({
    super.key,
    required this.first,
    required this.second,
    required this.builder,
    this.child,
  });

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<A>(
      valueListenable: first,
      builder: (ctx, a, _) => ValueListenableBuilder<B>(
        valueListenable: second,
        builder: (ctx2, b, _) => builder(ctx2, a, b, child),
      ),
    );
  }
}
