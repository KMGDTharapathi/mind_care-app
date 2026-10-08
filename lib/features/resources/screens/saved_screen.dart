import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../data/models/resource.dart';
import '../../../data/repositories/resource_repository.dart';

class SavedScreen extends StatefulWidget {
  const SavedScreen({super.key});

  @override
  State<SavedScreen> createState() => _SavedScreenState();
}

class _SavedScreenState extends State<SavedScreen> {
  final _repository = ResourceRepository();
  List<Resource> _saved = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSaved();
  }

  Future<void> _loadSaved() async {
    final saved = await _repository.getBookmarked();
    if (mounted) {
      setState(() {
        _saved = saved;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Saved Resources')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _saved.isEmpty
          ? const Center(
              child: Padding(
                padding: EdgeInsets.all(24.0),
                child: Text(
                  'No saved resources yet. Bookmark resources to see them here.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 16),
                ),
              ),
            )
          : ListView.separated(
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: _saved.length,
              separatorBuilder: (_, _) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final resource = _saved[index];
                return ListTile(
                  title: Text(resource.title),
                  subtitle: Text(resource.category),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => context.push('/resources/${resource.id}'),
                );
              },
            ),
    );
  }
}
