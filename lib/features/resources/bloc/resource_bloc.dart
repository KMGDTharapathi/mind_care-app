import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../../data/models/resource.dart';
import '../../../data/repositories/resource_repository.dart';
import '../../../services/analytics/analytics_service.dart';

// Events
abstract class ResourceEvent extends Equatable {
  const ResourceEvent();
  @override
  List<Object?> get props => [];
}

class LoadResources extends ResourceEvent {
  const LoadResources();
}

class SearchResources extends ResourceEvent {
  final String query;
  const SearchResources(this.query);
  @override
  List<Object?> get props => [query];
}

class ToggleBookmark extends ResourceEvent {
  final String resourceId;
  const ToggleBookmark(this.resourceId);
  @override
  List<Object?> get props => [resourceId];
}

class ViewResource extends ResourceEvent {
  final String resourceId;
  const ViewResource(this.resourceId);
  @override
  List<Object?> get props => [resourceId];
}

// State
class ResourceState extends Equatable {
  final List<Resource> resources;
  final List<Resource> filteredResources;
  final String searchQuery;
  final bool isLoading;

  const ResourceState({
    this.resources = const [],
    this.filteredResources = const [],
    this.searchQuery = '',
    this.isLoading = false,
  });

  ResourceState copyWith({
    List<Resource>? resources,
    List<Resource>? filteredResources,
    String? searchQuery,
    bool? isLoading,
  }) {
    return ResourceState(
      resources: resources ?? this.resources,
      filteredResources: filteredResources ?? this.filteredResources,
      searchQuery: searchQuery ?? this.searchQuery,
      isLoading: isLoading ?? this.isLoading,
    );
  }

  @override
  List<Object?> get props => [resources, filteredResources, searchQuery, isLoading];
}

// Bloc
class ResourceBloc extends Bloc<ResourceEvent, ResourceState> {
  final ResourceRepository repository;
  final AnalyticsService? analyticsService;

  ResourceBloc({required this.repository, this.analyticsService})
      : super(const ResourceState()) {
    on<LoadResources>(_onLoadResources);
    on<SearchResources>(_onSearchResources);
    on<ToggleBookmark>(_onToggleBookmark);
    on<ViewResource>(_onViewResource);
  }

  void _onLoadResources(LoadResources event, Emitter<ResourceState> emit) {
    emit(state.copyWith(isLoading: true));
    final all = repository.getAll();
    emit(state.copyWith(
      isLoading: false,
      resources: all,
      filteredResources: all,
      searchQuery: '',
    ));
  }

  void _onSearchResources(SearchResources event, Emitter<ResourceState> emit) {
    final query = event.query;
    final filtered = query.isEmpty ? state.resources : repository.search(query);
    emit(state.copyWith(filteredResources: filtered, searchQuery: query));
  }

  Future<void> _onToggleBookmark(
      ToggleBookmark event, Emitter<ResourceState> emit) async {
    final resource = state.resources.firstWhere((r) => r.id == event.resourceId);
    if (resource.isBookmarked) {
      await repository.removeBookmark(event.resourceId);
    } else {
      await repository.bookmark(event.resourceId);
    }
    // Reload resources to reflect updated bookmark state
    final all = repository.getAll();
    final filtered = state.searchQuery.isEmpty
        ? all
        : repository.search(state.searchQuery);
    emit(state.copyWith(resources: all, filteredResources: filtered));
  }

  Future<void> _onViewResource(
      ViewResource event, Emitter<ResourceState> emit) async {
    final resource = state.resources.firstWhere(
      (r) => r.id == event.resourceId,
      orElse: () => state.filteredResources.firstWhere(
        (r) => r.id == event.resourceId,
      ),
    );
    await analyticsService?.logEvent(
      'resource_viewed',
      parameters: {'category': resource.category},
    );
  }
}
