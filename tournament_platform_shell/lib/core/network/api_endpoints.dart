/// Central place for every REST path used from Phase 1 onward.
/// Keeps literal path strings out of repository bodies so there's exactly
/// one place to update if a route changes.
///
/// NOTE: these paths are relative to ApiClient's Dio baseUrl, which is
/// already `$baseUrl/api` (see ApiConfig.apiBase) — do NOT prefix these
/// with /api again, same convention auth_repository.dart already uses
/// ('/auth/signup', not '/api/auth/signup').
class ApiEndpoints {
  ApiEndpoints._();

  // --- Organizations ---
  static const String organizations = '/organizations/';
  static String organization(String id) => '/organizations/$id/';

  // --- Tournaments ---
  static const String tournaments = '/tournaments/';
  static String tournament(String id) => '/tournaments/$id/';

  // --- Categories (nested under a tournament) ---
  static String categories(String tournamentId) =>
      '/tournaments/$tournamentId/categories/';
  static String category(String tournamentId, String categoryId) =>
      '/tournaments/$tournamentId/categories/$categoryId/';

  // --- Courts (nested under a tournament) ---
  static String courts(String tournamentId) =>
      '/tournaments/$tournamentId/courts/';
  static String court(String tournamentId, String courtId) =>
      '/tournaments/$tournamentId/courts/$courtId/';
}