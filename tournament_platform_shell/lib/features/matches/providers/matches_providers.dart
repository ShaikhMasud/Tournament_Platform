import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/providers/auth_providers.dart';
import '../data/matches_repository.dart';
import '../models/match.dart';

final matchesRepositoryProvider = Provider<MatchesRepository>(
  (ref) => MatchesRepository(ref.watch(apiClientProvider)),
);

/// Matches list for a tournament, optionally filtered.
class MatchesListNotifier extends FamilyAsyncNotifier<List<MatchModel>, MatchesFilter> {
  @override
  Future<List<MatchModel>> build(MatchesFilter filter) async {
    return ref.read(matchesRepositoryProvider).listMatches(
          tournamentId: filter.tournamentId,
          categoryId: filter.categoryId,
          courtId: filter.courtId,
          status: filter.status,
        );
  }

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => build(arg));
  }
}

class MatchesFilter {
  const MatchesFilter({
    required this.tournamentId,
    this.categoryId,
    this.courtId,
    this.status,
  });

  final String tournamentId;
  final String? categoryId;
  final String? courtId;
  final String? status;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MatchesFilter &&
          runtimeType == other.runtimeType &&
          tournamentId == other.tournamentId &&
          categoryId == other.categoryId &&
          courtId == other.courtId &&
          status == other.status;

  @override
  int get hashCode =>
      tournamentId.hashCode ^
      categoryId.hashCode ^
      courtId.hashCode ^
      status.hashCode;
}

final matchesListProvider =
    AsyncNotifierProvider.family<MatchesListNotifier, List<MatchModel>, MatchesFilter>(
  MatchesListNotifier.new,
);

/// Single match detail.
class MatchDetailNotifier extends FamilyAsyncNotifier<MatchModel, String> {
  @override
  Future<MatchModel> build(String matchId) async {
    return ref.read(matchesRepositoryProvider).getMatch(matchId);
  }

  Future<void> schedule({String? courtId, DateTime? scheduledStart}) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      return ref.read(matchesRepositoryProvider).scheduleMatch(
            matchId: arg,
            courtId: courtId,
            scheduledStart: scheduledStart,
          );
    });
  }

  Future<void> start() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      return ref.read(matchesRepositoryProvider).startMatch(arg);
    });
  }

  Future<void> updateScore({
    required int entry1Points,
    required int entry2Points,
    required int version,
  }) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      return ref.read(matchesRepositoryProvider).updateScore(
            matchId: arg,
            entry1Points: entry1Points,
            entry2Points: entry2Points,
            version: version,
          );
    });
  }

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(
      () => ref.read(matchesRepositoryProvider).getMatch(arg),
    );
  }
}

final matchDetailProvider =
    AsyncNotifierProvider.family<MatchDetailNotifier, MatchModel, String>(
  MatchDetailNotifier.new,
);
