import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';
import '../../../data/models/journal_entry.dart';
import '../bloc/journal_bloc.dart';

class JournalEntryScreen extends StatefulWidget {
  final String? entryId;

  const JournalEntryScreen({super.key, this.entryId});

  @override
  State<JournalEntryScreen> createState() => _JournalEntryScreenState();
}

class _JournalEntryScreenState extends State<JournalEntryScreen> {
  late final TextEditingController _titleController;
  late final TextEditingController _bodyController;
  JournalEntry? _existingEntry;
  bool _initialized = false;

  bool get _isEditing => widget.entryId != null;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController();
    _bodyController = TextEditingController();
    _bodyController.addListener(_onBodyChanged);

    if (_isEditing) {
      context.read<JournalBloc>().add(const LoadEntries());
    }
  }

  void _onBodyChanged() {
    context.read<JournalBloc>().add(EntryBodyChanged(_bodyController.text));
  }

  void _initFromState(JournalState state) {
    if (_initialized || !_isEditing) return;
    final entry = state.entries.where((e) => e.id == widget.entryId).firstOrNull;
    if (entry != null) {
      _existingEntry = entry;
      _titleController.text = entry.title;
      _bodyController.text = entry.body;
      _initialized = true;
    }
  }

  void _save() {
    final now = DateTime.now();
    final entry = JournalEntry(
      id: _existingEntry?.id ?? const Uuid().v4(),
      title: _titleController.text.trim(),
      body: _bodyController.text,
      createdAt: _existingEntry?.createdAt ?? now,
      updatedAt: now,
    );
    context.read<JournalBloc>().add(SaveEntry(entry));
  }

  void _confirmDelete() {
    showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Entry'),
        content: const Text('Are you sure you want to permanently delete this entry?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    ).then((confirmed) {
      if (confirmed == true && widget.entryId != null) {
        context.read<JournalBloc>().add(DeleteEntry(widget.entryId!));
      }
    });
  }

  @override
  void dispose() {
    _bodyController.removeListener(_onBodyChanged);
    _titleController.dispose();
    _bodyController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<JournalBloc, JournalState>(
      listener: (context, state) {
        _initFromState(state);

        if (state.isSaved) {
          context.pop();
        }
        if (state.isDeleted) {
          context.pop();
        }
        if (state.validationError != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.validationError!)),
          );
        }
      },
      builder: (context, state) {
        if (_isEditing && !_initialized && state.entries.isEmpty) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }

        return Scaffold(
          appBar: AppBar(
            title: Text(_isEditing ? 'Edit Entry' : 'New Entry'),
            actions: [
              if (_isEditing)
                IconButton(
                  icon: const Icon(Icons.delete_outline),
                  tooltip: 'Delete',
                  onPressed: _confirmDelete,
                ),
              IconButton(
                icon: const Icon(Icons.check),
                tooltip: 'Save',
                onPressed: _save,
              ),
            ],
          ),
          body: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: _titleController,
                  decoration: const InputDecoration(
                    hintText: 'Title',
                    border: InputBorder.none,
                  ),
                  style: Theme.of(context).textTheme.titleLarge,
                  textCapitalization: TextCapitalization.sentences,
                ),
                const Divider(),
                Expanded(
                  child: TextField(
                    controller: _bodyController,
                    decoration: const InputDecoration(
                      hintText: 'Write your thoughts...',
                      border: InputBorder.none,
                    ),
                    maxLines: null,
                    expands: true,
                    textAlignVertical: TextAlignVertical.top,
                    textCapitalization: TextCapitalization.sentences,
                  ),
                ),
                const Divider(),
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                  child: Text(
                    '${state.wordCount} words',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
