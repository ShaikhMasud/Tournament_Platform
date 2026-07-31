import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/providers/auth_providers.dart';
import '../data/roles_repository.dart';
import '../models/tournament_role.dart';

final rolesRepositoryProvider = Provider<RolesRepository>(
  (ref) => RolesRepository(ref.watch(apiClientProvider)),
);

class TournamentRolesNotifier extends FamilyAsyncNotifier<List<TournamentRoleSummary>, String> {
  String get tournamentId => arg;

  @override
  Future<List<TournamentRoleSummary>> build(String tournamentId) async {
    return ref.read(rolesRepositoryProvider).listRoles(tournamentId);
  }

  Future<void> assignRole({
    required String email,
    required String role,
    List<String>? capabilities,
  }) async {
    await ref.read(rolesRepositoryProvider).assignRole(
          tournamentId: tournamentId,
          email: email,
          role: role,
          capabilities: capabilities,
        );
    state = await AsyncValue.guard(
      () => ref.read(rolesRepositoryProvider).listRoles(tournamentId),
    );
  }

  Future<void> revokeRole(String roleId) async {
    await ref.read(rolesRepositoryProvider).revokeRole(
          tournamentId: tournamentId,
          roleId: roleId,
        );
    state = await AsyncValue.guard(
      () => ref.read(rolesRepositoryProvider).listRoles(tournamentId),
    );
  }

  Future<void> updateCapabilities({
    required String roleId,
    required List<String> capabilities,
  }) async {
    await ref.read(rolesRepositoryProvider).updateCapabilities(
          tournamentId: tournamentId,
          roleId: roleId,
          capabilities: capabilities,
        );
    state = await AsyncValue.guard(
      () => ref.read(rolesRepositoryProvider).listRoles(tournamentId),
    );
  }
}

final tournamentRolesProvider =
    AsyncNotifierProvider.family<TournamentRolesNotifier, List<TournamentRoleSummary>, String>(
  TournamentRolesNotifier.new,
);
