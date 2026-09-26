import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:mind_care_app/core/widgets/leaf_background.dart';
import 'package:mind_care_app/data/models/mood_entry.dart';
import 'package:mind_care_app/features/mood/bloc/mood_bloc.dart';

class MoodTrackerScreen extends StatelessWidget {
  const MoodTrackerScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocListener<MoodBloc, MoodState>(
      listenWhen: (prev, curr) => curr.isSubmitted && !prev.isSubmitted,
      listener: (context, state) {
        if (state.isSubmitted) {
          context.pop();
        }
      },
      child: Scaffold(
        body: LeafBackground(
          child: SafeArea(
            child: Column(
              children: [
                _AppBar(),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'How are you feeling?',
                          style: Theme.of(context)
                              .textTheme
                              .headlineSmall
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Select the mood that best describes you right now.',
                          style: Theme.of(context)
                              .textTheme
                              .bodyMedium
                              ?.copyWith(
                                color: Theme.of(context)
                                    .colorScheme
                                    .onSurface
                                    .withOpacity(0.6),
                              ),
                        ),
                        const SizedBox(height: 24),
                        const _MoodGrid(),
                        const SizedBox(height: 8),
                        const _ValidationError(),
                        const SizedBox(height: 20),
                        const _NoteInput(),
                        const SizedBox(height: 28),
                        const _SubmitButton(),
                        const SizedBox(height: 16),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ── App bar ───────────────────────────────────────────────────────────────────

class _AppBar extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back_rounded),
            onPressed: () => context.pop(),
          ),
          Text(
            'Mood Tracker',
            style: Theme.of(context)
                .textTheme
                .titleLarge
                ?.copyWith(fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}

// ── Mood option data ──────────────────────────────────────────────────────────

class _MoodOption {
  final MoodType type;
  final String emoji;
  final String label;

  const _MoodOption(this.type, this.emoji, this.label);
}

const _moodOptions = [
  _MoodOption(MoodType.happy, '😊', 'Happy'),
  _MoodOption(MoodType.sad, '😔', 'Sad'),
  _MoodOption(MoodType.anxious, '😰', 'Anxious'),
  _MoodOption(MoodType.frustrated, '😤', 'Frustrated'),
  _MoodOption(MoodType.calm, '😌', 'Calm'),
  _MoodOption(MoodType.excited, '🤩', 'Excited'),
  _MoodOption(MoodType.tired, '😴', 'Tired'),
];

// ── Mood level selector ───────────────────────────────────────────────────────

class _MoodGrid extends StatelessWidget {
  const _MoodGrid();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<MoodBloc, MoodState>(
      buildWhen: (prev, curr) => prev.selectedLevel != curr.selectedLevel,
      builder: (context, state) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: List.generate(10, (index) {
                final level = index + 1;
                final isSelected = state.selectedLevel == level;
                return _MoodLevelCard(
                  level: level,
                  isSelected: isSelected,
                  onTap: () =>
                      context.read<MoodBloc>().add(MoodSelected(level)),
                );
              }),
            ),
            const SizedBox(height: 16),
            if (state.selectedLevel != null)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: _getLevelColor(state.selectedLevel!).withOpacity(0.12),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: _getLevelColor(state.selectedLevel!).withOpacity(0.4),
                  ),
                ),
                child: Row(
                  children: [
                    Text(
                      _getLevelEmoji(state.selectedLevel!),
                      style: const TextStyle(fontSize: 24),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Level ${state.selectedLevel} - ${_getLevelLabel(state.selectedLevel!)}',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: _getLevelColor(state.selectedLevel!),
                            ),
                          ),
                          Text(
                            _getLevelDesc(state.selectedLevel!),
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
          ],
        );
      },
    );
  }
}

class _MoodLevelCard extends StatelessWidget {
  final int level;
  final bool isSelected;
  final VoidCallback onTap;

  const _MoodLevelCard({
    required this.level,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = _getLevelColor(level);
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: (MediaQuery.of(context).size.width - 40 - 8 * 4) / 5,
        height: 52,
        decoration: BoxDecoration(
          color: isSelected ? color : color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? color : color.withOpacity(0.3),
            width: isSelected ? 2 : 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: color.withOpacity(0.4),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  )
                ]
              : [],
        ),
        child: Center(
          child: Text(
            level.toString(),
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: isSelected ? Colors.white : color,
            ),
          ),
        ),
      ),
    );
  }
}

Color _getLevelColor(int level) {
  if (level <= 2) return const Color(0xFFD32F2F); // Red
  if (level <= 4) return const Color(0xFFF57C00); // Orange
  if (level <= 6) return const Color(0xFFFBC02D); // Yellow
  if (level <= 8) return const Color(0xFF4CAF50); // Light Green
  return const Color(0xFF00796B); // Teal
}

String _getLevelEmoji(int level) {
  if (level <= 2) return '😭';
  if (level <= 4) return '😔';
  if (level <= 6) return '😌';
  if (level <= 8) return '😊';
  return '🤩';
}

String _getLevelLabel(int level) {
  if (level <= 2) return 'Very Low';
  if (level <= 4) return 'Low';
  if (level <= 6) return 'Neutral / Calm';
  if (level <= 8) return 'Good';
  return 'Excellent!';
}

String _getLevelDesc(int level) {
  if (level <= 2) return 'Feeling down, overwhelmed, or sad.';
  if (level <= 4) return 'A bit anxious, tired, or frustrated.';
  if (level <= 6) return 'Peaceful, stable, and balanced.';
  if (level <= 8) return 'Cheerful, optimistic, and happy.';
  return 'Thriving, excited, and full of positive energy!';
}

// ── Validation error ──────────────────────────────────────────────────────────

class _ValidationError extends StatelessWidget {
  const _ValidationError();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<MoodBloc, MoodState>(
      buildWhen: (prev, curr) => prev.validationError != curr.validationError,
      builder: (context, state) {
        if (state.validationError == null) return const SizedBox.shrink();
        return Padding(
          padding: const EdgeInsets.only(top: 8),
          child: Row(
            children: [
              Icon(Icons.error_outline,
                  size: 16, color: Theme.of(context).colorScheme.error),
              const SizedBox(width: 6),
              Text(
                state.validationError!,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.error,
                    ),
              ),
            ],
          ),
        );
      },
    );
  }
}

// ── Note input ────────────────────────────────────────────────────────────────

class _NoteInput extends StatefulWidget {
  const _NoteInput();

  @override
  State<_NoteInput> createState() => _NoteInputState();
}

class _NoteInputState extends State<_NoteInput> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<MoodBloc, MoodState>(
      buildWhen: (prev, curr) => prev.note != curr.note,
      builder: (context, state) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Add a note (optional)',
              style: Theme.of(context)
                  .textTheme
                  .titleSmall
                  ?.copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _controller,
              maxLines: 4,
              maxLength: 200,
              onChanged: (val) =>
                  context.read<MoodBloc>().add(NoteChanged(val)),
              decoration: InputDecoration(
                hintText: 'What\'s on your mind?',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: Theme.of(context)
                        .colorScheme
                        .primary
                        .withOpacity(0.3),
                  ),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: Theme.of(context)
                        .colorScheme
                        .primary
                        .withOpacity(0.3),
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: Theme.of(context).colorScheme.primary,
                    width: 2,
                  ),
                ),
                counterText: '${state.note.length}/200',
              ),
            ),
          ],
        );
      },
    );
  }
}

// ── Submit button ─────────────────────────────────────────────────────────────

class _SubmitButton extends StatelessWidget {
  const _SubmitButton();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<MoodBloc, MoodState>(
      buildWhen: (prev, curr) => prev.isSubmitting != curr.isSubmitting,
      builder: (context, state) {
        return SizedBox(
          width: double.infinity,
          child: FilledButton(
            onPressed: state.isSubmitting
                ? null
                : () =>
                    context.read<MoodBloc>().add(const MoodSubmitted()),
            style: FilledButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            child: state.isSubmitting
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text(
                    'Log Mood',
                    style: TextStyle(
                        fontSize: 16, fontWeight: FontWeight.w600),
                  ),
          ),
        );
      },
    );
  }
}
