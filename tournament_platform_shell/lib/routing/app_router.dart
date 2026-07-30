import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:tournament_platform/features/tournaments/screens/category_court_management_screen.dart';
import 'package:tournament_platform/features/tournaments/screens/organizer_home_screen.dart';

import '../features/auth/providers/auth_providers.dart';
import '../features/auth/screens/login_screen.dart';
import '../features/auth/screens/signup_screen.dart';
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
      
      // Add role-scoped shells here as they're built, e.g.:
      // GoRoute(path: '/organizer', builder: ...),
      // GoRoute(path: '/player', builder: ...),
      // GoRoute(path: '/assistant', builder: ...),
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
