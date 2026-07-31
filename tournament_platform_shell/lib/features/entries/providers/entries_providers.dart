import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/providers/auth_providers.dart';
import '../data/entries_repository.dart';
import '../models/entry.dart';

final entriesRepositoryProvider = Provider<EntriesRepository>(
  (ref) => EntriesRepository(ref.watch(apiClientProvider)),
);

class EntriesListState {
  final List<Entry> entries;
  final int page;
  final bool hasNext;
  final int count;
  final String search;
  final String? status;
  final bool isLoadingMore;

  const EntriesListState({
    this.entries = const [],
    this.page = 1,
    this.hasNext = false,
    this.count = 0,
    this.search = '',
    this.status,
    this.isLoadingMore = false,
  });

  EntriesListState copyWith({
    List<Entry>? entries,
    int? page,
    bool? hasNext,
    int? count,
    String? search,
    String? status,
    bool clearStatus = false,
    bool? isLoadingMore,
  }) {
    return EntriesListState(
      entries: entries ?? this.entries,
      page: page ?? this.page,
      hasNext: hasNext ?? this.hasNext,
      count: count ?? this.count,
      search: search ?? this.search,
      status: clearStatus ? null : (status ?? this.status),
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
    );
  }
}

/// One notifier per category id — holds the current page, search query,
/// and entry list for that category's roster.
class EntriesNotifier extends FamilyAsyncNotifier<EntriesListState, String> {
  String get categoryId => arg;

  @override
  Future<EntriesListState> build(String categoryId) async {
    return _fetchFirstPage();
  }

  Future<EntriesListState> _fetchFirstPage({
    String search = '',
    String? status,
  }) async {
    final repo = ref.read(entriesRepositoryProvider);
    final result = await repo.listEntries(
      categoryId: categoryId,
      search: search,
      status: status,
      page: 1,
    );
    return EntriesListState(
      entries: result.results,
      page: 1,
      hasNext: result.hasNext,
      count: result.count,
      search: search,
      status: status,
    );
  }

  Future<void> setSearch(String search) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(
      () => _fetchFirstPage(search: search, status: state.value?.status),
    );
  }

  Future<void> setStatusFilter(String? status) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(
      () => _fetchFirstPage(search: state.value?.search ?? '', status: status),
    );
  }

  Future<void> loadNextPage() async {
    final current = state.value;
    if (current == null || !current.hasNext || current.isLoadingMore) return;

    state = AsyncValue.data(current.copyWith(isLoadingMore: true));
    final repo = ref.read(entriesRepositoryProvider);
    try {
      final nextPage = current.page + 1;
      final result = await repo.listEntries(
        categoryId: categoryId,
        search: current.search,
        status: current.status,
        page: nextPage,
      );
      state = AsyncValue.data(
        current.copyWith(
          entries: [...current.entries, ...result.results],
          page: nextPage,
          hasNext: result.hasNext,
          isLoadingMore: false,
        ),
      );
    } catch (e, st) {
      state = AsyncValue.data(current.copyWith(isLoadingMore: false));
      // Surface the error without wiping the already-loaded list.
      state = AsyncValue.error(e, st).copyWithPrevious(state);
    }
  }

  /// Adds an entry, then refetches the first page from the server —
  /// never mutates the local list optimistically, since capacity/
  /// duplicate rules are enforced server-side and the list must stay
  /// authoritative.
  Future<void> addEntry({int? playerId}) async {
    final repo = ref.read(entriesRepositoryProvider);
    await repo.addEntry(categoryId: categoryId, playerId: playerId);
    final current = state.value;
    state = await AsyncValue.guard(
      () => _fetchFirstPage(
        search: current?.search ?? '',
        status: current?.status,
      ),
    );
  }

  Future<void> removeEntry(String entryId) async {
    final repo = ref.read(entriesRepositoryProvider);
    await repo.removeEntry(entryId);
    final current = state.value;
    state = await AsyncValue.guard(
      () => _fetchFirstPage(
        search: current?.search ?? '',
        status: current?.status,
      ),
    );
  }
}

final entriesProvider =
    AsyncNotifierProvider.family<EntriesNotifier, EntriesListState, String>(
  EntriesNotifier.new,
);
