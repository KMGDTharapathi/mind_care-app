import 'package:flutter/material.dart';
import '../../../core/service_locator.dart';
import '../../../data/repositories/resource_repository.dart';
import '../../../data/models/resource.dart';

class ResourceDetailScreen extends StatefulWidget {
  final String resourceId;

  const ResourceDetailScreen({super.key, required this.resourceId});

  @override
  State<ResourceDetailScreen> createState() => _ResourceDetailScreenState();
}

class _ResourceDetailScreenState extends State<ResourceDetailScreen> {
  final _repository = ResourceRepository();
  late Resource? _resource;

  @override
  void initState() {
    super.initState();
    _loadResource();
    _logView();
  }

  void _loadResource() {
    final all = _repository.getAll();
    try {
      _resource = all.firstWhere((r) => r.id == widget.resourceId);
    } catch (_) {
      _resource = null;
    }
  }

  void _logView() {
    final all = _repository.getAll();
    try {
      final resource = all.firstWhere((r) => r.id == widget.resourceId);
      ServiceLocator.analyticsService?.logEvent(
        'resource_viewed',
        parameters: {'category': resource.category},
      );
    } catch (_) {}
  }

  Future<void> _toggleBookmark() async {
    if (_resource == null) return;
    if (_resource!.isBookmarked) {
      await _repository.removeBookmark(_resource!.id);
    } else {
      await _repository.bookmark(_resource!.id);
    }
    setState(() {
      _loadResource();
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_resource == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Resource')),
        body: const Center(child: Text('Resource not found.')),
      );
    }

    final resource = _resource!;

    return Scaffold(
      appBar: AppBar(
        title: Text(resource.title),
        actions: [
          IconButton(
            icon: Icon(
              resource.isBookmarked ? Icons.bookmark : Icons.bookmark_border,
            ),
            tooltip: resource.isBookmarked ? 'Remove bookmark' : 'Bookmark',
            onPressed: _toggleBookmark,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Chip(label: Text(resource.category)),
            const SizedBox(height: 16),
            Text(
              resource.content,
              style: const TextStyle(fontSize: 16, height: 1.6),
            ),
          ],
        ),
      ),
    );
  }
}
