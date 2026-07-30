import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/providers/auth_providers.dart'; // apiClientProvider lives here
import '../data/tournaments_repository.dart';
import '../models/tournament.dart';

final tournamentsRepositoryProvider = Provider<TournamentsRepository>(
  (ref) => TournamentsRepository(ref.watch(apiClientProvider)),
);

class TournamentsNotifier extends AsyncNotifier<List<Tournament>> {
  @override
  Future<List<Tournament>> build() {
    return ref.read(tournamentsRepositoryProvider).listVisibleTournaments();
  }

  Future<Tournament> createTournament({
    required String organizationId,
    required String name,
    bool isPublic = false,
  }) async {
    final repo = ref.read(tournamentsRepositoryProvider);
    final created = await repo.createTournament(
      organizationId: organizationId,
      name: name,
      isPublic: isPublic,
    );
    state = await AsyncValue.guard(() => repo.listVisibleTournaments());
    return created;
  }
}

final tournamentsProvider =
    AsyncNotifierProvider<TournamentsNotifier, List<Tournament>>(
  TournamentsNotifier.new,
);

/// One tournament's detail (with nested categories/courts), keyed by id.
class TournamentDetailNotifier extends FamilyAsyncNotifier<Tournament, String> {
  @override
  Future<Tournament> build(String tournamentId) {
    return ref.read(tournamentsRepositoryProvider).getTournament(tournamentId);
  }

  Future<void> refresh() async {
    final repo = ref.read(tournamentsRepositoryProvider);
    state = await AsyncValue.guard(() => repo.getTournament(arg));
  }

  Future<void> addCategory({
    required String name,
    required String drawFormat,
    required int capacity,
  }) async {
    final repo = ref.read(tournamentsRepositoryProvider);
    await repo.createCategory(
      tournamentId: arg,
      name: name,
      drawFormat: drawFormat,
      capacity: capacity,
    );
    await refresh();
  }

  Future<void> addCourt({required String name}) async {
    final repo = ref.read(tournamentsRepositoryProvider);
    await repo.createCourt(tournamentId: arg, name: name);
    await refresh();
  }
}

final tournamentDetailProvider = AsyncNotifierProvider.family<
    TournamentDetailNotifier, Tournament, String>(TournamentDetailNotifier.new);