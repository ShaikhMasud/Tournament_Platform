import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/providers/auth_providers.dart';
import '../data/results_repository.dart';
import '../models/result_document.dart';

final resultsRepositoryProvider = Provider<ResultsRepository>(
  (ref) => ResultsRepository(ref.watch(apiClientProvider)),
);

/// Request or fetch results for a tournament.
class TournamentResultsNotifier extends FamilyAsyncNotifier<ResultDocument?, String> {
  @override
  Future<ResultDocument?> build(String tournamentId) async {
    return ref.read(resultsRepositoryProvider).requestResults(tournamentId);
  }

  Future<void> request() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(
      () => ref.read(resultsRepositoryProvider).requestResults(arg),
    );
  }

  Future<void> checkStatus() async {
    final current = state.valueOrNull;
    if (current == null) return;
    state = await AsyncValue.guard(
      () => ref.read(resultsRepositoryProvider).getStatus(current.id),
    );
  }
}

final tournamentResultsProvider =
    AsyncNotifierProvider.family<TournamentResultsNotifier, ResultDocument?, String>(
  TournamentResultsNotifier.new,
);
