import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:tournament_platform/features/roles/screens/tournament_roles_screen.dart';
import 'package:tournament_platform/features/tournaments/screens/category_court_management_screen.dart';
import 'package:tournament_platform/features/tournaments/screens/organizer_home_screen.dart';

import '../features/auth/providers/auth_providers.dart';
import '../features/auth/screens/login_screen.dart';
import '../features/auth/screens/signup_screen.dart';
import '../features/draws/screens/draw_screen.dart';
import '../features/entries/screens/category_entries_screen.dart';
import '../features/matches/screens/match_live_scoring_screen.dart';
import '../features/matches/screens/matches_list_screen.dart';
import '../features/results/screens/results_screen.dart';
import '../features/role_selector/screens/role_selector_screen.dart';

/// Route guarding lives here, not scattered through screens: every
/// role-gated route (once added) should check auth state via this same
/// redirect function rather than re-implementing the check per screen.
final appRouterProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authControllerProvider);

  return GoRouter(
    initialLocation: '/',
    refreshListenable: GoRouterRefreshStream(ref),
    redirect: (context, state) {
      final isLoggedIn = authState.valueOrNull != null;
      final isLoggingInOrOut = authState.isLoading;
      final goingToAuthScreen =
          state.matchedLocation == '/login' || state.matchedLocation == '/signup';

      if (isLoggingInOrOut) return null; // don't redirect mid-transition

      if (!isLoggedIn && !goingToAuthScreen) return '/login';
      if (isLoggedIn && goingToAuthScreen) return '/';
      return null;
    },
    routes: [
      GoRoute(path: '/login', builder: (context, state) => const LoginScreen()),
      GoRoute(path: '/signup', builder: (context, state) => const SignupScreen()),
      GoRoute(path: '/', builder: (context, state) => const RoleSelectorScreen()),
      GoRoute(
        path: '/organizer/home',
        builder: (context, state) => const OrganizerHomeScreen(),
      ),
      GoRoute(
        path: '/tournaments/:tournamentId/manage',
        builder: (context, state) {
          final id = state.pathParameters['tournamentId']!;
          return CategoryCourtManagementScreen(tournamentId: id);
        },
      ),
      // Entries routes.
      GoRoute(
        path: '/tournaments/:tournamentId/categories/:categoryId/entries',
        builder: (context, state) {
          final categoryId = state.pathParameters['categoryId']!;
          final categoryName = state.uri.queryParameters['name'] ?? 'Category';
          return CategoryEntriesScreen(categoryId: categoryId, categoryName: categoryName);
        },
      ),
      // Draw routes.
      GoRoute(
        path: '/tournaments/:tournamentId/categories/:categoryId/draw',
        builder: (context, state) {
          final categoryId = state.pathParameters['categoryId']!;
          final categoryName = state.uri.queryParameters['name'] ?? 'Draw';
          return DrawScreen(categoryId: categoryId, categoryName: categoryName);
        },
      ),
      // Roles routes.
      GoRoute(
        path: '/tournaments/:tournamentId/team',
        builder: (context, state) {
          final tournamentId = state.pathParameters['tournamentId']!;
          final tournamentName = state.uri.queryParameters['name'] ?? 'Tournament';
          return TournamentRolesScreen(tournamentId: tournamentId, tournamentName: tournamentName);
        },
      ),
      // Matches routes.
      GoRoute(
        path: '/tournaments/:tournamentId/matches',
        builder: (context, state) {
          final tournamentId = state.pathParameters['tournamentId']!;
          final categoryId = state.uri.queryParameters['category'];
          final status = state.uri.queryParameters['status'];
          return MatchesListScreen(
            tournamentId: tournamentId,
            categoryId: categoryId,
            status: status,
          );
        },
      ),
      GoRoute(
        path: '/matches/:matchId/live',
        builder: (context, state) {
          final matchId = state.pathParameters['matchId']!;
          return MatchLiveScoringScreen(matchId: matchId);
        },
      ),
      // Results routes.
      GoRoute(
        path: '/tournaments/:tournamentId/results',
        builder: (context, state) {
          final tournamentId = state.pathParameters['tournamentId']!;
          final tournamentName = state.uri.queryParameters['name'] ?? 'Tournament';
          return ResultsScreen(tournamentId: tournamentId, tournamentName: tournamentName);
        },
      ),
    ],
  );
});

/// Bridges Riverpod's AsyncValue changes into something GoRouter's
/// refreshListenable can listen to, so the router re-evaluates `redirect`
/// whenever auth state changes (login, logout, session-expired).
class GoRouterRefreshStream extends ChangeNotifier {
  GoRouterRefreshStream(Ref ref) {
    ref.listen(authControllerProvider, (_, __) => notifyListeners());
  }
}
