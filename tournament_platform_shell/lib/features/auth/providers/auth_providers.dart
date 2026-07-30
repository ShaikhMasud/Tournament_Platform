import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../../../core/network/api_client.dart';
import '../../../core/network/token_storage.dart';
import '../data/auth_repository.dart';
import '../models/session.dart';

final secureStorageProvider = Provider((ref) => const FlutterSecureStorage());

final tokenStorageProvider = Provider((ref) => TokenStorage(ref.watch(secureStorageProvider)));

final apiClientProvider = Provider((ref) => ApiClient(ref.watch(tokenStorageProvider)));

final authRepositoryProvider = Provider(
  (ref) => AuthRepository(ref.watch(apiClientProvider), ref.watch(tokenStorageProvider)),
);

/// Holds the current session (or null if logged out). This is THE state
/// every other feature's providers should watch to decide what a user can
/// see — never re-derive role/capability checks ad hoc in a widget.
class AuthController extends AsyncNotifier<Session?> {
  @override
  Future<Session?> build() async {
    final hasSession = await ref.read(tokenStorageProvider).hasSession;
    if (!hasSession) return null;
    try {
      return await ref.read(authRepositoryProvider).fetchSession();
    } catch (_) {
      // Stored token is invalid/expired and refresh already failed inside
      // the ApiClient interceptor — treat as logged out.
      return null;
    }
  }

  Future<void> login({required String email, required String password}) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      await ref.read(authRepositoryProvider).login(email: email, password: password);
      return ref.read(authRepositoryProvider).fetchSession();
    });
  }

  Future<void> signup({
    required String email,
    required String username,
    required String password,
    required String displayName,
  }) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => ref.read(authRepositoryProvider).signup(
            email: email,
            username: username,
            password: password,
            displayName: displayName,
          ),
    );
  }

  /// Logout must clear sensitive AND role/tournament-bound state — this is
  /// the single choke point for that per the auth spec. As more features add
  /// providers scoped to "current tournament"/"current role", invalidate
  /// them here too (ref.invalidate(someTournamentScopedProvider)).
  Future<void> logout() async {
    await ref.read(authRepositoryProvider).logout();
    state = const AsyncData(null);
    // Example of the pattern once more feature providers exist:
    // ref.invalidate(currentTournamentProvider);
    // ref.invalidate(selectedRoleProvider);
  }

  Future<void> refreshSession() async {
    state = await AsyncValue.guard(() => ref.read(authRepositoryProvider).fetchSession());
  }
}

final authControllerProvider = AsyncNotifierProvider<AuthController, Session?>(
  AuthController.new,
);

/// Convenience derived providers, so screens don't re-implement this logic.
final isLoggedInProvider = Provider<bool>((ref) {
  return ref.watch(authControllerProvider).valueOrNull != null;
});

/// The currently active role/tournament the user has drilled into, set by
/// the Role Selector screen. Null until they pick one (or if they only have
/// a single role, set automatically — see role_selector_screen.dart).
final selectedRoleProvider = StateProvider<TournamentRoleSummary?>((ref) => null);
