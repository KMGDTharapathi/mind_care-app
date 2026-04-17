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

// ── Mood grid ─────────────────────────────────────────────────────────────────

class _MoodGrid extends StatelessWidget {
  const _MoodGrid();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<MoodBloc, MoodState>(
      buildWhen: (prev, curr) => prev.selectedMood != curr.selectedMood,
      builder: (context, state) {
        return Wrap(
          spacing: 12,
          runSpacing: 12,
          children: _moodOptions
              .map((opt) => _MoodOptionCard(
                    option: opt,
                    isSelected: state.selectedMood == opt.type,
                    onTap: () =>
                        context.read<MoodBloc>().add(MoodSelected(opt.type)),
                  ))
              .toList(),
        );
      },
    );
  }
}

class _MoodOptionCard extends StatelessWidget {
  final _MoodOption option;
  final bool isSelected;
  final VoidCallback onTap;

  const _MoodOptionCard({
    required this.option,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: (MediaQuery.of(context).size.width - 40 - 12 * 2) / 3,
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: isSelected
              ? colorScheme.primary.withOpacity(0.15)
              : colorScheme.primaryContainer.withOpacity(0.4),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected
                ? colorScheme.primary
                : colorScheme.primary.withOpacity(0.2),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(option.emoji, style: const TextStyle(fontSize: 28)),
            const SizedBox(height: 6),
            Text(
              option.label,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight:
                        isSelected ? FontWeight.w700 : FontWeight.normal,
                    color: isSelected
                        ? colorScheme.primary
                        : colorScheme.onSurface,
                  ),
            ),
          ],
        ),
      ),
    );
  }
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
