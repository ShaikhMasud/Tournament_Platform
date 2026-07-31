import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/providers/auth_providers.dart';
import '../data/player_repository.dart';

final playerRepositoryProvider = Provider<PlayerRepository>(
  (ref) => PlayerRepository(ref.watch(apiClientProvider)),
);

/// Provider for the player's tournaments (tournaments they have entries in).
final playerTournamentsProvider = FutureProvider<List<PlayerTournament>>((ref) async {
  return ref.read(playerRepositoryProvider).getMyTournaments();
});

/// Provider for the player's entries.
final playerEntriesProvider = FutureProvider<List<PlayerEntry>>((ref) async {
  return ref.read(playerRepositoryProvider).getMyEntries();
});

/// Provider for a single entry detail.
final playerEntryDetailProvider = FutureProvider.family<PlayerEntryDetail, String>((ref, entryId) async {
  return ref.read(playerRepositoryProvider).getEntryDetail(entryId);
});
