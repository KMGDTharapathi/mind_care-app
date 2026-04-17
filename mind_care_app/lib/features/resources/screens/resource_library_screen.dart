import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../bloc/resource_bloc.dart';
import '../../../data/models/resource.dart';

class ResourceLibraryScreen extends StatefulWidget {
  const ResourceLibraryScreen({super.key});

  @override
  State<ResourceLibraryScreen> createState() => _ResourceLibraryScreenState();
}

class _ResourceLibraryScreenState extends State<ResourceLibraryScreen> {
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    context.read<ResourceBloc>().add(const LoadResources());
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Resource Library'),
        actions: [
          IconButton(
            icon: const Icon(Icons.bookmark),
            tooltip: 'Saved',
            onPressed: () => context.push('/resources/saved'),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search resources...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          context
                              .read<ResourceBloc>()
                              .add(const SearchResources(''));
                        },
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 0),
              ),
              onChanged: (value) {
                setState(() {});
                context.read<ResourceBloc>().add(SearchResources(value));
              },
            ),
          ),
          Expanded(
            child: BlocBuilder<ResourceBloc, ResourceState>(
              builder: (context, state) {
                if (state.isLoading) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (state.filteredResources.isEmpty &&
                    state.searchQuery.isNotEmpty) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(24.0),
                      child: Text(
                        'No results found',
                        style: TextStyle(fontSize: 16),
                      ),
                    ),
                  );
                }

                // Group by category
                final grouped = <String, List<Resource>>{};
                for (final r in state.filteredResources) {
                  grouped.putIfAbsent(r.category, () => []).add(r);
                }

                final categories = grouped.keys.toList();

                return ListView.builder(
                  padding: const EdgeInsets.only(bottom: 16),
                  itemCount: categories.length,
                  itemBuilder: (context, catIndex) {
                    final category = categories[catIndex];
                    final items = grouped[category]!;
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                          child: Text(
                            category,
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium
                                ?.copyWith(fontWeight: FontWeight.bold),
                          ),
                        ),
                        ...items.map((resource) => _ResourceCard(
                              resource: resource,
                              onTap: () =>
                                  context.push('/resources/${resource.id}'),
                              onBookmark: () => context
                                  .read<ResourceBloc>()
                                  .add(ToggleBookmark(resource.id)),
                            )),
                      ],
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _ResourceCard extends StatelessWidget {
  final Resource resource;
  final VoidCallback onTap;
  final VoidCallback onBookmark;

  const _ResourceCard({
    required this.resource,
    required this.onTap,
    required this.onBookmark,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: ListTile(
        title: Text(resource.title),
        subtitle: Chip(
          label: Text(resource.category),
          padding: EdgeInsets.zero,
          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
        ),
        trailing: IconButton(
          icon: Icon(
            resource.isBookmarked ? Icons.bookmark : Icons.bookmark_border,
            color: resource.isBookmarked
                ? Theme.of(context).colorScheme.primary
                : null,
          ),
          onPressed: onBookmark,
        ),
        onTap: onTap,
      ),
    );
  }
}
